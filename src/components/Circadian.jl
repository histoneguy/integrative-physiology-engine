"""
Endogenous circadian driver.

See docs/adr/0005-circadian-driver.md.

This is an EXOGENOUS oscillator: it supplies phase to other subsystems and takes no
feedback from them. That has two useful properties.

  1. It cannot be derived from any other state, which is required - the diurnal rhythm
     of tubular sodium handling occurs independent of posture and food/water intake,
     so it is a genuine driver rather than a consequence.
  2. For multirate partitioning (ADR 0003) it is the one genuinely free boundary in
     the model: with no feedback there is no coupling error, so it may be evaluated in
     either block.

STRUCTURAL COMMITMENT: separate output paths for the renal and cardiovascular arms.
In whole-body Bmal1 knockout rats, diurnal control of sodium excretion was lost while
circadian MAP rhythms remained intact. The rhythms are dissociable, so the model must
be able to dissociate them. Disabling `renal_gain` alone should reproduce that
phenotype - a falsifiable test, not a convenience.

STRUCTURE SOURCES - corrected 2026-08-25 by a citation audit. Every entry here
previously carried a title with NO AUTHOR LIST, which is the exact shape that let a
misattribution survive two sessions on PMID 2966064.

  Firsov D, Bonny O. Circadian rhythms and the kidney. Nat Rev Nephrol
    2018;14(10):626-635. 10.1038/s41581-018-0048-9
  Johnston JG, Speed JS, Jin C, Pollock DM. Loss of endothelin B receptor function
    impairs sodium excretion in a time- and sex-dependent manner. Am J Physiol Renal
    Physiol 2016;311(5):F991-F998. 10.1152/ajprenal.00103.2016
    NOTE THE ACTUAL TITLE. This is an endothelin-B knockout study, not a general
    characterisation of the renal circadian rhythm. It supports time-of-day
    dependence in sodium excretion; it does not supply an amplitude or a phase.
  Johnston JG, Speed JS, Becker BK, Kasztan M, Soliman RH, Rhoads MK, Tao B, Jin C,
    et al. Diurnal control of blood pressure is uncoupled from sodium excretion.
    Hypertension 2020;75(6):1624-1634. 10.1161/HYPERTENSIONAHA.119.13908
    YEAR IS 2020, not 2019 - the .119. in the DOI is a submission-year convention.

  ENDOGENEITY OF THE RENAL ARM, which is the claim ADR 0005 rests on:
  el-Hajj Fuleihan G, Klerman EB, Brown EN, Choe Y, Brown EM, Czeisler CA.
    J Clin Endocrinol Metab 1997;82(1):281-286. Under 28-40 h of constant routine -
    enforced wakefulness, strict semirecumbent posture, hourly snacks - the urinary
    calcium and phosphate rhythms changed character while URINARY SODIUM/CREATININE
    WAS UNCHANGED. A rhythm that survives removal of sleep, posture and meals is
    endogenous.

  THE CARDIOVASCULAR ARM IS ON WEAKER GROUND THAN THE RENAL ONE, which is the
  reverse of what the original parameters implied:
  Shea SA, Hilton MF, Hu K, Scheer FAJL. Circ Res 2011;108(8):980-984. 28 adults,
    three protocols including forced desynchrony. A real endogenous BP rhythm, but
    peak-to-trough only 3-6 mmHg systolic, peaking near 21:00 - the EVENING.
  Kerkhof GA, Van Dongen HP, Bobbert AC. Am J Hypertens 1998;11(3):373-377. 25
    normotensives, constant routine, stated power >0.95: NO endogenous BP rhythm.
    Replicated by Van Dongen 2001. The disagreement is live and unresolved.
  Degaute JP, van de Borne P, Linkowski P, Van Cauter E. Hypertension
    1991;18(2):199-210. Recumbency and sleep account for 65-75% of the nocturnal
    decline, so the familiar ambulatory dip is mostly EXOGENOUS and is not what this
    component models.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams:
    CIRC_PERIOD, CIRC_RENAL_NA_AMPLITUDE, CIRC_RENAL_NA_ACROPHASE,
    CIRC_CV_MAP_AMPLITUDE, CIRC_CV_ACROPHASE

"""
    CircadianClock(; name, phase0 = 0.0, renal_gain = 1.0, cv_gain = 1.0)

Cosinor oscillator with independent renal and cardiovascular output paths.

Time base is DAYS. `phase0` is the phase offset in days at t = 0; the convention is
that phase 0 corresponds to the start of the active period (waking in humans, lights
off in nocturnal rodents - state which when using rodent-derived parameters).

`renal_gain` and `cv_gain` scale the two arms independently. Set `renal_gain = 0` to
model loss of the renal clock path with the pressure rhythm intact.

A cosinor is the standard descriptive form in this literature and is adequate for a
first implementation. It is NOT a mechanistic clock - it cannot entrain, phase-shift,
or free-run. If protocols involving shift work, jet lag, or constant routine are ever
added, this must be replaced by a limit-cycle oscillator, not reparameterised.
"""
function CircadianClock(; name, phase0 = 0.0, renal_gain = 1.0, cv_gain = 1.0)

    pars = @parameters begin
        T          = CIRC_PERIOD                      # day
        phi0       = phase0                           # day
        A_renal    = CIRC_RENAL_NA_AMPLITUDE          # unitless, relative
        acro_renal = CIRC_RENAL_NA_ACROPHASE          # day, peak time
        A_cv       = CIRC_CV_MAP_AMPLITUDE            # unitless, relative
        acro_cv    = CIRC_CV_ACROPHASE                # day, peak time
        g_renal    = renal_gain
        g_cv       = cv_gain
    end

    vars = @variables begin
        # All algebraic functions of t - no defaults.
        phase(t)          # radians
        renal_mod(t)      # multiplier on tubular Na reabsorption capacity
        cv_mod(t)         # multiplier on MAP setpoint
        clock_hour(t)     # 0-24, for reporting (ADR 0005)
    end

    eqs = [
        # Free-running phase. Not a state that can be perturbed - see the note
        # above about entrainment.
        phase      ~ 2 * pi * (t + phi0) / T,
        clock_hour ~ 24 * mod(( t + phi0 ) / T, 1.0),

        # Two INDEPENDENT arms. Deliberately not derived from one another.
        renal_mod  ~ 1 + g_renal * A_renal * cos(2 * pi * (t + phi0 - acro_renal) / T),
        cv_mod     ~ 1 + g_cv    * A_cv    * cos(2 * pi * (t + phi0 - acro_cv)    / T),
    ]

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    circadian_couplings()

The clock's connections. Both are Neurohumoral: the clock acts through gene
expression and hormone signalling, so there is a genuine lag between clock phase and
effector response. Per ADR 0003 these are safe to partition across.

Note the clock takes NO inputs. There is no coupling into it, which is what makes it
a free partition boundary.
"""
function circadian_couplings()
    return [
        Coupling(:circadian, :renal, Neurohumoral;
                 tau_seconds = 3600.0,
                 gain_param = :CIRC_RENAL_NA_AMPLITUDE,
                 note = "aldosterone-Per1-ENaC path; tau is transcriptional-effector " *
                        "delay and is ASSUMED - see ledger"),
        # TWO CORRECTIONS, 2026-08-27, both found by assembling the graph.
        # (1) The target was `:cardiovascular`. The actual connection in
        #     assemble.jl is `br.cv_mod ~ clk.cv_mod` - the clock scales the
        #     BAROREFLEX SETPOINT, not anything in the cardiovascular component.
        #     A partition trusting the old declaration would have protected an
        #     edge that does not exist while cutting one that does.
        # (2) gain_param named :CIRC_CV_MAP_DIP_FRACTION, which is not a ledger
        #     parameter and never has been. coupling_ledger_rows() exists
        #     precisely to catch a dangling provenance pointer and had never
        #     been called. The row is CIRC.CV_MAP.AMPLITUDE.
        Coupling(:circadian, :baroreflex, Neurohumoral;
                 tau_seconds = 3600.0,
                 gain_param = :CIRC_CV_MAP_AMPLITUDE,
                 note = "independent path - Bmal1-/- rats lose renal rhythm while " *
                        "MAP rhythm persists, so these must not share a route"),
    ]
end

"""
    cycle_average(sol, sym; period_days = 1.0)

Average an observable over whole cycles.

REQUIRED for reporting. With an endogenous oscillator there is no steady state -
every equilibrium is a limit cycle (ADR 0005). A bare instantaneous value is
ambiguous unless its phase is stated, so summaries must be cycle-averaged and
comparisons must be made on a common phase grid.
"""
function cycle_average(sol, sym; period_days = 1.0)
    t = sol.t
    v = sol[sym]
    t_end = t[end]
    t_start = t_end - period_days
    t_start < t[1] && error("solution shorter than one cycle - cannot cycle-average")
    idx = findall(x -> x >= t_start, t)
    length(idx) < 3 && error("too few points in the final cycle; reduce saveat")
    # trapezoid over the final whole cycle
    num = sum((v[idx[i+1]] + v[idx[i]]) / 2 * (t[idx[i+1]] - t[idx[i]])
              for i in 1:length(idx)-1)
    den = t[idx[end]] - t[idx[1]]
    return num / den
end
