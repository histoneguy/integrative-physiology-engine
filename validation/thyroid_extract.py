#!/usr/bin/env python3
"""
The thyroid axis. BRANCH T3 IS DISCHARGED AND THE OUTCOME IS BRANCH T2.

    python validation/thyroid_extract.py

Pre-registered in validation/thyroid_prereg.md, written before any abstract was
read and sitting before this file in history. Structure in ADR 0019.

    git log --diff-filter=A -- validation/thyroid_prereg.md
    git log --diff-filter=A -- validation/thyroid_extract.py

THIS FILE REPLACES AN EARLIER VERSION THAT STOPPED AT BRANCH T3 - "the feedback
slope cannot be sourced" - because the base of one logarithm was unstated. That
stop was correct on the evidence then in hand. It is now resolved, and NOT by
picking the base that puts the euthyroid point in range, which section 6 of the
pre-registration forbids in terms. It is resolved by a SECOND, INDEPENDENT
MEASUREMENT OF THE SAME SLOPE in which the base is unambiguous.
"""
import math


def rule(c="="):
    print(c * 78)


LN10 = math.log(10.0)
B_BENHADI = 0.059 * LN10    # 0.13585, read as base 10 - see section 1
B_JOSTEL = 0.1345           # stated in natural-log units
# THE ENTERED SLOPE IS THE MEAN OF THE TWO. They differ by 1%, which is a fifth of
# any plausible experimental error on either, so preferring one is a coin toss with
# a justification attached. Directive 1.9.
B_LN = 0.1352
A_LN = 3.454                # 1.50 * ln(10), at the source's three figures
FT4 = 16.60                 # 1.29 ng/100 mL at MW 776.87 -> pmol/L
TSH = math.exp(A_LN - B_LN * FT4)

rule()
print("1. THE AMBIGUITY, AND HOW IT IS RESOLVED WITHOUT TOUCHING THE TARGET")
rule()
for line in [
    "  Benhadi N, Fliers E, Visser TJ, Reitsma JB, Wiersinga WM. Pilot study on the",
    "  assessment of the setpoint of the hypothalamus-pituitary-thyroid axis in healthy",
    "  volunteers. Eur J Endocrinol 2010;162(2):323-9. doi:10.1530/EJE-09-0655.",
    "  PMID 19926783. ABSTRACT ONLY. The publisher's site returns a Cloudflare 525",
    "  origin error and the Erasmus repository record carries metadata but no file;",
    "  Unpaywall's is_oa=true points at that empty record.",
    "",
    "  21 healthy volunteers, 9 male and 12 female, mean age 60, randomised to placebo,",
    "  125 or 250 ug T4, or placebo, 25 or 50 ug T3, at two-week intervals. Admissible",
    "  under thyroid_prereg.md section 2 on every criterion, and it is an INTERVENTION",
    "  rather than a cross-section, which is the design a feedback gain needs.",
    "",
    "      log TSH = 1.50 - 0.059 x FT4        P < 0.05, whole group",
    "",
    "  THE BASE IS NOT STATED. Read as ln, the slope is 0.059 per pmol/L; read as log10",
    "  it is 0.059 x ln(10) = %.4f. A factor of 2.30 in the feedback gain." % B_BENHADI,
    "",
    "  THE SECOND MEASUREMENT. Jostel A, Ryder WDJ, Shalet SM. The use of thyroid",
    "  function tests in the diagnosis of hypopituitarism: definition and evaluation of",
    "  the TSH Index. Clin Endocrinol (Oxf) 2009;71(4):529-34. PMID 19226261.",
    "  doi:10.1111/j.1365-2265.2009.03534.x. ABSTRACT ONLY, not open access.",
    "  9519 thyroid function tests in 4064 patients, Bayer Immuno-1 assay:",
    "",
    "      'Feedback inhibition was estimated to cause a 0.1345 decrease in log TSH",
    "       (mU/l) for 1 pmol/l increase in fT4 concentration'",
    "",
    "  ITS ABSTRACT SAYS 'log' TOO. What settles it is that the index it defines is in",
    "  wide use and the downstream literature states the base explicitly and computes",
    "  with it. Read in full, open access:",
    "",
    "    Wang Y, Yang W, Zhao Y, et al. Sensitivity to Thyroid Hormones and Risk of",
    "    Prediabetes: A Cross-Sectional Study. Front Endocrinol (Lausanne)",
    "    2021;12:657114. PMC8129566. n = 4378 health-checkup participants. Methods:",
    "    'TSH index, TSHI = ln TSH (mIU/L) + 0.1345 * FT4 (pmol/L)', citing Jostel.",
    "",
    "  AND ITS OWN TABLE 1 CHECKS THE ARITHMETIC, which is why this is not just one",
    "  paper's typography. FT4 13.33 pmol/L, TSH median 1.64 mIU/L, TSHI 2.25 +/- 0.76:",
]:
    print(line)

print()
print("      ln  reading:  ln(1.64) + 0.1345*13.33 = %.3f   against a reported 2.25"
      % (math.log(1.64) + 0.1345 * 13.33))
print("      log10 reading: log10(1.64) + 0.1345*13.33 = %.3f   against a reported 2.25"
      % (math.log10(1.64) + 0.1345 * 13.33))
print()
for line in [
    "  So Jostel's coefficient is 0.1345 per pmol/L IN NATURAL-LOG UNITS.",
    "",
    "  THE TWO STUDIES THEN AGREE TO 1%, AND ONLY UNDER ONE PAIRING.",
    "",
    "      Benhadi as log10 -> %.4f      Jostel as ln -> 0.1345      ratio %.4f" % (B_BENHADI, B_BENHADI / B_JOSTEL),
    "      Benhadi as ln    -> 0.0590      Jostel as ln -> 0.1345      ratio 0.44",
    "",
    "  A 2.3-fold disagreement between two competent measurements of the same",
    "  physiological gain, in cohorts whose FT4 ranges are comparable, is not credible.",
    "  A 1% agreement across different countries, decades, assays and designs is. The",
    "  Benhadi logarithm is base 10.",
    "",
    "  AND THE ENTERED VALUE IS THEIR MEAN, %.4f, NOT EITHER ONE." % B_LN,
    "  An earlier version of this file entered Benhadi's alone and called Jostel's",
    "  'corroboration, not the value', on the grounds that pooling.md bars pooling",
    "  across assays. THE TWO NUMBERS AGREE TO 1%. That rule exists to stop a real",
    "  method difference being averaged away, not to force a choice between",
    "  measurements that agree to a fifth of anyone's error bar - and making that",
    "  choice looks like rigour while being arbitrary. Directive 1.9 and HANDOVER",
    "  section 3.23 both already said so.",
    "",
    "  UNWEIGHTED, because neither reports a standard error and no weighting can move",
    "  a 1% interval anywhere that matters.",
    "",
    "  WHY THIS IS NOT THE FORBIDDEN MOVE. Section 6: 'It may not use either reference",
    "  interval to set a parameter.' Nothing here touches a reference interval. The",
    "  resolution is agreement with an independent measurement of the SAME QUANTITY,",
    "  and it selects the reading that the earlier version of this file noted puts the",
    "  euthyroid point HIGHER, not the flattering one. The test got harder, not easier.",
]:
    print(line)

print()
rule()
print("2. THE REST OF THE AXIS")
rule()
for line in [
    "  THE EUTHYROID FREE THYROXINE, AND IT IS NOT A REFERENCE INTERVAL.",
    "  Braverman LE, Vagenakis A, Downs P, Foster AE, Sterling K, Ingbar SH. Effects of",
    "  replacement doses of sodium L-thyroxine on the peripheral metabolism of thyroxine",
    "  and triiodothyronine in man. J Clin Invest 1973;52(5):1010-7. doi:10.1172/",
    "  JCI107265. PMC302354. OPEN ACCESS, READ IN FULL from the JCI archive.",
    "",
    "    11 euthyroid subjects, control (pre-treatment) values, Table I:",
    "      serum total T4  7.3 +/- 1.0 ug/100 mL",
    "      per cent free T4  0.018 +/- 0.001 %   BY EQUILIBRIUM DIALYSIS",
    "      absolute FT4    1.29 +/- 0.19 ng/100 mL  =  %.2f pmol/L" % FT4,
    "",
    "    Section 2 of the pre-registration says to prefer equilibrium dialysis or a",
    "    source that states its method. This is a measured concentration in normal",
    "    subjects by the preferred method, not a percentile of a laboratory population,",
    "    so using it does not spend the target.",
    "",
    "    CORROBORATED ACROSS 49 YEARS AND A COMPLETELY DIFFERENT METHOD. Maushart 2022",
    "    below reports FT4 15.0 +/- 3.9 pmol/L in its euthyroid visit and 16.6 +/- 3.7",
    "    at three months, by modern immunoassay. That is the assay-commensurability",
    "    worry in section 2 discharged empirically rather than argued away.",
    "",
    "  THE TIME CONSTANT, from the same paper, same subjects, control periods:",
    "      fractional turnover of T4  K = 9.7 +/- 0.8 %/day   (n = 5)",
    "      -> tau = 1/K = %.3f days, half-life %.2f days" % (1 / 0.097, math.log(2) / 0.097),
    "      T4 distribution space 8.7 +/- 0.8 L, clearance 0.84 +/- 0.09 L/day,",
    "      disposal 64.2 +/- 9.6 ug/day. Reported for context; the model needs only K.",
    "",
    "  THE METABOLIC ARM. Maushart CI, Senn JR, Loeliger RC, et al. Resting Energy",
    "  Expenditure and Cold-induced Thermogenesis in Patients With Overt",
    "  Hyperthyroidism. J Clin Endocrinol Metab 2022;107(2):450-461. PMC8764338.",
    "  doi:10.1210/clinem/dgab706. OPEN ACCESS, READ IN FULL.",
    "",
    "    18 patients, each measured hyperthyroid, then euthyroid, then euthyroid again",
    "    at 3 months. REE by indirect calorimetry, normalised to lean body mass because",
    "    lean mass itself changed (40.8 -> 43.7 kg):",
    "",
    "      hyperthyroid   fT4 36.3 +/- 18.1 pmol/L   REE 42 +/- 6.7 kcal/24h/kg LBM",
    "      euthyroid      fT4 15.0 +/-  3.9          REE 33 +/- 4.4",
    "      3 mo euthyroid fT4 16.6 +/-  3.7          REE 33 +/- 5.2",
    "",
    "      gain = (dREE/REE) / (dFT4/FT4) = %.3f  against the euthyroid visit" % (((42 - 33) / 33) / ((36.3 - 15.0) / 15.0)),
    "                                    = %.3f  against the 3-month visit" % (((42 - 33) / 33) / ((36.3 - 16.6) / 16.6)),
    "",
    "      ENTERED: the mean, 0.211. Two estimates of one quantity from one cohort,",
    "      differing by 20%, with no reason to prefer either. An earlier version",
    "      entered the lower, which is picking the cautious-looking number rather",
    "      than the central one - a bias, not a caution.",
    "",
    "    AND THE LINK TO CO2 IS TESTED IN THE SAME PAPER, NOT ASSUMED: 'RQ was not",
    "    significantly affected by thyroid hormone state (P = .19)'. At fixed",
    "    respiratory quotient a fractional change in energy expenditure is the same",
    "    fractional change in CO2 production, which is the only thing the respiratory",
    "    component consumes.",
    "",
    "    THIS SOURCE VIOLATES A PRE-REGISTERED EXCLUSION AND THAT IS WHY THE ARM STAYS",
    "    OFF BY DEFAULT. Section 2 excludes thyroid disease of any kind. It has to be",
    "    relaxed here or the gain cannot be measured at all - a healthy person cannot",
    "    ethically be made thyrotoxic, which is the same argument SOURCES.md makes for",
    "    animal preparations. The relaxation is recorded as amendment 8.3 of the",
    "    pre-registration rather than taken silently, and ADR 0019 decision 4 already",
    "    defaults this arm OFF.",
]:
    print(line)

print()
rule()
print("3. WHAT THE LOOP THEN PREDICTS, WITH NOTHING SET TO PRODUCE IT")
rule()
print("  pituitary limb   ln TSH = %.3f - %.4f x FT4       Benhadi + Jostel" % (A_LN, B_LN))
print("  euthyroid FT4    %.2f pmol/L                        Braverman 1973" % FT4)
print("  -> euthyroid TSH %.2f mIU/L" % TSH)
print()
for line in [
    "  ADR 0019 falsifiable test 2 asks whether the euthyroid point lands inside human",
    "  reference intervals for both hormones with neither entered as a target.",
    "",
    "    FT4 %.1f pmol/L sits mid-range on any adult interval (typically 10-22)." % FT4,
    "    TSH %.1f mIU/L is inside the conventional 0.4-4.0 - but only just, and 0.4-4.0" % TSH,
    "    is itself a round teaching number that directive 1.12 says not to trust.",
    "",
    "  AGAINST MEASURED POPULATIONS IT IS TOO HIGH, AND THAT IS THE HONEST READING.",
    "  Hollowell JG, Staehling NW, Flanders WD, et al. Serum TSH, T4, and thyroid",
    "  antibodies in the United States population (1988 to 1994): NHANES III. J Clin",
    "  Endocrinol Metab 2002;87(2):489-99. PMID 11836274. ABSTRACT ONLY. Reference",
    "  population n = 13,344: GEOMETRIC MEAN TSH 1.40 +/- 0.02 mIU/L. Maushart's",
    "  euthyroid visits give 1.98 +/- 1.9 and 1.75 +/- 1.3.",
    "",
    "      the model is %.2fx the NHANES III geometric mean." % (TSH / 1.40),
    "",
    "  SO THIS IS BRANCH T2: report it, do not tune, decompose. The decomposition is",
    "  unambiguous because the three inputs are separately corroborated:",
    "",
    "    the SLOPE is confirmed by a second study to 1%,",
    "    the FT4 LEVEL is confirmed by a second study using a different method,",
    "    the INTERCEPT is confirmed by nothing. It is the only unreplicated number and",
    "    it carries the entire discrepancy.",
    "",
    "  AND THAT LAST CLAIM IS ARITHMETIC, NOT RHETORIC. Sweeping the slope across its",
    "  whole two-source spread moves the prediction by 2%:",
    "",
    "      b = 0.1345 -> TSH %.2f      b = 0.13585 -> TSH %.2f" % (
        math.exp(A_LN - B_JOSTEL * FT4), math.exp(A_LN - B_BENHADI * FT4)),
    "",
    "  against a discrepancy of 2.4x. No plausible slope error reaches that. The",
    "  intercept can, because slope and intercept in a regression over a narrow range",
    "  are strongly anti-correlated and the intercept is the extrapolated one - and",
    "  BENHADI'S ABSTRACT REPORTS NO STANDARD ERROR FOR IT, so its variance cannot be",
    "  propagated. The honest statement is that this coefficient is not determined to",
    "  better than about a factor of two by the study that reports it.",
    "",
    "  RECONSTRUCTING THE INTERCEPT from independent euthyroid pairs, using the agreed",
    "  slope, shows exactly how much:",
]:
    print(line)

print()
for tag, (T, F) in {
    "Benhadi 2010, as entered": (None, None),
    "Maushart euthyroid visit  (TSH 1.98, FT4 15.0)": (1.98, 15.0),
    "Maushart 3-month visit    (TSH 1.75, FT4 16.6)": (1.75, 16.6),
    "NHANES III gm TSH at Braverman FT4": (1.40, FT4),
}.items():
    if T is None:
        print("    %-46s a = %.3f" % (tag, A_LN))
    else:
        print("    %-46s a = %.3f" % (tag, math.log(T) + B_LN * F))

print()
for line in [
    "  Benhadi's intercept is 0.6-0.9 natural-log units above every reconstruction,",
    "  i.e. a factor of 1.9-2.4 in TSH, and the slope is not the problem.",
    "",
    "  WHY IT WOULD BE HIGH, AND THIS IS THE THIRD TIME THIS REPO HAS SEEN IT. An",
    "  intercept is the line EXTRAPOLATED TO FT4 = 0 from data that never went near",
    "  zero - Benhadi's FT4 range is a euthyroid baseline plus a T4 load. The same",
    "  extrapolation produced the ADR 0017 amendment, where a chemoreflex line",
    "  extrapolated below its measured range put ventilation at 19.3 L/min against a",
    "  real 6.2, and it produced HANDOVER section 3.22's censoring bound. Benhadi's",
    "  cohort is also mean age 60, and NHANES III reports TSH rising with age.",
    "",
    "  IT IS NOT REPLACED. Fitting the intercept to any of the reconstructions above",
    "  would set a parameter from the quantity the test judges, which is section 6 and",
    "  is what HANDOVER section 3.15 records happening to the Lobo endpoints. The",
    "  ledger row carries the discrepancy and the model reports a euthyroid TSH that is",
    "  high by a factor of 2.4. Nothing downstream consumes TSH.",
]:
    print(line)

print()
rule()
print("4. WHAT IS BUILT, AND ONE PRE-REGISTERED FALLBACK TAKEN")
rule()
G_T = FT4 / TSH
for line in [
    "  ONE STATE, NOT TWO. ADR 0019 decision 3 planned a two-state loop. Section 4 of",
    "  the pre-registration wrote the fallback in advance: 'If the fast state makes the",
    "  system stiff enough to slow the suite materially, the thyrotropin limb is made",
    "  algebraic and the reason recorded.' Thyrotropin turns over in minutes against a",
    "  thyroxine time constant of ten days and a model horizon of four hundred, so the",
    "  limb is algebraic. The reason is directive 1.10 and it is taken BEFORE paying the",
    "  cost, not after measuring it - a state whose relaxation is four orders of",
    "  magnitude faster than anything the model integrates cannot repay itself.",
    "",
    "      TSH   = exp(a - b*FT4)                          algebraic",
    "      dFT4  = (G_T*sec_cap*TSH - FT4)/tau             one state",
    "",
    "  G_T IS DERIVED, %.3f pmol/L per mIU/L, and it is the ONLY derived number in the" % G_T,
    "  loop: it places the equilibrium at the sourced FT4 and the predicted TSH. It is",
    "  not free - both coordinates it is solved against come from outside.",
    "",
    "  THE OPEN-LOOP GAIN FALLS OUT AND IS ITSELF A RESULT. b*FT4 = %.3f, so" % (B_LN * FT4),
    "  d ln FT4 / d ln(secretion capacity) = 1/(1 + b*FT4) = %.3f. The human axis" % (1 / (1 + B_LN * FT4)),
    "  absorbs about 70% of a change in thyroid secretory capacity. Nothing was fitted",
    "  to produce that number and nothing in this repo was fitted to it.",
    "",
    "  THE METABOLIC ARM IS BUILT AND DEFAULTS OFF, per ADR 0019 decision 4. With it",
    "  off the multiplier is exactly 1.0 and every existing result is unchanged, which",
    "  section 6 requires. RESP.CO2.PRODUCTION stops being a primitive only when it is",
    "  switched on, and the switch is the owner's to throw.",
]:
    print(line)
print()
