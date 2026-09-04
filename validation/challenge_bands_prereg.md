# Pre-registration — deriving the challenge comparison bands from reported dispersion

**Written before any source is opened for this question.** Verify the ordering with

    git log --diff-filter=A -- validation/challenge_bands_prereg.md

and compare against the commit that adds `validation/challenge_bands_extract.py`.
Per HANDOVER §5 item 12 this document cites **no SHA**, because rebase-merge rewrites
them and every pre-registration SHA already in this repo points at a commit `main` does
not contain.

---

## 1. THE PROBLEM, STATED BEFORE IT IS INVESTIGATED

`validation/challenges.jl` judges the model against published human data using bands
that **nothing derives**. The Lobo comparisons use "+/- 33%". That figure appears in no
paper, has no derivation recorded anywhere in this repository, and is a round number —
which HANDOVER directive 1.12 says to treat as presumptively unsourced whatever else is
claimed for it. The resting-state ranges carry the note *"Reference ranges for a healthy
70 kg adult male; sourced ledger rows where they exist"*, which concedes that some are
not sourced without saying which.

**Two consequences, and the second is the one that motivated this.**

1. The model is being judged against an invented tolerance. A band nobody derived can be
   neither passed nor failed meaningfully.
2. **Parameters have been fitted far inside those bands.** `RN.ANP.TAU` was estimated
   against Lobo's 6 h time course to an agreement of about **0.5%**, and the harness
   judges that same comparison at **±33%**. The same repository states two tolerances for
   one dataset that differ by roughly **sixtyfold**. At n = 10 the tight one cannot be
   right.

This document fixes, in advance, how a band is derived and what happens when the derived
band contradicts a result the harness currently reports as a pass.

---

## 2. SCOPE

**In scope:** every `check(...)` band in `validation/challenges.jl`.

**Out of scope, deliberately:**

- `ledger/parameters.csv` `uncertainty_value` columns. Populating those is the ensemble
  dispersion problem in HANDOVER §7 and is a larger, separate pass.
- **Re-fitting any parameter.** This pass changes TOLERANCES AND REPORTING ONLY. If a
  derived band makes an existing fit look bad, that is the finding. Fitting to a new band
  would be choosing the answer after seeing it, which is what §5 item 13 records going
  wrong before.
- The chronic salt-sensitivity band 1.70–2.30, which is **already derived** from three
  named meta-analyses. It is re-examined only to record whether it is a range across
  three point estimates or a pooled interval, because those are different objects.

---

## 3. THE TWO BANDS, AND WHICH ONE GATES

A study reports a group statistic. The model emits **one deterministic number** for a
reference individual. These are not the same object and the comparison has to say which
question it asks.

    Band M   mean +/- 2*SEM     "does the model predict the population CENTRAL VALUE?"
    Band I   mean +/- 2*SD      "is the model a PLAUSIBLE MEMBER of that population?"

with `SD = SEM * sqrt(n)` where only SEM is reported.

**DECISION, FIXED HERE: Band I gates. Band M is computed, printed, and does NOT gate.**

**The rationale, so it can be attacked later.** Every parameter in this model is a point
estimate and **its uncertainty is not propagated** — HANDOVER §7 records that only body
mass is sampled. A model output therefore carries no error bar of its own. Judging an
error-bar-free point against the confidence interval of a mean would fail the model for
its missing propagation rather than for its physiology, and would fail it *harder the
larger the study*, which is the wrong direction for evidence to push.

**Band I is the defensible floor and it is WEAK, and that is stated here rather than
discovered as a convenience later.** Band M is the test that will matter once parameter
uncertainty is propagated. **Where the model falls outside Band M, this pass RECORDS a
strict-test failure in the harness output even though it does not gate.** A comparison
that only ever reports the lenient verdict is the reporting failure this pass exists to
correct.

---

## 4. DISPERSION SOURCES, IN ORDER OF PREFERENCE

Reusing `pooling.md`'s ordering discipline rather than inventing a second one.

1. **SD reported directly.** Use it.
2. **SEM and n reported.** `SD = SEM*sqrt(n)`. Recorded as converted.
3. **95% CI of the mean and n reported.** `SEM = (hi-lo)/3.92`, then as above.
4. **IQR and n reported.** `SD ≈ IQR/1.35`. **Permitted for the DISPERSION ONLY, never
   for a central value**, and flagged on the row. `pooling.md` prohibits `range-midpoint`
   for point estimates and that prohibition is not weakened here.
5. **Nothing reported.** Branch N below. **A percentage is not invented.**

**Prohibited, fixed here:** taking the spread of a figure's plotted points, reading
dispersion off a graph, or carrying a dispersion from a different endpoint in the same
paper on the grounds that it is "similar".

---

## 5. NON-INDEPENDENT ENDPOINTS

Already established by reading `validation/challenges.jl`, and recorded in HANDOVER
§3.15: of the four Lobo checks, **two are computed from the other two.** Urine osmolality
is the integrated solute load divided by the same urine volume; the excreted fraction is
the sodium endpoint divided by 308. **The fraction check cannot fail unless the sodium
check has already failed** — its band 20–45% strictly contains the 20.45–41.23% that the
sodium band maps onto.

**Fixed here: a derived endpoint does not get its own independently chosen band.** It is
either

- **dropped**, if it adds nothing its inputs do not already assert, or
- **kept and LABELLED non-independent in the printed output**, with its band obtained by
  propagating its inputs' bands rather than by a fresh choice.

Choosing per endpoint after seeing which option keeps the harness green is prohibited.
The rule is: **drop it if its band is implied by an input's band; keep and label it if
propagation gives a band that can bite independently.**

---

## 6. THE RESTING-STATE RANGES ARE A DIFFERENT OBJECT

The eight resting checks are **clinical reference intervals**, not study means. A
reference interval is already a population interval, conventionally the central 95%, so
it maps onto **Band I directly** and must be **cited, not recomputed**.

Fixed in advance, per row:

- **R1** — the quantity has a ledger row with a source. Use that row's value and its
  dispersion; the harness band must then agree with the ledger rather than float free.
- **R2** — no ledger row, but a citable reference interval exists. Cite it.
- **R3** — conventional and uncitable. **Label the band `assumed` in the printed output
  and say so**, exactly as directive 1.12 requires of a round number. The `assumed` count
  going UP is the honest outcome and is not a failure of this pass.

**`sodium balance closes` at 204.9–205.1 is NOT a literature band** and is exempt. It
asserts that the model's own conservation holds, against its own intake. It stays tight
and its note must say it is an internal identity rather than a comparison.

---

## 7. THE DECISION RULE

Let a check be **derivable** if §4 yields a dispersion for it.

- **B1 — every Lobo endpoint derivable.** Replace all bands, print both Band I and
  Band M, apply §5 to the derived endpoints.
- **B2 — some derivable.** Derive those. The rest take branch N.
- **B3 — none derivable.** The ±33% survives **only relabelled**: printed as `assumed`,
  with its absence of derivation stated in the harness output and in HANDOVER. **That is
  a real result, not a null** — it means the model's acute agreement has never been
  judged against anything.
- **N — no dispersion for a given endpoint.** Keep the current numeric band, relabel it
  `assumed`, record in the extract exactly what was searched and where. Do not widen or
  narrow it: an undocumented band that is also moved is worse than one left alone.

### 7.1 THE BRANCH THAT MUST NOT BE AVOIDED

- **F — a derived band makes a currently-passing check FAIL.** **Record the failure. Do
  not widen the band, do not re-fit the parameter, and do not switch that endpoint to
  Band M-versus-Band I whichever is kinder.** `validation/challenges.jl` exits nonzero
  and HANDOVER's state line changes accordingly.

**This is the branch the whole document exists for.** The harness currently exits 0 and
that is a comfortable place to be. A tolerance pass that can only confirm the comfortable
result is not a test of anything. **If tightening an invented band turns the suite red,
red is the correct outcome** and the model, not the band, is what may then need work.

---

## 8. WHAT THE ANSWER CANNOT BE ALLOWED TO DO

- It may not change any parameter value.
- It may not change any model equation.
- It may not convert a fit into a validation. Lobo fixed `RN.ANP.TAU`; deriving a band
  for Lobo does not make it independent evidence, and HANDOVER §3.15's correction stands
  whatever this pass finds.
- It may not report agreement to more significant figures than the band supports. That
  is the reporting half of this pass and it applies to HANDOVER §2, §3.17, §3.20, §3.21
  and §3.22, all of which currently quote four- and five-figure agreement against
  quantities known to tens of percent.

---

## 9. WHAT IS RECORDED FOR EVERY ENDPOINT

n, sex composition, the reported central value, the reported dispersion and **its type as
printed in the source**, the conversion applied if any, both bands, whether the model sits
inside each, and — where nothing is reported — what was searched.

---

## 10. WHY THIS IS PRE-REGISTERED AT ALL

A tolerance is exactly the kind of quantity that can be chosen after seeing whether the
test passes, and no gate in this repository can detect that it was. HANDOVER §5 item 13
records a composed result read as a fact about physiology when it was a consequence of a
declared assumption nobody re-checked. **A band chosen to keep a suite green is that same
error with the assumption left undeclared.** Fixing the rule first is the only defence,
and `pooling.md` says the same thing one level up: any reasonable fixed rule beats a
well-chosen variable one.
