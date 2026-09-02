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

## The falsifiable test has been run. It fails, and NOT because 51 is wrong — 2026-09-02

**Status is unchanged: Proposed. `RN.PRESSURE_NATRIURESIS.SLOPE` stays at 20.0.**

Pre-registered in `validation/ecf_salt_response_prereg.md`, committed before any paper was
opened. Reproduce with `python validation/ecf_salt_response_extract.py`.

This record said the volume test *"can fail, and it is independent"*, and that it *"should
be run before this ADR is Accepted rather than after"*. It has been, and it did.

### First, this record's own prediction was stale

It states the model moves `V_ecf` by **0.155 L** across the salt step at `G_pn` = 51. That
was measured on 2026-08-25 — before ADH landed, before the urine solute load tracked
sodium, before blood volume and haematocrit were sourced as sexed pairs, and before
cardiac output became a derivation from stroke volume. **The current figure is 0.176 L.**
Testing sourced data against the stale number would have tested nothing.

Re-measuring also produced the thing that makes the test sharp: **the map from `G_pn` to
the volume response is exactly inverse**, `G_pn × ΔV₁₀₀ = 8.786` at every value swept. So
the test inverts to arithmetic rather than to a judgement.

### The evidence

**van den Bosch 2021** (`Physiol Rep` 2021;9(24):e15103, PMID 34921521), n = 70 healthy
men, crossover, 7 days per level, ECFV as iothalamate distribution volume, intake
**verified by 24 h urinary sodium** — 230 against 38 mmol/24 h. The only study found that
reports volume, pressure **and** cohort mass in the same subjects.

| | measured | per 100 mmol/day |
|---|---|---|
| ΔMAP | 88 → 86 mmHg | 1.042 mmHg |
| ΔECFV | 1.061 L (17.4 → 16.5 L/1.73 m², BSA 2.04) | 0.553 L |
| Δbody weight | 80.6 → 79.2 kg | 0.729 kg |

### Test B fails by 5.2×, and Test B was pre-registered to override

    human   ΔMAP / ΔV_ecf  =  1.885 mmHg/L
    model   ΔMAP / ΔV_ecf  =  9.80  mmHg/L   (11.285 at 70 kg, scaling as 1/mass)

The pre-registered failure threshold was a factor of 2. It fails at 5.2 on de-indexed
ECFV, 4.4 on ECFV as printed, and 6.9 on body weight — so **it does not depend on the
iothalamate-space caveat or on the 1 kg = 1 L conversion.**

**Test A is separately inconclusive**, exactly as branch A4 describes: the volume-implied
`G_pn` is 15.9 (van den Bosch), 11.0 (Visser 2009), 6.5 (Heer 2009's low-to-normal limb)
and effectively infinite (Heer 2000). That spread crosses every branch boundary.

### The error is in the circulation, and this record predicted the place

> *"the error has moved rather than been fixed — most likely into `G_vr`, `f_pv`, or the
> fractional reabsorption term."*

**`G_pn` and `G_vr` are orthogonal.** Measured, not argued:

| `G_vr` | ΔMAP/100 mmol | ΔV_ecf/100 mmol | ratio (mmHg/L) |
|---|---|---|---|
| 2880 (calibrated) | 4.9577 | 0.4393 | 11.285 |
| 1440 | 4.9578 | 0.8786 | 5.643 |
| 720 | 4.9584 | 1.7573 | 2.822 |
| 554 | 4.9592 | 2.2840 | 2.171 |
| 360 | 4.9637 | 3.5168 | 1.411 |

An **8× change in `G_vr` moves the pressure response by 0.12%** and moves the volume
response exactly inversely. `G_pn` sets ΔMAP; `G_vr` sets ΔMAP/ΔV_ecf. **The human
pressure data and the human volume data therefore identify one parameter each, with no
cross-talk** — which means this model is exactly identifiable from the two of them.

**To match the human ratio, `G_vr` must fall from 2880 to about 554.**

### Why this is not a refutation of 51

The pressure limb is untouched. Three meta-analyses still put the normotensive response at
1.70–2.30 mmHg/100 mmol, still implying `G_pn` = 43.5–58.8, and this test says nothing
against that. What it says is that **accepting 51 on its own would make the volume
response worse** — from 1.26× too small at `G_pn` = 20 to 3.2× too small at 51 — because
`G_pn` moves ΔMAP and ΔV_ecf follows it down at a fixed, wrong ratio.

**The sequencing is therefore: fix `G_vr` first, then re-run this test, then accept.**
`G_vr` is `calibrated`, never measured, and replacing it with sourced venous compliance is
already HANDOVER §4 item 1. This test has now given that work a **number to hit** and an
independent human datum to hit it against, which it did not have before.

### A declared conflict, recorded and not resolved

A second group reports the opposite. **Heer 2000** (PMID 10751219, n = 32, metabolic ward,
50–550 meq/day) found plasma volume rose dose-dependently while **total body water and body
mass did not increase at all**, concluding that sodium drives a fluid *shift* rather than
storage. **Heer 2009** (PMID 19173770, n = 9) found ECV rose 2.02 L from low to normal
intake and then *fell* going to high, attributing the high limb to osmotically inactive
sodium storage on glycosaminoglycans.

Both camps agree that ECF responds across the low-to-normal range, which is where the
model's 103–205 mEq/day step sits; they disagree above ~200 mmol/day, outside it. But
Heer's 2.02 L for the same low-to-normal step is 3.7× van den Bosch's, and **that**
disagreement is inside the range.

**This bears directly on ADR 0004.** Osmotically inactive sodium storage — default OFF in
this model — is precisely the mechanism Heer and Titze invoke for sodium retention without
volume expansion. If that camp is right, the model is missing a mechanism it already has a
record for. Recorded; not acted on here.

### The evidence base, widened the same day — it was one cohort, it is now seven primaries

The verdict above initially rested on a single n = 70 study. Two further sweeps (24
queries, 162 records in total) were run for that reason. **The conclusion did not change;
its magnitude did, and it got a second independent method.**

**The body-weight limb, four independent groups, n-weighted per `pooling.md` rule 3:**

| study | n | Δintake | Δweight | per 100 mmol/day |
|---|---|---|---|---|
| van den Bosch 2021 | 70 | 192 | 1.4 kg | 0.729 |
| Rorije 2018 (PMID 29206647) | 12 | ~150 | 2.5 kg (95% CI 1.7–3.2) | 1.667 |
| Foo 1998 (PMID 9680497) | 18 | 180 | 0.45 ± 0.69 kg | 0.250 |
| Heer 2000 (PMID 10751219) | 32 | 150 | no increase | 0 |

**Pooled: 0.572 kg/100 mmol** (n = 132), or 0.755 excluding Heer's null. Heer's zero is an
*interpretation* of a null result, not a measurement, which is why both are reported.

**The tracer limb gives 0.553 L. Two independent methods agree to 4%.** The
pre-registration declared 1 kg = 1 L in advance and said in §8 that the conversion would
be **falsified** if the two diverged. It is corroborated instead.

**The defensible ratio is the pooled one, and it is 2.7–3.8× rather than 5.2×.** Pairing
the meta-analytic pressure (1.70–2.30 mmHg/100 mmol) with the pooled volume gives
**2.97–4.16 mmHg/L** against the model's 11.285. So `G_vr`'s target is **758–1062**, with
554 as the harshest within-subject reading.

**Why the pooled ratio and not the studies' own pressures.** Kirkendall 1976 (PMID
1249473, n = 8, **four weeks per level** — the closest protocol found to this model's 30
days), Rorije 2018 and Taurio 2023 (PMID 36708156, **n = 510**, the largest dataset found)
all report **no blood pressure change at all**. They are underpowered for the 2 mmHg the
meta-analyses detect — Foo's SD on 24 h SBP is 14.2 with n = 18 — so taking those nulls at
face value would give a ratio of zero and drive `G_vr` to zero, which is absurd. Taurio's
own conclusion is that sodium intake *"predominantly influences extracellular water volume
without a clear effect on blood pressure"*, which is this finding stated independently and
from the other direction.

**And part of the discrepancy is not `G_vr` at all.** `Cardiovascular.jl` computes
`V_blood ~ V_plasma / (1 - Hct)` with `Hct` a **constant parameter**, so red cell volume
expands with plasma across a 30-day salt step. Red cell mass is fixed on that timescale —
plasma expansion *dilutes* the haematocrit. `dV_blood/dV_ecf` should be `f_pv` = 0.211,
not `f_pv/(1-Hct)` = 0.386: **a factor of 1.83**, which would take the model ratio to 6.17
and leave `G_vr` needing only 1.5–2.8×, i.e. roughly 1000–1950.

**Diagnosed from the equation and from the arithmetic that reproduces 11.285 exactly. Not
yet run.** Its justification is independent of this test — red cell mass does not track
plasma over 30 days — but it was found while looking for the source of the discrepancy,
and that is declared rather than presented as an independent coincidence. It also makes
the sourced haematocrit pair **identifiable for the first time**: `f_pv` and `Hct` cancel
in the level, which is HANDOVER §3.5, but they do not cancel in the derivative.

## The 1.83× was real, and with it fixed the endpoint is visible — 2026-09-02

**Status is still Proposed and `G_pn` is still 20.0.** What changed is that the obstacle
has been measured, halved, and located precisely.

The red cell defect diagnosed above has been **fixed and run**. `Cardiovascular.jl`
computed `V_blood ~ V_plasma/(1 - Hct)` with `Hct` constant, so red cell volume expanded
with plasma over a 30-day salt step; it is now `V_blood ~ V_plasma + Hct*BV0`, and the
relation is reclassified `definitional` → `conservation`. The nominal operating point is
bit-identical by construction. `dMAP/dV_ecf` fell **11.285 → 6.173**, exactly the predicted
1/(1−Hct) = 1.83.

**So the residual on `G_vr` is 1.5–2.1×, not 2.7–5.2×, and its target is 1012–1941.**

### The endpoint, measured

| config | ΔMAP/100 mmol | ΔV/100 mmol | ratio (mmHg/L) |
|---|---|---|---|
| current (`G_pn` 20, `G_vr` 2880) | 4.958 | 0.803 | 6.173 |
| **this ADR alone** (51, 2880) | **1.944** ✓ | 0.315 ✗ | 6.173 ✗ |
| `G_vr` alone (20, 1400) | 4.958 ✗ | 1.652 ✗ | **3.001** ✓ |
| **both** (51, 1400) | **1.944** ✓ | **0.648** ✓ | **3.001** ✓ |
| **human** | **1.70–2.30** | **0.553–0.572** | **2.97–4.16** |

**Neither correction alone lands. Together they land on all three human quantities at
once.** That is the orthogonality result made operational, and it is the strongest
statement this record can now make: **the pressure evidence behind 51 was right, and the
volume objection was never about `G_pn`.**

1400 is illustrative and must not be entered. `G_vr` is `calibrated` and HANDOVER §4 item 1
is to **replace** it with sourced venous compliance; this table is the target that work has
to explain. Fitting 2880 to 1400 would swap one calibrated constant for another and destroy
the only independent test this record has.

**Sequencing is unchanged and now fully specified.** Source venous compliance → re-run
`validation/ecf_salt_response_extract.py` → if the ratio lands in 2.97–4.16, accept this
ADR and move `G_pn` to 51 in the same change, because the table above says the two are only
correct together.
