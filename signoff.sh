#!/usr/bin/env bash
#
# Review and sign off a generated patch series, then push it as a PR branch.
#
#   bash signoff.sh incoming/0001-whatever.patch [more.patch ...]
#
# What it does, in order:
#   1. Checks the patch applies cleanly (dry run, no state changed)
#   2. Shows you the diffstat and full diff
#   3. Waits for explicit confirmation
#   4. Applies with `git am --signoff` - your Signed-off-by is added, the
#      original authorship is preserved
#   5. Runs the ledger provenance check and the test suite
#   6. Pushes a branch and opens a PR
#
# Nothing is applied before step 3, and nothing is pushed if step 5 fails.

set -euo pipefail

BRANCH_PREFIX="${BRANCH_PREFIX:-patch}"
RUN_TESTS="${RUN_TESTS:-1}"      # set 0 to skip Julia tests (they will fail until
                                 # the toolchain work is done)

die() { echo "ERROR: $*" >&2; exit 1; }

[[ $# -ge 1 ]] || die "usage: bash signoff.sh <patch> [patch...]"
[[ -f SOURCES.md && -d .git ]] || die "run from inside the repo root"
command -v git >/dev/null || die "git not found"

# Signed-off-by needs a real identity
git config user.name  >/dev/null || die "git user.name not set"
git config user.email >/dev/null || die "git user.email not set"

# Refuse to operate on a dirty tree - a failed `git am` mid-series is much
# harder to unpick if there were uncommitted changes underneath it.
git diff --quiet && git diff --cached --quiet \
  || die "working tree is dirty; commit or stash first"

for p in "$@"; do [[ -f "$p" ]] || die "no such patch: $p"; done

# ---------------------------------------------------------------------------
echo "==> checking patches apply cleanly (dry run)"
git apply --check --verbose "$@" 2>&1 | sed 's/^/    /' \
  || die "patches do not apply cleanly against $(git rev-parse --short HEAD)

The patch was generated against a different base. Either fetch the base it was
made from, or ask for a regenerated series against $(git rev-parse --short HEAD)."

# ---------------------------------------------------------------------------
echo
echo "==> summary"
git apply --stat "$@" | sed 's/^/    /'
echo
echo "==> commits in this series"
grep -h "^Subject:" "$@" | sed 's/^Subject: /    /'

echo
read -r -p "Show full diff? [Y/n] " ans
[[ "${ans,,}" == "n" ]] || git apply --numstat --summary "$@" >/dev/null && {
  # shellcheck disable=SC2002
  cat "$@" | ${PAGER:-less -R}
}

# ---------------------------------------------------------------------------
echo
echo "Signing off means you take responsibility for this change (DCO)."
echo "Authorship stays with whoever generated it; your Signed-off-by is added."
read -r -p "Apply and sign off? [y/N] " ans
[[ "${ans,,}" == "y" ]] || { echo "Aborted. Nothing changed."; exit 0; }

# ---------------------------------------------------------------------------
BRANCH="${BRANCH_PREFIX}/$(date +%Y%m%d-%H%M%S)"
echo "==> branching $BRANCH"
git switch -c "$BRANCH"

echo "==> applying with signoff"
if ! git am --signoff "$@"; then
  echo
  echo "git am failed mid-series. To recover:"
  echo "    git am --abort && git switch - && git branch -D $BRANCH"
  exit 1
fi

# ---------------------------------------------------------------------------
echo "==> ledger provenance check"
python3 tools/ledger_to_julia.py --check || {
  echo
  echo "Ledger check FAILED. The branch exists but will not be pushed."
  echo "Either fix the ledger and amend, or discard:"
  echo "    git switch - && git branch -D $BRANCH"
  exit 1
}

if [[ "$RUN_TESTS" == "1" ]] && command -v julia >/dev/null; then
  echo "==> julia tests"
  julia --project=. -e 'using Pkg; Pkg.test()' || {
    echo
    echo "Tests FAILED. Branch not pushed. Discard with:"
    echo "    git switch - && git branch -D $BRANCH"
    exit 1
  }
else
  echo "==> skipping julia tests (RUN_TESTS=$RUN_TESTS, julia present: $(command -v julia >/dev/null && echo yes || echo no))"
fi

# ---------------------------------------------------------------------------
echo "==> pushing $BRANCH"
git push -u origin "$BRANCH"

if command -v gh >/dev/null; then
  echo "==> opening PR"
  gh pr create --fill --base main
  echo
  echo "PR opened. Merge when CI is green:"
  echo "    gh pr merge --squash --delete-branch"
else
  echo
  echo "Pushed. Open a PR at:"
  echo "    https://github.com/$(git remote get-url origin | sed -E 's#.*[:/]([^/]+/[^/]+?)(\.git)?$#\1#')/compare/$BRANCH?expand=1"
fi

git switch main >/dev/null 2>&1 || true
echo "Done. Back on main."
