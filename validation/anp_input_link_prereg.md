# Pre-registration: sourcing the ANP INPUT link (blood volume to plasma ANP)

**Written 2026-08-22, BEFORE any paper was read.**
Binding under `validation/pooling.md`. Third in the series, after
`autoreg_upper_prereg.md` and `anp_sourcing_prereg.md`.

## The gap being closed

`docs/adr/0010-anp-volume-natriuresis.md` is Proposed with one blocker. Everything
sourced so far describes what ANP does **once it is in the plasma**:

    [ANP] --> reduced distal fractional Na reabsorption     SOURCED
              De Nicola 1997, Morice 1988, Biollaz 1986, human

Nothing sourced supplies the input:

    V_blood --> [ANP]                                        NOT SOURCED

Without it, `V_blood -> ANP` is a fitted constant. That is exactly how
`RN.PRESSURE_NATRIURESIS.SLOPE` reached 20.0 with `species: human` on a number nobody
measured, and it is the failure this whole provenance layer exists to prevent.

## The variable actually needed, and why it is not atrial stretch

The mechanistic relation in the physiology is **atrial wall stretch (transmural
pressure) -> ANP secretion**, established in isolated perfused atria. IPE cannot use
it. ADR 0002 made the model cycle-averaged, so there is no right atrial pressure and no
wall tension state. The model's proposed sensed variable is `V_blood`.

**This makes human data MORE applicable, not less.** Sourcing stretch -> secretion from
rabbit atria would source a relation the model does not contain, and would then need a
second unsourced link (`V_blood` -> atrial transmural pressure) to connect it - trading
one gap for two. Human volume-perturbation studies measure the composite relation the
model actually uses.

Record this reasoning now so that if the search fails and isolated-atria data is used
instead, the extra link is a **declared** cost rather than a discovered one.

## Search order, declared in advance

Human paradigms first, in this order. Each manipulates central/total blood volume and
measures plasma ANP.

1. **Head-out water immersion** - controlled, reversible, non-invasive central volume
   expansion. Best human analogue of the model's perturbation. Includes PMID 2528914,
   surfaced during the previous search and not yet read.
2. **Lower body negative pressure** - the same manipulation in reverse.
3. **Graded intravenous saline loading** with plasma ANP measured.
4. **Controlled sodium diet / posture**, including the two-point observation already in
   hand from Kelly & Nelson 1987 (91.7 -> 179.7 pg/ml under fludrocortisone).

**Declared fallback, not a retreat:** if none of the above yields a usable gain,
isolated perfused atrial preparations (rabbit, rat) become the source. Under ADR 0006
as amended 2026-08-21 that is legitimate E2 evidence with species, preparation and
range recorded - cannulating a human atrium to titrate transmural pressure is not a
study anybody may run. It carries the extra-link cost named above, which must then be
written into ADR 0010 as a known structural weakness.

## The discrimination problem, declared before it bites

Volume-perturbation paradigms change several things at once. Immersion alters central
volume, renal perfusion, sympathetic tone and posture simultaneously. An association
between ANP and natriuresis in that setting does **not** isolate the volume -> ANP
gain.

**Preference order for study design:**

1. Studies using **ANP receptor blockade or clearance-receptor manipulation** to isolate
   the ANP contribution
2. Studies **clamping other hormones** (the Roman & Cowley approach that made the
   pressure-natriuresis form usable)
3. Studies reporting plasma ANP against a **quantified** volume change (litres, % body
   weight, or measured central volume shift), with no isolation
4. Studies reporting only a direction of change

**Tiers 3 and 4 may source the FORM but not the GAIN.** A number extracted from an
uncontrolled paradigm will be labelled as such.

## Pooling rules, declared in advance

The quantity is a slope: change in plasma ANP per unit change in blood volume.

1. **Meta-analysis** reporting a pooled estimate -> `meta-analysis`, take its dispersion
   and its k, do not re-pool
2. Individual studies with n and dispersion -> `pooled-inverse-variance`
3. Individual studies with n only -> `pooled-n-weighted`
4. **If expressed as a fold-change or ratio** (e.g. "ANP doubled") -> `pooled-geometric`,
   per `pooling.md`, because the arithmetic mean of a ratio and its reciprocal is biased
   away from 1
5. One study -> `single-source`, k=1, declared, not dressed as consensus

`range-midpoint` is **prohibited**. **No cross-species pooling** under any
circumstances - if both human and animal values are found, they are recorded separately
and the human one is used, with the animal one as a comparator only.

## Stop conditions, declared in advance

1. **If no usable gain is found in any species, ADR 0010 does not proceed to Accepted,
   and no `Anp` component is written.** A component whose input gain is fitted would
   reproduce the exact defect the ADR was raised to correct. Saying "blocked, and here
   is what is missing" is an acceptable outcome of this work.
2. **A fitted or assumed input gain is not an acceptable substitute.** Not even
   temporarily, not even marked provisional. `RN.PRESSURE_NATRIURESIS.SLOPE` entered
   this repo exactly that way in sprint 2 and has cost three sessions.
3. **No citation is recorded without opening it.** PMID 2966064 was attributed to the
   wrong authors for two sessions because nobody did. Every citation entered from this
   search is fetched and its author list, journal and year verified against the record.
4. **A result that contradicts the model is a finding.** In particular, if the sourced
   gain implies ANP cannot carry ~40% of physiological natriuresis at physiological
   volume swings, that contradicts De Nicola 1997 and must be reported as a conflict
   between sources, not silently averaged.

## What would falsify the approach

If plasma ANP turns out to track something the model cannot compute - atrial transmural
pressure specifically, rather than blood volume - then `V_blood` is the wrong sensed
variable and ADR 0010's Decision section is wrong. The honest response is to say so and
reconsider whether ANP can enter a cycle-averaged model at all, not to proceed with a
proxy the evidence does not support.

Record the magnitude comparison against the outstanding **2.2x residual** either way.
ANP was shown in the previous sourcing to account for only about 0.39 of the 3.68x
slope inflation on a log basis. Nothing found here should be used to re-attribute that
residual without separate work.
