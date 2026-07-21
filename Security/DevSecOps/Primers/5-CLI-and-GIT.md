# Primer 5: The Command Line & Git You Actually Need

**Feeds into:** *Every phase.* You'll run terminal commands from Step 1.1 onward, and Git is the literal foundation our Phase 1 pre-commit hooks and Phase 3 history-scanning plug into.
**You'll be ready when:** you can create a folder, run a command, and understand exactly what `git add`, `git commit`, and `git push` each do — and why our security hooks fire *between* two of them.

**No prerequisite primers.** This is the ground floor.

---

## Why this matters

Almost every step in this series begins with a command in a terminal or an interaction with Git. These aren't incidental — they're *where the security happens*:

- The terminal is how you run the scanners, start the app, and test with `curl`.
- **Git isn't just "how you save code" — it's the thing our first line of defense is built into.** The Phase 1 pre-commit hook fires *during* `git commit`. The Phase 3 secret scanner reads *Git history*. The whole CI pipeline triggers on `git push`. If Git is a black box to you, those defenses are too.

So this primer isn't about becoming a command-line wizard. It's about knowing *precisely enough* that nothing in the series is a mystery — and, critically, understanding the two or three Git concepts that make the security controls make sense.

---

## Part A: The terminal — talking to your computer with words

You normally use your computer by *clicking* — icons, buttons, menus. The **terminal** (also called the command line, shell, or console) is the *other* way: you type text commands and the computer does them.

> **Definition — Terminal / Command line:** A text-based interface where you type commands and press Enter to run them. Same computer, same files — just words instead of clicks.

Why do developers and security tools prefer it? Because text is **precise, repeatable, and automatable.** You can't put "click this button, then that one" into a CI pipeline — but you *can* put `npm run lint` into one. Every scanner, build tool, and Git operation in this series speaks this language.

> **The texting-vs-pointing analogy:** Using a mouse is like pointing at things across a room and grunting — fine for simple stuff, but imprecise and impossible to record. The terminal is like *texting exact instructions* — "install these three tools, then run the scan on this folder." Precise, copy-pasteable, and repeatable by a machine at 3am with no human awake.

### Reading a command
A command has a simple shape:
```bash
npm install express
│    │       │
│    │       └─ argument (what to act on)
│    └───────── subcommand (what to do)
└────────────── program (which tool)
```
Read it left to right as a sentence: "npm, please install express." Most commands follow this `program subcommand arguments` pattern.

### ⚠️ The `$` that confuses everyone
You'll often see commands written like this:
```bash
$ npm install express
```
**Do not type the `$`.** That dollar sign is just the *prompt symbol* — the terminal's way of saying "I'm ready for a command," like a blinking cursor. It's shown in documentation to indicate "this is a terminal command," but you type only what comes *after* it. (In this series' code blocks we usually omit it, but you'll see it in the wild — now it won't trip you up.)

---

## Part B: The five commands you'll actually use

You need shockingly few commands to complete this entire series. Here they are, with what they do:

### 1. `cd` — change directory (move around)
```bash
cd securenotes      # move INTO the securenotes folder
cd ..               # move UP one folder (.. means "the parent")
```
> **The "walking into rooms" analogy:** Your folders are rooms in a house. `cd securenotes` walks into the `securenotes` room. `cd ..` walks back out into the hallway. Wherever you currently "are" is where commands run — so `npm run dev` only works when you've `cd`'d into the project.

### 2. `ls` — list (look around)
```bash
ls          # show the files/folders in the current room
ls -la      # show them all, including hidden files, with details
```
The `-la` is a *flag* (an option that modifies behavior). `-a` reveals **hidden files** — ones starting with a dot, like `.git`, `.env`, and `.gitignore`. That's important for us: nearly every security config file in this series is a hidden dotfile, invisible to a plain `ls`.

### 3. `mkdir` — make directory (create a room)
```bash
mkdir securenotes   # create a new folder called securenotes
```
This is literally Step 1.1 of the series.

### 4. `cat` — show a file's contents
```bash
cat package.json    # print the contents of package.json to the screen
```
We use this constantly in the "Verification" steps to prove a file has the right contents.

### 5. `echo` — print text (or write it to a file)
```bash
echo "hello"                    # just prints: hello
echo "SECRET=value" > .env      # writes that text INTO a file called .env
```
That `>` redirects the output *into a file* instead of the screen. Phase 1 uses exactly this to create a fake `.env` and prove `.gitignore` hides it.

That's the whole toolkit. `cd`, `ls`, `mkdir`, `cat`, `echo` — plus the tools we install (`npm`, `git`, `docker`, scanners). You do not need more.

---

## Part C: Git — the real foundation

Now the important half. **Git** is where the security actually lives, so let's build a genuine mental model, not just memorize commands.

> **Definition — Git:** A *version control system* — a tool that records the complete history of every change to your project, so you can see what changed, when, by whom, and roll back to any past state.

> **The "save points in a video game" analogy:** In a game, you hit "save" at key moments. If you mess up later, you reload an earlier save. Git is that, for your entire project — except every save is permanent, labeled, and keeps the *full history*, not just the latest state. You can always travel back to *any* save point.

But Git is more than an undo button, and this next part is *the* thing that makes the security controls click.

### The three areas: the key mental model
Git moves your changes through **three areas.** Understanding these three areas — and especially the boundaries *between* them — is the single most useful thing in this primer, because **our security hooks live on those boundaries.**

```
  WORKING          STAGING             REPOSITORY
  DIRECTORY        AREA                (history)
  (your edits)     (ready to save)     (saved forever)
      │                 │                    │
      │   git add       │   git commit       │
      ├────────────────▶├───────────────────▶│
      │                 │                     │
   "I edited      "I've selected      "It's permanently
    files"         what to save"        recorded"
```

Let's walk each one:

**1. Working directory** — your actual files as they are right now, with all your latest edits. This is just your folder; edits here aren't tracked yet.

**2. Staging area** — a "holding zone" where you place the specific changes you want to save next. You *choose* what goes here.

**3. Repository (history)** — the permanent record. Once a change is committed here, it's saved forever in the project's history.

> **The "packing a box to ship" analogy:**
> - **Working directory** = your messy desk with lots of stuff on it (all your edits).
> - **Staging area** = the open box where you place *just the items you want to ship* (the changes for this save).
> - **`git commit`** = sealing and labeling the box, then putting it on the permanent shelf (recording it in history).
>
> You don't ship your whole desk — you *choose* what goes in the box (`git add`), then seal it (`git commit`).

### The commands that move things between areas

```bash
git add .           # move changes from working dir → staging ("put in the box")
git commit -m "..."  # move staging → history, with a message ("seal & shelve it")
git push            # send your local history → GitHub (the shared server)
```

- **`git add .`** stages all your changes (the `.` means "everything here"). You can also stage one file: `git add package.json`.
- **`git commit -m "message"`** permanently records the staged changes, with a required *message* describing what you did (`-m` = "here's the message"). Good messages are how future-you understands the history.
- **`git push`** uploads your local commits to the shared server (GitHub), where teammates and the CI pipeline can see them.

---

## Part D: Why the three areas *are* the security story

Here's the payoff — the reason we spent so long on those three areas. **Our defenses live precisely on the boundaries between them:**

```
  WORKING DIR ──git add──▶ STAGING ──git commit──▶ HISTORY ──git push──▶ GITHUB
                                    ▲                                    ▲
                                    │                                    │
                          🛡️ PRE-COMMIT HOOK                    🛡️ CI PIPELINE
                          (Phase 1: fires HERE,                 (Phase 2+: fires HERE,
                           BEFORE the commit                     on the server,
                           is sealed)                            after push)
```

Now the Phase 1 and Phase 2 controls make complete sense:

1. **The pre-commit hook (Phase 1) fires on the `git commit` boundary** — *after* you've staged changes but *before* they're sealed into history. This is the perfect moment: if the hook detects a hardcoded secret in your staged changes, it *aborts the commit* — the secret never enters history at all. It's caught in the box before the box is sealed. That's why it's called *pre-commit*.

2. **This is why "delete the secret later" doesn't work (Phase 3).** Remember: history is *permanent*. If a secret gets committed (sealed into history), then deleted in a *later* commit, the secret still lives in the *earlier* commit forever. You can't un-seal a shipped box by shipping a second box that says "ignore the first one." That's exactly why Phase 3 scans the *entire history*, not just the latest state — and why a leaked secret must be *rotated*, not just deleted.

3. **The CI pipeline (Phase 2+) fires on `git push`** — when your history reaches the server. It's the second, un-skippable wall: even if someone bypassed the local hook (with `git commit --no-verify`), the server-side CI catches it. **Two defenses on two different boundaries = defense in depth.**

Understanding these three areas transforms the security controls from "magic that yells at me" into "a guard standing at a specific, sensible checkpoint."

---

## Part E: Branches — parallel universes for your code

One more Git concept the series relies on: **branches.**

> **Definition — Branch:** An independent line of development — a parallel copy of the project where you can make changes without affecting the main version until you're ready.

> **The "draft document" analogy:** `main` is the published, official version of your document. A branch is a *draft copy* you can scribble on freely. When the draft is good, you *merge* it back into the official version. If the draft is a disaster, you just throw it away — the official version was never touched.

Why this matters for security in the series:
- We do risky experiments (like intentionally adding a vulnerability to *prove* a scanner catches it) on a **scratch branch**, so `main` stays clean.
- **Pull requests** (PRs) are how a branch asks to merge into `main` — and that's the exact moment our CI gates run. **Branch protection** (Primer 4's "turnstile") blocks the merge until the security checks pass green.

The commands you'll see:
```bash
git checkout -b test-leak   # create AND switch to a new branch called "test-leak"
git checkout main           # switch back to the main branch
git branch -D test-leak     # delete the branch (throw away the draft)
```

So the full loop the series uses repeatedly is:
1. Branch off (`git checkout -b`) to try something.
2. Stage and commit your changes (`git add`, `git commit`).
3. Push (`git push`) — CI runs its gates.
4. If green, merge via a PR into `main`; if it was just a test, delete the branch.

---

## Part F: Reading the series' Git moments correctly

With all this, every Git interaction in the series is now legible. For example, Phase 1's secret-blocking verification:

```bash
git add src/leak.ts                    # stage the file containing a fake AWS key
git commit -m "test: this should be BLOCKED"   # try to seal it into history...
# → the pre-commit hook fires on this boundary, detects the secret,
#   and ABORTS. The commit never happens. History stays clean.
git reset src/leak.ts                  # un-stage the file (take it out of the box)
rm src/leak.ts                         # delete the file entirely
```

You now know:
- `git add` put it in the box (staging).
- `git commit` *tried* to seal it — but that's the boundary the hook guards, so it was stopped.
- `git reset` took it back out of the box (the inverse of `git add`).
- `rm` deleted the actual file from your desk (working directory).

No magic. Just changes moving between three areas, with a guard on one of the boundaries.

---

## The five things to carry into the series

1. **The terminal is precise, repeatable text-commands** — and you only need about five (`cd`, `ls`, `mkdir`, `cat`, `echo`) plus the tools you install. (And never type the `$`.)
2. **Git records permanent history** — save points you can always return to; it's an undo button *and* the foundation of our defenses.
3. **Changes flow through three areas: working directory → staging (`git add`) → history (`git commit`) → server (`git push`).**
4. **Our security hooks live on the boundaries between those areas** — pre-commit guards the `git commit` boundary (catch secrets before they're sealed); CI guards the `git push` boundary (the un-skippable server-side wall).
5. **History is permanent — so deleting a committed secret doesn't remove it.** This is *why* Phase 3 scans full history and why leaked secrets must be *rotated*.

---

## ✅ Self-check

1. A tutorial shows `$ npm run dev`. What exactly do you type into your terminal, and what is that `$`?
2. You run `npm run dev` and it says "no such file." What's the most likely mistake, and which command fixes it?
3. In your own words, what's the difference between `git add` and `git commit`?
4. Phase 1's pre-commit hook catches a secret. On *which* boundary between Git's three areas does it fire, and why is that the ideal spot?
5. You accidentally committed a password, then deleted it in the very next commit. Is the password gone from the repo? Why or why not — and what must you actually do?
6. Why do we run "intentionally add a vulnerability" experiments on a separate branch instead of on `main`?
