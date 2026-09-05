# Pre-registration — the pituitary–thyroid operating point from NHANES

**Written before any relationship between TSH and free thyroxine was computed.** Verify
ordering with

    git log --diff-filter=A -- validation/nhanes_hpt_prereg.md
    git log --diff-filter=A -- validation/nhanes_hpt_extract.py

**WHAT HAD BEEN SEEN WHEN THIS WAS WRITTEN, STATED EXACTLY.** The variable lists of the
NHANES thyroid, demographic, prescription and medical-conditions files, and the marginal
distributions of the 2007–2008 thyroid file: TSH median 1.574 mIU/L, free thyroxine
median 0.800 ng/dL (10.3 pmol/L), total thyroxine median 7.7 µg/dL, thyroid peroxidase
and thyroglobulin antibody medians. **No regression, no cross-tabulation and no
subsetting had been run.** Nothing about the relationship between any two of these was
known.

---

## 1. WHY THIS EXISTS

`OPEN-QUESTIONS.md` §A1: the thyroid loop predicts a euthyroid thyrotropin of 3.35 mIU/L
against a measured population geometric mean of 1.40. The discrepancy is localised to
`THY.TSH.INTERCEPT`, which has one source, an abstract that reports no standard error for
it, and a value that is an extrapolation to zero free thyroxine.

**The owner's instruction: get it from public data.** NHANES measured thyrotropin, free
thyroxine, total thyroxine and both thyroid antibodies in a probability sample of the US
population across three cycles, and the microdata are public. That is a primary human
dataset, larger than anything in the ledger, and it is the right way to settle this.

---

## 2. THE DATA, FIXED HERE

NHANES **2007–2008 (`_E`)**, **2009–2010 (`_F`)** and **2011–2012 (`_G`)**, files
`THYROD`, `DEMO`, `RXQ_RX`, `MCQ`, from
`https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/<year>/DataFiles/`.

Variables used, and no others: `LBXTSH1` (thyrotropin, mIU/L), `LBDT4FSI` (free
thyroxine, pmol/L), `LBXTT4` (total thyroxine, µg/dL), `LBXTPO`, `LBXATG` (antibodies),
`RIDAGEYR`, `RIAGENDR`, `RIDEXPRG`, `WTMEC2YR`, `SDMVPSU`, `SDMVSTRA`, `MCQ160M`
(thyroid problem ever), `RXDDRUG` (drug name).

**THE THREE CYCLES ARE POOLED AND THE SURVEY WEIGHT IS DIVIDED BY THREE**, which is the
standard NHANES procedure for combining cycles. Cycle is reported as a covariate check;
if the estimates differ materially between cycles that is reported, not smoothed.

---

## 3. THE TWO POPULATIONS, DEFINED BEFORE ANY FIT

Both are defined now so that neither can be adjusted after seeing a coefficient.

**P1 — disease-free.** Age ≥ 20. Not pregnant (`RIDEXPRG` = 1 excluded). No reported
thyroid problem (`MCQ160M` = 1 excluded). No thyroid medication: any `RXDDRUG` matching
`LEVOTHYROXINE`, `LIOTHYRONINE`, `THYROID`, `METHIMAZOLE`, `PROPYLTHIOURACIL`,
`AMIODARONE` or `LITHIUM`. Non-missing thyrotropin and free thyroxine.

**P2 — reference (primary).** P1, plus thyroid peroxidase antibody < 9 IU/mL and
thyroglobulin antibody < 4 IU/mL, the manufacturer's thresholds NHANES itself documents.

**NO EXCLUSION ON THYROTROPIN OR FREE THYROXINE VALUE, AND THAT IS DELIBERATE.**
Hollowell 2002's reference population additionally removes biochemical hypo- and
hyperthyroidism. That is right for describing a reference interval and **wrong for
estimating a regression**, because it truncates the dependent variable and biases every
coefficient toward zero. Reference intervals here are therefore descriptive only, and
the regression is run on the untruncated population.

---

## 4. WHAT IS COMPUTED

1. **The operating point.** Geometric mean and median thyrotropin; mean and median free
   thyroxine; both survey-weighted and unweighted, with n.
2. **The pituitary line.** Ordinary least squares of `ln(TSH)` on free thyroxine,
   weighted and unweighted, with standard errors. Slope, intercept, and the intercept's
   standard error — **which is the number `THY.TSH.INTERCEPT` does not have.**
3. **The assay-scale comparison.** The ratio of free to total thyroxine, against
   Braverman 1973's equilibrium-dialysis figure of 0.018% in subjects whose total
   thyroxine was 7.3 µg/dL. This is the check that the model's free thyroxine and its
   pituitary line are on the same scale.
4. **Sex and age.** Both, because the ledger already carries free thyroxine as unsexed
   under ADR 0014's "where only one value is supported, use it for both", and this
   dataset can support a pair or refute the need for one.

---

## 5. DECISION RULES, FIXED IN ADVANCE

- **N1 — the NHANES slope agrees with the pooled Benhadi/Jostel slope within their
  spread.** Pool all three. The distinction between a within-subject perturbation slope
  and a between-subject cross-sectional slope is then empirically moot, and saying so is
  worth more than the caution.
- **N2 — the slopes differ materially.** They are **different quantities** and must not
  be pooled: a cross-sectional slope mixes individuals with different setpoints, and the
  model's loop is a within-individual loop. Keep the perturbation slope as the feedback
  gain; record the NHANES slope as the population-level relation it is. This is the
  branch the literature predicts, and it is written down so it cannot be presented as a
  surprise.
- **N3 — free thyroxine on the NHANES immunoassay is not commensurate with Braverman's
  equilibrium dialysis.** Then mixing an intercept measured on one free-thyroxine scale
  with a reference concentration measured on another is a **unit error**, and it, not the
  intercept's imprecision, is what §A1 is really about. Both must then come from the same
  scale. **Record explicitly that the euthyroid thyrotropin thereby stops being a
  prediction**, because an intercept and a reference concentration drawn from one
  population reproduce that population's thyrotropin by construction.
- **N4 — the scales agree.** The intercept is simply imprecise and §A1's three options
  stand as written.

---

## 6. WHAT THE ANSWER MAY NOT DO

- **The population definitions in §3 may not be re-cut after seeing a coefficient.** They
  are fixed above. If a defect in them is discovered, it is fixed and **both** the old and
  new results are reported.
- It may not drop cycles, trim outliers, or transform a variable in any way not stated in
  §4. NHANES' own reported detection limits are the only filter.
- **It may not present a restatement as a prediction.** If branch N3 fires, ADR 0019's
  falsifiable test 2 is void and the record must say so in those words — the failure mode
  HANDOVER §3.15 records for the Lobo endpoints.
- It may not change any parameter outside the thyroid subsystem.

---

## 7. WHY THIS IS WORTH DOING EVEN IF IT VOIDS A TEST

The model currently reports a euthyroid thyrotropin nobody would believe, on the strength
of one coefficient from a 21-person study that reports no error for it. **A test that a
model fails for a reason nobody can quantify is not evidence about the model.** Replacing
it with an operating point measured in a probability sample of a national population, on
one assay, with its own standard errors, is a straight improvement even though it costs
the claim that the crossing point was predicted.

**What survives as a real test is the RESPONSE** — ADR 0019's falsifiable tests 1, 3 and
4 — and the open-loop gain of 2.24, which nothing here was fitted to.
