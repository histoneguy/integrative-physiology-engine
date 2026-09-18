# ADR 0005: Endogenous circadian driver

**Status:** Accepted
**Date:** 2026-08-08
**Evidence tier:** MIXED - see table below (E1 rhythm, E2 dissociation, E2 mechanism)
**Supersedes:** the rhythmicity motivation in ADR 0004

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| Circadian rhythm in renal Na handling exists, independent of posture and food/water intake | **E1** | Nat Rev Nephrol 2018 10.1038/s41581-018-0048-9; PMC6350809 | human |
| Nocturnal BP dips 10-20%; loss of dipping carries CV risk | **E1** | PMC6350809; PMC7400814 | human |
| Renal and CV rhythms are dissociable, so the arms need separate paths | **E2** | Hypertension 10.1161/HYPERTENSIONAHA.119.13908 | rat (Bmal1-/-) - knockout not performable in humans |
| Clock-gene mechanism: Per1 as early aldosterone target regulating ENaC/NHE3/ET-1 | **E2** | PMC6350809 | mouse - human clock-gene knockout not performable (ADR 0006 amendment 2026-08-21) |
| ETB receptor effects on Na excretion are time- and sex-dependent | **E2** | Am J Physiol Renal Physiol 2016;311:F991 | rat |

**This ADR was originally written without splitting these tiers, which obscured that
the two-arm structure rests on rodent data.** It is retained because independent
parameters can always be collapsed to a shared one, whereas a shared path cannot be
split without rework - the conservative choice under structural uncertainty. That
reasoning should have been stated at the time and is recorded now.

The E3 clock-gene mechanism claims the structure-only exemption of ADR 0006:
**STRUCTURE ONLY - no numeric value**. It motivates having a circadian path at all,
but the cosinor implementation does not depend on Per1 and takes no number from it.
The two rodent ledger rows are marker rows carrying no value.

## Context

Renal sodium handling has a well-established circadian rhythm. Renal plasma flow, GFR
and tubular reabsorption/secretion peak during the active phase and decline during the
inactive phase, driven at least in part by a self-sustaining cellular clock.

Decisively for modelling: **the diurnal rhythm of tubular sodium handling occurs
independent of posture and food/water intake.** It is an endogenous driver, not a
behavioural artefact. It therefore cannot be represented as a consequence of anything
else in the model.

Mechanism. Per1 is an early aldosterone target gene in the kidney, transcriptionally
regulating ENaC, SGLT1, NHE3 and endothelin-1 - all central to sodium reabsorption.
Per1 knockout mice challenged with high salt plus DOCP lose both the night/day
difference in sodium excretion and the inactive-period blood pressure dip.

Clinical weight. Blood pressure normally dips 10-20% during the inactive period. Loss
of dipping carries elevated cardiovascular risk and end-organ damage. The day/night
urinary sodium excretion ratio is independently associated with hypertension and target
organ damage.

Key references (see ledger for per-parameter citations):
- Circadian rhythms and the kidney. Nat Rev Nephrol 2018. doi:10.1038/s41581-018-0048-9
- Recent advances in understanding the circadian clock in renal physiology. PMC6350809
- Johnston JG, Speed JS, Jin C, Pollock DM. Loss of endothelin B receptor function
  impairs sodium excretion in a time- and sex-dependent manner.
  Am J Physiol Renal Physiol 2016;311:F991-F998. doi:10.1152/ajprenal.00103.2016
- Diurnal control of blood pressure is uncoupled from sodium excretion.
  Hypertension (Bmal1-/- rat). doi:10.1161/HYPERTENSIONAHA.119.13908

## Decision

An explicit endogenous circadian driver, implemented as an independent oscillator
supplying phase to subsystems that need it. Not derived from any other state.

Entry point is tubular sodium reabsorption, via the aldosterone-Per1-ENaC pathway.
This is physiologically grounded rather than bolted on: the circadian signal reaches
sodium handling through a route that has to exist in the model anyway.

## Structural consequence 1: BP and sodium rhythms are dissociable

In whole-body Bmal1 knockout rats, males showed no significant difference in baseline
sodium excretion between active and inactive periods **while circadian MAP rhythms
remained intact**.

The two rhythms can be separated experimentally, so the model must be able to separate
them. The sodium rhythm must NOT be derived from the pressure rhythm. Each needs its
own path from the clock.

This is a falsifiable structural commitment: the model should be able to reproduce the
Bmal1 knockout phenotype by disabling the renal clock path alone.

## Structural consequence 2: THERE IS NO STEADY STATE

This is foundational and it invalidates earlier assumptions.

With an endogenous oscillator, every equilibrium is a **24-hour limit cycle**, not a
fixed point. Consequences:

- `validation/targets.md` steady-state tolerance must be restated as a tolerance on
  the cycle-averaged value, plus a separate tolerance on cycle amplitude and phase.
- Initialisation cannot solve for a fixed point. It must find a limit cycle, or start
  from a declared phase and discard a settling transient.
- **Every reported value must state its phase or its averaging window.** A bare
  "MAP = 93 mmHg" is now ambiguous.
- Solver-agreement checks must compare on a common phase grid.

## Timescale placement

Period is 24 h. Slower than baroreflex (1-5 s), faster than renal-body fluid
equilibration (days). It sits between the two.

Cost is negligible: resolving a 24 h oscillation needs perhaps 10^2 steps per day,
against a horizon measured in tens of days. It does not force the fast block.

It is a DRIVEN oscillation with a fixed period, so it does place a floor under step
size - but at 24 h that floor is far above anything else in the model. Cycle-averaging
(ADR 0002) removed cardiac and respiratory cycles and does not touch this one.

For ADR 0003 partitioning: the clock is an exogenous input with no feedback from the
model, so it may be evaluated in either block without coupling error. This is the one
genuinely free partition boundary in the system.

## Species caution

The human circadian sodium rhythm and BP dipping are documented in humans. The
**clock-gene mechanism is largely rodent** (Per1, Bmal1 knockouts). These require
separate ledger rows with honest species flags, and rodent-derived values must state
their scaling assumption.

## Sex dependence

Endothelin B receptor effects on sodium excretion are time- AND sex-dependent, and the
Bmal1 rat findings differ by sex. Sex is therefore a population covariate in the
circadian arm, not a nuisance parameter. Relevant to `sample_population`.

## Validation consequence - ACT ON THIS

**Mars500 cannot constrain any of this.** Daily 24-hour collections average the
circadian rhythm out entirely. The primary anchor for the body-fluid subsystem is
silent on the circadian question.

Constraining it requires **split day/night collections**. Human population datasets
reporting day/night UNaV ratios exist and must be added as the primary circadian
target. See `validation/targets.md`.


## Falsifiable test

Setting `renal_gain = 0` with `cv_gain` unchanged must abolish the sodium rhythm while
preserving the MAP rhythm, reproducing the Bmal1-/- rat phenotype. If the model cannot
dissociate them, the two-arm structure is wrong.

Separately: day/night UNaV ratio must fall within the observed human population
distribution without tuning the CV arm.

---

## Addendum, 2026-08-21 - re-tiered under the ADR 0006 amendment

The clock-gene mechanism row moves E3 -> E2. Its rodent basis is not a weakness that
can be remedied: human clock-gene knockout is not a study anybody may run. Under the
amended ADR 0006 that is an ethical ceiling, recorded as such, not debt.

**This does not turn the circadian arm on.** It stays `circadian = false` for the
reason it always has - ADR 0006 rule 2, build order. It modulates renal tubular
reabsorption, which needs RAAS and ADH before the modulation means anything. Nothing
about the tier changes that.

The structure-only exemption this ADR previously claimed for the mechanism row is now
unnecessary, since the row is no longer E3. The claim still contributes no numeric
value - the cosinor implementation takes nothing from Per1 - so the practical position
is unchanged.

---

## Evidence moved out of `ledger/parameters.csv`, 2026-09-17

**"No more unreferenced rows. Make that a structural change."** — the owner. A row nothing
reads cannot be contradicted by anything, so it is not evidence *about the model*; and a
row that no equation and no gate can read is **not a parameter**. The entries below were
marker rows in the parameter ledger. Their evidence is real and is kept here, where
evidence belongs; the CSV rows are gone and `check_relations.py` now fails on any
replacement.

### `CIRC.PER1.MECHANISM_MARKER`

**Clock gene mechanism evidence marker** — recorded value 1 unitless, tier C, reported.

**Source.** Recent advances in understanding the circadian clock in renal physiology. PMC6350809.

**Why it was in the ledger, and why it is not a parameter.** MARKER ROW - not a value. SPECIES: mouse. Per1 knockout mice under high salt plus DOCP lose the night/day difference in sodium excretion and the inactive-period BP dip. Recorded because the clock-gene MECHANISM is rodent-derived while the human circadian sodium rhythm and BP dipping are separately documented in humans. No scaling is applied because no numeric value is taken from this - the mechanism informs structure only. || CITATION FLAGGED 2026-08-25 BY AUDIT. This row cites a title and a PMC identifier with NO AUTHOR LIST and no DOI, and the title does not resolve on a PubMed title search. It must be replaced with a full citation - authors, journal, year, volume, pages - or removed. Until then the parameter should be treated as uncited, not as tier-supported. || ROUNDED 2026-09-09 TO MEASUREMENT PRECISION at the owner's instruction. Nothing physiological in this model is measured to more than four significant figures, and trailing zeros on a whole number read as precision that is not there. The discarded digits were floating-point residue from the derivation, not information. Directive 1.13.

### `CIRC.BMAL1.DISSOCIATION_MARKER`

**BP and sodium rhythm dissociation marker** — recorded value 1 unitless, tier A, reported.

**Source.** Johnston JG, Speed JS, Becker BK, Kasztan M, Soliman RH, Rhoads MK, Tao B, Jin C, et al. Diurnal control of blood pressure is uncoupled from sodium excretion. Hypertension 2020;75(6):1624-1634.

**Why it was in the ledger, and why it is not a parameter.** MARKER ROW - not a value. SPECIES: rat, whole-body Bmal1 knockout. Male knockouts showed no significant difference in baseline sodium excretion between 12-h active and inactive periods while circadian MAP rhythm remained intact. This is the evidence for independent renal and cardiovascular clock arms in Circadian.jl. No scaling applied - structural evidence only, no numeric value taken. || CITATION CORRECTED 2026-08-25 BY AUDIT. The row carried the title and journal with NO AUTHOR LIST, which is the exact shape that let a misattribution survive two sessions on PMID 2966064. Resolved via Crossref on the recorded DOI: first author Johnston JG, and the year is 2020, NOT 2019 - the .119. in the DOI is the submission-year convention and is misleading. || ROUNDED 2026-09-09 TO MEASUREMENT PRECISION at the owner's instruction. Nothing physiological in this model is measured to more than four significant figures, and trailing zeros on a whole number read as precision that is not there. The discarded digits were floating-point residue from the derivation, not information. Directive 1.13.

### `CIRC.RENAL_NA.ENDOGENEITY_MARKER`

**Marker: the urinary sodium rhythm persists under constant routine** — recorded value 1 unitless, tier A, reported.

**Source.** el-Hajj Fuleihan G, Klerman EB, Brown EN, Choe Y, Brown EM, Czeisler CA. The parathyroid hormone circadian rhythm is truly endogenous - a general clinical research center study. J Clin Endocrinol Metab 1997;82(1):281-286.

**Why it was in the ledger, and why it is not a parameter.** STRUCTURE MARKER, contributes no numeric value to any equation - it records WHY the renal arm is modelled as an endogenous driver at all, which is the claim ADR 0005 rests on. el-Hajj Fuleihan 1997: 11 healthy male volunteers, 36 h baseline followed by 28-40 h of constant routine - enforced wakefulness, strict semirecumbent posture, hourly snacks. Urinary calcium/creatinine, phosphate/creatinine and sodium/creatinine all showed a diurnal rhythm at baseline; the calcium and phosphate rhythms changed character under constant routine WHEREAS THAT OF URINARY SODIUM/CREATININE WAS UNCHANGED. An unmasked rhythm that survives removal of sleep, posture and meal timing is endogenous. CONTRAST WITH THE CARDIOVASCULAR ARM, where the same class of experiment is in open disagreement - see CIRC.CV_MAP.AMPLITUDE. The renal arm's premise is on firmer ground than the cardiovascular arm's, which is the reverse of what the placeholder parameters implied. || ROUNDED 2026-09-09 TO MEASUREMENT PRECISION at the owner's instruction. Nothing physiological in this model is measured to more than four significant figures, and trailing zeros on a whole number read as precision that is not there. The discarded digits were floating-point residue from the derivation, not information. Directive 1.13.

