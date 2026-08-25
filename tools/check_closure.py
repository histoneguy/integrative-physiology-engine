#!/usr/bin/env python3
"""
Verify that DERIVED ledger values are mutually consistent at the nominal
operating point.

WHY THIS EXISTS

The first successful run of the closed loop drove intracellular water to zero,
tripled extracellular volume, and reduced sodium content to 1% of physiological -
and reported `retcode: Success` with a settling tolerance of 1.13e-6. It
converged, smoothly and confidently, to a lethal state.

Cause: three `derived` ledger values had been computed independently and rounded,
so they no longer satisfied the relationships they were derived from.

  - FR_Na rounded 0.9918651 -> 0.9915, giving 214.2 mEq/day excretion against
    205 intake: a 9.2 mEq/day drift.
  - f_pv rounded 0.188874 -> 0.20, putting blood volume 0.295 L high, which
    through the venous return gain gave MAP = 104 rather than 93.
  - Osm_ecf was defined as 2*C_Na = 280 while Osm_set was 287, so the model
    began 7 mOsm hypertonic and drove osmotic flux from t = 0.

Each was individually plausible. Together they were fatal. The parameter ledger
records where each number CAME FROM; it says nothing about whether numbers that
depend on each other still agree. This closes that gap.

RULE: any ledger row with extraction_method = derived that participates in a
closure relationship must have that relationship expressed here.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LEDGER = ROOT / "ledger" / "parameters.csv"

TOL = 1e-6   # relative


def load() -> dict[str, float]:
    with LEDGER.open(newline="", encoding="utf-8") as fh:
        return {r["param_id"]: float(r["value"])
                for r in csv.DictReader(fh) if r.get("param_id", "").strip()}


def check(name: str, lhs: float, rhs: float, explain: str,
          errors: list[str], tol: float = TOL) -> None:
    denom = max(abs(rhs), 1e-12)
    rel = abs(lhs - rhs) / denom
    status = "ok  " if rel < tol else "FAIL"
    print(f"  {status} {name:<34} {lhs:.9g} vs {rhs:.9g}  (rel {rel:.2e})")
    if rel >= tol:
        errors.append(f"{name}: {lhs:.9g} != {rhs:.9g} (rel {rel:.2e})\n"
                      f"         {explain}")


def main() -> int:
    p = load()
    errors: list[str] = []
    body_mass = 70.0   # nominal reference adult

    print("Closure checks at the nominal operating point (70 kg adult):\n")

    # --- osmolality -------------------------------------------------------
    check("plasma osmolality closes",
          2 * p["BF.NA.PLASMA_SETPOINT"] + p["BF.OSM.NONSODIUM"],
          p["BF.OSM.PLASMA_SETPOINT"],
          "Osm_ecf = 2*C_Na + Osm_other must equal the osmolality setpoint, or "
          "the model starts hypertonic and drives osmotic flux at t=0.",
          errors)

    # --- compartment volumes ----------------------------------------------
    check("ICF + ECF = TBW",
          p["BF.ICF.MASS_FRACTION"] + p["BF.ECF.MASS_FRACTION"],
          p["BF.TBW.MASS_FRACTION"],
          "Compartment fractions must sum to total body water.",
          errors, tol=1e-3)

    # --- sodium balance ---------------------------------------------------
    filtered = p["RN.GFR.NOMINAL"] * p["BF.NA.PLASMA_SETPOINT"]
    excreted = filtered * (1 - p["RN.NA.FRACTIONAL_REABSORPTION"])
    check("Na excretion == Na intake",
          excreted, p["BF.NA.INTAKE_NOMINAL"],
          "FR_Na must satisfy GFR*C_Na*(1-FR) == intake, or extracellular "
          "sodium drifts every day of every run.",
          errors, tol=1e-4)

    # --- water balance ----------------------------------------------------
    check("water in == water out",
          p["BF.H2O.INTAKE_NOMINAL"],
          p["BF.H2O.INSENSIBLE_LOSS"] +
          (p["BF.H2O.INTAKE_NOMINAL"] - p["BF.H2O.INSENSIBLE_LOSS"]),
          "Intake must equal renal output plus insensible loss.",
          errors)

    # --- blood volume -----------------------------------------------------
    v_ecf = body_mass * p["BF.ECF.MASS_FRACTION"]
    v_blood = p["CV.PLASMA.ECF_FRACTION"] * v_ecf / (1 - p["CV.HEMATOCRIT.NOMINAL"])
    check("blood volume from ECF",
          v_blood, p["CV.BLOOD_VOLUME.NOMINAL"],
          "f_pv*V_ecf/(1-Hct) must equal nominal blood volume, or cardiac "
          "output sits off its operating point and MAP is wrong from t=0.",
          errors, tol=1e-4)

    # --- pressure ---------------------------------------------------------
    check("MAP = CO x TPR",
          p["CV.CO.NOMINAL"] * p["CV.TPR.NOMINAL"],
          p["CV.MAP.SETPOINT"],
          "Definitional. TPR is derived from MAP and CO and must reproduce them.",
          errors, tol=1e-4)

    # --- cardiac output at nominal volume ---------------------------------
    co = p["CV.CO.NOMINAL"] + p["CV.VENOUS_RETURN.SENSITIVITY"] * \
        (v_blood - p["CV.BLOOD_VOLUME.NOMINAL"])
    check("CO at nominal blood volume",
          co, p["CV.CO.NOMINAL"],
          "At nominal blood volume the venous return term must vanish, "
          "otherwise the operating point is not a fixed point.",
          errors, tol=1e-4)

    # --- central/peripheral partition, ADR 0012 stage 1 --------------------
    #
    # These two are what make the partition a change of variables rather than a
    # change of behaviour. If either drifts, stage 1 stops being inert and the
    # bit-identity assertion in the test suite is the only thing left holding
    # it - which is exactly the situation that produced this gate in the first
    # place. Keep them here.
    f_c = p["CV.CENTRAL.FRACTION"]

    check("central volume from fraction",
          p["CV.CENTRAL.VOLUME_NOMINAL"],
          f_c * p["CV.BLOOD_VOLUME.NOMINAL"],
          "VC0 = f_central * BV0. If this drifts, the central operating point "
          "is not the image of the blood-volume operating point and the CO term "
          "no longer vanishes at nominal.",
          errors)

    check("central CO sensitivity closes",
          p["CV.CENTRAL.CO_SENSITIVITY"] * f_c,
          p["CV.VENOUS_RETURN.SENSITIVITY"],
          "G_vc * f_central = G_vr. This is the whole content of ADR 0012 stage "
          "1: the partition must reproduce the pre-partition slope exactly. If "
          "it fails, results have silently changed while the ledger still claims "
          "the sensitivity is Guyton's calibrated value.",
          errors)

    print()
    if errors:
        print("CLOSURE CHECK FAILED:\n", file=sys.stderr)
        for e in errors:
            print("  " + e + "\n", file=sys.stderr)
        print("These values depend on each other. Recompute the derived ones "
              "rather than adjusting them individually.", file=sys.stderr)
        return 1

    print("All closure checks passed.")
    print("\nNote: closure is necessary, not sufficient. A model can close at the")
    print("operating point and still be wrong away from it. See the physiological")
    print("range assertions in test/runtests.jl.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
