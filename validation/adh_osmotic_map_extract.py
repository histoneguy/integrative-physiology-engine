#!/usr/bin/env python3
"""
The plasma-to-urine osmolality map, from Baylis 1986.

Run it:  python validation/adh_osmotic_map_extract.py

PRE-REGISTERED IN validation/adh_osmotic_map_prereg.md, COMMITTED BEFORE THIS FILE
EXISTED.

    git log --diff-filter=A -- validation/adh_osmotic_map_prereg.md
    git log --diff-filter=A -- validation/adh_osmotic_map_extract.py

WHAT THIS DISCHARGES. ADH.OSM.SENSITIVITY's own note said "no sourced map from plasma
vasopressin to urine osmolality was found". Baylis is that map.

WHAT IT DOES NOT CLAIM. Section 3 shows the SLOPE alone is not resolved by Baylis's
interval - the old value is inside it. The result is section 4's category error.
"""

from __future__ import annotations

import csv
import sys
from pathlib import Path

W = 78

# ---------------------------------------------------------------------------
# READ FROM THE PAPER. Baylis PH, Pippard C, Gill GV, Burd J. Development of a
# cytochemical assay for plasma vasopressin: application to studies on water
# loading normal man. Clin Endocrinol (Oxf) 1986;24(4):383-393. PMID 3017608.
# Eight healthy male adults, sustained water load, PAIRED plasma and urine.
N = 8
P_BASAL, P_BASAL_SE = 286.5, 2.0        # mmol/kg
P_LOAD, P_LOAD_SE = 279.2, 2.4          # mmol/kg
U_BASAL, U_BASAL_SE = 867.0, 54.0       # mmol/kg
U_LOAD, U_LOAD_SE = 69.0, 3.0           # mmol/kg
P_VALUE = "< 0.001"                     # for the fall in plasma osmolality

# t(df = 7) for p = 0.001 two-sided. Used ONLY to BOUND the SE, since the paper
# prints an inequality and not a dispersion for the paired difference.
T_CRIT_0001_DF7 = 5.408
T_CRIT_005_DF7 = 2.365


def ledger() -> dict[str, str]:
    path = Path(__file__).resolve().parents[1] / "ledger" / "parameters.csv"
    with open(path, newline="", encoding="utf-8") as f:
        return {r["param_id"]: r["value"] for r in csv.DictReader(f)}


def main() -> int:
    p = ledger()
    u_min = float(p["ADH.URINE.OSM_MIN"])
    u_max = float(p["ADH.URINE.OSM_MAX"])
    u_base = float(p["ADH.URINE.OSM_BASELINE"])
    osm_set = float(p["BF.OSM.PLASMA_SETPOINT"])
    k_now = float(p["ADH.OSM.SENSITIVITY"])
    thr_now = float(p["ADH.OSM.THRESHOLD"])
    span = u_max - u_min

    print("=" * W)
    print("THE PLASMA-TO-URINE OSMOLALITY MAP - Baylis 1986, PMID 3017608")
    print("=" * W)
    print("  n = %d healthy male adults, sustained water load, PAIRED." % N)
    print("    plasma  %5.1f +/- %.1f  ->  %5.1f +/- %.1f mmol/kg   p %s"
          % (P_BASAL, P_BASAL_SE, P_LOAD, P_LOAD_SE, P_VALUE))
    print("    urine   %5.0f +/- %2.0f    ->  %5.0f +/- %.0f   mmol/kg"
          % (U_BASAL, U_BASAL_SE, U_LOAD, U_LOAD_SE))

    print("\n1. MAPPED ONTO THIS MODEL'S NORMALISED 0-1 ACTIVITY")
    print("-" * W)
    print("  u_osm = U_min + adh * (U_max - U_min), with U_min = %.0f (ASSUMED, tier C)"
          % u_min)
    print("  and U_max = %.0f (Tryding 1988, tier A). Both UNTOUCHED by this pass." % u_max)
    a_basal = (U_BASAL - u_min) / span
    a_load = (U_LOAD - u_min) / span
    d_p = P_BASAL - P_LOAD
    k_baylis = (a_basal - a_load) / d_p
    print()
    print("    adh at basal  (%5.0f - %2.0f) / %.0f = %.4f" % (U_BASAL, u_min, span, a_basal))
    print("    adh at load   (%5.0f - %2.0f) / %.0f = %.4f" % (U_LOAD, u_min, span, a_load))
    print("    d(adh) = %.4f over d(plasma) = %.1f mmol/kg" % (a_basal - a_load, d_p))
    print("    k = %.4f per mmol/kg" % k_baylis)
    print()
    print("  TWO SIGNIFICANT FIGURES, DIRECTIVE 1.13. The numerator is a difference of")
    print("  three-figure urine values; the denominator a difference of four-figure")
    print("  plasma values, which carries two. -> k = %.2f" % round(k_baylis, 2))

    print("\n2. THE RAW SLOPE, FOR ORIENTATION")
    print("-" * W)
    print("  %.0f mmol/kg of urine per mmol/kg of plasma." % ((U_BASAL - U_LOAD) / d_p))
    print("  The model before this pass: %.0f. A factor of %.2f."
          % (0.17777 * span, 0.17777 / k_baylis))

    print("\n3. AND THE SLOPE ALONE DOES NOT RESOLVE IT - DIRECTIVE 1.14 FIRST")
    print("-" * W)
    print("  The paper prints an INEQUALITY for the paired fall, not a dispersion.")
    print("  p %s at df = %d bounds t > %.3f, so SE < %.1f / %.3f = %.3f mmol/kg."
          % (P_VALUE, N - 1, T_CRIT_0001_DF7, d_p, T_CRIT_0001_DF7,
             d_p / T_CRIT_0001_DF7))
    half = T_CRIT_005_DF7 * (d_p / T_CRIT_0001_DF7)
    lo_p, hi_p = d_p - half, d_p + half
    lo_k, hi_k = (a_basal - a_load) / hi_p, (a_basal - a_load) / lo_p
    print("  Worst-case 95%% interval on the fall: %.1f to %.1f mmol/kg." % (lo_p, hi_p))
    print("  So k lies in %.3f to %.3f." % (lo_k, hi_k))
    print()
    old = 0.17777
    print("  THE OLD VALUE %.5f IS %s THAT INTERVAL."
          % (old, "INSIDE" if lo_k <= old <= hi_k else "OUTSIDE"))
    print("  BAYLIS THEREFORE DOES NOT REFUTE THE OLD SLOPE. A pass resting on the")
    print("  slope would be chasing noise, which is what directive 1.14 forbids.")
    print("  Pre-registration section 0.1 said this BEFORE the numbers were entered.")

    print("\n4. THE RESULT: A NAME CARRYING A CONVENTION ITS VALUE CONTRADICTS")
    print("-" * W)
    print("  ADH.OSM.THRESHOLD was tier A, extraction_method=reported, named")
    print("  'Osmotic threshold for vasopressin RELEASE', from Zerbe 1991.")
    print("  THE MODEL USES IT AS THE OSMOLALITY WHERE URINE REACHES ITS FLOOR.")
    print()
    print("  Those cannot coincide: minimal urine needs release fully suppressed,")
    print("  which is BELOW where release starts. Baylis measures the second one -")
    print("  at plasma %.1f his subjects' urine was %.0f against a floor of %.0f."
          % (P_LOAD, U_LOAD, u_min))
    print()
    thr_baylis = P_BASAL - a_basal / k_baylis
    print("  Baylis's two points fix BOTH: k = %.4f and threshold = %.1f mmol/kg."
          % (k_baylis, thr_baylis))
    print("  (Two points, two parameters - they reproduce his data BY CONSTRUCTION")
    print("   and that agreement is not evidence of anything.)")

    print("\n5. WHY BAYLIS SETS THE SHAPE AND NOT THE POSITION")
    print("-" * W)
    k2 = round(k_baylis, 2)
    for lbl, kk, tt in (("Baylis slope AND Baylis threshold", k2, thr_baylis),
                        ("Baylis slope with Zerbe's 284", k2, 284.0),
                        ("Baylis slope, threshold DERIVED", k2,
                         osm_set - (u_base - u_min) / (span * k2))):
        a = min(1.0, max(0.0, kk * (osm_set - tt)))
        u = u_min + a * span
        print("    %-34s thr %6.2f -> u_osm %5.0f, urine %.2f L/day"
              % (lbl, tt, u, (u_base * 1.7) / u))
    print()
    print("  Baylis's basal is a SPOT MORNING SAMPLE; this model's %.2f is a 24 h MEAN."
          % u_base)
    print("  Different estimands. The like-for-like 24 h comparator is Kitada's")
    print("  measured 508 +/- 170 mmol/kg in this model's own salt arm, and %.0f is"
          % u_base)
    print("  inside it. U_min was NOT moved to absorb the difference: it would have")
    print("  had to become %.0f, which is not a minimum urine osmolality."
          % ((u_base - k2 * (osm_set - 284.0) * u_max) / (1 - k2 * (osm_set - 284.0))))

    print("\n6. WHAT WAS ENTERED, READ BACK FROM THE LEDGER")
    print("-" * W)
    print("    ADH.OSM.SENSITIVITY  %8.5f   sourced, Baylis 1986" % k_now)
    print("    ADH.OSM.THRESHOLD    %8.2f   DERIVED, and Zerbe's measured individual"
          % thr_now)
    print("                                   range 280-288 CONTAINS it: %s"
          % ("yes" if 280.0 <= thr_now <= 288.0 else "NO - branch W3"))
    a = k_now * (osm_set - thr_now)
    print("    operating point      adh %.4f -> u_osm %.2f (target %.2f)"
          % (a, u_min + a * span, u_base))
    return 0


if __name__ == "__main__":
    sys.exit(main())
