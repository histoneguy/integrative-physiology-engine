# ADR 0035: Hepatic and peripheral insulin resistance are separable, and the model's type 2 had the liver backwards

**Status:** Accepted
**Date:** 2026-09-24
**Evidence tier:** **E2** for the *shape* of the defect (Groop 1989, graded hyperinsulinaemia
in NIDDM and matched controls). **The magnitude is a lesion dial and not a sourced value**,
and the row says so.

Pre-registered in `validation/hepatic_ir_prereg.md`, **branch H1**. This is the omission
**ADR 0034 recorded against itself**, and `egp_suppression_prereg.md` §9 named adding it in
that pass as a way that pass would fail.

## Context

After ADR 0034 the liver responds to insulin — but `glu_disposal` scales `S_I` alone, so the
only insulin-resistance lesion available was **peripheral**. The liver's *sensitivity* could
not be lesioned at all.

**THE COST WAS STATED BEFORE BUILDING** (`hepatic_ir_prereg.md` §2): the model's type 2 was a
peripheral-resistance plus beta-cell-failure disease, so it reached fasting hyperglycaemia
**only through beta-cell failure** and therefore overstated the beta-cell contribution.

## Evidence

**Groop LC, Bonadonna RC, DelPrato S, Ratheiser K, Zyck K, Ferrannini E, DeFronzo RA.**
*Glucose and free fatty acid metabolism in non-insulin-dependent diabetes mellitus. Evidence
for multiple sites of insulin resistance.* J Clin Invest 1989;84(1):205–213. **PMID 2661589.**
Nine lean NIDDM, eight matched controls, graded insulin at **+5, +15, +30, +70, +200 µU/ml**.

> basal hepatic glucose production **higher in NIDDM**, and **suppression of HGP by insulin
> was impaired at all but the highest insulin concentration**; glucose disposal was reduced
> **at the three highest** plasma insulin concentrations

**TWO DEFECTS ACTING AT DIFFERENT INSULIN RANGES.** Hepatic suppression fails across almost
the whole range and is **rescued at the top**; peripheral disposal fails only at the highest
steps. That is a **rightward shift of the hepatic dose–response with maximal effect
preserved** — a different *shape* of defect, which is why one knob could not carry both.

## Decision

    egp_i ~ egp_basal * egp_0 / (1 + hep_sens * I_glu / K_egp)

**ONE MULTIPLIER INSIDE THE EXISTING HYPERBOLA.** `hep_sens` = 1 is health and the equation is
**identical to ADR 0034**; below 1, more insulin is needed for the same suppression and
**maximal suppression at infinite insulin is preserved**, matching *"impaired at all but the
highest insulin concentration"*.

**IT IS A LESION DIAL, NOT A SOURCED CONSTANT.** `beta_cell` and `glu_disposal` are the
precedent — dimensionless, inert at 1.0, set by whoever runs the model. **Groop sources the
shape; no admissible source gives a population value for the magnitude**, and inventing one
was named in §8 as a way this pass fails.

**ONE KNOB, NOT TWO, AND THE ELEVATED BASAL OUTPUT HAD TO EMERGE.** Groop also reports basal
HGP higher in NIDDM — but at a *higher prevailing insulin*, so an elevated basal rate is
**predicted by** a rightward shift rather than independent evidence for a second parameter.
§4 refused the second parameter in advance and §6 test 3 required the emergence.

## Consequences

**TEST 3 — THE EMERGENCE HELD.** Hepatic resistance alone, with both other knobs at health:

| `hep_sens` | glucose | insulin | EGP |
|---|---|---|---|
| 1.00 | 5.44 | 64.2 | 1079.8 |
| 0.60 | 5.59 | 72.4 | 1331.4 |
| 0.30 | 5.80 | 83.2 | 1680.2 |
| 0.15 | 5.98 | 92.4 | 1994.0 |

Glucose rises, **basal EGP rises**, and **insulin rises** — the compensation. Groop's *"basal
HGP higher in NIDDM"* appears **without being imposed**, from one multiplier.

**TEST 4 — THEY ARE NOT MERELY DISTINGUISHABLE, THEY MOVE EGP IN OPPOSITE DIRECTIONS.**

| at knob = 0.3 | glucose | insulin | **EGP** |
|---|---|---|---|
| hepatic only | 5.80 | 83.2 | **1680.2** ↑ |
| peripheral only | 6.62 | 124.1 | **698.7** ↓ |

The peripheral lesion raises glucose *more* while **suppressing** hepatic output harder,
because it drives insulin higher. **Branch H1 decisively; the knob is identifiable and is not
a duplicate of `glu_disposal`.** §7's branch H2 — remove it as redundant — was a real
possible outcome and did not occur.

**TEST 5 — AND IT FOUND THAT THE MODEL'S TYPE 2 HAD THE LIVER BACKWARDS.**

| type 2 | glucose | **EGP** |
|---|---|---|
| two lesions (before this ADR) | 11.63 | **850.8** — *below* the basal 1079.8 |
| three lesions | 14.29 | **1479.4** — above basal |

**The old two-lesion type 2 reached hyperglycaemia with hepatic glucose output BELOW
normal**, which is the opposite of the disease: fasting EGP is *elevated* in type 2 and is
the principal source of its fasting hyperglycaemia. The defect was invisible until the liver
could be lesioned, and §2 predicted its direction before the knob existed.

**Health is bit-identical** — glucose 5.44, insulin 64.2, EGP 1079.8, MAP, sodium, urine,
`Na_excr`. **Suite 834/834, six gates exit 0**, and the test count is unchanged because a
lesion dial is not a ledger parameter.

## What this disqualifies as evidence

**NO NUMBER HERE IS SOURCED.** `hep_sens` has no measured value and never will from Groop —
the paper establishes that hepatic sensitivity is reduced in type 2 and that the reduction
has a rightward-shift shape. **Any particular setting is the user's assumption**, exactly as
for `beta_cell` and `glu_disposal`.

**THE DISEASE COLUMNS ARE ILLUSTRATIONS, NOT PREDICTIONS.** "Type 2, three lesions" at 0.3 /
0.2 / 0.3 is three dials chosen to demonstrate separability. **It is not a claim about what a
type 2 patient's parameters are**, and the glucose it produces is not a validated number.

**GROOP'S NUMBERS WERE NOT EXTRACTED.** The five insulin steps and their suppression
percentages are in the full text, which is closed access. **A digitised hepatic dose–response
would let `hep_sens` be estimated rather than dialled**, and would also supply the Hill
coefficient ADR 0034 fixed at 1 — the same paper answers both open questions.

**GLUCAGON IS STILL ABSENT**, and free fatty acids — which Groop shows are the other half of
the story, with impaired FFA suppression correlating with HGP — are not represented at all.
That is the next real gap in this axis, and it is named here so a later pass cannot present
it as a discovery.
