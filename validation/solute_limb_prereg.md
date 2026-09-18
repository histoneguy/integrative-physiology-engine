# Pre-registration — the non-sodium solute limb's response to sodium

**Written 2026-09-17, before the row is entered and before the term is written.** Verify
the ordering with

    git log --diff-filter=A -- validation/solute_limb_prereg.md
    git log --diff-filter=A -- validation/solute_limb_extract.py

Short by design: **the extraction is already done and the defect is already measured.**
This document fixes what may move and what may not, because the term touches
`RN.URINE.SOLUTE_LOAD`, which the ledger itself calls load-bearing.

---

## 0. THE DEFECT, ALREADY QUANTIFIED IN THE LEDGER

`RN.URINE.SOLUTE_NONNA`'s own note, written when Kitada was read:

> *"In the source the non-sodium remainder FALLS from 7.08 to 6.58 mOsm/kg/day as salt goes
> 6 → 12 g/day, because urine urea concentration falls 13.9 percent … So the true slope of
> total osmolar excretion against excreted sodium is about 1.5 mOsm/mEq, where this model
> uses 2.0 and holds the rest fixed. **ACROSS ITS OWN SALT ARMS THE MODEL THEREFORE
> OVER-RESPONDS ON THE SOLUTE LIMB BY ROUGHLY 30 PERCENT**: 204 mOsm/day of swing from 205
> to 103 mEq/day where the data imply about 157."*

**It was not built** because *"the dependence would need a urea-recycling or glucocorticoid
mechanism with no sourced form and this pass pre-registered none."*

**THIS PASS DOES NOT BUILD THAT MECHANISM EITHER.** It enters the **measured empirical
slope**, which is what the rest of this model does with quantities whose mechanism is not
resolved — `RN.GFR.VOLUME_SENSITIVITY` is exactly that shape. The mechanism stays unsourced
and the row must say so.

## 0.1 THE SOURCE IS OPEN AND WAS READ

Kitada K, Daub S, … Sands JM, Titze J. *High salt intake reprioritizes osmolyte and energy
metabolism for body fluid conservation.* J Clin Invest 2017;127(5):1944–1959.
PMID 28414295, **PMC5409074, open access, full text read** — it is already the citation on
`RN.URINE.SOLUTE_LOAD`. 10 healthy men, **739 complete 24 h collections**.

---

## 1. THE ARITHMETIC, FIXED BEFORE THE ROW IS WRITTEN

    non-sodium remainder   7.08 -> 6.58 mOsm/kg/day   as salt 6 -> 12 g/day NaCl
    salt                    103 -> 205 mmol/day        (delta 102)
    slope                  -0.50 / 102 = -0.004902 mOsm/kg/day per mEq/day

**The row is entered per kilogram**, because that is how the source reports it and because
the quantity is extensive — urea production tracks lean mass, exactly as
`RN.URINE.SOLUTE_NONNA` already scales. At the 70 kg reference that is **−0.343 mOsm/day
per mEq/day**, and the net slope of total osmolar excretion against sodium becomes
2.0 − 0.343 = **1.66**, against the note's estimate of "about 1.5".

**TWO SIGNIFICANT FIGURES AND NOT MORE.** The inputs are 7.08 and 6.58 — three figures
whose *difference* is 0.50, which carries two. Directive 1.13.

---

## 2. WHAT MAY NOT MOVE

- **The reference operating point.** The new term is written as
  `k * (Na_excr − Na_excr_ref)` with `Na_excr_ref` the nominal intake, so it is
  **identically zero at the reference** and `RN.URINE.SOLUTE_LOAD` returns exactly 930
  mOsm/day there. **Every ADH constant derived from that total — `ADH.URINE.OSM_MAX`,
  `ADH.URINE.OSM_BASELINE`, `ADH.OSM.SENSITIVITY` — and the four closure checks that depend
  on it must be untouched.** If any moves, the term is written wrongly.
- **`RN.URINE.OSM_PER_NA` stays 2.0.** It is charge balance — sodium and its anion — and it
  is sourced. The new term is the **non-sodium** remainder's response and must not be folded
  into the sodium coefficient, which would be failure mode #11: a name carrying a convention
  its value contradicts.
- **No natriuretic gain, no store parameter, no ADH parameter.**
- **The chronic salt sensitivity must stay inside 1.70–2.30** and the resting state
  unchanged.

---

## 3. DIRECTIVE 1.12

**2.0** mOsm per mEq. **600** and **930** mOsm/day. **1.5**, the note's own round estimate of
the net slope, which this pass computes properly rather than adopting.

---

## 4. THE DECISION RULE

- **U1 — the term is zero at the reference, the resting state and every ADH constant are
  unchanged, and the chronic solute swing falls toward the measured 157 mOsm/day.** Accept.
- **U2 — the resting state or any derived ADH constant moves.** The term is written wrongly.
  **Fix it; do not re-derive the ADH constants to absorb it.**
- **U3 — the chronic salt sensitivity leaves 1.70–2.30.** Report and stop. The solute limb
  is not licensed to move the pressure limb.
- **U4 — the acute urine volume moves.** Report it either way. It is the quantity §3.55 left
  open and it is **not** what this term is being fitted to.

---

## 5. THE FALSIFIABLE TESTS

1. **`Osm_load` at the reference is exactly 930 mOsm/day**, demonstrated by running.
2. **The chronic solute swing across 205 → 103 mEq/day falls from 204 toward 157 mOsm/day.**
3. **Chronic salt sensitivity inside 1.70–2.30**; resting MAP, `V_ecf`, urine volume and
   osmolality unchanged at the reference.
4. **Jensen's final window and the acute ordering ratio reported before and after**, and
   neither fitted.
5. **The row states that the MECHANISM is unsourced** and that only the slope is measured.

---

## 6. WHAT WOULD MAKE THIS PASS A FAILURE

**Folding the slope into `RN.URINE.OSM_PER_NA`.** It would make the arithmetic come out and
destroy the meaning of a sourced charge-balance coefficient.

**Re-deriving any ADH constant.** They descend from the reference total, the term is zero
there by construction, and anything that moves them means the construction is wrong.

**Tuning the slope to the acute urine volume.** §3.55 left that open and it is a different
manoeuvre on different data; the slope comes from Kitada's chronic arms and nothing else.
