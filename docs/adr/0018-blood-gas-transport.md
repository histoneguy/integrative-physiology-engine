# ADR 0018: Blood oxygen transport, and the first quantity that needs two subsystems

**Status:** Proposed
**Date:** 2026-09-04
**Evidence tier:** E1 for the alveolar gas equation, oxygen carriage by haemoglobin,
the sigmoid dissociation relation and the convective delivery identity; E2 for the
alveolar-arterial difference, which is measured but varies with age and posture.

## Context

ADR 0017 built ventilation and alveolar CO2 and **explicitly deferred oxygen**:
*"Oxygen transport, haemoglobin saturation and oxygen delivery. The model carries
haematocrit but no oxygen carriage; that is a separate record."* This is that record.

**The gap is conspicuous.** The model has cardiac output, haematocrit as a sexed pair,
and now alveolar ventilation — every input to arterial oxygen content and oxygen
delivery — and computes neither. Haematocrit has been in the ledger since before the
red-cell correction and does no work except through blood volume.

**And oxygen delivery is the first quantity in this model that cannot be computed
inside one component.** It needs cardiac output from the cardiovascular side and
arterial oxygen content from the respiratory side. Every previous coupling passed a
signal or a flux between two components; this one is a product of two.

## Evidence

| Claim | Tier | Basis | Species |
|---|---|---|---|
| Alveolar PO2 follows from inspired PO2 and alveolar PCO2 through the respiratory exchange ratio | E1 | The alveolar gas equation. Mass balance, universally used | human |
| Almost all arterial oxygen is carried bound to haemoglobin; dissolved oxygen is a small additive term proportional to PO2 | E1 | Multiply replicated | human |
| Haemoglobin oxygen saturation is a sigmoid function of PO2 | E1 | Multiply replicated since Bohr; the Hill form is the standard published description | human |
| Oxygen delivery is cardiac output times arterial oxygen content | E1 | Definitional, a convective flux | human |
| Arterial PO2 is below alveolar PO2 by a measurable difference that widens with age | E2 | Measured in healthy adults; varies with age and posture | human |

**Numbers are deferred to `validation/blood_gas_prereg.md`.** None has been opened yet
and directive 1.5 forbids writing a citation nobody read.

**A CONSTRAINT RECORDED BECAUSE IT SHAPED THE SEARCH.** Structure and values come from
**primary experimental literature and published mathematical relationships only.** Other
whole-body simulation models are not sources here, for structure or for parameters, and
`validation/targets.md` already says targets are experimental data and never another
model's output. A published *equation* fitted to measured data — a dissociation-curve
relation, for instance — is admissible **as a relation, with its citation**, and is a
different object from another model's output.

## Decision

**1. Compute arterial oxygen content and oxygen delivery. Do not close a loop.**

There is no oxygen feedback in this record. The hypoxic ventilatory drive is omitted by
ADR 0017, and the cardiac-output response to anaemia and hypoxia is real, E1, and
**deliberately not built here** — it would perturb the pressure loop, and one change at
a time is how this repository keeps things testable.

**So this component is a forward computation, and saying so plainly is the point.**
It is a set of observables, not a controller. What it buys is that four existing
quantities finally do work, and that the model reports the variable clinical physiology
actually cares about.

**2. No state, for ADR 0017's reason.** Gas transport equilibrates in seconds.

**3. Saturation uses a published closed-form relation with its citation**, not a
lookup table and not a curve fitted here. Which relation is chosen is
`blood_gas_prereg.md`'s business; that it must be published, cited, and applicable to
human blood at normal pH and temperature is decided here.

**4. Haematocrit finally does work beyond blood volume.** Haemoglobin concentration is
sourced independently rather than derived from haematocrit, because both are measured
directly and deriving one from the other would repeat the dependency error HANDOVER
§3.6 records. The consistency between them becomes a closure check, which is a TEST
rather than a definition.

**5. It is sexed from the start.** Haemoglobin concentration is one of the largest
sexed differences in human physiology and this ledger already carries haematocrit as a
sexed pair. ADR 0014 applies.

## Consequences

- **A second new subsystem**, and the first quantity requiring two of them at once.
- **The A-a difference makes the model explicitly AGE-blind.** It widens with age and
  this model has no age dimension, so the row will carry a young-adult value and say so
  — the same debt `ADH.URINE.OSM_MAX` already carries.
- **Sea level only, again.** Inspired PO2 is barometric. ADR 0017 already bound the
  model to sea level twice; this is the third.
- **It opens the anaemia and hypoxia cardiac response** and does not take it.
- **It does NOT open acid-base.** The Bohr effect shifts the dissociation curve with pH,
  and pH needs bicarbonate, which is renal and absent. The curve is therefore fixed at
  normal pH and temperature, and that exclusion is recorded below.

## What this lumping disqualifies as evidence

**A fixed dissociation curve removes the Bohr and temperature shifts.** The model cannot
be calibrated against anything whose perturbed variable is the POSITION of the curve:
acidosis or alkalosis shifting P50, fever or hypothermia, 2,3-DPG changes in stored
blood or at altitude, or the increased oxygen offloading in exercising muscle.

**A single arterial compartment removes regional distribution.** Ventilation-perfusion
inequality is collapsed into one A-a difference, so the model cannot represent shunt
fraction, dead-space disease, or the multiple inert gas elimination paradigm at all.

**Still usable:** arterial oxygen content and saturation in healthy resting adults,
anaemia as a haemoglobin change at fixed curve position, and convective oxygen delivery.

## Falsifiable test

1. **Arterial saturation must land in the human reference range** with the sourced
   haemoglobin, the sourced curve and the sourced A-a difference, with **no parameter
   set to put it there.** Unlike ADR 0017's resting PCO2, this one is a genuine
   prediction: every input is sourced independently of the output.
2. **The sexed pair must move oxygen delivery and must not move arterial saturation.**
   Haemoglobin differs between the sexes; the curve does not. If saturation comes out
   sexed, haemoglobin has leaked into the wrong equation.
3. **Anaemia must reduce delivery roughly in proportion to haemoglobin** while leaving
   saturation and arterial PO2 unchanged. That is the property that distinguishes
   content from tension and it is the one most easily got wrong.
4. **Haemoglobin and haematocrit must agree** through a mean corpuscular haemoglobin
   concentration inside the human range. Sourced independently, so this can fail.

## What is NOT decided

- **Venous oxygen content, the Fick relation and extraction ratio.** They need tissue
  oxygen consumption, which is a metabolic row this model does not have.
- **The Bohr effect, temperature and 2,3-DPG.**
- **Carbon dioxide carriage**, which is bicarbonate, carbamino and dissolved — and again
  needs the renal acid-base limb.
- **Any oxygen feedback whatsoever.**
- **Carboxyhaemoglobin and methaemoglobin**, which are non-zero even in healthy
  non-smokers and are simply omitted.
