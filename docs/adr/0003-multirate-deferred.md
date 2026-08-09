# ADR 0003: Multirate integration - deferred pending measurement

**Status:** Deferred (not rejected)
**Date:** 2026-08-06
**Evidence tier:** n/a - methodological

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

---

## Amendment, 2026-08-06: lagged coupling weakens the correctness objection

**Objection raised:** the feedback pathways have their own physiological timescales.

Correct, and it materially changes risk assessment 3 above.

If a coupling is a first-order lag, a partition does not CUT it - it ASSIGNS it. And
lagged coupling is exactly the condition under which multirate is safe: the lag
low-pass filters the upstream signal, so a downstream block never sees high-frequency
content from a fast block, and interpolation error is attenuated by the same dynamics
that make the coupling physiological.

**The lag is the interpolator.** A multirate infinitesimal scheme that advances the
fast solution within the slow step and averages it delivers precisely the filtered
signal the lag equation requires. Method and physiology want the same thing.

### The refined partition rule

Not all coupling here is lagged. Two classes, and the distinction is the criterion:

| Class | Character | Partition? |
|---|---|---|
| **Neurohumoral** | first-order lag, measured tau | **Safe to cut across** |
| **Mechanical** | hydraulic pressure-flow, effectively instantaneous | **Never cut** |
| **Conservation** | mass/volume/solute balance, algebraic | **Never cut** |

Examples of the second and third: blood volume -> venous return -> cardiac filling is
hydraulic and has no lag; sodium content and volume determining concentration is
algebraic. Neither has anything to hide interpolation error behind.

Measured neurohumoral time constants spanning the range: vagal baroreflex ~0.5 s,
sympathetic effector 2-5 s, renin release minutes, angiotensin II seconds-minutes,
ADH renal effect 10-30 min, aldosterone synthesis 30-60 min with tubular effect
hours, autonomic resetting hours-days.

**Cut along neurohumoral pathways; never across mechanical or conservation ones.**
This is a physiologically motivated boundary, which was the main deficiency in the
original proposal.

Enforced mechanically by `validate_partition` in src/coupling.jl.

### Evidence quality note

Coupling GAINS are the weak link - frequently fitted rather than measured, and they
populate the `calibrated` category in the ledger. Coupling TIME CONSTANTS are the
opposite: directly measured and well replicated.

So the timescale structure of this model rests on firmer empirical ground than its
gain structure. Building the architecture around timescales leans on what is actually
known rather than on what was fitted.

### What survives of the objection

1. **State-dependence still applies.** Time constants shift with physiological state.
   Run `timescale_audit` at rest, mid-hemorrhage and peak exercise regardless.
2. **Couplings whose tau sits AT the boundary.** The filtering argument is weakest
   precisely where the lag is neither clearly fast nor clearly slow.
   `validate_partition` warns on these.
3. **The scheme must average, not sample.** A naive multirate method that samples the
   fast variable at slow steps aliases it. MRI-type schemes that integrate the fast
   solution within the slow step do not. Method choice is load-bearing.

### Status change

Multirate remains **Deferred** pending profiling, but the correctness risk is now
assessed as materially lower, and the partition boundary is no longer arbitrary.
