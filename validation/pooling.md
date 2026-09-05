# Literature Value Pooling Policy

**Binding. Fix before extracting any parameter from more than one source.**
Companion to `validation/averaging.md`, which governs averaging *within* a
dataset over time. This governs averaging *across* studies.

## The problem

The standing directive is to prefer fundamental, heavily-referenced publications.
Those publications are usually reviews, and reviews report **ranges across
studies**, not values. So the directive that tells us which sources to read is
the same directive that creates an averaging problem. Both halves have to be
answered or the source choice is worthless.

A pooling rule chosen *after* seeing the numbers is unfalsifiable. It is the
same failure `averaging.md` was written to prevent, one level up: individually
defensible choices that are collectively inconsistent and undetectable
downstream.

## The rule

**Declare the pooling rule before extraction, in `pooling_rule`. Any reasonable
fixed rule beats a well-chosen variable one.**

### Rule selection, in strict order of preference

1. **`meta-analysis`** — the source has already pooled, with a stated method.
   Take its estimate and its dispersion; do not re-pool. This is the preferred
   outcome and is what "fundamental publication with many references" should
   mean in practice. Record the source's own k.
2. **`pooled-inverse-variance`** — individual study estimates with SD and n are
   available. Standard random-effects weighting.
3. **`pooled-n-weighted`** — individual estimates with n but no dispersion.
4. **`pooled-geometric`** — for **ratio, gain, and dimensionless multiplier**
   quantities. The arithmetic mean of a ratio and its reciprocal is biased away
   from 1; the geometric mean is not. Use for open-loop gains, fractional
   quantities, and any parameter whose natural null value is 1.0.
5. **`pooled-unweighted`** — individual estimates, no n, no dispersion.
6. **`single-source`** — one study. Say so; do not dress it as consensus.

**AND PRECISION IS PART OF THE RULE, NOT A TIDINESS CONCERN.** A pooled or
converted value carries the significant figures of the measurements behind it
and no more. Converting a unit does not create a digit: 1.29 ng/100 mL is three
figures in pmol/L too. **`derived` rows are the exception** — they are
arithmetic on other rows rather than claims about a measurement, and truncating
them breaks the closure checks that recompute them. Directive 1.9.

### Prohibited

- **`range-midpoint` is prohibited for new entries.** Taking the midpoint of a
  reported min and max uses two numbers and discards every other study. It is
  maximally sensitive to the two most extreme results in the set. If a review
  reports a range across k studies, go to the k primary papers and pool their
  point estimates. Existing rows using it are grandfathered and listed as debt
  below.
- **Pooling across species.** Record species per source. If only animal data
  exist, the parameter is animal-derived and must say so — averaging a dog value
  with a human value produces a number describing no organism.
- **Pooling across incompatible measurement methods.** `extraction_method`
  already exists to separate these; a bioimpedance body-water fraction and an
  isotope-dilution one are not two measurements of the same thing.

  **AND THAT RULE HAS A LIMIT, ADDED 2026-09-05 AFTER IT WAS MISAPPLIED.** It
  exists to stop a *real* method difference being averaged into a number that
  describes neither method. It is **not** a licence to choose one of two
  estimates that agree. `THY.TSH.FT4_SLOPE` was entered as one study's 0.13585
  with a second study's 0.1345 demoted to "corroboration, not the value", on the
  strength of this bullet — **a 1% difference**, a fifth of any plausible error
  on either. Choosing there is a coin toss with a justification attached, and it
  throws away the one thing two estimates give you for free: a spread.

  **The test: would the two numbers be distinguishable given their own
  uncertainty?** If not, pool them and record the spread as the uncertainty,
  whatever the methods were. If yes, the method difference is real and this
  prohibition applies. Say which test was applied and why on the row.

  **AND THERE IS A STRONGER PROHIBITION THIS ONE DOES NOT IMPLY: DO NOT COMPOSE
  ACROSS INCOMPATIBLE METHODS EITHER.** Not pooling two free-thyroxine assays into
  one number is necessary and was not sufficient — the ledger kept them separate
  and then multiplied a slope measured in `1/(pmol/L)` on one assay by a
  concentration in `pmol/L` from another, which is a unit error and produced a
  hormone level 2.2× wrong. **Whenever two rows are multiplied, divided or added,
  they must share a measurement scale, not merely a unit symbol.** Where they
  cannot, find the DIMENSIONLESS combination that is scale-invariant and source
  that instead: `THY.LOOP_GAIN` exists for exactly this reason.

  **The spread is the point, not a formality.** Having both ends of
  `THY.TSH.FT4_SLOPE` made it possible to sweep the slope through the model and
  show it moves the disputed output by 2% against a discrepancy of 2.4× —
  turning "the slope is not the problem" from an argument into arithmetic.
- **Silent re-pooling of a meta-analytic estimate** with additional primary
  studies already inside it. Double-counting.

## Required fields

Added to `ledger/parameters.csv`:

    pooling_rule      one of the values above
    n_studies         k, the number of INDEPENDENT studies behind the value
    pooling_notes     which studies, which were excluded, and why

`n_studies` is the field that makes the directive checkable. A tier A value with
k = 1 is a contradiction that should be visible.

## Precedence against the primary-source directive

The two directives collide when a heavily-cited review reports a number that its
own primary sources do not support. **The primary source wins**, and the
divergence is logged in `pooling_notes` — the same discipline as the
fidelity-vs-quality rule for HumMod. A review's citation count measures its
influence, not the quality of the number it happens to quote.

## Known debt at adoption

- **`BR.OPEN_LOOP_GAIN = 2.0`** — the note states the value is the mid-range of
  a 1.0–3.5 range spanning Kent 1972, Shoukas and Sagawa 1973, McRitchie 1976,
  Burattini 1994, Sato 1999 and Sunagawa 2001. **The arithmetic midpoint of
  1.0 and 3.5 is 2.25, not 2.0**, so the recorded rule and the recorded value
  disagree. It is also a ratio quantity, whose geometric mean is 1.871. The
  three candidates give closed-loop buffering factors 1/(1+G) of 0.308, 0.333
  and 0.348. Resolve by going to the six primary papers and pooling their point
  estimates under rule 2, 3 or 4. Cited via Yamasaki 2021, a secondary source
  for a set of primary results.
- **`RN.AUTOREG.LOWER` / `RN.AUTOREG.UPPER`** — citation reads "Standard
  physiological reference. VERIFY." That is not a reference. Same defect as
  `Renal.GFR` in `relations.csv`.
- **`BF.NA.PLASMA_SETPOINT`, `BF.OSM.PLASMA_SETPOINT`** — trace only to clinical
  convention; already flagged in HANDOVER.md section 6.
- 16 of 41 existing rows imply a range or multiple studies. None records a
  pooling rule, because the field did not exist.
