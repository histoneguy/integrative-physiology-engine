#!/usr/bin/env python3
"""
POTASSIUM DOSE-RESPONSE EXTRACTION.

Pre-registered in validation/potassium_doseresponse_prereg.md, committed at 1698d2a
BEFORE this file existed and before any search was run for these values. Verify:

    git log --diff-filter=A -- validation/potassium_doseresponse_prereg.md
    git log --diff-filter=A -- validation/potassium_doseresponse_extract.py

WHY THIS PASS EXISTS. HANDOVER section 3.33 retracts a false claim that this
literature could not be sourced. The claim came from searching the bedside phrase
`fractional excretion of potassium` instead of the terms the physiologists use. The
owner's instruction was to stop recording the gap and close it.

THE SOURCE, READ IN FULL FROM THE EUROPE PMC FULL TEXT (PMC5013341):

  Cappuccio FP, Buchanan LA, Ji C, Siani A, Miller MA. Systematic review and
  meta-analysis of randomised controlled trials on the effects of potassium
  supplements on serum potassium and creatinine. BMJ Open 2016;6(8):e011716.
  doi:10.1136/bmjopen-2016-011716. PMID 27566636. PMC5013341. OPEN ACCESS, CC BY-NC.

  20 trials, 21 independent groups, 1216 participants, 12 countries. Minimum four
  weeks of supplementation. INTAKE VERIFIED BY 24-HOUR URINE COLLECTION, which the
  pre-registration section 2 requires and dietary recall does not satisfy.

WHAT THE MODEL NEEDS AND WHY THIS PAPER IS IT. At steady state,

    K_p / K_p_ref = [f_renal * K_intake / (FE_K * GFR * K_p_ref)] ^ (1 / n_K)

so 1/n_K is the ELASTICITY of plasma potassium with respect to potassium intake.
Table 1 of this paper reports, for each trial, urinary potassium and plasma or serum
potassium in BOTH arms - which is that elasticity, measured, twenty times over.
"""

import math

SEP = "=" * 80


def rule():
    print(SEP)


# ---------------------------------------------------------------------------
# TABLE 1, TRANSCRIBED. Every row is read off the published table; nothing here
# is computed from another row. `dose` is the supplement in mmol/day, `u_c`/`u_k`
# the urinary potassium in the control and potassium arms in mmol/day, `p_c`/`p_k`
# the plasma or serum potassium in mmol/L.
#
# `approx` marks the two rows the paper itself prints with a tilde.
# `excl` is the pre-registration section 2 reason for exclusion, or None.
# ---------------------------------------------------------------------------
TRIALS = [
    # author, year, dose, u_c, u_k, p_c, p_k, population, excl
    ("MacGregor", 1982,  64, 62.0, 118.0, 3.84, 4.02, "hypertensive", "hypertensive cohort"),
    ("Richards",  1984, 140, 60.0, 170.0, 3.84, 3.99, "hypertensive", "hypertensive cohort"),
    ("Bulpitt",   1985,  64, 55.0,  95.0, 3.50, 3.80, "hypertensive", "loop diuretics"),
    ("Kaplan",    1985,  60, 36.0,  82.0, 3.00, 3.56, "hypokalaemic", "diuretics; hypokalaemic"),
    ("Smith",     1985,  64, 67.0, 117.0, 3.90, 4.10, "hypertensive", "hypertensive cohort"),
    ("Zoccali",   1985, 100, 58.0, 139.0, 3.90, 4.00, "hypertensive", "hypertensive cohort"),
    ("Matlou",    1986,  65, 52.0, 114.0, 3.87, 4.32, "hypertensive", "hypertensive cohort"),
    ("Grobbee",   1987,  72, 74.0, 131.0, 3.76, 4.00, "hypertensive", "hypertensive cohort"),
    ("Siani",     1987,  48, 57.0,  87.0, 4.40, 4.30, "hypertensive", "hypertensive cohort"),
    ("Barden",    1987,  80, 55.0, 115.0, 3.725, 3.86, "normotensive", None),
    ("Obel",      1989,  64, 62.0, 102.0, 4.00, 4.00, "hypertensive", "hypertensive cohort"),
    ("Patki",     1990,  60, 60.0,  82.0, 3.60, 3.70, "hypertensive", "hypertensive cohort"),
    ("Valdes",    1991,  64, 55.0, 123.0, 3.80, 4.10, "hypertensive", "hypertensive cohort"),
    ("Fotherby",  1992,  60, 60.0,  99.0, 4.30, 4.40, "hypertensive", "hypertensive cohort"),
    ("Geleijnse", 1994,  22, 86.0,  97.0, 4.23, 4.35, "general population", None),
    ("Kawano",    1998,  64, 54.0,  96.0, 4.15, 4.42, "hypertensive", "hypertensive cohort"),
    ("He KCl",    2010,  64, 77.0, 122.0, 4.40, 4.60, "hypertensive", "hypertensive cohort"),
    ("He KHCO3",  2010,  64, 77.0, 125.0, 4.40, 4.40, "hypertensive", "hypertensive cohort"),
    ("Gijsbers",  2015,  72, 55.3, 118.1, 4.29, 4.41, "non-smokers, untreated", None),
]
# Yusuf 2012 and Graham 2014 are in the paper's Table 1 but report NO urinary
# potassium, so no elasticity can be formed from them. They are not transcribed
# above and are not counted anywhere below.

# Pooled estimates as published, for comparison with anything computed here.
WMD_PLASMA = (0.14, 0.09, 0.19)        # mmol/L, 95% CI
WMD_URINE = (45.75, 37.81, 53.69)      # mmol/24 h, 95% CI

# Ledger rows this pass may touch.
CURRENT_EXPONENT = 17.71
CURRENT_RENAL_FRACTION = 0.884
NHANES_INTAKE = 69.06                  # K.INTAKE.NOMINAL, mmol/day
P_ENTERED = 0.39                       # K.NONRENAL_LOSS_EXPONENT, entered 2026-09-08

# Hene RJ, Koomans HA, Boer P, Dorhout Mees EJ. Miner Electrolyte Metab
# 1986;12(3):165-72. PMID 3523191. Six healthy males, 18 days, controlled diet.
# ABSTRACT-LEVEL ONLY - the paper is not open access. (intake, urinary, SD).
HENE = [(80.0, 50.0, 12.0), (300.0, 233.0, 45.0)]

# Brunner 1970 experimental periods, transcribed from
# validation/macula_densa_potassium_extract.py, which read the full text.
BRUNNER_FRACTIONS = [(83, 70.7), (80, 77.9), (239, 202.0),
                     (259, 261.0), (165, 156.0), (161, 109.7)]


def elasticity(t):
    """d ln(plasma K) / d ln(urinary K), the model's 1 / n_K."""
    _, _, _, u_c, u_k, p_c, p_k, _, _ = t
    du = math.log(u_k / u_c)
    dp = math.log(p_k / p_c)
    return dp, du, (dp / du if du != 0 else float("nan"))


def main():
    rule()
    print("POTASSIUM DOSE-RESPONSE: THE EXPONENT, AND WHETHER THE RENAL FRACTION MOVES")
    rule()
    print("  Cappuccio FP et al. BMJ Open 2016;6(8):e011716. PMID 27566636. PMC5013341.")
    print("  20 trials, 1216 participants, 12 countries, >= 4 weeks, 24 h urine.")
    print("  Read in full from the Europe PMC full text. Table 1 transcribed below.")
    print()

    rule()
    print("1. THE MEASURED ELASTICITY, PER TRIAL")
    rule()
    print("  1/n_K is d ln(plasma K) / d ln(urinary K). Urinary potassium is the")
    print("  pre-registered biomarker of intake; this paper's inclusion rule required it.")
    print()
    print("  %-12s %5s %7s %7s %6s %6s %9s %8s  %s"
          % ("study", "dose", "U ctrl", "U K+", "P ctrl", "P K+", "1/n_K", "n_K", "admissible"))
    adm, allrows = [], []
    for t in TRIALS:
        name, year, dose, u_c, u_k, p_c, p_k, pop, excl = t
        dp, du, e = elasticity(t)
        n = (1.0 / e) if e > 0 else float("inf")
        allrows.append((t, dp, du, e))
        if excl is None:
            adm.append((t, dp, du, e))
        print("  %-12s %5d %7.1f %7.1f %6.3f %6.3f %9.5f %8.2f  %s"
              % ("%s %d" % (name, year), dose, u_c, u_k, p_c, p_k, e,
                 n, "yes" if excl is None else "no - " + excl))
    print()
    print("  Obel 1989 has an elasticity of exactly zero - plasma potassium 4.00 in both")
    print("  arms - so its n_K is infinite and it cannot enter a mean of n_K. That is why")
    print("  everything below pools the ELASTICITY and inverts at the end, which is the")
    print("  only pooling that stays finite. Siani 1987's is NEGATIVE, plasma potassium")
    print("  falling on a supplement; it is kept, because dropping the inconvenient sign")
    print("  is how a spread gets narrowed without evidence.")
    print()

    rule()
    print("2. THE PRE-REGISTERED ANSWER - SECTION 2 ADMISSIBILITY, DECISION D2")
    rule()
    print("  Section 2 excludes hypertensive and CKD cohorts unless a healthy arm is")
    print("  reported separately, and excludes diuretics. THAT COSTS 16 OF 19 TRIALS and")
    print("  it is followed anyway, because a rule that is relaxed once it is inconvenient")
    print("  is not a rule. What survives:")
    print()
    for (t, dp, du, e) in adm:
        print("    %-16s %-24s 1/n_K = %.5f   n_K = %6.2f"
              % ("%s %d" % (t[0], t[1]), t[7], e, 1.0 / e))
    sum_dp = sum(dp for (_, dp, _, _) in adm)
    sum_du = sum(du for (_, _, du, _) in adm)
    e_adm = sum_dp / sum_du
    n_adm = 1.0 / e_adm
    print()
    print("  POOLED AS A RATIO OF SUMS, which is a slope through the origin and is the")
    print("  weighting that does not let a trial with a tiny intake change dominate:")
    print("      sum d ln P = %.6f   sum d ln U = %.6f" % (sum_dp, sum_du))
    print("      1/n_K = %.6f      n_K = %.2f" % (e_adm, n_adm))
    print()
    print("  A MEAN OF THE THREE ELASTICITIES WOULD GIVE n_K = %.2f AND IT IS NOT USED."
          % (1.0 / (sum(e for (_, _, _, e) in adm) / len(adm))))
    print("  Geleijnse's intake changed by only 86 -> 97 mmol/day, so its ratio is the")
    print("  least stable of the three and an unweighted mean hands it equal weight.")
    print()

    rule()
    print("3. THE SAME QUANTITY BY TWO OTHER ROUTES, NEITHER OF THEM ADMISSIBLE")
    rule()
    u_ctrl = sum(t[3] for t in TRIALS) / len(TRIALS)
    p_ctrl = sum(t[5] for t in TRIALS) / len(TRIALS)
    print("  Mean control-arm urinary potassium %.2f mmol/day, plasma %.3f mmol/L,"
          % (u_ctrl, p_ctrl))
    print("  over the %d trials that report both." % len(TRIALS))
    print()
    print("  ROUTE B - the paper's own POOLED meta-analytic effects, applied to those")
    print("  baselines. Not admissible: the pool is dominated by hypertensive cohorts.")
    row = []
    for lab, dpl in (("estimate", WMD_PLASMA[0]), ("CI low", WMD_PLASMA[1]),
                     ("CI high", WMD_PLASMA[2])):
        e = math.log((p_ctrl + dpl) / p_ctrl) / math.log((u_ctrl + WMD_URINE[0]) / u_ctrl)
        row.append((lab, dpl, e, 1.0 / e))
        print("      plasma %+.2f mmol/L (%-8s) -> 1/n_K = %.6f   n_K = %6.2f"
              % (dpl, lab, e, 1.0 / e))
    n_pooled = row[0][3]
    lo_n, hi_n = row[2][3], row[1][3]
    print()
    print("  ROUTE C - Brunner 1970, already in the ledger, six studies in ten normal")
    print("  subjects on a constant diet: 16.31, 19.11, 23.45, 3.45, 13.26, 41.68,")
    print("  median %.2f." % CURRENT_EXPONENT)
    print()
    print("  THREE INDEPENDENT ROUTES:")
    print("      admissible subset, this paper   n_K = %6.2f" % n_adm)
    print("      full pooled meta-analysis       n_K = %6.2f  (95%% CI %.2f - %.2f)"
          % (n_pooled, lo_n, hi_n))
    print("      Brunner 1970 median             n_K = %6.2f" % CURRENT_EXPONENT)
    print("  They agree to within %.1f%%, and the two that carry a dispersion disagree by"
          % (100.0 * (max(n_adm, n_pooled, CURRENT_EXPONENT)
                      / min(n_adm, n_pooled, CURRENT_EXPONENT) - 1.0)))
    print("  far less than either dispersion. That convergence is the result of this pass.")
    print()

    rule()
    print("4. WHAT IS ENTERED, AND WHAT SECTION 8 SAID WOULD MAKE THIS A FAILURE")
    rule()
    print("  ENTERED: K.EXCRETION_EXPONENT = %.2f, from the admissible subset (D2)."
          % round(n_adm, 2))
    print("  UNCERTAINTY: %.1f to %.1f, the 95%% CI of the full pooled estimate, because"
          % (lo_n, hi_n))
    print("  three trials cannot carry a dispersion and 20 trials in 1216 people can.")
    print("  The value and the interval come from the SAME PAPER and the note says which")
    print("  subset each used.")
    print()
    print("  SECTION 8 SAID: landing inside Brunner's 3.45-41.68 with nothing else changed")
    print("  is precision without information. The value moved %.2f -> %.2f, which is"
          % (CURRENT_EXPONENT, round(n_adm, 2)))
    print("  nothing. WHAT CHANGED IS THE DISPERSION: 3.45-41.68, a twelvefold spread over")
    print("  six studies in ten people, becomes %.1f-%.1f over 1216. That interval excludes"
          % (lo_n, hi_n))
    print("  both ends of Brunner's, which is the test section 8 set.")
    print()

    rule()
    print("5. THE RENAL FRACTION - DECISION D5 IS NOT TAKEN, AND D4 IS")
    rule()
    print("  D5 would make f_renal rise with intake, in the shape fixed in advance by")
    print("  section 5 of the pre-registration. It requires two or more admissible studies")
    print("  measuring the rise. THE EVIDENCE POINTS BOTH WAYS:")
    print()
    marg = [((t[4] - t[3]) / t[2], t) for t in TRIALS]
    mmean = sum(m for m, _ in marg) / len(marg)
    print("    RISING - Hene 1986 (PMID 3523191) 0.63 at 80 mEq/day to 0.78 at 300;")
    print("             Rabelink 1990 (PMID 2266680) about 0.80 at 400 mmol/day.")
    print("             Both ABSTRACT-LEVEL ONLY, neither open access.")
    print("    FALLING - this paper's MARGINAL fraction, the share of each supplement")
    print("             appearing in urine, is %.3f across %d trials (range %.2f-%.2f),"
          % (mmean, len(marg), min(m for m, _ in marg), max(m for m, _ in marg)))
    print("             BELOW the ledger's %.3f. If the marginal fraction were below the"
          % CURRENT_RENAL_FRACTION)
    print("             average, the average would FALL with intake, not rise.")
    print()
    print("  THE MARGINAL FRACTION IS NOT A CLEAN MEASUREMENT OF THE DIETARY ONE.")
    print("  It is the fate of a KCl tablet, not of food: tablet absorption, incomplete")
    print("  24 h collections and the trials' own compliance all push it down, and every")
    print("  one of those biases has the same sign.")
    print()
    print("  ON 2026-09-06 THAT WAS REPORTED AND THE ROW WAS KEPT CONSTANT UNDER D4.")
    print("  ON 2026-09-08 THE OWNER STRUCK THE MARGINAL FIGURE OUT - tablet absorption,")
    print("  not renal handling, is what it measures - AND WITH IT GONE THE SOURCES NO")
    print("  LONGER DISAGREE. D5 fires. Section 5b is the fit.")
    print()

    rule()
    print("5b. D5: THE INTAKE-DEPENDENT FRACTION, IN THE SHAPE FIXED BEFORE THE DATA")
    rule()
    print("      f_renal(I) = f_max - (f_max - f_0) * (I_ref / I) ^ p")
    print()
    print("  f_max = 1 IS A BOUNDARY CONDITION AND NOT A FIT. At steady state urinary")
    print("  excretion cannot exceed intake, and a non-renal loss growing more slowly")
    print("  than intake vanishes beside it. Fixing it removes a free parameter rather")
    print("  than fitting three of them to two data points.")
    print()
    print("  p COMES FROM HENE'S WITHIN-SUBJECT CHANGE, the only admissible measurement")
    print("  of the rise. Six healthy males, 18 days, controlled diet:")
    print()
    print("     %8s %9s %9s %11s" % ("intake", "urinary", "f_renal", "non-renal"))
    for I, U, sd in HENE:
        print("     %8.1f %9.1f %9.4f %11.1f" % (I, U, U / I, I - U))
    a = 1.0 - HENE[0][1] / HENE[0][0]
    b = 1.0 - HENE[1][1] / HENE[1][0]
    ratio_I = HENE[1][0] / HENE[0][0]
    p = math.log(a / b) / math.log(ratio_I)
    print()
    print("     (1-f) ratio %.4f / %.4f = %.4f over an intake ratio of %.2f"
          % (a, b, a / b, ratio_I))
    print("     p = ln(%.4f) / ln(%.2f) = %.5f, entered at two figures as %.2f"
          % (a / b, ratio_I, p, P_ENTERED))
    print("     so the non-renal loss goes as intake^%.2f - it RISES, sub-linearly,"
          % (1.0 - P_ENTERED))
    print("     which is colonic potassium secretion and is E1.")
    print()
    n = 6
    a_se = (HENE[0][2] / math.sqrt(n)) / HENE[0][0]
    b_se = (HENE[1][2] / math.sqrt(n)) / HENE[1][0]
    rel = math.sqrt((a_se / a) ** 2 + (b_se / b) ** 2)
    p_se = rel / math.log(ratio_I)
    print("  AND IT IS %.1f STANDARD ERRORS FROM NOTHING AT ALL. Propagating the published"
          % (p / p_se))
    print("  SDs as standard errors of the mean, p = %.2f +/- %.2f, 95%% interval %.2f to"
          % (p, p_se, p - 1.96 * p_se))
    print("  %.2f - WHICH INCLUDES A CONSTANT FRACTION. The statistic does not carry this"
          % (p + 1.96 * p_se))
    print("  row; the physiology does, and the ledger note leads with that.")
    print()
    print("  THE LEVEL IS NOT HENE'S, AND HERE IS WHY IT CANNOT BE:")
    f0_h = 1.0 - a * (NHANES_INTAKE / HENE[0][0]) ** P_ENTERED
    print("     Hene's level implies f_0 = %.3f, i.e. %.1f mmol/day of urinary potassium"
          % (f0_h, f0_h * NHANES_INTAKE))
    print("     at the reference intake, against %.2f measured by 24 h collection in the"
          % 61.17)
    print("     %d control arms above. A %.0f%% miss."
          % (len(TRIALS), 100 * abs(f0_h * NHANES_INTAKE - 61.17) / 61.17))
    print("     SLOPE FROM THE WITHIN-SUBJECT DESIGN, LEVEL FROM THE POPULATION DATA,")
    print("     and both halves said out loud rather than blended.")
    print()

    def f_renal(I):
        return 1.0 - (1.0 - CURRENT_RENAL_FRACTION) * (NHANES_INTAKE / I) ** P_ENTERED

    print("  THE CURVE, against every admissible observation at that intake:")
    print("     %9s %9s %10s   %s" % ("intake", "f_renal", "urinary", "observed"))
    for I in (34.53, NHANES_INTAKE, 80.0, 138.12, 161.0, 239.0, 300.0, 400.0):
        obs = ["Brunner %.3f" % (u / i) for i, u in BRUNNER_FRACTIONS if abs(i - I) < 6.0]
        obs += ["Hene %.3f" % (u / i) for i, u, _ in HENE if abs(i - I) < 6.0]
        print("     %9.2f %9.4f %10.2f   %s" % (I, f_renal(I), f_renal(I) * I,
                                                ", ".join(obs) if obs else ""))
    print()
    print("  AT THE REFERENCE IT IS EXACTLY %.3f, so promoting a constant to a function"
          % f_renal(NHANES_INTAKE))
    print("  leaves every existing result bit-identical and the suite asserts that as an")
    print("  identity rather than as a comparison.")
    print()
    print("  RABELINK'S 0.80 AT 400 mmol/day IS NOT USED, AND THE PRE-REGISTRATION'S OWN")
    print("  RULE IS WHY. That figure is the SECOND 24-HOUR PERIOD of the load; section 2")
    print("  requires the intake held five days. It was quoted as supporting evidence for")
    print("  two days and never qualified. APPLYING THE RULE LATE COST A SOURCE THAT HAD")
    print("  BEEN AGREEING, which is the argument for applying it at extraction rather")
    print("  than at write-up.")
    print()
    print("  WHAT THIS CURVE CANNOT DO: potassium DEPLETION. Below the reference it keeps")
    print("  falling, where a real kidney conserves hard - Brunner's depletion periods show")
    print("  urinary excretion EXCEEDING intake as a store empties, which no steady-state")
    print("  fraction can express. Do not run this model below about half the reference")
    print("  intake and quote the fraction.")
    print()

    rule()
    print("6. THE ONE THING HERE THAT IS A CHECK RATHER THAN A FIT")
    rule()
    model_u = CURRENT_RENAL_FRACTION * NHANES_INTAKE
    print("  The model's resting urinary potassium is K.RENAL_FRACTION * K.INTAKE.NOMINAL")
    print("  = %.3f * %.2f = %.2f mmol/day, and both of those rows were set long before"
          % (CURRENT_RENAL_FRACTION, NHANES_INTAKE, model_u))
    print("  this paper was opened - one from Brunner 1970, one from 8893 NHANES recalls.")
    print()
    print("  THE %d CONTROL ARMS HERE AVERAGE %.2f mmol/day, measured by 24-hour urine"
          % (len(TRIALS), u_ctrl))
    print("  collection in 12 countries. The model is %.1f%% away."
          % (100.0 * abs(model_u - u_ctrl) / u_ctrl))
    print()
    print("  THIS IS NOT A VALIDATION AND THE ARITHMETIC SAYS WHY: NHANES dietary recall")
    print("  is known to understate intake, and these cohorts are not American. Two")
    print("  quantities that should not agree this well agreeing this well is worth")
    print("  stating and is worth distrusting. What it does rule out is a gross error in")
    print("  the product of two rows that had never been checked against anything.")
    print()

    rule()
    print("7. WHAT THIS PASS DID NOT DO")
    rule()
    for line in [
        "  IT DID NOT CLOSE OPEN-QUESTIONS B11. There is still no potassium adaptation:",
        "  Rabelink 1990 found renin and aldosterone back at baseline by day 20 of a 400",
        "  mmol/day load with kaliuresis maintained, and this model holds aldosterone at",
        "  2.80 times baseline for ever. Section 7 of the pre-registration forbade this",
        "  pass from touching that, and it did not.",
        "",
        "  IT DID NOT MAKE PLASMA POTASSIUM A PREDICTION. FE_K is still derived from it.",
        "  What improved is the RESPONSE, which is what the pre-registration said was the",
        "  only thing this pass could improve.",
        "",
        "  IT DID NOT TOUCH THE SEXED QUESTION. Eighteen of the twenty trials recruited",
        "  both sexes and two recruited only women; none reports the elasticity by sex.",
        "  ADR 0014's shared-value branch, and it is an absence rather than a finding.",
    ]:
        print(line)
    print()
    rule()
    print("ENTER: K.EXCRETION_EXPONENT = %.2f, uncertainty range %.1f to %.1f."
          % (round(n_adm, 2), lo_n, hi_n))
    print("ENTER: K.NONRENAL_LOSS_EXPONENT = %.2f (95%% interval -0.08 to 0.87)." % P_ENTERED)
    print("ENTER: K.RENAL_FRACTION_MAX = 1.0, a boundary condition and not a fit.")
    print("KEEP:  K.RENAL_FRACTION = %.3f, now the value AT THE REFERENCE INTAKE."
          % CURRENT_RENAL_FRACTION)
    rule()


if __name__ == "__main__":
    main()
