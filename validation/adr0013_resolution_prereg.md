# Pre-registration — resolving ADR 0013

**Written 2026-09-18, before the record's status is changed.** Verify with

    git log --diff-filter=A -- validation/adr0013_resolution_prereg.md

**NO PARAMETER MAY MOVE.** ADR 0013 proposes `RN.PRESSURE_NATRIURESIS.SLOPE` 20.0 -> 51.0
and has stood `Proposed` since 2026-08-25 while the model ran past it, twice, to 11.4 and
then 8.4.

## 0. THE QUESTION, AND IT IS ANSWERABLE BY ARITHMETIC ALONE

ADR 0013's Context states its own relation: **`dMAP ~ d(intake)/G_pn`**. **Is its evidence
independent of the salt-sensitivity data the model is already built on, or is it the same
numbers inverted?** That is checkable before any judgement, and it decides the record.

## 1. WHAT MAY NOT MOVE

- **No parameter.** Not `RN.PRESSURE_NATRIURESIS.SLOPE`, not `CV.VOLUME.NATRIURETIC_GAIN`,
  not any gain, band or pin. **The value 8.4 stands whatever is concluded.**
- **ADR 0015 is not touched.** It is separately `Proposed` and out of scope.
- **The 1.70-2.30 band is not widened, moved or removed**, whatever is concluded about what
  it means. Changing a band is a separate, visible act.
- **No prior text is rewritten.** The record is amended at its foot.

## 2. THE DECISION RULE

- **R1 - the implied slopes are `100 / sensitivity` from the same meta-analyses.** Then the
  record contains no independent pressure measurement, its relation assumed a single-path
  model that ADR 0010 replaced, and its evidence is **already adopted** through the joint
  constraint. **Mark Superseded, adopt nothing, move no number.**
- **R2 - the evidence is independent of the salt-sensitivity band.** Then two sourced human
  constraints genuinely disagree and **that is a finding, not a value change.** Report;
  pre-register any re-estimation separately.
- **R3 - the arithmetic is ambiguous.** Record INDETERMINATE and leave `Proposed`.

## 3. THE FALSIFIABLE TESTS

1. **The inversion is computed and printed for all five sources**, including the two
   Graudal rows that disagree by a factor of eight.
2. **`git diff` shows no `value` field change.** Mechanically checkable.
3. **What ADR 0013 got RIGHT is stated as prominently as what it got wrong** - the model
   *was* calibrated to hypertensives and this record is why that stopped.
4. **The open disagreement between the Cutler/He and Graudal camps is restated as
   unresolved**, because nothing in this pass resolves it.
5. **Suite and harness green with nothing moved.**

## 4. WHAT WOULD MAKE THIS PASS A FAILURE

**Adopting 51.0.** The row is load-bearing and this pass is about a record, not a value.

**Marking it Rejected.** Its central claim was right and was acted on. Superseded and
Rejected are different words and the difference is the point.

**Quietly re-solving `G_pn` against the joint constraint** because the constraint came up.
That is §3.59's item and it is not this one.

**The quiet one: concluding R1 and not saying that the model is fitted to the band it is
checked against.** If R1 holds, the same three papers set the gain AND score it, and that
is the more uncomfortable half of the result.
