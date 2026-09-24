# ADR 0034: Insulin suppresses hepatic glucose output, and that is what fasting hyperglycaemia is

**Status:** Accepted
**Date:** 2026-09-24
**Evidence tier:** **E2** — graded insulin infusion with isotopically measured endogenous
glucose production in healthy adults (Rizza 1981, n = 15), corroborated on the dose–response
**shape** by an independent laboratory (Groop 1989).

Pre-registered in `validation/egp_suppression_prereg.md`, **branch E1**. Named in HANDOVER §4
as *"the single biggest gap in the glucose axis"*, and by the owner as the blocker for both
diabetes types.

## Context

**EGP was a constant.** `egp_tot = GLU_EGP_BASAL * body_mass * 1440 / MW_glu`, and insulin
could not suppress hepatic glucose output at all.

**THAT IS WHY BOTH DIABETES TYPES WERE WRONG FOR THE SAME REASON.** Unrestrained hepatic
output is the principal driver of **fasting** hyperglycaemia in type 1 and type 2 alike. A
model with fixed EGP can only raise glucose by failing to **dispose** of it — so it
represents the postprandial defect and not the fasting one, and **no coefficient on the
disposal side can fix that**, because it is a missing term rather than a wrong number.

**IT WAS A NAMED HOLE, NOT A NEW IDEA.** `nimgu_form_prereg.md` §1.2 recorded the day before,
from the Ahrén & Pacini review, that `S_G` *lumps suppression of endogenous glucose production
and renal glucose excretion* — which is exactly why an `S_G` value was **refused** for NIMGU
in ADR 0033. **This is the term that refusal said existed and the model did not have.**

## Evidence

**Rizza RA, Mandarino LJ, Gerich JE.** *Dose-response characteristics for effects of insulin
on production and utilization of glucose in man.* Am J Physiol 1981;240(6):E630–E639.
**PMID 7018254.** 15 healthy subjects, insulin infused 8 h at sequential rates from 0.2 to
5.0 mU·kg⁻¹·min⁻¹, 2 h per rate; production and utilization measured isotopically with
[3-³H]glucose.

| | |
|---|---|
| half-maximal suppression of glucose **production** | **29 ± 2 µU/ml** |
| half-maximal glucose **utilization** | **55 ± 7 µU/ml** |
| difference | **P < 0.01** |
| complete suppression of production | *approximately* 60 µU/ml |

**PRODUCTION IS ROUGHLY TWICE AS INSULIN-SENSITIVE AS UTILIZATION, AND THAT CONTRAST IS THE
WHOLE POINT.** A model that suppresses neither cannot produce fasting hyperglycaemia by the
route people actually get it.

**GRADED INFUSION IS WHY THIS SOURCE.** `egp_suppression_prereg.md` §3 excluded single-step
clamps **before searching**: one point cannot constrain a dose–response.

**Independent corroboration, not pooled.** Groop LC, Bonadonna RC, DelPrato S, Ratheiser K,
Zyck K, Ferrannini E, DeFronzo RA. J Clin Invest 1989;84(1):205–213, **PMID 2661589** —
a different laboratory (Pisa–Yale), graded hyperinsulinaemia at **+5, +15, +30, +70, +200
µU/ml** in eight controls, showing progressive suppression of hepatic glucose production.
**No I₅₀ is extractable from its abstract**, so it corroborates the shape and supplies no
value.

## Decision

    egp_i ~ egp_basal * egp_0 / (1 + I_glu / K_egp)

**THE HYPERBOLA IS CHOSEN FOR THE TYPE 1 LIMIT AND FOR NO OTHER REASON.** A suppression
fraction written `egp_basal·(1 − Iʰ/(Kʰ+Iʰ))` is **undefined below basal insulin**, and type 1
is precisely the case where insulin reaches **zero**. This form is smooth, strictly positive
and defined on all `I ≥ 0`, so **type 1 is a value rather than an extrapolation off the end of
a curve.**

**TWO ANCHORS, TWO PARAMETERS — AN EXACT INVERSION, NOT A FIT**, the discipline of ADR 0031
and ADR 0033:

1. `EGP(I_fast) = egp_basal` — the **definition** of basal, and why the healthy operating
   point cannot move;
2. `EGP(I₅₀) = egp_basal/2` — Rizza.

which invert to `K_egp = I₅₀ − 2·I_fast` = **45.6 pmol/L** and `egp_0` = **2.41 × basal**.
**Both are computed in-component and stored nowhere** — ADR 0032's lesson that a stored
derived constant is a precision claim and a drift risk.

**`appear` STAYS A JULIA-LEVEL EXPRESSION, NOT AN UNKNOWN.** It costs no state, and it keeps
the balance's left-hand side a single symbol so `check_relations.py` sees one relation. The
derived identities `k_ni` and `S_I` are still solved against `appear_ref = egp_basal +
diet_tot` — appearance **at the operating point** — and the two coincide at `I_fast` by
construction.

## Consequences

**THE PREDICTION WAS A DIRECTION CHANGE AND BOTH DIRECTIONS HELD.**

| | `β` | `S_I` | glucose | insulin | **EGP** | glycosuria | urine |
|---|---|---|---|---|---|---|---|
| health | 1.0 | 1.0 | **5.44** | 64.2 | **1079.8** | 0 | 1.701 |
| compensated resistance | 1.0 | 0.2 | **7.21** ↓ | 151 | **603.6** | 0 | 1.701 |
| type 2, partial | 0.3 | 0.2 | 11.63 | 94 | 850.8 | 0 | 1.701 |
| type 2, marked | 0.1 | 0.15 | 19.39 | 49 | 1256.4 | 310 | 2.135 |
| **type 1, total** | **0.0** | 1.0 | **27.87** ↑ | **0** | **2600.1** | **1804** | **3.824** |

**Type 1 worsened 21.32 → 27.87 mmol/L. Compensated resistance IMPROVED 8.18 → 7.21** — and
the second is the sharper result, because it is a change of *direction*, not magnitude.
**Hyperinsulinaemia suppresses the liver harder**, which is exactly why fasting glucose stays
near-normal in compensated insulin resistance in people. That behaviour is now **emergent**
rather than absent.

**Type 1 at 27.87 mmol/L (502 mg/dl) with 1804 mmol/day of glycosuria (325 g) and 3.82 L/day
of urine** is the classic untreated presentation — severe hyperglycaemia, heavy glycosuria,
osmotic polyuria — produced from mechanism rather than imposed.

**THE OUT-OF-SAMPLE CHECK PASSED AND THE ANCHORS DID NOT GUARANTEE IT.** EGP at zero insulin
is **2600.1 against a basal 1079.8 — 2.41×**, and uncontrolled type 1 EGP is reported elevated
roughly two- to threefold. Neither anchor constrains that point.

**Health is bit-identical.** Glucose 5.44, insulin 64.2, MAP 87.0, sodium 140.0, osmolality
287.0, urine 1.70, `Na_excr` 205.0, and **EGP at fasting insulin is 1079.84 = `egp_basal`
exactly.** **Suite 834/834, six gates exit 0.**

## What this disqualifies as evidence

**THE HILL COEFFICIENT IS 1 AND IT UNDER-SUPPRESSES AT HIGH INSULIN.** Rizza reports
production *"completely suppressed"* at about 60 µU/ml; this form gives **27% of basal**
there. **Declared in advance and measured rather than tuned away** — §9 of the
pre-registration names raising `h` to match a qualitative word as the way this pass fails.
Only a digitised multi-point curve could justify `h > 1`, and Groop's five steps would supply
one if the full text were readable.

**HEPATIC INSULIN RESISTANCE IS NOT REPRESENTED.** `glu_disposal` scales `S_I` alone, so the
liver's sensitivity cannot be lesioned independently of the periphery. **Groop's central
finding is that the two dissociate in type 2**, so this is a real omission — recorded here so
a later pass cannot present it as a discovery, exactly as ADR 0032 did for CT-GF.

**GLUCAGON IS ABSENT ENTIRELY**, and it is the other arm of EGP control.

**`GLU.EGP.BASAL` REMAINS SINGLE-SOURCE** (Huidekoper 2014) — `OPEN-QUESTIONS` B21, untouched
here. This pass changed the *response*, not the basal value.

**THE I₅₀ IS SINGLE-SOURCE FOR ITS VALUE** and says so; Groop corroborates the form only.
SEM → SD conversion: 2 × √15 = **7.75 µU/ml = 46 pmol/L**.

**GLYCOSURIA STILL STARTS TOO LATE** — B20, no splay, untouched.
