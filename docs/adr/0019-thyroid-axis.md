# ADR 0019: The hypothalamic-pituitary-thyroid axis, and metabolic rate as an output

**Status:** Accepted
**Date:** 2026-09-04, **amended twice on 2026-09-05 — read A5 before A2**
**Evidence tier:** E1 for negative feedback of thyroid hormone on thyrotropin and for
the log-linear form of that feedback; E1 for thyroid hormone setting resting metabolic
rate; E2 for the quantitative slope, which is measured in humans but varies severalfold
between individuals.

## Context

**The model already has two endocrine components and neither is called that.** RAAS and
ADH are endocrine axes; they were built as parts of the pressure and water loops. So
"add the endocrine system" is not adding a first hormone, it is adding the axes that
are not already there in service of something else.

**Thyroid is the one that connects.** ADR 0017 built a respiratory component whose load
is `RESP.CO2.PRODUCTION`, currently `assumed` at a round teaching number because no
admissible source could be opened. **Thyroid hormone is the principal regulator of
resting metabolic rate**, and metabolic rate is what sets CO2 production. So this axis
does not arrive as an island: it drives a quantity another component already consumes,
which is the condition ADR 0006 records Circadian failing.

**And it repeats the model's thesis in a third system.** Arterial pressure is an output
of the renal loop. Thyrotropin is an output of the thyroid loop — a controlled variable
that nothing sets, landing where secretion and feedback balance. Whether that survives
contact with the data is the question ADR 0017's did not.

## Evidence

| Claim | Tier | Basis | Species |
|---|---|---|---|
| Thyroid hormone inhibits thyrotropin secretion; the axis is a negative feedback loop | E1 | Multiply replicated, the basis of all thyroid function testing | human |
| The relationship between thyrotropin and free thyroxine is approximately **log-linear** | E1 | The standard description, and the reason thyrotropin is reported on a log scale clinically | human |
| Thyroid hormone sets resting energy expenditure | E1 | Multiply replicated; hypothyroidism lowers it and thyrotoxicosis raises it | human |
| Each person has an individual setpoint, and between-person variation is much wider than within-person | E2 | Measured in healthy volunteers | human |

**Numbers are now in the ledger.** `validation/thyroid_extract.py` is the record
of how they were obtained and `validation/thyroid_prereg.md` §8 records the four
amendments the sourcing forced.

**Same constraint as ADR 0018:** primary experimental literature and published
mathematical relationships only. Other whole-body simulation models are not sources.

## Decision

**1. Thyrotropin is an OUTPUT of the loop.** Secretion falls log-linearly with free
thyroxine; thyroxine secretion rises with thyrotropin. The resting pair is where they
cross, not a pair of setpoints entered separately.

**2. Metabolic rate becomes a modelled quantity and stops being a constant.**
`RESP.CO2.PRODUCTION` becomes the product of a reference production and a thyroid
activity multiplier that is 1.0 at the euthyroid point. **The reference individual must
therefore be unmoved**, exactly as the respiratory water split left the water balance
unmoved, and for the same reason: every downstream quantity was closed on the old value.

**3. It is a two-state loop and that is a real cost, stated rather than hidden.**
Thyroxine turns over with a half-life of about a week and thyrotropin in minutes, so
unlike respiration this axis is NOT quasi-static on a 30-day horizon — the whole point
of it is a slow state. Two new states against eight existing, and directive 1.10 says
that is paid on every future run. **It is justified only because the slowness is the
physiology**: an axis whose response takes weeks cannot be represented by an algebraic
relation on a model that runs for four hundred days.

**4. The thyrotropin-thyroxine feedback and the metabolic effect are SEPARATELY
switchable**, with the metabolic arm defaulting OFF until it is sourced. The feedback
loop is E1 and defaults on; the quantitative effect on CO2 production is the part most
likely to be wrong, and it moves ventilation and therefore water balance.

## Consequences

- **A third new subsystem**, and the first that is endocrine in its own right rather
  than in service of pressure or water.
- **`RESP.CO2.PRODUCTION` stops being a primitive** if the metabolic arm lands. It
  becomes a reference value times a modelled multiplier — the same transition
  `CV.CO.NOMINAL` and `RN.H2O.OBLIGATORY_LOSS` made.
- **It makes thyroid disease representable**, which is the first disease state this
  model could express: hypothyroidism as reduced thyroxine secretion, thyrotoxicosis as
  raised. Neither is built here.
- **It does NOT open the other axes.** Cortisol, growth hormone, insulin and glucose,
  parathyroid and calcium are all absent and stay absent.
- **The respiratory exchange ratio remains assumed.** Thyroid changes substrate
  utilisation and therefore that ratio; this record does not model it.

## What this lumping disqualifies as evidence

**Collapsing thyroxine and triiodothyronine into one hormone.** The model will carry
free thyroxine as the feedback signal and the tissue effect, when in fact
triiodothyronine is the active hormone at the receptor and most of it is produced by
peripheral deiodination rather than secreted.

**No longer usable for calibration:** anything whose perturbed variable is the
conversion between the two. Deiodinase inhibition, the low-triiodothyronine state of
illness, amiodarone and propylthiouracil effects, selenium status, and the difference
between thyroxine monotherapy and combination therapy — that last being an active
clinical controversy this model has just excluded itself from.

**Still usable:** the thyrotropin-thyroxine relationship in healthy people, and resting
energy expenditure against thyroid status.

## Falsifiable test

1. **Thyrotropin must be an output.** Raise thyroxine secretion capacity; thyrotropin
   must FALL and free thyroxine must rise by less than it would with the loop open.
   Opening the loop must give the full uncontrolled rise. If thyrotropin does not move,
   the loop has been written as a setpoint by accident.
2. **The euthyroid point must land inside human reference intervals for BOTH hormones
   at once**, with neither entered as a target. This is a genuine prediction and it can
   fail: two reference intervals, one crossing point.
3. **The slow state must actually be slow.** A step in secretion capacity must take
   weeks, not hours, to re-equilibrate. If it settles in hours the time constants have
   been entered in the wrong units and decision 3's justification evaporates.
4. **With the metabolic arm off, every existing result must be bit-identical.**

## Amendment, 2026-09-05: three decisions changed by contact with the sources

**This ADR was written before any source was opened and was implemented a day
later. Three of its four decisions survived; one did not, and one falsifiable
test was failed on the conservative reading.** All of it is here rather than
rewritten into the record above, for the reason ADR 0017's amendment gives: a
decision record that quietly becomes correct is not a record.

### A1. Decision 3 is wrong about the cost, in the cheap direction — ONE state

*"It is a two-state loop and that is a real cost."* It is a one-state loop.
Thyrotropin turns over in minutes against a thyroxine time constant of 10.3 days
and a horizon of 400, so the pituitary limb is algebraic — the fallback
`thyroid_prereg.md` §4 wrote down in advance, taken by inspection rather than
after measuring a slowdown, because a state relaxing four orders of magnitude
faster than anything integrated here cannot repay directive 1.10.

**The justification decision 3 gives is unchanged and now applies to exactly one
state:** the slowness is the physiology, and ten days cannot be an algebraic
relation on a model that runs four hundred. That is the only state this model has
ever gained by choosing to.

### A2. Decision 1 stands, and THE MODEL FAILS FALSIFIABLE TEST 2 ON THE
CONSERVATIVE READING

Thyrotropin *is* an output — nothing sets it, and it lands where the sourced
pituitary line meets the sourced thyroxine level. **It lands at 3.35 mIU/L.**

That is inside the conventional 0.4–4.0 interval, which is the letter of test 2.
It is also **2.4× the NHANES III reference-population geometric mean of 1.40
mIU/L** (n = 13,344), and 0.4–4.0 is itself the kind of round number directive
1.12 says not to trust. **Treated as a failure, reported, and not tuned** —
branch T2 of the pre-registration.

**The decomposition is unambiguous and is the useful part.** Of the three sourced
inputs, the slope has two independent estimates agreeing to 1%, the euthyroid
free thyroxine has two agreeing within a standard deviation, and the intercept
has one. Reconstructing the intercept from independent euthyroid pairs at the
agreed slope gives 2.58–2.80 against the entered 3.45, and sweeping the slope
across its whole two-source spread moves the prediction by only 2%. **The
intercept carries the whole discrepancy, arithmetically and not rhetorically, and
it is an extrapolation to FT4 = 0 from data that never went near zero — the third
time this repository has been bitten by that exact move.**

**It is not replaced.** Every reconstruction is built from a measured euthyroid
thyrotropin, which is the quantity this test judges.

### A3. Decision 2 is built but stays OFF, and decision 4 is why

`RESP.CO2.PRODUCTION` is now a reference production times a modelled multiplier,
and **the multiplier is exactly 1.0 unless the arm is switched on**, which
decision 4 already required. So the transition decision 2 describes has been made
structurally and has changed no result.

The gain behind it comes from a preparation `thyroid_prereg.md` §2 excludes —
hyperthyroid patients — because the exclusion is unsatisfiable for this quantity:
a healthy person cannot ethically be made thyrotoxic. §8.3 relaxes it for that
one row and records the relaxation. **Decision 4, written before any of this,
is what makes that safe**: the arm the relaxed row feeds is off by default.

### A4. What the loop got RIGHT, and it was not fitted

The open-loop gain falls out at `b·FT4 = 2.24`, so `d ln FT4 / d ln(secretory
capacity) = 0.31`: **the human axis absorbs about 70% of a change in thyroid
secretory capacity.** Nothing in this repository was fitted to that number and
nothing is validated against it. It is what the two sourced gains imply, and it
is the claim most worth trying to falsify next.

### A5. Amended again 2026-09-05: falsifiable test 2 was ILL-POSED, not failed

**A2 above says the model fails falsifiable test 2 by 2.4×. That was wrong, and
the correction is worth more than the original finding.**

The test asks whether the loop's crossing point lands inside human reference
intervals with neither hormone entered as a target. **A crossing point is a line
meeting a concentration** — and a slope in 1/(pmol/L) composes with a
concentration in pmol/L only when both are on the same free-thyroxine scale. The
record composed a line measured on an immunoassay with a concentration measured
by equilibrium dialysis.

**NHANES 2007–2012 measured the discrepancy instead of leaving it arguable.** In
6814 reference-population adults, total thyroxine is 7.75 µg/dL against
Braverman's 7.30 — agreeing to 6% — while the free fraction is **0.0104% by
immunoassay against 0.0180% by dialysis, a ratio of 1.73.** Two methods agreeing
on the total hormone and disagreeing nearly two-fold on the free fraction are not
two measurements of one quantity.

`thyroid_prereg.md` §2 prohibited *pooling* across free-thyroxine assays. **It
should have prohibited *composing* across them**, which is the stronger and less
obvious error, and that is now in `validation/pooling.md`.

**So test 2 is VOID.** Not failed — ill-posed. The operating point is now an
input, sourced from NHANES, and the dependency inversion is the same one this
record's sibling ADR 0017 made for arterial PCO2.

**What survives is the response, and it is the part that was worth having.**
Tests 1, 3 and 4 are untouched. The open-loop gain `b·FT4*` is **dimensionless
and therefore scale-invariant** — exactly what the measured slopes are not — and
at 2.28 from two independent estimates it is the whole of the axis's dynamic
behaviour. Nothing here was fitted to it.

**And the model barely moved.** The closed-loop response is 0.305 against 0.308
before. What changed is that the numbers are now composable.

## What is NOT decided

- **Triiodothyronine, deiodination, and protein binding.** Free thyroxine only.
- **Thyrotropin-releasing hormone and the hypothalamic level.** The loop is closed at
  the pituitary.
- **Circadian variation in thyrotropin**, which is real and substantial, and which the
  existing clock could drive once this exists.
- **Any disease state.**
- **Every numeric value.** — superseded 2026-09-05; the values are in the ledger
  under `THY.*` and `validation/thyroid_extract.py` is how they were obtained.
- **The thyroid's saturating response to thyrotropin.** `Thyroid.D(FT4)` makes
  secretion linear in thyrotropin, which is a lumping and is labelled as one. The
  only human preparation that measures the real curve uses recombinant
  thyrotropin at roughly a hundred times the physiological range, and
  extrapolating that down is the error amendment A2 records.
