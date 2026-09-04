#!/usr/bin/env python3
"""
Respiratory parameters, and the structural result that falls out of them.

    python validation/respiratory_extract.py

Pre-registered in validation/respiratory_prereg.md, written before any source was
opened and sitting before this file in history:

    git log --diff-filter=A -- validation/respiratory_prereg.md
    git log --diff-filter=A -- validation/respiratory_extract.py

Structure decided in ADR 0017.

VERDICT: BRANCH P4 ON SOURCING, AND THE ANSWER IS BRANCH P2 ANYWAY - AND IT DOES NOT
DEPEND ON THE UNSOURCED ROWS. The chemoreflex slope and its threshold are sourced in
healthy humans. Resting CO2 production and dead space fraction could NOT be sourced in
an admissible preparation and are entered `assumed`. The pre-registration then requires
a sweep to show which the operating point turns on. The sweep shows something stronger:
NO PLAUSIBLE VALUE OF EITHER PRODUCES A NORMAL RESTING ARTERIAL PCO2. That is a
statement about the STRUCTURE, not about the two assumed numbers.
"""
from __future__ import annotations

import math

KPA_MMHG = 7.5006157584566  # exact by definition of the pascal and the mmHg


def rule(c="="):
    print(c * 78)


# ---------------------------------------------------------------------------
rule()
print("1. THE CHEMOREFLEX. SOURCED IN HEALTHY HUMANS, AND THE SEARCH ITSELF IS A RESULT")
rule()
for line in [
    "  Mannee DC, Fabius TM, Wagenaar M, Eijsvogel MMM, de Jongh FHC. Reproducibility of",
    "  hypercapnic ventilatory response measurements with steady-state and rebreathing",
    "  methods. ERJ Open Res 2018;4(1):00141-2017. doi:10.1183/23120541.00141-2017.",
    "  PMID 29492407. PMC5824331. OPEN ACCESS - full text and tables read.",
    "",
    "  20 healthy adults, both methods, two separate days. Table 1, median (IQR):",
    "",
    "      slope, steady-state, day 1     13.5 (8.3-17.3)  L/min/kPa",
    "      slope, steady-state, day 2     13.4 (8.4-16.9)",
    "      slope, rebreathing,  day 1     12.9 (9.2-16.3)",
    "      slope, rebreathing,  day 2     11.6 (7.0-17.2)",
    "      projected apnoea threshold, steady-state, day 1   3.9 (3.5-4.3) kPa",
    "      projected apnoea threshold, rebreathing,  day 1   4.1 (3.8-4.8) kPa",
    "",
    "  DIRECTIVE 1.7 DISQUALIFIED ALMOST THE ENTIRE LITERATURE, WHICH THE",
    "  PRE-REGISTRATION PREDICTED IN TERMS. A search for the CO2 response slope returns",
    "  remifentanil, alfentanil, midazolam, propofol, clonidine, diphenhydramine,",
    "  buprenorphine and etomidate. In every one of those the CO2 response is the",
    "  INSTRUMENT used to measure a drug's respiratory depression, not the subject.",
    "  Prereg section 2 trap 2 named this before the search ran.",
]:
    print(line)

SLOPE_KPA, SLOPE_IQR_KPA = 13.5, (8.3, 17.3)
PAT_KPA, PAT_IQR_KPA = 3.9, (3.5, 4.3)

SLOPE = SLOPE_KPA / KPA_MMHG
SLOPE_IQR = tuple(v / KPA_MMHG for v in SLOPE_IQR_KPA)
PAT = PAT_KPA * KPA_MMHG
PAT_IQR = tuple(v * KPA_MMHG for v in PAT_IQR_KPA)

print()
for line in [
    "  CONVERTED, 1 kPa = %.6f mmHg:" % KPA_MMHG,
    "      RESP.CHEMO.CO2_SLOPE      %.3f L/min/mmHg   IQR %.3f-%.3f" % (
        SLOPE, SLOPE_IQR[0], SLOPE_IQR[1]),
    "      RESP.CHEMO.CO2_THRESHOLD  %.1f mmHg          IQR %.1f-%.1f" % (
        PAT, PAT_IQR[0], PAT_IQR[1]),
    "",
    "  STEADY-STATE IS TAKEN, WHICH FOLLOWS THE PRE-REGISTRATION - AND THE PAPER'S OWN",
    "  HEADLINE ARGUES AGAINST IT, SO THE REASONING IS SET OUT RATHER THAN ASSUMED.",
    "  Mannee's conclusion is that REBREATHING is reproducible and steady-state is not:",
    "  intraclass correlation 0.90 against 0.49 for the slope, 0.90 against -0.08 for the",
    "  threshold. The pre-registration nevertheless preferred steady-state, on VALIDITY",
    "  grounds - this model is quasi-static by ADR 0017 and a rebreathing transient is",
    "  the wrong instrument for a quasi-static loop.",
    "",
    "  THE CONFLICT RESOLVES BECAUSE ICC AND A GROUP MEDIAN ARE DIFFERENT QUANTITIES.",
    "  An ICC says whether ONE PERSON'S measurement repeats. This ledger stores a",
    "  POPULATION CENTRAL VALUE. Mannee's own data separate the two cleanly: the",
    "  steady-state medians on the two days are 13.5 and 13.4, stable to 0.7 percent,",
    "  while the individual ICC is 0.49. So the poor reproducibility does not disqualify",
    "  the median, and no deviation from the pre-registration is needed.",
    "",
    "  AND THE TWO METHODS AGREE ON THE CENTRAL VALUE ANYWAY, 13.5 against 12.9, a 5",
    "  percent difference - so the choice barely moves the number. It moves the",
    "  DISPERSION, which is why the IQR is recorded and the method is on the row.",
    "",
    "  TIER B. n = 20, one group, one centre. The dispersion is wide and REAL: the",
    "  ventilatory response to CO2 varies several-fold between healthy people, the same",
    "  shape as the vasopressin sensitivity in HANDOVER section 7. Not narrowed.",
]:
    print(line)

# ---------------------------------------------------------------------------
print()
rule()
print("2. THE ALVEOLAR CONSTANT. DERIVED, NOT SEARCHED - AND THE DERIVATION IS HERE")
rule()
PB, PH2O_37 = 760.0, 47.0
T_BODY, T_STP = 310.15, 273.15
stpd_to_btps = (T_BODY / T_STP) * (PB / (PB - PH2O_37))
K_ALV = stpd_to_btps * (PB - PH2O_37)
for line in [
    "  PaCO2 = K * VCO2(STPD) / V_A(BTPS), with VCO2 and V_A in L/min and PaCO2 in mmHg.",
    "",
    "      dry barometric pressure      %.1f - %.1f = %.1f mmHg" % (PB, PH2O_37, PB - PH2O_37),
    "      STPD -> BTPS                 (%.2f/%.2f) x (%.0f/%.0f) = %.4f" % (
        T_BODY, T_STP, PB, PB - PH2O_37, stpd_to_btps),
    "      K = %.4f x %.1f = %.1f" % (stpd_to_btps, PB - PH2O_37, K_ALV),
    "",
    "  RESP.ALVEOLAR.K = %.0f, extraction_method = derived. It is arithmetic on physical" % K_ALV,
    "  constants, not a measurement, and the RN.NA.FRACTIONAL_REABSORPTION precedent says",
    "  a derived value needs its derivation written down rather than a citation.",
    "",
    "  IT CARRIES TWO ASSUMPTIONS AND THEY ARE ON THE ROW: sea-level barometric pressure,",
    "  and saturated water vapour at 37 C. ADR 0017 already restricts this model to sea",
    "  level by omitting the hypoxic drive; this is the second place that bites.",
]:
    print(line)

# ---------------------------------------------------------------------------
print()
rule()
print("3. TWO ROWS COULD NOT BE SOURCED. BRANCH P4, AND THE SEARCHES ARE RECORDED")
rule()
VCO2 = 0.20
VDVT = 0.30
for line in [
    "  RESP.CO2.PRODUCTION  = %.2f L/min STPD   ASSUMED" % VCO2,
    "  RESP.DEADSPACE.FRACTION = %.2f            ASSUMED" % VDVT,
    "",
    "  WHAT WAS SEARCHED AND WHY EVERY HIT WAS INADMISSIBLE, so it is not repeated:",
    "    resting metabolic rate / indirect calorimetry / reference values -> returns",
    "      prepubertal children, chronic kidney disease, and hand-held DEVICE VALIDATION",
    "      studies. The last are the instrument-not-subject trap again: the paper exists",
    "      to characterise a calorimeter, not resting metabolism.",
    "    dead space / tidal volume / healthy / rest -> returns chronic heart failure,",
    "      pneumoconiosis, dyspnoea evaluation and INCREMENTAL EXERCISE protocols.",
    "      Prereg section 2 excludes exercise and disease, fixed before the search.",
    "",
    "  BOTH ARE ROUND TEACHING NUMBERS AND ARE FLAGGED AS SUCH. Directive 1.12: 200",
    "  mL/min and a dead space fraction of 0.3 are exactly the kind of value that six of",
    "  eight comparable rows in this ledger turned out to be wrong about. They enter",
    "  `assumed`, never `reported`, and the assumed count going up is the honest outcome.",
]:
    print(line)

# ---------------------------------------------------------------------------
print()
rule()
print("4. THE CLOSED FORM, AND THE OPERATING POINT IT PRODUCES")
rule()


def resting_paco2(vco2=VCO2, vdvt=VDVT, slope=SLOPE, pat=PAT, k=K_ALV):
    """Solve the quasi-static loop in closed form. ADR 0017 decision 2: no state.

        V_E = slope * (PaCO2 - pat)          chemoreflex, rectified linear
        V_A = (1 - vdvt) * V_E               dead space
        PaCO2 = k * vco2 / V_A               alveolar ventilation equation

    =>  PaCO2^2 - pat*PaCO2 - k*vco2/((1-vdvt)*slope) = 0
    """
    c = k * vco2 / ((1.0 - vdvt) * slope)
    return (pat + math.sqrt(pat * pat + 4.0 * c)) / 2.0


p0 = resting_paco2()
ve0 = SLOPE * (p0 - PAT)
print("  V_E = slope*(PaCO2 - threshold);  V_A = (1-Vd/Vt)*V_E;  PaCO2 = K*VCO2/V_A")
print("  One quadratic, solved in closed form. NO STATE, per ADR 0017 decision 2.")
print()
print("      resting PaCO2        %6.2f mmHg" % p0)
print("      resting V_E          %6.2f L/min" % ve0)
print("      human reference      35-45 mmHg")
print()
for line in [
    "  THE OPERATING POINT IS HYPOCAPNIC. That is branch P2 of the pre-registration -",
    "  written down in advance as the interesting outcome, to be REPORTED rather than",
    "  tuned away - and it arrives even though two inputs are assumed.",
]:
    print(line)

# ---------------------------------------------------------------------------
print()
rule()
print("5. THE SWEEP THE PRE-REGISTRATION DEMANDS, AND IT MAKES THE RESULT STRUCTURAL")
rule()
print("  Branch P4 requires showing which assumed row the operating point turns on.")
print("  It turns on NEITHER strongly enough to matter.")
print()
print("  %-14s %s" % ("VCO2 L/min", "  ".join("Vd/Vt=%.2f" % v for v in (0.20, 0.30, 0.40, 0.50))))
for vco2 in (0.15, 0.20, 0.25, 0.30, 0.40):
    cells = "  ".join("%9.1f" % resting_paco2(vco2=vco2, vdvt=v)
                      for v in (0.20, 0.30, 0.40, 0.50))
    print("  %-14.2f %s" % (vco2, cells))

need = (40.0 * 40.0 - PAT * 40.0) * SLOPE / K_ALV
print()
for line in [
    "  TO REACH A NORMAL 40 mmHg THE MODEL NEEDS VCO2/(1-Vd/Vt) = %.3f L/min." % need,
    "      at Vd/Vt = 0.30 that is VCO2 = %.3f L/min, about three times resting" % (need * 0.7),
    "      at VCO2 = 0.20 that is Vd/Vt = %.3f, which is not a healthy lung" % (1 - 0.20 / need),
    "",
    "  SO NO PLAUSIBLE VALUE OF EITHER ASSUMED ROW REACHES A NORMAL PCO2, AND THAT",
    "  MAKES THIS A RESULT ABOUT THE STRUCTURE RATHER THAN ABOUT THE TWO NUMBERS.",
    "  It is the same shape as HANDOVER section 3.13's finding that the rectified renin",
    "  form cannot carry the human salt-renin response AT ANY GAIN. A form-imposed",
    "  ceiling either is or is not exceeded, and no threshold had to be chosen to say so.",
    "",
    "  THE PHYSIOLOGY THAT IS MISSING HAS A NAME. Awake humans do not stop breathing",
    "  below the apnoeic threshold; there is a non-chemoreflex drive to breathe present",
    "  in wakefulness and absent in sleep, which is why the apnoeic threshold matters",
    "  clinically in sleep and not awake. A purely rectified chemoreflex omits it, so",
    "  the loop balances at too low a PCO2. The fix is a structural term, NOT a",
    "  parameter, and the pre-registration forbids reaching for a parameter here.",
    "",
    "  WHAT MUST NOT HAPPEN NEXT: the slope, the threshold, VCO2 or the dead space",
    "  fraction being adjusted to bring PCO2 to 40. Prereg section 3 forbids it in",
    "  terms - 'no parameter may be set, adjusted or preferred because it puts PCO2",
    "  near 40' - and HANDOVER section 3.3 records what happened the last time a",
    "  missing mechanism was absorbed into a parameter.",
]:
    print(line)

# ---------------------------------------------------------------------------
print()
rule()
print("6. RESPIRATORY WATER LOSS - THE COUPLING THAT STOPS THIS BEING AN ISLAND")
rule()
R_L_ATM = 0.0820573660809596
PH2O_AMBIENT = 8.75


def gas_water(p_mmhg, t_k):
    """mg of water per litre of gas at partial pressure p and temperature t."""
    return (p_mmhg / 760.0) / (R_L_ATM * t_k) * 18.015 * 1000.0


w_exp = gas_water(PH2O_37, T_BODY)
w_ins = gas_water(PH2O_AMBIENT, 293.15)
net = w_exp - w_ins
loss = ve0 * 1440.0 * net / 1e6
for line in [
    "  Expired gas leaves saturated at body temperature; inspired gas carries whatever",
    "  the room holds. The difference is a water flux and it is pure mass balance.",
    "",
    "      expired,  47.0 mmHg at 37.0 C      %.1f mg/L" % w_exp,
    "      inspired,  8.75 mmHg at 20.0 C     %.1f mg/L" % w_ins,
    "      net                                %.1f mg/L" % net,
    "",
    "      at V_E = %.2f L/min  ->  %.3f L/day of respiratory water loss" % (ve0, loss),
    "",
    "  AND IT LANDS IN THE RIGHT PLACE, WHICH IS THE FIRST EXTERNAL CHECK THIS COMPONENT",
    "  HAS PASSED. BF.H2O.INSENSIBLE_LOSS is 0.8 L/day, `assumed`, cited 'Convention",
    "  pending primary source.' This derivation accounts for %.0f percent of it from" % (loss / 0.8 * 100),
    "  physical constants and a sourced chemoreflex, leaving %.3f L/day as the" % (0.8 - loss),
    "  cutaneous residual - which is the conventional split, reached without being aimed",
    "  at it. NOTE that the ventilation it uses comes from the hypocapnic operating point",
    "  above, so this figure moves when the wakefulness drive is added.",
    "",
    "  THE AMBIENT CONDITIONS ARE ASSUMED - 20 C and 50 percent relative humidity - and",
    "  they belong on the row. A model breathing desert air loses more.",
]:
    print(line)
print()
