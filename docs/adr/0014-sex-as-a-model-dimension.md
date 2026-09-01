# ADR 0014: Sex is a model dimension, not a nuisance parameter

**Status:** Proposed
**Date:** 2026-08-26
**Evidence tier:** n/a - methodological. This record decides how sex-dependent
values are represented and resolved. The dimorphism of any particular parameter is
an evidence question settled row by row in the ledger, not here.

## Context

The owner's decision: the model represents both sexes, and sex is selectable in the
eventual interface. Where sex-specific values exist they are used; otherwise the best
available data is used for both.

The ledger anticipated this and then deferred it. `CV.HEMATOCRIT.NOMINAL` has read
**"Adult male nominal. Sex-dependent - female nominal is lower. Sex is deferred until
the spine is validated"** since 2026-08-08. The spine completed when circadian was
connected, so the deferral condition has expired.

### The schema could not express it

There was no `sex` column, and `ledger_to_julia.py` treated a repeated `param_id` as a
hard error - one parameter, one value. This is the first change in this repository that
meets directive 1.2's bar of *something that breaks and cannot be worked around*: two
sexes cannot be represented in a schema that permits one value per parameter.

### And most of the ledger rests on male cohorts, unrecorded

From rows touched in the last two days alone: Kelly and Nelson n=4 males,
el-Hajj Fuleihan 11 males, Kanabrocki 11 males, Gybel-Brask 21 men, Epstein 60 males,
Bihari 6 males. Against Ueno - 20 women - which supplies the circadian sodium acrophase
that disagrees with everything else in that literature.

**`species` is recorded on every row. Sex was recorded on none.** Adding the dimension
without recording cohort composition would have hidden that.

## Decision

**A `sex` column on `ledger/parameters.csv`, taking `both`, `male` or `female`. The
uniqueness key becomes `(param_id, sex)`.**

### The pairing rule, which is the substance of this record

**A parameter has either exactly one `both` row, or both a `male` row and a `female`
row. Never one sexed row alone.**

A lone `male` row would leave the female case resolving to nothing, or - worse, if the
fallback were permissive - silently applying male data to women while looking
sex-aware. Where only one sex has been studied, the row stays `both` and the cohort
goes in the notes. **That is what "otherwise use the best data" means operationally:
shared value, honest label.**

Enforced in `ledger_to_julia.py`. Both failure directions were verified before this
landed: a lone `male` row is rejected with the rule quoted back, and a proper pair is
accepted and emitted.

### Resolution

    param(sym::Symbol, sex::Symbol) -> Float64

Sex-specific where the pair exists, shared constant otherwise.

**Asking for `:both` on a dimorphic parameter is an ERROR, not an average.** Averaging
male and female values produces a number describing no one - the same objection
`pooling.md` already raises against averaging across species, and the same objection
ADR 0006's amendment raised against using species as a proxy for quality. There is no
`:both` individual.

`build_model(; sex = :male | :female)` threads sex to the components; `salt_step` passes
it through. `Cardiovascular` resolves haematocrit through the accessor already, so the
path is exercised rather than merely available - the day a male/female haematocrit pair
is entered, nothing in the component changes.

### Closure is now one question per sex

`check_closure.py` resolves per sex and runs twice. Every derived value depends on
parameters that may be dimorphic - `f_pv` on haematocrit, `TPR0` on MAP and CO, `SV0`
on CO0 and HR0, `U_max` on solute load - so a derivation that closes for men can fail
for women the moment a pair is entered. Both currently pass because nothing is
dimorphic yet, which is the point: the check is in place *before* the first pair.

## What this deliberately does not do

**It enters no sex-specific values.** Every row is `both`. The machinery is inert today
and that is intentional, the same argument as ADR 0012 stage 1: the variable and the
rule exist, so each dimorphic parameter can be added one at a time without touching any
of this.

**Populating it is a sourcing task with a selection hazard**, and it gets its own
pre-registration. A search for sex differences, run by someone who knows the model wants
them, will find them. The inclusion criteria and the fallback rule must be fixed before
the search, exactly as for `G_pn`.

## Falsifiable test

**A parameter pair must change a result, and the right one.** When the haematocrit pair
lands, `salt_step(sex = :female)` must differ from `salt_step(sex = :male)`, and it must
differ *through the plasma-volume path* - lower haematocrit gives more plasma per unit
blood volume, so `f_pv` must be re-derived per sex and `check_closure` must fail loudly
if it is not.

If a pair lands and results do NOT move, the accessor is not on the path the component
actually uses and the wiring is decorative.

## What is NOT decided

- **Which parameters are dimorphic.** An evidence question, per row.
- **Whether `body_mass` becomes sex-dependent.** It is currently a 70 kg argument, not a
  ledger row, and it scales ECF, blood volume and GFR. Probably the largest single
  dimorphism in the model and it is not addressed here.
- **Whether sex is a covariate for population sampling** rather than a switch. The
  circadian arm already has sex-dependence recorded in `targets.md` as a covariate.
  Those are different uses and the second is not built.
- **Pregnancy, or any within-sex state.** Out of scope.

## The falsifiable test is satisfied, and it was satisfied by volumes — 2026-09-01

"Both currently pass because nothing is dimorphic yet" in *Closure is now one question
per sex*, and "It enters no sex-specific values. Every row is `both`" in *What this
deliberately does not do*, are both **out of date and were already out of date on
2026-08-27**. Ten parameters now carry male/female pairs. Read those sections as the
record of what was true when the machinery was built, not as a description of the ledger.

**The falsifiable test asked that a pair change a result. It now does, and not in the
place this record predicted.**

`CV.SV.NOMINAL` was sourced per sex on 2026-09-01 (Petersen 2017, CMR), so `CV.CO.NOMINAL`
became a derived male/female pair and `CV.TPR.NOMINAL` with it. **Cardiac output now
differs between the sexes by 22%.** Arterial pressure does not differ at all: the
salt-step shift is 5.056918 in men and 5.056912 in women, identical to eight significant
figures.

That is not the accessor failing to reach the component, which is the failure mode this
record warned about. It is the model's central claim: **the renal-body fluid loop sets
arterial pressure, and the heart supplies whatever the kidney demands.** The pair reaches
the answer through the volume side instead —

    dMAP/dV_ecf  scales as  TPR0 * BV0
    men    0.010151 * 5.62 = 0.05705
    women  0.012393 * 4.92 = 0.06097   (+6.9%)

so women reach the same pressure shift on a **6.9% smaller ECF excursion**, and the test
suite now asserts that ratio rather than only asserting that the pressures agree. Before
this pair landed, the sexes were identical in every quantity, because `SV0` was derived
from a shared `CO0` and the dimorphism cancelled arithmetically.

**The lesson for the next pair is that "results move" is the wrong test on its own.** A
correct dimorphic parameter can leave the headline result untouched because the loop is
regulated; what must be asserted is that it moves the quantity the mechanism says it
should. The haematocrit pair is still the outstanding case of the opposite problem: it is
sourced and the model cannot feel it at all, because `f_pv` is derived from it and the two
cancel.
