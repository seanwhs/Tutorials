# GreyMatter LMS — Software Requirements Document (SRD)

**Document type:** Software Requirements Document / Specification (SRS)
**Product:** GreyMatter LMS
**Version:** 1.0 (reflects implemented system, Parts 0–16)
**Status:** Baseline — approved
**Location:** `docs/SRD.md`
**Companion documents:** `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/USER_MANUAL.md`, Appendices A–I

**Conformance note:** This document follows the general structure of IEEE 830 / ISO/IEC/IEEE 29148 software requirements specifications, adapted for a web application context. Every functional requirement uses a "shall" statement, a unique identifier, and is traceable to its implementing module and verification method.

---

## 1. Introduction

### 1.1 Purpose

This SRD specifies the complete functional and non-functional software requirements for GreyMatter LMS at a level of detail sufficient for independent implementation and verification. Where the PRD (`docs/PRD.md`) describes business goals and user-facing outcomes, this document specifies exact system behavior: inputs, processing rules, outputs, preconditions, postconditions, and error conditions for every requirement.

### 1.2 Scope

GreyMatter LMS is a web-based learning management system comprising: a public content-discovery surface, an authenticated student learning surface, an authenticated instructor analytics surface, a content-authoring surface (Sanity Studio), and a set of automated background workflows. The system integrates with four external services (Clerk for identity, Sanity for content, Neon for relational storage, Inngest for workflow orchestration) and two optional external services (Resend for email, Upstash for rate limiting).

### 1.3 Definitions, Acronyms, and Abbreviations

See Appendix H (Glossary) for the complete, cross-referenced vocabulary. Key terms used throughout this document:

| Term | Definition |
|---|---|
| SRD | Software Requirements Document |
| CMS | Content Management System |
| ORM | Object-Relational Mapper |
| GROQ | Graph-Relational Object Queries (Sanity's query language) |
| RBAC | Role-Based Access Control |
| PII | Personally Identifiable Information |
| SLA | Service Level Agreement / expectation |
| Shall | Denotes a mandatory requirement |
| Should | Denotes a recommended, non-mandatory provision |

### 1.4 References

- `docs/PRD.md` — Product Requirements Document
- `docs/ARCHITECTURE.md` — Engineering Architecture Design Document
- Appendix B — Database Schema Reference
- Appendix C — Sanity Schema Reference
- Appendix F — Security Checklist
- Parts 0–16 — Full implementation record

### 1.5 Document Overview

Section 2 provides overall system context. Section 3 specifies functional requirements organized by subsystem, using the format described in 1.6. Section 4 specifies external interface requirements. Section 5 specifies non-functional requirements. Section 6 specifies data requirements. Section 7 defines verification and acceptance criteria.

### 1.6 Requirement Statement Format

Every functional requirement in Section 3 is stated as follows:

```text
REQ-ID: [Unique identifier]
Statement: The system shall [behavior]
Inputs: [what triggers or supplies this requirement]
Preconditions: [system state required for this requirement to apply]
Processing: [what the system does]
Postconditions: [resulting system state]
Outputs: [what is returned/displayed/persisted]
Error conditions: [what happens when preconditions are not met, or processing fails]
Priority: Mandatory | Should | May
Verification method: Test | Demonstration | Inspection | Analysis
Traceability: [implementing part / module]
```

---

## 2. Overall Description

### 2.1 Product Perspective

GreyMatter LMS is a new, self-contained system, not a component of a larger pre-existing system. It integrates with external SaaS providers (Section 4.3) but owns its own application logic, data schema, and user interface entirely.

### 2.2 Product Functions (Summary)

1. Public course discovery
2. Identity and session management (delegated)
3. Course enrollment
4. Structured lesson delivery
5. Interactive, server-graded assessment
6. Progress computation and persistence
7. Certificate issuance
8. Scheduled learner engagement (reminders, digests)
9. In-app notification management
10. Instructor reporting and intervention tooling
11. Content authoring (delegated to embedded CMS)

### 2.3 User Classes and Characteristics

| Class | Technical proficiency assumed | Frequency of use |
|---|---|---|
| Student | None | High — primary daily user |
| Instructor | Low | Moderate — periodic check-ins |
| Content Editor | Low–Moderate | Episodic — during content creation/review cycles |
| Administrator | Moderate (comfortable running a provided script) | Rare |
| External systems (Clerk, Inngest) | N/A (machine callers) | Continuous |

### 2.4 Operating Environment

- **Client:** any modern evergreen browser (Chromium, Firefox, Safari) supporting ES2017+ JavaScript; responsive layout supports viewport widths from mobile (≥320px) to desktop.
- **Server:** Node.js-compatible serverless runtime (Vercel), Next.js 16 application runtime.
- **Data stores:** Neon PostgreSQL (serverless, HTTP-driver compatible), Sanity hosted content API.
- **Background execution:** Inngest-managed function execution environment.

### 2.5 Design and Implementation Constraints

- All server-side database access shall occur through the Drizzle ORM query layer; no raw, unparameterized SQL string construction is permitted.
- All content access shall occur through the shared Sanity client using parameterized GROQ queries.
- All authentication shall be delegated to Clerk; no credential storage shall exist within the application's own database.
- All input crossing a network or process boundary (Server Action, Route Handler, webhook) shall be validated using Zod schemas before use.

### 2.6 Assumptions and Dependencies

- The system assumes continuous availability of its four core external dependencies (Clerk, Sanity, Neon, Inngest); the system does not specify offline or degraded-dependency operation beyond documented graceful-fallback behaviors (Section 3.9, 3.10).
- The system assumes a single content dataset and a single organizational tenant (see `docs/ARCHITECTURE.md`, §11).

---

## 3. Functional Requirements

### 3.1 Subsystem: Public Content Discovery

**REQ-PUB-001**
Statement: The system shall display a catalog of all courses where the course's `isPublished` field equals `true`.
Inputs: HTTP GET request to the catalog route.
Preconditions: None (unauthenticated access permitted).
Processing: Query the content system for all course documents matching the publication filter; sort alphabetically by title.
Postconditions: None (read-only).
Outputs: A rendered list of course cards, each displaying title, thumbnail, difficulty, category, and instructor name.
Error conditions: If zero courses match, an empty-state message shall be displayed instead of a blank page.
Priority: Mandatory
Verification method: Test
Traceability: Part 4

**REQ-PUB-002**
Statement: The system shall display a detail page for any course identified by a valid, published slug.
Inputs: A course slug path parameter.
Preconditions: A course with the given slug exists and `isPublished` equals `true`.
Processing: Retrieve the course document, its resolved category and instructor, its ordered chapters and lessons, and — if any lesson within the course has `isPreview` equal to `true` — the full content of that lesson.
Postconditions: None.
Outputs: Rendered course metadata, a chapter/lesson outline, and (if applicable) full preview lesson content.
Error conditions: If no course matches the given slug and publication state, the system shall respond with an HTTP 404 status and a user-facing "not found" page, not an error page or blank response.
Priority: Mandatory
Verification method: Test
Traceability: Part 4

**REQ-PUB-003**
Statement: The system shall never include assessment answer-key fields (correct option index, expected keywords) in any response reachable by an unauthenticated request.
Inputs: N/A (a constraint on all applicable query definitions).
Preconditions: N/A.
Processing: Every content query used by an unauthenticated-reachable code path shall use an explicit field projection excluding these fields; no query used in this context shall use an unrestricted field spread that would include them.
Postconditions: N/A.
Outputs: N/A.
Error conditions: N/A — this is a structural requirement verified by static inspection and automated regression test, not a runtime error condition.
Priority: Mandatory (security-critical)
Verification method: Test (automated regression test), Inspection (source review)
Traceability: Part 4, Part 11; Appendix F §F.5.1

---

### 3.2 Subsystem: Identity and Session Management

**REQ-AUTH-001**
Statement: The system shall allow any visitor to create an account via the delegated identity provider.
Inputs: Email address, password (or federated identity assertion).
Preconditions: None.
Processing: Delegate account creation entirely to the identity provider's hosted sign-up flow.
Postconditions: A session is established for the newly created account.
Outputs: Redirect to the authenticated dashboard.
Error conditions: Handled entirely by the identity provider's own UI (e.g., invalid email format, weak password).
Priority: Mandatory
Verification method: Test
Traceability: Part 6

**REQ-AUTH-002**
Statement: The system shall create an internal user record upon receipt of a verified account-creation event from the identity provider.
Inputs: A signed webhook payload containing the external identity provider's user identifier and primary email address.
Preconditions: The webhook's cryptographic signature is successfully verified against the configured signing secret.
Processing: Check whether an internal record already exists for the given external identifier; if not, create one with role `STUDENT` by default.
Postconditions: Exactly one internal user record exists for the given external identifier.
Outputs: HTTP 200 acknowledgment to the identity provider.
Error conditions: If signature verification fails, the system shall respond with HTTP 400 and shall not process the payload. If the payload lacks a primary email address, the system shall log the condition and shall not create a malformed record.
Priority: Mandatory
Verification method: Test
Traceability: Part 6

**REQ-AUTH-003**
Statement: The system shall process each uniquely identified webhook delivery from the identity provider at most once, regardless of redelivery.
Inputs: The webhook delivery's provider-assigned unique identifier.
Preconditions: None.
Processing: Attempt to record the delivery identifier against a uniqueness constraint prior to performing any associated data mutation; if the identifier has already been recorded, skip all further processing for this delivery.
Postconditions: No duplicate account-lifecycle side effects occur for a redelivered event.
Outputs: HTTP 200 acknowledgment in both the first-processing and duplicate-skip cases.
Error conditions: N/A.
Priority: Mandatory (reliability-critical)
Verification method: Test
Traceability: Part 6

**REQ-AUTH-004**
Statement: The system shall resolve a valid, authenticated session to a fully-provisioned internal user record even if the corresponding webhook has not yet completed processing.
Inputs: A verified session token.
Preconditions: The session token is valid per the identity provider.
Processing: Attempt to locate an existing internal record by the session's external identifier; if none exists, retrieve the account's details directly from the identity provider's API and create the internal record on demand.
Postconditions: Exactly one internal record exists for the given external identifier, regardless of whether this path or the webhook path created it first.
Outputs: A resolved internal user object (identifier, email, role).
Error conditions: If the identity provider's API is unreachable, the system shall treat the request as unauthenticated rather than raising an unhandled error.
Priority: Mandatory
Verification method: Test
Traceability: Part 6

**REQ-AUTH-005**
Statement: The system shall reject access to any authenticated-only route for a request lacking a valid session, redirecting the requester to the sign-in interface.
Inputs: Any request to a route under the authenticated route groups.
Preconditions: None.
Processing: Evaluate session validity before rendering any protected content.
Postconditions: An unauthenticated requester never receives protected content.
Outputs: An HTTP redirect response.
Error conditions: N/A.
Priority: Mandatory (security-critical)
Verification method: Test
Traceability: Part 6

**REQ-AUTH-006**
Statement: The system shall reject access to any role-restricted route for an authenticated user lacking the required role, redirecting the requester to a role-appropriate default location rather than the sign-in interface.
Inputs: Any request to a role-restricted route.
Preconditions: A valid session exists.
Processing: Evaluate the resolved internal user's role against the route's required role(s).
Postconditions: A user without the required role never receives role-restricted content.
Outputs: An HTTP redirect response to the general authenticated dashboard.
Error conditions: N/A.
Priority: Mandatory (security-critical)
Verification method: Test
Traceability: Part 6, Part 15

**REQ-AUTH-007**
Statement: The system shall permanently remove an internal user record and all data referencing it via a cascading relationship upon receipt of a verified account-deletion event.
Inputs: A signed account-deletion webhook payload.
Preconditions: Signature verification succeeds.
Processing: Delete the internal user record identified by the external identifier.
Postconditions: The user record, and every enrollment, progress record, module attempt, certificate, notification, and notification preference referencing it, no longer exist. Audit log entries referencing the user shall be retained with their user reference set to null rather than deleted.
Outputs: HTTP 200 acknowledgment.
Error conditions: If no matching internal record exists, the system shall acknowledge without error.
Priority: Mandatory
Verification method: Test
Traceability: Part 6, Part 5

---

### 3.3 Subsystem: Enrollment

**REQ-ENR-001**
Statement: The system shall allow an authenticated student to enroll in any course that both exists and has `isPublished` equal to `true`, as independently verified at the moment of enrollment.
Inputs: A course identifier, supplied by the requesting client.
Preconditions: A valid session exists for the requester.
Processing: Validate the input shape and length; independently re-fetch the course's existence and publication state from the content system, regardless of any client-supplied claim; verify no active enrollment already exists for this user/course pair; create an enrollment record and an initial (0%) progress record within a single atomic transaction; emit an enrollment event for asynchronous processing.
Postconditions: Exactly one enrollment record and one progress record exist for the user/course pair.
Outputs: A success result; the client's cached view of the user's enrollment list is invalidated immediately.
Error conditions: If the course does not exist or is not published, the system shall return a descriptive failure result without creating any record. If an active enrollment already exists, the system shall return a descriptive "already enrolled" failure result.
Priority: Mandatory
Verification method: Test
Traceability: Part 8

**REQ-ENR-002**
Statement: The system shall prevent the creation of more than one enrollment record for the same user/course pair under any condition, including concurrent enrollment requests.
Inputs: N/A (a data-integrity guarantee).
Preconditions: N/A.
Processing: A database-level uniqueness constraint on the combination of user identifier and course identifier shall govern this guarantee, independent of any application-level pre-check.
Postconditions: At most one enrollment record exists per user/course pair, at all times.
Outputs: N/A.
Error conditions: A concurrent request that would violate this constraint shall receive a constraint-violation error, which the system shall interpret as a non-fatal, already-enrolled outcome.
Priority: Mandatory (data-integrity-critical)
Verification method: Test (including concurrent-request test)
Traceability: Part 5, Part 8

**REQ-ENR-003**
Statement: The system shall restrict access to a course's authenticated learning content to users holding an active (non-cancelled) enrollment for that specific course.
Inputs: A request for course or lesson content within the authenticated area.
Preconditions: A valid session exists.
Processing: Independently verify, for the specific requesting user and specific requested course, that an enrollment record exists with a status other than cancelled.
Postconditions: N/A.
Outputs: If verified, the requested content. If not, an HTTP 404 response identical in form to a request for a genuinely nonexistent course.
Error conditions: The system shall not distinguish, in its response, between "course does not exist" and "course exists but user is not enrolled."
Priority: Mandatory (security-critical)
Verification method: Test
Traceability: Part 7, Part 8

---

### 3.4 Subsystem: Lesson Delivery

**REQ-LSN-001**
Statement: The system shall present a course's chapters and lessons in the order specified by their respective ordering fields, independent of their storage order.
Inputs: A request for a course outline or lesson player view.
Preconditions: The requesting user holds an active enrollment for the course (or the lesson is designated as a free preview, for unauthenticated contexts).
Processing: Retrieve chapters sorted by their order field; within each chapter, retrieve lessons sorted by their order field.
Postconditions: N/A.
Outputs: An ordered outline structure.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 4, Part 7

**REQ-LSN-002**
Statement: The system shall retrieve a specific lesson's content only by proving that the lesson belongs to the specific chapter and course claimed in the request, never by the lesson's identifier or slug in isolation.
Inputs: A course identifier/slug and a lesson identifier/slug.
Preconditions: N/A.
Processing: Execute a query that resolves the course, then its chapters, then their lessons, filtering for the requested lesson only within that resolved chain.
Postconditions: N/A.
Outputs: The lesson's content, if and only if it is reachable through the specified course's chapter/lesson chain. Otherwise, no result.
Error conditions: A lesson identifier that is valid but belongs to a different course shall yield no result, rendered as an HTTP 404, not the unrelated lesson's content.
Priority: Mandatory (security-critical)
Verification method: Test
Traceability: Part 4, Part 9

**REQ-LSN-003**
Statement: The system shall record the identifier of the most recently visited lesson for each active enrollment, and shall use this record to direct a returning student to that lesson rather than the course's first lesson.
Inputs: A lesson-view event for an authenticated, enrolled user.
Preconditions: An active enrollment and corresponding progress record exist.
Processing: Update the progress record's last-visited-lesson field and timestamp.
Postconditions: The progress record reflects the most recent lesson view.
Outputs: N/A (the update is a background-priority side effect of viewing a lesson; a failure of this specific update shall not affect the lesson content already being displayed to the user).
Error conditions: A failure in this recording step shall be logged but shall not be surfaced to the user or block lesson rendering.
Priority: Should
Verification method: Test
Traceability: Part 9

**REQ-LSN-004**
Statement: The system shall render an embedded video only if its source URL matches a domain on an explicit, predefined allow-list.
Inputs: A lesson's authored video URL.
Preconditions: N/A.
Processing: Parse the URL; extract a video identifier only if the URL's hostname matches an allow-listed provider; construct a new, trusted embed URL from that identifier.
Postconditions: N/A.
Outputs: A rendered video embed using the constructed, trusted URL — never the raw authored URL directly as an embed source.
Error conditions: If the URL does not match an allow-listed provider, or fails to parse, the system shall render nothing for that field rather than embedding an untrusted source.
Priority: Mandatory (security-critical)
Verification method: Test
Traceability: Part 9

---

### 3.5 Subsystem: Interactive Assessment and Grading

**REQ-ASM-001**
Statement: The system shall present interactive assessment content according to its authored type, resolved via an extensible registry, and shall render a distinct, non-fatal fallback for any assessment type the current system version does not recognize.
Inputs: A content block with a declared type.
Preconditions: N/A.
Processing: Look up the block's declared type against a registry of known types; if found, validate the block's structure against a schema specific to that type before rendering its corresponding component; if not found, or if validation fails, render an appropriate fallback message instead of failing the entire page.
Postconditions: N/A.
Outputs: Either the rendered interactive component, or one of two distinct fallback messages ("unsupported content type" vs. "content is misconfigured").
Error conditions: A runtime error within a specific rendered assessment component shall be contained to that component's display area and shall not affect the remainder of the page.
Priority: Mandatory
Verification method: Test
Traceability: Part 10

**REQ-ASM-002**
Statement: The system shall never transmit any assessment's answer key (correct option index, expected keyword list) to any client, under any authenticated or unauthenticated context, at any point prior to a grading operation.
Inputs: N/A (a structural constraint).
Preconditions: N/A.
Processing: All content queries reachable from client-rendered code shall explicitly exclude these fields via field-level projection. Exactly one query, invoked exclusively from server-side grading logic, shall include them.
Postconditions: N/A.
Outputs: N/A.
Error conditions: N/A — verified by static inspection and automated regression test.
Priority: Mandatory (security-critical)
Verification method: Test (automated regression test), Inspection
Traceability: Part 11; Appendix F §F.5.1

**REQ-ASM-003**
Statement: The system shall determine the correctness and score of every graded assessment submission exclusively through server-side computation, using an answer key retrieved directly by the server at the time of grading, and shall not accept, store, or trust any correctness or score value supplied by the client.
Inputs: A raw, ungraded submission (e.g., a selected option index, or free-text response).
Preconditions: The submission has passed shape and size validation.
Processing: Retrieve the authoritative assessment definition, scoped through the claimed course and lesson (per REQ-ASM-005); compute correctness/score via a dedicated grading function operating solely on the retrieved definition and the raw submission.
Postconditions: The persisted attempt record's score and correctness fields reflect only server-computed values.
Outputs: A grading result (correctness, score, message) returned to the client.
Error conditions: A submission failing shape validation for the specific assessment type shall be rejected with a descriptive error, without being persisted.
Priority: Mandatory (security-critical)
Verification method: Test (including adversarial/regression test)
Traceability: Part 11

**REQ-ASM-004**
Statement: The system shall enforce a maximum number of graded attempts per user per assessment module, rejecting any submission beyond that limit.
Inputs: A submission request.
Preconditions: A count of prior attempts for the given user and module is available.
Processing: Compare the prior attempt count against a configured maximum before performing any grading.
Postconditions: No attempt record is created once the limit has been reached.
Outputs: A descriptive rejection result.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 11

**REQ-ASM-005**
Statement: The system shall grade a submission only after independently verifying that the requesting user holds an active enrollment in the claimed course, and that the claimed assessment module is genuinely reachable through the claimed course's chapter/lesson/content chain.
Inputs: A course identifier, lesson identifier, and module identifier accompanying the submission.
Preconditions: N/A.
Processing: Verify active enrollment; execute a scoped query proving the module belongs to the specified lesson, which belongs to the specified course.
Postconditions: N/A.
Outputs: If either verification fails, a descriptive rejection result, without performing any grading.
Error conditions: The system shall return the same class of rejection response whether the course/lesson/module relationship is invalid or the user is unenrolled, avoiding disclosure of which specific condition failed.
Priority: Mandatory (security-critical)
Verification method: Test
Traceability: Part 11

**REQ-ASM-006**
Statement: The system shall process a submission bearing a previously-seen client-supplied idempotency key at most once, returning the originally recorded result for any repeat.
Inputs: An optional client-generated idempotency key accompanying a submission.
Preconditions: N/A.
Processing: Before grading, check whether an attempt already exists for the given user, module, and idempotency key; if so, return its recorded result without re-grading or re-persisting.
Postconditions: No duplicate attempt record is created for a repeated submission sharing an idempotency key.
Outputs: The original result, on repeat.
Error conditions: N/A.
Priority: Mandatory (reliability-critical)
Verification method: Test
Traceability: Part 11

**REQ-ASM-007**
Statement: The system shall reject any submission whose serialized size exceeds a configured maximum.
Inputs: A submission payload.
Preconditions: N/A.
Processing: Validate the serialized size of the submission field against a fixed limit prior to any further processing.
Postconditions: N/A.
Outputs: A descriptive rejection result identifying the submission as too large.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 11

**REQ-ASM-008**
Statement: The system shall record, within a single atomic transaction, an assessment attempt, an update to the corresponding lesson's progress status, and an audit log entry describing the outcome.
Inputs: A successfully graded submission.
Preconditions: Grading has completed.
Processing: Execute the attempt insert, progress upsert, and audit log insert as a single database transaction.
Postconditions: All three records exist, or none do — no partial state is observable.
Outputs: N/A.
Error conditions: If any component of the transaction fails, the entire transaction shall be rolled back and a generic failure result returned to the client.
Priority: Mandatory (data-integrity-critical)
Verification method: Test
Traceability: Part 11

---

### 3.6 Subsystem: Progress Computation

**REQ-PRG-001**
Statement: The system shall recalculate a course's overall completion percentage as an asynchronous, non-blocking operation following any graded assessment interaction, without requiring the initiating request to wait for its completion.
Inputs: An event signaling a graded interaction has occurred.
Preconditions: N/A.
Processing: Retrieve the course's full required-content structure; compare against the user's recorded lesson-level progress; mark a lesson complete once every contained assessment module has at least one recorded attempt; compute the overall percentage as completed lessons divided by total lessons.
Postconditions: The course's stored completion percentage reflects the current state.
Outputs: An updated completion percentage persisted to the user's course progress record.
Error conditions: If the referenced course can no longer be resolved, the operation shall terminate without error, leaving the prior state unchanged.
Priority: Mandatory
Verification method: Test
Traceability: Part 9, Part 12

**REQ-PRG-002**
Statement: The system shall emit a course-completion signal exactly once per user/course pair, at the moment the stored completion percentage first reaches 100%, and shall not re-emit this signal on subsequent recalculations once already at 100%.
Inputs: A recalculated completion percentage.
Preconditions: N/A.
Processing: Compare the newly computed percentage against the previously stored percentage before deciding whether to emit the completion signal.
Postconditions: N/A.
Outputs: A completion event, emitted at most once per crossing of the 100% threshold.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 12

---

### 3.7 Subsystem: Certificate Issuance

**REQ-CRT-001**
Statement: The system shall automatically issue a certificate upon receipt of a course-completion signal, without requiring any user-initiated request.
Inputs: A course-completion signal.
Preconditions: The referenced course/user completion percentage is independently re-verified to genuinely equal 100% at the time of processing.
Processing: Verify no certificate already exists for the user/course pair; generate a unique, sequential certificate number; snapshot the course's current title and the user's current email onto the new certificate record; record the certificate; dispatch a completion notification.
Postconditions: Exactly one certificate record exists for the user/course pair.
Outputs: A persisted certificate record; a completion notification (email and/or logged, per environment configuration).
Error conditions: If completion cannot be independently re-verified, no certificate shall be issued and the condition shall be recorded for operational visibility.
Priority: Mandatory
Verification method: Test
Traceability: Part 13

**REQ-CRT-002**
Statement: The system shall prevent the creation of more than one certificate for the same user/course pair under any condition, including concurrent completion signals.
Inputs: N/A (a data-integrity guarantee).
Preconditions: N/A.
Processing: A database-level uniqueness constraint on the combination of user identifier and course identifier shall govern this guarantee. Where a concurrent process encounters a constraint violation while attempting issuance, it shall recover by retrieving and returning the record created by the other, successful process rather than treating the condition as an error.
Postconditions: At most one certificate record exists per user/course pair, at all times.
Outputs: N/A.
Error conditions: N/A (handled via constraint plus race-recovery, per Processing).
Priority: Mandatory (data-integrity-critical)
Verification method: Test (including concurrent-signal test)
Traceability: Part 5, Part 13

**REQ-CRT-003**
Statement: The system shall preserve, on each issued certificate, the course title and recipient email exactly as they existed at the moment of issuance, independent of any subsequent change to the live course record or user account.
Inputs: N/A (a data-modeling constraint).
Preconditions: N/A.
Processing: The certificate record shall store its own copies of the course title and recipient email at creation time, rather than referencing the live values at display time.
Postconditions: A certificate's displayed course title and recipient email remain constant regardless of later edits to the source records.
Outputs: N/A.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test, Inspection
Traceability: Part 13

**REQ-CRT-004**
Statement: The system shall generate a downloadable PDF representation of a certificate on demand, using only data already recorded on the certificate itself.
Inputs: A request identifying a specific certificate.
Preconditions: The requesting user is authenticated and is the recipient of the identified certificate.
Processing: Retrieve the certificate record; render a PDF document containing its recipient, course title, certificate number, and issue date.
Postconditions: N/A.
Outputs: A binary PDF response with an appropriate downloadable-file disposition header.
Error conditions: If the certificate does not exist, or belongs to a different user, the system shall respond with HTTP 404, without disclosing which condition applied.
Priority: Mandatory
Verification method: Test
Traceability: Part 13

---

### 3.8 Subsystem: Scheduled Engagement and Notifications

**REQ-NOT-001**
Statement: The system shall, on a fixed daily schedule, identify every actively enrolled user whose course-level activity timestamp exceeds a configured inactivity threshold, and shall dispatch at most one inactivity reminder per user per rolling threshold period.
Inputs: The scheduled trigger; no user-supplied input.
Preconditions: N/A.
Processing: Query for qualifying enrollments in a single batch operation; for each, verify the user has not opted out of this notification type and has not already received one within the threshold period; if both checks pass, dispatch a reminder and record a corresponding notification.
Postconditions: N/A.
Outputs: Reminder emails and notification records for each qualifying, eligible user.
Error conditions: A failure processing one candidate shall not prevent processing of the remaining candidates in the same run.
Priority: Should
Verification method: Test
Traceability: Part 14

**REQ-NOT-002**
Statement: The system shall not send an inactivity reminder to a user who has disabled that notification type in their preferences, and shall treat the absence of a preference record as the default (enabled) state, not as an implicit opt-out.
Inputs: A candidate user's stored notification preference, if any.
Preconditions: N/A.
Processing: Resolve the effective preference via a single, centralized function that returns the enabled default whenever no explicit preference record exists.
Postconditions: N/A.
Outputs: N/A.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 14

**REQ-NOT-003**
Statement: The system shall not send an inactivity reminder for an enrollment whose status is not active (e.g., completed or cancelled).
Inputs: An enrollment's status field.
Preconditions: N/A.
Processing: The batch candidate query shall filter exclusively for active-status enrollments.
Postconditions: N/A.
Outputs: N/A.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 14

**REQ-NOT-004**
Statement: The system shall, on a fixed weekly schedule, dispatch a progress summary to every actively enrolled, notification-preference-eligible user, describing their completion percentage across every currently active enrollment.
Inputs: The scheduled trigger.
Preconditions: N/A.
Processing: Identify every user with at least one active enrollment; for each eligible user, retrieve their current enrolled-course summaries and dispatch a digest.
Postconditions: N/A.
Outputs: Digest emails and corresponding notification records.
Priority: Should
Verification method: Test
Traceability: Part 14

**REQ-NOT-005**
Statement: The system shall allow an authenticated user to view a history of notifications addressed to them, ordered most-recent-first, and to mark them as read.
Inputs: A request to view or acknowledge notifications.
Preconditions: A valid session exists.
Processing: Retrieve notification records scoped strictly to the requesting user; on acknowledgment, update the read timestamp for all currently unread records belonging to that user.
Postconditions: N/A.
Outputs: A list of notification records; an updated unread count.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 14

---

### 3.9 Subsystem: Instructor Reporting

**REQ-INS-001**
Statement: The system shall restrict access to any course-scoped instructor page to a user holding the instructor role and whose linked instructor profile matches the course's authored instructor reference.
Inputs: A request to a course-scoped instructor route.
Preconditions: A valid session exists.
Processing: Verify the requester's role; independently verify, via the content system, that the requester's linked identifier matches the target course's instructor reference.
Postconditions: N/A.
Outputs: If verified, the requested content. If not, an HTTP 404 response.
Error conditions: The system shall not distinguish, in its response, between a nonexistent course and a course owned by a different instructor.
Priority: Mandatory (security-critical)
Verification method: Test
Traceability: Part 15

**REQ-INS-002**
Statement: The system shall present a paginated listing of every student enrolled in a given course, showing status, completion percentage, and enrollment date, without loading the entire enrollment set into memory for any single request.
Inputs: A course identifier; an optional page number.
Preconditions: The requesting instructor is verified as the course owner (REQ-INS-001).
Processing: Execute a single bounded query retrieving one page of results, and a separate count query for total record count, using a stable, deterministic sort order.
Postconditions: N/A.
Outputs: A bounded list of student records for the requested page, plus a total count.
Error conditions: A request for a page beyond the available range shall return an empty result set, not an error.
Priority: Mandatory
Verification method: Test
Traceability: Part 15

**REQ-INS-003**
Statement: The system shall compute per-lesson completion counts and per-module average scores using database-level aggregation, for any course an instructor owns.
Inputs: A course identifier.
Preconditions: Ownership verified (REQ-INS-001).
Processing: Execute grouped aggregate queries against the progress and attempt tables, scoped to the target course's lessons and modules.
Postconditions: N/A.
Outputs: A per-lesson completion count list; a per-module average score and attempt count list.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 15

**REQ-INS-004**
Statement: The system shall identify, for a given course, every actively enrolled student whose completion percentage is below a configured threshold and whose last recorded activity exceeds a configured inactivity duration.
Inputs: A course identifier.
Preconditions: Ownership verified (REQ-INS-001).
Processing: Execute a filtered, joined query against enrollment and progress data using the configured thresholds.
Postconditions: N/A.
Outputs: A list of at-risk students with their completion percentage and last-activity date.
Error conditions: N/A.
Priority: Should
Verification method: Test
Traceability: Part 15

**REQ-INS-005**
Statement: The system shall allow an owning instructor to export the full student roster of a course as a downloadable, correctly-escaped CSV file.
Inputs: A course identifier.
Preconditions: Ownership verified (REQ-INS-001).
Processing: Retrieve every enrollment record for the course; format each field, escaping any value that could otherwise corrupt the CSV structure.
Postconditions: N/A.
Outputs: A CSV-formatted response with an appropriate downloadable-file disposition header.
Error conditions: N/A.
Priority: Should
Verification method: Test
Traceability: Part 15

**REQ-INS-006**
Statement: The system shall allow an owning instructor to manually trigger a reminder notification to a specific student, independent of the scheduled reminder cycle, and shall record this action distinctly from automated reminders.
Inputs: A course identifier and target student identifier.
Preconditions: Ownership verified (REQ-INS-001).
Processing: Dispatch a reminder to the specified student; record a notification entry flagged as manually triggered.
Postconditions: N/A.
Outputs: A confirmation of dispatch.
Error conditions: N/A.
Priority: Should
Verification method: Test
Traceability: Part 15

---

### 3.10 Subsystem: Content Authoring

**REQ-CNT-001**
Statement: The system shall provide a content-authoring interface, embedded within the application, independent of the application's own deployment lifecycle.
Inputs: N/A.
Preconditions: The authoring user is authenticated against the content system directly.
Processing: N/A (delegated to the embedded authoring tool).
Postconditions: N/A.
Outputs: N/A.
Priority: Mandatory
Verification method: Demonstration
Traceability: Part 3

**REQ-CNT-002**
Statement: The system shall reject, at authoring time, a quiz definition whose designated correct-option index does not correspond to an existing option.
Inputs: A quiz block definition, including its option list and correct-option index.
Preconditions: N/A.
Processing: Validate the correct-option index against the actual length of the option list before permitting the document to be published.
Postconditions: N/A.
Outputs: A validation error shown to the content author, blocking publication.
Error conditions: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 3

**REQ-CNT-003**
Statement: The system shall support marking any lesson as publicly viewable without enrollment, independent of the parent course's own public-visibility state.
Inputs: A lesson's designated preview flag.
Preconditions: N/A.
Processing: The public content-detail query shall honor this flag independently of the course's own publication flag when determining what content, if any, to render for unauthenticated visitors.
Postconditions: N/A.
Outputs: N/A.
Priority: Mandatory
Verification method: Test
Traceability: Part 3, Part 4

**REQ-CNT-004**
Statement: The system shall allow a course's public catalog visibility to be controlled independently of its authoring/draft state within the content system.
Inputs: A course's designated publication flag.
Preconditions: N/A.
Processing: The public catalog and detail queries shall filter on this flag in addition to, not instead of, the content system's own draft/published document state.
Postconditions: N/A.
Outputs: N/A.
Priority: Mandatory
Verification method: Test, Inspection
Traceability: Part 3; Appendix C §C.6

---

## 4. External Interface Requirements

### 4.1 User Interfaces

- The system shall present a responsive layout functional at minimum viewport widths of 320px, scaling appropriately through desktop widths.
- All interactive controls shall be operable via keyboard and shall present a visible focus indicator when navigated to via keyboard.
- All form controls shall be programmatically associated with their labels, and with any associated hint or error text, via appropriate ARIA attributes.
- All decorative-only visual elements shall be hidden from assistive technology.

### 4.2 Hardware Interfaces

Not applicable — the system is a web application with no direct hardware interface requirements.

### 4.3 Software Interfaces

| External system | Interface type | Purpose | Failure behavior requirement |
|---|---|---|---|
| Clerk | Hosted SDK components + signed webhook | Identity, session, account lifecycle | System shall treat unreachable identity API as unauthenticated (fail-closed) |
| Sanity | GROQ query API (HTTPS) | Content retrieval | A failed content fetch shall surface a generic error boundary, not raw error detail |
| Neon PostgreSQL | Pooled HTTP-based SQL connection | Transactional data storage | Connection failures shall be logged; the affected request shall fail gracefully with a generic error |
| Inngest | Event submission (HTTPS) + function-serving endpoint | Background workflow orchestration | A failed event emission shall not roll back an already-committed synchronous transaction |
| Resend | Transactional email API (HTTPS) | Email delivery | Absent configuration shall cause email content to be logged rather than sent, without raising an application error |
| Upstash Redis | Rate-limit check (HTTPS) | Request throttling | Absent configuration shall cause rate limiting to be bypassed (fail-open), not to block all traffic |

### 4.4 Communications Interfaces

All external communication shall occur over HTTPS. Inbound webhook requests shall be verified via provider-supplied cryptographic signatures prior to any processing, using the complete, unmodified request body.

---

## 5. Non-Functional Requirements

### 5.1 Performance Requirements

| ID | Requirement |
|---|---|
| NFR-PERF-001 | Aggregate reporting queries (roster, funnel, average scores, at-risk detection) shall be computed via database-level aggregation, not application-level iteration over raw rows. |
| NFR-PERF-002 | Any listing capable of returning an unbounded number of records shall be paginated at the query level. |
| NFR-PERF-003 | Independent data-fetching operations with no interdependency shall be executed concurrently rather than sequentially, wherever both are required to fulfill a single request. |

### 5.2 Security Requirements

Full detail: Appendix F. Summary obligations:

| ID | Requirement |
|---|---|
| NFR-SEC-001 | Every route requiring authentication shall enforce it at a shared boundary (layout-level), not ad hoc per page. |
| NFR-SEC-002 | Every resource-scoped operation shall independently verify the requester's relationship to the specific resource, in addition to route-level authentication. |
| NFR-SEC-003 | No unauthorized or unauthenticated response shall disclose whether a requested resource exists but is inaccessible, versus genuinely not existing. |
| NFR-SEC-004 | All webhook payloads shall be cryptographically verified before processing, using the unmodified original request body. |
| NFR-SEC-005 | All user-supplied input shall be validated for shape and bounded for size prior to use in any persistence operation. |
| NFR-SEC-006 | Error responses returned to any client shall never include raw exception detail, stack traces, or internal implementation identifiers. |
| NFR-SEC-007 | Secrets shall never be committed to version control; production and development credentials shall be provisioned independently. |
| NFR-SEC-008 | Sensitive, write-heavy operations shall be subject to rate limiting in production deployments. |

### 5.3 Reliability and Availability Requirements

| ID | Requirement |
|---|---|
| NFR-REL-001 | Any multi-step write representing a single logical business action shall be executed within a database transaction, ensuring all-or-nothing commitment. |
| NFR-REL-002 | Background workflow steps shall be independently retryable without re-executing already-successful steps or duplicating externally-visible side effects (e.g., a second email send). |
| NFR-REL-003 | A background workflow's terminal failure shall be recorded for operational visibility and shall be re-raised to permit the underlying orchestration engine's own retry mechanism to attempt recovery. |

### 5.4 Maintainability Requirements

| ID | Requirement |
|---|---|
| NFR-MAINT-001 | Every runtime validation schema and its corresponding static type shall be derived from a single definition. |
| NFR-MAINT-002 | Business logic bearing security or correctness significance (e.g., grading) shall be implemented as an independently unit-testable pure function, decoupled from request, authentication, and persistence concerns. |
| NFR-MAINT-003 | Any previously identified and remediated security defect shall be encoded as a permanent automated regression test. |

### 5.5 Accessibility Requirements

| ID | Requirement |
|---|---|
| NFR-A11Y-001 | The homepage and public course catalog shall report zero violations under an automated accessibility audit as a release gate. |
| NFR-A11Y-002 | All images conveying meaning shall include descriptive alternative text; this field shall be mandatory at the content-authoring layer. |
| NFR-A11Y-003 | All tabular data shall use semantic table markup with appropriately scoped headers. |

---

## 6. Data Requirements

### 6.1 Data Classification

| Classification | Storage system | Governing requirement |
|---|---|---|
| Authored content (courses, lessons, assessment definitions) | Content system (Sanity) | Read-heavy, rarely written, shared identically across all users |
| Transactional state (enrollment, progress, attempts, certificates, notifications) | Relational database (Neon) | Write-heavy, unique per user, strict consistency required |

Full schema: Appendix B (relational), Appendix C (content).

### 6.2 Data Integrity Requirements

- Every business rule requiring at-most-one-occurrence (enrollment per user/course, certificate per user/course, webhook-event processing, idempotent attempt processing) shall be enforced by a database-level uniqueness constraint, not solely by application logic.
- Certificate records shall store an immutable snapshot of course title and recipient email at issuance time.
- A relational foreign key reference to a content-system document identifier is not possible; every code path reading or writing such a reference shall independently verify the referenced relationship.

### 6.3 Data Retention

- Audit log entries shall be retained independent of the lifecycle of the user they reference; the user reference shall be nulled, not the record deleted, upon account deletion.
- All other user-referencing transactional records shall be deleted upon account deletion via cascading relationships.

---

## 7. Verification and Acceptance Criteria

### 7.1 Verification Methods Used in This Document

| Method | Description |
|---|---|
| Test | Automated unit or end-to-end test exercising the requirement directly |
| Demonstration | Manual walkthrough confirming observable behavior |
| Inspection | Source code or configuration review confirming structural compliance |
| Analysis | Reasoning-based confirmation where direct testing is impractical |

### 7.2 Acceptance Criteria — System-Level

The system shall be considered to meet this specification when:

1. Every requirement in Section 3 marked **Mandatory** is verified via its specified method with a passing result.
2. The complete end-to-end journey (account creation → enrollment → lesson completion → graded assessment → certificate issuance → instructor visibility) executes successfully as a single automated test against a deployed instance.
3. The full automated regression suite, including security-specific regression tests (REQ-ASM-002, REQ-PUB-003), passes with zero failures.
4. An automated accessibility audit of the homepage and public catalog reports zero violations.
5. A manual security review confirms every item in Appendix F, Section F.11 (pre-deployment security gate) is satisfied.

### 7.3 Traceability Matrix Reference

A complete requirement-to-implementation traceability table is maintained implicitly through the "Traceability" field of every requirement in Section 3, cross-referenced against Parts 0–16 of the implementation record and Appendices A–I of the technical reference documentation.
