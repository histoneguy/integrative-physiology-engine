# HANDOVER — Integrative Physiology Engine

**Date:** 2026-09-02
**Repo:** https://github.com/histoneguy/integrative-physiology-engine (public)
**Owner:** Eric George (`histoneguy`)
**State:** **427/427**, all five gates exit 0, nothing outstanding.

**This header deliberately names NO commit SHA and NO open PR.** Three consecutive
handovers were wrong in their first line, each in a different way: two pinned a SHA that
the next merge advanced, and the third replaced the SHA with an "in flight: PR #29"
line that went stale the moment PR #29 merged — which was minutes later, and was the
very merge that put the warning about it onto `main`. **Anything a merge can invalidate
does not belong in a header.** Run `git log -1` and `gh pr list` for live state; this
document describes the MODEL, which merging does not change.

**Supersedes** the handover of 2026-08-27, which was accurate about the MAP 93
correction and silent about everything after it. Folded in; nothing live dropped.

---

## 0. HOW THIS WORKS

**An ADR is an Architecture Decision Record** — a short document in `docs/adr/`
recording a structural choice: what was decided, the evidence, what it forecloses, and
what would show it wrong. There are fourteen and they are referenced constantly. Each
carries a **Status**, an **Evidence tier** (ADR 0006), and a **Falsifiable test**.
`tools/check_adrs.py` enforces that much. They are decisions, not documentation: a wrong
parameter gets re-estimated, a wrong structure invalidates every estimate resting on it.

**Claude Code runs locally on the owner's machine, inside the repo.** Julia 1.12.6,
Python 3.12.10, `git` and `gh` all present and working.

    julia --project=. -e "using Pkg; Pkg.test()"

**The loop is: edit, run the gates, run `Pkg.test()`, read the output, commit.** ~1m46
warm, ~3m30 cold. CI is the receipt, not the loop.

**`START-HERE.md` is stale and must not be reinstated.** It describes a workflow built
around `sprint.py` and self-applying `apply-*.py` scripts, from when the assistant could
not execute anything. That workflow is obsolete; the file has not been rewritten yet.
`incoming/` is likewise historical — `Raas.jl` was wired in on 2026-08-25 and what
remains there is prototype scaffolding, not live code.

---

## 1. BINDING DIRECTIVES

Set by the owner over several sessions. **Paraphrased, not quoted** — see §5.2.

### 1.1 Give runnable commands, not step-by-step instructions
He directs this work and does not write the code. Do the thing with tools. Where he must
run something, hand him one block he can paste. Windows and PowerShell: `python`, not
`python3`.

### 1.2 Build physiology, not process
Five gates and fourteen ADRs already exist. **Do not add tooling unless something breaks
that cannot be worked around.** Two changes have met that bar in the whole project: the
`sex` column, and `src/scaling.jl`.

### 1.3 Well-established relationships first
Build E1 before anything that modulates it. ADR 0006 carries the build order.

### 1.4 Provenance is the point
Numbers enter via `ledger/parameters.csv`, equations via `ledger/relations.csv`, both
with citations. Nothing hardcoded in a component. **This has been violated twice by
values sitting in dead code** — `form_factor = 0.4` in `reconstruct.jl` and
`Normal(70.0, 12.0)` in `ensemble.jl`. Unreached code still counts.

### 1.5 Stop working from memory; back up every statement
**Never write a citation you have not opened.** A wrong author on correct data passes
every check here. It has happened. When a value is believed but unverified, enter it as
`assumed` and say so — an honest assumption beats a citation nobody read.

### 1.6 Animal data is legitimate evidence
Judge a source on study quality, not species. Record species, preparation and tested
range. State *why* no human study exists. Encoded in ADR 0006.

### 1.7 Fundamental studies. New or old
Prefer studies characterising **baseline physiological relationships**. Not the year, and
not whether a stressor was used — Guyton 1957 varied right atrial pressure precisely to
trace the venous return curve, which is exactly what is wanted.

Ask of any candidate: *if the physiology had come out differently, what would this
paper's conclusion have been?* If the answer is "the device would have failed validation"
or "the technique would have been unsafe", the relationship is the **instrument**, not the
subject. **Search relationships, not variables** — a search ranked by what extracts easily
selects against the data you want, invisibly.

### 1.8 Cast a wide net. Do not anchor on a few papers
**It has now paid twice.** The circadian sweep returned 437 records across twelve queries
and five papers would have been wrong on both arms. The `RN.AUTOREG.LOWER` sweep returned
a clean-looking human answer in sweep 1 and the paper contradicting it in sweep 2 — see
§3.1.

### 1.9 Significant figures. Round to real numbers
**Sources support 2 to 4 significant figures. Store that, not sixteen.** Tolerances follow
the physics: **closure 1e-3, test pins 1e-4, identities between rounded values 1e-3.**

**Exception, and it is the instructive one:** significant figures belong to the quantity
carrying the information. `RN.NA.FRACTIONAL_REABSORPTION` keeps 7 figures because what
matters is `1 - FR_Na = 0.0081`. A small difference of large numbers needs digits on the
large numbers.

Chasing precision that does not exist cost roughly a third of one session.

### 1.10 Comprehensive, but super efficient — FOUNDATIONAL — 2026-08-27
**Coverage is not negotiable; cost is.** Code must be comprehensive AND efficient. This
ranks with provenance — not a preference to trade away when a task feels big.

The two are not in tension, and treating them as if they were is the error. What makes
work expensive here is almost never the number of things checked; it is **horizon,
duplication, and code that should not exist at all.**

**The evidence.** Connecting the ensemble took the suite from ~1 min to 3m33. Trimming to
four members over 25 days, folding a testset into an existing one, and dropping a
redundant salt-step arm brought it to **1m46 with more assertions than before.**

**A slow suite is a compounding cost** — paid on every future run, forever.

**How to apply.** Fold assertions into an existing testset rather than adding one. Pick
the shortest horizon at which the assertion still bites. Check whether the repo already
contains it before writing anything. No new file where a function will do; no new
function where an argument will do. **Assert more per unit of compute.**

**This never licenses skipping verification.** Falsification runs — reverting a parameter
to confirm a test genuinely fails — are cheap and are not what makes a suite slow.

### 1.11 Connect it and run it — FOUNDATIONAL — 2026-08-27
**Wire up what already exists before sourcing anything new.** Prefer connecting an
unconnected component over auditing or extracting.

**Why: every real defect found on 2026-08-27 was found by connecting something, and none
by any of the five gates.** Provenance auditing found none of them.

| found by wiring | what it was |
|---|---|
| `CV.MAP.SETPOINT` = 93 | the brachial 120/80 convention; exposed by a form factor of 0.515, an arithmetic impossibility |
| `CV.PULSE.FORM_FACTOR` | NAMED as the fraction *above* the mean while carrying the *below* value — would have shipped SBP 98 / DBP 65 against a sourced 109/76 |
| four coupling defects | including an edge naming a subsystem that does not exist, which `validate_partition` was structurally guaranteed to skip |
| `member_parameters` | returned parameters unchanged; every "population" member was the same 70 kg individual |
| the body-size collapse | six adults 49–91 kg converging on one ECF volume |

**Sourcing that runs ahead of the model consuming it is the failure mode.** A parameter
nobody calls is not evidence about anything. Do not propose an upstream extraction as a
prerequisite for wiring unless the wiring genuinely cannot proceed without it — a 5% error
in an input is recorded uncertainty, not a blocker.


### 1.12 Textbook numbers are teaching aids. The RELATIONSHIPS are the content — FOUNDATIONAL — 2026-08-31
**A round physiological constant is a pedagogical convention until proven otherwise.**
Treat every one as presumptively unsourced, whatever the ledger's `extraction_method`
column claims.

Textbooks are written for undergraduates and are deliberately simplified. What they get
*right* is the structure — that pressure natriuresis exists, that GFR is autoregulated,
that CO = HR × SV. What they carry alongside it are round numbers chosen to be
memorable, and **nobody ever meant them as population estimates.** 120/80 is not a mean.
Neither is 37 °C, 5 litres, 45%, 125 mL/min or 5 L/min.

**The record, and it is not close.** Eight ledger rows claimed
`Standard physiological reference. VERIFY.` Six could be opened directly on 2026-08-31
and **four were materially wrong**. The last two could not be sourced at all until their
DEPENDENCIES were inverted on 2026-09-01 — and then **both were wrong too**. Six of
eight, and not one of the six was high:

| row | textbook | measured |
|---|---|---|
| `CV.MAP.SETPOINT` | 93 (= 80 + 40/3, brachial 120/80) | 87, central |
| `RN.AUTOREG.LOWER` | 80 mmHg | 63.9, and an anaesthetised dog |
| `RN.GFR.NOMINAL` | 180 L/day (= 125 mL/min) | 152.6 (= 106 mL/min) |
| `CV.BLOOD_VOLUME.NOMINAL` | "5 litres" | 5.62 male / 4.92 female |
| `CV.HEMATOCRIT.NOMINAL` | 45% for everyone | 45.3 male / **39.5 female** |
| `CV.CO.NOMINAL` | “5 L/min” | 5.95 male / 4.88 female |
| `ADH.URINE.OSM_MAX` | 1200 mOsm/kg | 982, and 823 by age 80 |

Haematocrit is the clearest case: the unisex 45% is **the male value applied to women.**

**And a clinical reference value is a RANGE because humans are a distribution.** A
textbook point value is therefore wrong twice over — wrong centre, and no spread at all.
This ledger stores a point plus an `uncertainty_value`, and **only body mass is currently
sampled**; every other parameter is one number for all thousand virtual people. That is a
known defect, not a simplification.

**How to apply.** Do not act surprised when a round number fails — expect it, and budget
for it. Never enter one as `reported`. Where it cannot be sourced, `assumed` with an
honest note is the correct outcome and the `assumed` count going UP is progress
(`validation/verify_rows_prereg.md` branch 6). And prefer sources that report a
**central value with dispersion** over those reporting an interval — `pooling.md`
prohibits `range-midpoint`, so an interval cannot become a point estimate.

---

## 2. STATE

**427/427, five gates exit 0.** All of the below is on `main` as of 2026-09-01.

**THE `VERIFY` CLASS IS EMPTY.** Eight rows carried
`Standard physiological reference. VERIFY.` Five are now sourced — `CV.MAP.SETPOINT`,
`RN.AUTOREG.LOWER`, `RN.GFR.NOMINAL`, `CV.BLOOD_VOLUME.NOMINAL`,
`CV.HEMATOCRIT.NOMINAL` — one had its derivation written down
(`RN.NA.FRACTIONAL_REABSORPTION`), and two were **demoted to `assumed`** because no
source could be opened (`CV.CO.NOMINAL`, `RN.H2O.OBLIGATORY_LOSS`). **Four of the six
that could be opened were materially wrong.** The `assumed` count went UP by two, and
that is the honest direction — see `validation/verify_rows_prereg.md` branch 6.

### The model — 7 states after `structural_simplify`

`bf.V_icf`, `bf.V_ecf`, `bf.Na_ecf`, `br.tpr_mod`, `br.sp`, `ra.pra`, `ra.esc`

| Component | Status |
|---|---|
| `BodyFluids.jl` | ICF/ECF volumes, sodium mass balance, osmotic equilibration. Intakes now scale with body size. Inactive-Na storage **default off** (ADR 0004). |
| `Cardiovascular.jl` | ECF → plasma → blood volume, partitioned central/peripheral (ADR 0012). **CO = HR × SV**, and stroke volume is now the SOURCED half (ADR 0011). MAP = CO × TPR, sexed. |
| `Renal.jl` | GFR autoregulation, filtered load, pressure natriuresis, RAAS increment, circadian modulation, osmoregulated water excretion, **urine solute load tracking sodium**. |
| `Baroreflex.jl` | Lumped, resetting, **TPR effector only**. Setpoint scaled by the clock. |
| `Raas.jl` | Active at rest — PRA 2.31×. No AngII vasoconstriction, deliberate. |
| `Adh.jl` | Osmolality → antidiuretic activity → urine osmolality. Algebraic, no states. |
| `Circadian.jl` | Cosinor clock, connected to renal excretion and the reflex setpoint. **Default OFF** — both arms' parameters contested. |
| `reconstruct.jl` | **Connected.** SBP/DBP/PP from `SV` and `C_art`. NOT part of the ODE system — see §3.2. |
| `scaling.jl` | **New.** Extensive quantities scale with body mass, intensive ones do not. |

### The result

| intake (mEq/d) | MAP (mmHg) | SBP | DBP | PP |
|---|---|---|---|---|
| 205 | 86.979 | 108.97 | 75.98 | 32.99 |
| 154 | 84.450 | 105.81 | 73.77 | 32.03 |
| 103 | 81.922 | 102.64 | 71.57 | 31.07 |

**Shift 5.0570 mmHg**, and it survived a 19% rise in cardiac output without moving at
the fifth significant figure — §3.6. Arterial pressure is nowhere regulated; it lands at a stable
intake-dependent value through renal–body fluid feedback alone. **Do not quote beyond 5
significant figures** and do not pin tighter than 1e-4.

SBP/DBP are **reconstructed, not simulated** (ADR 0002) and must be labelled as such
wherever reported. Agreement with the sourced 109/76 is **consistency, not validation** —
`C_art` was derived as SV₀/PP₀.

### Population

`sample_population` draws Sobol over sexed NHANES percentiles. `V_ecf` scales with body
mass — **0.207943 L/kg male, 0.207959 female** — while MAP is invariant across the mass
range (86.9794 male, 86.9795 female). The population is **uniform** over P05–P95, not
weight-distributed.

**ECF per kg is now essentially sex-INVARIANT, and that is a change of meaning, not of
digits.** It read 0.20788 / 0.20284 before blood volume and haematocrit were sourced as
pairs — a 2.4% sex difference that was an ARTEFACT of a female plasma fraction derived
against a shared blood volume and a shared 45% haematocrit. With both sexed the chain is
internally consistent per sex and ECF per kg lands on `BF.ECF.MASS_FRACTION` (0.208),
which is a shared `both` row. The dimorphism moved to where it is actually measured —
blood volume and haematocrit — and left the compartment fraction alone.

### Ledger

**70 parameters over 82 rows** — 34 `reported`, 28 `derived`, 18 `assumed`, 2
`calibrated`. **20 weak.** Tiers: 38 A, 27 B, 17 C.
**The `assumed` count went DOWN by two on 2026-09-01, and that is as honest as its going
UP was on 2026-08-31.** `CV.CO.NOMINAL` and `RN.H2O.OBLIGATORY_LOSS` did not acquire
citations; they stopped being primitives. Each is now DERIVED from the quantity that is
actually measured — stroke volume and maximal urine concentration — and it is those two
rows that carry the new sources.
**42 relations** — 15 definitional, 14 empirical, 9 conservation, 4 placeholder.
**Twelve parameters carry male/female pairs:** `BF.BODY_MASS.{TYPICAL,P05,P95}`,
`CV.ARTERIAL.COMPLIANCE`, `CV.HR.NOMINAL`, `CV.SV.NOMINAL`,
`CV.BLOOD_VOLUME.NOMINAL`, `CV.HEMATOCRIT.NOMINAL`, `CV.PLASMA.ECF_FRACTION`,
`CV.CENTRAL.VOLUME_NOMINAL`, **`CV.CO.NOMINAL`** and **`CV.TPR.NOMINAL`** — the
last four are DERIVED and became sexed with their inputs: plasma fraction and
central volume from blood volume and haematocrit, cardiac output and resistance
from the sourced stroke volume.

### Couplings — connected 2026-08-27

13 couplings, cross-checked against the built model by
`assert_couplings_match_model()`. Declared time constants **3.0 / 302.4 / 3600 / 3600 s**,
largest gap **100.8×**, suggested boundary **30.1 s**. `cost_profile` on a real solution
returns `nf/nw = 2.5` — **linear-algebra bound, so partitioning is the right lever.** Both
halves of the ADR 0003 argument now exist; ADR 0003 stays Deferred on state count.

### Gates

`ledger_to_julia.py --check`, `check_relations.py --repo .`, `check_closure.py`
(19 checks, per sex), `check_adrs.py`, `fix_deps.py`. **Never rename the `Provenance` job
in `ci.yml`** — branch protection requires that exact string.

---

## 3. FINDINGS THAT MATTER

### 3.1 `RN.AUTOREG.LOWER`: the textbook 80 mmHg is an anaesthetised dog

**80 → 63.9 mmHg, species human → dog, tier B → A.** Pre-registered at `3fbe260` before
any paper was opened; 26 queries, 1114 records.

No human primary reports a lower breakpoint. **The human evidence conflicts at the same
pressure:** at MAP 60, Lessard 1991 (inulin GFR, PAH ERPF, n=20) found renal vascular
resistance *falling* to maintain flow, while Hara 1998 (n=26) found creatinine clearance
significantly *decreased*. All four human candidates are anaesthesia **safety** studies —
directive 1.7 says the relationship is the instrument there. Adopted **Finke 1983**: seven
**conscious** foxhounds, renal artery pressure servo-stepped 160 → 40 mmHg, lower limit
63.9 mmHg.

**Still debt**: a dog number where the human experiment *is* performable, so the ethical
ceiling that earns `RN.AUTOREG.UPPER` its E2 standing does **not** transfer. Ruled out in
the pre-registration before the search.

**Recorded, out of scope:** Finke also measured the renin threshold at **89.8 ± 3.3 mmHg**
in conscious dog, against `RAAS.RENIN.PRESSURE_THRESHOLD = 93.0` on van Ochten. That row
is the rectification point the model was found sitting exactly on.

### 3.2 The form-factor convention would have shipped an 11 mmHg error past every gate

`CV.PULSE.FORM_FACTOR` was **named** as the fraction of pulse pressure *above* the mean
while carrying the *below*-mean value 0.3333. `check_closure.py` used it correctly as
`MAP = DBP + k·PP` and passed; `reconstruct.jl` defined it the other way. Connecting them
under the shared word "form factor" would have returned SBP 98.0 / DBP 65.0 against the
sourced 109 / 76 — each wrong by PP/3, in opposite directions — **and every gate would
still have passed, because closure never reaches that file.**

It is now `k_below`, with no default and a hard error at ≥ 0.5. **Second
convention-hiding-in-a-name defect in two days**, after MAP 93.

### 3.3 The model is 2 to 19 times too salt-sensitive. It is calibrated to hypertensives.

Sourced under `validation/salt_sensitivity_prereg.md`. Reproduce with
`python validation/salt_sensitivity_extract.py`.

| source | trials | MAP mmHg/100 mmol | implied `G_pn` |
|---|---|---|---|
| Cutler 1997 | 32, n=2635 | 1.70 | 59 |
| He/Li/MacGregor 2013 | 34, n=3230 | 1.96 | 51 |
| He & MacGregor 2002 | 11, n=2220 | 2.30 | 44 |
| Graudal 2019 | 133 RCTs | 0.53 | 188 |
| Graudal 2017 Cochrane | 89, n=8569 | 0.25 | 393 |

The model gives ~4.8 mmHg per 100 mmol — a *hypertensive* number. **`G_pn` should be
LARGER than 20, not smaller.** ADR 0013 proposes 20.0 → 51.0 and is **PARKED at the
owner's decision**; it is one CSV value. Its falsifiable test uses a variable that did not
set the value — source the human ECF or weight response and run it before accepting.

Making the urine solute load track sodium moved salt sensitivity 5.0996 → 5.0575, the
**first structural change to move it toward the human data.** 0.8% against a 2× gap, so it
does not touch this finding.

**UPDATE 2026-09-02: the test was run and `G_pn` is NOT the row to change first — §3.7.**
The pressure evidence above is untouched and still implies 43.5–58.8. What the volume
test shows is that the model's **pressure-per-unit-volume is 5.2× too stiff**, and that
`G_pn` cannot fix that because the two parameters are orthogonal.

### 3.4 Body size: two quantities, and merging them would have corrupted the ledger

`BF.BODY_MASS.REFERENCE` (70.0 kg, `both`) is a **normalisation constant** — the mass at
which the extensive constants are stated. GFR 180 L/day, CO 7200 mL/min, blood volume
5.0 L are textbook values for a ~70 kg, 1.73 m² adult. **Setting it to the NHANES mean
would scale GFR to 232 L/day by arithmetic**, against a denominator its own sources never
used.

`BF.BODY_MASS.TYPICAL` is the sexed pair — 90.3 / 77.9 kg, NHANES 2021–2023 Table 3,
tier A. **No SD is entered**: the source reports SEM and percentiles, body weight is
right-skewed, and two standard estimators disagree by 15%. The pre-registration declared
no estimator, so choosing one afterwards is the unfalsifiable move `pooling.md` forbids.

---

### 3.5 The `VERIFY` class is closed, and four of six were wrong

Pre-registered in `validation/verify_rows_prereg.md` (commit `e0195f4`) as ONE document
for all six rather than six documents, per directive 1.10.

**Sourced:** `RN.GFR.NOMINAL` 180 → 152.6 L/day (Soares 2013, ⁵¹Cr-EDTA, n=285;
Denic 2017 NEJM n=1,388 corroborates but is unindexed and so NOT pooled).
`CV.BLOOD_VOLUME.NOMINAL` → 5.62/4.92 L (Oberholzer 2024, CO rebreathing, n=582).
`CV.HEMATOCRIT.NOMINAL` → 0.453/0.395 (Morales-Mendoza 2026 low-altitude stratum,
n=662,024; Fulgoni 2019 NHANES n=44,328 corroborates with intervals, not pooled).

**Derived, no search needed:** `RN.NA.FRACTIONAL_REABSORPTION` is exactly
`1 − Na_intake/(GFR0·C_Na)`. It claimed `derived` while carrying a citation; a derived
value needs its derivation written down. **`check_closure.py` already asserted it**, so
no gate was added.

**Demoted to `assumed`:** `CV.CO.NOMINAL` and `RN.H2O.OBLIGATORY_LOSS`. Nothing usable
could be opened — the attempts are recorded in the rows so they are not repeated.

**Two structural results, each worth more than the row that produced it.**

1. **GFR cancels out of the steady state.** `FR_Na` is derived to close sodium balance,
   so `Na_filtered·(1−FR_Na) = intake` and `MAP − MAP_ref = (intake − 205)/G_pn`. A **15%
   error in the entire renal input moved the salt-step shift by 0.0006 mmHg.** Salt
   sensitivity is set by `G_pn` alone; GFR enters only transients and the water side.
2. **Haematocrit is currently non-identifiable.** — **SUPERSEDED 2026-09-02, §3.8.**
   What follows is true of the LEVEL and false of the DERIVATIVE, and nobody checked
   the derivative for five days. Read it as the record of a conclusion that was
   half right. It enters only via
   `V_blood = f_pv·V_ecf/(1−Hct)`, and `f_pv` is DERIVED as `BV0(1−Hct)/V_ecf`, so
   `f_pv/(1−Hct) = BV0/V_ecf` and the Hct cancels. Verified empirically: a 15% sex
   difference in Hct left every result identical to seven figures. It bites the moment
   `f_pv` is sourced independently — plasma volume as a fraction of ECF is measurable —
   or when viscosity or oxygen carriage exists.

### 3.6 Two dependencies ran against the measurement, and inverting them cost 19% of cardiac output

Pre-registered in `validation/dependency_inversion_prereg.md` at `bd5cdf3`, before any
paper was opened. Reproduce with `python validation/dependency_inversion_extract.py`.

Both rows the 2026-08-31 sweep had to demote were demoted for the same reason: **the
ledger derived the measured quantity from the computed one.** No search could discharge
either, because the row a source would have filled was the row being computed.

| row | was | is |
|---|---|---|
| `CV.SV.NOMINAL` | 80.7 / 77.0 mL, `derived` | **96 / 75 mL, `reported`** (Petersen 2017, UK Biobank CMR, n = 800) |
| `CV.CO.NOMINAL` | 7200 L/day, `assumed`, no citation | **8570.88 / 7020 L/day, `derived`** |
| `ADH.URINE.OSM_MAX` | 1200 mOsm/kg, `derived` | **982, `reported`** (Tryding 1988, DDAVP, n = 212) |
| `RN.H2O.OBLIGATORY_LOSS` | 0.5 L/day, `assumed`, no citation | **0.611 L/day, `derived`** |

**The water side needed no search to be CORRECT, only to be better.** `Renal.jl` has
computed the obligatory volume as `Osm_load/U_max` since the solute load began tracking
sodium; nothing in `src/` read the row at all, and `check_closure.py` — its only consumer
— was asserting the relationship in the **opposite direction to the code it exists to
check.** Directive 1.11 found that, not a gate.

**A 19% RISE IN CARDIAC OUTPUT MOVED THE SALT-STEP SHIFT BY NOTHING.** 5.0569 before,
5.056918 after. `TPR0` is derived as `MAP0/CO0`, so the nominal operating point cannot
move — but loop gain does, `dMAP/dV_ecf` falling 16%, and §3.5 predicted the shift would
survive that because `G_pn` sets it. It does, to five significant figures. With the ADH
loop **disabled** it moves 0.6% (4.9352 → 4.9067), because the placeholder pins urine
output and forces sodium balance to close through the circulation instead. Checked rather
than assumed: the cardiac change was run alone with the old ADH constants restored.

**And the sex pair now moves volumes while leaving pressure alone.** Cardiac output
differs by 22% between the sexes; the salt-step shift differs at the eighth significant
figure. Women reach the same pressure on a **6.9% smaller ECF excursion**, because
`dMAP/dV_ecf` scales as `TPR0·BV0` and that product is 6.9% larger in women. ADR 0014's
falsifiable test asked that a pair change a result — it does, and not where that record
predicted. **"Results move" is the wrong test on its own in a regulated loop.**

**The pre-registered prediction about body size was half wrong, which is the useful
half.** `CV.SV.NOMINAL`'s old note cited Katori 1979 for no sex difference in stroke
*index* and concluded the dimorphism was body size. Indexing to body surface area, the
male excess falls from 28% to 9% — but it does **not** vanish, and four independent
cohorts totalling 4,582 people agree (Petersen 9%, Luu 10%, Salton and Le Ven both
stating the difference survives adjustment). Two thirds of it is size; about a third is
not. The note has been corrected on the row.

**What could not be used, and it is the better study.** Luu 2022 (CAHHM, n = 3,206,
multi-ethnic, anatomically correct contouring) reports stroke volume **indexed to BSA
only.** Converting it needs a body surface area, which this model does not carry, and the
pre-registration refused to introduce one as a side effect. Zhan 2024 — the Bayesian
meta-analysis of 12,812 healthy adults that `pooling.md` rule 1 would have preferred —
reports reference *limits*, indexed, so `range-midpoint` disqualifies it. **A BSA row
would unlock both.** See §4.

### 3.7 ADR 0013's own test fails, and it clears `G_pn` while convicting `G_vr`

Pre-registered in `validation/ecf_salt_response_prereg.md` before any paper was opened.
Reproduce with `python validation/ecf_salt_response_extract.py`. **`G_pn` stays at 20.0
and ADR 0013 stays Proposed.**

ADR 0013 says its volume test *"can fail, and it is independent"* and must run before
acceptance. It ran. **Its own predicted volume response was also stale** — 0.155 L, measured
before ADH, the sodium-tracking solute load, sourced blood volume and the cardiac
inversion. The current figure is 0.176 L.

**The evidence.** van den Bosch 2021 (`Physiol Rep` 2021;9(24):e15103, PMID 34921521),
n = 70 healthy men, 7 days per level, ECFV by iothalamate distribution volume, intake
**verified by 24 h urinary sodium** — 230 against 38 mmol/24 h. The only study found
reporting volume, pressure and cohort mass in the same subjects.

| | measured | per 100 mmol/day |
|---|---|---|
| ΔMAP | 88 → 86 mmHg | 1.042 mmHg |
| ΔECFV | 1.061 L | 0.553 L |
| Δbody weight | 80.6 → 79.2 kg | 0.729 kg |

**Test B — the ratio, which does not involve `G_pn` at all — fails by 2.7–5.2×.** Threshold
was 2. Within-subject: human 1.885 mmHg/L against the model's 9.80 at that cohort's mass,
and it fails on all three volume proxies (5.2, 4.4, 6.9), so it does not turn on the
iothalamate space or the 1 kg = 1 L conversion.

**The base is seven primaries across four groups and two methods, not one study.** Two
further sweeps were run because the verdict rested on one cohort. The **body-weight limb**
— van den Bosch (n=70, 0.729), Rorije 2018 (n=12, +2.5 kg, **BP unchanged**), Foo 1998
(n=18, 0.250), Heer 2000 (n=32, zero) — pools n-weighted to **0.572 kg/100 mmol** over
n=132, against the tracer limb's **0.553 L. Two independent methods agreeing to 4%**, and
the pre-registration said in §8 that the 1 kg = 1 L conversion would be FALSIFIED if they
diverged. Pairing the meta-analytic pressure with the pooled volume gives 2.97–4.16
mmHg/L, so **`G_vr`'s target is 758–1062**, with 554 the harshest reading.

**Use the pooled ratio, not the studies' own pressures.** Kirkendall 1976 (n=8, **four
weeks per level**, the closest protocol to this model's 30 days), Rorije 2018 and Taurio
2023 (**n=510**, the largest dataset found) all report **no blood pressure change at
all** — they are underpowered for 2 mmHg, and taking those nulls at face value would drive
`G_vr` to zero. Taurio's own conclusion is that sodium intake *“predominantly influences
extracellular water volume without a clear effect on blood pressure”*, which is this
finding stated independently.

**`G_pn` AND `G_vr` ARE ORTHOGONAL, AND THAT IS THE STRUCTURAL RESULT.** An 8× change in
`G_vr` moves the salt-step **pressure** response by **0.12%** and moves the **volume**
response **exactly inversely** (`G_vr × ΔV₁₀₀` = 1265 throughout). `G_pn` sets ΔMAP; `G_vr`
sets ΔMAP/ΔV_ecf. **So the human pressure data and the human volume data identify one
parameter each, with no cross-talk, and this model is exactly identifiable from the two.**

**To match the human ratio, `G_vr` must fall from 2880 to 758–1062.**

**And part of that was not `G_vr` at all. IT HAS NOW BEEN FIXED AND RUN — §3.8.**
`Cardiovascular.jl` computed `V_blood ~ V_plasma/(1 - Hct)` with `Hct` a **constant**, so
red cell volume expanded with plasma across a 30-day salt step. Red cell mass is fixed on
that timescale — plasma expansion *dilutes* the haematocrit. Correcting it moved
`dV_blood/dV_ecf` from 0.386 to 0.211 and the ratio from 11.285 to **6.173**, closing
**1.83×** of the gap and leaving `G_vr` needing **1012–1941**.

**Why this does not refute 51.** The pressure limb is untouched. Accepting 51 alone would
make the volume response *worse* — from 1.26× too small at `G_pn` = 20 to 3.2× too small —
because `G_pn` moves ΔMAP and ΔV_ecf follows it down at a fixed, wrong ratio. **Fix `G_vr`
first, re-run this test, then accept.**

**A declared conflict, recorded and not resolved.** Heer 2000 (PMID 10751219, n = 32,
metabolic ward) found plasma volume rose dose-dependently while **total body water and body
mass did not increase at all**; Heer 2009 (PMID 19173770) found ECV rose 2.02 L from low to
normal intake and then *fell*. If that camp is right the discrepancy has the opposite sign.
Both camps agree ECF responds across low-to-normal, which is where the model's step sits —
but Heer's 2.02 L for that same step is 3.7× van den Bosch's. **This bears on ADR 0004:**
osmotically inactive sodium storage, default OFF here, is exactly the mechanism that camp
invokes.

**Test A is separately inconclusive** — branch A4 by the pre-registration's own words. The
volume-implied `G_pn` is 15.9, 11.0, 6.5 and effectively infinite across the four studies.

### 3.8 Red cell volume was expanding with plasma, and correcting it made haematocrit bite

Found while attributing §3.7's 2.7–5.2× discrepancy. `Cardiovascular.jl` computed

    V_blood ~ V_plasma / (1 - Hct)          with Hct a CONSTANT parameter

which makes **red cell volume expand in proportion to plasma.** Over the 30-day salt step
this model runs, red cell mass does not move at all — erythrocyte lifespan is ~120 days and
erythropoiesis answers to EPO, not to sodium. A plasma expansion *dilutes* the haematocrit.
It is now `V_blood ~ V_plasma + Hct*BV0`, and `relations.csv` reclassifies it
`definitional` to **`conservation`**, because that is what it states: the red cell
compartment is conserved over the timescale of the perturbation.

**The nominal point is bit-identical by construction** — `f_pv` is derived as
`BV0(1-Hct)/V_ecf0`, so `V_plasma + Hct*BV0 = BV0` exactly at `V_ecf = V_ecf0`. MAP, SBP and
DBP at the operating point do not move. **The derivative is what changes, and that was the
point.**

| | before | after |
|---|---|---|
| `dV_blood/dV_ecf` | 0.386 | **0.211** (divided by 1.83 = 1/(1−Hct)) |
| `dMAP/dV_ecf` | 11.285 | **6.173** |
| ΔV_ecf per 100 mmol/day | 0.439 | **0.803** |
| male/female excursion ratio | 1.069 | **1.182** |
| salt-step MAP shift | 5.0569 | 5.0570 |

**HAEMATOCRIT IS IDENTIFIABLE NOW, AND §3.5 SAID IT WOULD NOT BE.** That section recorded
haematocrit as non-identifiable because `f_pv` is derived from it and
`f_pv/(1-Hct) = BV0/V_ecf0`. **That cancellation is in the LEVEL only.** In the derivative
the model now carries `f_pv = BV0(1-Hct)/V_ecf0`, which depends on `Hct` — so the sourced
0.453/0.395 pair moves a result for the first time, and ADR 0014's falsifiable test is
satisfied a second time, by a second parameter, through the volume side again.

**AND THE ENDPOINT IS NOW VISIBLE.** With `G_pn` = 51 (ADR 0013) *and* `G_vr` near 1400, the
model reproduces every human quantity at once:

| config | ΔMAP/100 mmol | ΔV/100 mmol | ratio |
|---|---|---|---|
| current (20, 2880) | 4.958 | 0.803 | 6.173 |
| ADR 0013 alone (51, 2880) | **1.944** yes | 0.315 no | 6.173 no |
| `G_vr` alone (20, 1400) | 4.958 no | 1.652 no | **3.001** yes |
| **both (51, 1400)** | **1.944** yes | **0.648** yes | **3.001** yes |
| **human** | **1.70–2.30** | **0.553–0.572** | **2.97–4.16** |

**Neither correction alone lands; together they land on all three.** 1400 is illustrative,
not a value to enter — `G_vr` must be REPLACED by sourced venous compliance (§4 item 1),
and this table is the target that work has to explain. It also **vindicates ADR 0013's 51**:
the pressure evidence was right and the volume objection was never about `G_pn`.

**Declared, because the discovery route was motivated.** The correction is justified
independently — red cell mass does not track plasma over 30 days whatever the pressure data
say — but it was found while hunting §3.7's discrepancy, and that is recorded rather than
presented as an independent discovery.

### 3.9 A venous-mechanics claim was made and withdrawn. Read this before repeating it

On 2026-09-02 a pre-registered pass concluded that `G_vr` could not be sourced from venous
mechanics, on the grounds that sourced compliance and venous-return resistance compose to
22,200–44,400 (L/day)/L against a target of 1012–1941. **That conclusion is withdrawn.
Its PR was closed unmerged and nothing reached `main`** — `validation/`
`venous_return_resistance_prereg.md` and its extract are NOT in this repository.

**The error, stated so it is not repeated.** The composition `G_vr = 1/(C_sys · R_vr)`
treats right atrial pressure as **fixed**. The pre-registration said so in terms — *"when
right atrial pressure is treated as fixed, which is what this model does"* — and the
result was then read as a fact about physiology rather than as a consequence of the
assumption. With RAP free the composition is `S/((1 + S·R_vr)·C_sys)`, and for a cardiac
function curve slope near 0.1 L/min/mmHg that lands around 2,100 — inside the model's own
range. **There was no order-of-magnitude gap, so there was nothing for an
unstressed-volume story to explain.**

**Refuted directly by primary data, both arms.** Manning, Coleman, Guyton, Norman & McCaa
1979 (PMID 434186), 9 dogs on chronic saline: **mean circulatory filling pressure rose 4.7
Torr by day 3 and was still 2 Torr elevated at two weeks.** Filling pressure rises
substantially and persistently — the opposite of the near-complete unstressed absorption
that had been argued. And Cowley & Guyton 1975 (PMID 1116246) refutes the fallback that
RAP rises so cardiac output does not: **CO rose 40% above control in intact dogs.**

**THE SOURCE SELECTION WAS ALSO WRONG, AND THAT IS THE MORE GENERAL LESSON.** The inputs
were Maas 2012 (post-cardiac-surgery ICU), Magder 2025 (compiled largely from critically
ill), Manning 1979 and Cowley 1975 (reduced-renal-mass dogs on 190 mL/kg/day saline, going
frankly hypertensive), Kim 1980 (anephric), the nonmodulator subgroup (hypertensive by
definition), and a trout. **A model whose structure is inferred from pathological
preparations becomes a pathological model** — which is what §3.3 already says has happened
to `G_pn`. Directive 1.7 is the guard and it was not applied to these.

**What survives, because none of it depends on that composition:**

- The **measured ratio gap**: model 6.173 mmHg/L against a human 2.97–4.16 (§3.7, §3.8).
  That is ~2×, from data alone, and it is an ordinary discrepancy.
- The **red cell correction** (§3.8) — independent physiology, and merged.
- **`G_pn` and `G_vr` are orthogonal** (§3.7) — measured from model runs.
- `G_vr`'s target of **1012–1941**, which comes from the human salt data and the model, not
  from venous mechanics.

### 3.10 The pressure-natriuresis curve is not fixed in humans. It is fixed in this model

**Literature plus one code observation. NOTHING HAS BEEN RUN TO TEST THIS, and it is
recorded as a lead rather than a finding.** Source table:
`validation/renal_hemodynamics_salt_sources.md` — 24 queries over three sweeps, healthy
humans first.

**Hall, Guyton, Smith & Coleman 1980** (PMID 6254369), six **conscious control dogs**,
chronic steps from **5 to 500 meq/day**: sodium balance achieved with **AP rising less
than 7 mmHg**, GFR +19%, filtration fraction and plasma renin activity both falling. In
six dogs with **angiotensin II held fixed by infusion**, the same intake steps produced
**AP +42%**. Their conclusion: the renin-angiotensin system, *independent of changes in
plasma aldosterone*, is what allows sodium balance without large changes in GFR or AP.

**The same phenomenon in healthy humans, from four groups:** renal plasma flow and GFR
both **rise** on high salt (Krikken 2007, n = 95, `17091123`; van den Bosch 2021, n = 70,
ERPF 592 vs 559 and GFR 138 vs 128, `34921521`), renal blood flow rises 79 ± 28
mL/min/1.73 m² with blood pressure unchanged (Redgrave 1985 normotensive controls,
`2985655`), and the renal vascular response to angiotensin II is modulated by sodium
within **3–7 hours** of volume expansion (Conlin 1993, `7503952`).

**Hall 1986** (PMID 3514280) gives the arteriolar mechanism: AngII **preferentially
constricts efferent arterioles** and does **not** constrict afferent/preglomerular vessels
at physiological activation; its intrarenal tubular effects are **quantitatively more
important than the aldosterone-mediated ones.**

**The code observation.** `Renal.jl` carries a constant `G_pn` with the RAAS entering as
`fr_mod`; `Raas.jl` sets `fr_mod ~ fr_raw - esc` with `D(esc) ~ (fr_raw - esc)/tau_esc`,
so at steady state `esc = fr_raw` and **`fr_mod = 0`** — which §7 already records as
*"escape drives fr_mod to ~1e-7 so no steady state moves"*. And `fr_raw ~ k_aldo*(aldo-1)`
acts through **aldosterone**, the component Hall calls quantitatively minor and which
genuinely does escape. **The AngII efferent-arteriolar and tubular component is not
represented at all.**

**What that would mean if it holds — and it has NOT been tested:** the model's renal
function curve cannot move, so all sodium-balance adaptation must run through arterial
pressure. That is a candidate explanation for §3.3 and for why `G_pn` needs recalibrating
at all. **Do not act on it without running something.** Two mechanistic claims were made
and withdrawn on 2026-09-02 (§3.9); this is a third and it is deliberately not being
built on.

**What is missing before it can be sized:** filtration fraction across salt intake
disagrees in direction between healthy humans (Krikken +1.1%, van den Bosch 0.229 → 0.233)
and the conscious dog control arm (Hall 1980, FF decreased). See the source table §4.

---

## 4. NEXT, IN ORDER

**Finish the cardiovascular system, then the other systems. Populations are far off — a
population of an incomplete model is a wider set of wrong answers.**

**Flipping the stroke-volume dependency was item 1 and is DONE, both halves — §3.6.**

1. **Renal haemodynamics across salt intake in healthy humans — THE SOURCE TABLE IS
   ALREADY BUILT.** `validation/renal_hemodynamics_salt_sources.md`, 24 queries, nine
   healthy-human primaries with numbers. Nothing is extracted from it and it needs a
   pre-registration before anything is. The two things to settle first are named in its
   §4: the **direction of the filtration-fraction change** on high salt, which disagrees
   between healthy humans and the conscious dog, and **one ambiguous sentence in Krikken
   2007** that needs the full text. This is item 1 because §3.10 is a lead about the
   MODEL'S OWN renal structure and this is what would let it be sized rather than argued.

2. **Venous compliance and the venous return limb.** §3.7 and §3.8 give `G_vr` a target of
   **1012–1941** (not the 554 an earlier draft of this item carried — the red cell
   correction closed 1.83× of the gap). That target comes from the human salt data and the
   model, and it is for a sourced relation to EXPLAIN, not a value to enter: refitting 2880
   would swap one calibrated constant for another and destroy the only independent test
   this line has. **ADR 0013 is blocked behind this.**
   **READ §3.9 FIRST.** A pass on this in September composed sourced mechanics into a
   conclusion that was withdrawn, and its inputs were ICU and anaesthetised-animal
   preparations. **No healthy-human source has been found for systemic compliance, mean
   systemic filling pressure, or resistance to venous return** — that gap is the real
   obstacle and it is recorded in §7.
   Pmsf, right atrial pressure, stressed
   vs unstressed volume. Replaces `G_vr`; `relations.csv` already names venous compliance
   as the unsourced step in the `CO` row. Record Beard and Feigl 2011 as a declared
   conflict. **`validation/venous_compliance_extract.py` already refutes ADR 0012's
   concavity requirement** — the filling relation is linear over the physiological range,
   and the operative variable is stressed/unstressed, not central/peripheral.
3. **Chronotropic baroreflex.** ADR 0009 gives the reflex one effector; HR now exists.
   **Deliberately deferred** — ADR 0009 says do not re-separate the arms without a
   protocol that needs it, the reflex resets so it nulls at every steady state, and the
   cardiac gain needs a sourcing pass. Best normative source found: **Schumann 2024**,
   *Am J Physiol Heart Circ Physiol* 326:H158–H165, n=980 healthy — and it is about **sex
   differences in BRS**, so it would also give ADR 0014 a second real dimorphic pair.
4. **ADR 0013 decision** on `G_pn`, with its ECF falsifiable test run first.
5. **Body surface area, and it is now worth more than it was.** It was on this list only
   because GFR and cardiac output scale sub-linearly in mass, so `scaling.jl` overstates
   their population spread. It has since acquired two further jobs, both from §3.6.
   **It unlocks the sources.** The two best studies in the cardiac reference literature —
   Luu 2022 (n = 3,206, multi-ethnic) and the Zhan 2024 meta-analysis (12,812) — report
   ventricular volumes indexed to BSA and were both rejected for that reason alone. **And
   it stops a double count.** `CV.SV.NOMINAL` is entered as reported at a cohort mass that
   Petersen gives only by age group, while `size_factor` scales it again and the ensemble
   samples mass by sex — so part of the size dimorphism is counted twice. Needs a height
   row and one BSA formula, sourced.
6. **`RN.URINE.SOLUTE_LOAD = 600 mOsm/day` is now the load-bearing unsourced number on
   the water side.** `ADH.URINE.OSM_MAX` is sourced, so the obligatory volume, `U_base`,
   `k_adh` and every steady state now hang off a conventional figure that
   `RN.URINE.SOLUTE_NONNA` already records as too low — measured totals are 700–900.
   Correcting it moves every ADH constant and needs its own pre-registration.
7. **`check_closure.py` is filling up** — 19 hand-coded relationships, does not scale past
   about twenty.

---

## 5. HOW THINGS BREAK HERE

1. **Exit codes swallowed by pipes.** `cmd | tail` reports `tail`'s status.
   **This recurred on 2026-08-31**, in the same session that rewrote the warning: a
   `git push` to protected `main` was rejected, the piped exit code came back `0`, and
   only a follow-up `git log origin/main` caught it. Verify state, not exit codes.
2. **A wrong author on correct data is invisible to every check.** PMID 2966064 was
   attributed to "Yokota N et al." for two sessions. **The same applies to quoting the
   owner** — directives here are paraphrased for that reason.
3. **A passing test suite is not evidence about a parameter it does not assert on.**
   Nothing asserted on either autoregulation breakpoint while both were wrong.
4. **`Diagnostics` cannot fail.** It is a report. Read the numbers.
5. **Derived values drifting apart.** Run `check_closure.py` after any ledger change.
6. **Silent string replacements.** Assert on every replacement.
7. **A gate cannot check a label you supplied.**
8. **Do not run experiments on uncommitted work.**
9. **Chasing precision that does not exist.** See §1.9.
10. **Citations without an author list.**
11. **A name can carry a convention its value contradicts.** Twice now — §3.2. No gate
    catches it; only wiring does.
12. **EVERY PRE-REGISTRATION SHA CITED IN THIS REPO POINTS AT A COMMIT `main` DOES NOT
    CONTAIN.** `3fbe260`, `e0195f4`, `3fd859b`, `7d97d65`, `9e2cef4`, `d811ca0` — all
    six. **Rebase-merge rewrites the SHA**, and branch protection requires linear
    history, so merge commits are unavailable and every merged branch is rewritten.
    They still resolve locally only because the side branches were never deleted;
    delete those, or clone fresh, and the pre-registration audit trail evaporates.
    This is the header-staleness lesson one level down: **anything a merge can
    invalidate does not belong in a citation either.** Cite the FILE and verify the
    ordering, which survives:

        git log --diff-filter=A -- validation/<name>_prereg.md

    Fixed for `dependency_inversion_prereg.md` on 2026-09-01; the other six are §7.
13. **AN ASSUMPTION YOU WROTE DOWN AND THEN STOPPED SEEING.** On 2026-09-02 a
    composition was built on "right atrial pressure treated as fixed", the
    pre-registration said so **in those words**, and the output was then read as a fact
    about physiology. Withdrawn the same day — §3.9. **Writing an assumption into a
    pre-registration does not discharge it; it records a debt that the result must be
    checked against.** The check is mechanical: before believing a composed number, vary
    each declared assumption and see whether the conclusion survives.
14. **SOURCING THE STRUCTURE FROM THE DISEASE.** The same pass drew its mechanism from ICU
    patients, anaesthetised ganglion-blocked dogs, reduced-renal-mass dogs, anephric
    patients, a hypertensive subgroup and a trout. **A model whose structure is inferred
    from pathological preparations becomes a pathological model**, which §3.3 says has
    already happened once to `G_pn`. Directive 1.7 is the guard. Ask of every mechanistic
    source: **was this preparation designed to show normal physiology, or to break it?**
15. **Dead code hides unledgered constants and stale API assumptions.** `reconstruct.jl`
    and `ensemble.jl` each carried a hardcoded number. Connecting the ensemble surfaced
    three live SciMLBase API breakages that nothing could have caught while it was dead.

---

## 6. SETTLED — DO NOT RELITIGATE

- **Julia stays.** **The `Provenance` job name.** **ADR 0004 default off.**
- **Pre-register before extracting** — it has caught something every time, including twice
  finding faults in the ADR it served, and twice preventing a rule chosen after seeing the
  numbers.
- **Posture is not a target of this model.**
- **Mars500 is not the primary validation target** — its comparisons carry no blood
  pressure.
- **MAP does not scale with body size.** Arterial pressure is intensive. A model in which
  large people are hypertensive *because* they are large would be worse, not better.

---

## 7. OPEN ITEMS

- **20 of 70 parameters** are `assumed` or `calibrated`. `unledgered_check()` lists them.
  The count went UP by two on 2026-08-31 and back DOWN by two on 2026-09-01, and **both
  directions were honest.** Up, because two rows stopped claiming sources they did not
  have. Down, because those same two stopped being primitives at all — see §3.6.
- ~~`CV.CO.NOMINAL` and `RN.H2O.OBLIGATORY_LOSS` are `assumed` with EMPTY citations.~~
  **DONE 2026-09-01.** Both are now `derived`, from the quantities that are actually
  measured.
- **`CV.SV.NOMINAL` is NOT normalised to the 70 kg reference mass.** Petersen reports
  cohort weight by age group and not by sex, so the sexed pair still carries a body-size
  component — and in the ensemble, where mass is sampled by sex, that component is
  counted twice. §4 item 5.
- **`ADH.URINE.OSM_MAX` carries no dispersion and no age.** Tryding reports age-related
  reference intervals; the record read gives means by age, not an SD at one age. Maximal
  concentrating ability falls 16% from 20 to 80 years and this model has no age
  dimension, so 982 is the young-adult ceiling.
- ~~Haematocrit is sourced but the model cannot feel it.~~ **RESOLVED 2026-09-02, and not
  by the route §3.5 predicted.** It said haematocrit becomes live only when
  `CV.PLASMA.ECF_FRACTION` is sourced independently. That is true of the LEVEL, where
  `f_pv` and `Hct` cancel. It is false of the DERIVATIVE: with red cell volume held fixed,
  `dV_blood/dV_ecf = f_pv = BV0(1-Hct)/V_ecf0` depends on `Hct`, so the sourced 0.453/0.395
  pair now moves a result — the male/female ECF excursion ratio, 1.069 to **1.182**. §3.8.
- **Only body mass is sampled in the ensemble.** Every other parameter is one number
  for all members, though the ledger carries dispersion for several. Humans are a
  distribution and the population currently is not — see §1.12.
- **`G_pn` is wrong by 2–19× on the PRESSURE evidence** (§3.3), and **ADR 0013's own
  falsifiable test now blocks changing it** (§3.7). The volume test fails by 5.2× and
  convicts `CV.VENOUS_RETURN.SENSITIVITY`, not this row. Sequencing: `G_vr` first, re-run
  the test, then accept. `G_pn` stays 20.0 in the meantime and that is the pre-registered
  outcome, not an omission.
- **`CV.VENOUS_RETURN.SENSITIVITY` is 1.5–2.1× too stiff against human data** (§3.7, §3.8).
  It was 2.7–5.2× before the red cell correction closed 1.83× of it. Already `calibrated`
  and already §4 item 1; the measured target is now **1012–1941**, from seven primaries
  across four groups and two methods. **It is the only thing standing between this model
  and matching the human pressure AND volume responses simultaneously** — §3.8.
- ~~`Cardiovascular.jl` lets red cell volume expand with plasma.~~ **DONE 2026-09-02**, §3.8.
- ~~Six rows still claim a source that does not exist.~~ **DONE 2026-08-31**, §3.5.
- **`RAAS.RENIN.PRESSURE_GAIN` was calibrated against a baseline that no longer exists** —
  fitted so the low-salt arm doubled PRA from 1.0, and baseline PRA is now 2.31. Not
  urgent: escape drives `fr_mod` to ~1e-7 so no steady state moves. **Blocking for anything
  transient.** The target should be an absolute resting PRA.
- **`RN.URINE.SOLUTE_NONNA` is a residual and the level is too low.** 292 mOsm/day is
  under-sized for urea + K salts because the parent 600 is an unsourced conventional
  figure. The sodium half responds; protein still moves nothing.
- **No population SD for body mass**; the sampled population is uniform over P05–P95.
- **`CV.VENOUS_RETURN.SENSITIVITY` is `calibrated`** and is what §4 item 2 replaces.
- **`ADH.URINE.OSM_MIN` is assumed**; it sets the maximal diuresis.
- **Zerbe's AVP sensitivity spans 0.12–1.66 pg/ml per mOsm/kg** — fourteen-fold,
  reproducible within subject, heritable. Recorded and unused because the model carries no
  plasma vasopressin. The most obvious population covariate in the repo.
- **Circadian amplitudes and acrophases are contested** on both arms. Minors & Waterhouse
  1990 have normative endogenous urinary sodium from ~80 constant routines.
- **Two circadian rows are effectively uncited** (title plus PMC id) — tier C pending
  replacement.
- **`BF.NA.SKIN_ACCUMULATION_RATE` is a secondary citation** via a dissertation.
- **Six pre-registration SHA citations are unverifiable from `main`** — §5 item 12.
  `3fbe260` and `3fd859b` (`RN.AUTOREG.LOWER`, and `autoreg_lower_extract.py` twice),
  `e0195f4` (`verify_rows_prereg`), `7d97d65` and `d811ca0` (ADR 0012 and two extract
  scripts), `9e2cef4` (`salt_sensitivity_extract.py`). Each should become a file
  reference plus the `--diff-filter=A` check. **Deliberately NOT fixed in the same
  change that sourced stroke volume** — it touches rows that change made no claim
  about, and two changes at once leaves neither testable. It is one clean pass.
- **No healthy-human source exists in this repo for systemic vascular compliance, mean
  systemic filling pressure, or resistance to venous return.** Everything currently held
  is post-cardiac-surgery ICU (Maas 2012), compiled from critically ill patients (Magder
  2025), or anaesthetised, ganglion-blocked, splenectomised animals
  (`venous_compliance_extract.py`). **That is the real obstacle on §4 item 2**, not the
  arithmetic. Recorded in `renal_hemodynamics_salt_sources.md` §5.
- **Renal haemodynamics across salt intake has been sourced in men only.** Krikken, van den
  Bosch, Visser, Barba, Textor, Kirkendall and Rorije are all male; Toering 2018 is the
  only sexed source found and gives a direction, not numbers.
- **Eight relations carry no `form_citation`**, grandfathered as tracked debt.
- **`pooling.md` requires columns `ledger/parameters.csv` does not have** — recorded in
  prose instead, by precedent.

---

## 8. ENVIRONMENT

**Owner's machine:** Windows 11, PowerShell, Julia 1.12.6, Python 3.12.10, `gh` authed as
`histoneguy`. Repo at `C:\Users\histo\Claude Coding\integrative-physiology-engine`.

**Branch protection on `main`:** PR required, required status check **`Provenance`**,
linear history, no force push, `enforce_admins: true`.

**Harness notes:** bash heredocs containing backticks or apostrophes fail — write the
script to a file and run it. `python` cannot read Git Bash paths like `/tmp/x`; pass
Windows paths. `pypdf` is installed. **PubMed HTML is behind a cookie wall — use the
E-utilities API.** **cdc.gov returns 403 to WebFetch and serves PDFs as downloads to the
browser tool; NHANES tables are reachable through the NCBI Bookshelf reproduction
instead.**
