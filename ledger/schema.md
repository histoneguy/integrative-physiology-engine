# Parameter Ledger Schema

Every quantitative value in the model has exactly one row in `parameters.csv`.
No value enters the codebase without a row. Assumed values are recorded, not hidden.

| Field | Description |
|---|---|
| `param_id` | Stable unique key, e.g. `CV.BLOODVOL.TOTAL`. Referenced from code. Never reused. |
| `name` | Human-readable name. |
| `symbol` | Symbol as used in our documentation. |
| `units` | SI preferred. Clinical units permitted where conventional (mmHg, mEq/L); state explicitly. |
| `value` | Nominal value. |
| `uncertainty_type` | `sd` \| `sem` \| `ci95` \| `range` \| `none` |
| `uncertainty_value` | Numeric, or a low-high pair for `range`/`ci95`. |
| `subsystem` | `cardiovascular`, `renal`, `respiratory`, `endocrine`, `thermal`, `metabolic`, `neural`, `body-fluids`. |
| `source_tier` | `A` \| `B` \| `C` - per `SOURCES.md`. |
| `citation` | Full citation. |
| `doi` | DOI or stable identifier. |
| `extraction_method` | See below. |
| `species` | `human` unless otherwise; state species and note scaling if not human. |
| `entered_by` | Contributor identifier. |
| `date_entered` | ISO 8601. |
| `notes` | Justification, caveats, reconciliation decisions. |

## `extraction_method` values

- **`reported`** - stated numerically in the source text or table.
- **`digitized`** - read off a published figure. Note the tool used and estimated read error.
- **`derived`** - computed from other reported values. Show the derivation in `notes`.
- **`assumed`** - no literature basis; set by us. **Requires written justification.**
- **`calibrated`** - a fitted value published by another modeling effort. A fact about what
  was published, not a measurement. Name the originating model in `notes`.

## Conventions

- Values reconciled to satisfy conservation constraints (flows summing to cardiac output,
  compartment volumes summing to total body water) keep their original citation, with the
  reconciliation recorded in `notes` and the residual redistribution stated.
- Where sources conflict, create one row per source and one `derived` row for the value used.
- `assumed` and `calibrated` rows are the model's soft underbelly. Review them as a set
  periodically; they are where unfalsifiable choices accumulate.
