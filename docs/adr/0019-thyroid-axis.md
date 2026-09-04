# ADR 0019: The hypothalamic-pituitary-thyroid axis, and metabolic rate as an output

**Status:** Proposed
**Date:** 2026-09-04
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

**Numbers deferred to `validation/thyroid_prereg.md`.** None opened yet.

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

## What is NOT decided

- **Triiodothyronine, deiodination, and protein binding.** Free thyroxine only.
- **Thyrotropin-releasing hormone and the hypothalamic level.** The loop is closed at
  the pituitary.
- **Circadian variation in thyrotropin**, which is real and substantial, and which the
  existing clock could drive once this exists.
- **Any disease state.**
- **Every numeric value.**
