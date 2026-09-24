#
# EXPORT THE MODEL'S BEHAVIOUR AND ITS PROVENANCE AS ONE JSON FILE.
#
# Run:  julia --project=. tools/export_gui_data.jl
# Writes gui/model_data.json, which gui/index.html reads.
#
# WHY A DUMP AND NOT A SERVER. The GUI has to run where the owner can open it,
# and nothing in this repository may depend on a Julia process being alive to
# make that happen. So the model is run here, over a declared grid, and the
# results are written out with the ledger that produced them. Every number the
# GUI shows came out of `build_model` in this file; none is recomputed in
# JavaScript, because a second implementation of the model is a second model.
#
# THE GRID IS DECLARED, NOT INFINITE. Four sweeps, listed below, each one axis
# at a time from the reference individual. A full factorial over six controls is
# combinatorial and would say nothing the one-at-a-time sweeps do not, since the
# couplings that matter are already asserted in the test suite.
#
# THREE BUILDS AND NO MORE. structural_simplify is the expensive step; body mass,
# sodium intake and thyroid secretory capacity are all parameters and go through
# `remake`. Sex and the thyroid metabolic arm are build-time and cannot.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf
using Dates

const OUT = joinpath(@__DIR__, "..", "gui", "model_data.json")

# ---------------------------------------------------------------- JSON, by hand
# No JSON dependency. CLAUDE.md: do not add tooling unless something breaks that
# cannot be worked around. Emitting an object and an array of numbers does not
# meet that bar.
jesc(s) = replace(string(s), "\\" => "\\\\", "\"" => "\\\"",
                  "\n" => "\\n", "\r" => "", "\t" => "\\t")
jstr(s) = "\"" * jesc(s) * "\""
function jnum(x)
    (x === nothing || (x isa Real && !isfinite(x))) && return "null"
    s = @sprintf("%.6g", float(x))
    return s
end
jarr(v, f) = "[" * join([f(x) for x in v], ",") * "]"
jobj(ps) = "{" * join(["$(jstr(k)):$(v)" for (k, v) in ps], ",") * "}"

# ------------------------------------------------------------------- the models
println("building...")
const SYS_M = IPE.build_model(sex = :male)
const SYS_F = IPE.build_model(sex = :female)
const SYS_T = IPE.build_model(sex = :male, thyroid_metabolic = true)

pget(sys, n) = (for p in parameters(sys)
                    occursin(n, String(Symbol(p))) && return p
                end; error("no parameter matching $n"))

"Final value of any unknown or observed variable whose name contains `n`."
function final(sys, sol, n)
    for u in unknowns(sys)
        String(Symbol(u)) == n * "(t)" && return sol[u][end]
    end
    for o in observed(sys)
        String(Symbol(o.lhs)) == n * "(t)" && return sol[o.lhs][end]
    end
    return NaN
end

"Steady state under a parameter override map, keyed by substring."
function steady(sys; overrides = Dict{String,Float64}(), days = 400.0)
    pm = Pair[pget(sys, k) => v for (k, v) in overrides]
    prob = ODEProblem(sys, pm, (0.0, days), Pair[])
    solve(prob, Rodas5P(); abstol = 1e-10, reltol = 1e-10, saveat = days)
end

# THE REPORTED QUANTITIES: subsystem, model name, label, UNITS. Ordered by
# subsystem so the GUI can group them without knowing any physiology. Names are
# the model's own, so a typo here is a NaN in the output rather than a plausible
# wrong number. UNITS ARE TRANSCRIBED FROM THE COMPONENT DECLARATIONS, where each
# variable carries its unit in a trailing comment - they are not inferred here.
const REPORT = [
    ("cardiovascular", "cv₊MAP",      "Mean arterial pressure", "mmHg"),
    ("cardiovascular", "cv₊CO",       "Cardiac output", "L/day"),
    ("cardiovascular", "cv₊SV",       "Stroke volume", "mL"),
    ("cardiovascular", "cv₊TPR",      "Total peripheral resistance", "mmHg/(L/day)"),
    ("cardiovascular", "cv₊V_blood",  "Blood volume", "L"),
    ("cardiovascular", "cv₊V_plasma", "Plasma volume", "L"),
    ("cardiovascular", "cv₊V_central","Central blood volume", "L"),
    ("body fluids",    "bf₊V_ecf",    "Extracellular fluid volume", "L"),
    ("body fluids",    "bf₊V_icf",    "Intracellular fluid volume", "L"),
    ("body fluids",    "bf₊V_total",  "Total body water", "L"),
    ("body fluids",    "bf₊C_Na",     "Plasma sodium concentration", "mEq/L"),
    ("body fluids",    "bf₊Osm_ecf",  "Plasma osmolality", "mOsm/kg"),
    ("body fluids",    "bf₊Na_total", "Total exchangeable sodium", "mEq"),
    ("renal",          "rn₊GFR",      "Glomerular filtration rate", "L/day"),
    ("renal",          "rn₊Na_excr",  "Sodium excretion", "mEq/day"),
    ("renal",          "rn₊Na_filtered", "Filtered sodium load", "mEq/day"),
    ("renal",          "rn₊FR_effective", "Fractional sodium reabsorption", "fraction"),
    ("renal",          "rn₊u_osm",    "Urine osmolality", "mOsm/kg"),
    ("renal",          "rn₊Osm_load", "Urinary solute load", "mOsm/day"),
    ("raas",           "ra₊pra",      "Plasma renin activity", "normalised"),
    ("raas",           "ra₊aldo",     "Aldosterone activity", "normalised"),
    ("adh",            "ad₊adh",      "Antidiuretic activity", "normalised 0-1"),
    ("baroreflex",     "br₊tpr_mod",  "Baroreflex resistance modifier", "multiplier"),
    # ADR 0022. BOTH EFFECTORS ARE SHOWN, and both read 1.0 at rest because the
    # reflex resets - which is the point rather than a dull display. A reader who
    # sees either move at a STEADY state has found a defect in the reset path.
    ("baroreflex",     "br₊hr_mod",   "Baroreflex heart rate modifier", "multiplier"),
    ("cardiovascular", "cv₊HR",       "Heart rate", "1/min"),
    ("respiratory",    "rs₊V_E",      "Minute ventilation", "L/min"),
    ("respiratory",    "rs₊V_A",      "Alveolar ventilation", "L/min"),
    ("respiratory",    "rs₊PaCO2",    "Arterial carbon dioxide tension", "mmHg"),
    ("respiratory",    "rs₊H2O_resp", "Respiratory water loss", "L/day"),
    ("blood",          "bl₊PAO2",     "Alveolar oxygen tension", "mmHg"),
    ("blood",          "bl₊PaO2",     "Arterial oxygen tension", "mmHg"),
    ("blood",          "bl₊SaO2",     "Arterial oxygen saturation", "fraction"),
    ("blood",          "bl₊CaO2",     "Arterial oxygen content", "mL/dL"),
    ("blood",          "bl₊DO2",      "Oxygen delivery", "mL/min"),
    ("blood",          "bl₊VO2",      "Oxygen consumption", "mL/min"),
    ("blood",          "bl₊avDO2",    "Arteriovenous oxygen difference", "mL/dL"),
    ("blood",          "bl₊CvO2",     "Mixed venous oxygen content", "mL/dL"),
    ("blood",          "bl₊SvO2",     "Mixed venous oxygen saturation", "fraction"),
    ("blood",          "bl₊ER",       "Oxygen extraction ratio", "fraction"),
    ("blood",          "bl₊pH",       "Arterial pH", "-"),
    ("thyroid",        "ty₊FT4",      "Free thyroxine", "pmol/L"),
    ("thyroid",        "ty₊TSH",      "Thyrotropin", "mIU/L"),
    ("thyroid",        "ty₊th_mod",   "Thyroid metabolic multiplier", "multiplier"),
    ("potassium",      "kp₊K_p",      "Plasma potassium", "mmol/L"),
    ("potassium",      "kp₊K_excr",   "Renal potassium excretion", "mmol/day"),
    ("renal",          "rn₊Na_distal","Distal sodium delivery", "mEq/day"),
    # ADDED 2026-09-22. The glucose, insulin and thirst quantities existed in the
    # model and were shown by NOTHING - the same defect Na_prox_out and Na_distal
    # each had, in the reporting layer rather than the equations. Directive 1.11.
    # ADR 0023's two headline quantities, and the haemorrhage time course exists
    # to show them apart: haematocrit falls within a day, red cell mass takes
    # months. Neither was exported until 2026-09-22.
    ("cardiovascular", "cv₊Hct_eff",  "Haematocrit", "fraction"),
    ("cardiovascular", "cv₊V_rbc",    "Red cell volume", "L"),
    ("glucose",        "rn₊C_glu",    "Plasma glucose", "mmol/L"),
    ("glucose",        "rn₊I_glu",    "Plasma insulin", "pmol/L"),
    ("glucose",        "rn₊glu_excr", "Urinary glucose", "mmol/day"),
    ("body-fluids",    "bf₊thirst",   "Osmotic thirst (drinking above protocol)", "L/day"),
]

snapshot(sys, sol) = [final(sys, sol, n) for (_, n, _, _) in REPORT]

# ------------------------------------------------- differential vs algebraic
# IPE.differential_unknown_names exists because three harnesses once carried
# algebraic unknowns as initial conditions and silently stopped integrating
# (ADR 0026). Reused here so the page cannot mislabel them either.
const DIFF_STATES = [u for u in unknowns(SYS_M)
                     if string(u) in IPE.differential_unknown_names(SYS_M)]

# ------------------------------------------------------------- TIME COURSES
# CHANGE OVER TIME, which the sweeps tab cannot show: it plots equilibria
# against a control, not trajectories. Three protocols were chosen because each
# exposes a DIFFERENT timescale, not because each looks good.
#
# Every series is subsampled to at most NT points. That is a plotting decision
# and not an integration one - the solver chooses its own steps and is not
# constrained by it.
const NT = 240

"Sample a solution at `n` evenly spaced times and return (t, rows)."
function course(sys, sol, t0, t1; n = NT)
    ts = collect(range(t0, t1; length = n))
    rows = Vector{Vector{Float64}}()
    for t in ts
        push!(rows, [ (function ()
                          for u in unknowns(sys)
                              String(Symbol(u)) == nm * "(t)" && return sol(t, idxs = u)
                          end
                          for o in observed(sys)
                              String(Symbol(o.lhs)) == nm * "(t)" && return sol(t, idxs = o.lhs)
                          end
                          return NaN
                       end)() for (_, nm, _, _) in REPORT ])
    end
    (ts, rows)
end

println("time courses...")

# (1) THE SALT STEP - the model's headline protocol, 30 days per arm.
#     Slow: pressure and volume take weeks, which is the point of ADR 0016.
const TC_SALT = let
    sys = SYS_M
    na = pget(sys, "Na_intake")
    U = IPE.mtk_unknowns(sys); DN = IPE.differential_unknown_names(sys)
    ts = Float64[]; rows = Vector{Vector{Float64}}(); carry = nothing; t0 = 0.0
    for lvl in (205.0, 154.0, 103.0)
        o = Dict{Any,Any}(na => lvl)
        carry === nothing || merge!(o, carry)
        sol = solve(ODEProblem(sys, o, (t0, t0 + 30.0)), Rodas5P();
                    abstol = 1e-10, reltol = 1e-10)
        SciMLBase.successful_retcode(sol) || error("salt course: $(sol.retcode) at $lvl")
        (tt, rr) = course(sys, sol, t0, t0 + 30.0; n = 80)
        append!(ts, tt); append!(rows, rr)
        carry = Dict{Any,Any}(u => sol[u][end] for u in U if string(u) in DN)
        t0 += 30.0
    end
    (ts, rows)
end

# (2) ONE-LITRE HAEMORRHAGE - ADR 0023. TWO timescales in one trace:
#     haematocrit falls within a day as plasma refills, red cell mass takes
#     months. A single chart cannot show both; the quantity selector can.
const TC_BLEED = let
    sys = SYS_M
    base = steady(sys; days = 400.0)
    U = IPE.mtk_unknowns(sys); DN = IPE.differential_unknown_names(sys)
    hct   = final(sys, base, "cv₊Hct_eff")
    fpv   = LedgerParams.param(:CV_PLASMA_ECF_FRACTION, :male)
    dV    = -1.0 * (1 - hct) / fpv          # the plasma share, through f_pv
    vecf0 = final(sys, base, "bf₊V_ecf")
    naecf0 = final(sys, base, "bf₊Na_ecf")
    u0 = Dict{Any,Any}()
    for u in U
        string(u) in DN || continue
        n = string(u)
        v = base[u][end]
        n == "bf₊V_ecf(t)"  && (v += dV)
        n == "bf₊Na_ecf(t)" && (v += (naecf0 / vecf0) * dV)   # isotonic loss
        n == "cv₊V_rbc(t)"  && (v -= 1.0 * hct)
        u0[u] = v
    end
    sol = solve(ODEProblem(sys, u0, (0.0, 150.0)), Rodas5P(); abstol = 1e-9, reltol = 1e-7)
    SciMLBase.successful_retcode(sol) || error("bleed course: $(sol.retcode)")
    course(sys, sol, 0.0, 150.0)
end

# (3) THE TWO GLUCOSE LESIONS - ADR 0031. Insulin resistance alone is
#     COMPENSATED; it takes a beta-cell deficit as well to move glucose. The
#     trace shows the compensation arriving, which a steady state cannot.
const TC_GLUC = let
    sys = SYS_M
    base = steady(sys; days = 400.0)
    U = IPE.mtk_unknowns(sys); DN = IPE.differential_unknown_names(sys)
    carry = Dict{Any,Any}(u => base[u][end] for u in U if string(u) in DN)
    o = merge(Dict{Any,Any}(pget(sys, "glu_disposal") => 0.2,
                            pget(sys, "beta_cell") => 0.05), carry)
    sol = solve(ODEProblem(sys, o, (0.0, 60.0)), Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    SciMLBase.successful_retcode(sol) || error("glucose course: $(sol.retcode)")
    course(sys, sol, 0.0, 60.0)
end

# ---------------------------------------------------------------- the baselines
println("baseline...")
base_m = steady(SYS_M)
base_f = steady(SYS_F)

# -------------------------------------------------------------------- the sweeps
# Each sweep moves ONE control away from the reference individual.
println("sweeps...")

const NA_LEVELS = [50.0, 100.0, 150.0, 205.0, 250.0, 300.0, 350.0, 400.0]
const BM_LEVELS = [45.0, 55.0, 65.0, 70.0, 80.0, 95.0, 110.0]
const H2O_LEVELS = [1.2, 1.6, 2.0, 2.5, 3.0, 3.5, 4.0]
const THY_LEVELS = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0]

function sweep(sys, key, levels)
    [snapshot(sys, steady(sys; overrides = Dict(key => v))) for v in levels]
end

salt_m = sweep(SYS_M, "bf₊Na_intake", NA_LEVELS)
salt_f = sweep(SYS_F, "bf₊Na_intake", NA_LEVELS)
h2o_m  = sweep(SYS_M, "bf₊H2O_intake", H2O_LEVELS)
thy_m  = sweep(SYS_T, "ty₊S_thy", THY_LEVELS)

# BODY MASS IS NOT ONE PARAMETER. Six of them scale with it, and `member_remake`
# is the single place that knows which - reusing it here rather than repeating
# the list is the whole point of HANDOVER section 3.24's finding.
function mass_sweep(sys)
    prob = ODEProblem(sys, [], (0.0, 400.0), []; sparse = true)
    out = Vector{Vector{Float64}}()
    for bm in BM_LEVELS
        sx = sys === SYS_F ? :female : :male
        p2 = IPE.member_remake(prob, sys, (body_mass = bm,); sex = sx)
        s = solve(p2, Rodas5P(); abstol = 1e-10, reltol = 1e-10, saveat = 400.0)
        push!(out, snapshot(sys, s))
    end
    out
end
mass_m = mass_sweep(SYS_M)
mass_f = mass_sweep(SYS_F)

# --------------------------------------------------------------- the provenance
# EVERY CITATION, SHIPPED WITH THE NUMBERS. The ledger is read here rather than
# duplicated, so the GUI cannot drift from it.
println("ledger...")
function read_csv(path)
    lines = readlines(path)
    rows = Vector{Vector{String}}()
    cur = String[]; field = IOBuffer(); inq = false
    for (li, line) in enumerate(lines)
        i = 1
        while i <= lastindex(line)
            c = line[i]
            if inq
                if c == '"'
                    if i < lastindex(line) && line[nextind(line, i)] == '"'
                        write(field, '"'); i = nextind(line, i)
                    else
                        inq = false
                    end
                else
                    write(field, c)
                end
            else
                if c == '"'
                    inq = true
                elseif c == ','
                    push!(cur, String(take!(field)))
                else
                    write(field, c)
                end
            end
            i = nextind(line, i)
        end
        if inq
            write(field, '\n')       # quoted newline: the row continues
        else
            push!(cur, String(take!(field)))
            push!(rows, cur); cur = String[]
        end
    end
    hdr = rows[1]
    [Dict(hdr[i] => (i <= length(r) ? r[i] : "") for i in eachindex(hdr))
     for r in rows[2:end] if !isempty(r) && !isempty(strip(r[1]))]
end

led = read_csv(joinpath(@__DIR__, "..", "ledger", "parameters.csv"))
rel = read_csv(joinpath(@__DIR__, "..", "ledger", "relations.csv"))

LED_KEYS = ["param_id", "name", "symbol", "units", "value", "uncertainty_type",
            "uncertainty_value", "subsystem", "source_tier", "citation", "doi",
            "extraction_method", "species", "sex", "notes"]
REL_KEYS = ["relation_id", "component", "expression", "class",
            "phenomenon_citation", "form_citation", "form_doi", "form_status",
            "notes"]

jrow(r, keys) = jobj([k => jstr(get(r, k, "")) for k in keys])

# --------------------------------------------------------------------- emit it
mkpath(dirname(OUT))
open(OUT, "w") do io
    quantities = "[" * join([jobj(["group" => jstr(g), "key" => jstr(k),
                                   "label" => jstr(l), "units" => jstr(u)])
                             for (g, k, l, u) in REPORT], ",") * "]"
    sweeps = jobj([
        "salt" => jobj(["axis" => jstr("Sodium intake (mmol/day)"),
                        "levels" => jarr(NA_LEVELS, jnum),
                        "male" => jarr(salt_m, v -> jarr(v, jnum)),
                        "female" => jarr(salt_f, v -> jarr(v, jnum))]),
        "mass" => jobj(["axis" => jstr("Body mass (kg)"),
                        "levels" => jarr(BM_LEVELS, jnum),
                        "male" => jarr(mass_m, v -> jarr(v, jnum)),
                        "female" => jarr(mass_f, v -> jarr(v, jnum))]),
        "water" => jobj(["axis" => jstr("Water intake (L/day)"),
                         "levels" => jarr(H2O_LEVELS, jnum),
                         "male" => jarr(h2o_m, v -> jarr(v, jnum))]),
        "thyroid" => jobj(["axis" => jstr("Thyroid secretory capacity (x normal)"),
                           "levels" => jarr(THY_LEVELS, jnum),
                           "male" => jarr(thy_m, v -> jarr(v, jnum))]),
    ])
    write(io, jobj([
        "generated" => jstr(string(Dates.now())),
        # SPLIT 2026-09-22. `unknowns` counts DIFFERENTIAL states AND ALGEBRAIC
        # unknowns together, and the page was calling the total "integrated
        # states". Two of them are not integrated: rn.ln_tal (the thick ascending
        # limb transport unknown, ADR 0026) and rn.C_glu (plasma glucose, implicit
        # since insulin saturates, ADR 0031). Reported apart.
        "n_states" => jnum(length(DIFF_STATES)),
        "n_algebraic" => jnum(length(unknowns(SYS_M)) - length(DIFF_STATES)),
        "quantities" => quantities,
        "baseline" => jobj(["male" => jarr(snapshot(SYS_M, base_m), jnum),
                            "female" => jarr(snapshot(SYS_F, base_f), jnum)]),
        "sweeps" => sweeps,
        "courses" => jobj([
            "salt" => jobj(["label" => jstr("Sodium intake stepped 205 → 154 → 103 mEq/day, 30 days each"),
                            "xlabel" => jstr("Day"),
                            "t" => jarr(TC_SALT[1], jnum),
                            "rows" => jarr(TC_SALT[2], v -> jarr(v, jnum))]),
            "bleed" => jobj(["label" => jstr("One-litre haemorrhage at day 0"),
                             "xlabel" => jstr("Day"),
                             "t" => jarr(TC_BLEED[1], jnum),
                             "rows" => jarr(TC_BLEED[2], v -> jarr(v, jnum))]),
            "glucose" => jobj(["label" => jstr("Insulin sensitivity to 0.2 and beta-cell capacity to 0.05 at day 0"),
                               "xlabel" => jstr("Day"),
                               "t" => jarr(TC_GLUC[1], jnum),
                               "rows" => jarr(TC_GLUC[2], v -> jarr(v, jnum))]),
        ]),
        "parameters" => "[" * join([jrow(r, LED_KEYS) for r in led], ",") * "]",
        "relations" => "[" * join([jrow(r, REL_KEYS) for r in rel], ",") * "]",
    ]))
end
@printf("wrote %s (%.0f kB)\n", OUT, filesize(OUT) / 1024)
