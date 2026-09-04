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

    julia --project=. -e "using Pkg; Pkg.test()"

~40 s warm on this machine. **That is the loop.** CI is the receipt. Do not send
untested code and do not wait on GitHub Actions to find out whether something works.

Run all five provenance gates before committing:

    python tools/ledger_to_julia.py --check
    python tools/check_relations.py --repo .
    python tools/check_closure.py
    python tools/check_adrs.py
    python tools/fix_deps.py

**Comprehensive, but super efficient** — HANDOVER directive 1.10, foundational.
Coverage is not negotiable; cost is. A slow suite is paid on every future run.

**Connect it and run it** — directive 1.11, foundational. Wire up what already
exists before sourcing anything new. Every real defect found on 2026-08-27 was
found by connecting something, and none by any of the five gates.

## Rules you need before you have read the handover

- **Provenance is the point.** Numbers enter via `ledger/parameters.csv`, equations via
  `ledger/relations.csv`, both with citations. Nothing is hardcoded in a component.
- **Never write a citation you have not opened.** A wrong author on correct data passes
  every check in this repo. It has already happened.
- **Never rename the `Provenance` job** in `.github/workflows/ci.yml`. Branch protection
  requires that exact string; a rename once deadlocked every merge.
- **Pre-register before extracting** literature values — see `validation/pooling.md` and
  the three `*_prereg.md` files in `validation/`. It has caught something every time.
- **Judge sources on study quality, not species.** Animal data is legitimate where the
  human experiment cannot ethically be performed. Record species, preparation and range.
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
| `src/components/` | the model — all **nine** components wired, including RAAS, ADH, the clock, and **Respiratory and Blood** (ADR 0017, ADR 0018) |
| `ledger/` | parameters and relations, with provenance |
| `docs/adr/` | **A**rchitecture **D**ecision **R**ecords - structural decisions, each with an evidence tier and a falsifiable test; ADR 0006 defines the tiers |
| `validation/` | targets, averaging and pooling policy, pre-registrations |
| `tools/` | the five gates |
