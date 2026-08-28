# Pre-registration: the six `Standard physiological reference. VERIFY.` rows

**Written BEFORE any source was opened.** One pre-registration for all six rather
than six, per directive 1.10 — the decision procedure is the same shape for each
and six separate documents would be duplication, not rigour.

Date: 2026-08-27. Targets, all carrying the identical non-citation
`Standard physiological reference. VERIFY.` in the citation column:

| row | value | method claimed |
|---|---|---|
| `RN.GFR.NOMINAL` | 180 L/day | `reported` |
| `RN.NA.FRACTIONAL_REABSORPTION` | 0.9918651 | `derived` |
| `RN.H2O.OBLIGATORY_LOSS` | 0.5 L/day | `reported` |
| `CV.CO.NOMINAL` | 7200 L/day | `derived` |
| `CV.BLOOD_VOLUME.NOMINAL` | 5.0 L | `reported` |
| `CV.HEMATOCRIT.NOMINAL` | 0.45 | `reported` |

## Why these, and why now

Eight rows carried this string. Two have been discharged and **both were materially
wrong**: `CV.MAP.SETPOINT` was the brachial 120/80 convention and had silently
disabled RAAS; `RN.AUTOREG.LOWER` was 20 mmHg off with the wrong species. A row
claiming `reported` asserts a source exists. For both discharged rows that
assertion was false.

Since 2026-08-27 every extensive quantity here also scales with body mass
(`src/scaling.jl`), so an error in `RN.GFR.NOMINAL` or `CV.CO.NOMINAL` now
propagates further than it did.

## The rows split in two, and the split is fixed here

**`derived` rows do not need a literature search.** A derived value needs its
DERIVATION stated and checkable, not a citation. Where the derivation is exact
arithmetic over other ledger rows, the fix is to write it down — searching for a
source would be answering a question the row is not asking.

- `RN.NA.FRACTIONAL_REABSORPTION` is **exactly** `1 - Na_intake/(GFR0 * C_Na)` =
  `1 - 205/(180*140)` = 0.9918650793…, i.e. it is pinned by requiring sodium
  balance at the operating point. **Verified before writing this.**
- `CV.CO.NOMINAL`'s own note says it is `5 L/min * 1440`. That is a UNIT
  CONVERSION, so the derivation discharges the arithmetic but **not** the 5 L/min,
  which remains unsourced and is what the VERIFY is really about.

**`reported` rows need a primary source or a demotion.** Four of them:
`RN.GFR.NOMINAL`, `RN.H2O.OBLIGATORY_LOSS`, `CV.BLOOD_VOLUME.NOMINAL`,
`CV.HEMATOCRIT.NOMINAL`, plus the 5 L/min behind `CV.CO.NOMINAL`.

## Declared decision procedure, applied per row, first match taken

1. **Exact derivation over existing ledger rows** → state it in the citation,
   `extraction_method = derived`, and add a `check_closure.py` assertion if one
   does not already cover it. No search.
2. **Whitelisted public reference dataset** (`SOURCES.md` Tier A names NHANES and
   ICRP Publication 89) reporting the quantity, by sex where the quantity is
   dimorphic → take it. `single-source`, k = 1, survey/population recorded.
3. **≥ 2 independent human primary studies** with n and dispersion →
   `pooled-inverse-variance`; with n only → `pooled-n-weighted`.
4. **Exactly 1 human primary study** → `single-source`, k = 1, said plainly.
5. **Animal primary only** → species corrected, tested range recorded, and per the
   ADR 0006 amendment the ethical-ceiling promotion applies ONLY if the human
   experiment cannot be performed. For all six of these it plainly can.
6. **Nothing** → value unchanged, `extraction_method` **demoted to `assumed`**,
   citation emptied, and the debt recorded. **A row that cannot name a source must
   stop claiming one.** This is the branch that must not be avoided by reaching for
   a textbook nobody opened.

## Constraints fixed in advance

- **Directive 1.5 governs absolutely.** These are exactly the values everybody
  "knows" — 5 L/min, 125 mL/min, 5 litres, 45%. Recalling a number is not opening a
  source. If the primary cannot be reached, branch 6 applies; a demotion to
  `assumed` with an honest note is a BETTER outcome than a plausible citation.
- **`CV.HEMATOCRIT.NOMINAL` is expected to be dimorphic** — androgen-driven
  erythropoiesis is not a body-size effect and will not dissolve into `body_mass`.
  Its own ledger note already says sex is deferred. Under ADR 0014 it becomes a
  male/female pair or stays `both`; **never one sex alone.**
- **Values will move and that is expected.** `RN.GFR.NOMINAL` and
  `CV.CO.NOMINAL` set the renal input and the pressure operating point
  respectively. `CV.CO.NOMINAL` moving drags `CV.TPR.NOMINAL` (= MAP/CO) and
  `CV.SV.NOMINAL` (= CO/(HR*1440)) with it, exactly as `CV.MAP.SETPOINT` did.
  **Do not prefer a source because its number is near the incumbent.**
- **`RN.NA.FRACTIONAL_REABSORPTION` KEEPS 7 SIGNIFICANT FIGURES.** Directive 1.9's
  recorded exception: the information is in `1 - FR_Na = 0.0081`, and rounding to
  0.9919 broke sodium balance by 0.43% immediately. Any change must preserve the
  digits on the difference.
- **If `RN.GFR.NOMINAL` moves, `RN.NA.FRACTIONAL_REABSORPTION` moves with it** by
  the derivation above. They are not independent and must not be re-entered as if
  they were.

## Out of scope

- `G_pn` / ADR 0013.
- Body surface area and height (§4 item 5 of the handover).
- The chronotropic baroreflex.
