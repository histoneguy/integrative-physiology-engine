#!/usr/bin/env python3
"""
Derive the validation/challenges.jl comparison bands from the dispersion the
sources actually report.

    python validation/challenge_bands_extract.py

Pre-registered in validation/challenge_bands_prereg.md, written before any source
was opened for this question and sitting before this file in history:

    git log --diff-filter=A -- validation/challenge_bands_prereg.md
    git log --diff-filter=A -- validation/challenge_bands_extract.py

WHAT PROVOKED IT. The Lobo comparisons used "+/- 33%", a round number appearing in
no paper with no derivation recorded anywhere in this repository, while RN.ANP.TAU
had been estimated against that same dataset to about 0.5 percent agreement. One
repository, one dataset, two tolerances differing roughly sixtyfold.

THE HEADLINE RESULT IS NOT THE ONE EXPECTED. Branch F - a derived band turning a
passing check red - did NOT fire. Where dispersion could be derived, the derived
band is WIDER than the hand-set one in three cases out of four. The model has been
passing a STRICTER test than anybody had justified, and the harness was claiming a
precision its sources do not support in the opposite direction from the worry that
started this. Nothing here makes the model look better: every model value sits
inside both the old band and the new one.
"""
from __future__ import annotations

import csv
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def rule(c="="):
    print(c * 78)


def band_i(mean, sd):
    """Band I - is the model a plausible MEMBER of that population? Gates."""
    return (mean - 2 * sd, mean + 2 * sd)


def band_m(mean, sd, n):
    """Band M - does the model predict the population CENTRAL VALUE? Recorded only."""
    sem = sd / math.sqrt(n)
    return (mean - 2 * sem, mean + 2 * sem)


def ledger(param_id):
    rows = list(csv.DictReader((ROOT / "ledger" / "parameters.csv").open(encoding="utf-8")))
    hit = [r for r in rows if r["param_id"] == param_id]
    if not hit:
        raise SystemExit("no ledger row %s" % param_id)
    return hit[0]


rule()
print("1. LOBO 2001 - BRANCH N ON ALL FOUR ENDPOINTS. NO DISPERSION IS OBTAINABLE.")
rule()
for line in [
    "  Lobo DN, Stanga Z, Simpson JA, Anderson JA, Rowlands BJ, Allison SP. Clin Sci",
    "  (Lond) 2001;101(2):173-9. PMID 11473492. doi:10.1042/CS20000316.",
    "",
    "  WHAT WAS OPENED, STATED EXACTLY, per directive 1.5. The PubMed ABSTRACT, via the",
    "  E-utilities API. NOT the full text. The abstract gives the endpoints this harness",
    "  compares against as BARE MEANS with no dispersion of any kind:",
    "",
    "      'Subjects voided more urine (means 1663 and 563 ml respectively) of lower",
    "       osmolality (means 129 and 630 mOsm/kg respectively) and sodium content",
    "       (means 26 and 95 mmol respectively) after dextrose than after saline'",
    "",
    "  n = 10 male volunteers, double-blind crossover, 2 L of 0.9% saline over 1 h.",
    "",
    "  WHY THE FULL TEXT WAS NOT USED: it is not available. elink pubmed_pmc returns NO",
    "  PMC record. Europe PMC reports isOpenAccess=N, inEPMC=N, inPMC=N, hasPDF=N, and",
    "  every fullTextUrl carries availability 'Subscription required' (Portland Press).",
    "  Reading dispersion off a figure is prohibited by the pre-registration section 4.",
    "",
    "  DISPOSITION - branch N. The four bands KEEP their current numeric values and are",
    "  RELABELLED as assumed in the harness output, with this absence stated there. They",
    "  are not widened and not narrowed: an undocumented band that is also moved is worse",
    "  than one left alone.",
    "",
    "  AND THIS IS THE FINDING THAT MATTERS FOR LOBO. The model's acute agreement with",
    "  Lobo has never been judged against anything derived, in either direction - and",
    "  RN.ANP.TAU was fitted to these same numbers to 0.5 percent. A fit residual quoted",
    "  to four figures against a target whose dispersion is unobtainable is the precision",
    "  that does not exist, which directive 1.9 says cost a third of one session already.",
]:
    print(line)

print()
rule()
print("2. JENSEN 2013 - THE RATIO IS BRANCH N, AND THE REASON IS NOT ABSENCE OF DATA")
rule()
FE_BASE, FE_BASE_SD = 1.26, 0.53
FE_PEAK, FE_PEAK_SD = 2.80, 0.75
N_JENSEN = 23
for line in [
    "  Jensen JM, Mose FH, Bech JN, Nielsen S, Pedersen EB. BMC Nephrol 2013;14:202.",
    "  PMID 24067081. PMC3849534. OPEN ACCESS - full text and tables were read.",
    "",
    "  Statistics section: 'Parametric data are presented as means +/- standard deviation",
    "  (SD)'. Table 3 footnote: 'Values are means with SD in brackets.' So the brackets",
    "  are SD and not SEM, checked rather than assumed.",
    "",
    "  Table 3, FE Na, 0.9% NaCl arm, n = 23 (9 male, 14 female):",
    "      baseline 0-90 min      %.2f (SD %.2f)" % (FE_BASE, FE_BASE_SD),
    "      post-infusion 210-240  %.2f (SD %.2f)" % (FE_PEAK, FE_PEAK_SD),
    "      ratio %.4f, i.e. +%.1f%% - which reproduces the abstract's '123%%'." % (
        FE_PEAK / FE_BASE, (FE_PEAK / FE_BASE - 1) * 100),
]:
    print(line)

# independence bound on the ratio - COMPUTED TO BE REJECTED AS A BAND
rel = math.sqrt((FE_BASE_SD / FE_BASE) ** 2 + (FE_PEAK_SD / FE_PEAK) ** 2)
lo_r = (FE_PEAK / FE_BASE) * math.exp(-2 * rel)
hi_r = (FE_PEAK / FE_BASE) * math.exp(+2 * rel)
print()
for line in [
    "  THE RATIO'S DISPERSION IS NOT DERIVABLE, AND THAT IS A PROPERTY OF THE REPORTING.",
    "  Baseline and peak are measured IN THE SAME SUBJECTS, so the variance of their",
    "  ratio needs their correlation, and the paper reports per-period SDs rather than",
    "  paired differences or a covariance. This is the identical obstacle recorded on",
    "  RN.GFR.VOLUME_SENSITIVITY, whose own pre-registration fixed in advance that an",
    "  interval must NOT be fabricated by propagating per-arm SDs as if independent.",
    "  That prohibition is honoured here rather than re-argued.",
    "",
    "  THE INDEPENDENCE BOUND, COMPUTED ONLY TO BE REJECTED AS A BAND:",
    "      relative SD of log-ratio, assuming rho = 0:  %.4f" % rel,
    "      implied 2-SD interval on the rise:           %+.0f%% to %+.0f%%" % (
        (lo_r - 1) * 100, (hi_r - 1) * 100),
    "      the harness's existing hand-set band:         +60% to +250%",
    "",
    "  READ THAT CAREFULLY, BECAUSE IT INVERTS THE EXPECTATION THIS PASS STARTED FROM.",
    "  rho = 0 OVERSTATES the ratio's SD, because positive within-subject correlation",
    "  shrinks it - so that interval is an UPPER BOUND on the spread. The existing band",
    "  is far NARROWER than even that upper bound. The Jensen band was never too",
    "  generous; if anything it is tighter than the reported statistics can justify.",
    "",
    "  DISPOSITION - branch N. Band unchanged, relabelled assumed, with the reason.",
]:
    print(line)

print()
rule()
print("3. WHY THE ABSOLUTE FE Na COMPARISON WAS NOT SUBSTITUTED, THOUGH IT HAS AN SD")
rule()
for line in [
    "  It is tempting: Table 3 gives mean and SD for the absolute FE Na, so a band would",
    "  be derivable where the ratio's is not. It is NOT substituted, for a reason that",
    "  is about the protocol and not about convenience.",
    "",
    "  JENSEN'S SUBJECTS WERE NOT ON THIS MODEL'S SODIUM INTAKE. Table 1 gives baseline",
    "  u-Na 124 (SD 52) mmol/24 h. The model's operating point is 205 mEq/day. Fractional",
    "  sodium excretion is intake over filtered load, so it moves with intake directly -",
    "  comparing the two absolutes compares two different diets.",
    "",
    "      model FE Na at 205 mEq/day                  0.958%",
    "      model FE Na rescaled to 124 mmol/day        %.3f%%" % (0.958 * 124 / 205),
    "      Jensen Table 1, 24 h baseline               0.49 (SD 0.15)",
    "      Jensen Table 3, clearance-day baseline      1.26 (SD 0.53)",
    "",
    "  AND JENSEN'S OWN TWO BASELINES DIFFER BY 2.6-FOLD - 0.49 over 24 h against 1.26",
    "  during the clearance experiment - because the clearance protocol water-loads the",
    "  subjects. So 'baseline fractional excretion' is not one number even inside this",
    "  one paper, and picking whichever matched the model would be exactly the choice",
    "  the pre-registration exists to forbid.",
    "",
    "  THE RATIO IS THE CORRECT COMPARATOR PRECISELY BECAUSE IT IS INTAKE-NORMALISED,",
    "  and it is the one whose dispersion cannot be derived. That bind is the result",
    "  here. It is recorded rather than resolved by substituting an easier endpoint.",
]:
    print(line)

print()
rule()
print("4. THE RESTING CHECKS - REFERENCE INTERVALS, CITED FROM THE LEDGER (BRANCH R1)")
rule()
print("  Pre-registration section 6: a clinical reference interval is ALREADY a")
print("  population interval, so it maps onto Band I directly and is CITED, not")
print("  recomputed. Band M is not defined for it - there is no study mean and no n.")
print()
print("  %-24s %-22s %-24s %s" % ("check", "ledger row", "derived Band I", "was"))
rows = [
    ("resting MAP", "CV.MAP.SETPOINT", "sd", 1.0, (80.0, 95.0), "mmHg"),
    ("resting ECF volume", "BF.ECF.MASS_FRACTION", "sd", 70.0, (13.0, 17.0), "L"),
    ("resting plasma sodium", "BF.NA.PLASMA_SETPOINT", "range", 1.0, (135.0, 145.0), "mEq/L"),
    ("resting plasma osmolality", "BF.OSM.PLASMA_SETPOINT", "range", 1.0, (280.0, 295.0), "mOsm/kg"),
    ("resting GFR", "RN.GFR.NOMINAL", "sd", 1.0, (130.0, 180.0), "L/day"),
]
derived = {}
for label, pid, kind, scale, old, units in rows:
    r = ledger(pid)
    if kind == "sd":
        mean = float(r["value"]) * scale
        sd = float(r["uncertainty_value"]) * scale
        lo, hi = band_i(mean, sd)
        how = "mean %.4g +/- 2 SD %.4g" % (mean, sd)
    else:
        lo, hi = (float(x) for x in r["uncertainty_value"].split("-"))
        how = "ledger reference interval"
    derived[label] = (lo, hi)
    flag = "WIDER" if (lo < old[0] - 1e-9 or hi > old[1] + 1e-9) else "same/narrower"
    print("  %-24s %-22s [%8.2f,%8.2f] %-6s [%.1f, %.1f]  %s" % (
        label, pid, lo, hi, units, old[0], old[1], flag))
    print("      %s" % how)

print()
for line in [
    "  THREE OF THE FIVE DERIVED BANDS ARE WIDER THAN THE HAND-SET ONES, WHICH IS THE",
    "  OPPOSITE OF WHAT THIS PASS WENT LOOKING FOR. MAP, extracellular volume and GFR",
    "  were all being judged more strictly than their own sourced dispersion supports.",
    "  The model passes either way and no value moves; what changes is that the harness",
    "  now states a tolerance somebody can check.",
    "",
    "  ONE REAL DISAGREEMENT FOUND, AND NO GATE COULD SEE IT. The plasma osmolality",
    "  check used 280-295 while its own ledger row BF.OSM.PLASMA_SETPOINT carries the",
    "  reference interval 275-295. The harness had invented a tighter lower bound than",
    "  the row it is supposed to be testing against. Corrected to the ledger.",
    "",
    "  TWO RESTING CHECKS HAVE NO LEDGER ROW AND NO CITATION - branch R3:",
    "      resting urine volume       0.8-2.5 L/day",
    "      resting urine osmolality   300-900 mOsm/kg",
    "  Both are conventional clinical figures. They keep their values and are relabelled",
    "  assumed. Directive 1.12: a round number is presumptively unsourced, and the",
    "  honest move is to say so rather than to dress it as a reference.",
    "",
    "  'sodium balance closes' at 204.9-205.1 is EXEMPT by pre-registration section 6.",
    "  It compares the model's excretion against the model's own intake. It is an",
    "  internal conservation identity, not a comparison with literature, and it stays",
    "  tight. Its label in the harness now says so.",
]:
    print(line)

print()
rule()
print("5. THE CHRONIC SALT-SENSITIVITY BAND IS DERIVED, AND IT IS NOT AN INTERVAL")
rule()
for line in [
    "  1.70-2.30 mmHg per 100 mmol/day is the SPREAD OF THREE META-ANALYTIC POINT",
    "  ESTIMATES - Cutler 1997 (32 trials, n=2635) 1.70; He/Li/MacGregor 2013 (34,",
    "  n=3230) 1.96; He & MacGregor 2002 (11, n=2220) 2.30 - and NOT a pooled",
    "  confidence interval. Those are different objects and the harness prints it as",
    "  though it were one.",
    "",
    "  IT IS LEFT ALONE, and the reason is pooling.md rather than convenience: pooling",
    "  three meta-analyses that share primary trials is the silent re-pooling that file",
    "  prohibits, and taking their min and max as an interval is range-midpoint's",
    "  sibling. The label is corrected to say what it is - a spread across three",
    "  estimates - so nobody reads it as a confidence interval.",
]:
    print(line)

print()
rule()
print("6. WHAT THIS PASS DID AND DID NOT DO")
rule()
for line in [
    "  BRANCH F DID NOT FIRE. No derived band turns a passing check red. That was the",
    "  branch the pre-registration existed to protect, and it is recorded as not having",
    "  been reached rather than quietly omitted.",
    "",
    "  NO PARAMETER VALUE CHANGED. NO EQUATION CHANGED. Section 8 of the",
    "  pre-registration forbade both and neither was touched.",
    "",
    "  THE REAL RESULT, IN ONE SENTENCE: the two acute datasets that the acute limb",
    "  rests on CANNOT SUPPLY A BAND AT ALL - Lobo because its full text is paywalled",
    "  and its abstract reports bare means, Jensen because the ratio's dispersion needs",
    "  a correlation it does not report - and where a band COULD be derived, from the",
    "  ledger's own resting rows, the derived band is mostly WIDER than the one in use.",
    "",
    "  SO THE WORRY THAT STARTED THIS WAS HALF RIGHT AND HALF BACKWARDS. Quoting",
    "  four-figure agreement against these targets is indefensible and that half stands.",
    "  But the harness was not being too lenient anywhere; it was being arbitrarily",
    "  strict in three places and arbitrarily precise in its reporting everywhere.",
]:
    print(line)
print()
