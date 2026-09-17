# Pre-registration — segmental sodium handling, from micropuncture

**Written 2026-09-17, before any source is opened and before any segmental fraction is
computed.** Verify the ordering with

    git log --diff-filter=A -- validation/nephron_segments_prereg.md
    git log --diff-filter=A -- validation/nephron_segments_extract.py

Opened at the owner's instruction: the model has micropuncture data available to it and
the tubule is one lumped fraction. Finish the cardio-renal relationships.

---

## 0. THE PREVIOUS SEARCH LOOKED FOR THE WRONG INSTRUMENT

`RN.NA.PROXIMAL_FRACTION = 0.90`, `assumed`, tier C. Its own note:

> *ASSUMED, AND IT IS A ROUND TEACHING NUMBER … Searches for segmental sodium handling in
> healthy humans return lithium-clearance studies in cirrhosis, heart failure and
> hypertension; directive 1.7's sixth subsystem.*

**It searched for LITHIUM CLEARANCE IN HEALTHY HUMANS. It did not search for
MICROPUNCTURE.** Micropuncture is the instrument that measures fractional delivery out of
a named tubular segment — TF/P inulin at end-proximal, at early distal, at late distal —
and it has existed since the 1960s.

**AND IT IS ADMISSIBLE UNDER THIS REPOSITORY'S OWN RULE.** `CLAUDE.md`: *"Judge sources on
study quality, not species. Animal data is legitimate where the human experiment cannot
ethically be performed. Record species, preparation and range."* **Micropuncture cannot be
performed in humans.** It is the paradigm case that rule was written for, and excluding it
on species grounds is what left this row at a teaching number.

**This is §3.19's shape a second time** — *"THE EARLIER SEARCH MISSED IT BY LOOKING FOR THE
WRONG OBJECT"*, recorded when `G_vr` turned out to be `dCO/dV_blood` and not a compliance.

## 0.1 AND THE ROW IS MISNAMED, WHICH IS §3.2's FAILURE MODE FOR THE THIRD TIME

`Renal.jl`:

    Na_distal ~ Na_filtered * (1.0 - FR_prox) * renal_mod
    md_drive  ~ (Na_distal_ref - Na_distal) / Na_distal_ref

`md_drive` is the **macula densa** signal, and the macula densa sits at the **end of the
thick ascending limb** — after the proximal tubule *and* the loop. So `1 - 0.90 = 10%`
delivery is **proximal plus loop combined**, not proximal. Conventional proximal
reabsorption is about two thirds; the loop takes most of the rest.

**`RN.NA.PROXIMAL_FRACTION` is not a proximal fraction.** It is the pre-macula-densa
fraction wearing a proximal name, and every reader of that row has been told something
false about which segment it describes.

---

## 1. THE QUANTITIES

| id | segment | what micropuncture gives |
|---|---|---|
| `RN.NA.PROXIMAL_DELIVERY` | end of proximal convoluted tubule | fraction of filtered Na remaining |
| `RN.NA.LOOP_DELIVERY` | end of thick ascending limb = **macula densa** | fraction remaining — **this is what the model actually needs** |
| `RN.NA.DISTAL_DELIVERY` | end of distal convoluted tubule | fraction remaining |
| `RN.NA.FRACTIONAL_REABSORPTION` | whole nephron | **DERIVED and stays derived** — it closes sodium balance |

**THE SECOND ROW IS THE PRIZE.** It is the one `md_drive` reads and the one the model
currently assumes.

---

## 2. WHAT THIS BUYS THAT IS NOT JUST A SOURCED ROW

**`RN.MD.RENIN_GAIN` IS CURRENTLY NOT SEPARATELY IDENTIFIABLE FROM THIS NUMBER**, and
`RN.NA.PROXIMAL_FRACTION`'s own note says so: *"IT IS NOT SEPARATELY IDENTIFIABLE FROM
RN.MD.RENIN_GAIN, AND THAT IS WHY AN ASSUMED VALUE IS TOLERABLE HERE."*

`md_drive` is a **fractional deviation** of distal delivery from its reference, so the
reference scales out of the steady state and only the product of the delivery fraction and
the renin gain is identified by van den Bosch's salt–renin ratio. **Sourcing the delivery
fraction independently breaks that degeneracy and makes `RN.MD.RENIN_GAIN` a measurable
quantity for the first time** — which is worth more than the row itself.

---

## 3. WHAT MAY NOT MOVE

- **Sodium balance at the reference.** `RN.NA.FRACTIONAL_REABSORPTION` is DERIVED to make
  excretion equal intake and it stays derived. Whole-nephron reabsorption is **not** the
  sum of the segmental fractions here; it is a closure quantity, and conflating the two
  would break the operating point.
- **`CV.ANP.NATRIURETIC_GAIN` and `RN.PRESSURE_NATRIURESIS.SLOPE`.** §3.40 measured
  `G_anp` carrying 45% of the model's salt-sensitivity sensitivity.
- **`RN.GFR.NOMINAL`, `BF.NA.PLASMA_SETPOINT`, `BF.NA.INTAKE_NOMINAL`.**
- **The chronic salt sensitivity must stay inside the human 1.70–2.30 mmHg per 100
  mmol/day.** It is 1.97 today.
- **It may not re-solve `RN.MD.RENIN_GAIN` against van den Bosch in the same pass that
  sources its partner.** See E4.

---

## 4. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED IN ADVANCE

**67%** proximal. **25%** loop. **5%** distal convoluted. **3%** collecting duct.
**90%** pre-macula-densa. **99%** whole-nephron. **All are teaching figures**, they are
taught as a set that sums to 100, and this repository's record on such numbers is four
materially wrong of six openable. **The 0.90 in the ledger today is one of them.**

---

## 5. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** micropuncture in **normal, euvolaemic, anaesthetised** rat or dog on a normal
sodium intake, free-flow (not stopped-flow, not microperfusion), with TF/P inulin or an
equivalent volume marker reported. **Record species, preparation, anaesthetic and
hydration state on every row** — hydration is the variable that moves proximal
reabsorption most, and a volume-expanded preparation is a different animal.

**Exclude:** volume expansion or contraction as the experimental condition, diuretics,
hypertensive or diabetic strains, micropuncture of superficial nephrons presented as
whole-kidney without saying so.

**THE SUPERFICIAL-NEPHRON CAVEAT MUST BE ON THE ROW.** Micropuncture reaches surface
nephrons only. Deep juxtamedullary nephrons have longer loops and handle sodium
differently, so a surface measurement is not a whole-kidney fraction, and saying so is not
optional.

**HUMAN CROSS-CHECK, NOT POOLED:** lithium clearance gives an end-proximal fraction in
humans. Where a healthy normotensive series exists, record it as corroboration **beside**
the micropuncture value, never averaged with it — different method, different species,
`pooling.md` rule.

---

## 6. THE DECISION RULE

- **N1 — micropuncture sources the end-of-loop (macula densa) fraction in a normal
  preparation.** Enter it, rename the row to what it measures, and re-derive
  `Na_distal_ref`.
- **N2 — it sources the end-proximal fraction but not the end-of-loop one.** Enter the
  proximal row for its own sake, **and keep the pre-macula-densa fraction assumed** but
  correctly named. A proximal number does not substitute for the one the model reads.
- **N3 — the sourced fraction differs materially from 0.90.** Then `md_drive`'s reference
  moves, and because only the PRODUCT with `RN.MD.RENIN_GAIN` is identified, the salt–renin
  ratio moves with it. **Report the new ratio. Do not re-solve the gain in this pass** —
  that is the degeneracy this work exists to break, and breaking it and immediately
  re-fitting across it would waste the result.
- **N4 — the model's chronic salt sensitivity leaves 1.70–2.30.** Stop. Something
  load-bearing has moved and the segmental change is not licensed to do that.
- **N5 — nothing admissible.** Record INDETERMINATE with the exact terms per §3.33, **and
  still rename the row**, because the naming defect is real whatever the search returns.

---

## 7. THE FALSIFIABLE TESTS

1. **The operating point is unchanged.** Sodium excretion equals intake at the reference;
   MAP, GFR and plasma sodium unmoved. The segmental split is a decomposition of a
   quantity the model already had.
2. **The row's name matches the segment it measures**, and `Renal.jl` reads the
   macula-densa fraction where it reads a macula-densa signal.
3. **Chronic salt sensitivity stays inside 1.70–2.30 mmHg per 100 mmol/day.**
4. **THE OUT-OF-SAMPLE TEST, AND IT IS THE ONE THAT MATTERS.** The model predicts a **+79%**
   acute fractional sodium excretion rise on 23 mL/kg of isotonic saline against Jensen
   2013's **+123%** — a third low, and §4 item 2 records it as the only number in the
   sodium limb that was held out of every estimation. **If a sourced distal delivery moves
   it toward 123%, that is the first genuine out-of-sample gain this limb has made.** If it
   moves away, say so.
5. **The segmental fractions are internally consistent**: each is less than the one
   upstream of it, and none exceeds the whole-nephron reabsorption.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Sourcing a proximal number and quietly using it where the model needs an end-of-loop
one.** The row is already misnamed; replacing an assumed 0.90 with a sourced 0.67 in the
same slot would be worse than leaving it, because it would be wrong *and* cited.

**Breaking the identifiability degeneracy and then re-fitting across it.** `RN.MD.RENIN_GAIN`
and this fraction are currently one composite. The whole value of sourcing one is that the
other becomes measurable; re-solving the gain against van den Bosch in the same pass puts
the composite straight back.

**Taking a volume-expanded micropuncture preparation as normal.** Proximal reabsorption
falls with volume expansion — that is what the technique is most used to demonstrate — so
the literature is full of expanded animals. A number read off one of those is the
model's own perturbation, entered as its baseline.
