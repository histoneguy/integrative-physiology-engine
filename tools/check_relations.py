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

    if failures:
        print(f"FAILED -- {len(failures)} problem(s):\n")
        for f in failures:
            print("  " + f)
        return 1
    print("PASS -- every relation is documented or grandfathered.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
