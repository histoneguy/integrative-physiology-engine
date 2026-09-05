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
using ADTypes: AutoForwardDiff, AutoFiniteDiff

include("mtk_compat.jl")
include("LedgerParams.jl")
using .LedgerParams

include("scaling.jl")
include("recording.jl")
include("reconstruct.jl")
include("coupling.jl")
include("profiling.jl")
include("components/Circadian.jl")
include("components/BodyFluids.jl")
include("components/Cardiovascular.jl")
include("components/Renal.jl")
include("components/Baroreflex.jl")
include("components/Raas.jl")
include("components/Adh.jl")
include("components/Respiratory.jl")
include("components/Blood.jl")
include("components/Thyroid.jl")
include("assemble.jl")
include("ensemble.jl")

export MTKSystem, mtk_simplify, mtk_unknowns
export build_model, build_raw_model, solve_individual, run_population, salt_step, check_pressure_natriuresis
export BodyFluids, Cardiovascular, Renal, Baroreflex, Raas, Adh, Respiratory, Blood
export FullTrace, StreamingStats, EventWindows, projected_storage
# recording.jl and ensemble.jl internals, connected 2026-08-27 - all of this
# was dead code, including the ensemble path HANDOVER calls the primary workload.
export save_grid, grid_size_report, streaming_output_func, OnlineStat
export sample_population, member_remake, default_summary
export step_distribution, cost_profile, timescale_audit, boundary_sensitivity
export Coupling, CouplingKind, Neurohumoral, Mechanical, Conservation
# The declared coupling graph, connected 2026-08-27. Every *_couplings()
# function had existed since its component was written and none was ever called.
export model_couplings, model_edges, assert_couplings_match_model
export bodyfluids_couplings, cardiovascular_couplings, renal_couplings
export baroreflex_couplings, raas_couplings, adh_couplings, respiratory_couplings
export blood_couplings, circadian_couplings
export coupling_ledger_rows
export CircadianClock, cycle_average
# Within-cycle reconstruction (ADR 0002). NOT simulated quantities - see
# reconstruct.jl and RECONSTRUCTED before reporting any of these.
export pulse_pressure, systolic_diastolic, reconstruct_pressures, RECONSTRUCTED
export validate_partition, suggest_boundary, partitionable
export LedgerParams, provenance, unledgered_check
export size_factor

end # module
