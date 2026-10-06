# Pre-registration — the GFR autoregulation breakpoint, and smoothing it

**Written 2026-10-06, at the owner's instruction: B26 option 2 — adopt 80.5 *and* smooth the
breakpoint.**

    git log --diff-filter=A -- validation/autoreg_breakpoint_prereg.md

`OPEN-QUESTIONS` **B26**. Sixth pass under directive 1.16.

---

## 0. THE REVIEW, AND WHAT IS ALREADY ESTABLISHED

**No new review is read for this pass and that is deliberate.** `autoreg_form_prereg.md` §0
read Carlström, Wilcox & Arendshorst (Physiol Rev 2015, PMID 25834230) for exactly this
subsystem six weeks ago, and recorded what matters here: autoregulation is **myogenic plus
MD-TGF**, both acting on the afferent arteriole, with a third mechanism (CT-GF) the model does
not have. **Directive 1.16 asks for a review before modelling a subsystem, not before every
pass within it.**

**The values were also already extracted**, in the pass that produced ADR 0032, and are
recorded in B26. **This pass changes a value the record already holds and adds a form.**

---

## 1. WHAT IS WRONG NOW

`RN.AUTOREG.LOWER` = **63.9 mmHg**, and its own citation field says what it is: *"Lower limit
of renal **blood flow** autoregulation"* (Finke 1983). **It is wired into the GFR equation.**

| | GFR break-off | RBF break-off | n |
|---|---|---|---|
| Kirchheim 1987, PMID 3324052 | **80.5 ± 3.5** | 65.6 ± 1.3 | 22 |
| Persson 1988, PMID 3239413 | **81.5 ± 2.2** | 65.0 ± 1.4 | 10 |

Different at **P < 0.01**. Kirchheim gives the mechanism: RBF autoregulation *"also involves
postglomerular vessels"*, so flow is defended below the pressure at which filtration is not.

**SAME LABORATORY, THEREFORE ONE SOURCE.** `form_sourcing_audit.md` §4 and
`autoreg_form_prereg.md` §4 both fixed in advance that papers from one group count as one.
**Kirchheim is adopted (larger n); Persson is corroboration agreeing within 1 mmHg, and is NOT
pooled.**

---

## 2. DIRECTIVE 1.12 — ROUND NUMBERS, LISTED BEFORE BUILDING

- **"80 mmHg"** as the lower limit. **80.5 is within half a unit of the textbook figure this
  repository spent a pre-registered search discrediting**, and that coincidence must not be
  allowed to feel like confirmation. The textbook 80–180 is Shipley & Study 1951, anaesthetised
  dog, for **renal blood flow**. Kirchheim's 80.5 is conscious dog, for **GFR**, and the two
  agreeing numerically is an accident of a different measurement.
- **A smoothing width chosen because it looks smooth.** §4 fixes it by a stated criterion.

---

## 3. WHAT MAY NOT MOVE

- **`RN.AUTOREG.UPPER` (160, Roman & Cowley)** — untouched.
- **`RN.PRESSURE_NATRIURESIS.SLOPE`, `RN.MD.RENIN_GAIN`** — the two `calibrated` rows. **This
  is the standing trap**: if anything shifts, the temptation is to re-solve `G_pn`. That is
  failure mode 22 and §7 forbids it.
- **ALL THREE STEADY-STATE SALT ARMS — MAP 81.900 / 84.450 / 87.001 — MUST BE BIT-IDENTICAL**,
  and §4 makes that a property of the form rather than something to be checked afterwards and
  hoped for.
- **No band, pin or tolerance widened.**

---

## 4. THE FORM, AND THE ARITHMETIC WAS DONE BEFORE THIS SECTION WAS WRITTEN

**That sentence is the point.** `glucose_splay_prereg.md` §4 asserted a form had "the right
limits", and it did not — the low-load limit was wrong by a factor of 5.88 and the model
reabsorbed 2.2× what it filtered while every gate passed. **This section was written after
evaluating the candidate at both limits and at all three operating arms.**

### 4.1 The symmetric smoothing is REJECTED, with numbers

`((x+1) − √((x−1)² + ε²))/2`, the standard hyperbolic smoothing of `min(x,1)`, **undershoots 1
everywhere**, so it moves the healthy operating point:

| ε | width | GFR change at MAP 87.001 |
|---|---|---|
| 0.05 | 4.03 mmHg | 7.1e-3 |
| 0.01 | 0.81 mmHg | 3.1e-4 |
| 0.001 | 0.08 mmHg | 3.1e-6 |

**Any width wide enough to regularise the corner moves results the suite pins to five figures;
any width narrow enough to be safe regularises nothing.** Rejected.

### 4.2 ADOPTED: a one-sided cubic Hermite blend, entirely BELOW the breakpoint

With `x = MAP / MAP_lo` and blend fraction `δ`:

    x ≥ 1        ->  f = 1                      EXACTLY
    x ≤ 1 − δ    ->  f = x                      EXACTLY
    otherwise    ->  cubic Hermite on [1−δ, 1] with f(1−δ)=1−δ, f'(1−δ)=1, f(1)=1, f'(1)=0

**VERIFIED NUMERICALLY BEFORE ADOPTION**, with `δ = 0.05` (4.03 mmHg, blending 76.47–80.50):

- `f` = **1.000000000000** at MAP 81.900, 84.450 and 87.001 — **all three arms exact**;
- `f` = `x` to machine precision at and below 76.47;
- derivative across the lower join 1.0000 → 1.0004, across the upper join 0.0008 → 0.0000;
- **monotone**, and `f ≤ 1` everywhere on 30–200 mmHg.

**SO STEADY STATES CANNOT MOVE AND ONLY TRANSIENTS SEE THE SMOOTHING.** That is the whole
design: the kink is removed from the path a falling pressure takes, not from the resting model.

**δ = 0.05 IS A NUMERICAL REGULARISATION WIDTH AND NOT A PHYSIOLOGICAL CLAIM.** Kirchheim
describes the break-off points as *"sharp"* **in individual animals**, so a smoothed corner is
not what he measured. It is declared as a solver accommodation, its size is reported, and §7
test 6 reports what it does.

**The blend lies slightly ABOVE the hard `min` inside the transition** — GFR is marginally
better preserved just below the breakpoint, by at most 7.3e-3 — rather than below it. Recorded
because it is the opposite of what a symmetric smoothing does.

---

## 5. WHAT THIS PASS WILL AND WILL NOT CHANGE — REQUIRED BY 1.16

**WILL:** the pressure at which GFR stops being autoregulated, 63.9 → 80.5, which is **16.6
mmHg of margin** between the low-salt arm and the limit; and the smoothness of that limit.

**WILL NOT change any steady state.** §4.2 makes `f` exactly 1 at every arm, and **the same is
true of the value change alone** — all three arms sit above 63.9 *and* above 80.5, so a hard
breakpoint at either gives identical steady states. **This must be stated plainly in the ADR:
the correction is about margin and transients, not about the resting model**, and reporting
"nothing changed" as reassurance would be the dishonest reading.

**WILL NOT fix B23.** Smoothing removes one candidate mechanism for the intermittent
`salt_step(raas=false)` failure. **It is not a diagnosis**, and §7 test 5 is evidence-gathering
rather than a closure.

---

## 6. THE DECISION RULE

- **K1 — the blend behaves as §4.2 verified and all arms are bit-identical.** Build; ADR.
- **K2 — a steady state moves at the fifth figure anyway**, e.g. through the transient path to
  equilibrium. **Report it and do not widen a pin**; investigate before accepting.
- **K3 — the solver gets worse**, more `Unstable` retcodes or slower. **Report and revert the
  smoothing, keeping the value change**, which stands on its own evidence.

---

## 7. THE FALSIFIABLE TESTS

1. **All three salt arms bit-identical** — MAP, `V_ecf`, `Na_excr`, urine, GFR — to the
   precision the suite already pins.
2. **Chronic salt sensitivity and `dMAP/dV_ecf` unchanged**, which follows from 1 and is
   asserted separately because it is the headline result.
3. **`f` is exactly 1 at every arm**, asserted directly on the model rather than inferred.
4. **GFR as a function of MAP across 50–170 mmHg**, reported, showing the plateau, the blend
   and the proportional limb — and **no discontinuity in slope**.
5. **`salt_step(raas = false)` run repeatedly**, with the count of `Unstable` retcodes
   reported against B23's record. **Evidence, not a closure.**
6. **The blend's maximum deviation from the hard corner**, reported as a number.
7. **All challenges and the full suite.**

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Re-solving `G_pn` or `RN.MD.RENIN_GAIN` because something moved.** §3.

**Choosing δ to make a test pass.** §4 fixed it at 0.05 by a stated criterion — wide enough to
regularise, entirely below the lowest arm — before anything was built.

**Claiming the smoothing fixed B23.** §5.

**Reporting "no steady state changed" as evidence the correction was right.** It is a property
of where the arms sit, not of the breakpoint's value, and §5 requires saying so.

**Letting 80.5 ≈ 80 feel like the textbook agreeing.** §2.
