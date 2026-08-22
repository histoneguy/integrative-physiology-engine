# HANDOVER — Integrative Physiology Engine

**Date:** 2026-08-22
**Repo:** https://github.com/histoneguy/integrative-physiology-engine (public)
**Owner:** Eric George (`histoneguy`)
**`main`:** `7cd629f` — 153/153, all five provenance gates green

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

Given explicitly by the owner. Several were violated repeatedly before they stuck.

### 1.1 Give commands, not instructions
*"Just give me the script to copy and execute."* *"Remember I know nothing."*
He is not a working programmer. Prefer doing the thing with tools over explaining how.
Where he must run something, give one copy-pasteable block. Windows and PowerShell:
`python`, not `python3`.

### 1.2 Build physiology, not process
*"You're here to simplify and speed up."* The repo already carries five provenance
gates and ten ADRs against five components, one of which is not even connected. Do not
add tooling unless something breaks that cannot be worked around.

### 1.3 Well-established relationships first
*"Prioritize the well established relationships first."* Build E1 before anything that
modulates it. Two structural decisions were already walked back for violating this
(ADR 0004 sodium storage; ADR 0005 circadian, built before the loop it modulates).

### 1.4 Provenance is the point
Every number enters via `ledger/parameters.csv` with citation, tier, extraction method,
species and uncertainty. Every *equation* now enters via `ledger/relations.csv` too.
Nothing is hardcoded in a component.

### 1.5 Stop working from memory
*"Stop working from memory. You're bad at it. Back up your statements."* Issued after
two confident assertions about classic curves, both wrong, both in the same direction.
**Never write a citation you have not opened.**

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

`main` at `7cd629f`. **153/153 in ~40 s.** All five gates exit 0.

### The model — 3 states after `structural_simplify` (`V_icf`, `V_ecf`, `Na_ecf`)

| Component | Status |
|---|---|
| `BodyFluids.jl` | ICF/ECF volumes, sodium mass balance, osmotic equilibration. Inactive-Na storage compartment **default off** (ADR 0004). |
| `Cardiovascular.jl` | Blood volume from ECF, CO from volume, MAP = CO × TPR. TPR scaled by `tpr_mod`. |
| `Renal.jl` | GFR autoregulation (80–160 mmHg), filtered load, pressure natriuresis. Water excretion still a **placeholder** until ADH. |
| `Baroreflex.jl` | Lumped, resetting. Verified in both directions. |
| `Circadian.jl` | Cosinor clock. **NOT CONNECTED**, default off — build order, not tier. |
| `incoming/Raas.jl` | Written, tested nowhere, **not wired in**. Parked deliberately: the relations gate globs `src/components/*.jl`, so a component parked there reads as undocumented relations. |

### The result, unchanged all day and bit-identical across every commit

| intake (mEq/d) | MAP (mmHg) |
|---|---|
| 205 | 93.00003751695675 |
| 154 | 90.53356850133511 |
| 103 | 88.06587129611133 |

Shift **4.934166220845427 mmHg**. Arterial pressure is nowhere regulated in this model;
it lands at a stable intake-dependent value through renal–body fluid feedback alone.

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

**`RN.PRESSURE_NATRIURESIS.SLOPE` stays at 20.0.** Mizelle 1993 puts it 3.68× too steep,
but adopting that alone forces 15.7 mmHg across a 102 mEq/day range — salt-sensitive
hypertensive behaviour, not normotensive. Read the ledger note on that row before
touching it.

### 3.2 The 3.68× gap is only ~40% explained by the missing ANP path

De Nicola 1997 puts ANP at ~40% of the natriuretic increment. If ANP carries 40% and IPE
lacks it, the pressure term inflates by 1/(1−0.4) = **1.67×**. Observed inflation is
**3.68×**. On a log basis ANP accounts for about 0.39 of it.

**A residual factor of ~2.2× is unexplained.** Candidates, none investigated: NCC
downregulation; renal sympathetic nerves; the dog→human filtered-load scaling; the
original calibration target; or the distal-delivery effect in §5. **Do not attribute the
residual to any of them without doing the work.**

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

## 5. ADR 0010 (ANP) — PROPOSED, THREE NAMED BLOCKERS

Sourced across two pre-registered searches (`validation/anp_sourcing_prereg.md`,
`validation/anp_input_link_prereg.md`). Both fixed pooling rules and stop conditions
before any paper was read. Keep doing this.

**The design got simpler as evidence came in.** Rabelink 1989 matched a 3 h head-out
immersion against a natriuresis-matched ANP infusion: immersion gave *equal* natriuresis
at **one-fifth** the plasma ANP rise, while raising renal plasma flow and lowering
fractional lithium reabsorption. ANP is not the proportional carrier — volume expansion
independently raises distal sodium delivery.

IPE has no proximal/distal partition, so it **cannot represent that mechanism**. A
mechanistic plasma-ANP pathway would be precision the surrounding model cannot support.
The component is therefore a **lumped volume-keyed natriuretic term, algebraic in
`V_blood`, with no ANP state**. Model stays at 3 states.

Blocking Accepted:

1. **Pool the k primary immersion papers** behind Epstein's 2.5–3× range. `pooling.md`
   prohibits `range-midpoint`, so there is currently a magnitude, not a number.
2. **Source the central→total blood volume mapping.** Immersion translocates volume
   centrally; `V_blood` is total. Nothing found maps one to the other.
3. **The 2.2× residual** (§3.2).

---

## 6. NEXT, IN ORDER

1. **The three ADR 0010 blockers.** Then ANP lands under a live gate.
2. **The 2.2× residual.** The sharpest open question in the model.
3. **RAAS.** `incoming/Raas.jl` is written and parked. It attaches to `FR_effective` via
   `fr_aldo` and to TPR via `tpr_mod`. It deliberately carries **no escape term** —
   escape emerges from pressure natriuresis alone at the current slope (99% of intake by
   day 2.9 against Hall's days 2–4). Adding ANP will change that; check the escape
   pressure cost *between* the two changes, or the errors cancel and hide each other.
4. **Digitise Mars500.** It gates the joint `G_pn` / ANP-gain re-estimation, which is the
   only way either becomes a posterior rather than a point value.
   `validation/averaging.md` is binding first: fixed 10 s window, applied uniformly.
5. **`check_closure.py` will break before the others.** It hand-codes seven
   relationships and does not scale past ~20. The owner has committed to hundreds of
   variables. Not urgent; do not let it be a surprise.
6. **Circadian last.** ADR 0005 is sound but its dependencies (RAAS, ADH) do not exist.

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
- **Pre-register before extracting.** Three times now it has caught something the
  extraction itself would have missed.

---

## 9. OPEN ITEMS

- **13 of 41 ledger parameters** are `assumed` or `calibrated`. `unledgered_check()`
  lists them.
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

---

## 10. ENVIRONMENT

**Owner's machine:** Windows 11, PowerShell, Julia 1.12.6, Python 3.12.10, `gh` authed as
`histoneguy`. Repo at `C:\Users\histo\Claude Coding\integrative-physiology-engine`.

**Branch protection on `main`:** PR required, required status check **`Provenance`**,
linear history (squash merges), no force push, `enforce_admins: true`.

**Harness note:** bash heredocs containing backticks and apostrophes fail in this
environment. Write the script to a file and run it instead. Also, `python` cannot read
Git Bash paths like `/tmp/x` — pass Windows paths.
