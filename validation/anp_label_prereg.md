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
