#!/usr/bin/env python3
"""
Generate src/LedgerParams.jl from ledger/parameters.csv.

The ledger is the single source of truth for every numeric constant in the model.
This tool is the only sanctioned path from ledger to code. CI runs it and fails the
build if the generated file is out of date, which makes the provenance policy in
SOURCES.md mechanically enforced rather than aspirational.

Usage:
    python3 tools/ledger_to_julia.py            # write src/LedgerParams.jl
    python3 tools/ledger_to_julia.py --check    # exit 1 if regeneration would change it
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEDGER = ROOT / "ledger" / "parameters.csv"
OUTPUT = ROOT / "src" / "LedgerParams.jl"

VALID_TIERS = {"A", "B", "C"}
VALID_METHODS = {"reported", "digitized", "derived", "assumed", "calibrated"}
ID_PATTERN = re.compile(r"^[A-Z][A-Z0-9]*(\.[A-Z][A-Z0-9_]*)+$")


class LedgerError(Exception):
    pass


def julia_symbol(param_id: str) -> str:
    """CV.BLOODVOL.TOTAL -> CV_BLOODVOL_TOTAL"""
    return param_id.replace(".", "_")


def load_rows(path: Path) -> list[dict]:
    with path.open(newline="", encoding="utf-8") as fh:
        rows = list(csv.DictReader(fh))
    return [r for r in rows if r.get("param_id", "").strip()
            and not r["param_id"].startswith("EXAMPLE.")]


def validate(rows: list[dict]) -> None:
    """Fail loudly. A silently-wrong parameter is worse than a broken build."""
    errors: list[str] = []
    seen: set[str] = set()

    for i, r in enumerate(rows, start=2):  # header is line 1
        pid = r["param_id"].strip()

        if not ID_PATTERN.match(pid):
            errors.append(f"line {i}: param_id {pid!r} must be DOTTED.UPPER_CASE")
        if pid in seen:
            errors.append(f"line {i}: duplicate param_id {pid!r}")
        seen.add(pid)

        try:
            float(r["value"])
        except (TypeError, ValueError):
            errors.append(f"line {i}: {pid} value {r.get('value')!r} is not numeric")

        if not r.get("units", "").strip():
            errors.append(f"line {i}: {pid} has no units")

        tier = r.get("source_tier", "").strip()
        if tier not in VALID_TIERS:
            errors.append(f"line {i}: {pid} source_tier {tier!r} not in {sorted(VALID_TIERS)}")

        method = r.get("extraction_method", "").strip()
        if method not in VALID_METHODS:
            errors.append(
                f"line {i}: {pid} extraction_method {method!r} not in {sorted(VALID_METHODS)}"
            )

        # Provenance rules from SOURCES.md
        if method == "assumed" and not r.get("notes", "").strip():
            errors.append(f"line {i}: {pid} is 'assumed' and requires written justification")
        if method != "assumed" and not r.get("citation", "").strip():
            errors.append(f"line {i}: {pid} has no citation")
        if method == "calibrated" and "model" not in r.get("notes", "").lower():
            errors.append(
                f"line {i}: {pid} is 'calibrated' and must name the originating model in notes"
            )
        if r.get("species", "").strip() and r["species"].strip() != "human":
            if "scal" not in r.get("notes", "").lower():
                errors.append(
                    f"line {i}: {pid} is non-human ({r['species']}) "
                    "and must state scaling in notes"
                )

    if errors:
        raise LedgerError("\n".join(errors))


def normalised_bytes(path: Path) -> bytes:
    """Content with line endings normalised to LF.

    Hashing raw bytes made the digest platform-dependent: a Windows checkout
    rewriting the file produces CRLF, git normalises back to LF on commit, and
    the recorded hash then describes a file that exists nowhere. A provenance
    tool that gives different answers on different machines is not a provenance
    tool. Normalise before hashing.
    """
    return path.read_text(encoding="utf-8").replace("\r\n", "\n").encode("utf-8")


def render(rows: list[dict]) -> str:
    digest = hashlib.sha256(normalised_bytes(LEDGER)).hexdigest()[:16]

    counts: dict[str, int] = {}
    for r in rows:
        counts[r["extraction_method"]] = counts.get(r["extraction_method"], 0) + 1
    tally = ", ".join(f"{k}={v}" for k, v in sorted(counts.items())) or "none"

    lines = [
        '"""',
        "    LedgerParams",
        "",
        "GENERATED FILE - DO NOT EDIT BY HAND.",
        "",
        "Produced by tools/ledger_to_julia.py from ledger/parameters.csv.",
        "To change a value, edit the ledger and regenerate. This is the only",
        "sanctioned path from source literature to executable code.",
        "",
        f"Ledger SHA256 (first 16): {digest}",
        f"Parameters: {len(rows)} ({tally})",
        '"""',
        "module LedgerParams",
        "",
        "export PARAM_PROVENANCE, provenance, unledgered_check",
        "",
        "# ---------------------------------------------------------------------------",
        "# Values",
        "# ---------------------------------------------------------------------------",
        "",
    ]

    by_subsystem: dict[str, list[dict]] = {}
    for r in rows:
        by_subsystem.setdefault(r.get("subsystem", "unclassified"), []).append(r)

    for subsystem in sorted(by_subsystem):
        lines.append(f"# --- {subsystem} " + "-" * max(0, 60 - len(subsystem)))
        for r in sorted(by_subsystem[subsystem], key=lambda x: x["param_id"]):
            sym = julia_symbol(r["param_id"])
            unc = ""
            if r.get("uncertainty_type", "none") not in ("", "none"):
                unc = f" +/- {r['uncertainty_value']} ({r['uncertainty_type']})"
            flag = ""
            if r["extraction_method"] in ("assumed", "calibrated"):
                flag = f"  [!] {r['extraction_method'].upper()}"
            lines.append(f'"""{r["name"]} [{r["units"]}]{unc}{flag}')
            lines.append(f'Source (tier {r["source_tier"]}, {r["extraction_method"]}): '
                         f'{r.get("citation", "-")}')
            if r.get("notes", "").strip():
                lines.append(f'Notes: {r["notes"]}')
            lines.append('"""')
            lines.append(f'const {sym} = {float(r["value"])}')
            lines.append("")
        lines.append("")

    lines += [
        "# ---------------------------------------------------------------------------",
        "# Provenance table - queryable at runtime so any result can be traced",
        "# ---------------------------------------------------------------------------",
        "",
        "struct Provenance",
        "    param_id::String",
        "    units::String",
        "    value::Float64",
        "    tier::String",
        "    method::String",
        "    citation::String",
        "    notes::String",
        "end",
        "",
        "const PARAM_PROVENANCE = Dict{Symbol,Provenance}(",
    ]
    for r in sorted(rows, key=lambda x: x["param_id"]):
        sym = julia_symbol(r["param_id"])

        def esc(s: str) -> str:
            return s.replace("\\", "\\\\").replace('"', '\\"')

        lines.append(
            f'    :{sym} => Provenance("{esc(r["param_id"])}", "{esc(r["units"])}", '
            f'{float(r["value"])}, "{r["source_tier"]}", "{r["extraction_method"]}", '
            f'"{esc(r.get("citation", ""))}", "{esc(r.get("notes", ""))}"),'
        )
    lines += [
        ")",
        "",
        '"""',
        "    provenance(sym::Symbol)",
        "",
        "Return the ledger record backing a parameter. Every number in a published",
        "result should be traceable through this.",
        '"""',
        "provenance(sym::Symbol) = PARAM_PROVENANCE[sym]",
        "",
        '"""',
        "    unledgered_check()",
        "",
        "Report parameters whose basis is weak: `assumed` (no literature basis) or",
        "`calibrated` (a fitted value published by another modeling effort, not a",
        "measurement). Review these as a set. They are where unfalsifiable choices",
        "accumulate, and they are the honest answer to \\\"how much of this is known?\\\"",
        '"""',
        "function unledgered_check()",
        "    weak = [p for p in values(PARAM_PROVENANCE) "
        "if p.method in (\"assumed\", \"calibrated\")]",
        "    sort!(weak, by = p -> p.param_id)",
        "    return weak",
        "end",
        "",
        "end # module",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="exit 1 if the generated file is stale")
    args = ap.parse_args()

    if not LEDGER.exists():
        print(f"ledger not found: {LEDGER}", file=sys.stderr)
        return 1

    rows = load_rows(LEDGER)
    try:
        validate(rows)
    except LedgerError as exc:
        print("Ledger validation failed:\n" + str(exc), file=sys.stderr)
        return 1

    rendered = render(rows)

    if args.check:
        current = (OUTPUT.read_text(encoding="utf-8").replace("\r\n", "\n")
                   if OUTPUT.exists() else "")
        if current != rendered.replace("\r\n", "\n"):
            print("src/LedgerParams.jl is stale. Run tools/ledger_to_julia.py.",
                  file=sys.stderr)
            return 1
        print(f"LedgerParams.jl up to date ({len(rows)} parameters).")
        return 0

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(rendered, encoding="utf-8", newline="\n")
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({len(rows)} parameters).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
