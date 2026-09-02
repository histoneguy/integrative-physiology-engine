# Pre-registration: re-deriving `RAAS.RENIN.PRESSURE_GAIN`

**Written BEFORE any source was opened.** Date: 2026-09-02. HANDOVER §4 item 3.

**Declared prior exposure, and it is small.** `src/components/Raas.jl` quotes van Ochten
2025 for the rectification threshold (93 ± 2 mmHg) and for the paper's own statement that
*risk of bias was high in most studies*. The ledger note on this row says van Ochten
*"reports the renal baroreflex slope in animal units this model cannot consume directly,
so the gain is fitted rather than converted."* **That sentence is a claim by a previous
session about a paper, and this document treats it as a hypothesis to test rather than a
finding to inherit.** No full text has been opened. No PRA value has been looked up.

**Why this blocks two records.** ADR 0013 and ADR 0015 are competing explanations for the
same salt-sensitivity discrepancy, and §3.11 measured ADR 0015's effect while this gain
carried an unsourced value. It sets how hard the tubular term pushes.

---

## 1. WHAT THE MODEL ALREADY SAYS, MEASURED

Reproduce with:

    julia --project=. bench/renin_gain_sweep.jl

**The whole of the derivation, on the model side, is one line.** `Raas.jl` sets
`renin_drive = max(0, (P_thr − MAP)/MAP_ref)` and `pra → 1 + g_renin · renin_drive`, so at
the operating point:

    g_renin  =  (pra_rest − 1) / 0.069210          drive at 205 mEq/day, MAP 86.97876

and the incumbent 19.0 reproduces `pra_rest` = 2.31498 exactly.

| intake mEq/d | MAP | renin_drive | `pra` | `aldo` | `fr_mod` |
|---|---|---|---|---|---|
| 205 | 86.97876 | 0.069210 | 2.31498 | 1.56977 | +4.7e-07 |
| 154 | 84.45010 | 0.098275 | 2.86722 | 1.76095 | +1.1e-07 |
| 103 | 81.92181 | 0.127336 | 3.41938 | 1.93569 | +6.8e-08 |

### `pra = 1` IS NOT RESTING RENIN, AND CONFUSING THE TWO IS HOW THIS ROW BROKE

The form is **rectified**: `renin_drive` is zero at and above `P_thr` = 93 mmHg. So
**`pra = 1` is renin at the PLATEAU of the renal baroreflex** — the floor, reached when
renal perfusion pressure is at or above threshold. It is *not* the resting value on a
normal diet, and the model's resting value is 2.31 precisely because the operating point
sits 6 mmHg below threshold.

**The voided calibration confused exactly these two.** It fitted the gain so the low-salt
arm doubled PRA "from a baseline of 1.0" — which was only the baseline while
`CV.MAP.SETPOINT` was also 93 and the drive was identically zero. **Any replacement anchor
must state which of the two levels it measures.**

### What the gain is worth, and it is not what §3.11's note assumed

**With escape ON, the steady state barely moves** across a 16-fold change in the gain —
0.0000% at 4.75, 0.81% at 76.0. Confirmed, not assumed.

**With escape SUPPRESSED, which is ADR 0015's configuration, the gain is most of the
answer:**

| `g_renin` | salt-step shift | per 100 mmol/day | fall vs escape-ON |
|---|---|---|---|
| 4.75 | 3.897 | 3.821 | 22.9% |
| 9.50 | 3.253 | 3.189 | 35.7% |
| **19.0 (incumbent)** | **2.493** | **2.444** | **50.7%** |
| 38.0 | 1.728 | 1.694 | 65.8% |
| 76.0 | 1.083 | 1.062 | 78.6% |

**ADR 0015's headline 50.7% IS the `g_renin` = 19.0 row.** Its whole magnitude is a
function of a row that has carried no target since 2026-08-27.

**Fixed here, before the search: the DIRECTION survives and the SIZE does not.** §3.11's
pre-registered rule was that a fall above 20% means the pathway is live. That verdict
holds even at a quarter of the incumbent gain, where the fall is still 22.9%. **So this
extraction cannot overturn ADR 0015; it can only resize it.** Recording that in advance
stops a convenient reading either way.

---

## 2. THE ANCHOR, AND THE THREE CANDIDATES IN FIXED PREFERENCE ORDER

The quantity needed is `pra_rest`: **resting plasma renin activity as a multiple of its
value at the renal baroreflex plateau.** Candidates, ranked before searching:

**A. The slope in van Ochten 2025 itself.** *Physiol Rep* 2025;13(17):e70547, PMID
40930784. It is already the source for both the threshold and the rectified form. If it
reports the renin response per unit renal perfusion pressure **as a fraction of the
plateau value**, that *is* `g_renin` and no second source is needed. **This is checked
first, and the ledger's claim that the units cannot be consumed is checked with it.**
A slope in absolute renin units becomes consumable if the paper also reports the plateau
level, because the ratio is what the model wants.

**B. A human study reporting PRA at two or more arterial pressures with sodium intake
held constant.** This is the clean anchor and it may not exist: servo-controlling renal
perfusion pressure is not performable in humans, which is the same ethical ceiling ADR
0006 already invokes for this row's threshold. Recorded as expected-absent, not assumed
absent.

**C. Human PRA across sodium intake. AVAILABLE, TEMPTING, AND DECLARED WRONG IN
ADVANCE.** `renal_hemodynamics_salt_sources.md` already records van den Bosch 2021, n=70
healthy men: PRA 2.10 (1.40–3.10) on high salt against 5.74 (4.19–7.80) on low, with MAP
88 against 86 mmHg. **Fitting the gain to that attributes the entire salt-induced renin
response to 2 mmHg of arterial pressure**, when in humans it runs mostly through macula
densa sodium delivery and renal sympathetic traffic, neither of which this component has.
**Candidate C may be used to FALSIFY the structure (§4) and may not be used to fit the
gain.**

---

## 3. WHAT MAY BE ENTERED

Only `RAAS.RENIN.PRESSURE_GAIN`. **One row.** `RAAS.PRA.TAU` (0.0035 d, `assumed`,
tier C) and `RAAS.ALDO.REABSORPTION_GAIN` (0.011, `assumed`, tier C) are the other two
weak rows in this component and are **out of scope** — two changes at once leaves neither
testable, which is the reason §7 gives for not batching the SHA citations.

**Species.** ADR 0006's amendment applies unchanged: an animal value is provenance rather
than debt **where the human experiment cannot ethically be performed**, with species,
preparation and tested range recorded. That clause plainly applies to servo-controlled
renal perfusion pressure. It does **not** license reaching for animal data to avoid
looking for human data on resting renin, which is measured in humans constantly.

---

## 4. THE STRUCTURAL FALSIFICATION TEST, AND IT NEEDS NO THRESHOLD

The rectified linear form imposes a **ceiling on the PRA ratio it can produce** between
any two pressures, and the ceiling does not depend on the gain:

    pra(MAP_lo) / pra(MAP_hi)  =  (1 + g·d_lo) / (1 + g·d_hi)   ->   d_lo / d_hi   as g -> infinity

with `d = (P_thr − MAP)/MAP_ref`. **So if an observed PRA ratio exceeds `d_lo/d_hi` for
the pressures at which it was observed, no value of this gain reproduces it and the
structure is what is wrong.** That is a parameter-free test and no threshold has to be
chosen, which is why it is used instead of one.

- **S1 — the observed ratio is below the ceiling.** The structure can carry the data.
  Proceed to derive the gain from the best available anchor.
- **S2 — the observed ratio EXCEEDS the ceiling.** The pressure-only renin control cannot
  produce the human salt-induced renin response at any gain. **The gain is then not
  identifiable from salt data**, and the finding is structural. Write it up; do not fit.

---

## 5. THE DECISION RULE, FIXED IN ADVANCE

- **R1 — candidate A yields a convertible slope.** Enter it. `extraction_method` becomes
  `derived` (converted from a reported slope) or `reported`, tier per ADR 0006 with
  species and preparation recorded. **The row stops being `assumed` and that is the goal.**
- **R2 — candidate A fails but a human anchor fixes `pra_rest`** in the plateau-relative
  sense §1 defines. Derive `g_renin = (pra_rest − 1)/0.069210` and enter it, recording the
  normalisation explicitly on the row so the next reader cannot repeat the 1.0 confusion.
- **R3 — no anchor, and branch S2 holds.** `g_renin` **stays 19.0 and stays `assumed`**,
  its note is rewritten to say the row is not identifiable from the available evidence
  *because the structure is pressure-only*, and an ADR records the structural gap.
  **A value that cannot be sourced must not acquire a citation**, and the honest outcome
  here is a better-documented assumption, not a number.
- **R4 — no anchor and S1 holds.** Stays 19.0 and `assumed`, with what was tried recorded
  exhaustively. **This is the branch that must not be avoided by fitting to candidate C.**

**In every branch, ADR 0015 gets the §1 sensitivity table**, because whatever happens to
the gain, that record's magnitude has to be read against it.

---

## 6. WHAT WOULD FALSIFY THE APPROACH RATHER THAN THE VALUE

- **If resting PRA in healthy humans has no single value** — it is famously dispersed, and
  assay methods differ by more than the quantity — then a point estimate is the wrong
  object and the row should say so rather than average across assays. `pooling.md`
  prohibits pooling across incompatible measurement methods, and PRA by enzyme-kinetic
  assay, by direct renin concentration and by antibody-trapping are not the same
  instrument.
- **If the plateau level cannot be identified in any preparation**, the normalisation
  `pra = 1` is not measurable and the gain is not a physical quantity as currently
  defined. That is a reason to redefine the normalisation, which is an ADR, not a fit.
- **If renin turns out to be controlled by sodium delivery in a way the model cannot
  express** — branch S2 — the correct output is a structural record, and any number
  entered here would be absorbing a missing mechanism exactly as `G_pn` did (§3.3).

---

## 7. OUT OF SCOPE

- **ADR 0013 and ADR 0015**, except that both receive the §1 sensitivity table.
- **`RAAS.PRA.TAU` and `RAAS.ALDO.REABSORPTION_GAIN`.**
- **Adding a macula densa or sympathetic renin pathway.** Branch S2 would *record* the
  need; building it is a separate decision with its own build-order question under
  ADR 0006.
- **Angiotensin II vasoconstriction**, which `Raas.jl` omits deliberately.
- **The escape time constant.** ADR 0015 already lists it as undecided.
