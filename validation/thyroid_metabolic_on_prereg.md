# Pre-registration — switching the thyroid metabolic arm ON by default

**Written 2026-09-18, before the default is flipped.** Verify with

    git log --diff-filter=A -- validation/thyroid_metabolic_on_prereg.md

**At the owner's instruction.** This reverses a default that was set deliberately and in
advance, so the reversal is argued rather than assumed.

## 0. WHAT IS BEING REVERSED, AND WHY IT WAS SET

**ADR 0019 decision 4** put the metabolic arm OFF by default. `thyroid_prereg.md` §8.3
states why that mattered: `THY.METABOLIC_GAIN` comes from a **disease preparation**
(Maushart 2022, paired hyperthyroid → euthyroid), which breaks §2's exclusion of thyroid
disease. The exclusion is **unsatisfiable** for this quantity — a healthy person cannot
ethically be made thyrotoxic — so §8.3 relaxed it for that one row and leaned on the
default being off: *"the relaxation changes no default behaviour; it puts a sourced number
behind a switch instead of leaving the switch pointing at nothing."*

**FLIPPING THE DEFAULT REMOVES THE THING THAT MADE THE RELAXATION SAFE.** That is the whole
content of this pass and it must be stated in ADR 0019, not buried.

## 1. THE ARGUMENT FOR FLIPPING IT

- **The arm is INERT AT EUTHYROID BY CONSTRUCTION.** `th_mod = 1 + G_met*(FT4/FT4_ref − 1)`
  is exactly 1.0 when `FT4 = FT4_ref`. The disease-derived gain **multiplies a deviation
  that is zero at the operating point.**
- **The gain is tier A, `derived`, human**, 0.211 with a range of 0.192–0.230 from the
  paper's two visits, and the CO2 link is **tested in the same paper rather than assumed**
  (*"RQ was not significantly affected by thyroid hormone state"*).
- **The owner's standing rule:** if we take the time to find a value or relationship, it is
  in the model; if it fails, we fix it. A sourced, tested, wired arm sitting behind a
  default-off switch is the thing that rule was written against.

## 2. WHAT MAY NOT MOVE

- **No parameter.** `THY.METABOLIC_GAIN` and every axis row stay exactly as they are.
- **The resting state must move by LESS THAN the model's own FT4 equilibrium offset.** The
  axis settles ~7e-5 off `FT4_ref`, so `th_mod` at rest is ~1 + 0.211*7e-5 ≈ 1.000015 and
  resting PaCO2 must move by at most that fraction. **Anything larger means the arm is not
  inert at euthyroid and the flip is wrong.**
- **No band, pin or tolerance may be widened to accommodate it** — except the one test whose
  premise is the old default, §3.
- **Ventilation and the water balance must NOT move at any thyroid state.** ADR 0019's A-note
  records why: resting PaCO2 is 40 against a ventilatory recruitment threshold of 45.28, so
  the chemoreflex is on its flat limb. **If they move, something else is wrong.**

## 3. THE ONE TEST WHOSE PREMISE THIS CHANGES

`test/runtests.jl` asserts `th_mod == 1.0` exactly, with the comment *"ADR 0019 decision 4
and thyroid_prereg.md section 6 require bit-identity, not closeness, so this is == and not
isapprox."*

**That test is correct and its premise is what is being reversed.** It is rewritten to
assert the arm is ON and inert at euthyroid to within the axis's own equilibrium offset —
**not** deleted, and not loosened for any other reason. The bit-identity claim it encoded
is retired explicitly, in ADR 0019, as the cost of the flip.

## 4. THE DECISION RULE

- **T1 — resting state moves by ≤ the FT4 offset, ventilation and water unmoved, the
  hyperthyroid predictions still hold.** Adopt, amend ADR 0019 decision 4.
- **T2 — resting PaCO2 moves by more than the FT4 offset.** The arm is not inert at
  euthyroid. **Stop and investigate; do not accept it.**
- **T3 — ventilation or the water balance moves.** ADR 0019's flat-limb finding is wrong or
  the wiring is. **Report and stop.**
- **T4 — anything in the cardiovascular-renal loop moves.** Stop. The thyroid arm reaches
  PaCO2 and oxygen consumption and has no path to sodium or pressure.

## 5. THE FALSIFIABLE TESTS

1. **Resting PaCO2 before and after, quoted**, and the change compared with 1.5e-5.
2. **`th_mod` at rest quoted**, and shown to differ from 1.0 only by the FT4 offset.
3. **Ventilation and urine volume identical.**
4. **The hyperthyroid chain still asserted** — FT4 up, TSH down, `th_mod` > 1, PaCO2 up,
   mixed venous saturation down.
5. **ADR 0019 decision 4 is amended, not silently contradicted**, and §8.3's safety
   argument is restated with what now carries it instead.
6. **No ledger value changes.**

## 6. WHAT WOULD MAKE THIS PASS A FAILURE

**Flipping the default and leaving ADR 0019 decision 4 reading "off by default".** Two
copies of a fact, drifting apart, in the record that exists to prevent exactly that.

**Loosening the `== 1.0` test without saying the premise changed.** It would read as a
tolerance being relaxed rather than a decision being reversed.

**Treating §8.3's relaxation as though it still holds unchanged.** It was written leaning on
the default. What now carries the safety is that the gain multiplies a deviation which is
zero at euthyroid — a **different** argument, and it has to be written down as one.
