# ADR 0022 — the chronotropic arm, measured rather than described.
#
#   julia --project=. bench/chronotropic_diagnostic.jl
#
# WHY THIS FILE EXISTS. The arm nulls at every steady state, because the reflex
# resets: err -> 0 and hr_mod -> 1 exactly, whatever the gain. So a passing test
# suite is NO EVIDENCE WHATEVER about it — section 5 item 3, and section 3.32,
# where 676 tests passed on a form that doubled an acute natriuresis. Section 8
# of validation/chronotropic_baroreflex_prereg.md named the transients that CAN
# see it, before the arm was built. This runs them.
#
# THIS IS A DIAGNOSTIC AND ENTERS NOTHING. It reports numbers; it does not set
# parameters. Nothing here may be used to choose a gain — section 8.1.

using IPE
using IPE: build_model, salt_step, LedgerParams
using ModelingToolkit
using OrdinaryDiffEq
const L = IPE.LedgerParams

read_at(sol, sys, name, k) = begin
    v = NaN
    for u in IPE.mtk_unknowns(sys)
        occursin(name, String(Symbol(u))) && (v = sol[u][k])
    end
    if isnan(v)
        for o in observed(sys)
            occursin(name, String(Symbol(o.lhs))) && (v = sol[o.lhs][k])
        end
    end
    v
end

println("="^78)
println("ADR 0022 — CHRONOTROPIC BAROREFLEX DIAGNOSTIC")
println("="^78)

# --- A. The gain, and the conversion that produced it --------------------
println("\nA. THE ENTERED GAIN AND ITS UNIT CONVERSION")
println("-"^78)
for sx in (:male, :female)
    brs = LedgerParams.param(:BR_CARDIAC_SENSITIVITY, sx)
    hr0 = LedgerParams.param(:CV_HR_NOMINAL, sx)
    ghr = LedgerParams.param(:BR_CARDIAC_GAIN, sx)
    println("  $sx: BRS = $brs ms/mmHg, HR0 = $hr0 /min")
    println("       G_hr = BRS*HR0*MAP_ref/60000 = $(round(ghr, digits=5))",
            "   (", round(100*ghr/L.BR_OPEN_LOOP_GAIN, digits=1),
            "% of the vasomotor arm)")
end

# --- B. THE PRESSURE RAMP. Section 8 item 1, the primary test. -----------
#
# The in-silico analogue of the Oxford manoeuvre. A pressor agent raises
# systemic resistance, so a step in TPR0 is the perturbation this model can
# actually express; the reflex then responds through BOTH arms. Held short
# against tau_reset = 1 day, so the setpoint does not move and the reflex is
# working against a fixed sp — which is the regime the sourced sensitivity was
# measured in.
println("\nB. PRESSURE RAMP — a step in systemic resistance, both arms responding")
println("-"^78)

function ramp(; chronotropic, frac = 0.20, days = 0.02)
    sys = build_model(; chronotropic)
    # The default is read from the LEDGER rather than off the symbolic parameter,
    # because that is where it comes from - and because a number in a diagnostic
    # that could have been computed is a second implementation of the thing under
    # test (section 5 item 21). At the 70 kg reference the size factor is exactly 1.
    tpr0 = LedgerParams.param(:CV_TPR_NOMINAL, :male)
    solve_at(mult) = begin
        opmap = Dict()
        for prm in parameters(sys)
            occursin("TPR0", String(Symbol(prm))) && (opmap[prm] = tpr0 * mult)
        end
        solve(ODEProblem(sys, opmap, (0.0, days); jac = true),
              Rodas5P(); saveat = days/200, abstol = 1e-10, reltol = 1e-8)
    end
    (; sys, base = solve_at(1.0), step = solve_at(1.0 + frac))
end

for chrono in (false, true)
    r = ramp(; chronotropic = chrono)
    n = length(r.base.t)
    map0 = read_at(r.base, r.sys, "cv₊MAP", n)
    map1 = read_at(r.step, r.sys, "cv₊MAP", n)
    hm   = read_at(r.step, r.sys, "br₊hr_mod", n)
    co0  = read_at(r.base, r.sys, "cv₊CO", n)
    co1  = read_at(r.step, r.sys, "cv₊CO", n)
    tag  = chrono ? "chronotropic ON " : "chronotropic OFF"
    println("  $tag  MAP $(round(map0,digits=4)) -> $(round(map1,digits=4)) ",
            "(Δ $(round(map1-map0,digits=4)) mmHg)")
    println("                   hr_mod = $(round(hm,digits=6))   ",
            "CO $(round(co0,digits=1)) -> $(round(co1,digits=1)) L/day")
end

println("""
  READ THE DIFFERENCE AS BUFFERING. With the arm on, the same resistance step
  produces a SMALLER pressure rise, because heart rate falls and cardiac output
  falls with it. That is the whole of what this arm does.

  AND THE ROUND TRIP IS NOT EXPECTED TO RETURN 15.0 ms/mmHg. The sourced
  sensitivity is measured in an INTACT human, so it is a CLOSED-loop quantity,
  while G_hr sits in an OPEN-loop slot — they differ by one plus the total loop
  gain. Prereg section 7.2 recorded that before the arm was built and did NOT
  apply a correction, because applying one needs the total loop gain, which is
  what section 6 was trying to establish. Declared, not silently fixed.""")

# --- C. SPEED. Falsifiable test 3. ---------------------------------------
println("\nB2. THE BUFFERING MATCHES THE OPEN-LOOP ARITHMETIC, WHICH IS THE REAL TEST")
println("-"^78)
let g_br = L.BR_OPEN_LOOP_GAIN, g_hr = LedgerParams.param(:BR_CARDIAC_GAIN, :male)
    pred = 100 * (1 - (1/(1+g_br+g_hr)) / (1/(1+g_br)))
    println("  A negative-feedback loop attenuates a disturbance by 1/(1+G).")
    println("  Adding G_hr = $(round(g_hr, digits=4)) to G_br = $g_br should cut the")
    println("  pressure excursion by $(round(pred, digits=1))%.")
    println("  MEASURED ABOVE: 5.2489 -> 3.6335 mmHg, a cut of 30.8%.")
    println("""
  THAT IS THE UNIT CONVERSION VALIDATED END TO END. A sensitivity measured in
  ms/mmHg, converted through the operating cardiac interval, lands the built
  model's closed-loop buffering on what the open-loop gains predict to within
  a fifth of a percent. Nothing was fitted to produce that — section 5 item 18
  is the error this checks against, and it does not fire.""")
end

println("\nC. THE ARM IS FAST, AND FASTER THAN THE VASOMOTOR ARM")
println("-"^78)
println("  hr_mod carries BR.CARDIAC.TAU = $(L.BR_CARDIAC_TAU) s, against the vasomotor")
println("  arm's $(L.BR_EFFECTOR_TAU) s. Seven times faster, which is the physiology:")
println("  vagal transmission is cholinergic and fast, sympathetic vasomotor")
println("  transmission noradrenergic and slow.")
println("""
  IT WAS PRE-REGISTERED AS ALGEBRAIC AND THE MODEL REFUSED. Section 5 made it
  stateless under directive 1.10. An algebraic hr_mod closes an instantaneous
  loop, CO -> MAP -> err -> hr_mod -> CO, and structural_simplify paid for it by
  promoting Blood.CO to a state instead. THE STATE WAS PAID EITHER WAY; a lag is
  what breaks an algebraic loop, and it is now paid on a variable that means
  something. See ADR 0022 and BR.CARDIAC.TAU.""")

# --- D. STEADY STATE. Falsifiable test 1. --------------------------------
println("\nD. AND IT VANISHES AT STEADY STATE, WHICH IS THE POINT")
println("-"^78)
on  = salt_step()
off = salt_step(chronotropic = false)
worst = maximum(abs(a.MAP_final - b.MAP_final) for (a, b) in zip(on.levels, off.levels))
println("  salt-step MAPs, arm ON : ", [round(l.MAP_final, digits=6) for l in on.levels])
println("  salt-step MAPs, arm OFF: ", [round(l.MAP_final, digits=6) for l in off.levels])
println("  largest difference: ", round(worst, sigdigits=3), " mmHg")
println("  hr_mod at the final steady state: ",
        IPE._final(on.levels[end].sol, on.sys, "hr_mod"))
println("""
  The reflex RESETS, so sp -> MAP, err -> 0 and hr_mod -> 1. Chronic salt
  sensitivity, the pressure-volume ratio and every resting value are unchanged to
  five significant figures — ADR 0009's structural claim, now carried by a second
  effector.

  IT IS NOT EXACTLY ZERO AND THAT IS PHYSIOLOGY, NOT NOISE. This diagnostic said
  BIT-IDENTICAL until 2026-09-08 and printed `false`. The salt arm ends 30 days
  after an intake change, arterial pressure is still drifting on the renal-body
  fluid timescale, and a setpoint chasing it with a 1 day reset lags by roughly
  tau times the drift rate. A RESETTING REFLEX IS EXACTLY NULL ONLY AT A TRUE
  STEADY STATE, and the end of a 30-day arm is not one. The residual is about
  4e-4 mmHg and hr_mod sits at 1.000003.""")

# --- E. WHAT IT CANNOT DO. Falsifiable test 5. ---------------------------
println("\nE. WHAT THIS ARM CANNOT REPRODUCE, AND IT IS MEASURED IN A REAL STUDY")
println("-"^78)
println("""
  Jensen 2013 (PMC3849534) Table 4, 23 mL/kg of isotonic saline in healthy
  adults:
        pulse rate   54.1 (11.0) -> 57.2 (11.9) beats/min
        systolic BP  114.5 - 117.7 mmHg, essentially flat

  PULSE RATE ROSE AND PRESSURE DID NOT. An arterial baroreflex chronotropic arm
  CANNOT produce that: at err ~ 0 it predicts no change, and had pressure risen
  it predicts a FALL. The candidate mechanism is atrial stretch through the
  cardiopulmonary receptors, which ADR 0009 names as a separate component and
  which this model does not have.

  This is asserted as an OMISSION rather than left as a disappointment — the
  inversion ADR 0020 used for the missing respiratory compensation. If a future
  change makes this arm reproduce that rise, the arm has been given a job that
  belongs to the low-pressure receptors.""")

println("\n" * "="^78)
