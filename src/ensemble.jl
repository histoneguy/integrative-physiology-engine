"""
Population studies.

Primary workload: many virtual individuals, long horizons, one workstation.
Design constraints follow from that and not from single-run latency.

  - Build and simplify the model ONCE. Ensemble members differ only in parameters
    and initial conditions, so code generation is shared.
  - `EnsembleThreads` saturates a workstation without cluster orchestration.
    Move to `EnsembleDistributed` only when a single machine is genuinely exhausted.
  - Reduce in-flight. `output_func` should extract the summary statistics you
    actually need and discard the trajectory. Retaining full solutions for a
    thousand members is what makes people think they need expensive cloud time.
"""

using Distributions
using QuasiMonteCarlo

"""
    sample_population(n; rng_seed = 1, ...)

Draw parameter vectors for a virtual population.

Sobol sequences rather than independent random draws: far better coverage of the
parameter space per sample, which matters when each sample is a multi-day
integration. Correlations between physiological parameters are real and currently
ignored here - a copula or a fitted joint distribution belongs here once the ledger
carries enough covariance information to justify one.
"""
function sample_population(n::Int; sex::Symbol = :male,
                           lo = LedgerParams.param(:BF_BODY_MASS_P05, sex),
                           hi = LedgerParams.param(:BF_BODY_MASS_P95, sex))
    # WAS `body_mass_dist = Normal(70.0, 12.0)`, WITH THE MEAN AND THE SD BOTH
    # HARD-CODED AND UNLEDGERED - which directive 1.4 forbids. It was inert while
    # nothing called the ensemble; the ensemble runs now, so it was live and
    # driving every population result.
    #
    # Bounds now come from NHANES 2021-2023 Table 3, per sex: male 60.9 to 131.8
    # kg, female 50.7 to 119.2 kg.
    #
    # THE NORMAL WAS NEVER DOING WHAT IT LOOKED LIKE IT WAS DOING. This function
    # only ever took the 1st and 99th percentiles of the distribution it was
    # handed and then sampled UNIFORMLY between them with Sobol. The distribution
    # supplied bounds and nothing else - the shape was discarded. Taking sourced
    # percentiles directly is therefore not a loss of information; it makes the
    # existing behaviour honest, and it avoids inventing a standard deviation the
    # source does not report (see the BF.BODY_MASS.P05 ledger note: two standard
    # SD estimators disagree by 15% because body weight is right-skewed, and the
    # pre-registration declared no estimator).
    #
    # KNOWN LIMITATION, now explicit rather than disguised: the sampled
    # population is UNIFORM over the 5th-95th percentile range, not
    # weight-distributed, so it over-represents the tails. Fixing that needs a
    # declared distribution family and a pre-declared SD estimator.
    s = QuasiMonteCarlo.sample(n, [float(lo)], [float(hi)], SobolSample())
    return [(body_mass = s[1, i],) for i in 1:n]
end

"""
    run_population(sys, population; tspan_days = 30.0, output_func = default_summary, ...)

Run an ensemble and return reduced outputs.

`output_func` runs inside the worker and its return value is what gets kept. Keep it
small. Returning the solution object defeats the purpose.
"""
function run_population(sys, population;
                        sex::Symbol = :male,
                        tspan_days = 30.0,
                        saveat = 1.0,
                        solver = FBDF(),
                        output_func = default_summary,
                        ensemble_alg = EnsembleThreads(),
                        kwargs...)

    base = ODEProblem(sys, [], (0.0, tspan_days), []; jac = true, sparse = true)

    # SciMLBase now hands prob_func/output_func an EnsembleContext rather than a
    # bare Int, and has changed the arity it calls them with. Accept both: pinning
    # the old signature produced a MethodError whose message is 400 lines of type
    # parameters, and pinning the new one would break the moment it changes again.
    function prob_func(prob, i, args...)
        # remake with this member's parameters AND initial conditions - no
        # re-simplification, no codegen. See member_remake for why both.
        return member_remake(prob, sys, population[member_index(i)]; sex)
    end

    # safetycopy = false. EnsembleProblem deepcopies the base problem before each
    # prob_func call by default, and the copy loses the symbolic index cache, so a
    # remake with symbolic u0/p maps throws about eliminated states
    # (`bf.Na_store` when storage = false). member_remake is non-mutating - remake
    # returns a new problem - so the copy protects nothing and costs a deepcopy of
    # the compiled problem per member, which is exactly what "build and simplify
    # ONCE" in the module docstring is trying to avoid.
    eprob = EnsembleProblem(base;
                            prob_func,
                            safetycopy = false,
                            output_func = (sol, i, args...) ->
                                (output_func(sol, member_index(i), sys), false))

    return solve(eprob, solver, ensemble_alg;
                 trajectories = length(population),
                 saveat, dense = false, save_everystep = false,
                 kwargs...)
end

"""
    member_index(i)

The trajectory index, whether SciMLBase passes an `Int` or an `EnsembleContext`.

Recent SciMLBase passes a context struct where it used to pass the index. Reading
`sim_id` off it - and still accepting a plain `Int` - keeps this working across both
without pinning either.
"""
member_index(i::Integer) = Int(i)
member_index(ctx) = Int(getfield(ctx, :sim_id))

"""
    member_remake(prob, sys, member)

Apply one population member to the base problem.

CONNECTED 2026-08-27. This replaced

    member_parameters(prob, member) = prob.p

which returned the problem's parameters UNCHANGED. `sample_population` has always
drawn a Sobol sequence over body mass, `run_population` has always fanned it out,
and every member solved the SAME 70 kg individual. The ensemble ran; it just did
not vary anything. Nothing called `run_population`, so nothing noticed.

WHY THE STUB COULD NOT HAVE WORKED AS WRITTEN. `body_mass` is not a single
parameter. In `BodyFluids` it sets

  * the parameter `m_body`;
  * the parameter `Osm_solute_icf`, the conserved intracellular solute content,
    which is `Osm_set * body_mass * f_icf`; and
  * the INITIAL CONDITIONS of `V_icf`, `V_ecf` and `Na_ecf`.

A `remake` that touches only `p` therefore cannot vary body mass at all - it would
give every member a 70 kg starting volume with a different `m_body`, which is not a
smaller person but an inconsistent one. Both `p` and `u0` have to move together, and
the ICF solute content has to move with them or the cell starts off anisosmolar.
That coupling is the reason this was left as a TODO, and it is the reason it has to
be done in one place rather than by callers.
"""
function member_remake(prob, sys, member; sex::Symbol = :male)
    bm = member.body_mass
    sz = size_factor(bm)
    return remake(prob;
        # EVERY EXTENSIVE PARAMETER, because the base problem was built at the
        # reference mass. The components apply this same scaling at BUILD time;
        # here it has to be reapplied through remake, since the whole point of an
        # ensemble is to avoid rebuilding. The two paths must agree, and the test
        # suite asserts they do rather than trusting that they do.
        p = [sys.bf.m_body         => bm,
             sys.bf.Osm_solute_icf => BF_OSM_PLASMA_SETPOINT * bm * BF_ICF_MASS_FRACTION,
             sys.bf.Na_intake      => sz * BF_NA_INTAKE_NOMINAL,
             sys.bf.H2O_intake     => sz * BF_H2O_INTAKE_NOMINAL,
             sys.bf.H2O_insens     => sz * BF_H2O_INSENSIBLE_LOSS,
             sys.rn.GFR0           => sz * RN_GFR_NOMINAL,
             sys.rn.G_pn           => sz * RN_PRESSURE_NATRIURESIS_SLOPE,
             sys.rn.Osm_ref        => sz * RN_URINE_SOLUTE_LOAD,
             sys.rn.Osm_nonNa      => sz * RN_URINE_SOLUTE_NONNA,
             # ADR 0010's volume-keyed natriuretic path, added 2026-09-02. BOTH
             # halves scale: the gain is an excretion per litre and the reference
             # is a volume. OMITTING V_blood_ref made every heavy member read as
             # massively volume-expanded, and the body-size testset below caught
             # it immediately - MAP spread went from under 1e-4 mmHg to 37.8.
             # That is exactly the "two encodings of one rule" this list warns
             # about, and it is why the assertion exists.
             # INTENSIVE - it multiplies a volume, which already scales. See the
             # note in Renal.jl. Only the REFERENCE volume scales here.
             sys.rn.G_anp          => CV_ANP_NATRIURETIC_GAIN,
             sys.rn.V_blood_ref    => sz * LedgerParams.param(:CV_BLOOD_VOLUME_NOMINAL, sex),
             sys.cv.CO0            => sz * LedgerParams.param(:CV_CO_NOMINAL, sex),
             sys.cv.BV0            => sz * LedgerParams.param(:CV_BLOOD_VOLUME_NOMINAL, sex),
             sys.cv.VC0            => sz * LedgerParams.param(:CV_CENTRAL_VOLUME_NOMINAL, sex),
             sys.cv.SV0            => sz * LedgerParams.param(:CV_SV_NOMINAL, sex),
             # RECIPROCAL. MAP = CO*TPR and CO scales, so resistance must fall or
             # larger people come out hypertensive. See src/scaling.jl.
             sys.cv.TPR0           => LedgerParams.param(:CV_TPR_NOMINAL, sex) / sz],
        u0 = [sys.bf.V_icf  => bm * BF_ICF_MASS_FRACTION,
              sys.bf.V_ecf  => bm * BF_ECF_MASS_FRACTION,
              sys.bf.Na_ecf => bm * BF_ECF_MASS_FRACTION * BF_NA_PLASMA_SETPOINT])
end

"""
Default reduction: keep the quantities this model exists to produce, discard the
trajectory.

Returns MAP and ECF volume rather than `sol.u[end]`. The raw state vector is
positional, so its meaning changes silently whenever `structural_simplify` reorders
states - which it does whenever a component is added. A summary that cannot survive
adding a subsystem is not a summary.
"""
function default_summary(sol, i, sys)
    # sys is passed in rather than read off `sol.prob.f.sys`. That field is not the
    # simplified system, so indexing the solution with symbols taken from it throws
    # about states structural_simplify has already eliminated - the first attempt
    # here died on `bf.Na_store`, which does not exist when storage = false.
    grab(name) = try
        sol[_obs(sys, name)][end]
    catch
        NaN
    end
    return (member = i,
            retcode = sol.retcode,
            MAP_final = grab("MAP"),
            V_ecf_final = grab("V_ecf"),
            n_steps = sol.stats.nf)
end
