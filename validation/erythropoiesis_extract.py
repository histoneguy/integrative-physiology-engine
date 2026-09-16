"""
Red cell mass as a state - the search.

Pre-registered in validation/erythropoiesis_prereg.md, committed BEFORE any source was
opened. Verify the ordering with

    git log --diff-filter=A -- validation/erythropoiesis_prereg.md
    git log --diff-filter=A -- validation/erythropoiesis_extract.py

Run:  python validation/erythropoiesis_extract.py

VERDICT: AN AMENDMENT TO E1/E2, RECORDED IN SECTION 6 BELOW. The lifespan sources
independently; the loop gain does NOT source but is ESTIMATED against a human
recovery time course, which is neither of the two cases the decision rule wrote down.
"""

# ---------------------------------------------------------------------------
# 1. LIFESPAN - SOURCED, AND THE CONVENTIONAL 120 DAYS IS A TEACHING NUMBER
# ---------------------------------------------------------------------------
LIFESPAN = dict(
    conventional=120.0,
    reading_level="SEARCH SUMMARY of the biotin-labelling literature - primaries not opened",
    measured=("Biotin-labelled transfused red cells give a mean lifespan of 132 days "
              "(95% CI 120-146) for FRESH blood and 124 days (95% CI 109-142) for "
              "stored blood."),
    finding=("THE ROUND 120 IS THE CONVENTION AND THE MEASUREMENTS SIT ABOVE IT. "
             "Directive 1.12 for the umpteenth time: 120 days is 'considered standard', "
             "and where the quantity is actually labelled and followed it comes out "
             "nearer 124-132. The conventional figure is not the centre of the measured "
             "range, it is below its lower confidence bound for fresh cells."),
    caveat=("These are POST-TRANSFUSION survivals, so they carry a storage lesion that "
            "autologous cells in situ do not - which is why fresh outlives stored by 8 "
            "days. The in-vivo autologous number is therefore at or above the fresh "
            "figure, and 132 is a floor rather than a centre."),
)

# ---------------------------------------------------------------------------
# 2. THE RECOVERY TIME COURSE - THE RIGHT PREPARATION, AND IT IS THIS MODEL'S
#    OWN PERTURBATION PERFORMED ON PURPOSE
# ---------------------------------------------------------------------------
POTTGIESSER = dict(
    citation=("Pottgiesser T, Specker W, Umhau M, Dickhuth H-H, Roecker K, Schumacher YO. "
              "Recovery of hemoglobin mass after blood donation. Transfusion 2008. "
              "PMID 18466177."),
    reading_level="ABSTRACT READ IN FULL via E-utilities; full text not opened",
    n=29, sex="male", age="30 +/- 10 years",
    donated_mL=550.0,
    hb_mass_lost_g=75.0, hb_mass_lost_sd_g=15.0,
    hb_mass_lost_pct=8.8, hb_mass_lost_pct_sd=1.9,
    recovery_days=36.0, recovery_sd_days=11.0, recovery_range=(20.0, 59.0),
    method="optimised carbon monoxide rebreathing",
    why_this_one=(
        "IT IS THE MODEL'S OWN HAEMORRHAGE PERTURBATION, PERFORMED DELIBERATELY IN "
        "HEALTHY PEOPLE. A known volume of whole blood removed, the deficit quantified, "
        "and the return followed within subject. Nothing in the orthostatic or "
        "critical-care literature comes close to that design for this purpose. "
        "AND THE METHOD IS THE SAME FAMILY AS THIS MODEL'S BLOOD VOLUME ROW - "
        "CV.BLOOD_VOLUME.NOMINAL is Oberholzer 2024 by CO rebreathing - so the two "
        "compose without the scale mismatch section 3.26 records."),
    not_in_abstract="iron status and supplementation are not stated",
)

# ---------------------------------------------------------------------------
# 3. THE CONFOUND, NAMED - THIS IS NOT A PURE ERYTHROPOIETIC GAIN
# ---------------------------------------------------------------------------
IRON_CONFOUND = (
    "DONATION REMOVES IRON AS WELL AS CELLS, and iron availability - not erythropoietic "
    "drive - is what limits recovery in many donors. The same literature reports "
    "recovery periods exceeding 300 DAYS in women under 30, against 36 days in these "
    "men, and women lose about 12% of haemoglobin mass per donation against about 7% in "
    "men. A gain estimated from this recovery is therefore a LUMPED recovery gain that "
    "includes iron supply, not an isolated erythropoietin-to-erythron gain. "
    "THAT IS THE SAME LUMPING K.EXCRETION_EXPONENT CARRIES - it folds aldosterone, "
    "distal flow and plasma potassium together because no human study separates them - "
    "and it must be written on the row in the same way: THE MODEL CANNOT DISTINGUISH AN "
    "ERYTHROPOIETIC DEFECT FROM IRON DEFICIENCY."
)

# ---------------------------------------------------------------------------
# 4. WHY ALTITUDE POLYCYTHAEMIA WAS REJECTED - BRANCH E3 DOES NOT FIRE
# ---------------------------------------------------------------------------
ALTITUDE_REJECTED = (
    "Section 7 branch E3 admitted altitude polycythaemia in principle, as the one "
    "setting where the closed loop is traced rather than perturbed once. IT IS "
    "REJECTED, and not for the reason the branch anticipated. The haemoglobin response "
    "to chronic hypoxia is POPULATION-SPECIFIC: Andean natives show it and an empirical "
    "haemoglobin-versus-oxygen-tension function exists for them, while Ethiopian Amhara "
    "highlanders do NOT have elevated haemoglobin despite normal saturation and arterial "
    "oxygen. A gain extracted there would describe one population's genetic adaptation, "
    "not a species-level erythropoietic response - and the model has no ancestry. "
    "The branch worried about altitude-SPECIFIC numbers; the real problem is that the "
    "phenotype is qualitatively absent in some healthy humans."
)

# ---------------------------------------------------------------------------
# 5. THE ARITHMETIC THAT MAKES THE GAIN ESTIMABLE
# ---------------------------------------------------------------------------
def loop_time_constant(lifespan_days: float, gain: float) -> float:
    """With production = production0*(1 + G*deficit) and first-order destruction,

           D(x) = (1/L)[1 + G(1-x)] - x/L = (1+G)(1-x)/L

    so the deficit decays with time constant L/(1+G). The lifespan alone would give
    L; the feedback speeds it by exactly (1+G).
    """
    return lifespan_days / (1.0 + gain)


def gain_for_recovery(lifespan_days: float, tau_days: float) -> float:
    return lifespan_days / tau_days - 1.0


# HOW MUCH OF THE 36 DAYS IS ONE TIME CONSTANT IS THE AMBIGUITY, AND IT IS REAL.
# "Recovered after 36 days" is a return to baseline, not a time constant. How many
# time constants that represents depends on the precision at which return was
# declared, and CO rebreathing resolves haemoglobin mass to roughly 2%.
RECOVERY_INTERPRETATIONS = [
    ("deficit gone to within measurement noise (8.8% -> 2%, 1.48 tau)", 36.0 / 1.48),
    ("conventional full recovery (3 tau)", 36.0 / 3.0),
]

# ---------------------------------------------------------------------------
# 6. THE AMENDMENT - THE CASE THE DECISION RULE DID NOT HAVE
# ---------------------------------------------------------------------------
AMENDMENT = (
    "SECTION 7 OFFERED E1 (lifespan AND gain both source -> build) and E2 (lifespan "
    "sources, gain does not -> BUILD NOTHING, because a balance whose production is "
    "INVENTED is one where production does all the work). The case that arose is "
    "neither: the lifespan sources independently, and the gain is neither sourced nor "
    "invented but ESTIMATED AGAINST A HUMAN RECOVERY TIME COURSE. "
    "|| E2's reasoning does not apply. Its objection is to an invented production term, "
    "and Pottgiesser is a measurement in 29 healthy men by a method this ledger already "
    "uses. This is the structure ADR 0021 used for RN.MD.RENIN_GAIN against van den "
    "Bosch, and ADR 0010 used for CV.ANP.NATRIURETIC_GAIN against the salt step. "
    "|| SO: BUILD IT, with the lifespan SOURCED and the gain ESTIMATED, and Pottgiesser "
    "declared an ESTIMATION SET that may never be reported as agreement. "
    "|| THE TEST OF AN AMENDMENT IS WHETHER IT COULD HAVE FLATTERED THE RESULT "
    "(section 3.25). This one COSTS a test rather than buying one: falsifiable test 2 "
    "becomes a fit in its MAGNITUDE and survives only as a claim about DIRECTION - the "
    "recovery unwinds rather than settling - which is what the pass exists to fix but is "
    "weaker than what was written down."
)

# ---------------------------------------------------------------------------
# 7. WHAT IS LEFT THAT CAN ACTUALLY FAIL
# ---------------------------------------------------------------------------
SURVIVING_TESTS = [
    ("operating point unchanged", "construction, but it can still break"),
    ("two timescales visibly different", "partly construction"),
    ("anaemia raises production while arterial SATURATION does not move",
     "GENUINE - section 3.27's content-versus-tension distinction must survive the "
     "loop closing, and nothing is fitted to it"),
    ("coupling count 21 -> 22, outbound from blood",
     "ADR 0018's own tripwire coming due"),
    ("THE SEX DIFFERENCE IS OUT OF SAMPLE",
     "The same literature reports women losing about 12% of haemoglobin mass per "
     "donation against about 7% in men. The model has SEXED blood volume and "
     "haematocrit and is told nothing about donation, so the fractional loss for a "
     "fixed donated volume is a PREDICTION it makes from the sexed volumes alone. "
     "Nothing here is fitted to it."),
]


# ---------------------------------------------------------------------------
# WRITTEN AFTER THE BUILD AND MARKED AS SUCH. Everything above this line was
# written before the model was touched; this block is the outcome, kept here so
# the file records what the search was worth rather than only what it claimed.
# ---------------------------------------------------------------------------
POSTSCRIPT = [
    "THE PRE-REGISTRATION SECTION 4 WAS WRONG, AND THE TEST SUITE CAUGHT IT.",
    "It committed to ARTERIAL OXYGEN CONTENT as the sensed signal. Content is a",
    "CONCENTRATION: expand the plasma and it falls with no red cell lost, so the",
    "loop read a salt load as anaemia. Measured with that signal in place, across",
    "the 205 -> 103 mEq/day salt step, red cell volume moved 2.546 -> 2.507 L and",
    "chronic salt sensitivity went 2.98 -> 4.24 - a 42 percent shift in the model",
    "headline result, and HANDOVER section 3.8 defect returning through a",
    "different door five weeks after it was closed.",
    "",
    "DELIVERY WAS TRIED AND IS NOT AVAILABLE HERE. CO*CaO2 is the right reduction,",
    "but this model cardiac output is far too insensitive to blood volume to",
    "supply the compensation - the venous return term gives an elasticity of 0.22 -",
    "so delivery still carried three quarters of the dilution artefact.",
    "",
    "THE LOOP THEREFORE REGULATES OXYGEN CAPACITY, NOT CONCENTRATION:",
    "    o2_deficit = 1 - (SaO2/SaO2_0) * (V_rbc / (Hct*BV0))",
    "deliberately NOT normalised by blood volume. Saturation stays in it, and that",
    "is the only reason pre-registered falsifiable test 5 - an outbound edge from",
    "blood - survived the correction at all. A correction that was right could have",
    "failed a test that was written down first, and nearly did.",
    "",
    "AND IT PAID: the capacity deficit is proportional to the red cell mass deficit",
    "with a coefficient of ONE, so the closed loop runs at lifespan/(1+G) = 24 days",
    "exactly - the row G was derived from. Under the content signal the coefficient",
    "is (1-Hct) = 0.55, the loop would have run at 33 days against a derived 24, and",
    "the ledger would have been asserting an identity the model did not satisfy.",
    "That is failure mode 22 and it would have been silent.",
    "",
    "THE HONEST LEDGER ON THIS SEARCH: the lifespan is entered ASSUMED, not",
    "reported, because no biotin-labelling primary was opened - directive 1.5. The",
    "search says the real figure is HIGHER than the conventional 120, near 132 with",
    "a 95 percent CI of 120-146, so directive 1.12 shape again but low rather than",
    "high this time. It barely matters: only lifespan/(1+gain) is identified by the",
    "recovery data, and nothing in this model reads the steady-state erythropoietic",
    "turnover.",
]


def main():
    print("=" * 78)
    print("RED CELL MASS AS A STATE - SEARCH RESULT")
    print("Pre-registered in validation/erythropoiesis_prereg.md")
    print("=" * 78)

    print("\n1. LIFESPAN")
    print("-" * 78)
    print("  conventional:", LIFESPAN["conventional"], "days")
    print("  [" + LIFESPAN["reading_level"] + "]")
    print("  " + LIFESPAN["measured"])
    print("  " + LIFESPAN["finding"])
    print("  " + LIFESPAN["caveat"])

    print("\n2. THE RECOVERY TIME COURSE")
    print("-" * 78)
    p = POTTGIESSER
    print("  " + p["citation"])
    print("  [" + p["reading_level"] + "]")
    print(f"  n = {p['n']} {p['sex']}, {p['age']}; {p['donated_mL']:.0f} mL donated")
    print(f"  haemoglobin mass lost {p['hb_mass_lost_g']:.0f} +/- {p['hb_mass_lost_sd_g']:.0f} g "
          f"({p['hb_mass_lost_pct']} +/- {p['hb_mass_lost_pct_sd']}%)")
    print(f"  recovered in {p['recovery_days']:.0f} +/- {p['recovery_sd_days']:.0f} days, "
          f"range {p['recovery_range'][0]:.0f}-{p['recovery_range'][1]:.0f}")
    print("  method:", p["method"])
    print("  " + p["why_this_one"])
    print("  NOT IN THE ABSTRACT:", p["not_in_abstract"])

    print("\n3. THE CONFOUND")
    print("-" * 78)
    print("  " + IRON_CONFOUND)

    print("\n4. ALTITUDE REJECTED")
    print("-" * 78)
    print("  " + ALTITUDE_REJECTED)

    print("\n5. THE GAIN, AND ITS HONEST RANGE")
    print("-" * 78)
    print("  tau = lifespan / (1 + G), so G = lifespan/tau - 1.")
    for L in (120.0, 132.0):
        print(f"\n  at a lifespan of {L:.0f} days:")
        for label, tau in RECOVERY_INTERPRETATIONS:
            print(f"    {label:<58} tau={tau:5.1f} d  ->  G = {gain_for_recovery(L, tau):5.2f}")
    print("\n  THE INTERPRETATION SPANS ROUGHLY FOURFOLD AND THAT IS THE ROW'S REAL")
    print("  UNCERTAINTY, not a confidence interval. It is entered as a range.")

    print("\n6. THE AMENDMENT")
    print("-" * 78)
    print("  " + AMENDMENT)

    print("\n7. WHAT CAN STILL FAIL")
    print("-" * 78)
    for name, note in SURVIVING_TESTS:
        print(f"  * {name}\n      {note}")

    print("\n" + "=" * 78)
    print("\n8. WHAT THE BUILD THEN FOUND, ADDED 2026-09-16 AFTER THE FACT")
    print("-" * 78)
    for line in POSTSCRIPT:
        print("  " + line)

    print("\n" + "=" * 78)
    print("VERDICT: BUILD, under the amendment. Lifespan ASSUMED, gain DERIVED,")
    print("         and the pre-registered SENSED SIGNAL falsified by the suite.")
    print("=" * 78)


if __name__ == "__main__":
    main()
