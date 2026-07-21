# Part 1: Foundations  
## Scaffolding GreyMatter MindfulLog and Creating the Privacy Engineering Baseline

Welcome to **Part 1** of **Privacy by Design: Engineering the Default**.

In Part 0, we defined the purpose of **GreyMatter MindfulLog**: a privacy-first mental-health journaling application where privacy is not a feature added later, but the default behavior of the system.

In this part, we start building.

But we are not going to begin with a database table or a journal form.

We begin with the foundation that will shape every technical decision afterward:

- the Next.js application scaffold,
- project structure,
- core dependencies,
- environment configuration,
- privacy engineering conventions,
- a living DPIA,
- a STRIDE threat model,
- and a basic vendor/register document.

The reason is simple: for a privacy-first application, architecture comes before features.

The series treats privacy as a system property, not a banner or legal checkbox. The guiding question is: what architecture makes violating user privacy structurally difficult or impossible? [8]

---

# 1.0 What We Are Building in This Part

By the end of Part 1, GreyMatter MindfulLog will have:

1. A generated Next.js application scaffold.
2. TypeScript, Tailwind, ESLint, and the App Router configured.
3. A clean project structure for app code, libraries, scripts, and documentation.
4. Core dependencies for authentication, database access, validation, and background jobs.
5. Environment variable templates.
6. A `docs/` folder containing the first privacy governance documents.
7. A living DPIA.
8. A STRIDE threat model.
9. Privacy engineering conventions that future code must follow.
10. A basic verification checklist.

This is the empty lot, foundation, electrical plan, fire code, and inspection process before we start building rooms.

---

# 1.1 Generate the Next.js Application

In your project directory, run:

```bash
npx create-next-app@latest .
```

When prompted:

```text
Would you like to use the recommended Next.js defaults? › Yes
```

For a non-interactive setup, you can also run:

```bash
npx create-next-app@latest . --typescript --tailwind --eslint --app --yes
```

This creates the base Next.js application using TypeScript, Tailwind, ESLint, and the App Router [7].

---

# 1.2 What the Scaffold Generated

After running `create-next-app`, your project will contain a starting structure similar to this:

```txt
greymatter-mindfullog/
├── app/
│   ├── favicon.ico
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── public/
├── .gitignore
├── eslint.config.mjs
├── next-env.d.ts
├── next.config.ts
├── package.json
├── package-lock.json
├── postcss.config.mjs
├── README.md
└── tsconfig.json
```

Depending on your installed version of `create-next-app`, the exact file names may differ slightly. For example, some projects may use `next.config.mjs` instead of `next.config.ts`, or may include a `src/` directory if that option was selected.

Let’s walk through the important pieces.

---

## `app/`

The `app/` directory is where the App Router lives.

This is where we will eventually place:

```txt
app/
├── page.tsx
├── layout.tsx
├── settings/
│   └── consent/
│       └── page.tsx
├── dashboard/
│   └── page.tsx
├── journal/
│   └── page.tsx
└── api/
    ├── dsar/
    ├── delete-account/
    └── consent/
```

For now, the scaffold gives us a basic homepage and root layout.

Later, this directory will contain the user-facing surfaces for:

- mood logging,
- journal writing,
- consent management,
- account deletion,
- and data export.

---

## `app/layout.tsx`

This is the root layout for the application.

It wraps every page.

Eventually, this is where we will integrate:

- global metadata,
- authentication providers,
- application shell layout,
- privacy-safe analytics boundaries,
- and global styling.

For now, it is just the outer frame of the app.

---

## `app/page.tsx`

This is the default homepage.

We will replace it with a GreyMatter MindfulLog landing page that explains:

- what the app does,
- what data it collects,
- what it does not collect by default,
- and why privacy is central to the experience.

The homepage should not be just marketing. For a privacy-first product, the homepage is also a transparency surface.

---

## `app/globals.css`

This is the global stylesheet.

Because we selected the recommended defaults with Tailwind, this file includes Tailwind’s base styling setup.

Later, we will add a simple privacy-first design language:

- calm colors,
- readable text,
- clear consent choices,
- no manipulative visual hierarchy,
- and accessible forms.

---

## `public/`

The `public/` directory stores static assets such as images, icons, and metadata files.

For GreyMatter MindfulLog, we should be careful not to place anything sensitive here.

Everything in `public/` is publicly accessible.

That means:

```txt
public/
```

is fine for:

- logo files,
- generic illustrations,
- public app icons.

It is not fine for:

- exports,
- logs,
- screenshots containing user data,
- generated reports,
- test data with real personal information.

---

## `package.json`

This file defines your project scripts and dependencies.

Initially, it includes scripts like:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  }
}
```

Later in the series, we will add privacy-specific scripts such as:

```json
{
  "scripts": {
    "privacy:scan": "ts-node scripts/pii-scanner.ts"
  }
}
```

The privacy scanner becomes part of the CI/CD guardrails and checks the schema for risky plaintext sensitive fields [2].

---

## `tsconfig.json`

This configures TypeScript.

TypeScript matters in this project because we will use types as part of our safety model.

For example, later we can make it harder to accidentally treat encrypted data as plaintext by using explicit types such as:

```ts
type EncryptedField = Buffer;
type Plaintext = string;
```

Types are not a complete privacy control, but they are useful friction.

They make unsafe behavior more visible during development.

---

## `eslint.config.mjs`

ESLint helps catch mistakes before they become production bugs.

Later, we can extend linting rules or add custom checks to discourage unsafe patterns such as:

```ts
console.log(user);
console.log(journalEntry);
console.log(req.body);
```

A privacy-first codebase should treat logging as a sensitive operation.

Logs often become accidental databases.

---

## `next.config.ts`

This contains Next.js configuration.

We do not need to heavily customize it yet.

Later, this is where we may configure stricter security headers or other framework-level behavior.

---

## `.gitignore`

This file prevents sensitive or unnecessary files from being committed.

Make sure it includes:

```gitignore
.env
.env.local
.env.*.local
node_modules
.next
```

Environment files are especially important.

A leaked `.env.local` can expose database credentials, API keys, authentication secrets, and encryption configuration.

---

# 1.3 Create the Project Structure

Now add the folders we will use throughout the project:

```bash
mkdir -p docs lib scripts inngest/functions app/settings/consent
```

Your project should now begin to look like this:

```txt
greymatter-mindfullog/
├── app/
│   ├── settings/
│   │   └── consent/
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── docs/
├── inngest/
│   └── functions/
├── lib/
├── scripts/
├── public/
├── package.json
└── tsconfig.json
```

Each folder has a specific purpose.

---

## `docs/`

This is where privacy governance lives.

We will create:

```txt
docs/
├── DPIA.md
├── PRIVACY_CONVENTIONS.md
├── THREAT_MODEL.md
├── VENDOR_REGISTER.md
└── INCIDENT_RESPONSE.md
```

Not all of these will be complete immediately.

But creating the folder now sends an important message:

> Privacy documentation belongs inside the engineering workflow.

It should live with the code, evolve with the code, and be reviewed with the code.

---

## `lib/`

This is where shared application logic will live.

Later, it will contain:

```txt
lib/
├── db.ts
├── schema.sql
├── encryption.ts
├── policy-engine.ts
├── consent.ts
├── export.ts
├── deletion-orchestrator.ts
├── privacy-utils.ts
└── logger.ts
```

The most important idea is separation.

We do not want encryption logic scattered across random components.

We do not want authorization rules duplicated in every route.

We do not want consent logic embedded only in the UI.

Privacy-critical behavior should be centralized.

---

## `scripts/`

This folder will contain developer and CI scripts.

Later:

```txt
scripts/
└── pii-scanner.ts
```

The PII scanner will inspect schema files and fail the build if sensitive columns are introduced without appropriate protections. The tutorial’s CI pipeline later runs `npm run privacy:scan` before building the app [2].

---

## `inngest/functions/`

This folder is for durable background jobs.

GreyMatter MindfulLog will eventually use background jobs for workflows like:

- consent propagation,
- DSAR export generation,
- account deletion orchestration,
- data cleanup,
- retention enforcement.

Consent changes need reliable fan-out to other systems, and events such as `consent.changed` can trigger background jobs [4].

DSAR export is also a good background-job use case because exporting user data should be complete, verifiable, and temporary [3].

---

# 1.4 Install Core Dependencies

Now install the dependencies we will use throughout the application:

```bash
npm install @clerk/nextjs @neondatabase/serverless zod inngest
```

These give us:

| Package | Purpose |
|---|---|
| `@clerk/nextjs` | Authentication and user session management |
| `@neondatabase/serverless` | Serverless PostgreSQL database access |
| `zod` | Runtime validation for inputs and environment variables |
| `inngest` | Durable background workflows and event-driven jobs |

We will add more packages later, including encryption and export-related utilities when needed.

For example, DSAR export later uses ZIP generation and may install `jszip` [3].

---

# 1.5 Add Environment Variable Files

Create:

```bash
touch .env.local .env.example
```

Add this to `.env.example`:

```env
# App
NEXT_PUBLIC_APP_NAME="GreyMatter MindfulLog"
NEXT_PUBLIC_APP_URL="http://localhost:3000"

# Clerk
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=""
CLERK_SECRET_KEY=""

# Neon / Postgres
DATABASE_URL=""

# Privacy utilities
HMAC_SALT=""

# Encryption / KMS placeholders
KMS_KEY_NAME=""
GOOGLE_APPLICATION_CREDENTIALS=""
```

Do not commit `.env.local`.

Your `.env.example` is documentation.

Your `.env.local` is secret configuration.

A safe rule:

```txt
.env.example = safe to commit
.env.local   = never commit
```

---

# 1.6 Validate Environment Variables

Create:

```bash
touch lib/env.ts
```

Add:

```ts
import { z } from "zod";

const envSchema = z.object({
  NEXT_PUBLIC_APP_NAME: z.string().default("GreyMatter MindfulLog"),
  NEXT_PUBLIC_APP_URL: z.string().url().default("http://localhost:3000"),

  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY: z.string().optional(),
  CLERK_SECRET_KEY: z.string().optional(),

  DATABASE_URL: z.string().optional(),

  HMAC_SALT: z.string().min(32).optional(),

  KMS_KEY_NAME: z.string().optional(),
  GOOGLE_APPLICATION_CREDENTIALS: z.string().optional(),
});

export const env = envSchema.parse({
  NEXT_PUBLIC_APP_NAME: process.env.NEXT_PUBLIC_APP_NAME,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,

  NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY:
    process.env.NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY,
  CLERK_SECRET_KEY: process.env.CLERK_SECRET_KEY,

  DATABASE_URL: process.env.DATABASE_URL,

  HMAC_SALT: process.env.HMAC_SALT,

  KMS_KEY_NAME: process.env.KMS_KEY_NAME,
  GOOGLE_APPLICATION_CREDENTIALS: process.env.GOOGLE_APPLICATION_CREDENTIALS,
});
```

This gives us a central place to validate configuration.

Later, we can make required values stricter as soon as the relevant subsystem is implemented.

For example, when we implement HMAC utilities, `HMAC_SALT` should become required. HMAC is useful for turning identifiable values like IP addresses into one-way fingerprints for rate limiting or fraud detection [6].

---

# 1.7 Replace the Default Homepage

Open:

```txt
app/page.tsx
```

Replace it with:

```tsx
export default function HomePage() {
  return (
    <main className="min-h-screen bg-slate-950 text-slate-50">
      <section className="mx-auto flex min-h-screen max-w-4xl flex-col items-center justify-center px-6 py-24 text-center">
        <p className="mb-4 rounded-full border border-slate-700 px-4 py-1 text-sm text-slate-300">
          Privacy by Design · Mental Health Journaling
        </p>

        <h1 className="text-4xl font-bold tracking-tight sm:text-6xl">
          GreyMatter MindfulLog
        </h1>

        <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-300">
          A privacy-first journaling application for mood tracking, reflection,
          consent management, data export, and account deletion.
        </p>

        <div className="mt-10 grid gap-4 text-left sm:grid-cols-3">
          <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
            <h2 className="font-semibold">Minimized by default</h2>
            <p className="mt-2 text-sm text-slate-400">
              We collect only what the feature requires.
            </p>
          </div>

          <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
            <h2 className="font-semibold">Encrypted by design</h2>
            <p className="mt-2 text-sm text-slate-400">
              Sensitive journal content is designed for field-level encryption.
            </p>
          </div>

          <div className="rounded-2xl border border-slate-800 bg-slate-900 p-5">
            <h2 className="font-semibold">User rights built in</h2>
            <p className="mt-2 text-sm text-slate-400">
              Export and deletion flows are core product capabilities.
            </p>
          </div>
        </div>
      </section>
    </main>
  );
}
```

This page is intentionally simple.

The purpose is not to finish the product UI yet.

The purpose is to replace the generic scaffold page with a product identity and a privacy-first message.

---

# 1.8 Create the Privacy Conventions Document

Create:

```bash
touch docs/PRIVACY_CONVENTIONS.md
```

Add:

```md
# GreyMatter MindfulLog Privacy Engineering Conventions

These rules apply to all code in this repository.

## 1. Privacy is the default

Features must be designed so that the safest reasonable behavior happens by default.

Users should not need to discover hidden settings to protect themselves.

## 2. Minimize first

Do not collect data unless there is a specific product, safety, legal, or operational reason.

Every new database column must have:

- a purpose,
- a sensitivity classification,
- a retention expectation,
- and a mitigation.

## 3. No plaintext sensitive journal content

Private notes, journal entries, and health-related free text must not be stored as ordinary plaintext database fields.

Sensitive free text must use field-level encryption.

## 4. No casual logging of user data

Do not log:

- journal entries,
- mood notes,
- raw request bodies,
- access tokens,
- session data,
- email addresses unless explicitly redacted,
- IP addresses unless transformed or justified.

Unsafe:

```ts
console.log(user);
console.log(entry);
console.log(req.body);
```

Safer:

```ts
logger.info("journal_entry_created", {
  userIdHash,
  entryId,
});
```

## 5. Authorization must be centralized

Every access decision must go through the policy engine.

Do not duplicate authorization logic across pages, components, or API routes.

## 6. Consent is append-only

Consent decisions must be recorded as events.

Do not overwrite historical consent decisions.

The current consent state should be derived from the latest event for each purpose.

## 7. Schema changes require DPIA updates

If a pull request changes the database schema, it must also update `docs/DPIA.md`.

## 8. Deletion must be explicit and verifiable

Account deletion must identify each affected subsystem and record whether deletion or anonymization succeeded.

## 9. Exports must be temporary and auditable

Data exports must be generated intentionally, expire automatically, and be logged as security-relevant events.

## 10. Fail closed

When the system is unsure whether access should be allowed, it must deny access.
```

These conventions become the engineering constitution for the app.

Later parts implement these principles in code.

For example, the policy engine will use a fail-closed model where unknown access is denied [5].

---

# 1.9 Create the Living DPIA

A DPIA is a Data Protection Impact Assessment.

For this project, it is the living map of:

- what data exists,
- why it exists,
- how sensitive it is,
- where it is stored,
- who can access it,
- how it is protected,
- and when it should be deleted.

Create:

```bash
touch docs/DPIA.md
```

Add:

```md
# Living DPIA — GreyMatter MindfulLog

Last updated: YYYY-MM-DD

Owner: Privacy Engineering

Status: Draft

---

## 1. Purpose of the Application

GreyMatter MindfulLog is a privacy-first mental-health journaling application.

Users can:

- record mood scores,
- add optional private notes,
- write journal entries,
- set reminders,
- manage consent,
- export their data,
- and delete their account.

Because the application may process mental-health information, it must be treated as a high-sensitivity system.

---

## 2. Privacy by Design Commitments

GreyMatter MindfulLog follows these engineering commitments:

1. Proactive privacy engineering before feature implementation.
2. Privacy-safe defaults.
3. Privacy embedded into schema, code, jobs, and operations.
4. Full functionality without unnecessary surveillance.
5. End-to-end security.
6. Transparency and user access to data.
7. Respectful interfaces without dark patterns.

---

## 3. Data Inventory

| Asset | Purpose | Sensitivity | Storage | Mitigation | Retention |
|---|---|---:|---|---|---|
| user_id | Link records to authenticated user | Medium | Database UUID/text | Pseudonymous internal identifier | Until account deletion |
| mood_score | Mood trend tracking | Medium | Plain integer | Minimized numeric value | User-controlled |
| mood_notes | Optional reflection on mood | Very High | Encrypted binary field | Field-level envelope encryption | User-controlled |
| journal_title | User organization/search | High | Encrypted or minimized text | Prefer encryption if sensitive | User-controlled |
| journal_content | Private journaling | Very High | Encrypted binary field | Field-level envelope encryption | User-controlled |
| reminder_label | Medication/wellness reminder | High | Encrypted or minimized text | Avoid unnecessary detail | User-controlled |
| consent_purpose | Track consent category | Medium | Plain enum/text | Append-only ledger | Audit retention |
| consent_decision | Track allow/deny decision | Medium | Plain boolean/event | Append-only ledger | Audit retention |
| consent_timestamp | Consent auditability | Medium | Timestamp | Immutable history | Audit retention |
| email | Authentication/contact | High | Clerk/vendor system | Avoid duplicating locally | Vendor controls |
| IP address | Abuse prevention/rate limiting | High | HMAC fingerprint only | One-way HMAC | Short retention |

---

## 4. Data Minimization Notes

GreyMatter MindfulLog should avoid storing:

- unnecessary demographic data,
- raw IP addresses,
- device fingerprinting data,
- precise location,
- inferred diagnosis,
- third-party social profile data,
- unnecessary analytics identifiers.

If a feature appears to require new personal data, update this DPIA before implementation.

---

## 5. High-Risk Processing

The highest-risk processing activities are:

1. Storing mental-health journal content.
2. Storing mood notes.
3. Providing support access.
4. Generating data exports.
5. Deleting accounts across multiple systems.
6. Processing consent changes.

---

## 6. Mitigations

| Risk | Mitigation |
|---|---|
| Database breach exposes journal content | Field-level encryption |
| Support staff over-access | Masked support views and policy engine |
| Consent history is altered | Append-only consent ledger |
| User cannot exercise rights | DSAR export and deletion workflows |
| Developer adds plaintext PII | CI privacy scanner |
| Logs leak sensitive content | PII-safe logger and logging conventions |
| Unauthorized access | Centralized fail-closed policy engine |
| Long-term unnecessary retention | Retention rules and cleanup jobs |

---

## 7. Review Triggers

This DPIA must be reviewed when:

- a new database table is added,
- a new sensitive column is added,
- a new vendor is introduced,
- a new analytics or tracking tool is introduced,
- consent purposes change,
- export/deletion behavior changes,
- incident response identifies a new risk,
- or production monitoring reveals unexpected data flows.
```

The DPIA is not paperwork for the end of the project.

It is a design tool.

The foundation material defines DPIA as the living map of every piece of data, why it is needed, and how it is protected [7].

---

# 1.10 Create the STRIDE Threat Model

STRIDE is a threat modeling framework.

It helps us inspect the application across six categories:

| STRIDE Category | Question |
|---|---|
| Spoofing | Can someone pretend to be another user? |
| Tampering | Can data be changed without authorization? |
| Repudiation | Can someone deny an action with no audit trail? |
| Information Disclosure | Can sensitive data leak? |
| Denial of Service | Can the app be made unavailable? |
| Elevation of Privilege | Can someone gain more access than intended? |

Create:

```bash
touch docs/THREAT_MODEL.md
```

Add:

```md
# STRIDE Threat Model — GreyMatter MindfulLog

Last updated: YYYY-MM-DD

Owner: Privacy Engineering

---

## 1. System Overview

GreyMatter MindfulLog is a Next.js application for privacy-first mental-health journaling.

Primary components:

- Next.js web application
- Clerk authentication
- Neon PostgreSQL database
- Field-level encryption layer
- Consent ledger
- Policy engine
- Inngest background jobs
- DSAR export pipeline
- Deletion orchestration
- Privacy CI/CD checks

---

## 2. Trust Boundaries

| Boundary | Description | Risk |
|---|---|---|
| Browser → Next.js server | User input enters the app | Injection, spoofing, invalid data |
| Next.js → Clerk | Authentication/session validation | Misconfigured auth |
| Next.js → Database | Application reads/writes user data | Unauthorized access, data leakage |
| App → KMS/encryption system | Encryption operations | Key misuse, failed encryption |
| App → Inngest | Background workflow events | Event spoofing, replay |
| App → Export storage | DSAR export generated | Unauthorized download |
| App → Logs/monitoring | Operational visibility | Sensitive data leakage |

---

## 3. STRIDE Analysis

### Spoofing

Threats:

- Attacker attempts to impersonate another user.
- Session token is stolen.
- Background job event is forged.

Mitigations:

- Clerk session validation.
- Server-side user checks.
- Signed or trusted event sources.
- Never trust client-provided `userId`.

---

### Tampering

Threats:

- User modifies another user's journal entry.
- Consent records are overwritten.
- Export job parameters are changed.

Mitigations:

- Centralized policy engine.
- Owner-based access checks.
- Append-only consent ledger.
- Database constraints.
- Authenticated server-side actions.

---

### Repudiation

Threats:

- User or staff member denies changing consent.
- Support access occurs without a trace.
- Export or deletion is triggered without evidence.

Mitigations:

- Immutable audit events.
- Append-only consent records.
- Export request logs.
- Deletion workflow status records.

---

### Information Disclosure

Threats:

- Database breach reveals journal entries.
- Logs contain private notes.
- Support staff sees full sensitive content.
- DSAR export link is shared or leaked.

Mitigations:

- Field-level encryption.
- PII-safe logging.
- Masked support access.
- Temporary export links.
- Strong access control.
- Least-privilege operational access.

---

### Denial of Service

Threats:

- Export generation is abused.
- Account deletion jobs are spammed.
- Login or API endpoints are flooded.

Mitigations:

- Rate limiting.
- Background jobs.
- Queue controls.
- Abuse detection using HMAC identifiers.
- Neon scaling.

---

### Elevation of Privilege

Threats:

- Support user accesses unmasked records.
- Admin route is accidentally exposed.
- API route forgets authorization checks.

Mitigations:

- Fail-closed policy engine.
- RBAC plus ABAC.
- Route-level authorization tests.
- No direct database access from unsafe contexts.
```

The foundation uses STRIDE to reason through spoofing, tampering, information disclosure, denial of service, elevation of privilege, and repudiation, with mitigations such as Clerk, AES-GCM, field-level encryption, fail-closed policy enforcement, and immutable audit records [7].

---

# 1.11 Create the Vendor Register

GreyMatter MindfulLog depends on vendors.

A privacy-first project should know which vendors process data, what data they touch, and what agreement or control applies.

Create:

```bash
touch docs/VENDOR_REGISTER.md
```

Add:

```md
# Vendor Register — GreyMatter MindfulLog

Last updated: YYYY-MM-DD

Owner: Privacy Engineering

---

## Vendor Summary

| Vendor | Purpose | Data Processed | Risk | Required Controls |
|---|---|---|---|---|
| Clerk | Authentication and user management | Email, auth identifiers, sessions | High | DPA, access controls, deletion process |
| Neon | Serverless PostgreSQL database | Application data, encrypted sensitive fields | High | Encryption, SCCs/DPA, access controls |
| Google Cloud KMS | Key encryption and wrapping | Key material operations, not plaintext app data | High | DPA, key rotation, IAM controls |
| Vercel | Hosting/deployment | Application runtime, logs, environment variables | Medium/High | DPA, environment protection, log controls |
| Inngest | Background jobs | Event metadata, workflow payloads | Medium | Minimized payloads, no plaintext sensitive content |

---

## Vendor Review Questions

Before adding a vendor, answer:

1. What data will this vendor process?
2. Is the data personal, sensitive, or health-related?
3. Is the vendor necessary?
4. Can the data be minimized before sending?
5. Is there a DPA or equivalent agreement?
6. What happens when a user deletes their account?
7. Can data be exported?
8. Where is the data stored geographically?
9. Who at our organization can access the vendor dashboard?
10. What logs does the vendor retain?

---

## Current Decision

No new vendor may be added to GreyMatter MindfulLog without updating this register and the DPIA.
```

The foundation model includes a vendor register covering providers such as Clerk, Neon, and Google Cloud, along with agreements like DPAs, SCCs, and data processing addenda [7].

---

# 1.12 Create a Basic README

Replace the default `README.md` with:

```md
# GreyMatter MindfulLog

GreyMatter MindfulLog is a privacy-first mental-health journaling application built as part of the tutorial series:

**Privacy by Design: Engineering the Default**

The project demonstrates how to build privacy into architecture, schema design, encryption, access control, consent, data export, deletion, CI/CD, and operations.

---

## Core Principles

1. Privacy as the default.
2. Data minimization first.
3. Field-level encryption for sensitive content.
4. Centralized access control.
5. Append-only consent.
6. User rights built into the product.
7. Privacy checks in CI/CD.
8. Incident readiness.

---

## Development

```bash
npm install
npm run dev
```

Open:

```txt
http://localhost:3000
```

---

## Verification

```bash
npm run build
```

Additional privacy verification commands will be added as the project evolves.
```

---

# 1.13 Add a Placeholder Schema File

We are not designing the full database yet.

That comes in Part 2.

But we can create the file now:

```bash
touch lib/schema.sql
```

Add:

```sql
-- GreyMatter MindfulLog schema
-- Full minimized schema will be implemented in Part 2.
--
-- Privacy rule:
-- Any new column containing sensitive user content must be documented in docs/DPIA.md.
```

This creates a useful convention:

> Schema and DPIA evolve together.

In later parts, sensitive note fields will be designed as encrypted binary fields, not casual plaintext.

---

# 1.14 Add a Placeholder Policy Engine

Create:

```bash
touch lib/policy-engine.ts
```

Add:

```ts
export type UserRole = "owner" | "support" | "admin";

export type UserContext = {
  userId: string;
  role: UserRole;
  isSupportMasked?: boolean;
};

export type Resource = {
  ownerId: string;
  type: "mood_log" | "journal" | "consent" | "export" | "account";
};

export class PolicyEngine {
  static canView(context: UserContext, resource: Resource): boolean {
    if (context.userId === resource.ownerId) {
      return true;
    }

    if (context.role === "support") {
      return context.isSupportMasked === true;
    }

    return false;
  }

  static canEdit(context: UserContext, resource: Resource): boolean {
    return context.userId === resource.ownerId;
  }

  static canDelete(context: UserContext, resource: Resource): boolean {
    return context.userId === resource.ownerId;
  }
}
```

This is only the starting point.

Later, we will expand this into a stronger access model.

But even now, the design direction is clear:

- access decisions are centralized,
- owners can access their own records,
- support is restricted,
- unknown access fails closed.

The later policy engine follows this same model: all access decisions go through one trusted place, and unknown access is denied [5].

---

# 1.15 Add a Placeholder Privacy Logger

Create:

```bash
touch lib/logger.ts
```

Add:

```ts
type LogMetadata = Record<string, string | number | boolean | null | undefined>;

const BLOCKED_KEYS = [
  "password",
  "token",
  "secret",
  "journal",
  "content",
  "notes",
  "email",
  "phone",
  "ip",
];

function redactMetadata(metadata: LogMetadata = {}) {
  return Object.fromEntries(
    Object.entries(metadata).map(([key, value]) => {
      const shouldRedact = BLOCKED_KEYS.some((blocked) =>
        key.toLowerCase().includes(blocked)
      );

      return [key, shouldRedact ? "[REDACTED]" : value];
    })
  );
}

export const logger = {
  info(message: string, metadata?: LogMetadata) {
    console.info(message, redactMetadata(metadata));
  },

  warn(message: string, metadata?: LogMetadata) {
    console.warn(message, redactMetadata(metadata));
  },

  error(message: string, metadata?: LogMetadata) {
    console.error(message, redactMetadata(metadata));
  },
};
```

This is not a complete production logger yet.

But it establishes the rule:

> logs are hostile until proven safe.

We will improve this later.

---

# 1.16 Add a First Privacy Checklist

Create:

```bash
touch docs/PRIVACY_CHECKLIST.md
```

Add:

```md
# Privacy Checklist — GreyMatter MindfulLog

This checklist should be reviewed before major releases.

---

## Data Minimization

- [ ] Every database column has a documented purpose.
- [ ] No unnecessary demographic data is collected.
- [ ] Raw IP addresses are not stored unless justified.
- [ ] Sensitive free text is encrypted.

## Consent

- [ ] Consent choices are clear and symmetric.
- [ ] No pre-checked boxes are used.
- [ ] Consent records are append-only.
- [ ] Users can withdraw consent as easily as they gave it.

## Access Control

- [ ] Every protected action uses the policy engine.
- [ ] Support access is masked by default.
- [ ] Unknown access fails closed.
- [ ] Admin capabilities are documented and reviewed.

## Export and Deletion

- [ ] Users can request a data export.
- [ ] Exports are temporary.
- [ ] Users can delete their account.
- [ ] Deletion/anonymization is verifiable.

## CI/CD

- [ ] Build passes.
- [ ] Privacy scan passes.
- [ ] Secret scan passes.
- [ ] Schema changes update the DPIA.

## Operations

- [ ] Incident response playbook exists.
- [ ] Key rotation process is documented.
- [ ] Backup and retention behavior is documented.
- [ ] Post-incident DPIA updates are required.
```

Later, this checklist will include operational metrics such as DSAR response time under 30 days and deletion success rate of 100% [2].

---

# 1.17 Run the First Verification

Run:

```bash
npm run build
```

If everything is correct, the project should compile.

Then run:

```bash
npm run dev
```

Open:

```txt
http://localhost:3000
```

You should see the new GreyMatter MindfulLog homepage.

---

# 1.18 Part 1 Completion Checklist

Before moving to Part 2, confirm:

```txt
[ ] Next.js project generated
[ ] Recommended defaults accepted
[ ] App Router present
[ ] TypeScript configured
[ ] Tailwind configured
[ ] ESLint configured
[ ] docs/ folder created
[ ] lib/ folder created
[ ] scripts/ folder created
[ ] inngest/functions/ folder created
[ ] README updated
[ ] DPIA created
[ ] STRIDE threat model created
[ ] vendor register created
[ ] privacy conventions created
[ ] placeholder schema created
[ ] placeholder policy engine created
[ ] placeholder logger created
[ ] npm run build succeeds
```

---

# What We Have Built

In Part 1, we did not build many user-facing features.

That is intentional.

We built the foundation that future features must obey.

GreyMatter MindfulLog now has:

- a modern Next.js scaffold,
- a clear project structure,
- a privacy-first homepage,
- early environment validation,
- privacy engineering conventions,
- a living DPIA,
- a STRIDE threat model,
- a vendor register,
- a placeholder schema,
- a placeholder policy engine,
- and a privacy-safe logging direction.

This is how privacy engineering starts: not with a cookie banner, but with architecture.

In Part 2, we will design the minimized database schema. Every column will need a reason to exist, because the less data we store, the less can be stolen, leaked, or misused.
