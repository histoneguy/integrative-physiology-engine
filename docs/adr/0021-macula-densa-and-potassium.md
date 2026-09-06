# ADR 0021: Distal sodium delivery, macula densa control of renin, and potassium

**Status:** Proposed
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

## What is NOT decided

- **Renal sympathetic traffic.**
- **Chloride and the anion gap.**
- **Transcellular potassium shifts**, and therefore acute hyperkalaemia.
- **Any effect of potassium other than on aldosterone.**
- **Tubuloglomerular feedback on the AFFERENT ARTERIOLE** — this record connects the
  macula densa to renin only, not to glomerular filtration.
- **Diuretics, and any disease state.**
- **Every numeric value.**
