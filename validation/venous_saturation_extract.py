#!/usr/bin/env python3
"""
MIXED VENOUS SATURATION AND THE OXYGEN EXTRACTION RATIO - BRANCH V3.

Pre-registered in validation/venous_saturation_prereg.md, committed at 7943cdb BEFORE
this file existed and before any search was run. Verify:

    git log --diff-filter=A -- validation/venous_saturation_prereg.md
    git log --diff-filter=A -- validation/venous_saturation_extract.py

NO VALUE IS ENTERED BY THIS PASS AND NO LEDGER ROW IS CREATED. That is the result,
not a failure to reach one, and section 6 branch V3 named it in advance.

This file exists because branch V3 requires the EXACT SEARCH TERMS to be recorded -
HANDOVER section 3.33 is what happens when a failed search is written up as a fact
about the literature, and this pass was approved partly to correct that class of error
in OPEN-QUESTIONS B8.
"""

SEP = "=" * 80

# Every query run, verbatim, against the Europe PMC REST search API on 2026-09-08.
QUERIES = [
    'TITLE_ABS:"right heart catheterization" AND (TITLE_ABS:"normal subjects" OR '
    'TITLE_ABS:"healthy") AND TITLE_ABS:"rest"',
    'TITLE_ABS:"resting" AND TITLE_ABS:"h?emodynamic" AND TITLE_ABS:"normal" AND '
    '(TITLE_ABS:"reference values" OR TITLE_ABS:"healthy subjects")',
    'AUTH:"Barratt-Boyes" AND TITLE_ABS:"oxygen saturation"',
    'TITLE:"oxygen saturation" AND (TITLE:"pulmonary artery" OR TITLE:"right heart") '
    'AND (TITLE:"healthy" OR TITLE:"normal")',
    'TITLE_ABS:"cardiac catheterization" AND TITLE_ABS:"normal subjects" AND '
    'TITLE_ABS:"cardiac output" AND TITLE_ABS:"oxygen"',
    'TITLE_ABS:"arteriovenous oxygen difference" AND (TITLE_ABS:"healthy" OR '
    'TITLE_ABS:"normal") AND TITLE_ABS:"rest" AND OPEN_ACCESS:Y',
    'TITLE_ABS:"mixed venous oxygen saturation" AND (TITLE_ABS:"healthy volunteers" '
    'OR TITLE_ABS:"normal subjects" OR TITLE_ABS:"reference")',
    '(TITLE_ABS:"cardiac magnetic resonance" OR TITLE_ABS:"magnetic resonance") AND '
    'TITLE_ABS:"thermodilution" AND (TITLE_ABS:"cardiac output" OR '
    'TITLE_ABS:"stroke volume")',
    'AUTH:"Kovacs G" AND TITLE_ABS:"healthy" AND TITLE_ABS:"pulmonary" AND '
    '(TITLE_ABS:"rest" OR TITLE_ABS:"systematic review")',
]

# What the model predicts, from three sourced rows and nothing fitted.
MODEL = {"VO2 mL/min": 228.0, "CaO2 mL/dL": 20.887, "CO L/min": 5.951,
         "avDO2 mL/dL": 3.831, "SvO2": 0.8014, "ER": 0.1834}


def rule():
    print(SEP)


def main():
    rule()
    print("MIXED VENOUS SATURATION: BRANCH V3, INDETERMINATE, AND NO ROW IS ENTERED")
    rule()
    print("  The model's prediction, from three independently sourced rows:")
    for k, v in MODEL.items():
        print("     %-14s %10.4g" % (k, v))
    print()
    print("  Oxygen consumption is Weir's equation on a 197-study meta-analysis, arterial")
    print("  content follows a sourced dissociation curve, cardiac output is heart rate")
    print("  times a tier-A cardiac-magnetic-resonance stroke volume. NOTHING IS FITTED,")
    print("  so the extraction ratio is a genuine three-source prediction.")
    print()

    rule()
    print("1. THE SEARCH, RECORDED VERBATIM BECAUSE BRANCH V3 REQUIRES IT")
    rule()
    for q in QUERIES:
        print("  %s" % q)
    print()
    print("  Europe PMC REST search API, 2026-09-08. HANDOVER section 3.33 is why these")
    print("  are printed rather than summarised: a search recorded as failed becomes a")
    print("  fact about the literature the moment nobody can see what was asked.")
    print()

    rule()
    print("2. WHAT THE LITERATURE IS, AND DIRECTIVE 1.7 FOR THE SEVENTH SUBSYSTEM")
    rule()
    for line in [
        "  SECTION 2 OF THE PRE-REGISTRATION PREDICTED THIS EXACTLY. Mixed venous blood",
        "  requires a PULMONARY ARTERY CATHETER, and healthy volunteers are not",
        "  catheterised, so the measurement exists BECAUSE THE PATIENT IS ILL.",
        "",
        "  Every modern hit is an inadmissible population: intensive care, cardiac",
        "  surgery, off-pump coronary bypass, liver transplantation, paediatric",
        "  anaesthesia, COPD, pulmonary hypertension, pulmonary arterial hypertension.",
        "  The preparation is the instrument in all of them.",
        "",
        "  THE ADMISSIBLE SOURCE EXISTS AND COULD NOT BE OPENED:",
        "",
        "    Barratt-Boyes BG, Wood EH. The oxygen saturation of blood in the venae",
        "    cavae, right-heart chambers, and pulmonary vessels of healthy subjects.",
        "    J Lab Clin Med 1957;50(1):93-106. PMID 13439270. NOT open access, NO",
        "    abstract in Europe PMC, and no route reached the text.",
        "",
        "  That is almost certainly where the textbook 75 percent comes from. It is",
        "  named here so the next reader chases the right paper rather than the phrase.",
    ]:
        print(line)
    print()

    rule()
    print("3. THE FINDING BRANCH V3 DID NOT ANTICIPATE, AND IT IS THE USEFUL ONE")
    rule()
    for line in [
        "  IN HEALTHY SUBJECTS THE ARTERIOVENOUS OXYGEN DIFFERENCE IS NEVER MEASURED.",
        "  IT IS COMPUTED, AS VO2 / CO.",
        "",
        "  Every non-invasive healthy study found - impedance cardiography, rebreathing,",
        "  bioreactance - obtains the a-v difference by dividing oxygen uptake by a",
        "  cardiac output it measured some other way. THAT IS THE SAME COMPOSITION THIS",
        "  MODEL PERFORMS. It cannot test the model; it can only tell you which",
        "  cardiac-output method was used.",
        "",
        "  SO THE MODEL'S EXTRACTION RATIO IS, IN HEALTH, NOT INDEPENDENTLY MEASURABLE",
        "  BY ANY METHOD SHORT OF A PULMONARY ARTERY CATHETER. B8 is not a defect that",
        "  has gone unproven; it is a comparison that cannot currently be made.",
        "",
        "  This is the same shape as the fluid-deprivation comparison, which was",
        "  RECLASSIFIED AS INDETERMINATE RATHER THAN FAILED, and for the same reason:",
        "  the target cannot separate a model defect from a method mismatch.",
    ]:
        print(line)
    print()

    rule()
    print("4. B8's SECOND ASSERTION - THE METHOD BIAS - IS HALF RIGHT AND THE WRONG HALF")
    rule()
    for line in [
        "  B8 said 'CMR is known to read stroke volume higher' and cited nothing.",
        "",
        "    Crowe LA, Genecand L, Hachulla AL, Noble S, Beghetti M, Vallee JP, Lador F.",
        "    Non-Invasive Cardiac Output Determination Using Magnetic Resonance Imaging",
        "    and Thermodilution in Pulmonary Hypertension. J Clin Med 2022;11(10):2717.",
        "    doi:10.3390/jcm11102717. PMID 35628843. PMC9143884. OPEN ACCESS, read in",
        "    full. 24 patients, stroke volume by MRI in six localisations against",
        "    thermodilution, Bland-Altman agreement analysis.",
        "",
        "  ADMISSIBLE FOR THE BIAS ONLY, and section 5 of the pre-registration says so in",
        "  advance: the quantity is the disagreement between two methods, and pulmonary",
        "  hypertension is not the instrument for that.",
        "",
        "  WHAT IT FOUND: no MRI localisation was interchangeable with thermodilution,",
        "  with 2SD of bias between 24.1 and 31.1 mL/beat - on a stroke volume of order",
        "  90 mL that is about +/- 30 percent. THE METHODS DISAGREE ENORMOUSLY.",
        "",
        "  WHAT IT DID NOT FIND: a direction. The paper reports poor AGREEMENT, not a",
        "  systematic CMR overestimate, and explicitly suggests 'TD is less precise than",
        "  previously thought' - which points at thermodilution, not at CMR.",
        "",
        "  SO B8's MECHANISM SURVIVES IN ITS WEAK FORM AND DIES IN ITS STRONG ONE.",
        "  Composing a CMR cardiac output with a thermodilution-era saturation is indeed",
        "  illegitimate, because the two do not agree. But B8 used that to conclude the",
        "  MODEL is high, and nothing supports which side is wrong. The uncited claim is",
        "  corrected in both directions, which is what section 8 required.",
    ]:
        print(line)
    print()

    rule()
    print("5. WHAT IS DECIDED, AND WHAT IS NOT")
    rule()
    for line in [
        "  BRANCH V3. B8 CLOSES AS INDETERMINATE, NOT AS RESOLVED AND NOT AS A DEFECT.",
        "  The model's prediction stands unjudged.",
        "",
        "  CV.SV.NOMINAL IS NOT TOUCHED. Section 7 forbids it under every branch, and",
        "  nothing found here would have justified it in any case.",
        "",
        "  NO ROW IS ENTERED. There is no admissible number to enter, and entering the",
        "  textbook 0.23 with a citation to a review that got it from Barratt-Boyes",
        "  would be laundering a teaching number through a secondary source - which is",
        "  what directive 1.12 exists to stop.",
        "",
        "  WHAT WOULD RESOLVE IT, in order of value:",
        "    1. A healthy cohort reporting cardiac output AND oxygen consumption in the",
        "       same subjects by ONE method family. Branch V4, never found.",
        "    2. Barratt-Boyes and Wood 1957 in full - the origin of the 75 percent, with",
        "       its cohort, its method and its dispersion.",
        "    3. A method-matched comparison in HEALTH rather than in pulmonary",
        "       hypertension, which would tell us which of CMR and thermodilution to",
        "       believe.",
        "",
        "  AND THE PASS DID WHAT SECTION 0 SAID IT COULD: it exonerated the model rather",
        "  than convicting it, and the possibility was written down before the search.",
    ]:
        print(line)
    print()
    rule()
    print("ENTER: nothing. B8 -> INDETERMINATE. CV.SV.NOMINAL unchanged.")
    rule()


if __name__ == "__main__":
    main()
