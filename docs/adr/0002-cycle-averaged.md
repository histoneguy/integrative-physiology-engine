# ADR 0002: Cycle-averaged formulation

**Status:** Accepted
**Date:** 2026-08-06
**Evidence tier:** n/a - methodological
**Supersedes:** the open question left in ADR 0001

## Decision

The model is **cycle-averaged** (mean-value). Cardiac and respiratory cycles are not
integrated dynamics. Within-cycle quantities are reconstructed algebraically where
needed.

This follows the Guyton-Coleman lineage, which made the same choice for the same
reason.

## Consequence for cost

The fastest integrated mode becomes baroreflex (~1-5 s time constants) rather than
the cardiac cycle (~1 s) or respiratory cycle (~4 s). Step size is therefore not
bounded below by a driven oscillation, and the solver expands its steps freely
during quiescent intervals. 5 s output is close to free: `saveat` costs storage,
not compute.

Stiffness ratio remains large - baroreflex (seconds) to renal-body fluid
equilibration (days) is ~1e5 - so adaptive stiff integration per ADR 0001 stands
unchanged.

## Consequence for QSS

**Cycle-averaging IS the fast-mode reduction.** It removes the fast oscillatory modes
at the modeling layer, before the solver sees them. There is nothing below baroreflex
left to collapse, and baroreflex is the observable of interest.

The `qss` flag on components is therefore now near-vestigial. It is retained only for
genuinely faster-than-baroreflex algebraic loops if any subsystem introduces one
(candidate: intracellular-extracellular osmotic equilibration, though at ~30 min that
is slower than baroreflex, not faster). Default is `false`. Do not build further
machinery on it without a concrete case.

## Sampling

Baroreflex time constants of 1-5 s against 5 s output sampling is marginal - the
envelope of a transient is captured, the rise is not.

**Convention:** 1 s inside declared challenge windows, 5 s or coarser outside, via
`EventWindows`. Any result claiming to characterise a fast transient must state its
sampling interval.

## What this model cannot represent

Recorded so these are not later mistaken for bugs:

- Heart rate variability, RSA, and all spectral/time-domain HRV measures
- Mayer waves and other sub-cycle oscillatory phenomena
- Beat-to-beat and breath-to-breath variability
- Any endpoint defined as a within-cycle or spectral quantity

Protocols whose primary endpoint is one of the above are out of scope for validation
and must not be listed in validation/targets.md as if they were achievable.

## Within-cycle reconstruction

Systolic and diastolic pressure are **not state variables**. They are reconstructed
from mean arterial pressure, stroke volume and arterial compliance.

This reconstruction:
  - is an approximation carrying its own error, which must be characterised
  - requires its own ledger entries, cited like any other relationship
  - must be validated separately against measured pulse pressure data
  - must never be presented as a directly simulated quantity

See `src/reconstruct.jl`.

## Validation consequence - ACT ON THIS BEFORE DIGITISING ANY DATA

Several protocols in the canon (LBNP, head-up tilt, graded exercise) report
beat-to-beat data. A cycle-averaged model **cannot** be compared to beat-to-beat
measurements directly.

**Required:** apply a declared averaging window to the REFERENCE DATA before
comparison. The window is part of the validation specification, fixed once, applied
uniformly - not chosen per figure.

Default: 10 s centred moving average, stated per dataset in the manifest, recorded in
the ledger `notes` for any parameter derived from that dataset.

Choosing this per-figure produces inconsistent comparisons across subsystems that are
very hard to detect later. Fix it now.
