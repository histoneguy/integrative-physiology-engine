# Pre-registration — hepatic insulin resistance as a lesion separate from peripheral

**Written 2026-09-24, immediately after ADR 0034 and before any code.**

    git log --diff-filter=A -- validation/hepatic_ir_prereg.md

Fourth pass under directive 1.16. **This is the omission ADR 0034 recorded against itself**,
and `egp_suppression_prereg.md` §9 named adding it in that pass as a way that pass would
fail — so it is here, on its own, where it can be tested alone.

---

## 1. THE REVIEW AND THE PRIMARY, AND WHAT THEY ESTABLISH

**Groop LC, Bonadonna RC, DelPrato S, Ratheiser K, Zyck K, Ferrannini E, DeFronzo RA.**
*Glucose and free fatty acid metabolism in non-insulin-dependent diabetes mellitus. Evidence
for multiple sites of insulin resistance.* J Clin Invest 1989;84(1):205–213. **PMID 2661589.**
Abstract read; it was already in hand as ADR 0034's corroborating source.

**ITS TITLE IS THE CLAIM.** Graded physiologic hyperinsulinaemia at **+5, +15, +30, +70,
+200 µU/ml** in nine lean NIDDM patients and eight matched controls:

> The basal rate of hepatic glucose production (HGP) was **higher in NIDDM** than in control
> subjects, and **suppression of HGP by insulin was impaired at all but the highest insulin
> concentration**. Glucose disposal was reduced in the NIDD patients **at the three highest
> plasma insulin concentrations**.

**TWO SEPARATE DEFECTS AT DIFFERENT INSULIN RANGES.** Hepatic suppression fails across almost
the whole range and is **rescued at the top**; peripheral disposal fails only at the **three
highest** steps. That is a **rightward shift of the hepatic dose–response** — more insulin
needed for the same suppression, with maximal effect preserved — and it is a different shape
of defect from the peripheral one.

**Ahrén & Pacini 2021 (PMID 33098240, full text read 2026-09-23)** supplies the framing
already used twice: insulin-independent and insulin-dependent disposal are separate terms,
and EGP suppression is one of the things `S_G` lumps.

---

## 2. WHAT THE MODEL CAN AND CANNOT REPRESENT TODAY — REQUIRED BY 1.16

**`glu_disposal` scales `S_I` ALONE.** So the only insulin-resistance lesion available is
**peripheral**. Since ADR 0034 the liver responds to insulin, but its *sensitivity* cannot be
lesioned.

**THE CONSEQUENCE, STATED BEFORE BUILDING:** the model's "type 2" is a peripheral-resistance
plus beta-cell-failure disease. **Real type 2 has hepatic resistance as well**, and it is the
arm that raises **fasting** glucose. So the model currently gets type 2's fasting
hyperglycaemia only through beta-cell failure, which overstates the beta-cell contribution.

---

## 3. DIRECTIVE 1.12 — ROUND NUMBERS LISTED BEFORE EXTRACTION

- **"Hepatic insulin resistance doubles fasting glucose output."**
- **"Type 2 is 50% hepatic, 50% peripheral."**
- Any single number for "the" degree of hepatic resistance — it is a **continuum across
  patients**, which is the point of a dial.

---

## 4. THE FORM, FIXED BEFORE ANYTHING IS BUILT

    egp_i ~ egp_basal * egp_0 / (1 + hep_sens * I_glu / K_egp)

**A RIGHTWARD SHIFT OF THE SAME HYPERBOLA, WHICH IS WHAT GROOP DESCRIBES.** `hep_sens` = 1 is
health and the equation is **identical** to ADR 0034's; `hep_sens` < 1 means more insulin is
needed for the same suppression, and **maximal suppression at infinite insulin is preserved**
— matching *"impaired at all but the highest insulin concentration"*.

**IT IS A LESION DIAL, NOT A SOURCED CONSTANT, AND THE ROW WILL SAY SO.** `beta_cell` and
`glu_disposal` are the precedent: dimensionless, **inert at 1.0**, set by the person running
the model. **Groop sources the SHAPE of the defect; no admissible source gives a population
value for its magnitude**, and inventing one would be §3's failure.

**WHY NOT RAISE `egp_0` INSTEAD.** Groop also reports basal HGP *higher* in NIDDM — but at a
*higher* prevailing insulin, so an elevated basal rate is **predicted by** a rightward shift
rather than being independent evidence for a second parameter. **One knob, and the elevated
basal output must EMERGE.** §6 test 3.

---

## 5. WHAT MAY NOT MOVE

- **`GLU.EGP.INSULIN_I50` (Rizza), `GLU.EGP.BASAL`, `egp_0`, `K_egp`** — this pass adds a
  multiplier and re-derives nothing.
- **`beta_cell`, `glu_disposal`** keep their exact current meanings.
- **The healthy operating point**, which `hep_sens` = 1 makes exact by construction.
- **No band, pin or tolerance widened.**

---

## 6. THE FALSIFIABLE TESTS

1. **`hep_sens` = 1 reproduces ADR 0034 bit-identically.** The null is testable.
2. **Health unchanged** — glucose 5.44, insulin 64.2, MAP, sodium, urine, `Na_excr`.
3. **THE PREDICTION, AND IT IS AN EMERGENT ONE: hepatic resistance alone raises FASTING
   glucose and raises basal EGP.** Set `hep_sens` < 1 with `beta_cell` = 1 and
   `glu_disposal` = 1. Glucose must rise, EGP must rise, and **insulin must rise too** — the
   compensation. **Groop's "basal HGP higher in NIDDM" must appear without being imposed.**
4. **Hepatic and peripheral resistance must be DISTINGUISHABLE**, not two names for one
   effect. Report glucose, insulin and EGP for `hep_sens` = 0.3 against `glu_disposal` = 0.3
   at matched glucose. **If the two are indistinguishable in every reported variable, the
   knob is redundant and must be removed** — that is a real possible outcome and the reason
   this test exists.
5. **A type 2 built from all three lesions** — modest beta-cell loss, peripheral and hepatic
   resistance — reported against the current two-lesion version, to show whether the
   beta-cell contribution was being overstated (§2).
6. **Full suite and all challenges.**

---

## 7. THE DECISION RULE

- **H1 — test 4 separates them.** Keep the knob; ADR.
- **H2 — test 4 shows them indistinguishable.** **Remove it and record that**, because a
  parameter that cannot be identified from any model output is not a lesion, it is a
  duplicate.
- **H3 — the model will not solve at low `hep_sens`.** Report the bound rather than clamping
  it quietly.

---

## 8. WHAT WOULD MAKE THIS PASS A FAILURE

**Entering a sourced-looking value for `hep_sens`.** §4. It is a dial.

**Adding a second parameter for elevated basal HGP.** §4 — that must emerge from the shift or
the shift is the wrong form.

**Reporting test 3 without test 4.** A knob that moves glucose is unsurprising; a knob that
moves glucose *differently from the one already there* is the finding.

**Tuning `hep_sens` so the three-lesion type 2 lands on a nice number.** §5, and test 5 is a
comparison, not a target.
