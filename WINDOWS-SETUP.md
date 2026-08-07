# Publishing this repo from Windows

You need three tools. Check what you already have by opening **Git Bash** (installed
with Git for Windows) and running:

    git --version
    gh --version
    python --version

Anything that errors, install below. Anything that prints a version, skip.

## Install what's missing

Open **PowerShell** (not Git Bash) for these:

    winget install --id Git.Git -e
    winget install --id GitHub.cli -e
    winget install --id Python.Python.3.12 -e

Close and reopen your terminals afterwards so PATH updates.

If `winget` isn't available: git-scm.com/download/win, cli.github.com, python.org
(tick **Add Python to PATH** in the installer).

## Sign in to GitHub

In Git Bash:

    gh auth login

Choose: GitHub.com -> HTTPS -> authenticate via browser. This stores credentials so
`git push` won't prompt you.

## Run the publication steps

**Use Git Bash, not PowerShell or CMD** - these are bash scripts.

    cd ~/Downloads
    tar -xzf ipe-repo.tar.gz
    cd ipe

Edit the CONFIG block at the top of `setup-github.sh` (Notepad is fine - it's the
first six lines: your GitHub username, repo name, your name and email).

Then:

    bash setup-github.sh preflight
    git diff
    git add -A && git commit -m "Pre-publication: licence, citation, authors"
    bash setup-github.sh publish
    gh run watch
    bash setup-github.sh protect

## If something goes wrong

**`$'\r': command not found`** - the script got Windows line endings. Fix:

    sed -i 's/\r$//' setup-github.sh

**`python: command not found`** - Python isn't on PATH. Reinstall from python.org
with "Add Python to PATH" ticked, then reopen Git Bash.

**`gh: command not found`** - reopen Git Bash after installing; PATH updates only
apply to new terminals.

**Nothing is destroyed by a failed run.** `preflight` only touches local files and
`git diff` shows you exactly what changed. Only `publish` reaches the internet.
