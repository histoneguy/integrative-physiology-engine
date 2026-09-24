# ADR 0031: Dietary carbohydrate, and the insulin split

**Status:** Accepted
**Date:** 2026-09-22
**Evidence tier:** **E2** for the non-insulin-mediated share of postabsorptive disposal
(Baron 1985, direct measurement under somatostatin); **E2** for the glucose–insulin
dose-response (Merovci 2021, two-step hyperglycaemic clamp); **E2** for dietary carbohydrate
intake (NHANES). **E3** for the linear form of non-insulin-mediated uptake — default ON,
falsifier named and already contradicted, see Consequences.

Pre-registered in `validation/glucose_insulin_prereg.md` §§11–12. **Branch G1**, reached
after §9.8 and §9.12 recorded G2.

## Context

ADR 0029 built glucose with **one lumped clearance** and ceilinged plasma glucose at
`(appearance + TmG)/GFR` = 25.5 mmol/L, because appearance was **hepatic production alone** —
the model ate sodium, drank water, and took in no glucose at all.

And §12.3 fixed the scope before anything was built: **with insulin fixed at its fasting
value, `IMGU = S_I·I·G` is mass-action in `G`, algebraically identical to the lumped
clearance.** Two terms that each scale with glucose and nothing else are one term wearing two
names. The split was only worth building if insulin responded to glucose.

## Evidence

| Claim | Tier | Source | Reading |
|---|---|---|---|
| Available dietary carbohydrate 225 g/day (IQR 168–302) | **E2** | NHANES 2007–2012, n = 5,337 | extracted |
| NIMGU = **75 ± 5%** of postabsorptive disposal, n = 11 | **E2** | Baron 1985, PMID 2865274 — somatostatin insulinopenia + [3-³H]glucose, **direct** | abstract |
| `I(G)`: 9 → 42 → 78 mU/L at 5.00 → 10.55 → 22.20 mmol/L, n = 12 | **E2** | Merovci 2021, PMID 33033064 — two-step hyperglycaemic clamp, **baseline arm** | **full text**, supplied by the owner |
| Fasting insulin 64.2 pmol/L | **E2** | NHANES, n = 5,563 | extracted |

**García-Estévez 1998's 77 ± 8% was NOT pooled** with Baron. It is a **minimal-model**
estimate, `pooling.md` forbids mixing measurement methods, and `SOURCES.md` would make it
`calibrated` with that model named. Keeping it separate turns it into something better: two
estimators, two cohorts, **agreeing within 2 percentage points**.

## Decision

    I_glu ~ beta_cell * (I_fast + dI_max*max(G-G_fast,0) / (K_ins + max(G-G_fast,0)))
    appear ~ k_ni*G + S_I*I_glu*G*glu_disposal + glu_excr

**BOTH DISPOSAL TERMS ARE DERIVED IDENTITIES. NO FREE PARAMETER.** `k_ni` =
`f_nimgu·EGP/G_fast`; `S_I` closes the 24-hour balance at the operating point. Glucose
therefore **cannot** move in health — it comes out at 5.44 mmol/L and insulin at 64.2 pmol/L
exactly.

**`k_ni` IS PINNED POSTABSORPTIVELY, AND THAT IS THE ONE REAL CHOICE.** Baron measured where
appearance is hepatic production alone; this model's appearance also carries diet, and a
meal's glucose is disposed largely by *insulin*-mediated uptake. So the postabsorptive
fraction may not be applied to the 24-hour total. **Predicted before building and then
measured: NIMGU is 75.0% of postabsorptive disposal and 34.8% of 24-hour disposal**, against
§12.2's "about 35%".

**`I(G)` SATURATES, AND MEROVCI'S OWN TWO INTERVALS ARE WHY** — 5.98 then 3.04 mU/L per
mmol/L. A line fitted to the first interval would overstate insulin at 22 mmol/L twofold.
Two parameters from two increments is an **exact inversion, not a fit**: no residual, no
goodness of fit, and the ceiling is read outside the measured range.

**ZERO NEW STATES.** Glucose becomes an algebraic unknown because the saturating insulin term
removes the closed form. Seventeen unknowns are now **14 integrated and 3 algebraic**.

## Consequences

**INSULIN RESISTANCE ALONE NO LONGER CAUSES DIABETES.** At `glu_disposal` = 0.02 glucose
reaches only 13.0 mmol/L and spills nothing, because insulin rises **64 → 351 pmol/L** and
compensates. That is type 2's natural history: compensated resistance is hyperinsulinaemic
and near-normoglycaemic, and diabetes appears only when the compensation fails — the
disposition index, emergent rather than imposed.

**AND A CLAIM THIS RECORD MADE FIRST WAS WRONG.** It said "a beta-cell deficit alone does
nothing either — both lesions are required." **That is true of type 2 and false of type 1**,
and it was false because of where the knob was applied, not because of physiology.
`beta_cell` first scaled only the **increment** above fasting, leaving basal insulin at 64.2
pmol/L however far it fell; since `S_I` is derived so that basal insulin disposes the whole
appearance at `G_fast`, **total beta-cell destruction produced no hyperglycaemia at all** —
measured 5.44 mmol/L at `beta_cell` = 0.

**CORRECTED 2026-09-23: `beta_cell` scales TOTAL secretion, basal included**, because in type
1 the cells are destroyed and basal secretion goes with the stimulated. The two knobs are now
the two diseases:

| | `beta_cell` | `glu_disposal` | glucose | insulin |
|---|---|---|---|---|
| health | 1.0 | 1.0 | 5.44 | 64.2 |
| compensated resistance | 1.0 | 0.2 | 7.75 | **174** |
| type 2, partial failure | 0.3 | 0.2 | 10.52 | 83 |
| type 2, marked | 0.1 | 0.15 | 13.49 | 36 |
| **type 1, total** | **0.0** | 1.0 | **15.64** | **0** |

Hyperinsulinaemia while compensating, falling insulin as the beta cells fail, absolute
deficiency in type 1. **The knob was the artefact; the physiology was never the finding.**

**IT ALSO CORRECTS A RESULT THIS REPOSITORY REPORTED THE DAY BEFORE.** Before the split,
`glu_disposal` = 0.02 gave 29.4 mmol/L, 374 g/day of glycosuria and 4.09 L/day of urine, and
that was described as insulin resistance producing the diabetic triad. **It was total absence
of a secretion response — beta-cell failure — with no insulin arm to say so.** The `beta_cell`
knob exists because the split proved it necessary, and it is **inert at 1.0**.

**THE CEILING MOVED ONTO A DEFECT I INTRODUCED, AND IT IS NOT FIXED HERE.** `NIMGU = k_ni·G`
is **strictly linear**, so with both knobs at zero the insulin-independent term alone clears
the whole appearance at **15.6 mmol/L** — below the renal spill point, so glycosuria is zero
at every setting and urine never moves. **Baron 1988, read in the same pass, shows NIMGU is
sub-proportional**: 128 → 213 mg/min for a glucose rise of 90 → 220 mg/dL, a 1.66-fold rise
for a 2.44-fold stimulus.

**It is deliberately left for its own pass.** The split is already a structural change and
stacking a second makes neither testable alone — the discipline ADR 0025 and ADR 0026 were
separated under. **Falsifier: give NIMGU Baron 1988's form and the ceiling should rise and
glycosuria reappear. If it does not, the linear term was not what capped it.**

**DIETARY CARBOHYDRATE IS AN INPUT, NOT A MECHANISM.** The model took in no glucose. Adding
225 g/day raises appearance from 1080 to 2329 mmol/day, and `k_glu`'s successor `S_I` is
derived against it, so **the healthy operating point cannot move**.

**What did not change:** MAP 87.0, sodium 140.0, osmolality 287.0, urine 1.70 L/day,
`Na_excr` 205.0, thirst 1.2 mL/day. **All challenges pass.**

## What this disqualifies as evidence

**`I(G)` is single-source and says so.** `pooling.md` permits it and requires the admission;
`OPEN-QUESTIONS` B21 carries the debt. A second two-step hyperglycaemic clamp in healthy
adults reporting both axes would pool with it.

**`dI_max` is an extrapolation.** Merovci's highest step is 22.2 mmol/L; the ceiling is what
the two-point form implies at infinity, and no measurement constrains it there. The model
reaches about 13 mmol/L today, inside the measured range — but that is a fact about the
current ceiling, not a licence.

**Insulin is held flat below fasting glucose.** Merovci has no data there. Real insulin falls
in hypoglycaemia; this model does not represent that and must not be run into it.

**The dispersions are SEs, not SDs.** Baron's 75 ± 5 is a standard error over n = 11; the
population SD is **16.6 percentage points**, so individuals span roughly 58–92%. For a
population model that is the number that matters, and entering the SE would have understated
the spread 3.3-fold.
