# GreyMatter Feedback  
## Enterprise Architecture and Design Document (EADD)

**Version:** 1.0  
**Status:** Proposed Reference Architecture  
**Application Type:** QR-code feedback, analytics, and reporting platform

---

## 1. Executive Summary

GreyMatter Feedback is a QR-first feedback platform for events, workshops, courses, conferences, and training sessions.

Participants scan a QR code, complete a mobile-friendly form, and submit feedback without requiring an account. Administrators create versioned forms, publish them, monitor analytics, download QR codes, export CSV data, and request asynchronous PDF reports.

The architecture prioritizes:

- Fast participant submission.
- Flexible forms per event and session.
- Historical reporting accuracy through form versioning.
- Privacy-aware anonymous feedback.
- Reliable background processing.
- Neon PostgreSQL as the authoritative data source.
- Inngest for retryable event processing and report generation.

---

## 2. Architecture Goals

| Goal | Design Response |
|---|---|
| Fast QR participant experience | Server-rendered participant shell with lightweight React form |
| Different forms for each event/course | Database-driven questions linked to form versions |
| Preserve historical accuracy | Responses store `formVersionId` |
| Avoid participant account friction | Anonymous public form route |
| Prevent spam | Daily IP hashing and distributed rate limiting |
| Handle retryable work safely | Inngest functions with idempotent submission IDs |
| Support reporting | Admin analytics, CSV export, asynchronous PDF reports |
| Support production deployment | Neon, Inngest, Upstash Redis, S3-compatible storage |

---

## 3. Logical Architecture

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         USER EXPERIENCE LAYER                       │
│                                                                     │
│  Participants                          Administrators               │
│  ├── Scan QR code                      ├── Create events            │
│  ├── Complete form                     ├── Create sessions          │
│  ├── Save local draft                  ├── Author draft forms       │
│  ├── Submit feedback                   ├── Publish versions         │
│  └── Receive confirmation              ├── Review analytics         │
│                                        ├── Export CSV               │
│                                        └── Request PDF reports      │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────┐
│                NEXT.JS 16 APPLICATION LAYER                        │
│                                                                     │
│  Public routes                                                      │
│  ├── /e/[sessionId]                                                 │
│  └── POST /api/feedback                                             │
│                                                                     │
│  Protected administration routes                                    │
│  ├── /admin/events                                                  │
│  ├── /admin/sessions/[sessionId]/edit                               │
│  └── /admin/sessions/[sessionId]                                   │
│                                                                     │
│  Integration routes                                                 │
│  ├── /api/inngest                                                   │
│  ├── /api/admin/export/[sessionId]                                  │
│  └── /api/admin/reports/[sessionId]                                 │
└──────────────────────┬───────────────────────┬──────────────────────┘
                       │                       │
                       ▼                       ▼
┌─────────────────────────────┐   ┌─────────────────────────────────┐
│     NEON POSTGRESQL         │   │             INNGEST             │
│       THROUGH PRISMA        │   │        EVENT PROCESSING         │
│                             │   │                                 │
│ Events                      │   │ feedback/submitted              │
│ Sessions                    │   │ ├── Save responses              │
│ Form versions               │   │ ├── Save answers                │
│ Questions                   │   │ └── Retry failures              │
│ Responses                   │   │                                 │
│ Answers                     │   │ report/generate.pdf             │
│ Reports                     │   │ ├── Load analytics              │
│                             │   │ ├── Render PDF                 │
│                             │   │ ├── Store report               │
│                             │   │ └── Mark report complete       │
└─────────────────────────────┘   └──────────────┬──────────────────┘
                                                  │
                                                  ▼
                              ┌─────────────────────────────────────┐
                              │          REPORT STORAGE             │
                              │                                     │
                              │ Development: public/reports         │
                              │ Production: private S3/R2 storage   │
                              └─────────────────────────────────────┘
```

---

## 4. Deployment Architecture

```text
                         ┌─────────────────────┐
                         │ Participant Browser │
                         │ Administrator Browser│
                         └──────────┬──────────┘
                                    │ HTTPS
                                    ▼
                    ┌─────────────────────────────┐
                    │ Next.js Hosting Platform     │
                    │ Example: Vercel              │
                    │                              │
                    │ Next.js 16 + React 19        │
                    │ API routes                   │
                    │ Server Actions               │
                    │ Inngest endpoint             │
                    └───────┬──────────┬──────────┘
                            │          │
                   Pooled DB│          │ Events
                            ▼          ▼
              ┌──────────────────┐  ┌──────────────────┐
              │ Neon PostgreSQL │  │ Inngest Cloud    │
              │                 │  │                  │
              │ Prisma runtime  │  │ Background jobs  │
              └──────────────────┘  └────────┬─────────┘
                                              │
                          ┌───────────────────┼───────────────────┐
                          │                   │                   │
                          ▼                   ▼                   ▼
                ┌───────────────┐   ┌──────────────┐   ┌────────────────┐
                │ Upstash Redis │   │ S3 / R2      │   │ Email / Slack  │
                │ Rate limiting │   │ PDF reports  │   │ Optional future│
                └───────────────┘   └──────────────┘   └────────────────┘
```

---

## 5. Core Domain Model

```text
Event or Course
  └── Session
        ├── Form Version
        │     └── Questions
        │
        ├── Response
        │     └── Answers
        │
        └── Report
```

### Main entities

| Entity | Purpose |
|---|---|
| `Event` | Parent container for a conference, course, workshop series, or training program |
| `Session` | QR-addressable feedback target, such as a course module or conference talk |
| `FormVersion` | Draft, published, or archived snapshot of a session feedback form |
| `Question` | A rating, NPS, text, or choice question |
| `Response` | One completed participant submission |
| `Answer` | One participant answer linked to a response and question |
| `Report` | PDF report lifecycle record |

---

## 6. Form Versioning Architecture

```text
Session: REACT-2026-Q3
│
├── Form Version 1
│   ├── Status: ARCHIVED
│   ├── Questions: 4
│   └── Responses: 125
│
├── Form Version 2
│   ├── Status: PUBLISHED
│   ├── Questions: 5
│   └── Responses: 48
│
└── Form Version 3
    ├── Status: DRAFT
    └── Editable by administrators
```

### Publishing workflow

```text
Administrator creates draft
        ↓
Administrator adds or changes questions
        ↓
Administrator previews form
        ↓
Administrator publishes draft
        ↓
Current published version becomes ARCHIVED
        ↓
New version becomes PUBLISHED
        ↓
Session.activeFormVersionId updates
```

### Architectural rule

```text
Published forms are immutable.
Changes require a new draft version.
Responses always retain their original formVersionId.
```

---

## 7. Participant Submission Sequence

```text
Participant          Next.js API         Upstash          Inngest          Neon
    │                    │                  │                │              │
    │ Scan QR code       │                  │                │              │
    │───────────────────>│                  │                │              │
    │ Load form          │───────────────────────────────────────────────>│
    │<───────────────────│       Published form configuration              │
    │                    │                  │                │              │
    │ Submit feedback    │                  │                │              │
    │───────────────────>│                  │                │              │
    │                    │ Hash IP          │                │              │
    │                    │─────────────────>│                │              │
    │                    │ Rate limit check │                │              │
    │                    │<─────────────────│                │              │
    │                    │ Validate form and answers ────────────────────>│
    │                    │<──────────────────────────────────────────────│
    │                    │ Send feedback/submitted event   │              │
    │                    │────────────────────────────────>│              │
    │ 202 Accepted       │                  │                │              │
    │<───────────────────│                  │                │              │
    │                    │                  │                │ Save response│
    │                    │                  │                │─────────────>│
    │                    │                  │                │ Save answers │
    │                    │                  │                │─────────────>│
```

---

## 8. Feedback Submission Security Model

```text
Participant Browser
        ↓
Client-side required-field validation
        ↓
POST /api/feedback
        ↓
Zod request validation
        ↓
Daily salted SHA-256 IP hash
        ↓
Upstash Redis rate limit
        ↓
Session active validation
        ↓
Published form version validation
        ↓
Question ownership validation
        ↓
Answer type and value validation
        ↓
Inngest event dispatch
        ↓
Idempotent Neon persistence
```

### Controls

| Control | Purpose |
|---|---|
| Zod | Validates request structure and types |
| Session validation | Rejects missing or closed sessions |
| Form version validation | Rejects stale or unpublished form submissions |
| Question ownership validation | Prevents answers against unrelated questions |
| Rate limiting | Reduces spam and repeated submissions |
| IP hashing | Supports abuse prevention without storing raw IP |
| Stable submission ID | Supports safe retry behavior |
| Unique `Response.eventId` | Prevents duplicate saved responses |

---

## 9. Background Processing Architecture

```text
┌──────────────────────────────────────────────────────┐
│                     INNGEST EVENTS                    │
├──────────────────────────────────────────────────────┤
│                                                      │
│ feedback/submitted                                   │
│ ├── process-feedback-submission                      │
│ │   ├── save-response-and-answers                    │
│ │   └── record-processing-complete                   │
│ │                                                    │
│ report/generate.pdf                                  │
│ └── generate-pdf-report                              │
│     ├── load-session-analytics                       │
│     ├── render-pdf                                   │
│     ├── store-report                                 │
│     └── update-report-status                         │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### Reliability controls

| Mechanism | Purpose |
|---|---|
| `step.run()` | Tracks individual background workflow steps |
| Retries | Recovers from temporary infrastructure failures |
| Concurrency limits | Protects Neon, storage, and runtime resources |
| Submission IDs | Prevent duplicate response persistence |
| Report status records | Gives administrators visible progress and failure status |

---

## 10. Reporting Architecture

```text
Responses and Answers in Neon
        ↓
Session analytics service
        ↓
┌──────────────────────────────────────────┐
│ Admin Dashboard                          │
│ ├── Total responses                      │
│ ├── Average ratings                      │
│ ├── NPS                                 │
│ ├── Rating distributions                 │
│ ├── Choice distributions                 │
│ └── Written comments                     │
└───────────────┬──────────────────────────┘
                │
       ┌────────┴─────────┐
       ▼                  ▼
┌──────────────┐   ┌─────────────────────┐
│ CSV Export   │   │ PDF Report Request  │
│ Immediate    │   │ Asynchronous        │
└──────────────┘   └─────────┬───────────┘
                              ▼
                         Inngest Worker
                              ▼
                      S3-compatible storage
```

---

## 11. Non-Functional Requirements

| Area | Requirement |
|---|---|
| Availability | Participant form should remain available during event response spikes |
| Performance | Participant route should load quickly on typical mobile networks |
| Interaction latency | Rating and choice selections should feel immediate |
| Security | Server validates all public requests |
| Privacy | Raw participant IP addresses are not stored |
| Reliability | Retries must not create duplicate responses |
| Scalability | Background processing absorbs submission spikes |
| Auditability | Form version IDs preserve historical reporting meaning |
| Accessibility | Form controls support keyboard, screen reader, touch, and zoom use |
| Observability | Logs, Inngest runs, Neon metrics, and alerts support diagnosis |

---

## 12. Recommended Production Infrastructure

| Concern | Recommended Service |
|---|---|
| Web application hosting | Vercel or equivalent Next.js host |
| Database | Neon PostgreSQL |
| ORM and migrations | Prisma |
| Background processing | Inngest |
| Distributed rate limiting | Upstash Redis |
| Report storage | Private S3, Cloudflare R2, or equivalent |
| Error monitoring | Sentry, Axiom, Better Stack, Datadog, or equivalent |
| Domain | Custom HTTPS domain |
| Email notifications | Resend, Postmark, SES, or equivalent |
| Secrets | Hosting-provider secret manager or dedicated secret manager |

---

## 13. Key Risks and Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Participant spam | Incorrect analytics | IP hashing, Upstash Redis rate limits, validation |
| Form changed during feedback | Stale participant submission | Form version validation and `409 Conflict` response |
| Inngest retry duplicates data | Inflated response counts | Stable submission ID and unique `Response.eventId` |
| PDF report generation fails | Admin cannot download report | Report lifecycle status, retries, error visibility |
| Public PDF URL exposes comments | Privacy incident | Private storage and protected signed download URLs |
| Admin shared password compromised | Unauthorized access | Upgrade to named users, MFA, roles, audit logs |
| Large event traffic spike | Slow participant experience | Neon pooling, Inngest queueing, concurrency controls |
| Destructive migration | Data loss | Neon branches, Prisma migration review, recovery plan |

---

## 14. Recommended Future Architecture Enhancements

```text
Phase 1
├── Multi-user administrator accounts
├── Password hashing
├── Role-based access control
├── Audit logging
└── Private signed report downloads

Phase 2
├── Reusable form templates
├── Question library
├── Email and Slack notifications
├── Schedule imports
└── Organization branding

Phase 3
├── Multi-tenant organization support
├── Analytics aggregates for high-volume sessions
├── Webhook integrations
├── AI-assisted qualitative summaries
└── SSO integration
```

---

## 15. Architecture Decision Summary

| Decision | Chosen Approach | Reason |
|---|---|---|
| Database | Neon PostgreSQL | Serverless-friendly managed PostgreSQL |
| ORM | Prisma | Type-safe schema, migrations, and queries |
| Forms | Database-driven versioned forms | Flexible authoring and historical accuracy |
| Participant access | Public QR route | Low-friction anonymous feedback |
| Admin access | Signed HTTP-only session | Secure baseline for protected portal |
| Background work | Inngest | Retries, step tracking, event workflows |
| Rate limiting | Upstash Redis in production | Shared distributed enforcement |
| Reports | Async PDF generation | Avoid browser timeouts |
| Report storage | S3-compatible storage | Durable production file storage |
| Analytics | Query authoritative response data | Simple and correct starting model |

---

## 16. Final Architecture Statement

GreyMatter Feedback is a modular, QR-first feedback platform built around one central principle:

```text
Participants should experience:
Scan → Answer → Submit → Done

Administrators should experience:
Author → Publish → Measure → Improve
```

The architecture supports that principle by using:

```text
Next.js 16 + React 19
        ↓
Neon PostgreSQL + Prisma
        ↓
Inngest background workflows
        ↓
Upstash rate limiting
        ↓
S3-compatible report storage
```

This design provides flexible event-specific forms, reliable anonymous submissions, historically accurate reporting, and a clear path from beginner implementation to production-scale operation.
