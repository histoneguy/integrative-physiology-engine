# Pre-registration — the late time course of an acute isotonic sodium load

**Written 2026-09-17, before any late-time source is opened and before any parameter is
re-solved.** Verify the ordering with

    git log --diff-filter=A -- validation/late_time_course_prereg.md
    git log --diff-filter=A -- validation/late_time_course_extract.py

Opened at the owner's instruction, following HANDOVER §3.45, which established that the
acute natriuresis **magnitude** is not the problem and that the **late time course** is
unconstrained by anything in this repository.

---

## 0. THE ROW ALREADY NAMED THIS EXPERIMENT, AND NOBODY RAN IT

`RN.ANP.TAU`, 0.15 d, tier C, `derived`. Its own note, verbatim:

> *"WHAT WOULD FALSIFY IT: a human isotonic-loading study reporting the full cumulative
> sodium excretion curve out to 72 h. Drummer measured one; the abstract does not give the
> series and the full text would settle this row."*

**This pass is that search.** The row is identified by **Lobo's two 6 h cumulative
endpoints and nothing else** — matching the 563 mL gives 0.171 d and matching the 95 mmol
gives 0.166 d — so the lag is pinned by the **area under the curve at one time point** and
is free in every other dimension.

---

## 1. THE MODEL'S PREDICTION, MEASURED AND WRITTEN DOWN BEFORE THE SEARCH

**Run today, on the model as merged at `4045c17`, before any late-time source was opened.**
Reproduce with `validation/late_time_course_extract.py`. Resting: `Na_excr` 205.00 mEq/day,
`FE_Na` 0.9594%, `V_ecf` 14.5618 L.

### Drummer's protocol — 22 mL/kg of 0.9% saline over 20 min, 237 mEq of sodium

| hour | Na excretion, mEq/day | cumulative extra, mEq | % of the sodium load |
|---|---|---|---|
| 1 | 421.7 | 7.4 | 3.1% |
| 2 | 446.8 | 16.9 | 7.1% |
| 6 | 479.0 | 61.1 | **25.8%** |
| 12 | 441.3 | 125.9 | **53.1%** |
| 24 | 270.5 | 207.5 | **87.5%** |
| 48 | 207.5 | 222.2 | **93.7%** |
| 72 | 207.6 | 224.8 | 94.8% |

- **Peak sodium excretion 2.34× baseline, at 344 min after infusion start.**
- **`FE_Na` maximum +125.7% at 348 min.**
- **Sodium excretion returns within 5% of baseline at 33.8 h.**
- **At 48 h it is 1.2% above baseline and `V_ecf` is +0.109 L.**

### Lobo's protocol — 2 L over 1 h, 308 mEq

Peak 2.57× baseline at 398 min; `FE_Na` maximum +147.9% at 402 min; 21.6% of the load by
6 h, 83.0% by 24 h, 94.3% by 48 h; back within 5% of baseline at **38.5 h**.

## 1.1 AND THE PREDICTION IS ALREADY IN TENSION WITH WHAT THE ABSTRACT SAYS

**Declared now, not discovered later.** `RN.ANP.TAU`'s citation column records Drummer's
abstract, which this pass has read **only as quoted there**:

> 6 healthy men, 0.9% saline 22 mL/kg over 20 min: sodium excretion rose **3-fold**,
> **less than 15%** of the infused sodium was excreted acutely, and urine flow and sodium
> excretion remained significantly elevated for **more than 48 hours**. The paper's own
> conclusion is that excretion of an acute isotonic load **requires several days**.

| | model | Drummer, as quoted |
|---|---|---|
| peak sodium excretion | **2.34×** | 3-fold |
| still elevated at 48 h | **1.2% above baseline** | "significantly elevated" |
| back to baseline | **33.8 h** | "requires several days" |

**THE MODEL LOOKS TOO FAST IN THE TAIL, AND THAT IS THE PREDICTION THIS PASS IS TESTING.**
Writing it here means a result that flatters the model has to argue against this paragraph.

---

## 2. THE CRITICAL POINT: THE TAIL DOES NOT TEST `RN.ANP.TAU`

**And this is the whole reason the pass needs a pre-registration rather than a search.**
The row's own note already says it:

> *"At 0.15 d this lag reaches 95 percent of its steady state in about 11 h, which is hours
> rather than days. The reconciliation is that Drummer describes the time course of
> EXCRETING THE LOAD, which in this model is set by how slowly the volume itself decays,
> not by this lag."*

**Confirmed by today's run:** at 48 h `V_ecf` is back to +0.109 L of a peak excursion near
1.4 L. The tail is **volume decay**, and volume decay is set by the natriuretic **gains** —
`CV.ANP.NATRIURETIC_GAIN` and `RN.PRESSURE_NATRIURESIS.SLOPE` — not by the lag.

**SO A FAILURE ON "STILL ELEVATED AT 48 H" IS EVIDENCE ABOUT THE GAINS, AND FIXING IT BY
MOVING `RN.ANP.TAU` WOULD BE FIXING THE WRONG PARAMETER.** Forbidden in §4.

**WHAT DOES IDENTIFY THE LAG is the SHAPE inside the first ~12 h** — time to peak, and the
increment between the 6 h and 12 h cumulative. That is the part of the curve this pass must
extract if it extracts anything.

## 2.1 AND THERE IS A QUANTITATIVE CONSEQUENCE, FIXED IN ADVANCE

Slowing the tail means **smaller** natriuretic gains, and smaller gains mean a **larger**
chronic salt sensitivity. The model is at **1.96** against a human window of **1.70–2.30**,
so there is headroom to the ceiling but not much: **roughly a 17% reduction in the combined
gain before the chronic constraint binds.**

**PREDICTION, STATED BEFORE THE DATA: if the late tail demands materially slower clearance,
the chronic salt sensitivity will be driven to the top of the human window or through it.**
If it goes through, the model cannot satisfy both, and **that tension is a structural
finding about the single-lag, two-gain form** — which ADR 0010's addendum already names as
the live question. **It would be a better result than a fitted parameter.**

---

## 3. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults; **intravenous isotonic (0.9%) saline** as a bolus or short
infusion, dose and duration recorded; **timed urine collections extending to at least
12 h**, and preferably 24–72 h; sodium excretion reported **per interval or cumulatively as
a series**, not as a single total.

**Exclude:** patients; diuretics; hypertonic or hypotonic loading; **oral** sodium loading,
whose absorption kinetics are a different experiment; and studies reporting only a single
endpoint.

**THE DRUMMER-SPECIFIC RULE, AND IT IS THE ONE MOST LIKELY TO BE GOT WRONG.** The paper's
title is *"…before, during, and after HDT"* — **head-down tilt**. HDT is itself a volume
redistribution manoeuvre and it is the paper's experimental variable. **ONLY THE CONTROL /
PRE-HDT ARM IS ADMISSIBLE.** Taking a during-HDT or post-HDT curve as the normal response
would be entering the study's own perturbation as this model's baseline — the same failure
`nephron_segments_prereg.md` §8 named for volume-expanded micropuncture.

**Lobo 2001 is NOT admissible as a test.** `RN.ANP.TAU` was estimated against its 6 h
endpoints. It may appear only as the fit residual it is, labelled as such.

**Jensen 2013 is admissible only up to 240 min**, which is where its protocol ends, and it
is already spent as the magnitude test.

---

## 4. WHAT MAY NOT MOVE

- **`RN.ANP.TAU` IS NOT RE-SOLVED AGAINST THE TAIL.** §2: the tail is gain, not lag. It may
  be re-solved against the **first-12-hour shape** if and only if an admissible series
  resolves it, and then §6's L3 rules apply.
- **`CV.ANP.NATRIURETIC_GAIN` AND `RN.PRESSURE_NATRIURESIS.SLOPE` ARE NOT RE-SOLVED IN THIS
  PASS AT ALL.** If the tail says they are wrong, **that is the finding and it is reported**;
  changing them is a separate pass with its own pre-registration, because they carry the
  chronic salt sensitivity and §2.1 predicts the two constraints may not both be satisfiable.
- **JENSEN 2013 MAY NOT ENTER ANY ESTIMATION.** If anything moves, Jensen's 210–240 min
  window value is reported before and after, and never fitted.
- **`JENSEN_FINAL_WINDOW_RISE` in `test/runtests.jl` may be re-pinned only with an explicit
  statement of what moved it and why** — it is a drift detector and re-pinning it silently
  is what it exists to prevent.
- **The chronic salt sensitivity must stay inside 1.70–2.30**, or the pass stops.

---

## 5. DIRECTIVE 1.12 — THE ROUND NUMBERS AND THE PHRASES

**"One third of the load by 6 h"** (`challenges.jl` carries it as a Lobo restatement),
**"3-fold"**, **"less than 15%"**, **"24 hours"**, **"48 hours"**. And two that are phrases
rather than numbers and are quoted far more than they are measured: **"requires several
days"** and **"significantly elevated"**. **A significance statement is not a magnitude**,
and a model cannot be tested against it — see L5.

---

## 6. THE DECISION RULE

- **L1 — an admissible resolved series is found and the model lies inside its dispersion.**
  Report. Nothing moves. It is the first genuine late-time validation the acute limb has.
- **L2 — found, and the model is outside it.** Report, in the direction §1.1 predicted or
  against it, and say which. Then run the **structural test**: sweep `RN.ANP.TAU` and ask
  whether **any single first-order lag** reproduces both Lobo's 6 h cumulative and the late
  series. **If none does, that is evidence about the FORM** — the real path is multi-timescale
  or saturating — and it is the pass's result. **Do not fit anything to hide it.**
- **L3 — a single lag can fit both, but it is not 0.15 d.** Then Lobo alone under-identified
  it. Re-estimate against **both**, and state plainly that Lobo's two endpoints are
  thereafter **not independent evidence**. Report Jensen before and after.
- **L4 — nothing admissible with a resolved series.** Record INDETERMINATE with the exact
  terms per §3.33, and name what would settle it. **Do not substitute the qualitative
  statements for a curve.**
- **L5 — only qualitative bounds are available** (Drummer's "3-fold", "<15% acutely",
  "elevated beyond 48 h"). Test the model against them **as bounds**, report pass or fail on
  each, **and record explicitly that a bound is not a curve and that "significantly
  elevated" cannot be compared to a model at all without the dispersion behind it.** This is
  the most likely branch and it must not be dressed up as L1.
- **L6 — anything else leaves its band.** Stop.

---

## 7. THE FALSIFIABLE TESTS

1. **The model's §1 table is the prediction and is compared to the data as printed**, not
   re-derived afterwards. A pass whose "prediction" appears only after the source is open
   has no prediction.
2. **Drummer's three bounds, each reported pass or fail:** peak ≈ 3-fold against the model's
   2.34×; under 15% excreted acutely; elevated beyond 48 h against the model's 1.2%.
3. **Lobo's 6 h endpoints are reported as fit residuals** and the write-up says so rather
   than claiming a validation — §3.15's standing correction.
4. **The chronic salt sensitivity is reported** and stays inside 1.70–2.30.
5. **Jensen's 210–240 min window** is reported, unchanged unless something moved, and never
   fitted.
6. **IF THE TAIL FAILS, §2's DIAGNOSIS IS TESTED RATHER THAN ASSERTED**: sweep the gains and
   the lag separately and show which one the tail actually responds to. The claim that the
   tail is gain and not lag is this document's, and it must be demonstrated by running.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Re-solving `RN.ANP.TAU` against the tail.** Named first because it is the obvious move,
the row is tier C so it looks cheap, and §2 says it is the wrong parameter. It would make
the curve fit and teach nothing.

**Taking Drummer's during- or post-HDT arm as the normal response.** The paper's variable is
head-down tilt; using it as baseline enters the study's perturbation as the model's resting
state.

**Treating "significantly elevated at 48 h" as a magnitude.** It is a significance
statement about six men. The model is 1.2% above baseline at 48 h; whether that is
compatible depends on a dispersion the abstract does not give.

**Quietly re-pinning `JENSEN_FINAL_WINDOW_RISE`** if something moves. That pin exists
because a 53-point drift went unnoticed for twelve days, and re-pinning it without saying
what moved it reproduces exactly the failure it was added to catch.

**The quiet one: reporting the bounds that pass and not the one that fails.** §1.1 says in
advance which is most likely to fail — the 48 h persistence — so a write-up that omits it
has selected its evidence.
