#!/usr/bin/env python3
"""
Pre-publication setup. Cross-platform replacement for setup-github.sh preflight.

HOW TO USE
    1. Edit the CONFIG block below.
    2. In VS Code, open this file and press the Run button (or F5).
    3. Look at the Source Control panel to see what changed.

This script only touches files in this folder. It does not talk to GitHub and it
does not commit anything. Everything it does is visible in the Source Control panel
before you decide to keep it.

The one thing it fetches from the internet is the Apache licence text. If you have no
connection it will tell you and carry on.
"""

# =============================================================================
# CONFIG - edit these seven lines, then run
# =============================================================================
GH_OWNER          = "histoneguy"
GH_REPO           = "integrative-physiology-engine"
YOUR_NAME         = "Your Name"
YOUR_EMAIL        = "you@example.com"
COPYRIGHT_HOLDER  = "Your Name"

# The eight scaffold parameter rows carry citations written from memory and are
# marked TODO-VERIFY. Public git history is permanent. True = remove them now.
STRIP_SEED_ROWS   = False
# =============================================================================

import datetime
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
YEAR = datetime.date.today().year
TODAY = datetime.date.today().isoformat()

ok_count = 0
warnings: list[str] = []


def step(msg: str) -> None:
    print(f"\n>> {msg}")


def done(msg: str) -> None:
    global ok_count
    ok_count += 1
    print(f"   OK  {msg}")


def warn(msg: str) -> None:
    warnings.append(msg)
    print(f"   !!  {msg}")


def check_location() -> None:
    if not (ROOT / "SOURCES.md").exists():
        sys.exit(
            "ERROR: this script must sit in the project folder next to SOURCES.md.\n"
            f"       It is currently in: {ROOT}"
        )
    if not (ROOT / ".git").exists():
        sys.exit(
            "ERROR: no .git folder here. The repository history is missing.\n"
            "       Re-extract the tarball rather than copying loose files."
        )


def check_config() -> None:
    if "Your Name" in (YOUR_NAME, COPYRIGHT_HOLDER) or "you@example.com" == YOUR_EMAIL:
        sys.exit(
            "ERROR: edit the CONFIG block at the top of this file first.\n"
            "       Your name and email go into the licence and the commit history."
        )


def git(*args: str) -> str:
    return subprocess.run(
        ["git", *args], cwd=ROOT, capture_output=True, text=True, check=False
    ).stdout.strip()


def set_identity() -> None:
    step("Git identity (whose name goes on commits)")
    subprocess.run(["git", "config", "user.name", YOUR_NAME], cwd=ROOT, check=True)
    subprocess.run(["git", "config", "user.email", YOUR_EMAIL], cwd=ROOT, check=True)
    done(f"{YOUR_NAME} <{YOUR_EMAIL}>")


def write_licence() -> None:
    step("Licence (Apache-2.0)")
    lic = ROOT / "LICENSE"
    if lic.exists():
        done("LICENSE already present, left alone")
    else:
        try:
            with urllib.request.urlopen(
                "https://www.apache.org/licenses/LICENSE-2.0.txt", timeout=20
            ) as r:
                lic.write_text(r.read().decode("utf-8"), encoding="utf-8")
            done("LICENSE downloaded")
        except Exception as exc:
            warn(
                f"could not download licence text ({exc}). "
                "Save it manually from apache.org/licenses/LICENSE-2.0.txt as LICENSE"
            )

    (ROOT / "NOTICE").write_text(
        f"Integrative Physiology Engine\n"
        f"Copyright {YEAR} {COPYRIGHT_HOLDER}\n\n"
        "This product includes software developed independently from published\n"
        "peer-reviewed literature. See SOURCES.md for the source whitelist policy.\n",
        encoding="utf-8",
    )
    done("NOTICE written")


def fix_project_toml() -> None:
    step("Project.toml authors")
    p = ROOT / "Project.toml"
    s = p.read_text(encoding="utf-8")
    new = re.sub(
        r'^authors = \[.*\]$',
        f'authors = ["{YOUR_NAME} <{YOUR_EMAIL}>"]',
        s,
        flags=re.M,
    )
    if new != s:
        p.write_text(new, encoding="utf-8")
        done("authors set")
    else:
        done("authors already set")


def fix_readme() -> None:
    step("README licence section")
    p = ROOT / "README.md"
    s = p.read_text(encoding="utf-8")
    orig = s
    s = re.sub(
        r"\*\*TODO before first push\.\*\*.*?separately accepted elsewhere\.",
        "Apache-2.0. See `LICENSE`. Chosen over MIT for its express patent grant and\n"
        "defensive termination clause. A permissive licence on this code says nothing\n"
        "about obligations a contributor may have accepted separately elsewhere.",
        s,
        flags=re.S,
    )
    s = s.replace(
        "TODO — CITATION.cff once the first release is tagged.", "See `CITATION.cff`."
    )
    s = s.replace("> Rename this repository and this heading before first push.\n\n", "")
    if s != orig:
        p.write_text(s, encoding="utf-8")
        done("licence section resolved")
    else:
        done("already resolved")


def write_citation() -> None:
    step("CITATION.cff")
    (ROOT / "CITATION.cff").write_text(
        "cff-version: 1.2.0\n"
        'message: "If you use this software, please cite it as below."\n'
        'title: "Integrative Physiology Engine"\n'
        "abstract: >-\n"
        "  An independent implementation of whole-body integrative human physiology,\n"
        "  built from published peer-reviewed literature with full parameter provenance.\n"
        "authors:\n"
        f'  - name: "{COPYRIGHT_HOLDER}"\n'
        f'repository-code: "https://github.com/{GH_OWNER}/{GH_REPO}"\n'
        "license: Apache-2.0\n"
        "version: 0.0.1\n"
        f'date-released: "{TODAY}"\n',
        encoding="utf-8",
    )
    done("written")


def strip_seeds() -> None:
    if not STRIP_SEED_ROWS:
        step("Scaffold ledger rows")
        print("   --  keeping them (STRIP_SEED_ROWS = False)")
        print("       They are marked TODO-VERIFY. Verify or remove before relying")
        print("       on any value. Git history is permanent once published.")
        return
    step("Removing scaffold ledger rows")
    p = ROOT / "ledger" / "parameters.csv"
    lines = p.read_text(encoding="utf-8").splitlines(keepends=True)
    kept = [ln for ln in lines if "SCAFFOLD SEED" not in ln]
    p.write_text("".join(kept), encoding="utf-8")
    done(f"removed {len(lines) - len(kept)} rows")


def regenerate_and_check() -> None:
    step("Parameter ledger check")
    gen = ROOT / "tools" / "ledger_to_julia.py"
    r = subprocess.run(
        [sys.executable, str(gen)], cwd=ROOT, capture_output=True, text=True
    )
    if r.returncode != 0:
        print(r.stdout)
        print(r.stderr)
        sys.exit("ERROR: ledger validation failed. Fix the rows it names, then re-run.")
    done(r.stdout.strip() or "regenerated")


def main() -> None:
    print("=" * 70)
    print("  Pre-publication setup")
    print(f"  {ROOT}")
    print("=" * 70)

    check_location()
    check_config()
    set_identity()
    write_licence()
    fix_project_toml()
    fix_readme()
    write_citation()
    strip_seeds()
    regenerate_and_check()

    print("\n" + "=" * 70)
    print(f"  {ok_count} steps completed" + (f", {len(warnings)} warning(s)" if warnings else ""))
    for w in warnings:
        print(f"  !! {w}")
    print("=" * 70)
    print(
        "\nNEXT, in VS Code:\n"
        "  1. Open the Source Control panel (the branch icon in the left bar,\n"
        "     or Ctrl+Shift+G). Review every changed file.\n"
        "  2. Type a message such as: Pre-publication: licence, citation, authors\n"
        "  3. Press the Commit tick.\n"
        "  4. Press 'Publish Branch' and choose PUBLIC when asked.\n"
        "\nNothing has been sent anywhere yet. Only step 4 reaches the internet.\n"
    )


if __name__ == "__main__":
    main()
