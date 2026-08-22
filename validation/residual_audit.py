#!/usr/bin/env python
"""Audit the 3.68x slope inflation, and the 2.2x residual derived from it.

Blocker 3 of ADR 0010 asks what explains the ~2.2x of the 3.68x inflation that
the missing ANP path does not cover. Before hunting mechanisms, this checks
whether 3.68 is itself a well-determined number.

It is not. It rests on two choices that are not measurements, and the residual
inherits both. No literature is extracted here - this is arithmetic on numbers
already in the repo (validation/pn_data.py, ledger/parameters.csv).

Run:  python validation/residual_audit.py
"""

import math

# --- from ledger/parameters.csv -------------------------------------------
G_PN_MODEL = 20.0        # RN.PRESSURE_NATRIURESIS.SLOPE, mEq/day/mmHg, CALIBRATED
GFR_HUMAN = 180.0        # RN.GFR.NOMINAL, L/day
C_NA = 140.0             # BF.NA.PLASMA_SETPOINT, mEq/L
FILTERED_HUMAN = GFR_HUMAN * C_NA

# --- from validation/pn_data.py, Mizelle 1993 (PMID 8319986), dog ----------
MIZELLE = [
    (74.2, 25.0, "servo-controlled kidney, 12 d"),
    (86.7, 41.0, "control, both kidneys, pre-servo"),
    (91.5, 55.0, "contralateral kidney, 12 d"),
]

# THE TWO ASSUMPTIONS UNDER AUDIT. Neither is cited to Mizelle or anywhere.
DOG_GFR_ASSUMED = 115.0  # L/day   <-- pn_data.py: "dog ~20 kg, GFR ~115 L/day"
DOG_MASS_ASSUMED = 20.0  # kg      <-- same comment, also uncited

ANP_SHARE = 0.40         # De Nicola 1997 PMID 9071713, ~40% of the increment
ANP_FACTOR = 1.0 / (1.0 - ANP_SHARE)   # 1.667x


def rule(t):
    print("\n" + "=" * 74)
    print(t)
    print("=" * 74)


def ratio_for(dog_gfr, dog_slope_whole):
    """Model fractional slope divided by dog fractional slope."""
    model_frac = G_PN_MODEL / FILTERED_HUMAN
    dog_frac = dog_slope_whole / (dog_gfr * C_NA)
    return model_frac / dog_frac


rule("0. REPRODUCE THE PUBLISHED NUMBERS FIRST")
pts = sorted(MIZELLE)
simul = (pts[2][1] - pts[0][1]) / (pts[2][0] - pts[0][0])
dog_total = 2 * simul
print(f"  per-kidney slope, the two simultaneous 12-d kidneys : {simul:.4f} mmol/day/mmHg")
print(f"  whole animal (x2)                                   : {dog_total:.4f} mmol/day/mmHg")
print(f"  model fractional slope   G_pn / (GFR*C_Na)          : {G_PN_MODEL/FILTERED_HUMAN:.4e} /mmHg")
print(f"  dog   fractional slope   at assumed GFR {DOG_GFR_ASSUMED:.0f} L/day  : "
      f"{dog_total/(DOG_GFR_ASSUMED*C_NA):.4e} /mmHg")
r0 = ratio_for(DOG_GFR_ASSUMED, dog_total)
print(f"  inflation ratio                                     : {r0:.4f}x")
print(f"  ledger/ADR quote 3.68x -- reproduced: {'YES' if abs(r0-3.68) < 0.01 else 'NO'}")
resid0 = r0 / ANP_FACTOR
print(f"  ANP factor 1/(1-0.40)                               : {ANP_FACTOR:.4f}x")
print(f"  residual = {r0:.4f} / {ANP_FACTOR:.4f}                          : {resid0:.4f}x")
print(f"  ADR quote ~2.2x -- reproduced: {'YES' if abs(resid0-2.2) < 0.05 else 'NO'}")

rule("1. ASSUMPTION A -- THE DOG GFR IS UNCITED AND THE RATIO IS PROPORTIONAL TO IT")
print("  The ratio compares FRACTIONS of filtered load. The dog's filtered load")
print("  is GFR_dog * C_Na, and GFR_dog is not reported in pn_data.py from")
print("  Mizelle -- it is a parenthetical estimate. So:")
print()
k = r0 / DOG_GFR_ASSUMED
print(f"      inflation ratio = {k:.5f} x GFR_dog(L/day)      -- exactly linear")
print()
print("  Canine GFR is conventionally 2.5-4.5 mL/min/kg. For the assumed 20 kg dog:")
print()
print("   mL/min/kg   GFR L/day    inflation    residual after ANP")
print("   " + "-" * 56)
for per_kg in (2.5, 3.0, 3.5, 4.0, 4.5):
    gfr = per_kg * DOG_MASS_ASSUMED * 60 * 24 / 1000.0
    r = ratio_for(gfr, dog_total)
    print(f"   {per_kg:>6.1f}     {gfr:8.1f}     {r:7.3f}x     {r/ANP_FACTOR:7.3f}x")
print()
print(f"  The assumed {DOG_GFR_ASSUMED:.0f} L/day corresponds to "
      f"{DOG_GFR_ASSUMED*1000/(DOG_MASS_ASSUMED*60*24):.2f} mL/min/kg,")
print("  at the TOP of that conventional range. The residual is not 2.2x; on")
print("  this axis alone it spans roughly 1.4x to 2.5x.")

rule("2. ASSUMPTION B -- MIZELLE'S OWN THREE POINTS DO NOT AGREE WITH EACH OTHER")
seg = []
for (p0, u0, l0), (p1, u1, l1) in zip(pts, pts[1:]):
    s = (u1 - u0) / (p1 - p0)
    seg.append(s)
    print(f"  {p0:5.1f} -> {p1:5.1f} mmHg   slope {s:6.3f} mmol/day/mmHg/kidney")
print(f"  {pts[0][0]:5.1f} -> {pts[2][0]:5.1f} mmHg   slope {simul:6.3f}   "
      f"<- the two simultaneous kidneys, adopted")
print()
print(f"  The two segments differ by {seg[1]/seg[0]:.2f}x. pn_data.py already flags this")
print("  as 'suggestive of steepening, NOT evidence of it'. But the adopted")
print("  slope is one of three defensible readings of the same three points:")
print()
print("   reading                          whole-animal    inflation   residual")
print("   " + "-" * 66)
for label, s in (("low segment  74.2->86.7", seg[0]),
                 ("simultaneous 74.2->91.5", simul),
                 ("high segment 86.7->91.5", seg[1])):
    r = ratio_for(DOG_GFR_ASSUMED, 2 * s)
    print(f"   {label:<30}   {2*s:7.3f}      {r:7.3f}x   {r/ANP_FACTOR:7.3f}x")

rule("2b. A THIRD EFFECT THE COMPARISON NEVER ACCOUNTED FOR")
print("""  Mizelle's abstract, verified 2026-08-22 against the PubMed record
  (PMID 8319986, DOI 10.1161/01.hyp.22.1.102, Mizelle HL, Montani JP,
  Hester RL, Didlake RH, Hall JE, Hypertension 1993;22:102-110):

    "in the low-pressure kidney, glomerular filtration rate was slightly
     but significantly lower (approximately 8%) than in the contralateral
     kidney"

  All three RPP/UNaV points in pn_data.py are reproduced exactly by that
  abstract, so the transcription is right. But the FILTERED LOAD was not
  constant between the two kidneys, and the comparison assumes it was.

  This matters because the model's G_pn is a slope AT CONSTANT FILTERED LOAD:
      Na_excr = Na_filtered*(1 - FR_Na) + G_pn*(MAP - MAP_ref)
  and IPE's GFR is flat over 80-160 mmHg, so d(Na_filtered)/dMAP = 0 at the
  operating point. Mizelle's raw between-kidney dUNaV/dRPP therefore contains
  a filtered-load term the model's parameter does not.""")
GFR_GAP = 0.08
per_kidney_gfr = DOG_GFR_ASSUMED / 2.0
F_hi = per_kidney_gfr * C_NA
F_lo = F_hi * (1.0 - GFR_GAP)
E_hi, E_lo = pts[2][1], pts[0][1]
one_minus_fr = E_hi / F_hi
load_term = (F_hi - F_lo) * one_minus_fr
dP = pts[2][0] - pts[0][0]
corrected_per_kidney = (E_hi - E_lo - load_term) / dP
print(f"\n  per-kidney filtered load at assumed GFR : {F_hi:8.1f} mEq/day (high-P kidney)")
print(f"  implied (1 - FR_Na) from E/F            : {one_minus_fr:8.5f}")
print(f"  filtered-load contribution to the 30    : {load_term:8.2f} mmol/day "
      f"({100*load_term/(E_hi-E_lo):.1f}% of it)")
print(f"  pressure-only slope, per kidney         : {corrected_per_kidney:8.4f} "
      f"(was {simul:.4f})")
r_corr = ratio_for(DOG_GFR_ASSUMED, 2 * corrected_per_kidney)
print(f"  inflation ratio, load-corrected         : {r_corr:8.3f}x (was {r0:.3f}x)")
print(f"  residual after ANP                      : {r_corr/ANP_FACTOR:8.3f}x "
      f"(was {resid0:.3f}x)")
print("""
  NOTE THE DIRECTION. Correcting for it makes the dog's pressure-only slope
  SMALLER, so the model looks MORE inflated, not less. This correction widens
  the gap. It is small next to the assumptions above, but it is a real bias and
  it has been sitting in the comparison unnoticed in the favourable direction.""")

rule("3. THE TWO UNCERTAINTIES TOGETHER")
lo_gfr = 2.5 * DOG_MASS_ASSUMED * 60 * 24 / 1000.0
hi_gfr = 4.5 * DOG_MASS_ASSUMED * 60 * 24 / 1000.0
combos = []
for gfr in (lo_gfr, hi_gfr):
    for s in (seg[0], simul, seg[1]):
        combos.append(ratio_for(gfr, 2 * s))
print(f"  inflation ratio ranges {min(combos):.2f}x to {max(combos):.2f}x")
print(f"  residual after ANP     {min(combos)/ANP_FACTOR:.2f}x to "
      f"{max(combos)/ANP_FACTOR:.2f}x")
print()
print(f"  The quoted 3.68x and 2.2x are ONE point inside that box, not the box.")
print(f"  At the low corner the residual is {min(combos)/ANP_FACTOR:.2f}x -- i.e. ANP")
print("  would account for essentially the whole discrepancy and there would be")
print("  no residual to explain. At the high corner it is "
      f"{max(combos)/ANP_FACTOR:.2f}x.")

rule("4. WHAT WOULD HAVE TO BE TRUE FOR THE RESIDUAL TO VANISH")
need_gfr = ANP_FACTOR / k
print(f"  Holding the adopted slope, the residual reaches 1.0x (ANP explains")
print(f"  everything) at GFR_dog = {need_gfr:.1f} L/day = "
      f"{need_gfr*1000/(DOG_MASS_ASSUMED*60*24):.2f} mL/min/kg.")
print("  That is below the conventional canine range, so the assumed-20-kg dog")
print("  cannot make the residual disappear on its own. SOMETHING is unexplained")
print("  at the adopted slope -- but its size is not 2.2x, it is 1.4-2.5x, and")
print("  the high segment reading removes it entirely.")

rule("VERDICT")
print("""  The 2.2x residual is quoted throughout HANDOVER.md and ADR 0010 as a
  definite quantity -- "a residual factor of roughly 2.2x is not explained".
  It is a point value carrying no uncertainty, and it is derived from:

    (a) an UNCITED dog GFR of 115 L/day, to which the ratio is exactly
        proportional, sitting at the top of the conventional canine range; and
    (b) one of three defensible slope readings of Mizelle's own three points,
        which disagree among themselves by 2.28x.

  Neither is a measurement. Propagating both, the residual is 0.8-3.4x rather
  than 2.2x, and at the favourable corner there is no residual at all.

  A THIRD effect (section 2b) was not in the comparison at all: Mizelle's two
  kidneys differed in GFR by ~8%, so the raw between-kidney slope carries a
  filtered-load term that the model's constant-filtered-load G_pn does not.
  Removing it moves the ratio 3.68 -> 4.32 and the residual 2.21 -> 2.59. That
  one is a genuine bias rather than an uncertainty, and it points the other way:
  the gap is WIDER than recorded, not narrower.

  This does NOT show the residual is zero. At the adopted slope and any
  plausible canine GFR something remains unexplained. It shows the residual is
  not currently a 2.2x-shaped fact, and that the cheapest way to sharpen it is
  not to investigate NCC, renal nerves or the calibration target, but to open
  Mizelle 1993 and read the dog weights and GFRs actually reported.

  DO NOT record any of these numbers as a parameter. Nothing here is sourced;
  it is a sensitivity analysis of numbers already in the repo.""")
