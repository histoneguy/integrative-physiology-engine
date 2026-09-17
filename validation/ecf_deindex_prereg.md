# Pre-registration — the de-indexing correction owed to `ecf_salt_response_extract.py`

**Written 2026-09-16, before any file is changed and before the corrected value is
propagated anywhere.** Verify the ordering with

    git log --diff-filter=A -- validation/ecf_deindex_prereg.md
    git log --diff-filter=A -- validation/ecf_deindex_extract.py

Opened at the owner's instruction as `HANDOVER` §4 item 6.

---

## 0. THE ITEM IS RIGHT, AND IT IS THE FIRST ONE THIS WEEK THAT WAS

Item 6: *"It multiplies an indexed ECF difference by ONE body surface area where each arm
has its own, understating the expansion by 9%."*

`validation/ecf_salt_response_extract.py` line 276:

    d_ecfv = (b["ecfv_high"] - b["ecfv_low"]) * b["bsa"] / 1.73

**van den Bosch reports BSA SEPARATELY FOR EACH ARM** — 2.04 ± 0.15 on high sodium and
2.03 ± 0.15 on low — because body weight differs between arms (80.6 vs 79.2 kg). The
indexed values therefore do **not** share a denominator, and the difference of two
indexed numbers cannot be de-indexed by one of them.

    as coded   (17.4 - 16.5) x 2.04 / 1.73                 = 1.0613 L
    correct    (17.4 x 2.04 - 16.5 x 2.03) / 1.73          = 1.1566 L
    understatement                                            9.0%

**VERIFIED AGAINST THE PAPER, NOT INFERRED.** Source read for this purpose:
van den Bosch JJON et al. *Plasma sodium, extracellular fluid volume, and blood pressure
in healthy men.* Physiol Rep 2021;9(24):e15103. PMID 34921521, PMC8683787, **open access,
read for the Methods and Table 1**. Methods: *"ECFV was indexed to 1.73 × BSA"*, BSA by
Du Bois. **The paper does not state whether BSA was recomputed per arm — it does not have
to, because it PRINTS both.**

**MY OWN FIRST ESTIMATE WAS 14% AND IT WAS WRONG.** I derived the low-arm BSA from Du Bois
at the arm weights and got 2.025 where the paper prints 2.03. At a 0.5% between-arm
difference the second decimal place decides the answer, so this could not be done by
arithmetic and had to be read. **Three work-list items have been checked this week and
items 8, 9 and 10 were all stale or wrong; this one is exactly right.** Being right about
the list being wrong is not a reason to stop checking the list.

---

## 1. THE NUMBER IS 9%. THE REASON FOR A PRE-REGISTRATION IS WHERE IT GOES

`d_ecfv` is not a leaf. It is **one of the two independent limbs of the human volume
response**, and that pair sets the band this model's stiffness is judged against.

| | now | after |
|---|---|---|
| tracer limb (van den Bosch, iothalamate) | **0.553** L/100 mmol | **0.602** |
| body-weight limb (four groups, n = 132) | 0.572 kg/100 mmol | 0.572, untouched |
| the two limbs | tracer **below**, agree to 3.4% | tracer **above**, agree to 5.3% |
| pooled volume range | 0.553–0.572 | **0.572–0.602** |
| human `dMAP/dV_ecf` band | **2.97–4.16** mmHg/L | **≈2.82–4.02** |
| within-subject figure | 1.885 mmHg/L | **1.729** |

**THE ORDERING OF THE TWO LIMBS FLIPS**, and `ecf_salt_response_extract.py`'s own headline
is *"Two independent methods agree to 4%."* That claim survives in substance and changes
in detail, and ADR 0013 leans on it in three separate tables.

**AND A HARD ASSERT WILL FIRE.** Line 394: `assert abs(round(ecf100, 3) - 0.553) < 1e-9`.
Good — it is doing its job.

---

## 2. THE DIRECTION IS FIXED NOW, BEFORE ANYTHING IS RUN

**The corrected human ECF expansion is LARGER, so the human `dMAP/dV_ecf` is SMALLER, so
THE MODEL IS MORE TOO-STIFF THAN THE REPOSITORY RECORDS — NOT LESS.**

§3.7 and ADR 0013 record the model as 1.5–2.1× above the human band. This correction
widens that gap. **A result in which the model comes out looking better is a red flag and
must be treated as an error in the propagation**, not as a finding. Written down here so
it cannot be decided after the numbers appear.

---

## 3. WHAT THIS PASS MAY NOT DO

- **It may not re-derive `CV.VENOUS_RETURN.SENSITIVITY`.** `G_vr` is §4 item 1's own work
  and ADR 0013 sets its target FROM the band this pass moves. Re-deriving it here would
  be fitting a parameter to a target the same pass just shifted — §5 item 22 in its
  purest form. **The band moves; `G_vr` does not.**
- **It may not touch `RN.PRESSURE_NATRIURESIS.SLOPE`.** It is the last `calibrated` row,
  it cites these numbers in its own note, and its label is §4 item 5's separate decision.
- **It may not touch `CV.ANP.NATRIURETIC_GAIN`**, which §3.40 measured carrying 45% of
  the model's salt-sensitivity sensitivity.
- **It may not touch the body-weight limb.** It is the independent check and its value is
  what makes the tracer limb's correction meaningful.
- **It may not touch the meta-analytic pressure range 1.70–2.30**, which is the numerator
  of the band and comes from different studies entirely.
- **It may not re-pin the model's own test to the new band without stating whether the
  model got better or worse.** §7.

---

## 4. DIRECTIVE 1.12 — AND ONE OF THEM IS A CLAIM RATHER THAN A NUMBER

**1.73 m²** — the 1928 indexing convention, already distrusted on `BF.BSA.REFERENCE`.
**"Two independent methods agree to 4%"** is not a round number but it is the same
hazard: a headline that is quoted more often than it is recomputed, and this pass changes
it. **It must be recomputed and restated, not adjusted.**

---

## 5. WHAT IS ALREADY KNOWN, DECLARED SO THE FREEDOM IS AUDITABLE

- The four arithmetic results in §0 and the six propagated values in §1.
- **Ten files carry at least one of the affected numbers**: `ecf_salt_response_extract.py`,
  `bench/uncertainty_sweep.jl`, `bench/gain_uncertainty_sweep.jl`, ADRs 0013, 0015 and
  0016, `HANDOVER.md`, `OPEN-QUESTIONS.md`, `src/assemble.jl`, and two ledger notes
  (`RN.PRESSURE_NATRIURESIS.SLOPE`, `CV.VENOUS_RETURN.SENSITIVITY`).
- The model's own ratio is **3.2185** mmHg/L as of 2026-09-16 (§3.43), inside both the
  old band and the projected new one.

---

## 6. THE DECISION RULE

- **E1 — the correction is 9% and the two limbs still agree within 10%.** Apply it,
  recompute the band from its parts, and report the flipped ordering explicitly.
- **E2 — the limbs diverge by more than 10%.** Then *"two independent methods agree"* is
  no longer a claim ADR 0013 can make, and that record needs an **amendment** rather than
  a number substitution. Stop and write it.
- **E3 — the model's ratio falls outside the corrected band.** **Report it. Do not refit
  `G_vr`.** The model being outside a corrected human band is the finding, not a defect
  to be tuned away, and ADR 0013's own text predicts the error lives in `G_vr`.
- **E4 — van den Bosch reports BSA to more precision elsewhere than the two decimals in
  Table 1.** Use it, and say how much the third decimal moves the 9%.
- **E5 — a consumer is found that changes a MODEL RESULT rather than a document.** Stop
  and re-scope. This pass is a correction to an extraction and its records; it is not
  licensed to move the model.

---

## 7. THE FALSIFIABLE TESTS

1. **The de-indexing uses the per-arm BSA**, and the extract asserts the corrected value
   the way it asserted the old one. A pass that removes the assert instead of updating it
   has hidden the thing the assert existed to catch.
2. **The two limbs still agree within 10%, and the extract states WHICH IS HIGHER.** The
   ordering is the part that flips and the part a reader will otherwise carry stale.
3. **The band is recomputed from its numerator and denominator, not restated.** Any file
   quoting 2.97–4.16 either recomputes it or points at the file that does.
4. **No ledger value moves.** `git diff` on `ledger/parameters.csv` shows note text only.
5. **The model's ratio is reported against the corrected band with an explicit
   better-or-worse**, and §2 says in advance which it must be.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Fixing the extract and leaving the other nine files carrying the old numbers.** That is
the "written down twice" family, which has bitten **three times this week** — the salt
pin in three assertions (§3.43), the 6.9% excursion claim left standing in prose after
§3.43 reversed it, and `check_closure.py` certifying a chain the model no longer ran
(§3.42). Ten files is the widest blast radius yet.

**Refitting `G_vr` to the moved band.** The pass would then have corrected a human number
and re-tuned the model onto it in one step, and nobody could tell which had moved.

**The quiet one: applying the correction and reporting only that the suite is green.**
The model gets 9% *worse* against the human band here. If the write-up does not say so in
those words, the correction has been used to launder a regression.
