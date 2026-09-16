# Pre-registration — red cell mass as a state

**Written 2026-09-16, before any source is opened and before any search has been run for
these values.** Verify the ordering with

    git log --diff-filter=A -- validation/erythropoiesis_prereg.md
    git log --diff-filter=A -- validation/erythropoiesis_extract.py

Opened at the owner's instruction as `OPEN-QUESTIONS` **C5**, recorded 2026-09-10 after
the haemorrhage perturbation exposed it.

---

## 0. THE DEFECT THIS EXISTS TO FIX, AND IT WAS MEASURED

`V_blood = f_pv·V_ecf + Hct·BV0`. **The red cell term is a constant**, so a bleed removes
red cells permanently and nothing restores them. Blood volume is what sets cardiac output
and therefore pressure, so the loop must restore it, and the only route left is plasma —
which is 21% of extracellular fluid. Replacing 0.453 L of red cells therefore costs
**2.15 L of extracellular expansion**. Predicted 16.71 L against a starting 14.56;
observed 16.65. **The model settles permanently haemodiluted and volume-expanded, with
renin at 0.37 against a pre-bleed 1.25.**

Every step of that is correct. What is missing is the mechanism that unwinds it.

---

## 1. THE QUANTITIES

| id | what | role |
|---|---|---|
| `RBC.LIFESPAN` | mean red cell survival | sets the destruction term and the slowest state in the model |
| `RBC.PRODUCTION_GAIN` | fractional rise in red cell production per fractional fall in the sensed oxygen signal | **the loop gain, and the number this pass turns on** |
| `RBC.MCHC` | mean corpuscular haemoglobin concentration | makes haemoglobin follow the red cell mass |
| `RBC.MATURATION_TAU` | delay from stimulus to circulating cells | entered **only if** §5 needs it |

**`CV.HEMATOCRIT.NOMINAL` AND `BLOOD.HB_CONCENTRATION` ARE BOTH TARGETS AND MAY NOT BE
USED TO SET THE LOOP GAIN.** They are what the resting state is judged against. Setting
the gain from them would be §3.15's error committed deliberately.

---

## 2. WHAT THIS PASS IS ALLOWED TO CHANGE, AND THE ONE IT IS NOT

**Red cell volume becomes a state and haematocrit becomes a variable.** Today `Hct` is a
parameter used in two different roles and only one of them may move:

- as the **reference** in `f_pv = BV0(1−Hct₀)/V_ecf₀` — **stays a parameter**, because it
  defines the operating point the whole ledger is stated at;
- as the **live** red cell fraction of blood volume — **becomes** `V_rbc/V_blood`.

**Conflating those two would move every derived cardiovascular row**, and §3.8 records
what happens when haematocrit's role is confused: red cell volume expanded with plasma
for weeks before anyone noticed.

**THE OPERATING POINT MAY NOT MOVE.** At the reference state the loop must give
`V_rbc = Hct₀·BV0` **exactly**, so production equals destruction there by construction
rather than by tuning. Every pinned number stays. This is the neutrality ADR 0012 stage 1
and ADR 0021's split both guaranteed rather than checked, and it is checkable here the
same way.

---

## 3. THE ELEGANT PART, AND IT IS ALSO A STOP CONDITION

If red cell mass is a state, **haemoglobin can stop being an independent parameter** and
become `MCHC × Hct`. That is attractive because §3.24 already records the model's implied
MCHC as **33.8 g/dL (male) and 33.4 (female), both inside a normal 32–36, and notes it
could have failed**. Deriving haemoglobin would turn that agreement from a coincidence
into a structural identity, and remove a redundancy: haematocrit and haemoglobin come
from **the same cohort and stratum** already.

**THE STOP CONDITION: is MCHC constant enough to carry that?** In health it is tightly
regulated, which is why it is a diagnostic index at all. If the literature says it varies
materially across healthy adults — or across the haematocrit range this model will
traverse after a bleed — then **haemoglobin stays an independent row** and the identity
is recorded as an observation rather than built. Deciding this before looking is the
point; deciding it afterwards would be choosing whichever made the resting state land.

---

## 4. THE SENSED SIGNAL, AND WHY IT WILL NOT BE ERYTHROPOIETIN

Erythropoietin is released by renal interstitial cells in response to **renal tissue
oxygenation**, which is set by renal oxygen delivery against renal oxygen consumption —
and consumption tracks tubular sodium reabsorption. **This model has none of that**: no
renal blood flow, no renal oxygen consumption, no filtration fraction.

**So the sensed signal is arterial oxygen CONTENT**, which the model computes and which
falls in exactly the two states that raise erythropoietin — anaemia and hypoxia.

**That is a phenomenological reduction and it is declared as one**, on the ADR 0010
precedent: that record is named after atrial natriuretic peptide, keyed to blood volume,
and carries no peptide state, because the input link could not be sourced. The same
applies here. **An explicit erythropoietin state is built only under branch E4**, if and
only if both arms source independently.

**What this forecloses, stated now:** the model will not be able to represent anaemia of
renal disease, where the kidney fails to make erythropoietin at a normal oxygen content.
That is the paradigm case this reduction excludes, and it must be written on the row.

---

## 5. THE FORM

    D(V_rbc) = production − V_rbc / lifespan

with production a function of the sensed oxygen signal, **normalised so that at the
reference state production = Hct₀·BV0 / lifespan exactly.**

**Destruction is first-order and that is a simplification with a name.** Real red cells
die at a fixed AGE, not a fixed rate — survival is near-rectangular, not exponential. A
first-order term makes the mean survival right and the distribution wrong, which matters
for a cohort-labelling experiment and does not matter for a volume balance. **Declared,
not hidden**, and the alternative is a delay or an age-structured population that would
cost far more than it buys.

**Maturation delay is NOT built by default.** Stimulus to circulating reticulocyte is
days against a lifespan of months; adding a lag whose time constant is identified by
nothing is the debt `RN.ANP.TAU` already carries and states on its own row.

---

## 6. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED IN ADVANCE

Red cell lifespan **120 days**. MCHC **33 g/dL**. Haematocrit **45%** — already caught
once in this repository as the male value applied to women. Normal haemoglobin **15 g/dL**.
Reticulocyte count **1%**. **All are teaching figures**, and this repository's record on
them is four materially wrong of six openable in the `VERIFY` class. **120 days in
particular is exactly the shape directive 1.12 warns about** and must be sourced from a
labelling study, not quoted.

---

## 7. THE DECISION RULE

- **E1 — lifespan and a loop gain both source.** Build it: one state, haematocrit
  variable, haemoglobin derived if §3 permits. Write ADR 0023.
- **E2 — lifespan sources, the loop gain does not.** **Build nothing.** A balance whose
  destruction is sourced and whose production is invented is a balance in which the
  production term does all the work — branch A4 of the acid–base pre-registration, and
  the reason that component has no state. Record and stop.
- **E3 — the gain is only obtainable from altitude polycythaemia.** Admissible in
  principle, because chronic hypoxia is the one setting where the closed loop is traced
  rather than perturbed once. But the model is **sea level in three places** (§7), so the
  extraction must take the **dimensionless** relation between steady-state red cell mass
  and arterial oxygen content — the scale-invariant move §3.26 established — and never an
  altitude-specific number.
- **E4 — erythropoietin sources on both arms.** Only then build it explicitly, as a
  second state.
- **E5 — MCHC is not constant enough.** Haemoglobin stays independent, the identity is
  recorded, and the rest of the build proceeds.

---

## 8. WHAT THIS PASS MAY NOT DO

- **It may not use `CV.HEMATOCRIT.NOMINAL` or `BLOOD.HB_CONCENTRATION` to set the loop
  gain.** They are the targets.
- **It may not move the operating point.** §2.
- It may not change `CV.BLOOD_VOLUME.NOMINAL`, `CV.PLASMA.ECF_FRACTION` or `f_pv`'s
  reference haematocrit.
- It may not add a second state except under E4.
- It may not tune the gain to make the haemorrhage recovery look right. **The recovery is
  the falsifiable test** (§9) and spending it is §3.15's error.
- It may not claim the model can represent renal anaemia. §4.

---

## 9. THE FALSIFIABLE TESTS ADR 0023 MUST INHERIT

1. **The operating point is unchanged.** Every pinned number, to five significant
   figures. Production equals destruction at reference by construction.
2. **Haemorrhage recovery unwinds.** After a 1 L bleed the extracellular volume returns
   toward 14.56 L as red cell mass regenerates, rather than settling at 16.65 L for ever.
   **This currently fails and is the reason the pass exists.**
3. **Haematocrit falls acutely and recovers slowly.** Effective haematocrit 0.453 → 0.373
   immediately after the bleed — already measured — then back over months, not days.
   The two timescales must be visibly different.
4. **Anaemia raises red cell production**, and arterial saturation still does not move —
   §3.27's distinction between content and tension must survive the loop closing.
5. **THE COUPLING COUNT RISES 21 → 22 AND THE NEW EDGE IS OUTBOUND FROM BLOOD.** ADR 0018
   made blood a forward computation deliberately and recorded that an outbound edge means
   an oxygen feedback has been built and needs its own record. **This is that edge**, and
   the count is the tripwire ADR 0018 left for exactly this moment.

---

## 10. WHAT WOULD MAKE THIS PASS A FAILURE

**Building a loop whose gain was chosen to make the haemorrhage recovery look right.**
Test 2 would pass by construction, test 1 would pass because the operating point is
neutral by design, and the suite would be green — while the single number that determines
how tightly this model regulates red cell mass would be a fit to a curve nobody measured.

**The second failure is quieter: making the model slower for nothing.** Red cells at a
months-long lifespan become the slowest state here by an order of magnitude over
thyroxine. If the loop gain cannot be sourced, that cost buys a state that only decays —
and E2 says do not build it.
