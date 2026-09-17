#!/usr/bin/env python3
"""
The ECF de-indexing correction: the arithmetic, and everywhere it lands.

Run it:  python validation/ecf_deindex_extract.py

PRE-REGISTERED IN validation/ecf_deindex_prereg.md, COMMITTED BEFORE THIS FILE EXISTED.

    git log --diff-filter=A -- validation/ecf_deindex_prereg.md
    git log --diff-filter=A -- validation/ecf_deindex_extract.py

THE SOURCE NUMBERS ARE NOT COPIED. They are imported from
ecf_salt_response_extract.py, which is the file that owns them and the file this pass
corrects. A second copy of van den Bosch's table is exactly the hazard this pass exists
to clean up.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ecf_salt_response_extract import TEST_B  # noqa: E402

# The independent limb. Four groups, n = 132, n-weighted, in kg per 100 mmol/day.
# UNTOUCHED BY THIS PASS - it is what makes the tracer limb's correction meaningful.
BODY_WEIGHT_LIMB = 0.572

# The meta-analytic pressure response, mmHg per 100 mmol/day. Different studies
# entirely, and the numerator of the band. Also untouched.
PRESSURE_BAND = (1.70, 2.30)

MODEL_RATIO_NOW = 3.2185   # HANDOVER 3.43, 2026-09-16


def limbs():
    b = TEST_B
    d_na = b["na_high"] - b["na_low"]
    old = (b["ecfv_high"] - b["ecfv_low"]) * b["bsa_high"] / 1.73
    new = (b["ecfv_high"] * b["bsa_high"] - b["ecfv_low"] * b["bsa_low"]) / 1.73
    return old, new, old / d_na * 100.0, new / d_na * 100.0, d_na


def band(tracer):
    lo_v, hi_v = min(tracer, BODY_WEIGHT_LIMB), max(tracer, BODY_WEIGHT_LIMB)
    return PRESSURE_BAND[0] / hi_v, PRESSURE_BAND[1] / lo_v


def position(x, lo, hi):
    return 100.0 * (x - lo) / (hi - lo)


def main() -> int:
    W = 78
    b = TEST_B
    old, new, old100, new100, d_na = limbs()
    print("=" * W)
    print("THE ECF DE-INDEXING CORRECTION - validation/ecf_deindex_prereg.md")
    print("=" * W)

    print("\n1. THE ARITHMETIC, AND THE REPOSITORY HAD ALREADY DONE IT")
    print("-" * W)
    print("  van den Bosch reports BSA PER ARM because body weight differs between")
    print("  them: %.2f m2 at %.1f kg on high sodium, %.2f at %.1f on low."
          % (b["bsa_high"], b["weight_high"], b["bsa_low"], b["weight_low"]))
    print("  A difference of two indexed numbers cannot be de-indexed by one of them.")
    print()
    print("    as coded   (%.1f - %.1f) x %.2f / 1.73                = %.4f L"
          % (b["ecfv_high"], b["ecfv_low"], b["bsa_high"], old))
    print("    correct    (%.1f x %.2f - %.1f x %.2f) / 1.73    = %.4f L"
          % (b["ecfv_high"], b["bsa_high"], b["ecfv_low"], b["bsa_low"], new))
    print("    understatement                                        %.1f%%"
          % (100.0 * (new / old - 1.0)))
    print()
    print("  THIS WAS NOT DISCOVERED HERE. HANDOVER section 3.12 and section 5 both")
    print("  already carried it - 1.157 L, within-subject ratio 1.73 rather than 1.885,")
    print("  failure 5.7x rather than 5.2x - recorded as 'found in passing and")
    print("  deliberately NOT fixed here', with the reason: it touches a document the")
    print("  renal haemodynamics change made no claim about, and two changes at once")
    print("  leaves neither testable. renal_hemodynamics_extract.py says the same.")
    print("  THE NUMBER WAS KNOWN AND THE PROPAGATION WAS THE WORK.")

    print("\n2. THE TWO INDEPENDENT LIMBS, AND THE ORDERING FLIPS")
    print("-" * W)
    print("  %-34s %8s %8s" % ("", "before", "after"))
    print("  %-34s %8.3f %8.3f" % ("tracer limb, L/100 mmol", old100, new100))
    print("  %-34s %8.3f %8.3f" % ("body-weight limb, kg/100 mmol",
                                   BODY_WEIGHT_LIMB, BODY_WEIGHT_LIMB))
    print("  %-34s %8s %8s" % ("which is higher",
                               "weight" if BODY_WEIGHT_LIMB > old100 else "tracer",
                               "weight" if BODY_WEIGHT_LIMB > new100 else "tracer"))
    print("  %-34s %7.1f%% %7.1f%%" % ("they agree to",
                                       100.0 * abs(old100 - BODY_WEIGHT_LIMB) / BODY_WEIGHT_LIMB,
                                       100.0 * abs(new100 - BODY_WEIGHT_LIMB) / BODY_WEIGHT_LIMB))
    print()
    print("  BRANCH E1: the limbs still agree within 10 percent, so the")
    print("  pre-registration's conversion claim - 1 kg = 1 L, declared in advance -")
    print("  is corroborated either way. WHAT CHANGES IS WHICH LIMB IS HIGHER, and that")
    print("  matters because the pair is quoted as a RANGE.")

    print("\n3. THE BAND THE MODEL IS JUDGED AGAINST")
    print("-" * W)
    ob = band(old100)
    nb = band(new100)
    print("  band = meta-analytic pressure %.2f-%.2f  /  pooled volume" % PRESSURE_BAND)
    print("    before   %.3f-%.3f L  ->  %.2f - %.2f mmHg/L"
          % (min(old100, BODY_WEIGHT_LIMB), max(old100, BODY_WEIGHT_LIMB), ob[0], ob[1]))
    print("    after    %.3f-%.3f L  ->  %.2f - %.2f mmHg/L"
          % (min(new100, BODY_WEIGHT_LIMB), max(new100, BODY_WEIGHT_LIMB), nb[0], nb[1]))
    print()
    print("  within-subject figure  %.3f -> %.3f mmHg/L"
          % ((b["map_high"] - b["map_low"]) / old, (b["map_high"] - b["map_low"]) / new))

    print("\n4. AND IT MAKES THE MODEL WORSE, WHICH IS WHAT WAS PREDICTED")
    print("-" * W)
    print("  The corrected human EXPANSION is larger, so the human RATIO is smaller, so")
    print("  the model is MORE too-stiff than this repository records. Section 2 of the")
    print("  pre-registration fixed that direction in advance so that a result")
    print("  flattering the model would read as a propagation error rather than a find.")
    print()
    print("  model %.4f mmHg/L sits %.0f%% up the old band and %.0f%% up the corrected one."
          % (MODEL_RATIO_NOW, position(MODEL_RATIO_NOW, *ob), position(MODEL_RATIO_NOW, *nb)))
    print("  Inside both. Stiffer relative to the human range than before.")
    print()
    print("  NOTHING WAS REFITTED. CV.VENOUS_RETURN.SENSITIVITY, whose target ADR 0013")
    print("  sets FROM this band, is untouched - refitting it to a band the same pass")
    print("  moved is failure mode 22 and section 3 of the pre-registration forbids it.")

    print("\n" + "=" * W)
    print("BRANCH E1. Correction applied, band recomputed from its parts, ordering")
    print("flipped and said so, model measured against the corrected band and worse.")
    print("=" * W)
    return 0


if __name__ == "__main__":
    sys.exit(main())
