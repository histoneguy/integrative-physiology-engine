# ADR 0004: Osmotically inactive sodium storage

**Status:** Accepted (was Provisional; see the 2026-09-17 re-tiering amendment)
**Evidence tier:** E2 - replicated in humans by three independent groups; compartment still inferred rather than measured (was E3)
**Default:** `storage = true` (default ON, permitted for E2 per ADR 0006)
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

---

## Amendment, 2026-09-17 (second) — scoped to the acute process, structure (C) adopted

**HANDOVER §3.52, `validation/sodium_store_structure_prereg.md` branch X1.**

### The compartment is now explicitly scoped

Three timescales are in evidence — **2–4 hours** (Olde Engberink 2017), **~6 days** and
**monthly and longer** (Rakova 2013) — and one first-order compartment carries one.

**THIS COMPARTMENT REPRESENTS THE ACUTE PROCESS. The circaseptan and monthly rhythms are
OUT OF SCOPE**, declared rather than forgotten, and the reason is a property of this model
rather than of the physiology: **it has no machinery to generate an infradian rhythm and no
protocol longer than the 30-day salt step in which one would show.**

**Structure (A) — two parallel compartments — was considered and NOT built.** §2.1 of the
pre-registration fixed in advance that **nothing this model runs distinguishes it from the
scoped single compartment**, and four parameters that nothing can test is what directive
1.10 and this repository's own evidence tiers exist to prevent. *That is a statement about
the model's reach, not about the body.*

### `BF.NA.STORAGE_TAU`: 7 d → 0.1 d, and the old value was wrong in kind

It came from Rakova's circaseptan rhythm, which that paper reports at *"about **6** days"*.
**But a rhythm period is not a first-order relaxation time constant** — an oscillation
against a relaxation — and the row's own note admitted it was *"chosen to match … rather
than derived from it."*

The new value is an **order of magnitude at one significant figure**, from Olde Engberink's
measured 2–4 h inactivation. Range 0.05–0.2 d. It is **not** the best-performing value in
the model's own sweep (0.25 d was), and the overlap with that sweep's 0.05–0.25 d is
recorded on the row as two independent routes agreeing the process takes **hours**.

### `BF.NA.OSMOTICALLY_INACTIVE_FRACTION` did NOT move

The combined sweep needs ≈0.40 to reproduce Drummer's half-life ratio. **That is the
model's requirement, not a measurement**, and §3.51 established that none of the available
sources measures this row's quantity: Olde Engberink gives a buffering fraction of a load,
Rakova a swing amplitude, and this row is a steady-state ratio. **It stays `assumed` at
0.15.**

### Status unchanged, and the reason is now sharper

**`Provisional` and tier E3 stand. `storage` stays `false` by default.** The compartment is
chronically inert — the sweep measured the chronic salt sensitivity as **identical to four
figures at every store setting** — so switching it on changes nothing this model is
currently judged on, and the acute behaviour it does change is entangled with the
natriuretic gain question in §3.52 that this record cannot settle alone.

---

## Evidence moved out of `ledger/parameters.csv`, 2026-09-17

**"No more unreferenced rows. Make that a structural change."** — the owner. A row nothing
reads cannot be contradicted by anything, so it is not evidence *about the model*; and a
row that no equation and no gate can read is **not a parameter**. The entries below were
marker rows in the parameter ledger. Their evidence is real and is kept here, where
evidence belongs; the CSV rows are gone and `check_relations.py` now fails on any
replacement.

### `BF.ECW.QUANTILE_REFERENCE`

**Extracellular water reference distribution source** — recorded value 1 unitless, tier A, reported.

**Source.** Extracellular water across the adult lifespan: reference values for adults. Physiol Meas 2007;28(5).

**Why it was in the ledger, and why it is not a parameter.** MARKER ROW - not a value. n=1538 multi-ethnic adults, ECW from isotope dilution and whole-body 40K counting, conditional quantile equations by weight height age sex race. This is the better source for a POPULATION DISTRIBUTION than any point estimate and should replace the BIA-derived fractions above once the equations are extracted. Extraction blocked: full text not retrieved. || ROUNDED 2026-09-09 TO MEASUREMENT PRECISION at the owner's instruction. Nothing physiological in this model is measured to more than four significant figures, and trailing zeros on a whole number read as precision that is not there. The discarded digits were floating-point residue from the derivation, not information. Directive 1.13.

### `BF.NA.SKIN_ACCUMULATION_RATE`

**Skin sodium accumulation with age** — recorded value 0.34 mmol/(L*year), tier A, reported.

**Source.** Titze J et al, 23Na MRI at 7.0 Tesla, n=17 men. Reported in Rakova N, Sodium Balance (dissertation), Freie Universitaet Berlin.

**Why it was in the ledger, and why it is not a parameter.** Described by the source as preliminary in vivo data. Not used in the current model - recorded because it constrains the storage compartment on long horizons and will matter if the model is ever run across decades. || CITATION FLAGGED 2026-08-25 BY AUDIT. This is a SECONDARY CITATION: the value is attributed to Titze et al but the stated source is 'Reported in Rakova N, Sodium Balance (dissertation)'. The primary was never opened. Directive 1.5 forbids writing a citation nobody has read, and a dissertation reporting another group's MRI data is two removes from the measurement. Obtain the Titze primary or downgrade the row.

---

## Amendment, 2026-09-17 (third) — re-tiered E3 to E2, and switched on

**The tier moved because the evidence moved, and the default follows the tier.**

ADR 0006's amendment of 2026-08-21 pinned this record at E3 in these words: *"Its weakness
is single-group small-n with the compartment inferred rather than measured, in human
subjects."* **The first half of that is no longer true.**

| group | study | what it contributes |
|---|---|---|
| Erlangen / Berlin (Titze, Rakova) | Cell Metab 2013;17:125–131, **read 2026-09-17** | total-body Na⁺ varies ±200–400 mmol at fixed intake without parallel changes in body weight or extracellular water |
| **Amsterdam** (Olde Engberink, Vogt) | Kidney Int 2017;91:738–745, **read 2026-09-17** | 12 healthy men; only 47% and 55% of expected Na⁺ and K⁺ excretion retrievable in urine after an acute load |
| **Antwerp** (Van Regenmortel, Jorens) | J Crit Care 2022;67:157–165, **read 2026-09-17** | 12 healthy volunteers; ΔNa 171 mmol → Δfluid 590 mL, about half what plasma tonicity implies |

**Three independent groups, all human. E3's "single group" criterion is not met; E2's
"replicated in humans with … mechanism partly inferred" is met exactly.** The second half
of ADR 0006's objection stands and is *why this is E2 and not E1*: Olde Engberink's own
limitation is that they *"did not directly measure the amount of nonosmotic Na⁺ stored in
the tissues."*

### THE FALSIFIABLE TEST THIS RECORD NOW PASSES, AND IT IS A SIGN

Drummer 1992 fits **two** half-lives to an acute isotonic load: body weight **7 h**, sodium
balance **10 h**. **Weight returns first — ratio 0.70.** With the compartment off the model
gave **1.065**: water could not leave ahead of salt, because extracellular volume is tied
to extracellular sodium and there was nowhere to put sodium that did not carry water.

**Switched on at the ledger values, the ratio is 0.910.** The ordering is correct. The
magnitudes are not, and per directive 1.14 they are not chased: Drummer's half-lives are
fitted to **n = 6 with no published dispersion** and support no interval at all. **What is
claimed here is the sign, and a sign survives the noise.**

### WHAT IT COST, REPORTED RATHER THAN ABSORBED

- **Chronic salt sensitivity: unchanged at 1.96.** The compartment is chronically inert —
  measured identical to four figures at every store setting swept.
- **Jensen's final window: 110 → 102** against a measured 122. Further away, and inside
  what that measurement resolves. The drift pin was **re-pinned with the reason on it**.
- **`urine volume, 6 h after infusion`: 708 → 852 mL, and `validation/challenges.jl` now
  FAILS it.** The band is 380–750 and is labelled in its own source line as *"BAND ASSUMED
  ±33%, no dispersion published"* around Lobo's mean of 563. **The band was not widened.**
  The model was already 26% above Lobo's mean before this change and the store added a
  further 144 mL, by the mechanism this record is about: sodium leaves the osmotically
  active pool, tonicity falls slightly, vasopressin is suppressed and the water that sodium
  would have held is excreted. **That is the dissociation working, and the magnitude is a
  separate defect in the water limb** — `RN.URINE.SOLUTE_NONNA`'s own note already records a
  measured ~30% over-response on the solute limb against Kitada. Named, not absorbed.

### AND TURNING IT ON FOUND A BUG THAT COULD NOT HAVE BEEN FOUND WITH IT OFF

`src/ensemble.jl`'s `member_remake` re-sizes every extensive state when an ensemble member's
body mass changes — and **`bf.Na_store` was missing from that list from the day this record
was written**, because `structural_simplify` eliminated it while the branch was off, so
nothing could fail. A 90 kg member started with a 70 kg store, which equilibrated over
`tau_store` and left a **mass-dependent residue in arterial pressure**: MAP invariance went
to 2.7e-4 against a 1e-4 bar and the body-size testset caught it on the first run. The list's
own comment said adding a state *"silently creates an obligation here … so the tenth one is
looked for rather than found."* **It was found.** A disabled branch cannot be tested, and
this is what was hiding in it.
