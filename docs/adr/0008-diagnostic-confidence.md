# ADR 0008: Diagnostics must not overstate their evidence

**Status:** Accepted
**Evidence tier:** n/a - methodological
**Date:** 2026-08-11

## Context

Three separate diagnostic stages produced confident, wrong conclusions in
consecutive runs of the same tool:

1. **"No analytic Jacobian available - this is itself a finding."** The stage built
   its own `ODEProblem` without `jac = true` after a deprecation fix dropped the
   kwargs. The solve path was passing them throughout. Reported twice before being
   checked.

2. **"Clear gap present - a partition boundary at 5.75e11 s is physiologically
   motivated."** 5.75e11 seconds is 18,000 years. A conserved quantity gives an
   exactly-zero eigenvalue; numerically it returns ~1e-19 and inverts to a time
   constant of 1e18 s. The absolute 1e-14 cutoff let it through.

3. **"LINEAR ALGEBRA BOUND - multirate is worth its correctness risk."** Rendered
   from a 3-state model with 22 RHS evaluations, where nf/nw measures startup
   overhead rather than any steady-state cost regime.

Each was formatted identically to a real finding: bold verdict, confident phrasing,
an actionable recommendation. A reader acting on any of them would have been misled.

There is also a related model-side failure worth recording here because it is the
same shape: the first successful run settled to 1.13e-6 at a state with zero
intracellular water and reported `retcode: Success`. The check asked whether the
model settled, not whether it settled anywhere survivable.

## Decision

A diagnostic must state the evidence its verdict rests on, and must refuse to
render a verdict when that evidence is insufficient.

Three requirements:

1. **Evidence thresholds.** A stage that classifies must declare the minimum data
   for classification and print **NO VERDICT** below it, naming what is missing.
   Stage 4 requires >= 20 states and >= 500 RHS evaluations.

2. **Plausibility bounds on derived quantities.** A result outside the range the
   model can physically represent is an artefact and must be reported as one, not
   as a finding. Stage 5 rejects any proposed partition boundary outside
   0.1 s - 30 days, and discards eigenvalues that are zero to within the
   conditioning of the matrix rather than an absolute tolerance.

3. **Diagnostics construct problems the same way the solve path does.** Where a
   stage builds its own object, it must use the production construction, or it is
   measuring something other than what runs.

## Consequence

`ADR 0003` (multirate) must NOT be closed on the current evidence. The stage now
says so explicitly rather than printing a verdict the model cannot support.

## Falsifiable test

Not applicable - methodological. The check is that each classifying stage has a
declared threshold and a NO VERDICT path, verifiable by reading the source.

## Note

The underlying failure is not carelessness in any one stage. It is that a
diagnostic which always emits a verdict will emit a wrong one whenever the evidence
is thin, and confident formatting makes thin evidence indistinguishable from strong.
Refusing to conclude is a feature.
