#
# STAGE 1 of validation/sodium_store_prereg.md. TURN IT ON AND LOOK. BUILDS NOTHING.
#
# Run:  julia --project=. bench/sodium_store_stage1.jl
#
# PRE-REGISTERED, COMMITTED BEFORE THIS FILE EXISTED:
#     git log --diff-filter=A -- validation/sodium_store_prereg.md
#     git log --diff-filter=A -- bench/sodium_store_stage1.jl
#
# ADR 0004's compartment is built, wired, PROVISIONAL and SWITCHED OFF. Nothing in the
# running model reads BF.NA.OSMOTICALLY_INACTIVE_FRACTION or BF.NA.STORAGE_TAU, which
# is why HANDOVER 3.47's stage 1 found them bit-identical from 0.1 d to 30 d. This is
# directive 1.11 in its purest form: the thing exists and nobody has turned it on.
#
# THE ENDPOINT IS THE RATIO, NOT EITHER HALF-LIFE. Drummer 1992 (PMID 1590419, full
# text) fits TWO monoexponentials to an acute isotonic load:
#
#     body weight back to baseline      7 h
#     sodium balance back to baseline  10 h      ratio 0.70 - WEIGHT COMES BACK FIRST
#
# The model's ratio is 1.065 because V_ecf is tied to Na_ecf and water cannot leave
# ahead of salt. Section 6 item 1: a configuration that hits 7 h on volume by dragging
# sodium to 7 h as well has reproduced NOTHING.
#
# THE MAPPING, AND IT IS WHAT MAKES THE STORE TESTABLE AT ALL. Drummer's sodium
# balance is intake minus urinary excretion - TOTAL body sodium retained, stored or
# not. So it maps to Na_total = Na_ecf + Na_store, NOT to Na_ecf. Body weight maps to
# V_ecf. If sodium moves into the store, Na_ecf falls while Na_total is still elevated,
# so volume comes back before sodium balance does. That is the mechanism under test.
#
using IPE, ModelingToolkit, OrdinaryDiffEq, Printf

const T_HALF_WEIGHT = 7.0
const T_HALF_SODIUM = 10.0
const TARGET_RATIO  = T_HALF_WEIGHT / T_HALF_SODIUM      # 0.70
const SALT_LO, SALT_HI = 1.70, 2.30
const DOSE_L = 30.0/1000 * 70.0                          # 30 mL/kg at 70 kg
const INF_D  = (25.0/60)/24                              # 25 min

built = Dict{Bool,Any}()
getsys(store) = get!(built, store) do
    store ? IPE.build_model(storage = true) : IPE.build_model()
end

function probe(store::Bool, ov::Dict{String,Float64})
    sys = getsys(store)
    U = unknowns(sys); O = observed(sys)
    pget(n) = (for p in parameters(sys); occursin(n, String(Symbol(p))) && return p; end;
               error(n))
    val(s, n, i) = begin
        for u in U; occursin(n, String(Symbol(u))) && return s[u][i]; end
        for o in O; occursin(n, String(Symbol(o.lhs))) && return s[o.lhs][i]; end
        NaN
    end
    base = Dict{Any,Any}(); for (k, v) in ov; base[pget(k)] = v; end

    s0 = solve(ODEProblem(sys, collect(base), (0.0, 120.0), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10)
    n0 = length(s0.t); u0 = [u => s0[u][end] for u in U]
    Vecf0 = val(s0, "V_ecf", n0)
    Nat0  = val(s0, "bf₊Na_total", n0)
    fena0 = val(s0, "rn₊Na_excr", n0) /
            (val(s0, "rn₊GFR", n0) * val(s0, "bf₊C_Na", n0))

    # --- Drummer's acute load ---------------------------------------------
    pm = copy(base)
    pm[pget("H2O_intake")] = 2.5 + DOSE_L/INF_D
    pm[pget("Na_intake")]  = 205.0 + 154.0*DOSE_L/INF_D
    s1 = solve(ODEProblem(sys, vcat(u0, collect(pm)), (0.0, INF_D), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10, saveat = INF_D/60)
    u1 = [x => s1[x][end] for x in U]
    s2 = solve(ODEProblem(sys, vcat(u1, collect(base)), (INF_D, 4.0), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10, saveat = 1/24/60)
    ts = Float64[]; dv = Float64[]; dn = Float64[]
    for s in (s1, s2), i in 1:length(s.t)
        push!(ts, s.t[i])
        push!(dv, val(s, "V_ecf", i) - Vecf0)
        push!(dn, val(s, "bf₊Na_total", i) - Nat0)
    end
    th(x) = begin
        ipk = argmax(x)
        ih = findfirst(i -> i > ipk && x[i] <= x[ipk]/2, 1:length(x))
        ih === nothing ? Inf : (ts[ih] - ts[ipk])*24
    end
    tv, tn = th(dv), th(dn)

    # --- Jensen's final window, 23 mL/kg, 210-240 min on its clock ---------
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
    jensen = isempty(acc) ? NaN : (sum(acc)/length(acc)/fena0 - 1)*100

    # --- chronic salt step -------------------------------------------------
    u = copy(u0); t0 = 0.0; maps = Float64[]
    for lev in (205.0, 154.0, 103.0)
        pm2 = copy(base); pm2[pget("Na_intake")] = lev
        ss = solve(ODEProblem(sys, vcat(u, collect(pm2)), (t0, t0 + 40.0), Pair[]),
                   Rodas5P(); abstol = 1e-9, reltol = 1e-9)
        push!(maps, val(ss, "MAP", length(ss.t)))
        u = [x => ss[x][end] for x in U]; t0 += 40.0
    end
    (tv = tv, tn = tn, ratio = tv/tn,
     shift = (maximum(maps) - minimum(maps))/102*100, jensen = jensen)
end

function row(lab, store, ov)
    r = probe(store, ov)
    ok_ratio = abs(r.ratio - TARGET_RATIO) <= 0.08
    ok_salt  = SALT_LO <= r.shift <= SALT_HI
    @printf("  %-34s %8.2f %8.2f %8.3f %9.4f %9.1f  %s\n",
            lab, r.tv, r.tn, r.ratio, r.shift, r.jensen,
            ok_ratio && ok_salt ? "<== BOTH" : ok_ratio ? "ratio only" :
            ok_salt ? "" : "salt OUT")
    r
end

W = 104
println("="^W)
println("SODIUM STORE - STAGE 1. TURN IT ON AND LOOK. NOTHING IS BUILT HERE.")
println("validation/sodium_store_prereg.md section 2")
println("="^W)
@printf("  Drummer 1992 (PMID 1590419, full text): weight %.0f h, sodium balance %.0f h, RATIO %.2f\n",
        T_HALF_WEIGHT, T_HALF_SODIUM, TARGET_RATIO)
@printf("  chronic salt sensitivity must stay inside %.2f-%.2f; Jensen's window measured %.0f%%\n\n",
        SALT_LO, SALT_HI, 122.0)
@printf("  %-34s %8s %8s %8s %9s %9s\n",
        "configuration", "t1/2 V", "t1/2 Na", "ratio", "salt sens", "Jensen %")
println("  " * "-"^100)

row("storage OFF (as merged)", false, Dict{String,Float64}())
println()
row("storage ON, ledger f=0.15 tau=7 d", true, Dict{String,Float64}())
println()
println("  tau_store swept at the ledger fraction f_store = 0.15:")
for v in (0.02, 0.05, 0.1, 0.25, 0.5, 1.0, 3.0, 7.0, 30.0)
    row("    tau_store = $v d", true, Dict("tau_store" => v))
end
println()
println("  f_store swept at the tau that did best above:")
for f in (0.05, 0.15, 0.30, 0.50, 0.70)
    row("    f_store = $f, tau = 0.05 d", true, Dict("f_store" => f, "tau_store" => 0.05))
end
println()
println("  and the joint corner - the largest store with the fastest kinetics:")
for (f, t) in ((0.70, 0.02), (0.90, 0.02), (0.90, 0.005))
    row("    f_store = $f, tau = $t d", true, Dict("f_store" => f, "tau_store" => t))
end


println("  REFINEMENT - where does the ratio actually cross 0.70?")
for (f, t) in ((0.35, 0.05), (0.40, 0.05), (0.45, 0.05), (0.40, 0.25))
    row("    f_store = $f, tau = $t d", true, Dict("f_store" => f, "tau_store" => t))
end
println()

println("\n" * "="^W)
println("READ THE RATIO COLUMN. Drummer's is 0.70 - weight comes back BEFORE sodium.")
println("A row that reaches 7 h on volume by dragging sodium to 7 h has reproduced nothing,")
println()
println("AND THE \"BOTH\" FLAG IS THE PRE-REGISTRATION'S S1 TEST, NOT A VERDICT. It checks the")
println("ratio and the chronic window, which is what section 5 branch S1 asks for. IT DOES NOT")
println("CHECK THAT EITHER HALF-LIFE IS RIGHT, and at the crossing neither is: Drummer wants")
println("7 h and 10 h, both FASTER than this model, and the store speeds volume while SLOWING")
println("sodium. It reproduces the ORDERING and not the SPEED. Read the first two columns.")
println("and a row that reaches the ratio outside 1.70-2.30 has solved nothing either.")
println("="^W)
