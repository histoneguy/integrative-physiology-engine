# ADR 0028: The tubule segments carry the flux, not just the signal

**Status:** Accepted
**Date:** 2026-09-21
**Evidence tier:** **E2** for the acute/chronic segmental asymmetry of sodium reabsorption
in man (Alexander 1972). The restructure itself is **definitional** — it adds no parameter.

Pre-registered in `validation/segmental_flux_prereg.md`.

## Context

ADR 0025 split the tubule and ADR 0026–0027 sourced the signals that come out of it. **The
excretion path was never moved.** Sodium excretion was still a whole-nephron fraction,

    FR_effective ~ 1 - (1 - FR_Na)*renal_mod + fr_mod - G_pn*ΔMAP/Na_filtered - vn_sig/Na_filtered

and **`Na_distal` was computed and read by nothing** — one test asserted its value, the GUI
exported it. The comment above it said so outright: *"THE SODIUM EQUATION ABOVE IS UNTOUCHED
AND THAT IS THE POINT."*

**That is the same defect `tubule_segments_prereg.md` diagnosed in `Na_prox_out` —** *"a
sourced, correct, salt-responsive quantity that does no work"* **— recurring one level
down.**

## Evidence

**Alexander EA, Doner DW Jr, Auld RB, Levinsky NG.** J Clin Invest 1972;51(9):2370-2379.
**PMID 4639021, PMC292404. ABSTRACT READ IN FULL; the full text is scanned page images on
both PMC and jci.org and could not be transcribed.** Adult and middle-aged men.

| manoeuvre | proximal FSR | distal FSR |
|---|---|---|
| acute isotonic saline, 37 mL/kg | −4.8% | **−4.4%** |
| comparable chronic expansion (mineralocorticoid escape) | −3.9% | **NOT ALTERED** |

> *"both acute and chronic extracellular expansion decrease proximal FSR in man, but only
> acute loading depresses distal FSR."*

**A lumped fraction cannot be unaltered and depressed at the same time.** The structure had
to change before any of this could be represented.

## Decision

    f_dist_excr ~ clamp((1 - f_dist_ref)*renal_mod - fr_mod/(f_prox*(1 - f_tal))
                        + (G_pn*ΔMAP + vn_sig)/max(Na_distal, 1e-6), 0, 1)
    Na_excr     ~ Na_distal * f_dist_excr
    FR_effective ~ Na_reabsorbed / Na_filtered        # kept, meaning unchanged

**NO PARAMETER WAS ADDED AND NONE WAS MOVED.** `f_dist_ref` = `1 − (1 − FR_Na)/(f_prox·(1 −
f_tal))` is derived in the component from rows already present, so **the operating point is
preserved exactly** rather than approximately. The circadian and aldosterone terms are now
fractions of what the segment *receives*, with `fr_mod` divided by the same delivery
fraction so its absolute effect at rest is unchanged. The pressure and volume terms stay
absolute fluxes in mEq/day, exactly as their estimation sets left them.

**Alexander's magnitudes are NOT entered.** His distal index is `C_H2O/V × 100`, a
free-water proxy, not this model's distal sodium fraction, and the full text that would
permit the conversion is scanned images. **Only the structure is taken** — Phase 2 of the
pre-registration was therefore **not built**, and §6/F2 is answered in those terms rather
than by fitting a number to an endpoint.

## Consequences

**THE ONE BEHAVIOURAL CHANGE IS THAT BASELINE EXCRETION NOW SCALES WITH DELIVERY.**
`Na_distal` carries `f_prox_eff`, which Folkerd 1995 made salt-responsive and which
**previously reached excretion through nothing at all**, because `f_prox_eff` cancels
exactly out of `md_conc`.

**JENSEN'S ACUTE RESPONSE: 49.5% → 59.9%**, with **no free parameter**. The band is 60–250
and the harness still reports it red by a third of a percentage point.

**AND THAT REMAINING GAP IS INSIDE THE MEASUREMENT.** `challenges.jl`'s own note records
that Jensen's reported statistics — FE_Na 1.26 (SD 0.53) → 2.80 (SD 0.75), n = 23, with no
paired correlation published — support **−18% to +502%**, and that the 60–250 band is
*"TIGHTER than the reported statistics can justify"*. **The band was not widened and Phase 2
was not built to cross it**; directive 1.14 says a disagreement inside the measurement's own
resolution is not a finding.

**THE DISABLED-RAAS BRANCH IS NO LONGER INERT, AND THAT IS THE RESULT.** Aldosterone escape
still drives `fr_mod` to machine epsilon at every steady state, so *that* route still
contributes nothing chronically. But RAAS now reaches excretion through a second path,
`pra → f_prox_eff → Na_distal → Na_excr`. Turning RAAS off **lowers** MAP by **0.336 / 0.433
/ 0.606 mmHg** at 205 / 154 / 103 mEq/day: without renin the proximal tubule passes more
sodium on, and excretion is delivery-scaled. **The separation grows as intake falls, which
is the direction Folkerd measured.** The suite assertion that the branch is inert was
**rewritten to pin the separation**, not loosened.

**CHRONIC SALT SENSITIVITY FELL 1.97 → 1.74** (band 1.70–2.30). It is inside, and it is
near the floor, and that is stated rather than left to be discovered. `G_vn` and `G_pn` were
**not** re-solved — §4 of the pre-registration forbade it, and re-solving them in the pass
that restructured their path is the double count this repository keeps catching.

**What did not change:** resting MAP 87.0, `Na_excr` 205.0, urine 1.70 L/day, GFR 152.6,
plasma sodium 140.0. `md_conc` 53.5 at 38 mEq/day against 53.96 at 230 — Vallon still holds.
Both Lobo endpoints and the acute ordering ratio pass. The chronic renin ratio is 1.302 and
remains a **failed test** since ADR 0027.

## What this disqualifies as evidence

**Jensen may not now be described as reproduced.** The model is at 59.9% against a band
floor of 60 and a measurement that supports anything from −18% to +502%. What can be said is
that a structural correction with no free parameter moved it 10 points in the right
direction.

**Alexander's 4.4% may not be quoted as entered.** It is not. If a future pass obtains the
full text and converts his free-water index to a sodium fraction, that becomes Phase 2.

**The 0.336–0.606 mmHg RAAS separation is a model prediction, not a measurement.** Nothing
bounds it; it is pinned as drift.
