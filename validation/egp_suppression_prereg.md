# Pre-registration — insulin suppression of endogenous glucose production

**Written 2026-09-24, before any value is entered and before either full text is opened.**

    git log --diff-filter=A -- validation/egp_suppression_prereg.md

Third pass under directive 1.16. `OPEN-QUESTIONS` B22's successor; named in HANDOVER §4 as
*"the single biggest gap in the glucose axis"* and by the owner as the blocker for both
diabetes types.

---

## 1. THE REVIEW, AND WHAT IT ESTABLISHED

**Ahrén & Pacini 2021, PMID 33098240, full text read 2026-09-23** (the same review that
produced ADR 0033). §1.2 of `nimgu_form_prereg.md` recorded the structural point that
matters here and recorded it **before** this pass existed:

> `S_G` *is a minimal-model parameter that lumps **suppression of endogenous glucose
> production** and renal glucose excretion.*

**THAT IS THE ADMISSION THIS PASS IS BUILT ON.** The model has renal excretion and EGP as
separate terms, which is why an `S_G` value was refused for NIMGU — **and EGP suppression is
the term that refusal said existed and the model did not have.** It has been a named hole
since 2026-09-23, not a new idea.

**WHAT THE MODEL CURRENTLY DOES:** `egp_tot = GLU_EGP_BASAL * body_mass * 1440 / MW_glu` —
**a constant.** Insulin cannot suppress hepatic glucose output at all.

**WHY THAT BREAKS BOTH DIABETES TYPES, STATED BEFORE BUILDING.** Unrestrained EGP is the
principal driver of **fasting** hyperglycaemia in type 1 and type 2 alike. A model with fixed
EGP can only produce hyperglycaemia by failing to *dispose* of glucose, so it represents the
postprandial defect and not the fasting one, and **no amount of tuning the disposal side can
fix that** — it is a missing term, not a wrong coefficient.

---

## 2. DIRECTIVE 1.12 — ROUND NUMBERS LISTED BEFORE EXTRACTION

- **"The liver produces 2 mg/kg/min"** — the model already carries 1.93 from Huidekoper, and
  the round 2 is the teaching version of it.
- **"Insulin halves hepatic glucose output"** with no concentration attached.
- **"EGP is fully suppressed at 60 µU/ml"** — a real reported figure, but *"approximately"*
  in the source, and §5 must not treat an approximate word as an anchor.
- A **Hill coefficient of 1** adopted because it is tidy rather than because it was measured.

---

## 3. ADMISSIBILITY AND POOLING, FIXED BEFORE EXTRACTION

**Include:** healthy adults; **graded** insulin infusion at three or more levels with EGP
measured **isotopically**; euglycaemia maintained by variable glucose infusion so that the
glucose effect is not confounded with the insulin effect.

**Exclude:** single-step clamps, which give one point and cannot constrain a dose–response;
diabetic cohorts as the source of the **normal** curve (they are the thing to be predicted);
minimal-model estimates, per `pooling.md` and the ADR 0031/0033 precedent.

**GROUP INDEPENDENCE.** Two candidate laboratories are known to exist before extraction and
are **independent**: Rizza/Gerich (Mayo) and Groop/Ferrannini (Pisa–Yale). **If both yield an
admissible dose–response the value is pooled; if only one does, the row says `single-source`
and the other is recorded as corroboration.** Directive 1.16's requirement is on the **form**
and is expected to be met either way.

**POPULATION DATA:** `uncertainty_type = sd`, SEM converted with its own n and recorded.

---

## 4. THE FORM, FIXED BEFORE THE VALUE IS KNOWN

    EGP(I) ~ EGP_0 / (1 + I / K_egp)

**WHY THIS AND NOT A SUPPRESSION FRACTION.** A form written as
`EGP_basal * (1 - I^h/(K^h + I^h))` is undefined below basal insulin, and **type 1 is
exactly the case where insulin goes to zero.** The hyperbolic above is smooth, strictly
positive and defined on the whole range `I ≥ 0`, so the type 1 limit is a *value* rather than
an extrapolation off the end of a curve.

**TWO ANCHORS, TWO PARAMETERS — AN EXACT INVERSION, NOT A FIT**, the same discipline as
Merovci (ADR 0031) and Baron (ADR 0033):

1. `EGP(I_fast) = GLU.EGP.BASAL` — **the definition of basal**, so health cannot move.
2. `EGP(I₅₀) = 0.5 × GLU.EGP.BASAL` — half-maximal suppression at the sourced insulin
   concentration.

**`K_egp` AND `EGP_0` ARE THEREFORE COMPUTED IN-COMPONENT AND STORED NOWHERE.** Only the
measured `I₅₀` becomes a ledger row. That is the ADR 0032 lesson about derived constants
applied deliberately: a stored derived constant is a precision claim and a drift risk.

**HILL COEFFICIENT FIXED AT 1 IN ADVANCE, AND THE COST DECLARED NOW.** A simple hyperbolic
will **under-suppress at high insulin** relative to a source reporting near-complete
suppression around 60 µU/ml. **That is accepted and must be reported, not tuned away.**
Raising `h` to match a qualitative word is the §9 failure. Only a digitised multi-point curve
could justify `h > 1`, and §7 test 6 declares that comparison in advance.

---

## 5. WHAT MAY NOT MOVE

- **`GLU.EGP.BASAL` (1.93 mg/kg/min, Huidekoper)** — this pass changes the *response*, not
  the basal value. It remains single-source debt under B21.
- **`GLU.NIMGU.FRACTION`, `GLU.NIMGU.FIXED_FRACTION`, every Merovci insulin row, `RN.GLU.TM`.**
- **`S_I`**, which re-derives against the new appearance and may **not** be re-fitted.
- **The healthy operating point** — glucose 5.44, insulin 64.2 — which anchor 1 makes exact.
- **Nothing renal.** If glycosuria changes it must be a consequence.

---

## 6. WHAT THIS PASS WILL AND WILL NOT LET THE MODEL REPRESENT — REQUIRED BY 1.16

**WILL:** fasting hyperglycaemia driven by hepatic output; the reason type 1 is severe;
hyperinsulinaemic suppression of EGP in compensated insulin resistance.

**WILL NOT:** hepatic *insulin resistance* as a lesion separate from peripheral resistance —
`glu_disposal` scales `S_I` only, and a separate hepatic knob is **deliberately not added
here**. Groop 1989's central finding is that the two are dissociable in type 2. **Recorded so
a later pass cannot present it as a discovery**, exactly as ADR 0032 did for CT-GF.

**WILL NOT:** glucagon, which is the other arm of EGP control and is absent from this model
entirely.

---

## 7. THE FALSIFIABLE TESTS

1. **Health is bit-identical** — glucose 5.44, insulin 64.2, MAP, sodium, urine, `Na_excr`.
   Anchor 1 makes this exact, not approximate.
2. **`EGP(I)` is monotonically decreasing** and strictly positive for all `I ≥ 0`.
3. **THE PREDICTION: type 1 worsens and type 2 worsens less.** Removing insulin removes EGP
   suppression, so fasting glucose must rise **further** in type 1 than the 21.32 mmol/L of
   ADR 0033. In compensated resistance, insulin is *elevated*, so EGP is *more* suppressed and
   glucose should rise **less** than it does today — a **direction change**, not a magnitude
   one, and the sharper test.
4. **Reported: EGP at zero insulin as a multiple of basal.** Uncontrolled type 1 EGP is
   elevated roughly two- to threefold in the literature. **If the inversion implies something
   far outside that, the form is wrong** — an out-of-sample check the anchors do not
   guarantee.
5. **Every challenge and the full suite**, reported unchanged or not.
6. **The `h = 1` cost, measured:** report `EGP/EGP_basal` at 60 µU/ml against the source's
   "approximately complete". **Declared in advance so the admission is owed.**

---

## 8. THE DECISION RULE

- **E1 — a graded-infusion I₅₀ for EGP suppression in healthy adults is reported.** Build.
- **E2 — two independent groups report one.** Pool by §3 and build; the form then has two
  independent primaries, as ADR 0033's does.
- **E3 — only suppression *percentages* at named insulin steps are extractable**, with no
  I₅₀. Then the two-anchor inversion is unavailable; **report INDETERMINATE and do not fit a
  curve to two percentages**.
- **E4 — the sources show EGP suppression is not saturable in the physiological range.**
  Then a linear term, and §4's argument about the type 1 limit is re-opened rather than
  assumed.

---

## 9. WHAT WOULD MAKE THIS PASS A FAILURE

**Raising the Hill coefficient to reproduce "complete suppression at ~60".** §4. That word is
approximate in the source and test 6 exists to keep the cost visible instead of absorbed.

**Re-deriving `S_I` against a glucose target.** §5. It re-derives against appearance by
identity; that is not the same thing.

**Adding a hepatic insulin-resistance knob in this pass.** §6. It is the obvious next thing
and stacking it makes neither testable alone — the ADR 0025/0026 discipline.

**Reporting type 1's new glucose without test 4.** A more severe type 1 is what this pass was
*built* to produce, so it is the least surprising possible result and the easiest to
over-read.

---

## 10. AMENDMENT — GROOP'S FULL TEXT WAS OBTAINED THE SAME NIGHT, AND IT CONSTRAINS `h`

**Appended 2026-09-24, after ADR 0034 and ADR 0035 were built and merged.** The paper was
**not** available when §4 fixed `h = 1`; JCI returned 503 twice and served it on a later
attempt. **Recorded here rather than folded back into §4**, because a pre-registration edited
after the result is not a pre-registration.

### 10.1 What §4's `h = 1` cost turned out to be

§4 accepted that a simple hyperbolic *"will under-suppress at high insulin"* and §7 test 6
required the number. **Measured: 27% of basal at 60 µU/ml.** Groop's controls give the missing
constraint directly — half-maximal suppression at portal **17 ± 2**, **>90% at portal 45** —
so `h = ln9/ln(45/17)` = **2.26**, and since *">90%"* is a bound, **h ≥ 2.26**.

### 10.2 AND IT IS A STRUCTURAL CONSTRAINT, NOT A TOLERANCE — WHICH §4 DID NOT SEE

The two-anchor inversion gives `K_egp = I₅₀ − 2·I_fast`, so **`h = 1` REQUIRES
`I₅₀ > 2·I_fast` = 21.4 µU/ml**. Rizza's 29 clears it; **Groop's peripheral 14 does not**, and
gives `K_egp` = **−44.4 pmol/L** — EGP would *rise* with insulin.

**So the form adopted in ADR 0034 is viable only because Rizza's value happens to exceed a
threshold nobody had computed.** §4 chose `h = 1` as "one fewer assumption"; it is in fact an
assumption with a hidden admissibility condition on `I₅₀`. **That is the single most useful
thing this pass learned, and it came from the second source rather than from the first.**

### 10.3 What may NOT be done with this

**`h` MAY NOT BE SET TO 2.26 AND THE MODEL REBUILT ON IT TONIGHT**, and §9's reasoning is why:

- **2.26 is inferred from a BOUND** (*">90%"*), so it is a floor, not an estimate.
- **`h` and `I₅₀` are not independent** — the same two points fix both — so adopting Groop's
  `h` while keeping Rizza's `I₅₀` mixes two cohorts inside one curve.
- **The two sources disagree two-fold on peripheral `I₅₀`** — 29 ± 2 against 14 ± 1 — and
  `pooling.md` is not a licence to average a conflict that tight.

**`OPEN-QUESTIONS` B30 carries it, with the three routes and the falsifier stated.**

### 10.4 And `hep_sens` is measurable after all

ADR 0035 said *"no admissible source gives a population value for the magnitude."* **Groop
does**: half-maximal suppression moves **17 → 26 µU/ml portal** from control to NIDDM, so
`hep_sens` = **0.65**. The ADR used an illustrative **0.3**. **The claim was wrong about the
literature, not about the model**, and it was wrong because the paper had not been read yet.

