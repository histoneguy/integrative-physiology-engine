#!/usr/bin/env python3
"""
check_relations.py -- every structural relation must be documented.

Directive (session 3): every equation and relationship is referenced and
documented from the primary literature.

The parameter ledger enforces provenance for NUMBERS. Nothing enforced
provenance for EQUATIONS -- structure sources lived in free-text docstrings
that no tool read. This closes that gap.

Extracts every `~` relation from src/components/*.jl, matches it against
ledger/relations.csv by relation_id, and fails on:

  - a relation in the code with no ledger row        (undocumented)
  - a ledger row with no matching relation           (stale)
  - an empirical relation whose form_citation is empty

Definitional and conservation relations do NOT need a citation -- they need
to be DECLARED as definitional, which is a claim the reviewer can check.

Exit code 1 on any failure. Unlike bench/diagnostics.jl, this gates.

    python tools/check_relations.py [--repo PATH]
"""
import argparse
import csv
import re
import sys
from pathlib import Path

NEEDS_CITATION = {"empirical"}

# FORWARD-ONLY GATING.
#
# These relations were already in the code, unsourced, when this gate was
# written. Sourcing them is tracked debt (see validation/pooling.md, which
# grandfathers its own pre-existing rows the same way).
#
# The alternative was to land red. Branch protection requires a green
# Provenance job, so a gate that fails on arrival deadlocks every merge --
# which has already happened once in this repo, when the required check was
# renamed and never reported again. A gate nobody can merge past gets deleted,
# not satisfied.
#
# This list SHRINKS ONLY. The gate still fails on:
#   - any NEW unsourced empirical relation
#   - an entry here that is no longer in the code
#   - an entry here that HAS since been sourced (remove it)
#
# Do not add to this list.
GRANDFATHERED_UNSOURCED = {
    "Baroreflex.D(sp)",
    "Baroreflex.D(tpr_mod)",
    "BodyFluids.J_osm",
    "BodyFluids.J_store",
    "BodyFluids.Osm_ecf",
    "Circadian.cv_mod",
    "Circadian.renal_mod",
    "Renal.GFR",
}
VALID_CLASSES = {"definitional", "conservation", "empirical", "placeholder"}


def extract_relations(component: Path):
    """Yield (lineno, lhs, text) for each `~` relation in a component file."""
    out = []
    in_docstring = False
    for n, raw in enumerate(component.read_text().splitlines(), 1):
        if raw.count('"""') % 2 == 1:
            in_docstring = not in_docstring
            continue
        if in_docstring:
            continue
        line = raw.split("#")[0]
        if "~" not in line:
            continue
        # Multiple relations can share a line (the disabled-branch vectors).
        for m in re.finditer(r"([A-Za-z_][A-Za-z0-9_]*(?:\([A-Za-z0-9_]*\))?)\s*~", line):
            lhs = m.group(1)
            if lhs in {"ifelse", "clamp", "max", "min"}:
                continue
            out.append((n, lhs, line.strip()))
    return out



# ---------------------------------------------------------------------------
# DIRECTIVE 1.11 MADE MECHANICAL: a ledger row that nothing reads is not
# evidence about anything.
#
# This is the Circadian failure the handover names, and on 2026-09-17 a manual
# sweep found SIXTEEN rows in that state, several tier A. Directive 1.11 has been
# FOUNDATIONAL since 2026-08-27 and was checked by nothing - the same shape as
# 1.13 being written down and violated for a week. RULES THAT LIVE ONLY IN PROSE
# DO NOT HOLD HERE; gates do.
#
# The exemptions are rows that RECORD EVIDENCE rather than feed an equation.
# Each must say why. A new row that nothing reads FAILS, which is the point.
# NO EXEMPTION LIST, BY INSTRUCTION. "No more unreferenced rows. Make that a
# structural change." - the owner, 2026-09-17. A row that nothing reads cannot
# be contradicted by anything, so it is not evidence about the model; if a value
# was worth finding it is worth wiring, and if wiring it breaks something then
# the breakage is the work. A row that genuinely cannot be read by an equation
# or a gate is not a PARAMETER and does not belong in parameters.csv - its
# evidence belongs in the ADR that needs it.


def check_unread(repo, prows):
    """Ledger parameter rows that no source file reads. Directive 1.11."""
    texts = []
    # .py AS WELL AS .jl, AND OMITTING IT WAS THE SECOND FALSE-POSITIVE BUG IN
    # THIS GATE IN ONE SITTING. The closure and ledger gates are PYTHON and they
    # read rows by their dotted param_id, so a row asserted only by
    # check_closure.py looked unread. Both bugs had the same shape: the gate
    # knew about one way of reading a row and there were two.
    for pat in ("src/**/*.jl", "tools/*.jl", "bench/*.jl", "validation/*.jl",
                "test/*.jl", "tools/*.py", "validation/*.py"):
        for f in Path(repo).glob(pat):
            if f.as_posix().endswith("src/LedgerParams.jl"):
                continue
            texts.append(f.read_text(encoding="utf-8", errors="ignore"))
    unread = []
    for pid in sorted({r["param_id"] for r in prows}):
        const = pid.replace(".", "_").replace("-", "_").upper()
        rx = re.compile(r"\b" + re.escape(const) + r"\b")
        # TWO SPELLINGS, AND MISSING THE SECOND MADE THIS GATE OVER-REPORT ON
        # THE DAY IT WAS WRITTEN. Julia reads the generated constant
        # BF_TBW_MASS_FRACTION; the Python gates read the dotted param_id
        # straight out of the CSV. Checking only the first called a row unread
        # that check_closure.py had been asserting for weeks, and the "fix" was
        # nearly a duplicate check. A GATE THAT CRIES WOLF GETS IGNORED, which
        # is the failure this gate exists to prevent.
        rx_id = re.compile(re.escape(pid))
        if not any(rx.search(t) or rx_id.search(t) for t in texts):
            unread.append(pid)
    return unread


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", default=".")
    args = ap.parse_args()
    repo = Path(args.repo).resolve()

    ledger_path = repo / "ledger" / "relations.csv"
    if not ledger_path.exists():
        print(f"FAIL: {ledger_path} does not exist.")
        return 1

    rows = list(csv.DictReader(ledger_path.open()))
    by_id = {r["relation_id"]: r for r in rows}

    found, failures, debt = {}, [], []
    for comp in sorted((repo / "src" / "components").glob("*.jl")):
        for lineno, lhs, text in extract_relations(comp):
            rid = f"{comp.stem}.{lhs}"
            # A variable can be defined once per branch (enabled/disabled).
            found.setdefault(rid, []).append((comp.name, lineno, text))

    for rid, sites in sorted(found.items()):
        row = by_id.get(rid)
        where = ", ".join(f"{f}:{n}" for f, n, _ in sites)
        if row is None:
            failures.append(f"UNDOCUMENTED  {rid:<34} ({where})")
            continue
        cls = (row.get("class") or "").strip()
        if cls not in VALID_CLASSES:
            failures.append(
                f"BAD CLASS     {rid:<34} '{cls}' not in {sorted(VALID_CLASSES)}")
        elif cls in NEEDS_CITATION and not (row.get("form_citation") or "").strip():
            if rid in GRANDFATHERED_UNSOURCED:
                debt.append(rid)
            else:
                failures.append(
                    f"NO SOURCE     {rid:<34} class=empirical, form_citation empty")

    for rid in sorted(by_id):
        if rid not in found:
            failures.append(f"STALE ROW     {rid:<34} in ledger, not in code")

    # The grandfather list must not rot. An entry that has been sourced, or that
    # no longer exists in the code, is a stale exemption and fails the gate.
    for rid in sorted(GRANDFATHERED_UNSOURCED):
        if rid not in found:
            failures.append(
                f"STALE EXEMPT  {rid:<34} grandfathered but not in code")
        elif (by_id.get(rid, {}).get("form_citation") or "").strip():
            failures.append(
                f"STALE EXEMPT  {rid:<34} now sourced - remove from "
                "GRANDFATHERED_UNSOURCED")

    print(f"relations in code:   {len(found)}")
    print(f"rows in ledger:      {len(by_id)}")
    counts = {}
    for r in rows:
        counts[r.get("class", "?")] = counts.get(r.get("class", "?"), 0) + 1
    for k in sorted(counts):
        print(f"  {k:<14} {counts[k]}")
    print()

    if debt:
        print(f"grandfathered unsourced (tracked debt, not a failure): {len(debt)}")
        for rid in sorted(debt):
            print(f"  DEBT          {rid}")
        print()

    ppath = Path(args.repo) / "ledger" / "parameters.csv"
    with open(ppath, newline="", encoding="utf-8") as fh:
        prows = list(csv.DictReader(fh))
    unread = check_unread(args.repo, prows)
    ids = {r["param_id"] for r in prows}
    unread = sorted(unread)
    print(f"parameter rows:      {len(ids)}")
    for p in unread:
        failures.append(
            f"UNREAD ROW    {p:<34} nothing reads it - directive 1.11. Wire it "
            "into a component or a gate, or it is not a parameter and belongs in "
            "an ADR instead.")


    if failures:
        print(f"FAILED -- {len(failures)} problem(s):\n")
        for f in failures:
            print("  " + f)
        return 1
    print("PASS -- every relation is documented or grandfathered.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
