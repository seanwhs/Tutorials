# Appendix B: Environment Variables Reference

Every environment variable used across the entire series, where it comes from, what it looks like, what breaks if it's wrong, and how it differs between local development and production. Treat this as the master reference whenever you're setting up a fresh clone of this project, onboarding a teammate, or debugging a "works locally but not in production" issue.

## B.1 — The Complete `.env.local` File, Fully Annotated

```bash
# =========================================================
# CLERK — Authentication & Organizations (Part 2)
# =========================================================

# Public identifier for your Clerk application. Safe to expose to the
# browser (the NEXT_PUBLIC_ prefix is what tells Next.js to bundle this
# into client-side JavaScript) — it identifies WHICH Clerk app to talk
# to, but grants no privileged access on its own.
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxxxxxxxxxxxxx

# The true secret. NEVER exposed to the browser — used only in
# server-side code (src/proxy.ts, currentUser(), clerkClient()).
# Anyone who obtains this can impersonate your entire application's
# backend authority with Clerk. Treat it like a master password.
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxx

# Tell Clerk's components which of OUR OWN routes handle sign-in/sign-up,
# and where to send a user immediately after each succeeds.
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dashboard


# =========================================================
# NEON — Postgres Database (Part 3)
# =========================================================

# POOLED connection — hostname contains "-pooler". Used by the live,
# running application (src/db/index.ts's `db` and `dbTransactional`
# clients). Required on Vercel, where many serverless function
# instances may connect simultaneously (Part 13, Step 13.4).
DATABASE_URL=postgresql://neondb_owner:PASSWORD@ep-xxxx-pooler.REGION.aws.neon.tech/neondb?sslmode=require

# UNPOOLED connection — no "-pooler" in the hostname. Used ONLY by
# drizzle.config.ts, for running migrations (a one-off, non-concurrent
# operation where a direct connection is more reliable).
DATABASE_URL_UNPOOLED=postgresql://neondb_owner:PASSWORD@ep-xxxx.REGION.aws.neon.tech/neondb?sslmode=require


# =========================================================
# INNGEST — Background & Scheduled Jobs (Part 11)
# =========================================================

# Used by our code to SEND events (inngest.send(...) inside
# createInvoice, etc.) to Inngest's cloud service.
INNGEST_EVENT_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Used by Inngest's cloud service to verify that incoming requests to
# our /api/inngest route genuinely came from Inngest, not an impersonator.
INNGEST_SIGNING_KEY=signkey-prod-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

## B.2 — Per-Service Setup Notes

### Clerk

- **Where to find these values:** Clerk Dashboard → your application → **API Keys** (left sidebar).
- **Local vs. production:** Clerk distinguishes between a **Development instance** (used while `localhost` testing, unlimited test users, relaxed domain checks) and a **Production instance** (used once you add a real domain, per Part 13.5). Switching to production can issue **entirely new keys** — if this happens, both `.env.local` (if you want production data locally, unusual) and Vercel's environment variables must be updated to match.
- **What breaks if missing/wrong:**
  - Missing `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` → the app throws immediately on any page load, with an error mentioning "Missing publishableKey."
  - Missing `CLERK_SECRET_KEY` → server-side calls like `auth()` and `currentUser()` throw or silently return null, breaking every protected route.
  - Wrong `_URL` values → redirects after sign-in/sign-up land on the wrong page, or 404.

### Neon

- **Where to find these values:** Neon Dashboard → your project → **Connection Details** panel → toggle between "Pooled connection" / "Direct connection" (naming may vary slightly by Neon UI version, but the `-pooler` hostname segment is the reliable tell).
- **Local vs. production:** Most readers of this course use the **same single Neon project** for both local development and production (Part 13.6) — meaning these two values are often identical between `.env.local` and Vercel. If you deliberately created a second, separate Neon project for production isolation, these values will differ, and you must run migrations against the new project separately (Part 13.6).
- **What breaks if missing/wrong:**
  - Missing `DATABASE_URL` → every single page throws a database connection error immediately.
  - Missing `DATABASE_URL_UNPOOLED` → `npm run db:generate`/`db:migrate` fail; the running app itself is unaffected, since only migrations use this value.
  - Using the **unpooled** string for `DATABASE_URL` in production → works fine at low traffic, then starts throwing intermittent "too many connections" errors as real usage grows (Part 3.2, Part 13 concept).

### Inngest

- **Where to find these values:** Inngest Dashboard → your app (`greymatter-ledger`) → **Manage** → **Keys** (exact navigation may vary slightly by Inngest dashboard version).
- **Local vs. production:** During local development (Parts 11–12), the local Inngest dev server (`npx inngest-cli@latest dev`) can often run without these keys at all, since it operates in a self-contained local mode. They become mandatory once syncing against Inngest's real cloud service, which is required for production (Part 13.7).
- **What breaks if missing/wrong:**
  - Missing `INNGEST_EVENT_KEY` → `inngest.send(...)` calls fail silently or throw, meaning background emails/reminders never fire, while the rest of the app (invoices, bills, reports) continues working completely normally — this is a good example of a "quiet" failure mode worth specifically checking for.
  - Missing `INNGEST_SIGNING_KEY` → Inngest's cloud service cannot verify requests to `/api/inngest`, and function syncing fails.

---

## B.3 — Environment Variable Scope on Vercel

Recall Part 13's reference section: Vercel lets you scope each variable to **Production**, **Preview**, and **Development**. For this course's simplicity, every variable in Section B.1 was checked for all three scopes. A more advanced setup, worth considering once you're past this course (see Part 14's roadmap), would use genuinely separate values per scope:

| Scope | Typical setup in a more advanced project |
|---|---|
| Production | Real Neon project, real Clerk production instance, real Inngest production keys |
| Preview | A separate Neon branch/project (Neon supports database branching specifically for this), Clerk's development instance, Inngest's dev/staging keys |
| Development | Your own local `.env.local`, never stored in Vercel at all |

For this course, all-scopes-identical is the correct, simplest choice — just be aware this is a deliberate simplification, not the only valid pattern.

---

## B.4 — Quick Diagnostic Table: "Which Variable Is Probably Wrong?"

| Symptom | Most likely variable |
|---|---|
| Every page throws immediately on load | `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` or `DATABASE_URL` |
| Sign-in works, but protected routes always redirect to sign-in even when logged in | `CLERK_SECRET_KEY` |
| After sign-up, redirected to the wrong page or a 404 | `NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL` |
| `npm run db:migrate` fails but the app itself runs fine | `DATABASE_URL_UNPOOLED` |
| App works fine with light testing, then throws "too many connections" under real traffic | `DATABASE_URL` is pointing at the unpooled string |
| Invoices/bills/payments all work, but no confirmation emails or reminders ever appear in logs | `INNGEST_EVENT_KEY` or `INNGEST_SIGNING_KEY` |
| `/api/inngest` returns an error instead of a function list | Missing import in `route.ts`, not an env var — check Part 11.2 |

---

## B.5 — Security Checklist (Cross-Reference to Part 13.1)

Before every `git push`, and especially before your very first one:

- [ ] `.gitignore` contains `.env*`
- [ ] `git status` never shows `.env.local` as trackable
- [ ] `git log --all --full-history -- .env.local` returns empty
- [ ] No environment variable value is ever hardcoded directly into a `.ts`/`.tsx` file as a fallback or default
- [ ] If any key was ever accidentally exposed (committed, screenshotted, pasted into a public chat), it is rotated immediately in that service's dashboard, and updated in both `.env.local` and Vercel
