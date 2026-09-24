# Pre-registration — the FORM of non-insulin-mediated glucose uptake

**Written 2026-09-23.** Verify the ordering with

    git log --diff-filter=A -- validation/nimgu_form_prereg.md

`OPEN-QUESTIONS` **B22**. Second pass run under directive 1.16, and the first in this
repository to reach **two independent laboratories** for a functional form.

---

## 0. HONESTY ABOUT WHEN THIS WAS WRITTEN — READ THIS FIRST

**THREE ABSTRACTS HAD ALREADY BEEN READ WHEN THIS FILE WAS WRITTEN**, because directive
1.16's first half worked exactly as intended and the review handed over its reference list.
**A pre-registration written after seeing numbers is weaker than one written before, and
pretending otherwise would be worse than the weakness.** What was already known:

- Edelman 1990: NIMGU measured at **four** glucose levels; leg extraction saturates,
  **EG50 5.3 ± 0.4 mM**.
- Best 1981: metabolic clearance rate falls **38 / 16 / 11%** at low / medium / high insulin.
- Ahrén & Pacini 2021: `S_G` *"is independent from glucose levels"* **in mice**.

**WHAT IS THEREFORE STILL GENUINELY PRE-REGISTERED, AND IT IS THE PART THAT MATTERS:** the
**form**, the **decision rule**, **what may not move**, the **falsifiable tests**, and the
**pooling rule** — all fixed below **before either paper's full text or tables are read**,
and before any number is extracted into the ledger. **No full text has been opened.**

**WHAT IS NOT CLAIMED:** that this pass met the pre-registration standard of
`autoreg_form_prereg.md`, which was written before any source was opened. It did not.

---

## 1. THE REVIEWS READ, AND WHAT THEY ESTABLISHED — DIRECTIVE 1.16

**Ahrén B, Pacini G. Glucose effectiveness: lessons from studies on insulin-independent
glucose clearance in mice. J Diabetes Investig 2021;12(5):675–685. PMID 33098240, PMC8088998.
Open access, FULL TEXT read 2026-09-23.**

1. **THE QUANTITY THIS MODEL CALLS NIMGU HAS A NAME AND A LITERATURE — `S_G`, glucose
   effectiveness** — and it *"accounts for ≈70% of glucose disposal"*, which independently
   brackets Baron 1985's 75 ± 5% that ADR 0031 already uses.
2. **`S_G` AND NIMGU ARE NOT THE SAME QUANTITY, AND THIS IS THE STRUCTURAL POINT.** `S_G` is
   a **minimal-model** parameter estimated from an intravenous glucose tolerance test; it
   lumps **suppression of endogenous glucose production**, and the review states it also
   includes **renal glucose excretion**. Baron's and Edelman's NIMGU is **uptake measured
   directly** under somatostatin. **This model has EGP and renal excretion as SEPARATE
   terms**, so it must take the **uptake** quantity and **must not** adopt an `S_G` value —
   that would double-count two terms the model already has.
3. **THE APPARENT CONTRADICTION IS A METHOD ARTEFACT AND MUST BE REPORTED AS ONE.** The
   review says `S_G` is *"independent from glucose levels"*; Best and Edelman say disposal is
   **not** proportional to glucose. **Both can be true**: `S_G` is a fitted coefficient of a
   model that *assumes* proportionality, so finding it independent of the glucose level
   reached is a statement about estimator stability, **not** evidence that uptake is linear.
   The mouse result is also **mouse**, and §4 forbids cross-species pooling.
4. **A REVIEW'S REFERENCE LIST IS THE ROUTE TO THE PRIMARIES**, which is 1.16's stated
   purpose. Best 1981 was found this way and **uses the term "NIMGU" nowhere** — no search
   on that term would have returned it.

**AND THE REVIEW'S OWN CITATION OF IT WAS WRONG.** It prints *"Diabetes 1981; 34: 847–850"*;
volume 34 is 1985. The record is **Diabetes 1981;30(10):847–850, PMID 6115785**, confirmed
against the indexed record. **Directive 1.5 is why this was checked rather than copied**, and
it is the second time in one evening that a number taken from a review would have been wrong.

---

## 2. THE DEFECT, AS ADR 0031 LEFT IT

    appear ~ k_ni*C_glu + S_I*I_glu*C_glu*glu_disposal + glu_excr

`k_ni*C_glu` is **strictly linear**, so with both disease knobs at zero the insulin-
independent term alone clears the whole appearance at **15.6 mmol/L** — below the renal
threshold, so **glycosuria is zero at every setting and urine never moves.** ADR 0031 named
this, named Baron 1988 as the contradiction, and **deliberately deferred it** rather than
stacking a second structural change.

---

## 3. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED BEFORE EXTRACTION

- **"70%"** and **"75%"** for the non-insulin-mediated share. Already in the model from
  Baron 1985; the review's ≈70% is a *review* number and §4 forbids taking it.
- **"The brain uses 120 g of glucose a day"** — the classic fixed-uptake figure, and this
  pass will be tempted to reach for it the moment Best's constant term appears.
- **A Michaelis–Menten `Km` of "5 mM"**, which is close enough to Edelman's EG50 of 5.3 to be
  mistaken for confirmation by a number that was a convention.

---

## 4. ADMISSIBILITY AND POOLING, FIXED BEFORE EXTRACTION

**Include:** human studies measuring glucose uptake at **two or more** glucose
concentrations with insulin **held fixed** (somatostatin, clamp, or both), reporting uptake
in absolute units.

**Exclude:** minimal-model `S_G` estimates as a source for the **form** — `pooling.md`
forbids mixing extraction methods, ADR 0031 already excluded García-Estévez on exactly this
ground, and §1.2 gives the physiological reason. **Exclude non-human data for the value**
(directive 1.6 does not apply: the human experiment is performable and has been performed).

**POOLING RULE:** `pooled-geometric` for the dimensionless shape parameters, per
`pooling.md`'s ratio clause; `single-source` declared where only one study reports a
quantity. **`range-midpoint` prohibited.**

**GROUP INDEPENDENCE, AND IT IS THE POINT OF THIS PASS.** Baron 1985, Baron 1988 and Edelman
1990 are **one laboratory** and count as **one**. **Best 1981 (Porte, Seattle) is
independent.** If the form is supported by both, this is the **first equation in this model
with two independent primaries behind it**, and `form_sourcing_audit.md` moves off zero.

**POPULATION DATA:** `uncertainty_type = sd`; SEM converted with its own n, recorded per
source. n = 6 (Edelman) is small and the SD will be wide; **that is the honest width.**

---

## 5. THE FORM, FIXED BEFORE THE TABLES ARE READ

**Best 1981's own proposed structure, because it is a MECHANISM and not a curve fit:**

> *insulin-independent tissues such as brain have a relatively fixed glucose uptake, while
> other tissues have glucose transport systems which take up glucose at a rate proportional
> to its plasma concentration*

    NIMGU ~ U_fixed + k_ni * C_glu

**TWO TERMS, ONE NEW PARAMETER, AND IT IS THE SIMPLEST FORM THAT MATCHES THE STATED
MECHANISM.** `U_fixed` is the obligate, concentration-independent component; `k_ni` keeps
its meaning.

**PREFERRED OVER A SATURATING `Vmax·G/(Km+G)`**, even though Edelman reports an EG50, for
three reasons fixed now: a Michaelis form would need **two** new parameters where the
mechanism calls for one; Edelman's EG50 of 5.3 mM is for **leg muscle extraction**, a tissue
and a quantity, not whole-body NIMGU; and **`U_fixed + k_ni·G` is falsifiable against the
saturating form** by test 5 below, whereas fitting the flexible form first would make the
comparison unavailable.

**CONSTRAINT: the total must be UNCHANGED at the operating point.** `U_fixed + k_ni·G_fast`
must equal the current `k_ni_old·G_fast`, so the split is a **redistribution**, not an
addition, and health cannot move. One relation, one free shape parameter, the other derived.

---

## 6. WHAT MAY NOT MOVE

- **`GLU.NIMGU.FRACTION` (Baron 1985, 75%)**, `GLU.EGP.BASAL`, `RN.GLU.TM`,
  `GLU.INTAKE_CARBOHYDRATE`, and every Merovci-derived insulin row.
- **`S_I`**, which is a derived identity closing the 24-hour balance. It will **re-derive**
  against the new split; it may not be **re-fitted** to a target.
- **The healthy operating point** — glucose 5.44, insulin 64.2 — which §5's constraint makes
  exact rather than approximate.
- **Nothing renal.** `RN.GLU.TM` in particular: if glycosuria reappears, that must be the
  *consequence* of the uptake form, not of a moved threshold.
- **No band, pin or tolerance widened.**

---

## 7. THE FALSIFIABLE TESTS

1. **The operating point is bit-identical** — glucose, insulin, MAP, sodium, osmolality,
   urine, `Na_excr` — because §5 makes the split exact at `G_fast`.
2. **THE PREDICTION, AND IT IS ADR 0031'S OWN STATED FALSIFIER: the glucose ceiling RISES
   and glycosuria REAPPEARS.** With `U_fixed` carrying part of the disposal that no longer
   scales with glucose, the insulin-independent term can no longer clear the whole appearance
   at 15.6 mmol/L. **If the ceiling does not move, the linear term was not what capped it**,
   and that is a finding about ADR 0031's diagnosis rather than about this form.
3. **Type 1 (`beta_cell` = 0) reaches a glycaemia the literature recognises**, with
   glycosuria and an osmotic diuresis — reported, **not tuned toward**.
4. **Urine volume moves in hyperglycaemia**, which ADR 0030's thirst pass predicted and
   could not produce while the ceiling sat below the renal threshold.
5. **THE FORM COMPARISON, DECLARED IN ADVANCE.** Fit both `U_fixed + k_ni·G` and a saturating
   `Vmax·G/(Km+G)` to the *same* extracted points and report both residuals. **If the
   saturating form is materially better, say so and record that the two-term form was chosen
   on mechanism and lost on data.**
6. **Best's MCR prediction, which is a genuine out-of-sample check.** `U_fixed + k_ni·G`
   implies MCR `= U_fixed/G + k_ni`, so clearance must **fall hyperbolically** with glucose.
   Best reports it falling **38% at low insulin**. Reported as a comparison, **and
   `check_tolerances.py`'s rule applies** — two-figure inputs, so no three-figure agreement
   may be claimed.

---

## 8. THE DECISION RULE

- **N1 — both laboratories support a concentration-independent component.** Build §5, and
  `form_sourcing_audit.md` records the **first form with two independent primaries**.
- **N2 — Edelman's points fit a saturating form materially better.** Build the saturating
  form, record that the mechanism-first choice lost, and **keep Best as the independent
  corroboration of non-proportionality**, which both forms share.
- **N3 — the papers do not report whole-body NIMGU at multiple glucose levels in extractable
  form** (a real risk: Edelman's abstract truncates at 250 words and the four-level NIMGU
  arm may be in a figure). **Then the value is not extractable from what can be read, and
  this pass stops at INDETERMINATE** rather than digitising a figure. Access request goes to
  the owner.
- **N4 — the sources support proportionality after all.** Then ADR 0031's linear term is
  vindicated, B22 closes with a citation, and the ceiling is explained some other way.

---

## 9. WHAT WOULD MAKE THIS PASS A FAILURE

**Adopting an `S_G` value.** §1.2. The model has EGP and renal excretion as separate terms
and would double-count them.

**Taking "≈70%" from the review**, or any number from it. §3, and the review's own miscited
volume is why.

**Tuning `U_fixed` until glycosuria appears.** Test 2 is a *prediction*. A parameter chosen
to produce it is not a prediction, and this is the specific trap because ADR 0031 already
wrote down the expected direction.

**Counting Baron 1985, Baron 1988 and Edelman 1990 as three sources.** §4. They are one.

**Claiming agreement with Best's 38% to more figures than two.**
