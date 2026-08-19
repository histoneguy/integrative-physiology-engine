# ADR 0009: Baroreflex — lumped, resetting, buffer not regulator

**Status:** Accepted
**Evidence tier:** MIXED — see table (E1 structure, animal-derived gain)
**Date:** 2026-08-19

## Context

TPR was a constant. The model had no fast pressure control at all — every
disturbance had to be absorbed through fluid volume, which acts over days.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| Baroreflex controls AP primarily via vascular resistance, not cardiac output | E1 | Dampney, Front Physiol 2017, PMC5559464 | mammal incl. human |
| Sympathetic vasomotor effector delay 2–3 s | E1 | La Rovere, Ann Noninvasive Electrocardiol 2008;13:191 | human |
| Parasympathetic response 200–600 ms, acts on heart rate | E1 | same | human |
| The reflex RESETS toward prevailing pressure over hours to days | E1 | Dampney 2017 | mammal |
| Open-loop gain 1.0–3.5 | — | Yamasaki, Front Neurosci 2021;15:707345 | **animal** |
| Reset time constant value | — | **ASSUMED**, no reported human value found | — |

The open-loop gain source states explicitly that the vascular-isolation method used
to obtain it is not applicable to humans and that **human open-loop gain has not been
clarified**. This is the weakest number in the component.

## Decision

One lumped first-order lag on TPR, with a resetting setpoint.

**Arms are lumped** because the model is cycle-averaged (ADR 0002): heart rate is not
a state, so the vagal arm has nothing to act on. Separating them buys nothing until
heart rate exists. This was an explicit instruction — do not re-separate them without
a protocol that needs it.

**The characteristic saturates** (tanh). The real reflex is sigmoidal; an unbounded
linear gain would drive TPR negative under hemorrhage-scale excursions.

## The central point: resetting

The baroreflex re-centres on prevailing pressure over hours to days. It is a **fast
buffer, not a long-term regulator**.

This matters structurally, not just for fidelity. If the baroreflex could set long-run
arterial pressure, the Guyton claim in ADR 0007 — that pressure is determined by
renal–body fluid feedback — would be false. The reset equation is what keeps the two
consistent:

    D(sp) ~ (MAP - sp) / tau_reset

At steady state `sp → MAP`, error → 0, `tpr_mod → 1`, and the reflex exerts no
long-run influence at all.

## Falsifiable test

**Adding the baroreflex MUST NOT change the 60-day salt-step result.**

Reference (ADR 0007, reproduced on CI):

| intake (mEq/d) | MAP (mmHg) |
|---|---|
| 205 | 93.00 |
| 154 | 90.53 |
| 103 | 88.07 |

`build_model(baroreflex = true)` must reproduce these to within tolerance.
`build_model(baroreflex = false)` recovers the previous model exactly.

If the steady state shifts, the reflex is acting as a long-term regulator and either
the reset path or the gain is wrong. This is a regression test on a physiological
claim, not on an implementation.

A second test: the reflex must be **fast** — a step disturbance must be buffered on a
timescale of seconds, not days.

## Consequences

- TPR is a state-dependent quantity. RAAS will scale it further along the same
  `tpr_mod` path when it lands, multiplicatively.
- Two new states (`sp`, `tpr_mod`) with a 3 s effector tau against day-scale
  horizons — a stiffness ratio near 1e6. This is the first component that genuinely
  exercises the adaptive stiff solver of ADR 0001.
- Re-run the ADR 0003 cost profile after this lands. The state count is still far
  below the 20-state threshold for a verdict, so ADR 0003 remains Deferred.

## What is NOT decided

- Open-loop gain is animal-derived and flagged. Any published result involving
  baroreflex magnitude must say so.
- Reset tau is assumed at 1 day. Sensitivity to it must be tested: it is the
  parameter that determines whether the reflex stays a buffer.
- Cardiopulmonary (low-pressure) baroreceptors are not represented. They matter for
  volume-loading and LBNP protocols and are a separate component.
