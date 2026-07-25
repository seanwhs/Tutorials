# Appendix E: API Reference and Data Contracts

This appendix documents the primary HTTP endpoints, background events, and database relationships used by GreyMatter Feedback.

It is useful when:

- Building an integration.
- Testing routes with Postman, Insomnia, or `curl`.
- Creating automated tests.
- Debugging a participant submission.
- Extending the admin portal.
- Building a mobile application that submits feedback to the same backend.

---

## E.1 Base URL

During local development:

```text
http://localhost:3000
```

In production:

```text
https://feedback.your-domain.example
```

Examples in this appendix use:

```text
http://localhost:3000
```

Replace it with the production URL when appropriate.

---

## E.2 Route summary

| Route | Method | Authentication | Purpose |
|---|---|---:|---|
| `/` | `GET` | No | Public GreyMatter Feedback landing page |
| `/e/[sessionId]` | `GET` | No | Public participant feedback form |
| `/admin/login` | `GET` | No | Administrator sign-in page |
| `/admin/events` | `GET` | Yes | Event and course list |
| `/admin/events/new` | `GET` | Yes | Create event or course |
| `/admin/events/[eventId]` | `GET` | Yes | Manage sessions in an event |
| `/admin/sessions/[sessionId]/edit` | `GET` | Yes | Form authoring environment |
| `/admin/sessions/[sessionId]` | `GET` | Yes | Analytics dashboard |
| `/api/feedback` | `POST` | No | Validate and queue participant feedback |
| `/api/inngest` | `GET`, `POST`, `PUT` | Inngest verification | Inngest function endpoint |
| `/api/admin/export/[sessionId]` | `GET` | Yes | Download response-answer CSV |
| `/api/admin/reports/[sessionId]` | `GET` | Yes | List recent PDF report records |
| `/api/admin/reports/[sessionId]` | `POST` | Yes | Queue PDF report generation |

---

# E.3 Public participant form route

## `GET /e/[sessionId]`

Loads the current published feedback form for a session.

Example:

```text
GET /e/REACT-2026-Q3?src=qr
```

### URL parameters

| Parameter | Required | Description |
|---|---:|---|
| `sessionId` | Yes | Human-readable session identifier |
| `src` | No | Optional source metadata, such as `qr`, `email`, or `admin-preview` |

### Success behavior

If all conditions are true:

```text
Session exists
Session is active
Session has activeFormVersionId
Active form version has PUBLISHED status
```

the page renders the session form.

### Failure behavior

| Condition | Result |
|---|---|
| Invalid or unknown session ID | Participant not-found page |
| Session is inactive | “Feedback is closed” page |
| No active published form | “Feedback is not available” page |

---

# E.4 Feedback submission endpoint

## `POST /api/feedback`

Accepts a participant feedback submission.

The API validates the request but does not synchronously store answers. Instead, it sends an Inngest event:

```text
feedback/submitted
```

The background worker stores the response and answers in Neon.

### Request headers

```http
Content-Type: application/json
```

### Request body

```json
{
  "submissionId": "6b9f6b86-8fc0-4e54-b064-2b60b848ac31",
  "sessionId": "REACT-2026-Q3",
  "formVersionId": "c39c3d46-3d35-4c25-b889-80e437f526e4",
  "answers": [
    {
      "questionId": "dc3ad31c-fd95-49ec-a8c8-0d6ef363be10",
      "value": 5
    },
    {
      "questionId": "e4dbdda5-c007-4d7f-858e-3b354e4559c9",
      "value": 9
    },
    {
      "questionId": "0f23efc8-1b4f-41ec-bc60-3cd2cb8c5a50",
      "value": "Server Components"
    },
    {
      "questionId": "6015bccd-0789-4c70-b784-055d02c4ac73",
      "value": "More time for the practical exercises would be helpful."
    }
  ],
  "metadata": {
    "source": "qr",
    "screenWidth": 390,
    "screenHeight": 844
  }
}
```

### Request field reference

| Field | Type | Required | Description |
|---|---|---:|---|
| `submissionId` | UUID | Yes | Stable ID for retry-safe submission processing |
| `sessionId` | String | Yes | Session identifier from QR URL |
| `formVersionId` | UUID | Yes | Published form version displayed to participant |
| `answers` | Array | Yes | One or more participant answers |
| `answers[].questionId` | UUID | Yes | Question ID from displayed form |
| `answers[].value` | Integer or string | Yes | Answer value |
| `metadata.source` | String | No | Source identifier, usually `qr` |
| `metadata.screenWidth` | Integer | No | Browser screen width |
| `metadata.screenHeight` | Integer | No | Browser screen height |

### Answer value rules

| Question type | Expected `value` |
|---|---|
| `RATING` | Integer within configured minimum and maximum |
| `NPS` | Integer from `0` through `10` |
| `CHOICE` | String matching one configured option |
| `TEXT` | String within configured character limit |

### Successful response

Status:

```http
HTTP/1.1 202 Accepted
```

Body:

```json
{
  "accepted": true,
  "submissionId": "6b9f6b86-8fc0-4e54-b064-2b60b848ac31"
}
```

### Error responses

#### Invalid JSON

Status:

```http
400 Bad Request
```

Body:

```json
{
  "error": "The request body must contain valid JSON."
}
```

#### Invalid request shape

Status:

```http
400 Bad Request
```

Body:

```json
{
  "error": "The feedback submission has an invalid format."
}
```

#### Unknown session

Status:

```http
404 Not Found
```

Body:

```json
{
  "error": "Feedback session not found."
}
```

#### Form no longer matches

Status:

```http
409 Conflict
```

Body:

```json
{
  "error": "This feedback form has changed. Refresh the page before submitting your answers."
}
```

#### Rate limited

Status:

```http
429 Too Many Requests
```

Headers:

```http
Retry-After: 300
X-RateLimit-Limit: 1
X-RateLimit-Remaining: 0
```

Body:

```json
{
  "error": "Too many feedback submissions were received from this device. Please try again later."
}
```

#### Background event service unavailable

Status:

```http
503 Service Unavailable
```

Body:

```json
{
  "error": "We could not accept your feedback right now. Your draft remains saved on this device, so please try again."
}
```

---

## E.5 Test feedback submission with curl

First, retrieve real question and form version IDs from Prisma Studio:

```bash
npx prisma studio
```

Then run a request using those IDs.

```bash
curl -i \
  -X POST "http://localhost:3000/api/feedback" \
  -H "Content-Type: application/json" \
  --data '{
    "submissionId": "6b9f6b86-8fc0-4e54-b064-2b60b848ac31",
    "sessionId": "REACT-2026-Q3",
    "formVersionId": "REPLACE-WITH-REAL-FORM-VERSION-UUID",
    "answers": [
      {
        "questionId": "REPLACE-WITH-REAL-RATING-QUESTION-UUID",
        "value": 5
      },
      {
        "questionId": "REPLACE-WITH-REAL-NPS-QUESTION-UUID",
        "value": 9
      }
    ],
    "metadata": {
      "source": "curl-test",
      "screenWidth": 1440,
      "screenHeight": 900
    }
  }'
```

A successful response should return:

```text
HTTP/1.1 202 Accepted
```

Then inspect Inngest:

```text
http://localhost:8288
```

Finally, inspect the stored `Response` and `Answer` records in Prisma Studio.

---

# E.6 CSV export endpoint

## `GET /api/admin/export/[sessionId]`

Downloads all answers for a session as CSV.

Example:

```text
GET /api/admin/export/REACT-2026-Q3
```

### Authentication

Requires an authenticated administrator session cookie.

Without authentication:

```http
HTTP/1.1 401 Unauthorized
```

```json
{
  "error": "Administrator authentication is required."
}
```

### Success response headers

```http
Content-Type: text/csv; charset=utf-8
Content-Disposition: attachment; filename="greymatter-feedback-REACT-2026-Q3-2026-07-25.csv"
Cache-Control: no-store
```

### CSV columns

```text
Event
Session ID
Session Title
Response ID
Submitted At (UTC)
Form Version
Question
Question Type
Numeric Value
Text Value
```

Example CSV row:

```csv
"React Summit 2026","REACT-2026-Q3","Advanced React Patterns","2fb0d18f-7d9d-4d3e-b5a0-d3f3af806955","2026-07-25T10:30:00.000Z","1","How useful was this workshop?","RATING","5",""
```

---

# E.7 PDF report endpoint

## `GET /api/admin/reports/[sessionId]`

Lists up to ten recent report records.

Example:

```text
GET /api/admin/reports/REACT-2026-Q3
```

### Success response

```json
{
  "reports": [
    {
      "id": "a308665e-c131-45b2-9937-94b295f0a164",
      "status": "COMPLETE",
      "url": "/reports/REACT-2026-Q3-a308665e-c131-45b2-9937-94b295f0a164.pdf",
      "error": null,
      "createdAt": "2026-07-25T10:45:00.000Z",
      "updatedAt": "2026-07-25T10:45:04.000Z"
    }
  ]
}
```

## `POST /api/admin/reports/[sessionId]`

Creates a report record and queues the Inngest PDF job.

Example:

```text
POST /api/admin/reports/REACT-2026-Q3
```

### Success response

```http
HTTP/1.1 202 Accepted
```

```json
{
  "reportId": "a308665e-c131-45b2-9937-94b295f0a164",
  "status": "QUEUED"
}
```

### Conflict response

If another report is already queued or processing:

```http
HTTP/1.1 409 Conflict
```

```json
{
  "error": "A report is already being generated for this session.",
  "reportId": "existing-report-id",
  "status": "PROCESSING"
}
```

### Report statuses

| Status | Meaning |
|---|---|
| `QUEUED` | Report record created; waiting for background worker |
| `PROCESSING` | Worker is generating analytics and PDF |
| `COMPLETE` | PDF was stored successfully; `url` is available |
| `FAILED` | Generation or storage failed; `error` explains why |

---

# E.8 Inngest event contracts

## `feedback/submitted`

Sent by:

```text
POST /api/feedback
```

Received by:

```text
process-feedback-submission
```

Event data structure:

```ts
type FeedbackSubmissionEventData = {
  submissionId: string;
  sessionId: string;
  formVersionId: string;
  clientIpHash: string;
  metadata: {
    source?: string;
    screenWidth?: number;
    screenHeight?: number;
    userAgent: string;
  };
  answers: Array<{
    questionId: string;
    numericValue: number | null;
    textValue: string | null;
  }>;
};
```

Example event:

```json
{
  "name": "feedback/submitted",
  "data": {
    "submissionId": "6b9f6b86-8fc0-4e54-b064-2b60b848ac31",
    "sessionId": "REACT-2026-Q3",
    "formVersionId": "c39c3d46-3d35-4c25-b889-80e437f526e4",
    "clientIpHash": "8e785da3b7105e13a10e99a0f51d1979...",
    "metadata": {
      "source": "qr",
      "screenWidth": 390,
      "screenHeight": 844,
      "userAgent": "Mozilla/5.0 ..."
    },
    "answers": [
      {
        "questionId": "dc3ad31c-fd95-49ec-a8c8-0d6ef363be10",
        "numericValue": 5,
        "textValue": null
      }
    ]
  }
}
```

## `report/generate.pdf`

Sent by:

```text
POST /api/admin/reports/[sessionId]
```

Received by:

```text
generate-pdf-report
```

Event data structure:

```ts
type ReportGenerationEventData = {
  reportId: string;
  sessionId: string;
  requestedBy: string;
};
```

Example event:

```json
{
  "name": "report/generate.pdf",
  "data": {
    "reportId": "a308665e-c131-45b2-9937-94b295f0a164",
    "sessionId": "REACT-2026-Q3",
    "requestedBy": "administrator"
  }
}
```

---

# E.9 Server action contracts

GreyMatter Feedback also uses Next.js Server Actions for protected administrator operations.

These are not traditional REST endpoints. They are server-side functions invoked by forms in the React application.

| Action | Purpose |
|---|---|
| `loginAction` | Verify admin password and create session cookie |
| `logoutAction` | Clear administrator session |
| `createEventAction` | Create event or course |
| `createSessionAction` | Create a QR-addressable session |
| `createDraftVersionAction` | Create and optionally clone a draft form version |
| `addQuestionAction` | Add a question to a draft |
| `moveQuestionAction` | Move a draft question up or down |
| `deleteQuestionAction` | Delete a draft question |
| `publishFormVersionAction` | Archive old version and publish new version |
| `setSessionActiveAction` | Open or close participant feedback collection |

Because they run on the server, these actions can safely use:

```text
Prisma
Neon credentials
Administrator authentication checks
Server-side Zod validation
```

They must not be exposed as unauthenticated public endpoints.

---

# E.10 Database model reference

## Event

```text
Event
├── id
├── title
├── createdAt
└── sessions[]
```

An event is the parent grouping for a course, conference, event, or training program.

Example:

```text
React Summit 2026
```

## Session

```text
Session
├── id
├── eventId
├── title
├── isActive
├── activeFormVersionId
├── createdAt
├── formVersions[]
├── responses[]
└── reports[]
```

A session is a QR-addressable feedback target.

Example:

```text
REACT-2026-Q3
Advanced React Patterns
```

## FormVersion

```text
FormVersion
├── id
├── sessionId
├── versionNumber
├── status
├── publishedAt
├── createdAt
├── updatedAt
└── questions[]
```

A form version is an immutable published snapshot or editable draft.

## Question

```text
Question
├── id
├── formVersionId
├── orderIndex
├── questionText
├── questionType
├── isRequired
├── settings
└── options
```

Question types:

```text
RATING
NPS
TEXT
CHOICE
```

## Response

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

`eventId` is the unique idempotency value from the participant submission.

## Answer

```text
Answer
├── id
├── responseId
├── questionId
├── numericValue
└── textValue
```

## Report

```text
Report
├── id
├── sessionId
├── status
├── url
├── error
├── createdAt
└── updatedAt
```

---

# E.11 Extension guidelines

When adding a new API endpoint, follow these rules.

## Public endpoints

For public routes such as participant submissions:

```text
[ ] Validate request JSON with Zod.
[ ] Limit body size where applicable.
[ ] Rate-limit requests.
[ ] Do not trust client-provided session or question data.
[ ] Confirm data ownership in Neon.
[ ] Return generic user-safe errors.
[ ] Avoid exposing internal database details.
```

## Administrator endpoints

For admin routes:

```text
[ ] Check isAdminAuthenticated().
[ ] Return 401 for unauthenticated requests.
[ ] Validate route parameters.
[ ] Validate query strings and request bodies.
[ ] Use Cache-Control: no-store for sensitive data.
[ ] Log operational identifiers, not participant content.
```

## Background events

For Inngest events:

```text
[ ] Define event types in src/inngest/client.ts.
[ ] Include an idempotency key when data writes occur.
[ ] Use step.run() for meaningful independent work.
[ ] Keep event data small.
[ ] Do not put secrets in event data.
[ ] Make retry behavior safe.
```
