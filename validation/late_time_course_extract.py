#!/usr/bin/env python3
"""
The late time course of an acute isotonic sodium load: what it tests, and what it says.

Run it:  python validation/late_time_course_extract.py

PRE-REGISTERED IN validation/late_time_course_prereg.md, COMMITTED BEFORE THIS FILE
EXISTED.

    git log --diff-filter=A -- validation/late_time_course_prereg.md
    git log --diff-filter=A -- validation/late_time_course_extract.py

THE MODEL NUMBERS ARE MEASURED, NOT ASSERTED. They are produced by
bench/late_time_course.jl and quoted here with their date, exactly as
ecf_deindex_extract.py quotes MODEL_RATIO_NOW. Re-run that file to reproduce them.
"""

from __future__ import annotations

import sys

W = 78

# ---------------------------------------------------------------------------
# THE SOURCE. Drummer C, Gerzer R, Heer M, Molz B, Bie P, Schlossberger M,
# Stadaeger C, Roecker L, Strollo F, Heyduck B, et al. Effects of an acute saline
# infusion on fluid and electrolyte metabolism in humans. Am J Physiol
# 1992;262(5 Pt 2):F744-54. PMID 1590419. ABSTRACT READ IN FULL; the full text was
# not obtained, so the interval series the abstract describes is NOT in hand and no
# quantity here depends on one.
#
# Six healthy volunteers, SUPINE, strictly controlled conditions, 9 days and nights.
# 2 litres of isotonic saline in 25 min. 48 h of collections after the infusion AND a
# 48 h CONTROL experiment, which is what makes the weight trajectory interpretable.
DRUMMER_HALFLIFE_H = 7.0          # "returned to baseline ... half-life of 7 h"
DRUMMER_PEAK_WINDOW = (3.0, 22.0)  # "largest increase ... between 3 and 22 h postinfusion"

# The meta-analytic human chronic response, mmHg per 100 mmol/day. k = 3.
SALT_WINDOW = (1.70, 2.30)

# ---------------------------------------------------------------------------
# MEASURED 2026-09-17 by bench/late_time_course.jl on the model at 4045c17, on
# Drummer's own protocol: 2 L of 0.9% saline in 25 min. The half-life is of the
# V_ecf excursion measured FROM ITS PEAK, which is the model's analogue of a body
# weight excursion for an isotonic load.
AS_MERGED = dict(thalf=13.10, shift=1.9604, peak_h=5.9)

LAG_SWEEP = [  # tau_anp (d), half-life (h), chronic salt sensitivity
    (0.001, 11.97, 1.9603),   # the tau -> 0 limit: an INSTANTANEOUS volume path
    (0.010, 11.93, 1.9603),
    (0.05, 12.07, 1.9603),
    (0.15, 13.10, 1.9604),
    (0.50, 16.47, 1.9607),
    (1.00, 19.37, 1.9612),
]

BOTH_GAINS = [  # multiplier, half-life, salt sensitivity
    (1.0, 13.10, 1.9604),
    (1.5, 10.47, 1.3088),
    (2.0, 8.87, 1.0009),
    (3.0, 6.98, 0.6806),
    (4.0, 5.88, 0.5155),
]

G_ANP_ONLY = [(2.0, 8.98, 1.0903), (3.0, 7.10, 0.7663), (4.0, 6.00, 0.5908)]
G_PN_ONLY = [(3.0, 12.58, 1.4479), (6.0, 11.90, 1.0575), (10.0, 11.12, 0.7786)]
S_GFR_V = [(1.30, 13.10, 1.9604), (2.60, 9.23, 1.7958), (5.20, 8.62, 1.4630)]


def rule(c="-"):
    print(c * W)


def table(rows, head, fmt):
    print("  %-30s %10s %14s" % (head, "t1/2 (h)", "salt sens"))
    for r in rows:
        print("  " + fmt % r)


def main() -> int:
    print("=" * W)
    print("THE LATE TIME COURSE - validation/late_time_course_prereg.md")
    print("=" * W)

    print("\n1. THE SOURCE, AND THE ROW ASKED FOR IT BY NAME")
    rule()
    print("  RN.ANP.TAU's own note: 'WHAT WOULD FALSIFY IT: a human isotonic-loading")
    print("  study reporting the full cumulative sodium excretion curve out to 72 h.'")
    print()
    print("  Drummer C et al. Am J Physiol 1992;262(5 Pt 2):F744-54. PMID 1590419.")
    print("  Six healthy volunteers, supine, 9 days, 2 L of 0.9% saline in 25 min,")
    print("  48 h of collections plus a 48 h CONTROL experiment. ABSTRACT READ IN FULL;")
    print("  the full text was not obtained, so the interval SERIES is not in hand.")
    print()
    print("  WHAT IT PRINTS THAT CAN BE TESTED:")
    print("    elevated body weight returned to baseline with an approximate")
    print("    HALF-LIFE OF %.0f h" % DRUMMER_HALFLIFE_H)
    print("    largest increase in fluid and electrolyte excretion between")
    print("    %.0f and %.0f h postinfusion" % DRUMMER_PEAK_WINDOW)
    print("    the body 'requires approximately 2 days' to regulate the load")
    print()
    print("  NOT the head-down-tilt paper (PMID 1324562). Section 3 of the")
    print("  pre-registration admits only a control arm, and this study has no tilt.")

    print("\n2. THE MODEL, AND ONE TEST PASSES WHILE THE OTHER FAILS")
    rule()
    lo, hi = DRUMMER_PEAK_WINDOW
    ok = lo <= AS_MERGED["peak_h"] <= hi
    print("  peak sodium excretion at %.1f h postinfusion, against a measured window"
          % AS_MERGED["peak_h"])
    print("  of %.0f-%.0f h                                          %s"
          % (lo, hi, "PASS" if ok else "FAIL"))
    print()
    print("  VOLUME EXCURSION HALF-LIFE  %.2f h  against a measured %.0f h    **FAIL**"
          % (AS_MERGED["thalf"], DRUMMER_HALFLIFE_H))
    print("  THE MODEL IS %.1fx TOO SLOW."
          % (AS_MERGED["thalf"] / DRUMMER_HALFLIFE_H))
    print()
    print("  AND THAT REVERSES THE PRE-REGISTERED DIRECTION. Section 1.1 predicted the")
    print("  model would look TOO FAST in the tail, from the HDT paper's qualitative")
    print("  'still elevated beyond 48 h' against a model home by 34 h. With a number")
    print("  rather than a significance statement, the model is too SLOW. The")
    print("  pre-registration fixed the direction in advance precisely so that this")
    print("  could be reported as a reversal instead of being absorbed.")

    print("\n3. THE TAIL RESPONDS TO THE GAINS, NOT TO THE LAG - DEMONSTRATED")
    rule()
    print("  Section 7 item 6 required this to be run rather than asserted.")
    print()
    table(LAG_SWEEP, "LAG: tau_anp (d)", "tau_anp = %-20.2f %10.2f %14.4f")
    print()
    print("  A THOUSANDFOLD CHANGE IN THE LAG MOVES THE HALF-LIFE FROM 19.37 TO 11.93 h")
    print("  AND THE CHRONIC SALT SENSITIVITY BY 0.05 PERCENT.")
    print()
    print("  AND THE LIMIT IS THE ARGUMENT. At tau = 0.001 d the volume path is")
    print("  effectively INSTANTANEOUS and the half-life is still 11.97 h. So 12 h is a")
    print("  FLOOR that no value of the lag can go below, and the measurement is 7 h.")
    print("  THE LAG CANNOT REACH IT - not because 0.15 d is the wrong value, but")
    print("  because the lag is not what sets this quantity.")
    print()
    table(BOTH_GAINS, "BOTH GAINS scaled", "gains x %-22.1f %10.2f %14.4f")
    print()
    print("  The gains reach it at about 3x - and the chronic salt sensitivity collapses")
    print("  from %.3f to %.3f against a human %.2f-%.2f."
          % (BOTH_GAINS[0][2], BOTH_GAINS[3][2], *SALT_WINDOW))

    print("\n4. AND NO OTHER LEVER REACHES IT EITHER")
    rule()
    table(G_ANP_ONLY, "G_anp alone", "G_anp x %-22.1f %10.2f %14.4f")
    print()
    table(G_PN_ONLY, "G_pn alone", "G_pn  x %-22.1f %10.2f %14.4f")
    print("  G_pn SATURATES: tenfold, and the half-life moves 13.10 -> 11.12 h. The")
    print("  pressure arm cannot clear an acute load because MAP barely moves on one.")
    print()
    table(S_GFR_V, "GFR volume response", "S_gfr_v = %-20.2f %10.2f %14.4f")
    print("  S_gfr_v SATURATES TOO, at about 8.6 h, because RN.GFR.VOLUME_RANGE clamps")
    print("  the fractional deviation at 2.9% and an acute load moves ECF by about 14%.")
    print("  The clamp is the censoring bound that row declares, doing its job.")

    print("\n5. THE RESULT: BRANCH L2, AND IT IS ABOUT THE FORM")
    rule()
    print("  NO SINGLE PARAMETER IN THIS MODEL SATISFIES BOTH CONSTRAINTS.")
    print()
    print("    to reach a %.0f h half-life          the chronic salt sensitivity becomes"
          % DRUMMER_HALFLIFE_H)
    print("    both gains x3                    %.3f" % BOTH_GAINS[3][2])
    print("    G_anp alone x3                   %.3f" % G_ANP_ONLY[1][2])
    print("    G_pn alone                       unreachable")
    print("    S_gfr_v alone                    unreachable")
    print("    tau_anp alone                    unreachable")
    print()
    print("  against a human window of %.2f-%.2f. THE ACUTE RESPONSE NEEDS ABOUT THREE"
          % SALT_WINDOW)
    print("  TIMES THE GAIN THE CHRONIC RESPONSE PERMITS.")
    print()
    print("  NOTHING WAS RE-SOLVED. Section 4 of the pre-registration forbids moving")
    print("  G_anp, G_pn or tau_anp in this pass, and none moved. The tension is the")
    print("  result; a parameter chosen to hide it would not be.")
    print()
    print("  AND IT RESTORES AN ARGUMENT THIS REPOSITORY HAD JUST WITHDRAWN. ADR 0010")
    print("  argued from a 'factor of two' disagreement between the acute and chronic")
    print("  limbs that a single linear instantaneous volume-keyed term cannot satisfy")
    print("  both. HANDOVER section 3.45 withdrew that argument on 2026-09-17, because")
    print("  the acute magnitude it rested on had been measured wrongly. THIS PASS")
    print("  RESTORES IT FROM INDEPENDENT DATA AND AT A FACTOR OF THREE - and this time")
    print("  from the SHAPE of the response rather than from its size.")

    print("\n" + "=" * W)
    print("BRANCH L2. Source admissible, the model is 1.9x too slow, the direction")
    print("reverses the pre-registration, the diagnosis was demonstrated rather than")
    print("asserted, and nothing was fitted.")
    print("=" * W)
    return 0


if __name__ == "__main__":
    sys.exit(main())
