#!/usr/bin/env python3
"""
Resting metabolic rate, and the two assumed rows it discharges.

    python validation/metabolic_rate_extract.py

Pre-registered in validation/metabolic_rate_prereg.md, which states plainly that
half of it is NOT pre-registered - McMurray 2014 was opened first, while
investigating the Fick arm's extraction ratio - and then fixes the decisions that
had not been made: the stratum, whether to sex the row, and four branches, all
blind to what any of them does to the model.

    git log --diff-filter=A -- validation/metabolic_rate_prereg.md
    git log --diff-filter=A -- validation/metabolic_rate_extract.py
"""
import math


def rule(c="="):
    print(c * 80)


R = 0.80
MASS = 70.0
WEIR = 3.941 + 1.106 * R

RMR_NORMAL = (0.960 + 0.926) / 2.0
RMR_ALLBMI = (0.892 + 0.839) / 2.0


def chain(rmr):
    ee = rmr * MASS / 60.0
    vo2 = ee / WEIR
    return ee, vo2, R * vo2


rule()
print("1. THE SOURCE, AND WHY THE EARLIER SEARCH MISSED IT")
rule()
for line in [
    "  McMurray RG, Soares J, Caspersen CJ, McCurdy T. Examining variations of resting",
    "  metabolic rate of adults: a public health perspective. Med Sci Sports Exerc",
    "  2014;46(7):1352-8. doi:10.1249/MSS.0000000000000232. PMID 24300125, PMC4535334.",
    "  READ IN FULL, via the Europe PMC rendered PDF.",
    "",
    "  197 studies, 397 publication estimates, inverse-variance weighted.",
    "",
    "  RESP.CO2.PRODUCTION's own ledger note recorded a search that failed: 'resting",
    "  metabolic rate / indirect calorimetry / reference values returns prepubertal",
    "  children, chronic disease...'. IT MISSED A WEIGHTED META-ANALYSIS OF 197 STUDIES",
    "  WHOSE SUBJECT IS EXACTLY THIS ROW. The paper exists to test the 1.0 kcal/kg/h",
    "  metabolic-equivalent convention - which is directive 1.12's subject stated as a",
    "  paper title - and its conclusion is that the convention overestimates resting",
    "  metabolic rate by about 10 percent in men and almost 15 percent in women.",
    "",
    "  THAT IS WORTH RECORDING AS A SEARCH FAILURE, NOT JUST AS A SOURCE. The row was",
    "  entered `assumed` with 'no admissible source could be opened', and the reader of",
    "  that note would reasonably stop looking. A recorded failed search is evidence",
    "  about the searcher, not about the literature.",
]:
    print(line)

print()
rule()
print("2. THE STRATA, AND THE ONE CHOSEN")
rule()
print("    %-34s %8s %10s %10s" % ("", "kcal/kg/h", "VO2 mL/min", "VCO2 L/min"))
for tag, rmr in (("men, normal weight", 0.960), ("women, normal weight", 0.926),
                 ("MEAN, NORMAL WEIGHT  [ENTERED]", RMR_NORMAL),
                 ("men, all BMI", 0.892), ("women, all BMI", 0.839),
                 ("mean, all BMI  [alternative]", RMR_ALLBMI),
                 ("obese men", 0.791), ("obese women", 0.721),
                 ("the MET convention", 1.0)):
    _, vo2, vco2 = chain(rmr)
    print("    %-34s %8.3f %10.0f %10.4f" % (tag, rmr, vo2 * 1000, vco2))

print()
for line in [
    "  NORMAL WEIGHT, because the model's reference individual is a healthy 70 kg adult",
    "  and the all-BMI means pool in subgroups whose metabolic rate per kilogram is",
    "  lower for a reason this model cannot represent: it has no body composition, and",
    "  fat mass is metabolically less active. FIXED IN THE PRE-REGISTRATION BEFORE ANY",
    "  CONSEQUENCE WAS COMPUTED.",
    "",
    "  THE TWO CHOICES DIFFER BY 8 PERCENT, which is about ten times either stratum's",
    "  own confidence interval. So the ledger's uncertainty range is the STRATUM CHOICE",
    "  and not a CI, and saying which is which is the whole of directive 1.9 here.",
    "",
    "  A SEXED PAIR IS SUPPORTED AND IS NOT TAKEN. This row drives basal ventilation,",
    "  which drives the respiratory water flux, whose residual closes against",
    "  BF.H2O.INSENSIBLE_LOSS - assumed, 0.8 L/day, unsexed. Sexing one half against an",
    "  unsexed total either invents a sexed total or puts the whole sex difference into",
    "  the cutaneous residual. Neither is sourced. ADR 0014 is satisfied by recording",
    "  the pair and the reason, not by taking it.",
]:
    print(line)

print()
rule()
print("3. THE CONVERSION, AND WHY AN ASSUMED EXCHANGE RATIO DOES NOT BLOCK IT")
rule()
print("  Weir JB de V. J Physiol 1949;109(1-2):1-9, PMC1392602, without urinary nitrogen:")
print("      EE (kcal/min) = 3.941*VO2 + 1.106*VCO2,  so  VO2 = EE / (3.941 + 1.106*R)")
print()
for r in (0.70, 0.75, 0.80, 0.85, 0.90):
    print("      R = %.2f  ->  denominator %.4f  ->  VO2 %.1f mL/min"
          % (r, 3.941 + 1.106 * r, RMR_NORMAL * MASS / 60.0 / (3.941 + 1.106 * r) * 1000))
print()
print("  +/- 1.1 PERCENT ACROSS THE WHOLE PLAUSIBLE RESTING RANGE, against an 8 percent")
print("  stratum choice. RESP.EXCHANGE_RATIO stays `assumed` and its weakness is")
print("  inherited at one percent, which is stated rather than hoped.")

_, VO2, VCO2 = chain(RMR_NORMAL)
K, FD, PACO2, WGAS, INSENS = 862.9, 0.30, 40.0, 35.15, 0.8
VE = K * VCO2 / ((1 - FD) * PACO2)
H2O = VE * 1440 * WGAS / 1e6

print()
rule()
print("4. WHAT MOVES, AND BRANCH M1")
rule()
print("    %-28s %12s %12s" % ("", "was", "now"))
for tag, a, b in (("RESP.CO2.PRODUCTION L/min", 0.20, VCO2),
                  ("RESP.VENTILATION.BASAL L/min", 6.1636, VE),
                  ("respiratory water L/day", 0.3120, H2O),
                  ("BF.H2O.CUTANEOUS_LOSS L/day", 0.4880, INSENS - H2O),
                  ("oxygen consumption mL/min", 250.0, VO2 * 1000)):
    print("    %-28s %12.4f %12.4f" % (tag, a, b))
print()
for line in [
    "  BRANCH M1 FIRES: ventilation lands at 5.62 L/min, inside the 4-8 the",
    "  pre-registration fixed before the number was computed. It is at the low end, and",
    "  the reason is worth naming rather than smoothing: this is what a SOURCED",
    "  metabolic rate and an ASSUMED dead-space fraction of 0.30 imply together, and",
    "  branch M2 forbade moving the dead space to make ventilation come out. That is",
    "  the row to source next.",
    "",
    "  ARTERIAL PCO2 DOES NOT MOVE, which branch M4 required. It is a sourced INPUT",
    "  under ADR 0017's amendment and ventilation is derived from it, so a change here",
    "  would mean the derivation had been run backwards.",
    "",
    "  THE WATER BALANCE DOES NOT MOVE EITHER. The respiratory and cutaneous halves",
    "  re-split; their sum is unchanged, so extracellular volume, plasma sodium and",
    "  arterial pressure are bit-identical. The respiratory share goes from 39 percent",
    "  of insensible loss to 36.",
]:
    print(line)

CO = 8570.065 * 1000 / 1440
CAO2 = 20.886842
KHB = 21.29
AV = VO2 * 1000 / CO * 100
AV_OLD = 250.0 / CO * 100

print()
rule()
print("5. BRANCH M3 FIRES, AND IT POINTS AT CARDIAC OUTPUT")
rule()
print("                        oxygen consumption   a-vO2      extraction   SvO2")
print("    before   %18.0f mL/min %8.2f mL/dL %8.1f%% %8.1f%%"
      % (250.0, AV_OLD, AV_OLD / CAO2 * 100, (CAO2 - AV_OLD) / KHB * 100))
print("    sourced  %18.0f mL/min %8.2f mL/dL %8.1f%% %8.1f%%"
      % (VO2 * 1000, AV, AV / CAO2 * 100, (CAO2 - AV) / KHB * 100))
print()
for line in [
    "  A BETTER-SOURCED OXYGEN CONSUMPTION MADE THE EXTRACTION RATIO WORSE, and the",
    "  pre-registration required that be reported rather than rescued. Measured mixed",
    "  venous saturation near 75 percent implies an extraction ratio near 23; the model",
    "  now gives 18.3.",
    "",
    "  THE ARITHMETIC LOCATES IT WITHOUT AMBIGUITY. Extraction is VO2 over cardiac",
    "  output times arterial content. Consumption is now the best-sourced of the three",
    "  and arterial content follows from haemoglobin and a sourced dissociation curve.",
    "  What is left is cardiac output:",
]:
    print(line)
print()
print("      Fick-consistent cardiac output at 23%% extraction:  %.2f L/min"
      % (VO2 * 1000 / (0.23 * CAO2 / 100) / 1000))
print("      the model's CV.CO.NOMINAL:                          %.2f L/min" % (CO / 1000))
print()
for line in [
    "  AND THE LIKELY REASON IS METHODOLOGICAL, WHICH MAKES IT THE SAME CLASS OF ERROR",
    "  AS THE THYROID ONE. CV.CO.NOMINAL is derived from a stroke volume measured by",
    "  CARDIAC MAGNETIC RESONANCE (UK Biobank), while every mixed-venous saturation and",
    "  extraction ratio in the literature comes from populations whose cardiac output",
    "  was measured by thermodilution or by Fick. Composing one method's cardiac output",
    "  with another method's venous saturation is the same move as composing an",
    "  immunoassay's free thyroxine with a dialysis concentration - HANDOVER section",
    "  3.26, and section 5 item 18.",
    "",
    "  IT IS NOT CLOSED HERE. Re-sourcing the stroke volume is its own pre-registered",
    "  pass, and doing it inside this one would be adjusting a second parameter to",
    "  rescue the first.",
]:
    print(line)
print()
