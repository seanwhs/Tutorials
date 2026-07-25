# Software Requirements Document (SRD)  
# GreyMatter Feedback

**Version:** 1.0  
**Status:** Baseline System Requirements  
**Product:** GreyMatter Feedback  
**System Type:** QR-code feedback collection, form authoring, analytics, and reporting platform

---

## 1. Purpose

This Software Requirements Document defines the functional, technical, security, operational, and quality requirements for **GreyMatter Feedback**.

GreyMatter Feedback enables organizations to:

- Create events, courses, and sessions.
- Author different feedback forms for different sessions.
- Publish immutable, versioned forms.
- Generate QR-code participant links.
- Collect anonymous mobile feedback.
- Persist feedback reliably through background processing.
- Review analytics.
- Export CSV data.
- Generate PDF reports.

This SRD is intended for:

```text
Product owners
Software engineers
Technical architects
QA engineers
Security reviewers
DevOps and platform engineers
Event operations teams
```

---

## 2. System Scope

### 2.1 In Scope

```text
Public participant feedback forms
QR-code session links
Administrator authentication
Event and course management
Session management
Versioned form authoring
Rating, NPS, choice, and text questions
Participant local drafts
Offline submission outbox
Secure feedback API
IP hashing
Rate limiting
Inngest background processing
Neon PostgreSQL persistence
Admin analytics dashboard
QR-code PNG download
CSV exports
Asynchronous PDF reports
Local development report storage
Production S3-compatible report storage
Testing, observability, and deployment support
```

### 2.2 Out of Scope for Baseline Release

```text
Participant accounts
Native iOS or Android applications
Public feedback browsing
Public comment sharing
Multi-tenant organization billing
Full role-based access control
Single sign-on
Complex conditional form logic
Multi-language localization
AI sentiment analysis
Automated moderation
LMS synchronization
Automated email notifications
```

---

## 3. System Context

```text
┌───────────────────────┐
│ Participant Device    │
│ QR Scan + Feedback    │
└───────────┬───────────┘
            │ HTTPS
            ▼
┌─────────────────────────────────────────────┐
│ Next.js 16 Application                      │
│                                             │
│ Public participant pages                    │
│ Protected administrator portal              │
│ API routes                                  │
│ Inngest endpoint                            │
└───────────┬─────────────────────────────────┘
            │
     ┌──────┴─────────────┐
     ▼                    ▼
┌───────────────┐   ┌─────────────────────┐
│ Neon Postgres │   │ Inngest             │
│ via Prisma    │   │ Background jobs     │
└───────────────┘   └──────────┬──────────┘
                                │
                                ▼
                      ┌─────────────────────┐
                      │ Report Storage      │
                      │ S3 / R2 / Local     │
                      └─────────────────────┘

Additional production dependency:
Upstash Redis for distributed rate limiting
```

---

## 4. Technology Requirements

| Area | Required Technology |
|---|---|
| Web framework | Next.js 16 App Router |
| UI library | React 19 |
| Language | TypeScript |
| Styling | Tailwind CSS |
| Database | Neon PostgreSQL |
| ORM | Prisma |
| Validation | Zod |
| Background jobs | Inngest |
| Rate limiting | Upstash Redis in production |
| QR generation | `qrcode` package |
| PDF generation | `@react-pdf/renderer` |
| Object storage | S3-compatible provider in production |
| Testing | Vitest minimum; Playwright recommended later |

---

## 5. User Roles

## 5.1 Participant

A public user who scans a QR code or opens a participant link.

Participant permissions:

```text
View active published form.
Submit feedback.
Store local draft.
Retry queued offline submission.
```

Participant restrictions:

```text
Cannot access admin routes.
Cannot view analytics.
Cannot view other responses.
Cannot create or modify forms.
```

---

## 5.2 Administrator

A protected user authenticated through an HTTP-only signed session cookie.

Administrator permissions:

```text
Create events and courses.
Create sessions.
Create drafts.
Add, delete, and reorder draft questions.
Publish form versions.
Open and close sessions.
View analytics.
Download QR codes.
Export CSV.
Request PDF reports.
Download completed reports.
```

---

## 5.3 Technical Operator

A system operator responsible for deployment, logs, Inngest, Neon, Upstash, storage, and incident handling.

Technical operator responsibilities:

```text
Configure environment variables.
Apply Prisma migrations.
Monitor application errors.
Monitor Inngest runs.
Review Neon health.
Configure report storage.
Maintain rate-limit infrastructure.
Respond to production incidents.
```

---

# 6. Functional Requirements

## FR-001 — Event Creation

The system shall allow authenticated administrators to create an event or course.

### Inputs

| Field | Type | Validation |
|---|---|---|
| Title | String | Required; 3–255 characters |

### Expected Behavior

```text
Administrator submits event title
        ↓
Server validates title
        ↓
Event record is created in Neon
        ↓
Administrator is redirected to event detail page
```

### Acceptance Criteria

```text
[ ] Event creation requires admin authentication.
[ ] Event title is trimmed.
[ ] Event title shorter than 3 characters is rejected.
[ ] Event title longer than 255 characters is rejected.
[ ] Created event appears in event list.
```

---

## FR-002 — Session Creation

The system shall allow authenticated administrators to create sessions within an event.

### Inputs

| Field | Type | Validation |
|---|---|---|
| Session title | String | Required; 3–255 characters |
| Session ID | String | Required; 3–64 characters; uppercase letters, numbers, hyphens |

### Acceptance Criteria

```text
[ ] Session ID is globally unique.
[ ] Session ID is normalized to uppercase.
[ ] Duplicate session IDs are rejected.
[ ] Session belongs to selected event.
[ ] New session is active by default.
[ ] New session does not have an active form version until publishing.
[ ] Admin is redirected to session editor after creation.
```

---

## FR-003 — Draft Form Version Creation

The system shall allow administrators to create editable form versions.

### Behavior

```text
If no prior version exists:
Create empty Draft Version 1.

If prior version exists:
Create next Draft Version and clone latest version questions.
```

### Acceptance Criteria

```text
[ ] Draft version number is incremented per session.
[ ] Draft versions are not visible through participant route.
[ ] New draft can clone prior question text, type, settings, options, and order.
[ ] Cloned questions receive new database IDs.
[ ] Draft creation requires admin authentication.
```

---

## FR-004 — Question Authoring

The system shall allow administrators to add questions to a draft form version.

### Supported Types

```text
RATING
NPS
CHOICE
TEXT
```

### Common Question Fields

| Field | Requirement |
|---|---|
| Question text | Required; 3–2,000 characters |
| Question type | Required; valid enum |
| Required flag | Boolean |
| Order index | Generated and managed by server |
| Settings | Type-specific JSON |
| Options | Required for choice questions |

### Acceptance Criteria

```text
[ ] Questions can be added only to draft versions.
[ ] Questions are assigned the next available order index.
[ ] Question text is validated.
[ ] Question type is validated.
[ ] Required flag is persisted.
[ ] Questions cannot be added to published or archived versions.
```

---

## FR-005 — Rating Question Configuration

The system shall support configurable rating questions.

### Required Settings

```json
{
  "min": 1,
  "max": 5,
  "minLabel": "Not useful",
  "maxLabel": "Extremely useful"
}
```

### Acceptance Criteria

```text
[ ] Minimum must be integer between 1 and 10.
[ ] Maximum must be integer between 2 and 10.
[ ] Maximum must be greater than minimum.
[ ] Labels are optional but limited to 100 characters.
[ ] Participant UI renders all values from min through max.
```

---

## FR-006 — NPS Question Configuration

The system shall support Net Promoter Score questions.

### Fixed Score Range

```text
0 through 10
```

### Optional Labels

```json
{
  "minLabel": "Not at all likely",
  "maxLabel": "Extremely likely"
}
```

### Acceptance Criteria

```text
[ ] NPS score range cannot be changed from 0–10.
[ ] Participant UI renders scores 0 through 10.
[ ] NPS answer must be an integer.
[ ] NPS analytics calculate promoter, passive, detractor, and total score.
```

---

## FR-007 — Choice Question Configuration

The system shall support single-select choice questions.

### Acceptance Criteria

```text
[ ] Administrator enters one option per line.
[ ] Blank options are removed.
[ ] Duplicate options are removed.
[ ] Each option has maximum length of 250 characters.
[ ] At least two options are required.
[ ] Participant can select exactly one option.
[ ] Submitted answer must match configured option exactly after normalization.
```

---

## FR-008 — Text Question Configuration

The system shall support plain-text feedback questions.

### Required Settings

```json
{
  "maxLength": 1500,
  "placeholder": "Write your feedback here."
}
```

### Acceptance Criteria

```text
[ ] Maximum text length is between 1 and 5,000.
[ ] Participant UI displays character count.
[ ] Submitted text is trimmed.
[ ] Submitted text longer than configured maximum is rejected.
[ ] Text is rendered as escaped plain text.
```

---

## FR-009 — Question Ordering

The system shall allow administrators to reorder draft questions.

### Acceptance Criteria

```text
[ ] Questions can move one position up.
[ ] Questions can move one position down.
[ ] First question cannot move up.
[ ] Last question cannot move down.
[ ] Ordering updates are atomic.
[ ] Unique order index constraint remains valid.
[ ] Reordering published or archived form questions is prohibited.
```

---

## FR-010 — Question Deletion

The system shall allow administrators to remove questions from draft forms.

### Acceptance Criteria

```text
[ ] Question deletion is allowed only for drafts.
[ ] Deleting question shifts later order indexes down by one.
[ ] Published question records cannot be deleted through authoring UI.
[ ] Deletion requires admin authentication.
```

---

## FR-011 — Form Publishing

The system shall allow an administrator to publish a draft form version.

### Publishing Transaction

```text
Archive currently published version, if present
        ↓
Set selected draft status to PUBLISHED
        ↓
Set published timestamp
        ↓
Update Session.activeFormVersionId
        ↓
Ensure Session.isActive is true
```

### Acceptance Criteria

```text
[ ] Only draft versions can be published.
[ ] Draft must contain at least one question.
[ ] Choice questions must have at least two options.
[ ] Previous published version becomes archived.
[ ] New version becomes published.
[ ] Session active form version updates atomically.
[ ] Participant route renders new form after publishing.
```

---

## FR-012 — Participant Form Availability

The system shall render participant feedback forms only when appropriate.

### Route

```text
/e/[sessionId]
```

### Required Checks

```text
Session exists.
Session is active.
Session has activeFormVersionId.
Active form version exists.
Active form version status is PUBLISHED.
```

### Outcomes

| Condition | Participant Result |
|---|---|
| Session does not exist | Not-found page |
| Session is inactive | Feedback closed page |
| No published form | Feedback unavailable page |
| Valid active published form | Interactive feedback form |

---

## FR-013 — Participant Form Rendering

The participant form shall dynamically render published questions.

### Acceptance Criteria

```text
[ ] Form displays event title.
[ ] Form displays session title.
[ ] Questions are ordered by order index.
[ ] Question type determines control type.
[ ] Required or optional state is displayed.
[ ] Rating controls render configured range.
[ ] NPS controls render 0–10 range.
[ ] Choice controls render all configured options.
[ ] Text controls render configured maximum and placeholder.
```

---

## FR-014 — Participant Draft Persistence

The system shall persist unfinished participant answers in browser localStorage.

### Draft Key Format

```text
greymatter-feedback:draft:{sessionId}:{formVersionId}
```

### Acceptance Criteria

```text
[ ] Draft stores answers.
[ ] Draft stores stable submission ID.
[ ] Draft stores updated timestamp.
[ ] Refresh restores answers in same browser.
[ ] Draft restoration is scoped by form version.
[ ] Participant can discard draft.
[ ] Draft is cleared after accepted submission.
```

---

## FR-015 — Participant Client-Side Validation

The participant form shall validate visible required fields before sending a submission request.

### Acceptance Criteria

```text
[ ] Required unanswered question produces field error.
[ ] Error text is visible near question.
[ ] Error uses accessible role or live region.
[ ] Form scrolls to first invalid question.
[ ] Existing answers are retained.
[ ] Client validation does not replace server validation.
```

---

## FR-016 — Participant Submission API

The system shall expose a public feedback API.

### Endpoint

```text
POST /api/feedback
```

### Request Structure

```json
{
  "submissionId": "UUID",
  "sessionId": "REACT-2026-Q3",
  "formVersionId": "UUID",
  "answers": [
    {
      "questionId": "UUID",
      "value": 5
    }
  ],
  "metadata": {
    "source": "qr",
    "screenWidth": 390,
    "screenHeight": 844
  }
}
```

### Success Response

```http
202 Accepted
```

```json
{
  "accepted": true,
  "submissionId": "UUID"
}
```

### Acceptance Criteria

```text
[ ] Invalid JSON returns HTTP 400.
[ ] Invalid request structure returns HTTP 400.
[ ] Unknown session returns HTTP 404.
[ ] Closed session returns HTTP 409.
[ ] Stale form version returns HTTP 409.
[ ] Invalid question ownership returns HTTP 400.
[ ] Valid requests queue Inngest event.
[ ] Valid requests return HTTP 202.
```

---

## FR-017 — Server-Side Answer Validation

The server shall validate all answers against the active published form configuration.

### Validation Rules

| Question Type | Server Validation |
|---|---|
| Rating | Integer within configured range |
| NPS | Integer from 0 through 10 |
| Choice | String matching configured option |
| Text | Trimmed string within max length |

### Acceptance Criteria

```text
[ ] Duplicate question IDs in same request are rejected.
[ ] Unknown question IDs are rejected.
[ ] Required answers are enforced.
[ ] Numeric values cannot be sent for text or choice question.
[ ] Text values cannot be sent for rating or NPS question.
[ ] Validated answers are converted into numericValue or textValue form.
```

---

## FR-018 — Privacy-Aware Client Hashing

The system shall derive a daily salted SHA-256 hash from client IP address.

### Acceptance Criteria

```text
[ ] Server uses x-forwarded-for first IP when present.
[ ] Server uses x-real-ip when forwarded header unavailable.
[ ] Development fallback is unknown-client.
[ ] Hash includes IP_HASH_SECRET.
[ ] Hash includes current UTC date.
[ ] Hash is 64-character hexadecimal SHA-256 digest.
[ ] Raw IP is never persisted.
```

---

## FR-019 — Rate Limiting

The system shall rate-limit public feedback submissions.

### Default Limits

```text
Per client per session:
1 submission every 5 minutes

Per session:
500 submissions per hour
```

### Acceptance Criteria

```text
[ ] Production rate limits use Upstash Redis.
[ ] Development may use in-memory fallback.
[ ] Rate-limit key includes session ID.
[ ] Client-specific key includes client IP hash.
[ ] Rejected request returns HTTP 429.
[ ] Rejected response includes Retry-After header.
[ ] Rate limiter errors return HTTP 503 without internal details.
```

---

## FR-020 — Inngest Submission Event

The API shall dispatch a validated event after accepting feedback.

### Event Name

```text
feedback/submitted
```

### Event Data

```text
submissionId
sessionId
formVersionId
clientIpHash
safe metadata
validated answers
```

### Acceptance Criteria

```text
[ ] Event is sent only after API validation succeeds.
[ ] Event contains no raw IP address.
[ ] Event contains no server secrets.
[ ] Event contains normalized answer data.
[ ] Event dispatch failure returns HTTP 503.
```

---

## FR-021 — Background Response Persistence

The system shall process feedback submissions through an Inngest function.

### Function

```text
process-feedback-submission
```

### Acceptance Criteria

```text
[ ] Function listens for feedback/submitted.
[ ] Function retries temporary failure up to configured limit.
[ ] Function saves Response record.
[ ] Function saves related Answer records.
[ ] Function uses step.run() for persistence step.
[ ] Function logs safe operational metadata.
```

---

## FR-022 — Idempotent Feedback Persistence

The system shall prevent duplicate stored responses.

### Acceptance Criteria

```text
[ ] Browser creates stable submission ID for draft.
[ ] Submission ID is reused on retries.
[ ] Response.eventId has unique database constraint.
[ ] Persistence service checks for existing event ID.
[ ] Unique constraint race is handled safely.
[ ] Replayed Inngest event does not create extra Response.
[ ] Replayed Inngest event does not create extra Answer records.
```

---

## FR-023 — Administrator Authentication

The system shall protect administrator routes using signed HTTP-only session cookies.

### Acceptance Criteria

```text
[ ] Login verifies configured admin password.
[ ] Password comparison uses timing-safe comparison.
[ ] Successful login creates signed session token.
[ ] Session token contains expiration time.
[ ] Cookie is HTTP-only.
[ ] Cookie uses SameSite=Lax.
[ ] Cookie uses Secure flag in production.
[ ] Expired or invalid token is rejected.
[ ] Protected routes redirect unauthenticated users to login.
[ ] Sign-out clears session cookie.
```

---

## FR-024 — Admin Dashboard

The system shall provide protected session analytics.

### Route

```text
/admin/sessions/[sessionId]
```

### Acceptance Criteria

```text
[ ] Dashboard requires authenticated admin.
[ ] Dashboard shows total response count.
[ ] Dashboard shows average rating.
[ ] Dashboard shows primary NPS score.
[ ] Dashboard shows question-level distributions.
[ ] Dashboard shows choice counts.
[ ] Dashboard shows written comments.
[ ] Dashboard shows form version context.
[ ] Dashboard refreshes every 15 seconds.
[ ] Dashboard supports empty states.
```

---

## FR-025 — NPS Analytics

The system shall calculate NPS for each NPS question.

### Definitions

```text
Promoter: score 9 or 10
Passive: score 7 or 8
Detractor: score 0 through 6
```

### Formula

```text
NPS = ((promoters - detractors) / total NPS answers) × 100
```

### Acceptance Criteria

```text
[ ] Empty NPS answer set returns null score.
[ ] NPS is rounded to nearest integer.
[ ] Dashboard displays promoter count.
[ ] Dashboard displays passive count.
[ ] Dashboard displays detractor count.
[ ] Dashboard displays NPS score.
```

---

## FR-026 — QR Code Generation

The system shall create a downloadable QR code for each session participant URL.

### Acceptance Criteria

```text
[ ] QR code generated in admin browser.
[ ] QR code uses active public participant URL.
[ ] QR code can download as PNG.
[ ] Administrator can copy URL.
[ ] QR image includes high contrast.
[ ] QR generation failure displays safe error.
```

---

## FR-027 — CSV Export

The system shall provide protected session CSV export.

### Endpoint

```text
GET /api/admin/export/[sessionId]
```

### Acceptance Criteria

```text
[ ] Export requires admin authentication.
[ ] Export returns HTTP 401 when unauthorized.
[ ] Export returns HTTP 404 for missing session.
[ ] Export includes one row per answer.
[ ] Export includes form version number.
[ ] Export escapes commas, line breaks, and quotes.
[ ] Export mitigates spreadsheet formula injection.
[ ] Export uses attachment Content-Disposition.
[ ] Export uses Cache-Control: no-store.
```

---

## FR-028 — PDF Report Request

The system shall allow administrators to queue PDF report generation.

### Endpoint

```text
POST /api/admin/reports/[sessionId]
```

### Acceptance Criteria

```text
[ ] Endpoint requires admin authentication.
[ ] Endpoint verifies session exists.
[ ] Endpoint creates Report record with QUEUED status.
[ ] Endpoint dispatches report/generate.pdf event.
[ ] Endpoint returns HTTP 202.
[ ] Endpoint rejects duplicate queued or processing report with HTTP 409.
[ ] Queue failure sets Report status to FAILED.
```

---

## FR-029 — PDF Report Generation

The system shall generate PDF reports asynchronously.

### Function

```text
generate-pdf-report
```

### Acceptance Criteria

```text
[ ] Function listens for report/generate.pdf.
[ ] Function updates report to PROCESSING.
[ ] Function loads session analytics.
[ ] Function renders PDF with React PDF.
[ ] Function stores PDF.
[ ] Function sets Report to COMPLETE.
[ ] Function stores report URL.
[ ] Function sets Report to FAILED on error.
[ ] Function retries temporary failures.
```

---

## FR-030 — Report Storage

The system shall support two report storage modes.

| Environment | Storage Mode |
|---|---|
| Development | Local filesystem under public/reports |
| Production | S3-compatible storage |

### Acceptance Criteria

```text
[ ] Local storage creates public/reports directory as needed.
[ ] Local reports are ignored by Git.
[ ] Production storage uses configured credentials.
[ ] Production report filenames are sanitized.
[ ] Report MIME type is application/pdf.
[ ] Production deployment does not rely on ephemeral local filesystem.
```

---

## FR-031 — Offline Submission Outbox

The system shall queue failed network submissions locally.

### Acceptance Criteria

```text
[ ] Outbox is stored in localStorage.
[ ] Outbox uses submission ID to avoid duplicate entries.
[ ] Outbox retries when navigator.onLine becomes true.
[ ] Successful response removes outbox item.
[ ] Failed request remains in outbox.
[ ] Participant receives clear offline message.
```

---

# 7. Data Requirements

## 7.1 Core Entity Relationships

```text
Event
  └── Session
        ├── FormVersion
        │     └── Question
        │
        ├── Response
        │     └── Answer
        │
        └── Report
```

---

## 7.2 Required Database Entities

### Event

| Field | Type | Requirement |
|---|---|---|
| id | UUID | Primary key |
| title | String | Required |
| createdAt | DateTime | Default current time |

---

### Session

| Field | Type | Requirement |
|---|---|---|
| id | String | Primary key; QR-friendly |
| eventId | UUID | Foreign key to Event |
| title | String | Required |
| isActive | Boolean | Default true |
| activeFormVersionId | UUID nullable | Active participant form |
| createdAt | DateTime | Default current time |

---

### FormVersion

| Field | Type | Requirement |
|---|---|---|
| id | UUID | Primary key |
| sessionId | String | Foreign key to Session |
| versionNumber | Integer | Unique per session |
| status | Enum | Draft, published, archived |
| publishedAt | DateTime nullable | Set when published |
| createdAt | DateTime | Default current time |
| updatedAt | DateTime | Automatically updated |

---

### Question

| Field | Type | Requirement |
|---|---|---|
| id | UUID | Primary key |
| formVersionId | UUID | Foreign key to FormVersion |
| orderIndex | Integer | Unique per form version |
| questionText | Text | Required |
| questionType | Enum | Rating, NPS, text, choice |
| isRequired | Boolean | Default false |
| settings | JSON | Type-specific configuration |
| options | JSON | Choice options |

---

### Response

| Field | Type | Requirement |
|---|---|---|
| id | UUID | Primary key |
| eventId | String | Unique submission ID |
| sessionId | String | Foreign key to Session |
| formVersionId | UUID | Foreign key to FormVersion |
| submittedAt | DateTime | Default current time |
| clientIpHash | String nullable | 64-char SHA-256 hash |
| metadata | JSON | Safe technical metadata |

---

### Answer

| Field | Type | Requirement |
|---|---|---|
| id | UUID | Primary key |
| responseId | UUID | Foreign key to Response |
| questionId | UUID | Foreign key to Question |
| numericValue | Integer nullable | Rating or NPS |
| textValue | Text nullable | Choice or text answer |

---

### Report

| Field | Type | Requirement |
|---|---|---|
| id | UUID | Primary key |
| sessionId | String | Foreign key to Session |
| status | Enum | Queued, processing, complete, failed |
| url | Text nullable | Download location |
| error | Text nullable | Safe error detail |
| createdAt | DateTime | Default current time |
| updatedAt | DateTime | Automatically updated |

---

# 8. Interface Requirements

## 8.1 Participant Interface

### Required Screens

```text
Participant feedback form
Feedback session not found
Feedback closed
Feedback unavailable
Feedback submission success
Feedback submission failure
Offline submission queued state
```

### Participant Design Requirements

```text
White or high-contrast readable background.
Minimum 48px interactive touch targets.
Input text size at least 16px.
Clear selected state for scores and choices.
Visible required/optional labels.
Clear accessible error messages.
Mobile-first layout.
No login requirement.
```

---

## 8.2 Administrator Interface

### Required Screens

```text
Admin login
Event list
Create event
Event detail
Create session
Session form editor
Session analytics dashboard
Report status panel
```

### Administrator Design Requirements

```text
Protected access.
Clear form state labels.
Visible draft, published, and archived form history.
Clear participant URL.
QR code download.
CSV export.
PDF report request and status visibility.
```

---

# 9. Security Requirements

## 9.1 Secret Management

```text
[ ] Secrets must use environment variables.
[ ] .env must not be committed to source control.
[ ] NEXT_PUBLIC_ variables must not contain secrets.
[ ] Development and production must use separate secrets.
[ ] Production secrets must be rotatable.
```

---

## 9.2 Authentication Requirements

```text
[ ] Admin routes require valid session cookie.
[ ] Admin API routes require valid session cookie.
[ ] Session cookie must be HTTP-only.
[ ] Session token must expire.
[ ] Login errors must not reveal secret configuration.
```

---

## 9.3 Input Security Requirements

```text
[ ] Validate all public request bodies.
[ ] Validate admin authoring input.
[ ] Validate URL route parameters.
[ ] Enforce length limits.
[ ] Escape participant text in HTML.
[ ] Escape participant text in CSV.
[ ] Avoid unsafe HTML rendering.
```

---

## 9.4 Report Security Requirements

```text
[ ] Local report storage is development-only.
[ ] Production reports should use private object storage.
[ ] Production report download should use authentication or short-lived signed URLs.
[ ] Report URLs must not expose cloud storage secrets.
```

---

# 10. Performance Requirements

| Area | Requirement |
|---|---|
| Participant initial render | Server-rendered shell with minimal client JavaScript |
| Participant interaction | Rating/choice UI update should be immediate |
| API response | Validation and event queue response should be fast |
| Background persistence | Inngest handles slow/retryable writes |
| Report generation | Asynchronous, never block admin browser request |
| Dashboard | Auto-refresh every 15 seconds |
| Database access | Use Neon pooled URL for runtime |
| Database migrations | Use Neon direct URL |

---

# 11. Reliability Requirements

```text
[ ] Feedback submission must survive temporary worker retry.
[ ] Duplicate submissions with same submission ID must not create duplicate responses.
[ ] Form publishing must use database transaction.
[ ] Report generation failures must be visible.
[ ] Offline participant submissions should be queued locally where possible.
[ ] Background jobs must have configured retries.
[ ] Production rate limiting must use shared Redis infrastructure.
```

---

# 12. Observability Requirements

## Required Logs

```text
Feedback API completion timing.
Submission ID.
Session ID.
Form version ID.
Response ID.
Report ID.
Inngest job status.
Report generation status.
Safe error category.
```

## Prohibited Logs

```text
Raw participant answers.
Raw IP addresses.
Database URLs.
Authorization headers.
Cookies.
Administrator passwords.
S3 secrets.
Inngest secrets.
```

## Required Monitoring

```text
Next.js request errors.
Inngest failed runs.
Neon connection errors.
Rate-limit rejection volume.
PDF report failures.
Storage upload failures.
```

---

# 13. Test Requirements

## Unit Tests

Required initial test coverage:

```text
Average calculation.
NPS calculation.
Choice option normalization.
CSV escaping.
Spreadsheet formula protection.
```

## Integration Tests

Recommended:

```text
Feedback API validation.
Admin authentication.
Response persistence.
Idempotency behavior.
CSV export authorization.
Report request lifecycle.
```

## End-to-End Tests

Recommended:

```text
Admin creates event.
Admin creates session.
Admin creates draft.
Admin adds questions.
Admin publishes form.
Participant submits feedback.
Inngest saves response.
Admin sees analytics.
Admin exports CSV.
Admin generates PDF.
```

---

# 14. Deployment Requirements

## Development

```text
Next.js: localhost:3000
Inngest Dev Server: localhost:8288
Neon: development branch
Reports: public/reports
Rate limit: in-memory fallback permitted
```

## Staging

```text
Separate deployment URL
Separate Neon branch
Separate Inngest environment
Separate Upstash database
Separate storage bucket or prefix
```

## Production

```text
HTTPS custom domain
Neon production branch
Inngest production application
Upstash Redis configured
S3-compatible storage configured
INNGEST_DEV=0
Private report download strategy
Monitoring and alerting configured
```

---

# 15. Definition of Done

A GreyMatter Feedback release is complete when:

```text
[ ] Feature requirements are implemented.
[ ] TypeScript compiles.
[ ] Prisma schema validates.
[ ] Unit tests pass.
[ ] Lint passes.
[ ] Production build passes.
[ ] Feature is tested on mobile participant experience.
[ ] Feature is tested in admin interface.
[ ] Security validation is complete.
[ ] No secrets are exposed.
[ ] Relevant Inngest function behavior is tested.
[ ] Documentation is updated.
[ ] Deployment and rollback impact is understood.
```

---

# 16. Final System Requirement Statement

GreyMatter Feedback shall provide a secure, mobile-first, QR-code feedback experience that supports configurable session-specific forms, immutable published form versions, privacy-aware participant submissions, reliable background processing, analytics, CSV exports, and asynchronous PDF reports.

The system shall preserve historical feedback accuracy by associating every response with the exact published form version displayed to the participant.
