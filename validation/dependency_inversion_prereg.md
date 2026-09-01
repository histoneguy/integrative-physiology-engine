# Pre-registration: two inverted dependencies — stroke volume, and maximal urine concentration

**Written BEFORE any source was opened.** Date: 2026-09-01.

One pre-registration for both branches rather than two, per directive 1.10. The
defect is the same shape in both and the decision procedure differs only in the
literature it points at; two documents would be duplication, not rigour. Same
precedent as `verify_rows_prereg.md`, which covered six rows in one.

HANDOVER §4 item 1. Both targets came out of branch 6 of
`verify_rows_prereg.md`, which demoted them to `assumed` with empty citations and
recorded in each row that its dependency is backwards.

## The targets

| row | value | method now | derived FROM | what is actually MEASURED |
|---|---|---|---|---|
| `CV.SV.NOMINAL` | 80.7 / 77.0 mL | `derived` | `CV.CO.NOMINAL`, `CV.HR.NOMINAL` | stroke volume, by echo and CMR |
| `CV.CO.NOMINAL` | 7200 L/day | `assumed`, citation empty | — (the conventional 5 L/min) | computed as HR × SV |
| `ADH.URINE.OSM_MAX` | 1200 mOsm/kg | `derived` | `RN.URINE.SOLUTE_LOAD`, `RN.H2O.OBLIGATORY_LOSS` | maximal concentrating ability, by water deprivation |
| `RN.H2O.OBLIGATORY_LOSS` | 0.5 L/day | `assumed`, citation empty | — (the conventional 0.5 L) | follows from U_max and the solute load |

In each pair the ledger derives the **measured** quantity from the **computed**
one. The arithmetic is not wrong; the direction is. A derivation that runs
against the measurement cannot be improved by sourcing, because the row that
would carry the source is the one being computed.

## What the model already says, and it disagrees with the ledger

`Renal.jl:84` records that `V_min` is **deliberately no longer a Julia
parameter**. Since the solute load began tracking sodium (2026-08-27) the
obligatory volume is not an independent number, and the component computes it as
`Osm_load / U_max`. Nothing in `src/` reads `RN.H2O.OBLIGATORY_LOSS`;
`tools/check_closure.py` is its only consumer, and it uses it to derive `U_max`
— the opposite direction to the code.

**So branch B is a ledger-and-gate correction that the model has already made.**
Its only new content is whether `U_max` can be sourced. This is directive 1.11:
the defect was found by connecting the solute load, not by any gate, and the gate
is now asserting a relationship the model no longer uses.

## Overdetermination, fixed in advance

`CO = HR × SV` is an identity. **At most two of the three may be sourced; the
third is derived.** `CV.HR.NOMINAL` is sourced and sexed (Gonzales 2023, Fenland).
Therefore:

- If a stroke volume is adopted, **`CV.CO.NOMINAL` becomes `derived`** as
  `HR0 · SV0 · 1440 / 1000`. It is not sourced in this pass.
- **If a candidate paper reports both SV and CO, the stroke volume is taken and
  the cardiac output is derived.** The paper's own CO is recorded in the note as
  a consistency check and is *never entered as the row value*. Taking both would
  overdetermine the operating point and hide the disagreement inside a rounding
  tolerance.

Consequence for significant figures, and it inverts with the dependency:
directive 1.9 and the `CV.SV.NOMINAL` note require that a **derived row closing an
identity carries every digit**, while a reported row carries its source's figures.
After the flip that rule moves from `SV0` to `CO0`.

## Branch A — decision procedure for stroke volume, first match taken

1. **≥ 2 independent human primary studies** reporting resting stroke volume in
   healthy adults **by sex**, with n and dispersion, **by the same technique** →
   `pooled-inverse-variance`.
2. **≥ 2 with n but no dispersion** → `pooled-n-weighted`.
3. **Exactly 1** → `single-source`, k = 1, said plainly, as `CV.HR.NOMINAL` already
   does.
4. **Only stroke INDEX (mL/m²), with no absolute value and no cohort BSA** →
   **unusable for this row.** Converting an index to an absolute value requires a
   body surface area, which this model does not carry (§4 item 5). Record the
   source and the obstruction; do not manufacture a BSA.
5. **Nothing openable** → **nothing changes.** `CV.SV.NOMINAL` stays `derived`,
   `CV.CO.NOMINAL` stays `assumed` with an empty citation, and the attempts are
   appended to the row so the next attempt does not repeat them — the same
   discipline that row already applies to Rusinaru 2021, Bruce 1962 and
   Patel 2021. **A remembered number is not a source.**

### Technique, fixed before any number is seen

`pooling.md` prohibits pooling across incompatible measurement methods, and
Patel 2021 states outright that Doppler, 2D and 3D echocardiographic values are
**not interchangeable**. Doppler, 2D echo, 3D echo and CMR are four techniques,
not four measurements of one thing.

**Declared preference order: CMR or 3D echo > 2D echo > Doppler.** Volumetric
methods measure the ventricular volume difference directly; Doppler infers it
from an LVOT cross-section and a velocity–time integral, so it inherits the
area's squared error. This is a judgement about the method, made before seeing
which method gives which number. The adopted technique is recorded in the row.

### Body-size normalisation — the trap, and the rule

`SV0` is **extensive** and is multiplied by `size_factor = body_mass / 70` in
`Cardiovascular.jl`. The ledger's extensive constants are stated at
`BF.BODY_MASS.REFERENCE = 70 kg`, which is a normalisation convention, not a
claim about how much people weigh.

A sourced absolute stroke volume belongs to **its cohort's** body size. Entering
one raw would state the row at a mass its own source never used — precisely the
error the `BF.BODY_MASS.REFERENCE` note warns about for GFR. Worse, the ensemble
samples body mass **by sex**, so a sexed absolute SV would count the size
dimorphism **twice**: once in the row and once in `size_factor`.

**Declared rule, before numbers:**

- If the source reports cohort body mass by sex → the row is entered
  **normalised to 70 kg** as `SV × 70 / m_cohort`, and what the sexed pair then
  claims is the residual difference *after* body size.
- If it reports BSA but not mass → normalisation is **not** attempted, because
  mass-from-BSA needs height. Value entered as reported, mismatch recorded as
  debt in the row and in HANDOVER §7.
- If it reports neither → entered as reported, same debt recorded. **Not**
  silently corrected against an assumed cohort mass.

### Predicted outcome, recorded so that it can be wrong

`CV.SV.NOMINAL`'s own note cites Katori 1979: no significant sex difference in
cardiac **index** or stroke **index** once normalised to body surface area, while
Eikendal 2016 finds absolute cardiac output lower in women. If those hold, then
after mass normalisation **the sexed pair should shrink substantially and may
collapse toward a shared value** — the same result the blood-volume and
haematocrit pass produced for ECF per kg (HANDOVER §2), where a 2.4% sex
difference turned out to be an artefact and the dimorphism moved to where it is
measured.

If instead the normalised pair stays widely separated, that is a claim about the
**heart** rather than about body size, and it must be stated as such rather than
absorbed quietly into the row.

## Branch B — decision procedure for maximal urine osmolality, first match taken

1. **Human primary** reporting maximal urine osmolality after water deprivation
   or DDAVP in **healthy adults**, with n and dispersion → take it. Record the
   protocol: deprivation duration, DDAVP or not, and the **age band**.
2. **≥ 2 such studies, same protocol class** → pooled per `pooling.md`.
3. **Only paediatric, clinical, concentrating-defect or disease cohorts** → not
   usable. This is what the 2026-08-31 search already returned for the obligatory
   volume; the row records it.
4. **Nothing openable → the inversion happens anyway.**
   `ADH.URINE.OSM_MAX` becomes `assumed` at its present 1200 with the derivation
   removed, and `RN.H2O.OBLIGATORY_LOSS` becomes `derived` as
   `RN.URINE.SOLUTE_LOAD / ADH.URINE.OSM_MAX`.

Branch 4 is the point of doing this at all. It **moves no number** — 600/0.5 and
600/1200 are the same two facts read in either order — and the `assumed` count is
**unchanged**, one row leaving `derived` as another enters it. What it buys is
that the primitive sits where the measurement is, so the row that needs a source
is the row a source could actually discharge, and the gate stops asserting a
direction the model contradicts.

### Age, stated in advance

Maximal concentrating ability declines with age, and this model has no age
dimension. Whatever is adopted, the cohort age band is recorded. A young-male-only
value is a **population mismatch** to be written down, not a free choice.

### If `U_max` moves

`ADH.OSM.SENSITIVITY` is derived from it and every steady state moves with it.
**Do not prefer a source because its number is near 1200.** Directive 1.12: 1200
mOsm/kg and 0.5 L/day are round teaching-aid figures and are presumptively
unsourced, whatever the ledger claims.

## What is expected to move, fixed in advance

**Unchanged by construction.** MAP at the nominal operating point: `TPR0` is
derived as `MAP0/CO0`, so any `CO0` reproduces `MAP0 = CO0 · TPR0`. Likewise
SBP/DBP at nominal: `C_art` is derived as `SV0/PP0`.

**Falsifiable prediction, and this is the load-bearing one.** §3.5 established
that `MAP − MAP_ref = (intake − 205)/G_pn`, so the salt-step shift is set by
`G_pn` **alone**. Therefore:

> Changing `CO0` and `TPR0` should leave the salt-step MAP shift essentially
> invariant, while the ECF and blood-volume **excursion** required to produce it
> moves in proportion to `CO0` (inversely to `TPR0`).

If the MAP shift moves by more than the ±0.02 mmHg the existing regression pins
allow, either §3.5 is wrong or the loop is not what it is believed to be.
**Investigate before repinning.** A repin that quietly absorbs a real change is
the failure this prediction exists to catch.

**Expected to move for real:** `CV.CO.NOMINAL`, `CV.TPR.NOMINAL`,
`CV.ARTERIAL.COMPLIANCE`, and — if `U_max` is sourced and moves —
`RN.H2O.OBLIGATORY_LOSS`, `ADH.OSM.SENSITIVITY` and every steady-state level.

## Test and gate consequences, named in advance

- `test/runtests.jl` "the HR/SV pair cannot move the model, and that is expected"
  asserts the male and female salt-step shifts are identical, and its own comment
  says **it should FAIL when a real pair lands, and be replaced rather than
  deleted.** A sourced sexed `SV0` makes `CO0` sexed, which is that moment.
- The ADR 0011 identity test compares `HR0 · SV0 · 1440/1000` against a shared
  `CV.CO.NOMINAL`; it becomes a per-sex identity.
- `check_closure.py`: "stroke volume from CO and heart rate" is unchanged as an
  identity but its explanation reverses; "max urine osmolality from obligatory
  volume" reverses outright.
- ADR 0011 and ADR 0014 both carry text asserting that the SV dimorphism is
  inherited from heart rate. That stops being true and the ADRs must say so.

## Out of scope

- `G_pn` / ADR 0013 — parked at the owner's decision.
- Body surface area and height (§4 item 5). Named here because branch A's
  normalisation would be cleaner with it; it is still **not** being done, and no
  BSA formula is introduced as a side effect.
- Venous compliance and `G_vr` (§4 item 2).
- `RN.URINE.SOLUTE_LOAD = 600 mOsm/day`, the unsourced parent. Branch B derives
  against it and **inherits its weakness**; correcting it moves `U_base`, `k_adh`
  and every steady state and needs its own pre-registration.
- The chronotropic baroreflex.

## Constraints inherited, restated because they bind here

- **Directive 1.5.** 5 L/min, 1200 mOsm/kg and 0.5 L/day are exactly the numbers
  everyone "knows". Recalling one is not opening a source.
- **Directive 1.12.** All three are round. Expect them to be wrong, and budget
  for it.
- **Directive 1.8.** Cast a wide net. It has now paid twice, most recently on
  `RN.AUTOREG.LOWER`, where sweep 1 returned a clean human answer and sweep 2
  returned the paper contradicting it.
- **`pooling.md`.** `range-midpoint` prohibited for new entries — which already
  cost this ledger Rusinaru 2021, a 4,040-adult normative study that reports only
  limits. No pooling across species or techniques.
- **ADR 0014.** A dimorphic row becomes a male/female **pair** or stays `both`.
  Never one sex alone.
