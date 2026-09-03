# ADR 0016: The salt-sensitivity gap has three claimants. They are sequenced, not competing, and the fitted constant is estimated last

**Status:** Accepted
**Date:** 2026-09-02
**Evidence tier:** n/a - methodological

> This record decides an **estimation order**, not a physiological structure. It makes no
> new claim about the body, changes no parameter, and enables no term. It exists because
> three records now claim the same discrepancy and the repo had no rule for what happens
> when they land in different orders.

## Context

The model gives **4.957 mmHg per 100 mmol/day** against a meta-analytic human
**1.70–2.30** (HANDOVER §3.3). Three records each remove part of that gap:

| record | what it moves | how it is identified |
|---|---|---|
| **ADR 0013** | `RN.PRESSURE_NATRIURESIS.SLOPE` 20 → 51 | **fitted** to the human salt-sensitivity data |
| **ADR 0015** | a non-escaping AngII tubular term | **mechanism**, sized by nothing yet |
| **`RN.GFR.VOLUME_SENSITIVITY`** | GFR rises with volume expansion | **measured**, and by a GFR and a volume — neither of which is a pressure |

HANDOVER §3.11 called the first two *competing explanations* and said whichever landed
second must be re-estimated against the other. §3.12 added a third. **Nobody had measured
what they do together**, and three published percentages were sitting there inviting
multiplication — which is exactly the move made and withdrawn on 2026-09-02 (§3.9).

## Evidence

**Every configuration below is a real solve of the real model**, not a composition.
`bench/explanation_stack.jl`, whose decision rule D1–D4 and human window were fixed in its
header and committed **before** the first run.

| configuration | mmHg/100 mmol | ΔV L/100 mmol | ratio | where |
|---|---|---|---|---|
| baseline | 4.957 | 0.803 | 6.173 | high |
| GFR limb alone | 4.201 – 4.555 | 0.681 – 0.738 | 6.173 | high |
| ADR 0015 alone | 3.889 | 0.630 | 6.172 | high |
| ADR 0013 alone (51) | 1.944 | 0.315 | 6.173 | **in** |
| **both mechanisms** | **3.409 – 3.634** | **0.552 – 0.589** | 6.172 | high |
| **all three** | **1.536 – 1.639** | 0.249 – 0.266 | 6.173 | **low** |
| **human** | **1.70 – 2.30** | **0.553 – 0.572** | **2.97 – 4.16** | |

**Branch D2**: the mechanisms alone sit above the window, and adding `G_pn` = 51 drops
below it. **The three over-explain the gap, which is precisely what the anti-double-count
rule was written to catch.**

### The corrected target, bisected on real solves

| GFR parameterisation | inverse-law guess | **bisected** | guess low by |
|---|---|---|---|
| per-litre | 29.6 – 40.1 | **32.3 – 45.6** | 8.1%, 12.0% |
| per-intake | 31.6 – 42.8 | **34.8 – 49.0** | 9.1%, 12.7% |

**The inverse law does not hold once the mechanisms are on**, and it is wrong by 8–13% in
the direction that matters. That is the whole justification for running rather than
composing, and it is why the bracket is bisected.

**`G_pn`'s corrected bracket is 32.3 – 49.0. ADR 0013 proposes 51.0, which is outside it.**
ADR 0013's own concordant pressure bracket was 43.5–58.8, so only **43.5 – 49.0** survives.

### The result that settles the ordering

**The mechanisms alone put the VOLUME response on the human value** — 0.552 against a
human 0.553 — while **ADR 0013 alone destroys it**, 0.315 against 0.553. That is §3.7's
verdict reproduced from a completely different direction.

**And it is not a success.** The ratio `dMAP/dV_ecf` is **6.17 in every configuration**,
against a human 2.97–4.16. The mechanisms get ΔV right by having ΔMAP too high by ~1.7×
*and* the ratio too high by ~1.8×, and the two errors cancel. Fixing ΔMAP with any `G_pn`
breaks ΔV again, which is what the last two rows of the table show.

**So no value of `G_pn` satisfies both limbs while the ratio is wrong.** `G_pn` and
`G_vr` are orthogonal (§3.7), and this is the fourth independent confirmation: the ratio
column does not move across nine configurations spanning three mechanisms.

## Decision

**1. The three claimants are sequenced, and the order is forced by what each can and
cannot fix.**

1. **`CV.VENOUS_RETURN.SENSITIVITY` first** (§4 item 2). The ratio is the only quantity
   **no other parameter can move**. Everything downstream is estimated against a wrong
   ratio until it lands.
2. **The mechanisms second.** ADR 0015's term implemented and its own falsifiable test
   run; the GFR limb enabled. Both are identified by something other than the
   discrepancy they explain.
3. **`G_pn` last, and jointly.** It is the only fitted constant among the three, so it
   is the only one that can absorb whatever the mechanisms leave. **Estimating it first
   guarantees it absorbs their share** — which is how it became a hypertensive value in
   the first place (§3.3).

**2. ADR 0013's proposed VALUE of 51.0 is stale and must not be entered as written.**
It was estimated with no mechanism present. The corrected bracket is 32.3–49.0.
**This does not accept, reject or re-tier ADR 0013** — that remains the owner's decision
and its own falsifiable test still blocks it (§3.7).

**3. Nothing is enabled and no parameter changes.** ADR 0013 stays Proposed, ADR 0015
stays Proposed and default OFF, `RN.GFR.VOLUME_SENSITIVITY` stays unconsumed.

## Consequences

- **`G_pn` = 51 will not be entered even if ADR 0013 is accepted.** Its value becomes an
  output of step 3, not an input.
- **ADR 0015 is necessary but nowhere near sufficient.** 21.5% of the gap at the sourced
  renin gain (§3.13), against the 50.7% its own motivating diagnostic showed at a gain
  that has since been sourced.
- **The volume limb is now the binding constraint, not the pressure limb.** The pressure
  limb can be fitted; the ratio cannot, and no sourced value for it exists in this repo.
- **This record expires when step 1 lands.** The whole table must be re-run against a
  sourced `G_vr`, and the corrected bracket will move.

## What this lumping disqualifies as evidence

**Two proxies stand in for terms that are not implemented, and neither is the thing it
represents.**

- **ADR 0015 is stood in for by disabling aldosterone escape** (`tau_esc` = 1e6 d). That
  is not a non-escaping AngII term: it removes a real physiological process, and it
  **moves the baseline** — MAP 86.98 → 88.1–88.4 in every row that uses it. **Every
  magnitude in the table above carries that confound.**
- **The GFR limb is stood in for by overriding `GFR0` per arm**, which imposes the
  response rather than deriving it from volume.

**What that forecloses.** These numbers may size an *ordering* and may not be quoted as
model predictions. **The brackets are provisional on both terms being implemented
properly**, and step 3 must re-derive them rather than reuse them.

## Falsifiable test

Not required for a methodological record, and one is given anyway because the ordering
makes a checkable claim.

**The claim: `G_pn` estimated first will be higher than `G_pn` estimated last.** When
steps 1 and 2 are complete and `G_pn` is re-estimated, **it must land below 51.0**. If it
lands at or above 51, the mechanisms are contributing nothing that `G_pn` was not already
absorbing, this ordering bought nothing, and ADR 0013 was right as written.

**A second, sharper one.** The ratio must move when `G_vr` is sourced. **If a sourced
`G_vr` leaves `dMAP/dV_ecf` near 6.17**, then the ratio error is not in that parameter,
step 1 is the wrong first step, and this ordering is wrong at its root.

## What is NOT decided

- **Whether ADR 0013 is accepted.** Owner's decision, unchanged, and separately blocked
  by its own volume test.
- **Whether ADR 0015's term is the right mechanism**, or whether the efferent arteriole
  should be explicit. Its own record holds both questions.
- **Any magnitude.** The 32.3–49.0 bracket is an ordering artefact of two proxies, not a
  proposal.
- **Whether `G_pn` should be a distribution rather than a point value.** ADR 0013 calls
  that the strongest case in the repo for a posterior; it is untouched here.
