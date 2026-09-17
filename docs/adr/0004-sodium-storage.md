# ADR 0004: Osmotically inactive sodium storage

**Status:** Provisional
**Evidence tier:** E3 - single group, small-n 23Na MRI, compartment inferred not measured, limited independent uptake
**Default:** `storage = false` (default OFF, required for E3 per ADR 0006)
**Date:** 2026-08-08

## Context

The classical formulation - Guyton-Coleman lineage and most descendants - treats all
body sodium as osmotically active. Extracellular volume therefore tracks extracellular
sodium content directly, and daily urinary sodium excretion reflects intake once a
steady state is reached.

The Mars500 balance studies contradict this.

Rakova N et al, *Long-term space flight simulation reveals infradian rhythmicity in
human Na+ balance*, Cell Metab 2013;17(1):125-131, doi:10.1016/j.cmet.2012.11.013.

Design: enclosed habitat, salt intake the only modified variable, stepped 12 -> 9 -> 6
g/day NaCl in Mars105 and back to 12 g/day in Mars520, each level held 30-60 days.
12 men, all urine collected daily, ~95% recovery of dietary electrolytes.

Findings that matter to us:
- Total-body Na+ is stored, and is NOT a simple function of salt intake.
- Total-body Na+ and extracellular water are NOT tightly coupled.
- Na+ balance shows infradian rhythmicity - 7-day and monthly cycles - at constant
  intake.

Storage appears to be largely in skin and other tissue binding sites. Independent
support: 23Na MRI shows skin Na+ content increasing with age at
0.34 +/- 0.07 mmol/(L*year).

## Decision

A third compartment: osmotically inactive stored sodium, exchanging with the
extracellular pool through a first-order lag.

`storage = false` recovers classical two-compartment behaviour. That switch exists as
a VALIDATION EXPERIMENT, not a fallback - reproducing the classical failure against
the Mars500 series is itself a result worth having.

## Why this matters beyond fidelity

A two-compartment model cannot reproduce the best available human sodium balance
dataset. Building it and then discovering that would waste a subsystem's worth of
estimation effort against a structure known in advance to be wrong.

This is also the clearest instance so far of the project's premise paying off. The
data did not exist in 1972. Coleman's structure was correct given what was known;
it is not correct given what is known now.

## What is NOT decided

The structure is accepted. The parameters are placeholders and are marked `assumed`
in the ledger:

- `BF.NA.OSMOTICALLY_INACTIVE_FRACTION` = 0.15. Rakova et al do not report a single
  storage fraction. This number exists only to make the compartment functional.
- `BF.NA.STORAGE_TAU` = 7 days. Chosen to MATCH the reported weekly rhythm, not
  derived from it. A first-order lag is the crudest structure that can produce
  retention and release on that scale.

Both must be estimated against the Mars500 series before any result involving sodium
balance is reported. Until then `unledgered_check()` will surface them, and it should.

A first-order lag may also prove structurally inadequate: it cannot generate the
monthly rhythm, and it cannot generate rhythmicity at constant intake at all, since
it has no oscillatory mode. If estimation fails to fit the data, the honest conclusion
is that the structure needs revising - possibly an active, clock-driven process rather
than passive buffering - not that the parameters need more tuning.

## Consequences elsewhere

- `Na_total = Na_ecf + Na_store` is a hard conservation assertion in the test suite.
- All three body-fluid couplings are Conservation or Mechanical class, so per ADR 0003
  no multirate partition may cut across them.
- Storage tau (7 d) sits in the slow block. Osmotic equilibration tau (30 min) is much
  faster but is still far slower than baroreflex, so it does not force the fast block
  either.


---

## Amendment, 2026-08-08: downgraded to Provisional, default off

Raised in review: the skin sodium storage story attracted attention but limited
independent uptake, and it has not been incorporated into how the field actually
models sodium handling.

That criticism is accepted. Two claims were conflated here and must be separated:

- **The balance measurement** - urinary Na+ excretion not tracking intake day to day
  under long controlled feeding - is a reasonably clean observation with good
  collection discipline. It stands.
- **The skin storage mechanism** - the proposed explanation - rests on small-n 23Na
  MRI, infers a compartment rather than measuring it directly, and has attracted
  limited independent corroboration.

An architectural decision was taken on the strength of a single paper found in two
searches. The ledger disciplines numbers; nothing disciplined the topology. That is a
real gap in the provenance machinery and it should be treated as one.

**Also a prioritisation error.** The model's spine is pressure natriuresis and the
renal-body fluid feedback. Sodium storage is a side branch. Even if correct, a ~15%
pool with a weekly time constant is second-order against the main loop over the
horizons this model targets.

### What changes

- Default flips to `storage = false`. The classical two-compartment formulation is now
  the baseline that gets built and validated.
- The compartment stays, as a testable hypothesis, available once the renal loop
  exists and can be perturbed. It costs nothing to leave in and the switch is written.
- Mars500 remains in `validation/targets.md` - long controlled sodium feeding with
  daily collections is a good target regardless of what one concludes about mechanism.

### Superseded as the explanation for rhythmicity

The infradian (7-day, monthly) rhythmicity Rakova et al report was the motivation for
the storage lag. The far better-supported rhythm in renal sodium handling is
**circadian**, and it now has its own decision record with a genuine mechanism behind
it. See **ADR 0005**.

Note also that a first-order storage lag never could have produced rhythmicity at
constant intake - it has no oscillatory mode. That objection was recorded above before
this downgrade, and it should have been enough on its own to prevent acceptance.


## Falsifiable test

Required for E3 (ADR 0006).

Once the renal loop exists and can be perturbed: apply a step change in sodium intake
and compare cumulative Na+ balance against the Mars500 series with `storage = true`
and `storage = false`. If the storage compartment does not measurably improve the fit
to cumulative balance, it is not earning its place and should be removed rather than
retuned.

Note the prior objection stands independently: a first-order lag cannot generate
rhythmicity at constant intake, so it cannot explain the observation that motivated it.

---

## Amendment, 2026-09-17 — the single compartment cannot carry three timescales

**HANDOVER §3.51, `validation/sodium_store_sourcing_prereg.md` branch T4.** Rakova 2013 was
finally opened — it is **Open Archive on cell.com** and had been cited in this record and on
both parameter rows since 2026-08-08 **without ever being read here**.

### What this record attributed to it, checked

| claim above | verdict |
|---|---|
| stepped 12 → 9 → 6 g/day NaCl, 30–60 days per level | **verified** |
| 24 h urine daily, ~95% recovery | **verified**, verbatim |
| total-body Na⁺ not a simple function of salt intake | **verified** |
| total-body Na⁺ and extracellular water not tightly coupled | **verified**, ±200–400 mmol |
| **"12 men"** | **NOT CONFIRMED** in the abstract or the Results text read — the paper says only *"men participating in space flight simulations"*, and Mars105 and Mars520 are separate crews |
| **"7-day … cycles"** | **IMPRECISE** — the paper reports *"peaks at about **6 days** period length"* |

### Three timescales, and this record has one compartment

| | timescale |
|---|---|
| Olde Engberink 2017 (PMID 28132715), acute inactivation in healthy men | **2–4 hours** |
| Rakova, urinary Na⁺ excretion rhythm | **~6 days** |
| Rakova, total-body Na⁺ rhythm | **monthly and longer** |

**A single first-order compartment cannot produce all three**, and `storage = true` gives
this model exactly one. That is a defect in this record's **structure**, not in its
parameter values.

### And `BF.NA.STORAGE_TAU` is wrong in kind, not only in value

Its note says the 7 d was *"chosen to match the reported weekly infradian rhythm period
rather than derived from it."* **A rhythm period is not a first-order relaxation time
constant** — an oscillation against a relaxation — and nothing converts one into the other.
The rounding from ~6 days is the smaller error.

### Status is UNCHANGED and deliberately so

**`Provisional` stands, tier E3 stands, `storage` stays `false` by default, and neither
parameter row moved.** §3.2 of the pre-registration: *"osmotically inactive"* is inferred
from a balance discrepancy in the sources too — Olde Engberink's own limitation is that they
*"did not directly measure the amount of nonosmotic Na⁺ stored in the tissues"* — so E3 does
not improve merely because two citations were finally read.

**What this record needs next is a structural decision, not another citation**, and it needs
its own pre-registration.
