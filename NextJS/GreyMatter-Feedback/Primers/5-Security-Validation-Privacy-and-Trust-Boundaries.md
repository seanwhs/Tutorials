# Primer 5: Security, Validation, Privacy, and Trust Boundaries

GreyMatter Feedback collects information from people outside the administrator system.

A participant can:

- Open a public QR-code URL.
- Use any browser.
- Modify requests with browser developer tools.
- Send requests through scripts.
- Retry requests.
- Submit unexpected values.

This means the application must never assume that browser-provided data is safe.

This primer explains the security principles used throughout GreyMatter Feedback.

---

## 1. Trust Boundaries

A **trust boundary** is the point where data moves from a less trusted place to a more trusted place.

In GreyMatter Feedback, the browser is outside the trust boundary.

```text
Participant browser
        ↓
Trust boundary
        ↓
GreyMatter server
        ↓
Neon database
```

The browser can provide useful input, but the server must verify it.

For example, a participant browser might claim:

```json
{
  "questionId": "some-question-id",
  "value": 999
}
```

The server must determine:

```text
Does this question exist?
Does it belong to this form version?
Is this form version published?
Is this question a rating question?
Is 999 inside its allowed rating range?
```

The browser cannot make those decisions safely by itself.

---

## 2. Client-Side Validation vs Server-Side Validation

GreyMatter Feedback uses validation in two places.

## Client-side validation

Client-side validation runs in the browser.

Examples:

```text
Show required-question error.
Count text characters.
Prevent obvious incomplete submission.
Scroll to first missing answer.
```

This improves participant experience.

Example:

```tsx
if (question.isRequired && !isAnswered(answers[question.id])) {
  nextErrors[question.id] = "This question requires an answer.";
}
```

However, client-side validation is not security.

A participant can bypass it by:

```text
Using browser developer tools.
Sending requests manually.
Writing a script.
Calling the API directly.
```

## Server-side validation

Server-side validation runs in the Next.js API route.

Examples:

```text
Validate JSON structure.
Validate session ID.
Validate form version ID.
Confirm session is active.
Confirm form is published.
Confirm question ownership.
Validate rating range.
Validate NPS range.
Validate choice options.
Validate text length.
```

The server is authoritative.

A useful rule is:

```text
Client validation improves usability.
Server validation protects correctness and security.
```

---

## 3. Zod Validation

GreyMatter Feedback uses **Zod** to validate untrusted input.

Zod defines a schema: a precise description of acceptable data.

Example participant submission schema:

```ts
import { z } from "zod";

const answerSchema = z.object({
  questionId: z.string().uuid(),
  value: z.union([
    z.number().int(),
    z.string().trim().max(5000),
  ]),
});

export const feedbackSubmissionSchema = z.object({
  submissionId: z.string().uuid(),
  sessionId: z
    .string()
    .trim()
    .min(3)
    .max(64)
    .regex(/^[A-Za-z0-9-]+$/),
  formVersionId: z.string().uuid(),
  answers: z.array(answerSchema).min(1).max(100),
});
```

This prevents malformed request shapes such as:

```json
{
  "sessionId": ["not", "a", "string"]
}
```

or:

```json
{
  "submissionId": "not-a-uuid"
}
```

or:

```json
{
  "answers": "not-an-array"
}
```

---

## 4. Validate Against the Database Too

Zod validates the request’s structure. It does not know whether the submitted values match the real published form.

For that, GreyMatter Feedback queries Neon.

Example validation flow:

```text
Request says:
sessionId = REACT-2026-Q3
formVersionId = abc-123
questionId = def-456
value = 5

Server checks:
1. Does session REACT-2026-Q3 exist?
2. Is it active?
3. Does it have active form version abc-123?
4. Is abc-123 published?
5. Does question def-456 belong to abc-123?
6. Is question def-456 a rating question?
7. Is 5 allowed by its configured range?
```

This is necessary because a client could otherwise submit an answer to any known question ID.

---

## 5. Validate Question Types

Each question type expects a different kind of answer.

| Question type | Valid answer |
|---|---|
| `RATING` | Integer inside configured scale |
| `NPS` | Integer from 0 through 10 |
| `CHOICE` | One configured option string |
| `TEXT` | String within configured maximum length |

Example rating validation:

```ts
if (
  submittedValue < settings.min ||
  submittedValue > settings.max
) {
  return {
    success: false,
    status: 400,
    message: `Question requires a score between ${settings.min} and ${settings.max}.`,
  };
}
```

Example choice validation:

```ts
if (!options.includes(normalizedValue)) {
  return {
    success: false,
    status: 400,
    message: "Question contains an invalid option.",
  };
}
```

This prevents a client from submitting:

```text
Choice question options:
- Presentation
- Exercises
- Discussion

Invalid submitted answer:
Pizza
```

---

## 6. Public Participant Forms and Private Admin Areas

GreyMatter Feedback has two security models.

## Participant routes are public

Participants can access:

```text
/e/[sessionId]
POST /api/feedback
```

They do not need administrator accounts.

The system protects these routes with:

```text
Input validation
Rate limiting
Session state checks
Form-version checks
Question ownership checks
Idempotent submission IDs
```

## Administrator routes are protected

Administrators access:

```text
/admin/events
/admin/sessions/[sessionId]/edit
/admin/sessions/[sessionId]
/api/admin/export/[sessionId]
/api/admin/reports/[sessionId]
```

These routes require an authenticated administrator session.

The baseline tutorial uses a signed HTTP-only cookie.

---

## 7. HTTP-Only Cookies

An HTTP-only cookie is a browser cookie that JavaScript cannot read.

GreyMatter Feedback stores the administrator session in:

```text
greymatter_admin_session
```

The cookie is configured with protections such as:

```ts
cookieStore.set({
  name: "greymatter_admin_session",
  value: token,
  httpOnly: true,
  sameSite: "lax",
  secure: process.env.NODE_ENV === "production",
  path: "/",
});
```

| Setting | Meaning |
|---|---|
| `httpOnly: true` | Browser JavaScript cannot read cookie value |
| `sameSite: "lax"` | Helps reduce cross-site request risks |
| `secure: true` in production | Cookie travels only over HTTPS |
| `path: "/"` | Cookie applies across the application |

The server verifies the cookie before serving admin pages or protected APIs.

---

## 8. Why Administrator Passwords Must Stay Server-Side

The administrator password belongs in:

```dotenv
ADMIN_PASSWORD="strong-private-password"
```

It must never appear in:

```text
Client Component code.
NEXT_PUBLIC_* variables.
Browser network responses.
Git commits.
Screenshots.
Logs.
```

This is unsafe:

```ts
const password = process.env.NEXT_PUBLIC_ADMIN_PASSWORD;
```

Anything prefixed with:

```text
NEXT_PUBLIC_
```

is intentionally available to browser code.

Only public values should use that prefix.

Safe example:

```dotenv
NEXT_PUBLIC_APP_URL="https://feedback.example.com"
```

Unsafe example:

```dotenv
NEXT_PUBLIC_DATABASE_URL="postgresql://..."
```

---

## 9. Raw IP Addresses and Privacy

Participant IP addresses can be personal data.

GreyMatter Feedback does not store raw IP addresses.

Instead, it creates a daily salted SHA-256 hash.

```text
Raw client IP
        +
Private server secret
        +
Current UTC date
        ↓
SHA-256 hash
        ↓
Stored clientIpHash
```

Conceptually:

```ts
createHash("sha256")
  .update(`${dailySalt}:${ipAddress}`)
  .digest("hex");
```

The stored value looks like:

```text
8e785da3b7105e13a10e99a0f51d1979...
```

This value helps rate limiting work without storing the original IP address.

---

## 10. Why the Salt Changes Daily

If GreyMatter Feedback used the same secret forever:

```text
Same IP
        ↓
Same hash forever
```

That could make long-term tracking easier.

Instead, the date is included:

```text
2026-07-25 + IP → Hash A
2026-07-26 + IP → Hash B
```

The application can still identify repeated requests on the same day, but it cannot use the same stored value for straightforward cross-day tracking.

---

## 11. Rate Limiting

Rate limiting controls how frequently a client can submit requests.

GreyMatter Feedback checks two limits.

```text
Per client and session:
One submission every five minutes

Per session:
Up to 500 submissions per hour
```

The client-specific rate-limit key resembles:

```text
feedback:client:session:REACT-2026-Q3:client:<hashed-ip>
```

The session-wide key resembles:

```text
feedback:session:REACT-2026-Q3
```

The purpose is not to punish normal participants. It is to reduce:

```text
Accidental repeated submissions
Simple automated spam
Rapid manual abuse
Unexpected event bursts
```

---

## 12. Why Production Uses Upstash Redis

In local development, rate-limit counters can live in memory.

```text
Local Next.js server
  └── Temporary in-memory counter
```

But production may run several server instances:

```text
Server instance A
Server instance B
Server instance C
```

If each instance has separate memory, a client could bypass limits simply by reaching a different instance.

Upstash Redis provides a shared counter store:

```text
All server instances
        ↓
Shared Upstash Redis rate-limit data
```

That is why production should configure:

```dotenv
UPSTASH_REDIS_REST_URL="https://..."
UPSTASH_REDIS_REST_TOKEN="..."
```

---

## 13. Input Length Limits

Length limits protect both user experience and system resources.

Examples in GreyMatter Feedback:

| Input | Example maximum |
|---|---:|
| Session ID | 64 characters |
| Event title | 255 characters |
| Question text | 2,000 characters |
| Choice option | 250 characters |
| Text feedback | 5,000 characters |
| User agent metadata | 500 characters |
| Submission answers | 100 answers |

Without limits, a malicious client could attempt to send:

```text
Several megabytes of text
Thousands of answers
Very long metadata headers
```

Limits reduce storage abuse and help keep PDF and CSV exports manageable.

---

## 14. Rendering Written Feedback Safely

Written feedback is untrusted participant input.

A participant might submit text that resembles HTML:

```html
<script>alert("unsafe")</script>
```

GreyMatter Feedback renders comments as normal React text:

```tsx
<p className="whitespace-pre-wrap leading-7">
  “{comment.value}”
</p>
```

React escapes text values by default.

That means the browser displays the characters rather than executing them.

Avoid this unless you have a strong reason and an HTML sanitizer:

```tsx
dangerouslySetInnerHTML
```

For participant comments, plain text is the safest default.

---

## 15. CSV Formula Injection

CSV exports may be opened in spreadsheet software.

A participant could submit text beginning with:

```text
=SUM(A1:A10)
```

Some spreadsheet programs may interpret it as a formula.

GreyMatter Feedback should protect formula-like text before exporting.

Example:

```ts
function protectSpreadsheetFormula(value: string): string {
  return /^[=+\-@]/.test(value) ? `'${value}` : value;
}
```

Then escape the value for CSV:

```ts
function escapeCsvValue(
  value: string | number | null | undefined,
): string {
  const normalizedValue =
    value === null || value === undefined
      ? ""
      : protectSpreadsheetFormula(String(value));

  return `"${normalizedValue.replaceAll('"', '""')}"`;
}
```

This makes spreadsheet software treat the value as text.

---

## 16. Protecting PDF Reports

PDF reports can contain:

```text
Participant comments
Ratings
NPS data
Session information
Potentially sensitive operational feedback
```

In local development, storing reports in:

```text
public/reports
```

is convenient.

In production, reports should generally be private.

Recommended production flow:

```text
Administrator requests report
        ↓
PDF stored in private object storage
        ↓
Admin requests protected download endpoint
        ↓
Server verifies admin authentication
        ↓
Server generates short-lived signed URL
        ↓
Administrator downloads report
```

Do not expose participant feedback reports through predictable public URLs unless the content is intentionally public.

---

## 17. Environment Variables and Secrets

Environment variables separate configuration from code.

GreyMatter Feedback uses values such as:

```dotenv
DATABASE_URL="..."
DIRECT_URL="..."
IP_HASH_SECRET="..."
ADMIN_SESSION_SECRET="..."
ADMIN_PASSWORD="..."
INNGEST_EVENT_KEY="..."
UPSTASH_REDIS_REST_TOKEN="..."
S3_SECRET_ACCESS_KEY="..."
```

Rules:

```text
[ ] Keep .env out of Git.
[ ] Use different secrets for development and production.
[ ] Rotate secrets after suspected exposure.
[ ] Use strong random values.
[ ] Never expose server secrets to Client Components.
[ ] Never log secret values.
```

Generate strong values with:

```bash
openssl rand -hex 32
```

---

## 18. Error Messages

Participants need useful error messages, but the application should not expose internal details.

Good participant-facing message:

```text
We could not accept your feedback right now. Your draft remains saved on this device, so please try again.
```

Unsafe participant-facing message:

```text
PrismaClientKnownRequestError: P1001 cannot reach ep-example-pooler.neon.tech using DATABASE_URL...
```

The first message helps the participant act.

The second message exposes infrastructure details.

Use detailed errors in protected logs, not public responses.

---

## 19. Security Checklist for New Features

Whenever adding a GreyMatter Feedback feature, ask:

```text
Does it accept browser input?
Does it require Zod validation?
Does it require admin authentication?
Does it need authorization beyond authentication?
Could it expose participant feedback?
Could it create duplicate work on retries?
Could it be rate-limited?
Could it leak secrets into client code?
Could it be abused with oversized input?
Could it expose unsafe content in CSV, HTML, or PDF?
```

For example, when adding a new report-download route:

```text
[ ] Require admin authentication.
[ ] Confirm report belongs to permitted organization.
[ ] Confirm report status is COMPLETE.
[ ] Generate a short-lived download URL.
[ ] Do not expose storage credentials.
[ ] Set no-store cache headers.
[ ] Log report ID, not participant comments.
```

---

## 20. Primer Summary

The essential security model is:

```text
Browser input
        ↓
Never trusted automatically
        ↓
Zod validates request structure
        ↓
Server validates against Neon form configuration
        ↓
Rate limiter controls frequency
        ↓
Inngest processes retryable work
        ↓
Database constraints prevent duplicates
```

The essential privacy model is:

```text
No required participant accounts
        ↓
No raw IP storage
        ↓
Daily salted IP hashes for abuse prevention
        ↓
Minimal metadata
        ↓
Protected administrator access
        ↓
Private report access in production
```

The most important rule is:

> Treat every value from a browser, QR URL, form, request body, or external integration as untrusted until the server validates it.
