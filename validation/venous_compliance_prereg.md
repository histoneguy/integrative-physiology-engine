# Pre-registration: the filling relation, sourced as a characterised relationship

**Written 2026-08-24, BEFORE any paper was opened.**
Seventh in the series. **The first written under directive 1.7**, and the first to source
a *relationship* rather than a quantity.

Serves item 0 of `HANDOVER.md` §6 and the 2026-08-24 addendum to
`docs/adr/0011-cardiac-output-hr-sv.md`. Supersedes nothing: `sv_filling_prereg.md`
stands as executed, and its Q3 result is untouched. What is re-aimed is the search.

---

## 0. TWO THINGS MEASURED BEFORE SEARCHING, AND ONE HAZARD

### 0.1 The salt step moves blood volume by 2.7%, and that reframes the whole question

Measured on the current model before writing this, because the range a curve must be
characterised over is not something to guess at:

| intake (mEq/d) | `V_ecf` (L) | `V_blood` (L) | `V_central` (L) | MAP |
|---|---|---|---|---|
| 205 | 14.5600 | 5.0000 | 1.2500 | 93.000 |
| 154 | 14.3669 | 4.9337 | 1.2334 | 90.534 |
| 103 | 14.1737 | 4.8674 | 1.2168 | 88.066 |

**The entire 103 → 205 mEq/day salt step displaces 0.133 L of blood volume - 2.7%.**
Central volume moves 0.033 L.

Over an excursion that narrow, **any smooth curve is indistinguishable from its own
tangent.** So the concavity ADR 0012 requires is real physics that is *operationally
irrelevant to the perturbation this model runs.* The incumbent linear form is adequate
for the salt step, and always was.

That is not a reason to drop concavity. It relocates where it matters:

- **Within an individual**, across a salt step: ±1.3% of blood volume. Curvature
  invisible.
- **Across a population**, which is the stated primary workload of `src/ensemble.jl`:
  `CV.BLOOD_VOLUME.NOMINAL` is 5.0 L with SD 0.6, so virtual individuals at ±2 SD span
  **3.8 to 6.2 L - roughly ±12%, about nine times the within-individual excursion.**

**On a concave curve, individuals at different blood volumes have different local slopes,
so heterogeneity in salt sensitivity arises partly from curvature and not only from
parameter spread.** That is a population-simulation question and it is the reason to
source a curve at all.

**Declared consequence:** the range to characterise is the **population** range of blood
volume, not the salt-step range. A source that only spans a few percent around normal
cannot answer this, however well it is done.

### 0.2 Over-rotating on directive 1.7 is a live risk, and is declared against here

1.7 was issued because the previous search returned only studies where the relationship
was the instrument. The failure mode of a new rule is applying it as a proxy: rejecting
work because it is recent, or accepting work because it is old.

**The test is design intent, not age.** Worked example fixed in advance: human mean
circulatory filling pressure obtained by inspiratory-hold manoeuvres is recent work, and
it **qualifies** - it was designed to characterise the pressure-volume relationship
itself. Conversely an old paper validating a dye-dilution method against another method
does **not** qualify, however venerable.

Directive 1.5 is untouched: an old classic is not quotable from memory, and nothing here
is recorded without opening it.

### 0.3 THE SELECTION HAZARD, AND IT IS THE SHARPEST YET

Every previous pre-registration risked selecting a *value* to match an incumbent. **This
one risks selecting a SHAPE that a live ADR requires.** ADR 0012 needs the filling
relation to be concave; if it is linear over the population range, ADR 0012's resolution
of the posture gradient fails.

**Declared now: a linear finding is a real result, and it is the more consequential one.**
It would mean the partition does not explain the posture gradient after all, and that
something else does - venous tone, sympathetic state, or the gradient not being real.
Report it, amend ADR 0012, and do not go looking for a more curved source.

---

## 1. WHAT IS BEING EXTRACTED

The model needs `SV ~ g(V_central)`. Physiologically that composes two characterised
relationships, and they are sourced separately.

| # | Relationship | Direction | Becomes a ledger parameter? |
|---|---|---|---|
| Q1 | Blood volume → mean circulatory filling pressure. Systemic vascular compliance, and whether it is linear over the population range. | volume → pressure | **Yes** |
| Q2 | Filling pressure → stroke volume or cardiac output. The cardiac function curve, and **its shape**. | pressure → flow | **Yes** |
| Q3 | Stroke volume against central blood volume directly, if anyone has characterised it in one step. | volume → flow | **Yes**, and it would supersede composing Q1 and Q2 |

**Composition rule, fixed in advance.** `g` is concave if Q2 is concave and Q1 is linear
or concave. If Q1 turns out **convex** - stiffening at higher volume, which is
physiologically plausible for a distended vascular bed - the two curvatures oppose and
`g` may be linear or convex. **Compose them explicitly and report the composed shape; do
not assert `g`'s shape from Q2 alone.**

---

## 2. SEARCH STRATEGY - RELATIONSHIPS, NOT VARIABLES

Directive 1.7. Search terms are shaped like the physiology:

- Q1: mean circulatory filling pressure; mean systemic filling pressure; vascular
  capacitance; venous compliance; unstressed volume; pressure-volume relationship of the
  systemic circulation.
- Q2: cardiac function curve; ventricular function curve; Frank-Starling relationship;
  stroke volume against right atrial or central venous pressure; preload recruitable
  stroke work.
- Q3: stroke volume against central blood volume; central blood volume and cardiac
  output.

**Not** `"stroke volume" AND "blood volume"`, which is what returned a set of device and
index papers last time.

---

## 3. INCLUSION AND EXCLUSION

**The directive 1.7 test, applied to every candidate and recorded in one line:**

> If the physiology had come out differently, what would this paper's conclusion have
> been?

- **INCLUDE** if the answer concerns the relationship itself.
- **EXCLUDE** if the answer concerns a device, an index, a drug, a fluid, a clinical
  protocol or a diagnostic threshold. The relationship is then the instrument.

**This exclusion may not be relaxed if the yield is thin.** A thin yield is a result -
see stop condition 5.

**Further requirements:**

1. The relationship must be characterised over **more than two points**. Two points are a
   slope, and a slope cannot answer a question about shape.
2. The **range** must be stated, and must be wide enough to bear on ±12% of blood volume.
3. Species recorded. Mean circulatory filling pressure classically requires circulatory
   arrest and is not performable in humans by that route, so animal data is legitimate
   here under directive 1.6 and ADR 0006 E2 - **with preparation and tested range
   recorded**, and with a statement of *why* no human measurement exists by that method.
4. Preparation recorded: intact, open-chest, areflex, ganglion-blocked. Reflex state
   changes vascular capacitance, so an areflex preparation and an intact one are not
   measuring the same curve.

---

## 4. INDEPENDENCE

Reports from the same laboratory on the same preparation count once. Reviews are used to
find primaries and are not counted as studies. **Where a review and its primaries
disagree, `pooling.md` says the primaries win** - and that has already fired once in this
repo, on Epstein's 2.5-3x immersion range.

---

## 5. THE RANGE, FIXED IN ADVANCE

Characterisation must span, at minimum, blood volume from **0.9 to 1.1 of the nominal
operating point**, and preferably 0.75 to 1.25. Sources spanning less are recorded as
range-limited and **may inform the slope but may not be used to claim a shape.**

Where a source reports volume as a percentage change rather than absolute litres, the
percentage governs; do not convert through an assumed nominal blood volume, which is the
unsourced-scaling failure that falsified ADR 0010's input link.

---

## 6. POOLING RULES

**Shape (Q1 and Q2):** not a poolable quantity. The finding is qualitative - linear,
concave, convex - and requires **agreement across at least two independent groups** in
the same direction before it may inform ADR 0012. Disagreement is recorded as
disagreement and not resolved by majority.

**Slope or compliance value:** `pooled-inverse-variance` where SD and n allow, otherwise
`pooled-n-weighted`, otherwise `pooled-unweighted`. **Not geometric** - a compliance is a
physical quantity in mL/mmHg, not a dimensionless multiplier. Declared now so the rule
cannot be chosen after seeing the spread.

**Never pool across preparations** - intact and areflex are different curves - or across
species. Both are already prohibited by `pooling.md`; restated because this literature
mixes them heavily.

---

## 7. STOP CONDITIONS

1. **k < 3 independent sources for any pooled numeric value means no parameter is
   recorded.** `G_vr` and `G_vc` stay as they are. "Blocked, and here is what is missing"
   is an acceptable outcome and has been the outcome of three of the previous six.
2. **No citation is recorded without opening it.** Authors, journal, year, volume, pages
   verified against the retrieved record.
3. **No fitted or assumed value substitutes for a missing one.** `G_vr` entered this repo
   that way and is still here.
4. **The result may not be selected for agreement with the incumbent, nor for
   concavity.** §0.3. Comparison against `G_vr = 2880 (L/day)/L` is made once, after
   pooling is complete.
5. **A thin yield after the 1.7 exclusion is a result, not licence to relax it.** If the
   admissible literature is empty, the finding is that this relationship has not been
   characterised in a form the model can use, and that goes back into ADR 0011.
6. **Sourcing does not license changing the code.** ADR 0012 stage 1 is inert and stays
   inert until a component change is separately decided.

---

## 8. WHAT WOULD FALSIFY THE APPROACH

**If Q1 and Q2 have been characterised only in preparations whose reflex state differs
from the model's**, then the composed `g` describes a preparation and not an intact
human, and the honest outcome is to say so rather than to compose it anyway. The model
has a baroreflex (ADR 0009); an areflex dog curve is not the curve the model sits on.

**If the composed `g` is linear over the population range**, ADR 0012's resolution of the
posture gradient fails and must be amended - see §0.3. The partition itself is not
thereby refuted; only the claim that partition-plus-curvature explains the gradient.

**If the population range turns out not to be the right frame** - for instance if
individual differences in blood volume are accompanied by proportional differences in
compliance, so that everyone sits at the same relative point on their own curve - then
curvature does not generate heterogeneity in salt sensitivity after all, and §0.1's
argument for sourcing a curve collapses. **This is the most likely way this whole
pre-registration turns out to be aimed at nothing**, and it is written down first so that
it is checked rather than discovered late.
