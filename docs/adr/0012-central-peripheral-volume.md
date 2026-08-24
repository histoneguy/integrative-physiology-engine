# ADR 0012: A central/peripheral volume partition - the distinction the evidence keeps asking for

**Status:** Proposed
**Date:** 2026-08-24
**Evidence tier:** MIXED - E1 for the existence of a central/peripheral blood volume
distribution and for its shift with posture and with water immersion. **NO TIER IS
CLAIMED for the quantitative partition fraction**, which this ADR does not assert. It
creates the variable and names the sourcing task.

> This is a refinement of the SPINE, not a modulator. ADR 0006 build order is satisfied:
> the existence of a central compartment is better established than the single lumped
> `V_blood` it refines, not less.

## Context

Two decision records have now failed on the same thing, from opposite ends of the model.

**ADR 0010 (ANP)** was calibrated against head-out immersion for three pre-registered
sourcing sessions before Norsk 1986 (PMID 3745047) established that immersion is a
redistribution at approximately constant total volume. IPE has one blood volume and no
central compartment, so it cannot represent that, and the record concluded that
**immersion is the wrong calibration paradigm** - closing blocker 2 as *falsified* rather
than sourced, and adding a new blocker to re-source the input link against a total-volume
paradigm instead.

**ADR 0011 (HR x SV)** hit it from the cardiac side. Its Q3 asked, before any paper was
opened, whether comparable total-volume changes at different posture would give different
stroke volume changes. They do: 28.00 mL/L seated, 13.33 at ~30 degrees, 10.16 supine.
Seated is 2.8x supine, and neither measurement technique nor dose orders the gradient.

Both findings say the same thing. **The model carries one `V_blood`, and the physiology
responds to where the volume is, not to how much of it there is in total.**

### A correction to how this was previously summarised

Earlier notes in this repo grouped Rabelink 1989's distal-delivery finding with Norsk's
redistribution finding as "the same mechanism seen from two directions". **They are not
the same distinction.** Rabelink is about a *nephron* partition - proximal versus distal
sodium handling. Norsk and the posture gradient are about a *vascular* partition. Both
are distributions the model lacks, but they are different compartments in different
organs, and conflating them would justify this ADR with evidence that does not bear on
it. The vascular evidence here is Norsk 1986, Greenleaf 1980 (PMID 6986349), Simanonok
1993 (PMID 8431188) and the ADR 0011 posture gradient. Rabelink is set aside as a
separate open question.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| Blood volume is distributed between an intrathoracic central compartment and a peripheral one | E1 | standard cardiovascular physiology | human |
| Posture shifts volume between them, peripherally when upright | E1 | standard; and the ADR 0011 posture gradient is consistent with it | human |
| Water immersion translocates volume centrally at approximately constant total volume | E1 | Norsk 1986 PMID 3745047, graded to three depths; Greenleaf 1980 PMID 6986349 | human |
| Natriuresis grades with immersion depth while plasma volume does not | E1 | Norsk 1986 | human |
| The natriuretic response largely survives a 15% reduction in total blood volume | E2 | Simanonok 1993 PMID 8431188, n=6 | human |
| Cardiopulmonary receptors and atrial ANP release respond to CENTRAL filling | E1 | standard; the basis of ADR 0010's own premise | human, mammalian |
| The numeric central fraction at any posture | **NOT ASSERTED** | requires a pre-registered search | - |

## The two arguments that decide this

### 1. It gives the model a variable that something in the body actually senses

`V_blood` is not a sensed variable anywhere in human physiology. No receptor measures
total blood volume. Cardiopulmonary baroreceptors sit in the atria and great veins, and
ANP is released on atrial stretch - **both respond to central filling.**

That is why ADR 0010's input link could not be sourced. The failure was read at the time
as a gap in the literature. It is better read as a category error: the model was asking
for a dose-response between a plasma hormone and a quantity that has no receptor. A
central compartment removes the error rather than working around it.

### 2. It un-disqualifies the immersion literature

This is the part that pays for the change immediately.

ADR 0010 ruled out head-out immersion **because IPE cannot represent a redistribution at
constant total volume**. That reason disappears here - immersion becomes precisely a
change in the partition at fixed `V_blood`, which is exactly what this structure
represents.

The repo has already read and verified that literature and then had to shelve it: seven
primaries pooled under `immersion_pooling_prereg.md` with authors, journal, year, volume
and pages verified against the PubMed record, plus Norsk, Greenleaf and Simanonok. **The
structural change converts work already done and currently unusable back into usable
evidence.** ADR 0010's blocker 4 - re-source the input link against a total-volume
paradigm - is probably the wrong instruction and should be revisited once this lands.

### What central/peripheral is NOT

It is **not** the stressed/unstressed distinction, and it does not substitute for it.
Stressed volume is what generates mean circulatory filling pressure; the Guyton venous
return formulation needs it, along with compliances and right atrial pressure. This ADR
provides none of that.

The two are related - upright posture moves volume peripherally *and* into unstressed
capacitance - but they are different cuts. Central/peripheral is chosen here because it
is the cut **the evidence in this repo is actually about**: Norsk graded immersion depth,
not venous tone, and immersion is an anatomical translocation. Choosing the partition the
data speaks to, rather than the one a textbook formulation would prefer, is the whole
lesson of ADR 0010.

## Decision

Add an **algebraic** partition of blood volume:

    V_central    ~ f_central * V_blood
    V_peripheral ~ V_blood - V_central

`f_central` is a parameter, not a state. **The model stays at 3 states.**

Filling-dependent quantities key off `V_central` rather than `V_blood`. Concretely this
revises ADR 0011's Decision on its input side only:

    SV ~ <filling function of V_central>        # was V_blood

**ADR 0011's `CO = HR x SV` decomposition is untouched and survives intact.** Only the
input variable changes. That record stays Proposed and carries a pointer to this one.

### Why algebraic rather than a state

Translocation between compartments happens over seconds to minutes. The renal-body fluid
loop this model exists to demonstrate operates over days. ADR 0002 already made exactly
this call once - cycle-averaging removes fast modes at the modelling layer, before the
solver sees them - and the same reasoning applies one level up. A dynamic compartment
would be precision the surrounding model cannot support, and it would buy nothing the
quasi-static split does not.

### Land it in two stages, and the first stage is numerically inert

**Stage 1: `f_central` fixed at its supine value.** Every simulated result is unchanged,
bit for bit, because a fixed fraction of `V_blood` is just a rescaling absorbed by the
filling function. What changes is that **the variable exists**, so ANP and the
cardiopulmonary receptors have something to key off, and immersion becomes expressible as
a change in `f_central` at fixed `V_blood`.

**Stage 2: `f_central` responds to posture**, and later to venous tone when RAAS lands.
That is a modulator and belongs after the spine, per directive 1.3.

Stage 1 is the whole structural commitment. Stage 2 is where the numbers come in. Nothing
in stage 1 requires a sourced value, which is why it can land before the partition
fraction is sourced.

## What this lumping disqualifies as evidence

Two compartments, quasi-static, no regional flows. That excludes:

- **Any endpoint defined on the translocation transient** - the initial seconds of
  standing, orthostatic transients, the onset phase of tilt. The split is quasi-static by
  construction. ADR 0002 independently excludes beat-to-beat endpoints; this is a
  **separate and additional** exclusion, and a fixed averaging window does not fix it.
- **Anything that dissociates splanchnic from limb capacitance.** One peripheral
  compartment cannot represent selective splanchnic venoconstriction, or upper-body versus
  lower-body loading, as distinct from each other. Paradigms whose result depends on that
  distinction cannot calibrate `f_central`.
- **Anything keyed to regional distribution of FLOW rather than volume.** The model has no
  regional flows and this does not add any.

What **is** admissible for `f_central`: graded head-out immersion, posture change with
measured central or thoracic volume, and quantified total-volume perturbation at recorded
posture. The last of these is the ADR 0011 removal set, which is already extracted.

## Falsifiable test

**1. The posture gradient must fall out, not be fitted in.** With `f_central` set from
posture, the same absolute blood loss must cost more stroke volume seated than supine, in
the observed direction and of roughly the observed size. If a central partition cannot
produce a monotonic gradient in the right direction without tuning, the partition is not
the mechanism the gradient is evidence for.

Note this is a genuine prediction rather than a restatement: the gradient was measured
across three studies that had nothing to do with this model, and the direction is fixed
by the physiology, not by a free parameter.

**2. Immersion must produce natriuresis at constant total blood volume.** The current
model cannot do this at all - it has no way to express the perturbation. If the model
with a central compartment still cannot, then the natriuretic pathway is not keyed to
central volume either, and ADR 0010's premise fails on its input side for a second and
final time.

**3. Stage 1 must be bit-identical.** If fixing `f_central` at supine changes any
simulated result, the partition has been implemented as something other than a rescaling
and the implementation is wrong. This is a cheap and total check, and it should be run
before stage 2 touches anything.

## Consequences

**ADR 0011** changes on its input side only; its decomposition survives. Its Q3 finding
converts from a threat to the record into a **validation target** for this one.

**ADR 0010** should be revisited once this lands. Its blocker 2 was closed as falsified
and its blocker 4 written on the assumption that immersion is permanently unusable.
Neither survives this change unexamined. **Do not reopen it until stage 1 is implemented
and test 3 passes** - the point of the two-stage split is that the structure is proven
inert before anything is rebuilt on it.

**`check_closure.py`** gains at least the identity `V_central + V_peripheral = V_blood`.
It hand-codes seven relationships and does not scale past about twenty; this is the work
that starts filling it, and the handover's warning should be read as live from here.

**The ledger** gains one row for `f_central` at supine, unsourced at stage 1 and
pre-registered before stage 2.

**What it costs.** Every parameter sourced against `V_blood` as the filling variable is
now provisional. That is one parameter - `CV.VENOUS_RETURN.SENSITIVITY`, already
`calibrated` and already known to be the second most consequential unmeasured number in
the model. The bill for this change was mostly paid before it was proposed.

## What is NOT decided

- **The numeric value of `f_central` at any posture.** Pre-register before extracting.
- **Whether `f_central` responds to venous tone** as well as posture. It certainly does
  physiologically; whether this model represents that is a stage-2 question and depends on
  RAAS existing.
- **Whether the model gains a posture input at all.** Stage 1 does not need one.
- **Stressed versus unstressed volume, compliances, mean circulatory filling pressure,
  right atrial pressure.** The Guyton venous return formulation proper. This ADR is
  deliberately not that, and does not foreclose it.
- **Whether the nephron proximal/distal partition is also needed.** Rabelink 1989 says
  something is missing there too. Different organ, different decision, and it should not
  ride along on this one.
- **Whether the ADR 0011 posture gradient is real.** It is a between-study gradient with
  posture confounded with study, population and age. van de Velde 2018 (PMID 29016531)
  crosses a 500 mL phlebotomy with active standing in the same subjects and remains the
  within-subject test. **This ADR does not depend on that test passing** - Norsk alone
  establishes that redistribution at constant total volume drives a renal response - but
  falsifiable test 1 does.
