#!/usr/bin/env python3
"""
sprint.py - the only command you need.

    python sprint.py

Works out what state the project is in and does the right next thing:

    not published yet   ->  set up, create the GitHub repo, push, protect it
    patch in incoming/  ->  show it, apply it, verify, push, open a PR
    local edits         ->  show them, commit, push
    nothing to do       ->  show status and what is waiting on you

It always tells you what it is about to do and waits for you to say yes.
Nothing reaches GitHub without your confirmation.
"""

import datetime
import json
import re
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent
CONFIG_FILE = ROOT / ".publish-config.json"
INCOMING = ROOT / "incoming"
YEAR = datetime.date.today().year
TODAY = datetime.date.today().isoformat()

BOLD, DIM, RESET = "\033[1m", "\033[2m", "\033[0m"


# ---------------------------------------------------------------------------
# plumbing
# ---------------------------------------------------------------------------

def run(cmd: list[str], check: bool = False, capture: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, cwd=ROOT, text=True, check=check,
                          capture_output=capture)


def out(cmd: list[str]) -> str:
    try:
        r = run(cmd)
        return r.stdout.strip() if r.returncode == 0 else ""
    except Exception:
        return ""


def have(tool: str) -> bool:
    return shutil.which(tool) is not None


def title(msg: str) -> None:
    print(f"\n{BOLD}{msg}{RESET}")


def info(msg: str) -> None:
    print(f"   {msg}")


def bail(msg: str) -> None:
    sys.exit(f"\nSTOPPED: {msg}\n")


def confirm(question: str, default_yes: bool = True) -> bool:
    hint = "[Y/n]" if default_yes else "[y/N]"
    try:
        a = input(f"\n   {question} {hint}: ").strip().lower()
    except EOFError:
        bail("this script needs to ask questions. In VS Code use the Run button.")
    if not a:
        return default_yes
    return a.startswith("y")


def ask(prompt: str, default: str = "", validate=None) -> str:
    while True:
        suffix = f" [{default}]" if default else ""
        try:
            v = input(f"   {prompt}{suffix}: ").strip() or default
        except EOFError:
            bail("this script needs to ask questions. In VS Code use the Run button.")
        if not v:
            print("       (required)")
            continue
        if validate and (err := validate(v)):
            print(f"       {err}")
            continue
        return v


def valid_email(v):
    return None if re.match(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", v) else "that does not look like an email"


def valid_name(v):
    return None if re.match(r"^[A-Za-z0-9._-]+$", v) else "letters, numbers, dots, dashes, underscores"


# ---------------------------------------------------------------------------
# state
# ---------------------------------------------------------------------------

def sanity() -> None:
    if not (ROOT / "SOURCES.md").exists():
        bail(f"this script must live in the project folder. It is in: {ROOT}")
    if not (ROOT / ".git").exists():
        bail("no .git folder - the history is missing. Re-extract the archive.")
    if not have("git"):
        bail("git is not installed.")


def has_remote() -> bool:
    return bool(out(["git", "remote", "get-url", "origin"]))


def dirty() -> bool:
    """Uncommitted work, ignoring incoming patch files (which are working
    material and are gitignored, but be defensive in case that is edited)."""
    lines = out(["git", "status", "--porcelain"]).splitlines()
    return any(l for l in lines if "incoming/" not in l)


def patches() -> list[Path]:
    if not INCOMING.exists():
        return []
    return sorted(p for p in INCOMING.glob("*.patch"))


def branch() -> str:
    return out(["git", "rev-parse", "--abbrev-ref", "HEAD"]) or "main"


def repo_slug() -> str:
    url = out(["git", "remote", "get-url", "origin"])
    m = re.search(r"[:/]([^/]+/[^/]+?)(?:\.git)?$", url)
    return m.group(1) if m else ""


# ---------------------------------------------------------------------------
# checks
# ---------------------------------------------------------------------------

def ledger_check(fix: bool = False) -> bool:
    """Ledger provenance (numbers) and ADR evidence tiers (topology)."""
    ok = True
    gen = ROOT / "tools" / "ledger_to_julia.py"
    if gen.exists():
        args = [sys.executable, str(gen)] + ([] if fix else ["--check"])
        r = run(args)
        if r.returncode != 0:
            print(r.stdout or "", r.stderr or "")
            ok = False
        else:
            info(r.stdout.strip() or "ledger OK")

    clo = ROOT / "tools" / "check_closure.py"
    if clo.exists():
        r = run([sys.executable, str(clo)])
        if r.returncode != 0:
            print(r.stdout or "", r.stderr or "")
            ok = False
        else:
            info("closure OK")

    adr = ROOT / "tools" / "check_adrs.py"
    if adr.exists():
        r = run([sys.executable, str(adr)])
        if r.returncode != 0:
            print(r.stdout or "", r.stderr or "")
            ok = False
        else:
            info(r.stdout.strip() or "ADRs OK")
    return ok


def julia_tests() -> bool | None:
    """None = skipped."""
    if not have("julia"):
        return None
    info("running Julia tests (this can take a few minutes the first time)...")
    r = run(["julia", "--project=.", "-e", "using Pkg; Pkg.test()"], capture=False)
    return r.returncode == 0


# ---------------------------------------------------------------------------
# config
# ---------------------------------------------------------------------------

def gh_field(f: str) -> str:
    return out(["gh", "api", "user", "--jq", f".{f} // empty"]) if have("gh") else ""


def get_config() -> dict:
    if CONFIG_FILE.exists():
        return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))

    title("First run - a few questions")
    info("Looking up your details...")
    login = gh_field("login")
    name = out(["git", "config", "--global", "--get", "user.name"]) or gh_field("name")
    email = out(["git", "config", "--global", "--get", "user.email"]) or gh_field("email")
    if not email and login:
        uid = gh_field("id")
        email = f"{uid}+{login}@users.noreply.github.com" if uid else ""
    found = [k for k, v in (("name", name), ("email", email), ("username", login)) if v]
    info("found: " + (", ".join(found) if found else "nothing - please type them"))
    print()

    cfg = {
        "your_name": ask("Your full name", name),
        "your_email": ask("Your email", email, valid_email),
        "gh_owner": ask("GitHub username", login, valid_name),
        "gh_repo": ask("Repository name", "integrative-physiology-engine", valid_name),
    }
    print()
    info("The ledger has 8 placeholder rows with citations written from memory,")
    info("marked TODO-VERIFY. Published history is permanent.")
    cfg["strip_seed_rows"] = confirm("Remove them before publishing?", default_yes=False)

    CONFIG_FILE.write_text(json.dumps(cfg, indent=2), encoding="utf-8", newline="\n")
    return cfg


# ---------------------------------------------------------------------------
# actions
# ---------------------------------------------------------------------------

def do_preflight(cfg: dict) -> None:
    title("Preparing for publication")

    run(["git", "config", "user.name", cfg["your_name"]], check=True)
    run(["git", "config", "user.email", cfg["your_email"]], check=True)
    info(f'identity: {cfg["your_name"]} <{cfg["your_email"]}>')

    lic = ROOT / "LICENSE"
    if not lic.exists():
        try:
            with urllib.request.urlopen(
                    "https://www.apache.org/licenses/LICENSE-2.0.txt", timeout=20) as r:
                lic.write_text(r.read().decode("utf-8"), encoding="utf-8", newline="\n")
            info("LICENSE downloaded (Apache-2.0)")
        except Exception as e:
            info(f"!! could not fetch licence text ({e})")
            info("   GitHub can add one later: Add file > Create new file > LICENSE")

    (ROOT / "NOTICE").write_text(
        f"Integrative Physiology Engine\nCopyright {YEAR} {cfg['your_name']}\n\n"
        "This product includes software developed independently from published\n"
        "peer-reviewed literature. See SOURCES.md for the source whitelist policy.\n",
        encoding="utf-8", newline="\n")

    p = ROOT / "Project.toml"
    if p.exists():
        s = p.read_text(encoding="utf-8")
        p.write_text(re.sub(r'^authors = \[.*\]$',
                            f'authors = ["{cfg["your_name"]} <{cfg["your_email"]}>"]',
                            s, flags=re.M), encoding="utf-8", newline="\n")

    rd = ROOT / "README.md"
    s = rd.read_text(encoding="utf-8")
    s = re.sub(r"\*\*TODO before first push\.\*\*.*?separately accepted elsewhere\.",
               "Apache-2.0. See `LICENSE`. Chosen over MIT for its express patent grant\n"
               "and defensive termination clause.", s, flags=re.S)
    s = s.replace("TODO — CITATION.cff once the first release is tagged.",
                  "See `CITATION.cff`.")
    s = s.replace("> Rename this repository and this heading before first push.\n\n", "")
    rd.write_text(s, encoding="utf-8", newline="\n")

    (ROOT / "CITATION.cff").write_text(
        'cff-version: 1.2.0\nmessage: "If you use this software, please cite it as below."\n'
        'title: "Integrative Physiology Engine"\nabstract: >-\n'
        "  An independent implementation of whole-body integrative human physiology,\n"
        "  built from published peer-reviewed literature with full parameter provenance.\n"
        f'authors:\n  - name: "{cfg["your_name"]}"\n'
        f'repository-code: "https://github.com/{cfg["gh_owner"]}/{cfg["gh_repo"]}"\n'
        f'license: Apache-2.0\nversion: 0.0.1\ndate-released: "{TODAY}"\n',
        encoding="utf-8", newline="\n")
    info("NOTICE, CITATION.cff, README, Project.toml written")

    if cfg.get("strip_seed_rows"):
        led = ROOT / "ledger" / "parameters.csv"
        lines = led.read_text(encoding="utf-8").splitlines(keepends=True)
        kept = [l for l in lines if "SCAFFOLD SEED" not in l]
        led.write_text("".join(kept), encoding="utf-8", newline="\n")
        info(f"removed {len(lines)-len(kept)} placeholder ledger rows")

    if not ledger_check(fix=True):
        bail("ledger validation failed - fix the rows named above")


def show_changes() -> None:
    print()
    print(run(["git", "status", "--short"]).stdout, end="")
    print(run(["git", "diff", "--stat"]).stdout, end="")
    if confirm("Show the full diff?", default_yes=False):
        run(["git", "--no-pager", "diff"], capture=False)


def do_commit(msg: str) -> None:
    run(["git", "add", "-A"], check=True)
    run(["git", "commit", "-m", msg], check=True)
    info(f"committed: {msg}")


def do_publish(cfg: dict) -> None:
    title("Publishing to GitHub")
    slug = f'{cfg["gh_owner"]}/{cfg["gh_repo"]}'
    info(f"this will create a PUBLIC repository at github.com/{slug}")
    if not confirm("Create it and push?"):
        bail("nothing published")

    run(["git", "branch", "-M", "main"])
    if have("gh"):
        r = run(["gh", "repo", "create", slug, "--public", "--source=.", "--push",
                 "--description",
                 "Independent whole-body integrative human physiology model, "
                 "built from published literature with full parameter provenance."],
                capture=False)
        if r.returncode != 0:
            bail("gh repo create failed - see the message above")
    else:
        info("gh is not installed. Create an EMPTY public repo at github.com/new")
        info("(no README, no .gitignore, no licence), then run:")
        info(f"   git remote add origin https://github.com/{slug}.git")
        info("   git push -u origin main")
        return

    print()
    info(f"published: https://github.com/{slug}")
    info("The first CI run will show 'Ledger provenance' passing and")
    info("'Julia tests' failing. That is the expected starting state.")
    do_protect(cfg)


def do_protect(cfg: dict) -> None:
    title("Protecting the main branch")
    info("This blocks force-pushes and history rewriting, which is what makes")
    info("the provenance claim in SOURCES.md mechanically true rather than stated.")
    if not have("gh"):
        info("Needs gh. Otherwise do it on github.com: Settings > Rules > Rulesets.")
        return
    if not confirm("Apply branch protection now?"):
        info("skipped - you can run this script again later to apply it")
        return

    body = json.dumps({
        "required_status_checks": {"strict": True, "contexts": ["Ledger provenance"]},
        "enforce_admins": True,
        "required_pull_request_reviews": {"required_approving_review_count": 0,
                                          "dismiss_stale_reviews": True},
        "restrictions": None,
        "allow_force_pushes": False,
        "allow_deletions": False,
        "required_linear_history": True,
    })
    slug = repo_slug() or f'{cfg["gh_owner"]}/{cfg["gh_repo"]}'
    r = subprocess.run(["gh", "api", "-X", "PUT",
                        f"repos/{slug}/branches/main/protection",
                        "-H", "Accept: application/vnd.github+json", "--input", "-"],
                       cwd=ROOT, input=body, text=True, capture_output=True)
    if r.returncode == 0:
        info("protection applied")
    else:
        info("could not apply protection automatically:")
        info(f"   {r.stderr.strip()[:300]}")
        info("If it mentions the status check, wait for the first Actions run")
        info("to finish, then run this script again.")


def do_patch(cfg: dict, pats: list[Path]) -> None:
    title(f"{len(pats)} patch file(s) waiting in incoming/")
    for p in pats:
        info(f"  {p.name}")

    if dirty():
        bail("you have uncommitted edits. Commit or discard them first, "
             "then run this again.")

    r = run(["git", "apply", "--check"] + [str(p) for p in pats])
    if r.returncode != 0:
        print(r.stderr)
        bail("these patches do not fit the current code. They were made against an\n"
             "        older version - ask for them to be regenerated.")

    print()
    print(run(["git", "apply", "--stat"] + [str(p) for p in pats]).stdout, end="")
    for p in pats:
        for line in p.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("Subject:"):
                info(line.replace("Subject:", "  ").strip())

    if confirm("Show the full diff?"):
        for p in pats:
            run(["git", "--no-pager", "apply", "--stat", str(p)], capture=False)
            print(p.read_text(encoding="utf-8", errors="replace"))

    print()
    info("Applying adds your Signed-off-by. Authorship stays with whoever wrote it.")
    if not confirm("Apply and sign off?", default_yes=False):
        bail("nothing changed")

    br = f"sprint/{datetime.datetime.now():%Y%m%d-%H%M}"
    run(["git", "switch", "-c", br], check=True)
    r = run(["git", "am", "--signoff"] + [str(p) for p in pats], capture=False)
    if r.returncode != 0:
        run(["git", "am", "--abort"])
        run(["git", "switch", "-"])
        run(["git", "branch", "-D", br])
        bail("patch application failed - back on your previous branch, nothing changed")

    title("Verifying")
    if not ledger_check():
        info("ledger check FAILED - not pushing")
        info(f"discard with:  git switch main && git branch -D {br}")
        return
    t = julia_tests()
    if t is False:
        info("Julia tests FAILED - not pushing")
        info(f"discard with:  git switch main && git branch -D {br}")
        return
    if t is None:
        info("Julia not installed - skipping tests (CI will run them)")

    title("Pushing")
    if run(["git", "push", "-u", "origin", br], capture=False).returncode != 0:
        bail("push failed")
    for p in pats:
        p.unlink()
    if have("gh"):
        run(["gh", "pr", "create", "--fill", "--base", "main"], capture=False)
        info("PR opened. Merge it once CI is green:  gh pr merge --squash --delete-branch")
    else:
        info(f"pushed. Open a PR at https://github.com/{repo_slug()}/compare/{br}?expand=1")
    run(["git", "switch", "main"])


def show_status(cfg: dict) -> None:
    title("Status")
    info(f"repo:     {repo_slug() or 'not published'}")
    info(f"branch:   {branch()}")
    info(f"commits:  {out(['git', 'rev-list', '--count', 'HEAD'])}")
    info(f"julia:    {'installed' if have('julia') else 'NOT installed'}")
    ledger_check()
    print()
    info("Nothing waiting. To start a sprint, ask for work against")
    info(f"   https://github.com/{repo_slug()}")
    info("then drop the resulting .patch file into incoming/ and run this again.")


# ---------------------------------------------------------------------------

def main() -> None:
    sanity()
    print("=" * 66)
    print(f"  {BOLD}sprint{RESET}   {DIM}{ROOT.name}{RESET}")
    print("=" * 66)

    cfg = get_config()
    pats = patches()

    if not has_remote():
        info("This project has not been published yet.")
        if not confirm("Set it up and publish to GitHub now?"):
            bail("nothing done")
        do_preflight(cfg)
        show_changes()
        if confirm("Commit these and publish?"):
            do_commit("Pre-publication: licence, citation, authors")
            do_publish(cfg)
        return

    if pats:
        do_patch(cfg, pats)
        return

    if dirty():
        title("You have uncommitted changes")
        show_changes()
        if confirm("Commit and push them?"):
            msg = ask("Commit message", "Update")
            do_commit(msg)
            run(["git", "push"], capture=False)
        return

    show_status(cfg)


if __name__ == "__main__":
    main()
