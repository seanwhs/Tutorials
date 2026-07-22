# GreyMatter LMS — API Documentation

**Document type:** API Reference Documentation
**Product:** GreyMatter LMS
**Version:** 1.0 (reflects implemented system, Parts 0–16)
**Status:** Baseline — approved
**Location:** `docs/API_REFERENCE.md`
**Companion documents:** `docs/ARCHITECTURE.md`, `docs/SRD.md`, `docs/DATA_DICTIONARY.md`, Appendix D, Appendix F

---

## 1. Introduction

### 1.1 How to Read This Document

GreyMatter LMS does not expose one uniform REST API. It exposes **two distinct programmatic interfaces**, chosen deliberately based on who the caller is (see `docs/ARCHITECTURE.md` §6.1):

| Interface | Section | Who calls it | Addressable by URL? |
|---|---|---|---|
| **Route Handlers** | Section 3 | External systems (Clerk, Inngest), browsers requesting files | Yes — real, stable URLs |
| **Server Actions** | Section 4 | GreyMatter's own UI, exclusively | No — invoked internally, not a public URL surface |

If you are integrating an **external system** with GreyMatter LMS, or building a monitoring/ops tool against it, Section 3 is your API. If you are a developer working *inside* the GreyMatter codebase and need to know what a specific mutation accepts and returns, Section 4 is your reference. Section 5 documents the **inbound webhook contract** GreyMatter expects to receive. Section 6 documents the **event catalog** GreyMatter emits internally via Inngest — not a public API, but documented here because it is the closest thing this system has to an internal service contract.

### 1.2 Base URL

```text
Production:  https://<your-production-domain>
Local dev:   http://localhost:3000
```

### 1.3 Authentication Model

All Route Handlers and Server Actions fall into one of four authentication categories:

| Category | Mechanism |
|---|---|
| **Public** | No authentication required |
| **Session-authenticated** | A valid Clerk session cookie, resolved server-side via `requireUser()` |
| **Role-authenticated** | A valid session plus a specific role (`INSTRUCTOR`, `ADMIN`), resolved via `requireRole()` |
| **Signature-authenticated** | No session — verified via a cryptographic signature specific to the calling external system |

### 1.4 Response Conventions

Route Handlers return standard HTTP responses with JSON bodies (except file-download endpoints, which return binary content with appropriate `Content-Type`/`Content-Disposition` headers). Server Actions return plain, structured JavaScript objects — never raw thrown exceptions on expected failure paths.

**Standard error body shape (Route Handlers):**
```json
{
  "error": "Human-readable, safe description of the failure"
}
```

**Standard result shape (Server Actions):**
```ts
{
  success: boolean;
  error?: string;       // present on failure, enrollment-style actions
  errorCode?: string;   // present on failure, assessment-submission actions
  message?: string;
  // ...action-specific fields
}
```

Per `docs/SRD.md` NFR-SEC-006, no response body — Route Handler or Server Action — ever includes a raw stack trace, internal exception message, or implementation-identifying detail.

---

## 2. Conventions Used Throughout This Document

### 2.1 Endpoint Entry Format

```text
METHOD  /path/[param]
Auth:        [category from 1.3]
Description: [one-line summary]

Path Parameters
  param      type      description

Request Body / Query Parameters
  field      type      required?      description

Success Response
  Status:    200
  Body:      { ... }

Error Responses
  Status     Condition
  4xx        ...
  5xx        ...
```

### 2.2 Server Action Entry Format

```text
functionName(args): Promise<ReturnType>
File:        [source location]
Auth:        [category from 1.3]
Description: [one-line summary]

Parameters
  name       type      description

Returns
  { ... }    — shape and meaning of each field

Failure Modes
  condition  →  resulting error / errorCode
```

---

## 3. Route Handlers (HTTP API)

### 3.1 `GET /api/health`

```text
METHOD  GET /api/health
Auth:        Public
Description: Liveness probe for uptime monitoring and deployment verification.
```

**Request:** No parameters, no body.

**Success Response**
```text
Status: 200 OK
Content-Type: application/json
```
```json
{
  "status": "ok",
  "name": "GreyMatter LMS",
  "environment": "production",
  "timestamp": "2025-01-15T10:32:00.000Z"
}
```

**Error Responses**

| Status | Condition |
|---|---|
| 405 | Any method other than `GET` |

**Notes:** This endpoint performs no downstream checks against Neon, Sanity, Clerk, or Inngest — it confirms only that the Next.js application process itself is responding. It is intentionally minimal and safe to call unauthenticated, at any frequency, from an external monitoring service.

---

### 3.2 `POST /api/webhooks/clerk`

```text
METHOD  POST /api/webhooks/clerk
Auth:        Signature-authenticated (Svix, on behalf of Clerk)
Description: Receives account lifecycle events from the Clerk identity provider.
```

**Required Headers**

| Header | Description |
|---|---|
| `svix-id` | Unique identifier for this specific delivery attempt |
| `svix-timestamp` | Delivery timestamp |
| `svix-signature` | HMAC signature computed over the raw request body |
| `Content-Type` | `application/json` |

**Request Body:** A Clerk event envelope. Only three `type` values are processed; all others are logged and acknowledged without action.

```json
{
  "type": "user.created",
  "data": {
    "id": "user_2abc123xyz",
    "email_addresses": [
      { "id": "idn_abc", "email_address": "student@example.com" }
    ],
    "primary_email_address_id": "idn_abc"
  }
}
```

**Handled event types**

| `type` | Effect |
|---|---|
| `user.created` | Creates an internal user record (role `STUDENT`) if one does not already exist for this external identifier; emits a `user/created` event |
| `user.updated` | Updates the internal user's email if it has changed |
| `user.deleted` | Deletes the internal user record and every cascading dependent record |

**Success Response**
```text
Status: 200 OK
```
```json
{ "received": true }
```
```json
{ "received": true, "duplicate": true }
```
*(the second form is returned when this exact delivery identifier has already been processed)*

**Error Responses**

| Status | Condition |
|---|---|
| 400 | One or more required Svix headers are missing |
| 400 | Signature verification fails against the configured signing secret |

**Notes:**
- The raw, unparsed request body is used for signature verification — this endpoint must never be placed behind any proxy or middleware layer that consumes the request body before verification occurs.
- This endpoint is idempotent: redelivering an already-processed event returns `200` with `duplicate: true` and performs no further processing (see `docs/SRD.md` REQ-AUTH-003).
- A processing failure *after* successful signature verification (e.g., a malformed payload) is logged internally; the endpoint still returns `200` to avoid triggering an unbounded retry loop from the provider for a non-transient failure. See `docs/ARCHITECTURE.md` §7.5.

---

### 3.3 `GET|POST|PUT /api/inngest`

```text
METHOD  GET | POST | PUT  /api/inngest
Auth:        Signing key (production) / none (local development)
Description: Function discovery and invocation endpoint for the Inngest workflow engine.
```

| Method | Purpose |
|---|---|
| `GET` | Inngest's dashboard/tooling introspects available functions |
| `PUT` | Registers this endpoint's function list with Inngest's infrastructure |
| `POST` | Inngest invokes a specific function when its trigger condition is met |

**Notes:** This endpoint is not intended for direct human or third-party use. It is called exclusively by Inngest's own infrastructure. In local development, no signing key is required; in production, requests are verified against `INNGEST_SIGNING_KEY`.

---

### 3.4 `GET /api/certificates/[certificateId]/download`

```text
METHOD  GET /api/certificates/[certificateId]/download
Auth:        Session-authenticated
Description: Generates and streams a certificate as a downloadable PDF.
```

**Path Parameters**

| Parameter | Type | Description |
|---|---|---|
| `certificateId` | UUID (string) | The internal identifier of the certificate record |

**Success Response**
```text
Status: 200 OK
Content-Type: application/pdf
Content-Disposition: attachment; filename="GM-2025-000042.pdf"
```
Body: binary PDF data.

**Error Responses**

| Status | Condition |
|---|---|
| 401 / redirect | No valid session present (redirected to sign-in by the authentication layer) |
| 404 | No certificate exists with the given ID, **or** the certificate exists but does not belong to the requesting user |

**Notes:** Per `docs/SRD.md` REQ-CRT-004, the two 404-triggering conditions are deliberately indistinguishable in the response — the endpoint never discloses whether an inaccessible certificate ID belongs to someone else or doesn't exist at all. The PDF is generated fresh on every request from data already stored on the certificate record; no file is persisted to storage between requests.

---

### 3.5 `GET /api/instructor/courses/[courseId]/students/export`

```text
METHOD  GET /api/instructor/courses/[courseId]/students/export
Auth:        Role-authenticated (INSTRUCTOR) + resource ownership
Description: Exports the full student roster of an owned course as CSV.
```

**Path Parameters**

| Parameter | Type | Description |
|---|---|---|
| `courseId` | String | The Sanity course document `_id` |

**Success Response**
```text
Status: 200 OK
Content-Type: text/csv
Content-Disposition: attachment; filename="course-<courseId>-students.csv"
```
Body:
```csv
"Email","Status","Completion %","Enrolled At"
"student@example.com","ACTIVE","45","2025-01-03T00:00:00.000Z"
```

**Error Responses**

| Status | Condition |
|---|---|
| 401 / redirect | No valid session, or session lacks `INSTRUCTOR` role |
| 404 | The course does not exist, or exists but is not linked to the requesting instructor's profile |

**Notes:** Every field is CSV-escaped (quoted, with internal quotes doubled) before being written, per `docs/SRD.md` REQ-INS-005.

---

## 4. Server Actions Reference

Server Actions are not reachable at a stable public URL. They are documented here for engineers working within the codebase, and for completeness of the system's full programmatic surface. Every Server Action begins with authentication resolution (`requireUser()` or equivalent) as its first step, regardless of whether that step is repeated explicitly in the description below.

### 4.1 `enrollInCourse`

```text
enrollInCourse(previousState, formData): Promise<EnrollActionResult>
File:        app/dashboard/courses/actions.ts
Auth:        Session-authenticated
Description: Enrolls the current user in a course, after independently
             re-verifying its existence and publication state.
```

**Parameters**

| Name | Type | Description |
|---|---|---|
| `previousState` | `EnrollActionResult \| null` | The prior call's result (required by the `useActionState` calling convention; not otherwise used) |
| `formData` | `FormData` | Must contain a `courseId` field (string, 1–200 characters) |

**Returns**
```ts
{
  success: boolean;
  error?: string;
}
```

**Failure Modes**

| Condition | `error` message |
|---|---|
| `courseId` missing or fails shape validation | `"Invalid course selection."` |
| Course does not exist, or `isPublished` is `false` (re-verified server-side, never trusted from the client) | `"This course is not available for enrollment."` |
| An active enrollment already exists for this user/course pair | `"You are already enrolled in this course."` |
| Database write fails (including a concurrent-request race resolved by the unique constraint) | `"Something went wrong. Please try again."` |

**Side effects on success:** Creates one `enrollments` row and one `course_progress` row within a single transaction; emits a `course/enrolled` event; invalidates cached views of `/dashboard` and the specific course's dashboard page.

---

### 4.2 `markLessonVisited`

```text
markLessonVisited(courseId, lessonId): Promise<void>
File:        app/dashboard/courses/[courseSlug]/lessons/actions.ts
Auth:        Session-authenticated
Description: Best-effort bookkeeping recording the most recently visited
             lesson, to power "resume learning."
```

**Parameters**

| Name | Type | Description |
|---|---|---|
| `courseId` | `string` | The Sanity course `_id` |
| `lessonId` | `string` | The Sanity lesson `_id` |

**Returns:** No meaningful return value.

**Failure Modes:** Any internal failure is caught and logged server-side; this action never surfaces an error to the caller and never blocks or delays lesson rendering. This is a deliberate fire-and-forget design (see `docs/ARCHITECTURE.md` §8.1).

---

### 4.3 `submitModuleAttempt`

```text
submitModuleAttempt(input): Promise<ModuleSubmissionResult>
File:        lib/modules/submit-module-attempt.ts
Auth:        Session-authenticated + resource-level (enrollment) verification
Description: The single, secure entry point for grading any interactive
             assessment submission. THE most security-significant
             Server Action in the system.
```

**Parameters**

`input` (validated as `unknown` before use — see `docs/SRD.md` REQ-ASM-003):

| Field | Type | Required | Notes |
|---|---|---|---|
| `lessonId` | `string` | Yes | Sanity lesson `_id` |
| `courseId` | `string` | Yes | Sanity course `_id` |
| `moduleId` | `string` | Yes | Authored `moduleId` value |
| `submission` | `unknown` | Yes | Shape varies by module type; max 5,000 serialized characters |
| `idempotencyKey` | `string` (UUID) | No | Client-generated; enables safe retry of a single logical submission |

**Returns**
```ts
{
  success: boolean;
  isCorrect: boolean | null;   // null for module types with no correctness concept
  score: number | null;         // 0–100, or null
  message: string;
  errorCode?: ModuleErrorCode;  // present only on failure
}
```

**Failure Modes**

| `errorCode` | Condition |
|---|---|
| `INVALID_SUBMISSION` | Input fails shape validation, or fails validation specific to the resolved module type |
| `SUBMISSION_TOO_LARGE` | Serialized submission exceeds the size limit |
| `NOT_ENROLLED` | Requester lacks an active enrollment for the claimed course |
| `MODULE_NOT_FOUND` | The module/lesson/course chain cannot be independently verified (identical response whether the mismatch is in course, lesson, or module) |
| `ATTEMPT_LIMIT_EXCEEDED` | The configured maximum attempt count for this module has been reached |
| `UNKNOWN_ERROR` | An unexpected failure occurred during grading or persistence |

**Idempotent replay:** If `idempotencyKey` matches a previously processed submission for this user/module, the original recorded result is returned without re-grading or re-persisting.

**Side effects on success:** Within a single transaction — inserts a `module_attempts` row with server-computed `score`/`isCorrect`; upserts the corresponding `lesson_progress` row to `IN_PROGRESS`; inserts an `audit_logs` entry. After the transaction commits, emits a `lesson/completed` event.

**Security note:** This action never accepts, reads, or persists any client-supplied correctness or score value. See `docs/ARCHITECTURE.md` §7.2 for the complete rationale, and Appendix F §F.5 for the full audit checklist governing this function.

---

### 4.4 `updateNotificationPreferences`

```text
updateNotificationPreferences(formData): Promise<void>
File:        app/dashboard/settings/actions.ts
Auth:        Session-authenticated
Description: Updates the current user's notification opt-in/opt-out state.
```

**Parameters**

`formData` fields:

| Field | Type | Description |
|---|---|---|
| `inactivityRemindersEnabled` | `"on"` or absent | Checkbox convention — presence means `true` |
| `weeklyDigestEnabled` | `"on"` or absent | Same convention |

**Returns:** No meaningful return value (revalidates the settings page on success).

**Failure Modes:** Input failing schema validation is silently ignored (no partial update applied); no error is surfaced distinctly from a no-op in the current implementation.

---

### 4.5 `getMyNotifications`

```text
getMyNotifications(): Promise<Notification[]>
File:        app/dashboard/notifications/actions.ts
Auth:        Session-authenticated
Description: Retrieves the current user's full notification history,
             most recent first.
```

**Returns:** An array of notification records (see `docs/DATA_DICTIONARY.md` §2.10), scoped strictly to the requesting user.

---

### 4.6 `markNotificationsRead`

```text
markNotificationsRead(): Promise<void>
File:        app/dashboard/notifications/actions.ts
Auth:        Session-authenticated
Description: Marks every currently unread notification belonging to the
             current user as read.
```

**Returns:** No meaningful return value.

---

### 4.7 `sendManualReminder`

```text
sendManualReminder(courseId, userId, userEmail): Promise<void>
File:        app/instructor/courses/[courseId]/students/actions.ts
Auth:        Role-authenticated (INSTRUCTOR) + resource ownership
Description: Instructor-triggered, immediate reminder dispatch to a
             specific student, independent of the scheduled reminder cycle.
```

**Parameters**

| Name | Type | Description |
|---|---|---|
| `courseId` | `string` | The Sanity course `_id`; ownership is verified before any further processing |
| `userId` | `string` | The internal Neon `users.id` of the target student |
| `userEmail` | `string` | The target student's email, used directly in the dispatched message |

**Returns:** No meaningful return value on success.

**Failure Modes:** If the requesting instructor does not own the specified course, the ownership check redirects/blocks before this action's body executes (per `requireCourseOwnership`).

**Side effects:** Dispatches an email (or logs it, per environment configuration); records a `notifications` entry with `metadata.manual: true`, distinguishing it from automated reminders.

---

## 5. Inbound Webhook Contract

GreyMatter LMS currently accepts exactly one class of inbound webhook.

### 5.1 Clerk Account Lifecycle Webhooks

**Endpoint:** `POST /api/webhooks/clerk` (see Section 3.2 for full detail)

**Subscribed event types:** `user.created`, `user.updated`, `user.deleted`

**Delivery guarantees expected of the sender:** at-least-once delivery (i.e., the same event may be delivered more than once). GreyMatter's endpoint is designed to tolerate this per REQ-AUTH-003.

**Signature scheme:** Svix (HMAC-based), verified using the endpoint-specific signing secret configured via `CLERK_WEBHOOK_SIGNING_SECRET`. Verification is performed over the exact, unmodified request body bytes.

**Adding a new inbound webhook (guidance for future integrators):** any new inbound webhook source must follow the identical four-step pattern documented in `docs/ARCHITECTURE.md` §7.5 and Appendix E's reusable idempotency pattern: (1) verify signature, (2) extract a provider-supplied unique delivery ID, (3) attempt to record that ID against a uniqueness constraint before any processing, (4) proceed only if the recording succeeds.

---

## 6. Internal Event Catalog (Inngest)

These are not a public API — they are internal, typed contracts between application code and GreyMatter's background workflow engine. Documented here because they represent the system's internal service-to-service interface, and because extending the system (adding a new workflow) requires understanding this catalog.

### 6.1 Event Definitions

| Event name | Payload shape | Emitted by | Consumed by |
|---|---|---|---|
| `user/created` | `{ userId: string; email: string }` | Clerk webhook handler, upon first-time internal user creation | `onboard-user` |
| `course/enrolled` | `{ userId: string; courseId: string; enrollmentId: string }` | `enrollInCourse` Server Action, after transaction commit | `confirm-enrollment` |
| `lesson/completed` | `{ userId: string; courseId: string; lessonId: string }` | `submitModuleAttempt` Server Action, after every successful graded submission | `recalculate-course-progress` |
| `course/completed` | `{ userId: string; courseId: string }` | `recalculate-course-progress`, exactly once per crossing of the 100% threshold | `issue-certificate` |

### 6.2 Scheduled (Cron-Triggered) Functions

These have no inbound event — they trigger on a fixed schedule.

| Function | Schedule (UTC) | Purpose |
|---|---|---|
| `send-inactivity-reminders` | Daily, `0 9 * * *` | Identifies and reminds active, inactive-beyond-threshold learners |
| `send-weekly-digest` | Weekly, Monday `0 8 * * 1` | Sends a per-user progress summary across all active enrollments |

### 6.3 Emitting a New Event (Guidance)

1. Add the event name and payload shape to `inngest/events.ts`'s `GreyMatterEvents` type.
2. Emit via `inngest.send({ name, data })` **after** any associated synchronous database transaction has committed — never from inside the transaction itself, and never before it (see `docs/ARCHITECTURE.md` §8.2, "why events are emitted after, not inside, a transaction").
3. Define a consuming function via `inngest.createFunction({ event: "..." }, handler)` and register it in `inngest/functions/index.ts`.

---

## 7. Rate Limiting

| Scope | Limit | Applies to |
|---|---|---|
| Per authenticated user | 10 requests / 10 seconds (sliding window) | `submitModuleAttempt` |

**Behavior when exceeded:** the Server Action returns `{ success: false, errorCode: "UNKNOWN_ERROR", message: "Too many requests. Please slow down." }` — a `429`-equivalent condition, though expressed as a structured Server Action result rather than an HTTP status code, since Server Actions do not carry independent HTTP status semantics from the caller's perspective.

**Configuration dependency:** this control is only active when `UPSTASH_REDIS_REST_URL` / `UPSTASH_REDIS_REST_TOKEN` are configured. In their absence, the check is bypassed entirely (fail-open) — see `docs/ARCHITECTURE.md` §11 and Appendix F §F.7.2 for the documented operational implication of this design choice.

---

## 8. Error Code Reference (Consolidated)

| Code | Surface | Meaning |
|---|---|---|
| HTTP `400` | Route Handlers | Malformed or unverifiable request (missing/invalid webhook signature or headers) |
| HTTP `404` | Route Handlers | Resource does not exist, **or** exists but is not accessible to the requester (deliberately indistinguishable) |
| HTTP `405` | Route Handlers | Method not supported at this endpoint |
| HTTP `200` with `duplicate: true` | Clerk webhook | A previously-processed delivery was recognized and skipped |
| `NOT_ENROLLED` | `submitModuleAttempt` | No active enrollment for the claimed course |
| `MODULE_NOT_FOUND` | `submitModuleAttempt` | Course/lesson/module relationship could not be verified |
| `ATTEMPT_LIMIT_EXCEEDED` | `submitModuleAttempt` | Maximum attempts reached for this module |
| `INVALID_SUBMISSION` | `submitModuleAttempt` | Shape validation failed |
| `SUBMISSION_TOO_LARGE` | `submitModuleAttempt` | Size limit exceeded |
| `UNKNOWN_ERROR` | `submitModuleAttempt` | Unexpected internal failure, or rate limit exceeded |

---

## 9. Versioning and Change Policy

GreyMatter LMS does not currently expose a versioned public API (e.g., `/api/v1/...`) — the Route Handler surface is small, internally consumed by named external integrations (Clerk, Inngest) rather than third-party developers, and the Server Action surface is not externally addressable at all. Any change to a Route Handler's request/response contract, or to an Inngest event's payload shape, should be treated as a breaking change requiring:

1. Coordinated update of the corresponding external configuration (e.g., Clerk webhook subscription, Inngest event schema).
2. An update to this document in the same change set.
3. Review against `docs/SRD.md` Section 4 (External Interface Requirements) for any requirement implicated by the change.
