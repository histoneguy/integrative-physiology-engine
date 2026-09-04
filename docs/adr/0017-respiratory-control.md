# ADR 0017: Respiratory control, and the build order past its own end

**Status:** Proposed
**Date:** 2026-09-04
**Evidence tier:** E1 for the alveolar ventilation equation and the CO2 chemoreflex;
E1 for respiratory water loss as a mass balance; **n/a - methodological** for the
quasi-static treatment. Split per claim below.

## Context

**ADR 0006's build order is finished.** All five spine steps exist — renal sodium
handling, cardiovascular mechanics, baroreflex, RAAS, osmoregulation — and both
modulators are built. Nothing declares what comes next.

**That is why the work drifted.** With no next system written down, the outstanding
list grew to eleven items of which **one** added physiology; the rest source an
existing row, reconcile records, fix a script or extend tooling. A finished build
order with no successor does not stop work, it redirects it into refinement.

**And the whole-body claim is thin.** `CLAUDE.md` calls this a whole-body integrative
human physiology model. Every one of the seven ledger subsystems sits on the renal,
cardiovascular and fluid axis. There is no gas exchange, no acid-base, no potassium
outside an unsourced lump, and no metabolic axis.

Respiration is the largest of those gaps and the one that reaches back into what
already exists.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| Arterial PCO2 is set by metabolic CO2 production over alveolar ventilation | E1 | The alveolar ventilation equation. Mass balance on CO2, multiply replicated, the foundation of respiratory physiology | human |
| Ventilation rises approximately linearly with arterial PCO2 above a threshold | E1 | Steady-state and rebreathing CO2 response, many groups, characterised since Haldane & Priestley | human |
| Respiratory water loss is ventilation times the water content difference between expired and inspired gas | E1 | Mass balance. Expired gas is saturated at body temperature | human |
| The hypoxic drive is negligible at sea-level arterial PO2 | E1 | The ventilatory response to PO2 is hyperbolic and flat above roughly 60 mmHg | human |

**Every number is deferred to its own pre-registration**, `validation/`
`respiratory_prereg.md`. This record commits to the STRUCTURE. Directive 1.5 forbids
writing a citation nobody opened, and none has been opened for the parameters yet.

## Decision

**1. Build a respiratory component whose controlled variable is arterial PCO2, and
let PCO2 be an OUTPUT of the loop rather than a setpoint.**

This is the same claim the model already makes about arterial pressure, in a second
system, and it is the reason respiration is the right next step rather than a
convenient one. Metabolic production sets the load, the chemoreflex sets the
response, and the operating PCO2 is where they balance.

**2. The loop is QUASI-STATIC at this model's horizon, and that is methodological
rather than physiological.** Arterial PCO2 re-equilibrates in minutes. The shortest
protocol in `validation/challenges.jl` is six hours and the longest is four hundred
days. So the component contributes **no state**: the chemoreflex and the alveolar
equation are solved together in closed form.

This follows ADR 0002, which averaged the cardiac cycle away for the same reason,
and it honours directive 1.10 — a new state is paid for on every future run.

**3. Ventilation drives respiratory water loss, and that is what stops this being an
island.** `BF.H2O.INSENSIBLE_LOSS` is 0.8 L/day, `assumed`, citation *"Convention
pending primary source."* Respiratory water loss is a computable part of it. So the
component connects to `BodyFluids` on the day it is built and begins to source a row
that is currently a round number.

**4. It is introduced so that the reference individual is unchanged.** The
respiratory water term reproduces the existing constant at the operating point, in
the pattern this repository has used for every recent addition. What moves is the
RESPONSE — a person whose ventilation rises loses more water — and that is the point.

**5. ADR 0006's build order is extended by one step, not rewritten.** The next system
is respiration. What follows it is deliberately NOT decided here; committing to a
sequence before the first system is built is how ADR 0005 ended up ahead of its
dependency.

## Consequences

- **A new subsystem appears in the ledger**, the first outside the renal and
  cardiovascular axis.
- **`BF.H2O.INSENSIBLE_LOSS` stops being wholly assumed.** Its respiratory part
  becomes derived; the cutaneous part remains a residual and must say so.
- **The water balance closure moves from a constant to a computed quantity.**
  `check_closure.py` asserts water in equals water out, so that check now spans two
  subsystems. This is the first closure relation to do so.
- **It forecloses nothing in the sodium limb.** No sodium equation is touched.
- **It opens acid-base as the natural successor and does NOT take it.** pH needs
  bicarbonate and bicarbonate is renal. That is the coupling that would make
  respiration and the kidney one system, and it is named here as the obvious next
  step rather than half-built now.

## What this lumping disqualifies as evidence

**Averaging the respiratory cycle away removes the breath as a unit**, exactly as
ADR 0002 removed the cardiac cycle. The model carries alveolar ventilation as a
single flow.

**No longer usable for calibration:** any paradigm whose perturbed variable is
within-breath or breath-resolved. Tidal volume against respiratory rate at fixed
minute ventilation, dead-space fraction manipulations, breath-by-breath control
studies, the ventilatory response to added external dead space, periodic breathing
and Cheyne-Stokes dynamics, and sleep-disordered breathing of every kind. **A model
with no breath cannot be calibrated against how the breath is divided.**

**Still usable:** steady-state CO2 response, chronic and multi-day acid-base states,
metabolic rate changes, and anything reported as minute or alveolar ventilation
against arterial gas tensions. That is the class this component is built against and
it is the class the sources must come from.

## Falsifiable test

Required here even though the claims are E1, because the QUASI-STATIC treatment is a
methodological choice and is the part most likely to be wrong.

1. **PCO2 must be an output, not a setpoint.** Raise metabolic CO2 production by a
   quarter with the chemoreflex intact; arterial PCO2 must rise by **less** than the
   twenty-five per cent an uncontrolled system would give, and ventilation must rise.
   Disabling the chemoreflex must produce the full uncontrolled rise. If PCO2 does
   not move at all the loop has been written as a setpoint by accident, which is the
   error this project exists to avoid.
2. **The resting operating point must be human and must not be imposed.** With the
   sourced production and chemoreflex, arterial PCO2 must land inside the human
   reference interval without any parameter having been set to put it there.
3. **The quasi-static assumption is falsified** if any protocol in
   `validation/challenges.jl` produces a ventilation change whose own time constant
   is comparable to the protocol's duration. The shortest is six hours; respiratory
   equilibration is minutes. If a future protocol runs in minutes this record must be
   reopened and the component given a state.

## What is NOT decided

- **Acid-base and pH.** Needs bicarbonate, which is renal and does not exist.
- **Oxygen transport, haemoglobin saturation and oxygen delivery.** The model carries
  haematocrit but no oxygen carriage; that is a separate record.
- **The hypoxic drive.** Omitted, on the E1 grounds above, and the omission means the
  model is sea-level only. It must not be run against altitude data.
- **Exercise, and any metabolic rate that is not resting.**
- **Dead space as a variable.** Held constant, so the alveolar and minute ventilation
  ratio is fixed.
- **Every numeric value.** All deferred to `validation/respiratory_prereg.md`.
- **What system comes after this one.**
