# Reference Data Averaging Policy

**Binding. Fix before digitising any dataset.** See ADR 0002.

## The problem

This model is cycle-averaged. Several canon protocols (LBNP, head-up tilt, graded
exercise) report beat-to-beat or breath-by-breath data. Comparing a cycle-averaged
model against beat-to-beat measurements is not a valid comparison.

## The rule

Apply a declared averaging window to the **reference data** before comparison.

- **Default window: 10 s centred moving average.**
- The window is stated per dataset in `validation/data/manifest.csv`.
- Any ledger parameter derived from a dataset records the window in `notes`.
- The window is fixed once and applied uniformly. It is NOT chosen per figure.

## Why uniformity matters more than the specific value

A per-figure choice of averaging window produces comparisons that are individually
defensible and collectively inconsistent, and the inconsistency is nearly undetectable
downstream. Any reasonable fixed window is better than a well-chosen variable one.

If a dataset genuinely requires a different window, record the deviation and the
reason in the manifest. Deviations should be rare and visible.

## Out of scope

Protocols whose primary endpoint is a within-cycle or spectral quantity cannot be
validated against this model and must not appear in `targets.md` as achievable:

- Heart rate variability (time-domain or spectral)
- Respiratory sinus arrhythmia
- Mayer wave characterisation
- Beat-to-beat or breath-to-breath variability measures

Protocols in the canon that report these as *secondary* endpoints remain usable for
their mean-value endpoints.

## Manifest fields

    dataset_id, source_citation, doi, protocol, raw_resolution,
    averaging_window_s, digitisation_tool, read_error_estimate, notes
