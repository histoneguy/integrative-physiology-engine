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

### B1. The held-out number is not low — and what IS open is the LATE time course

**CORRECTED 2026-09-17, HANDOVER §3.45.** This entry said the model predicted **+79.3%**
against Jensen 2013's **+123%** and called it a third low. **Two things were wrong with
that.**

**It was stale.** `be3691b` on 2026-09-05 — the macula densa arm — moved the endpoint and
nothing recorded it. The claim stood here for twelve days.

**And the comparison was not like for like.** It set a MODEL PEAK against Jensen's value
in its FINAL SAMPLING PERIOD. Jensen's series is monotone rising to that period (1.26,
1.93, 2.35, 2.67, 2.80), so the study never observed a peak; 210–240 min is where the
protocol stopped. Measured on Jensen's own window, the model is at **+110.1%** against
**+122%** — inside a reported 2.80 ± 0.75, and tracking the whole observed time course.

**The agreement is not accuracy.** Even the zero-correlation upper bound on Jensen's ratio
is −18% to +502%.

**WHAT IS GENUINELY OPEN — AND IT WAS RESOLVED INTO SOMETHING SHARPER THE SAME DAY.**
See B1b below and HANDOVER §3.46.

### B1b. The acute load is cleared 1.9x too slowly, and no parameter can fix it

**Drummer C et al., Am J Physiol 1992;262(5 Pt 2):F744–54, PMID 1590419** — six healthy
supine volunteers, 2 L of 0.9% saline in 25 min, 48 h of collections plus a 48 h control.
Elevated body weight returned to baseline with a **half-life of about 7 h**. **The model
gives 13.10 h.**

*(Not PMID 1324562, the same group's head-down-tilt study, whose experimental variable is
the tilt.)*

**It cannot be fixed by any single parameter, and that was demonstrated rather than
argued** (`bench/late_time_course.jl`):

| lever | reaches 7 h? | chronic salt sensitivity there |
|---|---|---|
| `RN.ANP.TAU` | **no — floors at 11.97 h even when instantaneous** | 1.960 |
| both gains ×3 | yes | **0.681** |
| `G_anp` alone ×3 | yes | **0.766** |
| `G_pn` alone ×10 | no — 11.12 h | 0.779 |
| `S_gfr_v` ×4 | no — saturates at 8.62 h | 1.463 |

against a human chronic window of **1.70–2.30**. **The acute response needs about three
times the gain the chronic one permits.**

**WHAT WOULD RESOLVE IT — AND THE PASS THAT TRIED IT FOUND SOMETHING ELSE. See B1c.**

### B1c. ~~Two acute human datasets disagree by twofold~~ WITHDRAWN 2026-09-17 — §3.49

**The conflict recorded here does not exist.** With Drummer's full text the model is 1.25×
off on the **sodium** half-life and 1.90× off on the **volume** half-life; §3.46's
three-fold gain requirement was a water problem being driven through a sodium lever, which
is why it broke Jensen. Jensen measures fractional **sodium** excretion and agrees.
**The open problem is the sodium store — see B1e.** What follows is kept as the record of
how the forms were tested, and its discriminator result stands.

**HANDOVER §3.47.** Both candidate forms were built, with the discriminator fixed before
either: a static convex gain bends the chronic pressure–sodium relation (12–20% of the MAP
range), an adapting rate-sensitive one leaves it exactly straight (2.1%, unchanged from
linear). **The convex form is refuted. ADR 0010's specified SATURATING path points the
wrong way entirely** — the requirement is *more* response per litre at large excursions,
not less.

The adapting form reaches the target and breaks the out-of-sample number:

| | t½ h | salt sens | **Jensen %** (measured 122) |
|---|---|---|---|
| linear, as merged | 13.05 | 1.9604 | **110.4** |
| k = 1/3 | 10.90 | 1.9596 | **127.6** |
| k = 2/3 | **7.47** | 1.9603 | **178.8** |

**Drummer wants an acute gain three times the chronic one; Jensen says it is already about
right. No value of k satisfies both.**

**WHAT WOULD RESOLVE IT is a third measurement, not a parameter — AND THE TWO BEST ONES
ARE BEHIND PAYWALLS.** Pursued 2026-09-17, HANDOVER §3.48. Drummer's full text is
`oa_status: closed` at all four locations, and **the authors' own institutional repository
says it cannot provide it**. Luft 1983 (PMID 6823962) — 2 L over 2 h at four prior sodium
intakes, natriuresis dependent on prior intake, FE_Na 6–7% — is closed too, and it is the
sharpest instrument that exists for this. **Both are abstract-only. This is BLOCKED, not
resolved**, and it needs institutional access rather than more searching.

**Neither form may be adopted until then** — both are committed default-off, and the
default build is unchanged at 12 states.

### B2. Salt sensitivity is a fit, and the sex difference in it is a prediction nobody has checked

The model gives 1.85 mmHg per 100 mmol/day against a meta-analytic 1.70–2.30, and 3.00
mmHg/L against a measured **2.82–4.02** (corrected 2026-09-16 from 2.97–4.16; HANDOVER §3.44). **Two of the three parameters that make it do so
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

### B8. ~~Cardiac output is 25% higher than the Fick relation allows~~ — INDETERMINATE 2026-09-08, and the question was wrongly put

**This entry was wrong in its framing and in one of its two assertions, and the pass that
corrected it is `validation/venous_saturation_prereg.md`, pre-registered before the search.**

**What the model actually does.** Oxygen extraction **0.183** and mixed venous saturation
**0.801** are a *prediction*: oxygen consumption from Weir's equation on a 197-study
meta-analysis, arterial content from a sourced dissociation curve, cardiac output from heart
rate times a tier-A CMR stroke volume. Nothing fitted.

**What this entry judged it against.** 0.23, which **is in no ledger row, no target file and
no closure check here.** It is a teaching number — directive 1.12 lists it, alongside the
75% saturation, the 5 mL/dL difference and the 5 L/min cardiac output it composes with.
**This entry asserted that a sourced prediction was wrong because it disagreed with an
unsourced convention.**

**Branch V3: the comparison cannot currently be made.** Mixed venous blood needs a pulmonary
artery catheter and healthy people are not catheterised, so every modern source is intensive
care, cardiac surgery, anaesthesia, transplantation, COPD or pulmonary hypertension —
directive 1.7 for the seventh subsystem, predicted in §2 before the search. The one clearly
admissible source, **Barratt-Boyes & Wood 1957** (*J Lab Clin Med* 50:93–106, PMID 13439270,
healthy subjects, right-heart saturations) — almost certainly the origin of the textbook 75%
— is not open access and has no abstract in Europe PMC.

**And the finding the branch did not anticipate:** in healthy subjects the arteriovenous
oxygen difference is **never measured, it is computed as VO₂/CO.** Every non-invasive healthy
study divides oxygen uptake by a cardiac output obtained some other way — *the same
composition this model performs*. It cannot test the model; it can only reveal which
cardiac-output method was used. **So the extraction ratio is, in health, not independently
measurable short of a PA catheter.**

**The method assertion is half right, and it is the wrong half.** This entry claimed "CMR is
known to read stroke volume higher" and cited nothing. Crowe LA et al., *J Clin Med*
2022;11(10):2717, PMC9143884, open access, read in full: no MRI localisation is
interchangeable with thermodilution, 2SD of bias **24.1–31.1 mL/beat** — about ±30% on a
90 mL stroke volume. **The methods disagree enormously, but no direction is established**,
and the authors suggest thermodilution is the less precise one. So composing a CMR cardiac
output with a thermodilution-era saturation is indeed illegitimate — but nothing says which
side is wrong, and this entry assumed it was the model.

**Nothing was entered and `CV.SV.NOMINAL` was not touched.** §7 forbade it under every
branch, and nothing found would have justified it anyway.

**What would resolve it, in order of value:** a healthy cohort reporting cardiac output *and*
oxygen consumption in the same subjects by one method family; Barratt-Boyes & Wood in full,
with its cohort, method and dispersion; a method-matched CMR-versus-reference comparison in
**health** rather than in pulmonary hypertension.

### B8-OLD. The entry as originally filed, kept because the wrong diagnosis was confident


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

### B9. ~~Two acute saline endpoints fail~~ — CLOSED 2026-09-09 as SUPERSEDED, not resolved, and the closure cost something

**The harness exits 0 and both endpoints are inside their bands.** That happened because
the two baroreflex gains were corrected, not because the physics B9 recorded was fixed.

    urine   770.976 -> 754.800 (ADR 0022) -> 738.134 mL    band 380-750
    sodium  129.098 -> 126.478 (ADR 0022) -> 123.756 mmol  band  63-127

**Nothing was fitted.** The chronotropic gain is Laitinen 1998 and the vasomotor gain is
Yamasaki's own human measurement, both sourced independently of these endpoints and of
each other. `RN.MD.RENIN_GAIN` and `CV.ANP.NATRIURETIC_GAIN` were **not** re-solved.

**WHAT WAS LOST, AND IT IS THE REASON THIS IS NOT A WIN.** These two endpoints were the
only quantitative bound on the macula densa arm. ADR 0021 amendment A6 measured that the
arm can carry a chronic renin ratio of about **2.57** before the acute limb leaves its
band, against a ledger **2.73**, and named that 6% gap as where the missing renal
sympathetic traffic lives. **Inside the band they bound nothing**, so ADR 0021's
prediction — that building sympathetic traffic lowers `g_md` and brings the endpoints
back — is no longer testable against Lobo.

**AND THE SOURCE FOR IT IS NO LONGER OPEN — 2026-09-18.** The owner set directive 1.15:
where no usable human data exists for neurogenic control of pressure through renal or
baroreceptor mechanisms, **default to Lohmeier's conscious-dog work.** This item has
been deferred for want of a source and that reason has now been withdrawn. What remains
is the work, not the question. **Directive 1.5 still binds: open the papers before
citing them, and record species and preparation as dog.**

**The physiology B9 recorded is unchanged.** There is still no renal sympathetic arm and
`RN.MD.RENIN_GAIN` still absorbs whatever it would contribute. What is gone is the
measurement that made that absorption visible as a number. **A green harness is worth
less here than the red one was**, and what would restore the constraint is an acute
protocol that is not a saline bolus — §7's monoculture item.

---

**The 2026-09-08 entry, kept because the half-way state is where the reasoning is.**

### B9-INTERIM. ONE acute saline endpoint fails — 2026-09-08

**ADR 0022's chronotropic arm moved both endpoints and turned one green.** It buffers the
pressure rise during the infusion, so less sodium leaves by pressure natriuresis:

| endpoint | before | after | band | |
|---|---|---|---|---|
| urine, 6 h | 770.976 mL | **754.800 mL** | 380–750 | still **FAIL**, 0.64% over against 2.80% |
| sodium, 6 h | 129.098 mmol | **126.478 mmol** | 63–127 | now **PASS** |

**B9 IS NOT CLOSED AND MUST NOT BE.** `chronotropic_baroreflex_prereg.md` §8.1 predicted
this movement **in writing before the run**, forbade choosing the gain to produce it, and
forbade re-solving `RN.MD.RENIN_GAIN` on the strength of it. **Neither was done.** The
chronotropic gain comes from Laitinen 1998 and from nothing in this repository — that is
the only thing separating this from the "nearly free fix" §3.37 warns is the most
dangerous kind.

**What it actually measures is how much of the excess was missing chronotropic
buffering: about 2% of each endpoint, which is three-quarters of the urine excess and
all of the sodium excess.** The remaining 4.8 mL is what the renal sympathetic arm has
to explain, and ADR 0021's prediction — that building it lowers `g_md` and brings the
last endpoint inside — is unchanged and now has a second, independent data point.

**A DECISION YOU MAY WANT TO MAKE.** One green line was bought by a change made for an
unrelated reason. If you would rather the record showed both endpoints failing until the
sympathetic arm exists, the alternative is to say so here rather than to move a
parameter. **My judgement: leave it.** The gain is externally sourced, the prediction
was pre-registered, and suppressing a real improvement to keep a record tidy is its own
kind of dishonesty.

---

**The original entry, unchanged below.**

### B9-ORIGINAL. Two acute saline endpoints now fail, and the failure is a bound rather than a bug — NEW, 2026-09-05

**`validation/challenges.jl` exits nonzero on this branch and it is meant to.** The macula
densa arm (ADR 0021) gives distal sodium delivery a route to renin and renin a route back
to sodium excretion. Every steady state is untouched — aldosterone escape zeroes the
tubular effect at rest — and Lobo's six-hour saline limb is not: **771 mL and 129 mmol
against bands of 380–750 and 63–127**, which are 2.8% and 1.7% over and are themselves
assumed ±33% because Lobo publishes no dispersion.

| `g_md` | urine, 6 h | Na, 6 h | chronic PRA ratio |
|---|---|---|---|
| 0.000 | 580 mL | 97.7 | 1.142 — the pressure-only ceiling |
| 5.000 | 750 mL | 125.8 | 2.572 — the acute band ends here |
| **5.396** | **771 mL** | **129.1** | **2.733** — van den Bosch, and the ledger |

**So the acute data bound the arm: the macula densa can carry a chronic salt–renin ratio
of about 2.57, and the measurement is 2.73.** ADR 0021 decision 7 said this gain would
absorb the renal sympathetic traffic the model lacks; this is the first number that shows
it. **My recommendation: leave it.** The prediction — that building the sympathetic arm
lowers `g_md` and brings both endpoints back inside — is worth more than two green lines
bought by fitting `g_md` to the dataset that already fixes `RN.ANP.TAU`.

**The decision is whether you want the harness green instead.** It would take capping the
gain near 5.0 and reporting the chronic ratio as 2.57, which is honest but spends the
prediction. §3.32 and ADR 0021 amendment A6.

### B10. ~~The potassium fraction is a constant and humans are not~~ — CLOSED 2026-09-08, it is now intake-dependent

**Found by the owner catching a false claim, not by any check here.** `K.RENAL_FRACTION`
is 0.884 at every intake. The Utrecht balance studies put it lower and *rising with
intake*: Hené 1986 measured 0.63 at 80 mEq/day and 0.78 at 300; Rabelink 1990 about 0.80
at 400 mmol/day. Brunner 1970's six studies — the ones actually in the ledger, read in
full — give 0.884.

**That pass was run on 2026-09-06 and the answer is that it stays a constant.**
`validation/potassium_doseresponse_prereg.md` §5 fixed the shape a rising fraction would
take *before* looking, and branch D5 would have taken it. It was not taken because **the
sources disagree on the sign**: Cappuccio 2016's *marginal* fraction — the share of each
supplement appearing in urine, across 19 trials — is **0.734**, below the ledger's 0.884,
and a marginal below the average makes the average **fall** with intake where Hené and
Rabelink have it rising. Branch D4: report, do not split.

**You struck it out on 2026-09-08** — it measures tablet absorption, not renal handling —
so the disagreement collapsed and D5 fired. `f_renal` is now
`1 − 0.116·(69.06/I)^0.39`: the shape from §5 of the pre-registration, the exponent from
Hené's within-subject change, the level unchanged so the reference individual is
bit-identical. §3.35 and ADR 0021 amendment A9.

**One thing to know about the row you now own.** The exponent is **1.6 standard errors from
zero** and its interval includes a constant fraction; it rests on one abstract-level study
in six men. What carries it is the physiology — colonic potassium secretion rises with
intake — not the statistic, and the ledger note leads with that. **Holbrook 1984** (*Am J
Clin Nutr*, PMID 6486085) is the balance study that would tighten or refute it and it was
not obtainable; if you can get it, that is the highest-value paper in this subsystem.

Also settled in the same pass: the exponent, 17.71 → 17.73, with an interval of 11.9–24.7
from 1216 participants in place of a twelvefold spread over ten. §3.34.

### B11. There is no potassium adaptation, and adaptation is what the literature is about — NEW, 2026-09-05

Rabelink 1990's title is *early and late adjustment to potassium loading*: by day 20 of a
400 mmol/day load, **renin and aldosterone had returned to baseline** while kaliuresis was
maintained. This model holds aldosterone at **2.80× baseline for ever** — its excretion
relation is fixed and its only adaptive machinery, aldosterone escape, acts on the sodium
side.

**So the model gets the direction and rough size of a chronic potassium load right and the
hormone time course wrong**, and that is the bounded claim to quote from it. Hené 1986
concluded the adaptation is a shift of sodium reabsorption to a distal, aldosterone-sensitive
site — a *segmental* claim, which ADR 0021's disqualification section says this model may
make no statement about, so building it means building segments for real rather than
observationally.

### B12. ~~Holbrook 1984 says the potassium fraction is FLAT~~ — DECIDED 2026-09-08, option 1: the rise stands

**You asked for Holbrook and could not get it; neither could I** — publisher, DOI redirect
and the USDA repository all failed. **But the abstract carries the decisive sentence**, and
it cuts against the change you directed two days ago.

Holbrook JT et al., *Am J Clin Nutr* 1984;40(4):786–93, PMID 6486085. **28 adults, one
year, four 7-day balances, meals and beverages and urine AND FAECES by atomic absorption,
self-selected FOOD diets.** Apparent absorption of potassium **85%**, and it *"did not
change significantly over the wide range of intakes."*

**Apparent absorption already nets out colonic secretion**, so a flat value across intakes
is a direct statement that the exponent is zero — a constant fraction, which is what the
model had before 2026-09-08. **And the tablet-absorption argument that removed Cappuccio's
marginal fraction does not touch this study: it is food.**

**What defends the current row is range, and only range.** Holbrook's subjects ate what
they chose — perhaps 38–115 mmol/day — and across exactly that span the curve moves
`f_renal` 0.853 → 0.905, about five percentage points, which 28 people with balance-study
noise would not resolve. Hené's 80 → 300 is the range the model must span and Holbrook's
design cannot test it. **That is a defence, not a refutation.** Holbrook has 28 subjects to
Hené's 6, measures the gut term directly rather than by subtraction, and explicitly tested
constancy and found it.

**There is also a ceiling problem.** At steady state the urinary fraction cannot exceed the
*absorbed* fraction. `K.RENAL_FRACTION_MAX` is 1.0 on the weaker argument that it cannot
exceed *intake*; Holbrook measures absorption at 0.85, flat. The model sits above that at
every intake — 0.884 at the reference, 0.942 at 400 mmol/day.

**No value was changed on the strength of an abstract.** The three options:

1. **Leave it.** The rise stands on Hené's range; Holbrook is underpowered for it. The
   ceiling tension is recorded and never reached in the model's valid range.
2. **Revert to a constant at 0.85.** Holbrook's level and slope both, `p` → 0. This is the
   pre-2026-09-08 structure at a 4% lower level, and it costs the reference individual's
   bit-identity — resting urinary potassium 61.05 → 58.7 mmol/day against Cappuccio's
   measured 61.17.
3. **Keep the rise, lower the ceiling and the level to Holbrook's 0.85.** Coherent, but it
   rests two structural rows on one abstract.

**Owner's decision, 2026-09-08: option 1.** The rise stands; Holbrook is underpowered for
the span that matters.

**The defence is now an assertion rather than a paragraph.** Option 1 rests entirely on one
quantitative claim — that across Holbrook's plausible range the model's fraction moves too
little for a 28-subject balance study to have seen it. The suite now asserts exactly that:
`f_renal(115) − f_renal(38) < 0.06`, presently 0.052. **If a future change steepens the
exponent, that test fires and the defence against Holbrook is gone with it** — which is the
only way this decision can be held to account by anything but memory.

**What would reopen this.** Holbrook's own table of intakes: if the range turns out to be
wide — say beyond 30–130 mmol/day — the five-point argument fails and option 2 becomes the
honest structure. That is one table in one paper neither of us can currently reach.

### B6. ~~Body size scaling is linear where physiology is sub-linear~~ — DONE 2026-09-05

Fixed in §3.30. Height and body surface area are in the ledger from 9300 measured NHANES
adults, and the surface-like quantities now scale as `(m/m_ref)^0.5083` while the fluid
compartments stay linear in mass. The reference individual is bit-identical.

**What is left of it is the other half: VOLUMES are still linear in mass.** Extracellular
volume is entered as a mass *fraction*, and fat carries less water than lean tissue, so
the model overstates the fluid volumes of heavy people exactly as it used to overstate
their filtration. That needs a body-composition row this model does not have.

**And nothing has been validated by this.** Narrowing a spread is not the same as making
it right; no measured population spread of filtration or cardiac output has been compared
against. Luu 2022 and Zhan 2024 are now *usable* — a per-1.73-m² figure must be multiplied
by 1.8545/1.73 to reach this reference individual — but they have not been used.

### B13. The reflex gain that now sets every transient rests on seven young men — NEW, 2026-09-09

`BR.OPEN_LOOP_GAIN` = **5.62 ± 0.98**, Yamasaki 2021, and it is a far more load-bearing
row than it was at 2.0, because the total loop gain went from about 3.35 to about 6.97
and **pressure excursions are now attenuated roughly twice as hard**. Everything acute in
this model runs through it.

**Its cohort is n = 7 healthy males aged 19–37, and the authors disclaim
representativeness in their own limitations.** It is entered `both`, so it is a male
number applied to women — the `CV.HEMATOCRIT.NOMINAL` failure, declared. And it is a
young cohort in a model whose stroke volume comes from 45–74 year olds and whose heart
rate comes from 29–65, against a reflex gain that falls steeply with age.

**It is still better than what it replaced** — seven young men measured directly, in the
right species, posture and units, beat six animal studies read through somebody's
introduction. But a second human estimate of the open-loop gain, in a larger or older or
mixed-sex cohort, is now **the highest-value cardiovascular source this model could
acquire**, because more of the model's behaviour depends on this one number than on any
other unreplicated row.

### B14. Two thirds of the ledger has no error bar, and derived rows drop the ones upstream — NEW, 2026-09-09

**Counted, not estimated:** 92 of 139 rows carry no dispersion at all, and **38 of 57
`derived` rows carry none even where their inputs have one**. A derived value whose
inputs have error bars has an error bar; leaving the field blank is not neutral, it
silently claims the number is exact. Directive 1.13 part 2.

**This is why validation band M cannot be run** — §3.23 established that the stronger
test, does the model predict the population central value, needs the model to carry an
error bar, and §7 has recorded since it was written that parameter uncertainty is not
propagated. **The count makes it concrete.** It is also why the ensemble sampling only
body mass and this are one problem seen from two sides.

**What I did NOT do, deliberately.** I did not invent dispersions to fill the column.
Propagating them properly means, for each derived row, taking the inputs' stated
intervals through the derivation - which is real work and in several cases the inputs
have no interval either, so the honest entry is a statement that propagation is
impossible rather than a number.

**The enforceable half is already in.** `tools/ledger_to_julia.py` now refuses a value
resolved finer than its own stated interval. What it cannot yet require is that a
derived row HAVE an interval, because 38 rows would fail on the day it is switched on
and most cannot be fixed without the upstream work above. **Turning that check on is the
natural end of this item**, and the count is how progress on it should be measured.

---

### B15. ~~Jensen's acute limb needs a mechanism that is NOT in the tubule~~ — WRONG, AND CLOSED 2026-09-21

**I wrote this on 2026-09-20 and it was wrong. Kept rather than deleted, because the way it
was wrong is the part worth remembering.**

**What it recommended:** building acute renal sympathetic withdrawal on tubular
reabsorption, as the first of three candidates.

**Why that was wrong, and the repository had already said so three times.**
`cardiopulmonary_sympathetic_prereg.md` §1 forbids a third natriuretic term keyed to central
volume, because `V_central` = `f_c`x`V_blood` and ADR 0010's arm already senses it. HANDOVER
§3.57 then MEASURED the consequence: the volume-keyed arm carries **77% of the chronic
swing**, it is keyed to `V_blood` because *"atrial stretch is intravascular"*, and Lohmeier's
Den/Inn ratio says **roughly half of such a response is nerve traffic**. §3.58 renamed the
row for exactly that reason. **The arm I recommended building is already in the model,
unlabelled, inside `CV.VOLUME.NATRIURETIC_GAIN`** — and building it again is the double
count that pre-registration exists to prevent.

**I recommended it anyway, having read none of the three.** That is the failure: not a wrong
mechanism, but a recommendation made without reading the record that had already settled it.

**What the real defect turned out to be — ADR 0028.** The tubule segments carried the
*signal* and not the *flux*: `Na_distal` was computed and read by nothing, the same defect
`tubule_segments_prereg.md` found in `Na_prox_out`, one level down. Routing excretion through
the segments — **no new parameter** — moved Jensen **49.5% → 59.9%** and connected Folkerd's
proximal salt response, which had been reaching excretion through nothing at all.

**What remains open is narrow and is recorded in ADR 0028 rather than here:** Alexander
1972's distal magnitudes cannot be entered because his index is a free-water proxy and the
full text is scanned page images. That is Phase 2, and it needs one paper, not a decision.

### B16. Two extraction gaps in papers already in hand — NEW, 2026-09-20

**Neither needs a new source. Both need a page of a paper that has already been read.**

**LORENZ 1990 SERIES 2 SEMs.** `RN.MD.RENIN_SLOPE` = 0.029 per mmol/L is derived from four
group means - 3.2 and 16.6 nGU/min at 80 and 24 mmol/L Na+, n = 8, P < 0.007.
`macula_densa_lorenz_prereg.md` took down the means and the significance test **but not the
dispersions**, so the row carries `uncertainty_type = none` with a note saying that this is
an **extraction gap and not a precision claim**. Directive 1.13 says the inputs' uncertainty
must be carried; here it was never taken. The full text is in the owner's hands.

**BRIGGS 1984 FREE-FLOW SNGFR.** `gfr_tgf` is clamped to 0.6-1.4 and **ADR 0026 declares
that clamp a numerical guard rather than a physiological claim**, because the abstract gives
`dSNGFR_max` in nl/min and not the free-flow SNGFR it would have to be divided by. Measured,
the guard spans 0.964-1.002 in normal operation and **never binds**, so nothing currently
rides on it - but a manoeuvre that pushed the macula densa harder would make it load-bearing
silently. One number from the full text retires the declaration.

**ALEXANDER 1972 JOINS THEM, ADDED 2026-09-21.** J Clin Invest 51(9):2370-2379, PMID
4639021. His acute distal depression of 4.4% cannot be entered because his index is
`C_H2O/V`, a FREE-WATER proxy, and converting it to this model's distal SODIUM fraction
needs the reabsorption rates in the full text. **The full text is scanned page images on
both PMC and jci.org.** ADR 0028 took only the structure.

**WHAT WOULD RESOLVE ALL THREE:** three papers. Lorenz is already supplied. **Briggs 1984**
(Am J Physiol 247:F808, PMID 6496746) and **Alexander 1972** (PMID 4639021) are the two I
would ask for, and neither blocks anything today — each retires a declared limitation.

---

### B17. An algebraic unknown silently disabled three harnesses — NEW, 2026-09-20, FIXED but worth a decision

**Fixed, and recorded here because the failure mode is general and will recur.**

Every unknown in this model was **differential** until ADR 0026. Three harnesses -
`salt_step`, `validation/challenges.jl` and the haemorrhage test - carried *every* unknown
between phases as an initial condition. An algebraic unknown is not one; pinning it
over-determines the initialisation.

**`salt_step`'s third salt arm then did not integrate at all.** It reported **103 mEq/day
excreting 154** and a chronic salt sensitivity of **0.95 against a true 1.96 - and raised no
error.** A failed solve was cycle-averaged and checked against a human band.

All three now carry differential states only and **treat a failed retcode as an error**. The
classifier asserts it found something, because its first version matched `Differential(t)(`
while ModelingToolkit prints `Differential(t, 1)(`, carried nothing at all, and made Jensen
read **-17%**.

**THE DECISION THIS LEAVES.** Nothing in the six gates could have seen either failure, and
the suite caught only the second. **Is a seventh gate warranted** - one that asserts every
harness in the repository checks `successful_retcode` before summarising? CLAUDE.md says do
not add tooling unless something breaks that cannot be worked around. **Something broke, and
it broke quietly, twice in one afternoon.** My inclination is still **no** - the assertions
are now in the three places that carry state, and a gate that greps for `solve(` would have
a false-positive rate like the first `check_tolerances.py` - but it is the owner's call.

---

### B18. The model has no thirst, so it cannot produce polyuria — NEW, 2026-09-21

**Found by the owner asking what the fluid intake was**, while the glucose pass was reporting
an osmotic diuresis it had not earned.

`BF.H2O.INTAKE_NOMINAL` is **2.5 L/day**, `extraction_method = assumed`, citation
**"Convention pending primary source."** Water intake is a fixed parameter, so at steady
state urine volume is pinned at intake minus losses — **1.70 L/day at every glucose
concentration the model can reach.** An osmotic load appears as urine **concentration**
instead (547 → 728 mOsm/kg), which is the right direction and the wrong variable.

**WHY IT MATTERS BEYOND GLUCOSE.** Every osmotic or solute challenge this model will ever run
— hyperglycaemia, high-protein diets, mannitol, diabetes insipidus — is a challenge to which
a real person responds by **drinking**. Without thirst the model answers all of them by
concentrating urine and none by making more of it.

**WHAT I WOULD DO.** Thirst is an afferent this model already half has: `Osm_ecf` is computed
and ADH already reads it. The missing piece is an efferent onto `H2O_intake`. The osmotic
threshold for thirst is measurable in healthy humans by hypertonic saline infusion — the same
paradigm Baylis used for vasopressin, and ADH.OSM.THRESHOLD is already sourced from it.
**Directive 1.7 is satisfied: the relationship is the subject of that literature.**

**WHAT WOULD RESOLVE IT:** a decision to build it, and one hypertonic-infusion study in
healthy adults reporting the thirst threshold and slope. This is probably the highest-value
unbuilt mechanism in the model, because it unblocks a whole class of challenge.

---

### B19. The two osmolality setpoints do not compose — NEW, 2026-09-21

`BF.OSM.PLASMA_SETPOINT` = 287 mOsm/kg and `BF.NA.PLASMA_SETPOINT` = 140 mEq/L are each
`reported` and each sourced. **They do not add up.**

ADR 0029 made glucose an explicit osmole and computed the remainder rather than storing it:
`287 − 2×140 − 5.44` = **1.56 mOsm/kg** left for urea, potassium and everything else — and
**urea alone is about 5**. The retired `BF.OSM.NONSODIUM` row was a closure residual whose
own note claimed it represented "glucose potassium urea and other solutes", and it cannot
have.

**NOTHING WAS ADJUSTED**, because the model's behaviour at normal glucose is identical either
way — the discrepancy is entirely inside the constant. But it means one of the two setpoints
is from a population the other is not, and the conventional formula `Osm = 2[Na] +
glucose + urea` would put the model at about 290.4 rather than 287.

**WHAT WOULD RESOLVE IT:** plasma osmolality and plasma sodium measured in the SAME cohort.
NHANES carries both in its biochemistry profile, and `glucose_insulin_extract.py` already has
the download machinery — this is one extraction, not a literature search.

---

### B20. Glucose has no splay, so glycosuria starts too late — NEW, 2026-09-21

ADR 0029 spills glucose at `TmG/GFR`, which is about **18 mmol/L**. People spill nearer
**10–11**. The difference is **splay** — nephrons are heterogeneous, so glycosuria begins
before any single nephron reaches its own maximum, and this model has one nephron's worth of
kinetics.

**THE TEACHING THRESHOLD WAS NOT SUBSTITUTED TO HIDE IT.** The pre-registration flagged "180
mg/dL" in advance as the most suspect number in the subsystem, and the arithmetic bore that
out: it is **not** `Tm/GFR`, and entering it would have been fitting a population
observation in place of a mechanism.

**WHAT WOULD RESOLVE IT:** a glucose titration curve in healthy humans reporting excretion
against plasma concentration across the spill region — Mogensen's own full text may have it,
since he performed exactly that titration. **PMID 5093515, and the full text is paywalled.**

---

### B21. Rows entered single-source that should have been pooled — NEW, 2026-09-21

**The owner's correction, twice, the second time with "We've already been through this."**
`validation/pooling.md` has been binding since long before this session and says
`single-source` is a last resort a row must admit to, not a default. **Three rows went in
single-source on 2026-09-21 anyway.** One has since been fixed; two have not.

| row | source | status |
|---|---|---|
| `BF.THIRST.OSM_THRESHOLD` | Thompson 1986, n = 10 | **FIXED** — repooled from Hughes 2018, a systematic review of 12 trials and 167 participants |
| `RN.GLU.TM` | Mogensen 1971, n = 9 | **DEBT** |
| `GLU.EGP.BASAL` | Huidekoper 2014, n = 40 | **DEBT** |

**THE FIX WAS NOT COSMETIC AND THAT IS WHY THE DEBT MATTERS.** Pooling moved the thirst
threshold 281 → 285.23, which shrank the derived gain's denominator from 6.00 to 1.77
mOsm/kg and moved the gain by a factor of 3.4. **A single-source row is not a smaller
version of a pooled one; it can be a different answer.**

**AND THE POPULATION FRAMING IS PART OF IT.** This model is meant to become a population
model in which each simulated person is a draw, so a row needs the **between-subject SD**,
not the uncertainty on a mean. Pooling shrinks the latter and must leave the former alone.
`ledger_to_julia.py` already documents `sd` as population spread and `se` as uncertainty on
an estimate.

**WHAT WOULD RESOLVE IT:** for each debt row, a search for a meta-analysis first and failing
that several primaries, pooled under a rule declared before extraction. Both are narrow
searches, not open-ended ones.

**AND THE THIRST ROW STILL LACKS A POPULATION SD.** Hughes reports a 95% CI on the pooled
mean, not a between-subject spread. Treating it as a standard error over 167 participants
implies about 8.5 mOsm/kg, but the review folds between-study heterogeneity into that
interval, so 8.5 is an **upper bound and not a measurement**. Getting the real spread needs
the constituent trials' individual data.

---

### B22. NIMGU is linear and Baron 1988 says it is not — NEW, 2026-09-22

**A defect I introduced in ADR 0031, with the fix already read.**

`NIMGU = k_ni * G` is strictly linear in glucose. With insulin sensitivity and beta-cell
capacity both at zero, the insulin-independent term alone clears the entire glucose
appearance at **15.6 mmol/L** — *below* the renal spill point of 18.4 — so **glycosuria is
zero at every setting and urine volume never moves.**

**Baron 1988 (Am J Physiol 255:E769), read in the same pass, gives the numbers:** whole-body
NIMGU rose **128 ± 6 → 213 ± 18 mg/min** while glucose went from euglycaemia (~90 mg/dL) to
hyperglycaemia (~220 mg/dL) — a **1.66-fold** rise for a **2.44-fold** stimulus.
Sub-proportional, not linear.

**WHY IT WAS NOT FIXED IN THE SAME PASS.** The insulin split is already a structural change,
and stacking a second makes neither testable on its own — the discipline ADR 0025 and ADR
0026 were deliberately separated under.

**THE FALSIFIER, STATED:** give NIMGU Baron's sub-proportional form and the ceiling should
rise and glycosuria should reappear. **If it does not, the linear term was not what capped
it** and the diagnosis is wrong.

**WHAT WOULD RESOLVE IT:** nothing external. The source is read, the numbers are in §11.7 of
`glucose_insulin_prereg.md`, and it is one pass.

---

### B23. A flaky `salt_step(raas = false)` failure — NEW, 2026-09-22

**Failed in 2 of 3 full-suite runs**, with `retcode Unstable` on the 103 mEq/day arm.
**Passes 8 of 8 in isolation**, including under `--check-bounds=yes` (the flag `Pkg.test`
adds) and in the testset's exact call order — `raas = true` then `raas = false` — run three
times in one process, **bit-identical** each trial (shift 1.7837 and 2.0453). So it is **not
solver nondeterminism** in isolation.

**THE COUNT WAS FIRST WRITTEN AS "2 OF 2" AND THAT WAS OVER-CLAIMED.** The third run passed.
It also carried the `beta_cell` correction, which changes the insulin term and could have
moved the model off the boundary — **so runs 1–2 and run 3 are not strictly comparable, and
neither "intermittent" nor "fixed" is established.** Recorded that way rather than resolved
by the reading that happens to be convenient.

**IT WAS CAUGHT RATHER THAN ABSORBED**, by the `successful_retcode` assertion ADR 0026 added
after `salt_step` silently reported a failed solve as a result. The assertion worked; that is
the good news in this entry.

**A SINGLE PASS IS NOT PROOF OF STABILITY**, any more than a single wall-clock timing is
evidence of speed — the same reason `CLAUDE.md` refuses to quote a whole-suite runtime. The
honest reading is that the RAAS-off salt step is now **marginally stable** and something —
solver step selection, machine load during a concurrent run — can tip it.

**WHY IT MIGHT HAVE BECOME MARGINAL:** ADR 0030 gave the model a second osmotic effector, and
with RAAS off the ADH-off/thirst-on branch does more work (the redundancy ADR 0030 measured).
ADR 0031 then made plasma glucose an implicit algebraic unknown. Either could narrow the
basin.

**WHAT WOULD RESOLVE IT:** bisect the SUITE, not the model — run `runtests.jl` with
progressively fewer preceding testsets until the failure disappears, and the last one removed
is the culprit. `IPE_TESTS` filters by name, so this needs a temporary ordering hack rather
than the existing switch.

**FIRST, ESTABLISH WHETHER IT STILL HAPPENS.** Run the full suite three more times on the
current tree. If it never recurs, the `beta_cell` correction moved it and this entry closes
with that recorded; if it does, bisect the suite.

**Do not "fix" it by loosening the assertion** — it is the instrument, and it has caught the
same thing twice already.

---

### B24. Every equation in the model is single-sourced — NEW, 2026-09-23

**Directive 1.16 was set today and `validation/form_sourcing_audit.md` is the baseline
measurement.** Of **32 empirical relations**: 11 have no citation for their form, 19 rest
on exactly one primary, 2 have a systematic review, and **0 rest on two primaries.**

**THIS IS DEBT, NOT A DEFECT.** No result in the repository is known to be wrong because
of it. The claim is narrower and worse: **nothing has ever checked**, and directive 1.16's
worked example is a case where every source was good and the model was still unable to
represent the physiology.

**RANKED, BY CONSEQUENCE RATHER THAN BY THE AUDIT'S FLAT COUNT:**

1. **`Renal.GFR` — the autoregulation plateau has NO form citation.** Every
   pressure–natriuresis result in this model passes through it. Both breakpoints are
   sourced rows; the piecewise shape between them is not. **Start here.**
2. **`Renal.I_glu` and the glucose axis** — Merovci 2021 alone, and it is the subsystem
   directive 1.16 was written about. **A recent review of diabetes classification is owed
   before any further glucose work**, including B22.
3. **The four first-order lags** — `Baroreflex.D(sp)`, `D(tpr_mod)`, `D(hr_mod)`,
   `Renal.D(vn_sig)`. Time constants sourced, **order of the lag assumed.** ADR 0022
   records a lag doing structural work, so the order is not cosmetic.
4. **`Baroreflex.drive` and `hr_drive`** — both `divergent`, both Kent 1972, **counted as
   two single-source rows and not as a pool.**
5. **Everything on a default-OFF path** (`BodyFluids.J_store`, `Circadian.renal_mod`) —
   cheapest debt in the file, lowest priority.

**WHAT WOULD CLOSE IT.** Not a re-sourcing pass — that is weeks and would mostly
reconfirm. **Item 1 sourced, and 1.16 applied to every NEW subsystem from today.** The
audit regenerates from the ledger, so progress is measurable rather than asserted.

**WHAT WOULD MAKE IT WORSE.** Adding a second citation that agrees, from the same group or
reusing the same published equation. That is one source wearing two names, and it would
make the count improve while the constraint did not.

---

### B25. Should a seventh gate read `form_citation`? — NEW, 2026-09-23, OWNER'S DECISION

**The case for.** This repository's own repeated lesson is that a true sentence in prose
goes stale silently and **no gate can see it** — §5 item 12's stale SHA, §3.15's stale
Lobo claim, the `calibrated` count that said one while the ledger said two. **B24 is
currently a prose claim of exactly that kind.** `check_tolerances.py` is the precedent: it
made directive 1.13 structural, and it is the gate that has caught the most.

**The case against, and it is the standing rule.** *"Do not add tooling unless something
breaks that cannot be worked around."* Nothing has broken. The audit regenerates in under
a second from the ledger, so the count can be refreshed by running it rather than by
gating it.

**The shape it would take if built.** A `form_sources` column, or a count parsed from
`form_citation`, with **the existing grandfathered-unsourced set extended** — the pattern
`check_relations.py` already uses, where the list shrinks only and is printed as debt.
Landing it red would deadlock every merge, which this repo has done to itself before.

**NOT BUILT. Awaiting a decision**, because it is a cost the owner should choose rather
than one I should assume.


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

1. ~~**The baroreflex has one effector while heart rate exists.**~~ **BUILT 2026-09-08**
   (ADR 0022, §3.38). The chronotropic arm exists: one error signal, two efferent
   limbs, `hr_mod` on heart rate alongside `tpr_mod` on resistance. Sourced from
   Laitinen 1998, phenylephrine bolus in 117 healthy adults, and it arrives as a
   **sexed pair**, the first in the neural subsystem.

   **THIS ENTRY SAID "NO NEW STATE" AND THAT WAS WRONG.** It was true of the
   pre-registration and false of what got built, and it stood while §3.38 said the
   opposite — the contradiction this repository exists to prevent. The arm carries a
   **0.4 s vagal lag (`BR.CARDIAC.TAU`) and IS the eleventh state.** An algebraic
   `hr_mod` closes an instantaneous loop through arterial pressure, `CO → MAP → err →
   hr_mod → CO`, and `structural_simplify` paid for it by promoting `Blood.CO` to a
   state instead. **The state was paid either way**; it is now paid on a variable with
   a physical meaning and a sourced time constant.

   **The pass turned on a stop condition, not on the value.** Before anything was
   built it had to be settled whether `BR.OPEN_LOOP_GAIN` was the whole reflex or the
   vasomotor arm alone, because a second effector on top of a whole-reflex gain
   doubles the reflex with every gate still green. It is the vasomotor arm: Yamasaki's
   gain decomposes through plasma noradrenaline and a cholinergic limb cannot appear
   in a noradrenergic product, and Dutoit 2010 finds the two arms **uncorrelated**
   within 53 healthy adults at R² = 0.0003.

   **What is left of it is the low-pressure limb, and it now has a number.** Jensen
   2013 measures pulse rate *rising* on a saline load while pressure stays flat, which
   this arm cannot produce. That is the cardiopulmonary receptors, still absent, and
   ADR 0022's falsifiable test 5 asserts the omission rather than describing it.
2. **RENAL SYMPATHETIC TRAFFIC — SEARCHED 2026-09-15, NOT BUILT, AND THE REASON IS
   THE MANOEUVRE.** `validation/cardiopulmonary_sympathetic_prereg.md` §4 required an
   admissible source to **separate** cardiopulmonary from arterial baroreceptor
   unloading, and named low-level lower-body negative pressure as the way. **That premise
   is refuted.** Arterial baroreceptors are consistently unloaded at −10 and −15 mmHg;
   the selective reading is a pre-1975 convention the field retired after 1985.

   So the sympathetic gain is **not independently identifiable**, and with one datum —
   van den Bosch's salt–renin ratio — it and `RN.MD.RENIN_GAIN` would trade off freely.
   **Branch S3: the renin arm is not built and `RN.MD.RENIN_GAIN` is untouched.**

   **What would unblock it:** a manoeuvre that genuinely separates the two afferents, or
   a direct measurement of renal sympathetic outflow against central volume in healthy
   humans. Not more searching on LBNP.

   **AND THE CHRONOTROPIC HALF MOVED COMPONENTS.** The human heart-rate rise on atrial
   loading **persists in transplant recipients and after pharmacological denervation**,
   and is present in isolated sinoatrial node and single pacemaker cells. It is largely
   **intracardiac mechano-electric coupling, not a reflex** — so if built it belongs in
   `Cardiovascular.jl` keyed to central volume, **not** in `Baroreflex.jl`, and it brings
   none of the other efferents with it. An intrinsic pacemaker property does not release
   renin or vasopressin. **That is the arm that would satisfy ADR 0022's test 5**, and it
   needs a quantitative human gain that this pass did not obtain.
   **RODDIE 1957 WAS OBTAINED BY THE OWNER ON 2026-09-16 AND READ IN FULL, AND IT IS A
   VASOMOTOR PAPER.** The secondary literature cites it as the human demonstration of a
   chronotropic response to atrial loading. **Heart rate appears in one sentence** — it
   "increased in most subjects", and was "inconspicuous" in the very subject whose
   forearm dilatation was marked — **with no numbers anywhere in the paper.** True, thin,
   and not what was measured.

   **What it does establish is better than what it was cited for.** The cardiopulmonary
   **vasomotor** arm in healthy humans, with the isolation this pre-registration demanded
   and could not get from lower-body negative pressure: arterial pressure often
   unaltered, pulse pressure sometimes *reduced* while dilatation was marked, no
   correlation between dilatation and either pressure, and independent evidence that
   carotid stretch receptors in man do not change limb vessel calibre. Controls rule out
   splanchnic pooling and cephalic venous congestion. Leg raising roughly **doubles**
   intact forearm muscle flow while a nerve-blocked forearm does not move, and the intact
   forearm approaches but never exceeds the blocked one — so the mechanism is
   **withdrawal of sympathetic tone**, not active vasodilator nerves.

   **It still yields no ledger row, and the authors say why twice.** They could not
   correlate the dilatation with pressure change, and of the venous pressure rise they
   write that it *"cannot be concluded that these changes represent the stimulus
   responsible"*. The response is forearm **muscle** flow with skin explicitly
   unaffected, so converting it to a whole-body resistance needs the muscle share of
   systemic resistance — the cross-scale composition §3.26 records going wrong.

   **So the sourceable cardiopulmonary arm is the VASOMOTOR one, not the chronotropic
   one**, and what it lacks is a gain rather than a phenomenon.

2b. ~~**Renin is pressure-only.**~~ **HALF BUILT 2026-09-05** (§3.31, §3.32, ADR 0021).
   The macula densa arm exists, and the ceiling §7 recorded against the model — a renin
   ratio capped at 1.14 across the human salt range, against a measured 2.73 — is
   exceeded. **Potassium arrived with it**, because aldosterone is one node and renin is
   only half its input; the model reports plasma potassium for the first time.
   **RENAL SYMPATHETIC TRAFFIC IS STILL ABSENT**, the macula densa gain absorbs whatever
   it would have contributed, and B9 is where that shows up as a number. That arm is the
   remaining half and it is the next renal item.
3. **Acid–base: pH is BUILT, compensation is NOT** (§3.29, 2026-09-05). Arterial pH
   composes from a sourced pK, solubility, bicarbonate and PCO2 — 7.42 against a human
   7.40, with the 0.02 residual named as an unapplied venous-to-arterial offset. **What
   is still missing is the bicarbonate STATE**: both halves of the balance failed to
   source (renal gain not measured in health; endogenous acid production spans threefold,
   22 against 70 mEq/day). So there is **no renal compensation for a respiratory
   disturbance**, and by ADR 0020 decision 3 **no respiratory compensation for a metabolic
   one**. The oxyhaemoglobin curve still ignores pH, so no Bohr shift.
4. ~~**No metabolic substrate.**~~ **BUILT 2026-09-05** (§3.27, §3.28). Oxygen
   consumption, the Fick relation, mixed venous content and saturation, and the
   extraction ratio. It needed no new component and, initially, no new source — the
   metabolic row ADR 0018 said was missing existed under another name. Oxygen is still a
   forward computation with no feedback, which ADR 0018 decides deliberately.
5. **RED CELL MASS IS A PARAMETER, NOT A STATE — so it can be lost and never
   recovered. CLOSED 2026-09-16 BY ADR 0023.** Found 2026-09-10 by building the
   haemorrhage perturbation and watching the recovery, and the arithmetic was available
   before the run rather than after it.

   `V_blood = f_pv*V_ecf + Hct*BV0`. A bleed removed red cells permanently, blood
   volume is what sets cardiac output and therefore pressure, so the loop had to restore
   it — and the only route left was plasma. Plasma is 21% of extracellular fluid, so
   replacing **0.453 L of red cells cost 2.15 L of extracellular expansion**. Predicted
   16.71 L against a starting 14.56; observed 16.65. Every step was correct; the model
   simply never unwound.

   **WHAT IT TOOK, AND IT WAS NOT WHAT THIS ENTRY PREDICTED.** Red cell volume is now
   the twelfth state, haematocrit split into a reference parameter and a live variable,
   and haemoglobin became `MCHC × Hct_eff` — one parameter removed rather than added,
   because §3.24's implied MCHC was already a check that could have failed. The
   destruction term is at the ~120 day lifespan and the loop gain is DERIVED from
   Pottgiesser 2008's 36-day haemoglobin-mass recovery.

   This entry said the drive would be **renal oxygen delivery**. It is not, and it is not
   arterial content either — the pre-registration's own §4 named content and the test
   suite falsified it. See §3.41.

   **MEASURED AFTER: the bleed unwinds completely.** Blood volume falls by exactly 1 L,
   MAP 87 → 73 instantly and back to 85 within the hour, HR 62 → 64, renin 1.25 → 2.23,
   sodium excretion to zero; haematocrit then dilutes 0.453 → 0.39 over three days while
   extracellular volume overshoots to 16.1 L; red cell mass regenerates with a 24-day
   time constant, and by day 200 everything is back — V_ecf 14.560 against a starting
   14.56, Hct 0.4530, Hb 15.30, MAP 86.99, renin 1.251, sodium excretion 205.

   **IT WAS THIS MODEL'S FIRST OXYGEN FEEDBACK**, and the coupling count 21 → 22 with the
   new edge outbound from blood is the tripwire ADR 0018 left for exactly this. Red cells
   are now the slowest state by a factor of three over thyroxine.

   **WHAT IS STILL OPEN.** The recovery time constant is an ESTIMATION SET and the model
   reproducing it is not agreement. It lumps iron availability into erythropoietic drive,
   so an iron-deficient donor — who may take ten times as long — cannot be represented.
   It is a male number applied to both sexes. And the model still cannot represent
   anaemia of renal disease, or any erythropoietic response to dilution rather than loss.

6. **No age dimension.** The alveolar–arterial difference widens with age and carries a
   young-adult value; so does maximal urine concentrating ability.
7. **Sea level, awake, resting, adult, non-pregnant, healthy.** No hypoxic ventilatory
   drive, no posture, no exercise, no sleep, no circadian modulation switched on.
8. **One thyroid hormone.** Free thyroxine only — no triiodothyronine, no deiodination,
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

### B1d. An open balance study exists that the model has never been tested against

**HANDOVER §3.48.** Found while searching for Drummer's full text. Van Regenmortel N et al.
*J Crit Care* 2022;67:157–165, **PMID 34798374, open access CC BY-NC-ND, full text read**.
Healthy arm (MIHMoSA): 12 volunteers, crossover, 48 h, no oral intake, 154 vs 54 mmol/L
maintenance fluid at 25 mL/kg/day; habitual intake 124 mmol/day.

**Two endpoints the model has never been judged on:**

1. **How long realignment takes.** Urinary sodium excretion plateaus *"after approximately
   24 h"* and output matches intake by the end of 48 h. **This model has only ever been
   tested on where a salt step ENDS UP, never on how long it takes to get there.**
2. **How much of a sodium load appears as fluid.** ΔNa 171 mmol → Δfluid **590 mL**. At
   plasma tonicity that sodium would carry 1221 mL, so **only 48% appeared as fluid.** The
   paper's own conclusion: *"sodium-induced fluid retention is eventually limited."* This
   bears directly on `BF.NA.OSMOTICALLY_INACTIVE_FRACTION` (`assumed` 0.15) and ADR 0004,
   which is **PROVISIONAL and switched off by default**.

**Not yet used, and it must not be used without a pre-registration.** It is a different
manoeuvre from the acute bolus, so it does not settle B1c; and the subjects **fasted for
48 h**, which the paper itself names as a confound on the absolute balances. The
between-treatment contrast is the defensible quantity.

### B1e. Water cannot leave ahead of salt in this model, and in people it does

**HANDOVER §3.49.** Drummer 1992's full text reports **two** monoexponential half-lives
after an acute isotonic load: **7 h for body weight, 10 h for sodium balance.** Weight comes
back first — a ratio of **0.70**. **The model's ratio is 1.065**, because `V_ecf` is tied to
`Na_ecf` and there is nowhere to put sodium that does not carry water.

**Three independent human numbers point the same way:**

| | |
|---|---|
| Drummer's half-life dissociation | 7 h weight against 10 h sodium |
| Van Regenmortel 2022 | ΔNa 171 mmol → Δfluid 590 mL — **48%** of what plasma tonicity implies |
| Drummer's haematocrit | −10.0% at 6 h; model −6.4% |

**`BF.NA.OSMOTICALLY_INACTIVE_FRACTION` is `assumed` at 0.15, and ADR 0004 is PROVISIONAL
with `storage` defaulting to false**, so nothing in the running model reads either row.

**The third number is probably NOT the store** — a haematocrit shortfall at 6 h is what a
constant `f_pv` would produce, since the model equilibrates an infused load across plasma
and interstitium instantly. It is listed because it must not be swept into the store's
evidence by accident.

**Stage 1 is done — HANDOVER §3.50.** The store **can** produce the dissociation, which
refutes the pre-registration's own §2.1 prediction: the ratio crosses 0.70 at `f_store`
≈ **0.40**, against a ledger value of 0.15 that leaves it at 1.046 — indistinguishable from
switched off.

**But it reproduces the ORDERING and not the SPEED.** Drummer needs volume 7 h *and* sodium
10 h, both faster than this model's 13.3 and 12.5. The store speeds volume and **slows**
sodium, pivoting the pair rather than moving both down: at the crossing, volume is 10.5 h
against 7 and sodium 14.9 h against 10. Jensen degrades 110.2 → 88.7 against a measured 122
— still inside the harness band, and still the wrong way.

**So the store is necessary and not sufficient**, and something else must speed the whole
clearance up. The pre-registration forbids this pass from finding out what, because §3.49
withdrew a published conclusion for reading a water defect as a sodium one.

**What it needs now is sourcing, not fitting.** `f_store` ≈ 0.40 is a **diagnostic**.
Titze's balance and skin-sodium work has never been opened in this repository, and ADR 0004
keeps `provisional` until it has been. `storage` stays `false` by default.

### B1f. The sodium-limb discrepancies are inside the measurement error — CLOSED 2026-09-17

**HANDOVER §3.53.** Of the five endpoints the acute/chronic tension was built on, **two have
no computable interval at all** (Drummer's half-lives, n = 6, no dispersion published),
**one is not an interval** (the meta-analytic 1.70–2.30 is a spread of three point
estimates), and the two that can be computed span **eleven-fold** (Jensen, −18% to +502%)
and **three-fold from rounding alone** (van den Bosch: MAP printed as integers, so the
difference is 1–3 mmHg).

**A factor of two is inside every one of them.** Directive 1.13 and failure mode #9.

**What stays open is not a number.** The direction results survive — the model has
Drummer's weight/sodium ordering backwards, ADR 0010's saturating specification points the
wrong way, and `BF.NA.STORAGE_TAU` was set from a rhythm period. **Those are signs and
category errors, and they do not depend on the magnitudes.**