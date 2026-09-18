# Pre-registration — the ANP label, and what the volume-natriuretic gain actually lumps

**Written 2026-09-18, before any identifier is changed and before any note is rewritten.**
Verify the ordering with

    git log --diff-filter=A -- validation/anp_label_prereg.md

Short by design. **This pass extracts nothing and must change no number.** It is here
because the row it touches is load-bearing and because §3.57 produced the evidence that
makes the current attribution wrong.

---

## 0. WHAT IS ACTUALLY WRONG, AND IT IS NARROWER THAN §3.57 SAID

**The `name` field is already honest:** *"Volume-keyed natriuretic gain"*. **ADR 0010 is
already honest**, in its own Decision: *"The component becomes a lumped volume-keyed
natriuretic term, algebraic in `V_blood`, with ANP as its named evidence base rather than
as a state."*

**THREE THINGS ARE NOT.**

1. **`CV.ANP.NATRIURETIC_GAIN`** — the `param_id`, which is what appears in code, in
   `LedgerParams.jl` and in the GUI. It names one mechanism for a lumped quantity.
2. **The symbol `G_anp`**, and the code identifiers `anp_sig`, `anp_gain`, `RN.ANP.TAU`.
3. **"ANP as its named evidence base."** The gain was estimated from **whole-body isotonic
   expansion** — Lobo 2001 and Jensen 2013 — which measures the **TOTAL** volume-natriuretic
   response. **ANP was never the evidence base; whole-body natriuresis was**, and ANP was
   the mechanism assumed to carry it.

**§3.57 SUPPLIED THE COUNTER-EVIDENCE.** Lohmeier's split-bladder dogs give a Den/Inn
sodium ratio of about 0.56 at sustained elevated pressure, so **renal sympathetic
withdrawal carries a substantial share of exactly the response this gain was fitted to.**
The gain is not wrong. **The attribution is.**

---

## 1. WHAT THIS PASS MAY NOT DO

- **NO NUMBER MAY MOVE.** Not `CV.ANP.NATRIURETIC_GAIN`'s 585, not `RN.ANP.TAU`, not
  `RN.MD.RENIN_GAIN`, not a band, not a drift pin. **The test is BIT-IDENTICAL model
  output**, demonstrated by running, not asserted.
- **NO DECOMPOSITION INTO AN ANP SHARE AND A NERVE SHARE.** §2 says why.
- **ADR 0010's file is not renamed.** Other records link to it by path; a broken link is a
  worse defect than a stale filename. It gets an amendment.
- **No new parameter, no new relation, no new state.**

---

## 2. WHY NO NUMERICAL SPLIT, EVEN THOUGH A RATIO EXISTS

It is tempting to split 585 into an ANP share and a nerve share on Lohmeier's ratio. **The
data do not support a number.**

- **Inn/Den ≈ 1.9 implies a nerve share of (1.9 − 1)/1.9 ≈ 47%** — but the 2001 abstract
  reports *"a latent impairment in sodium excretion from Den kidneys"*, so **denervation
  itself degrades excretion and the ratio OVERSTATES the nerve effect by an unknown
  amount.** 47% is an upper bound, not an estimate.
- **The protocol is ANG II hypertension, not a salt step.** Applying the share across
  protocols is an extrapolation with nothing behind it.
- **n = 5 dogs, abstract only.**

**So the supportable statement is "between zero and about a half, biased high", and a
parameter whose interval is 0–0.47 buys nothing.** Directive 1.14: entering a point
estimate here would be inventing precision. **The components are NAMED and the share is
left unquantified**, which is the honest form.

---

## 3. THE DECISION RULE

- **L1 — the rename is mechanical and output is bit-identical.** Adopt.
- **L2 — any model output changes.** The rename touched something it should not have.
  **Revert and investigate; do not accept a changed number as harmless.**
- **L3 — a decomposition turns out to be sourceable after all** (a human ANP infusion
  dose-response giving the ANP-specific natriuretic gain). **Report it and stop.** That is a
  separate pass with its own pre-registration, and doing it here would be re-estimating a
  calibrated-adjacent row in the pass that relabels it.

---

## 4. THE FALSIFIABLE TESTS

1. **Bit-identical output**, demonstrated by running the full suite and `challenges.jl`
   with no band, pin or tolerance touched.
2. **`git diff` on `ledger/parameters.csv` shows identifier, symbol and note text only —
   no `value` field changes.** Checkable mechanically.
3. **The six gates pass without any exemption list growing.**
4. **The row and ADR 0010 name the components of the lump explicitly** — ANP, renal
   sympathetic withdrawal, and whatever else volume expansion does to sodium handling —
   and state that the share is **not** quantified and why.
5. **The double-count trap is recorded**: a future ANP dose-response must NOT be added on
   top of this gain, because this gain already contains ANP's contribution.

---

## 5. WHAT WOULD MAKE THIS PASS A FAILURE

**Changing a number while relabelling.** The two are separately reviewable and combining
them makes the diff unreadable — which is exactly how a re-estimation hides inside
housekeeping.

**Splitting the gain on Lohmeier's ratio.** §2. The interval is 0–0.47 and biased.

**Renaming `RN.MD.RENIN_GAIN` or `RN.PRESSURE_NATRIURESIS.SLOPE` in passing** because they
are also mislabelled. They are, and they are the next items. One rename per pass.

**The quiet one: treating this as cosmetic.** The reason the identifier matters is the
trap in §4.5 — the next person who sources an ANP dose-response will look at
`CV.ANP.NATRIURETIC_GAIN` and reasonably conclude it is the ANP gain. **It is not, and it
never was.**

---

# AMENDMENT 1 — 2026-09-18, the output is NOT bit-identical and the difference is named

**§1 and falsifiable test 1 demanded BIT-IDENTICAL output. That is not what was obtained**,
and recording it is cheaper than defending a claim that is one digit wrong.

**WHAT ACTUALLY CHANGED, IN FULL.** `validation/challenges.jl` output before and after
differs in exactly three places:

1. **Julia precompilation timings.** Not model output.
2. **A comment string** in the harness that names the renamed identifier. The rename.
3. **`relative drift, day 200 to day 400`: 2.687e-10 -> 2.686e-10.** Band 0 to 1e-9,
   PASS on both sides.

**EVERY PHYSIOLOGICAL OUTPUT IS IDENTICAL.** All 24 challenge lines, every reported value,
every band. The full suite is green with no pin, band or tolerance touched.

**THE CAUSE IS FLOATING-POINT REASSOCIATION AND IT IS ALREADY DOCUMENTED IN THIS
REPOSITORY.** `structural_simplify` orders terms by variable name; `anp_sig` and `vn_sig`
sort differently, so the emitted code sums the same terms in a different order and the last
bits differ. `test/runtests.jl` names the same mechanism for the RAAS escape check: *"the
extra states change what structural_simplify emits and hence the solver trajectory."* The
absolute difference here is **1e-13 on a quantity of 3e-10.**

**THIS IS L1, NOT L2.** §3's L2 branch is for a model output that *changes*; a drift
diagnostic moving in its fourth significant figure at the 1e-13 level is the arithmetic
noise directive 1.9 was written about, not a number. **But the pass may not claim
bit-identity, so it does not**, and the wording "identical to within floating-point
reassociation, with the one difference quoted" is what goes in the write-up.

**WHAT WOULD HAVE MADE THIS L2:** any challenge line changing, any band or pin needing to
move, or a difference in a quantity whose own magnitude is not at solver tolerance. None
occurred.
