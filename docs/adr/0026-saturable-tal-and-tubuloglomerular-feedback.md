# ADR 0026: Saturable thick ascending limb transport, and tubuloglomerular feedback

**Status:** Accepted
**Date:** 2026-09-20
**Evidence tier:** **E2** for the flow dependence of thick ascending limb transport
(Layton 1997, a mathematical model, recorded as one); **E2** for tubuloglomerular feedback
and its dimensionless gain (Briggs 1984, rat micropuncture); **E3** for load-dependent
adaptation of transport capacity, default ON, falsifier named in Consequences.

Pre-registered in `validation/tal_saturable_prereg.md` (with **Amendment 1**, written after
running and before the fix) and `validation/tgf_prereg.md`.

## Context

ADR 0025 split the tubule and named its own falsifier: constant fractional TAL reabsorption
makes `md_conc` = `C_Na·(1 − f_tal)` — **rigidly proportional to plasma sodium at every
flow** — which gave Vallon's chronic salt-independence for free and cost Jensen's acute
response, 94% → 43%, outside its 60–250 band.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| TAL NaCl concentration depends only on transit time — i.e. on flow | **E2** | Layton 1997, PMID 9362340 | model (rabbit kinetics) |
| Michaelis constant for TAL chloride transport, 140 mM | **E2** | Layton 1997, Table 1 | model, `calibrated`, originating model named |
| A 10% rise in loop flow at the midpoint lowers SNGFR 5–10%, **independent of body size** | **E2** | Briggs 1984, PMID 6496746 | rat, micropuncture, 100/220/350 g |
| Free-flow values lie in the most sensitive range of the feedback curve | **E2** | Briggs 1984 | rat |
| The macula densa senses **concentration** | **E2** | Lorenz 1990, PMID 2197878 | rabbit, isolated perfused JGA |
| TAL transport capacity tracks sustained load | **E3** | none — see Consequences | — |

## Decision

**Saturable transport**, Layton's plug-flow Michaelis–Menten form integrated along the limb:

    Km*ln(C0/C) + (C0 - C) = Vmax * transit,   transit ~ 1/flow

**Nothing is fitted.** The right-hand side at rest is evaluated from `Km`, plasma sodium and
`md_conc_ref` **inside the component**, so the operating point is preserved by construction
and no derived constant is stored to carry digits it did not earn.

**THE IMPLICIT UNKNOWN IS `ln(C0/md_conc)`, NOT `md_conc`.** A concentration cannot be
negative but a Newton step on one can be, and the first build went past zero into the `log`
and returned `retcode Unstable`. Solving for the log-ratio makes positivity **structural**.

**Capacity adapts**, one slow state, `tau_tal` **assumed** and bracketed above Jensen's four
hours and below Vallon's one week. Without it `md_conc` would swing ~34% between salt arms
and contradict Vallon.

**Tubuloglomerular feedback**, a local slope about the operating point, **written on
concentration and not on flow**:

    gfr_tgf ~ clamp(1 - (e_tgf/tgf_rel_gain) * (md_conc/md_c_ref - 1), 0.6, 1.4)

The conversion from Briggs's flow elasticity uses the model's own transport integral. **The
choice of axis decides the chronic behaviour**: once capacity has adapted, flow is high and
concentration is back at reference, so a flow-driven term would stay switched on forever and
clamp GFR at every salt intake. `gfr_tgf` = **1.0 exactly at rest**.

## Consequences

**THE FIRST BUILD HAD NO STEADY STATE, AND THAT IS THE MOST INFORMATIVE RESULT IN THIS ADR.**
Saturable transport makes `md_conc` respond to flow with relative gain **1.13**, measured by
differentiating the transport integral. That closed a positive feedback loop which was inert
while the reabsorbed fraction was constant:

> concentration ↓ → renin ↑ → proximal reabsorption ↑ → TAL flow ↓ → transit ↑ → concentration ↓↓

Loop gain through the sourced constants was **1.13 × 4.99 × 0.29 = 1.6**, above one.
**Confirmed by cutting the loop at each end rather than by inspection:** zeroing `k_prox` or
`g_md` each gave MAP flat at 87.01 and `md_conc` between 53.8 and 54.2.

**Six gates passed on the unstable model.** Running it is what found this — directive 1.11.

**AND TUBULOGLOMERULAR FEEDBACK DID NOT FIX IT.** At Briggs's own elasticity the model still
had no steady state and the `gfr_tgf` guard bound at both ends. **`e_tgf` was not raised**;
`tal_saturable_prereg.md` Amendment 1 §4 **G3** had named the real culprit in advance — a
renin gain calibrated against a *delivery* signal, now multiplying a *concentration* one.
That is **ADR 0027**, and it is what made the model stable.

**SO TGF IS NOT LOAD-BEARING FOR STABILITY AND THIS ADR SAYS SO**, because `tgf_prereg.md`
§5 required the answer either way. Measured: with `e_tgf` = 0 the model is equally stable.
**TGF is here because it is real, measured and was missing, not because it rescued
anything.** Its guard spans 0.964–1.002 in normal operation and **never binds**.

**AN ALGEBRAIC UNKNOWN IS NOT AN INITIAL CONDITION, AND THREE HARNESSES DID NOT KNOW IT.**
Every unknown in this model was differential until this ADR. `salt_step`, `challenges.jl`
and the haemorrhage test all carried *every* unknown between phases, which over-determines
the initialisation. **`salt_step`'s third salt arm then did not integrate at all** — it
reported 103 mEq/day excreting 154 and a chronic salt sensitivity of **0.95 against a true
1.96 — with no error raised.** A silently failed solve was cycle-averaged and checked
against a human band. All three now carry differential states only, and **a failed retcode
is an error rather than a summary.**

**What the model does now:** stable; resting MAP 87.0, `Na_excr` 205.0, urine 1.70 L/day,
GFR 153, plasma sodium 140.0 — **unchanged**. Chronic salt sensitivity **1.97** (1.70–2.30).
`md_conc` **53.5 at 38 mEq/day against 53.96 at 230**, still Vallon. Every Lobo endpoint
passes.

**JENSEN DOES NOT RETURN: 43% → 49%, against 60–250.** ADR 0025's falsifier said that if
saturable transport did not restore the acute response, **the constant-fraction assumption
is not what was wrong.** It did not, and **that is this pass's result rather than a debt to
be worked off by tuning.** `tau_tal` was not shortened, `Km` was not adjusted, and Jensen
still failing is the evidence that neither was.

**The E3 claim and its falsifier:** load-dependent adaptation of TAL transport capacity is
assumed in form and in time constant. A measurement of how quickly NKCC2-mediated capacity
follows a step change in delivered load would retire it. If adaptation is much faster than a
day, Jensen's acute window would see a partly adapted limb and the response would be smaller
still; if much slower, `md_conc` would drift between salt arms and Vallon would break.

## What this disqualifies as evidence

**Layton's constants are a model's parameters, not measurements**, chosen in his Ref. 15 to
match experiments. The row says so and `extraction_method` is `calibrated` with the
originating model named.

**Briggs's elasticity is rat single-nephron applied to human whole-kidney GFR.** It is taken
because his own design tested size-invariance over a 3.5-fold weight range and found it —
not because rat and human were assumed alike. The row says that too.

**The `gfr_tgf` clamp may not be quoted as a saturation magnitude.** It is a numerical guard;
free-flow SNGFR is not in the abstract that was read, so the fraction Briggs's maximal
response corresponds to cannot be computed from it.
