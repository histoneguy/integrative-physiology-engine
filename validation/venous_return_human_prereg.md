# Pre-registration: a HEALTHY-HUMAN source for the venous return relation

**Date:** 2026-09-03. HANDOVER §4 item 2 and §7. Supersedes nothing —
`venous_compliance_prereg.md` stands as executed, and its finding that the filling
relation is linear over the physiological range is untouched. **What is re-aimed is the
population**: that pass returned dog, pig and rabbit, all anaesthetised, and §7 has since
recorded that no healthy-human source exists in this repo.

**Declared prior exposure.** Two screening sweeps were run before this document, 14
queries, 125 unique records, and the abstracts of five candidates were read. **No value
has been computed and no full text has been opened for extraction.** §4 fixes every rule
so that it does not depend on what those abstracts say.

---

## 1. THE QUANTITY IS NOT A COMPLIANCE, AND THAT IS THE FIRST FINDING

`CV.VENOUS_RETURN.SENSITIVITY` is **`dCO/dV_blood` in (L/day)/L**. It is not a compliance
in mL/mmHg. §3.9 recorded a whole line of work withdrawn for composing a compliance and a
resistance into it while treating right atrial pressure as fixed.

**So the search is for the composite, measured directly**, in a paradigm where blood
volume is manipulated by a known amount and cardiac output is measured. That paradigm
exists in healthy humans — blood withdrawal and plasma volume expansion — and it is
performable, unlike servo-controlled filling pressure.

**A compliance in mL/mmHg is recorded if found and is NOT entered**, because converting it
needs a resistance and a cardiac function curve slope, which is the composition that was
withdrawn.

---

## 2. INCLUSION, FIXED BEFORE EXTRACTION

**Include** only if: healthy normotensive adults; blood volume changed by a **quantified**
amount; cardiac output or stroke volume measured before and after; and the measurement
made at **rest**, or at a stated workload recorded as such.

**Exclude**, and these are the exclusions §5 item 14 exists for: intensive care,
post-cardiac-surgery, anaesthesia, heart failure, cirrhosis, renal failure, anephric
patients, and **any cohort defined by cardiac disease including NYHA class I** — a class I
cardiac patient is not a healthy human, and admitting one would repeat exactly the error
that put a trout and a ganglion-blocked dog into the withdrawn pass.

**Exclude head-out immersion and head-down tilt**, which redistribute at near-constant
total volume. ADR 0010's third addendum, reused not re-argued.

---

## 3. THE DIRECTION SPLIT, FIXED BEFORE THE NUMBERS

**Withdrawal and expansion are recorded separately and are NOT pooled.** The model's
relation is linear and symmetric about the operating point; the physiology may not be, and
pooling the two limbs would hide exactly that. **The model's salt step EXPANDS volume**, so
if the limbs differ, **the expansion limb is the one that governs this parameter** and the
withdrawal limb is recorded as evidence about the FORM.

---

## 4. THE DECISION RULE

- **H1 — the two limbs agree within a factor of 2.** Pool them, enter the value, record the
  range.
- **H2 — the limbs differ by more than 2.** **Enter the EXPANSION limb only**, because that
  is the limb the model's perturbation uses, and record the asymmetry as a structural
  limitation of a linear relation. **Do not average them**; the mean of two limbs describes
  no manoeuvre.
- **H3 — no healthy-human study quantifies both the volume change and the output change.**
  `G_vr` stays 2880 and stays `calibrated`, and §7's gap stands with the search recorded so
  it is not repeated. **This is the branch that must not be avoided** by admitting a
  cardiac-patient cohort or an anaesthetised preparation.

**The value must NOT be chosen to land the salt step in the human window.** §4 item 2 says
refitting 2880 swaps one calibrated constant for another and destroys the only independent
test this line has. **The human salt data are the TEST and may not also be the estimator.**
Where the sourced value lands is reported, not tuned.

**`CV.CENTRAL.CO_SENSITIVITY` moves with it**, being derived as `G_vr / f_c`. They are not
independent and must not be entered as if they were.

---

## 5. WHAT WOULD FALSIFY THE APPROACH

- **If heart rate compensates**, cardiac output falls less than stroke volume and
  `dCO/dV_blood` is smaller than `dSV/dV_blood`. The model's baroreflex has no chronotropic
  arm (ADR 0009), so a study reporting only stroke volume gives an **upper bound** on this
  parameter, and it is recorded as a bound rather than a value.
- **If the response is detectable only at large volume steps**, then the relation has a
  threshold or a plateau near normovolemia and a linear gain through the origin is the
  wrong object.
- **If exercise and resting values differ**, the resting value governs, because the salt
  step is a resting protocol.
