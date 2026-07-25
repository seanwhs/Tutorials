# Product Requirements Document  
# GreyMatter Feedback

**Document Status:** Draft  
**Version:** 1.0  
**Product Type:** QR-code feedback collection, analytics, and reporting platform  
**Primary Users:** Event organizers, course administrators, facilitators, participants, analysts  
**Target Platform:** Web application, mobile-first participant experience  
**Technology Direction:** Next.js 16, React 19, Tailwind CSS, Neon PostgreSQL, Prisma, Inngest

---

## 1. Product Summary

GreyMatter Feedback is a QR-first feedback platform for workshops, courses, conferences, talks, training sessions, meetings, and internal events.

Administrators create events and sessions, author versioned feedback forms, publish them, and distribute unique QR codes. Participants scan the QR code, complete a mobile-friendly form without creating an account, and submit feedback. Administrators then review analytics, export CSV data, and generate PDF reports.

The product’s core value proposition is:

```text
Participants:
Scan → Answer → Submit → Done

Administrators:
Author → Publish → Measure → Improve
```

---

## 2. Problem Statement

Organizations often collect feedback through paper forms, generic surveys, email links, or manual spreadsheets.

These approaches create problems:

```text
Participants must type long URLs.
Participants may need accounts.
Forms are not tailored to individual sessions.
Feedback is difficult to collect immediately after an event.
Organizers manually combine data.
Reporting is slow and repetitive.
Changing forms can make old analytics inaccurate.
```

GreyMatter Feedback solves these problems through:

```text
Session-specific QR codes.
Mobile-first feedback forms.
Configurable question types.
Versioned published forms.
Anonymous participant access.
Real-time-style analytics refresh.
CSV exports.
Asynchronous PDF reports.
```

---

## 3. Product Vision

GreyMatter Feedback will become a reliable, flexible, privacy-aware feedback system that helps organizations collect meaningful feedback at the moment participants are most able to provide it.

The platform should support:

```text
Different feedback forms for every event, course, module, session, or workshop.
Historically accurate reporting through immutable published form versions.
Fast participant submission even during response spikes.
Simple administrator workflows without requiring database tools.
```

---

## 4. Product Goals

### 4.1 Primary Goals

| Goal | Description |
|---|---|
| Fast participant feedback | Let participants submit feedback in under two minutes |
| Flexible forms | Support different forms for different events and sessions |
| Mobile-first usability | Make QR-to-submission flow easy on phones |
| Historical accuracy | Preserve the exact form version used for every response |
| Useful reporting | Provide metrics, CSV export, and PDF summaries |
| Reliable processing | Use background jobs and idempotency to avoid lost or duplicate responses |
| Privacy-aware design | Avoid participant accounts and raw IP storage |
| Simple administration | Let organizers create forms without Prisma Studio or direct database access |

### 4.2 Success Metrics

| Metric | Initial Target |
|---|---:|
| Participant form completion time | Under 2 minutes for standard short form |
| Participant form load time | Under 1 second on typical 4G where feasible |
| Feedback API acceptance | Under 500 ms under normal load |
| Background submission processing success rate | Greater than 99% |
| Duplicate response rate | 0 duplicate stored responses per submission ID |
| Admin report generation success rate | Greater than 95% |
| Form publishing accuracy | 100% of published forms tied to immutable versions |
| QR scan-to-form success | Greater than 99% in normal network conditions |

---

## 5. Non-Goals

The first product version will not include:

```text
Participant login accounts.
Public social sharing of feedback.
Complex survey branching as a baseline feature.
Advanced multi-organization billing.
Native iOS or Android applications.
Live chat support.
Video feedback submissions.
Automatic sentiment analysis.
Automatic AI-generated summaries by default.
Full learning-management-system synchronization.
Complex role-based access control in the single-admin baseline.
```

These may be considered as later enhancements.

---

## 6. User Personas

## 6.1 Participant

**Description:** A person attending a workshop, course module, talk, or event session.

**Needs:**

```text
Open feedback form quickly.
Avoid sign-up requirements.
Use phone easily.
Keep answers if interrupted.
Receive clear confirmation.
```

**Pain points:**

```text
Long forms.
Small controls.
Unclear questions.
Weak venue Wi-Fi.
Accidental refreshes.
Uncertainty about whether feedback was submitted.
```

---

## 6.2 Event Organizer

**Description:** A person responsible for organizing a conference, workshop, course, or event program.

**Needs:**

```text
Create sessions.
Publish appropriate forms.
Generate QR codes.
See response totals.
Understand what worked and what needs improvement.
```

---

## 6.3 Course Facilitator

**Description:** An instructor or training lead responsible for course modules and learner experience.

**Needs:**

```text
Collect module-level feedback.
Use different forms for different modules.
Compare feedback between cohorts.
Understand clarity, pacing, and exercise usefulness.
```

---

## 6.4 Analyst

**Description:** A person who needs to review detailed feedback data and prepare summaries.

**Needs:**

```text
Export raw CSV data.
Review question-level metrics.
Read written comments.
Generate executive reports.
Preserve form-version context.
```

---

## 6.5 Technical Operator

**Description:** A developer or operations person supporting the platform during live events.

**Needs:**

```text
Monitor submissions.
Inspect Inngest failures.
Verify database connectivity.
Troubleshoot reports.
Manage deployments and environment configuration.
```

---

# 7. Product Scope

## 7.1 Core Product Areas

```text
1. Participant feedback experience
2. Administrator authentication
3. Event and session management
4. Versioned form authoring
5. QR-code generation
6. Secure feedback submission
7. Background response processing
8. Analytics dashboard
9. CSV export
10. PDF reporting
11. Offline draft and submission resilience
12. Production monitoring and deployment support
```

---

# 8. Functional Requirements

## 8.1 Event and Course Management

### Requirement

Administrators must be able to create events or courses.

### Acceptance Criteria

```text
[ ] Administrator can create an event title.
[ ] Event title must be between 3 and 255 characters.
[ ] Event appears in the administrator event list.
[ ] Event can contain multiple sessions.
[ ] Event list displays session count.
```

### Example

```text
Event:
React Summit 2026

Sessions:
Opening Keynote
Server Components Workshop
Advanced React Patterns
```

---

## 8.2 Session Management

### Requirement

Administrators must be able to create session-level feedback targets.

### Acceptance Criteria

```text
[ ] Administrator can create a session title.
[ ] Administrator can create a unique QR-friendly session ID.
[ ] Session IDs support uppercase letters, numbers, and hyphens.
[ ] Session ID is used in participant URL.
[ ] Session can be active or closed.
[ ] Session can have one active published form version.
```

### Example

```text
Session title:
Advanced React Patterns

Session ID:
REACT-2026-Q3

Participant URL:
https://feedback.example.com/e/REACT-2026-Q3?src=qr
```

---

## 8.3 Versioned Form Authoring

### Requirement

Administrators must be able to create versioned feedback forms for sessions.

### Acceptance Criteria

```text
[ ] Administrator can create a draft form version.
[ ] Draft forms are not visible to participants.
[ ] Administrator can add questions to drafts.
[ ] Administrator can reorder draft questions.
[ ] Administrator can delete draft questions.
[ ] Administrator can publish a draft form version.
[ ] Publishing archives the previous published form version.
[ ] Published forms cannot be edited directly.
[ ] New drafts can clone questions from the latest version.
[ ] Every response stores the form version ID used during submission.
```

### Form Statuses

| Status | Participant visibility | Editable |
|---|---:|---:|
| `DRAFT` | No | Yes |
| `PUBLISHED` | Yes | No |
| `ARCHIVED` | No | No |

---

## 8.4 Question Types

### Requirement

The system must support configurable question types.

| Question Type | Description | Stored Value |
|---|---|---|
| Rating | Numeric score on configured scale | `numericValue` |
| NPS | Recommendation score from 0 to 10 | `numericValue` |
| Choice | One selected configured option | `textValue` |
| Text | Written participant feedback | `textValue` |

### Rating Requirements

```text
[ ] Administrator can configure minimum score.
[ ] Administrator can configure maximum score.
[ ] Administrator can configure low-end label.
[ ] Administrator can configure high-end label.
[ ] Minimum rating must be lower than maximum rating.
```

### NPS Requirements

```text
[ ] NPS uses fixed 0–10 scale.
[ ] Administrator can configure endpoint labels.
[ ] Dashboard calculates promoters, passives, detractors, and NPS.
```

### Choice Requirements

```text
[ ] Administrator enters one option per line.
[ ] Choice question must contain at least two options.
[ ] Duplicate and blank options are removed.
[ ] Participant can select one option.
```

### Text Requirements

```text
[ ] Administrator configures maximum character length.
[ ] Participant sees a character count.
[ ] Text is stored as escaped plain text.
```

---

## 8.5 Participant Form Experience

### Requirement

Participants must be able to access and complete a session-specific feedback form through a public QR URL.

### Acceptance Criteria

```text
[ ] Participant form loads from /e/[sessionId].
[ ] Form displays event title and session title.
[ ] Form loads only when session is active.
[ ] Form loads only when active form version is published.
[ ] Missing session shows not-found state.
[ ] Closed session shows feedback-closed state.
[ ] Unpublished form shows unavailable state.
[ ] Form supports rating, NPS, choice, and text controls.
[ ] Form uses touch-friendly controls.
[ ] Interactive controls use at least 48px height.
[ ] Text inputs use at least 16px font size.
[ ] Required questions show clear validation errors.
[ ] Form provides a clear submission confirmation.
```

---

## 8.6 Draft Persistence

### Requirement

The participant form must preserve unfinished answers in the current browser.

### Acceptance Criteria

```text
[ ] Draft answers are stored in localStorage.
[ ] Draft key includes session ID and form version ID.
[ ] Refreshing restores stored answers.
[ ] Participant can discard draft.
[ ] Draft is cleared after successful API acceptance.
[ ] Draft is not reused after a new form version is published.
```

---

## 8.7 Haptic Feedback

### Requirement

The form should provide optional haptic feedback when a participant selects rating or NPS values on supported devices.

### Acceptance Criteria

```text
[ ] Rating selection attempts navigator.vibrate(10).
[ ] NPS selection attempts navigator.vibrate(10).
[ ] Form remains functional when vibration is unavailable.
[ ] Haptic feedback is not required to understand selection state.
```

---

## 8.8 Secure Feedback Submission

### Requirement

The platform must provide a secure public endpoint for participant feedback submission.

### API

```text
POST /api/feedback
```

### Acceptance Criteria

```text
[ ] Endpoint accepts valid JSON.
[ ] Request body is validated with Zod.
[ ] Submission ID must be UUID.
[ ] Session ID must match approved format.
[ ] Form version ID must be UUID.
[ ] Question IDs must be UUIDs.
[ ] Answers must match question type requirements.
[ ] Session must exist.
[ ] Session must be active.
[ ] Form version must be published and active.
[ ] Submitted question IDs must belong to active form version.
[ ] Required questions must be present.
[ ] Invalid requests return safe user-facing errors.
[ ] Valid requests return HTTP 202 Accepted.
```

---

## 8.9 Privacy-Aware Client Identification

### Requirement

The system must not store raw client IP addresses.

### Acceptance Criteria

```text
[ ] Server reads forwarded client IP when available.
[ ] IP is transformed with SHA-256.
[ ] Hash includes private secret and current UTC date.
[ ] Stored value is 64-character hexadecimal hash.
[ ] Raw IP is not written to Neon.
[ ] IP hash is excluded from standard CSV export.
[ ] IP hash is excluded from standard PDF reports.
```

---

## 8.10 Rate Limiting

### Requirement

The platform must prevent repeated abusive participant submission attempts.

### Default Policy

```text
Per client per session:
1 submission every 5 minutes

Per session:
500 submissions per hour
```

### Acceptance Criteria

```text
[ ] Local development supports in-memory fallback.
[ ] Production requires Upstash Redis.
[ ] Rate limit uses session ID and daily IP hash.
[ ] Rate-limited requests return HTTP 429.
[ ] Response includes Retry-After header.
[ ] Rate-limit failures do not reveal internal infrastructure details.
```

---

## 8.11 Inngest Submission Processing

### Requirement

Accepted participant submissions must be processed asynchronously through Inngest.

### Event

```text
feedback/submitted
```

### Acceptance Criteria

```text
[ ] API sends feedback/submitted event after validation.
[ ] Inngest function processes event.
[ ] Function saves one Response record.
[ ] Function saves linked Answer records.
[ ] Function retries temporary failures.
[ ] Function uses step.run() for important processing step.
[ ] Response event ID is unique.
[ ] Replay of same event does not create duplicate response.
```

---

## 8.12 Analytics Dashboard

### Requirement

Administrators must be able to view session-level feedback analytics.

### Route

```text
/admin/sessions/[sessionId]
```

### Dashboard Metrics

```text
Total response count
Average rating
Primary NPS score
Rating question averages
Rating distributions
NPS distributions
Promoter/passive/detractor counts
Choice answer distributions
Written feedback comments
Latest submission timestamp
```

### Acceptance Criteria

```text
[ ] Dashboard requires administrator authentication.
[ ] Dashboard refreshes automatically.
[ ] Dashboard displays empty states when no responses exist.
[ ] Analytics group results by question and form version.
[ ] Dashboard does not expose IP hashes or raw technical metadata.
[ ] Written comments render as escaped text.
```

---

## 8.13 QR Code Generation

### Requirement

Administrators must be able to generate QR-code images for session participant URLs.

### Acceptance Criteria

```text
[ ] QR code is generated from active participant URL.
[ ] QR code can be downloaded as PNG.
[ ] Administrator can copy participant URL.
[ ] QR code includes production URL when production configuration is used.
[ ] QR code generation does not require a public server-side QR API.
```

---

## 8.14 CSV Export

### Requirement

Administrators must be able to export session feedback as CSV.

### Route

```text
GET /api/admin/export/[sessionId]
```

### Export Fields

```text
Event
Session ID
Session Title
Response ID
Submitted At
Form Version
Question
Question Type
Numeric Value
Text Value
```

### Acceptance Criteria

```text
[ ] CSV export requires admin authentication.
[ ] CSV uses one answer per row.
[ ] CSV escapes commas and quotation marks.
[ ] CSV protects spreadsheet formula-like values.
[ ] CSV includes form version context.
[ ] CSV excludes raw IP hashes and user-agent metadata.
[ ] CSV response uses Cache-Control: no-store.
```

---

## 8.15 PDF Report Generation

### Requirement

Administrators must be able to request a PDF executive report asynchronously.

### Event

```text
report/generate.pdf
```

### Report Statuses

```text
QUEUED
PROCESSING
COMPLETE
FAILED
```

### Acceptance Criteria

```text
[ ] Admin can request report from dashboard.
[ ] API creates Report record before sending event.
[ ] Only one active queued or processing report per session is allowed.
[ ] Inngest function calculates analytics.
[ ] Inngest function renders PDF.
[ ] PDF is stored locally in development.
[ ] PDF is stored in S3-compatible storage in production.
[ ] Report record updates to COMPLETE with URL.
[ ] Report record updates to FAILED with safe error message if needed.
[ ] Admin dashboard polls report status.
[ ] Completed report can be downloaded by authorized admin.
```

---

## 8.16 Offline Submission Outbox

### Requirement

The platform should preserve completed participant submissions when network connectivity is unavailable.

### Acceptance Criteria

```text
[ ] Failed network submission is added to browser outbox.
[ ] Outbox stores stable submission ID.
[ ] Duplicate submission ID is not queued twice.
[ ] Browser retries outbox when online event fires.
[ ] Successful retry removes item from outbox.
[ ] Failed retry remains queued.
[ ] Offline experience informs participant that retry will occur.
```

---

# 9. Technical Requirements

## 9.1 Frontend Stack

```text
Next.js 16
React 19
TypeScript
Tailwind CSS
App Router
React Server Components
Client Components
React useActionState where appropriate
```

---

## 9.2 Backend Stack

```text
Next.js API routes
Next.js Server Actions
Neon PostgreSQL
Prisma ORM
Zod validation
Inngest workflows
Upstash Redis rate limiting
S3-compatible report storage
```

---

## 9.3 Database Requirements

### Core Tables

```text
events
sessions
form_versions
questions
responses
answers
reports
```

### Required Relationships

```text
Event → Session
Session → FormVersion
FormVersion → Question
Session → Response
Response → Answer
Question → Answer
Session → Report
```

### Required Integrity Rules

```text
Session IDs are unique.
Form version numbers are unique per session.
Question order indexes are unique per form version.
Response event IDs are unique.
One answer per response per question.
```

---

# 10. Non-Functional Requirements

## 10.1 Performance

| Requirement | Target |
|---|---:|
| Participant page initial render | Under 1 second on typical mobile network where feasible |
| Feedback control interaction | Under 16 ms visible interaction delay |
| Feedback API acceptance | Under 500 ms normal conditions |
| Dashboard refresh interval | 15 seconds |
| PDF generation | Under 30 seconds for moderate response volume |
| QR generation | Under 2 seconds in normal browser conditions |

---

## 10.2 Availability

```text
Participant forms should remain operational during expected event response spikes.
Background processing failures should retry automatically.
Report generation failures should be visible to administrators.
```

---

## 10.3 Accessibility

```text
[ ] Keyboard navigation supported.
[ ] Focus states visible.
[ ] Form controls include accessible labels.
[ ] Required errors are announced.
[ ] Touch controls meet 48px minimum target.
[ ] Text fields avoid mobile zoom.
[ ] QR codes have typed URL alternative.
[ ] Participant forms are usable at 200% zoom.
```

---

## 10.4 Privacy

```text
[ ] No participant account required by default.
[ ] Raw IP addresses are not stored.
[ ] Daily salted IP hashes are used only for abuse prevention.
[ ] Standard exports exclude technical identifiers.
[ ] Written feedback is treated as potentially sensitive.
[ ] Report downloads are protected in production.
[ ] Retention policy is documented.
```

---

## 10.5 Observability

```text
[ ] Next.js logs are available.
[ ] Inngest runs are visible.
[ ] Neon metrics are monitored.
[ ] Rate-limit activity can be reviewed.
[ ] Report failures are visible.
[ ] Logs avoid raw participant answers and secrets.
[ ] Production alerting exists for major submission failures.
```

---

# 11. User Stories

## 11.1 Participant Stories

### Story: Scan and submit

> As a participant, I want to scan a QR code and submit feedback quickly so that I can share my thoughts before leaving the session.

### Story: Recover draft

> As a participant, I want my unfinished answers to remain available after refreshing the page so that I do not need to start again.

### Story: Offline resilience

> As a participant, I want my completed feedback to retry when my connection returns so that a temporary network issue does not lose my response.

---

## 11.2 Administrator Stories

### Story: Create session

> As an administrator, I want to create a session with a readable QR ID so that I can distribute a direct feedback link.

### Story: Author different forms

> As an administrator, I want to create different feedback forms for different sessions so that questions match the session context.

### Story: Publish safely

> As an administrator, I want to publish a new form version without changing previous responses so that historical reports remain accurate.

### Story: Review analytics

> As an administrator, I want to see totals, ratings, NPS, and written comments so that I can understand participant experience.

### Story: Export results

> As an analyst, I want to export CSV data so that I can perform custom analysis in a spreadsheet or BI tool.

### Story: Generate report

> As an event owner, I want to request a PDF summary so that I can share feedback insights with stakeholders.

---

# 12. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Participant QR code does not scan | Display typed fallback URL; test QR on multiple devices |
| Wrong form becomes public | Only published active versions render on public route |
| Published questions change historical reports | Immutable published versions and response formVersionId |
| Duplicate response due to retry | Stable submission ID and unique response eventId |
| Spam submissions | IP hashing and distributed rate limiting |
| PDF generation failure | Inngest retries, report statuses, error visibility |
| Public report exposure | Private object storage and protected signed downloads |
| Admin password exposure | Environment secrets, future named users and MFA |
| Large dashboard query cost | Add aggregates only after measured need |
| Live event outage | Typed URL fallback, external form fallback, operational runbook |

---

# 13. Future Roadmap

## Phase 1 — Core Product

```text
Events
Sessions
Versioned forms
Participant feedback
Neon storage
Inngest submission processing
Analytics
QR codes
CSV
PDF reports
```

## Phase 2 — Operational Improvements

```text
Private signed report downloads
Email report completion notifications
Slack notifications
Scheduled cleanup jobs
Enhanced monitoring
Audit logging
```

## Phase 3 — Authoring Enhancements

```text
Form templates
Question library
Question helper text
Form sections
Conditional questions
Reporting tags
CSV event import
```

## Phase 4 — Multi-Organization Product

```text
Organizations
Named admin users
Password hashing
Role-based permissions
Audit trails
Branding
Organization-specific templates
Tenant isolation
```

## Phase 5 — Advanced Analytics

```text
Scheduled reports
Cross-session comparisons
Aggregate analytics tables
Data warehouse exports
AI-assisted qualitative summaries
External webhooks
LMS integrations
```

---

# 14. Launch Criteria

GreyMatter Feedback is ready for production launch when:

```text
[ ] Participant form works on iPhone and Android.
[ ] QR code and typed fallback URL both work.
[ ] Form authoring works without direct database access.
[ ] Draft and published version workflow is tested.
[ ] Feedback API validates invalid input correctly.
[ ] Rate limiting works in production through Upstash Redis.
[ ] Inngest submission worker succeeds.
[ ] Duplicate event replay does not create duplicate response.
[ ] Dashboard metrics match Neon records.
[ ] CSV export works and excludes technical identifiers.
[ ] PDF report generation succeeds.
[ ] Production report storage is protected.
[ ] Neon migrations are applied safely.
[ ] Monitoring and alerting are configured.
[ ] Operational owner and fallback plan are documented.
```

---

# 15. Final Product Principle

GreyMatter Feedback should remain easy at the edges and rigorous at the center.

```text
Participant experience:
Simple, fast, mobile-friendly, anonymous

Administrator experience:
Flexible, guided, data-rich, operationally safe

Platform architecture:
Versioned, validated, privacy-aware, retry-safe, observable
```

The product succeeds when organizations can collect feedback at the right moment and confidently turn it into practical improvements.
