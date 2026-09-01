#!/usr/bin/env python
"""Two inverted dependencies, sourced: stroke volume and maximal urine concentration.

Executes validation/dependency_inversion_prereg.md, committed BEFORE any paper was
opened and sitting immediately before this change in main's history.

NO COMMIT SHA IS CITED, DELIBERATELY. Rebase-merge rewrites it, and every
pre-registration SHA already cited in this repository - 3fbe260, e0195f4, 3fd859b,
7d97d65, 9e2cef4, d811ca0 - points at a commit that main does not contain. Verify the
ordering instead:

    git log --diff-filter=A -- validation/dependency_inversion_prereg.md

THE ANSWER, BOTH BRANCHES: the textbook number was wrong, in the same direction the
last five were.

  Branch A  CV.SV.NOMINAL   80.7 / 77.0 mL derived  ->  96 / 75 mL reported
            CV.CO.NOMINAL   7200 L/day assumed      ->  8570.88 / 7020 derived
            The conventional 5 L/min is 5.95 in men and 4.88 in women once
            measured stroke volume meets measured supine heart rate.

  Branch B  ADH.URINE.OSM_MAX        1200 derived   ->  982 mOsm/kg reported
            RN.H2O.OBLIGATORY_LOSS   0.5 assumed    ->  0.611 L/day derived
            The conventional 1200 mOsm/kg is 22% above what two independent
            DDAVP studies measure in healthy adults.

Every citation below was read from the retrieved PubMed record; authors, journal, year,
volume and pages verified against that record. Petersen 2017 and Luu 2022 were read as
full text from PubMed Central, including their tables.

Run:  python validation/dependency_inversion_extract.py
"""

# ---------------------------------------------------------------------------
# THE SEARCH. Two sweeps per branch, per directive 1.8.
#
# Branch A sweep 1 went at CMR and 3D-echo reference-value studies and returned the
# candidate finally adopted. Sweep 2 went at the meta-analyses, the consensus
# compilations and the non-imaging cardiac-output literature specifically, to find
# whatever would contradict it. What it returned was not a contradiction but a
# CONSTRAINT: the largest and best-designed cohort in the field reports the quantity
# indexed to body surface area only, which this model cannot consume.
#
# Branch B sweep 1 and 2 returned an overwhelmingly clinical literature - lithium
# cohorts, polycystic kidney disease, paediatric series, desmopressin bioequivalence -
# which is what the 2026-08-31 attempt on RN.H2O.OBLIGATORY_LOSS also found. Two
# purpose-built normative studies survive.
# ---------------------------------------------------------------------------

SWEEP = dict(
    branch_a=dict(queries=16, records_screened=187,
                  sweep1="CMR / 3D echo reference values by sex, 8 queries",
                  sweep2="meta-analyses, consensus compilations, non-imaging CO, 8 queries"),
    branch_b=dict(queries=20, records_screened=176,
                  sweep1="maximal concentrating ability / water deprivation, 6 queries",
                  sweep2="DDAVP reference intervals, obligatory volume, ageing, 14 queries"),
)

# ---------------------------------------------------------------------------
# BRANCH A, ADOPTED. Pre-registration step 3: exactly one usable human primary
# study reporting ABSOLUTE resting stroke volume by sex with n and dispersion.
# single-source, k = 1, pooling.md rule 6.
# ---------------------------------------------------------------------------

SV_ADOPTED = dict(
    label="Petersen 2017", pmid="28178995", pmcid="PMC5304550",
    cite="Petersen SE, Aung N, Sanghvi MM, Zemrak F, Fung K, Paiva JM, Francis JM, "
         "Khanji MY, Lukaschuk E, Lee AM, Carapella V, Kim YJ, Leeson P, Piechnik SK, "
         "Neubauer S. Reference ranges for cardiac structure and function using "
         "cardiovascular magnetic resonance (CMR) in Caucasians from the UK Biobank "
         "population cohort. J Cardiovasc Magn Reson 2017;19(1):18.",
    doi="10.1186/s12968-017-0327-9",
    n=800, n_male=368, n_female=432, age="45-74", species="human",
    technique="CMR, steady-state free precession at 1.5 T, manual contouring, "
              "papillary muscles and trabeculations INCLUDED IN LV VOLUME",
    table="Table 12, ventricular parameters stratified by gender",
    lvsv_male=(96.0, 20.0), lvsv_female=(75.0, 14.0),          # mL, mean +/- SD
    lvsv_indexed_male=(49.0, 10.0), lvsv_indexed_female=(45.0, 8.0),   # mL/m2
    cohort_mass="71 / 71 / 69 kg by AGE GROUP; NOT reported by sex",
    why="The only candidate found that reports absolute stroke volume by sex with a "
        "dispersion, from a population-based cohort with cardiovascular disease and "
        "chamber-affecting conditions excluded. 5,065 scanned, 804 surviving exclusion.",
)

# ---------------------------------------------------------------------------
# BRANCH A, SCREENED AND NOT USED. Recorded so the next attempt does not repeat it.
# ---------------------------------------------------------------------------

SV_REJECTED = [
    dict(label="Zhan 2024", pmid="38377242", n=12812, k_studies=52, screened=254,
         cite="Zhan Y, Friedrich MG, Dendukuri N, Lu Y, Chetrit M, Schiller I, Joseph L, "
              "Shaw JL, Chuang ML, Riffel JH, Manning WJ, Afilalo J. Meta-Analysis of "
              "Normal Reference Values for Right and Left Ventricular Quantification by "
              "Cardiovascular Magnetic Resonance. Circ Cardiovasc Imaging "
              "2024;17(2):e016090.",
         why_not="THE SOURCE pooling.md RULE 1 WOULD HAVE PREFERRED, and it fails twice. "
                 "Bayesian hierarchical meta-analysis, 25 countries - but it reports "
                 "LOWER AND UPPER REFERENCE LIMITS, not a central estimate, and only "
                 "INDEXED to body surface area. range-midpoint is prohibited for new "
                 "entries and this model carries no BSA. It also reports end-diastolic "
                 "and end-systolic volume rather than stroke volume. ITS CENTRAL POINT "
                 "IS WHY BRANCH A IS SINGLE-SOURCE: it pools the two papillary-muscle "
                 "tracing conventions SEPARATELY, because they are not interchangeable."),

    dict(label="Luu 2022 (CAHHM)", pmid="34980185", pmcid="PMC8722350", n=3206,
         cite="Luu JM, Gebhard C, Ramasundarahettige C, Desai D, Schulze K, Marcotte F, "
              "Awadalla P, Broet P, Dummer T, Hicks J, Larose E, Moody A, Smith EE, "
              "Tardif JC, Teixeira T, Teo KK, Vena J, Lee DS, Anand SS, Friedrich MG. "
              "Normal sex and age-specific parameters in a multi-ethnic population: a "
              "cardiovascular magnetic resonance study of the Canadian Alliance for "
              "Healthy Hearts and Minds cohort. J Cardiovasc Magn Reson 2022;24(1):2.",
         why_not="LARGER AND BETTER DESIGNED THAN THE ROW ADOPTED - 3,206 people, "
                 "multi-ethnic, anatomically correct contouring, free of cardiovascular "
                 "disease AND risk factors - and unusable here. Table 2 reports every "
                 "ventricular volume INDEXED TO BSA ONLY (LVSV 46 +/- 8 male, 42 +/- 7 "
                 "female mL/m2). Converting needs a BSA formula, which the "
                 "pre-registration refused to introduce as a side effect. It also "
                 "contours papillary muscles into LV MASS rather than volume, so it "
                 "could not have been pooled with Petersen in any case. IT DOES "
                 "CORROBORATE on the indexed scale, to 6-7%."),

    dict(label="Patel 2021 (WASE)", pmid="34044105",
         cite="Patel HN, Miyoshi T, Addetia K, Henry MP, Citro R, Daimon M, "
              "Gutierrez Fajardo P, Kasliwal RR, Kirkpatrick JN, Monaghan MJ, Muraru D, "
              "Ogunyankin KO, Park SW, Ronderos RE, Sadeghpour A, Scalia GM, Takeuchi M, "
              "Tsang W, Tucay ES, Zhang Y, Blitz A, Mor-Avi V, Lang RM, Asch FM. Normal "
              "Values of Cardiac Output and Stroke Volume According to Measurement "
              "Technique, Age, Sex, and Ethnicity: Results of the World Alliance "
              "Societies of Echocardiography Study. J Am Soc Echocardiogr "
              "2021;34(10):1077-1085.",
         why_not="STILL PAYWALLED with no numbers in the abstract, as recorded against "
                 "CV.CO.NOMINAL on 2026-08-31. Named again only so the next attempt "
                 "knows it has been tried twice."),

    dict(label="Addetia 2022 (WASE 3D echo)", pmid="34920112", n=1589,
         cite="Addetia K, Miyoshi T, Amuthan V, Citro R, Daimon M, Gutierrez Fajardo P, "
              "Kasliwal RR, Kirkpatrick JN, Monaghan MJ, Muraru D, Ogunyankin KO, "
              "Park SW, Ronderos RE, Sadeghpour A, Scalia GM, Takeuchi M, Tsang W, "
              "Tucay ES, Tude Rodrigues AC, Zhang Y, Hitschrich N, Blankenhagen M, "
              "Degel M, Schreckenberg M, Mor-Avi V, Asch FM, Lang RM. Normal Values of "
              "Left Ventricular Size and Function on Three-Dimensional Echocardiography: "
              "Results of the World Alliance Societies of Echocardiography Study. "
              "J Am Soc Echocardiogr 2022;35(5):449-459.",
         why_not="Indexed volumes only in the record read, and 3D echocardiography is a "
                 "different technique from CMR - pooling across them is prohibited."),

    dict(label="Salton 2002 (Framingham Offspring)", pmid="11897450", n=142,
         cite="Salton CJ, Chuang ML, O'Donnell CJ, Kupka MJ, Larson MG, Kissinger KV, "
              "Edelman RR, Levy D, Manning WJ. Gender differences and normal left "
              "ventricular anatomy in an adult population free of hypertension. A "
              "cardiovascular magnetic resonance study of the Framingham Heart Study "
              "Offspring cohort. J Am Coll Cardiol 2002;39(6):1055-1060.",
         why_not="Reports end-diastolic and end-systolic volume and the DIRECTION of the "
                 "sex difference, not stroke volume, in the record read. Retained below "
                 "as evidence on the BSA question."),

    dict(label="Le Ven 2016", pmid="26354980", pmcid="PMC5066336", n=434,
         cite="Le Ven F, Bibeau K, De Larochelliere E, Tizon-Marcos H, "
              "Deneault-Bissonnette S, Pibarot P, Deschepper CF, Larose E. Cardiac "
              "morphology and function reference values derived from a large subset of "
              "healthy young Caucasian adults by magnetic resonance imaging. "
              "Eur Heart J Cardiovasc Imaging 2016;17(9):981-990.",
         why_not="Mean age 26 +/- 4, so a young-adult cohort rather than the adult range "
                 "the rest of this ledger uses, and no absolute stroke volume in the "
                 "record read. Retained below as evidence on the BSA question."),
]

# ---------------------------------------------------------------------------
# BRANCH A, THE PRE-REGISTERED PREDICTION THAT WAS HALF WRONG.
#
# The pre-registration predicted, citing Katori 1979 through the CV.SV.NOMINAL note,
# that normalising for body size would make the sexed pair SHRINK SUBSTANTIALLY AND
# POSSIBLY COLLAPSE - the way ECF per kg did when blood volume and haematocrit were
# sourced as pairs. It shrinks. It does not collapse, and four independent cohorts
# say so.
# ---------------------------------------------------------------------------

BSA_SURVIVES = [
    dict(label="Petersen 2017", n=800,
         absolute="96 vs 75 mL, a 28% male excess",
         indexed="49 vs 45 mL/m2, a 9% male excess"),
    dict(label="Luu 2022", n=3206,
         absolute="not reported",
         indexed="46 vs 42 mL/m2, a 10% male excess"),
    dict(label="Salton 2002", n=142,
         absolute="greater in men, p < 0.001",
         indexed="volumetric measures REMAIN greater in men after BSA adjustment, "
                 "p < 0.001, and after height adjustment, p < 0.02"),
    dict(label="Le Ven 2016", n=434,
         absolute="stroke volumes greater in men for both ventricles",
         indexed="after normalisation to BSA, ALL gender differences remained"),
]

BSA_VERDICT = (
    "Body size carries roughly two thirds of the absolute difference and about a third "
    "is not size. The CV.SV.NOMINAL note that cited Katori 1979 (dye dilution, 1979, "
    "109 men and 42 women) for NO significant sex difference in stroke index is "
    "contradicted by four modern imaging cohorts totalling 4,582 people, and has been "
    "corrected on the row. The pair is entered as reported and NOT mass-normalised, "
    "because Petersen reports cohort weight by age group and not by sex; that is "
    "recorded as debt in the row and in HANDOVER section 7."
)

# ---------------------------------------------------------------------------
# BRANCH B, ADOPTED.
# ---------------------------------------------------------------------------

UMAX_ADOPTED = dict(
    label="Tryding 1988", pmid="3206218",
    cite="Tryding N, Berg B, Ekman S, Nilsson JE, Sterner G, Harris A. DDAVP test for "
         "renal concentration capacity. Age-related reference intervals. "
         "Scand J Urol Nephrol 1988;22(2):141-145.",
    doi="10.1080/00365599.1988.11690400",
    n=212, age="20-80", species="human",
    protocol="single 4 microgram subcutaneous injection of DDAVP",
    value_20y=982.0, value_80y=823.0,      # mOsm/kg, mean by age
    why="Purpose-built reference-interval study of exactly this quantity - directive 1.7, "
        "the relationship IS the subject rather than the instrument. It also reports that "
        "maximal osmolality did NOT differ significantly between strict fluid restriction "
        "and liberal intake before the DDAVP, so the value is not an artefact of the "
        "deprivation protocol.",
    which_value="982, the value at the YOUNG ADULT end, because U_max is a CEILING - the "
                "saturation limit of the ADH curve at adh = 1 - and not a population mean. "
                "The 16% decline across six decades is real and this model has no age "
                "dimension: recorded as debt, not approximated.",
)

UMAX_CORROBORATION = dict(
    label="Bech 2017", pmid="29212860", pmcid="PMC5727289",
    cite="Bech AP, Wetzels JFM, Nijenhuis T. Reference values of renal tubular function "
         "tests are dependent on age and kidney function. Physiol Rep 2017;5(23):e13542.",
    doi="10.14814/phy2.13542",
    median_young=1002.0, median_old=820.0, median_ckd=624.0,   # mOsm/kg, desmopressin
    n_per_group=10,
    not_pooled="Bech reports a MEDIAN of 10 subjects aged 18-50; Tryding reports a fitted "
               "mean by age across 212. Pooling a median of ten with a regression endpoint "
               "would need a rule invented after seeing both, which pooling.md forbids. "
               "Recorded as independent corroboration instead: two studies thirty years "
               "apart agree within 2% in the young and within 0.4% in the old.",
)

UMAX_REJECTED = [
    dict(label="Nadvornikova 1980", pmid="7418281", n_healthy=45,
         cite="Nadvornikova H, Schuck O, Cort JH. A standardized desmopressin test of "
              "renal concentrating ability. Clin Nephrol 1980;14(3):142-147.",
         why_not="The right design - 45 healthy volunteers, each their own control, "
                 "36 h dehydration against 10 microgram intranasal desmopressin - and it "
                 "reports the equivalence of the two protocols rather than a normative "
                 "osmolality, in the record read."),
    dict(label="Curtis 1979", pmid="421089", pmcid="PMC1597680",
         cite="Curtis JR, Donovan BA. Assessment of renal concentrating ability. "
              "Br Med J 1979;1(6159):304-305.",
         why_not="Supports the protocol - most normal subjects pass maximally "
                 "concentrated urine at some point in a 24 h control period - and gives "
                 "no value."),
    dict(label="Malmberg 2020", pmid="32867720", n_controls=18,
         cite="Malmberg MH, Mose FH, Pedersen EB, Bech JN. Urine concentration ability is "
              "reduced to the same degree in adult dominant polycystic kidney disease "
              "compared with other chronic kidney diseases in the same CKD-stage and "
              "lower than in healthy control subjects - a case control study. "
              "BMC Nephrol 2020;21(1):379.",
         why_not="A case-control design with 18 healthy controls; the controls are a "
                 "comparison group, not a normative sample, and no normative maximum is "
                 "reported in the record read."),
]

# ---------------------------------------------------------------------------
# THE ARITHMETIC. Everything below is derived from the two adopted values plus
# ledger rows that did not move, and is asserted rather than asserted-about.
# ---------------------------------------------------------------------------

HR0 = dict(male=62.0, female=65.0)            # CV.HR.NOMINAL, Gonzales 2023
SV0 = dict(male=96.0, female=75.0)            # CV.SV.NOMINAL, Petersen 2017
MAP0 = 87.0                                   # CV.MAP.SETPOINT
PP0 = 33.0                                    # CV.PP.CENTRAL_NOMINAL
SOLUTE = 600.0                                # RN.URINE.SOLUTE_LOAD
U_MIN = 50.0                                  # ADH.URINE.OSM_MIN
U_MAX = 982.0                                 # ADH.URINE.OSM_MAX, Tryding 1988
OSM_SET, OSM_THR = 287.0, 284.0               # BF.OSM.PLASMA_SETPOINT, ADH.OSM.THRESHOLD
V_BASE = 2.5 - 0.8                            # intake minus insensible loss


def main() -> None:
    print(__doc__)

    print("SEARCH")
    for branch, s in SWEEP.items():
        print("  %s: %d queries, %d records" % (branch, s["queries"],
                                                s["records_screened"]))
        print("     sweep 1: " + s["sweep1"])
        print("     sweep 2: " + s["sweep2"])

    print("\nBRANCH A - STROKE VOLUME")
    print("  ADOPTED: %s, n = %d (%d men, %d women), %s"
          % (SV_ADOPTED["label"], SV_ADOPTED["n"], SV_ADOPTED["n_male"],
             SV_ADOPTED["n_female"], SV_ADOPTED["age"]))
    print("     technique: " + SV_ADOPTED["technique"])
    print("     LVSV  male %.0f +/- %.0f mL   female %.0f +/- %.0f mL"
          % (SV_ADOPTED["lvsv_male"] + SV_ADOPTED["lvsv_female"]))
    print("     cohort mass: " + SV_ADOPTED["cohort_mass"])
    for r in SV_REJECTED:
        print("  rejected: %-26s %s" % (r["label"], r["why_not"][:64] + "..."))

    print("\n  DOES THE SEX DIFFERENCE SURVIVE BODY-SURFACE INDEXING?")
    for e in BSA_SURVIVES:
        print("     %-16s n=%-5d indexed: %s" % (e["label"], e["n"], e["indexed"][:70]))
    print("     VERDICT: " + BSA_VERDICT[:96] + "...")

    print("\n  DERIVATION")
    co, tpr, cart = {}, {}, {}
    for sex in ("male", "female"):
        co[sex] = HR0[sex] * 1440.0 * SV0[sex] / 1000.0
        tpr[sex] = MAP0 / co[sex]
        cart[sex] = SV0[sex] / PP0
        print("     %-7s CO0 = %.1f * 1440 * %.0f / 1000 = %10.2f L/day  (%.2f L/min)"
              % (sex, HR0[sex], SV0[sex], co[sex], co[sex] / 1440.0))
        print("             TPR0 = 87.0 / CO0 = %.6g    C_art = %.0f / 33 = %.4g"
              % (tpr[sex], SV0[sex], cart[sex]))
    print("     the conventional 5.00 L/min sits BELOW both, by 19% in men")

    print("\nBRANCH B - MAXIMAL URINE CONCENTRATION")
    print("  ADOPTED: %s, n = %d, %s, %s"
          % (UMAX_ADOPTED["label"], UMAX_ADOPTED["n"], UMAX_ADOPTED["age"],
             UMAX_ADOPTED["protocol"]))
    print("     %.0f mOsm/kg at 20 years, %.0f at 80"
          % (UMAX_ADOPTED["value_20y"], UMAX_ADOPTED["value_80y"]))
    print("  CORROBORATED, NOT POOLED: %s, median %.0f (18-50), %.0f (over 50), n = %d each"
          % (UMAX_CORROBORATION["label"], UMAX_CORROBORATION["median_young"],
             UMAX_CORROBORATION["median_old"], UMAX_CORROBORATION["n_per_group"]))
    for r in UMAX_REJECTED:
        print("  rejected: %-22s %s" % (r["label"], r["why_not"][:64] + "..."))

    print("\n  DERIVATION")
    v_min = SOLUTE / U_MAX
    k_adh = ((SOLUTE / V_BASE) - U_MIN) / ((U_MAX - U_MIN) * (OSM_SET - OSM_THR))
    print("     V_min = %.1f / %.1f = %.6f L/day   (was 0.5, an 18%% underestimate)"
          % (SOLUTE, U_MAX, v_min))
    print("     k_adh = (%.6f - %.0f) / ((%.0f - %.0f) * %.0f) = %.6g"
          % (SOLUTE / V_BASE, U_MIN, U_MAX, U_MIN, OSM_SET - OSM_THR, k_adh))

    # The identities the ledger stores, checked here as well as in check_closure.py.
    assert abs(co["male"] - 8570.88) < 1e-9
    assert abs(co["female"] - 7020.0) < 1e-9
    assert abs(round(v_min, 3) - 0.611) < 1e-9
    assert abs(float("%.5g" % k_adh) - 0.10835) < 1e-9

    print("\nWHAT MOVED IN THE MODEL")
    print("     nominal MAP, SBP, DBP: unchanged BY CONSTRUCTION - TPR0 is derived from")
    print("     MAP0/CO0 and C_art from SV0/PP0, so the operating point cannot move.")
    print("     default salt-step shift: 5.0569 before, 5.056918 after - unchanged at the")
    print("     fifth significant figure,")
    print("     against a 19% rise in cardiac output. With the ADH loop DISABLED it moves")
    print("     0.6% (4.9352 -> 4.9067), because the placeholder pins urine output and")
    print("     forces sodium balance to close through the circulation instead.")
    print("     male and female cardiac output now differ by 22%. Arterial pressure does")
    print("     not differ at all; the ECF excursion differs by 6.9%.")


if __name__ == "__main__":
    main()
