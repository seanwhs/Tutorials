# GreyMatter LMS — Product Requirements Document

**Document type:** Product Requirements Document (PRD)
**Product:** GreyMatter LMS
**Status:** Approved for build — reference implementation complete (Parts 0–16)
**Location:** `docs/PRD.md`

---

## 1. Document Purpose

This PRD defines what GreyMatter LMS is, who it serves, what it must do, and how success will be measured. It is the authoritative source for *what* the product must accomplish — the companion tutorial series (Part 0–16) and technical appendices define *how* it was built. Where this document and the implementation diverge, this document should be treated as the source of intent, and the implementation should be reconciled toward it.

---

## 2. Product Summary

GreyMatter LMS is a full-stack Learning Management System that allows instructors to author structured, multimedia course content and allows students to enroll, learn, complete interactive assessments, track progress, and earn verifiable certificates. The platform is built on a **hybrid data architecture**: content is authored and published through a headless CMS (Sanity), while all per-user transactional state — enrollments, progress, assessment attempts, certificates — is stored in a relational database (Neon PostgreSQL). Work that does not need to block a user's immediate request (progress recalculation, email notifications, certificate generation, scheduled reminders) is handled by a durable background workflow engine (Inngest).

---

## 3. Problem Statement

Organizations and independent educators need a way to publish structured course content and reliably track whether learners actually absorbed it — not just whether they clicked through pages. Existing solutions typically fail in one of two ways:

1. **Content-management-only tools** treat "progress" as an afterthought — a simple percentage with no real integrity guarantee, and no defense against a learner falsifying their own results.
2. **Monolithic LMS platforms** entangle content authoring and per-user progress tracking in a single database and codebase, making it difficult to scale content editorial workflows independently from transactional load, and often failing to enforce that graded assessments are evaluated authoritatively on the server rather than trusted from the client.

GreyMatter LMS addresses both failure modes directly: content and transactional data are deliberately separated into systems best suited to each, and every graded interaction is evaluated exclusively server-side, against an answer key the learner's browser never receives.

---

## 4. Goals

### 4.1 Business / Product Goals

- Deliver a functioning, deployable LMS demonstrating a defensible, production-realistic architecture (content/transactional/workflow separation).
- Guarantee assessment integrity: a learner cannot manipulate their own graded outcome, under any circumstance, including direct network-request manipulation.
- Support three distinct operational roles (Student, Instructor, Administrator) plus a fourth, out-of-band authoring role (Content Editor) without conflating their permissions.
- Provide instructors with actionable, real analytics (completion funnels, at-risk learners, average scores) rather than superficial vanity metrics.
- Automate the operational lifecycle of course completion (detection → certificate issuance → notification) without manual intervention.

### 4.2 User Goals

**As a Student**, I want to:
- Browse available courses without needing an account.
- Enroll in a course and know my enrollment was recorded reliably.
- Read lesson content, watch embedded video, and complete interactive exercises.
- Trust that my quiz/exercise results are graded fairly and cannot be corrupted.
- Resume exactly where I left off.
- See my progress and receive occasional, non-spammy reminders if I go inactive.
- Earn and download a certificate the moment I finish a course, with no manual request required.

**As an Instructor**, I want to:
- See which students are enrolled in my courses and how they're progressing.
- Identify which lessons or assessments have the highest drop-off or lowest average score.
- Identify at-risk (inactive, low-progress) students and reach out to them directly.
- Export a roster for my own records.
- Trust that only I can view data for courses I actually own.

**As an Administrator**, I want to:
- Manage user roles.
- Review platform-wide enrollment and completion data.
- Inspect and, where needed, retry failed background workflows.

**As a Content Editor**, I want to:
- Author courses, chapters, lessons, and embedded interactive assessments in a dedicated authoring tool, entirely independent of the application's runtime concerns.
- Control whether a course is publicly visible without needing engineering involvement.
- Preview draft content before publishing it.

### 4.3 Non-Goals (Explicitly Out of Scope)

- Payment processing / paid course purchasing (architecture allows for future extension; not implemented).
- Live/synchronous instruction (video conferencing, live cohorts).
- Peer-to-peer discussion, forums, or social features.
- Mobile native applications (the web application is responsive but not packaged as a native app).
- Full administrative UI for every capability listed for the Administrator role — role management scripting exists; a dedicated `/admin` interface is explicitly deferred (see Section 11, Known Gaps).
- Real code execution/sandboxing for code exercises — submissions are evaluated via keyword matching, not by running submitted code.

---

## 5. Target Audience & Personas

| Persona | Description | Primary need |
|---|---|---|
| **The Student** | A self-directed learner, may have no prior relationship with the platform, discovers courses via public browsing. | Frictionless enrollment, trustworthy progress tracking, tangible proof of completion. |
| **The Instructor** | Owns one or more courses, cares about learner outcomes, not necessarily technical. | Visibility into learner behavior; tools to intervene before a learner disengages entirely. |
| **The Administrator** | Operates the platform itself, responsible for user governance and system health. | Oversight and control without needing to touch the database directly. |
| **The Content Editor** | Authors and maintains course material; may or may not be the same person as the Instructor. | An authoring experience decoupled from application deployment cycles. |

---

## 6. Scope

### 6.1 In Scope — Functional Areas

1. Public course discovery (catalog + detail pages, no authentication required)
2. Authentication and account lifecycle (sign-up, sign-in, session management)
3. Role-based access (Student / Instructor / Administrator)
4. Course enrollment
5. Structured lesson delivery (chapters, lessons, rich content, video)
6. Interactive, extensible assessment modules (quiz, short-answer, reflection, checkpoint)
7. Server-authoritative grading
8. Progress tracking (per-lesson and per-course)
9. Resume-learning behavior
10. Automated certificate issuance
11. Scheduled learner engagement (inactivity reminders, weekly digest)
12. In-app notification center
13. Instructor analytics and student roster management
14. Automated testing and production deployment tooling

### 6.2 Out of Scope

See Section 4.3.

---

## 7. Functional Requirements

Requirements are grouped by role and numbered for traceability. Each maps to the part(s) of the reference implementation that satisfy it.

### 7.1 Public / Unauthenticated

| ID | Requirement | Implemented in |
|---|---|---|
| FR-1.1 | Any visitor can view a catalog of published courses without signing in. | Part 4 |
| FR-1.2 | Any visitor can view a course's detail page, including a free preview lesson if one is designated. | Part 4 |
| FR-1.3 | An unpublished or nonexistent course must return an honest "not found" state, never a broken page or a silent empty response. | Part 4 |
| FR-1.4 | Quiz/exercise correct-answer data must never be present in any response served to an unauthenticated request. | Part 4, Part 11 |

### 7.2 Student

| ID | Requirement | Implemented in |
|---|---|---|
| FR-2.1 | A visitor can create an account and sign in. | Part 6 |
| FR-2.2 | Upon account creation, an internal user record must be created and remain consistent even under webhook delivery delay or duplication. | Part 6 |
| FR-2.3 | An authenticated student can enroll in any published course exactly once; a second enrollment attempt must not create a duplicate record, even under concurrent requests. | Part 8 |
| FR-2.4 | A student can only view dashboard content for courses they are actively enrolled in; attempting to access an unenrolled course by URL must return an honest "not found" state. | Part 7, Part 8 |
| FR-2.5 | A student can navigate a course's chapters and lessons in order, with next/previous controls. | Part 9 |
| FR-2.6 | A student's most recently visited lesson must be recorded and used to power a "resume learning" affordance. | Part 9 |
| FR-2.7 | A student can submit an answer to any interactive module type; the result must be computed exclusively server-side. | Part 10, Part 11 |
| FR-2.8 | A student may not exceed a defined maximum number of attempts per assessment module. | Part 11 |
| FR-2.9 | A retried/duplicated submission request must not be double-recorded. | Part 11 |
| FR-2.10 | Lesson and course completion percentage must update automatically following a graded interaction, without requiring the student to take further action. | Part 11, Part 12 |
| FR-2.11 | Upon reaching 100% course completion, a certificate must be issued automatically, exactly once, even under concurrent completion signals. | Part 13 |
| FR-2.12 | A student can view and download their certificate as a PDF at any time after issuance. | Part 13 |
| FR-2.13 | A student who has been inactive on an active course for a defined period should receive at most one reminder per period, and no reminder at all if they have opted out or already completed the course. | Part 14 |
| FR-2.14 | A student can view and manage their notification preferences. | Part 14 |
| FR-2.15 | A student can view an in-app history of notifications sent to them. | Part 14 |

### 7.3 Instructor

| ID | Requirement | Implemented in |
|---|---|---|
| FR-3.1 | An instructor may only access analytics/roster data for courses they are the linked author of. | Part 15 |
| FR-3.2 | An instructor can view total enrollment count for each owned course. | Part 15 |
| FR-3.3 | An instructor can view a paginated list of every enrolled student, their status, and their completion percentage. | Part 15 |
| FR-3.4 | An instructor can export the student roster as a CSV file. | Part 15 |
| FR-3.5 | An instructor can view a per-lesson completion funnel for an owned course. | Part 15 |
| FR-3.6 | An instructor can view average assessment scores, grouped by module. | Part 15 |
| FR-3.7 | An instructor can identify students who are enrolled, below a completion threshold, and inactive beyond a defined period. | Part 15 |
| FR-3.8 | An instructor can manually trigger a reminder to a specific student. | Part 15 |

### 7.4 Administrator

| ID | Requirement | Implemented in / status |
|---|---|---|
| FR-4.1 | An administrator can change a user's role. | Implemented as a manual, scripted operation (Part 15); dedicated UI deferred (Section 11). |
| FR-4.2 | Role-gated routes must exist and correctly reject non-administrators. | `requireRole("ADMIN")` implemented and available (Part 6); no admin-only page currently calls it. |
| FR-4.3 | Platform-wide enrollment/workflow review and retry tooling. | Deferred — see Section 11. |

### 7.5 Content Editor

| ID | Requirement | Implemented in |
|---|---|---|
| FR-5.1 | A content editor can author courses, chapters, and lessons through a dedicated authoring interface, independent of the deployed application's own release cycle. | Part 3 |
| FR-5.2 | A content editor can insert rich text, images, video embeds, and interactive assessment blocks directly within lesson content, in any order. | Part 3 |
| FR-5.3 | A content editor can preview unpublished content before making it publicly visible. | Part 3, Appendix C §C.6 |
| FR-5.4 | A course's public visibility must be independently controllable from its authoring/draft state. | Part 3 |
| FR-5.5 | Every quiz/exercise must define an answer key at authoring time, validated for basic correctness (e.g., a correct-option index must reference a real option) before publish. | Part 3 |

---

## 8. Non-Functional Requirements

### 8.1 Security

| ID | Requirement |
|---|---|
| NFR-SEC-1 | Authentication must be delegated to a specialist identity provider, never implemented in-house. |
| NFR-SEC-2 | Every authenticated route must enforce authentication at minimum; every resource-scoped operation must additionally enforce resource-level authorization, independent of route-level checks. |
| NFR-SEC-3 | No answer-key data for any assessment may ever be included in a response reachable by an unauthenticated or unauthorized browser request. |
| NFR-SEC-4 | Grading of any assessment submission must occur exclusively on the server, against a freshly retrieved, non-client-supplied answer key. |
| NFR-SEC-5 | All externally-delivered webhooks must be cryptographically verified before any associated processing occurs. |
| NFR-SEC-6 | All externally-delivered webhooks must be processed idempotently — redelivery must never duplicate an effect. |
| NFR-SEC-7 | All user-supplied input must be validated for shape and bounded for size before use in any write path. |
| NFR-SEC-8 | Error responses returned to a client must never include raw internal error detail (stack traces, database errors, implementation hints). |
| NFR-SEC-9 | Secrets must never be committed to version control; production and development secrets must be distinct. |
| NFR-SEC-10 | Sensitive write-heavy operations must be rate-limited in production. |

Full detail: Appendix F.

### 8.2 Reliability & Data Integrity

| ID | Requirement |
|---|---|
| NFR-REL-1 | Enrollment and certificate issuance must be structurally immune to duplication under concurrent requests — enforced at the database constraint level, not solely by application logic. |
| NFR-REL-2 | A multi-step write representing one logical action (e.g., recording an assessment attempt and updating lesson progress) must be atomic — partial completion must never be observable. |
| NFR-REL-3 | Background workflows must be durable: a transient failure at any step must be retryable without repeating already-completed work or duplicating side effects (e.g., a second email). |
| NFR-REL-4 | A certificate's recorded course title and recipient email must remain historically accurate even if the live course is later renamed or the account's email later changes. |

### 8.3 Performance & Scalability

| ID | Requirement |
|---|---|
| NFR-PERF-1 | Public content pages should tolerate brief data staleness (bounded, time-based cache) in exchange for reduced load on the content system. |
| NFR-PERF-2 | User-triggered writes must be reflected in that same user's subsequent views immediately (on-demand cache invalidation), never delayed by a caching layer. |
| NFR-PERF-3 | Aggregate reporting queries (enrollment counts, completion funnels, average scores) must be computed at the database layer, not by loading raw rows into application memory. |
| NFR-PERF-4 | Paginated views must never load an entire dataset into memory regardless of its size. |

### 8.4 Accessibility

| ID | Requirement |
|---|---|
| NFR-A11Y-1 | Interactive elements must be operable via keyboard, with visible focus indication. |
| NFR-A11Y-2 | Form controls must be programmatically associated with their labels, hints, and error messages. |
| NFR-A11Y-3 | Purely decorative content must not be exposed to assistive technology as meaningful content. |
| NFR-A11Y-4 | Tabular data must be marked up using genuine table semantics, not visually-styled non-semantic elements. |
| NFR-A11Y-5 | Automated accessibility scans of key public pages must report zero violations as a release gate. |

### 8.5 Maintainability

| ID | Requirement |
|---|---|
| NFR-MAINT-1 | Runtime input validation schemas and their corresponding TypeScript types must be derived from a single definition, never maintained as two independently-written artifacts. |
| NFR-MAINT-2 | Business-logic functions with security implications (e.g., grading) must be implemented as pure, independently unit-testable functions, decoupled from request/authentication plumbing. |
| NFR-MAINT-3 | A regression test must exist encoding any previously-identified and fixed security vulnerability, to prevent silent reintroduction. |

---

## 9. Data & Content Architecture Requirements

| ID | Requirement |
|---|---|
| DATA-1 | Content that is authored once and read identically by all users (courses, lessons, assessment definitions, instructor profiles) must be stored in the content system (Sanity). |
| DATA-2 | State that is unique to one user and changes frequently (enrollment, progress, attempts, certificates) must be stored in the transactional system (Neon). |
| DATA-3 | Cross-system references (a transactional record pointing at a content-system document) cannot be enforced by the transactional database's own constraints; every read/write path touching such a reference must independently verify the relationship. |
| DATA-4 | A lesson must never be retrievable by its identifier alone; every lookup must prove the lesson belongs to the specific course it is requested under. |
| DATA-5 | An assessment module must never be gradable by its identifier alone; every grading operation must prove the module belongs to the specific lesson and course claimed. |

Full schema detail: Appendix B. Full content model detail: Appendix C.

---

## 10. Success Metrics

| Metric | Target / Signal |
|---|---|
| Enrollment success rate | 100% of valid, published-course enrollment attempts succeed; 0% duplicate enrollment records under any load condition |
| Assessment integrity | 0 instances of a client-supplied correctness claim being persisted or trusted, verified via automated regression test and manual penetration-style testing |
| Certificate accuracy | 100% of certificates reflect the course title and recipient email as they existed at the moment of issuance, regardless of later changes |
| Reminder relevance | 0 reminders sent to students who have opted out or completed the relevant course |
| Full-journey reliability | The complete signup → enrollment → completion → certificate journey passes as a single automated end-to-end test on every release |
| Accessibility | 0 automated accessibility violations on the homepage and course catalog |

---

## 11. Known Gaps and Deferred Scope

These are explicitly acknowledged, deliberate scope boundaries, not oversights:

1. **No dedicated `/admin` UI.** `requireRole("ADMIN")` is implemented and ready for use; role promotion is currently performed via a manual script rather than a UI. A production rollout to real administrators should build this before opening the role to non-technical staff.
2. **Rate limiting requires external configuration.** The rate-limiting layer no-ops safely if Redis credentials are absent; production deployment must explicitly configure them or this control is inactive.
3. **No payment/paid-course flow.** The enrollment model assumes free enrollment; a paid tier would require a payment provider integration and enrollment-flow changes not covered here.
4. **Code exercises are keyword-graded, not executed.** Submissions are checked for expected substrings, not run as real code in a sandbox.

---

## 12. Assumptions & Constraints

- The platform assumes a single active content dataset (no multi-tenant content separation).
- The platform assumes English-only content and UI for the reference implementation; internationalization is not addressed.
- The platform assumes a moderate operational scale (hundreds to low thousands of concurrent learners); very large-scale batch workflows would require additional fan-out patterns beyond what is implemented (see Appendix E §E.8).

---

## 13. References

- Part 0 — architectural rationale and system overview
- Parts 1–16 — full implementation record
- Appendix A — project structure
- Appendix B — database schema
- Appendix C — content schema
- Appendix D — request/rendering lifecycle
- Appendix E — background workflow patterns
- Appendix F — security requirements detail
- Appendix G — troubleshooting reference
- Appendix H — glossary
- Appendix I — prerequisite primers
