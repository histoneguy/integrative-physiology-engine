# Pre-registration: BF.BODY_MASS.REFERENCE, sexed pair and population spread

**Written BEFORE any source was opened**, as required by `validation/pooling.md`.

Date: 2026-08-27. Target: `BF.BODY_MASS.REFERENCE`, currently 70.0 kg, `assumed`,
tier C, `sex = both`, with no citation — entered deliberately that way on
2026-08-27 so that promoting body mass to a ledger row changed nothing while the
scaling structure was built and tested.

## Why this row is worth more than its face value

Every extensive quantity in the model now scales through it (`src/scaling.jl`):
ECF and ICF volume, blood volume, GFR, cardiac output, stroke volume, sodium and
water intake, urinary solute load, and the pressure-natriuresis gain. It is the
single largest lever in the ledger. HANDOVER §5 calls body mass the largest
un-modelled dimorphism precisely because of this.

## TWO quantities are needed, and they are not the same quantity

This was nearly missed and is fixed here in advance.

1. **A REFERENCE mass**, per sex — the value at which `size_factor` returns 1.0.
2. **A POPULATION DISTRIBUTION** — mean *and* dispersion, per sex. `ensemble.jl`
   carries `sample_population(n; body_mass_dist = Normal(70.0, 12.0))`. **That
   mean and that SD are hard-coded and unledgered**, which directive 1.4 forbids.
   It was inert while nothing called the ensemble; the ensemble now runs, so it
   is live and it is currently driving every population result.

A source giving only a reference individual satisfies (1) and not (2).

## Question

What is the mean and standard deviation of adult body mass, by sex, in a defined
general population, from a source this repo's `SOURCES.md` already admits?

## Declared decision procedure

Applied in strict order; first match taken. Fixed before any source is opened.

1. **A whitelisted public reference dataset reporting mean AND dispersion by
   sex** (`SOURCES.md` Tier A names NHANES and ICRP Publication 89 explicitly)
   → take mean and SD per sex. `pooling_rule = single-source`, k = 1, and record
   the survey years and the population it describes.
2. **Two or more such datasets** → `pooled-n-weighted` across surveys, provided
   they describe comparable populations. Do **not** pool across countries: a
   pooled US/Japanese body mass describes no population, the same objection
   `pooling.md` makes to pooling across species.
3. **A whitelisted dataset giving a reference value per sex but NO dispersion**
   (this is the expected shape of ICRP 89, which reports a Reference Male and
   Reference Female rather than a distribution) → adopt it for quantity (1),
   `extraction_method = reported`, and **leave the ensemble SD as declared
   debt**. Do not invent a dispersion, and do not reuse the existing 12.0 as
   though the new source supported it.
4. **Nothing whitelisted resolves** → the row stays `assumed` at 70.0 `both`, and
   the failure is recorded. **No value is manufactured and no sexed pair is
   entered on a number nobody opened.**

## Constraints fixed in advance

- **ADR 0014 is binding: a parameter has either one `both` row or BOTH a male and
  a female row, never one alone.** If only one sex resolves, the row stays `both`
  with the cohort recorded in its notes.
- **Directive 1.5 governs.** ICRP 89's reference masses are widely quoted from
  memory. If the primary document cannot be opened, whatever secondary is used is
  recorded as a secondary with its own citation and the row is tier B, not tier A.
  A number I believe to be right but have not read is not entered as `reported`.
- **The reference value and the distribution mean may legitimately differ**, and
  if they do, that is recorded rather than reconciled. A radiological-protection
  Reference Male is a standardised construct; a survey mean is an estimate of a
  real population. They answer different questions and the model uses them in
  different places.
- **This must move the model, and that is expected.** Unlike the 2026-08-27
  structural pass — where `size_factor` returning exactly 1.0 kept the reference
  individual bit-identical — a male/female pair away from 70.0 will move every
  extensive quantity for both sexes. Steady states will shift. **That is the
  point of the row and is not grounds for choosing a value nearer 70.**
- **`MAP` must remain size-invariant.** The test asserting that is the tripwire:
  if entering the pair moves arterial pressure, the scaling has leaked into an
  intensive quantity and the extraction has exposed a defect in `scaling.jl`
  rather than in the number.

## Out of scope

- **Height and body surface area.** GFR and cardiac output properly scale with
  BSA, sub-linearly in mass; `scaling.jl` records that linear scaling overstates
  their spread. Fixing it needs a height row and a BSA formula, each with its own
  extraction. Not opened here.
- Body composition, fat-free mass, and the ICF/ECF mass fractions, which are
  separate ledger rows with their own provenance.
- `RN.GFR.NOMINAL` and the five other rows still carrying
  `Standard physiological reference. VERIFY.`
