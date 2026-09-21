# Pre-registration — splitting the tubule into flux-carrying segments

**Written 2026-09-20, before any equation is written.** Verify with

    git log --diff-filter=A -- validation/tubule_segments_prereg.md

At the owner's instruction, after four passes failed for one shared reason.

---

## 0. WHY, AND THE REASON IS THE SAME EVERY TIME

Four renal passes found the right primary source and could not use it:

| pass | source | why it did not land |
|---|---|---|
| `fr_angii` | Hall 1984 | needed an AngII dose-to-concentration anchor |
| saturating form | Hall 1977 | shape irrelevant; term too small a share |
| macula densa | Lorenz 1990 | needs macula densa **concentration**; model has delivery |
| proximal | Folkerd 1995 | landed and **changed nothing** — `Na_prox_out` is read by nothing |

**One cause: the tubule is a single lumped reabsorption term** and every primary renal
source is segmental. `Na_prox_out` is the proof — a sourced, correct, salt-responsive
quantity that does no work.

---

## 1. WHAT IS BUILT

    H2O_prox_out ~ GFR * f_prox_eff                 lithium measures FLUID delivery
    Na_md        ~ Na_prox_out * (1 - f_tal)        TAL reabsorbs a fraction of DELIVERY
    H2O_md       ~ H2O_prox_out                     TAL is water-impermeable
    md_conc      ~ Na_md / H2O_md                   THE LORENZ VARIABLE
    md_drive     ~ (md_conc_ref - md_conc) / md_conc_ref

**THE KEY CHANGE IS `f_tal`, NOT THE NEW VARIABLES.** `f_md` was a fixed fraction of the
**filtered** load; `f_tal` is a fraction of what the segment **receives**. That is what lets
delivery and concentration come apart, which is the whole point.

### 1.1 The two constants are DERIVED from rows already sourced

    f_tal       = 1 - (1 - f_md)/f_prox = 1 - 0.10/0.26 = 0.615
    md_conc_ref = C_Na * (1 - f_tal)    = 140 * 0.3846  = 53.8 mM

**AND 53.8 mM IS A FREE CONSISTENCY CHECK.** Lorenz 1990 states the full renin response
occurs *"below 80 mM Na+"*, which is *"the concentration range normally occurring at the
macula densa."* **53.8 is inside that bound** — three independent sources (Shirley 2002,
the macula densa fraction, Lorenz) agreeing with nothing arranged.

### 1.2 f_tal LUMPS TWO THINGS AND THE ROW MUST SAY SO

Only the combination of **TAL sodium reabsorption** and **descending-limb water
reabsorption** is identifiable here: they enter `md_conc` as a ratio and no measurement in
hand separates them.

---

## 2. THE PREDICTION, AND IT IS SEVERE — DECLARED BEFORE RUNNING

Substituting:

    md_conc = (Na_filtered * f_prox_eff * (1 - f_tal)) / (GFR * f_prox_eff)
            = C_Na * (1 - f_tal)

**`f_prox_eff` CANCELS.** Macula densa concentration depends on **plasma sodium alone** and
is therefore **salt-independent** — which is exactly Vallon 2002 (PMID 12089382), now
emergent rather than assumed.

**SO `md_drive` GOES TO NEARLY ZERO AT EVERY SALT INTAKE, AND THE MACULA DENSA RENIN ARM
STOPS CARRYING THE SALT RESPONSE.** §3.65 measured that arm supplying **1.41 of the 1.58
gap**. **I therefore expect the chronic renin ratio to fall from 2.733 toward the
pressure-plus-sympathetic floor of about 1.323, and van den Bosch to be FAILED.**

**THAT IS THE POINT, NOT AN ACCIDENT.** Vallon says this arm should not carry dietary salt.
A model that reproduces van den Bosch through it is right for the wrong reason, and the
honest outcome of making the structure correct is losing an agreement that was never
earned.

**`test/runtests.jl` pins that ratio at 5.74/2.10** and calls it *"ARITHMETIC, not
agreement"* — a check that the calibration still holds. **When the arm stops carrying the
response, that pin is testing a calibration that no longer exists**, and it must be
rewritten to say so rather than loosened.

---

## 3. WHAT MAY NOT MOVE

- **The operating point.** Resting MAP, `Na_excr`, urine volume, plasma sodium. `md_conc`
  equals `md_conc_ref` at rest by construction, so `md_drive` is zero there exactly.
- **`RN.MD.RENIN_GAIN` may NOT be re-solved to recover the ratio.** That is the whole
  temptation and it is forbidden. Losing the ratio is the result.
- **The sympathetic arm, the volume gain, `G_pn`, `f_prox_eff`, `k_prox`** — none of them.
- **No band or tolerance may be widened** to accommodate the loss.

---

## 4. THE DECISION RULE

- **T1 — `md_conc` is salt-independent, the operating point holds, the renin ratio falls.**
  Adopt, and report the failure plainly. **Expected.**
- **T2 — `md_conc` varies with salt.** The algebra above says it cannot; if it does the
  wiring is wrong. Fix it.
- **T3 — the operating point moves.** Same.
- **T4 — the renin ratio does NOT fall.** Then §3.65's measurement was wrong and that is
  the finding.

---

## 5. THE FALSIFIABLE TESTS

1. **`md_conc` reported at 38, 205 and 230 mEq/day**, and shown salt-independent.
2. **`md_conc` at rest equals 53.8 mM**, and is inside Lorenz's "below 80 mM".
3. **Operating point unchanged**, by running.
4. **The chronic renin ratio reported before and after**, and the failure against van den
   Bosch stated in words.
5. **Chronic salt sensitivity, Jensen, the acute ordering ratio and the Lobo endpoints
   reported**, none fitted.
6. **`f_tal`'s note records that it lumps TAL sodium and descending-limb water**, and that
   only their ratio is identified.

---

## 6. WHAT WOULD MAKE THIS PASS A FAILURE

**Re-solving `RN.MD.RENIN_GAIN` to keep the renin ratio.** The arm's signal is now
salt-independent; a larger gain on a constant signal buys nothing, and reaching for it would
mean the structure was built to preserve an answer rather than to be right.

**Loosening the `runtests.jl` renin pin instead of rewriting it.** The pin tested a
calibration. If the calibration is gone the pin must say so.

**Presenting the lost agreement as a defeat.** It was never earned. §3.65 and Vallon both
said so before this pass existed.

**Letting `md_conc` depend on `f_prox_eff`.** The algebra says it cannot; if the
implementation makes it, the segments are wired wrongly.
