#!/usr/bin/env python
"""Can the sourced venous mechanics produce G_vr? No, and not by a little.

Executes validation/venous_return_resistance_prereg.md, committed BEFORE any source was
opened and sitting immediately before this change in main's history. No commit SHA is
cited - rebase-merge rewrites it. Verify the ordering with:

    git log --diff-filter=A -- validation/venous_return_resistance_prereg.md

BRANCH R2, AND THE PRE-REGISTRATION PREDICTED IT IN WRITING.

The sourced mechanics predict G_vr = 22,000-44,000 (L/day)/L. The chronic human salt data
require 1012-1941. The model currently carries a CALIBRATED 2880. The mechanics are
11-44x above the target and 8-15x above even the incumbent.

Read the other way round, which is the way that makes it unarguable: the model's linear
CO-versus-volume relation, closed with a SOURCED compliance, implies a mean systemic
filling pressure gradient of

    46 mmHg   at the current calibrated G_vr = 2880
    68-132 mmHg at the target G_vr = 1012-1941

against a sourced normal gradient of 3 to 6 mmHg. A 132 mmHg venous gradient exceeds
arterial pressure. THE RELATION IS NOT PHYSICALLY INTERPRETABLE AS VENOUS MECHANICS AT ANY
VALUE OF G_vr, INCLUDING THE ONE IT HAS.

SO G_vr IS NOT A VENOUS-MECHANICS PARAMETER AND SOURCING VENOUS COMPLIANCE CANNOT PRODUCE
IT. It is a lumped CHRONIC sensitivity that silently absorbs the mechanism below.

THE MECHANISM IS SOURCED, NOT INFERRED. Chronic salt loading displaces the vascular
capacitance curve UPWARD AND PARALLEL - unstressed volume rises, compliance does not
change (Olson 2008, chronic dietary salt, unanaesthetised). Only the stressed fraction
drives flow, and it is about 30% of blood volume and "relatively constant under steady
state conditions" (Magder 2016). So chronic volume expansion is largely accommodated
without raising filling pressure, which is exactly the term the model has no variable for.

Every citation below was read from the retrieved PubMed record.

Run:  python validation/venous_return_resistance_extract.py
"""

SWEEP = dict(queries=11, records_screened=71,
             sweep1="resistance to venous return / venous return curve slope, 6 queries",
             sweep2="Pmsf-RAP gradient, unstressed volume, chronic volume loading, 5 queries")

# ---------------------------------------------------------------------------
# ALREADY SOURCED by validation/venous_compliance_extract.py, carried in unchanged.
# ---------------------------------------------------------------------------

C_SYS = dict(
    label="Maas 2012", pmid="22763909", species="HUMAN", n=15,
    cite="Maas JJ, Pinsky MR, Aarts LP, Jansen JR. Bedside assessment of total systemic "
         "vascular compliance, stressed volume, and cardiac function curves in intensive "
         "care unit patients. Anesth Analg 2012;115(4):880-887.",
    value_L_per_mmHg=0.0643,      # 64.3 +/- 32.7 mL/mmHg, LINEAR
    stressed_fraction=0.285,      # 28.5% +/- 15% of predicted blood volume
)

# ---------------------------------------------------------------------------
# THE GAP THIS PASS WENT AFTER: resistance to venous return.
# ---------------------------------------------------------------------------

R_VR = dict(
    label="Magder 2025", pmid="41283961", pmcid="PMC12644377", tier="B",
    cite="Magder S, Slobod D, Vieillard-Baron A. Physiological and clinical significance "
         "of mean circulatory and mean systemic filling pressure. Ann Intensive Care "
         "2025;15(1):187.",
    gradient_mmHg=(3.0, 6.0),
    note="A REVIEW, tier B, and it is used as a RANGE rather than a point - the "
         "conclusion below holds across the whole of it and across an order of magnitude "
         "beyond it, so no midpoint is taken and pooling.md's prohibition is not engaged. "
         "Its statement is a compilation: 'from our review of the studies, the pressure "
         "difference from MSFP to the right atrium (RAP) is generally in the 3 to 6 mmHg "
         "range'. R_vr = (Pmsf - RAP)/CO follows from it given a cardiac output.",
)

R_VR_REJECTED = [
    dict(label="Guerin 2015", pmid="26597901", n=30,
         cite="Guerin L, Teboul JL, Persichini R, Dres M, Richard C, Monnet X. Effects of "
              "passive leg raising and volume expansion on mean systemic pressure and "
              "venous return in shock in humans. Crit Care 2015;19:411.",
         why_not="REPORTS R_vr NUMERICALLY (5.1 +/- 2.6, unchanged by passive leg raising) "
                 "and is EXCLUDED BY THE PRE-REGISTRATION'S OWN SECTION 3: the cohort is "
                 "acute circulatory failure, and shock cohorts are excluded as primary "
                 "sources because this model's operating point is health. The units as "
                 "printed in the record read - 'mmHg/min/m2/mL' - are also ambiguous by a "
                 "factor of 1000, and directive 1.5 forbids resolving that by guessing "
                 "which reading is dimensionally sensible."),
    dict(label="Maas 2009", pmid="19237896", n=12,
         cite="Maas JJ, Geerts BF, van den Berg PC, Pinsky MR, Jansen JR. Assessment of "
              "venous return curve and mean systemic filling pressure in postoperative "
              "cardiac surgery patients. Crit Care Med 2009;37(3):912-918.",
         why_not="THE BEST-MATCHED SOURCE - same group and same inspiratory-hold method as "
                 "the adopted compliance - and it states the venous return relation is "
                 "LINEAR with a slope unaltered by volume status, which is what the "
                 "composition needs. It does not give the slope numerically in the record "
                 "read. It DOES give Pmsf 18.8 -> 29.1 mmHg for 0.5 L of colloid, i.e. "
                 "20.6 mmHg/L, which corroborates 1/C_sys = 15.55 mmHg/L from Maas 2012 "
                 "to within the method spread. Worth obtaining in full."),
    dict(label="Berger 2016", pmid="27422991", species="pig",
         cite="Berger D, Moller PW, Weber A, Bloch A, Bloechlinger S, Haenggi M, Jakob SM, "
              "Magder S, Takala J. Effect of PEEP, blood volume, and inspiratory hold "
              "maneuvers on venous return. Am J Physiol Heart Circ Physiol "
              "2016;311(3):H794-H806.",
         why_not="Reports that neither PEEP nor volume state altered RVR, which supports "
                 "treating it as a constant, but gives no number in the record read."),
]

# ---------------------------------------------------------------------------
# THE MECHANISM, AND IT IS SOURCED RATHER THAN INFERRED.
# ---------------------------------------------------------------------------

MECHANISM = [
    dict(label="Olson & Hoagland 2008", pmid="18184759", species="rainbow trout", n=None,
         cite="Olson KR, Hoagland TM. Effects of freshwater and saltwater adaptation and "
              "dietary salt on fluid compartments, blood pressure, and venous capacitance "
              "in trout. Am J Physiol Regul Integr Comp Physiol 2008;294(3):R1061-R1067.",
         finding="CHRONIC (>2 weeks) HIGH-SALT DIET DISPLACED THE VASCULAR CAPACITANCE "
                 "CURVE UPWARD AND PARALLEL to control - 'indicative of an ACTIVE INCREASE "
                 "IN UNSTRESSED BLOOD VOLUME WITHOUT ANY CHANGE IN VASCULAR COMPLIANCE'. "
                 "Unanaesthetised. Blood volume, ECF volume, arterial and venous pressure "
                 "and mean circulatory filling pressure all measured.",
         why_this_species="Directive 1.6. The design manipulates volume and salt balance "
                          "INDEPENDENTLY by freshwater / saltwater / freshwater-plus-salt "
                          "adaptation, which cannot be done in a human. The paper says it "
                          "is the first in any vertebrate to do so. Species and preparation "
                          "recorded; no ethical-ceiling tier promotion is claimed, and the "
                          "value is used for its SHAPE and DIRECTION, not as a number."),

    dict(label="Magder 2016", pmid="27613307", pmcid="PMC5018186", tier="B",
         cite="Magder S. Volume and its relationship to cardiac output and venous return. "
              "Crit Care 2016;20(1):271.",
         finding="Only the STRESSED component of blood volume determines flow; it is "
                 "'usually about 30% of total volume' and is 'RELATIVELY CONSTANT UNDER "
                 "STEADY STATE CONDITIONS'. Unstressed volume can be recruited into "
                 "stressed volume by decreasing vascular capacitance. In normal young "
                 "males cardiac output can rise FIVE-FOLD in exercise with only small "
                 "changes in stressed blood volume."),

    dict(label="carried from venous_compliance_extract.py", pmid="",
         cite="Cha 1992 (PMID 1423008), Ogilvie 1992 (PMID 1288839), "
              "Greenway & Lautt 1986 (PMID 3740285)",
         finding="Cha: blood volume rose 55 -> 67 mL/kg in pregnancy with total vascular "
                 "compliance UNCHANGED, the extra accommodated as unstressed volume. "
                 "Ogilvie: volume loading alone did not alter compliance. Greenway & "
                 "Lautt: about 60% of blood volume is haemodynamically inactive at minimal "
                 "tone, and 'a major unsolved problem is how the conversion is reflexly "
                 "controlled'. THREE INDEPENDENT LINES, ALREADY IN THE REPO, ALL SAYING "
                 "VOLUME IS ABSORBED WITHOUT COMPLIANCE CHANGING."),
]

# ---------------------------------------------------------------------------
# THE ARITHMETIC. Fixed in the pre-registration before any of this was opened.
# ---------------------------------------------------------------------------

CO0_L_MIN = 8570.88 / 1440.0          # model male nominal cardiac output
TPR0_MMHG_PER_L_DAY = 0.010151
F_PV = 0.21114                        # CV.PLASMA.ECF_FRACTION, male
G_VR_NOW = 2880.0                     # (L/day)/L, CALIBRATED
G_VR_TARGET = (1012.0, 1941.0)        # from validation/ecf_salt_response_extract.py


def main():
    print(__doc__)

    print("SEARCH")
    print("  %d queries, %d records" % (SWEEP["queries"], SWEEP["records_screened"]))
    print("     sweep 1: " + SWEEP["sweep1"])
    print("     sweep 2: " + SWEEP["sweep2"])

    inv_c = 1.0 / C_SYS["value_L_per_mmHg"]
    print("\nSOURCED INPUTS")
    print("  C_sys      %.4f L/mmHg  ->  1/C_sys = %.2f mmHg per litre  (%s, n=%d, HUMAN)"
          % (C_SYS["value_L_per_mmHg"], inv_c, C_SYS["label"], C_SYS["n"]))
    lo_g, hi_g = R_VR["gradient_mmHg"]
    r_lo, r_hi = lo_g / CO0_L_MIN, hi_g / CO0_L_MIN
    print("  Pmsf-RAP   %.0f-%.0f mmHg  ->  R_vr = %.3f-%.3f mmHg/(L/min) at CO %.2f L/min"
          % (lo_g, hi_g, r_lo, r_hi, CO0_L_MIN))
    print("             (%s, tier %s, used as a RANGE)" % (R_VR["label"], R_VR["tier"]))
    for r in R_VR_REJECTED:
        print("  rejected:  %-14s %s" % (r["label"], r["why_not"][:66] + "..."))

    print("\nTHE COMPOSITION")
    g_hi = 1.0 / (C_SYS["value_L_per_mmHg"] * r_lo) * 1440.0
    g_lo = 1.0 / (C_SYS["value_L_per_mmHg"] * r_hi) * 1440.0
    print("  G_vr = 1/(C_sys*R_vr) = %.0f to %.0f (L/day)/L" % (g_lo, g_hi))
    print("  target from the salt data       %.0f to %.0f" % G_VR_TARGET)
    print("  incumbent, CALIBRATED           %.0f" % G_VR_NOW)
    print("  mechanics / target   %.0f-%.0fx      mechanics / incumbent   %.1f-%.1fx"
          % (g_lo / G_VR_TARGET[1], g_hi / G_VR_TARGET[0],
             g_lo / G_VR_NOW, g_hi / G_VR_NOW))

    print("\nTHE SAME THING AS A PRESSURE, WHICH IS WHERE IT BECOMES UNARGUABLE")
    for lbl, g in (("incumbent 2880", G_VR_NOW),
                   ("target 1941", G_VR_TARGET[1]),
                   ("target 1012", G_VR_TARGET[0])):
        r_imp = inv_c / (g / 1440.0)
        print("  %-15s implies R_vr %6.2f mmHg/(L/min) -> Pmsf-RAP gradient %6.1f mmHg"
              % (lbl, r_imp, r_imp * CO0_L_MIN))
    print("  SOURCED normal gradient                                       %.0f-%.0f mmHg"
          % (lo_g, hi_g))
    print("  A %.0f mmHg venous gradient exceeds arterial pressure." % (
        inv_c / (G_VR_TARGET[0] / 1440.0) * CO0_L_MIN))

    print("\nWHAT THE ACUTE MECHANICS PREDICT FOR THE HUMAN SALT STEP")
    dv_ecf = 0.553                      # L per 100 mmol/day, pooled human
    dv_blood = dv_ecf * F_PV
    dpmsf = dv_blood * inv_c
    dco = dpmsf / ((r_lo + r_hi) / 2.0)
    dmap = dco * TPR0_MMHG_PER_L_DAY * 1440.0
    print("  dV_ecf %.3f L -> dV_blood %.4f L -> dPmsf %.2f mmHg -> dCO %.2f L/min"
          % (dv_ecf, dv_blood, dpmsf, dco))
    print("  -> dMAP %.1f mmHg per 100 mmol/day, against a measured HUMAN 1.04." % dmap)
    print("  THE ACUTE MECHANICS OVERPREDICT THE CHRONIC PRESSURE RESPONSE BY %.0fx."
          % (dmap / 1.042))

    print("\nMECHANISM, SOURCED")
    for m in MECHANISM:
        print("  %-32s %s" % (m["label"], m["finding"][:72] + "..."))

    print("\nVERDICT - BRANCH R2, AS PRE-REGISTERED")
    print("  G_vr STAYS `calibrated` AT 2880. No ledger value changes.")
    print("  Sourcing venous compliance cannot produce G_vr, because G_vr is not a")
    print("  venous-mechanics parameter: it is a lumped CHRONIC sensitivity that")
    print("  silently includes unstressed-volume absorption. HANDOVER section 4 item 1")
    print("  as framed CANNOT be discharged, and that is the finding.")
    print("  THE MODEL CHANGE IS NOT MADE HERE. Introducing stressed/unstressed volume")
    print("  supersedes ADR 0012's central/peripheral cut, which is a live structural")
    print("  record with its own falsifiable test. Its own ADR, and the owner's call.")

    assert g_lo > G_VR_TARGET[1] * 10.0
    assert inv_c / (G_VR_NOW / 1440.0) * CO0_L_MIN > hi_g * 5.0


if __name__ == "__main__":
    main()
