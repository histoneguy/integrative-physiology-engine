# Pre-registration: sourcing the ANP evidence rows of ADR 0010

**Written 2026-08-21, BEFORE any paper was read.**
Binding under `validation/pooling.md`: a pooling rule chosen after seeing the numbers
is unfalsifiable.

Companion to `validation/autoreg_upper_prereg.md`, which did the same for
`RN.AUTOREG.UPPER`.

## What is being extracted

Four rows in `docs/adr/0010-anp-volume-natriuresis.md` currently read
`[SOURCE REQUIRED]`. ADR 0010 cannot move from Proposed to Accepted until they carry
citations, and the component cannot be built until ADR 0010 is Accepted.

| # | Claim | Kind | Becomes a ledger parameter? |
|---|---|---|---|
| 1 | ANP is secreted by atrial myocytes in response to atrial wall stretch | structural, qualitative | No |
| 2 | ANP increases renal sodium excretion in humans | structural, qualitative | No |
| 3 | Quantitative dose-response: plasma ANP to fractional sodium excretion | **numeric** | **Yes** - the ANP gain |
| 4 | ANP roughly doubles during mineralocorticoid escape (Yokota, PMID 2966064) | numeric, corroborating | No - validation target |

Row 4 is a **verification**, not an extraction. That citation was inherited
second-hand from `incoming/Raas.jl` and has never been independently checked. It is
listed here so that checking it is a declared act rather than an assumption.

## Pooling rules, declared in advance

Per `pooling.md`, in its stated order of preference.

**Rows 1 and 2** are qualitative structural claims and take no pooling rule. They need
a primary source and a species, nothing more. A review is acceptable *as* the source
for a textbook-level phenomenon, provided it is cited as the review it is.

**Row 3 is the one that matters**, because it is the only row that becomes a number.
Declared before extraction, in this order:

1. If a **meta-analysis or systematic review** reports a pooled dose-response, take its
   estimate and its dispersion. Do not re-pool. Record its own k. → `meta-analysis`
2. Else, if individual human ANP infusion studies report an effect with n and
   dispersion → `pooled-inverse-variance`
3. Else, if they report n but no dispersion → `pooled-n-weighted`
4. **If the quantity is expressed as a fold-change, ratio or multiplier** - which a
   gain on fractional reabsorption is likely to be - → `pooled-geometric`, per
   `pooling.md`, because the arithmetic mean of a ratio and its reciprocal is biased
   away from 1
5. Else, one study only → `single-source`, declared as such, k=1, not dressed as
   consensus

`range-midpoint` is **prohibited** and will not be used regardless of what the
literature offers.

**Row 4** → `single-source`, k=1. Verification of an existing claim.

## Species policy

Under ADR 0006 as amended 2026-08-21:

- Human data preferred where it exists. ANP **infusion** studies in humans are
  ethically routine, so unlike the autoregulation breakpoint there is no ethical
  ceiling excusing an animal-only sourcing here. **If row 3 turns out to be
  animal-only, that is a genuine gap and must be recorded as such, not waved through
  under the amendment.** The amendment covers experiments that cannot be done, not
  experiments that merely were not.
- Where animal data is used, species, preparation and tested range are recorded.
- **No cross-species pooling**, under any circumstances.

## Stop conditions, declared in advance

1. **If row 3 cannot be sourced, ADR 0010 does not proceed.** The E3 rows
   (Seeliger, Bie) motivate having a volume-sensing component but set no number. They
   do not license building one. No component is written against a gain nobody measured.
2. **A claim that cannot be sourced stays `[SOURCE REQUIRED]`.** It is not replaced
   with a plausible-looking citation, and it is not quietly softened until it no longer
   needs one. Two errors of exactly that shape were made in this project on 2026-08-20,
   both asserting that a classic curve was nonlinear, both wrong, both from memory.
3. **If row 4 fails verification**, the Yokota claim is struck from ADR 0010 and from
   `incoming/Raas.jl`, and the fact that it propagated unverified is recorded.
4. **A sourced number that contradicts the model is a finding, not a problem.** If the
   measured ANP gain implies the pressure term is doing even more work than the 3.68x
   already suggests, that gets written down, not tuned around.

## What would falsify the premise

ADR 0010 rests on the claim that the missing volume-sensing path explains the inflated
`RN.PRESSURE_NATRIURESIS.SLOPE`. If the sourced ANP gain turns out to be too small to
account for a 3.68x discrepancy, the premise is wrong and the ADR should say so rather
than proceed. Record the magnitude comparison explicitly, whichever way it falls.
