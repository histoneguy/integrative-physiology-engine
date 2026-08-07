"""
Inter-subsystem coupling as a first-class object.

Couplings carry their own dynamics. Making that explicit - rather than burying it in
subsystem equations - does three things at once:

  1. Defines a physiologically motivated partition boundary for multirate integration
     (ADR 0003), replacing an arbitrary one.
  2. Puts coupling time constants in the ledger, where they belong. These are better
     measured than coupling GAINS - aldosterone response time, renin half-life,
     baroreflex latency are directly measured and well replicated, whereas gains are
     frequently fitted. See the `calibrated` entries in the ledger.
  3. Makes the fast/slow assignment auditable instead of implicit.

THE PARTITION RULE

  Lagged (neurohumoral) coupling  -> SAFE to partition across.
      The lag low-pass filters the upstream signal, so the downstream block never
      sees high-frequency content and interpolation error is attenuated by the same
      dynamics that make the coupling physiological. The lag IS the interpolator.

  Instantaneous (mechanical / mass-balance) coupling -> NEVER partition across.
      Hydraulic coupling (blood volume -> venous return -> cardiac filling) and
      algebraic conservation (Na content and volume determining concentration) have
      no lag to hide interpolation error behind. Both endpoints must sit in the
      same block.

This is checked mechanically by `validate_partition`.
"""

"""Kind of coupling. Determines whether a partition may cut across it."""
@enum CouplingKind begin
    Neurohumoral    # first-order lag, measured tau, safe to partition across
    Mechanical      # hydraulic/pressure-flow, effectively instantaneous
    Conservation    # mass/volume/solute balance, algebraic, exactly instantaneous
end

partitionable(k::CouplingKind) = k === Neurohumoral

"""
    Coupling(from, to, kind; tau_seconds, gain_param, citation_note)

A declared connection between subsystems.

`tau_seconds` is required for `Neurohumoral` and must be `nothing` for the others -
an instantaneous coupling with a time constant is a contradiction and is rejected at
construction.

`gain_param` names the ledger entry for the coupling strength. Expect many of these
to be `calibrated` rather than `reported`; that is the honest state of the field, and
`unledgered_check()` keeps them visible.
"""
struct Coupling
    from::Symbol
    to::Symbol
    kind::CouplingKind
    tau_seconds::Union{Float64,Nothing}
    gain_param::Union{Symbol,Nothing}
    note::String
end

function Coupling(from::Symbol, to::Symbol, kind::CouplingKind;
                  tau_seconds = nothing, gain_param = nothing, note = "")
    if kind === Neurohumoral && tau_seconds === nothing
        error("Neurohumoral coupling $from -> $to requires tau_seconds. " *
              "If it is genuinely instantaneous it is not neurohumoral.")
    end
    if kind !== Neurohumoral && tau_seconds !== nothing
        error("$kind coupling $from -> $to must not carry tau_seconds. " *
              "Instantaneous coupling with a time constant is a contradiction.")
    end
    return Coupling(from, to, kind, tau_seconds, gain_param, note)
end

# ---------------------------------------------------------------------------
# Partition validation
# ---------------------------------------------------------------------------

"""
    validate_partition(couplings, assignment)

Check a proposed fast/slow assignment against the partition rule.

`assignment` maps subsystem name -> `:fast` or `:slow`.

Fails if any Mechanical or Conservation coupling spans the boundary. Warns if a
Neurohumoral coupling has a time constant close to the boundary timescale - a lag
sitting AT the cut is the one case where the filtering argument does not protect you,
because the coupling is neither clearly fast nor clearly slow.
"""
function validate_partition(couplings::Vector{Coupling},
                            assignment::Dict{Symbol,Symbol};
                            boundary_seconds::Float64)
    violations = Coupling[]
    marginal   = Coupling[]

    for c in couplings
        a = get(assignment, c.from, nothing)
        b = get(assignment, c.to, nothing)
        (a === nothing || b === nothing) && continue
        a === b && continue                      # coupling is internal to a block

        if !partitionable(c.kind)
            push!(violations, c)
        else
            # lag sitting near the cut - filtering argument is weakest here
            r = c.tau_seconds / boundary_seconds
            (0.1 < r < 10) && push!(marginal, c)
        end
    end

    if !isempty(violations)
        msg = join(["  $(c.from) -> $(c.to) [$(c.kind)]" for c in violations], "\n")
        error("Partition cuts across instantaneous coupling. Both endpoints must " *
              "share a block:\n" * msg)
    end
    if !isempty(marginal)
        msg = join(["  $(c.from) -> $(c.to) tau=$(c.tau_seconds) s" for c in marginal], "\n")
        @warn "Neurohumoral couplings with time constants near the partition " *
              "boundary. The low-pass filtering argument is weakest here - these " *
              "need boundary_sensitivity results before the partition is trusted:\n" * msg
    end
    return (ok = true, marginal = marginal)
end

"""
    suggest_boundary(couplings)

Report the distribution of neurohumoral time constants and the largest gap.

Unlike `timescale_audit`, which works on the Jacobian spectrum, this works on the
DECLARED physiological time constants - so a gap here is a statement about physiology
rather than about the current numerical state. Both should be consulted; agreement
between them is a good sign, disagreement means the model's declared structure and
its numerical behaviour have diverged.
"""
function suggest_boundary(couplings::Vector{Coupling})
    taus = sort([c.tau_seconds for c in couplings if partitionable(c.kind)])
    isempty(taus) && return (taus = Float64[], gap = nothing)
    gaps = [(taus[i+1] / taus[i], taus[i], taus[i+1]) for i in 1:length(taus)-1]
    isempty(gaps) && return (taus = taus, gap = nothing)
    best = argmax(g -> g[1], gaps)
    best[1] < 10 && @warn "No clear gap in declared coupling timescales " *
                          "(largest ratio $(round(best[1], digits=1))x). " *
                          "Physiological timescales form a continuum; any boundary " *
                          "is a modelling choice requiring boundary_sensitivity."
    return (taus = taus, gap = best,
            suggested_boundary_seconds = sqrt(best[2] * best[3]))
end

"""
    coupling_ledger_rows(couplings)

Emit the ledger rows a coupling set requires, so none is introduced without
provenance. Every tau and every gain needs a citation like any other parameter.
"""
function coupling_ledger_rows(couplings::Vector{Coupling})
    rows = String[]
    for c in couplings
        if c.tau_seconds !== nothing
            push!(rows, "COUPLE.$(uppercase(string(c.from)))_$(uppercase(string(c.to))).TAU")
        end
        c.gain_param !== nothing && push!(rows, string(c.gain_param))
    end
    return rows
end
