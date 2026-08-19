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

WHAT THIS DELIBERATELY OMITS
  Heart rate, contractility, arterial and venous compliance as states, regional
  flows, and the circadian modulation in ADR 0005.

  TPR is no longer a constant - the baroreflex scales it (ADR 0009). RAAS will
  scale it further when it lands, multiplicatively on the same tpr_mod path.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams:
    CV_CO_NOMINAL, CV_TPR_NOMINAL, CV_BLOOD_VOLUME_NOMINAL,
    CV_HEMATOCRIT_NOMINAL, CV_PLASMA_ECF_FRACTION, CV_VENOUS_RETURN_SENSITIVITY

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
    end

    vars = @variables begin
        # All algebraic - no defaults. V_ecf arrives by connection; the rest
        # follow from it. Defaults here would overdetermine initialization.
        V_ecf(t)        # L        INPUT from body fluids
        tpr_mod(t)      # unitless INPUT from baroreflex (1.0 = no reflex action)
        V_plasma(t)     # L
        V_blood(t)      # L
        CO(t)           # L/day
        TPR(t)          # mmHg/(L/day)
        MAP(t)          # mmHg     OUTPUT
    end

    eqs = [
        V_plasma ~ f_pv * V_ecf,
        V_blood  ~ V_plasma / (1 - Hct),

        # Linearised venous return: cardiac output rises with blood volume above
        # the unstressed operating point. G_vr is a fitted constant, not a
        # measurement - the Frank-Starling relationship it linearises is E1, the
        # slope is not.
        CO  ~ max(0.0, CO0 + G_vr * (V_blood - BV0)),

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
