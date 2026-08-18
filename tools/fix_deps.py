#!/usr/bin/env python3
"""
Sync Project.toml [deps] against what the Julia source actually imports.

    python tools/fix_deps.py           # show what is missing
    python tools/fix_deps.py --apply   # add them and run Pkg.resolve()

WHY THIS EXISTS

Julia refuses to load a package that imports a module not declared in its
Project.toml, including standard-library modules like LinearAlgebra. Python does
not, which is why these were missed when the source was written. The errors
surface ONE AT A TIME - fix LinearAlgebra, hit Printf, fix Printf, hit Random -
which is slow and irritating.

This scans every `using` and `import` in src/, test/ and bench/, works out which
are undeclared, and adds them with their canonical UUIDs. It fixes all of them in
one pass instead of one per Julia invocation.

Standard-library UUIDs are fixed constants and are listed below. Anything not a
stdlib and not already declared is reported but NOT added automatically - adding
a third-party package is a real dependency decision, not a bookkeeping fix, and
should go through a human.
"""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROJECT = ROOT / "Project.toml"
SCAN_DIRS = ["src", "test", "bench", "tools"]

# Julia standard library UUIDs. Stable across versions.
STDLIB_UUIDS = {
    "Base64": "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f",
    "Dates": "ade2ca70-3891-5945-98fb-dc099432e06a",
    "DelimitedFiles": "8bb1440f-4735-579b-a4ab-409b98df4dab",
    "Distributed": "8ba89e20-285c-5b6f-9357-94700520ee1b",
    "InteractiveUtils": "b77e0a4c-d291-57a0-90e8-8db25a27a240",
    "LibGit2": "76f85450-5226-5b5a-8eaa-529ad045b433",
    "Libdl": "8f399da3-3557-5675-b5ff-fb832c97cbdb",
    "LinearAlgebra": "37e2e46d-f89d-539d-b4ee-838fcccc9c8e",
    "Logging": "56ddb016-857b-54e1-b83d-db4d58db5568",
    "Markdown": "d6f4376e-aef5-505a-96c1-9c027394607a",
    "Mmap": "a63ad114-7e13-5084-954f-fe012c677804",
    "Pkg": "44cfe95a-1eb2-52ea-b672-e2afdf69b78f",
    "Printf": "de0858da-6303-5e67-8744-51eddeeeb8d7",
    "Profile": "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79",
    "REPL": "3fa0cd96-eef1-5676-8a61-b3b8758bbffb",
    "Random": "9a3f8284-a2c9-5f02-9a11-845980a1fd5c",
    "SHA": "ea8e919c-243c-51af-8825-aaa63cd721ce",
    "Serialization": "9e88b42a-f829-5b0c-bbe9-9e923198166b",
    "SharedArrays": "1a1011a3-84de-559e-8e89-a11a2f7dc383",
    "Sockets": "6462fe0b-24de-5631-8697-dd941f90decc",
    "SparseArrays": "2f01184e-e22b-5df5-ae63-d93ebab69eaf",
    "Statistics": "10745b16-79ce-11e8-11f9-7d13ad32a3b2",
    "Test": "8dfed614-e22c-5e08-85e1-65c5234f0b40",
    "UUIDs": "cf7118a7-6976-5b1a-9a39-7adc72f591a4",
}

# Third-party packages that are hard requirements of this project, with their
# canonical UUIDs, so a fresh checkout is not blocked on a manual Pkg.add.
KNOWN_REQUIRED = {
    "ADTypes": "47edcb42-4c32-4615-8424-f2b9edc5f35b",
    "BenchmarkTools": "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf",
    "Unicode": "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5",
}

# Modules that are never dependencies
IGNORE = {"Base", "Core", "Main"}


def find_imports() -> dict[str, set[str]]:
    """Module name -> set of files importing it."""
    # Matches `using Foo`, `import Foo`, `using Foo, Bar`, `using Foo: baz`.
    # Skips `using ..Local` (relative, internal to this package).
    #
    # NOTE the character class uses [^\S\n] (whitespace except newline) rather
    # than \s. With \s a single match swallowed every following `using` line,
    # because \s matches newlines - so three consecutive imports were seen as
    # one. Caught by testing against the real source rather than a sample.
    pattern = re.compile(
        r"^[^\S\n]*(?:using|import)[^\S\n]+([A-Za-z_][\w,.:]*(?:[^\S\n]*,[^\S\n]*[\w.:]+)*)",
        re.M)
    found: dict[str, set[str]] = {}

    for d in SCAN_DIRS:
        base = ROOT / d
        if not base.exists():
            continue
        for f in base.rglob("*.jl"):
            text = f.read_text(encoding="utf-8", errors="replace")
            for m in pattern.finditer(text):
                clause = m.group(1).split(":")[0]
                for part in clause.split(","):
                    name = part.strip()
                    if not name or name.startswith("."):
                        continue
                    name = name.split(".")[0].strip()
                    if not name or name in IGNORE:
                        continue
                    if not re.match(r"^[A-Za-z_]\w*$", name):
                        continue
                    found.setdefault(name, set()).add(
                        str(f.relative_to(ROOT)).replace("\\", "/"))
    return found


def parse_project() -> tuple[list[str], dict[str, str], str]:
    """Return (lines, declared name->uuid, raw text)."""
    text = PROJECT.read_text(encoding="utf-8")
    declared: dict[str, str] = {}
    in_deps = False
    for line in text.splitlines():
        st = line.strip()
        if st.startswith("["):
            in_deps = st == "[deps]"
            continue
        if in_deps and "=" in st:
            k, v = st.split("=", 1)
            declared[k.strip()] = v.strip().strip('"')
    return text.splitlines(), declared, text


def is_local_module(name: str) -> bool:
    """A module defined by this package itself is not a dependency."""
    return name == "IPE" or (ROOT / "src" / f"{name}.jl").exists()


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true",
                    help="write Project.toml and run Pkg.resolve()")
    args = ap.parse_args()

    if not PROJECT.exists():
        print(f"no Project.toml at {PROJECT}", file=sys.stderr)
        return 1

    imports = find_imports()
    _, declared, text = parse_project()

    missing_stdlib: dict[str, str] = {}
    missing_other: dict[str, set[str]] = {}

    for name, files in sorted(imports.items()):
        if name in declared or is_local_module(name):
            continue
        if name == "Test":
            # Test-only. Belongs in [extras] + [targets], never in [deps] -
            # putting it in [deps] makes it a runtime dependency of the package.
            continue
        if name in STDLIB_UUIDS:
            missing_stdlib[name] = STDLIB_UUIDS[name]
        elif name in KNOWN_REQUIRED:
            missing_stdlib[name] = KNOWN_REQUIRED[name]
        else:
            missing_other[name] = files

    has_test_target = "[targets]" in text

    _, declared_now, text_now = parse_project()
    test_in_deps = "Test" in declared_now

    if not missing_stdlib and not missing_other and has_test_target and not test_in_deps:
        print(f"Dependencies are in sync ({len(declared)} declared).")
        return 0

    if missing_stdlib:
        print("Missing standard-library dependencies (will be added):")
        for n in sorted(missing_stdlib):
            print(f"   {n:<18} used in {', '.join(sorted(imports[n]))}")
    if missing_other:
        print("\nMissing THIRD-PARTY packages (NOT added automatically):")
        for n, files in sorted(missing_other.items()):
            print(f"   {n:<18} used in {', '.join(sorted(files))}")
        print("   Adding a third-party package is a dependency decision, not a")
        print("   bookkeeping fix. Add deliberately with:")
        print(f"     julia --project=. -e 'using Pkg; Pkg.add(\"{sorted(missing_other)[0]}\")'")
    if not has_test_target:
        print("\nNo [targets] section - Pkg.test() cannot find Test.")
    if test_in_deps:
        print("\nTest is in [deps] - it is test-only and will be moved to [extras].")

    if not args.apply:
        print("\nRun with --apply to fix.")
        return 1

    # ---- rewrite Project.toml ----
    lines, _, _ = parse_project()
    out: list[str] = []
    inserted = False
    i = 0
    while i < len(lines):
        line = lines[i]
        out.append(line)
        if line.strip() == "[deps]":
            # collect the existing block, merge, emit sorted
            block: dict[str, str] = {}
            i += 1
            while i < len(lines) and not lines[i].strip().startswith("["):
                st = lines[i].strip()
                if "=" in st:
                    k, v = st.split("=", 1)
                    block[k.strip()] = v.strip().strip('"')
                i += 1
            block.update(missing_stdlib)
            block.pop("Test", None)   # test-only; lives in [extras]
            for k in sorted(block):
                out.append(f'{k} = "{block[k]}"')
            out.append("")
            inserted = True
            continue
        i += 1

    body = "\n".join(out).rstrip() + "\n"

    if not has_test_target:
        body += (
            '\n[extras]\n'
            f'Test = "{STDLIB_UUIDS["Test"]}"\n'
            '\n[targets]\n'
            'test = ["Test"]\n'
        )

    PROJECT.write_text(body, encoding="utf-8", newline="\n")
    print(f"\nWrote {PROJECT.name}"
          f" (+{len(missing_stdlib)} deps"
          f"{', + test target' if not has_test_target else ''}).")

    print("Running Pkg.resolve()...")
    r = subprocess.run(
        ["julia", "--project=.", "-e", "using Pkg; Pkg.resolve()"],
        cwd=ROOT)
    if r.returncode != 0:
        print("Pkg.resolve() failed - see above.", file=sys.stderr)
        return 1

    print("\nNow check it loads:")
    print("   julia --project=. -e \"using IPE\"")
    return 0


if __name__ == "__main__":
    sys.exit(main())
