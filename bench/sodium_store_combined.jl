#
# THE COMBINED SWEEP of validation/sodium_store_structure_prereg.md.
#
# Run:  julia --project=. bench/sodium_store_combined.jl
#
# PRE-REGISTERED, COMMITTED BEFORE THIS FILE EXISTED:
#     git log --diff-filter=A -- validation/sodium_store_structure_prereg.md
#     git log --diff-filter=A -- bench/sodium_store_combined.jl
#
# THE QUESTION. Section 1: the store SLOWS sodium, because sodium parked in the
# compartment is still in the body and still counts in a balance. So landing Drummer's
# sodium half-life of 10 h WITH the store on needs the underlying clearance faster by
# roughly 1.4x - and the form pass measured gains x1.5 giving a chronic salt
# sensitivity of 1.31 against a human 1.70-2.30. SO THERE MAY BE NO CONFIGURATION THAT
# SATISFIES BOTH HALF-LIVES AND THE CHRONIC WINDOW AT ONCE. This sweep answers that.
#
# SECTION 3's LICENCE IS NARROW AND IS THE REASON THIS IS SAFE TO RUN. A natriuretic
# gain may be SWEPT here; NO GAIN MAY BE ADOPTED. Both rows end this pass at the values
# they start it with whatever the table shows. Every pre-registration since 3.49 has
# forbidden even the sweep, because 3.49 withdrew a published conclusion for reading a
# water defect as a sodium one; that error is now understood rather than merely avoided.
#
# SECTION 7 ITEM 2: BOTH HALF-LIVES ARE REPORTED, NOT ONLY THEIR RATIO. Section 3.50
# already produced a configuration where the ratio was right and neither half-life was.
#
using IPE, ModelingToolkit, OrdinaryDiffEq, Printf

const T_V, T_NA = 7.0, 10.0                 # Drummer 1992, PMID 1590419
const TOL_V, TOL_NA = 1.5, 2.0              # what counts as landing
const SALT_LO, SALT_HI = 1.70, 2.30
const G_PN0, G_ANP0 = 8.4, 585.0
const DOSE_L = 30.0/1000 * 70.0
const INF_D  = (25.0/60)/24

sys = IPE.build_model(storage = true)
const U = unknowns(sys); const O = observed(sys)
pget(n) = (for p in parameters(sys); occursin(n, String(Symbol(p))) && return p; end; error(n))
val(s, n, i) = begin
    for u in U; occursin(n, String(Symbol(u))) && return s[u][i]; end
    for o in O; occursin(n, String(Symbol(o.lhs))) && return s[o.lhs][i]; end
    NaN
end

function probe(f, tau, k)
    base = Dict{Any,Any}(pget("f_store") => f, pget("tau_store") => tau,
                         pget("G_pn") => G_PN0*k, pget("G_vn") => G_ANP0*k)
    s0 = solve(ODEProblem(sys, collect(base), (0.0, 120.0), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10)
    n0 = length(s0.t); u0 = [u => s0[u][end] for u in U]
    Vecf0 = val(s0, "V_ecf", n0); Nat0 = val(s0, "bf₊Na_total", n0)
    fena0 = val(s0, "rn₊Na_excr", n0) /
            (val(s0, "rn₊GFR", n0) * val(s0, "bf₊C_Na", n0))

    pm = copy(base)
    pm[pget("H2O_intake")] = 2.5 + DOSE_L/INF_D
    pm[pget("Na_intake")]  = 205.0 + 154.0*DOSE_L/INF_D
    a1 = solve(ODEProblem(sys, vcat(u0, collect(pm)), (0.0, INF_D), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10, saveat = INF_D/60)
    ua = [x => a1[x][end] for x in U]
    a2 = solve(ODEProblem(sys, vcat(ua, collect(base)), (INF_D, 4.0), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10, saveat = 1/24/60)
    ts = Float64[]; dv = Float64[]; dn = Float64[]
    for s in (a1, a2), i in 1:length(s.t)
        push!(ts, s.t[i]); push!(dv, val(s, "V_ecf", i) - Vecf0)
        push!(dn, val(s, "bf₊Na_total", i) - Nat0)
    end
    th(x) = begin
        ipk = argmax(x)
        ih = findfirst(i -> i > ipk && x[i] <= x[ipk]/2, 1:length(x))
        ih === nothing ? Inf : (ts[ih] - ts[ipk])*24
    end
    tv, tn = th(dv), th(dn)

    volj = 0.023*70.0; durj = 1/24
    pj = copy(base)
    pj[pget("H2O_intake")] = 2.5 + volj/durj
    pj[pget("Na_intake")]  = 205.0 + 154.0*volj/durj
    j1 = solve(ODEProblem(sys, vcat(u0, collect(pj)), (0.0, durj), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10, saveat = 1/24/60)
    uj = [x => j1[x][end] for x in U]
    j2 = solve(ODEProblem(sys, vcat(uj, collect(base)), (durj, durj + 4/24), Pair[]),
               Rodas5P(); abstol = 1e-10, reltol = 1e-10, saveat = 1/24/60)
    acc = Float64[]
    for s in (j1, j2), i in 1:length(s.t)
        tm = s.t[i]*24*60
        120.0 <= tm <= 150.0 &&
            push!(acc, val(s, "rn₊Na_excr", i) /
                       (val(s, "rn₊GFR", i) * val(s, "bf₊C_Na", i)))
    end
    jen = isempty(acc) ? NaN : (sum(acc)/length(acc)/fena0 - 1)*100

    u = copy(u0); t0 = 0.0; maps = Float64[]
    for lev in (205.0, 154.0, 103.0)
        p2 = copy(base); p2[pget("Na_intake")] = lev
        ss = solve(ODEProblem(sys, vcat(u, collect(p2)), (t0, t0 + 40.0), Pair[]),
                   Rodas5P(); abstol = 1e-9, reltol = 1e-9)
        push!(maps, val(ss, "MAP", length(ss.t)))
        u = [x => ss[x][end] for x in U]; t0 += 40.0
    end
    (tv = tv, tn = tn, shift = (maximum(maps) - minimum(maps))/102*100, jen = jen)
end

W = 96
println("="^W)
println("THE COMBINED SWEEP - store x natriuretic gain")
println("validation/sodium_store_structure_prereg.md sections 1 and 3")
println("="^W)
@printf("  Drummer: volume %.0f h AND sodium %.0f h. Landing = within %.1f and %.1f h.\n",
        T_V, T_NA, TOL_V, TOL_NA)
@printf("  Chronic salt sensitivity must stay inside %.2f-%.2f. Jensen measured 122%%.\n",
        SALT_LO, SALT_HI)
println("  NO GAIN IS ADOPTED HERE - section 3. This table is a diagnostic.")
println()
@printf("  %-6s %-6s %-6s %8s %8s %8s %9s %8s  %s\n",
        "f_st", "tau_d", "gain", "t1/2 V", "t1/2 Na", "ratio", "salt", "Jensen", "verdict")
println("  " * "-"^92)

hits = []
for f in (0.0, 0.20, 0.40, 0.60), tau in (0.05, 0.25), k in (1.0, 1.5, 2.0)
    r = probe(f, tau, k)
    okv = abs(r.tv - T_V)  <= TOL_V
    okn = abs(r.tn - T_NA) <= TOL_NA
    oks = SALT_LO <= r.shift <= SALT_HI
    verdict = okv && okn && oks ? "<== ALL THREE" :
              okv && okn        ? "half-lives, salt OUT" :
              oks               ? "" : "salt OUT"
    (okv && okn && oks) && push!(hits, (f, tau, k))
    @printf("  %-6.2f %-6.2f %-6.2f %8.2f %8.2f %8.3f %9.4f %8.1f  %s\n",
            f, tau, k, r.tv, r.tn, r.tv/r.tn, r.shift, r.jen, verdict)
end

println()
println("="^W)
if isempty(hits)
    println("NO CONFIGURATION SATISFIES BOTH HALF-LIVES AND THE CHRONIC WINDOW.")
    println("That is section 1's declared expectation and section 8's 'quiet failure' warns")
    println("against reading it as a failure to find something. It says the model's acute and")
    println("chronic constraints are in genuine tension - a claim ABOUT THE MODEL.")
else
    println("CONFIGURATIONS SATISFYING ALL THREE: ", hits)
    println("Section 6 branch X2: report in full, ADOPT NOTHING, pre-register the follow-up.")
end
println("="^W)
