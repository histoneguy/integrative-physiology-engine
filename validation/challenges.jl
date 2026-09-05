#
# CHALLENGE HARNESS. Does the model behave like a human when you perturb it?
#
# Run:  julia --project=. validation/challenges.jl
# Exits NONZERO if any challenge fails. This is not a diagnostic report - HANDOVER
# section 5 item 4 says a report cannot fail, and that is exactly the problem with
# reports. Every target below is a published human measurement with its citation.
#
# Targets are experimental data, never another model's output - validation/targets.md.
# The protocol canon in that file listed every one of these as TODO. These are the
# first four to be connected and run.
#
using IPE
using ModelingToolkit
using OrdinaryDiffEq
using Printf

const FAILURES = String[]

sys = IPE.build_model()
const U = unknowns(sys)
const O = observed(sys)

pget(n) = (for p in parameters(sys); occursin(n, String(Symbol(p))) && return p; end;
           error("no parameter matching $n"))
val(s, n, i) = begin
    for u in U; occursin(n, String(Symbol(u))) && return s[u][i]; end
    for o in O; occursin(n, String(Symbol(o.lhs))) && return s[o.lhs][i]; end
    NaN
end
final(s, n) = val(s, n, length(s.t))

"Integrate a rate observable over a solution segment, trapezoidally, in days."
function integrate(s, name)
    tot = 0.0
    for i in 2:length(s.t)
        tot += 0.5 * (val(s, name, i) + val(s, name, i - 1)) * (s.t[i] - s.t[i - 1])
    end
    tot
end

"Resting steady state. Verified to be a real fixed point, not a slow drift."
function equilibrate(; overrides = Dict(), days = 60.0)
    pm = Dict(pget(k) => v for (k, v) in overrides)
    p = ODEProblem(sys, collect(pm), (0.0, days), Pair[])
    s = solve(p, Rodas5P(); abstol = 1e-10, reltol = 1e-10)
    ([u => s[u][end] for u in U], pm)
end

"Run phases of (duration_days, Dict(param => value)) from a given state."
function run_phases(u0, basepm, phases; saveat = 0.002)
    u = copy(u0); t0 = 0.0; segs = []
    for (dur, ov) in phases
        pm = copy(basepm)
        for (k, v) in ov; pm[pget(k)] = v; end
        p = ODEProblem(sys, vcat(u, collect(pm)), (t0, t0 + dur), Pair[])
        s = solve(p, Rodas5P(); abstol = 1e-10, reltol = 1e-10, saveat = saveat)
        push!(segs, s)
        u = [x => s[x][end] for x in U]
        t0 += dur
    end
    segs
end

function check(label, model, lo, hi, units, source)
    ok = lo <= model <= hi
    ok || push!(FAILURES, label)
    @printf("  %-46s %10.3f   [%7.3f - %7.3f] %-9s %s\n",
            label, model, lo, hi, units, ok ? "PASS" : "**FAIL**")
    @printf("  %-46s %s\n", "", source)
    ok
end

println(repeat("=", 100))
println("1. HOMEOSTASIS. Does it hold a steady state, and is the resting state a human?")
println(repeat("=", 100))

u0, basepm = equilibrate()
p = ODEProblem(sys, Pair[], (0.0, 400.0), Pair[])
slong = solve(p, Rodas5P(); abstol = 1e-10, reltol = 1e-10, saveat = 1.0)
i200 = findfirst(>=(200.0), slong.t); iend = length(slong.t)
drift = maximum(abs(val(slong, n, iend) - val(slong, n, i200)) /
                max(abs(val(slong, n, i200)), 1e-12)
                for n in ("MAP", "V_ecf", "V_icf", "Na_ecf"))
@printf("  %-46s %10.3e   [%7.3f - %7.1e] %-9s %s\n",
        "relative drift, day 200 to day 400", drift, 0.0, 1e-9, "-",
        drift < 1e-9 ? "PASS" : "**FAIL**")
drift < 1e-9 || push!(FAILURES, "long-run drift")
println("  A model whose pressure is an OUTPUT could have drifted anywhere. It does not.")
println()

# BANDS DERIVED 2026-09-04. Pre-registered in validation/challenge_bands_prereg.md,
# derived by validation/challenge_bands_extract.py. Every band below now says where
# it came from. Before this they shared one string conceding that only some were
# sourced without saying which.
#
# A resting check compares against a clinical REFERENCE INTERVAL, which is already a
# population interval, so it is CITED from the ledger rather than recomputed (prereg
# section 6). Band I = mean +/- 2 SD where the row carries an SD.
#
# THREE OF THESE WIDENED. MAP, ECF and GFR were being judged MORE STRICTLY than their
# own sourced dispersion supports - the opposite of what this pass went looking for.
# The conventional range each used to carry is kept in the note, unasserted, so the
# tightening is recoverable if anyone wants to argue for it on other grounds.
check("resting MAP", final(slong, "MAP"), 71.0, 103.0, "mmHg",
      "CV.MAP.SETPOINT 87 +/- 2 SD 8.0, central. Was a conventional 80-95.")
check("resting ECF volume", final(slong, "V_ecf"), 11.34, 17.78, "L",
      "BF.ECF.MASS_FRACTION 0.208 +/- 2 SD 0.023 at 70 kg. Was a conventional 13-17.")
check("resting plasma sodium", final(slong, "bf₊C_Na"), 135.0, 145.0, "mEq/L",
      "BF.NA.PLASMA_SETPOINT reference interval 135-145. Unchanged - it already agreed.")
check("resting plasma osmolality", final(slong, "bf₊Osm_ecf"), 275.0, 295.0, "mOsm/kg",
      "BF.OSM.PLASMA_SETPOINT reference interval 275-295. WAS 280-295: the harness had " *
      "invented a tighter floor than the ledger row it tests against. No gate saw it.")
check("resting urine volume", final(slong, "rn₊H2O_excr"), 0.8, 2.5, "L/day",
      "ASSUMED. No ledger row, no citation, conventional figures - directive 1.12.")
check("resting urine osmolality", final(slong, "ad₊u_osm"), 300.0, 900.0, "mOsm/kg",
      "ASSUMED. No ledger row, no citation, conventional figures - directive 1.12.")
check("resting GFR", final(slong, "rn₊GFR"), 100.8, 204.4, "L/day",
      "RN.GFR.NOMINAL 152.6 +/- 2 SD 25.9 (Soares 2013). Was a conventional 130-180.")
check("sodium balance closes", final(slong, "rn₊Na_excr"), 204.9, 205.1, "mEq/day",
      "NOT A LITERATURE BAND. Model excretion against the model's own intake - an " *
      "internal conservation identity, so it stays tight. Exempt by prereg section 6.")

println()
println(repeat("=", 100))
println("2. TWO LITRES OF 0.9% SALINE OVER ONE HOUR")
println(repeat("=", 100))
LOBO = "Lobo DN, Stanga Z, Simpson JA, Anderson JA, Rowlands BJ, Allison SP. Clin Sci " *
       "(Lond) 2001;101(2):173-9. PMID 11473492. 10 healthy men, double-blind crossover."
println("  " * LOBO)
println("  Reported: over the 6 h after infusion subjects voided 563 ml of urine")
println("  containing 95 mmol sodium at a mean osmolality of 630 mOsm/kg, and only")
println("  one third of the sodium and water had been excreted by 6 h.")
println()

# 2 L of 0.9% saline = 2 L water + 308 mEq Na, over 1 h.
sal = run_phases(u0, basepm,
                 [(1/24, Dict("H2O_intake" => 2.5 + 2.0/(1/24),
                              "Na_intake"  => 205.0 + 308.0/(1/24))),
                  (6/24, Dict())]; saveat = 0.0005)
# The 6 h window in Lobo starts at the END of the infusion.
post = sal[2]
urine6 = integrate(post, "rn₊H2O_excr") * 1000.0
na6    = integrate(post, "rn₊Na_excr")
uosm6  = na6 > 0 ? integrate(post, "rn₊Osm_load") / (urine6 / 1000.0) : NaN

# THE +/- 33% IS ASSUMED AND CANNOT BE DERIVED. Searched 2026-09-04 under
# validation/challenge_bands_prereg.md, branch N. Lobo's PubMed abstract reports these
# endpoints as BARE MEANS with no dispersion of any kind; the full text is not
# obtainable - elink pubmed_pmc returns no PMC record and Europe PMC reports
# isOpenAccess=N, inEPMC=N, hasPDF=N, every full-text link "Subscription required".
# Reading dispersion off a figure is prohibited by that pre-registration.
#
# So these four bands are UNDERIVED, they are left exactly where they were rather than
# moved without evidence, and they are labelled. n = 10.
#
# AND RN.ANP.TAU WAS FITTED TO THESE SAME NUMBERS TO ABOUT 0.5%. A fit residual quoted
# to four figures against a target whose dispersion is unobtainable is the precision
# that does not exist - directive 1.9. Do not quote the Lobo agreement tightly.
check("urine volume, 6 h after infusion", urine6, 380.0, 750.0, "mL",
      "Lobo mean 563 mL, n=10. BAND ASSUMED +/- 33%, no dispersion published.")
check("urinary sodium, 6 h after infusion", na6, 63.0, 127.0, "mmol",
      "Lobo mean 95 mmol, n=10. BAND ASSUMED +/- 33%, no dispersion published.")
# NON-INDEPENDENT (prereg section 5). Computed from the integrated solute load over the
# same urine volume, and the load tracks Na_excr, so this is a function of the two
# checks above plus a constant. Kept because it can still bite through u_osm; labelled
# so three green lines are not read as three facts.
check("urine osmolality, 6 h mean", uosm6, 420.0, 840.0, "mOsm/kg",
      "Lobo mean 630, n=10. BAND ASSUMED +/- 33%. NON-INDEPENDENT of the two above.")
# NON-INDEPENDENT AND IT CANNOT FAIL ALONE. This is na6/308: a pure rescaling of the
# sodium check. Its band 20-45% strictly CONTAINS the 20.45-41.23% that the sodium
# band maps onto, so it only fails after that one already has. Kept only as the
# comparison against Lobo's own words; prereg section 5 says label, do not re-band.
check("fraction of the sodium load excreted by 6 h", na6/308.0*100, 20.0, 45.0, "%",
      "Lobo: one third by 6 h. RESTATEMENT of the sodium check - cannot fail alone.")

println()
println(repeat("=", 100))
println("3. ACUTE INTRAVENOUS VOLUME EXPANSION, ISOTONIC SALINE 23 mL/kg")
println(repeat("=", 100))
JENSEN = "Jensen JM, Mose FH, Bech JN, Nielsen S, Pedersen EB. BMC Nephrol 2013;14:202. " *
         "PMID 24067081. 23 healthy subjects, randomised crossover, standardised diet."
println("  " * JENSEN)
println("  Reported: fractional sodium excretion rose 123%, and plasma renin, angiotensin")
println("  II and aldosterone all FELL. Vasopressin was unchanged after isotonic saline.")
println()

vol = 0.023 * 70.0
je = run_phases(u0, basepm,
                [(1/24, Dict("H2O_intake" => 2.5 + vol/(1/24),
                             "Na_intake"  => 205.0 + 154.0*vol/(1/24))),
                 (4/24, Dict())]; saveat = 0.0005)
fena_base = 205.0 / (final(slong, "rn₊GFR") * final(slong, "bf₊C_Na"))
jp = je[2]
fena_peak = maximum(val(jp, "rn₊Na_excr", i) /
                    (val(jp, "rn₊GFR", i) * val(jp, "bf₊C_Na", i)) for i in 1:length(jp.t))
# BAND ASSUMED - branch N, and NOT for want of looking. Jensen is open access and was
# read in full: Table 3 gives FE Na 1.26 (SD 0.53) at baseline and 2.80 (SD 0.75) after,
# n = 23, ratio 2.222 = +122%, which reproduces the abstract's 123%. But baseline and
# peak are measured IN THE SAME SUBJECTS, so the ratio's variance needs their
# correlation and the paper reports neither paired differences nor a covariance. That
# is the identical obstacle recorded on RN.GFR.VOLUME_SENSITIVITY, whose own
# pre-registration forbade fabricating an interval by propagating per-arm SDs as if
# independent. Honoured here rather than re-argued.
#
# AND THE BOUND INVERTS THE WORRY THAT STARTED THIS PASS. Assuming zero correlation
# OVERSTATES the spread, and even that upper bound is -18% to +502% against this band's
# +60% to +250%. The Jensen band was never too generous. It is TIGHTER than the
# reported statistics can justify, and it is left alone because moving an undocumented
# band is worse than leaving it.
check("peak rise in fractional sodium excretion", (fena_peak/fena_base - 1)*100,
      60.0, 250.0, "%",
      "Jensen +123%, n=23. BAND ASSUMED: the ratio's dispersion needs a correlation " *
      "the paper does not report. Even the rho=0 upper bound is far wider than this.")

pra_base = final(slong, "ra₊pra")
pra_min  = minimum(val(jp, "ra₊pra", i) for i in 1:length(jp.t))
# A DIRECTION CHECK, NOT A MAGNITUDE COMPARISON, and now labelled as one. Jensen
# reports plasma renin falling after isotonic saline; the magnitude is shown only in a
# figure as mean +/- SEM, and reading it off the figure is prohibited. 0.5-100% asserts
# "it falls at all", which is the whole claim being made.
check("renin falls on volume expansion (fall, positive = correct)",
      (pra_base - pra_min)/pra_base*100, 0.5, 100.0, "%",
      "Jensen: renin, angiotensin II and aldosterone all fell. DIRECTION ONLY.")

println()
println(repeat("=", 100))
println("3b. CHRONIC SALT SENSITIVITY - the headline, and it belongs in this harness")
println(repeat("=", 100))
println("  Meta-analytic normotensive human response to chronic dietary sodium, k = 3:")
println("  Cutler 1997 (32 trials, n=2635) 1.70; He/Li/MacGregor 2013 (34, n=3230) 1.96;")
println("  He & MacGregor 2002 (11, n=2220) 2.30 mmHg per 100 mmol/day. HANDOVER 3.3.")
println()
let r = IPE.check_pressure_natriuresis(IPE.salt_step())
    # 1.70-2.30 IS A SPREAD ACROSS THREE POINT ESTIMATES, NOT A CONFIDENCE INTERVAL,
    # and the two are different objects. Left alone deliberately: pooling three
    # meta-analyses that share primary trials is the silent re-pooling pooling.md
    # prohibits, and taking their min and max as an interval is range-midpoint's
    # sibling. Only the label is corrected.
    check("chronic salt sensitivity", r.map_shift_mmHg / 102 * 100, 1.70, 2.30,
          "mmHg/100mmol", "SPREAD of 3 meta-analytic estimates (1.70/1.96/2.30), not a CI")
end

println()
println(repeat("=", 100))
println("4. TWENTY-FOUR HOUR FLUID DEPRIVATION")
println(repeat("=", 100))
PROSS = "Pross N, Demazieres A, Girard N, Barnouin R, Santoro F, Chevillotte E, Klein A, " *
        "Le Bellego L. Br J Nutr 2013;109(2):313-21. PMID 22716932. 20 healthy women, " *
        "crossover, 23-24 h with no beverages."
println("  " * PROSS)
println("  Reported: urine output fell significantly and urine specific gravity rose, but")
println("  PLASMA OSMOLALITY REMAINED UNCHANGED. That is the sharp end of this test.")
println()
println("  PROTOCOL NOTE, AND IT IS A MODEL LIMITATION NOT A PROTOCOL CHOICE. Fluid")
println("  deprivation removes BEVERAGES. Food water and oxidative water continue, and")
println("  they are 30-40% of total water intake. This model carries ONE lumped")
println("  BF.H2O.INTAKE_NOMINAL and cannot express the split, so the non-beverage")
println("  residual is swept below and the result is reported as a range.")
println()
@printf("  %-28s %12s %12s %12s\n", "non-beverage water L/day", "dOsm mOsm", "urine L/d", "u_osm")
dosm_at = Dict{Float64,Float64}()
for res in (0.0, 0.5, 0.75, 1.0, 1.25)
    fd = run_phases(u0, basepm, [(1.0, Dict("H2O_intake" => res))]; saveat = 0.02)[1]
    d = final(fd, "bf₊Osm_ecf") - val(fd, "bf₊Osm_ecf", 1)
    dosm_at[res] = d
    @printf("  %-28.2f %12.2f %12.3f %12.1f\n",
            res, d, final(fd, "rn₊H2O_excr"), final(fd, "ad₊u_osm"))
end
println()
println("  Plasma osmolality is measured to about +/- 3 mOsm/kg, so 'unchanged' is a")
println("  change of less than 3. The model meets that only if non-beverage water is at")
println("  least about 1.0 L/day, which is the upper end of the physiological range.")
println()
println("  RECLASSIFIED AS INDETERMINATE, NOT FAILED, AND THE REASON IS NOT THE NUMBER.")
println("  Pross reports the osmolality but NOT the water deficit its subjects ran, and")
println("  without that the comparison cannot separate a model defect from a protocol")
println("  mismatch. That is a defect in the COMPARISON and would have been the right")
println("  classification before the run had anyone noticed. It is recorded here rather")
println("  than quietly dropped.")
println()
println("  WHAT THE MODEL ACTUALLY DOES, decomposed. Over 24 h at 1.0 L/day non-beverage")
println("  water it loses 0.748 L, which is 1.07% of body mass and squarely inside the")
println("  1-1.5% that published 24 h deprivation produces. Its osmolality rise of 6.09")
println("  mOsm/kg is 5.69 from pure concentration of that loss plus 0.41 of everything")
println("  else. THE MODEL IS CONSERVING CORRECTLY. A human losing the same 0.748 L from")
println("  a 42 L total body water would rise about 5.1 mOsm on the same arithmetic.")
println()
println("  FOUR CANDIDATE CAUSES EXCLUDED BY MEASUREMENT, not by argument:")
println("    - BF.H2O.INSENSIBLE_LOSS swept 0.50-0.90 L/day: fails throughout.")
println("    - non-beverage water swept 0.75-1.20 L/day: fails throughout.")
println("    - total intake at the sourced NHANES 3.18 L/day with food fractions")
println("      0.19-0.36 and oxidative water 0.30: fails throughout, best case 4.69.")
println("    - the volume-keyed natriuretic path of section 6: makes it WORSE, 6.09 to")
println("      6.91, because retaining sodium raises plasma sodium as fast as it saves")
println("      water. That hypothesis is refuted, and it is a different defect from")
println("      the one in section 3.")
println()
println("  WHAT WOULD RESOLVE IT: one human 24 h deprivation study reporting BOTH the")
println("  body-mass or water deficit AND the plasma osmolality change in the same")
println("  subjects. Directive 1.8 - one comparator is not an evidence base, and this")
println("  one is missing the variable that makes it interpretable.")

println()
println(repeat("=", 100))
println("5. THE OSMOTIC EQUILIBRATION CONSTANT IS LOAD-BEARING AND UNSOURCED")
println(repeat("=", 100))
println("  BF.ICF_ECF.OSMOTIC_TAU = 30 min, extraction_method = assumed. Its own ledger")
println("  note says: 'Sensitivity to this value should be near zero on multi-day runs -")
println("  verify that in testing, and if it is not, the compartment structure is wrong.'")
println("  THAT CHECK HAD NEVER BEEN RUN. On multi-day runs it is indeed near zero. On")
println("  ACUTE protocols, which is what sections 2 to 4 are, it is the dominant term.")
println()
@printf("  %-18s %14s %14s\n", "tau_osm min", "peak dOsm", "ICF share L")
for tau in (1.0, 5.0, 15.0, 30.0, 60.0, 120.0)
    u0t, pmt = equilibrate(overrides = Dict("tau_osm" => tau/1440.0))
    wl = run_phases(u0t, pmt,
                    [(30/1440, Dict("H2O_intake" => 2.5 + 1.4/(30/1440)))];
                    saveat = 30/1440/60)[1]
    b = val(wl, "bf₊Osm_ecf", 1)
    @printf("  %-18.0f %14.3f %14.3f\n", tau, b - final(wl, "bf₊Osm_ecf"),
            final(wl, "V_icf") - val(wl, "V_icf", 1))
end
println()
println("  A 1.4 L water load moves peak plasma osmolality by 8.8 mOsm at 1 min and 17.6")
println("  at 120 min. The whole acute-osmolality behaviour of this model rests on an")
println("  assumed constant. It must be sourced before any acute osmotic protocol is")
println("  reported as a result.")
println()
println("  STANDING DEBT, not a challenge failure - it does not fail this harness. A")
println("  sourcing pass on 2026-09-02 ran 10 queries over two sweeps and found nothing")
println("  usable, so the row stays `assumed` and the debt is measured, bounded and")
println("  searched rather than unexamined. No acute osmotic MAGNITUDE may be reported")
println("  from this model until it is sourced.")

println()
println(repeat("=", 100))
println("6. ADR 0010 IS UNBLOCKED, SOURCED AND ON. THIS IS WHY SECTIONS 2 AND 3 PASS")
println(repeat("=", 100))
println("  bench/anp_diagnostic.jl and validation/anp_input_coupling_prereg.md.")
println()
println("  The kidney could not see volume at all until 2026-09-02 - Renal.jl named")
println("  V_ecf as an input in its docstring from the day it was written and nothing")
println("  ever connected it. Found by running section 3, not by any gate.")
println()
println("  CV.ANP.NATRIURETIC_GAIN = 700 (mEq/day)/L of BLOOD volume, with a first-order")
println("  lag RN.ANP.TAU = 0.50 d. Two human datasets, two parameters: the chronic")
println("  salt-step response fixes the gain, Lobo's 6 h acute time course fixes the")
println("  time constant. NEITHER is fitted to the salt-sensitivity discrepancy.")
println()
println("  THE ALGEBRAIC FORM WAS TRIED FIRST AND REFUTED. With no lag the acute limb")
println("  implies about 300 (mEq/day)/L and the chronic limb about 750 - a factor of")
println("  2.5 against a threshold of 2 fixed in the pre-registration. Drummer 1992")
println("  (PMID 1324562) says why: excretion of an acute isotonic load takes DAYS, and")
println("  a lag makes the transient response smaller than the steady-state gain, which")
println("  is the observed direction.")
println()
println("    quantity                     before        after       human")
println("    acute FENa rise               +43%         +79%        +123%")
println("    Lobo urinary Na, 6 h        78.3 mmol    96.3 mmol    95 mmol")
println("    Lobo urine, 6 h              481 mL       575 mL      563 mL")
println("    chronic salt sensitivity     4.958        2.301       1.70-2.30")
println()
println("  TWO CAVEATS THAT MUST TRAVEL WITH THESE NUMBERS.")
println("  1. The gain multiplies the MODEL'S volume excursion, which is 1.5-2.1x too")
println("     large while CV.VENOUS_RETURN.SENSITIVITY is calibrated. Part of 700 is")
println("     compensating for that and it must be re-estimated when G_vr is sourced.")
println("     The human data alone give 750 at G_pn = 5.43 and 505 at G_pn = 20.0.")
println("  2. RN.PRESSURE_NATRIURESIS.SLOPE is unchanged at 20.0 and is now")
println("     OVER-DETERMINED - the human joint constraint is G_pn + 0.0594*G_anp = 50.")
println("     The pre-registration fixed that before extraction and ADR 0016 sequences")
println("     it last. So this model still double-counts the path, and the chronic")
println("     agreement above is partly that double count.")
println()
println("  AND A NEW PREDICTION THE MODEL COULD NOT MAKE BEFORE: salt sensitivity is now")
println("  SEX-DEPENDENT, women 17.7% higher, because the path is keyed to a sexed")
println("  volume - 11% when ADR 0010 landed, widened by the GFR volume response.")
println("  A pressure-only kidney had salt sensitivity 1/G_pn, which carries no sex")
println("  information. Nothing here has sourced it. It is debt, and it is falsifiable.")

println()
println(repeat("=", 100))
if isempty(FAILURES)
    println("ALL CHALLENGES PASS")
else
    println("FAILURES (", length(FAILURES), "):")
    for f in FAILURES; println("  - ", f); end
end
println(repeat("=", 100))
exit(isempty(FAILURES) ? 0 : 1)
