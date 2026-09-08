#!/usr/bin/env python3
"""
Assemble gui/index.html from gui/template.html and gui/model_data.json.

    python tools/export_gui_data.jl   # via julia, writes gui/model_data.json
    python tools/build_gui.py         # writes gui/index.html

THE DATA IS INLINED, not fetched. A page opened with file:// cannot fetch a
sibling JSON file - the browser blocks it - and the owner opens this by
double-clicking it. One self-contained file also means the thing that gets
shared is the thing that was checked.

THE CAVEATS ARE HERE AND NOT IN THE TEMPLATE because they are transcribed from
HANDOVER.md, and a copy of a fact is how two copies drift apart. Each one names
the section it comes from so the trail is short.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "gui" / "template.html"
DATA = ROOT / "gui" / "model_data.json"
OUT = ROOT / "gui" / "index.html"

# (heading, body). Transcribed from HANDOVER.md; the section is named in each.
CAVEATS = [
    ("Salt sensitivity is a FIT, not a prediction (HANDOVER §3.21)",
     "The model reproduces human salt sensitivity, 1.85 mmHg per 100 mmol/day against a "
     "meta-analytic 1.70–2.30, and the pressure–volume ratio, 3.00 mmHg/L against a measured "
     "2.97–4.16. Two of the three parameters that make it do so were solved against those very "
     "targets. Quote neither to more than three significant figures."),
    ("One number is genuinely held out, and the model is a third low (§4 item 2)",
     "Predicted fractional sodium excretion after 23 mL/kg of isotonic saline is +79%, against "
     "Jensen 2013's measured +123%. Jensen was deliberately excluded from estimation, so it is "
     "the only place the parameterisation is tested rather than fitted. It is the sharpest "
     "discrepancy in the sodium limb and it must not be closed by refitting."),
    ("The thyroid axis is on ONE assay scale, and ADR 0019's test 2 is void (§3.26)",
     "It was reported here for a day that euthyroid thyrotropin came out 2.4× too high. That was "
     "a unit error, not a bad coefficient: a pituitary line measured on a free-thyroxine "
     "immunoassay was composed with a concentration measured by equilibrium dialysis, and the two "
     "scales differ 1.73-fold in the free fraction while agreeing to 6% on total thyroxine "
     "(NHANES 2007–2012, n = 6814). The axis is now on the dialysis scale throughout, with its "
     "operating point sourced — so the crossing point is no longer a prediction and the "
     "falsifiable test that judged it is ill-posed rather than failed. What remains a prediction "
     "is the RESPONSE, which barely moved: 0.305 against 0.308."),
    ("No acute osmotic magnitude may be reported (§4 item 3)",
     "The ICF–ECF osmotic time constant is assumed at 30 minutes and no admissible source could "
     "be found. It is negligible over days and DOMINANT within one: a 1.4 L water load moves peak "
     "plasma osmolality between 8.8 and 17.6 mOsm/kg depending on it. Directions and steady "
     "states are unaffected."),
    ("Arterial PCO2 is an INPUT, not an output (ADR 0017 amendment)",
     "The chemoreflex's recruitment threshold is 45.3 mmHg and resting PaCO2 is 40, so at rest "
     "the reflex is below its own threshold and is not the operative control. Resting PaCO2 is "
     "therefore sourced and basal ventilation derived from it. The component's claim is the "
     "RESPONSE, not the operating point — which is the opposite of how arterial pressure works "
     "in this model, and the asymmetry is physiological."),
    ("Sea level, awake, resting, adult, non-pregnant, healthy",
     "No hypoxic ventilatory drive, no altitude, no exercise, no sleep, no posture, no age "
     "dimension. The alveolar–arterial oxygen difference widens with age and this model carries a "
     "young-adult value. Arterial pH is computed and COMPENSATION is not: plasma bicarbonate is a "
     "sourced input rather than a state, because neither half of its balance could be sourced in "
     "health, so there is no renal answer to a respiratory disturbance and — by decision — no "
     "respiratory answer to a metabolic one. The oxyhaemoglobin curve is fixed at normal pH and "
     "temperature, so there is no Bohr shift."),
    ("Sex-dependent salt sensitivity is PREDICTED and unsourced (§4 item 7)",
     "The model predicts salt sensitivity 17.7% higher in women. A pressure-only kidney carried "
     "no sex information at all; the volume path is keyed to a sexed volume, so it does. It is "
     "asserted in the test suite as a prediction. Nobody has sourced or falsified it."),
    ("Body size scaling is sub-linear for SURFACES and still linear for VOLUMES (§3.30)",
     "Glomerular filtration, cardiac output and metabolic rate now scale as (m/70)^0.5083, from "
     "height and body surface area measured in 9300 NHANES adults. The fluid compartments do "
     "not: extracellular volume is a mass fraction, and fat carries less water than lean tissue, "
     "so the model still overstates the fluid volumes of heavy people. And nothing has been "
     "VALIDATED by the change — narrowing a spread is not the same as making it right, and no "
     "measured population spread has been compared against."),
    ("One parameter is still labelled `calibrated` (§4 item 5)",
     "The pressure-natriuresis slope. It is not freely fitted — it is the value the human joint "
     "constraint implies given the sourced volume gain — but the label has not been decided "
     "deliberately, and the ledger is organised to reach zero calibrated rows."),
    ("TWO ACUTE ENDPOINTS FAIL, and the failure bounds the macula densa arm (§3.32)",
     "The challenge harness exits nonzero on purpose. Distal sodium delivery now inhibits renin "
     "(ADR 0021), which lifts a ceiling the model had recorded against itself — the renin ratio "
     "across the human salt range goes from 1.14 to the measured 2.73 — and it overshoots the "
     "six-hour limb of a two-litre saline infusion: 771 mL and 129 mmol against bands of 380–750 "
     "and 63–127. Sweeping the gain shows the arm can carry a chronic renin ratio of about 2.57 "
     "before the acute limb leaves its band. The last 6% is where the renal sympathetic traffic "
     "the model does not have would sit. Reported, not tuned: the gain is left where its "
     "estimation set puts it."),
    ("Aldosterone is chronically a REPORTER, not an effector (ADR 0021 amendment A5)",
     "Plasma potassium reaches aldosterone and aldosterone reaches distal sodium reabsorption, so "
     "the coupling graph suggests potassium should move arterial pressure. It does not — by less "
     "than one part in 10^12 across a fourfold change in dietary potassium — because aldosterone "
     "escape drives the tubular effect to zero at every steady state. That is a fact about the "
     "escape structure, not about potassium. It also means the model's whole sodium response to "
     "aldosterone is invisible to any resting measurement."),
    ("Potassium excretion lumps three mechanisms into one exponent (ADR 0021 amendment A3)",
     "Excretion rises with aldosterone, with distal flow and with plasma potassium, and every "
     "human study found moves all three together, so no gain separates. They are collapsed into "
     "one exponent fitted to a measured intake–concentration response. The model therefore cannot "
     "tell a spironolactone, a primary aldosteronism and a potassium load apart. Written LINEAR "
     "first, it predicted 7.6 mmol/L from a doubled ordinary diet, and the pre-registered "
     "falsifiable test caught that on its first run."),
    ("There is no potassium ADAPTATION (§3.35)",
     "Rabelink 1990 found renin and aldosterone back at baseline by day 20 of a 400 mmol/day "
     "potassium load with kaliuresis maintained; this model holds aldosterone at 2.80 times "
     "baseline for ever, because its excretion relation is fixed and its only adaptive machinery "
     "acts on the sodium side. So the direction and rough size of a chronic potassium load are "
     "right and the hormone time course is wrong. The urinary share of dietary potassium is no "
     "longer a constant — it rises with intake, in a shape fixed before the data — but that "
     "exponent rests on one abstract-level study in six men and its interval includes no rise at "
     "all. What carries it is that colonic potassium secretion rises with intake, not the "
     "statistic."),
    ("Twenty-five parameters are `assumed` and the search is recorded on each",
     "An assumed row means no admissible source could be opened, not that none was sought. Open "
     "the Parameters tab and filter by basis to see every one with its search history. The "
     "load-bearing ones are the urinary solute load, the ICF–ECF osmotic time constant, and the "
     "respiratory dead-space fraction."),
]


def main() -> int:
    for p in (TEMPLATE, DATA):
        if not p.exists():
            print("missing %s" % p, file=sys.stderr)
            return 1

    raw = DATA.read_text(encoding="utf-8")
    # Parse and re-dump: a malformed export must fail here, not in a browser.
    obj = json.loads(raw)
    for key in ("quantities", "baseline", "sweeps", "parameters", "relations"):
        if key not in obj:
            print("export is missing %r" % key, file=sys.stderr)
            return 1
    compact = json.dumps(obj, separators=(",", ":"), ensure_ascii=False)
    # </script> inside the payload would close the tag early.
    compact = compact.replace("</", "<\\/")

    html = TEMPLATE.read_text(encoding="utf-8")
    for token in ("__DATA__", "__CAVEATS__"):
        if html.count(token) != 1:
            print("template must contain %s exactly once" % token, file=sys.stderr)
            return 1
    html = html.replace("__DATA__", compact)
    html = html.replace("__CAVEATS__",
                        json.dumps(CAVEATS, ensure_ascii=False).replace("</", "<\\/"))

    OUT.write_text(html, encoding="utf-8", newline="\n")
    print("wrote %s (%.0f kB): %d parameters, %d relations, %d quantities, %d sweeps"
          % (OUT, OUT.stat().st_size / 1024, len(obj["parameters"]),
             len(obj["relations"]), len(obj["quantities"]), len(obj["sweeps"])))
    return 0


if __name__ == "__main__":
    sys.exit(main())
