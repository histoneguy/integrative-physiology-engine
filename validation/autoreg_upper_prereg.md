# Pre-registration: RN.AUTOREG.UPPER extraction

**Written BEFORE any literature was read, as required by `validation/pooling.md`
("Declare the pooling rule before extraction... A pooling rule chosen *after*
seeing the numbers is unfalsifiable").**

Date: 2026-08-20. Target: `RN.AUTOREG.UPPER`, the upper breakpoint of the GFR
autoregulation plateau in `src/components/Renal.jl`, currently 180 mmHg with
citation "Standard physiological reference. VERIFY." and `species = human`.

## Question

Is there PRIMARY literature, in HUMANS, that measures the renal arterial /
arterial pressure above which GFR ceases to be autoregulated?

## Declared decision procedure

Applied in strict order; the first branch that matches is taken. Fixed before
extraction and not revisited after seeing numbers.

1. A meta-analysis or pooled analysis of human studies reporting the upper
   breakpoint exists -> `pooling_rule = meta-analysis`, take its estimate and
   dispersion, record its k.
2. >= 2 independent HUMAN primary studies each reporting a numeric upper
   breakpoint, with n and dispersion -> `pooled-inverse-variance`.
3. Same, with n but no dispersion -> `pooled-n-weighted`.
4. Same, without n -> `pooled-unweighted`.
5. Exactly 1 human primary study -> `single-source`, k = 1, said plainly.
6. **Zero human primary studies reporting an upper breakpoint** -> the parameter
   is NOT human-sourced. `range-midpoint` is prohibited for new entries and
   cross-species pooling is prohibited, so 180 mmHg may not be retained by
   averaging animal numbers or by splitting a textbook range. In that case the
   value must be set to the largest pressure at which the model's own evidenced
   relations have support, `species` corrected, tier corrected, and the absence
   of human evidence recorded as the reason.

## Constraint fixed in advance

Whatever branch is taken, `RN.AUTOREG.UPPER` must not exceed the upper bound of
the range over which the model's pressure-natriuresis FORM is evidenced
(~160 mmHg; see `RN.PRESSURE_NATRIURESIS.SLOPE` notes and `Renal.FR_effective`
in `ledger/relations.csv`). A breakpoint outside that range is a breakpoint in a
region where the equation it modifies has no support. If branch 1-5 returns a
human value above 160 mmHg, the value is recorded with its citation but the
model's operating range limitation is recorded alongside it, and the conflict is
escalated rather than silently resolved.

## Out of scope

`RN.PRESSURE_NATRIURESIS.SLOPE` is not to be changed (explicit instruction).
`RN.AUTOREG.LOWER` is a separate row with the same defect and is not fixed here.

---

# OUTCOME (written after extraction, 2026-08-21)

**Branch 6 was taken.** Zero human primary studies report an upper breakpoint of GFR
autoregulation.

## What the search found

Searched PubMed via E-utilities and the general literature. The human renal
autoregulation literature exists, but every study in it **lowers** arterial pressure
and asks whether GFR is preserved — Parving 1984 (clonidine, PMID 6442240), New 1998
(trandolapril, PMID 9498655), Christensen 2001 (PMID 11576357), Christensen 2003
(PMID 12502673). None approaches 160 mmHg, let alone 180. No human study raises
pressure to find where autoregulation fails, which is unsurprising.

The textbook "80–180 mmHg" traces to **Shipley RE, Study RS, Am J Physiol
1951;167:676-688 (PMID 14903093)** — **dog**. (Its PubMed record carries the MeSH term
"Humans"; that is a legacy-indexing artefact of the AJP back-catalogue, contradicted by
the paper and by every source that cites it as the canine range. Noted because the tag
would otherwise look like human support.) So 180 entered this ledger as a dog number
wearing a human label.

Two reviews were read and **not pooled**: Cupples & Braam 2007
(doi 10.1152/ajprenal.00194.2006) put the plateau at ~75 mmHg (dog) or ~85 mmHg (rat)
to **">160 mmHg"** — an open upper bound, not a fixed 180; and Carlström, Wilcox &
Arendshorst 2015 (doi 10.1152/physrev.00042.2012) repeat the conventional 80–180.
Neither adds human primary data on the upper limit.

## What was done

`RN.AUTOREG.UPPER`: **180 → 160 mmHg**, `species` human → **rat**, `source_tier`
B → **A**, cited to **Roman RJ, Cowley AW Jr, Am J Physiol 1985;248:F190-F198,
PMID 3970209** — which reports RPP raised 90 → 160 mmHg with "no detectable changes in
glomerular filtration rate, renal blood flow, or peritubular capillary pressure".
`pooling_rule = single-source`, `k = 1`.

The tier **rose** because the source became a primary measurement instead of an unnamed
reference; the species flag **fell** to rat. Those are two independent axes and both
moved honestly. No cross-species pooling was performed: the dog (Shipley) and rat
(Roman) numbers are not averaged.

This is a **censored observation**. 160 mmHg is the highest pressure tested, so the true
breakpoint is ≥ 160 and is not known to *be* 160. The model takes the edge of evidence,
which errs in the conservative direction — GFR is made to fall slightly earlier than
reality rather than asserting a plateau where nothing has been measured.

The ≤160 ceiling was fixed in the pre-registration above **before** extraction, so the
fact that Roman & Cowley 1985 turns out to source both the breakpoint and the
pressure-natriuresis form — terminating both at the same pressure — is a consequence of
the constraint, not a number chosen to fit.

## What was deliberately NOT done

- `RN.PRESSURE_NATRIURESIS.SLOPE` unchanged, as instructed.
- `RN.AUTOREG.LOWER` value unchanged at 80.0. Its note was corrected (it asserted the
  now-retracted 180) and its debt recorded. Roman & Cowley only descended to 90 mmHg so
  they cannot source it, and a 2025 review (doi 10.22514/sv.2025.001) holds that human
  evidence is insufficient for 80 mmHg as the lower limit. Fixing it needs its own
  pre-registered extraction.
- The piecewise **form** of the autoregulation equation remains unsourced.
  `ledger/relations.csv` row `Renal.GFR` keeps an empty `form_citation` and stays in
  `GRANDFATHERED_UNSOURCED`. A number was sourced; the equation was not.
- `pooling_rule` / `n_studies` / `pooling_notes` are still not columns of
  `parameters.csv` despite `pooling.md` specifying them. Recorded in prose, following
  the precedent set by `RN.PRESSURE_NATRIURESIS.SLOPE`. Schema debt, logged not fixed.
