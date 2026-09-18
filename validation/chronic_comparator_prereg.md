# Pre-registration — the chronic comparator, and whether the model is being judged against the right estimand

**Written 2026-09-17, before van den Bosch is re-opened for its dispersion and before any
comparator is changed.** Verify the ordering with

    git log --diff-filter=A -- validation/chronic_comparator_prereg.md
    git log --diff-filter=A -- validation/chronic_comparator_extract.py

Opened at the owner's instruction following HANDOVER §3.52.

---

## 0. THE QUESTION

§3.52 measured that **all three acute human endpoints are satisfiable together** — Drummer's
volume 7 h and sodium 10 h, and Jensen's +122% — at a natriuretic gain of ×1.5 to ×2.0.
**The chronic salt sensitivity alone dissents**, and wants ×1.0: at ×1.5 it is 1.32, at ×2.0
it is 1.01, against a window of **1.70–2.30**.

**Either the model's chronic limb is twice too sensitive, or it is being compared with the
wrong quantity.** This pass decides which, and **may not change the model either way.**

---

## 1. WHAT IS ALREADY IN THIS REPOSITORY AND HAS NEVER BEEN USED AS A TARGET

`validation/ecf_salt_response_extract.py` holds van den Bosch's own blood pressures:

    map_high = 88.0, map_low = 86.0     # mmHg
    na_high  = 230.0, na_low = 38.0     # mmol/24 h, MEASURED excretion

**2.0 mmHg over 192 mmol/day = 1.042 mmHg per 100 mmol/day.** The file **computes and
prints exactly that** — `map100` — and then uses the **meta-analytic** 1.70/1.96/2.30 for
every comparison it makes.

| | |
|---|---|
| the window the model is judged against | **1.70–2.30** (spread of three meta-analytic point estimates) |
| van den Bosch, within-subject, n = 70 healthy normotensive men, crossover, intake verified by 24 h urine | **1.042** |
| the model at §3.52's acute-satisfying gain | **1.01** |

**The last two are the same number to the precision either supports.**

**AND THIS REPOSITORY'S OWN EARLIER PRE-REGISTRATION GAVE VAN DEN BOSCH PRECEDENCE.** The
extract records: *"TEST B IS NOT INCONCLUSIVE, because it is taken WITHIN one study whose
own pressure, ECF and body-weight numbers agree with each other, and the pre-registration
gives it precedence for exactly that reason."* **It was given precedence for the RATIO and
not for the PRESSURE**, and `CV.ANP.NATRIURETIC_GAIN` is solved against the meta-analytic
2.00. That inconsistency is inside one file and has stood since 2026-09-03.

## 1.1 AND THAT IS PRECISELY WHY THIS PASS IS DANGEROUS

**Four passes have now failed against 1.70–2.30, and the fifth proposes to find a lower
comparator already sitting in the repository that happens to vindicate the model.** This is
the single most self-serving move available in this project, and **§8 names it first**.

**The pass must be able to conclude that 1.70–2.30 is right and the model is wrong**, and
§6 has a branch for it.

---

## 2. THE COUNTER-ARGUMENT IS ALREADY ON THE RECORD AND IS THE FIRST TEST

The same file says, in its own words:

> *"the mechanistic studies are UNDERPOWERED for a 2 mmHg effect — Foo SD on 24 h SBP is
> 14.2 with n = 18 — so BP did not change is NOT dMAP = 0"*

**DOES THAT CAVEAT APPLY TO VAN DEN BOSCH'S OWN 2.0 mmHg?** It is n = 70 and crossover,
which is far better powered than n = 18, but the question is quantitative and it has never
been asked of this particular number.

**TEST ZERO, AND IT IS PASS/FAIL BEFORE ANYTHING ELSE RUNS:** re-open van den Bosch
(PMID 34921521, PMC8683787, open access, already read twice in this repository) and
establish whether the 88.0 vs 86.0 mmHg difference is **reported with a dispersion and a
p-value, and whether it is distinguishable from zero.**

**IF IT IS NOT, IT CANNOT BE A TARGET AND THIS PASS ENDS THERE**, with the model's
disagreement against 1.70–2.30 standing exactly as §3.52 left it. A number that is
consistent with zero is consistent with 1.042 and with 2.30 alike, and choosing it because
it flatters the model would be the failure this document exists to prevent.

---

## 3. THE ESTIMAND QUESTION, WHICH IS THE REAL ONE

**A meta-analysis of sodium-reduction trials and a within-subject crossover do not estimate
the same thing.**

- The meta-analyses pool **trials**, reporting a **population-mean BP difference between
  arms**, over weeks, in populations that are often **mixed normotensive and hypertensive**,
  with imperfect adherence and regression dilution in the intake measurement.
- The model computes a **within-individual steady-state slope** in **one idealised healthy
  normotensive adult**.
- **Salt sensitivity is strongly heterogeneous between individuals**, so a population mean
  and an individual slope need not agree even when both are correctly measured.

**WHAT MUST BE ESTABLISHED, AND IT IS FIXED HERE:** the population each meta-analytic
estimate is drawn from. **If Cutler 1997, He 2013 and He 2002 are predominantly or
substantially hypertensive, they are not estimating the model's quantity**, and the window
is the wrong comparator for a reason that has nothing to do with whether the model fails it.

**AND VAN DEN BOSCH IS NOT AUTOMATICALLY RIGHT EITHER.** n = 70, **young men only**, **7
days per level**, one centre. Seven days may be short of a chronic steady state, and §3 of
`pooling.md` does not let one cohort displace three meta-analyses merely by being closer in
design.

---

## 4. WHAT MAY NOT MOVE — AND THIS PASS MAY NOT TOUCH THE MODEL AT ALL

- **No parameter of any kind.** `CV.ANP.NATRIURETIC_GAIN`, `RN.PRESSURE_NATRIURESIS.SLOPE`,
  `BF.NA.*`, the store, the gains. **This pass is about the COMPARATOR.**
- **If the comparator changes, `CV.ANP.NATRIURETIC_GAIN` was solved against the old one and
  would need re-solving. THAT IS A SEPARATE PASS WITH ITS OWN PRE-REGISTRATION**, and
  doing it here would be changing a target and refitting to it in one step — §5 item 22 in
  its purest form.
- **The acute results stand as §3.52 left them** and are not re-run.
- **`validation/challenges.jl`'s chronic band may not be widened or moved in this pass**,
  whatever is concluded. Changing a harness band is a separate, visible act.

---

## 5. DIRECTIVE 1.12 — AND THE HAZARD IS A BAND, NOT A NUMBER

**1.70, 1.96, 2.30** are three point estimates whose **min and max are being used as an
interval**. This repository already flagged that: *"taking their min and max as an interval
is range-midpoint's sibling … Only the label is corrected."* **The band was never a
confidence interval and has been treated as one for weeks.**

Round numbers listed: **2.00**, the value `CV.ANP.NATRIURETIC_GAIN` was solved to hit and
the exact centre of a made-up interval. **100 mmol/day.** **2 mmHg.**

---

## 6. THE DECISION RULE

- **C0 — van den Bosch's 2.0 mmHg is not distinguishable from zero.** **Stop.** It cannot be
  a comparator. Report that the model's chronic disagreement stands, and that the repository
  has been printing an unusable number for months.
- **C1 — it is a real effect, and the meta-analyses are predominantly hypertensive.** Then
  they are not the model's estimand. **Report it; propose the comparator change; change
  nothing.** The follow-up pass re-solves and is pre-registered separately.
- **C2 — it is a real effect and the meta-analyses ARE normotensive.** Then two valid
  measurements of the same estimand disagree by a factor of two, which is a finding about
  the **literature** and not about the model. **Report both and pick neither.**
- **C3 — the meta-analyses are mixed, or their populations cannot be established from what
  can be opened.** Record INDETERMINATE with the exact terms. **The window stays.**
- **C4 — van den Bosch turns out to have a dispersion wide enough to contain 1.70–2.30 as
  well.** Then it discriminates nothing and the window stays by default.
- **C5 — something else is found that settles it.** Report it; the same prohibition on
  changing the model applies.

---

## 7. THE FALSIFIABLE TESTS

1. **Test zero is answered first and reported whatever it says** — dispersion and p-value
   for van den Bosch's 88.0 vs 86.0.
2. **The population of each of Cutler 1997, He 2013 and He 2002 is established and
   reported** — normotensive, hypertensive or mixed, with the numbers.
3. **No parameter moves.** `git diff` on `ledger/parameters.csv` shows note text only, or
   nothing.
4. **The model's chronic salt sensitivity is reported unchanged at 1.97**, and the acute
   results are quoted from §3.52 rather than re-run.
5. **If the recommendation is to change the comparator, the write-up states plainly that the
   model FAILS the current one** and that the change is proposed on estimand grounds rather
   than on fit.
6. **The internal inconsistency in `ecf_salt_response_extract.py` is reported** — van den
   Bosch given precedence for the ratio and not for the pressure — whichever way the pass
   goes.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Adopting a lower comparator because the model fails the higher one.** Named first,
named in §1.1, and the reason this document is longer than the question deserves. Four
passes have failed against 1.70–2.30. The fifth finding a number that vindicates the model,
in a file the repository already had, is exactly what a motivated search produces.

**Skipping test zero.** If van den Bosch's 2 mmHg is noise, everything downstream of it is
noise, and the temptation to move past it quickly is proportional to how convenient the
number is.

**Treating the estimand argument as decisive on its own.** It is a reason the two might
differ; it is not evidence that one is right. C2 exists because both can be valid.

**Changing a parameter, a band, or a harness threshold.** §4. This pass produces a
recommendation and a record, and nothing else.

**The quiet one: reporting the comparator question and not §3.52's number.** The model's
chronic salt sensitivity is **1.97** and the acute-satisfying value is **1.01**. Whatever is
concluded about the window, **the model's own two limbs want gains a factor of two apart**,
and that does not go away by changing what it is compared to.
