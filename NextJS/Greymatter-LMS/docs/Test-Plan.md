# GreyMatter LMS — Software Test Plan (STP)

**Document type:** Software Test Plan
**Product:** GreyMatter LMS
**Version:** 1.0 (reflects implemented system, Parts 0–16)
**Status:** Baseline — approved
**Location:** `docs/TEST_PLAN.md`
**Companion documents:** `docs/PRD.md`, `docs/ARCHITECTURE.md`, `docs/SRD.md`, `docs/USER_MANUAL.md`, Appendices A–I

**Conformance note:** This document follows the general structure of an IEEE 829-style test plan, adapted for a web application with a hybrid content/transactional/workflow architecture. Every test item is traceable to a requirement identifier in `docs/SRD.md`.

---

## 1. Introduction

### 1.1 Purpose

This Software Test Plan (STP) defines the complete testing strategy for GreyMatter LMS: what will be tested, how, by whom, with what tools, in what environments, and against what pass/fail criteria. It converts the requirements specified in `docs/SRD.md` into a concrete, executable verification program spanning unit tests, integration tests, end-to-end tests, security tests, accessibility tests, and structured manual verification.

### 1.2 Scope

This plan covers verification of every subsystem specified in `docs/SRD.md` Section 3: public content discovery, identity and session management, enrollment, lesson delivery, interactive assessment and grading, progress computation, certificate issuance, scheduled engagement, instructor reporting, and content authoring. It also covers the non-functional requirements of Section 5 (performance, security, reliability, maintainability, accessibility) and the data requirements of Section 6.

This plan does not cover load/stress testing at scale beyond the volumes described in `docs/ARCHITECTURE.md` Section 11 ("moderate operational scale"), nor does it cover penetration testing by a third-party security firm — both are noted as recommended future extensions in Section 9.

### 1.3 References

- `docs/SRD.md` — every requirement ID referenced in this plan is defined there
- `docs/ARCHITECTURE.md` — system component boundaries referenced in test environment design
- Appendix E — background workflow patterns (informs workflow test design)
- Appendix F — security checklist (the direct source of every security test case)
- Part 16 — the implementation of the automated test suite itself (Vitest, Playwright, axe-core)

### 1.4 Definitions

| Term | Meaning in this document |
|---|---|
| Test item | A specific feature, function, or requirement under test |
| Test case | A concrete, executable procedure verifying one test item |
| Test suite | A collection of related test cases, executed together |
| Fixture | Predefined test data (seeded users, courses, enrollments) required for a test to run |
| Regression test | A test specifically encoding a previously found and fixed defect, to prevent recurrence |
| Fail-closed | A failure mode that denies access/action by default |
| Fail-open | A failure mode that permits access/action by default |

---

## 2. Test Strategy

### 2.1 Testing Levels

```text
┌─────────────────────────────────────────────────────────────┐
│  Level 5: Manual Exploratory & Acceptance Walkthrough          │
│  (case-study-driven, per docs/USER_MANUAL.md)                    │
├─────────────────────────────────────────────────────────────┤
│  Level 4: End-to-End (E2E) Tests — Playwright                    │
│  Full browser automation across real Server Actions/Routes         │
├─────────────────────────────────────────────────────────────┤
│  Level 3: Security & Accessibility Tests                           │
│  Regression guards, axe-core automated scans                        │
├─────────────────────────────────────────────────────────────┤
│  Level 2: Integration Tests                                          │
│  Real Neon + Sanity interaction, transaction/constraint behavior       │
├─────────────────────────────────────────────────────────────┤
│  Level 1: Unit Tests — Vitest                                          │
│  Pure functions in isolation: grading, validation schemas                │
└─────────────────────────────────────────────────────────────────┘
```

Each level tests a progressively larger and more integrated slice of the system, and each level's tests are cheaper and faster to run than the level above it — this shapes the pyramid-style balance of effort described in Section 2.2.

### 2.2 Test Pyramid Balance

| Level | Relative volume | Relative execution speed | Run frequency |
|---|---|---|---|
| Unit | High | Fastest (milliseconds) | Every commit, local dev loop |
| Integration | Moderate | Fast (seconds) | Every commit, CI |
| E2E | Low, but covering every critical journey | Slower (tens of seconds to minutes) | Every merge to main, pre-deploy |
| Security/Accessibility | Low, targeted | Fast to moderate | Every commit (security regression), pre-deploy (accessibility scan) |
| Manual | Lowest, exploratory only | Slowest | Pre-release, and after any change touching a trust boundary |

The strategy deliberately concentrates the largest volume of assertions at the unit level — particularly around `gradeSubmission` (Part 11), the single function bearing the most security consequence in the entire system — and reserves E2E testing for validating that the full stack of independently-tested pieces genuinely composes correctly end to end.

### 2.3 Testing Types

| Type | Objective | Primary tooling |
|---|---|---|
| Functional testing | Confirm each SRD requirement behaves as specified | Vitest, Playwright, manual |
| Regression testing | Confirm previously fixed defects (esp. security) never silently reappear | Vitest (dedicated regression files) |
| Security testing | Confirm trust boundaries hold under adversarial input | Vitest, Playwright, manual (Section 6) |
| Concurrency testing | Confirm database constraints resolve race conditions correctly | Manual scripted tests (`Promise.allSettled`-based) |
| Accessibility testing | Confirm WCAG-relevant automated checks pass | Playwright + `@axe-core/playwright` |
| Data integrity testing | Confirm constraints, cascades, and snapshotting behave correctly | Manual + Drizzle Studio inspection |
| Usability/acceptance testing | Confirm the system supports each documented user journey | Manual, per `docs/USER_MANUAL.md` case studies |

---

## 3. Test Environment

### 3.1 Environment Tiers

| Tier | Purpose | Data store configuration |
|---|---|---|
| Local development | Developer-run unit/integration tests, manual exploratory testing | Local `.env.local`, Neon `main` branch, Sanity `production` dataset (shared), Inngest local dev server |
| CI (continuous integration) | Automated unit, integration, and security regression tests on every commit | Ephemeral or dedicated test database configuration; no dependency on locally-configured secrets |
| Staging / Preview | Full E2E and accessibility test execution against a deployed, production-like build | Vercel preview deployment, Neon `main` branch, Clerk test-mode keys |
| Production (post-deploy smoke) | Final confirmation of the full journey against the live system | Neon `production` branch, Clerk production keys, Inngest production environment |

### 3.2 Required Tooling

| Tool | Role |
|---|---|
| Vitest | Unit test execution |
| `vite-tsconfig-paths` | Path alias resolution matching the application's own `@/` convention |
| Playwright | Browser automation for E2E and accessibility tests |
| `@axe-core/playwright` | Automated accessibility violation scanning |
| `@clerk/testing` | Test-mode authentication bypass for scripted E2E sign-up/sign-in |
| Drizzle Studio | Manual database state inspection during integration/manual testing |
| Sanity Vision | Manual GROQ query verification during content/security testing |
| Inngest local dev dashboard | Manual and automated inspection of background workflow execution and retry behavior |
| `ngrok` (or equivalent) | Local webhook delivery testing against Clerk |

### 3.3 Test Data / Fixtures

| Fixture | Description | Established in |
|---|---|---|
| Seed development user | A known, idempotently-created user with a real internal identifier | Part 5 (`db/seed.ts`) |
| Sample published course | "Introduction to Databases" — two lessons, one quiz block, one code-exercise block, one reflection block, one checkpoint block | Part 3 |
| Second, unrelated course | Used specifically to test cross-course scoping failures (lesson/module confusion) | Part 4 §Step 9, Part 8 §Step 6 |
| Promoted instructor account | A user promoted to `INSTRUCTOR` with a linked Sanity instructor profile | Part 15 |
| Backdated inactive enrollment | An enrollment with an artificially aged `last_activity_at`, used to test reminder eligibility | Part 14 |

---

## 4. Test Items and Traceability

Every test item below references its governing requirement ID from `docs/SRD.md`. This section is organized by subsystem, mirroring the SRD's own structure, so that a change to any requirement can be traced directly to the test cases that must be revisited.

### 4.1 Public Content Discovery (REQ-PUB-*)

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-PUB-001 | REQ-PUB-001 | E2E | Catalog displays only published courses, sorted alphabetically |
| TC-PUB-002 | REQ-PUB-001 | E2E | Catalog renders an empty-state message when zero courses are published |
| TC-PUB-003 | REQ-PUB-002 | E2E | Course detail page renders full metadata, outline, and preview lesson for a valid, published slug |
| TC-PUB-004 | REQ-PUB-002 | E2E | A nonexistent or unpublished slug returns an HTTP 404 with a friendly not-found page |
| TC-PUB-005 | REQ-PUB-003 | Unit (regression) | Public-facing query definitions contain no `correctOptionIndex` or `expectedKeywords` field in their projection |
| TC-PUB-006 | REQ-PUB-003 | Manual (Inspection) | Direct network-response inspection confirms no answer-key field is present in any unauthenticated request payload |

### 4.2 Identity and Session Management (REQ-AUTH-*)

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-AUTH-001 | REQ-AUTH-001 | E2E | New account creation via sign-up flow succeeds and establishes a session |
| TC-AUTH-002 | REQ-AUTH-002 | Manual | A verified `user.created` webhook creates exactly one internal record |
| TC-AUTH-003 | REQ-AUTH-002 | Manual | A webhook with an invalid signature is rejected with HTTP 400 and creates no record |
| TC-AUTH-004 | REQ-AUTH-003 | Manual | Resending an already-processed webhook delivery is recognized and skipped, producing no duplicate record |
| TC-AUTH-005 | REQ-AUTH-004 | Manual | Disabling webhook processing (simulated) still results in exactly one internal record via the on-demand fallback |
| TC-AUTH-006 | REQ-AUTH-005 | E2E | An unauthenticated request to a protected route redirects to sign-in |
| TC-AUTH-007 | REQ-AUTH-006 | E2E | An authenticated student requesting an instructor-only route redirects to the student dashboard, not sign-in |
| TC-AUTH-008 | REQ-AUTH-007 | Manual | Deleting a user via webhook removes the user record and every cascading dependent record; audit log entries persist with a nulled user reference |

### 4.3 Enrollment (REQ-ENR-*)

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-ENR-001 | REQ-ENR-001 | E2E | Enrolling in a valid, published course succeeds and creates enrollment + progress records |
| TC-ENR-002 | REQ-ENR-001 | Unit/Manual | Enrollment attempt against a course ID re-fetched as unpublished/nonexistent is rejected, regardless of any client-side assumption |
| TC-ENR-003 | REQ-ENR-001 | E2E | A second enrollment attempt for an already-enrolled course/user pair returns a descriptive "already enrolled" failure |
| TC-ENR-004 | REQ-ENR-002 | Manual (concurrency) | Two simultaneous enrollment requests for the same user/course pair result in exactly one enrollment record, verified via `Promise.allSettled` test script |
| TC-ENR-005 | REQ-ENR-003 | E2E | Direct URL navigation to a course dashboard page for an unenrolled (but existing, published) course returns HTTP 404 |
| TC-ENR-006 | REQ-ENR-003 | Manual | Setting an enrollment's status to cancelled removes dashboard access for that course without deleting historical data |

### 4.4 Lesson Delivery (REQ-LSN-*)

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-LSN-001 | REQ-LSN-001 | E2E | Chapters and lessons render in their authored order, independent of storage order |
| TC-LSN-002 | REQ-LSN-002 | Manual (Vision) | A lesson query scoped to Course A, given a lesson slug that belongs to Course B, returns no result |
| TC-LSN-003 | REQ-LSN-002 | E2E | Direct URL navigation combining a valid course slug with a mismatched lesson slug returns HTTP 404 |
| TC-LSN-004 | REQ-LSN-003 | E2E | Revisiting a course after viewing a non-first lesson shows "Resume learning" pointing at that specific lesson |
| TC-LSN-005 | REQ-LSN-004 | Unit | A YouTube/Vimeo URL is correctly parsed and rendered via constructed trusted embed URL |
| TC-LSN-006 | REQ-LSN-004 | Unit | A non-allow-listed domain URL renders nothing rather than an unchecked embed |

### 4.5 Interactive Assessment and Grading (REQ-ASM-*) — Highest Priority Subsystem

This subsystem receives the deepest test coverage in the entire plan, reflecting its designation as security-critical in the SRD.

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-ASM-001 | REQ-ASM-001 | E2E | Each known module type (quiz, code exercise, reflection, checkpoint) renders its correct interactive component |
| TC-ASM-002 | REQ-ASM-001 | Manual | An unrecognized block type renders an "unsupported content" fallback, not a crash |
| TC-ASM-003 | REQ-ASM-001 | Manual | A block failing config schema validation renders a "content is misconfigured" fallback |
| TC-ASM-004 | REQ-ASM-001 | Manual | A runtime error thrown by one module component is contained by its error boundary and does not affect the rest of the page |
| TC-ASM-005 | REQ-ASM-002 | Unit (regression) | `quizConfigSchema` does not define a `correctOptionIndex` property |
| TC-ASM-006 | REQ-ASM-002 | Unit (regression) | `codeExerciseConfigSchema` does not define an `expectedKeywords` property |
| TC-ASM-007 | REQ-ASM-002 | Manual (Inspection) | `grep`-based source scan confirms these two fields appear only inside the server-only assessment definition query |
| TC-ASM-008 | REQ-ASM-003 | Unit | `gradeSubmission` returns `isCorrect: true, score: 100` for a matching quiz submission |
| TC-ASM-009 | REQ-ASM-003 | Unit | `gradeSubmission` returns `isCorrect: false, score: 0` for a non-matching quiz submission |
| TC-ASM-010 | REQ-ASM-003 | Unit | `gradeSubmission` awards partial credit proportional to matched keywords for a code exercise |
| TC-ASM-011 | REQ-ASM-003 | Unit | `gradeSubmission` clamps computed score to the 0–100 range under all tested inputs |
| TC-ASM-012 | REQ-ASM-003 | Unit | `gradeSubmission` returns `null` correctness/score for reflection and checkpoint types |
| TC-ASM-013 | REQ-ASM-003 | E2E (adversarial) | Intercepting and modifying a submission's network payload to include a fabricated correctness claim has no effect on the persisted or returned result |
| TC-ASM-014 | REQ-ASM-003 | Manual (Inspection) | `grep`-based source scan confirms no reference to `clientComputedIsCorrect`/`clientComputedScore` exists anywhere in the codebase |
| TC-ASM-015 | REQ-ASM-004 | Unit/E2E | Submitting beyond the configured maximum attempt count is rejected with `ATTEMPT_LIMIT_EXCEEDED` |
| TC-ASM-016 | REQ-ASM-005 | Manual (Vision) | The server-only assessment definition query returns no result when the module ID is valid but does not belong to the claimed course/lesson chain |
| TC-ASM-017 | REQ-ASM-005 | E2E | A submission referencing a valid module ID under a mismatched course returns the same rejection class as a nonexistent module |
| TC-ASM-018 | REQ-ASM-005 | E2E | A submission from an unenrolled user is rejected with `NOT_ENROLLED` |
| TC-ASM-019 | REQ-ASM-006 | Manual | Replaying an identical request (same idempotency key) returns the original recorded result without creating a second attempt row |
| TC-ASM-020 | REQ-ASM-007 | Unit | A submission whose serialized size exceeds the configured limit is rejected as `SUBMISSION_TOO_LARGE` |
| TC-ASM-021 | REQ-ASM-008 | Manual | A successful submission results in exactly three new/updated records (attempt, progress, audit log) or none at all, verified by forcing a mid-transaction failure |

### 4.6 Progress Computation (REQ-PRG-*)

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-PRG-001 | REQ-PRG-001 | Manual/Inngest dashboard | Course completion percentage updates correctly following each graded module attempt |
| TC-PRG-002 | REQ-PRG-001 | Manual | A course whose referenced content can no longer be resolved terminates recalculation without error, leaving prior state intact |
| TC-PRG-003 | REQ-PRG-002 | Manual (Inngest dashboard) | Completion signal fires exactly once at the 100% threshold; subsequent recalculations at 100% do not re-fire it |

### 4.7 Certificate Issuance (REQ-CRT-*)

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-CRT-001 | REQ-CRT-001 | E2E | Completing every required lesson results in automatic certificate issuance without user action |
| TC-CRT-002 | REQ-CRT-001 | Manual | A completion signal that fails independent re-verification (percentage not genuinely 100%) does not issue a certificate |
| TC-CRT-003 | REQ-CRT-002 | Manual (concurrency) | Two simultaneous completion signals for the same user/course pair result in exactly one certificate, verified via a scripted concurrent-event test |
| TC-CRT-004 | REQ-CRT-003 | Manual | Renaming a course after certificate issuance does not alter the certificate's displayed title |
| TC-CRT-005 | REQ-CRT-004 | E2E | Certificate PDF downloads successfully and displays correct recipient, course title, number, and date |
| TC-CRT-006 | REQ-CRT-004 | E2E | A certificate download request for a certificate belonging to a different user returns HTTP 404 |

### 4.8 Scheduled Engagement and Notifications (REQ-NOT-*)

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-NOT-001 | REQ-NOT-001 | Manual (manual trigger) | A backdated, active, inactive enrollment receives a reminder on manual workflow invocation |
| TC-NOT-002 | REQ-NOT-001 | Manual | Re-invoking the workflow immediately afterward does not re-send a reminder to the same student within the threshold period |
| TC-NOT-003 | REQ-NOT-002 | Manual | Disabling the inactivity-reminder preference excludes that student from the next run |
| TC-NOT-004 | REQ-NOT-002 | Unit | The effective-preference resolver returns the enabled default when no preference record exists |
| TC-NOT-005 | REQ-NOT-003 | Manual | A completed enrollment is excluded from inactivity candidate selection regardless of activity recency |
| TC-NOT-006 | REQ-NOT-004 | Manual (manual trigger) | Weekly digest workflow dispatches a correct, per-course summary to every eligible active learner |
| TC-NOT-007 | REQ-NOT-005 | E2E | Notification center displays entries and correctly marks them read on open |

### 4.9 Instructor Reporting (REQ-INS-*)

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-INS-001 | REQ-INS-001 | E2E | An instructor can access their own owned course's analytics/roster pages |
| TC-INS-002 | REQ-INS-001 | E2E | An instructor attempting to access another instructor's course (or a nonexistent one) receives an HTTP 404, indistinguishably |
| TC-INS-003 | REQ-INS-002 | E2E | Roster pagination correctly bounds results per page and reports an accurate total count |
| TC-INS-004 | REQ-INS-003 | Manual | Lesson completion funnel and average score figures match manually computed expected values against known seeded data |
| TC-INS-005 | REQ-INS-004 | Manual | At-risk student detection correctly includes/excludes students based on threshold and inactivity boundary conditions |
| TC-INS-006 | REQ-INS-005 | Manual | Exported CSV opens correctly in spreadsheet software with properly escaped fields |
| TC-INS-007 | REQ-INS-006 | E2E | Manual reminder trigger dispatches an email and records a distinctly-flagged notification |

### 4.10 Content Authoring (REQ-CNT-*)

| Test ID | Requirement | Test type | Description |
|---|---|---|---|
| TC-CNT-001 | REQ-CNT-001 | Demonstration | Studio is reachable and functional at its embedded route, independent of a fresh application deploy |
| TC-CNT-002 | REQ-CNT-002 | Manual | Attempting to publish a quiz with an out-of-range correct-option index is blocked with a validation error |
| TC-CNT-003 | REQ-CNT-003 | E2E | A lesson marked as preview is visible publicly even when its parent course's public-visibility flag is off is NOT expected — confirm the inverse: preview lessons are only shown for courses that ARE catalog-visible, and preview status is independent only in the sense of per-lesson control within a visible course |
| TC-CNT-004 | REQ-CNT-004 | Manual | A course published in the content system's own sense, but with its custom visibility flag off, does not appear in the public catalog |

---

## 5. Non-Functional Test Items

### 5.1 Performance

| Test ID | Requirement | Description |
|---|---|---|
| TC-PERF-001 | NFR-PERF-001 | Confirm roster/funnel/score queries execute as grouped aggregate SQL, not per-row application loops (Inspection) |
| TC-PERF-002 | NFR-PERF-002 | Confirm roster query uses `LIMIT`/`OFFSET`; confirm no unbounded listing exists in the codebase (Inspection) |
| TC-PERF-003 | NFR-PERF-003 | Confirm independent data-fetch pairs (e.g., enrollment + progress lookups) use concurrent execution (Inspection) |

### 5.2 Security

Every item in Appendix F, Sections F.2 through F.10 constitutes a distinct test case in this plan. The complete Appendix F, Section F.11 pre-deployment gate is treated as the **exit criteria for the entire security test level** (see Section 7.2). Representative items:

| Test ID | Appendix F reference | Description |
|---|---|---|
| TC-SEC-001 | F.2.1 | Confirm `users.auth_provider_id` carries a database-level unique constraint |
| TC-SEC-002 | F.3.1 | Walk the complete resource-level authorization audit table; confirm every row is satisfied |
| TC-SEC-003 | F.3.2 | Confirm nonexistent and unauthorized resource requests return identical response signatures |
| TC-SEC-004 | F.6.1 | Send a webhook request with missing/invalid signature headers; confirm rejection and no processing |
| TC-SEC-005 | F.6.2 | Resend a previously-delivered webhook; confirm it is recognized and skipped |
| TC-SEC-006 | F.9.1 | Confirm `git log --all --full-history -- .env.local` returns empty |
| TC-SEC-007 | F.9.3 | Review every `NEXT_PUBLIC_`-prefixed variable and confirm none carries genuinely secret material |

### 5.3 Accessibility

| Test ID | Requirement | Description |
|---|---|---|
| TC-A11Y-001 | NFR-A11Y-001 | Automated axe-core scan of homepage reports zero violations |
| TC-A11Y-002 | NFR-A11Y-001 | Automated axe-core scan of course catalog reports zero violations |
| TC-A11Y-003 | NFR-A11Y-002 | Confirm image `alt` field is mandatory at the schema level (Inspection) |
| TC-A11Y-004 | NFR-A11Y-003 | Confirm the instructor roster uses semantic `<table>`/`<th scope="col">` markup (Inspection) |

### 5.4 Reliability

| Test ID | Requirement | Description |
|---|---|---|
| TC-REL-001 | NFR-REL-001 | Force a failure partway through the attempt/progress/audit transaction; confirm no partial state persists |
| TC-REL-002 | NFR-REL-002 | Simulate a step failure inside a background function; confirm retry does not re-execute already-succeeded steps or resend an email |
| TC-REL-003 | NFR-REL-003 | Force a background function to fail terminally; confirm a failure record is created and the underlying engine attempts a retry |

---

## 6. Security Test Approach (Detailed)

Given the elevated priority of assessment integrity throughout this system, security testing receives a dedicated, structured approach beyond the item list in Section 5.2.

### 6.1 The Adversarial Test Protocol (Assessment Integrity)

This protocol must be executed manually at least once per release, in addition to its automated regression coverage (TC-ASM-005, TC-ASM-006, TC-ASM-014):

```text
Step 1: Open a lesson containing a graded quiz module.
Step 2: Open browser developer tools; inspect the network response
        carrying the lesson's content payload.
Step 3: Confirm — by direct visual inspection of the raw response
        body — that no field resembling an answer key is present.
Step 4: Submit a deliberately incorrect answer.
Step 5: Intercept the outgoing submission request; attempt to inject
        any field suggesting a correct/passing outcome.
Step 6: Confirm the returned result and persisted database record
        both reflect the TRUE server-computed outcome (incorrect),
        unaffected by the injected field.
Step 7: Attempt to replay a captured submission request for a
        DIFFERENT course/lesson/module combination than it was
        originally issued for; confirm rejection.
```

A failure at any step of this protocol is treated as a **release-blocking critical defect**, per Section 8.2.

### 6.2 Concurrency Test Protocol

Applied to every business rule requiring "at most one" enforcement (enrollment, certificate issuance):

```text
Step 1: Establish a clean baseline state (no existing record for the
        target user/resource pair).
Step 2: Fire two logically identical write operations using
        Promise.allSettled, with no artificial delay between them.
Step 3: Inspect both settlement outcomes — expect exactly one
        "fulfilled" and one "rejected" (or both "fulfilled" if the
        implementation includes race-recovery logic).
Step 4: Query the database directly; confirm exactly one record
        exists for the target pair, never zero, never two.
```

### 6.3 Webhook Trust Test Protocol

```text
Step 1: Send a POST request to the webhook endpoint with valid JSON
        but no Svix headers. Expect HTTP 400.
Step 2: Send a POST request with Svix headers present but an invalid
        signature value. Expect HTTP 400.
Step 3: Send a genuinely valid, correctly signed request. Expect
        HTTP 200 and correct processing.
Step 4: Resend the exact same valid request a second time. Expect
        HTTP 200, but confirm via log inspection that processing was
        SKIPPED as a recognized duplicate, and confirm no duplicate
        database record was created.
```

---

## 7. Entry and Exit Criteria

### 7.1 Entry Criteria (per testing level)

| Level | Entry criteria |
|---|---|
| Unit | Code compiles (`tsc --noEmit` passes); function under test is implemented |
| Integration | Unit tests for the same subsystem pass; local Neon/Sanity connectivity confirmed |
| E2E | `npm run build` succeeds; local dev server and Inngest dev server both running; seed data present |
| Security | All functional tests for the affected subsystem pass |
| Accessibility | Target page renders without runtime errors |
| Manual/Acceptance | All automated levels pass on the candidate build |

### 7.2 Exit Criteria (release gate)

The system is considered ready for release when **all** of the following hold:

1. 100% of test cases marked against a **Mandatory** SRD requirement pass.
2. Zero failures in the automated regression suite, with particular attention to TC-ASM-005, TC-ASM-006, and TC-ASM-014 (assessment-integrity regression guards).
3. The full end-to-end journey test (signup → enrollment → lesson completion → graded assessment → certificate → instructor visibility) passes against a deployed staging build.
4. Zero automated accessibility violations on the homepage and course catalog.
5. The Section 6.1 Adversarial Test Protocol has been executed manually within the current release cycle with no findings.
6. The Appendix F §F.11 pre-deployment security checklist is fully checked.
7. No open defect is classified as **Critical** or **High** per Section 8.2 severity definitions.

### 7.3 Suspension Criteria

Testing shall be suspended and escalated immediately, without proceeding to remaining test cases in the current session, if:

- The Adversarial Test Protocol (Section 6.1) reveals that a client-supplied value influences a graded outcome.
- A concurrency test (Section 6.2) produces more than one record for an "at most one" business rule.
- A `.env.local` (or equivalent secret file) is found in version control history.

---

## 8. Defect Management

### 8.1 Defect Lifecycle

```text
New → Confirmed → Assigned → In Progress → Fixed →
  Verified (re-run failing test case) → Closed

                          │
                          ▼ (if verification fails)
                     Reopened → Assigned (loop)
```

### 8.2 Severity Classification

| Severity | Definition | Example |
|---|---|---|
| **Critical** | A security control fails; data integrity is violated; the core learning journey is unusable | Client-supplied score is trusted; duplicate certificate issued |
| **High** | A functional requirement fails under normal use; no workaround exists | Enrollment does not persist; pagination never advances |
| **Medium** | A functional requirement fails under an edge case; a workaround exists | CSV export omits a rarely-populated field |
| **Low** | Cosmetic, non-blocking, or a "Should"-priority requirement gap | Accessibility scan reports a non-blocking advisory |

Any **Critical** finding blocks release per Section 7.2 and 7.3, regardless of how many other exit criteria are otherwise satisfied.

### 8.3 Regression Policy

Every Critical or High defect, once fixed, shall have a corresponding automated test case added to the permanent regression suite before the fix is considered complete — mirroring the precedent set for the Part 10/11 assessment-integrity vulnerability, which is now permanently encoded as TC-ASM-005/006/014 rather than relying solely on manual retesting.

---

## 9. Risks and Contingencies

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| A future code change reintroduces answer-key exposure | Low (guarded by regression tests) | Critical | TC-ASM-005/006/007/014 run on every commit; any reintroduction fails CI immediately |
| Concurrency defects not caught by single-request testing | Medium | Critical | Dedicated concurrency protocol (Section 6.2) required at every release, not just once |
| External service (Clerk/Sanity/Neon/Inngest) unavailability during test execution | Medium | Test execution delay, not product defect | Tests scheduled with awareness of provider status; local dev fallbacks (email, rate limiting) reduce hard dependency where designed |
| Accessibility regressions introduced by new UI components | Medium | Low–Medium | Automated axe-core scan on every relevant page addition, not only the two currently covered |
| No third-party penetration test performed | Known, accepted | Unknown | Documented as an explicit gap; recommended before handling real production learner data at meaningful scale |
| Load/stress testing beyond "moderate scale" not performed | Known, accepted | Unknown at high scale | Documented in `docs/ARCHITECTURE.md` §11; revisit fan-out pattern (Appendix E §E.8) before scaling beyond low-thousands concurrent learners |

---

## 10. Roles and Responsibilities

| Role | Responsibility |
|---|---|
| Engineer authoring a change | Writes/updates unit tests for any new pure logic; runs the full local verification suite before proposing a change |
| Reviewer | Confirms new resource-scoped code includes both route-level and resource-level authorization checks (per the audit table in Appendix F §F.3.1) before approval |
| Release owner | Confirms all Section 7.2 exit criteria before authorizing deployment |
| Security reviewer | Executes the Section 6 protocols manually at least once per release cycle |

---

## 11. Schedule

Testing activities map directly onto the phased implementation record (Parts 1–16) and continue as an ongoing discipline post-implementation:

| Phase | Testing activity |
|---|---|
| During Parts 1–9 implementation | Manual, per-part verification steps as documented in each part's own "Verification" section |
| During Part 10–11 implementation | Manual adversarial verification of the vulnerability and its fix (the origin of Section 6.1's protocol) |
| During Part 12–15 implementation | Manual Inngest dashboard inspection, manual concurrency scripts (the origin of Section 6.2's protocol) |
| Part 16 | Formal introduction of automated unit (Vitest), E2E (Playwright), and accessibility (axe-core) suites; first execution of the full release gate (Section 7.2) |
| Post-implementation, ongoing | Every subsequent change follows the entry/exit criteria in Section 7; every release re-executes the full automated suite plus the manual protocols in Section 6 |

---

## 12. Appendices

### 12.1 Sample Test Case — Full Detail Format

For illustration, one test case expanded to full procedural detail (all other test cases in Section 4 follow this same underlying structure, abbreviated to table form for readability):

```text
Test ID: TC-ASM-013
Title: Adversarial network-payload manipulation does not affect grading outcome
Requirement: REQ-ASM-003
Priority: Critical
Preconditions:
  - A signed-in student account, enrolled in a course containing a
    quiz module with a known correct answer.
Procedure:
  1. Navigate to the lesson containing the quiz module.
  2. Select an option KNOWN to be incorrect.
  3. Open browser developer tools, Network tab.
  4. Click "Submit answer."
  5. Locate the outgoing submission request.
  6. Duplicate the request via "Copy as fetch"; modify the payload to
     add a field resembling a correctness claim (e.g.,
     "clientComputedIsCorrect": true); execute the modified request
     from the developer console.
  7. Reload the lesson page.
Expected Result:
  - The quiz displays the TRUE server-computed outcome: incorrect.
  - The database record for this attempt shows is_correct = false,
    score = 0.
  - The injected field has no observable effect on either the UI or
    the persisted record.
Actual Result: [recorded at execution time]
Status: [Pass / Fail]
```

### 12.2 Automated Suite Inventory Reference

| Suite file | Level | Covers |
|---|---|---|
| `tests/unit/grading.test.ts` | Unit | REQ-ASM-003 (correctness computation across all module types) |
| `tests/unit/validation.test.ts` | Unit | REQ-ENR-001, REQ-ASM-007 (schema-level input validation) |
| `tests/unit/grading-security.test.ts` | Unit (regression) | REQ-ASM-002 (permanent guard against answer-key exposure) |
| `tests/e2e/accessibility.spec.ts` | Accessibility | NFR-A11Y-001 |
| `tests/e2e/full-journey.spec.ts` | E2E | REQ-AUTH-001, REQ-ENR-001, REQ-LSN-*, REQ-ASM-*, REQ-PRG-*, REQ-CRT-001 (composite journey) |

### 12.3 Manual Test Log Template

```text
Date:                    Tester:                  Build/Commit:
Test ID:                 Result: Pass / Fail       Severity (if Fail):
Notes:
```
