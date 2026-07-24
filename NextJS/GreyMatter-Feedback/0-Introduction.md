# Part 0: Introduction

Welcome to the **GreyMatter Feedback** tutorial series.

In this series, you will build a complete, production-minded QR-code feedback application from scratch. The application will let organizers create feedback sessions, display or print session-specific QR codes, collect anonymous participant feedback on mobile devices, analyze results in an admin portal, export raw data to CSV, and generate PDF reports asynchronously.

> **Tutorial requirement noted:** We will use **Neon** as the hosted PostgreSQL database provider throughout this series, with **Prisma** as the type-safe database toolkit.

I have also noted the core requirements for the remaining parts of this tutorial series:

- Build **GreyMatter Feedback** from beginning to end, one part at a time.
- Use **Next.js 16 App Router**, **React 19**, **TypeScript**, and **Tailwind CSS**.
- Use **Neon PostgreSQL** with **Prisma**.
- Use **Inngest** for background jobs and asynchronous report generation.
- Provide beginner-friendly explanations while maintaining production-grade architecture and security.
- Make the tutorial code-heavy, with complete copy-pasteable file contents.
- Avoid placeholders, omitted implementation, and unexplained dependencies.
- For every technical step, include:
  1. **The Target**
  2. **The Concept**
  3. **The Implementation**
  4. **The Verification**
- Include clear generation logs between tutorial parts.
- Build participant feedback flows, an admin dashboard, QR generation, CSV export, background PDF reporting, privacy-aware abuse prevention, and offline-friendly form behavior.

---

## What Is GreyMatter Feedback?

**GreyMatter Feedback** is a feedback platform for workshops, lectures, conferences, training sessions, company meetings, customer events, and similar in-person experiences.

Its central idea is simple:

1. An organizer creates a feedback session.
2. The system generates a QR code for that session.
3. Participants scan the QR code with their phones.
4. They answer a short, mobile-friendly feedback form.
5. Organizers review analytics and export reports.

For example, an event organizer running a React workshop might create:

```text
Event: React Summit 2026
Session: Advanced React Patterns
Session ID: REACT-2026-Q3
```

GreyMatter Feedback generates a QR code that points to a URL like:

```text
https://feedback.example.com/e/REACT-2026-Q3?src=qr
```

When a participant scans that code, their phone opens the feedback form specifically configured for that session.

---

## The Problem GreyMatter Feedback Solves

Traditional feedback collection often creates unnecessary friction:

- Paper forms are slow to distribute and manually process.
- Generic web forms require attendees to find or type a URL.
- Spreadsheet analysis is time-consuming.
- Report generation is repetitive.
- Participants may be reluctant to share honest feedback if they think they can be personally identified.

GreyMatter Feedback reduces that friction.

The QR code acts like a direct door to the right form. Participants do not need an account, an app installation, or a complicated sign-in process. They scan, respond, and submit.

Meanwhile, administrators get useful information without manually combining paper forms or spreadsheets.

---

## What We Will Build

By the end of the series, GreyMatter Feedback will include two major application areas.

## 1. Participant Feedback Experience

Participants will open a route such as:

```text
/e/REACT-2026-Q3
```

This route will load the correct session details and questions from the database.

The feedback form will support four question types:

| Question type | Example |
|---|---|
| Rating | “How would you rate this session?” on a 1–5 scale |
| NPS | “How likely are you to recommend this session?” on a 0–10 scale |
| Choice | “Which part was most useful?” |
| Text | “What could we improve?” |

The participant experience will be optimized for phones:

- Large, easy-to-tap controls.
- A minimum 48-by-48 pixel touch target for interactive controls.
- Form input text sized to avoid unwanted mobile browser zoom.
- Haptic feedback on rating selection where the device supports vibration.
- Browser-based draft persistence, so an accidental refresh or dismissal does not erase answers.
- Fast submission feedback using React 19 patterns.
- Clear handling for inactive, missing, or unavailable sessions.

---

## 2. Administrator Portal

The administrator side of the application will include routes such as:

```text
/admin/sessions/REACT-2026-Q3
```

Administrators will be able to:

- Review total response counts.
- View average ratings for each question.
- View rating distributions.
- Calculate Net Promoter Score, or **NPS**.
- Read text feedback.
- Download a QR code for the session.
- Export response data as a CSV file.
- Trigger a PDF report generation job.
- View the status and download link for completed reports.

**Net Promoter Score** measures how likely people are to recommend an experience. It is calculated by grouping 0–10 answers into:

- **Promoters:** scores of 9 or 10.
- **Passives:** scores of 7 or 8.
- **Detractors:** scores from 0 through 6.

The formula is:

```text
NPS = percentage of promoters - percentage of detractors
```

The final score ranges from `-100` to `100`.

---

## Final System Architecture

GreyMatter Feedback will use an architecture that keeps participant submissions quick while safely moving slower work into background jobs.

```text
┌────────────────────────────┐
│ Participant Phone          │
│                            │
│ Scans session QR code      │
└──────────────┬─────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│ Next.js 16 Application                                │
│                                                      │
│ /e/[sessionId]                                       │
│ Mobile-first participant feedback form               │
│                                                      │
│ /admin/*                                             │
│ Protected analytics and reporting portal             │
│                                                      │
│ /api/feedback                                        │
│ Validates and accepts feedback submission requests   │
└──────────────┬───────────────────────────────────────┘
               │
               │ Sends background events
               ▼
┌──────────────────────────────────────────────────────┐
│ Inngest                                              │
│                                                      │
│ • Processes submitted feedback                       │
│ • Handles safe retries                               │
│ • Generates PDF reports asynchronously               │
└──────────────┬───────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────┐
│ Neon PostgreSQL                                      │
│                                                      │
│ Hosted serverless PostgreSQL database                │
│ accessed through Prisma                              │
│                                                      │
│ Stores events, sessions, questions, answers,         │
│ responses, and generated report records              │
└──────────────────────────────────────────────────────┘
```

Think of this system like an event venue:

- **Next.js** is the reception desk. It welcomes participants and administrators, displays the right screens, and receives requests.
- **Neon PostgreSQL** is the secure records room. It stores structured data reliably and durably.
- **Prisma** is the trained clerk who translates our TypeScript code into safe database operations.
- **Inngest** is the operations coordinator. It gives slow or heavy jobs—such as PDF generation—to the back-office workflow so participants do not have to wait.
- **QR codes** are printed directions that take each participant directly to the correct room.

---

## Why Neon?

We will use **Neon** for the application database.

Neon is a managed, serverless PostgreSQL platform. It gives us a real PostgreSQL database without requiring us to install, update, secure, back up, and operate a database server ourselves.

For this tutorial, Neon is a strong fit because it provides:

- Hosted PostgreSQL compatible with Prisma.
- A secure database connection string.
- A simple developer experience.
- Serverless-friendly connection behavior.
- A free tier suitable for learning and early prototypes.
- Branching capabilities that can be useful for safely testing database changes.

Instead of running PostgreSQL in Docker, you will create a Neon project and place its connection string in an environment variable:

```dotenv
DATABASE_URL="postgresql://..."
```

The application will use this URL privately on the server. It will never be exposed to participant browsers.

---

## The Core Data Model

Before implementation, it is useful to understand the data GreyMatter Feedback needs to track.

```text
Event
  └── Session
        ├── Question
        ├── Response
        │     └── Answer
        └── Report
```

Each item has a clear responsibility:

| Model | Responsibility |
|---|---|
| Event | A parent event, such as “React Summit 2026” |
| Session | A specific workshop, talk, lesson, or meeting with its own QR code |
| Question | A configured question shown for one session |
| Response | One completed participant form submission |
| Answer | A single answer within a response |
| Report | The status and location of a generated PDF report |

For example:

```text
Event
└── React Summit 2026
    └── Advanced React Patterns
        ├── “How would you rate the session?”
        ├── “How likely are you to recommend it?”
        └── “What should we improve?”
```

When a participant submits the form, GreyMatter Feedback stores one `Response` record and several related `Answer` records.

---

## Participant Submission Flow

The participant’s journey will follow this sequence:

```text
1. Scan QR code
2. Open session URL
3. Load session and question configuration
4. Fill out feedback form
5. Save drafts locally while answering
6. Submit validated answers
7. Receive immediate confirmation
8. Process heavier work asynchronously
```

The important performance principle is that the phone should not wait for expensive work.

For example, PDF generation could take seconds. The participant does not need to wait for that. Their submission should be acknowledged quickly, while Inngest performs related background tasks independently.

---

## Background Job Flow

When feedback is submitted, the application will send an event to Inngest:

```text
feedback/submitted
```

An Inngest function will then process that event. It will:

1. Verify the submission data.
2. Save the response and answers safely.
3. Prevent duplicate records during retries.
4. Prepare data for analytics.
5. Make later reporting tasks possible.

When an administrator requests a report, the application will send another event:

```text
report/generate.pdf
```

A second Inngest function will:

1. Read session analytics from Neon.
2. Render a PDF executive summary.
3. Store the finished report.
4. Update the report status.
5. Make the download URL available in the admin portal.

---

## Security and Privacy Principles

Feedback is often sensitive. Participants should feel safe providing honest feedback, and administrators should be able to trust that the data is valid.

GreyMatter Feedback will include the following protections:

### Anonymous participant access

Participants will not need accounts to submit feedback. This keeps the QR flow simple and supports candid responses.

### Privacy-preserving IP handling

We will not store a participant’s raw IP address.

Instead, we will create a daily salted SHA-256 hash. A **hash** is a one-way fingerprint of data. It can help us identify repeated requests for rate limiting without retaining the original IP address.

### Rate limiting

Rate limiting controls how frequently a client can submit requests. It is like a venue rule that prevents one person from repeatedly dropping hundreds of forms into a suggestion box.

We will use the hashed IP value and session context to reduce spam.

### Input validation

Every browser request can be modified by a malicious or broken client. Therefore, server-side code—not browser code—will be responsible for deciding whether submitted data is valid.

We will use **Zod** to validate:

- Session identifiers.
- Question identifiers.
- Numeric score ranges.
- Choice options.
- Text lengths.
- Required answers.

### Protected admin access

The admin portal will require authentication. We will use secure, signed sessions stored in HTTP-only cookies.

An **HTTP-only cookie** is a browser cookie JavaScript cannot read. This reduces the damage that could be caused by certain cross-site scripting attacks.

### Idempotent background jobs

Network requests and background jobs can occasionally be retried. An **idempotent** operation can run more than once without creating duplicate results.

We will assign each submission a unique event ID so retrying a job does not create duplicate feedback responses.

---

## What You Will Learn

After completing the complete tutorial series, you will understand how to:

1. Create a modern Next.js 16 App Router project.
2. Use React 19 for responsive form state and optimistic interactions.
3. Style a mobile-first interface with Tailwind CSS.
4. Create and configure a Neon PostgreSQL database.
5. Connect Prisma to Neon safely.
6. Model relational data with Prisma.
7. Create dynamic routes using `app/e/[sessionId]`.
8. Build a configuration-driven feedback form.
9. Save and restore form drafts with browser localStorage.
10. Create secure API routes.
11. Validate untrusted input with Zod.
12. Apply privacy-aware IP hashing and rate limiting.
13. Build a protected administrator portal.
14. Generate QR code images.
15. Calculate ratings and NPS metrics.
16. Stream CSV downloads from the server.
17. Use Inngest for reliable background work.
18. Generate PDF reports with React PDF.
19. Store generated report files locally during development and in S3-compatible storage in production.
20. Add offline-aware behavior through a service worker and retry-friendly submission design.
21. Prepare the application for deployment.

---

## How the Series Is Organized

The series will move from foundation to finished product in a deliberate order.

| Part | Focus |
|---|---|
| Part 0 | Introduction, architecture, requirements, and learning path |
| Part 1 | Next.js setup, Neon configuration, Prisma schema, and project foundation |
| Part 2 | Database access layer, seed data, session queries, and dynamic participant route |
| Part 3 | Mobile-first participant form, question types, local draft persistence, and haptic feedback |
| Part 4 | Secure feedback API, validation, IP hashing, and rate limiting |
| Part 5 | Inngest events and reliable submission-processing workflow |
| Part 6 | Admin authentication, dashboard layout, analytics metrics, and QR export |
| Part 7 | CSV exports and asynchronous PDF report generation |
| Part 8 | File storage, offline support, testing, security review, and production deployment |

Each technical section will contain:

1. **The Target** — exactly what we are building.
2. **The Concept** — why it works, explained simply.
3. **The Implementation** — complete files and commands.
4. **The Verification** — a concrete way to prove the step worked before continuing.

---

## Prerequisites

Before starting Part 1, make sure you have:

- Node.js 20.9 or later.
- npm, pnpm, or another Node package manager.
- A GitHub account or email address for creating a Neon account.
- A Neon account and project. We will create/configure this during the tutorial.
- A code editor, such as Visual Studio Code.
- A terminal.
- Basic familiarity with JavaScript or TypeScript syntax.

You do **not** need prior experience with Prisma, Neon, Inngest, QR-code generation, or PDF generation.

---

## A Note About Production Readiness

This tutorial will build a strong foundation suitable for real applications, including validation, error handling, privacy-aware identifiers, background job retries, protected admin access, and environment-based configuration.

However, production systems always require a final review tailored to their environment. Before handling sensitive or high-volume feedback in production, you should also consider:

- Legal and privacy obligations in your jurisdiction.
- Accessibility testing with real users.
- Monitoring and alerting.
- Database backup and recovery policies.
- A stronger multi-user administration and role system.
- Email delivery configuration.
- A managed rate-limiting provider such as Upstash Redis.
- File storage lifecycle policies.
- Load testing for expected event traffic.

We will call out these boundaries as we build.

---

GreyMatter Feedback is now fully defined: a fast, QR-first participant feedback platform backed by **Next.js**, **Neon PostgreSQL**, **Prisma**, and **Inngest**.
