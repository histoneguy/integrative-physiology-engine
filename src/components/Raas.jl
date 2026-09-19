"""
Renin-angiotensin-aldosterone system, lumped.

Wired in 2026-08-25 from `incoming/Raas.jl`, where it had been parked. Three
things were wrong with the parked version and are corrected here; see
CORRECTIONS below.

STRUCTURE SOURCES
  Renin vs renal perfusion pressure: RECTIFIED, not linear.
    van Ochten M, El Fathi W, Bovee EME, Spaanderman MEA, Hooijmans CR,
    van Drongelen J. The renal baroreflex: A systematic review and
    meta-analysis in healthy and hypertensive ANIMALS. Physiol Rep
    2025;13(17):e70547, PMID 40930784, doi 10.14814/phy2.70547.
    30 studies in the meta-analysis: renin decreases linearly with rising
    renal pressure and reaches a plateau above a threshold of 93 +/- 2 mmHg.
    SPECIES: animal, mixed, per ADR 0006 E2 - servo-controlling renal
    perfusion pressure is not performable in humans, the same ethical ceiling
    that applies to RN.PRESSURE_NATRIURESIS.SLOPE.
    QUALITY CAVEAT FROM THE PAPER ITSELF: "Risk of bias was high in most
    studies."

  Aldosterone vs the renin signal: COMPRESSIVE power law, log-log slope 0.537.
    Walker WG, Moore MA, Horvath JS, Whelton PK. Arterial and venous
    angiotensin II in normal subjects. Circ Res 1976;38(6):477-83,
    PMID 773568. 16 normal subjects; sodium restriction plus furosemide
    against sodium surfeit gave a 5-fold aldosterone rise against a 20-fold
    PRA rise. log(5)/log(20) = 0.537.

  Escape: Kelly TM, Nelson DH. Sodium excretion and atrial natriuretic
    peptide levels during mineralocorticoid administration. Endocr Res
    1987;13(4):363-83, PMID 2966064, doi 10.3109/07435808709035463.
    0.3-0.5 mg/day fludrocortisone for 18 days, four healthy males, sodium
    intake 180 +/- 2 mEq/day. Urinary sodium fell 27% immediately and
    RETURNED TO BASELINE IN AN AVERAGE OF 5 DAYS. Plasma ANP rose
    91.7 +/- 13.0 -> 179.7 +/- 39.2 pg/ml.
    ATTRIBUTION was corrected once already, in 2026-08-21, from "Yokota N
    et al." Re-verified against the PubMed record on 2026-08-25: authors,
    journal, volume, issue, pages and every quoted number check out.

CORRECTIONS TO THE PARKED VERSION, 2026-08-25
  1. THE EXPONENT WAS ATTACHED TO THE WRONG VARIABLE. The parked docstring
     read "Aldosterone vs ANGIOTENSIN: compressive power law, log-log slope
     0.54". Walker 1976 reports a 2.72-fold arterial angiotensin II rise
     alongside the 5.71-fold aldosterone rise and the 21.8-fold PRA rise.
     Aldosterone against PRA is log-log 0.537 and COMPRESSIVE; aldosterone
     against angiotensin II is 1.47 and EXPANSIVE. The sourced exponent is
     the PRA one, and the state it multiplies is renin-driven, so the state
     is named `pra` here rather than `ang`. Same number, correct referent.
  2. `ang_target_lag(...)` WAS CALLED AND NEVER DEFINED ANYWHERE IN THE REPO.
     The parked file could not have compiled. The first-order lag is written
     out explicitly below.
  3. SPECIES WAS NOT RECORDED for the renal baroreflex threshold, which
     ADR 0006 requires and which is the whole subject of the 1.6 amendment.

DELIBERATE OMISSION - angiotensin II vasoconstriction is NOT implemented, so
  there is no TPR path from this component. Human infusion data give MAP, not
  TPR, and angiotensin lowers cardiac output while raising pressure. In IPE
  the CO fall should EMERGE from the venous-return path rather than be
  imposed. `RAAS.ANG.TPR_GAIN` is deliberately absent from the ledger.

THE STEADY STATE IS UNCHANGED, AND THAT IS THE POINT
  `esc` chases `fr_raw`, so `fr_mod` is full on arrival and ZERO at steady
  state. Aldosterone does not permanently retain sodium in vivo and it does
  not here. Consequence for this model: wiring RAAS in CANNOT move the
  steady-state salt-step pressures, because those are steady states. It
  changes the TRANSIENT approach to them. The two calibrated parameters below
  therefore shape a time course and cannot move the headline result.

DIVERGENCES LOGGED
  1. ESCAPE IS LUMPED. In vivo it is mediated by pressure natriuresis
     (present here), NCC downregulation (absent) and ANP (absent). This
     reproduces the observed time course without the mechanism. When ANP
     lands this must be re-derived or the model will escape twice.
  2. THRESHOLD CONFLICT, unresolved. Schweda F et al. Hypertension 2006
     (isolated perfused mouse kidney) report continued suppression above
     90 mmHg, contradicting the in vivo plateau. The isolated preparation
     lacks neural and systemic input. This model follows the meta-analysis.
  3. ADRENAL LAG IS ABSENT. Aldosterone is algebraic in the renin signal. No
     primary source for the adrenal time constant was found.
  4. THE COINCIDENCE BROKE ON 2026-08-27, EXACTLY AS THIS NOTE WARNED.
     `P_thr` is 93 mmHg from van Ochten and `CV.MAP.SETPOINT` WAS also 93,
     under the citation "Standard physiological reference. VERIFY." So the
     model sat exactly ON the rectification threshold and RAAS was inactive
     at baseline by construction - structural work resting on one unverified
     number.

     That number was the textbook BRACHIAL 120/80 convention. Sourcing
     central pressure moved the setpoint to 87.0, so the model now sits
     6 mmHg BELOW threshold and RAAS IS ACTIVE AT REST: renin drive 0.069,
     plasma renin activity 2.31x. More physiological, not less - resting
     renin is not zero.

     CONSEQUENCE: `g_renin` was calibrated so the low-salt arm doubled PRA
     from a baseline of 1.0, and that baseline no longer exists.

     RE-DERIVED 2026-09-02, 19.0 -> 4.35, AND IT IS NO LONGER `assumed`.
     Pre-registered in validation/renin_gain_prereg.md; run
     python validation/renin_gain_extract.py. The slope came from the SAME
     van Ochten meta-analysis already cited above for the threshold and the
     form: renin rises 50 percentage points of its PLATEAU value per 10 mmHg
     fall in renal arterial pressure, so 0.05 per mmHg, and this file
     normalises the drive by MAP_ref, so g_renin = 0.05 * MAP_ref exactly.

     THE OLD LEDGER NOTE WAS WRONG ABOUT THE PAPER, WHICH IS WHY THE ROW SAT
     `assumed`. It said the slope was in "animal units this model cannot
     consume directly". The paper's own Limitations say the opposite: it
     could not meta-analyse ABSOLUTE renin, because studies reported PRA,
     PRC or renin release on assay-dependent scales, so it converted the
     dose-response to PERCENTAGE OF BASELINE - the one form a dimensionless
     normalised `pra` can consume. Nobody had opened it.

     `pra = 1` IS THE PLATEAU, NOT RESTING RENIN. The form is rectified, so
     the drive is zero at and above P_thr and `pra` is normalised to the
     floor. Resting `pra` is now 1.30 rather than 2.31 because the operating
     point sits 6 mmHg below threshold. Conflating the two is what broke this
     row in the first place.

     WHAT IT CANNOT DO, still. The human salt-induced renin response is NOT
     reproducible here at any gain. van den Bosch 2021 measures a 2.73-fold
     PRA difference between high and low sodium at MAP 88 against 86, and
     this rectified form caps the achievable ratio at (93-86)/(93-88) = 1.4.
     In humans that response runs mostly through macula densa sodium
     delivery and renal sympathetic traffic, and this component has neither.
     Recorded as a structural gap rather than absorbed into the gain.

Inputs   MAP (mmHg)
Outputs  fr_mod (unitless) - ADDITIVE increment to renal fractional sodium
         reabsorption. Positive = retention. Consumed by Renal.FR_effective.

When `enabled = false` every state is held at zero and `fr_mod` is identically
zero, so the renal equation reduces exactly to its pre-RAAS form. ADR 0008:
the disabled branch is TESTED, not assumed.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams:
    CV_MAP_SETPOINT, RAAS_RENIN_PRESSURE_THRESHOLD, RAAS_RENIN_PRESSURE_GAIN,
    RAAS_ALDO_PRA_LOG_SLOPE, RAAS_ALDO_REABSORPTION_GAIN, RAAS_PRA_TAU,
    RAAS_ALDO_ESCAPE_TAU, RN_MD_RENIN_GAIN, RAAS_ALDO_K_GAIN, K_PLASMA_REFERENCE,
    RAAS_RENIN_SYMPATHETIC_THRESHOLD_SHIFT, BR_OPEN_LOOP_GAIN,
    RAAS_ANGII_TUBULAR_GAIN, RAAS_PRA_REFERENCE

"""
    Raas(; name, enabled = true)

Lumped renin-angiotensin-aldosterone system. See the module docstring.
"""
function Raas(; name, enabled::Bool = true, pra_clamp = 0.0, k_angii_override = 0.0)

    pars = @parameters begin
        MAP_ref = CV_MAP_SETPOINT                    # mmHg
        P_thr   = RAAS_RENIN_PRESSURE_THRESHOLD      # mmHg
        g_renin = RAAS_RENIN_PRESSURE_GAIN           # unitless CALIBRATED
        g_aldo  = RAAS_ALDO_PRA_LOG_SLOPE            # unitless
        k_aldo  = RAAS_ALDO_REABSORPTION_GAIN        # unitless CALIBRATED
        tau_pra = RAAS_PRA_TAU                       # day
        tau_esc = RAAS_ALDO_ESCAPE_TAU               # day
        # ADR 0021. Both INTENSIVE: the macula densa gain multiplies a
        # dimensionless fractional deviation, and the potassium gain a
        # concentration difference. Neither inherits a body-size scaling, which
        # is deliberate - see the note on md_drive in Renal.jl.
        g_md    = RN_MD_RENIN_GAIN                   # unitless CALIBRATED
        g_aldo_K = RAAS_ALDO_K_GAIN                  # 1/(mmol/L)
        K_p_ref = K_PLASMA_REFERENCE                 # mmol/L
        # THE RENAL SYMPATHETIC ARM. Kirchheim 1985 in conscious dogs: carotid
        # occlusion shifts the pressure-renin curve RIGHT by 17 mmHg and leaves
        # the plateau and the slope alone. So sympathetic traffic moves the
        # THRESHOLD, and this is the shift at saturating activity.
        # dP_sym = 0 recovers the previous model EXACTLY - the precedent g_md
        # was introduced on, and it costs no new structural variant.
        dP_sym  = RAAS_RENIN_SYMPATHETIC_THRESHOLD_SHIFT   # mmHg
        G_br    = BR_OPEN_LOOP_GAIN                  # unitless, REUSED
        # ADR 0015'S TERM, BUILT 2026-09-19. Hall 1984 servo-controlled dogs:
        # at FIXED renal perfusion pressure, with plasma aldosterone back at
        # control, angiotensin II still retains 24 mEq/day. Escape is
        # PRESSURE-mediated, so this term sits OUTSIDE esc by construction.
        # k_angii = 0 recovers the previous model exactly.
        # k_angii_override < 0 means USE THE LEDGER VALUE; 0 means the term is
        # OFF. Default OFF - see the note in assemble.jl and ADR 0015.
        k_angii = k_angii_override < 0.0 ? RAAS_ANGII_TUBULAR_GAIN : k_angii_override
        pra_ref = RAAS_PRA_REFERENCE                 # unitless
        # DIAGNOSTIC, DEFAULT 0 = OFF, and it has NO LEDGER ROW - the precedent
        # anp_convexity and anp_adaptation were introduced on. It exists so that
        # ADR 0015's falsifiable test can be RUN rather than argued: Hall 1980
        # clamped angiotensin II so it could not fall as sodium intake rose, and
        # this pins the pra that fr_angii sees to do the same. It is not a
        # physiological parameter and must never be given one.
        p_clamp = pra_clamp                          # unitless, 0 = free
    end

    vars = @variables begin
        MAP(t)                     # mmHg     INPUT from cardiovascular
        renin_drive(t)             # unitless rectified pressure error
        pra(t) = 1.0               # unitless normalised renin activity
        aldo(t)                    # unitless normalised aldosterone activity
        fr_raw(t)                  # unitless unescaped tubular effect
        esc(t) = 0.0               # unitless escape state
        fr_mod(t)                  # unitless OUTPUT to renal
        md_drive(t)                # unitless INPUT from renal - macula densa
        K_p(t)                     # mmol/L   INPUT from potassium
        rsna(t)                    # unitless renal sympathetic activity, -1..1
        P_thr_eff(t)               # mmHg     threshold after the sympathetic shift
        fr_angii(t)                # unitless NON-ESCAPING AngII tubular term
    end

    eqs = if enabled
        [
            # Rectified renal baroreflex. Renin is stimulated when perfusion
            # pressure falls BELOW threshold and is already at its floor above
            # it, so this term is one-sided by construction. Normalised by
            # MAP_ref so g_renin is a fractional-per-fractional gain.
            # TWO DRIVES SINCE ADR 0021, AND THE SECOND IS WHAT LIFTS THE
            # CEILING. The pressure arm is UNCHANGED - rectified, van Ochten's
            # threshold, van Ochten's slope. HANDOVER section 7 records that a
            # pressure-only form caps the achievable renin ratio between two
            # pressures at the ratio of their drives, 1.40 between MAP 88 and 86,
            # WHATEVER the gain, against a measured 2.73. A second input that
            # moves with salt intake is the only thing that can exceed that, and
            # a ceiling either is or is not exceeded.
            #
            # THE MACULA DENSA GAIN IS ESTIMATED AGAINST THOSE SALT-RENIN DATA and
            # ADR 0021's falsifiable test 1 declared it so before the fact. Those
            # data are an ESTIMATION SET and must never be reported as agreement -
            # section 3.15 records what happened the last time that was forgotten.
            # RENAL SYMPATHETIC ACTIVITY, AND IT DOES NOT RESET - THAT IS THE
            # WHOLE CLAIM. The vasomotor arm in Baroreflex.jl carries a setpoint
            # that drifts to prevailing pressure with BR.RESET.TAU = 1 day, so its
            # drive is ZERO in every chronic steady state. Lohmeier 2001 measured
            # the opposite for the RENAL arm: at day 10 of ANG II, MAP stable at
            # +30 mmHg and sodium balance achieved, the denervated/innervated
            # sodium ratio was 0.56 +/- 0.05 against a control of 0.99 +/- 0.05.
            # Ten days is ten of those time constants; a completely reset arm would
            # have returned the ratio to 1.0. It did not.
            #
            # SO THIS ERROR IS TAKEN AGAINST THE FIXED MAP_ref, NOT AGAINST THE
            # RESETTING SETPOINT. It is a claim about the RENAL arm only and says
            # nothing about the vasomotor one - Baroreflex.jl already cites Dutoit
            # 2010 for the arms being independent within individuals, and
            # differential resetting between arms is the ordinary case.
            #
            # The tanh and G_br are BORROWED from the vasomotor efferent, because
            # Kirchheim measured two points and no submaximal curve. That
            # interpolation is this model's assumption and the ledger row says so.
            rsna ~ -tanh(G_br * (MAP - MAP_ref) / MAP_ref),

            # Sympathetic activation RAISES the threshold, so renin is stimulated
            # at a pressure that would otherwise be on the plateau. Zero at the
            # operating point by construction: MAP = MAP_ref gives rsna = 0.
            P_thr_eff ~ P_thr + dP_sym * rsna,

            renin_drive ~ ifelse(MAP < P_thr_eff, (P_thr_eff - MAP) / MAP_ref, 0.0) +
                          g_md * md_drive,

            # First-order approach to the renin target. Written out here; the
            # parked version called a helper that does not exist.
            # THE TARGET IS FLOORED AT ZERO, ADDED 2026-09-05 WITH THE MACULA
            # DENSA ARM. Renin secretion cannot be negative, and the new arm is
            # SIGNED where the pressure arm is rectified, so a large enough distal
            # delivery drives the target below zero and plasma renin activity with
            # it. The floor is INERT at every sourced parameter value - the target
            # is 1.05 at the highest salt intake in the estimation set - and it is
            # here because an unphysical negative would otherwise appear only in a
            # regime nobody had looked at.
            D(pra) ~ (max(1.0 + g_renin * renin_drive, 0.0) - pra) / tau_pra,

            # Compressive adrenal response: a power law with exponent < 1 IS a
            # log-log slope of that exponent. max() guards the fractional power
            # against a non-positive base during transients.
            # ALDOSTERONE HAS TWO INPUTS NOW, AND THAT IS THE JOIN ADR 0021
            # EXISTS FOR. The renin power law is unchanged - Walker 1976's
            # compressive log-log 0.537 - and plasma potassium enters
            # multiplicatively and exponentially, which is the form Brunner's
            # within-subject log ratios measure.
            #
            # THE RETURN ARM IS NOT BUILT: aldosterone does not act on potassium
            # excretion here, because every human study found moves potassium
            # intake and aldosterone together and neither gain separates from the
            # other. Recorded on RAAS.ALDO.K_GAIN rather than filled with a
            # plausible number.
            #
            # AND ESCAPE MUTES THIS CHRONICALLY. fr_mod goes to zero at steady
            # state, so potassium's route into sodium handling is open in the
            # transient and closed in the long run. That is a fact about ADR
            # 0010's escape structure, not about potassium, and it is why this
            # join changes what the model REPORTS more than what it DOES.
            aldo ~ max(pra, 1e-6)^g_aldo * exp(g_aldo_K * (K_p - K_p_ref)),

            # Tubular effect before escape.
            fr_raw ~ k_aldo * (aldo - 1),

            # ESCAPE. The escape state chases the raw effect, so the NET effect
            # is full on arrival and zero at steady state. This is the whole
            # reason aldosterone does not permanently retain sodium in vivo.
            D(esc) ~ (fr_raw - esc) / tau_esc,

            # ADR 0015. THE DIRECT ANGIOTENSIN II TUBULAR TERM, AND IT DOES NOT
            # ESCAPE. Hall 1984 (PMID 6720967) servo-controlled the renal perfusion
            # pressure of eight conscious dogs during ANG II infusion. At day 6 the
            # pressure was still clamped, plasma aldosterone had RETURNED TO CONTROL
            # (4.9 +/- 0.8 vs 4.6 +/- 1.0), and they were still retaining 24 +/- 5
            # mEq/day. Both competing routes excluded - one by the preparation, one
            # by measurement - so what remains is the direct tubular action.
            #
            # IT SITS OUTSIDE esc BECAUSE HALL SHOWED ESCAPE IS PRESSURE-MEDIATED:
            # releasing the occluder took urinary sodium from 56 to 322 mEq/day in a
            # day. ADR 0015 specified this structure in 2026-09-02, before the source
            # was found, and the source confirms it.
            #
            # ZERO AT THE OPERATING POINT by construction, so nothing pinned moves.
            # k_angii = 0 recovers the previous model exactly - the precedent g_md
            # and dP_sym were introduced on.
            fr_angii ~ k_angii *
                       (ifelse(p_clamp > 0.0, p_clamp, pra) - pra_ref),

            fr_mod ~ (fr_raw - esc) + fr_angii,
        ]
    else
        [
            rsna        ~ 0.0,
            P_thr_eff   ~ P_thr,
            fr_angii    ~ 0.0,
            renin_drive ~ 0.0,
            D(pra)      ~ 0.0,
            aldo        ~ 0.0,
            fr_raw      ~ 0.0,
            D(esc)      ~ 0.0,
            fr_mod      ~ 0.0,
        ]
    end

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    raas_couplings()

RAAS reads arterial pressure and writes a tubular reabsorption increment.
Hormonal, not mechanical: the renin response is measurable within a minute but
the escape it drives runs over days.
"""
function raas_couplings()
    return [
        Coupling(:cardiovascular, :raas, Mechanical,
                 note = "MAP sensed at the juxtaglomerular apparatus; no lag"),
        Coupling(:raas, :renal, Neurohumoral;
                 tau_seconds = RAAS_PRA_TAU * 86400.0,
                 gain_param = :RAAS_RENIN_PRESSURE_GAIN,
                 note = "renin -> aldosterone -> tubular sodium reabsorption, " *
                        "with first-order escape over days"),
    ]
end
