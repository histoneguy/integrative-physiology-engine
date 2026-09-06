# ADR 0020: The acid–base limb, and the first loop that is slow at one end and fast at the other

**Status:** Accepted, **amended the same day — read the amendment before the decisions**
**Date:** 2026-09-05
**Evidence tier:** E1 for the Henderson–Hasselbalch relation, for bicarbonate as the
dominant extracellular buffer, and for renal net acid excretion balancing endogenous acid
production; E2 for the quantitative renal response to plasma bicarbonate, which is
measured in humans but over a narrow range and mostly by bicarbonate loading.

## Context

**The model has arterial PCO2 and it has a kidney, and it cannot say what the pH is.**
That is the most conspicuous absence left in a whole-body model that already reports
oxygen saturation, thyrotropin and urine osmolality.

**Every piece of what is needed already exists except the bicarbonate.** ADR 0017 built
alveolar ventilation and arterial PCO2. The renal component carries glomerular filtration
and tubular handling. Henderson–Hasselbalch needs those two and one more state.

**And it is the first loop in this model that is genuinely two-timescale.** The
respiratory arm moves PCO2 in minutes; the renal arm moves bicarbonate in days. Every
other coupling here is either fast on both sides (pressure, gas exchange) or slow on both
(thyroxine, sodium storage). ADR 0003 deferred multirate integration on state count; this
is the first record whose physiology is *about* the separation.

**ADR 0018 named the absence explicitly** in what it disqualified: *"It does NOT open
acid-base. The Bohr effect shifts the dissociation curve with pH, and pH needs
bicarbonate, which is renal and absent."*

## Evidence

| Claim | Tier | Basis | Species |
|---|---|---|---|
| Arterial pH follows from the ratio of bicarbonate to dissolved CO2 by the Henderson–Hasselbalch relation | E1 | The definition of a buffer pair applied to a measured pK′ and CO2 solubility; universally used in clinical practice | human |
| Bicarbonate is the dominant extracellular buffer and its concentration is a regulated quantity | E1 | Multiply replicated | human |
| Diet and metabolism produce a net acid load that the kidney must excrete for bicarbonate to be stable | E1 | Multiply replicated; measurable as net acid excretion in urine | human |
| Renal net acid excretion rises as plasma bicarbonate falls, and bicarbonate is spilled when it rises above a threshold | E2 | Measured in humans by bicarbonate loading and by acid loading; the range studied is narrow and the threshold varies with volume status | human |
| Respiratory compensation for a metabolic acid–base disturbance exists and is fast; renal compensation for a respiratory one exists and takes days | E1 | Multiply replicated | human |

**Numbers are deferred to `validation/acid_base_prereg.md`.** None has been opened yet and
directive 1.5 forbids writing a citation nobody read.

**Same constraint as ADR 0018 and 0019:** primary experimental literature and published
mathematical relationships only. Other whole-body simulation models are not sources, for
structure or for values.

## Decision

**1. ONE state: extracellular bicarbonate. Arterial pH is an OUTPUT of it and of PCO2.**

Not pH — bicarbonate. pH is a logarithm of a ratio and integrating it would put the
model's conserved quantity in the wrong place: what is actually conserved is base, and
the kidney excretes acid in milliequivalents per day, not in pH units per day. This is
HANDOVER §3.6's rule — integrate the quantity that is measured as a flux.

**2. The renal arm is a first-order response to plasma bicarbonate, and the respiratory
arm is the PCO2 the model already computes.** Net acid excretion rises as bicarbonate
falls. Nothing new is measured on the respiratory side; ADR 0017's PCO2 is read as it
stands.

**3. NO pH FEEDBACK ONTO VENTILATION, and this is the deliberate omission that matters.**
The central and peripheral chemoreceptors respond to pH as well as to PCO2, and a
metabolic acidosis produces Kussmaul respiration. **Building that would make the
respiratory operating point an output again**, which ADR 0017's amendment explicitly
walked away from after its own falsifiable test failed. One change at a time. The hook is
left where a later record can take it.

**4. NO BOHR EFFECT, so ADR 0018's dissociation curve stays fixed.** pH will exist and
will not be read by the oxygen curve. That is a second deliberate omission and it means
this record does NOT discharge ADR 0018's disqualification list — it only removes the
stated reason the list was written.

**5. Bicarbonate does not enter plasma osmolality.** The model's osmolality is built from
sodium and a lumped non-sodium residual in which bicarbonate is already implicitly
counted. Adding it as a named solute would double-count it, which is the class of error
HANDOVER §3.8 records for red cell volume.

**6. It is NOT sexed.** ADR 0014's "where only one value is supported, use it for both"
until a pre-registered search says otherwise.

## Consequences

- **An eleventh component and a tenth state.** Directive 1.10 says the state is paid on
  every run. It is justified by the same argument ADR 0019 used for thyroxine: the
  slowness IS the physiology, and a renal compensation that takes days cannot be an
  algebraic relation on a model that runs four hundred.
- **The model gains arterial pH, plasma bicarbonate, the base excess, and renal net acid
  excretion** — four quantities a physiologist reads before most of what this model
  already reports.
- **Respiratory and metabolic acid–base disturbances become representable**, and the
  renal compensation for the respiratory one is a genuine multi-day prediction with
  nothing fitted to it.
- **It opens the anion gap and does not take it.** That needs chloride, which is absent.
- **It makes the model's silence about potassium louder**, because acidosis shifts
  potassium out of cells and the model has no potassium at all.

## What this lumping disqualifies as evidence

**One bicarbonate compartment removes intracellular buffering and bone.** Roughly half
the buffering of an acute acid load is non-bicarbonate and intracellular, so this model
will over-state the plasma bicarbonate fall for a given acute acid load and cannot be
calibrated against anything whose perturbed variable is buffer capacity: acute
bicarbonate infusion time courses, the acute-versus-chronic difference in respiratory
compensation, or bone buffering in chronic acidosis.

**No chloride and no unmeasured anions removes the anion gap entirely.** Diabetic
ketoacidosis, lactic acidosis, toxic alcohols and renal tubular acidosis cannot be
distinguished from one another or from a hyperchloraemic acidosis.

**No pH feedback on ventilation removes respiratory compensation for metabolic
disturbance.** A metabolic acidosis in this model will NOT lower PCO2. That is a large
and visible omission and it is decision 3.

**Still usable:** steady-state arterial pH and bicarbonate in health, the direction and
time course of renal compensation for a sustained change in PCO2, and the bicarbonate
consequence of a change in net acid intake.

## Falsifiable test

1. **Resting arterial pH and bicarbonate must land in the human reference range** with
   nothing set to put them there. PCO2 is an input from ADR 0017; bicarbonate follows
   from acid production against renal excretion. **This can fail**, and unlike ADR 0019's
   voided test the two inputs are on the same scale by construction — a millimole of
   bicarbonate is a millimole.
2. **A sustained rise in PCO2 must raise bicarbonate over DAYS and partially restore
   pH.** Renal compensation. If pH is fully restored the renal gain is too high; if
   bicarbonate does not move the arm is not connected.
3. **The compensation must be slow.** A step in PCO2 must take days, not hours. If it
   settles in hours the time constant is in the wrong units and decision 1's justification
   for a state evaporates.
4. **A metabolic acid load must lower bicarbonate and pH and must NOT change PCO2**,
   because decision 3 builds no pH feedback onto ventilation. That is the test that keeps
   the omission honest rather than forgotten.
5. **With the component disabled, every existing result must be bit-identical.**

## Amendment, 2026-09-05: NO state, NO eleventh component, and the dependency inverted

**This record was written in the morning and implemented in the afternoon, and decision
1 did not survive the sourcing.** Both halves of the bicarbonate balance failed:

- **The renal response to plasma bicarbonate could not be sourced** as a published form
  with a gain in healthy humans. The quantitative acid–base literature is almost entirely
  disorder-driven — directive 1.7's **fifth** subsystem — and the classic human titration
  work is neither open nor in healthy preparations. `acid_base_prereg.md` **branch A3**.
- **Net endogenous acid production spans threefold** across what could be opened: **22
  mEq/day** measured by 24-hour urine in ~90 healthy omnivorous adults (Mansouri 2024)
  against the conventional **70**, with a third source reporting 39 ± 38 on deliberately
  designed acid and base diets. **Branch A4** says do not build on that.

**A balance whose input flux is uncertain threefold and whose renal gain is unsourced is a
balance in which the set-point does all the work.** Building it would have produced a
bicarbonate that reproduced whatever set-point was entered, and falsifiable test 1 would
have been void for the same reason ADR 0019's test 2 was.

### What was built instead

**Plasma bicarbonate is an INPUT and arterial pH is the OUTPUT.** Sourced from NHANES
2007–2012, n = 8809 adults. **No state, no eleventh component** — the three constants and
one equation live in `Blood.jl`, which already receives arterial PCO2.

**This is the third dependency inversion in this model**, after arterial PCO2 (ADR 0017's
amendment) and the thyroid operating point (§3.26), and for the same reason each time:
source the quantity that is actually measured. Plasma bicarbonate is measured in every
basic metabolic panel; renal net acid excretion is not measured in anyone healthy.

### Falsifiable test 1 survives, and it is a real one

pH composes **four independent measurements** — an apparent pK by titration, a solubility
by tonometry, a bicarbonate in 8809 adults, and an arterial PCO2 sourced under ADR 0017 —
**all on scales that compose.** A millimole is a millimole. It can be wrong.

**It comes out at 7.420 against a human arterial 7.40, and the residual is not closed.**
`AB.HCO3.PLASMA` is a **venous serum total CO2**, which runs 1–2 mmol/L above arterial
bicarbonate; subtracting 1 gives 7.402. **Applying that correction would set the parameter
from the quantity being tested**, so it is reported instead. This is the third time a
measurement-scale mismatch has mattered here and **the first time it was caught before
the number was believed** rather than after.

### Tests 2 and 3 are void; test 4 is inverted and stronger

Without a bicarbonate state there is no renal compensation, so **tests 2 and 3 cannot be
run** and the deferral is recorded rather than quietly dropped. **Test 4 becomes the
sharp one**: a respiratory disturbance must move pH and a metabolic one cannot, because
bicarbonate is a constant — which makes decision 3's omission visible in the output
instead of only in this document.

**What the model does gain** is a live respiratory acid–base axis: at twice thyroid
secretory capacity with the metabolic arm on, arterial PCO2 rises to 41.8 and pH falls to
7.400. That is a **four-hop chain** — thyroid → respiratory → arterial CO2 → pH — and the
longest in the model.

## What is NOT decided

- **Chloride, the anion gap, and unmeasured anions.**
- **Intracellular and bone buffering.**
- **The Bohr and Haldane effects.**
- **pH feedback onto ventilation**, and therefore respiratory compensation for metabolic
  disturbance.
- **Potassium**, which acid–base status shifts and which the model does not have.
- **Renal tubular acidosis, or any disease state.**
- ~~**Every numeric value.**~~ Three are in the ledger under `AB.*`.
- **The bicarbonate STATE, renal net acid excretion, and endogenous acid production** —
  deferred by the amendment above, with the two sourcing failures named. What would
  discharge it: a measurement of renal net acid excretion against plasma bicarbonate in
  healthy adults, and a second habitual-diet measurement of net endogenous acid
  production to arbitrate the threefold spread.
- **The base excess**, which needs the Van Slyke relation and haemoglobin — one more
  published form, not yet opened.
