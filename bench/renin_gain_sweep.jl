#
# What does RAAS.RENIN.PRESSURE_GAIN actually control?
#
# Run:  julia --project=. bench/renin_gain_sweep.jl
#
# The model half of validation/renin_gain_prereg.md, measured BEFORE any source is
# opened. HANDOVER section 4 item 3: the gain was fitted so the low-salt arm doubled
# plasma renin activity from a baseline of 1.0, and CV.MAP.SETPOINT then moved 93 -> 87,
# putting the resting model BELOW the rectification threshold. Baseline pra is now 2.31,
# so the target the gain was fitted to no longer exists.
#
# THREE THINGS ARE MEASURED, and the third is the one that matters.
#
#   A. The operating point. renin_drive, pra, aldo, fr_mod at each salt arm, so the
#      derivation in the pre-registration has the model side written down.
#   B. Steady-state insensitivity WITH escape on. Escape drives fr_mod to zero, so the
#      salt-step shift should not move at all. Confirmed rather than assumed.
#   C. Steady-state SENSITIVITY WITH ESCAPE SUPPRESSED. This is ADR 0015's configuration -
#      a tubular term that does NOT escape - and it is the reason this row blocks that
#      record. Whatever magnitude ADR 0015 claims is proportional to whatever this gain
#      carries, and here that proportionality is measured instead of asserted.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf

function salt_step_renin(g_renin; tau_esc = nothing,
                         levels = (205.0, 154.0, 103.0), days = 30.0)
    sys = IPE.build_model()
    results = NamedTuple[]
    u_carry = nothing
    t0 = 0.0
    for level in levels
        opmap = Dict()
        for prm in parameters(sys)
            n = String(Symbol(prm))
            occursin("Na_intake", n) && (opmap[prm] = level)
            g_renin !== nothing && occursin("g_renin", n) && (opmap[prm] = g_renin)
            tau_esc !== nothing && occursin("tau_esc", n) && (opmap[prm] = tau_esc)
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
        push!(results, (level = level, MAP = fin("MAP"), pra = fin("pra"),
                        drive = fin("renin_drive"), aldo = fin("aldo"),
                        fr_mod = fin("fr_mod"), V_ecf = fin("V_ecf")))
        t0 += days
    end
    results
end

shift(r) = maximum(x.MAP for x in r) - minimum(x.MAP for x in r)

println("A. THE OPERATING POINT at the incumbent gain")
println("intake   MAP        drive      pra       aldo      fr_mod")
for x in salt_step_renin(nothing)
    @printf("  %5.0f  %9.5f  %.6f  %.5f  %.5f  %+.4e\n",
            x.level, x.MAP, x.drive, x.pra, x.aldo, x.fr_mod)
end

println()
println("B. STEADY STATE WITH ESCAPE ON - the shift must not move")
println("g_renin   shift mmHg    per 100 mmol   resting pra")
base = Ref{Union{Nothing,Float64}}(nothing)
for g in (4.35, 9.5, 19.0, 38.0, 76.0)
    r = salt_step_renin(g)
    s = shift(r)
    base[] === nothing && (base[] = s)
    @printf("  %6.2f  %11.6f  %13.6f  %11.5f   (%.4f%% from incumbent)\n",
            g, s, s / 102 * 100, r[2].pra, (s - base[]) / base[] * 100)
end

println()
println("C. STEADY STATE WITH ESCAPE SUPPRESSED - ADR 0015's configuration")
println("   tau_esc = 1e6 d, so the tubular term persists. THIS is where the gain bites.")
println("g_renin   shift mmHg    per 100 mmol   resting pra   fall vs escape-ON")
on_shift = shift(salt_step_renin(nothing))
for g in (4.35, 9.5, 19.0, 38.0, 76.0)
    r = salt_step_renin(g; tau_esc = 1.0e6)
    s = shift(r)
    @printf("  %6.2f  %11.6f  %13.6f  %11.5f  %10.1f%%\n",
            g, s, s / 102 * 100, r[2].pra, (on_shift - s) / on_shift * 100)
end

println()
println("The pre-registered question is what the resting pra SHOULD be. The model side")
println("of the derivation is renin_drive at the mid arm, printed in A above.")
