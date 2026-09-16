# Pre-registration — connecting body surface area, and de-indexing what it unlocks

**Written 2026-09-16, before any source is opened, before any NHANES query is run for
these values, and before any de-indexed number is computed.** Verify the ordering with

    git log --diff-filter=A -- validation/deindexing_prereg.md
    git log --diff-filter=A -- validation/deindexing_extract.py

Opened at the owner's instruction as `HANDOVER` §4 item 10, **body surface area**.

---

## 0. THE WORK-LIST ITEM IS HALF DONE AND HALF WRONG, AND WHAT IS LEFT IS SHARPER

§4 item 10 says BSA *"needs a height row and one sourced BSA formula"*. **That was done
on 2026-09-05** — `validation/body_size_scaling_prereg.md`, commits 8ef9d10 and bfd736b.
`BF.HEIGHT.REFERENCE` (sexed, NHANES measured), `BF.BSA.REFERENCE` (sexed, Du Bois) and
`BF.SIZE.EXPONENT` = 0.5083 are all in the ledger. **The third stale entry found in this
work list in two passes**, after items 8 and 9.

**Two of item 10's remaining claims are simply wrong and are struck here:**

- *"unlocks Zhan 2024 (n = 12,812)"* — **no.** `CV.SV.NOMINAL`'s screening note records
  two reasons: it reports reference **LIMITS**, and `pooling.md` prohibits range-midpoint
  for new entries; and it pools a different **contouring convention**. BSA fixes neither.
- *"unlocks Luu 2022 (n = 3,206)"* — **half.** Indexing was one of two reasons. The
  other: Luu contours papillary muscles into LV **mass** rather than volume, *"so it could
  not be pooled with Petersen in any case."*

**What is actually left is better than either.**

### 0.1 NOTHING IN THIS MODEL READS `BF.BSA.REFERENCE`

Verified: no `.jl` or `.py` file outside the generated `LedgerParams.jl` references it.
**It is an unconnected row** — ADR 0006 records exactly that failure for Circadian, and
directive 1.11 is the guard. It was sourced eleven days ago and has done no work since.

### 0.2 IT LEFT AN INSTRUCTION AND THE INSTRUCTION WAS NEVER FOLLOWED

`BF.BSA.REFERENCE`'s own note:

> *IT IS NOT 1.73, AND THAT IS WORTH SAYING BECAUSE 1.73 IS EVERYWHERE. The renal
> indexing convention of 1.73 m² is a 1928 figure for an average adult of that era, not a
> measurement of anyone here … **any quantity de-indexed from a per-1.73-m² figure must
> be multiplied by 1.8545/1.73 and not taken as-is.***

`RN.GFR.NOMINAL`'s note: *"106 mL/min/1.73 m² × 1440 / 1000 = 152.64 → 152.6 L/day"* —
**taken as-is.** A 7.2% correction sits unapplied between two rows in the same ledger,
one of which tells the other what to do.

### 0.3 AND `CV.SV.NOMINAL` DESCRIBES ITS OWN DOUBLE COUNT

> *This value is EXTENSIVE and is multiplied by `size_factor` … so it should be stated at
> 70 kg. Petersen reports body weight by AGE GROUP … but NOT by sex … So this pair still
> carries a body-size component, and in the ensemble — where mass is sampled by sex —
> **that component is counted twice. Fixing it needs sex-stratified cohort mass or a BSA
> row.***

**The BSA row now exists**, and Petersen indexes its own data: 49 ± 10 male and 45 ± 8
female mL/m², the same cohort and the same technique as the absolute pair already
entered. No new source is needed to fix it.

---

## 1. THE STOP CONDITION IS ALREADY WRITTEN IN THE LEDGER, AND IT COMES FIRST

`BF.HEIGHT.REFERENCE`'s own note:

> *IT IS NOT PAIRED WITH THE MODEL'S REFERENCE MASS AND THAT IS A KNOWN INCONSISTENCY.
> This is the mean height of adults averaging 88.4 kg (men); the model's reference
> individual is 70 kg, and shorter people weigh less … It does not matter for model
> BEHAVIOUR … and **it matters by a few per cent for de-indexing**.*

**The correction this pass exists to make is 7%. The row it would be made through is
known to be wrong by "a few per cent", in the same direction.** Using a mispaired BSA to
correct an indexing error is chasing precision that does not exist — failure mode 9, and
the owner has stopped this repository for it before.

**SO STAGE 1 COMES FIRST AND IT IS NOT OPTIONAL.** The reference body must be internally
consistent — the mass and the height must describe the same person — before anything is
de-indexed through it.

**And it needs NO new source.** The NHANES 2007–2012 `BMX` and `DEMO` microdata are
already in `validation/data/nhanes/`, `body_size_scaling_extract.py` already reads them,
and the quantity wanted is the survey-weighted mean height of adults **at the reference
mass** rather than over all adults. That is a different query on data this repository
already downloaded, not a new extraction.

---

## 2. THE QUANTITIES

| id | what | role |
|---|---|---|
| `BF.HEIGHT.REFERENCE` | height of adults **at 70 kg**, sexed | Stage 1; currently the all-adult mean |
| `BF.BSA.REFERENCE` | Du Bois at the reference mass and height | re-derives from it |
| `CV.SV.NOMINAL` | stroke volume at the reference | de-indexed from Petersen's own mL/m² |
| `RN.GFR.NOMINAL` | glomerular filtration at the reference | de-indexed from per-1.73 m² |
| `CV.CO.NOMINAL`, `CV.TPR.NOMINAL` | derived from SV and MAP | follow, and must stay closed |
| `RN.NA.FRACTIONAL_REABSORPTION` | `FR_Na` | **re-derives if GFR moves, and that is the risk** |

---

## 3. THREE STAGES, AND THEY MUST BE MEASURED APART

**STAGE 1 — make the reference body consistent.** Height at the reference mass; BSA
re-derives. **Nothing in the model reads BSA, so this moves no simulated result at all**,
and that is the point: it is free, and it is the precondition for the rest.

**STAGE 2 — de-index `CV.SV.NOMINAL`.** Petersen's own indexed pair, same cohort, same
technique, no new source. This moves the cardiovascular operating point.

**STAGE 3 — de-index `RN.GFR.NOMINAL`.** This is the load-bearing one and it may not
be reached; see B3.

**REPORTING ONE NUMBER FOR THREE CHANGES IS HOW THIS PASS FAILS**, and the urine solute
pass on 2026-09-16 is the precedent: Half A was a bug fix and Half B a sourcing, and
conflating them would have given each credit for the other.

---

## 4. WHAT THIS PASS MAY NOT DO

- **It may not move `BF.BODY_MASS.REFERENCE`.** 70 kg is `assumed` and the model is
  stated at it everywhere. Its mismatch with a population mean of 88.4/75.2 kg is a
  separate debt and stays one.
- **It may not re-estimate `CV.ANP.NATRIURETIC_GAIN` or `RN.PRESSURE_NATRIURESIS.SLOPE`.**
  §3.40 measured `G_anp`'s own interval swinging salt sensitivity by **45%** of baseline,
  nearly twice the next row. Moving GFR and then re-fitting the two parameters that
  carry the model would make any result unfalsifiable.
- **It may not change the Du Bois formula.** `body_size_scaling_prereg.md` §3 fixed the
  choice rule before that search: take the formula the indexed literature used, because
  making that literature usable is the whole point. Newer formulas fit better and are
  already recorded on `BF.SIZE.EXPONENT`.
- **It may not report a sexed GFR as a sourced sex difference.** See B4.
- **It may not touch `BF.SIZE.EXPONENT`.** It was sourced eleven days ago from the same
  microdata and nothing here re-opens it.

---

## 5. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED IN ADVANCE

**1.73 m²** — a 1928 figure for an average adult of that era, and `BF.BSA.REFERENCE`
already says so. **70 kg.** **1.7 m² and 1.8 m²** as "a typical adult". **125 mL/min**
GFR, already caught once in this repository and replaced with a measured 106.
**5 L/min** cardiac output, also already caught. **All are teaching figures**, and this
repository's record on them is four materially wrong of six openable.

---

## 6. WHAT IS ALREADY KNOWN, DECLARED SO THE FREEDOM IS AUDITABLE

- `BF.BSA.REFERENCE` = 1.855 male, 1.748 female, both at 70 kg; the sex difference is
  **height alone**, because the reference mass is a single `both` row.
- `RN.GFR.NOMINAL` = 152.6 L/day from 106 mL/min/1.73 m², **not** de-indexed. The naive
  correction is ×1.8545/1.73 = **1.0719**.
- `CV.SV.NOMINAL` = 96 male / 75 female mL absolute; Petersen also reports **49 ± 10 and
  45 ± 8 mL/m²**. The implied cohort BSA is therefore 96/49 = **1.959** male and
  75/45 = **1.667** female.
- Soares reports **no sex difference in indexed GFR** (108 ± 18 vs 104 ± 18, p = 0.134)
  and pooled the sexes for that reason.
- **THE PREDICTION FIXED IN ADVANCE.** The model's reference is 70 kg for *both* sexes —
  light for a man, heavy for a woman. So de-indexing must move the male stroke volume
  **DOWN** and the female **UP**. If both move the same way, the reference BSA pair is
  wrong and Stage 2 stops.

---

## 7. THE DECISION RULE

- **B1 — the conditional height at the reference mass differs from the current row and
  BSA moves by more than 1%.** Take it. Re-derive `BF.BSA.REFERENCE`, then de-index.
- **B2 — it moves BSA by less than 1%.** The current pair stands. **Record the null and
  proceed**, because a checked null is why Stage 1 exists; do not quietly skip it.
- **B3 — de-indexing GFR moves `FR_Na` enough that a calibrated row drifts outside its
  own stated interval.** **STOP AT STAGE 2.** Record the GFR correction as measured and
  unapplied, with the number, and leave item 10 open for it. The alternative — moving
  GFR and re-fitting `G_pn` and `G_anp` to absorb it — is §5 item 22 committed on
  purpose against the two parameters §3.40 says carry the model.
- **B4 — GFR becomes sexed.** It is `both` today. De-indexing through a sexed BSA
  necessarily creates an absolute sex difference, and **that is a CONSEQUENCE OF BODY
  SIZE AND NOT A FINDING**: Soares measured no difference in the indexed quantity. The
  row must say so in those words, or the next reader will cite this model for a sex
  difference in renal function that nobody measured.
- **B5 — Petersen's implied cohort BSA is not physiologically sensible** for UK Biobank
  adults aged 45–74, or the two sexes do not straddle the reference. Then the indexing
  convention is not what is assumed and **Stage 2 does not proceed**.
- **B6 — the reference individual cannot be made consistent without moving the reference
  MASS.** Record it and stop; §4 forbids moving it here.

---

## 8. THE FALSIFIABLE TESTS ANY RESULTING RECORD MUST INHERIT

1. **`BF.BSA.REFERENCE` is the Du Bois evaluation at the reference mass and height**, to
   closure tolerance. It is bookkeeping and it must stay bookkeeping.
2. **`size_factor(m_ref) = 1` exactly**, for any exponent. Branch S3 of the earlier
   pre-registration, and it must survive this one untouched.
3. **Sodium balance still closes at the reference.** Excretion equals intake. It is
   conservation and cannot be allowed to move, whatever GFR becomes.
4. **The male and female stroke-volume corrections have OPPOSITE SIGNS**, as §6 predicts
   in advance, and each is under 10%.
5. **The reference individual's simulated GFR equals the de-indexed row**, and the
   cardiac output identity `CO0 = HR0 × SV0 × 1440/1000` still closes.
6. **No row in the ledger carries a per-1.73 m² figure un-corrected.** Asserted over the
   ledger rather than over one row, because this pass found the instruction sitting
   unapplied for eleven days and the class is what matters.

---

## 9. WHAT WOULD MAKE THIS PASS A FAILURE

**De-indexing through a reference body that is itself mispaired.** The correction is 7%;
`BF.HEIGHT.REFERENCE` is wrong by "a few per cent" by its own admission, in the same
direction. Applying one without fixing the other would replace a known error with a
disguised one, and every gate would stay green because BSA closes by construction.

**The second is moving GFR and then re-fitting the model back onto its targets.**
Sodium excretion is `GFR × C_Na × (1−FR)`, so a 7% GFR rise must be absorbed somewhere;
`FR_Na` is derived and will absorb it at the operating point, but the *sensitivity* of
excretion to everything acting on it rises with the filtered load. If `G_pn` or `G_anp`
are then re-estimated, the pass has moved a structural number and re-tuned the two
parameters that carry the model to hide it.

**The third is quieter: doing Stage 1, finding it changes nothing, and writing the pass
up as though BSA had been connected.** A row that nothing reads is still a row that
nothing reads. **Connection is Stage 2 and Stage 3, and if neither is reached then
directive 1.11's complaint stands and item 10 stays open.**
