# Appendix O: GreyMatter Feedback Glossary

This glossary defines important terms used throughout the GreyMatter Feedback tutorial series.

---

## Admin portal

The protected area of GreyMatter Feedback where organizers can create events, author forms, publish versions, view analytics, export CSV files, and request PDF reports.

Example route:

```text
/admin/events
```

---

## Answer

One participant response to one question.

For example:

```text
Question:
How useful was this workshop?

Answer:
5
```

A full participant submission contains one `Response` and one or more related `Answer` records.

---

## API route

A server endpoint that receives or returns data over HTTP.

Example:

```text
POST /api/feedback
```

GreyMatter Feedback uses this route to accept participant feedback submissions.

---

## App Router

Next.js’s file-based routing system based on the `app/` directory.

For example:

```text
src/app/e/[sessionId]/page.tsx
```

creates a dynamic participant route like:

```text
/e/REACT-2026-Q3
```

---

## Background job

Work performed outside the immediate browser request.

GreyMatter Feedback uses background jobs for:

```text
Saving accepted feedback safely
Retrying failed processing
Generating PDF reports
Uploading PDF files
Sending future notifications
```

Inngest manages these jobs.

---

## Choice question

A question where the participant selects one predefined option.

Example:

```text
Which part of the workshop was most valuable?

- Live demonstration
- Hands-on exercises
- Group discussion
- Reference materials
```

In GreyMatter Feedback, choice answers are stored in `Answer.textValue`.

---

## Client Component

A React component that runs in the browser.

Client Components are needed for browser-only behavior such as:

```text
Button clicks
localStorage
navigator.vibrate()
Fetching from APIs
Interactive form state
```

They begin with:

```tsx
"use client";
```

Example:

```text
src/components/participant/feedback-form.tsx
```

---

## CSV

Comma-Separated Values.

A plain-text spreadsheet format supported by Excel, Google Sheets, LibreOffice, and analytics tools.

GreyMatter Feedback exports one answer per CSV row so exports remain flexible across different form versions.

---

## Dynamic route

A route that uses a variable URL segment.

Example file:

```text
src/app/e/[sessionId]/page.tsx
```

Example URL:

```text
/e/REACT-2026-Q3
```

Here, `REACT-2026-Q3` is the dynamic `sessionId`.

---

## Event

A parent container for courses, conferences, training programs, workshops, or similar activities.

Example:

```text
Event:
React Summit 2026
```

An event contains one or more sessions.

---

## Feedback form

The participant-facing set of questions for one session.

A form is created as a draft, then published as a versioned form.

---

## Form authoring

The administrator workflow used to create and manage a feedback form.

Typical form authoring tasks include:

```text
Create questions
Choose question types
Set rating scales
Add choice options
Mark questions required
Change question order
Preview the form
Publish the form
```

---

## Form version

A snapshot of a session feedback form.

Form versions protect historical reporting accuracy.

```text
Version 1:
Published in January

Version 2:
Published in February
```

Each participant response records the version that was displayed when it was submitted.

---

## Inngest

A background job orchestration platform.

GreyMatter Feedback uses Inngest for events such as:

```text
feedback/submitted
report/generate.pdf
```

Inngest provides retries, job visibility, step tracking, and reliable asynchronous processing.

---

## IP hash

A privacy-aware, one-way identifier derived from a participant IP address.

GreyMatter Feedback does not store raw IP addresses. Instead, it calculates a daily salted SHA-256 hash.

The hash helps limit repeated submissions without retaining the original IP address.

---

## Local draft

Unsubmitted participant answers stored in the browser’s localStorage.

Drafts help participants recover answers after:

```text
Page refresh
Accidental browser close
Temporary network failure
```

Drafts are scoped to both session ID and form version ID.

---

## localStorage

Persistent browser storage available to JavaScript on the current device and browser.

GreyMatter Feedback uses it for:

```text
Participant answer drafts
Stable submission IDs
Offline submission outbox records
```

It must not be used for passwords, database URLs, or private server secrets.

---

## NPS

Net Promoter Score.

A recommendation metric based on a 0–10 answer.

```text
Promoters: 9–10
Passives: 7–8
Detractors: 0–6
```

Formula:

```text
NPS = percentage of promoters - percentage of detractors
```

NPS ranges from:

```text
-100 to +100
```

---

## Neon

A managed serverless PostgreSQL provider.

GreyMatter Feedback uses Neon for:

```text
Events
Sessions
Form versions
Questions
Responses
Answers
Reports
```

Neon provides pooled and direct PostgreSQL connection strings.

---

## Participant

A person who scans a QR code or opens a feedback URL and completes a feedback form.

Participants do not need an account in the baseline GreyMatter Feedback design.

---

## Prisma

A TypeScript database toolkit.

Prisma provides:

```text
Database schema definition
Database migrations
Generated TypeScript client
Typed database queries
```

GreyMatter Feedback uses Prisma to access Neon PostgreSQL.

---

## Published form

A form version that is available to participants.

A participant route renders only a form when:

```text
Session is active
AND
Session has activeFormVersionId
AND
Active form version status is PUBLISHED
```

Published forms should not be edited directly.

---

## QR code

A square scannable image that encodes a URL.

GreyMatter Feedback QR codes usually encode a participant session URL:

```text
https://feedback.example.com/e/REACT-2026-Q3?src=qr
```

---

## Rate limiting

A protection that controls how frequently a client can submit requests.

GreyMatter Feedback uses rate limiting to reduce spam and repeated form submissions.

Example policy:

```text
One submission per session per client every five minutes
```

Production rate limiting should use shared infrastructure such as Upstash Redis.

---

## Report

A requested or generated PDF summary of session feedback.

A report record has one of these states:

```text
QUEUED
PROCESSING
COMPLETE
FAILED
```

---

## Response

One complete participant feedback submission.

A response records:

```text
Session
Form version
Submission time
Privacy-aware client hash
Safe metadata
Answers
```

---

## Server Action

A Next.js server-side function invoked from a React form.

GreyMatter Feedback uses Server Actions for protected administrative workflows such as:

```text
Creating events
Creating sessions
Adding questions
Publishing forms
Closing sessions
Signing in
```

---

## Server Component

A React component rendered on the server.

Server Components can safely access server-only resources such as Prisma and Neon.

Example:

```text
src/app/e/[sessionId]/page.tsx
```

The participant route loads published form data on the server, then passes safe data to interactive Client Components.

---

## Session

A specific feedback target with its own stable participant URL and QR code.

Examples:

```text
Opening Keynote
Module 1 — Type Basics
Advanced React Patterns
End-of-course Evaluation
```

A session belongs to one event and can have many form versions and responses.

---

## SHA-256

A cryptographic hashing algorithm.

GreyMatter Feedback uses SHA-256 to produce a daily salted fingerprint of a client IP address.

SHA-256 is one-way: it is designed to make recovering the original value impractical.

---

## S3-compatible storage

Object storage that supports the Amazon S3 API.

GreyMatter Feedback can use S3-compatible storage for generated PDF reports.

Compatible providers include:

```text
Amazon S3
Cloudflare R2
Backblaze B2
MinIO
DigitalOcean Spaces
```

---

## Session ID

A readable unique identifier used in participant URLs and QR codes.

Example:

```text
REACT-2026-Q3
```

It becomes part of the URL:

```text
/e/REACT-2026-Q3
```

GreyMatter Feedback restricts session IDs to letters, numbers, and hyphens.

---

## Upstash Redis

A serverless Redis provider.

GreyMatter Feedback uses Upstash Redis in production for distributed rate limiting.

This is important because multiple serverless application instances may process participant submissions.

---

## Zod

A TypeScript validation library.

GreyMatter Feedback uses Zod to validate:

```text
Environment variables
Administrator authoring input
Participant feedback submission JSON
Question settings
Choice options
Visibility rules
```

Zod prevents invalid or malicious data from reaching the database or background jobs.

---

## Final terminology map

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

```text
Participant
  └── Scans QR code
        └── Opens session URL
              └── Completes published form version
                    └── Creates response and answers
```

```text
Administrator
  └── Authors draft form
        └── Publishes version
              └── Reviews analytics
                    └── Exports CSV and PDF reports
```
