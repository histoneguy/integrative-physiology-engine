# Pre-registration: does posture modify the stroke-volume response to a fixed blood loss?

**Written 2026-08-24, BEFORE the full text of the target paper was opened.**
Sixth in the series, after `autoreg_upper_prereg.md`, `anp_sourcing_prereg.md`,
`anp_input_link_prereg.md`, `immersion_pooling_prereg.md` and `sv_filling_prereg.md`.

Tests the Q3 finding of `sv_filling_prereg.md`, which is the evidential basis of
`docs/adr/0012-central-peripheral-volume.md` falsifiable test 1. **This pre-registration
cannot source a parameter and is not permitted to.** See section 6.

---

## 0. PARTIAL PRIOR EXPOSURE, DECLARED BEFORE ANYTHING ELSE

**The abstract of the target paper has already been read**, on 2026-08-22, during the
`sv_filling_prereg.md` search. This is therefore **not a blind pre-registration**, and
saying so is the point of this section.

**What is already known from the abstract** (PMID 29016531, verified against the PubMed
record on 2026-08-22):

- Two experiments. The relevant one is the second: **31 middle-aged patients, mean age 57,
  65% men, studied during active standing before and after phlebotomy.**
- **500 mL of blood loss** augmented the fall in augmentation index by 5.9 percentage
  points.
- The fall in AIx "was associated with increases in HR, diastolic pressure and systemic
  vascular resistance and **a decrease in stroke volume** (all P < 0.05)".

**What is NOT known, and is what this pre-registration is about:** whether the paper
reports stroke volume **at both postures, both before and after the phlebotomy** - the
2x2 table that Q3 needs. The abstract reports AIx as the endpoint and mentions the SV
change only as an accompaniment to the standing manoeuvre.

**Why this is still worth pre-registering.** The extraction rule, the quantity, the
comparison and the stop conditions are fixed here before any *number* is seen. The known
facts above are design facts, not results on the quantity of interest. What must not
happen - and what this document exists to prevent - is choosing which cells of that table
to use, or which contrast to call the answer, after seeing which choice supports ADR 0012.

---

## 1. THE QUESTION, AND WHY THIS PAPER

`sv_filling_prereg.md` found that the stroke-volume response to a fixed absolute blood
loss orders monotonically with posture: **28.00 mL/L seated, 13.33 at ~30 degrees, 10.16
supine**, seated 2.76x supine. Neither measurement technique nor dose orders that
gradient. But it is a **between-study** gradient - posture is perfectly confounded with
study, population, age and device.

ADR 0012 rests on it in a specific way. The partition alone predicts that gradient
**backwards**; reproducing it requires the filling relation to be concave, with

    g'(V_central,seated) / g'(V_central,supine)  >=  2.76 * (f_sup / f_seat)

If the gradient is an artefact of between-study heterogeneity, that requirement loses its
motivation and ADR 0011 can proceed with a much simpler filling relation.

This paper is the only within-subject design found: **the same subjects, the same 500 mL,
measured at two postures.** That removes study, population, age and device from the
comparison in one step.

---

## 2. WHAT IS BEING EXTRACTED

The 2x2 stroke volume table:

|  | before phlebotomy | after phlebotomy |
|---|---|---|
| **supine (or seated baseline)** | SV_base_pre | SV_base_post |
| **standing** | SV_stand_pre | SV_stand_post |

From which the two quantities of interest, **both for the same 500 mL in the same
subjects**:

    dSV_base  = SV_base_pre  - SV_base_post
    dSV_stand = SV_stand_pre - SV_stand_post

and the single pre-registered test statistic:

    R = dSV_stand / dSV_base

If stroke volume is not tabulated directly but cardiac output and heart rate are, at the
same timepoints in the same subjects, `SV = CO/HR` is recoverable and is **the same
quantity, not a second measurement method** - the same ruling made in
`sv_filling_prereg.md` section 3.

---

## 3. THE PREDICTION, FIXED IN ADVANCE

**Q3 confirmed if `R > 1` with the paper's own reported dispersion excluding 1.** The
between-study gradient predicts `R` in the region of 2.8 for seated against supine.
Standing is *more* upright than seated, so if the mechanism is postural volume
displacement the effect should be **at least as large**, not smaller.

**Q3 refuted if `R <= 1`**, or if its dispersion comfortably includes 1. In that case the
between-study gradient is not reproduced within subjects, is most likely heterogeneity
between the three studies, and **ADR 0012 falsifiable test 1 loses its evidential basis.**

**Inconclusive if** the dispersion spans 1 but the point estimate is well above it. Record
as inconclusive. Do not promote it to confirmation by arguing the direction is right.

**Declared now, because it is the number most likely to be reached for after the fact:**
`R` between 1 and 2.8 is a **partial** result. It confirms the direction while failing to
reproduce the magnitude, which would mean posture modifies the response but does not
account for the full between-study gradient. That is a distinct outcome from either
confirmation or refutation and must be reported as its own thing.

---

## 4. WHAT A CONFIRMATION WOULD AND WOULD NOT ESTABLISH

**Would:** that posture modifies the stroke-volume response to a fixed total-volume
change within the same subjects. That is enough to keep ADR 0012 falsifiable test 1 alive
and to justify sourcing the curvature.

**Would NOT:** that the central/peripheral partition is the mechanism. Standing changes
venous tone, sympathetic outflow and heart rate along with volume distribution, and this
model represents only the last of those. A confirmation is consistent with ADR 0012 and
does not select it over the alternatives. **Do not write it up as though it did.**

This is the same error ADR 0010 made in reading "identical to 2 litres of saline" as a
statement about total volume: a result consistent with a mechanism is not evidence *for*
that mechanism over its rivals.

---

## 5. INCLUSION, AND ONE THING THAT LOOKS LIKE AN EXCLUSION

The study population is middle-aged patients, mean age 57, not healthy young volunteers.
**Recorded as a covariate, not an exclusion.** The three studies in the between-study
gradient differ in age too, and age is one of the confounds this within-subject design
exists to remove - within subjects, each person is their own age-matched control.

**Active standing is on ADR 0011's disqualification list. That does not exclude this
paper here, and the distinction is important.** That list governs what may **calibrate a
parameter**. This pre-registration tests whether posture is an **effect modifier**. A
paradigm can be inadmissible for sourcing a number and still be the right design for
testing whether a variable matters at all. Conflating the two would rule out the only
within-subject evidence available on the exact question the exclusion list was written to
protect against.

---

## 6. STOP CONDITIONS, DECLARED IN ADVANCE

1. **If the 2x2 table is not reported, this paper cannot answer Q3.** Record that and
   stop. **Do not substitute augmentation index for stroke volume.** AIx is the paper's
   endpoint and it is a pressure-waveform quantity; the whole point of this exercise is
   the volume-to-flow relation, and a proxy would answer a different question while
   looking like an answer to this one.
2. **No citation is recorded without opening it.** PMID 29016531 was verified against the
   PubMed record on 2026-08-22; the author list, journal, year, volume and pages are
   re-checked against the full text.
3. **NOTHING FOUND HERE MAY BE RECORDED AS A LEDGER PARAMETER.** Not `f_central`, not a
   filling slope, not a curvature. Active standing is an excluded calibration paradigm
   under ADR 0011 and this pre-registration does not lift that. If a clean-looking slope
   falls out, it is still inadmissible, and the temptation to keep it is exactly why this
   condition is written down before the number is seen.
4. **k = 1 and it stays k = 1.** One within-subject study does not become a pooled value.
   Whatever it says, it is `single-source` evidence about an effect modifier, and
   `pooling.md` forbids dressing that as consensus.
5. **A refutation is a result, and it is the more useful one.** If `R <= 1`, say so
   plainly, amend ADR 0012 falsifiable test 1, and tell ADR 0011 that its filling relation
   may be linear after all. Do not go looking for a second paper to break the tie without
   a new pre-registration.
6. **The direction of the search does not change after reading.** If this paper turns out
   to answer a different question well, that is a lead for a separate pre-registration,
   not a result of this one.

---

## 7. WHAT WOULD FALSIFY THE APPROACH ITSELF

If stroke volume in this paper is derived by a pulse-contour or waveform method that is
**itself sensitive to posture** - and finger volume-clamp methods are known to be
sensitive to hydrostatic height - then a posture-dependent measurement artefact could
produce `R > 1` with no physiology behind it at all.

**Declared before reading, because it would otherwise be very easy to miss:** record the
SV method and whether the paper applies a height correction. If the method is
posture-sensitive and uncorrected, `R` is uninterpretable in the confirming direction,
though a **refutation** would remain informative - an artefact that inflates `R` cannot
manufacture `R <= 1`.

This is the same class of problem as the measurement-technique question in
`sv_filling_prereg.md` section 3, where a spread was wrongly attributed to technique. The
lesson taken from that is to record the method first and reason about it second.
