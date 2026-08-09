#!/usr/bin/env julia
"""
Diagnostics for CI.

Answers, from a real Julia environment, the questions that cannot be settled by
reading the code:

  1. Does the package load at all?
  2. Does `structural_simplify` succeed, and how many states does it remove?
  3. Does the closed loop integrate?
  4. Is the solve linear-algebra bound or RHS bound? (settles ADR 0003)
  5. Where does the Jacobian spectrum sit? (settles the partition boundary question)
  6. Which parameters have a weak evidential basis?

DESIGN NOTE: every stage is wrapped. Nothing here is allowed to abort the run,
because the FIRST run is expected to fail and the whole value of that run is
learning exactly where. A diagnostic that dies at stage 1 and prints a stack trace
is worth less than one that reports "stage 1 failed: <reason>" and then honestly
reports that stages 2-6 were not reached.

Output goes to stdout and, when present, to the GitHub step summary so it is
readable without opening the log.
"""

const SUMMARY = get(ENV, "GITHUB_STEP_SUMMARY", "")

results = String[]

function emit(line::String = "")
    println(line)
    push!(results, line)
end

function flush_summary()
    isempty(SUMMARY) && return
    open(SUMMARY, "a") do io
        for l in results
            println(io, l)
        end
    end
end

"""Run a stage, capture any failure, never rethrow."""
function stage(name::String, f::Function)
    emit("### $name")
    emit()
    try
        f()
        emit()
        return true
    catch e
        emit("**FAILED**")
        emit()
        emit("```")
        emit(sprint(showerror, e))
        bt = catch_backtrace()
        for (i, frame) in enumerate(stacktrace(bt))
            i > 12 && (emit("  ... truncated"); break)
            emit("  " * string(frame))
        end
        emit("```")
        emit()
        return false
    end
end

emit("# IPE diagnostics")
emit()
emit("Julia $(VERSION) — $(Sys.CPU_THREADS) threads available")
emit()

# ---------------------------------------------------------------------------
loaded = stage("1. Package loads") do
    @eval using IPE
    @eval using ModelingToolkit, OrdinaryDiffEq, SciMLBase, LinearAlgebra
    emit("Loaded.")
end

if !loaded
    emit("Stages 2-6 not reached — nothing below is known.")
    flush_summary()
    exit(0)   # diagnostics never fail the build
end

# ---------------------------------------------------------------------------
sys = nothing
built = stage("2. Structural simplification") do
    global sys
    raw = @eval IPE.build_raw_model()
    n_before = length(unknowns(raw))
    sys = structural_simplify(raw)
    n_after = length(unknowns(sys))
    emit("| | states |")
    emit("|---|---|")
    emit("| before simplification | $n_before |")
    emit("| after simplification | $n_after |")
    emit("| removed | $(n_before - n_after) ($(round(100*(n_before-n_after)/max(n_before,1), digits=1))%) |")
    emit()
    emit("Remaining unknowns:")
    emit("```")
    for u in unknowns(sys)
        emit("  " * string(u))
    end
    emit("```")
end

built || (flush_summary(); exit(0))

# ---------------------------------------------------------------------------
sol = nothing
solved = stage("3. Closed loop integrates (60 days, nominal intake)") do
    global sol
    sol = IPE.solve_individual(sys; tspan_days = 60.0, saveat = 1.0)
    emit("retcode: `$(sol.retcode)`")
    emit()
    emit("| stat | value |")
    emit("|---|---|")
    emit("| RHS evaluations (nf) | $(sol.stats.nf) |")
    emit("| Jacobians (njacs) | $(sol.stats.njacs) |")
    emit("| factorisations (nw) | $(sol.stats.nw) |")
    emit("| accepted steps | $(sol.stats.naccept) |")
    emit("| rejected steps | $(sol.stats.nreject) |")
    emit()
    emit("Final state:")
    emit("```")
    for (u, v) in zip(unknowns(sys), sol.u[end])
        emit("  $(u) = $(round(v, sigdigits = 6))")
    end
    emit("```")
    emit()
    emit("**ADR 0007 check** — does the loop settle at nominal intake?")
    if length(sol.u) > 2
        drift = maximum(abs.((sol.u[end] .- sol.u[end-1]) ./ max.(abs.(sol.u[end]), 1e-9)))
        emit("Relative change over final day: $(round(drift, sigdigits=3))")
        emit(drift < 1e-3 ? "Settled." :
             "NOT settled — the derived ledger values (FR_Na, TPR, f_pv) may not be mutually consistent.")
    end
end

solved || (flush_summary(); exit(0))

# ---------------------------------------------------------------------------
stage("4. Cost profile — settles ADR 0003") do
    s = sol.stats
    ratio = s.nw > 0 ? s.nf / s.nw : Inf
    verdict = if s.nw == 0
        "no factorisations — non-stiff path taken; check solver selection"
    elseif ratio < 20
        "**LINEAR ALGEBRA BOUND** — partitioning to shrink the refactored block is the right lever. Multirate is worth its correctness risk."
    elseif ratio > 200
        "**RHS BOUND** — multirate buys little. Optimise generated code instead. ADR 0003 can be closed as Rejected."
    else
        "**MIXED** — profile per-window before committing."
    end
    emit("nf/nw = $(round(ratio, digits = 1))")
    emit()
    emit(verdict)
    emit()
    emit("Note this is a 3-component model. The verdict will shift as subsystems land — re-run before acting on it.")
end

# ---------------------------------------------------------------------------
stage("5. Timescale audit — partition boundary") do
    prob = ODEProblem(sys, [], (0.0, 1.0), [])
    u0 = prob.u0
    p = prob.p
    f = prob.f
    n = length(u0)
    J = zeros(n, n)
    if f.jac !== nothing
        f.jac(J, u0, p, 0.0)
    else
        emit("No analytic Jacobian available — **this is itself a finding**.")
        emit("`jac = true, sparse = true` was requested in solve_individual;")
        emit("if MTK is not generating one, the sparse-Jacobian speedup assumed")
        emit("throughout ADR 0001 is not actually being realised.")
        return
    end
    emit("Analytic Jacobian present. Density: $(round(100*count(!iszero, J)/max(n^2,1), digits=1))%")
    ev = eigvals(J)
    tau = sort([abs(real(e)) > 1e-14 ? 1/abs(real(e)) : Inf for e in ev])
    finite = filter(isfinite, tau)
    if isempty(finite)
        emit("No finite time constants — system is purely algebraic after simplification.")
        return
    end
    emit()
    emit("| | seconds |")
    emit("|---|---|")
    emit("| fastest tau | $(round(finite[1]*86400, sigdigits=3)) |")
    emit("| slowest tau | $(round(finite[end]*86400, sigdigits=3)) |")
    emit("| stiffness ratio | $(round(finite[end]/finite[1], sigdigits=3)) |")
    emit()
    if length(finite) > 1
        gaps = [(finite[i+1]/finite[i], finite[i], finite[i+1]) for i in 1:length(finite)-1]
        best = argmax(g -> g[1], gaps)
        emit("Largest spectral gap: $(round(best[1], digits=1))x")
        emit(best[1] < 10 ?
            "No clear gap — physiological timescales form a continuum, so any partition boundary is a modelling choice requiring `boundary_sensitivity` (ADR 0003)." :
            "Clear gap present — a partition boundary at $(round(sqrt(best[2]*best[3])*86400, sigdigits=3)) s is physiologically motivated.")
    end
end

# ---------------------------------------------------------------------------
stage("6. Weak-basis parameters — required disclosure") do
    weak = IPE.LedgerParams.unledgered_check()
    emit("$(length(weak)) of $(length(IPE.LedgerParams.PARAM_PROVENANCE)) parameters rest on `assumed` or `calibrated` values.")
    emit()
    emit("| parameter | method | note |")
    emit("|---|---|---|")
    for p in weak
        note = length(p.notes) > 110 ? first(p.notes, 110) * "…" : p.notes
        emit("| `$(p.param_id)` | $(p.method) | $(replace(note, "|" => "\\|")) |")
    end
    emit()
    emit("This table is the honest answer to \"how much of this model is actually known?\"")
    emit("It is a disclosure, not a failure.")
end

flush_summary()
