#!/usr/bin/env python3
"""
Acid-base: BRANCHES A3 AND A4 BOTH FIRED, and what was built instead.

    python validation/acid_base_extract.py

Pre-registered in validation/acid_base_prereg.md, written before any source was
opened, with all four branches fixed in advance. Structure in ADR 0020, amended
the same day because decision 1 did not survive the sourcing.

    git log --diff-filter=A -- validation/acid_base_prereg.md
    git log --diff-filter=A -- validation/acid_base_extract.py

NHANES data are fetched and cached by validation/nhanes_hpt_extract.py's helper;
this file adds the BIOPRO (standard biochemistry profile) files.
"""
from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
from nhanes_hpt_extract import fetch, build, wmean, wquantile, DEFAULT_DATA, BASE  # noqa: E402

CYCLES = [("2007", "E"), ("2009", "F"), ("2011", "G")]
PK, S_CO2, PACO2 = 6.10, 0.030, 40.0


def rule(c="="):
    print(c * 80)


def biopro(data_dir: Path) -> pd.DataFrame:
    import urllib.request
    frames = []
    for year, s in CYCLES:
        p = data_dir / f"BIOPRO_{s}.xpt"
        if not p.exists():
            urllib.request.urlretrieve(BASE.format(year=year, file="BIOPRO", s=s), p)
        b = pd.read_sas(p)
        frames.append(b[[c for c in ("SEQN", "LBXSC3SI", "LBXSKSI", "LBXSCLSI",
                                     "LBXSNASI") if c in b.columns]])
    return pd.concat(frames, ignore_index=True)


def main() -> int:
    d = build(fetch(DEFAULT_DATA)).merge(biopro(DEFAULT_DATA), on="SEQN", how="inner")
    d = d[(d.RIDAGEYR >= 20) & d.LBXSC3SI.notna() & d.w.gt(0) & (d.RIDEXPRG != 1)]
    w = d.w.values

    rule()
    print("1. WHAT WAS NOT BUILT, AND THE TWO BRANCHES THAT SAID SO")
    rule()
    for line in [
        "  ADR 0020 designed a bicarbonate STATE: renal net acid excretion balancing",
        "  endogenous acid production, with pH falling out of Henderson-Hasselbalch.",
        "  BOTH HALVES OF THAT BALANCE FAILED TO SOURCE.",
        "",
        "  BRANCH A3 - the renal response to plasma bicarbonate.",
        "    No published form with a gain in healthy humans could be opened. The",
        "    quantitative acid-base literature is almost entirely disorder-driven:",
        "    ketoacidosis, renal failure, sepsis, ventilated patients. Section 2 of the",
        "    pre-registration predicted this IN ADVANCE as directive 1.7's fifth",
        "    subsystem, which is why the search is reported rather than the absence.",
        "",
        "  BRANCH A4 - net endogenous acid production on an ordinary diet.",
        "",
        "    Mansouri K, Greupner T, van de Flierdt E, Schneider I, Hahn A. Acid-Base",
        "    Balance in Healthy Adults ... The BicarboWater Study. J Nutr Metab",
        "    2024;2024:3905500. PMC11390205. OPEN ACCESS, READ IN FULL. n = 90 healthy",
        "    omnivorous adults, 24-hour urine, three-step Lüthy titration, NAE = TA -",
        "    HCO3 + NH4. BASELINE, before any intervention:  22.4 and 22.3 mEq/day",
        "    (medians, IQR 23.8 and 19.0).",
        "",
        "    Parmenter BH, Dymock M, Banerjee T, Sebastian A, Slater GJ, Frassetto LA.",
        "    Performance of Predictive Equations and Biochemical Measures Quantifying Net",
        "    Endogenous Acid Production. Kidney Int Rep 2020;5(10):1738-45. PMC7569692.",
        "    OPEN ACCESS, READ IN FULL. n = 17, 102 twenty-four-hour urines, fed acid AND",
        "    base forming diets six days each:  NAE 39 +/- 38 mEq/day, range -9 to 95.",
        "    NOT an ordinary diet - the diets were designed to span the range.",
        "",
        "    Against a conventional 1 mEq/kg/day, about 70 for a 70 kg adult.",
        "",
        "    22 AGAINST 70 IS THREEFOLD, and the pre-registration's rule was written for",
        "    exactly this: 'A bicarbonate balance whose input flux is invented is a fitted",
        "    balance, and the set-point would then be doing all the work.'",
        "",
        "  THE OWNER'S RULE APPLIES AND DOES NOT RESCUE IT. Average two good papers when",
        "  they are close; report the spread when they are not. These are not close, they",
        "  do not measure the same thing - one is a habitual diet and one is a designed",
        "  pair of extreme diets - and averaging them would produce a number describing",
        "  neither.",
    ]:
        print(line)

    print()
    rule()
    print("2. WHAT WAS BUILT: THE DEPENDENCY INVERTED, FOR THE THIRD TIME")
    rule()
    hco3 = wmean(d.LBXSC3SI.values, w)
    sd = math.sqrt(wmean((d.LBXSC3SI.values - hco3) ** 2, w))
    print("  NHANES 2007-2012, standard biochemistry profile, variable LBXSC3SI.")
    print("  n = %d adults 20+, not pregnant, weighted WTMEC2YR/3." % len(d))
    print()
    print("    serum bicarbonate   %.2f mmol/L   SD %.2f   2.5-97.5%%  %.1f - %.1f"
          % (hco3, sd, wquantile(d.LBXSC3SI, w, .025), wquantile(d.LBXSC3SI, w, .975)))
    for tag, col in (("serum sodium", "LBXSNASI"), ("serum chloride", "LBXSCLSI"),
                     ("serum potassium", "LBXSKSI")):
        if col in d and d[col].notna().sum() > 100:
            print("    %-18s  %.2f mmol/L   (reported for context; not entered)"
                  % (tag, wmean(d[col].values, w)))
    print()
    for line in [
        "  PLASMA BICARBONATE IS AN INPUT AND ARTERIAL pH IS THE OUTPUT. Third inversion",
        "  in this model, after arterial PCO2 (ADR 0017's amendment) and the thyroid",
        "  operating point (HANDOVER section 3.26), and the same reason each time: source",
        "  the quantity that is actually measured. Bicarbonate is measured in every basic",
        "  metabolic panel; renal net acid excretion is measured in nobody healthy.",
        "",
        "  NO STATE AND NO ELEVENTH COMPONENT. Three constants and one equation, in",
        "  Blood.jl, which already receives arterial PCO2.",
    ]:
        print(line)

    print()
    rule()
    print("3. THE TEST THAT SURVIVES, AND IT IS A REAL ONE")
    rule()
    ph = PK + math.log10(hco3 / (S_CO2 * PACO2))
    for line in [
        "  Bellelli A. Blood buffers: the viewpoint of a biochemist. Physiol Rep",
        "  2025;13(9):e70345. PMC12051385. OPEN ACCESS, READ IN FULL:  'pK = 6.1 at",
        "  T = 37 C (Ellison et al., 1958)', and a solubility of 0.03 mmol/L/mmHg.",
        "  ELLISON 1958 WAS NOT OPENED and the row says so - directive 1.5 means the",
        "  citation is what was read, with the origin named.",
        "",
        "  FOUR INDEPENDENT MEASUREMENTS COMPOSE INTO A FIFTH, and none of them is a pH:",
        "",
        "      pK        6.10          by titration",
        "      solubility 0.030        by tonometry",
        "      HCO3      %.2f mmol/L  in 8809 adults" % hco3,
        "      PaCO2     40.0 mmHg     sourced under ADR 0017",
        "",
        "      ->  pH =  %.3f" % ph,
        "",
        "  AND THEY COMPOSE, WHICH IS THE WHOLE POINT. A millimole is a millimole, unlike",
        "  the free-thyroxine assays of section 3.26. So this can be wrong.",
    ]:
        print(line)

    print()
    print("  AGAINST A HUMAN ARTERIAL pH OF 7.40 (7.35-7.45) THE MODEL GIVES %.2f." % ph)
    print()
    for line in [
        "  THE RESIDUAL IS NAMED AND NOT CLOSED. AB.HCO3.PLASMA is a VENOUS serum TOTAL",
        "  CO2 - what a chemistry panel measures - and Henderson-Hasselbalch wants",
        "  ARTERIAL BICARBONATE. Total CO2 includes dissolved gas and carbamino compounds;",
        "  venous blood carries more of all three. The conventional offset is 1 to 2",
        "  mmol/L:",
    ]:
        print(line)
    print()
    for off in (0.0, 1.0, 2.0):
        print("      HCO3 %.2f  ->  pH %.3f%s" % (hco3 - off,
              PK + math.log10((hco3 - off) / (S_CO2 * PACO2)),
              "   <- as entered" if off == 0 else ""))
    print()
    for line in [
        "  ONE MILLIMOLE OF OFFSET IS THE WHOLE DISCREPANCY. Applying it would set the",
        "  parameter from arterial pH, which is the quantity the test judges - the error",
        "  that voided ADR 0019's falsifiable test 2. So it is reported.",
        "",
        "  THIRD MEASUREMENT-SCALE MISMATCH IN THIS MODEL AND THE FIRST CAUGHT BEFORE THE",
        "  NUMBER WAS BELIEVED. Section 3.26 and section 3.28 were both found afterwards.",
    ]:
        print(line)

    print()
    rule()
    print("4. WHAT THE MODEL CAN AND CANNOT NOW DO")
    rule()
    for line in [
        "  IT CAN: report arterial pH, and move it with any respiratory disturbance. At",
        "  twice thyroid secretory capacity with the metabolic arm on, arterial PCO2 rises",
        "  to 41.8 and pH falls to 7.400 - a FOUR-HOP chain, thyroid -> respiratory ->",
        "  arterial CO2 -> pH, and the longest in the model.",
        "",
        "  IT CANNOT: compensate. Bicarbonate is a constant, so there is no renal response",
        "  to a sustained change in PCO2 (ADR 0020 falsifiable tests 2 and 3 are void and",
        "  recorded as such), and pH does not feed back onto ventilation, so a metabolic",
        "  acidosis produces no respiratory compensation (decision 3, deliberate).",
        "",
        "  TEST 4 BECOMES THE SHARP ONE and is inverted into an assertion that the",
        "  omission is real: a respiratory disturbance MUST move pH and a metabolic one",
        "  CANNOT. That puts decision 3's omission in the output rather than only in the",
        "  record.",
        "",
        "  WHAT WOULD DISCHARGE THE DEFERRAL: a measurement of renal net acid excretion",
        "  against plasma bicarbonate in healthy adults, and a second habitual-diet",
        "  measurement of net endogenous acid production to arbitrate 22 against 70.",
    ]:
        print(line)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
