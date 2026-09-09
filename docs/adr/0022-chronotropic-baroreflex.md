# ADR 0022: The chronotropic arm of the baroreflex

**Status:** Accepted
**Date:** 2026-09-08
**Evidence tier:** E1 for the structure, E2 for the gain — see the table
**Amends:** ADR 0009, which lumped the arms and said why

## Context

**ADR 0009 gave the baroreflex one effector and named the condition for a second.**
It lumped the vagal and sympathetic arms onto total peripheral resistance because
the model is cycle-averaged (ADR 0002) and heart rate was a parameter, so the vagal
arm had nothing to act on. Its words: *separating them buys nothing until heart rate
exists*, recorded as an explicit instruction not to re-separate them without a
protocol that needs it.

**ADR 0011 made cardiac output heart rate times stroke volume**, and said on the line
that did it that heart rate is a parameter *until a chronotropic baroreflex exists,
and a second effector is its own decision.* This is that decision.

Pre-registered in `validation/chronotropic_baroreflex_prereg.md`, committed before any
source was opened; the search is `validation/chronotropic_baroreflex_extract.py`.

## Evidence

| Claim | Tier | Source | Species |
|---|---|---|---|
| The baroreflex has a cardiac limb that changes heart rate, vagally mediated, 200–600 ms | E1 | La Rovere, *Ann Noninvasive Electrocardiol* 2008;13:191 | human |
| A rise in pressure slows the heart; the reflex is negative feedback | E1 | Dampney, *Front Physiol* 2017, PMC5559464 | mammal incl. human |
| Cardiac baroreflex sensitivity in healthy adults, 15.0 (men) / 10.2 (women) ms/mmHg | E2 | Laitinen, *J Appl Physiol* 1998;84(2):576–583, n = 117, phenylephrine bolus — **abstract only** | human |
| The cardiac and sympathetic arms are **independent** within individuals | E2 | Dutoit, *Hypertension* 2010;56(6):1118–23, n = 53, R² = 0.0003 | human |
| Pharmacological and spontaneous methods are **not interchangeable** | E2 | Bonyhay, *PLoS One* 2013;8(11):e79513, same 18 subjects both ways | human |
| The reflex resets, so every effector nulls at steady state | E1 | Dampney 2017; ADR 0009 | mammal |
| Effector time constant for the vagal limb | — | **ASSUMED** at 0.5 s in the coupling declaration; not a ledger row, because no lag is built | — |
| `BR.HR.MAX_FRACTION` saturation bound | — | **ASSUMED**, 0.5, the same convention `BR.TPR.MAX_FRACTION` carries | — |

## Decision

**One error signal, two efferent limbs.** `Baroreflex` gains `hr_mod`, a multiplicative
modifier on heart rate, driven by the **same** `err` the vasomotor arm uses:

    hr_drive ~ -hr_sat * tanh(G_hr * err / (hr_sat * MAP_ref))
    hr_mod   ~ 1 + hr_drive
    CO       ~ HR0 * hr_mod * 1440 * SV / 1000

**1. The arms ADD; they do not split a shared gain.** This was the pre-registration's
stop condition, checked before anything was built, because getting it wrong would have
doubled the reflex with every gate still green — §5 item 22, a parameter re-estimated
by being given a second path. Three independent lines resolved it:

- Yamasaki's open-loop gain, which `BR.OPEN_LOOP_GAIN` carries, decomposes as
  arterial pressure → **plasma noradrenaline** → arterial pressure. A cholinergic
  vagal limb cannot appear in a noradrenergic product **by construction**.
- The animal preparations behind its 1.0–3.5 range are vagotomised where it could be
  checked — two of six, at search level, and recorded as such rather than as sourced.
- Cardiac and sympathetic baroreflex sensitivity are **uncorrelated within healthy
  individuals**, R² = 0.0003 in 53 people. Two arms that vary independently are not
  one gain apportioned between effectors.

**The residual overlap is declared and is not zero.** "Sympathetic" includes cardiac
sympathetic chronotropy, and the phenylephrine ramp is predominantly but not
exclusively vagal, so a small part of this limb may already sit inside the 2.0.

**2. IT HAS A LAG, AND THE PRE-REGISTRATION SAID IT WOULD NOT.** §5 made the arm
**algebraic** by default on directive 1.10 grounds — a 200–600 ms effector is
quasi-static against a six-hour protocol — and put the burden on *adding* a lag.
**Building it refuted that, for a structural reason rather than a physiological one.**

An algebraic `hr_mod` closes an **instantaneous algebraic loop** through arterial
pressure:

    CO -> MAP -> err -> hr_mod -> CO

`structural_simplify` resolved that loop by promoting `Blood.CO` to a state. **So the
"stateless" arm cost a state anyway** — in another component, on a variable where it
meant nothing, and the diagnostic that says so is the state list, not a test.

**The vasomotor arm never had this problem because `BR.EFFECTOR.TAU` makes `tpr_mod` a
state, and a lag is exactly what breaks an algebraic loop.** ADR 0009 chose that lag for
its 2–3 s delay and got loop-breaking for free; nobody recorded that the second property
was load-bearing.

The state is therefore paid either way, and this is the honest place to put it: on a
variable with a physical meaning and a sourced time constant. **Ten states before,
eleven after, and the eleventh is `br.hr_mod`.** `BR.CARDIAC.TAU` = 0.4 s comes from La
Rovere's 200–600 ms — the same sentence `BR.EFFECTOR.TAU` is entered from and the same
one ADR 0009 cited when it lumped the arms.

**It is now the fastest thing in the model**, seven times faster than the vasomotor
effector, which is the physiology: vagal transmission is cholinergic and fast,
sympathetic vasomotor transmission noradrenergic and slow. A multirate partition may not
cut across it.

**3. Source the milliseconds, derive the gain.** `BR.CARDIAC.SENSITIVITY` holds what
is measured, ms/mmHg. `BR.CARDIAC.GAIN` is derived through the operating cardiac
interval and is what the component reads. Fifth dependency inversion after arterial
PCO2, the thyroid operating point, plasma bicarbonate and plasma potassium.

**4. Stroke volume keeps the UNMODULATED heart rate in its denominator.** Putting
`hr_mod` there too would make ventricular filling depend on the reflex — a
force-interval or filling-time coupling nothing here sources — and would silently
change what `CV.SV.NOMINAL` means.

**5. The spontaneous-sequence and spectral literature is excluded, on evidence.**
ADR 0002 states this model cannot represent beat-to-beat fluctuations, which is what
those methods are computed from. Bonyhay measured both ways in the same subjects: they
differ by 20.7% with a limit of agreement of 10.8 ms/mmHg and do not agree within
individuals. The pre-registration's branch C6 would have widened admissibility had
they agreed. It did not fire.

## Consequences

- **The neural component becomes sex-dependent for the first time**, and sexed twice
  over: the sensitivity is a male/female pair and it is converted through
  `CV.HR.NOMINAL`, which is a second one. `member_remake` carries the gain for that
  reason, written down when the parameter was created rather than after a test caught
  it.
- **20 → 21 couplings**, and the new edge is declared **separately** rather than folded
  into the existing baroreflex → cardiovascular edge, because the two arms differ in
  the one thing the graph exists to record: the time constant. Lumping a 0.4 s vagal
  limb into a 3 s sympathetic edge would hide the faster of the two from the partition
  rule that reads it.
- **AND THE GRAPH SILENTLY DROPPED THAT EDGE UNTIL THE COUNT CAUGHT IT.**
  `model_couplings()` deduplicated on `(from, to, kind)`, which is right for one edge
  declared from both ends and wrong for two genuinely different edges between the same
  pair. The second baroreflex → cardiovascular coupling was declared in the component,
  absent from the graph, and the count stayed 20 while the component declared 21.
  **That is the defect class this graph exists to catch, committed by the graph
  itself** — a declaration that looks present and is not, which is how
  `bodyfluids → endocrine` survived (§1.11). The key now includes `tau_seconds` and
  `gain_param`; two declarations that really are one edge still carry the same values
  and still collapse.
- **Every steady state is bit-identical** and that is a prediction, not a hope — see
  test 1.
- **`BR.OPEN_LOOP_GAIN` now carries a recorded defect it did not carry before.** Its
  2.0 is the mid-point of an animal range quoted in Yamasaki's *introduction*, while
  Yamasaki's own *result* is a human measurement of 5.62 supine with vagal effects
  blocked — which is exactly the quantity that row is supposed to hold. **Not changed
  here**: it moves every transient including the two Lobo endpoints B9 lives on, and
  two changes at once leaves neither testable.

## What this lumping disqualifies as evidence

**The cardiac limb is represented as vagal-only in everything but name.** The gain
comes from a phenylephrine ramp, which is predominantly a vagal measurement, and it is
applied as a single symmetric tanh. So this model **cannot be calibrated against** any
paradigm that separates vagal from cardiac-sympathetic chronotropy — atropine or
beta-blockade protocols, and the tachycardic versus bradycardic limbs of the modified
Oxford manoeuvre, which are known to differ. A protocol whose perturbed variable is
one arm of the cardiac limb no longer matches a model variable.

**And it says nothing about heart-rate control that is not baroreflex.** Atrial
stretch, the cardiopulmonary limb, respiratory sinus arrhythmia and central command
all move heart rate and none of them is here.

## Falsifiable test

Fixed in `chronotropic_baroreflex_prereg.md` §10 **before the numbers**, so this record
inherits them rather than inventing them afterwards.

1. **No steady state moves.** The reflex resets, so `err → 0` and `hr_mod → 1`, and
   every pinned resting value, the 400-day drift, chronic salt sensitivity and
   `dMAP/dV_ecf` are unchanged. **If any pinned steady-state number moves, either the
   reset path is broken or the arm has been wired into something that does not null.**
   This is ADR 0009's own test applied to the second effector.

   **This was written as BIT-identity and that was too strong.** The suite asserted
   `hr_mod == 1.0` and got 1.0000029. It is not noise: the salt step ends 30 days after
   an intake change, arterial pressure is still drifting on the renal–body-fluid
   timescale, and a setpoint that chases pressure with a 1-day reset lags a drifting
   pressure by roughly its time constant times the drift rate. **A resetting reflex is
   exactly null only at a true steady state**, and the end of a 30-day arm is not one.
   The bar is 1e-5, which still pins the arm to five decimals.
2. **The sign.** Raise pressure, heart rate must fall. Inverting the sign must make the
   model misbehave visibly — run it, do not trust the comment. ADR 0009's addendum is
   what happens otherwise.
3. **The arm is fast**, and faster than the vasomotor arm's 3 s.
4. **Cardiac output falls when heart rate falls**, stroke volume unchanged at fixed
   filling — the ADR 0011 identity holding through the new multiplier.
5. **THE ARM MUST NOT REPRODUCE JENSEN'S HEART-RATE RISE, AND IT DOES NOT.** Jensen
   2013 Table 4 measures pulse rate rising about 3 beats/min on 23 mL/kg of saline
   while systolic pressure stays flat. An arterial baroreflex chronotropic arm cannot
   produce a rise: at `err ≈ 0` it predicts no change, and had pressure risen it
   predicts a fall. **This is asserted as an omission rather than left as a
   disappointment** — the same inversion ADR 0020 used for the missing respiratory
   compensation. If a future change makes the model reproduce that rise through this
   arm, the arm has been given a job that belongs to the cardiopulmonary receptors.

**Test 1 is the cheap one; 2 through 5 are the ones that can fail.** A record whose
only test is test 1 has tested nothing — §5 item 3, and §3.32, which passed 676 tests
on a form that doubled an acute natriuresis.

## What is NOT decided

- **The cardiopulmonary (low-pressure) baroreceptors are still absent**, and test 5 is
  now the number that shows what that costs. ADR 0009 already named them a separate
  component; this record gives that absence an out-of-sample measurement.
- **No lag.** If a protocol ever needs the 200–600 ms rise, `BR.CARDIAC.TAU` becomes a
  ledger row and `hr_mod` becomes a state.
- **`BR.HR.MAX_FRACTION` is assumed** and inert at every steady state. It can only
  matter in a transient large enough to reach the bound, which no protocol this model
  runs comes close to. Source it before reporting any result that reaches it.
- **Age.** Baroreflex sensitivity falls steeply with age — Laitinen r = −0.65 over
  23–77 years — and this model has no age dimension, so the entered value is a
  cohort mean over that range.
- **Whether the sexes really differ.** Laitinen's pair is contradicted by Wada 2014
  (Valsalva, n = 166), which found no sex effect. The two use different methods,
  `pooling.md` bars pooling them, and the pre-registration preferred the ramp — so
  Laitinen governs and the disagreement is recorded rather than averaged away.
