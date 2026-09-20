# Pre-registration — the macula densa signal does not vary with dietary salt

**Written 2026-09-20, before any value is changed.** Verify with

    git log --diff-filter=A -- validation/md_salt_independence_prereg.md

---

## 0. THE SOURCE, AND IT CONTRADICTS WHAT THIS MODEL USES THE ARM FOR

**Vallon V, Huang DY, Deng A, Richter K, Blantz RC, Thomson S.** *Salt-sensitivity of
proximal reabsorption alters macula densa salt and explains the paradoxical effect of
dietary salt on glomerular filtration rate in diabetes mellitus.* J Am Soc Nephrol
2002;13(7):1865-71. **PMID 12089382.**

Micropuncture in rats after one week of different NaCl diets; single-nephron GFR and
**early distal tubular Na+, Cl- and K+ concentration — the paper's words: "representing the
TGF signal"** — collected from early distal nephrons.

> **"In nondiabetics, dietary salt did not affect SNGFR or the TGF signal."**
>
> **"normal rats acclimate to dietary NaCl by primarily adjusting transport DOWNSTREAM of
> the macula densa."**

**THE MACULA DENSA SIGNAL IS SALT-INDEPENDENT IN THE NORMAL ANIMAL.** The diabetic arm is
the paper's subject and is not this model's case.

## 0.1 WHICH MEANS THE MODEL'S SMALL SIGNAL IS RIGHT AND ITS LARGE GAIN IS WRONG

§3.64 measured `md_drive` spanning **5.7%** across 38 → 230 mEq/day and read it as a defect
to be fixed by building a macula densa concentration. **Vallon says a near-constant signal
is the correct behaviour.**

What is not correct is `RN.MD.RENIN_GAIN` = **4.99**, `calibrated` to turn that
near-constant signal into the **entire** chronic salt-renin response — HANDOVER §7 records
the pressure-only ceiling at 1.40 against van den Bosch's measured 2.73, and ADR 0021 built
this arm to lift it.

**So this model reproduces the human salt-renin ratio through an arm the primary literature
says does not respond to dietary salt.**

---

## 1. WHAT THIS PASS DOES

**It runs the experiment and reports it. It does not repair the renin response.**

Sweep `RN.MD.RENIN_GAIN` down from 4.99 and report, at each value: the chronic renin ratio
against van den Bosch's 2.73, the chronic salt sensitivity against 1.70-2.30, the resting
state, Jensen, and the acute ordering ratio.

**THE POINT IS TO MEASURE WHAT THE ARM IS ACTUALLY CARRYING** and therefore what the other
arms would have to carry instead.

## 2. WHAT MAY NOT MOVE

- **No parameter is adopted in this pass**, including `RN.MD.RENIN_GAIN` itself. A sweep is
  a diagnostic; adopting its result is a separate pass.
- **No band, pin or tolerance.**
- **The renal sympathetic arm stays exactly as ADR 0024 left it.** Re-tuning it to absorb
  what the macula densa arm gives up, inside the pass that takes it away, is failure mode
  #22 with both hands.

---

## 3. THE DECISION RULE

- **V1 — lowering `g_md` costs the renin ratio and nothing else recovers it.** Then the
  model's agreement with van den Bosch rests on an arm the literature says is
  salt-independent. **Report it as a structural finding and change nothing.** Expected.
- **V2 — another built arm recovers the ratio.** Report which and how much; adopting is a
  separate pass.
- **V3 — the ratio is insensitive to `g_md`.** Then ADR 0021's ceiling argument was wrong
  and that is the finding.
- **V4 — the resting state or an acute endpoint moves.** Report; the sweep is diagnostic.

---

## 4. THE FALSIFIABLE TESTS

1. **The sweep is reported in full**, including values that fail.
2. **The pressure-only ceiling is re-measured at `g_md` = 0** and compared with HANDOVER
   §7's recorded 1.40, now that the renal sympathetic arm exists.
3. **No ledger value changes.** Mechanically checkable.
4. **Vallon's normal-animal result is quoted, and the diabetic arm is excluded explicitly**
   so nobody later reads the paper as supporting the opposite.
5. **§3.64's conclusion is corrected on the record** — it said the small signal was the
   defect, and it is not.

---

## 5. WHAT WOULD MAKE THIS PASS A FAILURE

**Quietly lowering `g_md` and letting the renin ratio fail without saying the model no
longer reproduces van den Bosch.** That ratio has been quoted as a success of ADR 0021.

**Re-tuning the sympathetic arm to cover the gap in the same pass.**

**Reading Vallon's DIABETIC arm as the normal case.** It is the paper's headline and it is
the opposite result; the normal arm is the one that applies here.

**Treating this as a refutation of the macula densa arm's EXISTENCE.** Lorenz 1990 measured
the gain directly and it is real. What is in question is whether it carries the response to
DIETARY SALT, which is a different claim.
