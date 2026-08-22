# ADR 0007: The minimal closed loop is the model

**Status:** Accepted
**Evidence tier:** MIXED - see the addendum of 2026-08-21 (E1 phenomena, E2 animal-derived quantitative forms)
**Date:** 2026-08-08

## Context

Work to date built two modulators - sodium storage (ADR 0004) and circadian rhythm
(ADR 0005) - before the subsystem they modulate existed. ADR 0006 recorded the rule
against this but its own build order still listed modulators alongside the spine.

A modulator of something that does not exist cannot be validated, tuned, or falsified.

## Decision

Three components, one loop, nothing else:

    BodyFluids  --V_ecf-->  Cardiovascular  --MAP-->  Renal
         ^                                              |
         +---------- Na_excr, H2O_excr -----------------+

Sodium and water in; ECF volume sets blood volume; blood volume sets cardiac output;
cardiac output sets pressure; pressure drives excretion; excretion closes onto ECF.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| Pressure natriuresis exists and is steep | E1 | Guyton 1972 and the replication literature since | human |
| GFR autoregulated ~80-180 mmHg | E1 | standard renal physiology | human |
| Filtered load = GFR x concentration; excretion = filtered - reabsorbed | E1 | definitional | - |
| MAP = CO x TPR | E1 | definitional | - |
| Cardiac output rises with venous return, which rises with blood volume | E1 | Guyton 1972; Frank-Starling literature | human |
| Pressure natriuresis SLOPE = 20 (mEq/day)/mmHg | **calibrated** | Guyton 1972 | fitted |
| Venous return sensitivity = 2880 (L/day)/L | **calibrated** | Guyton 1972 | fitted |

The two calibrated values TOGETHER SET THE LOOP GAIN. Everything the model claims
about long-run pressure regulation depends on two numbers that were fitted, not
measured, and that propagated through the modelling literature until they read as
facts. This is the clearest instance of the problem the ledger exists to make visible.

## The central claim

**Arterial pressure is an OUTPUT of this loop, not a setpoint.** Nothing in the model
regulates MAP. Its stability comes entirely from pressure natriuresis acting through
fluid volume.

That is the substance of the Guyton formulation, and demonstrating it is what this
minimal model is for.

## Falsifiable test

A step increase in sodium intake must produce:

1. transient sodium retention and a rise in ECF volume,
2. a rise in arterial pressure,
3. return of excretion to match intake - at a NEW, higher pressure.

Failure to re-equilibrate means the loop is not closed. Re-equilibration at the ORIGINAL
pressure means pressure natriuresis is inert and the model is not doing what it claims.

The Mars500 stepped protocol (12/9/6 g/day NaCl) is the intended input.

## What is deliberately omitted

Baroreflex, RAAS, ADH, tubuloglomerular feedback, nephron segments, potassium,
acid-base, regional flows, heart rate and contractility, TPR as a state, sex
differences, circadian modulation.

TPR is a CONSTANT. Water excretion is intake minus insensible loss, floored at the
obligatory minimum - it is NOT osmoregulation, because ADH does not exist. Both are
placeholders that hold the loop closed so the sodium arm can be tested.

## Status of prior work

- `BodyFluids` storage compartment: retained, defaults OFF (ADR 0004, E3).
- `Circadian.jl`: retained, NOT CONNECTED. `build_model(circadian=true)` adds the
  component and warns that it affects nothing. It modulates renal tubular
  reabsorption, which needs RAAS and ADH before the modulation is meaningful.

Both are recorded as sequencing costs rather than deleted. Neither is wrong; both
are early.

## Next, in order

1. Get this loop running and reproduce the salt step qualitatively.
2. Estimate the two calibrated gains against the Mars500 series - as posteriors.
3. Baroreflex (E1), which makes TPR a state.
4. RAAS (E1), then ADH (E1), which replaces the placeholder water excretion.
5. Only then reconnect circadian.

---

## Addendum, 2026-08-21 - the tier line was overstated

This ADR claimed **E1 - all three components rest on multiply-replicated human
physiology**. The phenomena do. Their quantitative forms do not.

`Renal.FR_effective`, the relation this ADR exists to justify, rests on Roman & Cowley
1985 (rat), Osborn/Francisco/DiBona 1981 (dog) and Mizelle 1993 (dog). There is no
human primary source for the pressure-natriuresis slope and there cannot be one: it
requires servo-controlling renal perfusion pressure for days.

Under the amended ADR 0006 that is **E2 under an ethical ceiling**, which is a
perfectly good basis to build on. What the original line did was obscure it. The
decision of this ADR is unchanged; only the honesty of its tier line is.

Note the asymmetry this exposed. `RN.PRESSURE_NATRIURESIS.SLOPE` is recorded as
`species: human`, but it is not a human measurement - it is a fitted constant from
Guyton 1972. The genuinely measured numbers here are the animal ones.
