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

### A1. The thyroid axis predicts a euthyroid thyrotropin 2.4× too high. Leave it?

**The situation.** Free thyroxine is sourced from equilibrium dialysis in normal
subjects (Braverman 1973, read in full). The pituitary line is sourced from a
thyroxine-loading experiment in different subjects (Benhadi 2010, abstract only). Where
they cross is therefore a genuine prediction — and it crosses at **3.35 mIU/L against a
NHANES III reference-population geometric mean of 1.40** (n = 13,344).

**It is not the slope.** Sweeping the feedback slope across the entire spread of its two
independent sources moves the prediction 2%. The intercept carries all of it, and the
intercept has one source which reports no standard error for it. Reconstructing it from
independent euthyroid pairs gives **2.58–2.80 against the entered 3.454** — the model is
inheriting a coefficient that is an extrapolation to zero free thyroxine from data that
never went near zero.

**Three options, and they are genuinely different commitments.**

| | what it does | what it costs |
|---|---|---|
| **1. Leave it** *(current)* | The euthyroid point stays a real prediction that the model fails. | The model reports a thyrotropin nobody would believe. Nothing downstream consumes it. |
| **2. Enter the intercept from a population TSH index** | Euthyroid point lands correctly; the axis becomes clinically usable. | **Destroys ADR 0019 falsifiable test 2.** The intercept would then come from measured euthyroid thyrotropin, so reproducing it is a restatement. Would have to be relabelled an *estimation* set, exactly as §3.15 relabelled the Lobo endpoints. |
| **3. Find a second perturbation study** | Fixes it honestly. | I could not find one. Benhadi is the only within-subject thyroxine-loading regression in healthy euthyroid adults I could locate, n = 21, mean age 60. |

**My recommendation: 2, done openly.** The prediction has already been made and reported;
it cannot be un-made by later fitting, and the finding is on the record either way. A
model whose thyrotropin is wrong by 2.4× is not usable for anything, and the honest
bookkeeping — this row is now an estimation input, this test is now void — is the thing
this repository is actually good at. **But it spends a falsifiable test, so it is your
call and not mine.**

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

### A3. Two articles I cannot open, and one of them is worth real money

| article | what it unblocks | why I cannot get it |
|---|---|---|
| **Crapo RO et al.** *Am J Respir Crit Care Med* 1999;160(5 Pt 1):1525-31, PMID 10556115 | **Three `assumed` rows across two subsystems**: resting arterial PCO2, the alveolar–arterial oxygen difference, and the arterial PO2 that follows. | Not open access. |
| **Benhadi N et al.** *Eur J Endocrinol* 2010;162(2):323-9, PMID 19926783 | The **standard error on the intercept** in A1, and independent confirmation of the log base. | The publisher origin (`eje.bioscientifica.com`) returns a Cloudflare 525 — a broken server, not a paywall. The OUP mirror sits behind a bot check I will not attempt to defeat. The Erasmus repository record Unpaywall points at holds metadata and no file. |

Institutional access or an author request. **Crapo is the higher-value one** — three rows
against one coefficient — and note that it is *not* the one I previously flagged as the
priority.

### A4. The averaging and precision rules are now written down. Confirm them?

Your correction on 2026-09-05 is recorded in `validation/pooling.md`:

- **Two estimates that are not distinguishable given their own uncertainty get pooled**,
  whatever the methods were, and the spread becomes the uncertainty. The
  incompatible-methods prohibition applies only when the difference is real. The test is
  stated on the row.
- **A pooled or converted value carries the significant figures of the measurements
  behind it and no more.** Converting a unit does not create a digit. `derived` rows are
  exempt — they are arithmetic, not measurement claims, and truncating them breaks the
  closure checks.

**I audited the rest of the ledger for the same error.** Four rows carry six or more
significant figures and all four are `derived`, so the exemption covers them. The thyroid
rows were the only offenders and are corrected.

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

## C. Physiology the model does not have, and knows it

Each of these is E1, uncontroversial, and inside a component that already exists. None
needs a paper nobody can open. **These are the next real work, and they are bigger than
anything in section A.**

1. **The baroreflex has one effector while heart rate exists.** ADR 0009 gives it
   resistance only. Deliberately deferred because the reflex resets and therefore nulls
   at every steady state, so the cardiac gain needs its own sourcing pass.
2. **Renin is pressure-only.** §7 already records that no gain reproduces the human
   salt–renin response, because **macula densa sodium delivery and renal sympathetic
   traffic are both absent**. This is the largest structural gap in the model.
3. **No acid–base limb.** No bicarbonate, so the oxyhaemoglobin curve is fixed at normal
   pH and temperature and nothing whose perturbed variable is the *position* of that
   curve exists: Bohr shift, fever, 2,3-DPG, altitude, exercising muscle.
4. **No metabolic substrate.** Tissue oxygen consumption is absent, so venous oxygen
   content, the Fick relation and extraction ratio cannot be computed. Oxygen is a
   forward computation with no feedback of any kind.
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
