#!/usr/bin/env python
"""Pool the primary head-out immersion ANP responses.

Executes validation/immersion_pooling_prereg.md. The pooling rule was fixed
BEFORE extraction: ratio quantities pool GEOMETRIC (pooling.md rule 4), in log
space, n-weighted where n is available. range-midpoint is prohibited.

Endpoint fixed in advance: plasma ANP at 180 min of continuous immersion over
the same subjects' pre-immersion baseline. Where a protocol is shorter, the
end-of-immersion value is used and the duration is recorded. Per-paper peaks
are recorded but are NOT the pooled endpoint.

Run:  python validation/immersion_pool.py
"""

import math

# ---------------------------------------------------------------------------
# Q1: plasma ANP fold-rise. IN-FRAME set only - primaries that Epstein 1989
# (PMID 2524162, Am J Nephrol 9:1-24) could have been summarising, i.e. <= 1989.
# Every row was read from the retrieved PubMed record; authors, journal, year,
# volume and pages verified against the record per stop condition 2.
# ---------------------------------------------------------------------------
# (label, pmid, n, duration_h, endpoint_note, baseline, immersed, ratio_override)

Q1_INFRAME = [
    ("Epstein 1987",    "2950133", 13, 3.0,
     "7.8+/-1.8 -> 19.4+/-3.8 fmol/ml; abstract reports the rise, and separately "
     "correlates PEAK ANF with PEAK UNaV, so this may be a peak rather than the "
     "180 min value. DEVIATION RECORDED.",
     7.8, 19.4, None),

    ("Anderson 1986",   "2944688", None, None,
     "'twofold increase of the mean plasma ANP concentration'. No absolute values, "
     "no n, no duration in the abstract. DEVIATION RECORDED.",
     None, None, 2.00),

    ("Pendergast 1987", "2951741", 6, 3.0,
     "~80 -> ~120 pg/ml, explicitly 'during the entire 3-hr immersion period'. "
     "Cleanest match to the declared 180 min endpoint. 35 C water.",
     80.0, 120.0, None),

    ("Ogihara 1987",    "2955141", 7, 1.0,
     "246+/-12 -> 392+/-32 pg/ml at 35+/-5 min. Protocol is 1 h, so the "
     "end-of-immersion rule applies, but only the peak is reported. Direct "
     "unextracted RIA - baseline 246 pg/ml is 3-8x every other study's. "
     "DEVIATION RECORDED.",
     246.0, 392.0, None),

    ("Miki 1988",       "2964206", 6, 3.0,
     "'similar twofold increase within 1 h of HOI and was maintained at this "
     "elevated level throughout the 3-h HOI period'. Matches the endpoint. "
     "Hydropenic subjects, 34.5 C.",
     None, None, 2.00),

    ("Tajima 1988 (young arm)", "2968055", 8, 3.0,
     "'nearly fourfold increase in ANF in the elderly, whereas that for the young "
     "was threefold'. Young arm (21-28 yr) taken; elderly arm is a recorded "
     "covariate, not pooled. Hydropenic, 34.5 C.",
     None, None, 3.00),

    ("Gerbes 1988",     "2972285", 9, 1.0,
     "C-terminal ANF 99-126 (the mature peptide) 4.8+/-0.5 -> 11.6+/-2.3 fmol/ml "
     "at end of 1 h. N-terminal fragment pooled separately below, NOT with this.",
     4.8, 11.6, None),
]

# N-terminal / prohormone fragment assays measure a different analyte.
# pooling.md prohibits pooling across incompatible measurement methods.
Q1_DIFFERENT_ANALYTE = [
    ("Gerbes 1988 N-terminal", "2972285", 9, 461.0, 749.0),
]

# ---------------------------------------------------------------------------
# Q2: natriuretic response, as fold-change vs the same subjects' control.
# ---------------------------------------------------------------------------
Q2_UNAV = [
    ("Epstein 1987",  "2950133", 13, "UNaV 92+/-12 -> 191+/-15 ueq/min", 92.0, 191.0),
    ("Anderson 1986", "2944688", None, "'a doubling of the mean urinary sodium excretion'", None, None),
]
Q2_UNAV_RATIOS = [191.0 / 92.0, 2.00]

# Pendergast reports FRACTIONAL excretion of Na (1.0 -> 1.8 %), not UNaV.
# Incompatible measurement method under pooling.md - recorded, not pooled.
Q2_INCOMPATIBLE = [
    ("Pendergast 1987", "2951741", 6, "FENa 1.0 -> 1.8 % (fractional, not UNaV)", 1.0, 1.8),
]


def geo_mean(ratios, weights=None):
    logs = [math.log(r) for r in ratios]
    if weights is None:
        m = sum(logs) / len(logs)
    else:
        m = sum(w * l for w, l in zip(weights, logs)) / sum(weights)
    return math.exp(m)


def geo_sd(ratios):
    logs = [math.log(r) for r in ratios]
    m = sum(logs) / len(logs)
    if len(logs) < 2:
        return float("nan")
    var = sum((l - m) ** 2 for l in logs) / (len(logs) - 1)
    return math.exp(math.sqrt(var))


def ratio_of(row):
    _, _, _, _, _, base, imm, override = row
    return override if override is not None else imm / base


def main():
    print("=" * 78)
    print("Q1  PLASMA ANP FOLD-RISE, HEAD-OUT IMMERSION, HEALTHY NORMALS")
    print("    In-frame set (<= 1989): the primaries behind Epstein 1989's 2.5-3x")
    print("=" * 78)

    ratios = []
    ns = []
    for row in Q1_INFRAME:
        label, pmid, n, dur, note, base, imm, override = row
        r = ratio_of(row)
        ratios.append(r)
        ns.append(n)
        dur_s = f"{dur:.0f} h" if dur else "n/s"
        n_s = f"n={n}" if n else "n=n/s"
        print(f"\n  {label:<26} PMID {pmid}  {n_s:<7} {dur_s:>4}   ratio = {r:.3f}")
        print(f"      {note}")

    print("\n" + "-" * 78)
    k = len(ratios)
    g_unw = geo_mean(ratios)
    gsd = geo_sd(ratios)

    known = [(r, n) for r, n in zip(ratios, ns) if n is not None]
    g_nw = geo_mean([r for r, _ in known], [n for _, n in known])

    print(f"  k (independent studies)          = {k}")
    print(f"  pooled-geometric, unweighted     = {g_unw:.4f}")
    print(f"  pooled-geometric, n-weighted     = {g_nw:.4f}   (k={len(known)}, "
          f"sum n={sum(n for _, n in known)})")
    print(f"  geometric SD                     = {gsd:.4f}")
    print(f"  min / max of contributing rows   = {min(ratios):.3f} / {max(ratios):.3f}")
    print(f"  PROHIBITED range-midpoint value  = {(2.5 + 3.0) / 2:.3f}  (NOT USED)")

    print("\n  Comparison against the review that reported the range:")
    print("    Epstein 1989 (PMID 2524162): 'rising 2.5- to 3-fold by the end of")
    print("    the 2nd or 3rd h'.")
    lo, hi = 2.5, 3.0
    inside = lo <= g_nw <= hi
    print(f"    Pooled primaries (n-weighted) = {g_nw:.3f}")
    print(f"    Inside the review's 2.5-3x range? {'YES' if inside else 'NO'}")
    n_in = sum(1 for r in ratios if lo <= r <= hi)
    print(f"    Individual studies inside 2.5-3x: {n_in} of {k}")
    print(f"    Individual studies below 2.5x:    {sum(1 for r in ratios if r < lo)} of {k}")

    print("\n" + "=" * 78)
    print("Q1b  DIFFERENT ANALYTE - NOT POOLED WITH THE ABOVE (pooling.md)")
    print("=" * 78)
    for label, pmid, n, base, imm in Q1_DIFFERENT_ANALYTE:
        print(f"  {label:<26} PMID {pmid}  n={n}  {base} -> {imm}  "
              f"ratio = {imm / base:.3f}")
    print("  N-terminal proANF is a different analyte from mature ANP 99-126.")
    print("  Its ratio (1.62) is LOWER than its own paper's C-terminal ratio (2.42),")
    print("  which is why mixing assays would corrupt the pool.")

    print("\n" + "=" * 78)
    print("Q2  NATRIURETIC RESPONSE - THE QUANTITY THE COMPONENT ACTUALLY NEEDS")
    print("=" * 78)
    for label, pmid, n, note, base, imm in Q2_UNAV:
        n_s = f"n={n}" if n else "n=n/s"
        r = imm / base if base else 2.00
        print(f"  {label:<20} PMID {pmid}  {n_s:<7} ratio = {r:.3f}   {note}")
    print()
    for label, pmid, n, note, base, imm in Q2_INCOMPATIBLE:
        print(f"  EXCLUDED (incompatible method): {label} PMID {pmid} n={n}")
        print(f"      {note}  ratio would be {imm / base:.3f}")

    k2 = len(Q2_UNAV_RATIOS)
    print(f"\n  k_pooled for UNaV fold-change = {k2}")
    print(f"  geometric mean of those two   = {geo_mean(Q2_UNAV_RATIOS):.4f}")
    print("\n  *** STOP CONDITION 1 FIRES ***")
    print("  The pre-registration requires k >= 3 INDEPENDENT studies before a")
    print("  parameter is recorded for Q2. k = 2. Two studies do not become a")
    print("  pooled value; they become single-source twice over.")
    print("  NO LEDGER PARAMETER IS RECORDED FOR Q2. Blocker 1 does not close on")
    print("  the model-relevant quantity.")

    print("\n" + "=" * 78)
    print("VERDICT")
    print("=" * 78)
    print(f"  Q1 (blocker 1 as literally written): CLOSES at k={k}, "
          f"pooled-geometric {g_nw:.3f}x n-weighted / {g_unw:.3f}x unweighted.")
    print("     But the value is NOT a model parameter - the revised component")
    print("     carries no ANP state. It is a review-vs-primaries audit, and the")
    print("     primaries do NOT support the review's range.")
    print(f"  Q2 (the quantity the component needs): BLOCKED at k={k2} < 3.")


if __name__ == "__main__":
    main()
