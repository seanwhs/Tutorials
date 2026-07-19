# Appendix C: Command Cheat Sheet

Every terminal command used across the entire series, grouped by purpose, with what it does, when you'd run it, and what its output should look like when it succeeds.

## C.1 — Environment Setup Commands (Part 1)

```bash
node -v
```
**Purpose:** Confirm Node.js meets Next.js 16's minimum version.
**Expected output:** `v22.11.0` (or any `v20.9.x`+ / `v22.x`).

```bash
npm -v
```
**Purpose:** Confirm npm is available.
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
**Expected output:** Nothing printed — silence means success.

---

## C.2 — Project Scaffolding (Part 1)

```bash
npx create-next-app@latest greymatter-ledger --typescript --tailwind --eslint --app --turbopack --import-alias "@/*" --use-npm
```
**Purpose:** Generate the initial Next.js project **without** a `src/` directory — note the deliberate omission of `--src-dir` here, since this project's structure keeps `app/`, `lib/`, `db/`, and `components/` at the project root.
**Expected output:** `Success! Created greymatter-ledger at ...`.
**Run when:** Exactly once, at the very beginning.

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
**Run when:** Continuously, in one dedicated terminal tab, throughout the entire course.
**Stop with:** `Ctrl+C`.

```bash
npm run build
```
**Purpose:** Produce a production-optimized build locally, exactly as Vercel would, to catch build errors before pushing.
**Expected output:** A build summary listing every route and its size, ending in `✓ Compiled successfully`.

```bash
npm run start
```
**Purpose:** Run the production build locally (must run `npm run build` first).

---

## C.3 — Database Commands (Drizzle, Parts 3, 5–12, and extensions 14.2–14.8)

```bash
npm run db:generate
```
**Purpose:** Compare `db/schema.ts` against the last-known schema state and write a new SQL migration file describing only the changes.
**Expected output:**
```
Reading config file 'drizzle.config.ts'
2 tables
journal_entries 9 columns 0 indexes 2 fks
journal_lines 9 columns 0 indexes 2 fks

[✓] Your SQL migration file ➜ drizzle/000X_xxxxxxx.sql created
```
**Run when:** Every time you edit `db/schema.ts` — a planning step; does **not** touch the real database yet.
**Watch for:** Interactive prompts asking whether a column was "created or renamed" — always choose "create," since this course only ever adds new columns.

```bash
npm run db:migrate
```
**Purpose:** Actually apply pending migration files to the real database.
**Expected output:**
```
[✓] migrations applied successfully!
```
**Run when:** Immediately after every `db:generate`, as a pair.

```bash
npm run db:studio
```
**Purpose:** Open Drizzle Studio, a visual, browser-based database inspector.
**Expected output:** Opens `https://local.drizzle.studio`, showing every table in the sidebar.
**Run when:** After nearly every feature — the primary verification tool used throughout this course.

```bash
DATABASE_URL_UNPOOLED="your-production-connection-string" npx drizzle-kit migrate
```
**Purpose:** One-off override to run migrations against a different database than `.env.local` points at.
**Run when:** Only if local and production databases are genuinely separate Neon projects.

---

## C.4 — Git & GitHub Commands (Parts 1–13)

```bash
git status
```
**Purpose:** Show what's changed, staged, or untracked. **Confirm `.env.local` never appears.**
**Run when:** Before every single commit, without exception.

```bash
git add .
git commit -m "Descriptive message"
```
**Purpose:** Stage all changes and save a permanent snapshot.
**Run when:** At the end of every part/step in this course.

```bash
git log --oneline
```
**Purpose:** View a condensed commit history.
**Run when:** After every commit, to confirm your checkpoint count is growing.

```bash
git log --all --full-history -- .env.local
```
**Purpose:** The critical security check — confirms `.env.local` has never, at any point, been part of any commit.
**Expected output:** **Nothing** — a completely empty result.
**Run when:** Once, deliberately, right before your first `git push` (Part 13.1) — and any time you're unsure whether a secret may have leaked.

```bash
git remote add origin https://github.com/YOUR_USERNAME/greymatter-ledger.git
git branch -M main
git push -u origin main
```
**Purpose:** Connect your local repository to a new, empty GitHub repository and upload your entire history.
**Run when:** Exactly once, in Part 13.2.

```bash
git push
```
**Purpose:** Upload new commits to GitHub — triggers a new Vercel deployment once connected.
**Run when:** After every commit, from Part 13 onward.

---

## C.5 — Inngest Commands (Part 11, extended by 14.5's payroll and 14.8's bank sync)

```bash
npx inngest-cli@latest dev
```
**Purpose:** Start Inngest's local development server, discovering and letting you test background/scheduled functions — including `send-invoice-confirmation-email`, `send-overdue-invoice-reminders`, `generate-recurring-invoices`, and (as of Part 14.8) `sync-bank-feeds`.
**Expected output:** A message confirming it's running, plus a URL, typically `http://localhost:8288`.
**Run when:** Alongside `npm run dev`, in a dedicated third terminal tab, for the entirety of local testing from Part 11 onward.

---

## C.6 — File/Folder Cleanup Commands (Corrected Paths)

Several parts built a temporary throwaway page to manually verify a piece of logic, then instructed you to delete it. With the no-`src/` structure, every one of these now sits directly under `app/`:

```bash
rm -rf app/journal-test
```
**From Part 6** — verified `postJournalEntry`'s guard clauses directly.

```bash
rm -rf app/backfill
```
**From Part 5** — backfilled the Chart of Accounts for organizations created before auto-seeding existed.

```bash
rm -rf app/db-test
```
**From Part 3** — confirmed the initial database connection worked end-to-end.

```bash
rm -rf app/recurring-test
```
**From Part 11** — created a one-off recurring invoice template for testing.

**Mac/Linux syntax** shown above. `-r` = recursive, `-f` = force (no confirmation prompt).

**Windows PowerShell equivalent**, using the same corrected paths:
```powershell
Remove-Item -Recurse -Force app\journal-test
Remove-Item -Recurse -Force app\backfill
Remove-Item -Recurse -Force app\db-test
Remove-Item -Recurse -Force app\recurring-test
```

⚠️ **Word of caution:** both command forms delete permanently, with no undo and no confirmation prompt. Always double-check the path before running.

---

## C.7 — The Full Sequence, Start to Finish (Corrected Paths)

```bash
# One-time machine setup
node -v && npm -v && git --version

# Scaffold — no --src-dir flag
npx create-next-app@latest greymatter-ledger --typescript --tailwind --eslint --app --turbopack --import-alias "@/*" --use-npm
cd greymatter-ledger
git add . && git commit -m "Initial commit"

# Terminal 1 (leave running throughout)
npm run dev

# Every time db/schema.ts changes (Parts 3, 5-12, and extensions 14.2-14.8)
npm run db:generate
npm run db:migrate
npm run db:studio   # to verify

# Terminal 3, from Part 11 onward
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
