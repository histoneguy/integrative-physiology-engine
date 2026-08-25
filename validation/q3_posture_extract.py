#!/usr/bin/env python
"""Test whether posture modifies the SV response to a fixed blood loss.

Executes validation/q3_posture_prereg.md, committed at 7d97d65 BEFORE the full
text was opened. Tests the Q3 finding of sv_filling_prereg.md, which is the
evidential basis of ADR 0012 falsifiable test 1.

SOURCE, verified against the PubMed record and then against the full text:
  van de Velde L, Eeftinck Schattenkerk DW, Venema PAHT, Best HJ,
  van den Bogaard B, Stok WJ, Westerhof BE, van den Born BJH.
  Myocardial preload alters central pressure augmentation through changes in
  the forward wave. J Hypertens 2018;36(3):544-551.
  PMID 29016531, doi:10.1097/HJH.0000000000001583
  Green OA deposit, Taverne licence, University of Twente Pure.

NOTHING HERE IS A LEDGER PARAMETER AND NOTHING HERE MAY BECOME ONE.
Stop condition 3: active standing is an excluded calibration paradigm under
ADR 0011 and this pre-registration does not lift that exclusion.

Run:  python validation/q3_posture_extract.py
"""

# ---------------------------------------------------------------------------
# Table 2, mean +/- SD, n = 31 middle-aged patients (57 +/- 10.2 y, 65% men)
# on regular phlebotomy on medical grounds. 500 mL drawn over 15-30 min.
# Protocol per arm: 10 min supine rest, then 5 min active standing. Data are
# 20 consecutive beats from the LAST MINUTE of each measurement.
# ---------------------------------------------------------------------------

SV = {                       # mL
    ("supine",   "before"): (69.5, 17.5),
    ("standing", "before"): (55.2, 17.4),
    ("supine",   "after"):  (66.7, 18.2),
    ("standing", "after"):  (44.6, 14.9),
}
CO = {                       # L/min
    ("supine",   "before"): 4.5, ("standing", "before"): 4.0,
    ("supine",   "after"):  4.3, ("standing", "after"):  3.7,
}
HR = {                       # bpm
    ("supine",   "before"): 66.0, ("standing", "before"): 74.8,
    ("supine",   "after"):  65.2, ("standing", "after"):  85.5,
}
DPDT = {                     # mmHg/s, "left ventricular contractility" per the paper
    ("supine",   "before"): 399, ("standing", "before"): 436,
    ("supine",   "after"):  413, ("standing", "after"):  445,
}

BLED_L = 0.500

# The between-study gradient this is testing, from sv_filling_extract.py.
BETWEEN_STUDY = {"seated": 28.00, "30deg": 13.33, "supine": 10.16}   # mL/L
BETWEEN_STUDY_RATIO = 28.00 / 10.16                                   # seated / supine


def main() -> None:
    w = 78
    print("=" * w)
    print("Q3 - DOES POSTURE MODIFY THE SV RESPONSE TO A FIXED BLOOD LOSS?")
    print("=" * w)
    print("  van de Velde L, Eeftinck Schattenkerk DW, Venema PAHT, Best HJ,")
    print("  van den Bogaard B, Stok WJ, Westerhof BE, van den Born BJH.")
    print("  J Hypertens 2018;36(3):544-551. PMID 29016531")
    print("  doi:10.1097/HJH.0000000000001583")
    print()
    print("  n = 31, within-subject, 500 mL over 15-30 min, 10 min supine then")
    print("  5 min active standing, both before and after. Table 2, mean +/- SD.")
    print()

    print("  THE 2x2 THE PRE-REGISTRATION ASKED FOR - it exists:")
    print()
    print("    SV (mL)        before          after           delta")
    for post in ("supine", "standing"):
        b, sb = SV[(post, "before")]
        a, sa = SV[(post, "after")]
        print(f"    {post:9s}   {b:5.1f} +/- {sb:4.1f}   {a:5.1f} +/- {sa:4.1f}"
              f"   {b - a:5.2f} mL")
    print()

    d_sup = SV[("supine", "before")][0] - SV[("supine", "after")][0]
    d_sta = SV[("standing", "before")][0] - SV[("standing", "after")][0]
    R = d_sta / d_sup

    print("=" * w)
    print("THE PRE-REGISTERED TEST STATISTIC")
    print("=" * w)
    print(f"    dSV_supine   = {d_sup:5.2f} mL   ->  {d_sup / BLED_L:6.2f} mL/L")
    print(f"    dSV_standing = {d_sta:5.2f} mL   ->  {d_sta / BLED_L:6.2f} mL/L")
    print()
    print(f"    R = dSV_standing / dSV_supine = {R:.3f}")
    print()
    print(f"  The pre-registration fixed: confirmed if R > 1, refuted if R <= 1,")
    print(f"  and 1 < R < {BETWEEN_STUDY_RATIO:.2f} is PARTIAL - direction without magnitude.")
    print(f"  The between-study gradient it is testing gave"
          f" {BETWEEN_STUDY['seated']:.2f} / {BETWEEN_STUDY['supine']:.2f}"
          f" = {BETWEEN_STUDY_RATIO:.2f}.")
    print()
    print(f"  R = {R:.2f}. DIRECTION CONFIRMED, AND THE MAGNITUDE EXCEEDS THE")
    print(f"  BETWEEN-STUDY GRADIENT RATHER THAN FALLING SHORT OF IT. Standing is")
    print("  more upright than seated, which is the direction the mechanism predicts.")
    print()

    print("=" * w)
    print("BUT THE PRE-REGISTRATION'S OWN BAR IS NOT MET, AND SAYING SO MATTERS")
    print("=" * w)
    print("  Section 3 required R > 1 'with the paper's own reported dispersion")
    print("  excluding 1'. THAT CANNOT BE COMPUTED FROM WHAT IS REPORTED.")
    print()
    print("  Table 2 gives SDs of the four CELL MEANS, not of the two paired")
    print("  differences, and the paired correlation is not reported. Worse, the")
    print("  footnotes show the supine phlebotomy effect IS NOT TESTED at all:")
    print("    *  marks Sta or CSup vs Sup       (the POSTURE effect)")
    print("    ** marks PSta vs PSup             (the POSTURE effect, after)")
    print("    the last column is PSta vs Sta    (the PHLEBOTOMY effect, standing)")
    print("  So the NUMERATOR is significant at P < 0.001 and the DENOMINATOR is")
    print("  untested - 2.8 mL against a cell SD of about 18 mL.")
    print()
    print("  If the true supine response is near zero, R is not 3.79 but unbounded.")
    print("  That is MORE extreme in the confirming direction, not less, so the")
    print("  finding survives - but R itself is a point estimate with no interval,")
    print("  and it must not be quoted as though it had one.")
    print()
    print("  This is a FOURTH outcome the pre-registration did not name. It listed")
    print("  confirmed, refuted, inconclusive-because-dispersion-spans-1, and")
    print("  partial. It did not anticipate the dispersion being UNAVAILABLE.")
    print()

    print("=" * w)
    print("THE CONFOUND THAT MATTERS, AND THE MODEL CANNOT REPRESENT IT")
    print("=" * w)
    print("    HR (bpm)       before   after   change")
    for post in ("supine", "standing"):
        b, a = HR[(post, "before")], HR[(post, "after")]
        print(f"    {post:9s}      {b:5.1f}   {a:5.1f}   {a - b:+5.1f}"
              f"  ({100 * (a - b) / b:+5.1f}%)")
    print()
    print("  The standing arm gains 10.7 bpm across the phlebotomy; the supine arm")
    print("  loses 0.8. Shorter diastolic filling at the higher rate lowers SV by")
    print("  itself, so part of the 10.6 mL standing fall is RATE-MEDIATED rather")
    print("  than filling-mediated. This is tension 0.1 of sv_filling_prereg.md,")
    print("  and here it is not negligible.")
    print()
    print("  The same comparison on CARDIAC OUTPUT makes the point sharply:")
    dco_sup = CO[("supine", "before")] - CO[("supine", "after")]
    dco_sta = CO[("standing", "before")] - CO[("standing", "after")]
    print(f"    dCO_supine   = {dco_sup:.2f} L/min")
    print(f"    dCO_standing = {dco_sta:.2f} L/min")
    print(f"    R_CO = {dco_sta / dco_sup:.2f}   against   R_SV = {R:.2f}")
    print()
    print("  Measured on SV the posture effect is 3.8x. Measured on CO it is 1.5x,")
    print("  because the tachycardia partly offsets the fall in SV. ADR 0011 holds")
    print("  HR a PARAMETER, so the model has no way to produce that divergence -")
    print("  with HR fixed, R_CO and R_SV are the same number by construction.")
    print()
    print("  NOTE WHAT THIS DOES AND DOES NOT DO TO ADR 0011. It does not refute")
    print("  HR-as-parameter for the perturbations ADR 0011 was reasoning about -")
    print("  in supine phlebotomy, HR moved 66.0 -> 65.2, consistent with the three")
    print("  studies already cited. It shows that HR-as-parameter FAILS UNDER")
    print("  ORTHOSTATIC STRESS, which is a paradigm ADR 0011 had already excluded")
    print("  from calibration for a different reason. The exclusion turns out to")
    print("  have been protecting something real.")
    print()

    print("=" * w)
    print("CHECKS THE PRE-REGISTRATION DEMANDED BEFORE READING")
    print("=" * w)
    print("  SECTION 7, the measurement artefact: PASSES. SV is Nexfin volume-clamp")
    print("  with Modelflow, exactly the posture-sensitive family flagged in advance,")
    print("  BUT the paper states care was taken to maintain the hand at HEART LEVEL")
    print("  throughout, and cites Modelflow CO as validated against thermodilution")
    print("  under supine AND orthostatic stress. The hydrostatic artefact that could")
    print("  have manufactured R > 1 is controlled.")
    print()
    print("  CONTRACTILITY: STABLE, which Kumar 2004 had made a live worry.")
    print("    dP/dtmax  " + "  ".join(
        f"{k[0][:3]}/{k[1][:3]}={v}" for k, v in DPDT.items()))
    print("  The paper reports no significant difference on this row.")
    print()
    print("  POPULATION: patients on regular phlebotomy on medical grounds, mean age")
    print("  57, and 6 of 31 on cardioactive drugs (2 beta-blockers, 2 thiazides,")
    print("  1 calcium antagonist, 1 alpha-blocker). Beta-blockade in particular")
    print("  blunts exactly the chronotropic response discussed above. Recorded as a")
    print("  covariate; within-subject design makes each patient their own control.")
    print()

    print("=" * w)
    print("VERDICT")
    print("=" * w)
    print("  Q3 IS CONFIRMED IN DIRECTION. Posture modifies the stroke-volume")
    print("  response to a fixed total-volume loss WITHIN subjects, removing study,")
    print("  population, age and device from the comparison in one step. ADR 0012")
    print("  falsifiable test 1 keeps its motivation and the concavity requirement")
    print("  stands.")
    print()
    print("  THE MAGNITUDE IS NOT ESTABLISHED. R = 3.79 is a point estimate with no")
    print("  computable interval and an untested denominator.")
    print()
    print("  AND THE CONFIRMATION ARRIVES ATTACHED TO A MECHANISM THE MODEL HAS")
    print("  EXPLICITLY EXCLUDED. Most of what separates R_SV from R_CO is")
    print("  chronotropic, and ADR 0011 fixes HR. A model with HR as a parameter")
    print("  cannot reproduce this experiment even if the partition and the")
    print("  curvature are both right.")
    print()
    print("  WHAT THIS DOES NOT ESTABLISH, per section 4 of the pre-registration:")
    print("  that the central/peripheral partition is THE mechanism. Standing moves")
    print("  venous tone and sympathetic outflow as well as volume distribution.")
    print("  This result is CONSISTENT WITH ADR 0012 and does not select it over")
    print("  its rivals. Do not write it up as though it did.")
    print()
    print("  k = 1 and it stays k = 1. NO LEDGER PARAMETER IS RECORDED.")


if __name__ == "__main__":
    main()
