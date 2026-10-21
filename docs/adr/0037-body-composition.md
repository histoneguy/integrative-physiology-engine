# ADR 0037: Body composition, and the model's body water implies women are 90% lean hydration

**Status:** Accepted
**Date:** 2026-10-20
**Evidence tier:** **E2** for the fat / fat-free partition (NHANES DXA, n = 10,832, extracted
here and survey-weighted); **E2** for skeletal muscle (Janssen 2000, whole-body MRI, n = 468,
abstract).

Pre-registered in `validation/body_composition_prereg.md`. `OPEN-QUESTIONS` **B28**, and the
substrate HANDOVER §4 names as unblocking metabolism, energy balance, thermoregulation and
urea at once.

## Context

**The model had level V and nothing else.** `BF.BODY_MASS.*` is whole-body mass, and every
extensive quantity scales off it. There was no fat, no lean tissue, no organ.

## Evidence

**THE REVIEW SETTLED THE QUESTION THAT HAD TO COME FIRST: WHICH LEVEL.** Wang ZM, Pierson RN
Jr, Heymsfield SB. *The five-level model.* Am J Clin Nutr 1992;56(1):19–28. **PMID 1609756.**
The field divides body composition into **atomic, molecular, cellular, tissue-system, whole
body**, and its point is that compartments at different levels are connected but **not
interchangeable.**

| Compartment | Level | Source | Method |
|---|---|---|---|
| fat / fat-free mass | **II, molecular** | NHANES DXA 2011–2018, **extracted** | DXA |
| skeletal muscle | **IV, tissue-system** | Janssen 2000, PMID 10904038 | whole-body MRI |

| | fat fraction | fat mass | fat-free mass | n |
|---|---|---|---|---|
| male | **0.272 ± 0.060** | 24.9 kg | 63.6 kg | 5385 |
| female | **0.387 ± 0.063** | 30.7 kg | 46.2 kg | 5447 |

**EXTRACTED, NOT TRANSCRIBED.** Kelly 2009 (PMID 19753111, PLoS One, open access, read) is the
canonical reference-value paper for this exact dataset and **its values are age-normalised
curves in figures.** Branches N3 and S3 of two earlier pre-registrations already fixed that
figures are not digitised here, so extracting the underlying file is strictly better than
reading the plot. The computed fraction agrees with the file's own `DXDTOPF` to **0.0001** in
both sexes, which is the check that the compartments were assembled as NHANES intends.

**DIRECTIVE 1.12 SCORED HARD.** §2 listed *"men 15% fat, women 25%"* **before** extraction.
Measured: **27.2% and 38.7%** — out by twelve percentage points. The teaching pair describes a
lean young reference subject, not a population.

## Decision

    mass_fat    ~ f_fat * m_body
    mass_ffm    ~ (1 - f_fat) * m_body
    mass_muscle ~ f_muscle * m_body

**`BodyFluids` now takes `sex`**, because composition is strongly sexed and it previously did
not need to know.

**BOTH FRACTIONS ARE OF BODY MASS AS THEIR SOURCES REPORT THEM.** Janssen's 38.4%/30.6% is a
fraction of body mass, **not** of fat-free mass, and it is deliberately **not** re-based onto
`mass_ffm` — that would be rescaling a measured number to fit this model's compartments, which
the pre-registration names as a way the pass fails.

**NOTHING CONSUMES MUSCLE MASS YET, AND THAT IS SAID PLAINLY.** Insulin-mediated glucose uptake
is where it belongs — Baron measured it in **leg muscle** — and that is a later pass. **A
substrate that pretends to be a mechanism is worse than one that admits it is not.**

## Consequences

**TEST 3 PASSED, AND IT WAS THE ONE THAT COULD HAVE SUNK THE PASS.** Fat-free mass exceeds
skeletal muscle by **1.9×** in men and **2.0×** in women. Treating DXA lean mass as muscle is
the standard conflation and is wrong by about twofold; **the model's two levels are not
conflated**, measured rather than asserted.

**TEST 1 PASSED.** Operating point untouched — MAP 87.0, `V_ecf` 14.6, sodium 140.0, `Na_excr`
205.0 — which follows from wiring nothing into the loop and is **a property of §5, not a
result.**

### The finding: the model's body water is unsexed and that is not survivable

**All three water fractions are `sex = both`** — TBW 0.552, ICF 0.344, ECF 0.208, each a
fraction of **body** mass. Divide by the measured fat-free fraction and ask what hydration of
fat-free mass that implies:

| | implied FFM hydration |
|---|---|
| male | 0.758 |
| **female** | **0.900** |

**The hydration of fat-free mass is ≈0.73 and is among the most stable quantities in body
composition — that is why it is called a constant. Fat-free mass cannot be 90% water.**

Because women carry **38.7%** fat against men's **27.2%**, a single body-mass water fraction
applied to both sexes forces a physiologically impossible female composition. In litres: 73%
of measured female fat-free mass is **34.9 L** against the model's **43.0 L** — roughly **8
litres** of water the model puts in women that has nowhere to be.

**IT WAS INVISIBLE WITHOUT THE SUBSTRATE, WHICH IS THE WHOLE ARGUMENT FOR BUILDING ONE.**
`check_closure.py` verifies ICF + ECF = TBW, and that identity holds perfectly at **both**
sexes — the compartments sum, they are just the wrong size in women. **It is the B32 class
exactly: an intermediate that is physically inadmissible and enters no identity.**

### And checking the source made it worse

**The three water fractions rest on Zhang N et al.** (PMC6751809, read in full 2026-10-20):
**160 Chinese college students, measured by bioelectrical impedance, in a study about water
intake.** Its 55.2 / 34.4 / 20.8 percent of body weight are exactly this ledger's 0.552 /
0.344 / 0.208.

- **It reports sex differences and the ledger took the pooled value** — the paper states
  males were higher than females in all three. **The sexed numbers existed and were not used.**
- **BIA is the weakest available method**; the reference methods are deuterium dilution for
  total body water and bromide dilution for extracellular.
- **Directive 1.7 fails outright.** Apply its test: had the physiology come out differently,
  the paper's conclusion would still have been about water intake. **Body water is the
  instrument, not the subject** — and these are the foundation of the fluid model.
- **The cohort is wrong for this model.** Lean young students against a 90.3 kg reference at
  27% fat, and total body water as a fraction of body weight **falls with adiposity** — which
  is the arithmetic that produced the 0.900 above.

**The paper itself cites Chumlea 2001** for total body water in NHANES III, a US population
reference. *The review sends you to the primary literature*, again.

**NOT FIXED HERE.** `OPEN-QUESTIONS` **B37** carries three non-equivalent routes — re-source
from a dilution or NHANES series, sex the existing Zhang values, or re-anchor on fat-free mass
with a sourced hydration constant. §6 of the pre-registration
forbade moving them in this pass, and `V_ecf` feeds blood volume, cardiac output and arterial
pressure — the entire closed loop.

## What this disqualifies as evidence

**NHANES IS NOT A HUMAN POPULATION SAMPLE, AND THE ROW SAYS SO IN FOUR PARTS.** With
`WTMEC2YR` it represents the **US civilian non-institutionalised** population. (1) **US only**
— body fat at a given BMI is higher in South and East Asian populations. (2) **Institutionalised
people are excluded**, dropping the frail elderly and the young fit from opposite ends.
(3) **The DXA subsample is truncated at the top** — pregnancy and the table's weight and height
limits — so the mean is affected little and **the SD is biased low**. (4) **DXA non-response is
unquantified**: NHANES publishes no DXA-specific weight from 2011 on, and for 1999–2006 it
released **multiply imputed** DXA files precisely because that assumption was shaky. So this is
a weighted estimate carrying an unquantified non-response assumption.

**BRANCH C2 WAS TAKEN ON THE MUSCLE ROW.** Janssen's percentages imply a cohort of 85.9 kg
(men) and **68.6 kg** (women); this ledger's references are 90.3 and 77.9. Applying his
percentage here gives **34.7 kg against the 33.0 he measured** in men and **23.8 against 21.0**
in women — 5% and **13.5%** high. **His number is not adjusted to fit.** It is `OPEN-QUESTIONS`
B31's defect again: a fraction from one cohort applied to a body mass from another.

**THE ERAS DIFFER TOO.** Janssen scanned in the 1990s; the DXA fat fractions are 2011–2018, and
population adiposity rose between. The muscle fraction comes from a leaner era than the fat
fraction beside it.

**THE MUSCLE FRACTION IS LINEAR AND THE SOURCE SAYS IT IS NOT.** Janssen states the
contribution of skeletal muscle to weight gain **decreases** with increasing body weight, so a
constant fraction overstates muscle in heavy individuals. It matters for the population sweep,
not at the reference individual, and correcting it needs a regression from a full text not read.

**NO DISPERSION ON MUSCLE.** The abstract gives no SD for the percentage, so
`uncertainty_type = none` rather than inventing one. Weight and height explain about half the
variance, so the real spread is substantial and unrecorded.

**AND TEST 4'S PREMISE WAS WRONG.** §4 expected re-anchoring the water compartments on fat-free
mass to change the **population sweep**. Measured: with a **constant** `f_fat` the two
anchorings are **algebraically identical**, so the sweep is a no-op. The effect is entirely
**between sexes**, which is how B37 was found. **The pre-registration predicted the wrong
mechanism for the right change**, and that is recorded rather than quietly re-framed.
