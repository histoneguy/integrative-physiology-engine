#!/usr/bin/env python
"""ADR 0013's falsifiable test, run. The answer is NO, and it is not about G_pn.

Executes validation/ecf_salt_response_prereg.md, committed BEFORE any paper was opened
and sitting immediately before this change in main's history. No commit SHA is cited -
rebase-merge rewrites it. Verify the ordering with:

    git log --diff-filter=A -- validation/ecf_salt_response_prereg.md

THE VERDICT: Test B fails by a factor of 2.7 to 5.2 across the whole evidence base,
against a pre-registered threshold of 2. Branch A1 is therefore unavailable,
RN.PRESSURE_NATRIURESIS.SLOPE stays at 20.0, and ADR 0013 stays Proposed.

THE EVIDENCE BASE IS SEVEN PRIMARIES ACROSS FOUR GROUPS AND TWO METHODS, not one study.
The n-weighted body-weight limb (four groups, n = 132) gives 0.572 kg per 100 mmol/day
and the iothalamate tracer limb gives 0.553 L - AGREEING TO 4%. The pre-registration
declared 1 kg = 1 L in advance and said the conversion would be falsified if they
diverged; it is corroborated instead.

THE FINDING IS ABOUT THE CIRCULATION, NOT THE KIDNEY, which is exactly what ADR 0013
said its test would show if it failed: "the error has moved rather than been fixed -
most likely into G_vr, f_pv, or the fractional reabsorption term".

  human   dMAP / dV_ecf  =  1.885 mmHg/L   within-subject (van den Bosch, n = 70)
                          =  2.97 - 4.16    meta-analytic pressure / pooled volume
  model   dMAP / dV_ecf  =  11.285 mmHg/L  at 70 kg, scaling as 1/mass

The within-subject figure is the tightest comparison and the harshest; the pooled figure
is the most defensible, because the mechanistic volume studies are UNDERPOWERED for the
2 mmHg the meta-analyses detect - Kirkendall, Rorije and Taurio all report no BP change
at all, and taking that at face value would give a ratio of zero.

AND G_pn CANNOT FIX IT, because the two parameters are ORTHOGONAL. Measured, not argued:
an 8x change in G_vr moves the pressure response by 0.1% and moves the volume response
exactly inversely. G_pn sets dMAP; G_vr sets dMAP/dV. The human pressure data and the
human volume data identify one parameter each with no cross-talk.

Every citation below was read from the retrieved PubMed record; van den Bosch 2021 was
read as full text from PubMed Central, including Table 1.

Run:  python validation/ecf_salt_response_extract.py
"""

# ---------------------------------------------------------------------------
# THE SEARCH. Two sweeps, 12 queries, 85 unique records.
#
# Sweep 1 went at extracellular volume and sodium loading directly and returned the
# Groningen iothalamate series. Sweep 2 went at the body-weight limb and the
# ultra-long-duration balance literature - which sweep 1 under-returns because it does
# not use the words "extracellular volume" - and returned the camp that CONTRADICTS it.
# Directive 1.8 has now paid a fourth time.
# ---------------------------------------------------------------------------

SWEEP = dict(queries=24, records_screened=162,
             sweep3="classic primary sodium loading with measured body fluids, 6 queries",
             sweep4="weight limb across other groups, salt-reduction trials, 6 queries",
             sweep1="sodium intake / ECF volume / salt loading in healthy adults, 6 queries",
             sweep2="body weight, metabolic ward and ultra-long sodium balance, 6 queries")

# ---------------------------------------------------------------------------
# ADOPTED FOR TEST B. The only study found that reports the volume response, the
# pressure response, AND cohort body mass, in the SAME subjects over the same step.
# ---------------------------------------------------------------------------

TEST_B = dict(
    label="van den Bosch 2021", pmid="34921521", pmcid="PMC8683787",
    cite="van den Bosch JJJON, Hessels NR, Visser FW, Krikken JA, Bakker SJL, "
         "Riphagen IJ, Navis GJ. Plasma sodium, extracellular fluid volume, and blood "
         "pressure in healthy men. Physiol Rep 2021;9(24):e15103.",
    doi="10.14814/phy2.15103",
    n=70, sex="male", age="24 +/- 7", species="human",
    design="crossover, 7 days per level, high sodium then low sodium",
    method="ECFV as iothalamate distribution volume; intake VERIFIED by 24 h urinary "
           "sodium, which is the pre-registration's preferred criterion",
    table="Table 1, physiologic data after high- and low-sodium diet",
    na_high=230.0, na_low=38.0,              # mmol/24 h, MEASURED excretion
    map_high=88.0, map_low=86.0,             # mmHg
    ecfv_high=17.4, ecfv_low=16.5,           # L per 1.73 m2
    bsa=2.04,                                # m2
    weight_high=80.6, weight_low=79.2,       # kg
)

# ---------------------------------------------------------------------------
# CORROBORATING, NOT POOLED. Same group, same institution, same 50/200 mmol protocol,
# same iothalamate method - almost certainly overlapping cohorts. pooling.md prohibits
# double counting, so these are read as consistency checks, not as extra studies.
# ---------------------------------------------------------------------------

SAME_COHORT_FAMILY = [
    dict(label="Visser 2009", pmid="19282825", n=78, sex="male",
         cite="Visser FW, Krikken JA, Muntinga JH, Dierckx RA, Navis GJ. Rise in "
              "extracellular fluid volume during high sodium depends on BMI in healthy "
              "men. Obesity (Silver Spring) 2009;17(9):1684-1688.",
         result="dECFV = 1.2 +/- 1.8 L for a nominal 50 -> 200 mmol/day step, i.e. "
                "0.80 L per 100 mmol/day. ALSO REPORTS that the rise scales with BMI "
                "(r = 0.361), which the model does NOT reproduce - its volume response "
                "is mass-INVARIANT. Recorded as an unmodelled dependence."),
    dict(label="Toering 2018", pmid="28592435", n=36, sex="18 male, 18 female",
         cite="Toering TJ, Gant CM, Visser FW, van der Graaf AM, Laverman GD, "
              "Danser AHJ, Faas MM, Navis G, Lely AT. Sex differences in "
              "renin-angiotensin-aldosterone system affect extracellular volume in "
              "healthy subjects. Am J Physiol Renal Physiol 2018;314(5):F873-F878.",
         result="Same protocol and method, and the only study found that reports the "
                "volume response BY SEX - extracellular volume and blood pressure both "
                "higher in men on both intakes. The record read gives the direction, "
                "not the step change, so it cannot supply a number here. It is the "
                "right source for the 6.9% sex difference the model predicts."),
]

# ---------------------------------------------------------------------------
# THE WEIGHT LIMB, ADDED ON A THIRD AND FOURTH SWEEP. Four independent groups,
# and it CONVERGES WITH THE TRACER LIMB TO 3%.
#
# The pre-registration declared 1 kg = 1 L in advance and said in section 8 that the
# conversion would be FALSIFIED if the weight and ECF studies disagreed beyond their
# dispersions. They do not. That is the conversion earning its keep rather than being
# assumed.
# ---------------------------------------------------------------------------

WEIGHT_LIMB = [
    # label, pmid, n, delta intake mmol/day, delta weight kg, notes
    dict(label="van den Bosch 2021", pmid="34921521", n=70, d_na=192.0, d_kg=1.4,
         note="Same study as TEST_B; its weight limb, read from the same Table 1."),
    dict(label="Rorije 2018", pmid="29206647", n=12, d_na=150.0, d_kg=2.5,
         cite="Rorije NMG, Olde Engberink RHG, Chahid Y, van Vlies N, van Straalen JP, "
              "van den Born BH, Verberne HJ, Vogt L. Microvascular Permeability after an "
              "Acute and Chronic Salt Load in Healthy Subjects: A Randomized Open-label "
              "Crossover Intervention Study. Anesthesiology 2018;128(2):352-360.",
         note="12 normotensive males, <50 vs >200 mmol/day for EIGHT DAYS, randomised "
              "crossover. Body weight and blood pressure are its PRIMARY outcomes. "
              "+2.5 kg (95% CI 1.7-3.2), and BLOOD PRESSURE DID NOT CHANGE."),
    dict(label="Foo 1998", pmid="9680497", n=18, d_na=180.0, d_kg=0.45,
         cite="Foo M, Denver AE, Coppack SW, Yudkin JS. Effect of salt-loading on blood "
              "pressure, insulin sensitivity and limb blood flow in normal subjects. "
              "Clin Sci (Lond) 1998;95(2):157-164.",
         note="18 healthy normotensive, 220 vs 40 mmol/day for 6 days. +0.45 +/- 0.69 kg, "
              "plasma volume +0.29 +/- 0.67 L (P = 0.08), 24 h SBP +5.8 +/- 14.2 mmHg "
              "(P = 0.06, NOT significant). The SMALLEST volume response in the set."),
    dict(label="Heer 2000", pmid="10751219", n=32, d_na=150.0, d_kg=0.0,
         note="Entered as ZERO, and that is an INTERPRETATION of a null result rather "
              "than a measurement - the abstract states body mass did not increase. The "
              "pooled estimate is reported both with and without it for that reason."),
]

# Two further primaries that carry no extractable number but bear on the PRESSURE limb,
# which is the half that decides Test B.
PRESSURE_LIMB_QUALITATIVE = [
    dict(label="Kirkendall 1976", pmid="1249473", n=8,
         cite="Kirkendall AM, Connor WE, Abboud F, Rastogi SP, Anderson TA, Fry M. The "
              "effect of dietary sodium chloride on blood pressure, body fluids, "
              "electrolytes, renal function, and serum lipids of normotensive man. "
              "J Lab Clin Med 1976;87(3):411-434.",
         note="THE LONGEST PROTOCOL FOUND AND THE CLOSEST TO THIS MODEL'S 30 DAYS - low, "
              "moderate and high salt for AT LEAST FOUR WEEKS EACH in 8 normotensive men. "
              "Reports a TENDENCY for body weight, exchangeable sodium and inulin space to "
              "rise, NO CHANGE IN BLOOD PRESSURE supine or upright, and no change in total "
              "body water. Qualitative only in the record read, so it supplies no number - "
              "but it is direct evidence that the pressure response over a month in 8 "
              "normotensives is below detection."),
    dict(label="Taurio 2023", pmid="36708156", n=510,
         cite="Taurio J, Koskela J, Sinisalo M, Tikkakoski A, Niemela O, Hamalainen M, "
              "Moilanen E, Choudhary MK, Mustonen J, Nevalainen P, Porsti I. Urine sodium "
              "excretion is related to extracellular water volume but not to blood "
              "pressure in 510 normotensive and never-treated hypertensive subjects. "
              "Blood Press 2023;32(1):2170869.",
         note="THE LARGEST DATASET FOUND, n = 510, 24 h urinary sodium tertiles at 94, 148 "
              "and 218 mmol. Extracellular water HIGHER in the top tertile; NO difference "
              "in aortic systolic or diastolic pressure, heart rate, CARDIAC OUTPUT or "
              "SYSTEMIC VASCULAR RESISTANCE. Its own conclusion is that sodium intake "
              "'predominantly influences extracellular water volume without a clear effect "
              "on blood pressure' - which is this finding, stated independently and from "
              "the other direction. CROSS-SECTIONAL, so it cannot supply a delta per 100 "
              "mmol/day, and it is recorded for its direction and its size."),
]

# THE CAUTION THAT KEEPS THIS HONEST. Every mechanistic study above is underpowered for
# the effect the meta-analyses detect: Foo's SD on 24 h SBP is 14.2 mmHg with n = 18,
# and the meta-analytic normotensive response is 1.7-2.3 mmHg per 100 mmol. So "blood
# pressure did not change" in Kirkendall, Rorije and Taurio is NOT evidence that the
# pressure response is zero, and taking it at face value would give a ratio of zero and
# drive G_vr to zero, which is absurd. The defensible ratio therefore pairs the
# META-ANALYTIC pressure with the POOLED volume, and the within-subject van den Bosch
# ratio is reported alongside it as the upper end.
POWER_CAVEAT = True

# ---------------------------------------------------------------------------
# THE DECLARED CONFLICT, AND IT IS NOT RESOLVED HERE.
#
# A second research group, in a metabolic ward with complete balance accounting,
# reports that high sodium intake does NOT expand total body water or body mass at
# all. That is a qualitative contradiction of the Groningen series, not a quantitative
# disagreement, and pooling across it would produce a number describing neither.
# ---------------------------------------------------------------------------

CONFLICT = [
    dict(label="Heer 2000", pmid="10751219", n=32, sex="male",
         cite="Heer M, Baisch F, Kropp J, Gerzer R, Drummer C. High dietary sodium "
              "chloride consumption may not induce body fluid retention in humans. "
              "Am J Physiol Renal Physiol 2000;278(4):F585-F595.",
         result="Metabolic ward, 50 / 200 / 400 / 550 meq NaCl per day. Plasma volume "
                "rose dose-dependently (+315 +/- 37 mL at 550) but TOTAL BODY WATER DID "
                "NOT INCREASE AND BODY MASS DID NOT INCREASE. Concludes high sodium "
                "induces a fluid SHIFT from interstitial to intravascular space rather "
                "than storage. If this is right, dV_ecf is near zero and the model's "
                "error has the OPPOSITE sign."),
    dict(label="Heer 2009 (Salty Life 6)", pmid="19173770", n=9, sex="male",
         cite="Heer M, Frings-Meuthen P, Titze J, Boschmann M, Frisch S, Baecker N, "
              "Beck L. Increasing sodium intake from a previous low or high intake "
              "affects water, electrolyte and acid-base balance differently. "
              "Br J Nutr 2009;101(9):1286-1294.",
         result="28 d metabolic ward, four consecutive NaCl levels. Going from LOW to "
                "AVERAGE-NORMAL, ECV rose 2.02 +/- 0.31 L - LARGER than the Groningen "
                "figure. Going on to HIGH, 244 mmol Na were retained and ECV did NOT "
                "rise (-0.54 L). The response is NON-MONOTONIC, and the authors "
                "attribute the high-intake limb to osmotically inactive sodium storage "
                "on glycosaminoglycans."),
]

CONFLICT_VERDICT = (
    "TEST A IS INCONCLUSIVE ON ITS OWN and would be branch A4 by the pre-registration's "
    "own words - a spread that crosses a branch boundary. The volume-implied G_pn is "
    "15.9 (van den Bosch), 11.0 (Visser), 6.5 (Heer 2009 low-to-normal limb) and "
    "effectively infinite (Heer 2000, and Heer 2009's high limb). That spread covers "
    "every branch. TEST B IS NOT INCONCLUSIVE, because it is taken WITHIN one study "
    "whose own pressure, ECF and body-weight numbers agree with each other, and the "
    "pre-registration gives it precedence for exactly that reason."
)

# The model's operating range is 103-205 mEq/day, which sits inside the LOW-to-NORMAL
# limb where both camps agree the volume DOES respond. The disagreement is concentrated
# above 200 mmol/day, outside the model's range.
RANGE_NOTE = (
    "The model steps 205 -> 103 mEq/day. Both camps agree that ECF responds across "
    "LOW to NORMAL intake; they disagree above ~200 mmol/day, which is OUTSIDE the "
    "model's range. So the conflict does not disqualify the comparison - but Heer 2009's "
    "2.02 L for that same low-to-normal step is 3.7x larger than van den Bosch's, and "
    "that disagreement IS inside the range."
)

# ---------------------------------------------------------------------------
# WHAT THE MODEL SAYS. Measured, from bench/gpn_sweep.jl and the G_vr sweep.
# ---------------------------------------------------------------------------

MODEL = dict(
    dv100_at_gpn20=0.4393,          # L per 100 mmol/day, MASS-INVARIANT (55/70/85 kg)
    dv100_at_gpn51=0.1723,
    dmap100_at_gpn20_70kg=4.9577,   # mmHg per 100 mmol/day at 70 kg, scales as 1/mass
    ratio_70kg=11.285,              # mmHg/L, scales as 1/mass, set by G_vr ALONE
    inversion_male=8.786,           # G_pn = 8.786 / dV100
    inversion_female=8.221,
)

# G_vr sweep at G_pn = 20, 70 kg. THE ORTHOGONALITY RESULT.
GVR_SWEEP = [
    # (G_vr, dMAP per 100 mmol, dV_ecf per 100 mmol, ratio mmHg/L)
    (2880.0, 4.9577, 0.4393, 11.285),
    (1440.0, 4.9578, 0.8786, 5.643),
    (720.0, 4.9584, 1.7573, 2.822),
    (554.0, 4.9592, 2.2840, 2.171),
    (360.0, 4.9637, 3.5168, 1.411),
]


def main():
    print(__doc__)

    print("SEARCH")
    print("  %d queries, %d records" % (SWEEP["queries"], SWEEP["records_screened"]))
    for k in ("sweep1", "sweep2", "sweep3", "sweep4"):
        print("     %s: %s" % (k, SWEEP[k]))

    b = TEST_B
    d_na = b["na_high"] - b["na_low"]
    d_map = b["map_high"] - b["map_low"]
    # ECFV is reported INDEXED to 1.73 m2; de-index to the cohort's own BSA.
    d_ecfv = (b["ecfv_high"] - b["ecfv_low"]) * b["bsa"] / 1.73
    d_wt = b["weight_high"] - b["weight_low"]

    print("\nTEST B - THE RATIO, WHICH DOES NOT INVOLVE G_pn AT ALL")
    print("  %s, n = %d, %s, %s" % (b["label"], b["n"], b["sex"], b["design"]))
    print("     %s" % b["method"])
    print("     sodium   %.0f -> %.0f mmol/24 h   (delta %.0f, MEASURED not prescribed)"
          % (b["na_high"], b["na_low"], d_na))
    print("     MAP      %.0f -> %.0f mmHg        (delta %.1f)"
          % (b["map_high"], b["map_low"], d_map))
    print("     ECFV     %.1f -> %.1f L/1.73 m2   (delta %.3f L at BSA %.2f)"
          % (b["ecfv_high"], b["ecfv_low"], d_ecfv, b["bsa"]))
    print("     weight   %.1f -> %.1f kg          (delta %.1f)"
          % (b["weight_high"], b["weight_low"], d_wt))

    map100 = d_map / d_na * 100.0
    ecf100 = d_ecfv / d_na * 100.0
    wt100 = d_wt / d_na * 100.0
    print("\n     per 100 mmol/day:  dMAP %.3f mmHg   dECFV %.3f L   dweight %.3f kg"
          % (map100, ecf100, wt100))

    model_ratio_here = MODEL["ratio_70kg"] * 70.0 / b["weight_high"]
    for name, dv in (("ECFV, de-indexed", d_ecfv),
                     ("ECFV, as printed", b["ecfv_high"] - b["ecfv_low"]),
                     ("body weight, 1 kg = 1 L", d_wt)):
        human_ratio = d_map / dv
        print("     ratio via %-24s %6.3f mmHg/L   model %5.2f   FACTOR %.1f"
              % (name, human_ratio, model_ratio_here, model_ratio_here / human_ratio))
    print("     PRE-REGISTERED FAILURE THRESHOLD: factor 2. All three exceed it.")

    print("\nTEST A - THE MAGNITUDE")
    gvol = MODEL["inversion_male"] / ecf100
    print("     volume-implied G_pn = %.3f / %.3f = %.1f" %
          (MODEL["inversion_male"], ecf100, gvol))
    print("     ADR 0013 concordant pressure bracket: 43.5 - 58.8   -> OUTSIDE, low")
    print("     " + CONFLICT_VERDICT[:100] + "...")

    print("\nTHE WEIGHT LIMB - FOUR GROUPS, POOLED n-WEIGHTED (pooling.md rule 3)")
    tot_n = tot_nw = 0.0
    for w in WEIGHT_LIMB:
        per100 = w["d_kg"] / w["d_na"] * 100.0
        tot_n += w["n"]; tot_nw += w["n"] * per100
        print("  %-20s n=%-4d d_Na=%-6.0f d_wt=%-5.2f kg   %.3f kg/100 mmol"
              % (w["label"], w["n"], w["d_na"], w["d_kg"], per100))
    pooled_all = tot_nw / tot_n
    keep = [w for w in WEIGHT_LIMB if w["d_kg"] > 0.0]
    pooled_pos = (sum(w["n"] * w["d_kg"] / w["d_na"] * 100.0 for w in keep) /
                  sum(w["n"] for w in keep))
    print("  POOLED %.3f kg/100 mmol (k=%d, n=%d)  |  %.3f excluding Heer null (k=%d)"
          % (pooled_all, len(WEIGHT_LIMB), int(tot_n), pooled_pos, len(keep)))
    print("  TRACER ECF LIMB: %.3f L/100 mmol (van den Bosch, iothalamate)" % ecf100)
    print("  TWO INDEPENDENT METHODS AGREE TO %.0f%% - the pre-registered 1 kg = 1 L"
          % (abs(pooled_all - ecf100) / ecf100 * 100.0))
    print("  conversion is CORROBORATED, not assumed; prereg section 8 said it would be")
    print("  falsified if they diverged.")

    print("\n  RATIO FROM THE POOLED VOLUME AND THE META-ANALYTIC PRESSURE")
    print("  (the mechanistic studies are UNDERPOWERED for a 2 mmHg effect - Foo SD on")
    print("   24 h SBP is 14.2 with n=18 - so BP did not change is NOT dMAP = 0)")
    for lbl, dmap in (("He 2013 1.96", 1.96), ("Cutler 1997 1.70", 1.70),
                      ("He 2002 2.30", 2.30)):
        for vlbl, vol in (("pooled weight", pooled_all), ("tracer ECF", ecf100)):
            rt = dmap / vol
            print("     %-17s / %-14s = %5.2f mmHg/L -> model %5.2f is %.1fx stiff"
                  % (lbl, vlbl, rt, MODEL["ratio_70kg"], MODEL["ratio_70kg"] / rt))

    print("\nTHE CONFLICT, RECORDED AND NOT RESOLVED")
    for c in CONFLICT:
        print("  %-24s n=%-3d %s" % (c["label"], c["n"], c["result"][:74] + "..."))
    print("\n  TWO PRIMARIES WITH NO NUMBER THAT BEAR ON THE PRESSURE LIMB")
    for q in PRESSURE_LIMB_QUALITATIVE:
        print("  %-18s n=%-4d %s" % (q["label"], q["n"], q["note"][:70] + "..."))
    print("  " + RANGE_NOTE[:100] + "...")

    print("\nORTHOGONALITY: G_pn SETS THE PRESSURE, G_vr SETS THE RATIO")
    print("  G_vr     dMAP/100    dV/100     ratio")
    for gvr, dm, dv, rt in GVR_SWEEP:
        print("  %-8.0f %-11.4f %-10.4f %.3f" % (gvr, dm, dv, rt))
    lo, hi = GVR_SWEEP[0], GVR_SWEEP[-1]
    print("  an %.0fx change in G_vr moves the pressure response by %.2f%%"
          % (lo[0] / hi[0], abs(hi[1] - lo[1]) / lo[1] * 100.0))
    print("  and moves the volume response EXACTLY inversely (G_vr * dV = %.1f throughout)"
          % (lo[0] * lo[2]))

    # The target the next pass has to hit, stated as a number rather than a direction.
    target_ratio_70kg = (d_map / d_ecfv) * b["weight_high"] / 70.0
    lo = 2880.0 * 2.97 / MODEL["ratio_70kg"]
    hi = 2880.0 * 4.16 / MODEL["ratio_70kg"]
    print("\n  TO MATCH THE HUMAN RATIO, G_vr must fall from 2880 to %.0f-%.0f"
          % (lo, hi))
    print("  (%.0f on the harshest within-subject reading; the range is the pooled one)"
          % (2880.0 * target_ratio_70kg / MODEL["ratio_70kg"]))
    print("  PART OF THAT IS NOT G_vr. Cardiovascular.jl computes V_blood as")
    print("  V_plasma/(1-Hct) with Hct a CONSTANT, so red cell volume expands with")
    print("  plasma over a 30 day salt step. Red cell mass is fixed on that timescale;")
    print("  plasma expansion DILUTES the haematocrit. dV_blood/dV_ecf should be f_pv")
    print("  (0.211), not f_pv/(1-Hct) (0.386) - a factor of 1.83, taking the model")
    print("  ratio to 6.17 and leaving G_vr needing only 1.5-2.8x. DIAGNOSED FROM THE")
    print("  EQUATION AND THE ARITHMETIC THAT REPRODUCES 11.285 EXACTLY; NOT YET RUN.")
    print("  Its justification is independent of this test - red cell mass does not")
    print("  track plasma in 30 days - but it was found while looking for the")
    print("  discrepancy, and that is declared rather than presented as coincidence.")
    print("  (human ratio %.3f mmHg/L at %.1f kg = %.3f at the 70 kg reference)"
          % (d_map / d_ecfv, b["weight_high"], target_ratio_70kg))

    print("\nVERDICT")
    print("  Test B fails by 2.7-5.2x across the base (%.1f within-subject);"
          % (model_ratio_here / (d_map / d_ecfv)))
    print("  branch A1 is unavailable REGARDLESS of Test A.")
    print("  RN.PRESSURE_NATRIURESIS.SLOPE stays 20.0 and ADR 0013 stays")
    print("  Proposed. The pressure limb still supports 51 - this does not refute it -")
    print("  but accepting it alone would take the volume response from 1.26x too small")
    print("  to 3.2x too small, because dMAP is what G_pn moves and dV_ecf follows it.")
    print("  FIX G_vr FIRST. It is calibrated, never measured, and replacing it with")
    print("  sourced venous compliance is already HANDOVER section 4 item 1.")

    # Assertions, so this file fails rather than misleads if the numbers are edited.
    assert abs(d_na - 192.0) < 1e-9
    assert abs(round(ecf100, 3) - 0.553) < 1e-9
    assert model_ratio_here / (d_map / d_ecfv) > 2.0
    assert gvol < 43.5


if __name__ == "__main__":
    main()
