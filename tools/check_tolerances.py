#!/usr/bin/env python3
"""
GATE: no comparison tolerance may be tighter than its target's significant figures.

Run it:  python tools/check_tolerances.py

WHY THIS IS A GATE AND NOT A DIRECTIVE. It was written on 2026-09-18 after the owner
said, for the fourth time, that published values are not accurate beyond their
significant digits and that chasing residuals below that wastes his time. Directives
1.9, 1.13 and 1.14 all already say it. They were all ignored. The owner's standing
instruction is to make such things STRUCTURAL - the same instruction that produced
check_relations.py's unread-rows check - so this is the version that fails a build.

WHAT IT CHECKS. A test of the form

    @test isapprox(model_value, 5.74 / 2.10; rtol = 1e-3)

asserts that the model agrees with 5.74/2.10 to one part in a thousand. But 5.74 and
2.10 are PRINTED TO THREE FIGURES, so the true ratio is only known to about +/- 0.35
percent from rounding alone, before any sampling error. A tolerance tighter than that
is not a test of the model - it is a test of digits nobody measured, and every
reassociation of the arithmetic downstream will read as a failure.

THE RULE: rtol must be >= the relative half-width implied by the target's own printed
precision. For atol, the absolute half-width.

WHAT IT DELIBERATELY DOES NOT CHECK. A DRIFT PIN - a comparison against the model's
OWN previous value, named in DRIFT_PINS below - is exempt, because directive 1.14
says that is the one place five-figure model numbers belong. A drift pin carries no
claim about physiology and its tolerance should be tight. Exemptions are named one at
a time, with the reason, exactly as ledger_to_julia.py's PRECISION_EXEMPT is.
"""

from __future__ import annotations

import math
import re
import sys
from pathlib import Path

SCANNED = ("test/runtests.jl", "validation/challenges.jl")

# A comparison against the model's own previous value. Not a measurement, so the
# precision rule does not apply - see the module docstring.
DRIFT_PINS = {
    "JENSEN_FINAL_WINDOW_RISE": "drift pin: the model's own previous FE_Na rise",
    "SALT_MAP_SHIFT": "drift pin: the model's own previous salt-step MAP shift",
    "MD_RENIN_RATIO": "drift pin: the model's own chronic renin ratio after the "
                      "tubule split retired the van den Bosch calibration",
}

# AN EXPLICIT DECLARATION, WRITTEN BY THE AUTHOR, NOT GUESSED BY THIS GATE.
#
# A tight tolerance against a ledger constant is legitimate when the model quantity
# is DERIVED FROM that constant - the test then asks "is it still wired up?", and
# the answer should be exact to solver precision. It is illegitimate when the model
# quantity is EMERGENT and the constant is a measurement, because then the tolerance
# claims digits the measurement does not have.
#
# NOTHING IN THE SOURCE DISTINGUISHES THOSE TWO AUTOMATICALLY. The first version of
# this gate tried, and flagged five comparisons of which five were legitimate - a
# 100 percent false-positive rate, and one of the five says "this assertion is a
# CLOSURE CHECK" in its own comment. So the gate does not guess: it requires the
# author to write CLOSURE PIN or WIRING PIN on the line or in the six lines above,
# and it fails anything tight that says neither.
DECLARED = re.compile(r"CLOSURE PIN|WIRING PIN")

# Tolerances that are structural rather than empirical: they assert that an
# operation is EXACTLY inert, or that two solvers agree, and have no target whose
# significant figures could bound them.
STRUCTURAL = re.compile(
    r"inert|exactly|identical|unchanged|solver|round[- ]trip|bit|neutral|"
    r"idempotent|partition|change of variables",
    re.IGNORECASE,
)


def sigfig_half_width(txt: str) -> float | None:
    """Relative half-width implied by how many figures `txt` is printed to."""
    t = txt.strip().lstrip("+-")
    if not re.fullmatch(r"[0-9]*\.?[0-9]+(?:[eE][+-]?[0-9]+)?", t):
        return None
    try:
        v = abs(float(t))
    except ValueError:
        return None
    if v == 0.0:
        return None
    mant, _, exp = t.partition("e") if "e" in t else t.partition("E")
    shift = int(exp) if exp else 0
    if "." in mant:
        decimals = len(mant.split(".")[1])
        ulp = 10.0 ** (-decimals + shift)
    else:
        # An integer literal: trailing zeros are not significant.
        stripped = mant.rstrip("0")
        zeros = len(mant) - len(stripped)
        ulp = 10.0 ** (zeros + shift)
    return (ulp / 2.0) / v


def ledger_values(root: Path) -> dict[str, str]:
    """JULIA_NAME -> the value as PRINTED in the ledger, digits and all."""
    import csv
    out: dict[str, str] = {}
    path = root / "ledger" / "parameters.csv"
    if not path.exists():
        return out
    with open(path, newline="", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            pid = (r.get("param_id") or "").strip()
            val = (r.get("value") or "").strip()
            if pid and val:
                out[pid.replace(".", "_")] = val
    return out


LEDGER_REF = re.compile(r"^(?:IPE\.)?(?:LedgerParams|L)\.([A-Z0-9_]+)$")


def target_half_width(expr: str, ledger: dict[str, str] | None = None) -> float | None:
    """Relative rounding half-width of a literal target, or a quotient/product of two.

    Relative half-widths add in quadrature for a ratio or a product, which is the
    standard propagation and the reason a ratio of two three-figure numbers is
    known to fewer figures than either.
    """
    expr = expr.strip().strip("()")
    if ledger:
        lm = LEDGER_REF.match(expr)
        if lm:
            printed = ledger.get(lm.group(1))
            return sigfig_half_width(printed) if printed else None
    m = re.fullmatch(r"\s*([0-9.eE+-]+)\s*([*/])\s*([0-9.eE+-]+)\s*", expr)
    if m:
        a, b = sigfig_half_width(m.group(1)), sigfig_half_width(m.group(3))
        if a is None or b is None:
            return None
        return math.hypot(a, b)
    return sigfig_half_width(expr)


ISAPPROX = re.compile(
    r"isapprox\(\s*(?P<lhs>[^,]+?)\s*,\s*(?P<rhs>[^;]+?)\s*;\s*"
    r"(?P<kind>rtol|atol)\s*=\s*(?P<tol>[0-9.eE+-]+)\s*\)"
)


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    ledger = ledger_values(root)
    errors: list[str] = []
    checked = 0

    for rel in SCANNED:
        path = root / rel
        if not path.exists():
            continue
        lines = path.read_text(encoding="utf-8").splitlines()
        for i, line in enumerate(lines, start=1):
            for m in ISAPPROX.finditer(line):
                lhs, rhs = m.group("lhs"), m.group("rhs")
                kind, tol = m.group("kind"), float(m.group("tol"))

                pin = next((p for p in DRIFT_PINS if p in lhs or p in rhs), None)
                if pin:
                    continue
                context = " ".join(lines[max(0, i - 6):i])
                if STRUCTURAL.search(context) or STRUCTURAL.search(line):
                    continue
                if DECLARED.search(context) or DECLARED.search(line):
                    continue

                half = target_half_width(rhs, ledger)
                if half is None:
                    continue
                checked += 1

                if kind == "rtol":
                    if tol < half:
                        errors.append(
                            f"{rel}:{i}: rtol = {tol:g} against a target printed as "
                            f"'{rhs.strip()}', whose own rounding spans +/- {half:.2%}. "
                            f"The tolerance asserts precision the target does not have. "
                            f"Loosen it to at least {half:.1e}; or, if the model quantity is "
                            f"DERIVED FROM this constant rather than emergent, declare "
                            f"it with a CLOSURE PIN or WIRING PIN comment."
                        )
                else:
                    lm = LEDGER_REF.match(rhs.strip())
                    raw = ledger.get(lm.group(1), "") if lm else rhs.strip()
                    try:
                        v = abs(float(raw))
                    except ValueError:
                        continue
                    if v > 0 and tol < half * v:
                        errors.append(
                            f"{rel}:{i}: atol = {tol:g} against a target printed as "
                            f"'{rhs.strip()}', whose own rounding spans +/- {half * v:.3g}. "
                            f"Loosen it to at least {half * v:.2g}, or name it in "
                            f"DRIFT_PINS."
                        )

    if errors:
        print("TOLERANCE GATE FAILED")
        print()
        for e in errors:
            print("  " + e)
            print()
        print("Directives 1.9, 1.13 and 1.14. A published value is not accurate beyond")
        print("its significant digits, and a tolerance tighter than that tests nothing")
        print("but arithmetic noise.")
        return 1

    print(f"Tolerance gate passed ({checked} literal-target comparisons checked, "
          f"{len(DRIFT_PINS)} drift pins exempt).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
