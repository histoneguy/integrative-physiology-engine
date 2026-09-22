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

### 9.12 The insulin concentration was pursued in other clamp papers and is still not in hand

**At the owner's suggestion, 2026-09-21.** The right move is not to patch RISC's M with
another study's insulin - that composes two protocols - but to find ONE paper reporting
**both** a measured steady-state insulin and M in healthy adults. That was searched for and
not found; the literature returns method and reproducibility papers.

**What WAS found, and it is the canonical anchor:**

**DeFronzo RA, Tobin JD, Andres R.** *Glucose clamp technique: a method for quantifying
insulin secretion and resistance.* Am J Physiol 1979;237(3):E214-E223. **PMID 382871.
ABSTRACT READ IN FULL, 2026-09-21.** The method paper itself:

> *"The plasma insulin concentration is acutely raised and maintained at approximately 100
> muU/ml by a prime-continuous infusion of insulin."*

**100 uU/mL is about 694 pmol/L. IT IS NOT ENTERED, FOR TWO REASONS THAT ARE BOTH ON THE
FACE OF IT:**

1. **It is the method's DESIGN TARGET, not a measurement** - "approximately", one
   significant figure, describing what the technique aims at rather than what a cohort
   achieved.
2. **THE PROTOCOLS DIFFER.** DeFronzo's standard clamp infuses about 40 mU/m2/min; RISC
   infuses 240 pmol/min/m2, which is about 35. Pairing RISC's M with DeFronzo's insulin
   would be reading a dose-response at a dose neither paper ran.

**A sensitivity derived from those two would be `assumed` wearing `derived`'s label**, and
§4 of this pre-registration exists precisely to stop insulin's gains being softly
determined. **G2 STANDS.**

**THE MODEL IS ONE NUMBER AWAY AND THE NUMBER IS SPECIFIC:** the **measured steady-state
plasma insulin during the RISC clamp**, which a RISC baseline paper will carry in its
characteristics table. With it, RISC's M and this model's fasting balance become two points
on the insulin-disposal line - a perturbation and a steady state, which is exactly what §4
asks for - and G2 becomes G1 in a single pass.

---

## 11. AMENDMENT — THE CLAMP IS NOT NEEDED, AND A SCALE PROBLEM I CREATED

**Written 2026-09-22, before any NIMGU source is opened.** Only the search-result summaries
have been seen; no paper has been read and no value is entered.

### 11.1 Non-insulin-mediated uptake replaces the clamp

§4 said insulin sensitivity and secretion are not separately identifiable from a fasting
pair, and §9.8/§9.12 then failed to source a clamp with a stated steady-state insulin.
**There is a second route and it does not need one.**

**Non-insulin-mediated glucose uptake (NIMGU) is itself measured in humans.** If its basal
fraction is sourced, the postabsorptive balance splits:

    postabsorptive disposal = EGP                       (sourced, Huidekoper)
    NIMGU                   = f_nimgu * EGP             (sourced, this pass)
    insulin-mediated        = (1 - f_nimgu) * EGP       at I_fast (sourced, NHANES)

**That is two independent measurements, not one datum used twice**, and §4 is discharged
without a clamp. The clamp remains the better instrument and `OPEN-QUESTIONS` keeps the ask;
this is the route that is actually open.

### 11.2 The pooling rule, declared before extraction

`pooling.md`, in its order of preference. Candidates seen in search summaries only: Baron
1985 (PMID 2865274), Baron 1988 (Am J Physiol 255:E769), PMID 9597380, PMID 20153490, and
Gottesman's 1.62 mg/kg/min in 16 lean non-diabetic subjects.

1. **`meta-analysis`** if one has already pooled NIMGU fractions.
2. **`pooled-inverse-variance`** — expected, since several report a fraction with a
   dispersion and an n.
3. **`pooled-n-weighted`**, then **`pooled-unweighted`**, then **`single-source`**.

**NOT POOLED:** diabetic and insulin-resistant arms — NIMGU is *elevated* in type II diabetes
and averaging those in would describe no healthy person. **NOT POOLED ACROSS METHODS** where
the somatostatin-suppression and clamp-based estimates differ in what they measure; the
method is recorded per source and mixing is decided by whether they estimate the same
quantity, not by convenience.

**A FRACTION IS NOT A RATIO WITH NULL 1.0**, so `pooled-geometric` does **not** apply here
despite the quantity being dimensionless — rule 4 is for gains and multipliers.

**AND THE ROW CARRIES THE BETWEEN-SUBJECT SD**, per §8.4 of `thirst_prereg.md`: pooling
shrinks the uncertainty in the mean and must not shrink population spread.

### 11.3 THE SCALE PROBLEM, AND IT IS MINE

**Adding dietary carbohydrate made the model's glucose balance a 24-HOUR AVERAGE while its
target stayed a FASTING measurement.** `k_glu` is derived so that appearance — now hepatic
production **plus** 225 g/day of diet — lands at `GLU.PLASMA.FASTING` = 5.44 mmol/L. **That
forces a fed-and-fasted average to sit at the postabsorptive concentration, which is wrong
in a direction I can state: the 24-hour mean glucose in healthy adults is HIGHER than the
fasting value.**

Sodium and water already run as 24-hour averages, so the model's framing is consistent and
**glucose's target is the odd one out.**

**NIMGU MAKES THIS BITE RATHER THAN MERELY UNTIDY.** The NIMGU fraction is measured
**postabsorptively**. Applying it to a 24-hour-average balance would overstate the
non-insulin-mediated share, because the fed state is exactly when insulin-mediated uptake
dominates. **That is a §3.26 scale mismatch and it is recorded here before any number is
taken.**

### 11.4 The decision, fixed now

- **D1 — 24-hour mean glucose sources in healthy adults** (continuous glucose monitoring
  normative data is abundant and poolable). **Then it becomes the model's target**, `k_glu`
  is derived against it, and **`GLU.PLASMA.FASTING` becomes a HELD-OUT comparison** that the
  model has not been fitted to. This is the preferred outcome and it turns a row into a test.
- **D2 — it does not source.** Keep the fasting target, and **state the approximation on the
  row**: a 24-hour balance pinned to a postabsorptive concentration, with the direction of
  the error named.
- **D3 — the NIMGU fraction is only available in mixed or diabetic cohorts.** Do not pool
  them; record INDETERMINATE and leave insulin unbuilt, as §6's G2 already permits.

**WHAT MAY NOT HAPPEN:** `GLU.INTAKE.CARBOHYDRATE` may not be reduced to make a fasting
target fit a fed balance. It is a measured input and the mismatch is in the target, not in
it.

### 11.5 THE CGM POOLING RULE, DECLARED BEFORE ANY CGM PAPER IS OPENED

**At the owner's instruction, 2026-09-22: take branch D1 and source the 24-hour mean.**
Nothing has been searched for or opened at the time of writing this section.

**THE QUANTITY:** mean interstitial glucose over 24 hours from **continuous glucose
monitoring in healthy, non-diabetic adults**, on their habitual diet and free-living.

### 11.5.1 The rule, in `pooling.md`'s order

1. **`meta-analysis`** if one has pooled normative CGM means.
2. **`pooled-inverse-variance`** — expected; CGM normative papers report mean, SD and n.
3. **`pooled-n-weighted`**, then **`pooled-unweighted`**, then **`single-source`**.

`range-midpoint` is prohibited, and a review's quoted span may not stand in for its
constituent papers.

### 11.5.2 Admissibility, fixed now

**Include:** adults, non-diabetic **by the study's own criterion**, free-living on habitual
diet, **at least 24 h of recording**, with the mean reported. Sensor generation recorded per
source.

**Exclude:** prediabetes cohorts where they are separable, pregnancy, inpatients, athletes
under training load, and any protocol that **standardises the diet** — a fixed research diet
measures a different quantity from habitual intake, and this model's dietary carbohydrate
row is a habitual-intake median from NHANES. **Mixing them would be the §3.26 error in a new
place.**

### 11.5.3 What must be checked, not assumed

**CGM MEASURES INTERSTITIAL FLUID, NOT PLASMA.** The two differ by a lag and by a calibration
convention, and modern sensors are factory-calibrated to report a *plasma-equivalent* value.
**If the pooled sources do not state which they report, that is a scale question and §3.26
applies** — record it on the row rather than assuming equivalence. This is written down
first because it is exactly the kind of thing that gets waved through.

### 11.5.4 What this buys, and the test it creates

`k_glu` is re-derived against the 24-hour mean, and **`GLU.PLASMA.FASTING` = 5.44 mmol/L
becomes a HELD-OUT COMPARISON the model has not been fitted to** — the model's predicted
*fasting* glucose against NHANES's measured one, on a quantity that no longer sets anything.

**THE DIRECTION IS PREDICTED NOW:** the 24-hour mean must come out **above** 5.44, because it
includes postprandial excursions. **If the pooled CGM mean is at or below the fasting value,
something is wrong with one of the two extractions and the pass stops to find out** rather
than adopting the number.

**AND THE MODEL HAS NO MEALS**, so it cannot reproduce the excursions that make the 24-hour
mean exceed the fasting value — it will simply sit at the mean. That is honest for a
24-hour-average model and it is stated on the row, not discovered later.

### 11.6 BRANCH D1 EXECUTED — AND THE PREDICTION IN §11.5.4 WAS WRONG

**§11.5.4 predicted, before searching, that the 24-hour mean would come out ABOVE the
fasting 5.44 mmol/L, and said that if it did not the pass would stop to find out why rather
than adopt the number. It did not. Here is why.**

**Shah VN, DuBose SN, Li Z, Beck RW, Peters AL, Weinstock RS, et al.** *Continuous Glucose
Monitoring Profiles in Healthy Nondiabetic Participants: A Multicenter Prospective Study.*
J Clin Endocrinol Metab 2019;104(10):4356-4364. **PMID 31127824. ABSTRACT READ IN FULL,
2026-09-22.** 153 nonpregnant, nonobese, nondiabetic participants aged 7-80 at 12 T1D
Exchange centres; blinded **Dexcom G6**, once-daily calibration, up to 10 days.

| | |
|---|---|
| mean average glucose | **98-99 mg/dL (5.4-5.5 mmol/L)**, all age groups except >60 y |
| >60 y | 104 mg/dL (5.8 mmol/L) |
| median time 70-140 mg/dL | **96%** (IQR 93-98) |
| median time >140 mg/dL | **2.1%, about 30 min/day** |
| within-individual CV | 17 +/- 3% |

**THE 24-HOUR MEAN AND THE FASTING MEDIAN COINCIDE.** NHANES gives 98 mg/dL fasting
(§9.5); Shah gives 98-99 mg/dL over 24 hours. **THE SAME PAPER EXPLAINS IT:** healthy
nonobese people are between 70 and 140 mg/dL for 96% of the day and above 140 for about
half an hour. **Excursions are small and brief, so they do not lift the mean.** My
prediction assumed postprandial excursions large enough to move a daily average, and in
health they are not.

**Keshet A et al., CGMap, Cell Metab 2023** (abstract read) characterises >7,000
non-diabetic individuals aged 40-70 and is the larger cohort, but **its mean is in neither
the abstract nor the accessible full text**, so it could not be pooled. A secondary summary
reports healthy mean CGM glucose "consistently below 6.2 mmol/L" with within-individual CV
11.6-25.6%; that is consistent and is **not** entered, because a secondary summary is not a
reading.

### 11.6.1 THE CORRIGENDUM WAS CHASED, AND IT IS READ

**JCEM 2022;107(4):e1775, PMID 34888657, doi 10.1210/clinem/dgab837**, correcting the 2019
paper. **PMC is behind a reCAPTCHA and Europe PMC's REST API returned HTTP 500**, so it
could not be opened from here; **the owner supplied the PDF and it has now been READ IN
FULL, 2026-09-22.**

**IT IS A FIGURE-KEY CORRECTION AND NOTHING ELSE.** In its own words: *"The key for Figure
3B incorrectly identified day statistics as night statistics and vice versa"*, and **"The
conclusions of the study are unchanged."** No mean, no time-in-range and no dispersion is
touched, so §11.6's conclusion stands on a paper whose correction has been seen rather than
assumed harmless.

**IT WAS WORTH CHASING EVEN THOUGH IT CHANGED NOTHING.** A corrigendum on the paper a
conclusion rests on is exactly what gets waved through, and "it probably only fixes a
figure" is the assumption that makes waving it through feel safe.

### 11.6.2 THE OUTCOME: NO CGM ROW IS ENTERED, AND THAT IS THE RESULT

**D1's target change is numerically negligible** — 5.44 against 5.4-5.5 is within rounding —
so re-deriving `k_glu` against the 24-hour mean would change nothing the model can resolve,
and **`GLU.PLASMA.FASTING` cannot become a held-out test because the two quantities are the
same number.** The test §11.5.4 hoped to create does not exist.

**A row nothing reads is what directive 1.11 exists to prevent**, so no CGM parameter is
added.

**WHAT IS GAINED IS NOT NOTHING.** §11.3's scale problem — a 24-hour-average balance pinned
to a postabsorptive target — is now **MEASURED to be negligible at the healthy operating
point** instead of assumed away. That licence is explicitly **conditional on health**: in
hyperglycaemia the excursions are neither small nor brief, and the coincidence will not
hold. **The approximation is recorded on `GLU.PLASMA.FASTING` with that condition attached.**

**AND THE NIMGU SCALE OBJECTION IN §11.3 IS CORRESPONDINGLY WEAKENED BUT NOT REMOVED.**
Applying a postabsorptive NIMGU fraction to a 24-hour balance is defensible in health,
because the 24-hour state and the postabsorptive state are the same state to within
rounding. It stops being defensible the moment the model is run hyperglycaemic, and §11.4's
D3 still governs what may be claimed there.

### 11.7 NIMGU EXTRACTION — one direct-method fraction, and a corroboration that may not be pooled

**All abstracts read in full on PubMed, 2026-09-22.**

| source | n | method | NIMGU |
|---|---|---|---|
| **Baron 1985**, J Clin Invest, PMID 2865274 | **11 normal** | somatostatin insulinopenia + [3-3H]glucose, **DIRECT** | **75 +/- 5% of basal Rd**; basal Rd 150 +/- 7 mg/min; NIMGU 113 +/- 8 mg/min |
| Baron 1988, Am J Physiol 255:E769 | 6 lean healthy men | same group, same direct method | NIMGU **128 +/- 6 mg/min** at euglycaemia — **absolute only; basal Rd is not in the abstract, so no fraction** |
| García-Estévez 1998, PMID 9597380 | 16 healthy | **MINIMAL MODEL** | 77 +/- 8% |

### 11.7.1 The pool is ONE study, and §11.2 is why

**García-Estévez is NOT pooled with Baron**, and the reason was fixed before extraction.
§11.2 said methods are not mixed by convenience, and `SOURCES.md` treats a value derived
from another model as `calibrated` with that model named. **The minimal model is a model**;
its glucose-effectiveness estimate and a somatostatin-clamp direct measurement are related
but not the same estimator.

**Baron 1988 cannot supply a fraction** because its abstract gives NIMGU in mg/min without
the basal Rd to divide by. It corroborates the magnitude — 128 mg/min against 1985's 113 —
in a different cohort by the same method.

**SO THE ROW WOULD BE `single-source`, AND `pooling.md` SAYS TO SAY SO RATHER THAN DRESS IT
AS CONSENSUS.** That is the second time this pass has had to; B21 already carries the debt.

**WHAT THE EXCLUSION BUYS IS A CROSS-METHOD CHECK.** 75 +/- 5% by somatostatin clamp against
77 +/- 8% by minimal model, in different cohorts by different estimators, **agree to within
2 percentage points.** That is worth more as corroboration than it would be as a pooled
digit, and it is recorded that way.

### 11.7.2 SE, NOT SD — and §8.4 makes the difference load-bearing

Baron reports **75 +/- 5%** and declares SE elsewhere in the same abstract. **Entering 5 as a
population SD would understate the spread by sqrt(11) = 3.3-fold.** Converted:
**SD = 5 x sqrt(11) = 16.6 percentage points**, so individuals span roughly 58-92%.

**For a population model that is the number that matters**, and it is the difference between
simulated people who all dispose glucose alike and people who do not.

### 11.7.3 What it composes with, checked rather than assumed

Baron's basal Rd of **150 +/- 7 mg/min** is **2.14 mg/kg/min** at 70 kg, against this
ledger's `GLU.EGP.BASAL` of **1.93 mg/kg/min** from Huidekoper by isotope dilution.
**Two different groups, two different decades, two different tracer protocols, 10% apart** —
and neither was chosen with the other in view. The postabsorptive balance the insulin split
will rest on is therefore consistent at its foundation.

---

## 12. THE INSULIN SPLIT — structure fixed before building

**Written 2026-09-22, at the owner's instruction, before any equation is changed.**

### 12.1 The split, and both legs are DERIVED identities

    NIMGU = k_ni * G                     insulin-independent, concentration-driven
    IMGU  = S_I * I * G                  insulin-dependent

At the **postabsorptive** reference, where Baron measured:

    k_ni = f_nimgu * EGP / G_fast
    S_I  = (appear - k_ni * G_fast) / (G_fast * I_fast)

**Every input is already sourced** — `f_nimgu` 0.75 (Baron 1985), `EGP` 1.93 mg/kg/min
(Huidekoper), `G_fast` 5.44 mmol/L and `I_fast` 64.2 pmol/L (NHANES), `appear` = EGP +
dietary carbohydrate (NHANES). **No new free parameter, and §4's identifiability requirement
is discharged without a clamp.**

### 12.2 NIMGU IS SET POSTABSORPTIVELY AND IMGU TAKES THE REMAINDER — this is the one real choice

`f_nimgu` = 75% is measured **postabsorptively**, where appearance is hepatic production
alone. This model's appearance also includes 225 g/day of diet. **The dietary load is
disposed largely by insulin-mediated uptake — that is what a meal insulin response is for —
so the postabsorptive fraction may NOT be applied to the 24-hour total.**

So `k_ni` is pinned by Baron's postabsorptive measurement, and IMGU absorbs the remainder.
**The consequence is arithmetic and is stated now rather than discovered:** NIMGU's share of
24-hour disposal falls to about **35%**, against **75% postabsorptively**. If that number
comes out otherwise, the wiring is wrong.

### 12.3 THE SPLIT IS WORTHLESS WITHOUT A SECRETION RESPONSE, AND THAT IS THE HONEST SCOPE

**With insulin fixed at its fasting value, `IMGU = S_I * I_fast * G` is mass-action in `G` —
algebraically identical to the single lumped clearance already in the model.** Splitting
disposal into two terms that both scale with `G` and nothing else **buys nothing**.

**The split only becomes a mechanism when insulin responds to glucose.** So this pass needs
one more sourced relation: **plasma insulin as a function of plasma glucose in healthy
adults**, `I(G)`.

**IF `I(G)` DOES NOT SOURCE, THE SPLIT IS NOT BUILT** and the pass reports that the two-term
form is unidentifiable from what is available — branch **G2** continues to stand. Building
it anyway would add a term and a row that change no behaviour, which is directive 1.11's
failure with extra steps.

### 12.4 Admissibility for `I(G)`, fixed before searching

**Include:** healthy non-diabetic adults; a **graded or stepped glucose stimulus** —
hyperglycaemic clamp, graded glucose infusion — reporting **steady-state plasma insulin at
stated steady-state plasma glucose**, so both axes are measured on scales that compose.

**Exclude:** first-phase/acute-insulin-response-only reports, which measure a transient this
24-hour-average model cannot express; OGTT-derived indices, which are held out as the test
(§7 test 3); and diabetic cohorts for anything setting a healthy relation.

**POOLING RULE, per `pooling.md`:** meta-analysis if one exists, else
`pooled-inverse-variance`, else n-weighted, else unweighted, else `single-source` **stated as
such**. **The relation is a SLOPE, so if studies report it as a gain or multiplier,
`pooled-geometric` applies** — rule 4, which does not apply to fractions but does apply here.

### 12.5 What may not move

- **`f_nimgu`, `GLU.EGP.BASAL`, `GLU.PLASMA.FASTING`, `GLU.INTAKE.CARBOHYDRATE`, `RN.GLU.TM`.**
- **The healthy operating point.** `k_ni` and `S_I` are derived so that total disposal equals
  appearance at the reference; glucose must still come out at 5.44 mmol/L **exactly**.
- **No band, pin or tolerance widened**, and the thirst and renal rows are untouched.

### 12.6 The falsifiable tests

1. **Operating point unchanged** — glucose 5.44, MAP, sodium, osmolality, urine.
2. **`thirst_on = 0` and the disease knob at 1.0 reproduce the current model**, so the split
   is neutral in health by construction.
3. **NIMGU is about 75% of postabsorptive disposal and about 35% of 24-hour disposal**, both
   reported — §12.2.
4. **Insulin rises with glucose**, reported against the sourced `I(G)`.
5. **The glucose ceiling is recomputed.** A secretion response BUFFERS hyperglycaemia, so the
   ceiling should RISE less steeply with reduced sensitivity than it does now. Reported.
6. **The renal, thirst and salt endpoints are unchanged**, by running the whole harness.
