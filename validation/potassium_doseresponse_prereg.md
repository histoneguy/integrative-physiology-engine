# Pre-registration — the potassium intake–plasma relation, and the renal fraction

**Written 2026-09-06, before any source is opened for these values, and before any search
has been run for them.** Verify the ordering with

    git log --diff-filter=A -- validation/potassium_doseresponse_prereg.md
    git log --diff-filter=A -- validation/potassium_doseresponse_extract.py

This exists because `HANDOVER.md` §3.33 retracted a false claim that this literature could
not be sourced, and the owner's instruction was to stop recording the gap and close it.
Structure is already decided in **ADR 0021**; this pre-registration fixes only how its two
weakest numbers are replaced.

---

## 1. THE TWO QUANTITIES, AND WHY THEY ARE ONE PASS

At steady state the model reduces to a single relation:

    K_p / K_p_ref = [ f_renal * K_intake / (FE_K * GFR * K_p_ref) ] ^ (1 / n_K)

so that

    d ln(plasma potassium) / d ln(potassium intake)  =  1 / n_K        (with f_renal fixed)

| id | what | current | how it got there |
|---|---|---|---|
| `K.EXCRETION_EXPONENT` | `n_K` | 17.71 | median of **six** studies in Brunner 1970, spread 3.45–41.68 |
| `K.RENAL_FRACTION` | `f_renal` | 0.884 | mean of the same six |

**They are one pass because they are not separable.** `f_renal` sets how much potassium
reaches the kidney and `n_K` sets how hard the kidney works per unit plasma concentration;
a change in either moves the same steady state. Sourcing one and not the other would leave
the composite carrying the error, which is §3.26's mistake and §3.29's.

**`K.FRACTIONAL_EXCRETION` is NOT in this pass.** It is derived to close the balance and,
measured, it barely matters — sweeping it 0.04–0.16 moves plasma potassium 4.18 → 3.87
mmol/L. Re-deriving it is arithmetic that follows whatever this pass concludes.

---

## 2. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults; potassium intake either controlled by feeding or measured by
**24-hour urinary excretion** (not dietary recall); steady state, meaning the intake held
at least **five days** before the measurement; serum or plasma potassium measured in the
same subjects at the same intake; sea level; no diuretics, no potassium-sparing agents, no
ACE inhibitors or angiotensin receptor blockers, no NSAIDs, no mineralocorticoid or
glucocorticoid manipulation, no renal or adrenal disease, not pregnant.

**Explicitly admissible, and this is the correction §3.33 exists to make:** the search
terms are **potassium balance**, **potassium loading**, **potassium supplementation**,
**adaptation in normal man**, and **dose–response**. *Fractional excretion of potassium* is
a bedside diagnostic phrase and returns disease by construction; it is not the physiology
and it is not to be used as the primary term again.

**Exclude:** spot-urine estimates of anything; single-meal or single-day loads, which
measure distribution rather than balance; hypertensive or CKD cohorts unless a healthy arm
is reported separately; and any study whose potassium intake is not stated.

**Trials of potassium supplementation in healthy or mixed adults ARE admissible** where
serum potassium and achieved intake are both reported, including as a pooled estimate.
That is the same class of evidence as any other meta-analysis this ledger uses.

**AND OTHER WHOLE-BODY MODELS ARE NOT SOURCES.**

---

## 3. WHAT IS ALREADY KNOWN, DECLARED SO THE FREEDOM IS AUDITABLE

**Three Utrecht abstracts were read on 2026-09-05, before this file existed**, and are
recorded in `HANDOVER.md` §3.33:

- **Hené 1986** (PMID 3523191): 6 healthy males, 18 days, 80 → 300 mEq/day; urinary
  potassium 50 ± 12 → 233 ± 45 mEq/day; serum potassium "somewhat increased" — **no number
  for serum potassium, which is the number this pass needs.**
- **Hené 1988** (PMID 3199680): "a steep positive relation between plasma K and urine K."
  Direction only.
- **Rabelink 1990** (PMID 2266680): 6 healthy humans, 400 mmol/day, 20 days; urinary
  potassium ≈ 80% of intake; plasma potassium "elevated" — again no number.

**So the ratios 50/80 = 0.63 and 233/300 = 0.78 are already known and so is Rabelink's
0.80.** They are declared here because a value seen in advance is a value that can be
landed on without noticing. **None of the three gives a serum potassium**, which is why
this pass is not simply an average of what is already in hand.

Brunner 1970's six per-study exponents are also already known: 16.31, 19.11, 23.45, 3.45,
13.26, 41.68.

---

## 4. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED IN ADVANCE

Urinary potassium as 90% of intake, stool as 10%, dietary potassium 100 mmol/day, and
"serum potassium changes little with intake". **All four are teaching numbers.** None is
enterable without a source, and where the measured value turns out to be the round one the
source is what makes it enterable.

---

## 5. THE FORM

**`n_K` will be taken as the reciprocal of a measured elasticity**, because that is what
the model's steady state makes it, and an elasticity is dimensionless and transferable
across cohorts and assays — the property §3.26 established the hard way.

**`f_renal` MAY BECOME A FUNCTION OF INTAKE.** ADR 0021 made it a constant and two Utrecht
studies say it is not one. If the extraction supports a monotone rise, the form is fixed
here in advance as the simplest one that cannot leave [0, 1]:

    f_renal(K_intake) = f_max - (f_max - f_0) * (K_intake_ref / K_intake) ^ p     (p > 0)

and **if the extraction does not support it, `f_renal` stays a constant and this branch is
not taken.** Choosing the shape after seeing the data is the error ADR 0017's amendment
records.

---

## 6. THE DECISION RULE

- **D1 — a pooled dose–response estimate of plasma potassium against potassium intake
  exists in admissible subjects.** It sets `n_K`. **Brunner is demoted to a comparison**
  and its twelvefold spread is reported as the reason it could not carry the row.
- **D2 — no pooled estimate, but two or more independent admissible studies each give an
  intake and a plasma potassium.** Pool them by the rule in `validation/pooling.md`, report
  the spread as the uncertainty, and **do not** pick the one that flatters the model.
- **D3 — only Brunner survives admissibility.** The row keeps 17.71, the search is recorded
  with the exact terms used, and **the note says which terms were tried** so the next
  reader can tell a failed search from a settled one. §3.33 is what happens otherwise.
- **D4 — the sources disagree beyond their stated dispersion.** Report the disagreement,
  enter the pooled value, and widen the uncertainty to span both. **Do not split the
  difference silently**, which is what `OPEN-QUESTIONS.md` B10 currently records not doing.
- **D5 — the renal fraction is measured to rise with intake in two or more admissible
  studies.** Take the §5 form, fit `p` and `f_max`, and **`K.RENAL_FRACTION` becomes
  derived from them rather than a mean.** Otherwise it stays constant.

---

## 7. WHAT THE ANSWER MAY NOT DO

- It may not use `K.PLASMA.REFERENCE` to set `n_K` or `f_renal`. That row is NHANES and it
  is the operating point, not the slope.
- It may not re-estimate `RN.MD.RENIN_GAIN`, `CV.ANP.NATRIURETIC_GAIN` or
  `RN.PRESSURE_NATRIURESIS.SLOPE` — §3.32's lesson, one change at a time.
- It may not add a second state, and it may not add potassium adaptation. **The absence of
  adaptation (`OPEN-QUESTIONS.md` B11) is NOT closed by this pass** and must still be said.
- It may not report the resulting plasma potassium as a validation. `FE_K` is still derived
  from it, so the operating point remains a restatement; **what this pass can improve is
  the RESPONSE, and only the response.**
- It may not enter a value from an abstract when the full text is obtainable, and must
  label the reading level of every source it does enter.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**If `n_K` lands inside Brunner's 3.45–41.68 and nothing else changes, this pass has bought
precision and no information.** The test that it was worth running is that the new value
comes with a dispersion narrow enough to *exclude* part of that range — or that `f_renal`
stops being a constant. One of those two, or the pass is recorded as having found nothing.
