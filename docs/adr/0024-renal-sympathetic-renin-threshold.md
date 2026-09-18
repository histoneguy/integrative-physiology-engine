# ADR 0024: The renal sympathetic arm moves the renin threshold, and it does not reset

**Status:** Accepted
**Date:** 2026-09-18
**Evidence tier:** E2 for the threshold shift and its β-adrenergic mechanism; **E2** for
non-resetting of the renal sympathetic arm; **E3** for the interpolation between
Kirchheim's two points and for keying the efferent to arterial rather than cardiopulmonary
pressure — both default ON and both stated below with what would refute them.

> Split mixed claims. The claims here have different evidence behind them and are tiered
> separately on purpose.

Pre-registered in `validation/renal_sympathetic_prereg.md` with two amendments written
**before** anything was built, both recording that the pre-registration had guessed wrong.

## Context

HANDOVER §4 item 1 names the control layer as the honest next target: *"renin is
pressure-only when §7 already records that no gain reproduces the human salt-renin response
because macula densa delivery and renal sympathetic traffic are absent."* Macula densa
landed in ADR 0021. **Renal sympathetic traffic is the one that was left**, and it had been
deferred for want of a source until directive 1.15 made Lohmeier's conscious-dog work the
standing default for exactly this gap.

**ADR 0021 A6.3 left a falsifiable prediction waiting:** *"Building renal sympathetic
traffic must LOWER `RN.MD.RENIN_GAIN` … If it does not, the acute overshoot is something
else — the missing candidate being tubuloglomerular feedback on the afferent arteriole."*
Half of that prediction was already dead — §3.54 widened Lobo's bands and HANDOVER records
that inside them they bound nothing — and this record does not pretend otherwise.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| Renal sympathetic activation shifts the renin pressure threshold right by 17 mmHg, leaving plateau and slope unchanged | **E2** | Kirchheim 1985, PMID 3903653, n = 7, renal artery cuff with pressure control | dog, conscious |
| The pathway is direct β-adrenergic on juxtaglomerular cells, with no vasomotor component | **E2** | Gross 1981, PMID 7024507, denervated kidney n = 3 and β-blockade n = 4 controls | dog, conscious |
| The pressure–renin relation is rectified: a plateau above a distinct threshold, a steep limb below | **E2** | Kirchheim 1985 (92.7 ± 2.8 mmHg) **and** van Ochten 2025 meta-analysis (93 ± 2) | dog; mixed animal |
| Renal sympathetic outflow is **not** completely reset at 5–10 days of sustained pressure elevation | **E2** | Lohmeier 2001 PMID 11448845 (day 10, Den/Inn 0.56 ± 0.05); Lohmeier 2000 PMID 11004014 (day 5, 0.51 ± 0.05) | dog, conscious |
| The chronic afferent for renal sympathoinhibition is cardiopulmonary, not arterial | **E2** | Lohmeier 2000: cardiopulmonary denervation **alone** abolished the response | dog, conscious |
| The efferent is keyed to **arterial** pressure in this model | **E3** | none — see Consequences | — |
| `rsna` interpolates between Kirchheim's two points with the vasomotor `tanh` and `BR.OPEN_LOOP_GAIN` | **E3** | none — Kirchheim measured two points, no submaximal curve | — |

**All four primary sources are ABSTRACT ONLY.** Both AJP-Regu papers are paywalled and
`elink pubmed_pmc` returns only citing articles; Pflügers Archiv 1985 has no PMC record;
Gross 1981 is free to read at PMC1274447 but the publisher blocks XML retrieval and the
page is behind a CAPTCHA. The abstracts carry the numbers **with dispersion**, which is
why these rows are possible at all, and every row says so. Directive 1.5: the MEDLINE
abstracts were opened; the full texts were not.

## Decision

**1. The renin pressure threshold becomes dynamic.** `P_thr_eff ~ P_thr + dP_sym * rsna`,
with `RAAS.RENIN.SYMPATHETIC_THRESHOLD_SHIFT = 17 mmHg`. The **rectified form and the slope
are untouched** and van Ochten still owns both — what moves is where the rectification
turns on.

**2. A sympathetic renin GAIN is explicitly rejected.** Kirchheim's plateau (0.98 → 0.99)
and slope (−0.379 → −0.416) are both unchanged; only the threshold moves. The
pre-registration assumed a gain and amendment 1 withdrew it. **Adding a gain would have
contradicted the only source that measured the effect.**

**3. The renal sympathetic arm does not reset.** `rsna` takes its error against the fixed
`MAP_ref`, **not** against `Baroreflex.jl`'s resetting setpoint `sp`. This is a claim about
the renal arm alone.

**4. `BR.RESET.TAU` is not touched.** It is `assumed` at 1 day, it governs the **vasomotor**
arm, and re-valuing it on renal-nerve data would be failure mode #11.

**5. No sodium-excretion sympathetic arm is built.** See Consequences.

**6. `dP_sym = 0` recovers the previous model exactly** — the precedent `g_md` was
introduced on. No new structural variant, no new state, no new compilation configuration.

## Consequences

**ADR 0021 A6.3 IS CONFIRMED, AND THE INSTRUMENT READ TRUE ON ITS CONTROL ARM.**

| | `g_md` that reproduces van den Bosch's 2.73 |
|---|---|
| arm OFF | **5.713** — reproduces the 5.71 that stood |
| arm ON | **4.99** |

`RN.MD.RENIN_GAIN` was re-solved 5.71 → 4.99 **after** the measurement was taken. Had the
gain not fallen, A6.3 named tubuloglomerular feedback as the successor and that branch was
live until this ran.

**THE SODIUM ARM WAS NOT BUILT, AND THE REASON IS A FINDING.** The pre-registration's
branch S2 applies. Measured before anything was written: at the chronic salt step the
volume-keyed `anp_sig` term carries **77% of the 192 mEq/day excretion swing**, it is keyed
to `V_blood` because *"atrial stretch is intravascular"* — **and cardiopulmonary receptors
are atrial stretch receptors.** Lohmeier's Den/Inn ratio of ~1.9 says roughly half of such
a response is nerve traffic. **The path labelled ANP already carries an unlabelled
sympathetic component**, and a third gain on the same afferent would be failure mode #22.
**That is a criticism of `CV.ANP.NATRIURETIC_GAIN`'s label, and it is left on the record
rather than fixed here**, because re-estimating it in the pass that found the problem would
be changing a target and refitting to it in one step.

**WHAT DECISION 3 COSTS.** The model now has **one resetting constant where the physiology
has at least two**, and the one it has is `assumed`. `Baroreflex.jl` already cites Dutoit
2010 for cardiac and sympathetic arms being independent within individuals, so differential
resetting is the ordinary case rather than a special plea — but this record is making the
claim on renal-nerve data and applying it only to the renal arm.

**AND DECISION 3 IS WHY THE ARM COULD NOT HAVE BEEN BUILT NAIVELY.** Wiring `P_thr` to the
sympathetic drive the model already had would have produced **an arm that does nothing
chronically**, because that drive is zero in every chronic steady state. A6.3 would have
come back **refuted, with a plausible successor mechanism attached**, when the instrument
was reading the resetting assumption. That failure would have been invisible in the result.

**THE E3 CLAIMS, AND WHAT WOULD REFUTE THEM.** Both default ON, per ADR 0006's requirement
that an E3 claim on by default states its falsifier:

- *Arterial rather than cardiopulmonary afferent.* Lohmeier's CPD result says the **chronic**
  afferent is the low-pressure volume receptors; Kirchheim's **carotid** manipulation is what
  calibrates the efferent. Both converge on renal sympathetic outflow and this model keys to
  MAP because that is what the 17 mmHg was measured against. **Refuted by** any protocol
  that dissociates volume from pressure — a volume expansion at constant MAP should then
  produce renin suppression this model will miss.
- *The `tanh` interpolation.* Kirchheim measured control and occlusion and nothing between.
  **Refuted by** any submaximal renal sympathetic stimulus–threshold curve.

**WHAT THIS FORECLOSES.** Nothing structurally, but it **narrows what `RN.MD.RENIN_GAIN`
can still be blamed for.** Sympathetic effects on tubular sodium reabsorption and on
afferent arteriolar tone remain absent, and tubuloglomerular feedback is still not built,
so that gain still absorbs those. **The count of `calibrated` rows in the ledger is
unchanged at two.**

## What this lumping disqualifies as evidence

**van den Bosch's salt–renin ratio remains an ESTIMATION SET and must never be reported as
agreement.** ADR 0021 said this and re-solving `g_md` against the same target does not
change it. What is a TEST is the **form** — that the arm lowers the required gain at all,
predicted in A6.3 before the arm existed.

**Kirchheim's 92.7 ± 2.8 may not be used to re-value `RAAS.RENIN.PRESSURE_THRESHOLD`.** It
independently confirms van Ochten's 93 ± 2 from a different species by a different method,
and that agreement is worth having **precisely because nobody arranged it**. Adopting it as
the value would spend a free confirmation to gain nothing.

**The Schweda 2006 threshold conflict stays open.** Kirchheim supplies a *mechanism* for why
an isolated preparation lacking neural input might show a displaced threshold. A mechanism
for a conflict is not a resolution of one, and `Raas.jl`'s note keeps recording it.
