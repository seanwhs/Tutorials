# Appendix D: Security, Privacy, and Data Retention

GreyMatter Feedback is designed to collect honest feedback while minimizing unnecessary collection of participant data.

This appendix explains the application’s security model, privacy decisions, data risks, and recommended production improvements.

> This appendix is technical guidance, not legal advice. Organizations should obtain legal and privacy guidance appropriate to their country, industry, participants, and data-handling obligations.

---

## D.1 What GreyMatter Feedback stores

GreyMatter Feedback stores structured feedback data in Neon PostgreSQL.

The core records are:

```text
Event
Session
FormVersion
Question
Response
Answer
Report
```

A simplified representation looks like this:

```text
Response
├── id
├── eventId
├── sessionId
├── formVersionId
├── submittedAt
├── clientIpHash
├── metadata
└── answers[]
```

Each answer stores either:

```text
numericValue
```

for rating and NPS answers, or:

```text
textValue
```

for text and choice answers.

---

## D.2 What GreyMatter Feedback does not intentionally collect

The baseline participant feedback flow does **not** require:

- Participant accounts.
- Participant names.
- Email addresses.
- Phone numbers.
- Raw IP addresses.
- GPS location.
- Camera images.
- Device identifiers.
- Browser cookies for participant identity.

This supports low-friction and more candid feedback.

However, written feedback can still contain personal information if a participant chooses to include it.

For example:

```text
“My manager, Jordan Smith, should explain the process more clearly.”
```

The system cannot guarantee that free-text fields contain no personal data. Organizations should communicate that participants should avoid sharing sensitive or personally identifying information unless it is necessary.

---

## D.3 IP hashing model

GreyMatter Feedback uses IP hashing for rate limiting and abuse resistance.

The process is:

```text
Client IP address
        +
Daily rotating salt
        +
Server secret
        ↓
SHA-256 hash
        ↓
64-character hexadecimal identifier
```

The code conceptually performs:

```ts
createHash("sha256")
  .update(`${dailySalt}:${ipAddress}`)
  .digest("hex");
```

The stored value is not the raw IP address.

Example:

```text
Raw IP:
203.0.113.25

Stored hash:
8e785da3b7105e13a10e99a0f51d1979...
```

The same IP address should produce the same hash on the same UTC day, but a different hash on the next day because the daily salt changes.

```text
2026-07-25:
hash(IP + secret + 2026-07-25)

2026-07-26:
hash(IP + secret + 2026-07-26)
```

This limits the ability to track a participant across days.

---

## D.4 Important limitation of IP hashes

A hashed IP address is safer than storing a raw IP address, but it may still be treated as personal data under some privacy laws.

Why?

Because the system can still use it to distinguish repeated activity during a limited period.

Treat `clientIpHash` carefully:

```text
[ ] Do not expose it in the admin dashboard.
[ ] Do not include it in standard CSV exports.
[ ] Do not include it in PDF reports.
[ ] Do not use it for participant profiling.
[ ] Delete or anonymize old data according to retention policy.
```

The CSV export built in the tutorial intentionally excludes:

```text
clientIpHash
metadata.userAgent
```

Administrators receive response data, not low-level anti-abuse identifiers.

---

## D.5 Request metadata

The feedback API stores limited metadata:

```ts
metadata: {
  source?: string;
  screenWidth?: number;
  screenHeight?: number;
  userAgent: string;
}
```

Example:

```json
{
  "source": "qr",
  "screenWidth": 390,
  "screenHeight": 844,
  "userAgent": "Mozilla/5.0 ..."
}
```

This can help diagnose usability issues, such as whether a form is heavily used on phones.

However, user-agent values can be detailed and occasionally identifying when combined with other data.

Recommended policy:

```text
Use metadata only for technical support and aggregate device analysis.
Do not show raw user-agent strings to normal administrators.
Do not include raw user-agent strings in CSV exports.
Retain metadata for a shorter period than feedback responses if possible.
```

---

## D.6 Administrator authentication model

The tutorial uses a single administrator password:

```dotenv
ADMIN_PASSWORD="..."
```

When a user signs in, GreyMatter Feedback creates a signed session token and stores it in an HTTP-only cookie:

```text
greymatter_admin_session
```

Cookie protections include:

```text
httpOnly = true
sameSite = "lax"
secure = true in production
path = "/"
```

### Why HTTP-only matters

An HTTP-only cookie cannot be read by browser JavaScript.

This helps reduce exposure if an attacker successfully injects malicious browser-side code through an unrelated vulnerability.

### Why signed tokens matter

The session token contains a payload and cryptographic signature:

```text
base64url(payload).signature
```

The server verifies the signature using:

```dotenv
ADMIN_SESSION_SECRET="..."
```

A modified or forged token fails verification.

---

## D.7 Limitations of the tutorial authentication system

The single-password authentication approach is appropriate for:

- Local development.
- Small internal deployments.
- Early prototypes.
- Single-operator feedback systems.

It is not sufficient for a larger organization.

A production multi-user administration system should add:

```text
Administrator user accounts
Password hashes, never plaintext passwords
Password reset workflow
Email verification
Role-based authorization
Audit logs
Multi-factor authentication
Session revocation
Login rate limiting
Account lockout or challenge controls
```

A stronger schema could include:

```text
AdminUser
├── id
├── email
├── passwordHash
├── role
├── createdAt
├── lastLoginAt
└── isActive

AdminAuditLog
├── id
├── adminUserId
├── action
├── targetType
├── targetId
├── createdAt
└── metadata
```

Roles might include:

```text
OWNER
ADMIN
FORM_EDITOR
ANALYST
READ_ONLY
```

---

## D.8 Participant submission protections

The participant submission pipeline includes several layers.

```text
Participant browser
        ↓
Client-side required-field validation
        ↓
POST /api/feedback
        ↓
Zod request-shape validation
        ↓
Daily salted IP hash
        ↓
Rate-limit check
        ↓
Session active check
        ↓
Published form version check
        ↓
Question ownership check
        ↓
Question-type validation
        ↓
Inngest event
        ↓
Idempotent Neon persistence
```

Each layer serves a different purpose.

| Protection | Why it exists |
|---|---|
| Browser validation | Better participant experience |
| Zod request validation | Reject malformed API payloads |
| Published version check | Prevent submissions to drafts or stale forms |
| Question ownership check | Prevent answers being attached to unrelated questions |
| Rating/NPS range checks | Prevent invalid numeric values |
| Choice option validation | Prevent unsupported option values |
| Text length limits | Prevent oversized payloads |
| Rate limiting | Reduce spam and repeated submissions |
| Stable submission ID | Prevent duplicate records during retries |
| Unique database constraint | Final duplicate-prevention safety net |

---

## D.9 Rate limiting recommendations

The tutorial uses these defaults:

```text
Per client and session:
1 submission every 5 minutes

Per session:
500 submissions per hour
```

These values are intentionally conservative examples.

Different deployments need different settings.

### Small workshop

```text
Expected participants: 20
Recommended per-session limit: 100/hour
Recommended per-client limit: 1/10 minutes
```

### Large conference keynote

```text
Expected participants: 1,000
Recommended per-session limit: 2,000/hour
Recommended per-client limit: 1/5 minutes
```

### Public survey linked from social media

```text
Expected participants: Unknown
Recommended protections:
- Stronger rate limiting
- CAPTCHA or challenge system
- Session expiration
- Abuse monitoring
- Optional email verification
```

For production, use Upstash Redis:

```dotenv
UPSTASH_REDIS_REST_URL="https://..."
UPSTASH_REDIS_REST_TOKEN="..."
```

Do not rely on the in-memory local-development fallback in production.

---

## D.10 Cross-site request concerns

The participant feedback endpoint is:

```text
POST /api/feedback
```

The application accepts anonymous public submissions, so it cannot rely on an authenticated browser session for CSRF protection.

The primary protections are:

```text
Strict schema validation
Rate limiting
Session and form version checks
Question ownership validation
Text-length limits
No browser credentials required
```

For deployments with elevated abuse risk, consider adding an origin check.

Example concept:

```ts
const origin = request.headers.get("origin");

if (origin && origin !== env.NEXT_PUBLIC_APP_URL) {
  return NextResponse.json(
    { error: "Unexpected request origin." },
    { status: 403 },
  );
}
```

Be careful: QR flows may open in embedded browsers, preview tools, or environments where `Origin` is absent. An origin check should be tested thoroughly before enforcement.

---

## D.11 Content safety and written feedback

Text answers are untrusted user input.

GreyMatter Feedback renders comments as text:

```tsx
<p className="whitespace-pre-wrap leading-7">
  “{comment.value}”
</p>
```

React escapes string values by default. This helps prevent a participant from submitting HTML such as:

```html
<script>alert("unsafe")</script>
```

from being executed in the administrator browser.

Do not replace safe text rendering with unsafe HTML rendering such as:

```tsx
dangerouslySetInnerHTML
```

unless you add a well-maintained HTML sanitizer and have a specific business need for rich text.

Recommended rules:

```text
[ ] Store participant comments as plain text.
[ ] Render comments as escaped text.
[ ] Do not allow HTML in feedback fields.
[ ] Keep text-length limits.
[ ] Add content moderation if public comments are exposed externally.
```

---

## D.12 CSV export security

The CSV export endpoint requires administrator authentication:

```text
GET /api/admin/export/[sessionId]
```

The tutorial escapes CSV values by:

1. Wrapping every value in quotes.
2. Replacing embedded quotes with doubled quotes.

Example:

```text
Original:
She said "great workshop"

CSV:
"She said ""great workshop"""
```

### Spreadsheet formula injection

CSV files can create another risk: spreadsheet formula injection.

A participant could submit text beginning with:

```text
=SUM(A1:A10)
```

or:

```text
=HYPERLINK(...)
```

When opened in spreadsheet software, some formulas may be interpreted.

For stronger protection, update the export helper to prefix formula-like text values with a single quote.

Example:

```ts
function protectSpreadsheetFormula(value: string): string {
  return /^[=+\-@]/.test(value) ? `'${value}` : value;
}
```

Then apply it before CSV escaping:

```ts
function escapeCsvValue(value: string | number | null | undefined): string {
  const normalizedValue =
    value === null || value === undefined
      ? ""
      : protectSpreadsheetFormula(String(value));

  return `"${normalizedValue.replaceAll('"', '""')}"`;
}
```

This is recommended before using exports in production.

---

## D.13 PDF report security

PDF reports may contain:

- Session names.
- Response counts.
- NPS data.
- Written participant feedback.

For this reason, reports should be treated as potentially sensitive.

The local development implementation stores files under:

```text
public/reports
```

This is convenient locally but should not be used for confidential production reports.

### Production recommendation

Use private object storage and a protected download endpoint:

```text
GET /api/admin/reports/[reportId]/download
```

The route should:

1. Verify administrator authentication.
2. Find the report record in Neon.
3. Confirm the report is complete.
4. Generate a short-lived signed URL.
5. Redirect the authenticated administrator.

The flow becomes:

```text
Admin browser
        ↓
Authenticated report download endpoint
        ↓
Temporary signed object-storage URL
        ↓
Private PDF download
```

Avoid publicly guessable URLs for reports that include written feedback.

---

## D.14 Secrets management

GreyMatter Feedback relies on several secret values.

| Variable | Purpose |
|---|---|
| `DATABASE_URL` | Neon pooled database connection |
| `DIRECT_URL` | Neon direct migration connection |
| `IP_HASH_SECRET` | Daily privacy-preserving IP hashes |
| `ADMIN_SESSION_SECRET` | Admin session signatures |
| `ADMIN_PASSWORD` | Tutorial administrator password |
| `INNGEST_EVENT_KEY` | Send production Inngest events |
| `INNGEST_SIGNING_KEY` | Verify Inngest requests |
| `UPSTASH_REDIS_REST_TOKEN` | Connect to distributed rate limiting |
| `S3_SECRET_ACCESS_KEY` | Upload private reports |

Rules for secrets:

```text
[ ] Do not commit .env files.
[ ] Do not paste secrets into tickets or chat logs.
[ ] Do not expose secrets through NEXT_PUBLIC_* variables.
[ ] Rotate secrets after suspected exposure.
[ ] Use separate secrets for development, staging, and production.
[ ] Restrict cloud credential permissions to the minimum necessary.
```

Only values intended for browser code should use the `NEXT_PUBLIC_` prefix.

For example:

```dotenv
NEXT_PUBLIC_APP_URL="https://feedback.example.com"
```

is safe to expose.

This is not:

```dotenv
NEXT_PUBLIC_DATABASE_URL="..."
```

Database URLs must never use a public environment prefix.

---

## D.15 Data retention policy

GreyMatter Feedback should have a documented retention policy before production use.

A basic policy might look like this:

| Data | Example retention period | Reason |
|---|---:|---|
| Raw feedback responses | 12–24 months | Supports historical reporting |
| Written comments | 12–24 months | Supports qualitative review |
| IP hashes | 7–30 days | Abuse prevention only |
| User-agent metadata | 30–90 days | Technical troubleshooting |
| Generated reports | 12 months | Administrative archive |
| Drafts in participant browser | Until submission or manual discard | Participant-controlled local storage |

The exact periods depend on organizational requirements.

### Important observation

The tutorial schema stores `clientIpHash` in the same `Response` record as long-term feedback data.

For a stronger privacy model, add an expiration process.

For example:

```text
Daily scheduled job
        ↓
Find responses older than 30 days
        ↓
Set clientIpHash = null
        ↓
Remove or minimize metadata
```

A future Inngest scheduled function could handle this:

```text
cron: "0 3 * * *"
```

Example cleanup concept:

```ts
await prisma.response.updateMany({
  where: {
    submittedAt: {
      lt: cutoffDate,
    },
  },
  data: {
    clientIpHash: null,
    metadata: {},
  },
});
```

This preserves feedback answers while removing anti-abuse identifiers after they are no longer needed.

---

## D.16 Deletion requests

Organizations may need to delete feedback data because of:

- Legal obligations.
- Participant requests.
- Event cancellation.
- Internal retention rules.
- Accidental collection of sensitive information.

Because GreyMatter Feedback is anonymous by default, locating one person’s response may not be possible or appropriate.

However, administrators can support deletion at the session level:

```text
Delete session
        ↓
Cascade delete form versions
        ↓
Cascade delete questions
        ↓
Cascade delete responses
        ↓
Cascade delete answers
        ↓
Cascade delete report records
```

Before implementing deletion controls, decide:

```text
Should reports also be deleted from object storage?
Should deleted data be recoverable for a short period?
Who is allowed to delete a session?
Should deletion require a second confirmation?
Should deletion be recorded in an audit log?
```

For production, session deletion should be restricted to high-privilege administrator roles.

---

## D.17 Logging guidance

Logs are helpful for diagnosing failures, but logs can accidentally expose sensitive data.

Safe log example:

```ts
console.info("Feedback submission processed.", {
  submissionId: event.data.submissionId,
  responseId: saveResult.responseId,
  sessionId: event.data.sessionId,
  duplicate: saveResult.duplicate,
});
```

Avoid logging:

```text
Raw participant answers
Text comments
Raw IP addresses
Database URLs
Session secrets
Admin passwords
Full request headers
```

For errors, log enough context to debug while excluding participant content:

```ts
console.error("Feedback validation failed.", {
  sessionId,
  formVersionId,
  reason: "unknown-question",
});
```

---

## D.18 Security incident response basics

If you suspect a secret has been exposed:

```text
1. Rotate the exposed secret immediately.
2. Redeploy the application with the new value.
3. Invalidate active administrator sessions if ADMIN_SESSION_SECRET changed.
4. Review deployment and provider logs.
5. Review repository history and remove exposed files.
6. Notify affected stakeholders according to organizational policy.
```

If `ADMIN_SESSION_SECRET` changes:

```text
Existing admin cookies become invalid.
Administrators must sign in again.
```

If `IP_HASH_SECRET` changes:

```text
Rate-limit identities change.
Historical hashes cannot be compared to new hashes.
```

That is generally acceptable because the hash exists only for short-lived abuse prevention.

---

## D.19 Recommended production hardening roadmap

After completing the tutorial, prioritize these improvements.

### High priority

```text
[ ] Multi-user administrator accounts.
[ ] Password hashing with Argon2id or bcrypt.
[ ] Multi-factor authentication for administrators.
[ ] Upstash Redis rate limiting.
[ ] Private report storage.
[ ] Signed report download URLs.
[ ] Audit logs for publishing, export, and deletion.
[ ] Error monitoring.
[ ] Security headers.
[ ] Data retention cleanup jobs.
```

### Medium priority

```text
[ ] CAPTCHA or challenge system for high-risk public forms.
[ ] Administrator role-based permissions.
[ ] Email notifications when reports finish.
[ ] Automated database backups and restore tests.
[ ] Sentry or equivalent monitoring.
[ ] Content moderation workflow for public feedback.
[ ] Staging environment with separate Neon branch.
```

### Situational priority

```text
[ ] SSO integration.
[ ] Organization-level tenancy.
[ ] Encryption key management.
[ ] Regional data residency.
[ ] Accessibility audit.
[ ] Penetration testing.
[ ] Formal privacy impact assessment.
```

---

## D.20 Final privacy-by-design checklist

Use this checklist before accepting live feedback.

```text
[ ] The form asks only questions needed for a clear purpose.
[ ] Participants are not required to create accounts.
[ ] Raw IP addresses are not stored.
[ ] IP hashes are retained only as long as necessary.
[ ] Participant comments are rendered as escaped text.
[ ] Feedback exports exclude anti-abuse identifiers.
[ ] Admin routes require authentication.
[ ] Report downloads are protected.
[ ] Database and storage credentials are private.
[ ] Production rate limiting uses shared infrastructure.
[ ] Published forms use immutable versions.
[ ] Data retention and deletion procedures are documented.
[ ] Incident response responsibilities are assigned.
```
