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

**Default ON.** The buildable claims are E1/E2. The E3 rows contribute no value and
take the structure-only exemption, so nothing here needs to default off.

**`G_pn` is NOT changed by this ADR.** It stays at 20.0. Re-estimating it is the
*consequence* of this work, not part of it, and it must be re-estimated jointly with
the ANP gain against digitised Mars500 as posteriors - not as point values, and not one
at a time. See `HANDOVER.md` section 5 item 4, corrected on this branch: the two gains
are separately identified, so a joint posterior is tractable rather than degenerate.

## Consequences

- **Adds at least one state** (plasma ANP, with a secretion-clearance lag), taking the
  model from 3 states to 4 or more. ADR 0003 (multirate) stays Deferred - still far too
  small to classify the cost regime, and the diagnostic now says so itself.
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
  choice needs its own `form_citation`.
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
