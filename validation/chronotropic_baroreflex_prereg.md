# Pre-registration — the chronotropic arm of the arterial baroreflex

**Written 2026-09-08, before any source is opened and before any search has been run for
these values.** No abstract has been read. Verify the ordering with

    git log --diff-filter=A -- validation/chronotropic_baroreflex_prereg.md
    git log --diff-filter=A -- validation/chronotropic_baroreflex_extract.py

Opened at the owner's instruction as `OPEN-QUESTIONS.md` **C1**, the first item on
Section C's work list, and `HANDOVER.md` **§4 item 9**.

**Structure will be decided in ADR 0022, which does not yet exist.** §10 fixes the
falsifiable tests that record must inherit, so that they are written before the numbers
rather than after them — the discipline that made ADR 0021's test 3 catch a lethal
hyperkalaemia on its first run.

---

## 0. WHY THIS PASS EXISTS, AND WHAT ADR 0009 ALREADY DECIDED

**ADR 0009 gave the baroreflex one effector and said why.** The arms are lumped onto
total peripheral resistance because the model is cycle-averaged (ADR 0002), so heart rate
was not a variable and the vagal arm had nothing to act on. That record's own words:
*separating them buys nothing until heart rate exists*, recorded as an explicit
instruction not to re-separate them without a protocol that needs it.

**Heart rate now exists.** ADR 0011 split cardiac output into `HR0 * SV`, and
`Cardiovascular.jl` says on the line that does it that heart rate is a parameter *until a
chronotropic baroreflex exists, and a second effector is its own decision.* This is that
decision.

**THE ARM NULLS AT EVERY STEADY STATE AND THAT IS WHY IT WAS DEFERRED, NOT AN OVERSIGHT.**
The reflex resets: `D(sp) ~ (MAP - sp)/tau_reset`, so `sp -> MAP`, `err -> 0`, and every
effector modifier returns to 1 whatever its gain. A chronotropic arm therefore cannot move
the resting state, the 400-day steady state, chronic salt sensitivity, or the
pressure-volume ratio. **It is invisible to almost every assertion in the suite**, which is
§5 item 23 — a model can be right at every steady state and wrong about every transient —
and it is the reason §8 and §10 are written around transients rather than around pins.

---

## 1. THE QUANTITIES

| id | what | role |
|---|---|---|
| `BR.CARDIAC.SENSITIVITY` | cardiac baroreflex sensitivity in healthy resting adults, ms/mmHg | **the sourced row** |
| `BR.CARDIAC.GAIN` | dimensionless chronotropic gain the model consumes | **derived** from the above, `HR0` and `MAP_ref` |
| `BR.HR.MAX_FRACTION` | saturation bound on the fractional heart-rate excursion | bounds the characteristic |
| `BR.CARDIAC.TAU` | vagal effector time constant | entered **only if** §5 builds a lag |
| — | whether `BR.OPEN_LOOP_GAIN` is the whole reflex or the vasomotor arm alone | **decides whether this pass may proceed at all** — §6 |

**SOURCE THE MILLISECONDS, DERIVE THE GAIN.** Baroreflex sensitivity is reported in
ms/mmHg because what is measured is the lengthening of the cardiac interval against a
pressure ramp. The dimensionless gain is what this model consumes and is measured by
nobody. Entering the measured quantity and deriving the consumed one is the dependency
direction §3.6 established and §3.26, §3.29 and §3.31 have each repeated; the reverse
would put an unmeasured number in the `reported` column.

**`BR.CARDIAC.GAIN` IS SEXED WHETHER OR NOT THE SENSITIVITY IS**, because it is derived
through `CV.HR.NOMINAL`, which is a 62/65 pair. If a sexed sensitivity is also found, the
two dimorphisms are independent facts and compose; neither may be presented as evidence
for the other.

---

## 2. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults, awake, **resting**, supine or seated, sea level, no
cardioactive medication, not pregnant, normal sinus rhythm. Record n, sex, age, posture,
and — the field this pass turns on — **the method by which the sensitivity was measured.**

**Exclude:** heart failure, myocardial infarction and the post-infarction period,
hypertension, diabetes with autonomic neuropathy, syncope and dysautonomia cohorts,
athletes as a selected group, anaesthesia, critical illness, exercise, head-up tilt as the
measurement condition, and any cohort selected on autonomic abnormality.

### 2.1 THE METHOD IS PART OF THE QUANTITY, AND TWO METHODS MEASURE DIFFERENT THINGS

**Pharmacological ramp (the Oxford method — a pressor or depressor bolus, sensitivity read
as the slope of cardiac interval on pressure) is the PREFERRED and presumptively
admissible method.** It perturbs arterial pressure by tens of mmHg over tens of seconds,
which is a timescale this cycle-averaged model can represent at the 1 s sampling ADR 0002
fixes inside a challenge window.

**Spontaneous-sequence and spectral (alpha-index) baroreflex sensitivity are a different
quantity and may not be substituted.** They are computed from **beat-to-beat** interval
and pressure fluctuations, and ADR 0002 states in terms that this model cannot represent
heart rate variability, respiratory sinus arrhythmia, Mayer waves, or any spectral or
beat-to-beat measure, and that protocols whose endpoint is one of those are out of scope.
**A sequence-method sensitivity is a slope fitted to fluctuations the model does not
have.** Entering one as the gain of a reflex arc the model does have would be a different
quantity wearing the right name — the `ScvO2`-for-`SvO2` error named in
`venous_saturation_prereg.md` §2 and the free-thyroxine-assay error of §3.26.

**This is a declared position and it may be wrong.** If the literature establishes that
the two methods measure the same arc and agree within their dispersion, that is a finding
and branch **C6** takes it. What is forbidden is discovering that after seeing which
method gives the convenient number.

**Neck-chamber (variable-pressure neck collar) studies stimulate the carotid
baroreceptors in isolation** and give a carotid-cardiac gain, not a whole-reflex gain.
Record separately; do not pool with either of the above.

**DIRECTIVE 1.7 WILL BITE HERE FOR THE EIGHTH SUBSYSTEM AND IT IS PREDICTED IN ADVANCE.**
Baroreflex sensitivity is measured overwhelmingly as a **prognostic marker** — depressed
sensitivity after myocardial infarction predicts mortality, and that is why the
measurement exists in most of the literature. There the relationship is the *instrument*
and the cohort is selected on disease. Ask of every candidate the directive's own
question: if the physiology had come out differently, what would this paper's conclusion
have been? Where the answer is *the marker would not have stratified risk*, the paper is
about the marker. **Prefer normative studies whose subject is the reflex in health.**

**AND OTHER WHOLE-BODY MODELS ARE NOT SOURCES.**

---

## 3. WHAT IS ALREADY KNOWN, DECLARED SO THE FREEDOM IS AUDITABLE

**One candidate source is already named in the repository and I have not opened it.**
`HANDOVER.md` §4 item 9 records, from a previous session: *Best normative source found:
Schumann 2024, Am J Physiol Heart Circ Physiol 326:H158–H165, n=980 healthy, and it is
about sex differences in BRS.* **That is a name in a handover, not a reading.** Directive
1.5 forbids writing a citation I have not opened, and §5 item 20 records twice what
happens when a previous session's sentence about a paper is inherited instead of tested —
the renin gain sat `assumed` for six days behind exactly such a sentence, and the paper
said the opposite. **It is a starting point for the search and carries no standing until
opened.** Its method (§2.1) is unknown to me and decides its admissibility.

**Nothing else about the value has been looked at.** No abstract, no record, no number.

**What IS known, because it is in the ledger and in this model's own arithmetic, is the
conversion factor and the fact that it makes the double count possible** — §6 and §7. That
is declared here rather than presented later as a discovery, because it is the reason this
pass has a stop condition at all.

---

## 4. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED IN ADVANCE

Baroreflex sensitivity **15 ms/mmHg**. The clinical cutoff **6 ms/mmHg**. Resting heart
rate **72 beats/min**. Cardiac interval **1000 ms**. Vagal latency **0.5 s**. Open-loop
gain **2.0** — which is already in this ledger, tier B, from an animal preparation.

**All six are teaching or threshold numbers.** The 6 ms/mmHg figure is the sharpest case:
it is a **prognostic stratification cutoff**, chosen to separate risk groups after
infarction, and it is not a measurement of anything in health. This repository's record on
round numbers is four materially wrong of six openable in the `VERIFY` class, six of eight
in the blood-gas pass, and the metabolic-equivalent convention overturned by the paper
whose title was the row's own subject. **None is enterable without a source, and where a
measured value turns out to be the round one, the source is what makes it enterable.**

---

## 5. THE FORM

**The effector is multiplicative on heart rate, mirroring `tpr_mod`:**

    HR      = HR0 * hr_mod
    hr_mod  = 1 + hr_drive
    hr_drive ~ -sat_hr * tanh(G_hr * err / (sat_hr * MAP_ref))

with `err` the **same** `MAP - sp*cv_mod` the vasomotor arm already computes. One error
signal, two effectors, which is what one reflex with two efferent limbs means.

**THE SIGN IS NEGATIVE AND IT IS ASSERTED, NOT ASSUMED.** A rise in pressure stretches the
baroreceptors, raises afferent firing, raises vagal outflow and withdraws cardiac
sympathetic drive, so **heart rate falls.** ADR 0009's addendum records that the vasomotor
arm shipped with this sign inverted and produced a mean arterial pressure of 40 mmHg. §10
requires the falsification run — invert the sign, confirm the model misbehaves, revert.

**NO NEW STATE. The default form is ALGEBRAIC and the burden is on adding the lag, not on
omitting it.** The vagal effector acts in 200–600 ms against a vasomotor 2–3 s and a
shortest protocol of six hours. Respiration and blood gas were both built without a state
for the same reason and directive 1.10 is why: a state is paid for on every future run,
forever. This model has nine states and has added exactly one deliberately.

**If a lag is built it must be because a protocol needs it**, and then `BR.CARDIAC.TAU`
is entered with the La Rovere latency and the relation carries `form_status` recording
that first-order is the simplest form producing that delay — the honest label
`Baroreflex.D(tpr_mod)` already carries.

**Stroke volume is NOT re-derived.** `Cardiovascular.SV` keeps its filling dependence and
its `HR0` denominator unchanged. Making the stroke-volume relation read the modulated heart
rate would introduce a force-interval or filling-time coupling that nothing here sources,
and it would silently change what `CV.SV.NOMINAL` means. **`CO ~ HR0 * hr_mod * 1440 * SV /
1000` and nothing else moves.**

---

## 6. THE CENTRAL RISK: IS THE EXISTING GAIN THE WHOLE REFLEX?

**This decides whether the pass may proceed, and it is checked FIRST, before any
sensitivity is entered.**

`BR.OPEN_LOOP_GAIN` = 2.0 is named *"Sympathetic arterial baroreflex open-loop gain"* and
comes from Yamasaki 2021, an integrative framework built on vascularly isolated
baroreceptors. **If that 2.0 is the open-loop gain of the WHOLE arterial baroreflex, then
adding a second effector with its own gain does not extend the model — it doubles the
reflex.** §7 shows the two gains are of the same order, so this is not a rounding concern.

**The word "sympathetic" does not settle it**, because heart rate carries a sympathetic
limb as well as a vagal one. What settles it is what Yamasaki's framework takes as its
output variable: a vasomotor outflow, a total peripheral resistance, or an arterial
pressure.

**AND THIS IS §5 ITEM 22 BEFORE IT HAPPENS RATHER THAN AFTER.** That entry records
`CV.ANP.NATRIURETIC_GAIN` and `RN.PRESSURE_NATRIURESIS.SLOPE` being re-estimated by being
given a second path to the quantity they were fitted against, with **no value changed and
no gate able to see it** — found only by an acute challenge, 2.8% outside a band. A second
effector into arterial pressure is precisely that move. It is written here, before the
implementation, because that is the only place a check like this is cheap.

---

## 7. THE MEASUREMENT-SCALE PROBLEM, AND IT IS TWO PROBLEMS

### 7.1 Milliseconds per mmHg is not a dimensionless gain

The conversion is exact and uses only rows already in the ledger. With `RR = 60000/HR`,

    d(HR)/dP        = -(HR^2 / 60000) * BRS
    (1/HR) d(HR)/dP = -(HR / 60000) * BRS
    G_hr            =  (HR0 * MAP_ref / 60000) * BRS

so at `HR0` = 62 and `MAP_ref` = 87 the factor is **0.0899 per (ms/mmHg)** for men and
0.0943 for women.

**THIS IS WHY §6 IS THE STOP CONDITION.** Any cardiac sensitivity in the ordinary range
of that literature produces a dimensionless gain of the **same order as the 2.0 already
in the ledger.** No number is asserted here — the range is exactly what the search is for
— but the *order* follows from the conversion factor alone and can be stated before any
source is opened. A second arm of comparable gain is not a refinement.

**The reciprocal is nonlinear and the conversion is therefore a LOCAL one**, valid at the
operating heart rate. `pooling.md` requires two rows to share a measurement scale and not
merely a unit symbol (§5 item 18); this conversion is the point at which that is either
honoured or quietly broken, and it must be written into the derived row's note rather than
into a comment.

### 7.2 An intact-human sensitivity is CLOSED loop and 2.0 is OPEN loop

A pharmacological ramp in an intact person is measured with the reflex operating. A
vascularly isolated baroreceptor preparation is measured with it opened. For a negative
feedback loop of open-loop gain `G`,

    G_closed = G_open / (1 + G_open)

so a measured intact sensitivity **understates** the open-loop gain by a factor of one
plus the total loop gain — and the total includes the vasomotor arm. **Entering a
closed-loop cardiac sensitivity into a model position occupied by an open-loop vasomotor
gain composes two quantities that do not share a scale**, which is the error §3.26 records
costing a 2.2-fold hormone level and a confident, wrong decomposition.

**Whether the correction should be applied is not decided here**, because applying it
requires knowing the total loop gain, which is what §6 is trying to establish. What is
decided here is that **the two cannot simply be placed side by side**, and that a pass
which does so has failed whatever number it produces.

---

## 8. WHERE THE ARM CAN ACTUALLY BE TESTED, FIXED BEFORE IT IS BUILT

Because the arm nulls at every steady state (§0), a passing suite is **no evidence
whatever** about it — §5 item 3. The transient tests, in order of value:

1. **A pressure ramp run inside the model.** Step or ramp arterial pressure by a declared
   amount and read the heart-rate response. This reproduces the Oxford paradigm *in
   silico* and is the only test that speaks directly to the sourced quantity. It requires
   no new protocol machinery beyond a declared perturbation and is **the primary test.**
2. **The existing acute saline challenges.** Lobo and Jensen raise blood volume, so
   central volume, stroke volume, cardiac output and pressure all rise, `err` goes
   positive, and the arm must **lower heart rate and buffer the pressure rise.**
3. **Does either report heart rate?** Jensen 2013 is open access. **If it reports a heart
   rate time course, that is an out-of-sample transient test for this arm** and it is the
   most valuable thing this pass could find. Established by looking, not assumed.

### 8.1 THE ARM WILL MOVE B9, AND THAT IS A TRAP WRITTEN DOWN IN ADVANCE

Buffering the pressure rise reduces `G_pn * (MAP - MAP_ref)`, which is the pressure
natriuresis term, so **the model should excrete less sodium over Lobo's six hours.**
`OPEN-QUESTIONS.md` B9 records the two Lobo endpoints failing **2.8% and 1.7% high**.

**So this arm moves them toward their bands, and it must not be allowed to close B9.**

- The gain comes from its own sourcing and from nothing else. It may not be chosen,
  rounded, or bounded to bring an endpoint inside a band.
- **`RN.MD.RENIN_GAIN` may not be re-solved in this pass.** B9's bound is a measurement of
  a missing renal sympathetic arm (ADR 0021 decision 7); re-solving it against a limb this
  pass has just moved would absorb one missing mechanism into a parameter that already
  absorbs another.
- If the endpoints move, **the movement is reported as a magnitude** — how much of B9's
  excess was missing chronotropic buffering — and B9 is updated to say so, not closed.

**§3.37 is the precedent and it is exact.** A cheap adjustment that lands a model on a
convention is the most dangerous kind, and *the fix being nearly free is the warning sign,
not the reassurance.* If this arm makes two red lines green, that is the moment to
distrust it hardest.

---

## 9. THE DECISION RULE

- **C1 — an admissible normative pharmacological-ramp sensitivity in healthy adults is
  found, AND §6 resolves that the existing 2.0 is the vasomotor arm alone.** Build the
  arm, enter both rows, write ADR 0022 with §10's tests, run every test in §8. This is the
  clean branch.
- **C2 — the sensitivity is found and §6 resolves that 2.0 is the WHOLE reflex.** **The
  arms must SPLIT that gain, not add to it.** The split fraction is then itself a quantity
  needing a source. If it cannot be sourced, **the arm is NOT built**, and the finding —
  that this model's single lumped gain already contains the cardiac limb — is recorded
  against `BR.OPEN_LOOP_GAIN` and in ADR 0009, which currently reads as though the cardiac
  limb is simply absent.
- **C3 — §6 cannot be resolved from what can be opened.** The arm is **not built.** An
  ambiguity of this kind is worse than a missing number — §3.24's finding on the thyroid
  logarithm, which looked sourced, carried a real citation and would have been wrong by
  2.3× silently. Record the ambiguity, enter nothing, ADR 0022 stays Proposed.
- **C4 — only sequence-method or spectral sensitivities are admissible-looking.** Do not
  substitute (§2.1). Record what was found, state that ADR 0002 puts the quantity out of
  scope, and stop. **Record the exact search terms**, because §3.33 is what happens when a
  failed search is written up as a fact about the literature — and ask before recording it
  whether the term is the one the people who did the work would have used.
- **C5 — every admissible value is in a post-infarction or risk-stratification cohort.**
  Directive 1.7 disqualifies them as the relationship is the instrument. **Record as
  INDETERMINATE**, exactly as the fluid-deprivation comparison and B8 stand, and do not
  enter a value from the least-bad diseased cohort.
- **C6 — the methods are established to agree.** If a source directly compares ramp and
  sequence sensitivities in the same healthy subjects and they agree within dispersion,
  §2.1's exclusion is amended in this file with the evidence, and the wider literature
  becomes admissible. **Amend the text, do not quietly widen.**
- **C7 — the arm is built and changes nothing measurable in any protocol the model can
  run.** Then it is a parameter, a coupling and a relation bought for no representable
  consequence, and directive 1.10 says say so. **Report it as such** rather than as a
  completed subsystem — but do **not** delete it, because the null result *is* the finding
  that the model's acute protocols are too gentle to exercise the cardiac limb, and that
  belongs in the record alongside the monoculture criticism §7 of `HANDOVER` already makes
  of the acute evidence base.

---

## 10. THE FALSIFIABLE TESTS ADR 0022 MUST INHERIT

Fixed here so they are not written after the numbers.

1. **Every steady state is BIT-IDENTICAL.** Resting values, the 400-day drift, chronic
   salt sensitivity, `dMAP/dV_ecf`, every pinned number. Not close — identical. The reflex
   resets, so `err -> 0` and `hr_mod -> 1` exactly. **If any pinned steady-state number
   moves, either the reset path is broken or the arm has been wired into something that
   does not null**, and this is ADR 0009's own falsifiable test applied to the second
   effector.
2. **The sign.** Raise pressure, heart rate must fall. Invert the sign and the model must
   misbehave visibly. Run it.
3. **The arm must be FAST.** Its response is complete on a timescale of seconds, and
   faster than the vasomotor arm's 3 s.
4. **Cardiac output must fall when heart rate falls**, with stroke volume unchanged at
   fixed filling — the ADR 0011 identity holding through the new multiplier.
5. **The magnitude of the buffering is reported against the pressure ramp of §8.1**, and
   is a prediction of the sourced gain rather than a target.

**Test 1 is the cheap one and tests 2–5 are the ones that can fail.** A record whose only
test is test 1 has tested nothing, which is what §5 item 3 says and what §3.32 demonstrated
by passing 676 tests on a form that doubled an acute natriuresis.

---

## 11. WHAT THE ANSWER MAY NOT DO

- **It may not change `CV.HR.NOMINAL`, `CV.SV.NOMINAL`, or `CV.CO.NOMINAL`.** One change
  at a time. A resting heart rate re-sourced inside this pass would move cardiac output and
  every derived cardiovascular row with it, and nothing here would be separately testable.
- **It may not re-estimate `RN.MD.RENIN_GAIN`, `CV.ANP.NATRIURETIC_GAIN`,
  `RN.ANP.TAU` or `RN.PRESSURE_NATRIURESIS.SLOPE`** — §8.1.
- **It may not silently leave `BR.OPEN_LOOP_GAIN` at 2.0 if §6 resolves it as
  whole-reflex.** Branch C2 governs, and leaving it is the double count.
- **It may not enter a sequence-method or spectral sensitivity as this row** without
  amending §2.1 in this file, with evidence, under C6.
- It may not enter a value from an abstract where the full text is obtainable, and must
  **label the reading level of every source** — a lesson the thyroid axis paid for twice,
  once by being blocked on a paper that was free the whole time.
- It may not add more than one state, and the burden is on adding any (§5).
- **It may not report the arm as validated by a passing test suite.** The suite cannot see
  it (§0). Only §8's transients can.
- It may not quote agreement to more figures than the source's dispersion supports.

---

## 12. WHAT WOULD MAKE THIS PASS A FAILURE

**Building a second effector that doubles the reflex gain, and having every test pass.**
Test 1 of §10 would still be green, because both arms null at steady state and the
double count lives entirely in the transient. The five gates would be clean: the ledger
parses, the relations carry citations, the closure identities hold, the ADR has a tier and
a test. **Not one thing in this repository except a run of `validation/challenges.jl`
could see it**, and that harness is not in CI.

That is §5 item 22 exactly, and §6 exists to stop it. **A pass that enters a beautifully
sourced cardiac sensitivity without first settling what the existing gain measures has
produced a worse model with better provenance.**
