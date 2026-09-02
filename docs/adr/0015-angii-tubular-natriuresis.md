# ADR 0015: A non-escaping AngII tubular term, so sodium balance is not reached by pressure alone

**Status:** Proposed
**Date:** 2026-09-02
**Evidence tier:** MIXED — E1, E3.

- **E1** — that chronic high sodium intake suppresses the renin-angiotensin system and
  raises renal plasma flow and GFR in healthy humans. Four independent groups, n up to 95.
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
| High Na suppresses RAS and raises renal plasma flow and GFR | **E1** | Krikken 2007 (n=95, PMID 17091123); van den Bosch 2021 (n=70, ERPF 592 vs 559, GFR 138 vs 128, PRA 2.10 vs 5.74, PMID 34921521); Redgrave 1985 normotensive controls (RBF +79±28 mL/min/1.73 m², **BP unchanged**, PMID 2985655); Conlin 1993 (modulation reversed in 3–7 h, PMID 7503952) | **human** |
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
- **ADR 0013 becomes a competing explanation rather than a complementary one.** It raises
  `G_pn` 20 → 51 to get 1.944 mmHg/100 mmol from a fitted constant; this gets 2.444 from a
  mechanism. **Both cannot be adopted at full strength** — that would double-count the same
  discrepancy. Whichever lands second must be re-estimated against the other.
- **`RAAS.RENIN.PRESSURE_GAIN` must be re-derived first.** It is calibrated against a
  baseline that no longer exists, and this term amplifies whatever it carries.
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
