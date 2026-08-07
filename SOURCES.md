# Source Whitelist Policy

**Status:** Binding on all contributors. Effective from the first commit of this repository.
**Purpose:** Every quantitative and structural element of this model must trace to a permitted
source. This document defines what is permitted, what is excluded, and how each is recorded.

This project is an independent implementation in the Guyton–Coleman tradition of integrative
physiological modeling. It is built from the peer-reviewed literature. It is not a modification,
port, translation, or derivative of any existing model distribution.

---

## 1. Permitted sources

### Tier A — Primary
Preferred for all physiological parameters and relationships.

- Peer-reviewed primary research reporting original measurements in humans.
- Peer-reviewed primary research in animal models, **flagged as such** with species noted.
- Public reference datasets: ICRP Publication 89 (reference anatomical and physiological
  values), NHANES, WHO/CDC growth and anthropometric references.
- Standards documents from recognized bodies (IUPS, ISO, NIST) for units and constants.
- Public clinical trial data and published supplementary datasets.

### Tier B — Secondary, permitted with flag
Usable, but every value must be marked non-primary in the ledger, and the citation chain
should be traced to Tier A where feasible.

- Review articles and meta-analyses.
- Textbooks (e.g. Guyton & Hall, *Textbook of Medical Physiology*).
- Modeling papers reporting **fitted or calibrated** parameter values. These are facts about
  what an author published; they are not measurements. Record them with
  `extraction_method = calibrated` and note the originating model.

### Tier C — Architecture and rationale only
Published literature describing prior model designs. Read for design rationale, structural
reasoning, and historical context. Values taken from these papers fall under Tier B rules.

- Guyton AC, Coleman TG, Granger HJ. Circulation: overall regulation.
  *Annu Rev Physiol* 1972;34:13–46.
- Coleman TG, Randall JE. HUMAN: a comprehensive physiological model.
  *The Physiologist* 1983;26:15–21.
- Abram SR, Hodnett BL, Summers RL, Coleman TG, Hester RL. Quantitative circulatory
  physiology: an integrative mathematical model of human physiology for medical education.
  *Adv Physiol Educ* 2007;31:202–210.
- Hester RL, Brown AJ, Husband L, Iliescu R, Pruett D, Summers R, Coleman TG. HumMod: a
  modeling environment for the simulation of integrative human physiology.
  *Front Physiol* 2011;2:12. doi:10.3389/fphys.2011.00012
- Hester RL, Iliescu R, Summers R, Coleman TG. Systems biology and integrative
  physiological modelling. *J Physiol* 2011;589(5):1053–1060.

---

## 2. Excluded sources

No contributor may consult, open, decompile, inspect, or copy from:

- Any model **distribution artifact**: XML definition files, executables, Model Navigator or
  equivalent inspection tools, bundled documentation, installers, or parameter databases.
- Any decompiled, disassembled, or reverse-engineered artifact derived from the above.
- Any material received under NDA, click-through licence, evaluation agreement, or
  institutional IP agreement that restricts its use.
- Any leaked, unlicensed, or third-party-mirrored copy of a restricted distribution.

**Rationale.** Not because the underlying science is protected — it is not, and the design
rationale is published in Tier C above. The exclusion exists so that our provenance claim is
verifiable, and so that no contributor inadvertently reproduces protected *expression*:
file organization, naming schemes, code structure, or documentation prose. Transliterating a
definition file into another language is a translation, and translations are derivative works.

---

## 3. Prior-exposure declaration

Before a contributor's first commit, they must complete a prior-exposure declaration held privately by the project lead. Declarations are NOT stored in this repository - see `docs/exposure-declarations-README.md`.

Prior exposure does **not** automatically disqualify anyone. Copyright does not restrict what
is in your memory. **Contract may.** If a contributor has signed or clicked through terms
attached to a restricted distribution, or is bound by an institutional IP agreement that
touches this domain, that must be resolved with counsel before they contribute — it is an
obligation independent of copyright and it does not lapse because we now work from papers.

---

## 4. Validation policy

Validation targets are **experimental and clinical data**, never another model's outputs.

Where a prior model's published figure reports a comparison against experimental data, the
**experimental data** is the target. Digitize the data series, cite the original experimental
study wherever the figure identifies it, and record the digitization in the ledger.

Parameters are never tuned to reproduce another model's trajectories. Doing so is both a
contamination risk and bad science: it fits our model to another model's errors.

See `validation/targets.md` for the challenge-protocol canon.

---

## 5. Recording requirements

- Every parameter enters `ledger/parameters.csv`. No exceptions, including assumed values.
- Every structural relationship carries a source citation in the module docstring.
- Values with no literature basis are recorded with `extraction_method = assumed` and a
  written justification. Honest assumptions are acceptable; undocumented ones are not.
- Figures and diagrams in our documentation are drawn by us. Published figures are not
  reproduced, as figure copyright typically sits with the journal publisher.

---

## 6. Amendment

This policy is amended only by pull request with explicit reviewer sign-off. The git history
of this file is part of the project's provenance record and must not be rewritten.
