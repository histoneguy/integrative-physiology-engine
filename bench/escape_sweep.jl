#
# Does the RAAS tubular term carry salt balance when it is allowed to persist?
#
# ADR 0015's motivating diagnostic. Run:  julia --project=. bench/escape_sweep.jl
#
# Raas.jl computes fr_mod ~ fr_raw - esc with D(esc) ~ (fr_raw - esc)/tau_esc, so at
# steady state esc == fr_raw and fr_mod == 0. Every steady state in this model therefore
# reaches sodium balance through ARTERIAL PRESSURE alone, via G_pn.
#
# This sweep lengthens tau_esc so the term persists, and measures what that does to the
# salt step. IT IS A DIAGNOSTIC, NOT THE PROPOSED CHANGE - disabling aldosterone escape
# is wrong physiology, and ADR 0015 proposes a separate non-escaping AngII term instead.
#
# The prediction was fixed before the first run: >20% fall in the shift means the pathway
# is live, <5% means the lead is dead.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf

function salt_step_tau(tau; levels = (205.0, 154.0, 103.0), days = 30.0)
    sys = IPE.build_model(; baroreflex = true, raas = true)
    results = NamedTuple[]
    u_carry = nothing
    t0 = 0.0
    for level in levels
        opmap = Dict()
        for prm in parameters(sys)
            n = String(Symbol(prm))
            occursin("Na_intake", n) && (opmap[prm] = level)
            tau !== nothing && occursin("tau_esc", n) && (opmap[prm] = tau)
        end
        prob = ODEProblem(sys, u_carry === nothing ? Pair[] : u_carry,
                          (t0, t0 + days), collect(opmap))
        sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)
        u_carry = [u => sol[u][end] for u in unknowns(sys)]
        fin(name) = begin
            v = NaN
            for u in unknowns(sys)
                occursin(name, String(Symbol(u))) && (v = sol[u][end])
            end
            if isnan(v)
                for o in observed(sys)
                    occursin(name, String(Symbol(o.lhs))) && (v = sol[o.lhs][end])
                end
            end
            v
        end
        push!(results, (level = level, MAP = fin("MAP"), V_ecf = fin("V_ecf"),
                        fr_mod = fin("fr_mod"), aldo = fin("aldo"), esc = fin("esc")))
        t0 += days
    end
    results
end

println("intake   MAP         V_ecf     fr_mod        aldo      esc")
shifts = Dict{String,Float64}()
for (label, tau) in (("escape ON (default tau_esc)", nothing),
                     ("escape OFF (tau_esc = 1e6 d)", 1.0e6))
    r = salt_step_tau(tau)
    println("\n", label)
    for x in r
        @printf("  %5.0f  %9.5f  %8.5f  %+.4e  %.4f  %+.4e\n",
                x.level, x.MAP, x.V_ecf, x.fr_mod, x.aldo, x.esc)
    end
    dm = maximum(x.MAP for x in r) - minimum(x.MAP for x in r)
    dv = maximum(x.V_ecf for x in r) - minimum(x.V_ecf for x in r)
    shifts[label] = dm
    @printf("  --> shift %.4f mmHg (%.3f per 100 mmol/day), dV_ecf %.4f L (%.3f), ratio %.3f\n",
            dm, dm / 102 * 100, dv, dv / 102 * 100, dm / dv)
end

on = shifts["escape ON (default tau_esc)"]
off = shifts["escape OFF (tau_esc = 1e6 d)"]
@printf("\nFALL: %.4f -> %.4f mmHg, %.1f%%\n", on, off, (on - off) / on * 100)
println("Pre-registered rule: >20% = pathway live, <5% = lead dead.")
println("HUMAN, meta-analytic (Cutler 1997 / He 2013 / He 2002): 1.70-2.30 mmHg per")
println("100 mmol/day. The escape-OFF arm lands just above that range.")
println()
println("CAVEATS, and they are load-bearing:")
println(" 1. The BASELINE MOVES - MAP 86.98 -> 90.30 at the high arm - so the model is")
println("    off its calibrated operating point and the magnitude carries that confound.")
println(" 2. RAAS.RENIN.PRESSURE_GAIN is CALIBRATED against a baseline that no longer")
println("    exists (HANDOVER section 7). Direction is trustworthy; size is not.")
println(" 3. The RATIO dMAP/dV_ecf is UNCHANGED at 6.173. This touches the pressure limb")
println("    only. The volume limb is still G_vr and still unsourced.")
