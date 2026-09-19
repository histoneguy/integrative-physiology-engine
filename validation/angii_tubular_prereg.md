# Pre-registration — `fr_angii`, the non-escaping angiotensin II tubular term

**Written 2026-09-19, before any row is entered and before any term is written.** Verify
with

    git log --diff-filter=A -- validation/angii_tubular_prereg.md
    git log --diff-filter=A -- validation/angii_tubular_extract.py

Opened at the owner's instruction after the Hall 1984 full text was supplied. This builds
what **ADR 0015** has proposed and left unbuilt since 2026-09-02.

---

## 0. WHAT CHANGED, AND WHY THIS IS NOW BUILDABLE

The 2026-09-19 source search recorded that **no human source exists** — every human ANG II
infusion moves GFR and renal plasma flow with tubular handling, and servo-control of renal
perfusion pressure is not performable in a human. **Directive 1.15, and Hall is the
source.** The blocker recorded that day was **not** the magnitude but the **mapping**: the
model has no absolute ANG II scale.

**The full text supplies the mapping in Hall's own words**, and it is a physiological state
rather than a concentration:

> *"ANG II infusion at a rate of 5 ng·kg⁻¹·min⁻¹, a dose calculated to increase plasma ANG
> II concentration to levels similar to those found during **sodium deprivation**"*

**That is expressible on the model's `pra` axis without any absolute concentration**, which
is what made this unbuildable yesterday.

---

## 1. THE SOURCE, READ IN FULL

**Hall JE, Granger JP, Hester RL, Coleman TG, Smith MJ Jr, Cross RB.** *Mechanisms of
escape from sodium retention during angiotensin II hypertension.* Am J Physiol
1984;246(5 Pt 2):F627-F634. **PMID 6720967. FULL TEXT READ** — supplied by the owner.

Twelve conscious male mongrel dogs, 21–27 kg (mean 22.2 ± 0.8), chronically instrumented,
sodium-deficient diet plus supplement to **~80 meq/day**. ANG II
[Asp¹,Val⁵] at 5 ng·kg⁻¹·min⁻¹. **Eight dogs had renal perfusion pressure servo-controlled
at the control level by an inflatable aortic occluder driven by a proportional servo-control
unit, 24 h/day.** Four had it free.

| | value |
|---|---|
| sodium intake | ~80 meq/day |
| control UNaV | 79 ± 6 meq/day |
| control MAP | 100 ± 3 mmHg |
| control GFR | 81.5 ± 7.4 ml/min |
| control plasma Na | 142.5 ± 0.5 meq/l |
| **servo arm, day 6 UNaV** | **56 ± 5 meq/day** |
| servo arm, cumulative Na balance 6 d | +210 ± 37 meq |
| plasma aldosterone, control | 4.6 ± 1.0 ng/100 ml |
| **plasma aldosterone, servo day 4** | **4.9 ± 0.8 — back at control** |
| UNaV on releasing the occluder | **56 → 322 ± 35 meq/day** |

---

## 2. THE MAGNITUDE IS THE DAY-6 RATE, NOT THE SIX-DAY AVERAGE

**The +210 meq/6 days = 35 meq/day figure quoted on 2026-09-18 is a FRONT-LOADED AVERAGE
and must not be used.** Table 1's free arm shows the transient: UNaV falls to 20 meq/day on
day 1 and recovers. The servo arm's day-6 rate is **80 − 56 = 24 ± 5 meq/day**, and that is
the quantity a **non-escaping steady term** represents, because at day 6:

- **renal perfusion pressure is still clamped** — the pressure-natriuresis route is excluded
  by the preparation;
- **plasma aldosterone has returned to control** (4.9 ± 0.8 vs 4.6 ± 1.0) — the
  aldosterone route is excluded by measurement, not by assumption;
- **retention continues anyway.**

**That is `fr_angii` exactly as ADR 0015 defines it**, and the record's structural choice —
`fr_angii` not subject to `esc` — is confirmed by Hall's own conclusion that the pressure
rise is what permits escape.

**TWO SIGNIFICANT FIGURES: 24 meq/day.** Directive 1.13.

---

## 3. THE DERIVATION CHAIN, FIXED BEFORE ANYTHING IS ENTERED

    fractional increment = retention / filtered load
                         = 24 / (81.5 ml/min -> 117.4 L/day x 142.5 meq/l)
                         = 24 / 16724 = 0.00144

    anchor: that increment occurs at plasma ANG II of SODIUM DEPRIVATION (Hall's words)
    model pra:  resting 1.2956,  low-salt arm (38 mEq/day) 2.5795,  delta 1.2839

    k_angii = 0.00144 / 1.2839 = 1.1e-3 per unit pra        TWO FIGURES

    fr_angii = k_angii * (pra - pra_ref)                    ZERO AT THE OPERATING POINT

**THE THREE WEAK LINKS, NAMED NOW RATHER THAN DISCOVERED LATER:**

1. **The fractional transfer is the cross-species step.** Retention is expressed as a
   fraction of the filtered load, which is intensive, rather than as mEq/day, which is not.
   **That is the same argument `RAAS.RENIN.SYMPATHETIC_THRESHOLD_SHIFT` makes for an
   intensive pressure**, and it is the strongest available — but it is still dog → human.
2. **"Sodium deprivation" = the model's 38 mEq/day arm is MY mapping, not Hall's.** He says
   his dose reaches sodium-deprivation ANG II levels; which model `pra` that is remains a
   judgement. **The row must say so.**
3. **Hall's preparation has exogenous ANG II with SUPPRESSED endogenous renin** — PRA falls
   0.27 → 0.04 ng·ml⁻¹·h⁻¹. **The model's `pra` conflates renin and ANG II** and cannot
   represent that dissociation. The anchor therefore rests on total ANG II activity being
   comparable, not on the renin state matching.

---

## 4. WHAT MAY NOT MOVE

- **The operating point.** `fr_angii` is zero at `pra_ref` by construction. Resting MAP,
  `V_ecf`, urine volume and osmolality, plasma sodium, `Na_excr` = 205.000 must be
  **unchanged**. If any moves, the term is written wrongly — fix the term.
- **No existing parameter may be re-solved to absorb it.** Not
  `RN.PRESSURE_NATRIURESIS.SLOPE`, not `CV.VOLUME.NATRIURETIC_GAIN`, not
  `RN.MD.RENIN_GAIN`, not `RAAS.RENIN.PRESSURE_GAIN`. **If the chronic band breaks, that is
  the result**, not a licence to re-fit.
- **`k_angii` may NOT be tuned to Hall 1980's clamp contrast.** That is the falsifiable
  test and it must stay out of the estimation.
- **`esc` is untouched.** `fr_angii` is added outside it, per ADR 0015.

---

## 5. THE FALSIFIABLE TEST, WHICH IS ADR 0015'S AND IS UNCHANGED

**Hall 1980 (PMID 6254369): control dogs take < 7 mmHg across 5 → 500 meq/day; dogs with
ANG II clamped take +42%.** ADR 0015 requires that **pinning `fr_angii` increase the
salt-step pressure shift by at least 2×.** Hall's own contrast is about six-fold.

**This is a different protocol, a different endpoint and a different paper from the
estimation source**, which is what makes it a test.

---

## 6. THE DECISION RULE

- **A1 — built, operating point unchanged, chronic salt sensitivity stays inside
  1.70–2.30, and pinning it amplifies the shift ≥ 2×.** Adopt; ADR 0015 moves to Accepted.
- **A2 — the operating point moves.** The term is written wrongly. Fix it.
- **A3 — chronic salt sensitivity leaves 1.70–2.30.** **Report it and leave the term OFF.**
  Do **not** re-solve anything to bring it back. The sourced magnitude is what it is, and a
  model that cannot carry it is the finding.
- **A4 — pinning it amplifies by less than 2×.** **ADR 0015's own test fails**, and the
  record says what that means: the term is not carrying the physiology it is named for.
  Report it as a refutation regardless of how well the magnitude was sourced.
- **A5 — the sodium limb's acute endpoints (Jensen, the ordering ratio) move.** Report;
  they are not fitted here.

---

## 7. THE FALSIFIABLE TESTS

1. **Operating point bit-unchanged**, demonstrated by running.
2. **`fr_angii` is exactly zero at the reference**, demonstrated by running.
3. **The day-6 rate is used and the 35 meq/day average is explicitly rejected on the row.**
4. **Chronic salt sensitivity, Jensen, and the acute ordering ratio reported before and
   after.**
5. **The ≥ 2× pinning test run and reported**, whichever way it goes.
6. **All three weak links in §3 are on the row**, including that the "sodium deprivation"
   mapping is this repository's judgement and not Hall's.
7. **Species dog, conscious, servo-controlled, n = 8, FULL TEXT READ** — and the scaling
   argument stated, per directive 1.6.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Using 35 meq/day.** It is a front-loaded average over a transient the free arm shows
directly. §2.

**Tuning `k_angii` to Hall 1980, or to the human chronic band.** Both are tests; spending
either leaves nothing able to be wrong. ADR 0015 said this before any source existed.

**Re-solving another gain when the chronic band moves.** A3 exists precisely because that
is the tempting move, and four of this repository's recorded failures are that move.

**Presenting the dog → human fractional transfer as though it were free.** It is the
weakest link in §3 and the row must carry it.

**The quiet one: reporting A1 and burying A4.** ADR 0015's test was written to be able to
fail. If pinning does not amplify, **that is the pass's main result**, and it says the term
is misnamed rather than that the sourcing was poor.
