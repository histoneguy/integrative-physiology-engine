# Pre-registration — tubuloglomerular feedback

**Written 2026-09-20, before any equation is written.** Verify with

    git log --diff-filter=A -- validation/tgf_prereg.md

Required by `tal_saturable_prereg.md` Amendment 1, which measured a loop gain of 1.6 and
named this as the missing mechanism **before** looking for a source for it.

---

## 0. WHY

Saturable TAL transport made `md_conc` respond to flow, relative gain **1.13**. That closed
a positive feedback loop — concentration down, renin up, proximal reabsorption up, TAL flow
down, concentration down further — and **the model has no steady state**. Cutting either end
of the loop restores one exactly.

**The macula densa has two effectors and this model has only the slow one.** Renin release
is built (ADR 0021). Afferent arteriolar constriction is not.

---

## 1. THE SOURCE

**Briggs JP, Schubert G, Schnermann J.** *Quantitative characterization of the
tubuloglomerular feedback response: effect of growth.* Am J Physiol 1984;247(5 Pt
2):F808-15. **PMID 6496746**, doi 10.1152/ajprenal.1984.247.5.F808. **ABSTRACT READ IN
FULL**, on PubMed, 2026-09-20.

Male Sprague-Dawley rats at 100, 220 and 350 g; standard micropuncture, SNGFR measured at
multiple loop-of-Henle perfusion rates in the same nephron. The relation is an inverse
sigmoid,

    dSNGFR = a / (1 + exp(k*(b - VLP)))

| group | `dSNGFR_max` (nl/min) | `V-half` (nl/min) | slope at `V-half` |
|---|---|---|---|
| 100 g | 7.9 +/- 1.16 | 10.3 +/- 0.8 | 0.9 +/- 0.19 |
| 220 g | 18.9 +/- 0.90 | 15.4 +/- 0.83 | 1.7 +/- 0.16 |
| 350 g | 25.2 +/- 2.73 | 22.3 +/- 1.22 | 3.2 +/- 0.70 |

**TWO STATEMENTS IN THIS PAPER ARE WHY IT IS THE RIGHT ONE, AND BOTH ARE THE AUTHORS', NOT
MINE:**

1. **Independent of rat size, a 10% increase in loop flow at the midpoint produced a 5-10%
   decrease in SNGFR.** Every absolute quantity in the table triples across the weight
   range. **The dimensionless elasticity does not.** The paper varied body size 3.5-fold and
   reported the quantity that survived it — which is exactly the quantity a human
   whole-body model can take, and the cross-species step is therefore the weakest link on
   this row rather than a hidden one.
2. **Free-flow SNGFR and loop flow lie in the most sensitive range of the curve.** So a
   linear term about the operating point is what the source licenses, and the operating
   point belongs at the midpoint — which it is, by construction.

**THE VALUE ENTERED IS 0.8, RANGE 0.5-1.0.** The bounds are the paper's own and are given to
one figure. **A midpoint quoted as 0.75 would claim a second figure the range does not
support** — directive 1.13.

---

## 2. THE FORM, AND WHY IT ACTS ON CONCENTRATION AND NOT ON FLOW

Briggs's independent variable is loop **flow**. The macula densa senses **concentration** —
Lorenz 1990 (PMID 2197878), already in this repo, raised delivery 51% and got a 3.2-fold
renin rise driven by concentration.

**THE DIFFERENCE IS NOT COSMETIC AND IT DECIDES THE CHRONIC BEHAVIOUR.** After `tal_cap`
has adapted, flow is high and `md_conc` is back at reference. A TGF term written on flow
would stay switched on forever and clamp GFR at every salt intake. **Written on
concentration it switches itself off, which is what the sensor actually does.**

So the elasticity is carried across by this model's **own** transport integral,

    tgf_rel_gain = dC/C per dphi/phi at the operating point
                 = md_vt_ref / ((Km/md_c_ref + 1) * md_c_ref) = 1.13

and the term is

    gfr_tgf ~ 1 - (e_tgf / tgf_rel_gain) * (md_conc / md_c_ref - 1)
    GFR     ~ ... * gfr_vol_mod * gfr_tgf

**`tgf_rel_gain` IS COMPUTED IN THE COMPONENT, NOT STORED.** It is arithmetic on rows the
model already has, it carries no digits it did not earn, and it needs no closure check.

**`gfr_tgf` = 1 EXACTLY AT REST**, because `md_conc` = `md_c_ref` there. **The operating
point cannot move by construction.**

### 2.1 The saturation bound is a GUARD, and it is declared as one

Briggs's sigmoid saturates; a linear term does not. `gfr_tgf` is clamped to **0.6-1.4**.
**THIS IS A NUMERICAL GUARD AND NOT A PHYSIOLOGICAL CLAIM.** The maximal response is in the
table but free-flow SNGFR is not in the abstract, so the fraction it corresponds to cannot
be computed from what has been read.

**Section 5 test 6 therefore reports whether the clamp ever binds.** If it does, the bound
is load-bearing, this pass may not claim the linear form, and the full text is needed.

---

## 3. WHAT MAY NOT MOVE

- **`g_md`, `k_prox`, `tau_tal`** — Amendment 1 forbade each by name, and the instability is
  precisely the pressure that would tempt all three.
- **`Km`, the transport integral, `f_tal`, `f_prox`, `md_conc_ref`.**
- **`e_tgf` may not be moved off 0.8 to buy stability.** If 0.8 does not stabilise the loop,
  **that is the result** — section 4.
- **The operating point, the existing pressure autoregulation, `G_pn`, the sympathetic arm.**
- **No band or tolerance widened.**

---

## 4. THE DECISION RULE

- **G1 — the loop is stable, the operating point holds, Jensen returns inside 60-250,
  `md_conc` stays chronically salt-independent.** Adopt.
- **G2 — stable, but Jensen does not return.** ADR 0025's falsifier has fired: saturable
  transport was not what was missing. Report it as the pass's result.
- **G3 — still unstable at `e_tgf` = 0.8.** Report. **Do NOT raise `e_tgf`.** The honest
  reading would be that some other gain in the renal arm is wrong, most likely `g_md`, which
  was calibrated against a *delivery* signal and is now multiplying a *concentration* one —
  failure mode #22, and a separate pass.
- **G4 — the operating point moves.** The term is 1 at rest by construction, so it cannot;
  if it does, the wiring is wrong.

---

## 5. THE FALSIFIABLE TESTS

1. **A steady state exists**: MAP, `md_conc` and `pra` flat over the last 100 days of a
   120-day run, reported as ranges.
2. **Operating point unchanged** — MAP, `Na_excr`, urine volume, plasma sodium.
3. **`md_conc` at 38, 205, 230 mEq/day**, still chronically salt-independent (Vallon).
4. **Jensen's acute FE_Na rise against its 60-250 band**, reported whichever way.
5. **Chronic renin ratio, chronic salt sensitivity, the Lobo endpoints, the ordering
   ratio** — reported, none fitted.
6. **Whether the `gfr_tgf` clamp ever binds**, reported as a number.

---

## 6. WHAT WOULD MAKE THIS PASS A FAILURE

**Choosing `e_tgf` to make the model stable.** It is Briggs's, the range is his, and the
midpoint is arithmetic on his bounds.

**Letting `gfr_tgf` differ from 1 at rest.** Then TGF is not a feedback, it is a
recalibration of GFR wearing the name of one.

**Writing TGF on flow because it is easier.** Section 2 gives the reason it must be
concentration, and the reason is about the chronic behaviour, not about tidiness.

**Reporting G1 when the clamp is doing the stabilising.** Test 6 exists so that cannot pass
unnoticed.
