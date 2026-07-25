# Primer 1: How GreyMatter Feedback Works End to End

Before building features, it helps to understand how the major parts of GreyMatter Feedback cooperate.

At first, a QR feedback platform may appear simple:

```text
Show QR code
   ↓
Participant answers questions
   ↓
Organizer sees feedback
```

Behind that simple experience, several systems work together to keep the application fast, secure, and reliable.

---

## 1. The Two People Using the System

GreyMatter Feedback has two primary user groups.

### Participants

Participants are people attending an event, course, workshop, talk, or training session.

Their experience should be quick:

```text
Scan QR code
   ↓
Open feedback form
   ↓
Answer questions
   ↓
Submit feedback
   ↓
See confirmation
```

Participants do not need an account in the baseline design.

### Administrators

Administrators are event organizers, facilitators, course creators, or analysts.

Their workflow is more involved:

```text
Create event or course
   ↓
Create session
   ↓
Create feedback form draft
   ↓
Add questions
   ↓
Publish form version
   ↓
Download QR code
   ↓
Review analytics
   ↓
Export CSV or PDF report
```

---

## 2. Events, Sessions, and Forms

GreyMatter Feedback uses a simple hierarchy.

```text
Event or Course
  └── Session
        └── Form Version
              └── Questions
```

For example:

```text
Event: React Summit 2026
  ├── Session: Opening Keynote
  ├── Session: Server Components Workshop
  └── Session: Advanced React Patterns
```

Each session has its own QR URL.

```text
/e/REACT-2026-KEYNOTE
/e/REACT-2026-RSC
/e/REACT-2026-Q3
```

Each session can also have its own feedback form.

For example, the keynote form may ask:

```text
How relevant was the keynote?
How likely are you to recommend the conference?
What should we improve?
```

The workshop form may ask:

```text
How useful were the hands-on exercises?
Was the workshop pace appropriate?
Which topic needs more explanation?
```

The application does not need a separate code deployment for each form. It reads the question configuration from the database and renders the appropriate controls.

---

## 3. Why Forms Have Versions

A **form version** is a snapshot of a form at a particular time.

Imagine participants answer this question:

```text
How useful was this workshop?
```

Later, an administrator changes it to:

```text
How useful were the hands-on exercises?
```

Those are different questions. If old answers were shown under the new wording, reports would become misleading.

GreyMatter Feedback prevents this through versioning:

```text
Version 1 — Published
How useful was this workshop?

Version 2 — Draft
How useful were the hands-on exercises?
```

When Version 2 is published:

```text
Version 1 becomes archived
Version 2 becomes the active participant form
Old responses remain attached to Version 1
New responses attach to Version 2
```

This makes historical analytics trustworthy.

---

## 4. What a QR Code Contains

A QR code does not contain the complete feedback form.

It contains a URL, such as:

```text
https://feedback.example.com/e/REACT-2026-Q3?src=qr
```

The important part is:

```text
REACT-2026-Q3
```

This is the session ID.

When a participant scans the code, the application performs this process:

```text
Read session ID from URL
   ↓
Find matching session in Neon PostgreSQL
   ↓
Confirm session is active
   ↓
Find active published form version
   ↓
Load its questions
   ↓
Display participant form
```

This means the QR code can remain stable even when a new form version is published for the session later.

---

## 5. Next.js: The Application Front Door

**Next.js** is the web application framework used by GreyMatter Feedback.

Think of it as the building that contains all application rooms:

```text
Participant feedback room:
/e/[sessionId]

Administrator login room:
/admin/login

Form authoring room:
/admin/sessions/[sessionId]/edit

Analytics room:
/admin/sessions/[sessionId]

API service desk:
/api/feedback

Background-job integration desk:
/api/inngest
```

Next.js lets us create both:

- Pages that people visit in a browser.
- API routes that receive requests from code.

---

## 6. React: The Interactive User Interface

**React** creates the visible interface people use.

For participants, React powers:

```text
Rating button selection
NPS score selection
Choice selection
Text input
Required-field errors
Draft restoration
Submission status
```

For administrators, React powers:

```text
Login forms
Event creation
Session creation
Question authoring
Question ordering
QR-code download
Report status updates
```

Some React components run on the server, while others run in the browser.

---

## 7. Server Components and Client Components

GreyMatter Feedback uses two major types of React components.

## Server Components

A Server Component runs on the server.

It can safely:

```text
Read from Neon
Use Prisma
Read secret environment variables
Check admin authentication
Load form configuration
```

Example:

```text
src/app/e/[sessionId]/page.tsx
```

The participant route uses server-side code to load a published form.

## Client Components

A Client Component runs in the participant or administrator browser.

It can safely use:

```text
Button clicks
React state
localStorage
navigator.vibrate()
Browser fetch requests
Clipboard access
```

Example:

```text
src/components/participant/feedback-form.tsx
```

A Client Component cannot safely access:

```text
Neon database URL
Prisma
Server secrets
Administrator session secret
Raw database records
```

A useful rule is:

```text
Server Components load secure data.
Client Components handle browser interaction.
```

---

## 8. Neon PostgreSQL: The System of Record

**Neon PostgreSQL** stores GreyMatter Feedback data permanently.

Think of Neon as the application’s secure records room.

It stores:

```text
Events
Sessions
Form versions
Questions
Responses
Answers
Report records
```

For example:

```text
Session:
REACT-2026-Q3

Published form version:
Version 1

Question:
How useful was this workshop?

Participant response:
Submitted at 2026-07-25 10:30 UTC

Answer:
5
```

Neon is the source of truth. The dashboard, CSV export, and PDF reports all derive their information from the data stored there.

---

## 9. Prisma: The Database Translator

**Prisma** is a TypeScript database toolkit.

Instead of writing raw SQL for every database operation, we can write typed TypeScript code.

Example:

```ts
const session = await prisma.session.findUnique({
  where: {
    id: "REACT-2026-Q3",
  },
});
```

Prisma translates that into PostgreSQL queries.

It also helps us define relationships:

```text
Event
  └── Session
        └── FormVersion
              └── Question
```

and:

```text
Response
  └── Answer
```

Prisma reduces common mistakes by checking database fields and relationships at development time.

---

## 10. Why Feedback Submission Uses a Background Job

A participant should not wait for every database operation to finish.

Imagine 300 people submit feedback within a few minutes after a keynote.

A slow workflow would be:

```text
Participant presses Submit
   ↓
Browser waits for database write
   ↓
Browser waits for analytics update
   ↓
Browser waits for report work
   ↓
Participant finally sees success
```

That is not ideal.

GreyMatter Feedback uses a faster workflow:

```text
Participant presses Submit
   ↓
API validates submission
   ↓
API sends event to Inngest
   ↓
Participant quickly sees confirmation
   ↓
Inngest saves response in background
```

This keeps the participant experience responsive.

---

## 11. Inngest: The Background Work Coordinator

**Inngest** manages background jobs.

Think of it as a reliable operations team working behind the scenes.

GreyMatter Feedback sends events such as:

```text
feedback/submitted
report/generate.pdf
```

When feedback is submitted:

```text
feedback/submitted
   ↓
Inngest function runs
   ↓
Response and answers saved in Neon
```

When an administrator requests a PDF:

```text
report/generate.pdf
   ↓
Inngest function runs
   ↓
Analytics loaded
   ↓
PDF generated
   ↓
PDF stored
   ↓
Report status updated
```

Inngest can retry work when temporary failures occur.

For example:

```text
Temporary database issue
   ↓
Inngest retries the save operation
   ↓
Response is saved when Neon is available again
```

---

## 12. Preventing Duplicate Feedback

Retries are useful, but they can accidentally cause duplicate records.

For example:

```text
Participant presses Submit
   ↓
Server accepts submission
   ↓
Phone loses connection before success message appears
   ↓
Participant presses Submit again
```

GreyMatter Feedback assigns each draft a stable submission ID:

```text
submissionId = 6b9f6b86-8fc0-4e54-b064-2b60b848ac31
```

That ID follows the submission through the system:

```text
Browser draft
   ↓
Feedback API
   ↓
Inngest event
   ↓
Response.eventId in Neon
```

The database requires `eventId` to be unique.

So if the same submission is processed twice:

```text
First processing:
Creates response

Second processing:
Finds existing response
Does not create duplicate
```

This property is called **idempotency**.

---

## 13. Local Drafts and Offline Support

Participants may accidentally refresh a page or temporarily lose connection.

GreyMatter Feedback saves unfinished answers in browser localStorage.

```text
Participant selects answers
   ↓
Answers saved in localStorage
   ↓
Browser refreshes
   ↓
Draft restores
```

If a completed submission cannot reach the API:

```text
Participant submits while offline
   ↓
Submission saved in browser outbox
   ↓
Connection returns
   ↓
Browser retries submission
```

The stable submission ID ensures the retry remains safe.

---

## 14. Security Layers

Participant feedback is public in the sense that people can access the form through a QR code. That does not mean the API should trust every request.

GreyMatter Feedback applies several checks:

```text
Browser validation
   ↓
API request validation
   ↓
IP hashing
   ↓
Rate limiting
   ↓
Session active check
   ↓
Published form version check
   ↓
Question ownership check
   ↓
Answer value validation
   ↓
Inngest event processing
   ↓
Duplicate prevention in Neon
```

Each layer protects against a different problem.

| Layer | Example protection |
|---|---|
| Browser validation | Participant forgot a required answer |
| Zod validation | Request has malformed JSON |
| Rate limiting | One device submits repeatedly |
| Session check | Closed session cannot receive new feedback |
| Form version check | Participant submits an outdated form |
| Choice validation | Client submits an option not configured by admin |
| Idempotency | Retry does not duplicate response |

---

## 15. The Admin Dashboard

The dashboard reads stored response data and calculates useful metrics.

```text
Responses and answers in Neon
   ↓
Analytics helper
   ↓
Dashboard cards and distributions
```

Examples:

```text
Total responses:
142

Average rating:
4.8 / 5

Net Promoter Score:
+78
```

The dashboard also displays:

```text
Rating distributions
NPS promoter/passive/detractor counts
Choice answer counts
Written comments
CSV export
QR code
PDF report controls
```

---

## 16. The Complete Data Flow

Here is the complete participant-feedback flow.

```text
1. Administrator creates session
2. Administrator authors draft form
3. Administrator publishes form version
4. GreyMatter generates QR code from session URL
5. Participant scans QR code
6. Next.js loads session and published form from Neon
7. React displays mobile-friendly questions
8. Participant answers questions
9. Browser saves draft locally
10. Participant submits
11. API validates request
12. API hashes IP address
13. API checks rate limit
14. API validates answers against published form
15. API sends Inngest event
16. Participant receives fast confirmation
17. Inngest saves response and answers in Neon
18. Admin dashboard refreshes
19. Administrator exports CSV or requests PDF report
```

---

## 17. The Complete Reporting Flow

```text
1. Administrator opens analytics dashboard
2. Next.js loads responses and answers from Neon
3. Analytics helper calculates metrics
4. Dashboard displays results
5. Administrator clicks Export CSV
6. Protected API generates CSV response
7. Administrator downloads spreadsheet

or

5. Administrator clicks Generate PDF report
6. Protected API creates Report record
7. API sends report/generate.pdf event
8. Inngest loads analytics
9. React PDF renders report
10. Storage layer saves PDF
11. Report record becomes COMPLETE
12. Administrator downloads PDF
```

---

## 18. The Most Important Design Principle

The key GreyMatter Feedback design principle is:

> Keep the participant experience fast, while moving slower work into reliable background processing.

That is why:

```text
Participant form → quick API acceptance
Heavy persistence/reporting → Inngest background jobs
```

Participants should not need to understand Neon, Prisma, Inngest, PDF generation, or rate limiting.

They should only experience:

```text
Scan
Answer
Submit
Done
```

Administrators should experience:

```text
Author
Publish
Measure
Improve
```
