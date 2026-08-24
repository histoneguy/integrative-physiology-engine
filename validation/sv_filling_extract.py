#!/usr/bin/env python
"""Extract resting heart rate and the SV dependence on total blood volume.

Executes validation/sv_filling_prereg.md, which was written and committed
BEFORE any paper was opened. Serves ADR 0011.

Every row below was read from the retrieved PubMed record via the E-utilities
API; authors, journal, year, volume, issue and pages were verified against that
record per stop condition 2. PubMed's HTML is behind a cookie wall and returns
no article data - efetch XML is the record that was actually read.

NOTHING HERE IS A LEDGER PARAMETER. See VERDICT.

Run:  python validation/sv_filling_extract.py
"""

# ---------------------------------------------------------------------------
# Values already in the repo, used only to derive and to compare. Not sourced
# here.
# ---------------------------------------------------------------------------
CO0_L_PER_DAY = 7200.0        # CV.CO.NOMINAL, ledger; itself DERIVED from 5 L/min
G_VR_INCUMBENT = 2880.0       # CV.VENOUS_RETURN.SENSITIVITY, ledger; CALIBRATED
MIN_PER_DAY = 1440.0

# ---------------------------------------------------------------------------
# Q1 - resting heart rate.
#
# pooling.md rule order puts meta-analysis first. None was found for a nominal
# resting adult HR with posture recorded. What was found is a single cohort an
# order of magnitude larger than any candidate meta-analysis would pool, with a
# better-defined resting condition than a clinic pulse. Recorded as
# single-source per pooling.md rule 6 - "say so; do not dress it as consensus".
# ---------------------------------------------------------------------------

Q1 = {
    "label": "Fenland Study",
    "pmid": "37167327",
    "citation": ("Gonzales TI, Jeon JY, Lindsay T, Westgate K, Perez-Pozuelo I, "
                 "Hollidge S, Wijndaele K, Rennie K, Forouhi N, Griffin S, "
                 "Wareham N, Brage S. PLoS One 2023;18(5):e0285272"),
    "doi": "10.1371/journal.pone.0285272",
    "n": 10865,
    "n_women": 5722,
    "n_men": 5143,
    "age_range": "29-65 y",
    "postures": {           # bpm, mean and SD
        "supine":  (63.5, 8.9),
        "seated":  (67.6, 9.8),
        "sleeping": (56.9, 6.9),
    },
    "method": ("supine: Actiheart combined HR/movement chest sensor after at least "
               "1 h rest, 6 min recording, RHR from the final 3 min. seated: pulse "
               "during BP assessment, 3 readings at 1 min intervals, averaged."),
    "pooling_rule": "single-source",
}

# Posture selected in advance of seeing the numbers by consistency, not by value:
# CV.CO.NOMINAL is DERIVED from the conventional resting 5 L/min, which is a
# supine figure, so the HR that divides it must be supine too.
Q1_POSTURE = "supine"

# ---------------------------------------------------------------------------
# Q2, REMOVAL DIRECTION - quantified phlebotomy with SV measured.
#
# Blood removed IS a measured total blood volume change, 1:1 at the moment of
# removal. That is why this direction survives inclusion criterion 2 and the
# addition direction does not (see below).
#
# (label, pmid, citation, doi, n, mL_removed, dSV_mL, technique, posture,
#  hr_response, unresolved)
# ---------------------------------------------------------------------------

Q2_REMOVAL = [
    dict(
        label="Leonetti 2004", pmid="15241646", admissible=False,
        citation=("Leonetti P, Audat F, Girard A, Laude D, Lefrere F, Elghozi JL. "
                  "Clin Auton Res 2004;14(3):176-81"),
        doi="10.1007/s10286-004-0191-1", n=12, ml_removed=375.0, dsv_ml=13.3,
        baseline_sv=94.0,
        technique="finger volume-clamp pulse contour (Finometer/Beatscope Modelflow)",
        posture="STILL UNVERIFIED",
        hr_response="75.2+/-3.7 -> 78.3+/-4.5 bpm, NOT significant",
        unresolved=("STILL NOT ADMISSIBLE - full text not obtained. Dispersion "
                    "'+/- 5.2' on a mean of 94.0 at n=12 is almost certainly SEM "
                    "rather than SD, but UNVERIFIED. Posture UNVERIFIED. Elapsed "
                    "time appears to be the 6.4 min withdrawal itself - a continuous "
                    "beat-to-beat regression rather than the settled endpoint "
                    "section 5 fixed - but that too is UNVERIFIED. Subjects are "
                    "asymptomatic hereditary haemochromatosis on regular phlebotomy "
                    "with normal cardiac function stated, permitted by inclusion "
                    "criterion 1 as a recorded disease state."),
    ),
    dict(
        label="Gybel-Brask 2020", pmid="33030269", admissible=True,
        citation=("Gybel-Brask M, Nordsborg NB, Goetze JP, Johansson PI, "
                  "Secher NH, Bejder J. Transfus Med 2020;30(6):450-455"),
        doi="10.1111/tme.12727", n=21, ml_removed=900.0, dsv_ml=12.0,
        baseline_sv=118.0,
        technique=("finger volume-clamp pulse wave analysis (COtrek/Nexfin, BMeye), "
                   "60 s average, reference sensor at the 4th intercostal space"),
        posture="bed with upper body elevated ~30 deg, after 30 min of rest",
        hr_response="baseline 58 +/- 8 bpm (SD); post-donation values not tabulated",
        unresolved=("RESOLVED FROM FULL TEXT. Elapsed time: measurements taken "
                    "WITHIN 5 MINUTES of completing each donation, each donation "
                    "lasting 5-8 min, the two separated by ~5 min. Criterion 4 met. "
                    "Baseline mean +/- SD: HR 58 +/- 8, SV 118 +/- 11 mL, CO 6.9 "
                    "+/- 1.1 L/min. Strongest design in the set - randomised, "
                    "single-blinded, SHAM-PHLEBOTOMISED crossover at least 4 months "
                    "apart - so -12 mL is already sham-corrected. Total blood volume "
                    "separately measured by CO rebreathing in 9 of the 21. SV "
                    "UNCHANGED at 450 mL, changed only at 900 mL: a threshold signal "
                    "a single slope through the operating point cannot carry."),
    ),
    dict(
        label="Epstein 2021", pmid="32769818", admissible=True,
        citation=("Epstein D, Guinzburg A, Sharon S, Kiso S, Glick Y, Marcusohn E, "
                  "Glass YD, Miller A, Minha S, Furer A. Shock 2021;55(2):230-235"),
        doi="10.1097/SHK.0000000000001621", n=60, ml_removed=450.0, dsv_ml=4.57,
        baseline_sv=90.37,
        technique="whole-body bio-impedance (NiCaS), wrist and contralateral ankle",
        posture="supine",
        hr_response="67 (13) -> 68 (11) bpm; control 56 (7) -> 56 (7). Unchanged.",
        unresolved=("RESOLVED FROM FULL TEXT. Elapsed time: immediately before to "
                    "immediately after a 450 mL donation over ~10 min; the 20-subject "
                    "control was re-measured after 10 min without phlebotomy. "
                    "Criterion 4 met. Table 2, mean (SD): donors SV 90.37 (16.57) -> "
                    "85.32 (17.5), i.e. -5.05 mL; controls 98.91 (11.74) -> 98.43 "
                    "(11.48), i.e. -0.48 mL. CONTROL-CORRECTED dSV = 4.57 mL, which "
                    "is what is used here - the abstract's 5.07 mL is uncorrected. "
                    "Healthy young adult male military donors."),
    ),
]

# ---------------------------------------------------------------------------
# Q2, ADDITION DIRECTION - every candidate found, and why each is excluded.
#
# This is the finding of the search. The pre-registration anticipated that the
# two directions might DISAGREE. It did not anticipate that one of them would
# have no admissible study at all.
# ---------------------------------------------------------------------------

Q2_ADDITION_EXCLUDED = [
    dict(
        label="Weiner 2010", pmid="20826594",
        citation=("Weiner RB, Weyman AE, Khan AM, Reingold JS, Chen-Tournoux AA, "
                  "Scherrer-Crosbie M, Picard MH, Wang TJ, Baggish AL. "
                  "Circ Cardiovasc Imaging 2010;3(6):672-8"),
        doi="10.1161/CIRCIMAGING.109.932921",
        finding=("n=8 healthy, 2.1+/-0.3 L saline bolus. SV 51.3+/-10.9 -> "
                 "63.0+/-15.5 mL, P=0.003; CO 3.4 -> 4.4 L/min; NO CHANGE in heart "
                 "rate or blood pressure. Speckle-tracking echo."),
        reason=("INCLUSION CRITERION 2. 2.1 L of saline INFUSED is not a 2.1 L rise "
                "in blood volume - most of it leaves the intravascular space. No "
                "plasma or blood volume was measured. Converting infused volume to "
                "V_blood needs a retention fraction that is not in the paper, which "
                "is precisely the unsourced scaling that falsified ADR 0010's input "
                "link. Also reports peak systolic LV torsion up 33%, i.e. the "
                "contractile state did not hold still."),
    ),
    dict(
        label="Kumar 2004a", pmid="15153240",
        citation=("Kumar A, Anel R, Bunnell E, Zanotti S, Habet K, Haery C, "
                  "Marshall S, Cheang M, Neumann A, Ali A, Kavinsky C, Parrillo JE. "
                  "Crit Care 2004;8(3):R128-36"),
        doi=None,
        finding=("24 healthy male + 12 healthy mixed-sex volunteers, 3 L saline over "
                 "3 h. SV index up 15-25%. End-diastolic volumes only INCONSISTENTLY "
                 "increased; end-systolic volumes fell almost uniformly. Decreased "
                 "end-systolic volume contributed 40-90% of the SV response. "
                 "Ejection fraction, ventricular stroke work and Pes/ESVI all rose."),
        reason=("INCLUSION CRITERION 2, and separately the ADR 0011 contractility "
                "exclusion - which this paper does not merely trip but QUANTIFIES. "
                "See VERDICT."),
    ),
    dict(
        label="Kumar 2004b", pmid="15090949",
        citation=("Kumar A, Anel R, Bunnell E, Habet K, Zanotti S, Marshall S, "
                  "Neumann A, Ali A, Cheang M, Kavinsky C, Parrillo JE. "
                  "Crit Care Med 2004;32(3):691-9"),
        doi=None,
        finding=("Same 3 L over 3 h protocol, n=12 + n=32. End-diastolic VOLUME "
                 "indices tracked SV index well; CVP and PAOP did not track either."),
        reason=("NON-INDEPENDENT of Kumar 2004a - near-identical author list and the "
                "same protocol. pooling.md section 4 counts them once. Excluded on "
                "criterion 2 regardless. Retained because its result is a point "
                "AGAINST pressure-keyed and FOR volume-keyed formulations, which is "
                "relevant to ADR 0011 even though it sets no parameter."),
    ),
    dict(
        label="Bihari 2019", pmid="30998121",
        citation=("Bihari S, Wiersema UF, Perry R, Schembri D, Bouchier T, Dixon D, "
                  "Wong T, Bersten AD. J Appl Physiol (1985) 2019;126(6):1646-1660"),
        doi="10.1152/japplphysiol.01058.2018",
        finding=("n=6 healthy males, randomised double-blind crossover, 30 mL/kg "
                 "saline / Hartmann's / 4% albumin and 6 mL/kg 20% albumin. Greater "
                 "rise in CO and SV after colloid, ASSOCIATED WITH A REDUCTION IN "
                 "AFTERLOAD."),
        reason=("INCLUSION CRITERION 2, plus an explicit afterload change. n=6."),
    ),
    dict(
        label="van de Velde 2018", pmid="29016531",
        citation=("van de Velde L, Eeftinck Schattenkerk DW, Venema PAHT, Best HJ, "
                  "van den Bogaard B, Stok WJ, Westerhof BE, van den Born BJH. "
                  "J Hypertens 2018;36(3):544-551"),
        doi="10.1097/HJH.0000000000001583",
        finding=("31 middle-aged patients, active standing before and after 500 mL "
                 "phlebotomy. Blood loss augmented the fall in augmentation index by "
                 "5.9 pp."),
        reason=("The reported SV change belongs to the ACTIVE STANDING manoeuvre, "
                "which is on ADR 0011's disqualification list, not to the 500 mL. "
                "No supine pre/post-phlebotomy SV in the abstract. RETAIN AS A Q3 "
                "LEAD: it crosses a total-volume change with a posture change in the "
                "same subjects, which is the comparison Q3 asks for."),
    ),
    dict(
        label="Kucukdurmaz 2012", pmid="22324433",
        citation=("Kucukdurmaz Z, Karapinar H, Karavelioglu Y, Acar G, Gul I, "
                  "Emiroglu MY, Bulut M, Esen AM. Echocardiography 2012;29(4):451-4"),
        doi="10.1111/j.1540-8175.2011.01614.x",
        finding="71 healthy subjects, 450 mL donation, RV tissue-Doppler indices.",
        reason=("INCLUSION CRITERION 3. Reports E', TAPSE, MPI and inflow velocities. "
                "No SV, no CO, no HR. Nothing extractable."),
    ),
]


def main() -> None:
    w = 78
    print("=" * w)
    print("Q1 - RESTING HEART RATE")
    print("=" * w)
    q = Q1
    print(f"  {q['label']}  PMID {q['pmid']}")
    print(f"  {q['citation']}")
    print(f"  doi:{q['doi']}")
    print(f"  n = {q['n']} ({q['n_women']} women, {q['n_men']} men), {q['age_range']}")
    for p, (m, sd) in q["postures"].items():
        mark = "  <== selected" if p == Q1_POSTURE else ""
        print(f"    {p:9s} {m:5.1f} +/- {sd:4.1f} bpm{mark}")
    print(f"  method: {q['method']}")
    print(f"  pooling_rule = {q['pooling_rule']}")
    print()
    print("  DEVIATIONS FROM THE PRE-REGISTRATION, RECORDED:")
    print("   1. The prereg specified HEALTHY adults. Fenland is a GENERAL")
    print("      POPULATION cohort recruited from GP lists, not health-screened.")
    print("      For a nominal adult that is arguably the better frame, but it is")
    print("      not what was declared. Recorded, not silently adopted.")
    print("   2. Sex composition is 53% women. CV.HEMATOCRIT.NOMINAL is recorded as")
    print("      ADULT MALE nominal. The cardiovascular rows would then describe two")
    print("      different populations. The prereg forbade papering over this.")
    print("   3. k = 1. Large, but one cohort. single-source, not consensus.")
    print()

    hr0, hr0_sd = Q1["postures"][Q1_POSTURE]
    beats_per_day = hr0 * MIN_PER_DAY
    sv0_l = CO0_L_PER_DAY / beats_per_day
    print(f"  DERIVED, not sourced - the closure constraint:")
    print(f"    SV0 = CO0 / HR0 = {CO0_L_PER_DAY:.1f} / ({hr0:.1f} x {MIN_PER_DAY:.0f})")
    print(f"        = {sv0_l:.6f} L = {sv0_l * 1000:.2f} mL")
    print(f"  Sourcing SV0 as well would overdetermine the operating point.")
    print()

    print("=" * w)
    print("Q2 REMOVAL - PHLEBOTOMY WITH SV MEASURED")
    print("=" * w)
    rows = []
    for s in Q2_REMOVAL:
        slope = s["dsv_ml"] / (s["ml_removed"] / 1000.0)      # mL SV per L blood
        rows.append((s, slope))
        flag = "ADMISSIBLE" if s["admissible"] else "NOT ADMISSIBLE"
        print(f"  {s['label']:20s} PMID {s['pmid']}  n={s['n']}   [{flag}]")
        print(f"    {s['citation']}")
        print(f"    doi:{s['doi']}")
        print(f"    -{s['ml_removed']:.0f} mL blood  ->  dSV = -{s['dsv_ml']:.2f} mL"
              f"   slope = {slope:.2f} mL/L")
        print(f"    baseline SV: {s['baseline_sv']:.2f} mL")
        print(f"    technique : {s['technique']}")
        print(f"    posture   : {s['posture']}")
        print(f"    HR        : {s['hr_response']}")
        print(f"    NOTES     : {s['unresolved']}")
        print()

    adm = [(s, sl) for s, sl in rows if s["admissible"]]
    slopes = [sl for _, sl in adm]
    n_tot = sum(s["n"] for s, _ in adm)
    n_w = sum(s["n"] * sl for s, sl in adm) / n_tot

    print("  *** STOP CONDITION 1 FIRES ***")
    print(f"  k_admissible = {len(adm)}. The pre-registration requires k >= 3")
    print("  independent studies before any parameter is recorded for Q2. Two")
    print("  studies do not become a pooled value; they become single-source twice")
    print("  over, and pooling.md forbids dressing that as consensus.")
    print("  NO LEDGER PARAMETER IS RECORDED. G_vr stays in place.")
    print()
    print(f"  For the record only, so nobody re-derives it and mistakes it for an")
    print(f"  adopted value: n-weighted over the two admissible studies is")
    print(f"  {n_w:.3f} mL/L (from {slopes[0]:.2f} and {slopes[1]:.2f}).")
    print()
    print("  CORRECTION TO THE 2026-08-22 WRITE-UP. It said the spread tracked")
    print("  measurement technique - one Modelflow study against two impedance")
    print("  studies. THAT WAS WRONG. Gybel-Brask measures SV by finger volume-clamp")
    print("  pulse wave analysis (COtrek/Nexfin), the same family as Leonetti's")
    print("  Finometer; the thoracic impedance in its title is for CENTRAL BLOOD")
    print("  VOLUME, not stroke volume. So the two finger-pulse-contour studies")
    print("  disagree with EACH OTHER by 2.7x, and the one true impedance study sits")
    print("  at the bottom with the lower of them. The spread does NOT track")
    print("  technique, and prereg section 3's clause was invoked in error.")
    print()
    print("  WHAT DOES SHOW UP ACROSS ALL THREE: every baseline SV is well above the")
    baselines = " / ".join("%.0f" % s["baseline_sv"] for s, _ in rows)
    print(f"  operating point this model derives. {baselines} mL against"
          f" SV0 = {sv0_l * 1000:.1f} mL,")
    print("  and Gybel-Brask's baseline CO of 6.9 L/min and Epstein's 6.03 L/min")
    print("  against the model's 5.0 L/min. A slope can be right while the offset is")
    print("  wrong, so this does not invalidate the slopes - but these devices are")
    print("  not reading the same resting operating point the ledger describes, and")
    print("  that is recorded rather than reconciled.")
    print()

    print("=" * w)
    print("Q2 ADDITION - EVERY CANDIDATE, AND WHY EACH IS EXCLUDED")
    print("=" * w)
    for s in Q2_ADDITION_EXCLUDED:
        print(f"  {s['label']:20s} PMID {s['pmid']}")
        print(f"    {s['citation']}")
        if s["doi"]:
            print(f"    doi:{s['doi']}")
        print(f"    found : {s['finding']}")
        print(f"    EXCLUDED: {s['reason']}")
        print()
    print(f"  ADMISSIBLE STUDIES IN THE ADDITION DIRECTION: 0")
    print()

    print("=" * w)
    print("STOP CONDITION 4 - THE G_vr COMPARISON, MADE ONCE, AFTER POOLING")
    print("=" * w)
    print("  No study above was included, excluded, weighted or trimmed on the")
    print("  basis of this comparison. It is computed here and nowhere earlier.")
    print()
    print(f"    implied G_vr = HR0 x dSV/dV_blood, HR0 = {beats_per_day:.0f} beats/day")
    print()
    for s, sl in rows:
        implied = beats_per_day * sl / 1000.0
        tag = "" if s["admissible"] else "   [not admissible]"
        print(f"    {s['label']:20s} {implied:8.1f} (L/day)/L"
              f"   incumbent/implied = {G_VR_INCUMBENT / implied:.3f}{tag}")
    implied_nw = beats_per_day * n_w / 1000.0
    print(f"    {'k=2, not recorded':20s} {implied_nw:8.1f} (L/day)/L"
          f"   incumbent/implied = {G_VR_INCUMBENT / implied_nw:.3f}")
    print(f"    {'INCUMBENT G_vr':20s} {G_VR_INCUMBENT:8.1f} (L/day)/L  CALIBRATED")
    print()
    print("  DO NOT CONNECT THIS TO THE 2.2x RESIDUAL. The n-weighted ratio lands")
    print("  near a number that appears elsewhere in this repo for an unrelated")
    print("  reason. The pre-registration states that nothing found here may be used")
    print("  to re-attribute that residual, and a numerical coincidence is not an")
    print("  exception to that. It is recorded so that nobody 'discovers' it later.")
    print()

    print("=" * w)
    print("VERDICT")
    print("=" * w)
    print("  Q1  SOURCEABLE as single-source, with three recorded deviations.")
    print("      NOT YET A LEDGER ROW - the sex-composition mismatch against")
    print("      CV.HEMATOCRIT.NOMINAL is a decision, not an extraction.")
    print()
    print("  Q2 REMOVAL  k_admissible = 2. STOP CONDITION 1 FIRES.")
    print("      Full text of Gybel-Brask and Epstein was read on 2026-08-24 and")
    print("      both clear inclusion criterion 4 outright - Gybel-Brask measures")
    print("      within 5 min of each donation, Epstein immediately before and after")
    print("      against a 10-min time-matched control. Posture is semi-recumbent at")
    print("      ~30 deg and supine respectively. Neither is a during-withdrawal")
    print("      regression, so the endpoint objection was wrong for both.")
    print("      Leonetti is the only one left unresolved, and k stalls at 2.")
    print("      NO PARAMETER IS RECORDED. G_vr stays.")
    print()
    print("      Note the pattern: Q2 of the immersion pre-registration also stopped")
    print("      at k = 2. Twice now the admissible human literature has come up one")
    print("      study short of the threshold this repo set for itself. That is a")
    print("      fact about the threshold meeting the literature, not about either")
    print("      search, and it is worth watching rather than adjusting.")
    print()
    print("  Q2 ADDITION  BLOCKED, k = 0, and this is the finding of the search.")
    print("      Saline studies report INFUSED volume, not measured blood volume.")
    print("      Criterion 2 needs a quantified change in TOTAL BLOOD OR PLASMA")
    print("      volume; an infused crystalloid volume is not one, and converting")
    print("      it needs a retention fraction that is exactly the unsourced")
    print("      scaling that falsified ADR 0010's input link. The prereg foresaw")
    print("      the two directions DISAGREEING. It did not foresee one of them")
    print("      being empty, so section 6's directional comparison CANNOT BE RUN.")
    print()
    print("  AND THE CONTRACTILITY EXCLUSION IS NOT A TECHNICALITY. Kumar 2004")
    print("      measured it: 40-90% of the stroke volume response to 3 L of saline")
    print("      in healthy volunteers came from a FALL IN END-SYSTOLIC VOLUME, not")
    print("      a rise in end-diastolic volume, with ejection fraction and stroke")
    print("      work both up. Volume loading in intact humans is not a preload-only")
    print("      perturbation. Prereg section 0.2 refused to relax that exclusion")
    print("      before knowing this; the refusal was right.")
    print()
    print("  FULL-TEXT ACCESS. All three are subscription-only in Europe PMC")
    print("      (isOpenAccess=N, inPMC=N) with no PMC or repository deposit.")
    print("      - Gybel-Brask and Epstein: full text supplied 2026-08-24 and read.")
    print("        Both now satisfy inclusion criterion 4. The Copenhagen research")
    print("        portal also independently confirms the Gybel-Brask record, so")
    print("        that citation is verified against two records.")
    print("      - Leonetti: STILL NOT OBTAINED. A public PDF copy exists but its")
    print("        text layer is a subset-encoded font, and the browser treats the")
    print("        URL as a download rather than a page. This is the single item")
    print("        standing between k=2 and k=3.")
    print()
    print("  ONE RESULT FAVOURS ADR 0011 AND IS NOW THREE-DEEP. The ADR keeps HR a")
    print("      parameter rather than a state. Epstein tabulates HR 67 (13) -> 68")
    print("      (11) bpm across a 450 mL withdrawal with controls flat at 56 (7);")
    print("      Leonetti reports HR not significantly changed across 375 mL; Weiner")
    print("      reports no change across a 2.1 L bolus. Three independent studies,")
    print("      two directions, measured three different ways. Holding HR fixed")
    print("      while V_blood moves is defensible at these perturbation sizes,")
    print("      which is what tension 0.1 of the pre-registration asked.")


if __name__ == "__main__":
    main()
