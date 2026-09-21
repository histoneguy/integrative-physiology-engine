# ADR 0025: The tubule is split into flux-carrying segments

**Status:** Accepted
**Date:** 2026-09-20
**Evidence tier:** **E2** for the macula densa concentration being the renin stimulus and for
its salt-independence; **E2** for end-proximal delivery responding to salt; **E3** for
constant fractional TAL reabsorption, which is default ON and whose falsifier is named in
Consequences.

Pre-registered in `validation/tubule_segments_prereg.md`, which **predicted the severe
consequence before the structure was built**.

## Context

**Four renal passes found the right primary source and could not use it**, all for one
reason:

| pass | source | why it did not land |
|---|---|---|
| `fr_angii` | Hall 1984 | needed an AngII dose-to-concentration anchor |
| saturating form | Hall 1977 | shape irrelevant; term too small a share |
| macula densa | Lorenz 1990 | needs macula densa **concentration**; model had delivery |
| proximal | Folkerd 1995 | landed and **changed nothing** — `Na_prox_out` was read by nothing |

**The tubule was one lumped reabsorption term and every primary renal source is segmental.**

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| Renin responds to macula densa NaCl **concentration**, not delivery | **E2** | Lorenz 1990, PMID 2197878 — delivery rose 51% and renin rose 3.2× anyway | rabbit, isolated perfused JGA |
| The macula densa signal is **salt-independent** | **E2** | Vallon 2002, PMID 12089382 | rat, micropuncture |
| End-proximal delivery **rises** with dietary salt | **E2** | Folkerd 1995 PMID 7733329; Chiolero 2000 PMID 11040249 | human |
| Lithium clearance measures **fluid** delivery from the proximal tubule | **E2** | Boer 1988, PMID 3138131, n = 103 | human |
| TAL reabsorbs a **constant fraction** of delivery | **E3** | none — see Consequences | — |

## Decision

    H2O_prox_out ~ GFR * f_prox_eff              lithium measures FLUID delivery
    Na_md        ~ Na_prox_out * (1 - f_tal)     a fraction of what the segment RECEIVES
    md_conc      ~ Na_md / H2O_prox_out          the Lorenz variable
    md_drive     ~ (md_conc_ref - md_conc) / md_conc_ref

**The change that matters is the denominator.** `f_md` was a fixed fraction of the
**filtered** load; `f_tal` is a fraction of what the segment **receives**. With a fixed
fraction of filtration, delivery and concentration cannot come apart — and coming apart is
what Lorenz measured.

**Both constants are DERIVED from rows already sourced**, introducing no new information:
`f_tal` = 1 − 0.10/0.26 = **0.615**, `md_conc_ref` = 140 × 0.385 = **53.9 mmol/L**.

**`f_tal` lumps TAL sodium reabsorption with descending-limb water reabsorption.** They
enter `md_conc` as a ratio and nothing in hand separates them.

## Consequences

**VALLON IS NOW EMERGENT RATHER THAN ASSUMED.** `md_conc` = `C_Na·(1 − f_tal)` — the
proximal delivery fraction **cancels** — so the macula densa concentration is
salt-independent by construction. Measured: **53.62 mmol/L at 38 mEq/day against 53.94 at
230**, a 0.6% change across a six-fold change in sodium excretion.

**AND 53.9 IS A FREE CONSISTENCY CHECK.** Lorenz states the normal macula densa range is
*"below 80 mM Na+"*. Shirley 2002 supplied the proximal fraction, the macula densa fraction
came from elsewhere, Lorenz supplied the bound — **nobody arranged this and nothing was
fitted to obtain it.**

**THE MODEL NO LONGER REPRODUCES van den Bosch's SALT–RENIN RATIO.** It fell from **2.733 to
1.433**, and this was **predicted in the pre-registration before the structure was built**.
§3.65 measured the macula densa arm supplying 1.41 of the 1.58 gap; with the arm's signal
now salt-independent it supplies almost none. **`RN.MD.RENIN_GAIN` was NOT re-solved** — a
larger gain on a constant signal buys nothing, and reaching for it would mean the structure
was built to preserve an answer. The `runtests.jl` pin on 5.74/2.10 tested a calibration
that no longer exists and was **retired**, replaced by a drift pin on the model's own value.

**AND `challenges.jl` IS NOW RED ON ONE ENDPOINT.** Jensen's acute FE_Na rise fell from
**94% to 43%**, outside its 60–250 band. **This is a genuine regression against a human
measurement and it is reported rather than absorbed.**

**ITS CAUSE IS THE E3 CLAIM, AND THAT IS THE FALSIFIER.** Constant fractional TAL
reabsorption makes `md_conc` rigidly proportional to plasma sodium **at every flow**. Real
thick ascending limb transport is **saturable**, so an acute flow surge is reabsorbed less
completely and the concentration **rises** — which is the acute signal the model has just
lost. Chronic salt-independence would survive, because over days delivery and reabsorption
scale together. **Building saturable TAL transport is the named next step**, and if it does
not restore the acute response the constant-fraction assumption is not what is wrong.

**What did NOT change:** resting MAP 87.0, `Na_excr` 205.0, urine 1.7 L/day; chronic salt
sensitivity 1.96; both Lobo endpoints, which improved to 628 mL and 476 mOsm/kg.

## What this lumping disqualifies as evidence

**van den Bosch's 2.73 is no longer reproduced and must not be quoted as agreement** in
either direction — it was an estimation set while `g_md` was calibrated against it, and it
is now simply failed.

**`f_tal` may not be tuned to restore Jensen.** It is derived from two sourced rows and the
missing mechanism is saturable transport, not a different constant.
