#!/usr/bin/env python
"""The blood pressure response to chronic sodium intake in normotensive humans.

Executes validation/salt_sensitivity_prereg.md, committed at 9e2cef4 BEFORE any
paper was opened.

THE ANSWER: the model is 2 to 17 times too salt-sensitive for a normotensive
population, and its salt sensitivity sits in the HYPERTENSIVE range. Every
qualifying meta-analysis lands below the model. The conclusion survives the
disagreement between the two rival groups in this literature.

Every citation was read from the retrieved PubMed record; authors, journal,
year, volume and pages verified against that record.

NOTHING HERE IS A LEDGER PARAMETER. Stop condition 6: a re-estimated G_pn goes
through an ADR with its own falsifiable test.

Run:  python validation/salt_sensitivity_extract.py
"""

# --- what the model says, from HANDOVER section 2, pinned in test/runtests.jl ---
MODEL_DMAP = 4.934166220845427     # mmHg
MODEL_DINTAKE = 102.0              # mEq/day, 205 -> 103
G_PN_INCUMBENT = 20.0              # RN.PRESSURE_NATRIURESIS.SLOPE, calibrated
G_PN_MIZELLE = 5.43                # implied by the dog comparison

# ---------------------------------------------------------------------------
# Qualifying meta-analyses. pooling.md rule 1 puts meta-analysis first, and this
# literature has several. They are NOT pooled with each other: they share
# primaries, and pooling.md prohibits silent re-pooling of a meta-analytic
# estimate with studies already inside it.
#
# sbp/dbp are mmHg per 100 mmol/day sodium reduction, NORMOTENSIVE or
# lowest-75th-percentile groups only. Per prereg section 1 the target is the
# UNSELECTED normotensive mean; subgroup-only rows are recorded, not pooled.
# ---------------------------------------------------------------------------

MA = [
    dict(label="Cutler 1997", pmid="9022560", n_trials=32, n_subj=2635,
         cite="Cutler JA, Follmann D, Allender PS. Am J Clin Nutr 1997;65:643S-651S",
         doi="10.1093/ajcn/65.2.643S",
         sbp=2.3, dbp=1.4, basis="reported directly as per 100 mmol Na/24 h",
         note="weighted linear regression across trials; dose response 'more "
              "consistent for trials in normotensive subjects'."),

    dict(label="He & MacGregor 2002", pmid="12444537", n_trials=11, n_subj=2220,
         cite="He FJ, MacGregor GA. J Hum Hypertens 2002;16:761-70",
         doi=None,
         sbp=3.57, dbp=1.66, basis="reported directly as per 100 mmol/day",
         note="modest reduction only, duration >= 4 weeks. Excludes the acute "
              "load-then-deplete protocols they argue are inappropriate."),

    dict(label="He, Li & MacGregor 2013", pmid="23558162", n_trials=34, n_subj=3230,
         cite="He FJ, Li J, MacGregor GA. BMJ 2013;346:f1325",
         doi="10.1136/bmj.f1325",
         sbp=2.42 * 100 / 75, dbp=1.00 * 100 / 75,
         basis="normotensive subgroup -2.42/-1.00 mmHg for a -75 mmol/24 h change, "
               "scaled to 100 mmol",
         note="their headline 5.8 mmHg/100 mmol is the META-REGRESSION ADJUSTED for "
              "age, ethnicity and BP STATUS - it is not the unselected normotensive "
              "figure and is deliberately not used here."),

    dict(label="Graudal 2017 Cochrane", pmid="28391629", n_trials=89, n_subj=8569,
         cite="Graudal NA, Hubeck-Graudal T, Jurgens G. Cochrane Database Syst Rev "
              "2017;4:CD004022",
         doi="10.1002/14651858.CD004022.pub4",
         sbp=1.09 * 100 / 135, dbp=-0.03 * 100 / 135,
         basis="white normotensive SBP -1.09, DBP +0.03, for 201 -> 66 mmol/day "
               "= 135 mmol, scaled to 100 mmol",
         note="DBP moved the WRONG WAY and was not significant. Largest evidence "
              "base here, graded high-quality by the review itself."),

    dict(label="Graudal 2019 meta-regression", pmid="31051506", n_trials=133, n_subj=None,
         cite="Graudal N, Hubeck-Graudal T, Jurgens G, Taylor RS. "
              "Am J Clin Nutr 2019;109:1273-1278",
         doi="10.1093/ajcn/nqy384",
         sbp=1.46, dbp=0.07,
         basis="study groups with mean BP <= 131/78 mmHg, reported directly as "
               "mmHg per 100 mmol",
         note="THE CLOSEST MATCH TO THE QUESTION - an explicit dose-response "
              "meta-regression. Splits by BP percentile rather than by label."),
]

# Recorded, and per prereg section 1 NEVER pooled into the target.
HIGH_BP = [
    dict(label="Graudal 2019, BP > 131/78", pmid="31051506", sbp=7.7, dbp=3.0),
    dict(label="He & MacGregor 2002, hypertensive", pmid="12444537", sbp=7.11, dbp=3.88),
    dict(label="Cutler 1997, hypertensive", pmid="9022560", sbp=5.8, dbp=2.5),
]


def mapslope(sbp, dbp):
    """MAP = DBP + (SBP - DBP)/3, the conversion fixed in prereg section 2."""
    return dbp + (sbp - dbp) / 3.0


def main() -> None:
    w = 78
    model_per100 = MODEL_DMAP / MODEL_DINTAKE * 100.0
    print("=" * w)
    print("WHAT THE MODEL SAYS")
    print("=" * w)
    print(f"  {MODEL_DMAP:.4f} mmHg across {MODEL_DINTAKE:.0f} mEq/day")
    print(f"  = {model_per100:.2f} mmHg MAP per 100 mmol/day")
    print(f"  G_pn incumbent {G_PN_INCUMBENT}, Mizelle-implied {G_PN_MIZELLE}")
    print()

    print("=" * w)
    print("NORMOTENSIVE HUMANS - EVERY QUALIFYING META-ANALYSIS")
    print("=" * w)
    print(f"  {'source':30s} {'SBP':>6s} {'DBP':>6s} {'MAP':>6s}  {'model/human':>11s}"
          f"  {'G_pn':>7s}")
    rows = []
    for m in MA:
        ms = mapslope(m["sbp"], m["dbp"])
        rows.append((m, ms))
        print(f"  {m['label']:30s} {m['sbp']:6.2f} {m['dbp']:6.2f} {ms:6.2f}"
              f"  {model_per100 / ms:10.1f}x  {100.0 / ms:7.1f}")
    print("  (mmHg per 100 mmol/day. G_pn = 100 / MAP slope, in (mEq/day)/mmHg.)")
    print()
    for m in MA:
        print(f"  {m['label']}  PMID {m['pmid']}  ({m['n_trials']} trials"
              + (f", n={m['n_subj']}" if m["n_subj"] else "") + ")")
        print(f"    {m['cite']}" + (f"  doi:{m['doi']}" if m["doi"] else ""))
        print(f"    basis: {m['basis']}")
        print(f"    note : {m['note']}")
        print()

    ms_all = [x[1] for x in rows]
    lo, hi = min(ms_all), max(ms_all)
    print("=" * w)
    print("THE ANSWER")
    print("=" * w)
    print(f"  Normotensive human MAP slope: {lo:.2f} to {hi:.2f} mmHg per 100 mmol.")
    print(f"  The model:                    {model_per100:.2f} mmHg per 100 mmol.")
    print()
    print(f"  **THE MODEL IS {model_per100 / hi:.1f}x TO {model_per100 / lo:.1f}x TOO"
          f" SALT-SENSITIVE.**")
    print()
    print("  The five meta-analyses disagree with each other by a factor of 8, and")
    print("  that disagreement is a live and well-known controversy - the Graudal and")
    print("  He/MacGregor groups argue with each other in the abstracts read here.")
    print("  pooling.md forbids papering over it and they share primaries, so they are")
    print("  NOT pooled. It does not matter for the conclusion: **every one of them")
    print("  lands below the model**, and the closest to it is still 2.1x away.")
    print()

    print("=" * w)
    print("AND THE MODEL IS SITTING IN THE HYPERTENSIVE RANGE")
    print("=" * w)
    print(f"  {'source':38s} {'SBP':>6s} {'DBP':>6s} {'MAP':>6s}")
    for h in HIGH_BP:
        print(f"  {h['label']:38s} {h['sbp']:6.2f} {h['dbp']:6.2f}"
              f" {mapslope(h['sbp'], h['dbp']):6.2f}")
    print()
    print(f"  The model's {model_per100:.2f} mmHg/100 mmol is not a normotensive number.")
    print("  It sits among the HYPERTENSIVE and above-75th-percentile estimates.")
    print()
    print("  THIS INVERTS THE REASONING IN HANDOVER SECTION 3.1. That section holds")
    print("  G_pn at 20.0 rather than Mizelle's 5.43 because 5.43 gives a 15.7 mmHg")
    print("  shift - 'salt-sensitive hypertensive behaviour, not normotensive'. The")
    print("  judgement was right and the threshold was far too generous: 20.0 ALSO")
    print("  gives hypertensive-range salt sensitivity. The model has been calibrated")
    print("  to the wrong population the whole time, and the note that flagged the")
    print("  risk did not go far enough.")
    print()
    print("  G_pn should be LARGER than 20, not smaller:")
    print(f"    implied by human normotensive data : {100.0 / hi:.0f} to {100.0 / lo:.0f}")
    print(f"    incumbent                          : {G_PN_INCUMBENT:.0f}")
    print(f"    implied by the Mizelle dog comparison: {G_PN_MIZELLE:.2f}")
    print()
    print("  **THE MIZELLE COMPARISON POINTS THE WRONG WAY.** It argues G_pn should")
    print("  fall to 5.43, i.e. that the model is not salt-sensitive ENOUGH. The human")
    print("  data says the opposite by a wide margin. The 3.68x inflation and the 2.2x")
    print("  residual have been an argument about how much to move a number in a")
    print("  direction the human evidence does not support. That does not make the")
    print("  residual audit wrong - it was arithmetic and it stands - but it removes")
    print("  it from the critical path, exactly as prereg section 0 anticipated.")
    print()

    print("=" * w)
    print("SENSITIVITY CHECK REQUIRED BY PREREG SECTION 2")
    print("=" * w)
    print("  Four of five rows required MAP = DBP + (SBP-DBP)/3, and reconstruct.jl")
    print("  records that form factor as the largest error source in within-cycle")
    print("  reconstruction. Recomputing on DBP ALONE:")
    print(f"    {'source':30s} {'DBP-only':>9s}")
    for m in MA:
        print(f"    {m['label']:30s} {m['dbp']:9.2f}")
    print("  Every value is SMALLER than the MAP estimate, so the conclusion is")
    print("  STRENGTHENED, not weakened, by the conversion. It does not depend on it.")
    print()

    print("=" * w)
    print("WHAT IS RECORDED")
    print("=" * w)
    print("  NO LEDGER PARAMETER. Stop condition 6: a re-estimated G_pn goes through")
    print("  an ADR with its own falsifiable test, because it sets the model's")
    print("  headline claim and test/runtests.jl pins it deliberately.")
    print()
    print("  Stop condition 1 IS satisfied - five qualifying meta-analyses where one")
    print("  would have done - so the blocker is not evidence. It is that changing")
    print("  G_pn changes the number this repo has quoted in every handover, and that")
    print("  is a decision.")
    print()
    print("  PREREG SECTION 8, WRITTEN BEFORE ANY PAPER WAS OPENED:")
    print("    'If the human population slope implies a G_pn far from 20.0, then the")
    print("     model's headline result - 4.934 mmHg, bit-stable since the loop")
    print("     closed, pinned in the test suite, quoted in every handover - HAS BEEN")
    print("     WRONG THE WHOLE TIME, and every downstream conclusion that leaned on")
    print("     it needs revisiting.'")
    print()
    print("  That is the outcome.")


if __name__ == "__main__":
    main()
