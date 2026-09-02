# Source table: renal haemodynamics across sodium intake

**This is a CANDIDATE LIST, not an extraction.** No value here is entered anywhere, no
pooling rule has been applied, and no conclusion is drawn. If any of it is ever used to
set a parameter, that needs its own pre-registration first, written before the numbers
below are re-read.

**THAT PRE-REGISTRATION NOW EXISTS: `validation/renal_hemodynamics_prereg.md`.** It could
not satisfy the sentence above — this table was already on `main` and had been read — so
its §1 declares the prior exposure instead and fixes every threshold by reusing a rule
that was set before its own run. Read it before touching anything below, and note that it
forbids §2 and §3 of this table from supplying magnitudes at all.

**THE EXTRACTION HAS NOW RUN.** `validation/renal_hemodynamics_extract.py`, verdict
**branch G3**, one row entered — `RN.GFR.VOLUME_SENSITIVITY = 1.30`. **Read §0 below
before using this table again: it is not nine independent primaries and never was.**

---

## 0. INDEPENDENCE AUDIT — ADDED AFTER EXTRACTION, AND IT CHANGES HOW §1 READS

**The nine healthy-human primaries in §1 are FOUR GROUPS, and three of the nine are one
cohort.** This was not visible from the retrieved records and only appeared on reading
van den Bosch as full text.

| group | papers here | note |
|---|---|---|
| **Groningen** (Navis) | Krikken 2007, Visser 2009, van den Bosch 2021, Toering 2018 | **The first three are ONE parent cohort** of ~93–95 healthy men. van den Bosch says so in its Methods: *a post-hoc analysis from a prior study … published previously (Krikken et al., 2007; Visser et al., …)*, n = 70/93. All use ¹²⁵I-iothalamate and the same 50/200 mmol crossover. |
| **Brigham** (Hollenberg / Williams) | Shoback 1983, Redgrave 1985, Conlin 1993 | Also the §2 review, Hollenberg & Williams 2006. |
| **Mayo** | Textor & Turner 1991 | |
| **UCL / Naples** | Barba 2000 | |

**Consequence, and it reached ADR 0015.** That record cited *"four independent groups,
n up to 95"* for its E1 human claim, naming Krikken, van den Bosch, Redgrave and Conlin.
**Those are two groups.** Corrected there.

**Consequence for pooling.** Krikken, Visser and van den Bosch may never be pooled with
one another. `RN.GFR.VOLUME_SENSITIVITY` is `single-source`, **k = 1**, and it would have
looked like k = 3.

**Two genuinely independent groups were added by the pre-registered sweep 4** and are in
§6 below.

Compiled 2026-09-02. Three sweeps, 24 queries. **Healthy humans first; animal data listed
separately as backup, per directive 1.6.** Every entry read from the retrieved PubMed
record; where the record gives only a direction, that is what is recorded.

---

## 1. HUMAN, HEALTHY OR NORMOTENSIVE — primary

| # | study | n | design | Na levels | what it reports |
|---|---|---|---|---|---|
| 1 | **Krikken 2007** `17091123` *Kidney Int* 71(3):260-5 | **95** healthy men, median age 23, BMI 23.0±2.5 | crossover | 50 vs 200 mmol | GFR **and** ERPF both rise on high salt (both P<0.001). ΔGFR **+16.1±13.1** mL/min (BMI<25) vs +7.8±12.3 (BMI≥25). ΔFF **+1.1±2.3%** (BMI<25) vs −0.1±2.2%. ERPF not related to BMI. |
| 2 | **van den Bosch 2021** `34921521` *Physiol Rep* 9(24):e15103 | **70** healthy men, 24±7 y | crossover, 7 d/level, intake verified by 24 h urine | 230 vs 38 mmol measured | ERPF **592±96 vs 559±89** (p<0.001); GFR **138±18 vs 128±18** (p<0.001); MAP 88±7 vs 86±7 (p=0.02); PRA 2.10 vs 5.74; aldosterone 39 vs 134; ECFV 17.4±1.66 vs 16.5±1.54 L/1.73 m²; weight 80.6 vs 79.2 kg |
| 3 | **Toering 2018** `28592435` *AJP Renal* 314(5):F873-8 | 18 M + 18 F healthy normotensive | crossover, ECV by ¹²⁵I-iothalamate | 50 vs 200 mmol | Direction only in the record read: ECV and blood pressure higher in men on both intakes. **The only source found reporting this by sex.** |
| 4 | **Redgrave 1985** `2985655` *J Clin Invest* 75(4):1285-90 | **9 normotensive controls** (+10 modulator, 15 nonmodulator hypertensives) | 5 d | 200 meq/d | **Controls: RBF rose 79±28 mL/min/1.73 m²**; blood pressure **did not change** in controls or modulators |
| 5 | **Textor & Turner 1991** `2045180` *Hypertension* 17(6 Pt 2):982-8 | sons of **normotensive** parents (controls) vs sons of hypertensive parents | 1 wk per level | 10 vs 200 meq/d | Controls: **118±2/71±2 (low Na) vs 112±2/70±2 (high Na)** — pressure *lower* on high salt. Renal vascular resistance fell on low Na. |
| 6 | **Shoback 1983** `6309884` *JCEM* 57(4):764-70 | 11 Na-restricted + 9 Na-replete **normal** subjects | graded AngII infusion ± ACE inhibition, PAH clearance | restricted vs replete | Na restriction **reduces** renovascular responsiveness to infused AngII; ACE inhibition restores it. Sodium modulation of PAH response depends on circulating AngII. |
| 7 | **Conlin 1993** `7503952` *Hypertension* 22(6):832-8 | 15 normotensive | acute volume expansion (saline or dextran) out of low-salt balance | — | Renal perfusion and renal vascular responses to AngII became **identical to high-salt intake within 3–7 hours**. Modulation follows volume expansion per se. |
| 8 | **Barba 2000** `10826565` *J Hypertens* 18(5):615-21 | 7 healthy normotensive men | double-blind crossover, 7 d/level, L-NMMA | high vs low | Pressor response to NO synthase inhibition on **high salt only**; correlated with individual salt sensitivity (r=0.756) |
| 9 | **Visser 2009** `19282825` *Obesity* 17(9):1684-8 | **78** healthy men | 1 wk per level | 50 vs 200 mmol | ΔECFV **+1.2±1.8 L**; correlated with BMI (r=0.361) |

## 2. HUMAN, other populations — contrast only, not primary

| # | study | n | note |
|---|---|---|---|
| 10 | **Kirkendall 1976** `1249473` *J Lab Clin Med* 87(3):411-34 | 8 normotensive men | **≥4 weeks per level** — the longest protocol found. No BP change; *tendency* for weight, exchangeable Na and inulin space to rise; no change in total body water. Qualitative only. |
| 11 | **Taurio 2023** `36708156` *Blood Press* 32(1):2170869 | **510** normotensive + never-treated hypertensive | Cross-sectional, tertiles 94/148/218 mmol. ECW higher in top tertile; **no difference in aortic SBP/DBP, heart rate, cardiac output or systemic vascular resistance** |
| 12 | **Rorije 2018** `29206647` *Anesthesiology* 128(2):352-60 | 12 normotensive males | 8 d/level, <50 vs >200 mmol. Weight **+2.5 kg (95% CI 1.7–3.2)**; blood pressure unchanged |
| 13 | **Hollenberg & Williams 2006** `16672145` *Curr Hypertens Rep* 8(2):127-31 | review | Nonmodulation — failure of Na to modulate renal/adrenal AngII responsiveness — in ~40% of essential hypertension; corrected by ACE inhibition. **Disease phenotype; listed so it is not mistaken for the normal arm.** |

## 3. ANIMAL — backup only

| # | study | n | design | what it reports |
|---|---|---|---|---|
| 14 | **Hall, Guyton, Smith & Coleman 1980** `6254369` *Am J Physiol* 239(3):F271-80 | **6 control dogs** (+6 AngII-clamped, +6 ACE-inhibited) | chronic step increases, conscious | **5 → 500 meq/day** with AP rising **<7 mmHg**, GFR **+19%**, **filtration fraction DECREASED**, PRA decreased. AngII-clamped arm: AP **+42%**. |
| 15 | **Hall 1986** `3514280` *Fed Proc* 45(5):1431-7 | review | AngII **preferentially constricts efferent arterioles**; does **not** constrict afferent/preglomerular vessels at physiological activation. Intrarenal tubular effects **quantitatively more important than aldosterone-mediated** ones. |

---

## 4. TWO THINGS TO CHECK BEFORE ANY OF THIS IS USED

**(a) Filtration fraction moves in opposite directions in human and dog.**

| source | preparation | ΔFF on high salt |
|---|---|---|
| Krikken 2007, n=95 | healthy men, BMI<25 | **+1.1 ± 2.3 %** |
| van den Bosch 2021, n=70 | healthy men | 0.229 → **0.233** (computed from reported GFR/ERPF, not reported as FF) |
| Hall 1980, n=6 | conscious control dogs | **decreased** |

Two independent healthy-human cohorts give a small **rise**; the dog control arm gives a
**fall**. ~~Not resolved here.~~

**RESOLVED 2026-09-02 AS BRANCH F3, AND THE TABLE ABOVE OVERSTATED IT.** Neither human
entry is eligible under the pre-registration's §7 rule, which was fixed before any full
text was read: a source establishes a direction only with dispersion on the filtration
fraction, or on GFR and renal plasma flow in the same subjects.

- **Krikken is STRUCK** under branch K2 — see (b).
- **van den Bosch's 0.229 → 0.233 was computed by this repo** from two reported means with
  no dispersion on either. The pre-registration declared that class **descriptive only,
  in advance.** It establishes nothing.
- **Sweep 4 added the only human sources with their own significance tests**, and they
  disagree with each other by hormonal state. Pechère-Bertschi 2003 (n = 27 women on oral
  contraceptives) finds GFR and FF both rising, P < 0.05 — but that paper exists to show
  the oral-contraceptive renal salt response is *altered*. Pechère-Bertschi 2002 (n = 35
  women, no contraceptive) finds **no change in renal haemodynamics in the follicular
  phase**, with vasodilation in the luteal phase.

**The dog fall is therefore UNREPLICATED in humans, and no human direction is
established.** This model carries no filtration fraction and is not constrained by it
either way, so ADR 0015's efferent-arteriolar rows stand **untested** rather than
confirmed or contradicted.

**(b) One number in Krikken 2007 is ambiguous as printed.** The record reads *"FF was
significantly higher in BMI≥25 versus <25 kg/m², (22.6±2.9 versus 24.6±2.4%, P<0.05)"* —
the sentence says higher in the high-BMI group but lists the smaller value first. Directive
1.5 forbids resolving that by picking the dimensionally sensible reading.

**BRANCH K2 APPLIED 2026-09-02. THE SENTENCE IS STRUCK, NOT REINTERPRETED.** *Kidney
International* 2007 is subscription-only: no PubMed Central record, `isOpenAccess = N` and
`inPMC = N` on Europe PMC, ScienceDirect returns 403 on both article identifiers, and the
Groningen repository has no copy. **Krikken is excluded from the filtration-fraction
question entirely**, and that includes its ΔFF pair, whose group ordering is ambiguous in
exactly the same way.

**Recorded as an observation and NOT used as a resolution.** The same abstract reports
that during high salt, FF correlated **positively** with BMI (R = 0.28, P < 0.01), and
that BMI correlated positively with the sodium-induced change in GFR (R = 0.30) and FF
(R = 0.23). Read literally, those coefficients are inconsistent with every one of the
three value pairs in the order the sentence names its groups. That is a reason to think
the pairs are printed in reverse order throughout — **it is not a reading of the paper,
and it must not be entered as one.** Anyone who obtains the full text should record which
way it went.

## 5. WHAT IS STILL MISSING

- **Systemic vascular compliance and mean systemic filling pressure in HEALTHY humans.**
  Everything currently in this repo for those is post-cardiac-surgery ICU (Maas 2012) or
  compiled from critically ill patients (Magder 2025), or anaesthetised, ganglion-blocked,
  splenectomised animals (`venous_compliance_extract.py`). **No healthy-human source has
  been found for either.**
- **Resistance to venous return in healthy humans.** None found. The one study reporting it
  numerically (Guérin 2015 `26597901`) is a shock cohort with units ambiguous by 10³.
- ~~**Renal haemodynamics across salt intake in healthy WOMEN.** Only Toering 2018, and
  only as a direction.~~ **PARTLY CLOSED 2026-09-02 — and the answer is not the one the
  male limb predicts. See §6.** Krikken, van den Bosch, Visser, Barba, Textor, Kirkendall
  and Rorije are still all male.

---

## 6. ADDED BY SWEEP 4, THE PRE-REGISTERED FOURTH SWEEP

8 queries, **84 unique records screened**, aimed at the two gaps §5 declares. Two
genuinely independent groups, and directive 1.8 paid again.

| study | n | design | what it reports |
|---|---|---|---|
| **Roos 1985** `3907374` *Am J Physiol* 249(6 Pt 2):F941-7 | **8** healthy volunteers | equilibrated at 20 / 200 / 1128 ± 141 meq sodium; **inulin** clearance, lithium clearance, ECFV, PRA, aldosterone, noradrenaline | Inulin clearance **103 ± 9 → 129 ± 9 mL/min** and creatinine clearance 111 ± 7 → 136 ± 11 from lowest to highest intake. Proximal and distal fractional reabsorption both fall. **No consistent rise in blood pressure.** Utrecht (Koomans, Dorhout Mees) — **independent group, different tracer, different decade.** |
| **Pechère-Bertschi 2002** `11849382` *Kidney Int* 61(2):425-31 | **35** normotensive **women** | 40 vs 250 mmol/day, 7 d/level, randomised over two cycles; 17 follicular, 18 luteal | **Follicular phase: NO change in renal haemodynamics** on the salt increase. Luteal phase: significant renal vasodilation and distal salt escape (P<0.01 between phases). Geneva (Burnier, Brunner). |
| **Pechère-Bertschi 2003** `12969156` *Kidney Int* 64(4):1374-80 | **27** normotensive **women on oral contraceptives** | 40 vs 250 mmol/day, 7 d/level | Salt loading **raises GFR (P<0.05) with renal plasma flow unchanged, so filtration fraction rises (P<0.05)**. Blood pressure salt-resistant. The paper's own point is that contraceptives **alter** the renal salt response. |

**Roos 1985 corroborates DIRECTION and supplies no magnitude.** Its endpoints span 20 to
1128 meq/day — four times outside any diet and far outside this model's 103–205 — and the
200 meq intermediate values are described as intermediate but not printed. The
pre-registration clamps to the tested range, so it is **not pooled**.

**The women result is a declared conflict, not a gap.** The male limb says GFR rises on
high salt. The only clean healthy-women study says renal haemodynamics do not move in the
follicular phase. `RN.GFR.VOLUME_SENSITIVITY` is entered `both` on a male cohort because
ADR 0014 forbids a sexed pair on a direction alone — **but it may be a male number applied
to women, which is what `CV.HEMATOCRIT.NOMINAL` turned out to be.**

**Still missing:** GFR and extracellular volume in the *same* healthy women across salt
intake. Nothing found reports both.
