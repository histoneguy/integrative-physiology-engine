# Pre-registration — body-size scaling, and the exponent that replaces linear-in-mass

**Written before any source is opened for these values, and before the exponent is
computed.** Verify ordering with

    git log --diff-filter=A -- validation/body_size_scaling_prereg.md
    git log --diff-filter=A -- validation/body_size_scaling_extract.py

**What was already known when this was written.** That NHANES carries height and weight
per subject in the `BMX` body-measures file, and that the `DEMO` and `BIOPRO` files were
already downloaded for two earlier extractions. **No height, no BSA and no exponent has
been computed.**

---

## 1. WHY, AND IT IS A DEFECT THE MODEL ALREADY RECORDS AGAINST ITSELF

`src/scaling.jl`, in its own docstring:

> *SCALING IS LINEAR IN MASS, AND THAT IS AN APPROXIMATION WITH A KNOWN DIRECTION.
> Extracellular volume and blood volume genuinely are near-linear in body mass … GFR and
> cardiac output are conventionally normalised to BODY SURFACE AREA, which grows
> sub-linearly with mass, so linear scaling OVERSTATES their spread across a population.
> Correcting that needs height, which this model does not carry, and a BSA formula, which
> would need its own extraction. Recorded as debt rather than approximated with an
> unsourced exponent.*

This is that extraction. **`HANDOVER.md` §4 item 10 and `OPEN-QUESTIONS.md` §B6** are the
same debt.

**And it is now worth more than when it was recorded**, because `RESP.METABOLIC_RATE`
(§3.28) is entered per kilogram from a source that says explicitly that metabolic rate per
kilogram FALLS with body mass. The model currently scales it linearly and therefore
overstates the metabolic rate of heavy people, which the source itself refutes.

---

## 2. THE QUANTITIES

| id | what | role |
|---|---|---|
| `BF.HEIGHT.REFERENCE` | adult standing height, **sexed**, cm | with mass, defines the reference body |
| `BF.BSA.REFERENCE` | body surface area of the reference individual, m² | de-indexes indexed literature |
| `BF.SIZE.EXPONENT` | `d ln BSA / d ln mass` across adults | replaces the exponent 1 in `size_factor` |

**`BF.SIZE.EXPONENT` IS THE ONE THAT CHANGES BEHAVIOUR.** The other two are bookkeeping
that lets indexed data be used; this one alters every population result.

---

## 3. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** non-pregnant adults aged 20+, measured height and weight (not self-reported).
**Exclude:** pregnancy, and nothing else — the exponent is a property of the adult
population as it is, and trimming it to the healthy subset would describe a population
nobody samples from.

**THE BSA FORMULA MUST BE PUBLISHED, CITED, AND VALIDATED AGAINST DIRECT MEASUREMENT.**
Several exist and they disagree by a few per cent. **The choice rule is fixed here:** take
the one with the largest direct-measurement validation sample that could be opened; where
two are comparable, take the older and more widely used, because the point of a BSA row is
to make INDEXED literature usable and indexed literature was overwhelmingly indexed with
DuBois. **Record the alternatives and the spread between them.**

**Directive 1.7's form here.** BSA formulas are mostly re-derived in oncology, for
chemotherapy dosing, and in paediatric burns. Prefer a derivation against directly
measured surface area in adults.

---

## 4. DIRECTIVE 1.12

Round numbers to expect: BSA 1.73 m² (the renal indexing convention), height 170 cm,
exponent 2/3 (the geometric surface law) or 0.75 (Kleiber). **None is entered because it
is familiar.** 1.73 m² in particular is a 1928 convention, not a measurement of anyone,
and if the reference individual's BSA comes out near it that is a coincidence worth
stating rather than a confirmation.

---

## 5. THE FORM

    size_factor(m) = (m / m_ref) ^ k          for BSA-like quantities
    mass_factor(m) =  m / m_ref               for volume-like quantities

**`k` is `BF.SIZE.EXPONENT`, obtained by regressing `ln(BSA)` on `ln(mass)` across adults**
— not by algebra on the BSA formula's own exponents, because that would need the
height–mass relation anyway and would hide it.

**ONE EXPONENT FOR EVERY BSA-LIKE QUANTITY, AND THAT IS A LUMPING.** Glomerular filtration
tracks surface area; metabolic rate tracks something nearer mass^0.75; dietary intake
tracks metabolic rate. Giving them different exponents would break the sodium and water
balances — the model's closure requires intake and clearance to scale together — and the
model has no evidence for the difference. **Collapsing them to one exponent is recorded as
a lumping, and the consequence is that this model cannot represent the real, small rise in
arterial pressure with body size.**

---

## 6. WHICH PARAMETERS MOVE, DECIDED NOW

**BSA-like** — everything in the sodium, water and metabolic chain, because the closure
requires them to scale together: glomerular filtration and the pressure-natriuresis
slope, urinary solute load and its non-sodium residual, sodium and water intake, stroke
volume (and therefore cardiac output), peripheral resistance as the reciprocal, CO2
production, the chemoreflex slope and basal ventilation.

**Mass-like** — the fluid compartments and their contents: extracellular, intracellular
and blood volumes, the intracellular osmole content, the reference blood volume.

**Neither** — every intensive quantity, unchanged.

---

## 7. THE DECISION RULE

- **S1 — the exponent lands between 0.5 and 0.9.** Adopt it. Rewrite `scaling.jl`'s
  closure argument, re-derive nothing else, and let the body-size testset's MAP-invariance
  assertion be the guard.
- **S2 — it lands outside that.** Something is wrong with the extraction, not with human
  physiology. Report and do not adopt.
- **S3 — the reference individual moves.** It must not: `size_factor(m_ref) = 1` for any
  exponent, so every existing result is bit-identical by construction. **If any pinned
  number in the suite moves, the change has touched something it should not have.**
- **S4 — MAP stops being invariant across body mass.** The closure has been broken. Fix
  the closure; do not adjust a parameter to restore the invariance.

---

## 8. WHAT THE ANSWER MAY NOT DO

- It may not change any value at the reference mass. **Bit-identical, not close.**
- It may not give different exponents to different quantities in the sodium or water
  chain, which would break the balances (§5).
- It may not use the 1.73 m² indexing convention as a measurement of anything.
- It may not report the population spread of glomerular filtration or cardiac output as
  validated until something is actually compared against a measured spread — **narrowing
  a spread is not the same as making it right**, and this pass changes the exponent
  without testing the result against data.
