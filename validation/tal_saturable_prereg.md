# Pre-registration — saturable TAL transport with chronic adaptation

**Written 2026-09-20, before any equation is written.** Verify with

    git log --diff-filter=A -- validation/tal_saturable_prereg.md

ADR 0025 named this as its own falsifier. This pass builds it.

---

## 0. WHAT ADR 0025 LEFT BROKEN

Constant fractional TAL reabsorption makes `md_conc` = `C_Na·(1 − f_tal)` — rigidly
proportional to plasma sodium **at every flow**. That gave Vallon's chronic
salt-independence for free and **cost Jensen's acute response**, which fell from 94% to 43%
and left its 60–250 band. ADR 0025's Consequences named saturable transport as the fix and
said that if it does not work the constant-fraction assumption is not what is wrong.

---

## 1. THE SOURCE

**Layton HE, Pitman EB, Moore LC.** *Nonlinear filter properties of the thick ascending
limb.* Am J Physiol 1997;273(4):F625-F634. **PMID 9362340. FULL TEXT READ**, supplied by
the owner.

**It is a MATHEMATICAL MODEL, and that is recorded rather than hidden.** Its transport
constants enter here as `calibrated` with a **named originating model**, which is what
`SOURCES.md` reserves that label for. Table 1, backleak-free column:

| | |
|---|---|
| Michaelis constant `Km` | **140 mM** |
| chloride at TAL entrance `Co` | 275 mM |
| macula densa chloride `Cop` | **32.12 mM** |
| TAL length / radius / SNGFR | 0.500 cm / 10.0 µm / 30.0 nl/min |

**WHAT TRANSFERS IS THE FORM AND `Km`.** The paper's central result is that *"NaCl
concentration in intratubular fluid at each location along the TAL depends only on the
fluid transit time up the TAL to that location"* — which is the flow dependence, stated
exactly.

## 1.1 THE FORM, INTEGRATED

For plug flow up a water-impermeable tube with Michaelis-Menten efflux, following a fluid
element, `dC/dt = −Vmax·C/(Km + C)` integrates to

    Km * ln(C0/C) + (C0 - C) = Vmax * transit_time,    transit_time ∝ 1/flow

**The operating point sets `Vmax·transit` and nothing is fitted:** with this model's TAL
entrance at `C0` = 140 mM (isosmotic proximal output) and `md_conc_ref` = 53.9,
`Vmax·to` = 140·ln(140/53.9) + 86.1 = **219.7 mM**.

Checked before building:

| relative flow | `md_conc` |
|---|---|
| 0.70 | 32.1 mM |
| **1.00** | **53.9** |
| 1.50 | 77.1 |
| 2.00 | 90.8 |

**Higher flow, shorter transit, less complete reabsorption, higher concentration** — and at
1.5× flow it approaches **Lorenz's 80 mM threshold**, which the model can now traverse.

---

## 2. AND IT BREAKS VALLON UNLESS TRANSPORT ADAPTS — DECLARED BEFORE RUNNING

`f_prox_eff` varies **1.76×** across the salt step (Folkerd), so TAL flow varies with it.
With `Vmax` fixed, `md_conc` would swing about **34%** chronically — **contradicting Vallon
2002**, who measured no change in the TGF signal across dietary salt in normal rats.

**THE RECONCILIATION IS TUBULAR ADAPTATION, AND IT IS THE STANDARD PHYSIOLOGY.** TAL
transport capacity tracks sustained load. So:

    D(Vmax_ad) ~ (delivery-matched target - Vmax_ad) / tau_tal

- **acutely** (minutes to hours) `Vmax_ad` is fixed, flow rises, `md_conc` rises — Jensen;
- **chronically** (days) `Vmax_ad` tracks delivery, `md_conc` returns to reference — Vallon.

**ALL THREE SOURCES BECOME TRUE AT ONCE**, which none of the three previous forms managed.

**`tau_tal` IS ASSUMED AND THE ROW MUST SAY SO.** It is bracketed rather than measured:
above Jensen's 4-hour protocol, which sees the flow effect, and below Vallon's one-week
diets, which do not. **It may NOT be tuned to make Jensen pass** — §5.

---

## 3. WHAT MAY NOT MOVE

- **The operating point.** `md_conc` = `md_conc_ref` at rest, `md_drive` = 0 there.
- **`Km` = 140 mM is Layton's and is not adjustable.**
- **`RN.MD.RENIN_GAIN`, `f_prox_eff`, `k_prox`, `f_tal`, the sympathetic arm, `G_pn`, the
  volume gain** — none of them.
- **No band or tolerance widened.**

---

## 4. THE DECISION RULE

- **L1 — `md_conc` is flow-sensitive acutely and salt-independent chronically, Jensen
  returns inside 60–250, the operating point holds.** Adopt.
- **L2 — Jensen returns but `md_conc` now varies chronically.** Vallon is broken and the
  adaptation is too slow. Report; do not fix by tuning `tau_tal` toward Jensen.
- **L3 — `md_conc` stays chronically flat but Jensen does NOT return.** Then ADR 0025's
  stated falsifier has fired: **saturable transport is not what was missing**, and that is
  the pass's result.
- **L4 — the operating point moves, or the chronic renin ratio moves.** Report; the renin
  arm was not supposed to be touched.

---

## 5. THE FALSIFIABLE TESTS

1. **`md_conc` at 38, 205, 230 mEq/day** — still salt-independent chronically.
2. **`md_conc` during Jensen's acute load**, reported, showing it rises.
3. **Jensen's FE_Na rise against its 60–250 band**, reported whichever way.
4. **Operating point unchanged**, by running.
5. **Chronic renin ratio, chronic salt sensitivity, the Lobo endpoints and the ordering
   ratio** reported, none fitted.
6. **`tau_tal`'s row states it is assumed, states the bracket, and states that it was not
   tuned to Jensen.**

---

## 6. WHAT WOULD MAKE THIS PASS A FAILURE

**Tuning `tau_tal` to make Jensen pass.** Jensen is the test. The bracket is hours-to-a-week
and the value is taken from the middle of it, not from the endpoint that flatters the model.

**Adjusting `Km`.** It is Layton's, entered as `calibrated` with his model named.

**Reporting L1 when the truth is L2.** Chronic `md_conc` is the easier number to leave out,
and §5 test 1 exists so that it cannot be.

**Presenting Layton's constants as measurements.** They are a model's parameters, chosen in
his Ref. 15 to match experiments. The row says so.

---

## 7. AMENDMENT 1 — L5, AND IT IS NOT ONE OF THE FOUR OUTCOMES I DECLARED

**Written 2026-09-20, after running the structure in §1.1 and BEFORE building anything to
fix it.** §4 offered four outcomes. **The model produced a fifth: it does not have a steady
state at all.** That is my omission, not a surprise in the physiology, and it is recorded
here rather than quietly repaired.

### What happened

`retcode = Success`, and the trajectory is a **violent limit cycle**: `pra` between 1e-66
and 23.4, `md_conc` between 1e-9 and 131.7, `f_prox_eff` slamming between both ends of its
clamp. Nothing converges.

### The cause, measured rather than argued

Differentiating the transport integral at the operating point:

    dC/dphi = R / (Km/C + 1) = 61 mmol/L per unit relative flow
    relative gain (dC/C)/(dphi/phi) = 1.13

So `md_conc` is **slightly more than proportional to TAL flow** — and that closes a loop
which was inert while the reabsorbed fraction was constant:

    md_conc down -> md_drive up -> renin up -> pra up
                 -> proximal reabsorption up -> TAL flow down
                 -> transit longer -> md_conc down FURTHER

Loop gain through the sourced constants is `1.13 x g_md 4.99 x k_prox 0.29` = **1.6**, times
the renin-to-`pra` gain. **Above one, so it diverges.**

**CONFIRMED BY BREAKING IT AT EACH END, not by inspection:**

| | retcode | `md_conc` | `pra` | MAP, last 100 d |
|---|---|---|---|---|
| as built | Success | 1e-9 – 131.7 | -9e-8 – 23.4 | oscillating |
| `k_prox` = 0, actuator cut | Success | **53.8 – 54.2** | **1.0 – 1.32** | **87.01 flat** |
| `g_md` = 0, sensor cut | Success | **53.8 – 58.9** | **1.0 – 1.30** | **87.01 flat** |

Either cut removes it completely. **The loop is the one named above and no other.**

### THE MISSING MECHANISM IS TUBULOGLOMERULAR FEEDBACK

The macula densa has **two** effectors. This model has the slow one and not the fast one:

- **renin release**, slow, inverse — built, ADR 0021;
- **afferent arteriolar tone**, seconds, direct — **not built**. A rise in luminal NaCl
  constricts the afferent arteriole and **lowers** single-nephron GFR, which lowers flow
  and returns the concentration. **Negative feedback, and it is the loop that dominates at
  the macula densa.**

While the TAL reabsorbed a constant fraction, `md_conc` = `C_Na(1 - f_tal)` **could not
respond to flow at all**, so neither feedback path could act and the omission was invisible.
Making transport saturable is what exposed it.

**THIS IS "CONNECT IT AND RUN IT" (directive 1.11) PRODUCING A DEFECT NO GATE COULD SEE.**
Six gates pass on the unstable model. Running it is what found this.

### L5 — the decision rule, fixed before the fix is built

- **The instability is a REAL PROPERTY of the structure**, not a solver artefact: it
  survives `Rodas5P` at `abstol` and `reltol` of 1e-8 and is removed by cutting either end
  of the loop.
- **`g_md` MAY NOT BE REDUCED to restore stability.** §3 already forbids re-solving it and
  the reason is now stronger, not weaker: a smaller gain would hide a missing mechanism
  behind a fitted constant. The same goes for `k_prox`, which is Folkerd's.
- **`tau_tal` MAY NOT BE SHORTENED to damp it.** §6 named that as what would make this pass
  a failure, and the instability is exactly the pressure that would tempt it.
- **Tubuloglomerular feedback is to be SOURCED AND BUILT**, not approximated by a damping
  term chosen to work. Its own ADR, its own evidence tier, its own falsifier.
- **If TGF with sourced constants does NOT stabilise the loop**, that is the result and it
  is reported as one. Saturable transport would then be wrong or incomplete, and §4's L3
  applies after all.

### What this does NOT change

The transport integral, `Km`, and the entrance concentration are untouched, and the
operating point is still preserved by construction. **The equation is not what is broken.**
What is broken is that a flow-sensitive macula densa was wired to its slow effector and not
its fast one.
