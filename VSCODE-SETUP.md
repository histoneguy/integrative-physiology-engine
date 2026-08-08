# Working in VS Code (Windows)

No terminal required for any of this.

## One-off setup

1. **Extract the download.** In File Explorer, right-click `ipe-repo.tar` ->
   *Extract All* (Windows 11), or open PowerShell in your Downloads folder and run
   `tar -xzf ipe-repo.tar`. You should end up with a folder called `ipe`.

2. **Open it in VS Code.** File -> Open Folder -> select the `ipe` folder.
   Open the FOLDER, not an individual file - VS Code needs the folder to see the
   git history.

3. **Install the recommended extensions.** VS Code will prompt you bottom-right.
   Accept. (Python, Julia, and GitHub Pull Requests.)

4. **Sign in to GitHub.** Click the account icon at the bottom of the left bar ->
   *Sign in to GitHub*. A browser window handles it.

## Publishing

1. **Open `preflight.py`** from the file list and click the ▶ button at the top
   right. Nothing to edit - it asks you four questions in the terminal panel at the
   bottom: your name, your email, your GitHub username, and a repository name.
   Press Enter to accept anything shown in [brackets].

   Your answers are saved, so re-running it will not ask again.

3. **Review.** Click the Source Control icon in the left bar (or Ctrl+Shift+G).
   Every changed file is listed. Click any one to see exactly what changed,
   old on the left, new on the right.

4. **Commit.** Type a message in the box - *Pre-publication: licence, citation,
   authors* - and click the tick.

5. **Publish.** Click **Publish Branch**. VS Code asks whether to publish to a
   public or private repository. **Choose public.**

That is the whole thing. Steps 1-4 stay on your machine; only step 5 goes online.

## After publishing: protect the branch

This must be done on github.com. It stops the history being rewritten, which is what
makes the provenance claim in `SOURCES.md` mechanically true rather than merely
stated.

Go to your repository -> **Settings** -> **Rules** -> **Rulesets** -> **New ruleset**
-> *New branch ruleset*.

- Name: `main protection`
- Enforcement status: **Active**
- Target branches: *Add target* -> **Include default branch**
- Tick: **Restrict deletions**
- Tick: **Block force pushes**
- Tick: **Require a pull request before merging**, and set
  *Required approvals* to **0** (you are working alone; a PR is still required,
  a second person is not)
- Tick: **Require status checks to pass**, then *Add checks* -> `Ledger provenance`
  (this only appears after the first Actions run has finished)

Click **Create**.

## Day-to-day afterwards

- Source Control panel: stage, commit, push, all by clicking.
- The Julia tests will fail until someone with a Julia install works through them.
  That is the expected starting state, not a problem with your setup.
