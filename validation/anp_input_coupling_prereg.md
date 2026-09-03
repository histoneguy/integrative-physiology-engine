# Pre-registration: the ANP input coupling, so the volume-keyed natriuretic term can be turned on

**Date:** 2026-09-02. ADR 0010's standing blocker, and HANDOVER §4 item 0.

**Declared prior exposure, and it is real.** Two papers already opened this session carry
the quantities this needs: Lobo 2001 (PMID 11473492) and Jensen 2013 (PMID 24067081), both
read for `validation/challenges.jl`. Their abstracts are known to me. **No study has been
opened for the purpose below, no third source has been screened, and no value has been
computed.** §5 fixes every rule so that it does not depend on what those two say.

---

## 1. WHAT ADR 0010 ACTUALLY NEEDS, AND IT IS NOT PLASMA ANP

That record was revised on 2026-08-22 to drop the plasma ANP state, because the
natriuretic effect of a given ANP concentration depends on distal sodium delivery, which
this model does not carry. **The component is a lumped volume-keyed natriuretic term with
ANP as its named evidence base, not as a state.** So the quantity to source is not
"ANP per litre" and not "natriuresis per pg/mL". It is the composite:

    CV.ANP.NATRIURETIC_GAIN  =  d(sodium excretion) / d(blood volume)     (mEq/day)/L

**The sensed variable is BLOOD volume, not ECF volume.** Atrial stretch is intravascular.
ADR 0010 proposed `V_blood` and that stands. The diagnostic term added on 2026-09-02 was
keyed to `V_ecf` for convenience and **must be re-keyed to `V_blood` before anything is
entered** — they differ by the factor `dV_blood/dV_ecf = f_pv = 0.211`, so a value entered
against the wrong one is wrong by 4.7×.

**ADR 0010's blocker-4 wording is stale and this document does not inherit it.** It says
"IPE has no central compartment". `V_central` has existed since ADR 0012. It is
`f_c·V_blood` at stage 1, so it carries no information `V_blood` does not, and the
immersion paradigm stays closed — **but for a different reason than the record gives**,
and the record should be corrected rather than quoted.

---

## 2. TWO INDEPENDENT ROUTES, AND BOTH ARE REQUIRED

The point of using two is that they fail differently. **Neither is allowed to be dropped
after the fact.**

**Route A — CHRONIC, from steady-state sodium balance.** At steady state excretion equals
intake, so across two chronic intake levels

    Δintake  =  G_pn·ΔMAP  +  G_anp·ΔV_blood

Every term on the right is available from human data already extracted in this repo:
ΔMAP per 100 mmol/day from the meta-analytic pressure limb, ΔV_ecf per 100 mmol/day from
`ecf_salt_response_extract.py`, converted by `f_pv`. `G_pn` is taken at the **measured
animal value 5.43** (Mizelle 1993), not the calibrated 20.0 — using the calibrated value
would make this circular, because 20.0 is exactly the number ADR 0010 says is inflated by
the missing path.

**Route B — ACUTE, from isotonic volume expansion.** Extra sodium excreted per litre of
measured intravascular expansion, over a window short enough that arterial pressure has
barely moved, with the residual pressure contribution `G_pn·ΔMAP` subtracted.

**Route B needs the intravascular share of an infused isotonic load, measured rather than
assumed.** A haematocrit fall gives it directly with red cell mass held fixed, which is
the correction already made to `Cardiovascular.jl` on 2026-09-02 (§3.8).

---

## 3. THE AGREEMENT TEST, FIXED BEFORE EXTRACTION

**The two routes must agree within a factor of 2.** They use different protocols,
different timescales and different measurements, and a chronic steady-state gain and an
acute transient gain are not guaranteed to be the same number even in a correct model.

**Why a factor of 2.** It is the same threshold `ecf_salt_response_prereg.md` fixed for
its own ratio test, chosen there before anyone knew which way it cut, and it is reused
verbatim rather than re-decided. **No new threshold is invented here.**

- **A1 — routes agree within 2×.** Pool them, enter the value, **turn the term on.**
- **A2 — routes disagree by more than 2×.** **The term is NOT turned on.** A lumped
  algebraic gain cannot be both, and the disagreement is evidence that the real path is
  lagged or saturating — which is what §3.16 already suspected from the model side.
  Record both numbers and the form question. **This is the branch that must not be
  avoided by preferring whichever route lands closer to the salt-sensitivity target.**

---

## 4. WHAT MUST NOT BE DONE, STATED BEFORE THE NUMBERS

**The gain must NOT be fitted to the chronic salt-sensitivity discrepancy.** That is the
circularity §3.3 records having already happened to `G_pn`, and §3.16 measured its shape:
the model's chronic window wants a gain roughly twice what its acute datum wants, and the
difference is `G_vr`, not this parameter. **If the sourced value leaves the model outside
the human salt window, that is the correct outcome and it is reported, not tuned.**

**`G_pn` is not changed in this pass.** ADR 0016 sequences it last and ADR 0010 says
re-estimating it is the consequence of this work rather than part of it.

---

## 5. INCLUSION, FIXED BEFORE THE SEARCH

**Include** a study only if it reports, in healthy normotensive adults: a quantified
isotonic or dietary sodium/volume change; sodium excretion over a stated window; and
**arterial pressure over the same window**, because the pressure contribution has to be
subtracted rather than assumed zero.

**Exclude** hypertensive cohorts, heart failure, renal disease, anaesthesia and intensive
care — §5 item 14, a model whose structure comes from pathological preparations becomes a
pathological model. **Exclude head-out immersion and head-down tilt**: they redistribute
volume centrally at near-constant total volume, and Norsk 1986 already falsified total
volume as the driver in that paradigm. That exclusion is ADR 0010's third addendum and is
reused, not re-argued.

**A sweep is required before pooling**, per directive 1.8, aimed at acute isotonic
expansion in healthy humans. Two papers already in hand do not constitute a search.

---

## 6. POOLING

`pooling.md` order unchanged. Pool **within a route**, never across A and B — they are
different measurement paradigms and §3 tests them against each other rather than merging
them. Record `n_studies` honestly. `range-midpoint` prohibited.

---

## 7. WHAT WOULD FALSIFY THE APPROACH RATHER THAN THE VALUE

- **If arterial pressure moves materially in the acute studies**, the pressure and volume
  contributions are not separable in that window and Route B is unavailable.
- **If the intravascular share of an isotonic load cannot be measured** in any included
  study, Route B rests on an assumed distribution volume and must say so.
- **If turning the term on fails ADR 0010's own falsifiable test 1** — clamp the pressure
  term and step sodium intake; excretion must still rise and the loop must still close —
  then the term is not carrying volume-keyed natriuresis whatever its gain says, and the
  component is wrong rather than mis-parameterised.

---

## 8. OUT OF SCOPE

- **`G_pn`, `G_vr`, ADR 0013, ADR 0015 and ADR 0016's ordering.**
- **An explicit plasma ANP state**, dropped by ADR 0010 itself on 2026-08-22.
- **Posture, immersion and the central/peripheral split beyond stage 1.**
- **Mars500**, which §3.16 showed cannot identify this gain at all: the pressure and
  volume paths are indistinguishable at steady state, so no sodium-balance study
  separates them. That result is why Route B exists.
