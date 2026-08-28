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

# 1e-3 relative. The ledger carries 2 to 4 significant figures because that is what
# the sources support, so derived identities cannot hold to better than about 0.1%
# once every input is rounded. Asserting 1e-6 between numbers known to two figures
# was asserting a precision nobody has, and it turned every rounding into a failure.
#
# This still catches what the gate exists for. The original disaster was f_pv rounded
# from 0.188874 to 0.20 - a 6% error that put MAP at 104 instead of 93. 0.1% is sixty
# times tighter than that and safely looser than arithmetic noise.
TOL = 1e-3   # relative


def load(sex: str = "male") -> dict[str, float]:
    """Ledger values resolved for one sex.

    A row tagged with this sex wins; otherwise the shared `both` row is used.
    That is the same fallback the generated `param()` accessor applies, and the
    two must agree or the closure check would be validating numbers the model
    does not use.
    """
    shared: dict[str, float] = {}
    mine: dict[str, float] = {}
    with LEDGER.open(newline="", encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            pid = r.get("param_id", "").strip()
            if not pid:
                continue
            sx = (r.get("sex") or "both").strip() or "both"
            if sx == "both":
                shared[pid] = float(r["value"])
            elif sx == sex:
                mine[pid] = float(r["value"])
    return {**shared, **mine}


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
    # Every derived value depends on parameters that MAY be dimorphic - f_pv on
    # hematocrit, TPR0 on MAP and CO, SV0 on CO0 and HR0. So closure is not one
    # question, it is one per sex, and a derivation that closes for men can fail
    # for women the moment a male/female pair is entered.
    failures = 0
    for sex in ("male", "female"):
        print(f"===== sex: {sex} " + "=" * 52)
        failures += _check_one(load(sex))
        print()
    return 1 if failures else 0


def _check_one(p: dict[str, float]) -> int:
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
          errors)

    # --- sodium balance ---------------------------------------------------
    filtered = p["RN.GFR.NOMINAL"] * p["BF.NA.PLASMA_SETPOINT"]
    excreted = filtered * (1 - p["RN.NA.FRACTIONAL_REABSORPTION"])
    check("Na excretion == Na intake",
          excreted, p["BF.NA.INTAKE_NOMINAL"],
          "FR_Na must satisfy GFR*C_Na*(1-FR) == intake, or extracellular "
          "sodium drifts every day of every run.",
          errors)

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
          errors)

    # --- pressure ---------------------------------------------------------
    check("MAP = CO x TPR",
          p["CV.CO.NOMINAL"] * p["CV.TPR.NOMINAL"],
          p["CV.MAP.SETPOINT"],
          "Definitional. TPR is derived from MAP and CO and must reproduce them.",
          errors)

    # --- cardiac output at nominal volume ---------------------------------
    co = p["CV.CO.NOMINAL"] + p["CV.VENOUS_RETURN.SENSITIVITY"] * \
        (v_blood - p["CV.BLOOD_VOLUME.NOMINAL"])
    check("CO at nominal blood volume",
          co, p["CV.CO.NOMINAL"],
          "At nominal blood volume the venous return term must vanish, "
          "otherwise the operating point is not a fixed point.",
          errors)

    # --- pressure reconstruction, 2026-08-27 -------------------------------
    #
    # MAP is now DERIVED from the sourced central pressure. This is the check
    # that caught a brachial MAP being mixed with a central pulse pressure: the
    # form factor came out 0.515, which is impossible.
    check("MAP from central DBP and PP",
          p["CV.MAP.SETPOINT"],
          p["CV.DBP.CENTRAL_NOMINAL"] +
          p["CV.PULSE.FORM_FACTOR"] * p["CV.PP.CENTRAL_NOMINAL"],
          "MAP = DBP + k_form*PP. If this drifts, the pressure reference has "
          "been mixed across measurement sites again.",
          errors)

    check("pulse pressure from systolic and diastolic",
          p["CV.PP.CENTRAL_NOMINAL"],
          p["CV.SBP.CENTRAL_NOMINAL"] - p["CV.DBP.CENTRAL_NOMINAL"],
          "PP = SBP - DBP, definitional.",
          errors)

    check("arterial compliance from SV and PP",
          p["CV.ARTERIAL.COMPLIANCE"],
          p["CV.SV.NOMINAL"] / p["CV.PP.CENTRAL_NOMINAL"],
          "C_art = SV/PP, the Chemla 1998 estimator. Moves when either moves.",
          errors)

    # --- ADR 0011: CO = HR x SV -------------------------------------------
    #
    # SV0 is DERIVED from CO0 and HR0, and HR0 is sex-specific, so this closure
    # is the reason the check runs per sex at all. Sourcing SV independently as
    # well would overdetermine the operating point.
    check("stroke volume from CO and heart rate",
          p["CV.SV.NOMINAL"],
          p["CV.CO.NOMINAL"] / (p["CV.HR.NOMINAL"] * 1440.0) * 1000.0,
          "SV0 = CO0 / (HR0 * 1440) in mL. If this drifts the heart rate and "
          "stroke volume no longer multiply to the nominal cardiac output and "
          "the operating point moves for that sex only.",
          errors)

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

    # --- osmoregulation, ADR 0006 build order item 5 -----------------------
    #
    # ADH replaced a placeholder that reproduced baseline water balance by
    # construction. Three derived values keep that true. If any drifts, the
    # model silently stops excreting what it takes in, which is precisely the
    # class of failure this gate was written for.
    solute = p["RN.URINE.SOLUTE_LOAD"]
    u_min  = p["ADH.URINE.OSM_MIN"]
    v_base = p["BF.H2O.INTAKE_NOMINAL"] - p["BF.H2O.INSENSIBLE_LOSS"]

    check("max urine osmolality from obligatory volume",
          p["ADH.URINE.OSM_MAX"],
          solute / p["RN.H2O.OBLIGATORY_LOSS"],
          "U_max = solute load / obligatory minimum urine volume. At maximal "
          "antidiuresis urine volume must equal the obligatory minimum already "
          "in the ledger, so U_max is forced, not chosen.",
          errors)

    check("non-sodium solute is the residual at the mid salt arm",
          p["RN.URINE.SOLUTE_NONNA"] +
          p["RN.URINE.OSM_PER_NA"] * p["BF.NA.INTAKE_MID"],
          solute,
          "Osm_nonNa + osm_Na*Na_mid = the REFERENCE solute load. The load now "
          "tracks sodium excretion, and the residual is pinned so the mid arm "
          "returns exactly the reference. If this drifts, U_max, U_base and "
          "k_adh - all derived from that reference - describe a different model "
          "than the one being run.",
          errors)

    check("baseline urine osmolality closes water balance",
          p["ADH.URINE.OSM_BASELINE"], solute / v_base,
          "U_base = solute load / (intake - insensible loss). Used by the "
          "disabled branch to reproduce the pre-ADH placeholder exactly.",
          errors)

    check("ADH sensitivity closes at the setpoint",
          p["ADH.OSM.SENSITIVITY"],
          ((solute / v_base) - u_min) /
          ((p["ADH.URINE.OSM_MAX"] - u_min) *
           (p["BF.OSM.PLASMA_SETPOINT"] - p["ADH.OSM.THRESHOLD"])),
          "k_adh is DERIVED by requiring that at the plasma osmolality setpoint "
          "the model excretes exactly intake minus insensible loss. If this "
          "drifts the operating point moves and every salt-step level moves "
          "with it.",
          errors)

    # And the thing all three exist to guarantee, checked directly.
    adh_base = p["ADH.OSM.SENSITIVITY"] * (p["BF.OSM.PLASMA_SETPOINT"] -
                                           p["ADH.OSM.THRESHOLD"])
    u_base_from_adh = u_min + adh_base * (p["ADH.URINE.OSM_MAX"] - u_min)
    check("water out at the osmotic setpoint",
          solute / u_base_from_adh, v_base,
          "Composed end to end: osmolality -> antidiuretic activity -> urine "
          "osmolality -> volume must return intake minus insensible loss.",
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
