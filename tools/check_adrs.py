#!/usr/bin/env python3
"""
Enforce ADR 0006 on decision records.

The parameter ledger disciplines numbers. This disciplines topology, which is the
larger commitment: a wrong parameter is re-estimated, a wrong structure invalidates
the estimation that rests on it.

Run:  python3 tools/check_adrs.py
CI runs this alongside the ledger check.
"""
import re
import sys
from pathlib import Path

ADR_DIR = Path(__file__).resolve().parent.parent / "docs" / "adr"
VALID_TIERS = {"E1", "E2", "E3", "E4"}
VALID_STATUS = {"Proposed", "Accepted", "Provisional", "Deferred", "Superseded"}


def main() -> int:
    errors: list[str] = []
    checked = 0

    for f in sorted(ADR_DIR.glob("0*.md")):
        text = f.read_text(encoding="utf-8")
        checked += 1

        m = re.search(r"^\*\*Status:\*\*\s*(.+)$", text, re.M)
        if not m:
            errors.append(f"{f.name}: no **Status:** line")
        elif not any(s in m.group(1) for s in VALID_STATUS):
            errors.append(f"{f.name}: status {m.group(1).strip()!r} not one of {sorted(VALID_STATUS)}")

        tier = re.search(r"^\*\*Evidence tier:\*\*\s*(.+)$", text, re.M)
        methodological = bool(re.search(r"n/a\s*-\s*methodolog", text, re.I))

        if not tier and not methodological:
            errors.append(
                f"{f.name}: no **Evidence tier:** line. Every structural claim needs "
                "one (ADR 0006). Methodological ADRs state 'n/a - methodological'."
            )
        elif tier:
            val = tier.group(1)
            if not (set(re.findall(r"E[1-4]", val)) & VALID_TIERS or "n/a" in val):
                errors.append(f"{f.name}: evidence tier {val.strip()!r} unrecognised")

            # E3 claims must be falsifiable and must not be on by default.
            #
            # EXEMPTION: an E3 claim that informs structure without contributing
            # any state, component or numeric value has nothing to default off.
            # Claiming the exemption requires the explicit marker below, so it is
            # a deliberate act rather than an oversight.
            if "E3" in val:
                if not re.search(r"##\s*Falsifiable test", text, re.I):
                    errors.append(
                        f"{f.name}: tier E3 requires a '## Falsifiable test' section "
                        "(ADR 0006). An E3 claim with no test is not buildable."
                    )
                structure_only = bool(
                    re.search(r"STRUCTURE ONLY\s*-\s*no numeric value", text, re.I))
                defaults_off = bool(re.search(r"default\s*(=\s*)?(off|false)", text, re.I))
                if not (defaults_off or structure_only):
                    errors.append(
                        f"{f.name}: tier E3 must either default OFF and say so, or "
                        "claim the structure-only exemption with the exact phrase "
                        "'STRUCTURE ONLY - no numeric value' (ADR 0006)."
                    )
            if "E4" in val and "Accepted" in (m.group(1) if m else ""):
                errors.append(f"{f.name}: tier E4 must not be Accepted. Record and move on.")

    if errors:
        print("ADR check FAILED:\n" + "\n".join("  " + e for e in errors), file=sys.stderr)
        return 1
    print(f"ADR check OK ({checked} records).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
