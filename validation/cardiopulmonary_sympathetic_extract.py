"""
Cardiopulmonary receptors and renal sympathetic traffic - the search.

Pre-registered in validation/cardiopulmonary_sympathetic_prereg.md, committed BEFORE
any source was opened. Verify the ordering with

    git log --diff-filter=A -- validation/cardiopulmonary_sympathetic_prereg.md
    git log --diff-filter=A -- validation/cardiopulmonary_sympathetic_extract.py

Run:  python validation/cardiopulmonary_sympathetic_extract.py

VERDICT: BRANCH S3, AND A STRUCTURAL FINDING THE PRE-REGISTRATION DID NOT ANTICIPATE.
Nothing was entered. No ledger row, no relation, no model code. RN.MD.RENIN_GAIN was
not touched.

READING LEVEL, STATED FIRST BECAUSE IT BOUNDS EVERYTHING BELOW. **NO PRIMARY WAS
OPENED IN THIS PASS.** Every item is at search-summary or abstract-title level; the
Journal of Physiology review returned 403 at the publisher and a CAPTCHA at PMC.
Directive 1.5 therefore forbids entering ANY value from this pass, and none is
proposed. What the evidence IS sufficient for is stopping a build, because the two
structural claims below are consistent across several independent secondary sources
and both point the same way.
"""

# ---------------------------------------------------------------------------
# FINDING 1 - THE MANOEUVRE THE PRE-REGISTRATION RELIED ON DOES NOT DO WHAT IT SAYS
#
# Section 4 fixed, before searching, that an admissible source must SEPARATE
# cardiopulmonary from arterial baroreceptor unloading, and named low-level lower-body
# negative pressure as the way to do it. That premise is refuted.
# ---------------------------------------------------------------------------

LBNP_NOT_SELECTIVE = [
    dict(
        source=("Taylor JA et al. Differential sympathetic nerve and heart rate spectral "
                "effects of nonhypotensive lower body negative pressure. "
                "Am J Physiol Regul Integr Comp Physiol 2001;281(2):R468."),
        reading_level="SEARCH SUMMARY ONLY - not opened",
        finding=("At -5 mmHg, LBNP lowered central venous pressure with no effect on "
                 "stroke volume or systolic pressure, and MSNA rose - but it ALSO "
                 "reduced vagal heart-rate modulation, which is arterial baroreceptor "
                 "unloading. Stated as REFUTING the concept that low levels of LBNP "
                 "selectively interrogate cardiopulmonary reflexes."),
    ),
    dict(
        source=("Fu Q et al. Evidence for unloading arterial baroreceptors during low "
                "levels of lower body negative pressure in humans. "
                "Am J Physiol Heart Circ Physiol 2008. PMID 19074678."),
        reading_level="TITLE AND SEARCH SUMMARY ONLY - not opened",
        finding=("Arterial baroreceptors are CONSISTENTLY unloaded at -10 and -15 mmHg, "
                 "so selective unloading of cardiopulmonary baroreceptors cannot be "
                 "presumed at these levels. The title alone states the conclusion."),
    ),
    dict(
        source=("Lower Body Negative Pressure: Physiological Effects, Applications, and "
                "Implementation. Physiol Rev 2018 (doi 10.1152/physrev.00006.2018)."),
        reading_level="SEARCH SUMMARY ONLY - not opened",
        finding=("The authoritative review puts a date on it: before 1975 it was "
                 "generally accepted that LBNP of -20 mmHg or less exclusively unloads "
                 "the cardiopulmonary baroreceptors; work after 1985 showed carotid "
                 "baroreceptors are also unloaded, with small consistent linear heart "
                 "rate rises at -15 and -20 mmHg. THE SELECTIVE READING IS A "
                 "PRE-1975 CONVENTION that the field has already retired."),
    ),
]

# ---------------------------------------------------------------------------
# FINDING 2 - AND IT IS THE ONE THAT CHANGES THE DESIGN
#
# The pre-registration proposed a cardiopulmonary AFFERENT with a chronotropic
# EFFERENT: a neural arc. The human chronotropic response to atrial loading is
# substantially NOT a neural arc.
# ---------------------------------------------------------------------------

CHRONOTROPIC_IS_LARGELY_INTRINSIC = dict(
    human_phenomenon=(
        "Roddie IC, Shepherd JT, Whelan RF. J Physiol 1957;139(3):369-376. Passive leg "
        "elevation raised venous return in healthy volunteers and heart rate rose, IN "
        "THE ABSENCE of a rise in arterial pressure. NOT OPENED - cited here from "
        "secondary description, and no quantitative gain was obtained."),
    mechanism=(
        "The positive chronotropic response to stretch PERSISTS IN HEART TRANSPLANT "
        "RECIPIENTS and after pharmacological denervation, and is present in isolated "
        "heart, isolated right atrium, isolated sinoatrial node and SINGLE PACEMAKER "
        "CELLS. So a large part of it is intracardiac mechano-electric coupling - "
        "stretch-activated channels in the pacemaker - and not a reflex at all."),
    reading_level="SEARCH SUMMARY ONLY across several secondary sources - none opened",
    animal_quantitative=(
        "Rabbit isolated sinoatrial node cells: about 7% stretch raised spontaneous "
        "beating rate by about 5% (J Appl Physiol 2000;89:2099). Directive 1.6 admits "
        "animal data where the human experiment cannot be performed, and a human "
        "sinoatrial node cannot be stretched in isolation - but SINGLE CELLS ARE A LONG "
        "WAY FROM A WHOLE-BODY GAIN and this is recorded, not entered."),
    consequence=(
        "WHAT THE PRE-REGISTRATION CALLED A CARDIOPULMONARY AFFERENT IS, FOR HEART RATE, "
        "MOSTLY A PROPERTY OF THE HEART. If built it belongs in Cardiovascular.jl keyed "
        "to central volume, NOT in Baroreflex.jl as a neural arc - and it brings NONE of "
        "the other efferents with it. An intrinsic pacemaker property does not release "
        "renin, does not release vasopressin, and does not constrict vessels."),
)

# ---------------------------------------------------------------------------
# DIRECTIVE 1.12 - THE ROUND NUMBERS MET, AND NOT ENTERED
# ---------------------------------------------------------------------------
TEACHING_NUMBERS = [
    "Direct sinoatrial stretch raises heart rate 'as much as 15%'.",
    "The reflex contributes 'an additional 40% to 60%'.",
    "Cardiopulmonary receptors engage below -20 mmHg LBNP and arterial ones above.",
]

# ---------------------------------------------------------------------------
# THE DECISION RULE, APPLIED
# ---------------------------------------------------------------------------
VERDICT = {
    "S3 - sympathetic renin gain does NOT source independently": (
        "FIRES. The manoeuvre that would isolate the cardiopulmonary afferent does not "
        "isolate it. With one datum (van den Bosch's salt-renin ratio) and two arms, "
        "RN.MD.RENIN_GAIN and a sympathetic gain trade off freely - a fit with two knobs "
        "and no test. THE RENIN ARM IS NOT BUILT and RN.MD.RENIN_GAIN is untouched."),
    "S1 - chronotropic gain sourced in healthy adults": (
        "PARTIAL AND REDIRECTED. The phenomenon is established in humans in the right "
        "preparation (Roddie 1957, leg elevation, arterial pressure unchanged) and is "
        "the loading direction Jensen measures. But no quantitative human gain was "
        "obtained, no primary was opened, and the mechanism turns out to be largely "
        "INTRINSIC - which moves it out of the neural component entirely."),
    "S2 - non-osmotic vasopressin": (
        "POINTS TO FAILURE, NOT PURSUED. One secondary report states that low-level "
        "non-hypotensive LBNP did NOT elevate plasma vasopressin. If mild volume "
        "unloading does not move AVP, the arm is not worth building at the volume "
        "excursions this model produces. Recorded as a lead, not a conclusion."),
    "S5 - a source implies a natriuretic action": (
        "DID NOT ARISE, and section 1 would have forbidden it anyway."),
}

# ---------------------------------------------------------------------------
# WHAT THE PRE-REGISTRATION BOUGHT
# ---------------------------------------------------------------------------
WHAT_IT_PREVENTED = (
    "Without section 4's requirement that the manoeuvre SEPARATE the two afferents, the "
    "obvious build was a cardiopulmonary sympathetic arm calibrated against low-level "
    "LBNP data - which is abundant, looks clean, and measures BOTH receptor populations "
    "at once. That arm would then have been added on top of RN.MD.RENIN_GAIN, which "
    "ADR 0021 decision 7 says already absorbs it. Two double counts in one change, and "
    "every gate green: the ledger parses, the relations carry citations, the closure "
    "identities hold, the suite passes. THE ACUTE LIMB THAT WOULD HAVE CAUGHT IT WAS "
    "SPENT ON 2026-09-09 (OPEN-QUESTIONS B9).")


def main():
    print("=" * 78)
    print("CARDIOPULMONARY RECEPTORS AND RENAL SYMPATHETIC TRAFFIC - SEARCH RESULT")
    print("Pre-registered in validation/cardiopulmonary_sympathetic_prereg.md")
    print("=" * 78)
    print("\nREADING LEVEL: NO PRIMARY WAS OPENED. Everything below is search-summary or")
    print("title level. Directive 1.5 forbids entering any value from this pass, and none")
    print("is proposed. It is enough to STOP a build; it is not enough to start one.\n")

    print("FINDING 1 - LOW-LEVEL LBNP IS NOT SELECTIVE")
    print("-" * 78)
    for s in LBNP_NOT_SELECTIVE:
        print(f"  {s['source'][:72]}")
        print(f"    [{s['reading_level']}]")
        print(f"    {s['finding']}\n")

    print("FINDING 2 - THE CHRONOTROPIC EFFECT IS LARGELY INTRINSIC, NOT A REFLEX")
    print("-" * 78)
    c = CHRONOTROPIC_IS_LARGELY_INTRINSIC
    for k in ("human_phenomenon", "mechanism", "animal_quantitative", "consequence"):
        print(f"  {k.upper()}: {c[k]}\n")

    print("DIRECTIVE 1.12 - ROUND NUMBERS MET AND NOT ENTERED")
    print("-" * 78)
    for n in TEACHING_NUMBERS:
        print("  *", n)

    print("\nTHE DECISION RULE, APPLIED")
    print("-" * 78)
    for k, v in VERDICT.items():
        print(f"  {k}\n    {v}\n")

    print("WHAT THE PRE-REGISTRATION PREVENTED")
    print("-" * 78)
    print(" ", WHAT_IT_PREVENTED)

    print("\n" + "=" * 78)
    print("NOTHING ENTERED. RN.MD.RENIN_GAIN UNTOUCHED. ADR 0022 TEST 5 STANDS.")
    print("=" * 78)


if __name__ == "__main__":
    main()
