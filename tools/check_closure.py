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
import math
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
    # REWRITTEN 2026-09-02 TO MATCH THE MODEL. This computed
    # f_pv*V_ecf/(1-Hct), which is the form Cardiovascular.jl used until the red
    # cell correction. The two agree at the nominal point BY CONSTRUCTION, so this
    # gate would have kept passing while checking an expression the component no
    # longer evaluates - the same defect the U_max inversion had. A gate must
    # assert what the code does.
    v_ecf = body_mass * p["BF.ECF.MASS_FRACTION"]
    v_plasma = p["CV.PLASMA.ECF_FRACTION"] * v_ecf
    v_blood = v_plasma + p["CV.HEMATOCRIT.NOMINAL"] * p["CV.BLOOD_VOLUME.NOMINAL"]
    check("blood volume from ECF plus fixed red cells",
          v_blood, p["CV.BLOOD_VOLUME.NOMINAL"],
          "V_plasma + Hct*BV0 must equal nominal blood volume, or cardiac "
          "output sits off its operating point and MAP is wrong from t=0. This "
          "holds iff f_pv = BV0*(1-Hct)/V_ecf, which is how f_pv is derived.",
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
    # INVERTED 2026-09-01. SV0 used to be derived from CO0; it is now SOURCED
    # (Petersen 2017, CMR) and CO0 is derived from it, because stroke volume is
    # what imaging measures and cardiac output is what it computes. The identity
    # is unchanged - only which side is the primitive. HR0 and SV0 are both
    # sex-specific, so CO0 is too, and this closure is the reason the check runs
    # per sex at all. At most two of the three may ever be sourced.
    check("cardiac output from heart rate and stroke volume",
          p["CV.CO.NOMINAL"],
          p["CV.HR.NOMINAL"] * 1440.0 * p["CV.SV.NOMINAL"] / 1000.0,
          "CO0 = HR0 * SV0 * 1440 / 1000 in L/day. If this drifts the heart "
          "rate and stroke volume no longer multiply to the nominal cardiac "
          "output and the operating point moves for that sex only.",
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

    # INVERTED 2026-09-01. This check used to read U_max = solute/V_min, which
    # made maximal concentrating ability the CONSEQUENCE of an assumed obligatory
    # volume. That is backwards twice over: maximal concentration is what water
    # deprivation MEASURES, and Renal.jl has computed the floor as Osm_load/U_max
    # since the solute load became variable - so this gate was asserting the
    # opposite direction to the code it exists to check. U_max is now sourced
    # (Tryding 1988) and the obligatory volume is derived from it.
    # ADR 0017. Insensible loss stopped being one constant on 2026-09-04: it is a
    # CUTANEOUS residual plus a RESPIRATORY flux computed from ventilation. The two
    # halves must reproduce the old total at the reference individual, because every
    # ADH constant below is derived from a water balance that closes on it. If this
    # drifts, the resting state has moved and the ADH chain is silently describing a
    # different model.
    #
    # THE RESPIRATORY HALF IS COMPUTED THE WAY Respiratory.jl COMPUTES IT, from
    # V_basal and the gas water content, rather than read from a stored total. That
    # is deliberate: a check that reads the same number the code reads asserts
    # nothing. This one recomputes it and compares.
    resp_h2o = (p["RESP.VENTILATION.BASAL"] * 1440.0 *
                p["RESP.H2O.GAS_CONTENT"] / 1.0e6)
    check("insensible loss splits into respiratory and cutaneous",
          p["BF.H2O.INSENSIBLE_LOSS"],
          resp_h2o + p["BF.H2O.CUTANEOUS_LOSS"],
          "V_basal*1440*w_gas/1e6 + cutaneous residual must return the total "
          "insensible loss the water balance was closed on before respiration "
          "existed. ADR 0017 required the reference individual to be unmoved.",
          errors)

    # And the derivation that produces V_basal in the first place, checked in the
    # direction the ADR 0017 amendment settled: PaCO2 is the sourced INPUT and
    # ventilation is derived from it, not the other way round.
    check("basal ventilation from the alveolar equation",
          p["RESP.VENTILATION.BASAL"],
          p["RESP.ALVEOLAR.K"] * p["RESP.CO2.PRODUCTION"] /
          ((1.0 - p["RESP.DEADSPACE.FRACTION"]) * p["RESP.CO2.ARTERIAL_RESTING"]),
          "V_basal = K*VCO2/((1-Vd/Vt)*PaCO2_rest). The dependency inversion of "
          "the ADR 0017 amendment: resting PaCO2 is measured, basal ventilation "
          "is not, so ventilation is the derived one.",
          errors)

    # ADR 0018. Haemoglobin and haematocrit are entered from INDEPENDENT measurements
    # in the same cohort rather than derived from one another - deriving one from the
    # other would repeat the dependency error HANDOVER section 3.6 records - so their
    # ratio is a TEST that can fail. It is the mean corpuscular haemoglobin
    # concentration and the human range is roughly 32-36 g/dL of red cells.
    # _check_one already runs once per sex, so the pair is exercised by the caller.
    mchc = p["BLOOD.HB.CONCENTRATION"] / p["CV.HEMATOCRIT.NOMINAL"]
    if not (32.0 <= mchc <= 36.0):
        errors.append("MCHC outside the human 32-36 g/dL: %.2f" % mchc)
    else:
        print("  ok   mean corpuscular Hb concentration  %.2f g/dL rbc  "
              "(human 32-36)" % mchc)

    # The dissociation curve's implied P50, solved from the adopted equation rather
    # than entered as a row. Deliberately NOT a parameter, so it cannot silently
    # disagree with the curve it comes from - which makes this a test of the equation
    # rather than a second definition of the same quantity.
    lo_p, hi_p = 1.0, 100.0
    for _ in range(200):
        mid = (lo_p + hi_p) / 2.0
        s = 1.0 / (p["BLOOD.O2.CURVE_A"] / (mid ** 3 + p["BLOOD.O2.CURVE_B"] * mid) + 1.0)
        if s < 0.5:
            lo_p = mid
        else:
            hi_p = mid
    p50 = (lo_p + hi_p) / 2.0
    if not (24.0 <= p50 <= 29.0):
        errors.append("Severinghaus curve implies P50 %.2f Torr, outside human 24-29" % p50)
    else:
        print("  ok   Severinghaus curve implies P50   %.2f Torr  (human 24-29)" % p50)

    check("obligatory urine volume from maximal concentration",
          p["RN.H2O.OBLIGATORY_LOSS"],
          solute / p["ADH.URINE.OSM_MAX"],
          "V_min = solute load / U_max. At maximal antidiuresis the urine "
          "carries the whole solute load at the highest concentration the "
          "kidney can reach, so the volume is forced, not chosen.",
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

    # ADR 0018's DEFERRED FICK ARM, discharged 2026-09-05 with no new source.
    # Oxygen consumption is CO2 production over the exchange ratio, both already
    # in the ledger. Asserted here rather than only in the suite because it is a
    # property of the ROWS - if either moves, the model's oxygen consumption
    # silently moves with it, and 250 mL/min at rest is the number a reader
    # checks first.
    vo2 = p["RESP.CO2.PRODUCTION"] / p["RESP.EXCHANGE_RATIO"] * 1000.0
    if not (180.0 <= vo2 <= 320.0):
        errors.append("Resting oxygen consumption %.0f mL/min is outside 180-320; "
                      "RESP.CO2.PRODUCTION or RESP.EXCHANGE_RATIO has moved and "
                      "both are `assumed` rows" % vo2)
    else:
        print("  ok   resting oxygen consumption      %.0f mL/min  "
              "(VCO2/RER, both assumed rows)" % vo2)

    # ------------------------------------------------------------------ thyroid
    #
    # ADR 0019. THY.FT4.GAIN is the one derived number in the thyroid loop, and
    # it is derived so that the loop rests at the SOURCED free thyroxine rather
    # than wherever two independent gains happen to cross. Recomputed here, not
    # read back - the same discipline as the respiratory water split.
    tsh_ref = math.exp(p["THY.TSH.INTERCEPT"] -
                       p["THY.TSH.FT4_SLOPE"] * p["THY.FT4.EUTHYROID"])
    # THE WHOLE THYROID AXIS NOW HANGS OFF ONE DIMENSIONLESS NUMBER, and these
    # three checks are what keep the scale-dependent rows consistent with it.
    # A slope in 1/(pmol/L) and an intercept in ln(mIU/L) are both specific to a
    # free-thyroxine assay; the loop gain is not, which is why it is the sourced
    # row and they are derived from it.
    check("feedback slope is the loop gain over the operating free thyroxine",
          p["THY.TSH.FT4_SLOPE"] * p["THY.FT4.EUTHYROID"], p["THY.LOOP_GAIN"],
          "b*FT4* = G. If these drift apart the model is running a different "
          "loop gain from the one that was sourced, and the loop gain is the "
          "only thing about this axis that transfers between assays.",
          errors)

    check("intercept is the operating point plus the loop gain",
          p["THY.TSH.INTERCEPT"],
          math.log(p["THY.TSH.EUTHYROID"]) + p["THY.LOOP_GAIN"],
          "a = ln(TSH*) + G. The intercept is DERIVED from the operating point "
          "and not the other way round - the dependency inversion ADR 0017 made "
          "for arterial PCO2, made again here for the reason recorded on "
          "THY.TSH.EUTHYROID.",
          errors)

    check("thyroid loop rests at the sourced free thyroxine",
          p["THY.FT4.GAIN"] * tsh_ref, p["THY.FT4.EUTHYROID"],
          "G_T * exp(a - b*FT4_ref) = FT4_ref. If this drifts the model starts "
          "with thyroxine off its equilibrium and every run opens with a "
          "spurious ten-day transient - and the metabolic multiplier is no "
          "longer 1.0 at rest, which is what keeps the respiratory CO2 load "
          "unchanged when the arm is off.",
          errors)

    # AND THE OPERATING POINT COMES BACK, WHICH IS A CLOSURE CHECK AND NOT A
    # PREDICTION - said plainly because for one day this repository reported it as
    # a prediction that failed by 2.4x. It was not a failing prediction; it was a
    # unit error, composing a pituitary line measured on one free-thyroxine assay
    # with a concentration measured by equilibrium dialysis. NHANES measured the
    # gap: at total thyroxine agreeing to 6%, the free fractions differ 1.73-fold.
    # See validation/nhanes_hpt_extract.py section 3.
    check("thyroid operating point returns the sourced thyrotropin",
          tsh_ref, p["THY.TSH.EUTHYROID"],
          "exp(a - b*FT4*) = TSH*, which is true by construction now that a is "
          "derived from TSH*. It is here because every OTHER thyroid row feeds "
          "it, so it is the cheapest single tripwire for the whole subsystem.",
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
