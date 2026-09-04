# Pre-registration — hypothalamic-pituitary-thyroid axis parameters

**Written before any source is opened for these values.** Search results have been
listed by TITLE only; no abstract has been read. Verify ordering with

    git log --diff-filter=A -- validation/thyroid_prereg.md
    git log --diff-filter=A -- validation/thyroid_extract.py

Structure decided in **ADR 0019**.

---

## 1. THE QUANTITIES

| id | what | role |
|---|---|---|
| `THY.TSH.FT4_SLOPE` | fall in log thyrotropin per unit free thyroxine | the feedback gain |
| `THY.FT4.SECRETION` | thyroxine secretion at reference thyrotropin | the forward gain |
| `THY.FT4.TAU` | thyroxine turnover time constant | makes the axis slow |
| `THY.TSH.TAU` | thyrotropin turnover time constant | the fast limb |
| `THY.FT4.REFERENCE` | euthyroid free thyroxine | the point the loop must reproduce |
| `THY.TSH.REFERENCE` | euthyroid thyrotropin | the other half of the same test |
| `THY.METABOLIC_GAIN` | fractional change in resting metabolic rate per fractional change in free thyroxine | the arm that reaches respiration |

**`THY.FT4.REFERENCE` and `THY.TSH.REFERENCE` ARE NOT INPUTS TO THE LOOP.** They are
the targets ADR 0019's second falsifiable test judges it against. **If either is used
to set a parameter, that test is void** and this document has failed at its only job.

---

## 2. ADMISSIBILITY

**Include:** healthy euthyroid adults, no thyroid disease, no thyroid medication, no
iodine deficiency or excess, not pregnant, no acute illness, iodine-replete population
where stated. Record n, sex, age, assay and the reference interval the source itself
used.

**Exclude:** thyroid disease of any kind, thyroid hormone or antithyroid therapy,
amiodarone or lithium, non-thyroidal illness, pregnancy, and neonates.

**ASSAYS ARE THE METHOD SPLIT HERE, AND THEY ARE NOT COMPARABLE.** Free thyroxine
immunoassays differ substantially between manufacturers and against equilibrium
dialysis. `pooling.md` prohibits pooling across incompatible methods, so **the assay is
recorded for every source and values from different assays are NOT pooled.** Where a
choice exists, prefer equilibrium dialysis or a source that states its method.

**Directive 1.7's form here.** Much of this literature exists to define a screening
cut-off or to argue a treatment threshold. The relationship is the instrument there.
Prefer sources whose purpose was to characterise the axis in healthy people.

---

## 3. DIRECTIVE 1.12

Round teaching numbers to expect: thyrotropin 1.0 or 2.0 mIU/L, free thyroxine 1.0 or
1.3 ng/dL, a reference interval of 0.4–4.0 mIU/L, a thyroxine half-life of exactly 7
days. **None is entered as `reported`.** Unsourceable values enter `assumed`.

---

## 4. THE FORM

**Log-linear feedback, fixed here before searching:**

    ln(TSH) = a - b * FT4

This is the standard description and the reason thyrotropin is reported logarithmically
in clinical practice. **`b` is `THY.TSH.FT4_SLOPE` and is the quantity to source.** `a`
is NOT sourced separately — it is whatever makes the loop cross at the sourced
secretion, and fixing both would over-determine the operating point and destroy
falsifiable test 2.

**Two states, and the units are the trap.** The model's time base is DAYS. Thyroxine
turnover is about a week and thyrotropin's is minutes, so the two constants differ by
roughly three orders of magnitude and one of them is far below any step this model
takes. **If the fast state makes the system stiff enough to slow the suite materially,
the thyrotropin limb is made algebraic and the reason recorded** — ADR 0019 decision 3
justifies the slow state only, and directive 1.10 says suite runtime is paid forever.

---

## 5. THE DECISION RULE

- **T1 — the loop crosses inside BOTH human reference intervals.** Build and connect,
  run all four falsifiable tests, ADR 0019 to Accepted.
- **T2 — it crosses outside one or both.** **Report it, do not tune.** Then decompose:
  the feedback slope, the secretion gain and the reference intervals are separable, and
  the extract must say which carries the discrepancy. This is the branch ADR 0017 hit
  and it is written down again because it is the likely one.
- **T3 — the feedback slope cannot be sourced in healthy euthyroid adults.** The axis
  is NOT built. A feedback loop with an unsourced gain is a fitted loop, and fitting it
  to the reference intervals is precisely the circularity that made
  `RN.PRESSURE_NATRIURESIS.SLOPE` a hypertensive value.
- **T4 — the metabolic gain cannot be sourced.** Build the feedback loop, leave the
  metabolic arm OFF as ADR 0019 already defaults it, and record that respiration's
  `RESP.CO2.PRODUCTION` stays a primitive. **The loop is worth having on its own**;
  the metabolic arm is what makes it reach another component, and an unsourced arm
  reaching into the water balance is worse than no arm.

---

## 6. WHAT THE ANSWER MAY NOT DO

- It may not change any existing parameter value.
- With the metabolic arm off, every existing result must be **bit-identical**. Not
  close — identical. The axis touches nothing until that arm is enabled.
- It may not use either reference interval to set a parameter. See §1.
- It may not add more than two states.
- **It may not report the euthyroid point as a validation if any parameter was chosen
  to produce it.** That is the trap HANDOVER §3.15 records the Lobo endpoints falling
  into: a dataset used for estimation reported back as agreement.

---

## 7. WHY THIS AXIS AND NOT ANOTHER

Cortisol, growth hormone, insulin, parathyroid hormone are all absent. Thyroid is first
because **it is the only one that drives a quantity another component already
consumes** — resting metabolic rate, which sets the CO2 production ADR 0017's
respiratory loop balances, and which is currently `assumed` at a round number.

Directive 1.11 says a parameter nobody calls is not evidence about anything, and ADR
0006 records Circadian sitting unconnected because it was built ahead of its dependency.
**An endocrine axis chosen for completeness rather than connection would repeat that.**
