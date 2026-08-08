# Validation Targets

**Policy:** targets are experimental and clinical data. Never another model's outputs.
See `SOURCES.md` section 4.

Where a prior model's published figure shows a comparison against experimental data, the
experimental series is the target. Cite the original experimental study, not the figure that
reproduced it, wherever the figure identifies its source.

## Why this matters more here than usual

This project's primary goal is execution speed. The intuitive equivalence check for a faster
reimplementation - "does it produce the same numbers as the original?" - is unavailable to us,
and would be the wrong criterion regardless. Replacing fixed-step explicit integration with a
modern stiff solver is expected to be one of the largest single sources of speedup, and it
will change trajectories because it is *more* accurate, not less. Matching a less accurate
reference would mean reproducing its integration error.

So equivalence is defined against data, plus an explicit numerical spec (below).

## Numerical equivalence specification

Declare and enforce, per subsystem:

- **Steady-state tolerance.** Converged values must fall within the stated tolerance of the
  literature reference range for a nominal adult.
- **Conservation invariants.** Mass, volume, and solute balance must hold to a stated
  numerical tolerance at every timestep. These are hard assertions in the test suite.
- **Dynamic response envelopes.** For each challenge protocol, the trajectory must fall
  inside the published experimental spread (mean +/- SD, or reported CI).
- **Solver-independence.** Results must agree across at least two independent integrators to
  a stated tolerance. This substitutes for the missing external reference and is a stronger
  check than matching any single implementation.

## Challenge protocol canon

These are integrated perturbations - the only data class that constrains *coupling gains*
between subsystems. Subsystem literature constrains subsystem parameters; only these
constrain the interactions that make the model integrative.

Populate each with specific citations before implementation of the relevant subsystem.

| Protocol | Primarily constrains | Status |
|---|---|---|
| Graded hemorrhage / controlled blood loss | Baroreflex gain, capacitance recruitment, fluid shift | TODO |
| Lower-body negative pressure (graded) | Cardiopulmonary and arterial baroreflex, orthostatic tolerance | TODO |
| Head-up tilt / orthostasis | Autonomic control, venous pooling | TODO |
| High- and low-sodium balance studies | Renal-body fluid feedback, RAAS, pressure natriuresis | TODO |
| Acute and chronic volume loading | Renal excretory function, ANP, capacitance | TODO |
| Water immersion | Central volume redistribution, renal response | TODO |
| Graded exercise (submaximal to maximal) | Cardiac output reserve, muscle flow, metabolic coupling, thermal load | TODO |
| Passive heat stress | Thermoregulatory flow redistribution, sweating, plasma volume | TODO |
| Acute hypoxia and altitude acclimatization | Chemoreflex, ventilatory control, erythropoietic response | TODO |
| Hypercapnic rebreathing | Ventilatory control loop gain | TODO |
| Water deprivation / fluid restriction | Osmoregulation, ADH axis | TODO |

## Reference anatomy and physiology

Nominal adult structural parameters from ICRP Publication 89 and equivalent public reference
datasets. Recorded in the ledger as Tier A.

## Digitization protocol

When extracting a data series from a published figure:

1. Record the tool used and version.
2. Record estimated read error in the ledger `notes`.
3. Store the extracted series under `validation/data/` with a manifest naming the source.
4. Cite the study that generated the data, not the review or model paper that reprinted it.
5. Do not commit the source figure image.

## Averaging of reference data

This model is cycle-averaged (ADR 0002). Reference data must be averaged to a declared
window before comparison. See `validation/averaging.md` - binding, and to be settled
before any dataset is digitised.

Endpoints that are within-cycle or spectral quantities (HRV, RSA, Mayer waves,
beat-to-beat variability) are **out of scope** and must not be listed above as
achievable targets.

---

## Primary target: Mars500 ultra-long-term sodium balance

**Rakova N et al. Long-term space flight simulation reveals infradian rhythmicity in
human Na+ balance. Cell Metab 2013;17(1):125-131. doi:10.1016/j.cmet.2012.11.013**

Companion: ultra-long-term salt balance analysis, PMC4919532.

The best available human sodium balance dataset, and the anchor for the body-fluid
subsystem.

| Property | Value |
|---|---|
| Design | Enclosed habitat, salt intake the only modified variable |
| Levels | 12, 9, 6 g/day NaCl (Mars105); back to 12 g/day (Mars520) |
| Duration per level | 30-60 days |
| Subjects | 12 men (6 x Mars105 105 d; 6 x Mars520 first 205 d) |
| Sampling | Daily 24-h urine, all collected |
| Quality | ~95% recovery of dietary electrolytes |

### Why it anchors this subsystem

Long enough to see the slow arm of renal-body fluid feedback equilibrate; controlled
enough that intake is a known input rather than an estimate; and it directly tests the
structural question in ADR 0004 - whether total-body Na+ tracks intake, and whether
Na+ and extracellular water are coupled.

### Required comparisons

1. **Step response.** Cumulative Na+ balance following each intake step. The classical
   two-compartment model (`storage = false`) is expected to FAIL here. Run it anyway
   and report the failure - it is the evidence for ADR 0004.
2. **Steady-state excretion.** Daily UNaV against intake at each level.
3. **Rhythmicity.** The 7-day and monthly cycles at constant intake. A first-order
   storage lag CANNOT produce these. If the model reproduces steps but not rhythms,
   that is a structural finding to report, not a fitting failure to tune away.

### Extraction status

**NOT YET DIGITISED.** Series must be extracted from published figures per
`validation/averaging.md` and recorded in `validation/data/manifest.csv`. Sampling is
daily, so the cycle-averaging window question does not arise for this dataset - note
that explicitly in the manifest.
