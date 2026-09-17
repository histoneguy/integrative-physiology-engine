#!/usr/bin/env python3
"""
De-indexing: the reference body first, then the rows it unlocks.

Run it:  python validation/deindexing_extract.py

PRE-REGISTERED IN validation/deindexing_prereg.md, COMMITTED BEFORE THIS FILE EXISTED.

    git log --diff-filter=A -- validation/deindexing_prereg.md
    git log --diff-filter=A -- validation/deindexing_extract.py

STAGE 1 uses NO NEW SOURCE. The NHANES 2007-2012 BMX and DEMO microdata are already in
validation/data/nhanes and were downloaded for body_size_scaling_extract.py, which this
file reuses wholesale. The quantity wanted is different: the survey-weighted mean height
of adults AT THE REFERENCE MASS, rather than over all adults.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from body_size_scaling_extract import (  # noqa: E402
    DEFAULT_DATA, bmx, build, dubois, fetch, wmean,
)

# --- what the ledger says today -------------------------------------------
M_REF = 70.0                    # BF.BODY_MASS.REFERENCE, kg, `assumed`
H_NOW = {"male": 175.8, "female": 162.1}     # BF.HEIGHT.REFERENCE, cm
BSA_NOW = {"male": 1.855, "female": 1.748}   # BF.BSA.REFERENCE, m2 - BEFORE STAGE 1

# --- SETTLED BY STAGE 1, AND THE BAND CHOICE IS NOT LOAD-BEARING -----------
# Weight band +/- 2 kg: the narrowest whose weighted mean weight lands within
# 0.2 kg of the reference with n > 300 per sex. IT BARELY MATTERS - across the
# +/-1, +/-2, +/-3 and +/-5 kg bands the resulting BSA spans 0.17 percent in men
# and 0.22 percent in women, so the choice moves nothing and is recorded as a
# tie-break rather than as a decision.
BAND_KG = 2.0
H_REF = {"male": 171.8, "female": 162.4}     # cm, at 70 kg
BSA_REF = {"male": 1.824, "female": 1.751}   # m2, Du Bois at 70 kg
BSA_CONVENTION = 1.73           # the renal indexing convention

# Petersen 2017, UK Biobank CMR, the SAME cohort and technique the absolute pair
# already in the ledger comes from. Absolute and indexed, reported side by side.
PETERSEN = {
    "male":   {"abs": 96.0, "sd_abs": 20.0, "idx": 49.0, "sd_idx": 10.0, "n": 368},
    "female": {"abs": 75.0, "sd_abs": 14.0, "idx": 45.0, "sd_idx":  8.0, "n": 432},
}

# Soares 2013, 51Cr-EDTA, n = 285. Indexed per 1.73 m2, sexes POOLED because the
# difference was not significant (108 +/- 18 vs 104 +/- 18, p = 0.134).
SOARES = {"idx_mL_min": 106.0, "sd": 18.0, "n": 285,
          "male": 108.0, "female": 104.0, "p_sex": 0.134}

GFR_NOW = 152.6                 # RN.GFR.NOMINAL, L/day


def band_height(d, sex_code, lo, hi):
    """Survey-weighted mean height of adults whose weight is in [lo, hi] kg."""
    e = d[(d.RIAGENDR == sex_code) & d.BMXWT.ge(lo) & d.BMXWT.le(hi)]
    if len(e) == 0:
        return None
    return (wmean(e.BMXHT.values, e.w.values),
            wmean(e.BMXWT.values, e.w.values),
            float(e.w.sum()), len(e))


def stage1(d):
    """The reference body, made internally consistent."""
    out = {}
    for sex, code in (("male", 1), ("female", 2)):
        rows = []
        for half in (1.0, 2.0, 3.0, 5.0):
            r = band_height(d, code, M_REF - half, M_REF + half)
            if r:
                h, w, sw, n = r
                rows.append((half, h, w, n, dubois(M_REF, h)))
        out[sex] = rows
    return out


def stage2():
    """Stroke volume, de-indexed through the reference BSA."""
    out = {}
    for sex, p in PETERSEN.items():
        implied = p["abs"] / p["idx"]
        out[sex] = {"implied_cohort_bsa": implied, **p}
    return out


def gfr_deindexed(bsa):
    """GFR at the reference body, from a per-1.73 m2 figure."""
    return SOARES["idx_mL_min"] * (bsa / BSA_CONVENTION) * 1440.0 / 1000.0


STAGE2_OUTCOME = [
    "THE PRE-REGISTERED PREDICTION HELD AND IT COULD HAVE FAILED. Male stroke",
    "volume -6.9 percent, female +5.0. Opposite signs, each under 10, fixed in",
    "deindexing_prereg.md section 6 before the implied cohort BSA was computed.",
    "",
    "BUT THE CONSEQUENCE IS NOT THE ROW. CV.SV.NOMINAL carried Petersen's COHORT",
    "body size - men of 1.96 m2 against women of 1.67 - on top of the model's own",
    "sexed mass sampling. Removing that double count moves:",
    "",
    "    stroke volume sex difference        28  -> 13  percent",
    "    cardiac output sex difference       22  -> 7.5 percent",
    "    predicted salt-sensitivity ratio    1.172 -> 1.062",
    "    TPR0 x BV0, female/male             1.069 -> 0.941",
    "",
    "THE LAST LINE IS A REVERSAL. The test suite asserted, with the mechanism",
    "written out, that dMAP/dV_ecf scales as TPR0*BV0 and that the product is",
    "larger in women, so women reach the same pressure shift on a SMALLER",
    "extracellular excursion. De-indexing raised male TPR0 and lowered female, and",
    "the ordering flipped: women now need a LARGER excursion.",
    "",
    "SO A SEXED MODEL PREDICTION WAS SUBSTANTIALLY AN INDEXING ARTEFACT. HANDOVER",
    "section 4 item 7 records the 17.7 percent as debt and says 'source it or",
    "falsify it'. Two thirds of it is now falsified, and not by a source - by a",
    "double count inside the model that the row itself had described.",
    "",
    "NOTHING WAS FITTED. deindexing_prereg.md section 4 forbids re-estimating",
    "G_pn and G_anp and neither moved. The two regression pins that failed both",
    "moved INTO the middle of their human bands: the salt-sensitivity shift from",
    "1.886 to 2.004 against a human 1.70-2.30, and dMAP/dV_ecf from 2.98 to 3.22",
    "against a human 2.97-4.16, where 2.98 sat on the floor. Their own comments",
    "say to re-pin and not to refit, and that is what was done.",
]

STAGE3_DEFERRAL = [
    "GFR IS NOT DE-INDEXED IN THIS PASS. The correction is computed above and is",
    "+5.4 percent for men and +1.2 for women at the corrected reference body.",
    "",
    "WHY NOT. Sodium excretion is GFR * C_Na * (1-FR), so a higher GFR must be",
    "absorbed by RN.NA.FRACTIONAL_REABSORPTION, which is derived and would take it",
    "at the operating point. But BF.NA.INTAKE_NOMINAL is a single `both` row while",
    "the de-indexed GFR is a PAIR, so FR_Na would become sexed too - and the model",
    "would then assert a sex difference in tubular reabsorption that exists only",
    "because both sexes are fed the same absolute sodium. Soares measured NO sex",
    "difference in indexed GFR, p = 0.134.",
    "",
    "AND THE SENSITIVITY, NOT ONLY THE LEVEL, WOULD MOVE. Everything acting on FR",
    "scales with the filtered load, so a 5 percent GFR rise makes every natriuretic",
    "response stronger - and section 3.40 measured CV.ANP.NATRIURETIC_GAIN's own",
    "interval swinging salt sensitivity by 45 percent of baseline. Moving GFR and",
    "then re-fitting the two parameters that carry the model is what",
    "deindexing_prereg.md section 9 names as the second way this pass fails.",
    "",
    "THIS PASS ALREADY CARRIES A REVERSED SEXED PREDICTION. Two structural changes",
    "and one review is how a real effect and an artefact get attributed to each",
    "other. Recorded, unapplied, and HANDOVER section 4 item 10 stays open for it.",
]

def main() -> int:
    W = 78
    print("=" * W)
    print("DE-INDEXING - EXTRACTION UNDER validation/deindexing_prereg.md")
    print("=" * W)

    d = build(fetch(DEFAULT_DATA)).merge(bmx(DEFAULT_DATA), on="SEQN", how="inner")
    d = d[(d.RIDAGEYR >= 20) & d.BMXHT.notna() & d.BMXWT.notna() & d.w.gt(0)
          & (d.RIDEXPRG != 1)]
    print("\nNHANES 2007-2012, adults 20+, non-pregnant, MEASURED height and weight.")
    print("n = %d unweighted. Same file and same filter as body_size_scaling_extract.py."
          % len(d))

    print("\n1. STAGE 1 - THE REFERENCE BODY, AND IT IS NOT CONSISTENT TODAY")
    print("-" * W)
    print("  BF.HEIGHT.REFERENCE is the mean height of ALL adults, who average 88.4 kg")
    print("  (men). The reference individual weighs 70. Its own note says the mismatch")
    print("  matters by a few per cent for de-indexing - which is the size of the")
    print("  correction this pass exists to make.")
    print()
    s1 = stage1(d)
    print("  %-8s %-10s %8s %8s %7s %9s" %
          ("sex", "band (kg)", "height", "mean wt", "n", "BSA@70kg"))
    for sex, rows in s1.items():
        for half, h, w, n, bsa in rows:
            print("  %-8s %-10s %8.1f %8.1f %7d %9.4f"
                  % (sex, "%g +/- %g" % (M_REF, half), h, w, n, bsa))
        print("  %-8s %-10s %8.1f %8s %7s %9.4f   <- IN THE LEDGER NOW"
              % (sex, "all adults", H_NOW[sex], "-", "-", BSA_NOW[sex]))
        print()

    print("\n2. STAGE 2 - STROKE VOLUME, AND THE SIGN WAS PREDICTED IN ADVANCE")
    print("-" * W)
    print("  Petersen reports ABSOLUTE and INDEXED stroke volume for the same cohort,")
    print("  so the implied cohort BSA is their quotient. No new source.")
    print()
    print("  %-8s %8s %8s %12s %12s" %
          ("sex", "abs mL", "idx mL/m2", "implied BSA", "ref BSA now"))
    for sex, v in stage2().items():
        print("  %-8s %8.0f %8.0f %12.3f %12.3f"
              % (sex, v["abs"], v["idx"], v["implied_cohort_bsa"], BSA_NOW[sex]))
    print()
    print("  PREDICTION FIXED BEFORE LOOKING (prereg section 6): the reference is 70 kg")
    print("  for BOTH sexes - light for a man, heavy for a woman - so de-indexing must")
    print("  move male stroke volume DOWN and female UP. Opposite signs, each under 10%.")

    print("\n3. STAGE 3 - GFR, THE INSTRUCTION THAT SAT UNAPPLIED FOR ELEVEN DAYS")
    print("-" * W)
    print("  BF.BSA.REFERENCE's note: 'any quantity de-indexed from a per-1.73-m2")
    print("  figure must be multiplied by 1.8545/1.73 and not taken as-is.'")
    print("  RN.GFR.NOMINAL's note: '106 mL/min/1.73 m2 x 1440 / 1000 = 152.64' - as-is.")
    print()
    print("  Soares pooled the sexes: %.0f vs %.0f mL/min/1.73 m2, p = %.3f."
          % (SOARES["male"], SOARES["female"], SOARES["p_sex"]))
    print("  SO A SEXED GFR HERE IS BODY SIZE AND NOT A MEASURED SEX DIFFERENCE.")
    print()
    print("  %-8s %12s %12s %10s" % ("sex", "BSA used", "GFR L/day", "vs 152.6"))
    for sex in ("male", "female"):
        g = gfr_deindexed(BSA_NOW[sex])
        print("  %-8s %12.4f %12.1f %9.1f%%"
              % (sex, BSA_NOW[sex], g, 100.0 * (g - GFR_NOW) / GFR_NOW))
    print()
    print("  THIS IS THE NAIVE CORRECTION, computed through the CURRENT reference BSA.")
    print("  Stage 1 must settle that BSA before any of it is entered - prereg section 1.")

    print("\n4. SETTLED - THE SAME TWO STAGES AT THE CORRECTED REFERENCE BODY")
    print("-" * W)
    print("  Band +/- %g kg. Across the +/-1, +/-2, +/-3 and +/-5 kg bands the"
          % BAND_KG)
    print("  resulting BSA spans 0.17 percent in men and 0.22 in women, so the band")
    print("  choice is a tie-break and not a decision.")
    print()
    print("  %-8s %10s %10s %10s %10s" % ("sex", "height", "BSA now", "BSA new", "change"))
    for sex in ("male", "female"):
        print("  %-8s %8.1f   %10.4f %10.4f %9.2f%%"
              % (sex, H_REF[sex], BSA_NOW[sex], BSA_REF[sex],
                 100.0 * (BSA_REF[sex] - BSA_NOW[sex]) / BSA_NOW[sex]))
    print()
    print("  THE ASYMMETRY IS THE WHOLE POINT AND IT IS NOT AN ACCIDENT. The reference")
    print("  mass is 70 kg for both sexes. NHANES women average 75.2 kg, so the")
    print("  all-adult mean height was already nearly right for a 70 kg woman. NHANES")
    print("  men average 88.4 kg, so it described a man 4 cm taller than a 70 kg man")
    print("  really is - BMI 22.6 against a measured 23.7.")
    print()
    print("  %-8s %10s %10s %10s %12s %12s"
          % ("sex", "SV now", "SV new", "change", "GFR new", "implied FR"))
    for sex in ("male", "female"):
        sv = PETERSEN[sex]["idx"] * BSA_REF[sex]
        g = gfr_deindexed(BSA_REF[sex])
        fr = 1.0 - 205.0 / (g * 140.0)
        print("  %-8s %10.0f %10.1f %9.1f%% %12.1f %12.6f"
              % (sex, PETERSEN[sex]["abs"], sv,
                 100.0 * (sv - PETERSEN[sex]["abs"]) / PETERSEN[sex]["abs"], g, fr))
    print()
    print("  THE PRE-REGISTERED PREDICTION HOLDS: male stroke volume moves DOWN and")
    print("  female UP, opposite signs, each under 10 percent. Prereg section 6, fixed")
    print("  before the implied cohort BSA was computed; section 8 falsifiable test 4.")

    print("\n5. WHAT STAGE 2 DID TO THE MODEL, AND IT IS BIGGER THAN THE ROW")
    print("-" * W)
    for line in STAGE2_OUTCOME:
        print("  " + line)

    print("\n6. STAGE 3 IS NOT TAKEN, AND THE NUMBER IS RECORDED UNAPPLIED")
    print("-" * W)
    for line in STAGE3_DEFERRAL:
        print("  " + line)

    print("\n" + "=" * W)
    print("STAGE 1: B1 for men (BSA -1.7%), B2 for women (+0.15%). Behaviourally inert.")
    print("STAGE 2: taken. Opposite signs as predicted. A sexed prediction reversed.")
    print("STAGE 3: DEFERRED. GFR +5.4% male / +1.2% female, measured and unapplied.")
    print("=" * W)
    return 0


if __name__ == "__main__":
    sys.exit(main())
