# Pre-registration — body composition

**Written 2026-10-20, after reading one review for structure and BEFORE any number is
extracted.** No DXA file has been downloaded.

    git log --diff-filter=A -- validation/body_composition_prereg.md

Seventh pass under directive 1.16. `OPEN-QUESTIONS` **B28**, and the substrate HANDOVER §4
names as unblocking metabolism, energy balance, thermoregulation and urea at once.

---

## 0. THE REVIEW, AND WHAT IT ESTABLISHED — DIRECTIVE 1.16

**Wang ZM, Pierson RN Jr, Heymsfield SB.** *The five-level model: a new approach to
organizing body-composition research.* Am J Clin Nutr 1992;56(1):19–28. **PMID 1609756**,
doi 10.1093/ajcn/56.1.19. Abstract read 2026-10-20.

**IT SETTLES THE ONE QUESTION THAT MATTERS BEFORE ANY NUMBER IS CHOSEN: WHICH LEVEL ARE WE
MODELLING?** The field divides body composition into **five levels** of increasing
complexity — **I atomic, II molecular, III cellular, IV tissue-system, V whole body** — and
the review's point is that compartments at *different* levels are connected but **not
interchangeable**.

**THIS MODEL CURRENTLY HAS LEVEL V AND NOTHING ELSE.** `BF.BODY_MASS.*` is whole-body mass,
and every extensive quantity in `src/scaling.jl` scales off it.

**WHAT THIS PASS BUILDS, AND THE LEVELS ARE NAMED SO THEY CANNOT BE CONFLATED:**

- **Level II, molecular: fat mass and fat-free mass.** The two-compartment partition, which
  is what DXA measures and what the body-water fractions actually belong to.
- **Level IV, tissue-system: skeletal muscle mass.** A *different level*, measured by a
  different method (MRI), and **not** derivable from DXA lean mass without an assumption.

**THE REVIEW IS WHY THOSE ARE TWO ROWS AND NOT ONE.** DXA "lean mass" is a **molecular-level**
quantity (fat-free soft tissue); skeletal muscle is a **tissue-system** organ. Treating DXA
lean mass as muscle is the standard conflation, it is wrong by roughly a factor of two
because lean mass includes viscera, skin and body water, and **a model that made that
substitution would be unable to say so.** Recorded before extraction.

**WHAT THE REVIEW DOES NOT GIVE: any number.** Directive 1.16, and §2 lists the round
numbers it would be tempting to take.

---

## 1. WHAT IT IS FOR, AND WHAT IT WILL AND WILL NOT LET THE MODEL DO

**WILL:** carry adiposity as a state of the individual rather than an unrepresented
confound, so that two people of the same **mass** but different **composition** are
different in the model.

**WILL NOT, in this pass:** free fatty acids, lipolysis, glucagon, or energy balance. **B28
names FFA as mechanistically upstream of the hepatic defect ADR 0035 built**, and that is the
next pass, not this one. Building a substrate and a mechanism together makes neither testable
alone — the discipline ADRs 0025/0026 and 0034/0035 were separated under.

**WILL NOT: re-scale organ masses.** Liver mass is a **level IV** compartment this pass does
not source, so `GLU.EGP.BASAL` keeps its mg/kg **body** mass normalisation. It is wrong in
principle — hepatic glucose output is a property of the liver — and **it is recorded as a
known defect rather than fixed by an unsourced liver fraction.**

---

## 2. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED BEFORE EXTRACTION

- **"Men are 15% fat, women 25%."** The teaching pair.
- **"Fat-free mass is 73% water."** The hydration constant, which is a *derived* molecular
  identity and will be checked, not assumed.
- **"Skeletal muscle is 40% of body mass."**
- **"The reference man is 70 kg."** Already in this ledger as `BF.BODY_MASS.TYPICAL`, and
  **already measured from NHANES rather than taken from Reference Man** — so the precedent
  for refusing this one is set.
- **ICRP Publication 89 reference values generally.** They are *consensus reference values*,
  not a measured cohort, and `pooling.md` forbids treating a reference standard as a source.

---

## 3. ADMISSIBILITY AND POOLING, FIXED BEFORE EXTRACTION

**Fat / fat-free (level II): NHANES DXA, extracted here**, by the method this repository
already uses for body mass, fasting glucose and insulin — survey-weighted, adults ≥ 20 y,
pregnancy excluded. **Extraction, not transcription**, so `extraction_method = reported` with
the file and variables named.

**WHY NOT KELLY 2009** (PMID 19753111, PLoS One, open access, read): it is the canonical
reference-value paper for exactly this dataset, **and its values are age-normalised curves in
figures.** `nimgu_form_prereg.md` branch N3 and `glucose_splay_prereg.md` branch S3 both fixed
the rule that **figures are not digitised here.** Extracting the underlying NHANES file is
strictly better than reading his plot.

**Skeletal muscle (level IV): Janssen 2000**, PMID 10904038, J Appl Physiol — whole-body MRI,
n = 468, sexed. **MRI is the reference method for this level**, and directive 1.7 applies: the
relationship is the paper's subject.

**POOLING:** `pooling.md`. NHANES is a single weighted survey and is entered as such.
**Janssen is `single-source` and will say so**; if a second whole-body MRI series in healthy
adults is found it pools, and **cross-method pooling of DXA lean mass with MRI muscle is
PROHIBITED** — §0's reason, different levels.

**DISPERSION:** `uncertainty_type = sd`, **population** spread, sexed. NHANES gives it
directly from the weighted distribution.

**A SELECTION EFFECT TO RECORD, NOT DISCOVER LATER:** NHANES DXA excludes pregnancy and
excludes participants above a weight and height limit, so the **upper** tail of adiposity is
truncated. The mean is affected little; **the SD is biased low**, and the row must say so.

---

## 4. THE FORM, AND THE ARITHMETIC COMES BEFORE THE SECTION ADOPTING IT

**Two identities, no free parameter:**

    fat_mass  = f_fat * body_mass
    ffm       = (1 - f_fat) * body_mass

**THE ONE REAL DECISION IS WHAT THE BODY-WATER FRACTIONS ARE A FRACTION *OF*.** `BF.ECF.MASS_FRACTION`
is currently **0.208 of body mass**, which silently assumes a fixed adiposity — **so in this
model adding 10 kg of fat adds 2.1 L of extracellular fluid.** Adipose tissue is roughly
10–20% water against ~73% for lean tissue, so that is wrong in a way adiposity makes visible.

**CANDIDATE: re-express the water compartments on fat-free mass.** It is neutral at the
reference individual by construction — `f_ecf_ffm = 0.208 / (1 − f_fat)` — and changes the
**population sweep**, which varies body mass.

**IT IS NOT ADOPTED IN THIS PASS AND THE REASON IS STATED NOW.** `V_ecf` feeds blood volume,
which feeds cardiac output, which feeds arterial pressure — **the entire closed loop** — and
the population invariance of MAP across the mass range is an asserted result (HANDOVER §2).
Re-anchoring it is a **separate structural change with its own falsifiable test**, and
stacking it onto the pass that introduces the compartments would make neither testable alone.
**§7 test 4 reports what it *would* do, computed and not built.**

**SO THIS PASS ADDS COMPARTMENTS AND WIRES EXACTLY ONE THING** — §5.

---

## 5. WHAT GETS WIRED, BECAUSE AN UNREAD ROW IS A GATE FAILURE

`check_relations.py` fails an **UNREAD ROW** — directive 1.11 — as it did when the glucose
splay value was entered with nothing to read it. **So the compartments must do work in this
pass or they do not land.**

**WIRED: the fat-free mass fraction becomes the scaling basis for SKELETAL MUSCLE, and
skeletal muscle mass becomes an exported observable.** That is the minimum honest wiring: it
makes the two levels explicit, it is checked by §7 test 2 against Janssen's own absolute
masses, and it reads both new rows.

**NOT WIRED, AND SAID PLAINLY: nothing downstream consumes muscle mass yet.** Insulin-mediated
glucose uptake is where it belongs — Baron measured it in **leg muscle** — and that is the
pass after FFA. **This pass is a substrate, and a substrate that pretends to be a mechanism
is worse than one that admits it is not.**

---

## 6. WHAT MAY NOT MOVE

- **`BF.BODY_MASS.*`**, `BF.ECF.MASS_FRACTION`, `BF.ICF.MASS_FRACTION`, `BF.TBW.MASS_FRACTION`
  and every cardiovascular row. §4 is why.
- **The healthy operating point and every challenge**, which follows from §5 wiring nothing
  into the loop.
- **`GLU.EGP.BASAL`'s per-body-mass normalisation** — §1, recorded as a defect, not fixed.
- **No band, pin or tolerance widened.**

---

## 7. THE FALSIFIABLE TESTS

1. **The operating point and all challenges are bit-identical**, which §5 makes structural
   rather than hoped for.
2. **Janssen's absolute masses are reproduced**: at the sexed reference body mass, the model's
   skeletal muscle mass must come out at **Janssen's own kg**, not merely at his percentage.
   A percentage that does not reproduce the mass means the reference body mass and his cohort
   disagree, **and that is a finding about cohort mismatch** — the B31 failure in a new place.
3. **DXA lean mass EXCEEDS skeletal muscle mass, substantially.** §0's conflation check, run
   as arithmetic: if the model's fat-free mass is not well above its muscle mass, the two
   levels have been confused.
4. **REPORTED, NOT BUILT: what re-anchoring the water compartments on fat-free mass would do**
   — `f_ecf_ffm` at the reference individual, and `V_ecf` at the P05 and P95 body masses under
   both anchorings. **This is the number that decides whether §4's deferred change matters.**
5. **The hydration check, as a check and not an input:** fat-free mass times the 0.73 teaching
   constant against the model's total body water. **A disagreement is a result about §2's
   round number**, and neither value is adjusted to the other.
6. **Full suite and all six gates.**

---

## 8. THE DECISION RULE

- **C1 — DXA extracts cleanly and Janssen reproduces.** Enter both levels; ADR.
- **C2 — DXA extracts but Janssen's percentage does not reproduce his masses at this model's
  reference body mass.** Enter the DXA rows, enter Janssen as a **percentage with the cohort
  mismatch recorded**, and open it as a question. **Do not rescale his number to fit.**
- **C3 — the DXA file is unavailable or the variables have changed.** Record INDETERMINATE
  with the variable names tried. **Do not fall back to Kelly's figures or to ICRP 89.**
- **C4 — test 3 fails.** Then the two levels have been conflated somewhere and **the pass is
  withdrawn**, not patched.

---

## 9. WHAT WOULD MAKE THIS PASS A FAILURE

**Taking a fat fraction from ICRP 89 or from the teaching pair.** §2, §3.

**Treating DXA lean mass as skeletal muscle.** §0. It is the single most likely error here and
test 3 exists for it alone.

**Re-anchoring the water compartments in this pass.** §4. Test 4 reports it; building it is a
separate pass with its own pre-registration.

**Entering fat mass with nothing reading it**, then arguing the gate is wrong. §5.

**Reporting "the operating point did not move" as evidence the compartments are right.** It
follows from wiring nothing into the loop and is a property of §5, not a result.
