# ADR 0015: A non-escaping AngII tubular term, so sodium balance is not reached by pressure alone

**Status:** Provisional — **built and sourced 2026-09-19, and REFUTED BY ITS OWN FALSIFIABLE TEST.** The term exists, its magnitude comes from Hall 1984, and it is **off by default** because pinning it amplifies the salt-step shift 1.2× against the ≥ 2× this record requires. See the Result at the foot.
**Date:** 2026-09-02
**Evidence tier:** MIXED — E1, E3.

- **E1** — that chronic high sodium intake suppresses the renin-angiotensin system and
  raises renal plasma flow and GFR in healthy humans. ~~Four independent groups, n up to
  95.~~ **CORRECTED 2026-09-02: the four papers first cited here are TWO groups.** Krikken
  2007 and van den Bosch 2021 are the same Groningen cohort — van den Bosch is a post-hoc
  analysis of it and says so — and Redgrave 1985 and Conlin 1993 are both Brigham. **The
  E1 tier survives, and on a wider base than before**, because the pre-registered fourth
  sweep in `validation/renal_hemodynamics_prereg.md` added two further independent groups:
  Roos 1985 (Utrecht, n = 8, **inulin** clearance, PMID 3907374) and Pechère-Bertschi 2002
  and 2003 (Geneva, women, PMIDs 11849382 and 12969156). **Four groups, three tracers.**
  The count was wrong; the claim was not. See `renal_hemodynamics_salt_sources.md` §0.
- **The E1 claim is now known to be MALE-SPECIFIC where it is quantified.** The only clean
  healthy-women study finds **no change in renal haemodynamics** on high salt in the
  follicular phase (Pechère-Bertschi 2002, n = 35). Recorded as a declared conflict on
  `RN.GFR.VOLUME_SENSITIVITY`.
- **E3** — that the AngII tubular effect is what allows sodium balance at nearly constant
  pressure, and that it does **not** escape as aldosterone does. The decisive experiment
  is a **dog** AngII clamp, and the human experiment **is performable** — chronic ACE
  inhibition or ARB therapy is essentially it. So ADR 0006's ethical-ceiling clause does
  **not** apply and this cannot be E2. Same reasoning §3.1 applied to `RN.AUTOREG.LOWER`.
- **NO TIER CLAIMED** for any magnitude or parameterisation. None is proposed here.

> **E3 means default OFF with a falsifiable test.** That is what this record proposes,
> and it is the same discipline ADR 0004 applied to sodium storage.

## Context

Every steady state in this model reaches sodium balance through **arterial pressure
alone**. `Renal.jl` carries a constant `G_pn`; the RAAS enters as `fr_mod`; and `Raas.jl`
sets `fr_mod ~ fr_raw - esc` with `D(esc) ~ (fr_raw - esc)/tau_esc`, so at steady state
`esc = fr_raw` and **`fr_mod = 0`**. HANDOVER §7 already recorded this — *"escape drives
`fr_mod` to ~1e-7 so no steady state moves"* — but filed it as a transient-only problem.

It is not transient-only. It is why `G_pn` has to absorb the whole of salt balance, and
therefore a candidate explanation for §3.3: the model is **2–19× too salt-sensitive** and
reads as "calibrated to hypertensives".

`fr_raw ~ k_aldo * (aldo - 1)` acts through **aldosterone** — the component the literature
calls quantitatively minor, and which genuinely does escape. The AngII component, which
the literature calls dominant and which does the resetting, is not represented at all.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| High Na suppresses RAS and raises renal plasma flow and GFR | **E1** | **Groningen:** Krikken 2007 (n=95, PMID 17091123) and van den Bosch 2021 (n=70, ERPF 592 vs 559, GFR 138 vs 128, PRA 2.10 vs 5.74, PMID 34921521) — **one cohort, not two studies.** **Brigham:** Redgrave 1985 normotensive controls (RBF +79±28 mL/min/1.73 m², **BP unchanged**, PMID 2985655) and Conlin 1993 (modulation reversed in 3–7 h, PMID 7503952). **Utrecht:** Roos 1985 (n=8, inulin 103→129 mL/min over 20→1128 meq/day, PMID 3907374). **Geneva:** Pechère-Bertschi 2003 (n=27 women on oral contraceptives, GFR and FF rise, PMID 12969156) — **but the same group's non-contraceptive cohort finds no change in the follicular phase** (n=35, PMID 11849382) | **human** |
| Sodium balance across a 100-fold intake range is achieved with <7 mmHg of pressure change when the RAS is free | **E3** | Hall, Guyton, Smith & Coleman 1980, six **conscious control** dogs, 5 → 500 meq/day (PMID 6254369) | dog |
| Clamping AngII converts the same intake steps into a 42% rise in arterial pressure | **E3** | Hall 1980, six AngII-infused dogs, same protocol | dog |
| The RAS acts **independently of plasma aldosterone**; its intrarenal tubular effects outweigh the aldosterone-mediated ones | **E3** | Hall 1980 (PAC not different in the ACE-inhibited arm); Hall 1986 review (PMID 3514280) | dog / review |
| AngII preferentially constricts **efferent** arterioles and does not constrict preglomerular vessels at physiological activation | **E3** | Hall 1986 (PMID 3514280) | review |
| Failure of this modulation produces salt-sensitive hypertension in humans | E3, **disease phenotype** | Hollenberg & Williams 2006 (PMID 16672145); Redgrave 1985 nonmodulators | human, hypertensive |

Full source table with every number: `validation/renal_hemodynamics_salt_sources.md`.

**The disease-phenotype row is listed last and is not load-bearing**, deliberately. §5 item
14 records that sourcing structure from pathological preparations is how this repo got a
model calibrated to hypertensives in the first place.

### The motivating diagnostic

`julia --project=. bench/escape_sweep.jl`. Lengthening `tau_esc` so the existing tubular
term persists:

| | salt-step shift | per 100 mmol/day |
|---|---|---|
| escape ON (default) | 5.0570 mmHg | 4.958 |
| escape OFF (`tau_esc` = 1e6 d) | **2.4925 mmHg** | **2.444** |
| human, meta-analytic (k=3) | — | **1.70–2.30** |

**A 50.7% fall**, against a threshold of 20% fixed before the run. `fr_mod` is +3.1e-3 at
205 mEq/day and +5.5e-3 at 103 — less reabsorption on high salt, more on low. That is
pressure-independent natriuresis, and it does the work `G_pn` is currently doing alone.

> **RESIZED 2026-09-02, AND THE 50.7% ABOVE WAS A FUNCTION OF AN UNSOURCED ROW.**
> `RAAS.RENIN.PRESSURE_GAIN` has been re-derived from van Ochten's own slope, 19.0 → 4.35
> (`validation/renin_gain_prereg.md`, branch R1). **The fall becomes 21.5% and the
> escape-off salt sensitivity goes 2.444 → 3.892 mmHg per 100 mmol/day** against a human
> 1.70–2.30. Measured with `bench/renin_gain_sweep.jl`:
>
> | `g_renin` | fall | escape-off mmHg/100 mmol |
> |---|---|---|
> | **4.35 (derived)** | **21.5%** | **3.892** |
> | 9.50 | 35.7% | 3.188 |
> | 19.0 (the value behind the table above) | 50.7% | 2.444 |
> | 38.0 | 65.8% | 1.696 |
>
> **This record survives its own pre-registered rule and loses most of its size.** The
> pathway is still live at 21.5%, but it now closes about a fifth of the salt-sensitivity
> gap rather than nearly all of it. The renin pre-registration recorded *before its
> search* that it could resize this record but not overturn it, because the fall stays
> above 20% even at a quarter of the incumbent gain. **The consequences section below is
> corrected accordingly: this is no longer a mechanism that reaches the human range on its
> own.**

**This diagnostic is NOT the proposed change.** Disabling aldosterone escape is wrong
physiology; escape is real. It demonstrates that the *pathway* is capable of carrying salt
balance in this model, nothing more. Three caveats travel with it, all in the bench script:
the **baseline moves** (MAP 86.98 → 90.30), `RAAS.RENIN.PRESSURE_GAIN` is **calibrated
against a baseline that no longer exists**, and the ratio `dMAP/dV_ecf` is **unchanged at
6.173** — this touches the pressure limb only.

## Decision

**Add a second RAAS tubular term representing the AngII effect, which does NOT escape,
alongside the existing aldosterone term, which continues to escape. Default OFF.**

    fr_mod ~ (fr_raw - esc) + fr_angii        fr_angii NOT subject to esc

`fr_angii` is **not parameterised here** and no magnitude is claimed. Default OFF is
required by ADR 0006 for an E3 claim and is not a hedge: it means every existing result is
bit-identical until the term is deliberately enabled, exactly as ADR 0004 and ADR 0005 did.

## Falsifiable test

**Reproducing the human salt sensitivity is not a test** — the term would be sized to do
that, so the model matching it is arithmetic. The test must use a manipulation that was
not used to set the value.

**The test: the AngII clamp contrast.** Hall 1980 ran the same intake protocol twice, once
with the RAS free and once with AngII fixed, and got **<7 mmHg versus +42%**. With
`fr_angii` implemented and enabled, **pinning it** (the model's analogue of the clamp) must
**increase the salt-step pressure shift by at least 2×** relative to leaving it free.

If pinning the term does not substantially amplify salt sensitivity, the term is not
carrying the physiology it is named for, and this record is wrong regardless of how well a
fitted magnitude reproduces the human slope.

**A second, independent test if the renal haemodynamic sourcing lands:** the model should
show renal plasma flow *rising* on high salt. It currently cannot — see below.

**THE SOURCING LANDED ON 2026-09-02 AND THIS TEST IS NOT AVAILABLE.** The model carries no
renal plasma flow and the extraction did not add one — `validation/`
`renal_hemodynamics_extract.py`, branch G3. What it did add is a **GFR** response to
volume expansion, `RN.GFR.VOLUME_SENSITIVITY = 1.30`, which is a **third competing
explanation** for the same salt-sensitivity discrepancy and is worth 8–15% of it against
this record's 51%. **The anti-double-count rule now covers three records, not two.**

**And the filtration-fraction contrast came back inconclusive, which touches the E3 rows
above.** The pre-registered question was whether healthy humans reproduce Hall 1980's fall
in filtration fraction, as the efferent-arteriolar mechanism predicts. **They neither
reproduce it nor contradict it**: the Krikken numbers are struck as unreadable, the van
den Bosch ratio carries no dispersion, and the two eligible human sources disagree by
hormonal state. **The dog fall is unreplicated in humans and the efferent rows here stand
untested rather than confirmed.** That is not a reason to change the tier — E3 already
means the mechanism is inferred — but it removes a corroboration this record did not
claim and should not later acquire by assumption.

## What this lumping disqualifies as evidence

The term **collapses two mechanisms into one**: AngII's efferent-arteriolar constriction,
which acts on sodium reabsorption through peritubular capillary physical forces, and its
direct action on tubular transport. Hall 1986 distinguishes them; this does not.

**What that forecloses as calibration targets.** The model has no afferent/efferent
arteriolar distinction, no filtration fraction as a state, and no peritubular oncotic
pressure. So it can no longer be calibrated against **micropuncture studies**, against
**filtration-fraction paradigms**, or against experiments whose perturbed variable is
renal plasma flow or renal vascular resistance — including Redgrave 1985 and Krikken 2007,
which are cited above for *direction* and must not later be used for *magnitude*.

**The class that still matches** is whole-kidney sodium balance against intake and arterial
pressure — Hall 1980, and the human salt-step literature already in
`ecf_salt_response_extract.py`.

## Consequences

- **Nothing moves until it is enabled.** Default OFF, so 428/428 stands and every pinned
  result is unchanged.
- ~~**ADR 0013 becomes a competing explanation rather than a complementary one.**~~
  **MEASURED 2026-09-02 — see ADR 0016.** They are not competing; they are **sequenced**,
  and there are **three** claimants rather than two. Run together in the model rather than
  composed on paper, this term and the sourced GFR limb give **3.409–3.634** mmHg per 100
  mmol/day, and adding `G_pn` = 51 on top gives **1.536–1.639**, below the human
  1.70–2.30. **The corrected `G_pn` bracket is 32.3–49.0 and 51 is outside it.**
  **This record is necessary and nowhere near sufficient**: 21.5% of the gap at the sourced
  renin gain, against the 50.7% its own motivating diagnostic showed before that gain was
  sourced. ADR 0016 puts this record **second** and the fitted constant **last**.
- **AND THE MECHANISMS GET THE VOLUME RESPONSE RIGHT WHERE THE FITTED CONSTANT DESTROYS
  IT.** Both mechanisms together give ΔV = 0.552 L per 100 mmol/day against a human 0.553;
  `G_pn` = 51 alone gives 0.315. That is §3.7's verdict reproduced from a different
  direction — but it is **not** a success, because it happens by ΔMAP being ~1.7× too high
  and the ratio ~1.8× too high and the two errors cancelling. Fixing either alone breaks it.
- ~~**`RAAS.RENIN.PRESSURE_GAIN` must be re-derived first.**~~ **DONE 2026-09-02, and it
  cost this record more than half its effect.** 19.0 → 4.35, `assumed` → `derived`, from
  the same van Ochten meta-analysis that already supplied this component's threshold and
  form. The blocker was never the physiology: the row's note claimed the paper reported
  the slope in unconsumable units, and the paper in fact converted its dose-response to
  percentage of the plateau precisely so it could be consumed. Nobody had opened it.
- **A STRUCTURAL LIMIT WAS FOUND WHILE DOING IT, and it bears on this record.** The
  rectified pressure-only renin control **cannot reproduce the human salt-induced renin
  response at any gain** — van den Bosch measures a 2.73-fold PRA change between sodium
  intakes at 2 mmHg of pressure difference, where this form's ceiling is 1.40. Human
  renin answers to macula densa sodium delivery and renal sympathetic traffic, and this
  component has neither. **The tubular term this record proposes is driven by that same
  renin signal**, so whatever `fr_angii` ends up representing is being driven by an input
  that is known to be incomplete. That is not a reason to reject the record; it is a
  reason its magnitude must never be fitted to salt data.
- **The volume limb is untouched.** `dMAP/dV_ecf` stays 6.173 against a human 2.97–4.16.
  §4 item 2 is unaffected.

## What is NOT decided

- **The magnitude of `fr_angii`, or its functional form.** No number is proposed, and a
  fitted one would fail this record's own falsifiable test as evidence.
- **Whether ADR 0013 should still be accepted.** See Consequences.
- **Whether the efferent arteriole should be modelled explicitly** rather than lumped.
  That is the change that would restore the disqualified evidence base above.
- **Whether escape should apply to the aldosterone term at its current `tau_esc`.** The
  escape time constant is untouched here and unexamined.

> **The human volume limb and the `dMAP/dV_ecf` band quoted in this record were corrected on 2026-09-16** — tracer limb 0.553 → 0.602 L/100 mmol, band 2.97–4.16 → 2.82–4.02 mmHg/L, because `ecf_salt_response_extract.py` de-indexed van den Bosch with one body surface area where each arm has its own. **See ADR 0013's addendum**, which owns the band, and `validation/ecf_deindex_extract.py`, which computes it.

---

## Status review — 2026-09-18. THE BLOCKER IS DISCHARGED; THE RECORD STAYS `Proposed`

**No parameter moved. No code changed. `fr_angii` is still not built.**

### This record named its own blocker, and both halves are now built

Its Consequences say:

> *"**The tubular term this record proposes is driven by that same renin signal**, so
> whatever `fr_angii` ends up representing is being driven by an input that is known to be
> incomplete … Human renin answers to **macula densa sodium delivery and renal sympathetic
> traffic**, and this component has neither."*

**It has both now.**

- **Macula densa sodium delivery — ADR 0021**, 2026-09-05. `RN.MD.RENIN_GAIN` = 4.99.
- **Renal sympathetic traffic — ADR 0024**, 2026-09-18. Kirchheim's measured threshold
  shift, `RAAS.RENIN.SYMPATHETIC_THRESHOLD_SHIFT` = 17 mmHg, and the arm is ON.

**So the renin signal that would drive `fr_angii` is no longer the rectified pressure-only
form whose ceiling this record flagged.** The structural limit it recorded — *"cannot
reproduce the human salt-induced renin response at any gain … ceiling is 1.40"* — has been
lifted by the two arms it named. **The reason this record gave for distrusting its own
input no longer applies.**

### But its arithmetic is stale, and that is why this is a review rather than an adoption

The Consequences reason throughout about **`G_pn` = 51**. That value came from **ADR 0013,
which is now `Superseded`** (2026-09-18): its implied slopes are `100 / sensitivity` from
the same three meta-analyses the model is validated against, computed under a
**pressure-only** assumption that ADR 0010's volume path replaced. **`G_pn` is 8.4.**

The human comparator it quotes is also stale: **`dMAP/dV_ecf` against 2.97–4.16** became
**2.82–4.02** on 2026-09-16, when `ecf_salt_response_extract.py` was found de-indexing van
den Bosch's extracellular volume with one body surface area where the paper prints one per
arm.

**Every bracket in the Consequences — 3.409–3.634, 1.536–1.639, 32.3–49.0, 21.5%, 50.7% —
was computed against a parameterisation that no longer exists**, and none of them is
re-computed here. **Re-running them is the adoption pass, not this one.**

### Why it stays `Proposed`, and the reason is now precise

**What it needs is a SOURCED MAGNITUDE for `fr_angii`, and this record forbids fitting
one.** Its own falsifiable-test section says so: *"Reproducing the human salt sensitivity
is not a test — the term would be sized to do that,"* and its Consequences add that the
magnitude *"must never be fitted to salt data."*

**That is a LITERATURE problem, not a code problem**, and it is the honest one-line reason
this record has stood open since 2026-09-02. What would move it: a human study giving the
**direct tubular sodium effect of angiotensin II at fixed renal perfusion pressure** —
the magnitude, separated from the haemodynamic and aldosterone routes. **Hall 1980's clamp
contrast, already named here as the falsifiable test, is the right shape of experiment and
is a dog preparation**; directive 1.15's reasoning about ethically-unperformable human
experiments may apply to it, and that has never been assessed for this record.

### What has NOT changed

- **The falsifiable test stands unchanged.** With `fr_angii` built and enabled, pinning it
  must increase the salt-step pressure shift by **at least 2×**. It is a manipulation the
  magnitude would not be set from, which is what makes it a test.
- **ADR 0016's ordering stands.** This record is still second and the fitted constant last.
- **The E1/E3 tiering stands**, including the declared conflict that the E1 claim is
  male-specific where it is quantified — Pechère-Bertschi 2002 finds no renal haemodynamic
  change in healthy women in the follicular phase.

---

## Source search — 2026-09-19. No human source exists; Hall 1984 supplies the magnitude

**At the owner's instruction: look for a human source, and if none exists go with Hall.**
**No parameter entered, no code changed.** This records what the search found.

### 1. NO HUMAN SOURCE EXISTS, AND THE REASON IS STRUCTURAL

Searched for the direct tubular sodium effect of angiotensin II **separated from the
haemodynamic route**. The best human candidate is **Eiskjaer H, Nielsen CB, Sørensen SS,
Pedersen EB. Eur J Clin Invest 1996;26(7):584-95, PMID 8864421** — **69 healthy subjects**,
ANG II at 1.5 ng·kg⁻¹·min⁻¹, **lithium clearance to resolve segmental tubular
reabsorption**, which is exactly the right instrument.

**It still does not isolate the quantity.** Its own abstract: ANG II alone *"caused a
decrease in glomerular filtration rate (GFR), renal plasma flow, urinary absolute and
fractional excretion of sodium…"* Every human ANG II infusion moves GFR and renal plasma
flow together with tubular handling — Eadington 1991 (PMID 1832351) measures the same
pattern, ERPF 665 → 498 and GFR 113 → 100 — so the tubular and haemodynamic routes stay
**confounded in every human preparation.**

**The manoeuvre that separates them is servo-control of renal perfusion pressure, and it is
not performable in a human.** That is the same ethical ceiling already recorded for
`RN.PRESSURE_NATRIURESIS.SLOPE` and for `RAAS.RENIN.PRESSURE_THRESHOLD`. **Directive 1.15
applies and Hall is the source.**

### 2. AND HALL 1984 IS A BETTER PAPER THAN THE HALL 1980 THIS RECORD NAMES

**Hall JE, Granger JP, Hester RL, Coleman TG, Smith MJ Jr, Cross RB.** *Mechanisms of
escape from sodium retention during angiotensin II hypertension.* Am J Physiol
1984;246(5 Pt 2):F627-34. **PMID 6720967. ABSTRACT ONLY — closed, no PMC record.**

Eight conscious dogs, ANG II at 5 ng·kg⁻¹·min⁻¹, renal arterial pressure either free or
**held by a servo-controlled aortic occluder**:

| | RAP free | RAP servo-controlled |
|---|---|---|
| cumulative Na balance, 6 days | no significant change | **+210 ± 37 mEq** |
| Na iothalamate space | no significant change | **+1,158 ± 244 mL** |
| MAP | 100 ± 3 → 132 ± 2, plateaus by day 3 | keeps rising, **157 ± 3** at day 6 |

Three of the eight servo-controlled dogs developed **pulmonary oedema** within 4–6 days.

**THE MAGNITUDE THIS RECORD ASKED FOR: 210/6 = 35 ± 6 mEq/day** of ANG II-driven sodium
retention **at fixed renal perfusion pressure.** Two significant figures, directive 1.13.
It is a **measurement, not a fit**, and it is not derived from any salt-sensitivity data —
which is what §"What is NOT decided" required.

**AND IT INDEPENDENTLY CONFIRMS THIS RECORD'S STRUCTURAL CHOICE.** Hall's conclusion is
that *"a rise in RAP is essential in allowing the kidneys to escape from the chronic
Na-retaining actions of ANG II."* **Escape is PRESSURE-mediated, not intrinsic to the
tubular effect** — which is exactly why this record specifies `fr_angii` as **not subject
to `esc`**. The design was right before the source was found.

**Hall 1980 (PMID 6254369 / 7004743) remains the FALSIFIABLE TEST and is untouched by
this**, so the test stays independent of the magnitude: control dogs take **< 7 mmHg**
across 5 → 500 meq/day, AngII-clamped dogs take **+42%**, about a six-fold amplification
against this record's ≥ 2× threshold.

### 3. THE BLOCKER HAS MOVED, AND THE NEW ONE IS PRECISE

**It is no longer "needs a magnitude."** It is:

> **The model has no absolute angiotensin II scale.** `pra` is normalised so that 1.0 is
> the rectified plateau, and resting `pra` is about 1.30. Hall's magnitude is stated at a
> specific **exogenous dose**, 5 ng·kg⁻¹·min⁻¹. Placing that dose on the model's `pra` axis
> needs a **dose → plasma concentration → normalised activity** chain, and no source for it
> was found.

**This is ADR 0010's obstacle in a different subsystem**, and that record solved it by
refusing to carry an absolute hormone concentration: *"carrying an explicit ANP
concentration state would add a variable the model cannot use correctly."* The same
reasoning applies here and the same answer may be right.

**WHAT WOULD CLOSE IT**, in order of preference:

1. **Hall 1984's full text**, which likely reports plasma ANG II for both arms — that would
   give the dose-to-concentration anchor directly. Am J Physiol 1984;246:F627-34, closed.
2. **Any conscious-dog study reporting plasma ANG II during a 5 ng·kg⁻¹·min⁻¹ infusion
   against its own control.** One number.
3. **A reformulation that avoids the absolute scale entirely** — expressing `fr_angii`
   against the model's own `pra` excursion. **That must not be calibrated against Hall
   1980's clamp contrast**, which is this record's test.

### 4. STATUS

**Still `Proposed`.** The magnitude is now **sourced and recorded**; what is missing is the
mapping, not the measurement. Nothing was entered, because entering 35 mEq/day without the
`pra` anchor would mean choosing the anchor to make the arithmetic work — a fit wearing a
citation.

---

## Result — 2026-09-19. Built, sourced, and REFUTED by this record's own test

**Pre-registered in `validation/angii_tubular_prereg.md`, before the term was written.**
Branches **A3 and A4 both fired.** Nothing was re-solved to rescue it.

### What was built

    fr_angii ~ k_angii * (pra - pra_ref)          zero at the operating point
    fr_mod   ~ (fr_raw - esc) + fr_angii          OUTSIDE esc, as this record specified

`RAAS.ANGII.TUBULAR_GAIN` = **0.0011** per unit `pra`, from Hall 1984's servo-controlled
arm: 24 ± 5 mEq/day of retention at **fixed renal perfusion pressure with plasma
aldosterone already back at control**, expressed as a fraction of the filtered load and
anchored on Hall's own statement that his dose reached sodium-deprivation ANG II levels.

**The operating point does not move.** MAP 87.0, `Na_excr` 205.0, urine 1.7 L/day, identical
with the term on and off, and the model is still 13 states.

### The refutation

| | required | measured |
|---|---|---|
| **pinning the term amplifies the salt-step shift** | **≥ 2×** (this record) | **1.2×** |
| Hall 1980's own clamp contrast | — | **about 6×** |

| chronic salt sensitivity | |
|---|---|
| term OFF | **2.0** |
| term ON | **1.6** — outside the human 1.70–2.30 |

**The term is roughly three to five times too weak to carry what Hall's clamp shows**, and
it takes the chronic sensitivity out of the human band on the way. **A3 says report and
leave it off; A4 says report the refutation regardless of how well the magnitude was
sourced.** Both were followed.

### The sign and the direction are RIGHT, which is what makes this a magnitude result

Switching the term on **lowers** salt sensitivity, because angiotensin II falling on high
salt **substitutes for a pressure rise**. That is Hall 1980's own conclusion — that ANG II
allows sodium balance *"without large fluctuations in glomerular filtration rate or arterial
pressure."* Pinning it removes the substitution and the sensitivity rises. **Everything
qualitative this record predicted is reproduced. Only the size fails.**

So this is **not** a refutation of the structure. It is a refutation of the claim that a
term of this magnitude accounts for the clamp contrast.

### What the failure most likely means, and none of it was acted on

1. **The dog → human fractional transfer** is the weakest link the pre-registration named,
   and it is the obvious suspect for a factor of three.
2. **The `pra` anchor.** Mapping "sodium deprivation" onto this model's 38 mEq/day arm is
   this repository's judgement, not Hall's. A more extreme anchor gives a larger `k_angii`.
3. **Hall's clamp is not the model's clamp.** He infused exogenous ANG II with endogenous
   renin *suppressed* (PRA 0.27 → 0.04); the model's `pra` conflates the two and cannot
   represent that dissociation. This is the deepest of the three and the hardest to fix.
4. **The term may not be the whole mechanism.** ADR 0015's own Consequences already said
   this record is *"necessary and nowhere near sufficient."* The measured 1.2× is that
   sentence with a number attached.

**None of these was pursued**, because pursuing them in the pass that found the failure is
choosing the anchor that makes the arithmetic work.

### What is now true that was not

- **The magnitude is sourced**, from the only preparation that can isolate it, with the
  full text read.
- **The structure is confirmed by the source** — escape is pressure-mediated, so the term
  belongs outside `esc`.
- **The record's falsifiable test has been RUN**, which it never had been. It was written to
  be able to fail and it failed.
- **`RAAS.PRA.REFERENCE`** was added so the term is zero at the operating point; it is a
  model-internal quantity and carries no claim about human plasma renin activity.

---

## Corroboration — 2026-09-19. Hall 1977 says the relation SATURATES, which is why the term is weak

**Full text supplied by the owner and read. No value changed, no code changed.**

**Hall JE, Guyton AC, Trippodo NC, Lohmeier TE, McCaa RE, Cowley AW Jr.** *Intrarenal
control of electrolyte excretion by angiotensin II.* Am J Physiol 1977;232(6):F538-F544.
**PMID 879288.**

### It is the endogenous version of the same experiment, and it needs no dose mapping

Instead of infusing exogenous angiotensin II, Hall **blocked the endogenous hormone**
with intrarenal [Sar¹,Ile⁸]angiotensin II — so the contrast is a dog's own angiotensin II
acting, against the same dog with it blocked, in the same kidney. **The anchor problem that
the 2026-09-19 search recorded as the precise blocker does not arise at all here.**

### The normal-sodium arm sits at this model's own operating point

Five normal dogs, Table 1, 90 min of blockade:

| | control | AngII blocked |
|---|---|---|
| **FE_Na** | **1.23 ± 0.19 %** | **1.74 ± 0.28 %** |
| GFR, ml/min per g | 0.83 ± 0.08 | 0.86 ± 0.11 — n.s. |
| MAP, mmHg | 128.2 ± 7.2 | 131.6 ± 5.8 |

**GFR and pressure unchanged, so the 0.51 percentage-point change is very nearly purely
tubular.** Endogenous angiotensin II accounts for **0.0051 of the filtered load** at normal
sodium status. And in four sodium-depleted dogs the blocker produced *"no consistent changes
in plasma aldosterone concentration"* — **the same exclusion Hall 1984 reaches by a
different design.**

### The two studies together say the relation SATURATES

| | fraction of filtered load |
|---|---|
| **total** AngII-dependent reabsorption at normal sodium (1977) | **0.0051** |
| **marginal** increment on raising AngII to sodium-deprivation levels (1984) | **0.00144** |
| ratio | **0.28** |

**Roughly a quarter of the resting effect is added by taking angiotensin II to
sodium-deprivation levels.** The tubular action is largely **saturated at normal
angiotensin II**.

### Which explains the refutation rather than overturning it

**The marginal slope really is small — that is physiology, not a sourcing error** — so the
measured **1.2× against the required 2× stands**. What this indicts is the **FORM**:
`fr_angii` linear in `pra` cannot represent a relation that is mostly saturated at rest with
a small marginal slope.

### A falsifiable prediction, recorded before it is tried

**A saturating form has a LARGER LOCAL SLOPE AT REST** than a straight line fitted across
`pra` 1.296 → 2.58, because the line averages over a range the curve flattens across. **So
replacing the linear term with a saturating one should RAISE the amplification above 1.2×.**

**If it does not, the form is not what is wrong**, and ADR 0015's own suspicion — that this
record is *"necessary and nowhere near sufficient"* — is the answer.

### What these numbers do NOT support

**Two points do not establish a saturation curve; they are consistent with one.** The
preparations differ: 1977 is intrarenal blockade in dogs whose kidneys averaged 59.5 ± 4.1 g;
1984 is systemic infusion with servo-controlled pressure. **And the sodium-depleted arm of
1977 is NOT usable for the tubular effect** — glomerular filtration rate rose 22% in it, and
the paper says that accounts for an important part of the natriuresis. **Only the
normal-sodium arm is clean.**

---

## The saturating form — 2026-09-19. My own prediction, REFUTED

**Pre-registered in `validation/angii_saturating_prereg.md`. Branch S3.** The form was
changed; **no other parameter moved, no band and no threshold moved.**

### What was predicted, and by whom

The prediction was written into this record on 2026-09-19, before it was tried:

> *"A saturating form has a LARGER LOCAL SLOPE AT REST … So replacing the linear term with
> a saturating one SHOULD RAISE the amplification above 1.2×. If it does not, the form is
> not what is wrong."*

**It does not.**

| | linear | saturating |
|---|---|---|
| local slope at `pra_ref` | 0.0011 | **0.00173** — 58% steeper |
| **amplification on pinning** | 1.225× | **1.254× — a 2% change** |
| chronic salt sensitivity, term ON | 1.60 | **1.61** |
| operating point | MAP 87.0, Na_excr 205.0 | **identical** |

**A 58% steeper local slope bought a 2% change in the quantity it was supposed to move.**
ADR 0015's threshold is ≥ 2×.

### Why the local slope did not translate

Two reasons, and the second is the important one.

1. **A saturating curve is steeper at rest and SHALLOWER above it.** Across the salt step's
   `pra` range of 1.03 → 2.52 the term's excursion grew only **16%**, not 58% — the extra
   steepness near the reference is spent again at the high-renin end.
2. **The term is too small a share of the system for its shape to matter.** §3.57 measured
   the volume-keyed path carrying **77% of the chronic sodium swing**, with pressure
   natriuresis, GFR and filtration carrying the remaining 23%. **A term of this magnitude
   cannot move a system-level ratio whatever its shape.**

### And my branch threshold was badly specified — recorded rather than glossed

§4's S3 reads *"amplification does NOT rise above 1.2×"*, but the linear baseline was
**already 1.225×**, so read literally every outcome satisfies S1 or S2. **That is a badly
written decision rule and it is my error.** The substantive prediction, quoted above, was a
rise **toward the ≥ 2× this record requires**. Against that reading, **2% is a refutation**
and it is scored as one.

### What this settles

**The form is not what is wrong.** This record's own Consequences said in 2026-09-02 that it
is *"necessary and nowhere near sufficient"* — **that is now the standing answer, with a
number attached: 1.25× against a required 2×, and insensitive to both the magnitude and the
shape of the term.**

**The saturating form is KEPT** even though it changed nothing, because it is the
better-sourced shape: it uses both Hall studies rather than one, and it respects the
measured saturation instead of contradicting it. `RAAS.ANGII.TUBULAR_GAIN` was deleted and
its provenance carried onto `RAAS.ANGII.TUBULAR_VMAX` verbatim.

**The term remains OFF**, and the chronic band is still left with it on (1.61 against a
1.70 floor).

### What would move this record next, and it is no longer a parameter

Nothing about `fr_angii` itself. **If the salt–renin response is to be reproduced, the
missing contribution is somewhere other than this term** — the candidates this repository
already names are tubuloglomerular feedback on the afferent arteriole, which ADR 0021
explicitly does not build, and the sympathetic effects on tubular reabsorption and afferent
arteriolar tone that ADR 0024 records as still absent.
