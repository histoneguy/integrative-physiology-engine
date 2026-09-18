# Pre-registration — the plasma-to-urine osmolality map, and which ADH row is derived

**Written 2026-09-18, before Baylis is entered and before any ADH row is changed.** Verify
the ordering with

    git log --diff-filter=A -- validation/adh_osmotic_map_prereg.md
    git log --diff-filter=A -- validation/adh_osmotic_map_extract.py

Opened at the owner's instruction — *"fix the water limb"* — after `ADH.OSM.SENSITIVITY`'s
own note was read.

---

## 0. THE GAP THIS DISCHARGES IS ONE THE LEDGER DECLARED ITSELF

`ADH.OSM.SENSITIVITY`, in its own words:

> *"THIS IS NOT ZERBE'S SENSITIVITY: that is 0.12-1.66 pg/ml per mOsm/kg and this is a
> normalised 0-1 activity, **because no sourced map from plasma vasopressin to urine
> osmolality was found**."*

**That map has now been found.** Baylis PH, Pippard C, Gill GV, Burd J. *Development of a
cytochemical assay for plasma vasopressin: application to studies on water loading normal
man.* Clin Endocrinol (Oxf) 1986;24(4):383-93. **PMID 3017608.** Eight healthy male adults,
sustained water load, **paired plasma and urine osmolality**:

    plasma   286.5 +/- 2.0  ->  279.2 +/- 2.4 mmol/kg   (p < 0.001)
    urine    867   +/- 54   ->   69   +/- 3   mmol/kg

**JUDGE THE RESEARCH GROUP.** Baylis is the group that built the vasopressin assay this
subfield runs on. This is not a PubMed-indexed number of unknown provenance.

## 0.1 AND THE SIGNIFICANT-FIGURES CHECK IS RUN FIRST, NOT LAST

Directive 1.14 requires the supportable interval **before** the discrepancy is called one.
`p < 0.001` at df = 7 bounds `t > 5.41`, so the paired SE of the 7.3 mOsm/kg fall is under
1.35 and the 95% interval is at worst 4.1-10.5. **A slope back-derived from that span alone
is NOT resolved**, and a pass that rested on the slope would be chasing noise again.

**THE PASS DOES NOT REST ON THE SLOPE.** It rests on section 1, which is a category
distinction and survives the interval entirely.

---

## 1. THE DEFECT: A NAME CARRYING A CONVENTION ITS VALUE CONTRADICTS — FAILURE MODE #11

`ADH.OSM.THRESHOLD` = 284 mOsm/kg is tier A and its own name is
**"Osmotic threshold for vasopressin RELEASE"**, from Zerbe's hypertonic-saline regressions
of *plasma vasopressin* on plasma osmolality.

**THE MODEL DOES NOT USE IT AS THAT.** In `src/components/ADH.jl` it is the osmolality at
which `adh` reaches zero — the point where **URINE** reaches `U_min`. Release *beginning*
and urine reaching its *floor* are not the same osmolality, and they cannot be: minimal
urine requires vasopressin fully suppressed, which is **below** where release starts.

**Baylis measures the second quantity directly.** At plasma 279.2 his subjects' urine was
69 mmol/kg, against an assumed floor of 50 — essentially at the bottom. The dilution
threshold is therefore near **279**, not 284.

Run at Baylis's two osmolalities the model gives **464 and 50** where he measured
**867 +/- 54 and 69 +/- 3**. The dilute end is fine; the concentrated end is not, and 400
mmol/kg is not inside +/- 54.

---

## 2. THE FORM IS OVER-DETERMINED, AND THAT IS THE RESULT TO REPORT

`u_osm = U_min + clamp(k*(Osm - Osm_thr), 0, 1) * (U_max - U_min)` has four constants and
four constraints are now in evidence:

| constraint | source | status |
|---|---|---|
| `U_max` = 982 | Tryding 1988 | tier A, sourced |
| `U_min` = 50 | none | **assumed, tier C** |
| slope `k` | Baylis 1986 | **newly sourced** |
| passes through (287, 547.06) | the model's own 24 h water balance | derived, load-bearing |

Baylis's own two points fix `k` = 0.117 **and** `Osm_thr` = 279.0 together. Imposing both
puts baseline urine at **1.0 L/day**, not 1.7. Imposing Baylis's `k` with Zerbe's 284 puts
it at **2.5 L/day**. **The four cannot hold at once, and `U_min` cannot absorb it** — it
would have to be 311, which is not a minimum urine osmolality.

**WHY THE TWO DISAGREE, AND IT IS NOT A MODEL DEFECT.** Baylis's basal is a **spot morning
sample**; the model's 547.06 is a **24 h mean**. They are different estimands. The
like-for-like 24 h comparator is Kitada's **measured 508 +/- 170 mmol/kg in the model's own
salt arm**, and the model's 547 is inside it. **So Baylis may set the SHAPE and may not set
the POSITION**, and the write-up must say so in those terms.

---

## 3. THE PROPOSAL, FIXED BEFORE ANYTHING IS RUN

**Invert which row is derived.**

- `ADH.OSM.SENSITIVITY` becomes **sourced from Baylis** — two significant figures, 0.12.
  It was explicitly unsourced and the gap is now discharged.
- `ADH.OSM.THRESHOLD` becomes **derived** to position the curve at the model's 24 h
  operating point, and is **renamed** to say it is a urine-dilution threshold and not a
  release threshold. Predicted value **282.5**, which lies inside **Zerbe's own published
  individual range 280-288** and below his midpoint, exactly as section 1 requires.
- Zerbe stays on the row as the range that contains it. **Zerbe's 284 is not deleted and
  not contradicted** — it is identified as measuring a different quantity.

**THIS IS A STRICT PROVENANCE IMPROVEMENT ONLY IF BOTH HALVES HOLD.** A sourced slope
replaces an unsourced one; a mislabelled tier-A constant becomes an honestly-derived one.
If the derived threshold lands **outside 280-288**, the inversion is not licensed and
branch W3 applies.

---

## 4. WHAT MAY NOT MOVE

- **The 24 h operating point.** Resting urine 1.7 L/day, `u_osm` 547.06, `Osm_ecf` 287,
  MAP, `V_ecf`. The threshold is derived *to hold these*, so if any moves the derivation is
  written wrongly. **The closure checks that depend on them must pass untouched.**
- **`U_max` = 982 and `U_min` = 50.** Tryding is sourced; `U_min` is assumed and this pass
  does not get to tune an assumed row to absorb a discrepancy. Failure mode #22.
- **No natriuretic gain, no store parameter, no solute row, no GFR row.** The water limb is
  not licensed to move the sodium limb.
- **Chronic salt sensitivity, Jensen's final window and the acute ordering ratio are
  REPORTED before and after and NONE is fitted.**

---

## 5. DIRECTIVE 1.12 — THE ROUND NUMBERS

**284** (a midpoint of 280-288, adopted as a value). **50**. **287**. **280-295**, the
conventional "normal range" for plasma osmolality, which is a reference interval and not a
measurement of anything here.

---

## 6. THE DECISION RULE

- **W1 — the derived threshold lands inside 280-288 and the 24 h operating point is
  unchanged.** Adopt the inversion, rename the row, and report the acute urine volume
  against the **two-source band** and not against a point.
- **W2 — the operating point moves.** The derivation is written wrongly. Fix it; **do not
  re-derive anything else to absorb it.**
- **W3 — the derived threshold lands outside Zerbe's 280-288.** The inversion is not
  licensed. **Report that the linear-clamped form cannot carry the sourced constraints**,
  leave the model as it stands, and pre-register a form change separately.
- **W4 — the acute 6 h urine volume does not move toward the band.** Report it. The slope
  is Baylis's and is **not** adjusted to make the volume come out; that would be fitting a
  sourced row to a target.
- **W5 — anything in the sodium limb moves.** Stop. Read it as section 3.49's error
  repeating.

---

## 7. THE FALSIFIABLE TESTS

1. **The model is run at Baylis's two plasma osmolalities before and after**, and both
   numbers are reported against 867 +/- 54 and 69 +/- 3.
2. **The derived threshold is reported with Zerbe's 280-288 beside it.**
3. **The 24 h operating point is bit-unchanged**, demonstrated by running, not asserted.
4. **The acute 6 h urine volume is reported against Lobo 563 and Drummer ~738 as TWO
   SOURCES**, with the band's `assumed +/-33%` provenance restated, per directive 1.14.
5. **Chronic salt sensitivity, Jensen and the ordering ratio reported before and after.**
6. **The sensitivity row carries two significant figures**, being the ratio of a
   three-figure urine span to a two-figure plasma span. Directive 1.13.
7. **The threshold row's NAME changes**, not merely its note. A row whose name asserts the
   wrong quantity is the defect.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Adopting Baylis's threshold as well as his slope.** It would move the 24 h operating point
to 1.0 L/day on the strength of a spot morning sample. Section 2 is the whole reason this is
forbidden.

**Tuning `k` to the 6 h urine volume.** The slope comes from Baylis and nothing else. The
volume is an *outcome* of this pass and W4 exists so that a bad outcome gets reported rather
than absorbed.

**Moving `U_min`.** It is assumed, which makes it the easiest row in the file to move and
therefore the one most likely to be moved for the wrong reason.

**Deleting Zerbe.** The 284 is a correct measurement of a different quantity. Removing it
would lose the record of what the row used to claim, which is the finding.

**The quiet one: presenting the slope as the result.** Section 0.1 shows the slope alone is
not resolved by Baylis's interval. **The result is the category error in section 1** — that
a tier-A row was carrying a release threshold into a dilution role. If the write-up leads
with the slope, it has reported the weak half.
