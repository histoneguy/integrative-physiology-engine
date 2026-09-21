# Pre-registration — glucose and insulin

**Written 2026-09-21, before any source is opened and before any search has been run for
these values.** Verify the ordering with

    git log --diff-filter=A -- validation/glucose_insulin_prereg.md

---

## 0. WHY THIS ONE, AND THE GUARD IT HAS TO PASS FIRST

HANDOVER §4 item 1 says it plainly: **"Cortisol, insulin and glucose still connect to
nothing, and an endocrine component built for completeness rather than connection is
exactly what ADR 0006 records Circadian being. Directive 1.11 is the guard."**

**So the first question is not what to build, it is what it connects to, and the answer has
to exist before anything is written.**

| connection | where it lands | status today |
|---|---|---|
| glucose is an extracellular osmole | `BodyFluids.Osm_ecf ~ 2*C_Na + Osm_other` | **`Osm_other` is a CONSTANT**, `BF.OSM_NONSODIUM` |
| osmolality drives vasopressin | `Adh.jl`, input `Osm_ecf` | **already wired** |
| urinary glucose is an osmotic solute | `RN.URINE.SOLUTE_LOAD`, urine volume | **solute load is a constant** |
| metabolic rate sets substrate use | `Thyroid.th_mod`, `Blood.VO2`/`RER` | **`RER` exists and is a constant** |

**THE SLOT ALREADY EXISTS IN THREE PLACES AND IS A CONSTANT IN ALL THREE.** That is the
same shape as `V_ecf` before §3.22 and `Na_distal` before ADR 0028: a quantity the model
names, does not compute, and therefore cannot respond to.

**IF THE CONNECTIONS BELOW CANNOT BE MADE, THIS PASS DOES NOT BUILD THE COMPONENT.** See
branch G5.

---

## 1. THE MINIMUM THAT IS WORTH BUILDING

**Two states, not more.** Plasma glucose and plasma insulin. Directive 1.10: a state is
paid on every run of a model that integrates four hundred days.

- **Glucose** — a mass balance: appearance (hepatic production + absorbed intake) minus
  disposal (insulin-dependent and insulin-independent) minus **urinary loss**.
- **Insulin** — secretion as a function of glucose, and first-order clearance. Fast
  relative to everything else in this model.

**WHAT IS EXPLICITLY NOT BUILT IN THIS PASS:** glucagon, incretins, free fatty acids, the
two-compartment insulin kinetics of the clamp literature, beta-cell mass dynamics, and any
disease state beyond turning one parameter down. Each is a separate pass with its own
record, and listing them here is what stops them arriving quietly.

---

## 2. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED BEFORE SEARCHING

This subsystem is made of teaching numbers and **this repository's record on those is four
materially wrong out of six openable**. Named in advance so none can be entered by reflex:

- Fasting plasma glucose **"90"** or **"100" mg/dL**; **5.0** or **5.5 mmol/L**.
- The renal glucose threshold **"180 mg/dL"** / **10 mmol/L**. This one is the most
  suspect of the set: it is a *population* threshold quoted as a constant, it varies with
  glomerular filtration rate, and the quantity a model needs is a **maximum reabsorptive
  rate**, not a plasma concentration.
- Hepatic glucose production **"2 mg/kg/min"**; glucose distribution volume **"20% of body
  weight"**; insulin half-life **"4-6 minutes"**.
- **A "normal" OGTT peak of "140 mg/dL"** — a diagnostic cut-point, not a measurement.

**None is enterable without a source, and any that survives must say which paper measured
it in whom.**

---

## 3. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults, non-diabetic by the study's own criterion, fasted where the
protocol requires it, no glucose-lowering medication. Prefer **within-subject
perturbation** — OGTT, IVGTT, clamp — over cross-sectional association, because the model
needs a *relationship* and not a level.

**Exclude:** type 1 and type 2 diabetes cohorts for anything that sets a NORMAL value,
pregnancy, critical illness, and paediatric series.

**DIRECTIVE 1.7 WILL BITE AND IT IS PREDICTED HERE.** Glucose physiology exists in the
literature overwhelmingly as **diabetes research** — the relationships are characterised in
people who have lost them. This is the same trap as lower-body negative pressure being
syncope research and acid–base being disorder-driven. **Prefer studies whose subject is
normal glucose regulation itself.**

**AND OTHER WHOLE-BODY MODELS ARE NOT SOURCES.** The Bergman minimal model, Sorensen, and
the UVA/Padova simulator are all *models*. If a form is taken from one it enters as
`calibrated` with the originating model named, which is what `SOURCES.md` reserves that
label for and what `RN.TAL.KM` set the precedent for.

---

## 4. THE IDENTIFIABILITY PROBLEM, STATED BEFORE THE SEARCH

**Insulin sensitivity and beta-cell responsiveness are not separately identifiable from a
fasting pair.** Fasting glucose and fasting insulin give one equation; HOMA-IR and HOMA-B
are two indices computed from the same two numbers and are therefore **not** two
measurements. **A pass that sets both from HOMA has set one number twice** — §5 item 22 in
a new subsystem.

**So at least one of the two must come from a PERTURBATION**: a clamp for sensitivity, or
an IVGTT/OGTT time course for secretion. **If neither can be opened, branch G4 applies.**

---

## 5. WHAT MAY NOT MOVE

- **`BF.OSM_NONSODIUM`** may not be re-solved to absorb a new glucose term. It currently
  lumps glucose, urea and the rest; if glucose becomes explicit, the constant must be
  **reduced by the glucose it now double-counts, from the same source that sets fasting
  glucose**, and that subtraction is arithmetic, not a fit.
- **`ADH.OSM.THRESHOLD`, `ADH.OSM.SENSITIVITY`** — Baylis, and the water limb is settled.
- **`RN.URINE.SOLUTE_LOAD`** — sourced on 2026-09-16; urinary glucose ADDS to it and does
  not re-scale it.
- **`BF.NA.PLASMA_SETPOINT`, `RN.GFR.NOMINAL`, and every renal row touched by ADR 0025-0028.**
- **The resting operating point.** At normal glucose the model's MAP, sodium, urine volume
  and osmolality must be **unchanged to the precision they are currently pinned at**.
- **No band, pin or tolerance widened.**

---

## 6. THE DECISION RULE

- **G1 — fasting glucose, insulin secretion and insulin sensitivity all source in healthy
  adults, and at least one comes from a perturbation.** Build both states and all three
  connections.
- **G2 — glucose sources but insulin does not identify (§4).** Build glucose with a
  **fixed** disposal rate and NO insulin state, and say so. A glucose that responds to
  intake and spills into urine is still worth having; an insulin whose two gains trade off
  freely is not.
- **G3 — the renal threshold cannot be sourced as a reabsorptive maximum.** Build the
  osmotic connection anyway with the loss term switched OFF and its falsifier named, the
  discipline `thyroid metabolic` and the `sat_rel` hypoxic limb are already wired under.
- **G4 — neither limb identifies.** Build nothing, record the search terms per §3.33, and
  say the subsystem is blocked on access rather than on effort.
- **G5 — the connections turn out not to bite.** If an explicit glucose changes `Osm_ecf`
  by less than the model can resolve, and urinary glucose is zero at every normal
  concentration, then **the component connects to nothing in practice** and building it is
  the Circadian error. **Report that and stop.** This is the branch I expect to have to
  take seriously, and it is written down first so it cannot be argued away later.

---

## 7. THE FALSIFIABLE TESTS

1. **Resting operating point unchanged** — MAP, plasma sodium, osmolality, urine volume,
   `Na_excr`, at normal glucose.
2. **Fasting glucose and insulin land on their sourced values**, by running.
3. **An oral glucose load reproduces a measured OGTT time course** — peak and return —
   against a study **held out of every estimation**, named in advance here rather than
   chosen afterwards.
4. **Osmotic diuresis is a PREDICTION, and it is the one worth having.** At a glucose high
   enough to exceed the reabsorptive maximum, urine volume must rise, and the model has
   never been able to produce a solute diuresis from anything but sodium. Reported against
   whatever human data can be found, with the comparison stated as out-of-sample.
5. **`Osm_ecf` moves by the right amount per mmol/L of glucose** — an identity, since
   glucose is an osmole, and it checks the double-count subtraction of §5.
6. **The chronic salt endpoints, Jensen, Lobo and the renin ratio are all unchanged** at
   normal glucose, reported.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Building two states because a subsystem "should have" two.** §4 says when it may not.

**Setting insulin sensitivity and secretion from the same fasting pair** and reporting them
as two sourced numbers.

**Entering the 180 mg/dL renal threshold** because every textbook has it. §2.

**Reporting G1 when the honest answer is G5.** A component that changes nothing the model
can resolve has not been connected, whatever the ledger says about it.

**Letting `BF.OSM_NONSODIUM` absorb the difference.** It is the free parameter in this pass
and §5 forbids it for that reason.

---

## 9. SOURCING LOG — appended as each source is OPENED, 2026-09-21

**Directive 1.5. Reading level recorded for every entry, before any value enters the ledger.**

### 9.1 Branch G5 was tested FIRST and is NOT taken

The pre-registration said G5 was the branch to take seriously, so it was checked before any
source was opened. `Osm_ecf` = `2*C_Na + Osm_other`; with plasma osmolality 287 and sodium
140 the non-sodium lump is about **7 mOsm/kg**, and `ADH.OSM.SENSITIVITY` is 0.12 per
mOsm/kg. A 10 mmol/L glucose excursion is a **10 mOsm/kg** signal — an order of magnitude
above anything the model cannot resolve — and it also shifts water out of cells, which the
ICF/ECF partition already represents. **The connection bites. G5 is not taken.**

At NORMAL glucose the contribution is a constant offset already inside `BF.OSM_NONSODIUM`,
which is why §7 test 1 (operating point unchanged) and §7 test 5 (the double-count
subtraction) are the pair that keep this honest.

### 9.2 Renal glucose reabsorptive maximum — SOURCED

**Mogensen CE.** *Maximum Tubular Reabsorption Capacity for Glucose and Renal Hemodynamics
during Rapid Hypertonic Glucose Infusion in Normal and Diabetic Subjects.* Scand J Clin Lab
Invest 1971;28(1):101-109. **PMID 5093515**, doi 10.3109/00365517109090668.

**READING LEVEL: ABSTRACT READ IN FULL at the publisher, 2026-09-21. PubMed carries NO
abstract for this paper** — the figures below were first seen in a search summary of
secondary reviews, which is not a reading, and were only accepted after the publisher's own
abstract was opened. The full text is paywalled.

| | |
|---|---|
| **normal subjects** | **TmG 352 ± 64 mg/min, n = 9** |
| diabetics, short duration | 419 ± 50 mg/min, n = 10 |

**THREE THINGS THIS SETTLES, AND THE SECOND IS THE ONE THAT MATTERS:**

1. **§2's flagged round number survives, but only just.** The textbook **375 mg/min** sits
   inside 352 ± 64 — so it is not *wrong*, it simply **has no error bar and this does**. The
   sourced value is entered with its dispersion; the teaching number could not have been.
2. **TmG CORRELATES WITH GFR** — *"for the whole material there was a clear positive
   correlation between GFR and Tmc."* So it is **not a fixed mg/min** and must not be
   entered as one. It scales with filtration, which is the scaling discipline this ledger
   already applies to every extensive renal quantity, and the paper supplies the reason
   rather than the model assuming it.
3. **AND IT HANDS THIS PASS A HELD-OUT TEST NOBODY WENT LOOKING FOR.** In both groups,
   during glucose infusion, **urinary potassium excretion FELL and urinary sodium excretion
   ROSE.** This model has sodium AND potassium. That is a measured human response to a
   glucose load, in two quantities the model already computes, **from the same paper that
   supplies TmG but from a different sentence** — so it is usable as an out-of-sample
   direction check provided no gain is ever fitted to it. **Recorded here, before the
   component exists, so that it cannot later be claimed as a prediction that was designed
   in.**

### 9.3 Still needed

Fasting plasma glucose and insulin in healthy adults; basal glucose turnover; glucose
distribution volume; and at least one PERTURBATION for §4's identifiability requirement.

---

## 10. THE NHANES OPERATIONALISATION, FIXED BEFORE THE EXTRACTION IS WRITTEN

**Appended 2026-09-21, before `glucose_insulin_extract.py` exists.** Verify with

    git log --diff-filter=A -- validation/glucose_insulin_extract.py

§3 fixed admissibility in words. **This fixes it in columns**, because "healthy adult" is a
decision and `nhanes_hpt_prereg.md` set the precedent that it is made before the data are
touched, not after.

### 10.1 Files and cycles

NHANES **2007-2008 (E), 2009-2010 (F), 2011-2012 (G)** — the same three cycles the thyroid
axis used, so the two subsystems describe the same population. Files **GLU** (fasting
glucose `LBXGLU`, insulin `LBXIN`), **DEMO**, **RXQ_RX**, **DIQ**.

**Insulin moved out of the GLU file after 2011-2012**, which is the reason these three
cycles and not later ones. Stated so the choice is not mistaken for cherry-picking.

### 10.2 The population, fixed now

**Include:** age `RIDAGEYR` **>= 20**; valid `LBXGLU` **and** `LBXIN`; fasting-subsample
weight `WTSAF2YR` > 0; fasting time `PHAFSTHR` **>= 8** hours.

**Exclude:**
- **Diagnosed diabetes** — `DIQ010 == 1`.
- **Told they are prediabetic** — `DIQ160 == 1`. Excluded because §3 says a NORMAL value may
  not come from people who have lost the relationship, and prediabetes is the loss beginning.
- **Any glucose-lowering drug** in `RXQ_RX`, matched as substrings of `RXDDRUG`:
  INSULIN, METFORMIN, GLIPIZIDE, GLYBURIDE, GLIMEPIRIDE, PIOGLITAZONE, ROSIGLITAZONE,
  SITAGLIPTIN, SAXAGLIPTIN, LINAGLIPTIN, EXENATIDE, LIRAGLUTIDE, ACARBOSE, NATEGLINIDE,
  REPAGLINIDE, CHLORPROPAMIDE, TOLBUTAMIDE, TOLAZAMIDE.
- **Pregnancy** — `RIDEXPRG == 1`.
- **`LBXGLU` >= 126 mg/dL**, the diagnostic threshold for undiagnosed diabetes. **THIS IS A
  DIAGNOSTIC CUT-POINT AND NOT A MEASUREMENT** — §2 — and it is used here ONLY to exclude
  people, never as a model value. The count excluded is reported.

### 10.3 Weighting, and the same honesty as the thyroid pass

Point estimates weighted with `WTSAF2YR/3` for three pooled cycles. **Standard errors
computed WITHOUT strata and PSU**, so they are independent-sampling errors and are
**optimistic by a design-effect factor of roughly 1.5 to 2.5**. No conclusion in this pass
may rest on one being narrow. Copied deliberately from `nhanes_hpt_extract.py` rather than
re-derived.

### 10.4 What is taken, and what is NOT

**TAKEN:** the weighted **median and interquartile range** of fasting glucose and of fasting
insulin, and the counts at each exclusion step.

**NOT TAKEN: any relationship between them.** §4 says fasting glucose and fasting insulin
are ONE equation, so a regression of one on the other across this cohort is not a second
measurement and may not be used to set insulin sensitivity. **NHANES cannot discharge §4 and
is not being asked to.** The perturbation study is still required, and if it does not open,
branch **G2** applies.

### 10.5 The decision branch this adds

- **N1 — both land with usable dispersion.** Enter fasting glucose and fasting insulin as
  `reported`, cycle and population named on the row.
- **N2 — the download fails or the columns are absent.** Record it, and fall back to a
  published reference interval with its cohort stated. Do NOT substitute a textbook value.

### 9.4 Basal endogenous glucose production — SOURCED

**Huidekoper HH et al.** *Endogenous glucose production from infancy to adulthood: a
non-linear regression model.* Arch Dis Child 2014 Dec. **PMID 24996789. ABSTRACT READ IN
FULL on PubMed, 2026-09-21.**

`[6,6-2H2]` glucose dilution after an overnight fast during normoglycaemia, **n = 40
healthy subjects aged 2.5-54.3 y**, one-phase exponential decay fit:

    EGP (mg/kg/min) = 6.50 * e^(-0.145 * age_years) + 1.93

**THE ADULT PLATEAU IS WHAT A MODEL WITHOUT AN AGE DIMENSION CAN USE.** Beyond about 30
years the exponential term contributes under 2%, so EGP is **1.93-1.97 mg/kg/min** across
the adult range and the age term is not representable here anyway.

**THE COHORT IS PAEDIATRIC-WEIGHTED AND THAT IS THE LIMITATION.** It is an *Archives of
Disease in Childhood* paper whose purpose is paediatric fluid therapy; the adult end of
2.5-54.3 y is the sparse end. **No dispersion is given for the regression parameters in the
abstract** — a second extraction gap of the same kind as Lorenz's SEMs.

§2's flagged round number, **"2 mg/kg/min"**, again sits close to a sourced value that
carries a form and a cohort where the round number carries neither.

### 9.5 Fasting glucose and fasting insulin — SOURCED, branch N1

`validation/glucose_insulin_extract.py`, NHANES 2007-2012, run 2026-09-21. **n = 5,563**
after every exclusion §10.2 fixed in advance.

| | median | IQR |
|---|---|---|
| fasting plasma glucose | **5.44 mmol/L** (98 mg/dL) | 5.05-5.77 |
| fasting insulin | **64.2 pmol/L** (9.25 uU/mL) | 41.9-103.2 |

**DIRECTIVE 1.12 SCORES AGAIN, AND THIS TIME THE ROUND NUMBER IS MATERIALLY WRONG.** §2
listed "5.0 mmol/L" as the teaching value for fasting glucose. **5.0 sits essentially at the
25th percentile of healthy US adults, not at the median** — the measured centre is 5.44.
That is the fifth instance of this repository's pattern.

**The median, not the mean, and it was fixed before the data were seen** (§10.4). Fasting
insulin's weighted mean is 11.87 uU/mL against a median of 9.25 — **28% apart** — so a mean
would have described nobody typical.

### 9.6 Insulin sensitivity — ONE SOURCE OPENED AND REJECTED

**Tam CS et al.** *Defining insulin resistance from hyperinsulinemic-euglycemic clamps.*
Diabetes Care 2012;35(7):1605-1610. **PMID 22511259. ABSTRACT READ IN FULL, 2026-09-21.**

**NOT ADMISSIBLE, AND REJECTED ON TWO OF THIS PASS'S OWN RULES:**

1. **Its numbers are CUT-POINTS, not measurements.** It reports the glucose disposal rate
   below which 75% of individuals "are truly insulin resistant" — 4.9 mg/kg/min on body
   weight. **§2 names diagnostic cut-points as a class this repository keeps getting wrong**
   and this is one.
2. **Its cohort contains diabetics by design** — 51 with diabetes against 116 without.
   **§3 excludes diabetes cohorts for anything that sets a NORMAL value.**

**Recorded rather than quietly skipped**, because a source opened and rejected is evidence
about the search and the next reader should not have to open it again.

### 9.7 Still outstanding — the §4 blocker

**Insulin sensitivity from a perturbation in healthy adults.** The right cohort has been
identified: the **EGIR-RISC study** — about 1,300-1,500 healthy Europeans aged 30-60,
euglycaemic clamp, across 19-20 centres, **a study whose subject IS normal insulin
sensitivity**, which is exactly what directive 1.7 asks for. The value is not yet in hand.

**IF IT DOES NOT OPEN, BRANCH G2 APPLIES** and glucose is built with a fixed disposal rate
and no insulin state. That is written here before the attempt, so a failure to source
cannot quietly become a fit.

### 9.8 BRANCH G2 IS TAKEN — insulin sensitivity did not source

**Three sources opened, 2026-09-21, none enterable. Recorded individually so the next
reader does not repeat the search.**

| source | reading level | why it fails |
|---|---|---|
| **Tam 2012**, Diabetes Care 35(7):1605, PMID 22511259 | abstract, full | reports CUT-POINTS, not measurements (§2); cohort contains 51 diabetics by design (§3) |
| **Zanetti 2023**, Diabetologia 66(9):1643, PMID 37329449, PMC10390625 | **full text read** | RISC n = 966 healthy adults, age 44.5 (8.3), BMI 25.4 (4.0), **M value 7.12 (2.95) — REPORTED WITH NO UNITS ANYWHERE IN THE PAPER**, and it explicitly notes differing clamp methodology between its two cohorts |
| **Hills 2004**, Diabetologia 47:566, RISC methodology | abstract, full | study-design paper; no value, full text paywalled |

**THE SECOND ONE IS THE INSTRUCTIVE FAILURE.** It is the right cohort — healthy, non-diabetic,
1,500 Europeans aged 30-60, a study whose subject IS normal insulin sensitivity, exactly
what directive 1.7 asks for — and its headline number **cannot be used because no unit is
printed**. 7.12 is consistent with mg/kg_FFM/min and inconsistent with the usual molar
convention, so it could be *inferred*. **It is not.** §3.26 is the record of what composing
quantities across unstated scales costs here, and a number whose unit is a guess is not a
measurement.

### 9.9 AND G2 HAS A DESIGN CONSEQUENCE: GLUCOSE IS NOT A STATE

**§1 proposed two states. G2 removes the regulator, and with it the case for either.**

With no insulin there is nothing that makes glucose move on a timescale this model runs. Its
pool turns over in about an hour; no existing challenge infuses glucose; and with a fixed
disposal rate the balance has no dynamics of its own worth integrating. **Directive 1.10:
a state is paid on every run of a model that integrates four hundred days.**

**So glucose enters as an ALGEBRAIC balance and the component adds ZERO states.** What the
model actually needs from it is the *level* — the thing that sets osmolality and urinary
loss — and that is what an algebraic balance gives.

**IF INSULIN EVER SOURCES, GLUCOSE BECOMES A STATE IN THAT PASS AND THIS SENTENCE IS THE
REASON IT WAS NOT ONE HERE.**

### 9.10 What G2 can and cannot claim — §7 test 3 is VOID

- **CAN:** sustained hyperglycaemia and its consequences — raised osmolality, the ADH
  response, urinary glucose above the reabsorptive maximum, and osmotic diuresis. This is
  the complication axis and it is what makes the component worth building.
- **CANNOT:** glucose *regulation*. **§7 test 3, the OGTT time course, is VOID** — not
  failed. The component does not claim a regulator, so a test of one has nothing to judge,
  and declaring it void is the treatment ADR 0020 used for its own tests 2 and 3 rather
  than running a test the structure cannot address.

**Tests 1, 2, 4, 5 and 6 all still run**, and test 4 — osmotic diuresis — is the prediction
this pass exists to produce.

### 9.11 AMENDMENT — Zanetti's units resolved, and G2 still stands

**The owner supplied Zanetti's Methods and Supplementary Information, 2026-09-21.** Two
things change and one does not.

**THE UNITS OBJECTION IN §9.8 IS WITHDRAWN.** The Methods read: *"the M value, the rate of
glucose disposal, was calculated as the amount of glucose taken up during the EIC study and
was transformed to milligrams per kilogram body weight per minute."* So RISC's

    M = 7.12 +/- 2.95 mg/kg/min, n = 966 healthy adults, age 44.5 (8.3), BMI 25.4 (4.0)

**is a real, unit-stated measurement and §9.8's rejection of it no longer applies.** It was
correct at the time - no unit appears in the paper body or its tables - and it is withdrawn
rather than deleted, because the reason it was made is the reason to keep looking.

**BUT THE ESM GIVES THE INFUSION RATE, NOT THE ACHIEVED CONCENTRATION.** RISC clamped
glucose at 4.5-5.5 mmol/L with insulin infused at **240 pmol/min/m2**, steady state 80-120
min. The ESM's own words are that M measures *"sensitivity to the prevailing plasma insulin
concentrations"* - and **the prevailing concentration is not reported.**

**A POINT WITHOUT ITS ABSCISSA IS NOT A POINT.** The model needs disposal as a function of
insulin:

    disposal = (k_ii + S_I * I) * G

Fasting gives one equation, the clamp gives a second, and **I_clamp is a third unknown**.
Recovering it from 240 pmol/min/m2 would require an insulin clearance that is not sourced
either, and chaining one assumption onto another to manufacture a measurement is the
failure §3.26 records. **BRANCH G2 IS UNCHANGED.**

**WHAT IS RECORDED INSTEAD — A HELD-OUT TARGET, NOT A PARAMETER.** M = 7.12 mg/kg/min
against this model's basal disposal of 1.93 mg/kg/min is a **3.7-fold dynamic range** for
insulin-stimulated glucose disposal in healthy humans. **It is NOT entered in the ledger,
because nothing reads it and directive 1.11 exists to prevent exactly that.** It is written
here so that the day an insulin axis lands, there is a number waiting that no part of that
pass will have been fitted to.

**WHAT WOULD UPGRADE G2 TO G1:** the steady-state plasma insulin concentration during the
RISC clamp. One number, from a RISC baseline paper rather than this one.
