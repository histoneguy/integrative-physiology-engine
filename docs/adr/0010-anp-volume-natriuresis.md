# ADR 0010: ANP - a volume-sensing natriuretic path, built before the slope is re-estimated

**Status:** Proposed
**Date:** 2026-08-21
**Evidence tier:** E1 for the existence, stretch-coupled secretion and natriuretic
action of ANP; E2 for the quantitative human dose-response; E3 for the claim that
volume-keyed rather than pressure-keyed signalling carries physiological natriuresis
(STRUCTURE ONLY - no numeric value; see Evidence).

> **SOURCED 2026-08-21, ONE BLOCKER REMAINS.** Every row that read `[SOURCE REQUIRED]`
> now carries a citation, extracted under the pre-registration in
> `validation/anp_sourcing_prereg.md`. Two things came out of it that change this
> record: a citation inherited from `incoming/Raas.jl` was **misattributed**, and the
> magnitude check **partially falsifies this ADR's own premise**. Both are below. The
> remaining blocker is the INPUT side - nothing sourced connects blood volume or atrial
> stretch to plasma ANP concentration in humans, and that is the link the component
> needs. Status stays Proposed.

> **UPDATED 2026-08-22, THIRD SOURCING — THE SENSED VARIABLE IS FALSIFIED.** See the
> third addendum. Blocker 1 is closed: k=7 primaries pooled, `pooled-geometric` 2.191x,
> and **the review's 2.5-3x range is not supported by its own primaries** (6 of 7 fall
> below it). Blocker 2 is closed **as falsified, not as sourced** — Norsk 1986
> (PMID 3745047) held plasma volume approximately constant across three immersion depths
> while natriuresis graded with depth, so total blood volume does not drive the response.
> The "identical to 2 litres of saline" equivalence this record has been leaning on is a
> claim about **central** volume and cannot be read as a total-volume change. **Immersion
> is therefore the wrong calibration paradigm for a `V_blood`-keyed term**, though the
> model's own salt step is not a redistribution and a `V_blood`-keyed term is not itself
> refuted. Status stays Proposed; the component is further from being written than
> before, which is the correct direction.

## Context

The model has exactly one natriuretic path: the pressure term in `Renal.FR_effective`.
Every gram of sodium regulation is forced through it.

That has now produced a measurable distortion. `RN.PRESSURE_NATRIURESIS.SLOPE` is
calibrated at 20.0 (mEq/day)/mmHg. Mizelle 1993 puts the measured animal value at
2.154e-4 of filtered load per mmHg against the model's 7.937e-4 - **3.68x steeper**.
The gap cannot be corrected in place. Measured on `fix/pressure-natriuresis-slope`:

| `G_pn` | `G_vr` | MAP shift, 205 -> 103 mEq/day | `V_ecf` |
|---|---|---|---|
| 20.0 | 2880 | 4.934 mmHg | 14.174 L |
| 5.43 | 2880 | 15.698 mmHg | 13.331 L |
| 5.43 | 600 | 12.403 mmHg | 9.889 L (below the 10 L floor) |

At steady state excretion equals intake, so `Na_excr = Na_filtered*(1 - FR_Na) +
G_pn*(MAP - MAP_ref)` gives `dMAP ~ d(intake)/G_pn`, in which
`CV.VENOUS_RETURN.SENSITIVITY` does not appear. `G_pn` alone sets salt sensitivity.
Lowering it to the measured value in isolation therefore rebalances nothing - it
forces salt-sensitive-hypertensive behaviour on a normotensive subject.

**The inflated slope is the shape of the missing component.** With no volume-sensing
path, `G_pn` absorbs work that ANP does in the real organism. That is the argument for
building ANP before RAAS: RAAS is antinatriuretic, and adding a second sodium-retaining
arm to a model with one overworked natriuretic arm compounds the distortion instead of
relieving it.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| Servo-controlling renal perfusion pressure during isotonic saline loading does not reduce peak or cumulative natriuresis | E2 | Seeliger E, Andersen JL, Bie P, Reinhardt HW. *J Physiol* 2004;559:939-951 | dog, freely moving - not performable in humans (ethical ceiling, ADR 0006 amended) |
| Renal sodium excretion is regulated primarily by neurohumoral mechanisms keyed to extracellular volume rather than to arterial pressure | E3 - **contested, not species** | Bie P. *Am J Physiol Regul Integr Comp Physiol* 2018;315:R945-R962. `10.1152/ajpregu.00363.2017` | review, mixed |
| Pressure natriuresis contributes to control of total body sodium (balance studies) | E2 | Seeliger E, Safak E, Persson PB, Reinhardt HW. *J Physiol* 2001;537:941-947 | dog |
| ANP is secreted by atrial myocytes in response to atrial wall stretch | E1 | Reviewed in Cardiovascular Research 2005;68(1):8 (mechanisms of ANP secretion from the atrium); StatPearls NBK562257. Wall stretch from increased intravascular volume is the dominant stimulus | mammal incl. human; mechanotransduction detail from rat/rabbit atria |
| ANP increases renal sodium excretion in humans | E1 | Morice A et al. *Clin Sci* 1988;74:359-363, PMID 2965631, `10.1042/cs0740359`; Biollaz J et al. *Hypertension* 1986;8:II96-105, PMID 2941372 | human |
| Quantitative dose-response of infused ANP on sodium excretion | E2 | De Nicola L et al. *J Am Soc Nephrol* 1997;8:445-455, PMID 9071713, `10.1681/asn.v83445` (2/4/8/16 ng/kg/min); Morice 1988 (0.4/2/10 pmol/min/kg) | human |
| ANP accounts for ~40% of the natriuretic increment on shifting low -> normal sodium diet | E2 | De Nicola 1997, PMID 9071713; reviewed in Conte G et al. *Kidney Int Suppl* 1997;59:S28-32, PMID 9185100 | human |
| ANP roughly doubles during mineralocorticoid escape (91.7 -> 179.7 pg/ml, 1.96x) | **E3** - n=4, single study | **Kelly TM, Nelson DH.** *Endocr Res* 1987;13(4):363-383, PMID 2966064, `10.3109/07435808709035463`. **NOT Yokota - see the misattribution note below** | human, n=4 |
| ANP secretion tracks atrial stretch rather than arterial pressure, so it is the volume-keyed arm the model lacks | E3 | inference from the rows above, not a measured claim | - |

**Why the E3 rows are E3.** Not because they are animal-derived. Under ADR 0006 as
amended 2026-08-21, dog data from a preparation no human may undergo is E2 evidence
with its species recorded - and Seeliger's servo-control is exactly that: you cannot
clamp renal perfusion pressure in a conscious person. The two E3 rows are E3 because
they are **contested and interpretive**: Bie 2018 argues a position that runs against
the Guyton formulation this entire model is built on, and the last row is an inference
of mine rather than a measured result. Species has nothing to do with either.

**The E3 rows claim the structure-only exemption: STRUCTURE ONLY - no numeric value.**
They motivate *having* a volume-sensing component. They set no parameter. Every number
entering the component comes from the E1/E2 rows, which are now sourced. The E3 rows
alone would not have licensed building it.

## Decision

Add an `Anp` component sensing cardiac filling and acting on distal tubular sodium
reabsorption, on the same `FR_effective` path aldosterone will use:

    FR_effective ~ clamp(FR_Na - fr_anp - G_pn*(MAP - MAP_ref)/Na_filtered, 0.0, 1.0)

**Sensed variable.** The model is cycle-averaged (ADR 0002) and has no right atrial
pressure state, so atrial wall stretch has no direct representation. `V_blood` in
`Cardiovascular` is the available proxy. **This is a modelling choice, not a
measurement, and must be declared as such in `ledger/relations.csv` with
`class=empirical` and its own `form_citation`** - the relations gate is live and will
fail the build otherwise.

**REVISED 2026-08-22 - no plasma ANP state.** The input-link sourcing (see the second
addendum) found that the natriuretic effect of a given plasma ANP concentration is
**not fixed**: it depends on distal sodium delivery, which IPE does not model. Carrying
an explicit ANP concentration state would therefore add a variable the model cannot use
correctly, plus secretion and clearance constants nobody has measured for this
formulation. The component becomes a **lumped volume-keyed natriuretic term**, algebraic
in `V_blood`, with ANP as its named evidence base rather than as a state. Fewer
unsourced links, no extra state, and it matches what the human studies actually
measure.

**Default ON.** The buildable claims are E1/E2. The E3 rows contribute no value and
take the structure-only exemption, so nothing here needs to default off.

**`G_pn` is NOT changed by this ADR.** It stays at 20.0. Re-estimating it is the
*consequence* of this work, not part of it, and it must be re-estimated jointly with
the ANP gain against digitised Mars500 as posteriors - not as point values, and not one
at a time. See `HANDOVER.md` section 5 item 4, corrected on this branch: the two gains
are separately identified, so a joint posterior is tractable rather than degenerate.

## Consequences

- **Adds NO state** (revised 2026-08-22). The term is algebraic in `V_blood`. The model
  stays at 3 states, so ADR 0003 (multirate) stays Deferred for the same reason as
  before - far too small to classify the cost regime.
- **Makes the `G_pn` re-estimation real work.** Once a second natriuretic path exists,
  the calibrated slope is not merely unsourced, it is over-determined.
- **Blocks nothing for RAAS.** RAAS attaches to the same path via `fr_aldo` and
  `tpr_mod`; `incoming/Raas.jl` is written and parked. Its escape behaviour is
  *expected* to change once ANP lands - that component deliberately carries no escape
  term, because escape emerges from pressure natriuresis alone at the current slope.
- **Creates a double-counting risk that must be watched.** The recovered RAAS work puts
  the model's pressure cost of aldosterone escape at +2.4 mmHg against Hall's observed
  15-19. Adding ANP pushes that cost DOWN while fixing the slope pushes it UP. Do both
  without checking the escape cost in between and the two errors cancel and hide each
  other.

## Falsifiable test

Two, and the first is the one that matters.

**1. Pressure-clamped natriuresis - Seeliger's experiment, in silico.** Hold the
pressure-natriuresis term at its reference value, the model equivalent of
servo-controlling renal perfusion pressure, and step sodium intake. With ANP present,
excretion must still rise and the loop must still close.

**The current model cannot pass this.** With only the pressure term, clamping pressure
abolishes the natriuretic response entirely. That is a clean discriminator: it fails
today and must pass after ANP lands. If it still fails, the component is not carrying
volume-keyed natriuresis regardless of what its parameters say.

**2. The slope must become re-estimable downward.** With ANP on, it must be possible to
reproduce the 205 -> 103 mEq/day salt step at a plausible human sensitivity with `G_pn`
moved materially toward the Mizelle-consistent 5.43 rather than pinned at 20.0.

If adding ANP does *not* permit `G_pn` to fall while the salt step survives, the premise
of this ADR is wrong - the inflated slope is not compensation for a missing volume path,
and the 3.68x gap needs a different explanation. That would be a real finding and should
be recorded, not tuned around.

Note the asymmetry. Test 1 can be run the day the component exists. Test 2 cannot be
settled without digitised Mars500, still outstanding in
`validation/data/manifest.csv`. **Do not treat test 2 as passed on the grounds that
some `G_pn` was found that keeps the suite green** - `test/runtests.jl` pins salt
sensitivity precisely because every other assertion passed at a 3.68x wrong slope.

## What is NOT decided

- **The sensed variable.** `V_blood` is proposed as the atrial-stretch proxy. Whether
  ECF volume, blood volume or a filling-pressure surrogate is right is open, and the
  choice needs its own `form_citation`. **Narrowed 2026-08-22 by the third addendum:
  `V_blood` cannot be calibrated against head-out immersion, because immersion
  redistributes volume centrally at approximately constant total volume and IPE has no
  central compartment. This closes off a paradigm, not the variable — a sodium-loading
  or isotonic-expansion paradigm remains open and is now blocker 4.**
- **Functional form of the ANP effect on reabsorption** - linear, saturating or
  threshold. Unknown until the dose-response row is sourced.
- **Secretion kinetics.** Time constant unsourced. ANP's plasma half-life is short
  against the model's day time base, so whether it needs a state at all or can be
  algebraic is an open question the sourcing should settle.
- **The INPUT link: blood volume or atrial stretch to plasma ANP concentration, in
  humans.** This is now the single blocker on Accepted. Everything sourced below
  describes what ANP DOES once it is in the plasma. Nothing sourced says how much ANP a
  given filling state produces in a human. Without it, `V_blood -> ANP` would be a
  fitted constant - which is exactly how `RN.PRESSURE_NATRIURESIS.SLOPE` got here.
- **NCC downregulation**, the other escape mechanism recorded in the RAAS work, is not
  addressed here and remains absent.

---

## Sourcing outcome, 2026-08-21

Extracted under `validation/anp_sourcing_prereg.md`, which fixed the pooling rules and
stop conditions before any paper was read. Three findings, two of them uncomfortable.

### 1. The Yokota citation was misattributed, and it propagated unverified

`incoming/Raas.jl` attributes PMID 2966064 to **Yokota N et al.** It is
**Kelly TM and Nelson DH**, *Endocrine Research* 1987;13(4):363-383,
`10.3109/07435808709035463`.

The *content* was accurate - 0.3-0.5 mg/day fludrocortisone for 18 days, four healthy
males, sodium intake 180 +/- 2 mEq/day, plasma ANP 91.7 +/- 13.0 -> 179.7 +/- 39.2
pg/ml, urinary sodium down 27% and back to baseline in an average of 5 days. Every one
of those numbers checks out. Only the authors were wrong.

That is worth more than the correction itself. A wrong author on correct data is
invisible to every check in this repo: the ledger validates that a citation *exists*,
not that it points at the right paper. The claim travelled from a chat session into a
component docstring into an ADR without anyone opening it. **Stop condition 3 of the
pre-registration anticipated exactly this**, which is the only reason it was checked.

Re-tiered **E2 -> E3** at the same time: n=4, single study. That is small-n in humans,
which is an ADR 0004-shaped weakness and has nothing to do with species. It is a
validation target rather than a model parameter, so nothing defaults off.

### 2. The dose-response is well sourced, in humans, and it is the effect side only

| Study | Design | Doses | Result |
|---|---|---|---|
| De Nicola 1997, PMID 9071713 | normals + GN + CRF, low-sodium (35 mEq/d) and normal-sodium (235 mEq/d) diets | 2, 4, 8, 16 ng/kg/min | dose-dependent UNaV rise; normals 0.09 +/- 0.02 -> 0.49 +/- 0.11 mEq/min at 16 ng/kg/min. 2-8 ng/kg/min reached *physiological* plasma ANP |
| Morice 1988, PMID 2965631 | 6 fluid-loaded volunteers, double-blind, placebo-controlled | 0.4, 2, 10 pmol/min/kg | UNaV +35%, +98%, +207% vs placebo |
| Biollaz 1986, PMID 2941372 | 8 salt-loaded normals, 4 h | 0.5, 5.0 ug/min | marked natriuresis at the high dose; **inulin clearance unchanged** |

Biollaz's unchanged inulin clearance is the structurally important one: the natriuresis
is **tubular, not filtration-driven**. That is direct support for attaching ANP to
`FR_effective` rather than to `GFR`, which this ADR proposed on general grounds before
the sourcing was done.

**No meta-analysis of the physiological dose-response exists.** The pre-registration's
rule 1 therefore does not fire. The systematic reviews that exist are of ANP as a
*therapeutic* in AKI and heart failure, which is a different question. Under the
declared order this falls to `single-source` per study, with no cross-study pooling
attempted, because the designs are not commensurable: low-sodium-diet normals and
fluid-loaded volunteers are different physiological states, and `pooling.md` prohibits
pooling across incompatible measurement conditions.

### 3. THE PREMISE IS ONLY PARTLY SUPPORTED - record this rather than proceed past it

The pre-registration required a magnitude comparison "whichever way it falls".

De Nicola 1997 reports that **ANP accounts for approximately 40% of the UNaV increment**
evoked by shifting from low to normal sodium diet in humans. If ANP carries ~40% of the
natriuretic response and IPE lacks it entirely, the pressure term must carry the whole
load, inflating it by roughly `1/(1 - 0.40)` = **1.67x**.

The observed inflation of `RN.PRESSURE_NATRIURESIS.SLOPE` against Mizelle 1993 is
**3.68x**.

So ANP plausibly accounts for something under half of the discrepancy - on a log basis
`ln(1.67)/ln(3.68)` is about **0.39**. **A residual factor of roughly 2.2x is not
explained by the missing ANP path.**

This ADR's Context asserts that the inflated slope *is* the shape of the missing
component. On the sourced numbers that is an overstatement. ANP is a real and
substantial contributor and building it remains justified - but something else is also
wrong, and adding ANP while assuming it will absorb the whole 3.68x would push the
slope down too far and hide the remainder.

Candidates for the residual, none investigated: NCC downregulation (absent, and
recorded in `incoming/Raas.jl` as a second escape route); renal sympathetic nerves
(absent); the dog-to-human filtered-load scaling itself; or the possibility that the
calibration target the slope was fitted to was never right. **Do not attribute the
residual to any of these without doing the work.**

Caveat on the comparison: De Nicola's 40% is for a 35 -> 235 mEq/day shift, wider than
the model's 103 -> 205 mEq/day step, and fractional contributions need not be constant
across that range. The 1.67x is an order-of-magnitude argument, not an estimate.
---

## Second sourcing outcome, 2026-08-22: the INPUT link

Extracted under `validation/anp_input_link_prereg.md`. Every citation below was fetched
and its author list, journal and year verified against the record, per stop condition 3
- which exists because PMID 2966064 carried the wrong authors for two sessions.

### The link is sourceable in humans, but only to an order of magnitude

Head-out water immersion is the human volume-perturbation model, and it is well
characterised.

| Source | Design | Finding |
|---|---|---|
| Vesely DL, Norsk P, Winters CJ, Rico DM, Sallman AL, Epstein M. *Proc Soc Exp Biol Med* 1989;192:230-235, PMID 2532366, `10.3181/00379727-192-42990` | 7 seated sodium-replete normals, 3 h neck immersion | NI gives "acute central volume expansion **identical to that produced by 2 liters of saline** but without plasma compositional change". ANF C-terminus and N-terminus both rose promptly, peaking at 1 h |
| Epstein M, Norsk P, Loutzenhiser R. *Am J Nephrol* 1989;9:1-24, PMID 2524162, `10.1159/000167929` - **review** | synthesis of the immersion literature | ANP rises during the 1st hour, "**rising 2.5- to 3-fold** by the end of the 2nd or 3rd h"; returns promptly on recovery |

So the order of magnitude is roughly **2.5-3x plasma ANP for a central volume expansion
equivalent to 2 L of saline**.

**That is not yet a usable gain, and the declared rules are why.** Epstein 1989 is a
review reporting a *range across studies*. `pooling.md` prohibits `range-midpoint` for
new entries: taking 2.75x would use two numbers and discard every other study. The rule
requires going to the k primary papers and pooling their point estimates. **That work is
not done here.** This sources the FORM and the magnitude, not the number.

**A second caveat the sources do not resolve.** Immersion produces *central* volume
expansion by translocating blood from the periphery, not by adding it. IPE's `V_blood`
is total blood volume. Mapping one to the other needs an assumption none of these papers
supplies.

### The finding that matters: ANP-only is contradicted, in humans, with an isolation design

**Rabelink TJ, Koomans HA, Boer P, Gaillard CA, Dorhout Mees EJ.** *Am J Physiol*
1989;257:F375-82, PMID 2528914, `10.1152/ajprenal.1989.257.3.f375`. Seven healthy
subjects on 100 mmol sodium, 3 h immersion compared against a **deliberately
natriuresis-matched** ANP infusion, both repeated under enalapril.

> "HOI caused a natriuresis equal to that of ANP infusion despite an **about five times
> smaller rise in plasma ANP**."

Immersion *increased* renal plasma flow and *decreased* fractional lithium reabsorption
- a proximal reabsorption marker. ANP infusion did neither. The authors conclude the
data "speak against an exclusive role" for ANP, and Epstein's review says the same
independently: it is "simplistic to consider the WI-induced augmentation of ANP to be
the sole, or even the prepotent, mediator".

### A conflict between sources, recorded rather than averaged

Stop condition 4 required this be reported as a conflict.

| Source | Species | ANP's share of volume-expansion natriuresis |
|---|---|---|
| De Nicola 1997, PMID 9071713 | human | ~40% of the UNaV increment, low to normal sodium diet |
| Schwab TR, Edwards BS, Heublein DM, Burnett JC. *Am J Physiol* 1986;251:R310-3, PMID 2943167, `10.1152/ajpregu.1986.251.2.r310` | **rat**, anaesthetised, SHAM n=6 vs right atrial appendectomy n=12, isoncotic albumin | ~50%: delta UNaV 9.48 +/- 1.01 to 4.77 +/- 1.03 ueq/min |
| Rabelink 1989, PMID 2528914 | human | matched natriuresis at **one fifth** the ANP rise |

The first two agree at 40-50%. The third appears to contradict them. **The reading that
reconciles all three, and it has a modelling consequence:** ANP may well be necessary
for 40-50% of the response while volume expansion *simultaneously* raises distal sodium
delivery, making a given ANP concentration far more effective. Rabelink's own lithium
and ERPF data say exactly that.

Note Schwab is rat with atrial appendectomy - not performable in humans, so legitimate
E2 under ADR 0006 as amended. It is recorded as a comparator and **not pooled** with the
human values.

### Consequence: this is why the component carries no ANP state

**IPE has no proximal/distal partition.** `FR_effective` is a single lumped fractional
reabsorption. The model therefore *cannot represent* the mechanism by which immersion
achieves full natriuresis at one fifth the ANP.

Building a mechanistic ANP-concentration pathway into that structure would be precision
the surrounding model cannot support: a sourced concentration driving an effect whose
true gain varies with a variable the model does not have. The Decision above is revised
accordingly - a **lumped volume-keyed natriuretic term**, algebraic in `V_blood`, whose
magnitude is calibrated against volume-expansion natriuresis *as a whole* (the 40-50%
figure) rather than against a plasma concentration.

That is a weaker claim than the original ADR made, and it is the one the evidence
supports.

### Still blocking Accepted

1. **The k primary immersion papers behind Epstein's 2.5-3x** must be pooled properly
   under `pooling.md`. Until then there is no number, only a magnitude.
2. **The central-to-total blood volume mapping** is unsourced.
3. The **2.2x residual** from the first sourcing outcome is untouched by any of this.
   Nothing found here should be used to re-attribute it. If anything, Rabelink's
   delivery effect is a *candidate* for part of that residual - IPE forces through
   `FR_effective` what the real kidney also does by changing delivery - but that is a
   hypothesis, not a finding, and it needs its own work.

---

## Third sourcing outcome, 2026-08-22: the pooling, and a falsified sensed variable

Extracted under `validation/immersion_pooling_prereg.md`, written and **committed before
any paper was opened** (`49c2165`). Computation is reproducible: `python
validation/immersion_pool.py`. Every citation below was fetched from the PubMed record
and its author list, journal, year, volume and pages verified, per stop condition 2.

**Blocker 1 closes on the letter and fails on the substance. Blocker 2 does not close,
and the reason it does not close falsifies this ADR's sensed variable.**

### 0. The blocker list contained a quantity the component does not use

The 2026-08-22 revision dropped the ANP state — the component became a lumped
volume-keyed natriuretic term algebraic in `V_blood`, calibrated against
volume-expansion natriuresis rather than against a plasma concentration. In the same
addendum, blocker 1 asked for the primaries behind Epstein's 2.5-3x to be pooled. But
that range is the **plasma ANP fold-rise**, and under the revised design no state carries
it and nothing multiplies it.

Pooling it would have produced a correctly-sourced number the component does not use,
which is worse than an unsourced one because it looks finished. The pre-registration
therefore extracted **both** the ANP fold-rise (Q1, closing blocker 1 as written and
auditing the review against its own primaries) and the natriuretic response (Q2, the
quantity the component needs), from the same papers.

### 1. Q1 — the primaries do NOT support the review's range

Sampling frame: primaries at or before 1989, i.e. those Epstein 1989 could have been
summarising. Endpoint fixed in advance at 180 min of immersion over the same subjects'
pre-immersion baseline, with per-paper peaks recorded but **not** pooled — per-paper
maxima would bias every estimate upward, which is the defect being tested for.

| Study | PMID | n | Duration | ANP fold-rise |
|---|---|---|---|---|
| Epstein M, Loutzenhiser R, Friedland E, Aceto RM, Camargo MJ, Atlas SA. *J Clin Invest* 1987;79:738-745, `10.1172/JCI112879` | 2950133 | 13 | 3 h | **2.487** (7.8+/-1.8 -> 19.4+/-3.8 fmol/ml) |
| Anderson JV, Millar ND, O'Hare JP, Mackenzie JC, Corrall RJ, Bloom SR. *Clin Sci* 1986;71:319-322, `10.1042/cs0710319` | 2944688 | n/s | n/s | **2.00** ("twofold") |
| Pendergast DR, de Bold AJ, Pazik M, Hong SK. *Proc Soc Exp Biol Med* 1987;184:429-435, `10.3181/00379727-184-42497` | 2951741 | 6 | 3 h | **1.50** (~80 -> ~120 pg/ml) |
| Ogihara T, Shima J, Hara H, Tabuchi Y, Hashizume K, Kumahara Y, Kangawa K, Matsuo H. *Jpn Heart J* 1987;28:41-51, `10.1536/ihj.28.41` | 2955141 | 7 | 1 h | **1.593** (246+/-12 -> 392+/-32 pg/ml) |
| Miki K, Shiraki K, Sagawa S, de Bold AJ, Hong SK. *Am J Physiol* 1988;254:R235-R241 | 2964206 | 6 | 3 h | **2.00** (maintained across the 3 h) |
| Tajima F, Sagawa S, Iwamoto J, Miki K, Claybaugh JR, Shiraki K. *Am J Physiol* 1988;254:R977-R983 | 2968055 | 8 (young arm) | 3 h | **3.00** |
| Gerbes AL, Vollmar AM. *Biochem Biophys Res Commun* 1988;156:228-232 | 2972285 | 9 | 1 h | **2.417** (C-terminal, 4.8+/-0.5 -> 11.6+/-2.3 fmol/ml) |

**k = 7 independent studies. `pooled-geometric` per `pooling.md` rule 4 (ratio
quantity), computed in log space: 2.191x n-weighted, 2.087x unweighted, geometric SD
1.282, range of contributing estimates 1.50-3.00.**

**Epstein 1989 reports "rising 2.5- to 3-fold by the end of the 2nd or 3rd h". Six of
the seven primaries fall below 2.5x. Only one lands inside the review's range.**

`pooling.md` is explicit that when a heavily-cited review and its own primaries
disagree, **the primary source wins and the divergence is logged**. It is logged here.
The likely mechanism is the one the pre-registration was written to defend against: a
review quoting per-study peak values, and drawing on the hydrated-subject studies, where
the fixed common endpoint gives a materially lower number. `range-midpoint` was
prohibited in advance and **2.75x is not recorded anywhere**.

Excluded, each on a criterion declared before extraction:

- **Patient populations** — the Kokot series (renal failure, transplant, diabetic),
  Skorecki 1988, Campbell 1988, Legault 1993, Vesely 1991 (cirrhotic), Doniec-Ulman 1987
  (gestosis), Hwang 1991 (nephrotic), Wiecek 1991 and Coruzzi 1993 (hypertensive),
  Tajima 1990 (quadriplegic), Rabelink 1993 and al-Haidary 1990 (transplant).
- **Species** — Miki 1986, Sondeen 1990, Krasney 1991 (dog).
- **Protocol** — Viti 1989 (PMID 2534120): 20 min, 28 C water, horizontal. Fails
  duration, thermoneutrality and head-out on three separate declared criteria. Wolf 1990
  (PMID 2149337): 20 min, below the 60 min minimum.
- **Cohort overlap**, per the independence rule declared in advance — Epstein 1986
  (PMID 2941549, 4 subjects) against Epstein 1987 (13 subjects), same authors, same
  institution, same protocol; Ogihara 1986 (PMID 2941635, 5 men, 1 h) against Ogihara
  1987 (7 men, 1 h); Gerbes 1986 (PMID 2945039) against Gerbes 1988. In each case the
  more complete report was taken and the other recorded as excluded-for-overlap.
- **Not extractable** — Vesely 1989 (PMID 2532366) reports timing but no ANP values, and
  additionally shares Epstein as senior author with a 7-subject "seated sodium-replete
  normal" cohort against Epstein 1987's 13, so it fails independence as well. Rabelink
  1989 (PMID 2528914) reports only that the immersion ANP rise was about five times
  smaller than the matched infusion — no baseline-referenced fold-change.
- **Different analyte, not pooled** — Gerbes 1988's N-terminal proANF fragment rose
  1.625x in the same subjects whose C-terminal ANP rose 2.417x. That single paper
  demonstrates why `pooling.md` forbids mixing assays: the two numbers describe the same
  event and differ by 49%.

**One independence judgement is recorded rather than hidden.** Miki 1988 and Tajima 1988
come from the same laboratory (Shiraki, Sagawa, Miki), the same journal and volume, and
the same 3 h / 34.5 C hydropenic protocol. They were counted as **independent** because
n differs (6 vs 8) and the subject-selection criteria differ (a day-night comparison
versus young-versus-elderly). This is the least secure call in the set, and it matters:
Tajima's young arm is the single highest estimate, so collapsing the two would move the
pooled value further below the review's range, not toward it.

### 2. Q2 — BLOCKED at k = 2, and the stop condition is honoured

Extractable UNaV fold-changes against the same subjects' control: Epstein 1987, 2.076
(92+/-12 -> 191+/-15 ueq/min); Anderson 1986, 2.00 ("a doubling"). Pendergast 1987
reports **fractional** excretion (1.0 -> 1.8%), a different measurement, and
`pooling.md` prohibits pooling across incompatible measurement methods, so it is
recorded and not pooled.

**k = 2. The pre-registration required k >= 3 before any parameter is recorded. No
ledger row is created.** Two studies do not become a pooled value; they become
`single-source` twice over. The geometric mean of the two is 2.038 and it is written
here only so that nobody re-derives it later and mistakes it for an adopted value.

**And it would not have mattered if k had been 3**, for the reason in the next section:
without Q3 there is nothing to divide by.

### 3. Q3 — THE SENSED VARIABLE IS FALSIFIED, NOT MERELY UNSOURCED

The pre-registration declared that Q3 could sink this, that no fallback would be
declared for it, and (§8) that if the immersion natriuresis tracked central
redistribution rather than a volume the model can compute, then **`V_blood` is the wrong
sensed variable and this ADR's Decision is wrong on its input side**.

That is what the evidence says. Three independent human studies, none of them
previously read into this repo:

| Source | Design | Result |
|---|---|---|
| **Norsk P, Bonde-Petersen F, Warberg J.** *J Appl Physiol* 1986;61:565-574, PMID 3745047, `10.1152/jappl.1986.61.2.565` | 10 normal males, **graded** immersion to umbilicus, chest and neck, 34.5 C, 4 h | Cardiac output, stroke volume and **plasma volume increased to approximately the same level at all three depths**, while CVP rose only at chest and neck, and **diuresis and natriuresis increased gradually with depth** |
| **Greenleaf JE, Shvartz E, Kravik S, Keil IC.** *J Appl Physiol Respir Environ Exerc Physiol* 1980;48:79-88, PMID 6986349, `10.1152/jappl.1980.48.1.79` | 4 men, 8 h immersion at 34.4 C vs chair rest | Immersion **plasma volume loss of 12.6%** (0.43 L) with ECV down 2,230 ml/8 h, while natriuresis and diuresis were sustained |
| **Simanonok KE, Bernauer E.** *Aviat Space Environ Med* 1993;64:139-145, PMID 8431188 | 6 healthy men, bled **15% of total blood volume** before 7 h seated immersion, own controls | Cardiac output returned to dry-control level, but sodium excretion was still **+120%** above dry control (vs +200% unbled) |

**Norsk 1986 is the decisive one.** It is a graded-dose human experiment in which the
model's candidate sensed variable is held approximately constant while the response
varies monotonically. Plasma volume was the same at all three immersion depths; the
natriuresis was not. Whatever grades the response, it is not total intravascular volume.
Greenleaf shows total volume moving *downward* while the response persists, and
Simanonok shows the response largely surviving a deliberate 15% reduction in total blood
volume.

**The mapping ADR 0010 needed does not merely lack a source — it is contradicted.**

**And this exposes an inference this ADR was already resting on.** Epstein 1986 and
Vesely 1989 both state that immersion provides a volume stimulus "identical to that
produced by 2 liters of saline". That equivalence, quoted approvingly in the second
sourcing outcome, is a claim about the **central** stimulus. It has been read here as
though it licensed a **total** volume change of 2 L. It does not, and Norsk 1986 is the
direct evidence that it does not. That step was the unsourced scaling all along; the
search for a "central-to-total mapping" was looking for a source for an inference the
literature contradicts.

### 4. Consequence: immersion is the wrong calibration paradigm for this component

This is narrower than "ANP cannot be modelled here", and the distinction matters.

IPE is cycle-averaged (ADR 0002) with a single blood volume and no central compartment,
so it cannot represent a redistribution at constant total volume. Head-out immersion is
**precisely** a redistribution at approximately constant total volume. The paradigm and
the model variable are mismatched, and no amount of further immersion sourcing fixes it.

But the perturbation the model actually runs — a sodium intake step — is **not** a
redistribution. It genuinely changes ECF and total blood volume. So a `V_blood`-keyed
natriuretic term is not thereby refuted; what is refuted is calibrating it against
immersion.

**The already-sourced anchor is the right one.** De Nicola 1997 (PMID 9071713) puts ANP
at ~40% of the natriuretic increment for a **sodium diet shift**, 35 -> 235 mEq/day —
a total-volume perturbation of the same kind as the model's own salt step, and the
figure the revised Decision named as the calibration target. Ogihara 1987 additionally
provides a quantified total-volume perturbation in the same paper as its immersion arm
(1 L saline over 1 h raised hANP to a peak of 305+/-30 pg/ml from 246+/-12, 1.24x; 1 L
over 2 h, 285+/-25, 1.16x), and is a lead for that paradigm rather than this one. k = 1;
it sets no parameter.

### 5. Status

**Stays Proposed.** No `Anp` component is written, no ledger row is added, and no
parameter is recorded. Revised blocker list:

1. ~~Pool the k primary immersion papers behind Epstein's 2.5-3x.~~ **Done.** k = 7,
   `pooled-geometric` 2.191x n-weighted. The review's range is not supported by its
   primaries and the divergence is logged. **The number is not a model parameter** and
   closing this blocker does not advance the component.
2. ~~Source the central-to-total blood volume mapping.~~ **Closed as falsified, not as
   sourced.** Total blood volume does not grade the immersion response. `V_blood` is not
   defensible as the sensed variable for an immersion-calibrated term, and the "2 L of
   saline" equivalence cannot be read as a total-volume change.
3. **The 2.2x residual** — not re-attributed, as declared, but **audited**: see section
   6 below. The figure is not a 2.2x-shaped fact. Nothing found in the immersion search
   was used to re-attribute it. Note separately that Rabelink's distal-delivery effect
   and Norsk's redistribution finding are the *same* mechanism seen from two directions,
   which strengthens it as a *candidate* for part of whatever residual survives the
   audit. It remains a hypothesis and needs its own pre-registered work.
4. **NEW — re-source the input link against a total-volume paradigm.** Sodium loading or
   isotonic saline expansion with quantified volume and measured natriuresis, not
   immersion. Until then the component's input has no defensible calibration.

**What this costs.** The `Anp` component is further from being written than it was this
morning, and that is the correct direction: the previous position rested on a mapping
that is contradicted rather than merely missing. Falsifiable test 1 in this ADR
(pressure-clamped natriuresis, Seeliger's experiment in silico) is unaffected and remains
the discriminator the day a component exists.

### 6. Blocker 3 — the 2.2x residual is not a 2.2x-shaped fact

Audited on the same day, reproducibly: `python validation/residual_audit.py`. **No
literature was extracted for this** — it is arithmetic on numbers already in the repo,
plus one verification of a citation the ledger has already adopted. Nothing here is
recorded as a parameter.

The audit reproduces both published figures exactly (3.6843 against the quoted 3.68x,
2.2106 against the quoted ~2.2x), which confirms the derivation was correctly
identified before it was taken apart. It then finds that the 3.68x rests on two choices
that are not measurements, plus one bias that was never in the comparison at all.

**(a) The dog GFR is uncited, and the ratio is exactly proportional to it.** The
comparison is between *fractions of filtered load*, so the dog's filtered load enters as
`GFR_dog x C_Na`. `validation/pn_data.py` supplies `DOG_GFR = 115.0` L/day from a
parenthetical — "dog ~20 kg, GFR ~115 L/day" — with no citation and no source in
Mizelle. The relation is `inflation = 0.03204 x GFR_dog(L/day)`. The assumed value
corresponds to 3.99 mL/min/kg, at the **top** of the conventional canine range of
2.5-4.5 mL/min/kg. Across that range the inflation is 2.31-4.15x and the residual after
ANP is **1.38-2.49x**.

**(b) Mizelle's own three points disagree with each other by 2.28x.** The adopted slope
(1.734 mmol/day/mmHg per kidney, from the two simultaneous 12-day kidneys) is one of
three defensible readings: the low segment gives 1.280, the high segment 2.917. Those
imply inflations of 4.99x, 3.68x and 2.19x respectively, i.e. residuals of 3.00x, 2.21x
and 1.31x. `pn_data.py` already flags the segment disagreement as "suggestive of
steepening, NOT evidence of it" — but the ADR then quotes the value derived from one
reading as though the disagreement had been resolved.

Propagating (a) and (b) together, **the residual is 0.82-3.37x, not 2.2x.** At the
favourable corner ANP accounts for the entire discrepancy and there is nothing left to
explain. This does *not* show the residual is zero: holding the adopted slope, it would
take a canine GFR of 52 L/day (1.81 mL/min/kg) to erase it, which is below the plausible
range. Something is probably there. Its size is simply not known to be 2.2x.

**(c) A bias the comparison never accounted for, and it points the wrong way.**
Mizelle's abstract, verified against the PubMed record on 2026-08-22 (PMID 8319986,
`10.1161/01.hyp.22.1.102`, **Mizelle HL, Montani JP, Hester RL, Didlake RH, Hall JE**,
*Hypertension* 1993;22:102-110 — all three RPP/UNaV points in `pn_data.py` reproduce
exactly, so the transcription is sound), states:

> "in the low-pressure kidney, glomerular filtration rate was slightly but significantly
> lower (approximately 8%) than in the contralateral kidney"

**The filtered load was not constant between the two kidneys, and the comparison assumes
it was.** IPE's `G_pn` is a slope at *constant* filtered load — `Na_excr =
Na_filtered*(1 - FR_Na) + G_pn*(MAP - MAP_ref)`, with GFR flat over 80-160 mmHg — so the
model's parameter contains no filtered-load term, while Mizelle's raw between-kidney
`dUNaV/dRPP` does. Removing it drops the dog's pressure-only slope from 1.734 to 1.480
per kidney and moves the inflation **3.68x -> 4.32x**, the residual **2.21x -> 2.59x**.

Unlike (a) and (b) this is a bias rather than an uncertainty, and it makes the model look
*more* inflated, not less. It has been sitting in the comparison in the favourable
direction.

**What this changes about the next step.** The handover lists five uninvestigated
candidates for the residual — NCC downregulation, renal sympathetic nerves, the
dog-to-human scaling, the calibration target, and the distal-delivery effect — and warns
against attributing the residual to any of them without doing the work. That warning
stands. But the cheapest way to sharpen the residual is none of the five: it is to
**open Mizelle 1993 in full text and read the body weights and absolute GFRs actually
reported**, which collapses (a) outright, and to recover enough of the dataset to settle
(b). Only then is a mechanistic hunt worth starting. Two of the five candidates — the
dog-to-human scaling, and the calibration target — are partly *this* problem rather than
physiology.

Blocker 3 therefore stays open, but it is now a **specific, cheap, bounded task** rather
than an open-ended mechanistic search. The 2.2x figure should not be quoted as a
quantity anywhere until it is redone; `HANDOVER.md` section 3.2 and the Context section
of this ADR both currently state it without uncertainty.
