#!/usr/bin/env python3
"""
SMOKE DETECTOR ONLY -- NOT A VALIDATOR.

A scipy reduction of the IPE closed loop with a candidate RAAS attached.
Its job is to catch sign errors, runaway feedback and stiffness blowups in
seconds, and to answer two STRUCTURAL questions before any Julia is written:

  Q1  Does aldosterone-on-distal-reabsorption change the effective
      pressure-natriuresis slope that RN.PRESSURE_NATRIURESIS.SLOPE was
      calibrated to?
  Q2  Does angiotensin-II-on-TPR change long-run MAP, or only the volume
      at which that MAP is reached?

Ledger constants are READ FROM ledger/parameters.csv, not typed in. The
previous prototype guessed them and consequently showed no salt sensitivity
at all (HANDOVER2 section 3).

The RAAS gains are NOT in the ledger and are GUESSED. Any number this file
prints that depends on them is a shape, not a result. Do not quote them.
"""
import csv
import numpy as np
from scipy.integrate import solve_ivp

LEDGER = "/home/claude/ipe/ledger/parameters.csv"
P = {r["param_id"]: float(r["value"]) for r in csv.DictReader(open(LEDGER))}

# ---- ledger-backed constants (days as the time base, as in BodyFluids.jl) ----
M_BODY   = 70.0
F_ICF    = P["BF.ICF.MASS_FRACTION"]
F_ECF    = P["BF.ECF.MASS_FRACTION"]
C_NA_SET = P["BF.NA.PLASMA_SETPOINT"]
OSM_SET  = P["BF.OSM.PLASMA_SETPOINT"]
OSM_OTH  = P["BF.OSM.NONSODIUM"]
TAU_OSM  = P["BF.ICF_ECF.OSMOTIC_TAU"] / 1440.0        # min -> day
H2O_IN   = P["BF.H2O.INTAKE_NOMINAL"]
H2O_INS  = P["BF.H2O.INSENSIBLE_LOSS"]

GFR0     = P["RN.GFR.NOMINAL"]
FR_NA    = P["RN.NA.FRACTIONAL_REABSORPTION"]
G_PN     = P["RN.PRESSURE_NATRIURESIS.SLOPE"]
MAP_LO   = P["RN.AUTOREG.LOWER"]
MAP_HI   = P["RN.AUTOREG.UPPER"]
V_MIN    = P["RN.H2O.OBLIGATORY_LOSS"]

CO0      = P["CV.CO.NOMINAL"]
MAP_REF  = P["CV.MAP.SETPOINT"]
TPR0     = P["CV.TPR.NOMINAL"]
BV0      = P["CV.BLOOD_VOLUME.NOMINAL"]
HCT      = P["CV.HEMATOCRIT.NOMINAL"]
F_PV     = P["CV.PLASMA.ECF_FRACTION"]
G_VR     = P["CV.VENOUS_RETURN.SENSITIVITY"]

G_BR     = P["BR.OPEN_LOOP_GAIN"]
TAU_BR   = P["BR.EFFECTOR.TAU"] / 86400.0              # s -> day
TAU_RST  = P["BR.RESET.TAU"]
SAT      = P["BR.TPR.MAX_FRACTION"]

OSM_SOLUTE_ICF = OSM_SET * M_BODY * F_ICF

# ---- RAAS gains: GUESSED, not ledgered ----------------------------------
class Raas:
    def __init__(self, g_ang=3.0, tau_ang=0.01, g_aldo=0.8, tau_aldo=0.05,
                 k_aldo=0.005, k_tpr=0.15, on=True):
        self.g_ang, self.tau_ang = g_ang, tau_ang
        self.g_aldo, self.tau_aldo = g_aldo, tau_aldo
        self.k_aldo, self.k_tpr = k_aldo, k_tpr
        self.on = on

OFF = Raas(on=False)


def rhs(t, y, intake, raas, baroreflex=True):
    Na_ecf, V_ecf, V_icf, tpr_br, sp, A_ang, A_aldo = y

    C_Na    = Na_ecf / V_ecf
    Osm_ecf = 2 * C_Na + OSM_OTH
    Osm_icf = OSM_SOLUTE_ICF / V_icf
    J_osm   = V_icf * (Osm_icf - Osm_ecf) / OSM_SET / TAU_OSM

    V_plasma = F_PV * V_ecf
    V_blood  = V_plasma / (1 - HCT)
    CO       = max(0.0, CO0 + G_VR * (V_blood - BV0))

    # Baroreflex and Ang II scale the SAME tpr_mod path, multiplicatively.
    ang_tpr = 1 + raas.k_tpr * (A_ang - 1) if raas.on else 1.0
    tpr_mod = tpr_br * ang_tpr
    MAP     = CO * TPR0 * tpr_mod

    GFR = GFR0 * (MAP / MAP_LO if MAP < MAP_LO
                  else MAP / MAP_HI if MAP > MAP_HI else 1.0)
    Na_filtered = GFR * C_Na

    aldo_term = raas.k_aldo * (A_aldo - 1) if raas.on else 0.0
    FR_eff = np.clip(FR_NA + aldo_term - G_PN * (MAP - MAP_REF) / Na_filtered,
                     0.0, 1.0)
    Na_excr  = Na_filtered * (1 - FR_eff)
    H2O_excr = max(V_MIN, H2O_IN - H2O_INS)

    if baroreflex:
        err     = MAP - sp
        drive   = -SAT * np.tanh(G_BR * err / (SAT * MAP_REF))
        d_tpr   = ((1 + drive) - tpr_br) / TAU_BR
        d_sp    = (MAP - sp) / TAU_RST
    else:
        d_tpr = d_sp = 0.0

    if raas.on:
        d_ang  = (1 + raas.g_ang * (MAP_REF - MAP) / MAP_REF - A_ang) / raas.tau_ang
        d_aldo = (1 + raas.g_aldo * (A_ang - 1) - A_aldo) / raas.tau_aldo
    else:
        d_ang = d_aldo = 0.0

    return [intake - Na_excr,
            H2O_IN - H2O_excr - H2O_INS - J_osm,
            J_osm,
            d_tpr, d_sp, d_ang, d_aldo]


def observe(y, raas):
    Na_ecf, V_ecf, V_icf, tpr_br, sp, A_ang, A_aldo = y
    C_Na = Na_ecf / V_ecf
    V_blood = F_PV * V_ecf / (1 - HCT)
    CO = max(0.0, CO0 + G_VR * (V_blood - BV0))
    ang_tpr = 1 + raas.k_tpr * (A_ang - 1) if raas.on else 1.0
    MAP = CO * TPR0 * tpr_br * ang_tpr
    return MAP, V_ecf, C_Na, A_ang, A_aldo


def settle(intake, raas=OFF, baroreflex=True, days=60.0):
    y0 = [M_BODY * F_ECF * C_NA_SET, M_BODY * F_ECF, M_BODY * F_ICF,
          1.0, MAP_REF, 1.0, 1.0]
    s = solve_ivp(rhs, (0.0, days), y0, args=(intake, raas, baroreflex),
                  method="LSODA", rtol=1e-9, atol=1e-11, dense_output=False)
    if not s.success:
        raise RuntimeError(s.message)
    return observe(s.y[:, -1], raas)


def salt_step(raas=OFF, baroreflex=True):
    return [settle(i, raas, baroreflex)
            for i in (P["BF.NA.INTAKE_NOMINAL"],
                      P["BF.NA.INTAKE_MID"],
                      P["BF.NA.INTAKE_LOW"])]


def shift(rows):
    return rows[0][0] - rows[2][0]


if __name__ == "__main__":
    print("=" * 72)
    print("STEP 0 -- does the reduction reproduce the known-good baseline?")
    print("=" * 72)
    base = salt_step(OFF, baroreflex=True)
    print("  intake   MAP (proto)    MAP (Julia, owner's machine)")
    for (m, *_), i, j in zip(base, (205, 154, 103),
                             (93.0000375, 90.5335685, 88.0658713)):
        print(f"  {i:>5}    {m:10.4f}     {j:12.7f}   delta {m-j:+.4f}")
    print(f"\n  salt-step shift: proto {shift(base):.4f} mmHg"
          f"   vs Julia 4.934166 mmHg")
    print("  If these disagree the reduction is not trustworthy and nothing")
    print("  below this line means anything.")

    print()
    print("=" * 72)
    print("Q2 -- Ang II on TPR: does it move long-run MAP, or only volume?")
    print("=" * 72)
    tpr_only = Raas(k_aldo=0.0, k_tpr=0.15)
    rows = salt_step(tpr_only)
    print("  intake    MAP        V_ecf      (aldosterone arm disabled)")
    for (m, v, *_), i in zip(rows, (205, 154, 103)):
        print(f"  {i:>5}   {m:9.5f}   {v:8.4f}")
    print(f"\n  MAP shift {shift(rows):.4f} vs baseline {shift(base):.4f}"
          f"   -> delta {shift(rows)-shift(base):+.2e}")
    print(f"  V_ecf at nominal: {rows[0][1]:.4f} vs baseline {base[0][1]:.4f}"
          f"   -> delta {rows[0][1]-base[0][1]:+.4f} L")

    print()
    print("=" * 72)
    print("Q1 -- aldosterone on distal reabsorption: does G_pn_eff move?")
    print("=" * 72)
    print("  k_aldo    shift(mmHg)   G_pn_eff   vs calibrated 20.67")
    for k in (0.0, 0.001, 0.002, 0.005, 0.010):
        r = salt_step(Raas(k_aldo=k, k_tpr=0.0))
        s = shift(r)
        print(f"  {k:6.4f}   {s:10.4f}    {102.0/s:8.2f}"
              f"   {'(baseline)' if k == 0 else f'{100*(102.0/s)/20.67-100:+6.1f}%'}")

    print()
    print("=" * 72)
    print("STABILITY -- both arms live, on the same tpr_mod path")
    print("=" * 72)
    full = Raas(k_aldo=0.005, k_tpr=0.15)
    for br in (True, False):
        r = salt_step(full, baroreflex=br)
        maps = [x[0] for x in r]
        mono = all(maps[i] > maps[i + 1] for i in range(len(maps) - 1))
        print(f"  baroreflex={str(br):<5} MAP {maps[0]:.4f} / {maps[1]:.4f}"
              f" / {maps[2]:.4f}   monotonic={mono}")
