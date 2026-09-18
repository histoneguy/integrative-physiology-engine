#
# THE LATE TIME COURSE OF AN ACUTE ISOTONIC SODIUM LOAD.
#
# Run:  julia --project=. bench/late_time_course.jl
#
# PRE-REGISTERED IN validation/late_time_course_prereg.md, COMMITTED BEFORE THIS FILE
# EXISTED:
#     git log --diff-filter=A -- validation/late_time_course_prereg.md
#     git log --diff-filter=A -- bench/late_time_course.jl
#
# THE SOURCE. Drummer C, Gerzer R, Heer M, Molz B, Bie P, Schlossberger M, Stadaeger C,
# Roecker L, Strollo F, Heyduck B, et al. Effects of an acute saline infusion on fluid
# and electrolyte metabolism in humans. Am J Physiol 1992;262(5 Pt 2):F744-54.
# PMID 1590419. ABSTRACT READ IN FULL. Six healthy volunteers, SUPINE, strictly
# controlled, 9 days and nights, 2 litres of isotonic saline in 25 min, 48 h of
# collections AND a 48 h control experiment. It prints one number this model can be
# tested against: elevated body weight returned to baseline "with an approximate
# half-life of 7 h".
#
# THIS IS NOT THE OTHER DRUMMER 1992. PMID 1324562 (Acta Physiol Scand Suppl) is the
# head-down-tilt study, and HDT is its experimental variable; the pre-registration
# admits only its control arm. This one has no tilt at all.
#
# WHY THE HALF-LIFE IS THE RIGHT TEST. validation/late_time_course_prereg.md section 2
# argues that the tail of an acute load is set by the natriuretic GAINS and not by
# RN.ANP.TAU, and section 7 item 6 requires that to be DEMONSTRATED BY RUNNING rather
# than asserted. That is what the sweeps below are.
#
# section 7 item 6 of validation/late_time_course_prereg.md: the claim that the TAIL is
# GAIN and not LAG must be DEMONSTRATED BY RUNNING, not asserted.
#
# For each configuration: the volume-excursion half-life after 2 L of 0.9% saline in
# 25 min (Drummer 1992 AJP, PMID 1590419, measured ~7 h) and the chronic salt
# sensitivity (human window 1.70-2.30 mmHg per 100 mmol/day).
#
using IPE, ModelingToolkit, OrdinaryDiffEq, Printf

sys = IPE.build_model()
U = unknowns(sys); O = observed(sys)
pget(n) = (for p in parameters(sys); occursin(n, String(Symbol(p))) && return p; end; error(n))
val(s, n, i) = begin
    for u in U; occursin(n, String(Symbol(u))) && return s[u][i]; end
    for o in O; occursin(n, String(Symbol(o.lhs))) && return s[o.lhs][i]; end
    NaN
end
const G_PN0  = 8.4
const G_ANP0 = 585.0
const TAU0   = 0.15

function run(; gpn = G_PN0, ganp = G_ANP0, tau = TAU0, sgfr = nothing)
    base = Dict{Any,Any}(pget("G_pn") => gpn, pget("G_vn") => ganp,
                         pget("tau_vn") => tau)
    sgfr === nothing || (base[pget("S_gfr_v")] = sgfr)
    s0 = solve(ODEProblem(sys, collect(base), (0.0, 60.0), Pair[]), Rodas5P();
               abstol=1e-10, reltol=1e-10)
    n0 = length(s0.t); u0 = [u => s0[u][end] for u in U]
    Vecf0 = val(s0,"V_ecf",n0)

    # --- acute: 2 L in 25 min, volume-excursion half-life -------------------
    dur = (25/60)/24
    pm = copy(base)
    pm[pget("H2O_intake")] = 2.5 + 2.0/dur
    pm[pget("Na_intake")]  = 205.0 + 154.0*2.0/dur
    s1 = solve(ODEProblem(sys, vcat(u0, collect(pm)), (0.0, dur), Pair[]), Rodas5P();
               abstol=1e-10, reltol=1e-10, saveat=dur/60)
    u1 = [x => s1[x][end] for x in U]
    s2 = solve(ODEProblem(sys, vcat(u1, collect(base)), (dur, 5.0), Pair[]), Rodas5P();
               abstol=1e-10, reltol=1e-10, saveat=1/24/60)
    ts=Float64[]; dv=Float64[]
    for s in (s1,s2), i in 1:length(s.t)
        push!(ts, s.t[i]); push!(dv, val(s,"V_ecf",i) - Vecf0)
    end
    ipk = argmax(dv); peak = dv[ipk]
    h = findfirst(i -> i > ipk && dv[i] <= peak/2, 1:length(dv))
    thalf = h === nothing ? NaN : (ts[h]-ts[ipk])*24

    # --- chronic salt sensitivity ------------------------------------------
    u = copy(u0); t0 = 0.0; maps = Float64[]
    for lev in (205.0, 154.0, 103.0)
        pm2 = copy(base); pm2[pget("Na_intake")] = lev
        ss = solve(ODEProblem(sys, vcat(u, collect(pm2)), (t0, t0+30.0), Pair[]),
                   Rodas5P(); abstol=1e-9, reltol=1e-9)
        push!(maps, val(ss,"MAP",length(ss.t)))
        u = [x => ss[x][end] for x in U]; t0 += 30.0
    end
    shift = (maximum(maps)-minimum(maps))/102*100
    (thalf = thalf, shift = shift, peak = peak)
end

println("="^80)
println("DOES THE TAIL RESPOND TO THE LAG OR TO THE GAINS?")
println("Drummer 1992 AJP (PMID 1590419): body weight half-life about 7 h")
println("Human chronic salt sensitivity: 1.70-2.30 mmHg per 100 mmol/day")
println("="^80)
@printf("%-42s %12s %14s\n", "configuration", "t1/2 (h)", "salt sens")
println("-"^80)

r = run(); @printf("%-42s %12.2f %14.4f\n", "AS MERGED  G_pn 8.4, G_vn 585, tau 0.15", r.thalf, r.shift)

println("\n  LAG SWEEP - gains fixed:")
for tau in (0.05, 0.15, 0.50, 1.00)
    r = run(tau = tau)
    @printf("%-42s %12.2f %14.4f\n", "    tau_vn = $tau d", r.thalf, r.shift)
end

println("\n  GAIN SWEEP - lag fixed, BOTH natriuretic gains scaled together:")
for k in (1.0, 1.5, 2.0, 3.0, 4.0)
    r = run(gpn = G_PN0*k, ganp = G_ANP0*k)
    @printf("%-42s %12.2f %14.4f\n", "    gains x $k", r.thalf, r.shift)
end
println("="^80)

println("
  WHICH GAIN? - swept separately:")
for k in (2.0, 3.0, 4.0)
    r = run(ganp = G_ANP0*k)
    @printf("%-42s %12.2f %14.4f
", "    G_vn x $k only", r.thalf, r.shift)
end
for k in (3.0, 6.0, 10.0)
    r = run(gpn = G_PN0*k)
    @printf("%-42s %12.2f %14.4f
", "    G_pn x $k only", r.thalf, r.shift)
end

println("
  IS THERE ANOTHER LEVER? - the GFR volume response:")
for v in (1.30, 2.60, 5.20)
    r = run(sgfr = v)
    @printf("%-42s %12.2f %14.4f
", "    S_gfr_v = $v", r.thalf, r.shift)
end
println("="^80)
