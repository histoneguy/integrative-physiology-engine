# ADR 0030: Osmotic thirst

**Status:** Accepted
**Date:** 2026-09-21
**Evidence tier:** **E1** that thirst is osmotically driven in humans; **E2** for the
threshold, pooled from a systematic review of 12 trials. The **gain is DERIVED**, not
measured, and the record says so throughout.

Pre-registered in `validation/thirst_prereg.md`. **Branch T2.**

## Context

ADR 0029 made glucose an osmole and then could not produce the thing hyperglycaemia is
famous for. `BF.H2O.INTAKE_NOMINAL` is a fixed 2.5 L/day, `assumed`, so urine volume was
pinned at intake minus losses — **1.70 L/day at every glucose the model could reach** — and
an osmotic load appeared as urine *concentration* instead.

**The defect was general and glucose only exposed it.** Every osmotic challenge this model
will run is one a person answers by drinking. `OPEN-QUESTIONS` B18.

## Evidence

**Hughes F, Mythen M, Montgomery H.** *The sensitivity of the human thirst response to
changes in plasma osmolality: a systematic review.* Perioper Med (Lond) 2018;7:1. **Open
access, read 2026-09-21.** 12 trials, **167 participants**.

| | |
|---|---|
| thirst threshold | **285.23 ± 1.29 mOsm/kg** (95% CI) |
| thirst slope | 0.54 ± 0.07 **cm of visual analogue scale** per mOsm/kg |
| vasopressin threshold | 284.3 ± 0.71 mOsm/kg |

**THIS ROW REPLACED A SINGLE-SOURCE ONE AND THE REPLACEMENT CHANGED THE MODEL.** It was
first entered as Thompson 1986 (PMID 3791867, n = 10) at **281**. `pooling.md` has been
binding since long before this session and ranks an existing pooled estimate first; the
owner's correction is why the review was sought. Pooling moved the threshold 281 → 285.23
and **shrank the derived gain's denominator from 6.00 to 1.77 mOsm/kg**, moving the gain by
a factor of 3.4. **A single-source row is not a smaller version of a pooled one; it can be a
different answer.** `OPEN-QUESTIONS` B21 records the two rows still carrying that debt.

**DIRECTIVE 1.12 SCORED ON A CLAIM, SETTLED BY 12 TRIALS RATHER THAN ONE.**
`thirst_prereg.md` §2 wrote down the teaching claim — thirst threshold *above* the
vasopressin threshold, so urine concentrates before thirst begins — **before searching.**
Hughes finds 285.23 ± 1.29 against 284.3 ± 0.71, overlapping intervals, both "in the middle
of the normal range". **The textbook ordering is not supported.**

## Decision

    thirst ~ thirst_on * k_thirst * (max(Osm_ecf - Osm_thr_t, 0) - sig_ref)
    D(V_ecf) ~ H2O_intake + thirst - H2O_excr_rate - ...

**THIRST ADDS TO INTAKE AND DOES NOT REPLACE IT**, because `H2O_intake` is a **protocol
input** that `challenges.jl` overrides for Lobo's infusion and for fluid deprivation. §1 of
the pre-registration found that constraint before any equation was written.

**THE GAIN IS AN IDENTITY — BRANCH T2, DECLARED IN ADVANCE.** Hughes's slope is in
**centimetres of visual analogue scale**, a perception scale with no conversion to litres,
and a search found no volumetric drinking slope in healthy adults. So the gain comes from
the steady-state water balance: `2.5 / (287 − 285.23)` = **1.41 L/day per mOsm/kg**.
**Baseline drinking IS the thirst response at baseline osmolality** rather than something
added to it.

**It uses the ledger constant, not the `H2O_intake` parameter**, or a deprived person's
thirst gain would shrink because water was withheld.

## Consequences

**ALL CHALLENGES PASS** and the suite is green. **Jensen crossed its band edge, 59.9 → 60.x,
and that is NOT a result** — the harness's own note records that band as *"TIGHTER than the
reported statistics can justify"*, and a 0.1-point move across an arbitrary line is
bookkeeping. **Thirst did not fix the acute natriuresis and must not be said to have.**

**THE OPERATING POINT HOLDS, WITH A 1.2 mL/DAY RESIDUAL THAT IS NOT A WIRING ERROR.** Thirst
is zero when osmolality is at its setpoint; the model rests at 287.0009 rather than 287.0000,
and the derived gain amplifies that 0.0009 offset into 1.2 mL/day. That is a statement about
the model's osmolality closure — **B19 again** — not about thirst.

**THE PREDICTION WORKS AND IS WEAK, AND THE REASON IS ARITHMETIC.** Urine rises 1.70 → 2.14
L/day as glucose reaches 19.4 mmol/L. Plasma osmolality barely moves — 287.00 → 287.31 —
because `Δosm = Δglucose·(1 − 2f)` and the model's sodium-per-glucose fall `f` is **0.49**,
within a hair of the 0.5 that makes Δosm exactly zero. **The gain was NOT raised to improve
this**; §7 named that as what would make the pass a failure.

**AND ADH IS NO LONGER NECESSARY FOR THE SALT RESPONSE — THE SUITE'S CLAIM INVERTED.** A
test asserted `on > off`: that ADH amplifies the salt-step pressure shift. It no longer
does, because without ADH the kidney cannot concentrate, osmolality moves further, thirst
fires harder, and the water is restored anyway. **Measured across the gain's own six-fold
interval** (`thirst_prereg.md` §5 test 7):

| `thirst_on` | ADH on | ADH off |
|---|---|---|
| 0.00 | 1.7711 | 1.6737 |
| 0.58 | 1.7824 | 1.7875 |
| 1.00 | 1.7842 | 1.7875 |
| 3.69 | 1.7865 | 1.7875 |

**The inversion is robust across the whole interval**, driven by the ADH-off branch rising
rather than the ADH-on branch moving. The test now asserts the **redundancy** — the two
defend osmolality by different routes — and the old directional claim is recorded as
something thirst removed.

## What this disqualifies as evidence

**The gain is not a measurement and may never be quoted as one.** It divides by a difference
of two numbers 1.77 mOsm/kg apart, so across the review's own CI it spans **0.82 to 5.21** —
a six-fold range. §8.3 predicted that amplification before the pooling was done.

**The row has no population SD.** Hughes reports a CI on the pooled mean. Treating it as a
standard error over 167 participants implies ≈8.5 mOsm/kg, but the review folds
between-study heterogeneity into that interval, so **8.5 is an upper bound, not a
measurement.** A population model needs the real spread; B21 records what it would take.

**The review violates two of this pass's declared admissibility criteria** — it includes
pathologies and ages to 78. Osmotic thirst blunts with age, so the pooled threshold is
biased **upward**, the healthy-young value is probably lower, and the deviation is
**conservative** for this model rather than flattering. Stated rather than the review
discarded.
