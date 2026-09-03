#!/usr/bin/env python
"""The renin gain, re-derived. Branch R1, and the blocker was a sentence nobody checked.

Executes validation/renin_gain_prereg.md, committed before any source was opened and
sitting before this change in the branch history. No commit SHA is cited - rebase-merge
rewrites it. Verify the ordering with:

    git log --diff-filter=A -- validation/renin_gain_prereg.md

THE VERDICT: RAAS.RENIN.PRESSURE_GAIN 19.0 -> 4.35, `assumed` -> `derived`, tier C -> B.

    g_renin = 0.05 per mmHg * MAP_ref = 0.05 * 87.0 = 4.35

THE SOURCE WAS ALREADY CITED IN THE SAME FILE. van Ochten 2025 supplies the rectification
threshold and the linear form in Raas.jl. It also supplies the SLOPE, in section 3.3.2:
"A decrease of 10 mmHg in renal blood pressure leads to an increase of 50 percentage
points renin in healthy animals", renin being a percentage of its value at the baseline
mean renal arterial pressure of 110 mmHg. That baseline is ABOVE the 93 mmHg threshold,
so the 100% reference IS the plateau - which is exactly what pra = 1 means in Raas.jl.

WHY THE ROW SAT `assumed` FOR SIX DAYS. Its note said van Ochten "reports the renal
baroreflex slope in animal units this model cannot consume directly, so the gain is
fitted rather than converted." The paper says the opposite, in its own Limitations: it
could NOT meta-analyse absolute renin, because the included studies reported PRA, PRC or
renin release on assay-dependent scales, so it converted the dose-response to PERCENTAGE
OF BASELINE - the one form a dimensionless normalised pra can consume. The units were
never the obstacle. The pre-registration flagged that sentence as a previous session's
claim about a paper and required it to be tested rather than inherited. It was wrong.

pra = 1 IS THE PLATEAU, NOT RESTING RENIN, and conflating the two is how this row broke.
The old calibration fitted the gain so the low-salt arm "doubled PRA from a baseline of
1.0" - true only while CV.MAP.SETPOINT was also 93 and the drive was identically zero.

AND BRANCH S2 HOLDS TOO: the structure cannot carry the human salt-renin response at any
gain. That is recorded, not fitted around. See section 3.

Run:  python validation/renin_gain_extract.py
"""

# ---------------------------------------------------------------------------
# THE SOURCE. Read as full text from PubMed Central, PMC12422813.
#
# van Ochten M, El Fathi W, Bovee EME, Spaanderman MEA, Hooijmans CR, van Drongelen J.
# The renal baroreflex: A systematic review and meta-analysis in healthy and hypertensive
# animals. Physiol Rep 2025;13(17):e70547. doi:10.14814/phy2.70547. PMID 40930784.
#
# 1508 records screened, 55 in the systematic review, 30 in the meta-analysis, 36
# comparisons. Species: rat (16), dog (12), plus mouse, rabbit, cat and fowl.
# Method, section 2.4: linear regression below 90 mmHg renal arterial pressure; plateau
# averaged above 105 mmHg; threshold = their intersection.
# The paper states: "Risk of bias was high in most studies."
# ---------------------------------------------------------------------------

VAN_OCHTEN = dict(
    slope_pct_points=50.0,      # percentage points of plateau renin ...
    slope_per_mmHg=10.0,        # ... per this many mmHg of renal arterial pressure
    reference_pressure=110.0,   # mmHg, the 100% reference - ABOVE threshold, so plateau
    threshold=93.0, threshold_sd=2.0,
    n_comparisons_slope=5,      # Figure 6 subset, NOT the 30-study main analysis
    n_studies_meta=30,
    linear_fit_below=90.0,      # mmHg - the range the slope is fitted over
    plateau_averaged_above=105.0,
)

MODEL = dict(
    map_ref=87.0,               # CV.MAP.SETPOINT
    p_thr=93.0,                 # RAAS.RENIN.PRESSURE_THRESHOLD
    drive_at_operating_point=0.069216,
    incumbent_gain=19.0,
    operating_map=86.978,
)

# Human salt-step renin, from validation/renal_hemodynamics_salt_sources.md. RECORDED
# FOR FALSIFICATION ONLY. The pre-registration forbids fitting the gain to these.
# van den Bosch 2021, PMID 34921521, n = 70 healthy men, Table 1.
VDB = dict(pra_high_salt=2.10, pra_low_salt=5.74, map_high_salt=88.0, map_low_salt=86.0)

# bench/renin_gain_sweep.jl, escape SUPPRESSED (ADR 0015's configuration).
ESCAPE_OFF = {4.35: 0.215, 9.50: 0.357, 19.0: 0.507, 38.0: 0.658, 76.0: 0.786}


def main():
    print(__doc__)
    print("=" * 78)
    print("1. THE DERIVATION")
    print("=" * 78)
    v, m = VAN_OCHTEN, MODEL
    slope = v["slope_pct_points"] / 100.0 / v["slope_per_mmHg"]
    g = slope * m["map_ref"]
    print("  Raas.jl:      pra -> 1 + g_renin * (P_thr - MAP) / MAP_ref")
    print("  so            d(pra)/d(MAP) = -g_renin / MAP_ref")
    print("  van Ochten:   d(renin/plateau)/d(MAP) = -%.0f%% / %.0f mmHg = -%.4f per mmHg"
          % (v["slope_pct_points"], v["slope_per_mmHg"], slope))
    print()
    print("  g_renin = %.4f x %.1f = %.4f  ->  ENTERED AS 4.35" % (slope, m["map_ref"], g))
    print()
    print("  Resting pra falls %.2f -> %.4f  (drive %.6f at the operating point)"
          % (1 + m["incumbent_gain"] * m["drive_at_operating_point"],
             1 + g * m["drive_at_operating_point"], m["drive_at_operating_point"]))
    print()
    print("  THREE SIGNIFICANT FIGURES FROM A ONE-FIGURE SOURCE, and the difference is")
    print("  arithmetic rather than precision. '50 percentage points per 10 mmHg' carries")
    print("  one figure. 4.35 is stored so the identity g_renin = 0.05*MAP_ref reproduces")
    print("  exactly and stays exact if the setpoint moves again - which it has done once")
    print("  already, and that move is what voided the old target. The test suite asserts")
    print("  the IDENTITY, not the digits.")
    print()
    print("  NO EXTRAPOLATION. The slope is fitted below %.0f mmHg and this model runs at"
          % v["linear_fit_below"])
    print("  MAP 82-87, inside that range. The plateau was averaged above %.0f mmHg and"
          % v["plateau_averaged_above"])
    print("  the threshold is their intersection, %.0f +/- %.0f - the incumbent value of"
          % (v["threshold"], v["threshold_sd"]))
    print("  RAAS.RENIN.PRESSURE_THRESHOLD, unchanged, from the same paper.")

    print()
    print("=" * 78)
    print("2. WHAT IT CHANGES - bench/renin_gain_sweep.jl")
    print("=" * 78)
    print("  STEADY STATE, ESCAPE ON: nothing. Escape drives fr_mod to zero, and a")
    print("  16-fold change in this gain moves the salt-step shift by at most 0.81%.")
    print("  The headline goes 5.056953 -> 5.056485 mmHg. Fifth significant figure.")
    print()
    print("  STEADY STATE, ESCAPE SUPPRESSED - ADR 0015's configuration. This is where")
    print("  the gain was always doing the work, and it is why this row blocked that")
    print("  record:")
    print()
    print("    g_renin   fall in the salt-step shift   escape-off mmHg/100 mmol")
    for gg, fall in sorted(ESCAPE_OFF.items()):
        mark = "  <- DERIVED" if gg == 4.35 else ("  <- was" if gg == 19.0 else "")
        print("     %6.2f            %5.1f%%                %6.3f%s"
              % (gg, fall * 100, 4.9578 * (1 - fall), mark))
    print()
    print("  ADR 0015 SURVIVES ITS OWN TEST AND LOSES MOST OF ITS SIZE. Its pre-registered")
    print("  rule was that a fall above 20% means the pathway is live. At the derived gain")
    print("  the fall is 21.5%, so the verdict holds - but the escape-off salt sensitivity")
    print("  goes 2.444 -> 3.892 mmHg per 100 mmol/day against a human 1.70-2.30. It no")
    print("  longer nearly closes the gap on its own; it closes about a fifth of it.")
    print()
    print("  THE DIRECTION WAS PRE-COMMITTED. The pre-registration recorded, before the")
    print("  search, that this extraction could resize ADR 0015 but not overturn it,")
    print("  because the fall stays above 20% even at a quarter of the incumbent gain.")
    print("  That is what happened, and it was not decided after seeing the number.")

    print()
    print("=" * 78)
    print("3. BRANCH S2 - THE STRUCTURE CANNOT CARRY THE HUMAN SALT-RENIN RESPONSE")
    print("=" * 78)
    d_lo = (m["p_thr"] - VDB["map_low_salt"]) / m["map_ref"]
    d_hi = (m["p_thr"] - VDB["map_high_salt"]) / m["map_ref"]
    ceiling = d_lo / d_hi
    observed = VDB["pra_low_salt"] / VDB["pra_high_salt"]
    print("  The pre-registered test needs no threshold, which is why it was used instead")
    print("  of one. As g_renin -> infinity the achievable PRA ratio between two pressures")
    print("  tends to the ratio of their drives, so that ratio is a CEILING on the form.")
    print()
    print("    van den Bosch 2021, n = 70 healthy men, same subjects:")
    print("      PRA   %.2f (high salt)  against  %.2f (low salt)   ratio %.3f"
          % (VDB["pra_high_salt"], VDB["pra_low_salt"], observed))
    print("      MAP   %.0f              against  %.0f              drives %.5f / %.5f"
          % (VDB["map_high_salt"], VDB["map_low_salt"], d_hi, d_lo))
    print()
    print("      CEILING  %.3f      OBSERVED  %.3f      -> %s"
          % (ceiling, observed, "S2, EXCEEDED" if observed > ceiling else "S1"))
    print()
    print("  NO VALUE OF THIS GAIN REPRODUCES A 2.7-FOLD PRA CHANGE ACROSS 2 mmHg. In")
    print("  humans the salt-induced renin response runs mostly through macula densa")
    print("  sodium delivery and renal sympathetic traffic, and this component has")
    print("  neither. The pre-registration declared these data unusable for fitting")
    print("  BEFORE the search, for exactly this reason.")
    print()
    print("  WHY THAT MATTERS BEYOND THIS ROW. Fitting the gain to salt data would have")
    print("  absorbed a missing mechanism into a parameter - which is precisely how")
    print("  RN.PRESSURE_NATRIURESIS.SLOPE became a hypertensive value (HANDOVER 3.3).")
    print("  The gap is recorded in HANDOVER section 7 instead.")
    print()
    print("  AND IT IS NOT A DEFECT IN 4.35. The van Ochten slope is a pressure-renin")
    print("  relation measured at fixed sodium intake, which is the quantity this form")
    print("  actually represents. The two results are independent.")
    print()


if __name__ == "__main__":
    main()
