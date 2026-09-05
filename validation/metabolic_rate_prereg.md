# Pre-registration — resting metabolic rate, and the CO2 production derived from it

**PARTIAL, AND THE PART THAT IS NOT PRE-REGISTERED IS NAMED FIRST.** The repository's
rule is that the pre-registration precedes the extraction. **It did not here.** McMurray
2014 was opened while investigating why the newly built Fick arm gave an oxygen
extraction ratio of 20% (§3.27), and its numbers were read before this file existed.

**What was already known when this was written**, stated exactly so the residual freedom
is auditable:

    McMurray RG, Soares J, Caspersen CJ, McCurdy T. Examining variations of resting
    metabolic rate of adults: a public health perspective. Med Sci Sports Exerc
    2014;46(7):1352-8. PMID 24300125, PMC4535334, read in full.
    197 studies, 397 publication estimates, inverse-variance weighted.

    overall                     0.863 kcal/kg/h   (95% CI 0.852-0.874)
    men,   all BMI  (n = 131)   0.892             (0.872-0.912)
    women, all BMI  (n = 220)   0.839             (0.825-0.853)
    men,   normal weight        0.960             (0.934-0.985)
    women, normal weight        0.926             (0.908-0.945)
    obese groups                0.721 - 0.791
    RMR declines with age and with BMI in both sexes.

**What was NOT known, and is what this file fixes in advance:** what any of those choices
does to the model. No value has been entered, no row changed, and the consequences for
ventilation, the water balance, oxygen consumption and the extraction ratio have not been
computed. **The decision rules below are therefore made blind to the outcome, which is
the property that matters.** Verify the ordering:

    git log --diff-filter=A -- validation/metabolic_rate_prereg.md
    git log --diff-filter=A -- validation/metabolic_rate_extract.py

---

## 1. WHY

`RESP.CO2.PRODUCTION` is `assumed` at **0.20 L/min**, a round teaching number, and its
own ledger note records a search for resting metabolic rate that returned prepubertal
children, chronic disease and exercise protocols. It is now load-bearing in **two**
subsystems: basal ventilation and the respiratory water flux are derived from it, and
since §3.27 so is whole-body oxygen consumption.

`RESP.EXCHANGE_RATIO` is `assumed` at **0.80**, also a round teaching number.

McMurray 2014 is admissible where the earlier search's hits were not: healthy adults, a
weighted meta-analysis, and **its stated purpose is to test the 1.0 kcal/kg/h MET
convention** — which is directive 1.12's exact subject rather than an incidental finding.

## 2. THE CONVERSION, FIXED BEFORE ANY VALUE IS ENTERED

Energy expenditure to oxygen consumption by **Weir's equation without urinary nitrogen**:

    EE (kcal/min) = 3.941 * VO2 (L/min) + 1.106 * VCO2 (L/min)

Weir JB de V. New methods for calculating metabolic rate with special reference to
protein metabolism. *J Physiol* 1949;109(1-2):1-9. With `VCO2 = R * VO2`:

    VO2 = EE / (3.941 + 1.106 * R)

**The exchange ratio barely matters here and that is why it is not blocking.** The
denominator runs 4.771 at R = 0.75 to 4.881 at R = 0.85 — **±1.1% across the whole
plausible resting range**, an order of magnitude smaller than the choice in §3. So
`RESP.EXCHANGE_RATIO` stays `assumed`, its weakness is inherited at 1%, and this
pre-registration does not attempt to source it.

## 3. THE STRATUM, CHOSEN NOW AND FOR A STATED REASON

McMurray reports RMR by sex, age group and BMI group, and the strata differ by up to 30%.
**Choosing after seeing what each does to the model would be fitting.**

**Decision: the NORMAL-WEIGHT stratum, averaged across the sexes.** The model's reference
individual is a healthy 70 kg adult; the all-BMI means pool in overweight and obese
subgroups whose RMR per kilogram is lower for reasons — fat mass is metabolically less
active — that the model does not represent, having no body composition. Averaging the
sexes unweighted is appropriate because the strata are near-equal in the population, and
because §4 decides not to sex the row.

**Recorded as the alternative, with its value, so the choice is visible:** the all-BMI
sexed means, 0.892 and 0.839, averaging 0.866. The two choices differ by about 8%.

## 4. THE ROW STAYS `both`, AND THE REASON IS THE WATER BALANCE

**A sexed pair IS supported by this source** and is deliberately not taken.
`RESP.CO2.PRODUCTION` drives basal ventilation, which drives the respiratory water flux,
whose residual is `BF.H2O.CUTANEOUS_LOSS` — derived so the two halves reproduce
`BF.H2O.INSENSIBLE_LOSS`, which is `assumed` at 0.8 L/day and unsexed. **Sexing the CO2
production would sex the water balance against an unsexed total**, which either invents a
sexed total or puts the sex difference entirely into the cutaneous residual. Neither is
sourced.

ADR 0014 is satisfied by recording the pair and the reason on the row, not by taking it.

## 5. DECISION RULES

- **M1 — the derived CO2 production leaves resting ventilation inside 4–8 L/min.**
  Accept, change the row from `assumed` to `derived`, and re-derive
  `RESP.VENTILATION.BASAL` and `BF.H2O.CUTANEOUS_LOSS` from it.
- **M2 — ventilation lands outside that.** **Report it, do not adjust the dead-space
  fraction to rescue it.** `RESP.DEADSPACE.FRACTION` is the obvious free parameter and
  is itself `assumed` at a round 0.30; moving it to make ventilation come out is the
  error `RN.PRESSURE_NATRIURESIS.SLOPE` records.
- **M3 — the oxygen extraction ratio moves further from measured mixed venous
  saturation.** **Report that too.** §3.27 already records the extraction ratio at 20%
  against a measured mixed venous saturation near 75%, which implies about 23%. If a
  better-sourced oxygen consumption widens that gap, the gap is evidence about cardiac
  output or about consumption, and it is not closed by choosing a stratum.
- **M4 — arterial PCO2 must not move.** It is a sourced INPUT under ADR 0017's
  amendment and basal ventilation is derived from it. If PaCO2 moves, the derivation has
  been done in the wrong direction.

## 6. WHAT THE ANSWER MAY NOT DO

- It may not change `RESP.EXCHANGE_RATIO`, `RESP.DEADSPACE.FRACTION`,
  `RESP.CO2.ARTERIAL_RESTING` or `BF.H2O.INSENSIBLE_LOSS`.
- It may not re-choose the stratum after seeing the model output.
- It may not present the resulting extraction ratio as agreement if it is not.
