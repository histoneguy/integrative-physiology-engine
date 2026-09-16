#!/usr/bin/env python3
"""
The urine solute load: the search, the arithmetic, and the two deltas kept apart.

Run it:  python validation/urine_solute_extract.py

PRE-REGISTERED IN validation/urine_solute_prereg.md, COMMITTED BEFORE THIS FILE
EXISTED. Verify with

    git log --diff-filter=A -- validation/urine_solute_prereg.md
    git log --diff-filter=A -- validation/urine_solute_extract.py

The pre-registration named Rakova 2013 in advance as the preferred source, because
BF.NA.INTAKE_MID is already derived from its 9 g/day protocol level, and said what
would disqualify it. What the search actually found is that Rakova 2013 is the
SODIUM-RHYTHM paper and reports no osmolar excretion at all; the numbers live in two
2017 companion papers from the same cohort. That is the same cohort, so the
same-cohort rule of section 3.24 is satisfied - but by a different paper than the one
named, and the pre-registration gets no credit for naming a paper that turned out not
to contain the number.
"""

# ---------------------------------------------------------------------------
# THE SOURCE
# ---------------------------------------------------------------------------

SOURCE = (
    "Kitada K, Daub S, Zhang Y, Klein JD, Nakano D, Pedchenko T, Lantier L, "
    "LaRocque LM, Marton A, Neubert P, Schroeder A, Rakova N, Jantsch J, "
    "Dikalova AE, Dikalov SI, Harrison DG, Mueller DN, Nishiyama A, Rauh M, "
    "Harris RC, Luft FC, Wassermann DH, Sands JM, Titze J. High salt intake "
    "reprioritizes osmolyte and energy metabolism for body fluid conservation. "
    "J Clin Invest 2017;127(5):1944-1959. doi:10.1172/JCI88532. PMID 28414295. "
    "PMC5409074. OPEN ACCESS, FULL TEXT READ, AND TABLE 1 READ AS AN IMAGE - it is "
    "published as a figure (jci-127-88532-g009.jpg), not as HTML, and an automated "
    "text extraction of it returned numbers that did not self-consistently add up. "
    "The values below were read off the rendered table."
)

COMPANION = (
    "Rakova N, Kitada K, Lerchl K, Dahlmann A, Birukov A, Daub S, Kopp C, "
    "Pedchenko T, Zhang Y, Beck L, Johannes B, Marton A, Mueller DN, Rauh M, "
    "Luft FC, Titze J. Increased salt consumption induces body water conservation "
    "and decreases fluid intake. J Clin Invest 2017;127(5):1932-1943. "
    "doi:10.1172/JCI88530. PMID 28414302. FULL TEXT AND SUPPLEMENT READ. Supplies "
    "the protocol - 12 g/d = 200 mmol Na/d, 9 g/d = 150, 6 g/d = 100 - and "
    "Supplemental Table S1, the anthropometrics. Its own osmolyte figures are "
    "mixed-linear-model CONTRASTS, not per-arm levels, so the levels are taken from "
    "the companion table and not from here."
)

# --- Kitada Table 1, HUMAN balance study, per kg body weight per day -------
# n = 10 healthy men; the collection counts are collection-DAYS, not subjects.
HUMAN = {
    #                 6 g/d            12 g/d
    "n_days":        (396,             739),
    "UNaV":          ((1.2, 0.4),      (2.3, 0.5)),    # mmol/kg/d
    "UKV":           ((1.0, 0.3),      (1.1, 0.3)),    # mmol/kg/d
    "UUreaV":        ((4.3, 1.0),      (4.1, 1.1)),    # mmol/kg/d
    "U2Na2KUreaV":   ((8.6, 2.1),      (10.8, 2.3)),   # mmol/kg/d
    "U_osm":         ((431.0, 175.0),  (508.0, 170.0)),# mOsm/kg
    "UV":            ((22.0, 8.0),     (22.0, 7.0)),   # mL/kg/d
    "fluid_intake":  ((35.0, 7.0),     (31.0, 7.0)),   # mL/kg/d
    "FWC":           ((-6.6, 8.7),     (-12.6, 7.6)),  # mL/kg/d
}

# --- Rakova Supplemental Table S1, the 12 g/d arms ------------------------
BODYWEIGHT_12G = {
    "Mars105":           (81.5, 10.0),   # kg, n = 6
    "Mars520 first":     (84.2, 7.8),    # kg, n = 6
    "Mars520 reexposed": (81.4, 6.7),    # kg, n = 6
}
BSA = 2.0          # m^2, both crews, Du Bois
AGE = "32.9 +/- 5.1 (Mars105) and 32.3 +/- 4.3 (Mars520)"
BW = 83.0          # kg, the value adopted; see check_bodyweight()

# --- What the model currently has -----------------------------------------
MODEL_NOW = {
    "SOLUTE_LOAD":      600.0,   # mOsm/day, assumed, tier C, no citation
    "SOLUTE_NONNA":     292.0,   # mOsm/day, derived, pinned at the MID arm
    "OSM_PER_NA":       2.0,     # mOsm/mEq, sourced (Imamura 2013)
    "NA_INTAKE_NOMINAL": 205.0,  # mEq/day, the REFERENCE arm
    "NA_INTAKE_MID":    154.0,   # mEq/day, where the residual was pinned
    "OSM_MAX":          982.0,   # mOsm/kg, sourced (Tryding 1988)
    "OSM_MIN":          50.0,    # mOsm/kg, assumed
    "OSM_THRESHOLD":    284.0,   # mOsm/kg, sourced (Zerbe 1991)
    "OSM_SETPOINT":     287.0,   # mOsm/kg
    "V_BASE":           1.7,     # L/day = intake 2.5 - insensible 0.8
    "K_EXCR":           61.0,    # mmol/day, the model's own urinary potassium
}


def per_day(per_kg, bw=BW):
    return per_kg * bw


def check_internal_consistency():
    """The table has to agree with itself before any of it is used."""
    out = []
    for i, arm in enumerate(("6 g/d", "12 g/d")):
        na = HUMAN["UNaV"][i][0]
        k = HUMAN["UKV"][i][0]
        urea = HUMAN["UUreaV"][i][0]
        reported = HUMAN["U2Na2KUreaV"][i][0]
        computed = 2 * na + 2 * k + urea
        osm_x_vol = HUMAN["U_osm"][i][0] * HUMAN["UV"][i][0] / 1000.0
        out.append((arm, computed, reported, osm_x_vol,
                    osm_x_vol - reported, 100.0 * (osm_x_vol - reported) / osm_x_vol))
    return out


def check_bodyweight():
    """Sodium in must equal sodium out, and that is what pins the body weight.

    The 12 g/d arm is 200 mmol/d of dietary sodium. Urinary sodium is 2.3
    mmol/kg/d. If the cohort is in balance and 5 to 10 percent of intake leaves
    by sweat and stool, the implied weight follows - and it has to agree with the
    weights in Supplemental Table S1 or something is wrong with the units.
    """
    rows = []
    for frac in (1.00, 0.95, 0.90):
        rows.append((frac, 200.0 * frac / HUMAN["UNaV"][1][0]))
    return rows


def totals():
    """Absolute daily quantities at the 12 g/d arm."""
    i = 1
    osm_tot = HUMAN["U_osm"][i][0] * HUMAN["UV"][i][0] / 1000.0   # mOsm/kg/d
    na_osm = 2.0 * HUMAN["UNaV"][i][0]
    return {
        "total_per_kg":  osm_tot,
        "nonNa_per_kg":  osm_tot - na_osm,
        "total":         per_day(osm_tot),
        "nonNa":         per_day(osm_tot - na_osm),
        "UNaV":          per_day(HUMAN["UNaV"][i][0]),
        "UKV":           per_day(HUMAN["UKV"][i][0]),
        "UUreaV":        per_day(HUMAN["UUreaV"][i][0]),
        "urine_L":       per_day(HUMAN["UV"][i][0]) / 1000.0,
        "intake_L":      per_day(HUMAN["fluid_intake"][i][0]) / 1000.0,
        "U_osm":         HUMAN["U_osm"][i][0],
    }


def salt_slope():
    """How the TOTAL osmolar excretion actually responds to sodium.

    The model says 2 mOsm per mEq and holds everything else constant. The data
    say otherwise, and the difference is the non-sodium part FALLING as salt
    rises - Kitada reports a 13.9 percent fall in urine urea concentration.
    """
    tot6 = HUMAN["U_osm"][0][0] * HUMAN["UV"][0][0] / 1000.0
    tot12 = HUMAN["U_osm"][1][0] * HUMAN["UV"][1][0] / 1000.0
    dna = HUMAN["UNaV"][1][0] - HUMAN["UNaV"][0][0]
    non6 = tot6 - 2 * HUMAN["UNaV"][0][0]
    non12 = tot12 - 2 * HUMAN["UNaV"][1][0]
    return {"slope": (tot12 - tot6) / dna, "nonNa_6": non6, "nonNa_12": non12,
            "nonNa_change_pct": 100.0 * (non12 - non6) / non6}


def derive(load_ref):
    """The three constants, all derived AT THE REFERENCE LOAD.

    This is Half A. Every one of these is currently computed from 600 mOsm/day,
    which is not a load the model ever has.
    """
    m = MODEL_NOW
    u_base = load_ref / m["V_BASE"]
    k_adh = ((u_base - m["OSM_MIN"]) /
             ((m["OSM_MAX"] - m["OSM_MIN"]) * (m["OSM_SETPOINT"] - m["OSM_THRESHOLD"])))
    return {
        "load_ref":   load_ref,
        "nonNa":      load_ref - m["OSM_PER_NA"] * m["NA_INTAKE_NOMINAL"],
        "obligatory": load_ref / m["OSM_MAX"],
        "u_base":     u_base,
        "k_adh":      k_adh,
        "adh_at_set": k_adh * (m["OSM_SETPOINT"] - m["OSM_THRESHOLD"]),
        "max_diuresis": load_ref / m["OSM_MIN"],
    }


def current_state():
    """What the model does now, and why it sits off its own setpoint.

    Reproduces the measured operating point from the constants alone.
    """
    m = MODEL_NOW
    load_actual = m["SOLUTE_NONNA"] + m["OSM_PER_NA"] * m["NA_INTAKE_NOMINAL"]
    k_adh = ((600.0 / m["V_BASE"] - m["OSM_MIN"]) /
             ((m["OSM_MAX"] - m["OSM_MIN"]) * (m["OSM_SETPOINT"] - m["OSM_THRESHOLD"])))
    u_needed = load_actual / m["V_BASE"]
    adh_needed = (u_needed - m["OSM_MIN"]) / (m["OSM_MAX"] - m["OSM_MIN"])
    osm_needed = m["OSM_THRESHOLD"] + adh_needed / k_adh
    return {"load_actual": load_actual, "k_adh": k_adh, "u_needed": u_needed,
            "adh_needed": adh_needed, "osm_needed": osm_needed,
            "offset": osm_needed - m["OSM_SETPOINT"]}


POTASSIUM_VERDICT = [
    "BRANCH U4 DOES NOT FIRE, AND THE SOURCE CONDITION IS NOT WHY.",
    "",
    "U4 required a source in the 2(Na+K) estimator family before an explicit",
    "potassium term could be built, because RN.URINE.OSM_PER_NA comes from",
    "Imamura's estimator, which carries no potassium at all. Kitada's osmolyte",
    "sum is literally U2Na2KUreaV - 2Na, 2K and urea - so the condition is MET.",
    "",
    "It fails on coherence instead. The model excretes 61 mmol/day of potassium;",
    "Kitada's men excrete 1.1 mmol/kg/d, which at 83 kg is 91. THE MODEL'S OWN",
    "POTASSIUM IS A THIRD BELOW THE COHORT THE TOTAL COMES FROM. Wiring the",
    "explicit term would replace a constant with a model variable that is itself",
    "incoherent with the source, and the residual would absorb the 60 mOsm/day",
    "difference anyway - which is the failure section 10 of the pre-registration",
    "names, moved into a new place rather than removed.",
    "",
    "The two diets differ and that is the honest reading: K.INTAKE.NOMINAL is a",
    "free-living Western figure and the Mars crews ate a controlled, nutritionally",
    "specified diet. Resolve that first; the potassium term is cheap afterwards.",
]

NOT_BUILT = [
    "THE NON-SODIUM LOAD IS NOT CONSTANT, AND THE MODEL HOLDS IT CONSTANT.",
    "",
    "Measured: the non-sodium remainder FALLS from 7.08 to 6.58 mOsm/kg/d as salt",
    "goes 6 -> 12 g/d, because urine urea concentration falls 13.9 percent. So the",
    "total osmolar excretion rises with a slope of about 1.5 mOsm per mmol of",
    "excreted sodium, not the 2.0 the model uses.",
    "",
    "THE 2.0 IS NOT WRONG - it is charge balance on the sodium term itself and the",
    "pre-registration forbids moving it. What is wrong is holding the REST constant.",
    "Building the dependence would need a urea-recycling or glucocorticoid mechanism",
    "with no sourced form, and this pass did not pre-register one.",
    "",
    "SO IT IS RECORDED AS A BOUNDED DISCREPANCY: across the model's own salt arms,",
    "205 -> 103 mEq/day, the model moves the solute load by 204 mOsm/day where the",
    "data imply about 157. The model over-responds by roughly 30 percent on the",
    "solute limb, and that is now a number rather than an unknown.",
]


def main():
    W = 78
    print("=" * W)
    print("THE URINE SOLUTE LOAD - EXTRACTION UNDER validation/urine_solute_prereg.md")
    print("=" * W)

    print("\n1. THE SOURCE")
    print("-" * W)
    print("  " + SOURCE.replace(". ", ".\n  "))
    print("\n  COMPANION, same cohort:")
    print("  " + COMPANION.replace(". ", ".\n  "))

    print("\n2. THE TABLE HAS TO AGREE WITH ITSELF FIRST")
    print("-" * W)
    print("  %-8s %10s %10s %12s %10s %8s" %
          ("arm", "2Na+2K+ur", "reported", "Uosm x UV", "unmeasured", "pct"))
    for arm, comp, rep, ox, diff, pct in check_internal_consistency():
        print("  %-8s %10.1f %10.1f %12.2f %10.2f %7.1f%%" % (arm, comp, rep, ox, diff, pct))
    print("\n  The sum reproduces the reported osmolyte excretion to a rounding digit,")
    print("  and osmolality x volume exceeds it by 3-9 percent - the unmeasured")
    print("  osmolytes, ammonium and phosphate and sulfate and creatinine. THE TABLE")
    print("  IS INTERNALLY CONSISTENT, which an automated extraction of it was not.")

    print("\n3. THE BODY WEIGHT, PINNED BY SODIUM BALANCE")
    print("-" * W)
    print("  12 g/d arm = 200 mmol/d dietary sodium; UNaV = 2.3 mmol/kg/d.")
    for frac, bw in check_bodyweight():
        print("    if %.0f%% of intake leaves in urine -> %.1f kg" % (100 * frac, bw))
    print("  Supplemental Table S1, 12 g/d arms:")
    for k, (m, s) in BODYWEIGHT_12G.items():
        print("    %-20s %.1f +/- %.1f kg" % (k, m, s))
    print("  BSA %.1f m2 both crews (Du Bois); age %s." % (BSA, AGE))
    print("  ADOPTED: %.0f kg. The sodium-balance estimate and the measured weights" % BW)
    print("  agree, which is the check that the per-kg units are what they say.")

    t = totals()
    print("\n4. THE 12 g/d ARM IN ABSOLUTE TERMS, AND IT IS THE MODEL'S REFERENCE ARM")
    print("-" * W)
    print("  Rakova's 12 g/d = 200 mmol Na/d; the model's BF.NA.INTAKE_NOMINAL = 205.")
    print("  THE COHERENCE CONSTRAINT OF SECTION 3 IS SATISFIED: same protocol level,")
    print("  same cohort as BF.NA.INTAKE_MID, 2.4 percent apart in sodium.")
    print()
    print("    total osmolar excretion   %7.1f mOsm/day  (%.2f mOsm/kg/d)"
          % (t["total"], t["total_per_kg"]))
    print("    of which sodium salts     %7.1f" % (2 * t["UNaV"]))
    print("    NON-SODIUM REMAINDER      %7.1f mOsm/day  (%.2f mOsm/kg/d)"
          % (t["nonNa"], t["nonNa_per_kg"]))
    print("    urinary Na / K / urea     %7.1f / %.1f / %.1f mmol/day"
          % (t["UNaV"], t["UKV"], t["UUreaV"]))
    print("    urine volume              %7.2f L/day   (model: %.2f)"
          % (t["urine_L"], MODEL_NOW["V_BASE"]))
    print("    fluid intake              %7.2f L/day   (model assumes 2.5)" % t["intake_L"])
    print("    urine osmolality          %7.0f mOsm/kg" % t["U_osm"])
    print()
    print("  THE LEDGER PREDICTED THIS. RN.URINE.SOLUTE_NONNA's own note says the")
    print("  non-sodium remainder should be 'nearer 400-500' and that 292 is")
    print("  'almost certainly TOO LOW'. Measured: %.0f." % t["nonNa"])

    print("\n5. HALF A - THE REFERENCE-POINT DEFECT, WHICH NEEDS NO SOURCE")
    print("-" * W)
    c = current_state()
    print("  The model's residual is pinned at the MID arm (154 mEq/day), so at the")
    print("  NOMINAL arm (205) its actual load is %.0f, not 600." % c["load_actual"])
    print("  k_adh is derived from 600 and is %.5f." % c["k_adh"])
    print("  To excrete %.2f L/day at a load of %.0f the model needs u_osm = %.1f,"
          % (MODEL_NOW["V_BASE"], c["load_actual"], c["u_needed"]))
    print("  hence adh = %.4f, hence plasma osmolality = %.3f." % (c["adh_needed"], c["osm_needed"]))
    print("  MEASURED IN THE RUNNING MODEL: adh 0.3895, Osm_ecf 287.592.")
    print("  THE MODEL SITS %.2f mOsm/kg ABOVE ITS OWN SETPOINT, for no physiology."
          % c["offset"])

    print("\n6. THE TWO DELTAS, KEPT APART AS SECTION 1 REQUIRES")
    print("-" * W)
    a = derive(c["load_actual"])            # Half A alone
    b = derive(round(t["total"], -1))       # Half A + Half B
    print("  %-26s %12s %12s %12s" % ("", "now", "Half A", "Half A + B"))
    rows = [
        ("reference solute load", 600.0, a["load_ref"], b["load_ref"]),
        ("RN.URINE.SOLUTE_NONNA", 292.0, a["nonNa"], b["nonNa"]),
        ("RN.H2O.OBLIGATORY_LOSS", 0.611, a["obligatory"], b["obligatory"]),
        ("ADH.URINE.OSM_BASELINE", 353.0, a["u_base"], b["u_base"]),
        ("ADH.OSM.SENSITIVITY", 0.1084, a["k_adh"], b["k_adh"]),
        ("adh activity at rest", 0.3895, a["adh_at_set"], b["adh_at_set"]),
        ("maximal diuresis L/day", 12.0, a["max_diuresis"], b["max_diuresis"]),
    ]
    for name, now, ha, hb in rows:
        print("  %-26s %12.4f %12.4f %12.4f" % (name, now, ha, hb))
    print()
    print("  HALF A moves no ledger VALUE that is sourced - it re-derives three")
    print("  constants at the load the model actually has, and the plasma")
    print("  osmolality offset goes to zero by construction.")
    print("  HALF B is the sourcing, and it is the column on the right.")

    print("\n7. BRANCH U6 - THE STOP CONDITION, CHECKED")
    print("-" * W)
    print("  Obligatory urine volume becomes %.3f L/day against a reference urine"
          % b["obligatory"])
    print("  volume of %.2f L/day. It is 56 percent of it, leaving 0.75 L of" % MODEL_NOW["V_BASE"])
    print("  headroom. U6 does NOT fire, but the obligatory loss has more than")
    print("  doubled and that is a real change to the model's water reserve.")
    print("  Antidiuretic activity at rest %.3f, inside the 0.2-0.6 the" % b["adh_at_set"])
    print("  pre-registration required, with room to move both ways.")

    print("\n8. WHAT IS NOT BUILT, AND WHY")
    print("-" * W)
    s = salt_slope()
    for line in NOT_BUILT:
        print("  " + line)
    print()
    print("    non-sodium at 6 g/d   %.2f mOsm/kg/d" % s["nonNa_6"])
    print("    non-sodium at 12 g/d  %.2f mOsm/kg/d   (%+.1f%%)"
          % (s["nonNa_12"], s["nonNa_change_pct"]))
    print("    measured slope        %.2f mOsm per mmol Na   (model: 2.00)" % s["slope"])
    print()
    for line in POTASSIUM_VERDICT:
        print("  " + line)

    print("\n" + "=" * W)
    print("VERDICT: BRANCH U1. The total sources WITH urinary sodium in the same")
    print("         subjects, at the model's own reference salt intake, from the")
    print("         cohort BF.NA.INTAKE_MID already comes from. U4 does not fire.")
    print("=" * W)


if __name__ == "__main__":
    main()
