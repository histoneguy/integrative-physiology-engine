"""
Cardiovascular mechanics - MINIMAL.

STRUCTURE SOURCES
  MAP = CO x TPR: definitional.
  Venous return / Frank-Starling dependence of cardiac output on filling:
    Guyton AC, Coleman TG, Granger HJ. Annu Rev Physiol 1972;34:13-46.

EVIDENCE (ADR 0006)
  E1  MAP = CO x TPR. Definitional.
  E1  Cardiac output rises with venous return, which rises with blood volume.
  --  The linearised SENSITIVITY of CO to blood volume is CALIBRATED. See ledger.

STRUCTURE (ADR 0012)
  Blood volume is partitioned into a central (intrathoracic) and a peripheral
  compartment, and cardiac output is keyed to CENTRAL filling. At stage 1 the
  central fraction is constant, so the partition is a change of variables and
  every result is bit-identical - see the note on the CO equation.

STRUCTURE (ADR 0011)
  Cardiac output is HEART RATE x STROKE VOLUME. Heart rate is a parameter,
  not a state, until a chronotropic baroreflex exists. Stroke volume carries
  the filling dependence and is the quantity reconstruct.jl has needed since
  the repository began.

WHAT THIS DELIBERATELY OMITS
  Contractility, arterial and venous compliance as states, regional flows,
  and the circadian modulation in ADR 0005.

  Splanchnic and limb capacitance are ONE peripheral compartment and cannot be
  told apart. Per ADR 0012 that disqualifies any paradigm which dissociates them
  from calibrating the partition.

  TPR is no longer a constant - the baroreflex scales it (ADR 0009). RAAS will
  scale it further when it lands, multiplicatively on the same tpr_mod path.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams
using ..LedgerParams:
    CV_CO_NOMINAL, CV_TPR_NOMINAL,
    CV_HEMATOCRIT_NOMINAL, CV_VENOUS_RETURN_SENSITIVITY,
    CV_CENTRAL_FRACTION, CV_CENTRAL_CO_SENSITIVITY,
    BF_BODY_MASS_REFERENCE

"""
    Cardiovascular(; name)

Blood volume from extracellular fluid, cardiac output from blood volume, pressure
from cardiac output.

Inputs   V_ecf (L)
Outputs  MAP (mmHg), CO (L/day), V_blood (L)

MAP is an OUTPUT of the closed loop, not a setpoint. Nothing in this component
regulates it. Its stability comes entirely from renal pressure natriuresis acting
through fluid volume - which is the central claim of the Guyton formulation and is
what this minimal model exists to demonstrate.
"""
function Cardiovascular(; name, sex::Symbol = :male,
                        body_mass = BF_BODY_MASS_REFERENCE)

    sz = size_factor(body_mass)

    pars = @parameters begin
        # EXTENSIVE: a flow and two volumes.
        CO0    = sz * CV_CO_NOMINAL
        # SEXED as of 2026-08-27 (Oberholzer 2024, CO rebreathing): 80.3 mL/kg in
        # men, 70.3 in women. f_pv and VC0 are DERIVED from it and are sexed with
        # it, so all three go through the ADR 0014 accessor.
        BV0    = sz * LedgerParams.param(:CV_BLOOD_VOLUME_NOMINAL, sex)
        # TPR CARRIES THE RECIPROCAL, and this is the line that keeps arterial
        # pressure intensive. MAP = CO*TPR, CO ~ s, so TPR ~ 1/s or big people
        # would be hypertensive. Physically that is right: resistance falls as
        # the vascular bed gets larger. See src/scaling.jl.
        TPR0   = CV_TPR_NOMINAL / sz               # baseline; scaled by reflex
        # Resolved through the sex-aware accessor rather than read as a bare
        # constant. While CV.HEMATOCRIT.NOMINAL carries a single `both` row this
        # returns that value for either sex; the moment a male/female pair is
        # entered it starts returning the right one, with no change here.
        Hct    = LedgerParams.param(:CV_HEMATOCRIT_NOMINAL, sex)
        f_pv   = LedgerParams.param(:CV_PLASMA_ECF_FRACTION, sex)   # DERIVED from BV0
        G_vr   = CV_VENOUS_RETURN_SENSITIVITY      # CALIBRATED - see ledger
        f_c    = CV_CENTRAL_FRACTION               # PLACEHOLDER - cancels, see below
        VC0    = sz * LedgerParams.param(:CV_CENTRAL_VOLUME_NOMINAL, sex)  # = f_c*BV0
        # G_vc is dCO/dV_central. Both numerator and denominator are extensive,
        # so the SENSITIVITY is intensive and must NOT scale.
        G_vc   = CV_CENTRAL_CO_SENSITIVITY         # DERIVED = G_vr / f_c
        # HR is INTENSIVE - resting heart rate does not track body mass in
        # adults - so stroke volume carries the whole of the cardiac scaling.
        HR0    = LedgerParams.param(:CV_HR_NOMINAL, sex)   # 1/min, SEX-SPECIFIC
        SV0    = sz * LedgerParams.param(:CV_SV_NOMINAL, sex)   # mL, EXTENSIVE
    end

    vars = @variables begin
        # All algebraic - no defaults. V_ecf arrives by connection; the rest
        # follow from it. Defaults here would overdetermine initialization.
        V_ecf(t)        # L        INPUT from body fluids
        tpr_mod(t)      # unitless INPUT from baroreflex (1.0 = no reflex action)
        V_plasma(t)     # L
        V_blood(t)      # L
        V_central(t)    # L        intrathoracic; the filling variable (ADR 0012)
        V_periph(t)     # L        everything else; V_central + V_periph = V_blood
        SV(t)           # mL       stroke volume (ADR 0011)
        CO(t)           # L/day
        TPR(t)          # mmHg/(L/day)
        MAP(t)          # mmHg     OUTPUT
    end

    eqs = [
        V_plasma ~ f_pv * V_ecf,
        V_blood  ~ V_plasma / (1 - Hct),

        # ADR 0012 stage 1: the central/peripheral partition. f_c is constant in
        # time, so this is a CHANGE OF VARIABLES and nothing else. VC0 = f_c*BV0
        # and G_vc = G_vr/f_c are both derived from f_c, so
        #
        #     G_vc * (V_central - VC0) == G_vr * (V_blood - BV0)
        #
        # identically, for any f_c. Every result is bit-identical to the version
        # before the partition existed, which is ADR 0012 falsifiable test 3 and
        # is asserted in the test suite. The point of stage 1 is not to change a
        # number - it is that V_central EXISTS, so that a natriuretic term and
        # the cardiopulmonary receptors have a variable with a receptor behind it,
        # and so that immersion is expressible as a different constant f_c at
        # unchanged V_blood. Stage 2 makes f_c posture-dependent, at which point
        # it stops cancelling and MUST be sourced first.
        V_central ~ f_c * V_blood,
        V_periph  ~ V_blood - V_central,

        # ADR 0011: CARDIAC OUTPUT IS HEART RATE TIMES STROKE VOLUME.
        #
        # Stroke volume carries the filling dependence; heart rate is a parameter
        # until a chronotropic baroreflex exists (ADR 0009 gives the reflex one
        # effector, tpr_mod, and a second is its own decision).
        #
        # G_vc is a sensitivity of CO to central volume in (L/day)/L, so dividing
        # by beats per day converts it to a stroke-volume sensitivity, and the
        # 1000 puts SV in mL. Written this way the identity
        #
        #     HR0 * 1440 * SV == CO0 + G_vc * (V_central - VC0)
        #
        # holds exactly, so this is a CHANGE OF VARIABLES like ADR 0012 stage 1
        # and moves nothing. What it buys is that HR and SV EXIST: separately
        # measurable in humans where G_vr never was, a stroke volume for
        # reconstruct.jl which has taken one as an argument since the repo began,
        # and the variable a chronotropic reflex will act on.
        #
        # SEX ENTERS HERE AND CURRENTLY CANCELS. HR0 and SV0 are a male/female
        # pair, but SV0 is DERIVED as CO0/(HR0*1440) and CO0 is shared, so their
        # product is CO0 for either sex and the model does not move. That is not a
        # failure of the wiring - it is what it means for cardiac output to have
        # no sex-specific row yet. Katori 1979 found no sex difference in cardiac
        # INDEX or stroke INDEX once normalised to body surface area, so the real
        # dimorphism is body size, and body_mass is still a hard-coded 70.0.
        SV  ~ max(0.0, SV0 + (G_vc / (HR0 * 1440.0)) * (V_central - VC0) * 1000.0),
        CO  ~ HR0 * 1440.0 * SV / 1000.0,

        # TPR is now a STATE-DEPENDENT quantity, scaled by baroreflex outflow.
        # It was a constant until the baroreflex landed; tpr_mod = 1.0 recovers
        # the previous behaviour exactly.
        TPR ~ TPR0 * tpr_mod,

        MAP ~ CO * TPR,
    ]

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    cardiovascular_couplings()

All Mechanical: volume to filling to output to pressure is a hydraulic chain with
no lag at this resolution. Per ADR 0003 no partition may cut across any of it.
"""
function cardiovascular_couplings()
    return [
        Coupling(:bodyfluids, :cardiovascular, Mechanical,
                 note = "V_ecf -> plasma -> blood volume -> venous return"),
        Coupling(:cardiovascular, :renal, Mechanical,
                 note = "MAP drives filtration and pressure natriuresis"),
        # DECLARED 2026-08-27. This edge exists in assemble.jl as
        # `bf.MAP ~ cv.MAP` and was declared nowhere, so the declared graph and
        # the built model disagreed. It is currently INERT: BodyFluids takes MAP
        # as an input and no equation there consumes it, so structural_simplify
        # removes it. It is the hook ADR 0010 needs for a volume-natriuresis /
        # ANP path. Declared rather than deleted so the two graphs match, and
        # recorded as Mechanical, which means the partition rule forbids cutting
        # across it - a precautionary constraint until something reads bf.MAP.
        Coupling(:cardiovascular, :bodyfluids, Mechanical,
                 note = "MAP to body fluids; INERT - no equation consumes bf.MAP " *
                        "yet. ADR 0010 ANP hook."),
    ]
end
