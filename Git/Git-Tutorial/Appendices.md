## Appendices

Series: Mastering Version Control | Prev: Part 6, Professional Pipelines

---

### Appendix A: The Git Cheat Sheet

| Command | What it does | Common example |
|---|---|---|
| `git init` | Create a new local repository in the current folder | `git init` |
| `git clone <url>` | Copy an existing remote repository to your machine | `git clone git@github.com:user/repo.git` |
| `git status` | Show staged, unstaged, and untracked changes | `git status` |
| `git add` | Move changes from working directory to staging area | `git add file.js` / `git add .` |
| `git commit` | Save a permanent snapshot of the staging area | `git commit -m "feat: add login form"` |
| `git commit --amend` | Modify the most recent commit (message and/or contents) | `git commit --amend -m "fix typo"` |
| `git branch` | List, create, or delete branches | `git branch feature/x` / `git branch -d feature/x` |
| `git switch` | Change your current branch (modern) | `git switch main` / `git switch -c feature/x` |
| `git checkout` | Older multi-purpose command: switch branches, restore files, or detach HEAD | `git checkout feature/x` |
| `git merge` | Combine another branch's history into your current branch | `git merge feature/x` |
| `git rebase` | Replay your branch's commits on top of another branch | `git rebase main` |
| `git rebase -i` | Interactively edit, squash, reorder, or drop commits | `git rebase -i HEAD~3` |
| `git push` | Upload local commits to a remote | `git push origin main` / `git push -u origin feature/x` |
| `git pull` | Download and merge remote changes into your current branch | `git pull` |
| `git fetch` | Download remote changes WITHOUT merging them | `git fetch origin` |
| `git stash` | Temporarily shelve uncommitted changes | `git stash push -m "wip"` / `git stash pop` |
| `git log` | View commit history | `git log --oneline --graph --all` |
| `git diff` | Show unstaged differences | `git diff` / `git diff --staged` |
| `git reset` | Move the current branch pointer (optionally touching staging/working dir) | `git reset --soft HEAD~1` |
| `git revert` | Create a new commit that undoes an earlier commit | `git revert <hash>` |
| `git reflog` | Show a log of everywhere HEAD has pointed, including "lost" commits | `git reflog` |
| `git remote` | Manage connections to remote repositories | `git remote add origin <url>` / `git remote -v` |
| `git tag` | Mark a specific commit as a release point | `git tag v1.0.0` |
| `git show` | Show the full diff and metadata of a single commit | `git show <hash>` |
| `git blame` | Show who last modified each line of a file, and in which commit | `git blame file.js` |

---

### Appendix B: Troubleshooting Dictionary

**"You are in 'detached HEAD' state"**
- Cause: you checked out a specific commit hash or tag instead of a branch, so `HEAD` points directly at a commit rather than at a branch pointer.
- Fix: if you want to keep any new commits made in this state, create a branch right now: `git switch -c rescue-branch`. If you don't need to keep anything, just switch back: `git switch main`.

**"Your branch is ahead of / behind 'origin/main' by N commits"**
- Ahead: you have local commits not yet pushed. Fix: `git push`.
- Behind: the remote has commits you don't have locally. Fix: `git pull`.
- Diverged (both ahead and behind): fix with `git pull` (which merges) or `git pull --rebase` (which rebases your local commits on top), then resolve any conflicts.

**"Updates were rejected because the remote contains work that you do not have locally"**
- Cause: someone else pushed to the same branch since you last synced.
- Fix: `git pull` first (merge or rebase in the conflicts if any), then `git push` again. Never use `git push --force` on a shared branch to bypass this — you would overwrite a teammate's commits.

**"I committed with the wrong message"**
- If it's the very last commit and NOT yet pushed: `git commit --amend -m "correct message"`.
- If it's already pushed to a shared branch: leave it — amending and force-pushing shared history is disruptive. Optionally follow up with a normal commit clarifying the correction, or coordinate with your team before force-pushing.

**"I need to undo my last commit but keep the changes"**
- `git reset --soft HEAD~1` (keeps changes staged) or `git reset HEAD~1` (keeps changes unstaged, in your working files).

**"I need to fully discard my last commit and its changes"**
- `git reset --hard HEAD~1` — use with caution, this destroys uncommitted work permanently unless recovered via `git reflog`.

**"I accidentally deleted a branch"**
- `git reflog`, find the last commit hash the branch pointed to, then `git branch recovered-branch <hash>`.

**MERGE CONFLICT: "Automatic merge failed; fix conflicts and then commit the result"**
- Run `git status` to see which files conflict. Open each file, look for `<<<<<<<`, `=======`, `>>>>>>>` markers, manually choose/combine the correct content, delete all marker lines, then `git add <file>` and `git commit`.
- To back out entirely: `git merge --abort`.

**REBASE CONFLICT: rebase pauses mid-way**
- Same resolution as a merge conflict, but finish with `git rebase --continue` instead of `git commit`. To back out: `git rebase --abort`.

**"fatal: refusing to merge unrelated histories"**
- Cause: usually happens when you `git init` locally AND create a repo with a README on GitHub, then try to connect them — two repos with no shared commit ancestor.
- Fix: `git pull origin main --allow-unrelated-histories`, resolve any conflicts, then push.

**"Permission denied (publickey)" when pushing**
- Cause: SSH key not set up or not added to your GitHub account.
- Fix: revisit Part 3, Section 2.2 — generate a key with `ssh-keygen`, add it via `ssh-add`, and paste the public key into GitHub Settings → SSH and GPG keys.

**"I committed a secret / API key by accident"**
- Removing the file in a new commit is NOT enough — it still exists in earlier commit history.
- If NOT yet pushed: `git reset --soft HEAD~1`, remove the secret from the file, re-commit.
- If already pushed: immediately revoke/rotate the leaked secret at its source (this is non-negotiable — assume it's compromised), then use `git filter-repo` (recommended, install via pip/brew) or the older `git filter-branch` / BFG Repo-Cleaner to strip it from all history, then force-push and have all collaborators re-clone.

**"My `git push` to gh-pages branch seems to have wiped its history"**
- This is often expected — the `gh-pages` npm package intentionally force-pushes a fresh orphan branch of build output each time, since that branch holds only generated files, not source. Your real source history on `main` is untouched.

**"GitHub Pages site shows 404 or old content after deploying"**
- Check Settings → Pages to confirm the correct branch/folder is selected as the source.
- GitHub Pages builds can take 1–2 minutes; check the "Actions" tab (if using Actions deployment) for build/deploy status and errors.
- Hard-refresh or check in an incognito window — browser caching of static assets is a very common false alarm.

**"Vercel preview deployment failed"**
- Check the deployment's build logs in the Vercel dashboard — almost always a missing environment variable, a lint/type error, or a dependency not listed in `package.json`.

---

### Appendix C: Deployment Strategy Matrix — GitHub Pages vs. Vercel

| Consideration | GitHub Pages | Vercel |
|---|---|---|
| **Content type** | Static files only (HTML, CSS, client-side JS) | Static AND dynamic — SSR, API routes, edge/serverless functions |
| **Server-side code** | Not supported at all | Fully supported (Node.js serverless/edge functions) |
| **Frameworks best suited** | Plain HTML/CSS/JS, static site generators (Jekyll, Hugo, Astro static, Vite static build), documentation sites | Next.js (first-class support), and any framework needing SSR/ISR, API routes, or backend logic |
| **Database / auth / secrets** | Not possible — no server to hold or use secrets | Fully supported, with scoped Environment Variables per environment |
| **Cost (typical hobby use)** | Free, unlimited for public repos | Free hobby tier, generous limits; paid tiers for teams/heavy traffic |
| **Custom domains** | Supported via CNAME file + DNS | Supported, simpler dashboard-driven setup |
| **Preview deployments per PR** | Not built-in (would need a custom Actions workflow) | Built-in, automatic, and a core selling point |
| **Deployment trigger** | Push to configured branch/folder | Push to any branch (preview) or production branch (production) |
| **Build step required?** | Optional — none needed for plain HTML/CSS/JS; needed for frameworks/generators | Effectively always — Vercel runs your `build` command automatically |
| **Rollbacks** | Manual (revert the commit / redeploy an older commit) | One-click instant rollback to any previous deployment in the dashboard |
| **When to choose this** | A resume site, project documentation, a marketing landing page, an open-source project's docs, any purely static output | Any app with a backend: authentication, a database, dynamic per-request rendering, API endpoints, or anything built with the Next.js App Router beyond a static export |

**Decision rule of thumb:** if your project could be zipped up and opened directly in a browser with no server running, GitHub Pages is sufficient and free forever. The moment your app needs to *compute* something per request — check a session, query a database, call a paid API with a secret key — you need Vercel (or an equivalent platform that executes server-side code).
