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

"""Run a stage, capture any failure, never rethrow.

Signature is (f, name) so that do-block syntax works:

    stage("1. Thing") do
        ...
    end

Julia's do-block passes the closure as the FIRST argument.
"""
function stage(f::Function, name::String)
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
# Loaded at top level rather than inside a stage closure: deferring via @eval
# left these names unresolvable in later closures.
emit("### 1. Package loads")
emit()
loaded = try
    using IPE
    using ModelingToolkit, OrdinaryDiffEq, SciMLBase, LinearAlgebra
    emit("Loaded.")
    emit()
    true
catch e
    emit("**FAILED**")
    emit()
    emit("```")
    emit(sprint(showerror, e))
    emit("```")
    emit()
    false
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
    raw = IPE.build_raw_model()
    # `unknowns` in ModelingToolkit v9+, `states` before that.
    nstates = IPE.mtk_unknowns
    n_before = length(nstates(raw))
    sys = IPE.mtk_simplify(raw)
    n_after = length(nstates(sys))
    emit("| | states |")
    emit("|---|---|")
    emit("| before simplification | $n_before |")
    emit("| after simplification | $n_after |")
    emit("| removed | $(n_before - n_after) ($(round(100*(n_before-n_after)/max(n_before,1), digits=1))%) |")
    emit()
    emit("Remaining unknowns:")
    emit("```")
    for u in nstates(sys)
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
    emit("| factorisations | $(hasproperty(sol.stats, :nw) ? sol.stats.nw : "n/a") |")
    emit("| accepted steps | $(sol.stats.naccept) |")
    emit("| rejected steps | $(sol.stats.nreject) |")
    emit()
    emit("Final state:")
    emit("```")
    for (u, v) in zip(IPE.mtk_unknowns(sys), sol.u[end])
        emit("  $(u) = $(round(v, sigdigits = 6))")
    end
    emit("```")
    emit()
    emit("**ADR 0007 check** — settles AND stays physiological?")
    emit()
    emit("Settling alone is not a pass. The first run of this loop settled to")
    emit("1.13e-6 at a state where intracellular water was zero. Both conditions")
    emit("are required.")
    emit()

    if length(sol.u) > 2
        drift = maximum(abs.((sol.u[end] .- sol.u[end-1]) ./ max.(abs.(sol.u[end]), 1e-9)))
        settled = drift < 1e-3
        emit("Relative change over final day: $(round(drift, sigdigits=3)) — " *
             (settled ? "settled" : "**NOT SETTLED**"))
    end

    # Physiological range assertions. Wide bounds - these catch catastrophe,
    # not fine calibration.
    ranges = Dict(
        "V_icf"  => (18.0, 32.0),      # L, 70 kg adult
        "V_ecf"  => (10.0, 20.0),      # L
        "Na_ecf" => (1400.0, 2600.0),  # mEq
    )
    emit()
    emit("| state | value | plausible range | |")
    emit("|---|---|---|---|")
    allok = true
    for (u, v) in zip(IPE.mtk_unknowns(sys), sol.u[end])
        nm = String(Symbol(u))
        for (key, (lo, hi)) in ranges
            if occursin(key, nm)
                ok = lo <= v <= hi
                allok &= ok
                emit("| `$key` | $(round(v, sigdigits=6)) | $lo – $hi | $(ok ? "ok" : "**OUT OF RANGE**") |")
            end
        end
    end
    emit()
    emit(allok ? "**PASS** — settles within physiological range." :
                 "**FAIL** — converged to a non-physiological state. The model " *
                 "runs and reports success while being wrong. Check " *
                 "`python tools/check_closure.py` first.")
end

solved || (flush_summary(); exit(0))

# ---------------------------------------------------------------------------
stage("3b. ADR 0007 falsifiable test — salt step") do
    emit("Mars500 design: sodium intake stepped 205 → 154 → 103 mEq/day,")
    emit("30 days per level, state carried across.")
    emit()
    emit("A step DOWN in intake must give: transient negative Na balance, a fall")
    emit("in ECF volume, a fall in pressure, and excretion returning to match the")
    emit("new intake AT A NEW, LOWER PRESSURE.")
    emit()
    emit("Re-equilibration at the SAME pressure means pressure natriuresis is")
    emit("inert — the model would be excreting whatever it is given, with no")
    emit("pressure regulation in it at all.")
    emit()

    r = IPE.salt_step()
    v = IPE.check_pressure_natriuresis(r)

    emit("| intake (mEq/d) | excretion | ECF (L) | MAP (mmHg) |")
    emit("|---|---|---|---|")
    for l in r.levels
        emit("| $(round(l.level, digits=1)) | $(round(l.Na_excr_final, digits=1)) " *
             "| $(round(l.V_ecf_final, digits=3)) | $(round(l.MAP_final, digits=2)) |")
    end
    emit()
    emit("| condition | result |")
    emit("|---|---|")
    emit("| excretion matches intake at each level | $(v.excretion_matches_intake ? "yes" : "**NO**") |")
    emit("| MAP differs between levels | $(v.map_shifts_between_levels ? "yes" : "**NO**") |")
    emit("| MAP range across levels | $(round(v.map_shift_mmHg, digits=2)) mmHg |")
    emit("| higher intake → higher pressure | $(v.higher_intake_higher_pressure ? "yes" : "**NO**") |")
    emit()
    if v.pass
        emit("**PASS** — the loop closes AND pressure natriuresis is load-bearing.")
        emit("This is the central claim of ADR 0007 demonstrated, not asserted.")
    else
        emit("**FAIL** — see conditions above.")
        if v.excretion_matches_intake && !v.map_shifts_between_levels
            emit("Excretion tracks intake but pressure does not move: the loop is")
            emit("closed but natriuresis is inert. Check RN.PRESSURE_NATRIURESIS.SLOPE")
            emit("and CV.VENOUS_RETURN.SENSITIVITY — together they are the loop gain.")
        end
    end
end

# ---------------------------------------------------------------------------
stage("4. Cost profile — settles ADR 0003") do
    s = sol.stats
    nw = hasproperty(s, :nw) ? s.nw : (hasproperty(s, :nsolve) ? s.nsolve : 0)
    ratio = nw > 0 ? s.nf / nw : Inf
    nstates = length(IPE.mtk_unknowns(sys))

    emit("nf = $(s.nf), factorisations = $nw, states = $nstates")
    emit("nf/nw = $(round(ratio, digits = 1))")
    emit()

    # A verdict needs enough work to have measured steady-state cost rather than
    # startup overhead. Below these thresholds the ratio reflects setup, not the
    # regime we are trying to identify.
    MIN_STATES = 20
    MIN_NF = 500
    if nstates < MIN_STATES || s.nf < MIN_NF
        emit("**NO VERDICT.** This run is too small to classify: $nstates states")
        emit("(need >= $MIN_STATES) and $(s.nf) RHS evaluations (need >= $MIN_NF).")
        emit("At this scale nf/nw measures startup overhead, not the cost regime.")
        emit()
        emit("**ADR 0003 remains Deferred.** Do not close it on this evidence.")
        emit("Re-run once several subsystems have landed.")
    elseif nw == 0
        emit("No factorisations — non-stiff path taken; check solver selection.")
    elseif ratio < 20
        emit("**LINEAR ALGEBRA BOUND** — partitioning to shrink the refactored")
        emit("block is the right lever. Multirate is worth its correctness risk.")
    elseif ratio > 200
        emit("**RHS BOUND** — multirate buys little. Optimise generated code")
        emit("instead. ADR 0003 can be closed as Rejected.")
    else
        emit("**MIXED** — profile per-window before committing.")
    end
end

# ---------------------------------------------------------------------------
stage("5. Timescale audit — partition boundary") do
    # MUST pass the same kwargs as solve_individual. An earlier version of this
    # stage built the problem WITHOUT jac = true and then reported "no analytic
    # Jacobian" as a finding about the model. It was a finding about the
    # diagnostic. Sparse is off here: for a handful of states the sparse path
    # costs more than it saves, and MTK's own docs say so.
    prob = ODEProblem(sys, Dict(), (0.0, 1.0); jac = true, sparse = false)
    u0 = prob.u0
    p = prob.p
    f = prob.f
    n = length(u0)
    J = zeros(n, n)
    jac_ok = try
        f.jac !== nothing && (f.jac(J, u0, p, 0.0); true)
    catch
        false
    end
    if !jac_ok
        emit("No analytic Jacobian available — **this is itself a finding**.")
        emit("`jac = true, sparse = true` was requested in solve_individual;")
        emit("if MTK is not generating one, the sparse-Jacobian speedup assumed")
        emit("throughout ADR 0001 is not actually being realised.")
        return
    end
    emit("Analytic Jacobian present. Density: $(round(100*count(!iszero, J)/max(n^2,1), digits=1))%")
    ev = eigvals(J)

    # Discard eigenvalues that are zero to within the conditioning of the matrix.
    # A conserved quantity gives an exactly-zero eigenvalue; numerically it comes
    # back as ~1e-19 and inverts to a time constant of 1e18 seconds - 140 billion
    # years. An earlier version of this stage cut at an absolute 1e-14, let that
    # through, and then reported a "clear spectral gap" at 5.75e11 s as
    # physiologically motivated. It was numerical noise. Scale the cutoff to the
    # largest eigenvalue instead.
    scale = maximum(abs.(real.(ev)); init = 0.0)
    cutoff = max(scale * 1e-10, 1e-30)
    n_conserved = count(e -> abs(real(e)) <= cutoff, ev)
    tau = sort([1/abs(real(e)) for e in ev if abs(real(e)) > cutoff])

    if n_conserved > 0
        emit("$n_conserved eigenvalue(s) at zero to within conditioning — discarded.")
        emit("These are CONSERVED QUANTITIES, not slow dynamics. Inverting them")
        emit("gives spurious time constants of order 1e18 s.")
        emit()
    end

    finite = tau
    if isempty(finite)
        emit("No dynamic modes — the system is purely conserved or algebraic.")
        return
    end
    if length(finite) < 3
        emit("Only $(length(finite)) dynamic mode(s). Too few for a meaningful")
        emit("spectral gap analysis — a gap between two modes says nothing about")
        emit("where a partition boundary belongs.")
        emit()
        emit("| mode | tau (s) |")
        emit("|---|---|")
        for (i, t) in enumerate(finite)
            emit("| $i | $(round(t*86400, sigdigits=4)) |")
        end
        emit()
        emit("**ADR 0003 partition boundary: UNDETERMINED.** Re-run with more subsystems.")
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
        # Sanity-bound any claimed boundary: nothing in this model is slower
        # than remodelling (weeks) or faster than baroreflex (~1 s). A proposed
        # boundary outside that window is an artefact, not physiology.
        boundary_s = sqrt(best[2]*best[3]) * 86400
        plausible = 0.1 <= boundary_s <= 30*86400
        if best[1] < 10
            emit("No clear gap — physiological timescales form a continuum, so any")
            emit("partition boundary is a modelling choice requiring")
            emit("`boundary_sensitivity` (ADR 0003).")
        elseif !plausible
            emit("Gap implies a boundary at $(round(boundary_s, sigdigits=3)) s, which is")
            emit("outside any physiological timescale in this model (0.1 s – 30 d).")
            emit("**This is a numerical artefact, not a finding.** Ignore it.")
        else
            emit("Clear gap — a partition boundary at $(round(boundary_s, sigdigits=3)) s")
            emit("is physiologically motivated. Still requires `boundary_sensitivity`")
            emit("before it is trusted (ADR 0003).")
        end
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
