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
    BF_NA_INTAKE_NOMINAL, BF_H2O_INTAKE_NOMINAL, BF_H2O_INSENSIBLE_LOSS,
    BF_H2O_CUTANEOUS_LOSS,
    BF_OSM_NONSODIUM,
    BF_BODY_MASS_REFERENCE

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
function BodyFluids(; name, body_mass = BF_BODY_MASS_REFERENCE,
                    storage::Bool = false)

    sz = size_factor(body_mass)

    pars = @parameters begin
        m_body      = body_mass
        f_icf       = BF_ICF_MASS_FRACTION
        f_ecf       = BF_ECF_MASS_FRACTION
        C_Na_set    = BF_NA_PLASMA_SETPOINT
        Osm_set     = BF_OSM_PLASMA_SETPOINT
        f_store     = BF_NA_OSMOTICALLY_INACTIVE_FRACTION
        tau_store   = BF_NA_STORAGE_TAU                    # already days
        tau_osm     = BF_ICF_ECF_OSMOTIC_TAU / 1440.0      # min -> day
        # EXTENSIVE - scale with body size. A 90 kg adult eats more sodium and
        # loses more water insensibly than a 50 kg adult. See src/scaling.jl.
        Na_intake   = sz * BF_NA_INTAKE_NOMINAL            # protocol input
        H2O_intake  = sz * BF_H2O_INTAKE_NOMINAL           # protocol input
        # INSENSIBLE LOSS IS NOW A SPLIT, NOT A CONSTANT. 2026-09-04, ADR 0017.
        # BF.H2O.INSENSIBLE_LOSS was 0.8 L/day, `assumed`, cited "Convention
        # pending primary source." Respiratory loss is computable from ventilation
        # and physical constants, so the total is now cutaneous + respiratory, and
        # the respiratory half arrives by connection from Respiratory.jl.
        #
        # THE CUTANEOUS ROW IS A RESIDUAL, pinned so the two halves reproduce the
        # old total at the reference individual. Same construction as
        # RN.URINE.SOLUTE_NONNA, and check_closure.py asserts the identity. The
        # resting state must not move: every ADH constant is derived from a water
        # balance that closes here.
        H2O_cutan   = sz * BF_H2O_CUTANEOUS_LOSS
        # Intracellular osmotically active solute content, CONSERVED. Set so that
        # at nominal ICF volume the cell is iso-osmolar with plasma. Cells do not
        # gain or lose solute on the timescales this model covers - only water
        # moves - so this is a parameter, not a state.
        Osm_solute_icf = BF_OSM_PLASMA_SETPOINT * body_mass * BF_ICF_MASS_FRACTION
        Osm_other      = BF_OSM_NONSODIUM
    end

    # Defaults are INLINE. MTK v10 removed `defaults` as a constructor keyword,
    # and inline is better practice regardless - the default sits next to the
    # variable it belongs to.
    vars = @variables begin
        V_icf(t)         = body_mass * BF_ICF_MASS_FRACTION            # L
        V_ecf(t)         = body_mass * BF_ECF_MASS_FRACTION            # L
        Na_ecf(t)        = body_mass * BF_ECF_MASS_FRACTION * BF_NA_PLASMA_SETPOINT
        Na_store(t)      = storage ? BF_NA_OSMOTICALLY_INACTIVE_FRACTION *
                                     body_mass * BF_ECF_MASS_FRACTION *
                                     BF_NA_PLASMA_SETPOINT : 0.0
        C_Na(t)             # mEq/L
        Osm_ecf(t)          # mOsm/kg
        Osm_icf(t)          # mOsm/kg
        J_store(t)          # mEq/day  net flux into storage, +ve = retaining
        J_osm(t)            # L/day    water flux ECF -> ICF
        # NO defaults on these three: they are supplied by connection equations.
        # A default here becomes a redundant initialization equation and makes
        # the initialization system overdetermined.
        Na_excr_rate(t)     # mEq/day  INPUT from renal
        H2O_excr_rate(t)    # L/day    INPUT from renal
        MAP(t)              # mmHg     INPUT from cardiovascular
        # WIRED 2026-09-04. Ventilation carries water vapour out of the body, so
        # this is a mass flux and not a signal. It arrives from Respiratory.jl.
        H2O_resp_rate(t)    # L/day    INPUT from respiratory
        V_total(t)          # L        conservation observable
        Na_total(t)         # mEq      conservation observable
    end

    obs = [
        C_Na    ~ Na_ecf / V_ecf,
        # Sodium is the dominant extracellular cation; the factor of two covers
        # accompanying anions. Standard approximation, and a known simplification -
        # it omits glucose and urea, which matters only in states this model does
        # not yet represent.
        Osm_ecf ~ 2 * C_Na + Osm_other,
        # Intracellular osmolality from a CONSERVED intracellular solute content.
        # Cells contain a fixed osmotically active solute mass; osmolality is that
        # mass divided by current cell water. This is what makes the compartment
        # self-correcting: as water leaves, ICF concentrates and opposes further
        # loss. The previous formulation drove ICF toward a fixed target volume
        # with no such restoring term, which let it collapse to zero.
        Osm_icf ~ Osm_solute_icf / V_icf,
        V_total ~ V_icf + V_ecf,
        # Conservation observable INCLUDES stored sodium. If this is not conserved
        # the storage compartment is leaking and the test suite fails.
        Na_total ~ Na_ecf + Na_store,
        # Water flux ECF -> ICF, driven by the osmotic gradient BETWEEN the two
        # compartments. Positive when ICF is hypertonic relative to ECF, i.e.
        # water enters cells. SIGN: previously this used (Osm_ecf/Osm_set - 1),
        # which has the opposite sense - it pushed water INTO cells when the ECF
        # was hypertonic, when water should leave cells to dilute the ECF.
        J_osm   ~ V_icf * (Osm_icf - Osm_ecf) / Osm_set / tau_osm,
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
        D(V_ecf)  ~ H2O_intake - H2O_excr_rate - H2O_cutan - H2O_resp_rate - J_osm,
        D(V_icf)  ~ J_osm,
    ]

    return MTKSystem(vcat(obs, store_eqs, balance), t, vars, pars; name)
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
        # WAS `:endocrine`, WHICH IS NOT A SUBSYSTEM. Corrected to `:adh` on
        # 2026-08-27. There has never been a subsystem called `endocrine`; the
        # name predates the ADH component. The consequence was not cosmetic:
        # validate_partition does `get(assignment, c.to, nothing) === nothing &&
        # continue`, so an edge naming a subsystem that does not exist is
        # SILENTLY SKIPPED - the one coupling most in need of checking was the
        # one guaranteed never to be checked. Kind aligned to Mechanical to match
        # Adh.jl, which declares the same edge; both are non-partitionable, so
        # the disagreement never affected the partition rule.
        Coupling(:bodyfluids, :adh, Mechanical,
                 note = "Osm_ecf drives ADH release; algebraic at this resolution"),
    ]
end
