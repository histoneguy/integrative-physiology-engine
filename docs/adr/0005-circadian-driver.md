# ADR 0005: Endogenous circadian driver

**Status:** Accepted
**Date:** 2026-08-08
**Supersedes:** the rhythmicity motivation in ADR 0004

## Context

Renal sodium handling has a well-established circadian rhythm. Renal plasma flow, GFR
and tubular reabsorption/secretion peak during the active phase and decline during the
inactive phase, driven at least in part by a self-sustaining cellular clock.

Decisively for modelling: **the diurnal rhythm of tubular sodium handling occurs
independent of posture and food/water intake.** It is an endogenous driver, not a
behavioural artefact. It therefore cannot be represented as a consequence of anything
else in the model.

Mechanism. Per1 is an early aldosterone target gene in the kidney, transcriptionally
regulating ENaC, SGLT1, NHE3 and endothelin-1 - all central to sodium reabsorption.
Per1 knockout mice challenged with high salt plus DOCP lose both the night/day
difference in sodium excretion and the inactive-period blood pressure dip.

Clinical weight. Blood pressure normally dips 10-20% during the inactive period. Loss
of dipping carries elevated cardiovascular risk and end-organ damage. The day/night
urinary sodium excretion ratio is independently associated with hypertension and target
organ damage.

Key references (see ledger for per-parameter citations):
- Circadian rhythms and the kidney. Nat Rev Nephrol 2018. doi:10.1038/s41581-018-0048-9
- Recent advances in understanding the circadian clock in renal physiology. PMC6350809
- Johnston JG, Speed JS, Jin C, Pollock DM. Loss of endothelin B receptor function
  impairs sodium excretion in a time- and sex-dependent manner.
  Am J Physiol Renal Physiol 2016;311:F991-F998. doi:10.1152/ajprenal.00103.2016
- Diurnal control of blood pressure is uncoupled from sodium excretion.
  Hypertension (Bmal1-/- rat). doi:10.1161/HYPERTENSIONAHA.119.13908

## Decision

An explicit endogenous circadian driver, implemented as an independent oscillator
supplying phase to subsystems that need it. Not derived from any other state.

Entry point is tubular sodium reabsorption, via the aldosterone-Per1-ENaC pathway.
This is physiologically grounded rather than bolted on: the circadian signal reaches
sodium handling through a route that has to exist in the model anyway.

## Structural consequence 1: BP and sodium rhythms are dissociable

In whole-body Bmal1 knockout rats, males showed no significant difference in baseline
sodium excretion between active and inactive periods **while circadian MAP rhythms
remained intact**.

The two rhythms can be separated experimentally, so the model must be able to separate
them. The sodium rhythm must NOT be derived from the pressure rhythm. Each needs its
own path from the clock.

This is a falsifiable structural commitment: the model should be able to reproduce the
Bmal1 knockout phenotype by disabling the renal clock path alone.

## Structural consequence 2: THERE IS NO STEADY STATE

This is foundational and it invalidates earlier assumptions.

With an endogenous oscillator, every equilibrium is a **24-hour limit cycle**, not a
fixed point. Consequences:

- `validation/targets.md` steady-state tolerance must be restated as a tolerance on
  the cycle-averaged value, plus a separate tolerance on cycle amplitude and phase.
- Initialisation cannot solve for a fixed point. It must find a limit cycle, or start
  from a declared phase and discard a settling transient.
- **Every reported value must state its phase or its averaging window.** A bare
  "MAP = 93 mmHg" is now ambiguous.
- Solver-agreement checks must compare on a common phase grid.

## Timescale placement

Period is 24 h. Slower than baroreflex (1-5 s), faster than renal-body fluid
equilibration (days). It sits between the two.

Cost is negligible: resolving a 24 h oscillation needs perhaps 10^2 steps per day,
against a horizon measured in tens of days. It does not force the fast block.

It is a DRIVEN oscillation with a fixed period, so it does place a floor under step
size - but at 24 h that floor is far above anything else in the model. Cycle-averaging
(ADR 0002) removed cardiac and respiratory cycles and does not touch this one.

For ADR 0003 partitioning: the clock is an exogenous input with no feedback from the
model, so it may be evaluated in either block without coupling error. This is the one
genuinely free partition boundary in the system.

## Species caution

The human circadian sodium rhythm and BP dipping are documented in humans. The
**clock-gene mechanism is largely rodent** (Per1, Bmal1 knockouts). These require
separate ledger rows with honest species flags, and rodent-derived values must state
their scaling assumption.

## Sex dependence

Endothelin B receptor effects on sodium excretion are time- AND sex-dependent, and the
Bmal1 rat findings differ by sex. Sex is therefore a population covariate in the
circadian arm, not a nuisance parameter. Relevant to `sample_population`.

## Validation consequence - ACT ON THIS

**Mars500 cannot constrain any of this.** Daily 24-hour collections average the
circadian rhythm out entirely. The primary anchor for the body-fluid subsystem is
silent on the circadian question.

Constraining it requires **split day/night collections**. Human population datasets
reporting day/night UNaV ratios exist and must be added as the primary circadian
target. See `validation/targets.md`.
