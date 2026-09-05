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
  E1  GFR RISES WITH EXTRACELLULAR VOLUME EXPANSION across chronic sodium
      intake in healthy humans. Four independent groups, human: van den Bosch
      2021 (PMID 34921521, n = 70, GFR and ECFV both by 125I-iothalamate),
      Roos 1985 (PMID 3907374, n = 8, inulin, an independent tracer),
      Redgrave 1985 (PMID 2985655, normotensive controls) and
      Pechere-Bertschi 2002/2003. The PHENOMENON is E1; the LINEAR FORM is a
      straight line between two measured intake levels, which is E2 inside
      the tested volume range and nothing at all outside it - hence the
      clamp on RN.GFR.VOLUME_RANGE below. Autoregulation is flat in PRESSURE
      and this term is a response to VOLUME; they are not in conflict, and
      the salt step never leaves the autoregulatory plateau.
      NOT tubuloglomerular feedback, which has the sign backwards: macula
      densa sensing LOWERS GFR when distal delivery rises. Ruled out in
      validation/renal_hemodynamics_prereg.md before the search, so it
      cannot be reached for later to rescue a null.
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

using ..LedgerParams
using ..LedgerParams:
    RN_GFR_NOMINAL, RN_NA_FRACTIONAL_REABSORPTION, RN_PRESSURE_NATRIURESIS_SLOPE,
    RN_URINE_SOLUTE_LOAD, RN_URINE_SOLUTE_NONNA, RN_URINE_OSM_PER_NA,
    RN_AUTOREG_LOWER, RN_AUTOREG_UPPER, ADH_URINE_OSM_MAX, RN_URINE_SOLUTE_LOAD,
    CV_MAP_SETPOINT, BF_H2O_INTAKE_NOMINAL, BF_H2O_INSENSIBLE_LOSS,
    BF_BODY_MASS_REFERENCE, BF_ECF_MASS_FRACTION, CV_ANP_NATRIURETIC_GAIN, RN_ANP_TAU,
    RN_GFR_VOLUME_SENSITIVITY, RN_GFR_VOLUME_RANGE

"""
    Renal(; name)

Filtration, pressure-dependent reabsorption, excretion.

Inputs   MAP (mmHg), C_Na (mEq/L), V_ecf (L), V_blood (L)
Outputs  Na_excr (mEq/day), H2O_excr (L/day), GFR (L/day)

The whole component is one idea: filtered sodium minus reabsorbed sodium, where
reabsorption falls as pressure rises. That single dependence is what makes arterial
pressure self-regulating in the long run.
"""
function Renal(; name, solute_tracking::Bool = true,
               body_mass = BF_BODY_MASS_REFERENCE,
               sex::Symbol = :male,
               anp_gain = CV_ANP_NATRIURETIC_GAIN)

    sz = size_factor(body_mass)

    pars = @parameters begin
        # EXTENSIVE. GFR is a flow and G_pn is an excretion per mmHg, so both
        # scale. They scale TOGETHER, which is the point: FR_effective subtracts
        # G_pn*(MAP-MAP_ref)/Na_filtered, and with G_pn ~ s and Na_filtered ~ s
        # that term is INVARIANT. The reabsorbed fraction stays intensive and the
        # pressure-natriuresis loop is size-free. See src/scaling.jl.
        #
        # GFR SCALING IS THE APPROXIMATION IN THIS FILE: clinically GFR is
        # normalised to body surface area, which grows sub-linearly with mass, so
        # linear scaling overstates the spread. Debt, not silently absorbed.
        GFR0     = sz * RN_GFR_NOMINAL
        FR_Na    = RN_NA_FRACTIONAL_REABSORPTION     # INTENSIVE - a fraction
        G_pn     = sz * RN_PRESSURE_NATRIURESIS_SLOPE  # CALIBRATED - see ledger
        MAP_lo   = RN_AUTOREG_LOWER
        MAP_hi   = RN_AUTOREG_UPPER
        MAP_ref  = CV_MAP_SETPOINT
        # GFR RESPONDS TO VOLUME, NOT ONLY TO PRESSURE. WIRED 2026-09-03.
        #
        # The row was entered on 2026-09-02 and NOTHING READ IT, which is the
        # state directive 1.11 calls not evidence about anything. Its blocker was
        # named on the row and has been discharged: this term multiplies the
        # model's volume excursion, which was 1.5-2.1x too large while G_vr was
        # calibrated, and G_vr is now sourced in healthy humans.
        #
        # S_gfr_v is INTENSIVE - a ratio of a fractional GFR change to a
        # fractional volume change, and a fraction does not care how big you are.
        # dV_gfr_max likewise. Only the REFERENCE VOLUME scales. The product
        # GFR0*(1 + S*dV/V) therefore stays proportional to size exactly as GFR0
        # does, which is what keeps the salt-step shift mass-invariant.
        S_gfr_v    = RN_GFR_VOLUME_SENSITIVITY
        # THE CENSORING BOUND, and it is a parameter rather than a literal for
        # the reason directive 1.4 gives. Outside the volumes van den Bosch
        # measured, the straight line has no support of any kind - so the
        # fractional deviation is clamped and the term saturates rather than
        # extrapolating. It is INERT on the chronic salt step, which moves ECF
        # about 2.4% either way against this 2.9%, and it BINDS on the acute
        # saline challenges, which move it about 9%.
        dV_gfr_max = RN_GFR_VOLUME_RANGE
        # EXTENSIVE. This is the same expression BodyFluids.jl initialises V_ecf
        # with, so the modifier is exactly 1.0 at the nominal operating point and
        # FR_Na - which is derived to close sodium balance against GFR0 - is not
        # silently re-based. It is written in the sz form rather than as
        # body_mass*f_ecf so that it reads identically to the line in
        # ensemble.jl's member_remake, which must reapply it.
        V_ecf_ref  = sz * BF_ECF_MASS_FRACTION * BF_BODY_MASS_REFERENCE
        # V_min (RN.H2O.OBLIGATORY_LOSS) IS DELIBERATELY NO LONGER A PARAMETER
        # HERE. It was a constant 0.5 L/day floor, which equalled
        # RN.URINE.SOLUTE_LOAD / ADH.URINE.OSM_MAX only while the solute load was
        # constant. The obligatory volume is a CONSEQUENCE of the load, not an
        # independent number, so it is now computed as Osm_load / U_max. The
        # ledger row survives as the reference-load value and the identity is
        # asserted in the test suite instead.
        #
        # THE LEDGER CAUGHT UP ON 2026-09-01. RN.H2O.OBLIGATORY_LOSS is now
        # DERIVED from U_max, which is the direction this code has used since the
        # solute load became variable; check_closure.py had been asserting the
        # inverse. U_max is now SOURCED (Tryding 1988, 982 mOsm/kg) rather than
        # back-computed from a conventional 0.5 L/day.
        U_max     = ADH_URINE_OSM_MAX
        # EXTENSIVE. Urea production tracks lean mass, so the non-sodium solute
        # load scales. osm_Na is INTENSIVE - it is mOsm per mEq, charge balance,
        # and charge balance does not care how big you are.
        Osm_ref   = sz * RN_URINE_SOLUTE_LOAD   # reference load, disabled branch
        Osm_nonNa = sz * RN_URINE_SOLUTE_NONNA  # urea + K salts + rest
        osm_Na    = RN_URINE_OSM_PER_NA         # INTENSIVE - charge balance
        H2O_in   = BF_H2O_INTAKE_NOMINAL
        H2O_ins  = BF_H2O_INSENSIBLE_LOSS
        # VOLUME-KEYED NATRIURESIS - ADR 0010, DIAGNOSTIC, DEFAULT ZERO.
        #
        # EXTENSIVE, in (mEq/day)/L, and it scales exactly as G_pn does and for the
        # same reason. G_anp = 0.0 recovers the pressure-only equation identically,
        # so every existing result is bit-identical unless this is passed a value.
        #
        # THIS IS NOT ADR 0010'S PROPOSED COMPONENT. It has no ANP state, no
        # secretion dynamics and no ledger row, and it must not acquire one until
        # the input coupling that record names as its blocker is sourced. It exists
        # so the question "would a volume-keyed path fix the acute natriuresis
        # deficit, and would it let G_pn fall?" can be ANSWERED rather than argued.
        # validation/challenges.jl section 3 is the deficit it was built to test.
        # INTENSIVE, AND THAT IS NOT THE OBVIOUS CHOICE. G_pn multiplies a
        # PRESSURE, which is intensive, so G_pn must scale for the product to be
        # a flow. G_anp multiplies a VOLUME, which already scales, so G_anp must
        # NOT scale or the term comes out as size squared. It was written
        # extensive first and the body-size testset caught it within one run:
        # the salt-step shift stopped being mass-invariant, 2.30 against 2.06
        # across the population mass range. src/scaling.jl exists for exactly
        # this and the rule is per-quantity, not per-component.
        G_anp      = anp_gain
        V_blood_ref = sz * LedgerParams.param(:CV_BLOOD_VOLUME_NOMINAL, sex)
        # THE LAG, AND IT IS WHY THE ALGEBRAIC FORM WAS REFUTED. A single
        # instantaneous gain cannot carry both limbs: the ACUTE natriuretic
        # response to an isotonic load implies about 300 (mEq/day)/L while the
        # CHRONIC steady-state sodium balance implies about 750, a factor of 2.5.
        # Drummer 1992 (PMID 1324562) says why - excretion of an acute isotonic
        # load takes DAYS, and sodium excretion is still elevated beyond 48 h.
        # A first-order lag makes the transient response SMALLER than the
        # steady-state gain, which is exactly the observed direction.
        tau_anp    = RN_ANP_TAU
    end

    vars = @variables begin
        # All algebraic - no defaults. MAP and C_Na arrive by connection.
        MAP(t)              # mmHg     INPUT from cardiovascular
        C_Na(t)             # mEq/L    INPUT from body fluids
        # WIRED 2026-09-02. The component docstring above has claimed a volume input
        # since the file was written and it was never connected - the kidney could
        # not see volume at all. Found by running validation/challenges.jl, not by
        # any gate. RE-KEYED from V_ecf to V_blood the same day: ATRIAL STRETCH IS
        # INTRAVASCULAR, ADR 0010 proposed V_blood, and the two differ by
        # f_pv = 0.211, so a gain entered against the wrong one is wrong by 4.7x.
        V_blood(t)          # L        INPUT from cardiovascular
        # WIRED 2026-09-03, and it is a SECOND volume input rather than a reuse of
        # V_blood. The two are keyed to different measurements and must not be
        # conflated: the natriuretic path above is keyed to V_blood because atrial
        # stretch is intravascular, and this term is keyed to V_ecf because that
        # is what van den Bosch measured by iothalamate. They differ by
        # f_pv = 0.211, so a sensitivity entered against the wrong one is wrong by
        # 4.7x - the same error this file already records being made and caught.
        V_ecf(t)            # L        INPUT from body fluids
        fr_mod(t)           # unitless INPUT from RAAS (0.0 = no RAAS action)
        u_osm(t)            # mOsm/kg  INPUT from ADH (urine osmolality)
        renal_mod(t)        # unitless INPUT from circadian clock (1.0 = no rhythm)
        GFR(t)              # L/day
        gfr_vol_mod(t)      # unitless GFR multiplier from ECF volume
        Na_filtered(t)      # mEq/day
        Na_reabsorbed(t)    # mEq/day
        Na_excr(t)          # mEq/day  OUTPUT
        H2O_excr(t)         # L/day    OUTPUT
        FR_effective(t)     # unitless
        Osm_load(t)         # mOsm/day urinary solute load - NOW TRACKS SODIUM
        # STATE, added 2026-09-02. The lagged volume-keyed natriuretic signal, in
        # mEq/day. Its steady-state value is G_anp*(V_blood - V_blood_ref), so the
        # CHRONIC gain is G_anp exactly and the ACUTE gain is smaller by the lag.
        anp_sig(t) = 0.0
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
                     ifelse(MAP > MAP_hi, MAP / MAP_hi, 1.0)) * gfr_vol_mod,

        # THE VOLUME RESPONSE, ledger relation Renal.gfr_vol_mod.
        #
        # It is a SEPARATE equation rather than another factor written inline, and
        # that is a provenance decision rather than a stylistic one. Renal.GFR is
        # in check_relations.py's GRANDFATHERED_UNSOURCED list because its
        # piecewise autoregulatory FORM is uncited. This term is sourced, and
        # folding it into that row would have filed a sourced relation under a
        # permanent exemption. Split, it carries its own form_citation and its own
        # form_status and the exemption keeps shrinking rather than absorbing.
        # structural_simplify aliases it away, so it costs no state.
        #
        # SIGN. Volume above reference RAISES GFR, which raises filtered load and
        # therefore excretion. It is a NEGATIVE feedback on volume, in the same
        # direction as pressure natriuresis and the ADR 0010 path, and it reaches
        # excretion through a THIRD route: the filtered load rather than the
        # reabsorbed fraction.
        #
        # WHY THIS BITES WHEN HANDOVER 3.5 SAID GFR CANCELS. It cancels BETWEEN
        # BUILDS, because FR_Na is derived as 1 - intake/(GFR0*C_Na) and absorbs
        # any change in GFR0. It does NOT cancel WITHIN a run: a GFR that moves
        # while FR_Na is fixed changes Na_filtered*(1 - FR_Na) directly. That is
        # the same shape of error as the haematocrit one in 3.8 - a quantity that
        # cancels at the operating point need not cancel in the response.
        gfr_vol_mod ~ 1.0 + S_gfr_v * clamp((V_ecf - V_ecf_ref) / V_ecf_ref,
                                            -dV_gfr_max, dV_gfr_max),

        Na_filtered ~ GFR * C_Na,

        # PRESSURE NATRIURESIS. Fractional reabsorption falls as pressure rises
        # above reference. This one line is the model's spine: it is what makes
        # long-run arterial pressure self-regulating rather than imposed.
        #
        # G_pn is normalised by filtered load so the slope is expressed in
        # mEq/day per mmHg of excretion, matching how it is reported.
        # fr_mod is the RAAS tubular increment (ADR 0006 build order item 4).
        # It is ADDITIVE and escape drives it to zero at steady state, so it
        # moves the transient and leaves every steady state exactly where it
        # was. fr_mod = 0.0 recovers the pre-RAAS equation identically.
        # renal_mod IS APPLIED TO THE EXCRETED FRACTION, NOT TO REABSORPTION.
        # The component docstring calls it a multiplier on tubular reabsorption
        # CAPACITY, and taken literally that is unusable: FR_Na is 0.9919 and the
        # ledger amplitude is 0.25, so FR_Na*1.25 = 1.24 clamps to 1.0 and sodium
        # excretion stops dead. The measured rhythm is a rhythm in EXCRETION -
        # cosinor studies report peak-to-trough ratios in UNaV - so it belongs on
        # (1 - FR_Na), which is 0.0081. A 25% swing there is a 25% swing in
        # excretion and a 0.2% swing in reabsorption, which is the physiological
        # reading. renal_mod = 1.0 recovers the previous equation exactly.
        # The anp_sig term is the volume-keyed natriuresis of ADR 0010. It enters
        # with the same sign and the same normalisation as the pressure term:
        # Na_excr gains anp_sig, whose target is G_anp*(V_blood - V_blood_ref), so
        # sodium excretion rises when BLOOD volume is above its reference,
        # independently of pressure. G_anp = 0 recovers the pressure-only form.
        #
        # CORRECTED 2026-09-03. This comment read "G_anp*(V_ecf - V_ecf_ref)" and
        # said "extracellular volume". The path was RE-KEYED to V_blood on
        # 2026-09-02, because atrial stretch is intravascular, and the comment was
        # not carried over. It was harmless while no V_ecf_ref existed and stopped
        # being harmless the moment one did: this file now holds BOTH volume
        # references, for two different paths, and they differ by f_pv = 0.211.
        # HANDOVER section 5 item 11 - a name carrying a convention its value
        # contradicts, twice recorded, and no gate sees it.
        FR_effective ~ clamp(1.0 - (1.0 - FR_Na) * renal_mod + fr_mod -
                             G_pn * (MAP - MAP_ref) / Na_filtered -
                             anp_sig / Na_filtered, 0.0, 1.0),

        # First-order approach to the volume-keyed natriuretic target.
        D(anp_sig) ~ (G_anp * (V_blood - V_blood_ref) - anp_sig) / tau_anp,

        Na_reabsorbed ~ FR_effective * Na_filtered,
        Na_excr       ~ Na_filtered - Na_reabsorbed,

        # OSMOREGULATION (ADR 0006 build order item 5). The placeholder that
        # stood here - intake minus insensible loss, floored - was replaced on
        # 2026-08-25 when ADH landed.
        #
        # Urine volume is solute excretion divided by urine concentration, and
        # ADH sets the concentration. That is where the nonlinearity lives: the
        # THE URINE SOLUTE LOAD NOW TRACKS SODIUM EXCRETION.
        # It was the constant RN.URINE.SOLUTE_LOAD, and its own ledger note named
        # that as the load-bearing assumption of the ADH component: urine volume
        # is solute load over urine osmolality, so freezing the numerator made the
        # model under-respond to a salt load on the WATER side while responding
        # correctly on the sodium side. The note said to consider making it depend
        # on Na_excr. This is that.
        #
        # The coefficient of 2 is CHARGE BALANCE, not a fit: every excreted Na+
        # leaves with an accompanying anion, mostly chloride, so a mEq of sodium
        # carries about two milliosmoles. Osm_nonNa is urea plus potassium salts
        # plus the remainder and is STILL CONSTANT, so protein intake still moves
        # nothing here.
        #
        # Osm_nonNa is pinned as a RESIDUAL so that the total returns exactly
        # 600.0 mOsm/day at the mid salt arm. That is deliberate: U_max, U_base
        # and k_adh are all DERIVED from the reference load and four closure
        # checks depend on it, so the reference must not move. The mid arm is
        # unchanged to the last digit; the high and low arms are what move.
        # WHY THIS IS BEHIND THE SAME SWITCH AS ADH (ADR 0008). The pre-ADH
        # water placeholder was a CONSTANT 1.7 L/day - intake minus insensible
        # loss - and it is recovered by holding u_osm at U_base so that
        # Osm_load/U_base returns exactly that. A VARIABLE Osm_load breaks that
        # recovery, because the numerator then moves while the denominator is
        # pinned. The constant load and the pinned urine osmolality are two
        # halves of ONE placeholder, so they belong to one switch; splitting
        # them would leave a disabled branch that reproduces neither the old
        # model nor the new one. assemble.jl wires solute_tracking from the adh
        # flag for exactly this reason.
        # solute_tracking is a build-time Bool, so this resolves to ONE concrete
        # equation at model construction - not a runtime branch in the compiled
        # system. Same pattern as the enabled/disabled branches elsewhere.
        Osm_load ~ solute_tracking ? Osm_nonNa + osm_Na * Na_excr : Osm_ref,

        # Urine volume is solute excretion divided by urine concentration, and
        # ADH sets the concentration. That is where the nonlinearity lives: the
        # same change in u_osm moves litres at the dilute end and millilitres at
        # the concentrated end.
        #
        # THE FLOOR NOW TRACKS THE LOAD. It was the constant V_min = 0.5 L/day,
        # which was exactly RN.URINE.SOLUTE_LOAD / ADH.URINE.OSM_MAX while the
        # load was constant. With a variable load the obligatory volume is
        # Osm_load / U_max by definition - the volume needed to carry THIS solute
        # load at maximal concentrating ability - and a fixed 0.5 would bind
        # spuriously on the low-salt arm, where the load falls to 498 mOsm/day and
        # 498/1200 = 0.415 L/day. V_min is retained only to assert that identity
        # at the reference load; see the test.
        H2O_excr ~ max(Osm_load / U_max, Osm_load / u_osm),
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
        # DECLARED 2026-09-03. bodyfluids -> renal already existed for C_Na and is
        # declared in BodyFluids.jl; V_ecf now drives filtration through
        # gfr_vol_mod as well, and the note there already said it did.
        Coupling(:bodyfluids, :renal, Conservation,
                 note = "V_ecf raises GFR (RN.GFR.VOLUME_SENSITIVITY); algebraic"),
    ]
end
