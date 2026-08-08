#!/usr/bin/env python3
"""
Pre-publication setup.

HOW TO USE
    In VS Code, open this file and press the Run button (top right).
    It will ask you four questions, then do the rest.

    Nothing is sent anywhere. This script only edits files in this folder,
    and everything it changes shows up in the Source Control panel for you
    to review before you commit.

Your answers are saved to .publish-config.json so you are only asked once.
Delete that file if you want to change them.
"""

import datetime
import json
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONFIG_FILE = ROOT / ".publish-config.json"
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


def ask(prompt: str, default: str = "", validate=None) -> str:
    """Ask until we get something usable. Blank accepts the default."""
    while True:
        suffix = f" [{default}]" if default else ""
        try:
            val = input(f"   {prompt}{suffix}: ").strip()
        except EOFError:
            sys.exit(
                "\nERROR: this script needs to ask you questions, but nothing is\n"
                "       connected to type into. In VS Code use the Run button (top\n"
                "       right) rather than 'Run Python File in Interactive Window'."
            )
        val = val or default
        if not val:
            print("       (required)")
            continue
        if validate:
            err = validate(val)
            if err:
                print(f"       {err}")
                continue
        return val


def valid_email(v: str) -> str | None:
    return None if re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", v) else "that does not look like an email address"


def valid_reponame(v: str) -> str | None:
    return None if re.match(r"^[A-Za-z0-9._-]+$", v) else "letters, numbers, dots, dashes and underscores only"


def _run(cmd: list[str]) -> str:
    """Run a command, return stdout stripped, empty string on any failure."""
    try:
        r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=15)
        return r.stdout.strip() if r.returncode == 0 else ""
    except Exception:
        return ""


def git_config_get(key: str) -> str:
    """Read the GLOBAL git config only.

    Deliberately not the repo-local config: this repository ships with a
    placeholder identity (Project scaffold <scaffold@localhost>) from when the
    scaffold commits were generated. Offering that as a default would quietly put
    the wrong name on your commits.
    """
    return _run(["git", "config", "--global", "--get", key])


def gh_user_field(field: str) -> str:
    """Pull a field from the signed-in GitHub account via the gh CLI."""
    return _run(["gh", "api", "user", "--jq", f".{field} // empty"])


def guess_defaults() -> dict:
    """Best-effort defaults, in order of trustworthiness."""
    print("\n   Looking up your details...", end=" ", flush=True)
    login = gh_user_field("login")
    name = git_config_get("user.name") or gh_user_field("name")
    email = git_config_get("user.email") or gh_user_field("email")

    # GitHub hides real emails by default; the noreply address always works for
    # commits and keeps your address private.
    if not email and login:
        uid = gh_user_field("id")
        email = f"{uid}+{login}@users.noreply.github.com" if uid else ""

    found = [k for k, v in (("name", name), ("email", email),
                            ("GitHub username", login)) if v]
    print("found " + (", ".join(found) if found else "nothing"))
    if not found:
        print("   (gh not on PATH, or not signed in - you can just type the answers)")
    return {"name": name, "email": email, "login": login}


def load_config() -> dict:
    if CONFIG_FILE.exists():
        cfg = json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        print("\nUsing saved settings from .publish-config.json:")
        for k, v in cfg.items():
            print(f"   {k:18} {v}")
        ans = input("\n   Use these? [Y/n]: ").strip().lower()
        if ans != "n":
            return cfg
        print()

    print("\n" + "-" * 70)
    print("  A few questions. Press Enter to accept anything in [brackets].")
    print("-" * 70)

    d = guess_defaults()
    print()

    cfg = {}
    cfg["your_name"] = ask("Your full name", d["name"])
    cfg["your_email"] = ask("Your email", d["email"], valid_email)
    cfg["gh_owner"] = ask("Your GitHub username", d["login"], valid_reponame)
    cfg["gh_repo"] = ask("Repository name", "integrative-physiology-engine", valid_reponame)

    print()
    print("   The ledger has 8 placeholder parameter rows whose citations were")
    print("   written from memory and are marked TODO-VERIFY. Published git")
    print("   history is permanent.")
    strip = input("   Remove them before publishing? [y/N]: ").strip().lower()
    cfg["strip_seed_rows"] = strip == "y"

    CONFIG_FILE.write_text(json.dumps(cfg, indent=2), encoding="utf-8")
    print(f"\n   Saved to {CONFIG_FILE.name} (you will not be asked again)")
    return cfg


def check_location() -> None:
    if not (ROOT / "SOURCES.md").exists():
        sys.exit(
            "ERROR: this script must sit in the project folder next to SOURCES.md.\n"
            f"       It is currently in: {ROOT}"
        )
    if not (ROOT / ".git").exists():
        sys.exit(
            "ERROR: no .git folder here. The repository history is missing.\n"
            "       Re-extract the archive rather than copying loose files."
        )


def git(*args: str) -> str:
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True,
                          text=True, check=False).stdout.strip()


def set_identity(cfg) -> None:
    step("Git identity (whose name goes on commits)")
    subprocess.run(["git", "config", "user.name", cfg["your_name"]], cwd=ROOT, check=True)
    subprocess.run(["git", "config", "user.email", cfg["your_email"]], cwd=ROOT, check=True)
    done(f'{cfg["your_name"]} <{cfg["your_email"]}>')


def write_licence(cfg) -> None:
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
        f'Copyright {YEAR} {cfg["your_name"]}\n\n'
        "This product includes software developed independently from published\n"
        "peer-reviewed literature. See SOURCES.md for the source whitelist policy.\n",
        encoding="utf-8",
    )
    done("NOTICE written")


def fix_project_toml(cfg) -> None:
    step("Project.toml authors")
    p = ROOT / "Project.toml"
    s = p.read_text(encoding="utf-8")
    new = re.sub(
        r'^authors = \[.*\]$',
        f'authors = ["{cfg["your_name"]} <{cfg["your_email"]}>"]',
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


def write_citation(cfg) -> None:
    step("CITATION.cff")
    (ROOT / "CITATION.cff").write_text(
        "cff-version: 1.2.0\n"
        'message: "If you use this software, please cite it as below."\n'
        'title: "Integrative Physiology Engine"\n'
        "abstract: >-\n"
        "  An independent implementation of whole-body integrative human physiology,\n"
        "  built from published peer-reviewed literature with full parameter provenance.\n"
        "authors:\n"
        f'  - name: "{cfg["your_name"]}"\n'
        f'repository-code: "https://github.com/{cfg["gh_owner"]}/{cfg["gh_repo"]}"\n'
        "license: Apache-2.0\n"
        "version: 0.0.1\n"
        f'date-released: "{TODAY}"\n',
        encoding="utf-8",
    )
    done("written")


def strip_seeds(cfg) -> None:
    if not cfg["strip_seed_rows"]:
        step("Scaffold ledger rows")
        print("   --  keeping them (you chose not to remove them)")
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
    cfg = load_config()

    set_identity(cfg)
    write_licence(cfg)
    fix_project_toml(cfg)
    fix_readme()
    write_citation(cfg)
    strip_seeds(cfg)
    regenerate_and_check()

    print("\n" + "=" * 70)
    print(f"  {ok_count} steps completed" + (f", {len(warnings)} warning(s)" if warnings else ""))
    for w in warnings:
        print(f"  !! {w}")
    print("=" * 70)
    print(
        "\nNEXT, in VS Code:\n"
        "  1. Open the Source Control panel (Ctrl+Shift+G). Review the changed files -\n"
        "     click any one to see old on the left, new on the right.\n"
        "  2. Type a message: Pre-publication: licence, citation, authors\n"
        "  3. Press the Commit tick.\n"
        "  4. Press 'Publish Branch' and choose PUBLIC when asked.\n"
        "\nNothing has been sent anywhere yet. Only step 4 reaches the internet.\n"
    )


if __name__ == "__main__":
    main()
