# ADR 0033: NIMGU is not proportional to glucose, and two independent groups say so

**Status:** Accepted
**Date:** 2026-09-24
**Evidence tier:** **E2** — direct measurement of non-insulin-mediated glucose uptake at two
glucose concentrations under somatostatin insulinopenia in healthy humans (Baron 1985, full
text), with the **form** independently corroborated by a different laboratory, decade and
protocol (Best 1981).

Pre-registered in `validation/nimgu_form_prereg.md`, **branch N1**. `OPEN-QUESTIONS` **B22**.
Discharges the falsifier **ADR 0031 wrote against itself.**

## Context

ADR 0031 built the insulin split and then named its own defect in the same record:

> `NIMGU = k_ni·G` is **strictly linear**, so with both knobs at zero the insulin-independent
> term alone clears the whole appearance at **15.6 mmol/L** — below the renal spill point, so
> glycosuria is zero at every setting and urine never moves.

It deferred the fix rather than stacking a second structural change, and stated the
falsifier: *give NIMGU a sub-proportional form and the ceiling should rise and glycosuria
reappear. If it does not, the linear term was not what capped it.*

**This is the first pass in this repository to satisfy directive 1.16 in full**, and the
route it took is the directive's own argument.

## Evidence

**THE REVIEW CAME FIRST AND DID TWO DISTINCT JOBS.** Ahrén B, Pacini G. *Glucose
effectiveness: lessons from studies on insulin-independent glucose clearance in mice.*
J Diabetes Investig 2021;12(5):675–685. PMID 33098240. **Open access, full text read.**

1. **It separated two quantities this model would otherwise have conflated.** `S_G` (glucose
   effectiveness) is a **minimal-model** parameter that lumps suppression of endogenous
   glucose production **and renal glucose excretion**. This model has both as **separate
   terms**, so adopting an `S_G` value would double-count them. NIMGU as measured directly
   under somatostatin is the quantity this model wants.
2. **It dissolved an apparent contradiction rather than leaving it standing.** The review
   reports `S_G` *"is independent from glucose levels"* in mice, while Baron and Best report
   disposal is **not** proportional to glucose. Both are true: `S_G` is the fitted coefficient
   of a model that **assumes** proportionality, so its stability is a statement about the
   estimator, not evidence that uptake is linear.
3. **Its reference list produced the independent second source**, which is 1.16's stated
   purpose. **Best 1981 uses the term "NIMGU" nowhere** — no search on that term returns it.

| Source | Group | Method | Finding |
|---|---|---|---|
| **Baron 1985**, JCI 76:1782–1788, PMID 2865274, **full text** | Indiana | SRIF insulinopenia + [3-³H]glucose, two glucose levels | NIMGU **113 ± 8** mg/min at **90 ± 1.7** mg/dl (n=11); **186 ± 19** at **248 ± 2** (n=7) |
| **Best 1981**, Diabetes 30:847–850, PMID 6115785 | **Porte, Seattle** | somatostatin at three fixed insulin levels | metabolic clearance falls **38%** at low insulin |

**THE REVIEW MISCITED BEST AS `Diabetes 1981;34`.** Volume 34 is 1985. Verified against the
indexed record before use — **directive 1.5**, and the second time in two days that a number
taken from a review would have been wrong. The first was Carlström repeating 80–180 mmHg
(ADR 0032).

## Decision

**Best's own stated mechanism, not a curve fit:**

> insulin-independent tissues such as brain have a relatively fixed glucose uptake, while
> other tissues have glucose transport systems which take up glucose at a rate proportional
> to its plasma concentration

    NIMGU ~ U_fixed + k_ni * C_glu

**ONE NEW PARAMETER.** `GLU.NIMGU.FIXED_FRACTION` = **0.63**, an **exact two-point inversion**
of Baron's data: `k_ni` = (186−113)/(248−90) = 0.462, `U_fixed` = 113 − 0.462×90 = **71.4
mg/min**, fraction = 71.4/113 = **0.63**. Two points, two parameters — no residual, no
goodness of fit.

**THE PAPER CARRIES ITS OWN CONSISTENCY CHECK AND THE FIT PASSES IT.** Baron separately
reports NIMGU clearance falling **1.2 ± 0.07 → 0.74 ± 0.08**; the fitted rates give 113/90 =
**1.256** and 186/248 = **0.750**. The rates and the clearances are one dataset, not two
claims.

**THE SPLIT IS A REDISTRIBUTION, NOT AN ADDITION.** `U_fixed + k_ni·G_fast ≡ nimgu_tot`
identically, so `S_I` is unchanged and **the healthy operating point cannot move** — asserted,
not hoped: glucose **5.44**, insulin **64.2**, MAP 87.0, sodium 140.0, urine 1.70, `Na_excr`
205.0, all unchanged. **`f_ni_fixed` = 0 returns ADR 0031 exactly.**

## Consequences

**THE FALSIFIER ADR 0031 WROTE AGAINST ITSELF IS DISCHARGED.**

| | `β` | `S_I` | glucose | insulin | glycosuria | urine |
|---|---|---|---|---|---|---|
| health | 1.0 | 1.0 | **5.44** | 64.2 | 0 | 1.701 |
| compensated resistance | 1.0 | 0.2 | 8.18 | **192** | 0 | 1.701 |
| type 2, partial | 0.3 | 0.2 | 12.62 | 102 | 0 | 1.701 |
| type 2, marked | 0.1 | 0.15 | 18.75 | 48 | **202** | 1.989 |
| **type 1, total** | **0.0** | 1.0 | **21.32** | **0** | **644** | **2.561** |

**The ceiling moved 15.64 → 21.32 mmol/L, glycosuria reappeared, and urine moved for the
first time.** 644 mmol/day is **116 g/day** of urinary glucose and 21.3 mmol/L is 384 mg/dl —
both inside the range for uncontrolled type 1.

**AND IT COMPLETES ADR 0030'S THIRST PREDICTION, WHICH COULD NOT FIRE BEFORE.** That pass
predicted polyuria in hyperglycaemia and produced only 1.70 → 2.14 L/day, because the ceiling
sat below the renal threshold. **Urine now moves 1.70 → 2.56 L/day in type 1** — the osmotic
diuresis, emergent from an uptake form rather than imposed.

**THE FIRST EQUATION IN THIS MODEL WITH TWO INDEPENDENT GROUPS BEHIND ITS FORM.**
`validation/form_sourcing_audit.md` measured that count at **zero** on 2026-09-23. `Renal.appear`
is reclassified `conservation → empirical` and sourced, for the same reason `Renal.f_dist_excr`
was on 2026-09-23 (§3.74): **empirical content must sit in a row the gate asks a citation for.**

**Suite 831/831** — 828 plus three, because the `ledger provenance` testset asserts units,
tier and method **per parameter** and one row was added. **Six gates exit 0.**

## What this disqualifies as evidence

**BEST IS CORROBORATION AND IS NOT POOLED.** Its abstract reports only *"more than twice
basal"*, which spans a concentration-independent fraction of **63% at 2.5×** and **76% at
2.0×**. It constrains the form and **cannot supply a value**. That it *contains* Baron's 63%
is agreement, not a pooled estimate.

**THE TWO-TERM FORM IS NOT SHOWN TO BEAT A SATURATING ONE ON DATA.** Two points cannot
distinguish `U_fixed + k_ni·G` from `Vmax·G/(Km+G)`. The choice is on **Best's stated
mechanism**, and `nimgu_form_prereg.md` §7 test 5 declared that comparison **in advance** so
this admission would be owed rather than optional. **Edelman 1990 (PMID 1973673, closed
access) has a four-point dose–response and would decide it.**

**THE DISPERSION IS AN UPPER BOUND AND IS LABELLED ONE.** SD 0.34 propagates Baron's two arms
with their own n (26.5 and 50.3 after SEM→SD) **assuming independence — and they are not
independent**, since seven of the eleven controls appear in both. The true between-subject
spread is smaller and cannot be computed without subject-level data.

**NEITHER CLEARANCE FALL MAY BE QUOTED TO THREE FIGURES.** 38% from Baron's printed
clearances, 40% from the fitted rates; 1.2 ± 0.07 and 0.74 ± 0.08 are two-figure numbers whose
ratio carries several points of uncertainty. **Directive 1.13, and the agreement with Best's
38% is real but must not be read as exact.**

**GLYCOSURIA STILL STARTS TOO LATE.** `OPEN-QUESTIONS` **B20** — the model has no glucose
splay, so spill begins at a sharp threshold rather than over 10–11 mmol/L. Untouched here.
