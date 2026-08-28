"""
Within-cycle reconstruction.

The model is cycle-averaged (ADR 0002). Systolic and diastolic pressure are NOT
state variables - the cardiac cycle they live inside has been averaged away. They are
reconstructed algebraically here.

READ THIS BEFORE USING THE OUTPUT: these are approximations with their own error.
They must be validated separately against measured pulse-pressure data, and must
never be reported as directly simulated quantities. Any figure showing systolic or
diastolic pressure from this model must say it is reconstructed.

CONNECTED 2026-08-27. This file sat in the repo unused from the beginning - included
by IPE.jl, called by nothing, tested by nothing - because it took `SV` and `C_art` as
arguments and neither existed. ADR 0011 created `SV`; the sourcing pass behind
CV.MAP.SETPOINT created `C_art` and the central pressure references. Both now come
from the ledger and nothing here is hardcoded.

DELIBERATELY NOT PART OF THE ODE SYSTEM. Making SBP and DBP observed variables of the
compiled model would put them in the same namespace as genuinely simulated states,
which is precisely what the warning above exists to prevent - every downstream
consumer would lose the distinction. They stay functions of a solved trajectory, and
`RECONSTRUCTED` names them so callers can label them.

THE CONVENTION, WHICH IS WHERE THE BODIES ARE BURIED. `k_below` is the fraction of
pulse pressure lying BELOW mean pressure:

    MAP = DBP + k_below * PP          so   DBP = MAP - k_below * PP
                                      and  SBP = MAP + (1 - k_below) * PP

`k_below` MUST BE LESS THAN 0.5. Diastole is longer than systole, so the time-weighted
mean sits nearer diastolic than systolic. The ledger row CV.PULSE.FORM_FACTOR carries
0.3333 - the conventional MAP = DBP + PP/3 - and it was NAMED as the fraction lying
*above* the mean until 2026-08-27, which is the opposite quantity (0.667). An earlier
version of this file compounded that by defining its `form_factor` as the fraction
above and computing `SBP = MAP + form_factor * PP` with a hardcoded default of 0.4.
Connecting the two under the shared word "form factor" would have returned SBP 98.0 /
DBP 65.0 against the sourced 109 / 76 - each wrong by PP/3 = 11 mmHg, in opposite
directions - and `check_closure.py` would still have passed, because it uses the row
correctly as MAP = DBP + k*PP and never reaches this file. Hence `k_below`: the name
now carries the convention, so the two cannot be silently transposed again.

STRUCTURE SOURCES. `PP = SV / C_art` is the two-element Windkessel estimator, the form
Chemla 1998 validated; `C_art` enters from the ledger where that citation lives. The
fixed form factor is NOT sourced - CV.PULSE.FORM_FACTOR is `assumed`, tier C - and
reconstruct treats it as constant, which is the single largest error source here.
Wave reflection, ejection duration and the pressure-dependence of compliance are all
ignored. Adequate for an operating point; NOT adequate for any claim about pulse
pressure as an endpoint.
"""

"""
    pulse_pressure(SV, C_art)

Pulse pressure from stroke volume and arterial compliance, `PP = SV / C_art`.

`SV` in mL and `C_art` in mL/mmHg give `PP` in mmHg. Ignores wave reflection,
ejection duration, and the pressure-dependence of compliance.
"""
pulse_pressure(SV, C_art) = SV / C_art

"""
    systolic_diastolic(MAP, SV, C_art, k_below)

Split mean arterial pressure into systolic and diastolic using a reconstructed pulse
pressure.

`k_below` is the fraction of pulse pressure lying BELOW the mean - see the convention
note at the top of this file. It has no default ON PURPOSE: the previous default of
0.4 was both unsourced and of the opposite convention to the ledger row that now
supplies it. Callers who want the ledger value should use `reconstruct_pressures`.

Errors if `k_below >= 0.5`, which is physiologically impossible while diastole is
longer than systole, and is the signature of a transposed convention or of a mean and
a pulse pressure measured at different sites.
"""
function systolic_diastolic(MAP, SV, C_art, k_below)
    0.0 < k_below < 0.5 || error(
        "k_below = $k_below is not in (0, 0.5). It is the fraction of pulse " *
        "pressure BELOW the mean, which cannot reach half while diastole is " *
        "longer than systole. A value at or above 0.5 means the convention has " *
        "been transposed, or that a mean and a pulse pressure from different " *
        "measurement sites have been mixed - which is exactly how the brachial " *
        "MAP of 93 mmHg was caught on 2026-08-27, at 0.515.")
    PP  = pulse_pressure(SV, C_art)
    DBP = MAP - k_below * PP
    SBP = MAP + (1.0 - k_below) * PP
    return (systolic = SBP, diastolic = DBP, pulse = PP)
end

"""
    reconstruct_pressures(MAP, SV; sex)

Systolic, diastolic and pulse pressure from a solved mean pressure and stroke volume,
taking arterial compliance and the form factor from the ledger.

`sex` is REQUIRED and has no default. `CV.ARTERIAL.COMPLIANCE` is a male/female pair
(2.445 and 2.333 mL/mmHg), so ADR 0014 makes `:both` an error rather than an average.
That is the correct behaviour and not an inconvenience to work around: an arterial
compliance describing no one would propagate straight into a reported blood pressure.

Returns a NamedTuple `(systolic, diastolic, pulse)` in mmHg. Every field is
RECONSTRUCTED, not simulated - see `RECONSTRUCTED` and label accordingly.
"""
function reconstruct_pressures(MAP, SV; sex::Symbol)
    C_art   = LedgerParams.param(:CV_ARTERIAL_COMPLIANCE, sex)
    k_below = LedgerParams.param(:CV_PULSE_FORM_FACTOR)
    return systolic_diastolic(MAP, SV, C_art, k_below)
end

"""
    RECONSTRUCTED

Names of quantities that are reconstructed rather than simulated. Anything drawn from
this set must be labelled as such wherever it is plotted or reported.
"""
const RECONSTRUCTED = Set([:systolic, :diastolic, :pulse])
