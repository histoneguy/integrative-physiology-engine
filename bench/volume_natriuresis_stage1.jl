#
# STAGE 1 of validation/volume_natriuresis_form_prereg.md. BUILDS NOTHING.
#
# Run:  julia --project=. bench/volume_natriuresis_stage1.jl
#
# PRE-REGISTERED, COMMITTED BEFORE THIS FILE EXISTED:
#     git log --diff-filter=A -- validation/volume_natriuresis_form_prereg.md
#     git log --diff-filter=A -- bench/volume_natriuresis_stage1.jl
#
# Directive 1.11. Section 2 of the pre-registration forbids writing a new term until
# the rows the model ALREADY HAS have been swept and reported - INCLUDING the ones
# that change nothing, because a sweep reported only for the row that mattered is not
# a sweep (section 7 item 1).
#
# THE TARGET. Drummer C et al., Am J Physiol 1992;262(5 Pt 2):F744-54, PMID 1590419:
# after 2 L of isotonic saline in 25 min, elevated body weight returned to baseline
# with an approximate half-life of about 7 h. The model gives 13.10 h (HANDOVER 3.46).
#
# THE CONSTRAINT THAT MUST HOLD AT THE SAME TIME: chronic salt sensitivity inside the
# human 1.70-2.30 mmHg per 100 mmol/day. Section 3.46 showed every natriuretic-gain
# route reaches 7 h only by breaking it.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf

const TARGET_H = 7.0
const SALT_LO, SALT_HI = 1.70, 2.30

sys = IPE.build_model()
U = unknowns(sys)
O = observed(sys)

pget(n) = (for p in parameters(sys); occursin(n, String(Symbol(p))) && return p; end;
           error("no parameter matching " * n))
val(s, n, i) = begin
    for u in U; occursin(n, String(Symbol(u))) && return s[u][i]; end
    for o in O; occursin(n, String(Symbol(o.lhs))) && return s[o.lhs][i]; end
    NaN
end

"Acute volume half-life and chronic salt sensitivity under one parameter override."
function probe(overrides::Dict{String,Float64})
    base = Dict{Any,Any}()
    for (k, v) in overrides; base[pget(k)] = v; end

    s0 = solve(ODEProblem(sys, collect(base), (0.0, 60.0), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10)
    n0 = length(s0.t); u0 = [u => s0[u][end] for u in U]
    Vecf0 = val(s0, "V_ecf", n0)

    dur = (25/60)/24                      # Drummer: 2 L in 25 min
    pm = copy(base)
    pm[pget("H2O_intake")] = 2.5 + 2.0/dur
    pm[pget("Na_intake")]  = 205.0 + 154.0*2.0/dur
    s1 = solve(ODEProblem(sys, vcat(u0, collect(pm)), (0.0, dur), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10, saveat = dur/60)
    u1 = [x => s1[x][end] for x in U]
    s2 = solve(ODEProblem(sys, vcat(u1, collect(base)), (dur, 5.0), Pair[]), Rodas5P();
               abstol = 1e-10, reltol = 1e-10, saveat = 1/24/60)
    ts = Float64[]; dv = Float64[]
    for s in (s1, s2), i in 1:length(s.t)
        push!(ts, s.t[i]); push!(dv, val(s, "V_ecf", i) - Vecf0)
    end
    ipk = argmax(dv)
    ih = findfirst(i -> i > ipk && dv[i] <= dv[ipk]/2, 1:length(dv))
    thalf = ih === nothing ? Inf : (ts[ih] - ts[ipk])*24

    u = copy(u0); t0 = 0.0; maps = Float64[]
    for lev in (205.0, 154.0, 103.0)
        pm2 = copy(base); pm2[pget("Na_intake")] = lev
        ss = solve(ODEProblem(sys, vcat(u, collect(pm2)), (t0, t0 + 30.0), Pair[]),
                   Rodas5P(); abstol = 1e-9, reltol = 1e-9)
        push!(maps, val(ss, "MAP", length(ss.t)))
        u = [x => ss[x][end] for x in U]; t0 += 30.0
    end
    (thalf = thalf, shift = (maximum(maps) - minimum(maps))/102*100, peak = dv[ipk])
end

function row(label, ov)
    r = probe(ov)
    reach = abs(r.thalf - TARGET_H) <= 2.0
    inband = SALT_LO <= r.shift <= SALT_HI
    @printf("  %-44s %8.2f %10.4f  %s\n", label, r.thalf, r.shift,
            reach && inband ? "<== BOTH" : reach ? "t1/2 only" :
            inband ? "" : "salt OUT")
    r
end

"Swap in a differently-built system for one block of rows."
function with_build(f, newsys)
    old_sys, old_U, old_O = sys, U, O
    global sys = newsys; global U = unknowns(newsys); global O = observed(newsys)
    try f() finally
        global sys = old_sys; global U = old_U; global O = old_O
    end
end

println("="^90)
println("STAGE 1 - SWEEPING WHAT THE MODEL ALREADY HAS. NOTHING IS BUILT HERE.")
println("validation/volume_natriuresis_form_prereg.md section 2")
println("="^90)
@printf("  target: acute volume half-life %.0f h (Drummer 1992, PMID 1590419)\n", TARGET_H)
@printf("          chronic salt sensitivity inside %.2f-%.2f mmHg per 100 mmol/day\n",
        SALT_LO, SALT_HI)
println()
@printf("  %-44s %8s %10s\n", "configuration", "t1/2 h", "salt sens")
println("  " * "-"^86)

row("AS MERGED", Dict{String,Float64}())

# THE STORAGE ROWS ARE BEHIND A FLAG, AND THAT IS WHY A NAIVE SWEEP IS INERT.
# build_model defaults to storage = false and ADR 0004 is PROVISIONAL, so
# D(Na_store) ~ 0, J_store ~ 0, and NEITHER ROW IS READ. Swept from 0.1 d to 30 d
# against the default build they are bit-identical - a property of the flag, not of
# the physiology. Both facts are reported, per section 7 item 1.
println("\n  BF.NA.STORAGE_TAU and BF.NA.OSMOTICALLY_INACTIVE_FRACTION")
println("  On the DEFAULT build (storage = false, ADR 0004 PROVISIONAL) these are")
println("  BIT-IDENTICAL from 0.1 d to 30 d - the branch is off and nothing reads them.")
println("  Re-swept on a build with the branch ON:")
with_build(IPE.build_model(storage = true)) do
    row("    storage ON, tau_store = 7 d (the ledger value)", Dict{String,Float64}())
    for v in (0.1, 0.5, 3.0, 30.0)
        row("    storage ON, tau_store = $v d", Dict("tau_store" => v))
    end
    for v in (0.05, 0.30, 0.50)
        row("    storage ON, f_store = $v", Dict("f_store" => v))
    end
end

println("\n  BF.ICF_ECF.OSMOTIC_TAU  (min, assumed at 30):")
for v in (1.0, 30.0, 120.0)
    row("    tau_osm = $v min", Dict("tau_osm" => v))
end

# THE STRUCTURAL SUSPECT - CV.PLASMA.ECF_FRACTION (section 2.1) - AND IT CANNOT BE
# SWEPT AS A CONSTANT. f_pv is DERIVED to close the loop at the nominal point,
# f_pv = BV0*(1 - Hct)/V_ecf0, so that V_plasma + Hct*BV0 = BV0 exactly at rest.
# Override it and the RESTING STATE moves, which is a different experiment from the
# one section 2.1 proposes.
println("\n  CV.PLASMA.ECF_FRACTION - SWEPT, AND THE SWEEP IS CONFOUNDED (section 2.1):")
for v in (0.2111, 0.30, 0.45, 0.60)
    row("    f_pv = $v  (DERIVED - override breaks closure)", Dict("f_pv" => v))
end
println("  ^^ READ THE SALT COLUMN, NOT THE HALF-LIFE. It sits at 1.9604 at the derived")
println("     value and jumps to about 2.126 at EVERY other value - that is the closure")
println("     breaking and the operating point moving, not a natriuretic response. And")
println("     f_pv = 0.60 puts resting plasma volume at 8.7 L in a 14.6 L extracellular")
println("     space, which is not a human. NO CONCLUSION IS DRAWN FROM THIS BLOCK.")
println("     What section 2.1 actually asks is whether the plasma share is HIGHER EARLY")
println("     and falls as the load equilibrates - a TIME-VARYING f_pv, which is a")
println("     structural change and belongs to stage 2.")

println("\n  THE WATER LIMB - does volume decay wait on water rather than on sodium?")
with_build(IPE.build_model(adh = false)) do
    row("    ADH disabled (placeholder water limb)", Dict{String,Float64}())
end

println("\n" * "="^90)
println("Read the 'salt OUT' column first: a row that reaches the half-life by leaving")
println("the human chronic window has solved nothing, which is exactly what section")
println("3.46 found for every natriuretic gain.")
println("="^90)
