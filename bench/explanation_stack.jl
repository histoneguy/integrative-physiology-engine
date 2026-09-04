#
# ADR 0013 versus ADR 0015 versus the GFR limb. Do they compose, and does anything land?
#
# Run:  julia --project=. bench/explanation_stack.jl
#
# HANDOVER section 4 item 5. Three records now claim the same discrepancy: the model is
# 4.958 mmHg per 100 mmol/day against a human 1.70-2.30, and each of ADR 0013 (a fitted
# constant), ADR 0015 (a non-escaping tubular term) and RN.GFR.VOLUME_SENSITIVITY (a
# sourced GFR response to volume) removes part of it. The anti-double-count rule says the
# total explained must not exceed the gap. Nobody has measured the total.
#
# WHY THIS IS RUN RATHER THAN COMPOSED. Multiplying three published percentages together
# is exactly the move that was made and withdrawn on 2026-09-02 (HANDOVER section 3.9),
# and section 5 item 13 says a composed number must be checked by varying each declared
# assumption. So every configuration below is a real solve of the real model.
#
# THE DECISION RULE IS FIXED HERE, BEFORE THE RUN, and the human window is the
# meta-analytic 1.70-2.30 already used by ADR 0013 and ADR 0015:
#
#   D1  mechanisms alone land INSIDE the window
#         -> ADR 0013 is unnecessary. Recommend it be Rejected rather than parked.
#   D2  mechanisms alone are ABOVE the window and mechanisms + G_pn = 51 land BELOW it
#         -> both limbs are needed and ADR 0013's VALUE is stale, because 51 was
#            estimated with no mechanism present. ADR 0013 stays Proposed with a
#            corrected target, which this script reports.
#   D3  mechanisms + G_pn = 51 land INSIDE the window
#         -> the two records are complementary as written and 51 survives.
#   D4  mechanisms alone land BELOW the window
#         -> the mechanisms over-explain the gap and at least one of them is wrong.
#
# STALE AS OF 2026-09-03, AND IT DOUBLE-COUNTS IF RE-RUN. THE GFR LIMB IS NOW
# IMPLEMENTED. RN.GFR.VOLUME_SENSITIVITY was wired into Renal.jl as gfr_vol_mod
# (HANDOVER section 4 item 1), so the model already carries the response this
# script stands in for with a GFR0 override. Running it now applies the GFR limb
# TWICE, once in the model and once in the proxy, and the g = 0 rows are no longer
# a baseline without it.
#
# THE NUMBERS BELOW ARE NOT REPRODUCIBLE AGAINST THE CURRENT MODEL FOR THREE
# FURTHER REASONS, and they are recorded so the table in ADR 0016 is read as the
# history it is: G_pn has moved 20 -> 8.4, CV.VENOUS_RETURN.SENSITIVITY 2880 ->
# 1400, and ADR 0010's volume-keyed natriuretic path is sourced and ON. The
# baseline this script was written against was 4.958 mmHg per 100 mmol/day; it is
# now 2.000 before this change. THE ORDERING IT ESTABLISHED SURVIVES - G_vr first,
# mechanisms second, the fitted constant last - and that ordering was followed.
# The ARITHMETIC does not. Kept as the record of a run, not as a live diagnostic.
#
# TWO PROXIES, AND BOTH ARE DECLARED BECAUSE NEITHER TERM WAS IMPLEMENTED WHEN
# THIS WAS WRITTEN.
#
#   ADR 0015 -> tau_esc = 1e6 d, the escape diagnostic from bench/escape_sweep.jl. It is
#     NOT the proposed change: it disables aldosterone escape rather than adding a
#     separate non-escaping AngII term, and ADR 0015 says so. It also MOVES THE BASELINE,
#     so baseline MAP is printed for every configuration and the confound stays visible.
#   GFR limb -> GFR0 overridden per arm by (1 + g*(level-154)/51), the diagnostic from
#     bench/gfr_salt_sweep.jl. Run at BOTH ends of the bracket in HANDOVER section 3.12:
#     g = 0.0376 from the per-litre route and g = 0.0200 from the per-intake route.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf

const HUMAN = (1.70, 2.30)
const S_GFR = 1.30        # RN.GFR.VOLUME_SENSITIVITY, sourced
const VOL_HALF = 0.02896  # model fractional ECF half-excursion per +/- 51 mEq/day

function salt_step_stack(; g_gfr = 0.0, gpn = nothing, tau_esc = nothing,
                         levels = (205.0, 154.0, 103.0), days = 30.0)
    sys = IPE.build_model()
    gfr0_base = Dict()
    for prm in parameters(sys)
        occursin("GFR0", String(Symbol(prm))) &&
            (gfr0_base[prm] = ModelingToolkit.getdefault(prm))
    end
    results = NamedTuple[]
    u_carry = nothing
    t0 = 0.0
    for level in levels
        opmap = Dict()
        for prm in parameters(sys)
            n = String(Symbol(prm))
            occursin("Na_intake", n) && (opmap[prm] = level)
            gpn !== nothing && occursin("G_pn", n) && (opmap[prm] = gpn)
            tau_esc !== nothing && occursin("tau_esc", n) && (opmap[prm] = tau_esc)
            haskey(gfr0_base, prm) &&
                (opmap[prm] = gfr0_base[prm] * (1 + g_gfr * (level - 154.0) / 51.0))
        end
        prob = ODEProblem(sys, u_carry === nothing ? Pair[] : u_carry,
                          (t0, t0 + days), collect(opmap))
        sol = solve(prob, Rodas5P(); abstol = 1e-8, reltol = 1e-8)
        u_carry = [u => sol[u][end] for u in unknowns(sys)]
        fin(name) = begin
            v = NaN
            for u in unknowns(sys)
                occursin(name, String(Symbol(u))) && (v = sol[u][end])
            end
            if isnan(v)
                for o in observed(sys)
                    occursin(name, String(Symbol(o.lhs))) && (v = sol[o.lhs][end])
                end
            end
            v
        end
        push!(results, (level = level, MAP = fin("MAP"), V_ecf = fin("V_ecf")))
        t0 += days
    end
    dm = maximum(x.MAP for x in results) - minimum(x.MAP for x in results)
    dv = maximum(x.V_ecf for x in results) - minimum(x.V_ecf for x in results)
    (per100 = dm / 102 * 100, shift = dm, dv100 = dv / 102 * 100,
     ratio = dm / dv, base_map = results[1].MAP)
end

# Tolerance because the bisection below lands ON the boundary by construction, and a
# strict comparison then reports the target it just hit as outside the window. Sized from
# the bisection tolerance: 1e-3 in G_pn is about 7e-5 in the shift, so 1e-3 clears it.
const EDGE = 1e-3
inwin(x) = (HUMAN[1] - EDGE) <= x <= (HUMAN[2] + EDGE)
mark(x) = inwin(x) ? "IN " : (x > HUMAN[2] ? "high" : "low ")

g_hi = VOL_HALF * S_GFR      # per-litre route,  HANDOVER 3.12
g_lo = 0.0200                # per-intake route, HANDOVER 3.12

CONFIGS = [
    ("baseline, nothing enabled",                (g_gfr=0.0,  gpn=nothing, tau_esc=nothing)),
    ("GFR limb only, per-litre  g=0.0376",       (g_gfr=g_hi, gpn=nothing, tau_esc=nothing)),
    ("GFR limb only, per-intake g=0.0200",       (g_gfr=g_lo, gpn=nothing, tau_esc=nothing)),
    ("ADR 0015 proxy only",                      (g_gfr=0.0,  gpn=nothing, tau_esc=1.0e6)),
    ("ADR 0013 only, G_pn=51",                   (g_gfr=0.0,  gpn=51.0,    tau_esc=nothing)),
    ("MECHANISMS: 0015 + GFR per-litre",         (g_gfr=g_hi, gpn=nothing, tau_esc=1.0e6)),
    ("MECHANISMS: 0015 + GFR per-intake",        (g_gfr=g_lo, gpn=nothing, tau_esc=1.0e6)),
    ("ALL THREE: 0015 + GFR per-litre + 51",     (g_gfr=g_hi, gpn=51.0,    tau_esc=1.0e6)),
    ("ALL THREE: 0015 + GFR per-intake + 51",    (g_gfr=g_lo, gpn=51.0,    tau_esc=1.0e6)),
]

@printf("human window %.2f - %.2f mmHg per 100 mmol/day\n\n", HUMAN[1], HUMAN[2])
println("configuration                               per100   dV100   ratio   baseMAP  where")
for (label, kw) in CONFIGS
    r = salt_step_stack(; kw...)
    @printf("%-42s %6.3f  %6.3f  %6.3f  %7.3f  %s\n",
            label, r.per100, r.dv100, r.ratio, r.base_map, mark(r.per100))
end

# What G_pn puts the mechanism stack inside the window?
#
# The obvious move is to assume G_pn scales the shift inversely and solve. THAT IS WRONG
# HERE and the error is printed below: with the mechanisms on, the inverse law
# under-predicts the required G_pn by 7-12%, because the pressure-independent limbs
# remove sodium that G_pn then does not have to clear. So the inverse solve is used only
# as a BRACKET and the answer is bisected on real solves. This is section 5 item 13 in
# practice - the composed number was checked and did not survive.
function bisect_gpn(g, target; lo = 15.0, hi = 90.0, tol = 1e-3, maxit = 24)
    f(x) = salt_step_stack(; g_gfr = g, gpn = x, tau_esc = 1.0e6).per100 - target
    flo, fhi = f(lo), f(hi)
    (flo * fhi > 0) && return (NaN, 0)
    it = 0
    while it < maxit && (hi - lo) > tol
        mid = 0.5 * (lo + hi)
        fm = f(mid)
        if flo * fm <= 0
            hi, fhi = mid, fm
        else
            lo, flo = mid, fm
        end
        it += 1
    end
    (0.5 * (lo + hi), it)
end

println()
println("THE CORRECTED G_pn TARGET, BISECTED ON REAL SOLVES")
for (label, g) in (("per-litre", g_hi), ("per-intake", g_lo))
    m = salt_step_stack(; g_gfr = g, gpn = nothing, tau_esc = 1.0e6)
    naive_lo = 20.0 * m.per100 / HUMAN[2]
    naive_hi = 20.0 * m.per100 / HUMAN[1]
    gl, il = bisect_gpn(g, HUMAN[2])
    gh, ih = bisect_gpn(g, HUMAN[1])
    @printf("  %-11s mechanisms give %.3f\n", label, m.per100)
    @printf("      inverse-law guess   %.1f - %.1f\n", naive_lo, naive_hi)
    @printf("      BISECTED            %.1f - %.1f   (%d and %d iterations)\n",
            gl, gh, il, ih)
    @printf("      the guess is low by %.1f%% and %.1f%%\n",
            (gl - naive_lo) / gl * 100, (gh - naive_hi) / gh * 100)
    for gpn in (gl, gh)
        r = salt_step_stack(; g_gfr = g, gpn = gpn, tau_esc = 1.0e6)
        @printf("      G_pn = %5.1f -> %.3f per 100 mmol/day, dV %.3f L  %s\n",
                gpn, r.per100, r.dv100, mark(r.per100))
    end
end

println()
println("Decision rule D1-D4 is in this file's header, fixed before the run.")
println("ADR 0013's own pressure bracket is 43.5-58.8 and its proposal is 51.0.")
