> # VOIDED AND UNEXECUTED — 2026-09-17
>
> **This pre-registration was written against a stale number and must not be executed as
> written.** It states that the model is at **+79.3%** against Jensen 2013's +123% and
> treats closing that deficit as its purpose. **There is no such deficit.** Measured like
> for like on Jensen's own 210–240 min window the model is at **+110.1%** against a
> measured **+122%** — see HANDOVER §3.45, which also records that the +79.3% figure was
> twelve days stale and that the comparison behind it set a model PEAK against a study's
> FINAL SAMPLE.
>
> **It is committed rather than deleted for three things it contains that survive:**
> Alexander 1972 (PMID 4639021) and its human acute/chronic segmental asymmetry; the
> §5.1/§3.4 algebra showing what is and is not identifiable in this model; and the record
> that two passes were pre-registered before anyone ran the thing they were about, which
> is directive 1.11's failure in its clearest form.
>
> **Nothing in it was executed. No value it proposes entered the ledger.**

> Its §5.3 prediction — that the segmental split would land on branch S4 — is
> therefore an UNTESTED recorded prediction, not a result.

# Pre-registration — segmental regulation of tubular sodium, and the acute/chronic asymmetry

**Written 2026-09-17, before the model is changed, before any gain is re-solved, and
before the two-segment form has been run even once.** Verify the ordering with

    git log --diff-filter=A -- validation/segmental_regulation_prereg.md
    git log --diff-filter=A -- validation/segmental_regulation_extract.py

Opened under the owner's standing instruction to finish the cardio-renal relationships,
and under the constraint the previous pass wrote into its own commit message: *"What the
tubule needs is segmental STRUCTURE — regulators acting where they act — and that needs
its own pre-registration because it moves `G_anp` and `G_pn`, which this one forbids."*

`validation/nephron_segments_prereg.md` §3 forbids moving those two rows. **This document
is the separate pass that is allowed to, and it inherits every other prohibition in that
file.**

---

## 0. THE MODEL'S SODIUM EXCRETION IS A SUM WHERE THE PHYSIOLOGY IS A PRODUCT

`Renal.jl` has **one** lumped tubule:

    FR_effective ~ clamp(1 - (1 - FR_Na)*renal_mod + fr_mod
                           - G_pn*(MAP - MAP_ref)/Na_filtered
                           - anp_sig/Na_filtered, 0, 1)
    Na_excr      ~ Na_filtered * (1 - FR_effective)

Four regulators — the circadian modifier, the RAAS tubular increment, pressure
natriuresis and the volume-keyed natriuretic path — are **added into the same fraction**,
so the model cannot distinguish a proximal from a distal natriuresis. Fractional sodium
excretion is `1 - FR_effective`, **a difference.**

In a segmented nephron it is a **product**. With `p` the fraction of the filtered load
reabsorbed before the diluting segment and `d` the fraction of what arrives there that is
reabsorbed beyond it,

    FE_Na = (1 - p)(1 - d)

**The two forms are not the same model and they do not respond the same way**, because in
the product each segment's natriuretic effect is multiplied by the *other* segment's
escape fraction, which is small. A given percentage-point fall in distal reabsorption buys
far more fractional excretion than the same fall proximally. **An additive model cannot
reproduce that, at any parameterisation.**

## 0.1 AND THE REPOSITORY ALREADY WROTE DOWN THAT THIS WAS THE GAP

`RN.GFR.VOLUME_SENSITIVITY`'s own ledger note, on the Jensen shortfall:

> *"The model therefore excretes MORE sodium and reports a SMALLER fractional rise.
> Whether that is right depends on glomerulotubular balance, **which this model does not
> represent, and nothing here sources it**."*

**That is §3.19's shape for the third time** — the earlier search missed it by looking for
the wrong object. It searched for *glomerulotubular balance*. The instrument that decides
this is **human segmental clearance during volume expansion**, and it has existed since
1972.

---

## 1. THE SOURCE, AND IT MEASURES THE ASYMMETRY DIRECTLY IN MAN

**Alexander EA, Doner DW Jr, Auld RB, Levinsky NG. Tubular reabsorption of sodium during
acute and chronic volume expansion in man. J Clin Invest 1972;51(9):2370-2379.
doi:10.1172/JCI107049. PMID 4639021. PMC292404.**

**ABSTRACT READ IN FULL AND QUOTED FROM. THE FULL TEXT IS SCANNED PAGE IMAGES** on both
PMC and jci.org and could not be transcribed, so **the number of subjects, the control-
period baselines, the infusion rate and the mineralocorticoid protocol are NOT KNOWN TO
THIS PASS** and no row may imply otherwise. Directive 1.5 in its narrow form: what was
opened is the abstract, and the citation must say so.

Method, as the abstract states it: `(1 - V/GFR) x 100` as an index of **proximal**
fractional sodium reabsorption and `(C_H2O/V) x 100` as an estimate of **distal**
fractional reabsorption.

| manoeuvre | proximal FSR | distal FSR |
|---|---|---|
| acute isotonic saline, 37 mL/kg | **-4.8%** | **-4.4%** |
| chronic mineralocorticoid expansion ("escape") | **-3.9%** | **NOT ALTERED** |
| progressive to 57 mL/kg, "excreters" | -7.1% | -14.8% |
| further to 80 mL/kg, "excreters" | -0.9% more | -4.9% more |
| progressive to 57 then 80 mL/kg, "nonexcreters" | not significant | -4.5%, then -1.3% more |

Its conclusion, verbatim: *"both acute and chronic extracellular expansion decrease
proximal FSR in man, but only acute loading depresses distal FSR."*

**THAT SENTENCE IS THE WHOLE PASS.** This model's sodium limb was estimated against
**chronic** data — `CV.ANP.NATRIURETIC_GAIN` was solved for a chronic salt sensitivity of
2.00 mmHg per 100 mmol/day, and `RN.PRESSURE_NATRIURESIS.SLOPE` is calibrated. Alexander
says the chronic manoeuvre exercises **only the proximal segment**. So a lumped model
tuned on chronic data is missing precisely the arm that acute loading recruits — which
predicts, **before anything is run**, both the *direction* and roughly the *size* of the
model's acute shortfall.

### 1.1 The segmental assignment of each regulator, fixed here

| model term | segment | why |
|---|---|---|
| `G_pn`, pressure natriuresis | **proximal** | renal interstitial hydrostatic pressure, NHE3 retraction from the apical brush border, paracellular backleak in proximal tubule and loop. Ivy JR, Bailey MA. *Pressure natriuresis and the renal control of arterial blood pressure.* J Physiol 2014;592(18):3955-3967. AND Alexander: the chronic manoeuvre depresses proximal FSR |
| `fr_mod`, the RAAS tubular increment | **distal** | aldosterone acts on ENaC in the distal nephron. It already escapes to zero at steady state in this model, which is Alexander's "only acute loading depresses distal FSR" |
| `anp_sig`, the volume-keyed path | **distal** | amiloride-sensitive conductive sodium entry in the inner medullary collecting duct |
| `renal_mod`, circadian | **unsegmented, unchanged** | no segmental data was found and none is invented |
| GFR and filtered load | **upstream of both, unchanged** | |

### 1.2 THE ANP ASSIGNMENT IS THE RISKY ONE, AND THE FALLBACK IS FIXED NOW

Alexander's chronic manoeuvre is **mineralocorticoid escape**, in which ANP is elevated
and distal FSR is nevertheless unaltered. Two readings, and **an abstract cannot decide
between them**: either the distal segment is clamped by exogenous mineralocorticoid so the
experiment is blind to a distal natriuretic effect, or the chronic natriuresis of escape
genuinely is proximal.

**So the fallback is pre-registered rather than chosen after the numbers appear.** If the
chronic salt sensitivity cannot be recovered inside 1.70-2.30 with ANP distal at any
`G_anp` in its stated 500-900 range, **ANP moves to the proximal segment**, the run is
repeated, and the pass reports that Alexander's escape experiment decided it. It may not
be split fractionally between segments — that would be a new free parameter, which §8
forbids.

---

## 2. WHAT IS ALREADY KNOWN, DECLARED SO THE FREEDOM IS AUDITABLE

- **The target, verified today rather than inherited.** Jensen JM, Mose FH, Bech JN,
  Nielsen S, Pedersen EB. BMC Nephrol 2013;14:202. PMID 24067081, PMC3849534, open access.
  23 healthy subjects, 0.9% saline **23 mL/kg over 60 min**. Table 3, FE_Na in the
  isotonic arm: **1.26 (0.53) -> 2.80 (0.75) %**, and the paper's own text says
  *"FE_Na increased (123%)"*. 2.80/1.26 = 2.22. **The repository's +123% is correct.**
- The model predicts **+79.3%** today.
- Chronic salt sensitivity is **1.97** mmHg per 100 mmol/day; the human window is
  1.70-2.30.
- `dMAP/dV_ecf` is 3.2185 against the corrected human band **2.82-4.02** (§3.44).
- **AN ARITHMETIC I HAVE ALREADY DONE, AND IT IS NOT A PREDICTION OF JENSEN.** Taking
  `p = 0.90`, a baseline FE_Na of 1.26% implies `1 - d = 0.126`. Applying Alexander's
  acute deltas gives `(0.148)(0.170) = 2.52%`, **+100%**. That is at **37 mL/kg** against
  Jensen's **23**, in different subjects, so it is not a forecast of Jensen's number — it
  is a demonstration that the **multiplicative structure reaches the right order** where
  the additive one returns +79%. Written down here so it cannot be presented later as a
  result.
- **NOT known:** what the two-segment model actually does. It has not been run.

---

## 3. WHAT MAY NOT MOVE

- **`RN.NA.FRACTIONAL_REABSORPTION` stays DERIVED** to close sodium balance at the
  reference. The segment split is a decomposition of a quantity the model already has.
- **`RN.GFR.NOMINAL`, `BF.NA.PLASMA_SETPOINT`, `BF.NA.INTAKE_NOMINAL`.**
- **`RN.MD.RENIN_GAIN` may not be re-solved.** Its degeneracy with the delivery fraction
  is what the previous pass broke, and re-fitting it here would put the composite straight
  back — `nephron_segments_prereg.md` §8, inherited.
- **`RN.NA.MACULA_DENSA_FRACTION` may not be re-solved to make the split work.** It was
  proved inert in the lumped model; if the split makes it live, that is a **finding to
  report**, not a licence to fit it.
- **JENSEN 2013 MAY NOT ENTER ANY ESTIMATION, IN ANY FORM.** `G_anp` is re-solved against
  its own target — a chronic salt sensitivity of 2.00 — and `G_pn` against its own
  calibration set, both unchanged from what those rows already cite. Jensen is read out
  **afterwards** and never read in. Spending the only out-of-sample datum in the sodium
  limb on a fit is how this line loses its one test.
- **`RN.ANP.TAU` may be re-solved against Lobo's 6 h time course and against nothing else.**
- **The chronic salt sensitivity must stay inside 1.70-2.30.**

---

## 4. DIRECTIVE 1.12 — THE ROUND NUMBERS, AND ONE THAT IS A SENTENCE

**67%** proximal, **25%** loop, **5%** distal convoluted, **3%** collecting duct, **99%**
whole-nephron, **90%** pre-macula-densa. Teaching figures, taught as a set that sums to
100, and this repository's record on such numbers is four materially wrong of six openable.

**And the hazard that is not a number: "ANP acts on the collecting duct."** It is a
textbook sentence, it is quoted far more often than any quantitative share of the
natriuresis is measured, and §1.2 above turns on it. It is used here to assign a
**segment**, never to assign a **magnitude**.

---

## 5. THE STRUCTURE ADDS NO FREE PARAMETER, AND THAT IS A HARD CONSTRAINT

`d` at the reference is **derived** from the two quantities the model already has:
`f_md` fixes `p`, and sodium balance at the reference fixes the product. Nothing is
estimated to create the second segment. The regulators keep **the same ledger rows**,
re-solved against **the same targets**.

**If the split cannot be made to work without a new free parameter, the pass stops and
says so.** A structural improvement bought with an extra degree of freedom is not a
structural improvement, and §5 item 22 is the failure mode.

### 5.1 THE ALGEBRA SAYS THE OBVIOUS SPLIT IS A RE-PARAMETERISATION, AND THAT IS WRITTEN DOWN HERE RATHER THAN DISCOVERED HALFWAY THROUGH

**Done on the EXISTING model, before the segmented one has been run.** Closure gives
`d` with no new parameter: `(1 - p0)(1 - d0) = 1 - FR_Na`, so at `p0 = f_md = 0.90` and
`FR_Na = 0.9919`, `1 - d0 = 0.081` and `d0 = 0.919`.

Now push each regulator through. The model's gains are **absolute** — `G_pn` is in
(mEq/day)/mmHg and `anp_sig` in mEq/day — so:

- **ANP applied distally** as `d = d0 - anp_sig/Na_distal` yields an excretion increment of
  exactly `anp_sig`. **Unchanged from today.** `G_anp` barely moves.
- **Pressure applied proximally** as `p = p0 - G_pn*dMAP/Na_filtered` yields an excretion
  increment of `(1 - d0) * G_pn * dMAP` — **damped by a factor of 12**, because a
  fixed-fraction distal segment reabsorbs 92% of any extra delivery handed to it. `G_pn`
  would have to be re-solved from 8.4 to roughly 104 to restore the chronic steady state.

**AND THEN THE STEADY STATES ARE IDENTICAL.** Same absolute increments, same `Na_excr`,
same `FE_Na`. What the product form adds over the sum is only the **cross-term**
`Na_filtered * d(1-p) * d(1-d)` — real, but on Alexander's acute deltas it is 13% of the
response: **+128% against the additive +102% on the same inputs.** The model needs to go
from +79% to +123%. **The cross-term alone will not get there.**

**SO THE FIXED-FRACTION SPLIT IS LARGELY A RE-PARAMETERISATION, AND BRANCH S4 IS THE LIVE
OUTCOME, NOT THE UNLIKELY ONE.**

### 5.2 WHAT THE PHYSIOLOGICAL CONTENT OF SEGMENTATION ACTUALLY IS, AND THE ONE PARAMETER IT NEEDS

A fixed-fraction distal segment compensates for 92% of any rise in delivery. **The real
distal nephron does not**, and that incompleteness *is* the physiology of segmentation.
Alexander measures it: in the "excreters", distal FSR fell **14.8%** while proximal FSR
fell 7.1% — increased delivery **itself** suppressed fractional distal reabsorption.

Representing that needs one sensitivity of distal fractional reabsorption to delivery.
That is a new parameter, which §5 forbids **unless it is sourced rather than fitted to the
endpoint being predicted.** It can be, and the split is fixed **now**:

- **ESTIMATION SET — Alexander's progressive arm only**, `E1` at 57 mL/kg and `E2` at 80
  mL/kg, excreters and nonexcreters. That is where delivery is driven hard enough to
  identify a delivery sensitivity.
- **TEST SET, UNTOUCHED — Alexander's 37 mL/kg acute arm and the chronic mineralocorticoid
  arm**, which are the four numbers §7 item 7 tests the model's *pattern* against, **plus
  Jensen throughout.**

**IF THAT SEPARATION CANNOT BE HELD — if the progressive arm fails to identify the
sensitivity, or if the same numbers end up on both sides — THE PARAMETER IS NOT ENTERED
AND THE PASS REPORTS S4.** A delivery sensitivity fitted to the acute natriuresis it is
then said to explain is failure mode 22 with an extra step, and it would be the single
easiest way to make this pass look successful.

### 5.3 AND THE PROGRESSIVE ARM IS STRATIFIED ON THE OUTCOME, WHICH IS RECORDED BEFORE IT IS USED

Alexander splits the progressive-infusion subjects into **"excreters" (maximum U_Na·V >
1000 µEq/min)** and **"nonexcreters" (< 550)** — that is, **by the very natriuresis a
delivery sensitivity would be estimated to explain.** Reporting that the high-natriuresis
group also had the larger falls in fractional reabsorption is close to tautological, and a
parameter estimated across that split inherits the circularity.

**Two further things are visible in those four numbers before any fitting**, and both are
written down now:

- The implied sensitivity is **not consistent between E1 and E2**. Taking delivery as
  `1 - p`: at E1 the excreters' delivery rises 7.1 points while distal FSR falls 14.8, a
  ratio of **-2.1**; at E2 delivery rises a further 0.9 while distal FSR falls a further
  4.9, a ratio of **-5.4**. **A factor of 2.6 apart.** Two-figure differences read off an
  abstract with no dispersion cannot be reconciled, and directive 1.13 does not permit
  splitting the difference and calling it a value.
- **The nonexcreters' distal FSR fell 4.5 points with NO significant change in proximal
  FSR** — that is, **distal reabsorption fell without any rise in delivery at all.** So
  delivery cannot be the only thing driving the distal segment, and a pure delivery
  sensitivity is refuted by the same arm that would estimate it. What that arm *does*
  support is a **hormonal distal term acting independently of delivery**, which is exactly
  what `anp_sig` already is.

**TAKEN TOGETHER, THE HONEST EXPECTATION GOING IN IS THAT §5.2's ESTIMATION SET WILL FAIL
ITS OWN ADMISSIBILITY TEST AND THIS PASS WILL LAND ON S4.** That is stated here so that
landing there reads as the rule working rather than as a disappointment, and so that a
value produced anyway would have to argue against this paragraph.

### 5.4 THE NAMED SUCCESSOR, FIXED NOW SO IT CANNOT BE REACHED FOR AFTERWARDS

If the pass lands on S4, the next hypothesis is **not** a further rearrangement of the
regulators. It is the one the ledger already named and this model does not have:

**Acute isotonic saline DILUTES PLASMA PROTEIN; chronic salt loading does not.** Peritubular
capillary oncotic pressure is what couples proximal reabsorption to that dilution, and it
is the classical mechanism of the acute response. **That single asymmetry reproduces
Alexander's result — a mechanism present acutely and absent chronically — with no
segmental rearrangement at all**, and the model already has the state it needs in
`V_plasma`. Lobo 2001 measured the haematocrit fall of **7.5%** on 2 L of saline, which
gives the plasma dilution directly and in the same protocol class.

**IT IS NOT IN SCOPE FOR THIS PASS**, it needs its own pre-registration and its own
admissibility rules, and the micropuncture literature on peritubular oncotic pressure is
openly **contradictory** — some preparations show no detectable effect on proximal
reabsorption. Naming it here fixes what the next pass is, so that arriving at it after
seeing S4 is following a plan rather than finding a rescue.

---

## 6. THE DECISION RULE

- **S1 — chronic recovered inside 1.70-2.30 and Jensen moves TOWARD 123%.** Accept.
  Report the new figure and state plainly that it is out-of-sample.
- **S2 — chronic recovered, Jensen moves AWAY.** Report it in those words. The structure
  may still be better motivated than what it replaced, but the out-of-sample number got
  worse and the pass says so rather than burying it in a green suite.
- **S3 — chronic not recoverable with ANP distal.** Move ANP proximal per §1.2, re-run,
  and report that Alexander's escape experiment forced the reading.
- **S4 — the split changes nothing.** Then the two forms are equivalent at this operating
  point, the acute deficit is **not** segmental, and that is the finding. Name what is
  left: glomerulotubular balance and peritubular Starling forces, neither of which is in
  this model.
- **S5 — Jensen OVERSHOOTS 123%.** **Do not tune back.** An overshoot on a number that was
  not fitted is exactly as informative as an undershoot, and correcting it would convert
  the one out-of-sample test into an estimation set.
- **S6 — anything else leaves its band:** sodium balance at the reference, `dMAP/dV_ecf`
  outside 2.82-4.02, Lobo's 6 h endpoints, or a segment fraction leaving [0, 1]. **Stop.**
  The segmental change is not licensed to move those.

---

## 7. THE FALSIFIABLE TESTS

1. **The operating point is unchanged.** Sodium excretion equals intake at the reference;
   MAP, GFR and plasma sodium unmoved to the digits the suite already pins.
2. **Chronic salt sensitivity inside 1.70-2.30.**
3. **`dMAP/dV_ecf` inside the corrected human band 2.82-4.02.**
4. **Lobo 2001's 6 h endpoints still reproduced** — 563 mL and 95 mmol. **This is a fit
   residual, not a test**, because `RN.ANP.TAU` was estimated against that same time
   course, and the write-up must repeat that sentence rather than claim a validation.
5. **THE OUT-OF-SAMPLE TEST.** Jensen's **+123%** against today's **+79.3%**. Report the
   new figure and whether it moved toward or away.
6. **THE STRUCTURE-VERSUS-REFIT DECOMPOSITION, AND IT IS MANDATORY.** Report the model's
   Jensen figure **with the new structure at the OLD gains, before any re-solve**, as well
   as after. Without those two numbers side by side there is no way to tell whether the
   acute response improved because the nephron was segmented or because `G_anp` came out
   larger. A pass that reports only the final number has hidden the thing it was for.
7. **ALEXANDER'S PATTERN IS A TEST OF THE MODEL, NOT AN INPUT TO IT.** Measure the
   model's own proximal and distal fractional reabsorption change across (a) the chronic
   salt step and (b) the acute saline challenge, and compare the **pattern** — proximal
   only, against both — with Alexander's four numbers. **None of those four is used to set
   anything**, so this is the strongest test in the pass, and it is the one to report
   first.
8. **Both segment fractions stay in [0, 1]** across the whole salt step and both acute
   challenges, and no clamp binds at the operating point.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Fitting anything to Jensen.** Named first because it is the cheapest way to make this
pass look like a success and it would destroy the only out-of-sample number the sodium
limb has.

**Buying the improvement with a new free parameter** and reporting it as a structural
result. §5 is a hard constraint, not a preference.

**Presenting Alexander as if the full text had been read.** It has not. The subject count,
the baselines and the mineralocorticoid protocol are unknown to this pass, the citation
must say `ABSTRACT READ IN FULL` and no derived quantity may depend on a number the
abstract does not print.

**The quiet one: reporting the final Jensen figure without §7 item 6.** If the structure
did nothing and the re-solve did the work, the numbers would look identical from outside,
and this pass exists to tell those two apart.

**Reporting that the suite is green instead of reporting §7 item 7.** The pattern
comparison is the result. The suite passing is the receipt.
