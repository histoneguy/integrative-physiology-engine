# Pre-registration: the extracellular volume response to chronic sodium intake in normotensive humans

**Written BEFORE any source was opened.** Date: 2026-09-02.

This is **ADR 0013's own falsifiable test**, which that record says must run *before* the
ADR is Accepted rather than after. It exists because reproducing the pressure response is
not a test: `G_pn` was estimated as `100/slope` from the human pressure data, so the model
matching that pressure is arithmetic. **The test has to use a variable that was not used
to set the value.** Volume is that variable.

Companion to `validation/salt_sensitivity_prereg.md`, whose inclusion criteria this
document reuses **verbatim and deliberately** — they were fixed before anyone knew which
way they cut, and re-deciding them now, for a test whose answer we want, is exactly the
move `pooling.md` exists to prevent.

---

## 0. WHAT THE MODEL ALREADY SAYS, STATED FIRST SO IT CANNOT BE QUIETLY MET

Measured on the current model, not quoted from ADR 0013 — that record's figures date from
2026-08-25, before ADH, before the urine solute load tracked sodium, before blood volume
and haematocrit were sourced as sexed pairs, and before cardiac output became a
derivation from stroke volume. Its predicted 0.155 L is **stale**; the current value is
0.172 L. Reproduce with:

    julia --project=. bench/gpn_sweep.jl

**The model's map from `G_pn` to the volume response is exactly inverse.**

| `G_pn` | ΔMAP (mmHg) | ΔV_ecf (L) over 102 mEq/day | ΔV_ecf per 100 mmol/day | `G_pn` × ΔV₁₀₀ |
|---|---|---|---|---|
| 20.0 (incumbent) | 5.0569 | 0.4481 | **0.4393 L** | 8.786 |
| 44.0 | 2.2984 | 0.2037 | 0.1997 L | 8.786 |
| **51.0 (proposed)** | **1.9829** | **0.1757** | **0.1723 L** | 8.786 |
| 59.0 | 1.7141 | 0.1519 | 0.1489 L | 8.786 |
| 188.0 (Graudal) | 0.5379 | 0.0476 | 0.0467 L | 8.786 |

So the model can be **inverted**, and the inversion is the test:

    G_pn  =  8.786 / (ΔV_ecf in litres per 100 mmol/day)     male
    G_pn  =  8.221 / (ΔV_ecf in litres per 100 mmol/day)     female

### Three model facts fixed here because the comparison depends on them

1. **ΔV_ecf per 100 mmol/day is INVARIANT to body mass.** Measured, not derived: 0.4393 L
   at 55, 70 and 85 kg, identical to four decimals, with `G_pn` carrying its own
   body-size scaling as the model applies it. ΔV_ecf ∝ mass at fixed *absolute* `G_pn`
   and `G_pn` ∝ mass, and the two cancel exactly. **The cohort's body mass therefore does
   NOT need to be recorded for Test A.**
2. **ΔMAP and the ratio ΔMAP/ΔV_ecf both scale as 1/mass.** ΔMAP is 6.4359 / 5.0569 /
   4.1646 mmHg at 55 / 70 / 85 kg and the ratio is 14.363 / 11.285 / 9.294 mmHg/L.
   **Cohort mass IS required for Test B** and a study that does not report it cannot
   supply Test B.
3. **The prediction is sex-dependent by 6.9%**: 0.4393 L male against 0.4110 L female at
   `G_pn` = 20, because `dMAP/dV_ecf` scales as `TPR0·BV0` and that product is larger in
   women. Use the male figure unless the cohort is majority female; record the split.

---

## 1. THE TWO TESTS, AND WHY THERE ARE TWO

### Test A — the magnitude. What ADR 0013 asked for.

Take the sourced ΔV_ecf per 100 mmol/day, invert it through the constant above, and see
where the implied `G_pn` lands.

### Test B — the ratio. Stronger, and available only from studies reporting both.

    ΔMAP / ΔV_ecf  =  11.285 × (70 / m_cohort)  mmHg/L      male, model

**This does not involve `G_pn` at all.** `G_pn` sets ΔMAP; the cardiovascular chain
(`G_vr`, `f_pv`, `f_c`, `TPR0`) sets how much volume is needed to produce it. Their ratio
is a property of the circulation alone. **Test B therefore isolates precisely the place
ADR 0013 fears the error would move to** — it says in terms that if the volume is wrong,
the error has relocated into `G_vr`, `f_pv` or the reabsorption term rather than been
fixed.

**Where both are available, Test B takes precedence.** A study supplying only volume gives
Test A; a study supplying volume, pressure and cohort mass gives both.

---

## 2. WHAT IS BEING EXTRACTED

**Primary:** change in extracellular fluid volume, in litres, per 100 mmol/day change in
chronic dietary sodium intake, in normotensive adults.

**Secondary, for Test B:** the change in mean arterial pressure over the same step, in the
same subjects, with cohort body mass.

**Recorded for every study regardless:** n, sex composition, age, cohort body mass, the
two or more sodium levels and how intake was verified, duration per level, and the
measurement method.

---

## 3. METHOD SEPARATION, FIXED BEFORE EXTRACTION

`pooling.md` prohibits pooling across incompatible measurement methods. These are **four
different measurements** and are pooled separately, never across:

1. **Tracer dilution ECF** — bromide, sulphate, thiosulphate, inulin. The target
   quantity. Preferred.
2. **Bioimpedance ECF.** A different instrument with its own calibration; recorded
   separately even though it claims the same quantity.
3. **Body weight.** A *proxy*, not a measurement of ECF. Converted at **1 kg = 1 L**,
   declared here, and carrying the stated assumption that the weight change over the
   protocol is fluid. That assumption weakens as duration grows, so **for weight-derived
   values the protocol duration is recorded and any study long enough for body
   composition to drift is flagged.**
4. **Plasma volume or total body water.** **NOT interchangeable with ECF and NOT
   converted.** Recorded and set aside. The model has a plasma compartment derived from
   ECF, so a plasma-volume datum would test `f_pv`, which is a different question.

---

## 4. INCLUSION AND EXCLUSION — REUSED VERBATIM FROM `salt_sensitivity_prereg.md` §4

**Include** if all of:

1. **Normotensive** adults, defined by the source, and the definition recorded.
2. **At least two sodium intake levels**, quantified, with intake **measured or
   controlled** — 24 h urinary sodium preferred over dietary recall.
3. The volume variable measured at each level.
4. **Duration per level long enough to approach steady state.** The model runs 30 days per
   level. Minimum **5 days**; record the actual duration; anything shorter is
   **short-protocol** and pooled separately, because a protocol that has not equilibrated
   measures a transient and the model's number is a steady state.

**Exclude:** hypertensive cohorts (recorded separately as comparators, as ADR 0013 does
for pressure), heart failure, renal disease, cirrhosis, pregnancy, diuretic or
antihypertensive therapy, and acute load-then-deplete protocols.

---

## 5. SEARCH STRATEGY

Two sweeps minimum, per directive 1.8. Relationship-shaped, not variable-shaped
(directive 1.7): the question is *how extracellular volume responds to chronic salt*, not
*what is normal ECF*.

**Sweep 1** — sodium loading and extracellular volume: controlled-feeding and metabolic
ward studies, tracer-dilution ECF, sodium balance.
**Sweep 2** — the weight limb and the long-duration balance literature, which sweep 1 will
under-return because it does not use the words "extracellular volume".

**One candidate is named in advance, and it is one this repo has already set aside.**
HANDOVER §6 records that **Mars500 is not the primary validation target because its
comparisons carry no blood pressure.** Test A does not need blood pressure. The
ultra-long-duration sodium balance studies in that family (Titze and Rakova, 105 and 205
day controlled sodium intake in men, with body weight and complete sodium balance) are
therefore **squarely in scope here even though they were correctly out of scope there**,
and must be screened rather than skipped on the strength of that earlier decision. They
would supply Test A but not Test B.

---

## 6. POOLING

`pooling.md` order applies unchanged: `meta-analysis` if one exists, then
`pooled-inverse-variance`, `pooled-n-weighted`, `pooled-unweighted`, `single-source`.
**`range-midpoint` is prohibited.** Pool within a measurement method only (§3).

---

## 7. THE DECISION RULE, FIXED IN ADVANCE

Let `G_vol` be the `G_pn` implied by the sourced volume response through §0's inversion.
The concordant pressure bracket from ADR 0013 is **43.5–58.8**.

- **A1 — `43.5 ≤ G_vol ≤ 58.8`.** Volume and pressure agree. **ADR 0013 → Accepted;
  `RN.PRESSURE_NATRIURESIS.SLOPE` 20.0 → 51.0**, `extraction_method` → `reported`,
  uncertainty spanning the full human range 44–393.
- **A2 — `G_vol < 43.5`**, i.e. the human volume response is LARGER than 0.202 L/100 mmol.
  The kidney would look less salt-sensitive on volume than on pressure. If `G_vol` lands
  near 20, the incumbent value is right on volume while wrong on pressure — an internal
  contradiction meaning **`dMAP/dV_ecf` is wrong**. **Do NOT accept 51.** Open a record on
  the cardiovascular gain; `G_vr` is `calibrated` and is already §4 item 1.
- **A3 — `G_vol > 58.8`.** Volume favours a stiffer kidney than the concordant pressure
  cluster, and toward Graudal. **Do NOT accept 51.** Record that the two independent lines
  disagree and that the pressure controversy is now a volume controversy too.
- **A4 — no usable data, or a pooled estimate whose spread crosses a branch boundary.**
  **ADR 0013 stays Proposed and `G_pn` stays at 20.0.** Record exhaustively what was tried
  so the next attempt does not repeat it. **This is the branch that must not be avoided by
  reaching for a weaker test**, and specifically not by accepting on the pressure evidence
  alone — that is the exact move ADR 0013 forbids.

**Test B overrides.** If Test B is available and the human ratio differs from the model's
`11.285 × (70/m_cohort)` mmHg/L **by more than a factor of 2**, then no value of `G_pn`
reconciles pressure and volume, **A1 is unavailable regardless of Test A**, and the
finding is about the circulation rather than the kidney.

**Why a factor of 2.** It is tighter than the human pressure controversy, which spans a
factor of 9 (44–393), and looser than the separation between the incumbent and the
proposal, which is 2.55×. Chosen before any ratio was seen, and chosen so the test can
actually fail.

---

## 8. WHAT WOULD FALSIFY THE APPROACH RATHER THAN THE VALUE

- **If the sourced volume response is not linear in sodium intake** over the 103–205
  mEq/day range, the inversion in §0 is invalid, because the model's ΔV_ecf is linear by
  construction. Record the curvature; do not force a slope through it.
- **If ECF and body-weight studies disagree beyond their stated dispersions**, the 1 kg =
  1 L conversion in §3 is wrong and the weight limb comes out of the analysis, not into
  it under a correction chosen afterwards.
- **If the response depends strongly on the direction of the step** — loading versus
  restriction — the model has no such asymmetry and the mismatch is structural, not
  parametric.

---

## 9. OUT OF SCOPE

- **Choosing between 51 and a Graudal-camp value on the pressure evidence.** ADR 0013
  argued that and states plainly it has not refuted the alternative. This document tests;
  it does not re-argue.
- **Making `G_pn` a distribution rather than a point value.** ADR 0013 calls this the
  strongest case in the repo for a posterior. It is the owner's decision and is not taken
  here.
- **Salt sensitivity as a population covariate.**
- **`G_vr` and venous compliance**, except that branch A2 and a failed Test B would open
  that record.
- **Sourcing plasma volume as a fraction of ECF**, which would make haematocrit
  identifiable (HANDOVER §3.5) and is a different question reached through §3 item 4.
