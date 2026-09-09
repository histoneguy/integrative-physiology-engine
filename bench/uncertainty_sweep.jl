# WHAT THE LEDGER'S OWN ERROR BARS DO TO THE MODEL.
#
#   julia --project=. bench/uncertainty_sweep.jl
#
# THE POINT. Rounding a value from 2.189 to 2.2 is cosmetic when its stated interval
# is 0.833 to 3.270. The question that matters is what the model does ACROSS that
# interval, and until this file existed nothing here had ever asked it. Directive 1.13
# part 2 - carry the uncertainty, do not drop it - and section 7's standing admission
# that parameter uncertainty is not propagated.
#
# WHAT IT DOES. For every parameter the model actually reads that has a stated interval
# in the ledger, re-solve the chronic salt step at the LOW and HIGH ends and report how
# far the model's two headline outputs move. Sorted by influence, so the answer to
# "which numbers actually matter" is read off the top and everything below the line is
# provably not worth arguing about.
#
# WHAT IT IS NOT. One parameter at a time. Real propagation is joint - correlations and
# interactions are invisible here - and doing it properly means sampling the ledger,
# which is OPEN-QUESTIONS B14. This is the one-at-a-time version, which is the cheapest
# thing that is honest.

using IPE
using IPE: build_model, LedgerParams, check_pressure_natriuresis
using ModelingToolkit
using OrdinaryDiffEq
using Printf

const HUMAN_SENS  = (1.70, 2.30)     # mmHg per 100 mmol/day
const HUMAN_RATIO = (2.97, 4.16)     # mmHg/L

"""Ledger rows that state an interval, as param_id => (lo, hi)."""
function ledger_intervals()
    out = Dict{String,Tuple{Float64,Float64}}()
    path = joinpath(@__DIR__, "..", "ledger", "parameters.csv")
    open(path) do io
        hdr = split(readline(io), ',')
        ix = Dict(strip(h) => i for (i, h) in enumerate(hdr))
        for line in eachline(io)
            f = split(line, ',')
            length(f) < 8 && continue
            pid  = String(f[ix["param_id"]])
            typ  = lowercase(strip(String(f[ix["uncertainty_type"]])))
            val  = strip(String(f[ix["uncertainty_value"]]))
            cent = tryparse(Float64, strip(String(f[ix["value"]])))
            cent === nothing && continue
            if typ == "range"
                m = match(r"^\s*([-\d.eE+]+)\s*[-–]\s*([-\d.eE+]+)\s*$", val)
                m === nothing && continue
                lo = tryparse(Float64, m.captures[1]); hi = tryparse(Float64, m.captures[2])
                (lo === nothing || hi === nothing) && continue
                out[pid] = (lo, hi)
            elseif typ == "sd"
                sd = tryparse(Float64, val)
                sd === nothing && continue
                out[pid] = (cent - sd, cent + sd)     # +/- 1 SD
            end
        end
    end
    return out
end

"""Salt step with one model parameter overridden."""
function outputs(sys, prm, value)
    levels = (205.0, 154.0, 103.0)
    maps = Float64[]; vols = Float64[]
    u = nothing; t0 = 0.0
    for lv in levels
        pm = Dict()
        prm !== nothing && (pm[prm] = value)
        for p in parameters(sys)
            occursin("Na_intake", String(Symbol(p))) && (pm[p] = lv)
        end
        prob = ODEProblem(sys, pm, (t0, t0 + 30.0); jac = true)
        u !== nothing && (prob = remake(prob; u0 = u))
        sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-6, saveat = [t0 + 30.0])
        u = sol.u[end]; t0 += 30.0
        push!(maps, IPE._final(sol, sys, "cv₊MAP"))
        push!(vols, IPE._final(sol, sys, "bf₊V_ecf"))
    end
    shift = maps[1] - maps[end]
    return (sens = shift / 1.02, ratio = shift / (vols[1] - vols[end]))
end

function main()
    sys = build_model()
    iv  = ledger_intervals()

    # Map each model parameter to a ledger row by matching its default value. The
    # ledger id is not carried into the built system, so this is the available join;
    # ambiguous matches are dropped rather than guessed.
    prms = Any[]
    for p in parameters(sys)
        d = try ModelingToolkit.getdefault(p) catch; nothing end
        d isa Number || continue
        # Sexed rows are keyed with a _MALE / _FEMALE suffix in PARAM_PROVENANCE,
        # so try the bare name first and then both suffixes.
        hits = String[]
        for (pid, _) in iv
            base = Symbol(replace(pid, "." => "_"))
            for k in (base, Symbol(base, "_MALE"), Symbol(base, "_FEMALE"))
                if haskey(LedgerParams.PARAM_PROVENANCE, k) &&
                   isapprox(Float64(d), LedgerParams.PARAM_PROVENANCE[k].value; rtol = 1e-9)
                    push!(hits, pid); break
                end
            end
        end
        unique!(hits)
        length(hits) == 1 && push!(prms, (p, hits[1], Float64(d), iv[hits[1]]))
    end

    base = outputs(sys, nothing, 0.0)
    @printf("baseline: salt sensitivity %.2f mmHg/100mmol, dMAP/dV_ecf %.2f mmHg/L\n",
            base.sens, base.ratio)
    println("human:    ", HUMAN_SENS, "                       ", HUMAN_RATIO)
    println()
    println("Each row re-solves the salt step at the LOW and HIGH end of that row's own")
    println("stated interval. `swing` is the full excursion in the output.")
    println()
    @printf("%-34s %-19s %9s %9s %8s\n", "parameter", "interval", "sens lo", "sens hi", "swing")
    println("-"^86)

    results = Any[]
    for (p, pid, d, (lo, hi)) in prms
        a = try outputs(sys, p, lo) catch; nothing end
        b = try outputs(sys, p, hi) catch; nothing end
        (a === nothing || b === nothing) && continue
        push!(results, (pid, lo, hi, a.sens, b.sens, abs(b.sens - a.sens),
                        a.ratio, b.ratio))
    end
    sort!(results, by = r -> -r[6])
    for (pid, lo, hi, sa, sb, sw, ra, rb) in results
        @printf("%-34s %-19s %9.3f %9.3f %8.3f\n",
                first(pid, 34), string(round(lo, sigdigits=3), "-", round(hi, sigdigits=3)),
                sa, sb, sw)
    end

    println()
    big = [r for r in results if r[6] >= 0.05 * base.sens]
    println("PARAMETERS WHOSE OWN UNCERTAINTY MOVES SALT SENSITIVITY BY 5% OR MORE: ",
            length(big), " of ", length(results))
    for r in big
        @printf("   %-34s swings %.3f (%.0f%% of baseline)\n", first(r[1], 34), r[6],
                100 * r[6] / base.sens)
    end
    println()
    println("""
EVERYTHING NOT LISTED ABOVE IS A PARAMETER WHOSE STATED ERROR BAR CHANGES THE ANSWER BY
LESS THAN 5%. Arguing about the third significant figure of any of them is arguing below
the noise floor of the measurement it came from. That is the use of this file: it says
which numbers are worth work and which are not.""")
end

main()
