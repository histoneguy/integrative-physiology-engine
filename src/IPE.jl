"""
    IPE

Integrative Physiology Engine.

An independent implementation of whole-body integrative human physiology built from
the peer-reviewed literature. See SOURCES.md for the source whitelist policy.

Architecture:
  - Model is authored symbolically (ModelingToolkit) and compiled. Nothing is
    interpreted at run time.
  - Every numeric constant originates in ledger/parameters.csv and reaches code only
    via tools/ledger_to_julia.py. See LedgerParams.
  - CYCLE-AVERAGED (ADR 0002). Cardiac and respiratory cycles are not integrated.
    Within-cycle quantities are reconstructed algebraically - see reconstruct.jl -
    and are never reported as simulated. Cycle-averaging is itself the fast-mode
    reduction, so the per-component `qss` flag is near-vestigial; default false.
  - Ensembles are the primary workload. STORAGE is the binding constraint, not
    compute: at 5 s resolution a 1000-member 30-day population would materialise
    ~0.9 TB of trajectory. Members return summary statistics, never trajectories.
    See recording.jl.

STATUS: walking skeleton. The physiological payload is deliberately trivial and is
NOT a physiological claim. Its purpose is to prove the pipeline end to end -
ledger -> codegen -> symbolic model -> structural simplification -> compiled stiff
solve -> ensemble -> validation harness - before subsystem work begins.

UNVERIFIED: this code has not been executed. It was written without a Julia
toolchain available. Expect API drift against current ModelingToolkit; treat the
first task as getting `test/runtests.jl` green.
"""
module IPE

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D
using OrdinaryDiffEq
using SciMLBase

include("LedgerParams.jl")
using .LedgerParams

include("recording.jl")
include("reconstruct.jl")
include("coupling.jl")
include("profiling.jl")
include("components/Circadian.jl")
include("components/BodyFluids.jl")
include("assemble.jl")
include("ensemble.jl")

export build_model, solve_individual, run_population
export FullTrace, StreamingStats, EventWindows, projected_storage
export step_distribution, cost_profile, timescale_audit, boundary_sensitivity
export Coupling, CouplingKind, Neurohumoral, Mechanical, Conservation
export CircadianClock, cycle_average
export validate_partition, suggest_boundary
export LedgerParams, provenance, unledgered_check

end # module
