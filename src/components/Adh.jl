"""
Antidiuretic hormone and osmoregulation, lumped.

ADR 0006 build order item 5. Replaces the water-excretion PLACEHOLDER in
`Renal.jl`, which was `max(V_min, H2O_in - H2O_ins)` - intake minus insensible
loss, floored. That held water balance closed so the sodium loop could be
tested; it was not osmoregulation and could not respond to anything.

STRUCTURE SOURCES
  Osmotic threshold for vasopressin release, and the linearity of the
  osmolality-vasopressin relation:
    Zerbe RL, Miller JZ, Robertson GL. The reproducibility and heritability of
    individual differences in osmoregulatory function in normal human subjects.
    J Lab Clin Med 1991;117(1):51-9, PMID 1987308.
    Linear regression of plasma vasopressin on plasma osmolality during
    hypertonic saline infusion. OSMOTIC THRESHOLD 280 to 288 mOsm/kg across
    individuals; SENSITIVITY 0.12 to 1.66 pg/ml per mOsm/kg, a FOURTEEN-FOLD
    spread that was highly reproducible WITHIN a subject (r = 0.94 on repeat)
    and correlated within monozygotic but not dizygotic twins. In 80 healthy
    adults the frequency distributions of both threshold and sensitivity were
    essentially normal.
    Human, healthy adults. Verified against the PubMed record 2026-08-25.

  That the relation is well described by linear regression at all:
    Robertson GL. Physiology of ADH secretion. Kidney Int Suppl 1987;21:S20-6,
    PMID 3476800: "linear regression analysis of the relationship between
    plasma vasopressin and plasma osmolality or sodium continues to provide a
    simple and useful way to describe the major functional properties of the
    osmoregulatory system", and the SET and the SENSITIVITY can be altered
    independently, which is why they are two parameters here and not one.

THE FORM, AND WHY IT IS NOT A LINEAR INTERPOLATION OF URINE VOLUME
  Urine volume is solute excretion divided by urine concentration. Modelling
  ADH as setting URINE OSMOLALITY and letting volume follow gives the strongly
  nonlinear volume response the kidney actually has - small changes near the
  dilute end move litres, the same change near the concentrated end moves
  millilitres. Interpolating VOLUME linearly between its limits was tried first
  and forced an implausible maximal diuresis; interpolating CONCENTRATION puts
  every derived number in range without tuning:

    280-284 mOsm/kg  ->  full water diuresis, 12.0 L/day
    287 (baseline)   ->  U_osm 353,           1.70 L/day
    290              ->  U_osm 656,           0.91 L/day
    295              ->  U_osm 1161,          0.52 L/day

  The baseline row reproduces the old placeholder EXACTLY, which is the point:
  wiring this in does not move the operating point.

WHAT IS SOURCED AND WHAT IS NOT
  SOURCED   the osmotic threshold, and the linear form.
  ASSUMED   the minimum urine osmolality and the daily urinary solute load.
            Neither was found characterised in healthy humans in a form this
            model can consume; the search returned lithium cohorts, hydration
            indices and clinical case series. Both are flagged in the ledger.
  DERIVED   the maximum urine osmolality, forced by the obligatory minimum
            urine volume already in the ledger, and the osmotic sensitivity,
            forced by requiring baseline water balance to close. Both are
            enforced by tools/check_closure.py.

  NOTE WHAT THE DERIVATION DOES NOT DO. The sensitivity here is a NORMALISED
  gain from osmolality to antidiuretic activity. It is NOT Zerbe's 0.12-1.66
  pg/ml per mOsm/kg, because this model carries no plasma vasopressin
  concentration and there is no sourced map from pg/ml to urine osmolality.
  The measured fourteen-fold spread is therefore recorded and unused. It is the
  obvious population covariate for src/ensemble.jl and the obvious next thing
  to source.

DIVERGENCES LOGGED
  1. NON-OSMOTIC RELEASE IS ABSENT. Baylis 1987 (PMID 3318505) names
     hypotension and hypovolaemia, acting through carotid sinus and left
     atrial receptors, as a major nonosmotic stimulus. This component responds
     to osmolality alone. In haemorrhage or severe volume depletion it will
     under-retain water.
  2. THIRST IS ABSENT. Water intake is a fixed parameter, so the model has
     the efferent arm of osmoregulation and not the afferent one. Osmolality
     is defended by excretion only, which halves the real control authority.
  3. NO ADRENAL OR RENAL LAG. Antidiuretic activity is algebraic in
     osmolality. Vasopressin half-life is minutes and the aquaporin response
     is faster than the day timebase, so this is consistent with ADR 0002 -
     but it is a choice, and it means the model cannot show the delay between
     a water load and its excretion.
  4. RECTIFICATION AT BOTH ENDS. clamp() gives derivative discontinuities at
     full diuresis and maximal antidiuresis, shared with Renal.GFR and
     Raas.renin_drive. Consistent, not independently justified.

Inputs   Osm_ecf (mOsm/kg)
Outputs  u_osm (mOsm/kg) - urine osmolality, consumed by Renal.H2O_excr
         adh (unitless, 0-1) - normalised antidiuretic activity, diagnostic

When `enabled = false`, u_osm is held at the value that reproduces the old
placeholder exactly, so water excretion reverts to intake minus insensible
loss. ADR 0008: the disabled branch is TESTED, not assumed.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams:
    ADH_OSM_THRESHOLD, ADH_OSM_SENSITIVITY, ADH_URINE_OSM_MIN,
    ADH_URINE_OSM_MAX, ADH_URINE_OSM_BASELINE

"""
    Adh(; name, enabled = true)

Lumped osmoregulation. See the module docstring.
"""
function Adh(; name, enabled::Bool = true)

    pars = @parameters begin
        Osm_thr  = ADH_OSM_THRESHOLD        # mOsm/kg
        k_adh    = ADH_OSM_SENSITIVITY      # per mOsm/kg
        U_min    = ADH_URINE_OSM_MIN        # mOsm/kg
        U_max    = ADH_URINE_OSM_MAX        # mOsm/kg  REPORTED (Tryding 1988)
        U_base   = ADH_URINE_OSM_BASELINE   # mOsm/kg  DERIVED, disabled branch
    end

    vars = @variables begin
        Osm_ecf(t)      # mOsm/kg  INPUT from body fluids
        adh(t)          # unitless normalised antidiuretic activity, 0-1
        u_osm(t)        # mOsm/kg  OUTPUT to renal
    end

    eqs = if enabled
        [
            # Linear in osmolality above threshold, saturating at both ends.
            # Below threshold vasopressin is suppressed and the kidney is in
            # full water diuresis; above the antidiuretic ceiling it cannot
            # concentrate further.
            adh ~ clamp(k_adh * (Osm_ecf - Osm_thr), 0.0, 1.0),

            # ADH sets urine CONCENTRATION. Volume follows in Renal as solute
            # load divided by this, which is where the nonlinearity comes from.
            u_osm ~ U_min + adh * (U_max - U_min),
        ]
    else
        [
            adh   ~ 0.0,
            u_osm ~ U_base,
        ]
    end

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    adh_couplings()

Osmolality is sensed by hypothalamic osmoreceptors and the antidiuretic
response is expressed in the collecting duct. Both limbs are fast against a
day timebase, so neither carries a lag here.
"""
function adh_couplings()
    return [
        Coupling(:bodyfluids, :adh, Mechanical,
                 note = "plasma osmolality sensed by hypothalamic osmoreceptors"),
        Coupling(:adh, :renal, Mechanical,
                 note = "antidiuretic activity sets urine osmolality; " *
                        "volume follows as solute load / concentration"),
    ]
end
