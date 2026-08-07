"""
Measurement tools for the multirate decision.

DO NOT BUILD THE PARTITION BEFORE RUNNING THESE.

The case for multirate integration rests on two empirical claims. Both are testable
and neither is safe to assume:

  1. Step count concentrates in transient windows.
     (Arithmetic says 63-99% of steps fall inside <1% of wall-clock horizon. Verify
     against the real model - it depends on how far the solver expands during quiet
     intervals, which depends on the actual eigenvalue spectrum.)

  2. Linear algebra dominates the per-step cost.
     If Jacobian construction and sparse LU are NOT dominant, partitioning buys
     little and costs real correctness risk. Measure before committing.

Multirate pays by shrinking the matrix you refactor at small steps - not by skipping
right-hand-side arithmetic. RHS evaluation is rarely the bottleneck in a stiff solve.
"""

using OrdinaryDiffEq
using LinearAlgebra
using Printf

# ---------------------------------------------------------------------------
# 1. Where do the steps actually go?
# ---------------------------------------------------------------------------

"""
    step_distribution(sol; windows)

Fraction of accepted steps falling inside declared challenge windows, versus the
fraction of wall-clock horizon those windows occupy.

A large ratio is the precondition for multirate being worth anything. If steps are
spread evenly, the solver is already handling the multiscale structure and a
partition adds risk for little gain.
"""
function step_distribution(sol; windows::Vector{Tuple{Float64,Float64}})
    t = sol.t
    inwin(x) = any(w -> w[1] <= x <= w[2], windows)
    n_in = count(inwin, t)
    horizon = t[end] - t[1]
    win_time = sum(w -> w[2] - w[1], windows)
    return (steps_total = length(t),
            steps_in_windows = n_in,
            frac_steps = n_in / length(t),
            frac_time = win_time / horizon,
            concentration = (n_in / length(t)) / (win_time / horizon))
end

# ---------------------------------------------------------------------------
# 2. Does linear algebra dominate?
# ---------------------------------------------------------------------------

"""
    cost_profile(sol)

Break down solver work. `njacs` and `nw` (LU/W-matrix factorisations) versus `nf`
(RHS evaluations) tells you which lever matters.

Interpretation:
  - Many factorisations relative to RHS evals -> linear algebra bound. Partitioning
    to shrink the refactored block is the right lever. Multirate is worth the risk.
  - Few factorisations, many RHS evals -> RHS bound. Multirate buys little. Look at
    RHS allocation, common-subexpression elimination in the generated code, and
    whether structural_simplify actually reduced the state count.
"""
function cost_profile(sol)
    s = sol.stats
    ratio = s.nw > 0 ? s.nf / s.nw : Inf
    verdict = if s.nw == 0
        "no factorisations - non-stiff path taken, check solver choice"
    elseif ratio < 20
        "LINEAR ALGEBRA BOUND - partitioning is the right lever"
    elseif ratio > 200
        "RHS BOUND - multirate buys little; optimise generated code instead"
    else
        "MIXED - profile per-window before committing"
    end
    @printf("nf=%d  njacs=%d  nw=%d  naccept=%d  nreject=%d\n",
            s.nf, s.njacs, s.nw, s.naccept, s.nreject)
    @printf("nf/nw = %.1f  ->  %s\n", ratio, verdict)
    return (stats = s, nf_per_factorisation = ratio, verdict = verdict)
end

# ---------------------------------------------------------------------------
# 3. Is there a partition boundary at all?
# ---------------------------------------------------------------------------

"""
    timescale_audit(sys, u0, p, t)

Eigenvalues of the Jacobian, as time constants in seconds, sorted.

Multirate assumes a GAP in this spectrum. Physiological timescales tend to form a
continuum - baroreflex (s) -> autonomic adaptation (min) -> fluid shifts (min-h) ->
RAAS (h) -> renal-body fluid (days) -> remodelling (weeks) - with no natural place
to cut.

Print this before choosing a boundary. If there is no visible gap, any boundary is
arbitrary, and you must then demonstrate that results are insensitive to where you
put it (see `boundary_sensitivity`).

Also: this spectrum is STATE-DEPENDENT. Run it at rest, mid-hemorrhage, and at peak
exercise. A partition tuned on resting physiology can be wrong precisely during the
challenge protocols the model exists to reproduce.
"""
function timescale_audit(J::AbstractMatrix; label = "")
    ev = eigvals(Matrix(J))
    tau = [abs(real(e)) > 0 ? 1 / abs(real(e)) : Inf for e in ev]
    sort!(tau)
    finite = filter(isfinite, tau)
    isempty(finite) && return (tau = tau, gaps = Float64[])

    @printf("\n--- timescale audit %s ---\n", label)
    @printf("fastest tau = %.4g s   slowest finite tau = %.4g s   stiffness ratio = %.3g\n",
            finite[1], finite[end], finite[end] / finite[1])

    # largest ratio between consecutive time constants = candidate boundary
    gaps = [(finite[i+1] / finite[i], finite[i], finite[i+1]) for i in 1:length(finite)-1]
    sort!(gaps, by = g -> -g[1])
    println("largest spectral gaps (ratio, below, above):")
    for g in first(gaps, min(5, length(gaps)))
        @printf("   %8.2fx   %.4g s | %.4g s\n", g[1], g[2], g[3])
    end
    gaps[1][1] < 10 && @warn "No clear spectral gap. Any partition boundary is arbitrary - boundary_sensitivity is then MANDATORY, not optional."
    return (tau = finite, gaps = gaps)
end

# ---------------------------------------------------------------------------
# 4. Correctness gate - required before any multirate result is trusted
# ---------------------------------------------------------------------------

"""
    boundary_sensitivity(build_partitioned, boundaries; reference, tol = 1e-4, kwargs...)

Solve with several partition boundaries and compare each against a monolithic
reference solve.

This is the gate. Multirate schemes interpolate slow variables into the fast
subsystem; when coupling is strong they can lose formal order or destabilise WHILE
STILL PRODUCING SMOOTH, PLAUSIBLE OUTPUT. In a feedback-dominated model - where the
coupling is the physiology - that failure mode is more likely than in the domains
these methods were developed for.

Two conditions must both hold:
  - every partition agrees with the monolithic reference to `tol`
  - results are INSENSITIVE to where the boundary is placed

The second matters as much as the first. Agreement at one convenient boundary is not
evidence; it may be coincidence.

Same logic as `solver_agreement` in assemble.jl: we have no external reference by
policy, so internal consistency across independent methods is what we rely on.
"""
function boundary_sensitivity(build_partitioned, boundaries;
                              reference, tol = 1e-4, kwargs...)
    ref = Array(reference)
    results = NamedTuple[]
    for b in boundaries
        sol = build_partitioned(b)
        A = Array(sol)
        size(A) == size(ref) || error("grids must match; use identical saveat")
        dev = maximum(abs.(A .- ref) ./ max.(abs.(ref), 1e-12))
        push!(results, (boundary = b, max_rel_deviation = dev, pass = dev < tol))
        @printf("boundary %-20s  max rel dev = %.3e  %s\n",
                string(b), dev, dev < tol ? "PASS" : "FAIL")
    end
    spread = maximum(r.max_rel_deviation for r in results) -
             minimum(r.max_rel_deviation for r in results)
    spread > tol && @warn "Results depend on partition boundary placement. The partition is not physically justified."
    return results
end
