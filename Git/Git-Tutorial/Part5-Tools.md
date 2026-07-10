Here's **Git Mastery - Part 5: Time Travel & Recovery** in full:

---

## Part 5: Time Travel & Recovery

**Series:** Mastering Version Control | **Prev:** Part 4 — Deployment 101: GitHub Pages | **Next:** Part 6 — Professional Pipelines

---

### 1. Concept Explanation

#### 1.1 The core professional mindset: Git rarely, truly loses data

Beginners fear Git because it feels like mistakes are permanent. The opposite is true: **almost nothing in Git is truly gone until it's garbage-collected weeks later, and even then there are ways back.** Every commit you ever make (even ones you later "undo") remains reachable in Git's internal object database for a long time, tracked by the `reflog`. Understanding this turns panic into "let me check the reflog" — a genuinely career-changing shift.

#### 1.2 `git log` — reading history properly

```bash
git log                      # full detail: author, date, message, hash
git log --oneline            # condensed
git log --oneline --graph --all   # visual branch structure across ALL branches
git log --stat                # shows which files changed + line counts per commit
git log -p                    # shows the full diff per commit
git log --author="Jane"       # filter by author
git log --since="2 weeks ago" # filter by date
git log -- path/to/file.js    # history of ONE file specifically
```

#### 1.3 `git reset` — moving the branch pointer (rewriting local history)

`reset` moves your current branch's pointer to a different commit. It has three modes, differing in what happens to your working directory and staging area:

| Mode | Moves branch pointer | Staging area | Working directory | When to use |
|---|---|---|---|---|
| `--soft` | Yes | Keeps changes staged | Untouched | "Undo my last commit(s) but keep everything staged, ready to re-commit differently" |
| `--mixed` (default) | Yes | Unstages changes | Untouched (files keep their edits) | "Undo commits AND unstage, but keep my edits to redo the add/commit" |
| `--hard` | Yes | Cleared | **Reverted to match the target commit — uncommitted changes are DESTROYED** | Only when you are certain you want to discard changes entirely |

> **`--hard` is the single most dangerous common Git command.** It silently deletes uncommitted work with no confirmation prompt. Always run `git status` and consider `git stash` (below) before using it.

**Critical rule:** never `reset` commits that have already been pushed and that others may have pulled — you'd be erasing shared history out from under your teammates. For already-shared history, use `revert` instead (next section).

#### 1.4 `git revert` — the safe, public undo

`revert` doesn't remove a commit — it creates a **new commit that applies the inverse of an old commit's changes.** History moves forward, nothing is erased, which makes it safe for commits that are already pushed/shared.

```
Before:  A ─ B ─ C   (C introduced a bug)
After:   A ─ B ─ C ─ C'   (C' undoes exactly what C did)
```

**Rule of thumb:** `reset` for local, not-yet-shared mistakes. `revert` for anything already pushed to a shared branch.

#### 1.5 `git stash` — the temporary shelf

`stash` takes your uncommitted changes (staged and/or unstaged) and tucks them away on a hidden stack, giving you a clean working directory — without committing anything. Classic use case: you're mid-feature when you're asked to urgently fix something on `main`.

```
Working directory (dirty) ──git stash──▶ [stash stack]  ──git stash pop──▶ Working directory restored
```

#### 1.6 The `reflog` — your safety net of last resort

`git reflog` records every place `HEAD` has pointed, including commits that are no longer reachable from any branch (e.g., after a `reset --hard` or a deleted branch). This is how you recover from almost any local mistake.

---

### 2. Implementation — Step-by-Step Terminal Commands

#### 2.1 Undoing an uncommitted change (before staging)

```bash
# Discard changes to a specific file back to last commit
git checkout -- app.js
# Modern equivalent (Git 2.23+):
git restore app.js
```

#### 2.2 Unstaging a file (staged, but not yet committed)

```bash
git restore --staged app.js
# older syntax you'll see: git reset app.js
```

#### 2.3 Fixing your most recent commit (message or forgotten file)

```bash
# Just fix the message of the last commit:
git commit --amend -m "fix(auth): correct typo in error message"

# Forgot to include a file in the last commit?
git add forgotten-file.js
git commit --amend --no-edit    # keeps the same message, adds the file
```

> **Warning:** `--amend` rewrites the last commit's hash. Never amend a commit that's already been pushed and pulled by teammates — same rule as `reset`.

#### 2.4 Undoing commits with `reset` (local, unshared work only)

```bash
# Undo the last 2 commits, but keep their changes staged (ready to re-commit)
git reset --soft HEAD~2

# Undo the last commit, unstage the changes (edits remain in your files)
git reset HEAD~1

# Nuclear option: discard the last commit AND its changes completely
git reset --hard HEAD~1
```

#### 2.5 Undoing a commit safely on a shared branch

```bash
git log --oneline
# a1b2c3d  feat: add broken payment validation   <- this one's bad, and it's already on main/pushed

git revert a1b2c3d
# Opens an editor for the revert commit message — save and close
git push
```

If reverting a merge commit specifically:

```bash
git revert -m 1 <merge-commit-hash>
# -m 1 tells Git which parent line to consider "mainline" when inverting
```

#### 2.6 Using stash to switch context quickly

```bash
# Mid-feature, uncommitted changes everywhere, urgent bug reported on main
git stash push -m "WIP: half-finished checkout form"

git switch main
# ...fix the urgent bug, commit, push...

git switch feature/checkout-form
git stash list
git stash pop
# Your half-finished work is back exactly as you left it
```

```bash
git stash list                 # see all stashes
git stash show -p stash@{0}    # preview a stash's diff without applying it
git stash drop stash@{0}       # delete a specific stash without applying it
git stash apply stash@{0}      # apply but keep it in the stash list (vs pop, which removes it)
```

#### 2.7 The reflog rescue — recovering "lost" commits

```bash
# Scenario: you ran git reset --hard and now panic-realize you needed that commit
git reflog
# Example output:
# a1b2c3d HEAD@{0}: reset: moving to HEAD~1
# e4f5g6h HEAD@{1}: commit: feat: the commit you thought you lost

# Recover it — create a new branch pointing at the "lost" commit
git branch recovery-branch e4f5g6h

# Or reset your current branch straight back onto it
git reset --hard e4f5g6h
```

This works because `git reset --hard` only *moves the pointer* — the old commit object itself still physically exists in `.git/objects` until garbage collection (which defaults to ~90 days for unreachable commits).

#### 2.8 Recovering a deleted branch

```bash
git reflog | grep "checkout"
# find the commit hash the deleted branch was pointing at, then:
git branch resurrected-branch <hash>
```

---

### 3. Practice Exercise

**Step 1:** Make 3 commits to a test file in a scratch repo. Use `git reset --soft HEAD~1` to undo the last one, confirm with `git status` that the changes are staged, then re-commit with a better message.

**Step 2:** Make an uncommitted change, `git stash` it, confirm `git status` is clean, then `git stash pop` it back.

**Step 3:** Deliberately break something: commit a "bad" change, then immediately `git reset --hard HEAD~1` to discard it — but pretend you change your mind. Use `git reflog` to find and recover that commit onto a new branch called `rescued`.

**Step 4:** Simulate a shared-history mistake: commit a bad change, and this time undo it with `git revert` instead of `reset`, confirming the bad commit still visibly exists in `git log` (as expected — revert doesn't erase, it counters).

---

### 4. Solution & Explanation

```bash
mkdir time-travel-practice && cd time-travel-practice
git init
echo "line1" > notes.txt && git add . && git commit -m "commit 1"
echo "line2" >> notes.txt && git add . && git commit -m "commit 2"
echo "line3" >> notes.txt && git add . && git commit -m "commit 3 - oops typo"

# Step 1
git reset --soft HEAD~1
git status   # notes.txt change is staged, not committed
git commit -m "feat: add line3 with corrected message"

# Step 2
echo "temp idea" >> scratch.txt
git status          # scratch.txt untracked/dirty
git stash push -m "temp idea WIP"
git status          # clean
git stash pop
cat scratch.txt     # "temp idea" is back

# Step 3
echo "bad-line" >> notes.txt
git add . && git commit -m "commit 4 - accidentally bad"
git reset --hard HEAD~1     # "oops, didn't mean to discard that"
git reflog                  # find the hash for "commit 4 - accidentally bad"
git branch rescued <hash-from-reflog>
git log rescued --oneline   # confirms the "lost" commit is safely recovered

# Step 4
echo "bad-feature" >> notes.txt
git add . && git commit -m "feat: bad feature that needs undoing"
git revert HEAD --no-edit
git log --oneline
# Shows BOTH the original bad commit AND the new revert commit —
# history is honest about what happened, nothing was erased
```

**Why this is correct:** Step 3 demonstrates the single most important safety fact in all of Git: a `reset --hard` looks destructive but the commit object survives in the object database, discoverable via `reflog`, until it's eventually garbage collected. Step 4 demonstrates the professional distinction between `reset` (rewrites history — local/unshared only) and `revert` (adds new history — safe for anything already pushed). Internalizing "reflog is my safety net, revert is my public undo button" removes almost all fear of working with Git day-to-day.

---

**Next up:** Part 6 — rebasing vs. merging like a senior engineer, and scaling your deployment skills from GitHub Pages to a fully automated Vercel CI/CD pipeline for dynamic apps.

Want **Part 6** next?
