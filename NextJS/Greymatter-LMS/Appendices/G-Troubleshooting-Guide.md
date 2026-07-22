# Appendix G — Troubleshooting Guide

This expanded reference is a complete, systematic troubleshooting guide for GreyMatter LMS. Rather than a flat list of "symptom → fix" pairs, each section below walks through **diagnostic reasoning** — how to narrow down the actual cause before applying a fix — because the same visible symptom (a blank page, a failed build) can have several genuinely different root causes. Every entry includes the exact error text to search for, the underlying mechanism that produces it, a step-by-step diagnostic path, the fix, and how to verify the fix actually worked.

---

## G.1 How to use this guide

Before diving into a specific section, run through this general diagnostic discipline — it resolves a surprising number of "mystery" bugs on its own:

```text
1. Read the FULL error message, not just the first line.
   Next.js, Drizzle, and Sanity errors often bury the actual cause
   two or three lines down, after a generic wrapper message.

2. Identify WHICH layer the error originates in:
   - Browser console → likely a Client Component / hydration issue
   - Terminal running `npm run dev` → likely a Server Component,
     Server Action, or Route Handler issue
   - `npm run build` output → likely a type error or a build-time
     data-fetching issue
   - Neon/Sanity/Clerk/Inngest's own dashboard → likely a
     configuration or connectivity issue, not application code

3. Reproduce with the SMALLEST possible change.
   Comment out unrelated code, isolate the failing call.

4. Check the "Common mistakes" section of the PART that introduced
   the feature you're debugging — every part in this series has one,
   and it's the fastest path to a known, documented fix.
```

---

## G.2 Next.js build failures

### G.2.1 `Module not found: Can't resolve '@/...'`

**What you'll see:**
```text
Module not found: Can't resolve '@/lib/auth/require-user'
```

**Root cause:** the `@/` path alias (Part 1, Step 4) isn't resolving — either `tsconfig.json`'s `paths` entry was removed/edited, or the file genuinely doesn't exist at that path, or there's a typo in the import.

**Diagnostic path:**
```bash
# 1. Confirm the alias is configured
cat tsconfig.json | grep -A2 '"paths"'
# Expected: "@/*": ["./*"]

# 2. Confirm the file genuinely exists at that path
ls -la lib/auth/require-user.ts

# 3. Confirm the import path exactly matches (case-sensitive on
#    Linux/Vercel, even if your local machine is case-insensitive)
```

**Fix:** restore the `paths` entry in `tsconfig.json` if missing; correct the import path/casing if mismatched. Case sensitivity is a common trap for Mac/Windows developers deploying to Vercel's Linux build environment — a file imported as `@/lib/Auth/requireUser` will build locally on macOS but fail on Vercel if the actual file is `lib/auth/require-user.ts`.

**Verify:** `npx tsc --noEmit` completes with no errors.

---

### G.2.2 Build fails only on Vercel, passes locally

**What you'll see:** `npm run build` succeeds on your machine; Vercel's deployment log shows a failure.

**Root cause:** almost always one of three things — a missing environment variable in Vercel's project settings (Part 16, Step 12), a case-sensitivity mismatch (G.2.1), or a dependency that behaves differently in a fresh `npm install` versus your local `node_modules` (a stale or manually-patched local install).

**Diagnostic path:**
```bash
# Reproduce Vercel's exact conditions locally:
rm -rf node_modules .next
npm ci        # NOT npm install — ci performs a clean, exact install from package-lock.json
npm run build
```

If this reproduces the failure, you've found a genuine dependency/config issue, not a Vercel-specific quirk. If it does **not** reproduce, the issue is almost certainly a missing/misconfigured environment variable — recheck Vercel's project settings against the complete list in Part 16, Step 12.

**Fix:** add the missing variable, or correct the casing mismatch, then redeploy.

---

### G.2.3 `Error: Missing environment variable: DATABASE_URL` (or similar) during build

**What you'll see:** a thrown error from `assertValue`-style guards (Part 3's `sanity/env.ts` pattern, Part 5's `getDatabaseUrl()`) at build time, not runtime.

**Root cause:** Next.js's build process executes Server Components to statically analyze/pre-render what it can — if a page or its dependencies read an environment variable that's absent even at build time, these fail-fast guards correctly throw.

**Diagnostic path:** identify which specific variable is missing from the error message, then check:
```bash
# Locally:
cat .env.local | grep VARIABLE_NAME

# On Vercel:
# Project Settings → Environment Variables → confirm it's listed
# under the correct environment scope (Production/Preview/Development)
```

**Fix:** add the missing variable to the correct scope. **Important:** Vercel's environment variables are scoped per-environment (Production, Preview, Development) — a variable added only under "Production" won't be available to Preview deployments, a common source of "works on my Vercel production, fails on the PR preview" confusion.

---

### G.2.4 Build succeeds, but a specific page 404s or 500s only in production

**Root cause:** frequently a data-fetching call that depends on a value only correctly configured in one environment (e.g., a Sanity dataset name that differs between dev/prod, or a Neon branch mismatch).

**Diagnostic path:**
```bash
# Confirm which Sanity dataset production is actually reading from:
echo $NEXT_PUBLIC_SANITY_DATASET   # should be "production" per Part 3

# Confirm which Neon branch production is connected to:
# (check the DATABASE_URL's hostname against Neon's console — Part 16,
#  Step 7's dedicated "production" branch, NOT your dev "main" branch)
```

**Fix:** ensure Vercel's production environment variables point at genuinely production-appropriate Sanity/Neon resources, not development ones accidentally copy-pasted across.

---

## G.3 React hydration errors

### G.3.1 `Hydration failed because the initial UI does not match what was rendered on the server`

**Root cause:** the HTML the server sent doesn't match what React produces when it "hydrates" (attaches interactivity to) that same HTML in the browser. Three common causes, in order of likelihood in this codebase:

**Cause A — a value that differs between server and client:**
```tsx
// PROBLEMATIC pattern (not present in GreyMatter's actual code, but
// illustrative of what would break):
export function BadTimestamp() {
  return <p>{new Date().toLocaleString()}</p>;
  // Server renders this at build/request time; the browser re-renders
  // it a moment later — the two timestamps can genuinely differ.
}
```
**Fix:** move any genuinely time-of-render-dependent value into a `useEffect` (runs only client-side, after hydration) rather than computing it during the initial render shared between server and client.

**Cause B — browser-only APIs read during initial render:**
```tsx
// PROBLEMATIC:
"use client";
export function BadWindowCheck() {
  const width = window.innerWidth; // `window` doesn't exist server-side
  return <p>{width}</p>;
}
```
Even in a Client Component, the *first* render pass still happens conceptually alongside the server's HTML for consistency — reading `window` directly during render (not inside `useEffect`) causes exactly this mismatch.

**Fix:**
```tsx
"use client";
import { useEffect, useState } from "react";
export function GoodWindowCheck() {
  const [width, setWidth] = useState<number | null>(null);
  useEffect(() => setWidth(window.innerWidth), []);
  return <p>{width ?? "..."}</p>;
}
```

**Cause C — invalid HTML nesting:**
A `<p>` containing a `<div>`, or a `<button>` nested inside another `<button>` (browsers silently "fix" invalid nesting when parsing raw HTML, producing a DOM structure that doesn't match what React expected to hydrate).

**Diagnostic path:** React's hydration error message in development mode includes a diff showing exactly which DOM node mismatched — read it carefully; it names the specific tag and location.

**Verify:** the warning disappears entirely from the browser console after the fix; a lingering hydration warning even after a fix usually means a *different* mismatch remains elsewhere on the same page.

---

### G.3.2 A Client Component's interactive button appears but does nothing on click

**Root cause:** almost always a missing or misplaced `"use client"` directive (Part 1's rule).

**Diagnostic path:**
```bash
# Confirm "use client" is the literal FIRST line of the file
head -n 1 components/your-component.tsx
# Expected: "use client";
```

Common mistakes: a blank line or comment *above* `"use client"`, using single quotes inconsistently in a way that a linter reformatted incorrectly, or the directive present in a *child* component but missing in a *parent* that also needs client-side behavior.

**Fix:** ensure `"use client"` is genuinely the first line, with nothing above it.

---

## G.4 Neon connection issues

### G.4.1 `Error: too many connections for role "..."` or `remaining connection slots are reserved`

**Root cause:** using the **direct** (non-pooled) Neon connection string in a serverless/edge context, where many short-lived function invocations each open their own connection, quickly exhausting Postgres's limited direct connection slots.

**Diagnostic path:**
```bash
echo $DATABASE_URL | grep -o "@[^/]*"
# If the hostname does NOT contain "-pooler", you're using the
# direct connection — this is the bug.
```

**Fix:** replace `DATABASE_URL` with Neon's **pooled** connection string (Part 5, Step 1 — the one containing `-pooler` in the hostname). Confirm both local `.env.local` and every Vercel environment scope use the pooled variant.

**Verify:**
```bash
npm run db:studio  # should connect without error
# Then generate load: rapidly refresh several authenticated dashboard
# pages in quick succession and confirm no connection errors appear
# in the terminal running `npm run dev`.
```

### G.4.2 `Connection terminated unexpectedly` (intermittent)

**Root cause:** Neon's serverless compute can scale to zero after a period of inactivity (a cost-saving feature) — the very first query after a cold period can occasionally hit a brief connection blip while compute spins back up.

**Diagnostic path:** check whether the error correlates with a period of no traffic (e.g., first request after leaving `npm run dev` idle overnight).

**Fix:** this is expected, transient behavior for Neon's free/scale-to-zero tier — no code change needed. If it happens frequently enough to be disruptive in production, Neon's paid tiers offer an "always-on" compute option that avoids scale-to-zero entirely.

---

## G.5 Migration failures

### G.5.1 `relation "users" already exists`

**Root cause:** a previous `db:migrate` run partially succeeded (some tables created), then failed partway through, leaving Drizzle's internal migration-tracking table out of sync with the real schema state.

**Diagnostic path:**
```bash
# Check which tables genuinely exist in the database right now:
npm run db:studio
# Compare against Drizzle's migration journal:
cat db/migrations/meta/_journal.json
```

**Fix:** if the tables that exist match what an earlier migration *would have* created, and you're confident no data needs preserving (safe in early development, dangerous in production), the cleanest fix is dropping the affected tables manually via Neon's SQL console, then re-running `npm run db:migrate` from a clean state. **In production, never do this without a backup** — instead, manually mark the specific migration as applied in Drizzle's tracking table, or write a corrective migration.

### G.5.2 `column "..." of relation "..." contains null values` during migration

**Root cause:** adding a new `NOT NULL` column to a table that already has existing rows — Postgres has no value to backfill those existing rows with.

**Diagnostic path:** identify which migration introduced the new `NOT NULL` column without a `.default(...)` value in the Drizzle schema.

**Fix:** add a sensible `.default(...)` to the column definition (so existing rows get a real value automatically), or write a two-step migration: add the column as nullable first, backfill existing rows with a data migration script, then add the `NOT NULL` constraint in a follow-up migration.

### G.5.3 `npm run db:generate` produces an empty migration (no changes detected)

**Root cause:** the schema file was edited, but Drizzle's snapshot of the *previous* schema state (stored in `db/migrations/meta/`) doesn't reflect a genuine difference — often because the file wasn't saved, or the edit was reverted by an auto-formatter.

**Diagnostic path:**
```bash
git diff db/schema/
# Confirm your intended change is genuinely present and saved
```

**Fix:** save the file, confirm the diff shows your change, then re-run `npm run db:generate`.

---

## G.6 Sanity CORS and content issues

### G.6.1 Browser console: `Access to fetch at 'https://xxx.api.sanity.io/...' has been blocked by CORS policy`

**Root cause:** the requesting domain isn't registered in Sanity's project CORS origins list (Part 16, Step 8).

**Diagnostic path:**
```bash
# Identify the EXACT origin the browser is requesting from —
# check the browser's Network tab, "Origin" request header
```
Common trap: registering `https://your-app.com` but the actual deployed URL is `https://your-app.vercel.app`, or vice versa — CORS matching is exact, not fuzzy.

**Fix:** visit sanity.io/manage → your project → API → CORS Origins, and add the **exact** origin (protocol + domain, no trailing slash), with "Allow credentials" checked if using authenticated Sanity requests.

**Verify:** hard-refresh the affected page (clear cache) and confirm the request succeeds in the Network tab.

### G.6.2 A published course doesn't appear on the site

**Root cause — walk through in this exact order, since each is progressively less common:**

```text
1. Was "Publish" clicked, or only "Save"?
   → In Studio, an unpublished draft is INVISIBLE to client.fetch()
     entirely — this is the single most common cause (Part 3/4).

2. Is isPublished (the CUSTOM boolean field) also true?
   → Sanity's own publish state and GreyMatter's isPublished field
     are TWO SEPARATE things (Appendix C, Section C.6). A course can
     be Sanity-published but still isPublished: false, hiding it from
     courseCatalogQuery specifically.

3. Has the 60-second revalidation window elapsed?
   → Part 4's `next: { revalidate: 60 }` means changes can take up
     to a minute to appear — not a bug, an intentional tradeoff.

4. Does the slug in the URL exactly match slug.current in Sanity?
   → Case-sensitive, exact string match required.
```

**Diagnostic path:** use Sanity Vision (`/studio/vision`) to run the exact query the page uses, with the exact same parameters, and inspect the raw result directly — this bypasses the application entirely and tells you definitively whether Sanity itself would return the document.

### G.6.3 An image renders as a broken icon

**Root cause:** almost always `next.config.ts`'s `remotePatterns` missing the Sanity CDN hostname (Part 4, Step 5), or the config was changed but the dev server wasn't restarted.

**Fix:**
```bash
cat next.config.ts | grep -A3 remotePatterns
# Confirm hostname: "cdn.sanity.io" is present
```
Restart `npm run dev` after any `next.config.ts` change — this file is only read at server startup, never hot-reloaded.

---

## G.7 Clerk webhook failures

### G.7.1 Webhook returns `Invalid signature` for every request, even genuine ones from Clerk

**Root cause, checked in this order:**

```text
1. Wrong signing secret — local vs. production endpoints have
   DIFFERENT secrets (Appendix F, Section F.6.3). Confirm you're
   using the secret for the SPECIFIC endpoint being tested.

2. Request body was consumed before signature verification —
   check for any earlier code path (middleware, a logging wrapper)
   that calls request.json() or request.text() before the webhook
   handler's own verification code runs. Once a request body stream
   is read once, it cannot be read again.

3. A proxy or platform layer (rare) altered the raw body in transit
   — e.g. re-serializing JSON with different whitespace/key order,
   which changes the exact bytes the signature was computed over.
```

**Diagnostic path:**
```ts
// Add a temporary diagnostic log INSIDE the webhook handler,
// immediately after reading the raw body, before verification:
const rawBody = await request.text();
console.log("Raw body length:", rawBody.length);
console.log("Svix headers present:", { svixId, svixTimestamp, svixSignature });
```
If headers are missing entirely, the issue is upstream (Clerk isn't sending them, or something is stripping them). If headers are present but verification still fails, focus on cause #1 or #2 above.

**Fix:** confirm the exact signing secret from Clerk's dashboard for the specific endpoint under test; ensure no code path reads the request body before the webhook's own `request.text()` call.

### G.7.2 Webhook succeeds (200 returned) but no user row appears

**Root cause:** either the event type isn't being handled (check the `switch` statement's cases match exactly), or `primaryEmail` resolution silently fails and the code path returns early.

**Diagnostic path:**
```bash
# Check the terminal running `npm run dev` for the specific log line:
# "Provisioned internal user for Clerk ID: ..." — its ABSENCE tells
# you execution never reached that point.
```
Common cause: a test account created via Clerk's dashboard with no email address configured, causing `clerkUser.email_addresses.find(...)` to return `undefined`.

**Fix:** ensure test accounts have a genuine primary email; add a defensive log immediately before the `throw new Error("Clerk user has no primary email address")` line to confirm this is (or isn't) the actual failure point.

---

## G.8 Inngest functions not executing

### G.8.1 Dashboard shows the app connected, but zero functions listed

**Root cause:** `functions/index.ts`'s exported array is empty, stale, or the dev server needs restarting after a change to `app/api/inngest/route.ts`.

**Diagnostic path:**
```bash
cat inngest/functions/index.ts
# Confirm every function you expect is genuinely imported AND
# included in the exported `functions` array — a common mistake is
# writing a new function file but forgetting this registration step.
```

**Fix:** add the missing import/array entry, restart `npm run dev`, and confirm `npx inngest-cli@latest dev` re-syncs (its terminal output shows a fresh "synced" message).

### G.8.2 An event is sent (confirmed in Inngest's "Events" tab) but no function run appears

**Root cause:** a typo'd event name — since event names are plain strings passed to `inngest.send()`, a mismatch between the emitted name and a function's `{ event: "..." }` trigger produces **no error at all**, just silence.

**Diagnostic path:**
```bash
# Confirm the EXACT string used in both places matches character-for-character:
grep -rn '"course/enrolled"' inngest/ app/
```
Since Part 12 typed every event through `GreyMatterEvents`, using the typed `inngest.send({ name: "...", ... })` call (rather than a loosely-typed alternative) should make TypeScript itself catch a genuine typo — if you're seeing this issue, check whether the call site is somehow bypassing the typed catalog.

**Fix:** correct the mismatched string; rely on `GreyMatterEvents`' type safety going forward rather than raw string literals typed outside the catalog.

### G.8.3 A cron function never fires locally

**Root cause:** this is largely expected, not a bug — Inngest's local dev server only honors real cron schedules if it runs continuously across the actual scheduled time; short development sessions will simply never reach `09:00 UTC` unless you happen to be actively running the dev server at that exact moment.

**Fix:** for local testing, always use the dashboard's manual "Invoke" / "Trigger" button (Part 14's verification steps) rather than waiting for the real schedule. Reserve genuine schedule-based testing for the deployed production environment, where the app runs continuously.

### G.8.4 A function run shows status "Failed" with a serialization-related error

**What you'll see:** something like `Cannot serialize step result` or a run that fails specifically at a `step.run` boundary with no application-level error message.

**Root cause:** returning a non-JSON-safe value (a `Set`, `Map`, `Date` object, class instance, or `undefined`) from inside a `step.run` callback — Inngest must serialize every step's result to persist it durably for retry/replay.

**Fix:** convert to a plain, JSON-safe value before returning — exactly the `Array.from(set)` pattern used in `recalculate-course-progress` (Part 12).

---

## G.9 Stale cache data

### G.9.1 A user's own action (enrollment, preference change) doesn't appear immediately

**Root cause:** a missing `revalidatePath(...)` call after the write succeeds (Part 8's on-demand invalidation pattern).

**Diagnostic path:**
```bash
grep -n "revalidatePath" app/dashboard/courses/actions.ts
# Confirm it's called for EVERY path the user will subsequently
# visit that displays the changed data — a common oversight is
# revalidating the specific resource's page but forgetting the
# overview/list page that ALSO displays a summary of it.
```

**Fix:** add the missing `revalidatePath` call immediately after the write's transaction commits.

### G.9.2 Sanity content changes take longer than expected to appear

**Root cause:** this is very likely *not* a bug — recall Part 4's deliberate 60-second `next: { revalidate: 60 }` window. This is a designed tradeoff, not a defect.

**Diagnostic path:** time how long the delay actually is. If consistently under ~60 seconds, this is expected behavior. If changes never appear even after several minutes, the issue is more likely G.6.2 (draft not published, or `isPublished` flag) than a caching problem at all.

**Fix (only if genuinely instant updates are required for a specific admin action):** replace the time-based `revalidate` option with on-demand `revalidatePath`/`revalidateTag`, called explicitly right after the specific write that needs to be reflected immediately — as already done for enrollment (Part 8).

---

## G.10 Environment variable misconfiguration

### G.10.1 A feature silently "no-ops" instead of erroring

**Root cause:** several subsystems in this series are deliberately built with **graceful fallbacks** for missing configuration (Part 13's email dev-fallback, Part 16's rate-limit no-op) — this is intentional design, not a bug, but it can be mistaken for one if you forget the fallback exists.

**Diagnostic path:**
```text
Symptom: "I configured RESEND_API_KEY but I don't see a real email"
    │
    ▼
Check: is the terminal instead showing "(DEV) Would send..." logs?
    │
   Yes ──► RESEND_API_KEY isn't actually being read — check for a typo
    │        in the variable name, or confirm the dev server was
    │        restarted after adding it to .env.local
    │
   No  ──► A different issue — check Resend's own dashboard/API logs
```

**Fix:** restart the dev server after any `.env.local` change (environment variables are read once, at process startup, never hot-reloaded); confirm exact variable name spelling against `.env.example`.

### G.10.2 `NEXT_PUBLIC_` variable is `undefined` in browser code

**Root cause:** `NEXT_PUBLIC_` variables are inlined into the JavaScript bundle **at build time**, not read dynamically at runtime — if the variable wasn't present during `npm run build`, no later runtime change to the environment will fix it; the value is permanently baked into that specific build's bundle.

**Diagnostic path:** confirm the variable was present in the environment *during the build step specifically* (not just added afterward to a running server's environment).

**Fix:** ensure the variable is set correctly in Vercel *before* triggering a new deployment/build — then redeploy. Simply adding the variable to an already-built, already-deployed instance has no effect until the next build.

---

## G.11 A master diagnostic flowchart

When you're not sure which section above applies, start here:

```text
Where does the error/symptom first appear?
        │
        ├── Browser console, red error ──► G.3 (hydration) or check
        │                                    if it's a thrown error
        │                                    reaching error.tsx (G.8.1
        │                                    reasoning about "silence"
        │                                    doesn't apply — a VISIBLE
        │                                    error means something DID
        │                                    run; read its message)
        │
        ├── `npm run dev` terminal ──► Likely Server Component/Action/
        │                               Route Handler — check which
        │                               PART's file is involved, then
        │                               that part's own "Common
        │                               mistakes" section first
        │
        ├── `npm run build` output ──► G.2
        │
        ├── Neon console / Drizzle Studio shows unexpected data ──►
        │     G.4 (connection) or G.5 (migration) or trace back to
        │     which query/mutation wrote the unexpected state
        │
        ├── Sanity Studio or public pages show wrong/missing content ──►
        │     G.6
        │
        ├── Clerk dashboard shows a failed webhook delivery ──► G.7
        │
        ├── Inngest dashboard shows missing/failed runs ──► G.8
        │
        ├── Data is correct in the database but stale on screen ──► G.9
        │
        └── A feature behaves as if unconfigured, no error at all ──►
              G.10 (check for a deliberate graceful-fallback pattern
              FIRST, before assuming it's broken)
```
