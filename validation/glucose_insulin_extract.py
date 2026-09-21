#!/usr/bin/env python3
"""
Fasting plasma glucose and fasting insulin in healthy adults, measured in NHANES.

    python validation/glucose_insulin_extract.py [--data DIR]

Pre-registered in validation/glucose_insulin_prereg.md, whose section 10 fixes the
population in COLUMNS - not in words - before this file existed.

    git log --diff-filter=A -- validation/glucose_insulin_prereg.md
    git log --diff-filter=A -- validation/glucose_insulin_extract.py

DATA. NHANES 2007-2008, 2009-2010 and 2011-2012, public microdata:
    https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/<2007|2009|2011>/DataFiles/<FILE>_<E|F|G>.xpt
files GLU, DEMO, RXQ_RX, DIQ. Downloaded on first run into validation/data/nhanes and
cached; delete that directory to re-fetch. THE FILES ARE NOT COMMITTED - they are public
and large, and .gitignore already excludes that directory for the thyroid pass.

WHY THESE THREE CYCLES. Insulin (LBXIN) leaves the GLU file after 2011-2012. Stated in
prereg section 10.1 so the choice is not mistaken for cherry-picking.

NO SURVEY PACKAGE IS USED AND THE CONSEQUENCE IS STATED, copied deliberately from
nhanes_hpt_extract.py rather than re-derived. Point estimates are weighted with
WTSAF2YR/3, the standard NHANES procedure for pooling three cycles. Standard errors are
computed WITHOUT the design (strata and PSU), so they are independent-sampling errors and
are too small - typically by a design-effect factor of 1.5 to 2.5. Every interval printed
below is therefore OPTIMISTIC and no conclusion here rests on one being narrow.

WHAT THIS MAY NOT BE ASKED FOR - prereg section 10.4. Fasting glucose and fasting insulin
are ONE equation. A regression of one on the other across this cohort is NOT a second
measurement and may not set insulin sensitivity. NHANES cannot discharge the
identifiability problem in prereg section 4 and is not being asked to.
"""
from __future__ import annotations

import argparse
import sys
import urllib.request
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DATA = ROOT / "validation" / "data" / "nhanes"
BASE = "https://wwwn.cdc.gov/Nchs/Data/Nhanes/Public/{year}/DataFiles/{file}_{s}.xpt"
CYCLES = [("2007", "E"), ("2009", "F"), ("2011", "G")]
FILES = ["GLU", "DEMO", "RXQ_RX", "DIQ"]

# Prereg section 10.2, fixed before the data were touched.
GLUCOSE_DRUGS = (
    "INSULIN", "METFORMIN", "GLIPIZIDE", "GLYBURIDE", "GLIMEPIRIDE",
    "PIOGLITAZONE", "ROSIGLITAZONE", "SITAGLIPTIN", "SAXAGLIPTIN",
    "LINAGLIPTIN", "EXENATIDE", "LIRAGLUTIDE", "ACARBOSE", "NATEGLINIDE",
    "REPAGLINIDE", "CHLORPROPAMIDE", "TOLBUTAMIDE", "TOLAZAMIDE",
)
MIN_AGE = 20
MIN_FAST_HOURS = 8.0
DIABETES_GLUCOSE = 126.0        # mg/dL - AN EXCLUSION, NEVER A MODEL VALUE


def fetch(data_dir: Path, file: str, year: str, suffix: str) -> pd.DataFrame:
    path = data_dir / f"{file}_{suffix}.xpt"
    if not path.exists():
        url = BASE.format(year=year, file=file, s=suffix)
        print(f"  downloading {url}", file=sys.stderr)
        data_dir.mkdir(parents=True, exist_ok=True)
        try:
            with urllib.request.urlopen(url, timeout=120) as r:
                path.write_bytes(r.read())
        except Exception as exc:                       # noqa: BLE001
            print(f"  FAILED {file}_{suffix}: {exc}", file=sys.stderr)
            return pd.DataFrame()
    try:
        return pd.read_sas(path, format="xport")
    except Exception as exc:                           # noqa: BLE001
        print(f"  UNREADABLE {path.name}: {exc}", file=sys.stderr)
        return pd.DataFrame()


def weighted_quantile(values: np.ndarray, weights: np.ndarray, q: float) -> float:
    """Weighted quantile. Sorts, accumulates weight, interpolates at q."""
    order = np.argsort(values)
    v, w = values[order], weights[order]
    cw = np.cumsum(w) - 0.5 * w
    cw /= np.sum(w)
    return float(np.interp(q, cw, v))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--data", type=Path, default=DEFAULT_DATA)
    args = ap.parse_args()

    frames = {f: [] for f in FILES}
    for year, suffix in CYCLES:
        for f in FILES:
            df = fetch(args.data, f, year, suffix)
            if not df.empty:
                frames[f].append(df)

    missing = [f for f in FILES if not frames[f]]
    if missing:
        print(f"\nBRANCH N2: files unavailable {missing}. "
              "Prereg section 10.5 - record it, do NOT substitute a textbook value.")
        return 2

    glu = pd.concat(frames["GLU"], ignore_index=True)
    demo = pd.concat(frames["DEMO"], ignore_index=True)
    rx = pd.concat(frames["RXQ_RX"], ignore_index=True)
    diq = pd.concat(frames["DIQ"], ignore_index=True)

    need = {"LBXGLU", "LBXIN", "WTSAF2YR"}
    if not need.issubset(glu.columns):
        print(f"\nBRANCH N2: GLU is missing {sorted(need - set(glu.columns))}. "
              "Prereg section 10.5.")
        return 2

    df = glu.merge(demo, on="SEQN", how="inner").merge(diq, on="SEQN", how="left")

    steps = [("merged GLU + DEMO + DIQ", len(df))]

    def keep(mask, label):
        nonlocal df
        df = df[mask].copy()
        steps.append((label, len(df)))

    keep(df["RIDAGEYR"] >= MIN_AGE, f"age >= {MIN_AGE}")
    keep(df["LBXGLU"].notna() & df["LBXIN"].notna(), "glucose and insulin both present")
    keep(df["WTSAF2YR"].notna() & (df["WTSAF2YR"] > 0), "in the fasting subsample")
    if "PHAFSTHR" in df.columns:
        keep(df["PHAFSTHR"].notna() & (df["PHAFSTHR"] >= MIN_FAST_HOURS),
             f"fasted >= {MIN_FAST_HOURS:.0f} h")
    else:
        steps.append(("PHAFSTHR ABSENT - fasting time NOT verified", len(df)))
    if "DIQ010" in df.columns:
        keep(df["DIQ010"] != 1, "no diagnosed diabetes")
    if "DIQ160" in df.columns:
        keep(df["DIQ160"] != 1, "not told prediabetic")
    if "RIDEXPRG" in df.columns:
        keep(df["RIDEXPRG"] != 1, "not pregnant")

    if "RXDDRUG" in rx.columns:
        name = rx["RXDDRUG"].astype(str).str.upper()
        hit = np.zeros(len(rx), dtype=bool)
        for d in GLUCOSE_DRUGS:
            hit |= name.str.contains(d, na=False)
        treated = set(rx.loc[hit, "SEQN"])
        keep(~df["SEQN"].isin(treated), "no glucose-lowering drug")

    n_hi = int((df["LBXGLU"] >= DIABETES_GLUCOSE).sum())
    keep(df["LBXGLU"] < DIABETES_GLUCOSE,
         f"glucose < {DIABETES_GLUCOSE:.0f} mg/dL (excluded {n_hi})")

    print("\nEXCLUSIONS, in the order prereg section 10.2 fixes them")
    print("-" * 66)
    for label, n in steps:
        print(f"  {label:<52} {n:>7,}")

    if len(df) < 500:
        print("\nBRANCH N2: too few subjects survive to report. Prereg section 10.5.")
        return 2

    w = df["WTSAF2YR"].to_numpy() / len(CYCLES)

    print("\nWEIGHTED DISTRIBUTIONS, n = {:,}".format(len(df)))
    print("-" * 66)
    out = {}
    for col, label, unit, si, si_unit in (
        ("LBXGLU", "fasting plasma glucose", "mg/dL", 0.05551, "mmol/L"),
        ("LBXIN", "fasting insulin", "uU/mL", 6.945, "pmol/L"),
    ):
        v = df[col].to_numpy(dtype=float)
        med = weighted_quantile(v, w, 0.50)
        q1 = weighted_quantile(v, w, 0.25)
        q3 = weighted_quantile(v, w, 0.75)
        mean = float(np.average(v, weights=w))
        out[col] = (med, q1, q3)
        print(f"  {label}")
        print(f"      median {med:8.2f} {unit}   IQR {q1:.2f} - {q3:.2f}")
        print(f"      median {med*si:8.3f} {si_unit}   IQR {q1*si:.3f} - {q3*si:.3f}")
        print(f"      weighted mean {mean:.2f} {unit}  "
              f"({mean*si:.3f} {si_unit})   [mean is NOT what is entered]")

    print("\nWHAT IS ENTERED, prereg section 10.4")
    print("-" * 66)
    print("  THE MEDIAN, not the mean. Fasting insulin is right-skewed and a mean")
    print("  would sit above the typical person; glucose's median is reported with")
    print("  it so both rows come from the same statistic.")
    print("  Dispersion is the IQR. Standard errors are NOT reported because they")
    print("  would be design-naive and optimistic - see the module docstring.")
    print()
    print("  AND NO RELATIONSHIP BETWEEN THE TWO IS COMPUTED. Prereg section 10.4:")
    print("  fasting glucose and fasting insulin are ONE equation. Insulin")
    print("  sensitivity still needs a PERTURBATION and NHANES cannot supply it.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
