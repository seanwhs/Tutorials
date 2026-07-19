# Appendix C: Command Cheat Sheet

Every terminal command used across the entire series, grouped by purpose, with what it does, when you'd run it, and — critically — what its output should look like when it succeeds, so you can immediately tell "did that actually work?" without guessing.

## C.1 — Environment Setup Commands (Part 1)

```bash
node -v
```
**Purpose:** Confirm Node.js is installed and meets Next.js 16's minimum version.
**Expected output:** `v22.11.0` (or any `v20.9.x`+ / `v22.x`).
**Run when:** Once, at the very start, and any time you suspect a version mismatch (e.g., switching computers).

```bash
npm -v
```
**Purpose:** Confirm npm (bundled with Node) is available.
**Expected output:** A version string like `10.9.0`.

```bash
git --version
```
**Purpose:** Confirm Git is installed.
**Expected output:** `git version 2.47.0` (or similar).

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```
**Purpose:** One-time identity setup so Git can label your commits.
**Expected output:** Nothing printed — silence means success. Verify with:
```bash
git config --global user.name
```
which should echo back the name you set.

---

## C.2 — Project Scaffolding (Part 1)

```bash
npx create-next-app@latest greymatter-ledger
```
**Purpose:** Generate the initial Next.js project.
**Expected output:** A series of prompts (or, if using explicit flags, none at all), ending with `Success! Created greymatter-ledger at ...`.
**Run when:** Exactly once, at the very beginning of the entire course.

```bash
npm run dev
```
**Purpose:** Start the local development server with hot-reload.
**Expected output:**
```
▲ Next.js 16.0.0 (Turbopack)
- Local:        http://localhost:3000
- Ready in 800ms
```
**Run when:** Every single time you sit down to work on this project — this should be running continuously in one dedicated terminal tab throughout the entire course.
**Stop with:** `Ctrl+C` in that terminal.

```bash
npm run build
```
**Purpose:** Produce a production-optimized build locally, exactly as Vercel would, to catch build errors before pushing (Part 13 troubleshooting).
**Expected output:** A build summary listing every route and its size, ending in `✓ Compiled successfully`.
**Run when:** Before pushing to GitHub if you suspect something might not build cleanly, or any time `npm run dev` behaves oddly but shows no explicit error.

```bash
npm run start
```
**Purpose:** Run the production build locally (must run `npm run build` first). Rarely needed in this course, since Vercel handles this in the real deployment — useful only for advanced local debugging of production-specific behavior.

---

## C.3 — Database Commands (Drizzle, Parts 3, 5–12)

```bash
npm run db:generate
```
**Purpose:** Compare `src/db/schema.ts` against the last-known schema state and write a new SQL migration file describing only the changes.
**Expected output:**
```
Reading config file 'drizzle.config.ts'
2 tables
journal_entries 6 columns 0 indexes 1 fks
journal_lines 5 columns 0 indexes 2 fks

[✓] Your SQL migration file ➜ drizzle/0002_xxxxxxx.sql created
```
**Run when:** Every time you edit `schema.ts` — this is a planning step; it does **not** touch your real database yet.
**Watch for:** Interactive prompts asking whether a column was "created or renamed" — for this course, always choose the "create" option, since we only ever add new columns, never rename existing ones (Part 5 troubleshooting).

```bash
npm run db:migrate
```
**Purpose:** Actually apply pending migration files to the real database (local or, if overridden, production).
**Expected output:**
```
[✓] migrations applied successfully!
```
**Run when:** Immediately after every `db:generate`, as a pair — never leave a generated migration unapplied for long.

```bash
npm run db:studio
```
**Purpose:** Open Drizzle Studio, a visual, browser-based database inspector.
**Expected output:** Opens `https://local.drizzle.studio` in your default browser, showing every table in the sidebar.
**Run when:** After nearly every feature you build, to visually confirm rows exist with the correct values — this was the primary verification tool used in almost every part from Part 3 onward.

```bash
DATABASE_URL_UNPOOLED="your-production-connection-string" npx drizzle-kit migrate
```
**Purpose:** One-off override to run migrations against a *different* database than whatever `.env.local` points at — used only if you created a separate production Neon project (Part 13.6).
**Expected output:** Same as `npm run db:migrate` above.
**Run when:** Rarely — only if your local and production databases are genuinely different Neon projects.

---

## C.4 — Git & GitHub Commands (Parts 1–13)

```bash
git status
```
**Purpose:** Show what's changed, staged, or untracked.
**Expected output:** A list of modified/new files. **The single most important thing to check here, every time, is that `.env.local` never appears.**
**Run when:** Before every single commit, without exception.

```bash
git add .
git commit -m "Descriptive message"
```
**Purpose:** Stage all changes and save a permanent snapshot.
**Expected output:** A summary like `X files changed, Y insertions(+), Z deletions(-)`.
**Run when:** At the end of every part in this course (twelve checkpoints total, per the pattern established from Part 1 onward), and any time you complete a meaningful, working chunk of functionality.

```bash
git log --oneline
```
**Purpose:** View a condensed commit history, one line per commit.
**Expected output:** A list like:
```
d4e5f6g Add journal_entries/journal_lines schema and postJournalEntry engine
c3d4e5f Add Chart of Accounts schema, default seed data, and viewing page
...
```
**Run when:** After every commit, to visually confirm your checkpoint count is growing as expected.

```bash
git log --all --full-history -- .env.local
```
**Purpose:** The critical security check — confirms `.env.local` has never, at any point, been part of any commit in the repository's entire history.
**Expected output:** **Nothing** — a completely empty result. This is the *only* correct output.
**Run when:** Once, deliberately, right before your very first `git push` (Part 13.1) — and again any time you're unsure whether a secret may have leaked.

```bash
git remote add origin https://github.com/YOUR_USERNAME/greymatter-ledger.git
git branch -M main
git push -u origin main
```
**Purpose:** Connect your local repository to a new, empty GitHub repository and upload your entire commit history for the first time.
**Expected output:** A progress display (`Enumerating objects...`, `Writing objects...`), ending in a line confirming the branch was set up to track `origin/main`.
**Run when:** Exactly once, in Part 13.2.

```bash
git push
```
**Purpose:** Upload any new commits to GitHub — and, once Vercel is connected (Part 13.3), automatically trigger a new production deployment.
**Expected output:** A short progress summary, no errors.
**Run when:** After every commit, from Part 13 onward — this is what makes your live site actually update.

---

## C.5 — Inngest Commands (Part 11)

```bash
npx inngest-cli@latest dev
```
**Purpose:** Start Inngest's local development server, which discovers and lets you test your app's background/scheduled functions without needing the real Inngest cloud service.
**Expected output:** A message confirming it's running, plus a URL, typically `http://localhost:8288`.
**Run when:** Alongside `npm run dev`, in a dedicated **third terminal tab**, for the entirety of Parts 11–12's local testing. Not needed once deployed to production (Part 13.7 uses the real Inngest cloud dashboard instead).

---

## C.6 — File/Folder Cleanup Commands (Used for Temporary Test Pages)

Several parts (6, 9, 11) built a temporary throwaway page to manually verify a piece of logic, then instructed you to delete it. The two relevant commands:

```bash
rm -rf src/app/journal-test
```
**Mac/Linux syntax.** `-r` = recursive (delete folder contents too), `-f` = force (no confirmation prompt).

```powershell
Remove-Item -Recurse -Force src\app\journal-test
```
**Windows PowerShell equivalent.**

**Run when:** Immediately after a temporary verification page has served its purpose (Part 6's `journal-test`, Part 11's `recurring-test`, Part 5's `backfill`) — these should never be committed to Git or left lying around in a real project.

⚠️ **Word of caution:** both commands delete permanently, with no undo and no confirmation prompt (that's what `-f`/`-Force` means). Always double-check the path before running — these commands only ever appeared in this course targeting a specific, disposable folder created moments earlier in the same part.

---

## C.7 — The Full Sequence, Start to Finish (Quick Reference)

If you were rebuilding this entire project from scratch in one sitting, here is the exact command sequence, in order, collapsed to its essentials:

```bash
# One-time machine setup
node -v && npm -v && git --version

# Scaffold
npx create-next-app@latest greymatter-ledger --typescript --tailwind --eslint --app --src-dir --turbopack --import-alias "@/*" --use-npm
cd greymatter-ledger
git add . && git commit -m "Initial commit"

# Terminal 1 (leave running throughout)
npm run dev

# Every time schema.ts changes (repeated across Parts 3, 5–12)
npm run db:generate
npm run db:migrate
npm run db:studio   # to verify

# Terminal 3, during Parts 11-12
npx inngest-cli@latest dev

# End of every part
git add .
git commit -m "..."

# Part 13, once
git log --all --full-history -- .env.local   # must be empty
git remote add origin https://github.com/YOU/greymatter-ledger.git
git branch -M main
git push -u origin main
# ...then connect via vercel.com dashboard...

# Every subsequent change
git push   # auto-deploys via Vercel
```
