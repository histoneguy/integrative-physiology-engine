# ADR 0021: Distal sodium delivery, macula densa control of renin, and potassium

**Status:** Accepted, **amended the same day — read the amendment before the decisions**
**Date:** 2026-09-05
**Evidence tier:** E1 for macula densa inhibition of renin by distal NaCl delivery, for
potassium stimulation of aldosterone, and for aldosterone-driven distal potassium
secretion; E2 for every quantitative gain, all of which are measured in humans but by
perturbations that move several things at once.

## Context

**These are one record because aldosterone is one node.** The owner's instruction was to
build them together and the physiology is why: renin sets aldosterone, **and so does
plasma potassium, directly and independently**; aldosterone then drives distal sodium
reabsorption — which the model already has — **and distal potassium secretion**, which it
does not. Build either alone and aldosterone is being driven by half its inputs while
doing half its job.

**The model records the sodium half as its largest structural gap.** `HANDOVER.md` §7:

> *THE RENIN CONTROL IS PRESSURE-ONLY AND HUMANS ARE NOT. The rectified form caps the PRA
> ratio it can produce between two pressures at the ratio of their drives, whatever the
> gain. Between MAP 88 and 86 that ceiling is **1.40**; van den Bosch measures **2.73**
> across sodium intake in the same subjects. **No value of the gain reproduces it**, and
> the missing inputs are macula densa sodium delivery and renal sympathetic traffic.*

**And the potassium half is an absence nobody has to be told about.** The model reports
plasma sodium, osmolality, urine osmolality and now arterial pH, and cannot say what the
potassium is. Aldosterone's principal physiological job is potassium excretion.

**ADR 0020 said this would happen:** *"It makes the model's silence about potassium
louder, because acidosis shifts potassium out of cells and the model has no potassium at
all."*

## Evidence

| Claim | Tier | Basis | Species |
|---|---|---|---|
| Renin release is inhibited by NaCl delivery to the macula densa, independently of perfusion pressure | E1 | Multiply replicated; the basis of the juxtaglomerular apparatus | human, mammal |
| Plasma potassium stimulates aldosterone secretion directly, independently of renin | E1 | Multiply replicated; the reason adrenal insufficiency presents with hyperkalaemia | human |
| Aldosterone increases distal nephron potassium secretion | E1 | Multiply replicated | human |
| Distal potassium secretion also rises with distal tubular flow | E1 | Multiply replicated | human, mammal |
| About 98% of body potassium is intracellular, so the extracellular pool is small and turns over fast | E1 | Isotope dilution | human |
| Most of a potassium load is excreted within a day, with plasma potassium moving little | E1 | Balance studies | human |

**Numbers deferred to `validation/macula_densa_potassium_prereg.md`.** None opened yet.

**Same constraint as ADR 0018, 0019 and 0020:** primary experimental literature and
published mathematical relationships only; no other whole-body model, for structure or
for values.

## Decision

**1. Tubular sodium reabsorption is split into a PROXIMAL-plus-loop segment and a DISTAL
segment, and the split is NEUTRAL BY CONSTRUCTION.**

This is the enabling change and it is deliberately inert. The reference individual's
fractional reabsorption is unchanged, and the *total* effect of every existing modulator
is unchanged, because the distal increment is defined so that its contribution to the
whole-nephron fraction is exactly what the lumped increment was.

**Its only purpose is to make two things exist**: distal NaCl delivery, which the macula
densa senses, and a distal segment, which is where potassium is secreted.

**The sites are assigned by physiology, not by convenience:** pressure natriuresis and the
natriuretic peptide term act on the PROXIMAL segment, aldosterone on the DISTAL. That is
what makes distal delivery rise on a high-salt diet — proximal reabsorption falls — and it
is the whole mechanism this record exists to add.

**WHAT THIS DOES NOT DO IS RE-ESTIMATE ANYTHING.** `RN.PRESSURE_NATRIURESIS.SLOPE`,
`CV.ANP.NATRIURETIC_GAIN` and the RAAS tubular gain keep their values and their meanings.
A split that changed them would invalidate the estimation chain that ADR 0016 sequenced,
and one change at a time is how this repository stays testable.

**2. Renin is inhibited by distal NaCl delivery, and the pressure arm is untouched.**

The existing rectified pressure relation stays exactly as it is. The macula densa term is
added alongside it, which is what lifts the ceiling §7 records: a form whose PRA ratio
between two pressures is capped at the ratio of their drives can exceed that cap once a
second input moves.

**3. Potassium is ONE state: extracellular potassium content.** Plasma potassium is that
over extracellular volume. The intracellular pool is ~50 times larger and is represented
as a *buffer*, not a compartment — one state, not two, and the lumping is recorded below.

**4. Aldosterone is driven by BOTH renin and plasma potassium.** This is the join, and it
is the reason the two halves are one record. The existing renin-driven power law is kept
and a potassium term is added multiplicatively.

**5. Renal potassium excretion rises with aldosterone, with distal flow, and with plasma
potassium.** All three are E1. The distal flow term is why the split in decision 1 is
load-bearing for potassium as well as for renin.

**6. NO potassium effect on anything but aldosterone.** No membrane potential, no cardiac
rhythm, no insulin- or catecholamine-driven transcellular shift, and no acid–base
coupling — ADR 0020's pH exists and will not move potassium, nor potassium pH. Every one
of those is real and each would be its own record.

**7. Renal sympathetic traffic is STILL ABSENT** and §7 names it alongside the macula
densa. This record adds one of the two missing inputs, not both, and the salt–renin
comparison must be read knowing that.

**8. Not sexed** unless the extraction supports a pair. ADR 0014.

## Consequences

- **One new component, one new state.** The eleventh and the tenth.
- **The largest recorded structural gap is half closed**, and the half that is closed is
  the one that can be tested against human salt–renin data.
- **Aldosterone stops being a pure function of pressure.** Everything downstream of it —
  distal sodium reabsorption, and now potassium — inherits a potassium input.
- **It opens the anion gap**, which ADR 0020 also opened and neither takes: with sodium,
  potassium, chloride and bicarbonate the gap would be computable, and chloride is the
  only one still missing.
- **It makes a diuretic representable in principle** — a distal segment is where thiazides
  and potassium-sparing agents act — and none is built.
- **It does NOT open the renin-angiotensin vasoconstrictor path**, which ADR 0006's build
  order and `Raas.jl`'s own deliberate omission both keep out.

## What this lumping disqualifies as evidence

**One extracellular potassium pool with the intracellular space as a buffer** removes
every transcellular shift: insulin, beta-agonists, acidosis, exercise, and the
hyperkalaemia of cell lysis. The model cannot be calibrated against anything whose
perturbed variable is the DISTRIBUTION of potassium rather than its balance — which is
most of acute hyperkalaemia.

**A neutral proximal-distal split** carries no independent evidence about segmental
handling. It cannot be used to argue about lithium clearance, about the site of action of
a diuretic, or about proximal versus distal sodium avidity, because the split reproduces
the lumped model exactly by construction and therefore contains no new information about
where anything happens.

**No renal sympathetic traffic** means the salt–renin response, even once this lands, is
being produced by two of the three known inputs.

**Still usable:** the steady-state relationship between sodium intake, renin, aldosterone
and potassium excretion; plasma potassium in health; and the direction and rough size of
the response to a potassium load.

## Falsifiable test

1. **The salt–renin response must reach the human range.** **AND THIS IS AN ESTIMATION
   SET, NOT A VALIDATION, AND IT IS SAID HERE BEFORE THE FACT.** The macula densa gain
   has no independent human measurement that could be found, so it will be estimated
   against exactly these data. §3.15 records what happens when an estimation set is
   quoted back as agreement; this record forecloses it in advance. What IS a test is that
   the *form* can exceed the ceiling at all — a pressure-only model cannot, at any gain.
2. **Plasma potassium must land in the human reference range** with nothing set to put it
   there. Intake, the secretion relation and extracellular volume are sourced separately;
   the concentration follows. **This one can fail.**
3. **A potassium load must raise aldosterone and raise potassium excretion, with plasma
   potassium rising only slightly.** The physiology that makes the extracellular pool
   survivable, and the property most easily got wrong by a model with one pool.
4. **A low-salt diet must raise renin AND aldosterone**, and aldosterone must rise
   proportionally less than renin, because the existing power law is compressive.
5. **The split must be exactly neutral.** With the macula densa and potassium arms
   disabled, every existing result must be **bit-identical** — not close. That is the
   assertion that decision 1 did what it claims.

## Amendment, 2026-09-05: three decisions changed, and one falsifiable test did its job

**Written and implemented the same day. Decisions 1, 3 and 5 all moved, and the suite
refuted a form before it was ever committed.**

### A1. Decision 1's split is OBSERVATIONAL, which is stronger than it promised

It said the split would be neutral by construction. **It is neutral by not existing.**
Distal delivery is DEFINED as a new variable and the sodium equation is untouched, so
bit-identity is guaranteed rather than checked. The consequence the disqualification
section already stated stands and is sharper: the model contains **no** information about
segmental handling, because nothing about segments was added.

### A2. Decision 3's potassium state is PLASMA concentration, and the resting value is an INPUT

The outflow's *shape* is sourced and its *level* is not, a case branch P4 did not
anticipate.

**This amendment originally said renal potassium clearance in healthy adults could not be
sourced. THAT WAS FALSE and it is retracted** — see amendment A7. What is true is
narrower: no admissible study reports this model's own composite (intake, plasma potassium
and glomerular filtration in the same healthy subjects), so the level is derived.

**So the dependency is inverted for the fourth time in this model** — after arterial PCO2,
the thyroid operating point and plasma bicarbonate — and **falsifiable test 2 is VOID.**
The pattern is now the rule: *where a concentration is measured in thousands of people and
its clearance is measured in nobody healthy, the concentration is the input.*

### A3. DECISION 5 IS AMENDED AND THE SUITE IS WHY

It required excretion to rise with aldosterone, with distal flow and with plasma
potassium. **Every human study found moves all three together**, so no gain separates from
the others — and the first implementation therefore made excretion LINEAR in plasma
potassium alone.

**Falsifiable test 3 killed that on its first run.** Linear excretion makes the
steady-state concentration *proportional* to intake: doubling an ordinary diet gave
**7.6 mmol/L**, a lethal hyperkalaemia from a dietary variation.

The fix is one exponent, `K.EXCRETION_EXPONENT` = 17.7, fitted to Brunner's measured
plasma-potassium response to intake across a fortyfold range. **It LUMPS all three
mechanisms**, which means aldosterone's effect on potassium is *inside* that number rather
than absent from the model — and that the model cannot tell a spironolactone from a
potassium load, which the disqualification section now says.

**This is the clearest case in the repository of a falsifiable test earning its keep.** It
was written before the implementation, it named the property most easily got wrong, and it
caught the wrong form before a single commit.

### A4. What test 1 turned out to be worth

The macula densa gain is estimated against the salt–renin data, as declared. **What the
run shows is the structural claim, not the fit:** with the arm off, the renin ratio between
38 and 230 mmol/day of sodium is **1.14**; with it on, **2.73**. §7's ceiling is confirmed
by measurement rather than by argument, and exceeded.

### A5. The join is real and chronically MUTE

Potassium reaches aldosterone; aldosterone reaches distal sodium reabsorption. **And ADR
0010's escape drives that effect to zero at every steady state** — doubling dietary
potassium moves arterial pressure by less than one part in 10^12. Asserted, because the
coupling graph would suggest the opposite. **Aldosterone in this model is chronically a
reporter, not an effector**, and that is a fact about the escape structure rather than
about potassium.

## Amendment A6, 2026-09-05: the acute saline challenge refuted the first form and now bounds the second

**Written after the challenge harness was run, which is the only reason any of it is
known.** The suite passed 676 tests with the wrong form in place.

### A6.1 The pressure and natriuretic-peptide terms were a double count

Decision 1 assigned pressure natriuresis and the natriuretic peptide to the proximal
segment, so the first implementation put both into distal delivery. Run against Lobo's
two-litre saline challenge that gave **877 mL and 148 mmol over six hours against 563 and
95**, with modelled renin driven onto its zero floor by an ordinary clinical infusion.

**The argument against it is a priori and the run is only how it was noticed.**
`RN.PRESSURE_NATRIURESIS.SLOPE` and `CV.ANP.NATRIURETIC_GAIN` are calibrated *against
sodium excretion* — the chronic salt step and Lobo's own six-hour time course. The macula
densa arm returns to sodium excretion through renin, aldosterone and `fr_mod`. Putting
either gain into the signal counts the same measurement twice, and **decision 1 forbids
changing what those two rows mean.** The pressure term double-counts twice over: MAP
already reaches renin through the rectified arm decision 2 promised to leave untouched and
to add to *alongside*, and a term in MAP is not alongside.

Distal delivery is now the filtered load less proximal reabsorption and nothing else. That
carries **41% of the chronic signal on its own** — 2046 to 2171 mEq/day between 38 and 230
mmol/day of sodium — because GFR rises with volume. That path is admissible where the
other two are not: `RN.GFR.VOLUME_SENSITIVITY` was calibrated against GFR, not against
sodium excretion, so the loop does not re-use its own fit. **`RN.MD.RENIN_GAIN` therefore
moved 2.480 → 5.396 against the same estimation set**, because the signal it reads is
smaller.

### A6.2 Two endpoints still fail, and the failure is a measurement

| g_md | Lobo urine, 6 h | Lobo Na, 6 h | chronic PRA ratio |
|---|---|---|---|
| 0.000 | 580 mL | 97.7 mmol | 1.142 — the pressure-only ceiling |
| 4.500 | 727 mL | 122.1 mmol | 2.382 |
| 5.000 | 750 mL | 125.8 mmol | 2.572 — Lobo's urine band ends here |
| **5.396** | **771 mL** | **129.1 mmol** | **2.733** — van den Bosch, and the ledger |

Bands 380–750 mL and 63–127 mmol, both **assumed ±33%** because Lobo publishes no
dispersion at all. The model is 2.8% and 1.7% outside them.

**The acute challenge bounds the arm.** The macula densa can carry a chronic salt–renin
ratio of about **2.57** before the acute limb leaves its band; the measurement is **2.73**.
**Decision 7 said in advance that this gain absorbs the renal sympathetic traffic the model
does not have**, and this is the first place that appears as a number: the last 6% of the
chronic ratio is where the missing arm lives.

**THE GAIN IS NOT TUNED TO MAKE THESE PASS.** Lobo is itself the estimation set for
`RN.ANP.TAU`, and fitting one parameter to two datasets to make a third thing green is how
a model stops being able to be wrong.

### A6.3 The prediction

**Building renal sympathetic traffic must LOWER `RN.MD.RENIN_GAIN` and bring both Lobo
endpoints back inside their bands.** If it does not, the acute overshoot is something else
— the missing candidate being tubuloglomerular feedback on the afferent arteriole, which
this record explicitly does not build and which would blunt the delivery excursion that
drives the overshoot.

### A6.4 What this says about the suite

**Every steady state was right while the form was wrong.** Resting values, the chronic salt
sensitivity, sodium balance and 676 unit tests were bit-identical with the double count in
place, because aldosterone escape zeroes the tubular effect at rest. Only the six-hour limb
moved. **A model whose steady states are all correct can still be wrong about every
transient**, and nothing but a challenge would have said so — directive 1.11 again.

## Amendment A7, 2026-09-05: a false claim about the literature, and what replaced it

**A2 said renal potassium clearance in healthy adults could not be sourced. It could.**
The claim was a generalisation from a handful of queries that returned ketoacidosis,
chronic kidney disease, diuretics and Gitelman syndrome — recorded as a search failure and
then written up as a fact about the literature. **HANDOVER §5 item 20 is that exact failure
mode**, named in this repository after `RESP.CO2.PRODUCTION` missed a 197-study
meta-analysis behind a careful note saying the search had failed. Second occurrence.

**The search term was wrong.** "Fractional excretion of potassium" is a bedside phrase for
separating renal from extrarenal hypokalaemia, so it returns disease by construction. The
physiology is under *potassium balance*, *potassium loading* and *adaptation in normal
man*, and it is the Utrecht group — Koomans, Dorhout Mees, Hené, Boer, Rabelink:

| study | preparation | measured |
|---|---|---|
| Hené 1986, PMID 3523191 | 6 healthy males, 18 d, 80 → 300 mEq/day | urinary K 50 ± 12 → 233 ± 45 mEq/day |
| Hené 1988, PMID 3199680 | 6 healthy males, fixed Na/K | "a steep positive relation between plasma K and urine K" |
| Rabelink 1990, PMID 2266680 | 6 healthy humans, 400 mmol/day, 20 d | urinary K ≈ 80% of intake; renin and aldosterone **back to baseline by day 20** |

**All three are abstract-level only** — none is open access and no full text was obtained.
They therefore change **no value**: re-pooling a full-text extraction against three
abstracts is a decision that needs its own pre-registration. What they buy is an
independent comparison, and it produces two disagreements the model did not have before.

**D1. The urinary fraction is a constant here and is not one in humans.**
`K.RENAL_FRACTION` is 0.884 at every intake. Hené measured 0.63 at 80 mEq/day rising to
0.78 at 300; Rabelink ≈ 0.80 at 400. The direction is consistent across both, the fraction
**rises with intake**, and every Utrecht value sits **below** the 0.884 taken from
Brunner's six studies. Two good groups disagree and it is recorded rather than split.

**D2. There is no potassium adaptation in this model, and adaptation is what these papers
are about.** Rabelink's title is *early and late adjustment*: by day 20 of a 400 mmol/day
load, renin and aldosterone had returned to baseline while kaliuresis was maintained. This
model holds aldosterone at **2.80× baseline for ever**, because its excretion relation is
fixed and its only adaptive machinery — aldosterone escape — acts on the sodium side.
**So the model gets the direction and rough size of a chronic potassium load and gets the
time course of the hormones wrong.** That is the bounded claim to quote.

### A7.1 And falsifiable test 2 is weak for a different reason than A2 gave

A2 blamed the sourcing. **Measured, the sourcing barely matters:** sweeping FE_K from 0.04
to 0.16 moves steady-state plasma potassium only from 4.18 to 3.87 mmol/L, every value
inside the human reference range, because `K.EXCRETION_EXPONENT` = 17.71 pins the
concentration. **Test 2 would be a weak test with FE_K perfectly sourced**, and saying so
is worth more than the void.

## Amendment A8, 2026-09-06: the exponent is re-sourced, and the renal fraction is decided rather than left open

**A3 fitted `K.EXCRETION_EXPONENT` to Brunner 1970 and A7 recorded that the urinary
fraction disagreed between two good groups. Both are now settled under
`validation/potassium_doseresponse_prereg.md`**, committed before the search was run.

**The source.** Cappuccio FP, Buchanan LA, Ji C, Siani A, Miller MA. *BMJ Open*
2016;6(8):e011716, PMID 27566636, PMC5013341, open access, read in full. Twenty
supplementation trials, 1216 participants, 12 countries, ≥ 4 weeks, **intake verified by
24-hour urine collection**. Its Table 1 reports urinary *and* plasma potassium in both arms
of every trial — which is the elasticity `1/n_K` is defined as, measured twenty times.

**The exponent barely moved and that is not the point.**

| route | `n_K` | basis |
|---|---|---|
| pre-registered admissible subset | **17.73** | 3 non-hypertensive, drug-free trials |
| full pooled meta-analysis | 16.00 (95% CI **11.9–24.7**) | 20 trials, 1216 participants |
| Brunner 1970 (A3's source) | 17.71 | 6 studies, 10 subjects, spread **3.45–41.68** |

Three independent routes agree to 11%. **What changed is the dispersion**: a twelvefold
spread over ten people becomes an interval over 1216 that excludes both ends of it. The
pre-registration's §8 fixed exactly that as the test of whether the pass was worth running.

**And decision 5's renal fraction stays a constant by branch D4, not by inertia.** §5 of
the pre-registration fixed the shape a rising fraction would take *before* looking, and D5
would have taken it. **The sources disagree on the sign:** Hené and Rabelink have the
fraction rising with intake (0.63 → 0.78 → ≈0.80), while this paper's *marginal* fraction —
the share of each supplement appearing in urine — is **0.734**, below the ledger's 0.884,
which would make the average fall. D4 says report the disagreement and do not split it.
The marginal figure is also the fate of a KCl tablet rather than of food, and every bias on
it points the same way.

**One thing became a check that had never been one.** `K.RENAL_FRACTION × K.INTAKE.NOMINAL`
= 61.05 mmol/day of urinary potassium; the 19 control arms average **61.17**, measured by
24-hour collection in 12 countries. **0.2% is too good** — a dietary recall understates
intake and those cohorts are not American — but it rules out a gross error in a product
that had been compared with nothing.

**What this does not fix: `OPEN-QUESTIONS` B11 stands.** There is still no potassium
adaptation, and §7 of the pre-registration forbade this pass from touching it.

## What is NOT decided

- **Renal sympathetic traffic.**
- **Chloride and the anion gap.**
- **Transcellular potassium shifts**, and therefore acute hyperkalaemia.
- **Any effect of potassium other than on aldosterone.**
- **Tubuloglomerular feedback on the AFFERENT ARTERIOLE** — this record connects the
  macula densa to renin only, not to glomerular filtration.
- **Diuretics, and any disease state.**
- ~~**Every numeric value.**~~ Nine are in the ledger under `RN.*` and `K.*`.
- **Aldosterone, distal flow and plasma potassium as SEPARATE influences on potassium
  excretion.** They are lumped into one exponent because no human study separates them,
  so spironolactone, primary aldosteronism and a pure flow change are all outside this
  model — it cannot tell them from a change in plasma potassium.
