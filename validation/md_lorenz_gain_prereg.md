# Pre-registration — sourcing the macula densa renin gain from Lorenz 1990

**Written 2026-09-20, before any equation is written.** Verify with

    git log --diff-filter=A -- validation/md_lorenz_gain_prereg.md

This pass exists because **two pre-registrations, written on different days, both predicted
it in advance and both named the condition that would make it possible.**

---

## 0. THE PREDICTION WAS RECORDED, AND ITS CONDITION IS NOW MET

`macula_densa_lorenz_prereg.md` §3 gave exactly two reasons Lorenz could not be consumed:

> **THE CONCENTRATION CANNOT BE COMPUTED.** Macula densa NaCl concentration is distal sodium
> delivery divided by distal flow. This model lumps water reabsorption into one term and has
> no distal flow.

> **THE THRESHOLD CANNOT BE PLACED ON THIS MODEL'S AXIS.** Where the reference sits relative
> to 80 mM is unknowable without a macula densa concentration.

**ADR 0025 built `md_conc` and both reasons are gone.** `md_conc_ref` = **53.9 mmol/L**,
which is **below Lorenz's 80 mM threshold, on the steep limb** — and Lorenz himself states
the full response occurs *"within the concentration range normally occurring at the macula
densa."* **The threshold's position relative to the operating point is no longer assumed; it
is computed, and it agrees with the source.** That is decision rule **M2** of that
pre-registration, which was live and is now taken.

`RN.MD.RENIN_GAIN`'s own note states the consequence:

> Build a macula densa NaCl concentration … and this row becomes sourceable from Lorenz,
> retiring the second of this ledger's two calibrated rows.

And `tal_saturable_prereg.md` Amendment 1 §4 **G3**, written before TGF was built, named this
same row as the thing that would be wrong if sourced TGF did not stabilise the loop:

> most likely `g_md`, which was calibrated against a *delivery* signal and is now multiplying
> a *concentration* one — failure mode #22, and a separate pass.

**SOURCED TGF DID NOT STABILISE THE LOOP.** At Briggs's own elasticity the model still has no
steady state, the `gfr_tgf` guard binds at both ends, and **`e_tgf` was not raised.** G3 fired
as written. This is that separate pass.

---

## 1. WHAT IS WRONG WITH THE ROW, STATED WITHOUT REFERENCE TO WHETHER IT HELPS

- **Its name is `Renin drive per fractional fall in distal sodium DELIVERY`** and since
  ADR 0025 it multiplies a **concentration** signal. **Failure mode #11** — a name carrying a
  convention its value contradicts.
- **Its calibration target has been withdrawn.** It was solved against van den Bosch's
  5.74/2.10. ADR 0025 retired that agreement and the `runtests.jl` pin on it. **A calibrated
  row whose estimation set no longer applies is not a parameter, it is a leftover.**
- **It absorbs mechanisms that now exist.** Its note lists what it stands in for; the renal
  sympathetic arm (ADR 0024) and tubuloglomerular feedback (ADR 0026) have both since been
  built, and the note predicted each would lower it.

**None of these depend on the instability, and all three would be reasons to do this pass if
the model were perfectly stable.**

---

## 2. WHAT LORENZ MEASURED, AND IT IS A FOLD CHANGE

**Lorenz JN, Weihprecht H, Schnermann J, Skøtt O, Briggs JP.** Am J Physiol
1990;259(1 Pt 2):F186–F193. **PMID 2197878. FULL TEXT READ**, supplied by the owner;
extracted in `macula_densa_lorenz_prereg.md` §1 **before this pass existed**.

Isolated perfused rabbit juxtaglomerular apparatus — the preparation removes intravascular
pressure and renal nerve activity, so **what remains is this arm alone.**

| series 2 | perfusate Na+ | renin secretion |
|---|---|---|
| A, n = 8 | 141 | 2.2 nGU/min |
| A | 80 | 1.9 — **no effect** |
| B, n = 8 | 80 | 3.2 nGU/min |
| B | 24 | 16.6, **P < 0.007** |

**Two numbers come out of this and both are his:**

- **A THRESHOLD AT 80 mmol/L.** Flat from 141 to 80, steep below. Reported, not fitted.
- **A LOG-LINEAR SLOPE BELOW IT.** `ln(16.6/3.2) / (80 - 24)` = **0.029 per mmol/L**.
  **TWO SIGNIFICANT FIGURES AND NOT THREE**: 3.2 carries two, so the ratio is 5.2 and the
  slope cannot be known better than 0.029. Directive 1.13.

**THE DISPERSION IS NOT CARRIED AND THE ROW SAYS SO.** `macula_densa_lorenz_prereg.md`
extracted group means and the significance test, not the SEMs. The row is entered with
`uncertainty_type = none` and a note recording that this is an **extraction gap, not a claim
of precision** — the honest form of directive 1.13 when the spread was not taken down.

---

## 3. THE FORM

    md_drive ~ exp(k_md * (md_c_ref - min(md_conc, md_c_thr))) - 1.0
    pra_target = max(1 + g_renin * pressure_term, 0) * (1 + md_drive)

- **`md_drive` = 0 at rest EXACTLY**, because `md_conc` = `md_c_ref` there. Every existing
  statement that this arm is silent at the operating point survives unchanged.
- **The threshold rectifies where Lorenz rectifies**, at 80 mmol/L, on the axis he measured
  it on. `md_c_ref` = 53.9 < 80, so the operating point is on the steep limb — **his finding,
  reproduced, not imposed.**
- **MULTIPLICATIVE, AND THAT IS WHAT THE PREPARATION LICENSES.** Lorenz measured this arm
  with pressure and nerves physically removed, so his 5.2-fold is the arm's **own** factor.
  Adding it instead would make its effect depend on the size of the pressure term, which is
  the thing his preparation was built to exclude.
- **`RN.MD.RENIN_GAIN` IS DELETED**, not set to something. The ledger's calibrated-row count
  falls, which is the direction its own notes have been asking for since 2026-09-05.

---

## 4. WHAT MAY NOT MOVE

- **`k_md` = 0.029 and `md_c_thr` = 80 are Lorenz's.** Neither may be moved to buy stability,
  to recover van den Bosch, or to make Jensen pass.
- **`e_tgf` = 0.8, `Km` = 140, `tau_tal` = 1.0, `k_prox` = 0.29, `f_tal`, `f_prox`,
  `md_conc_ref`, `G_pn`, the sympathetic arm, the volume gain.**
- **No band, pin or tolerance widened.**
- **van den Bosch may NOT be re-adopted as an estimation set.** It was retired; if the model
  now reproduces it, that is a test passing, and if it does not, that is a test failing.

---

## 5. THE DECISION RULE

- **L1 — stable, operating point holds, `md_conc` chronically salt-independent, Jensen
  inside 60–250.** Adopt.
- **L2 — stable, Jensen still outside.** ADR 0025's falsifier has fired and saturable
  transport was not what was missing. **Report it as the result of the whole sequence.**
- **L3 — still unstable.** Then the diagnosis in Amendment 1 was wrong. Report it; do not
  reach for a fourth gain.
- **L4 — the operating point moves.** `md_drive` is 0 at rest by construction, so it cannot;
  if it does, the wiring is wrong.

**AND A SEPARATE, HONEST QUESTION THAT MUST BE ANSWERED WHATEVER HAPPENS:** with Lorenz's
gain in place, **is TGF still load-bearing for stability?** The loop gain is to be reported
**with and without TGF**. If the model is stable without it, **ADR 0026 must say so** — TGF
stays because it is real and sourced, not because it rescued anything.

---

## 6. THE FALSIFIABLE TESTS

1. **A steady state exists** — MAP, `md_conc`, `pra` ranges over the last 100 of 120 days.
2. **Operating point unchanged** — MAP, `Na_excr`, urine volume, plasma sodium.
3. **`md_conc` at 38, 205, 230 mEq/day** — chronically salt-independent (Vallon).
4. **Jensen's acute FE_Na rise against 60–250**, reported whichever way.
5. **The chronic renin ratio against van den Bosch's 2.73 — NOW A TEST**, reported whichever
   way, and reported as a test rather than as a fit for the first time.
6. **Whether the `gfr_tgf` guard binds**, as a number.
7. **Loop gain with and without TGF**, measured.
8. **Chronic salt sensitivity, the Lobo endpoints, the ordering ratio** — none fitted.

---

## 7. WHAT WOULD MAKE THIS PASS A FAILURE

**Choosing `k_md` to stabilise the model.** It is arithmetic on Lorenz's four numbers, and
§2 fixes it to two significant figures before anything is run.

**Quietly keeping `g_md` alongside.** Two gains on one arm is how a sourced number gets a
fitted multiplier.

**Reporting the renin ratio as agreement.** It has been an estimation set since 2026-09-05
and its retirement is what makes it a test. If it now passes, that is the first time it has
ever meant anything — and if it fails, that is reported in the same sentence it would have
been celebrated in.

**Letting the operating point move by a hair and calling it rounding.** `md_drive` is zero at
rest exactly; anything else is a wiring error.
