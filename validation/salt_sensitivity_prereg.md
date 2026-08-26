# Pre-registration: the blood pressure response to chronic sodium intake in normotensive humans

**Written 2026-08-25, BEFORE any paper was opened.**
Eighth in the series. Binding under `validation/pooling.md` and directive 1.7.

**This one sources the model's own headline output.** Every previous pre-registration
sourced a component parameter. This sources the quantity the model exists to produce, and
it is the first that can tell us whether the model is right rather than whether a part of
it is well cited.

---

## 0. WHAT THE MODEL ALREADY SAYS, STATED FIRST SO IT CANNOT BE QUIETLY MET

| intake (mEq/d) | MAP (mmHg) |
|---|---|
| 205 | 93.000 |
| 154 | 90.534 |
| 103 | 88.066 |

**4.934 mmHg across 102 mEq/day**, i.e. **4.84 mmHg per 100 mEq/day**, or
0.0484 mmHg per mEq/day. Bit-stable since the loop first closed and pinned in
`test/runtests.jl`.

At steady state the model gives `dMAP ~ d(intake)/G_pn`, so a sourced human slope is a
**direct estimate of `G_pn`**:

    G_pn_implied  =  d(intake) / d(MAP)      [(mEq/day) / mmHg]

The incumbent `RN.PRESSURE_NATRIURESIS.SLOPE` is **20.0**, a fitted constant from
Guyton 1972. The Mizelle 1993 dog comparison implies 5.43, which would give a 15.7 mmHg
shift. **This search estimates the same quantity in humans, directly, from the model's
own output variable.** If it succeeds, the dog slope becomes a mechanistic cross-check and
the uncited `DOG_GFR` and the 2.2x residual stop being on the critical path.

---

## 1. THE HAZARD, AND IT IS THE WORST IN THE SERIES

The model predicts 4.934 mmHg. The human literature **explicitly partitions normotensive
subjects into salt-sensitive and salt-resistant**, whose blood pressure responses differ
several-fold by construction. A reader free to choose the subgroup can obtain almost any
answer and cite it honestly.

**Declared before searching, and this is the load-bearing decision of this document:**

> **The target is the UNSELECTED normotensive population mean.** Not the salt-sensitive
> subgroup, not the salt-resistant subgroup, not a mean of the two subgroup means.

Reasons, fixed now: the model has one `G_pn` and no salt-sensitivity covariate; and
`src/ensemble.jl` samples a *population*, so the population mean is the quantity a
population model should reproduce. **Salt sensitivity is the variance this model does not
yet represent, and the subgroup means are the evidence for a future covariate - recorded,
never pooled into the target.**

Where a study reports only subgroups, recombine to an unselected mean using the reported
subgroup `n` if both are given. If it cannot be recombined, record it as **subgroup-only**
and exclude it from the pooled estimate.

**Additional prohibitions, declared now:**

- **No study may be included, excluded, weighted or trimmed by how close it lands to
  4.934 mmHg.** The comparison is computed **once, after pooling is complete**, and
  reported as a divergence whichever way it falls.
- **A large divergence is the finding, not a problem.** If the human slope implies
  `G_pn` far from 20.0, that is the most valuable result this repo could obtain, and it
  must not be softened by widening the inclusion criteria until the incumbent falls inside
  the range.

---

## 2. WHAT IS BEING EXTRACTED

| # | Quantity | Unit |
|---|---|---|
| Q1 | Change in **MAP** per change in chronic sodium intake, unselected normotensive adults | mmHg per 100 mEq/day |
| Q2 | The same in salt-sensitive and salt-resistant subgroups separately | mmHg per 100 mEq/day |
| Q3 | Whether the relation is linear over the model's 103-205 mEq/day range | - |

**Q2 is extracted but is NOT the target.** It is recorded as the evidence base for a
future salt-sensitivity covariate, and per §1 it may not enter the pooled estimate.

**MAP conversion, fixed in advance.** Where MAP is reported, use it. Where only SBP and
DBP are reported, use `MAP = DBP + (SBP - DBP)/3`. That form factor is **not constant** -
`src/reconstruct.jl` already records it as the single largest error source in within-cycle
reconstruction - so every converted value is flagged `converted` and a sensitivity check
is run with the pooled estimate computed from DBP alone. If the conclusion depends on the
conversion, say so.

---

## 3. SEARCH STRATEGY

**`pooling.md` rule 1 puts meta-analysis first**, and this is a literature where
systematic reviews of sodium intake against blood pressure exist. Search them first, take
the pooled estimate and its dispersion, and **do not re-pool it with primaries already
inside it** - that is double-counting and is prohibited.

Where a review and its primaries disagree, `pooling.md` says the **primaries win**. That
clause has already fired once here, on Epstein's immersion range.

Terms are relationship-shaped per directive 1.7: sodium intake and blood pressure;
dietary sodium reduction blood pressure; graded sodium intake; sodium loading normotensive.

---

## 4. INCLUSION AND EXCLUSION

**Include** if all of:

1. **Normotensive** adults, defined by the source, and the definition recorded.
2. **At least two sodium intake levels**, quantified, with intake **measured or
   controlled** - 24 h urinary sodium preferred over dietary recall.
3. Blood pressure measured at each level.
4. **Duration per level long enough to approach steady state.** The model runs 30 days per
   level. Fix the minimum at **5 days** and record the actual duration per study; anything
   shorter is recorded as **short-protocol** and pooled separately, because a protocol that
   has not equilibrated measures a transient and the model's number is a steady state.

**Exclude** if any of:

1. Hypertensive cohorts, or mixed cohorts where normotensives cannot be separated.
2. The sodium manipulation is a **probe for something else** - a drug trial, a diuretic
   study, a genotype challenge, a device evaluation. Directive 1.7: if the answer to
   *"what would this paper's conclusion have been if the physiology had come out
   differently"* concerns a drug or a method, the relationship is the instrument.
3. Acute intravenous saline loading. The model's perturbation is chronic dietary intake,
   and §5 of `sv_filling_prereg.md` already established that infused volume is not a
   measured volume change.
4. Sodium given as a salt other than chloride without a chloride arm - the repo's own
   ledger notes the chloride question as live.

---

## 5. RANGE

The model's step is **103 to 205 mEq/day**. Studies whose range brackets that are the
primary set. Studies spanning far wider ranges - the extreme-loading literature goes to
many hundreds of mEq/day - are **recorded separately** and used only to test Q3 linearity,
because a slope taken across a 15-fold range is not the same quantity as a slope across
the model's 2-fold range.

---

## 6. POOLING

Rule order per `pooling.md`: `meta-analysis` first, then `pooled-inverse-variance`, then
`pooled-n-weighted`. **Not geometric** - mmHg per 100 mEq/day is a physical slope, not a
dimensionless multiplier. Declared now so the rule cannot be chosen after seeing the
spread.

**Never pool** unselected means with subgroup means (§1), short-protocol with
steady-state, or converted-MAP with reported-MAP without running the §2 sensitivity check.

---

## 7. STOP CONDITIONS

1. **k < 3 independent sources, or one qualifying meta-analysis, means no parameter is
   recorded.** `RN.PRESSURE_NATRIURESIS.SLOPE` stays at 20.0.
2. **No citation recorded without opening it.** Authors, journal, year, volume, pages
   verified against the retrieved record.
3. **No fitted or assumed value substitutes for a missing one.**
4. **§1's prohibitions are binding** - no selection on proximity to 4.934, and no
   softening of a divergence.
5. **A thin yield after the 1.7 exclusion is a result**, not licence to admit drug trials.
6. **Sourcing does not license changing `G_pn`.** A re-estimated slope goes through an ADR
   with its own falsifiable test, because `G_pn` sets the model's headline claim and the
   test suite pins it deliberately.

---

## 8. WHAT WOULD FALSIFY THE APPROACH

**If the unselected normotensive slope cannot be recovered** - because the literature
reports only salt-sensitive and salt-resistant subgroups, or only hypertensive cohorts -
then the quantity the model produces is not the quantity the field measures, and that is a
finding about the model's framing rather than about the literature.

**If the relation is strongly non-linear across 103-205 mEq/day**, a single `G_pn` cannot
represent it and ADR 0007's linear pressure-natriuresis term is wrong in a way the salt
step would not reveal.

**And the outcome that would matter most.** If the human population slope implies a `G_pn`
far from 20.0, then the model's headline result - 4.934 mmHg, bit-stable since the loop
closed, pinned in the test suite, quoted in every handover - **has been wrong the whole
time**, and every downstream conclusion that leaned on it needs revisiting. That is the
outcome this pre-registration exists to make reportable rather than avoidable.
