# Pre-registration — acid–base parameters

**Written before any source is opened for these values.** Search results have been listed
by TITLE only; no abstract has been read. Verify ordering with

    git log --diff-filter=A -- validation/acid_base_prereg.md
    git log --diff-filter=A -- validation/acid_base_extract.py

Structure is decided in **ADR 0020**, which defers every number here.

---

## 1. THE QUANTITIES

| id | what | role |
|---|---|---|
| `AB.PK_APPARENT` | apparent pK′ of the CO2/bicarbonate pair in plasma at 37 °C | positions Henderson–Hasselbalch |
| `AB.CO2.SOLUBILITY` | plasma CO2 solubility, mmol/L/mmHg | the denominator of the same ratio |
| `AB.HCO3.ARTERIAL` | arterial bicarbonate in healthy adults, mmol/L | the target of falsifiable test 1 |
| `AB.PH.ARTERIAL` | arterial pH in healthy adults | the other half of the same test |
| `AB.ACID.PRODUCTION` | net endogenous acid production, mEq/kg/day | the load the kidney must clear |
| `AB.NAE.SLOPE` | rise in renal net acid excretion per mmol/L fall in plasma bicarbonate | the renal gain |
| `AB.HCO3.VOLUME` | distribution volume of bicarbonate | converts a flux to a concentration change |
| `AB.HCO3.TAU` | if the renal arm is written as a lag rather than a gain | the timescale |

**`AB.HCO3.ARTERIAL` AND `AB.PH.ARTERIAL` ARE NOT INPUTS.** They are what ADR 0020's
falsifiable test 1 judges the loop against. **If either is used to set a parameter that
test is void**, which is what happened to ADR 0019's test 2 and is written down here so
it cannot happen twice for the same reason.

---

## 2. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults, resting, sea level, awake, eating an ordinary mixed diet,
normal renal function by the source's own account. Record n, sex, age, diet and sampling
site — **arterial, arterialised-capillary and venous blood are not interchangeable** and
venous bicarbonate runs 1–2 mmol/L higher.

**Exclude:** renal disease, respiratory disease, diabetes, diuretics, any alkali or acid
supplement, vegetarian or ketogenic diets where the source identifies them separately,
pregnancy, altitude residence, acute illness, and intensive care.

**Directive 1.7's form here, and it will bite hard.** Almost the whole acid–base
literature exists to manage a DISORDER — diabetic ketoacidosis, renal failure, sepsis,
ventilated patients. In those the relationship is the instrument and the preparation is
the disease. This is the fifth subsystem in which that is expected; it is written down in
advance so the search is not mistaken for an absence of evidence.

**AND OTHER WHOLE-BODY MODELS ARE NOT SOURCES.** A published equation fitted to measured
data is admissible with its citation; a value traceable only to a simulation is not.

---

## 3. DIRECTIVE 1.12 — THE ROUND NUMBERS ARE LISTED IN ADVANCE

pH 7.40. Bicarbonate 24 mmol/L. pK′ 6.1. Solubility 0.03. Net acid production 1
mEq/kg/day. PCO2 40. **Every one of these is a teaching number and this repository's
record is that most such numbers are wrong when checked** — six of eight in the blood-gas
pass, four of six in the `VERIFY` class, and the metabolic-equivalent convention two
records ago.

**No round number is entered as `reported`.** Where the measured value turns out to be
the round one, the SOURCE is what makes it enterable, not the roundness.

**`AB.PK_APPARENT` IS THE ONE TO WATCH.** 6.1 is a rounding of a quantity that is
genuinely constant to about ±0.01 in normal plasma but varies with temperature, ionic
strength and protein concentration, and several groups have argued the fixed value is a
source of error in exactly the states this model does not represent. **The value and its
conditions must both be recorded**, and the conditions are 37 °C and normal plasma.

---

## 4. THE FORM, FIXED HERE

**Henderson–Hasselbalch**, taken whole with its citation:

    pH = pK' + log10( [HCO3-] / (S * PCO2) )

**The bicarbonate balance is a one-compartment conservation law:**

    d[HCO3-]/dt = ( NAE - acid_production ) / V_dist

with net acid excretion rising as bicarbonate falls. **The renal arm's functional form is
NOT fixed here**, because the choice between a linear response, a threshold-plus-slope
and a saturating one is exactly what the literature has to decide — see §5's branch A3.
What IS fixed is that it must be a published form with a citation, not one chosen here
and justified afterwards, which is the discipline ADR 0017's amendment records learning
the hard way.

---

## 5. THE DECISION RULE

- **A1 — the loop rests inside the human reference ranges for both pH and bicarbonate.**
  Build, connect, run ADR 0020's five falsifiable tests, ADR 0020 to Accepted.
- **A2 — it rests outside one or both.** **Report it. Do not tune.** Then decompose: acid
  production, the renal gain, the distribution volume and PCO2 are four separable stages
  and the extract must say which carries the discrepancy. **And check the SCALES first** —
  §3.26's lesson is that a composed quantity can be wrong because two of its inputs are
  not commensurable, and a decomposition run inside a wrong model is confident and
  useless.
- **A3 — the renal response cannot be sourced as a published form with a gain.** Then the
  arm is a first-order relaxation of bicarbonate toward a sourced set-point with a sourced
  time constant, the weaker structure is recorded as such, and **falsifiable test 2 is
  reported as a restatement rather than a prediction** — because a relaxation toward a
  set-point reproduces that set-point by construction.
- **A4 — net endogenous acid production cannot be sourced in an ordinary mixed diet.**
  The component is NOT built. A bicarbonate balance whose input flux is invented is a
  fitted balance, and the set-point would then be doing all the work.

---

## 6. WHAT THE ANSWER MAY NOT DO

- It may not change any existing parameter, equation, or the value of any pressure,
  volume, sodium or gas quantity. **With the component disabled every existing result
  must be BIT-IDENTICAL**, not close.
- It may not add more than one state.
- **It may not add a pH term to the chemoreflex.** ADR 0020 decision 3 forbids it, and
  the reason is that it would make the respiratory operating point an output again.
- **It may not put bicarbonate into plasma osmolality**, where it is already implicitly
  counted in the non-sodium residual.
- It may not use either reference range in §1 to set a parameter.
- **It may not report agreement to more significant figures than the sources carry.** pH
  is a logarithm: 0.01 in pH is 2.3% in the hydrogen ion concentration, and quoting three
  decimal places would be claiming a precision no blood gas analyser has.

---

## 7. WHY THIS IS A REAL TEST AND ADR 0019'S WAS NOT

ADR 0019's second falsifiable test was void because a slope in `1/(pmol/L)` and a
concentration in `pmol/L` were on two different free-thyroxine assay scales, so their
composition was a unit error dressed as a prediction (§3.26).

**Nothing here has that problem.** Bicarbonate is a millimole per litre measured by
titration or by calculation from measured pH and PCO2, and it means the same thing in
every laboratory. Acid production is a milliequivalent per day. The distribution volume
is a volume. **They compose, so the resting point can be genuinely wrong**, and being
able to be wrong is the whole difference between a prediction and a restatement.

**The one place a scale error could still hide** is between an acid production measured
as urinary net acid excretion and a bicarbonate space measured by isotope dilution. The
extract must state the method behind each.
