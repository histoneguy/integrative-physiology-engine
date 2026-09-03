#
# Would a volume-keyed natriuretic path fix what the challenges say is broken?
#
# Run:  julia --project=. bench/anp_diagnostic.jl
#
# ADR 0010 has said since 2026-08-21 that G_pn is inflated because the model has no
# volume-sensing natriuretic path, and that the inflated slope is "the shape of the
# missing component". It has never been tested, because the component was never built.
#
# validation/challenges.jl produced the first measured evidence: acute isotonic volume
# expansion raises fractional sodium excretion by 43% in this model against 123% in
# 23 healthy humans (Jensen 2013, PMID 24067081). The model under-natriureses acutely.
# That is exactly what a missing volume-keyed path predicts, because the only natriuretic
# path it has is pressure, and pressure is the SLOW arm.
#
# THE PREDICTION IS ALGEBRAIC AND IS WRITTEN DOWN BEFORE THE RUN. At steady state
# excretion equals intake, so
#
#     d(intake) = G_pn*dMAP + G_anp*dV_ecf,   and   dMAP = ratio * dV_ecf
#
# with ratio = dMAP/dV_ecf = 6.173 mmHg/L measured. Therefore
#
#     dMAP/d(intake) = 1 / (G_pn + G_anp/ratio)
#
# So THE TWO ARE INTERCHANGEABLE AT STEADY STATE and only their ACUTE behaviour differs.
# Three consequences, all falsifiable here:
#
#   P1  Chronic salt sensitivity depends only on the COMBINATION G_pn + G_anp/6.173.
#       Configurations with equal combinations must give the same salt-step shift.
#   P2  G_pn can therefore fall to the measured animal value of 5.43 (Mizelle 1993)
#       without changing chronic salt sensitivity, provided G_anp takes up the slack:
#       G_anp = (20.0 - 5.43) * 6.173 = 89.9 (mEq/day)/L.
#   P3  To ALSO reach the human chronic salt sensitivity of 1.70-2.30 mmHg per 100
#       mmol/day, the combination must reach 44-59, so with G_pn at 5.43 the required
#       G_anp is (44 - 5.43)*6.173 = 238 to (59 - 5.43)*6.173 = 331.
#
# If P1 holds and the acute response ALSO improves, the two paths are distinguishable by
# acute data and only by acute data - which would tell ADR 0010 exactly which experiment
# identifies its gain.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf

const RATIO = 6.173

function harness(; anp = 0.0, gpn = nothing)
    sys = IPE.build_model(; anp_gain = anp)
    U = unknowns(sys); O = observed(sys)
    pget(n) = (for p in parameters(sys); occursin(n, String(Symbol(p))) && return p; end;
               error(n))
    val(s, n, i) = begin
        for u in U; occursin(n, String(Symbol(u))) && return s[u][i]; end
        for o in O; occursin(n, String(Symbol(o.lhs))) && return s[o.lhs][i]; end
        NaN
    end
    base = Dict{Any,Any}()
    gpn !== nothing && (base[pget("G_pn")] = gpn)

    # resting state
    p = ODEProblem(sys, collect(base), (0.0, 90.0), Pair[])
    s0 = solve(p, Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    u0 = [u => s0[u][end] for u in U]
    rest = (MAP = val(s0,"MAP",length(s0.t)), V_ecf = val(s0,"V_ecf",length(s0.t)),
            GFR = val(s0,"rn₊GFR",length(s0.t)), C_Na = val(s0,"bf₊C_Na",length(s0.t)),
            Na = val(s0,"rn₊Na_excr",length(s0.t)))

    # chronic salt step
    u = copy(u0); t0 = 0.0; maps = Float64[]
    for lev in (205.0, 154.0, 103.0)
        pm = copy(base); pm[pget("Na_intake")] = lev
        pr = ODEProblem(sys, vcat(u, collect(pm)), (t0, t0 + 30.0), Pair[])
        ss = solve(pr, Rodas5P(); abstol = 1e-9, reltol = 1e-9)
        push!(maps, val(ss, "MAP", length(ss.t)))
        u = [x => ss[x][end] for x in U]; t0 += 30.0
    end
    shift = (maximum(maps) - minimum(maps)) / 102 * 100

    # acute isotonic volume expansion, Jensen 23 mL/kg over 1 h
    vol = 0.023 * 70.0
    pm = copy(base)
    pm[pget("H2O_intake")] = 2.5 + vol/(1/24)
    pm[pget("Na_intake")]  = 205.0 + 154.0*vol/(1/24)
    p1 = ODEProblem(sys, vcat(u0, collect(pm)), (0.0, 1/24), Pair[])
    s1 = solve(p1, Rodas5P(); abstol = 1e-10, reltol = 1e-10, saveat = 1/24/40)
    u1 = [x => s1[x][end] for x in U]
    p2 = ODEProblem(sys, vcat(u1, collect(base)), (1/24, 1/24 + 4/24), Pair[])
    s2 = solve(p2, Rodas5P(); abstol = 1e-10, reltol = 1e-10, saveat = 0.002)
    fena0 = rest.Na / (rest.GFR * rest.C_Na)
    fpk = maximum(maximum(val(s,"rn₊Na_excr",i)/(val(s,"rn₊GFR",i)*val(s,"bf₊C_Na",i))
                          for i in 1:length(s.t)) for s in (s1, s2))
    (rest = rest, shift = shift, fena = (fpk/fena0 - 1)*100,
     comb = (gpn === nothing ? 20.0 : gpn) + anp/RATIO)
end

println("HUMAN TARGETS   chronic salt sensitivity 1.70-2.30 mmHg per 100 mmol/day")
println("                acute FENa rise on 23 mL/kg isotonic saline +123%")
println("                resting MAP 80-95, resting V_ecf 13-17 L")
println()
@printf("%-34s %8s %9s %9s %9s %9s\n",
        "configuration", "G_pn+G_anp/r", "shift", "FENa%", "restMAP", "restVecf")

CONFIGS = [
    ("incumbent, no volume path",         0.0,    nothing),
    ("P1a  G_pn 20.0, G_anp 0",           0.0,    20.0),
    ("P1b  G_pn 10.0, G_anp 61.7",       61.73,   10.0),
    ("P1c  G_pn  5.43, G_anp 89.9",      89.94,    5.43),
    ("P2   measured animal G_pn only",    0.0,     5.43),
    ("P3a  G_pn 5.43, G_anp 238",       238.0,     5.43),
    ("P3b  G_pn 5.43, G_anp 331",       331.0,     5.43),
    ("P3c  G_pn 5.43, G_anp 285",       285.0,     5.43),
]
for (lab, anp, gpn) in CONFIGS
    r = harness(; anp = anp, gpn = gpn)
    @printf("%-34s %8.2f %9.3f %9.1f %9.3f %9.3f\n",
            lab, r.comb, r.shift, r.fena, r.rest.MAP, r.rest.V_ecf)
end

println()
println("P1 is confirmed if the three P1 rows give the SAME shift. P2 is confirmed if")
println("row P2 is far outside the human window and row P1c is not. P3 is confirmed if")
println("the P3 rows land the shift in 1.70-2.30 AND raise FENa toward 123%.")
