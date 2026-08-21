"""
Renal sodium and water excretion - MINIMAL.

STRUCTURE SOURCES
  Filtration-reabsorption arithmetic: definitional.
  Pressure natriuresis: Guyton AC, Coleman TG, Granger HJ. Circulation: overall
    regulation. Annu Rev Physiol 1972;34:13-46. doi:10.1146/annurev.ph.34.030172.000305
  GFR autoregulation, UPPER BREAKPOINT ONLY: Roman RJ, Cowley AW Jr. Characterization
    of a new model for the study of pressure-natriuresis in the rat. Am J Physiol
    1985;248:F190-F198. PMID 3970209. doi:10.1152/ajprenal.1985.248.2.F190
    Rat, denervated, vasopressin/aldosterone/corticosterone/noradrenaline clamped.
    RPP raised 90 -> 160 mmHg with "no detectable changes in glomerular filtration
    rate, renal blood flow, or peritubular capillary pressure". 160 mmHg is the
    HIGHEST PRESSURE TESTED, so it is a lower bound on the true breakpoint rather
    than a measured breakpoint. The LOWER breakpoint and the piecewise FORM below
    are still unsourced - see ledger/relations.csv row Renal.GFR.

EVIDENCE (ADR 0006)
  E1  Pressure natriuresis exists and is steep. Multiply replicated.
  E1  GFR is autoregulated over a plateau of arterial pressure.
  E2  The UPPER limit is at or above 160 mmHg. Rat, Roman 1985, hormones clamped.
      No human study raises arterial pressure to find where autoregulation fails,
      and none may - the human literature only ever lowers it. Per ADR 0006
      (amended 2026-08-21) that is an ETHICAL CEILING, so the rat value is
      evidence with its species and range recorded, not debt awaiting a human
      replacement that cannot be run. It IS censored: 160 mmHg was the highest
      pressure tested, so the breakpoint is >= 160, not known to equal 160.
  --  The LOWER limit of 80 mmHg is a different matter and IS debt: no primary
      source in any species, and a 2025 human review argues the evidence for it
      is insufficient. The piecewise FORM is likewise uncited. See the ledger
      notes on RN.AUTOREG.LOWER and relations.csv row Renal.GFR.
  E1  Filtered load = GFR x plasma concentration; excretion = filtered - reabsorbed.
  --  The pressure natriuresis SLOPE is CALIBRATED, not measured. See ledger.

WHAT THIS DELIBERATELY OMITS
  Nephron segments, tubuloglomerular feedback, RAAS, ADH, potassium, acid-base,
  urea, and the circadian modulation in ADR 0005. All of those attach to this
  component later. None of them can be validated until this loop closes.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams:
    RN_GFR_NOMINAL, RN_NA_FRACTIONAL_REABSORPTION, RN_PRESSURE_NATRIURESIS_SLOPE,
    RN_AUTOREG_LOWER, RN_AUTOREG_UPPER, RN_H2O_OBLIGATORY_LOSS,
    CV_MAP_SETPOINT, BF_H2O_INTAKE_NOMINAL, BF_H2O_INSENSIBLE_LOSS

"""
    Renal(; name)

Filtration, pressure-dependent reabsorption, excretion.

Inputs   MAP (mmHg), C_Na (mEq/L), V_ecf (L)
Outputs  Na_excr (mEq/day), H2O_excr (L/day), GFR (L/day)

The whole component is one idea: filtered sodium minus reabsorbed sodium, where
reabsorption falls as pressure rises. That single dependence is what makes arterial
pressure self-regulating in the long run.
"""
function Renal(; name)

    pars = @parameters begin
        GFR0     = RN_GFR_NOMINAL
        FR_Na    = RN_NA_FRACTIONAL_REABSORPTION
        G_pn     = RN_PRESSURE_NATRIURESIS_SLOPE     # CALIBRATED - see ledger
        MAP_lo   = RN_AUTOREG_LOWER
        MAP_hi   = RN_AUTOREG_UPPER
        MAP_ref  = CV_MAP_SETPOINT
        V_min    = RN_H2O_OBLIGATORY_LOSS
        H2O_in   = BF_H2O_INTAKE_NOMINAL
        H2O_ins  = BF_H2O_INSENSIBLE_LOSS
    end

    vars = @variables begin
        # All algebraic - no defaults. MAP and C_Na arrive by connection.
        MAP(t)              # mmHg     INPUT from cardiovascular
        C_Na(t)             # mEq/L    INPUT from body fluids
        GFR(t)              # L/day
        Na_filtered(t)      # mEq/day
        Na_reabsorbed(t)    # mEq/day
        Na_excr(t)          # mEq/day  OUTPUT
        H2O_excr(t)         # L/day    OUTPUT
        FR_effective(t)     # unitless
    end

    eqs = [
        # GFR autoregulation: FLAT across the autoregulatory range, falling
        # proportionally below it.
        #
        # MAP_hi is 160 mmHg, not the textbook 180. 180 was a dog number carrying a
        # 'human' label and it sat OUTSIDE the 55-160 mmHg range over which the
        # pressure-natriuresis term below is evidenced - a kink in a region where
        # the equation it modifies has no support. Both breakpoint and natriuresis
        # form now come from the same paper (Roman and Cowley 1985) and terminate
        # at the same pressure. No effect at the operating point: MAP ~88-93 mmHg.
        #
        # The previous form multiplied by clamp(MAP,lo,hi)/MAP_ref, making GFR
        # PROPORTIONAL to pressure within the range - the opposite of
        # autoregulation, and it happened to equal GFR0 at MAP = MAP_ref so it
        # looked correct at the operating point.
        GFR ~ GFR0 * ifelse(MAP < MAP_lo, MAP / MAP_lo,
                     ifelse(MAP > MAP_hi, MAP / MAP_hi, 1.0)),

        Na_filtered ~ GFR * C_Na,

        # PRESSURE NATRIURESIS. Fractional reabsorption falls as pressure rises
        # above reference. This one line is the model's spine: it is what makes
        # long-run arterial pressure self-regulating rather than imposed.
        #
        # G_pn is normalised by filtered load so the slope is expressed in
        # mEq/day per mmHg of excretion, matching how it is reported.
        FR_effective ~ clamp(FR_Na - G_pn * (MAP - MAP_ref) / Na_filtered, 0.0, 1.0),

        Na_reabsorbed ~ FR_effective * Na_filtered,
        Na_excr       ~ Na_filtered - Na_reabsorbed,

        # Water excretion is a placeholder: intake minus insensible loss, floored
        # at the obligatory minimum. This is NOT osmoregulation - ADH does not
        # exist yet. It holds water balance closed so the sodium loop can be
        # tested. Replace when ADH lands.
        H2O_excr ~ max(V_min, H2O_in - H2O_ins),
    ]

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    renal_couplings()

Renal connections. The inbound pressure signal is Mechanical - glomerular
filtration responds to pressure hydraulically, with no lag at this resolution.
Per ADR 0003 a partition must not cut across it.
"""
function renal_couplings()
    return [
        Coupling(:cardiovascular, :renal, Mechanical,
                 note = "MAP drives filtration and pressure natriuresis; hydraulic"),
        Coupling(:renal, :bodyfluids, Conservation,
                 note = "Na and water excretion are mass fluxes out of ECF"),
    ]
end
