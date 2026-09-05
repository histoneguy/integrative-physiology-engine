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

---

## 8. AMENDMENTS, 2026-09-05

**Written after the sources were opened and before the component was built.** Each
one names the pre-registered text it changes and why. Amending a pre-registration
after seeing data is the thing pre-registration exists to prevent, so the test is
not whether an amendment is convenient but whether it could have flattered the
result — and each of these is checked against that below. Same discipline as the
ADR 0017 amendment.

### 8.1 The log base is resolved by a second measurement, not by the target

§4 fixed the form `ln(TSH) = a - b*FT4` and named `b` as the quantity to source.
The first extraction pass reached branch T3 because Benhadi 2010's abstract does
not state the base of its logarithm.

**Resolved in `thyroid_extract.py` §1** by Jostel 2009's independent estimate of
the same slope, whose base is fixed unambiguously by the downstream literature's
explicit `ln` and confirmed arithmetically against a 4,378-person cohort's own
published TSH, FT4 and TSH-index means. The two slopes agree to 1% under exactly
one pairing.

**Could this have flattered the result? No, and it demonstrably did not.** The
reading it selects is the one the earlier extraction noted puts the euthyroid
point further from mid-range, and the loop's predicted TSH came out 2.4× the
NHANES III geometric mean. **The amendment made the test harder and the model
then failed it on the conservative reading.** That is the evidence it was not
reverse-engineered.

### 8.2 The thyrotropin limb is algebraic — the §4 fallback, taken up front

§4: *"If the fast state makes the system stiff enough to slow the suite
materially, the thyrotropin limb is made algebraic and the reason recorded."*

Taken. Thyrotropin turns over in minutes; thyroxine's time constant is 10.3 days
and the model's horizon is 400. **The condition is met by inspection**, and it is
taken before paying the cost rather than after measuring it, because a state
relaxing four orders of magnitude faster than anything the model integrates
cannot repay directive 1.10. **ADR 0019 decision 3's two-state loop becomes one
state**, which is strictly cheaper than the record allowed for.

`THY.TSH.TAU` is therefore not sourced and not entered. §1's table lists it; it
is struck.

### 8.3 §2's exclusion of thyroid disease is relaxed for the METABOLIC ARM ONLY

§2 excludes thyroid disease of any kind. That exclusion is right for the axis
parameters and it is **unsatisfiable for the tissue gain**: the fractional change
in resting metabolic rate per fractional change in free thyroxine cannot be
measured in healthy people, because making a healthy person thyrotoxic is not an
experiment anyone may perform. This is the same argument `SOURCES.md` already
makes for animal preparations — the human experiment cannot ethically be done —
applied to a disease preparation instead of a species.

**Scope of the relaxation, stated narrowly:** it applies to
`THY.METABOLIC_GAIN` and to nothing else. Every parameter of the feedback loop
itself is sourced inside the original admissibility rules.

**And the arm it feeds defaults OFF**, which ADR 0019 decision 4 already required
before any of this was known. So the relaxation changes no default behaviour; it
puts a sourced number behind a switch instead of leaving the switch pointing at
nothing.

### 8.4 The euthyroid FT4 is a measured concentration, not a reference interval

§6: *"It may not use either reference interval to set a parameter."* Upheld.
`THY.FT4.EUTHYROID` is Braverman 1973's equilibrium-dialysis measurement in 11
normal subjects — a concentration measured by the method §2 says to prefer, not a
percentile of a laboratory population. §1's `THY.FT4.REFERENCE` — the *interval*
— is still a target and is still untouched.

**This is the weakest joint in the record and it is named here rather than
buried.** It supplies the absolute FT4 scale that Benhadi's per-pmol/L slope
needs, across a 49-year gap and two unrelated methods. The corroboration is
empirical: Maushart 2022's euthyroid immunoassay visits give 15.0 and 16.6
pmol/L against Braverman's 16.6.

### 8.5 The outcome is branch T2, and §5's instruction is followed

The loop's euthyroid TSH lands inside the conventional 0.4–4.0 interval but at
2.4× the NHANES III reference-population geometric mean. **Reported, not tuned,
and decomposed**: slope corroborated, FT4 level corroborated, intercept
unreplicated and carrying the whole discrepancy.

### 8.6 Two estimates that agree are AVERAGED, not chosen between

§2 says values from different assays are not pooled. Applied literally to the two
slope estimates it produced a bad outcome: the ledger entered Benhadi's 0.13585
and demoted Jostel's 0.1345 to "corroboration", **when the two agree to 1%**.

**That rule exists to stop a real method difference being averaged away.** It is
not a licence to pick one of two measurements that agree to a fifth of anyone's
plausible error, which is a coin toss with a justification attached. The entered
slope is the unweighted mean, 0.1352, and the spread is the uncertainty.
Unweighted because neither source reports a standard error and no weighting moves
a 1% interval anywhere that matters.

**`THY.METABOLIC_GAIN` was corrected the same way** — two estimates of one
quantity from one cohort, 0.192 and 0.230, of which the *lower* had been entered.
Preferring the conservative-looking number is a bias, not a caution. The mean,
0.211, is entered.

**And every thyroid row was cut to the significant figures its source supports.**
Six and seven figures had been entered on numbers reported to three. Directive
1.9 and HANDOVER §3.23 already covered this and it was broken anyway; the ledger
notes carry the arithmetic.

**The useful consequence, not a bookkeeping one:** with the slope's real spread in
hand it can be swept, and doing so moves the model's euthyroid thyrotropin by 2%
against a discrepancy of 2.4×. **§8.5's decomposition is now arithmetic rather
than an argument from counting sources.**

### 8.7 §6's real prohibition was the one it did not write down

§6: *"It may not use either reference interval to set a parameter."* Upheld
throughout — and it turned out not to be the binding constraint.

**The binding constraint was that a slope and a concentration must share a
scale.** §2 prohibits *pooling* across free-thyroxine assays; nothing prohibited
*composing* across them, which is what the ledger did, and it produced a
euthyroid thyrotropin 2.2× high that was reported for a day as a failed
prediction. It was a unit error.

`validation/nhanes_hpt_prereg.md` and its extract settle it in public data:
total thyroxine agrees to 6% between an immunoassay population and Braverman's
dialysis subjects, while the free fractions differ 1.73-fold.

**Consequences, recorded here because §6 required them in these words:**
`THY.FT4.EUTHYROID` and `THY.TSH.EUTHYROID` now come from one population on one
assay, `THY.LOOP_GAIN` carries the only scale-invariant quantity in the axis, the
slope and intercept are derived from those, and **ADR 0019's falsifiable test 2 is
void.** The euthyroid point is an input; the response is the claim.
