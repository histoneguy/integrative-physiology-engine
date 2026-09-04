# Pre-registration — blood oxygen transport parameters

**Written before any source is opened for these values.** Verify ordering with

    git log --diff-filter=A -- validation/blood_gas_prereg.md
    git log --diff-filter=A -- validation/blood_gas_extract.py

Structure is decided in **ADR 0018**, which defers every number here.

---

## 1. THE QUANTITIES

| id | what | role |
|---|---|---|
| `BLOOD.HB.CONCENTRATION` | arterial haemoglobin, g/L, **sexed** | sets carrying capacity |
| `BLOOD.O2.BINDING_CAPACITY` | mL O2 per g of haemoglobin | converts haemoglobin to content |
| `BLOOD.O2.P50` | PO2 at 50% saturation, mmHg | positions the dissociation curve |
| `BLOOD.O2.HILL_N` | Hill exponent | sets its steepness |
| `BLOOD.O2.SOLUBILITY` | dissolved O2, mL/dL/mmHg | the small additive term |
| `RESP.O2.INSPIRED_FRACTION` | fraction of O2 in dry air | sets inspired PO2 |
| `RESP.EXCHANGE_RATIO` | respiratory exchange ratio | couples alveolar O2 to alveolar CO2 |
| `BLOOD.O2.AA_GRADIENT` | alveolar-arterial PO2 difference, mmHg | alveolar to arterial |

---

## 2. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults, resting, sea level, awake, breathing air, normal
haemoglobin by the source's own account. Record n, sex composition, age, altitude and
method for every source.

**Exclude:** anaemia, polycythaemia, haemoglobinopathy, smoking (carboxyhaemoglobin is
raised and the model has none), respiratory or cardiac disease, altitude residence,
stored or banked blood, pregnancy, mechanical ventilation, anaesthesia, and exercise.

**Directive 1.7 in the form it takes here.** Much of the oxygen-transport literature
exists to characterise a **pulse oximeter**, a blood gas analyser, or a transfusion
threshold. In all of those the relationship is the instrument and not the subject.
Prefer sources whose purpose was to describe the physiology.

**AND OTHER WHOLE-BODY MODELS ARE NOT SOURCES**, for structure or for values. A
published *equation fitted to measured data* is a different object and IS admissible
with its citation. Where a value can only be traced to a simulation, it is not used.

---

## 3. DIRECTIVE 1.12 WILL BITE, AND THE LIST IS WRITTEN OUT IN ADVANCE

Every one of these is a round teaching number until a source is opened: haemoglobin 15
g/dL, binding capacity 1.34 mL/g, P50 26.6 mmHg, Hill n 2.7, saturation 97%, arterial
PO2 100 mmHg, exchange ratio 0.8, an A-a difference of 10. **The record in this ledger
is six of eight such values materially wrong when checked.**

**No round number is entered as `reported`.** Unsourceable values enter `assumed` with
the search recorded.

**THE BINDING CAPACITY IS THE ONE TO WATCH.** The theoretical figure from haemoglobin's
molecular weight and four binding sites is 1.39 mL/g, while measured whole-blood values
cluster nearer 1.34, and the difference is usually attributed to inactive haemoglobin
species that this model does not represent. **Both must be recorded and the choice
justified on the row, not silently taken.**

---

## 4. THE FORM OF THE DISSOCIATION CURVE

**Decided in advance: a published closed-form relation, cited, applicable to human
blood at normal pH and temperature.** Two admissible kinds:

1. **The Hill equation**, `S = P^n / (P50^n + P^n)`, with `n` and `P50` sourced.
2. **A published empirical fit** to measured human data, taken whole with its citation.

**Preference, fixed here: the Hill form**, for two reasons that are about this model
rather than about accuracy. It carries exactly two parameters that are separately
measurable and separately reportable, so each gets its own ledger row and its own
provenance. And it is invertible in closed form, which ADR 0018 decision 2 needs.

**A more accurate fit that cannot be decomposed into sourced parameters is REJECTED
even if it fits better**, because a single opaque constant with no independent
measurement behind it is the thing this ledger exists to prevent. That is a deliberate
trade of accuracy for provenance and it is recorded as such.

---

## 5. THE DECISION RULE

Let the sourced values be entered and the model compute arterial saturation.

- **B1 — saturation lands in the human reference range (roughly 95–99% at sea level).**
  Build, connect, and run ADR 0018's four falsifiable tests. **This is a genuine
  prediction**: every input is sourced independently of the output, unlike ADR 0017's
  resting PCO2 which is an input.
- **B2 — saturation lands outside it.** **Report it. Do not tune.** Then decompose:
  the alveolar gas equation, the A-a difference and the curve are three separable
  stages and the extract must say which one carries the discrepancy.
- **B3 — the curve cannot be sourced as two independent parameters.** Fall back to §4's
  second kind, a published fit taken whole, and record that the decomposition failed.
- **B4 — haemoglobin cannot be sourced as a sexed pair.** Enter `both` under ADR 0014's
  "where only one value is supported, use it for both" branch, and record it as the
  `CV.HEMATOCRIT.NOMINAL` failure waiting to happen — that row was a male value applied
  to women until it was sourced as a pair.

---

## 6. WHAT THE ANSWER MAY NOT DO

- It may not change any existing parameter, equation, or the value of any pressure,
  volume or sodium quantity. **Oxygen is a forward computation** (ADR 0018 decision 1).
- It may not add a state.
- It may not introduce an oxygen feedback of any kind.
- **It may not tune the A-a difference to make saturation come out right.** That row is
  the obvious free parameter here — it is the least precisely known of the three stages
  and it sits directly upstream of the output being judged. Sourcing it independently
  is what makes falsifiable test 1 a real test rather than a restatement.

---

## 7. WHY THIS ONE IS A REAL TEST AND ADR 0017'S WAS NOT

Resting arterial PCO2 became an INPUT under ADR 0017's amendment, because the
chemoreflex is not the operative control at rest, so the model makes no claim to
predict it.

**Arterial saturation is different.** Haemoglobin, the binding capacity, the curve, the
exchange ratio and the A-a difference are all measured independently of saturation, and
saturation follows from them by arithmetic. **So the model can be WRONG about it**, and
being able to be wrong is the whole difference between a prediction and a restatement.
That is why §6 forbids tuning the one row that could rescue it.
