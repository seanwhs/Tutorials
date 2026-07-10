## Part 2: Branching & Merging

**Series:** Mastering Version Control | **Prev:** Part 1 — The Git Philosophy | **Next:** Part 3 — The GitHub Workflow

---

### 1. Concept Explanation

#### 1.1 What a branch actually is

A branch is **just a movable pointer to a commit**. That's it — not a copy of your files, not a separate folder. When you run `git branch feature/login`, Git creates a tiny pointer file. When you commit while on that branch, the pointer moves forward to the new commit. This is why branching in Git is instant and cheap — unlike older systems (SVN) where branching meant physically copying the whole codebase.

`HEAD` is a special pointer that tracks *which branch you're currently on* (or, in "detached HEAD" state, a specific commit — see Appendix B).

```
main:      A ─── B ─── C
                        └── feature/login: D ─── E
                                                    ▲
                                                   HEAD
```

#### 1.2 Why feature branches exist

The core rule of professional Git workflows: **`main` (or `master`) should always be deployable.** You never write new, unproven code directly on `main`. Instead:

1. Branch off `main` for every distinct feature, fix, or experiment.
2. Do your work — commit freely — on that branch.
3. Merge back into `main` only when the work is complete and reviewed.

This isolates risk. If your feature branch is a disaster, you delete the branch and `main` never knew it happened.

#### 1.3 Linear history vs. merge commits

There are two shapes your history can take when you bring a branch back into `main`:

- **Merge commit** (`git merge`): creates a new commit with two parents, preserving the fact that a branch existed and joining the two histories. History becomes a graph, not a line.
- **Linear/fast-forward or rebase-based history**: `main`'s pointer is simply moved forward, or commits are replayed on top of `main` one-by-one, producing a straight line with no merge commit.

```
Merge commit result:                  Fast-forward result:
A ─ B ─ C ─────── M   (main)          A ─ B ─ C ─ D ─ E   (main)
     \           /
      D ─ E ──────  (feature)
```

Neither is universally "correct" — teams pick a convention (we cover rebase vs. merge trade-offs in depth in Part 6). For now: **merge is the safe default for beginners** because it never rewrites commits that already exist.

#### 1.4 What a merge conflict actually is

A merge conflict happens when Git cannot automatically decide how to combine two changes because **both branches touched the same lines of the same file** in incompatible ways. Git is not confused about *what* changed — it's refusing to *guess* which version you want. Resolving a conflict is you, the human, making that judgment call.

---

### 2. Implementation — Step-by-Step Terminal Commands

#### 2.1 Creating and switching branches

```bash
# See existing branches (asterisk = current branch)
git branch

# Create a new branch AND switch to it in one step (modern syntax)
git switch -c feature/add-navbar
# Older/equivalent syntax you'll see in tutorials: git checkout -b feature/add-navbar

# Confirm
git branch
```

#### 2.2 Doing work on the branch

```bash
echo "<nav>Home | About | Contact</nav>" >> index.html
git add index.html
git commit -m "feat: add site navbar markup"

echo "nav { display: flex; gap: 1rem; }" >> styles.css
git add styles.css
git commit -m "style: flex layout for navbar"

git log --oneline --graph --all
# --graph draws the branch structure in the terminal, --all shows every branch
```

#### 2.3 Merging the feature branch back into main

```bash
# Switch back to main first — you always merge INTO your current branch
git switch main

# Bring feature/add-navbar's commits into main
git merge feature/add-navbar

# If it fast-forwards cleanly, you'll see "Fast-forward" in the output.
# Confirm history
git log --oneline --graph

# Clean up — delete the branch now that it's merged
git branch -d feature/add-navbar
```

#### 2.4 Creating a REAL merge conflict on purpose (so you're not afraid of one)

```bash
# On main, make a change to a shared line
git switch main
echo "<title>My Site</title>" > conflict-demo.html
git add conflict-demo.html
git commit -m "feat: add page title on main"

# Branch off, then diverge main further AFTER branching
git switch -c feature/update-title
echo "<title>My Awesome Site</title>" > conflict-demo.html
git add conflict-demo.html
git commit -m "feat: update title wording on feature branch"

git switch main
echo "<title>My Site | Official</title>" > conflict-demo.html
git add conflict-demo.html
git commit -m "feat: update title wording on main"

# Now try to merge — this WILL conflict because both branches
# changed the same line of conflict-demo.html differently
git merge feature/update-title
```

You'll see:
```
Auto-merging conflict-demo.html
CONFLICT (content): Merge conflict in conflict-demo.html
Automatic merge failed; fix conflicts and then commit the result.
```

#### 2.5 Resolving the conflict

```bash
git status
# Shows conflict-demo.html listed under "Unmerged paths"

code conflict-demo.html
```

The file now contains conflict markers:

```html
<<<<<<< HEAD
<title>My Site | Official</title>
=======
<title>My Awesome Site</title>
>>>>>>> feature/update-title
```

- Everything between `<<<<<<< HEAD` and `=======` is **your current branch's version** (`main`).
- Everything between `=======` and `>>>>>>> feature/update-title` is the **incoming branch's version**.

Manually edit the file to the version you actually want (you decide — that's the whole point), removing ALL the marker lines:

```html
<title>My Site | Official</title>
```

Then finish the merge:

```bash
git add conflict-demo.html
git commit -m "merge: resolve title wording conflict, keep official branding"

git log --oneline --graph
git branch -d feature/update-title
```

> **Tip:** VS Code's Source Control panel gives you clickable "Accept Current / Accept Incoming / Accept Both" buttons for conflicts — extremely helpful as a beginner, but understand what it's doing under the hood using the method above at least once.

#### 2.6 Aborting a merge you're not ready for

```bash
# If a conflict appears and you want to bail out entirely and try later:
git merge --abort
# This returns you to the exact state before you ran `git merge`.
```

---

### 3. Practice Exercise

**Step 1:** In a fresh repo, create `main` with one file `app.js` containing `console.log("v1");` and commit it.

**Step 2:** Create a branch `feature/greeting` and change the line to `console.log("Hello, World!");`, commit.

**Step 3:** Switch back to `main` and, WITHOUT merging yet, change the same line to `console.log("v2 - production");`, commit.

**Step 4:** Merge `feature/greeting` into `main` and resolve the resulting conflict by keeping a combined message: `console.log("v2 - production - Hello, World!");`.

**Step 5:** Confirm with `git log --oneline --graph` that the merge commit has two parent lines feeding into it.

---

### 4. Solution & Explanation

```bash
mkdir branching-practice && cd branching-practice
git init
echo 'console.log("v1");' > app.js
git add app.js
git commit -m "feat: initial app entry point"

git switch -c feature/greeting
echo 'console.log("Hello, World!");' > app.js
git add app.js
git commit -m "feat: change greeting message"

git switch main
echo 'console.log("v2 - production");' > app.js
git add app.js
git commit -m "feat: bump app to v2 production message"

git merge feature/greeting
# CONFLICT (content): Merge conflict in app.js

code app.js
# Manually replace conflict markers with:
# console.log("v2 - production - Hello, World!");

git add app.js
git commit -m "merge: combine v2 production label with greeting update"

git log --oneline --graph
git branch -d feature/greeting
```

**Why this is correct:** Both branches modified line 1 of `app.js` after the branch point, so Git could not auto-merge — this is the textbook definition of a conflict. The resolution is a judgment call (combining both messages), which only a human can make. The resulting `git log --graph` shows a diamond shape: one commit on `main`, a diverging line on `feature/greeting`, and a merge commit where both lines converge — visual, permanent proof of how the code evolved, which is exactly what "history as living documentation" means in practice.

---

**Next up:** Part 3 takes this to GitHub — pushing branches to a remote, opening Pull Requests, and understanding code review as professional communication, not gatekeeping.
