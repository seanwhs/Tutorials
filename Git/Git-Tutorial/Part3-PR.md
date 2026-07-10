## Part 3: The GitHub Workflow

**Series:** Mastering Version Control | **Prev:** Part 2 — Branching & Merging | **Next:** Part 4 — Deployment 101: GitHub Pages

---

### 1. Concept Explanation

#### 1.1 GitHub is not Git

This trips up nearly everyone at first: **Git is the tool; GitHub is a hosting service built around it.** Git works entirely without GitHub (as Parts 1–2 proved). GitHub adds:
- A remote server to push/pull from (your backup + collaboration hub)
- Pull Requests (a review/discussion layer on top of merging)
- Issues, project boards, Actions (CI/CD), and Pages (static hosting — Part 4)

You could just as easily push to GitLab, Bitbucket, or a private server — the underlying Git commands are identical.

#### 1.2 Authentication: SSH vs. Personal Access Token (PAT)

As of 2021, GitHub no longer accepts your account password over HTTPS for `git push`. You need one of:
- **SSH key** (recommended, set up once, never expires by default)
- **Personal Access Token (PAT)** (used like a password over HTTPS, can be scoped and expired)

```bash
# --- SSH SETUP (recommended) ---
# 1. Generate a key (press Enter to accept defaults, optionally set a passphrase)
ssh-keygen -t ed25519 -C "you@example.com"

# 2. Start the SSH agent and add your key
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# 3. Copy your public key
cat ~/.ssh/id_ed25519.pub
# Paste this into GitHub: Settings -> SSH and GPG keys -> New SSH key

# 4. Test it
ssh -T git@github.com
# Expected: "Hi <username>! You've successfully authenticated..."
```

#### 1.3 The remote-tracking mental model

A "remote" is just a named URL pointing to another copy of the repository (usually on GitHub, conventionally named `origin`). Your local branches can *track* remote branches, meaning Git remembers "my local `main` corresponds to `origin/main`" so `git push`/`git pull` know where to sync without you specifying every time.

```
Local repo                          GitHub (origin)
──────────                          ────────────────
main ──tracks──▶ origin/main   ◀──  main
feature/x ─tracks▶ origin/feature/x ◀── feature/x (after first push -u)
```

#### 1.4 Pull Requests as communication, not gatekeeping

A Pull Request (PR) is a request to merge one branch into another, wrapped in a conversation. The professional mindset shift:

- A PR is **not** "prove you're good enough." It's "here's a change, here's why, please sanity-check it with fresh eyes before it becomes permanent."
- Good PR descriptions answer: **What** changed, **why** it changed, and **how** to verify it (steps to test, screenshots for UI).
- Small PRs get reviewed faster and more thoroughly than large ones — this is the same atomic-commit philosophy from Part 1, applied at the branch level.
- Code review catches bugs, but its bigger long-term value is **knowledge transfer** — spreading context about the codebase across the whole team so no one person is a single point of failure.

#### 1.5 Fork vs. Clone vs. Branch

| Concept | What it is | When you use it |
|---|---|---|
| **Clone** | Download a full copy of a repo (any repo) to your machine | Getting *any* repo onto your local machine |
| **Branch** | A pointer within one repository | Working on a feature within a repo you have write access to |
| **Fork** | A full copy of *someone else's* repo, under *your* GitHub account | Contributing to a repo you don't have write access to (open source) |

---

### 2. Implementation — Step-by-Step Terminal Commands

#### 2.1 Creating a remote repo and connecting it

On GitHub.com: click **New repository** → give it a name → **do not** initialize with a README if you already have a local repo (avoids an unnecessary merge on first push).

```bash
# Inside your existing local repo (from Part 1/2)
git remote add origin git@github.com:yourusername/professional-git-demo.git

# Confirm it's set
git remote -v

# Push main for the first time, and set up tracking with -u
git push -u origin main
```

After this, plain `git push` and `git pull` work without arguments because `main` now tracks `origin/main`.

#### 2.2 The full feature branch → PR → merge cycle

```bash
# 1. Always start a feature from an up-to-date main
git switch main
git pull

git switch -c feature/contact-form

# 2. Do the work, in atomic commits
echo "<form>...</form>" >> index.html
git add index.html
git commit -m "feat: add contact form markup"

echo "form { border: 1px solid #ccc; }" >> styles.css
git add styles.css
git commit -m "style: add contact form border"

# 3. Push the branch to GitHub (note: pushing a NEW branch needs -u the first time)
git push -u origin feature/contact-form
```

#### 2.3 Opening the Pull Request

Either via the URL GitHub prints after `git push` (it detects the new branch and offers a "Compare & pull request" link), or manually:

1. Go to the repo on GitHub → **Pull requests** tab → **New pull request**.
2. Base: `main` ← Compare: `feature/contact-form`.
3. Write a title and description:

```markdown
## What
Adds a basic contact form to the homepage.

## Why
Users have no way to reach us directly (see Issue #12).

## How to test
1. Pull this branch
2. Open index.html in a browser
3. Confirm the form renders with a visible border
```

4. Click **Create pull request**.

#### 2.4 Reviewing a PR (as the reviewer)

- **Files changed** tab shows a diff. Click a line to leave an inline comment.
- Leave a review as: **Comment** (just discussion), **Approve** (ready to merge), or **Request changes** (blocking — must be addressed).
- Good review comments are specific and kind: not _"this is wrong"_ but _"this will throw if `email` is undefined — should we default it or validate earlier?"_

#### 2.5 Merging the PR and syncing back locally

On GitHub, click **Merge pull request** (or **Squash and merge** — squashes all commits on the branch into one clean commit on `main`; common for tidy history on noisy WIP branches).

```bash
# Back on your machine, switch to main and pull the merged changes
git switch main
git pull

# Delete your local feature branch — it's done its job
git branch -d feature/contact-form

# Delete the remote branch too (GitHub often offers a button for this,
# or do it manually:)
git push origin --delete feature/contact-form
```

#### 2.6 Keeping your branch updated while a PR is open (avoiding drift)

If `main` moves forward while your PR is still open:

```bash
git switch feature/contact-form
git fetch origin
git merge origin/main
# resolve any conflicts (Part 2 skills), then push again
git push
```

---

### 3. Practice Exercise

**Step 1:** Push your `branching-practice` repo from Part 2 to a brand-new GitHub repository called `git-mastery-practice`.

**Step 2:** Create a branch `feature/readme-update`, add a `## Features` section to `README.md`, commit, and push it.

**Step 3:** Open a Pull Request with a proper "What / Why / How to test" description.

**Step 4:** Self-review it: leave one inline comment on your own diff (GitHub allows this), then approve and merge using **Squash and merge**.

**Step 5:** Pull `main` locally and confirm the squashed commit appears once in `git log --oneline`, and delete both the local and remote feature branches.

---

### 4. Solution & Explanation

```bash
cd branching-practice
git remote add origin git@github.com:yourusername/git-mastery-practice.git
git push -u origin main

git switch -c feature/readme-update
cat >> README.md << 'EOF'

## Features
- Branching demo
- Merge conflict demo
EOF
git add README.md
git commit -m "docs: add features section to README"
git push -u origin feature/readme-update

# Open PR on GitHub.com with description:
# ## What
# Adds a Features section to the README.
# ## Why
# New contributors had no quick summary of what this repo demonstrates.
# ## How to test
# Open README.md and confirm the new section renders correctly.

# After reviewing/approving on GitHub, click "Squash and merge"

git switch main
git pull
git log --oneline   # squashed commit appears as ONE entry

git branch -d feature/readme-update
git push origin --delete feature/readme-update
```

**Why this is correct:** Squash-and-merge collapses however many WIP commits existed on the feature branch into a single, clean commit on `main` — so `main`'s history stays readable (one line = one feature) even if your working process on the branch was messy (which is fine and normal!). This is the professional middle ground: commit freely and often on your own branch, but present a clean, atomic story to `main`. Deleting the branch afterward (both local and remote) keeps the repository's branch list from becoming cluttered with dozens of stale, already-merged branches — a common sign of an unmaintained repo.

---

**Next up:** Part 4 — turning a repository into a live, public website for free using GitHub Pages.
