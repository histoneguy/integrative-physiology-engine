# HANDOVER — Integrative Physiology Engine

**Date:** 2026-08-24
**Repo:** https://github.com/histoneguy/integrative-physiology-engine (public)
**Owner:** Eric George (`histoneguy`)
**`main`:** `67ca26c` (ADR 0012), plus the squash of PR #17 which carries this file —
**166/166**, all five provenance gates green, verified locally before the merge

**Supersedes** the handover dated 2026-08-19 and the uncommitted `HANDOVER2.md`
(session 2, which lived only in a downloads folder). Everything still live from both is
folded in below. If you find `HANDOVER2.md` on disk, it is history, not instruction.

---

## 0. THE THING THAT CHANGED

**Claude Code now runs locally on the owner's machine, inside the repo.** Julia 1.12.6,
Python 3.12.10, `git`, and `gh` authenticated as `histoneguy` are all present and
working. The full test suite runs in **~40 s warm**.

    julia --project=. -e "using Pkg; Pkg.test()"

Three sessions of this project were shaped by an assistant that could not execute
anything, sending untested patches to the owner and using him as the test harness. That
constraint is gone. Sections of the old handovers about Julia being uninstallable in a
sandbox, about a domain allowlist request, and about shipping every sprint as a
self-applying `apply-*.py` script are **obsolete**. Do not reinstate that workflow.

**The loop is now: edit, run the gates, run `Pkg.test()`, read the output, commit.**
CI is the receipt, not the loop.

---

## 1. BINDING DIRECTIVES

Set by the owner over several sessions. Several were violated repeatedly before they
stuck. Paraphrased, not quoted — see §7.2 on why this file no longer puts quotation
marks around words without a source to hand.

### 1.1 Give runnable commands, not step-by-step instructions
He directs this work; he is not the one writing the code, and a workflow that turns him
into the executor of multi-step instructions wastes his time and introduces
transcription errors. Do the thing with tools wherever possible. Where he must run
something, hand him one block he can paste and run. Windows and PowerShell: `python`,
not `python3`.

### 1.2 Build physiology, not process
The repo already carries five provenance gates and ten ADRs against five components,
one of which is not even connected. That ratio is already wrong. Do not add tooling
unless something breaks that cannot be worked around.

### 1.3 Well-established relationships first
Build E1 before anything that modulates it. Two structural decisions were already
walked back for violating this (ADR 0004 sodium storage; ADR 0005 circadian, built
before the loop it modulates).

### 1.4 Provenance is the point
Every number enters via `ledger/parameters.csv` with citation, tier, extraction method,
species and uncertainty. Every *equation* now enters via `ledger/relations.csv` too.
Nothing is hardcoded in a component.

### 1.5 Stop working from memory; back up every statement
Issued after two confident assertions about classic curves, both asserted from memory,
both wrong, both in the same direction — each claiming a relationship was nonlinear
when the primary data said linear. **Never write a citation you have not opened.**

### 1.6 Animal data is legitimate evidence — 2026-08-21
Physiologists cannot always experiment on humans to find where a mechanism fails. Some
values are derived from animal models because that is the best evidence obtainable
within the ethical limits of the field. **High-quality published animal data is
acceptable where no definitive human data exists — document where the values, equations
and relationships come from.**

Judge a source on study quality, not species. Record species, preparation and tested
range. State *why* no human study exists — an ethical ceiling and a study nobody has got
round to are different facts, and only the second is debt. This is now encoded in ADR
0006; see §4.

---

## 2. STATE

`main` at `67ca26c` + PR #17. **166/166 in ~60 s warm.** All five gates exit 0.

**The model gained a central/peripheral volume partition on 2026-08-24 (ADR 0012), and
it is the first source change since 21 August.** Everything between was documents: two
ADRs, two pre-registrations, three analysis scripts, ~1,500 lines and zero Julia. That
was not waste — it prevented two wrong components and caught a sign error — but read §6
before adding a third ADR ahead of any code.

### The model — 3 states after `structural_simplify` (`V_icf`, `V_ecf`, `Na_ecf`)

| Component | Status |
|---|---|
| `BodyFluids.jl` | ICF/ECF volumes, sodium mass balance, osmotic equilibration. Inactive-Na storage compartment **default off** (ADR 0004). |
| `Cardiovascular.jl` | Blood volume from ECF, **partitioned into `V_central`/`V_periph` (ADR 0012)**, CO from CENTRAL filling, MAP = CO × TPR. TPR scaled by `tpr_mod`. `f_central` is constant, so the partition is currently a change of variables and nothing else. |
| `Renal.jl` | GFR autoregulation (80–160 mmHg), filtered load, pressure natriuresis. Water excretion still a **placeholder** until ADH. |
| `Baroreflex.jl` | Lumped, resetting. Verified in both directions. |
| `Circadian.jl` | Cosinor clock. **NOT CONNECTED**, default off — build order, not tier. |
| `incoming/Raas.jl` | Written, tested nowhere, **not wired in**. Parked deliberately: the relations gate globs `src/components/*.jl`, so a component parked there reads as undocumented relations. |

### The result, unchanged since the loop first closed

| intake (mEq/d) | MAP (mmHg) |
|---|---|
| 205 | 93.00003751695675 |
| 154 | 90.53356850133511 |
| 103 | 88.06587129611133 |

Shift **4.934166220845427 mmHg**. Arterial pressure is nowhere regulated in this model;
it lands at a stable intake-dependent value through renal–body fluid feedback alone.

**These values were bit-identical across every commit until 2026-08-24, and are no longer.**
The ADR 0012 partition is algebraically an identity but adds two equations, so
`structural_simplify` emits differently ordered arithmetic and the adaptive solver takes
fractionally different steps. Measured deviation: **2.1e-15 to 2.2e-14 relative on the
three levels, 3.5e-13 on the shift** — 1.7e-12 mmHg.

`test/runtests.jl` now pins the table above at **1e-9 relative** rather than by equality.
Do not restore a bit-identity check; it is unachievable across a structural change in an
adaptive solver, and the reason is written up in ADR 0012 falsifiable test 3. The free
integrity check the old bit-identity gave is spent — that is a real loss, and the 1e-9
pin is what replaces it.

### Gates — all in the `Provenance` CI job

| Tool | Purpose |
|---|---|
| `ledger_to_julia.py --check` | numbers: citation, units, tier, method; generated code not stale |
| `check_relations.py --repo .` | **equations**: every `~` relation has a ledger row; empirical ones need a `form_citation` |
| `check_closure.py` | seven derived relationships must stay mutually consistent |
| `check_adrs.py` | evidence tiers; E3 needs a falsifiable test and must default off |
| `fix_deps.py` | `Project.toml` matches actual imports |

**Never rename the `Provenance` job in `ci.yml`.** Branch protection requires that
exact string and a rename once deadlocked every merge.

`check_relations.py` is **forward-only**: eight pre-existing unsourced relations are
grandfathered inside the script and printed as `DEBT`. The list shrinks only — the gate
fails on a new unsourced relation, on an entry no longer in the code, and on an entry
that has since been sourced. Both failure paths were tested before it was wired in.

---

## 3. THE TWO LOAD-BEARING FINDINGS

### 3.1 `G_pn` alone sets salt sensitivity — this corrects the old handover

At steady state excretion equals intake, so

    Na_excr = Na_filtered·(1 − FR_Na) + G_pn·(MAP − MAP_ref)

gives `ΔMAP ≈ Δintake / G_pn`, in which `CV.VENOUS_RETURN.SENSITIVITY` **does not
appear**. Measured: the 205→103 step gives 4.934 mmHg at `G_pn = 20.0` and 15.698 at
`G_pn = 5.43`, while sweeping `G_vr` 2880→600 at fixed `G_pn` moves it only
15.698→12.403 and drives `V_ecf` to 9.889 L, under the 10 L floor.

The previous handover said the two gains "together *are* the loop gain". **They are
not.** They are separately identified — `G_pn` by the pressure shift, `G_vr` by ECF
volume. That is *better* news for estimating them: a joint posterior is tractable rather
than degenerate.

**`RN.PRESSURE_NATRIURESIS.SLOPE` stays at 20.0.** The comparison against Mizelle 1993
puts it 3.68× too steep, and adopting *that* alone forces 15.7 mmHg across a 102 mEq/day
range — salt-sensitive hypertensive behaviour, not normotensive. The decision to stay at
20.0 is unaffected by §3.2; what §3.2 removes is the precision of the 3.68×, not its
sign. Read the ledger note on that row before touching it.

### 3.2 The gap is real, but neither the 3.68× nor the 2.2× is a measured quantity

De Nicola 1997 puts ANP at ~40% of the natriuretic increment. If ANP carries 40% and IPE
lacks it, the pressure term inflates by 1/(1−0.4) = **1.67×**. Set against a nominal
observed inflation of 3.68×, ANP accounts for about 0.39 of it on a log basis, leaving
~2.2×.

**Both figures were audited on 2026-08-22 and neither survives as a point value.**
Reproduce with `python validation/residual_audit.py`; the full write-up is ADR 0010 §6.
The audit reproduces the published 3.6843 and 2.2106 exactly — confirming the derivation
was correctly identified before it was taken apart — and then finds three things:

- **The dog GFR is uncited and the ratio is exactly proportional to it.** The comparison
  is between *fractions of filtered load*, so the dog's filtered load enters as
  `GFR_dog × C_Na`. `validation/pn_data.py` supplies `DOG_GFR = 115.0` L/day from a
  parenthetical, with no citation and none in Mizelle. `inflation = 0.03204 × GFR_dog`.
  115 L/day is 3.99 mL/min/kg — the **top** of the conventional canine range. Across
  2.5–4.5 mL/min/kg the residual is **1.38–2.49×**.
- **Mizelle's own three points disagree by 2.28×.** The adopted slope (1.734
  mmol/day/mmHg per kidney) is one of three defensible readings; the low and high
  segments give 1.280 and 2.917, i.e. residuals of **3.00×, 2.21× and 1.31×**.
  `pn_data.py` already flags the segment disagreement as suggestive of steepening rather
  than evidence of it — the ADR then quoted one reading as if that were settled.
- **A bias never in the comparison at all, pointing the wrong way.** Mizelle's
  low-pressure kidney had ~8% lower GFR (verified against PMID 8319986). IPE's `G_pn` is
  a slope at *constant* filtered load, so the model's parameter carries no filtered-load
  term while Mizelle's raw between-kidney `dUNaV/dRPP` does. Removing it moves the
  inflation **3.68× → 4.32×** and the residual **2.21× → 2.59×**.

Propagated, **the residual is 0.82–3.37×**. That is not a claim it is zero: holding the
adopted slope, erasing it needs a canine GFR of 52 L/day (1.81 mL/min/kg), below the
plausible range. Something is probably there; its size is not known.

**Do not quote 2.2× as a quantity.** The five candidates — NCC downregulation, renal
sympathetic nerves, the dog→human scaling, the original calibration target, the
distal-delivery effect in §5 — remain uninvestigated, and the standing rule against
attributing the residual to any of them without doing the work still holds. But two of
the five are partly *this* arithmetic rather than physiology, and the cheapest next move
is none of them: **open Mizelle 1993 in full text**, read the reported body weights and
absolute GFRs, and recover enough of the dataset to settle the segment question. That
collapses the first finding outright. Only then is a mechanistic hunt worth starting.

---

## 4. ADR 0006 WAS AMENDED — RETROSPECTIVE

The tier table made species a proxy for quality: `species-extrapolated` sat in E3, which
forces default OFF. Taken literally it would have forced ANP to default off because
Seeliger's servo-control is dog, and demoted Roman & Cowley (rat), Mizelle (dog) and
Hall (dog) — the entire primary basis of `Renal.FR_effective`. Meanwhile
`RN.PRESSURE_NATRIURESIS.SLOPE` sat unchallenged labelled `species: human`, when it is
not a human measurement at all but a fitted constant from Guyton 1972.

**The rule protected the fitted number and penalised the measured ones.**

E2 now admits animal data where the human experiment is not ethically performable, with
species, preparation and range recorded. E3 keeps species-extrapolation only where human
data exist and disagree, or the animal model is a poor homologue. Re-tiered: ADR 0005
clock-gene mechanism E3→E2; ADR 0009 open-loop gain *no tier at all*→E2; ADR 0007
E1→MIXED (its "rests on multiply-replicated human physiology" line was overstated).

**ADR 0004 stays E3 and default off.** Its weakness is single-group small-*n* with the
compartment inferred, in *human* subjects. Species was never its problem. The amendment
is narrow and deliberately does not rescue it.

---

## 5. ADR 0010 (ANP) — STILL PROPOSED, AND FURTHER AWAY THAN IT WAS

Sourced across three pre-registered searches (`validation/anp_sourcing_prereg.md`,
`validation/anp_input_link_prereg.md`, `validation/immersion_pooling_prereg.md`). All
three fixed pooling rules and stop conditions before any paper was read. Keep doing this;
the third one falsified the component's input side, which no amount of care *after*
extraction would have caught.

**The design got simpler as evidence came in.** Rabelink 1989 matched a 3 h head-out
immersion against a natriuresis-matched ANP infusion: immersion gave *equal* natriuresis
at **one-fifth** the plasma ANP rise, while raising renal plasma flow and lowering
fractional lithium reabsorption. ANP is not the proportional carrier — volume expansion
independently raises distal sodium delivery.

IPE has no proximal/distal partition, so it **cannot represent that mechanism**. A
mechanistic plasma-ANP pathway would be precision the surrounding model cannot support.
The component is therefore a **lumped volume-keyed natriuretic term, algebraic in
`V_blood`, with no ANP state**. Model stays at 3 states.

### 5.1 The sensed variable is falsified — 2026-08-22

`V_blood` does not grade the immersion response. Three human studies, none previously
read into this repo, and the first is decisive because it is a graded-dose design that
holds the candidate variable roughly constant while the response varies:

- **Norsk 1986** (PMID 3745047), 10 males, graded immersion to umbilicus / chest / neck:
  plasma volume rose to about the same level at **all three depths** while diuresis and
  natriuresis increased **gradually with depth**.
- **Greenleaf 1980** (PMID 6986349): 8 h immersion produced a **12.6% plasma volume
  loss** while the natriuresis was sustained — total volume moving the wrong way.
- **Simanonok 1993** (PMID 8431188): subjects bled **15% of total blood volume** before
  immersion still excreted **+120%** above dry control (+200% unbled).

**The mapping this ADR needed is contradicted, not merely missing.** And it exposes an
inference the record was already resting on: Epstein 1986 and Vesely 1989 both describe
immersion as a stimulus identical to 2 L of saline, which was read here as licensing a
**total** volume change of 2 L. It is a claim about the **central** stimulus. That step
was the unsourced scaling all along — the hunt for a central→total mapping was looking
for a source for something the literature refutes.

**What this does and does not kill.** Head-out immersion is precisely a redistribution at
approximately constant total volume, and IPE is cycle-averaged with one blood volume and
no central compartment, so the paradigm and the model variable are mismatched and no
further immersion sourcing fixes it. But the perturbation the model actually runs — a
sodium intake step — is *not* a redistribution; it genuinely moves ECF and total blood
volume. A `V_blood`-keyed term is not refuted. **Calibrating it against immersion is.**
The right anchor is the one already sourced: De Nicola 1997 (PMID 9071713), ANP at ~40%
of the natriuretic increment for a 35→235 mEq/day **diet shift** — the same kind of
total-volume perturbation as the model's own salt step.

### 5.2 Blocker list, revised

1. ~~Pool the k primary immersion papers behind Epstein's 2.5–3× range.~~ **Done, and it
   audits the review against itself.** k = 7, `pooled-geometric` **2.191×** n-weighted;
   **6 of 7 primaries fall below the review's 2.5–3×**, which its own sources do not
   support. Reproduce with `python validation/immersion_pool.py`. But the pooled figure
   is the plasma ANP fold-rise, and under the revised design **no state carries it and
   nothing multiplies it** — closing this blocker does not advance the component. The
   pre-registration caught that before extraction and pulled the natriuretic response
   (Q2) from the same papers as well.
2. ~~Source the central→total blood volume mapping.~~ **Closed as falsified, not as
   sourced** — §5.1.
3. **The 2.2× residual** — audited, not re-attributed; §3.2. Now a specific, cheap,
   bounded task instead of an open-ended mechanistic search. Separately: Rabelink's
   distal-delivery effect and Norsk's redistribution finding are the *same* mechanism
   from two directions, which strengthens it as a **candidate** for part of whatever
   residual survives. It is a hypothesis and needs its own pre-registration.
4. **NEW — re-source the input link against a total-volume paradigm.** Sodium loading or
   isotonic saline expansion with quantified volume and measured natriuresis, not
   immersion. Until then the component's input has no defensible calibration. Ogihara
   1987 is a lead (1 L saline over 1 h, hANP 246±12 → 305±30 pg/ml, 1.24×), k = 1, sets
   nothing.

Q2 — the natriuretic response, the quantity the component actually needs — **stopped at
k = 2** against a pre-registered k ≥ 3. Epstein 1987 gives 2.076, Anderson 1986 gives
2.00; Pendergast 1987 reports *fractional* excretion and `pooling.md` forbids pooling
across incompatible measurement methods. Their geometric mean is 2.038 and it is written
here **only so nobody re-derives it later and mistakes it for an adopted value**.

**The component is further from being written than it was that morning, and that is the
correct direction** — the previous position rested on a mapping that is contradicted
rather than absent. Falsifiable test 1 (pressure-clamped natriuresis, Seeliger's
experiment in silico) is untouched and remains the discriminator the day a component
exists. No `Anp` component, no ledger row, no parameter.

### 5.3 ADR 0012 REOPENS THIS — READ BEFORE ACTING ON ANY OF THE ABOVE

The central/peripheral partition (§5A) removes **one of the two obstacles** that shelved
immersion. Blocker 2 was closed as falsified because IPE could not represent a
redistribution at constant total volume; it now can. Blocker 4 — re-source the input link
against a total-volume paradigm — is **probably the wrong instruction** and should be
revisited rather than executed.

What is NOT removed is Rabelink's nephron-partition obstacle. Immersion becomes usable
for calibrating a **lumped** natriuretic term keyed to `V_central`. It does not restore a
mechanistic ANP pathway. Everything above about the term staying lumped still holds.

---

## 5A. ADR 0011 AND ADR 0012 — THE CARDIOVASCULAR TURN, 2026-08-22 to 08-24

### ADR 0011: `CO = HR x SV`, Proposed, superseded on its input side

`G_vr` is `calibrated`, load-bearing, and does not refine — a fitted constant has no
principled decomposition when compliances eventually separate. `CO = HR x SV` is no
heavier, adds no state, and its halves are separately measurable in humans. **A lump
whose pieces can be measured separately is a temporary convenience; one whose pieces
cannot is a permanent commitment in disguise.**

Sourced under `validation/sv_filling_prereg.md`. Reproduce with
`python validation/sv_filling_extract.py`.

- **Q1 sourced.** Fenland (PMID 37167327), n=10,865, **supine 63.5 ± 8.9 bpm**. Supine
  chosen because `CO0` derives from the conventional supine 5 L/min — consistency, not
  value. `SV0 = CO0/HR0 = 78.74 mL`, derived, closure constraint follows. **Not yet a
  ledger row**: the cohort is 53% women while `CV.HEMATOCRIT.NOMINAL` is male nominal.
  That is a decision for the owner, not an extraction.
- **Q2 addition direction is EMPTY, k = 0.** Saline studies report *infused* volume, not
  measured blood volume. Converting needs a retention fraction that is the same unsourced
  scaling that falsified ADR 0010's input link, arriving from a different direction.
- **The contractility exclusion is evidence-backed, not precautionary.** Kumar 2004
  (PMID 15153240): **40–90% of the SV response to 3 L of saline** came from a fall in
  end-systolic volume, not a rise in end-diastolic volume.
- **HR holds still.** Epstein 67→68 bpm across 450 mL with controls flat; Leonetti not
  significant across 375 mL; Weiner no change across a 2.1 L bolus. Three studies, two
  directions, three techniques. HR-as-parameter is defensible at these sizes.

### The finding that redirected the project

Q2's removal direction reached k = 3 and **still recorded nothing**, for a better reason
than the count. The slopes order monotonically with posture:

| posture | upright | removed | slope |
|---|---|---|---|
| seated | 90° | 375 mL | **28.00 mL/L** |
| ~30°, 30 min rest | 30° | 900 mL | **13.33 mL/L** |
| supine | 0° | 450 mL | **10.16 mL/L** |

Seated is **2.8× supine**. Neither technique nor dose orders it — the two
finger-volume-clamp studies differ 2.1× from each other, and the 900 mL study gives the
*middle* per-litre value. Population and age remain confounded with posture, so this is a
**between-study gradient: suggestive, not decisive.** Pooling across it would produce a
correctly-sourced number describing no posture in particular.

**The pre-registered endpoint rule moved Leonetti's number by 21%** — its abstract quotes
the last minute *of* withdrawal (80.7 mL), while §5 of the prereg fixed the settled
post-perturbation value (83.5 mL). Write the rule first; it changes extractions.

### ADR 0012: the central/peripheral partition, stage 1 built

`V_blood` is **not a sensed variable anywhere in the body**. Cardiopulmonary receptors and
atrial ANP release respond to *central* filling. ADR 0010's unsourceable input link was a
category error, not a gap in the literature.

    V_central ~ f_c * V_blood
    V_periph  ~ V_blood - V_central
    CO        ~ max(0.0, CO0 + G_vc * (V_central - VC0))

`VC0 = f_c*BV0` and `G_vc = G_vr/f_c` are derived from `f_c`, so stage 1 is a **change of
variables**. Model stays at 3 states.

**THE PARTITION ALONE PREDICTS THE POSTURE GRADIENT BACKWARDS.** With `g` linear,
`dSV/dV_blood = g'·f_central`, and seated has the *lower* `f_central`, so the model
predicts seated < supine against a measured 2.76× larger. Resolving it requires
`g'(seated)/g'(supine) ≥ 2.76·(f_sup/f_seat)` — i.e. **the filling relation must be
CONCAVE, and linear is excluded.** Concavity is E1 textbook, so this is not an added
assumption; but the partition and the curvature each fail alone and only predict the
gradient together. What ADR 0011 must source is a **curve over a range, not a slope.**

**`f_central` is `assumed`, inert, and 0.25 for a numerical reason.** It is a power of two
and exact in binary, which is why it deviates from the pre-partition result by 3.5e-13
where 0.30 deviates by 3.7e-10. The margin to the 1e-9 test bar is only ~3×. **When
`f_central` becomes a sourced value at stage 2, re-measure that tolerance rather than
assuming it holds.**

Two gates catch a broken partition independently: `check_closure.py` asserts
`G_vc·f_central == G_vr`, and the 1e-9 pin in `test/runtests.jl` catches an 8e-5 shift.
Both verified by perturbation, not assumed.


---

## 6. NEXT, IN ORDER

Reordered 2026-08-24, after the cardiovascular turn in §5A. **Read this before starting
a fourth ADR.** Between 21 and 24 August this project produced ~1,500 lines of documents
and zero lines of Julia; ADR 0012 stage 1 broke that. Directive 1.2 is not satisfied by
good documents.

1. **ADR 0012 stage 2, or settle Q3 first — this is the live decision.** Stage 2 makes
   `f_central` posture-dependent and needs `f_central` at two postures *plus* a sourced
   curvature for the filling relation. Before spending that, van de Velde 2018
   (PMID 29016531) crosses a 500 mL phlebotomy with active standing **in the same
   subjects** — the within-subject test the between-study gradient needs. One
   pre-registration, one extraction. If it refutes the gradient, the curvature
   requirement loses its motivation and ADR 0011 proceeds to a parameter. If it confirms,
   stage 2 rests on a controlled comparison rather than a three-study coincidence.
2. **Decide the Q1 population question.** Fenland is 53% women; `CV.HEMATOCRIT.NOMINAL`
   is male nominal. It is the only thing between Q1 and a ledger row, and it is a
   decision, not a search.
3. **Open Mizelle 1993 (PMID 8319986) in full text.** Body weights and absolute GFRs
   collapse the uncited `DOG_GFR`; enough of the dataset settles the segment
   disagreement. Cheapest move in the model and it sharpens the sharpest open question.
   §3.2. Unaffected by everything above — it can be done in any order.
4. **Revisit ADR 0010 rather than execute its blocker 4.** §5.3. Do not reopen it until
   stage 1 is merged and its 1e-9 test passes on `main`.
5. **RAAS.** `incoming/Raas.jl` is written and parked. It attaches to `FR_effective` via
   `fr_aldo` and to TPR via `tpr_mod`. It deliberately carries **no escape term** —
   escape emerges from pressure natriuresis alone at the current slope (99% of intake by
   day 2.9 against Hall's days 2–4). Adding ANP will change that; check the escape
   pressure cost *between* the two changes, or the errors cancel and hide each other.
6. **Digitise Mars500.** It gates the joint `G_pn` / ANP-gain re-estimation, which is the
   only way either becomes a posterior rather than a point value.
   `validation/averaging.md` is binding first: fixed 10 s window, applied uniformly.
7. **`check_closure.py` is now filling up.** It hand-codes NINE relationships as of ADR
   0012 and does not scale past ~20. The owner has committed to hundreds of variables.
   The cardiovascular refinement is what starts filling it; treat the warning as live
   rather than distant.
8. **Circadian last.** ADR 0005 is sound but its dependencies (RAAS, ADH) do not exist.

---

## 7. HOW THINGS BREAK HERE

Root cause across four sessions: **code written that could not be executed, then
presented as if it had been.** Mostly solved by §0. The rest are still live.

1. **Exit codes swallowed by pipes.** `cmd | tail` reports `tail`'s status. This happened
   again on 2026-08-21, one message after the trap was quoted aloud. Check exit codes
   explicitly; never infer success from output that looks clean.
2. **A wrong author on correct data is invisible to every check.** PMID 2966064 was
   attributed to "Yokota N et al." for two sessions — it is Kelly TM and Nelson DH. Every
   number attached to it was right. The ledger validates that a citation *exists*, not
   that it points at the right paper. Only a pre-registered stop condition caught it.
   **The same applies to quoting the owner.** Earlier versions of this file put
   quotation marks around directives with no source to hand, and framed them in ways he
   would not have chosen — remarks made in frustration at a slow workflow, written up as
   if they were statements about himself. Directives are paraphrased here for that
   reason. Record what was decided, not a reconstruction of how it was said.
3. **A passing test suite is not evidence about a parameter it does not assert on.**
   Every assertion passed at a 3.68× wrong slope. `test/runtests.jl` now pins salt
   sensitivity for exactly this reason.
4. **`Diagnostics` cannot fail.** `continue-on-error` at job *and* step level, and
   `bench/diagnostics.jl` calls `exit(0)` at every gate. It once reported green while
   printing a 40 mmHg salt-step table to its own summary. It is a report. Read the
   numbers.
5. **Derived values drifting apart.** `FR_Na`, `f_pv` and the osmolality relation were
   each rounded correctly and independently, and collectively drove intracellular water
   to zero while reporting `retcode: Success`. Run `check_closure.py` after any ledger
   change.
6. **Silent string replacements.** Three of five `str_replace` calls failed silently in
   one session because whitespace assumptions were wrong. Assert on every replacement.
7. **A gate cannot check a label you supplied.** ADR 0012's first draft tiered its
   load-bearing row E1 when the source is one group of ten, and `check_adrs.py` returned
   OK *because* of that. The gate did not miss an error; it was told the wrong tier. Same
   shape as the misattributed citation: the tooling validates form, never the claim.
8. **Do not run experiments on uncommitted work.** Perturbing the ledger to verify the
   partition, then `git checkout`-ing it back, discarded three rows that had never been
   committed. Recovered with no loss, but commit first and perturb second.

---

## 8. SETTLED — DO NOT RELITIGATE

- **Julia stays.** Porting was considered and rejected: the friction it would solve is
  already gone; `OrdinaryDiffEq`'s stiff suite has no Python equal; and nothing in Python
  replicates `structural_simplify`'s alias elimination, index reduction and tearing,
  which is what pays at hundreds of variables. The one scenario that could revisit it is
  **ensembles** — JAX + diffrax `vmap` over 1000 members on GPU — and only once ensembles
  are the bottleneck. They are not.
- **The `Provenance` job name.** See §2.
- **ADR 0004 default off.** See §4.
- **Pre-register before extracting.** Five times now it has caught something the
  extraction itself would have missed. The fifth changed a number rather than a
  conclusion: the endpoint rule fixed in advance moved Leonetti's extraction 21% off what
  its own abstract quotes. The fourth is the largest: it noticed the blocker
  list was asking for a quantity the component does not use, and it carried a declared
  stop condition that turned a missing source into a falsified one (§5.1).

---

## 9. OPEN ITEMS

- **14 of 45 ledger parameters** are `assumed` or `calibrated`. `unledgered_check()`
  lists them. The newest is `CV.CENTRAL.FRACTION`, which is **inert today and
  load-bearing at ADR 0012 stage 2** — see §5A.
- **The ADR 0011 filling relation must be CONCAVE and is still linear in the code.**
  `Cardiovascular.CO` records this as known-insufficient. Nothing is wrong at stage 1,
  because the partition is inert; it becomes wrong the moment `f_central` varies.
- **Q1 (resting HR) is sourced but unentered** pending the sex-composition decision, §6
  item 2.
- **`RN.AUTOREG.LOWER = 80` is genuine debt** — no primary source in any species, and a
  2025 human review argues the evidence for it is insufficient. Its upper counterpart is
  now sourced to Roman & Cowley 1985 at 160 mmHg, but that is a **censored** observation:
  160 was the highest pressure tested, so the true breakpoint is ≥160.
- **The piecewise GFR autoregulation FORM is uncited** and derivative-discontinuous at
  both breakpoints. `Renal.GFR` stays grandfathered in the relations gate because what
  was sourced is a *number*, not the equation.
- **`BF.NA.PLASMA_SETPOINT` and `BF.OSM.PLASMA_SETPOINT`** trace only to clinical
  convention.
- **Eight relations carry no `form_citation`** and are grandfathered as tracked debt.
- **Mars500 not digitised.** `validation/data/manifest.csv` has the entry.
- **`pooling.md` requires `pooling_rule`, `n_studies` and `pooling_notes` columns** that
  `ledger/parameters.csv` does not yet have. The policy is binding; the schema has not
  caught up. Rules have been recorded in prose in the meantime.
- **`DOG_GFR = 115.0` in `validation/pn_data.py` is uncited** — a parenthetical, not a
  measurement, and the whole 3.68× is exactly proportional to it. §3.2.
- **The 2.2× residual has been withdrawn as a quantity**, replaced by 0.82–3.37×. Any
  text still stating it as a point value is stale. §3.2.
- **ADR 0010's input link has no defensible calibration** and immersion cannot supply
  one. §5.
- **`validation/immersion_pool.py` and `validation/residual_audit.py` are analysis
  scripts, not gates.** Nothing runs them in CI and nothing depends on their output. They
  exist so both results are reproducible rather than asserted.

---

## 10. ENVIRONMENT

**Owner's machine:** Windows 11, PowerShell, Julia 1.12.6, Python 3.12.10, `gh` authed as
`histoneguy`. Repo at `C:\Users\histo\Claude Coding\integrative-physiology-engine`.

**Branch protection on `main`:** PR required, required status check **`Provenance`**,
linear history (squash merges), no force push, `enforce_admins: true`.

**Harness note:** bash heredocs containing backticks and apostrophes fail in this
environment. Write the script to a file and run it instead. Also, `python` cannot read
Git Bash paths like `/tmp/x` — pass Windows paths.
