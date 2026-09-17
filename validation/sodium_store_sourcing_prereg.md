# Pre-registration — sourcing the sodium store's two parameters

**Written 2026-09-17, before any Titze or Rakova source is opened and before either row is
touched.** Verify the ordering with

    git log --diff-filter=A -- validation/sodium_store_sourcing_prereg.md
    git log --diff-filter=A -- validation/sodium_store_sourcing_extract.py

Opened at the owner's instruction, following `validation/sodium_store_prereg.md` branch
**S1**: *"report as a diagnostic, then SOURCE the two rows against primary literature."*

---

## 0. WHAT STAGE 1 LEFT, AND THE SECOND GAP IS ENORMOUS

| row | ledger | `assumed` since | stage 1's diagnostic |
|---|---|---|---|
| `BF.NA.OSMOTICALLY_INACTIVE_FRACTION` | **0.15** | 2026-08-08 | ≈ **0.40** |
| `BF.NA.STORAGE_TAU` | **7 days** | 2026-08-08 | ≈ **0.05–0.25 days** |

**The fraction is out by 2.7×. The time constant is out by a factor of about 30 to 140**,
and in the direction nobody would guess: the acute dissociation needs a store that fills
and empties in **hours**, while the row is set to a **week**.

**NEITHER NUMBER MAY BE ENTERED FROM THAT DIAGNOSTIC.** They are what the model needs to
reproduce Drummer, which is precisely what makes them inadmissible as values —
`sodium_store_prereg.md` §3: *"a value fitted to the 0.70 and then cited to Titze would be
the worst outcome available."*

## 0.1 AND THE TWO TIMESCALES MAY NOT BE THE SAME PROCESS — PREDICTED NOW

Both rows' own notes name their estimation set: **Rakova's Mars500 series**, whose
rhythmicity is **7-day and monthly**. `BF.NA.STORAGE_TAU`'s note says the 7 d was *"chosen
to match the reported weekly infradian rhythm period rather than derived from it."*

**Stage 1 wants hours. Rakova describes weeks.** A single first-order compartment cannot be
both, so one of three things is true, and **which one must be decided by the sources rather
than by which is convenient**:

1. there are **two** storage processes on different timescales, and the model has one;
2. the **acute** dissociation is not storage at all and stage 1's `f_store` ≈ 0.40 is a
   fitted artefact standing in for something else;
3. Rakova's weekly rhythm is not the same quantity as a buffering time constant.

**This is the pass's central question, and it is not "what is the value of τ".**

---

## 1. WHAT IS ALREADY KNOWN, DECLARED SO THE FREEDOM IS AUDITABLE

- **Rakova N et al., Cell Metab 2013;17(1):125–131 is already cited on both rows and in
  ADR 0004, and has never been opened in this repository.** What the ADR records from it —
  stepped 12 → 9 → 6 g/day NaCl, 12 men, daily complete collection, ~95% recovery, total
  body Na⁺ stored and not tightly coupled to extracellular water, 7-day and monthly
  rhythmicity — is second-hand and must be verified against the paper, not inherited.
- **ADR 0004 is `Provisional`, tier E3**, and its own tier line says the compartment is
  *"inferred not measured"*.
- Stage 1's diagnostics, above.
- Drummer's ratio 0.70, and Van Regenmortel's 48% (HANDOVER §3.48, §3.49, §3.50).
- **NOT known:** anything from a Titze primary. None has been opened here.

---

## 2. THE ESTIMATION SET AND THE TEST SET ARE ALREADY DIFFERENT, AND THAT IS THE DESIGN

**ESTIMATION — Rakova / Mars500 and the Titze balance literature.** Chronic, stepped
intake, 30–60 days per level. This is what both rows' notes already declare, so using it is
honouring an existing commitment rather than choosing a convenient set.

**TEST, HELD OUT — Drummer's acute half-life ratio of 0.70**, and Van Regenmortel's 48%.
**Neither may enter the estimation in any form.** Drummer is acute and Mars500 is chronic;
they are different protocols on different subjects, and that separation is what makes the
test worth anything.

**IF A SOURCE TURNS OUT TO BE BOTH — if a Titze paper reports an acute isotonic load as
well as chronic balance — ITS ACUTE ARM IS TEST AND ITS CHRONIC ARM IS ESTIMATION**, and
the split is declared in the extract before either is used.

### 2.1 ONE SOURCE'S ROLE IS FIXED HERE, BEFORE IT IS OPENED

**Olde Engberink RHG, Rorije NMG, van den Born BJH, Vogt L. Quantification of nonosmotic
sodium storage capacity following acute hypertonic saline infusion in healthy individuals.
Kidney Int 2017;91(3):738–745. PMID 28132715.** Identified as closed, then **supplied by
the owner on 2026-09-17. Not yet opened.**

**It is the only paper found that measures this row's quantity directly rather than by
inference**, so §3.2's caveat may apply to it more weakly than to the balance literature —
which is exactly why its role must be fixed before anyone reads it.

**IT IS AN ESTIMATION SOURCE, AND IT WEAKENS THE TEST, AND THAT IS DECLARED RATHER THAN
HIDDEN.** §2 puts chronic balance in the estimation set and holds Drummer's **acute**
ratio out. Olde Engberink is **acute hypertonic**. So:

- it is **a different manoeuvre** from Drummer (hypertonic against isotonic), **different
  subjects and a different group** — those keep it independent;
- but it **shares Drummer's timescale**, so a store parameterised from it is no longer
  being tested on an entirely unrelated regime.

**The write-up must say, in those words, that Drummer's ratio is a weaker test after this
source is used than it would have been after Mars500 alone.** A pass that quietly banks
Drummer as fully out-of-sample while estimating from an acute study has overstated its own
evidence.

**AND THE TONICITY DIFFERENCE IS NOT COSMETIC.** Hypertonic saline shifts water out of
cells and raises plasma sodium; isotonic does neither. A storage capacity measured under
hypertonic loading may not be the capacity available under isotonic loading, and **if the
paper's own discussion says so, that goes on the row.**

---

## 3. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** human balance studies with **complete** urine collection and a stated recovery
fraction; controlled or recorded intake; a duration long enough for the quantity claimed.
Animal work where the human experiment cannot be done, **with species, strain, preparation
and salt intake recorded** — ADR 0004's tier is E3 partly on that basis and it must not
silently improve.

**Exclude:** cross-sectional tissue sodium with no balance arm, as a source of a **fraction**
(see §3.1); studies in heart failure, renal failure or hypertension as a source of the
**normal** value; and anything where dietary sodium was not measured or controlled.

### 3.1 THE TRAP THAT WOULD BE EASIEST TO FALL INTO, NAMED IN ADVANCE

**²³Na MRI measures tissue sodium CONTENT. It does not measure an osmotically inactive
FRACTION.** Kopp, Linz and colleagues report skin and muscle sodium concentrations in
healthy and hypertensive people, and those numbers are quotable, striking, and **not this
row**. Converting a tissue concentration into an osmotically inactive fraction needs
tissue water measured alongside and an assumption about what "inactive" means.

**A number taken from a ²³Na MRI paper and entered on
`BF.NA.OSMOTICALLY_INACTIVE_FRACTION` would be failure mode #11 — a name carrying a
convention its value contradicts — and this document exists partly to stop it.**

### 3.2 AND THE SOURCE'S OWN QUANTITY IS MODEL-DEPENDENT

**"Osmotically inactive" is INFERRED from a balance discrepancy**, not observed. It is what
is left when measured sodium retention exceeds what the measured water retention can carry
at plasma tonicity. **So the source's number depends on the source's assumptions about
tonicity and about water balance**, and any row entered from it must say so in its note
and must stay tier B or below on that account alone.

---

## 4. DIRECTIVE 1.12 — AND ONE OF THEM IS ALREADY IN THE LEDGER

**7 days** — on the row now, and its own note admits it was *chosen to match* a reported
rhythm rather than derived from one. **0.15**, likewise a placeholder. **1/3 and 2/3** for
exchangeable versus non-exchangeable sodium. **40 mmol/L**, **140 mmol/L**, and the skin
sodium figures that get quoted as round numbers.

**And the slogan again: "sodium is stored in skin without water."** Named in the previous
pre-registration and repeated because this is the pass where it would do the damage.

---

## 5. WHAT MAY NOT MOVE

- **No natriuretic gain.** `CV.ANP.NATRIURETIC_GAIN`, `RN.PRESSURE_NATRIURESIS.SLOPE`,
  `RN.ANP.TAU`. Inherited from `sodium_store_prereg.md` §3 and for the same reason.
- **`storage` stays `false` by default.** Sourcing two rows does not license a structural
  change; ADR 0004 loses `provisional` only if §6's S-branches say so, and that is a
  separate decision with its own record.
- **Drummer's 0.70 and Van Regenmortel's 48% may not enter the estimation.**
- **The chronic salt sensitivity must stay inside 1.70–2.30** and `dMAP/dV_ecf` inside
  2.82–4.02, measured with `storage = true` at whatever is sourced.
- **Neither row may be entered `derived` on the strength of a single balance series.**
  ADR 0004 is tier E3 and §3.2 says why that does not improve just because a number was
  found.

---

## 6. THE DECISION RULE

- **T1 — a primary gives an osmotically inactive fraction in healthy humans with a
  balance arm.** Enter it with its species, protocol and the §3.2 caveat. Re-run stage 1
  at the sourced value and **report Drummer's ratio as the out-of-sample number it is.**
- **T2 — a primary gives a storage TIME CONSTANT, or data from which one is identifiable.**
  Same. **And then §0.1 must be answered explicitly**: if it is weeks, say that the acute
  dissociation is not this compartment.
- **T3 — the sources give a fraction but no timescale.** Enter the fraction, leave
  `BF.NA.STORAGE_TAU` `assumed`, and say plainly that the row that matters most to stage 1
  is the one still unsourced.
- **T4 — the literature supports TWO timescales.** Then ADR 0004's single first-order
  compartment is the wrong structure, and that is the finding. **Report it; do not build
  the second compartment in this pass.**
- **T5 — nothing admissible.** Record INDETERMINATE with the exact terms, leave both rows
  `assumed`, and say what experiment would settle it. **A pass that returns nothing is a
  result**, and after §3.1 it is a more likely one than it looks.
- **T6 — a sourced value moves the chronic salt sensitivity outside 1.70–2.30.** Stop and
  report. Do not rescue it with a gain.

---

## 7. THE FALSIFIABLE TESTS

1. **Rakova is opened and what ADR 0004 attributes to it is checked line by line.** The ADR
   was written from it without it being read here; three claims are attributed and all
   three get verified or corrected.
2. **Every entered row states its species, preparation and the §3.2 inference caveat.**
3. **Stage 1 is re-run at the sourced values** and the table reprinted — volume half-life,
   sodium half-life, ratio, chronic salt sensitivity, Jensen.
4. **Drummer's ratio is reported as OUT-OF-SAMPLE**, with the word used, and whether it
   moved toward 0.70 or away.
5. **Chronic salt sensitivity inside 1.70–2.30 with `storage = true`.**
6. **§0.1 is answered in the write-up in one of its three forms**, not left open.
7. **The number of sources opened and the number found inadmissible are both reported.**
   §3.1 predicts most ²³Na MRI hits will be inadmissible for the fraction, and a search
   that reports only its successes has hidden its selection.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Entering 0.40 and citing Titze.** Named first, named in the previous pre-registration,
and the only reason it needs saying twice is that the number is already known and the
citation would look right.

**Taking a ²³Na MRI tissue concentration as an osmotically inactive fraction.** §3.1. It is
the most available number in this literature and it is not this quantity.

**Letting Drummer or Van Regenmortel into the estimation** because a chronic source was
thin. The separation in §2 is the whole reason a test exists afterwards.

**Quietly improving ADR 0004's tier** because a citation was added. E3 rests on the
compartment being inferred rather than measured, and §3.2 says that does not change.

**The quiet one: reporting the fraction and not §0.1.** The time constant is out by
somewhere between thirty and a hundred and forty fold, the two timescales may not be the
same process, and a pass that sources the easy row and leaves that unexamined has taken
the part that was already nearly right.
