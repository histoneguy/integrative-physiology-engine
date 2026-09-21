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
