"""
Recording strategy: reduce in flight, never materialise.

THE BINDING CONSTRAINT is storage, not compute. At 5 s resolution a 30-day run is
518,400 points per individual; a 1000-member population at 500 saved states is
roughly 0.9 TB. The integration to produce that is a few hours on a workstation.
The storage is not tractable at any budget worth spending.

So the rule for ensembles: an ensemble member returns SUMMARY STATISTICS, never a
trajectory. Full 5 s trajectories are for single individuals and for narrow event
windows, on request.

Three recording modes:

  `FullTrace`      - every saveat point retained. Single individuals only. Will
                     exhaust RAM in an ensemble; guarded against.
  `StreamingStats` - online accumulators updated at each saveat point, trajectory
                     discarded. O(1) memory per member regardless of horizon.
                     DEFAULT for populations.
  `EventWindows`   - coarse recording throughout, full 5 s resolution only inside
                     declared challenge windows. The usual right answer when you
                     want fine detail around perturbations over a long horizon.

Note on cost: `saveat` does NOT set step size. The solver steps as accuracy demands
and interpolates onto the output grid. Requesting 5 s output therefore costs storage;
it costs compute only if the physiology carries persistently active fast modes that
bound the step size from below.
"""

using DiffEqCallbacks
using SciMLBase

abstract type RecordingMode end

# ---------------------------------------------------------------------------
# Online accumulators - O(1) memory, no trajectory retained
# ---------------------------------------------------------------------------

"""
Welford online moments plus extrema and time-weighted mean.

Time-weighted rather than sample-weighted because adaptive output grids and event
windows produce non-uniform spacing, and a naive mean over saved points would then
silently over-weight the densely-sampled intervals - i.e. exactly the perturbation
windows you care about, biasing every summary toward the transient.
"""
mutable struct OnlineStat
    n::Int
    mean::Float64
    m2::Float64
    min::Float64
    max::Float64
    tw_sum::Float64      # integral of value dt
    t_span::Float64
    t_last::Float64
    v_last::Float64
end

OnlineStat() = OnlineStat(0, 0.0, 0.0, Inf, -Inf, 0.0, 0.0, NaN, NaN)

function update!(s::OnlineStat, t::Float64, x::Float64)
    s.n += 1
    d = x - s.mean
    s.mean += d / s.n
    s.m2 += d * (x - s.mean)
    s.min = min(s.min, x)
    s.max = max(s.max, x)
    if !isnan(s.t_last)
        dt = t - s.t_last
        s.tw_sum += 0.5 * (x + s.v_last) * dt   # trapezoid
        s.t_span += dt
    end
    s.t_last = t
    s.v_last = x
    return s
end

variance(s::OnlineStat) = s.n > 1 ? s.m2 / (s.n - 1) : NaN
timeweighted_mean(s::OnlineStat) = s.t_span > 0 ? s.tw_sum / s.t_span : NaN

function summarise(s::OnlineStat)
    return (n = s.n, mean = s.mean, sd = sqrt(variance(s)),
            min = s.min, max = s.max, twmean = timeweighted_mean(s))
end

# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------

"""Retain everything. Single individuals only."""
struct FullTrace <: RecordingMode
    saveat::Float64
end
FullTrace(; saveat_seconds = 5.0) = FullTrace(saveat_seconds / 86400.0)

"""
Online statistics over named observables; trajectory discarded.
Memory is O(number of tracked observables), independent of horizon.
"""
struct StreamingStats <: RecordingMode
    saveat::Float64
    observables::Vector{Symbol}
end
function StreamingStats(observables; saveat_seconds = 5.0)
    StreamingStats(saveat_seconds / 86400.0, collect(observables))
end

"""
Coarse throughout, fine inside declared windows.

`windows` are (start_day, stop_day) pairs - typically your challenge protocols.
This is the mode that makes "5 s resolution over a year" affordable: you get 5 s
detail where the physiology is actually doing something and minute-scale elsewhere.
"""
struct EventWindows <: RecordingMode
    coarse::Float64
    fine::Float64
    windows::Vector{Tuple{Float64,Float64}}
    observables::Vector{Symbol}
end
function EventWindows(windows, observables;
                      coarse_seconds = 300.0, fine_seconds = 5.0)
    EventWindows(coarse_seconds / 86400.0, fine_seconds / 86400.0,
                 collect(windows), collect(observables))
end

"""Build the explicit save grid for windowed recording."""
function save_grid(m::EventWindows, tspan::Tuple{Float64,Float64})
    grid = collect(tspan[1]:m.coarse:tspan[2])
    for (a, b) in m.windows
        append!(grid, collect(a:m.fine:b))
    end
    return unique!(sort!(grid))
end

function grid_size_report(m::EventWindows, tspan, nstates)
    n = length(save_grid(m, tspan))
    naive = (tspan[2] - tspan[1]) / m.fine
    return (points = n, naive_points = naive,
            reduction = naive / n,
            bytes_f32 = n * nstates * 4)
end

# ---------------------------------------------------------------------------
# Ensemble output functions
# ---------------------------------------------------------------------------

"""
    streaming_output_func(mode::StreamingStats, sys)

Ensemble `output_func` that returns summaries and drops the solution.

The returned object must be small. Returning `sol` - even accidentally, by closing
over it - reintroduces the terabyte. There is a guard for this in the test suite.
"""
function streaming_output_func(mode::StreamingStats, sys)
    return function (sol, i)
        stats = Dict{Symbol,OnlineStat}(o => OnlineStat() for o in mode.observables)
        for (k, t) in enumerate(sol.t)
            for o in mode.observables
                update!(stats[o], t, Float64(sol[o][k]))
            end
        end
        reduced = (member = i,
                   retcode = sol.retcode,
                   nf = sol.stats.nf,
                   njacs = sol.stats.njacs,
                   stats = Dict(o => summarise(s) for (o, s) in stats))
        return (reduced, false)
    end
end

"""
    projected_storage(; n_members, horizon_days, dt_seconds, n_states, bits = 32)

Print the storage a naive full-trace ensemble would need. Call this before launching
a long run. It is cheaper to be told the number now than to discover it at hour six.
"""
function projected_storage(; n_members, horizon_days, dt_seconds, n_states, bits = 32)
    pts = horizon_days * 86400 / dt_seconds
    total = pts * n_states * (bits / 8) * n_members
    gb = total / 2^30
    @info "Projected full-trace storage" points_per_member=pts total_GB=round(gb, digits=2)
    gb > 100 && @warn "Full trace is not viable at this scale - use StreamingStats or EventWindows."
    return gb
end
