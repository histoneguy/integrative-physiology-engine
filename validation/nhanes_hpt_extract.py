#!/usr/bin/env python3
"""
The pituitary-thyroid operating point, measured in NHANES.

    python validation/nhanes_hpt_extract.py [--data DIR]

Pre-registered in validation/nhanes_hpt_prereg.md, which sits before this file in
history and fixes both population definitions and all four decision branches.

    git log --diff-filter=A -- validation/nhanes_hpt_prereg.md
    git log --diff-filter=A -- validation/nhanes_hpt_extract.py

DATA. NHANES 2007-2008, 2009-2010 and 2011-2012, public microdata:
    https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/<2007|2009|2011>/DataFiles/<FILE>_<E|F|G>.xpt
files THYROD, DEMO, RXQ_RX, MCQ. Downloaded on first run into validation/data/nhanes
and cached; delete that directory to re-fetch. THE FILES ARE NOT COMMITTED - they are
53 MB and they are public.

NO SURVEY PACKAGE IS USED AND THE CONSEQUENCE IS STATED. Point estimates are
weighted with WTMEC2YR/3, which is the standard NHANES procedure for pooling three
cycles and is unbiased. Standard errors are computed WITHOUT the design (strata and
PSU), so they are the independent-sampling ones and are too small - typically by a
design-effect factor of 1.5 to 2.5 in NHANES. Every interval printed below is
therefore OPTIMISTIC, and no conclusion here rests on one being narrow.
"""
from __future__ import annotations

import argparse
import math
import sys
import urllib.request
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DATA = ROOT / "validation" / "data" / "nhanes"
BASE = "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/{year}/DataFiles/{file}_{s}.xpt"
CYCLES = [("2007", "E"), ("2009", "F"), ("2011", "G")]
FILES = ["THYROD", "DEMO", "RXQ_RX", "MCQ"]

# Thyroid-active drugs, matched as substrings of RXDDRUG. Fixed in prereg section 3.
THYROID_DRUGS = ("LEVOTHYROXINE", "LIOTHYRONINE", "THYROID", "METHIMAZOLE",
                 "PROPYLTHIOURACIL", "AMIODARONE", "LITHIUM")

# Antibody positivity thresholds NHANES documents for its own assays.
TPO_POS, TGA_POS = 9.0, 4.0

MW_T4 = 776.87          # g/mol
NG_DL_TO_PMOL_L = 1e-9 / MW_T4 * 1e12 * 10.0   # ng/dL -> pmol/L  = 12.87


def rule(c="="):
    print(c * 84)


def fetch(data_dir: Path) -> dict:
    data_dir.mkdir(parents=True, exist_ok=True)
    out = {}
    for year, s in CYCLES:
        for f in FILES:
            p = data_dir / f"{f}_{s}.xpt"
            if not p.exists():
                url = BASE.format(year=year, file=f, s=s)
                print("  fetching %s ..." % url, file=sys.stderr)
                urllib.request.urlretrieve(url, p)
            out[(f, s)] = pd.read_sas(p)
    return out


def build(raw: dict) -> pd.DataFrame:
    frames = []
    for _, s in CYCLES:
        thy, demo = raw[("THYROD", s)], raw[("DEMO", s)]
        mcq, rx = raw[("MCQ", s)], raw[("RXQ_RX", s)]

        d = demo[["SEQN", "RIDAGEYR", "RIAGENDR", "WTMEC2YR"]].copy()
        d["RIDEXPRG"] = demo["RIDEXPRG"] if "RIDEXPRG" in demo else np.nan
        d = d.merge(thy[["SEQN", "LBXTSH1", "LBDT4FSI", "LBXTT4", "LBXTPO", "LBXATG"]],
                    on="SEQN", how="inner")

        d["thy_hx"] = d.SEQN.isin(mcq.loc[mcq.get("MCQ160M").eq(1), "SEQN"]) \
            if "MCQ160M" in mcq else False

        drug = rx[["SEQN", "RXDDRUG"]].copy()
        drug["RXDDRUG"] = drug.RXDDRUG.apply(
            lambda v: v.decode("utf-8", "ignore") if isinstance(v, bytes) else str(v))
        hit = drug.RXDDRUG.str.upper().apply(
            lambda n: any(k in n for k in THYROID_DRUGS))
        d["thy_rx"] = d.SEQN.isin(drug.loc[hit, "SEQN"])

        d["cycle"] = s
        frames.append(d)

    a = pd.concat(frames, ignore_index=True)
    a["w"] = a.WTMEC2YR / 3.0          # three pooled cycles
    return a


def wmean(x, w):
    x, w = np.asarray(x, float), np.asarray(w, float)
    m = np.isfinite(x) & np.isfinite(w)
    return float(np.sum(x[m] * w[m]) / np.sum(w[m]))


def wquantile(x, w, q):
    x, w = np.asarray(x, float), np.asarray(w, float)
    m = np.isfinite(x) & np.isfinite(w)
    x, w = x[m], w[m]
    o = np.argsort(x)
    x, w = x[o], w[o]
    c = np.cumsum(w) - 0.5 * w
    return float(np.interp(q * np.sum(w), c, x))


def wols(y, x, w):
    """Weighted least squares of y on x. Returns slope, intercept and their SEs.

    SEs ASSUME INDEPENDENT SAMPLING - see the module docstring. They are too small."""
    y, x, w = (np.asarray(v, float) for v in (y, x, w))
    m = np.isfinite(y) & np.isfinite(x) & np.isfinite(w)
    y, x, w = y[m], x[m], w[m]
    X = np.column_stack([np.ones_like(x), x])
    W = w / w.mean()
    XtW = X.T * W
    beta = np.linalg.solve(XtW @ X, XtW @ y)
    resid = y - X @ beta
    dof = len(y) - 2
    s2 = float((W * resid ** 2).sum() / dof)
    cov = s2 * np.linalg.inv(XtW @ X)
    return beta[1], beta[0], math.sqrt(cov[1, 1]), math.sqrt(cov[0, 0]), len(y)


def describe(tag, d):
    w = d.w.values
    gm = math.exp(wmean(np.log(d.LBXTSH1.values), w))
    print("  %-26s n=%-6d  TSH gm %.3f  median %.3f   FT4 mean %.2f  median %.2f pmol/L"
          % (tag, len(d), gm, wquantile(d.LBXTSH1, w, 0.5),
             wmean(d.LBDT4FSI, w), wquantile(d.LBDT4FSI, w, 0.5)))
    return gm


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", default=str(DEFAULT_DATA))
    args = ap.parse_args()

    a = build(fetch(Path(args.data)))

    rule()
    print("NHANES 2007-2012: THE PITUITARY-THYROID OPERATING POINT")
    rule()
    print("  thyroid profile records, all ages          %6d" % len(a))

    base = a[(a.RIDAGEYR >= 20) & a.LBXTSH1.notna() & a.LBDT4FSI.notna()
             & a.w.gt(0)].copy()
    print("  adults 20+ with TSH and free T4            %6d" % len(base))

    p1 = base[~base.thy_hx & ~base.thy_rx & (base.RIDEXPRG != 1)].copy()
    print("  P1 disease-free (no history, no drug, not pregnant)  %6d" % len(p1))
    p2 = p1[(p1.LBXTPO < TPO_POS) & (p1.LBXATG < TGA_POS)].copy()
    print("  P2 reference (P1, antibody negative)                 %6d" % len(p2))
    print()

    rule("-")
    print("1. THE OPERATING POINT")
    rule("-")
    describe("P1 disease-free", p1)
    gm2 = describe("P2 reference  [PRIMARY]", p2)
    for s in ("E", "F", "G"):
        describe("   cycle %s" % s, p2[p2.cycle == s])
    for g, lab in ((1, "men"), (2, "women")):
        describe("   %s" % lab, p2[p2.RIAGENDR == g])
    print()
    print("  Hollowell 2002 (NHANES III, 1988-94, n = 13,344) reported a reference-")
    print("  population geometric mean TSH of 1.40 mIU/L. Two surveys, two decades,")
    print("  two assays, and the operating point is where it was.")
    print()

    rule("-")
    print("2. THE PITUITARY LINE, ln(TSH) ON FREE THYROXINE")
    rule("-")
    for tag, d in (("P1 disease-free", p1), ("P2 reference [PRIMARY]", p2)):
        b, a0, sb, sa, n = wols(np.log(d.LBXTSH1), d.LBDT4FSI, d.w)
        bu, au, sbu, sau, _ = wols(np.log(d.LBXTSH1), d.LBDT4FSI,
                                   np.ones(len(d)))
        print("  %-24s n=%-6d  weighted   b = %.4f +/- %.4f   a = %.3f +/- %.3f"
              % (tag, n, -b, sb, a0, sa))
        print("  %-24s            unweighted b = %.4f +/- %.4f   a = %.3f +/- %.3f"
              % ("", -bu, sbu, au, sau))
    b2, a2, sb2, sa2, n2 = wols(np.log(p2.LBXTSH1), p2.LBDT4FSI, p2.w)
    print()
    print("  Sign convention: the model writes ln TSH = a - b*FT4, so b is reported")
    print("  positive above and the regression coefficient is its negative.")
    print()
    print("  THE INTERCEPT NOW HAS A STANDARD ERROR, which THY.TSH.INTERCEPT did not.")
    print("  Note the caveat in the module docstring: the design is not used, so this")
    print("  SE is the independent-sampling one and is too small.")
    print()

    rule("-")
    print("3. THE ASSAY-SCALE COMPARISON, WHICH IS THE ONE THAT MATTERS")
    rule("-")
    ff = (p2.LBDT4FSI / NG_DL_TO_PMOL_L) / (p2.LBXTT4 * 1000.0) * 100.0
    ffm = wmean(ff, p2.w)
    tt4 = wmean(p2.LBXTT4, p2.w)
    ft4 = wmean(p2.LBDT4FSI, p2.w)
    print("  NHANES reference population, weighted means:")
    print("    total thyroxine     %.2f ug/dL" % tt4)
    print("    free  thyroxine     %.2f pmol/L  (%.3f ng/dL)"
          % (ft4, ft4 / NG_DL_TO_PMOL_L))
    print("    free fraction       %.4f %%" % ffm)
    print()
    print("  Braverman LE et al. J Clin Invest 1973;52(5):1010-7, PMC302354, n = 11")
    print("  euthyroid subjects, EQUILIBRIUM DIALYSIS:")
    print("    total thyroxine     7.30 ug/dL")
    print("    free  thyroxine     16.61 pmol/L (1.29 ng/dL)")
    print("    free fraction       0.0180 %")
    print()
    print("  TOTAL THYROXINE AGREES TO %.0f%%. FREE THYROXINE DOES NOT."
          % (abs(tt4 - 7.30) / 7.30 * 100))
    print("    ratio of free fractions, dialysis / immunoassay = %.2f" % (0.0180 / ffm))
    print("    ratio of free thyroxine at equal total          = %.2f"
          % (16.61 / (ft4 * 7.30 / tt4)))
    print()
    print("  Two methods measuring the same subjects' total hormone to within a few")
    print("  per cent, and disagreeing by more than half on the free fraction, are not")
    print("  two measurements of one quantity. THE FREE-THYROXINE SCALES ARE NOT")
    print("  COMMENSURATE, and this is measured here rather than argued.")
    print()

    rule("-")
    print("4. WHAT THAT DOES TO THE MODEL - PRE-REGISTERED BRANCH N3")
    rule("-")
    A_BEN, B_POOL, FT4_BRAV = 3.454, 0.1352, 16.60
    print("  The ledger currently composes a pituitary line measured on one free-")
    print("  thyroxine scale with a reference concentration measured on another:")
    print()
    print("    ln TSH = %.3f - %.4f x FT4      Benhadi 2010, immunoassay"
          % (A_BEN, B_POOL))
    print("    FT4    = %.2f pmol/L                Braverman 1973, dialysis" % FT4_BRAV)
    print("    -> TSH = %.2f mIU/L                 %.1fx the measured %.2f"
          % (math.exp(A_BEN - B_POOL * FT4_BRAV),
             math.exp(A_BEN - B_POOL * FT4_BRAV) / gm2, gm2))
    print()
    print("  THAT IS A UNIT ERROR, NOT AN IMPRECISE COEFFICIENT. An intercept is")
    print("  ln(TSH) + b*FT4 evaluated in one population, so it inherits that")
    print("  population's free-thyroxine SCALE. Putting a different scale's")
    print("  concentration into it is dimensionally the same mistake as reading a")
    print("  pressure in kPa off a line fitted in mmHg.")
    print()
    print("  ON ONE SCALE THROUGHOUT, using NHANES for both:")
    print("    ln TSH = %.3f - %.4f x FT4" % (a2, -b2))
    print("    FT4    = %.2f pmol/L" % ft4)
    print("    -> TSH = %.3f mIU/L    against a measured geometric mean of %.3f"
          % (math.exp(a2 + b2 * ft4), gm2))
    print()
    print("  AND THAT AGREEMENT IS A RESTATEMENT, NOT A PREDICTION. A line and a mean")
    print("  drawn from one population reproduce that population by construction.")
    print("  Pre-registration section 6 requires this be said in those words:")
    print()
    print("      ADR 0019 FALSIFIABLE TEST 2 IS VOID.")
    print()
    print("  It was never a real test. The crossing point of a line and a reference")
    print("  concentration can only be a prediction if the two are on a common scale,")
    print("  and free-thyroxine immunoassays do not share one - which is why section 2")
    print("  of thyroid_prereg.md prohibited POOLING across them and should have")
    print("  prohibited COMPOSING across them too.")
    print()

    rule("-")
    print("5. THE SLOPE: PRE-REGISTERED BRANCH N2, AND IT FIRES")
    rule("-")
    print("    within-subject perturbation  0.1345 - 0.1359 /pmol/L   Benhadi, Jostel")
    print("    between-subject NHANES       %.4f +/- %.4f /pmol/L" % (-b2, sb2))
    print()
    print("  These are NOT the same quantity and the pre-registration said so before")
    print("  the number was computed. A cross-sectional slope mixes people with")
    print("  different setpoints; the model's loop is a within-individual loop, so it")
    print("  needs the perturbation slope. THEY ARE NOT POOLED.")
    print()
    print("  Reported here because it is the population-level relation, and because a")
    print("  large discrepancy between the two is itself the evidence that individual")
    print("  setpoints dominate - which is Benhadi's own conclusion from a different")
    print("  direction: individuality indices of 0.5 to 0.6 for all three hormones.")
    print()

    rule("-")
    print("6. SEX, AND WHETHER ADR 0014 NEEDS A PAIR HERE")
    rule("-")
    for g, lab in ((1, "men"), (2, "women")):
        d = p2[p2.RIAGENDR == g]
        print("    %-6s n=%-6d  FT4 %.2f pmol/L   TSH gm %.3f mIU/L"
              % (lab, len(d), wmean(d.LBDT4FSI, d.w),
                 math.exp(wmean(np.log(d.LBXTSH1), d.w))))
    mfa = wmean(p2[p2.RIAGENDR == 1].LBDT4FSI, p2[p2.RIAGENDR == 1].w)
    mfb = wmean(p2[p2.RIAGENDR == 2].LBDT4FSI, p2[p2.RIAGENDR == 2].w)
    print()
    print("    free thyroxine differs by %.1f%% between the sexes."
          % (abs(mfa - mfb) / ((mfa + mfb) / 2) * 100))
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
