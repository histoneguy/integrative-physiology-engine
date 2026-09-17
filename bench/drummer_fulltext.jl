#
# THE MODEL AGAINST DRUMMER 1992's FULL TEXT, now that the full text exists.
#
# Run:  julia --project=. bench/drummer_fulltext.jl
#
# Pre-registered in validation/late_time_course_prereg.md, whose section 6 branch L2
# said: found, and the model is outside it - report, and run the structural test. The
# structural test was HANDOVER 3.46 and 3.47. THIS IS THE SAME TEST AGAINST THE SERIES
# THE ABSTRACT DID NOT CARRY, obtained by the owner on 2026-09-17.
#
# THE SOURCE, READ IN FULL THIS TIME. Drummer C, Gerzer R, Heer M, Molz B, Bie P,
# Schlossberger M, Stadaeger C, Roecker L, Strollo F, Heyduck B, et al. Effects of an
# acute saline infusion on fluid and electrolyte metabolism in humans. Am J Physiol
# 1992;262(5 Pt 2):F744-54. PMID 1590419.
#
# WHAT THE FULL TEXT CHANGES, AND THE FIRST ITEM IS THE HEADLINE.
#
#  1. THERE ARE TWO HALF-LIVES AND THE ABSTRACT GAVE ONE. "By fitting the decline in
#     body weight relations to a monoexponential function, a half-life of ~7 h for
#     returning to baseline body weights was found. THE RESPECTIVE HALF-LIFE FOR
#     REACHIEVING SODIUM BALANCE WAS 10 h."  Weight comes back FASTER than sodium.
#  2. THE DOSE IS 30 mL/kg, not "2 litres" - the abstract rounds. 2.1 L at 70 kg.
#  3. The subjects were SUPINE and ate and drank nothing from 06:30 to noon.
#  4. The interval amounts, as differences from a same-subject CONTROL experiment.
#  5. Haematocrit fell 45.6 -> 40.6 percent over the first 6 h, a 10.0 percent
#     relative fall, and regained baseline only at 46 h. Lobo's was 7.5 percent on
#     2 L over 1 h; Drummer gave the same volume in 25 min.
#
using IPE, ModelingToolkit, OrdinaryDiffEq, Printf

# ---- Drummer's reported quantities ---------------------------------------
const DOSE_ML_KG   = 30.0
const INFUSION_MIN = 25.0
const T_HALF_WEIGHT = 7.0      # h, monoexponential fit, body weight
const T_HALF_SODIUM = 10.0     # h, monoexponential fit, sodium balance
const HCT_FALL_PCT  = 10.0     # 45.6 -> 40.6 over the first 6 h
# extra excretion over the control experiment, mg sodium -> mmol (/22.99)
const EXTRA = [("0-3 h",    0.0,   3.0,  104.0,   460.0/22.99),
               ("3-22 h",   3.0,  22.0, 1322.0,  6000.0/22.99),
               ("22-46 h", 22.0,  46.0,  504.0,  2100.0/22.99)]

sys = IPE.build_model()
U = unknowns(sys); O = observed(sys)
pget(n) = (for p in parameters(sys); occursin(n, String(Symbol(p))) && return p; end; error(n))
val(s, n, i) = begin
    for u in U; occursin(n, String(Symbol(u))) && return s[u][i]; end
    for o in O; occursin(n, String(Symbol(o.lhs))) && return s[o.lhs][i]; end
    NaN
end

s0 = solve(ODEProblem(sys, Pair[], (0.0, 90.0), Pair[]), Rodas5P();
           abstol = 1e-10, reltol = 1e-10)
n0 = length(s0.t)
u0 = [u => s0[u][end] for u in U]
Na_base  = val(s0, "rn₊Na_excr", n0)
H2O_base = val(s0, "rn₊H2O_excr", n0)
Vecf0    = val(s0, "V_ecf", n0)
Naecf0   = val(s0, "bf₊Na_ecf", n0)
Hct0     = val(s0, "cv₊Hct_eff", n0)

vol = DOSE_ML_KG/1000 * 70.0
dur = (INFUSION_MIN/60)/24
pm = Dict{Any,Any}(pget("H2O_intake") => 2.5 + vol/dur,
                   pget("Na_intake")  => 205.0 + 154.0*vol/dur)
s1 = solve(ODEProblem(sys, vcat(u0, collect(pm)), (0.0, dur), Pair[]), Rodas5P();
           abstol = 1e-10, reltol = 1e-10, saveat = dur/60)
u1 = [x => s1[x][end] for x in U]
s2 = solve(ODEProblem(sys, vcat(u1, collect(Dict{Any,Any}())), (dur, 3.0), Pair[]),
           Rodas5P(); abstol = 1e-10, reltol = 1e-10, saveat = 1/24/60)

ts = Float64[]; na = Float64[]; h2o = Float64[]; dv = Float64[]; dna = Float64[]; hct = Float64[]
for s in (s1, s2), i in 1:length(s.t)
    push!(ts, s.t[i])
    push!(na,  val(s, "rn₊Na_excr", i))
    push!(h2o, val(s, "rn₊H2O_excr", i))
    push!(dv,  val(s, "V_ecf", i) - Vecf0)
    push!(dna, val(s, "bf₊Na_ecf", i) - Naecf0)
    push!(hct, val(s, "cv₊Hct_eff", i))
end

"Trapezoid of (rate - baseline) between hours a and b, in the rate's own units x day."
function extra(rate, basal, a, b)
    idx = findall(t -> a/24 <= t <= b/24, ts)
    length(idx) < 2 && return NaN
    acc = 0.0
    for j in 2:length(idx)
        i1, i2 = idx[j-1], idx[j]
        acc += ((rate[i1] - basal) + (rate[i2] - basal))/2 * (ts[i2] - ts[i1])
    end
    acc
end

"Half-life of a decaying excursion, measured from its peak."
function thalf(x)
    ipk = argmax(x)
    ih = findfirst(i -> i > ipk && x[i] <= x[ipk]/2, 1:length(x))
    ih === nothing ? Inf : (ts[ih] - ts[ipk])*24
end

W = 84
println("="^W)
println("THE MODEL AGAINST DRUMMER 1992, FULL TEXT  (PMID 1590419)")
println("="^W)
@printf("  protocol: %.0f mL/kg of 0.9%% saline in %.0f min = %.2f L at 70 kg\n",
        DOSE_ML_KG, INFUSION_MIN, vol)
@printf("  resting: Na_excr %.1f mEq/day, H2O_excr %.3f L/day, V_ecf %.4f L, Hct %.4f\n\n",
        Na_base, H2O_base, Vecf0, Hct0)

println("  THE TWO HALF-LIVES - and the abstract carried only the first")
@printf("  %-34s %10s %10s %8s\n", "", "model", "Drummer", "ratio")
tw = thalf(dv); tn = thalf(dna)
@printf("  %-34s %10.2f %10.1f %8.2f\n", "volume excursion, h",  tw, T_HALF_WEIGHT, tw/T_HALF_WEIGHT)
@printf("  %-34s %10.2f %10.1f %8.2f\n", "sodium excursion, h",  tn, T_HALF_SODIUM, tn/T_HALF_SODIUM)
println()
println("  DRUMMER'S WEIGHT COMES BACK FASTER THAN HIS SODIUM - 7 h against 10 h.")
@printf("  THE MODEL'S DO NOT: %.2f h against %.2f h, a ratio of %.3f against Drummer's %.2f.\n",
        tw, tn, tw/tn, T_HALF_WEIGHT/T_HALF_SODIUM)
println("  In this model extracellular volume is tied to extracellular sodium, so water")
println("  cannot leave ahead of salt. Drummer's dissociation is what an osmotically")
println("  inactive sodium store would produce, and ADR 0004 is switched off.")

println("\n  EXTRA EXCRETION OVER THE CONTROL EXPERIMENT")
@printf("  %-10s %12s %12s   %12s %12s\n", "window",
        "model H2O mL", "Drummer", "model Na mmol", "Drummer")
for (lab, a, b, w_ml, na_mmol) in EXTRA
    mw = extra(h2o, H2O_base, a, b) * 1000
    mn = extra(na,  Na_base,  a, b)
    @printf("  %-10s %12.0f %12.0f   %12.1f %12.1f\n", lab, mw, w_ml, mn, na_mmol)
end

i6 = findlast(t -> t <= 6/24, ts)
@printf("\n  HAEMATOCRIT at 6 h: model %.4f, a %.1f%% relative fall;  Drummer %.1f%% (45.6 -> 40.6)\n",
        hct[i6], 100*(1 - hct[i6]/Hct0), HCT_FALL_PCT)
println("="^W)
