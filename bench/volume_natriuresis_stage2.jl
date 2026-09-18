#
# STAGE 2 of validation/volume_natriuresis_form_prereg.md: form (A), the static
# convex nonlinearity, and section 3.1's discriminator.
#
# Run:  julia --project=. bench/volume_natriuresis_stage2.jl
#
# PRE-REGISTERED, COMMITTED BEFORE THIS FILE EXISTED:
#     git log --diff-filter=A -- validation/volume_natriuresis_form_prereg.md
#     git log --diff-filter=A -- bench/volume_natriuresis_stage2.jl
#
# THE DISCRIMINATOR, FIXED IN ADVANCE. Section 3.1: a gain that rises with the
# excursion makes the CHRONIC pressure-sodium relation BEND - at high intake the
# larger extracellular excursion recruits a disproportionately larger natriuresis, so
# pressure rises less per mmol and the relation becomes CONCAVE. An adapting,
# rate-sensitive term, form (B), leaves it straight. The human relation is
# approximately linear across 38-230 mmol/day and all three meta-analyses quote a
# SINGLE slope per 100 mmol/day, which is itself a linearity assumption.
#
# So: build (A) steep enough to deliver the required factor of three, then measure the
# curvature it imposes. The pre-registration records in advance the expectation that
# (A) WILL BE REFUTED, so that agreeing with that is not evidence.
#
# G_vn IS RE-SOLVED FOR EVERY c_anp, AGAINST THE CHRONIC ANCHOR AND NOTHING ELSE.
# Section 4 permits exactly that and forbids solving anything against the 7 h
# half-life. Without the re-solve, a convex term would be testing a model whose
# chronic behaviour had silently moved.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf

const TARGET_H  = 7.0        # Drummer 1992, PMID 1590419
const ANCHOR    = 1.9604     # the model's chronic salt sensitivity as merged
const LEVELS    = (38.0, 68.0, 103.0, 154.0, 205.0, 230.0)

built = Dict{Float64,Any}()
getsys(c) = get!(built, c) do
    IPE.build_model(anp_convexity = c)
end

function harness(c::Float64, gain::Float64)
    sys = getsys(c)
    U = unknowns(sys); O = observed(sys)
    pget(n) = (for p in parameters(sys); occursin(n, String(Symbol(p))) && return p; end;
               error(n))
    val(s, n, i) = begin
        for u in U; occursin(n, String(Symbol(u))) && return s[u][i]; end
        for o in O; occursin(n, String(Symbol(o.lhs))) && return s[o.lhs][i]; end
        NaN
    end
    base = Dict{Any,Any}(pget("G_vn") => gain)

    s0 = solve(ODEProblem(sys, collect(base), (0.0, 60.0), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10)
    n0 = length(s0.t); u0 = [u => s0[u][end] for u in U]
    Vecf0 = val(s0, "V_ecf", n0)

    # --- acute, Drummer's protocol -----------------------------------------
    dur = (25/60)/24
    pm = copy(base)
    pm[pget("H2O_intake")] = 2.5 + 2.0/dur
    pm[pget("Na_intake")]  = 205.0 + 154.0*2.0/dur
    s1 = solve(ODEProblem(sys, vcat(u0, collect(pm)), (0.0, dur), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10, saveat = dur/60)
    u1 = [x => s1[x][end] for x in U]
    s2 = solve(ODEProblem(sys, vcat(u1, collect(base)), (dur, 5.0), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10, saveat = 1/24/60)
    ts = Float64[]; dv = Float64[]
    for s in (s1, s2), i in 1:length(s.t)
        push!(ts, s.t[i]); push!(dv, val(s, "V_ecf", i) - Vecf0)
    end
    ipk = argmax(dv)
    ih = findfirst(i -> i > ipk && dv[i] <= dv[ipk]/2, 1:length(dv))
    thalf = ih === nothing ? Inf : (ts[ih] - ts[ipk])*24

    # --- the chronic RELATION, not just its endpoints ----------------------
    maps = Float64[]
    u = copy(u0); t0 = 0.0
    for lev in LEVELS
        pm2 = copy(base); pm2[pget("Na_intake")] = lev
        ss = solve(ODEProblem(sys, vcat(u, collect(pm2)), (t0, t0 + 40.0), Pair[]),
                   Rodas5P(); abstol = 1e-9, reltol = 1e-9)
        push!(maps, val(ss, "MAP", length(ss.t)))
        u = [x => ss[x][end] for x in U]; t0 += 40.0
    end
    shift = (maps[5] - maps[3]) / 102 * 100      # the 103 -> 205 anchor step
    (thalf = thalf, shift = shift, maps = maps)
end

"""
Solve G_vn so the chronic anchor is reproduced. Section 4's only licensed fit.

BISECTION, NOT SECANT, AND THE FIRST VERSION OF THIS FILE USED A SECANT THAT DID NOT
CONVERGE. At c_anp = 100 and 200 it left the anchor at 1.887 against 1.9604 - 3.6%
out - so the curvature was being read off a model whose chronic behaviour had moved,
which is the exact confound the re-solve exists to prevent. Bracket and bisect: the
shift is monotone decreasing in the gain, which is what makes this safe.
"""
function solve_gain(c::Float64)
    lo, hi = 10.0, 40000.0
    flo = harness(c, lo).shift - ANCHOR       # > 0: too little natriuresis
    fhi = harness(c, hi).shift - ANCHOR       # < 0
    (flo > 0 && fhi < 0) || error("anchor not bracketed at c_anp = $c")
    g = lo; r = harness(c, g)
    for _ in 1:40
        g = sqrt(lo*hi)                        # geometric: the gain spans 3 decades
        r = harness(c, g); f = r.shift - ANCHOR
        abs(f) < 0.001 && break
        if f > 0; lo = g; else; hi = g; end
        hi/lo < 1.0005 && break
    end
    (gain = g, r = r)
end

"Max deviation from a straight line through the endpoints, as % of the MAP range."
function curvature(maps)
    x = collect(LEVELS)
    lo, hi = maps[1], maps[end]
    line = [lo + (hi - lo)*(xi - x[1])/(x[end] - x[1]) for xi in x]
    rng = abs(hi - lo)
    (maxdev = maximum(abs.(maps .- line)), pct = 100*maximum(abs.(maps .- line))/rng)
end

println("="^92)
println("STAGE 2 - FORM (A), THE STATIC CONVEX NONLINEARITY, AND SECTION 3.1's TEST")
println("="^92)
@printf("  anchor: chronic salt sensitivity held at %.4f by re-solving G_vn\n", ANCHOR)
@printf("  target: acute volume half-life %.0f h (Drummer 1992, PMID 1590419)\n", TARGET_H)
println("  chronic relation sampled at 38, 68, 103, 154, 205, 230 mmol/day")
println()
@printf("  %-10s %9s %8s %9s %10s %10s\n",
        "c_anp", "G_vn", "t1/2 h", "salt sens", "bend mmHg", "bend %")
println("  " * "-"^88)

results = []
for c in (0.0, 50.0, 100.0, 200.0, 400.0)
    sg = solve_gain(c)
    cv = curvature(sg.r.maps)
    @printf("  %-10.0f %9.1f %8.2f %9.4f %10.3f %9.1f%%\n",
            c, sg.gain, sg.r.thalf, sg.r.shift, cv.maxdev, cv.pct)
    push!(results, (c = c, gain = sg.gain, thalf = sg.r.thalf,
                    maps = sg.r.maps, pct = cv.pct))
end

println()
println("  THE CHRONIC RELATION ITSELF, MAP in mmHg at each intake:")
@printf("  %-10s", "c_anp")
for l in LEVELS; @printf("%9.0f", l); end
println()
for r in results
    @printf("  %-10.0f", r.c)
    for m in r.maps; @printf("%9.3f", m); end
    println()
end

println()
println("  LOCAL SLOPE, mmHg per 100 mmol/day, low end against high end:")
@printf("  %-10s %14s %14s %10s\n", "c_anp", "38->103", "154->230", "ratio")
for r in results
    lo = (r.maps[3] - r.maps[1]) / (LEVELS[3] - LEVELS[1]) * 100
    hi = (r.maps[6] - r.maps[4]) / (LEVELS[6] - LEVELS[4]) * 100
    @printf("  %-10.0f %14.4f %14.4f %10.2f\n", r.c, lo, hi, lo/hi)
end
println()
println("  A RATIO OF 1.00 IS A STRAIGHT LINE. The human relation is quoted as a single")
println("  slope per 100 mmol/day by Cutler 1997, He 2013 and He 2002 alike, which is a")
println("  linearity assumption those analyses make across the whole dietary range.")
println("="^92)
