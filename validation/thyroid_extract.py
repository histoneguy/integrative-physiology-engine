#!/usr/bin/env python3
"""
The thyroid axis: BRANCH T3. The feedback slope cannot be sourced unambiguously,
so the axis is NOT built and no ledger row is entered.

    python validation/thyroid_extract.py

Pre-registered in validation/thyroid_prereg.md, written before any abstract was read
and sitting before this file in history. Structure proposed in ADR 0019, which stays
Proposed and unimplemented.

    git log --diff-filter=A -- validation/thyroid_prereg.md
    git log --diff-filter=A -- validation/thyroid_extract.py

THIS IS A NULL RESULT AND IT IS THE PRE-REGISTRATION WORKING. The slope exists, it is
published, and it is measured in the right preparation. What is missing is the base of
one logarithm - and the only way to resolve it from what can be opened is to pick
whichever base puts the euthyroid point inside the reference range, which section 6 of
that document forbids in terms.
"""


def rule(c="="):
    print(c * 78)


rule()
print("1. THE SLOPE WAS FOUND, IN THE RIGHT PREPARATION, AND IT CANNOT BE USED")
rule()
for line in [
    "  Benhadi N, Fliers E, Visser TJ, Reitsma JB, Wiersinga WM. Pilot study on the",
    "  assessment of the setpoint of the hypothalamus-pituitary-thyroid axis in healthy",
    "  volunteers. Eur J Endocrinol 2010;162(2):323-9. doi:10.1530/EJE-09-0655.",
    "  PMID 19926783. ABSTRACT ONLY - Europe PMC reports isOpenAccess=N, no PMC record.",
    "",
    "  21 healthy volunteers, 9 male and 12 female, mean age 60. Randomised to placebo,",
    "  125 or 250 ug T4, or placebo, 25 or 50 ug T3, at two-week intervals. Admissible",
    "  under validation/thyroid_prereg.md section 2 on every criterion.",
    "",
    "      log TSH = 1.50 - 0.059 x FT4        P < 0.05, whole group",
    "      log TSH = 0.790 - 0.245 x T3        P < 0.001, whole group",
    "",
    "  THE ABSTRACT DOES NOT STATE THE BASE OF THE LOGARITHM, AND IT CHANGES EVERYTHING.",
]:
    print(line)

print()
print("  %-10s %-14s %-14s %s" % ("FT4", "TSH if log10", "TSH if ln", "reference 0.4-4.0"))
import math
for ft4 in (12.0, 15.0, 18.0, 20.0, 22.0, 25.0):
    y = 1.50 - 0.059 * ft4
    t10, tln = 10.0 ** y, math.exp(y)
    print("  %-10.0f %-14.2f %-14.2f %s" % (
        ft4, t10, tln,
        "log10 in" if 0.4 <= t10 <= 4.0 else "",
    ))

print()
for line in [
    "  BOTH READINGS ARE PHYSIOLOGICALLY ARGUABLE AND THEY DISAGREE ABOUT WHERE A",
    "  EUTHYROID PERSON SITS.",
    "",
    "    Reading it as log10 puts the euthyroid FT4 at the TOP of a typical 10-22 pmol/L",
    "    reference interval - a mid-range TSH of 1.5 needs FT4 = 22.4.",
    "",
    "    Reading it as ln puts euthyroid FT4 at 18.6 pmol/L, comfortably mid-range, which",
    "    looks better - but then extrapolating to FT4 = 0 caps TSH at 4.5 mIU/L, and",
    "    untreated hypothyroidism reaches the tens to hundreds. log10 gives 31.6 there,",
    "    which is at least the right order.",
    "",
    "  AND THAT SECOND ARGUMENT IS ITSELF INADMISSIBLE, WHICH IS WORTH SAYING. It",
    "  extrapolates a line fitted across a narrow euthyroid range all the way to zero -",
    "  exactly the error that produced HANDOVER section 3.22's censoring bound and again",
    "  the ADR 0017 amendment, where a chemoreflex line extrapolated below its measured",
    "  range put ventilation at 19.3 L/min against a real 6.2. TWICE IS A PATTERN AND IT",
    "  IS NOT USED HERE TO SETTLE ANYTHING.",
]:
    print(line)

print()
rule()
print("2. WHY IT IS NOT RESOLVED BY PICKING THE ONE THAT WORKS")
rule()
for line in [
    "  Section 6 of the pre-registration: 'It may not use either reference interval to",
    "  set a parameter.' Section 1: the euthyroid TSH and FT4 are the TARGETS ADR 0019's",
    "  second falsifiable test judges the loop against, and if either is used to set a",
    "  parameter that test is void.",
    "",
    "  CHOOSING THE LOG BASE BY WHICH ONE LANDS IN THE REFERENCE RANGE IS SETTING A",
    "  PARAMETER FROM THE TARGET. It would produce an axis that reproduces the euthyroid",
    "  point by construction and then reports that as agreement - which is precisely what",
    "  HANDOVER section 3.15 records happening to the Lobo endpoints, where a dataset",
    "  used for estimation was quoted back as validation for a day before anyone noticed.",
    "",
    "  A UNIT AMBIGUITY IS WORSE THAN A MISSING NUMBER, and that is the finding. A",
    "  missing number is honestly `assumed` and its absence is visible in the ledger. An",
    "  ambiguous one looks sourced, carries a real citation and a real cohort, and passes",
    "  every gate in this repository - and would be wrong by a factor of 2.3 in the",
    "  feedback gain, silently.",
]:
    print(line)

print()
rule()
print("3. WHAT ELSE WAS SEARCHED, SO IT IS NOT REPEATED")
rule()
for line in [
    "  Meier CA, Maisey MN, Lowry A, Muller J, Smith MA. Clin Endocrinol (Oxf)",
    "  1993;39(1):101-7. PMID 8348700. 21 normal volunteers plus 257 normal single",
    "  samples. Confirms the LOG-LINEAR FORM (multiple r = 0.96) and that setpoint",
    "  differs significantly between individuals while slope differs less, independent of",
    "  age and gender. NOT open access, and its regression is against T3 rather than FT4,",
    "  so it corroborates the FORM and supplies no usable FT4 slope.",
    "",
    "  Goede SL, Leow MK, Smit JW, Klein HH, Dietrich JW. Bull Math Biol 2014;76(6):",
    "  1270-87. PMID 24789568. EXCLUDED AS A MODEL. It is a mathematical modelling paper",
    "  and its parameters are model parameters. validation/targets.md and the",
    "  pre-registration both bar other models as sources, and that bar is not relaxed",
    "  because a model happens to be about the right axis.",
    "",
    "  Searches for an openable log-linear TSH-FT4 slope in a healthy euthyroid cohort",
    "  returned nothing further.",
]:
    print(line)

print()
rule()
print("4. VERDICT: BRANCH T3. THE AXIS IS NOT BUILT.")
rule()
for line in [
    "  'T3 - the feedback slope cannot be sourced in healthy euthyroid adults. The axis",
    "  is NOT built. A feedback loop with an unsourced gain is a fitted loop, and fitting",
    "  it to the reference intervals is precisely the circularity that made",
    "  RN.PRESSURE_NATRIURESIS.SLOPE a hypertensive value.'",
    "",
    "  NO LEDGER ROW IS ENTERED. NO COMPONENT IS WRITTEN. ADR 0019 STAYS PROPOSED.",
    "",
    "  WHAT WOULD DISCHARGE THIS: one full text. Eur J Endocrinol 2010;162(2):323-9,",
    "  where the axis of Figure/Table reporting the regression will state the units. It",
    "  joins Crapo 1999 on the list of single articles that would each unblock real work",
    "  - that one discharges three assumed rows across two subsystems, this one unblocks",
    "  an entire axis.",
    "",
    "  AND RESP.CO2.PRODUCTION STAYS A PRIMITIVE. The reason thyroid was chosen first was",
    "  that it drives resting metabolic rate, which is the load ADR 0017's respiratory",
    "  loop balances and which is currently assumed at a round teaching number. That",
    "  connection is the whole argument for this axis over cortisol or glucose, and it is",
    "  not made tonight.",
    "",
    "  THE COST OF STOPPING IS ONE EVENING. The cost of not stopping is a feedback gain",
    "  that is wrong by 2.3x, looks fully sourced, and sits underneath every metabolic",
    "  number the model would go on to produce.",
]:
    print(line)
print()
