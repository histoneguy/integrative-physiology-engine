# Pre-registration — the structure of the sodium store, and whether it is the right target

**Written 2026-09-17, before any structure is built and before any combined sweep is run.**
Verify the ordering with

    git log --diff-filter=A -- validation/sodium_store_structure_prereg.md
    git log --diff-filter=A -- validation/sodium_store_structure_extract.py

Opened at the owner's instruction, following `sodium_store_sourcing_prereg.md` branch
**T4**: *"ADR 0004's single first-order compartment is the wrong structure … report it; do
not build the second compartment in this pass."* **This is the pass that may.**

---

## 0. TWO QUESTIONS, AND THE SECOND ONE IS THE ONE NOBODY HAS ASKED

**Q1 — what structure does the store need?** §3.51 put three timescales in evidence against
one compartment: **2–4 hours** (Olde Engberink), **~6 days** and **monthly and longer**
(Rakova).

**Q2 — IS THE STORE THE RIGHT TARGET AT ALL?** §3.50 measured that it **reproduces the
ordering and not the speed**: it pivots the two half-lives about their common starting
point rather than moving both down. **A perfect store does not fix Drummer.** Every pass
since §3.49 has assumed the store is the answer because it explains the *dissociation*, and
**explaining the dissociation is not the same as reproducing the decay.**

---

## 1. THE ARITHMETIC THAT FRAMES IT, DONE BEFORE ANYTHING IS BUILT

| | volume t½ | sodium t½ | ratio |
|---|---|---|---|
| **Drummer** | **7.0 h** | **10.0 h** | **0.70** |
| model, store off | 13.33 | 12.52 | 1.065 |
| model, store f=0.40 τ=0.25 d | 9.68 | **14.37** | 0.674 |

**THE STORE SLOWS SODIUM.** It must — sodium parked in the compartment is still in the body
and still counts in a balance. So landing sodium at 10 h **with the store on** needs the
underlying clearance faster by roughly **1.4×**, on top of whatever the store then does.

**AND THAT MAY NOT BE AFFORDABLE.** The form pass measured gains ×1.5 → chronic salt
sensitivity **1.31**, against a human window of **1.70–2.30**. **So there may be NO
configuration of this model that satisfies Drummer's two half-lives and the chronic window
at once.**

**THAT OUTCOME IS DECLARED HERE AS A LIVE AND LIKELY RESULT**, so that arriving at it reads
as the rule working rather than as a failure to find something.

---

## 2. THE CANDIDATE STRUCTURES, FIXED BEFORE ANY IS BUILT

- **(A) TWO PARALLEL FIRST-ORDER COMPARTMENTS** — fast (hours) and slow (days–weeks), each
  with its own fraction and time constant. **Four new parameters.**
- **(B) ONE COMPARTMENT WITH CAPACITY-LIMITED BINDING** — saturable, which is what the
  glycosaminoglycan literature actually describes. **Two new parameters** (capacity,
  affinity).
- **(C) SCOPE THE EXISTING COMPARTMENT TO THE ACUTE PROCESS** — keep one first-order store,
  re-value its time constant to the **hours** Olde Engberink measures, and declare the
  ~6-day and monthly rhythms **explicitly out of scope** with the reason on the record.
  **No new parameters.**
- **(D) REMOVE THE COMPARTMENT** and attribute the acute dissociation elsewhere.

### 2.1 THE DISCRIMINATORS, AND ONE PAIR IS NOT DISTINGUISHABLE AT ALL

**(B) against (C): DOSE-DEPENDENCE.** A capacity-limited store **saturates**, so a larger
load gets proportionally *less* buffering; a linear store does not. Drummer gave **30
mL/kg of isotonic** saline and Olde Engberink **5 mmol Na⁺/L TBW of 2.4%** — different
sizes and different tonicities. **If the buffered fraction differs between them beyond what
tonicity explains, that is evidence for (B).** It is weak evidence — two studies, two
groups — and it is the only dose-dependence available.

**(A) against (C): NOTHING THIS MODEL RUNS CAN TELL THEM APART.** The slow compartment's
signature is **rhythmicity at fixed intake**, and this model has no machinery to generate an
infradian rhythm and no protocol longer than the 30-day salt step in which one would show.
**Adding two parameters that nothing can test is what directive 1.10 and ADR 0006's tiers
exist to prevent**, and a pass that picks (A) because it sounds most physiological has
ignored both.

**So the burden is asymmetric and it is set now: (A) must be justified by something the
model can MEASURE, not by the literature's richness.**

---

## 3. THIS PASS MAY SWEEP A NATRIURETIC GAIN, AS A DIAGNOSTIC AND NOT AS A CHANGE

Every pre-registration since §3.49 has forbidden it, because §3.49 withdrew a published
conclusion for reading a water defect as a sodium one. **That error is now understood
rather than merely avoided, and §1 shows the question cannot be answered without it.**

**THE LICENCE IS NARROW:**

- a combined sweep of **store parameters × natriuretic gain** may be run **to answer
  whether any configuration satisfies both of Drummer's half-lives and the chronic
  window**;
- **no gain may be adopted.** `CV.ANP.NATRIURETIC_GAIN` and `RN.PRESSURE_NATRIURESIS.SLOPE`
  end this pass at the values they start it with, whatever the sweep shows;
- **the chronic salt sensitivity is reported at every point**, and a configuration that
  leaves 1.70–2.30 is reported as failing regardless of what it does to Drummer;
- **Jensen is reported at every point** and never fitted.

**If the sweep finds a configuration that satisfies everything, that is a finding to report
and to pre-register a separate pass for — not to merge here.**

---

## 4. WHAT MAY NOT MOVE

- **`RN.ANP.TAU`.** §3.46 proved the lag cannot reach the target at any value.
- **`BF.NA.OSMOTICALLY_INACTIVE_FRACTION` and `BF.NA.STORAGE_TAU` may not take stage 1's
  diagnostic values.** 0.40 and 0.05–0.25 d are what the model needs to reproduce Drummer.
  **If (C) is adopted, the time constant comes from Olde Engberink's 2–4 h as an ORDER OF
  MAGNITUDE at one significant figure**, or the row stays `assumed`. §3.51 established that
  the existing 7 d is wrong in kind; replacing it with a fitted number would be worse than
  leaving it.
- **`storage` may not become `true` by default in this pass.** That is ADR 0004's status
  decision and it needs the structure settled first.
- **`dMAP/dV_ecf` inside 2.82–4.02**, resting state unchanged, and the operating point
  identical with the store at its steady state.

---

## 5. DIRECTIVE 1.12 — AND THE HAZARD IS A PREFERENCE, NOT A NUMBER

**"The real system has multiple compartments, so the model should."** It is true and it is
not a reason. This repository's rule is that structure earns its place by being testable,
and §2.1 says (A) is not — **in this model, on the protocols it runs.** That is a statement
about the model's reach, not about physiology, and the write-up must say which.

Round numbers, listed: **7 days**, **0.15**, **two-thirds**, **6 days**, **4 hours**.

---

## 6. THE DECISION RULE

- **X1 — (C), and the combined sweep shows nothing satisfies both half-lives and the
  chronic window.** Adopt the scope decision, re-value the time constant from Olde
  Engberink as an order, record the rhythms as out of scope, **and report the impossibility
  as the pass's main result.** §1 says this is the expected branch.
- **X2 — (C), and the sweep DOES find a satisfying configuration.** Report it in full,
  adopt nothing, and pre-register the follow-up. **The gain stays where it was.**
- **X3 — the dose-dependence test supports (B).** Then build it **only if the capacity and
  affinity can be sourced**, not fitted. If they cannot, record that (B) is indicated and
  unsourceable, and fall back to (C) with that on the record.
- **X4 — (A) is indicated by something the model can measure.** §2.1 says nothing currently
  can, so this branch requires naming the measurement first. **Build only then.**
- **X5 — (D).** If the combined sweep shows the store contributes nothing that another
  mechanism does not, say so and propose removal. **ADR 0004 would then need retiring, not
  amending**, and that is the owner's decision rather than this pass's.
- **X6 — anything leaves its band.** Stop.

---

## 7. THE FALSIFIABLE TESTS

1. **The combined sweep is reported in full**, store parameters × gain, with chronic salt
   sensitivity and Jensen at every point — including the region that fails.
2. **Both of Drummer's half-lives are reported separately, not only their ratio.** §3.50's
   lesson: the ratio is reachable while both half-lives are wrong.
3. **The chronic salt sensitivity stays inside 1.70–2.30 in anything adopted**, and any
   configuration outside it is labelled as failing however good its acute behaviour.
4. **Jensen's final window before and after**, unfitted.
5. **If (C) is adopted, the time constant's provenance is Olde Engberink's measured
   timescale and the note says it is an ORDER**, with the ~6-day and monthly rhythms
   recorded as out of scope and why.
6. **The operating point is unchanged** and the store contributes nothing at the reference,
   demonstrated by running.
7. **The dose-dependence comparison is reported even though it is weak**, with its weakness
   stated — two studies, two groups, two tonicities.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Building (A) because it is the most physiological.** §2.1: nothing this model runs
distinguishes it from (C), and four untestable parameters is what ADR 0006's tiers and
directive 1.10 exist to stop.

**Adopting a natriuretic gain.** §3 licenses the sweep and forbids the adoption, and the
distinction is the entire reason the licence is safe to grant.

**Re-valuing the time constant from stage 1's 0.05–0.25 d.** It is the model's requirement,
not a measurement. Olde Engberink or `assumed` — nothing else.

**Reporting the ratio and not both half-lives.** §3.50 already produced a configuration
where the ratio was right and neither half-life was, and a pass that repeats that
presentation has learned nothing from it.

**The quiet one: treating §1's impossibility as a failure to find something.** If no
configuration satisfies Drummer and the chronic window together, **that is the result** —
it says the model's acute and chronic constraints are in genuine tension, which is a claim
about the model and worth more than a fitted compartment.
