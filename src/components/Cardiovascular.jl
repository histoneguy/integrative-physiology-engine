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

WHAT THIS DELIBERATELY OMITS
  Heart rate, contractility, arterial and venous compliance as states, regional
  flows, and the circadian modulation in ADR 0005.

  Splanchnic and limb capacitance are ONE peripheral compartment and cannot be
  told apart. Per ADR 0012 that disqualifies any paradigm which dissociates them
  from calibrating the partition.

  TPR is no longer a constant - the baroreflex scales it (ADR 0009). RAAS will
  scale it further when it lands, multiplicatively on the same tpr_mod path.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams:
    CV_CO_NOMINAL, CV_TPR_NOMINAL, CV_BLOOD_VOLUME_NOMINAL,
    CV_HEMATOCRIT_NOMINAL, CV_PLASMA_ECF_FRACTION, CV_VENOUS_RETURN_SENSITIVITY,
    CV_CENTRAL_FRACTION, CV_CENTRAL_VOLUME_NOMINAL, CV_CENTRAL_CO_SENSITIVITY

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
function Cardiovascular(; name)

    pars = @parameters begin
        CO0    = CV_CO_NOMINAL
        TPR0   = CV_TPR_NOMINAL                    # baseline; scaled by reflex
        BV0    = CV_BLOOD_VOLUME_NOMINAL
        Hct    = CV_HEMATOCRIT_NOMINAL
        f_pv   = CV_PLASMA_ECF_FRACTION
        G_vr   = CV_VENOUS_RETURN_SENSITIVITY      # CALIBRATED - see ledger
        f_c    = CV_CENTRAL_FRACTION               # PLACEHOLDER - cancels, see below
        VC0    = CV_CENTRAL_VOLUME_NOMINAL         # DERIVED = f_c * BV0
        G_vc   = CV_CENTRAL_CO_SENSITIVITY         # DERIVED = G_vr / f_c
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

        # Linearised venous return, now keyed to central filling. G_vr is a
        # fitted constant, not a measurement - the Frank-Starling relationship it
        # linearises is E1, the slope is not. ADR 0012 additionally requires this
        # relation to be CONCAVE, not linear, before the posture gradient can be
        # reproduced; that is stage 2 work and this line is still linear.
        CO  ~ max(0.0, CO0 + G_vc * (V_central - VC0)),

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
    ]
end
