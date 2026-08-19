"""
    LedgerParams

GENERATED FILE - DO NOT EDIT BY HAND.

Produced by tools/ledger_to_julia.py from ledger/parameters.csv.
To change a value, edit the ledger and regenerate. This is the only
sanctioned path from source literature to executable code.

Ledger SHA256 (first 16): fc954485ec98b4d8
Parameters: 41 (assumed=11, calibrated=2, derived=8, reported=20)
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

"""Non-sodium contribution to plasma osmolality [mOsm/kg]
Source (tier B, derived): Derived from the standard osmolality estimate.
Notes: DERIVED as Osm_set - 2*C_Na = 287 - 280 = 7. Represents glucose potassium urea and other solutes in the conventional estimate Osm = 2[Na] + glucose/18 + BUN/2.8. Without this term the model started 7 mOsm hypertonic at nominal and drove osmotic flux from t=0. CLOSURE constraint - recompute if BF.NA.PLASMA_SETPOINT or BF.OSM.PLASMA_SETPOINT change. Enforced by tools/check_closure.py.
"""
const BF_OSM_NONSODIUM = 7.0

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


# --- cardiovascular ----------------------------------------------
"""Time of peak mean arterial pressure [day]  [!] ASSUMED
Source (tier B, assumed): Recent advances in understanding the circadian clock in renal physiology. PMC6350809.
Notes: ASSUMED. Placeholder consistent with pressure peaking during the active period. Must be extracted from ambulatory BP monitoring cosinor analysis. NOTE the CV and renal acrophases are deliberately independent parameters - Bmal1 knockout rats lose the renal sodium rhythm while MAP rhythm persists, so a shared phase would be structurally wrong.
"""
const CIRC_CV_ACROPHASE = 0.25

"""Nocturnal blood pressure dip as fraction of daytime mean [unitless] +/- 0.10-0.20 (range)
Source (tier A, reported): Recent advances in understanding the circadian clock in renal physiology. PMC6350809.
Notes: Blood pressure normally dips 10-20 percent during the inactive period; 0.15 is the midpoint of that stated range. Loss of dipping is associated with elevated cardiovascular risk and target organ damage, so this is a clinically load-bearing parameter, not a cosmetic one.
"""
const CIRC_CV_MAP_DIP_FRACTION = 0.15

"""Total blood volume nominal [L] +/- 0.6 (sd)
Source (tier B, reported): Standard physiological reference. VERIFY.
Notes: Nominal 70 kg adult.
"""
const CV_BLOOD_VOLUME_NOMINAL = 5.0

"""Cardiac output at rest [L/day] +/- 1150.0 (sd)
Source (tier B, derived): Standard physiological reference. VERIFY.
Notes: DERIVED from the conventional 5 L/min. 5 x 1440 = 7200 L/day. Units are per-day throughout the model.
"""
const CV_CO_NOMINAL = 7200.0

"""Hematocrit [unitless] +/- 0.04 (sd)
Source (tier B, reported): Standard physiological reference. VERIFY.
Notes: Adult male nominal. Sex-dependent - female nominal is lower. Sex is deferred until the spine is validated.
"""
const CV_HEMATOCRIT_NOMINAL = 0.45

"""Mean arterial pressure nominal [mmHg] +/- 8.0 (sd)
Source (tier B, reported): Standard physiological reference. VERIFY.
Notes: Nominal normotensive adult. NOTE this is an OUTPUT of the closed loop, not an input - it emerges from renal-body fluid feedback. It appears here as an initialisation value and a validation target, not as a setpoint the model enforces.
"""
const CV_MAP_SETPOINT = 93.0

"""Plasma volume as fraction of extracellular fluid [unitless]
Source (tier B, derived): Derived to close the loop at nominal.
Notes: DERIVED and NOT rounded: f_pv = BV0 x (1-Hct) / V_ecf = 5.0 x 0.55 / 14.56 = 0.188874. Rounding to 0.20 put blood volume 0.295 L above nominal, which through the venous return gain produced MAP = 104 rather than 93 mmHg. The conventional textbook figure is 0.25; the discrepancy comes from using the measured ECF fraction (20.8% of body mass) rather than the textbook 20%. This is a CLOSURE constraint - if Hct BF.ECF.MASS_FRACTION or CV.BLOOD_VOLUME.NOMINAL change this must be recomputed. Enforced by tools/check_closure.py.
"""
const CV_PLASMA_ECF_FRACTION = 0.188874

"""Total peripheral resistance nominal [mmHg/(L/day)]
Source (tier B, derived): Derived from MAP and CO.
Notes: DERIVED: TPR = MAP/CO = 93/7200. Definitional given the other two. In this minimal model TPR is a constant - it becomes a state once baroreflex and RAAS exist.
"""
const CV_TPR_NOMINAL = 0.012916667

"""Cardiac output sensitivity to blood volume [(L/day)/L]  [!] CALIBRATED
Source (tier B, calibrated): Guyton AC, Coleman TG, Granger HJ. Annu Rev Physiol 1972;34:13-46.
Notes: CALIBRATED, not measured. Originating model: Guyton 1972. The Frank-Starling and venous return relationships are E1; this linearised sensitivity around the operating point is a fitted constant. Second most consequential unmeasured number after the pressure natriuresis slope - together these two set the loop gain.
"""
const CV_VENOUS_RETURN_SENSITIVITY = 2880.0


# --- neural ------------------------------------------------------
"""Sympathetic vasomotor effector time constant [s] +/- 2.0-3.0 (range)
Source (tier A, reported): La Rovere MT, Pinna GD, Raczak G. Baroreflex sensitivity: measurement and clinical implications. Ann Noninvasive Electrocardiol 2008;13(2):191-207.
Notes: Cardiac and vasomotor sympathetic activation occurs with a 2-3 second delay and reaches maximal effect more slowly. Parasympathetic activation is far faster (200-600 ms) but acts on heart rate, which is not a state in this cycle-averaged model (ADR 0002) - hence the lumped single-arm treatment. 3.0 s is the upper end of the stated range.
"""
const BR_EFFECTOR_TAU = 3.0

"""Sympathetic arterial baroreflex open-loop gain [unitless] +/- 1.0-3.5 (range)
Source (tier B, reported): Yamasaki F, Sato T, Sato K, Diedrich A. Analytic and integrative framework for understanding human sympathetic arterial baroreflex function. Front Neurosci 2021;15:707345.
Notes: SPECIES: animal (dog, rabbit) - open-loop gain measured by perfusing vascularly isolated carotid sinus or aortic arch, reported between 1.0 and 3.5 across Kent 1972, Shoukas and Sagawa 1973, McRitchie 1976, Burattini 1994, Sato 1999, Sunagawa 2001. The source states explicitly that this invasive approach is not applicable to humans and that human open-loop gain has NOT been clarified. 2.0 is the mid-range. NO SCALING APPLIED - gain is dimensionless and the reflex architecture is conserved, but this is the weakest link in the component and must be flagged in any result.
"""
const BR_OPEN_LOOP_GAIN = 2.0

"""Baroreflex setpoint resetting time constant [day]  [!] ASSUMED
Source (tier B, assumed): Dampney RAL. Resetting of the baroreflex control of sympathetic vasomotor activity during natural behaviors. Front Physiol 2017.
Notes: ASSUMED. Baroreflex resetting is well established qualitatively - the reflex re-centres on prevailing pressure over hours to days, which is WHY it cannot set long-run arterial pressure. A specific human time constant is not reported in the sources consulted. 1 day is an order-of-magnitude placeholder. CRITICAL: this parameter is what makes the baroreflex a fast buffer rather than a long-term regulator. If it were infinite the reflex would set long-run pressure and the Guyton claim in ADR 0007 would be false. Sensitivity to it must be tested.
"""
const BR_RESET_TAU = 1.0

"""Maximum fractional change in TPR from baroreflex [unitless]  [!] ASSUMED
Source (tier B, assumed): Saturation bound; see notes.
Notes: ASSUMED. The baroreflex characteristic is sigmoidal and saturates; an unbounded linear gain would let TPR go negative under large pressure excursions. 0.5 means TPR can move at most +/-50 percent from baseline by reflex action alone. Placeholder chosen to keep the model well-posed under hemorrhage-scale perturbations, not extracted from a reported response range.
"""
const BR_TPR_MAX_FRACTION = 0.5

"""Clock to effector transcriptional delay [s]  [!] ASSUMED
Source (tier B, assumed): Recent advances in understanding the circadian clock in renal physiology. PMC6350809.
Notes: ASSUMED. The source describes Per1 as an early aldosterone target gene regulating ENaC, SGLT1, NHE3 and ET-1, and notes Per genes have short half-lives, but does not report an effector delay. 1 h is an order-of-magnitude placeholder. This is a Neurohumoral coupling tau per ADR 0003 and is what makes the clock safe to partition across.
"""
const CIRC_EFFECTOR_TAU = 3600.0

"""Circadian period [day]
Source (tier A, reported): Circadian rhythms and the kidney. Nat Rev Nephrol 2018;14:626-635.
Notes: Free-running human period is slightly over 24 h but entrained period is 24 h. This model has no entrainment mechanism (see Circadian.jl) so the entrained value is the correct one to use. If constant-routine or shift-work protocols are ever added this must become a free-running period with an entrainment path.
"""
const CIRC_PERIOD = 1.0


# --- renal -------------------------------------------------------
"""BP and sodium rhythm dissociation marker [unitless]
Source (tier A, reported): Diurnal control of blood pressure is uncoupled from sodium excretion. Hypertension.
Notes: MARKER ROW - not a value. SPECIES: rat, whole-body Bmal1 knockout. Male knockouts showed no significant difference in baseline sodium excretion between 12-h active and inactive periods while circadian MAP rhythm remained intact. This is the evidence for independent renal and cardiovascular clock arms in Circadian.jl. No scaling applied - structural evidence only, no numeric value taken.
"""
const CIRC_BMAL1_DISSOCIATION_MARKER = 1.0

"""Clock gene mechanism evidence marker [unitless]
Source (tier A, reported): Recent advances in understanding the circadian clock in renal physiology. PMC6350809.
Notes: MARKER ROW - not a value. SPECIES: mouse. Per1 knockout mice under high salt plus DOCP lose the night/day difference in sodium excretion and the inactive-period BP dip. Recorded because the clock-gene MECHANISM is rodent-derived while the human circadian sodium rhythm and BP dipping are separately documented in humans. No scaling is applied because no numeric value is taken from this - the mechanism informs structure only.
"""
const CIRC_PER1_MECHANISM_MARKER = 1.0

"""Time of peak renal sodium excretion [day]  [!] ASSUMED
Source (tier B, assumed): Impaired daytime urinary sodium excretion impacts nighttime blood pressure. PMC7400814.
Notes: ASSUMED. Sodium excretion is maximal during daytime and minimal at night; 0.33 d = 8 h after start of active period is a placeholder consistent with that pattern but not extracted from a reported acrophase. Cosinor acrophase must be extracted properly from split-collection data.
"""
const CIRC_RENAL_NA_ACROPHASE = 0.33

"""Relative amplitude of circadian modulation of renal sodium handling [unitless]  [!] ASSUMED
Source (tier B, assumed): Circadian rhythms and the kidney. Nat Rev Nephrol 2018;14:626-635.
Notes: ASSUMED PLACEHOLDER. The source establishes that renal plasma flow, GFR and tubular reabsorption peak in the active phase and decline in the inactive phase, but a single relative amplitude is not reported. MUST be estimated against split day/night UNaV data. Reported day/night UNaV ratios in human cohorts span a wide range (tertile boundaries around 0.47 and 0.84 in one CKD study), which is the data class to fit against.
"""
const CIRC_RENAL_NA_AMPLITUDE = 0.25

"""Lower limit of renal autoregulation [mmHg]
Source (tier B, reported): Standard physiological reference. VERIFY.
Notes: GFR is approximately independent of MAP between roughly 80 and 180 mmHg. Below this GFR falls with pressure. E1 qualitatively; the exact limits vary and are convention here.
"""
const RN_AUTOREG_LOWER = 80.0

"""Upper limit of renal autoregulation [mmHg]
Source (tier B, reported): Standard physiological reference. VERIFY.
Notes: See RN.AUTOREG.LOWER.
"""
const RN_AUTOREG_UPPER = 180.0

"""Glomerular filtration rate nominal [L/day] +/- 25.0 (sd)
Source (tier B, reported): Standard physiological reference. VERIFY.
Notes: 125 mL/min = 180 L/day, conventional nominal adult value. Tier B pending a citable primary source; the value itself is textbook-level E1 but its provenance here is convention.
"""
const RN_GFR_NOMINAL = 180.0

"""Obligatory urine volume at maximal concentration [L/day]
Source (tier B, reported): Standard physiological reference. VERIFY.
Notes: Minimum urine volume needed to excrete the daily solute load at maximal urinary concentration. Sets a floor on water excretion.
"""
const RN_H2O_OBLIGATORY_LOSS = 0.5

"""Fractional tubular sodium reabsorption at nominal pressure [unitless]
Source (tier B, derived): Standard physiological reference. VERIFY.
Notes: DERIVED to close the loop at nominal: filtered load = 180 L/day x 140 mEq/L = 25200 mEq/day; excretion must equal intake of 205 mEq/day at steady state, so FR = 1 - 205/25200 = 0.9918651. NOT rounded - rounding to 0.9915 gave excretion of 214.2 vs intake 205, a 9.2 mEq/day drift that ran the model to a lethal state while reporting Success. This is NOT an independent measurement - it is fixed by the other three values, and that dependency must be preserved if any of them changes.
"""
const RN_NA_FRACTIONAL_REABSORPTION = 0.9918651

"""Pressure natriuresis slope [(mEq/day)/mmHg]  [!] CALIBRATED
Source (tier B, calibrated): Guyton AC, Coleman TG, Granger HJ. Circulation: overall regulation. Annu Rev Physiol 1972;34:13-46.
Notes: CALIBRATED, not measured. Originating model: Guyton 1972 systems analysis. The EXISTENCE and steepness of pressure natriuresis is E1 and well replicated; this particular slope is a fitted constant that propagated through the modelling literature. It is the single most consequential unmeasured number in the model - it sets the long-run pressure setpoint. Must be re-estimated with a posterior, not carried as a point value.
"""
const RN_PRESSURE_NATRIURESIS_SLOPE = 20.0


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
    :BF_OSM_NONSODIUM => Provenance("BF.OSM.NONSODIUM", "mOsm/kg", 7.0, "B", "derived", "Derived from the standard osmolality estimate.", "DERIVED as Osm_set - 2*C_Na = 287 - 280 = 7. Represents glucose potassium urea and other solutes in the conventional estimate Osm = 2[Na] + glucose/18 + BUN/2.8. Without this term the model started 7 mOsm hypertonic at nominal and drove osmotic flux from t=0. CLOSURE constraint - recompute if BF.NA.PLASMA_SETPOINT or BF.OSM.PLASMA_SETPOINT change. Enforced by tools/check_closure.py."),
    :BF_OSM_PLASMA_SETPOINT => Provenance("BF.OSM.PLASMA_SETPOINT", "mOsm/kg", 287.0, "B", "reported", "Standard clinical reference interval.", "VERIFY - as above. Needed to close the osmotic equilibration between ICF and ECF."),
    :BF_TBW_MASS_FRACTION => Provenance("BF.TBW.MASS_FRACTION", "unitless", 0.552, "A", "reported", "Zhang N et al. Association between the content of intracellular and extracellular fluid and the amount of water intake among Chinese college students. PMC6751809.", "Reported as 55.2 +/- 6.2 percent of body weight by bioelectrical impedance, n=159 young adults. NOTE this is below the conventional textbook 60 percent; BIA and isotope dilution disagree systematically and the cohort is young Chinese adults. VERIFY against a second population before relying on it. Candidate cross-check: ICRP 89."),
    :BR_EFFECTOR_TAU => Provenance("BR.EFFECTOR.TAU", "s", 3.0, "A", "reported", "La Rovere MT, Pinna GD, Raczak G. Baroreflex sensitivity: measurement and clinical implications. Ann Noninvasive Electrocardiol 2008;13(2):191-207.", "Cardiac and vasomotor sympathetic activation occurs with a 2-3 second delay and reaches maximal effect more slowly. Parasympathetic activation is far faster (200-600 ms) but acts on heart rate, which is not a state in this cycle-averaged model (ADR 0002) - hence the lumped single-arm treatment. 3.0 s is the upper end of the stated range."),
    :BR_OPEN_LOOP_GAIN => Provenance("BR.OPEN_LOOP_GAIN", "unitless", 2.0, "B", "reported", "Yamasaki F, Sato T, Sato K, Diedrich A. Analytic and integrative framework for understanding human sympathetic arterial baroreflex function. Front Neurosci 2021;15:707345.", "SPECIES: animal (dog, rabbit) - open-loop gain measured by perfusing vascularly isolated carotid sinus or aortic arch, reported between 1.0 and 3.5 across Kent 1972, Shoukas and Sagawa 1973, McRitchie 1976, Burattini 1994, Sato 1999, Sunagawa 2001. The source states explicitly that this invasive approach is not applicable to humans and that human open-loop gain has NOT been clarified. 2.0 is the mid-range. NO SCALING APPLIED - gain is dimensionless and the reflex architecture is conserved, but this is the weakest link in the component and must be flagged in any result."),
    :BR_RESET_TAU => Provenance("BR.RESET.TAU", "day", 1.0, "B", "assumed", "Dampney RAL. Resetting of the baroreflex control of sympathetic vasomotor activity during natural behaviors. Front Physiol 2017.", "ASSUMED. Baroreflex resetting is well established qualitatively - the reflex re-centres on prevailing pressure over hours to days, which is WHY it cannot set long-run arterial pressure. A specific human time constant is not reported in the sources consulted. 1 day is an order-of-magnitude placeholder. CRITICAL: this parameter is what makes the baroreflex a fast buffer rather than a long-term regulator. If it were infinite the reflex would set long-run pressure and the Guyton claim in ADR 0007 would be false. Sensitivity to it must be tested."),
    :BR_TPR_MAX_FRACTION => Provenance("BR.TPR.MAX_FRACTION", "unitless", 0.5, "B", "assumed", "Saturation bound; see notes.", "ASSUMED. The baroreflex characteristic is sigmoidal and saturates; an unbounded linear gain would let TPR go negative under large pressure excursions. 0.5 means TPR can move at most +/-50 percent from baseline by reflex action alone. Placeholder chosen to keep the model well-posed under hemorrhage-scale perturbations, not extracted from a reported response range."),
    :CIRC_BMAL1_DISSOCIATION_MARKER => Provenance("CIRC.BMAL1.DISSOCIATION_MARKER", "unitless", 1.0, "A", "reported", "Diurnal control of blood pressure is uncoupled from sodium excretion. Hypertension.", "MARKER ROW - not a value. SPECIES: rat, whole-body Bmal1 knockout. Male knockouts showed no significant difference in baseline sodium excretion between 12-h active and inactive periods while circadian MAP rhythm remained intact. This is the evidence for independent renal and cardiovascular clock arms in Circadian.jl. No scaling applied - structural evidence only, no numeric value taken."),
    :CIRC_CV_ACROPHASE => Provenance("CIRC.CV.ACROPHASE", "day", 0.25, "B", "assumed", "Recent advances in understanding the circadian clock in renal physiology. PMC6350809.", "ASSUMED. Placeholder consistent with pressure peaking during the active period. Must be extracted from ambulatory BP monitoring cosinor analysis. NOTE the CV and renal acrophases are deliberately independent parameters - Bmal1 knockout rats lose the renal sodium rhythm while MAP rhythm persists, so a shared phase would be structurally wrong."),
    :CIRC_CV_MAP_DIP_FRACTION => Provenance("CIRC.CV_MAP.DIP_FRACTION", "unitless", 0.15, "A", "reported", "Recent advances in understanding the circadian clock in renal physiology. PMC6350809.", "Blood pressure normally dips 10-20 percent during the inactive period; 0.15 is the midpoint of that stated range. Loss of dipping is associated with elevated cardiovascular risk and target organ damage, so this is a clinically load-bearing parameter, not a cosmetic one."),
    :CIRC_EFFECTOR_TAU => Provenance("CIRC.EFFECTOR.TAU", "s", 3600.0, "B", "assumed", "Recent advances in understanding the circadian clock in renal physiology. PMC6350809.", "ASSUMED. The source describes Per1 as an early aldosterone target gene regulating ENaC, SGLT1, NHE3 and ET-1, and notes Per genes have short half-lives, but does not report an effector delay. 1 h is an order-of-magnitude placeholder. This is a Neurohumoral coupling tau per ADR 0003 and is what makes the clock safe to partition across."),
    :CIRC_PER1_MECHANISM_MARKER => Provenance("CIRC.PER1.MECHANISM_MARKER", "unitless", 1.0, "A", "reported", "Recent advances in understanding the circadian clock in renal physiology. PMC6350809.", "MARKER ROW - not a value. SPECIES: mouse. Per1 knockout mice under high salt plus DOCP lose the night/day difference in sodium excretion and the inactive-period BP dip. Recorded because the clock-gene MECHANISM is rodent-derived while the human circadian sodium rhythm and BP dipping are separately documented in humans. No scaling is applied because no numeric value is taken from this - the mechanism informs structure only."),
    :CIRC_PERIOD => Provenance("CIRC.PERIOD", "day", 1.0, "A", "reported", "Circadian rhythms and the kidney. Nat Rev Nephrol 2018;14:626-635.", "Free-running human period is slightly over 24 h but entrained period is 24 h. This model has no entrainment mechanism (see Circadian.jl) so the entrained value is the correct one to use. If constant-routine or shift-work protocols are ever added this must become a free-running period with an entrainment path."),
    :CIRC_RENAL_NA_ACROPHASE => Provenance("CIRC.RENAL_NA.ACROPHASE", "day", 0.33, "B", "assumed", "Impaired daytime urinary sodium excretion impacts nighttime blood pressure. PMC7400814.", "ASSUMED. Sodium excretion is maximal during daytime and minimal at night; 0.33 d = 8 h after start of active period is a placeholder consistent with that pattern but not extracted from a reported acrophase. Cosinor acrophase must be extracted properly from split-collection data."),
    :CIRC_RENAL_NA_AMPLITUDE => Provenance("CIRC.RENAL_NA.AMPLITUDE", "unitless", 0.25, "B", "assumed", "Circadian rhythms and the kidney. Nat Rev Nephrol 2018;14:626-635.", "ASSUMED PLACEHOLDER. The source establishes that renal plasma flow, GFR and tubular reabsorption peak in the active phase and decline in the inactive phase, but a single relative amplitude is not reported. MUST be estimated against split day/night UNaV data. Reported day/night UNaV ratios in human cohorts span a wide range (tertile boundaries around 0.47 and 0.84 in one CKD study), which is the data class to fit against."),
    :CV_BLOOD_VOLUME_NOMINAL => Provenance("CV.BLOOD_VOLUME.NOMINAL", "L", 5.0, "B", "reported", "Standard physiological reference. VERIFY.", "Nominal 70 kg adult."),
    :CV_CO_NOMINAL => Provenance("CV.CO.NOMINAL", "L/day", 7200.0, "B", "derived", "Standard physiological reference. VERIFY.", "DERIVED from the conventional 5 L/min. 5 x 1440 = 7200 L/day. Units are per-day throughout the model."),
    :CV_HEMATOCRIT_NOMINAL => Provenance("CV.HEMATOCRIT.NOMINAL", "unitless", 0.45, "B", "reported", "Standard physiological reference. VERIFY.", "Adult male nominal. Sex-dependent - female nominal is lower. Sex is deferred until the spine is validated."),
    :CV_MAP_SETPOINT => Provenance("CV.MAP.SETPOINT", "mmHg", 93.0, "B", "reported", "Standard physiological reference. VERIFY.", "Nominal normotensive adult. NOTE this is an OUTPUT of the closed loop, not an input - it emerges from renal-body fluid feedback. It appears here as an initialisation value and a validation target, not as a setpoint the model enforces."),
    :CV_PLASMA_ECF_FRACTION => Provenance("CV.PLASMA.ECF_FRACTION", "unitless", 0.188874, "B", "derived", "Derived to close the loop at nominal.", "DERIVED and NOT rounded: f_pv = BV0 x (1-Hct) / V_ecf = 5.0 x 0.55 / 14.56 = 0.188874. Rounding to 0.20 put blood volume 0.295 L above nominal, which through the venous return gain produced MAP = 104 rather than 93 mmHg. The conventional textbook figure is 0.25; the discrepancy comes from using the measured ECF fraction (20.8% of body mass) rather than the textbook 20%. This is a CLOSURE constraint - if Hct BF.ECF.MASS_FRACTION or CV.BLOOD_VOLUME.NOMINAL change this must be recomputed. Enforced by tools/check_closure.py."),
    :CV_TPR_NOMINAL => Provenance("CV.TPR.NOMINAL", "mmHg/(L/day)", 0.012916667, "B", "derived", "Derived from MAP and CO.", "DERIVED: TPR = MAP/CO = 93/7200. Definitional given the other two. In this minimal model TPR is a constant - it becomes a state once baroreflex and RAAS exist."),
    :CV_VENOUS_RETURN_SENSITIVITY => Provenance("CV.VENOUS_RETURN.SENSITIVITY", "(L/day)/L", 2880.0, "B", "calibrated", "Guyton AC, Coleman TG, Granger HJ. Annu Rev Physiol 1972;34:13-46.", "CALIBRATED, not measured. Originating model: Guyton 1972. The Frank-Starling and venous return relationships are E1; this linearised sensitivity around the operating point is a fitted constant. Second most consequential unmeasured number after the pressure natriuresis slope - together these two set the loop gain."),
    :RN_AUTOREG_LOWER => Provenance("RN.AUTOREG.LOWER", "mmHg", 80.0, "B", "reported", "Standard physiological reference. VERIFY.", "GFR is approximately independent of MAP between roughly 80 and 180 mmHg. Below this GFR falls with pressure. E1 qualitatively; the exact limits vary and are convention here."),
    :RN_AUTOREG_UPPER => Provenance("RN.AUTOREG.UPPER", "mmHg", 180.0, "B", "reported", "Standard physiological reference. VERIFY.", "See RN.AUTOREG.LOWER."),
    :RN_GFR_NOMINAL => Provenance("RN.GFR.NOMINAL", "L/day", 180.0, "B", "reported", "Standard physiological reference. VERIFY.", "125 mL/min = 180 L/day, conventional nominal adult value. Tier B pending a citable primary source; the value itself is textbook-level E1 but its provenance here is convention."),
    :RN_H2O_OBLIGATORY_LOSS => Provenance("RN.H2O.OBLIGATORY_LOSS", "L/day", 0.5, "B", "reported", "Standard physiological reference. VERIFY.", "Minimum urine volume needed to excrete the daily solute load at maximal urinary concentration. Sets a floor on water excretion."),
    :RN_NA_FRACTIONAL_REABSORPTION => Provenance("RN.NA.FRACTIONAL_REABSORPTION", "unitless", 0.9918651, "B", "derived", "Standard physiological reference. VERIFY.", "DERIVED to close the loop at nominal: filtered load = 180 L/day x 140 mEq/L = 25200 mEq/day; excretion must equal intake of 205 mEq/day at steady state, so FR = 1 - 205/25200 = 0.9918651. NOT rounded - rounding to 0.9915 gave excretion of 214.2 vs intake 205, a 9.2 mEq/day drift that ran the model to a lethal state while reporting Success. This is NOT an independent measurement - it is fixed by the other three values, and that dependency must be preserved if any of them changes."),
    :RN_PRESSURE_NATRIURESIS_SLOPE => Provenance("RN.PRESSURE_NATRIURESIS.SLOPE", "(mEq/day)/mmHg", 20.0, "B", "calibrated", "Guyton AC, Coleman TG, Granger HJ. Circulation: overall regulation. Annu Rev Physiol 1972;34:13-46.", "CALIBRATED, not measured. Originating model: Guyton 1972 systems analysis. The EXISTENCE and steepness of pressure natriuresis is E1 and well replicated; this particular slope is a fitted constant that propagated through the modelling literature. It is the single most consequential unmeasured number in the model - it sets the long-run pressure setpoint. Must be re-estimated with a posterior, not carried as a point value."),
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
