"""
Model assembly and single-individual solve.

The point of the symbolic layer: `structural_simplify` performs alias elimination,
index reduction and tearing BEFORE any code is generated. On a system of thousands
of states this typically removes a large fraction of them outright. That reduction
is not available to an interpreted graph-walking engine at all, and it is a bigger
lever than the choice of compiled language.
"""

"""
    build_model(; qss = false, body_mass = 70.0)

Construct and structurally simplify the composed model. Returns a simplified
`ODESystem` ready for `ODEProblem`.

Call once, reuse across an ensemble. Never rebuild inside a population loop -
symbolic simplification and code generation are the expensive part, and they are
identical across ensemble members.
"""
function build_model(; qss::Bool = false, body_mass = 70.0)
    @named bf = BodyFluids(; qss, body_mass)
    # Real assembly composes many subsystems here and connects their interface
    # variables. Walking skeleton has one.
    @named model = ODESystem(Equation[], t; systems = [bf])
    return structural_simplify(model)
end

"""
    solve_individual(sys; tspan_days = 30.0, solver = nothing, saveat = 1.0, kwargs...)

Solve for a single individual.

Defaults chosen for the stated workload - long horizons, no dense output, coarse
saving. `saveat` in days: at 30 days with `saveat = 1.0` you store 31 points rather
than every accepted step. For ensembles this is the difference between fitting in
RAM and not.

`FBDF` is the default: multistep BDF, good on stiff systems with expensive RHS, and
it exploits a sparse analytic Jacobian which `structural_simplify` gives us for free.
`Rodas5P` is often better for smaller or more strongly nonlinear systems - benchmark
both per subsystem rather than assuming.
"""
function solve_individual(sys;
                          tspan_days = 30.0,
                          solver = nothing,
                          saveat = 1.0,
                          abstol = 1e-8,
                          reltol = 1e-6,
                          kwargs...)
    prob = ODEProblem(sys, [], (0.0, tspan_days), [];
                      jac = true, sparse = true)
    alg = solver === nothing ? FBDF(autodiff = true) : solver
    return solve(prob, alg;
                 saveat, abstol, reltol,
                 dense = false,
                 save_everystep = false,
                 kwargs...)
end

"""
    solver_agreement(sys; solvers, tol = 1e-4, kwargs...)

Solve with several independent integrators and report the maximum relative deviation
between them.

This substitutes for the external reference we deliberately do not have. Agreement
across independent methods is a stronger correctness claim than matching any single
implementation, because it cannot be satisfied by reproducing another engine's
integration error. Required by validation/targets.md.
"""
function solver_agreement(sys;
                          solvers = [FBDF(), Rodas5P(), QNDF()],
                          kwargs...)
    sols = [solve_individual(sys; solver = s, kwargs...) for s in solvers]
    ref = Array(sols[1])
    worst = 0.0
    for s in sols[2:end]
        A = Array(s)
        size(A) == size(ref) || error("solver_agreement requires identical saveat grids")
        denom = max.(abs.(ref), 1e-12)
        worst = max(worst, maximum(abs.(A .- ref) ./ denom))
    end
    return (max_rel_deviation = worst, solutions = sols)
end
