#!/usr/bin/env python
"""Renal haemodynamics across sodium intake, extracted. The verdict is G3, and the
evidence base is four groups rather than the nine primaries it looked like.

Executes validation/renal_hemodynamics_prereg.md, which sits immediately before this
change in the branch history. No commit SHA is cited - rebase-merge rewrites it. Verify
the ordering with:

    git log --diff-filter=A -- validation/renal_hemodynamics_prereg.md

THE VERDICT, against thresholds reused verbatim from ADR 0015's escape diagnostic:

    S = 1.30      fractional GFR change per fractional ECF change, healthy humans
    fall in the model salt-step shift = 0.1173 * S = 15.2%       -> BRANCH G3

G3 is "real but minor": enter the row, write NO structural ADR, change no code. The
per-intake cross-check lands at 8.1%, also inside G3, so the band does not turn on which
parameterisation is used. Closing the whole human gap by this route would need a 26-32%
GFR swing across the model step; the sourced human response over the same 102 mmol/day is
4.0%, which is where the sixth-of-the-gap figure comes from.

THREE FINDINGS THAT OUTRANK THE NUMBER.

1. THE NINE HEALTHY-HUMAN PRIMARIES ARE FOUR GROUPS, AND THREE OF THEM ARE ONE COHORT.
   Krikken 2007, Visser 2009 and van den Bosch 2021 are the SAME Groningen study - van
   den Bosch says so in its own Methods, "a post-hoc analysis from a prior study ...
   published previously (Krikken et al., 2007; Visser et al., ...)", n = 70/93. Toering
   2018 is Groningen too. Shoback 1983, Redgrave 1985 and Conlin 1993 are all Brigham and
   Women's Hospital. That leaves Textor 1991 (Mayo) and Barba 2000 (UCL/Naples).
   ADR 0015 cites "four independent groups, n up to 95" for its E1 human claim and names
   Krikken, van den Bosch, Redgrave and Conlin. THOSE ARE TWO GROUPS. Corrected there.

2. THE ONLY CLEAN HEALTHY-WOMEN STUDY REPORTS NO RENAL HAEMODYNAMIC CHANGE ON SALT.
   The pre-registered women sweep found it: Pechere-Bertschi 2002, 35 normotensive women,
   40 vs 250 mmol/day for 7 days, and in the FOLLICULAR phase "the increase in salt intake
   was associated with no change in renal hemodynamics", with renal vasodilation in the
   LUTEAL phase instead. The male limb this row rests on is Groningen men. The row is
   entered `both` per the pre-registration, and this is recorded as a DECLARED CONFLICT
   rather than a gap.

3. THE FILTRATION-FRACTION QUESTION IS BRANCH F3 - the dog fall is UNREPLICATED in
   humans, and no eligible human source establishes a direction. Krikken is struck under
   branch K2 (below). van den Bosch's 0.229 -> 0.233 is a ratio of two reported means with
   no dispersion, which the pre-registration declared descriptive only IN ADVANCE.
   Pechere-Bertschi 2003 does report a significant FF RISE - but in women on oral
   contraceptives, whose renal salt response that paper exists to show is altered.

THE KRIKKEN AMBIGUITY IS BRANCH K2. Kidney Int 2007 is subscription-only, not in PMC, not
open access on Europe PMC, and ScienceDirect returns 403. The sentence is STRUCK, not
reinterpreted, and Krikken is excluded from the filtration-fraction question entirely.
What the abstract's own correlation coefficients imply is recorded below as an
observation, NOT used as a resolution - directive 1.5.

Every number below was read from the retrieved PubMed record. van den Bosch 2021 was read
as full text from PubMed Central, including Table 1 in full.

Run:  python validation/renal_hemodynamics_extract.py
"""

# ---------------------------------------------------------------------------
# THE SEARCH. The candidate table's three sweeps stand as sweeps 1 and 2. The
# pre-registration required ONE FURTHER SWEEP before any pooling, aimed at the two gaps
# that table declares in its own section 5: healthy women, and baseline GFR values.
#
# Sweep 4: 8 queries, 84 unique records screened. It paid twice - it returned the only
# clean healthy-women source (Pechere-Bertschi 2002, finding 2 above) and an independent
# Utrecht cohort with a different tracer (Roos 1985). Directive 1.8 again.
# ---------------------------------------------------------------------------

SWEEP = dict(
    prior_sweeps="3 sweeps, 24 queries, in renal_hemodynamics_salt_sources.md",
    sweep4_queries=8,
    sweep4_records=84,
    sweep4_aim="healthy women; baseline GFR and dispersion",
    sweep4_yield="Pechere-Bertschi 2002 and 2003 (Geneva); Roos 1985 (Utrecht)",
)

# ---------------------------------------------------------------------------
# THE PRIMARY SOURCE. The ONLY study found reporting GFR and extracellular volume in the
# SAME subjects across chronic sodium intake levels, which is what the ratio needs.
#
# van den Bosch JJJON, Hessels NR, Visser FW, Krikken JA, Bakker SJL, Riphagen IJ,
# Navis GJ. Plasma sodium, extracellular fluid volume, and blood pressure in healthy men.
# Physiol Rep 2021;9(24):e15103. doi:10.14814/phy2.15103. PMID 34921521. PMC8683787.
#
# n = 70 healthy normotensive men, age 24 +/- 7, crossover, 7 days per level, intake
# VERIFIED by 24 h urinary sodium: 230 +/- 67 (HS) against 38 +/- 26 (LS) mmol/24 h.
# GFR and ECFV both by 125I-iothalamate - ONE tracer, so numerator and denominator are
# method-consistent and also correlated. Table 1, read in full.
# ---------------------------------------------------------------------------

VDB = dict(
    n=70,
    gfr_hs=138.0, gfr_hs_sd=18.0,      # ml/min, ABSOLUTE (not indexed)
    gfr_ls=128.0, gfr_ls_sd=18.0,      # p < 0.001
    ecfv_hs=17.4, ecfv_hs_sd=1.66,     # L per 1.73 m2, INDEXED
    ecfv_ls=16.5, ecfv_ls_sd=1.54,     # p < 0.001
    bsa_hs=2.04, bsa_ls=2.03,          # m2, p < 0.001 - BSA ITSELF MOVES
    erpf_hs=592.0, erpf_ls=559.0,      # ml/min, p < 0.001
    map_hs=88.0, map_ls=86.0,          # mmHg, p = 0.02
    na_hs=230.0, na_ls=38.0,           # mmol/24 h, MEASURED
    weight_hs=80.6, weight_ls=79.2,    # kg
)

# ---------------------------------------------------------------------------
# THE MODEL CONSTANTS, fixed in the pre-registration section 2 BEFORE this extraction and
# measured with bench/gfr_salt_sweep.jl. Not re-derived here.
# ---------------------------------------------------------------------------

MODEL = dict(
    vol_half_excursion=0.02896,   # fractional dV_ecf at +/- 51 mEq/day
    fall_per_g=4.05,              # fractional fall in the shift per unit g
    shift_per_100=4.9578,         # mmHg per 100 mmol/day, current model
    human_target=(1.70, 2.30),    # meta-analytic, k = 3
    g_to_close_gap=(0.132, 0.162),
)

BANDS = dict(live=0.20, dead=0.05)   # reused VERBATIM from ADR 0015's escape diagnostic


def s_value(basis="absolute"):
    """S = (dGFR/GFR) / (dV_ecf/V_ecf), both as fractions of the two-arm mean.

    GFR is reported ABSOLUTE and ECFV is reported INDEXED to 1.73 m2, so one of them has
    to be converted or the ratio is not dimensionless in the same body.

    DE-INDEXING USES EACH ARM'S OWN BSA, and that matters: BSA rose from 2.03 to 2.04
    (p < 0.001) because body weight rose 1.4 kg. Multiplying the indexed DIFFERENCE by a
    single BSA understates the absolute expansion by 9%.
    """
    v = VDB
    dgfr = v["gfr_hs"] - v["gfr_ls"]
    gfr_mean = (v["gfr_hs"] + v["gfr_ls"]) / 2.0
    if basis == "absolute":
        ecf_hs = v["ecfv_hs"] * v["bsa_hs"] / 1.73
        ecf_ls = v["ecfv_ls"] * v["bsa_ls"] / 1.73
    else:                                   # index the GFR instead
        ecf_hs, ecf_ls = v["ecfv_hs"], v["ecfv_ls"]
        dgfr = v["gfr_hs"] * 1.73 / v["bsa_hs"] - v["gfr_ls"] * 1.73 / v["bsa_ls"]
        gfr_mean = (v["gfr_hs"] * 1.73 / v["bsa_hs"] +
                    v["gfr_ls"] * 1.73 / v["bsa_ls"]) / 2.0
    decf = ecf_hs - ecf_ls
    ecf_mean = (ecf_hs + ecf_ls) / 2.0
    f_gfr = dgfr / gfr_mean
    f_ecf = decf / ecf_mean
    return f_gfr / f_ecf, f_gfr, f_ecf, decf


def band(fall):
    if fall > BANDS["live"]:
        return "G1 - pathway live"
    if fall < BANDS["dead"]:
        return "G2 - lead dead"
    return "G3 - real but minor"


def main():
    print(__doc__)
    print("=" * 78)
    print("1. THE RATIO, FROM THE ONLY STUDY REPORTING BOTH IN THE SAME SUBJECTS")
    print("=" * 78)

    s_abs, fg, fe, decf_abs = s_value("absolute")
    s_idx, fg2, fe2, _ = s_value("indexed")

    print("  dGFR  = %.1f ml/min on a mean of %.1f      -> %.5f fractional"
          % (VDB["gfr_hs"] - VDB["gfr_ls"],
             (VDB["gfr_hs"] + VDB["gfr_ls"]) / 2.0, fg))
    print("  dECFV = %.4f L absolute                    -> %.5f fractional"
          % (decf_abs, fe))
    print()
    print("  S (de-index ECFV to absolute) = %.4f" % s_abs)
    print("  S (index GFR to 1.73 m2)      = %.4f   <- 2%% apart, so it does not turn"
          % s_idx)
    print("                                            on which side is converted")
    print()
    print("  ADOPTED  S = 1.30, TWO significant figures and not three. Directive 1.9:")
    print("  the information is in the DIFFERENCES, and dECFV is 0.9 L off two")
    print("  three-figure means. There is no third figure to keep.")
    print()
    print("  NO INTERVAL IS COMPUTED, and that is deliberate. The pre-registration")
    print("  section 11 fixed it in advance: numerator and denominator are measured in")
    print("  the same subjects BY THE SAME TRACER, so they are correlated, and the")
    print("  paired differences and their covariance are not reported. Propagating the")
    print("  per-arm SDs as if independent would fabricate a number.")

    print()
    print("=" * 78)
    print("2. THE DECISION, against thresholds fixed before this run")
    print("=" * 78)

    S = 1.30
    g = MODEL["vol_half_excursion"] * S
    fall = MODEL["fall_per_g"] * g
    print("  g    = %.5f x %.2f = %.5f" % (MODEL["vol_half_excursion"], S, g))
    print("  fall = %.2f x %.5f = %.4f  = %.1f%%" %
          (MODEL["fall_per_g"], g, fall, fall * 100))
    print("  BRANCH: %s" % band(fall))
    print()

    # per-intake cross-check. NOT the entered value - pre-registration section 3.
    f_gfr_per_100 = fg / (VDB["na_hs"] - VDB["na_ls"]) * 100.0
    g_x = 51.0 * fg / (VDB["na_hs"] - VDB["na_ls"])
    fall_x = MODEL["fall_per_g"] * g_x
    print("  CROSS-CHECK, per 100 mmol/day rather than per litre. Recorded in the note,")
    print("  never entered - the kidney does not sense the diet.")
    print("    fractional dGFR per 100 mmol/day = %.5f" % f_gfr_per_100)
    print("    g = %.5f   fall = %.1f%%   BRANCH: %s"
          % (g_x, fall_x * 100, band(fall_x)))
    print()
    print("  BOTH PARAMETERISATIONS LAND IN G3. The verdict does not turn on the choice,")
    print("  and it does not turn on the model volume error either: the per-litre route")
    print("  runs through the model's own excursion, which is 1.5-2.1x too large, and")
    print("  the per-intake route does not. They bracket the answer at 8.1% and 15.2%")
    print("  and both are inside the band.")

    print()
    print("  WHAT IT WOULD DO TO SALT SENSITIVITY:")
    print("    model now                  %.4f mmHg per 100 mmol/day" %
          MODEL["shift_per_100"])
    print("    model with this term       %.4f" % (MODEL["shift_per_100"] * (1 - fall)))
    print("    human, meta-analytic       %.2f - %.2f" % MODEL["human_target"])
    print("  It closes about a sixth of the gap. It is not the explanation, and the")
    print("  pre-registration said in advance what would count as one.")

    print()
    print("  THE ONE THING THE POINT ESTIMATE CANNOT SETTLE. G1 and G3 differ only in")
    print("  whether a structural ADR is written. No interval is computable, so the")
    print("  G1/G3 boundary at S = 1.71 is not securely resolved - a crude propagation")
    print("  that IGNORES the correlation puts the upper edge near it. G3 is therefore")
    print("  taken as the CONSERVATIVE reading, not as a measured exclusion of G1, and a")
    print("  future source reporting paired differences could move it.")

    print()
    print("=" * 78)
    print("3. INDEPENDENCE AUDIT - the reason k = 1 and not 3")
    print("=" * 78)
    for line in [
        "  Groningen (Navis)  Krikken 2007 n=95, Visser 2009 n=78, van den Bosch 2021",
        "                     n=70, Toering 2018 n=36. The first three are ONE PARENT",
        "                     COHORT of ~93-95 men - van den Bosch states it in Methods.",
        "  Brigham (Hollenberg/Williams)  Shoback 1983, Redgrave 1985, Conlin 1993.",
        "  Mayo               Textor and Turner 1991.",
        "  UCL / Naples       Barba 2000.",
        "",
        "  So the table's nine primaries are FOUR groups. Pooling Krikken with van den",
        "  Bosch would be the silent re-pooling pooling.md prohibits, and it would have",
        "  looked like k = 3.",
        "",
        "  NEW, AND GENUINELY INDEPENDENT, from sweep 4:",
        "  Utrecht (Koomans, Dorhout Mees)  Roos 1985, n = 8, INULIN clearance, 20 /",
        "                     200 / 1128 meq/day. GFR 103 +/- 9 -> 129 +/- 9 ml/min from",
        "                     the lowest to the highest intake. Same direction, different",
        "                     tracer, different decade, different country.",
        "  Geneva (Burnier, Brunner)  Pechere-Bertschi 2002 (n=35 women, no OC) and 2003",
        "                     (n=27 women on OC), 40 vs 250 mmol/day, 7 days.",
        "",
        "  ROOS 1985 IS NOT POOLED, and the reason is the range clamp fixed in section 6.",
        "  Its reported endpoints span 20 to 1128 meq/day, four times outside any diet",
        "  and far outside the model's 103-205. The intermediate 200 meq values are",
        "  described as intermediate but not printed, and the full text is not open",
        "  access. It corroborates DIRECTION in an independent group. It supplies no",
        "  magnitude.",
    ]:
        print(line)

    print()
    print("=" * 78)
    print("4. FILTRATION FRACTION - BRANCH F3")
    print("=" * 78)
    for line in [
        "  Eligibility was fixed before any full text was read: a source establishes a",
        "  direction only with dispersion, or with GFR and renal plasma flow with",
        "  dispersion in the same subjects.",
        "",
        "  Krikken 2007        STRUCK under branch K2. Subscription only, no PMC, no open",
        "                      access, ScienceDirect 403. Excluded from this question.",
        "  van den Bosch 2021  0.2290 -> 0.2331, computed here from two reported means",
        "                      with no dispersion on either. DESCRIPTIVE ONLY, declared",
        "                      as such in advance.",
        "  Pechere-Bertschi 2003  FF rises, P < 0.05, n = 27 - but in women on oral",
        "                      contraceptives, and that paper exists to show the OC",
        "                      renal salt response is altered. Recorded, not decisive.",
        "  Pechere-Bertschi 2002  No change in renal haemodynamics in the follicular",
        "                      phase; renal vasodilation in the luteal phase.",
        "  Hall 1980           Six conscious control dogs, filtration fraction DECREASED.",
        "",
        "  VERDICT: the dog fall is UNREPLICATED IN HUMANS, and the human evidence does",
        "  not establish a direction either way. This model carries no filtration",
        "  fraction, so it is not constrained by this in any case. ADR 0015's efferent-",
        "  arteriolar rows stand UNTESTED rather than confirmed or contradicted, and that",
        "  is recorded there.",
    ]:
        print(line)

    print()
    print("=" * 78)
    print("5. WHAT IS RECORDED BUT NOT ENTERED")
    print("=" * 78)
    for line in [
        "  PLASMA RENIN ACTIVITY, for HANDOVER section 4 item 3, which needs an absolute",
        "  resting value rather than a doubling ratio. van den Bosch Table 1, n = 70",
        "  healthy men, same cohort:",
        "      PRA          2.10 (1.40-3.10) HS   against  5.74 (4.19-7.80) LS  ng/ml/h",
        "      aldosterone    39 (24-57)     HS   against   134 (80-178)    LS  ng/L",
        "  Medians with interquartile ranges. NOT entered here - that is item 3's own",
        "  pre-registration, and two changes at once leaves neither testable.",
        "",
        "  AN ARITHMETIC DISCREPANCY IN AN EXISTING REPO NUMBER, found in passing and",
        "  NOT fixed here. ecf_salt_response_extract.py de-indexes this same study as",
        "  0.9 x 2.04 / 1.73 = 1.061 L, multiplying the indexed DIFFERENCE by ONE body",
        "  surface area. Each arm has its own: (17.4 x 2.04 - 16.5 x 2.03) / 1.73 =",
        "  1.157 L, 9% larger, because BSA itself rose with the retained fluid.",
        "  It makes the section 3.7 within-subject ratio 1.73 rather than 1.885 mmHg/L,",
        "  which moves that failure from 5.2x to 5.7x - the same direction, slightly",
        "  worse. It is one clean pass on its own and it is section 4 item 2's business.",
    ]:
        print(line)

    print()
    print("=" * 78)
    print("6. THE ENTERED ROW")
    print("=" * 78)
    for line in [
        "  RN.GFR.VOLUME_SENSITIVITY = 1.30, dimensionless, extraction_method = derived,",
        "  tier B, species human, sex both, pooling_rule single-source, n_studies = 1.",
        "",
        "  DERIVED, not reported: van den Bosch reports four means and two body surface",
        "  areas; this ratio is computed from them and the computation is this file.",
        "",
        "  NOTHING IN src/ READS IT, AND THAT IS DECLARED RATHER THAN HIDDEN. Directive",
        "  1.11 warns that a parameter nobody calls is not evidence about anything. The",
        "  pre-registration reached branch G3, which says enter the row and write no",
        "  structural ADR, and it sequences any implementation behind the venous",
        "  compliance work because the model's volume excursion is the input this term",
        "  would multiply. The row is therefore deliberately unconsumed, with a named",
        "  consumer and a named unblocking condition, and it is in HANDOVER section 7.",
    ]:
        print(line)
    print()


if __name__ == "__main__":
    main()
