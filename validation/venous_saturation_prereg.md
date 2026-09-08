# Pre-registration — mixed venous saturation and the oxygen extraction ratio

**Written 2026-09-08, before any source is opened and before any search has been run for
these values.** Verify the ordering with

    git log --diff-filter=A -- validation/venous_saturation_prereg.md
    git log --diff-filter=A -- validation/venous_saturation_extract.py

Approved by the owner as the resolution of `OPEN-QUESTIONS.md` **B8**, which this file
also exists to correct.

---

## 0. WHY THIS PASS EXISTS, AND WHAT B8 GOT WRONG

**B8 said the model's cardiac output is 25% higher than the Fick relation allows.** The
arithmetic is right and the framing was not.

The model's oxygen extraction ratio, **0.183**, and its mixed venous saturation, **0.801**,
are a **PREDICTION**. Three independently sourced rows compose to make them: oxygen
consumption (Weir's equation on a 197-study meta-analysis), arterial oxygen content (a
sourced dissociation curve and haemoglobin), and cardiac output (heart rate times a tier-A
cardiac-magnetic-resonance stroke volume). Nothing was fitted.

**B8 judged that prediction against 0.23, and 0.23 IS IN NO LEDGER ROW, NO TARGET FILE AND
NO CLOSURE CHECK IN THIS REPOSITORY.** It is a teaching number. Directive 1.12 lists
exactly that class, and this repository's record on such numbers is four wrong in six in
the blood-gas pass. **B8 asserted a sourced prediction was wrong because it disagreed with
an unsourced convention**, which is the inverse of how this model is meant to work.

**B8 also asserted that "CMR is known to read stroke volume higher" without a citation.**
That claim is §5 of this file's second quantity and is not assumed here.

**So this pass can exonerate the model, not only convict it**, and that possibility is
written down before the search so that finding it cannot look like a rescue.

---

## 1. THE QUANTITIES

| id | what | role |
|---|---|---|
| `BL.SVO2.NOMINAL` | mixed venous oxygen saturation in healthy resting adults | **the target of the test** |
| `BL.ER.NOMINAL` | whole-body oxygen extraction ratio at rest | the same statement, dimensionless |
| — | the bias between CMR and thermodilution/Fick stroke volume | decides whether B8's mechanism is real |

**THE FIRST TWO ARE TARGETS AND MAY NOT SET A PARAMETER.** The model already predicts
both. If either is used to set `CV.SV.NOMINAL`, `RESP.METABOLIC_RATE` or anything in
`Blood.jl`, the comparison is destroyed and the pass has produced a restatement — which is
what happened to ADR 0019's falsifiable test 2 and what §3.29 avoided by naming an offset
rather than applying it.

**The extraction ratio is the preferred form** because it is dimensionless and therefore
transferable between cohorts, haemoglobin concentrations and assays — the property §3.26
established the hard way. A saturation is comparable only where haemoglobin is stated.

---

## 2. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults; **resting**, supine or seated, awake, sea level; measurement
of **true mixed venous blood from the pulmonary artery**; the method of cardiac-output
measurement **stated**; haemoglobin or arterial oxygen content reported, or derivable.
Record n, sex, age, posture, and the cardiac-output method — **a saturation without the
method that produced its cardiac output cannot be composed with anything.**

**Exclude:** critical illness, sepsis, shock, anaesthesia, cardiac surgery and the
perioperative period, heart failure, pulmonary hypertension, congenital heart disease,
anaemia, exercise, and altitude.

**CENTRAL VENOUS SATURATION IS NOT MIXED VENOUS SATURATION AND MAY NOT BE SUBSTITUTED.**
`ScvO2` is drawn from the superior vena cava, misses the lower-body and coronary returns,
and runs systematically different from `SvO2` — the difference is itself a literature. A
row entered from `ScvO2` would be a different quantity wearing the right name, which is
the error §3.26 records for free thyroxine assays.

**DIRECTIVE 1.7 WILL BITE HERE AND IT IS PREDICTED IN ADVANCE, FOR THE SEVENTH SUBSYSTEM.**
Mixed venous saturation requires a **pulmonary artery catheter**, and healthy volunteers
are not routinely catheterised. The literature is therefore overwhelmingly intensive care,
cardiac surgery and heart failure, where the measurement exists **because the patient is
ill** — the preparation is the instrument. **The admissible sources, if any, will be small
physiological studies and control arms**, and they are what to search for.

**AND OTHER WHOLE-BODY MODELS ARE NOT SOURCES.**

---

## 3. WHAT IS ALREADY KNOWN, DECLARED SO THE FREEDOM IS AUDITABLE

**The model predicts SvO2 = 0.8014 and ER = 0.1834**, from VO2 = 228.0 mL/min and
CaO2 = 20.887 mL/dL at a cardiac output of 5.951 L/min. Those numbers are in this
conversation and in `OPEN-QUESTIONS.md` B8 and cannot be unseen.

**A target already known is a target that can be reached without noticing**, and here the
risk runs in the unusual direction: the model's own value is the one I have looked at, so
the temptation is to accept a source that flatters **0.183** and to find reasons against
one that does not. §6's branches are written to remove that discretion.

**The bench measurement of what a "fix" would cost is also already known** and is recorded
in `OPEN-QUESTIONS.md` B8: scaling stroke volume to 76.6 mL preserves arterial pressure
exactly and leaves both validated cardiovascular targets inside their bands. **That the fix
is nearly free is a reason for suspicion, not for confidence**, and it is declared here so
that it cannot be presented later as evidence for making it.

---

## 4. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED IN ADVANCE

Mixed venous saturation **75%**. Oxygen extraction **25%**. Arteriovenous oxygen difference
**5 mL/dL**. Oxygen consumption **250 mL/min**. Cardiac output **5 L/min**. Oxygen delivery
**1000 mL/min**. **All six are teaching numbers**, they compose into each other, and B8
quoted the first two as though they were measurements. None is enterable without a source,
and where a measured value turns out to be the round one, the source is what makes it
enterable.

---

## 5. THE SECOND QUANTITY: DOES B8'S MECHANISM EXIST?

B8 blamed a method mismatch — cardiac magnetic resonance reading stroke volume higher than
thermodilution or Fick — and cited nothing. **This pass either finds that comparison or
records that the claim was unsupported.**

**Admissible:** studies measuring stroke volume or cardiac output by CMR **and** by
thermodilution, direct Fick or another reference method **in the same subjects**. Healthy
subjects preferred; a cardiac cohort is admissible for the *bias between methods*, because
the bias is the quantity and the disease is not the instrument for it.

**If the bias is found and is small**, B8's mechanism is refuted and the model's cardiac
output stands. **If it is found and is large**, composing a CMR cardiac output with a
thermodilution-era saturation is illegitimate and B8 becomes a real finding about method,
not about physiology.

---

## 6. THE DECISION RULE

- **V1 — an admissible resting healthy extraction ratio or mixed venous saturation is
  found, and the model's 0.183 falls inside its reported spread.** B8 **closes as no
  defect**, the row is entered as a **validation target**, and the model has made a
  successful three-source prediction — which must be reported as neither more nor less
  than that.
- **V2 — found, and the model falls outside.** **B8 is a real defect.** Decompose across
  the three sourced inputs — oxygen consumption, arterial content, cardiac output — and
  **check method-matching first**, because §3.26 and §3.29 both turned on inputs that were
  not commensurable. **Do not tune inside this pass.**
- **V3 — only found in inadmissible populations** (intensive care, cardiac surgery, heart
  failure). **B8 closes as INDETERMINATE, not as resolved**, exactly as the
  fluid-deprivation comparison did, and the model's prediction stands unjudged. Record the
  exact search terms used, because §3.33 is what happens when a failed search is written up
  as a fact about the literature.
- **V4 — a cohort reports cardiac output AND oxygen consumption in the same healthy
  subjects.** Best case. The extraction ratio is then internal to one study and one method,
  and it is the primary comparison whatever else is found.
- **V5 — the CMR-versus-reference-method bias is found.** Record it whichever way it falls,
  and correct B8's uncited assertion in either direction.

---

## 7. WHAT THE ANSWER MAY NOT DO

- **It may not change `CV.SV.NOMINAL`.** Not under any branch. That row is a tier-A
  measurement in a large cohort; moving it is its own pre-registered pass with its own
  evidence, and one change at a time is how this repository stays testable. **V2 makes the
  case for that pass; it does not authorise it.**
- It may not change `RESP.METABOLIC_RATE`, `RESP.O2.CONSUMPTION`, or the dissociation
  curve.
- It may not enter `ScvO2` as `SvO2`.
- It may not enter a value from an abstract where the full text is obtainable, and must
  label the reading level of every source.
- **It may not report a successful prediction as a validation of cardiac output.** If V1
  fires, what is validated is the *composition* of three rows, and the extraction ratio is
  insensitive to compensating errors in them — 0.183 would also be reproduced by a cardiac
  output too high and an oxygen consumption too high in the same proportion.
- It may not quote agreement to more figures than the source's own dispersion supports.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Finding a number, entering it, and leaving B8 saying what it says now.** B8 currently
contains two unsourced assertions — the 0.23 target and the CMR bias — and this pass must
correct both **whatever it finds about the physiology**. If it resolves the extraction
ratio and leaves the uncited method claim standing, it has fixed the smaller error and
preserved the larger one.
