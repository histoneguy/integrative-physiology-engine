# Pre-registration: pooling the primary head-out immersion papers, and the central-to-total blood volume mapping

**Written 2026-08-22, BEFORE any paper was read.**
Binding under `validation/pooling.md`. Fourth in the series, after
`autoreg_upper_prereg.md`, `anp_sourcing_prereg.md` and `anp_input_link_prereg.md`.

Closes blockers 1 and 2 of `docs/adr/0010-anp-volume-natriuresis.md`, or reports that
they cannot be closed. Blocker 3 — the 2.2x residual — is **not** in scope here and gets
its own pre-registration; nothing found under this one may be used to re-attribute it.

---

## 0. A TENSION IN THE BLOCKER LIST, RECORDED BEFORE SEARCHING

ADR 0010's 2026-08-22 addendum does two things that do not sit together.

It **revises the component** to carry no ANP state:

> a **lumped volume-keyed natriuretic term**, algebraic in `V_blood`, whose magnitude is
> calibrated against volume-expansion natriuresis *as a whole* (the 40-50% figure)
> rather than against a plasma concentration.

And it **states blocker 1** as:

> The k primary immersion papers behind Epstein's 2.5-3x must be pooled properly under
> `pooling.md`. Until then there is no number, only a magnitude.

Epstein's 2.5-3x is the **plasma ANP fold-rise**. Under the revised design that quantity
is not a model parameter — no state carries it and nothing multiplies it. Pooling it
would produce a correctly-sourced number that the component does not use, which is a
more expensive failure than an unsourced one because it looks finished.

The parameter the revised component actually needs is a **natriuretic gain**:

    d(natriuretic term) / d(V_blood)

**Resolution declared in advance, and it is not a choice between them.** Head-out
immersion studies measure plasma ANP and urinary sodium excretion in the same subjects
over the same protocol. The same k papers serve both. This pre-registration therefore
extracts both quantities from one search:

- **Q1** closes blocker 1 exactly as written, and independently audits whether Epstein's
  review range is supported by its own primaries. `pooling.md` says the primary source
  wins when a review and its primaries disagree; that has not been tested here.
- **Q2** is the quantity the component needs.

If the two turn out to disagree about which papers are usable, **Q2 governs what gets
built** and Q1 is recorded as a review-vs-primaries audit only.

This tension was found by reading ADR 0010 before searching. Recording it here rather
than resolving it silently, because an ADR that names a blocker the component cannot use
will otherwise be closed by work that does not unblock anything.

---

## 1. WHAT IS BEING EXTRACTED

Three quantities. Q1 and Q2 come from one search over one literature; Q3 is a separate
search over a different one.

| # | Quantity | Unit | Becomes a ledger parameter? | Blocker |
|---|---|---|---|---|
| Q1 | Plasma ANP fold-rise, pre-immersion to immersion | dimensionless ratio | **No** — audit of Epstein 1989 against its primaries | 1 |
| Q2 | Natriuretic response to head-out immersion | mEq/min or mEq/3 h, and as fold-change | **Yes** — the lumped ANP-arm gain | 1 |
| Q3 | Central-to-total blood volume mapping | L central per L total, or the inverse | **Yes** — the input scaling | 2 |

**Q3 is the one that can sink this.** Immersion translocates blood centrally without
adding any; `V_blood` in `Cardiovascular` is total blood volume, which immersion barely
changes. Without Q3, Q2 has a numerator and no denominator. Declared consequence: **if
Q3 fails, Q2 cannot be converted into a `V_blood` gain and blocker 2 stays open even if
blocker 1 closes.** Q2 is then recorded as a sourced natriuretic response awaiting a
scaling, not as a parameter.

---

## 2. SEARCH STRATEGY, DECLARED IN ADVANCE

### Q1/Q2 — the immersion primaries

Epstein M, Norsk P, Loutzenhiser R. *Am J Nephrol* 1989;9:1-24 (PMID 2524162) is the
review carrying the 2.5-3x range. **Its reference list is the sampling frame.** Search
order:

1. **Retrieve the reference list of Epstein 1989** and identify every primary human
   head-out immersion study reporting plasma ANP against a pre-immersion baseline.
2. **Vesely 1989** (PMID 2532366) and **Rabelink 1989** (PMID 2528914) are already in
   hand from the previous search and are in the frame by default.
3. Supplement by direct search for human head-out / neck immersion studies measuring
   plasma ANP or atrial natriuretic factor, to catch primaries published after the
   review or missed by it. Papers found this way are **recorded separately** from the
   Epstein-frame set, because adding them changes what "the k papers behind Epstein's
   range" means.

### Q3 — the volume mapping

Different literature. Declared search order:

1. **Direct measurement during immersion** — central blood volume or intrathoracic blood
   volume measured (indicator dilution, radionuclide, impedance) alongside total blood
   volume or plasma volume, in the same subjects.
2. **Posture and lower-body negative pressure** studies quantifying the same
   translocation, as the reverse manipulation.
3. **Any source giving the fraction of total blood volume resident in the central /
   intrathoracic compartment** at rest in supine and upright humans. A fraction plus a
   measured central change gives the mapping arithmetically.

**Declared fallback:** none. If Q3 is not measured, it is not assumed. See stop
condition 4.

---

## 3. INCLUSION AND EXCLUSION, DECLARED IN ADVANCE

**Include:** human subjects; head-out (neck-level) water immersion; thermoneutral water,
declared as 33-36 C; a pre-immersion or seated-control baseline in the same subjects;
immersion duration >= 60 min.

**Exclude, with the reason recorded per paper:**

- Patient populations — cirrhosis, heart failure, hypertension, renal disease. The model
  is a normotensive 70 kg adult. De Nicola's GN and CRF arms were excluded on the same
  grounds in the previous sourcing.
- Non-thermoneutral water. Temperature independently drives the response.
- Concurrent drug administration **unless** the paper carries a placebo or pre-drug
  control arm, in which case **the control arm only** is extracted. Rabelink 1989's
  enalapril repetition is handled this way: the non-enalapril immersion arm is the
  extractable one.
- Immersion below neck level (xiphoid, waist) — a different central volume shift.
- Studies reporting only a direction of change, or only a figure with no extractable
  values. These are counted in k_screened but not in k_pooled, and the count of each is
  reported.

**Sodium intake is recorded, not used as an exclusion.** Baseline sodium state modulates
the response, and excluding on it after seeing the values would be a post-hoc filter.
It is recorded per paper and, if the pooled estimate is heterogeneous, it is the first
declared covariate to inspect — as an observation, not a re-pool.

---

## 4. INDEPENDENCE, DECLARED IN ADVANCE

Epstein's group published head-out immersion studies repeatedly over two decades, often
in small cohorts of healthy male volunteers. **Overlapping subjects are likely.**

Rule: where two papers share a senior author and report a plausibly overlapping cohort —
same institution, same era, same n, same protocol — they count as **one** independent
study. The paper with the more complete ANP and UNaV time course is extracted; the other
is listed as excluded-for-overlap with the judgement recorded in `pooling_notes`.

`n_studies` in the ledger means **independent** studies. A k inflated by counting one
cohort three times is precisely the defect `n_studies` was added to make visible.

---

## 5. ENDPOINT TIMING, FIXED IN ADVANCE

This is the choice most vulnerable to being made after seeing the data. ANP rises within
the first hour and Epstein's range is quoted "by the end of the 2nd or 3rd h", so peak
timing varies between papers and picking per-paper maxima would bias every estimate
upward.

**Primary endpoint, fixed now:**

- **Q1** — plasma ANP at **180 min** of continuous immersion, divided by the
  pre-immersion baseline in the same subjects. If the protocol is shorter than 180 min,
  the end-of-immersion value is used and the duration is recorded. If sampling does not
  land on 180 min, the nearest sample **at or before** 180 min is used. Per-paper peaks
  are recorded alongside but are **not** the pooled endpoint.
- **Q2** — cumulative or mean urinary sodium excretion over the immersion period against
  the same subjects' control period, expressed both as an absolute increment and as a
  fold-change.

Any deviation forced by how a paper reports its data is recorded per paper in
`pooling_notes`, with the deviation named.

---

## 6. POOLING RULES, DECLARED IN ADVANCE

Both Q1 and Q2-as-fold-change are **ratio quantities**. `pooling.md` rule 4 governs
ratios, and it overrides the general preference order for this reason: the arithmetic
mean of a ratio and its reciprocal is biased away from 1.

1. If a **meta-analysis or systematic review of immersion ANP or natriuresis** reports a
   pooled estimate with a stated method — `meta-analysis`, take its estimate, dispersion
   and its own k, do not re-pool. Epstein 1989 does **not** qualify: it reports a range,
   not a pooled estimate, which is the whole reason this document exists.
2. Otherwise **`pooled-geometric`** on the per-study point estimates, computed in log
   space. Where n is available, weight in log space by n and record the weighting in
   `pooling_notes`; the rule stays `pooled-geometric`.
3. Dispersion is reported as the geometric SD, and the min and max of the contributing
   estimates are recorded so the review's range can be compared against the primaries.
4. **Q2's absolute increment** (mEq/min) is not a ratio and takes the standard order:
   `pooled-inverse-variance` if SD and n are available, else `pooled-n-weighted`, else
   `pooled-unweighted`.

**`range-midpoint` is prohibited.** 2.75x will not be recorded under any circumstances.
**No cross-species pooling.** This search is human-only; Schwab 1986 (rat) stays a
comparator and is not pooled with anything.

---

## 7. STOP CONDITIONS, DECLARED IN ADVANCE

1. **k_pooled < 3 independent studies for Q2 means no parameter is recorded.** Two
   studies do not become a pooled value; they become `single-source` twice over, and
   `pooling.md` forbids dressing that as consensus. The blocker stays open and the ADR
   stays Proposed. **"Blocked, and here is what is missing" is an acceptable outcome** —
   it was the acceptable outcome declared in the previous two pre-registrations and it
   remains one here.
2. **No citation is recorded without opening it.** Author list, journal, year, volume and
   PMID verified against the retrieved record for every entry. PMID 2966064 carried the
   wrong authors for two sessions; that is the standing reason for this condition.
3. **No fitted or assumed value substitutes for a missing one.** Not provisionally, not
   marked TODO. `RN.PRESSURE_NATRIURESIS.SLOPE` entered this repo that way.
4. **Q3 is not assumed.** If the central-to-total mapping is not measured anywhere, the
   honest outcome is that IPE's `V_blood` cannot represent an immersion perturbation
   without an unsourced scaling, and ADR 0010 must say so. A plausible-looking fraction
   from a textbook is exactly the failure mode of `RN.AUTOREG.LOWER`, whose citation
   reads "Standard physiological reference. VERIFY."
5. **A result that contradicts a source already in the ADR is a finding.** Specifically:
   if the pooled primaries fall outside 2.5-3x, `pooling.md` says the primaries win and
   Epstein's range is logged as a divergence, not averaged with them.
6. **Closing blocker 1 does not close ADR 0010.** Blockers 2 and 3 are independent. No
   `Anp` component is written under this pre-registration regardless of outcome.

---

## 8. WHAT WOULD FALSIFY THE APPROACH

**For Q2:** if the immersion natriuresis cannot be expressed as a function of a volume
change the model can compute — if it tracks only central redistribution, renal perfusion
or sympathetic withdrawal, none of which IPE has — then `V_blood` is the wrong sensed
variable and ADR 0010's Decision is wrong on its input side as well as its output side.
Rabelink 1989 already showed the *output* side is not ANP-proportional. If the input side
fails the same way, the honest response is that a cycle-averaged 3-state model cannot
carry this component, not to proceed with a proxy.

**For Q3:** if central and total blood volume turn out not to be mappable by a fixed
fraction — if the ratio depends on posture, venous tone or filling state, which is
physiologically likely — then a constant scaling is wrong and the mapping is itself a
relation needing a form citation, not a number. Record which it is.

**For the premise:** the reason ANP is being built first is that it should let `G_pn`
fall toward the Mizelle-consistent 5.43 while the 205 -> 103 mEq/day salt step survives
(ADR 0010 falsifiable test 2). If the gain sourced here is far too small to permit that,
the premise is wrong and the 3.68x gap needs a different explanation — which is blocker
3's territory, and must be recorded as a conflict rather than absorbed by tuning.
