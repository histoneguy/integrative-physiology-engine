#!/usr/bin/env python3
"""
Macula densa renin control and potassium.

    python validation/macula_densa_potassium_extract.py

Pre-registered in validation/macula_densa_potassium_prereg.md, written before any
source was opened, with the two forbidden moves named twice. Structure in ADR
0021, amended because two of its decisions did not survive the sourcing.

    git log --diff-filter=A -- validation/macula_densa_potassium_prereg.md
    git log --diff-filter=A -- validation/macula_densa_potassium_extract.py
"""
from __future__ import annotations

import math
import sys
import urllib.request
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
from nhanes_hpt_extract import fetch, build, wmean, wquantile, DEFAULT_DATA, BASE  # noqa: E402

CYCLES = [("2007", "E"), ("2009", "F"), ("2011", "G")]
MW_K = 39.0983

# Brunner 1970 Table I, NORMAL subjects, dietary sodium >= 100 mEq/day.
# name, Na, K_control, K_expt, UKV_C, UKV_E, Kp_C, Kp_E, aldo_C, aldo_E
BRUNNER = [
    ("J.S.(2)", 121, 3, 83, 11.0, 70.7, 3.1, 3.8, 62, 229),
    ("T.B.(2)", 121, 3, 80, 11.9, 77.9, 3.2, 3.8, 45, 232),
    ("G.W.", 102, 132, 239, 93.2, 202.0, 3.9, 4.0, 20, 52),
    ("R.H.", 118, 120, 259, 57.4, 261.0, 4.0, 5.0, 140, 322),
    ("P.K.(1)", 173, 4.1, 165, 12.7, 156.0, 2.8, 3.7, 2.7, 20.3),
    ("G.R.(3)", 171.5, 0.45, 161, 18.6, 109.7, 3.3, 3.8, 2.3, 11.8),
]


def rule(c="="):
    print(c * 80)


def diet(data_dir: Path) -> pd.DataFrame:
    frames = []
    for year, s in CYCLES:
        p = data_dir / f"DR1TOT_{s}.xpt"
        if not p.exists():
            urllib.request.urlretrieve(BASE.format(year=year, file="DR1TOT", s=s), p)
        b = pd.read_sas(p)
        frames.append(b[[c for c in ("SEQN", "DR1TPOTA", "DR1TSODI", "DR1DRSTZ")
                         if c in b.columns]])
    return pd.concat(frames, ignore_index=True)


def biopro(data_dir: Path) -> pd.DataFrame:
    frames = []
    for year, s in CYCLES:
        p = data_dir / f"BIOPRO_{s}.xpt"
        if not p.exists():
            urllib.request.urlretrieve(BASE.format(year=year, file="BIOPRO", s=s), p)
        b = pd.read_sas(p)
        frames.append(b[[c for c in ("SEQN", "LBXSKSI") if c in b.columns]])
    return pd.concat(frames, ignore_index=True)


def main() -> int:
    a = build(fetch(DEFAULT_DATA))

    rule()
    print("1. THE MACULA DENSA ARM: WHAT IS A TEST AND WHAT IS A FIT")
    rule()
    for line in [
        "  HANDOVER section 7 records the gap this closes half of:",
        "",
        "    'THE RENIN CONTROL IS PRESSURE-ONLY AND HUMANS ARE NOT. The rectified form",
        "     caps the PRA ratio it can produce between two pressures at the ratio of",
        "     their drives, whatever the gain. Between MAP 88 and 86 that ceiling is 1.40;",
        "     van den Bosch measures 2.73 across sodium intake in the same subjects. No",
        "     value of the gain reproduces it, and the missing inputs are macula densa",
        "     sodium delivery and renal sympathetic traffic.'",
        "",
        "  ONE OF THE TWO IS NOW BUILT. Renal sympathetic traffic is still absent, so the",
        "  estimated gain absorbs whatever that arm would have contributed - which is the",
        "  same criticism this repository makes of the old pressure gain, made here",
        "  against its own new row.",
        "",
        "  THE GAIN IS ESTIMATED, NOT MEASURED, and ADR 0021's falsifiable test 1 said so",
        "  BEFORE the number existed. No human measurement of renin against distal sodium",
        "  delivery could be found: the searchable literature is hypertension and adrenal",
        "  disease, where the relationship is the diagnostic instrument. Directive 1.7,",
        "  and the pre-registration predicted it as the SIXTH such subsystem.",
        "",
        "  SO van den Bosch 2021 IS AN ESTIMATION SET AND MUST NEVER BE REPORTED AS",
        "  AGREEMENT. Section 3.15 records what happened the last time that was forgotten.",
        "",
        "  WHAT SURVIVES AS A TEST IS THE FORM. Measured in the model itself:",
        "",
        "      g_md = 0      renin ratio 38 vs 230 mmol/day sodium   1.142",
        "      g_md = 2.480                                          2.733",
        "      van den Bosch, n = 70 healthy men                     2.733",
        "",
        "  A ceiling either is or is not exceeded, and no value of the OLD gain exceeds",
        "  it. That the new form CAN is a structural result. That it lands on 2.733 is",
        "  arithmetic, because 2.480 was solved to make it so.",
        "",
        "  ONLY THE RATIO IS COMPARABLE. This model's plasma renin activity is NORMALISED",
        "  to 1.0 at the reference individual, not expressed in ng/mL/h.",
    ]:
        print(line)

    print()
    rule()
    print("2. POTASSIUM: WHAT NHANES GIVES")
    rule()
    d = a.merge(diet(DEFAULT_DATA), on="SEQN", how="inner")
    d = d[(d.RIDAGEYR >= 20) & d.DR1TPOTA.notna() & d.w.gt(0) & (d.RIDEXPRG != 1)]
    if "DR1DRSTZ" in d:
        d = d[d.DR1DRSTZ == 1]
    w = d.w.values
    K = d.DR1TPOTA.values / MW_K
    print("  Dietary potassium, file DR1TOT, reliable recalls only (DR1DRSTZ = 1).")
    print("    n = %d adults 20+   mean %.2f mmol/day   median %.2f   2.5-97.5%% %.1f - %.1f"
          % (len(d), wmean(K, w), wquantile(K, w, .5),
             wquantile(K, w, .025), wquantile(K, w, .975)))
    for g, lab in ((1, "men"), (2, "women")):
        e = d[d.RIAGENDR == g]
        print("      %-6s %.2f mmol/day" % (lab, wmean(e.DR1TPOTA.values / MW_K, e.w.values)))
    print("    the same recall gives sodium %.1f mmol/day, against this model's 205 -"
          % wmean(d.DR1TSODI.values / 22.9898, w))
    print("    A DIETARY RECALL UNDERSTATES INTAKE and the ledger row says so.")

    b = a.merge(biopro(DEFAULT_DATA), on="SEQN", how="inner")
    b = b[(b.RIDAGEYR >= 20) & b.LBXSKSI.notna() & b.w.gt(0) & (b.RIDEXPRG != 1)]
    kp = wmean(b.LBXSKSI.values, b.w.values)
    print()
    print("  Plasma potassium, file BIOPRO, variable LBXSKSI.")
    print("    n = %d   mean %.3f mmol/L   SD %.3f" % (len(b), kp,
          math.sqrt(wmean((b.LBXSKSI.values - kp) ** 2, b.w.values))))
    print("    THIS WAS ALREADY KNOWN WHEN THE PRE-REGISTRATION WAS WRITTEN and section 3")
    print("    of that file says so, because a target seen early is a target that can be")
    print("    reached without noticing.")

    print()
    rule()
    print("3. POTASSIUM: WHAT BRUNNER 1970 GIVES")
    rule()
    print("  J Clin Invest 1970;49(11):2128-38, PMC535788, OPEN ACCESS, read in full.")
    print("  10 NORMAL subjects, constant diet, potassium loaded or depleted with sodium")
    print("  fixed - the controlled-diet balance study in healthy volunteers the")
    print("  pre-registration says to prefer, and almost the only one.")
    print()
    print("  Table I, restricted to dietary sodium >= 100 mEq/day, because the rest were")
    print("  run at 0.5-15 where renin is maximally stimulated and this model does not sit.")
    print()
    print("  %-9s %6s %8s %8s %9s %11s" % ("subject", "Na", "UKV/K_E", "dKp", "aldo E/C",
                                           "dln(aldo)/dKp"))
    fr, ga = [], []
    for n, Na, kc, ke, uc, ue, pc, pe, ac, ae in BRUNNER:
        f = ue / ke
        fr.append(f)
        dk = pe - pc
        g = math.log(ae / ac) / dk if dk > 0.15 else None
        if g is not None:
            ga.append(g)
        print("  %-9s %6.0f %8.3f %8.2f %9.2f %11s"
              % (n, Na, f, dk, ae / ac, "%.3f" % g if g is not None else "excluded"))
    print()
    print("    renal fraction of intake   mean %.3f   range %.3f - %.3f"
          % (sum(fr) / len(fr), min(fr), max(fr)))
    print("    d ln(aldosterone)/d[K]     mean %.3f   range %.3f - %.3f  per mmol/L"
          % (sum(ga) / len(ga), min(ga), max(ga)))
    print()
    for line in [
        "  G.W. IS EXCLUDED FROM THE GAIN because its plasma potassium moved 0.10 mmol/L",
        "  and dividing by that gives 9.6 - an artefact of a small denominator.",
        "",
        "  A FOURFOLD SPREAD, REPORTED AND NOT NARROWED. Potassium loading also causes a",
        "  natriuresis, which moves aldosterone through renin, so none of these six",
        "  isolates the potassium arm. That confounding is intrinsic to the preparation.",
        "",
        "  A RENAL FRACTION ABOVE 1 IS NOT AN ERROR: those subjects were still excreting",
        "  stores laid down earlier. A one-compartment model cannot represent that.",
    ]:
        print(line)

    fek = (sum(fr) / len(fr)) * wmean(K, w) / (152.562 * kp)
    print()
    rule()
    print("4. WHY FE_K IS DERIVED - AND A RETRACTION, 2026-09-05")
    rule()
    for line in [
        "  THIS SECTION PREVIOUSLY SAID RENAL POTASSIUM CLEARANCE IN HEALTHY ADULTS",
        "  COULD NOT BE SOURCED, AND THAT WAS FALSE. It recorded what a handful of",
        "  queries returned - ketoacidosis, chronic kidney disease, diuretics, Gitelman -",
        "  and wrote it up as a fact about the literature. HANDOVER section 5 item 20 is",
        "  that exact failure mode, named after RESP.CO2.PRODUCTION missing a 197-study",
        "  meta-analysis behind a careful note saying the search had failed.",
        "",
        "  WHAT WAS WRONG WAS THE SEARCH TERM, NOT THE LITERATURE. 'Fractional excretion",
        "  of potassium' is a BEDSIDE DIAGNOSTIC phrase - it separates renal from",
        "  extrarenal hypokalaemia - so of course it returns disease. The physiology is",
        "  under 'potassium balance', 'potassium loading' and 'adaptation in normal man',",
        "  and it is the Utrecht group: Koomans, Dorhout Mees, Hene, Boer, Rabelink.",
        "",
        "    Hene RJ, Koomans HA, Boer P, Dorhout Mees EJ. Adaptation to chronic",
        "      potassium loading in normal man. Miner Electrolyte Metab 1986;12(3):165-72.",
        "      PMID 3523191. 6 healthy males, 18 days, 80 -> 300 mEq/day. Urinary",
        "      potassium 50 +/- 12 -> 233 +/- 45 mEq/day; serum potassium 'somewhat",
        "      increased'. ABSTRACT ONLY - not open access, no full text obtained.",
        "    Hene RJ, Koomans HA, Rabelink AJ, Boer P, Dorhout Mees EJ. Mineralocorticoid",
        "      activity and the excretion of an oral potassium load in normal man. Kidney",
        "      Int 1988;34(5):697-703. PMID 3199680. 6 healthy males, fixed Na/K intake.",
        "      'A steep positive relation between plasma K and urine K.' ABSTRACT ONLY.",
        "    Rabelink TJ, Koomans HA, Hene RJ, Dorhout Mees EJ. Early and late adjustment",
        "      to potassium loading in humans. Kidney Int 1990;38(5):942-7. PMID 2266680.",
        "      6 healthy humans, 400 mmol/day for 20 days. Urinary potassium about 80% of",
        "      intake; plasma potassium and aldosterone elevated early, and BOTH RENIN AND",
        "      ALDOSTERONE BACK TO BASELINE BY DAY 20 with kaliuresis maintained.",
        "      ABSTRACT ONLY.",
        "",
        "  THESE ARE READ AT ABSTRACT LEVEL AND ARE LABELLED SO. No value below is changed",
        "  by them, because re-pooling a full-text extraction against three abstracts is",
        "  not a decision this file is entitled to make. What they buy is an independent",
        "  comparison, and two disagreements worth having - section 4b.",
        "",
        "  Branch P4 said not to build a balance whose outflow is invented. THE OUTFLOW'S",
        "  SHAPE IS SOURCED - excretion rises with filtration and with concentration, E1 -",
        "  AND ONLY ITS LEVEL IS NOT. That is a case the pre-registration did not",
        "  anticipate, and its amendment 9 records the branch taken instead.",
        "",
        "  SO PLASMA POTASSIUM IS AN INPUT AND ADR 0021's FALSIFIABLE TEST 2 IS VOID.",
        "",
        "      FE_K = f_renal * K_intake / (GFR * K_plasma)",
        "           = %.3f * %.2f / (152.562 * %.3f)  =  %.4f" % (
            sum(fr) / len(fr), wmean(K, w), kp, fek),
        "",
        "  IT LANDS AT 10 PERCENT, WHERE THE TEXTBOOK PUTS IT, and that is a coincidence",
        "  worth stating rather than a confirmation - the row is DERIVED from the plasma",
        "  potassium it would otherwise predict. It is TEN TIMES the fractional excretion",
        "  of sodium, which is the whole difference between the two ions.",
        "",
        "  FOURTH DEPENDENCY INVERSION IN THIS MODEL, after arterial PCO2 (ADR 0017), the",
        "  thyroid operating point (section 3.26) and plasma bicarbonate (section 3.29).",
        "  The rule, CORRECTED - its old wording claimed the clearance was measured in",
        "  nobody healthy, which is the sentence this section retracts:",
        "",
        "      WHERE A CONCENTRATION IS MEASURED IN THOUSANDS OF PEOPLE AND ITS CLEARANCE",
        "      ONLY IN SIXES, THE CONCENTRATION IS THE INPUT - AND THE SIXES ARE THEN A",
        "      COMPARISON, WHICH IS WHAT THEY ARE USED AS HERE.",
        "",
        "  AND FE_K IS THE WRONG THING TO ARGUE ABOUT ANYWAY, WHICH IS MEASURABLE.",
        "  Sweeping FE_K from 0.04 to 0.16 - wider than any dispersion reported for it -",
        "  moves the model's steady-state plasma potassium only from 4.18 to 3.87 mmol/L,",
        "  every value inside the human reference range. The excretion exponent is what",
        "  pins the concentration. SO FALSIFIABLE TEST 2 WOULD BE A WEAK TEST EVEN IF",
        "  FE_K WERE PERFECTLY SOURCED, and that - not the sourcing - is the honest reason",
        "  plasma potassium is not a strong prediction of this structure.",
        "",
        "  AND THE RETURN ARM IS NOT BUILT EITHER. Aldosterone does not act on potassium",
        "  excretion here, because every human study found moves potassium intake and",
        "  aldosterone together and neither gain separates from the other. Branch P3,",
        "  fired in the direction the pre-registration did not expect.",
    ]:
        print(line)

    print()
    rule()
    print("4b. THE UTRECHT PROTOCOLS RUN AGAINST THE MODEL - TWO DISAGREEMENTS")
    rule()
    for line in [
        "  Out of sample: none of these fixed any parameter here.",
        "",
        "    protocol                       measured               model",
        "    Hene 1986,  80 mEq/day        50 +/- 12 mEq/day      70.7 mEq/day",
        "    Hene 1986, 300 mEq/day       233 +/- 45 mEq/day     265.2 mEq/day",
        "    Rabelink 1990, 400 mmol/d    about 80% of intake    88.4% of intake",
        "",
        "  DISAGREEMENT 1 - THE URINARY FRACTION IS NOT A CONSTANT AND THE MODEL MAKES IT",
        "  ONE. K.RENAL_FRACTION is 0.884 at every intake by construction. Hene measured",
        "  0.63 at 80 mEq/day rising to 0.78 at 300; Rabelink about 0.80 at 400. The",
        "  direction is consistent across both Utrecht studies - the fraction RISES with",
        "  intake - and every one of their values is BELOW the 0.884 taken from Brunner's",
        "  six studies (0.852, 0.974, 0.845, 1.008, 0.945, 0.681). Two good groups",
        "  disagree, so this is NOT averaged here: three of the four numbers are",
        "  abstract-level, and pooling them against a full-text extraction is a decision",
        "  that needs its own pre-registration. RECORDED, NOT SILENTLY SPLIT.",
        "",
        "  DISAGREEMENT 2 - THERE IS NO POTASSIUM ADAPTATION IN THIS MODEL, AND",
        "  ADAPTATION IS WHAT THESE PAPERS ARE ABOUT. Rabelink's title is 'early and late",
        "  adjustment': at 20 days of 400 mmol/day, renin and aldosterone had returned to",
        "  BASELINE while kaliuresis was maintained. This model holds aldosterone at 2.80",
        "  times baseline for ever, because its excretion relation is fixed and its only",
        "  adaptive machinery is aldosterone escape, which acts on the SODIUM side. Hene",
        "  1986 concluded the adaptation is a shift of sodium reabsorption to a distal,",
        "  aldosterone-sensitive site rather than an intrinsic distal change - which is a",
        "  segmental claim ADR 0021's disqualification section says this model may make",
        "  no statement about.",
        "",
        "  SO THE MODEL GETS THE DIRECTION AND ROUGH SIZE OF A CHRONIC POTASSIUM LOAD AND",
        "  GETS THE TIME COURSE OF THE HORMONES WRONG. That is the bounded claim to quote.",
    ]:
        print(line)

    print()
    rule()
    print("5. THE JOIN, AND WHY IT IS CHRONICALLY MUTE")
    rule()
    for line in [
        "  Plasma potassium reaches aldosterone, which is the whole reason ADR 0021 is",
        "  one record and not two. Aldosterone reaches distal sodium reabsorption through",
        "  fr_mod, which the model already had.",
        "",
        "  BUT ADR 0010's ESCAPE DRIVES fr_mod TO ZERO AT EVERY STEADY STATE. So the route",
        "  from potassium to sodium handling is open in the transient and closed in the",
        "  long run: doubling dietary potassium moves aldosterone and moves arterial",
        "  pressure by less than a part in a million. The suite asserts both.",
        "",
        "  THAT IS A FACT ABOUT THE ESCAPE STRUCTURE AND NOT ABOUT POTASSIUM, and it means",
        "  aldosterone in this model is chronically a REPORTER rather than an effector. A",
        "  reader would reasonably assume the opposite from the coupling graph, which is",
        "  why it is asserted rather than left to be noticed.",
    ]:
        print(line)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
