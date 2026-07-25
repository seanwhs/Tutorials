# GreyMatter Feedback API Guide

**Base URL — Local Development**

```text
http://localhost:3000
```

**Base URL — Production**

```text
https://feedback.your-domain.example
```

---

## 1. API Overview

GreyMatter Feedback exposes four main API areas:

| Area | Purpose |
|---|---|
| Public feedback API | Accept participant feedback submissions |
| Admin export API | Download session responses as CSV |
| Admin reports API | Request and check PDF report generation |
| Inngest endpoint | Receive and run background workflows |

```text
Participant
   ↓
POST /api/feedback
   ↓
Inngest
   ↓
Neon PostgreSQL

Administrator
   ├── GET /api/admin/export/[sessionId]
   └── GET / POST /api/admin/reports/[sessionId]
```

---

# 2. Authentication

## 2.1 Public endpoints

The participant feedback endpoint is public:

```text
POST /api/feedback
```

It does not require a participant account.

Security is enforced through:

```text
Zod validation
Rate limiting
Session validation
Published form validation
Question ownership validation
Answer value validation
Stable submission IDs
```

---

## 2.2 Administrator endpoints

Administrator routes require a valid signed HTTP-only cookie:

```text
greymatter_admin_session
```

Protected endpoints include:

```text
GET /api/admin/export/[sessionId]
GET /api/admin/reports/[sessionId]
POST /api/admin/reports/[sessionId]
```

Unauthorized requests return:

```http
HTTP/1.1 401 Unauthorized
```

```json
{
  "error": "Administrator authentication is required."
}
```

---

# 3. Participant Feedback API

## 3.1 Submit Feedback

```http
POST /api/feedback
```

This endpoint validates a participant submission and queues it for background processing.

It returns quickly with `202 Accepted` after the submission has passed validation and has been accepted by Inngest.

---

## 3.2 Request Headers

```http
Content-Type: application/json
```

Optional browser-generated metadata is included in the request body.

Do not send:

```text
Database credentials
Admin cookies
Admin password
Raw IP addresses
Storage credentials
```

---

## 3.3 Request Body

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
      "value": "More time for hands-on exercises would be helpful."
    }
  ],
  "metadata": {
    "source": "qr",
    "screenWidth": 390,
    "screenHeight": 844
  }
}
```

---

## 3.4 Request Field Reference

| Field | Type | Required | Description |
|---|---|---:|---|
| `submissionId` | UUID | Yes | Stable idempotency key for this submission |
| `sessionId` | String | Yes | QR-friendly session identifier |
| `formVersionId` | UUID | Yes | Published form version displayed to participant |
| `answers` | Array | Yes | Participant answers |
| `answers[].questionId` | UUID | Yes | Question identifier from published form |
| `answers[].value` | Integer or string | Yes | Answer value |
| `metadata.source` | String | No | Source, such as `qr`, `email`, or `admin-preview` |
| `metadata.screenWidth` | Integer | No | Device screen width |
| `metadata.screenHeight` | Integer | No | Device screen height |

---

## 3.5 Answer Rules

| Question Type | Expected `value` | Example |
|---|---|---|
| `RATING` | Integer within configured range | `5` |
| `NPS` | Integer from `0` through `10` | `9` |
| `CHOICE` | String matching configured option | `"Server Components"` |
| `TEXT` | String within configured maximum length | `"More exercises, please."` |

---

## 3.6 Successful Response

```http
HTTP/1.1 202 Accepted
Content-Type: application/json
```

```json
{
  "accepted": true,
  "submissionId": "6b9f6b86-8fc0-4e54-b064-2b60b848ac31"
}
```

`202 Accepted` means:

```text
The API validated and accepted the submission.
The submission was queued for background processing.
The response and answers may be saved moments later by Inngest.
```

---

## 3.7 Error Responses

### Invalid JSON

```http
HTTP/1.1 400 Bad Request
```

```json
{
  "error": "The request body must contain valid JSON."
}
```

---

### Invalid Request Format

```http
HTTP/1.1 400 Bad Request
```

```json
{
  "error": "The feedback submission has an invalid format."
}
```

---

### Missing Required Answer

```http
HTTP/1.1 400 Bad Request
```

```json
{
  "error": "The required question \"How useful was this workshop?\" is missing an answer."
}
```

---

### Invalid Rating Score

```http
HTTP/1.1 400 Bad Request
```

```json
{
  "error": "Question \"How useful was this workshop?\" requires a score between 1 and 5."
}
```

---

### Invalid Choice Option

```http
HTTP/1.1 400 Bad Request
```

```json
{
  "error": "Question \"Which topic was most valuable?\" contains an invalid option."
}
```

---

### Unknown Session

```http
HTTP/1.1 404 Not Found
```

```json
{
  "error": "Feedback session not found."
}
```

---

### Closed Session

```http
HTTP/1.1 409 Conflict
```

```json
{
  "error": "This feedback session is closed."
}
```

---

### Stale Form Version

```http
HTTP/1.1 409 Conflict
```

```json
{
  "error": "This feedback form has changed. Refresh the page before submitting your answers."
}
```

---

### Rate Limited

```http
HTTP/1.1 429 Too Many Requests
Retry-After: 300
X-RateLimit-Limit: 1
X-RateLimit-Remaining: 0
```

```json
{
  "error": "Too many feedback submissions were received from this device. Please try again later."
}
```

---

### Service Unavailable

```http
HTTP/1.1 503 Service Unavailable
```

```json
{
  "error": "We could not accept your feedback right now. Your draft remains saved on this device, so please try again."
}
```

---

## 3.8 cURL Example

Replace the placeholder UUID values with real IDs from Prisma Studio or the session configuration.

```bash
curl -i \
  -X POST "http://localhost:3000/api/feedback" \
  -H "Content-Type: application/json" \
  --data '{
    "submissionId": "6b9f6b86-8fc0-4e54-b064-2b60b848ac31",
    "sessionId": "REACT-2026-Q3",
    "formVersionId": "REPLACE-WITH-FORM-VERSION-UUID",
    "answers": [
      {
        "questionId": "REPLACE-WITH-RATING-QUESTION-UUID",
        "value": 5
      },
      {
        "questionId": "REPLACE-WITH-NPS-QUESTION-UUID",
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

Expected result:

```http
HTTP/1.1 202 Accepted
```

---

# 4. CSV Export API

## 4.1 Export Session Answers

```http
GET /api/admin/export/[sessionId]
```

Example:

```http
GET /api/admin/export/REACT-2026-Q3
```

This endpoint downloads one CSV row per answer.

---

## 4.2 Authentication Requirement

The caller must have an active admin session cookie.

Unauthenticated response:

```http
HTTP/1.1 401 Unauthorized
```

```json
{
  "error": "Administrator authentication is required."
}
```

---

## 4.3 Successful Response Headers

```http
Content-Type: text/csv; charset=utf-8
Content-Disposition: attachment; filename="greymatter-feedback-REACT-2026-Q3-2026-07-25.csv"
Cache-Control: no-store
```

---

## 4.4 CSV Columns

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

Example:

```csv
"React Summit 2026","REACT-2026-Q3","Advanced React Patterns","2fb0d18f-7d9d-4d3e-b5a0-d3f3af806955","2026-07-25T10:30:00.000Z","1","How useful was this workshop?","RATING","5",""
```

---

## 4.5 CSV Security Requirements

The CSV export must:

```text
Require administrator authentication.
Use Cache-Control: no-store.
Exclude client IP hashes.
Exclude raw user-agent metadata.
Escape quotation marks.
Quote comma-containing values.
Protect spreadsheet formula-like values.
```

Example spreadsheet formula protection:

```text
Original participant comment:
=SUM(A1:A10)

Exported value:
'=SUM(A1:A10)
```

---

# 5. PDF Report API

## 5.1 List Report History

```http
GET /api/admin/reports/[sessionId]
```

Example:

```http
GET /api/admin/reports/REACT-2026-Q3
```

### Successful Response

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

---

## 5.2 Queue PDF Report Generation

```http
POST /api/admin/reports/[sessionId]
```

Example:

```http
POST /api/admin/reports/REACT-2026-Q3
```

No request body is required in the baseline implementation.

### Successful Response

```http
HTTP/1.1 202 Accepted
```

```json
{
  "reportId": "a308665e-c131-45b2-9937-94b295f0a164",
  "status": "QUEUED"
}
```

---

## 5.3 Report Statuses

| Status | Meaning |
|---|---|
| `QUEUED` | Report record created and waiting for background worker |
| `PROCESSING` | Inngest worker is loading analytics, rendering PDF, or uploading |
| `COMPLETE` | Report is available through `url` |
| `FAILED` | Generation failed; `error` may contain safe operational detail |

---

## 5.4 Conflict Response

Only one queued or processing report is allowed per session.

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

---

## 5.5 Production Download Recommendation

In development, a report URL may look like:

```text
/reports/REACT-2026-Q3-report-id.pdf
```

In production, use a protected download flow:

```text
GET /api/admin/reports/[reportId]/download
```

Recommended behavior:

```text
1. Verify admin authentication.
2. Confirm report exists and is COMPLETE.
3. Confirm caller can access report session.
4. Generate short-lived signed S3/R2 URL.
5. Redirect to signed URL.
```

Do not expose sensitive report files through permanent public URLs.

---

# 6. Inngest API Integration

## 6.1 Inngest Endpoint

```http
GET /api/inngest
POST /api/inngest
PUT /api/inngest
```

This endpoint is for Inngest function registration, synchronization, and execution.

It is not intended for direct participant or administrator use.

---

## 6.2 Registered Events

| Event Name | Trigger | Worker |
|---|---|---|
| `feedback/submitted` | Valid participant API submission | `process-feedback-submission` |
| `report/generate.pdf` | Admin report request | `generate-pdf-report` |

---

## 6.3 `feedback/submitted` Event Contract

```ts
type FeedbackSubmittedEvent = {
  name: "feedback/submitted";
  data: {
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
};
```

Example:

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

---

## 6.4 `report/generate.pdf` Event Contract

```ts
type GeneratePdfReportEvent = {
  name: "report/generate.pdf";
  data: {
    reportId: string;
    sessionId: string;
    requestedBy: string;
  };
};
```

Example:

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

# 7. Administrator Server Actions

GreyMatter Feedback uses Next.js Server Actions for administrator web forms.

These are not external REST APIs, but they are important internal server interfaces.

| Server Action | Purpose |
|---|---|
| `loginAction` | Verify admin password and set signed session cookie |
| `logoutAction` | Clear signed session cookie |
| `createEventAction` | Create event or course |
| `createSessionAction` | Create session and QR-friendly session ID |
| `createDraftVersionAction` | Create a new draft form version |
| `addQuestionAction` | Add question to a draft |
| `deleteQuestionAction` | Delete question from draft |
| `moveQuestionAction` | Reorder draft question |
| `publishFormVersionAction` | Publish draft and archive previous version |
| `setSessionActiveAction` | Open or close participant feedback collection |

---

# 8. Error Handling Standards

## 8.1 Public Participant Errors

Participant-facing errors must be:

```text
Clear
Short
Actionable
Free of internal infrastructure details
```

Good example:

```json
{
  "error": "This feedback form has changed. Refresh the page before submitting your answers."
}
```

Unsafe example:

```json
{
  "error": "PrismaClientKnownRequestError P2002 on database connection..."
}
```

---

## 8.2 Administrator Errors

Administrator errors may include more operational context but must still avoid exposing secrets.

Good example:

```json
{
  "error": "The report could not be queued. Please try again."
}
```

Avoid exposing:

```text
Database URL
Storage secret
Inngest key
Raw stack trace
Full request headers
```

---

# 9. HTTP Status Code Reference

| Status | Meaning in GreyMatter Feedback |
|---:|---|
| `200 OK` | Successful read request |
| `202 Accepted` | Submission or report request queued for asynchronous processing |
| `400 Bad Request` | Invalid JSON, invalid request shape, or invalid answer |
| `401 Unauthorized` | Administrator authentication missing or invalid |
| `404 Not Found` | Session or resource does not exist |
| `409 Conflict` | Session closed, stale form version, or report already generating |
| `429 Too Many Requests` | Rate limit exceeded |
| `500 Internal Server Error` | Unexpected server failure |
| `503 Service Unavailable` | Dependency such as Inngest or rate-limit service unavailable |

---

# 10. API Extension Standards

When adding a new GreyMatter Feedback endpoint:

```text
[ ] Define route purpose clearly.
[ ] Decide whether it is public or admin-only.
[ ] Validate route parameters.
[ ] Validate JSON body with Zod.
[ ] Apply rate limiting for public endpoints.
[ ] Require authentication for admin endpoints.
[ ] Apply organization authorization in multi-tenant implementation.
[ ] Return safe errors.
[ ] Avoid exposing secrets.
[ ] Use no-store caching for sensitive exports.
[ ] Add tests.
[ ] Document request, response, and error formats.
```

---

# 11. Recommended Future Endpoints

| Endpoint | Method | Purpose |
|---|---|---|
| `/api/admin/reports/[reportId]/download` | `GET` | Protected signed PDF download |
| `/api/admin/events/import` | `POST` | Import event/session schedule CSV |
| `/api/admin/templates` | `GET`, `POST` | Manage reusable form templates |
| `/api/admin/templates/[templateId]` | `GET`, `PATCH`, `DELETE` | Manage one template |
| `/api/admin/webhooks` | `GET`, `POST` | Configure outbound integrations |
| `/api/admin/audit-logs` | `GET` | Review privileged actions |
| `/api/health` | `GET` | Service health check |
| `/api/admin/metrics/[sessionId]` | `GET` | Optional JSON analytics API |

---

# 12. API Security Checklist

```text
[ ] Public feedback API validates request body.
[ ] Public feedback API validates current session and form version.
[ ] Public feedback API validates question ownership.
[ ] Public feedback API rate limits submissions.
[ ] API never stores raw IP addresses.
[ ] Admin export API requires authentication.
[ ] Admin report APIs require authentication.
[ ] Report downloads are protected in production.
[ ] CSV export mitigates spreadsheet formula injection.
[ ] Inngest endpoint uses production signing key.
[ ] API responses do not expose secrets or stack traces.
[ ] Sensitive responses use Cache-Control: no-store.
```
