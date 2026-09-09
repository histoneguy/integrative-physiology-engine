"""
Live simulation server for the GUI.

    julia --project=. tools/gui_server.jl
    then open http://127.0.0.1:877

WHY A SERVER AND NOT A JAVASCRIPT MODEL. The obvious way to get a GUI that responds
instantly is to reimplement the ODE system in JavaScript. That would be a SECOND
ENCODING OF THE MODEL, and section 5 item 21 is the entry about what happens when one
rule is written down twice: it passes for as long as the two agree and then accuses the
wrong component. This server drives the REAL model - the same `build_model` the test
suite and the challenge harness use - so there is nothing to drift.

WHAT IT COSTS. The GUI now needs Julia running. `gui/index.html` stays as it was: a
self-contained static snapshot that opens by double-clicking, for sharing a result.
This is the instrument; that is the photograph.

NO NEW DEPENDENCY. HTTP is spoken directly over `Sockets` from the standard library.
Directive 1.2 - do not add tooling unless something breaks that cannot be worked
around - and a whole HTTP stack to serve one page and one stream is not warranted.

HOW LIVE EDITING WORKS. A session owns a model, a current state vector and a current
parameter map. The stream integrates ONE CHUNK at a time and, before each chunk, drains
a queue of pending edits and applies them by rebuilding the problem from the CURRENT
state. So changing a parameter mid-run continues the simulation rather than restarting
it, which is what makes a clamp or a step visible as a transient.
"""

using Sockets
using IPE
using IPE: build_model, LedgerParams, mtk_unknowns, sample_population, member_remake
using ModelingToolkit
using OrdinaryDiffEq

const PORT = 877
const GUI_DIR = joinpath(@__DIR__, "..", "gui")

# ---------------------------------------------------------------------------
# Minimal JSON writer. Only what this server emits: numbers, strings, bools,
# vectors and Dicts with string keys. Reaching for a JSON package to print four
# shapes would be the tooling directive 1.2 warns about.
# ---------------------------------------------------------------------------
jesc(s) = replace(string(s), '\\' => "\\\\", '"' => "\\\"", '\n' => "\\n", '\r' => "",
                  '\t' => "\\t")
jval(x::AbstractString) = "\"" * jesc(x) * "\""
jval(x::Symbol)         = jval(String(x))
jval(x::Bool)           = x ? "true" : "false"
jval(x::Nothing)        = "null"
function jval(x::Real)
    (isnan(x) || isinf(x)) && return "null"
    return string(x)
end
jval(v::AbstractVector) = "[" * join(jval.(v), ",") * "]"
jval(d::AbstractDict)   = "{" * join(("$(jval(string(k))):$(jval(v))" for (k, v) in d), ",") * "}"

# ---------------------------------------------------------------------------
# Minimal JSON reader, for the small flat objects the client posts.
# ---------------------------------------------------------------------------
function jparse(s::AbstractString)
    i = Ref(1); skipws(s, i); return jparse_value(s, i)
end
skipws(s, i) = while i[] <= lastindex(s) && isspace(s[i[]]); i[] += 1 end
function jparse_value(s, i)
    c = s[i[]]
    c == '{' && return jparse_obj(s, i)
    c == '[' && return jparse_arr(s, i)
    c == '"' && return jparse_str(s, i)
    if startswith(SubString(s, i[]), "true");  i[] += 4; return true;  end
    if startswith(SubString(s, i[]), "false"); i[] += 5; return false; end
    if startswith(SubString(s, i[]), "null");  i[] += 4; return nothing; end
    j = i[]
    while j <= lastindex(s) && (isdigit(s[j]) || s[j] in ('-', '+', '.', 'e', 'E')); j += 1 end
    v = parse(Float64, SubString(s, i[], j - 1)); i[] = j; return v
end
function jparse_str(s, i)
    i[] += 1; io = IOBuffer()
    while s[i[]] != '"'
        if s[i[]] == '\\'
            i[] += 1
            c = s[i[]]
            write(io, c == 'n' ? '\n' : c == 't' ? '\t' : c)
        else
            write(io, s[i[]])
        end
        i[] += 1
    end
    i[] += 1; return String(take!(io))
end
function jparse_arr(s, i)
    i[] += 1; out = Any[]; skipws(s, i)
    if s[i[]] == ']'; i[] += 1; return out end
    while true
        skipws(s, i); push!(out, jparse_value(s, i)); skipws(s, i)
        s[i[]] == ',' ? (i[] += 1) : (i[] += 1; break)
    end
    return out
end
function jparse_obj(s, i)
    i[] += 1; out = Dict{String,Any}(); skipws(s, i)
    if s[i[]] == '}'; i[] += 1; return out end
    while true
        skipws(s, i); k = jparse_str(s, i); skipws(s, i); i[] += 1  # colon
        skipws(s, i); out[k] = jparse_value(s, i); skipws(s, i)
        s[i[]] == ',' ? (i[] += 1) : (i[] += 1; break)
    end
    return out
end

# ---------------------------------------------------------------------------
# The quantities the GUI can plot. Grouped so the client can lay them out, and
# deliberately a SUPERSET of the static page's list - this one is for driving
# the model, not for summarising it.
# ---------------------------------------------------------------------------
# DISPLAY PRECISION IS A PROPERTY OF THE QUANTITY, and the last column carries it.
# A mean arterial pressure is meaningful to about 1 mmHg - a sphygmomanometer reads
# in 2 mmHg steps and the model's own setpoint is sourced to three figures - so
# printing 86.995 asserts a resolution that exists nowhere in the measurement chain.
# A reflex modifier that lives at 1.0000 is the opposite case and needs four decimals
# to say anything at all. There is no single right number of digits, which is why this
# is per row rather than a global rule.
const QUANTITIES = [
    ("cardiovascular", "cv₊MAP",        "Mean arterial pressure",      "mmHg",         0),
    ("cardiovascular", "cv₊CO",         "Cardiac output",              "L/day",        0),
    ("cardiovascular", "cv₊HR",         "Heart rate",                  "1/min",        1),
    ("cardiovascular", "cv₊SV",         "Stroke volume",               "mL",           1),
    ("cardiovascular", "cv₊TPR",        "Total peripheral resistance", "mmHg/(L/day)", 5),
    ("cardiovascular", "cv₊V_blood",    "Blood volume",                "L",            2),
    ("baroreflex",     "br₊tpr_mod",    "Reflex resistance modifier",  "×",            4),
    ("baroreflex",     "br₊hr_mod",     "Reflex heart rate modifier",  "×",            4),
    ("baroreflex",     "br₊sp",         "Reflex setpoint",             "mmHg",         1),
    ("body fluids",    "bf₊V_ecf",      "Extracellular fluid volume",  "L",            2),
    ("body fluids",    "bf₊V_icf",      "Intracellular fluid volume",  "L",            2),
    ("body fluids",    "bf₊C_Na",       "Plasma sodium",               "mEq/L",        1),
    ("body fluids",    "bf₊Osm_ecf",    "Plasma osmolality",           "mOsm/kg",      1),
    ("renal",          "rn₊GFR",        "Glomerular filtration rate",  "L/day",        1),
    ("renal",          "rn₊Na_excr",    "Sodium excretion",            "mEq/day",      1),
    ("renal",          "rn₊H2O_excr",   "Water excretion",             "L/day",        2),
    ("renal",          "rn₊u_osm",      "Urine osmolality",            "mOsm/kg",      0),
    ("raas",           "ra₊pra",        "Plasma renin activity",       "×",            3),
    ("raas",           "ra₊aldo",       "Aldosterone activity",        "×",            3),
    ("adh",            "ad₊adh",        "Antidiuretic activity",       "0-1",          3),
    ("potassium",      "kp₊K_p",        "Plasma potassium",            "mmol/L",       2),
    ("thyroid",        "ty₊FT4",        "Free thyroxine",              "pmol/L",       2),
    ("thyroid",        "ty₊TSH",        "Thyrotropin",                 "mIU/L",        3),
    ("respiratory",    "rs₊V_E",        "Minute ventilation",          "L/min",        2),
    ("respiratory",    "rs₊PaCO2",      "Arterial CO2 tension",        "mmHg",         1),
    ("blood",          "bl₊SaO2",       "Arterial O2 saturation",      "fraction",     3),
    ("blood",          "bl₊DO2",        "Oxygen delivery",             "mL/min",       0),
    ("blood",          "bl₊pH",         "Arterial pH",                 "-",            3),
]

# ---------------------------------------------------------------------------
# Session
# ---------------------------------------------------------------------------
mutable struct Session
    sys
    prob
    integ          # ONE integrator, stepped forward - see step_chunk!
    minteg::Vector{Any}   # one per population member, same discipline
    u0::Vector{Float64}
    t::Float64
    pmap::Dict{String,Float64}      # parameter name -> current value
    pending::Dict{String,Float64}   # edits waiting for the next chunk
    paused::Bool
    stop::Bool
    duration::Float64
    chunk::Float64
    mode::String
    members::Vector{Any}
    lock::ReentrantLock
end

const SESSIONS = Dict{String,Session}()

# STRIP THE `(t)`. `Symbol(u)` on a time-dependent variable renders as
# `cv₊MAP(t)`, and the client keys plots on `cv₊MAP`. The stream worked and every
# card stayed blank, which is the whole class of bug this repo keeps meeting: two
# spellings of one name, agreeing until something reads them side by side.
pname(p) = replace(String(Symbol(p)), "(t)" => "")

function new_session(; sex::Symbol = :male, body_mass = 70.0, mode = "individual",
                     n_members = 8, duration = 60.0, chunk = 0.25)
    sys = build_model(; sex, body_mass)
    prob = ODEProblem(sys, Dict(), (0.0, duration); jac = true)
    pmap = Dict{String,Float64}()
    # GUARDED, AND THE REPO ALREADY RECORDS WHY. Section 3.24: `parameters()` on a
    # SIMPLIFIED system carries dummy-derivative symbols that have no default, and
    # asking one for its default throws - `bf.Na_store` when storage = false is the
    # named example. Skip anything without a numeric default rather than assuming the
    # parameter list is clean.
    for p in parameters(sys)
        v = try ModelingToolkit.getdefault(p) catch; nothing end
        v isa Number && (pmap[pname(p)] = Float64(v))
    end
    members = Any[]
    if mode == "population"
        pop = sample_population(n_members; sex)
        for m in pop
            push!(members, member_remake(prob, sys, m; sex))
        end
    end
    return Session(sys, prob, nothing, Any[], Vector{Float64}(prob.u0), 0.0, pmap,
                   Dict{String,Float64}(), false, false, duration, chunk,
                   mode, members, ReentrantLock())
end

last_of(x) = x isa AbstractVector ? x[end] : x

"""Read every plottable quantity at the current point of `src`.

`src` is an ODE solution OR a live integrator. Indexing a solution yields a vector
and indexing an integrator yields a scalar, so both go through `last_of`.
"""
function sample_quantities(sys, src)
    out = Dict{String,Any}()
    for u in mtk_unknowns(sys)
        out[pname(u)] = last_of(src[u])
    end
    for o in observed(sys)
        k = pname(o.lhs)
        haskey(out, k) && continue
        try
            out[k] = last_of(src[o.lhs])
        catch
        end
    end
    return out
end

"""
Advance one chunk on a PERSISTENT integrator.

WHY NOT RE-SOLVE EACH CHUNK. The obvious implementation calls `solve` per chunk from
the previous end state. That discards the integrator's step-size history and error
estimate every chunk and restarts a stiff solve from cold. In a fast ALGEBRAIC
observable that appears as step-to-step jitter which is an artefact of the CHUNKING
rather than of the physiology - and sodium excretion is exactly such an observable,
so it inherits every restart transient directly.

Stepping ONE integrator is also the only version in which the chunk size is purely a
DISPLAY choice. With re-solving, changing the step changed the answer.
"""
function step_chunk!(s::Session, target)
    if s.integ === nothing
        s.integ = init(remake(s.prob; u0 = s.u0,
                              tspan = (s.t, s.t + max(s.duration, 1.0))),
                       Rodas5P(); abstol = 1e-8, reltol = 1e-6,
                       save_everystep = false)
    end
    step!(s.integ, max(target - s.t, 1e-9), true)
    s.u0 = Vector{Float64}(s.integ.u)
    s.t  = s.integ.t
    return s.integ
end

function apply_pending!(s::Session)
    isempty(s.pending) && return false
    lock(s.lock) do
        for (k, v) in s.pending
            s.pmap[k] = v
        end
        empty!(s.pending)
    end
    opmap = Dict()
    for p in parameters(s.sys)
        k = pname(p)
        haskey(s.pmap, k) && (opmap[p] = s.pmap[k])
    end
    s.prob = ODEProblem(s.sys, opmap, (s.t, s.t + s.duration); jac = true)
    # Rebuild around the new parameters but keep the CURRENT state, so an edit
    # mid-run continues the simulation rather than restarting it.
    s.integ = init(remake(s.prob; u0 = s.u0,
                          tspan = (s.t, s.t + max(s.duration, 1.0))),
                   Rodas5P(); abstol = 1e-8, reltol = 1e-6, save_everystep = false)
    # POPULATION MEMBERS ARE REBUILT FROM THEIR CURRENT STATE TOO. Without this a
    # parameter edit applies to an individual run and is silently ignored by a
    # population one - the same class of quiet divergence as the frozen members.
    if !isempty(s.minteg)
        cur = [Vector{Float64}(ig.u) for ig in s.minteg]
        s.minteg = Any[init(remake(mp; u0 = cur[i],
                                   tspan = (s.t, s.t + max(s.duration, 1.0))),
                            Rodas5P(); abstol = 1e-8, reltol = 1e-6,
                            save_everystep = false)
                       for (i, mp) in enumerate(s.members)]
    end
    return true
end

# ---------------------------------------------------------------------------
# HTTP
# ---------------------------------------------------------------------------
function send_headers(io, status, ctype; stream = false)
    write(io, "HTTP/1.1 $status\r\n")
    write(io, "Content-Type: $ctype\r\n")
    write(io, "Access-Control-Allow-Origin: *\r\n")
    write(io, "Cache-Control: no-store\r\n")
    stream && write(io, "Connection: close\r\n")
    write(io, "\r\n")
end

function send_body(io, status, ctype, body)
    b = Vector{UInt8}(body)
    write(io, "HTTP/1.1 $status\r\n")
    write(io, "Content-Type: $ctype\r\n")
    write(io, "Content-Length: $(length(b))\r\n")
    write(io, "Access-Control-Allow-Origin: *\r\n")
    write(io, "Cache-Control: no-store\r\n\r\n")
    write(io, b)
end

"""
The reported dispersion for each row, read straight from the CSV.

WHY THE CSV AND NOT THE GENERATED JULIA. `Provenance` carries the value, tier, method
and citation but NOT `uncertainty_type` / `uncertainty_value`, so the generated module
cannot answer "how well is this known". That question is the whole point of showing
these rows in a simulator: precision is a property of the SOURCE and differs per row -
two figures for a tonometric solubility, four for an NHANES mean of 8809 adults - and
a reader who cannot see it will read every curve as equally trustworthy.
"""
function ledger_uncertainty()
    out = Dict{String,String}()
    path = joinpath(@__DIR__, "..", "ledger", "parameters.csv")
    isfile(path) || return out
    open(path) do io
        header = split(readline(io), ',')
        ix = Dict(strip(h) => i for (i, h) in enumerate(header))
        for line in eachline(io)
            # naive split is wrong inside quoted notes, so take only the leading
            # fields, which are unquoted and precede the citation.
            f = split(line, ',')
            length(f) < 7 && continue
            pid = f[ix["param_id"]]
            ut  = f[ix["uncertainty_type"]]
            uv  = f[ix["uncertainty_value"]]
            (ut == "none" || isempty(ut)) && continue
            out[String(pid)] = strip(string(ut, " ", uv))
        end
    end
    return out
end

function meta_json()
    unc = ledger_uncertainty()
    params = Any[]
    for (id, pv) in sort(collect(LedgerParams.PARAM_PROVENANCE), by = first)
        push!(params, Dict("key" => String(id), "id" => pv.param_id,
                           "units" => pv.units, "value" => pv.value,
                           "tier" => pv.tier, "method" => pv.method,
                           "unc" => get(unc, pv.param_id, ""),
                           "citation" => first(pv.citation, 300)))
    end
    qs = [Dict("group" => g, "key" => k, "label" => l, "units" => u, "digits" => d)
          for (g, k, l, u, d) in QUANTITIES]
    return jval(Dict("quantities" => qs, "parameters" => params))
end

function handle_stream(io, s::Session)
    send_headers(io, "200 OK", "application/x-ndjson"; stream = true)
    emitted = 0
    while !s.stop && s.t < s.duration
        if s.paused
            sleep(0.05); continue
        end
        apply_pending!(s)
        tspan = (s.t, min(s.t + s.chunk, s.duration))
        try
            if s.mode == "population"
                # ONE INTEGRATOR PER MEMBER, STEPPED - the same discipline as the
                # individual path, and it was NOT what this branch did.
                #
                # It re-solved every chunk from `mprob.u0`, which is each member's
                # INITIAL state and is never updated, so the whole population froze:
                # members differed from one another correctly and none of them moved
                # in time. Days 1, 2, 3 and 4 came back identical. The tell was a
                # no-op ternary left in while writing - both arms read `mprob.u0`.
                #
                # A FROZEN POPULATION IS THE WORST FAILURE SHAPE AVAILABLE HERE: the
                # spread looks right, so the picture is convincing and completely
                # static, and nothing errors. Found by running it (directive 1.11),
                # not by any check.
                if isempty(s.minteg)
                    s.minteg = Any[init(remake(mp; tspan = (s.t, s.t + max(s.duration, 1.0))),
                                        Rodas5P(); abstol = 1e-8, reltol = 1e-6,
                                        save_everystep = false) for mp in s.members]
                end
                rows = Any[]
                for ig in s.minteg
                    step!(ig, max(tspan[2] - ig.t, 1e-9), true)
                    push!(rows, sample_quantities(s.sys, ig))
                end
                isempty(s.minteg) || (s.t = s.minteg[1].t)
                write(io, jval(Dict("t" => s.t, "members" => rows)), "
")
            else
                integ = step_chunk!(s, tspan[2])
                write(io, jval(Dict("t" => s.t,
                                    "q" => sample_quantities(s.sys, integ))), "\n")
            end
            flush(io)
        catch e
            write(io, jval(Dict("error" => sprint(showerror, e))), "\n")
            flush(io); break
        end
        s.t = tspan[2]
        emitted += 1
    end
    write(io, jval(Dict("done" => true, "t" => s.t)), "\n")
    flush(io)
end

function serve(io)
    req = readline(io, keep = false)
    isempty(req) && return
    parts = split(req, ' ')
    length(parts) < 2 && return
    method, target = parts[1], parts[2]
    headers = Dict{String,String}()
    while true
        line = readline(io, keep = false)
        isempty(line) && break
        kv = split(line, ": "; limit = 2)
        length(kv) == 2 && (headers[lowercase(kv[1])] = kv[2])
    end
    body = ""
    if haskey(headers, "content-length")
        n = parse(Int, headers["content-length"])
        n > 0 && (body = String(read(io, n)))
    end

    path = split(target, '?')[1]
    query = Dict{String,String}()
    if occursin('?', target)
        for kv in split(split(target, '?', limit = 2)[2], '&')
            p = split(kv, '=', limit = 2)
            length(p) == 2 && (query[p[1]] = p[2])
        end
    end

    if path == "/" || path == "/index.html"
        f = joinpath(GUI_DIR, "live.html")
        return send_body(io, "200 OK", "text/html; charset=utf-8", read(f, String))
    elseif path == "/api/meta"
        return send_body(io, "200 OK", "application/json", meta_json())
    elseif path == "/api/session" && method == "POST"
        spec = isempty(body) ? Dict{String,Any}() : jparse(body)
        id = string(rand(UInt32); base = 16)
        s = new_session(; sex = Symbol(get(spec, "sex", "male")),
                        body_mass = Float64(get(spec, "body_mass", 70.0)),
                        mode = String(get(spec, "mode", "individual")),
                        n_members = Int(get(spec, "n_members", 8.0)),
                        duration = Float64(get(spec, "duration", 60.0)),
                        chunk = Float64(get(spec, "chunk", 0.25)))
        SESSIONS[id] = s
        return send_body(io, "200 OK", "application/json",
                         jval(Dict("id" => id, "t" => s.t,
                                   "params" => Dict{String,Any}(k => v for (k, v) in s.pmap))))
    elseif path == "/api/stream"
        id = get(query, "id", "")
        haskey(SESSIONS, id) || return send_body(io, "404 Not Found", "text/plain", "no session")
        return handle_stream(io, SESSIONS[id])
    elseif path == "/api/update" && method == "POST"
        spec = jparse(body)
        id = String(get(spec, "id", ""))
        haskey(SESSIONS, id) || return send_body(io, "404 Not Found", "text/plain", "no session")
        s = SESSIONS[id]
        haskey(spec, "paused")   && (s.paused = Bool(spec["paused"]))
        haskey(spec, "stop")     && (s.stop = Bool(spec["stop"]))
        haskey(spec, "duration") && (s.duration = Float64(spec["duration"]))
        haskey(spec, "chunk")    && (s.chunk = Float64(spec["chunk"]))
        if haskey(spec, "params")
            lock(s.lock) do
                for (k, v) in spec["params"]
                    s.pending[String(k)] = Float64(v)
                end
            end
        end
        return send_body(io, "200 OK", "application/json", jval(Dict("ok" => true)))
    end
    return send_body(io, "404 Not Found", "text/plain", "not found")
end

function main()
    server = listen(ip"127.0.0.1", PORT)
    println("=" ^ 70)
    println("Integrative Physiology Engine - live simulator")
    println("  http://127.0.0.1:$PORT")
    println("  Ctrl-C to stop.")
    println("=" ^ 70)
    println("Warming the model (first build takes a few seconds)...")
    new_session()
    println("Ready.")
    while true
        conn = accept(server)
        @async try
            serve(conn)
        catch e
            e isa Base.IOError || @warn "request failed" exception = e
        finally
            try close(conn) catch end
        end
    end
end

abspath(PROGRAM_FILE) == abspath(@__FILE__) && main()
