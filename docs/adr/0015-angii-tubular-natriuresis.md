# ADR 0015: A non-escaping AngII tubular term, so sodium balance is not reached by pressure alone

**Status:** Proposed
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
