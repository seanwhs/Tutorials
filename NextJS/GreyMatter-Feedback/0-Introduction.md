# Part 0: Introduction

Welcome to the **GreyMatter Feedback** tutorial series.

In this series, you will build a complete QR-code feedback platform for events, courses, workshops, conferences, training programs, and internal meetings.

GreyMatter Feedback lets an organizer create a feedback form for a specific event session, publish it, generate a QR code, and collect participant responses through a mobile-friendly web page. Administrators can then review analytics, read written feedback, export responses as CSV, and generate executive PDF reports.

The final application will use:

- **Next.js 16** with the App Router
- **React 19**
- **TypeScript**
- **Tailwind CSS**
- **Neon PostgreSQL**
- **Prisma**
- **Inngest**
- **QR-code generation**
- **React PDF**
- **Optional S3-compatible file storage** for production reports

---

## What Is GreyMatter Feedback?

GreyMatter Feedback is a feedback collection and reporting system designed around a simple participant experience:

1. An organizer displays or prints a QR code.
2. A participant scans the QR code with their phone.
3. The phone opens the correct feedback form.
4. The participant submits ratings, choices, and comments.
5. Administrators review results and generate reports.

For example, an organization may run a course called:

```text
React Fundamentals
```

That course may contain several feedback targets:

```text
React Fundamentals
├── Module 1: Components
├── Module 2: State and Effects
├── Module 3: Data Fetching
└── End-of-course Evaluation
```

Each target can have its own QR code and its own feedback form.

```text
/e/REACT-MODULE-1
/e/REACT-MODULE-2
/e/REACT-MODULE-3
/e/REACT-FINAL
```

This same model works for a conference:

```text
Annual Product Conference
├── Opening Keynote
├── Product Strategy Panel
├── Customer Success Workshop
└── Closing Session
```

Or for a company training program:

```text
Leadership Essentials
├── Week 1: Communication
├── Week 2: Delegation
└── Week 3: Performance Conversations
```

---

## The Main Idea: Every Session Can Have a Different Form

GreyMatter Feedback does **not** use one hard-coded feedback form for every event.

Instead, forms are **configuration-driven**.

A configuration-driven system stores the form definition in the database. The application reads that definition and renders the appropriate fields dynamically.

For example, a short workshop form may look like this:

```text
1. How useful was this workshop?                Rating, 1–5
2. How likely are you to recommend it?          NPS, 0–10
3. What should we improve?                      Text
```

A course evaluation form may be more detailed:

```text
1. How clear was the instructor?                Rating, 1–5
2. How useful were the course materials?        Rating, 1–5
3. Was the pace appropriate?                    Choice
4. Which topic needs more explanation?          Choice
5. What was most valuable?                      Text
6. What should change next time?                Text
```

The participant-facing application stays reusable. It does not need a new page or code deployment every time an administrator creates a different form.

Instead, the QR URL identifies a session:

```text
https://feedback.example.com/e/REACT-2026-Q3?src=qr
```

The application loads the published form assigned to that session and renders its questions.

---

## Form Authoring Environment

GreyMatter Feedback will include a protected administrator environment for creating and managing feedback forms.

This is not an external form builder. It is a first-class feature built directly into the GreyMatter admin portal.

Administrators will be able to:

- Create events or courses.
- Create sessions inside an event or course.
- Give each session a QR-friendly identifier.
- Create a feedback form draft.
- Add questions.
- Choose question types.
- Add choice options.
- Mark questions as required or optional.
- Set rating scales and limits.
- Reorder questions.
- Preview the participant form.
- Publish a form.
- Generate and download a QR code.
- Deactivate a session when feedback collection ends.
- Review results and export reports.

A future administrator authoring screen will resemble this:

```text
Session: Advanced React Patterns
Session ID: REACT-2026-Q3
Form status: Draft

Question 1
Type: Rating
Prompt: How useful was this workshop?
Scale: 1 to 5
Required: Yes

Question 2
Type: NPS
Prompt: How likely are you to recommend this workshop?
Scale: 0 to 10
Required: Yes

Question 3
Type: Choice
Prompt: Which section was most valuable?
Options:
- Server Components
- Data Fetching
- Performance
Required: No

Question 4
Type: Text
Prompt: What should we improve?
Maximum length: 1,500 characters
Required: No

[ Save Draft ] [ Preview ] [ Publish ]
```

---

## Why GreyMatter Feedback Uses a Built-In Form Authoring System

The tutorial will use **Neon PostgreSQL and Prisma** as the authoritative source of truth for both:

1. Form definitions.
2. Participant responses.

We considered using a headless CMS such as Sanity for form authoring. Sanity is a strong tool for editorial content, but it is not the preferred baseline architecture for this application.

Feedback forms are deeply tied to transactional data:

- Responses.
- Answers.
- Rating averages.
- NPS calculations.
- CSV exports.
- PDF reports.
- Question-level analytics.
- Historical reporting accuracy.

If form definitions were stored in Sanity while responses lived in Neon, the system would need synchronization between two sources of truth:

```text
Sanity
└── Form definitions and publishing

Neon
└── Responses, answers, analytics, and reports
```

This would add complexity around:

- Synchronization failures.
- Published form snapshots.
- Question changes after responses exist.
- Duplicate validation logic.
- Runtime dependency on another external service.

Instead, GreyMatter Feedback will keep the form authoring workflow close to the feedback data:

```text
GreyMatter Admin Portal
        |
        v
Neon PostgreSQL via Prisma
├── Events
├── Sessions
├── Form versions
├── Questions
├── Responses
├── Answers
└── Reports
```

This gives us one consistent system for authoring, publishing, submitting, analyzing, exporting, and reporting.

---

## Drafts, Publishing, and Form Versioning

A feedback form must not silently change after people have responded to it.

Consider this example.

A form initially contains:

```text
How would you rate the instructor?
```

After 100 responses, an administrator changes the same question to:

```text
How would you rate the venue?
```

If the old answers remain attached to that same question, the resulting report becomes misleading. It would combine instructor ratings and venue ratings.

To prevent this, GreyMatter Feedback will use **form versioning**.

A form version is a snapshot of a form at a particular point in time.

```text
Session: REACT-2026-Q3
├── Version 1 — Published
│   ├── “How useful was this workshop?”
│   ├── “How likely are you to recommend it?”
│   └── “What should we improve?”
│
└── Version 2 — Draft
    ├── “How useful was this workshop?”
    ├── “How likely are you to recommend it?”
    ├── “How useful was the hands-on exercise?”
    └── “What should we improve?”
```

The workflow will be:

```text
Create session
   ↓
Create editable draft form version
   ↓
Add and configure questions
   ↓
Preview on desktop and mobile
   ↓
Publish the form version
   ↓
Generate/share session QR code
   ↓
Participants submit feedback
   ↓
Published version becomes historically protected
   ↓
Create a new draft version if future changes are needed
```

Each participant response will record which exact form version it used.

That means GreyMatter Feedback can always accurately answer questions such as:

```text
Which wording did participants see?
Which options were available?
Which rating scale was used?
Which version produced these analytics?
```

---

## Form Statuses

Forms will use clear lifecycle states.

| Status | Meaning |
|---|---|
| `DRAFT` | Editable by administrators but unavailable to participants |
| `PUBLISHED` | Live and available to participants through the session QR URL |
| `ARCHIVED` | Retained for historical reporting but no longer active |

A session itself will also have an active/inactive state.

```text
Session active + published form = accepts feedback
Session inactive = displays a polite “feedback is closed” message
No published form = participant cannot access an unfinished draft
```

---

## The Final Product

By the end of the tutorial series, you will have built two connected experiences.

## 1. Participant Experience

Participants will visit a route like:

```text
/e/REACT-2026-Q3
```

They will receive a fast, mobile-first form containing the questions from the session’s active published form version.

The form will support:

| Question type | Example |
|---|---|
| Rating | “How would you rate this session?” |
| NPS | “How likely are you to recommend this session?” |
| Choice | “Which section was most useful?” |
| Text | “What should we improve?” |

The participant experience will include:

- Large touch-friendly controls.
- A minimum interactive touch target of 48 by 48 pixels.
- Input font sizes that avoid mobile browser auto-zoom.
- Haptic feedback on supported devices.
- Local draft persistence in the browser.
- Server-side validation.
- Fast feedback submission confirmation.
- Clear errors for unavailable, inactive, or unpublished sessions.
- Privacy-aware abuse protection.

## 2. Administrator Experience

Administrators will access protected routes such as:

```text
/admin/events
/admin/events/new
/admin/sessions/REACT-2026-Q3/edit
/admin/sessions/REACT-2026-Q3
```

They will be able to:

- Create events and courses.
- Create sessions.
- Author and publish feedback forms.
- Preview forms.
- Download QR codes.
- View total submissions.
- Review average scores.
- Review score distributions.
- Calculate NPS.
- Read text feedback.
- Export CSV files.
- Request PDF reports.
- Download completed PDF reports.

---

## Final System Architecture

GreyMatter Feedback will use a modern architecture that separates fast participant interactions from slower background work.

```text
┌────────────────────────────┐
│ Participant Phone          │
│                            │
│ Scans QR code              │
└──────────────┬─────────────┘
               │
               ▼
┌──────────────────────────────────────────────────┐
│ Next.js 16 App Router                            │
│                                                  │
│ /e/[sessionId]                                   │
│ Dynamic participant feedback form                │
│                                                  │
│ /admin/*                                         │
│ Protected form authoring and analytics portal    │
│                                                  │
│ /api/feedback                                    │
│ Secure submission endpoint                       │
└──────────────┬───────────────────────────────────┘
               │
               │ sends events
               ▼
┌──────────────────────────────────────────────────┐
│ Inngest                                          │
│                                                  │
│ • Process submitted feedback                     │
│ • Retry temporary failures safely                │
│ • Generate PDF reports asynchronously            │
└──────────────┬───────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────┐
│ Neon PostgreSQL + Prisma                         │
│                                                  │
│ Events                                           │
│ Sessions                                         │
│ Form versions                                    │
│ Questions                                        │
│ Responses                                        │
│ Answers                                          │
│ Reports                                          │
└──────────────────────────────────────────────────┘
```

A useful analogy is an event venue:

- **Next.js** is the reception desk where participants and administrators arrive.
- **Neon PostgreSQL** is the secure records room.
- **Prisma** is the trained clerk who safely translates application requests into database operations.
- **Inngest** is the operations team that takes slow tasks away from the reception desk.
- **QR codes** are direct signs pointing participants to the right feedback room.
- **Form versions** are archived copies of official event materials, ensuring that historical records remain accurate.

---

## Why Neon PostgreSQL?

GreyMatter Feedback will use **Neon** as its PostgreSQL provider.

Neon is managed, serverless PostgreSQL. It gives us a real PostgreSQL database without requiring us to install, update, secure, back up, or operate a database server ourselves.

Neon is well suited to this project because it provides:

- PostgreSQL compatibility.
- Secure connection strings.
- Serverless-friendly pooled connections.
- A strong free tier for learning and prototypes.
- Database branching for safe experimentation.
- Compatibility with Prisma.

The application will use environment variables for database access:

```dotenv
DATABASE_URL="postgresql://..."
DIRECT_URL="postgresql://..."
```

The pooled connection URL will be used by the running application. The direct URL will be used by Prisma migrations.

Neither value will be exposed to browsers.

---

## Core Data Model

The final data model will look like this:

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

More specifically:

```text
Event
  └── Session
        ├── FormVersion
        │     └── Question
        │
        ├── Response
        │     ├── formVersionId
        │     └── Answer
        │
        └── Report
```

| Record | Responsibility |
|---|---|
| Event | Parent grouping for a course, conference, program, or event |
| Session | A specific workshop, lesson, talk, or feedback target with a QR URL |
| FormVersion | A draft, published, or archived snapshot of a session form |
| Question | A configured field in a single form version |
| Response | One completed participant submission |
| Answer | One participant answer for one question |
| Report | A requested, processing, completed, or failed PDF report |

---

## Background Processing with Inngest

Participants should never need to wait for heavy work after submitting a form.

When a participant submits feedback, the application will create an Inngest event:

```text
feedback/submitted
```

A background function will:

1. Validate and safely save the submission.
2. Use idempotency protections to avoid duplicate responses during retries.
3. Prepare data for later analytics and reporting.
4. Handle temporary failures without requiring the participant to submit again.

When an administrator requests a PDF report, the application will create another event:

```text
report/generate.pdf
```

A report-generation function will:

1. Fetch analytics for the selected session.
2. Generate a PDF executive summary.
3. Store the generated file.
4. Update report status.
5. Make the download URL available to administrators.

---

## Security and Privacy Principles

GreyMatter Feedback is intended to collect honest feedback without unnecessarily collecting participant identity.

The application will include these protections.

### Anonymous participant access

Participants do not need accounts. A QR scan should lead directly to the relevant form.

### Privacy-preserving IP hashing

The system will not store raw IP addresses.

Instead, it will derive a daily salted SHA-256 hash from the client IP address. A hash is a one-way fingerprint. It can help detect repeated requests without retaining the original IP address.

### Rate limiting

Rate limiting prevents spam by limiting how often a client can submit a form.

Think of it as a rule that stops one person from dropping hundreds of completed slips into a physical feedback box.

### Server-side validation

The browser is helpful for user experience, but it cannot be trusted as a security boundary. The API will validate all submitted data using Zod before it is accepted.

### Protected admin access

The form authoring environment, analytics dashboard, and exports will require administrator authentication through secure signed sessions.

### Idempotent background jobs

Background work can be retried after a temporary network or provider failure. The system will use unique event identifiers so a retry does not create duplicate responses.

---

## What You Will Learn

By the end of this tutorial series, you will know how to:

1. Create a Next.js 16 App Router application.
2. Configure Tailwind CSS and shared layouts.
3. Set up Neon PostgreSQL.
4. Connect Prisma to Neon.
5. Design relational schemas for dynamic forms and response data.
6. Build a form versioning and publishing workflow.
7. Create a protected admin form authoring environment.
8. Build dynamic participant routes using `app/e/[sessionId]`.
9. Render different question types from stored configuration.
10. Build mobile-first forms with React 19.
11. Save draft answers in browser localStorage.
12. Add haptic feedback on compatible devices.
13. Validate submissions with Zod.
14. Implement privacy-aware IP hashing and rate limiting.
15. Use Inngest for reliable background processing.
16. Calculate rating averages and NPS.
17. Generate QR-code images.
18. Export response data to CSV.
19. Generate PDF reports asynchronously.
20. Store report files locally during development and in S3-compatible storage in production.
21. Add offline-aware behavior and retry-friendly submission flows.
22. Prepare the application for deployment.

---

## Tutorial Structure

The series will proceed in this order.

| Part | Focus |
|---|---|
| Part 0 | Product scope, architecture, dynamic forms, authoring environment, and versioning strategy |
| Part 1 | Next.js setup, Neon configuration, Prisma setup, and versioned database schema |
| Part 2 | Database query layer, seed data, form lifecycle helpers, and participant session route |
| Part 3 | Admin authentication and form authoring environment |
| Part 4 | Participant mobile form, question rendering, draft persistence, and haptic feedback |
| Part 5 | Secure feedback API, validation, privacy hashing, and rate limiting |
| Part 6 | Inngest submission processing and resilient background workflows |
| Part 7 | Admin analytics dashboard, QR exports, and CSV exports |
| Part 8 | PDF report generation, file storage, offline support, testing, and deployment |

Every technical implementation step will include:

1. **The Target** — the file, feature, or configuration being built.
2. **The Concept** — a short plain-language explanation.
3. **The Implementation** — complete code and exact file paths.
4. **The Verification** — commands or browser steps to prove the work succeeded.

---

## Prerequisites

Before beginning Part 1, you should have:

- Node.js 20.9 or later.
- npm, pnpm, or another Node.js package manager.
- A code editor such as Visual Studio Code.
- A terminal.
- A Neon account.
- Basic familiarity with JavaScript or TypeScript.

You do not need previous experience with Neon, Prisma, Inngest, QR-code generation, PDF generation, or form versioning.

---

## Production Note

This tutorial will build a strong production-oriented foundation, including validation, versioning, error handling, privacy-aware design, authentication, and retry-safe background workflows.

Before using GreyMatter Feedback for large-scale or sensitive production data, also plan for:

- A legal and privacy review.
- Accessibility testing.
- Monitoring and alerting.
- Managed rate limiting, such as Upstash Redis.
- Backups and disaster recovery.
- Multi-user administrator roles and permissions.
- Email delivery for report completion notifications.
- Load testing before major events.
- Security review of deployment configuration.

---

GreyMatter Feedback is now defined as a flexible, QR-first feedback platform with a built-in authoring environment, versioned forms, reliable reporting, and a single source of truth in Neon PostgreSQL.
