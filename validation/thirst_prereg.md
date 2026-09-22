# Pre-registration — osmotic thirst

**Written 2026-09-21, before any source is opened and before any search has been run for
these values.** Verify the ordering with

    git log --diff-filter=A -- validation/thirst_prereg.md

At the owner's instruction, after ADR 0029 found the absence.

---

## 0. WHY, AND IT IS NOT ABOUT GLUCOSE

ADR 0029 made glucose an osmole and then could not produce the thing hyperglycaemia is
famous for. **`BF.H2O.INTAKE_NOMINAL` is a fixed 2.5 L/day, `assumed`, citation "Convention
pending primary source"** — so at steady state urine volume is pinned at intake minus losses
and stays at **1.70 L/day at every glucose concentration the model can reach**. The osmotic
load appears as urine *concentration* instead, 547 → 728 mOsm/kg: right direction, wrong
variable.

**THE DEFECT IS GENERAL AND GLUCOSE ONLY EXPOSED IT.** Every osmotic challenge this model
will ever run — hyperglycaemia, a high-protein diet, mannitol, diabetes insipidus, salt
loading — is one a person answers by **drinking**. Without thirst the model answers all of
them by concentrating urine and none by making more of it. `OPEN-QUESTIONS` B18.

**AND THE AFFERENT IS ALREADY BUILT.** `Osm_ecf` is computed in `BodyFluids` and `Adh.jl`
already reads it. What is missing is one efferent.

---

## 1. THE CONSTRAINT THAT DECIDES THE FORM, FOUND BEFORE WRITING ANYTHING

**`H2O_intake` IS A PROTOCOL INPUT.** `validation/challenges.jl` sets it directly — Lobo's
saline infusion and the fluid-deprivation case both override it. A thirst term that
*replaces* intake would silently break every protocol in the harness.

**So thirst ADDS:**

    H2O_intake_total = H2O_intake + thirst

with `thirst` **exactly zero at the operating point**, the discipline `fr_mod`, `vn_sig` and
`md_drive` are all already wired under. Every existing challenge is then bit-identical by
construction rather than by inspection, and §5 test 2 asserts it rather than assuming it.

---

## 2. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED BEFORE SEARCHING

- The thirst threshold **"295 mOsm/kg"**, and the teaching claim that it is **higher than
  the vasopressin threshold** so that "you concentrate urine before you get thirsty".
- **"1% change in plasma osmolality"** as the trigger.
- Daily water intake **"2.5 L"**, or **"8 glasses"**.
- A thirst **"slope"** quoted without the scale it was measured on.

**THE SECOND ONE IS A CLAIM, NOT A NUMBER, AND IT IS THE INTERESTING ONE.** If the two
thresholds turn out to be the same, the tidy textbook ordering is wrong and this model would
have inherited it by accident. **Recorded before looking.**

---

## 3. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults, euhydrated at baseline, **hypertonic saline infusion** with
thirst rated on a scale whose endpoints are stated, and plasma osmolality measured
concurrently. This is the same paradigm `ADH.OSM.THRESHOLD` already comes from, so the two
rows will be on the same scale by construction — which is §3.26's lesson applied in advance
rather than after.

**Exclude:** diabetes insipidus and hyponatraemia cohorts for anything setting a NORMAL
threshold; the elderly as a *source* of the normal value, because thirst sensitivity is
known to fall with age and this model has no age dimension; exercise and heat-stress
protocols, where thirst is confounded by volume and temperature.

**PREFER THE GROUP THAT OWNS THE PHYSIOLOGY.** `ADH.OSM.THRESHOLD` and
`ADH.OSM.SENSITIVITY` are already Baylis's. If the same group measured thirst by the same
method, that is the source, and the two rows then compose without a conversion.

---

## 4. WHAT MAY NOT MOVE

- **`ADH.OSM.THRESHOLD` and `ADH.OSM.SENSITIVITY`** — Baylis, settled, and a thirst pass
  must not re-tune the vasopressin limb to accommodate itself.
- **`BF.H2O.INTAKE_NOMINAL` stays 2.5 L/day and stays `assumed`.** Thirst adds to it; it is
  not re-solved, and if a sourced intake ever lands that is a different pass.
- **`BF.OSM.PLASMA_SETPOINT`, `BF.NA.PLASMA_SETPOINT`** — and B19 already records that they
  do not compose. **This pass may not "fix" that by moving either**, because a thirst
  threshold is measured on the same osmolality scale and would inherit the discrepancy
  either way.
- **`RN.URINE.SOLUTE_LOAD`, the glucose rows, every renal row.**
- **The resting operating point**, to the precision it is currently pinned at.
- **No band, pin or tolerance widened.**

---

## 5. THE FALSIFIABLE TESTS

1. **`thirst` is exactly zero at the operating point**, and the resting state is unchanged —
   MAP, plasma sodium, osmolality, urine volume, `Na_excr`.
2. **EVERY EXISTING CHALLENGE IS UNCHANGED**, asserted by running the whole harness, because
   thirst is zero wherever osmolality is at its setpoint.
3. **THE PREDICTION: hyperglycaemia now produces POLYURIA.** At reduced glucose disposal the
   model must make *more urine*, not merely more concentrated urine. Reported as urine
   volume against glucose, and it is the reason this pass exists.
4. **Fluid deprivation** — the harness case that overrides `H2O_intake` — must still behave,
   and thirst must not silently undo the deprivation. **This is the test most likely to
   catch a wiring error**, because it is the one protocol that deliberately fights the new
   term.
5. **The osmotic threshold ordering**, reported: is the model's thirst threshold above,
   below or equal to its vasopressin threshold, and does that match the source rather than
   the textbook?
6. **Chronic salt sensitivity, Jensen, Lobo and the renin ratio**, reported unchanged.

---

## 6. THE DECISION RULE

- **T1 — a threshold and a slope both source in healthy adults by hypertonic infusion.**
  Build it. This is the expected outcome and the literature exists.
- **T2 — the threshold sources but the slope does not.** Build thirst as a rectified
  proportional term with the slope **derived from the steady-state water balance** — the
  intake that closes the balance at the threshold — and say plainly that the gain is an
  identity rather than a measurement.
- **T3 — only elderly or patient cohorts are available.** Record as INDETERMINATE per
  §3.33, build nothing, and leave B18 open with the search terms written down.
- **T4 — thirst turns out to be measured on an unstated scale**, as Zanetti's M was.
  **Do not infer it.** Same rule, same reason.

---

## 7. WHAT WOULD MAKE THIS PASS A FAILURE

**Letting thirst replace `H2O_intake` rather than add to it.** §1. It would break the
harness silently, which is the failure mode this repository keeps catching.

**A thirst term that is non-zero at rest.** Then the operating point moves and the model has
been re-tuned, not extended.

**Tuning the slope to make ADR 0029's polyuria appear.** Test 3 is the prediction; a gain
chosen to produce it is not a prediction. If the sourced slope gives too little polyuria,
**that is the result.**

**Reporting the textbook threshold ordering** if the source disagrees with it. §2 wrote the
claim down first for exactly that reason.

---

## 8. AMENDMENT — THE POOLING RULE, DECLARED BEFORE ANY SECOND SOURCE IS OPENED

**Appended 2026-09-21 at the owner's instruction: gather multiple sources and pool them
rather than settling for one.** `validation/pooling.md` is binding and says the rule must be
fixed **before** extraction, because a rule chosen after seeing the numbers is
unfalsifiable. Thompson 1986 has been read (§9.1); **no further source has been opened at
the time of writing this section.**

### 8.1 The rule, in `pooling.md`'s own order of preference

1. **`meta-analysis`** if one exists that has already pooled osmotic thirst thresholds with
   a stated method. Take its estimate and its dispersion; do not re-pool.
2. **`pooled-inverse-variance`** if the primary studies report a threshold with a dispersion
   and an n.
3. **`pooled-n-weighted`** if they report a threshold and an n but no dispersion.
4. **`pooled-unweighted`** if neither.
5. **`single-source`** if Thompson turns out to be the only admissible study — **and then
   the row says so and is not dressed as consensus.**

**`range-midpoint` IS PROHIBITED**, and so is reaching for a review's quoted span instead of
its constituent papers.

### 8.2 What may NOT be pooled, and this matters more here than usual

- **NOT ACROSS SPECIES.** Rat and dog osmotic thirst literature is large and older than the
  human work. Averaging it in would produce a number describing no organism.
- **NOT ACROSS MEASUREMENT METHODS.** The threshold must come from **hypertonic saline
  infusion with concurrent plasma osmolality**, which is the paradigm `ADH.OSM.THRESHOLD`
  already uses. Water-deprivation and oral-loading protocols measure something related on a
  different axis and are excluded from the pool — `pooling.md` prohibits mixing
  `extraction_method`s, and §3 of this pre-registration already fixed the paradigm.
- **NOT ACROSS AGE.** Thirst sensitivity falls with age and this model has no age dimension;
  elderly cohorts are excluded from the pool and recorded if found.

### 8.3 What the pool changes downstream, stated now

The threshold enters the derived gain as `k = intake / (Osm_setpoint − threshold)`. **That
denominator is a DIFFERENCE of two numbers close together, so it amplifies error**: at 287,
a threshold of 281 gives 6 mOsm/kg and one of 284 gives 3, which halves the signal and
doubles the gain.

**THE POOLED THRESHOLD THEREFORE HAS TO BE REPORTED WITH ITS DISPERSION AND THE GAIN'S
SENSITIVITY TO IT SHOWN** — §5 gains a test:

7. **The derived gain across the pooled threshold's own uncertainty interval**, reported,
   with the polyuria prediction recomputed at each end. If the prediction survives the
   interval, it is a result; if it does not, the interval is the finding.

**AND IF THE POOLED THRESHOLD RISES ABOVE 287** the mechanism inverts — the model would rest
below threshold and osmotic thirst could not explain baseline drinking. **That is branch
T5**, added here: report it, and do not move `BF.OSM.PLASMA_SETPOINT` to rescue it, because
§4 already forbids that and B19 already records that the setpoints do not compose.
