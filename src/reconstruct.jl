"""
Within-cycle reconstruction.

The model is cycle-averaged (ADR 0002). Systolic and diastolic pressure are NOT
state variables - the cardiac cycle they live inside has been averaged away. They are
reconstructed algebraically here.

READ THIS BEFORE USING THE OUTPUT: these are approximations with their own error.
They must be validated separately against measured pulse-pressure data, and must
never be reported as directly simulated quantities. Any figure showing systolic or
diastolic pressure from this model must say it is reconstructed.

STRUCTURE SOURCES: none yet. The two-element Windkessel relation below is generic and
is a PLACEHOLDER. Real implementation cites its literature here and every constant
enters via the ledger.
"""

"""
    pulse_pressure(SV, C_art)

Pulse pressure from stroke volume and arterial compliance - the crudest useful
reconstruction (PP = SV / C).

Ignores wave reflection, ejection duration, and the pressure-dependence of compliance.
Adequate for order-of-magnitude checks, NOT adequate for any claim about pulse
pressure as an endpoint. Replace before validating against PP data.
"""
pulse_pressure(SV, C_art) = SV / C_art

"""
    systolic_diastolic(MAP, SV, C_art; form_factor = 0.4)

Split mean arterial pressure into systolic and diastolic using a reconstructed pulse
pressure and an assumed form factor.

`form_factor` is the fraction of pulse pressure lying above MAP. The conventional
value near 0.4 corresponds to the familiar MAP ~ DBP + PP/3, and it is NOT constant -
it varies with heart rate, arterial stiffness, and disease state. Treating it as
constant is the single largest error source in this reconstruction.

TODO: ledger entry required for `form_factor` with extraction_method = assumed and
written justification, before this is used for anything.
"""
function systolic_diastolic(MAP, SV, C_art; form_factor = 0.4)
    PP  = pulse_pressure(SV, C_art)
    SBP = MAP + form_factor * PP
    DBP = MAP - (1 - form_factor) * PP
    return (systolic = SBP, diastolic = DBP, pulse = PP)
end

"""
    RECONSTRUCTED

Names of quantities that are reconstructed rather than simulated. Anything drawn from
this set must be labelled as such wherever it is plotted or reported.
"""
const RECONSTRUCTED = Set([:systolic, :diastolic, :pulse])
