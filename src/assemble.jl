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
              reabsorption and has nothing to attach to until RAAS and ADH land.
              Defaults OFF. Enabling it currently does nothing.
`baroreflex` - ADR 0009. Defaults ON. Set false to recover the pre-baroreflex
              model exactly - used by the regression test that the reflex does
              not alter long-run pressure.

Call once, reuse across an ensemble. Never rebuild inside a population loop -
symbolic simplification and code generation are the expensive part and are
identical across members.
"""
function build_model(; kwargs...)
    return mtk_simplify(build_raw_model(; kwargs...))
end

"""
    build_raw_model(; body_mass = 70.0, storage = false, circadian = false)

The composed system BEFORE structural simplification.

Exposed so diagnostics can count how many states simplification removes - the
figure that justifies the symbolic layer in ADR 0001. Not for general use;
call `build_model`.
"""
function build_raw_model(; body_mass = 70.0, storage::Bool = false,
                         circadian::Bool = false, baroreflex::Bool = true,
                         raas::Bool = true, adh::Bool = true,
                         sex::Symbol = :male)
    @named bf = BodyFluids(; body_mass, storage)
    sex in (:male, :female) ||
        error("sex must be :male or :female, got :$sex. There is no :both " *
              "individual - a parameter with no known dimorphism resolves to its " *
              "shared value for either sex, which is not the same thing.")
    @named cv = Cardiovascular(; sex)
    @named rn = Renal()
    @named br = Baroreflex(; enabled = baroreflex)
    @named ra = Raas(; enabled = raas)
    @named ad = Adh(; enabled = adh)

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
        # cardiovascular <-> baroreflex
        br.MAP          ~ cv.MAP,
        cv.tpr_mod      ~ br.tpr_mod,
        # cardiovascular -> raas -> renal
        ra.MAP          ~ cv.MAP,
        rn.fr_mod       ~ ra.fr_mod,
        # body fluids -> adh -> renal (osmoregulation)
        ad.Osm_ecf      ~ bf.Osm_ecf,
        rn.u_osm        ~ ad.u_osm,
    ]

    systems = [bf, cv, rn, br, ra, ad]

    # CONNECTED 2026-08-25. ADR 0006 build order item 6: the clock modulates
    # renal tubular sodium handling and the reflex pressure setpoint, both of
    # which now exist. With circadian=false the gains are zero, so renal_mod and
    # cv_mod are identically 1.0 and every equation reduces to its pre-clock form.
    # DEFAULT REMAINS OFF: the amplitude and acrophase of both arms are contested
    # in the literature - see the ledger notes on CIRC.RENAL_NA.AMPLITUDE and
    # CIRC.CV_MAP.AMPLITUDE - so this must not silently drive results.
    g = circadian ? 1.0 : 0.0
    @named clk = CircadianClock(; renal_gain = g, cv_gain = g)
    push!(systems, clk)
    push!(connections, rn.renal_mod ~ clk.renal_mod)
    push!(connections, br.cv_mod    ~ clk.cv_mod)

    @named model = MTKSystem(connections, t; systems)
    return model
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
                          sparse = nothing,
                          kwargs...)
    # Sparse Jacobians pay on large hierarchical systems and COST on small dense
    # ones - the sparse machinery's overhead exceeds its saving below roughly 50
    # states. Decide from the system rather than assuming, and let the caller
    # override. ADR 0001 assumed sparse was always a win; at 3 states it is not.
    use_sparse = sparse === nothing ? length(mtk_unknowns(sys)) >= 50 : sparse
    # Empty Dict() rather than positional [] - the positional form is
    # deprecated and MTK now wants variable => value maps.
    prob = ODEProblem(sys, Dict(), (0.0, tspan_days);
                      jac = true, sparse = use_sparse)
    # `autodiff` takes an ADTypes specifier now, not a Bool.
    alg = solver === nothing ? FBDF(autodiff = AutoForwardDiff()) : solver
    return solve(prob, alg;
                 saveat, abstol, reltol,
                 dense = false, save_everystep = false, kwargs...)
end

"""
    _obs(sys, name)

Resolve a variable or observed quantity by substring, for cycle averaging.
"""
function _obs(sys, name)
    for o in observed(sys)
        occursin(name, String(Symbol(o.lhs))) && return o.lhs
    end
    for u in unknowns(sys)
        occursin(name, String(Symbol(u))) && return u
    end
    error("no variable matching $name")
end

"""
    salt_step(; levels_mEq_day, days_per_level, body_mass = 70.0, saveat = 0.25, kwargs...)

Run a stepped sodium intake protocol - the Mars500 design - carrying state across
levels.

THIS IS THE ADR 0007 FALSIFIABLE TEST. Three conditions, all required:

  1. transient sodium retention and a rise in ECF volume
  2. a rise in arterial pressure
  3. excretion returns to match intake AT A NEW, HIGHER PRESSURE

Failure to re-equilibrate means the loop is not closed. Re-equilibration at the
ORIGINAL pressure means pressure natriuresis is inert and the model is not doing
what it claims - which is the whole substance of the Guyton formulation.

Returns a NamedTuple per level with the solution and the summary quantities the
test needs, plus a combined trajectory.
"""

function salt_step(; levels_mEq_day = (205.0, 154.0, 103.0),
                   days_per_level = 30.0,
                   body_mass = 70.0,
                   baroreflex::Bool = true,
                   raas::Bool = true,
                   adh::Bool = true,
                   circadian::Bool = false,
                   sex::Symbol = :male,
                   saveat = 0.25,
                   solver = nothing,
                   kwargs...)

    sys = build_model(; body_mass, baroreflex, raas, adh, circadian, sex)
    results = NamedTuple[]
    u_carry = nothing          # state carried between levels
    t0 = 0.0

    for (i, level) in enumerate(levels_mEq_day)
        # Rebuild the problem at this intake level. The parameter lives in the
        # BodyFluids subsystem, so address it by its namespaced symbol.
        opmap = Dict()
        for prm in parameters(sys)
            if occursin("Na_intake", String(Symbol(prm)))
                opmap[prm] = level
            end
        end
        # Carry the end state of the previous level in as the initial condition.
        if u_carry !== nothing
            for (u, v) in zip(mtk_unknowns(sys), u_carry)
                opmap[u] = v
            end
        end

        prob = ODEProblem(sys, opmap, (t0, t0 + days_per_level); jac = true)
        alg  = solver === nothing ? FBDF(autodiff = AutoForwardDiff()) : solver
        sol  = solve(prob, alg; saveat, dense = false, abstol = 1e-8, reltol = 1e-6,
                     kwargs...)

        u_carry = sol.u[end]
        # PHASE-AWARE SUMMARIES. With a clock running there is no steady state,
        # only a limit cycle (ADR 0005), so an instantaneous end value is
        # ambiguous unless its phase is stated. Connecting the clock exposed
        # this immediately: excretion/intake read 0.72/0.61/0.45 on instantaneous
        # values and 1.00/1.00/1.00 once cycle-averaged, with MAP returning to
        # the pre-clock levels to four decimals. cycle_average has existed since
        # ADR 0005 and nothing used it, because nothing was connected.
        #
        # Computed unconditionally: with no clock the average over the final day
        # equals the endpoint to solver tolerance, so this costs nothing and
        # removes a whole class of phase artefact from every downstream check.
        _cyc(name) = try
            cycle_average(sol, _obs(sys, name); period_days = 1.0)
        catch
            _final(sol, sys, name)
        end
        push!(results, (level = level,
                        index = i,
                        t_start = t0,
                        t_end = t0 + days_per_level,
                        sol = sol,
                        MAP_cycavg = _cyc("MAP"),
                        Na_excr_cycavg = _cyc("Na_excr"),
                        MAP_final = _final(sol, sys, "MAP"),
                        V_ecf_final = _final(sol, sys, "V_ecf"),
                        Na_excr_final = _final(sol, sys, "Na_excr"),
                        Na_ecf_final = _final(sol, sys, "Na_ecf")))
        t0 += days_per_level
    end

    return (levels = results, sys = sys)
end

"""Read an observable or state by partial name from the final time point."""
function _final(sol, sys, name::AbstractString)
    for u in mtk_unknowns(sys)
        occursin(name, String(Symbol(u))) && return sol[u][end]
    end
    for o in observed(sys)
        lhs = String(Symbol(o.lhs))
        occursin(name, lhs) && return sol[o.lhs][end]
    end
    return NaN
end

"""
    check_pressure_natriuresis(r; tol_excretion = 0.02, min_map_shift = 0.5)

Evaluate the ADR 0007 test against `salt_step` output.

Returns a NamedTuple of verdicts. `pass` requires BOTH that excretion matches
intake at every level (the loop closes) AND that arterial pressure DIFFERS
between levels (natriuresis is doing work). The second condition is the one that
matters: a model can close the loop trivially by excreting whatever it is given,
and that model has no pressure regulation in it at all.
"""
function check_pressure_natriuresis(r; tol_excretion = 0.02, min_map_shift = 0.5)
    lv = r.levels
    closes = all(abs(l.Na_excr_cycavg - l.level) / l.level < tol_excretion for l in lv)

    # Cycle-averaged, so a running clock cannot make this phase-dependent.
    maps = [l.MAP_cycavg for l in lv]
    intakes = [l.level for l in lv]
    map_range = maximum(maps) - minimum(maps)
    shifts = map_range >= min_map_shift

    # Higher intake must give higher pressure. Sign matters: an inverted
    # relationship would be worse than no relationship.
    correct_sign = all(
        (intakes[i] - intakes[i+1]) * (maps[i] - maps[i+1]) > 0
        for i in 1:length(lv)-1 if intakes[i] != intakes[i+1])

    return (pass = closes && shifts && correct_sign,
            excretion_matches_intake = closes,
            map_shifts_between_levels = shifts,
            map_shift_mmHg = map_range,
            higher_intake_higher_pressure = correct_sign,
            maps = maps,
            intakes = intakes)
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
function solver_agreement(sys; solvers = [FBDF(), Rodas5P()], atol = 1e-6, kwargs...)
    sols = [solve_individual(sys; solver = s, kwargs...) for s in solvers]
    ref = Array(sols[1])
    worst = 0.0
    for s in sols[2:end]
        A = Array(s)
        size(A) == size(ref) || error("solver_agreement requires identical saveat grids")
        # MIXED absolute/relative, not pure relative. The denominator floor is
        # `atol`, not machine epsilon.
        #
        # WHY, recorded 2026-08-25 when this bit. The floor was 1e-12, which makes
        # the metric a pure ratio for any state that legitimately sits at zero.
        # RAAS has one: `esc` is identically zero at the operating point, because
        # MAP equals the rectification threshold so renin drive is zero. Its value
        # was 2.2e-17 and the two solvers disagreed by 2.1e-11 in ABSOLUTE terms -
        # utterly negligible - which the old metric reported as a relative
        # deviation of 20.5 and failed the suite on. Every state carrying real
        # magnitude agreed to 1e-7 or better at the same time.
        #
        # This is a defect in the metric that RAAS exposed rather than caused, and
        # any future component with a zero-valued state would have hit it too. A
        # deviation below `atol` is below any physiological meaning for every state
        # in this model - the largest, Na_ecf, is order 2000.
        worst = max(worst, maximum(abs.(A .- ref) ./ max.(abs.(ref), atol)))
    end
    return (max_rel_deviation = worst, solutions = sols)
end
