# Pre-registration — the saturating form of `fr_angii`

**Written 2026-09-19, before the form is changed.** Verify with

    git log --diff-filter=A -- validation/angii_saturating_prereg.md

**This pass tests a prediction that is already on the record**, written into
`docs/adr/0015-angii-tubular-natriuresis.md` and onto `RAAS.ANGII.TUBULAR_GAIN` before it
was tried.

---

## 0. THE PREDICTION BEING TESTED, QUOTED FROM WHERE IT WAS WRITTEN

> *"A saturating form has a LARGER LOCAL SLOPE AT REST than a straight line fitted across
> `pra` 1.296 to 2.58, because the line averages over a range the curve flattens across. So
> replacing the linear term with a saturating one SHOULD RAISE the amplification above
> 1.2×. If it does not, the form is not what is wrong."*

---

## 1. THE FORM, DERIVED AND NOT FITTED

Two measured points, both from Hall's own laboratory, neither from any quantity this model
is judged by:

    f(1.2956) = 0.00510     Hall 1977, TOTAL AngII tubular reabsorption at normal sodium
                            (FE_Na 1.23 -> 1.74 %, GFR and MAP unchanged)
    f(2.5795) = 0.00654     + Hall 1984's MARGINAL 0.00144 at sodium-deprivation AngII
    f(0)      = 0           no angiotensin II, no AngII-dependent reabsorption

Michaelis-Menten `f(p) = Vmax * p / (Km + p)` through them gives **Km = 1.0**,
**Vmax = 0.0091** — **two significant figures**, because the inputs carry two. The local
slope at `pra_ref` is **0.00173** per unit `pra`, against the linear row's 0.0011:
**1.58× steeper locally.**

**The model's term stays a DEVIATION**, because the baseline fractional reabsorption already
contains angiotensin II's resting contribution:

    fr_angii = f(pra) - f(pra_ref)          still identically zero at the operating point

**WHY MICHAELIS-MENTEN AND NOT SOME OTHER SATURATING CURVE.** Two points and an origin
determine a two-parameter saturating family and nothing more. Michaelis-Menten is the
conventional choice for a receptor-mediated transport effect and it is the one this
repository can defend as a **convention, not a measurement** — the row must say so.
**Any saturating form through the same two points has a similar local slope**, which is what
the prediction turns on, so the test is not sensitive to this choice.

---

## 2. THE TENSION I EXPECT, DECLARED BEFORE RUNNING

**A stronger term improves the amplification AND pushes the chronic band further out, because
they are the same effect measured two ways.**

- Switching the term on **lowers** salt sensitivity, because angiotensin II falling on high
  salt substitutes for a pressure rise. A **stronger** term substitutes more. At the linear
  gain the sensitivity was **1.6**, already below the 1.70 floor.
- Clamping the term removes that substitution, so a **stronger** term gives a **bigger**
  amplification.

**So I expect amplification to rise toward 2× and chronic salt sensitivity to fall further
below 1.70.** If both happen, **ADR 0015's falsifiable test and the chronic band are in
direct conflict for this term and cannot both be satisfied** — and that is a finding about
the model, not a reason to move either.

**IT IS DECLARED HERE SO THAT ARRIVING AT IT READS AS THE RULE WORKING RATHER THAN AS A
CONVENIENT DISCOVERY.**

---

## 3. WHAT MAY NOT MOVE

- **No other parameter.** Not `RN.PRESSURE_NATRIURESIS.SLOPE`, not
  `CV.VOLUME.NATRIURETIC_GAIN`, not `RN.MD.RENIN_GAIN`, not `RAAS.RENIN.PRESSURE_GAIN`.
- **No band, pin or tolerance.** Not 1.70–2.30, not ADR 0015's ≥ 2×.
- **The operating point.** `fr_angii` is zero at `pra_ref` by construction; resting MAP,
  `Na_excr`, urine volume must be unchanged with the term on **and** off.
- **`Vmax` and `Km` may not be tuned to either criterion.** They come from two measured
  points and the origin. **If the form fails, it fails.**

## 3.1 AND THE LINEAR ROW IS REMOVED, NOT LEFT DANGLING

`RAAS.ANGII.TUBULAR_GAIN` is superseded by this form. **It is deleted from the ledger rather
than left unread**, because `check_relations.py`'s unread-rows gate would fail it and
because a superseded row sitting beside its replacement is exactly the two-copies-of-a-fact
failure this repository is organised against. **Its provenance — the whole Hall 1984 and
Hall 1977 derivation — is carried forward onto `RAAS.ANGII.TUBULAR_VMAX` verbatim**, and the
deletion is recorded there.

---

## 4. THE DECISION RULE

- **S1 — amplification rises above 1.2× AND chronic salt sensitivity stays inside
  1.70–2.30.** The prediction holds and the term is viable. Adopt; consider switching on in
  a separate pass.
- **S2 — amplification rises but the chronic band is left.** **The declared tension in §2.**
  Report both numbers, keep the saturating form as the better-sourced shape, and **leave the
  term OFF.** Change nothing else.
- **S3 — amplification does NOT rise above 1.2×.** **The prediction is refuted and the form
  is not what is wrong.** Report it; ADR 0015's own *"necessary and nowhere near
  sufficient"* becomes the standing answer.
- **S4 — the operating point moves.** The deviation construction is written wrongly. Fix it.

---

## 5. THE FALSIFIABLE TESTS

1. **Amplification reported before and after**, against the 1.2× the linear form gave and
   the ≥ 2× ADR 0015 requires.
2. **Chronic salt sensitivity reported with the term on and off.**
3. **Operating point unchanged**, demonstrated by running, with the term on and off.
4. **`Vmax` and `Km` reproduce Hall's two points**, demonstrated arithmetically on the row.
5. **Two significant figures on both**, and the Michaelis-Menten choice labelled a
   **convention**.
6. **The linear row's deletion is recorded** and its provenance carried forward.

---

## 6. WHAT WOULD MAKE THIS PASS A FAILURE

**Tuning `Vmax` or `Km`.** They are determined by two measured points and the origin. Moving
either to satisfy a criterion is fitting to the test.

**Reporting S1 when the truth is S2.** The chronic band is the easier number to leave out of
a summary, and §2 exists so that omission is visible.

**Treating the declared tension as a reason to widen 1.70–2.30 or lower ADR 0015's 2×.**
Both are targets. A term that cannot satisfy both is the result.

**Quietly keeping the linear row around** so that nothing has to be explained.
