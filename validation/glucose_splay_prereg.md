# Pre-registration — glucose splay

**Written 2026-09-24, after two abstracts and BEFORE either full text is read for numbers.**

    git log --diff-filter=A -- validation/glucose_splay_prereg.md

`OPEN-QUESTIONS` **B20**. Fifth pass under directive 1.16.

---

## 0. HONESTY ABOUT WHEN THIS WAS WRITTEN

**Two abstracts had been read**: DeFronzo 2014 (PMID 23735727) and McPhaul & Simonaitis 1968
(PMID 5641612). Both state *qualitatively* that splay exists and was quantified; **neither
abstract contains a splay number.** McPhaul's PDF has been downloaded and **not yet read**.

**What is genuinely pre-registered:** the form, the admissibility rule, what may not move, the
tests, and the decision rule — all below, before any figure is extracted.

---

## 1. THE DEFECT

    glu_excr ~ max(0.0, GFR * C_glu - TmG)

**A HARD THRESHOLD AT `TmG/GFR`**, which in this model is about **18 mmol/L**. People begin
spilling nearer **10–11**. The gap is **splay**: nephrons are heterogeneous, so some reach
their own transport maximum well before the whole-kidney average does, and glucose appears in
urine before `TmG` is reached anywhere near uniformly.

**IT MATTERS MORE SINCE ADR 0033 AND 0034 THAN IT DID WHEN B20 WAS FILED.** Glycosuria used
to be unreachable — the ceiling sat below the threshold — so the threshold's position was
untestable. **It is now the thing that sets when urine starts to move**, and type 1 runs well
past it.

**THE TEACHING NUMBER WAS REFUSED ONCE ALREADY.** `glucose_insulin_prereg.md` flagged
"180 mg/dL" in advance as the most suspect figure in the subsystem, and B20 records that
entering it *"would have been fitting a population observation in place of a mechanism"*.
**That refusal stands; this pass looks for the mechanism's shape, not the population number.**

---

## 2. DIRECTIVE 1.12 — ROUND NUMBERS LISTED BEFORE EXTRACTION

- **"The renal threshold for glucose is 180 mg/dL."** Already refused once.
- **"TmG is 375 mg/min."** The classic textbook figure.
- **"10 mmol/L"** as the threshold, which is the same teaching claim in SI dress.

---

## 3. ADMISSIBILITY

**Include:** glucose titration in **healthy adults**, excretion measured against plasma
concentration across the spill region, with **GFR measured concurrently** so excretion can be
put on a filtered-load axis rather than a concentration axis.

**Exclude:** diabetic cohorts as the source of the **normal** curve — DeFronzo reports type 2
has *elevated* TmG, splay and threshold, so mixing them would bias every parameter; renal
glycosuria and nephrotic cohorts, which are the pathology of this exact mechanism; and
**SGLT2-inhibitor arms**, which are the intervention.

**GROUP INDEPENDENCE.** McPhaul & Simonaitis (1968, JCI) and DeFronzo et al. (2014, Diabetes
Care) are **independent** — different groups, eras, and methods (classical titration versus
pancreatic/stepped hyperglycaemic clamp with a pharmacodynamic model). **If both yield a
usable splay parameter this is the second equation in the model with two independent
primaries behind its form.**

---

## 4. THE FORM, FIXED BEFORE THE NUMBERS

**Replace the hard `max` with a smooth saturating approach to `TmG`:**

    reabs    ~ TmG * (load / (load + K_splay))          # load = GFR * C_glu
    glu_excr ~ max(0.0, load - reabs)

**ONE NEW PARAMETER**, and `K_splay → 0` returns the current hard-threshold behaviour, so the
change is testable against its own null.

**WHY A SATURATING REABSORPTION AND NOT A SMOOTHED THRESHOLD.** Splay is **not** rounding
applied to a corner — it is the aggregate of heterogeneous nephrons each with its own
maximum. A saturating whole-kidney reabsorption is the standard summary of that aggregate and
has the right limits: proportional at low load, asymptotic to `TmG` at high load.
**A smoothed `max` would reproduce the curve and mean nothing.**

**`TmG` KEEPS ITS SOURCED VALUE.** Mogensen's `RN.GLU.TM` is unchanged; splay is added
**around** it, not by moving it. **If matching a threshold requires moving `TmG`, that is a
failure** — §8.

---

## 5. WHAT MAY NOT MOVE

- **`RN.GLU.TM`** (Mogensen), **`RN.GFR.NOMINAL`**, every glucose and insulin row.
- **The healthy operating point.** At 5.44 mmol/L the model spills **zero**, and it must
  continue to — a saturating reabsorption leaks a little at every load, so **§6 test 2 checks
  the leak is below what the ledger's precision can represent** rather than assuming it.
- **Nothing hepatic.** ADRs 0034/0035 are untouched.

---

## 6. THE FALSIFIABLE TESTS

1. **`K_splay` = 0 reproduces the current model bit-identically.**
2. **Health still spills nothing measurable** — and the residual leak at 5.44 mmol/L is
   **reported as a number**, not asserted to be zero.
3. **THE PREDICTION: the spill threshold falls from ~18 toward 10–11 mmol/L**, reported as
   the concentration at which excretion first exceeds 1 mmol/day. **This is what B20 exists
   for.**
4. **Type 1 glycosuria and urine volume are reported before and after.** They should rise,
   because spill starts earlier — **but ADR 0034's type 1 already runs at 27.9 mmol/L, far
   above either threshold, so the effect there should be SMALL.** A large change would mean
   the parameter is doing something other than splay.
5. **The whole suite and all challenges.**
6. **`K_splay` across its own uncertainty**, with test 3 recomputed at each end.

---

## 7. THE DECISION RULE

- **S1 — both sources give a usable splay parameter.** Pool per `pooling.md`; build.
- **S2 — only one does.** Build, declare `single-source`, record the other as corroboration.
- **S3 — the splay data are only in figures.** **Stop at INDETERMINATE and do not digitise a
  figure**, which is the rule `nimgu_form_prereg.md` branch N3 already set and honoured.
- **S4 — the sources show the threshold is at `TmG/GFR` after all.** Then B20's premise is
  wrong and the model is right; close it with a citation.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Moving `TmG` to land the threshold at 10–11.** §4. That is fitting the population
observation B20 explicitly refused.

**Adopting 180 mg/dL as the threshold.** §2, and it was refused in advance once already.

**Tuning `K_splay` until the threshold hits 10–11.** Test 3 is a *prediction*. The parameter
comes from the sources' titration curves, and if it lands at 13 or 8 **that is the result.**

**Reporting a lower threshold without test 4.** If type 1 moves a lot, splay is not what was
added.
