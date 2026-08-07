"""
Benchmarks tied to the stated workload, not to microbenchmarks.

Required by CONTRIBUTING.md for any PR touching numerics or performance.
The number that matters: individual-days of simulated physiology per wall-clock
minute per core, and peak RSS for a 1000-member ensemble.
"""
using IPE, BenchmarkTools, Printf

function bench_individual(; horizons = (1.0, 30.0, 365.0), qss = (false, true))
    for q in qss, h in horizons
        sys = build_model(qss = q)
        t = @belapsed solve_individual($sys; tspan_days = $h, saveat = 1.0)
        @printf("qss=%-5s horizon=%6.0f d   %8.3f s   %10.1f sim-days/s\n", q, h, t, h / t)
    end
end

function bench_population(; n = 1000, horizon = 30.0)
    sys = build_model(qss = true)
    pop = IPE.sample_population(n)
    t = @elapsed run_population(sys, pop; tspan_days = horizon, saveat = 5.0)
    @printf("n=%d horizon=%.0f d  %.1f s  %.1f member-runs/s  peak RSS %.2f GB\n",
            n, horizon, t, n / t, Sys.maxrss() / 2^30)
end
