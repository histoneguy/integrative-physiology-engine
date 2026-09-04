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
    RESP_O2_INSPIRED_FRACTION, RESP_EXCHANGE_RATIO, RESP_ALVEOLAR_K

"""
    Blood(; name, sex = :male)

Arterial oxygen tension, saturation, content and convective delivery.

Inputs   PaCO2 (mmHg) from respiratory, CO (L/day) from cardiovascular
Outputs  PaO2, SaO2, CaO2, DO2 - all observables, nothing feeds back

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
        Hb       = LedgerParams.param(:BLOOD_HB_CONCENTRATION, sex)
        k_hb     = BLOOD_O2_BINDING_CAPACITY
        sev_A    = BLOOD_O2_CURVE_A
        sev_B    = BLOOD_O2_CURVE_B
        a_O2     = BLOOD_O2_SOLUBILITY
        AaDO2    = BLOOD_O2_AA_GRADIENT
        FiO2     = RESP_O2_INSPIRED_FRACTION
        RER      = RESP_EXCHANGE_RATIO
        # The dry barometric pressure, PB - PH2O. RESP.ALVEOLAR.K is exactly that
        # times the STPD-to-BTPS factor, so reusing it here keeps ONE statement of
        # sea level in the ledger instead of two that can drift apart. The factor
        # is (310.15/273.15)*(760/713) = 1.21030.
        K_alv    = RESP_ALVEOLAR_K
    end

    vars = @variables begin
        PaCO2(t)        # mmHg     INPUT from respiratory
        CO(t)           # L/day    INPUT from cardiovascular
        PAO2(t)         # mmHg     alveolar oxygen tension
        PaO2(t)         # mmHg     arterial oxygen tension
        SaO2(t)         # fraction arterial saturation
        CaO2(t)         # mL/dL    arterial oxygen content
        DO2(t)          # mL/min   convective oxygen delivery
    end

    P_dry = K_alv / 1.21030

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
        CaO2 ~ k_hb * Hb * SaO2 + a_O2 * PaO2,

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
    ]

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    blood_couplings()

TWO INBOUND EDGES AND NO OUTBOUND ONE, which is what a forward computation looks
like in the coupling graph. Both are Mechanical: gas tensions equilibrate and
blood is convected, neither with a lag at this resolution.

If an outbound edge ever appears here it means an oxygen feedback has been built,
and ADR 0018 says that needs its own record.
"""
function blood_couplings()
    return [
        Coupling(:respiratory, :blood, Mechanical,
                 note = "alveolar PCO2 sets alveolar PO2 through the exchange ratio"),
        Coupling(:cardiovascular, :blood, Mechanical,
                 note = "cardiac output convects arterial oxygen content"),
    ]
end
