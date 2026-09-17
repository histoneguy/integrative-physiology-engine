> # VOIDED AND UNEXECUTED — 2026-09-17
>
> **This pre-registration was written against a stale number and must not be executed as
> written.** It states that the model is at **+79.3%** against Jensen 2013's +123% and
> treats closing that deficit as its purpose. **There is no such deficit.** Measured like
> for like on Jensen's own 210–240 min window the model is at **+110.1%** against a
> measured **+122%** — see HANDOVER §3.45, which also records that the +79.3% figure was
> twelve days stale and that the comparison behind it set a model PEAK against a study's
> FINAL SAMPLE.
>
> **It is committed rather than deleted for three things it contains that survive:**
> Alexander 1972 (PMID 4639021) and its human acute/chronic segmental asymmetry; the
> §5.1/§3.4 algebra showing what is and is not identifiable in this model; and the record
> that two passes were pre-registered before anyone ran the thing they were about, which
> is directive 1.11's failure in its clearest form.
>
> **Nothing in it was executed. No value it proposes entered the ledger.**

> Its §3.4 finding — that a plasma-protein term is collinear with the existing
> volume-keyed path unless `G_onc` is independently sourced — stands on its own and
> is worth keeping whatever motivates the next pass.

# Pre-registration — plasma protein dilution, peritubular oncotic pressure, and the acute natriuresis

**Written 2026-09-17, before any source on peritubular oncotic pressure is opened, before
any sensitivity is extracted, and before the term has been run once.** Verify the ordering
with

    git log --diff-filter=A -- validation/oncotic_proximal_prereg.md
    git log --diff-filter=A -- validation/oncotic_proximal_extract.py

**Opened at the owner's instruction**, who re-scoped to this route rather than execute
`validation/segmental_regulation_prereg.md` to its predicted S4 verdict. That document is
committed **unexecuted**; its §5.4 named this pass in advance, and its S4 prediction
stands as a recorded, untested prediction rather than a result.

---

## 0. THE ASYMMETRY THIS PASS EXISTS TO REPRESENT

Alexander EA, Doner DW Jr, Auld RB, Levinsky NG. J Clin Invest 1972;51(9):2370-2379.
PMID 4639021. **ABSTRACT READ IN FULL; the full text is scanned page images on both PMC
and jci.org and could not be transcribed**, so subject count, baselines, infusion rate and
the mineralocorticoid protocol are NOT KNOWN TO THIS PASS.

> *"both acute and chronic extracellular expansion decrease proximal FSR in man, but only
> acute loading depresses distal FSR."*

Acute isotonic saline 37 mL/kg: proximal FSR **-4.8%**, distal **-4.4%**. Chronic
mineralocorticoid expansion: proximal **-3.9%**, distal **unaltered**.

**THE MODEL'S SODIUM LIMB WAS ESTIMATED AGAINST CHRONIC DATA** — `CV.ANP.NATRIURETIC_GAIN`
solved for a chronic salt sensitivity of 2.00 mmHg per 100 mmol/day,
`RN.PRESSURE_NATRIURESIS.SLOPE` calibrated — and it is a third low on the one acute number
held out of every estimation: **+79.3% against Jensen 2013's +123%.**

**The mechanism proposed here is not a rearrangement of regulators. It is a quantity the
model does not have.** Acute isotonic saline **dilutes plasma protein**; chronic salt
loading, at the same sodium load, dilutes it roughly a third as much, because the volume
excursion is roughly a third as large. Peritubular capillary oncotic pressure is the
classical coupling from that dilution to proximal reabsorption.

## 0.1 THE REPOSITORY NAMED THIS GAP ITSELF AND THEN DID NOT SEARCH FOR IT

`RN.GFR.VOLUME_SENSITIVITY`'s ledger note, on the Jensen shortfall:

> *"The model therefore excretes MORE sodium and reports a SMALLER fractional rise.
> Whether that is right depends on glomerulotubular balance, **which this model does not
> represent, and nothing here sources it**."*

---

## 1. THE MODEL ALREADY HAS THE STATE, AND THAT IS CHECKED RATHER THAN ASSUMED

`Cardiovascular.jl`: `V_plasma ~ f_pv * V_ecf`. So plasma volume already moves with
extracellular volume, and **the model's plasma dilution on an acute load is already right**:

| | model | measured |
|---|---|---|
| plasma volume rise, 2 L of 0.9% saline | **+14.3%** | **+14.9%**, from Lobo 2001's 7.5% haematocrit fall with red cell mass fixed |

**That agreement is not a result of this pass and must not be reported as one.** It is a
pre-existing property of `f_pv`, and it is recorded here because it is the precondition:
if the model's plasma dilution were wrong, nothing keyed to it could be right.

The acute-versus-chronic ratio the term will see:

| manoeuvre | `V_ecf` excursion | protein dilution at constant mass |
|---|---|---|
| acute, 2 L isotonic saline | ~+14% | ~-13% |
| chronic, the 103 -> 205 mmol/day salt step | ~+4.3% | ~-4.1% |

**About 3.3 to 1.** That ratio is what produces Alexander's asymmetry, and it comes out of
quantities the model already has rather than from a new time constant.

---

## 2. THE FORM, FIXED BEFORE ANY SOURCE IS OPENED

    C_prot       ~ C_prot_ref * V_plasma_ref / V_plasma
    FR_effective ~ ... - G_onc * (1 - C_prot/C_prot_ref) / Na_filtered

**Plasma protein MASS is held constant.** Justification and its direction of error, stated
now: albumin turnover is days and transcapillary escape over the hours of an acute
challenge is small, so constant mass is a good approximation acutely. **Chronically it is
NOT** — protein mass re-equilibrates across the capillary wall, so holding it constant
**overstates** the chronic dilution and therefore **overstates** the chronic action of this
term. **The error is in the direction that makes this pass look worse, not better**, and
the write-up must say so rather than discovering it later.

`G_onc` is **one** new parameter. It is the whole risk of this pass and §3 is about
sourcing it.

---

## 3. THE IDENTIFICATION PROBLEM IS THE PASS, AND IT IS STATED BEFORE THE SEARCH

**`G_onc` MUST BE SOURCED FROM A PREPARATION THAT IS NOT THE ACUTE NATRIURESIS IT IS MEANT
TO EXPLAIN.** A gain fitted to Jensen, to Lobo, or to Alexander's acute arm and then
reported as explaining the acute natriuresis is failure mode 22 and would be worthless.

**The admissible instrument, fixed now:** a preparation in which peritubular protein
concentration or oncotic pressure is varied **directly** and proximal fluid or sodium
reabsorption measured — isolated perfused proximal tubule, or free-flow micropuncture with
the peritubular capillary perfused at controlled protein concentration.

**THE SENSITIVITY IS TAKEN IN DIMENSIONLESS FORM AND THIS IS WHY.** What transfers across
species and across preparations is the **elasticity** — the fractional change in proximal
reabsorption per fractional change in peritubular protein concentration (or oncotic
pressure). Taken that way, no nephron number, no single-tubule flux and no kidney-size
conversion is needed: `G_onc` is that elasticity multiplied by a baseline reabsorption the
model already computes. **A dimensional single-tubule flux would need three conversion
factors this repository would then have to source, and it is refused for that reason.**

### 3.1 CONCENTRATION OR ONCOTIC PRESSURE — DECIDED NOW, NOT AFTER

Oncotic pressure is strongly non-linear in protein concentration, so the choice changes the
effect size by roughly the exponent, about 1.7x over this range. **It is therefore fixed in
advance:** the elasticity is taken **against whichever variable the source preparation
actually controlled and reported.** If the source reports against oncotic pressure, a
Landis-Pappenheimer style relation is sourced separately and carried; if against protein
concentration, it is used directly and no conversion is invented. **Choosing the variable
after seeing which gives the better acute response is forbidden.**

### 3.2 THE LITERATURE IS CONTRADICTORY AND THE NULLS ARE ADMISSIBLE

Already known before the search, and declared: **some preparations report no detectable
effect of peritubular protein concentration on proximal reabsorption, while a substantial
body of work reports a clear one.** This is not a case where the positive studies are the
findable ones and the nulls are absent.

**A null preparation meeting the admissibility rules is evidence and is reported beside the
positive ones, never excluded for being inconvenient.** If the admissible set straddles
zero, that is the finding — branch O4 — and this model does not get the term.

### 3.3 SPECIES

Micropuncture and isolated tubule perfusion **cannot be performed in humans**. Per
`CLAUDE.md`, that makes animal data legitimate here with species, preparation and range
recorded on the row. **Hydration state must be recorded on every row**: a volume-expanded
preparation has the perturbation of interest already applied, which is §8's named failure.

### 3.4 THE TERM IS COLLINEAR WITH THE EXISTING VOLUME-KEYED PATH, AND THAT IS FOUND HERE RATHER THAN AFTER IT IS BUILT

**Worked out before writing a line of Julia.** `V_plasma ~ f_pv * V_ecf` with `f_pv`
constant, and plasma protein mass is constant, so

    C_prot / C_prot_ref  =  V_plasma_ref / V_plasma  =  V_ecf_ref / V_ecf

**`f_pv` cancels, and so does `C_prot_ref`.** The proposed term reduces to

    - G_onc * (1 - V_ecf_ref/V_ecf) / Na_filtered

which for small excursions is `G_onc * (V_ecf - V_ecf_ref)/V_ecf_ref / Na_filtered` — **the
same functional form as `anp_sig`'s target** `G_anp*(V_blood - V_blood_ref)`, since
`V_blood = f_pv*V_ecf + V_rbc` and `V_rbc` is slow.

**SO IN THIS MODEL, AS STRUCTURED, THE ONCOTIC PATH AND THE VOLUME-KEYED PATH ARE THE SAME
PATH TO FIRST ORDER.** The physiological distinction — protein is confined to plasma,
infused saline is not — is erased by holding `f_pv` constant. **This is the
`RN.MD.RENIN_GAIN` degeneracy in a new place**, and if both gains were estimated the pass
would land on a re-parameterisation exactly as the segmental one was predicted to.

**THAT IS WHY §3's SOURCING REQUIREMENT IS THE WHOLE PASS AND NOT A FORMALITY.** Collinearity
is fatal only if **both** gains are free. If `G_onc` is sourced independently from a
preparation that varies peritubular protein directly, then the model becomes **more**
constrained, not less: a previously free gain acquires a fixed partner, and the acute
behaviour stops being adjustable. **If `G_onc` ends up fitted, this pass has achieved
nothing and must say so.**

### 3.5 THE TWO THINGS THAT DO SEPARATE THEM, FIXED IN ADVANCE AS TESTS

1. **TIME.** The oncotic term is **instantaneous** — dilution is immediate. `anp_sig` carries
   a first-order lag `RN.ANP.TAU`, about 0.17 d. Jensen's peak is at 210-240 min. An
   instantaneous term therefore produces an **earlier and higher** peak, which is a
   prediction about the SHAPE of the acute response and not only its size. **Report the time
   to peak, not just the peak.**
2. **WHICH VOLUME.** The oncotic term is keyed to **plasma** volume; the ANP term to **blood**
   volume. Those differ by red cell volume, and `V_rbc` became a state in ADR 0023. **They
   separate whenever red cell mass moves independently of plasma** — haemorrhage, and the
   anaemia the erythropoiesis limb now represents. **`validation/challenges.jl`'s haemorrhage
   case is therefore a discriminator between the two paths and must be reported**, even
   though nothing in it was used to set either gain.

**If neither discriminator moves, the two paths are indistinguishable in every behaviour this
model produces, and the honest report is that the oncotic term is the volume-keyed term
under another name.**
---


## 4. WHAT MAY NOT MOVE

- **`RN.NA.FRACTIONAL_REABSORPTION` stays DERIVED** to close sodium balance at the reference.
- **`RN.GFR.NOMINAL`, `BF.NA.PLASMA_SETPOINT`, `BF.NA.INTAKE_NOMINAL`, `CV.ECF.PLASMA_FRACTION`
  (`f_pv`).** `f_pv` in particular: it sets the plasma dilution this whole term is keyed to,
  and tuning it would be tuning the input to make the output come right.
- **JENSEN 2013 MAY NOT ENTER ANY ESTIMATION IN ANY FORM.** It is read out afterwards and
  never read in.
- **`RN.ANP.TAU` is fixed by Lobo's 6 h time course.** If `G_onc` changes the acute
  trajectory enough that Lobo no longer fits, **report it; do not re-solve tau to absorb
  it.** Re-solving the lag against Lobo while a new acute term is being judged against
  Lobo's own protocol class is the double count this repository keeps catching.
- **`RN.MD.RENIN_GAIN` and `RN.NA.MACULA_DENSA_FRACTION`** — inherited prohibitions from
  `nephron_segments_prereg.md`.
- **The chronic salt sensitivity must stay inside 1.70-2.30 mmHg per 100 mmol/day.**
- **`CV.ANP.NATRIURETIC_GAIN` and `RN.PRESSURE_NATRIURESIS.SLOPE` MAY be re-solved**, against
  their own unchanged estimation sets and against nothing else. This pass inherits that
  licence from `segmental_regulation_prereg.md` §3, which the owner re-scoped rather than
  revoked.

---

## 5. DIRECTIVE 1.12 — THE ROUND NUMBERS AND THE TEACHING SENTENCES

**7 g/dL** total plasma protein, **4 g/dL** albumin, **25 mmHg** plasma colloid osmotic
pressure, **20%** filtration fraction, **67%** proximal reabsorption. All are teaching
figures, and this repository's record on such numbers is four materially wrong of six
openable.

**And two hazards that are sentences rather than numbers:**
- *"Peritubular Starling forces govern proximal reabsorption."* Textbook, and §3.2 says the
  primary literature does not speak with one voice.
- *"Glomerulotubular balance keeps fractional reabsorption constant."* If it held exactly,
  this term could not exist. It is used here to name a phenomenon, never to supply a value.

---

## 6. THE DECISION RULE

- **O1 — an admissible elasticity is sourced, the chronic salt sensitivity stays inside
  1.70-2.30 after re-solving `G_anp`/`G_pn` against their own sets, and Jensen moves TOWARD
  123%.** Accept. Report the new figure and state that it is out-of-sample.
- **O2 — sourced and chronic recovered, but Jensen moves AWAY.** Report it in those words.
  Do not tune.
- **O3 — sourced, but the chronic salt sensitivity cannot be recovered inside 1.70-2.30 at
  any admissible `G_anp`.** Then the term is too strong chronically, which is the direction
  §2 predicted from constant protein mass. **Report it, and do NOT rescue it by adding a
  protein re-equilibration time constant in this pass** — that is a second new parameter and
  it needs its own pre-registration.
- **O4 — the admissible set straddles zero**, or every candidate preparation is
  volume-expanded, or the elasticity cannot be extracted in dimensionless form. **Record
  INDETERMINATE with the exact terms, enter nothing, and say what experiment would settle
  it.** The term is not entered on a mechanism that is plausible but unmeasured.
- **O5 — Jensen OVERSHOOTS 123%.** **Do not tune back.** An overshoot on a number that was
  not fitted is exactly as informative as an undershoot.
- **O6 — anything else leaves its band:** sodium balance at the reference, `dMAP/dV_ecf`
  outside 2.82-4.02, resting MAP or `V_ecf` outside their windows, or `FR_effective`
  hitting a clamp at the operating point. **Stop.**

---

## 7. THE FALSIFIABLE TESTS

1. **The operating point is unchanged.** At the reference, `C_prot = C_prot_ref` exactly, so
   the new term is **identically zero** and every existing steady state is bit-identical by
   construction. **This must be demonstrated by running, not asserted** — the same
   `G_anp = 0` style check ADR 0010 used.
2. **Chronic salt sensitivity inside 1.70-2.30.**
3. **`dMAP/dV_ecf` inside the corrected human band 2.82-4.02.**
4. **Lobo 2001's 6 h endpoints, 563 mL and 95 mmol.** **A fit residual, not a test**, because
   `RN.ANP.TAU` was estimated against that same time course. The write-up repeats that
   sentence rather than claiming a validation.
5. **THE OUT-OF-SAMPLE TEST.** Jensen's **+123%** against today's **+79.3%**. Report the new
   figure and whether it moved toward or away.
6. **THE STRUCTURE-VERSUS-REFIT DECOMPOSITION, MANDATORY.** Report Jensen **with the new term
   at the OLD gains, before any re-solve**, as well as after. Without both numbers there is
   no way to tell whether the acute response improved because plasma protein was represented
   or because `G_anp` came out larger.
7. **ALEXANDER'S PATTERN IS A TEST, NOT AN INPUT.** The term must act **more acutely than
   chronically**, in roughly the 3.3:1 ratio §1 computes. Report the model's proximal-side
   natriuretic term across (a) the chronic salt step and (b) the acute challenge. **None of
   Alexander's four numbers is used to set anything**, so this is the strongest test here and
   it is reported first.
8. **The acute/chronic ratio is a PREDICTION and is stated now: about 3.3 to 1.** If the model
   delivers something far from that, the term is not doing what this document says it does,
   whatever it does to Jensen.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Fitting `G_onc` to Jensen, to Lobo, or to Alexander's acute arm.** Named first. It is the
cheapest way to make this pass look successful and it would destroy the only out-of-sample
number the sodium limb has.

**Taking a volume-expanded preparation as the baseline.** Peritubular oncotic pressure
studies are overwhelmingly *about* volume expansion, so the literature is full of expanded
animals. A sensitivity read off one of those has the model's own perturbation built into its
reference.

**Reporting only the positive preparations.** §3.2 fixed in advance that the nulls are
admissible. A pass that returns a clean elasticity and does not say how many admissible
preparations found nothing has selected its evidence.

**Adding a protein re-equilibration time constant to rescue branch O3.** Two new parameters,
one of them introduced after seeing that one was not enough, is how a mechanism becomes a
curve fit.

**The quiet one: reporting the final Jensen figure without §7 item 6, or the suite being
green instead of §7 items 7 and 8.** The acute/chronic ratio is the claim. Jensen is the
test. The suite passing is the receipt.
