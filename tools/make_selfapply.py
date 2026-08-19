#!/usr/bin/env python3
"""
Turn a git patch series into ONE self-applying Python script.

    python tools/make_selfapply.py out.py 0001-*.patch [0002-*.patch ...]

The generated script is a single file the user downloads and runs:

    python out.py

It locates the repo, verifies the patches apply, shows what they change, asks
for confirmation, applies with `git am --signoff`, runs the provenance checks,
and offers to push.

WHY BASE64

The patch is embedded base64-encoded, not as literal text. Line endings have
already broken this project twice: a Windows checkout rewrote parameters.csv as
CRLF and invalidated a recorded SHA256, and shell scripts checked out with CRLF
failed under bash. A patch is byte-exact by nature - one changed line ending and
`git am` rejects it. Base64 survives any transport.
"""

from __future__ import annotations

import base64
import sys
from pathlib import Path

TEMPLATE = '''#!/usr/bin/env python3
"""
Self-applying patch for the Integrative Physiology Engine.

    python {script_name}

Run it from anywhere inside the project folder. It will find the repo root.

Nothing is applied until you confirm, and nothing is pushed unless the
provenance checks pass.

Contains {n} commit(s):
{subjects}
"""

import base64
import subprocess
import sys
import tempfile
from pathlib import Path

PATCHES = {patches!r}

BOLD, RESET = "\\033[1m", "\\033[0m"


def find_root(start: Path) -> Path:
    """Walk up looking for the project root."""
    for d in [start, *start.parents]:
        if (d / "SOURCES.md").exists() and (d / ".git").exists():
            return d
    sys.exit(
        "ERROR: not inside the project.\\n"
        "       Put this file in (or under) the folder containing SOURCES.md\\n"
        "       and run it again."
    )


def run(cmd, root, capture=True):
    return subprocess.run(cmd, cwd=root, text=True, capture_output=capture)


def out(cmd, root):
    r = run(cmd, root)
    return r.stdout.strip() if r.returncode == 0 else ""


def confirm(q, default_yes=True):
    hint = "[Y/n]" if default_yes else "[y/N]"
    try:
        a = input(f"\\n   {{q}} {{hint}}: ").strip().lower()
    except EOFError:
        sys.exit("\\nERROR: needs an interactive terminal.")
    return default_yes if not a else a.startswith("y")


def main() -> int:
    root = find_root(Path(__file__).resolve().parent)
    print("=" * 66)
    print(f"  {{BOLD}}Applying {n} commit(s){{RESET}}")
    print(f"  {{root}}")
    print("=" * 66)

    if not out(["git", "rev-parse", "--git-dir"], root):
        sys.exit("ERROR: git not available, or this is not a git repository.")

    # Uncommitted work would make a failed `git am` hard to unpick.
    dirty = [l for l in out(["git", "status", "--porcelain"], root).splitlines()
             if "incoming/" not in l and Path(__file__).name not in l]
    if dirty:
        print("\\nYou have uncommitted changes:")
        for l in dirty[:10]:
            print("   " + l)
        sys.exit("\\nCommit or discard them first, then run this again.")

    # Write the patches out byte-exact.
    tmp = Path(tempfile.mkdtemp())
    files = []
    for name, b64 in PATCHES:
        p = tmp / name
        p.write_bytes(base64.b64decode(b64))
        files.append(str(p))

    print("\\n>> checking the patches fit your current code")
    chk = run(["git", "apply", "--check"] + files, root)
    if chk.returncode != 0:
        print(chk.stderr)
        sys.exit(
            "\\nThese patches were built against a different version of the code.\\n"
            "Ask for them to be regenerated against your current main."
        )
    print("   they fit")

    print("\\n>> what changes")
    print(run(["git", "apply", "--stat"] + files, root).stdout)

    if confirm("Show the full diff?", default_yes=False):
        run(["git", "--no-pager", "apply", "--stat"] + files, root, capture=False)
        for f in files:
            print(Path(f).read_text(encoding="utf-8", errors="replace"))

    print("\\n   Applying adds your Signed-off-by. Authorship stays with whoever")
    print("   wrote the change.")
    if not confirm("Apply?", default_yes=False):
        print("\\nNothing changed.")
        return 0

    import datetime
    br = f"sprint/{{datetime.datetime.now():%Y%m%d-%H%M}}"
    run(["git", "switch", "-c", br], root, capture=False)
    r = run(["git", "am", "--signoff"] + files, root, capture=False)
    if r.returncode != 0:
        run(["git", "am", "--abort"], root)
        run(["git", "switch", "-"], root)
        run(["git", "branch", "-D", br], root)
        sys.exit("\\nApply failed. Back on your previous branch; nothing changed.")

    print("\\n>> provenance checks")
    failed = False
    for tool, label in (("tools/ledger_to_julia.py", "ledger"),
                        ("tools/check_closure.py", "closure"),
                        ("tools/check_adrs.py", "ADRs")):
        if not (root / tool).exists():
            continue
        args = [sys.executable, tool] + (["--check"] if "ledger" in tool else [])
        c = run(args, root)
        if c.returncode != 0:
            print(f"   {{label}}: FAILED")
            print(c.stdout or "", c.stderr or "")
            failed = True
        else:
            print(f"   {{label}}: ok")

    if failed:
        print(f"\\nChecks failed. The branch {{br}} exists but will not be pushed.")
        print(f"Discard with:  git switch main && git branch -D {{br}}")
        return 1

    if not out(["git", "remote", "get-url", "origin"], root):
        print(f"\\nApplied on branch {{br}}. No remote configured, so nothing pushed.")
        return 0

    if not confirm(f"Push {{br}} and open a pull request?"):
        print(f"\\nApplied on branch {{br}}. Push when ready:  git push -u origin {{br}}")
        return 0

    if run(["git", "push", "-u", "origin", br], root, capture=False).returncode != 0:
        sys.exit("Push failed.")

    import shutil
    if shutil.which("gh"):
        run(["gh", "pr", "create", "--fill", "--base", "main"], root, capture=False)
        print("\\nPR opened. Merge when CI is green:")
        print("   gh pr merge --squash --delete-branch")
    else:
        print(f"\\nPushed {{br}}. Open a PR on GitHub.")

    run(["git", "switch", "main"], root)
    print("Done. Back on main.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
'''


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__)
        return 1

    out_path = Path(sys.argv[1])
    patch_paths = [Path(p) for p in sys.argv[2:]]

    patches = []
    subjects = []
    for p in patch_paths:
        if not p.exists():
            print(f"no such patch: {p}", file=sys.stderr)
            return 1
        raw = p.read_bytes()
        patches.append((p.name, base64.b64encode(raw).decode("ascii")))
        for line in raw.decode("utf-8", errors="replace").splitlines():
            if line.startswith("Subject:"):
                subjects.append("  " + line.replace("Subject: ", "")
                                .replace("[PATCH] ", "").strip())
                break

    body = TEMPLATE.format(
        script_name=out_path.name,
        n=len(patches),
        subjects="\n".join(subjects),
        patches=patches,
    )
    out_path.write_text(body, encoding="utf-8", newline="\n")
    size_kb = out_path.stat().st_size / 1024
    print(f"Wrote {out_path} ({size_kb:.0f} KB, {len(patches)} commit(s))")
    print("The user runs:  python " + out_path.name)
    return 0


if __name__ == "__main__":
    sys.exit(main())
