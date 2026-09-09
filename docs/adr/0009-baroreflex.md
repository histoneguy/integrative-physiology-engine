# ADR 0009: Baroreflex — lumped, resetting, buffer not regulator

**Status:** Accepted
**Evidence tier:** MIXED — see table (E1 structure, E2 animal-derived gain under an ethical ceiling)
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
| Open-loop gain 1.0–3.5 | E2 | Yamasaki, Front Neurosci 2021;15:707345 | animal, vascularly isolated baroreceptors - not performable in humans |
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

## Addendum, 2026-08-19 — the effector sign was inverted on merge

The version merged in PR #6 had `drive ~ +sat * tanh(...)`. That is **positive**
feedback: a rise in pressure raised `tpr_mod`, which raised TPR, which raised
pressure.

The closed-loop gain of that error is exactly `G_br`. The tanh slope at the
operating point is `G_br / MAP_ref`, and `∂MAP/∂tpr_mod = MAP / tpr_mod ≈ MAP_ref`,
so the product is `G_br = 2.0`. Regenerative with gain 2 is unconditionally
unstable: `tpr_mod` ran to the saturation bound, `sp` then reset toward the new
pressure, `err` collapsed, and the loop fell onto the opposite branch. The
salt step returned:

| intake (mEq/d) | MAP, sign inverted | MAP, correct |
|---|---|---|
| 205 | 95.03 | 93.0000375 |
| 154 | **40.42** | 90.5335685 |
| 103 | 95.81 | 88.0658713 |

40 mmHg is not a survivable mean arterial pressure, and the sequence is not
monotonic in intake.

With the sign corrected, `baroreflex = true` and `baroreflex = false` agree to a
relative 4e-7 — three orders inside the `rtol = 1e-3` of the regression test — and
the salt-step shift is 4.9341 mmHg, matching the pre-baroreflex baseline.

**The decision in this ADR is unchanged.** No parameter was implicated:
`BR.OPEN_LOOP_GAIN` and `BR.RESET.TAU` are as recorded. This was an implementation
sign error, not a structural or evidentiary one.

### What let it through

Two things, and the second is the one worth fixing.

1. The `baroreflex = false` path was written and never executed before merge. It
   turned out to be correct, but it was not known to be at the time.

2. **The Diagnostics workflow reported green while printing a 40 mmHg salt-step
   table to its own job summary.** `diagnostics.yml` sets `continue-on-error: true`
   at both job and step level, and `bench/diagnostics.jl` calls `exit(0)` at every
   gate. It is structurally incapable of failing. A green Diagnostics check was
   read as evidence the model ran correctly; it is not evidence of anything.

The Julia test suite *did* catch this — `CI/Julia tests` failed on PR #6, correctly,
and the failing assertion was precisely the falsifiable claim above. The gate worked.
What failed was reading a check that cannot fail as if it were a second opinion.
This is the failure mode ADR 0008 was written about, recurring in the tooling ADR 0008
produced.

---

## Addendum, 2026-08-21 - open-loop gain tiered

`BR.OPEN_LOOP_GAIN` carried **no tier at all**, which ADR 0006 rule 1 forbids and
`check_adrs.py` does not catch, since it only reads the header line. It is now E2.

The value comes from vascularly isolated baroreceptor preparations. That is not a
study anyone may perform on a human - isolating the carotid sinus from the systemic
circulation to open the loop is definitionally terminal. Under the amended ADR 0006
this is an ethical ceiling, and the animal provenance is recorded rather than treated
as a defect.

`BR.RESET.TAU` is a different matter and is untouched: it is ASSUMED, with no reported
value in any species. That remains debt.

---

## Amendment, 2026-09-08 — the arms are no longer lumped. See ADR 0022

**The condition this record set has been met.** ADR 0009 lumped the vagal and
sympathetic arms onto total peripheral resistance and said why: the model is
cycle-averaged, heart rate was a parameter, and the vagal arm had nothing to act on.
It recorded, as an explicit instruction, *do not re-separate them without a protocol
that needs it.*

ADR 0011 made cardiac output `HR × SV`. **ADR 0022 splits the arms**, giving the reflex
a second effector, `hr_mod`, on heart rate. The decision, the evidence and the
falsifiable tests live there. Three things about it belong here, on the record it
amends:

1. **The gain in this record is the VASOMOTOR arm, not the whole reflex**, and that was
   established before the second effector was built rather than assumed afterwards.
   `BR.OPEN_LOOP_GAIN` decomposes through plasma noradrenaline, so a cholinergic vagal
   limb cannot be inside it; and the two arms are uncorrelated within healthy
   individuals (Dutoit 2010, n = 53, R² = 0.0003). **The arms add. They do not split
   this number.** Had it gone the other way, a second effector would have doubled the
   reflex with every gate still green.

2. **The lumping argument was right for its time and is now the thing to check.** "One
   lumped lag on TPR is the honest representation at this resolution" was true while
   heart rate did not exist. What made it stop being true was ADR 0011, and **nothing
   in this repository connected the two records** — the note that did was a comment in
   `Cardiovascular.jl` saying heart rate is a parameter *until a chronotropic
   baroreflex exists*. A structural precondition recorded only in a source comment is
   one nobody re-reads.

3. **`BR.OPEN_LOOP_GAIN` now carries a recorded defect.** Its 2.0 is the mid-point of
   an animal range quoted in Yamasaki's *introduction*, while Yamasaki's own *result*
   is a human measurement of 5.62 supine with vagal effects blocked — the very quantity
   this row is meant to hold. Not changed in ADR 0022's pass, because it moves every
   transient in the model; it is its own pass. See HANDOVER §3.38.

**What is unchanged:** the resetting structure, and with it this record's falsifiable
test. The reflex is still a fast buffer and not a long-term regulator, and the second
effector nulls at every steady state exactly as the first does.

---

## Amendment, 2026-09-09 — the gain is a HUMAN number, and this record's ethical-ceiling argument was wrong

**`BR.OPEN_LOOP_GAIN` is 5.62, not 2.0, at the owner's instruction.** The citation did
not change. This record and that row both carried the mid-point of an **animal** range
of 1.0–3.5 that Yamasaki 2021 quotes in his *introduction*, while Yamasaki's own
**result** is a human measurement: **GL(0) = 5.62 ± 0.98 supine**, n = 7 healthy males
aged 19–37, arterial pressure as the output variable, means ± SD.

### The addendum of 2026-08-21 is corrected, not merely updated

That addendum tiered the row E2 and defended the animal provenance like this:

> *That is not a study anyone may perform on a human — isolating the carotid sinus from
> the systemic circulation to open the loop is definitionally terminal. Under the amended
> ADR 0006 this is an ethical ceiling.*

**The ceiling is real for that PREPARATION and false for the QUANTITY.** Yamasaki
obtained the open-loop gain in conscious humans without opening the loop surgically, by
constructing an equilibrium diagram from graded head-up tilt and ganglionic blockade.
**The number was obtainable all along by a different method, in the paper this record
already cited.**

**That is §3.19's lesson repeated exactly.** The venous-return pass missed its relation
for weeks by searching for the wrong *object* — a compliance in mL/mmHg rather than the
composite `dCO/dV_blood` — and the fix was to ask what is *measurable*, not whether the
obvious preparation is permitted. **An ethical ceiling justifies animal data only after
the human literature has been searched for a different route to the same quantity.**

### What the tier becomes, and what stays weak

Still **E2**, and for a different reason than before: no longer species extrapolation
under an ethical ceiling, but a direct human measurement in **seven young men whose
authors explicitly disclaim representativeness**. It is entered `both`, so it is a male
number applied to women — the `CV.HEMATOCRIT.NOMINAL` failure, declared. And it is a
young cohort in a model whose stroke volume comes from 45–74 year olds.

### Why this pairs correctly with ADR 0022 and would not have before

Yamasaki blocked vagal effects with atropine throughout, so **5.62 is sympathetic
pressure control with the cardiac vagal limb removed.** Since ADR 0022 that limb is a
separate effector with its own sourced gain, so the two rows now partition the reflex
the way the measurements do. **Made before ADR 0022, this change would have deleted the
vagal contribution from the model entirely.**

### What it does, and what was deliberately not done about it

No steady state moves — the reflex resets, so `tpr_mod → 1` whatever the gain, and this
record's falsifiable test is untouched. **Every transient moves**: total loop gain goes
from about 3.35 to about 6.97, so a pressure disturbance is buffered roughly twice as
hard. **Nothing was re-estimated to compensate** — in particular `RN.MD.RENIN_GAIN` and
`CV.ANP.NATRIURETIC_GAIN` were not re-solved. HANDOVER §3.39 has the measured
consequences, including what it costs `OPEN-QUESTIONS` B9.
