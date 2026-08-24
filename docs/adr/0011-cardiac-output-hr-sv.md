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

> **SUPERSEDED ON ITS INPUT SIDE BY ADR 0012, 2026-08-24.** The Q3 finding below - that
> the stroke volume response to a fixed blood loss orders monotonically with posture -
> is the falsification signature this record's own section 8 declared in advance, and it
> says `V_blood` is the wrong filling variable. ADR 0012 introduces a central/peripheral
> partition and the decision becomes `SV ~ f(V_central)`. **The `CO = HR x SV`
> decomposition below is untouched and survives intact**; only the input variable
> changes. Read the two together. Nothing here is retracted.

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

### The admissible list partly violates the exclusion above - recorded, not resolved

Caught by `validation/sv_filling_prereg.md`, written against this record before any
paper was opened. A 15% withdrawal of total blood volume provokes sympathetic
activation, which raises contractility. **The named example fails the stated rule**, and
so will most volume perturbations large enough to produce a measurable SV signal. The
exclusion is not relaxed to accommodate it. The consequences fixed there are:
sympathetic state recorded per study as an uncontrolled covariate; sources reporting
autonomic blockade or contractility indices preferred, declared before seeing which
exist; and a parameter pooled from confounded studies tiered **E2 with a stated
confound**, never written up as measured at constant contractility.

This is structurally the same defect as the filtered-load term sitting inside `G_pn` - a
quantity the model does not represent, hiding inside a number meant to represent
something else. Recording it does not remove it. It makes it visible the next time the
residual is audited.

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
  or otherwise. Pre-registered in `validation/sv_filling_prereg.md`, which also fixes the
  pooling rule, the endpoint, and the condition that the result may not be selected for
  agreement with `G_vr` or with the 4.934 mmHg salt step. Nothing has been extracted.
- **The numeric value of resting HR.** Not in the ledger and not asserted here. Q1 of the
  same pre-registration; note the open question there about whether the nominal
  population matches `CV.HEMATOCRIT.NOMINAL`, which is recorded as adult male.
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

---

## First sourcing outcome, 2026-08-22 - one direction is empty

Extracted under `validation/sv_filling_prereg.md`, committed before any paper was opened.
Reproduce with `python validation/sv_filling_extract.py`. Every citation was read from
the PubMed record via the E-utilities API and its author list, journal, year, volume,
issue and pages verified there, per stop condition 2. **No ledger row is created and no
parameter is recorded.** Status stays Proposed.

### Q1 is sourceable; the decision it forces is not an extraction

Gonzales TI, Jeon JY, Lindsay T, Westgate K, Perez-Pozuelo I, Hollidge S, Wijndaele K,
Rennie K, Forouhi N, Griffin S, Wareham N, Brage S. *PLoS One* 2023;18(5):e0285272,
PMID 37167327, `10.1371/journal.pone.0285272`. n = 10,865 (5,722 women, 5,143 men),
29-65 y. **Supine 63.5 +/- 8.9 bpm**, seated 67.6 +/- 9.8, sleeping 56.9 +/- 6.9, by
chest sensor after at least 1 h rest with the value taken from the final 3 min of a 6 min
recording. Supine is selected because `CV.CO.NOMINAL` is itself derived from the
conventional resting 5 L/min, which is supine - consistency, not the value.

`SV0 = CO0/HR0` = **78.74 mL**, derived, and the closure constraint follows.

Three deviations are recorded rather than absorbed. It is a **general population** cohort
from GP lists, not the health-screened sample the pre-registration specified; it is
**53% women** while `CV.HEMATOCRIT.NOMINAL` is recorded as adult male nominal, so
adopting both would have the cardiovascular rows describing two different populations;
and it is `single-source`, large but one cohort. The second is a decision for the owner,
not something extraction can settle.

### Q2 removal: k = 3 admissible, and the count was never the real problem

Revised 2026-08-24 after the owner supplied all three full texts. All three clear
inclusion criterion 4, and **the endpoint objection raised on 2026-08-22 was wrong for
all three**.

| Study | PMID | n | posture | removed | dSV | slope |
|---|---|---|---|---|---|---|
| Leonetti 2004, *Clin Auton Res* 14(3):176-81 | 15241646 | 12 | **seated** | 375 mL | 10.5 mL | 28.00 mL/L |
| Gybel-Brask 2020, *Transfus Med* 30(6):450-455 | 33030269 | 21 | **~30 deg**, 30 min rest | 900 mL | 12 mL (sham-corrected) | 13.33 mL/L |
| Epstein 2021, *Shock* 55(2):230-235 | 32769818 | 60 | **supine** | 450 mL | 4.57 mL (control-corrected) | 10.16 mL/L |

Blood removed **is** a measured total blood volume change, 1:1, which is why this
direction survives inclusion criterion 2. Gybel-Brask measures within 5 min of each
donation; Epstein immediately before and after against a 20-subject control re-measured
at 10 min without phlebotomy; Leonetti over the last 60 s of a recovery period ending
5 min after completion.

**The pre-registered endpoint rule moved Leonetti's number by 21%.** Its Table 1 reports
three periods - pre 94.0, end-of-phlebotomy 80.7, post-phlebotomy 83.5 mL - and the
abstract quotes 94.0 -> 80.7. But 80.7 is the last minute *of* the withdrawal, and
section 5 fixed the endpoint as the settled post-perturbation value. **dSV = 10.5 mL, not
13.3.** Dispersion is confirmed **SEM**, so SD = 5.2·√12 = 18.0 mL. A confound is
recorded: total peripheral resistance rose 0.73 -> 0.79 significantly, so the vascular
state did not hold still, and per pre-registration section 0.2 this is **E2 with a stated
confound**, not E1.

Gybel-Brask additionally reports **no SV change at 450 mL with a change only at 900 mL**,
a threshold signal a single slope through the operating point cannot carry.

#### Correction: the spread does not track technique

The 2026-08-22 version said the spread tracked measurement technique and invoked prereg
section 3's report-do-not-average clause on that basis. **That was wrong.** Gybel-Brask
measures stroke volume by finger volume-clamp pulse wave analysis, the same family as
Leonetti's Finometer; the thoracic electrical impedance in its title is for **central
blood volume**. Section 3's clause was invoked in error. What actually orders the spread
is below.

### Q3: the falsification signature fires

Section 8 of the pre-registration, written before any paper was opened, said that if
comparable total-volume changes at different posture gave materially different SV
changes, then total blood volume is not what sets filling.

**The three slopes order monotonically with uprightness: 28.00 seated, 13.33 at 30
degrees, 10.16 supine. Seated is 2.8x supine.** The direction is the physiologically
expected one - the more upright, the more of the blood volume sits in dependent veins,
the less of it is stressed, and the more a fixed absolute loss costs in filling.

**The two obvious alternatives do not order it.** Technique: Leonetti and Gybel-Brask use
the *same* finger volume-clamp family and still differ 2.1x, while the one bio-impedance
study sits closest to Gybel-Brask rather than furthest. Dose: the slope is already per
litre, and if saturation drove it the 900 mL study would give the smallest per-litre
value - it gives the middle one.

**What it does not rule out, stated because three studies cannot settle it.** Population
and age differ across the three - haemochromatosis patients on regular phlebotomy,
healthy men, young military donors - and posture is perfectly confounded with study. This
is a **between-study gradient, not a controlled comparison. Suggestive, not decisive.**

**The consequence is not a count problem.** `k = 3` is met. But pooling these three would
average across the very variable Q3 nominates as the effect modifier and produce a
correctly-sourced number describing no posture in particular - worse than an unsourced
one because it looks finished. That is the same failure the immersion pre-registration
caught on the ANP fold-rise. **No parameter is recorded. `G_vr` stays.**

**If Q3 holds, this ADR is wrong on its input side in exactly the way ADR 0010 was:** the
model variable is total blood volume, the physiological variable is the *stressed*
fraction, and posture moves one without moving the other. The stressed/unstressed split
would not be optional - which is precisely what this record's own falsifiable test said
its likely failure mode would be. It has arrived during sourcing, at the cost of a
search, rather than after a component was built.

**The confirmatory study is already identified.** van de Velde 2018 (PMID 29016531)
crosses a 500 mL phlebotomy with active standing **in the same subjects** - the
within-subject posture-by-volume design this gradient needs. It was flagged as a Q3 lead
on 2026-08-22, before any of this was visible.

#### Correction: the spread does not track technique

The 2026-08-22 version of this section said the spread tracked measurement technique -
one Modelflow study against two impedance studies - and invoked prereg section 3's
report-do-not-average clause on that basis. **That was wrong.** Gybel-Brask measures
stroke volume by finger volume-clamp pulse wave analysis, the same family as Leonetti's
Finometer; the thoracic electrical impedance in its title is for **central blood volume**,
not stroke volume. The two finger-pulse-contour studies therefore disagree with *each
other* by 2.7x, and the one genuine impedance study sits at the bottom alongside the
lower of them. Section 3's clause was invoked in error.

#### What does hold across all three: the baselines do not match the model

Baseline stroke volumes are 94, 118 and 90 mL against the `SV0 = 78.74 mL` this record
derives, and baseline cardiac outputs are 6.9 and 6.03 L/min against the model's 5.0.
A slope can be right while the offset is wrong, so this does not invalidate the slopes -
but these devices are not reading the resting operating point the ledger describes, and
that is recorded rather than reconciled.

### Q2 addition: k = 0, and this is the finding

Every candidate is excluded, and mostly on the same criterion. **Saline studies report
infused volume, not measured blood volume.** Weiner 2010 (PMID 20826594) infused
2.1 +/- 0.3 L and measured SV 51.3 -> 63.0 mL by echo, but 2.1 L of saline is not a 2.1 L
rise in `V_blood`, and no plasma or blood volume was measured. Converting one to the
other needs a retention fraction that is not in the paper - **the same unsourced scaling
step that falsified ADR 0010's input link**, arriving from a different direction.

The pre-registration foresaw the two directions *disagreeing*. It did not foresee one of
them being **empty**, so its section 6 directional comparison cannot be run at all.

### The contractility exclusion turned out to be load-bearing

Kumar A, Anel R, Bunnell E, Zanotti S, Habet K, Haery C, Marshall S, Cheang M, Neumann A,
Ali A, Kavinsky C, Parrillo JE. *Crit Care* 2004;8(3):R128-36, PMID 15153240. In 36
healthy volunteers given 3 L of saline over 3 h, end-diastolic volumes rose only
inconsistently while end-systolic volumes fell almost uniformly, and **the fall in
end-systolic volume contributed 40-90% of the stroke volume response**, with ejection
fraction and ventricular stroke work both up.

Volume loading in intact humans is **not a preload-only perturbation**, and the size of
the non-preload part is most of it. Section 0.2 of the pre-registration refused to relax
this exclusion before knowing that. The refusal was right, and the exclusion is now
evidence-backed rather than precautionary.

### One result favours this ADR, and it is the one tension 0.1 asked about

This record keeps `HR` a parameter rather than a state. Epstein tabulates heart rate
**67 (13) -> 68 (11) bpm** across a 450 mL withdrawal with controls flat at 56 (7);
Leonetti reports heart rate **not significantly changed** across 375 mL (75.2 -> 78.3);
and Weiner reports **no change** across a 2.1 L bolus. Three independent studies, two
directions of perturbation, three different measurement techniques. Holding HR fixed
while `V_blood` moves is defensible at these perturbation sizes.

### The comparison against `G_vr`, made once, after pooling

Per stop condition 4, and no study was included, excluded, weighted or trimmed on it.
Implied `G_vr = HR0 x dSV/dV_blood`: Leonetti 3243, Gybel-Brask 1219, Epstein 1030,
n-weighted **1358 (L/day)/L** against the incumbent **2880**. The incumbent sits above
two of three and just below the third.

**Do not connect this to the 2.2x residual.** The n-weighted ratio lands near a number
that appears elsewhere in this repo for an unrelated reason. The pre-registration states
that nothing found here may be used to re-attribute that residual, and a numerical
coincidence is not an exception. It is written down so that nobody discovers it later and
mistakes it for a result.

### What is needed next

All three removal full texts have been read. The removal direction is resolved as far as
this pre-registration can take it, and what remains is no longer a sourcing backlog.

1. **Settle Q3, because everything else waits on it.** van de Velde 2018
   (PMID 29016531) crosses a 500 mL phlebotomy with active standing **in the same
   subjects** and is the within-subject test the between-study gradient needs. It needs
   its own pre-registration - the question is now specific enough to state in advance,
   which the 2026-08-22 version was not. If posture governs, no single `SV(V_blood)`
   slope is recordable at any `k` and this ADR needs its Decision revised before more
   searching, not after.
2. **A total-volume addition paradigm that measures volume**, or the recorded acceptance
   that there is none. Autologous blood reinfusion is the obvious candidate and was not
   reached. Note it is only worth running **after** Q3 - if posture governs, an addition
   study at an unrecorded posture adds nothing.
3. **Decide the Q1 population question.** The Fenland cohort is 53% women while
   `CV.HEMATOCRIT.NOMINAL` is adult male nominal. That is a decision, not an extraction,
   and it is the only thing standing between Q1 and a ledger row.
4. **The baseline mismatch is unexplained and is not part of Q3.** Baseline stroke
   volumes of 94, 118 and 90 mL against the 78.74 mL this record derives, and cardiac
   outputs of 6.9 and 6.03 against 5.0 L/min, are a separate discrepancy between what
   these devices read and what the ledger's operating point asserts. It does not
   invalidate a slope. It has not been investigated.
