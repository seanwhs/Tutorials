# Primer 04 — Threat Modeling with STRIDE

## For GreyMatter MindfulLog

Welcome to **Primer 04: Threat Modeling with STRIDE**.

This primer explains how to think systematically about security and privacy threats in **GreyMatter MindfulLog**, a privacy-first mental-health journaling application.

GreyMatter MindfulLog handles highly sensitive user data:

- mood scores,
- private mood notes,
- journal entries,
- wellness and medication reminders,
- consent preferences,
- access/export requests,
- account deletion workflows,
- operational logs,
- and vendor-integrated workflows.

Because the application may process mental-health information, we cannot treat security as a checklist added at the end. Threat modeling must happen before we design the database schema, before we implement access control, before we build exports, and before we deploy.

In the GreyMatter MindfulLog architecture, the foundations come first: privacy impact assessment, STRIDE threat modeling, vendor review, and privacy conventions are established before user-facing code because skipping this foundation creates problems that are expensive or impossible to fix later [7].

---

# 1. What Threat Modeling Is

Threat modeling is a structured way to ask:

> What could go wrong, how bad would it be, and what are we doing about it?

It is not paranoia.

It is engineering discipline.

A good threat model helps us identify:

- who might attack the system,
- what assets need protection,
- where trust boundaries exist,
- how data flows through the system,
- what could fail,
- how failures could harm users,
- what controls reduce risk,
- and what evidence proves those controls work.

For GreyMatter MindfulLog, threat modeling is especially important because the application stores private mental-health reflections. A breach or misuse of this data could cause emotional, reputational, professional, financial, or personal harm to users.

---

# 2. Why Threat Modeling Comes Before the Schema

A common mistake is to design tables first and ask security questions later.

That is backwards.

If you create a table like this:

```sql
CREATE TABLE journal_entries (
  id UUID PRIMARY KEY,
  user_id TEXT NOT NULL,
  title TEXT,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

you have already made a major privacy decision:

> Journal content will be stored in plaintext.

Once that decision is embedded into the schema, every later feature inherits the risk.

Instead, GreyMatter MindfulLog starts with threat modeling and data minimization. The less data we store, and the more intentionally we store it, the less can be stolen, leaked, or misused [6].

A privacy-first schema should be designed after we understand:

- what the sensitive assets are,
- who might access them,
- how they could leak,
- what storage protections are needed,
- what deletion must remove,
- what exports must include,
- and what logs must avoid.

That is why STRIDE and the privacy impact assessment are part of the foundation.

---

# 3. What STRIDE Means

**STRIDE** is a threat modeling framework.

It helps us examine a system through six categories of threats:

| Letter | Category | Core Question |
|---|---|---|
| S | Spoofing | Can someone pretend to be someone else? |
| T | Tampering | Can someone modify data or behavior improperly? |
| R | Repudiation | Can someone deny an action because there is no reliable record? |
| I | Information Disclosure | Can sensitive data be exposed? |
| D | Denial of Service | Can the system be made unavailable or degraded? |
| E | Elevation of Privilege | Can someone gain more power than they should have? |

The GreyMatter MindfulLog foundation explicitly uses STRIDE as a safety-inspection checklist for the app, alongside a living privacy impact assessment that maps every data asset, its purpose, sensitivity, storage method, and mitigation [7].

---

# 4. STRIDE in One Sentence Each

## Spoofing

Someone pretends to be another user, service, or system.

Example:

> An attacker sends an API request claiming to be another user.

---

## Tampering

Someone modifies data, requests, events, or records without permission.

Example:

> A user changes another user’s journal entry ID in a request.

---

## Repudiation

Someone performs an action and later denies it because there is no reliable audit trail.

Example:

> A support user accesses a record, but the system has no access log.

---

## Information Disclosure

Sensitive data is exposed to someone who should not see it.

Example:

> Plaintext journal content appears in logs or a database dump.

---

## Denial of Service

Someone prevents legitimate users from using the system.

Example:

> An attacker repeatedly triggers expensive export jobs.

---

## Elevation of Privilege

Someone gains permissions beyond what they should have.

Example:

> A support user obtains unmasked admin-level access to private journal content.

---

# 5. GreyMatter MindfulLog Assets

Before applying STRIDE, identify what we are protecting.

An **asset** is anything valuable, sensitive, or operationally important.

## 5.1 User Data Assets

| Asset | Sensitivity | Why It Matters |
|---|---:|---|
| Mood score | Medium | Reveals emotional state over time |
| Mood notes | Very High | May contain mental-health details |
| Journal entries | Very High | Highly personal free text |
| Reminder labels | High | May reveal medication or wellness routines |
| Consent history | Medium/High | Shows user preferences and legal state |
| Export files | Very High | Bundle of user data |
| Deletion requests | High | Account lifecycle and rights exercise |
| Email/account metadata | High | Identity and contact data |

GreyMatter MindfulLog uses minimized schema design and encrypted binary fields for sensitive content so that the database does not store plaintext health data for fields like private notes and journal content [6].

---

## 5.2 System Assets

| Asset | Why It Matters |
|---|---|
| Authentication sessions | Control who is logged in |
| Database credentials | Allow data access |
| Encryption keys | Protect sensitive content |
| KMS access | Allows wrapping/unwrapping data keys |
| Background job events | Trigger exports, deletion, consent propagation |
| Logs | May reveal sensitive operational details |
| Vendor dashboards | May expose account or runtime data |
| CI/CD pipeline | Controls what reaches production |

The architecture uses field-level encryption, a centralized policy engine, safe logging, privacy CI/CD, and incident response as part of the privacy-first system [8].

---

# 6. Trust Boundaries

A **trust boundary** is a place where data or control crosses from one trust zone into another.

Trust boundaries are where many threats appear.

For GreyMatter MindfulLog, important boundaries include:

```txt
Browser
  ↓
Next.js application
  ↓
Authentication provider
  ↓
Policy engine
  ↓
Database
  ↓
Encryption/KMS layer
  ↓
Background jobs
  ↓
Export storage
  ↓
Logs and monitoring
  ↓
Vendors and infrastructure
```

Each boundary deserves questions.

## Browser → Server

Questions:

- Is the user authenticated?
- Are inputs validated?
- Are user IDs trusted from the client?
- Could the request be forged?
- Could sensitive data be logged?

---

## Server → Database

Questions:

- Is the query scoped to the authenticated user?
- Are sensitive fields encrypted before insert?
- Are plaintext fields justified?
- Are database errors sanitized?
- Does the schema match the DPIA?

---

## Server → KMS

Questions:

- Who can call KMS?
- Are keys managed outside the database?
- Are DEKs generated correctly?
- Is key usage auditable?
- What happens if KMS fails?

GreyMatter MindfulLog uses envelope encryption with a data encryption key for data and a key encryption key protected through Google Cloud KMS [5].

---

## Server → Background Jobs

Questions:

- Does the event contain sensitive plaintext?
- Can the event be forged?
- Is the job idempotent?
- What happens if the job partially fails?
- Is there retry and failure tracking?

Deletion is expected to use explicit sequencing and retries across systems [3].

---

## Server → Logs

Questions:

- Are journal entries ever logged?
- Are raw request bodies logged?
- Are emails, IPs, tokens, or notes redacted?
- Are logs retained too long?

The system includes a PII-redacting logger concept that recursively redacts sensitive values before logging and blocks raw `console.log` in favor of safer logging [2].

---

# 7. Data Flow: Mood Log Creation

Let’s threat model one core flow: creating a mood log.

## 7.1 Expected Flow

```txt
1. User opens mood form.
2. User enters mood score and optional note.
3. Browser sends request to server.
4. Server verifies authenticated user.
5. Server validates mood score.
6. Server encrypts optional note.
7. Server stores mood score and encrypted note.
8. Server logs a safe event without note content.
```

The data layer encrypts private notes before insertion, storing `notes_encrypted` as binary data rather than readable text [5].

---

## 7.2 Threats

| STRIDE | Threat | Mitigation |
|---|---|---|
| Spoofing | User sends another user’s ID | Derive user ID from server session |
| Tampering | User sends invalid mood score | Server-side validation and DB constraints |
| Repudiation | User denies creating entry | Audit event without sensitive content |
| Information Disclosure | Note appears in logs | Safe logger and no raw request logging |
| Denial of Service | Repeated mood submissions | Rate limiting |
| Elevation of Privilege | User writes to another account | Policy engine and owner scoping |

---

## 7.3 Safer Pattern

Bad:

```ts
const body = await req.json();

await sql`
  INSERT INTO mood_logs (user_id, mood_score, notes)
  VALUES (${body.userId}, ${body.score}, ${body.notes})
`;
```

Problems:

- trusts client-provided `userId`,
- stores notes in plaintext,
- does not validate ownership,
- does not encrypt,
- likely encourages unsafe logging.

Better:

```ts
const userId = getUserIdFromServerSession();
const score = validateMoodScore(body.score);
const notesEncrypted = body.notes
  ? await encryptField(body.notes)
  : null;

await sql`
  INSERT INTO mood_logs (user_id, mood_score, notes_encrypted)
  VALUES (${userId}, ${score}, ${notesEncrypted})
`;
```

This follows the project’s intended pattern: sensitive notes are encrypted before storage and stored as binary encrypted data [5].

---

# 8. Data Flow: Journal Entry Creation

Journal entries are among the highest-risk data in the app.

## 8.1 Expected Flow

```txt
1. User writes journal entry.
2. Server authenticates user.
3. Server validates input.
4. Server encrypts journal content.
5. Server stores encrypted content.
6. Server returns entry ID.
7. Server logs only a safe event.
```

---

## 8.2 STRIDE Analysis

### Spoofing

Threat:

- Attacker submits a journal entry as another user.

Mitigation:

- never accept `userId` from client body,
- derive identity from authenticated session,
- use authentication provider session validation.

The foundation threat model identifies spoofing as mitigated by Clerk and session tokens [7].

---

### Tampering

Threat:

- Attacker modifies another user’s entry by changing an ID.

Mitigation:

- policy engine checks ownership,
- SQL queries scope by authenticated `userId`,
- server validates resource ownership.

The policy engine uses a fail-closed approach: owners can access their own resources, support only receives masked views, and unknown access is denied [5].

---

### Repudiation

Threat:

- User or staff member denies an action.

Mitigation:

- audit events,
- append-only consent records where relevant,
- export and deletion request logs,
- support access logs.

The STRIDE model identifies repudiation as mitigated through immutable audit logs and the consent ledger [7].

---

### Information Disclosure

Threat:

- Journal content leaks through database, logs, support UI, exports, or backups.

Mitigation:

- field-level encryption,
- safe logging,
- masked support views,
- temporary export files,
- encrypted backups,
- access control.

Field-level encryption and a centralized policy engine provide defense in depth for health data even if the database is breached or a developer makes a mistake [5].

---

### Denial of Service

Threat:

- Large entries, repeated submissions, or abusive requests degrade service.

Mitigation:

- input size limits,
- rate limiting,
- queue controls,
- database limits.

The foundation threat model lists denial of service mitigations such as rate limiting and Neon scaling [7].

---

### Elevation of Privilege

Threat:

- Support or admin role gains full journal access.

Mitigation:

- support access masked by default,
- policy engine,
- audit logs,
- explicit support-access consent,
- just-in-time access where appropriate.

The policy engine design allows support viewing only when `isSupportMasked` is true and otherwise denies unknown access [5].

---

# 9. Data Flow: Consent Change

Consent is a privacy-critical workflow.

## 9.1 Expected Flow

```txt
1. User opens consent settings.
2. User chooses Allow or Don’t Allow for each purpose.
3. Server records a new consent event.
4. System derives current state from latest event.
5. Background job propagates change to relevant systems.
```

Consent should not use manipulative UI. GreyMatter MindfulLog’s consent screen uses equal prominence for “Allow” and “Don’t Allow,” no pre-checked boxes, and clear descriptions [4].

---

## 9.2 STRIDE Analysis

| STRIDE | Threat | Mitigation |
|---|---|---|
| Spoofing | Attacker changes another user’s consent | Server-side session identity |
| Tampering | Old consent record is edited | Append-only ledger |
| Repudiation | User denies consent change | Immutable consent history |
| Information Disclosure | Consent screen leaks other data | Scope queries to user |
| Denial of Service | Consent endpoint spammed | Rate limiting |
| Elevation of Privilege | Staff changes consent for user | Policy engine and audit |

The consent ledger should never update prior records; every consent decision is inserted as a new immutable record, and current state is derived from the latest record per purpose [4].

---

# 10. Data Flow: PDPA Access Request Export

For the Singapore-adapted version, we can call this a **PDPA Access Request Export** rather than a GDPR DSAR export.

The engineering pattern remains similar: the user requests a complete export of their personal data.

## 10.1 Expected Flow

```txt
1. User requests export.
2. Server authenticates user.
3. Server creates export job.
4. Background worker gathers data.
5. Encrypted fields are decrypted only for export.
6. Export ZIP is generated.
7. Export manifest is included.
8. Export is made temporary and access-controlled.
9. Export request is logged safely.
```

The existing export implementation packages data such as mood logs, consent history, and a manifest into a ZIP file [3].

---

## 10.2 STRIDE Analysis

### Spoofing

Threat:

- Attacker requests another user’s export.

Mitigation:

- derive user ID from authenticated session,
- ignore client-provided user IDs,
- require re-authentication for sensitive export flows where appropriate.

---

### Tampering

Threat:

- Export job parameters are modified to include another user’s data.

Mitigation:

- job payload contains only server-derived user ID,
- worker revalidates authorization,
- export query scopes by user ID.

---

### Repudiation

Threat:

- User or attacker denies requesting export.

Mitigation:

- export request audit record,
- timestamp,
- requester ID,
- safe metadata,
- export completion status.

---

### Information Disclosure

Threat:

- Export file leaks,
- export URL is too long-lived,
- plaintext appears in job logs,
- export sent to wrong user.

Mitigation:

- short-lived links,
- authentication before download,
- encrypted storage,
- no plaintext in logs,
- export manifest,
- safe background job payloads.

---

### Denial of Service

Threat:

- Attacker triggers many export jobs.

Mitigation:

- rate limit export requests,
- queue controls,
- maximum export frequency,
- background job throttling.

---

### Elevation of Privilege

Threat:

- Support or admin triggers exports for users without authorization.

Mitigation:

- policy engine,
- audit logging,
- user-initiated export by default,
- administrative export only under controlled policy.

---

# 11. Data Flow: Account Deletion and Retention Limitation

For the Singapore PDPA adaptation, deletion can be framed as:

```txt
Account Deletion and Retention Limitation
```

rather than only “Right to be Forgotten.”

## 11.1 Expected Flow

```txt
1. User requests account deletion.
2. Server verifies identity.
3. System records deletion request.
4. Local mood logs are deleted.
5. Journal entries are deleted.
6. Reminders are deleted.
7. Consent ledger is anonymized where audit retention is needed.
8. Vendor deletion or deactivation workflows run.
9. Export files are deleted.
10. Deletion status is recorded.
```

The deletion orchestrator deletes mood logs, journal entries, and reminders, then anonymizes consent records to preserve audit value [3].

---

## 11.2 STRIDE Analysis

| STRIDE | Threat | Mitigation |
|---|---|---|
| Spoofing | Attacker deletes another user’s account | Re-authentication and server-side identity |
| Tampering | Deletion job skips records | Explicit sequencing and verification |
| Repudiation | User denies deletion request | Deletion request audit event |
| Information Disclosure | Deleted data remains in export file | Export cleanup and retention rules |
| Denial of Service | Deletion endpoint spammed | Rate limiting and confirmation |
| Elevation of Privilege | Staff deletes account improperly | Policy engine and admin audit |

Deletion must be explicit and reliable because it spans multiple systems. The provided deletion concept uses sequencing and retries for atomic deletion across systems [3].

---

# 12. STRIDE Category Deep Dive

## 12.1 Spoofing

Spoofing is about false identity.

Examples in GreyMatter MindfulLog:

- request body includes another user’s ID,
- stolen session token is reused,
- fake webhook triggers a deletion job,
- background event impersonates system process,
- support user pretends to be an admin.

Mitigations:

- server-side authentication,
- session validation,
- never trust client-provided user IDs,
- signed webhooks/events,
- short-lived sessions,
- re-authentication for sensitive actions,
- audit logs.

Checklist:

```txt
[ ] Is identity derived from a trusted source?
[ ] Are client-provided user IDs ignored?
[ ] Are webhooks signed?
[ ] Are background events authenticated?
[ ] Are sensitive actions re-authenticated?
```

---

## 12.2 Tampering

Tampering is unauthorized modification.

Examples:

- changing mood score outside valid range,
- editing another user’s journal entry,
- modifying consent records,
- changing export job payload,
- altering encrypted bytes in database,
- modifying deletion status.

Mitigations:

- server-side validation,
- database constraints,
- AES-GCM authentication tags,
- append-only consent ledger,
- policy engine,
- audit records.

The STRIDE model identifies tampering as mitigated through AES-GCM and authentication tags [7].

Checklist:

```txt
[ ] Are inputs validated server-side?
[ ] Are database constraints present?
[ ] Is sensitive ciphertext authenticated?
[ ] Are consent records append-only?
[ ] Are job payloads trusted and verified?
```

---

## 12.3 Repudiation

Repudiation means lack of accountability.

Examples:

- user denies changing consent,
- admin denies accessing data,
- support denies viewing a record,
- system cannot prove deletion occurred,
- export was generated but no audit record exists.

Mitigations:

- append-only consent records,
- audit events,
- export request logs,
- deletion workflow status,
- support access logging,
- safe logging.

Consent history is especially important because each consent decision is recorded as an immutable event rather than overwriting the prior state [4].

Checklist:

```txt
[ ] Is the action logged safely?
[ ] Does the log avoid sensitive content?
[ ] Is there a timestamp?
[ ] Is there an actor?
[ ] Can the action be reconstructed later?
```

---

## 12.4 Information Disclosure

Information disclosure is the most serious category for GreyMatter MindfulLog.

Examples:

- journal content stored as plaintext,
- mood notes appear in logs,
- support sees unmasked entries,
- export file is exposed,
- database dump leaks encrypted and unencrypted data,
- vendor receives plaintext content unnecessarily,
- error pages reveal secrets.

Mitigations:

- data minimization,
- field-level encryption,
- encrypted binary columns,
- safe logger,
- masked support views,
- policy engine,
- short-lived exports,
- encrypted backups,
- vendor minimization.

Sensitive fields should use binary encrypted storage so the database cannot store plaintext health data for those fields [6].

Checklist:

```txt
[ ] Is sensitive free text encrypted?
[ ] Are logs redacted?
[ ] Are support views masked?
[ ] Are exports temporary?
[ ] Are vendors receiving minimized payloads?
[ ] Are backups encrypted?
```

---

## 12.5 Denial of Service

Denial of service affects availability.

Examples:

- repeated login attempts,
- repeated export generation,
- repeated deletion requests,
- huge journal entries,
- background queue flooding,
- expensive database queries.

Mitigations:

- rate limiting,
- size limits,
- queue controls,
- job deduplication,
- caching where safe,
- database indexing,
- scaling.

The foundation threat model lists rate limiting and Neon scaling as denial-of-service mitigations [7].

Checklist:

```txt
[ ] Are expensive endpoints rate-limited?
[ ] Are background jobs bounded?
[ ] Are payload sizes limited?
[ ] Are repeated requests deduplicated?
[ ] Are database queries indexed?
```

---

## 12.6 Elevation of Privilege

Elevation of privilege means a user or process gains more authority than intended.

Examples:

- ordinary user accesses admin route,
- support user sees unmasked journal content,
- admin bypasses policy engine,
- API route forgets authorization,
- background job runs with excessive permissions.

Mitigations:

- centralized policy engine,
- role-based and attribute-based checks,
- fail-closed defaults,
- least privilege,
- route tests,
- support masking,
- audit logs.

All access decisions should go through one trusted policy engine, and unknown access should fail closed [5].

Checklist:

```txt
[ ] Does this route call the policy engine?
[ ] Is support access masked?
[ ] Are admin actions audited?
[ ] Are background jobs least-privileged?
[ ] Does unknown access fail closed?
```

---

# 13. Threat Modeling the Privacy Architecture

GreyMatter MindfulLog has several core privacy controls.

Threat modeling helps confirm what each one protects against.

| Control | Primary Threat Reduced |
|---|---|
| Data minimization | Information disclosure |
| Field-level encryption | Information disclosure, tampering |
| AES-GCM auth tags | Tampering |
| Policy engine | Elevation of privilege, information disclosure |
| Append-only consent | Repudiation, tampering |
| Safe logger | Information disclosure |
| HMAC for IPs | Information disclosure |
| DSAR/access export audit | Repudiation |
| Deletion orchestrator | Retention risk, repudiation |
| Privacy CI scanner | Developer mistakes, information disclosure |
| Incident response | Impact of failures |

GreyMatter MindfulLog’s final project includes a living DPIA, encrypted minimized schema, envelope encryption library, centralized policy engine, append-only consent system, export and deletion pipelines, privacy CI/CD, and a full incident playbook [1].

---

# 14. Singapore PDPA Angle

For the Singapore-adapted series, STRIDE remains the technical threat-modeling framework, but the legal framing should align with the PDPA.

Threat modeling supports PDPA-aligned obligations such as:

- protecting personal data,
- limiting collection and use to appropriate purposes,
- supporting access and correction,
- retaining data only as needed,
- handling withdrawal of consent,
- assessing notifiable data breaches,
- maintaining accountability.

For example:

| PDPA Concern | STRIDE Connection |
|---|---|
| Unauthorized disclosure | Information Disclosure |
| Inaccurate or altered records | Tampering |
| Unverifiable consent | Repudiation |
| Overbroad support access | Elevation of Privilege |
| Export misuse | Spoofing, Information Disclosure |
| Incomplete deletion | Tampering, Repudiation |
| Breach response | All categories, especially Information Disclosure |

The technical architecture does not need to change dramatically between GDPR and Singapore PDPA. What changes is the legal vocabulary and notification framing.

---

# 15. Threat Model Document Template

Create or update:

```bash
touch docs/THREAT_MODEL.md
```

Add a structure like this:

```md
# Threat Model — GreyMatter MindfulLog

Last updated: YYYY-MM-DD

Owner: Privacy Engineering

---

## 1. System Overview

GreyMatter MindfulLog is a privacy-first mental-health journaling application.

Primary components:

- Next.js application
- Authentication provider
- Neon PostgreSQL database
- Field-level encryption layer
- KMS/key management
- Consent ledger
- Policy engine
- Background jobs
- Access request export pipeline
- Account deletion workflow
- Privacy-safe logger
- CI/CD privacy checks

---

## 2. Protected Assets

| Asset | Sensitivity | Protection |
|---|---:|---|
| Mood score | Medium | Validation, owner access |
| Mood notes | Very High | Field-level encryption |
| Journal content | Very High | Field-level encryption |
| Reminder labels | High | Minimization/encryption |
| Consent history | Medium | Append-only ledger |
| Export files | Very High | Temporary, access-controlled |
| Logs | High | Redaction |
| Encryption keys | Critical | KMS |

---

## 3. Trust Boundaries

| Boundary | Risk |
|---|---|
| Browser to server | Spoofing, invalid input |
| Server to database | Unauthorized access |
| Server to KMS | Key misuse |
| Server to background jobs | Event spoofing |
| Server to export storage | Data leakage |
| App to logs | Sensitive data exposure |
| App to vendors | Over-disclosure |

---

## 4. STRIDE Analysis

### Spoofing

Threats:

- Client sends fake user ID.
- Session token stolen.
- Background event forged.

Mitigations:

- Server-side auth.
- Never trust client user IDs.
- Signed events.
- Re-authentication for sensitive actions.

---

### Tampering

Threats:

- User edits another user’s journal.
- Consent record is modified.
- Export job payload is changed.

Mitigations:

- Policy engine.
- Append-only consent.
- Server-side validation.
- AES-GCM auth tags.

---

### Repudiation

Threats:

- User denies consent change.
- Support denies access.
- Export/deletion has no record.

Mitigations:

- Consent ledger.
- Audit events.
- Export logs.
- Deletion status records.

---

### Information Disclosure

Threats:

- Database breach.
- Logs leak journal content.
- Export file exposed.
- Support sees unmasked data.

Mitigations:

- Field-level encryption.
- Safe logger.
- Temporary exports.
- Masked support views.
- Policy engine.

---

### Denial of Service

Threats:

- Export endpoint spam.
- Large journal payloads.
- Queue flooding.

Mitigations:

- Rate limiting.
- Size limits.
- Queue controls.
- Job deduplication.

---

### Elevation of Privilege

Threats:

- User accesses admin route.
- Support sees full journal content.
- Route bypasses policy engine.

Mitigations:

- Fail-closed policy engine.
- Least privilege.
- Route authorization tests.
- Support masking.
```

---

# 16. Threat Modeling Questions for Every Feature

Before adding any new GreyMatter MindfulLog feature, ask these questions.

## Identity

```txt
[ ] Who is the actor?
[ ] How do we know who they are?
[ ] Are we trusting client-provided identity?
[ ] Should this action require re-authentication?
```

---

## Data

```txt
[ ] What personal data is involved?
[ ] Is any data sensitive mental-health data?
[ ] Can the data be minimized?
[ ] Should the data be encrypted?
[ ] Should it be included in access exports?
[ ] Should it be deleted during account deletion?
```

---

## Access

```txt
[ ] Who can view this data?
[ ] Who can edit it?
[ ] Who can delete it?
[ ] Does access go through the policy engine?
[ ] Does unknown access fail closed?
```

---

## Consent

```txt
[ ] Is consent required?
[ ] Is the purpose clear?
[ ] Can the user withdraw consent?
[ ] Is consent append-only?
[ ] Does withdrawal propagate downstream?
```

---

## Logging

```txt
[ ] Could this feature log sensitive data?
[ ] Are request bodies logged?
[ ] Are errors sanitized?
[ ] Is safe logging used?
```

---

## Abuse

```txt
[ ] Can this endpoint be spammed?
[ ] Is it expensive?
[ ] Does it trigger background jobs?
[ ] Is rate limiting needed?
```

---

## Vendors

```txt
[ ] Does data leave our system?
[ ] Is the vendor documented?
[ ] Is the payload minimized?
[ ] Is plaintext journal content avoided?
```

---

## Failure

```txt
[ ] What happens if the operation fails halfway?
[ ] Can we retry safely?
[ ] Is the job idempotent?
[ ] Is there a status record?
[ ] Would this failure require incident response?
```

---

# 17. Example Threat Model: Support Access

Support access is high risk.

Users may need help, but support staff should not casually see private journal entries.

## Expected Design

```txt
1. User requests support.
2. User grants support_access consent.
3. Support user can view masked/minimized information.
4. Full journal content remains inaccessible by default.
5. Support access is logged.
6. User can withdraw support access.
```

## STRIDE Analysis

| STRIDE | Threat | Mitigation |
|---|---|---|
| Spoofing | Fake support user | Server-side role checks |
| Tampering | Support modifies records | Support role cannot edit user entries |
| Repudiation | Support denies access | Audit access events |
| Information Disclosure | Support sees journal content | Masked views only |
| Denial of Service | Support tools queried excessively | Rate limits and audit |
| Elevation of Privilege | Support becomes admin-like | Policy engine and least privilege |

The policy engine model supports this by allowing support viewing only in a masked mode and denying unknown access [5].

---

# 18. Example Threat Model: Export Link

Exports are dangerous because they bundle personal data.

## STRIDE Analysis

| STRIDE | Threat | Mitigation |
|---|---|---|
| Spoofing | Attacker downloads export | Authenticated download |
| Tampering | Export content modified | Manifest/checksums |
| Repudiation | Export request denied | Audit event |
| Information Disclosure | Link leaked | Short expiration |
| Denial of Service | Export spam | Rate limits |
| Elevation of Privilege | Admin exports user data | Policy and audit |

The export flow includes a manifest with metadata such as user ID, export timestamp, record count, and completeness status [3].

---

# 19. Example Threat Model: Logs

Logs are often overlooked.

## Risks

```txt
console.log(req.body)
console.log(user)
console.log(journalEntry)
console.log(error)
```

These can leak:

- notes,
- content,
- email,
- phone,
- tokens,
- IP addresses,
- internal IDs.

## Mitigations

- use safe logger,
- redact sensitive keys,
- avoid raw request logging,
- block `console.log`,
- keep log retention short,
- review incident logs carefully.

The project’s safe logger redacts sensitive values such as notes, content, email, phone, and encrypted notes before logging [2].

---

# 20. Threat Modeling and Incident Response

Threat modeling identifies what could go wrong.

Incident response defines what to do when it does.

For GreyMatter MindfulLog, the incident playbook includes severity levels:

- SEV-1 for plaintext health data exposure,
- SEV-2 for potential encrypted data breach,
- SEV-3 for near-miss or policy violation [1].

The response process includes:

1. detect,
2. contain,
3. eradicate,
4. recover,
5. post-mortem [1].

Threat modeling should feed incident response.

If we identify a new high-risk threat, we should update:

- incident playbook,
- DPIA/privacy impact assessment,
- scanner rules,
- tests,
- logging controls,
- vendor register,
- and operational checklists.

---

# 21. Mini Exercise: Threat Model a Reminder Feature

Feature:

> Users can create medication or wellness reminders.

Questions:

## Assets

- reminder label,
- reminder time,
- user ID,
- notification settings.

## STRIDE

| Category | Possible Threat |
|---|---|
| Spoofing | Attacker creates reminder for another user |
| Tampering | Reminder time changed without authorization |
| Repudiation | User denies creating reminder |
| Information Disclosure | Reminder label reveals medication |
| Denial of Service | Reminder spam overwhelms jobs |
| Elevation of Privilege | Support sees sensitive reminder labels |

## Mitigations

- derive user from session,
- policy engine,
- validate reminder input,
- encrypt or minimize label,
- safe logging,
- rate limiting,
- include in export,
- delete during account deletion.

The deletion workflow should remove reminders along with mood logs and journal entries during account deletion [3].

---

# 22. Mini Exercise: Find the STRIDE Problems

Review this code:

```ts
export async function getJournalEntry(req: Request) {
  const { userId, entryId } = await req.json();

  console.log("Fetching journal", { userId, entryId });

  const rows = await sql`
    SELECT * FROM journal_entries
    WHERE id = ${entryId}
  `;

  return Response.json(rows[0]);
}
```

Problems:

1. Trusts `userId` from request body.
2. Does not use authenticated server session.
3. Does not check ownership.
4. Does not use policy engine.
5. Logs request data unsafely.
6. Query does not scope by authenticated user.
7. May return encrypted or plaintext content improperly.
8. No fail-closed behavior.

STRIDE mapping:

| Problem | STRIDE |
|---|---|
| Trusts client user ID | Spoofing |
| No ownership check | Elevation of Privilege |
| Unsafe logging | Information Disclosure |
| No audit event | Repudiation |
| Query by ID only | Information Disclosure |
| No validation | Tampering |

Safer sketch:

```ts
export async function getJournalEntry(req: Request) {
  const userId = getUserIdFromServerSession();
  const { entryId } = await req.json();

  const entry = await sql`
    SELECT id, user_id, content_encrypted, created_at
    FROM journal_entries
    WHERE id = ${entryId}
    AND user_id = ${userId}
  `;

  if (!entry[0]) {
    throw new Error("Not found");
  }

  const allowed = PolicyEngine.canView(
    { userId, role: "owner" },
    { ownerId: entry[0].user_id, type: "journal" }
  );

  if (!allowed) {
    throw new Error("Forbidden");
  }

  return entry[0];
}
```

---

# 23. Threat Modeling Review Checklist

Use this before merging privacy-relevant features.

## STRIDE Coverage

```txt
[ ] Spoofing considered
[ ] Tampering considered
[ ] Repudiation considered
[ ] Information disclosure considered
[ ] Denial of service considered
[ ] Elevation of privilege considered
```

## Privacy Controls

```txt
[ ] Sensitive data minimized
[ ] Sensitive free text encrypted
[ ] Access goes through policy engine
[ ] Logs are safe
[ ] Consent implications reviewed
[ ] Export implications reviewed
[ ] Deletion implications reviewed
[ ] Vendor implications reviewed
```

## Documentation

```txt
[ ] Threat model updated
[ ] Privacy impact assessment updated
[ ] Vendor register updated if needed
[ ] Privacy checklist updated if needed
[ ] Incident playbook updated if needed
```

## Verification

```txt
[ ] Unit tests added
[ ] Authorization tests added
[ ] Privacy scanner passes
[ ] Build passes
[ ] Manual checks performed if sensitive
```

The final verification flow includes running the build, privacy scan, and database connection test, plus manual checks for encrypted storage, denied unauthorized access, valid export ZIP generation, and deletion/anonymization [1].

---

# 24. Key Takeaways

Threat modeling is how GreyMatter MindfulLog turns privacy concerns into engineering decisions.

The most important lessons are:

1. Threat modeling should happen before schema design.
2. STRIDE gives us six categories of failure to examine.
3. Mental-health data makes information disclosure especially severe.
4. Trust boundaries reveal where controls are needed.
5. Never trust client-provided identity.
6. Sensitive free text should be encrypted before storage.
7. Access control must be centralized and fail closed.
8. Consent should be append-only and auditable.
9. Export and deletion workflows are high-risk privacy surfaces.
10. Logs are a major information-disclosure risk.
11. Incident response should be informed by the threat model.
12. Threat models must evolve as the system changes.

Threat modeling is not a one-time document.

It is a habit.

Every new feature should ask:

> What could go wrong, how could it harm the user, and what control prevents it?

---

# 25. Completion Criteria

You have completed this primer when you can explain:

- what threat modeling is,
- why STRIDE is useful,
- what each STRIDE category means,
- why trust boundaries matter,
- how spoofing appears in API routes,
- how tampering appears in consent and database workflows,
- how repudiation is reduced through audit trails,
- why information disclosure is the highest-risk category for journal data,
- how denial of service affects export and deletion jobs,
- how elevation of privilege appears in support/admin tooling,
- why policy engines should fail closed,
- why logs need threat modeling,
- and how threat modeling supports Singapore PDPA-aligned accountability and protection.
