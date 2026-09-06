"""
Potassium balance - ONE state, and the ion that finally gives aldosterone a job.

STRUCTURE SOURCES
  Dietary potassium, and plasma potassium:
    NHANES 2007-2012 public microdata, extracted in
    validation/macula_densa_potassium_extract.py. Intake n = 8893 adults;
    plasma n = 8809.
  The renal fraction of dietary potassium, and the aldosterone response to
  plasma potassium:
    Brunner HR, Baer L, Sealey JE, Ledingham JGG, Laragh JH. The influence of
    potassium administration and of potassium deprivation on plasma renin in
    normal and hypertensive subjects. J Clin Invest 1970;49(11):2128-38.
    PMC535788. OPEN ACCESS, read in full. 10 NORMAL subjects, constant diet,
    potassium loaded or depleted with sodium held fixed. Six studies at a
    dietary sodium of 100 mEq/day or more are admissible; the rest were run at
    0.5-15 mEq/day, where renin is maximally stimulated and this model does not
    operate.

EVIDENCE (ADR 0006)
  E1  Potassium balance is intake against renal excretion, with a small faecal
      residual. Multiply replicated.
  E1  About 98% of body potassium is intracellular, so a load distributes far
      beyond the extracellular fluid.
  E1  Plasma potassium stimulates aldosterone directly.
  --  K.FRACTIONAL_EXCRETION is DERIVED to close the balance against a measured
      plasma potassium, so the resting concentration is an INPUT. See below.
  --  K.DISTRIBUTION_VOLUME is ASSUMED and sets the time constant only.

WHY PLASMA POTASSIUM IS AN INPUT, WHICH VOIDS ADR 0021's FALSIFIABLE TEST 2

The pre-registration named plasma potassium a TARGET and forbade using it to set
a parameter.

A RETRACTION FIRST. This docstring said renal potassium clearance in healthy
adults could not be sourced, and that was FALSE. It generalised what a handful of
queries returned - ketoacidosis, chronic kidney disease, diuretics, Gitelman - into
a claim about the literature, which is HANDOVER section 5 item 20, the failure mode
this repository named after RESP.CO2.PRODUCTION.

THE SEARCH TERM WAS WRONG, NOT THE LITERATURE. `Fractional excretion of potassium`
is a bedside phrase for separating renal from extrarenal hypokalaemia, so it
returns disease. The physiology is under potassium balance, potassium loading and
adaptation in normal man, and it is the Utrecht group - Hene 1986 (PMID 3523191),
Hene 1988 (PMID 3199680), Rabelink 1990 (PMID 2266680), each six healthy
volunteers on controlled intake. All three are read at ABSTRACT level only and
none is open access; they are used as a COMPARISON in
validation/macula_densa_potassium_extract.py section 4b, and they set nothing here.

WHAT REMAINS TRUE is that no admissible study gives this model's own composite -
dietary intake, plasma potassium and glomerular filtration in the same healthy
subjects - so FE_K is still DERIVED rather than reported.

Branch P4 said not to build a balance whose outflow is invented. The outflow's
SHAPE is sourced - excretion is proportional to filtered load and to plasma
concentration - and only its LEVEL is not, which is a case the pre-registration
did not anticipate and its amendment 9 records.

So the dependency is inverted for the FOURTH time in this model, after arterial
PCO2 (ADR 0017), the thyroid operating point and plasma bicarbonate. The pattern
is now the rule: WHERE A CONCENTRATION IS MEASURED IN THOUSANDS OF PEOPLE AND
ITS CLEARANCE IS MEASURED IN NOBODY HEALTHY, THE CONCENTRATION IS THE INPUT.

WHAT REMAINS A PREDICTION is the RESPONSE - how plasma potassium moves when
intake or filtration changes - because that follows from the sourced shape and
not from the derived level.

AND FE_K IS THE WRONG THING TO ARGUE ABOUT, WHICH IS MEASURABLE. Sweeping it from
0.04 to 0.16 moves steady-state plasma potassium only from 4.18 to 3.87 mmol/L,
every value inside the human range, because the exponent below pins it. So ADR
0021's falsifiable test 2 would be a WEAK test even with FE_K perfectly sourced,
and that - not the sourcing - is the honest reason plasma potassium is not a
strong prediction of this structure.

TWO MEASURED DISAGREEMENTS, both recorded in the extract's section 4b. The urinary
fraction is a CONSTANT here and is not one in humans: Hene measured 0.63 at 80
mEq/day rising to 0.78 at 300, Rabelink about 0.80 at 400, all below the 0.884
this model uses at every intake. And there is NO POTASSIUM ADAPTATION here at all
- Rabelink found renin and aldosterone back at baseline by day 20 of a 400 mmol/day
load with kaliuresis maintained, where this model holds aldosterone at 2.80 times
baseline for ever.

THE EXPONENT WAS RE-SOURCED ON 2026-09-06 and the first disagreement was DECIDED
rather than left open. validation/potassium_doseresponse_prereg.md, committed
before the search. Cappuccio 2016 (BMJ Open, PMC5013341) reports urinary AND plasma
potassium in both arms of twenty supplementation trials, 1216 participants, intake
verified by 24-hour urine - which is this model's elasticity, measured twenty
times. The exponent moved 17.71 -> 17.73, WHICH IS NOTHING, and its interval went
from a twelvefold spread over ten people to 11.9-24.7 over 1216.

AND THE RENAL FRACTION STAYS A CONSTANT BY DECISION D4, NOT BY DEFAULT: the same
paper's MARGINAL fraction is 0.734, BELOW this row, which would make the average
fall with intake where Hene and Rabelink have it rising. The sources disagree on
the SIGN, so the pre-registered rising form is not taken and the disagreement is
recorded. See K.RENAL_FRACTION.

WHAT IS NOW CHECKED, AND NEVER WAS: f_renal * K_intake = 0.884 * 69.06 = 61.05
mmol/day of urinary potassium, against 61.17 measured by 24-hour collection in the
nineteen control arms of that meta-analysis. Treat 0.2% as too good - a dietary
recall understates intake and those cohorts are not American - but it rules out a
gross error in a product that had been compared with nothing at all.

WHAT THIS DELIBERATELY OMITS
  Every transcellular shift: insulin, beta-agonists, acid-base, exercise, cell
  lysis. The intracellular pool is a BUFFER here and not a compartment, so the
  model cannot represent anything whose perturbed variable is the DISTRIBUTION
  of potassium rather than its balance - which is most of acute hyperkalaemia.
  Aldosterone's effect ON potassium excretion is also absent; see Raas.jl.
  No membrane potential, no cardiac rhythm, no acid-base coupling.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams
using ..LedgerParams:
    K_INTAKE_NOMINAL, K_RENAL_FRACTION, K_FRACTIONAL_EXCRETION,
    K_DISTRIBUTION_VOLUME, K_PLASMA_REFERENCE, K_EXCRETION_EXPONENT,
    BF_BODY_MASS_REFERENCE

"""
    Potassium(; name, body_mass, enabled = true)

Whole-body potassium balance.

Inputs   GFR (L/day) from renal
Outputs  K_p (mmol/L), K_excr (mmol/day)

`enabled = false` FREEZES plasma potassium at its reference, which makes the
aldosterone potassium term inert and leaves every existing result untouched. Same
pattern as the ADH, RAAS, respiratory and thyroid disabled branches.
"""
function Potassium(; name, body_mass = BF_BODY_MASS_REFERENCE, enabled::Bool = true)

    sz = size_factor(body_mass)      # SURFACE-like: intake tracks metabolic rate
    mz = mass_factor(body_mass)      # MASS-like: a distribution volume is a volume

    pars = @parameters begin
        K_intake = sz * K_INTAKE_NOMINAL
        f_renal  = K_RENAL_FRACTION          # INTENSIVE, a fraction
        FE_K     = K_FRACTIONAL_EXCRETION    # INTENSIVE, a fraction
        V_K      = mz * K_DISTRIBUTION_VOLUME
        K_p_ref  = K_PLASMA_REFERENCE        # INTENSIVE, a concentration
        n_K      = K_EXCRETION_EXPONENT      # INTENSIVE, an exponent
    end

    vars = @variables begin
        GFR(t)                        # L/day    INPUT from renal
        K_p(t) = K_PLASMA_REFERENCE   # mmol/L   THE ONE STATE
        K_excr(t)                     # mmol/day OUTPUT, renal potassium excretion
        K_load(t)                     # mmol/day the renal load, intake less stool
    end

    eqs = if enabled
        [
            # THE RENAL LOAD. Not all dietary potassium reaches the kidney; the
            # residual is stool, which this model does not have, so it is removed
            # here as a sourced fraction rather than ignored.
            K_load ~ f_renal * K_intake,

            # EXCRETION IS A FRACTION OF THE FILTERED LOAD. The shape is sourced -
            # excretion rises with filtration and with plasma concentration - and
            # the fraction is DERIVED to close the balance at the reference
            # individual, which is why the resting concentration is an input and
            # ADR 0021's falsifiable test 2 is void. See the header.
            #
            # FE_K IS TEN TIMES SODIUM'S, and that is the whole difference between
            # the two ions: sodium is reabsorbed, potassium is SECRETED distally,
            # so its excretion can exceed what a purely reabsorptive nephron could
            # deliver.
            #
            # THE EXPONENT IS THE ROW THE SUITE DEMANDED. Written LINEAR in plasma
            # potassium - the obvious first form - the steady-state concentration
            # is PROPORTIONAL to intake, and doubling an ordinary diet gave 7.6
            # mmol/L. ADR 0021's falsifiable test 3 caught it on its first run.
            # Real renal potassium excretion adapts far more steeply than that:
            # a fortyfold change in intake moves plasma potassium by a third.
            #
            # ONE EXPONENT LUMPS THREE MECHANISMS. Excretion rises with
            # aldosterone, with distal flow and with plasma potassium, and every
            # human study found moves all three together. Collapsing them onto
            # plasma potassium is a LUMPING, not a claim that the other two do not
            # exist - and it means ALDOSTERONE'S EFFECT ON POTASSIUM IS INSIDE
            # THIS NUMBER rather than absent from the model. ADR 0021 decision 5
            # is amended accordingly.
            K_excr ~ FE_K * GFR * K_p_ref * (K_p / K_p_ref)^n_K,

            # ONE COMPARTMENT, WITH THE INTRACELLULAR POOL AS A BUFFER RATHER THAN
            # A STATE. V_K is total body water, not extracellular volume, which is
            # the crudest possible statement of the fact that a load distributes
            # into cells. IT CANCELS AT STEADY STATE - the balance is load against
            # excretion - so every resting value here is independent of it and only
            # the TIME COURSE is not. That is why an assumed row is tolerable and
            # why NO ACUTE POTASSIUM MAGNITUDE MAY BE REPORTED, exactly as
            # BF.ICF_ECF.OSMOTIC_TAU blocks acute osmotic magnitudes.
            D(K_p) ~ (K_load - K_excr) / V_K,
        ]
    else
        [
            K_load ~ 0.0,
            K_excr ~ 0.0,
            D(K_p) ~ 0.0,
        ]
    end

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    potassium_couplings()

Declared connections, per src/coupling.jl.

TWO EDGES. Renal supplies the filtered load through glomerular filtration;
potassium supplies plasma concentration to the adrenal, which is the join ADR
0021 exists for.

THE RETURN ARM - aldosterone acting on potassium excretion - IS NOT DECLARED
BECAUSE IT IS NOT BUILT. Every human study found moves potassium intake and
aldosterone together, so neither gain separates from the other. That absence is
recorded on RAAS.ALDO.K_GAIN rather than papered over with a plausible number.
"""
function potassium_couplings()
    return [
        Coupling(:renal, :potassium, Mechanical,
                 note = "filtered potassium load follows glomerular filtration"),
        # MECHANICAL rather than Neurohumoral, and the choice is a statement about
        # this model rather than about the adrenal. The real response takes
        # minutes; here aldosterone is ALGEBRAIC in plasma potassium, so declaring
        # a lag the equations do not implement would be a declaration that is
        # false. Same precedent as bodyfluids -> adh, where plasma osmolality is
        # sensed with no lag. The missing lag is far shorter than anything this
        # model integrates.
        Coupling(:potassium, :raas, Mechanical,
                 gain_param = :RAAS_ALDO_K_GAIN,
                 note = "plasma potassium stimulates aldosterone directly"),
    ]
end
