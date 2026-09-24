# Retrospective audit — what the FORMS of the equations rest on

**Run 2026-09-23, at the owner's instruction, immediately after directive 1.16 was set.**
Mechanical, from `ledger/relations.csv` and `ledger/parameters.csv`; regenerate with the
classifier described in §5 rather than by editing the table below.

**THE QUESTION THIS ASKS IS NARROW AND DELIBERATELY SO.** Not "is the number right" —
`pooling.md` and directive 1.13 already govern that, and the parameter side is in
reasonable order. The question is **directive 1.16's second half: how many primary
sources stand behind the FUNCTIONAL FORM of each equation.**

---

## 1. THE HEADLINE, AND IT IS WORSE THAN THE PARAMETER SIDE

| | |
|---|---|
| empirical relations | **32** |
| form rests on **no** citation at all | **11** |
| form rests on **exactly one** primary | **19** |
| form has a **systematic review** behind it | **2** |
| form has **more than one primary** | **0** |

**NOT ONE EQUATION IN THIS MODEL HAS TWO PRIMARY SOURCES BEHIND ITS FORM.** Thirty of
thirty-two rest on one paper or on none. The two exceptions are reviews —
`BodyFluids.thirst` (Hughes 2018) and `Raas.renin_drive` (van Ochten 2025) — and **both
arrived in the last four days**, the first because the owner ordered a repool and the
second because the renal baroreflex had no usable human data at all.

**THE PARAMETER SIDE IS IN BETTER SHAPE, AND THAT CONTRAST IS THE FINDING.** Of 58
`reported` rows, **34 are pooled, meta-analytic or NHANES** and 24 are single-source.

**AND THE POLICY THAT MADE THAT HAPPEN HAS EXISTED SINCE 2026-08-21.** `validation/pooling.md`
opens *"Binding. Fix before extracting any parameter from more than one source"* and was
written from an owner instruction five weeks before this audit. **It governs VALUES.**
Where this repository has been disciplined, it has been disciplined about numbers.

**NOBODY EVER EXTENDED IT TO FORMS, AND THE COUNT ABOVE IS WHAT FIVE WEEKS OF THAT LOOKS
LIKE.** Directive 1.8 said cast a wide net and was read as a rule about *searching*;
`pooling.md` said combine what you find and was read as a rule about *numbers*. **The
equations fell between the two.** Directive 1.16 closes the gap; this file is the baseline
it is measured from.

---

## 2. THE TABLE

**"NONE" covers two different failures** and they are listed apart. Seven relations have
an **empty** `form_citation`; four carry **prose** in the field — an explanation of why a
first-order lag was chosen, which is honest and is still not a source.

| Relation | Primaries behind the FORM | Declared status | Source |
|---|---|---|---|
| `Baroreflex.D(sp)` | **NONE** | `unsourced` | (field empty) |
| `Baroreflex.D(tpr_mod)` | **NONE** | `unsourced` | (field empty) |
| `BodyFluids.J_osm` | **NONE** | `unsourced` | (field empty) |
| `BodyFluids.J_store` | **NONE** | `unsourced` | (field empty) |
| `BodyFluids.Osm_ecf` | **NONE** | `unsourced` | (field empty) |
| `Circadian.renal_mod` | **NONE** | `unsourced` | (field empty) |
| `Renal.GFR` | **NONE** | `unsourced` | (field empty) |
| `Baroreflex.D(hr_mod)` | **NONE** | `sourced-lag-unsourced-order` | (prose, not a citation) |
| `Cardiovascular.D(V_rbc)` | **NONE** | `assumed` | (prose, not a citation) |
| `Cardiovascular.o2_deficit` | **NONE** | `assumed` | (prose, not a citation) |
| `Renal.D(vn_sig)` | **NONE** | `sourced-lagged-linear` | (prose, not a citation) |
| `Adh.adh` | one | `sourced-linear-saturating` | Robertson 1987 |
| `Baroreflex.drive` | one | `divergent` | Kent 1972 |
| `Baroreflex.hr_drive` | one | `divergent` | Kent 1972 |
| `Blood.SaO2` | one | `sourced-published-fit` | Severinghaus 1979 |
| `Cardiovascular.SV` | one | `sourced-linear` | Guyton 1957 |
| `Raas.D(esc)` | one | `sourced-first-order` | Kelly 1987 |
| `Raas.P_thr_eff` | one | `sourced-threshold-shift` | Kirchheim 1985 |
| `Raas.aldo` | one | `sourced-power-law` | Walker 1976 |
| `Raas.fr_angii` | one | `sourced-two-points-assumed-saturating` | Hall 1984 |
| `Raas.rsna` | one | `sourced-phenomenon-assumed-shape` | Kirchheim 1985 |
| `Renal.FR_effective` | one | `sourced-linear` | Roman 1985 |
| `Renal.I_glu` | one | `saturating-two-point` | Merovci 2021 |
| `Renal.f_prox_eff` | one | `sourced-two-points-assumed-linear-in-pra` | Folkerd 1995 |
| `Renal.gfr_tgf` | one | `local-slope-sourced` | Briggs 1984 |
| `Renal.gfr_vol_mod` | one | `sourced-linear-censored` | van den Bosch JJJON, Hesse |
| `Renal.glu_excr` | one | `threshold-sourced` | Mogensen 1971 |
| `Respiratory.V_E` | one | `sourced-piecewise-threshold` | Guluzade 2022 |
| `Thyroid.TSH` | one | `sourced-log-linear` | Benhadi 2010 |
| `Thyroid.th_mod` | one | `sourced-linear-fractional` | Maushart 2022 |
| `BodyFluids.thirst` | **review** | `threshold-pooled-gain-derived` | Hughes 2018 |
| `Raas.renin_drive` | **review** | `sourced-rectified-linear` | van Ochten M, El Fathi W,  |

---

## 3. WHAT THE ELEVEN UNSOURCED FORMS ACTUALLY ARE

**Most are defensible and one is load-bearing.** A flat "11 unsourced" would be exactly
the scary-sounding count directive 1.14 exists to stop, so they are ranked here by hand.

- **`Renal.GFR` IS THE LOAD-BEARING ONE.** Pressure autoregulation of the glomerular
  filtration rate is the piecewise plateau that every pressure–natriuresis result in this
  model passes through, and **its form has no citation.** Both breakpoints are sourced
  rows (`RN.AUTOREG.LOWER`, `RN.AUTOREG.UPPER`); the shape between them is not.
  **First item on the 1.16 backlog.**
- **`BodyFluids.Osm_ecf`, `BodyFluids.J_osm`** — osmotic equilibration. `Osm_ecf` is close
  to definitional and may simply be misclassified as empirical; `J_osm` relaxes to osmotic
  equilibrium on a time constant that does not matter at this horizon.
- **`Baroreflex.D(sp)`, `D(tpr_mod)`, `D(hr_mod)`, `Renal.D(vn_sig)`,
  `Cardiovascular.D(V_rbc)`** — first-order lags. The **time constants are sourced rows**;
  what is unsourced is the claim that the response is first-order at all. ADR 0022 already
  records that a lag here does structural work as well as representing a delay, so the
  order of the lag is not a cosmetic choice.
- **`BodyFluids.J_store`, `Circadian.renal_mod`** — both **default OFF** (ADR 0004, and
  the clock's two contested arms). An unsourced form on a disabled path is the cheapest
  debt in the file.
- **`Cardiovascular.o2_deficit`** — declares itself phenomenological in ADR 0023.

---

## 4. WHAT THIS AUDIT DOES NOT SHOW

**It cannot see whether the single source was the RIGHT one**, only that there is one.
`Renal.I_glu` rests on Merovci 2021, a good paper read in full — and the insulin split
still could not express type 1 diabetes, because the defect was in **which physiology was
represented**, not in which paper the dose–response came from. **Directive 1.16's first
half — read a review to learn the basics — is the half this audit cannot measure**, and
it is the half that failed.

**It does not rank by consequence.** `Renal.GFR` and a disabled circadian arm score
identically here. §3 ranks by hand; nothing mechanical does.

**A second primary that agrees is not automatically worth having.** 1.16 asks for multiple
sources so a *form* is constrained by more than one laboratory's protocol. Two papers from
one group, or one that reuses the other's published equation, are one source wearing two
names — the trap `pooling.md` already names for numbers. **`Baroreflex.drive` and
`Baroreflex.hr_drive` both cite Kent 1972 and are counted as two single-source rows, not
as a pool.**

---

## 5. REGENERATING THIS

Produced from the ledger; **do not hand-edit the table.** The classifier is a regex over
`form_citation` — empty, or prose beginning `FIRST-ORDER`/`Phenomenological`/`First-order
production`, or matching `systematic review|meta-analysis`, else one primary.

**The classifier is a heuristic and both `review` hits were checked by hand:** Hughes 2018
and van Ochten 2025 are genuine systematic reviews, not regex accidents. A future review
whose title says neither phrase would be missed, which is the known failure direction —
**it under-counts reviews and never invents one.**

**No gate enforces any of this.** Whether one should is `OPEN-QUESTIONS` B25.
