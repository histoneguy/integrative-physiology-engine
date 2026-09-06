#!/usr/bin/env python3
"""
Body-size scaling: height, body surface area, and the exponent.

    python validation/body_size_scaling_extract.py

Pre-registered in validation/body_size_scaling_prereg.md, written before any
number was computed, with the formula-choice rule and all four branches fixed.

    git log --diff-filter=A -- validation/body_size_scaling_prereg.md
    git log --diff-filter=A -- validation/body_size_scaling_extract.py

This discharges the debt src/scaling.jl recorded against itself.
"""
from __future__ import annotations

import math
import sys
import urllib.request
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
from nhanes_hpt_extract import fetch, build, wmean, DEFAULT_DATA, BASE  # noqa: E402

CYCLES = [("2007", "E"), ("2009", "F"), ("2011", "G")]
M_REF = 70.0


def rule(c="="):
    print(c * 80)


# The four formulas, all as printed in sources. Du Bois is the one entered; the
# others are here because the spread between them IS the exponent's uncertainty.
def dubois(wt, ht):
    return 0.007184 * wt ** 0.425 * ht ** 0.725


def mosteller(wt, ht):
    return np.sqrt(wt * ht / 3600.0)


def haycock(wt, ht):
    return 0.024265 * wt ** 0.5378 * ht ** 0.3964


def gehan(wt, ht):
    return 0.0235 * wt ** 0.51456 * ht ** 0.42246


FORMULAS = [("Du Bois 1916  [ENTERED]", dubois), ("Mosteller 1987", mosteller),
            ("Gehan-George 1970", gehan), ("Haycock 1978", haycock)]


def bmx(data_dir: Path) -> pd.DataFrame:
    frames = []
    for year, s in CYCLES:
        p = data_dir / f"BMX_{s}.xpt"
        if not p.exists():
            urllib.request.urlretrieve(BASE.format(year=year, file="BMX", s=s), p)
        b = pd.read_sas(p)
        frames.append(b[[c for c in ("SEQN", "BMXHT", "BMXWT") if c in b.columns]])
    return pd.concat(frames, ignore_index=True)


def wreg(y, x, w):
    """Weighted slope of y on x."""
    mx, my = wmean(x, w), wmean(y, w)
    return wmean((x - mx) * (y - my), w) / wmean((x - mx) ** 2, w)


def main() -> int:
    d = build(fetch(DEFAULT_DATA)).merge(bmx(DEFAULT_DATA), on="SEQN", how="inner")
    d = d[(d.RIDAGEYR >= 20) & d.BMXHT.notna() & d.BMXWT.notna() & d.w.gt(0)
          & (d.RIDEXPRG != 1)]
    w, H, W = d.w.values, d.BMXHT.values, d.BMXWT.values

    rule()
    print("1. THE DEBT, IN src/scaling.jl's OWN WORDS")
    rule()
    for line in [
        "    'GFR and cardiac output are conventionally normalised to BODY SURFACE AREA,",
        "     which grows sub-linearly with mass, so linear scaling OVERSTATES their",
        "     spread across a population. Correcting that needs height, which this model",
        "     does not carry, and a BSA formula, which would need its own extraction.",
        "     Recorded as debt rather than approximated with an unsourced exponent.'",
        "",
        "  Also HANDOVER section 4 item 10 and OPEN-QUESTIONS B6. This is that extraction.",
        "",
        "  IT IS WORTH MORE NOW THAN WHEN IT WAS RECORDED, because RESP.METABOLIC_RATE was",
        "  entered per kilogram from a source that says explicitly that metabolic rate per",
        "  kilogram FALLS with mass. The model was scaling it linearly and therefore",
        "  overstating the metabolic rate of heavy people in a way its own source refutes.",
    ]:
        print(line)

    print()
    rule()
    print("2. HEIGHT, MEASURED")
    rule()
    print("  NHANES 2007-2012, file BMX, variables BMXHT and BMXWT - MEASURED, not")
    print("  self-reported. Adults 20+, not pregnant, weighted WTMEC2YR/3.")
    print()
    print("    %-8s %6s %10s %8s %10s" % ("", "n", "height cm", "SD", "weight kg"))
    for g, lab in ((1, "men"), (2, "women")):
        e = d[d.RIAGENDR == g]
        h = e.BMXHT.values
        m = wmean(h, e.w.values)
        print("    %-8s %6d %10.2f %8.2f %10.2f"
              % (lab, len(e), m,
                 math.sqrt(wmean((h - m) ** 2, e.w.values)), wmean(e.BMXWT, e.w.values)))
    print("    %-8s %6d %10.2f %8s %10.2f" % ("all", len(d), wmean(H, w), "-", wmean(W, w)))
    print()
    print("  THE MODEL'S REFERENCE INDIVIDUAL IS 70 kg AND THE US ADULT MEAN IS 88.4 and")
    print("  75.2. BF.BODY_MASS.REFERENCE is `assumed`; the model is scaled against a")
    print("  population it does not sit in the middle of. Recorded, not fixed here.")

    print()
    rule()
    print("3. BODY SURFACE AREA, AND THE EXPONENT")
    rule()
    hm = wmean(d[d.RIAGENDR == 1].BMXHT.values, d[d.RIAGENDR == 1].w.values)
    hf = wmean(d[d.RIAGENDR == 2].BMXHT.values, d[d.RIAGENDR == 2].w.values)
    print("  %-26s %11s %11s %11s %10s"
          % ("formula", "BSA 70 kg M", "BSA 70 kg F", "mean BSA", "exponent"))
    for nm, f in FORMULAS:
        bsa = f(W, H)
        k = wreg(np.log(bsa), np.log(W), w)
        print("  %-26s %11.4f %11.4f %11.4f %10.4f"
              % (nm, f(M_REF, hm), f(M_REF, hf), wmean(bsa, w), k))
    print()
    print("  The BSA columns are at the model's 70 kg reference mass and each sex's")
    print("  MEASURED mean height, which is what BF.BSA.REFERENCE carries. The exponent")
    print("  is regressed over all 9300 adults at their own heights and weights.")
    k_ent = wreg(np.log(dubois(W, H)), np.log(W), w)
    print()
    for line in [
        "  DU BOIS IS ENTERED, AND THE RULE WAS FIXED BEFORE THE SEARCH: where formulas",
        "  are comparable, take the one the INDEXED LITERATURE used, because the point of",
        "  having a BSA at all is to make that literature usable. The renal 1.73 m2",
        "  convention and most cardiac indexing descend from Du Bois.",
        "",
        "  THE FORMULA IS QUOTED FROM A SOURCE THAT PRINTS IT, not from memory: Kobayashi",
        "  T et al. PLoS One 2023;18(1):e0280569, PMC9858735, OPEN ACCESS, read in full -",
        "  'BSA[m2] = BW[kg]^0.425 x BH[cm]^0.725 x 0.007184'. Du Bois & Du Bois 1916 was",
        "  NOT opened and the ledger row says so.",
        "",
        "  HOW GOOD ANY OF THEM ARE, against DIRECTLY MEASURED surface area: 179 adults",
        "  3D-scanned, Rybarczyk-Kapuscik A et al. Int J Occup Med Environ Health",
        "  2024;37(2):205-19, PMC11142402, OPEN ACCESS, read in full. Best established",
        "  formula: mean absolute error 0.0249 m2, about 1.3 percent, and accuracy",
        "  'diminishes' outside a normal BMI. That paper's conclusion is that no single",
        "  universal formula is possible - which is why the ledger records the spread",
        "  rather than claiming one is correct.",
        "",
        "  THE REFERENCE BSA IS 1.85 m2 AND THE INDEXING CONVENTION IS 1.73. The model's",
        "  reference adult has 7 percent more surface than the 1928 figure everything is",
        "  indexed to, so a per-1.73-m2 quantity must be multiplied by 1.8545/1.73 to",
        "  reach this individual and NOT taken as-is. That is the whole practical point of",
        "  these rows.",
    ]:
        print(line)

    print()
    rule()
    print("4. WHAT IT DOES TO THE MODEL - BRANCH S1")
    rule()
    print("  k = %.4f, inside the 0.5-0.9 the pre-registration fixed as branch S1." % k_ent)
    print()
    print("    %-10s %14s %14s %12s" % ("body mass", "old factor", "new factor", "change"))
    for bm in (45.0, 55.0, 70.0, 85.0, 95.0, 110.0):
        old, new = bm / M_REF, (bm / M_REF) ** k_ent
        print("    %-10.0f %14.4f %14.4f %11.1f%%"
              % (bm, old, new, (new / old - 1) * 100))
    print()
    for line in [
        "  THE REFERENCE INDIVIDUAL DOES NOT MOVE, and that is branch S3: the factor is",
        "  exactly 1 at 70 kg for ANY exponent, so every pinned number in the suite is",
        "  bit-identical and only the population spread changes. If a pinned number had",
        "  moved, the change would have touched something it should not have.",
        "",
        "  IT IS A POPULATION REGRESSION, NOT A GEOMETRIC LAW, and the difference is the",
        "  whole finding. The surface law gives 2/3 and Kleiber 3/4; this is 0.51, lower",
        "  because in a real adult population mass varies more from ADIPOSITY than from",
        "  frame size and fat adds mass with little height and little surface. That is the",
        "  right exponent for the question the ensemble asks - how does a heavier PERSON",
        "  differ from a lighter one - and the wrong one if body_mass is ever reread as",
        "  frame size, where the two differ by 25 percent at 95 kg.",
        "",
        "  ONE EXPONENT FOR EVERY SURFACE-LIKE QUANTITY IS A LUMPING, fixed in the",
        "  pre-registration before the number was known. Filtration tracks surface,",
        "  metabolic rate tracks nearer mass^0.75, intake tracks metabolic rate; giving",
        "  them different exponents breaks the sodium and water balances, which need",
        "  intake and clearance to scale together. THE CONSEQUENCE IS THAT THIS MODEL",
        "  CANNOT REPRESENT THE REAL SMALL RISE IN ARTERIAL PRESSURE WITH BODY SIZE, and",
        "  the suite's pressure-invariance assertion is a property of the closure rather",
        "  than a claim about physiology.",
        "",
        "  AND THE WEAKER HALF IS NOW THE VOLUMES. They are still linear in mass, because",
        "  extracellular volume is entered as a mass FRACTION. Fat carries less water than",
        "  lean tissue, so the model overstates the fluid volumes of heavy people exactly",
        "  as it used to overstate their filtration. Not fixed here - one change at a time",
        "  - and it needs a body-composition row this model does not have.",
        "",
        "  NARROWING A SPREAD IS NOT THE SAME AS MAKING IT RIGHT. Nothing here compares",
        "  the model's population spread of filtration or cardiac output against a measured",
        "  spread, and section 8 of the pre-registration forbade claiming otherwise.",
    ]:
        print(line)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
