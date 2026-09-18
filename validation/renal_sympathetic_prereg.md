# Pre-registration — the renal sympathetic arm, and which path it is actually on

**Written 2026-09-18, before any row is entered and before any term is written.** Verify
the ordering with

    git log --diff-filter=A -- validation/renal_sympathetic_prereg.md
    git log --diff-filter=A -- validation/renal_sympathetic_extract.py

Opened because HANDOVER §4 item 1 names the control layer as the honest next target, and
because directive 1.15 removed this item's only stated blocker.

---

## 0. THIS PASS HAS A PREDICTION WAITING FOR IT, WRITTEN BEFORE THE ANSWER WAS VISIBLE

**ADR 0021 A6.3:** *"Building renal sympathetic traffic must LOWER `RN.MD.RENIN_GAIN` and
bring both Lobo endpoints back inside their bands. If it does not, the acute overshoot is
something else — the missing candidate being tubuloglomerular feedback on the afferent
arteriole."*

**HALF OF THAT PREDICTION IS ALREADY DEAD AND THIS PASS DOES NOT GET TO PRETEND
OTHERWISE.** §3.54 widened Lobo's bands and HANDOVER records the consequence in its own
words: *"Inside the band they bound nothing, so ADR 0021's prediction … is no longer
testable against Lobo."* **The Lobo half is unavailable. The `g_md` half stands and is
test 1 below.**

---

## 1. THE SOURCE, AND WHAT CAN AND CANNOT BE OPENED

**Directive 1.15's default, and the papers were opened — as ABSTRACTS, via NCBI efetch.**
Both are AJP-Regu, both paywalled, and `elink pubmed_pmc` returns only citing articles for
each. **Full text was not obtained and the rows must say so**, exactly as the thyroid axis
records Benhadi 2010 as abstract-only.

**Lohmeier TE, Lohmeier JR, Reckelhoff JF, Hildebrandt DA.** *Sustained influence of the
renal nerves to attenuate sodium retention in angiotensin hypertension.* Am J Physiol Regul
Integr Comp Physiol 2001;281(2):R434-43. **PMID 11448845.**

**Lohmeier TE, Lohmeier JR, Haque A, Hildebrandt DA.** *Baroreflexes prevent neurally
induced sodium retention in angiotensin hypertension.* Am J Physiol Regul Integr Comp
Physiol 2000;279(4):R1437-48. **PMID 11004014.**

**THE PREPARATION IS WHY THIS IS USABLE.** Conscious dogs, **unilateral renal denervation
plus surgical division of the bladder into hemibladders**, so denervated (Den) and
innervated (Inn) kidneys are collected separately **in the same animal at the same arterial
pressure, the same circulating ANG II and the same hormonal state.** The Den/Inn ratio is a
**within-animal isolation of the renal nerve contribution to sodium excretion**, which is
precisely the quantity this model lacks and cannot get from a human.

| | MAP | Den/Inn sodium |
|---|---|---|
| 2001 control, n = 5 | 92 ± 4 mmHg | **0.99 ± 0.05** |
| 2001 day 10 of ANG II | +30 ± 3 mmHg | **0.56 ± 0.05** |
| 2000 intact control | 98 ± 4 mmHg | **1.04 ± 0.04** |
| 2000 day 5 of ANG II, intact | +30 to 35 mmHg | **0.51 ± 0.05** |
| 2000 day 5, after CPD + SAD | same hypertension | **2.02 ± 0.14** |

---

## 2. THE FINDING THAT DECIDES THE WIRING, AND IT IS NOT THE MAGNITUDE

> *"CPD totally abolished the fall in the Den/Inn sodium in response to ANG II."*

**CARDIOPULMONARY DENERVATION ALONE KILLED THE RESPONSE, BEFORE THE CAROTID SINUSES WERE
TOUCHED.** Cardiopulmonary receptors are **low-pressure volume receptors**. So the input to
this arm is **VOLUME, not arterial pressure** — and a pass that wired it to MAP because
"baroreflex" appears in the title would have wired it to the wrong afferent on the strength
of a word.

**AND THE SIGN REVERSES WITHOUT THE REFLEX.** After CPD + SAD the ratio goes to
**2.02 ± 0.14** — the innervated kidney excretes *less*, because ANG II's direct
sympathoexcitatory effect is unopposed. **A sign reversal is not a magnitude and survives
every uncertainty in §5.** It is the strongest single piece of evidence here.

## 2.1 WHICH MEANS THE DOUBLE-COUNT RISK MOVED, IT DID NOT DISAPPEAR

Wiring to volume **avoids** triple-counting the pressure path, where HANDOVER already
records `RN.PRESSURE_NATRIURESIS.SLOPE` as over-determined against
`CV.ANP.NATRIURETIC_GAIN` with a joint constraint `G_pn + 0.0594·G_anp = 50`.

**IT LANDS INSTEAD ON THE VOLUME PATH, WHERE TWO GAINS ALREADY SIT** —
`CV.ANP.NATRIURETIC_GAIN` and `RN.GFR.VOLUME_SENSITIVITY`, both keyed to volume, both
estimated with this arm absent. **This is failure mode #22 in its exact form: a calibrated
parameter re-estimated by a second path.** §6 branch S2 exists for the case where it cannot
be separated, and **S2 forbids building.**

---

## 3. WHAT THE FORM MUST DO, FIXED BEFORE IT IS WRITTEN

- **IDENTICALLY ZERO AT THE OPERATING POINT.** Two independent cohorts give **0.99 ± 0.05**
  and **1.04 ± 0.04** — at rest the innervated and denervated kidneys excrete the *same*
  sodium. **Two significant figures: 1.0.** The term is written against a reference so that
  it vanishes at the reference by construction, the way the solute slope is, and **every
  constant derived from the operating point must be untouched.**
- **Keyed to the model's volume state**, per §2, and **not** to MAP.
- **Monotone and signed**: volume expansion → cardiopulmonary loading → sympathoinhibition
  → *more* sodium excreted.

**THE MAGNITUDE IS TWO FIGURES AND NOT THREE.** Inn/Den at the hypertensive steady state is
1/0.56 = 1.79 and 1/0.51 = 1.96 in two cohorts whose SEs are 0.05 — **they agree to within
one SE and pool to about 1.9.** Directive 1.13: the augmentation is **about 90%**, not
89.3%, and no derived gain may carry more.

---

## 4. WHAT MAY NOT MOVE

- **The resting state.** MAP, `V_ecf`, urine volume and osmolality, plasma sodium,
  `Na_excr` = 205.000. The arm is zero there by construction; if any moves, the term is
  written wrongly. **Fix the term; do not re-derive anything to absorb it.**
- **`CV.ANP.NATRIURETIC_GAIN`, `RN.GFR.VOLUME_SENSITIVITY` and
  `RN.PRESSURE_NATRIURESIS.SLOPE` may not be re-solved in this pass**, whatever §2.1
  shows. Identifying the double count is this pass's job; **re-estimating against it is a
  separate pass with its own pre-registration**, because doing both here is changing a
  target and refitting to it in one step.
- **`RN.MD.RENIN_GAIN` may not be re-solved either — it is the TEST.** ADR 0021 predicts it
  falls. A pass that re-solves it first has destroyed its own instrument.
- **Chronic salt sensitivity must stay inside 1.70–2.30**, and Jensen and the acute
  ordering ratio are **reported and never fitted**.

---

## 5. DIRECTIVE 1.14 — THE INTERVAL, COMPUTED BEFORE ANY DISCREPANCY IS CALLED ONE

1. **Printed precision.** The ratios are two-figure with two-figure SEs. Inn/Den is
   **1.8–2.0**, and nothing downstream may carry three figures.
2. **Sampling error.** n = 5 dogs. The SEs *are* published, which is more than Lobo or
   Drummer offer, but five animals bound very little.
3. **THE AUTHORS' OWN CAVEAT, AND IT CUTS AGAINST THE MAGNITUDE.** The 2001 abstract
   reports *"a latent impairment in sodium excretion from Den kidneys."* **Denervation
   itself degrades excretion**, so Den is not a clean zero-nerve control and the ratio
   **overstates** the nerve effect by an unknown amount. This must be on the row.
4. **Species.** Dog, and directive 1.6's recording requirements bind: species, preparation
   and range on the row, stated plainly.
5. **ONE MANIPULATION.** Both papers raise pressure with **infused ANG II**. The Den/Inn
   ratio controls for systemic ANG II because both kidneys see it — but it does **not**
   establish that the same gain applies to volume expansion reached any other way.

**SO WHAT IS STRONG HERE IS THE SIGN, THE AFFERENT AND THE ZERO AT BASELINE. THE GAIN IS
WEAK AND THE ROW MUST SAY SO.**

---

## 6. THE DECISION RULE

- **S1 — the arm is keyed to volume, is zero at the reference, the resting state is
  unchanged, and its contribution is separable from the two existing volume gains.** Build
  it, tier B, dog, abstract-only, with §5's caveats on the row.
- **S2 — its contribution is NOT separable from `CV.ANP.NATRIURETIC_GAIN` or
  `RN.GFR.VOLUME_SENSITIVITY`.** **Do not build.** Report that the volume path already
  carries an unlabelled sympathetic component, which is a finding about the existing rows
  and worth more than a third gain on the same path.
- **S3 — built, and `RN.MD.RENIN_GAIN` falls.** ADR 0021 A6.3 is **confirmed**. Report it
  and re-solve the gain **in a separate pass**.
- **S4 — built, and `RN.MD.RENIN_GAIN` does not fall.** The prediction is **refuted**, and
  ADR 0021 already names the successor: tubuloglomerular feedback on the afferent arteriole.
  **Record the refutation as the pass's main result** — it is worth more than the arm.
- **S5 — the resting state or the chronic band moves.** Stop.

---

## 7. THE FALSIFIABLE TESTS

1. **`RN.MD.RENIN_GAIN` is reported before and after, unchanged in the ledger**, and the
   direction of the change it *would* need is stated. That is ADR 0021 A6.3's instrument.
2. **The operating point is bit-unchanged**, demonstrated by running.
3. **The arm's contribution at the reference is exactly zero**, demonstrated by running.
4. **The Den/Inn ratio the model reproduces at +30 mmHg is reported against 1.8–2.0**, as a
   band and not a point.
5. **The double-count question is answered explicitly with numbers** — how much of the
   volume-driven natriuresis each of the three paths now carries.
6. **Chronic salt sensitivity, Jensen and the acute ordering ratio before and after.**
7. **The row records: dog, conscious, unilateral denervation with divided bladder, n = 5,
   ANG II protocol, ABSTRACT ONLY, and the authors' latent-impairment caveat.**

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Wiring it to MAP.** §2 — cardiopulmonary denervation alone abolished the response. The
word "baroreflex" in a title is not an afferent.

**Building it on top of two volume gains without asking whether they already contain it.**
§2.1. The existing gains were estimated with this arm absent, which means they absorbed
whatever it contributes, which is the same criticism this repository already makes of
`RN.MD.RENIN_GAIN` and of the old pressure gain.

**Re-solving `RN.MD.RENIN_GAIN` in this pass.** It is the instrument for a prediction
written before the answer was known. Spending it is §3.15's error committed deliberately.

**Quoting the gain to three figures.** §3 and §5. Two cohorts, five dogs, no full text, and
a denervation artifact the authors name themselves.

**The quiet one: reporting S3 and not S4 with equal weight.** ADR 0021 predicted the gain
falls. **If it does not, that is the more valuable result**, because it promotes
tubuloglomerular feedback from a guess to the indicated mechanism — and it is the outcome a
pass that wants its own arm to matter will be least inclined to look for.
