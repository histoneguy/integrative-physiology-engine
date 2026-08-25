# ADR 0012: A central/peripheral volume partition - the distinction the evidence keeps asking for

**Status:** Proposed
**Date:** 2026-08-24
**Evidence tier:** MIXED - E1, E2, E3. See the table and the correction below.

- **E1** - the existence of a central/peripheral blood volume distribution, its shift with
  posture, and the concavity of the Frank-Starling relation.
- **E2** - total intravascular volume does not grade the immersion natriuresis. Three
  independent human groups, converging by different designs.
- **E3** - the graded-depth result specifically, which is Norsk 1986 alone, n=10, single
  group. Retained as `STRUCTURE ONLY - no numeric value` under the ADR 0006 exemption.
- **NO TIER CLAIMED** for the quantitative partition fraction, which this ADR does not
  assert.

An earlier draft tiered the E3 row **E1**, and the ADR gate passed *because* of that.

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
| Posture shifts volume between them, peripherally when upright | E1 | standard cardiovascular physiology | human |
| Water immersion translocates volume centrally | E1 | standard; the premise of the whole immersion literature | human |
| **The Frank-Starling relation is CONCAVE over the physiological filling range** | E1 | standard cardiovascular physiology; textbook | human, mammalian |
| Cardiopulmonary receptors and atrial ANP release respond to CENTRAL filling | E1 | standard; the basis of ADR 0010's own premise | human, mammalian |
| Total intravascular volume does not grade the immersion natriuresis | **E2** | three independent groups, converging by different designs: Norsk 1986 PMID 3745047; Greenleaf 1980 PMID 6986349 (plasma volume falls 12.6% while natriuresis persists); Simanonok 1993 PMID 8431188 (response largely survives a 15% bleed) | human |
| Natriuresis grades specifically with immersion DEPTH at constant plasma volume | **E3** | Norsk 1986 alone, n=10, single group, graded to three depths | human |
| The numeric central fraction at any posture | **NOT ASSERTED** | requires a pre-registered search | - |

The E3 row contributes no state, component or numeric value to this record - it
motivates having a partition at all, and the partition takes no number from it. It is
retained as **`STRUCTURE ONLY - no numeric value`** under the ADR 0006 exemption, claimed
here deliberately rather than avoided by mislabelling.

### Correction, 2026-08-24: this table was wrong on its first draft

The row now tiered E3 was originally tiered **E1**, and `check_adrs.py` returned OK
*because* of that. ADR 0006 defines E1 as multiply replicated in humans and textbook
level, and puts single-group small-n at E3 with a default-off or structure-only
requirement. Norsk 1986 is one group of ten.

The gate did not fail to catch an error; it was **told** the wrong tier and had nothing
to check against. This is the same failure the ADR 0006 amendment was written about - a
tier line that protects a weakness instead of exposing it - occurring in the record that
cites that amendment. Recorded rather than quietly fixed.

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

**Narrowed, 2026-08-24.** An earlier draft of this section overclaimed, and did so by
failing to propagate its own correction. Having just separated Rabelink 1989 (a *nephron*
partition) from Norsk (a *vascular* one), it then treated the vascular fix as though it
unlocked immersion outright. It does not. There were two obstacles and this removes one:

- **The sensed-variable obstacle is removed.** Immersion perturbs central volume, and
  central volume is now a model variable with a receptor behind it.
- **The nephron-partition obstacle remains.** Rabelink showed volume expansion raises
  distal sodium delivery independently of ANP, and IPE still has no proximal/distal
  split. That is untouched here.

So immersion becomes usable for calibrating a **lumped** natriuretic term keyed to
`V_central`. It does not restore a mechanistic ANP pathway, and the term stays lumped for
exactly the reason ADR 0010 already gave. That is still a large gain - ADR 0010's revised
design is a lumped term - but it is one obstacle cleared, not two.

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

`f_central` is a parameter, constant in time within a run. **The model stays at 3
states.**

Filling-dependent quantities key off `V_central` rather than `V_blood`. Concretely this
revises ADR 0011's Decision on its input side only:

    SV ~ g(V_central)        # was a filling function of V_blood

**ADR 0011's `CO = HR x SV` decomposition is untouched and survives intact.** Only the
input variable changes. That record stays Proposed and carries a pointer to this one.

### `g` must be CONCAVE, and this is part of the decision, not a detail left downstream

Added 2026-08-24 after the first draft was checked against the evidence it claims to
explain. **The partition alone predicts the posture gradient backwards.**

    dSV/dV_blood  =  g'(V_central) * f_central

Upright posture pools volume peripherally, so `f_seat < f_sup`. With `g` **linear**,
`g'` is constant and the ratio of the two slopes is just

    (dSV/dV_blood)_seated / (dSV/dV_blood)_supine  =  f_seat / f_sup  <  1

The model would predict the seated response is **smaller** than supine. ADR 0011 measured
it as **2.76x larger** (28.00 against 10.16 mL/L). The sign is wrong, for any partition
fractions whatever - no choice of `f_central` rescues it.

What resolves it is that the seated operating point sits at **lower** central filling, so
on a concave curve its **local slope is steeper**. The requirement is

    g'(V_central,seated) / g'(V_central,supine)  >=  2.76 * (f_sup / f_seat)

Since `f_sup / f_seat > 1`, **the required curvature ratio is at least 2.76 and grows
with the size of the postural shift.**

Two things follow, and both are load-bearing.

**Concavity is not an extra assumption.** The Frank-Starling relation is concave over the
physiological range, and that is E1 textbook physiology. The partition and the curvature
are each independently well established; it is their *combination* that predicts the
gradient, and neither does it alone.

**This constrains ADR 0011.** That record explicitly left the functional form of the
filling relation undecided - "linear about the operating point, saturating, or
otherwise". This decides it: **linear is excluded.** The thing to source is a curve with
a specified shape over a specified range, not a slope, which is materially harder and
changes what `sv_filling_prereg.md` should ask for on its next revision.

### Why algebraic rather than a state

Translocation between compartments happens over seconds to minutes. The renal-body fluid
loop this model exists to demonstrate operates over days. ADR 0002 already made exactly
this call once - cycle-averaging removes fast modes at the modelling layer, before the
solver sees them - and the same reasoning applies one level up. A dynamic compartment
would be precision the surrounding model cannot support, and it would buy nothing the
quasi-static split does not.

### Land it in two stages, and the first stage is numerically inert

**Stage 1: `f_central` is a constant, set to its supine value for the baseline
protocol.** Every result of *that* protocol is unchanged to within solver reassociation,
because a constant input scaling is absorbed by reparameterising the filling function.
See falsifiable test 3 for why "unchanged" is not "bit-identical".

Note that this is **not** a linearity assumption, and it survives the concavity
requirement above: a constant input scale can be absorbed by reparameterisation for any
functional family closed under input scaling - linear, power-law, saturating alike.

**Constant in time is not the same as fixed at one value forever, and the distinction is
load-bearing.** An earlier draft ran the two together and then claimed stage 1 makes
immersion expressible. It does not, if `f_central` never varies - immersion *is* a change
in `f_central`. What stage 1 gives is a parameter that can be **set per protocol**: an
immersion run is the same model with a different constant `f_central` at unchanged
`V_blood`, which is exactly the perturbation IPE previously could not express. That works
because immersion is a sustained state and this model is cycle-averaged, so no dynamic
translocation is needed to represent it.

**Stage 2: `f_central` responds to posture** as a model input rather than a per-protocol
constant, and later to venous tone when RAAS lands. That is a modulator and belongs after
the spine, per directive 1.3.

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

**1. The curvature required to reproduce the posture gradient must be one the
Frank-Starling literature supports.** Rewritten 2026-08-24; the first version of this
test asked whether the gradient "falls out", and the answer is that it cannot, because
the partition alone predicts it backwards. The real test is quantitative:

    required  g'(V_central,seated) / g'(V_central,supine)  >=  2.76 * (f_sup / f_seat)

Source `f_sup` and `f_seat`, source the curvature of the filling relation, and check.
**If the curvature the gradient demands exceeds what the Frank-Starling literature
supports at these operating points, the partition is not the explanation for the
gradient** and the gradient needs a different one - venous tone, population differences
between the three studies, or the gradient not being real at all.

This is a test that can fail, which the first version was not. It is also a genuine
prediction rather than a restatement: the gradient was measured across three studies that
had nothing to do with this model, and both the direction and the required magnitude are
fixed before any parameter here is chosen.

Note the dependency this creates. Test 1 now needs `f_central` at two postures **and** a
sourced curvature, none of which exist. It is a stage-2 test and cannot be run at stage 1.

**2. Immersion must produce natriuresis at constant total blood volume.** The current
model cannot do this at all - it has no way to express the perturbation. If the model
with a central compartment still cannot, then the natriuretic pathway is not keyed to
central volume either, and ADR 0010's premise fails on its input side for a second and
final time.

**3. Stage 1 must not change behaviour.** If introducing `f_central` moves any simulated
result by more than solver reassociation, the partition has been implemented as something
other than a rescaling and the implementation is wrong. Run before stage 2 touches
anything.

> **CORRECTED 2026-08-24 ON FIRST IMPLEMENTATION. This test originally demanded
> BIT-IDENTITY, and that was an unachievable bar rather than a strict one.** Adding two
> equations changes what `structural_simplify` emits, so the generated code orders its
> arithmetic differently, the adaptive solver takes fractionally different steps, and the
> trajectories separate in the last few digits - even though the algebra is exactly
> equivalent. Measured on introduction: **2.1e-15 to 2.2e-14 relative on the three MAP
> levels, 3.5e-13 on the shift**, which is 1.7e-12 mmHg.
>
> The achievable and still-meaningful bar is agreement to **1e-9 relative**, which is what
> `test/runtests.jl` now asserts against the values recorded before the partition existed.
> That is eight orders of magnitude tighter than any physiological claim this model makes
> and still robust to a solver version bump.
>
> Recorded rather than quietly relaxed, because a test whose bar is lowered after it fails
> is worth nothing unless the reason is written down. The reason here is that the original
> bar was wrong on numerical grounds, not that the result was disappointing.
>
> **Both directions were then verified by perturbation rather than argued.** A 10% error in
> `G_vc` moves the MAP levels by 8e-5 relative - caught by this assertion easily, and
> caught independently by `check_closure.py`, so a broken partition fails two gates. And
> moving `f_central` from 0.25 to 0.30 with both derived values recomputed moves the shift
> by 3.7e-10 relative, confirming the partition is inert to the placeholder's value.
>
> One thing that finding exposed, and it was not anticipated: **0.25 is a power of two and
> therefore exact in binary**, which is why it deviates by 3.5e-13 where 0.30 deviates by
> 3.7e-10 - a thousandfold difference arising purely from representability. The margin
> between 3.7e-10 and the 1e-9 bar is only about 3x. When `f_central` is replaced by a
> sourced value at stage 2, this tolerance must be re-measured, not assumed to hold.

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

---

## Q3 outcome, 2026-08-24: confirmed in direction, and it brings a new problem

Extracted under `validation/q3_posture_prereg.md`, committed at `7d97d65` **before the
full text was opened**. Reproduce with `python validation/q3_posture_extract.py`.

**van de Velde L, Eeftinck Schattenkerk DW, Venema PAHT, Best HJ, van den Bogaard B,
Stok WJ, Westerhof BE, van den Born BJH.** *J Hypertens* 2018;36(3):544-551,
PMID 29016531, `10.1097/HJH.0000000000001583`. Green OA under the Taverne licence.
n = 31, within-subject, 500 mL over 15-30 min, 10 min supine then 5 min active standing,
before and after.

### The 2x2 exists, and posture modifies the response

| SV (mL) | before | after | change |
|---|---|---|---|
| supine | 69.5 ± 17.5 | 66.7 ± 18.2 | **2.8 mL** |
| standing | 55.2 ± 17.4 | 44.6 ± 14.9 | **10.6 mL** |

**R = 3.79**, against a pre-registered threshold of 1 for confirmation and 2.76 for
"partial". The direction is confirmed *within subjects* - study, population, age and
device are all removed from the comparison - and the magnitude **exceeds** the
between-study gradient rather than falling short. Standing is more upright than seated,
which is the direction the mechanism predicts.

**Falsifiable test 1 keeps its motivation. The concavity requirement stands.**

### The pre-registration's own bar is not met, and that is recorded rather than waived

Section 3 required `R > 1` *with the paper's own reported dispersion excluding 1*. That
cannot be computed. Table 2 reports SDs of the four cell means, not of the two paired
differences, and no paired correlation. Worse, the footnotes show the **supine phlebotomy
effect is not tested at all** - the asterisks mark posture contrasts and the last column
marks the phlebotomy effect *in standing*. So the numerator is significant at P < 0.001
and the denominator is untested: 2.8 mL against a cell SD near 18.

If the true supine response is near zero, `R` is unbounded rather than 3.79 - more
extreme in the confirming direction, so the finding survives. But **`R` is a point
estimate with no interval and must not be quoted as though it had one.** This is a fourth
outcome the pre-registration did not name; it anticipated dispersion *spanning* 1, not
dispersion being *unavailable*.

### The confirmation arrives attached to a mechanism this model has excluded

| HR (bpm) | before | after | change |
|---|---|---|---|
| supine | 66.0 | 65.2 | −0.8 |
| standing | 74.8 | 85.5 | **+10.7 (+14.3%)** |

The standing arm gains 10.7 bpm across the phlebotomy; the supine arm loses 0.8. Shorter
diastolic filling at the higher rate lowers stroke volume by itself, so part of the
10.6 mL is **rate-mediated rather than filling-mediated**.

The same comparison on cardiac output makes it sharp: `dCO_supine` 0.20 and
`dCO_standing` 0.30 L/min give **R_CO = 1.50 against R_SV = 3.79**. ADR 0011 holds `HR` a
parameter, so **with HR fixed those two numbers are identical by construction** and the
model cannot produce the divergence. A model with HR as a parameter cannot reproduce this
experiment even if the partition and the curvature are both right.

**What this does and does not do to ADR 0011.** It does not refute HR-as-parameter for
the perturbations that record was reasoning about - in *supine* phlebotomy HR moved
66.0 → 65.2, consistent with the three studies already cited there. It shows
HR-as-parameter fails **under orthostatic stress**, a paradigm ADR 0011 had already
excluded from calibration for an unrelated reason. That exclusion turns out to have been
protecting something real.

### What it does not establish

Per section 4 of the pre-registration, fixed in advance: **this does not establish that
the central/peripheral partition is the mechanism.** Standing moves venous tone and
sympathetic outflow as well as volume distribution. The result is *consistent with* this
ADR and does not select it over its rivals. It is the same error ADR 0010 made in reading
"identical to 2 litres of saline" as a claim about total volume.

### Checks the pre-registration demanded in advance

**Section 7, the measurement artefact: passes.** SV is Nexfin volume-clamp with
Modelflow - exactly the posture-sensitive family flagged before reading - but the hand was
maintained at **heart level** throughout, and the paper cites Modelflow CO as validated
against thermodilution under supine *and orthostatic* stress. The hydrostatic artefact
that could have manufactured `R > 1` is controlled.

**Contractility is stable** (`dP/dtmax` 399/436/413/445, no significant difference), which
Kumar 2004 had made a live worry.

**Population recorded:** patients on regular phlebotomy on medical grounds, mean age 57,
with 6 of 31 on cardioactive drugs including two on beta-blockers - which blunts exactly
the chronotropic response above.

**k = 1 and it stays k = 1. No ledger parameter is recorded**, per stop condition 3:
active standing is an excluded calibration paradigm under ADR 0011 and this
pre-registration did not lift that.
