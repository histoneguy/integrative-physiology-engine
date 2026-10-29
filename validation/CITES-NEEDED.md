# Citations needed

**Standing catalogue, opened 2026-10-20 at the owner's instruction.** Every paper this model
needs and cannot read, what each one unblocks, and whether an alternative exists.

**ACCESS STATUS IS CHECKED, NOT ASSUMED** — each line was resolved through OpenAlex and, where
the publisher serves its own open-access link, downloaded. **No bot check has been worked
around on any publisher**, and three papers that looked paywalled turned out not to be
(Baron 1985, McPhaul 1968, Groop 1989, all from JCI's own links).

**HOW TO USE THIS.** The top table is the short list — papers that block a named decision or
build. Everything below it is debt that costs precision rather than progress. **A row marked
`closed` means OpenAlex reports no open version; it does not mean the owner cannot reach it
through an institutional subscription**, which is the point of this file.

---

## 1. BLOCKING — a decision or a build waits on these

| Paper | PMID | Access | What it unblocks |
|---|---|---|---|
| **Rizza RA, Mandarino LJ, Gerich JE.** Dose-response characteristics for effects of insulin on production and utilization of glucose in man. *Am J Physiol* 1981;240(6):E630–9 | **7018254** | **closed** (AJP bot-checked, not bypassed) | **B30.** The two-fold discrepancy with Groop on the insulin concentration at half-maximal EGP suppression — **29 vs 14 µU/ml.** Needed to know whether portal insulin was estimated, i.e. whether the two are even the same quantity. **This one matters most.** |
| **Edelman SV** et al. Kinetics of insulin-mediated and non-insulin-mediated glucose uptake in humans. *Diabetes* 1990;39:955–64 | **1973673** | **closed** | **ADR 0033** §7 test 5. A **four-point** NIMGU dose–response where Baron gives two, which would decide the two-term vs saturating form **on data** instead of on mechanism. |
| ~~**Chumlea WC** et al. *Kidney Int* 2001~~ | 11380828 | **SUPERSEDED — not needed** | **B37 is closed.** The owner supplied the **1999 Fels** paper instead (Kidney Int 56:244–252), which is **better here**: its FFM is DXA lean + bone mineral, exactly this model's `mass_ffm`, so its hydration ratio composes where the canonical 0.73 would not. **ADR 0038.** |
| **A bromide-dilution extracellular water series** in healthy adults, sexed, ideally with concurrent deuterium | — | **not yet searched** | **B39 — now the weakest thing in the fluid model.** ADR 0038 made the water *total* deuterium-sourced and sexed; the **ECF/ICF split is still bioimpedance**, and `V_ecf` is what feeds blood volume and pressure. Bromide is the reference method for extracellular water. |
| **Janssen I** et al. Skeletal muscle mass and distribution in 468 men and women aged 18–88 yr. *J Appl Physiol* 2000;89(1):81–8 | **10904038** | **closed** | **B36.** The regression of muscle mass on weight and height — he reports it explains ~half the variance, so a **curvilinear** form exists and the ledger currently carries a linear fraction. |
| **Wang Z, Deurenberg P, Wang W, Pietrobelli A, Baumgartner RN, Heymsfield SB.** Hydration of fat-free body mass: review and critique of a classic body-composition constant. *Am J Clin Nutr* 1999;69(5):833–41 | **10232621** | **closed.** Three routes tried: AJCN **bot-checked** (not bypassed), no PMCID, and the Wageningen repository holds **metadata only, no deposited text** | **B37 route 3.** The hydration constant itself, and whether it is **sex-invariant** — which is the whole question. Its abstract says *"approximately 0.73 in mammals"*, and **a round number from a review abstract is exactly what directives 1.12 and 1.16 forbid taking.** Same group as the five-level model. |

---

## 2. WOULD RESOLVE AN OPEN QUESTION, NOT BLOCKING

| Paper | PMID | Access | What it resolves |
|---|---|---|---|
| **Best JD, Taborsky GJ, Halter JB, Porte D.** Glucose disposal is not proportional to plasma glucose level in man. *Diabetes* 1981;30(10):847–50 | **6115785** | **closed** | **ADR 0033.** Would make the NIMGU form **pooled** rather than corroborated. Its abstract gives only *"more than twice basal"*, which spans 63–76%. |
| **Mogensen CE.** Maximum tubular reabsorption capacity for glucose and renal haemodynamics | **5093515** | **closed** | **B20 / B31.** TmG **and GFR in the same subjects**, which is what the spill threshold needs — the model currently forms `TmG/GFR` from two unrelated cohorts. |
| ~~**DeFronzo RA** et al. *Diabetes Care* 2014~~ | 23735727 | **OBTAINED 2026-10-20** via PMC3781504 | **Read.** Gave the threshold **9.5 ± 3.7 mmol/L** and TmG **317 mg/min** in healthy controls — **B38**. Its **Supplementary Data holds the splay model's equations and has NOT been fetched**; that is now the blocking item for B20. |
| **DeFronzo 2014 SUPPLEMENTARY DATA** — the splay model's equations and **integration convention** | 23735727 | **attempted, not reachable.** Europe PMC's supplementaryFiles returns only the article figures; the real supplement is on `care.diabetesjournals.org`, which bot-checks | **B20, and the ask is now precise.** The splay VALUE is in the text — 13,598 mg²/min² in healthy controls, as an AUC difference from the ideal curve. A one-parameter form can be inverted against that exactly. **What is missing is only the integration limits and the definition of "ideal".** |
| **Kirchheim HR** et al. *Pflugers Arch* 1987;410:441–9 | **3324052** | **closed** | **B26 / ADR 0036.** Already used from its abstract. Directive 1.5 limits what may be entered from one, and the GFR break-off SD matters for the 4.7 mmHg margin (**B33**). |
| **Carlström M, Wilcox CS, Arendshorst WJ.** Renal autoregulation in health and disease. *Physiol Rev* 2015;95:405–511 | **25834230** | **green OA** — *try this first* | The autoregulation review, read as abstract only. Reported as having a green copy; would let the myogenic/CT-GF structure be used rather than cited. |

---

## 3. PRECISION DEBT — rows standing on an abstract

**Systematically collected from the ledger, not from memory**: every row whose citation or note
records that only an abstract was read. A full text would let the dispersion, the cohort or the
functional form be entered properly.

| Row | PMID | What the abstract withheld |
|---|---|---|
| `GLU.NIMGU.FRACTION` | 2865274 | *(full text obtained — JCI open)* |
| `BF.MUSCLE.MASS_FRACTION` | 10904038 | no SD on the percentage; curvilinear form — §1 |
| `CV.VOLUME.NATRIURETIC_GAIN` | 11473492, 24067081, 1324562, 1590419 | four sources, none read in full |
| `RN.VOLUME_NATRIURESIS.TAU` | 1324562, 1590419, 6823962 | the lag's order, not just its constant |
| `BR.CARDIAC.SENSITIVITY` | 24477673 | **green OA — try first.** Underpins every transient (**B13**) |
| `RAAS.RENIN.SYMPATHETIC_THRESHOLD_SHIFT` | 7024507 | also the form of `Raas.P_thr_eff` |
| `RESP.CHEMO.VRT` | 14519377 | also `Respiratory.V_E`'s threshold |
| `THY.TSH.FT4_SLOPE`, `THY.LOOP_GAIN` | 19926783, 19226261 | the intercept is §4's item 1 — euthyroid TSH is 2.4× high |
| `THY.TSH.EUTHYROID` | 11836274 | — |
| `K.NONRENAL_LOSS_EXPONENT` | 3523191, 6486085 | — |

---

---

## 3b. THE ONE ROUTE THAT NEEDS NO CITE — AND ITS HONEST LIMITS

**B37 route 4: extract total body water from NHANES bioelectrical impedance directly**, by the
machinery `body_composition_extract.py` already uses.

**WHAT IT WOULD FIX.** The present source (Zhang) is **also BIA**, so the method does not get
worse — and everything else gets better: **US** rather than mainland-China conducted
(directive 1.17), **nationally weighted** rather than 160 students, **n in the thousands**, and
**sexed**, which is the defect B37 is about.

**WHAT IT WOULD NOT FIX, AND THIS IS WHY IT IS NOT AUTOMATICALLY THE ANSWER.** BIA remains the
weakest method against **deuterium dilution** for total body water and **bromide** for
extracellular. And **NHANES publishes resistance and reactance, not an ECF/ICF split** — the
three-way partition this ledger needs may not be derivable without importing a prediction
equation, which would make the row `calibrated` with that equation named.

**SO IT IS A STRICT IMPROVEMENT ON THE CURRENT ROW AND NOT A SOLUTION.** Worth doing if the
closed papers stay closed; **not worth doing instead of asking for them.**

---

## 4. WHAT IS *NOT* NEEDED, SO NOBODY FETCHES IT TWICE

**Already read in full**, all from publishers' own open-access links:

- **Baron 1985**, JCI — the NIMGU fraction and its two-point dose–response (ADR 0033).
- **McPhaul & Simonaitis 1968**, JCI — the point of splay, 0.83 ± 0.04.
- **Groop 1989**, JCI — portal and peripheral I₅₀, and the >90% suppression point (B29/B30).
- **Ahrén & Pacini 2021**, J Diabetes Investig — the glucose-effectiveness review.
- **Kelly 2009**, PLoS One — NHANES DXA reference values. **Read and deliberately not used**:
  its values are age-normalised curves in figures, and the underlying file was extracted instead.
- **Zhang N et al.**, PMC6751809 — read in full and **rejected**; see B37 and directive 1.17.

---

## 5. HOW THESE WERE REJECTED OR DEFERRED, SO THE REASONS DO NOT HAVE TO BE REDISCOVERED

- **Figures are not digitised here.** Fixed as branch N3 (`nimgu_form_prereg.md`) and branch S3
  (`glucose_splay_prereg.md`), and honoured both times. It is why Kelly 2009 was read and not
  used, and why Edelman's four-point curve needs the **text**, not the plot.
- **A reference standard is not a source.** ICRP Publication 89's organ masses were refused in
  `body_composition_prereg.md` §2 for the same reason this ledger refused Reference Man's 70 kg.
- **Directive 1.17** prefers studies not conducted in mainland China where an admissible
  alternative exists, and requires the **cohort to match this model's US reference individual**.
  Where only that literature exists, it is used with the provenance recorded — having nothing
  leaves a row `assumed`, which is not neutral.
- **Directive 1.5** — a citation never written unopened — is why abstract-only rows are marked
  as such rather than quietly carrying a full-text claim.
