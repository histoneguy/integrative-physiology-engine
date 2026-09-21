# ADR 0027: The macula densa renin gain comes from Lorenz 1990, not from a fit

**Status:** Accepted
**Date:** 2026-09-20
**Evidence tier:** **E2** — direct measurement in the isolated perfused rabbit
juxtaglomerular apparatus, the preparation that removes the model's other two renin arms.

Pre-registered in `validation/md_lorenz_gain_prereg.md`. **Two earlier pre-registrations
predicted this pass and named the condition that would make it possible.**

## Context

`RN.MD.RENIN_GAIN` = 4.99 was one of two `calibrated` rows — solved by bisection against van
den Bosch's 5.74/2.10 salt–renin ratio. Three things were wrong with it, **none of which
depend on the instability that occasioned this pass**:

- **Its name was `Renin drive per fractional fall in distal sodium DELIVERY`** and since
  ADR 0025 it multiplied a **concentration** signal. **Failure mode #11.**
- **Its estimation set had been withdrawn.** ADR 0025 retired van den Bosch and the
  `runtests.jl` pin on it. A calibrated row whose target no longer applies is a leftover.
- **It absorbed mechanisms that now exist** — the renal sympathetic arm (ADR 0024) and
  tubuloglomerular feedback (ADR 0026), each of which its own note predicted would lower it.

`macula_densa_lorenz_prereg.md` §3 gave exactly two reasons Lorenz could not be consumed:
the model had no macula densa concentration, and therefore no axis on which to place his
threshold. **ADR 0025 built the concentration and both reasons went away.**

## Evidence

**Lorenz JN, Weihprecht H, Schnermann J, Skøtt O, Briggs JP.** Am J Physiol
1990;259(1 Pt 2):F186–F193. **PMID 2197878. FULL TEXT READ**, supplied by the owner and
extracted in `macula_densa_lorenz_prereg.md` §1 **before this pass existed**.

Isolated perfused rabbit juxtaglomerular apparatus — in the paper's words, studied *"in the
absence of the confounding influences of intravascular pressure and renal nerve activity."*
**Both of this model's other renin arms are physically removed, so what it measures is this
arm alone.**

| series 2 | perfusate Na⁺ | renin secretion |
|---|---|---|
| A, n = 8 | 141 | 2.2 nGU/min |
| A | 80 | 1.9 — **no effect** |
| B, n = 8 | 80 | 3.2 nGU/min |
| B | 24 | 16.6, **P < 0.007** |

## Decision

    md_drive   ~ exp(k_md * (md_c_ref - min(md_conc, md_c_thr))) - 1
    pra_target = max(1 + g_renin*pressure_term, 0) * (1 + md_drive)

- **`md_c_thr` = 80 mmol/L**, reported. Flat above, steep below.
- **`k_md` = 0.029 per mmol/L** = `ln(16.6/3.2)/(80 − 24)`. **Two significant figures and
  not three**: 3.2 carries two, so the ratio is 5.2. Directive 1.13.
- **MULTIPLICATIVE, because that is what the preparation licenses.** Lorenz measured this
  arm with pressure and nerves removed, so his 5.2-fold belongs to the arm. Adding it would
  make its effect depend on the size of the pressure term — the very thing his preparation
  excludes.
- **`RN.MD.RENIN_GAIN` is DELETED, not re-solved.**

**`md_drive` = 0 at rest exactly**, so every prior statement that this arm is silent at the
operating point survives unchanged.

**AND THE THRESHOLD LANDS WHERE LORENZ PUT IT WITHOUT BEING PUT THERE.** `md_conc_ref` =
53.9 mmol/L, derived from Shirley's proximal fraction and the macula densa fraction, both
entered before this threshold was consumed. Lorenz reports the full response occurring
*"within the concentration range normally occurring at the macula densa."* **Two independent
derivations agree about which side of 80 the kidney sits on. Nothing was fitted to obtain
that.**

## Consequences

**THE MODEL HAS A STEADY STATE AGAIN.** This — not tubuloglomerular feedback — is what fixed
ADR 0026's instability, and `tal_saturable_prereg.md` Amendment 1 §4 **G3 named it in
advance**. The positive loop gain falls from 1.6 to below one because the sourced elasticity
of renin to macula densa concentration is **1.6**, where the retired fit behaved like **5.0**
on the same signal.

**A CALIBRATED ROW IS RETIRED AND THE COUNT FALLS**, which its own notes have been asking
for since 2026-09-05.

**van den Bosch's 2.73 IS NOW A TEST, AND IT FAILS.** The chronic renin ratio is **1.343**.
It has been an estimation set since 2026-09-05 and could never be quoted as agreement; with
the gain sourced from an independent preparation it is a genuine endpoint for the first time
— **and it is reported in the same sentence it would have been celebrated in.** The reason
it fails is ADR 0025's: `md_conc` is chronically salt-independent (Vallon), so this arm
should not and does not carry dietary salt.

**What did not change:** resting MAP 87.0, `Na_excr` 205.0, urine 1.70 L/day, GFR 153,
plasma sodium 140.0. Chronic salt sensitivity **1.97**. Every Lobo endpoint passes. Jensen
still fails at 49% — ADR 0026's result, untouched by this one.

## What this disqualifies as evidence

**The renin ratio may never again be described as reproduced.** It is failed, and the
failure is informative because the arm is now sourced.

**`k_md` and `md_c_thr` may not be moved** — to stabilise the model, to recover van den
Bosch, or to make Jensen pass.

**Rabbit juxtaglomerular apparatus applied to a human kidney is the weakest link on both
rows**, and is taken because the human experiment — perfusing one macula densa at a
controlled NaCl concentration with renal perfusion pressure and nerve traffic held fixed —
cannot ethically be performed.

**The dispersion is not carried and that is an extraction gap, not a precision claim.** The
group means and P-value were taken down; the SEMs were not. Retiring the gap needs only
series 2's SEMs from a paper already in hand.
