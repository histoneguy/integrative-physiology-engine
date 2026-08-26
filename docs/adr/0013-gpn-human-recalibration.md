# ADR 0013: Re-estimate `G_pn` against human data. The model is calibrated to hypertensives

**Status:** Proposed
**Date:** 2026-08-25
**Evidence tier:** MIXED - E1, E2.

- **E1** - that mean arterial pressure responds to chronic dietary sodium intake in
  normotensive humans, and that the response is smaller than in hypertensives. Multiply
  replicated across five meta-analyses covering 32 to 185 trials.
- **E2** - the **magnitude** of that response. Replicated in humans with a large and
  explicit open question: two research groups disagree by a factor of 8 and argue with
  each other in print.
- **NO TIER CLAIMED** for the choice of a single point value within that disagreement.
  That is a modelling decision and is argued as one below, not dressed as a measurement.

> This changes the number this repository has quoted in every handover since the loop
> first closed. It is written as a proposal precisely because of that.

## Context

`RN.PRESSURE_NATRIURESIS.SLOPE` is **20.0 (mEq/day)/mmHg**, `calibrated` - a fitted
constant from Guyton 1972, never measured. It sets the model's headline claim: a
**4.934 mmHg** shift across a 205 → 103 mEq/day salt step, bit-stable since the loop
closed and pinned in `test/runtests.jl`.

Sourced under `validation/salt_sensitivity_prereg.md`, committed before any paper was
opened. Reproduce with `python validation/salt_sensitivity_extract.py`.

At steady state `dMAP ~ d(intake)/G_pn`, so a human slope estimates `G_pn` directly. The
model's 4.934 mmHg is **4.84 mmHg per 100 mmol/day**.

## Evidence

Normotensive humans, MAP per 100 mmol/day. MAP from `DBP + (SBP−DBP)/3` where not
reported; the sensitivity check on DBP alone makes every value *smaller*, so the
conclusion does not depend on the conversion.

| Source | Trials | MAP mmHg/100 mmol | implied `G_pn` |
|---|---|---|---|
| Cutler JA, Follmann D, Allender PS. *Am J Clin Nutr* 1997;65:643S-651S, PMID 9022560 | 32, n=2635 | 1.70 | 58.8 |
| He FJ, Li J, MacGregor GA. *BMJ* 2013;346:f1325, PMID 23558162 | 34, n=3230 | 1.96 | 50.9 |
| He FJ, MacGregor GA. *J Hum Hypertens* 2002;16:761-70, PMID 12444537 | 11, n=2220 | 2.30 | 43.5 |
| Graudal N, Hubeck-Graudal T, Jürgens G, Taylor RS. *Am J Clin Nutr* 2019;109:1273-1278, PMID 31051506 | 133 RCTs | 0.53 | 187.5 |
| Graudal NA, Hubeck-Graudal T, Jurgens G. *Cochrane* 2017;4:CD004022, PMID 28391629 | 89, n=8569 | 0.25 | 393.2 |

**The model's 4.84 is above every one of them**, and sits among the *hypertensive*
comparators - Graudal 2019 above the 75th BP percentile gives 4.57, He & MacGregor 2002
hypertensive gives 4.96, Cutler hypertensive 3.60.

### The model has been calibrated to the wrong population

HANDOVER §3.1 holds `G_pn` at 20.0 rather than the Mizelle-implied 5.43 because 5.43
produces a 15.7 mmHg shift — *"salt-sensitive hypertensive behaviour, not normotensive"*.
**The judgement was right and the threshold was far too generous.** 20.0 is also
hypertensive-range.

`G_pn` should be **larger** than 20, not smaller. **The Mizelle comparison points the
wrong way**: it argues the model is not salt-sensitive *enough*. The 3.68× inflation and
the 2.2× residual have been an argument about moving a number in a direction the human
evidence does not support. The residual audit stands as arithmetic and comes off the
critical path.

## The disagreement, argued in the open

Three estimates cluster at **43.5–58.8**; two Graudal estimates sit at **187–393**. The
difference is not noise and it is not resolvable by pooling — they share primaries, and
`pooling.md` prohibits re-pooling a meta-analytic estimate with studies already inside it.

**The argument for preferring the concordant three**, which is the one this record acts
on: He & MacGregor state in print that the Graudal-type analyses include trials of a week
or less and acute load-then-deplete protocols, which raise sympathetic tone and renin, and
thereby blunt the measured blood-pressure response. The model runs **30 days per level**.
Its perturbation is chronic. Chronic-protocol evidence is the matching evidence, and §4 of
the pre-registration fixed a duration criterion **before** seeing which way it cut.

**And the rebuttal, which weakens that argument and is recorded because it does.**
Graudal's reviews state directly that their effects were **stable in study populations
with a duration of at least two weeks**. That is a specific denial of the mechanism He &
MacGregor invoke. It was overlooked when this recalibration was first recommended in
conversation, and the recommendation was presented as better supported than it is.

Nor does the intake range separate them cleanly: both camps include reductions that go
below the model's 103 mEq/day lower bound.

**What actually remains true after the rebuttal** is narrower, and it is what this record
relies on: three independent analyses agree within 43.5–58.8, and two agree with each
other at 187–393. Adopting the modal cluster while carrying the full range as uncertainty
is a defensible modelling choice. **It is not a demonstration that Graudal is wrong**, and
this record does not claim to have made one.

## Decision

**`RN.PRESSURE_NATRIURESIS.SLOPE`: 20.0 → 51.0 (mEq/day)/mmHg.**

51 is the midpoint of the concordant bracket 43.5–58.8. The three are **not pooled** —
they share primaries. The uncertainty recorded on the row spans the **full human range,
44 to 393**, because the disagreement is real and a narrow uncertainty would hide it.

`extraction_method` becomes **`reported`** rather than `calibrated`: the value now comes
from measurements in humans rather than from fitting a model to itself. That is the single
largest change in the provenance status of any number in this repo.

### What the model does at 51, measured

`julia --project=. bench/gpn_sweep.jl`:

| `G_pn` | shift (mmHg) | `V_ecf` range (L) | excretion/intake |
|---|---|---|---|
| 20.0 | 4.9342 | 14.174–14.560 | 1.0000 |
| 44.0 | 2.2830 | 14.381–14.560 | 1.0000 |
| **51.0** | **1.9737** | **14.405–14.560** | **1.0000** |
| 59.0 | 1.7091 | 14.426–14.560 | 1.0000 |
| 188.0 | 0.5406 | 14.518–14.560 | 1.0000 |

**The loop closes exactly at every value.** `V_ecf` gets *tighter* as `G_pn` rises — a
steeper natriuretic response needs less volume excursion to excrete the same load — so the
concern that a large change might approach the 10 L floor was misplaced.

## Falsifiable test

**Reproducing 1.97 mmHg is not a test.** `G_pn` was derived as `100/slope`, so the model
matching it is arithmetic. The test has to use a variable that was not used to set the
value.

**The test: extracellular volume.** At `G_pn = 51` the model moves `V_ecf` by **0.155 L
across 102 mEq/day**, i.e. ~0.15 L per 100 mmol/day. Human sodium-loading studies measure
body weight and, in some cases, extracellular volume directly. **Source the weight or ECF
change per 100 mmol/day change in chronic sodium intake in normotensive humans, under its
own pre-registration, and compare.**

If the sourced volume response is far from ~0.15 L/100 mmol, then `G_pn = 51` reproduces
the pressure while getting the volume wrong, and the error has moved rather than been
fixed — most likely into `G_vr`, `f_pv`, or the fractional reabsorption term.

**This test can fail, and it is independent.** It is also the natural next piece of work
and should be run before this ADR is Accepted rather than after.

## Consequences

**`test/runtests.jl` breaks, deliberately.** It pins the shift at 4.934 ± 0.05 precisely
so a change to this parameter cannot pass unnoticed. Accepting this ADR replaces that pin
with 1.9737 and the ADR 0012 stage-1 bit-identity block with it, since both reference the
old trajectory.

**`check_pressure_natriuresis` still passes**, at 1.97 against `min_map_shift = 0.5`.
**But note how close the other end of the controversy comes**: at Graudal's 188 the shift
is 0.5406, passing by 8%. If that camp is right, the effect this model exists to
demonstrate is barely visible. That is worth knowing and is not an argument for choosing
51.

**ADR 0007's central claim is unaffected in kind.** Pressure is still an output, still
re-equilibrates at a new higher pressure. It is smaller, and correct.

**HANDOVER §2's result table and §3 both change**, and §3.1's Mizelle reasoning is
superseded.

**The 2.2× residual comes off the critical path**, as `salt_sensitivity_prereg.md` §0
anticipated. `validation/residual_audit.py` stands as arithmetic.

## What is NOT decided

- **Whether to adopt 51 rather than a value from the Graudal camp.** This record argues
  for the modal cluster and states plainly that it has not refuted the alternative.
- **Whether the model should carry salt sensitivity as a population covariate.** The
  subgroup means extracted under §1 of the pre-registration are the evidence base for
  exactly that, and `src/ensemble.jl` samples populations. Recorded, not built.
- **Whether `G_pn` should be a posterior rather than a point value.** The human range
  spans a factor of 9 and a point value hides that. This is the strongest case in the repo
  so far for a distribution.
- **The volume test above.** Until it runs, this ADR should stay Proposed.
