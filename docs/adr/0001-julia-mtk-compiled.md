# ADR 0001: Julia + ModelingToolkit, compiled, adaptive stiff

**Status:** Accepted
**Date:** 2026-08-06

## Context

Primary goal is throughput, not single-run latency. Required workload: single
individuals and virtual populations over long horizons (weeks to months of simulated
time) on a workstation, without sustained cloud spend.

Existing engines in this lineage parse an XML physiology description and interpret it
at run time, with fixed-step explicit integration.

## Decision

Author the model symbolically in ModelingToolkit; compile. Adaptive stiff integration
(FBDF / Rodas5P / QNDF, with Sundials CVODE available for cross-checking).

## Where the speedup actually comes from

Ordered by expected magnitude. Note that only the third is about language choice.

1. **Structural simplification before code generation.** Alias elimination, index
   reduction and tearing remove states outright. Unavailable to an interpreted
   graph-walking engine at any language speed.
2. **Fixed-step explicit -> adaptive stiff.** Stiffness ratio across baroreflex
   (seconds) and renal-body fluid equilibration (days) is 1e5 or worse. Explicit
   fixed-step must size every step for the fastest mode across the entire horizon.
3. **Interpretation -> compilation.** Real, but smaller than the two above.
4. **Quasi-steady-state reduction of fast subsystems on long runs.** Component-level
   `qss` option. Largest remaining lever specifically for month-scale horizons.
5. **Sparse analytic Jacobian with matrix colouring.** Free from the symbolic layer.

## Consequences for the workload

- Build and simplify once; reuse across ensemble members. Never rebuild in a loop.
- Per-run memory is the binding constraint, not per-run time. Coarse `saveat`, no
  dense output, reduce inside `output_func`.
- Zero allocation in the RHS. GC pressure dominates at ensemble scale.
- `EnsembleThreads` on one workstation before any distributed compute.

## Costs accepted

- JIT latency on first call. Mitigate with PrecompileTools; irrelevant to batch work.
- Smaller hiring pool than C++. Mitigated by the symbolic layer being declarative -
  a physiologist can read a component without writing solver code.
- Ecosystem churn. Pin versions in Manifest.toml; commit it.

## Rejected

- **C++ / SUNDIALS.** Higher ceiling, easier to staff, much slower to iterate. Remains
  the fallback, and MTK can emit C if a static binary is ever required.
- **Rust.** Stiff-solver and AD ecosystem not competitive for this problem class.
- **Modelica.** The natural acausal language and a real option, but adopting an
  existing whole-body Modelica model is a build-versus-adopt decision rather than a
  language decision. See docs/canon.md.
- **Pure Python.** Retained for tooling, validation harness and CI. Not the engine.

## Verification obligation

We deliberately do not validate against another engine's outputs
(SOURCES.md section 4). `solver_agreement` in src/assemble.jl substitutes: independent
integrators must agree to a stated tolerance. This is a stronger claim than matching a
single implementation, since it cannot be satisfied by reproducing that
implementation's integration error.

---

## Amendment, 2026-08-06: output resolution requirement

Requirement clarified to ~5 s output resolution. Arithmetic:

| Horizon | Points/individual | 500 states, f64 |
|---|---|---|
| 1 day | 17,280 | 0.06 GB |
| 30 days | 518,400 | 1.93 GB |
| 1 year | 6,307,200 | 23.5 GB |

1000 members x 30 days x 500 states = **~0.9 TB**. Not viable.

Compute, by contrast, is comfortable. Even if the solver is forced to ~5 s steps at
1 ms/step, a 30-day individual is ~8.6 min and 1000 members on 32 cores is ~4.5 h.
At 300 us/step, ~1.4 h. Workstation-scale, as required.

**Conclusion: storage is the binding constraint, not compute.** Ensemble members
return summary statistics; trajectories are never materialised. See src/recording.jl.

### Consequence for QSS (revises point 4 above)

`saveat` does not set step size - the solver steps as accuracy demands and
interpolates onto the output grid. Requesting 5 s output costs storage; it costs
compute only if fast modes are persistently active.

Global QSS reduction is therefore NO LONGER the default. If 5 s dynamics are the
observable of interest, collapsing fast loops destroys the signal being paid for.
QSS becomes a windowed tool - applied during quiescent intervals, disabled inside
challenge windows - via `EventWindows`.

### Open decision: transient-resolver or oscillator

Unresolved and load-bearing.

- **Transient-resolver** (mean-value / cycle-averaged, the Guyton-Coleman lineage):
  fast modes quiescent between perturbations, solver expands steps to hours during
  quiet intervals, 5 s output is nearly free. Long horizons stay cheap.
- **Oscillator** (beat-to-beat cardiac, breath-by-breath respiratory, Mayer waves):
  step size bounded below permanently, full 5 s-step cost across the entire horizon,
  ~8 min/individual-month floor.

Both are defensible. They are different model classes with an order-of-magnitude
cost difference. Decide deliberately; do not discover it.
