# ADR 0003: Multirate integration - deferred pending measurement

**Status:** Deferred (not rejected)
**Date:** 2026-08-06

## Context

Proposal: evaluate each subsystem only on its own timescale, rather than evaluating
the whole right-hand side at the step size demanded by the fastest active mode.

This is multirate integration. The motivating observation is sound.

## The arithmetic

30-day run, four 30-minute challenge windows:

| quiet dt | transient dt | quiet steps | transient steps | transient share |
|---|---|---|---|---|
| 60 s | 0.1 s | 43,080 | 72,000 | 62.6% |
| 300 s | 0.1 s | 8,616 | 72,000 | 89.3% |
| 3600 s | 0.1 s | 718 | 72,000 | 99.0% |

Challenge windows are **0.28% of wall-clock horizon but 63-99% of steps**. Nearly all
compute is spent inside transients, evaluating a renal-endocrine system that barely
moves during them. The waste is real.

## Where the win actually is

NOT in skipping right-hand-side arithmetic. In a stiff solve the dominant cost is
Jacobian construction and sparse LU factorisation, not RHS evaluation.

Multirate pays by shrinking the matrix refactored at small steps. Sparse
factorisation scaling ~O(n^1.5):

| fast block | of 3000 | factorisation speedup per transient step |
|---|---|---|
| 50 | 3000 | ~465x |
| 100 | 3000 | ~164x |
| 300 | 3000 | ~32x |

Design toward a smaller refactored block, not toward skipping equations.

## Why this is deferred rather than adopted

Three risks, in increasing order of how quietly they bite.

1. **No natural partition boundary.** Physiological timescales form a continuum -
   baroreflex (s), autonomic adaptation (min), fluid shifts (min-h), RAAS (h),
   renal-body fluid (days), remodelling (weeks). There is no gap to cut at. Any
   boundary is arbitrary unless results are shown insensitive to its placement.

2. **The partition is state-dependent.** Subsystems classified as slow at rest speed
   up substantially during exercise or hemorrhage - precisely the challenge protocols
   the model exists to reproduce.

3. **Coupling error and order reduction.** Multirate schemes interpolate slow
   variables into the fast subsystem. Under strong coupling they can lose formal
   order or destabilise WHILE STILL PRODUCING SMOOTH, PLAUSIBLE OUTPUT. This model is
   feedback-dominated; the coupling *is* the physiology. That elevates the risk
   relative to the domains these methods were developed for.

## Required order of work

1. **Confirm sparse Jacobian with matrix colouring is active.** Already planned, zero
   correctness risk, plausibly 10-100x on its own. Do this first regardless.
2. **Profile.** `cost_profile` in src/profiling.jl reports nf/nw. If linear algebra
   is not dominant, multirate buys little at meaningful risk - stop here.
3. **Audit the spectrum.** `timescale_audit` at rest, mid-hemorrhage and peak
   exercise. If there is no spectral gap, record that the boundary is arbitrary.
4. **Only then partition** - two blocks, not many - with the boundary as its own ADR.

## Correctness gate

`boundary_sensitivity` in src/profiling.jl. Two conditions, both required:

- every partition agrees with a monolithic stiff reference to stated tolerance
- results are insensitive to where the boundary is placed

The second matters as much as the first: agreement at one convenient boundary may be
coincidence. Same logic as `solver_agreement` (ADR 0001) - we have no external
reference by policy, so internal consistency across independent methods is the
standard.

## Note

Do not build the partition before running the measurements. The tools in
src/profiling.jl exist to make the decision, not to implement it.
