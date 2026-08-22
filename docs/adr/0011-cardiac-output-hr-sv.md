# ADR 0011: Cardiac output as HR x SV - the light refinement that refines

**Status:** Proposed
**Date:** 2026-08-22
**Evidence tier:** MIXED - E1 for `CO = HR x SV` (definitional) and for the dependence
of stroke volume on ventricular filling (Frank-Starling). **NO TIER IS CLAIMED for the
quantitative SV-filling form**, because this ADR does not assert one. It names the
sourcing task and the paradigm that may be used for it, and stops there.

> This is a refinement of the SPINE, not a modulator. It replaces a fitted constant in
> the existing loop with a decomposition whose parts are separately measurable. ADR 0006
> build order is satisfied: `CO = HR x SV` is better established than the linearisation
> it displaces, not less.

## Context

`Cardiovascular.jl` collapses the entire volume-to-flow limb into one line:

    CO ~ max(0.0, CO0 + G_vr * (V_blood - BV0))

`CV.VENOUS_RETURN.SENSITIVITY` (`G_vr` = 2880 (L/day)/L) is `calibrated` in the ledger,
and its own note calls it the second most consequential unmeasured number in the model
after the pressure natriuresis slope. ADR 0007 recorded the same thing more bluntly:
everything the model claims about long-run pressure regulation rests on two numbers that
were fitted rather than measured.

Three things have since sharpened what is wrong with it, and none of them is that the
model is too simple.

**1. Fitted lumping does not refine; definitional lumping does.** `V_blood =
V_plasma/(1 - Hct)` is a definitional aggregate - split it later and the parts sum back
to the whole. `G_vr` is a constant fitted to close the loop. When arterial and venous
compliance eventually become separate quantities, there is nothing in `G_vr` to take
back out. It must be re-fitted from scratch, and there is no way to check the new fit
against the old. Thirteen of the ledger's forty-one parameters are `assumed` or
`calibrated`; those are the ones that will not survive refinement, and `G_vr` is the
most load-bearing of them.

**2. A lumped parameter absorbs whatever the model does not represent, and then a
disagreement with the literature cannot be diagnosed.** This is not hypothetical here.
The 3.68x / 2.2x problem is exactly it: IPE's `G_pn` is a slope at constant filtered
load, Mizelle's between-kidney slope is not, and the ~8% GFR difference between those
kidneys sat inside the comparison in the favourable direction until it was audited
(ADR 0010 section 6). A fitted lump is where undiagnosed structure goes to hide.

**3. Simplification does not merely defer detail - it disqualifies evidence.** ADR 0010
was calibrated against head-out immersion for three sourcing sessions before Norsk 1986
established that immersion is a redistribution at approximately constant total volume,
which a model with one blood volume and no central compartment cannot represent. The
model did not fail to represent the physiology; it failed to *connect to the evidence*.
That cost was not visible in advance because no record said which paradigms the lumping
had already ruled out.

Separately, `src/reconstruct.jl` already takes stroke volume as an argument it cannot be
given: ADR 0002 requires SV and arterial compliance for systolic/diastolic
reconstruction, and the model has no SV. That debt is already owed.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| `CO = HR x SV` | E1 | definitional | - |
| Stroke volume rises with ventricular filling (Frank-Starling) | E1 | as already cited for `G_vr` in the ledger and in ADR 0007; no new source is claimed here | human, mammalian |
| `CO0 = HR0 x SV0` at the nominal operating point | E1 | definitional; a closure constraint, see Consequences | - |
| The quantitative form of SV against total blood volume | **NOT ASSERTED** | requires a pre-registered search; admissible paradigms are fixed below | - |
| Resting heart rate nominal | **NOT ASSERTED** | not currently in the ledger; requires sourcing | human |

The middle row is the entire point of this record. The Frank-Starling *relationship* is
E1 and always was - ADR 0007 says so. What has never been sourced is the *slope*, in
either its current form (`G_vr`) or its proposed one. This ADR does not fix that. It
makes the unsourced quantity a thing that can be measured on its own.

## Decision

Replace the fitted volume-to-flow line with a decomposition, staying algebraic:

    CO ~ HR * SV
    SV ~ <filling function of V_blood>        # form NOT decided here

**The model stays at 3 states.** Nothing here adds a differential equation. `HR` is a
parameter, not a state, until baroreflex chronotropy exists - the baroreflex currently
scales `TPR` through `tpr_mod` and nothing else, and giving it a second effector is a
separate decision requiring its own evidence.

`G_vr` is **not deleted on acceptance.** It stays until its replacement is sourced, so
the loop never sits open. When the replacement lands, `G_vr` is retired with a ledger
note recording that it was superseded by a decomposition rather than re-estimated -
otherwise a future reader will look for a re-estimation that never happened.

### Why this is worth doing when it adds no capability

It adds none, deliberately. What it buys is that **HR and SV are separately measurable
in humans, and `G_vr` is not.** Each half can be sourced, tiered, and refined
independently, and each has an evidence base that exists. That is the whole argument:
a lump whose pieces can be measured separately is a temporary convenience, and a lump
whose pieces cannot is a permanent commitment wearing a temporary disguise.

## What this lumping disqualifies as evidence

**New section, and the practice this ADR is arguing for.** ADR 0002 already records what
the cycle-averaged formulation *cannot represent*. That is a statement about outputs.
This is a statement about **inputs**: which experimental paradigms may no longer be used
to calibrate this component, because the model variable and the perturbed variable do
not match. Had ADR 0002 carried such a section, the ANP immersion search would not have
been run.

An algebraic `SV(V_blood)` with one blood volume, no stressed/unstressed split, no
central compartment and fixed contractility **may not be calibrated against**:

- **Any redistribution paradigm at constant total volume** - head-out water immersion,
  head-up tilt, lower-body negative pressure, posture change, microgravity onset. These
  move central volume while total volume is approximately unchanged, which is precisely
  the mismatch that falsified ADR 0010's input link. This disqualifies the richest and
  most-replicated part of the volume-CO literature, and that is the cost of the
  simplification, stated up front rather than discovered three sessions in.
- **Any paradigm in which contractility changes** - catecholamine or inotrope infusion,
  heart failure cohorts, beta-blockade. Contractility is fixed here, so it would be
  absorbed into the filling slope exactly as filtered load was absorbed into `G_pn`.
- **Exercise of any grade.** HR, contractility and venous tone all move together; the
  filling dependence is not identifiable from it.

It **may** be calibrated against paradigms that change **total** blood volume:

- Blood withdrawal and reinfusion with quantified volume - Simanonok 1993 (PMID 8431188,
  already read into this repo for ADR 0010) is this class: a 15% bled fraction of total
  blood volume, measured.
- Isotonic saline or plasma volume expansion with quantified infused volume.
- Chronic sodium loading, which is the perturbation the model itself runs.

Note that ADR 0002 independently rules out beat-to-beat endpoints, and tilt and LBNP are
usually reported beat-to-beat. They are disqualified here for a **different and
additional** reason - a 10 s averaging window fixes the sampling objection and does not
fix this one. Do not read one exclusion as covering the other.

## Consequences

**Ledger.** Adds approximately two sourced rows (resting HR nominal; the SV-filling
slope or its functional parameters) and one derived row. `CV.CO.NOMINAL` already exists
at 7200 L/day, so `SV0 = CO0 / HR0` is **derived, not sourced**, and becomes a closure
constraint of exactly the same kind as `CV.PLASMA.ECF_FRACTION` - if `CO0` or `HR0`
move, `SV0` must be recomputed. Source one, derive the other, and let
`tools/check_closure.py` hold the identity.

**`check_closure.py`.** This adds one relationship to the seven it hand-codes. That is
survivable, but the handover's warning that the gate does not scale past roughly twenty
should be read as applying from here on, not later: cardiovascular refinement is the
work that starts filling it.

**`reconstruct.jl` becomes connectable.** `pulse_pressure(SV, C_art)` currently takes an
argument the model cannot supply. It still needs `C_art`, which this ADR does not
provide, so nothing is unblocked yet - but half the missing input arrives.

**The salt step will move, and the tests pin it.** `test/runtests.jl` asserts salt
sensitivity precisely so that a parameter change cannot pass unnoticed. The algebra in
HANDOVER section 3.1 says the steady-state pressure shift is set by `G_pn` alone and
`G_vr` does not appear in it; the measured sweep at `G_pn = 5.43` nonetheless moved the
shift 15.698 -> 12.403 while driving `V_ecf` to 9.889 L. So the expectation is that a
re-sourced filling slope moves **ECF volume first and the pressure shift second**.

That is an expectation, not a result. **Run it and read the numbers.** If the pressure
shift moves substantially at `G_pn = 20`, the algebra is being violated somewhere and
that is a finding, not a nuisance.

**Bit-identity ends.** The 4.934166220845427 mmHg figure has been bit-identical across
every commit and has served as a cheap integrity check. Once the filling slope is
re-sourced it changes, legitimately, and that check is spent. Record the new value the
same way.

## Falsifiable test

Source `SV(V_blood)` from total-volume perturbations only, per the disqualification list
above, then close the loop and check the nominal operating point.

**The structure is wrong if** the independently sourced filling slope cannot reproduce
the nominal steady state - `V_ecf` near 14.56 L and MAP near 93 mmHg at nominal intake -
within the closure constraints and the uncertainty of the sourced values.

The most likely reason for that failure is informative rather than fatal: an algebraic
`SV(V_blood)` treats **all** blood volume as filling pressure, when only the stressed
fraction contributes. If the loop will not close, that is evidence the
stressed/unstressed split is not optional, and it points directly at the next structural
decision instead of leaving it to a completeness checklist.

Failure would **not** vindicate `G_vr`. A fitted constant that closes the loop by
construction cannot be evidence that its own structure is right.

## What is NOT decided

- **The functional form of `SV(V_blood)`** - linear about the operating point, saturating,
  or otherwise. Pre-register before extracting, per the standing rule.
- **The numeric value of resting HR.** Not in the ledger and not asserted here.
- **HR as a state.** Requires chronotropic baroreflex, which requires its own evidence
  and would extend ADR 0009's effector set.
- **Contractility**, in any form.
- **Arterial and venous compliance, stressed and unstressed volume, mean circulatory
  filling pressure, right atrial pressure.** These are the Guyton venous-return
  formulation proper. This ADR is deliberately not that, and the falsifiable test above
  is the thing that would tell us whether they have become unavoidable.
- **Whether `G_vr`'s fitted value is recoverable** as `HR0 x dSV/dV_blood`. It probably
  is arithmetically. That would be a consistency check, **not** a source, and it must not
  be recorded as one.

## Note on the disqualification section

`docs/adr/TEMPLATE.md` gains a **What this lumping disqualifies as evidence** section as
part of this change. It is prose in a document already being written, not tooling, and
it generalises a section ADR 0002 already contains. It is optional where a record lumps
nothing.

The cost it targets is measured: three pre-registered sourcing sessions were spent on a
paradigm the model's own simplification had already excluded, and nothing in the repo
recorded that exclusion.
