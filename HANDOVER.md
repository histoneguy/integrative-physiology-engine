# HANDOVER — Integrative Physiology Engine

**Date:** 2026-08-19
**Repo:** https://github.com/histoneguy/integrative-physiology-engine (public)
**Owner:** Eric George (`histoneguy`)
**State:** Working minimal closed-loop model on `main`. CI green. 3 PRs merged.

---

## 1. USER DIRECTIVES — these are binding, read them first

These were given explicitly during the session and were repeatedly violated before
they stuck. Follow them.

### 1.1 One download, one command, one answer
Every sprint ships as **a single self-applying Python script**. The user downloads
it into the project folder and runs `python apply-whatever.py`. It handles fetching,
branch switching, applying, checking, and pushing. The user answers `y` twice.

Do NOT send: loose `.patch` files, tarballs to extract over folders, multi-step git
sequences, or instructions to hand-edit files.

Generate scripts with `tools/make_selfapply.py`:

    python3 tools/make_selfapply.py out.py 0001-*.patch

### 1.2 Give commands, not instructions
The user has said plainly: *"just give me the script to copy and execute"* and
*"Remember I know nothing."*

Give a copy-pasteable block. Do not explain what a branch is unless asked. Do not
say "open X and change Y" — write the command that does it.

**PowerShell, not bash.** The user is on Windows. Heredocs (`<< 'EOF'`) fail.
Use `@' ... '@ | Set-Content file.json` for multi-line input. `python`, not
`python3`. Backslash paths in Explorer commands.

### 1.3 Test before sending — non-negotiable
The repo is public. Clone it, apply the patch, run the checks. Every time.

    git clone -q https://github.com/histoneguy/integrative-physiology-engine.git /tmp/t
    cd /tmp/t && <apply patch> && python3 tools/ledger_to_julia.py --check \
      && python3 tools/check_closure.py && python3 tools/check_adrs.py \
      && python3 tools/fix_deps.py

Both patches that were tested this way worked first time. Every untested one failed.

### 1.4 Build physiology, not process
Direct quote: *"You're here to simplify and speed up."*

The repo has 4 provenance tools and 8 ADRs against 3 physiological components. That
ratio is already wrong. Do not add tooling unless something breaks that cannot be
worked around. Prefer a smaller model that runs to a larger one that does not.

### 1.5 Well-established relationships first
Direct quote: *"Prioritize the well established relationships first"* and
*"We need a basic physiology model first before we start worrying about
circadian/sex differences."*

Build E1 (multiply replicated, human, mechanistically understood) before anything
that modulates it. See ADR 0006 for tiers, ADR 0007 for build order.

Two structural decisions were already walked back for violating this: sodium storage
(ADR 0004, downgraded to Provisional, default off) and circadian (ADR 0005, correct
but built before the renal loop it modulates, currently unconnected).

### 1.6 Provenance is the point
Every number enters via `ledger/parameters.csv` with citation, tier, extraction
method, species, and uncertainty. Nothing is hardcoded in a component. Generated
commits keep their authorship with the user's `Signed-off-by` added — do not
re-author generated work under the user's name.

---

## 2. WHAT EXISTS

### The model — `src/components/`

| File | Status |
|---|---|
| `BodyFluids.jl` | ICF/ECF volumes, sodium mass balance, osmotic equilibration. Optional inactive-Na storage compartment, **default off**. |
| `Cardiovascular.jl` | Blood volume from ECF, cardiac output from volume, MAP = CO × TPR. TPR is a **constant** until baroreflex lands. |
| `Renal.jl` | GFR autoregulation, filtered load, pressure natriuresis. Water excretion is a **placeholder** (intake − insensible) until ADH lands. |
| `Circadian.jl` | Cosinor clock, independent renal and CV arms. **NOT CONNECTED.** |

`src/assemble.jl` closes the loop, `salt_step()` runs the Mars500 protocol,
`check_pressure_natriuresis()` evaluates the ADR 0007 test.

### The result

Structural simplification: **38 states → 3** (`V_icf`, `V_ecf`, `Na_ecf`).

Salt step, 30 days per level, state carried across:

| intake (mEq/d) | excretion | ECF (L) | MAP (mmHg) |
|---|---|---|---|
| 205 | 205.0 | 14.560 | 93.00 |
| 154 | 154.0 | 14.367 | 90.53 |
| 103 | 103.0 | 14.174 | 88.07 |

4.93 mmHg across a 102 mEq/day range (~2.5 mmHg per 50 mEq), consistent with human
salt-sensitivity data for normotensive adults. **Reproduced identically on CI**
(MAP 93.00003726, shift 4.9341416) — machine-independent.

Arterial pressure is nowhere regulated in this model. It lands at a stable
intake-dependent value through renal–body fluid feedback alone. That is the Guyton
claim demonstrated rather than asserted.

### Tooling — `tools/`

| Tool | Purpose |
|---|---|
| `ledger_to_julia.py` | Ledger → `src/LedgerParams.jl`. Validates citation, units, tier, method. `--check` for CI. |
| `check_closure.py` | Seven relationships derived values must satisfy. **Exists because rounding three of them independently produced a lethal model that reported Success.** |
| `check_adrs.py` | Evidence tiers on ADRs. E3 requires a falsifiable test and must default off. |
| `fix_deps.py` | Syncs `Project.toml` with actual imports. Adds stdlibs; reports third-party without adding. |
| `make_selfapply.py` | Patch series → one runnable script. |

All four run in CI (job name: **Provenance**) and in `sprint.py`.

### ADRs — `docs/adr/`

0001 Julia/MTK/adaptive stiff · 0002 cycle-averaged · 0003 multirate **Deferred**
· 0004 Na storage **Provisional, default off** · 0005 circadian **built, not
connected** · 0006 evidence tiers · 0007 minimal closed loop · 0008 diagnostic
confidence

---

## 3. WHY THINGS KEPT BREAKING

Root cause: **code was written that could not be executed, then presented as if it
had been.** The user became the test harness.

Four modes, all still live risks:

1. **Unverified environment assumptions.** Wrote against ModelingToolkit v9 when the
   registry serves v11. Pinned CI to Julia 1.10 while the user runs 1.12. Assumed
   bash on Windows. **Check the registry and the user's actual versions first.**

2. **Derived values drifting out of consistency.** `FR_Na`, `f_pv` and the
   osmolality relation were each computed correctly then rounded independently.
   Individually plausible, collectively lethal — the model drove intracellular water
   to zero and reported `retcode: Success` with settling tolerance 1.13e-6.
   `check_closure.py` now catches this class. **Run it after any ledger change.**

3. **Process built instead of physiology when blocked.** See directive 1.4.

4. **Diagnostics asserting beyond their evidence.** Three confident wrong findings in
   consecutive runs: a "missing Jacobian" that was the diagnostic's own omitted
   kwarg, a "spectral gap" at 18,000 years from inverting a conserved quantity's zero
   eigenvalue, and a cost-regime verdict from 22 RHS evaluations. ADR 0008 fixes the
   tooling. **The habit is the assistant's — state evidence, refuse to conclude
   below threshold.**

---

## 4. ENVIRONMENT

**Julia is NOT available in the assistant's sandbox.** `julialang-s3.julialang.org`
returns `x-deny-reason: host_not_allowed`. Building from source is not viable in a
container that resets between sessions.

**REQUESTED ALLOWLIST** (user considers the 20-minute CI loop unacceptable):

    julialang-s3.julialang.org    binaries
    pkg.julialang.org             registry and packages
    cache.julialang.org           artifacts

Caveat, stated to the user: the container wipes between sessions, so each session
would pay ~20 min for install plus ModelingToolkit precompile — about one CI cycle.
Every run after that drops to seconds.

**Until then:** most failures were catchable without executing Julia — wrong API
version, undeclared imports, argument order, inconsistent constants. Read the
registry, read the source, run `check_closure.py`, and always apply patches to a
fresh clone first.

**What IS available:** `git clone` of the public repo (verified), `web_search`,
`web_fetch`. GitHub API is rate-limited from the shared sandbox IP — have the user
run `gh` commands instead.

**User's machine:** Windows, PowerShell, Julia 1.12.6, Python 3.12, `gh` authed as
`histoneguy`. Project at `C:\Users\histo\Downloads\files (27)\ipe-repo\ipe`.

**Branch protection on `main`:** requires PR, required status check **`Provenance`**,
linear history, no force push, `enforce_admins: true`. Note: the required check was
originally named "Ledger provenance" and a rename deadlocked all merges — if merges
are ever blocked by a check that never reports, that is the cause.

---

## 5. NEXT — in this order

1. **Baroreflex** (E1). Makes TPR a state instead of a constant. The most thoroughly
   characterised control loop in integrative physiology.
2. **RAAS** (E1). Renin, angiotensin II, aldosterone — the slow arm.
3. **ADH / osmoregulation** (E1). Replaces the placeholder water excretion.
4. **Re-estimate the two calibrated gains** against Mars500 as posteriors, not point
   values. `RN.PRESSURE_NATRIURESIS.SLOPE` and `CV.VENOUS_RETURN.SENSITIVITY`
   together *are* the loop gain — everything the model claims about long-run pressure
   regulation currently rests on two numbers fitted in 1972.
5. **Only then** reconnect circadian (ADR 0005).

**Do not close ADR 0003** (multirate) on current evidence — 3 states is far too small
to classify the cost regime. The diagnostic now says so itself.

---

## 6. OPEN ITEMS

- 11 of 37 parameters are `assumed` or `calibrated`. `unledgered_check()` lists them.
- Two ledger values traced only to clinical convention and needing a primary source:
  `BF.NA.PLASMA_SETPOINT`, `BF.OSM.PLASMA_SETPOINT`.
- The ECW quantile equations (*Physiol Meas* 2007, n=1538, isotope dilution + ⁴⁰K)
  would give a population **distribution** rather than the BIA-derived point
  estimates currently used. Full text not retrieved.
- TBW fraction in the ledger is 55.2%, not the textbook 60% — different method, young
  cohort. Flagged in the ledger rather than averaged away.
- Mars500 data **not yet digitised**. `validation/data/manifest.csv` has the entry.
- `validation/averaging.md` is binding before any digitisation: fixed 10 s window,
  applied uniformly, not chosen per figure.
