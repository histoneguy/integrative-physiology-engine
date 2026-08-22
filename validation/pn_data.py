#!/usr/bin/env python3
"""
Pressure natriuresis: compile the primary data, fit it, test linearity.

Prompted by a correction: I asserted in ledger/relations.csv that "Guyton's
renal function curve is markedly nonlinear" WITHOUT CHECKING. That assertion
is retracted below on the evidence.

Every datum here is transcribed from a primary report's stated numbers. No
figure digitisation -- where only a figure exists, the row is omitted rather
than eyeballed. Sources are named per row.

    python pn_data.py
"""
import numpy as np

# ─────────────────────────────────────────────────────────────────────────
# DATASET 1 -- Roman RJ, Cowley AW Jr. Characterization of a new model for
# the study of pressure-natriuresis in the rat. Am J Physiol 1985.
# PMID 3970209.  Rat, DENERVATED kidney, vasopressin/aldosterone/
# corticosterone/norepinephrine clamped by infusion. ACUTE.
# Reported: RPP 90->160 mmHg gave 5- to 20-fold rises in urine flow and UNaV
# with NO change in GFR, RBF or peritubular capillary pressure; "the slope of
# the LINE relating urine flow and RPP averaged 2 uL/min/kidney/mmHg"; and
# from 90 mmHg, urine flow doubled for a rise of as little as 5 mmHg.
ROMAN = dict(
    species="rat", prep="denervated, hormones clamped", regime="acute",
    rpp_lo=90.0, rpp_hi=160.0,
    slope_uL_min_kidney_mmHg=2.0,
    fold_low=5.0, fold_high=20.0,
    doubling_delta_mmHg=5.0,
)

# ─────────────────────────────────────────────────────────────────────────
# DATASET 2 -- Mizelle HL, Montani JP, Hester RL et al. Role of pressure
# natriuresis in long-term control of renal electrolyte excretion.
# Hypertension 1993;22:102-110. PMID 8319986.
# Dog, n=6, split bladder, bilateral renal artery servo-control, 12 DAYS.
# Both kidneys share one neurohumoral environment, so the ONLY difference
# between them is renal perfusion pressure. This is the cleanest isolation
# of pressure per se in the literature.
MIZELLE = [
    # (RPP mmHg, UNaV mmol/day/kidney, label)
    (86.7, 41.0, "control, both kidneys, pre-servo"),
    (74.2, 25.0, "servo-controlled kidney, 12 d"),
    (91.5, 55.0, "contralateral kidney, 12 d"),
]

# ─────────────────────────────────────────────────────────────────────────
# The model under test
G_PN_MODEL = 20.0      # RN.PRESSURE_NATRIURESIS.SLOPE, mEq/day/mmHg, CALIBRATED
GFR_HUMAN = 180.0      # L/day
C_NA = 140.0           # mEq/L
FILTERED_HUMAN = GFR_HUMAN * C_NA


def rule(t):
    print("\n" + "=" * 72)
    print(t)
    print("=" * 72)


rule("1. IS THE ACUTE RELATIONSHIP LINEAR?  (Roman & Cowley 1985)")
r = ROMAN
print(f"  RPP range {r['rpp_lo']:.0f}-{r['rpp_hi']:.0f} mmHg, span {r['rpp_hi']-r['rpp_lo']:.0f} mmHg")
print(f"  Reported as the slope of a LINE: {r['slope_uL_min_kidney_mmHg']} uL/min/kidney/mmHg")
print()
print("  Consistency test. If the response is linear with a low baseline,")
print("  the reported fold-changes and the reported doubling must agree with")
print("  the reported slope. Solve for the baseline implied by each:")
# doubling in 5 mmHg from baseline b: b + 5*slope = 2b  ->  b = 5*slope
b_doub = r["doubling_delta_mmHg"] * r["slope_uL_min_kidney_mmHg"]
print(f"    from 'doubles in {r['doubling_delta_mmHg']:.0f} mmHg':  baseline = {b_doub:.1f} uL/min")
span = r["rpp_hi"] - r["rpp_lo"]
for f in (r["fold_low"], r["fold_high"]):
    # b + span*slope = f*b  ->  b = span*slope/(f-1)
    b = span * r["slope_uL_min_kidney_mmHg"] / (f - 1)
    print(f"    from '{f:.0f}-fold over {span:.0f} mmHg':      baseline = {b:.1f} uL/min")
print()
print("  A single constant slope of 2 uL/min/mmHg reproduces BOTH the local")
print("  doubling and the 5-20x range, given a baseline of roughly 7-35")
print("  uL/min. The 'doubling in 5 mmHg' is a statement about a RATIO on a")
print("  near-zero baseline, not about curvature.")
print()
print("  => LINEAR IS SUPPORTED. My 'markedly nonlinear' claim is RETRACTED.")
print("  Corroborating, independently: Osborn JL, Francisco LL, DiBona GF,")
print("  Proc Soc Exp Biol Med 1981 (dog, RPP 137->55 mmHg) report that")
print("  urinary sodium excretion decreased LINEARLY as RPP decreased.")

rule("2. DOES THE CHRONIC RELATIONSHIP STAY LINEAR?  (Mizelle et al. 1993)")
print("  RPP      UNaV      source")
for p, u, lab in MIZELLE:
    print(f"  {p:6.1f}   {u:5.1f}     {lab}")
print()
print("  Segment slopes, mmol/day/mmHg per kidney:")
pts = sorted(MIZELLE)
for (p0, u0, _), (p1, u1, _) in zip(pts, pts[1:]):
    print(f"    {p0:.1f} -> {p1:.1f}   {(u1-u0)/(p1-p0):6.3f}")
lo, hi = pts[0], pts[2]
simul = (hi[1] - lo[1]) / (hi[0] - lo[0])
print()
print(f"  The two 12-day kidneys are SIMULTANEOUS and share one animal, so")
print(f"  the pair {lo[0]:.1f}/{lo[1]:.0f} vs {hi[0]:.1f}/{hi[1]:.0f} is the")
print(f"  cleanest single estimate:  {simul:.3f} mmol/day/mmHg per kidney")
print(f"                             {2*simul:.3f} mmol/day/mmHg whole animal")
print()
seg1 = (pts[1][1]-pts[0][1])/(pts[1][0]-pts[0][0])
seg2 = (pts[2][1]-pts[1][1])/(pts[2][0]-pts[1][0])
print(f"  BUT the two segments differ by {seg2/seg1:.2f}x ({seg1:.3f} then {seg2:.3f}).")
print("  Three points cannot distinguish curvature from the fact that the")
print("  control point is a DIFFERENT DAY than the two servo points. This is")
print("  suggestive of steepening, NOT evidence of it. Recorded as an open")
print("  question, not a finding.")

rule("3. CROSS-CHECK: is the CALIBRATED G_pn consistent with primary data?")
print(f"  Model: G_pn = {G_PN_MODEL} mEq/day/mmHg, human, tier B, CALIBRATED.")
print(f"  Fractional form: G_pn / filtered load = {G_PN_MODEL/FILTERED_HUMAN:.3e} per mmHg")
print()
print("  Mizelle dog, scaled three ways (dog ~20 kg, GFR ~115 L/day):")
dog_total = 2 * simul
DOG_MASS, HUMAN_MASS = 20.0, 70.0
DOG_GFR = 115.0
for label, factor in (
    ("body mass  (70/20)", HUMAN_MASS / DOG_MASS),
    ("GFR        (180/115)", GFR_HUMAN / DOG_GFR),
    ("mass^0.75", (HUMAN_MASS / DOG_MASS) ** 0.75),
):
    print(f"    {label:<22} -> {dog_total*factor:6.2f} mEq/day/mmHg")
dog_filtered = DOG_GFR * C_NA
print()
print(f"  Scaling-free comparison (fraction of filtered load per mmHg):")
print(f"    dog   {dog_total/dog_filtered:.3e}")
print(f"    model {G_PN_MODEL/FILTERED_HUMAN:.3e}")
print(f"    model is {(G_PN_MODEL/FILTERED_HUMAN)/(dog_total/dog_filtered):.2f}x steeper")

rule("4. THE CONTRADICTING EVIDENCE -- does the mechanism operate at all?")
print("""  Three primary findings that the model's spine does not accommodate:

  Seeliger E, Andersen JL, Bie P, Reinhardt HW. J Physiol 2004;559:939-951.
    Freely moving dogs, isotonic saline load, RPP servo-controlled 10% below
    control. Servo-control did NOT reduce peak or cumulative sodium
    excretion. Conclusion as stated: pressure natriuresis does not contribute
    to the natriuresis following acute saline loading.

  Seeliger E, Safak E, Persson PB, Reinhardt HW. J Physiol 2001;537:941-947.
    Balance studies, freely moving dogs, contribution of pressure natriuresis
    to control of total body sodium.

  Bie P. Am J Physiol Regul Integr Comp Physiol 2018;315:R945-R962.
    Reviews the position that renal sodium excretion is regulated primarily
    by neurohumoral mechanisms keyed to extracellular volume rather than to
    arterial pressure.

  These do not say the acute pressure-natriuresis SLOPE is wrong. They say
  the slope may be largely IRRELEVANT over the physiological range, because
  natriuresis is driven by volume-sensing before pressure ever moves. The
  IPE model has no volume-sensing natriuretic path at all -- ANP does not
  exist in it -- so every gram of sodium regulation is forced through the
  pressure term. That is the real exposure, and it is structural, not a
  matter of the slope's shape.""")

rule("VERDICT")
print("""  Linear form: SUPPORTED by primary data over 90-160 mmHg acute, and
    independently reported as linear over 55-137 mmHg in dog. Keep it.
    Retract the 'markedly nonlinear' note in relations.csv.

  Validity range: state it. The linear form is evidenced over roughly
    55-160 mmHg. The model's autoregulatory breakpoints (80/180) sit
    outside the evidenced range at the top.

  Slope magnitude: the calibrated value is the right order but roughly
    4x steeper than the dog data on a filtered-load basis. Since the
    calibration target was human salt sensitivity, that gap is a real
    finding and belongs in the ledger notes.

  Curvature: NOT established. Three points across two conditions cannot
    settle it. Needs the Mizelle full dataset or a digitisation of the
    acute curve figures under validation/averaging.md.""")
