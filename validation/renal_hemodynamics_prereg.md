# Pre-registration: renal haemodynamics across sodium intake in healthy humans

**Date:** 2026-09-02. HANDOVER §4 item 1.

This governs extraction from `validation/renal_hemodynamics_salt_sources.md`, which is a
candidate list compiled without a pre-registration and which says in its own first
paragraph that using any of it to set a parameter requires one.

**It is NOT written blind, and §1 says exactly how far.** Every other pre-registration in
this directory opens with *"written before any source was opened"*. This one cannot, and
pretending otherwise would be the failure mode §5 item 13 records — writing an assumption
down and then ceasing to see it.

---

## 1. DECLARED PRIOR EXPOSURE, BECAUSE THE SOURCE TABLE ALREADY EXISTS

The abstract-level results of all fifteen candidates were read on 2026-09-02 and are on
`main`. **Nothing below is blind to the direction of the human GFR and renal plasma flow
response, nor to the two effect sizes that table prints.** What has NOT been seen, and what
this extraction is actually for:

- **No full text has been opened.** Krikken 2007 baseline GFR, its ambiguous filtration
  fraction sentence, and the dispersion on every response are all unread.
- **No dispersion has been read** for any response other than the two the table prints.
- **No study has been screened for the women gap** the source table declares in its §5.
- **No pooling rule has been applied** and no value has been converted into model terms.

**The consequence, and it is binding.** Every threshold in §6 and §7 is either **reused
verbatim from a rule fixed before its own run** or set by a principle that does not refer
to the observed effect size. **No new threshold is invented here.** Where the reused rule
leaves a gap, §6 says so and marks the addition as an addition.

---

## 2. WHAT THE MODEL ALREADY SAYS, STATED FIRST SO IT CANNOT BE QUIETLY MET

Measured, not argued. Reproduce with:

    julia --project=. bench/gfr_salt_sweep.jl

**`Renal.jl` autoregulates GFR FLAT across the plateau, and the salt step never leaves the
plateau, so GFR is IDENTICAL at all three arms to seven figures.**

| intake mEq/d | GFR L/day | MAP mmHg | V_ecf L |
|---|---|---|---|
| 205 | 152.6000 | 86.97876 | 14.55600 |
| 154 | 152.6000 | 84.45010 | 14.14639 |
| 103 | 152.6000 | 81.92181 | 13.73679 |

Healthy humans do not do this. That is the whole subject of the extraction.

**The sensitivity, measured.** `GFR0` is overridden per arm as `GFR0*(1 + g*(level-154)/51)`
with `FR_Na` left alone, so `g` is the fractional GFR change at ±51 mEq/day.

| `g` | shift mmHg | per 100 mmol/day | ΔV_ecf L | ratio mmHg/L | fall |
|---|---|---|---|---|---|
| 0.00 | 5.0570 | 4.9578 | 0.8192 | 6.173 | — |
| 0.01 | 4.8520 | 4.7569 | 0.7860 | 6.173 | 4.1% |
| 0.02 | 4.6470 | 4.5559 | 0.7528 | 6.173 | 8.1% |
| 0.04 | 4.2371 | 4.1540 | 0.6864 | 6.173 | 16.2% |
| 0.08 | 3.4173 | 3.3503 | 0.5535 | 6.174 | 32.4% |
| 0.16 | 1.7776 | 1.7428 | 0.2878 | 6.176 | 64.8% |

**The map is linear to within 1% for `g` ≤ 0.08**, so the inversion is fixed here:

    fractional fall in the salt-step shift  =  4.05 × g

**Three model facts fixed in advance because the comparison depends on them.**

1. **This is a pressure-limb lever ONLY.** `dMAP/dV_ecf` is **6.173 at every `g` tested**,
   moving only in the fifth significant figure at `g` = 0.16. That is the **third**
   independent confirmation of §3.7's orthogonality result, after the `G_vr` sweep and the
   escape sweep. **Nothing here touches §4 item 2, and this extraction must not be reported
   as if it did.**
2. **Why GFR bites here when §3.5 said it cancels.** It cancels **between builds**, because
   `FR_Na` is DERIVED as `1 − intake/(GFR0·C_Na)` and absorbs any change in `GFR0`. It does
   **not** cancel **within a run**: a GFR that moves while `FR_Na` is fixed changes
   `Na_filtered·(1−FR_Na)` directly. §3.5's *"a 15% error in the entire renal input moved
   the shift by 0.0006 mmHg"* is true of the level and false of the derivative — which is
   the same shape of error §3.8 found in haematocrit. **Two for two, and the pattern is
   worth naming: a quantity that cancels at the operating point need not cancel in the
   response.**
3. **The model volume excursion is 0.02896 fractional per ±51 mEq/day** (14.14639 mid,
   ±0.40961 L). §3 and §6 need it.

**To reach the human 1.70–2.30 mmHg/100 mmol from 4.9578 by this route ALONE requires
`g` = 0.132–0.162** — a 26–32% GFR swing across the 102 mEq/day step. That figure is
written down before the extraction, and it is what the sourced value gets judged against.

---

## 3. THE TARGET QUANTITY, AND WHY IT IS PER LITRE AND NOT PER MILLIMOLE

**Primary, and the only value that may be entered:**

    RN.GFR.VOLUME_SENSITIVITY  =  (ΔGFR/GFR) / (ΔV_ecf/V_ecf)      dimensionless

the fractional GFR change per fractional extracellular volume change, across chronic
sodium intake levels, in healthy humans.

**Three reasons the per-millimole form is rejected as the entered value.**

1. **The kidney does not sense the diet.** A GFR keyed to the `Na_intake` parameter is
   teleological — it hands the kidney a signal no nephron receives. The measured
   association is with volume expansion, and Conlin 1993 (`7503952`) shows the renal
   response follows volume expansion **per se**, within 3–7 hours, by saline or dextran
   alike.
2. **It would bake in a known-wrong denominator.** The model expands 0.0568 fractional per
   100 mmol/day, against a human figure roughly half that, and `G_vr` is `calibrated` and
   1.5–2.1× too stiff (§3.7, §3.8). A per-millimole value is correct **today** and wrong
   the moment `G_vr` is sourced. A per-litre value is correct **through** that fix. This is
   §3.6's lesson applied before the fact rather than after: **derive from the quantity that
   is actually measured.**
3. **It survives the missing BSA row.** A fractional change is invariant to the 1.73 m²
   indexing every renal source uses, so this extraction does **not** depend on §4 item 6.

**Tubuloglomerular feedback is the wrong mechanism, and it is ruled out here, before the
search.** Macula densa sensing of distal delivery lowers GFR when delivery rises; the human
observation is that GFR **rises** on high salt. Any account built on TGF has the sign
backwards, and it must not be reached for later to rescue a null.

**Recorded for every study regardless:** n, sex composition, age, cohort mass, the sodium
levels and how intake was verified, days per level, the GFR method, the volume method,
baseline GFR, and whether GFR and volume were measured in the **same** subjects.

**Recorded but NOT entered:** plasma renin activity and aldosterone at each intake level.
Several candidates report both. That is the input HANDOVER §4 item 3 needs, and it belongs
to **item 3's own pre-registration**; carrying it here would be the two-changes-at-once
move §7 refused for the SHA citations. Record it in the source table. Enter nothing.

---

## 4. METHOD SEPARATION, FIXED BEFORE EXTRACTION

`pooling.md` prohibits pooling across incompatible measurement methods. Three splits:

1. **GFR by true clearance** — inulin, iothalamate, ⁵¹Cr-EDTA. The target. Preferred.
2. **GFR by creatinine clearance or an estimating equation.** A different instrument.
   Recorded separately, never pooled with 1.
3. **Extracellular volume method** — iothalamate or ¹²⁵I-iothalamate distribution volume,
   bromide, inulin space, bioimpedance. Split exactly as `ecf_salt_response_prereg.md` §3
   splits them. That split is **reused verbatim**, not re-decided.

**Renal plasma flow, renal blood flow, renal vascular resistance and filtration fraction
are NOT extractable as magnitudes.** The model carries none of them, and ADR 0015 has
already disqualified them as calibration targets in terms, naming Redgrave 1985 and
Krikken 2007. They enter this document only through §7, as a **direction** question about
an ADR — never as a number about a parameter.

---

## 5. INCLUSION AND EXCLUSION — REUSED FROM `ecf_salt_response_prereg.md` §4

Reused deliberately and without amendment, because those criteria were fixed before anyone
knew which way they cut.

**Include** if all of: normotensive adults by the source's own definition, recorded; at
least two quantified sodium levels with intake measured or controlled, 24 h urinary sodium
preferred; the renal variable measured at each level; **at least 5 days per level**, with
the actual duration recorded and anything shorter pooled separately as short-protocol.

**Exclude:** hypertensive cohorts, heart failure, renal disease, cirrhosis, pregnancy,
diuretic or antihypertensive therapy, acute load-then-deplete protocols.

**Two exclusions specific to this question, fixed here.**

- **Anaesthesia and intensive care.** §5 item 14 records that sourcing structure from
  pathological preparations is how this repo acquired a model calibrated to hypertensives,
  and §3.9 records an entire line of work withdrawn for it. **Ask of every candidate: was
  this preparation designed to show normal physiology, or to break it?**
- **The nonmodulator phenotype is a disease and is not the normal arm.** Redgrave 1985 and
  Hollenberg & Williams 2006 both describe it. Only Redgrave's **nine normotensive
  controls** are eligible, and only for direction under §7.

---

## 6. THE DECISION RULE FOR THE GFR LIMB

Let `S` be the pooled sensitivity from §3. Convert to model terms by §2:

    g     =  0.02896 × S
    fall  =  4.05 × g  =  0.1173 × S

**The thresholds are reused verbatim from ADR 0015's escape diagnostic**, where they were
fixed before that run, for the same question, by someone who did not know this answer:
**more than 20% fall means the pathway is live, less than 5% means the lead is dead.** No
new threshold is chosen here, for the reason given in §1.

- **G1 — fall above 20%** (`S` above 1.71). The pathway is live. Enter
  `RN.GFR.VOLUME_SENSITIVITY`, write the ADR proposing that GFR responds to volume
  expansion, and re-estimate ADR 0013 and ADR 0015 against it per §8.
- **G2 — fall below 5%** (`S` below 0.43). Dead. Enter the row anyway if it is sourced — a
  sourced number that changes nothing is still a sourced number, and it closes the question
  — and record that the human GFR response cannot explain the salt-sensitivity gap.
- **G3 — fall between 5% and 20%. THIS IS AN ADDITION AND IS MARKED AS ONE.** The escape
  diagnostic left this band undefined because its own answer was nowhere near it. The rule:
  **real but minor. Enter the row, do NOT write a structural ADR, and record the magnitude
  as a partial contribution that the other two records must be re-estimated against.** A
  band the reused rule does not cover has to be given a disposition in advance rather than
  negotiated afterwards.
- **G4 — no usable data, or a pooled estimate whose interval crosses a band boundary.**
  Nothing is entered, `Renal.jl` is unchanged, and what was tried is recorded exhaustively
  so it is not repeated. **This is the branch that must not be avoided** by reaching for the
  per-millimole form, which §3 rejects, or by taking one study's point estimate as though a
  spread had been established.

**The tier is MIXED and is fixed here.** That healthy humans raise GFR on high sodium is
**E1** — four independent groups, human, n up to 95, and ADR 0015 already tiers it so. The
**functional form** in this model is sourced only as a straight line between two measured
intake levels, which is **E2** inside the tested range and **nothing at all** outside it. So
the term is **clamped to the pooled tested intake range**, and that censoring is recorded on
the row exactly as `RN.AUTOREG.UPPER` records its own.

**Under ADR 0006 an E1 phenomenon defaults ON.** That is a real difference from ADR 0015 and
it is stated in advance so it is not discovered conveniently later: **if G1 or G3 is
reached, this term is not a flag.** Every pinned result in the suite moves, and the change
is therefore subject to the full falsification discipline — revert the value, confirm the
tests genuinely fail, re-pin.

**Implementation is SEQUENCED BEHIND `G_vr`. The extraction is not.** The entered value is
per litre and so survives that fix, but the model's *response* to it inherits the model's
volume excursion, which is 1.5–2.1× too large. **Enter the row now; enable the term after
§4 item 2.** This dependency of item 1 on item 2 is not currently recorded in HANDOVER §4
and should be added there.

---

## 7. THE FILTRATION-FRACTION DIRECTION QUESTION

Source table §4(a). Two healthy-human cohorts give a small **rise**; Hall 1980's six
conscious control dogs give a **fall**. **No parameter turns on this.** It is a consistency
check on ADR 0015's evidence base, whose E3 rows rest on AngII preferentially constricting
efferent arterioles — which predicts filtration fraction **high on low salt**, that is,
**falling** on high salt, as the dog does.

**Eligibility, fixed before any full text is read.** A study establishes a direction only if
it reports filtration fraction with dispersion, or reports GFR and renal plasma flow with
dispersion **in the same subjects**. Where the source gives its own significance test, that
is used. Where it gives mean, SD and n, require `|mean| > 2·SD/sqrt(n)`. **A ratio computed
by this repo from two reported means, with no dispersion on either, is descriptive only and
establishes nothing** — which is exactly what van den Bosch's 0.229 → 0.233 currently is.

- **F1 — human filtration fraction falls, agreeing with the dog.** The efferent limb
  transfers; ADR 0015's E3 rows stand as written; record the agreement.
- **F2 — human filtration fraction rises, contradicting the dog.** The efferent-arteriolar
  claim does **not** transfer to humans. ADR 0015's Hall 1986 row is marked
  non-transferring, and its lumped term is re-scoped to the tubular effect alone. Note that
  this **confirms** ADR 0015's E3 tier rather than changing it: ADR 0006 defines E3 as
  species extrapolation *where human data exist and disagree*, which would then be precisely
  the case, and the disagreement becomes the recorded reason for the tier.
- **F3 — not distinguishable from zero in humans.** No contradiction and no support. Record
  that the dog fall is **unreplicated in humans**, and that this model, carrying no
  filtration fraction, cannot be constrained by it either way. **This is the branch that
  must not be avoided** by promoting a mean without dispersion into a direction.

---

## 8. THE KRIKKEN 2007 AMBIGUITY, AND THE ANTI-DOUBLE-COUNT RULE

**The ambiguity.** Source table §4(b): the retrieved record reads that filtration fraction
was *higher* in BMI ≥ 25 than in BMI < 25 while listing the smaller value first. **Directive
1.5 forbids resolving that by picking the dimensionally sensible reading.**

- **K1 — full text obtained.** Correct the source table and record which reading was right.
- **K2 — full text unobtainable.** The sentence is **struck** from the source table, not
  reinterpreted. Krikken is then excluded from §7 entirely, while its ΔGFR remains eligible
  for §6 if unambiguous and if a baseline GFR can be read.

**Krikken also reports the response stratified by BMI** (ΔGFR +16.1 against +7.8 mL/min).
Fixed in advance: **if the response depends on BMI, the whole-cohort mean misrepresents it**,
and the BMI below 25 stratum is the one this model's reference subject matches. Record both;
enter the stratum, not the mean, and say so on the row.

**THE ANTI-DOUBLE-COUNT RULE. Three records now compete to explain one discrepancy.**
ADR 0013 moves a fitted constant, ADR 0015 adds a mechanism, and this would add a second
mechanism. The model is 4.958 mmHg/100 mmol against a human 1.70–2.30, so **the total
explained must not exceed that gap**, and whichever lands second and third must be
re-estimated against those already in.

**This one has a property the other two lack, and it is why it is worth doing.** `G_pn` = 51
is obtained by fitting to the salt-sensitivity data, and `fr_angii` would be sized against
the same. **`S` is identified by an independent measurement** — a GFR and a volume, neither
of which is a pressure — so it is the only one of the three whose magnitude is not inferred
from the discrepancy it is invoked to explain.

---

## 9. SEARCH

The source table's three sweeps stand as sweeps 1 and 2 under directive 1.8. **One further
sweep is required before any pooling**, targeted at what that table declares missing in its
own §5:

- **Healthy WOMEN.** Krikken, van den Bosch, Visser, Barba, Textor, Kirkendall and Rorije
  are all male; Toering 2018 is the only sexed source and gives a direction, not numbers.
- **Baseline GFR and dispersion** for any candidate whose record gives only a delta.

**Fixed in advance, under ADR 0014.** If no sexed source with numbers is found, the row is
entered **`both`**, on a male-only cohort, with that recorded as the limitation. **A sexed
pair is never entered on a direction alone.** This is the same branch `RN.GFR.NOMINAL` took
when Soares found no sex difference, and there it was a recorded finding rather than an
omission.

---

## 10. POOLING

`pooling.md` order, unchanged and not re-decided: `meta-analysis`, then
`pooled-inverse-variance`, `pooled-n-weighted`, `pooled-geometric`, `pooled-unweighted`,
`single-source`. **`range-midpoint` is prohibited.** Pool within a measurement method only
(§4). Record `n_studies` honestly; a tier A value with k = 1 is a contradiction that should
be visible.

**`S` is dimensionless but its natural null is not 1.0**, so `pooled-geometric` does **not**
apply to it. Fixed here so it is not reached for later.

**If only one study reports GFR and volume in the same subjects, `S` is `single-source`,
k = 1, and it is said plainly.** The per-millimole limb will pool over more studies; it is a
**cross-check recorded in the note**, never the entered value, and it never raises k.

---

## 11. WHAT WOULD FALSIFY THE APPROACH RATHER THAN THE VALUE

- **`S` is a ratio of two quantities measured in the same subjects, often by the same
  tracer.** Numerator and denominator are correlated, and its dispersion **cannot** be
  computed as though they were independent. Where the paired data are not reported, record
  the point estimate and say the interval is unavailable. **Do not fabricate one.**
- **If the GFR response is not monotone** over roughly 50–230 mmol/day, the straight line
  between two levels is invalid. Record the curvature; do not force a slope through it.
- **If the response is driven by a subgroup** rather than the cohort — §8 — the pooled mean
  is not a property of healthy adults and must not be entered as one.
- **If GFR and renal plasma flow move together with filtration fraction flat**, the
  phenomenon is whole-kidney vasodilation rather than an arteriolar redistribution, and
  ADR 0015's efferent framing does not describe it. That is §7's F3 read as a positive
  result rather than a null, and it is the outcome most likely to require ADR 0015 to be
  rewritten rather than merely re-tiered.
- **If the volume expansion in these cohorts disagrees with the four studies already pooled
  in `ecf_salt_response_extract.py`** beyond their stated dispersions, the denominator of
  `S` is not the same quantity that document extracted, and the two lines of work are
  measuring different things.

---

## 12. OUT OF SCOPE

- **`G_pn` and ADR 0013.** Not re-argued here, in either direction.
- **`G_vr`, venous compliance and §4 item 2.** §6 sequences against it and stops there.
- **`RAAS.RENIN.PRESSURE_GAIN` and HANDOVER §4 item 3.** Values encountered are recorded in
  the source table for that document to start from. Nothing is entered.
- **Body surface area and a height row.** §3 is deliberately constructed not to need them.
- **Modelling the afferent and efferent arterioles separately**, which is ADR 0015's own
  open question and would restore the evidence base its §4 disqualifies.
- **Adding renal plasma flow or renal vascular resistance as model variables.**
- **Sex as a covariate beyond ADR 0014's existing rule**, and salt sensitivity as a
  population covariate.
