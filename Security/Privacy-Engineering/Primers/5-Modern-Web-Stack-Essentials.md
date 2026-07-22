# Primer 05 — Modern Web Stack Essentials

## For GreyMatter MindfulLog

Welcome to **Primer 05: Modern Web Stack Essentials**.

This primer explains the technology stack behind **GreyMatter MindfulLog**, a privacy-first mental-health journaling application.

By this point, the primers have introduced:

```txt
Primer-01 — Privacy Engineering 101
Primer-02 — Cryptography Basics
Primer-03 — Singapore PDPA Basics
Primer-04 — Threat Modeling with STRIDE
```

Now we connect those ideas to the tools we will use to build the application.

GreyMatter MindfulLog is not just a Next.js app with a database. It is a privacy-first system where the framework, authentication provider, database, encryption layer, background jobs, CI/CD pipeline, logging model, and vendor choices all affect user privacy.

The goal of this primer is to explain the stack before we rely on it heavily in the main build.

---

# 1. The GreyMatter MindfulLog Stack

GreyMatter MindfulLog uses a modern full-stack TypeScript architecture.

The core tools are:

| Layer | Tool | Purpose |
|---|---|---|
| Web framework | Next.js | Full-stack React app, routing, server logic |
| UI | React + Tailwind CSS | Interface and styling |
| Authentication | Clerk | User identity, sessions, protected routes |
| Database | Neon Postgres | Serverless PostgreSQL |
| Validation | Zod | Runtime validation at boundaries |
| Encryption | Node crypto + Google Cloud KMS | Field-level envelope encryption |
| Background jobs | Inngest | Durable workflows for exports, deletion, consent sync |
| Rate limiting | Redis / Upstash-style store | Abuse prevention |
| Hosting | Vercel or equivalent | Deployment/runtime |
| CI/CD | GitHub Actions | Automated build and privacy checks |
| Secret scanning | Gitleaks | Prevent leaked secrets |
| Logging | PII-redacting logger | Avoid sensitive operational leakage |

The high-level architecture places the browser behind HTTPS, then routes requests through the Next.js server, Clerk middleware, validation, rate limiting, a centralized policy engine, a PII-redacting logger, and a field-level encryption service before reaching Neon, Google Cloud KMS, Inngest, and Clerk lifecycle integrations [8].

---

# 2. Why the Stack Matters for Privacy

Technology choices are privacy choices.

For example:

- If the database stores plaintext journal entries, the database becomes a high-risk exposure point.
- If logs capture request bodies, logs become a shadow database of sensitive user content.
- If authentication is weak, private records are exposed.
- If background jobs contain plaintext payloads, queue systems become sensitive data stores.
- If CI/CD does not scan for risky schema changes, plaintext PII may enter production accidentally.
- If vendors receive unnecessary data, the privacy boundary expands.

GreyMatter MindfulLog’s architecture is designed around several strict principles:

- plaintext health data should not touch disk or logs,
- every access decision should go through a centralized policy engine,
- consent should be append-only,
- deletion should cascade safely across systems,
- and CI/CD should enforce privacy rules on every pull request [8].

This primer explains the stack through that lens.

---

# 3. Next.js

## 3.1 What Next.js Provides

Next.js is the application framework.

It gives us:

- routing,
- layouts,
- server-rendered pages,
- React Server Components,
- route handlers,
- server-side logic,
- API endpoints,
- metadata,
- static assets,
- deployment-friendly structure.

GreyMatter MindfulLog uses Next.js because it lets us build the product UI and backend logic in one TypeScript codebase.

That is useful for a privacy-first app because we can keep privacy-critical logic close to the application boundary.

---

## 3.2 App Router

Modern Next.js applications commonly use the **App Router**.

A simplified structure looks like this:

```txt
app/
├── page.tsx
├── layout.tsx
├── dashboard/
│   └── page.tsx
├── journal/
│   └── page.tsx
├── mood/
│   └── page.tsx
├── settings/
│   └── consent/
│       └── page.tsx
└── api/
    ├── access-export/
    ├── delete-account/
    └── consent/
```

For GreyMatter MindfulLog, the `app/` directory will eventually contain:

- homepage,
- dashboard,
- mood tracking,
- journal entry screens,
- consent settings,
- personal data access export,
- account deletion,
- support-access settings.

---

## 3.3 Server Components and Privacy

React Server Components are useful because they execute on the server.

This means sensitive server-side operations can stay off the client, such as:

- reading authenticated session state,
- loading user-owned data,
- checking access policies,
- decrypting encrypted content when appropriate,
- avoiding unnecessary client-side exposure.

However, Server Components are not magic.

Privacy rules still apply:

```txt
Do not send sensitive data to the browser unless the user is authorized to see it.
Do not fetch another user’s data.
Do not expose secrets through props.
Do not include decrypted content in logs or error payloads.
```

---

## 3.4 Route Handlers

Route handlers are useful for server-side endpoints.

Example paths:

```txt
app/api/consent/route.ts
app/api/access-export/route.ts
app/api/delete-account/route.ts
```

Privacy-sensitive route handlers should always:

1. authenticate the user,
2. validate input,
3. derive user ID from the server session,
4. check authorization through the policy engine,
5. avoid logging sensitive payloads,
6. perform minimized database operations,
7. trigger durable jobs where needed.

Bad pattern:

```ts
const { userId } = await req.json();
```

Better pattern:

```ts
const userId = getUserIdFromServerSession();
```

Never trust client-provided identity.

---

# 4. TypeScript

TypeScript is not a security boundary, but it helps create safer development patterns.

In GreyMatter MindfulLog, TypeScript can help us distinguish between concepts like:

```ts
type UserId = string;
type InternalPseudonym = string;
type Plaintext = string;
type EncryptedBytes = Buffer;

type ConsentPurpose =
  | "analytics"
  | "marketing"
  | "research"
  | "support_access";
```

This matters because privacy mistakes often happen when developers treat different kinds of data as interchangeable.

For example, plaintext journal content and encrypted journal content should not feel like the same thing in code.

Bad:

```ts
const content: string = row.content;
```

Better:

```ts
const contentEncrypted: EncryptedBytes = row.content_encrypted;
```

Types make privacy-sensitive boundaries more visible.

---

# 5. Tailwind CSS

Tailwind CSS is the styling layer.

It does not directly protect data, but it matters for privacy UX.

Consent, access export, deletion, and support-access screens should be:

- clear,
- accessible,
- calm,
- readable,
- non-manipulative,
- equal in choice presentation.

For example, a privacy-respecting consent UI should not make “Allow” bright and large while making “Don’t Allow” small and grey.

GreyMatter MindfulLog’s consent design emphasizes equal prominence for “Allow” and “Don’t Allow,” no pre-checked boxes, and clear language [4].

Tailwind helps us implement that consistency.

---

# 6. Clerk Authentication

## 6.1 What Clerk Provides

Clerk handles authentication and user identity.

It can provide:

- sign-up,
- sign-in,
- session management,
- user identity,
- middleware integration,
- protected route enforcement,
- user lifecycle hooks.

In the GreyMatter MindfulLog architecture, Clerk acts as the front gate for protected routes.

The application uses Clerk middleware to protect routes such as:

```txt
/dashboard
/journal
/settings
/export
/delete-account
```

so unauthenticated users are redirected to sign in [7].

---

## 6.2 Why We Use an Auth Provider

Authentication is easy to get wrong.

Using an identity provider helps avoid implementing password storage, session management, and auth flows from scratch.

However, using a vendor does not remove privacy responsibility.

For GreyMatter MindfulLog, Clerk should be documented in the vendor register because it processes identity-related personal data such as email, user IDs, and sessions.

---

## 6.3 Authentication Is Not Authorization

Authentication answers:

```txt
Who are you?
```

Authorization answers:

```txt
What are you allowed to do?
```

A user being logged in does not mean they can access every resource.

Example:

```txt
Alice is authenticated.
Bob is authenticated.
Alice must not read Bob’s journal.
```

So Clerk handles identity, while the policy engine handles access decisions.

The architecture requires every access decision to go through a centralized policy engine [8].

---

# 7. Neon Postgres

## 7.1 What Neon Provides

Neon provides serverless PostgreSQL.

Postgres gives us:

- relational tables,
- constraints,
- indexes,
- transactions,
- SQL queries,
- strong consistency,
- mature tooling.

Neon also supports database branching, which is useful for testing destructive workflows such as deletion before running them against production-like data [7].

---

## 7.2 Database as a Privacy Boundary

The database is one of the most important privacy boundaries.

For GreyMatter MindfulLog, the schema must be minimized.

Every column should have a reason to exist.

Sensitive free text should not be stored as ordinary plaintext.

The minimized schema uses binary fields such as:

```sql
notes_encrypted BYTEA
content_encrypted BYTEA
```

so sensitive health-related notes and journal content are stored as encrypted binary data rather than readable database text [6].

---

## 7.3 Example: Bad vs Better Schema

Bad:

```sql
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

Problem:

```txt
content TEXT stores private journal content in plaintext.
```

Better:

```sql
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  title_encrypted BYTEA,
  content_encrypted BYTEA NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

This makes the database itself enforce the privacy expectation.

---

## 7.4 Indexes and Privacy

Indexes should not contain sensitive plaintext.

For example, indexing encrypted fields is usually not useful for plaintext search.

Good indexes:

```sql
CREATE INDEX idx_mood_user ON mood_logs(user_id);
CREATE INDEX idx_consent_user ON consent_records(user_id, purpose);
```

The schema uses indexes for performance while avoiding sensitive data in indexes [6].

---

# 8. Zod Validation

Zod is used for runtime validation.

TypeScript checks code at development time.

Zod checks real input at runtime.

This matters because users, browsers, and attackers can send unexpected data.

Example mood input schema:

```ts
import { z } from "zod";

export const createMoodLogSchema = z.object({
  moodScore: z.number().int().min(1).max(10),
  notes: z.string().max(5000).optional(),
});
```

Benefits:

- rejects invalid mood scores,
- limits text size,
- prevents malformed payloads,
- creates a clean boundary before encryption and storage.

Zod is part of the stack specifically for runtime validation and type inference at data boundaries [8].

---

# 9. Google Cloud KMS

## 9.1 What KMS Provides

Google Cloud KMS is used for key management.

In GreyMatter MindfulLog, it supports envelope encryption.

The field-level encryption model uses:

- a **Data Encryption Key**, or DEK, to encrypt actual data,
- a **Key Encryption Key**, or KEK, managed by Google Cloud KMS,
- AES-256-GCM for authenticated encryption.

The KEK never leaves Google’s hardware-backed protection model [5].

---

## 9.2 Why We Do Not Store Master Keys in the App

Bad:

```ts
const MASTER_KEY = "my-hardcoded-key";
```

Better:

```txt
Use KMS to protect the KEK.
Generate DEKs per encryption operation.
Store only wrapped DEKs with ciphertext.
```

GreyMatter MindfulLog encrypts data with a DEK, then wraps the DEK with the KEK managed in Google Cloud KMS [5].

---

## 9.3 Why KMS Matters for Privacy

KMS helps reduce the risk of:

- hardcoded keys,
- leaked source code exposing keys,
- database dumps exposing both data and keys,
- uncontrolled key rotation,
- unclear key access.

Key management is part of privacy engineering because encrypted data is only as safe as the keys that protect it.

---

# 10. Node Crypto

Node’s built-in `crypto` module provides cryptographic primitives.

We use it for:

- random bytes,
- AES-GCM encryption,
- HMAC,
- hashing where appropriate.

Example:

```ts
import crypto from "crypto";

const dek = crypto.randomBytes(32); // AES-256 key
const iv = crypto.randomBytes(12);  // AES-GCM nonce
```

In GreyMatter MindfulLog, a new DEK is created per encryption operation, and KEK rotation is handled through Google Cloud KMS versioning [1].

---

# 11. Inngest Background Jobs

## 11.1 Why Background Jobs Matter

Some workflows should not run entirely inside a single web request.

Examples:

- personal data access exports,
- account deletion,
- consent propagation,
- retention cleanup,
- vendor synchronization,
- long-running audit tasks.

GreyMatter MindfulLog uses Inngest for durable jobs that support export, deletion, and consent synchronization [8].

---

## 11.2 Access Export Workflow

A personal data access export may need to:

1. gather mood logs,
2. decrypt encrypted mood notes,
3. gather journal entries,
4. decrypt journal content,
5. include reminders,
6. include consent history,
7. generate a ZIP file,
8. include a manifest,
9. return a temporary download link.

The export workflow is implemented as an Inngest function triggered by an event such as an access/export request, returning success metadata and an expiration window [3].

---

## 11.3 Deletion Workflow

Account deletion may require:

- deleting mood logs,
- deleting journal entries,
- deleting reminders,
- anonymizing consent records,
- removing export files,
- calling vendor deletion APIs,
- recording status,
- retrying failures.

The deletion orchestrator deletes local data like mood logs, journal entries, and reminders, then anonymizes the consent ledger to preserve audit value [3].

This is exactly the kind of workflow that benefits from durable background jobs.

---

## 11.4 Privacy Rule for Job Payloads

Background job payloads should be minimized.

Bad:

```json
{
  "userId": "user_123",
  "journalContent": "I felt terrible today..."
}
```

Better:

```json
{
  "userId": "user_123",
  "exportRequestId": "export_456"
}
```

The worker can fetch sensitive data only when needed, authorize the action, decrypt only inside the controlled workflow, and avoid logging plaintext.

---

# 12. Redis / Upstash-Style Rate Limiting

Rate limiting helps prevent abuse.

GreyMatter MindfulLog uses rate limiting to protect sensitive or expensive endpoints such as:

- export requests,
- deletion requests,
- login-related flows,
- consent update endpoints,
- reminder creation,
- journal creation.

The stack includes Upstash Redis for rate limiting to prevent abuse of export and deletion endpoints [8].

Example protected actions:

```txt
POST /api/access-export
POST /api/delete-account
POST /api/consent
```

Rate limiting is both a security and privacy control.

Why?

Because abusive repeated export or deletion requests can create operational and privacy risks.

---

# 13. PII-Redacting Logger

Logs are dangerous.

They often outlive the request that created them.

They may be copied to vendors, dashboards, alerting tools, and support systems.

GreyMatter MindfulLog includes a PII-redacting logger in the architecture [8].

The goal is to prevent data like this from entering logs:

- journal content,
- mood notes,
- raw request bodies,
- email addresses,
- IP addresses,
- tokens,
- cookies,
- session data,
- export contents.

Bad:

```ts
console.log(req.body);
console.log(journalEntry);
console.log(user);
```

Better:

```ts
safeLog("info", "journal_entry_created", {
  userIdHash,
  entryId,
  hasNotes: true,
});
```

Privacy rule:

```txt
Logs should describe events, not expose private content.
```

---

# 14. Centralized Policy Engine

The policy engine is where authorization decisions happen.

It should answer questions like:

```txt
Can this user view this journal entry?
Can this support user access this account?
Can this admin trigger this export?
Can this user delete this account?
```

The architecture uses a centralized RBAC/ABAC policy engine that is testable and fail-closed [8].

## 14.1 RBAC vs ABAC

**RBAC** means role-based access control.

Example:

```txt
role = "support"
role = "admin"
role = "user"
```

**ABAC** means attribute-based access control.

Example:

```txt
resource.ownerId === context.userId
supportAccessConsent === true
isSupportMasked === true
```

GreyMatter MindfulLog needs both.

---

## 14.2 Fail Closed

Fail closed means:

```txt
If the system is unsure, deny access.
```

Bad:

```ts
return true;
```

Better:

```ts
return false;
```

Unknown access should never be allowed by default.

---

# 15. GitHub Actions

GitHub Actions runs automated checks when code changes.

GreyMatter MindfulLog uses a privacy pipeline that runs on pull requests to `main`.

The pipeline:

1. checks out the code,
2. sets up Node.js,
3. installs dependencies,
4. runs the privacy scanner,
5. runs the build,
6. performs secret scanning with Gitleaks [2].

This matters because privacy should not depend only on manual review.

CI/CD should catch obvious mistakes before they reach production.

---

# 16. PII Schema Scanner

The privacy scanner checks for risky schema changes.

It looks for sensitive patterns such as:

```txt
email
phone
ssn
notes
content
health
password
```

and fails if those appear without signs of encryption or binary storage, such as `encrypted` or `bytea` [2].

Example bad schema:

```sql
notes TEXT
content TEXT
health_notes TEXT
```

Example better schema:

```sql
notes_encrypted BYTEA
content_encrypted BYTEA
```

The scanner is intentionally simple at first.

It is a guardrail, not a replacement for privacy review.

---

# 17. Gitleaks Secret Scanning

Gitleaks scans for accidentally committed secrets.

This can catch things like:

- API keys,
- database URLs,
- private tokens,
- cloud credentials,
- webhook secrets.

GreyMatter MindfulLog’s CI privacy workflow includes Gitleaks as a secret scanning step [2].

Secrets must never be committed to the repository.

Use:

```txt
.env.local
```

for local secrets, and keep it in `.gitignore`.

Use:

```txt
.env.example
```

as the safe committed template.

---

# 18. Environment Variables

Environment variables store configuration and secrets outside source code.

GreyMatter MindfulLog uses environment variables for:

```env
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
DATABASE_URL=
GOOGLE_CLOUD_PROJECT=
KMS_KEY_RING=
KMS_KEY_NAME=
HMAC_SALT=
```

The setup explicitly warns not to hard-code secrets and uses `.env.local` for local configuration [7].

Important distinction:

```txt
NEXT_PUBLIC_* variables are exposed to the browser.
Non-NEXT_PUBLIC variables must stay server-side.
```

Never put secrets in `NEXT_PUBLIC_*`.

Bad:

```env
NEXT_PUBLIC_CLERK_SECRET_KEY=sk_test_...
```

Good:

```env
CLERK_SECRET_KEY=sk_test_...
```

---

# 19. Vercel or Equivalent Hosting

Vercel is a common hosting platform for Next.js.

In a production setup, hosting must be treated as part of the privacy architecture.

Hosting may touch:

- runtime logs,
- environment variables,
- deployment artifacts,
- build output,
- serverless function logs,
- request metadata.

Privacy considerations:

```txt
[ ] Are production secrets protected?
[ ] Are preview deployments configured safely?
[ ] Are logs redacted?
[ ] Who can access deployment dashboards?
[ ] Are environment variables scoped by environment?
[ ] Are production and development projects separated?
```

Vercel or any hosting provider should be documented in the vendor register.

---

# 20. Vendor Register

Every vendor expands the privacy boundary.

GreyMatter MindfulLog should maintain a vendor register for providers such as:

- Clerk,
- Neon,
- Google Cloud,
- Vercel,
- Inngest,
- Redis/Upstash,
- logging tools,
- email services.

The foundation includes a vendor register and agreements such as a DPA for Clerk, SCCs for Neon, and a Google Cloud Data Processing Addendum [7].

For Singapore PDPA alignment, the vendor register also supports transfer limitation, accountability, data intermediary review, and comparable protection analysis.

---

# 21. How the Stack Fits Together

A simplified request flow:

```txt
Browser
  ↓ HTTPS
Next.js Route / Server Action
  ↓
Clerk authentication
  ↓
Zod validation
  ↓
Rate limiting
  ↓
Policy engine
  ↓
Safe logger
  ↓
Encryption service
  ↓
Neon Postgres
  ↓
Inngest job if needed
```

For sensitive content, the flow should look like:

```txt
User writes journal entry
  ↓
Server authenticates user
  ↓
Input is validated
  ↓
Policy engine authorizes operation
  ↓
Journal content is encrypted
  ↓
Encrypted bytes are stored in Neon
  ↓
Safe event is logged without plaintext
```

The architecture specifically requires field-level encryption, minimized encrypted columns, Google Cloud KMS for key management, Inngest for durable jobs, Clerk for identity lifecycle, and CI/CD enforcement [8].

---

# 22. Example: Creating a Mood Log

A privacy-aware flow:

```ts
import { z } from "zod";
import { encryptField } from "@/lib/encryption";
import { safeLog } from "@/lib/safe-logger";
import { sql } from "@/lib/db";

const createMoodLogSchema = z.object({
  moodScore: z.number().int().min(1).max(10),
  notes: z.string().max(5000).optional(),
});

export async function createMoodLog(input: unknown, userId: string) {
  const parsed = createMoodLogSchema.parse(input);

  const notesEncrypted = parsed.notes
    ? await encryptField(parsed.notes)
    : null;

  const result = await sql`
    INSERT INTO mood_logs (user_id, mood_score, notes_encrypted)
    VALUES (${userId}, ${parsed.moodScore}, ${notesEncrypted})
    RETURNING id;
  `;

  safeLog("info", "mood_log_created", {
    userId,
    moodLogId: result[0].id,
    hasNotes: Boolean(parsed.notes),
  });

  return result[0];
}
```

The data layer should encrypt notes before insert and store `notes_encrypted` as binary data rather than readable text [5].

---

# 23. Example: Consent Update

Consent should be append-only.

Bad:

```sql
UPDATE consent_records
SET granted = true
WHERE user_id = $1 AND purpose = 'analytics';
```

Better:

```sql
INSERT INTO consent_records (user_id, purpose, granted)
VALUES ($1, 'analytics', true);
```

GreyMatter MindfulLog records every consent decision as a new immutable record and derives current consent state from the latest record per purpose [4].

This makes the consent history auditable and resistant to silent drift.

---

# 24. Example: Access Export

A personal data access export should not be handled casually.

Expected stack usage:

```txt
Next.js route receives request
  ↓
Clerk confirms identity
  ↓
Rate limit checks request
  ↓
Policy engine confirms user can export own data
  ↓
Inngest job is triggered
  ↓
Worker gathers data
  ↓
Encrypted fields are decrypted only inside job
  ↓
ZIP + manifest is generated
  ↓
Temporary URL is returned
```

The export verification should confirm the generated ZIP contains decrypted JSON and a manifest [3].

---

# 25. Example: Account Deletion

Deletion should be orchestrated.

Expected stack usage:

```txt
Next.js route receives deletion request
  ↓
Clerk confirms identity
  ↓
Optional re-authentication
  ↓
Rate limiting
  ↓
Policy engine confirms account owner
  ↓
Inngest deletion workflow starts
  ↓
Local records deleted
  ↓
Consent ledger anonymized
  ↓
Vendor lifecycle actions triggered
  ↓
Deletion status recorded
```

The deletion orchestrator deletes local mood logs, journal entries, and reminders, then anonymizes consent records for audit preservation [3].

---

# 26. Singapore PDPA Lens

For the Singapore version of GreyMatter MindfulLog, the stack supports PDPA-aligned obligations in practical ways.

| PDPA-Aligned Concern | Stack Support |
|---|---|
| Consent | Append-only consent ledger |
| Notification | Clear UI and settings pages |
| Purpose limitation | DPIA/privacy impact assessment and schema review |
| Access | Personal data access export |
| Correction | User-editable records |
| Protection | Encryption, policy engine, safe logging |
| Retention limitation | Deletion workflows and cleanup jobs |
| Transfer limitation | Vendor register and minimized payloads |
| Accountability | Docs, threat model, CI/CD checks |
| Breach readiness | Incident response playbook |

The technical stack is not “PDPA compliance” by itself, but it gives us the controls needed to build responsibly.

---

# 27. Common Stack Mistakes

## Mistake 1: Trusting the Client

Bad:

```ts
const { userId } = await req.json();
```

Fix:

```ts
const userId = getUserIdFromServerSession();
```

---

## Mistake 2: Logging Sensitive Data

Bad:

```ts
console.log(req.body);
```

Fix:

```ts
safeLog("info", "request_received", {
  route: "/api/mood",
});
```

---

## Mistake 3: Plaintext Sensitive Columns

Bad:

```sql
journal_content TEXT
```

Fix:

```sql
content_encrypted BYTEA
```

---

## Mistake 4: Authorization in Random Places

Bad:

```ts
if (entry.user_id === userId) {
  return entry;
}
```

Fix:

```ts
PolicyEngine.canView(context, resource);
```

---

## Mistake 5: Background Jobs with Plaintext Payloads

Bad:

```ts
await inngest.send({
  name: "journal/process",
  data: {
    userId,
    content: plaintextJournalContent,
  },
});
```

Fix:

```ts
await inngest.send({
  name: "journal/process",
  data: {
    userId,
    entryId,
  },
});
```

---

## Mistake 6: Putting Secrets in Public Env Vars

Bad:

```env
NEXT_PUBLIC_DATABASE_URL=
NEXT_PUBLIC_CLERK_SECRET_KEY=
```

Fix:

```env
DATABASE_URL=
CLERK_SECRET_KEY=
```

---

# 28. Local Development Checklist

Before building features, verify:

```txt
[ ] Node.js 20+ installed
[ ] npm installed
[ ] Git installed
[ ] Next.js app created
[ ] Clerk account created
[ ] Neon project created
[ ] Google Cloud project created
[ ] Cloud KMS enabled
[ ] Redis/Upstash-style rate limiting provider available
[ ] GitHub repository created
```

The prerequisite stack includes Node.js 20+, npm, Git, Clerk, Neon, Google Cloud KMS, Upstash Redis, and GitHub [8].

---

# 29. Project Structure Preview

A mature GreyMatter MindfulLog project may look like this:

```txt
greymatter-mindfullog/
├── app/
│   ├── page.tsx
│   ├── layout.tsx
│   ├── dashboard/
│   ├── journal/
│   ├── mood/
│   ├── settings/
│   │   └── consent/
│   └── api/
│       ├── access-export/
│       ├── delete-account/
│       └── consent/
├── docs/
│   ├── primers/
│   │   ├── Primer-01-Privacy-Engineering-101.md
│   │   ├── Primer-02-Cryptography-Basics.md
│   │   ├── Primer-03-Singapore-PDPA-Basics.md
│   │   ├── Primer-04-Threat-Modeling-with-STRIDE.md
│   │   └── Primer-05-Modern-Web-Stack-Essentials.md
│   ├── PRIVACY_IMPACT_ASSESSMENT.md
│   ├── PRIVACY_CONVENTIONS.md
│   ├── THREAT_MODEL.md
│   ├── VENDOR_REGISTER.md
│   ├── PRIVACY_CHECKLIST.md
│   └── INCIDENT_RESPONSE.md
├── inngest/
│   └── functions/
├── lib/
│   ├── db.ts
│   ├── schema.sql
│   ├── encryption.ts
│   ├── policy-engine.ts
│   ├── consent.ts
│   ├── deletion-orchestrator.ts
│   ├── privacy-utils.ts
│   ├── safe-logger.ts
│   └── env.ts
├── scripts/
│   └── pii-scanner.ts
├── .github/
│   └── workflows/
│       └── privacy.yml
└── package.json
```

---

# 30. Stack Review Checklist

Use this checklist before adding a new feature.

## Next.js

```txt
[ ] Is this a page, route handler, or server action?
[ ] Is sensitive logic kept server-side?
[ ] Are secrets kept out of client code?
```

## Clerk

```txt
[ ] Is the user authenticated?
[ ] Is user identity derived from the server session?
[ ] Are protected routes protected by middleware?
```

## Zod

```txt
[ ] Is input validated at runtime?
[ ] Are string lengths limited?
[ ] Are enums constrained?
[ ] Are numeric ranges enforced?
```

## Policy Engine

```txt
[ ] Does access go through the centralized policy engine?
[ ] Does unknown access fail closed?
[ ] Are support/admin paths constrained?
```

## Neon

```txt
[ ] Is the schema minimized?
[ ] Are sensitive fields encrypted?
[ ] Are indexes free of sensitive plaintext?
[ ] Are queries scoped by authenticated user?
```

## KMS and Encryption

```txt
[ ] Is sensitive free text encrypted before insert?
[ ] Are keys kept out of source code?
[ ] Is KMS used for key wrapping?
[ ] Is decryption limited to authorized flows?
```

## Inngest

```txt
[ ] Should this be a background job?
[ ] Is the payload minimized?
[ ] Is the job idempotent?
[ ] Are retries safe?
```

## Logging

```txt
[ ] Is safe logging used?
[ ] Are request bodies avoided?
[ ] Are sensitive keys redacted?
[ ] Are errors sanitized?
```

## CI/CD

```txt
[ ] Does the build pass?
[ ] Does the privacy scanner pass?
[ ] Does secret scanning pass?
[ ] Does schema change update the privacy impact assessment?
```

---

# 31. Key Takeaways

The GreyMatter MindfulLog stack is not just a collection of tools.

It is a privacy architecture.

The key lessons are:

1. Next.js gives us a full-stack TypeScript foundation.
2. Clerk handles authentication, but authorization still needs a policy engine.
3. Neon Postgres stores application data, but sensitive free text must be encrypted.
4. Zod validates untrusted input at runtime boundaries.
5. Google Cloud KMS protects key encryption keys.
6. Node crypto supports encryption and HMAC utilities.
7. Inngest handles durable export, deletion, and consent workflows.
8. Redis-style rate limiting protects expensive and sensitive endpoints.
9. The safe logger prevents logs from becoming a privacy leak.
10. GitHub Actions and Gitleaks help enforce privacy before code reaches production.
11. Vendor choices must be documented because vendors expand the privacy boundary.
12. The stack supports Singapore PDPA-aligned protection, accountability, retention, and access workflows.

The stack should make the safe path the easy path.

That is the entire point of GreyMatter MindfulLog.

---

# 32. Completion Criteria

You have completed this primer when you can explain:

- why Next.js is used,
- what Clerk does and does not do,
- why authentication is not authorization,
- why Neon must use a minimized encrypted schema,
- why Zod is important at runtime boundaries,
- how Google Cloud KMS supports envelope encryption,
- why Inngest is useful for export and deletion workflows,
- why rate limiting is a privacy control,
- why logs must be redacted,
- what GitHub Actions checks,
- what Gitleaks prevents,
- why vendors must be documented,
- and how the stack supports privacy-first engineering.
