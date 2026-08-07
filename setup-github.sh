#!/usr/bin/env bash
#
# Publish the IPE repository to GitHub.
#
#   1. Edit the CONFIG block below.
#   2. bash setup-github.sh preflight   # local changes, no network
#   3. Review the diff, then:
#      bash setup-github.sh publish     # create remote + push
#   4. Wait for the first Actions run to finish, then:
#      bash setup-github.sh protect     # branch protection
#
# Run from inside the extracted `ipe` directory.

set -euo pipefail

# ----------------------------------------------------------------------------
# CONFIG - edit these
# ----------------------------------------------------------------------------
GH_OWNER="YOUR-GITHUB-USERNAME"
GH_REPO="integrative-physiology-engine"
GIT_NAME="Your Name"
GIT_EMAIL="you@example.com"
AUTHOR_LINE="Your Name <you@example.com>"
COPYRIGHT_HOLDER="Your Name"
YEAR="$(date +%Y)"
# Set to 1 to delete the eight TODO-VERIFY scaffold rows from the ledger.
# Recommended: they carry citations written from memory, and git history is permanent.
STRIP_SEED_ROWS=0
# ----------------------------------------------------------------------------

die() { echo "ERROR: $*" >&2; exit 1; }

check_repo() {
  [[ -f SOURCES.md && -d .git ]] || die "run this from inside the ipe/ directory"
}

# ----------------------------------------------------------------------------
preflight() {
  check_repo
  command -v git >/dev/null || die "git not found"

  echo "==> git identity"
  git config user.name  "$GIT_NAME"
  git config user.email "$GIT_EMAIL"

  echo "==> LICENSE (Apache-2.0)"
  if [[ ! -f LICENSE ]]; then
    curl -fsSL https://www.apache.org/licenses/LICENSE-2.0.txt -o LICENSE \
      || die "could not fetch licence text; download it manually"
    cat > NOTICE <<EOF
Integrative Physiology Engine
Copyright ${YEAR} ${COPYRIGHT_HOLDER}

This product includes software developed independently from published
peer-reviewed literature. See SOURCES.md for the source whitelist policy.
EOF
  fi

  echo "==> Project.toml authors"
  sed -i.bak "s|^authors = \[\"TODO\"\]|authors = [\"${AUTHOR_LINE}\"]|" Project.toml
  rm -f Project.toml.bak

  echo "==> README licence section"
  python3 - <<'PY'
import pathlib, re
p = pathlib.Path("README.md"); s = p.read_text()
s = re.sub(
    r"\*\*TODO before first push\.\*\*.*?separately accepted elsewhere\.",
    "Apache-2.0. See `LICENSE`. Chosen over MIT for its express patent grant and\n"
    "defensive termination clause. Note that a permissive licence on this code says\n"
    "nothing about obligations a contributor may have accepted separately elsewhere.",
    s, flags=re.S)
s = s.replace("TODO — CITATION.cff once the first release is tagged.",
              "See `CITATION.cff`.")
p.write_text(s)
print("   README updated")
PY

  echo "==> CITATION.cff"
  cat > CITATION.cff <<EOF
cff-version: 1.2.0
message: "If you use this software, please cite it as below."
title: "Integrative Physiology Engine"
abstract: >-
  An independent implementation of whole-body integrative human physiology,
  built from published peer-reviewed literature with full parameter provenance.
authors:
  - name: "${COPYRIGHT_HOLDER}"
repository-code: "https://github.com/${GH_OWNER}/${GH_REPO}"
license: Apache-2.0
version: 0.0.1
date-released: "$(date +%F)"
EOF

  if [[ "$STRIP_SEED_ROWS" == "1" ]]; then
    echo "==> stripping scaffold seed rows from ledger"
    grep -v "SCAFFOLD SEED" ledger/parameters.csv > /tmp/led.csv
    mv /tmp/led.csv ledger/parameters.csv
    python3 tools/ledger_to_julia.py
  fi

  echo "==> verifying ledger/codegen consistency"
  python3 tools/ledger_to_julia.py --check

  echo "==> remaining TODOs (review these):"
  grep -rn "TODO" README.md Project.toml CITATION.cff 2>/dev/null || echo "   none"

  echo
  echo "Preflight done. Review with:  git diff"
  echo "Then:  git add -A && git commit -m 'Pre-publication: licence, citation, authors'"
}

# ----------------------------------------------------------------------------
publish() {
  check_repo
  git diff --quiet && git diff --cached --quiet || die "uncommitted changes; commit first"

  git branch -M main

  if command -v gh >/dev/null; then
    echo "==> creating public repo via gh"
    # --source=. --push wires the remote and pushes in one step.
    gh repo create "${GH_OWNER}/${GH_REPO}" --public --source=. --push \
      --description "Independent whole-body integrative human physiology model, built from published literature with full parameter provenance."
  else
    echo "gh not installed. Create an EMPTY public repo at:"
    echo "  https://github.com/new   (no README, no .gitignore, no licence)"
    echo "then run:"
    echo "  git remote add origin git@github.com:${GH_OWNER}/${GH_REPO}.git"
    echo "  git push -u origin main"
    exit 0
  fi

  echo
  echo "Pushed. Watch the first CI run:"
  echo "  gh run watch"
  echo "Expect: 'Ledger provenance' PASS, 'Julia tests' FAIL (Julia has never been run)."
  echo "Once that run has completed, run:  bash setup-github.sh protect"
}

# ----------------------------------------------------------------------------
protect() {
  command -v gh >/dev/null || die "gh CLI required for branch protection"

  echo "==> applying branch protection to main"
  # enforce_admins=true applies the rules to you as well. That is the point:
  # the provenance argument rests on history being append-only, so the owner
  # should not be able to bypass it either.
  # required_approving_review_count=0 still forces a PR but does not require a
  # second person, which is what you want on a solo project.
  gh api -X PUT "repos/${GH_OWNER}/${GH_REPO}/branches/main/protection" \
    -H "Accept: application/vnd.github+json" --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Ledger provenance"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 0,
    "dismiss_stale_reviews": true
  },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_linear_history": true,
  "required_conversation_resolution": true
}
JSON

  echo "==> verifying"
  gh api "repos/${GH_OWNER}/${GH_REPO}/branches/main/protection" \
    --jq '{force_push: .allow_force_pushes.enabled,
           deletions: .allow_deletions.enabled,
           linear: .required_linear_history.enabled,
           checks: .required_status_checks.contexts,
           admins: .enforce_admins.enabled}'

  echo
  echo "Done. From here, work on branches:"
  echo "  git switch -c subsystem/cardiovascular"
  echo "  ... commit ..."
  echo "  git push -u origin subsystem/cardiovascular"
  echo "  gh pr create --fill && gh pr merge --squash"
}

# ----------------------------------------------------------------------------
case "${1:-}" in
  preflight) preflight ;;
  publish)   publish ;;
  protect)   protect ;;
  *) echo "usage: bash setup-github.sh {preflight|publish|protect}"; exit 1 ;;
esac
