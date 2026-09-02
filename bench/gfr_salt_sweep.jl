#
# Does a salt-linked GFR carry any of the salt-step pressure shift?
#
# Run:  julia --project=. bench/gfr_salt_sweep.jl
#
# WHY THIS EXISTS. Renal.jl autoregulates GFR FLAT across the whole plateau, and the
# salt step never leaves the plateau, so GFR is IDENTICAL at 205, 154 and 103 mEq/day.
# Healthy humans do not do that - four groups report GFR and renal plasma flow RISING
# on high salt. This sweep asks what it would be worth if the model did it too, and it
# is the model half of validation/renal_hemodynamics_prereg.md, measured BEFORE any
# paper is opened.
#
# HOW. GFR0 is overridden per arm as GFR0 * (1 + g * (level - 154) / 51), so the high
# arm is +g, the mid arm unchanged and the low arm -g. FR_Na is NOT recomputed, which
# is the whole point: HANDOVER section 3.5 showed GFR cancels out of the steady state
# only because FR_Na is DERIVED from it. A GFR that moves WITHIN a run has no such
# compensation.
#
# NOT A PROPOSAL. No functional form is claimed and g is not a parameter. This measures
# a sensitivity so that a sourced value can be judged material or immaterial against a
# threshold fixed in advance.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf

function salt_step_gfr(g; levels = (205.0, 154.0, 103.0), days = 30.0)
    sys = IPE.build_model()
    results = NamedTuple[]
    u_carry = nothing
    t0 = 0.0
    gfr0_base = Dict()
    for prm in parameters(sys)
        n = String(Symbol(prm))
        occursin("GFR0", n) && (gfr0_base[prm] = ModelingToolkit.getdefault(prm))
    end
    for level in levels
        opmap = Dict()
        for prm in parameters(sys)
            n = String(Symbol(prm))
            occursin("Na_intake", n) && (opmap[prm] = level)
            haskey(gfr0_base, prm) &&
                (opmap[prm] = gfr0_base[prm] * (1 + g * (level - 154.0) / 51.0))
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
                        GFR = fin("GFR"), Na_excr = fin("Na_excr"),
                        Na_filtered = fin("Na_filtered")))
        t0 += days
    end
    results
end

println("g       intake   GFR        MAP        V_ecf     Na_excr")
base_shift = Ref(NaN)
for g in (0.0, 0.01, 0.02, 0.04, 0.08, 0.16)
    r = salt_step_gfr(g)
    for x in r
        @printf("%.3f   %5.0f  %9.4f  %9.5f  %8.5f  %8.3f\n",
                g, x.level, x.GFR, x.MAP, x.V_ecf, x.Na_excr)
    end
    dm = maximum(x.MAP for x in r) - minimum(x.MAP for x in r)
    dv = maximum(x.V_ecf for x in r) - minimum(x.V_ecf for x in r)
    isnan(base_shift[]) && (base_shift[] = dm)
    @printf("  --> shift %.4f mmHg (%.4f per 100 mmol/day), dV %.4f L (%.4f), ratio %.3f, fall %.1f%%\n\n",
            dm, dm / 102 * 100, dv, dv / 102 * 100, dm / dv,
            (base_shift[] - dm) / base_shift[] * 100)
end
println("g is the FRACTIONAL GFR change at the high and low arms, NOT a ledger value.")
println("Decision rule is fixed in validation/renal_hemodynamics_prereg.md section 6.")
