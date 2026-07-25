# GreyMatter Feedback Quiz and Test Bank

This test bank covers:

```text
GreyMatter Feedback product concepts
Participant workflow
Form authoring
Form versioning
Security and privacy
Next.js architecture
Neon and Prisma
Inngest background jobs
Analytics and reporting
Operations and incident response
```

---

# Section A — Multiple Choice Questions

## A1. What is the main purpose of a GreyMatter Feedback QR code?

A. Store all participant answers inside the QR image  
B. Open the correct session-specific participant feedback form  
C. Sign an administrator into the portal  
D. Download a PDF report automatically  

---

## A2. Which URL pattern is used for a participant feedback session?

A. `/admin/sessions/[sessionId]`  
B. `/api/feedback/[sessionId]`  
C. `/e/[sessionId]`  
D. `/reports/[sessionId]`  

---

## A3. Which entity is the parent container for workshops, modules, talks, or sessions?

A. Answer  
B. Event  
C. Report  
D. FormVersion  

---

## A4. Which entity stores the exact published form snapshot shown to a participant?

A. Session  
B. Response  
C. FormVersion  
D. Event  

---

## A5. Why does GreyMatter Feedback use form versioning?

A. To make QR codes larger  
B. To keep published forms editable  
C. To preserve historical reporting accuracy  
D. To remove the need for a database  

---

## A6. Which form version status is editable by administrators but not visible to participants?

A. `PUBLISHED`  
B. `ARCHIVED`  
C. `DRAFT`  
D. `COMPLETE`  

---

## A7. Which form version status is available to participants?

A. `DRAFT`  
B. `PUBLISHED`  
C. `ARCHIVED`  
D. `FAILED`  

---

## A8. Which question type uses a score from 0 through 10?

A. Rating  
B. Choice  
C. Text  
D. NPS  

---

## A9. Which question type stores its selected answer in `textValue`?

A. Rating only  
B. NPS only  
C. Choice and text  
D. Rating and NPS  

---

## A10. What is the recommended minimum touch target height used in GreyMatter Feedback?

A. 16 pixels  
B. 24 pixels  
C. 32 pixels  
D. 48 pixels  

---

## A11. Why are text inputs styled with at least 16px text?

A. To make all text bold  
B. To reduce mobile browser auto-zoom  
C. To make PDF reports faster  
D. To avoid database migration errors  

---

## A12. What browser storage mechanism is used for participant drafts?

A. Cookies  
B. IndexedDB only  
C. localStorage  
D. sessionStorage only  

---

## A13. What should happen to a participant draft after the server accepts a submission?

A. It should be emailed to the participant  
B. It should remain forever  
C. It should be cleared  
D. It should be copied to the admin dashboard  

---

## A14. What HTTP status code indicates that feedback was accepted for asynchronous processing?

A. 200  
B. 201  
C. 202  
D. 404  

---

## A15. What does HTTP `202 Accepted` mean in GreyMatter Feedback?

A. The PDF report is complete  
B. The submission was accepted for background processing  
C. The participant is authenticated  
D. The database migration has finished  

---

## A16. Which tool validates feedback request structure in the API?

A. Tailwind CSS  
B. Zod  
C. QRCode  
D. React PDF  

---

## A17. Which service is used for background job orchestration?

A. Neon  
B. Prisma  
C. Inngest  
D. Tailwind CSS  

---

## A18. Which Inngest event is sent after a valid participant submission?

A. `report/created`  
B. `feedback/submitted`  
C. `session/published`  
D. `answer/updated`  

---

## A19. Why is a stable submission ID used?

A. To create prettier QR codes  
B. To prevent duplicate responses during retries  
C. To avoid using PostgreSQL  
D. To identify participant names  

---

## A20. Which database field prevents duplicate response persistence for the same submission?

A. `sessionId`  
B. `submittedAt`  
C. `eventId` or recommended `submissionEventId`  
D. `questionText`  

---

## A21. What does idempotency mean?

A. A form can only contain one question  
B. Repeating an operation produces the same final result  
C. A session cannot be closed  
D. A QR code cannot be scanned twice  

---

## A22. Which service provides the hosted PostgreSQL database?

A. Clerk  
B. Neon  
C. Inngest  
D. Upstash  

---

## A23. Which tool provides typed database queries and migrations?

A. Prisma  
B. React  
C. Tailwind CSS  
D. QRCode  

---

## A24. Which connection URL should be used by the running serverless application?

A. `DIRECT_URL` only  
B. `DATABASE_URL` pooled connection  
C. `NEXT_PUBLIC_APP_URL`  
D. `S3_ENDPOINT`  

---

## A25. Which connection URL should be used for Prisma migrations?

A. `DATABASE_URL` only  
B. `NEXT_PUBLIC_APP_URL`  
C. `DIRECT_URL`  
D. `INNGEST_EVENT_KEY`  

---

## A26. What is stored instead of a raw participant IP address?

A. Participant email address  
B. Daily salted SHA-256 hash  
C. Device GPS location  
D. Phone number  

---

## A27. Why does the IP hash include a daily rotating value?

A. To make database queries slower  
B. To reduce long-term tracking ability  
C. To store the raw IP securely  
D. To generate QR codes  

---

## A28. Which service is recommended for distributed production rate limiting?

A. Upstash Redis  
B. Prisma Studio  
C. React PDF  
D. Clerk only  

---

## A29. Which route exports response data as CSV?

A. `/api/admin/export/[sessionId]`  
B. `/api/feedback/[sessionId]`  
C. `/api/inngest/export`  
D. `/admin/csv/[sessionId]`  

---

## A30. Why should CSV exports protect values beginning with `=`, `+`, `-`, or `@`?

A. To improve QR scan speed  
B. To avoid spreadsheet formula injection  
C. To make NPS calculations easier  
D. To allow anonymous login  

---

## A31. Which report status means the PDF is ready?

A. `QUEUED`  
B. `PROCESSING`  
C. `COMPLETE`  
D. `DRAFT`  

---

## A32. Which report status means the worker encountered an error?

A. `ARCHIVED`  
B. `FAILED`  
C. `PUBLISHED`  
D. `ACTIVE`  

---

## A33. Why should PDF reports be stored privately in production?

A. PDFs cannot be downloaded in public  
B. Reports may include sensitive written feedback  
C. Neon requires private files  
D. QR codes only work with private storage  

---

## A34. Which component type can safely access Prisma and Neon?

A. Client Component  
B. Server Component  
C. Browser extension  
D. CSS module  

---

## A35. Which directive marks a React component as browser-side interactive?

A. `"use server"`  
B. `"use client"`  
C. `"use database"`  
D. `"use prisma"`  

---

## A36. What is the primary purpose of the `server-only` import?

A. Add styling to a component  
B. Ensure a module cannot be imported into browser code  
C. Create a PDF report  
D. Cache a QR code  

---

## A37. What should happen if a participant submits a form version that is no longer active?

A. Server should silently save the answer to current version  
B. Server should reject it with a conflict response  
C. Server should delete the session  
D. Server should create a new form version  

---

## A38. What is the correct publishing sequence?

A. Delete old responses, publish draft, create QR code  
B. Archive old published version, publish new version, update active form pointer  
C. Create new event, delete old form, close session  
D. Publish all drafts simultaneously  

---

## A39. Which action should be avoided after a form has collected responses?

A. Viewing analytics  
B. Exporting CSV  
C. Editing the published questions directly  
D. Generating PDF report  

---

## A40. What is the correct first action if a report containing sensitive comments becomes publicly accessible?

A. Generate more reports  
B. Make storage private and stop public access  
C. Delete all sessions  
D. Change the QR code  

---

# Section B — True or False

## B1. Participants must create accounts before submitting feedback.

---

## B2. A session may have multiple form versions.

---

## B3. A participant response should store the specific form version used during submission.

---

## B4. A published form can be edited directly without affecting historical analytics.

---

## B5. A choice question should have at least two options.

---

## B6. NPS scores use a range from 1 through 5.

---

## B7. The participant browser is considered a trusted security boundary.

---

## B8. Client-side validation alone is sufficient to secure participant submissions.

---

## B9. Inngest is used to process background tasks such as response persistence and PDF generation.

---

## B10. A replayed Inngest event should create another response record.

---

## B11. Raw IP addresses should be stored in Neon for better analytics.

---

## B12. Upstash Redis is recommended for production distributed rate limiting.

---

## B13. CSV export should normally include participant IP hashes.

---

## B14. Written feedback should be rendered as escaped text rather than unsafe HTML.

---

## B15. A service worker should cache POST feedback submission requests.

---

## B16. A report can move from `QUEUED` to `PROCESSING` to `COMPLETE`.

---

## B17. PDF reports should use private object storage in production when they include written feedback.

---

## B18. `DATABASE_URL` should generally use Neon’s pooled connection URL.

---

## B19. `DIRECT_URL` should generally be used for Prisma migrations.

---

## B20. A QR code should include a typed fallback URL when displayed to participants.

---

# Section C — Short Answer Questions

## C1. Explain the difference between an Event and a Session.

---

## C2. Why is `Response.formVersionId` important?

---

## C3. What is the difference between a draft form and a published form?

---

## C4. Name the four supported GreyMatter Feedback question types.

---

## C5. Explain why participant drafts include both `sessionId` and `formVersionId`.

---

## C6. What is the purpose of a stable `submissionId`?

---

## C7. What is the difference between client-side validation and server-side validation?

---

## C8. What does a daily salted IP hash help the system do?

---

## C9. Describe the correct flow after a participant selects **Submit feedback**.

---

## C10. What is the difference between `QUEUED`, `PROCESSING`, `COMPLETE`, and `FAILED` report statuses?

---

## C11. Why should published form versions not be edited directly?

---

## C12. What information should not be included in standard CSV exports?

---

## C13. Why is a PDF report generated asynchronously?

---

## C14. What should a trainer display alongside a QR code?

---

## C15. What is the first response action if an administrator suspects that a private PDF report became publicly accessible?

---

# Section D — Scenario Questions

## D1. Stale Form Submission

A participant opens Version 1 of a feedback form. Before they submit, an administrator publishes Version 2. The participant then submits Version 1 answers.

**Question:** What should the API do and why?

---

## D2. Duplicate Submission Retry

A participant submits feedback. The API accepts the request, but the phone loses connection before the participant sees the success page. The participant presses submit again.

**Question:** How should GreyMatter Feedback prevent duplicate stored responses?

---

## D3. Choice Question Tampering

The published choice options are:

```text
Server Components
Data Fetching
Performance
```

An attacker manually submits:

```json
{
  "value": "Pizza"
}
```

**Question:** What should happen?

---

## D4. Wrong QR Code on a Slide

An event facilitator displays a QR code that opens the wrong session.

**Question:** List three immediate actions.

---

## D5. PDF Report Exposure

A PDF report containing participant comments is found at a public URL.

**Question:** What immediate containment actions should the technical team take?

---

## D6. No Dashboard Updates

Participants see success confirmations, but the dashboard response count is not increasing.

**Question:** What system components should be checked in order?

---

## D7. Bad Published Question

A published form accidentally contains this question:

```text
How excellent was the instructor?
```

**Question:** Why is this weak, and what should the administrator do instead of editing the published form directly?

---

## D8. Rate Limit During Local Testing

A developer receives a `429 Too Many Requests` response while testing locally.

**Question:** Why might this happen, and what is one safe local development fix?

---

## D9. Closed Session

A participant opens a valid QR code but sees:

```text
Feedback is closed
```

**Question:** Which session field should the administrator check first?

---

## D10. Report Generation Failure

A report remains in `FAILED` status.

**Question:** Name three systems or configurations that should be checked.

---

# Answer Key

# Section A — Multiple Choice Answers

| Question | Answer | Explanation |
|---|---|---|
| A1 | B | The QR code contains a URL to the correct session participant form. |
| A2 | C | Participant forms use `/e/[sessionId]`. |
| A3 | B | An Event is the parent container for sessions. |
| A4 | C | FormVersion stores a form snapshot. |
| A5 | C | Versioning preserves historical reporting accuracy. |
| A6 | C | Draft forms are editable and not publicly visible. |
| A7 | B | Published forms are shown to participants. |
| A8 | D | NPS uses scores from 0–10. |
| A9 | C | Choice and text answers use `textValue`. |
| A10 | D | The target minimum is 48px. |
| A11 | B | Inputs at 16px help avoid mobile Safari zoom. |
| A12 | C | Drafts use browser localStorage. |
| A13 | C | Clear the draft after the API accepts the submission. |
| A14 | C | `202 Accepted` means accepted for background processing. |
| A15 | B | Inngest will process the accepted submission asynchronously. |
| A16 | B | Zod validates request structure. |
| A17 | C | Inngest runs background workflows. |
| A18 | B | Valid submissions dispatch `feedback/submitted`. |
| A19 | B | Stable IDs make retries idempotent. |
| A20 | C | The unique submission event field prevents duplicate persistence. |
| A21 | B | Repeated operations produce one final result. |
| A22 | B | Neon provides hosted PostgreSQL. |
| A23 | A | Prisma provides typed database access and migrations. |
| A24 | B | Runtime application traffic uses pooled `DATABASE_URL`. |
| A25 | C | Prisma migrations use `DIRECT_URL`. |
| A26 | B | A daily salted SHA-256 hash is stored instead. |
| A27 | B | Daily salt reduces long-term tracking linkability. |
| A28 | A | Upstash Redis supports distributed rate limiting. |
| A29 | A | CSV export route is `/api/admin/export/[sessionId]`. |
| A30 | B | It mitigates spreadsheet formula injection. |
| A31 | C | `COMPLETE` means the report is ready. |
| A32 | B | `FAILED` means report generation encountered an error. |
| A33 | B | Reports can contain sensitive comments and analytics. |
| A34 | B | Server Components can safely access Prisma and Neon. |
| A35 | B | `"use client"` marks browser-interactive React components. |
| A36 | B | It prevents accidental client-side imports of server modules. |
| A37 | B | Server rejects stale form submissions with HTTP 409. |
| A38 | B | Archive old form, publish draft, update active pointer atomically. |
| A39 | C | Published forms must not be edited directly. |
| A40 | B | First contain exposure by making report storage private. |

---

# Section B — True or False Answers

| Question | Answer | Explanation |
|---|---|---|
| B1 | False | Participants do not need accounts in the baseline design. |
| B2 | True | Sessions can have multiple draft, published, and archived versions. |
| B3 | True | Form version ID preserves historical accuracy. |
| B4 | False | Direct edits to published forms can corrupt reporting meaning. |
| B5 | True | Choice questions require at least two options. |
| B6 | False | NPS uses 0–10, not 1–5. |
| B7 | False | Browser input is untrusted until server validation. |
| B8 | False | Server-side validation is mandatory. |
| B9 | True | Inngest handles background processing. |
| B10 | False | Replays must not create duplicate responses. |
| B11 | False | Raw IP addresses should not be stored. |
| B12 | True | Upstash Redis is recommended for distributed production limits. |
| B13 | False | IP hashes should not be included in standard exports. |
| B14 | True | Escaped text prevents unsafe HTML execution. |
| B15 | False | POST submissions should not be cached by the service worker. |
| B16 | True | This is the normal report lifecycle. |
| B17 | True | Private report storage protects sensitive feedback. |
| B18 | True | Runtime database access generally uses the pooled URL. |
| B19 | True | Migrations generally use the direct database URL. |
| B20 | True | Typed URL is an accessibility and operational fallback. |

---

# Section C — Short Answer Sample Responses

## C1. Difference between Event and Session

An Event is the parent container, such as a course, conference, or training program. A Session is an individual workshop, module, talk, or feedback target within that Event.

---

## C2. Why `Response.formVersionId` matters

It records the exact form version shown to the participant. This preserves historical reporting accuracy if questions, options, or rating scales change later.

---

## C3. Difference between draft and published form

A draft form is editable by administrators and not visible to participants. A published form is visible to participants and should be treated as immutable for historical accuracy.

---

## C4. Four question types

```text
RATING
NPS
CHOICE
TEXT
```

---

## C5. Why drafts use both `sessionId` and `formVersionId`

The session ID identifies the feedback target. The form version ID ensures answers from an older form version do not appear in a newly published version of the form.

---

## C6. Purpose of stable `submissionId`

It acts as an idempotency key. If the browser, API, or Inngest retries the same submission, the system can recognize it and avoid creating duplicate response records.

---

## C7. Client-side versus server-side validation

Client-side validation improves usability by showing errors before submission. Server-side validation protects data integrity and security because browser requests can be modified or bypassed.

---

## C8. Purpose of daily salted IP hash

It supports rate limiting and abuse prevention without storing a raw IP address. The daily salt reduces long-term tracking of the same user across days.

---

## C9. Submission flow

```text
Participant submits form
→ browser validates required fields
→ POST /api/feedback
→ API validates request and form ownership
→ API hashes client IP
→ API checks rate limit
→ API sends Inngest event
→ API returns 202
→ Inngest saves Response and Answer records in Neon
```

---

## C10. Report statuses

```text
QUEUED:
Report request exists and is waiting for worker.

PROCESSING:
Worker is generating report.

COMPLETE:
PDF is stored and available.

FAILED:
Generation or storage did not complete.
```

---

## C11. Why published forms should not be edited

Editing published questions can make old answers appear under new wording or changed options. A new draft version should be created and published instead.

---

## C12. Data not included in standard CSV exports

```text
Raw IP addresses
Client IP hashes
Raw user-agent metadata
Database credentials
Session cookies
Administrator secrets
```

---

## C13. Why PDF reports are asynchronous

PDF generation can require analytics calculation, document rendering, file storage upload, and status updates. Running it in the background avoids long browser waits and request timeouts.

---

## C14. What trainers should display beside QR code

A typed fallback participant URL, such as:

```text
feedback.example.com/e/REACT-2026-Q3
```

---

## C15. First action after public report exposure

Immediately contain the exposure by making storage private or disabling public report access. Preserve logs and identify affected reports before continuing investigation.

---

# Section D — Scenario Answer Guide

## D1. Stale Form Submission

The API should reject the submission with HTTP `409 Conflict`.

Reason:

```text
The participant completed an old form version.
The active published form has changed.
The system must not silently attach old answers to the new form.
```

The participant should refresh the page and review the current form.

---

## D2. Duplicate Submission Retry

GreyMatter Feedback should use the same stable `submissionId` for retries.

The system prevents duplicates through:

```text
Stable browser submission ID
Unique Response submission event ID
Idempotent response persistence logic
Inngest replay safety
```

Only one Response record should exist for that submission ID.

---

## D3. Choice Question Tampering

The API should reject the request with HTTP `400 Bad Request`.

Reason:

```text
"Pizza" is not one of the configured choice options.
The server validates the submitted value against the published question options.
```

---

## D4. Wrong QR Code on a Slide

Possible immediate actions:

```text
1. Remove, cover, or stop displaying the incorrect QR code.
2. Display the correct typed participant URL immediately.
3. Replace the slide or poster with the correct QR code.
4. Test the corrected QR code using at least two devices.
5. Confirm the corrected session is active and published.
```

Any three are acceptable.

---

## D5. PDF Report Exposure

Immediate containment actions:

```text
1. Make the storage bucket or object private.
2. Disable public access to the report URL.
3. Preserve access logs and identify affected report IDs.
4. Remove exposed links from the application.
5. Begin assessment of report content and possible data exposure.
```

---

## D6. No Dashboard Updates

Check in this order:

```text
1. Confirm participant received success confirmation.
2. Confirm API returned 202.
3. Check Inngest dashboard for feedback/submitted run.
4. Inspect process-feedback-submission step status.
5. Check Neon Response and Answer records.
6. Refresh dashboard or wait for auto-refresh.
```

---

## D7. Bad Published Question

The question is weak because it is leading and biased. It encourages positive answers by using “excellent.”

Better wording:

```text
How would you rate the instructor’s explanation?
```

The administrator should create a new draft version, change the question there, preview it, and publish the corrected version. They should not edit the published version directly.

---

## D8. Local Rate Limit Test

This can happen because local development may use the in-memory fallback rate limiter and multiple requests may share the `unknown-client` identity.

One safe fix:

```text
Restart the Next.js development server.
```

Other valid answer:

```text
Test against a different session ID.
```

---

## D9. Closed Session

The administrator should first check:

```text
Session.isActive
```

If it is `false`, the session is closed. The administrator may reopen it from the session editor if appropriate.

---

## D10. Failed PDF Report

Check at least three of:

```text
Inngest generate-pdf-report run status
Neon database connectivity
Report record error field
S3/R2 storage credentials
Storage bucket permissions
S3 endpoint configuration
PDF rendering error logs
Local public/reports directory in development
```
