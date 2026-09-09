# What the reported uncertainty on BR.OPEN_LOOP_GAIN does to the model.
#
#   julia --project=. bench/gain_uncertainty_sweep.jl
#
# WHY THIS EXISTS. The row is 5.62 +/- 0.98 SD in seven subjects. That is a +/-17%
# spread on the number that now sets every transient in this model, and it is the
# ORDER OF THE UNCERTAINTY that matters rather than the fifth decimal of any output
# computed from it. Section 7 has recorded since it was written that parameter
# uncertainty is NOT propagated here and that every model output is a point with no
# error bar. This does not fix that. It does the one-parameter version of it for the
# parameter that currently carries the most weight, so that nothing downstream gets
# quoted more tightly than the input allows.
#
# DIRECTIVE 1.9. Outputs are printed to the figures the INPUT supports, not to the
# figures the solver emits.

using IPE
using IPE: build_model, salt_step, check_pressure_natriuresis, LedgerParams
using ModelingToolkit
using OrdinaryDiffEq

const L = IPE.LedgerParams

# 5.62 +/- 0.98 SD, n = 7 (Yamasaki 2021, Table 2). Also shown: the SEM, which is
# what an uncertainty on the MEAN would be, and the value this row carried before.
const CENTRE = L.BR_OPEN_LOOP_GAIN
const SD     = 0.98
const SEM    = SD / sqrt(7)

function run_at(gain)
    r = salt_step()
    sys = r.sys
    opmap = Dict()
    for p in parameters(sys)
        occursin("G_br", String(Symbol(p))) && (opmap[p] = gain)
    end
    # salt_step builds its own problems, so sweep by rebuilding through it is not
    # available; instead re-solve the three arms with the gain overridden.
    levels = (205.0, 154.0, 103.0)
    maps = Float64[]; vols = Float64[]
    u_carry = nothing; t0 = 0.0
    for lv in levels
        pm = copy(opmap)
        for p in parameters(sys)
            occursin("Na_intake", String(Symbol(p))) && (pm[p] = lv)
        end
        prob = ODEProblem(sys, pm, (t0, t0 + 30.0); jac = true)
        u_carry !== nothing && (prob = remake(prob; u0 = u_carry))
        sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-6,
                    saveat = [t0 + 30.0])
        u_carry = sol.u[end]; t0 += 30.0
        push!(maps, IPE._final(sol, sys, "cv₊MAP"))
        push!(vols, IPE._final(sol, sys, "bf₊V_ecf"))
    end
    shift = maps[1] - maps[end]
    dv    = vols[1] - vols[end]
    return (; shift, ratio = shift / dv, sens = shift / 1.02)
end

println("=" ^ 74)
println("BR.OPEN_LOOP_GAIN = $CENTRE +/- $SD SD  (n = 7; SEM = $(round(SEM, digits=2)))")
println("=" ^ 74)
println("The reported dispersion is +/-", round(100 * SD / CENTRE, digits = 0),
        "% of the value. Everything below is inside that.")
println()
println(rpad("gain", 10), rpad("salt sensitivity", 20), rpad("dMAP/dV_ecf", 16), "note")
println("-" ^ 74)

for (g, note) in ((CENTRE - SD, "-1 SD"),
                  (CENTRE - SEM, "-1 SEM"),
                  (CENTRE, "entered value"),
                  (CENTRE + SEM, "+1 SEM"),
                  (CENTRE + SD, "+1 SD"),
                  (2.0, "the old animal mid-range"))
    r = run_at(g)
    println(rpad(round(g, digits = 2), 10),
            rpad(round(r.sens, digits = 2), 20),
            rpad(round(r.ratio, digits = 2), 16), note)
end

println()
println("""
HOW TO READ THIS. Human salt sensitivity is 1.70-2.30 mmHg per 100 mmol/day and the
pressure-volume ratio 2.97-4.16 mmHg/L - spans of 35% and 40%. If the whole +/-1 SD
sweep above stays inside those, then THE GAIN'S UNCERTAINTY IS NOT WHAT LIMITS THE
MODEL'S AGREEMENT, and quoting either output beyond three significant figures asserts
a precision neither the parameter nor the target possesses.

WHAT THIS IS NOT. It is a one-parameter sweep, not propagated uncertainty. Every other
row here is still a point estimate, the ensemble still samples only body mass, and
section 7 records that as the reason validation band M cannot be run. Doing this
properly means sampling the ledger's dispersion across every row that has one.""")
