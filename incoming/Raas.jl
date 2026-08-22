"""
    Raas(; name, enabled = true)

Renin-angiotensin-aldosterone system, lumped.

STRUCTURE SOURCES
  Renin vs renal perfusion pressure: RECTIFIED, not linear. van Ochten M et
    al. Physiol Rep 2025;13:e70547 (10.14814/phy2.70547), systematic review
    and meta-analysis of 30 studies: renin falls linearly with rising renal
    pressure BELOW a threshold and PLATEAUS above it, threshold 93 +/- 2 mmHg.
    That threshold coincides with CV.MAP.SETPOINT = 93.0, so this model's
    operating point sits ON the threshold and the response is one-sided.
  Aldosterone vs angiotensin: COMPRESSIVE power law, log-log slope 0.54,
    derived from a 5-fold aldosterone rise against a 20-fold PRA rise
    (PMID 773568). A linear gain would be wrong.
  Escape: Yokota N et al. PMID 2966064 -- urinary sodium fell 27% acutely
    under fludrocortisone at 180 mEq/day intake and returned to baseline in
    an average of 5 days. Corroborated by Knox FG et al. Kidney Int 1980 and
    Wang XY et al. J Clin Invest 2001;108:215 (10.1172/JCI10366).
  Effector lag: renin-limited, not angiotensin-limited. Plasma AngII half-
    life is under 1 min (PMC6050881); renin release is measurable within 60 s
    and maximal near 5 min (Hofbauer KG et al. Pflugers Arch 1975).

DELIBERATE OMISSION -- angiotensin II vasoconstriction is NOT implemented.
  Human infusion data give MAP, not TPR, and AngII lowers cardiac output
  while raising pressure (Charles CJ et al. Biosci Rep 2018, conscious sheep,
  3-48 ng/kg/min: MAP +<10 to +23 mmHg with heart rate and cardiac output
  falling). In IPE the CO fall should EMERGE from the venous-return path
  rather than be imposed, so k_tpr may not be a free parameter at all. The
  ledger row RAAS.ANG.TPR_GAIN is deliberately blank. See ADR 0010.

DIVERGENCES LOGGED (fidelity-vs-quality directive)
  1. ESCAPE IS LUMPED. In vivo it is mediated by pressure natriuresis (present
     in IPE), NCC downregulation (absent) and ANP (absent). Modelling it as a
     first-order adaptation of the tubular effect reproduces the OBSERVED
     time course without the mechanism. When ANP lands, this term should be
     re-derived, and part of the escape should then emerge rather than be
     imposed. Escaping twice would be a real risk.
  2. THRESHOLD CONFLICT, unresolved. Schweda F et al. Hypertension 2006
     (isolated perfused mouse kidney) report continued suppression ABOVE
     90 mmHg -- to 64% at 115 and 40% at 140 -- which contradicts the in vivo
     plateau. The isolated prep lacks neural and systemic input. This model
     follows the meta-analysis (tier A over tier B). test_raas_threshold
     documents the divergence so it fails loudly if anyone flips it.
  3. ADRENAL LAG IS ABSENT. Aldosterone is algebraic in angiotensin. No
     primary source for the adrenal time constant was found; on a day time
     base it is likely fast relative to escape, but this is a CHOICE.
  4. Derivative discontinuity at the threshold, shared with Renal.GFR's
     autoregulation breakpoints. Not justified, only consistent.

Inputs   MAP (mmHg)
Outputs  fr_mod (unitless) -- ADDITIVE increment to renal fractional sodium
         reabsorption. Positive = retention. Consumed by Renal.FR_effective.

When `enabled = false` every state is held at zero and fr_mod is identically
zero, so the renal equation reduces exactly to its pre-RAAS form. ADR 0008:
the disabled branch is TESTED, not assumed.
"""
function Raas(; name, enabled::Bool = true)

    pars = @parameters begin
        MAP_ref = CV_MAP_SETPOINT                    # mmHg
        P_thr   = RAAS_RENIN_PRESSURE_THRESHOLD      # mmHg
        g_renin = RAAS_RENIN_PRESSURE_GAIN           # unitless
        g_aldo  = RAAS_ALDO_ANG_LOG_SLOPE            # unitless
        k_aldo  = RAAS_ALDO_REABSORPTION_GAIN        # unitless
        tau_ang = RAAS_ANG_TAU                       # day
        tau_esc = RAAS_ALDO_ESCAPE_TAU               # day
    end

    vars = @variables begin
        MAP(t)                     # mmHg     INPUT from cardiovascular
        renin_drive(t)             # unitless rectified pressure error
        ang(t) = 1.0               # unitless normalised angiotensin activity
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

            ang_target_lag(ang, renin_drive, g_renin, tau_ang)...,

            # Compressive adrenal response: a power law with exponent < 1 IS a
            # log-log slope of that exponent. max() guards the fractional power
            # against a non-positive base during transients.
            aldo ~ max(ang, 1e-6)^g_aldo,

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
            D(ang)      ~ 0.0,
            aldo        ~ 0.0,
            fr_raw      ~ 0.0,
            D(esc)      ~ 0.0,
            fr_mod      ~ 0.0,
        ]
    end

    return MTKSystem(eqs, t, vars, pars; name)
end
