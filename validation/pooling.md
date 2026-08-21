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
