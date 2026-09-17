#
# STAGE 3 of validation/volume_natriuresis_form_prereg.md: form (B), the adapting
# rate-sensitive term, against the SAME discriminator that refuted form (A).
#
# Run:  julia --project=. bench/volume_natriuresis_stage3.jl
#
# PRE-REGISTERED, COMMITTED BEFORE THIS FILE EXISTED:
#     git log --diff-filter=A -- validation/volume_natriuresis_form_prereg.md
#     git log --diff-filter=A -- bench/volume_natriuresis_stage3.jl
#
# THE FORM. A slow state subtracts a fixed FRACTION of the sustained drive, so a
# rapid excursion sees the full gain and a sustained one sees (1 - k_adapt) of it.
# The acute-to-chronic ratio is 1/(1 - k_adapt) exactly, and HANDOVER 3.46 measured
# that the acute response needs about THREE times the chronic - so k_adapt = 2/3 is
# the value the requirement implies, not a value chosen to fit.
#
# THE PREDICTION, AND IT IS THE POINT. Form (B) is LINEAR in the excursion at every
# timescale, so it CANNOT bend the chronic relation. Section 3.1 refuted form (A) on
# exactly that bend - 12 to 20 percent of the MAP range, with the high-intake slope
# twice the low-intake one. Form (B) must come back at the linear form's 2.1 percent
# and a slope ratio near 1.11, OR IT IS NOT DOING WHAT THIS DOCUMENT SAYS IT DOES.
#
# SECTION 8's DECOMPOSITION IS MANDATORY and is the last block: the half-life the new
# FORM buys at the OLD gain, before any re-solve, so that structure and refit can be
# told apart.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf

const TARGET_H = 7.0          # Drummer 1992, PMID 1590419
const ANCHOR   = 1.9604       # the model's chronic salt sensitivity as merged
const G_OLD    = 585.0        # CV.ANP.NATRIURETIC_GAIN as it stands
const LEVELS   = (38.0, 68.0, 103.0, 154.0, 205.0, 230.0)

built = Dict{Any,Any}()
getsys(k, tau) = get!(built, (k, tau)) do
    k == 0.0 ? IPE.build_model() :
        IPE.build_model(anp_adaptation = true, anp_adapt_fraction = k,
                        anp_adapt_tau = tau)
end

function harness(k, tau, gain)
    sys = getsys(k, tau)
    U = unknowns(sys); O = observed(sys)
    pget(n) = (for p in parameters(sys); occursin(n, String(Symbol(p))) && return p; end;
               error(n))
    val(s, n, i) = begin
        for u in U; occursin(n, String(Symbol(u))) && return s[u][i]; end
        for o in O; occursin(n, String(Symbol(o.lhs))) && return s[o.lhs][i]; end
        NaN
    end
    base = Dict{Any,Any}(pget("G_anp") => gain)

    s0 = solve(ODEProblem(sys, collect(base), (0.0, 90.0), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10)
    n0 = length(s0.t); u0 = [u => s0[u][end] for u in U]
    Vecf0 = val(s0, "V_ecf", n0)
    fena0 = val(s0, "rn₊Na_excr", n0) /
            (val(s0, "rn₊GFR", n0) * val(s0, "bf₊C_Na", n0))

    # --- acute, Drummer's protocol: 2 L in 25 min --------------------------
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

    # --- Jensen's own final window, 23 mL/kg, 210-240 min on its clock -----
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

    # --- the chronic relation ---------------------------------------------
    maps = Float64[]; u = copy(u0); t0 = 0.0
    for lev in LEVELS
        pm2 = copy(base); pm2[pget("Na_intake")] = lev
        ss = solve(ODEProblem(sys, vcat(u, collect(pm2)), (t0, t0 + 40.0), Pair[]),
                   Rodas5P(); abstol = 1e-9, reltol = 1e-9)
        push!(maps, val(ss, "MAP", length(ss.t)))
        u = [x => ss[x][end] for x in U]; t0 += 40.0
    end
    (thalf = thalf, shift = (maps[5]-maps[3])/102*100, maps = maps, jensen = jensen)
end

function solve_gain(k, tau)
    lo, hi = 10.0, 60000.0
    (harness(k, tau, lo).shift - ANCHOR > 0 && harness(k, tau, hi).shift - ANCHOR < 0) ||
        error("anchor not bracketed at k = $k")
    g = lo; r = harness(k, tau, g)
    for _ in 1:40
        g = sqrt(lo*hi); r = harness(k, tau, g); f = r.shift - ANCHOR
        abs(f) < 0.001 && break
        if f > 0; lo = g; else; hi = g; end
        hi/lo < 1.0005 && break
    end
    (gain = g, r = r)
end

function curvature(maps)
    x = collect(LEVELS)
    line = [maps[1] + (maps[end]-maps[1])*(xi-x[1])/(x[end]-x[1]) for xi in x]
    (pct = 100*maximum(abs.(maps .- line))/abs(maps[end]-maps[1]),)
end
sloperatio(m) = ((m[3]-m[1])/(LEVELS[3]-LEVELS[1])) / ((m[6]-m[4])/(LEVELS[6]-LEVELS[4]))

println("="^100)
println("STAGE 3 - FORM (B), THE ADAPTING TERM, AGAINST THE SAME DISCRIMINATOR")
println("="^100)
@printf("  anchor %.4f held by re-solving G_anp;  target half-life %.0f h\n", ANCHOR, TARGET_H)
println("  form (A) for comparison: reached 7.55 h only at bend 19.8% and slope ratio 0.39")
println("  the LINEAR form sits at bend 2.1% and slope ratio 1.11 - that is 'straight'")
println()
@printf("  %-26s %9s %8s %9s %8s %8s %9s\n",
        "configuration", "G_anp", "t1/2 h", "salt sens", "bend %", "slope r", "Jensen %")
println("  " * "-"^96)

for (k, tau) in ((0.0, 1.0), (1/3, 1.0), (0.5, 1.0), (2/3, 1.0), (0.75, 1.0),
                 (2/3, 0.25), (2/3, 3.0))
    sg = solve_gain(k, tau)
    lab = k == 0.0 ? "linear (as merged)" : @sprintf("k=%.3f tau_adapt=%.2f d", k, tau)
    @printf("  %-26s %9.1f %8.2f %9.4f %7.1f%% %8.2f %9.1f\n",
            lab, sg.gain, sg.r.thalf, sg.r.shift, curvature(sg.r.maps).pct,
            sloperatio(sg.r.maps), sg.r.jensen)
end

println()
println("  SECTION 8's DECOMPOSITION - the FORM at the OLD gain, before any re-solve:")
r_old = harness(2/3, 1.0, G_OLD)
@printf("  %-26s %9.1f %8.2f %9.4f %28.1f\n",
        "k=0.667 at G_anp = 585", G_OLD, r_old.thalf, r_old.shift, r_old.jensen)
println("  ^^ If the half-life improves HERE, the structure did it. If it only improves")
println("     after the re-solve, the gain did it and the form is decoration.")
println("="^100)
