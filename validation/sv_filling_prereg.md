# Pre-registration: resting heart rate, and the stroke-volume dependence on total blood volume

**Written 2026-08-22, BEFORE any paper was read.**
Binding under `validation/pooling.md`. Fifth in the series, after
`autoreg_upper_prereg.md`, `anp_sourcing_prereg.md`, `anp_input_link_prereg.md` and
`immersion_pooling_prereg.md`.

Sources the two quantities `docs/adr/0011-cardiac-output-hr-sv.md` declines to assert, or
reports that they cannot be sourced. Nothing found here may be used to re-attribute the
2.2x residual (ADR 0010 blocker 3) or to re-open ADR 0010's input link; those have their
own scope.

---

## 0. TWO TENSIONS INSIDE ADR 0011, RECORDED BEFORE SEARCHING

Found by reading the ADR against its own disqualification list. Both are problems with
the record this pre-registration serves, not with the literature.

### 0.1 The model holds HR fixed; every admissible paradigm moves it

ADR 0011 keeps `HR` a parameter, not a state, until chronotropic baroreflex exists. But
every paradigm it admits — quantified bleed and reinfusion, saline expansion, chronic
sodium loading — changes total blood volume by enough to provoke a reflex heart rate
response. The model's HR is fixed while every source's HR moves.

**Resolution declared in advance.** The model's fixed HR is a statement about the model,
not a requirement on the source. What is extracted is `SV`, and `CO = HR x SV` lets it be
recovered from any study reporting CO and HR in the same subjects. The confound is
removed arithmetically, not by finding studies where HR happened to stay put.

**What that resolution does NOT cover, and must be recorded rather than assumed away:**
if part of the SV response is *mediated* by the HR change — altered diastolic filling
time at higher rate — then it is not arithmetically separable, and `SV` extracted this
way is a mixed quantity. Record per study whether HR moved and by how much. If the
extracted slope correlates with the size of the HR change across studies, that is
evidence the confound is not removable, and it is a finding.

### 0.2 ADR 0011's own admissible list may violate ADR 0011's own exclusion

The ADR excludes any paradigm in which contractility changes, then names Simanonok 1993
— a 15% withdrawal of total blood volume — as an admissible example. A withdrawal of that
size provokes sympathetic activation, which raises contractility. **The named example may
fail the stated rule.**

**Resolution declared in advance, and it is not to relax the rule.** Sympathetic state is
recorded per study as an uncontrolled covariate, with whatever the source reports about
it. Consequences fixed now:

- A parameter pooled from sympathetically-confounded studies is **E2 with a stated
  confound**. It is not E1, and it must not be written up as though contractility had
  been held constant.
- Where a source reports the perturbation under autonomic blockade, or reports
  contractility indices alongside, it is preferred over one that does not — **declared
  before seeing which studies exist**, so the preference cannot be assembled after the
  fact to favour a convenient result.
- If **every** admissible study is sympathetically confounded, say so in the ledger note
  and in ADR 0011. Do not describe it as measured at constant contractility.

This is the same defect as the filtered-load term inside `G_pn`: a quantity the model
does not represent, sitting inside the number that is supposed to represent something
else. Recording it here does not remove it. It makes it visible when the residual is next
audited.

---

## 1. WHAT IS BEING EXTRACTED

| # | Quantity | Unit | Becomes a ledger parameter? |
|---|---|---|---|
| Q1 | Resting heart rate, nominal healthy adult | beats/min | **Yes** |
| Q2 | Stroke volume dependence on total blood volume, `dSV/dV_blood` | mL per L | **Yes** — the replacement for `G_vr` |
| Q3 | Whether the response depends on the stressed fraction rather than total volume | - | **No** — a structural finding, see section 8 |

`SV0` is **not** extracted. `CV.CO.NOMINAL` already exists at 7200 L/day, so
`SV0 = CO0 / HR0` is derived and becomes a closure constraint enforced by
`tools/check_closure.py`, exactly as `CV.PLASMA.ECF_FRACTION` is. Source one, derive the
other. **Do not source both** — that would overdetermine the operating point and the
inconsistency would be absorbed silently.

**Q3 is the one that can sink this**, and it is the direct analogue of Q3 in
`immersion_pooling_prereg.md`, which is the question that falsified ADR 0010's input
link. See section 8.

---

## 2. SEARCH STRATEGY, DECLARED IN ADVANCE

### Q1 — resting heart rate

Preference order follows `pooling.md` strictly: a `meta-analysis` or large-cohort
reference estimate is preferred and is not re-pooled. Population fixed in advance as
**healthy adults, mixed sex, at rest, awake, supine or seated with posture recorded**.
Athletic, paediatric, elderly-specific and disease cohorts are excluded.

This value has to sit beside `CV.BLOOD_VOLUME.NOMINAL` (nominal 70 kg adult) and
`CV.HEMATOCRIT.NOMINAL` (recorded as adult male nominal, with sex deferred). Record the
sex composition. **Do not silently adopt a male-specific value to match the hematocrit
row**; if the nominal population differs across cardiovascular rows, that is a closure
problem to record, not to paper over.

### Q2 — stroke volume against total blood volume

Two directions, searched and extracted **separately**:

- **Volume removal**: quantified phlebotomy or blood donation with SV or (CO and HR)
  measured before and after.
- **Volume addition**: quantified isotonic saline, colloid, or autologous reinfusion with
  the same measurements.

Both must report the perturbation as a **measured or calculable volume** — millilitres
withdrawn or infused, or a measured change in blood or plasma volume. A study reporting
only a percentage without the basis for it is excluded.

### Paradigm exclusions are binding and were fixed in ADR 0011 before this search

Head-out immersion, head-up tilt, lower-body negative pressure, posture change,
microgravity onset, exercise of any grade, and inotrope or beta-blockade protocols are
**excluded regardless of study quality**. They are excluded because the perturbed
variable is not the model variable, which is the defect that cost ADR 0010 three
sessions.

**These exclusions may not be relaxed if the yield is thin.** A thin yield is a result —
see stop condition 5.

---

## 3. INCLUSION AND EXCLUSION, DECLARED IN ADVANCE

**Include** if all of:

1. Human subjects, healthy or with the disease state recorded.
2. A quantified change in **total** blood or plasma volume, in absolute units.
3. `SV` reported directly, or `CO` and `HR` reported in the same subjects at the same
   timepoints so `SV = CO/HR` is recoverable.
4. Elapsed time between perturbation and measurement reported.
5. Own-subject control, or a matched control arm.

**Exclude** if any of:

1. The paradigm is on ADR 0011's disqualification list.
2. The volume change is inferred from a hematocrit shift alone with no measured volume.
3. Only CO is reported, with no HR — `SV` is not recoverable and CO carries the
   chronotropic response.
4. Elapsed time is not reported. Transcapillary refill after withdrawal and renal
   handling after loading both change total volume with time; a measurement at an unknown
   time is a measurement at an unknown volume. **No refill timescale is asserted here** —
   the elapsed time is recorded per study and its adequacy judged against what that study
   itself reports.

**Measurement technique.** Record the CO or SV technique per study (thermodilution, Fick,
dye dilution, echocardiography, impedance, MRI). Declared in advance: `SV` measured
directly and `SV` recovered as `CO/HR` in the same subjects are **the same quantity** —
that is an identity, not a second measurement method, and `pooling.md`'s bar on pooling
incompatible methods does not bite. Different **CO** techniques may be pooled, but if the
spread in the extracted slope tracks technique, that is a finding and is reported rather
than averaged.

---

## 4. INDEPENDENCE, DECLARED IN ADVANCE

Two reports from the same subject cohort count once. Where a group has published
repeatedly on one protocol, the fullest report is used and the others are recorded as
non-independent. Reviews are not counted as studies; they are used only to find
primaries.

---

## 5. ENDPOINT, FIXED IN ADVANCE

The endpoint is the **earliest post-perturbation timepoint the source itself reports as
hemodynamically settled**, with the elapsed time recorded per study. Not the peak, and
not the latest timepoint.

Per-study extremes are recorded but **not pooled** — per-paper maxima bias every estimate
upward, which is the defect `immersion_pooling_prereg.md` was written to test for and
which it found in a published review.

---

## 6. POOLING RULES, DECLARED IN ADVANCE

**Q1:** `meta-analysis` if a pooled source exists — take its estimate and dispersion, do
not re-pool. Otherwise `pooled-inverse-variance`, else `pooled-n-weighted`.

**Q2:** `dSV/dV_blood` is a **slope in physical units**, not a dimensionless multiplier
whose null is 1.0, so `pooled-geometric` is wrong for it. Use
`pooled-inverse-variance` where SD and n are available, otherwise `pooled-n-weighted`,
otherwise `pooled-unweighted`. Declared now so the rule cannot be chosen after seeing the
spread.

**The two directions are pooled separately and compared before any combined value is
formed.** If withdrawal and loading disagree beyond their pooled dispersion, the
relationship is not linear through the operating point and **a single slope is the wrong
model** — that is a finding about ADR 0011's decision, not a number to average. Record it
and stop.

---

## 7. STOP CONDITIONS, DECLARED IN ADVANCE

1. **k < 3 independent studies for Q2 means no parameter is recorded.** Two studies
   become `single-source` twice over. `G_vr` stays in place, ADR 0011 stays Proposed, and
   the outcome is "blocked, and here is what is missing" — an acceptable outcome, as in
   the previous four pre-registrations.
2. **No citation is recorded without opening it.** Author list, journal, year, volume and
   PMID verified against the retrieved record for every entry. PMID 2966064 carried the
   wrong authors for two sessions; that is the standing reason for this condition.
3. **No fitted or assumed value substitutes for a missing one.** Not provisionally, not
   marked TODO. Both `RN.PRESSURE_NATRIURESIS.SLOPE` and `G_vr` itself entered this repo
   that way.
4. **THE RESULT MAY NOT BE SELECTED FOR AGREEMENT WITH `G_vr` OR WITH THE SALT STEP.**
   This is the most important condition here. `G_vr = 2880 (L/day)/L` is fitted, and the
   4.934166220845427 mmHg shift is its consequence, not evidence for it. The comparison
   `HR0 x dSV/dV_blood` against 2880 is made **once, after pooling is complete**, and
   recorded as a divergence whichever way it falls. No study may be included, excluded,
   weighted or trimmed on the basis of how close it lands to the incumbent value. A
   fitted constant that closes the loop by construction cannot adjudicate its own
   replacement.
5. **A thin yield after the paradigm exclusions is a result, not a reason to relax
   them.** If the admissible literature is k = 0 or 1, the finding is that ADR 0011's
   lumping has excluded the usable evidence base — which is a fact about the lumping and
   goes back into the ADR. It is not licence to admit tilt or LBNP.
6. **Sourcing Q2 does not license writing the component.** `G_vr`'s replacement lands
   only after the closed loop is run and read, per ADR 0011's falsifiable test. No
   ledger row is swapped in this pre-registration.

---

## 8. WHAT WOULD FALSIFY THE APPROACH

**Q3, and this is the one that can sink it.** Only the *stressed* fraction of blood
volume contributes to filling pressure. IPE has one `V_blood` and no stressed/unstressed
split, so `SV ~ f(V_blood)` treats all of it as filling.

The test is available in the sources themselves and is declared now: **if two studies
with comparable total-volume changes but different posture or venous tone report
materially different SV changes, total blood volume is not the variable that sets
filling.** In that case ADR 0011 is wrong on its input side in exactly the way ADR 0010
was — the model variable and the physiological variable do not match — and the honest
response is that the stressed/unstressed split is not optional.

That is ADR 0011's own falsifiable test firing, and it fires **here, during sourcing, at
the cost of a search**, rather than after a component is built. That is the entire reason
this pre-registration exists.

**For Q2's linearity:** section 6. Directional disagreement means a single slope is
wrong.

**For the premise of ADR 0011:** the argument for the decomposition is that HR and SV are
separately measurable in humans where `G_vr` is not. If Q2 turns out to be unsourceable —
because SV cannot be isolated from the reflex response, or because the admissible
paradigms do not exist at usable quality — then `HR x SV` is **not** more measurable than
`G_vr` in practice, only in principle, and the argument for ADR 0011 fails on its own
terms.

Record that as a conflict. Do not rescue it by widening the paradigm list, and do not
rescue it by adopting a textbook slope. The correct outcome in that case is that the
fitted lump stays, honestly labelled, until a structure exists that can be sourced.
