# Pre-registration: can the sourced venous mechanics produce the `G_vr` the human salt data demand?

**Written BEFORE any source was opened.** Date: 2026-09-02.

**An extension of `validation/venous_compliance_prereg.md`, not a replacement.** That
document asked what the filling relation's *shape* is and answered it: **linear**, in
humans and three other species, by four methods. It deliberately entered **no ledger
parameter**, because human compliance is k = 1 and the animal values cannot be pooled
across species or preparation.

This document asks the question that became answerable only on 2026-09-02, when
`validation/ecf_salt_response_extract.py` produced a **target**:

> `CV.VENOUS_RETURN.SENSITIVITY` must be **1012–1941 (L/day)/L** for the model to match
> the human chronic pressure and volume responses to dietary sodium simultaneously.

`G_vr` is `calibrated` — fitted, never measured. HANDOVER §4 item 1 is to **replace** it
with sourced venous mechanics. **Whether that is possible is the question here, and it is
not obviously yes.**

---

## 0. WHAT IS ALREADY SOURCED, AND THE ONE MISSING PIECE

From `venous_compliance_extract.py`, already executed:

| quantity | value | source | status |
|---|---|---|---|
| systemic compliance `C_sys`, human | **64.3 ± 32.7 mL/mmHg** (0.97 mL/mmHg/kg PBW) | Maas 2012, n = 15, PMID 22763909 | sourced, k = 1, LINEAR |
| stressed volume fraction, human | 28.5% ± 15% of predicted blood volume | Maas 2012 | sourced, k = 1 |
| shape of the filling relation | **linear** over the physiological range | 6 studies, 4 species, 4 methods | established |
| **resistance to venous return `R_vr`** | — | **never extracted** | **THE GAP** |

`G_vr` composes as

    dCO/dV_blood  =  (dPmsf/dV_blood) x (dCO/dPmsf)  =  1 / (C_sys * R_vr)

when right atrial pressure is treated as fixed, which is what this model does — `MAP ~ CO
* TPR` neglects RAP, and `relations.csv` records that as a modelling choice.

**`C_sys` is sourced. `R_vr` is not. That single number closes the composition, so it is
what this pre-registration goes after.**

## 0.1 THE ARITHMETIC THAT MAKES THIS A TEST, FIXED BEFORE SEARCHING

`1/C_sys` = 1/0.0643 L/mmHg = **15.55 mmHg per litre of blood volume** (Maas 2012).

So the model's target range corresponds to an implied resistance to venous return of

    R_implied  =  (1/C_sys) / G_vr_target
               =  15.55 / (1012 to 1941 L/day/L)
               =  15.55 / (0.703 to 1.348 L/min/L)
               =  **11.5 to 22.1 mmHg/(L/min)**

**That is the number the search has to check.** If the sourced `R_vr` lands in 11.5–22.1,
the venous mechanics explain `G_vr` and the parameter can be derived rather than fitted.
If it lands far below, they do not, and the model is missing a mechanism that absorbs
chronic volume.

**Recorded before searching: I expect it to land far below**, because the prior extract
already contains the mechanism that would explain a shortfall — Cha 1992 and Ogilvie 1992
both report added volume being accommodated as **unstressed** volume, and Greenway & Lautt
put ~60% of blood volume in the unstressed reserve at minimal tone. If chronic expansion
recruits unstressed volume, ΔPmsf per litre is far below `1/C_sys` and the composition
above overestimates `G_vr`. **Writing the expectation down is what makes the result
falsifiable rather than a rationalisation afterwards.**

---

## 1. WHAT IS BEING EXTRACTED

**Resistance to venous return**, `R_vr` = (Pmsf − RAP)/CO, in mmHg/(L/min), or equivalently
the **slope of the venous return curve**, in L/min/mmHg.

Recorded for every study: species, preparation, anaesthesia, whether reflexes were intact
or blocked, the range of right atrial pressure traversed, and n.

## 2. SEARCH STRATEGY

Two sweeps minimum, per directive 1.8. Relationship-shaped per directive 1.7: the subject
is *the venous return curve*, not "what is venous resistance".

**Sweep 1** — venous return curve slope, resistance to venous return, mean systemic
filling pressure and cardiac output, in humans.
**Sweep 2** — the animal preparations that define the curve, because sweep 1 will
under-return: Guyton's own series and its successors, right-atrial-pressure servo studies,
and inspiratory-hold human work.

## 3. INCLUSION AND EXCLUSION

**Include** if the study reports `R_vr` or the venous return curve slope as a measured
quantity, in a preparation where the relationship is the subject (directive 1.7).

**Exclude** hypovolaemic shock, heart failure and sepsis cohorts as *primary* sources —
they may be recorded as range evidence but the model's operating point is health.

**Species is recorded, never pooled across** (`pooling.md`). Guyton's venous return curve
is dog work; that is legitimate evidence under directive 1.6 provided the species is stated
and the ethical-ceiling promotion of ADR 0006 is **not** claimed, because the human
experiment is performable — Maas 2012 performed it.

## 4. POOLING

`pooling.md` order unchanged. Human and animal are reported separately. **k = 1 is
declared as k = 1.**

---

## 5. THE DECISION RULE, FIXED IN ADVANCE

Let `R_src` be the sourced resistance to venous return, in mmHg/(L/min).

- **R1 — `R_src` lands in 11.5–22.1.** The venous mechanics explain `G_vr`.
  `CV.VENOUS_RETURN.SENSITIVITY` becomes **`derived`** as `1/(C_sys·R_vr)`, its citation
  becomes Maas 2012 plus the `R_vr` source, and §4 item 1 is discharged.
- **R2 — `R_src` is far BELOW 11.5** (i.e. the mechanics predict a `G_vr` far larger than
  the salt data allow). **The composition does not close, and that is a finding about the
  MODEL, not about the sources.** It means chronic volume expansion is absorbed by
  something the model does not represent. `G_vr` stays `calibrated`, and the work moves to
  the mechanism — the stressed/unstressed distinction the prior extract already identified
  as the operative variable.
- **R3 — `R_src` far above 22.1.** The mechanics predict a `G_vr` smaller than the salt
  data allow, which would point at `C_sys` or at the salt-response extraction. Re-examine
  both before touching the model.
- **R4 — no usable source.** Record what was tried; `G_vr` stays `calibrated` and §4
  item 1 stays open with the composition written down for the next attempt.

**Under R2 the model change is NOT made in the same pass.** Introducing stressed/unstressed
volume supersedes ADR 0012's central/peripheral cut, which is a live structural record with
its own falsifiable test. That is a decision for its own ADR and for the owner, not a side
effect of a sourcing pass.

## 6. WHAT WOULD FALSIFY THE APPROACH

- **If `R_vr` is not a constant** over the relevant range — if the venous return curve is
  not straight — the composition above is invalid and the shape has to be carried instead.
  The prior extract found the *filling* relation linear; that is a different curve.
- **If the human and animal values differ by more than the animal between-preparation
  spread**, the animal literature cannot stand in for the human number and R4 applies even
  though numbers exist.
- **If `C_sys` from Maas 2012 is not the compliance this composition needs** — it is
  measured over ten 50 mL boluses, an acute manoeuvre, while the model's step is 30 days.
  **This is the most likely way the whole approach fails**, and it is the same
  acute-versus-chronic mismatch flagged in §0.1. Record it if the numbers force it.

## 7. OUT OF SCOPE

- Entering any value for `G_vr` that is not derived from sourced quantities. **Fitting
  2880 to 1400 is prohibited** — it would swap one calibrated constant for another and
  destroy the only independent test this line of work has.
- ADR 0013 and `G_pn`, which are blocked behind this and stay blocked.
- Implementing stressed/unstressed volume (see §5).
- ADR 0012 stage 2 and the posture gradient.
