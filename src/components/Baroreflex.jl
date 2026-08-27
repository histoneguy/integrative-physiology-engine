"""
Arterial baroreflex - LUMPED, cycle-averaged.

STRUCTURE SOURCES
  Baroreflex controls arterial pressure primarily via reflex changes in vascular
    resistance rather than cardiac output:
    Dampney RAL. Resetting of the baroreflex control of sympathetic vasomotor
    activity during natural behaviors. Front Physiol 2017. PMC5559464.
  Sympathetic vasomotor delay 2-3 s; parasympathetic 200-600 ms:
    La Rovere MT et al. Ann Noninvasive Electrocardiol 2008;13(2):191-207.
  Open-loop gain 1.0-3.5 (animal, vascularly isolated baroreceptors):
    Yamasaki F et al. Front Neurosci 2021;15:707345.

EVIDENCE (ADR 0006)
  E1  The reflex exists, is fast, and acts mainly through vascular resistance.
  E1  The reflex RESETS over hours to days.
  --  Open-loop gain is ANIMAL-derived; human value is explicitly unclarified.
  --  Reset time constant is ASSUMED.

WHY THE ARMS ARE LUMPED
The vagal arm acts on heart rate in 200-600 ms; the sympathetic arm acts on
vascular tone in 2-3 s. This model is cycle-averaged (ADR 0002), so heart rate is
not a state and the vagal arm has nothing to act on. One lumped lag on TPR is the
honest representation at this resolution. Separating them buys nothing until
heart rate exists.

WHY RESETTING IS THE POINT
The baroreflex re-centres on prevailing pressure over hours to days. It is
therefore a FAST BUFFER, not a long-term regulator - which is exactly why
renal-body fluid feedback has to set long-run pressure (ADR 0007).

This is a falsifiable structural commitment: adding this component MUST NOT change
the 60-day salt-step steady state. If it does, the reflex is wrongly acting as a
long-term regulator and either the reset path or the gain is wrong.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams:
    BR_OPEN_LOOP_GAIN, BR_EFFECTOR_TAU, BR_RESET_TAU, BR_TPR_MAX_FRACTION,
    CV_MAP_SETPOINT

"""
    Baroreflex(; name, enabled = true)

Lumped baroreflex acting on total peripheral resistance.

Inputs   MAP (mmHg)
Outputs  tpr_mod (unitless) - multiplicative modifier, 1.0 = no reflex action

Two states:
  `sp`      the reflex setpoint, which RESETS toward prevailing pressure
  `tpr_mod` the effector output, a first-order lag on the pressure error

Time base is DAYS. The effector tau (3 s) is roughly 1e-5 days against horizons of
tens of days - a stiffness ratio near 1e6, which is precisely the regime the
adaptive stiff solver of ADR 0001 exists for.

`enabled = false` fixes tpr_mod at 1.0, for the regression test that the reflex
does not alter long-run pressure.
"""
function Baroreflex(; name, enabled::Bool = true)

    pars = @parameters begin
        G_br      = BR_OPEN_LOOP_GAIN
        tau_br    = BR_EFFECTOR_TAU / 86400.0      # s -> day
        tau_reset = BR_RESET_TAU                   # already days
        sat       = BR_TPR_MAX_FRACTION
        MAP_ref   = CV_MAP_SETPOINT
    end

    vars = @variables begin
        MAP(t)                          # mmHg  INPUT from cardiovascular
        sp(t)      = CV_MAP_SETPOINT    # mmHg  resetting setpoint  (STATE)
        cv_mod(t)                       # unitless INPUT from circadian clock
        tpr_mod(t) = 1.0                # unitless multiplier       (STATE)
        err(t)                          # mmHg
        drive(t)                        # unitless, saturated
    end

    eqs = if enabled
        [
            # cv_mod is the circadian modulation of the reflex setpoint
            # (1.0 = no rhythm). Scaling the SETPOINT rather than adding to
            # MAP keeps the reflex a comparator: the clock moves what the
            # reflex defends, which is what a central circadian influence on
            # blood pressure means.
            err ~ MAP - sp * cv_mod,

            # Saturating characteristic. The real reflex is sigmoidal; tanh gives
            # the right shape with the right slope at the operating point and
            # cannot drive TPR negative under large excursions.
            #
            # THE SIGN IS NEGATIVE AND THAT IS THE WHOLE REFLEX. A rise in
            # pressure stretches the baroreceptors, RAISES afferent firing, and
            # INHIBITS sympathetic vasomotor outflow — so TPR falls. Positive
            # here makes the loop regenerative: closed-loop gain is G_br = 2.0,
            # which is unconditionally unstable, runs away to the tanh
            # saturation bound, and then bounces off the other branch as `sp`
            # resets. That was the state merged in PR #6 and it produced a
            # 40 mmHg mean arterial pressure. See the addendum to ADR 0009.
            drive ~ -sat * tanh(G_br * err / (sat * MAP_ref)),

            # Effector lag: 2-3 s sympathetic vasomotor response.
            D(tpr_mod) ~ ((1 + drive) - tpr_mod) / tau_br,

            # RESETTING. The setpoint drifts toward prevailing pressure over
            # hours to days. At steady state sp -> MAP, err -> 0, tpr_mod -> 1,
            # and the reflex exerts NO long-run influence. This single equation
            # is what keeps the baroreflex a buffer rather than a regulator.
            D(sp) ~ (MAP - sp) / tau_reset,
        ]
    else
        [err ~ 0.0, drive ~ 0.0, D(tpr_mod) ~ 0.0, D(sp) ~ 0.0]
    end

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    baroreflex_couplings()

Inbound pressure sensing is Mechanical - baroreceptors respond to wall stretch with
no meaningful lag at this resolution. The outbound effector path is Neurohumoral
with a 3 s time constant, so per ADR 0003 a multirate partition may cut across it.
"""
function baroreflex_couplings()
    return [
        Coupling(:cardiovascular, :baroreflex, Mechanical,
                 note = "MAP sensed by arterial baroreceptors; wall stretch, no lag"),
        Coupling(:baroreflex, :cardiovascular, Neurohumoral;
                 tau_seconds = BR_EFFECTOR_TAU,
                 gain_param = :BR_OPEN_LOOP_GAIN,
                 note = "sympathetic vasomotor outflow to TPR; 2-3 s effector delay"),
    ]
end
