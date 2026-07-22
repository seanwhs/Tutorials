# Primer 05 — Git Basics

## Why this primer exists

Every part of the main series ends with a "Git checkpoint" — a `git add`, a `git commit` with a specific message. This isn't decoration. Part 1 called Git "the car's black-box flight recorder," and the entire series relies on you having a working save point after every part, so that if something breaks three parts later, you can compare against a known-good state instead of guessing. If you've never used Git before, or you've only ever clicked a "Commit" button in an editor without understanding what's actually happening underneath, this primer builds that understanding from first principles — enough to follow every Git instruction in the main series with real confidence, not just by rote.

**You can safely skip this primer if** you're already comfortable with: what a repository, commit, and the staging area are, the difference between `git add` and `git commit`, why `.gitignore` matters, and how to check history and compare states. If any of those feel uncertain, keep reading.

---

## The core idea: a series of permanent, labeled snapshots of your project

Git is a **version control system** — a tool that keeps a complete history of every meaningful change ever made to a project, letting you go back to any prior state at any time. Think of it as a series of snapshots, not a single mutable "current state" that overwrites itself as you work.

**Analogy:** imagine writing a book, and instead of just one file called `book.docx` that you keep overwriting, you save `book-draft-1.docx`, `book-draft-2.docx`, `book-draft-3-with-editor-notes.docx`, and so on — except Git does this far more precisely and automatically, tracking *exactly* what changed between each version, letting you jump back to any of them instantly, and never requiring you to manually rename anything.

```text
Snapshot 1 ──► Snapshot 2 ──► Snapshot 3 ──► Snapshot 4 (current)
"Part 1:        "Part 2:        "Part 3:        "Part 4: public
 foundation"     design system"  Sanity model"   course pages"

Each snapshot is a COMMIT. You can inspect any of them, compare any
two of them, or (in an emergency) revert back to any of them.
```

This is precisely why the main series' Git checkpoints matter: each one is a permanent, labeled snapshot of the project at the end of a working, verified part. If Part 9's lesson player somehow breaks something that worked fine in Part 7, you have an exact, comparable record of what Part 7 looked like — not a vague memory of "it worked before I made some changes."

---

## The repository: a project's entire tracked history, living in a hidden folder

A **repository** (often shortened to "repo") is a project folder that Git is tracking. The moment you run `git init` inside a folder, Git creates a hidden `.git` subfolder that stores the *entire history* of every commit ever made — every snapshot, forever, unless deliberately removed.

```bash
cd greymatter-lms
git init
```

```text
greymatter-lms/
├── .git/          ← Git's own internal storage — the entire history lives here
├── app/
├── components/
├── package.json
└── ...
```

You never manually edit anything inside `.git/` — it's Git's own internal bookkeeping. But it's worth knowing it's there, and that deleting it (`rm -rf .git`) would permanently erase your project's *entire history*, while leaving your actual current files completely untouched. This distinction — your files vs. Git's record of every past version of those files — is the single most important mental model in this entire primer.

---

## The three states: working directory, staging area, and repository

This is the part of Git that confuses nearly everyone at first, because it introduces a middle step that doesn't exist in simpler tools. Git tracks your files across **three distinct states**, and understanding the flow between them is what makes every `git add`/`git commit` instruction in the main series make sense.

```text
┌───────────────────┐    git add    ┌───────────────┐   git commit   ┌────────────────┐
│  Working Directory  │ ────────────► │ Staging Area   │ ─────────────► │  Repository     │
│  (your actual files, │                │ (files marked   │                │  (a permanent,   │
│   as you're editing   │                │  "ready to be    │                │   named snapshot  │
│   them right now)      │                │  committed")      │                │   in history)      │
└───────────────────┘                └───────────────┘                └────────────────┘
```

- **Working directory** — the actual files on your disk, exactly as you're editing them right now. This is what your code editor shows you.
- **Staging area** (also called "the index") — a holding area where you place *specific* changes you intend to include in your *next* commit. You can stage some changes while leaving others un-staged, giving you fine control over what goes into each snapshot.
- **Repository** — the permanent record. Once committed, a snapshot exists in history forever (until deliberately rewritten with advanced commands well beyond this primer's scope).

### Why the staging area exists at all — a concrete reason

Imagine you're mid-way through Part 8, and you've made two genuinely unrelated changes: you fixed a typo in the homepage (unrelated to Part 8's actual work) and you finished the enrollment Server Action (Part 8's real work). The staging area lets you commit these as two separate, clearly-labeled snapshots — `git add app/dashboard/courses/actions.ts` for the real Part 8 work, commit it with a message describing exactly that, and then separately stage and commit the homepage typo fix with its own honest message — rather than lumping two unrelated changes into one vague commit.

In practice, throughout this series, you'll almost always stage *everything* at once with `git add .` (the period means "everything in and below the current folder"), since each part's checkpoint is designed to represent one complete, coherent unit of work — but it's worth understanding that the staging area gives you this finer control whenever you want it.

### The three commands, in the order the main series uses them

```bash
# 1. See what's changed since the last commit — files that are
#    modified, newly created, or deleted, none of it staged yet
git status

# 2. Stage everything — moves changes from "working directory"
#    into the "staging area," marking them ready for the next commit
git add .

# 3. Take everything currently staged and permanently record it as
#    a new snapshot in the repository's history, with a descriptive message
git commit -m "Part 8: secure course enrollment — Zod validation, ..."
```

This exact three-step sequence appears at the end of every single part in the main series — you've already seen it dozens of times. Now you know precisely what each step is actually doing underneath.

---

## `git status` — the single most useful command you'll run constantly

`git status` tells you, at any moment, exactly what Git currently sees: which files are modified but not yet staged, which are staged and ready to commit, and — critically for this series — which files exist in your folder but aren't tracked by Git at all.

```bash
git status
```

```text
On branch main
Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
        modified:   app/page.tsx
        modified:   package.json

Untracked files:
  (use "git add <file>..." to include in what will be committed)
        components/ui/button.tsx
        lib/cn.ts
```

Recall Part 1's Git checkpoint instructed: *"Before committing, glance over the `git status` output and confirm you do NOT see `.env.local` listed."* This is the exact mechanism that check relies on — `git status` shows you, in plain text, precisely what's about to be included in your next commit, giving you a chance to catch a mistake (like accidentally about to commit a secrets file) before it becomes a permanent part of your project's history.

---

## `.gitignore` — telling Git "never track these files at all"

Some files should **never** be part of a Git repository's history — generated build output (`.next/`), installed dependencies (`node_modules/`), and, most importantly for this series, files containing secrets (`.env.local`). A `.gitignore` file lists patterns for exactly what Git should always ignore, never showing them in `git status`, never allowing `git add` to stage them (without an explicit override).

```gitignore
# .gitignore (relevant excerpt from Part 1)
node_modules
.next
.env*.local
```

**Why this matters so much specifically for `.env.local`:** recall Part 1's explanation — environment variables are "sticky notes taped *inside* a building, never printed on the blueprint that gets mailed to the public." Once a secret is committed to Git, it exists in that repository's history **permanently** — even if you later delete the file in a subsequent commit, the *old* commit that included it still exists, and anyone with access to the repository (including anyone who ever cloned or forked it) can dig through history and find it. This is why Appendix F's security checklist includes the specific, non-optional verification:

```bash
git log --all --full-history -- .env.local
# Expected: completely EMPTY output, always, for the entire life of the project
```

If this command ever shows commits, every secret that file contained must be treated as permanently compromised and rotated — deleting the file afterward does not undo the exposure.

---

## Commits: permanent, labeled snapshots with meaningful messages

A **commit** is one permanent snapshot in a repository's history, created by `git commit`. Every commit has:

- A unique identifier (a long hash, like `a1b2c3d...`, though you usually only need to reference the first several characters)
- A message describing what changed and why
- A reference to the *previous* commit, forming a chain — this chain is what makes "history" meaningful; you can walk backward through it

```bash
git commit -m "Part 6: Clerk authentication — sign-in/sign-up, webhook-based user provisioning, ..."
```

### Why commit messages matter more than they might seem to

Every Git checkpoint in the main series provides a specific, descriptive commit message — never something generic like `"updates"` or `"fixed stuff"`. This is a deliberate habit worth adopting permanently: six months from now, `git log --oneline` will show you a scrollable list of every commit message ever written for this project. A message like `"Part 11: secure server-side grading — answer keys removed from every browser-facing query, ..."` tells you, at a glance, both *what* changed and, importantly, *why* it mattered — versus a message like `"fix"`, which tells you nothing useful when you're trying to find "which commit introduced the secure grading fix" a year later.

### Viewing history

```bash
git log --oneline
```

```text
a3f8c21 Part 8: secure course enrollment — Zod validation, ...
d92e015 Part 7: student dashboard shell — responsive sidebar/mobile nav, ...
7b4a903 Part 6: Clerk authentication — sign-in/sign-up, webhook-based ...
1c88ef2 Part 5: Neon PostgreSQL transactional schema — ...
```

`--oneline` compresses each commit down to just its short identifier and message — the fastest way to scan a project's history at a glance. This is exactly the tool Part 1's reference section pointed to: *"If anything ever breaks badly in a later part, you can always compare your current code against this exact snapshot."*

### Comparing two snapshots

```bash
git diff <commit-hash>
```

This shows you, line by line, exactly what's different between your current working files and a specific past commit — every line added, every line removed, clearly marked. This is the concrete tool behind Part 1's promise: if Part 14 breaks something, you can `git diff` against the end-of-Part-13 commit and see *precisely* what changed in between, rather than manually re-reading every file trying to spot a difference by eye.

---

## Branches: a brief, honest note (not deeply used in this series)

A **branch** is a parallel, independent line of commits — letting you experiment or work on something without affecting your main line of history until you're ready to merge it back in. Recall Part 5's mention that "a branch in Neon is similar in spirit to a Git branch" — the underlying concept (an isolated, independent copy you can diverge from and later reconcile) is genuinely the same idea, just applied to a database instead of source code.

```text
main:     ──●────●────●────●────●──►  (your primary line of work)
                       \
feature:                 ●────●──►     (an isolated line for trying something risky)
```

**This series deliberately doesn't ask you to create branches** — every part's work happens directly on your single primary branch (conventionally named `main`), committed in sequence, one part after another. This is a reasonable, deliberate simplification for a tutorial series: branching, merging, and resolving conflicts between branches is a genuinely useful skill, but it's also a large enough topic that introducing it here would distract from the series' actual subject matter. If you're already comfortable with branches from prior experience, feel free to use them for your own experimentation as you work through the parts — nothing in the main series depends on you using only one branch, it simply never requires more than one.

---

## `git rm --cached` — untracking a file without deleting it

Occasionally you'll accidentally commit a file that should have been ignored (before adding it to `.gitignore`, or before realizing it needed to be there). Recall Part 1's "Common mistakes" section:

```bash
git rm --cached .env.local
```

This is worth understanding precisely: `--cached` means "remove this file from Git's tracking, but leave the actual file on my disk untouched." Without `--cached`, plain `git rm` would delete the file from your working directory too — almost certainly not what you want when the goal is simply "stop tracking this, don't destroy it." After running this, you'd still need to commit the removal (`git add .` then `git commit`) for the untracking to actually take effect in the repository's history — and, again, this does **not** erase the file from *earlier* commits that already included it; it only stops tracking it going forward.

---

## Putting it all together: walking through one real Git checkpoint from the series

Let's trace Part 8's actual checkpoint instructions, step by step, naming every concept from this primer as it appears:

```bash
git add .
```
*(Stages every change in the working directory — every modified and newly-created file — into the staging area, preparing it for the next commit.)*

```bash
git status
```
*(A verification step: confirms exactly what's about to be committed. Part 8's instructions specifically say to check this output doesn't include anything unexpected — this is the same habit Part 1 established for catching an accidentally-staged `.env.local`.)*

```bash
git commit -m "Part 8: secure course enrollment — Zod validation, server-side existence/publication checks, atomic transaction, unique-constraint race protection, useActionState enrollment UI"
```
*(Takes everything currently staged and permanently records it as one new commit — a labeled snapshot — in the repository's history, with a message describing exactly what this snapshot represents.)*

If you ever need to return to exactly this point later:

```bash
git log --oneline
# find the commit hash for "Part 8: secure course enrollment..."

git diff <that-hash>
# see exactly what's changed in your project since that snapshot
```

---

## You're ready for Part 1 if you can answer these

1. What are the three states Git tracks a file through (working directory → ? → repository), and what command moves a file from the first state into the second?
2. Why does `.gitignore` matter specifically for a file like `.env.local`, and what's the one thing that's permanently true about a secret once it's ever been committed, even if the file is deleted in a later commit?
3. What's the practical difference between `git add .` and `git commit -m "..."` — why are these two separate steps rather than one combined command?
4. If a Git checkpoint's instructions say to run `git status` before committing, what specifically are you checking for, and why does the main series emphasize this repeatedly?
5. What does `git log --oneline` show you, and how would you use it (together with `git diff`) to figure out exactly what changed between two specific points in the project's history?

If all five feel solid, you have everything you need to follow every Git checkpoint in the main series with genuine understanding, not just by rote repetition of the same three commands.
