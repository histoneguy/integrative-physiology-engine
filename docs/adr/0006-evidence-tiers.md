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
| **E2** | Replicated in humans with some open questions or mechanism partly inferred; **OR** replicated in an appropriate animal model where the human experiment is not ethically performable, with species, preparation and tested range recorded | Build after E1 spine exists. Default on. |
| **E3** | Single group, small-n, mechanism inferred not measured; or species-extrapolated **where human data exist and disagree, or the animal model is a poor homologue for the mechanism** | Build only as OPTIONAL, default OFF, with a falsifiable test |

**E3 structure-only exemption.** An E3 claim that informs structure but contributes no
state, component or numeric value has nothing to default off. Such a claim may be
retained by stating the exact phrase `STRUCTURE ONLY - no numeric value`. This came up
immediately: the rodent clock-gene mechanism in ADR 0005 motivates having a circadian
path at all, but the cosinor implementation does not depend on Per1 and takes no number
from it. The exemption must be claimed explicitly so it is a deliberate act rather than
an oversight - it is the obvious loophole in this policy and should be rare.
| **E4** | Contested or speculative | Do not build. Record and move on. |

Mixed claims are split: state the tier per claim, not per document.

**4. A claim resting on animal data states WHY no human study exists.**

Two different facts currently collapse into the same label. "Animal-derived because
the human experiment may not ethically be performed" and "animal-derived because
nobody has done the human study yet" are not the same claim, and only the second is
debt worth burning down. Say which. An ethical ceiling is a documented fact about the
limits of the field, not a deficiency in the parameter.


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

---

## Amendment, 2026-08-21: species is not a quality tier

**Retrospective.** This amends the tier table above in place; there is no second tier
system.

### What was wrong

The original E3 row lumped `species-extrapolated` together with `single group, small-n`
and `mechanism inferred not measured`, and E3 forces default OFF. That made species a
proxy for quality, which it is not.

Physiologists cannot always experiment on humans to find where a mechanism fails.
Nobody raises a conscious person's renal perfusion pressure to 160 mmHg to locate the
GFR autoregulation breakpoint, servo-clamps their renal artery for twelve days, or
knocks out their clock genes. Where the human study cannot ethically exist, a
well-conducted animal study is not a weaker substitute for it - it is the only
evidence there is, and demoting it does not make the model more human, it makes the
model rest on whatever unsourced human-labelled number happens to be lying around.

That is not hypothetical here. Taken literally, the original table would have:

- forced a **volume-sensing ANP component** to default OFF, because the servo-control
  experiments that motivate it are dog - while the pressure term it is meant to relieve
  stays on unchallenged. (That ADR is drafted but not yet in the repo; it is held
  pending sourcing, so it is described here rather than cited by number.);
- demoted **Roman & Cowley 1985** (rat), **Mizelle 1993** (dog) and **Hall** (dog), which
  are the entire primary basis of `Renal.FR_effective` - the model's spine;
- left `RN.PRESSURE_NATRIURESIS.SLOPE` in place at 20.0 with `species: human`, when it
  is not a human measurement at all but a fitted constant from Guyton 1972 carrying a
  human label.

The rule as written protected the fitted number and penalised the measured one.

### What changed

E2 now admits animal data where the human experiment is not ethically performable,
with species, preparation and tested range recorded. E3 keeps species-extrapolation
only where human data exist and disagree, or where the animal model is a poor
homologue. Rule 4 above requires the reason the human study is absent to be stated.

### What did NOT change

- **Documentation requirements are unchanged and remain the whole point.** Species,
  preparation, tested range, and whether a value is a bound rather than a measurement.
  `validation/pooling.md` still prohibits pooling across species: a dog value averaged
  with a human one describes no organism.
- **ADR 0004 (sodium storage) stays E3 and stays default OFF.** Its weakness is
  single-group small-n with the compartment inferred rather than measured, in *human*
  subjects. Species was never the issue. The amendment is narrow and does not rescue it.
- **Build order is untouched.** ADR 0005's circadian arm stays off because it modulates
  a subsystem that does not exist yet (rule 2), not because of its tier.
- **Censoring is still a caveat.** `RN.AUTOREG.UPPER = 160` is the highest pressure
  tested, so the true breakpoint is >= 160. That limitation survives the re-tiering
  untouched - it is about the experiment's range, not the species.

### Records re-tiered under this amendment

| ADR | Claim | Was | Now | Why |
|---|---|---|---|---|
| 0005 | Clock-gene mechanism, Per1 as early aldosterone target | E3 | **E2** | mouse; human clock-gene knockout is not performable. Contributes no numeric value either way, so the structure-only exemption it previously claimed is now unnecessary. |
| 0005 | Renal and CV rhythms are dissociable | E2 | **E2** | unchanged, but the rat Bmal1-/- basis is now correctly justified rather than tolerated |
| 0009 | Baroreflex open-loop gain 1.0-3.5 | *(no tier)* | **E2** | animal, vascularly isolated baroreceptors - a preparation definitionally impossible in humans. It previously carried no tier at all, which rule 1 forbids. |
| 0007 | "All three components rest on multiply-replicated human physiology" | E1 | **MIXED** | overstated. The pressure-natriuresis primaries are rat and dog. The *phenomenon* is E1; its quantitative form is E2 animal-derived under an ethical ceiling. |

`RN.AUTOREG.UPPER` and `RN.AUTOREG.LOWER` notes in `ledger/parameters.csv`, and the
evidence block in `src/components/Renal.jl`, are reworded to match: rat provenance
under an ethical ceiling is provenance, not debt. What remains genuine debt there is
the uncited piecewise FORM and the unsourced lower breakpoint.
