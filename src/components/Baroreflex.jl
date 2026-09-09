"""
Arterial baroreflex - LUMPED, cycle-averaged.

STRUCTURE SOURCES
  Baroreflex controls arterial pressure primarily via reflex changes in vascular
    resistance rather than cardiac output:
    Dampney RAL. Resetting of the baroreflex control of sympathetic vasomotor
    activity during natural behaviors. Front Physiol 2017. PMC5559464.
  Sympathetic vasomotor delay 2-3 s; parasympathetic 200-600 ms:
    La Rovere MT et al. Ann Noninvasive Electrocardiol 2008;13(2):191-207.
  Open-loop gain 1.0-3.5 (animal, vascularly isolated baroreceptors):
    Yamasaki F et al. Front Neurosci 2021;15:707345.

EVIDENCE (ADR 0006)
  E1  The reflex exists, is fast, and acts mainly through vascular resistance.
  E1  The reflex RESETS over hours to days.
  --  Open-loop gain is ANIMAL-derived; human value is explicitly unclarified.
  --  Reset time constant is ASSUMED.

WHY THE ARMS WERE LUMPED, AND WHY THEY NO LONGER ARE - ADR 0022, 2026-09-08
The vagal arm acts on heart rate in 200-600 ms; the sympathetic arm acts on
vascular tone in 2-3 s. This model was cycle-averaged (ADR 0002) with heart rate
as a PARAMETER, so the vagal arm had nothing to act on, and one lumped lag on TPR
was the honest representation. ADR 0009 said in terms: separating them buys
nothing until heart rate exists.

ADR 0011 made cardiac output HR x SV, so heart rate exists. The chronotropic arm
is now built and acts on `hr_mod`.

THE ARMS ADD, THEY DO NOT SPLIT A SHARED GAIN, and that was checked BEFORE this
was built because getting it wrong would have doubled the reflex silently -
section 5 item 22, a parameter re-estimated by being given a second path.
Three independent lines, in validation/chronotropic_baroreflex_prereg.md section 6:
  * Yamasaki's open-loop gain decomposes through PLASMA NOREPINEPHRINE, and a
    cholinergic vagal limb cannot appear in a noradrenergic arc by construction;
  * the animal preparations behind its 1.0-3.5 range are vagotomized where it
    could be checked;
  * Dutoit 2010 (PMID 21060001) found cardiac and sympathetic baroreflex
    sensitivity UNCORRELATED within 53 healthy adults, R-squared 0.0003. Two arms
    that vary independently are not one gain apportioned between effectors.

CHRONOTROPIC SOURCES
  Cardiac baroreflex sensitivity, phenylephrine bolus, 117 healthy adults 23-77:
    Laitinen T, Hartikainen J, Vanninen E, Niskanen L, Geelen G, Lansimies E.
    Age and gender dependency of baroreflex sensitivity in healthy subjects.
    J Appl Physiol 1998;84(2):576-583. Men 15.0, women 10.2 ms/mmHg, P < 0.01.
  Cardiac and sympathetic arms are independent within individuals:
    Dutoit AP et al. Hypertension 2010;56(6):1118-23.

WHY RESETTING IS THE POINT
The baroreflex re-centres on prevailing pressure over hours to days. It is
therefore a FAST BUFFER, not a long-term regulator - which is exactly why
renal-body fluid feedback has to set long-run pressure (ADR 0007).

This is a falsifiable structural commitment: adding this component MUST NOT change
the 60-day salt-step steady state. If it does, the reflex is wrongly acting as a
long-term regulator and either the reset path or the gain is wrong.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams
using ..LedgerParams:
    BR_OPEN_LOOP_GAIN, BR_EFFECTOR_TAU, BR_RESET_TAU, BR_TPR_MAX_FRACTION,
    BR_HR_MAX_FRACTION, BR_CARDIAC_TAU, CV_MAP_SETPOINT

"""
    Baroreflex(; name, enabled = true, chronotropic = true, sex = :male)

Baroreflex with TWO effectors: total peripheral resistance and heart rate.

Inputs   MAP (mmHg)
Outputs  tpr_mod (unitless) - multiplicative modifier, 1.0 = no reflex action
         hr_mod  (unitless) - multiplicative modifier on heart rate, ADR 0022

Two states:
  `sp`      the reflex setpoint, which RESETS toward prevailing pressure
  `tpr_mod` the effector output, a first-order lag on the pressure error

Time base is DAYS. The effector tau (3 s) is roughly 1e-5 days against horizons of
tens of days - a stiffness ratio near 1e6, which is precisely the regime the
adaptive stiff solver of ADR 0001 exists for.

`enabled = false` fixes tpr_mod at 1.0, for the regression test that the reflex
does not alter long-run pressure. `chronotropic = false` fixes hr_mod at 1.0,
which recovers the pre-ADR-0022 model EXACTLY and is the diagnostic control the
chronotropic tests use.

THE CHRONOTROPIC ARM WAS PRE-REGISTERED AS STATELESS AND THE MODEL REFUSED.
Section 5 of validation/chronotropic_baroreflex_prereg.md made it algebraic by
default under directive 1.10 - a 200-600 ms effector is quasi-static against a
six-hour protocol - and put the burden on ADDING a lag. An algebraic hr_mod
closes an instantaneous loop through arterial pressure, CO -> MAP -> err ->
hr_mod -> CO, and structural_simplify resolved it by promoting Blood.CO to a
state. THE STATE WAS PAID EITHER WAY; it is now paid on a variable that means
something, with a sourced time constant. See the equations below and ADR 0022.
"""
function Baroreflex(; name, enabled::Bool = true, chronotropic::Bool = true,
                    sex::Symbol = :male)

    pars = @parameters begin
        G_br      = BR_OPEN_LOOP_GAIN
        tau_br    = BR_EFFECTOR_TAU / 86400.0      # s -> day
        tau_reset = BR_RESET_TAU                   # already days
        sat       = BR_TPR_MAX_FRACTION
        MAP_ref   = CV_MAP_SETPOINT
        # ADR 0022. SEX-SPECIFIC, and sexed TWICE OVER: BR.CARDIAC.SENSITIVITY is
        # a male/female pair (Laitinen: 15.0 against 10.2 ms/mmHg) and it is
        # converted through CV.HR.NOMINAL, which is a second pair. The two
        # dimorphisms are independent facts and neither is evidence for the other.
        G_hr      = LedgerParams.param(:BR_CARDIAC_GAIN, sex)
        hr_sat    = BR_HR_MAX_FRACTION
        tau_hr    = BR_CARDIAC_TAU / 86400.0       # s -> day
    end

    vars = @variables begin
        MAP(t)                          # mmHg  INPUT from cardiovascular
        sp(t)      = CV_MAP_SETPOINT    # mmHg  resetting setpoint  (STATE)
        cv_mod(t)                       # unitless INPUT from circadian clock
        tpr_mod(t) = 1.0                # unitless multiplier       (STATE)
        err(t)                          # mmHg
        drive(t)                        # unitless, saturated
        hr_drive(t)                     # unitless, saturated  ADR 0022
        hr_mod(t)  = 1.0                # unitless multiplier  ADR 0022  (STATE)
    end

    eqs = if enabled
        [
            # cv_mod is the circadian modulation of the reflex setpoint
            # (1.0 = no rhythm). Scaling the SETPOINT rather than adding to
            # MAP keeps the reflex a comparator: the clock moves what the
            # reflex defends, which is what a central circadian influence on
            # blood pressure means.
            err ~ MAP - sp * cv_mod,

            # Saturating characteristic. The real reflex is sigmoidal; tanh gives
            # the right shape with the right slope at the operating point and
            # cannot drive TPR negative under large excursions.
            #
            # THE SIGN IS NEGATIVE AND THAT IS THE WHOLE REFLEX. A rise in
            # pressure stretches the baroreceptors, RAISES afferent firing, and
            # INHIBITS sympathetic vasomotor outflow — so TPR falls. Positive
            # here makes the loop regenerative: closed-loop gain is G_br = 2.0,
            # which is unconditionally unstable, runs away to the tanh
            # saturation bound, and then bounces off the other branch as `sp`
            # resets. That was the state merged in PR #6 and it produced a
            # 40 mmHg mean arterial pressure. See the addendum to ADR 0009.
            drive ~ -sat * tanh(G_br * err / (sat * MAP_ref)),

            # Effector lag: 2-3 s sympathetic vasomotor response.
            D(tpr_mod) ~ ((1 + drive) - tpr_mod) / tau_br,

            # RESETTING. The setpoint drifts toward prevailing pressure over
            # hours to days. At steady state sp -> MAP, err -> 0, tpr_mod -> 1,
            # and the reflex exerts NO long-run influence. This single equation
            # is what keeps the baroreflex a buffer rather than a regulator.
            D(sp) ~ (MAP - sp) / tau_reset,
        ]
    else
        [err ~ 0.0, drive ~ 0.0, D(tpr_mod) ~ 0.0, D(sp) ~ 0.0]
    end

    # ---------------------------------------------------------------------
    # ADR 0022: THE CHRONOTROPIC ARM. Same error signal, second effector.
    #
    # ONE COMPARATOR, TWO EFFERENT LIMBS - which is what one reflex with two
    # arms means, and it is why `err` is shared rather than recomputed. The
    # circadian modulation of the setpoint therefore reaches heart rate too,
    # without a second path having to be declared for it.
    #
    # THE SIGN IS NEGATIVE AND IT IS THE WHOLE REFLEX, exactly as for the
    # vasomotor arm. A rise in pressure stretches the baroreceptors, RAISES
    # afferent firing, RAISES vagal outflow and withdraws cardiac sympathetic
    # drive, so HEART RATE FALLS. The addendum to ADR 0009 records what a
    # positive sign did to the vasomotor arm - a mean arterial pressure of
    # 40 mmHg, shipped and merged - and the suite now asserts this sign
    # rather than trusting the comment.
    #
    # IT HAS A LAG, AND THE PRE-REGISTRATION SAID IT WOULD NOT. Section 5 made
    # this arm ALGEBRAIC by default and put the burden on adding a lag, because
    # a 200-600 ms effector is quasi-static against a six-hour protocol and
    # directive 1.10 says a state is paid for on every future run.
    #
    # BUILDING IT REFUTED THAT, AND THE REASON IS STRUCTURAL RATHER THAN
    # PHYSIOLOGICAL. An algebraic hr_mod closes an INSTANTANEOUS LOOP through
    # arterial pressure:
    #
    #     CO -> MAP -> err -> hr_mod -> CO
    #
    # structural_simplify resolved that loop by promoting Blood.CO to a state,
    # so the "stateless" arm cost a state anyway — in another component, on a
    # variable where it meant nothing. The vasomotor arm never had this problem
    # because BR.EFFECTOR_TAU makes tpr_mod a state, and A LAG IS EXACTLY WHAT
    # BREAKS AN ALGEBRAIC LOOP.
    #
    # So the state is paid either way, and this is the honest place to put it.
    # BR.CARDIAC.TAU is La Rovere's 200-600 ms, the same sentence BR.EFFECTOR.TAU
    # comes from and the same one ADR 0009 cited when it lumped the arms.
    #
    # AT EVERY STEADY STATE THIS IS 1.0, because `sp` resets to MAP
    # and `err` goes to zero. That is not an approximation and it is not a
    # weakness of the arm - it is ADR 0009's central structural claim applied
    # to a second effector, and it is why the whole of this arm is invisible
    # to any resting assertion. It can only be tested in a transient.
    append!(eqs, chronotropic ?
        [hr_drive ~ -hr_sat * tanh(G_hr * err / (hr_sat * MAP_ref)),
         D(hr_mod) ~ ((1 + hr_drive) - hr_mod) / tau_hr] :
        [hr_drive ~ 0.0, D(hr_mod) ~ 0.0])

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    baroreflex_couplings()

Inbound pressure sensing is Mechanical - baroreceptors respond to wall stretch with
no meaningful lag at this resolution. The outbound effector path is Neurohumoral
with a 3 s time constant, so per ADR 0003 a multirate partition may cut across it.
"""
function baroreflex_couplings()
    return [
        Coupling(:cardiovascular, :baroreflex, Mechanical,
                 note = "MAP sensed by arterial baroreceptors; wall stretch, no lag"),
        Coupling(:baroreflex, :cardiovascular, Neurohumoral;
                 tau_seconds = BR_EFFECTOR_TAU,
                 gain_param = :BR_OPEN_LOOP_GAIN,
                 note = "sympathetic vasomotor outflow to TPR; 2-3 s effector delay"),
        # ADR 0022. DECLARED AS ITS OWN EDGE RATHER THAN FOLDED INTO THE ONE
        # ABOVE, because the two arms differ in the thing this graph exists to
        # record: the time constant. The partition rule of ADR 0003 uses tau to
        # decide what a multirate split may cut across, so lumping a 0.5 s vagal
        # limb into a 3 s sympathetic edge would hide the faster of the two from
        # the only check that reads it. They also differ in gain_param, and the
        # gains are independently measured and uncorrelated in people.
        Coupling(:baroreflex, :cardiovascular, Neurohumoral;
                 tau_seconds = BR_CARDIAC_TAU,
                 gain_param = :BR_CARDIAC_GAIN,
                 note = "vagal chronotropic outflow to heart rate; 200-600 ms"),
    ]
end
