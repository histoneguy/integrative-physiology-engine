# Start here

One command does everything:

    python sprint.py

Run it from VS Code: open `sprint.py`, click the ▶ button (top right).

It works out what needs doing and asks before doing it.

---

## Reading CI

After every push, go to **Actions** on GitHub. Two workflows run:

- **CI** — gates the build. Ledger provenance and ADR evidence tiers pass; Julia
  tests will fail until the toolchain work is done. That is expected.
- **Diagnostics** — never fails, always reports. Click it, then **Summary**.

The Diagnostics summary answers the questions that cannot be settled by reading
code: does the package load, does structural simplification work and how many
states does it remove, does the closed loop integrate and settle, is the solve
linear-algebra bound (which settles ADR 0003), where does the Jacobian spectrum
sit, and which parameters rest on a weak basis.

**The first runs will fail.** That is the point — they will say exactly where.
Paste the summary and it can be worked from directly.

## The sprint loop

**1. Ask for work.** Point at the repo:

> Clone github.com/YOU/YOUR-REPO and add the cardiovascular coupling set.

The ADRs in `docs/adr/` carry the reasoning, so no other context is needed.

**2. Save the script.** Put the `apply-*.py` file anywhere in the project folder.

**3. Run it.**

    python apply-whatever.py

It finds the repo root itself, shows what changes, waits for you to say yes,
applies with your sign-off, runs the provenance checks, and offers to push and
open a pull request. Nothing is pushed unless the checks pass.

The patch is embedded in the script, so there is no separate file to place and
no line-ending risk.

That is the whole loop.

---

## What it does in each situation

| Situation | What happens |
|---|---|
| Not published yet | Sets up licence and citation, creates the public repo, pushes, protects `main` |
| Patch in `incoming/` | Shows it, applies with sign-off, verifies, pushes, opens a PR |
| You edited files | Shows the diff, commits, pushes |
| Nothing waiting | Prints status |

It never touches GitHub without asking first.

---

## First run

It asks four things, filling in defaults from your GitHub account:

- your name
- your email
- your GitHub username
- a repository name

Answers are saved to `.publish-config.json`. It will not ask again.

---

## If something goes wrong

**"patches do not fit the current code"** — the patch was made against an older
version. Ask for it to be regenerated.

**"you have uncommitted edits"** — run `python sprint.py` on its own first to commit
them, then apply the patch.

**"could not apply protection"** — branch protection needs one CI run to have
finished. Wait a couple of minutes, run the script again.

**Julia tests fail** — expected until someone with Julia installed works through
them. The script skips them if Julia is absent; CI reports them either way.

Nothing the script does before the confirmation prompt reaches the internet, and
everything it changes locally shows up in VS Code's Source Control panel first.
