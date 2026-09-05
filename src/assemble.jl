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
                         respiration::Bool = true,
                         thyroid::Bool = true,
                         thyroid_metabolic::Bool = false,
                         thyroid_secretion = 1.0,
                         sex::Symbol = :male,
                         anp_gain = IPE.LedgerParams.CV_ANP_NATRIURETIC_GAIN)
    @named bf = BodyFluids(; body_mass, storage)
    sex in (:male, :female) ||
        error("sex must be :male or :female, got :$sex. There is no :both " *
              "individual - a parameter with no known dimorphism resolves to its " *
              "shared value for either sex, which is not the same thing.")
    @named cv = Cardiovascular(; sex, body_mass)
    # solute_tracking follows the adh flag. The urine solute load tracking
    # sodium and ADH setting urine osmolality are the two halves of the same
    # post-placeholder water limb: with adh = false, u_osm is pinned at U_base
    # so that Osm_load/U_base reproduces the old constant 1.7 L/day, and a
    # varying Osm_load would break that recovery. See Renal.jl and ADR 0008.
    @named rn = Renal(; solute_tracking = adh, body_mass, sex, anp_gain)
    @named br = Baroreflex(; enabled = baroreflex)
    @named ra = Raas(; enabled = raas)
    @named ad = Adh(; enabled = adh)
    # ADR 0017. Quasi-static, no state, and its only outward flux is water.
    @named rs = Respiratory(; body_mass, enabled = respiration)
    # ADR 0018. A forward computation - two inbound edges, no feedback.
    @named bl = Blood(; sex)
    # ADR 0019. One state - thyroxine - and an algebraic pituitary limb. The
    # METABOLIC ARM DEFAULTS OFF (decision 4), so th_mod is the literal 1.0 and
    # the respiratory CO2 load is exactly what it was before this component
    # existed. `thyroid = false` opens the loop by holding thyrotropin at its
    # euthyroid value, which is the control arm falsifiable test 1 needs.
    @named ty = Thyroid(; feedback = thyroid, metabolic = thyroid_metabolic,
                        sec_cap = thyroid_secretion)

    connections = [
        # body fluids -> cardiovascular
        cv.V_ecf        ~ bf.V_ecf,
        # cardiovascular -> renal
        rn.MAP          ~ cv.MAP,
        # body fluids -> renal
        rn.C_Na         ~ bf.C_Na,
        # ADDED 2026-09-02. Renal.jl has named V_ecf as an input in its docstring
        # since it was written and nothing ever connected it. ADR 0010's volume-keyed
        # natriuretic term needs it, and validation/challenges.jl section 3 is the
        # measured deficit that motivated wiring it.
        rn.V_blood      ~ cv.V_blood,
        # ADDED 2026-09-03. RN.GFR.VOLUME_SENSITIVITY was entered on 2026-09-02
        # and nothing read it; HANDOVER section 4 item 1. GFR rises with
        # EXTRACELLULAR volume in healthy humans, so this is bf.V_ecf and not
        # cv.V_blood - the two differ by f_pv and the sourced sensitivity is
        # against the iothalamate space.
        rn.V_ecf        ~ bf.V_ecf,
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
        # respiratory -> body fluids. ADDED 2026-09-04, ADR 0017. This is the
        # coupling that stops the respiratory component being an island on the day
        # it is built - the failure ADR 0006 records for Circadian, which sat
        # unconnected because it was built ahead of its dependency.
        bf.H2O_resp_rate ~ rs.H2O_resp,
        # -> blood. ADDED 2026-09-04, ADR 0018. OXYGEN DELIVERY IS THE FIRST
        # QUANTITY IN THIS MODEL THAT NEEDS TWO SUBSYSTEMS AT ONCE: content comes
        # from the respiratory side, flow from the cardiovascular side, and it is
        # their product. Every earlier coupling passed a signal or a flux.
        bl.PaCO2        ~ rs.PaCO2,
        bl.CO           ~ cv.CO,
        # thyroid -> respiratory. ADDED 2026-09-05, ADR 0019. Thyroid hormone sets
        # resting metabolic rate and therefore CO2 production, which is the load the
        # respiratory loop balances. WITH THE METABOLIC ARM OFF THIS CARRIES THE
        # CONSTANT 1.0 - the edge exists so that the declaration and the model agree
        # in both configurations, which is the discipline `model_couplings` records
        # four defects for lacking.
        rs.th_mod       ~ ty.th_mod,
    ]

    systems = [bf, cv, rn, br, ra, ad, rs, bl, ty]

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
    model_couplings()

The declared coupling graph of the whole model, deduplicated.

CONNECTED 2026-08-27. Every component has had a `*_couplings()` function since it
was written and NOTHING HAS EVER CALLED ONE. Seven declaration functions, plus
`coupling_ledger_rows`, `suggest_boundary` and `partitionable`, all dead. ADR 0003's
partition rule was enforced by `validate_partition`, which had no graph to validate.

Assembling it found four defects, none of which any of the five gates can see:

  1. `bodyfluids -> endocrine` named a subsystem that does not exist. Worse than a
     typo: `validate_partition` skips any edge whose endpoint is not in the
     assignment, so the edge was guaranteed never to be checked.
  2. `circadian -> cardiovascular` was the wrong endpoint. The clock scales the
     BAROREFLEX setpoint (`br.cv_mod ~ clk.cv_mod`).
  3. `cardiovascular -> bodyfluids` exists in the model and was declared nowhere.
  4. `CIRC_CV_MAP_DIP_FRACTION` is not a ledger parameter. It is the dangling
     provenance pointer `coupling_ledger_rows` exists to catch.

Edges are declared by BOTH endpoints by convention, so duplicates are expected and
are removed here. A duplicate that disagrees on KIND is not a duplicate and is left
for `assert_couplings_match_model` to reject.
"""
function model_couplings()
    all = vcat(bodyfluids_couplings(), cardiovascular_couplings(), renal_couplings(),
               baroreflex_couplings(), raas_couplings(), adh_couplings(),
               circadian_couplings(), respiratory_couplings(), blood_couplings(),
               thyroid_couplings())
    seen = Set{Tuple{Symbol,Symbol,CouplingKind}}()
    out = Coupling[]
    for c in all
        k = (c.from, c.to, c.kind)
        k in seen && continue
        push!(seen, k)
        push!(out, c)
    end
    return out
end

"""
    model_edges()

The subsystem-level edges actually present in `build_raw_model`, as `(from, to)`.

Hand-maintained to mirror the `connections` vector above, and asserted against the
declarations by `assert_couplings_match_model`. It is written out rather than derived
from the symbolic system because the connection equations name namespaced VARIABLES
(`rn.MAP ~ cv.MAP`), and mapping those back to subsystems is exactly the step where a
mistake would reintroduce the class of defect this function exists to catch.
"""
model_edges() = Set([
    (:bodyfluids, :cardiovascular),   # cv.V_ecf ~ bf.V_ecf
    (:cardiovascular, :renal),        # rn.MAP ~ cv.MAP
    (:bodyfluids, :renal),            # rn.C_Na ~ bf.C_Na, rn.V_ecf ~ bf.V_ecf
    (:cardiovascular, :renal),        # rn.V_blood ~ cv.V_blood - ADR 0010
    (:renal, :bodyfluids),            # bf.Na_excr_rate, bf.H2O_excr_rate
    (:respiratory, :bodyfluids),      # bf.H2O_resp_rate ~ rs.H2O_resp - ADR 0017
    (:respiratory, :blood),           # bl.PaCO2 ~ rs.PaCO2 - ADR 0018
    (:thyroid, :respiratory),         # rs.th_mod ~ ty.th_mod - ADR 0019
    (:cardiovascular, :blood),        # bl.CO ~ cv.CO - ADR 0018
    (:cardiovascular, :bodyfluids),   # bf.MAP ~ cv.MAP - INERT, ADR 0010 hook
    (:cardiovascular, :baroreflex),   # br.MAP ~ cv.MAP
    (:baroreflex, :cardiovascular),   # cv.tpr_mod ~ br.tpr_mod
    (:cardiovascular, :raas),         # ra.MAP ~ cv.MAP
    (:raas, :renal),                  # rn.fr_mod ~ ra.fr_mod
    (:bodyfluids, :adh),              # ad.Osm_ecf ~ bf.Osm_ecf
    (:adh, :renal),                   # rn.u_osm ~ ad.u_osm
    (:circadian, :renal),             # rn.renal_mod ~ clk.renal_mod
    (:circadian, :baroreflex),        # br.cv_mod ~ clk.cv_mod
])

"""
    assert_couplings_match_model()

Assert the DECLARED coupling graph is exactly the graph the model is built from,
and that every declared `gain_param` resolves to a ledger constant.

This is the check whose absence let four defects sit in the declarations
indefinitely. Returns a NamedTuple of the discrepancies; throws on any.
"""
function assert_couplings_match_model()
    cs = model_couplings()
    declared = Set((c.from, c.to) for c in cs)
    actual   = model_edges()

    undeclared = setdiff(actual, declared)
    phantom    = setdiff(declared, actual)

    subsystems = Set([:bodyfluids, :cardiovascular, :renal, :baroreflex,
                      :raas, :adh, :circadian, :respiratory, :blood,
                      :thyroid])
    unknown = [c for c in cs if !(c.from in subsystems) || !(c.to in subsystems)]

    dangling = Symbol[]
    for r in coupling_ledger_rows(cs)
        startswith(r, "COUPLE.") && continue      # tau rows, not ledger constants yet
        isdefined(LedgerParams, Symbol(r)) || push!(dangling, Symbol(r))
    end

    isempty(unknown) || error("Coupling names a subsystem that does not exist " *
        "(validate_partition SILENTLY SKIPS these):
" *
        join(["  $(c.from) -> $(c.to)" for c in unknown], "
"))
    isempty(undeclared) || error("Model has connections declared by no component:
" *
        join(["  $(e[1]) -> $(e[2])" for e in undeclared], "
"))
    isempty(phantom) || error("Components declare couplings the model does not build:
" *
        join(["  $(e[1]) -> $(e[2])" for e in phantom], "
"))
    isempty(dangling) || error("Coupling gain_param is not a ledger parameter:
" *
        join(["  $(d)" for d in dangling], "
"))

    return (n_couplings = length(cs), undeclared = undeclared, phantom = phantom,
            unknown = unknown, dangling = dangling)
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
        # WITHIN-CYCLE RECONSTRUCTION (ADR 0002, reconstruct.jl). Systolic and
        # diastolic are NOT simulated - the cardiac cycle was averaged away - so
        # they are reconstructed here from the cycle-averaged MAP and SV and
        # carried in fields named to say so. reconstruct.jl sat unconnected from
        # the beginning of the repo because SV and C_art did not exist; ADR 0011
        # created SV and the CV.MAP.SETPOINT sourcing pass created C_art.
        #
        # sex is threaded through because CV.ARTERIAL.COMPLIANCE is a male/female
        # pair and ADR 0014 makes :both an error rather than an average.
        map_cyc = _cyc("MAP")
        sv_cyc  = _cyc("SV")
        recon   = reconstruct_pressures(map_cyc, sv_cyc; sex)

        push!(results, (level = level,
                        index = i,
                        t_start = t0,
                        t_end = t0 + days_per_level,
                        sol = sol,
                        MAP_cycavg = map_cyc,
                        SV_cycavg = sv_cyc,
                        Na_excr_cycavg = _cyc("Na_excr"),
                        MAP_final = _final(sol, sys, "MAP"),
                        V_ecf_final = _final(sol, sys, "V_ecf"),
                        Na_excr_final = _final(sol, sys, "Na_excr"),
                        Na_ecf_final = _final(sol, sys, "Na_ecf"),
                        # RECONSTRUCTED, not simulated. Label as such.
                        SBP_reconstructed = recon.systolic,
                        DBP_reconstructed = recon.diastolic,
                        PP_reconstructed = recon.pulse))
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
function solver_agreement(sys; solvers = [FBDF(), Rodas5P()],
                          atol = 1e-6, rtol = 1e-4, kwargs...)
    sols = [solve_individual(sys; solver = s, kwargs...) for s in solvers]
    ref = Array(sols[1])
    worst = 0.0
    for s in sols[2:end]
        A = Array(s)
        size(A) == size(ref) || error("solver_agreement requires identical saveat grids")
        # `|A - B| / (atol + rtol*|ref|)`, the standard ODE accept criterion.
        # A result below 1.0 means the two solvers agree to within a tolerance
        # no looser than the one they were each integrated to.
        #
        # THIS IS THE SECOND REVISION OF THIS METRIC AND THE FIRST WAS ONLY HALF
        # RIGHT. It originally divided by max(|ref|, 1e-12), a pure ratio that
        # exploded on any state legitimately sitting at zero. That was replaced
        # on 2026-08-25 by a floor of `atol`, which fixed the symptom and left
        # the shape wrong: a bare floor is still an arbitrary constant, and when
        # ADR 0011 perturbed the trajectory enough to move RAAS `esc` from 2e-17
        # to 7e-10 the same failure returned - 6.9e-4 reported against a 1e-4
        # threshold while every state carrying real magnitude agreed to 3e-7.
        #
        # A mixed criterion has no such cliff: near zero it is absolute, at scale
        # it is relative, and it is what the solvers themselves use. Recorded
        # rather than quietly retuned, because changing a test metric twice to
        # accommodate two failures is exactly what moving the goalposts looks
        # like, and the defence is that the metric was wrong both times in the
        # same way.
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
        #
        # THIRD REVISION, 2026-09-02, AND THE NOTE ABOVE PREDICTED IT: "any future
        # component with a zero-valued state would have hit it too." ADR 0010's
        # volume-keyed natriuretic signal is one. It is initialised at exactly 0.0
        # and grows to 12.1 mEq/day; the two solvers disagreed by 2.9e-5 in
        # absolute terms, which is 2.4e-6 of the state's own magnitude and 1.4e-7
        # of the sodium flux it modifies, and the metric reported 2.9.
        #
        # THE FIRST TWO REVISIONS FIXED THE FLOOR AND KEPT THE CRITERION
        # POINTWISE, and that is the actual defect. A pointwise denominator is
        # degenerate wherever a trajectory passes through zero, which is a
        # property of TRAJECTORIES rather than of components - so no choice of
        # floor can fix it, and each new near-zero state re-breaks it.
        #
        # Normalising by the state's own CHARACTERISTIC SCALE over the run removes
        # the cliff permanently: near zero the comparison is still absolute
        # through atol, at scale it is still relative through rtol, and a state
        # that starts at zero is judged against the magnitude it actually reaches
        # rather than against the instant it happened to be crossing zero.
        scale = maximum(abs.(ref); dims = 2)
        worst = max(worst, maximum(abs.(A .- ref) ./ (atol .+ rtol .* scale)))
    end
    return (max_rel_deviation = worst, solutions = sols)
end
