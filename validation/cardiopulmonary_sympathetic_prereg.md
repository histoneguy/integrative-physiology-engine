# Pre-registration — cardiopulmonary receptors and renal sympathetic traffic

**Written 2026-09-10, before any source is opened and before any search has been run for
these values.** Verify the ordering with

    git log --diff-filter=A -- validation/cardiopulmonary_sympathetic_prereg.md
    git log --diff-filter=A -- validation/cardiopulmonary_sympathetic_extract.py

Opened at the owner's instruction: build the two together rather than in isolation,
and examine what else belongs in the same pass regardless of subsystem.

---

## 0. WHY THESE ARE ONE PASS AND NOT TWO

**Sympathetic outflow is one node.** The arterial baroreceptors and the cardiopulmonary
receptors are its two afferents; the heart, the vessels and the kidney are its
effectors. Building renal sympathetic traffic driven by arterial baroreceptors alone
would drive an effector from half its inputs — **the exact error §3.31 records for
aldosterone**, which is why the macula densa arm and potassium were built together.

**And ADR 0012 built the hook on purpose.** `V_central` exists, in that record's own
words, so that a natriuretic term and the cardiopulmonary receptors have a variable with
a receptor behind it. It has been waiting.

---

## 1. THE STOP CONDITION, AND IT IS NOT THE ONE I EXPECTED

**A cardiopulmonary arm would be the FOURTH thing in this model that senses volume, and
the third that turns volume into sodium excretion.** Before anything is built:

| existing arm | sensed variable | effect |
|---|---|---|
| `Renal.anp_sig` (ADR 0010) | `V_blood` | natriuresis, lagged, gain **585** |
| `Renal.gfr_vol_mod` (§3.22) | `V_ecf` | raises filtration → natriuresis |
| `Cardiovascular.SV` (ADR 0012) | `V_central` | filling → stroke volume |
| **proposed cardiopulmonary** | **`V_central` = `f_c`·`V_blood`** | **?** |

**`V_central` IS `V_blood` TIMES A CONSTANT.** So a cardiopulmonary receptor keyed to
central volume senses **the same signal** as ADR 0010's path, which that record
describes in its own text as the atrial-stretch proxy and *"the volume-keyed arm the
model lacks"*.

**THEREFORE: A CARDIOPULMONARY ARM THAT PRODUCES NATRIURESIS IS NOT A NEW MECHANISM. IT
IS ADR 0010'S ARM UNDER A DIFFERENT NAME**, and adding it on top double-counts —
§5 item 22 in its purest form, a calibrated parameter re-estimated by giving its signal
a second path. `CV.ANP.NATRIURETIC_GAIN` is **the most influential parameter in the whole
model**: §3.40 measured its own interval swinging salt sensitivity by 45% of baseline,
nearly twice the next row. Double-counting it is the worst available error.

**What is genuinely NEW about cardiopulmonary receptors is everything that is NOT
natriuresis:**

- a **chronotropic** effect — unloading raises heart rate, loading lowers it;
- **non-osmotic vasopressin** release, which this model does not have at all
  (`Adh.jl` is purely osmotic);
- **renal sympathetic traffic to renin**, which ADR 0021 decision 7 says its own
  macula densa gain currently absorbs.

**So this pass may build the afferent and those three efferents, and MAY NOT add a third
natriuretic term.** That is decided here, before any source is opened, so it cannot be
decided by whichever answer makes a chart look better.

---

## 2. THE SECOND DOUBLE COUNT, WHICH THE REPOSITORY PREDICTED IN WRITING

**ADR 0021 decision 7:** *this gain absorbs the renal sympathetic traffic the model does
not have*, and *building renal sympathetic traffic must LOWER `RN.MD.RENIN_GAIN`*.

So `RN.MD.RENIN_GAIN` = 5.396 **must be re-solved** when a sympathetic renin arm lands,
or renin is driven twice by the same physiology.

**AND THE TEST THAT WOULD HAVE DISCIPLINED IT WAS DESTROYED ON 2026-09-09.** ADR 0021
predicted that building this arm *brings both Lobo endpoints back inside their bands*.
Those endpoints came inside on their own when the two baroreflex gains were corrected
(§3.39), so **the bound is gone and that prediction is no longer runnable.**
`OPEN-QUESTIONS` B9 closed as superseded for exactly this reason and said a green
harness was worth less than the red one it replaced. **This is the pass that pays for
it.**

**What is left to re-solve against** is van den Bosch's chronic salt–renin ratio of
2.73, which is the estimation set `g_md` was solved against in the first place. With two
arms and one datum they are **not separately identifiable**, so the sympathetic gain
must come from independent data (§3) and `g_md` is then the residual. **If the
sympathetic gain cannot be sourced independently, this pass does not build the renin
arm** — see branch S3.

---

## 3. THE QUANTITIES

| id | what | role |
|---|---|---|
| `CP.GAIN.HR` | heart-rate response per fractional change in central volume | **the new chronotropic afferent** |
| `CP.GAIN.RSNA` | renal sympathetic outflow per fractional change in central volume | drives renin; forces `g_md` down |
| `CP.GAIN.AVP` | vasopressin response per fractional change in central volume | non-osmotic release |
| `CP.THRESHOLD` | central volume deviation below which unloading engages | if the relation is not linear |
| — | the split of renin drive between macula densa and sympathetic traffic | decides whether the renin arm is buildable |

**`RN.MD.RENIN_GAIN` IS RE-ESTIMATED, NOT SOURCED**, and its estimation set is unchanged.
Whatever it becomes may never be reported as agreement.

---

## 4. ADMISSIBILITY, FIXED BEFORE SEARCHING

**Include:** healthy adults, supine or seated, awake, sea level, no cardioactive
medication. The manoeuvre must **separate cardiopulmonary from arterial** baroreceptor
unloading — low-level lower-body negative pressure (about −10 to −20 mmHg) and small
head-down tilt do this, because they reduce central filling with **arterial pressure
unchanged**. Record the pressure at which arterial baroreceptors begin to contribute.

**Exclude:** syncope and orthostatic-intolerance cohorts, heart failure, anaesthesia,
critical illness, exercise, and any protocol in which arterial pressure moves — a
manoeuvre that unloads both sets of receptors cannot separate them, which is the whole
point.

**DIRECTIVE 1.7 WILL BITE, FOR THE NINTH SUBSYSTEM, AND IT IS PREDICTED HERE.** Lower-body
negative pressure exists in the literature overwhelmingly as a **model of haemorrhage or
a syncope-provocation test** — the response is the instrument for studying tolerance, and
the cohorts are selected on fainting. **Prefer studies whose subject is the reflex arc
itself**, and where a graded stimulus traces a relationship rather than a single dose
being applied to see who falls over.

**AND OTHER WHOLE-BODY MODELS ARE NOT SOURCES.**

---

## 5. WHAT IS ALREADY KNOWN, DECLARED SO THE FREEDOM IS AUDITABLE

**Jensen 2013 Table 4** measures pulse rate rising about 3 beats/min on 23 mL/kg of
saline with systolic pressure flat. **ADR 0022's falsifiable test 5 currently asserts
that the model CANNOT reproduce this**, as an omission rather than a disappointment, and
names the cardiopulmonary receptors as the missing mechanism.

**That test is the single most valuable thing in this pass and it is already written
down.** It was recorded before this work was contemplated, it names the mechanism, and
it must **invert**: after this pass the model should reproduce a heart-rate rise on
volume loading, and the suite assertion flips from "must not" to "must". **A test that
was written as an absence and then satisfied by the mechanism it named is the strongest
evidence this repository can produce**, and it is worth more than any number sourced
here.

**Also known and declared:** `CV.ANP.NATRIURETIC_GAIN` = 585 carries 45% of the model's
salt-sensitivity sensitivity (§3.40), and `RN.MD.RENIN_GAIN` = 5.396 was solved to
absorb this very arm. Both numbers are in front of me and neither may be moved to make
a result look better.

---

## 6. DIRECTIVE 1.12 — THE ROUND NUMBERS, LISTED IN ADVANCE

Central blood volume **"about 25–30%"** of total. Cardiopulmonary receptors engaging at
**−10 mmHg** of lower-body negative pressure and arterial ones at **−20**. A **10%**
blood volume shift. Vasopressin responding to a **10%** fall in volume. **All are
teaching thresholds.** This repository's record on such numbers is four materially wrong
of six openable in the `VERIFY` class. None is enterable without a source.

---

## 7. THE FORM

**The afferent is one signal**, the fractional deviation of central volume from its
operating point, so the gains are dimensionless and inherit no body-size scaling — the
mistake §3.30 records for `G_anp`, avoided by construction rather than by care.

    cp_drive = (V_central - VC0) / VC0

**Efferents are separate and independently gated**, so each can be disabled and the
others still run. The chronotropic effect joins `hr_mod` **additively with the arterial
reflex**, because they are two afferents to one node and not two nodes.

**Sign, asserted and not assumed:** volume LOADING raises heart rate here. That is the
opposite of the arterial baroreflex, which slows the heart when pressure rises, and it
is why Jensen sees a rise. **Getting this backwards would produce a plausible curve** —
ADR 0009's addendum records the vasomotor arm shipping sign-inverted once already.

---

## 8. THE DECISION RULE

- **S1 — a graded cardiopulmonary chronotropic gain is sourced in healthy adults.**
  Build the afferent and the chronotropic arm. ADR 0022 test 5 **inverts**. This is the
  minimum successful outcome and it does not depend on the renin arm.
- **S2 — the non-osmotic vasopressin gain also sources.** Build it. `Adh.jl` gains a
  volume input alongside its osmotic one, and the model has its first non-osmotic AVP.
- **S3 — the sympathetic renin gain does NOT source independently.** **Do not build the
  renin arm.** With one datum and two arms it is unidentifiable, and estimating both
  against van den Bosch would make `g_md` and the new gain trade off freely — which is
  a fit with two knobs and no test. Record it, leave `g_md` untouched, and say the
  renin half is still absent.
- **S4 — it does source.** Re-solve `g_md` as the residual against the unchanged
  estimation set, report the new value as a **fit and never as agreement**, and state
  how much of the salt–renin response each arm now carries.
- **S5 — any source implies a natriuretic action.** Record it and **do not build it**.
  §1 forbids a third natriuretic arm; the finding is that the mechanism was already
  present under another name, and it belongs in ADR 0010's record rather than in a new
  term.
- **S6 — nothing admissible is found because the literature is syncope research.**
  Record as INDETERMINATE with the exact search terms, per §3.33, and build nothing.

---

## 9. WHAT THIS PASS MAY NOT DO

- **It may not add a third natriuretic term.** §1.
- **It may not move `CV.ANP.NATRIURETIC_GAIN`.** It is the most influential parameter in
  the model and re-estimating it inside a pass that adds a second path to its own signal
  is the definition of §5 item 22.
- **It may not re-estimate `RN.MD.RENIN_GAIN` except under S4**, and never to make an
  endpoint pass.
- It may not use Jensen's heart-rate data to SET any gain. That series is what ADR 0022
  test 5 judges, and spending it is §3.15's error committed deliberately.
- It may not enter a value from an abstract where the full text is obtainable, and must
  label the reading level of every source.
- **It may not report the salt–renin ratio as agreement.** Ever.

---

## 10. WHAT WOULD MAKE THIS PASS A FAILURE

**Building a cardiopulmonary arm that quietly duplicates ADR 0010's path.** Every gate
would stay green: the ledger parses, the relations carry citations, the closure
identities hold, and the suite passes — because both arms push sodium the same way and
the steady state can be restored by trading one gain against the other. **The only thing
that would notice is a transient**, and the acute limb that used to bound this model was
spent on 2026-09-09.

**The second failure is subtler: getting S1 and stopping.** The chronotropic arm alone
makes Jensen work and looks like success. But the renin half is what §7 has wanted since
it was written, and declaring victory on the easy afferent while the hard efferent stays
absent would leave the record claiming more than was built.
