"""
Blood oxygen transport - FORWARD COMPUTATION, NO FEEDBACK.

STRUCTURE SOURCES
  Alveolar gas equation: PAO2 = FiO2*(PB - PH2O) - PaCO2/R. Mass balance.
  Oxyhaemoglobin dissociation: Severinghaus JW. Simple, accurate equations for
    human blood O2 dissociation computations. J Appl Physiol Respir Environ Exerc
    Physiol 1979;46(3):599-602. PMID 35496. doi:10.1152/jappl.1979.46.3.599.
    S = 1/(23400/(PO2^3 + 150*PO2) + 1), fitted to the STANDARD human curve to
    within +/- 0.0055 fractional saturation over 0 < S < 1. Abstract read; the
    equation and its stated accuracy are both in it.
  Oxygen content and convective delivery: definitional.
  Haemoglobin: Morales-Mendoza E et al. Med Sci (Basel) 2026;14(1):136.
    PMID 41892851. n = 667,857, low-altitude stratum, sexed. Open access.

EVIDENCE (ADR 0006)
  E1  Alveolar PO2 follows from inspired PO2 and alveolar PCO2 through the
      exchange ratio.
  E1  Almost all arterial oxygen is carried on haemoglobin; dissolved oxygen is a
      small additive term proportional to PO2.
  E1  Saturation is a sigmoid function of PO2.
  E1  Oxygen delivery is cardiac output times arterial content. Definitional.
  E2  Arterial PO2 is below alveolar by a measurable difference. ASSUMED here -
      the source was identified (Crapo 1999) and could not be opened.

THIS COMPONENT CLOSES NO LOOP, AND SAYING SO PLAINLY IS THE POINT

There is no oxygen feedback anywhere in it. The hypoxic ventilatory drive is
omitted by ADR 0017 and the cardiac-output response to anaemia and hypoxia is
real, E1, and deliberately not built - it would perturb the pressure loop, and
one change at a time is how this repository stays testable.

So this is a set of observables. What it buys is that four quantities which
already existed finally do work - cardiac output, haematocrit, ventilation and
alveolar CO2 - and that the model reports the variable clinical physiology
actually cares about.

IT IS THE FIRST QUANTITY IN THIS MODEL THAT NEEDS TWO SUBSYSTEMS AT ONCE. Oxygen
delivery is cardiac output times arterial content: the first from the
cardiovascular side, the second from the respiratory side. Every previous
coupling passed a signal or a flux between two components. This one is a product.

WHAT THIS DELIBERATELY OMITS
  The Bohr effect, temperature and 2,3-DPG - the curve is fixed at normal pH and
  temperature, and pH needs bicarbonate, which is renal and absent. Venous
  content, the Fick relation and extraction ratio, which need a tissue oxygen
  consumption row. Carbon dioxide carriage. Carboxyhaemoglobin and
  methaemoglobin, which are non-zero even in healthy non-smokers. Regional
  ventilation-perfusion inequality, collapsed into one A-a difference.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams
using ..LedgerParams:
    BLOOD_O2_BINDING_CAPACITY, BLOOD_O2_CURVE_A, BLOOD_O2_CURVE_B,
    BLOOD_O2_SOLUBILITY, BLOOD_O2_AA_GRADIENT,
    RESP_O2_INSPIRED_FRACTION, RESP_EXCHANGE_RATIO, RESP_ALVEOLAR_K,
    RESP_CO2_ARTERIAL_RESTING,
    AB_PK_APPARENT, AB_CO2_SOLUBILITY, AB_HCO3_PLASMA

"""
    Blood(; name, sex = :male)

Arterial oxygen tension, saturation, content and convective delivery.

Inputs   PaCO2 (mmHg) and VCO2_eff (L/min) from respiratory, CO (L/day) from
         cardiovascular
Outputs  PaO2, SaO2, CaO2, DO2, VO2, avDO2, CvO2, SvO2, ER - all observables,
         nothing feeds back

`sex` selects the haemoglobin pair. ADR 0014 makes `:both` an error rather than
an average, and haemoglobin is one of the largest sexed differences in human
physiology - 16 percent here.
"""
function Blood(; name, sex::Symbol = :male)

    sex in (:male, :female) ||
        error("sex must be :male or :female, got :$sex")

    pars = @parameters begin
        # ALL INTENSIVE, and that is worth stating because this component has no
        # extensive parameter at all. A concentration, a capacity per gram, two
        # curve coefficients, a solubility, a partial pressure difference and two
        # fractions - none of them changes because a person is larger. Body size
        # enters oxygen DELIVERY only, through cardiac output, which already
        # scales. So Blood.jl contributes nothing to ensemble.jl's scaling list,
        # and that absence is deliberate rather than an oversight.
        # HAEMOGLOBIN IS NOW THE REFERENCE AND NOT THE LIVE VALUE. ADR 0023. It
        # was read straight into the content equation until red cell mass became a
        # state; the live concentration is MCHC*Hct_eff, and this row is what that
        # must reproduce at the reference haematocrit - the identity
        # check_closure.py now asserts. The row itself is unchanged and still
        # sourced; only its ROLE moved, from live value to reference.
        # HAEMOGLOBIN IS NO LONGER READ DIRECTLY. It enters through RBC.MCHC,
        # which is DERIVED from it and from the reference haematocrit, and
        # check_closure.py asserts that MCHC*Hct reproduces the sourced row at the
        # reference state. The provenance is unchanged; the route is one step
        # longer and one parameter shorter.
        MCHC     = LedgerParams.param(:RBC_MCHC, sex)
        # Resting arterial PCO2, used ONLY to fix the reference oxygen content
        # below. It is the same row the respiratory component is sourced from, so
        # sea level is stated once here and cannot drift into a second copy.
        PaCO2_0  = RESP_CO2_ARTERIAL_RESTING
        k_hb     = BLOOD_O2_BINDING_CAPACITY
        sev_A    = BLOOD_O2_CURVE_A
        sev_B    = BLOOD_O2_CURVE_B
        a_O2     = BLOOD_O2_SOLUBILITY
        AaDO2    = BLOOD_O2_AA_GRADIENT
        FiO2     = RESP_O2_INSPIRED_FRACTION
        RER      = RESP_EXCHANGE_RATIO
        # ACID-BASE, ADR 0020. Bicarbonate is an INPUT and pH is the output - the
        # dependency inversion that record was amended into, for the reason on
        # AB.HCO3.PLASMA. All three are intensive, like everything else here.
        pK_ab    = AB_PK_APPARENT
        S_co2_pl = AB_CO2_SOLUBILITY
        HCO3     = AB_HCO3_PLASMA
        # The dry barometric pressure, PB - PH2O. RESP.ALVEOLAR.K is exactly that
        # times the STPD-to-BTPS factor, so reusing it here keeps ONE statement of
        # sea level in the ledger instead of two that can drift apart. The factor
        # is (310.15/273.15)*(760/713) = 1.21030.
        K_alv    = RESP_ALVEOLAR_K
    end

    vars = @variables begin
        PaCO2(t)        # mmHg     INPUT from respiratory
        CO(t)           # L/day    INPUT from cardiovascular
        Hct_eff(t)      # fraction INPUT from cardiovascular, ADR 0023
        Hb(t)           # g/dL     live haemoglobin, ADR 0023
        sat_rel(t)      # fraction OUTPUT to cardiovascular, ADR 0023
        PAO2(t)         # mmHg     alveolar oxygen tension
        PaO2(t)         # mmHg     arterial oxygen tension
        SaO2(t)         # fraction arterial saturation
        CaO2(t)         # mL/dL    arterial oxygen content
        DO2(t)          # mL/min   convective oxygen delivery
        VCO2_eff(t)     # L/min    INPUT from respiratory
        VO2(t)          # mL/min   whole-body oxygen consumption
        avDO2(t)        # mL/dL    arteriovenous oxygen difference
        CvO2(t)         # mL/dL    mixed venous oxygen content
        SvO2(t)         # fraction mixed venous saturation
        ER(t)           # fraction oxygen extraction ratio
        pH(t)           # -        arterial pH, ADR 0020
    end

    P_dry = K_alv / 1.21030

    # THE REFERENCE ARTERIAL SATURATION, ADR 0023, BUILT FROM PARAMETERS ONLY AND
    # THEREFORE A CONSTANT: what this person saturates to breathing air at sea
    # level with a resting alveolar PCO2.
    #
    # IT MUST BE A CONSTANT AND NOT THE PREVAILING SATURATION, and the difference
    # is the entire hypoxic response. A reference that moved with the current
    # value would keep the deficit at zero by construction and the model would
    # grow no red cells on a mountain - the one setting where this loop is traced
    # rather than perturbed once.
    #
    # NO NEW LEDGER ROW: every term is already in this component. Writing it as a
    # Julia-level expression rather than a parameter means it cannot silently
    # disagree with the equation below, which is the same reason the Severinghaus
    # P50 is solved in check_closure.py and not entered as a row.
    PAO2_0 = FiO2 * P_dry - PaCO2_0 / RER
    PaO2_0 = PAO2_0 - AaDO2
    SaO2_0 = 1.0 / (sev_A / (PaO2_0^3 + sev_B * PaO2_0) + 1.0)

    eqs = [
        # THE ALVEOLAR GAS EQUATION. Every oxygen molecule taken up is replaced in
        # the alveolus by CO2 in the ratio R, so alveolar PO2 is the inspired
        # tension less the alveolar PCO2 divided by the exchange ratio.
        #
        # THIS IS THE ONLY PLACE THE CO2 SIDE AND THE O2 SIDE MEET, through RER -
        # which is why that row's note says it should become derived the moment a
        # metabolic oxygen consumption exists.
        PAO2 ~ FiO2 * P_dry - PaCO2 / RER,

        # A single lumped difference standing for every cause: diffusion
        # limitation, shunt, and ventilation-perfusion inequality together. ADR
        # 0018 records what that collapse disqualifies - shunt fraction, dead-space
        # disease, and the multiple inert gas paradigm are no longer targets.
        PaO2 ~ PAO2 - AaDO2,

        # SEVERINGHAUS 1979 EQUATION 1, TAKEN WHOLE WITH ITS CITATION. The two
        # coefficients are not separately measurable and must move together; the
        # ledger rows say so. Branch B3 of the pre-registration - the Hill
        # decomposition was preferred and failed, because every measured P50 and
        # exponent found was in a diseased preparation.
        SaO2 ~ 1.0 / (sev_A / (PaO2^3 + sev_B * PaO2) + 1.0),

        # CONTENT. Bound plus dissolved. The dissolved term is 1.4% of the total
        # here and matters only where haemoglobin is low or PO2 is high, neither
        # of which this model represents.
        # HAEMOGLOBIN FOLLOWS RED CELL MASS. ADR 0023, and it REMOVES a parameter
        # rather than adding one: haematocrit and haemoglobin were entered from the
        # same cohort and the same stratum, and HANDOVER section 3.24 already
        # records their ratio as a check that could have failed and did not. This
        # turns that agreement from a coincidence into a structural identity.
        #
        # MCHC IS ASSUMED CONSTANT, AND THE MODEL OWN SCOPE IS WHAT JUSTIFIES IT:
        # MCHC falls in iron deficiency - hypochromia - and this model has no iron,
        # so holding it fixed is consistent with what can be represented here
        # rather than with all of haematology. Branch E5 of the pre-registration
        # would have kept haemoglobin independent had that failed.
        Hb ~ MCHC * Hct_eff,

        CaO2 ~ k_hb * Hb * SaO2 + a_O2 * PaO2,

        # THE OXYGEN SIGNAL THAT LEAVES THIS COMPONENT, AND IT IS THE FIRST
        # OUTBOUND EDGE BLOOD HAS EVER HAD. ADR 0018 made this a forward
        # computation deliberately and left a tripwire in this file: if an outbound
        # edge ever appears here it means an oxygen feedback has been built and
        # needs its own record. This is that edge and ADR 0023 is that record.
        #
        # IT IS SATURATION AND NOT CONTENT, AND THAT IS A CORRECTION THE TEST SUITE
        # FORCED. erythropoiesis_prereg.md section 4 pre-registered arterial
        # CONTENT as the sensed signal. Content was wrong, the salt step caught it,
        # and the reason is written out in full on the deficit equation in
        # Cardiovascular.jl where the two halves are combined. In short: content is
        # a CONCENTRATION, it falls when plasma expands, and a concentration-keyed
        # loop grows red cells on a salt load - which is HANDOVER section 3.8's
        # already-corrected defect returning through a different door.
        #
        # So this component exports the part of the oxygen signal it actually owns
        # - how well the haemoglobin present is saturated - and the cardiovascular
        # side supplies how much of it there is. Splitting it here is not a dodge:
        # ADR 0018 already records that oxygen DELIVERY is the first quantity in
        # this model needing two subsystems at once, and this is the same seam.
        #
        # SIGN, ASSERTED RATHER THAN ASSUMED: saturation BELOW reference gives
        # sat_rel < 1 and RAISES production. Getting this backwards would produce a
        # perfectly plausible curve in which oxygen therapy stimulates
        # erythropoiesis, and the ADR 0009 addendum records the vasomotor arm
        # shipping sign-inverted once already.
        sat_rel ~ SaO2 / SaO2_0,

        # CONVECTIVE DELIVERY, and the first quantity in this model that needs two
        # subsystems at once.
        #
        # THE UNIT CHAIN IS WRITTEN OUT BECAUSE IT IS WHERE THIS WOULD SILENTLY GO
        # WRONG. Cardiovascular.jl carries CO in L/DAY - the model's time base is
        # days throughout - while oxygen content is per dL and delivery is
        # conventionally reported per minute. So:
        #
        #     CO [L/day] * 1000/1440  -> mL/min of blood
        #     CaO2 [mL O2/dL] / 100   -> mL O2 per mL of blood
        #
        # Getting this wrong by the 1440 would put delivery out by three orders of
        # magnitude and still look like a plausible number in some other unit,
        # which is exactly the class of error a closure check exists for.
        DO2 ~ CO * (1000.0 / 1440.0) * CaO2 / 100.0,

        # OXYGEN CONSUMPTION, AND IT NEEDED NO NEW SOURCE. ADR 0018 deferred the
        # Fick relation because "they need tissue oxygen consumption, which is a
        # metabolic row this model does not have". It does: the respiratory
        # component's CO2 production, divided by the exchange ratio that already
        # links the two sides of the alveolus. Both rows were already in the
        # ledger and neither moves.
        #
        # SO RER CANNOT LATER BECOME DERIVED FROM VO2 AND VCO2. The comment on the
        # alveolar gas equation above says it should the moment an oxygen
        # consumption exists; that is now wrong and is corrected here, because VO2
        # is derived THROUGH RER. It stays a primitive.
        VO2 ~ VCO2_eff * 1000.0 / RER,

        # THE FICK RELATION, REARRANGED. Fick measures cardiac output from oxygen
        # uptake and the arteriovenous difference; here cardiac output and content
        # are already determined by the pressure loop, so the same identity gives
        # the difference. It is a conservation law either way.
        #
        #   VO2 [mL/min] / (CO [mL/min]) -> mL O2 per mL blood, x100 -> per dL
        avDO2 ~ VO2 / (CO * (1000.0 / 1440.0)) * 100.0,

        CvO2 ~ CaO2 - avDO2,

        # MIXED VENOUS SATURATION, ATTRIBUTING ALL VENOUS OXYGEN TO HAEMOGLOBIN.
        # The dissolved term is omitted here where the arterial content includes
        # it, which OVERSTATES SvO2 by about 0.6 percentage points at rest -
        # smaller than the alveolar-arterial difference's own uncertainty and far
        # smaller than any measurement of SvO2. Including it would need the
        # inverse dissociation curve, which is four more coefficients taken whole
        # for a correction below the noise.
        SvO2 ~ CvO2 / (k_hb * Hb),

        # EXTRACTION RATIO. Identically avDO2/CaO2, which is VO2/DO2 with the unit
        # chains cancelled - written the short way so there is nothing to get
        # wrong twice.
        ER ~ avDO2 / CaO2,

        # ARTERIAL pH, HENDERSON-HASSELBALCH. ADR 0020, and it lives here rather
        # than in an eleventh component because everything it needs is already in
        # this one: arterial PCO2 arrives from respiratory, and the other three
        # terms are constants.
        #
        # IT IS A COMPOSITION OF THREE INDEPENDENT MEASUREMENTS AND CAN THEREFORE
        # BE WRONG, which is what makes it a test rather than a restatement: an
        # apparent pK measured by titration, a solubility measured by
        # tonometry, a bicarbonate measured in 8809 adults, and a PCO2 sourced
        # under ADR 0017. All four are on scales that compose - a millimole is a
        # millimole - unlike the free-thyroxine assays of HANDOVER section 3.26.
        #
        # IT COMES OUT AT 7.42 AGAINST A HUMAN ARTERIAL 7.40, and the residual is
        # NOT closed. AB.HCO3.PLASMA is a VENOUS serum TOTAL CO2, which runs 1 to
        # 2 mmol/L above arterial bicarbonate; subtracting 1 gives 7.402.
        # Applying that correction would set the parameter from the quantity being
        # tested, so it is reported instead. See that row.
        pH ~ pK_ab + log10(HCO3 / (S_co2_pl * PaCO2)),
    ]

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    blood_couplings()

TWO INBOUND EDGES AND, SINCE 2026-09-16, ONE OUTBOUND. The inbound pair are
Mechanical: gas tensions equilibrate and blood is convected, neither with a lag at
this resolution.

THE OUTBOUND EDGE IS ADR 0023, AND THIS DOCSTRING PREDICTED IT. It used to say
that if an outbound edge ever appeared here it meant an oxygen feedback had been
built and needed its own record. It has, and it does: arterial saturation below
its reference drives red cell production. It is the first time anything in this
model reads an oxygen number and acts on it.
"""
function blood_couplings()
    return [
        Coupling(:respiratory, :blood, Mechanical,
                 note = "alveolar PCO2 sets alveolar PO2 through the exchange ratio"),
        Coupling(:cardiovascular, :blood, Mechanical,
                 note = "cardiac output convects arterial oxygen content, and the live haematocrit sets haemoglobin"),
        # THE TRIPWIRE THIS FILE LEFT ITSELF, TRIPPED ON PURPOSE. ADR 0023.
        #
        # NEUROHUMORAL, AND THE TIME CONSTANT IS THE POINT RATHER THAN A FORMALITY.
        # tau here is RBC.RECOVERY_TAU = 24 days, which is the slowest lag in this
        # model by two orders of magnitude - the thyroid axis is next at about 7
        # days and everything else is hours. So this edge is emphatically SAFE TO
        # PARTITION ACROSS, which is what the Neurohumoral classification buys and
        # why validate_partition wants the number.
        #
        # The lag is carried by V_rbc itself rather than by a separate signal
        # state: there is no erythropoietin here, and the pre-registration section
        # 5 refused a maturation delay on top because its time constant would be
        # identified by nothing - the debt RN.ANP.TAU already carries.
        Coupling(:blood, :cardiovascular, Neurohumoral,
                 tau_seconds = 24.0 * 86400.0,
                 gain_param = :RBC_PRODUCTION_GAIN,
                 note = "arterial saturation below its reference drives red cell production"),
    ]
end
