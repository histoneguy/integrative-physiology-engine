#!/usr/bin/env python3
"""Two confirmations. Same smoke-detector caveat as proto_raas.py."""
import numpy as np
from scipy.integrate import solve_ivp
import proto_raas as M
from proto_raas import Raas, P

print("=" * 72)
print("A -- closed form for the aldosterone contribution to G_pn_eff")
print("=" * 72)
print("  Predicted:  G_pn_eff = G_pn + Na_filtered * k_aldo * g_aldo * g_ang / MAP_ref")
print()
Na_filt = M.GFR0 * M.C_NA_SET
print(f"  Na_filtered = {Na_filt:.0f} mEq/day,  MAP_ref = {M.MAP_REF}")
print()
print("  k_aldo    predicted   measured    error")
for k in (0.001, 0.002, 0.005, 0.010):
    r = Raas(k_aldo=k, k_tpr=0.0)
    pred = 20.67 + Na_filt * k * r.g_aldo * r.g_ang / M.MAP_REF
    rows = M.salt_step(r)
    meas = 102.0 / M.shift(rows)
    print(f"  {k:6.4f}   {pred:9.2f}   {meas:8.2f}   {pred-meas:+7.3f}")

print()
print("=" * 72)
print("B -- is the Ang II->TPR effect on MAP an artifact of absent ADH?")
print("=" * 72)
print("  Hypothesis: with C_Na free to drift, TPR leaks into steady-state MAP.")
print("  Pin C_Na at its setpoint (a stand-in for perfect osmoregulation) and")
print("  the effect should vanish, because the renal equation then fixes MAP")
print("  from intake alone.")
print()


def rhs_pinned(t, y, intake, raas):
    """As rhs(), but C_Na is held at setpoint: the ADH-present limit."""
    Na_ecf, V_ecf, V_icf, tpr_br, sp, A_ang, A_aldo = y
    C_Na = M.C_NA_SET                                   # <-- pinned
    V_blood = M.F_PV * V_ecf / (1 - M.HCT)
    CO = max(0.0, M.CO0 + M.G_VR * (V_blood - M.BV0))
    ang_tpr = 1 + raas.k_tpr * (A_ang - 1) if raas.on else 1.0
    MAP = CO * M.TPR0 * tpr_br * ang_tpr
    GFR = M.GFR0
    Na_filtered = GFR * C_Na
    aldo = raas.k_aldo * (A_aldo - 1) if raas.on else 0.0
    FR = np.clip(M.FR_NA + aldo - M.G_PN * (MAP - M.MAP_REF) / Na_filtered, 0, 1)
    Na_excr = Na_filtered * (1 - FR)
    err = MAP - sp
    drive = -M.SAT * np.tanh(M.G_BR * err / (M.SAT * M.MAP_REF))
    d_ang = ((1 + raas.g_ang * (M.MAP_REF - MAP) / M.MAP_REF - A_ang)
             / raas.tau_ang) if raas.on else 0.0
    d_aldo = ((1 + raas.g_aldo * (A_ang - 1) - A_aldo)
              / raas.tau_aldo) if raas.on else 0.0
    # Volume tracks sodium at fixed concentration.
    return [intake - Na_excr,
            (intake - Na_excr) / M.C_NA_SET,
            0.0,
            ((1 + drive) - tpr_br) / M.TAU_BR,
            (MAP - sp) / M.TAU_RST,
            d_ang, d_aldo]


def settle_pinned(intake, raas):
    y0 = [M.M_BODY * M.F_ECF * M.C_NA_SET, M.M_BODY * M.F_ECF,
          M.M_BODY * M.F_ICF, 1.0, M.MAP_REF, 1.0, 1.0]
    s = solve_ivp(rhs_pinned, (0, 400.0), y0, args=(intake, raas),
                  method="LSODA", rtol=1e-10, atol=1e-12)
    Na_ecf, V_ecf, V_icf, tpr_br, sp, A_ang, A_aldo = s.y[:, -1]
    V_blood = M.F_PV * V_ecf / (1 - M.HCT)
    CO = max(0.0, M.CO0 + M.G_VR * (V_blood - M.BV0))
    ang = 1 + raas.k_tpr * (A_ang - 1) if raas.on else 1.0
    return CO * M.TPR0 * tpr_br * ang


intakes = (P["BF.NA.INTAKE_NOMINAL"], P["BF.NA.INTAKE_MID"], P["BF.NA.INTAKE_LOW"])
off = [settle_pinned(i, M.OFF) for i in intakes]
on = [settle_pinned(i, Raas(k_aldo=0.0, k_tpr=0.15)) for i in intakes]
print("  C_Na PINNED (ADH-present limit)")
print("  intake   Ang-TPR off   Ang-TPR on     delta")
for i, a, b in zip((205, 154, 103), off, on):
    print(f"  {i:>5}   {a:11.6f}   {b:10.6f}   {b-a:+.2e}")
print(f"\n  shift off {off[0]-off[2]:.6f}   shift on {on[0]-on[2]:.6f}"
      f"   delta {(on[0]-on[2])-(off[0]-off[2]):+.2e}")
print()
print("  Analytic prediction with C_Na pinned:  MAP = MAP_ref + (I - 205)/G_pn")
for i in (205.0, 154.0, 103.0):
    print(f"    I={i:5.0f}  ->  {M.MAP_REF + (i - 205.0)/M.G_PN:.6f}")
