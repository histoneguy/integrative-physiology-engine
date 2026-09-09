"""
Chronotropic baroreflex — extraction and the section 6 stop condition.

Pre-registered in validation/chronotropic_baroreflex_prereg.md, which was committed
BEFORE any source was opened. Verify the ordering with

    git log --diff-filter=A -- validation/chronotropic_baroreflex_prereg.md
    git log --diff-filter=A -- validation/chronotropic_baroreflex_extract.py

NO COMMIT SHA IS CITED, DELIBERATELY - rebase-merge rewrites it, and every such
citation already in this repository points at a commit main does not contain.

Run:  python validation/chronotropic_baroreflex_extract.py

WHAT THIS PASS DID AND DID NOT DO
  It ran the search. It entered NO ledger row and changed NO model code. The
  verdict is branch C1 - build - and building is the next pass.

READING LEVEL IS RECORDED FOR EVERY SOURCE, per prereg section 11. Directive 1.5:
never write a citation you have not opened. Where a claim rests on a search-engine
summary of a paper rather than on the paper, it says so and is NOT treated as
sourced.
"""

# ---------------------------------------------------------------------------
# SECTION 6 - THE STOP CONDITION. Checked FIRST, before any sensitivity value,
# because the pre-registration made it the condition on proceeding at all.
#
# THE QUESTION: is BR.OPEN_LOOP_GAIN = 2.0 the gain of the WHOLE reflex, or of
# the vasomotor arm alone? If the whole reflex, a second effector does not extend
# the model, it doubles it - section 5 item 22, written down before the
# implementation instead of after it.
# ---------------------------------------------------------------------------

YAMASAKI = dict(
    citation=("Yamasaki F, Sato T, Sato K, Diedrich A. Analytic and integrative "
              "framework for understanding human sympathetic arterial baroreflex "
              "function: equilibrium diagram of arterial pressure and plasma "
              "norepinephrine level. Front Neurosci 2021;15:707345."),
    pmid="34335177", pmc="PMC8322947",
    reading_level="FULL TEXT, open access, read",
    # (1) The 1.0-3.5 in this ledger is NOT this paper's own measurement. It is
    #     the range this paper cites from ANIMAL work in its introduction:
    #     "Many investigators have estimated the open-loop gain of sympathetic
    #      baroreflex control of AP by perfusing vascularly isolated areas such as
    #      one carotid sinus, both carotid sinuses, or the aortic arch at various
    #      pressures while measuring AP changes in animals. The ratio of AP change
    #      to baroreceptor pressure change, i.e., open-loop gain, was reported to
    #      be between 1.0 and 3.5"
    #     cited to Kent 1972, Shoukas and Sagawa 1973, McRitchie 1976,
    #     Burattini 1994, Sato 1999a, Sunagawa 2001.
    animal_open_loop_gain_range=(1.0, 3.5),
    # (2) THE DECOMPOSITION IS THE ARGUMENT, and it comes from the paper itself.
    #     GL = GMN x GNM, where the mechanoneural arc GMN runs arterial pressure
    #     -> PLASMA NOREPINEPHRINE and the neuromechanical arc GNM runs plasma
    #     norepinephrine -> arterial pressure. The intermediate variable is
    #     noradrenergic. A VAGAL limb is CHOLINERGIC and is therefore invisible to
    #     that decomposition BY CONSTRUCTION.
    intermediate_variable="plasma norepinephrine",
    # (3) And this paper's own HUMAN measurement, which the ledger row does not
    #     mention at all - see THE FINDING ABOUT AN EXISTING ROW, below.
    human_GL_supine=5.62, human_GL_supine_sd=0.98,
    human_GL_tilt15=3.75, human_GL_tilt15_sd=0.62,
    human_n=7, human_sex="male",
    # (4) Vagal effects were pharmacologically removed in ALL protocols:
    #     "Atropine (0.4 mg.kg-1) was infused via the forearm venous line to block
    #      vagal effects during the protocol."
    vagal_blocked=True,
    # (5) The paper does NOT compare its human 5.62 with the animal 1.0-3.5 and
    #     does not explain the difference. Checked; absent from Discussion and
    #     Limitations.
    compares_human_to_animal=False,
)

# The vagal status of the cited animal preparations, WHERE IT COULD BE CHECKED.
# THIS IS SEARCH-LEVEL EVIDENCE AND IS NOT TREATED AS SOURCED. The primaries were
# not opened; what follows is what secondary description says, recorded so the
# next reader knows exactly how far it was verified.
ANIMAL_PREPARATIONS = {
    "Shoukas and Sagawa 1973, Circ Res 33:22-33":
        "described as VAGOTOMIZED dogs, with cardiac output and central venous "
        "pressure held constant by a bypass reservoir - so cardiac effects are "
        "excluded by construction. NOT OPENED, search-level only.",
    "Sato 1999a / Sunagawa 2001 (Kawada, Sugimachi, Sunagawa lineage)":
        "described as ANAESTHETIZED and VAGOTOMIZED rabbits. NOT OPENED, "
        "search-level only.",
    "Kent 1972, McRitchie 1976, Burattini 1994":
        "NOT CHECKED. Three of the six cited preparations are unverified.",
}

# THE INDEPENDENT PHYSIOLOGICAL TEST, and it is the one that settles section 6
# without resting on any unopened animal paper.
DUTOIT = dict(
    citation=("Dutoit AP, Hart EC, Charkoudian N, Wallin BG, Curry TB, Joyner MJ. "
              "Cardiac baroreflex sensitivity is not correlated to sympathetic "
              "baroreflex sensitivity within healthy, young humans. "
              "Hypertension 2010;56(6):1118-23."),
    pmid="21060001", doi="10.1161/HYPERTENSIONAHA.110.158329",
    reading_level="ABSTRACT and secondary description; full text 403 at publisher",
    n=53, men=28, women=25, age_mean=24.0, age_sem=0.9,
    resting_HR=58, resting_MAP=89,
    # THE RESULT: cardiac and sympathetic baroreflex sensitivities are UNCORRELATED
    # within individuals.
    r_squared=0.0003,
)

# ---------------------------------------------------------------------------
# SECTION 6 VERDICT: BRANCH C1 - ADD, DO NOT SPLIT.
#
# Three lines, and they do not share an assumption:
#
#   1. Yamasaki's open-loop gain is a product of two arcs whose INTERMEDIATE
#      VARIABLE IS PLASMA NOREPINEPHRINE. A cholinergic vagal limb cannot appear
#      in it. This comes from the paper that the ledger row cites, read in full.
#   2. The animal preparations behind 1.0-3.5 are vagotomized where it could be
#      checked - two of six, at search level, declared as such.
#   3. Cardiac and sympathetic baroreflex sensitivity are UNCORRELATED within
#      healthy individuals, R^2 = 0.0003 in 53 people. Two arms that vary
#      independently are not one gain to be apportioned between effectors.
#
# So the vagal chronotropic limb is GENUINELY ABSENT from this model and may be
# added without double-counting BR.OPEN_LOOP_GAIN. Branch C2 does not fire.
#
# THE RESIDUAL OVERLAP IS DECLARED AND IS NOT ZERO. "Sympathetic" includes cardiac
# sympathetic chronotropy, and the phenylephrine ramp below is PREDOMINANTLY but
# not exclusively vagal. Some small part of the cardiac limb may already sit
# inside the 2.0, routed through resistance. That is a bounded overlap, not the
# wholesale double count section 6 existed to prevent.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# THE VALUE. Prereg section 2.1 admits the pharmacological ramp and excludes
# spontaneous-sequence and spectral methods.
# ---------------------------------------------------------------------------

LAITINEN = dict(
    citation=("Laitinen T, Hartikainen J, Vanninen E, Niskanen L, Geelen G, "
              "Lansimies E. Age and gender dependency of baroreflex sensitivity "
              "in healthy subjects. J Appl Physiol 1998;84(2):576-583."),
    pmid="9475868", doi="10.1152/jappl.1998.84.2.576",
    reading_level="ABSTRACT ONLY - publisher returns 403, no PMC record",
    method="phenylephrine bolus injection",       # admissible, prereg section 2.1
    n=117, age_range=(23, 77),
    population="healthy, normal-weight, nonsmoking men and women",
    brs_male=15.0, brs_male_pm=1.2,
    brs_female=10.2, brs_female_pm=1.1,
    p_sex="<0.01",
    # DISPERSION IS NOT ENTERED AND THAT IS DELIBERATE. The abstract prints
    # "15.0 +/- 1.2" and "10.2 +/- 1.1" without saying whether that is SD or SEM.
    # At n = 117 split by sex, and against SDs near 9 reported by every other
    # study here, these are almost certainly SEM. Directive 1.9 and the
    # BF.BODY_MASS.TYPICAL precedent: where the estimator is not stated, none is
    # chosen after the fact.
    dispersion_form="UNSTATED in the abstract - not entered",
    # Its subject IS the relationship, which is what directive 1.7 asks for.
    age_correlation=-0.65,
)

WADA = dict(
    citation=("Wada N, Singer W, Gehrking TL, Sletten DM, Schmelzer JD, Kihara M, "
              "Low PA. Determination of vagal baroreflex sensitivity in normal "
              "subjects. Muscle Nerve 2014;50(4):535-540."),
    pmid="24477673",
    reading_level="FULL TEXT via PMC4115054, read",
    method="VALSALVA manoeuvre - heart period on systolic pressure, phase III-IV",
    n=166, men=73, women=93, age_range=(18, 81),
    brs_up=7.3, brs_up_sd=3.6, brs_up_range=(0.4, 18.5), brs_up_ci=(6.7, 7.8),
    brs_down=5.3, brs_down_sd=3.2,
    sex_effect="NONE - 'we did not find a gender effect in BRS indices'",
    age_regression="ln BRS_v_up = 2.72 - 0.02 * age, R^2 = 0.28",
)

BONYHAY = dict(
    citation=("Bonyhay I, Risk M, Freeman R. High-pass filter characteristics of "
              "the baroreflex - a comparison of frequency domain and "
              "pharmacological methods. PLoS One 2013;8(11):e79513."),
    pmid="24244518", pmc="PMC3828383",
    reading_level="FULL TEXT, open access, read",
    n=18, women=12, men=6, age_mean=39, age_sd=10,
    modified_oxford=15.7, modified_oxford_sd=9.2,
    transfer_function=19.4, transfer_function_sd=10.5,
    p="<0.05",
    mean_relative_difference_pct=20.7,
    typical_error=3.9, limit_of_agreement=10.8,
    across_subject_r=0.85,
)

SCHUMANN = dict(
    citation=("Schumann A, Gupta Y, Gerstorf D, Demuth I, Bar KJ. Sex differences "
              "in the age-related decrease of spontaneous baroreflex function in "
              "healthy individuals. Am J Physiol Heart Circ Physiol "
              "2024;326(1):H158-H165."),
    pmid="37947436",
    reading_level="ABSTRACT and partial text; publisher 403",
    method="SPONTANEOUS - time-domain bradycardic/tachycardic slopes and "
           "frequency-domain LF-alpha, HF-alpha",
    n=980,
    verdict="INADMISSIBLE under prereg section 2.1",
)

# ---------------------------------------------------------------------------
# THE CONVERSION. Fixed in prereg section 7.1 BEFORE any value was known, and it
# uses only rows already in this ledger.
#
#     RR (ms)          = 60000 / HR
#     BRS              = dRR/dP                       ms/mmHg, what is measured
#     (1/HR) dHR/dP    = -(HR / 60000) * BRS          fractional, per mmHg
#     G_hr             =  (HR0 * MAP_ref / 60000) * BRS   dimensionless
#
# THE CONVERSION IS LOCAL. The reciprocal between rate and interval is nonlinear,
# so this holds at the operating heart rate and nowhere else. pooling.md requires
# two rows to share a measurement SCALE and not merely a unit symbol - section 5
# item 18 - and this is the line where that is honoured or quietly broken.
# ---------------------------------------------------------------------------

HR0_MALE, HR0_FEMALE = 62.0, 65.0     # CV.HR.NOMINAL, Gonzales 2023
MAP_REF = 87.0                        # CV.MAP.SETPOINT
G_BR = 2.0                            # BR.OPEN_LOOP_GAIN, as it currently stands


def conversion_factor(hr0, map_ref=MAP_REF):
    """Dimensionless chronotropic gain per (ms/mmHg) of measured sensitivity."""
    return hr0 * map_ref / 60000.0


def g_hr(brs_ms_per_mmhg, hr0):
    return conversion_factor(hr0) * brs_ms_per_mmhg


def main():
    print("=" * 78)
    print("CHRONOTROPIC BAROREFLEX - SEARCH RESULT")
    print("Pre-registered in validation/chronotropic_baroreflex_prereg.md")
    print("=" * 78)

    print("\nSECTION 6, THE STOP CONDITION -> BRANCH C1: ADD, DO NOT SPLIT")
    print("-" * 78)
    print("  Yamasaki's open-loop gain decomposes through PLASMA NOREPINEPHRINE.")
    print("  A cholinergic vagal limb cannot appear in a noradrenergic arc.")
    print(f"  Cardiac vs sympathetic BRS in {DUTOIT['n']} healthy adults: "
          f"R^2 = {DUTOIT['r_squared']}  (uncorrelated)")
    print("  Animal preparations behind 1.0-3.5: vagotomized where checkable,")
    print("  2 of 6, at SEARCH LEVEL only - declared, not treated as sourced.")

    print("\nTHE CONVERSION, fixed in prereg 7.1 before any value was known")
    print("-" * 78)
    fm, ff = conversion_factor(HR0_MALE), conversion_factor(HR0_FEMALE)
    print(f"  male   factor = {HR0_MALE:.0f} x {MAP_REF:.0f} / 60000 = {fm:.6f} per (ms/mmHg)")
    print(f"  female factor = {HR0_FEMALE:.0f} x {MAP_REF:.0f} / 60000 = {ff:.6f} per (ms/mmHg)")

    print("\nTHE VALUE - Laitinen 1998, phenylephrine bolus, n = 117, ages 23-77")
    print("-" * 78)
    gm = g_hr(LAITINEN["brs_male"], HR0_MALE)
    gf = g_hr(LAITINEN["brs_female"], HR0_FEMALE)
    print(f"  men    BRS = {LAITINEN['brs_male']:5.1f} ms/mmHg  ->  G_hr = {gm:.4f}")
    print(f"  women  BRS = {LAITINEN['brs_female']:5.1f} ms/mmHg  ->  G_hr = {gf:.4f}")
    print(f"  against BR.OPEN_LOOP_GAIN = {G_BR:.1f}")
    print(f"    men   {100*gm/G_BR:.0f}% of the vasomotor arm")
    print(f"    women {100*gf/G_BR:.0f}% of the vasomotor arm")
    print("  PREREG 7.1 PREDICTED 'the same order' FROM THE FACTOR ALONE,")
    print("  before any source was opened. It is.")
    print(f"  Dispersion: {LAITINEN['dispersion_form']}")

    print("\nMETHOD NON-INTERCHANGEABILITY - measured, so C6 does NOT fire")
    print("-" * 78)
    print(f"  Bonyhay 2013, same {BONYHAY['n']} subjects both ways:")
    print(f"    modified Oxford    {BONYHAY['modified_oxford']} +/- {BONYHAY['modified_oxford_sd']} ms/mmHg")
    print(f"    transfer function  {BONYHAY['transfer_function']} +/- {BONYHAY['transfer_function_sd']} ms/mmHg")
    print(f"    mean relative difference {BONYHAY['mean_relative_difference_pct']}%, "
          f"limit of agreement {BONYHAY['limit_of_agreement']} ms/mmHg")
    print("  The methods do not agree WITHIN subjects. Section 2.1's exclusion of")
    print("  spontaneous and spectral sensitivities STANDS, on evidence.")

    print("\nTHE SOURCE HANDOVER NAMED IS INADMISSIBLE")
    print("-" * 78)
    print(f"  Schumann 2024, n = {SCHUMANN['n']}: {SCHUMANN['method']}")
    print(f"  -> {SCHUMANN['verdict']}, by the rule fixed BEFORE the search.")

    print("\nTHE SEX PAIR, AND A METHOD-DISCORDANT DISAGREEMENT")
    print("-" * 78)
    print(f"  Laitinen, phenylephrine, n=117: men {LAITINEN['brs_male']} vs "
          f"women {LAITINEN['brs_female']}, P {LAITINEN['p_sex']}")
    print(f"  Wada,     Valsalva,      n=166: {WADA['sex_effect']}")
    print("  Two methods, two answers. pooling.md bars pooling across them and")
    print("  section 2.1 prefers the ramp, so Laitinen governs and Wada is")
    print("  recorded as a discordant comparison rather than averaged away.")

    print("\nSECTION 8 ITEM 3 - THE OUT-OF-SAMPLE TRANSIENT, AND IT POINTS THE")
    print("WRONG WAY")
    print("-" * 78)
    print("  Jensen 2013 (PMC3849534) Table 4 DOES report pulse rate:")
    print("    baseline            54.1 (11.0) beats/min")
    print("    during 0.9% saline  57.2 (11.9)")
    print("    post infusion       56.4 - 58.0")
    print("    systolic BP         114.5 - 117.7, essentially flat")
    print("  PULSE RATE ROSE ABOUT 3 BEATS/MIN WHILE PRESSURE DID NOT RISE.")
    print("  An arterial baroreflex chronotropic arm cannot produce that: at")
    print("  err ~ 0 it predicts no change, and had pressure risen it predicts a")
    print("  FALL. The candidate mechanism is atrial stretch through")
    print("  cardiopulmonary receptors, which ADR 0009 names as a SEPARATE")
    print("  component this model does not have. This bounds what the arm may be")
    print("  claimed to reproduce; it does not refute the arm.")

    print("\nA FINDING ABOUT AN EXISTING ROW - NOT CHANGED IN THIS PASS")
    print("-" * 78)
    print("  BR.OPEN_LOOP_GAIN = 2.0 is the ANIMAL range quoted in Yamasaki's")
    print("  INTRODUCTION, and the row's note repeats his statement that human")
    print("  open-loop gain 'has not been clarified'.")
    print(f"  Yamasaki's own RESULT is a human measurement: GL = "
          f"{YAMASAKI['human_GL_supine']} +/- {YAMASAKI['human_GL_supine_sd']} "
          f"supine, n = {YAMASAKI['human_n']}, atropine-blocked.")
    print("  THE ROW QUOTES THE PAPER'S PROBLEM STATEMENT AND MISSES ITS ANSWER.")
    print("  That is section 3.13 exactly - the renin gain sat assumed for six")
    print("  days behind a sentence about a paper that said the opposite.")
    print("  NOT CHANGED HERE: 2.0 -> 5.62 moves every transient in the model,")
    print("  including the two Lobo endpoints B9 lives on. One change at a time.")

    print("\n" + "=" * 78)
    print("VERDICT: BRANCH C1. Build the arm. Nothing entered by this pass.")
    print("=" * 78)


if __name__ == "__main__":
    main()
