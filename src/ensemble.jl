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
function sample_population(n::Int; body_mass_dist = Normal(70.0, 12.0))
    lb = [quantile(body_mass_dist, 0.01)]
    ub = [quantile(body_mass_dist, 0.99)]
    s = QuasiMonteCarlo.sample(n, lb, ub, SobolSample())
    return [(body_mass = s[1, i],) for i in 1:n]
end

"""
    run_population(sys, population; tspan_days = 30.0, output_func = default_summary, ...)

Run an ensemble and return reduced outputs.

`output_func` runs inside the worker and its return value is what gets kept. Keep it
small. Returning the solution object defeats the purpose.
"""
function run_population(sys, population;
                        tspan_days = 30.0,
                        saveat = 1.0,
                        solver = FBDF(),
                        output_func = default_summary,
                        ensemble_alg = EnsembleThreads(),
                        kwargs...)

    base = ODEProblem(sys, [], (0.0, tspan_days), []; jac = true, sparse = true)

    function prob_func(prob, i, repeat)
        # remake with this member's parameters - no re-simplification, no codegen
        return remake(prob; p = member_parameters(prob, population[i]))
    end

    eprob = EnsembleProblem(base;
                            prob_func,
                            output_func = (sol, i) -> (output_func(sol, i), false))

    return solve(eprob, solver, ensemble_alg;
                 trajectories = length(population),
                 saveat, dense = false, save_everystep = false,
                 kwargs...)
end

"""Map a population member onto the problem's parameter vector. TODO: fill in as
subsystems land; keep it allocation-free."""
member_parameters(prob, member) = prob.p

"""Default reduction: keep endpoints and extrema, discard the trajectory."""
function default_summary(sol, i)
    return (member = i,
            retcode = sol.retcode,
            final = sol.u[end],
            n_steps = sol.stats.nf)
end
