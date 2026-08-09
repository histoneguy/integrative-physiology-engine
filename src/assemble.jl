"""
Model assembly and single-individual solve.

THE MINIMAL CLOSED LOOP (ADR 0007)

    BodyFluids  --V_ecf-->  Cardiovascular  --MAP-->  Renal
         ^                                              |
         +---------- Na_excr, H2O_excr -----------------+

Three components, one loop. Sodium and water in, ECF volume sets blood volume,
blood volume sets cardiac output, cardiac output sets pressure, pressure drives
excretion, excretion closes back onto ECF.

That loop is the whole model at this stage. Arterial pressure is an OUTPUT of it,
not a setpoint anything enforces. Everything else in whole-body physiology -
baroreflex, RAAS, ADH, circadian modulation - attaches to these three and cannot
be validated until this closes.

`structural_simplify` performs alias elimination, index reduction and tearing
BEFORE code generation. On this small system the reduction is modest; on the full
system it removes a large fraction of states outright, and it is not available to
an interpreted graph-walking engine at all.
"""

"""
    build_model(; body_mass = 70.0, storage = false, circadian = false)

Construct and structurally simplify the closed loop.

`storage`   - osmotically inactive sodium compartment. ADR 0004 is PROVISIONAL and
              tier E3; defaults OFF per ADR 0006.
`circadian` - ADR 0005. Correct and well-evidenced, but it modulates renal tubular
              reabsorption and has nothing to attach to until this loop is
              validated. Defaults OFF. Enabling it currently does nothing.

Call once, reuse across an ensemble. Never rebuild inside a population loop -
symbolic simplification and code generation are the expensive part and are
identical across members.
"""
function build_model(; body_mass = 70.0, storage::Bool = false, circadian::Bool = false)
    @named bf = BodyFluids(; body_mass, storage)
    @named cv = Cardiovascular()
    @named rn = Renal()

    connections = [
        # body fluids -> cardiovascular
        cv.V_ecf        ~ bf.V_ecf,
        # cardiovascular -> renal
        rn.MAP          ~ cv.MAP,
        # body fluids -> renal
        rn.C_Na         ~ bf.C_Na,
        # renal -> body fluids (closes the loop)
        bf.Na_excr_rate ~ rn.Na_excr,
        bf.H2O_excr_rate ~ rn.H2O_excr,
        # cardiovascular -> body fluids (currently unused downstream)
        bf.MAP          ~ cv.MAP,
    ]

    systems = [bf, cv, rn]

    if circadian
        @named clk = CircadianClock()
        push!(systems, clk)
        # NOT CONNECTED. ADR 0005 is sound but ahead of its dependency: it
        # modulates renal tubular reabsorption, which needs RAAS and ADH before
        # the modulation means anything. Wiring it now would be untestable.
        @warn "circadian=true adds the clock but it is not connected to anything " *
              "(ADR 0006 build order). It will not affect results."
    end

    @named model = ODESystem(connections, t; systems)
    return structural_simplify(model)
end

"""
    solve_individual(sys; tspan_days = 30.0, solver = nothing, saveat = 1.0, kwargs...)

Solve for a single individual.

Defaults chosen for the stated workload: long horizons, no dense output, coarse
saving. `saveat` is in DAYS.

`FBDF` is the default - multistep BDF, good on stiff systems with an expensive RHS,
and it exploits the sparse analytic Jacobian `structural_simplify` provides.
`Rodas5P` is often better on smaller or more strongly nonlinear systems. Benchmark
both per subsystem rather than assuming.
"""
function solve_individual(sys;
                          tspan_days = 30.0,
                          solver = nothing,
                          saveat = 1.0,
                          abstol = 1e-8,
                          reltol = 1e-6,
                          kwargs...)
    prob = ODEProblem(sys, [], (0.0, tspan_days), []; jac = true, sparse = true)
    alg = solver === nothing ? FBDF(autodiff = true) : solver
    return solve(prob, alg;
                 saveat, abstol, reltol,
                 dense = false, save_everystep = false, kwargs...)
end

"""
    salt_step(sys; levels_mEq_day, days_per_level, kwargs...)

Run a stepped sodium intake protocol - the Mars500 design.

This is the model's first real test. A step up in sodium intake should produce
transient retention, a rise in ECF volume and arterial pressure, and a return of
excretion to match intake at a NEW pressure. Failure to re-equilibrate means the
loop is not closed; equilibration at the OLD pressure means pressure natriuresis
is not doing anything.
"""
function salt_step(sys; levels_mEq_day = (205.0, 154.0, 103.0),
                   days_per_level = 30.0, kwargs...)
    results = []
    for (i, lvl) in enumerate(levels_mEq_day)
        # TODO: remake with Na_intake = lvl and carry state across levels.
        # Requires the parameter plumbing in ensemble.jl.
        push!(results, (level = lvl, index = i))
    end
    return results
end

"""
    solver_agreement(sys; solvers, tol = 1e-4, kwargs...)

Solve with several independent integrators and report the maximum relative
deviation.

Substitutes for the external reference we deliberately do not have (SOURCES.md
section 4). Agreement across independent methods cannot be satisfied by
reproducing another engine's integration error, which makes it a stronger claim
than matching any single implementation.
"""
function solver_agreement(sys; solvers = [FBDF(), Rodas5P(), QNDF()], kwargs...)
    sols = [solve_individual(sys; solver = s, kwargs...) for s in solvers]
    ref = Array(sols[1])
    worst = 0.0
    for s in sols[2:end]
        A = Array(s)
        size(A) == size(ref) || error("solver_agreement requires identical saveat grids")
        worst = max(worst, maximum(abs.(A .- ref) ./ max.(abs.(ref), 1e-12)))
    end
    return (max_rel_deviation = worst, solutions = sols)
end
