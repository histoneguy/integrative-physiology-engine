#!/usr/bin/env python
"""The filling relation, sourced as a characterised relationship.

Executes validation/venous_compliance_prereg.md, committed at d811ca0 BEFORE any
paper was opened. Written under directive 1.7.

THE ANSWER: the systemic pressure-volume relationship is LINEAR over the
physiological range, in every species measured, by independent groups using
independent methods. ADR 0012's concavity requirement is REFUTED - which
prereg section 0.3 declared in advance to be a real result and the more
consequential one.

Every citation below was read from the retrieved PubMed record; authors,
journal, year, volume and pages verified against that record.

NOTHING HERE IS A LEDGER PARAMETER. See VERDICT.

Run:  python validation/venous_compliance_extract.py
"""

# ---------------------------------------------------------------------------
# Q1 - blood volume to mean circulatory filling pressure.
# Total systemic vascular compliance, and its SHAPE.
#
# Every entry is a study designed to characterise the pressure-volume
# relationship itself. Directive 1.7 test applied and recorded per row.
# ---------------------------------------------------------------------------

Q1 = [
    dict(label="Lee 1988", pmid="3337249", species="dog", n=12,
         cite="Lee RW, Lancaster LD, Gay RG, Paquin M, Goldman S. Am J Physiol 1988;254:H115-9",
         prep="splenectomised, ganglion-blocked with hexamethonium, acetylcholine arrest",
         compliance=2.09, units="mL/mmHg/kg",
         range_="controlled haemorrhage and volume loading, +/- 10 mL/kg",
         shape="LINEAR between MCFP 5 and 12 mmHg, slope 0.479 mmHg/mL/kg, R2=0.992. "
               "NON-LINEAR below 5 mmHg, exponential P=P0*exp(kV), k=0.061, R2=0.998.",
         intent="to define total vascular capacitance. The relationship IS the subject."),

    dict(label="Rothe & Gaddis 1990", pmid="2297840", species="dog", n=10,
         cite="Rothe CF, Gaddis ML. Circulation 1990;81:360-8",
         prep="chloralose, servo-controlled reservoir, intact and hexamethonium-blocked",
         compliance=1.80, units="mL/mmHg/kg",
         range_="cardiac output driven over 50-140 mL/min/kg",
         shape="compliance NOT significantly changed by reflex blockade. Only 21% of "
               "blood volume redistribution was attributable to active reflex response.",
         intent="autoregulation of cardiac output by PASSIVE elastic characteristics. "
                "The relationship IS the subject."),

    dict(label="Ogilvie 1990", pmid="2360680", species="pig", n=7,
         cite="Ogilvie RI, Zborowska-Sluis D, Tenaschuk B. Am J Physiol 1990;258:H1925-32",
         prep="pentobarbital, balloon occlusion / ACh arrest / infusion-withdrawal",
         compliance=2.1, units="mL/mmHg/kg",
         range_="baseline, +5 and +10 mL/kg circulating volume",
         shape="three methods gave 2.1 +/- 0.3, 3.5 +/- 0.9 and 2.8 +/- 0.4. METHOD "
               "SPREAD IS LARGER THAN ANY BIOLOGICAL EFFECT REPORTED ELSEWHERE HERE.",
         intent="to measure Pmcf and vascular compliance. The relationship IS the subject."),

    dict(label="Cha 1992", pmid="1423008", species="guinea pig", n=None,
         cite="Cha SC, Aberdeen GW, Nuwayhid BS, Quillen EW. Can J Physiol Pharmacol 1992;70:669-74",
         prep="pentobarbital, open-chest, pulmonary artery constriction",
         compliance=2.1, units="mL/mmHg/kg",
         range_="+/- 5 mL blood volume",
         shape="total vascular compliance UNCHANGED by pregnancy (2.1 +/- 0.1) even "
               "though blood volume rose 55 -> 67 mL/kg. The extra volume was "
               "accommodated as UNSTRESSED volume.",
         intent="to assess circulatory fullness and its regulation. Subject."),

    dict(label="Ogilvie 1992", pmid="1288839", species="dog", n=18,
         cite="Ogilvie RI, Zborowska-Sluis D. Can J Cardiol 1992;8:1071-8",
         prep="anaesthetised, splenectomised, ACh transient circulatory arrest",
         compliance=3.4, units="mL/mmHg/kg",
         range_="saline 40 mL/kg over 10 min",
         shape="volume loading alone did NOT alter total vascular compliance. Pacing-"
               "induced failure reduced it 3.4 -> 2.5 and cut UNSTRESSED volume "
               "77 -> 57 mL/kg.",
         intent="effect of pacing and volume loading on capacitance. Subject."),

    dict(label="Maas 2012", pmid="22763909", species="HUMAN", n=15,
         cite="Maas JJ, Pinsky MR, Aarts LP, Jansen JR. Anesth Analg 2012;115:880-7",
         prep="ventilated post-cardiac-surgery, inspiratory hold + arm stop-flow",
         compliance=0.97, units="mL/mmHg/kg predicted body weight",
         range_="ten sequential 50 mL colloid boluses, i.e. 500 mL total",
         shape="**Csys WAS LINEAR** (64.3 +/- 32.7 mL/mmHg absolute). Stressed volume "
               "1265 +/- 541 mL = 28.5% +/- 15% of predicted total blood volume.",
         intent="to characterise compliance, stressed volume and cardiac function "
                "curves at the bedside. Recent, and it QUALIFIES under 1.7 - it was "
                "designed to characterise the relationships. Prereg section 0.2 fixed "
                "this exact example in advance."),
]

# ---------------------------------------------------------------------------
# Q2 - filling pressure to flow. The cardiac function / venous return curve.
# ---------------------------------------------------------------------------

Q2 = [
    dict(label="Pinsky 1984", pmid="6368503", species="dog", n=17,
         cite="Pinsky MR. J Appl Physiol Respir Environ Exerc Physiol 1984;56:765-71",
         finding="the stroke-volume-to-Pra relationship 'describes a STRAIGHT LINE with "
                 "a negative slope and a positive zero-flow intercept'. Vascular "
                 "compliance measured by adding and removing blood showed curvilinear "
                 "HYSTERESIS - a path dependence, not a curvature of the relation."),

    dict(label="Greene & Shoukas 1986", pmid="3740285", species="dog", n=10,
         cite="Greene AS, Shoukas AA. Am J Physiol 1986;251:H288-96",
         finding="carotid sinus pressure 50 -> 200 mmHg moved the venous return curve's "
                 "ZERO-FLOW INTERCEPT 15.37 -> 11.94 mmHg with **NO CHANGE IN SLOPE**. "
                 "The cardiac function curve slope changed 60.32 -> 37.06 "
                 "mL/min/kg/mmHg when afterload was controlled. Conclusion: changes in "
                 "vascular CAPACITY are the primary mechanism for reflex changes in "
                 "cardiac output."),

    dict(label="Maas 2012", pmid="22763909", species="HUMAN", n=15,
         cite="Maas JJ, Pinsky MR, Aarts LP, Jansen JR. Anesth Analg 2012;115:880-7",
         finding="cardiac function curves were STEEP in volume-responsive patients and "
                 "FLAT in the rest. Different individuals sit on different SLOPES - "
                 "which is the population-heterogeneity question, answered by position "
                 "and reflex state rather than by curvature."),
]

# ---------------------------------------------------------------------------
# The mechanism the literature offers INSTEAD of curvature.
# ---------------------------------------------------------------------------

UNSTRESSED = [
    dict(label="Rothe 1976", pmid="975458", species="dog",
         cite="Rothe CF. Circ Res 1976;39:705-10",
         finding="maximal active reflex venoconstriction moved 9.0 mL/kg of volume "
                 "during the first minute of fibrillation; a basal capacity tone "
                 "equivalent to 10 mL/kg was present."),
    dict(label="Greenway & Lautt 1986", pmid="3730923", species="review",
         cite="Greenway CV, Lautt WW. Can J Physiol Pharmacol 1986;64:383-7",
         finding="with minimal sympathetic tone about **60% of total blood volume is "
                 "haemodynamically inactive** - the unstressed volume. Venoconstriction "
                 "converts unstressed to stressed volume. 'A major unsolved problem is "
                 "how the conversion is reflexly controlled.'"),
]


def main() -> None:
    w = 78
    print("=" * w)
    print("Q1 - SYSTEMIC PRESSURE-VOLUME RELATIONSHIP: VALUE AND SHAPE")
    print("=" * w)
    for s in Q1:
        print(f"  {s['label']:22s} PMID {s['pmid']:9s} {s['species']:11s}"
              f" n={s['n'] if s['n'] else '?'}")
        print(f"    {s['cite']}")
        print(f"    prep    : {s['prep']}")
        print(f"    range   : {s['range_']}")
        print(f"    C       : {s['compliance']} {s['units']}")
        print(f"    SHAPE   : {s['shape']}")
        print(f"    1.7 test: {s['intent']}")
        print()

    print("=" * w)
    print("Q2 - PRESSURE TO FLOW: THE CARDIAC FUNCTION / VENOUS RETURN CURVE")
    print("=" * w)
    for s in Q2:
        print(f"  {s['label']:22s} PMID {s['pmid']:9s} {s['species']}")
        print(f"    {s['cite']}")
        print(f"    {s['finding']}")
        print()

    print("=" * w)
    print("THE ANSWER")
    print("=" * w)
    print("  BOTH LEGS ARE LINEAR OVER THE PHYSIOLOGICAL RANGE, so the composed")
    print("  filling relation g is LINEAR over the physiological range.")
    print()
    print("  Q1 linear: Lee 1988 explicitly, MCFP 5-12 mmHg, R2=0.992. Maas 2012")
    print("     explicitly, in humans. Compliance unchanged by reflex blockade")
    print("     (Rothe 1990), by pregnancy (Cha 1992) and by volume loading alone")
    print("     (Ogilvie 1992).")
    print("  Q2 linear: Pinsky 1984 'a straight line'. Greene & Shoukas 1986 report")
    print("     a SLOPE, and report the baroreflex moving the INTERCEPT and not it.")
    print()
    print("  NON-LINEARITY EXISTS AND IS OUT OF RANGE. Lee 1988 finds an exponential")
    print("  pressure-volume relation BELOW MCFP 5 mmHg. The model sits near 7-8")
    print("  mmHg and its salt step moves blood volume by 2.7%. The curvature is real")
    print("  and the model never visits it.")
    print()
    print("=" * w)
    print("ADR 0012'S CONCAVITY REQUIREMENT IS REFUTED")
    print("=" * w)
    print("  Prereg section 0.3, written before any paper was opened: 'a linear")
    print("  finding is a real result, and it is the more consequential one. It would")
    print("  mean the partition does not explain the posture gradient after all, and")
    print("  that something else does. Report it, amend ADR 0012, and do not go")
    print("  looking for a more curved source.'")
    print()
    print("  That is the finding. The partition-plus-curvature explanation of the")
    print("  posture gradient FAILS, because the curvature it needs is not there.")
    print()
    print("=" * w)
    print("AND THE LITERATURE NAMES THE MECHANISM IT SHOULD HAVE BEEN")
    print("=" * w)
    for s in UNSTRESSED:
        print(f"  {s['label']:22s} PMID {s['pmid']:9s} {s['species']}")
        print(f"    {s['cite']}")
        print(f"    {s['finding']}")
        print()
    print("  Greene & Shoukas is decisive on the mechanism: the baroreflex moves the")
    print("  venous return curve's INTERCEPT, NOT ITS SLOPE, and vascular CAPACITY is")
    print("  the primary route by which reflexes change cardiac output.")
    print()
    print("  So the posture gradient is a shift in UNSTRESSED VOLUME, not a slide")
    print("  along a curve. Standing provokes reflex venoconstriction, which converts")
    print("  unstressed volume to stressed volume and moves the intercept. Compliance")
    print("  - the slope - does not change; Rothe 1990 measured that directly.")
    print()
    print("  **THE DISTINCTION THE MODEL NEEDS IS STRESSED / UNSTRESSED, NOT")
    print("  CENTRAL / PERIPHERAL.** ADR 0012 chose central/peripheral on the grounds")
    print("  that it was 'the cut the evidence in this repo is actually about'. That")
    print("  was true of the evidence in the repo at the time. It is not true of this")
    print("  literature, which is unanimous that the operative variable is the")
    print("  stressed fraction and that reflexes act on the unstressed reserve.")
    print()
    print("  Greenway & Lautt put roughly 60% of blood volume in the unstressed")
    print("  reserve at minimal tone; Maas 2012 measures stressed volume in humans at")
    print("  28.5% +/- 15% of total blood volume, which is the same statement.")
    print()
    print("  COINCIDENCE, FLAGGED SO IT IS NOT EXPLOITED: the model's placeholder")
    print("  f_central = 0.25 sits close to that 28.5% stressed fraction. THEY ARE")
    print("  DIFFERENT QUANTITIES. Central volume is anatomical; stressed volume is")
    print("  mechanical. Do not quietly reinterpret one as the other.")
    print()
    print("=" * w)
    print("WHAT IS RECORDED, AND WHAT IS NOT")
    print("=" * w)
    print("  NO LEDGER PARAMETER IS RECORDED. Stop condition 1 requires k >= 3")
    print("  independent sources for a pooled numeric value.")
    print("    - HUMAN compliance: k = 1 (Maas 2012, 0.97 mL/mmHg/kg PBW).")
    print("      single-source. pooling.md forbids dressing that as consensus.")
    print("    - ANIMAL compliance: dog 1.80 / 2.09 / 3.4, pig 2.1-3.5, guinea pig")
    print("      2.1 mL/mmHg/kg. pooling.md forbids pooling across species AND across")
    print("      preparations, and these differ in both. Ogilvie 1990's own three")
    print("      METHODS span 2.1 to 3.5 in the same animals, which is wider than most")
    print("      of the between-study spread. Reported as a range, not pooled.")
    print()
    print("  WHAT IS ESTABLISHED is the SHAPE, and the pre-registration set a lower")
    print("  bar for that deliberately: agreement across at least two independent")
    print("  groups. It is met several times over, in humans and in three other")
    print("  species, by four methods.")


if __name__ == "__main__":
    main()
