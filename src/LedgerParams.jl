"""
    LedgerParams

GENERATED FILE - DO NOT EDIT BY HAND.

Produced by tools/ledger_to_julia.py from ledger/parameters.csv.
To change a value, edit the ledger and regenerate. This is the only
sanctioned path from source literature to executable code.

Ledger SHA256 (first 16): 6d6c83c58ec5f2ab
Parameters: 8 (assumed=1, calibrated=1, reported=6)
"""
module LedgerParams

export PARAM_PROVENANCE, provenance, unledgered_check

# ---------------------------------------------------------------------------
# Values
# ---------------------------------------------------------------------------

# --- body-fluids -------------------------------------------------
"""Extracellular fluid as fraction of total body water [unitless] +/- 0.03 (sd)
Source (tier A, reported): TODO-VERIFY: ICRP Publication 89 reference values
Notes: SCAFFOLD SEED - citation must be verified. One third of TBW is the conventional partition.
"""
const BF_ECF_FRACTION = 0.3333

"""Intracellular-extracellular osmotic equilibration time constant [min]  [!] ASSUMED
Source (tier A, assumed): 
Notes: SCAFFOLD SEED - no literature value assigned yet. Fast relative to all integrative timescales of interest; a candidate for quasi-steady-state reduction on long runs. Justification: order-of-magnitude placeholder to exercise the stiffness path in the walking skeleton.
"""
const BF_ICF_OSMOTIC_EQUILIBRATION_TAU = 30.0

"""Plasma sodium concentration setpoint [mEq/L] +/- 135-145 (range)
Source (tier A, reported): TODO-VERIFY: standard clinical reference range
Notes: SCAFFOLD SEED - citation must be verified.
"""
const BF_NA_PLASMA_SETPOINT = 140.0

"""Plasma volume as fraction of extracellular fluid [unitless] +/- 0.03 (sd)
Source (tier A, reported): TODO-VERIFY: ICRP Publication 89 reference values
Notes: SCAFFOLD SEED - citation must be verified. Remainder is interstitial.
"""
const BF_PLASMA_ECF_FRACTION = 0.25

"""Total body water as fraction of body mass [unitless] +/- 0.05 (sd)
Source (tier A, reported): TODO-VERIFY: ICRP Publication 89 reference values
Notes: SCAFFOLD SEED - citation must be verified against the primary source before any use. Nominal adult male.
"""
const BF_TBW_FRACTION = 0.6


# --- cardiovascular ----------------------------------------------
"""Cardiac output at rest [L/min] +/- 0.8 (sd)
Source (tier A, reported): TODO-VERIFY: standard physiological reference
Notes: SCAFFOLD SEED - citation must be verified.
"""
const CV_CO_NOMINAL = 5.0

"""Mean arterial pressure nominal setpoint [mmHg] +/- 8.0 (sd)
Source (tier A, reported): TODO-VERIFY: population reference
Notes: SCAFFOLD SEED - citation must be verified. Nominal normotensive adult.
"""
const CV_MAP_SETPOINT = 93.0


# --- renal -------------------------------------------------------
"""Pressure natriuresis slope [(mEq/day)/mmHg]  [!] CALIBRATED
Source (tier B, calibrated): TODO-VERIFY: Guyton AC Coleman TG Granger HJ. Circulation: overall regulation. Annu Rev Physiol 1972;34:13-46.
Notes: SCAFFOLD SEED - placeholder value. This is the archetypal coupling gain that is fitted rather than measured; originating model is the Guyton 1972 systems-analysis model. Must be re-derived against challenge-protocol data and given a posterior rather than a point value.
"""
const RN_PRESSURE_NATRIURESIS_GAIN = 20.0


# ---------------------------------------------------------------------------
# Provenance table - queryable at runtime so any result can be traced
# ---------------------------------------------------------------------------

struct Provenance
    param_id::String
    units::String
    value::Float64
    tier::String
    method::String
    citation::String
    notes::String
end

const PARAM_PROVENANCE = Dict{Symbol,Provenance}(
    :BF_ECF_FRACTION => Provenance("BF.ECF.FRACTION", "unitless", 0.3333, "A", "reported", "TODO-VERIFY: ICRP Publication 89 reference values", "SCAFFOLD SEED - citation must be verified. One third of TBW is the conventional partition."),
    :BF_ICF_OSMOTIC_EQUILIBRATION_TAU => Provenance("BF.ICF.OSMOTIC_EQUILIBRATION_TAU", "min", 30.0, "A", "assumed", "", "SCAFFOLD SEED - no literature value assigned yet. Fast relative to all integrative timescales of interest; a candidate for quasi-steady-state reduction on long runs. Justification: order-of-magnitude placeholder to exercise the stiffness path in the walking skeleton."),
    :BF_NA_PLASMA_SETPOINT => Provenance("BF.NA.PLASMA_SETPOINT", "mEq/L", 140.0, "A", "reported", "TODO-VERIFY: standard clinical reference range", "SCAFFOLD SEED - citation must be verified."),
    :BF_PLASMA_ECF_FRACTION => Provenance("BF.PLASMA.ECF_FRACTION", "unitless", 0.25, "A", "reported", "TODO-VERIFY: ICRP Publication 89 reference values", "SCAFFOLD SEED - citation must be verified. Remainder is interstitial."),
    :BF_TBW_FRACTION => Provenance("BF.TBW.FRACTION", "unitless", 0.6, "A", "reported", "TODO-VERIFY: ICRP Publication 89 reference values", "SCAFFOLD SEED - citation must be verified against the primary source before any use. Nominal adult male."),
    :CV_CO_NOMINAL => Provenance("CV.CO.NOMINAL", "L/min", 5.0, "A", "reported", "TODO-VERIFY: standard physiological reference", "SCAFFOLD SEED - citation must be verified."),
    :CV_MAP_SETPOINT => Provenance("CV.MAP.SETPOINT", "mmHg", 93.0, "A", "reported", "TODO-VERIFY: population reference", "SCAFFOLD SEED - citation must be verified. Nominal normotensive adult."),
    :RN_PRESSURE_NATRIURESIS_GAIN => Provenance("RN.PRESSURE_NATRIURESIS.GAIN", "(mEq/day)/mmHg", 20.0, "B", "calibrated", "TODO-VERIFY: Guyton AC Coleman TG Granger HJ. Circulation: overall regulation. Annu Rev Physiol 1972;34:13-46.", "SCAFFOLD SEED - placeholder value. This is the archetypal coupling gain that is fitted rather than measured; originating model is the Guyton 1972 systems-analysis model. Must be re-derived against challenge-protocol data and given a posterior rather than a point value."),
)

"""
    provenance(sym::Symbol)

Return the ledger record backing a parameter. Every number in a published
result should be traceable through this.
"""
provenance(sym::Symbol) = PARAM_PROVENANCE[sym]

"""
    unledgered_check()

Report parameters whose basis is weak: `assumed` (no literature basis) or
`calibrated` (a fitted value published by another modeling effort, not a
measurement). Review these as a set. They are where unfalsifiable choices
accumulate, and they are the honest answer to \"how much of this is known?\"
"""
function unledgered_check()
    weak = [p for p in values(PARAM_PROVENANCE) if p.method in ("assumed", "calibrated")]
    sort!(weak, by = p -> p.param_id)
    return weak
end

end # module
