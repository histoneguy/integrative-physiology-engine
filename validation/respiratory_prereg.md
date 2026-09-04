# Pre-registration — respiratory parameters

**Written before any source is opened for these values.** Verify the ordering with

    git log --diff-filter=A -- validation/respiratory_prereg.md
    git log --diff-filter=A -- validation/respiratory_extract.py

No SHA is cited, per HANDOVER §5 item 12.

Structure is decided in **ADR 0017**, which commits to the topology and defers every
number here. This document fixes what will be extracted, from what, and what happens
in each outcome.

---

## 1. THE QUANTITIES, AND WHY EACH IS NEEDED

| id | what | why the component cannot proceed without it |
|---|---|---|
| `RESP.CO2.PRODUCTION` | resting CO2 production, L/min STPD | the load the loop balances |
| `RESP.CHEMO.CO2_SLOPE` | ventilatory response to arterial PCO2, L/min/mmHg | the gain of the control loop |
| `RESP.CHEMO.CO2_THRESHOLD` | x-intercept of that response, mmHg | without it the response has no operating point |
| `RESP.ALVEOLAR.K` | constant in `PaCO2 = K·VCO2/V_A` | converts the mass balance to mmHg |
| `RESP.H2O.GAS_CONTENT` | water carried per litre of expired gas, net of inspired | turns ventilation into a water flux |
| `RESP.DEADSPACE.FRACTION` | dead space over tidal volume | relates alveolar to minute ventilation |

**`RESP.ALVEOLAR.K` is expected to be DERIVED, not searched.** It follows from the
STPD-to-BTPS correction and barometric pressure and is arithmetic, not a measurement.
**If the derivation cannot be written down, the row is `assumed` and says so** — the
`RN.NA.FRACTIONAL_REABSORPTION` precedent, where a derived value needed its derivation
recorded rather than a citation.

---

## 2. SOURCE ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults, resting, sea level, spontaneous breathing, awake, normal
arterial gases by the source's own account. Sex composition, age, n and posture
recorded for every source.

**Exclude, and these follow ADR 0017's disqualification section rather than being
invented here:** mechanical ventilation, anaesthesia, sedation, sleep, altitude or
hypoxic exposure, exercise, respiratory or cardiac disease, obesity hypoventilation,
pregnancy, and **any protocol whose perturbed variable is within-breath.** A model with
no breath must not be calibrated against how the breath is divided.

**Two specific traps, named in advance.**

1. **Rebreathing and steady-state CO2 response are DIFFERENT INSTRUMENTS** and
   `pooling.md` prohibits pooling across incompatible methods. Read's rebreathing
   method and steady-state inhaled-CO2 methods give systematically different slopes.
   **Record them separately. Do not pool them.** If both are available, the
   steady-state figure is preferred, because this model is quasi-static by ADR 0017
   and a rebreathing transient is the wrong instrument for it.
2. **Directive 1.7 applies with force here.** Much of the CO2-response literature
   exists to characterise a DRUG, a disease, or a safety margin, and there the
   relationship is the instrument rather than the subject. Ask of every candidate:
   was this preparation designed to show normal control, or to break it? **Prefer
   normative studies in healthy volunteers whose purpose was to describe the
   relationship.**

---

## 3. DIRECTIVE 1.12 APPLIES AND IS EXPECTED TO BITE

Respiratory physiology is dense with round teaching numbers: arterial PCO2 of 40, a
production of 200 mL/min, a dead-space fraction of 0.3, a minute ventilation of 6
L/min, 500 mL tidal volume at 12 breaths. **Every one of those is presumptively a
teaching aid until a source is opened**, and the record here is that six of eight such
values elsewhere in this ledger were materially wrong when checked.

**Fixed in advance: no round number is entered as `reported`.** Where a value cannot be
sourced it enters `assumed` with the attempt recorded, and the `assumed` count going up
is the honest outcome.

**And 40 mmHg is the one to watch.** It is the number the model must produce as an
OUTPUT. If a parameter is chosen to make PCO2 come out at 40, the loop has been
calibrated to its own target and ADR 0017's falsifiable test is void. **No parameter may
be set, adjusted or preferred because it puts PCO2 near 40.**

---

## 4. POOLING

`pooling.md` applies unchanged. Preference order is its own: meta-analysis, then
inverse-variance, then n-weighted, then geometric for ratios, then unweighted, then
single-source. `range-midpoint` is prohibited. Method splits from §2 are respected.

**The chemoreflex slope is expected to be wide and that is not a defect.** The
ventilatory response to CO2 varies several-fold between healthy people and is
reproducible within a person, the same shape as the vasopressin sensitivity already
recorded in HANDOVER §7. **Record the dispersion. Do not narrow it by selection.**

---

## 5. THE DECISION RULE

Let the sourced production, slope and threshold be entered, and let the model solve
its closed form for resting PaCO2.

- **P1 — resting PaCO2 lands inside the human reference interval.** The component is
  built and connected, ADR 0017 moves to Accepted, and the falsifiable test's first
  and second conditions are run.
- **P2 — PaCO2 lands OUTSIDE the human interval.** **This is the interesting branch and
  it must not be escaped by tuning.** The component is built anyway, the discrepancy is
  reported as the headline, and the cause is investigated as a structural question. It
  would mean the three sourced numbers are jointly inconsistent with the quasi-static
  closed form, which is a real finding about the structure. **ADR 0017 stays Proposed.**
- **P3 — the chemoreflex slope cannot be sourced in an admissible preparation.** The
  component is NOT built. A control loop whose gain is unsourced is a fitted loop, and
  fitting it against resting PaCO2 is exactly the circularity that made
  `RN.PRESSURE_NATRIURESIS.SLOPE` a hypertensive value.
- **P4 — production or threshold unsourceable but slope available.** Enter what is
  sourced, mark the rest `assumed`, build, and record which of the two the operating
  point actually turns on by sweeping each.

---

## 6. WHAT THE ANSWER MAY NOT DO

- It may not touch any sodium equation or any cardiovascular parameter.
- It may not change `BF.H2O.INSENSIBLE_LOSS`'s VALUE. The respiratory term must
  reproduce the existing total at the reference individual, so the resting state is
  unmoved and only the RESPONSE changes. If that cannot be arranged, the water coupling
  is deferred and the reason recorded — a component that silently moves every water
  steady state would invalidate the ADH constants derived from them.
- It may not report a resting PaCO2 agreement to more figures than §2's sources carry.
  `validation/challenge_bands_prereg.md` governs any band added to
  `validation/challenges.jl`, and a respiratory challenge added later inherits it.
- **It may not add a state.** ADR 0017 decided the loop is quasi-static. If the closed
  form cannot be written, that record is reopened rather than quietly given a state.

---

## 7. WHY THIS IS PRE-REGISTERED

The operating point of this loop — arterial PCO2 near 40 mmHg — is one of the most
familiar numbers in physiology, and the component has three free-ish parameters that
could each be nudged to produce it. **That is the precise configuration in which a model
gets calibrated to its own target and then reported as reproducing it.** HANDOVER §3.3
records that happening to the pressure-natriuresis slope, which absorbed a missing
mechanism and became a hypertensive value nobody noticed for weeks.

Fixing the sources and the decision rule first is the only defence, and branch P2 is
written down so that the interesting outcome has somewhere to go other than into a
parameter.

---

## 8. AMENDMENT, 2026-09-04 — THE SUB-EUPNOEIC LIMB

**Written before any source is opened on this question**, after the first extraction
returned branch P2. Verify the ordering against `respiratory_extract.py`'s successor.

### 8.1 The diagnosis is sharper than "a missing wakefulness drive"

The first extraction concluded a non-chemoreflex drive was missing. **That was stated
before the arithmetic was inspected and it is only half the story.** On the sourced
line, ventilation at a normal arterial PCO2 of 40 would be **19.3 L/min**, three times
resting. The line does not pass through the resting operating point at all.

**It was never measured there.** A hypercapnic ventilatory response test RAISES CO2;
the line is fitted above eupnoea and the "projected apnoea threshold" is, in the
source's own word, **projected** — an extrapolation to zero ventilation from data that
never went there. **Using it as the operating intercept extrapolates a straight line
outside its measured range**, which is exactly what `RN.GFR.VOLUME_RANGE` was created
to stop for the GFR volume response. The same error, in a second component, found the
same way.

### 8.2 The quantity to be sourced

**What governs ventilation BELOW eupnoea, between the apnoeic threshold and the
resting operating point.** Recorded for every source: whether the measurement was made
awake or asleep, the eupnoeic PCO2, the apnoeic threshold, the difference between them
(the **CO2 reserve**), and the slope below eupnoea where reported.

### 8.3 Three candidate structures, declared before searching

1. **Additive wakefulness drive.** `V_E = V_wake + S·(PaCO2 − P_thr)`, a non-chemoreflex
   baseline present awake and absent asleep.
2. **Two-slope, "dogleg".** A lower slope below eupnoea than above, so the response
   line kinks rather than continuing to a low intercept.
3. **Censoring only.** The measured line is clamped to its measured range and the
   resting point is set by the metabolic balance elsewhere.

**No preference is expressed here.** Whichever the literature supports is taken, and if
it supports 2, **both slopes must be sourced** — sourcing the upper and fitting the
lower is the prohibited move.

### 8.4 THE PROHIBITION, AND IT IS THE POINT OF THIS AMENDMENT

Every candidate above contains a parameter that **would produce a normal resting PCO2
if chosen to**. The threshold alone does it: moving it from 29.3 to 36.5 lands PCO2 at
39.9 without touching anything else.

**So: the sub-eupnoeic parameter must come from data measured BELOW eupnoea.** It may
not be inferred from the resting point, back-solved from a target PCO2, or preferred
among candidates because of where it puts the operating point. **If the only way to get
a value is to solve for it, the answer is branch W3 and the component is not built.**

### 8.5 Branches

- **W1** — a sub-eupnoeic structure is sourced in awake healthy humans. Build it,
  report the resting PCO2 that results **whatever it is**, and if it is still outside
  35–45 that is reported too rather than pursued further.
- **W2** — sourced only in sleep. Enter it with species and state recorded, default the
  awake model to it **only if** the source itself licenses the transfer; otherwise W3.
  Sleep and wakefulness differ in exactly the term being sourced, so this transfer is
  the one most likely to be wrong.
- **W3** — nothing admissible. **The component is NOT built**, the chemoreflex rows are
  entered with their measured range recorded as a censoring bound, and the finding
  stands as the result: a rectified linear chemoreflex extrapolated below its measured
  range cannot produce a normal operating point, and this repository has now hit that
  same error twice.
