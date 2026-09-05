# OPEN QUESTIONS

**Everything I could not resolve on my own, in one place, with what it would take to
resolve each.** Written 2026-09-05 at the owner's instruction: work the problems out,
document what is left, hash it out at the end.

This is a decision list, not a summary. `HANDOVER.md` §3 has the evidence and §4 has the
work queue; this file is the subset where **the next move is a judgement call, an
access problem, or a piece of physiology the model deliberately does not have.** Each
item states what I would do and why, so a "yes, do that" is enough.

---

## A. Decisions only the owner can make

### A1. ~~The thyroid axis predicts a euthyroid thyrotropin 2.4× too high~~ — RESOLVED 2026-09-05

**It was a unit error, not a bad coefficient, and it is fixed.** Kept here rather than
deleted because the wrong diagnosis was confident and detailed, and that is the part
worth remembering.

The ledger composed a pituitary line measured on one free-thyroxine **immunoassay** with
a concentration measured by **equilibrium dialysis**. A slope in `1/(pmol/L)` composes
with a concentration in `pmol/L` only when both are on the same scale, and free-thyroxine
assays do not share one.

**NHANES 2007–2012 settled it in public data** (n = 6814 reference population,
pre-registered before any relationship was computed): total thyroxine agrees to 6%
between the two methods while the **free fraction differs 1.73-fold**. That is the whole
of the 2.2× discrepancy.

The axis is now on one scale throughout — operating point 10.16 pmol/L and 1.512 mIU/L
from NHANES, everything else derived from those and from the **dimensionless** loop gain,
which is the only quantity in the axis that transfers between assays. **ADR 0019's
falsifiable test 2 is void — ill-posed, not failed.** The model's dynamics barely moved:
closed-loop response 0.305 against 0.308. §3.26 and `validation/nhanes_hpt_extract.py`.

**Two things fell out that were not asked for.** The conventional 0.4–4.5 thyrotropin
reference interval is now measured (0.460–4.484) rather than quoted as a round number.
And free thyroxine differs by **0.5%** between the sexes in 6814 adults, so ADR 0014
needs no pair here — an absence turned into a finding.

### A2. Switch the thyroid metabolic arm on?

It is **built, sourced, wired and tested, and defaults OFF.** Turning it on costs
nothing at rest: the multiplier is exactly 1.0 at the euthyroid point, and the suite
asserts that with `==`.

**The one reason it is off:** its gain comes from hyperthyroid patients (Maushart 2022,
n = 18, paired hyperthyroid → euthyroid, read in full), and `thyroid_prereg.md` §2
excludes thyroid disease. **That exclusion is unsatisfiable for this quantity** — a
healthy person cannot ethically be made thyrotoxic, which is `SOURCES.md`'s own argument
for animal preparations applied to a disease preparation instead of a species.

**What it buys, and it is less than I first claimed:** it moves arterial PCO2 and, through
that, alveolar and arterial oxygen — the model's first two-hop coupling. **It cannot move
ventilation or water balance at any thyroid state**, because the chemoreflex sits on its
flat limb and even six times normal secretory capacity reaches PaCO2 45.0 against a
threshold of 45.28.

**My recommendation: on.** It is the only preparation the measurement exists in, the
relaxation is recorded, and it changes no existing result.

### A3. One article worth having, and one that no longer matters

**Crapo RO et al.** *Am J Respir Crit Care Med* 1999;160(5 Pt 1):1525-31, PMID 10556115 —
discharges **three `assumed` rows across two subsystems**: resting arterial PCO2, the
alveolar–arterial oxygen difference, and the arterial PO2 that follows. Not open access.
**Deprioritised at the owner's instruction 2026-09-05**; recorded so it is not searched
for a fourth time.

**Benhadi 2010 has fallen a long way** and is no longer worth chasing. It once blocked the
whole axis, then supplied a slope, and now would only tighten one dimensionless number by
about 10% by reporting its cohort's mean thyrotropin.

---

## B. Where the model is knowingly wrong, and I did not fix it

### B1. The one genuinely held-out number is a third low

Predicted fractional sodium excretion after 23 mL/kg isotonic saline: **+79.3%** against
Jensen 2013's measured **+123%**. Jensen was deliberately excluded from estimation, so it
is the only place the parameterisation is tested rather than fitted.

**Do not close it by refitting the ANP gain to Jensen** — that spends the only
out-of-sample datum this line has. Wiring the GFR volume response moved it from 82.5% to
79.3%, i.e. slightly the wrong way, while moving both Lobo endpoints closer; the
arithmetic is in §3.22.

### B2. Salt sensitivity is a fit, and the sex difference in it is a prediction nobody has checked

The model gives 1.85 mmHg per 100 mmol/day against a meta-analytic 1.70–2.30, and 3.00
mmHg/L against a measured 2.97–4.16. **Two of the three parameters that make it do so
were solved against those targets.** Quote neither beyond three significant figures.

The model also predicts salt sensitivity **17.7% higher in women**, which nothing has
sourced. A pressure-only kidney carried no sex information at all; the volume path is
keyed to a sexed volume, so it does. **Source it or falsify it** — Schumann 2024,
*Am J Physiol Heart Circ Physiol* 326:H158–H165, n = 980 healthy, is about sex
differences in baroreflex sensitivity and would give a second dimorphic pair at the same
time.

### B3. No acute osmotic magnitude may be reported

`BF.ICF_ECF.OSMOTIC_TAU` is `assumed` at 30 minutes. Negligible over days, **dominant
within one**: a 1.4 L water load moves peak plasma osmolality between 8.8 and 17.6
mOsm/kg depending on it. A sourcing pass ran ten queries over two sweeps and found
nothing usable — the volume-kinetics literature models plasma and interstitium, not
ICF–ECF osmotic exchange. Directions and steady states are unaffected.

### B4. The urinary solute load is a convention and everything on the water side hangs off it

`RN.URINE.SOLUTE_LOAD = 600 mOsm/day`. `RN.URINE.SOLUTE_NONNA`'s own note records that
measured totals are 700–900. Because the maximal urine osmolality is sourced, the
obligatory volume, the baseline urine osmolality, the ADH sensitivity and every steady
state are derived from this figure. **Correcting it moves every ADH constant** and needs
its own pre-registration.

### B5. The thyroid loop cannot represent thyrotoxicosis, only its direction

At six times secretory capacity the sourced pituitary line still puts thyrotropin at 0.89
mIU/L; real thyrotoxicosis is below 0.01. The log-linear relation is fitted across the
euthyroid range and does not suppress outside it. **`thyroid_secretion` expresses which
way the disease goes, not how far.**

### B8. Cardiac output is 25% higher than the Fick relation allows — NEW, 2026-09-05

**The sharpest quantified discrepancy in the cardiovascular limb, and nothing in it was
fitted to anything.** With oxygen consumption now sourced from a 197-study meta-analysis
(§3.28) and arterial content following from a sourced dissociation curve, the oxygen
extraction ratio comes out at **18.3% against roughly 23%** implied by a measured mixed
venous saturation near 75%. The Fick-consistent cardiac output is **4.75 L/min against
the model's 5.95**.

**The likely cause is methodological and is the same class of error as the thyroid one.**
`CV.CO.NOMINAL` descends from a stroke volume measured by **cardiac magnetic resonance**
(UK Biobank, 96 mL male); every mixed venous saturation in the literature comes from
populations whose cardiac output was measured by **thermodilution or Fick**. CMR is known
to read stroke volume higher. Composing one method's cardiac output with another's venous
saturation is exactly §5 item 18.

**What would settle it:** a stroke volume or cardiac output measured by the same family of
methods as the venous saturations — or, better, a healthy-cohort study reporting cardiac
output and oxygen consumption in the same subjects, which makes the extraction ratio
internal rather than composed. **Its own pre-registered pass**; re-sourcing it inside the
metabolic pass would have been adjusting a second parameter to rescue the first.

### B6. Body size scaling is linear where physiology is sub-linear

Glomerular filtration and cardiac output scale linearly in mass here, so the population
spread of both is overstated. Fixing it needs a height row and one sourced
body-surface-area formula — which also unlocks Luu 2022 (n = 3,206) and Zhan 2024
(n = 12,812), both rejected for reporting indexed volumes only, and removes a double
count in the nominal stroke volume.

### B7. A de-indexing correction is owed

`validation/ecf_salt_response_extract.py` multiplies an *indexed* ECF difference by ONE
body surface area where each arm has its own, understating the expansion by ~9%. One
clean pass.

---

## C. Physiology the model does not have — a WORK LIST, not open questions

**Corrected 2026-09-05 at the owner's instruction: all of this is published, so none of
it belongs in a file about things that cannot be resolved.** Listing undone work as an
open question is a way of not doing it. It stays here only until each item is built, in
this order.

1. **The baroreflex has one effector while heart rate exists.** ADR 0009 gives it
   resistance only. Deliberately deferred because the reflex resets and therefore nulls
   at every steady state, so the cardiac gain needs its own sourcing pass.
2. **Renin is pressure-only.** §7 already records that no gain reproduces the human
   salt–renin response, because **macula densa sodium delivery and renal sympathetic
   traffic are both absent**. This is the largest structural gap in the model.
3. **No acid–base limb.** No bicarbonate, so the oxyhaemoglobin curve is fixed at normal
   pH and temperature and nothing whose perturbed variable is the *position* of that
   curve exists: Bohr shift, fever, 2,3-DPG, altitude, exercising muscle.
4. ~~**No metabolic substrate.**~~ **BUILT 2026-09-05** (§3.27, §3.28). Oxygen
   consumption, the Fick relation, mixed venous content and saturation, and the
   extraction ratio. It needed no new component and, initially, no new source — the
   metabolic row ADR 0018 said was missing existed under another name. Oxygen is still a
   forward computation with no feedback, which ADR 0018 decides deliberately.
5. **No age dimension.** The alveolar–arterial difference widens with age and carries a
   young-adult value; so does maximal urine concentrating ability.
6. **Sea level, awake, resting, adult, non-pregnant, healthy.** No hypoxic ventilatory
   drive, no posture, no exercise, no sleep, no circadian modulation switched on.
7. **One thyroid hormone.** Free thyroxine only — no triiodothyronine, no deiodination,
   no protein binding, so the low-T3 state and the monotherapy-versus-combination
   question are outside the model by construction.

---

## D. Bookkeeping I did not do

- **ADR 0013, 0015 and 0016 are stale.** All three were written against a model with a
  different pressure-natriuresis gain, no volume path and a wrong venous return. Reconcile
  or mark superseded. A stale decision record is worse than none.
- **`RN.PRESSURE_NATRIURESIS.SLOPE` is the last row labelled `calibrated`.** It is not
  freely fitted — it is what the human joint constraint implies given the sourced volume
  gain, which is closer to `derived`. Decide the label deliberately; if it moves, **the
  ledger has no calibrated rows left**, which is worth doing on purpose.
- **`tools/check_closure.py` has 21 hand-coded relationships** and does not scale past
  about twenty-five.
- **The fluid-deprivation comparison is indeterminate.** Pross 2013 reports plasma
  osmolality but not the water deficit, so it cannot separate a model defect from a
  protocol mismatch. Resolved by any 24 h human deprivation study reporting **both** the
  body-mass deficit **and** the osmolality change in the same subjects.
- **`START-HERE.md` is stale** and describes an obsolete workflow. Not rewritten.
