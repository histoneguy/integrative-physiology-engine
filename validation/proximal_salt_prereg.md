# Pre-registration — proximal sodium delivery responds to dietary salt

**Written 2026-09-20, before the row is entered and the term written.** Verify with

    git log --diff-filter=A -- validation/proximal_salt_prereg.md

---

## 0. THE DEFECT

`RN.NA.PROXIMAL_DELIVERY` = **0.26** is a CONSTANT, sourced from Shirley 2002 at a single
salt state. `Na_prox_out ~ Na_filtered * f_prox * renal_mod` is the lithium-clearance
quantity, and Renal.jl's own comment says **"nothing reads it"** — an observable that cannot
be wrong.

**IN HUMANS IT MORE THAN DOUBLES WITH DIETARY SALT.**

**Folkerd E, Singer DR, Cappuccio FP, Markandu ND, Sampson B, MacGregor GA.** *Clearance of
endogenous lithium in humans: altered dietary salt intake and comparison with exogenous
lithium clearance.* Am J Physiol 1995;268(4 Pt 2):F718-22. **PMID 7733329.** Six normal
subjects, five days per diet:

| sodium intake | FE_Li |
|---|---|
| **31 ± 10 mmol/day** | **8.3 ± 2.9 %** |
| **357 ± 78 mmol/day** | **18.0 ± 5.1 %**, P < 0.05 |

**Chiolero A, Maillard M, Nussberger J, Brunner HR, Burnier M.** Hypertension
2000;36(4):631-7. **PMID 11040249.** Independent confirmation in **27 normotensive
subjects**: low → high sodium gave *"increases in glomerular filtration rate (P<0.05), renal
plasma flow (P<0.05), and fractional excretion of lithium (FE(Li), P<0.01)."*

## 0.1 AND IT IS CONSISTENT WITH VALLON, NOT AGAINST HIM

§3.65 recorded Vallon 2002: in normal rats *"dietary salt did not affect … the TGF
signal"* and they adapt *"downstream of the macula densa."* **Both hold together** if
proximal delivery rises with salt and the thick ascending limb absorbs the difference, so
the macula densa sees little change. **This pass must leave `md_drive` near-constant**, and
§5 tests it.

---

## 1. THE FORM AND THE DERIVATION, FIXED BEFORE ANYTHING IS WRITTEN

**Keyed to `pra`, not to intake.** Angiotensin II stimulates proximal reabsorption — that is
what Hall 1977 and Hall 1984 measured — so the mechanism is in the model already and keying
to the sodium intake parameter would be open-loop.

    f_prox_eff = f_prox * (1 + k_prox * (pra_ref - pra))        zero deviation at rest

    Folkerd exponent:  ln(18.0/8.3) / ln(357/31) = 0.317
    predicted FE_Li ratio across THIS model's arms, 38 -> 230:  (230/38)^0.317 = 1.77
    model pra 2.5795 -> 0.9437 about pra_ref 1.2956
    k_prox = 0.29        TWO SIGNIFICANT FIGURES, directive 1.13

Giving f_prox **0.163** at 38 mEq/day, **0.260** at the reference, **0.287** at 230.

**THE POWER LAW IS AN INTERPOLATION AND THE ROW MUST SAY SO.** Two points fix one exponent
and say nothing about curvature. A linear-in-intake reading of the same two points is
equally admissible and is not distinguishable by them.

---

## 2. WHAT MAY NOT MOVE

- **The operating point.** `f_prox_eff` equals `f_prox` exactly at `pra_ref`, so resting
  MAP, `Na_excr`, urine volume and `Na_prox_out` must be unchanged.
- **`md_drive` must stay near-constant** — §0.1. If it starts tracking salt, the term is
  wired into the macula densa path, which is wrong and which Vallon forbids.
- **No other parameter.** Not `RN.MD.RENIN_GAIN`, not `RN.NA.MACULA_DENSA_FRACTION`, not
  any gain, band, pin or tolerance.
- **`RN.NA.PROXIMAL_DELIVERY` keeps its value 0.26.** It becomes the value at the reference
  rather than at all salt intakes.

---

## 3. THE DECISION RULE

- **P1 — FE_Li ratio near 1.77, `md_drive` near-constant, operating point unchanged.**
  Adopt.
- **P2 — `md_drive` starts tracking salt.** The term is wired wrongly. Fix it; do not
  re-derive anything else.
- **P3 — the operating point moves.** Same.
- **P4 — any model output outside `Na_prox_out` changes.** Report it. `Na_prox_out` is
  read by nothing, so a change elsewhere means the wiring reached further than intended.

---

## 4. THE FALSIFIABLE TESTS

1. **FE_Li at 38 and 230 mEq/day reported**, and their ratio against the predicted 1.77.
2. **`md_drive` at both arms reported**, and shown still near-constant.
3. **Operating point unchanged**, by running.
4. **Chronic salt sensitivity, the renin ratio, Jensen and the ordering ratio reported**,
   and none of them fitted.
5. **The endogenous/exogenous lithium distinction is on the row.** Folkerd's own finding is
   that they differ — 16.4 ± 2.1 % against 27.9 ± 2.1 % — and the model's 0.26 reference is
   an EXOGENOUS-technique number (Shirley 2002) while the salt response is ENDOGENOUS. Only
   the RELATIVE response is transferred.

---

## 5. WHAT WOULD MAKE THIS PASS A FAILURE

**Transferring Folkerd's absolute FE_Li values.** They are endogenous-lithium numbers and
the model's reference is an exogenous one; the two differ by nearly two-fold in Folkerd's
own hands. **Only the ratio crosses.**

**Letting `md_drive` move with salt.** That would make the model contradict Vallon while
appearing to agree with Folkerd, which is worse than doing nothing.

**Re-deriving `RN.MD.RENIN_GAIN` because the segmental picture changed.** It is calibrated,
it is wrong for reasons §3.65 records, and it is not this pass's business.

**Presenting the power law as measured.** Two points, one exponent, no curvature.
