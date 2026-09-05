"""
Respiratory control and alveolar gas exchange - MINIMAL.

STRUCTURE SOURCES
  Alveolar ventilation equation: mass balance on CO2. PaCO2 = K*VCO2/V_A.
    Definitional given the constant, which is arithmetic on barometric pressure
    and saturated vapour pressure - see RESP.ALVEOLAR.K.
  Piecewise chemoreflex: Guluzade NA, Huggard JD, Keltz RR, Duffin J, Keir DA.
    Strategies to improve respiratory chemoreflex characterization by Duffin's
    rebreathing. Exp Physiol 2022;107(12):1507-1520. PMID 36177675. Fits a
    PIECEWISE model - a ventilatory recruitment threshold and a slope above it -
    and finds the threshold far more reproducible than the slope (ICC 0.93-0.97,
    CV 2.2-3.0% against CV 14-18%). ABSTRACT ONLY, not open access.
  Threshold position: Mateika JH, Ellythy M. Respir Physiol Neurobiol
    2003;138(1):45-57. PMID 14519377. n = 8 awake healthy matched controls.
    ABSTRACT ONLY. Also the source of the sub-threshold ventilation figure that
    is deliberately NOT used - see RESP.VENTILATION.BASAL.
  Slope above threshold: Mannee DC et al. ERJ Open Res 2018;4(1):00141-2017.
    PMID 29492407. Open access, read in full.
  Respiratory water loss: mass balance on water vapour.

EVIDENCE (ADR 0006)
  E1  Arterial PCO2 is set by metabolic CO2 production over alveolar ventilation.
      Mass balance, the foundation of respiratory physiology.
  E1  The ventilatory response to CO2 is PIECEWISE: flat below a recruitment
      threshold, rising above it. Duffin's model, two independent groups.
  E2  The threshold sits ABOVE eupnoea - 45.3 mmHg hyperoxic against a resting
      PaCO2 near 40. Two groups, but both abstract-only and the value carries a
      protocol caveat: rebreathing after voluntary hyperventilation may raise the
      measured threshold.
  E1  Respiratory water loss is ventilation times the expired-minus-inspired
      water content. Mass balance.
  --  RESP.CO2.PRODUCTION and RESP.DEADSPACE.FRACTION are ASSUMED. No admissible
      source could be opened; see the ledger notes for what was searched.

WHAT THIS DELIBERATELY OMITS
  Oxygen and haemoglobin carriage - that is Blood.jl. Acid-base and pH, which
  need bicarbonate and therefore a renal limb that does not exist. The hypoxic
  drive, which makes this model SEA LEVEL ONLY. Exercise. Sleep. Dead space as
  a variable rather than a fraction. The breath itself, per ADR 0017.

WHY PCO2 IS AN INPUT AND NOT AN OUTPUT, WHICH IS THE OPPOSITE OF THIS MODEL'S
TREATMENT OF ARTERIAL PRESSURE

ADR 0017 originally decided PaCO2 would be an OUTPUT of the chemoreflex loop, as
arterial pressure is an output of the renal loop. Its own falsifiable test killed
that. The recruitment threshold is at 45.3 mmHg and resting PaCO2 is near 40, so
AT REST THE CHEMOREFLEX IS BELOW ITS OWN THRESHOLD AND IS NOT THE OPERATIVE
CONTROL. Deriving resting PaCO2 from it would derive it from a mechanism not yet
recruited. On the extrapolated line, ventilation at PaCO2 40 comes out at 19.3
L/min against a real 6.2.

So the dependency is INVERTED, which is HANDOVER section 3.6's lesson applied a
second time: derive from the quantity that is actually measured. Resting PaCO2 is
sourced (weakly - see the ledger row) and V_basal is derived from it. The
component's claim shrinks to the RESPONSE, which is what the chemoreflex data
measure.

THAT ASYMMETRY IS PHYSIOLOGICAL, NOT A MODELLING FAILURE. Pressure natriuresis
operates continuously around the resting pressure, so its gain is measured AT the
operating point. The CO2 chemoreflex's gain is measured only ABOVE a threshold
that lies above the operating point.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams
using ..LedgerParams:
    RESP_CO2_PRODUCTION, RESP_DEADSPACE_FRACTION, RESP_ALVEOLAR_K,
    RESP_CHEMO_CO2_SLOPE, RESP_CHEMO_VRT, RESP_VENTILATION_BASAL,
    RESP_H2O_GAS_CONTENT, BF_BODY_MASS_REFERENCE

"""
    Respiratory(; name, body_mass, enabled = true)

Ventilation, alveolar CO2, and the respiratory water flux.

Inputs   th_mod - the thyroid metabolic multiplier, ADR 0019. Exactly 1.0 unless
         the thyroid metabolic arm is switched on, which it is not by default.
Outputs  V_E (L/min), PaCO2 (mmHg), H2O_resp (L/day)

`enabled = false` FREEZES VENTILATION AT BASAL, which makes the chemoreflex inert
and leaves the water flux at exactly its reference value. Every existing protocol
already sits below the recruitment threshold, so the two branches agree there;
the flag exists so a CO2 challenge can be run against a no-chemoreflex control.
"""
function Respiratory(; name, body_mass = BF_BODY_MASS_REFERENCE,
                     enabled::Bool = true)

    sz = size_factor(body_mass)

    pars = @parameters begin
        # EXTENSIVE. A bigger body produces more CO2 and ventilates more. VCO2,
        # the slope and the basal ventilation all scale together, which is what
        # keeps PaCO2 INTENSIVE - see the invariance argument below.
        VCO2     = sz * RESP_CO2_PRODUCTION
        S_co2    = sz * RESP_CHEMO_CO2_SLOPE
        V_basal  = sz * RESP_VENTILATION_BASAL
        # INTENSIVE. A fraction, a partial pressure, a pressure constant, and a
        # concentration per litre of gas. None of them care how big you are.
        f_dead   = RESP_DEADSPACE_FRACTION
        K_alv    = RESP_ALVEOLAR_K
        VRT      = RESP_CHEMO_VRT
        w_gas    = RESP_H2O_GAS_CONTENT
    end

    vars = @variables begin
        V_E(t)          # L/min    total minute ventilation
        V_A(t)          # L/min    alveolar ventilation
        PaCO2(t)        # mmHg     arterial CO2 tension
        H2O_resp(t)     # L/day    OUTPUT to body fluids
        th_mod(t)       # -        INPUT from thyroid, 1.0 at euthyroid
        VCO2_eff(t)     # L/min    OUTPUT to blood - the load AFTER the thyroid arm
    end

    # THE METABOLIC HYPERBOLA'S NUMERATOR. PaCO2 = C / V_E, with C carrying the
    # dead space so the whole loop can be written in terms of TOTAL ventilation,
    # which is what the chemoreflex sources report and what the water flux needs.
    # th_mod IS THE THYROID METABOLIC ARM AND IT IS 1.0 UNLESS SWITCHED ON.
    # RESP.CO2.PRODUCTION was a primitive - assumed, at a round teaching number -
    # until ADR 0019; it is now a reference production times a modelled multiplier,
    # the same transition CV.CO.NOMINAL and RN.H2O.OBLIGATORY_LOSS already made.
    # With the arm off Thyroid.jl emits the literal constant 1.0 and this reduces
    # to the bare parameter, which thyroid_prereg.md section 6 requires exactly
    # rather than approximately.
    C = K_alv * VCO2 * th_mod / (1.0 - f_dead)

    # SOLVED IN CLOSED FORM, NO STATE, per ADR 0017 decision 2. The chemoreflex
    # and the alveolar equation are two equations in two unknowns:
    #
    #     V_E   = V_basal + S*(PaCO2 - VRT)     above the threshold
    #     PaCO2 = C / V_E
    #
    # which is a quadratic in V_E. Below the threshold the first equation is just
    # V_E = V_basal and no solve is needed at all.
    #
    # THE BRANCH CONDITION IS ON C, NOT ON PaCO2, and that is what makes this
    # explicit rather than implicit: at basal ventilation PaCO2 = C/V_basal, so
    # the reflex is recruited exactly when C >= V_basal*VRT. No fixed point, no
    # nonlinear solver, nothing for the integrator to iterate on.
    #
    # THE TWO BRANCHES MEET CONTINUOUSLY. At C = V_basal*VRT the quadratic
    # returns V_basal exactly - substitute and the terms cancel - so there is no
    # jump in V_E and no jump in the water flux. That matters because a
    # discontinuity here would land straight in D(V_ecf).
    b = S_co2 * VRT - V_basal
    V_recruited = (-b + sqrt(b * b + 4.0 * S_co2 * C)) / 2.0

    eqs = [
        # enabled is a build-time Bool, so this resolves to ONE concrete equation
        # at construction - not a runtime branch in the compiled system. Same
        # pattern as the ADH and RAAS disabled branches.
        V_E ~ enabled ? ifelse(C >= V_basal * VRT, V_recruited, V_basal) : V_basal,

        V_A ~ (1.0 - f_dead) * V_E,

        # The alveolar ventilation equation, written against TOTAL ventilation
        # through C. Identical to K*VCO2/V_A by construction.
        PaCO2 ~ C / V_E,

        # RESPIRATORY WATER LOSS. Expired gas leaves saturated at body
        # temperature and inspired gas carries whatever the room holds; w_gas is
        # the difference. 1440 converts minutes to days, 1e6 converts mg to kg,
        # and a kg of water is a litre.
        #
        # THIS IS THE ONLY OUTPUT THAT REACHES THE REST OF THE MODEL, and it is
        # what stops this component being an island on the day it is built.
        # BF.H2O.INSENSIBLE_LOSS was 0.8 L/day, assumed, cited "Convention
        # pending primary source"; this computes 39% of it and leaves the rest as
        # a named cutaneous residual.
        H2O_resp ~ V_E * 1440.0 * w_gas / 1.0e6,

        # THE CO2 LOAD AFTER THE THYROID ARM, EXPOSED SO BLOOD CAN DIVIDE IT BY THE
        # EXCHANGE RATIO AND GET OXYGEN CONSUMPTION. It is the same quantity C is
        # built from, published rather than recomputed downstream, so there is one
        # statement of the metabolic load in the model instead of two that can
        # drift. Identical to VCO2 whenever the thyroid metabolic arm is off.
        VCO2_eff ~ VCO2 * th_mod,
    ]

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    respiratory_couplings()

Declared connections, per src/coupling.jl.

ONE EDGE, and it is a mass flux rather than a signal. Ventilation carries water
out of the body, so this is Conservation and a multirate partition must not cut
across it any more than it may cut across renal excretion.

WHAT IS NOT DECLARED HERE, DELIBERATELY: respiratory -> blood. Gas transport is
Blood.jl's business and it declares its own edge.
"""
function respiratory_couplings()
    return [
        Coupling(:respiratory, :bodyfluids, Conservation,
                 note = "ventilation carries water vapour out of the body"),
    ]
end
