# CLAUDE.md

**Read `HANDOVER.md` first, in full, before touching anything.** It is the authoritative
brief: binding directives, current state, the two load-bearing findings, what breaks
here and why. This file exists only to make sure you get there and to carry the few
things you need before you have read it.

Do not duplicate `HANDOVER.md` here. Two copies of a fact is how they drift apart, which
is the failure mode this whole repo is organised against.

## What this is

An independent whole-body integrative human physiology model in Julia /
ModelingToolkit, built from published literature with full parameter provenance.
Arterial pressure is an **output** of the closed loop, not a setpoint — that is the
claim the model exists to demonstrate rather than assert.

## The development loop

    # iterating - fast, and you can run ONE testset
    IPE_TESTS="red cell" julia --project=. -e 'include("test/runtests.jl")'

    # before committing - slower on purpose, --check-bounds=yes catches indexing bugs
    julia --project=. -e "using Pkg; Pkg.test()"

**That is the loop.** CI is the receipt. Do not send untested code and do not wait on
GitHub Actions to find out whether something works.

**MEASURED 2026-09-16, because the old note here said "~40 s warm" and it has not been
that for a long time.** One model testset about 2 min; **a ledger-only change checked
against `IPE_TESTS="ledger provenance"` costs 23 s.** Most edits in this repo are ledger
edits, so use the filter.

**NO FULL-SUITE WALL-CLOCK FIGURE IS QUOTED HERE ON PURPOSE.** It has measured anywhere
from 2m13s to 6m30s for code that differed by nothing. The 23 s figure is quotable
because it is dominated by Julia startup rather than by the machine's mood; a whole-suite
number is not.

**THE COST IS COMPILATION, NOT INTEGRATION, AND IT IS PER JULIA PROCESS.** Measured
2026-09-18:

| | |
|---|---|
| `using IPE` | **7.7 s** |
| first `build_raw_model()` — Julia compiling MTK's machinery for our types | **18.3 s** |
| second call, *any* configuration | **0.0 s** |
| first full `structural_simplify` + `ODEProblem` + `solve` | **14.0 s** |
| another config, same structure, different parameters | **0.06 s** |
| another config, **different structure** (`adh=false`, `storage=false` …) | **1.2–1.9 s** |
| **400-day closed-loop solve, warm** | **0.000 s**, 414 steps |

**So roughly 40 s is paid ONCE PER PROCESS and almost nothing after that.** A 400-day
integration of the whole loop is free; `salt_step()` is 0.112 s warm.

**THE PRACTICAL CONSEQUENCE, AND IT IS THE BIGGEST SINGLE DEV-LOOP LEVER: BATCH YOUR
CHECKS INTO ONE `julia -e`.** Twenty small invocations cost twenty × 40 s of identical
recompilation and produce nothing the one invocation would not. On 2026-09-17 that pattern
burned roughly fifteen minutes on its own.

**`PrecompileTools` was considered and NOT added.** It would cache the 18.3 s into the
package image, but the workload re-runs whenever `src/` changes — which is every edit
during development — so it moves the cost rather than removing it. Do not add tooling for
this.

Repeated identical calls are already free, so memoising them buys nothing; it was tried and
reverted. See HANDOVER §5.

**A SINGLE WALL-CLOCK TIMING ON THIS MACHINE IS NOT EVIDENCE.** The same commit measured
2m14s and 5m40s in one session. Compare paired runs taken back to back, or CI job
durations.

Rebuild the GUI after any ledger or model change — it ships the numbers AND the
citations, so a stale one misquotes both:

    julia --project=. tools/export_gui_data.jl
    python tools/build_gui.py

Run all six provenance gates before committing:

    python tools/ledger_to_julia.py --check
    python tools/check_relations.py --repo .
    python tools/check_closure.py
    python tools/check_adrs.py
    python tools/fix_deps.py
    python tools/check_tolerances.py

**The sixth is the significant-figures rule made structural** — no comparison tolerance
may be tighter than its target's printed precision. A tight comparison against a
constant the model is *derived from* is legitimate and must declare itself with a
`CLOSURE PIN` or `WIRING PIN` comment; the gate does not guess, because the version
that guessed had a 100% false-positive rate.

**Comprehensive, but super efficient** — HANDOVER directive 1.10, foundational.
Coverage is not negotiable; cost is. A slow suite is paid on every future run.

**Connect it and run it** — directive 1.11, foundational. Wire up what already
exists before sourcing anything new. Every real defect found on 2026-08-27 was
found by connecting something, and none by any of the five gates.

## Rules you need before you have read the handover

- **Provenance is the point.** Numbers enter via `ledger/parameters.csv`, equations via
  `ledger/relations.csv`, both with citations. Nothing is hardcoded in a component.
- **A derived number cannot be more precise than what it came from.** Significant
  figures do not increase through arithmetic: three-figure inputs give a three-figure
  answer. And the inputs' uncertainty must be carried, not dropped - a derived row whose
  inputs have error bars has one. The only exception is a value that exists to close an
  identity `check_closure.py` checks, which is bookkeeping and never a precision claim.
  **No model output may be quoted beyond what its weakest input supports**, and a
  disagreement inside that uncertainty is not a finding. Directive 1.13, enforced by
  `tools/ledger_to_julia.py`.
- **Never write a citation you have not opened.** A wrong author on correct data passes
  every check in this repo. It has already happened.
- **Never rename the `Provenance` job** in `.github/workflows/ci.yml`. Branch protection
  requires that exact string; a rename once deadlocked every merge.
- **Pre-register before extracting** literature values — see `validation/pooling.md` and
  the three `*_prereg.md` files in `validation/`. It has caught something every time.
- **Judge sources on study quality, not species.** Animal data is legitimate where the
  human experiment cannot ethically be performed. Record species, preparation and range.
  **For neurogenic control of pressure through renal or baroreceptor mechanisms with no
  usable human data, the default source is Lohmeier's conscious-dog work** — directive
  1.15. It is a default for an empty slot, and it does **not** relax the rule above it:
  never write a Lohmeier citation you have not opened.
- **Check exit codes explicitly.** Piping into `tail` or `head` reports the pipe's
  status, not the command's.
- **Do not add tooling** unless something breaks that cannot be worked around.
- **Paraphrase the owner; do not quote him.** Record what was decided, not a
  reconstruction of how it was said.

## Known stale file

`START-HERE.md` describes a workflow built around `sprint.py` and self-applying
`apply-*.py` scripts, from when the assistant could not execute anything. **That
workflow is obsolete** — see `HANDOVER.md` §0, which explicitly says not to reinstate
it. The file has not been rewritten yet.

## Where things are

| Path | What |
|---|---|
| `HANDOVER.md` | the brief — read it |
| `OPEN-QUESTIONS.md` | everything awaiting the owner's decision, with what would resolve each |
| `gui/` | the GUI: `index.html` is self-contained and opens by double-clicking |
| `src/components/` | the model — all **ten** components wired, including RAAS, ADH, the clock, **Respiratory and Blood** (ADR 0017, ADR 0018) and the **Thyroid** axis (ADR 0019) |
| `ledger/` | parameters and relations, with provenance |
| `docs/adr/` | **A**rchitecture **D**ecision **R**ecords - structural decisions, each with an evidence tier and a falsifiable test; ADR 0006 defines the tiers |
| `validation/` | targets, averaging and pooling policy, pre-registrations |
| `tools/` | the six gates |
