# ADR 0038: Body water re-sourced to deuterium dilution, and the 90% hydration is gone

**Status:** Accepted
**Date:** 2026-10-28
**Evidence tier:** **E2** — total body water by **deuterium dilution** (the reference method)
with DXA body composition, 566 US adults, sexed, mixed longitudinal over eight years.

Pre-registered in `validation/body_water_prereg.md`. `OPEN-QUESTIONS` **B37**, opened by
ADR 0037 eight days earlier.

## Context

`BF.TBW/ICF/ECF.MASS_FRACTION` were **0.552 / 0.344 / 0.208**, a single `sex = both` triple
expressed as fractions of **body** mass, from **Zhang N et al.** — 160 Chinese college students
measured by **bioelectrical impedance** in a study about **water intake**.

**ADR 0037 showed what that cost.** Dividing by the newly measured fat-free fraction implied a
hydration of fat-free mass of **0.758 in men and 0.900 in women.** Hydration of fat-free mass
is ≈0.73 and is among the most stable quantities in body composition. **Fat-free mass cannot be
90% water** — the model carried roughly **8 L** in women with nowhere to be.

**AND NO GATE COULD SEE IT.** `check_closure.py` verifies ICF + ECF = TBW, which held perfectly
in both sexes. **The compartments summed; they were the wrong size.**

## Evidence

**Chumlea WC, Guo SS, Zeller CM, Reo NV, Siervogel RM.** *Total body water data for white adults
18 to 64 years of age: The Fels Longitudinal Study.* **Kidney Int 1999;56(1):244–252.**
274 men, 292 women, 18–64 y; **TBW by deuterium NMR**, DXA alongside. **Full text read, supplied
by the owner.**

**IT IS NOT THE PAPER THE CATALOGUE ASKED FOR.** `CITES-NEEDED.md` named Chumlea **2001** (PMID
11380828). This is the **1999 Fels** paper, and **it is better here** — the reason is §"compartment
definitions" below, and the catalogue was corrected rather than the substitution passed over.

### The compartment definitions match exactly, and that is the deciding reason

Chumlea computes FFM as *"the sum of whole body lean tissue and whole body bone mineral mass"*
from DXA. `BF.FAT.MASS_FRACTION` was extracted from NHANES DXA as
`DXDTOFAT / (DXDTOFAT + DXDTOLE + DXDTOBMC)`, so this model's `mass_ffm` **is** lean + bone
mineral. **Same compartment, same instrument class.**

**THE CANONICAL 0.73 WAS DELIBERATELY NOT USED.** It refers to fat-free *body* mass; a
DXA-defined FFM includes bone mineral, which carries almost no water, so pairing 0.73 with a
DXA-derived fat fraction is a **level and method mismatch** — the error the five-level model
exists to prevent.

### The paper reports its own ratio three inconsistent ways

| within the paper | men | women |
|---|---|---|
| running text | *"approximately 0.68"* (both) | 0.68 |
| **Table 3**, random-effects fit, **no age effect** | **0.700** | **0.720** |
| Table 1, ratio of group means (DXA-n weighted) | 0.716 | 0.733 |

**Table 3 is taken, and the rule was fixed in the pre-registration before choosing.** It is the
paper's own fitted estimate of this quantity **by sex**, and with no age term the intercept is
the value across the range. The text's 0.68 carries **no n and no dispersion** and contradicts
both tables. Table 1's figures are **ratios of group means from different subsamples** — TBW on
N, FFM on N\* — which is not the mean of individual ratios. **All three are recorded on the
row.**

## Decision

    TBW = h_sex * (1 - f_fat_sex) * body_mass

| | `f_fat` | `h` | **TBW** | ECF | ICF | was |
|---|---|---|---|---|---|---|
| male | 0.272 | 0.700 | **0.510** | 0.192 | 0.318 | 0.552 / 0.208 / 0.344 |
| female | 0.387 | 0.720 | **0.441** | 0.166 | 0.275 | same shared triple |

**The sex difference in water per kg body mass now EMERGES from the sourced fat fractions
instead of being imposed.** Hydration itself is nearly sex-invariant and slightly **higher** in
women.

**`CV.PLASMA.ECF_FRACTION` WAS RE-DERIVED, AND THAT IS BOOKKEEPING THE GATE DEMANDS.**
`f_pv = BV0·(1−Hct)/V_ecf` is a closure identity `check_closure.py` enforces per sex. `V_ecf` at
the 70 kg reference falls to 13.44 L male and 11.62 L female from a shared 14.56, so `f_pv`
**rises**: 0.2111 → **0.2287** male, 0.2044 → **0.2562** female. The pre-registration permitted
this and **forbade** re-tuning `CV.MAP.SETPOINT`, the venous return gain or either `calibrated`
row.

**SEXING A SHARED PARAMETER IS NOT A ONE-LINE CHANGE.** Sixteen use sites across
`BodyFluids.jl`, `Renal.jl`, `ensemble.jl` and the suite read these fractions as scalars and had
to move to the sexed lookup. In `BodyFluids` the lookup is done **once**, so the component has a
single place where sex enters the water compartments.

## Consequences

**THE CHECK THIS PASS EXISTS FOR — measured, not asserted.** Implied hydration of fat-free mass
is now **0.7005 male / 0.7194 female**, against **0.758 / 0.900** before. **The impossible figure
is gone.**

**THE OPERATING POINT HELD WHILE THE VOLUMES MOVED.** MAP 87.0 / 86.1 / 85.2 male and
87.0 / 86.1 / 85.1 female across the salt arms, with `V_ecf` falling from a shared 14.56 to
**13.44** and **11.62**. The closure identity absorbed it through `f_pv` — which is what
re-deriving it was for, and the reason the loop still closes (branch **W1**, not W3).

**NOTHING LEFT ITS BAND.**

| | salt sensitivity (1.70–2.30) | `dMAP/dV_ecf` (2.97–4.16) |
|---|---|---|
| male | **1.7** | 3.5 |
| female | **1.8** | 4.2 |

**Salt sensitivity in women improved slightly** off the lower edge B35 recorded, which was not
predicted and is not claimed as a success — it is a consequence of `f_pv` rising most in women.

**A NEW SEXED PREDICTION, EMERGENT RATHER THAN IMPOSED.** `dMAP/dV_ecf` now differs by sex,
**3.5 against 4.2**, because `f_pv` differs by sex, because `V_ecf` differs by composition.
Nothing sourced that difference directly.

## What this disqualifies as evidence

**THE ECF/ICF SPLIT IS STILL ZHANG'S, AND IT IS NOW THE WEAKEST THING IN THE FLUID MODEL.**
Chumlea measures **total** body water, not extracellular and intracellular water. Its
introduction gives 65/35 for *"the proverbial 70 kg person"* — a convention, and directive 1.12
forbids taking it. So the **total** is deuterium-sourced and sexed while the **partition** keeps
Zhang's 0.3768 : 0.6232 unchanged. **This pass makes the total right and leaves the partition
wrong**, and calling the fluid model sourced would be false. Bromide dilution would fix it —
`OPEN-QUESTIONS` **B39**.

**THE COHORT IS WHITE US ADULTS, 18–64.** Single-ancestry, where this model's reference
individual is a multi-ancestry NHANES adult. **Directive 1.17's Rule B is satisfied on country
and only partly on composition.**

**NO DISPERSION.** Table 3 gives intercepts without standard errors, so `uncertainty_type = none`
rather than inventing one — the treatment Finke's autoregulatory limit and Janssen's muscle
fraction already get. **A population model needs this spread and does not have it.**

**AND GEOGRAPHY WAS NOT WHAT REJECTED ZHANG.** Directive 1.17's Rule A was satisfied, but
**four stronger grounds each sufficed independently**: directive 1.7 (body water was the
instrument there, not the subject), method, cohort, and the sex-pooling that produced the 0.900.
**1.17 requires naming the rule that did the work, and it was 1.7.**
