# Pre-registration — the osmotically inactive sodium store

**Written 2026-09-17, before ADR 0004's compartment is switched on, before any sweep of it
is run, and before any source on sodium storage is opened.** Verify the ordering with

    git log --diff-filter=A -- validation/sodium_store_prereg.md
    git log --diff-filter=A -- validation/sodium_store_extract.py

Opened at the owner's instruction, following HANDOVER §3.49.

---

## 0. THE THING TO EXPLAIN, AND IT IS A DISSOCIATION RATHER THAN A LEVEL

Drummer 1992 (PMID 1590419, **full text supplied by the owner and read**) fits two
monoexponential half-lives to an acute isotonic load:

| | |
|---|---|
| body weight back to baseline | **7 h** |
| sodium balance back to baseline | **10 h** |

**Weight comes back FIRST. Ratio 0.70.** The model's ratio is **1.065** — volume 13.33 h,
sodium 12.52 h — because `V_ecf` is tied to `Na_ecf` and **water cannot leave ahead of
salt.**

**THE LEVELS ARE NOT THE PROBLEM AND THIS MUST NOT BE FORGOTTEN MID-PASS.** Over the bulk
3–22 h window the model excretes 1429 mL against 1322 and 220.6 mmol against 261.0. Its
sodium half-life is 1.25× out. §3.49 withdrew §3.47's "twofold disagreement" precisely
because it read a water defect as a sodium one. **A pass that fixes the ratio by moving a
natriuretic gain has repeated that error.**

## 0.1 THE COMPARTMENT ALREADY EXISTS, IS PROVISIONAL, AND IS SWITCHED OFF

`BodyFluids.jl` has `Na_store`, `J_store ~ (f_store*Na_ecf - Na_store)/tau_store`, and
`D(Na_ecf) ~ Na_intake - Na_excr_rate - J_store`. **`build_model` defaults to
`storage = false`**, ADR 0004 is **PROVISIONAL**, and so
`BF.NA.OSMOTICALLY_INACTIVE_FRACTION` (0.15, `assumed`) and `BF.NA.STORAGE_TAU` (7 d,
`assumed`) are read by nothing. §3.47's stage 1 measured them **bit-identical from 0.1 d to
30 d** against the default build for exactly that reason.

**So this pass is directive 1.11 in its purest form: the thing is built, it is wired, and
nobody has ever turned it on and looked.**

---

## 1. THE EVIDENCE, AND ONE OF THE THREE ITEMS IS PROBABLY NOT ABOUT THE STORE

| | number | what it bears on |
|---|---|---|
| Drummer's half-life dissociation | weight 7 h, sodium 10 h, ratio **0.70** | **the store** |
| Van Regenmortel 2022, PMID 34798374, open access, read | ΔNa 171 mmol → Δfluid **590 mL**; plasma tonicity implies 1221 mL, so **48%** appeared as fluid | **the store** |
| Drummer's haematocrit | **−10.0%** at 6 h (45.6 → 40.6); model **−6.4%** | **probably NOT the store** |

**THE THIRD IS LISTED SO IT CANNOT BE SWEPT INTO THE STORE'S EVIDENCE BY ACCIDENT.** A
haematocrit shortfall at 6 h is what a **constant `f_pv`** produces — the model
equilibrates an infused load across plasma and interstitium instantly, so it understates
the early intravascular share. Drummer gave 2.1 L in 25 min against Lobo's 2 L in 60 min,
and the model matches Lobo's 6 h plasma expansion while missing Drummer's haematocrit,
which is what a too-fast equilibration looks like. **It is out of scope and it is not
evidence for this pass.** If turning the store on happens to move it, that is a finding to
report, not a target.

### 1.1 AND VAN REGENMORTEL IS A DIFFERENT MANOEUVRE, DECLARED NOW

48 h of **continuous** maintenance infusion, not an acute bolus, and the subjects **fasted
for 48 h** — the paper names the resulting weight loss as a confound on the absolute
balances itself. **Only the between-treatment contrast is admissible**, because the fast is
common to both arms. It is a **corroborating** number and it may not be pooled with
Drummer's, which is a different protocol on different subjects — `pooling.md`.

---

## 2. STAGE 1 — TURN IT ON AND LOOK, BEFORE SOURCING ANYTHING

**No row may be re-valued and no structure changed until this is run and reported in full,
including whatever changes nothing.**

Sweep, on a `storage = true` build, `f_store` and `tau_store` jointly, reporting for each:
the **volume** half-life, the **sodium** half-life, **their ratio**, the chronic salt
sensitivity, and Jensen's final window.

**THE TARGET IS THE RATIO, 0.70, AND NOT EITHER HALF-LIFE ALONE.** A configuration that
hits 7 h on volume by also dragging sodium to 7 h has reproduced nothing.

- **If some admissible (`f_store`, `tau_store`) reproduces a ratio near 0.70 while keeping
  the chronic salt sensitivity inside 1.70–2.30 and Jensen inside its band — that is the
  result**, and the two rows are then worth sourcing properly.
- **If none does, the compartment as ADR 0004 specifies it cannot produce the dissociation**,
  and that is a finding about its FORM — reported, with the structure that would be needed
  named but not built.

## 2.1 THE FORM MAY BE THE PROBLEM AND THE SUSPICION IS RECORDED IN ADVANCE

`J_store ~ (f_store*Na_ecf - Na_store)/tau_store` drives the store toward a **fixed
fraction of `Na_ecf`**. On an acute load `Na_ecf` rises by a few percent, so the store
takes up a few percent of a few percent. **It is not obvious that a proportional store can
buffer an acute load at all**, and §3.47's stage 1 already hints at it: with the branch on
at the ledger values the volume half-life moved only 13.10 → 12.93 h.

**Written down now so that arriving at it later reads as the rule working.** If stage 1
lands there, the honest statement is that the phenomenon is real, the model's compartment
is the wrong shape for it, and what the literature describes — capacity-limited,
concentration-dependent binding in skin and muscle glycosaminoglycan — is a different
functional form that this pass is **not** licensed to invent.

---

## 3. WHAT MAY NOT MOVE

- **`CV.ANP.NATRIURETIC_GAIN`, `RN.PRESSURE_NATRIURESIS.SLOPE` and `RN.ANP.TAU`.** §0 says
  why: the sodium levels are already about right and this is a water defect. **Moving a
  natriuretic gain in this pass repeats the error §3.49 withdrew.**
- **`anp_adaptation` and `anp_convexity` stay off.** They are answers to a question that
  should not have been asked.
- **`CV.PLASMA.ECF_FRACTION`.** The haematocrit item is out of scope — §1.
- **The chronic salt sensitivity must stay inside 1.70–2.30**, `dMAP/dV_ecf` inside
  2.82–4.02, and **Jensen inside its band with its value reported before and after**.
  `JENSEN_FINAL_WINDOW_RISE` may be re-pinned only with an explicit statement of what moved
  it.
- **`BF.NA.OSMOTICALLY_INACTIVE_FRACTION` and `BF.NA.STORAGE_TAU` MAY NOT BE SOLVED AGAINST
  DRUMMER'S RATIO.** They may be **sourced**. If stage 1 shows which region of the plane
  works, that is a *diagnostic*, and the rows still need primary literature — Titze's
  balance and skin-sodium work is the obvious place and none of it has been opened here.
  **A value fitted to the 0.70 and then cited to Titze would be the worst outcome available.**

---

## 4. DIRECTIVE 1.12 — THE ROUND NUMBERS AND THE ONE THAT IS A SLOGAN

**0.15** — the current `assumed` inactive fraction. **1/3** and **2/3**, the shares
conventionally quoted for exchangeable versus non-exchangeable sodium. **7 days**, the
current `assumed` storage time constant, which is a week because a week is a round number.

**And the slogan: "sodium is stored in skin without water."** It is quoted far more often
than any number attached to it is checked, this pass exists because of it, and **it is used
here to name a phenomenon and never to supply a magnitude.**

---

## 5. THE DECISION RULE

- **S1 — stage 1 finds an admissible region reproducing a ratio near 0.70 with every band
  held.** Report it as a diagnostic, then **source** the two rows against primary
  literature and re-run. ADR 0004 may then lose `provisional`.
- **S2 — a region reproduces the ratio but breaks the chronic window or Jensen.** Report
  both numbers. **Do not trade one for the other**, and do not re-solve a natriuretic gain
  to buy the room — §3.
- **S3 — no region reproduces the ratio.** Then ADR 0004's proportional form cannot produce
  the dissociation. **Report it as a finding about the form**, name what would be needed
  (capacity-limited binding), **and build nothing.** §2.1 predicts this.
- **S4 — the store turns out to be inert even switched on.** Report the sweep that shows it
  and say what reads the rows. This is §3.47 stage 1's outcome and it would mean ADR 0004's
  compartment does nothing at any parameterisation, which is worth knowing precisely.
- **S5 — anything else leaves its band.** Stop.

---

## 6. THE FALSIFIABLE TESTS

1. **The half-life RATIO against Drummer's 0.70**, reported alongside both half-lives
   separately. The ratio is the endpoint; the two half-lives are context.
2. **The interval series** — 0–3, 3–22, 22–46 h, water and sodium — against Drummer's, since
   the model already reproduces the bulk window and **must not stop doing so.**
3. **Chronic salt sensitivity inside 1.70–2.30** and `dMAP/dV_ecf` inside 2.82–4.02.
4. **Jensen's final window before and after, unfitted.**
5. **Van Regenmortel's 48%** — the fraction of a sustained sodium load appearing as fluid —
   as a **corroborating** comparison on a different protocol, never pooled with Drummer.
6. **The operating point is unchanged**: at the reference the store is at its steady state
   and contributes nothing, demonstrated by running.
7. **Stage 1 is reported in full**, including parameter combinations that changed nothing.

---

## 7. WHAT WOULD MAKE THIS PASS A FAILURE

**Moving a natriuretic gain.** Named first. §3.49 withdrew a published conclusion because a
water defect was read as a sodium one, and the same lever is still sitting there.

**Fitting `f_store` or `tau_store` to Drummer's ratio and then citing Titze.** The rows may
be sourced or they may stay `assumed`; what they may not be is solved against the endpoint
and dressed as measured.

**Reporting the volume half-life and not the ratio.** 7 h is reachable by making everything
faster, which reproduces the number and not the physiology.

**Letting the haematocrit item in.** §1 rules it out in advance because it is the most
convenient piece of evidence available and it is about a different parameter.

**The quiet one: turning `storage = true` on by default because it improves something.**
ADR 0004 is PROVISIONAL, the default build is 12 states, and changing that is a structural
decision needing its own record — not a side effect of a diagnostic sweep.
