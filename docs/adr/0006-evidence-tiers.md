# ADR 0006: Evidence tiers for structural claims, and build order

**Status:** Accepted
**Date:** 2026-08-08
**Applies to:** every ADR making a physiological structural claim, retrospectively

## Context

Two structural decisions were taken on thin evidence and had to be walked back:
sodium storage (ADR 0004, downgraded) and the ordering of the circadian work
(ADR 0005, sound but built before the loop it modulates).

The parameter ledger enforces provenance on every NUMBER - citation, tier, extraction
method, species. Nothing enforced anything on TOPOLOGY, which is the larger commitment.
A wrong parameter is re-estimated; a wrong structure invalidates the estimation.

## Decision

**1. Every ADR making a structural claim declares an evidence tier.**

| Tier | Meaning | Permitted use |
|---|---|---|
| **E1** | Multiply replicated in humans, mechanistically understood, textbook-level | Build first. Default on. |
| **E2** | Replicated, human data, some open questions or mechanism partly inferred | Build after E1 spine exists. Default on. |
| **E3** | Single group, small-n, mechanism inferred not measured, or species-extrapolated | Build only as OPTIONAL, default OFF, with a falsifiable test |

**E3 structure-only exemption.** An E3 claim that informs structure but contributes no
state, component or numeric value has nothing to default off. Such a claim may be
retained by stating the exact phrase `STRUCTURE ONLY - no numeric value`. This came up
immediately: the rodent clock-gene mechanism in ADR 0005 motivates having a circadian
path at all, but the cosinor implementation does not depend on Per1 and takes no number
from it. The exemption must be claimed explicitly so it is a deliberate act rather than
an oversight - it is the obvious loophole in this policy and should be rare.
| **E4** | Contested or speculative | Do not build. Record and move on. |

Mixed claims are split: state the tier per claim, not per document.

**2. Well-established relationships are built before anything that modulates them.**

A modulator of a subsystem that does not exist cannot be validated, tuned, or
falsified. Order by evidence tier first, dependency second.

**3. Structural claims carry citations like parameters do.**

Every ADR lists the sources its structure rests on. `docs/adr/TEMPLATE.md` enforces
the shape; `tools/check_adrs.py` fails CI on a missing tier or evidence section.

## Retrospective tiers

| ADR | Claim | Tier |
|---|---|---|
| 0001 | Julia / MTK / adaptive stiff | n/a - methodological |
| 0002 | Cycle-averaged formulation | n/a - methodological |
| 0003 | Multirate deferred; partition rule | n/a - methodological |
| 0004 | Osmotically inactive sodium storage | **E3** - default off, consistent |
| 0005 | Circadian rhythm in renal Na handling exists, independent of posture and intake | **E1** |
| 0005 | Nocturnal BP dip 10-20%, loss associated with CV risk | **E1** |
| 0005 | Clock-gene mechanism (Per1, aldosterone-ENaC path) | **E3** - rodent |
| 0005 | Renal and CV arms are dissociable, so separate paths | **E2** - rat Bmal1 |

ADR 0005 is mixed and was not marked as such. The rhythm is E1; the two-arm structure
rests on rodent data and is E2. It is retained because independent parameters can
always be collapsed to a shared one, whereas a shared path cannot be split without
rework - the conservative choice under uncertainty. That reasoning should have been
stated at the time.

## Build order

**Spine first - all E1, all required before any modulator connects.**

1. **Renal sodium handling.** GFR, filtered load, tubular reabsorption, pressure
   natriuresis. The long-run arterial pressure setpoint and the model's spine.
2. **Cardiovascular mechanics.** Frank-Starling, venous return, MAP = CO x TPR,
   arterial and venous compliance.
3. **Baroreflex.** Fast arm. The most thoroughly characterised control loop in
   integrative physiology.
4. **RAAS.** Renin, angiotensin II, aldosterone. Slow arm of pressure control.
5. **ADH and osmoregulation.** Closes water balance against BodyFluids.

**Then modulators.**

6. Circadian (ADR 0005) - ALREADY BUILT, currently connects to nothing. Wire to renal
   tubular reabsorption once step 1 exists.
7. Sodium storage (ADR 0004) - E3, optional, default off. Test only once the renal
   loop can be perturbed.

## Consequence for work already done

`Circadian.jl` stays. It is correct and its evidence is good. It is simply ahead of
its dependency and will sit unconnected until renal handling exists. That is a
sequencing cost, not a correctness problem, and it is recorded rather than hidden.
