"""
Body fluid compartments - WALKING SKELETON COMPONENT.

This is a deliberately minimal two-compartment fluid and sodium balance. It exists to
exercise the architecture, not to make a physiological claim. It will be replaced.

What it demonstrates, and what every real subsystem must also do:

  1. Every constant comes from LedgerParams. No literals in the equations.
  2. Structure is cited in this docstring, per CONTRIBUTING.md.
  3. The component exposes a `qss` option that algebraically collapses its fast mode.
     This is the mechanism that makes month-long runs affordable: fast loops that
     have equilibrated contribute cost but no information.
  4. Conservation is asserted as an observable, so the test suite can check it as a
     hard invariant rather than eyeballing plots.

STRUCTURE SOURCES: none yet - the topology here is generic mass balance and is not
taken from any source. Real subsystems list their literature here.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams: BF_TBW_FRACTION, BF_ECF_FRACTION, BF_NA_PLASMA_SETPOINT,
                      BF_ICF_OSMOTIC_EQUILIBRATION_TAU, RN_PRESSURE_NATRIURESIS_GAIN,
                      CV_MAP_SETPOINT

"""
    BodyFluids(; name, qss = false, body_mass = 70.0)

Two-compartment fluid/solute balance with pressure-driven sodium excretion.

`qss = true` replaces the osmotic equilibration ODE with its algebraic equilibrium.
Use for horizons long relative to `BF_ICF_OSMOTIC_EQUILIBRATION_TAU`. This removes
the stiffest mode in the component and is the single most effective lever on
long-horizon cost - far more so than any micro-optimisation of the RHS.
"""
function BodyFluids(; name, qss::Bool = false, body_mass = 70.0)

    pars = @parameters begin
        m_body      = body_mass            # kg
        f_tbw       = BF_TBW_FRACTION      # unitless
        f_ecf       = BF_ECF_FRACTION      # unitless
        C_Na_set    = BF_NA_PLASMA_SETPOINT        # mEq/L
        tau_osm     = BF_ICF_OSMOTIC_EQUILIBRATION_TAU / 1440.0  # min -> day
        G_pn        = RN_PRESSURE_NATRIURESIS_GAIN # (mEq/day)/mmHg
        MAP_set     = CV_MAP_SETPOINT              # mmHg
        Na_intake   = 150.0                        # mEq/day - protocol input, set per run
        H2O_intake  = 2.0                          # L/day  - protocol input, set per run
    end

    vars = @variables begin
        V_ecf(t)                # L      extracellular fluid volume
        V_icf(t)                # L      intracellular fluid volume
        Na_ecf(t)               # mEq    extracellular sodium content
        C_Na(t)                 # mEq/L  plasma sodium concentration (observable)
        MAP(t)                  # mmHg   mean arterial pressure (interface input)
        Na_excr(t)              # mEq/day
        H2O_excr(t)             # L/day
        V_total(t)              # L      conservation observable
    end

    # Interface algebra - observables, cheap, always present
    obs = [
        C_Na    ~ Na_ecf / V_ecf,
        V_total ~ V_ecf + V_icf,
        # Pressure natriuresis. G_pn is CALIBRATED, not measured - see the ledger.
        # This is exactly the coupling gain that needs a posterior, not a point value.
        Na_excr ~ max(0.0, G_pn * (MAP - MAP_set) + Na_intake),
        H2O_excr ~ H2O_intake,
    ]

    # Slow dynamics - always integrated
    slow = [
        D(Na_ecf) ~ Na_intake - Na_excr,
        D(V_ecf)  ~ H2O_intake - H2O_excr - fluid_shift(V_ecf, V_icf, C_Na, C_Na_set, tau_osm, qss),
    ]

    # Fast mode - integrated, or collapsed to equilibrium
    fast = if qss
        # Osmotic equilibrium: ICF tracks ECF tonicity instantaneously.
        [0 ~ V_icf - (m_body * f_tbw * (1 - f_ecf)) * (C_Na_set / C_Na)]
    else
        [D(V_icf) ~ (( m_body * f_tbw * (1 - f_ecf)) * (C_Na_set / C_Na) - V_icf) / tau_osm]
    end

    eqs = vcat(obs, slow, fast)

    defaults = Dict(
        V_ecf  => body_mass * BF_TBW_FRACTION * BF_ECF_FRACTION,
        V_icf  => body_mass * BF_TBW_FRACTION * (1 - BF_ECF_FRACTION),
        Na_ecf => body_mass * BF_TBW_FRACTION * BF_ECF_FRACTION * BF_NA_PLASMA_SETPOINT,
        MAP    => CV_MAP_SETPOINT,
    )

    return ODESystem(eqs, t, vars, pars; name, defaults)
end

"""Water flux ECF -> ICF driven by tonicity gradient. Zero under QSS."""
function fluid_shift(V_ecf, V_icf, C_Na, C_Na_set, tau_osm, qss)
    return qss ? 0.0 : (V_icf * (C_Na / C_Na_set - 1)) / tau_osm
end
