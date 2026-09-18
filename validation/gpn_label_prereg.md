# Pre-registration — the pressure-natriuresis slope's provenance, and a stale constraint

**Written 2026-09-18, before any field is edited.** Verify with

    git log --diff-filter=A -- validation/gpn_label_prereg.md

Short. **This pass extracts nothing and MAY NOT MOVE THE VALUE.** `RN.PRESSURE_NATRIURESIS.SLOPE`
is the last `calibrated` row and it is load-bearing for the pressure limb.

---

## 0. TWO DEFECTS, BOTH PROVENANCE, NEITHER A VALUE

**DEFECT 1 — THE CITATION DESCRIBES A VALUE THE ROW NO LONGER HOLDS.** The `citation` field
is *Guyton AC, Coleman TG, Granger HJ. Circulation: overall regulation. Annu Rev Physiol
1972;34:13-46* and `extraction_method` is `calibrated`, which `SOURCES.md` defines as a
value lifted from another model's fitted parameters. **The value 8.4 is not Guyton's.** The
row's own note says what it is: *"8.4 is the CONSTRAINT-CONSISTENT partner of the sourced
volume gain"*, solved from a human joint constraint inside **this** model. Guyton is the
origin of the ROW and of the form; he is not the source of the NUMBER.

**This is the same shape as `RN.MD.RENIN_GAIN`, which already states it honestly about
itself:** *"NO ORIGINATING MODEL … this is solved inside THIS model against human
measurements, which makes it a fit rather than a citation."* That row's wording is the
precedent this pass follows.

**DEFECT 2 — THE STATED CONSTRAINT IS NO LONGER SATISFIED, AND NOTHING SAYS SO.** The note
records the human joint constraint as `G_pn + 0.0594*G_anp = 50` and says 8.4 follows
"with `CV.ANP.NATRIURETIC_GAIN` sourced at 700". **That partner is now 585.**

    8.4 + 0.0594 * 700 = 49.98    satisfied, as written
    8.4 + 0.0594 * 585 = 43.15    SHORT BY 6.85, about 14%

---

## 1. AND DEFECT 2 IS NOT A VALUE DEFECT — CHECK BEFORE CHASING

Directive 1.14, applied before calling this a discrepancy. **The model's chronic salt
sensitivity at the current pair is 1.96, inside the human 1.70–2.30.** The pair works.

**Why both can be true:** `CV.VOLUME.NATRIURETIC_GAIN` was re-solved 700 → 585 **against the
nonlinear model outcome at `G_pn` held to 8.4**, targeting a chronic salt sensitivity of
2.00. `G_pn + 0.0594*G_anp = 50` is a **LINEARISATION** of that same target. The solved pair
satisfies the outcome; it does not satisfy the linearisation. **The outcome is the thing
that was ever meant to hold.**

**So the defect is that the note states a constraint the model deliberately does not
satisfy, with no flag.** Two copies of a fact that have drifted apart — which is the failure
`CLAUDE.md` says this whole repository is organised against.

---

## 2. WHAT THIS PASS MAY NOT DO

- **THE VALUE 8.4 MAY NOT MOVE**, nor `CV.VOLUME.NATRIURETIC_GAIN`, nor any band, pin or
  tolerance. **Test: model output unchanged**, demonstrated by running.
- **The constraint may NOT be "restored" by moving `G_pn` to 15.25.** That is a
  re-estimation, it would move the chronic limb off a target it currently hits, and doing it
  in the pass that found the drift is re-estimating against a discrepancy the same pass
  surfaced.
- **ADR 0013 is not adopted.** It proposes 51.0 and remains `Proposed`; this pass does not
  resolve it.
- **No prior note prose or ADR text is rewritten.** Append only.

---

## 3. THE DECISION RULE

- **P1 — provenance fields corrected, value unchanged, output unchanged.** Adopt.
- **P2 — any output moves.** Something was touched that should not have been. Revert.
- **P3 — the linearisation turns out to be the thing that is right and the outcome fit
  wrong.** Report and stop; that is a re-estimation pass with its own pre-registration.

---

## 4. THE FALSIFIABLE TESTS

1. **`git diff` shows no `value` field change anywhere.** Checkable mechanically.
2. **Model output unchanged**; suite and `challenges.jl` green with nothing moved.
3. **The row states plainly that 8.4 is solved inside this model and is not Guyton's
   number**, with Guyton retained as the origin of the row and the form.
4. **The constraint drift is recorded on the row** — 43.15 against 50, why it is not a
   defect, and what would make it one.
5. **ADRs 0013 and 0015 being `Proposed` while the model is built on them is reported**,
   not silently resolved.

---

## 5. WHAT WOULD MAKE THIS PASS A FAILURE

**Moving 8.4 to 15.25 to satisfy the linearisation.** §1 and §2. The outcome is what holds.

**Deleting Guyton.** He is the origin of the row, of the form, and of the 20.0 that stood
for months. Removing the citation loses that history; the fix is to say what he is the
source **of**.

**Adopting ADR 0013's 51.0 in passing** because the row is being touched anyway.

**The quiet one: presenting the constraint drift as a bug.** It is a stale note beside a
working pair, and saying otherwise would manufacture a defect to justify the pass.
