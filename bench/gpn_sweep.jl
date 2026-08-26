using IPE
using ModelingToolkit
using OrdinaryDiffEq

# Replicates IPE.salt_step but with G_pn overridden per run, so the model is
# built and simplified ONCE and only parameters change between sweeps.
function salt_step_gpn(gpn; levels = (205.0, 154.0, 103.0), days = 30.0,
                       body_mass = 70.0)
    sys = IPE.build_model(; body_mass, baroreflex = true)
    results = NamedTuple[]
    u_carry = nothing
    t0 = 0.0
    for level in levels
        opmap = Dict()
        for prm in parameters(sys)
            n = String(Symbol(prm))
            if occursin("Na_intake", n)
                opmap[prm] = level
            elseif occursin("G_pn", n)
                opmap[prm] = gpn
            end
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
                        Na_excr = fin("Na_excr")))
        t0 += days
    end
    results
end

println("G_pn   intake   MAP        V_ecf     Na_excr   excr/intake")
for gpn in (20.0, 44.0, 51.0, 59.0, 188.0)
    r = salt_step_gpn(gpn)
    maps = [x.MAP for x in r]
    for x in r
        println(rpad(gpn, 7), rpad(Int(x.level), 9),
                rpad(round(x.MAP, digits = 3), 11),
                rpad(round(x.V_ecf, digits = 4), 10),
                rpad(round(x.Na_excr, digits = 2), 10),
                round(x.Na_excr / x.level, digits = 4))
    end
    println("  --> shift ", round(maximum(maps) - minimum(maps), digits = 4),
            " mmHg,  V_ecf range ", round(minimum(x.V_ecf for x in r), digits = 3),
            " - ", round(maximum(x.V_ecf for x in r), digits = 3), " L")
    println()
end
