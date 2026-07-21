# Part 1: Foundations — Moving Beyond Legal Compliance to System Design

---

## 1.1 Security ≠ Privacy: A Distinction Every Engineer Must Internalize

Before we write a single line of code, we need to fix a misconception that causes more privacy failures than any missing encryption library: **security and privacy are not the same discipline, and one does not imply the other.**

**Analogy:** Imagine a diary with an unbreakable steel lock, stored inside a bank vault, guarded 24/7. That's *excellent security* — no unauthorized person can get in. Now imagine the diary's owner never gave permission for the diary to be written in the first place, doesn't know it exists, and can never ask for it to be destroyed. That is a **privacy failure**, despite perfect security.

Concretely:
- **Security** asks: *"Can an unauthorized party access this data?"* (confidentiality, integrity, availability)
- **Privacy** asks: *"Should this data have been collected, retained, or processed at all — and does the person it describes have control over that?"* (necessity, consent, purpose limitation, individual rights)

A perfectly encrypted database that retains a user's location history for 10 years after they deleted their account, with no way for them to ever get it erased, is **secure but not private**. This series is not primarily a security course (though we'll build real security controls in Part 3) — it's a course on the *second* question, the one most engineering curricula skip entirely.

---

## 1.2 The 7 Foundational Principles of Privacy by Design

Dr. Ann Cavoukian's original framework has 7 principles, written for policy audiences. Our job is translating each into something an engineer can implement. This table is our north star for the rest of the series — we will refer back to it by number (e.g., "this satisfies Principle 2").

| # | Cavoukian's Principle | Engineering Translation | Where We Build It |
|---|---|---|---|
| 1 | Proactive not Reactive | Threat-model and DPIA *before* writing schema code, not after a breach | Part 1 (now) |
| 2 | Privacy as the Default Setting | Every new field, endpoint, and consent toggle defaults to the *most restrictive* state | Parts 2 & 4 |
| 3 | Privacy Embedded into Design | Encryption/minimization aren't optional middleware you can forget — they're structurally required to compile/run | Parts 2 & 3 |
| 4 | Full Functionality (Positive-Sum) | Privacy controls that don't cripple UX — a consent flow with zero added friction | Part 4 |
| 5 | End-to-End Security | Lifecycle protection: create → store → transmit → delete, not just "at rest" | Parts 3 & 5 |
| 6 | Visibility and Transparency | Users and auditors can verify claims — immutable consent ledger, DSAR exports | Parts 4 & 5 |
| 7 | Respect for User Privacy | The system is architected user-centric — the person, not the business, controls their data | All parts, esp. 4 & 5 |

---

## 1.3 The Target: Your First Data Protection Impact Assessment (DPIA)

**The Concept:** A DPIA is a structured document that answers: *what personal data are we collecting, why, where does it flow, who can see it, and what's the worst that could happen if it leaked?* Think of it as a **building inspector's blueprint review** — done *before* construction, not after the tenants move in. GDPR Article 35 legally requires a DPIA for high-risk processing (which special-category health data always triggers) — but we're doing this because it's the single highest-leverage engineering document you can write before touching a database schema.

**Why we do this before any code:** You cannot minimize a schema (Part 2) or decide what to encrypt (Part 3) without first knowing every field you *intend* to collect and why. Skipping this step is the #1 cause of "privacy debt" — schemas that grow organically and accumulate unnecessary PII no one remembers approving.

### The Implementation

**File: `docs/dpia/dpia-mindfullog-v1.md`**

```markdown
# Data Protection Impact Assessment (DPIA) — MindfulLog v1

**Status:** Draft
**Owner:** Engineering Lead
**Last Reviewed:** (fill in current date)
**Review Trigger:** Any new personal data field, new third-party vendor, or new data flow

---

## 1. Description of Processing

MindfulLog is a mental-health journaling and mood-tracking web application.
Users create an account, log daily mood scores, write free-text journal
entries, and set medication reminders. The system also manages user consent
preferences and must support data export and deletion on request.

## 2. Data Inventory (What We Collect and Why)

| Field                     | Category                  | Purpose                                | Necessity Justification                              | Retention                                |
|---------------------------|----------------------------|-------------------------------------------|----------------------------------------------------------|---------------------------------------------|
| Email address              | Identifying                | Login, account recovery, notifications      | Required for authentication (via Clerk)                    | Life of account                              |
| Display name (optional)    | Identifying                | Personalization                            | Not required for core function — must be optional         | Life of account                              |
| Mood score (1-10)          | Special category (health)   | Core product feature                       | Directly required — the product's purpose                  | Life of account + user-set export window     |
| Mood note (free text)      | Special category (health)   | Core product feature                       | Directly required, must be field-level encrypted            | Life of account                              |
| Journal entry text         | Special category (health)   | Core product feature                       | Directly required, must be field-level encrypted            | Life of account                              |
| Medication reminder text   | Special category (health)   | Core product feature                       | Directly required, must be field-level encrypted            | Life of account                              |
| Consent preferences        | Preference data             | Legal basis tracking, UX personalization     | Required to prove lawful basis for processing                | 7 years post-decision (audit requirement)    |
| IP address (login events)  | Technical/identifying       | Security (abuse/fraud detection)            | Required for security, NOT for product features             | 30 days (TTL)                                 |
| Session tokens              | Technical                   | Authentication                             | Required, ephemeral only                                     | Session lifetime (TTL)                        |

## 3. Data Flow Map

1. Browser -> Next.js Server: All fields above, over TLS 1.3.
2. Next.js Server -> Clerk: Email, display name, session/auth events.
   (Clerk is a third-party data processor — see Vendor Register, Section 5)
3. Next.js Server -> Neon (Postgres): Mood scores, mood notes (encrypted),
   journal entries (encrypted), medication reminders (encrypted),
   consent ledger entries (append-only), and pseudonymized user references.
4. Next.js Server -> Inngest: Event payloads (e.g., user.deletion.requested,
   consent.updated, dsar.export.requested). These payloads MUST carry only
   a pseudonymous internal user ID — never raw email, name, or journal text —
   because Inngest's event log is a third-party system outside our direct
   database access controls.
5. Inngest -> Neon: Background jobs read/write the same encrypted tables
   above, plus TTL-based deletion sweeps on ephemeral tables (Part 2).
6. Inngest -> Clerk (Backend API): Deletion orchestrator calls Clerk's
   Backend API to remove the user's identity record on account deletion
   (Part 5). This is a one-way, one-time call per deletion request.
7. Next.js Server -> Cloud KMS: Requests to encrypt/decrypt Data Encryption
   Keys (DEKs) only. Raw plaintext journal/mood content NEVER leaves our
   server process and is NEVER sent to the KMS directly (Part 3, envelope
   encryption pattern).

## 4. Risk Assessment

| Risk                                                        | Likelihood | Impact   | Mitigation                                                                 |
|--------------------------------------------------------------|------------|----------|------------------------------------------------------------------------------|
| Database breach exposes plaintext journal entries              | Medium     | Severe   | Field-level encryption (Part 3) — breach yields ciphertext only              |
| Consent state disputed in a legal complaint                    | Low        | High     | Immutable, timestamped consent ledger (Part 4)                               |
| User requests deletion, but data persists in backups/streams    | Medium     | High     | Documented tombstone + retention-aware deletion strategy (Part 5)             |
| PII leaks into application logs or error trackers                | High       | Medium   | PII-redacting logger + CI static scanner (Part 6)                            |
| Third-party vendor (Clerk) breach exposes email/name             | Low        | Medium   | Vendor contractual review + minimal data shared with vendor                   |
| Over-collection creep (new field added without review)          | High       | Medium   | DPIA-diff check in CI blocks schema PRs missing a DPIA update (Part 6)         |

## 5. Vendor / Third-Party Processor Register

| Vendor  | Data Shared                                            | Role (GDPR term)   | Data Location                     |
|---------|-----------------------------------------------------------|------------------------|---------------------------------------|
| Clerk   | Email, display name, auth/session events                    | Data Processor          | Clerk's cloud infrastructure          |
| Neon    | All application tables (encrypted where sensitive)           | Data Processor          | Configurable region (we select)       |
| Inngest | Event payloads (pseudonymous IDs + metadata only)             | Data Processor          | Inngest's cloud infrastructure         |

## 6. Legal Basis for Processing

- Mood/journal/medication data: Explicit consent (GDPR Art. 9(2)(a)) —
  captured and versioned in the Consent Ledger (Part 4).
- Account email/auth: Contractual necessity (GDPR Art. 6(1)(b)) — required
  to provide the service the user signed up for.
- Security logs (IP, session): Legitimate interest (GDPR Art. 6(1)(f)),
  narrowly scoped to fraud/abuse prevention, with a strict 30-day TTL.

## 7. Data Subject Rights Supported

- [x] Right to Access (Art. 15) — DSAR export engine, Part 5
- [x] Right to Rectification (Art. 16) — standard "edit" endpoints
- [x] Right to Erasure (Art. 17) — deletion orchestrator, Part 5
- [x] Right to Restrict Processing (Art. 18) — consent toggles, Part 4
- [x] Right to Data Portability (Art. 20) — JSON/ZIP export, Part 5
- [x] Right to Object (Art. 21) — consent withdrawal, Part 4

## 8. Sign-off

This DPIA must be re-reviewed whenever:
- A new personal data field is added to any schema.
- A new third-party vendor receives any user data.
- A new data flow crosses a system boundary not listed in Section 3.

Automated enforcement of this rule is implemented in Part 6 via a CI check
that diffs schema migrations against this document's Data Inventory table.
```

### The Verification

You won't run code yet, but you *will* verify this artifact like an engineer, not like a lawyer:

**Step 1 — Initialize the repo and commit the DPIA**
```bash
mkdir mindfullog && cd mindfullog
git init
mkdir -p docs/dpia
# paste the file content above into docs/dpia/dpia-mindfullog-v1.md
git add docs/dpia/dpia-mindfullog-v1.md
git commit -m "docs: initial DPIA for MindfulLog v1"
```

**Step 2 — Manual "test suite" for a document**

Ask yourself these three questions, out loud, checking each row of the DPIA:
- Does every field in Section 2 have a **non-empty** Necessity Justification? (If you can't justify it, it shouldn't be collected — this is Principle 1 in action.)
- Does every arrow in Section 3's Data Flow Map correspond to a vendor in Section 5, if it crosses outside our own infrastructure? (Cross-reference Clerk, Neon, Inngest — all three appear in both sections.)
- Does every risk in Section 4 have a mitigation that maps to a **specific future Part** of this series? (This is how we know our roadmap isn't arbitrary — every part exists to close a specific, named risk.)

If any of these checks fail on a document you write for a real project, that's your signal to keep refining the DPIA *before* writing schema code — exactly the discipline Principle 1 demands.

---

## 1.4 The Target: Scaffolding the MindfulLog Repository

**The Concept:** Now that we know *what* we're collecting and *why* (our DPIA), we can scaffold the actual application skeleton. Think of this like pouring the foundation slab of a house only after the architectural blueprint (DPIA) is approved — pouring concrete first and designing later is how you end up with load-bearing walls in the wrong place.

### The Implementation

**Step 1 — Create the Next.js 16 project**

```bash
npx create-next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias "@/*"
```

When prompted, accept the defaults (App Router, `src/` directory, Tailwind, ESLint). This gives us Next.js 16 with the App Router — a file-based routing system where each folder under `app/` is like a physical room in our house, and a `page.tsx` file inside it means "this room is open to visitors."

**Step 2 — Install core dependencies**

```bash
npm install @clerk/nextjs @neondatabase/serverless drizzle-orm inngest
npm install -D drizzle-kit dotenv
```

- `@clerk/nextjs` — Clerk's official Next.js SDK (our front-desk security guard).
- `@neondatabase/serverless` — the low-latency serverless driver for talking to Neon Postgres over HTTP (important because traditional TCP Postgres drivers don't work well in serverless environments — see Reference 1.A below).
- `drizzle-orm` / `drizzle-kit` — a lightweight, type-safe SQL query builder and migration tool. We choose Drizzle over something heavier like Prisma because it keeps our SQL schema visible and explicit — critical for a series where *seeing exactly what columns exist* is the whole point.
- `inngest` — our durable background function SDK.

**Step 3 — Project structure**

```
mindfullog/
├── docs/
│   ├── dpia/
│   │   └── dpia-mindfullog-v1.md
│   └── engineering/
│       └── privacy-defaults.md
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── api/
│   │       └── inngest/
│   │           └── route.ts
│   ├── db/
│   │   ├── schema.ts
│   │   └── index.ts
│   ├── inngest/
│   │   └── client.ts
│   └── middleware.ts
├── .env.local
├── drizzle.config.ts
├── package.json
└── tsconfig.json
```

**Step 4 — Environment variables**

**File: `.env.local`**
```bash
# --- Clerk (get these from clerk.com dashboard after creating an app) ---
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxxxxxxxxx
CLERK_SECRET_KEY=sk_test_xxxxxxxxxxxxxxxxxxxx

# --- Neon (get this from neon.tech dashboard after creating a project) ---
DATABASE_URL=postgresql://user:password@ep-xxxx.us-east-2.aws.neon.tech/mindfullog?sslmode=require

# --- Inngest (local dev needs no keys; production needs these from inngest.com) ---
INNGEST_EVENT_KEY=
INNGEST_SIGNING_KEY=
```

> **Why `.env.local` and not hardcoded strings?** This is Principle 3 (Privacy Embedded into Design) in its simplest form: secrets and connection strings must never be committed to source control, because a leaked database credential is a leaked *entire user database*. Add `.env.local` to `.gitignore` immediately — Next.js does this by default, but verify it:

```bash
cat .gitignore | grep env
# should output: .env*.local
```

**File: `src/db/index.ts`**
```typescript
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import * as schema from "./schema";

// The neon() function creates an HTTP-based SQL client — not a persistent
// TCP connection. This matters because serverless functions (like Next.js
// Route Handlers deployed on Vercel) spin up and down constantly; a
// traditional TCP connection pool would exhaust the database's connection
// limit almost immediately under load. HTTP-based queries have no
// "connection" to leak, because there's no long-lived connection at all.
const sql = neon(process.env.DATABASE_URL!);

// We pass our schema module in here so Drizzle gives us fully typed query
// results later (e.g., db.query.users.findFirst() will be typed, not `any`).
export const db = drizzle(sql, { schema });
```

**File: `src/inngest/client.ts`**
```typescript
import { Inngest } from "inngest";

// The Inngest client is our "event bus handle" — every background job we
// trigger later (Parts 2, 4, 5) will import this single client instance to
// either send events into the system or define functions that react to them.
// Giving it a stable `id` lets Inngest's dashboard group all our functions
// under one recognizable application.
export const inngest = new Inngest({ id: "mindfullog" });
```

**File: `src/app/api/inngest/route.ts`**
```typescript
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";

// This single route is the ONLY HTTP endpoint Inngest needs to talk to our
// app. Think of it as a mail slot: Inngest drops a "run this function"
// letter through it, and serve() handles unpacking that letter, running the
// right function, and reporting the result back. As we add functions in
// later Parts (TTL sweeps in Part 2, consent sync in Part 4, DSAR/deletion
// jobs in Part 5), we register them in the functions array below — this
// file is the single source of truth for "every background job our app
// can run."
export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [
    // Part 2 onward: functions get pushed into this array as we build them,
    // e.g. ttlCleanupSweep, syncConsentState, generateDsarExport, etc.
  ],
});
```

**File: `src/middleware.ts`**
```typescript
import { clerkMiddleware, createRouteMatcher } from "@clerk/nextjs/server";

// clerkMiddleware runs on every matched request BEFORE it reaches any page
// or API route — like a security guard checking badges at the building
// entrance before anyone reaches an elevator. We define which "floors"
// (routes) require a valid badge (authenticated session).
const isProtectedRoute = createRouteMatcher([
  "/dashboard(.*)",
  "/api/mood(.*)",
  "/api/journal(.*)",
]);

export default clerkMiddleware(async (auth, req) => {
  // If the requested route is protected and there's no valid session,
  // Clerk automatically redirects to sign-in. We are explicit here rather
  // than protecting everything by default-deny at the middleware layer,
  // because our marketing/landing pages must remain public.
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});

export const config = {
  matcher: [
    // Skip Next.js internals and static files, run on everything else
    "/((?!_next|[^?]*\\.(?:html?|css|js(?!on)|jpe?g|webp|png|gif|svg|ttf|woff2?|ico|csv|docx?|xlsx?|zip|webmanifest)).*)",
    "/(api|trpc)(.*)",
  ],
};
```

**File: `src/app/layout.tsx`**
```typescript
import type { Metadata } from "next";
import { ClerkProvider } from "@clerk/nextjs";
import "./globals.css";

export const metadata: Metadata = {
  title: "MindfulLog",
  description: "A private-by-design mood and journaling app.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    // ClerkProvider wraps the entire app so any component, anywhere in the
    // tree, can ask "is there a logged-in user right now?" without every
    // page having to manually fetch session state itself.
    <ClerkProvider>
      <html lang="en">
        <body className="antialiased">{children}</body>
      </html>
    </ClerkProvider>
  );
}
```

**File: `src/app/page.tsx` (continued)**
```typescript
import { SignedIn, SignedOut, SignInButton, UserButton } from "@clerk/nextjs";

export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-6 p-8">
      <h1 className="text-3xl font-bold text-slate-800">MindfulLog</h1>
      <p className="text-slate-600 max-w-md text-center">
        A mood-tracking and journaling app engineered to be private by
        default, not by afterthought.
      </p>

      {/* SignedOut/SignedIn are Clerk components that render conditionally
          based on auth state — no manual "if (user)" checks needed here. */}
      <SignedOut>
        <SignInButton mode="modal">
          <button className="rounded-lg bg-slate-800 px-4 py-2 font-semibold text-white hover:bg-slate-700">
            Sign In
          </button>
        </SignInButton>
      </SignedOut>
      <SignedIn>
        <UserButton afterSignOutUrl="/" />
      </SignedIn>
    </main>
  );
}
```

**File: `drizzle.config.ts`**
```typescript
import { defineConfig } from "drizzle-kit";
import * as dotenv from "dotenv";

dotenv.config({ path: ".env.local" });

// This config tells drizzle-kit (our migration CLI tool) where our schema
// lives, what database dialect to speak, and how to connect. We'll flesh
// out schema.ts fully in Part 2 — for now it can be an empty file so the
// tool doesn't error out.
export default defineConfig({
  schema: "./src/db/schema.ts",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});
```

**File: `src/db/schema.ts`** (placeholder — fully built in Part 2)
```typescript
// Intentionally minimal for now. Every table and column added here from
// Part 2 onward must first be justified in the DPIA (Section 1.3) before
// it appears in this file — that ordering is not a suggestion, it's the
// enforced discipline this entire series is built around.
export {};
```

### The Verification

**Check 1 — Confirm the dev server boots cleanly**
```bash
npm run dev
```
Open `http://localhost:3000` — you should see the MindfulLog landing page with a working "Sign In" button. Click it: a Clerk modal should appear (using the publishable key from `.env.local`). Sign up with a test email, and you should see the button change to a circular user avatar (`UserButton`), confirming Clerk's session state is live end-to-end.

**Check 2 — Confirm the database connection works (even with an empty schema)**
```bash
npx drizzle-kit introspect
```
This should connect to Neon successfully and report zero existing tables — confirming `DATABASE_URL` is valid and reachable, without yet creating anything (we don't have a schema to migrate until Part 2).

**Check 3 — Confirm the Inngest endpoint is live**
```bash
npx inngest-cli@latest dev
```
Then visit `http://localhost:8288` (the local Inngest Dev Server UI) — it should detect your app at `http://localhost:3000/api/inngest` and show "0 functions registered," which is correct and expected at this stage. This confirms the mail-slot (our route handler) is correctly wired before we ever put a letter through it.

---

## 1.5 The Target: Establishing "Privacy as the Default Setting" as a Repo-Level Rule

**The Concept:** Principle 2 says every new setting should start in its *most private* state, requiring the user to actively opt into anything less private — never the reverse. This isn't just a UI rule; it's an engineering contract we enforce structurally, starting now, before a single user-facing toggle exists.

**Analogy:** A hotel room's curtains should be closed by default when you check in. It should never be the guest's job to notice and close them — it should be the guest's job, if they want light, to *choose* to open them.

### The Implementation

We encode this rule directly as a project convention document — a lightweight but binding artifact, exactly like an ESLint config, except it governs data-modeling decisions rather than syntax.

**File: `docs/engineering/privacy-defaults.md`**
```markdown
# Engineering Rule: Privacy as the Default Setting

This rule is binding for every schema, API, and UI change in this repository.

## The Rule

1. Every new boolean consent/preference column MUST default to the most
   restrictive value (false for anything that shares, exposes, or
   processes data beyond core function).
2. Every new API endpoint returning user data MUST require explicit
   authorization checks — there is no "public by default" endpoint for
   any authenticated resource.
3. Every new database column storing personal data MUST be evaluated
   against the DPIA (docs/dpia/) before merge. If it's not in the DPIA's
   Data Inventory table, it does not get merged.
4. Every new analytics/tracking integration MUST ship in a disabled state
   until a corresponding consent record exists for the user (built in
   Part 4).

## Enforcement

- Manual: PR reviewers check this file as part of code review, same as a
  style guide.
- Automated: Part 6 introduces a CI job that fails the build if a new
  boolean column default of true is detected in a migration diff for
  any column matching consent/tracking naming patterns.
```

```bash
git add docs/engineering/privacy-defaults.md
git commit -m "docs: codify Privacy as the Default Setting as a binding repo rule"
```

### The Verification

There's no server output to check here — the verification is a **process check**: from this commit forward, every future Part of this series will explicitly cite this document when adding any new field or toggle. You can verify Part 2 honors it by confirming (when we get there) that every new consent-adjacent column's migration SQL includes `DEFAULT false`.

---

## Part 1 — Reference Section: Deep Dives

*(Isolated here per our format — read now for depth, or skip ahead to Part 2 and return later.)*

### Reference 1.A — Why HTTP-based Postgres drivers matter in serverless

Traditional Postgres drivers (`pg`, `node-postgres`) hold a persistent TCP socket open to the database. In a long-running server (like a traditional Express app on a single EC2 instance), this is efficient — one connection pool, reused forever. But Next.js Route Handlers and Server Actions, when deployed to serverless platforms, may spin up dozens of isolated function instances under load, each wanting its own TCP connection. Postgres has a hard connection limit (commonly 100–500 depending on plan); a traffic spike can exhaust it in seconds, causing cascading failures for *every* user, not just the ones causing the spike.

Neon's HTTP driver instead sends each query as a single stateless HTTP request, similar to calling a REST API. There's no persistent socket to exhaust — the tradeoff is marginally higher per-query latency (a few milliseconds), which is negligible for typical CRUD operations but matters if you were, say, streaming thousands of rows in a tight loop (in which case Neon also offers a pooled TCP mode via `@neondatabase/serverless`'s `Pool` class, worth knowing exists but out of scope for our use case).

### Reference 1.B — GDPR vs. CCPA, the engineering-relevant differences

| Aspect | GDPR (EU) | CCPA/CPRA (California) |
|---|---|---|
| Legal basis required to process data | Yes — must have one of 6 bases (consent, contract, legitimate interest, etc.) before *any* processing | No blanket requirement — focuses on disclosure + opt-out rights |
| Default consent model | Opt-in (explicit action required to allow processing) | Largely opt-out (processing allowed by default, user can object) |
| "Special category" data | Extra protections for health, biometric, religious, etc. data (Art. 9) | "Sensitive Personal Information" category exists (CPRA) with a right to limit its use |
| Right to erasure | Explicit, strong right (Art. 17) | Right to delete exists but has more business-purpose exceptions |
| Applies to | Any org processing EU residents' data, regardless of company location | Businesses meeting revenue/data-volume thresholds processing CA residents' data |

**Engineering takeaway:** Building to GDPR's stricter opt-in, special-category-aware model *automatically* satisfies the looser CCPA/CPRA opt-out model as a side effect — but the reverse is not true. This is why MindfulLog's consent ledger (Part 4) is designed as an explicit, granular opt-in system rather than a single "I agree" checkbox: it's the strictest common denominator, and every other regime's requirements fall out of it "for free." When in doubt, engineer to the stricter standard and let the looser ones be automatically satisfied — never the other way around.

### Reference 1.C — Anatomy of a DPIA: What Regulators Actually Look For

Our `dpia-mindfullog-v1.md` file isn't an arbitrary template — each section maps to a specific question that a Data Protection Authority (DPA) or an internal legal reviewer will ask when auditing high-risk processing:

| DPIA Section | Regulator's Underlying Question |
|---|---|
| Description of Processing | "What are you actually building, in plain terms?" |
| Data Inventory | "What exact data, and why is *each* field necessary — not just useful?" |
| Data Flow Map | "Where can this data end up, including third parties?" |
| Risk Assessment | "What's the worst realistic outcome, and what specifically stops it?" |
| Vendor Register | "Who else touches this data, and are they contractually bound (a Data Processing Agreement, or DPA)?" |
| Legal Basis | "Under what specific legal justification are you allowed to do this at all?" |
| Data Subject Rights | "Can a user actually exercise every right the law grants them, today, in your running system?" |

Note the phrase "not just useful" in the Data Inventory row — this is the single most common way DPIAs fail review. "It would be useful for personalization" is **not** a necessity justification; "the core feature cannot function without it" is. This distinction is the entire engineering discipline of **data minimization**, which is the subject of Part 2.

### Reference 1.D — Why We Scaffold Before the Schema Exists

You may have noticed Section 1.4 built an entire running app — auth, database connection, background job runner — before a single real database table exists. This ordering is deliberate and mirrors Principle 1 (Proactive not Reactive) at the infrastructure level: we want the *rails* (auth checks, encrypted connection strings, event bus) to already be safe and correctly wired before any sensitive data has anywhere to land. If we built the mood-tracking schema first and wired up auth/security afterward, there would exist a window — however brief in development, but real in a rushed production timeline — where sensitive data could be written to an unprotected table. Building the safety rails first makes that window structurally impossible rather than merely "unlikely if everyone remembers."

---

## Part 1 — Summary & What Carries Forward

By completing Part 1, your repository now contains:

- ✅ `docs/dpia/dpia-mindfullog-v1.md` — a living DPIA that every future schema/vendor change must update
- ✅ `docs/engineering/privacy-defaults.md` — a binding "privacy as default" engineering rule
- ✅ A working Next.js 16 app with Clerk authentication wired end-to-end
- ✅ A Neon Postgres connection verified via Drizzle
- ✅ An Inngest event bus with zero functions registered, ready to receive jobs from Part 2 onward
- ✅ A route-protection middleware enforcing default-deny on sensitive paths (`/dashboard`, `/api/mood`, `/api/journal`)

Every one of these artifacts will be directly extended, never replaced, in the parts that follow. Specifically: **Part 2 will populate `src/db/schema.ts` for the first time** — and every column added there will be checked against the Data Inventory table you just wrote in Section 1.3. Nothing you built here is throwaway scaffolding; it is the permanent skeleton the rest of the series builds onto.

**Quick self-check before moving on** — you should be able to answer "yes" to all of these:
1. Can I sign up and sign in via the Clerk modal on `localhost:3000`?
2. Does `npx drizzle-kit introspect` connect to my Neon database without error?
3. Does the Inngest Dev Server at `localhost:8288` detect my app with 0 functions registered (not an error, not "unreachable")?
4. Do I understand *why* `note_ciphertext` will be typed as `bytea` and not `text` before I even get to Part 2's schema code?
5. Can I explain, in one sentence, the difference between security and privacy to someone else?

If any of those are "no," it's worth pausing here rather than carrying a gap forward — every subsequent part assumes this foundation is solid.

```
[COMPLETED: Part 1 — Foundations, Moving Beyond Legal Compliance to System Design]
```
