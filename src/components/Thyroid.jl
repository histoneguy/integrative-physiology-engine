"""
The hypothalamic-pituitary-thyroid axis - ONE STATE, and the first endocrine
component in this model that is not in service of pressure or water.

STRUCTURE SOURCES
  Log-linear negative feedback of free thyroxine on thyrotropin:
    Benhadi N, Fliers E, Visser TJ, Reitsma JB, Wiersinga WM. Eur J Endocrinol
    2010;162(2):323-9. PMID 19926783. ABSTRACT ONLY. 21 healthy volunteers,
    randomised T4 and T3 loading - an intervention, not a cross-section.
    and Jostel A, Ryder WDJ, Shalet SM. Clin Endocrinol (Oxf) 2009;71(4):529-34.
    PMID 19226261, 9519 tests in 4064 patients. THE ENTERED SLOPE IS THE MEAN OF
    THE TWO, which agree to 1%.
  Thyroxine turnover, and the euthyroid free thyroxine that sets the scale:
    Braverman LE, Vagenakis A, Downs P, Foster AE, Sterling K, Ingbar SH.
    J Clin Invest 1973;52(5):1010-7. PMC302354. OPEN ACCESS, read in full.
    Equilibrium dialysis, control periods, euthyroid subjects.
  Thyroid hormone and resting metabolic rate:
    Maushart CI et al. J Clin Endocrinol Metab 2022;107(2):450-461. PMC8764338.
    OPEN ACCESS, read in full. Paired hyperthyroid -> euthyroid measurements.

EVIDENCE (ADR 0006)
  E1  Thyroid hormone inhibits thyrotropin secretion. The basis of all thyroid
      function testing.
  E1  The relationship is approximately log-linear, which is why thyrotropin is
      reported logarithmically in clinical practice.
  E2  The quantitative slope: two independent estimates agreeing to 1%, but both
      abstract-only and both in cohorts with wide between-person variation.
  E2  The intercept: ONE source, and it carries the whole discrepancy. See below.
  E1  Thyroid hormone sets resting energy expenditure.
  E2  The size of that effect, from a disease preparation - see the ledger note
      on THY.METABOLIC_GAIN and amendment 8.3 of the pre-registration.

WHY THERE IS ONE STATE AND NOT TWO

ADR 0019 decision 3 planned a two-state loop. `validation/thyroid_prereg.md`
section 4 wrote the escape in advance: if the fast state makes the system stiff,
the thyrotropin limb is made algebraic and the reason recorded. Thyrotropin turns
over in MINUTES; thyroxine's time constant is 10.3 days and this model runs for
400. So the pituitary limb is algebraic and the thyroxine limb is the one state.

That is the same quasi-static argument ADR 0017 makes for ventilation, applied to
the fast half of a loop whose slow half genuinely needs integrating. The slowness
IS the physiology here - an axis that takes weeks to re-equilibrate cannot be an
algebraic relation - and directive 1.10 says the state is paid on every run, so
only the half that earns it gets one.

THE EUTHYROID THYROTROPIN IS A PREDICTION, AND THE MODEL GETS IT WRONG BY 2.4x

Free thyroxine is sourced from equilibrium dialysis in normal subjects; the
pituitary line is sourced from a T4-loading experiment in different subjects.
Neither is a thyrotropin reference value, so the crossing point is a genuine
prediction - and it lands at 3.35 mIU/L against a NHANES III reference-population
geometric mean of 1.40.

IT IS REPORTED AND NOT TUNED, which is branch T2 of the pre-registration. The
decomposition is arithmetic: sweeping the slope across its whole two-source spread
moves the prediction by 2% against a discrepancy of 2.4x, the free thyroxine has
two estimates agreeing within a standard deviation, and the INTERCEPT has one
source that reports no standard error for it. An intercept is a line extrapolated to FT4 = 0 from data that
never went near zero - the third time this repository has been bitten by exactly
that, after the ADR 0017 chemoreflex amendment and HANDOVER section 3.22's
censoring bound.

Nothing downstream consumes thyrotropin. What reaches the rest of the model is
free thyroxine, through the metabolic arm, and that quantity is corroborated.

WHAT THIS DELIBERATELY OMITS
  Triiodothyronine, deiodination and protein binding - free thyroxine only, so
  the model is blind to the low-T3 state, deiodinase inhibition, and the
  T4-versus-combination-therapy question. Thyrotropin-releasing hormone and the
  hypothalamic level; the loop closes at the pituitary. Circadian variation in
  thyrotropin, which is real and which the existing clock could drive. Any
  disease state. All per ADR 0019.
"""

using ModelingToolkit
using ModelingToolkit: t_nounits as t, D_nounits as D

using ..LedgerParams
using ..LedgerParams:
    THY_TSH_FT4_SLOPE, THY_TSH_INTERCEPT, THY_FT4_EUTHYROID,
    THY_FT4_TAU, THY_FT4_GAIN, THY_METABOLIC_GAIN

"""
    Thyroid(; name, feedback = true, metabolic = false, sec_cap = 1.0)

The thyrotropin-thyroxine loop, and the metabolic multiplier it drives.

Inputs   none
Outputs  FT4 (pmol/L), TSH (mIU/L), th_mod (dimensionless, 1.0 at euthyroid)

`sec_cap` is THYROID SECRETORY CAPACITY as a multiple of normal. It is the knob
ADR 0019's falsifiable test 1 turns and the only way to express thyroid disease:
below 1 is hypothyroidism, above 1 is thyrotoxicosis. Neither is built here.

`feedback = false` OPENS THE LOOP by holding thyrotropin at its euthyroid value,
so free thyroxine responds to `sec_cap` in full proportion. That is the control
arm falsifiable test 1 needs - the closed loop must respond by LESS.

`metabolic = false` (the default, ADR 0019 decision 4) pins `th_mod` at exactly
1.0, so the respiratory CO2 load is untouched and every existing result is
unchanged. The feedback loop is E1 and defaults on; the size of the metabolic
effect is the part most likely to be wrong and it moves the water balance.
"""
function Thyroid(; name, feedback::Bool = true, metabolic::Bool = false,
                 sec_cap = 1.0)

    pars = @parameters begin
        # ALL INTENSIVE. Concentrations, a fractional rate and two gains between
        # concentrations. None of them is a per-body quantity, so unlike the
        # respiratory and cardiovascular parameters none is scaled by body size -
        # a bigger thyroid serves a bigger body and the hormone concentration it
        # defends is the same.
        a_tsh   = THY_TSH_INTERCEPT
        b_tsh   = THY_TSH_FT4_SLOPE
        tau_t4  = THY_FT4_TAU
        G_T     = THY_FT4_GAIN
        FT4_ref = THY_FT4_EUTHYROID
        G_met   = THY_METABOLIC_GAIN
        S_thy   = sec_cap
    end

    vars = @variables begin
        FT4(t) = THY_FT4_EUTHYROID   # pmol/L   THE ONE STATE
        TSH(t)                       # mIU/L    algebraic, see the header
        th_mod(t)                    # -        OUTPUT to respiratory CO2 load
    end

    # THE EUTHYROID THYROTROPIN, computed once at construction from the sourced
    # line and the sourced free thyroxine. It is what `feedback = false` holds
    # thyrotropin at, and it is the number ADR 0019 falsifiable test 2 judges.
    TSH_ref = exp(THY_TSH_INTERCEPT - THY_TSH_FT4_SLOPE * THY_FT4_EUTHYROID)

    eqs = [
        # THE PITUITARY LIMB. Log-linear negative feedback, written as the
        # exponential so thyrotropin is positive by construction rather than by
        # hoping the integrator stays in range.
        #
        # feedback is a build-time Bool, so this resolves to ONE concrete equation
        # at construction - the same pattern as the ADH, RAAS and respiratory
        # disabled branches, not a runtime branch in the compiled system.
        TSH ~ feedback ? exp(a_tsh - b_tsh * FT4) : TSH_ref,

        # THE THYROID LIMB, and the only state in this component. Secretion is
        # proportional to thyrotropin and to secretory capacity; clearance is
        # first-order with the measured turnover time constant.
        #
        # At S_thy = 1 this sits at rest exactly: G_T is DERIVED so that
        # G_T*TSH_ref = FT4_ref, which check_closure.py recomputes rather than
        # reads back. So building the model does not perturb anything, and the
        # initial condition above is the equilibrium rather than a guess near it.
        D(FT4) ~ (G_T * S_thy * TSH - FT4) / tau_t4,

        # THE METABOLIC ARM. A fractional change in free thyroxine gives G_met
        # times that fractional change in resting metabolic rate, and - because
        # the source measured the respiratory quotient and found it unmoved by
        # thyroid state - the same fractional change in CO2 production.
        #
        # Exactly 1.0 when off, not approximately: with metabolic = false this is
        # the literal constant and structural_simplify eliminates it, so the
        # respiratory load is the bare parameter it was before this component
        # existed. thyroid_prereg.md section 6 requires bit-identity, not
        # closeness.
        th_mod ~ metabolic ? 1.0 + G_met * (FT4 / FT4_ref - 1.0) : 1.0,
    ]

    return MTKSystem(eqs, t, vars, pars; name)
end

"""
    thyroid_couplings()

Declared connections, per src/coupling.jl.

ONE EDGE, thyroid -> respiratory, and it is Neurohumoral rather than Conservation:
the multiplier scales a metabolic load, it does not carry mass across a boundary.
The lag it carries is thyroxine's own turnover, 10.3 days, which is by an enormous
margin the slowest coupling in this model and the safest thing in it to partition
across.

IT IS DECLARED EVEN THOUGH THE ARM DEFAULTS OFF, because the connection is built
either way - with `metabolic = false` the signal is the constant 1.0. Declaring
only the enabled case is how `bodyfluids -> endocrine` came to name a subsystem
that did not exist and was silently skipped for weeks (see `model_couplings`).
"""
function thyroid_couplings()
    return [
        Coupling(:thyroid, :respiratory, Neurohumoral;
                 tau_seconds = THY_FT4_TAU * 86400.0,
                 gain_param = :THY_METABOLIC_GAIN,
                 note = "thyroid hormone scales resting metabolic rate and " *
                        "therefore CO2 production"),
    ]
end
