# ADR 0029: Glucose, as an algebraic balance with no new state

**Status:** Accepted
**Date:** 2026-09-21
**Evidence tier:** **E2** for the renal reabsorptive maximum (Mogensen 1971, human
titration) and for basal endogenous glucose production (Huidekoper 2014, isotope dilution);
**E1** for glucose being an extracellular osmole. **E3** for the lumped disposal term,
default ON, falsifier named in Consequences.

Pre-registered in `validation/glucose_insulin_prereg.md`. **Branch G2.**

## Context

HANDOVER §4 item 1: *"Cortisol, insulin and glucose still connect to nothing, and an
endocrine component built for completeness rather than connection is exactly what ADR 0006
records Circadian being."* So the pre-registration answered **what it connects to** before
deciding what to build, and found the slot already present and **constant** in three places:
`Osm_other` in `BodyFluids`, `RN.URINE.SOLUTE_LOAD`, and `RER` in `Blood`.

**Branch G5 — "the connection does not bite" — was tested FIRST**, before any source was
opened. The non-sodium osmolal lump is ~7 mOsm/kg against an ADH sensitivity of 0.12 per
mOsm/kg, and a 10 mmol/L glucose excursion is a 10 mOsm/kg signal. It bites. G5 not taken.

## Evidence

| Claim | Tier | Source | Reading level |
|---|---|---|---|
| Renal TmG 352 ± 64 mg/min, n = 9 normals; **correlates with GFR** | **E2** | Mogensen 1971, PMID 5093515 | abstract read **at the publisher** — PubMed carries none |
| Basal EGP = `6.50·e^(−0.145·age) + 1.93` mg/kg/min, n = 40 | **E2** | Huidekoper 2014, PMID 24996789 | abstract, PubMed |
| Fasting glucose 5.44 mmol/L (IQR 5.05–5.77), n = 5,563 | **E2** | NHANES 2007–2012 | extracted, `glucose_insulin_extract.py` |
| Glucose is an extracellular osmole | **E1** | definitional | — |
| Insulin sensitivity | **NOT SOURCED** | three papers opened, §9.8/§9.12 | — |

## Decision

**Glucose is an ALGEBRAIC balance. The component adds ZERO states — the model still has 16.**

    C_glu_ns ~ egp_tot / (k_glu * glu_disposal)
    C_glu    ~ ifelse(GFR*C_glu_ns <= TmG, C_glu_ns, (egp_tot + TmG)/(k_glu*glu_disposal + GFR))
    glu_excr ~ max(0, GFR*C_glu - TmG)

The balance is **linear on each side of the spill point**, so both branches invert in closed
form and nothing is solved iteratively. `k_glu` = `egp_tot/G_fast` is **derived in the
component** — the identity that balances production at the fasting concentration, arithmetic
on two sourced rows and not a fit. At the reference it is 199 L/day, i.e. **138 mL/min**,
the right order for basal whole-body glucose clearance; nobody arranged that.

**WHY NO STATE, AND IT IS BRANCH G2 APPLIED RATHER THAN QUOTED.** §1 proposed two. G2
removed the insulin regulator and with it the case for either: glucose turns over in about
an hour, nothing in this model infuses it, and a fixed clearance leaves no dynamics worth
paying for on every run of a 400-day integration. **Directive 1.10. If insulin ever sources,
glucose becomes a state in that pass.**

**`BF.OSM.NONSODIUM` is RETIRED** and the remainder computed in `BodyFluids`, the treatment
`md_vt_ref` and `f_dist_ref` already have.

## Consequences

**THE OPERATING POINT IS EXACT.** MAP 87.01, plasma sodium 140.0, osmolality 287.004, urine
1.70 L/day, `Na_excr` 205.0, GFR 152.6, urine osmolality 547 — all unchanged. Suite
**808/808**, six gates green, `challenges.jl` unchanged at one failure (Jensen, ADR 0028's).

**DILUTIONAL HYPONATRAEMIA IS EMERGENT AND NOTHING WAS FITTED TO IT.** Plasma sodium falls
**0.49 mmol/L per mmol/L of glucose** — 140.0 at 5.44, 133.9 at 17.7 — against a classic
clinical correction of **0.29** and Hillier's measured **0.43**. It falls out of glucose
being an osmole in a model that already had ICF/ECF water shifts.

**THE MODEL CANNOT PRODUCE POLYURIA, AND THAT IS THE SHARPEST LIMITATION THIS PASS FOUND.**
`BF.H2O.INTAKE_NOMINAL` is 2.5 L/day, **`assumed`, citation "Convention pending primary
source"**. At steady state urine volume is pinned by intake minus losses, so it stays at
**1.70 L/day at every glucose level**; the osmotic load appears as urine *concentration*
instead, 547 → 728 mOsm/kg. **Thirst is the missing mechanism**, and until it exists the
osmotic-diuresis prediction can only be read as a concentration.

**NO SPLAY, AND IT VINDICATES THE ADVANCE FLAG.** §2 named the "180 mg/dL renal threshold"
as the most suspect number in the subsystem before any search. Tm/GFR gives a spill
concentration of **about 18 mmol/L**, not 10 — the difference is nephron heterogeneity, and
this model has one nephron's worth of kinetics. **It will predict glycosuria starting later
than it does in people**, and the teaching threshold was not substituted to hide that.

**AND THE TWO OSMOLALITY SETPOINTS DO NOT COMPOSE.** Computing the remainder rather than
storing it exposes that `287 − 280 − 5.44` leaves **1.56 mOsm/kg** for urea, potassium and
the rest — and urea alone is about 5. `BF.OSM.PLASMA_SETPOINT` and `BF.NA.PLASMA_SETPOINT`
are sourced from different populations and do not add up. **Nothing here is adjusted to hide
it**, because the model's behaviour at normal glucose is identical either way.

**DIRECTIVE 1.12 SCORED AGAIN, MATERIALLY.** §2 listed 5.0 mmol/L as the teaching fasting
glucose. The measured centre is **5.44**, and 5.0 sits essentially at the **25th
percentile** of healthy US adults. Fifth instance of the pattern.

**THE E3 CLAIM AND ITS FALSIFIER:** `glu_disposal` lumps insulin resistance and insulin
deficiency into one clearance, and real type 2 diabetes lowers insulin-stimulated disposal
while *raising* endogenous production. Sourcing the steady-state insulin of the RISC clamp
would split them and retire this.

## What this disqualifies as evidence

**Fasting insulin was measured and deliberately NOT entered.** NHANES gives 64.2 pmol/L
(IQR 41.9–103.2) in the same 5,563 adults. G2 removed its consumer, and a ledger row nothing
reads is what directive 1.11 exists to prevent.

**RISC's M = 7.12 ± 2.95 mg/kg/min is a held-out target, not a parameter.** Against this
model's basal 1.93 it implies a 3.7-fold dynamic range for insulin-stimulated disposal. It
is recorded in the pre-registration so that the pass which builds insulin cannot be fitted
to it.

**Mogensen's diabetic arm (419 ± 50 mg/min) is not used.** §3 excludes diabetes cohorts for
anything setting a normal value.

**And his sodium/potassium observation is reserved.** During glucose infusion urinary
potassium fell and sodium rose, in both his groups. This model computes both. **It is
recorded before the component existed** so it cannot later be claimed as a prediction that
was designed in.
