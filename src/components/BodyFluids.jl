"""
Body fluid and sodium balance.

STRUCTURE SOURCES
  Mass and volume balance: conservation laws, not taken from any source.
  Osmotically inactive sodium storage: Rakova N et al, Long-term space flight
    simulation reveals infradian rhythmicity in human Na+ balance,
    Cell Metab 2013;17(1):125-131, doi:10.1016/j.cmet.2012.11.013.
    See docs/adr/0004-sodium-storage.md for why this compartment exists.

COMPARTMENTS
  ICF    intracellular fluid
  ECF    extracellular fluid (plasma + interstitial, not yet split)
  Store  osmotically inactive sodium, largely skin and other tissue binding

The third compartment is the substantive departure from the classical
two-compartment formulation. Classical models assume all body sodium is
osmotically active, so ECF volume tracks sodium content directly. Rakova et al
show total-body Na+ is stored, is not a simple function of intake, and is not
tightly coupled to extracellular water. A two-compartment model cannot reproduce
their data. Set `storage = false` for classical behaviour - that comparison is a
validation experiment, not a fallback.

ALL constants come from LedgerParams. No literals in the equations.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams:
    BF_ICF_MASS_FRACTION, BF_ECF_MASS_FRACTION,
    BF_NA_PLASMA_SETPOINT, BF_OSM_PLASMA_SETPOINT,
    BF_NA_OSMOTICALLY_INACTIVE_FRACTION, BF_NA_STORAGE_TAU,
    BF_ICF_ECF_OSMOTIC_TAU,
    BF_NA_INTAKE_NOMINAL, BF_H2O_INTAKE_NOMINAL, BF_H2O_INSENSIBLE_LOSS

"""
    BodyFluids(; name, body_mass = 70.0, storage = false)

Fluid and sodium balance with optional osmotically inactive sodium storage.

Time base is DAYS throughout, matching the horizons this model is built for.
Time constants held in other units in the ledger are converted here, once, visibly.

Interface (see src/coupling.jl):
  in   MAP              mmHg     from cardiovascular
  in   Na_excr_rate     mEq/day  from renal
  in   H2O_excr_rate    L/day    from renal
  out  V_ecf, C_Na, Osm_ecf      to cardiovascular, renal, endocrine
"""
function BodyFluids(; name, body_mass = 70.0, storage::Bool = false)

    pars = @parameters begin
        m_body      = body_mass
        f_icf       = BF_ICF_MASS_FRACTION
        f_ecf       = BF_ECF_MASS_FRACTION
        C_Na_set    = BF_NA_PLASMA_SETPOINT
        Osm_set     = BF_OSM_PLASMA_SETPOINT
        f_store     = BF_NA_OSMOTICALLY_INACTIVE_FRACTION
        tau_store   = BF_NA_STORAGE_TAU                    # already days
        tau_osm     = BF_ICF_ECF_OSMOTIC_TAU / 1440.0      # min -> day
        Na_intake   = BF_NA_INTAKE_NOMINAL                 # protocol input
        H2O_intake  = BF_H2O_INTAKE_NOMINAL                # protocol input
        H2O_insens  = BF_H2O_INSENSIBLE_LOSS
    end

    vars = @variables begin
        V_icf(t)            # L
        V_ecf(t)            # L
        Na_ecf(t)           # mEq      osmotically ACTIVE extracellular sodium
        Na_store(t)         # mEq      osmotically INACTIVE stored sodium
        C_Na(t)             # mEq/L
        Osm_ecf(t)          # mOsm/kg
        J_store(t)          # mEq/day  net flux into storage, +ve = retaining
        J_osm(t)            # L/day    water flux ECF -> ICF
        Na_excr_rate(t)     # mEq/day  INPUT from renal
        H2O_excr_rate(t)    # L/day    INPUT from renal
        MAP(t)              # mmHg     INPUT from cardiovascular
        V_total(t)          # L        conservation observable
        Na_total(t)         # mEq      conservation observable
    end

    obs = [
        C_Na    ~ Na_ecf / V_ecf,
        # Sodium is the dominant extracellular cation; the factor of two covers
        # accompanying anions. Standard approximation, and a known simplification -
        # it omits glucose and urea, which matters only in states this model does
        # not yet represent.
        Osm_ecf ~ 2 * C_Na,
        V_total ~ V_icf + V_ecf,
        # Conservation observable INCLUDES stored sodium. If this is not conserved
        # the storage compartment is leaking and the test suite fails.
        Na_total ~ Na_ecf + Na_store,
        J_osm   ~ (V_icf * (Osm_ecf / Osm_set - 1)) / tau_osm,
    ]

    # First-order relaxation of stored sodium toward a target proportional to
    # extracellular content. Crudest structure that can produce retention and
    # release on the timescale Rakova et al report. tau_store and f_store are
    # BOTH placeholders - see ADR 0004 and the ledger notes.
    store_eqs = if storage
        [D(Na_store) ~ J_store,
         J_store     ~ (f_store * Na_ecf - Na_store) / tau_store]
    else
        [D(Na_store) ~ 0.0,
         J_store     ~ 0.0]
    end

    balance = [
        D(Na_ecf) ~ Na_intake - Na_excr_rate - J_store,
        D(V_ecf)  ~ H2O_intake - H2O_excr_rate - H2O_insens - J_osm,
        D(V_icf)  ~ J_osm,
    ]

    defaults = Dict(
        V_icf    => body_mass * BF_ICF_MASS_FRACTION,
        V_ecf    => body_mass * BF_ECF_MASS_FRACTION,
        Na_ecf   => body_mass * BF_ECF_MASS_FRACTION * BF_NA_PLASMA_SETPOINT,
        Na_store => storage ?
                    BF_NA_OSMOTICALLY_INACTIVE_FRACTION * body_mass *
                    BF_ECF_MASS_FRACTION * BF_NA_PLASMA_SETPOINT : 0.0,
        MAP           => 93.0,
        Na_excr_rate  => BF_NA_INTAKE_NOMINAL,
        H2O_excr_rate => BF_H2O_INTAKE_NOMINAL - BF_H2O_INSENSIBLE_LOSS,
    )

    return ODESystem(vcat(obs, store_eqs, balance), t, vars, pars; name, defaults)
end

"""
    bodyfluids_couplings()

Declared connections, per src/coupling.jl.

All three are instantaneous classes: concentration follows algebraically from
content and volume, and volume drives filling hydraulically. Per ADR 0003 a
multirate partition must NOT cut across these - anything reading C_Na or V_ecf
shares a block with this component.
"""
function bodyfluids_couplings()
    return [
        Coupling(:bodyfluids, :renal, Conservation,
                 note = "C_Na and V_ecf drive filtered load; algebraic, no lag"),
        Coupling(:bodyfluids, :cardiovascular, Mechanical,
                 note = "V_ecf -> plasma volume -> venous return; hydraulic, no lag"),
        Coupling(:bodyfluids, :endocrine, Conservation,
                 note = "Osm_ecf drives ADH release; algebraic at this resolution"),
    ]
end
