# ADR 0004: Osmotically inactive sodium storage

**Status:** Accepted (structure), parameters unestimated
**Date:** 2026-08-08

## Context

The classical formulation - Guyton-Coleman lineage and most descendants - treats all
body sodium as osmotically active. Extracellular volume therefore tracks extracellular
sodium content directly, and daily urinary sodium excretion reflects intake once a
steady state is reached.

The Mars500 balance studies contradict this.

Rakova N et al, *Long-term space flight simulation reveals infradian rhythmicity in
human Na+ balance*, Cell Metab 2013;17(1):125-131, doi:10.1016/j.cmet.2012.11.013.

Design: enclosed habitat, salt intake the only modified variable, stepped 12 -> 9 -> 6
g/day NaCl in Mars105 and back to 12 g/day in Mars520, each level held 30-60 days.
12 men, all urine collected daily, ~95% recovery of dietary electrolytes.

Findings that matter to us:
- Total-body Na+ is stored, and is NOT a simple function of salt intake.
- Total-body Na+ and extracellular water are NOT tightly coupled.
- Na+ balance shows infradian rhythmicity - 7-day and monthly cycles - at constant
  intake.

Storage appears to be largely in skin and other tissue binding sites. Independent
support: 23Na MRI shows skin Na+ content increasing with age at
0.34 +/- 0.07 mmol/(L*year).

## Decision

A third compartment: osmotically inactive stored sodium, exchanging with the
extracellular pool through a first-order lag.

`storage = false` recovers classical two-compartment behaviour. That switch exists as
a VALIDATION EXPERIMENT, not a fallback - reproducing the classical failure against
the Mars500 series is itself a result worth having.

## Why this matters beyond fidelity

A two-compartment model cannot reproduce the best available human sodium balance
dataset. Building it and then discovering that would waste a subsystem's worth of
estimation effort against a structure known in advance to be wrong.

This is also the clearest instance so far of the project's premise paying off. The
data did not exist in 1972. Coleman's structure was correct given what was known;
it is not correct given what is known now.

## What is NOT decided

The structure is accepted. The parameters are placeholders and are marked `assumed`
in the ledger:

- `BF.NA.OSMOTICALLY_INACTIVE_FRACTION` = 0.15. Rakova et al do not report a single
  storage fraction. This number exists only to make the compartment functional.
- `BF.NA.STORAGE_TAU` = 7 days. Chosen to MATCH the reported weekly rhythm, not
  derived from it. A first-order lag is the crudest structure that can produce
  retention and release on that scale.

Both must be estimated against the Mars500 series before any result involving sodium
balance is reported. Until then `unledgered_check()` will surface them, and it should.

A first-order lag may also prove structurally inadequate: it cannot generate the
monthly rhythm, and it cannot generate rhythmicity at constant intake at all, since
it has no oscillatory mode. If estimation fails to fit the data, the honest conclusion
is that the structure needs revising - possibly an active, clock-driven process rather
than passive buffering - not that the parameters need more tuning.

## Consequences elsewhere

- `Na_total = Na_ecf + Na_store` is a hard conservation assertion in the test suite.
- All three body-fluid couplings are Conservation or Mechanical class, so per ADR 0003
  no multirate partition may cut across them.
- Storage tau (7 d) sits in the slow block. Osmotic equilibration tau (30 min) is much
  faster but is still far slower than baroreflex, so it does not force the fast block
  either.
