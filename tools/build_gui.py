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
    ("Euthyroid thyrotropin is 2.4× too high (§3.25)",
     "The thyroid loop's crossing point is a real prediction — free thyroxine from equilibrium "
     "dialysis, the pituitary line from a loading experiment in different subjects — and it lands "
     "at 3.35 mIU/L against a NHANES III reference-population geometric mean of 1.40. Sweeping "
     "the slope across its whole two-source spread moves it 2%, so the unreplicated intercept "
     "carries all of it. Reported, not tuned."),
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
     "young-adult value. Acid–base is absent entirely: the oxyhaemoglobin curve is fixed at "
     "normal pH and temperature, so nothing whose perturbed variable is the POSITION of that "
     "curve can be represented."),
    ("Sex-dependent salt sensitivity is PREDICTED and unsourced (§4 item 7)",
     "The model predicts salt sensitivity 17.7% higher in women. A pressure-only kidney carried "
     "no sex information at all; the volume path is keyed to a sexed volume, so it does. It is "
     "asserted in the test suite as a prediction. Nobody has sourced or falsified it."),
    ("Body size scaling is linear and should not be (§4 item 10)",
     "Glomerular filtration and cardiac output scale sub-linearly with mass in reality and "
     "linearly here, so the population spread of both is overstated. Fixing it needs a height row "
     "and a sourced body-surface-area formula."),
    ("One parameter is still labelled `calibrated` (§4 item 5)",
     "The pressure-natriuresis slope. It is not freely fitted — it is the value the human joint "
     "constraint implies given the sourced volume gain — but the label has not been decided "
     "deliberately, and the ledger is organised to reach zero calibrated rows."),
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
