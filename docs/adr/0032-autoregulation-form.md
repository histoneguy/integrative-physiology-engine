# ADR 0032: The autoregulation form is vindicated, and pressure natriuresis had lost its citation

**Status:** Accepted
**Date:** 2026-09-23
**Evidence tier:** **E2** for the piecewise autoregulation form (Kirchheim 1987, conscious
dog, servo-controlled graded renal artery pressure, n = 22). **No model equation changed.**

Pre-registered in `validation/autoreg_form_prereg.md`, **branch A3**. First pass run under
**directive 1.16**. `OPEN-QUESTIONS` B24 item 1.

## Context

`validation/form_sourcing_audit.md` ranked `Renal.GFR` first of the eleven relations with no
citation for their form: the piecewise autoregulation plateau that **every
pressure–natriuresis result in this model passes through**. Inside the range the `ifelse`
evaluates to exactly `1.0`, so GFR had **no direct pressure dependence at all** between the
breakpoints — a plateau that was perfectly flat *by construction* rather than emergent.

And `RN.AUTOREG.LOWER`'s note ended by naming the expected defect: *"the true plateau has a
slight slope the model's `ifelse` does not represent"*, citing Finke 1983's ~7% rise.

**So the pass was set up to ADD a residual slope.** §5 of the pre-registration fixed the
form — `(MAP/MAP_ref)^a_index`, one parameter, reducing to the current equation at zero —
before any value was sought.

## Evidence

**THE REVIEW FIRST, WHICH IS WHAT 1.16 REQUIRES.** Carlström M, Wilcox CS, Arendshorst WJ.
*Renal Autoregulation in Health and Disease.* Physiol Rev 2015;95(2):405–511. PMID 25834230.
Abstract read; **full text not retrievable**, and the publisher's bot check was **not worked
around** — recorded as an access item rather than bypassed.

It established **structure, not numbers**: autoregulation is a fast **myogenic** response
plus slower **MD-TGF**, both acting on the afferent arteriole; there is a **third**
mechanism, connecting-tubule glomerular feedback, that this model has never heard of; and
the mechanisms **modulate each other** rather than multiplying as independent factors.

**AND IT QUOTED THE RANGE AS "80–180 mmHg"** — the figure this repository had already traced
to Shipley & Study 1951, *anaesthetised dog*, carrying a legacy "Humans" MeSH tag that is an
indexing artefact. **A 2015 Physiological Reviews article repeating it unqualified is
directive 1.12 scoring again**, and it is the strongest available argument for 1.16's own
rule that reviews are read for structure and **never** for numbers.

**THE PRIMARIES.** Kirchheim HR, Ehmke H, Hackenthal E, Loewe W, Persson P. Pflugers Arch
1987;410(4–5):441–449. **PMID 3324052.** 22 conscious foxhounds, renal artery pressure
reduced in steps and held 5 minutes by a servo-controlled cuff.

| | |
|---|---|
| *"Between 160 and 81 mm Hg … concomitant autoregulation of GFR and RBF with a high precision"* | the plateau |
| *"In the subautoregulatory range GFR and RBF decreased in a linear fashion"* | the lower limb |
| GFR break-off point | **80.5 ± 3.5 mmHg** |
| RBF break-off point | **65.6 ± 1.3 mmHg**, different at **P < 0.01** |

Corroborated in the same preparation by Persson P, Ehmke H, Kirchheim H. Acta Physiol Scand
1988;134(1):1–7, **PMID 3239413**, n = 10 control: RBF 65.0 ± 1.4, GFR **81.5 ± 2.2**.

## Decision

**BRANCH A3. `a_index` = 0, AND NOT ONE LINE OF MODEL CODE CHANGED.** The sources refute the
need for the slope this pass was built to add: GFR is *"perfectly autoregulated"* across the
plateau and falls **linearly** below the break point, which **is** the equation already in
`Renal.jl`. The row gains a citation; the model gains nothing, which is the correct outcome
when the model was already right.

`Renal.GFR` leaves `GRANDFATHERED_UNSOURCED` — **8 exemptions to 6** counting ADR 0028's
cleanup below. The list shrinks only.

**THE NOTE THAT MOTIVATED THE PASS WAS ITSELF WRONG, AND IN AN INSTRUCTIVE WAY.** Finke's
~7% is **renal blood flow**, not GFR, and RBF autoregulates over a *wider* pressure range
than GFR because, as Kirchheim puts it, RBF autoregulation *"also involves postglomerular
vessels"*. **An RBF observation had been imported onto a GFR equation.**

## Consequences — AND THE PASS FOUND SOMETHING WORSE THAN IT WENT LOOKING FOR

**ADR 0028 MOVED PRESSURE NATRIURESIS OUT OF A SOURCED ROW INTO AN UNCITED ONE.**

| | before ADR 0028 | after |
|---|---|---|
| carries `G_pn*(MAP − MAP_ref)` and `vn_sig` | `Renal.FR_effective` | `Renal.f_dist_excr` |
| class | **empirical** | **definitional** |
| form citation | Roman & Cowley 1985 | **empty** |

`check_relations.py` has `NEEDS_CITATION = {"empirical"}`, so it never asked. **The model's
single most important empirical relation sat in a row that declared itself definitional and
cited nothing, and all six gates passed.** `FR_effective` meanwhile kept the Roman & Cowley
citation while its equation had become `Na_reabsorbed / Na_filtered` — **a pure ratio with no
pressure term in it** — so a source was attributed to an equation the code no longer
contained.

**Corrected:** `f_dist_excr` → `empirical`, `sourced-linear-composite`, carrying the citation
that follows `G_pn`; `FR_effective` → `definitional`. **What is NOT claimed** is that the
composite is wholly sourced — `renal_mod` is circadian, `fr_mod` is RAAS, and the segmental
balance is definitional. The status says exactly that.

**AND THE REASON NOTHING SAW IT: THE `expression` COLUMN IS DOCUMENTATION NO GATE CHECKS.**
`check_relations.py` matches on `relation_id` — `component.lhs` — and **never compares the
ledger's expression to the code**. Measured: **13 rows had genuinely drifted**, nine of them
corrected here, and **ADR 0028 alone accounted for three**. Four remain and are *not* drift —
they are the legitimate pattern where the ledger records the enabled physics and the code
carries a configuration toggle.

**THE DUPLICATE KEY (§3.73) AND THIS ARE THE SAME HOLE SEEN TWICE.** `by_id` is built as a
dict comprehension, so a repeated `relation_id` silently keeps the last row; and no column
except the key is validated against the source. **Whether to close it is `OPEN-QUESTIONS`
B27**, and it is **not** closed here, because the standing rule is not to add tooling unless
something breaks that cannot be worked around — and this was worked around, by hand, in one
evening.

**WHAT DID NOT CHANGE.** MAP 87.0, sodium 140.0, osmolality 287.0, urine 1.70 L/day,
`Na_excr` 205.0, glucose 5.44, insulin 64.2. **Suite 828/828, six gates exit 0, all
challenges pass.** No model equation was touched, so this is expected rather than
reassuring.

## What this disqualifies as evidence

**DIRECTIVE 1.16'S SECOND REQUIREMENT WAS NOT MET ON THE FIRST PASS RUN UNDER IT, AND THE ROW
SAYS SO.** Kirchheim 1987 and Persson 1988 have different first authors, different n and
different protocols — and they are **the same Heidelberg laboratory**, as are Finke 1983,
Just 1999 and Just 2001. `form_sourcing_audit.md` §4 and the pre-registration's §4 both fixed,
in advance, that papers from one group **count as one source**. A search across Europe PMC
found **no independent laboratory** measuring the whole-kidney GFR autoregulatory breakpoint
in a conscious preparation. **Branch A2's admission applies: one source, declared, not dressed
as consensus.**

**THE BREAKPOINT IS PROBABLY WRONG AND THIS PASS DELIBERATELY DID NOT FIX IT.**
`RN.AUTOREG.LOWER` = 63.9 is **Finke's renal blood flow limit used as a GFR limit**. Two
studies put the GFR limit at 80.5 ± 3.5 and 81.5 ± 2.2. The model's low-salt arm rests at MAP
**81.900**, so the ledger's claim that it *"now sits 18.0 mmHg above"* the kink would become
**0.4 mmHg** — a wholly different statement about margin. **`OPEN-QUESTIONS` B26**, and §6 of
the pre-registration forbade moving it in this pass, which is why it was not moved.

**Species.** Conscious dog throughout, recorded as such. Directive 1.6 and the
`autoreg_lower_prereg.md` finding that human graded-pressure GFR data exists only under
anaesthesia.
