# GreyMatter Feedback Threat Model

**Version:** 1.0  
**Methodology:** STRIDE-inspired threat modeling  
**System:** QR-code feedback collection, form authoring, analytics, CSV export, and PDF reporting platform

---

## 1. Scope

This threat model covers:

```text
Participant QR-code feedback flow
Administrator authentication and authoring
Next.js application and API routes
Neon PostgreSQL through Prisma
Inngest background functions
Upstash Redis rate limiting
PDF report generation
S3-compatible report storage
CSV export
Browser localStorage drafts and offline outbox
```

---

## 2. Security Objectives

GreyMatter Feedback must protect:

| Objective | Description |
|---|---|
| Confidentiality | Participant comments, reports, exports, credentials, and admin access must remain private |
| Integrity | Forms, responses, analytics, reports, and session states must not be modified improperly |
| Availability | Participants must be able to submit feedback during active events |
| Privacy | Raw IP addresses should not be retained; data collection should be minimized |
| Historical accuracy | Responses must remain associated with the exact published form version used |
| Non-repudiation / auditability | Important administrator actions should be traceable in a production-grade deployment |

---

## 3. High-Value Assets

| Asset | Sensitivity | Why It Matters |
|---|---|---|
| Admin credentials | Critical | Grants access to authoring, exports, and reports |
| `ADMIN_SESSION_SECRET` | Critical | Signs administrator session tokens |
| `DATABASE_URL` / `DIRECT_URL` | Critical | Grants database access |
| `IP_HASH_SECRET` | High | Protects privacy-aware rate-limit hashing |
| Inngest keys | High | Allows event dispatch or verification |
| S3 storage credentials | Critical | Can expose or overwrite reports |
| Form definitions | Medium | Incorrect forms create invalid data and poor participant experience |
| Participant responses | High | May contain sensitive opinions or personal data |
| Written comments | High | May contain personal, confidential, or harmful content |
| CSV exports | High | Bulk feedback data may be shared incorrectly |
| PDF reports | High | May contain qualitative feedback and organizational insights |
| Rate-limit state | Medium | Protects availability and abuse resistance |
| QR URLs | Low to Medium | Public by design, but should target correct active sessions |

---

## 4. Trust Boundaries

```text
Participant Browser
        │
        │ Untrusted public input
        ▼
Next.js Public Routes and Feedback API
        │
        ├── Trust boundary: validation and rate limiting
        ▼
Inngest Event Bus
        │
        ├── Trust boundary: signed event delivery
        ▼
Neon PostgreSQL
        │
        ├── Trust boundary: data persistence
        ▼
S3-Compatible Report Storage

Administrator Browser
        │
        │ Authenticated but potentially compromised client
        ▼
Next.js Admin Routes and Server Actions
        │
        ├── Trust boundary: session verification and authorization
        ▼
Neon / Inngest / Storage
```

Primary untrusted sources:

```text
Participant form data
QR route parameters
Browser metadata
HTTP headers
CSV content
Written feedback
Administrator form inputs
External service responses
Object storage URLs
```

---

# 5. Threat Actors

| Threat Actor | Capability | Likely Goal |
|---|---|---|
| Casual participant | Can scan QR and submit feedback | Submit duplicate or misleading feedback |
| Automated bot | Can send high-volume API requests | Spam, denial of service, corrupt analytics |
| Malicious participant | Can alter browser requests | Submit invalid values or exploit validation gaps |
| Unauthorized outsider | Can access public URLs | Find exposed reports or admin weaknesses |
| Compromised admin browser | Can use active admin session | Modify forms, export data, request reports |
| Insider administrator | Has legitimate access | Misuse exports, delete data, alter sessions |
| Misconfigured deployment | Incorrect secrets, storage, or URLs | Expose data accidentally |
| Third-party dependency failure | Neon, Inngest, Upstash, storage outage | Cause service interruption |
| Supply-chain attacker | Compromised npm dependency | Steal data or execute malicious code |

---

# 6. Threat Analysis by System Area

## 6.1 Participant QR Route

### Threat: Guessing or enumerating session IDs

**Example**

```text
/e/REACT-2026-Q3
/e/REACT-2026-Q4
/e/REACT-2026-Q5
```

An attacker may guess session IDs and discover active participant forms.

**Impact**

```text
Low to Medium
```

Public forms are intentionally accessible, but guessable IDs can expose upcoming sessions or enable targeted spam.

**Mitigations**

```text
Use sufficiently specific session IDs.
Do not expose draft forms.
Require active session and published form checks.
Rate-limit feedback submissions.
Use unguessable suffixes for sensitive/private sessions if necessary.
```

**Recommended enhancement**

For sensitive sessions, use IDs such as:

```text
REACT-2026-Q3-K7M4P
```

rather than predictable sequential values.

---

### Threat: QR-code replacement

An attacker may replace a printed QR code with one pointing to a malicious website.

**Impact**

```text
Medium to High
```

Participants may be phished or directed to a fake form.

**Mitigations**

```text
Display typed fallback URL next to QR code.
Use HTTPS custom domain.
Use recognizable domain branding.
Train facilitators to verify QR materials.
Use tamper-resistant printed signage where possible.
```

---

## 6.2 Participant Submission API

### Threat: Malformed request payloads

An attacker may submit malformed JSON, unexpected fields, invalid UUIDs, huge text, or invalid data types.

**Mitigations**

```text
Zod request validation.
Maximum answer count.
Maximum text lengths.
UUID validation.
Session ID format validation.
Reject malformed JSON with HTTP 400.
```

---

### Threat: Tampered answer values

An attacker could change browser requests.

Example:

```json
{
  "questionId": "rating-question-id",
  "value": 999
}
```

**Mitigations**

```text
Load active published form from Neon.
Verify session is active.
Verify form version matches active published version.
Verify question belongs to that form version.
Validate rating range.
Validate NPS range.
Validate choice option membership.
Validate text length.
```

---

### Threat: Submitting answers for another form version

An attacker may submit a valid question ID from an older or unrelated form version.

**Mitigations**

```text
Require submitted formVersionId.
Compare submitted formVersionId with Session.activeFormVersionId.
Verify every submitted question belongs to submitted form version.
Reject stale form versions with HTTP 409.
```

---

### Threat: Duplicate submission

A participant may accidentally submit repeatedly, or an attacker may replay requests.

**Mitigations**

```text
Stable browser submission ID.
Unique Response.submissionEventId database constraint.
Idempotent Inngest persistence.
Rate limiting by session and client hash.
```

**Residual risk**

A participant using multiple devices, VPNs, or network addresses may still submit multiple responses.

---

### Threat: Denial of service through large submission volume

**Mitigations**

```text
Upstash Redis distributed rate limiting.
Per-client and per-session limits.
Request body size limits at hosting platform.
Maximum text and answer counts.
Inngest concurrency limits.
Monitoring and alerting.
```

**Recommended enhancement**

Configure edge or WAF-level rate limiting for public routes:

```text
/e/*
/api/feedback
```

---

## 6.3 Client IP Hashing and Privacy

### Threat: Raw IP address retention

Storing raw IP addresses may create privacy and compliance concerns.

**Mitigations**

```text
Use SHA-256 hash.
Include private secret.
Rotate salt daily using UTC date.
Store hash rather than original IP.
Exclude hash from admin dashboard, CSV, and PDF.
```

---

### Threat: Long-term participant tracking

Even hashed identifiers may become linkable if salt is static.

**Mitigations**

```text
Daily rotating salt.
Retention cleanup job.
Set clientIpHash to null after retention period.
Minimize stored metadata.
```

**Recommended retention policy**

| Data | Suggested Retention |
|---|---:|
| `clientIpHash` | 7–30 days |
| User agent metadata | 30–90 days |
| Feedback responses | 12–24 months, policy dependent |

---

### Threat: Proxy header spoofing

An attacker may manually send:

```http
X-Forwarded-For: 1.2.3.4
```

to evade IP-based rate limits.

**Mitigations**

```text
Deploy behind a trusted reverse proxy.
Ensure hosting platform overwrites or sanitizes forwarding headers.
Trust proxy headers only when platform behavior is known.
Use additional anti-abuse controls for high-risk public forms.
```

**Recommended enhancement**

Use provider-specific trusted headers or an edge-layer identity signal where available.

---

## 6.4 Administrator Authentication

### Threat: Shared administrator password compromise

The baseline application uses one password:

```text
ADMIN_PASSWORD
```

If compromised, anyone with it can access all admin functions.

**Impact**

```text
High
```

**Mitigations in baseline**

```text
Server-only environment variable.
Timing-safe comparison.
Signed HTTP-only session cookie.
Session expiration.
Secure cookie in production.
```

**Recommended production enhancement**

```text
Named administrator accounts.
Argon2id or bcrypt password hashes.
Multi-factor authentication.
Role-based access control.
Login rate limiting.
Password reset workflow.
Session revocation.
Audit logging.
```

---

### Threat: Brute-force login attempts

**Mitigations**

```text
Add rate limiting to /admin/login.
Use strong unique password.
Add CAPTCHA or challenge after repeated failures.
Monitor failed sign-in attempts.
Use MFA in production.
```

---

### Threat: Stolen admin session cookie

A compromised device or browser extension may steal or misuse an active session.

**Mitigations**

```text
HTTP-only cookie.
Secure cookie in production.
SameSite=Lax.
Session expiration.
Force sign-out by rotating ADMIN_SESSION_SECRET after incident.
Use MFA and named users in production.
```

---

### Threat: Cross-site request forgery against admin actions

An attacker may attempt to cause a signed-in administrator browser to perform actions unintentionally.

**Mitigations**

```text
SameSite=Lax cookies.
Next.js Server Action protections.
Authenticated route checks.
Avoid unsafe state-changing GET endpoints.
Use POST for report requests and form mutations.
```

**Recommended enhancement**

Add origin validation and CSRF tokens if introducing cross-origin admin workflows.

---

## 6.5 Form Authoring and Publishing

### Threat: Editing published questions

Changing a published question could corrupt historical analytics.

**Mitigations**

```text
Published forms are not editable.
Only drafts may be modified.
Publishing creates a new active version.
Responses store formVersionId.
Questions are cloned into new draft versions.
```

---

### Threat: Publishing an incomplete or invalid form

**Mitigations**

```text
Require at least one question.
Require at least two options for choice questions.
Validate rating min and max values.
Validate all authoring input with Zod.
Preview participant route before distribution.
```

---

### Threat: Concurrent publishing race condition

Two administrators may publish different drafts nearly simultaneously.

**Mitigations**

```text
Use serializable database transaction.
Archive old published version.
Publish selected draft.
Update activeFormVersionId atomically.
```

**Recommended enhancement**

Add optimistic locking or draft `updatedAt` conflict detection in multi-user version.

---

## 6.6 Inngest Background Jobs

### Threat: Event replay creates duplicate responses

**Mitigations**

```text
Stable submission ID.
Unique response submission event ID.
Idempotent save service.
Duplicate detection before insert.
Duplicate unique-constraint handling after race.
```

---

### Threat: Forged Inngest callback

An attacker may attempt to call:

```text
/api/inngest
```

directly.

**Mitigations**

```text
Use INNGEST_SIGNING_KEY in production.
Use official Inngest Next.js integration.
Do not expose custom unauthenticated worker endpoints.
Monitor unexpected invocation behavior.
```

---

### Threat: Background queue overload

High-volume event traffic may create a backlog.

**Mitigations**

```text
Set feedback worker concurrency.
Set lower PDF worker concurrency.
Use Inngest retry controls.
Monitor queue depth.
Alert on sustained backlog.
Scale platform plan where required.
```

---

### Threat: PDF generation resource exhaustion

A report with thousands of comments may cause memory or timeout issues.

**Mitigations**

```text
Limit comments included in PDF.
Include aggregate metrics for all data.
Provide CSV for complete raw export.
Limit PDF generation concurrency.
Use report status and failure handling.
```

---

## 6.7 Neon PostgreSQL and Prisma

### Threat: Database credential exposure

**Mitigations**

```text
Store DATABASE_URL and DIRECT_URL only in server environment.
Never use NEXT_PUBLIC_DATABASE_URL.
Keep .env out of Git.
Rotate credentials after exposure.
Use separate development, staging, and production databases or branches.
```

---

### Threat: Destructive migration or accidental data deletion

**Mitigations**

```text
Use Prisma migration files in source control.
Test migrations on Neon branch.
Use prisma migrate deploy in production.
Do not use prisma migrate reset in production.
Maintain backup and restore process.
Restrict destructive operations.
```

---

### Threat: Unauthorized direct database access

**Mitigations**

```text
Restrict Neon project access.
Use least-privilege database roles where feasible.
Use separate credentials per environment.
Rotate credentials.
Review access logs and users.
```

---

## 6.8 CSV Export

### Threat: Unauthorized export of participant data

**Mitigations**

```text
Require administrator authentication.
Use no-store response cache header.
Do not expose export route publicly.
Add organization-level authorization in multi-tenant version.
Log export actions in audit log.
```

---

### Threat: Spreadsheet formula injection

A participant may submit:

```text
=HYPERLINK("https://malicious.example")
```

**Mitigations**

```text
Prefix values starting with =, +, -, or @ using apostrophe.
Quote CSV values.
Escape embedded quotation marks.
```

---

### Threat: Excessive export size

A very large session may create expensive memory use.

**Mitigations**

```text
Use streaming CSV output for large datasets.
Add pagination or background export job.
Limit export access.
Use rate limiting for export route.
```

---

## 6.9 PDF Reports and Object Storage

### Threat: Public report URL exposes sensitive feedback

**Impact**

```text
High
```

**Baseline risk**

A direct public object URL can expose PDF content if guessed or shared.

**Required production mitigation**

```text
Store reports in private bucket.
Do not use publicly readable object URLs.
Create authenticated report download endpoint.
Generate short-lived signed URL.
Log report downloads.
```

---

### Threat: Object storage credential misuse

**Mitigations**

```text
Use least-privilege storage credentials.
Restrict write access to report prefix only.
Use separate production and staging buckets.
Rotate storage credentials.
Enable object versioning where appropriate.
```

---

### Threat: PDF content injection

Participant comments may contain malicious-looking text.

**Mitigations**

```text
Render comments as text only.
Do not render participant HTML.
Limit comment length.
Avoid embedding remote participant-provided URLs or images.
```

---

## 6.10 Browser Storage and Offline Outbox

### Threat: Local drafts visible to another user of same device

Drafts are stored in localStorage.

**Impact**

```text
Medium
```

**Mitigations**

```text
Do not store credentials in localStorage.
Do not store raw IP or admin tokens.
Provide Discard Draft action.
Document that drafts are device/browser-local.
Clear drafts after accepted submission.
```

**Residual risk**

Anyone with access to the same unlocked browser profile may inspect local draft data.

---

### Threat: Offline outbox repeatedly retries stale submission

A form may change while an offline submission waits.

**Mitigations**

```text
Server validates active formVersionId.
Server returns HTTP 409 for stale form.
Outbox retains failed item for participant review.
Do not silently attach old answers to new form version.
```

---

# 7. STRIDE Summary

| Category | Example Threat | Primary Mitigation |
|---|---|---|
| Spoofing | Forged admin session | Signed HTTP-only cookie, secret rotation, MFA future |
| Spoofing | Forged Inngest callback | Inngest signing key |
| Tampering | Modified answer values | Server-side form and question validation |
| Tampering | Published form modification | Immutable published versions |
| Repudiation | Admin denies export or publish action | Audit logs in production enhancement |
| Information disclosure | Public report URL | Private storage and signed downloads |
| Information disclosure | Raw IP exposure | Daily salted hash and export exclusion |
| Denial of service | Submission spam | Upstash Redis, limits, WAF, Inngest concurrency |
| Elevation of privilege | Shared admin password compromise | Named users, RBAC, MFA future |

---

# 8. Required Security Controls

## Baseline Controls

```text
Zod request validation
Server-side answer validation
Session active validation
Form version validation
Question ownership validation
Daily salted IP hashing
Upstash Redis rate limiting in production
HTTP-only signed admin cookie
Admin route authentication
Inngest signed endpoint
Unique submission event ID
Prisma database constraints
Escaped participant text rendering
CSV formula injection protection
No-store headers for sensitive exports
```

## Production Hardening Controls

```text
Named administrator accounts
Password hashing using Argon2id or bcrypt
MFA for administrators
Role-based authorization
Audit logs
Private PDF storage
Signed report download URLs
WAF or edge rate limiting
Security headers
CSP where compatible
Automated dependency scanning
Sentry or equivalent error monitoring
Scheduled data-retention cleanup
Backup and restore drills
```

---

# 9. Security Test Cases

| Test ID | Test | Expected Result |
|---|---|---|
| SEC-001 | Submit malformed JSON to `/api/feedback` | HTTP 400 |
| SEC-002 | Submit invalid UUIDs | HTTP 400 |
| SEC-003 | Submit rating outside allowed range | HTTP 400 |
| SEC-004 | Submit invalid choice option | HTTP 400 |
| SEC-005 | Submit to closed session | HTTP 409 |
| SEC-006 | Submit stale form version | HTTP 409 |
| SEC-007 | Submit same submission ID twice | One stored response only |
| SEC-008 | Submit repeatedly from same identity | HTTP 429 after limit |
| SEC-009 | Access admin route without cookie | Redirect to login |
| SEC-010 | Access CSV export without cookie | HTTP 401 |
| SEC-011 | Attempt direct report URL access in production | Denied unless authorized |
| SEC-012 | Export text beginning with `=SUM(...)` | CSV value prefixed as text |
| SEC-013 | Submit HTML comment | Rendered as text, not executable HTML |
| SEC-014 | Replay Inngest event | No duplicate response or answers |
| SEC-015 | Change published question through UI | Operation unavailable or rejected |

---

# 10. Residual Risks

Some risks remain even after mitigations.

| Residual Risk | Explanation |
|---|---|
| Anonymous duplicate responses across devices | A participant can use several devices or network paths |
| QR-code physical tampering | Printed materials can be replaced outside application control |
| Sensitive content in written feedback | Participants may voluntarily enter names or confidential information |
| Shared-device localStorage exposure | Drafts may be visible to another user of same browser profile |
| Administrator misuse | Legitimate access can still be misused without roles and audit logs |
| Third-party outage | Neon, Inngest, Redis, storage, or hosting can fail |
| High-volume coordinated abuse | Rate limits reduce but do not eliminate DDoS risk |
| Screenshot or downloaded report sharing | Authorized users may redistribute reports outside system control |

---

# 11. Security Review Checklist

```text
[ ] No secrets use NEXT_PUBLIC_ prefix.
[ ] .env is excluded from Git.
[ ] Production reports use private storage.
[ ] Signed downloads are used for reports.
[ ] Upstash Redis is configured in production.
[ ] INNGEST_DEV is disabled in production.
[ ] Admin login is rate-limited.
[ ] Published form versions are immutable.
[ ] Submission IDs are unique and idempotent.
[ ] Raw IP addresses are not stored.
[ ] CSV exports neutralize spreadsheet formulas.
[ ] Written comments are rendered as escaped text.
[ ] Dependencies are scanned and updated.
[ ] Monitoring alerts exist for API and worker failures.
[ ] Backups and recovery procedures are tested.
[ ] Multi-user authorization and audit logging are planned before broad organizational rollout.
```

---

# 12. Final Threat Model Statement

GreyMatter Feedback is designed around a public, anonymous participant interface and a protected administrator interface.

The central security model is:

```text
Public input is untrusted.
        ↓
Server validates structure and business rules.
        ↓
Rate limiting reduces abuse.
        ↓
Inngest provides retryable background processing.
        ↓
Database constraints preserve integrity.
        ↓
Form versioning preserves historical truth.
        ↓
Protected admin access controls authoring and reporting.
```

The highest-priority production improvements are:

```text
Private report storage
Signed report downloads
Named admin accounts
Password hashing
MFA
Role-based authorization
Audit logs
Admin login rate limiting
WAF or edge-layer protection
Scheduled privacy cleanup
```
