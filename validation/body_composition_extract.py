#!/usr/bin/env python3
"""
Body composition: fat mass and fat-free mass from NHANES DXA.

    python validation/body_composition_extract.py

Pre-registered in validation/body_composition_prereg.md, written before any
number was computed, with the level distinction and all four branches fixed.

    git log --diff-filter=A -- validation/body_composition_prereg.md
    git log --diff-filter=A -- validation/body_composition_extract.py

WHY EXTRACTED AND NOT READ OFF KELLY 2009 (PMID 19753111, PLoS One, open
access). Kelly is the canonical reference-value paper for exactly this dataset,
and its values are age-normalised CURVES IN FIGURES. Branches N3 and S3 of two
earlier pre-registrations already fixed that figures are not digitised here, so
extracting the underlying file is strictly better than reading his plot.

THE CYCLE WINDOW DIFFERS FROM THE REST OF THIS LEDGER AND THAT IS NOT A CHOICE.
NHANES whole-body DXA ran 1999-2006 and resumed in 2011; it was NOT collected in
2007-2010. The glucose, insulin and body-mass rows use 2007-2012, so the only
overlapping cycle is G (2011-2012). Cycles H, I and J are added for n, and the
cohort difference is recorded on the row rather than hidden.

LEVEL II, MOLECULAR. DXA measures fat and fat-free soft tissue plus bone
mineral. It does NOT measure skeletal muscle, which is level IV and comes from
Janssen 2000 by MRI. The five-level model (Wang 1992, PMID 1609756) is why those
are separate rows: DXA lean mass includes viscera, skin and body water and
exceeds skeletal muscle by roughly twofold.
"""
from __future__ import annotations

import sys
import urllib.request
from pathlib import Path

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent))
from nhanes_hpt_extract import wmean, DEFAULT_DATA, BASE  # noqa: E402

# DXA cycles. G overlaps this ledger's 2007-2012 window; H-J extend n.
CYCLES = [("2011", "G"), ("2013", "H"), ("2015", "I"), ("2017", "J")]

# DXX variables, named so a rename upstream is a visible failure rather than a
# silent NaN: total fat mass (g), total lean mass excluding bone mineral (g),
# total percent fat, total bone mineral content (g).
DXA_VARS = ("DXDTOFAT", "DXDTOLE", "DXDTOPF", "DXDTOBMC")


def rule(c="="):
    print(c * 80)


def grab(data_dir: Path, file: str, keep: tuple[str, ...]) -> pd.DataFrame:
    """Download and concatenate one NHANES file across CYCLES."""
    frames = []
    for year, s in CYCLES:
        p = data_dir / f"{file}_{s}.xpt"
        if not p.exists():
            url = BASE.format(year=year, file=file, s=s)
            try:
                urllib.request.urlretrieve(url, p)
            except Exception as e:                      # noqa: BLE001
                print(f"  MISSING {file}_{s}: {e}")
                continue
        try:
            d = pd.read_sas(p)
        except Exception as e:                          # noqa: BLE001
            print(f"  UNREADABLE {file}_{s}: {e}")
            continue
        cols = [c for c in keep if c in d.columns]
        missing = [c for c in keep if c not in d.columns]
        if missing:
            print(f"  {file}_{s}: variables absent {missing}")
        frames.append(d[["SEQN"] + [c for c in cols if c != "SEQN"]])
    if not frames:
        return pd.DataFrame()
    return pd.concat(frames, ignore_index=True)


def describe(label: str, x: np.ndarray, w: np.ndarray) -> tuple[float, float, int]:
    m = wmean(x, w)
    sd = float(np.sqrt(wmean((x - m) ** 2, w)))
    print(f"   {label:<34} {m:8.3f}  sd {sd:7.3f}   n {len(x):5d}")
    return m, sd, len(x)


def main() -> int:
    data_dir = DEFAULT_DATA
    data_dir.mkdir(parents=True, exist_ok=True)

    rule()
    print("BODY COMPOSITION FROM NHANES DXA - level II, molecular")
    rule()
    print("Cycles:", ", ".join(f"{y}-{int(y)+1} ({s})" for y, s in CYCLES))
    print("Files: DEMO (weights, age, sex), BMX (mass), DXX (fat and lean)")
    print()

    demo = grab(data_dir, "DEMO", ("SEQN", "RIDAGEYR", "RIAGENDR", "WTMEC2YR",
                                   "RIDEXPRG"))
    bmx = grab(data_dir, "BMX", ("SEQN", "BMXWT", "BMXHT"))
    dxx = grab(data_dir, "DXX", ("SEQN",) + DXA_VARS)

    if demo.empty or dxx.empty:
        print("BRANCH C3: the DXA or demographics file could not be read.")
        print("Variables tried:", DXA_VARS)
        return 1

    d = demo.merge(bmx, on="SEQN", how="inner").merge(dxx, on="SEQN", how="inner")

    # Survey weights: WTMEC2YR divided by the number of pooled cycles, which is
    # the standard NHANES procedure and the one nhanes_hpt_extract already uses.
    d["w"] = d.WTMEC2YR / float(len(CYCLES))

    before = len(d)
    d = d[(d.RIDAGEYR >= 20) & d.w.gt(0)
          & d.DXDTOFAT.notna() & d.DXDTOLE.notna() & d.BMXWT.notna()]
    if "RIDEXPRG" in d.columns:
        d = d[d.RIDEXPRG != 1]
    print(f"adults >= 20 y with DXA and mass: {len(d)} of {before} merged rows")
    print()

    # Fat-free mass at the MOLECULAR level is lean soft tissue PLUS bone
    # mineral. Omitting BMC would put ~3 kg of skeleton into neither
    # compartment and the fractions would not sum to one.
    d["fat_kg"] = d.DXDTOFAT / 1000.0
    d["bmc_kg"] = d.DXDTOBMC / 1000.0 if "DXDTOBMC" in d.columns else 0.0
    d["ffm_kg"] = d.DXDTOLE / 1000.0 + d["bmc_kg"]
    d["dxa_total"] = d.fat_kg + d.ffm_kg
    d["f_fat"] = d.fat_kg / d.dxa_total

    out = {}
    for g, lab in ((1, "male"), (2, "female")):
        e = d[d.RIAGENDR == g]
        if e.empty:
            continue
        rule("-")
        print(f" {lab.upper()}")
        w = e.w.values
        describe("scale mass BMXWT (kg)", e.BMXWT.values, w)
        describe("DXA total mass (kg)", e.dxa_total.values, w)
        describe("fat mass (kg)", e.fat_kg.values, w)
        describe("fat-free mass incl BMC (kg)", e.ffm_kg.values, w)
        m, sd, n = describe("FAT FRACTION of DXA total", e.f_fat.values, w)
        pf, _, _ = describe("DXDTOPF (percent fat, as printed)",
                            e.DXDTOPF.values / 100.0, w)
        out[lab] = (m, sd, n)
        print()
        print(f"   CHECK f_fat against DXDTOPF: {m:.4f} vs {pf:.4f}"
              f"   difference {abs(m - pf):.4f}")
        print("     DXDTOPF is the file's own percent fat; agreement means the")
        print("     compartments were assembled the way the file intends.")

    rule()
    print("WHAT THIS IS NOT")
    rule()
    print("NOT skeletal muscle. DXA lean mass is MOLECULAR fat-free soft tissue")
    print("and includes viscera, skin and body water. Skeletal muscle is level")
    print("IV and comes from Janssen 2000 (PMID 10904038, whole-body MRI,")
    print("n = 468): men 33.0 kg and 38.4 percent of body mass, women 21.0 kg")
    print("and 30.6 percent. Compare those with the fat-free masses above - the")
    print("gap is the conflation the five-level model exists to prevent, and it")
    print("is pre-registration test 3.")
    print()
    print("THE SD IS BIASED LOW AND THE ROW MUST SAY SO. NHANES DXA excludes")
    print("pregnancy and excludes participants above a weight and height limit,")
    print("so the upper tail of adiposity is truncated. The mean is affected")
    print("little; the spread is not. Pre-registration section 3.")
    print()
    for lab, (m, sd, n) in out.items():
        print(f"  ENTER  BF.FAT.MASS_FRACTION [{lab}] = {m:.3f}  sd {sd:.3f}  n {n}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
