# Pre-registration — the FORM of renal autoregulation

**Written 2026-09-23, AFTER reading one review for structure and BEFORE opening any
source for a number.** Verify the ordering with

    git log --diff-filter=A -- validation/autoreg_form_prereg.md

**First pass run under directive 1.16.** `OPEN-QUESTIONS` B24 item 1.

---

## 0. THE REVIEWS READ, AND WHAT THEY ESTABLISHED — REQUIRED BY DIRECTIVE 1.16

**Carlström M, Wilcox CS, Arendshorst WJ. Renal Autoregulation in Health and Disease.
Physiol Rev 2015;95(2):405–511. PMID 25834230, doi 10.1152/physrev.00042.2012.**
Abstract read in full 2026-09-23; **full text not retrievable** — the publisher blocks XML
download through both Europe PMC and NCBI eutils, and `journals.physiology.org` serves a
bot check which was **not** worked around. §7 records this as an access item.

**WHAT IT ESTABLISHED, AND IT IS STRUCTURE RATHER THAN NUMBER:**

1. **Autoregulation is TWO mechanisms and this model represents ONE of them.** A fast
   **myogenic** response of the afferent arteriole to transmural pressure, and a slower
   **macula densa tubuloglomerular feedback (MD-TGF)**. *"Differences in response times
   allow separation of these mechanisms in the time and frequency domains."*
   **The model has MD-TGF (`gfr_tgf`, ADR 0026) and has no myogenic term at all.**
2. **THERE IS A THIRD MECHANISM THIS MODEL HAS NEVER HEARD OF** — *connecting tubule
   glomerular feedback (CT-GF)*, which the review names as modulating the strength and
   speed of the myogenic response. **Recorded, not built.** It is named here so that a
   later pass cannot present it as a discovery.
3. **The mechanisms are not additive and independent.** The review's stated novelty is
   that MD-TGF and CT-GF *modulate* the myogenic response. **A model that multiplies two
   independent factors is making a claim the review contradicts**, and this pass must say
   so rather than quietly assume separability.
4. **Both act on preglomerular tone, primarily the AFFERENT arteriole.** So both change
   GFR through the same effector, which is why a lumped representation is defensible at
   all.

**AND THE REVIEW QUOTES THE RANGE AS "80–180 mmHg", WHICH THIS REPOSITORY HAS ALREADY
SHOWN TO BE CANINE AND ANAESTHETISED.** `RN.AUTOREG.LOWER`'s note traces 80–180 to Shipley
& Study 1951 — anaesthetised dog, with a legacy "Humans" MeSH tag that is an indexing
artefact — and this repository's own pre-registered extractions put the lower limit near
**63.9** (Finke 1983, conscious dog) with human anaesthesia studies bracketing 50–60.

**A 2015 PHYSIOLOGICAL REVIEWS ARTICLE REPEATING IT UNQUALIFIED IS DIRECTIVE 1.12 SCORING
AGAIN**, and it is the strongest available argument for directive 1.16's own restriction:
**reviews are read for STRUCTURE and never for NUMBERS.** Written down before any
extraction so it cannot be claimed afterwards.

---

## 1. THE DEFECT, STATED BEFORE ANY VALUE IS SOUGHT

    GFR ~ GFR0 * ifelse(MAP < MAP_lo, MAP/MAP_lo,
                 ifelse(MAP > MAP_hi, MAP/MAP_hi, 1.0)) * gfr_vol_mod * gfr_tgf

**INSIDE THE AUTOREGULATORY RANGE THE `ifelse` EVALUATES TO EXACTLY 1.0.** So **GFR has no
direct pressure dependence between 63.9 and 160 mmHg**, and the plateau is **perfectly
flat by construction** rather than emergent from any mechanism.

**THE LITERATURE ALREADY IN THIS REPOSITORY CONTRADICTS THE PERFECTION.**
`RN.AUTOREG.LOWER`'s note records, from Finke 1983 read during that extraction:
*"between resting pressure and the lower limit of autoregulation, average 63.9 mmHg,
[renal blood flow] rose only about 7%."* **Only about 7% is not zero.** The same note ends
by naming this exact defect: *"the true plateau has a slight slope the model's `ifelse`
does not represent."*

**SO THIS PASS IS NOT A NEW IDEA. IT IS A DEBT THE RECORD NAMED AND NOBODY DISCHARGED**,
and finding it cost nothing because §3.73's audit pointed at `Renal.GFR` first.

---

## 2. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED BEFORE SEARCHING

- **"80–180 mmHg"** — already disposed of above, and **already repeated to me by a 2015
  Physiol Rev review**, which is why it is listed rather than assumed dead.
- **"GFR is constant over the autoregulatory range"** — the claim this pass is testing.
  It is a teaching simplification and the question is by how much.
- **An autoregulatory index of "0"** for perfect autoregulation, quoted without the
  measurement bandwidth it was obtained at. **Autoregulatory efficiency is
  FREQUENCY-DEPENDENT** — the review's first structural point — so an index without a
  stated timescale is not usable here.
- **"Autoregulation is 90% efficient"** or similar round efficiencies.

---

## 3. ADMISSIBILITY, FIXED BEFORE SEARCHING

**The quantity sought is a DIMENSIONLESS ELASTICITY**: the fractional change in GFR (or
RBF, declared per source) per fractional change in renal perfusion pressure, **within the
autoregulatory plateau**, at **steady state or a timescale of minutes or longer**.

**Include:** graded, servo-controlled or otherwise held reductions of renal perfusion
pressure with GFR or RBF measured at each step, in **conscious** preparations or in humans;
the relationship must be **the subject** of the study, not the instrument — directive 1.7.

**Exclude:** anaesthetised preparations as the *primary* source where a conscious one
exists, for the reason `RN.AUTOREG.LOWER` already established (anaesthesia is the most
likely single explanation of 80 vs 63.9); **dynamic / frequency-domain autoregulatory
indices**, because this model integrates over days and a transfer-function gain at 0.1 Hz
is a different quantity; disease and diabetic models, which the review says have
**attenuated** autoregulation — that is a later pass and must not contaminate the normal
value.

**SPECIES.** Directive 1.6 and 1.15. Human graded-pressure data with GFR measurement does
not exist outside anaesthesia (established by `autoreg_lower_prereg.md`, 1114 records
screened). **Conscious dog is the expected source and Finke 1983 is already in hand.**
Species, preparation and range recorded on the row.

---

## 4. THE POOLING RULE, DECLARED BEFORE EXTRACTION

`validation/pooling.md`, binding since 2026-08-21, in its own order of preference:
meta-analysis, then inverse-variance, then n-weighted, then **`pooled-geometric` — and
this quantity is a DIMENSIONLESS ELASTICITY, so the geometric rule applies** by
`pooling.md`'s own clause for ratios and gains whose natural null is a fixed value.
Then unweighted, then `single-source` declared as such.

**`range-midpoint` is prohibited. Cross-species pooling is prohibited.**

**DIRECTIVE 1.16 ADDS A SECOND REQUIREMENT AND IT IS THE POINT OF THIS PASS: the FORM
needs more than one primary**, not only the value. Two papers from one group, or one
reusing the other's published equation, **count as one** — `form_sourcing_audit.md` §4.

**THIS IS POPULATION DATA.** `uncertainty_type = sd`, between-subject; a reported SEM is
converted with its own n and the conversion recorded per source.

---

## 5. THE FORM, CHOSEN BEFORE THE VALUE IS KNOWN

**One parameter, and it reduces to the current equation at zero.**

    gfr_auto ~ (MAP/MAP_ref)^a_index          within the plateau

with `a_index` the autoregulatory index: **0 is perfect autoregulation, 1 is none.**
Outside the plateau the existing proportional limbs are unchanged.

**WHY A POWER AND NOT A LINE.** GFR must stay positive and the elasticity is what the
sources report; a power law makes the reported quantity the parameter directly, with no
conversion, and **`a_index = 0` returns the current model exactly**, so the change is
testable against its own null.

**WHAT IS NOT CLAIMED.** This is a **lumped** residual, not a myogenic term. §0 established
that the review says the mechanisms modulate each other; a single exponent does not
represent that and **must not be described as "adding the myogenic mechanism."** It
represents *the pressure dependence that survives whatever autoregulation does*, which is
what the sources measure.

---

## 6. WHAT MAY NOT MOVE

- **`RN.AUTOREG.LOWER` (63.9) and `RN.AUTOREG.UPPER` (160).** Both are pre-registered
  extractions with their own records. This pass changes the shape BETWEEN them.
- **`RN.PRESSURE_NATRIURESIS.SLOPE`, `RN.MD.RENIN_GAIN`** — the two `calibrated` rows.
  **THIS IS THE TRAP.** A non-zero `a_index` gives GFR a direct pressure response, which
  is a second pressure–natriuresis route, and **the temptation will be to re-solve
  `G_pn` against the salt-sensitivity target.** That is failure mode 22 — a calibrated
  parameter re-estimated by a second path. **If salt sensitivity moves outside its band,
  THAT IS THE RESULT**, reported, and the re-solve is a separate decision for the owner.
- **`gfr_tgf`, `gfr_vol_mod`** and every ADR 0026/0028 row.
- **The operating point**, to its current precision — `a_index` enters as
  `(MAP/MAP_ref)^a`, which is **exactly 1.0 at `MAP = MAP_ref`** by construction.

---

## 7. THE FALSIFIABLE TESTS

1. **`gfr_auto` is exactly 1.0 at the operating point** and the resting state is
   unchanged — MAP, sodium, osmolality, urine volume, `Na_excr`, GFR.
2. **`a_index = 0` reproduces the current model bit-identically.** The null is testable.
3. **THE PREDICTION: salt sensitivity RISES.** A direct GFR response to pressure adds a
   natriuretic route, so a given sodium load needs a smaller pressure rise to excrete it,
   so **dMAP per 100 mmol/day should FALL**. Reported against the human meta-analytic
   1.70–2.30 **before** anything is re-tuned.
4. **The autoregulatory range is still recognisable as one** — GFR across 64–160 mmHg
   must vary by much less than proportionally, reported as the measured elasticity of the
   assembled model, which is **not** `a_index` because TGF and the volume term also act.
   **If the assembled elasticity differs from `a_index`, that is a result about the loop
   and not an error.**
5. **Jensen, Lobo, the renin ratio and every challenge**, reported unchanged or not.
6. **`a_index` swept across its own uncertainty interval**, with test 3 recomputed at each
   end. If the prediction survives the interval it is a result; if not, the interval is.

---

## 8. THE DECISION RULE

- **A1 — two or more admissible primaries report an elasticity.** Pool by §4 and build.
- **A2 — exactly one does** (the expected outcome; Finke 1983 is already in hand).
  **Build it, declare `single-source`, and say plainly that directive 1.16's second
  requirement was NOT met on the first pass run under it.** That admission is more useful
  than a second citation found by lowering the bar.
- **A3 — the sources report autoregulation as indistinguishable from perfect at steady
  state.** Then `a_index = 0`, **the current form is vindicated**, and the row acquires a
  citation saying so. **This is a real possible outcome and would close B24 item 1 without
  changing a line of model code.**
- **A4 — only dynamic/frequency-domain indices exist.** §3 excludes them. Record
  INDETERMINATE, leave the form uncited, and write down the search terms.

---

## 9. WHAT WOULD MAKE THIS PASS A FAILURE

**Re-solving `G_pn` to keep salt sensitivity in band.** §6. Test 3 is a prediction; a gain
chosen to satisfy it is not.

**Calling the exponent "the myogenic mechanism."** §5. It is a lumped residual and the
review is explicit that the mechanisms are not separable that way.

**Taking 80–180, or any other number, from the review.** §0.

**Pooling a conscious-dog elasticity with an anaesthetised-human one** because two sources
are wanted and only one is admissible. §4 and branch A2 exist precisely so that the honest
outcome is available.
