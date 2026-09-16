# ADR 0023: Red cell mass is a state, and the oxygen loop closes

**Status:** Accepted
**Date:** 2026-09-16
**Evidence tier:** E1 for the direction, E2 for the lifespan and the recovery, E3 for the sensed signal (STRUCTURE ONLY - no numeric value)

Pre-registered in `validation/erythropoiesis_prereg.md`, written before any source
was opened. Verify the ordering with

    git log --diff-filter=A -- validation/erythropoiesis_prereg.md
    git log --diff-filter=A -- validation/erythropoiesis_extract.py

## Context

`V_blood = f_pv·V_ecf + Hct·BV0`. **The red cell term was a constant**, so a bleed
removed erythrocytes that nothing restored.

That defect was not deduced, it was **measured**. The haemorrhage perturbation
built on 2026-09-08 showed a 1 L bleed settling permanently at **16.65 L of
extracellular fluid against a starting 14.56**, with renin at 0.37 against a
pre-bleed 1.25. Every step of it was correct: replacing 0.453 L of red cells can
only be done with plasma, plasma is 21% of extracellular fluid, so restoring blood
volume costs 2.15 L of extracellular expansion — predicted 16.71, observed 16.65.
The model was not convalescing. It was finding a new equilibrium, and it was right
to, because the mechanism that unwinds it did not exist.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| Red cell mass is regulated; loss raises production | E1 | Not in dispute | human |
| Mean red cell lifespan is of order four months | E2 | Conventional 120 d, **primaries not opened** | human |
| An 8.8% haemoglobin-mass deficit is made good in 36 ± 11 d | E2 | Pottgiesser 2008, PMID 18466177, **abstract read in full** | human |
| Haemoglobin concentration is MCHC × haematocrit | E1 | Definitional | — |
| MCHC is near-constant absent iron deficiency | E3 | Reasoned from model scope; **not sourced** | human |
| Erythropoietin answers to renal tissue oxygenation | E1 | Not in dispute — and **not what is built** | human |

**THE TWO E3 CLAIMS ARE STRUCTURE ONLY - no numeric value.** Neither the
constancy of MCHC nor the choice of sensed signal contributes a number to the
ledger. `RBC.MCHC` itself is DERIVED from two tier-A rows already present from the
same cohort and stratum, so its value carries their provenance; what is E3 is the
decision to hold it fixed, which is a structural claim about scope. Likewise the
capacity reduction fixes the FORM of `o2_deficit` and contributes no parameter -
its one gain, `RBC.PRODUCTION_GAIN`, is derived from the lifespan and the measured
recovery. ADR 0006's structure-only exemption is claimed for both, rather than
defaulting them off, because a component that defaults off would leave the bleed
not unwinding, which is the defect this record exists to close.

**The lifespan is entered as `assumed`, not `reported`, and the reason is
directive 1.5:** no primary was opened. The biotin-labelling literature reached in
this pass was at search-summary level, and it says the conventional 120 days is
**too low** — fresh transfused cells give a mean near 132 d (95% CI 120–146). So
the round number is a teaching figure of exactly the shape directive 1.12 warns
about, and it is recorded as one.

**It barely matters, and saying why is the point.** Only the combination
`lifespan/(1+gain)` is identified by the recovery data. An error in the lifespan is
absorbed by the gain, and the recovery time — the only behaviour tested — is
unchanged. Nothing in this model reads the steady-state erythropoietic turnover.
Section 3.26's rule applied: where two rows are not separately identifiable, the
composite is the real quantity and the split is bookkeeping.

## Decision

Red cell volume becomes the **twelfth state**:

    D(V_rbc) = (Hct·BV0 / lifespan)·(1 + G·o2_deficit) − V_rbc / lifespan

**Haematocrit splits in two, and the split was fixed in advance.** `Hct` stays a
parameter — it is the reference the whole ledger is stated at, and it appears in
`f_pv = BV0(1−Hct)/V_ecf₀`. `Hct_eff = V_rbc/V_blood` is the new variable.
Conflating them would move every derived cardiovascular row, and §3.8 records what
happened the last time haematocrit played two roles at once.

**Haemoglobin stops being an independent parameter** and becomes `MCHC × Hct_eff`.
§3.24 already recorded the model's implied MCHC — 33.8 male, 33.4 female, both
inside a normal 32–36 — as a check that could have failed and did not. This turns
that agreement from a coincidence into a structural identity and removes a
redundancy: haematocrit and haemoglobin came from the same cohort and stratum.
`RBC.MCHC` therefore introduces **no new source**; it carries five figures solely
to close that identity, which is the one precision exemption `CLAUDE.md` states.
As a physiological statement the row is 34 g/dL.

**The operating point does not move, by construction rather than by tuning.** At
zero deficit, production is exactly `Hct·BV0/lifespan`, so the state is stationary
at the reference identically, for any gain and any lifespan.

### The sensed signal, and the pre-registration was wrong about it

§4 of the pre-registration committed to **arterial oxygen content**. Content is
wrong, and **the test suite is what caught it**. That is the only reason to write a
pre-registration: so that being wrong is visible rather than absorbed.

Content is a *concentration*. Expand the plasma and it falls with no red cell lost,
so a content-keyed loop reads a salt load as anaemia. Measured before the
correction: across the 205 → 103 mEq/day salt step **red cell volume moved
2.546 → 2.507 L and salt sensitivity went 2.98 → 4.24** — a 42% shift in the
model's headline result. That is §3.8's already-closed defect, red cells expanding
with plasma, returning through a different door five weeks later.

Physiologically the reason is clear: **dilutional anaemia does not drive
erythropoiesis**, because the kidney senses oxygen *delivery* against its own
consumption, and flow rises to meet the fall in concentration. That is why
normovolaemic haemodilution is tolerated at all.

**Delivery was tried and is not available here.** `CO × CaO2` is the right
reduction, but this model's cardiac output is far too insensitive to blood volume
to supply the compensation — the venous-return term gives an elasticity of 0.22, so
delivery still carries three quarters of the dilution artefact.

**So the loop regulates oxygen CAPACITY, not concentration:**

    o2_deficit = 1 − (SaO2/SaO2₀)·(V_rbc / Hct·BV0)

The deficit is deliberately **not** normalised by blood volume. Every volume
perturbation this model can express is a *plasma* perturbation, and it has no
viscosity, no renal blood flow and no renal oxygen consumption with which to tell
dilution from depletion. This gets the cases the model **has** right and gives up a
case it does not have.

**Saturation is still in it, and that is why the edge from blood survives.** A fall
in arterial saturation raises production at unchanged red cell mass, so the hypoxic
limb is built and works the day an inspired oxygen fraction becomes an input. Today
`FiO2` and barometric pressure are constants, so `sat_rel` is 1.0 and that term is
inert — wired under the same discipline as the thyroid metabolic arm, so the
declaration and the model agree in both configurations.

### The gain is the recovery rate, and that is not an accident

Because the deficit is proportional to the red cell mass deficit with a coefficient
of **one**, linearising gives `lifespan/(1+G) = 120/5 = 24 days`, which is
`RBC.RECOVERY_TAU` — the number `G` was derived from. **That would not have held
under the pre-registered content signal**: the coefficient there is `(1−Hct) = 0.55`,
the closed loop would have run at 33 days against a derived 24, and the ledger row
would have been asserting an identity the model did not satisfy — §5 item 22, a
calibrated parameter quietly re-estimated by a second path.

## Consequences

**The coupling count rises 21 → 22 and the new edge is outbound from blood.** ADR
0018 built that component as a forward computation and left a tripwire in its own
docstring: *if an outbound edge ever appears here it means an oxygen feedback has
been built, and it needs its own record.* This is that edge and this is that
record. The pre-registration named the count as falsifiable test 5 before the work
began, and the lag count rises 6 → 7 with it.

**Red cells are now the slowest state in the model by a factor of three** over the
thyroid axis. That cost is real, it buys the haemorrhage recovery, and it buys
nothing else yet.

**`RBC.RECOVERY_TAU` is an ESTIMATION SET and may never be reported as agreement.**
The recovery the model reproduces is the datum it was solved against.

**`member_remake` gained its first non-body-fluid initial condition.** Adding a
state to a component with sexed or extensive parameters silently creates an
obligation in `src/ensemble.jl`; this is the ninth time that list has been short of
something and the first time it was a state rather than a parameter. The
class-level test caught it at `worst = 0.0107`.

### What this forecloses

- **Anaemia of renal disease.** The kidney failing to make erythropoietin at a
  normal oxygen signal is the paradigm case this reduction excludes. Predicted in
  the pre-registration, before building.
- **Any state where erythropoiesis should answer to dilution rather than to loss.**
  Discovered by the salt step, not predicted.
- **Iron.** `RBC.RECOVERY_TAU` lumps erythropoietic drive with iron availability,
  the way `K.EXCRETION_EXPONENT` lumps aldosterone, distal flow and plasma
  potassium. Donation removes iron as well as cells, and iron is what limits
  recovery in many donors — the same literature reports beyond 300 days in young
  women against 36 in these men. **The model cannot distinguish an erythropoietic
  defect from iron deficiency.**
- **Cohort-labelling experiments.** Destruction is first-order; real red cells die
  at a fixed *age*, and survival is near-rectangular. Mean lifespan right,
  distribution wrong. Declared in the pre-registration §5 before building.
- **Sex differences in recovery.** Pottgiesser is 29 men. Recovery is markedly
  slower in women and this row carries no pair, so it is a male number applied to
  both — the `CV.HEMATOCRIT.NOMINAL` failure of §3.8, declared in advance this time
  rather than found later.
- **Reticulocyte kinetics.** No maturation delay is built. Stimulus to circulating
  reticulocyte is days against a lifespan of months, and a lag whose time constant
  is identified by nothing is the debt `RN.ANP.TAU` already carries.

## What this lumping disqualifies as evidence

Any study whose endpoint is the **rate** of red cell recovery, because that rate is
what the gain was solved against. Any study of **erythropoietin concentration**,
because there is no erythropoietin here. Any comparison of the model's red cell
response to a **plasma-volume manipulation** — haemodilution, plasmapheresis,
saline loading — because the capacity reduction deliberately makes it null, and a
null the model was built to produce is not a prediction.

## Falsifiable tests

All five were committed in `validation/erythropoiesis_prereg.md` §9 before any
source was opened. They live in `test/runtests.jl`.

1. **The operating point is unchanged.** Red cell volume, effective haematocrit and
   derived haemoglobin all rest on their sourced values after 60 days of
   integration, with production equal to destruction by construction.
2. **The haemorrhage unwinds.** After a 1 L bleed, extracellular volume expands
   acutely and returns to within 0.5% of its pre-bleed value as red cell mass
   regenerates. **This failed before this record, and it is the reason the pass
   exists.**
3. **Two timescales, visibly different.** Haematocrit falls more than 2 points
   within a day; the red cell deficit takes 10–30 days to halve, more than five
   times the plasma refill time.
4. **Content moves, tension does not.** Arterial oxygen content falls after the
   bleed while saturation is unchanged to 1e-6 — §3.27's distinction surviving the
   loop closing — and the deficit signal is zero at rest and above 0.1 after.
5. **The coupling count rises 21 → 22, the new edge outbound from blood**, and the
   lag count rises 6 → 7.

A sixth was added by what the suite found and it is the one that matters most:
**the salt step may not move red cell mass at all** (< 1e-4 L across all three
arms) while haematocrit must still dilute (> 0.005). That is precisely the
assertion the pre-registered content signal fails, and it is written down so the
correction cannot be quietly undone.
