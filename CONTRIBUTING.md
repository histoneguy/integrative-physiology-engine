# Contributing

## Before your first commit

1. Read `SOURCES.md` in full.
2. Complete a prior-exposure declaration with the project lead. Declarations are NOT stored in this repository - see `docs/exposure-declarations-README.md`.
3. Confirm you understand that the git history of this repository is the project's
   contemporaneous provenance evidence.

## Working rules

**Do not open excluded artifacts while working on this project.** If you need to check
something you believe is only in a distribution file, the answer is either in the Tier C
papers or it is a gap we record and decide ourselves. Ask in an issue rather than looking.

**Cite in the code.** Every module carries a header block listing the sources its structure
came from. Every parameter reference resolves to a `param_id` in the ledger.

**Commit granularly and honestly.** Small commits with real messages. A history showing the
model assembled incrementally from cited sources is worth more than a tidy one. Never
force-push to `main`; never rewrite history.

**Name things yourself.** Use naming and module boundaries that follow our own decomposition.
If you notice yourself mirroring another implementation's structure element-for-element,
stop and raise it.

**Redraw, don't reproduce.** Diagrams in our docs are ours. Do not paste published figures.

## Numerical equivalence

Performance work must not silently change physiological behaviour. Any PR touching solver
configuration, integration scheme, or numerical tolerances must report:

- validation-suite results before and after, against the targets in `validation/`
- wall-clock and step-count benchmarks
- a statement of which trajectories changed and why the change is an improvement

Divergence from a fixed-step reference integrator is expected and often correct. Say so
explicitly rather than tuning it away.

## Pull requests

Use the template. PRs that add or change parameters without corresponding ledger entries
will not be merged.

## Generated patches

Changes produced outside the repo arrive as `git format-patch` series in `incoming/`
and are applied via `python sprint.py`. See `incoming/README.md`.

Authorship is preserved; the reviewer adds `Signed-off-by`. Do not re-author a
generated commit under your own name - the distinction between author and signer is
part of the provenance record.
