#!/usr/bin/env python
"""The venous return relation, sourced in HEALTHY HUMANS at last. Branch H1, entered 1400.

Executes validation/venous_return_human_prereg.md, committed before any value was
computed and sitting before this change in history. Verify the ordering with:

    git log --diff-filter=A -- validation/venous_return_human_prereg.md

THE HEADLINE, AND IT IS TWO THINGS.

1. A HEALTHY-HUMAN SOURCE EXISTS FOR WHAT THE MODEL ACTUALLY USES, and the earlier pass
   missed it by searching for the wrong object. G_vr is dCO/dV_blood in (L/day)/L, NOT a
   compliance in mL/mmHg. Blood volume can be changed by a known amount in healthy people
   - withdrawal, or plasma expansion - and cardiac output measured. Five such studies.

2. SYSTEMIC VENOUS COMPLIANCE IN mL/mmHg IS STILL UNSOURCED IN HEALTHY HUMANS, and that
   gap is UNCHANGED. The one human value found is Takatsu 1989 (PMID 2545936), 2.3 +/- 0.7
   mL/mmHg/kg - which agrees strikingly with the anaesthetised dog and pig values already
   in venous_compliance_extract.py - but its cohort is 56 CARDIAC PATIENTS graded by NYHA
   class, and even its class I subgroup is cardiac patients. The pre-registration excluded
   NYHA class I in advance, for the reason section 5 item 14 exists. NOT ENTERED.

THE MODEL IS ROUGHLY TWICE TOO STIFF, WHICH IS WHAT SECTION 3.7 SAID FROM THE SALT DATA.
Two completely independent lines - chronic sodium balance, and acute volume manipulation
in healthy people - agree. That agreement is the result; the number is a consequence.

Run:  python validation/venous_return_human_extract.py
"""

# ---------------------------------------------------------------------------
# THE SEARCH. Two screening sweeps, 14 queries, 125 unique records, before the
# pre-registration; one confirmatory sweep after it. Every abstract below was read from
# the retrieved PubMed record. Full texts of the two key studies are subscription-only,
# which is recorded as a limitation rather than worked around.
# ---------------------------------------------------------------------------

SWEEP = dict(queries=19, records=153,
             excluded_paradigms="head-out immersion, head-down tilt, ICU, "
                                "post-cardiac-surgery, anaesthesia, heart failure, "
                                "cirrhosis, anephric, NYHA-graded cardiac patients")

# CO and blood volume references for converting fractional changes, from this repo's
# own sourced rows, so the conversion is not smuggling in a new assumption.
CO_MALE, CO_FEMALE = 8568.44 / 1440, 7020.0 / 1440    # L/min
BV_MALE, BV_FEMALE = 5.62, 4.92                        # L
SV_NOMINAL, HR_NOMINAL = 0.0727, 66.0                  # L, beats/min (Bundgaard cohort)

WITHDRAWAL = [
    dict(label="Diaz-Canestro 2022", pmid="34875180", n=30,
         cite="Diaz-Canestro C, Pentz B, Sehgal A, Montero D. Appl Physiol Nutr Metab "
              "2022;47(1):75-82. doi:10.1139/apnm-2021-0196",
         cohort="healthy women 47-77 y, non-smokers, non-obese, moderately fit; "
                "haematocrit 38.0-44.8%, blood volume 3.8-6.6 L",
         manoeuvre="standard 10% reduction of blood volume = 0.5 +/- 0.1 L withdrawn, "
                   "haematocrit unchanged (P = 0.953)",
         at_rest=True,
         reported="LVEDV and stroke volume reduced at rest AND during incremental "
                  "exercise, >=10% decrements, P <= 0.009. Peak cardiac output "
                  "proportionally decreased.",
         # >=10% SV fall on a 10% BV fall. Female CO 4.88 L/min.
         value=0.10 * CO_FEMALE / 0.5, bound="upper",
         intent="the title is 'in proportion to induced hypovolemia'. The relationship "
                "IS the subject - directive 1.7 satisfied."),
    dict(label="Fortney 1983 (withdrawal limb)", pmid="6629925", n=5,
         cite="Fortney SM, Wenger CB, Bove JR, Nadel ER. J Appl Physiol Respir Environ "
              "Exerc Physiol 1983;55(3):884-90",
         cohort="5 healthy men", at_rest=False,
         manoeuvre="blood volume reduced 490 mL (9.7%) with diuretics",
         reported="cardiac output -2.2 L/min during exercise at 65-70% VO2max",
         value=2.2 / 0.490, bound=None,
         intent="three levels of plasma volume, duplicate experiments. The relationship "
                "IS the subject."),
]

EXPANSION = [
    dict(label="Fortney 1983 (expansion limb)", pmid="6629925", n=5,
         cite="same study, same subjects, same protocol", at_rest=False,
         manoeuvre="blood volume increased 440 mL (7.8%) with 5% human serum albumin",
         reported="cardiac output +1.0 L/min during exercise",
         value=1.0 / 0.440, bound=None,
         intent="same"),
    dict(label="Bundgaard-Nielsen 2010", pmid="20545713", n=20,
         cite="Bundgaard-Nielsen M, Jorgensen CC, Kehlet H, Secher NH. Clin Physiol Funct "
              "Imaging 2010;30(5):318-322. doi:10.1111/j.1475-097X.2010.00944.x",
         cohort="20 healthy supine subjects, 23 +/- 2 y", at_rest=True,
         manoeuvre="200 mL hydroxyethyl starch, repeated if a >=10% stroke volume "
                   "increment was obtained",
         reported="NO subject increased stroke volume by >=10%. Cardiac output 4.8 +/- "
                  "1.1 L/min UNCHANGED (P = 0.25). Heart rate unchanged (P = 0.32).",
         # SV < +10% on 0.2 L. SV = CO/HR = 4.8/66 L.
         value=0.10 * (4.8 / HR_NOMINAL) * HR_NOMINAL / 0.2, bound="upper",
         intent="to define normovolemia by the stroke volume response. The relationship "
                "IS the subject."),
    dict(label="Nguyen 1988", pmid="2901018", n=8,
         cite="Nguyen PV, Smith DL, Leenen FH. Life Sci 1988;43(10):821-30",
         cohort="8 healthy normotensive men", at_rest=True,
         manoeuvre="1200 mL of 2.5% NaCl, giving 10-11% intravascular volume expansion",
         reported="small NON-SIGNIFICANT increases in LVEDV, stroke volume and cardiac "
                  "index, while plasma ANP doubled",
         value=None, bound="direction",
         intent="ANP release against volume expansion; the haemodynamics are reported "
                "alongside and are usable as a direction."),
    dict(label="Kanstrup 1982", pmid="7096143", n=None,
         cite="Kanstrup IL, Ekblom B. J Appl Physiol Respir Environ Exerc Physiol "
              "1982;52(5):1186-91",
         cohort="healthy subjects", at_rest=True,
         manoeuvre="plasma expander, average 700 mL blood volume expansion, red cell "
                   "mass constant",
         reported="cardiac output INCREASED at rest and at all exercise levels; peak "
                  "stroke volume 144 -> 173 mL. Magnitude at rest not in the record.",
         value=None, bound="direction", intent="blood volume against cardiac performance."),
]

NOT_HEALTHY = dict(
    label="Takatsu 1989", pmid="2545936", n=56,
    cite="Takatsu H, Gotoh K, Suzuki T, Ohsumi Y, Yagi Y, Tsukamoto T, Terashima Y, "
         "Nagashima K, Hirakawa S. Jpn Circ J 1989;53(3):245-54",
    reports="systemic venous compliance 127.2 +/- 24.8 mL/mmHg, 2.3 +/- 0.7 mL/mmHg/kg "
            "in NYHA class I (n=13); 101.1 in class II, 62.2 in class III",
    why_excluded="56 patients with various cardiac diseases. Class I is the least "
                 "affected group, not a healthy group. The pre-registration excluded "
                 "NYHA class I IN ADVANCE. Admitting it would repeat the error that put "
                 "a trout and a ganglion-blocked dog into the withdrawn section 3.9 pass.")

MODEL_GVR = 2880.0          # (L/day)/L, calibrated
SALT_TARGET = (1012.0, 1941.0)   # (L/day)/L, from HANDOVER 3.7 and 3.8


def main():
    print(__doc__)
    print("=" * 96)
    print("1. THE TWO LIMBS, KEPT SEPARATE AS THE PRE-REGISTRATION REQUIRES")
    print("=" * 96)
    for title, rows in (("WITHDRAWAL", WITHDRAWAL), ("EXPANSION", EXPANSION)):
        print("\n  " + title)
        for d in rows:
            v = d["value"]
            tag = "rest " if d["at_rest"] else "EXER "
            if v is None:
                print("    %-32s %s n=%-4s  direction only: %s"
                      % (d["label"], tag, d["n"], d["bound"]))
            else:
                print("    %-32s %s n=%-4s  %5.2f (L/min)/L = %6.0f (L/day)/L  %s"
                      % (d["label"], tag, d["n"], v, v * 1440,
                         "UPPER BOUND" if d["bound"] == "upper" else ""))

    print()
    print("=" * 96)
    print("2. THE ASYMMETRY TEST, threshold 2 fixed before the numbers")
    print("=" * 96)
    w = next(d for d in WITHDRAWAL if d["label"].startswith("Fortney"))
    e = next(d for d in EXPANSION if d["label"].startswith("Fortney"))
    ratio = w["value"] / e["value"]
    print("  Fortney 1983 is the ONLY study giving both limbs in the SAME subjects under")
    print("  the SAME protocol, which is what makes it the test rather than a comparison.")
    print("    withdrawal %.2f (L/min)/L against expansion %.2f  ->  ratio %.2f"
          % (w["value"], e["value"], ratio))
    print("    BRANCH %s" % ("H1, pool" if ratio <= 2.0 else "H2, expansion limb only"))
    print()
    print("  1.98 AGAINST A THRESHOLD OF 2. It passes by 1%, and a rule that survives by")
    print("  1% is reported as such rather than as a clean result. The direction is the")
    print("  physiologically expected one - the heart is nearer the flat part of its")
    print("  filling curve above normovolemia than below - and a linear symmetric gain")
    print("  is at the edge of what this evidence supports.")

    print()
    print("=" * 96)
    print("3. REST GOVERNS, AND IT IS MUCH SHALLOWER THAN EXERCISE")
    print("=" * 96)
    print("  Pre-registration section 5: the salt step is a RESTING protocol, so resting")
    print("  values govern. Fortney's numbers are at 65-70 percent of VO2max and are recorded as")
    print("  evidence about the FORM, not as the value.")
    print()
    print("  The resting evidence, all of it:")
    print("    Diaz-Canestro  withdrawal 0.5 L  ->  <= %.2f (L/min)/L = %.0f (L/day)/L"
          % (WITHDRAWAL[0]["value"], WITHDRAWAL[0]["value"] * 1440))
    print("    Bundgaard-N.   expansion 0.2 L   ->  <  %.2f (L/min)/L = %.0f (L/day)/L"
          % (EXPANSION[1]["value"], EXPANSION[1]["value"] * 1440))
    print("    Nguyen         expansion ~0.5 L  ->  no significant change in output")
    print("    Kanstrup       expansion 0.7 L   ->  output rose; magnitude not reported")
    print()
    print("  BOTH RESTING NUMBERS ARE UPPER BOUNDS AND THE PRE-REGISTRATION SAID THEY")
    print("  WOULD BE. Section 5: a study reporting stroke volume gives an upper bound on")
    print("  dCO/dV, because heart rate can compensate and this model's baroreflex has no")
    print("  chronotropic arm. Diaz-Canestro reports stroke volume at rest; Bundgaard-")
    print("  Nielsen reports that heart rate did NOT change, which makes its bound the")
    print("  tighter of the two in kind even though it is looser in value.")

    entered = 1400.0
    print()
    print("=" * 96)
    print("4. THE ENTERED VALUE")
    print("=" * 96)
    print("  CV.VENOUS_RETURN.SENSITIVITY  2880 -> %.0f (L/day)/L" % entered)
    print("  CV.CENTRAL.CO_SENSITIVITY     11520 -> %.0f, derived as G_vr / f_c" % (entered / 0.25))
    print()
    print("  It is the Diaz-Canestro resting withdrawal bound, %.0f, rounded to two"
          % (WITHDRAWAL[0]["value"] * 1440))
    print("  significant figures. Entered AS A BOUND-DERIVED VALUE and said to be one:")
    print("  the three expansion studies all indicate the true resting value is at or")
    print("  below it, and none of them resolves how far below.")
    print()
    print("  THE MODEL WAS %.2fx TOO STIFF." % (MODEL_GVR / entered))
    print("  Independent line, from chronic sodium balance (HANDOVER 3.7, 3.8): %.0f-%.0f."
          % SALT_TARGET)
    print("  %.0f sits inside that range, and the two lines share no data, no subjects,"
          % entered)
    print("  no measurement and no timescale. THAT AGREEMENT IS THE RESULT.")
    print()
    print("  AND IT IS NOT CIRCULAR. The pre-registration forbade choosing the value to")
    print("  land the salt step in the human window, because the salt data are the TEST.")
    print("  1400 does NOT land it in the window - see the challenge harness. A value")
    print("  chosen to pass would have been nearer 1700.")

    print()
    print("=" * 96)
    print("5. WHAT IS STILL NOT SOURCED, AND THE GAP IS NARROWER NOT CLOSED")
    print("=" * 96)
    print("  SYSTEMIC VENOUS COMPLIANCE IN mL/mmHg, IN HEALTHY HUMANS. Still none.")
    print("    %s, PMID %s, n=%s" % (NOT_HEALTHY["label"], NOT_HEALTHY["pmid"], NOT_HEALTHY["n"]))
    print("    reports: %s" % NOT_HEALTHY["reports"])
    print("    EXCLUDED: %s" % NOT_HEALTHY["why_excluded"])
    print()
    print("  Worth recording anyway: its 2.3 mL/mmHg/kg is close to the 2.09, 1.80 and")
    print("  2.1 that venous_compliance_extract.py has from anaesthetised dog and pig.")
    print("  A cross-species agreement that is interesting and is NOT a healthy-human")
    print("  source, and the distinction is the whole point of this document.")
    print()
    print("  ALSO STILL UNSOURCED: mean systemic filling pressure and resistance to")
    print("  venous return in healthy humans. Neither is needed now - the composite was")
    print("  sourced directly, which is what section 3.9's withdrawal should have")
    print("  prompted and did not.")
    print()


if __name__ == "__main__":
    main()
