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
