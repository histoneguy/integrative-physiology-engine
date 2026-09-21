# Pre-registration — the segments must carry the FLUX, not just the signal

**Written 2026-09-21, before any equation is changed.** Verify with

    git log --diff-filter=A -- validation/segmental_flux_prereg.md

---

## 0. THE DEFECT, AND IT IS THE SAME ONE ADR 0025 WAS BUILT TO FIX, ONE LEVEL DOWN

`tubule_segments_prereg.md` diagnosed four failed renal passes with one sentence: **the
tubule is a single lumped reabsorption term and every primary renal source is segmental.**
Its proof was `Na_prox_out` — *"a sourced, correct, salt-responsive quantity that does no
work."*

**ADR 0025 gave the segments to the SIGNAL and not to the FLUX.** Sodium excretion is still

    FR_effective ~ 1 - (1 - FR_Na)*renal_mod + fr_mod - G_pn*(MAP - MAP_ref)/Na_filtered
                     - vn_sig/Na_filtered
    Na_excr      ~ Na_filtered - FR_effective*Na_filtered

**a WHOLE-NEPHRON fraction.** `Na_distal` is computed and **read by nothing** — one test
asserts its value and the GUI exports it. The comment above it says so in terms: *"THE
SODIUM EQUATION ABOVE IS UNTOUCHED AND THAT IS THE POINT."* That was the right call for a
pass that was only moving the renin signal. **It is now the same defect, recurred.**

---

## 1. THE SOURCE, AND IT IS HUMAN

**Alexander EA, Doner DW Jr, Auld RB, Levinsky NG.** *Tubular reabsorption of sodium during
acute and chronic volume expansion in man.* J Clin Invest 1972;51(9):2370-2379. **PMID
4639021, PMC292404. ABSTRACT READ IN FULL, 2026-09-21. THE FULL TEXT IS SCANNED PAGE IMAGES
ON BOTH PMC AND jci.org AND COULD NOT BE TRANSCRIBED**, so subject counts, dispersions and
the infusion protocol are NOT KNOWN TO THIS PASS. Adult and middle-aged men; proximal index
`(1 - V/GFR)x100`, distal index `(C_H2O/V)x100`.

| manoeuvre | proximal FSR | distal FSR |
|---|---|---|
| acute isotonic saline, 37 mL/kg | **-4.8%** | **-4.4%** |
| comparable chronic expansion (mineralocorticoid escape) | **-3.9%** | **NOT ALTERED** |
| graded, excreters, to 57 mL/kg | -7.1% | -14.8% |
| ...further to 80 mL/kg | -0.9% | -4.9% |
| graded, nonexcreters, to 57 mL/kg | not significant | -4.5% |

**HIS CONCLUSION, VERBATIM:** *"both acute and chronic extracellular expansion decrease
proximal FSR in man, but only acute loading depresses distal FSR."*

**THIS IS THE ACUTE/CHRONIC ASYMMETRY THE MODEL HAS NEVER HAD, AND IT IS SEGMENTAL.** A
lumped fractional reabsorption cannot hold it: there is only one fraction and it cannot be
unaltered and depressed at the same time.

**`oncotic_proximal_prereg.md` IS VOIDED AND UNEXECUTED**, and named Alexander as one of
three things in it that survive. This pass takes that and nothing else from it. **Its §3.4
collinearity finding is respected rather than worked around** — see §3.

---

## 2. WHAT IS BUILT, AND PHASE 1 HAS NO NEW PARAMETER AT ALL

**PHASE 1 — STRUCTURAL ONLY.** Excretion flows through the segments:

    Na_excr ~ Na_distal*(1 - f_dist) + G_pn*(MAP - MAP_ref) + vn_sig

with `f_dist` carrying the circadian rhythm and the aldosterone increment, which is
**where those act** — the distal nephron and the collecting duct, not a whole-nephron
average.

**`f_dist`'s reference is DERIVED FROM TWO ROWS ALREADY IN THE LEDGER** and computed in the
component, so nothing is stored and no digit is claimed:

    f_dist_ref = 1 - (1 - FR_Na)/f_md

**THE ABSOLUTE REGULATOR FLUXES ARE UNCHANGED**, so the chronic behaviour is not being
re-tuned: `G_pn` and `vn_sig` enter in mEq/day exactly as they do now.

**WHAT CHANGES IS THAT BASELINE EXCRETION NOW SCALES WITH DELIVERY.** `Na_distal` carries
`f_prox_eff`, which Folkerd 1995 made salt-responsive. In the lumped form a rise in
proximal delivery reached excretion through **nothing**. That is the whole of Phase 1, and
**it introduces no free parameter, so it cannot be a disguised refit.**

**PHASE 2 — ONLY IF PHASE 1 IS INSUFFICIENT, AND ONLY WITH ALEXANDER'S NUMBER.** A distal
fractional depression that is **acute-only**, magnitude `-4.4%` at his 37 mL/kg load,
keyed to the model's existing acute volume signal. **No new sensor. No second volume
receptor.**

---

## 3. THE DOUBLE COUNT THIS PASS MUST NOT COMMIT, NAMED BEFORE BUILDING

`cardiopulmonary_sympathetic_prereg.md` §1 forbids a **third natriuretic term** keyed to
central volume, because `V_central` = `f_c`x`V_blood` and ADR 0010's arm already senses it.
HANDOVER §3.57 then measured the consequence: the volume-keyed arm carries **77% of the
chronic swing**, it is keyed to `V_blood` because *"atrial stretch is intravascular"*, and
Lohmeier's Den/Inn ratio says **roughly half of such a response is nerve traffic** — so
**the path labelled volume-natriuresis already contains an unlabelled sympathetic
component.**

**THEREFORE THE ACUTE RENAL SYMPATHETIC NATRIURETIC ARM IS ALREADY IN THIS MODEL AND MAY
NOT BE BUILT AGAIN.** `OPEN-QUESTIONS` B15 recommended exactly that on 2026-09-20 and **B15
was wrong**; this pre-registration records that before building anything, and B15 is
corrected rather than quietly dropped.

**Phase 1 is safe from this by construction because it adds no gain.** Phase 2's term is a
**fractional depression of a segment**, not an absolute flux keyed to a volume receptor, and
it is **acute-only where `G_vn`'s chronic component is what sets salt sensitivity**. If
Phase 2 cannot be made to satisfy §5 test 3 without moving `G_vn`, **it is not built.**

---

## 4. WHAT MAY NOT MOVE

- **`CV.VOLUME.NATRIURETIC_GAIN`** — the most influential parameter in the model, 45% of
  the salt-sensitivity sensitivity. Untouchable in a pass that touches its path.
- **`RN.PRESSURE_NATRIURESIS.SLOPE` (`G_pn`), `RN.NA.FRACTIONAL_REABSORPTION` (stays
  DERIVED to close balance), `RN.NA.MACULA_DENSA_FRACTION`, `f_prox`, `k_prox`, `f_tal`,
  `md_conc_ref`, `Km`, `tau_tal`, `e_tgf`, `k_md`, `md_c_thr`.**
- **`RN.VOLUME_NATRIURESIS.TAU`** — fixed by Lobo's 6 h time course. If the restructure
  moves Lobo, **report it; do not re-solve the lag.**
- **JENSEN 2013 MAY NOT ENTER ANY ESTIMATION IN ANY FORM.** It is read out, never in.
- **No band, pin or tolerance widened.**

---

## 5. THE FALSIFIABLE TESTS

1. **The operating point is unchanged** — MAP, `Na_excr`, urine volume, plasma sodium, GFR.
   Phase 1 is an identity at rest by construction; anything else is a wiring error.
2. **`md_conc` still salt-independent** at 38/205/230 mEq/day — Vallon, ADR 0025.
3. **Chronic salt sensitivity stays inside 1.70-2.30.**
4. **Jensen's acute FE_Na rise against 60-250**, reported whichever way, for Phase 1 alone
   and again for Phase 2 if it is built.
5. **Both Lobo endpoints and the acute ordering ratio**, reported.
6. **The chronic renin ratio**, reported; it is a failed test since ADR 0027 and stays one.
7. **Whether `Na_distal` is now read by the excretion path** — the defect this pass exists
   to remove, asserted rather than assumed.

---

## 6. THE DECISION RULE

- **F1 — Phase 1 alone brings Jensen inside 60-250 with the operating point and the chronic
  endpoints intact.** Adopt, and Phase 2 is **not built**. A structural correction with no
  free parameter is the strongest possible outcome and it must not be decorated.
- **F2 — Phase 1 moves Jensen in the right direction but not inside.** Build Phase 2 with
  Alexander's -4.4% and report both numbers separately, so the structural and the sourced
  contributions are never conflated.
- **F3 — Phase 1 moves Jensen the WRONG way.** Report it. The delivery-scaling argument in
  §2 would then be wrong, which is worth more than the endpoint.
- **F4 — the operating point moves.** Wiring error; fix it, do not absorb it.
- **F5 — chronic salt sensitivity leaves its band.** Report and **revert**. The chronic
  limbs are correct today and a pass aimed at an acute endpoint may not spend them.

---

## 7. WHAT WOULD MAKE THIS PASS A FAILURE

**Adding a gain in Phase 1.** It is a restructure. If it needs a number to work, it is not
the restructure it claims to be.

**Re-solving `G_vn` or `G_pn` "because the structure changed".** Both are licensed by their
own estimation sets and by nothing that happens here.

**Reporting F1 when the truth is F2.** Test 4 requires Phase 1's Jensen number to be
reported on its own, before Phase 2 exists, precisely so that it cannot be absorbed.

**Letting Alexander's 4.4% become adjustable.** It is his, from an abstract, at a stated
load, and the row must say all three.
