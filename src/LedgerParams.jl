"""
    LedgerParams

GENERATED FILE - DO NOT EDIT BY HAND.

Produced by tools/ledger_to_julia.py from ledger/parameters.csv.
To change a value, edit the ledger and regenerate. This is the only
sanctioned path from source literature to executable code.

Ledger SHA256 (first 16): bddf7a92b97fffda
Parameters: 15 (assumed=5, derived=3, reported=7)
"""
module LedgerParams

export PARAM_PROVENANCE, provenance, unledgered_check

# ---------------------------------------------------------------------------
# Values
# ---------------------------------------------------------------------------

# --- body-fluids -------------------------------------------------
"""Extracellular fluid as fraction of body mass [unitless] +/- 0.023 (sd)
Source (tier A, reported): Zhang N et al. PMC6751809.
Notes: 20.8 +/- 2.3 percent of body weight, same cohort and method. Sums with ICF to TBW.
"""
const BF_ECF_MASS_FRACTION = 0.208

"""Extracellular water reference distribution source [unitless]
Source (tier A, reported): Extracellular water across the adult lifespan: reference values for adults. Physiol Meas 2007;28(5).
Notes: MARKER ROW - not a value. n=1538 multi-ethnic adults, ECW from isotope dilution and whole-body 40K counting, conditional quantile equations by weight height age sex race. This is the better source for a POPULATION DISTRIBUTION than any point estimate and should replace the BIA-derived fractions above once the equations are extracted. Extraction blocked: full text not retrieved.
"""
const BF_ECW_QUANTILE_REFERENCE = 1.0

"""Insensible water loss [L/day]  [!] ASSUMED
Source (tier B, assumed): Convention pending primary source.
Notes: ASSUMED. Respiratory plus transepidermal, sedentary thermoneutral adult. Needs a primary source; varies strongly with ambient conditions and activity, so a single constant is a known simplification.
"""
const BF_H2O_INSENSIBLE_LOSS = 0.8

"""Total water intake nominal [L/day]  [!] ASSUMED
Source (tier B, assumed): Convention pending primary source.
Notes: ASSUMED. Needs a primary source. In the Mars500 protocol fluid intake was ad libitum and recorded; extracting the actual series would be better than any population figure and would remove this assumption entirely.
"""
const BF_H2O_INTAKE_NOMINAL = 2.5

"""Intracellular fluid as fraction of body mass [unitless] +/- 0.040 (sd)
Source (tier A, reported): Zhang N et al. PMC6751809.
Notes: 34.4 +/- 4.0 percent of body weight, same cohort and method as BF.TBW.MASS_FRACTION. Consistency check: ICF + ECF = 55.2 which matches TBW as reported.
"""
const BF_ICF_MASS_FRACTION = 0.344

"""Intracellular-extracellular osmotic equilibration time constant [min]  [!] ASSUMED
Source (tier B, assumed): Convention pending primary source.
Notes: ASSUMED. Fast relative to every integrative timescale of interest. Per ADR 0002 this sits well SLOWER than baroreflex so it is not a candidate for the fast block; per ADR 0003 it is a Conservation-class coupling and must not be partitioned across. Sensitivity to this value should be near zero on multi-day runs - verify that in testing, and if it is not, the compartment structure is wrong.
"""
const BF_ICF_ECF_OSMOTIC_TAU = 30.0

"""Dietary sodium intake low protocol level [mEq/day]
Source (tier A, derived): Rakova N et al. Cell Metab 2013;17(1):125-131.
Notes: DERIVED from 6 g/day NaCl protocol level. 6 / 58.44 = 103 mmol.
"""
const BF_NA_INTAKE_LOW = 103.0

"""Dietary sodium intake middle protocol level [mEq/day]
Source (tier A, derived): Rakova N et al. Cell Metab 2013;17(1):125-131.
Notes: DERIVED from 9 g/day NaCl protocol level. 9 / 58.44 = 154 mmol.
"""
const BF_NA_INTAKE_MID = 154.0

"""Dietary sodium intake nominal [mEq/day]
Source (tier A, derived): Rakova N et al. Cell Metab 2013;17(1):125-131.
Notes: DERIVED from the Mars500 protocol salt level of 12 g/day NaCl. 12 g NaCl / 58.44 g/mol = 205 mmol Na. Protocol levels were 12, 9 and 6 g/day held for 30-60 days each. Use these three as the validation step inputs, not a free parameter.
"""
const BF_NA_INTAKE_NOMINAL = 205.0

"""Fraction of total body sodium stored osmotically inactive [unitless]  [!] ASSUMED
Source (tier B, assumed): Rakova N et al. Long-term space flight simulation reveals infradian rhythmicity in human Na+ balance. Cell Metab 2013;17(1):125-131.
Notes: ASSUMED PLACEHOLDER. Rakova et al establish that total-body Na+ is stored and is NOT a simple function of salt intake, and that total-body Na+ and extracellular water are not tightly coupled. They do not report a single storage fraction. This value is a placeholder to make the third compartment functional and MUST be replaced by estimation against the Mars500 balance series. See ADR 0004.
"""
const BF_NA_OSMOTICALLY_INACTIVE_FRACTION = 0.15

"""Plasma sodium concentration setpoint [mEq/L] +/- 135-145 (range)
Source (tier B, reported): Standard clinical reference interval.
Notes: VERIFY - clinical reference range, needs a citable primary source. Widely reproduced but traced here only to convention.
"""
const BF_NA_PLASMA_SETPOINT = 140.0

"""Skin sodium accumulation with age [mmol/(L*year)] +/- 0.07 (sd)
Source (tier A, reported): Titze J et al, 23Na MRI at 7.0 Tesla, n=17 men. Reported in Rakova N, Sodium Balance (dissertation), Freie Universitaet Berlin.
Notes: Described by the source as preliminary in vivo data. Not used in the current model - recorded because it constrains the storage compartment on long horizons and will matter if the model is ever run across decades.
"""
const BF_NA_SKIN_ACCUMULATION_RATE = 0.34

"""Osmotically inactive sodium storage time constant [day]  [!] ASSUMED
Source (tier B, assumed): Rakova N et al. Cell Metab 2013;17(1):125-131.
Notes: ASSUMED PLACEHOLDER, chosen to match the reported weekly infradian rhythm period rather than derived from it. Rakova et al report 7-day and monthly rhythmicity in Na+ balance; a first-order lag with tau = 7 d is the crudest structure that can produce retention and release on that scale. This is the single most important parameter to estimate properly against the Mars500 series. See ADR 0004.
"""
const BF_NA_STORAGE_TAU = 7.0

"""Plasma osmolality setpoint [mOsm/kg] +/- 275-295 (range)
Source (tier B, reported): Standard clinical reference interval.
Notes: VERIFY - as above. Needed to close the osmotic equilibration between ICF and ECF.
"""
const BF_OSM_PLASMA_SETPOINT = 287.0

"""Total body water as fraction of body mass [unitless] +/- 0.062 (sd)
Source (tier A, reported): Zhang N et al. Association between the content of intracellular and extracellular fluid and the amount of water intake among Chinese college students. PMC6751809.
Notes: Reported as 55.2 +/- 6.2 percent of body weight by bioelectrical impedance, n=159 young adults. NOTE this is below the conventional textbook 60 percent; BIA and isotope dilution disagree systematically and the cohort is young Chinese adults. VERIFY against a second population before relying on it. Candidate cross-check: ICRP 89.
"""
const BF_TBW_MASS_FRACTION = 0.552


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
    :BF_ECF_MASS_FRACTION => Provenance("BF.ECF.MASS_FRACTION", "unitless", 0.208, "A", "reported", "Zhang N et al. PMC6751809.", "20.8 +/- 2.3 percent of body weight, same cohort and method. Sums with ICF to TBW."),
    :BF_ECW_QUANTILE_REFERENCE => Provenance("BF.ECW.QUANTILE_REFERENCE", "unitless", 1.0, "A", "reported", "Extracellular water across the adult lifespan: reference values for adults. Physiol Meas 2007;28(5).", "MARKER ROW - not a value. n=1538 multi-ethnic adults, ECW from isotope dilution and whole-body 40K counting, conditional quantile equations by weight height age sex race. This is the better source for a POPULATION DISTRIBUTION than any point estimate and should replace the BIA-derived fractions above once the equations are extracted. Extraction blocked: full text not retrieved."),
    :BF_H2O_INSENSIBLE_LOSS => Provenance("BF.H2O.INSENSIBLE_LOSS", "L/day", 0.8, "B", "assumed", "Convention pending primary source.", "ASSUMED. Respiratory plus transepidermal, sedentary thermoneutral adult. Needs a primary source; varies strongly with ambient conditions and activity, so a single constant is a known simplification."),
    :BF_H2O_INTAKE_NOMINAL => Provenance("BF.H2O.INTAKE_NOMINAL", "L/day", 2.5, "B", "assumed", "Convention pending primary source.", "ASSUMED. Needs a primary source. In the Mars500 protocol fluid intake was ad libitum and recorded; extracting the actual series would be better than any population figure and would remove this assumption entirely."),
    :BF_ICF_MASS_FRACTION => Provenance("BF.ICF.MASS_FRACTION", "unitless", 0.344, "A", "reported", "Zhang N et al. PMC6751809.", "34.4 +/- 4.0 percent of body weight, same cohort and method as BF.TBW.MASS_FRACTION. Consistency check: ICF + ECF = 55.2 which matches TBW as reported."),
    :BF_ICF_ECF_OSMOTIC_TAU => Provenance("BF.ICF_ECF.OSMOTIC_TAU", "min", 30.0, "B", "assumed", "Convention pending primary source.", "ASSUMED. Fast relative to every integrative timescale of interest. Per ADR 0002 this sits well SLOWER than baroreflex so it is not a candidate for the fast block; per ADR 0003 it is a Conservation-class coupling and must not be partitioned across. Sensitivity to this value should be near zero on multi-day runs - verify that in testing, and if it is not, the compartment structure is wrong."),
    :BF_NA_INTAKE_LOW => Provenance("BF.NA.INTAKE_LOW", "mEq/day", 103.0, "A", "derived", "Rakova N et al. Cell Metab 2013;17(1):125-131.", "DERIVED from 6 g/day NaCl protocol level. 6 / 58.44 = 103 mmol."),
    :BF_NA_INTAKE_MID => Provenance("BF.NA.INTAKE_MID", "mEq/day", 154.0, "A", "derived", "Rakova N et al. Cell Metab 2013;17(1):125-131.", "DERIVED from 9 g/day NaCl protocol level. 9 / 58.44 = 154 mmol."),
    :BF_NA_INTAKE_NOMINAL => Provenance("BF.NA.INTAKE_NOMINAL", "mEq/day", 205.0, "A", "derived", "Rakova N et al. Cell Metab 2013;17(1):125-131.", "DERIVED from the Mars500 protocol salt level of 12 g/day NaCl. 12 g NaCl / 58.44 g/mol = 205 mmol Na. Protocol levels were 12, 9 and 6 g/day held for 30-60 days each. Use these three as the validation step inputs, not a free parameter."),
    :BF_NA_OSMOTICALLY_INACTIVE_FRACTION => Provenance("BF.NA.OSMOTICALLY_INACTIVE_FRACTION", "unitless", 0.15, "B", "assumed", "Rakova N et al. Long-term space flight simulation reveals infradian rhythmicity in human Na+ balance. Cell Metab 2013;17(1):125-131.", "ASSUMED PLACEHOLDER. Rakova et al establish that total-body Na+ is stored and is NOT a simple function of salt intake, and that total-body Na+ and extracellular water are not tightly coupled. They do not report a single storage fraction. This value is a placeholder to make the third compartment functional and MUST be replaced by estimation against the Mars500 balance series. See ADR 0004."),
    :BF_NA_PLASMA_SETPOINT => Provenance("BF.NA.PLASMA_SETPOINT", "mEq/L", 140.0, "B", "reported", "Standard clinical reference interval.", "VERIFY - clinical reference range, needs a citable primary source. Widely reproduced but traced here only to convention."),
    :BF_NA_SKIN_ACCUMULATION_RATE => Provenance("BF.NA.SKIN_ACCUMULATION_RATE", "mmol/(L*year)", 0.34, "A", "reported", "Titze J et al, 23Na MRI at 7.0 Tesla, n=17 men. Reported in Rakova N, Sodium Balance (dissertation), Freie Universitaet Berlin.", "Described by the source as preliminary in vivo data. Not used in the current model - recorded because it constrains the storage compartment on long horizons and will matter if the model is ever run across decades."),
    :BF_NA_STORAGE_TAU => Provenance("BF.NA.STORAGE_TAU", "day", 7.0, "B", "assumed", "Rakova N et al. Cell Metab 2013;17(1):125-131.", "ASSUMED PLACEHOLDER, chosen to match the reported weekly infradian rhythm period rather than derived from it. Rakova et al report 7-day and monthly rhythmicity in Na+ balance; a first-order lag with tau = 7 d is the crudest structure that can produce retention and release on that scale. This is the single most important parameter to estimate properly against the Mars500 series. See ADR 0004."),
    :BF_OSM_PLASMA_SETPOINT => Provenance("BF.OSM.PLASMA_SETPOINT", "mOsm/kg", 287.0, "B", "reported", "Standard clinical reference interval.", "VERIFY - as above. Needed to close the osmotic equilibration between ICF and ECF."),
    :BF_TBW_MASS_FRACTION => Provenance("BF.TBW.MASS_FRACTION", "unitless", 0.552, "A", "reported", "Zhang N et al. Association between the content of intracellular and extracellular fluid and the amount of water intake among Chinese college students. PMC6751809.", "Reported as 55.2 +/- 6.2 percent of body weight by bioelectrical impedance, n=159 young adults. NOTE this is below the conventional textbook 60 percent; BIA and isotope dilution disagree systematically and the cohort is young Chinese adults. VERIFY against a second population before relying on it. Candidate cross-check: ICRP 89."),
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
