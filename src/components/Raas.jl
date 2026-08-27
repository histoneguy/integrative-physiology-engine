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
     from a baseline of 1.0, and that baseline no longer exists. Escape
     still zeroes `fr_mod` at steady state, so no steady state moves, but
     the gain must be re-derived before this component is trusted for
     anything transient.

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
    RAAS_ALDO_ESCAPE_TAU

"""
    Raas(; name, enabled = true)

Lumped renin-angiotensin-aldosterone system. See the module docstring.
"""
function Raas(; name, enabled::Bool = true)

    pars = @parameters begin
        MAP_ref = CV_MAP_SETPOINT                    # mmHg
        P_thr   = RAAS_RENIN_PRESSURE_THRESHOLD      # mmHg
        g_renin = RAAS_RENIN_PRESSURE_GAIN           # unitless CALIBRATED
        g_aldo  = RAAS_ALDO_PRA_LOG_SLOPE            # unitless
        k_aldo  = RAAS_ALDO_REABSORPTION_GAIN        # unitless CALIBRATED
        tau_pra = RAAS_PRA_TAU                       # day
        tau_esc = RAAS_ALDO_ESCAPE_TAU               # day
    end

    vars = @variables begin
        MAP(t)                     # mmHg     INPUT from cardiovascular
        renin_drive(t)             # unitless rectified pressure error
        pra(t) = 1.0               # unitless normalised renin activity
        aldo(t)                    # unitless normalised aldosterone activity
        fr_raw(t)                  # unitless unescaped tubular effect
        esc(t) = 0.0               # unitless escape state
        fr_mod(t)                  # unitless OUTPUT to renal
    end

    eqs = if enabled
        [
            # Rectified renal baroreflex. Renin is stimulated when perfusion
            # pressure falls BELOW threshold and is already at its floor above
            # it, so this term is one-sided by construction. Normalised by
            # MAP_ref so g_renin is a fractional-per-fractional gain.
            renin_drive ~ ifelse(MAP < P_thr, (P_thr - MAP) / MAP_ref, 0.0),

            # First-order approach to the renin target. Written out here; the
            # parked version called a helper that does not exist.
            D(pra) ~ ((1.0 + g_renin * renin_drive) - pra) / tau_pra,

            # Compressive adrenal response: a power law with exponent < 1 IS a
            # log-log slope of that exponent. max() guards the fractional power
            # against a non-positive base during transients.
            aldo ~ max(pra, 1e-6)^g_aldo,

            # Tubular effect before escape.
            fr_raw ~ k_aldo * (aldo - 1),

            # ESCAPE. The escape state chases the raw effect, so the NET effect
            # is full on arrival and zero at steady state. This is the whole
            # reason aldosterone does not permanently retain sodium in vivo.
            D(esc) ~ (fr_raw - esc) / tau_esc,
            fr_mod ~ fr_raw - esc,
        ]
    else
        [
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
