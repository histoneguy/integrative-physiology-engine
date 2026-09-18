#!/usr/bin/env python3
"""
Test zero: is van den Bosch's 2 mmHg a measurement or is it noise?

Run it:  python validation/chronic_comparator_extract.py

PRE-REGISTERED IN validation/chronic_comparator_prereg.md, COMMITTED BEFORE THIS FILE
EXISTED.

    git log --diff-filter=A -- validation/chronic_comparator_prereg.md
    git log --diff-filter=A -- validation/chronic_comparator_extract.py

THE SOURCE NUMBERS ARE NOT COPIED. The diet and pressure values are imported from
ecf_salt_response_extract.py, which owns them. What is added here is the DISPERSION,
which that file never carried.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ecf_salt_response_extract import TEST_B  # noqa: E402

W = 78

# ---------------------------------------------------------------------------
# READ FROM THE PAPER FOR THIS PASS. van den Bosch JJON, Hessels NR, Visser FW,
# Krikken JA, Bakker SJL, Riphagen IJ, Navis GJ. Physiol Rep 2021;9(24):e15103.
# PMID 34921521, PMC8683787, open access. Table 1 and Methods.
N = 70
MAP_SD = 7.0            # mmHg, PER ARM - and see section 2 for why it is useless
P_MAP = 0.02            # reported for the MAP difference
SBP = (123.0, 120.0, 10.0, 0.007)
DBP = (70.0, 69.0, 7.0, 0.09)
# Methods: automated oscillometric (Dinamap), every 3 min for 15 min, 11 a.m.,
# fasted, after a 2 h stabilisation. 70 healthy NORMOTENSIVE men, age 24 +/- 7.
# ONE WEEK per dietary period, randomised order, washout at least 3 weeks.
# Crossover, analysed with linear mixed effects models for repeated measurements.

# The three meta-analytic point estimates the model is judged against.
META = (("Cutler 1997", 1.70), ("He 2013", 1.96), ("He 2002", 2.30))
MODEL_NOW = 1.97        # chronic salt sensitivity as merged
MODEL_ACUTE = 1.01      # the value that satisfies all three acute endpoints, HANDOVER 3.52


def t_crit(p_two_sided, df):
    """Two-sided critical t by bisection on the normal-approx-corrected CDF."""
    # Student t CDF via incomplete beta, good enough for df = 69.
    def cdf(t):
        x = df / (df + t * t)
        return 1.0 - 0.5 * betainc(df / 2.0, 0.5, x) if t > 0 else \
            0.5 * betainc(df / 2.0, 0.5, x)

    def betainc(a, b, x):
        # continued fraction, Lentz
        if x <= 0.0:
            return 0.0
        if x >= 1.0:
            return 1.0
        lbeta = (math.lgamma(a) + math.lgamma(b) - math.lgamma(a + b))
        front = math.exp(math.log(x) * a + math.log(1 - x) * b - lbeta) / a
        f, c, d = 1.0, 1.0, 0.0
        for i in range(0, 300):
            m = i // 2
            if i == 0:
                num = 1.0
            elif i % 2 == 0:
                num = (m * (b - m) * x) / ((a + 2 * m - 1) * (a + 2 * m))
            else:
                num = -((a + m) * (a + b + m) * x) / ((a + 2 * m) * (a + 2 * m + 1))
            d = 1.0 + num * d
            d = 1e-30 if abs(d) < 1e-30 else d
            d = 1.0 / d
            c = 1.0 + num / c
            c = 1e-30 if abs(c) < 1e-30 else c
            f *= c * d
            if abs(1.0 - c * d) < 1e-12:
                break
        return front * (f - 1.0)

    lo, hi = 0.0, 20.0
    for _ in range(200):
        mid = (lo + hi) / 2.0
        if 2.0 * (1.0 - cdf(mid)) > p_two_sided:
            lo = mid
        else:
            hi = mid
    return (lo + hi) / 2.0


def main() -> int:
    b = TEST_B
    d_na = b["na_high"] - b["na_low"]
    d_map = b["map_high"] - b["map_low"]
    point = d_map / d_na * 100.0
    df = N - 1

    print("=" * W)
    print("TEST ZERO - validation/chronic_comparator_prereg.md section 2")
    print("=" * W)
    print("  Is van den Bosch's 2 mmHg a measurement, or is it noise?")
    print("  If it is noise it cannot be a comparator and the pass ends here.")

    print("\n1. WHAT THE PAPER REPORTS")
    print("-" * W)
    print("  van den Bosch JJON et al. Physiol Rep 2021;9(24):e15103.")
    print("  PMID 34921521, PMC8683787, open access. Table 1 and Methods, READ.")
    print("  n = %d healthy NORMOTENSIVE men, age 24 +/- 7." % N)
    print("  Automated oscillometric (Dinamap), every 3 min for 15 min, 11 a.m.,")
    print("  fasted, after a 2 h stabilisation. ONE WEEK per dietary period,")
    print("  randomised order, washout >= 3 weeks. Crossover, analysed with linear")
    print("  mixed effects models for repeated measurements.")
    print()
    print("    MAP   %5.1f vs %5.1f  +/- %.0f   p = %.2f   SIGNIFICANT"
          % (b["map_high"], b["map_low"], MAP_SD, P_MAP))
    print("    SBP   %5.1f vs %5.1f  +/- %.0f   p = %.3f  significant"
          % (SBP[0], SBP[1], SBP[2], SBP[3]))
    print("    DBP   %5.1f vs %5.1f  +/- %.0f   p = %.2f   NOT significant"
          % (DBP[0], DBP[1], DBP[2], DBP[3]))
    print("    UNaV  %5.0f vs %5.0f mmol/24 h" % (b["na_high"], b["na_low"]))

    print("\n2. TEST ZERO PASSES, AND THE PER-ARM SDs ARE USELESS FOR SAYING SO")
    print("-" * W)
    naive_se = MAP_SD * math.sqrt(2.0 / N)
    print("  Treating the arms as INDEPENDENT gives SE = %.2f x sqrt(2/%d) = %.3f mmHg,"
          % (MAP_SD, N, naive_se))
    print("  so t = %.2f / %.3f = %.2f - which would NOT be significant."
          % (d_map, naive_se, d_map / naive_se))
    print("  The paper reports p = %.2f. THE PAIRING IS WHAT MAKES IT SIGNIFICANT," % P_MAP)
    print("  and the paired SD is not printed. SAME OBSTACLE THE REPOSITORY ALREADY")
    print("  RECORDED FOR JENSEN'S RATIO: the dispersion of a within-subject")
    print("  difference needs the correlation, and the correlation is not published.")
    print()
    print("  SO THE INTERVAL BELOW IS BACK-DERIVED FROM THE p-VALUE, NOT MEASURED.")

    print("\n3. THE INTERVAL, BACK-DERIVED AND THEREFORE INDICATIVE")
    print("-" * W)
    print("  %-22s %10s %10s %10s" % ("assumed p", "SE mmHg", "lo", "hi"))
    for p in (0.015, 0.02, 0.024):
        se = d_map / t_crit(p, df)
        half = t_crit(0.05, df) * se
        print("  %-22s %10.3f %10.3f %10.3f"
              % ("p = %.3f" % p, se, (d_map - half) / d_na * 100.0,
                 (d_map + half) / d_na * 100.0))
    se = d_map / t_crit(P_MAP, df)
    half = t_crit(0.05, df) * se
    lo, hi = (d_map - half) / d_na * 100.0, (d_map + half) / d_na * 100.0
    print()
    print("  POINT ESTIMATE %.3f mmHg per 100 mmol/day, 95%% CI about %.2f to %.2f."
          % (point, lo, hi))
    print("  The upper bound is %.2f-%.2f across the plausible rounding of p, so it is"
          % (1.87, 1.94))
    print("  robust to that even though the derivation is not exact.")

    print("\n4. WHAT IT DOES AND DOES NOT EXCLUDE")
    print("-" * W)
    print("  %-34s %8s   %s" % ("", "value", "inside van den Bosch's CI?"))
    rows = [("Cutler 1997 meta-analysis", META[0][1]),
            ("He 2013 meta-analysis", META[1][1]),
            ("He 2002 meta-analysis", META[2][1]),
            ("model, as merged", MODEL_NOW),
            ("model at the acute-satisfying gain", MODEL_ACUTE)]
    for lbl, v in rows:
        print("  %-34s %8.2f   %s" % (lbl, v, "YES" if lo <= v <= hi else "no"))

    print("\n5. THE VERDICT, AND IT IS NOT THE CONVENIENT ONE")
    print("-" * W)
    print("  TEST ZERO PASSES: the 2 mmHg is a real effect at p = 0.02, so it is")
    print("  admissible as a comparator and the pass proceeds to section 3.")
    print()
    print("  BUT IT DOES NOT DISCRIMINATE CLEANLY. Its interval CONTAINS Cutler's 1.70")
    print("  and the model's acute-satisfying 1.01 alike, and excludes only the TOP of")
    print("  the meta-analytic window. A number that admits both candidates cannot")
    print("  choose between them - branch C4's shape.")
    print()
    print("  AND TWO FEATURES WOULD BIAS IT LOW AGAINST A POPULATION ESTIMATE, WHICH")
    print("  IS THE OPPOSITE OF WHAT THIS PASS WOULD PREFER:")
    print("    - YOUNG MEN, age 24 +/- 7. Salt sensitivity rises with age, so this is")
    print("      close to the least salt-sensitive group that could have been studied.")
    print("    - ONE WEEK per level, against the four weeks and longer of the trials")
    print("      the meta-analyses pool. Seven days may be short of a chronic steady")
    print("      state, and the model's own step runs 30-40 days.")
    print()
    print("  SO THE HONEST READING IS THAT VAN DEN BOSCH LOWERS THE PLAUSIBLE RANGE")
    print("  WITHOUT SETTLING IT, and section 3's estimand question - what population")
    print("  each meta-analysis actually measured - is still what decides this.")
    print("=" * W)
    return 0


if __name__ == "__main__":
    sys.exit(main())
