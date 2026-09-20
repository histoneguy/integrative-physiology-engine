# Pre-registration — Lorenz 1990 and the macula densa renin arm

**Written 2026-09-20, before any note or comment is changed.** Verify with

    git log --diff-filter=A -- validation/macula_densa_lorenz_prereg.md

**NO PARAMETER MAY MOVE AND NO EQUATION MAY CHANGE.** This pass records what the primary
source says about a form this repository chose without it, and states precisely why the
obvious fix is not available.

---

## 0. WHY THIS SOURCE WAS SOUGHT

`RN.MD.RENIN_GAIN` = 4.99 is one of two `calibrated` rows — solved against van den Bosch's
salt–renin ratio rather than measured. The diagnosis on 2026-09-19 was that the model's
macula densa signal spans only **5.7%** across the whole salt step, so a large gain is
needed to reach the measured 2.73× renin ratio.

**Lorenz JN, Weihprecht H, Schnermann J, Skøtt O, Briggs JP.** *Characterization of the
macula densa stimulus for renin secretion.* Am J Physiol 1990;259(1 Pt 2):F186–F193.
**PMID 2197878. FULL TEXT READ**, supplied by the owner.

**Isolated perfused rabbit juxtaglomerular apparatus** — the preparation exists precisely to
study this signal *"in the absence of the confounding influences of intravascular pressure
and renal nerve activity."* Both of the model's other renin arms are physically removed.

---

## 1. WHAT IT MEASURED

Perfusate compositions, Table 1: **high = 141 mM Na⁺ / 122 Cl⁻**, **medium = 80 / 61**,
**low = 24 / 7**.

**Series 2 — there is a THRESHOLD.**

| group | perfusate | Na⁺ | renin secretion |
|---|---|---|---|
| A, n = 8 | high | 141 | 2.2 nGU/min |
| A | medium | 80 | **1.9 — no effect** |
| B, n = 8 | medium | 80 | 3.2 nGU/min |
| B | low | 24 | **16.6, P < 0.007** |

**Nothing happens between 141 and 80 mM. The entire ~5.2-fold response lives between 80 and
24.** The paper's own conclusion: the full response occurs *"below 80 mM Na+ and 61 mM Cl-."*

**Series 3 — and DELIVERY IS NOT THE STIMULUS**, n = 7:

| period | Na⁺ delivery | renin |
|---|---|---|
| 1 — medium NaCl, high flow | 5,572 ± 924 peq/min | 3.4 nGU/min |
| 2 — flow reduced, same concentration | 1,197 ± 276 | 8.1, P < 0.014 |
| 3 — flow restored, **concentration cut 54 mM** | **1,811 ± 300** | **26.3, P < 0.011** |

**From period 2 to 3 delivery ROSE 51% and renin rose 3.2× anyway.** The paper concludes
*"RSR responds with a larger change to alterations in NaCl concentration than in NaCl
delivery or fluid flow rate."*

---

## 2. BOTH FINDINGS CONTRADICT THE MODEL'S FORM, AND ONE OF THEM CONTRADICTS A COMMENT

`Raas.jl` / `Renal.jl` carries `md_drive ~ (Na_distal_ref - Na_distal) / Na_distal_ref` with
this comment:

> *"SIGNED, NOT RECTIFIED, unlike the pressure arm. The pressure relation is rectified
> because renin plateaus above a measured threshold; **nothing found says the macula densa
> arm does**, and inventing a threshold to match the other arm's shape would be a functional
> form chosen here."*

**Lorenz is the something found.** The macula densa arm **does** plateau above a threshold,
measured, in the cleanest preparation available. **That comment is now false and must be
corrected whatever else this pass does.**

And the signal is keyed to **delivery**, which Series 3 shows is not the stimulus.

---

## 3. WHY NEITHER CAN BE FIXED HERE, STATED BEFORE TRYING

**THE THRESHOLD CANNOT BE PLACED ON THIS MODEL'S AXIS.** Lorenz's threshold is a
**concentration**, 80 mM Na⁺, and he states the full response occurs *"within the
concentration range normally occurring at the macula densa"* — so **the normal operating
point is BELOW the threshold, on the steep limb.** The model's `md_drive` is zero at its
reference by construction, and where that reference sits relative to 80 mM is **unknowable
without a macula densa concentration**. Rectifying at the model's reference would put the
threshold in the wrong place and would be exactly the "functional form chosen here" the
comment warns against.

**THE CONCENTRATION CANNOT BE COMPUTED.** Macula densa NaCl concentration is distal sodium
delivery divided by distal flow. **This model lumps water reabsorption into one term and has
no distal flow**, so the quantity does not exist and cannot be derived from what does.

---

## 4. WHAT THIS PASS MAY AND MAY NOT DO

- **MAY:** correct the false comment; record Lorenz on the relation and on
  `RN.MD.RENIN_GAIN`; state the structural requirement and the prediction in §5.
- **MAY NOT:** move any parameter; rectify `md_drive`; invent a concentration; re-solve
  `RN.MD.RENIN_GAIN`; touch any band, pin or tolerance.
- **The model output must be unchanged** — this pass edits prose only.

---

## 5. THE DECISION RULE

- **M1 — both findings stand and neither is representable.** Record them, correct the
  comment, and state the structural requirement. **Expected.**
- **M2 — the threshold turns out placeable** because the model's reference can be located
  against 80 mM from something already sourced. **Report it and stop**; rectifying is then a
  separate pass with its own pre-registration.
- **M3 — Lorenz's preparation is disqualified** for a reason found on reading. Record why
  and leave everything.

---

## 6. THE FALSIFIABLE TESTS

1. **The false comment is corrected**, and the correction quotes Lorenz.
2. **`git diff` shows no `value` field change**, and no equation change.
3. **The delivery/concentration dissociation is recorded with Series 3's numbers**, because
   it is the stronger of the two findings and the easier to leave out.
4. **`RN.MD.RENIN_GAIN`'s note states why it remains `calibrated`** — not "no source found",
   but "the source exists and the model cannot consume it".
5. **The prediction in §7 is written before any follow-up pass.**

---

## 7. THE PREDICTION THIS LEAVES BEHIND

**If a macula densa NaCl concentration is built — distal delivery over distal flow, which
needs the lumped water reabsorption split — then `RN.MD.RENIN_GAIN` becomes sourceable from
Lorenz and this repository's second `calibrated` row can be retired.**

**And van den Bosch's 2.73× renin ratio becomes a TEST rather than an estimation set**,
which it has never been. That is the thing worth having, and it is worth more than the gain.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Rectifying `md_drive` at the model's reference.** §3. The threshold is a concentration and
the reference is not known against it; putting it at zero because that is where the model's
zero happens to be is the invented form the code comment already warns against.

**Quietly leaving the false comment.** It is the one thing here that is unambiguously wrong.

**Reporting the threshold and not the delivery/concentration dissociation.** Series 3 is the
stronger result — renin rose while delivery rose — and it is the one that says the model's
signal is the wrong variable rather than the right variable with the wrong shape.
