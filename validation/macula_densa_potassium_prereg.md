# Pre-registration — macula densa renin control and potassium

**Written before any source is opened for these values.** Search results have been listed
by TITLE only; no abstract has been read. The one exception is stated in §3 and is
NHANES serum potassium, which was computed as a by-product of the acid–base extraction
before this file existed. Verify ordering with

    git log --diff-filter=A -- validation/macula_densa_potassium_prereg.md
    git log --diff-filter=A -- validation/macula_densa_potassium_extract.py

Structure is decided in **ADR 0021**, which defers every number here.

---

## 1. THE QUANTITIES

| id | what | role |
|---|---|---|
| `RN.NA.PROXIMAL_FRACTION` | fraction of filtered sodium reabsorbed before the distal nephron | makes distal delivery exist |
| `RN.MD.RENIN_GAIN` | fall in renin drive per fractional rise in distal NaCl delivery | the macula densa arm |
| `K.INTAKE.NOMINAL` | dietary potassium, mmol/day | the load |
| `K.PLASMA.REFERENCE` | plasma potassium in healthy adults, mmol/L | **the target of test 2** |
| `K.ECF.FRACTION` | fraction of body potassium that is extracellular | sizes the pool that moves |
| `K.BODY.CONTENT` | total exchangeable body potassium, mmol/kg | with the fraction, the buffer |
| `RN.K.SECRETION_GAIN` | rise in potassium excretion per unit aldosterone | the effector |
| `RN.K.FLOW_GAIN` | rise in potassium excretion per fractional rise in distal flow | why the split matters twice |
| `RAAS.ALDO.K_GAIN` | rise in aldosterone per mmol/L plasma potassium | **the join** |

**`K.PLASMA.REFERENCE` IS NOT AN INPUT.** It is what ADR 0021's falsifiable test 2 judges
the loop against. **If it is used to set any parameter that test is void**, which is what
happened to ADR 0019's test 2 and what §3.29 avoided by naming a scale offset instead of
applying it.

**`RN.MD.RENIN_GAIN` IS AN ESTIMATED PARAMETER AND THE ADR SAYS SO.** It will be solved
against human salt–renin data because no independent human measurement of it could be
found. Those data are therefore an **estimation set** and must never be reported as
agreement. This is written twice on purpose.

---

## 2. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults, normal renal function, ordinary mixed diet, no diuretics, no
potassium or sodium supplements beyond a stated protocol, not pregnant, sea level.
Record n, sex, age, diet, and the sodium intake at which anything renin-related was
measured — **renin without a stated sodium intake is uninterpretable.**

**Exclude:** renal disease, adrenal disease, heart failure, cirrhosis, diabetes,
diuretics, ACE inhibitors and angiotensin receptor blockers, potassium-sparing agents,
beta-blockers, NSAIDs, pregnancy, and intensive care.

**Directive 1.7 will bite here for the SIXTH subsystem.** Renin and aldosterone are
measured overwhelmingly in hypertension and in adrenal disease, where the relationship is
the diagnostic instrument. Potassium handling is measured overwhelmingly in renal failure
and in diuretic therapy. **Prefer balance studies and controlled-diet protocols in
healthy volunteers**, which is where this physiology was established and where the
preparation is the subject.

**AND OTHER WHOLE-BODY MODELS ARE NOT SOURCES.**

---

## 3. WHAT IS ALREADY KNOWN, STATED SO THE FREEDOM IS AUDITABLE

**NHANES serum potassium was computed on 2026-09-05 as a by-product of the acid–base
extraction, before this file existed: 3.97 mmol/L, SD 0.32, in 8809 adults.** No other
number in §1 has been looked at, and no relationship of any kind has been computed.

**That value is a TARGET and §1 forbids using it to set a parameter.** Recording that it
is already known is the point — a target seen early is a target that can be reached
without noticing.

---

## 4. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED IN ADVANCE

Plasma potassium 4.0 mmol/L. Dietary potassium 100 mmol/day. Total body potassium 50
mmol/kg. Extracellular fraction 2%. Proximal reabsorption 65%, loop 25%, distal delivery
10%. **All six are teaching numbers.** This repository's record on such numbers is six of
eight wrong in the blood-gas pass, four of six in the `VERIFY` class, and the
metabolic-equivalent convention. None is entered as `reported` without a source, and
where the measured value turns out to be the round one the source is what makes it
enterable.

---

## 5. THE FORM

**The split, fixed here and required to be neutral:**

    distal_delivery = Na_filtered * (1 - FR_prox_effective)
    FR_effective    = FR_prox_effective + (1 - FR_prox_effective) * FR_dist_effective

with the distal increment defined so that `FR_effective` reproduces the current lumped
expression **identically**. Pressure natriuresis and the natriuretic peptide term enter
`FR_prox`; the RAAS tubular increment enters `FR_dist`.

**The macula densa arm** is written on the FRACTIONAL deviation of distal delivery from
its reference, so the gain is dimensionless and does not inherit a body-size scaling —
the mistake §3.30 records making with `G_anp`, avoided here by construction rather than
by care.

**Potassium balance** is a one-compartment conservation law on extracellular content,
with the intracellular pool entering only as a buffer term. **The functional form of
renal potassium secretion is NOT fixed here** — whether it is linear in aldosterone,
saturating, or multiplicative in flow is what the literature has to decide. It must be a
published form with a citation.

---

## 6. THE DECISION RULE

- **P1 — every gain sources and plasma potassium lands in the human range.** Build,
  connect, run all five of ADR 0021's tests, ADR 0021 to Accepted.
- **P2 — plasma potassium lands outside it.** **Report it, do not tune.** Decompose:
  intake, the secretion relation, the extracellular fraction and extracellular volume are
  four separable stages. **And check the SCALES first** — §3.26 and §3.29 both turned on
  two inputs that were not commensurable, and a decomposition run inside a wrong model is
  confident and useless.
- **P3 — the aldosterone-potassium gain cannot be sourced.** Then the two halves are NOT
  joined: potassium is built with aldosterone as a one-way input, the join ADR 0021
  exists for is not made, and **that must be said in the record rather than left for a
  reader to notice.**
- **P4 — the potassium secretion relation cannot be sourced.** Potassium is NOT built.
  A balance whose only outflow is invented is a balance in which the intake does all the
  work, which is branch A4 of the acid–base pre-registration and the reason that
  component has no state.
- **P5 — the macula densa gain has no independent measurement.** Expected. Estimate it
  against human salt–renin data, **relabel those data an estimation set in
  `validation/targets.md` and in the extract**, and report the salt–renin agreement as a
  fit. The test that survives is that the form can exceed the pressure-only ceiling.

---

## 7. WHAT THE ANSWER MAY NOT DO

- **The split must be exactly neutral.** With both new arms disabled, every existing
  result **bit-identical**, not close. If a pinned number moves, decision 1 has done
  something it claims not to.
- It may not re-estimate `RN.PRESSURE_NATRIURESIS.SLOPE`, `CV.ANP.NATRIURETIC_GAIN` or
  the RAAS tubular gain.
- It may not add more than one state.
- It may not use `K.PLASMA.REFERENCE` to set a parameter.
- It may not add any potassium effect other than on aldosterone.
- **It may not report the salt–renin comparison as a validation.** Ever.
- It may not put potassium into plasma osmolality, where the non-sodium residual already
  counts it — the double-count §3.8 records for red cell volume and ADR 0020 avoided for
  bicarbonate.

---

## 8. WHY TEST 2 IS REAL AND TEST 1 IS NOT

**Test 1 is a fit and is declared one.** The macula densa gain is solved against the
salt–renin data; reproducing them afterwards is arithmetic.

**Test 2 is a genuine prediction.** Plasma potassium is intake divided by a clearance
relation, over an extracellular volume the model already computes — three sourced
quantities and none of them is a potassium concentration. They compose in the plain sense
that §3.29 required and §3.26 lacked: a millimole of potassium means the same thing in
every laboratory, and the extracellular volume is the model's own.

**So the model can be wrong about plasma potassium**, and being able to be wrong is the
difference between a prediction and a restatement.

---

## 9. AMENDMENT, 2026-09-05: THE BRANCH §6 DID NOT HAVE

**Branch P4 said: if the potassium secretion relation cannot be sourced, potassium is not
built.** The case that actually arose was one this document did not anticipate: **the
relation's SHAPE is sourced and its LEVEL is not.**

Excretion rising with filtration and with plasma concentration is E1. What could not be
sourced is the fractional excretion that fixes where the balance rests — searches return
ketoacidosis, chronic kidney disease, diuretics, transplantation and Gitelman syndrome,
directive 1.7 disqualifying a sixth literature exactly as §2 predicted.

**Branch taken: build it, derive the level against the measured plasma potassium, and
void falsifiable test 2 in the record.** §1's prohibition on using `K.PLASMA.REFERENCE` to
set a parameter is therefore BROKEN, deliberately and in the open, which is the only
honest way to enter that row. What remains a prediction is the RESPONSE.

**And §5's form was refuted by the suite before the first commit.** Written linear in
plasma potassium, the model predicted 7.6 mmol/L from a doubled ordinary diet. §5 said the
functional form was deliberately not fixed here because choosing a shape and then finding
a citation is the error ADR 0017's amendment records — and the shape that was chosen
turned out to be wrong in a way only a run could show. The exponent that replaced it is
fitted to Brunner's measured intake–concentration response, and it lumps aldosterone,
distal flow and plasma potassium because no human study separates them.

**Branch P3 fired in the direction not expected.** It anticipated the potassium →
aldosterone gain failing; that one sourced. What failed was the return arm, aldosterone →
excretion, and it is now inside the exponent rather than absent.

---

## 10. AMENDMENT, 2026-09-05: §7's FIRST CLAUSE HELD AND ITS SECOND ONE BIT

§7 said the split must be exactly neutral with both arms disabled, and it is — the split
is observational, so neutrality is guaranteed rather than checked.

**§7 also said the answer may not re-estimate `CV.ANP.NATRIURETIC_GAIN` or
`RN.PRESSURE_NATRIURESIS.SLOPE`, and the first implementation broke that clause without
changing either number.** It put both terms into distal sodium delivery, which gave each
gain a second route to sodium excretion through renin and aldosterone. A parameter whose
effect has doubled has been re-estimated in every sense that matters, whatever its value
still says.

**The acute saline challenge is what found it**, at 877 mL against Lobo's 563. Both terms
are removed; distal delivery is the filtered load less proximal reabsorption, which still
carries 41% of the chronic signal because GFR rises with volume; `RN.MD.RENIN_GAIN`
re-solved against the same estimation set to 5.396.

**Two Lobo endpoints still fail by 2.8% and 1.7%, and they are reported, not tuned** —
branch P2's rule applied to a quantity P2 was not written about. ADR 0021 amendment A6
carries the sweep that turns the failure into a bound on the arm.
