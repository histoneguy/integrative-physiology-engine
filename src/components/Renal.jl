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
    RN_URINE_SOLUTE_LOAD, RN_URINE_SOLUTE_NONNA, RN_URINE_OSM_PER_NA, RN_URINE_SOLUTE_NONNA_SLOPE,
    RN_AUTOREG_LOWER, RN_AUTOREG_UPPER, ADH_URINE_OSM_MAX, RN_URINE_SOLUTE_LOAD,
    CV_MAP_SETPOINT, BF_H2O_INTAKE_NOMINAL, BF_H2O_INSENSIBLE_LOSS,
    BF_BODY_MASS_REFERENCE, BF_ECF_MASS_FRACTION, CV_VOLUME_NATRIURETIC_GAIN, RN_VOLUME_NATRIURESIS_TAU,
    RN_GFR_VOLUME_SENSITIVITY, RN_GFR_VOLUME_RANGE, RN_NA_MACULA_DENSA_FRACTION,
    RN_NA_PROXIMAL_SALT_SENSITIVITY, RAAS_PRA_REFERENCE,
    RN_NA_PROXIMAL_DELIVERY,
    BF_NA_PLASMA_SETPOINT, BF_NA_INTAKE_NOMINAL

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
               vn_gain = CV_VOLUME_NATRIURETIC_GAIN,
               anp_convexity = 0.0,
               anp_adaptation::Bool = false,
               anp_adapt_fraction = 0.0, anp_adapt_tau = 1.0)

    # SURFACE-like for filtration, the pressure-natriuresis slope and the solute
    # load; MASS-like for the reference volumes. src/scaling.jl carries the
    # closure argument, and G_vn below is the one parameter that needs both.
    sz = size_factor(body_mass)
    mz = mass_factor(body_mass)

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
        # ADR 0021. INTENSIVE - a fraction. It sets the SCALE of distal delivery
        # and is NOT separately identifiable from the macula densa gain that
        # multiplies the fractional deviation; see its ledger note.
        f_md     = RN_NA_MACULA_DENSA_FRACTION
        # SOURCED IN HEALTHY HUMANS, Shirley 2002, by lithium clearance. It is a
        # DIFFERENT SEGMENT from f_md above: lithium stops at the end of the
        # proximal tubule, the macula densa sits past the loop, and the loop takes
        # most of what the proximal tubule passes on. 0.26 and 0.10 are both real.
        f_prox   = RN_NA_PROXIMAL_DELIVERY
        k_prox   = RN_NA_PROXIMAL_SALT_SENSITIVITY
        pra_ref_p = RAAS_PRA_REFERENCE
        # EXTENSIVE and SURFACE-like, exactly as GFR0 is: it is a filtered flux.
        # The ratio in md_drive is therefore size-free.
        Na_distal_ref = sz * RN_GFR_NOMINAL * BF_NA_PLASMA_SETPOINT *
                        (1.0 - RN_NA_MACULA_DENSA_FRACTION)
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
        V_ecf_ref  = mz * BF_ECF_MASS_FRACTION * BF_BODY_MASS_REFERENCE
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
        # THE NON-SODIUM REMAINDER RESPONDS TO SODIUM. Sourced 2026-09-17 from
        # Kitada 2017 (PMC5409074, read in full), validation/solute_limb_prereg.md.
        # EXTENSIVE and per kilogram, because urea production tracks lean mass -
        # exactly as Osm_nonNa above scales, and for the same reason.
        #
        # RN.URINE.SOLUTE_NONNA's note has said since 2026-09-16 that holding this
        # remainder CONSTANT makes the model over-respond on the solute limb by
        # about 30 percent, and that the fix was 'not built'. This is it, as the
        # measured SLOPE and not as the urea-recycling mechanism, which stays
        # unsourced and is said so on the row.
        k_nonNa   = mz * RN_URINE_SOLUTE_NONNA_SLOPE * BF_BODY_MASS_REFERENCE
        # The reference excretion the deviation is taken from. At steady state
        # excretion equals intake, so this is the nominal intake and the new term
        # is IDENTICALLY ZERO at the operating point - which is what keeps
        # RN.URINE.SOLUTE_LOAD at exactly 930 and leaves every ADH constant
        # derived from it untouched. Branch U2: if one moves, THIS is wrong.
        Na_excr_ref = sz * BF_NA_INTAKE_NOMINAL
        H2O_in   = BF_H2O_INTAKE_NOMINAL
        H2O_ins  = BF_H2O_INSENSIBLE_LOSS
        # VOLUME-KEYED NATRIURESIS - ADR 0010, DIAGNOSTIC, DEFAULT ZERO.
        #
        # EXTENSIVE, in (mEq/day)/L, and it scales exactly as G_pn does and for the
        # same reason. G_vn = 0.0 recovers the pressure-only equation identically,
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
        # a flow. G_vn multiplies a VOLUME, which already scales, so G_vn must
        # NOT scale or the term comes out as size squared. It was written
        # extensive first and the body-size testset caught it within one run:
        # the salt-step shift stopped being mass-invariant, 2.30 against 2.06
        # across the population mass range. src/scaling.jl exists for exactly
        # this and the rule is per-quantity, not per-component.
        # STILL INTENSIVE UNDER TWO-FACTOR SCALING, AND THE ARGUMENT FOR IT WAS
        # GOT WRONG ONCE ON 2026-09-05 BEFORE THE SUITE CAUGHT IT.
        #
        # The tempting reasoning: G_vn turns a blood VOLUME excess into a sodium
        # EXCRETION, volume is mass-like and excretion is surface-like, so the
        # gain should carry sz/mz. That is wrong, and it is wrong because what
        # this gain multiplies is not a volume but a DEVIATION.
        #
        # V_blood and V_blood_ref are both mass-like and cancel exactly at the
        # operating point for any body size. What survives is the deviation
        # produced by a sodium load, and that is SODIUM-DRIVEN: a salt step
        # scaled to the individual moves the volume by an amount that scales as
        # sz, not as mz. Divided by Na_filtered, which is also sz, the term is
        # invariant only if the gain is intensive.
        #
        # THE OPERATING POINT HIDES THIS ENTIRELY, which is why it is worth the
        # paragraph: with sz/mz the resting state of every body size is still
        # exactly right and only the salt-step RESPONSE moves - 2.040 mmHg at 85 kg
        # against 1.886 at the reference. The body-size testset's invariance
        # assertion is the only thing in the repository that could have seen it.
        G_vn      = vn_gain
        # CONVEXITY OF THE VOLUME-NATRIURESIS RELATION. DIAGNOSTIC, DEFAULT ZERO,
        # AND ZERO IS BIT-IDENTICAL TO THE LINEAR FORM. It exists on exactly the
        # precedent G_vn itself was introduced on: so that a question can be
        # ANSWERED rather than argued, without a ledger row and without a claim.
        #
        # THE QUESTION. HANDOVER section 3.46 measured that this model clears an
        # acute isotonic load with a volume half-life of 13.10 h against a measured
        # 7 h, and that no single parameter fixes it - the acute response needs
        # about THREE TIMES the gain the chronic response permits. That requires a
        # response per litre that is LARGER at a large excursion than at a small
        # one, which is a CONVEX relation.
        #
        # AND IT IS THE OPPOSITE OF WHAT ADR 0010 SPECIFIES. That record says the
        # real path is "lagged or SATURATING", and a saturating path delivers LESS
        # per litre acutely. validation/volume_natriuresis_form_prereg.md section 1
        # records the correction and why the record got it backwards.
        #
        # INTENSIVE, and it has to be: it multiplies a RATIO of a volume to a
        # volume, and a ratio does not care how big you are. Getting this wrong is
        # section 3.30's mistake, which the body-size testset caught once already.
        #
        # THIS IS NOT A PROPOSED MODEL TERM, AND IT WAS REFUTED THE DAY IT WAS
        # WRITTEN. Section 6 branch F2: if the curvature it imposes on the chronic
        # pressure-sodium relation would have been visible in the human data, the
        # convex form is refuted. MEASURED, bench/volume_natriuresis_stage2.jl,
        # with G_vn re-solved to hold the chronic anchor at every point:
        #
        #   c_anp     G_vn   t1/2 h   bend %   slope ratio 38-103 : 154-230
        #   0         589.2   13.05      2.1%   1.11
        #   50        272.4    8.93     12.2%   0.54
        #   200       103.9    7.78     18.3%   0.41
        #   400        56.8    7.55     19.8%   0.39
        #
        # It never reaches 7 h - it plateaus near 7.5 - and buying even 8.9 h costs
        # a chronic relation whose slope at the top of the dietary range is TWICE
        # its slope at the bottom. The human relation is quoted as ONE slope per
        # 100 mmol/day by all three meta-analyses. REFUTED.
        #
        # THE PRE-REGISTRATION PREDICTED THE BEND AND GOT ITS DIRECTION WRONG.
        # Section 3.1 said the relation would go CONCAVE; it goes CONVEX - the
        # low-intake slope collapses 2.11 -> 1.05 while the high-intake slope rises
        # 1.90 -> 2.72. The refutation stands on the SIZE of the bend, which is what
        # the test was about; the mechanism of its sign is NOT established here and
        # is not guessed at.
        #
        # KEPT AT DEFAULT ZERO so the refutation can be re-run, on the precedent
        # G_vn itself was introduced on. It is not a candidate.
        c_anp      = anp_convexity
        # FORM (B), THE ADAPTING TERM. DIAGNOSTIC, BEHIND anp_adaptation, AND THE
        # DEFAULT BUILD IS BIT-IDENTICAL - with the flag off the extra state is
        # eliminated by structural_simplify exactly as bf.Na_store is, so the model
        # is still 12 states. Same pattern as ADR 0004's storage compartment.
        #
        # WHAT IT IS. The natriuretic drive adapts: a slow state subtracts a fixed
        # FRACTION of the sustained signal, so a RAPID volume excursion sees the
        # full gain and a SUSTAINED one sees (1 - k_adapt) of it. The acute-to-
        # chronic ratio is therefore 1/(1 - k_adapt) exactly, and HANDOVER 3.46
        # measured that the acute response needs about THREE times the chronic -
        # which is k_adapt = 2/3.
        #
        # WHY THIS FORM AND NOT THE CONVEX ONE. validation/volume_natriuresis_form_prereg.md
        # section 3.1 fixed the discriminator before either was built: a static
        # convex gain BENDS the chronic pressure-sodium relation, an adapting one
        # leaves it STRAIGHT, and the human relation is quoted as a single slope per
        # 100 mmol/day by all three meta-analyses. The convex form was built and
        # refuted - see c_anp above. This one is linear in the excursion at every
        # timescale, so it cannot bend the chronic relation at all, and that is a
        # PREDICTION this pass must check rather than assume.
        #
        # IT IS ALSO WHAT THE MODEL ALREADY DOES ELSEWHERE. ra.esc is an escape
        # state on the RAAS tubular arm, and fr_mod goes to zero at steady state by
        # the same device. This is that mechanism on the volume-keyed path.
        #
        # BOTH ROWS ARE INTENSIVE. k_adapt is a fraction; tau_adapt is a time. And
        # NEITHER HAS A LEDGER ROW, on the precedent G_vn itself was introduced on:
        # a diagnostic may exist without one, and must not acquire one until it is
        # sourced rather than solved.
        k_adapt    = anp_adapt_fraction
        tau_adapt  = anp_adapt_tau
        V_blood_ref = mz * LedgerParams.param(:CV_BLOOD_VOLUME_NOMINAL, sex)
        # THE LAG, AND IT IS WHY THE ALGEBRAIC FORM WAS REFUTED. A single
        # instantaneous gain cannot carry both limbs: the ACUTE natriuretic
        # response to an isotonic load implies about 300 (mEq/day)/L while the
        # CHRONIC steady-state sodium balance implies about 750, a factor of 2.5.
        # Drummer 1992 (PMID 1324562) says why - excretion of an acute isotonic
        # load takes DAYS, and sodium excretion is still elevated beyond 48 h.
        # A first-order lag makes the transient response SMALLER than the
        # steady-state gain, which is exactly the observed direction.
        tau_vn    = RN_VOLUME_NATRIURESIS_TAU
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
        Na_prox_out(t)      # mEq/day  END-PROXIMAL sodium delivery (Shirley 2002)
        Na_distal(t)        # mEq/day  macula densa sodium delivery, ADR 0021
        md_drive(t)         # unitless OUTPUT to raas - the macula densa signal
        pra(t)              # unitless INPUT from raas - normalised renin activity
        f_prox_eff(t)       # unitless end-proximal delivery fraction, salt-responsive
        Na_excr(t)          # mEq/day  OUTPUT
        H2O_excr(t)         # L/day    OUTPUT
        FR_effective(t)     # unitless
        Osm_load(t)         # mOsm/day urinary solute load - NOW TRACKS SODIUM
        # STATE, added 2026-09-02. The lagged volume-keyed natriuretic signal, in
        # mEq/day. Its steady-state value is G_vn*(V_blood - V_blood_ref), so the
        # CHRONIC gain is G_vn exactly and the ACUTE gain is smaller by the lag.
        vn_sig(t) = 0.0
        anp_adapt(t) = 0.0   # FORM (B) - zero and inert unless anp_adaptation
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
        # The vn_sig term is the volume-keyed natriuresis of ADR 0010. It enters
        # with the same sign and the same normalisation as the pressure term:
        # Na_excr gains vn_sig, whose target is G_vn*(V_blood - V_blood_ref), so
        # sodium excretion rises when BLOOD volume is above its reference,
        # independently of pressure. G_vn = 0 recovers the pressure-only form.
        #
        # CORRECTED 2026-09-03. This comment read "G_vn*(V_ecf - V_ecf_ref)" and
        # said "extracellular volume". The path was RE-KEYED to V_blood on
        # 2026-09-02, because atrial stretch is intravascular, and the comment was
        # not carried over. It was harmless while no V_ecf_ref existed and stopped
        # being harmless the moment one did: this file now holds BOTH volume
        # references, for two different paths, and they differ by f_pv = 0.211.
        # HANDOVER section 5 item 11 - a name carrying a convention its value
        # contradicts, twice recorded, and no gate sees it.
        FR_effective ~ clamp(1.0 - (1.0 - FR_Na) * renal_mod + fr_mod -
                             G_pn * (MAP - MAP_ref) / Na_filtered -
                             vn_sig / Na_filtered, 0.0, 1.0),

        # DISTAL SODIUM DELIVERY, ADR 0021. THE SODIUM EQUATION ABOVE IS UNTOUCHED
        # AND THAT IS THE POINT: this defines a VARIABLE, it does not restructure
        # anything, so the split is neutral in the strongest possible sense and
        # every existing result is bit-identical by construction rather than by
        # arithmetic that has to be checked.
        #
        # Delivery to the macula densa is the filtered load less what the proximal
        # tubule and loop reabsorb.
        #
        # THE PRESSURE AND NATRIURETIC-PEPTIDE TERMS ARE DELIBERATELY ABSENT, AND
        # THAT IS A CORRECTION - they were here for one afternoon and the acute
        # saline challenge refuted them the first time it was run. ADR 0021
        # amendment A6 and HANDOVER section 3.32 record it in full.
        #
        # The argument is a priori and the run is only how it was noticed. G_pn and
        # G_vn are CALIBRATED AGAINST SODIUM EXCRETION - the chronic salt step and
        # Lobo's six-hour time course. The macula densa arm returns to sodium
        # excretion through renin, aldosterone and fr_mod. Feeding a gain that was
        # fitted to an excretion into a loop that produces that same excretion
        # counts the measurement twice, and ADR 0021 decision 1 forbids changing
        # what those two rows mean. The pressure term double-counts twice over:
        # MAP already reaches renin through the rectified arm this record promised
        # to leave untouched and to add to ALONGSIDE, and a term in MAP is not
        # alongside.
        #
        # WHAT IS LEFT IS THE FILTERED LOAD, and it carries 41% of the chronic
        # signal on its own - 2046 to 2171 mEq/day between 38 and 230 mmol/day of
        # sodium - because GFR rises with volume. That path is admissible where the
        # other two are not: RN.GFR.VOLUME_SENSITIVITY was calibrated against GFR,
        # not against sodium excretion, so the loop does not re-use its own fit.
        #
        # IT CONTAINS NO NEW INFORMATION ABOUT SEGMENTAL HANDLING and ADR 0021's
        # disqualification section says so. f_md is assumed and is not
        # separately identifiable from the gain that reads this signal.
        # END-PROXIMAL DELIVERY, REPORTED. This is what lithium clearance measures
        # in humans and it is the one segmental quantity in this model with a human
        # number behind it. It is an OBSERVABLE and nothing reads it: the tubule is
        # still one lumped reabsorption, so a segmental delivery cannot yet do work.
        # Wiring it as a reported quantity rather than leaving the row unconnected
        # is the ADR 0006 rule - a row nothing reads is the Circadian failure.
        # END-PROXIMAL DELIVERY RESPONDS TO SALT, 2026-09-20, and until now it did
        # not. Folkerd 1995 (PMID 7733329), six normal subjects, five days per diet:
        # fractional lithium excretion 8.3 +/- 2.9 percent on 31 mmol/day of sodium
        # against 18.0 +/- 5.1 on 357, P < 0.05. Chiolero 2000 (PMID 11040249)
        # confirmed the direction in 27 normotensives. This quantity MORE THAN
        # DOUBLES across the human dietary range and the model had it constant.
        #
        # KEYED TO pra AND NOT TO SODIUM INTAKE. Angiotensin II stimulates proximal
        # reabsorption - what Hall 1977 and Hall 1984 measured - so the mechanism is
        # already here, and keying to the intake parameter would have the tubule
        # respond to a number the body cannot see.
        #
        # ZERO DEVIATION AT THE OPERATING POINT by construction, so Shirley 2002's
        # 0.26 still holds exactly at rest and nothing pinned moves.
        #
        # AND IT MUST LEAVE md_drive ALONE. Vallon 2002 (PMID 12089382): in normal
        # rats dietary salt does not affect the tubuloglomerular feedback signal.
        # Both results hold together only if the thick ascending limb absorbs the
        # extra proximal delivery - which is why f_prox_eff feeds Na_prox_out and
        # NOT Na_distal. f_md is a separate fraction of the FILTERED load, so the
        # macula densa signal is untouched by construction.
        f_prox_eff ~ clamp(f_prox * (1.0 + k_prox * (pra_ref_p - pra)), 0.02, 0.60),

        Na_prox_out ~ Na_filtered * f_prox_eff * renal_mod,

        Na_distal ~ Na_filtered * (1.0 - f_md) * renal_mod,

        # THE MACULA DENSA SIGNAL, as a FRACTIONAL deficit of delivery below its
        # reference. Fractional on purpose: a dimensionless drive cannot inherit a
        # body-size scaling, which is the mistake section 3.30 records making with
        # G_vn and which is avoided here by construction rather than by care.
        #
        # SIGNED, NOT RECTIFIED, unlike the pressure arm - AND THAT IS NOW KNOWN
        # TO BE WRONG. This comment used to read "nothing found says the macula
        # densa arm does [plateau], and inventing a threshold to match the other
        # arm's shape would be a functional form chosen here."
        #
        # LORENZ 1990 IS THE SOMETHING FOUND (PMID 2197878, full text read,
        # macula_densa_lorenz_prereg.md). Isolated perfused rabbit juxtaglomerular
        # apparatus, pressure and renal nerves physically absent. Renin secretion
        # was 2.2 nGU/min at 141 mM Na+ and 1.9 at 80 mM - NO EFFECT - while the
        # whole 5.2-fold response ran between 80 and 24 mM. THE ARM PLATEAUS ABOVE
        # A MEASURED THRESHOLD, exactly as the pressure arm does.
        #
        # IT IS NOT RECTIFIED HERE ANYWAY, AND THE REASON IS NOT INERTIA. Lorenz's
        # threshold is a CONCENTRATION, 80 mM, and he reports the full response
        # occurring "within the concentration range normally occurring at the
        # macula densa" - so the normal operating point sits BELOW the threshold on
        # the steep limb. md_drive is zero at ITS reference by construction, and
        # where that reference lies against 80 mM is unknowable without a macula
        # densa concentration. Rectifying at md_drive = 0 would put the threshold
        # at the operating point, which is the wrong place, and would be precisely
        # the invented form the old comment warned against.
        #
        # AND THE DEEPER PROBLEM IS THE VARIABLE, NOT THE SHAPE. Lorenz's series 3
        # dissociated them: from period 2 to 3 sodium DELIVERY ROSE 51 percent
        # (1,197 -> 1,811 peq/min) and renin rose 3.2-fold anyway, because
        # concentration fell 54 mM. His conclusion is that renin "responds with a
        # larger change to alterations in NaCl concentration than in NaCl delivery
        # or fluid flow rate." THIS SIGNAL IS KEYED TO DELIVERY. Concentration is
        # delivery over distal flow, and this model lumps water reabsorption and
        # has no distal flow, so the right variable cannot be computed from what
        # exists. That is the structural requirement, recorded rather than faked.
        md_drive ~ (Na_distal_ref - Na_distal) / Na_distal_ref,

        # First-order approach to the volume-keyed natriuretic target.
        # c_anp = 0.0 recovers (G_vn*(V_blood - V_blood_ref) - vn_sig)/tau_vn
        # EXACTLY, so every existing result is bit-identical by construction.
        D(vn_sig) ~ (G_vn * (V_blood - V_blood_ref) *
                      (1.0 + c_anp * abs(V_blood - V_blood_ref) / V_blood_ref)
                      - anp_adapt - vn_sig) / tau_vn,

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
        Osm_load ~ solute_tracking ?
                   Osm_nonNa + osm_Na * Na_excr +
                   k_nonNa * (Na_excr - Na_excr_ref) : Osm_ref,

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

    # FORM (B). With the flag off this is D(anp_adapt) ~ 0 on a state initialised at
    # zero, which structural_simplify eliminates - the default build stays at 12
    # states and every existing result is bit-identical by construction.
    append!(eqs, anp_adaptation ?
            [D(anp_adapt) ~ (k_adapt * G_vn * (V_blood - V_blood_ref) - anp_adapt) /
                            tau_adapt] :
            [D(anp_adapt) ~ 0.0])

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
        # DECLARED 2026-09-05, ADR 0021. THE MACULA DENSA ARM, and it is the
        # second of the two renin inputs HANDOVER section 7 names as missing.
        # Mechanical rather than Neurohumoral because the signal is sensed at the
        # juxtaglomerular apparatus with no lag in this model - the same reading
        # as bodyfluids -> adh. The renin STATE downstream carries the lag.
        #
        # RENAL SYMPATHETIC TRAFFIC IS STILL ABSENT and would be a third edge into
        # raas from a component that does not exist.
        Coupling(:renal, :raas, Mechanical,
                 gain_param = :RN_MD_RENIN_GAIN,
                 note = "distal sodium delivery inhibits renin at the macula densa"),
        # DECLARED 2026-09-03. bodyfluids -> renal already existed for C_Na and is
        # declared in BodyFluids.jl; V_ecf now drives filtration through
        # gfr_vol_mod as well, and the note there already said it did.
        Coupling(:bodyfluids, :renal, Conservation,
                 note = "V_ecf raises GFR (RN.GFR.VOLUME_SENSITIVITY); algebraic"),
    ]
end
