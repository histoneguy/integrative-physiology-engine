# Pre-registration — the form of the volume–natriuresis path

**Written 2026-09-17, before any diagnostic sweep is run, before any source on the shape of
the natriuretic response is opened, and before any new term is written.** Verify the
ordering with

    git log --diff-filter=A -- validation/volume_natriuresis_form_prereg.md
    git log --diff-filter=A -- validation/volume_natriuresis_form_extract.py

Opened at the owner's instruction, following HANDOVER §3.46, which measured the tension
this document is about.

---

## 0. THE REQUIREMENT, STATED AS A NUMBER

§3.46: the model clears an acute isotonic load with a volume half-life of **13.10 h**
against Drummer 1992's measured **≈7 h** (PMID 1590419), and **no single parameter fixes
it** — the lag floors at 11.97 h even when made instantaneous, `G_pn` saturates at 11.12 h
at tenfold, `S_gfr_v` saturates at 8.62 h, and the natriuretic gains reach 7 h only at ×3,
where the chronic salt sensitivity collapses to **0.681** against a human **1.70–2.30**.

**So the requirement is:**

| excursion | what the path must deliver |
|---|---|
| chronic salt step, `ΔV_blood` ≈ **0.131 L** | what it delivers now — the chronic window is satisfied at 1.96 |
| acute load, peak `ΔV_blood` ≈ **0.441 L** | about **three times** the present response |

**THE RESPONSE PER LITRE MUST BE LARGER AT THE LARGE EXCURSION THAN AT THE SMALL ONE.**

---

## 1. AND THAT IS THE OPPOSITE OF WHAT ADR 0010 PROPOSES

ADR 0010 has said since 2026-08-21 that *"the real path is lagged or **saturating**"*, and
its unbuilt component is specified that way.

**A SATURATING PATH FLATTENS AT LARGE EXCURSIONS.** It delivers *less* per litre acutely
than chronically, which is the **wrong direction**, and building it as specified would make
§3.46's failure **worse**.

**THIS IS A CORRECTION TO ADR 0010's OWN PROPOSAL AND IT MUST BE RECORDED AS ONE**, not
quietly designed around. The reason the record got it backwards is traceable: its
saturating argument came from the acute **magnitude** comparison — *"matching Jensen's
acute +123% needs roughly half"* the chronic gain — and **HANDOVER §3.45 withdrew that
comparison** as a model peak set against a study's final sample. The direction reversed
when the measurement was corrected. **The record's conclusion did not follow its own
evidence out.**

---

## 2. WHAT MAY NOT BE BUILT UNTIL WHAT EXISTS HAS BEEN RUN

**Directive 1.11, and it is the whole of stage 1.** Every real defect found on 2026-08-27
was found by connecting something and none by any gate, and this repository's standing rule
is to wire up what exists before sourcing or inventing anything new.

**STAGE 1 IS A DIAGNOSTIC SWEEP OF ROWS THE MODEL ALREADY HAS, AND NO NEW TERM MAY BE
WRITTEN UNTIL IT IS DONE AND REPORTED.** The candidates, all `assumed`, all plausibly
governing how fast an acute load leaves:

| row | value | why it could matter |
|---|---|---|
| `BF.NA.STORAGE_TAU` | 7 d, assumed | a slow sodium store holds the load and slows the volume decay |
| `BF.NA.OSMOTICALLY_INACTIVE_FRACTION` | 0.15, assumed | how much of the load is osmotically inert, so never expands ECF |
| `BF.ICF_ECF.OSMOTIC_TAU` | 30 min, assumed | already flagged as dominant on acute manoeuvres and unsourced |
| the water limb / ADH | — | volume decay needs water out as well as sodium; if water lags, volume lags |
| `CV.PLASMA.ECF_FRACTION` | derived | the path senses `V_blood`, which is 21% of the ECF excursion — see §2.1 |

**Each is swept for the acute half-life AND the chronic salt sensitivity together**, exactly
as §3.46 swept the gains. **If any of them reaches ≈7 h without leaving 1.70–2.30, the
answer is that an existing row is wrong and NO NEW TERM IS BUILT.** That outcome is branch
F1 and it would be the best one.

### 2.1 ONE OF THEM IS A STRUCTURAL SUSPECT AND IS NAMED IN ADVANCE

`V_plasma ~ f_pv * V_ecf` with `f_pv` **constant**, so the model distributes an infused load
across plasma and interstitium **instantly and in fixed proportion**. The natriuretic path
senses `V_blood`, so it sees only 21% of the excursion.

**In life the intravascular share is HIGHER immediately after an infusion and falls as the
load equilibrates across the capillary wall over minutes to hours.** So the model may
understate the **early** atrial stretch signal — which is exactly when the natriuretic
response needs to be large — while matching it later. **That would produce a too-slow decay
with no nonlinearity anywhere.**

**The evidence that it matches LATE is already in this repository and is why this is a
suspect rather than a conclusion:** the model's plasma expansion at 6 h is **+14.3%**
against Lobo's measured **+14.9%** (§3.45 §1). **Right at six hours says nothing about
thirty minutes.**

---

## 3. THE TWO CANDIDATE FORMS, AND THE DISCRIMINATOR IS FIXED NOW

If stage 1 exonerates the existing rows, two forms could deliver §0's requirement, and
**which one is chosen must not be decided by which fits**:

- **(A) A STATIC CONVEX NONLINEARITY IN VOLUME.** The natriuretic response rises
  supralinearly with the excursion — a threshold or an accelerating curve.
- **(B) AN ADAPTING, RATE-SENSITIVE TERM.** The response is large to a *rapid* change and
  decays under a *sustained* one. Physiologically this is escape and receptor adaptation;
  the model already contains the machinery, because `fr_mod` escapes to zero at steady
  state.

### 3.1 THE DISCRIMINATOR, AND IT USES DATA THIS REPOSITORY ALREADY HOLDS

**(A) and (B) make different predictions about the CHRONIC pressure–sodium relation.**

Under **(A)**, a gain that rises with excursion makes the chronic relation **bend**: at high
sodium intake the larger ECF excursion recruits a disproportionately larger natriuresis, so
pressure rises *less* per mmol. The chronic relation becomes **concave**.

Under **(B)**, the sustained response is the same at every intake, so the chronic relation
stays **straight**.

**THE HUMAN CHRONIC RELATION IS APPROXIMATELY LINEAR ACROSS 38–230 mmol/day** — van den
Bosch's two arms, and the meta-analytic response is quoted as a single slope per 100
mmol/day by all three of Cutler 1997, He 2013 and He 2002, which is itself a linearity
assumption those analyses make.

**SO THE TEST IS QUANTITATIVE AND IT IS FIXED HERE:** build the convex form (A) steep enough
to deliver §0's factor of three, then **measure the curvature it imposes on the model's own
chronic pressure–intake relation across 38–230 mmol/day**. If that curvature is large enough
to have been visible in the human data, **(A) is refuted and (B) is what remains.**

**This must be measured, not argued.** The a priori expectation — written down so that
agreeing with it later is not evidence — is that **(A) will be refuted**, because a factor
of three between a 0.13 L and a 0.44 L excursion is steep, and a relation that steep does
not look linear over a sixfold range of intake.

---

## 4. WHAT MAY NOT MOVE

- **`CV.ANP.NATRIURETIC_GAIN` and `RN.PRESSURE_NATRIURESIS.SLOPE` may be re-solved ONLY
  against their own unchanged estimation sets** — the chronic salt sensitivity target of
  2.00 and `G_pn`'s own calibration. **Neither may be solved against the 7 h half-life**,
  which is this pass's test.
- **`RN.ANP.TAU` may not be re-solved at all.** §3.46 proved the lag cannot reach the target
  at any value; moving it would be fitting the wrong parameter.
- **JENSEN 2013 MAY NOT ENTER ANY ESTIMATION.** Reported before and after, never fitted.
  `JENSEN_FINAL_WINDOW_RISE` may be re-pinned only with an explicit statement of what moved
  it.
- **The chronic salt sensitivity must stay inside 1.70–2.30**, and `dMAP/dV_ecf` inside
  2.82–4.02.
- **Drummer's 7 h is ONE approximate figure from an abstract with n = 6 and no dispersion.**
  The model may be brought **inside a band around it**; it may not be tuned **onto it**.
  Matching 7.0 h to two figures would be claiming a precision the source does not have —
  directive 1.13.

---

## 5. DIRECTIVE 1.12 — AND THE HAZARD HERE IS A SENTENCE, NOT A NUMBER

**"The volume–natriuresis relation saturates."** It is in ADR 0010, it has been quoted
inside this repository for four weeks, it has never been measured here, and **§1 says it
points the wrong way.** It is the single most likely thing to be carried forward unexamined
by this pass, because it is already written down in a record with a status.

Round numbers listed in advance: **7 h**, **2 days**, **one third of the load by 6 h**,
**20%** filtration fraction, **1.73 m²**.

---

## 6. THE DECISION RULE

- **F1 — stage 1 finds an existing row that reaches ≈7 h inside the chronic window.** **No
  new term is built.** Report which row, source it properly if it is `assumed`, and stop.
  This is the best outcome and directive 1.11 predicts it is not the least likely.
- **F2 — stage 1 exonerates the existing rows; the convex form (A) is built and §3.1's
  curvature test refutes it.** Report the refutation with its number, **do not keep (A)**,
  and proceed to (B).
- **F3 — (A) survives §3.1.** Then both forms are live and neither is chosen in this pass.
  **Report that the discriminator failed to discriminate** and say what experiment would.
- **F4 — (B) is built and reaches ≈7 h inside the chronic window.** Accept. Report Jensen
  before and after, unfitted. Amend ADR 0010 to record that its saturating specification was
  the wrong direction and what replaced it.
- **F5 — neither form reaches the target without leaving 1.70–2.30.** **Report it and build
  nothing.** A model that cannot satisfy two human constraints simultaneously has said
  something, and §3.46 already established that the tension is real. Adding a term that
  fails to resolve it is worse than recording that none does.
- **F6 — anything else leaves its band.** Stop.

---

## 7. THE FALSIFIABLE TESTS

1. **Stage 1 is reported in full before any new term appears in the diff**, including the
   rows that changed nothing. A sweep reported only for the row that mattered is not a sweep.
2. **The acute volume half-life against Drummer's ≈7 h**, as a band and not a point.
3. **Chronic salt sensitivity inside 1.70–2.30** and `dMAP/dV_ecf` inside 2.82–4.02.
4. **The §3.1 curvature number is reported whichever way it comes out.**
5. **Jensen's 210–240 min window before and after**, unfitted.
6. **The operating point is unchanged** and the new term is **identically zero at the
   reference**, demonstrated by running — the `G_anp = 0` convention ADR 0010 itself used.
7. **`validation/challenges.jl` §3c goes from red to green, or it does not and the write-up
   says so in those words.** That check was added in the same session to make this failure
   visible; a pass that leaves it red has still learned something, and a pass that quietly
   widens its band has not.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Building ADR 0010's saturating component because the record says so.** §1 is the reason
this document exists, and a diff that adds a saturating term has not read it.

**Skipping stage 1.** Inventing a nonlinearity while three `assumed` rows that could explain
the whole thing sit unswept is the exact inversion of directive 1.11, and this repository's
record is that connecting existing things finds the real defect.

**Choosing between (A) and (B) by which one fits.** §3.1 fixes the discriminator in advance
precisely so that the choice is made by a prediction about the chronic relation and not by
the acute residual.

**Tuning onto 7.0 h.** One approximate figure, n = 6, no dispersion. A model brought to 7.02
h has been fitted to noise and will be quoted as agreement.

**The quiet one: re-solving `G_anp` against the half-life and calling the new form the
reason it works.** §4 permits re-solving only against the unchanged chronic target. If the
gain moves, the write-up must show the half-life the new FORM buys at the OLD gain, exactly
as §3.45 §7 item 6 required for the segmental pass — otherwise structure and refit cannot be
told apart.
