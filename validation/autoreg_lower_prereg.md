# Pre-registration: RN.AUTOREG.LOWER extraction

**Written BEFORE any literature was read, as required by `validation/pooling.md`
("Declare the pooling rule before extraction... A pooling rule chosen *after*
seeing the numbers is unfalsifiable").**

Date: 2026-08-27. Target: `RN.AUTOREG.LOWER`, the lower breakpoint of the GFR
autoregulation plateau in `src/components/Renal.jl`, currently 80.0 mmHg with
citation "Standard physiological reference. VERIFY." and `species = human`.

Companion to `validation/autoreg_upper_prereg.md`, which settled the upper
breakpoint on 2026-08-21 and explicitly deferred this row: "Fixing it needs its
own pre-registered extraction." This is that extraction.

## Why this row, and why now

Three things already established, none of them found by this pass:

1. The citation is not a reference. The row asserts `extraction_method =
   reported`, i.e. that a source exists, and no source is named.
2. The row's own notes record that 80 mmHg traces to **Shipley RE, Study RS, Am J
   Physiol 1951;167:676-688 (PMID 14903093)** — **dog** — and that `species`
   reads `human`, which is not supported. A 2025 review
   (doi 10.22514/sv.2025.001) concludes that human evidence is insufficient to
   state 80 mmHg is the lower limit, and Cupples & Braam 2007
   (doi 10.1152/ajprenal.00194.2006) put the animal limit at ~75 mmHg in dog and
   ~85 mmHg in rat — not one number even across species.
3. `CV.MAP.SETPOINT` moved 93 → 87 on 2026-08-27, so the operating point moved
   **toward** this breakpoint. It now sits 7 mmHg above it.

## Question

Is there PRIMARY literature, in HUMANS, that measures the arterial or renal
perfusion pressure BELOW which GFR ceases to be autoregulated?

## The asymmetry with the upper limit, fixed in advance

The upper breakpoint was rescued from its species problem by an **ethical
ceiling**: no human study raises arterial pressure to find where autoregulation
fails, and none may, so under ADR 0006 (amended 2026-08-21) a well-conducted rat
study is the evidence rather than a placeholder for a human study that cannot be
run.

**That argument is not available here and must not be reused.** The human
experiment for the LOWER limit is performable and has repeatedly been performed —
the human renal autoregulation literature lowers pressure as a matter of course
(Parving 1984, New 1998, Christensen 2001, Christensen 2003 are already named in
`autoreg_upper_prereg.md`). Where the human experiment can ethically be done,
animal-only provenance is a **gap**, not a ceiling, and does not earn the E2
promotion. Recorded now so that the amended ADR 0006 is not applied by analogy
after the fact to whatever the search happens to return.

## The only outcome that can move the model, stated before extraction

The autoregulation relation is piecewise:

    GFR ~ GFR0 * ifelse(MAP < MAP_lo, MAP / MAP_lo,
                        ifelse(MAP > MAP_hi, MAP / MAP_hi, 1.0))

The model's three salt arms sit at MAP = 81.900 / 84.450 / 87.001 mmHg. All three
are above `MAP_lo = 80`, so all three are on the plateau and GFR = GFR0 in every
one.

**Therefore any sourced value at or below ~81.9 mmHg leaves every current result
bit-identical, and only a value above ~81.9 mmHg changes the model at all.**

This is declared here because it is exactly the kind of fact that, discovered
mid-extraction, silently biases branch selection toward "no change". The
consequence is fixed in the constraints below: the value follows the evidence
whether or not it moves the model, and a value that moves the model is escalated,
not avoided.

## Declared decision procedure

Applied in strict order; the first branch that matches is taken. Fixed before
extraction and not revisited after seeing numbers.

1. A meta-analysis or pooled analysis of human studies reporting the lower
   breakpoint exists → `pooling_rule = meta-analysis`; take its estimate and
   dispersion, record its k.
2. ≥ 2 independent HUMAN primary studies each reporting a numeric lower
   breakpoint, with n and dispersion → `pooled-inverse-variance`.
3. Same, with n but no dispersion → `pooled-n-weighted`.
4. Same, without n → `pooled-unweighted`.
5. Exactly 1 human primary study reporting a numeric lower breakpoint →
   `single-source`, k = 1, said plainly.
6. **Zero human primary studies report a breakpoint, but human studies establish
   that GFR is PRESERVED down to some lowest tested pressure** → take the
   **lowest human-tested pressure at which GFR was still preserved**. This is a
   BOUND, not an average, so no pooling rule applies and none is invented; record
   `single-source` with the study named and k = number of human studies
   consulted. The observation is **censored in the opposite direction from the
   upper limit**: GFR preserved at pressure P means the true breakpoint is ≤ P,
   so setting `MAP_lo = P` asserts the breakpoint at the edge of evidence and
   makes GFR in the model fall EARLIER (at a higher pressure) than reality. That
   is the conservative direction, and it is the same discipline applied to
   `RN.AUTOREG.UPPER = 160`.
7. **Zero human primary studies and no usable human censored bound** → the
   parameter is NOT human-sourced and may not be made so. Cross-species pooling
   is prohibited by `pooling.md`, so the dog (~75) and rat (~85) values may NOT
   be averaged, and `range-midpoint` is prohibited for new entries. Take the
   single best-conducted animal primary, record `species` as what it actually is,
   record the tested range and preparation, and record the divergent value from
   the other species as a **declared conflict** rather than resolving it. Per the
   asymmetry section above this is logged as **debt with a named source** — an
   improvement on an unnamed reference, but not evidence under a ceiling.
8. **No defensible number in any species** → the row stays at 80.0, `species` is
   still corrected off `human`, and the debt is recorded. **A value will not be
   manufactured to close the row.**

## Constraints fixed in advance

- **The value is not to be chosen to preserve the current operating point.** If
  the evidence returns a breakpoint above ~81.9 mmHg, the low-salt arm leaves the
  plateau, GFR falls with pressure, and steady states move. That outcome is to be
  recorded, tested and escalated to an ADR — not sidestepped by taking a later
  branch.
- **The value must lie inside the evidenced validity range of the
  pressure-natriuresis form, ~55–160 mmHg** (`RN.PRESSURE_NATRIURESIS.SLOPE`
  notes: Roman & Cowley 1985 rat 90–160; Osborn/Francisco/DiBona 1981 dog
  55–137). A breakpoint below 55 mmHg would place the autoregulation kink in a
  region where the equation it modifies has no support; if branches 1–7 return
  one, it is recorded with its citation and the model's range limitation is
  recorded alongside it, and the conflict is escalated rather than silently
  resolved.
- **`species` is corrected to what the source actually is**, regardless of the
  consequence for `source_tier`. Tier and species are independent axes; on
  `RN.AUTOREG.UPPER` the tier rose while the species fell, and both moved
  honestly.
- **A "reported" row must name its source.** Whatever branch is taken,
  `extraction_method` must end up consistent with what is actually in the
  citation field.

## Falsifiable check to run after, whatever the branch

`Pkg.test()` plus the five gates, and additionally: assert that the low-salt arm
MAP (81.900) sits above the adopted `MAP_lo`, or if it does not, that the changed
steady states are reported rather than repinned silently. The 294 existing test
pins are the tripwire; any of them moving is the signal that branch selection had
a model consequence, which the escalation constraint above then governs.

## Out of scope

- `RN.AUTOREG.UPPER` — settled 2026-08-21, not reopened.
- **The piecewise FORM of the autoregulation equation.** `relations.csv` row
  `Renal.GFR` carries an empty `form_citation` and stays in
  `GRANDFATHERED_UNSOURCED`. This extraction sources a NUMBER; it does not source
  the EQUATION, and finishing one must not be reported as finishing the other.
- `RN.PRESSURE_NATRIURESIS.SLOPE` and `G_pn` / ADR 0013.
- The other six rows carrying "Standard physiological reference. VERIFY."
- `pooling_rule` / `n_studies` / `pooling_notes` are still not columns of
  `parameters.csv` despite `pooling.md` specifying them. They will be recorded in
  prose, following the precedent set by `RN.PRESSURE_NATRIURESIS.SLOPE` and
  `RN.AUTOREG.UPPER`. Schema debt, logged not fixed — per directive 1.2, do not
  add tooling.
