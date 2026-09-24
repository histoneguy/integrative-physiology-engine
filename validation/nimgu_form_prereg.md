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

---

## 10. EXTRACTION RECORD — 2026-09-24, AND IT STOPS AT BRANCH N3

**Written after §§0–9 and after the searches below; nothing above was edited.**

### 10.1 What could be read, and what could not

| Paper | DOI | Open? | Read |
|---|---|---|---|
| Baron 1985, JCI | 10.1172/jci112169 | **yes, bronze** | abstract in full; **full text not reachable** by the fetcher |
| Baron 1988 | — | no | numbers as already recorded in ADR 0031 |
| Edelman 1990, Diabetes | 10.2337/diab.39.8.955 | **closed** | abstract, truncated at 250 words |
| Best 1981, Diabetes | 10.2337/diab.30.10.847 | **closed** | abstract |

**Checked against OpenAlex** rather than assumed from a paywall page — three are `closed`,
Baron 1985 is `bronze`. **No bot check was worked around** on `diabetesjournals.org`,
`journals.physiology.org` or elsewhere.

### 10.2 What Baron 1985's abstract does supply, and it is more than expected

| | controls |
|---|---|
| basal Rd | **150 ± 7 mg/min** |
| NIMGU at basal glucose | **113 ± 8 mg/min** |
| NIMGU at a 250 mg/dl SRIF clamp | **186 ± 19 mg/min** |
| NIMGU share of basal Rd | **75 ± 5%**, SEM, n = 11 |

**INTERNALLY CONSISTENT AND THAT IS A REAL CHECK:** 0.75 × 150 = 112.5 ≈ 113. The share and
the absolute rate are not independent claims, and they agree.

**A TWO-POINT NIMGU DOSE-RESPONSE IS THEREFORE IN AN OPEN-ACCESS PAPER**, which §8's branch
N3 did not anticipate — it expected the dose–response to live only in the closed Edelman.

### 10.3 Why the pass still stops

**THE FIT NEEDS THE CONTROLS' FASTING GLUCOSE AND THE ABSTRACT DOES NOT REPORT IT.**
`U_fixed + k_ni·G` through (G_basal, 113) and (250, 186) is an exact two-point inversion —
but only once `G_basal` is known.

**AND SUBSTITUTING 90 mg/dl IS EXACTLY WHAT §3 FORBADE.** That is directive 1.12's teaching
number, listed before extraction for this reason. The answer moves on it:

| assumed `G_basal` | concentration-independent fraction at basal |
|---|---|
| 90 mg/dl (the teaching number) | **64%** |
| 98 mg/dl (this model's NHANES fasting value) | **58%** |

**THE DIRECTION IS ROBUST AND THE MAGNITUDE IS NOT.** Best 1981's independent bracket,
derived from its reported 38% fall in metabolic clearance, is **63–76%** — and it too is
unextractable to better precision, because its abstract says only *"more than twice basal"*,
which spans 63% at 2.5× and 76% at 2.0×.

**SO TWO INDEPENDENT LABORATORIES AGREE ON THE FORM AND NEITHER PINS THE VALUE FROM WHAT CAN
BE READ.** Entering a number here would be a three-figure claim built on a two-figure
assumption about someone else's cohort — directive 1.13, and `check_tolerances.py` exists
because that failure is structural rather than occasional.

### 10.4 What is nevertheless established, and it is not nothing

**NIMGU IS NOT PROPORTIONAL TO GLUCOSE, ON TWO INDEPENDENT LINES OF HUMAN EVIDENCE.** Baron
(Indiana, SRIF clamp, direct rates) and Best (Porte, Seattle, somatostatin at three fixed
insulin levels, metabolic clearance) — **different cities, methods, decades and endpoints.**
ADR 0031's `k_ni·C_glu` is therefore **wrong in form and not merely imprecise**, and its own
stated falsifier stands.

**THIS IS THE FIRST FORM IN THIS MODEL WITH TWO INDEPENDENT GROUPS BEHIND IT** — and it
cannot be built yet. `form_sourcing_audit.md` stays at **zero** until it is, because the
audit counts what is in `relations.csv`, not what is known.

### 10.5 SUPERSEDED — the number was obtained, 2026-09-24, and the branch is N1

**§10.3 stopped because the controls' fasting glucose was not in the abstract. It is in the
paper, and the paper is open access.** The JCI PDF was downloaded directly from the
publisher's own open-access link — **no bot check was involved or circumvented**, and this
is what §10.1 should have done before writing a stop.

**Table I. Control, n = 11: fasting serum glucose 90 ± 1.7 mg/dl** (the text rounds it to
90 ± 2).

#### The exact two-point inversion

| glucose | NIMGU | n |
|---|---|---|
| **90** mg/dl (euglycaemic) | **113 ± 8** mg/min | 11 |
| **248 ± 2** mg/dl (SRIF + hyperglycaemic clamp) | **186 ± 19** mg/min | **7** |

**THE TWO POINTS HAVE DIFFERENT n — 11 and 7 — because only seven controls underwent the
hyperglycaemic arm.** Recorded because it is the kind of detail an abstract loses.

    k_ni    = (186 - 113)/(248 - 90) = 0.462 (mg/min)/(mg/dl)
    U_fixed = 113 - 0.462 x 90       = 71.4  mg/min
    concentration-independent fraction at fasting = 71.4/113 = 0.63

**AND THE PAPER CONTAINS ITS OWN CONSISTENCY CHECK, WHICH THE FIT PASSES.** It separately
reports NIMGU metabolic clearance falling **1.2 ± 0.07 → 0.74 ± 0.08**. The fitted rates give
113/90 = **1.256** and 186/248 = **0.750**. **The arithmetic closes**, so the rates and the
clearances are one dataset and not two claims.

**A CORRECTION MADE IMMEDIATELY RATHER THAN CARRIED.** The clearance *fall* is **38%** from
the paper's printed clearances and **40.3%** from the fitted rates. These are **not** two
findings: 1.2 ± 0.07 and 0.74 ± 0.08 are two-figure numbers whose ratio carries several
points of uncertainty, and directive 1.13 forbids reading a difference inside that as
anything. **Neither figure may be quoted to three.**

#### The independent corroboration, and it is strong

**Best 1981 reports metabolic clearance falling 38% at low insulin** — the same direction,
the same rough magnitude, in a **different laboratory** (Porte, Seattle), a **different
decade**, and by a **different protocol** (somatostatin at three fixed insulin levels rather
than one insulinopenic clamp at two glucose levels). Best's implied concentration-independent
fraction is **63–76%**, and **it contains Baron's 63%.**

**THIS IS BRANCH N1.** Two independent groups support the form; one supplies the value; the
other constrains it and agrees. **§4's group-independence rule is satisfied on the FORM,
which is what directive 1.16 asked for and what no other equation in this model has.**

#### Dispersions, per §4

All Baron figures are **SEM**; converted with their own n. **NIMGU basal SD = 8 x sqrt(11) =
26.5 mg/min; hyperglycaemic SD = 19 x sqrt(7) = 50.3; the 75 ± 5% share SD = 16.6 percentage
points**, which is the figure ADR 0031 already carries.

---

### 10.6 The access request that REMAINS — and it is no longer blocking

**Nothing blocks B22 any more.** Edelman 1990 (`10.2337/diab.39.8.955`) and Best 1981
(`10.2337/diab.30.10.847`) are both `closed` by OpenAlex and both remain **desirable rather
than required**:

- **Edelman 1990** would add a **four-point** dose–response where Baron gives two, turning an
  exact inversion into something with a residual — which is the only way §7 test 5's
  comparison against a saturating form can be decided on data rather than on mechanism.
- **Best 1981** would replace an abstract-derived 63–76% bracket with a real number and make
  the form **pooled** rather than corroborated.

**Neither is needed to build.** They are what would let the next pass falsify this one.

