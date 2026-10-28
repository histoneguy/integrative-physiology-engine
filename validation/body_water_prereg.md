# Pre-registration — re-sourcing total body water

**Written 2026-10-27.** `OPEN-QUESTIONS` **B37**. Eighth pass under directive 1.16.

    git log --diff-filter=A -- validation/body_water_prereg.md

---

## 0. HONESTY ABOUT WHEN THIS WAS WRITTEN — READ THIS FIRST

**The owner supplied Chumlea 1999 and it has been read in full before this file was written.**
A pre-registration written after the numbers are known is weaker than one written before, and
pretending otherwise is worse than the weakness. **What is already known:**

- **Chumlea WC, Guo SS, Zeller CM, Reo NV, Siervogel RM.** *Total body water data for white
  adults 18 to 64 years of age: The Fels Longitudinal Study.* **Kidney Int 1999;56:244–252.**
  274 men, 292 women, **deuterium NMR**, DXA alongside, mixed longitudinal over eight years.
- **It reports its own hydration ratio three inconsistent ways** — §3.2.
- Hydration is **slightly higher in women** in both tables.

**THIS IS NOT THE PAPER THE CATALOGUE ASKED FOR.** `CITES-NEEDED.md` named Chumlea **2001**,
*Total body water reference values and prediction equations for adults* (PMID 11380828). This
is the **1999 Fels** paper. **It is better for this purpose** — §3.1 — and the catalogue is
corrected rather than the substitution passed over in silence.

**WHAT IS THEREFORE STILL GENUINELY PRE-REGISTERED:** the selection rule among the paper's
three disagreeing figures (§3.2), what may not move (§5), the falsifiable tests (§6), and the
decision rule (§7) — **all fixed before any row is edited and before the model is run.**

---

## 1. THE DEFECT

`BF.TBW/ICF/ECF.MASS_FRACTION` are **0.552 / 0.344 / 0.208**, all `sex = both`, all fractions
of **body** mass, from **Zhang N et al.** — 160 Chinese college students, **bioelectrical
impedance**, in a study about **water intake**.

**ADR 0037 showed what that costs.** Divide by the measured fat-free fraction and the implied
hydration of fat-free mass is **0.758 in men and 0.900 in women.** Fat-free mass cannot be 90%
water. The model carries roughly **8 L** of water in women that has nowhere to be.

**FOUR INDEPENDENT GROUNDS FOR REPLACEMENT, AND GEOGRAPHY IS THE WEAKEST OF THEM.** Directive
1.7 (body water is the instrument there, not the subject), method (BIA against dilution),
cohort (lean young students against a 90.3 kg reference at 27% fat), and sex-pooling (the paper
reports a sex difference and the pooled value was taken). Directive 1.17's Rule A is satisfied
too, and **§8 requires the record to say which rule did the work.**

---

## 2. WHAT THIS PASS WILL AND WILL NOT FIX — DIRECTIVE 1.16

**WILL:** total body water, **sexed**, from **deuterium dilution** — the reference method — in
a US cohort, expressed on **fat-free mass**, so the sex difference in water per kg body mass
**emerges from the sourced fat fractions** instead of being imposed.

**WILL NOT: the ECF/ICF split.** Chumlea measures TBW, not ECW and ICW. Its introduction gives
65%/35% for *"the proverbial 70 kg person"* — **a convention, and directive 1.12 forbids taking
it.** So the split keeps Zhang's ratio, and **that is the weakest thing in the fluid model
after this pass and must say so on the row.** Sourcing it needs **bromide dilution**, which is
a separate pass and a separate cite.

**SO THIS PASS MAKES THE TOTAL RIGHT AND LEAVES THE PARTITION WRONG.** That is an improvement
and not a fix, and reporting it as a fix would be the dishonest reading.

---

## 3. ADMISSIBILITY, AND THE SELECTION RULE FIXED BEFORE ANY ROW IS EDITED

### 3.1 Why the 1999 Fels paper rather than the 2001 one that was asked for

**The compartment definitions match exactly, and that is the deciding reason.** Chumlea
computes FFM as *"the sum of whole body lean tissue and whole body bone mineral mass"* from
DXA. `BF.FAT.MASS_FRACTION` was extracted from NHANES DXA as `DXDTOFAT / (DXDTOFAT + DXDTOLE +
DXDTOBMC)`, so this model's `mass_ffm` **is** lean + bone mineral. **Same compartment, same
instrument class.**

**THAT MATTERS MORE THAN IT SOUNDS.** The canonical hydration constant of **0.73** refers to
fat-free *body* mass. A DXA-defined FFM includes bone mineral, which carries almost no water,
so **TBW/FFM(DXA) is necessarily lower than the canonical constant** — and pairing the
canonical 0.73 with a DXA-derived fat fraction would be a **level and method mismatch**, the
error the five-level model exists to prevent. Chumlea's ratio is the one that composes.

### 3.2 THE PAPER DISAGREES WITH ITSELF, AND THE RULE IS FIXED NOW

| within the paper | men | women |
|---|---|---|
| running text | *"approximately 0.68"* (both sexes) | 0.68 |
| **Table 3**, random-effects fit, **no age effect** | **0.700** | **0.720** |
| Table 1, ratio of group means (DXA-n weighted) | 0.716 | 0.733 |

**THE RULE, DECLARED BEFORE CHOOSING: take Table 3.** It is the paper's **own fitted estimate
of this quantity**, by sex, from the model the paper was built around, and the absence of an
age term means the intercept **is** the value across the age range. The running text's 0.68
carries **no n and no dispersion** and is inconsistent with both tables. Table 1's ratios are
**ratios of group means from different subsamples** — TBW on N, FFM on N\* — which is not the
mean of individual ratios and is a known bias.

**ALL THREE ARE RECORDED ON THE ROW.** A source that reports one quantity three ways is a fact
about the evidence, and burying two of them would be the failure
`source both sides of a discrepancy` names.

**NO DISPERSION IS AVAILABLE FOR THE RATIO.** Table 3 gives intercepts without standard errors.
`uncertainty_type = none`, and **the spread is not invented** — the same treatment Finke's
autoregulatory limit and Janssen's muscle fraction already get.

### 3.3 Cohort

**White US adults, 18–64 y**, Dayton Ohio. **Single-ancestry**, which is a real limit and is
recorded: this model's reference individual is a US adult from NHANES, which is multi-ancestry.
**Directive 1.17's Rule B is satisfied on country and only partly on composition.**

---

## 4. THE FORM, AND THE ARITHMETIC IS DONE BEFORE THIS SECTION IS ADOPTED

    TBW_fraction_of_body_mass  =  h_sex * (1 - f_fat_sex)

| | `f_fat` | `1 − f_fat` | `h` | **TBW/body mass** | now |
|---|---|---|---|---|---|
| male | 0.272 | 0.728 | 0.700 | **0.510** | 0.552 |
| female | 0.387 | 0.613 | 0.720 | **0.441** | 0.552 |

**Male falls 7.6%, female falls 20%.** The ECF and ICF fractions keep Zhang's ratio
(0.208 : 0.344, i.e. 37.7% : 62.3% of TBW) applied to the new totals.

**THE OPERATING POINT WILL MOVE AND THAT IS THE POINT.** `V_ecf` feeds plasma volume, blood
volume, cardiac output and arterial pressure. **A pass that left the operating point untouched
would mean the change had not reached the loop.** §6 test 1 reports the move rather than
asserting it away.

---

## 5. WHAT MAY NOT MOVE

- **`BF.FAT.MASS_FRACTION`, `BF.MUSCLE.MASS_FRACTION`** — sourced last week, untouched.
- **`CV.BLOOD_VOLUME.NOMINAL`, `CV.HEMATOCRIT.NOMINAL`, `CV.MAP.SETPOINT`** and every
  cardiovascular row. **THIS IS THE TRAP.** `CV.PLASMA.ECF_FRACTION` is **derived** as
  `BV0·(1−Hct)/V_ecf` and `check_closure.py` enforces it per sex, so **it must be re-derived**
  — that is bookkeeping the gate demands, not a free parameter. **Re-deriving `f_pv` is
  permitted; re-tuning `CV.MAP.SETPOINT` or the venous return gain to put MAP back is not.**
- **`RN.PRESSURE_NATRIURESIS.SLOPE`, `RN.MD.RENIN_GAIN`** — the two `calibrated` rows.
  **If salt sensitivity leaves its band, that is the result** (failure mode 22).
- **No band, pin or tolerance widened.**

---

## 6. THE FALSIFIABLE TESTS

1. **The operating point is REPORTED, at a tenth of a mmHg** — MAP, `V_ecf`, plasma sodium,
   urine, `Na_excr` — before and after, per sex. **It is expected to move.** Directive 1.9:
   pressures to 0.1 mmHg in prose, whatever the suite pins.
2. **THE CHECK THIS PASS EXISTS FOR: implied hydration of fat-free mass is 0.700 / 0.720**, by
   construction, against the 0.758 / **0.900** ADR 0037 measured. **If it is not, the wiring is
   wrong.**
3. **Chumlea's own absolute volumes are reproduced** at his cohort's body mass, not merely his
   ratio — the B36 cohort check applied to this row. **A ratio that does not reproduce the
   litres means the cohorts disagree**, and that is a finding.
4. **Salt sensitivity and `dMAP/dV_ecf`**, reported per sex against 1.70–2.30 and 2.97–4.16.
   It was **1.7** — on the lower band edge (**B35**) — so a further fall leaves the band.
   **Reported, not corrected.**
5. **The sexed ECF excursion ratio**, which HANDOVER §2 reports as a prediction. It depends on
   `f_pv` and therefore on this change.
6. **Full suite and all six gates**, and **`check_closure.py` per sex is the one that matters**
   — it enforces the `f_pv` identity this change breaks until it is re-derived.

---

## 7. THE DECISION RULE

- **W1 — the arithmetic lands and the loop still closes.** Enter, re-derive `f_pv`, ADR.
- **W2 — a challenge or a band fails.** **Report it and enter anyway if the provenance is
  better**, because a worse-sourced number that happens to sit in a band is not preferable to
  a better-sourced one that does not. Open it as a question.
- **W3 — the loop will not close**, e.g. `V_ecf` falls so far that blood volume cannot reach
  nominal. **Then the conflict is between this row and `CV.BLOOD_VOLUME.NOMINAL`, and it is
  reported as such rather than split between them.**
- **W4 — the implied hydration does not come out at 0.700/0.720.** Wiring error; fix before
  anything else is judged.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Re-tuning `CV.MAP.SETPOINT`, the venous return gain or either `calibrated` row to put the
operating point back.** §5. Re-deriving `f_pv` is required; everything else is forbidden.

**Taking 0.73 from the hydration literature instead of Chumlea's ratio.** §3.1 — it is a
different compartment definition and would not compose with a DXA fat fraction.

**Taking the 65/35 ECF:ICF split from Chumlea's introduction.** §2. It is described there as
the proverbial 70 kg person; directive 1.12.

**Reporting the three disagreeing figures as one.** §3.2.

**Claiming the fluid model is now sourced.** §2 — the total is; the partition is still Zhang's.

**Recording geography as the reason Zhang was replaced.** §1 — four stronger grounds exist and
directive 1.17 requires naming the one that did the work.
