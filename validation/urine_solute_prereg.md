# Pre-registration — the urine solute load

**Written 2026-09-16, before any source is opened and before any search has been run
for these values.** Verify the ordering with

    git log --diff-filter=A -- validation/urine_solute_prereg.md
    git log --diff-filter=A -- validation/urine_solute_extract.py

Opened at the owner's instruction as `HANDOVER` §4 item 8: *`RN.URINE.SOLUTE_LOAD =
600 mOsm/day` is the load-bearing unsourced number on the water side.*

---

## 0. THE DEFECT IS NOT THE ONE THE WORK LIST NAMES, AND IT WAS MEASURED

§4 item 8 says the model's solute load is an unsourced 600 mOsm/day. **It is not
600. It is 702**, and finding that out changed what this pass is.

Measured at the reference individual, 60-day run, male, 70 kg:

| quantity | model | the constant it was derived from |
|---|---|---|
| `rn.Osm_load` | **702.0 mOsm/day** | `RN.URINE.SOLUTE_LOAD` = 600 |
| `rn.u_osm` | **412.9 mOsm/kg** | `ADH.URINE.OSM_BASELINE` = 353 |
| `bf.Osm_ecf` | **287.59 mOsm/kg** | `BF.OSM.PLASMA_SETPOINT` = 287.0 |
| `rn.H2O_excr` | 1.700 L/day | intake − insensible = 1.7 ✓ |

`Osm_load = Osm_nonNa + 2·Na_excr`, and `Osm_nonNa = 292` was pinned so the **total
returns 600 at the MID salt arm, 154 mEq/day**. The model's reference is the
**NOMINAL arm, 205 mEq/day**. So `292 + 2·205 = 702`.

**THREE CONSTANTS ARE DERIVED AT A LOAD THE MODEL NEVER OCCUPIES.**
`RN.H2O.OBLIGATORY_LOSS`, `ADH.URINE.OSM_BASELINE` and `ADH.OSM.SENSITIVITY` are all
computed from 600. The last of those is **live** — it is the gain of the entire
osmoregulatory limb — and it is derived by requiring that *at the osmotic setpoint
the model excretes exactly intake minus insensible loss*. At a load of 600 that
holds. At the model's actual 702 it does not: `702/353 = 1.99 L/day` against a
required 1.70.

**The loop pays for it with a permanent offset, and the arithmetic closes exactly:**

    at Osm_ecf = 287.0:  adh = 0.10835·3 = 0.325 → u_osm = 353 → 1.99 L/day  ✗
    the loop must reach  u_osm = 702/1.7 = 412.9 → adh = 0.3895
                         → Osm_ecf = 284 + 0.3895/0.10835 = 287.595

Observed: `adh` 0.3895, `Osm_ecf` 287.592. **The model sits 0.6 mOsm/kg above its own
setpoint for no physiological reason** — only because a derived constant was computed
at the wrong operating point.

### AND `check_closure.py` PASSES, BECAUSE IT CHECKS THE SAME WRONG NUMBER

    check("water out at the osmotic setpoint", solute / u_base_from_adh, v_base, ...)

with `solute = p["RN.URINE.SOLUTE_LOAD"]` = 600. It reports `1.699 vs 1.7` and passes.
**The composed chain it certifies is not the chain the model runs.** That is precisely
the defect §3.8's own comment names — *a gate must assert what the code does* — and it
is the second time a closure check has certified an expression the component no longer
evaluates.

### WHERE THE 154 CAME FROM, AND WHY IT IS STILL THERE

`RN.URINE.SOLUTE_NONNA`'s note says it plainly: pinning at the mid arm *"achieves
that: the mid arm is unchanged to the last digit and only the high and low arms
move."* **That was change-management, not physiology** — a way to introduce solute
tracking without moving the salt step. It worked, and it then became the reference
point for three derived constants, none of which the model occupies.

---

## 1. SO THIS PASS HAS TWO HALVES AND THEY MUST NOT BE CONFUSED

**HALF A — THE REFERENCE-POINT DEFECT. It needs NO source and it is a bug.** One
operating point, used everywhere: the constants derived from the solute load must be
derived at the load the model actually has. This is fixable today and **must be
delivered even if the search returns nothing** (branch U5).

**HALF B — THE SOURCING. `RN.URINE.SOLUTE_LOAD` is `assumed`, tier C, no citation.**
Whatever it becomes, Half A is what makes it land where it is stated.

**THEY MUST BE MEASURED SEPARATELY.** Fixing the reference point moves results on its
own; sourcing the load moves them again. Doing both and reporting one number is how a
pass makes itself unfalsifiable. **The extract must report the two deltas apart.**

---

## 2. THE QUANTITIES

| id | what | role |
|---|---|---|
| `RN.URINE.SOLUTE_LOAD` | 24 h urinary osmolar excretion | **the row this pass exists to source** |
| `RN.URINE.SOLUTE_NONNA` | the non-sodium residual | derived; carries every incoherence |
| `RN.H2O.OBLIGATORY_LOSS` | load ÷ maximal concentration | derived |
| `ADH.URINE.OSM_BASELINE` | urine osmolality of the disabled branch | derived |
| `ADH.OSM.SENSITIVITY` | `k_adh`, the osmoregulatory gain | **derived, and LIVE** |
| `RN.URINE.OSM_PER_K` | mOsm per mmol of urinary potassium | entered **only** under U4 |
| `ADH.URINE.OSM_MIN` | minimal urine osmolality | `assumed` at 50, **out of scope here** |

---

## 3. THE COHERENCE CONSTRAINT, AND IT IS THE SHARPEST THING IN THIS DOCUMENT

**THE URINE SOLUTE LOAD IS NOT A PHYSIOLOGICAL CONSTANT. IT IS A DIET.** Urea tracks
protein intake, the cation terms track salt and potassium intake. A number extracted
from a cohort eating differently from the cohort `BF.NA.INTAKE_NOMINAL = 205 mEq/day`
came from is **not a measurement of the same person**.

**And the mismatch does not announce itself — it lands entirely in the residual**,
which is already carrying inherited debt its own note describes as *"almost certainly
TOO LOW."* Sourcing a total from a low-salt cohort would silently inflate the
non-sodium term to compensate, and every gate would stay green.

**THEREFORE, FIXED BEFORE SEARCHING: an admissible source must report urinary SODIUM
in the same subjects over the same collection**, so that
`residual = total − 2·Na_urine` can be computed *within the source* and compared with
what the model needs. If it cannot, the row is enterable only under U2 and the
residual stays tier C with the mismatch stated.

**THE PREFERRED SOURCE IS NAMED IN ADVANCE, AND SO IS WHY.** `Rakova N et al. Cell
Metab 2013;17(1):125-131` is **already in this ledger** — `BF.NA.INTAKE_MID` is
derived from its 9 g/day NaCl protocol level. A balance study with controlled sodium
and complete 24 h collections is exactly the preparation this row needs, and taking
both rows from one cohort satisfies §3.24's same-cohort rule **by construction rather
than by luck.** Declared now so it cannot later look like a convenient find.

**What would disqualify it, also declared now:** it is a long-duration isolation study
in **six men**. If it reports osmolar excretion only under a salt protocol with no
free-diet arm, or if n and sex cannot support a population value, it is corroboration
and not the primary. **A source is not admissible because it is already cited here.**

---

## 4. DIRECTIVE 1.7 — AND THE PREDICTION IS THAT IT BITES FOR THE TENTH SUBSYSTEM

24 h urine solute exists in the literature overwhelmingly as:

- **kidney-stone risk profiling** — solute and volume are the instrument for predicting
  stones, and the cohorts are selected on having formed them;
- **hydration-intervention trials** — water intake is manipulated and solute excretion
  is the covariate, in cohorts selected as low drinkers;
- **spot urine surveys** — NHANES-style single samples, which are not 24 h collections
  and cannot give a daily load.

**Prefer studies whose subject is the excretion itself**: balance studies, metabolic
ward protocols, and complete-collection cohorts validated by creatinine. **Record the
diet.** And **other whole-body models are not sources.**

---

## 5. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED IN ADVANCE

Solute load **600 mOsm/day**. Maximal urine osmolality **1200 mOsm/kg** — already
caught once in this repository and replaced with a measured 982. Minimal **50**.
Water intake **2.5 L/day**. Insensible loss **0.8 L/day**. Urine **1.5 L/day**.
Obligatory urine **500 mL/day**. **All are teaching figures.** This repository's record
on such numbers is four materially wrong of six openable in the `VERIFY` class, and
three of the six above are still `assumed` rows in this ledger today.

---

## 6. WHAT IS ALREADY KNOWN, DECLARED SO THE FREEDOM IS AUDITABLE

- The four measured values in §0, and the offset arithmetic that closes to three
  decimal places.
- `RN.URINE.SOLUTE_NONNA`'s own note: *"292 mOsm/day is almost certainly TOO LOW …
  typical measured totals are 700–900"*, and that urea is normally the largest single
  contributor with potassium salts adding roughly 100–120 mOsm/day.
- **The model already computes urinary potassium**: `kp.K_excr` = 61.0 mmol/day. At the
  charge-balance coefficient that is ~122 mOsm/day, and it is currently buried inside
  the constant residual. Directive 1.11 is pointing straight at it.
- `RN.URINE.OSM_PER_NA = 2` is sourced from **Imamura 2013, whose estimator carries no
  potassium term at all** — `1.07·(2·[Na] + [ureaN]/2.8 + [creatinine]·2/3) + 16`.
- `ADH.URINE.OSM_MAX = 982` (Tryding) and `ADH.OSM.THRESHOLD = 284` (Zerbe) are sourced
  and are **not** in play.

---

## 7. WHAT THIS PASS MAY NOT DO

- **It may not move the reference water balance.** 2.5 L/day in, 0.8 insensible,
  **1.7 L/day out**. That is conservation, not a fit, and it must hold before and after.
- **It may not move `ADH.URINE.OSM_MAX` or `ADH.OSM.THRESHOLD`.** Both sourced.
- **It may not touch the sodium limb.** `BF.NA.INTAKE_NOMINAL`, the salt arms, `G_pn`,
  `G_anp` — none of them.
- **It may not change `RN.URINE.OSM_PER_NA`.** The absolute sensitivity of the solute
  load to sodium is 2 mOsm/mEq and is sourced. **Only the constant part may move.**
- **It may not fit `k_adh` to remove the osmolality offset.** `k_adh` is DERIVED; the
  offset must vanish because the derivation is done at the right load, not because the
  gain was tuned until it did. Fitting it would be §3.15's error committed on purpose.
- **It may not let the residual absorb a cohort mismatch silently.** §3.
- It may not enter a value from an abstract where the full text is obtainable, and must
  label the reading level of every source.

---

## 8. THE DECISION RULE

- **U1 — a 24 h osmolar excretion in healthy adults sources WITH urinary sodium in the
  same subjects.** Enter it. Re-derive the residual against `BF.NA.INTAKE_NOMINAL`
  (**205**, the reference — not the mid arm), re-derive `RN.H2O.OBLIGATORY_LOSS`,
  `ADH.URINE.OSM_BASELINE` and `k_adh` **at the reference load**, and fix the closure
  check to assert the model's own `Osm_load`.
- **U2 — the total sources but urinary sodium does not.** Enter it, and the residual
  **stays tier C** with the unverifiable diet stated on the row. The coherence check of
  §3 cannot be run and the row must say so.
- **U3 — only urine osmolality and volume separately.** Their product is admissible
  **only** from the same subjects over the same collection, and the row records that it
  is a product of two reported means and therefore carries both their errors.
- **U4 — urinary potassium also sources, in the same subjects.** Build the explicit
  potassium term, `Osm_load = 2·Na_excr + osm_K·K_excr + Osm_other` — **but only with a
  source in the `2·(Na+K)` estimator family.** `RN.URINE.OSM_PER_NA` came from an
  estimator with no potassium term, and carrying its coefficient across to potassium
  would be attributing to Imamura something Imamura does not contain. **AND the residual
  must fall by exactly the potassium contribution at the reference**, or the total moves
  and the pass has double-counted — §5 item 22, in a component where it would be silent.
- **U5 — nothing admissible.** Record INDETERMINATE with the exact search terms per
  §3.33, **and still deliver Half A.** The reference-point defect is a bug, not a
  sourcing question, and it is fixed whatever the search returns.
- **U6 — the sourced total is so large that `RN.H2O.OBLIGATORY_LOSS` approaches the
  reference urine volume of 1.7 L/day.** Stop. Either the maximal concentrating ability
  or the load is wrong, and entering both would put the model permanently near its
  concentrating limit with no room to respond.

---

## 9. THE FALSIFIABLE TESTS ANY RESULTING RECORD MUST INHERIT

1. **The reference water balance is unchanged at 1.7 L/day out.** Conservation. It held
   before and it must hold after, whatever the load becomes.
2. **The model rests AT its osmotic setpoint.** `bf.Osm_ecf` returns 287.0 to within
   solver tolerance instead of sitting 0.6 mOsm/kg above it. **This currently fails and
   is the reason Half A exists.**
3. **`check_closure.py` composes the chain the model actually runs.** The water-balance
   check reads the reference `Osm_load`, not a stated constant, and **it must fail if
   reverted to the present form.**
4. **Antidiuretic activity at rest stays mid-range**, 0.2–0.6, with room to move both
   ways. It is 0.389 now and a larger load pushes it up.
5. **The solute load's sensitivity to sodium is unchanged at 2 mOsm/mEq.** Only the
   constant moves. A pass that changed the slope changed the sourced row.
6. **The obligatory volume stays well below the reference urine volume** and the maximal
   diuresis stays above 10 L/day. Both move; both must stay physiological.

---

## 10. WHAT WOULD MAKE THIS PASS A FAILURE

**Sourcing a total from a cohort on a different diet and letting the residual swallow
the difference.** Every gate stays green — the ledger parses, the closure identities
hold because the residual is *defined* to make them hold, and the suite passes because
the reference water balance is conservation and cannot move. **The residual is where
incoherence goes to hide, and it is already carrying debt its own note admits to.**

**The second failure is reporting one number for two changes.** Half A moves the
operating point on its own. If the extract reports only the post-sourcing state, the
sourcing gets credit for a bug fix and the bug fix gets credit for a source, and
neither can be checked.

**The third is quieter: fixing Half A, finding nothing in the search, and writing the
pass up as though the row had been sourced.** `RN.URINE.SOLUTE_LOAD` is `assumed`
today. Under U5 it is still `assumed` afterwards, and the work list keeps item 8.
