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
  - Subsystems are components with a declared interface. Each may expose a
    quasi-steady-state form so long-horizon runs can collapse fast loops instead of
    integrating them.
  - Ensembles are the primary workload. Per-run memory is the binding constraint.

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

include("components/BodyFluids.jl")
include("assemble.jl")
include("ensemble.jl")

export build_model, solve_individual, run_population
export LedgerParams, provenance, unledgered_check

end # module
