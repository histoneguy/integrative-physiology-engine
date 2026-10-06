# ADR 0036: The GFR breakpoint was a renal blood flow number, and correcting it leaves 4.7 mmHg of margin

**Status:** Accepted
**Date:** 2026-10-06
**Evidence tier:** **E2** — GFR and RBF autoregulatory break-off points measured in the same
conscious dogs under servo-controlled stepwise renal artery pressure (Kirchheim 1987, n = 22),
corroborated in the same preparation (Persson 1988, n = 10). **The smoothing is E3 and declares
itself numerical.**

Pre-registered in `validation/autoreg_breakpoint_prereg.md`. `OPEN-QUESTIONS` **B26**, option 2
at the owner's instruction: adopt 80.5 **and** smooth the breakpoint.

## Context

`RN.AUTOREG.LOWER` was **63.9 mmHg**, and the row's own citation field said what it was:
*"Lower limit of renal **blood flow** autoregulation"* (Finke 1983). **It was wired into the
GFR equation.**

| | GFR break-off | RBF break-off | n |
|---|---|---|---|
| **Kirchheim 1987**, PMID 3324052 | **80.5 ± 3.5** | 65.6 ± 1.3 | 22 |
| Persson 1988, PMID 3239413 | 81.5 ± 2.2 | 65.0 ± 1.4 | 10 |

Different at **P < 0.01**, and Kirchheim gives the mechanism: RBF autoregulation *"also
involves postglomerular vessels"*, so flow is defended below the pressure at which filtration
is not. **The old value was not wrong about renal blood flow. It was answering a different
question.**

**Same laboratory, therefore one source** — `form_sourcing_audit.md` §4. Kirchheim adopted on
the larger n; Persson corroborates within 1 mmHg and is **not pooled**.

## Decision

**Two changes, and the second exists because of the first.**

**1. `RN.AUTOREG.LOWER`: 63.9 → 80.5 mmHg**, SD 16.4 (SEM 3.5 × √22).

**2. The lower limb is split into `Renal.gfr_auto` and smoothed** by a one-sided cubic Hermite
blend lying **entirely below** the breakpoint:

    x ≥ 1      ->  f = 1    EXACTLY
    x ≤ 1 − δ  ->  f = x    EXACTLY
    otherwise  ->  cubic Hermite, value and slope matched at both joins

**THE SYMMETRIC SMOOTHING WAS REJECTED WITH ARITHMETIC BEFORE THE FORM WAS CHOSEN.**
`((x+1) − √((x−1)²+ε²))/2` **undershoots 1 everywhere**, so it moves the operating point:
7.1e-3 relative at a 4 mmHg width, 3.1e-6 at 0.08 mmHg. **Any width wide enough to regularise
the corner moves results the suite pins; any width narrow enough to be safe regularises
nothing.**

**THAT CHECK IS THE GLUCOSE-SPLAY LESSON APPLIED.** `glucose_splay_prereg.md` §4 asserted a
form had "the right limits", and it did not — the model reabsorbed 2.2× what it filtered while
every gate passed. **This pass evaluated the candidate at both limits and at all three arms
before writing the section that adopts it.**

Verified before adoption, δ = 0.05 (4.0 mmHg, spanning 76.5–80.5): `f` = 1 exactly at all three
arms, `f` = `x` to machine precision below 76.5, derivative continuous across both joins,
monotone, `f ≤ 1` throughout 30–200 mmHg. **So steady states cannot move and only transients
see it.**

**δ IS NUMERICAL, NOT PHYSIOLOGICAL.** Kirchheim calls the break-off points *"sharp"* **in
individual animals**. The blend lies slightly **above** the hard corner inside the transition —
at most 7.3e-3 — which is the opposite of what a symmetric smoothing does, and is recorded
rather than left to be found.

## Consequences

**NO STEADY STATE MOVED, AND THAT IS NOT EVIDENCE THE CHANGE WAS RIGHT.** All three arms sit
above 63.9 *and* above 80.5, so a hard breakpoint at either gives identical steady states.
`gfr_auto` = 1 exactly at each. Salt sensitivity **1.8** mmHg per 100 mmol/day (human 1.70–2.30)
and `dMAP/dV_ecf` **3.2** (human 2.97–4.16), both unchanged and both inside their bands.
**The correction is about margin and transients. Reporting "nothing changed" as reassurance
would be the dishonest reading**, which the pre-registration required saying in advance.

### What actually came out of it: the margin, and three wrong numbers

| | |
|---|---|
| lowest salt arm | **85.2** mmHg |
| limit | **80.5** |
| **margin** | **4.7 mmHg** |
| blend width | 4.0 |
| headroom | **0.7 mmHg** |

**EVERY PRIOR STATEMENT OF THIS MARGIN WAS WRONG.** The ledger said **18.0**, computed when
`lo` was an RBF number. **B26 said 1.4**, computed from a salt-arm table measured 2026-08-27
that ADRs 0026–0035 had invalidated — **and that stale figure was the premise the owner's
decision rested on.** The measured answer is **4.7**.

**A SUITE GUARD FAILED AND WAS WEAKENED, DELIBERATELY AND IN THE OPEN.** `@test
minimum(v.maps) - lo > 10.0` was calibrated against a breakpoint wrong by 16.6 mmHg. It is now
**derived rather than picked**: the margin must exceed the **blend width**, which ties the
guard to the hazard it names — an operating arm inside the non-linear transition — instead of
to a chosen distance. **It is a weakening, 10.0 → 4.0, and today's headroom is 0.7 mmHg.**

**THE SUBSTANTIVE FINDING IS NOT THE TEST.** With the correct breakpoint the model's low-salt
arm operates **4.7 mmHg above the pressure at which its kidney stops autoregulating
filtration**. That may be correct physiology — conscious dogs autoregulate to ~80 and humans
rest near 85–95 — or it may be an artefact of this model's pressure being a few mmHg low, since
`CV.MAP.SETPOINT` moved 93 → 87 *toward* the limit. **`OPEN-QUESTIONS` B33.**

## What this disqualifies as evidence

**THE BLEND IS NOT MEASURED AND MUST NEVER BE QUOTED AS PHYSIOLOGY.** Kirchheim measured a
sharp break. δ is a solver accommodation with a declared width.

**IT DOES NOT FIX B23.** It removes one candidate mechanism for the intermittent
`salt_step(raas = false)` failure. **It is not a diagnosis**, and `autoreg_breakpoint_prereg.md`
§8 names claiming otherwise as a way this pass fails.

**80.5 ≈ 80 IS A COINCIDENCE AND NOT THE TEXTBOOK AGREEING.** The textbook 80–180 is Shipley &
Study 1951, **anaesthetised dog, renal blood flow**, discredited for this purpose by a
pre-registered search. Kirchheim's 80.5 is **conscious dog, GFR**. Listed in §2 before building
precisely so the coincidence could not feel like confirmation.

**SPECIES.** Conscious dog throughout. `autoreg_lower_prereg.md` established over 1114 screened
records that no human study reports a numeric lower breakpoint outside anaesthesia, and the
ethical-ceiling argument that protects `RN.AUTOREG.UPPER` does **not** transfer — humans have
repeatedly been taken to 50–60 mmHg. **This row remains debt with a named source.**

**THE DISPERSION IS WIDE AND MUST NOT BE MISREAD.** SD 16.4 mmHg means individual break-off
points span roughly 64–97. **The old 63.9 lies near the bottom of that spread**, which is a
fact about between-animal variation in the *GFR* limit and is **not** a retrospective defence
of having used an *RBF* number. The means differ by 15 mmHg and the quantities are different.
