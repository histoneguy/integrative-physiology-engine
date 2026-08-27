# HANDOVER — Integrative Physiology Engine

**Date:** 2026-08-27
**Repo:** https://github.com/histoneguy/integrative-physiology-engine (public)
**Owner:** Eric George (`histoneguy`)
**`main`:** `b492d2b` — **273/273**, all five provenance gates green

**Supersedes** the handover dated 2026-08-24, which described a 3-state model with no
RAAS, no ADH and an unconnected clock. All of that is now wrong. Everything still live
is folded in below.

---

## 0. HOW THIS WORKS

### What an ADR is

**Architecture Decision Record.** A short document in `docs/adr/` recording a structural
choice: what was decided, what the evidence was, what it forecloses, and what would show
it wrong. They exist so the reasoning outlives the session that produced it — the repo
has fourteen and they are referenced constantly below, so it is worth knowing the term is
not jargon for its own sake.

Each carries a **Status** (Proposed, Accepted, Provisional, Deferred, Superseded), an
**Evidence tier** per ADR 0006, and a **Falsifiable test** — the observation that would
show the structure is wrong. `tools/check_adrs.py` enforces that much.

They are decisions, not documentation. A wrong parameter gets re-estimated; a wrong
structure invalidates every estimate resting on it, which is why they get their own
record.

**Claude Code runs locally on the owner's machine, inside the repo.** Julia 1.12.6,
Python 3.12.10, `git` and `gh` are present and working.

    julia --project=. -e "using Pkg; Pkg.test()"

**The loop is: edit, run the gates, run `Pkg.test()`, read the output, commit.** CI is
the receipt, not the loop. There is no handover script — `CLAUDE.md` loads at session
start and points here. The brief arrives on its own.

---

## 1. BINDING DIRECTIVES

Set by the owner over several sessions. Paraphrased, not quoted — see §7.2.

### 1.1 Give runnable commands, not step-by-step instructions
He directs this work and does not write the code. Do the thing with tools. Where he must
run something, hand him one block he can paste. Windows and PowerShell: `python`, not
`python3`.

### 1.2 Build physiology, not process
The repo already carries five gates and fourteen ADRs. **Do not add tooling unless
something breaks that cannot be worked around.** In the whole project only one change has
met that bar: the sex column, because two sexes do not fit in a schema permitting one
value per parameter.

### 1.3 Well-established relationships first
Build E1 before anything that modulates it. ADR 0006 carries the build order.

### 1.4 Provenance is the point
Numbers enter via `ledger/parameters.csv`, equations via `ledger/relations.csv`, both with
citations. Nothing hardcoded in a component.

### 1.5 Stop working from memory; back up every statement
**Never write a citation you have not opened.** A wrong author on correct data passes
every check here. It has happened.

### 1.6 Animal data is legitimate evidence
Judge a source on study quality, not species. Record species, preparation and tested
range. State *why* no human study exists. Encoded in ADR 0006.

### 1.7 Fundamental studies. New or old — 2026-08-24
Prefer studies that characterise **baseline physiological relationships**. The test is
not the year and **not whether a stressor was used** — Guyton 1957 varied right atrial
pressure precisely to trace the venous return curve, and that is exactly what is wanted.

Ask of any candidate: *if the physiology had come out differently, what would this
paper's conclusion have been?* If the answer is "the device would have failed validation"
or "the index would have been unconfounded", the relationship is the **instrument**, not
the subject.

**Why it exists.** Everything sourced 22–24 August came from the second kind — can
bio-impedance *detect* blood loss, does Modelflow SV *mirror* withdrawn volume, does
preload *confound* augmentation index. Median year 2018, nothing before 2004. And every
extraction came back with a confound attached, which was recorded as bad luck. It was
not: a study built around a stressor as its endpoint returns a stressor-contaminated
number.

**Search relationships, not variables.** Modern stressor studies have structured
abstracts with the numbers in them; foundational measurements often do not. A search
ranked by what extracts easily selects against the data you want, invisibly.

### 1.8 Cast a wide net. Do not anchor on a few papers — 2026-08-25
**Do not fix on a small number of papers early and ignore the wider literature.**

**Why it exists.** The circadian sweep returned 437 records across twelve queries. Five
papers would have been wrong on **both** arms: Kerkhof alone makes the BP rhythm entirely
exogenous, and Shea 2011 contradicts him with a stronger design; and the sodium amplitude
and acrophase are both contested, with one large cosinor study finding the rhythm
non-significant and another placing the acrophase nearly antiphase. None of that was
visible from the first five hits.

### 1.9 Significant figures. Round to real numbers — 2026-08-27
**The sources support 2 to 4 significant figures. Store that, not sixteen.**

Tolerances follow the physics, not the arithmetic: **closure 1e-3, test pins 1e-4,
identities between rounded values 1e-3.** Still sixty times tighter than the 6% error
that motivated the closure gate.

**Exception, and it is the instructive one:** significant figures belong to the quantity
that carries the information. `RN.NA.FRACTIONAL_REABSORPTION` must keep 7 figures because
what matters is `1 - FR_Na = 0.0081`; rounding it to 0.9919 broke sodium balance
immediately. A small difference of large numbers needs digits on the large numbers.

**What this cost, so it is not repeated:** roughly a third of one session. Demanding
bit-identity of ADR 0012 and rewriting its falsifiable test when it failed at 1e-13.
Revising `solver_agreement` twice over a state sitting at 2e-17 then 7e-10. Storing SV0
to sixteen digits to erase a 6.2e-8 mmHg difference. Every structural change then broke a
pin and needed another round. Rounding the whole ledger left **every simulated result
unchanged** — that is the proof the digits carried nothing.

---

## 2. STATE

`main` at `b492d2b`. **273/273.** All five gates exit 0.

**The ADR 0006 spine is COMPLETE.** Renal, cardiovascular, baroreflex, RAAS, ADH all
exist and are connected; circadian, the last item, was wired on 26 August.

### The model — 7 states after `structural_simplify`

`bf.V_icf`, `bf.V_ecf`, `bf.Na_ecf`, `br.tpr_mod`, `br.sp`, `ra.pra`, `ra.esc`

| Component | Status |
|---|---|
| `BodyFluids.jl` | ICF/ECF volumes, sodium mass balance, osmotic equilibration. Inactive-Na storage **default off** (ADR 0004). |
| `Cardiovascular.jl` | ECF → plasma → blood volume, partitioned central/peripheral (ADR 0012). **CO = HR × SV** (ADR 0011). MAP = CO × TPR. |
| `Renal.jl` | GFR autoregulation, filtered load, pressure natriuresis, RAAS tubular increment, circadian modulation on the excreted fraction, **osmoregulated water excretion**. |
| `Baroreflex.jl` | Lumped, resetting, TPR effector only. Setpoint scaled by the clock. |
| `Raas.jl` | **Now active at rest** (see §3.1). Rectified renal baroreflex → renin → aldosterone → tubular reabsorption, with first-order escape. **No AngII vasoconstriction** — deliberate. |
| `Adh.jl` | Osmolality → antidiuretic activity → urine osmolality; volume follows as solute load ÷ concentration. Algebraic, no states. |
| `Circadian.jl` | Cosinor clock, **connected** to renal excretion and the reflex setpoint. **Default OFF** — both arms' parameters are contested. |

### The result

| intake (mEq/d) | MAP (mmHg) |
|---|---|
| 205 | 87.001 |
| 154 | 84.450 |
| 103 | 81.900 |

**Shift 5.101 mmHg.** Arterial pressure is nowhere regulated; it lands at a stable
intake-dependent value through renal–body fluid feedback alone.

**These moved down 6 mmHg on 2026-08-27 and the shift did not move at all.** See §3.1.
That is the useful part: the operating point was wrong, the salt-sensitivity finding it
sat on was not affected, because the shift is set by `G_pn` and not by where the
operating point sits.

**Do not quote this to more than 5 significant figures** and do not pin it tighter than
1e-4. See §1.9.

### Ledger

61 parameters — 22 `reported`, 21 `derived`, 16 `assumed`, 2 `calibrated`. **18 weak.**
41 relations — 15 definitional, 14 empirical, 8 conservation, 4 placeholder.
Two parameters carry male/female pairs; the rest are `both`.

### Gates

`ledger_to_julia.py --check`, `check_relations.py --repo .`, `check_closure.py`,
`check_adrs.py`, `fix_deps.py`. **Never rename the `Provenance` job in `ci.yml`** —
branch protection requires that exact string.

`check_closure.py` now runs **per sex**. `check_relations.py` is forward-only with
grandfathered debt.

---


## 3.1 MAP 93 was the brachial 120/80 convention, and it was load-bearing

`CV.MAP.SETPOINT` was **93.0** under the citation *"Standard physiological reference.
VERIFY."* It was never verified. It is 80 + 40/3 = 93.33 - **the textbook brachial
120/80 rounded** - and it is now **87.0**, derived from sourced central pressure
(Gomez-Sanchez 2021, 501 adults without cardiovascular disease).

**What exposed it was an impossibility, not a search.** Deriving the pulse form factor
gave 0.515. It cannot exceed 0.5: the fraction of pulse pressure above the mean must be
below half when diastole is longer than systole. A brachial MAP was being divided by a
central pulse pressure.

### Three things followed, and the third is the one to read

1. **`CV.TPR.NOMINAL` moved** 0.01292 -> 0.0120833, since it is MAP/CO by definition.
   Every steady state dropped about 6 mmHg. Eight test pins were repinned.

2. **The salt-sensitivity finding did not move.** The shift is 5.101 where it was 5.0996
   - 0.2%. It is set by `G_pn`, not by the operating point. **ADR 0013 survives the
   correction of the number underneath it**, which is worth more than if it had never
   been wrong.

3. **RAAS silently switched itself on.** The van Ochten renin threshold is 93 mmHg and
   the old setpoint was 93 mmHg, so the model sat EXACTLY ON the rectification point and
   RAAS was inactive at baseline **by construction**. `Raas.jl` had flagged this in its
   own divergence notes as fragile and resting on one unverified number. That was the
   number. The model now sits 6 mmHg below threshold: renin drive 0.069, **PRA 2.31x**.
   More physiological, not less - resting renin is not zero.

**There was a test asserting the coincidence** (`RAAS_RENIN_PRESSURE_THRESHOLD ==
CV_MAP_SETPOINT`). It has been **inverted to a strict inequality**, not repinned. An
equality would pass again the moment the two numbers coincided for any reason, including
by accident, and would go on certifying a structural artefact as intended behaviour.

### What this leaves open

**`RAAS.RENIN.PRESSURE_GAIN` was calibrated against a baseline that no longer exists** -
it was fitted so the low-salt arm doubled PRA from 1.0, and baseline PRA is now 2.31.
**Not urgent**: escape drives `fr_mod` to 7.7e-7 regardless, so no steady state moves and
the loop still closes at 1.0000. **Blocking for anything transient.** The target should
be an absolute resting PRA, not a fold-change from an artefact.

### The six others exactly like it - DO THIS NEXT

**Take the general lesson, not the specific one.** A number carrying "VERIFY" sat in the
ledger for weeks, silently set another parameter, and silently disabled an entire
subsystem. It was caught by an arithmetic impossibility, not by any of the five gates.

The ledger was grepped. **`CV.MAP.SETPOINT` was one of seven rows carrying the identical
string "Standard physiological reference. VERIFY.", and it is the only one discharged.**
All six survivors are load-bearing:

| row | value | drives |
|---|---|---|
| `CV.CO.NOMINAL` | 7200 mL/min | `CV.TPR.NOMINAL` and `CV.SV.NOMINAL` - the same position MAP held |
| `CV.HEMATOCRIT.NOMINAL` | 0.45 | plasma fraction `f_pv`, and it is the row whose own note says sex is deferred |
| `CV.BLOOD_VOLUME.NOMINAL` | 5.0 L | `f_pv` and the central volume reference `VC0` |
| `RN.GFR.NOMINAL` | 180 L/day | filtered sodium load - the whole renal input |
| `RN.NA.FRACTIONAL_REABSORPTION` | 0.9918651 | sodium balance; `1 - FR` is the excreted fraction |
| `RN.AUTOREG.LOWER` | 80 mmHg | autoregulation range, and **87 now sits only 7 mmHg above it** |
| `RN.H2O.OBLIGATORY_LOSS` | 0.5 L/day | water balance |

**These are a different category from the nine `assumed` rows with empty citations.**
Those are honestly labelled guesses and the relations gate already tracks them as debt.
These seven claim `extraction_method = reported`: they assert a source exists. For MAP
that assertion was false and the number was a unit-convention artefact.

`RN.AUTOREG.LOWER` is the one to look at first. The operating point moved toward it.

**No gate catches this class.** All five pass on the ledger as it stands. A gate that
rejects `reported` with a non-citation would have caught MAP 93 at entry - but per
directive 1.2, do not build it until this sourcing pass shows the failure recurring.

## 3. THE FINDING THAT MATTERS MOST

### The model is 2 to 19 times too salt-sensitive. It is calibrated to hypertensives.

Sourced under `validation/salt_sensitivity_prereg.md`, committed before any paper was
read. Reproduce with `python validation/salt_sensitivity_extract.py`.

| source | trials | MAP mmHg/100 mmol | implied `G_pn` |
|---|---|---|---|
| Cutler 1997 | 32, n=2635 | 1.70 | 59 |
| He/Li/MacGregor 2013 | 34, n=3230 | 1.96 | 51 |
| He & MacGregor 2002 | 11, n=2220 | 2.30 | 44 |
| Graudal 2019 | 133 RCTs | 0.53 | 188 |
| Graudal 2017 Cochrane | 89, n=8569 | 0.25 | 393 |

**The model gives 4.84 mmHg per 100 mmol.** Every estimate lands below it; the closest is
2.1× away. 4.84 is not a normotensive number — it sits among the *hypertensive*
comparators.

**`G_pn` should be LARGER than 20, not smaller. The Mizelle dog comparison points the
wrong way**, and the 3.68× inflation and 2.2× residual were an argument about moving a
number in a direction the human evidence contradicts. The residual audit stands as
arithmetic and is off the critical path.

**ADR 0013 proposes 20.0 → 51.0 and is PARKED at the owner's decision.** It is one CSV
value and can be changed in ten minutes. Its falsifiable test uses a variable that did
not set the value: at `G_pn = 51` the model moves `V_ecf` by 0.155 L per 102 mEq/day —
source the human ECF or weight response and compare. Run that before accepting.

`bench/gpn_sweep.jl` shows the loop closes exactly at every value from 20 to 188, and
`V_ecf` gets *tighter* as `G_pn` rises. At Graudal's 188 the shift is 0.54 mmHg against
the 0.5 mmHg `min_map_shift` threshold — on that reading the effect this model exists to
demonstrate is barely visible.

---

## 4. ADR 0006 WAS AMENDED — RETROSPECTIVE

The tier table made species a proxy for quality: `species-extrapolated` sat in E3, which
forces default OFF. That would have demoted the entire primary basis of
`Renal.FR_effective` while leaving `RN.PRESSURE_NATRIURESIS.SLOPE` unchallenged — a
fitted constant labelled `species: human`. **The rule protected the fitted number and
penalised the measured ones.**

E2 now admits animal data where the human experiment is not ethically performable, with
species, preparation and range recorded. **ADR 0004 stays E3 and default off** — its
weakness is single-group small-*n* in humans; species was never its problem.

---

## 5. THE CARDIOVASCULAR TURN — ADRs 0011 to 0014

### ADR 0012: central/peripheral partition, stage 1 built

`V_blood` is **not a sensed variable anywhere in the body**. Cardiopulmonary receptors and
atrial ANP release respond to *central* filling, so ADR 0010's unsourceable input link was
a category error rather than a gap in the literature.

    V_central ~ f_c * V_blood
    V_periph  ~ V_blood - V_central

`f_c` is constant, so stage 1 is a change of variables. **Stage 2 is VENOUS TONE, not
posture** — see below.

### ADR 0011: CO = HR × SV, built

Exact identity with the previous CO equation. What it buys is that HR and SV **exist**:
separately measurable where `G_vr` never was, a stroke volume for `reconstruct.jl`, and
the variable a chronotropic reflex will act on.

**The filling relation is LINEAR over the range the model traverses.** The salt step
displaces 2.7% of blood volume; over that excursion any smooth curve is its own tangent.
Concavity matters across a **population** range (±12% at ±2 SD), not within one
individual's step.

### ADR 0014: sex is a model dimension

`sex` column, key `(param_id, sex)`. **A parameter has either one `both` row or both a
male and a female row — never one alone.** Where only one sex has been studied the row
stays `both` with the cohort in its notes.

`param(sym, :both)` on a dimorphic parameter is an **error, not an average** — averaging
two sexes describes no one.

**The first pair — heart rate and stroke volume — cannot move the model, and that is
correct.** `SV0` is derived to preserve `CO0`, so HR × SV is the same either way. Katori
1979 found **no sex difference in cardiac or stroke INDEX** once normalised to body
surface area; Eikendal 2016 finds absolute CO lower in women. Both true: **the difference
is body size.**

**So `body_mass` is where sex actually enters, and it is still a hard-coded 70.0
argument, not a ledger row.** That is the next thing that makes sex bite. Haematocrit
after it — androgen-driven erythropoiesis is not a size effect and will not dissolve into
body mass.

### Posture is descoped

`ensemble.jl` states the primary workload as many virtual individuals over long horizons;
head-up tilt is a **TODO** challenge protocol in `targets.md`, not a target. What survives
from the posture work is diagnostic: `V_blood` is not the filling variable, and the
filling relation is concave across a population.

---

## 6. NEXT, IN ORDER

**Finish the cardiovascular system, then the other systems. Populations are far off —
a population of an incomplete model is a wider set of wrong answers.**

1. **Arterial compliance.** `PP = SV / C_art` gives pulse pressure and hence systolic and
   diastolic. `reconstruct.jl` has taken `SV` and `C_art` as arguments since the repo
   began and has never been connected; `SV` now exists. **The model cannot currently
   produce a systolic pressure at all.** Smallest remaining piece with a real capability
   gain. `form_factor` needs a ledger row (`reconstruct.jl` has a TODO saying so).
2. **Venous compliance and the venous return limb.** Pmsf, right atrial pressure,
   stressed vs unstressed volume. This replaces `G_vr`, and `relations.csv` already names
   venous compliance as the unsourced step in the `CO` row. Directive 1.7 re-aimed that
   search at the relationship. Record Beard and Feigl 2011 as a declared conflict — they
   argue Guyton's interpretation interchanges independent and dependent variables.
3. **`body_mass` as a sex-specific ledger row.** Dissolves three separate sex questions
   into one parameter.
4. **Chronotropic baroreflex.** ADR 0009 gives the reflex one effector; HR now exists.
5. **ADR 0013 decision** on `G_pn`, with its ECF falsifiable test run first.
6. **`check_closure.py` is filling up** — it hand-codes thirteen relationships and does
   not scale past about twenty.

---

## 7. HOW THINGS BREAK HERE

1. **Exit codes swallowed by pipes.** `cmd | tail` reports `tail`'s status.
2. **A wrong author on correct data is invisible to every check.** PMID 2966064 was
   attributed to "Yokota N et al." for two sessions. **The same applies to quoting the
   owner** — directives here are paraphrased for that reason.
3. **A passing test suite is not evidence about a parameter it does not assert on.**
4. **`Diagnostics` cannot fail.** It is a report. Read the numbers.
5. **Derived values drifting apart.** Run `check_closure.py` after any ledger change.
6. **Silent string replacements.** Assert on every replacement.
7. **A gate cannot check a label you supplied.** ADR 0012's first draft tiered its
   load-bearing row E1 when the source is one group of ten, and `check_adrs.py` returned
   OK *because* of that.
8. **Do not run experiments on uncommitted work.** Perturbing the ledger then
   `git checkout`-ing it discarded three rows that had never been committed.
9. **CHASING PRECISION THAT DOES NOT EXIST.** See §1.9. This one cost the most.
10. **Citations without an author list.** Four defects found by audit on 2026-08-25,
    including one relation justified by a **pointer to a ledger row** rather than to
    literature — circular, and dangling after a rename.

---

## 8. SETTLED — DO NOT RELITIGATE

- **Julia stays.**
- **The `Provenance` job name.**
- **ADR 0004 default off.**
- **Pre-register before extracting** — it has caught something every time, including
  twice finding faults in the ADR the pre-registration served.
- **Posture is not a target of this model.**
- **Mars500 is not the primary validation target.** Its required comparisons carry **no
  blood pressure**, so it cannot test the claim the model exists to demonstrate. It
  anchors ADR 0004's storage question, which is E3 and parked.

---

## 9. OPEN ITEMS

- **18 of 61 parameters** are `assumed` or `calibrated`. `unledgered_check()` lists them.
- **`G_pn` is wrong by 2–19×** (§3). Parked, one CSV value.
- **`body_mass` is not a ledger row** and is the largest un-modelled dimorphism.
- **`CV.VENOUS_RETURN.SENSITIVITY` is `calibrated`** and is what item 2 replaces.
- **`RN.URINE.SOLUTE_LOAD` is assumed and held constant.** It should track salt and
  protein intake; holding it fixed makes the model under-respond on the water side.
- **`ADH.URINE.OSM_MIN` is assumed**; it sets the maximal diuresis.
- **Zerbe's AVP sensitivity spans 0.12–1.66 pg/ml per mOsm/kg** — fourteen-fold,
  reproducible within subject, heritable. Recorded and unused because the model carries
  no plasma vasopressin. The most obvious population covariate in the repo.
- **Circadian amplitudes and acrophases are contested** on both arms. Minors & Waterhouse
  1990 have normative endogenous urinary sodium from ~80 constant routines — the source
  to get.
- **Two circadian rows are effectively uncited** (title plus PMC id, no authors) and are
  tier C pending replacement.
- **`BF.NA.SKIN_ACCUMULATION_RATE` is a secondary citation** via a dissertation.
- **`RN.AUTOREG.LOWER = 80` is genuine debt.**
- **Eight relations carry no `form_citation`**, grandfathered as tracked debt.
- **`pooling.md` requires columns `ledger/parameters.csv` does not have.**

---

## 10. ENVIRONMENT

**Owner's machine:** Windows 11, PowerShell, Julia 1.12.6, Python 3.12.10, `gh` authed as
`histoneguy`. Repo at `C:\Users\histo\Claude Coding\integrative-physiology-engine`.

**Branch protection on `main`:** PR required, required status check **`Provenance`**,
linear history, no force push, `enforce_admins: true`.

**Harness notes:** bash heredocs containing backticks or apostrophes fail — write the
script to a file and run it. `python` cannot read Git Bash paths like `/tmp/x`; pass
Windows paths. `pypdf` is installed for reading supplied PDFs. PubMed HTML is behind a
cookie wall — use the E-utilities API.
