# How the low-sensitivity parameters should vary, and what the ledger holds instead

**Written 2026-09-09 at the owner's instruction**, after `bench/uncertainty_sweep.jl`
showed that 24 of 30 rows with a stated interval move chronic salt sensitivity by
**0.000** across that interval. The question asked was: find the references, and say how
these should vary.

**Reading level is stated for every source. Nothing here is cited from a search summary.**

---

## 0. THE FINDING THAT MATTERS MORE THAN ANY INDIVIDUAL REFERENCE

**Almost every interval in this ledger is the wrong KIND of number for varying a
population**, and the sweep could not see that because it only asked how far the model
moves between two endpoints. Four different quantities are stored in one
`uncertainty_value` column:

| what is stored | what it means | usable for a population? |
|---|---|---|
| **`sd`** from a large cohort | between-subject spread | **yes — this is the one** |
| a **clinical reference interval** | where 95% of a lab's results fall, conventionally rounded | no — it is a convention, and wider than the real spread |
| a **confidence interval on a fitted value** | how well the AVERAGE is known | no — it shrinks with n and says nothing about people |
| a **choice between strata or formulas** | a modelling decision | no — not variation at all |

**A confidence interval is not a population.** `THY.TSH.FT4_SLOPE`'s 0.176–0.272 says
how well a meta-analytic slope is pinned; it does not say that people differ that much.
Sampling an ensemble from it would be wrong in both directions at once.

`pooling.md` already records that this file lacks columns it wants. **This is the
sharpest instance: one column carrying four incompatible meanings.**

---

## 1. THE ONE ROW WHERE THE LITERATURE GIVES A LARGE, MEASURED, HERITABLE SPREAD

### `ADH.OSM.SENSITIVITY` — currently **no dispersion at all**, and it should carry a 14-fold range

**Zerbe RL, Miller JZ, Robertson GL. The reproducibility and heritability of individual
differences in osmoregulatory function in normal human subjects.** *J Lab Clin Med*
1991;117(1):51–9. **PMID 1987308. ABSTRACT READ IN FULL** via the E-utilities API;
full text not opened.

| | value |
|---|---|
| subjects | 80 adults in the frequency distribution; 7 in repeat testing; 13 twin pairs (7 monozygotic, 6 dizygotic) |
| **vasopressin/osmolality slope, between subjects** | **0.12 to 1.66 pg/mL per mOsm/kg — a 13.8-fold range** |
| osmotic threshold, between subjects | 280 to 288 mOsm/kg |
| reproducibility on repeat testing | **slope r = 0.94**; threshold r = 0.61 |
| monozygotic twins | r = 0.95 for both threshold and sensitivity |
| dizygotic twins | r = 0.34 and 0.21 |

**This is the best population-variation datum in the whole ledger and the row carrying it
is blank.** The spread is large, it is *reproducible within a person* — so it is a real
individual characteristic and not measurement noise — and the twin discordance makes it
**heritable**. `HANDOVER.md` §7 already calls it "the most obvious population covariate
in the repo" and it has sat unused.

**THE UNITS DO NOT TRANSFER AND THE RATIO DOES.** Zerbe's slope is pg/mL per mOsm/kg of
plasma vasopressin, which this model does not carry — `ADH.OSM.SENSITIVITY` = 0.1084 is a
derived gain on a normalised antidiuretic activity. §3.26's rule applies: source the
**dimensionless** thing. What transfers is the *fold-range*, and a defensible ensemble
draw is log-uniform or log-normal over roughly ±1 order of magnitude about the entered
value, not a narrow band.

### `ADH.OSM.THRESHOLD` — already correct, and worth saying so

284 mOsm/kg, interval 280–288, cited to the same paper. **That interval IS Zerbe's
measured between-subject range**, so this row already holds the right kind of number from
the right study. It is the only row in this group of which that is true.

---

## 2. TWO ROWS CARRY A CLINICAL CONVENTION LABELLED AS A DISPERSION

Both cite, verbatim, *"Standard clinical reference interval."* That is directive 1.12's
named class — a round teaching figure, entered as though it were measured. This
repository has already found four of six such rows materially wrong.

### `BF.OSM.PLASMA_SETPOINT` = 287, interval 275–295

**Measured instead:** venous plasma osmolality **284.2 ± 3.5 mOsm/kg** in healthy young
adults under controlled euhydration meeting the dietary reference intake for water
(n = 42; 20 men, 22 women). Freezing-point depression.

> Cheuvront SN et al. *Biological variation of plasma osmolality obtained with capillary
> versus venous blood.* Clin Chem Lab Med. **PMID 25720122. ABSTRACT READ IN FULL.**

**The real between-subject SD is 3.5, so ±2 SD is roughly 277–291** — narrower than the
stored 275–295, and centred about 3 mOsm/kg lower. The conventional interval is both the
wrong kind of number and the wrong width.

### `BF.NA.PLASMA_SETPOINT` = 140, interval 135–145

Same problem, same citation text. Sodium is the most tightly regulated analyte in this
group and its true between-subject spread is far narrower than ±5 mEq/L. **Not sourced
here** — see §4.

---

## 3. ROWS THAT ALREADY HOLD A PROPER BETWEEN-SUBJECT SPREAD

No work needed. Recorded so nobody searches them again.

| row | dispersion | source |
|---|---|---|
| `AB.HCO3.PLASMA` | sd 2.24 | NHANES 2007–2012, n = 8809, extracted here |
| `K.PLASMA.REFERENCE` | sd 0.320 | NHANES 2007–2012, n = 8809, extracted here |
| `THY.FT4.EUTHYROID` | sd 1.767 | NHANES 2007–2012, n = 6814, extracted here |
| `BF.ICF.MASS_FRACTION` | sd 0.040 | Zhang N et al., PMC6751809 |
| `BF.ECF.MASS_FRACTION` | sd 0.023 | Zhang N et al., PMC6751809 |
| `CV.MAP.SETPOINT` | sd 8.0 | Gomez-Sanchez 2021, central pressure cohort |
| `BF.HEIGHT.REFERENCE` | sd 7.60 / 7.08 | NHANES, n = 9300 measured |
| `CV.SV.NOMINAL` | sd 20 / 14 | Petersen 2017, UK Biobank CMR, n = 800 |

---

## 4. WHAT IS STILL MISSING, AND THE SOURCE THAT WOULD SUPPLY MOST OF IT

**The European Biological Variation Study is the right instrument for the electrolytes**
and is named here rather than quoted, because its per-analyte figures are in a full text
this pass did not open.

> Aarsand AK, Díaz-Garzón J, Fernandez-Calle P, Guerra E, Locatelli M, Bartlett WA, et al.
> *The EuBIVAS: within- and between-subject biological variation data for electrolytes,
> lipids, urea, uric acid, total protein, total bilirubin, direct bilirubin, and glucose.*
> Clin Chem 2018;64(9):1380–93. **PMID 29941472. ABSTRACT READ; the electrolyte tables
> were NOT opened.**
>
> Design, from the abstract: 91 healthy individuals (38 men, 53 women), aged 21–69,
> sampled weekly for 10 consecutive weeks across 6 European laboratories, duplicate
> analysis, CV-ANOVA on trend-corrected data with confidence intervals.

**One paper would give a properly measured between-subject CV for plasma sodium,
potassium and bicarbonate at once**, in a design built for exactly this question —
repeated sampling of the same healthy people, which is what separates between-subject
spread from within-subject noise and from analytical error. Numbers for sodium,
potassium and bicarbonate circulate widely in secondary sources; **directive 1.5 forbids
entering them from a summary**, so they are not written here.

**Still with no between-subject source of any kind:** every derived and fitted row in the
low-sensitivity group — `RAAS.ALDO.K_GAIN`, `K.EXCRETION_EXPONENT`, `K.RENAL_FRACTION`,
`RN.ANP.TAU`, `THY.TSH.FT4_SLOPE`, `THY.TSH.INTERCEPT`, `THY.METABOLIC_GAIN`,
`THY.FT4.TAU`, `CV.VENOUS_RETURN.SENSITIVITY`, `RESP.CO2.PRODUCTION`. **These are gains
and time constants, not analytes**, and no clinical laboratory measures their spread
across people. For most, the honest entry is that the between-subject variation is
unknown rather than a number.

---

## 5. WHAT THIS CHANGES ABOUT THE SWEEP'S CONCLUSION

**It does not rescue the 24.** They still move chronic salt sensitivity by nothing across
the intervals they hold, and three of the four that matter are still where sourcing work
belongs.

**But it changes what a population run means.** The ensemble samples only body mass
(`OPEN-QUESTIONS` B14), and the reason it cannot yet sample anything else is visible
here: most rows have no between-subject number, and several have an interval that would
be actively misleading if drawn from. **Fixing that is not one search — it is deciding,
per row, which of the four meanings its interval carries**, which is a schema question
before it is a literature question.

**The one row worth acting on immediately is `ADH.OSM.SENSITIVITY`**, because the
variation is large, measured in 80 people, reproducible within a person, heritable, and
currently recorded as nothing at all.
