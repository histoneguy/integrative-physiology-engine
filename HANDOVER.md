# HANDOVER — Integrative Physiology Engine

**Date:** 2026-08-31
**Repo:** https://github.com/histoneguy/integrative-physiology-engine (public)
**Owner:** Eric George (`histoneguy`)
**`main`:** `1d32104` — **411/411**, all five gates exit 0. Nothing in flight.
**PR #28 merged 2026-08-31**, 18 commits, rebased so every commit message survives.

**Supersedes** the handover written earlier today, which was accurate about the MAP 93
correction and wrong or silent about everything after it. That version has been folded
in; nothing live has been dropped.

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

---

## 2. STATE

**`main` at `1d32104`: 411/411, five gates exit 0.** PR #28 merged 2026-08-31.

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
| `Cardiovascular.jl` | ECF → plasma → blood volume, partitioned central/peripheral (ADR 0012). **CO = HR × SV** (ADR 0011). MAP = CO × TPR. |
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
| 205 | 86.979 | 108.99 | 76.01 | 32.98 |
| 154 | 84.450 | 105.80 | 73.78 | 32.02 |
| 103 | 81.922 | 102.60 | 71.55 | 31.05 |

**Shift 5.0575 mmHg.** Arterial pressure is nowhere regulated; it lands at a stable
intake-dependent value through renal–body fluid feedback alone. **Do not quote beyond 5
significant figures** and do not pin tighter than 1e-4.

SBP/DBP are **reconstructed, not simulated** (ADR 0002) and must be labelled as such
wherever reported. Agreement with the sourced 109/76 is **consistency, not validation** —
`C_art` was derived as SV₀/PP₀.

### Population

`sample_population` draws Sobol over sexed NHANES percentiles. `V_ecf` scales with body
mass (0.20788 L/kg male, 0.20284 female) while **MAP is invariant to 1e-4 mmHg** across a
1.85× mass range. The population is **uniform** over P05–P95, not weight-distributed.

### Ledger

**70 parameters over 80 rows** — 31 `reported`, 27 `derived`, 20 `assumed`, 2
`calibrated`. **22 weak.** Tiers: 35 A, 26 B, 19 C.
**42 relations** — 15 definitional, 14 empirical, 9 conservation, 4 placeholder.
**Ten parameters carry male/female pairs:** `BF.BODY_MASS.{TYPICAL,P05,P95}`,
`CV.ARTERIAL.COMPLIANCE`, `CV.HR.NOMINAL`, `CV.SV.NOMINAL`,
`CV.BLOOD_VOLUME.NOMINAL`, `CV.HEMATOCRIT.NOMINAL`, `CV.PLASMA.ECF_FRACTION`,
`CV.CENTRAL.VOLUME_NOMINAL` — the last two DERIVED from blood volume and
haematocrit, so they became sexed with them.

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

## 4. NEXT, IN ORDER

**Finish the cardiovascular system, then the other systems. Populations are far off — a
population of an incomplete model is a wider set of wrong answers.**

1. **The six remaining `Standard physiological reference. VERIFY.` rows.** Two of two
   examined have been materially wrong. `RN.GFR.NOMINAL` (180 L/day) is the one that would
   actually move the model — it is the whole renal input, and it now also scales with body
   mass. The others: `RN.NA.FRACTIONAL_REABSORPTION`, `RN.H2O.OBLIGATORY_LOSS`,
   `CV.CO.NOMINAL`, `CV.BLOOD_VOLUME.NOMINAL`, `CV.HEMATOCRIT.NOMINAL`.
2. **Venous compliance and the venous return limb.** Pmsf, right atrial pressure, stressed
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
5. **Body surface area.** GFR and CO properly scale with BSA, sub-linearly in mass;
   `scaling.jl` records that linear scaling overstates their spread. Needs a height row.
6. **`check_closure.py` is filling up** — 19 hand-coded relationships, does not scale past
   about twenty.

---

## 5. HOW THINGS BREAK HERE

1. **Exit codes swallowed by pipes.** `cmd | tail` reports `tail`'s status.
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
12. **Dead code hides unledgered constants and stale API assumptions.** `reconstruct.jl`
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
- **`G_pn` is wrong by 2–19×** (§3.3). Parked, one CSV value.
- **Six rows still claim a source that does not exist** (§4 item 1).
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
