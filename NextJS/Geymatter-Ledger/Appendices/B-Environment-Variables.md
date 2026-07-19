# Appendix B: Environment Variables Reference

Every environment variable used across the entire series, where it comes from, what it looks like, what breaks if it's wrong, and how it differs between local development and production.

## B.1 — The Complete `.env.local` File, Fully Annotated

```bash
# =========================================================
# CLERK — Authentication & Organizations (Part 2)
# =========================================================
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxxxxxxxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxx
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_AFTER_SIGN_IN_URL=/dashboard
NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL=/dashboard

# =========================================================
# NEON — Postgres Database (Part 3)
# =========================================================
DATABASE_URL=postgresql://neondb_owner:PASSWORD@ep-xxxx-pooler.REGION.aws.neon.tech/neondb?sslmode=require
DATABASE_URL_UNPOOLED=postgresql://neondb_owner:PASSWORD@ep-xxxx.REGION.aws.neon.tech/neondb?sslmode=require

# =========================================================
# INNGEST — Background & Scheduled Jobs (Part 11)
# =========================================================
INNGEST_EVENT_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
INNGEST_SIGNING_KEY=signkey-prod-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**Location, confirmed unaffected by the `src/` correction:** `.env.local` sits at the project root — sibling to `package.json`, `proxy.ts`, `app/`, `lib/`, and `db/` — exactly as it always has, in every version of this project's folder layout.

## B.2 — Per-Service Setup Notes

### Clerk
- **Where to find these values:** Clerk Dashboard → your application → **API Keys**.
- **Local vs. production:** Clerk distinguishes a **Development instance** (relaxed domain checks, unlimited test users) from a **Production instance** (added once you have a real domain, Part 13.5) — switching can issue entirely new keys.
- **What breaks if missing/wrong:**
  - Missing `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` → app throws immediately on load.
  - Missing `CLERK_SECRET_KEY` → `auth()`/`currentUser()` throw or silently return null, breaking every protected route.
  - Wrong `_URL` values → redirects land on the wrong page or 404.

### Neon
- **Where to find these values:** Neon Dashboard → project → **Connection Details** → toggle Pooled/Direct.
- **Local vs. production:** Most readers use the same single Neon project for both (Part 13.6); the values only diverge if a separate production project was deliberately created.
- **What breaks if missing/wrong:**
  - Missing `DATABASE_URL` → every page throws a database connection error immediately.
  - Missing `DATABASE_URL_UNPOOLED` → migrations fail; the running app is unaffected.
  - Unpooled string used for `DATABASE_URL` in production → intermittent "too many connections" errors under real traffic (Part 3.2, Part 13).

### Inngest
- **Where to find these values:** Inngest Dashboard → app → **Manage** → **Keys**.
- **Local vs. production:** The local dev server (`npx inngest-cli@latest dev`) can often run without these at all; they become mandatory once syncing against the real cloud service (Part 13.7).
- **What breaks if missing/wrong:**
  - Missing `INNGEST_EVENT_KEY` → `inngest.send(...)` fails silently or throws — background emails/reminders never fire, while the rest of the app continues working normally. A good example of a "quiet" failure mode worth specifically checking for.
  - Missing `INNGEST_SIGNING_KEY` → function syncing and request verification fail (see Appendix F, T6).

## B.3 — Environment Variable Scope on Vercel

Vercel lets you scope each variable to **Production**, **Preview**, and **Development**. This course checks all three scopes identically for simplicity — a deliberate simplification, not the only valid pattern; a more advanced setup would use genuinely separate Neon/Clerk instances per scope.

## B.4 — Quick Diagnostic Table

| Symptom | Most likely variable |
|---|---|
| Every page throws immediately on load | `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` or `DATABASE_URL` |
| Sign-in works, but protected routes always redirect to sign-in even when logged in | `CLERK_SECRET_KEY` |
| After sign-up, redirected to the wrong page or a 404 | `NEXT_PUBLIC_CLERK_AFTER_SIGN_UP_URL` |
| `npm run db:migrate` fails but the app itself runs fine | `DATABASE_URL_UNPOOLED` |
| App works fine lightly, then throws "too many connections" under real traffic | `DATABASE_URL` pointing at the unpooled string |
| Invoices/bills/payments all work, but no confirmation emails, reminders, or CPF/recurring jobs ever fire | `INNGEST_EVENT_KEY` or `INNGEST_SIGNING_KEY` |
| `/api/inngest` returns an error instead of a function list | Missing import in `app/api/inngest/route.ts`, not an env var |

## B.5 — Security Checklist (Cross-Reference to Part 13.1 and Appendix G.5)

- [ ] `.gitignore` contains `.env*`
- [ ] `git status` never shows `.env.local` as trackable
- [ ] `git log --all --full-history -- .env.local` returns empty
- [ ] No environment variable value is ever hardcoded as a fallback/default directly in a `.ts`/`.tsx` file
- [ ] Any accidentally exposed key is rotated immediately in that service's dashboard, then updated in both `.env.local` and Vercel

## B.6 — Note on Part 14.8's `bank_connections.accessToken`

Worth stating explicitly here, since it's the one credential-like value introduced by any extension: it is **not** an environment variable and does not belong in `.env.local`. It's a per-organization, per-bank-account secret stored as a database row (`bank_connections.accessToken`), and — as flagged in Appendix A.20 and Appendix F's T5 — stored as plain text in this course's implementation, with application-layer encryption explicitly called out as required before real production use. This distinguishes it from every other secret in this appendix, which are all static, singular values shared across the whole app.
