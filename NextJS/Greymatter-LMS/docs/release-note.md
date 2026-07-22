# GreyMatter LMS — Release Notes

**Document type:** Release Notes
**Product:** GreyMatter LMS
**Version:** 1.0.0
**Release date:** Baseline release — reflects Parts 0–16 of the implementation record
**Location:** `docs/RELEASE_NOTES.md`
**Companion documents:** `docs/PRD.md`, `docs/SRD.md`, `docs/ARCHITECTURE.md`, `docs/API_REFERENCE.md`, `docs/TEST_PLAN.md`

---

## How to Read These Notes

This document follows [Keep a Changelog](https://keepachangelog.com/)-style conventions, adapted for a system whose entire v1.0.0 was built as a single, deliberate, documented implementation arc rather than a series of incremental production releases. Because this is the **first production release**, there is no prior version to diff against — instead, Section 2 presents the complete v1.0.0 feature set organized by subsystem, and Section 8 presents it as a phased changelog corresponding to the internal implementation milestones, for teams that want to understand the order in which capabilities were built and hardened.

All version numbers follow semantic versioning (`MAJOR.MINOR.PATCH`). Every entry in this document is traceable to a requirement ID in `docs/SRD.md` and/or a Part number in the implementation record.

---

## 1. Release Summary

**GreyMatter LMS v1.0.0** is the first production-ready release of a full-stack Learning Management System built on a hybrid content/transactional architecture. This release delivers the complete student, instructor, and content-authoring journey — from public course discovery through server-authoritative assessment grading to automated certificate issuance — backed by a durable background workflow engine and a security model that has been deliberately stress-tested against its own most serious threat class.

**This release is production-deployable.** It has passed its full automated test suite (unit, integration, end-to-end, accessibility), its complete security review (Appendix F), and its documented pre-deployment gate (`docs/TEST_PLAN.md` §7.2).

---

## 2. What's New in v1.0.0 — By Subsystem

### 2.1 Public Course Discovery

- Public, unauthenticated course catalog with difficulty and category badges.
- Course detail pages with learning objectives, chapter/lesson outlines, and instructor attribution.
- Free-preview lesson support — instructors may designate any lesson as publicly readable without enrollment.
- Honest, correctly-coded "not found" behavior for unpublished or nonexistent courses (real HTTP 404, not a disguised 200 response).

*(REQ-PUB-001 through REQ-PUB-004; Part 4)*

### 2.2 Identity and Account Management

- Sign-up and sign-in delegated to Clerk, with email/password and federated (Google) options.
- Automatic internal account provisioning via verified, idempotent webhook processing.
- Race-safe, on-demand account resolution ensures no legitimate freshly-signed-up user is ever incorrectly treated as unauthenticated, even before webhook delivery completes.
- Account deletion cascades correctly across every dependent record, while preserving an anonymized audit trail.

*(REQ-AUTH-001 through REQ-AUTH-007; Part 6)*

### 2.3 Enrollment

- One-click, free course enrollment with independent, server-side re-verification of course existence and publication status — the client's own belief about a course's availability is never trusted.
- Structural, database-enforced protection against duplicate enrollment, verified under real concurrent load.
- Resource-level access control ensures a signed-in user cannot view a course's authenticated content without a genuine, active enrollment — confirmed via direct URL manipulation testing.

*(REQ-ENR-001 through REQ-ENR-003; Part 8)*

### 2.4 Lesson Delivery

- Chapter and lesson navigation in authored order, with previous/next controls.
- Rich lesson content: formatted text, images, headings, and highlighted callout boxes.
- Safely allow-listed video embedding (YouTube, Vimeo) — no untrusted external content is ever embedded unchecked.
- Course-scoped lesson resolution — a lesson can never be retrieved by its identifier alone; every access proves the full course→chapter→lesson relationship.
- "Resume learning" — automatic tracking and restoration of the most recently visited lesson.

*(REQ-LSN-001 through REQ-LSN-004; Part 9)*

### 2.5 Interactive Assessments

- Five interactive module types: multiple-choice quiz, short-answer/code exercise, SQL syntax exercise, open-ended reflection, and completion checkpoint.
- Extensible plugin architecture — new module types can be added without modifying the lesson player itself.
- Graceful, non-fatal handling of unrecognized or malformed content, isolated per-module via dedicated error boundaries.
- **Server-exclusive grading** — no assessment's answer key is ever transmitted to any client, at any point, in any context. Correctness and score are computed entirely server-side against a freshly-retrieved, independently-scoped answer key.
- Configurable per-module attempt limits.
- Idempotent submission handling — a network retry of an identical submission is recognized and never double-processed.
- Honest optimistic UI — students see immediate feedback that a submission is "checking," never a guessed or pre-computed result.

*(REQ-ASM-001 through REQ-ASM-008; Parts 10–11)*

> **Security note — read in full:** this subsystem's server-exclusive grading model exists specifically because an earlier, intentionally-vulnerable version of this feature (built as part of this project's own development process to demonstrate the risk concretely) allowed a client to falsify its own graded outcome via simple network request manipulation. That vulnerability class is now permanently closed and is protected by a dedicated, mandatory automated regression suite (`tests/unit/grading-security.test.ts`) that fails the build if any answer-key field is ever reintroduced into a client-facing query. See `docs/ARCHITECTURE.md` §7.2 and `docs/THREAT_MODEL.md` T-T-01/T-I-01 for full detail.

### 2.6 Progress Tracking and Certification

- Automatic, asynchronous per-lesson and per-course completion percentage recalculation following every graded interaction — no manual refresh or trigger required.
- Automatic certificate issuance the moment a course reaches 100% completion, with no user-initiated request.
- Structural, database-enforced protection against duplicate certificate issuance, including under concurrent completion signals.
- Certificates snapshot the course title and recipient email at the moment of issuance, remaining historically accurate regardless of later course renames or account email changes.
- On-demand PDF certificate generation and download, owner-verified.

*(REQ-PRG-001, REQ-PRG-002, REQ-CRT-001 through REQ-CRT-004; Parts 12–13)*

### 2.7 Learner Engagement

- Scheduled, at-most-once-per-period inactivity reminder emails for active, disengaged learners.
- Weekly progress digest emails summarizing standing across all active enrollments.
- Per-user notification preference controls (independently toggleable for reminders vs. digests), with safe, enabled-by-default behavior when no preference has been explicitly set.
- In-app notification center with unread tracking.
- Reminders and digests are automatically and correctly suppressed for completed courses and opted-out users.

*(REQ-NOT-001 through REQ-NOT-005; Part 14)*

### 2.8 Instructor Tools

- Instructor-only dashboard, strictly scoped to courses linked to the instructor's own authored profile.
- Paginated student roster with status, completion percentage, and enrollment date.
- CSV roster export.
- Per-lesson completion funnel and per-module average score reporting, computed via database-level aggregation.
- At-risk student detection (low completion + inactivity threshold).
- Manual, instructor-triggered reminder dispatch, distinctly recorded from automated reminders.

*(REQ-INS-001 through REQ-INS-006; Part 15)*

### 2.9 Content Authoring

- Embedded Sanity Studio, fully independent of the application's own deployment lifecycle — content changes require no engineering deploy.
- Full course/chapter/lesson authoring, including mixed rich-text and interactive-block content in any author-chosen order.
- Author-time validation preventing publication of a quiz whose correct-answer index does not correspond to a real option.
- Independent control over public catalog visibility, distinct from the content system's own draft/publish state — enabling internal review before public launch.

*(REQ-CNT-001 through REQ-CNT-004; Part 3)*

### 2.10 Testing, Security, and Operations

- Full automated test suite: unit (Vitest), end-to-end (Playwright), and accessibility (axe-core).
- A complete, twelve-step, fully-automated end-to-end journey test covering signup through certificate issuance.
- A documented, checkable security audit covering identity, authorization, input validation, assessment integrity, webhooks, rate limiting, error handling, secrets, and audit logging.
- Production deployment across Vercel, Neon, Sanity, Clerk, and Inngest, with documented environment separation.
- Complete operational documentation set: architecture, data dictionary, API reference, test plan, threat model, disaster recovery plan, and incident response plan.

*(Part 16; full `docs/` set)*

---

## 3. Security Fixes Included in This Release

| ID | Description | Severity | Status |
|---|---|---|---|
| SEC-001 | Client-side assessment grading permitted network-level falsification of correctness/score | Critical | **Fixed** — server-exclusive grading implemented; permanent regression test added (`tests/unit/grading-security.test.ts`) |
| SEC-002 | Answer-key fields (`correctOptionIndex`, `expectedKeywords`) were present in the authenticated lesson-content query, reachable by any signed-in browser | Critical | **Fixed** — removed from all client-facing query projections; confined to a single server-only query |

**Both findings above originated from this project's own deliberate internal security exercise**, not an external report — see `docs/ARCHITECTURE.md` §7.2 for the full narrative of how and why this vulnerability class was intentionally built, studied, and then permanently closed prior to this release.

---

## 4. Known Issues and Limitations

These are documented, deliberate scope boundaries carried into v1.0.0, not defects:

| ID | Description | Impact | Tracking |
|---|---|---|---|
| GAP-001 | No dedicated `/admin` UI. Role management (`STUDENT`→`INSTRUCTOR`/`ADMIN`) is performed via a manual administrative script, not a self-service interface. | Administrators must have direct database/script access to promote users. | `docs/ARCHITECTURE.md` §11, item 1 |
| GAP-002 | Rate limiting (Upstash-backed) fails open if not explicitly configured in production. | If credentials are omitted, sensitive write paths are not rate-limited, with no runtime error surfaced. | `docs/ARCHITECTURE.md` §11, item 2; `docs/THREAT_MODEL.md` T-D-01 |
| GAP-003 | No paid/premium course enrollment flow. | All enrollment is free-only in this release. | `docs/PRD.md` §4.3 |
| GAP-004 | Code exercises are graded via keyword matching, not real code execution. | Submissions are not run in a sandbox; correctness is approximated via expected-substring matching. | `docs/PRD.md` §4.3 |
| GAP-005 | Scheduled batch workflows (reminders, digests) process candidates sequentially, not in parallel. | Appropriate at current documented scale; will require a fan-out architecture change before very large user bases. | `docs/ARCHITECTURE.md` §11, item 3; Appendix E §E.8 |
| GAP-006 | No multi-tenant content isolation. | Single organizational tenant assumed throughout. | `docs/ARCHITECTURE.md` §11, item 4 |
| GAP-007 | No independent third-party certificate verification mechanism (e.g., a public verification link or embedded signature). | A downloaded certificate PDF has no self-service authenticity check beyond the platform's own records. | `docs/THREAT_MODEL.md` T-R-03 |
| GAP-008 | No CI-level automated secret scanning; secret-exposure prevention currently relies on a mandatory manual pre-release check. | Reduced defense-in-depth against accidental credential commits. | `docs/THREAT_MODEL.md` T-I-04 |
| GAP-009 | No Postgres Row-Level Security; per-user data scoping relies on consistent query-authoring convention rather than a database-enforced backstop. | A future query authored without proper user-scoping could theoretically leak cross-user data; no incident of this kind has occurred. | `docs/THREAT_MODEL.md` T-I-03 |
| GAP-010 | No formal third-party penetration test has been performed as of this release. | Security posture is internally reviewed and tested but not independently externally validated. | `docs/TEST_PLAN.md` §9 |

None of the above block production deployment; all are explicitly accepted, documented residual scope per `docs/ARCHITECTURE.md` §11 and `docs/THREAT_MODEL.md` §5.

---

## 5. Upgrade / Deployment Notes

This is the first production release — there is no prior version to migrate from. Deploying operators should nonetheless note:

- **Database migrations must be applied manually**, never as part of an automatic deploy pipeline step (`docs/ARCHITECTURE.md` §10). Follow `docs/DEVSECOPS_ONBOARDING.md` §3.3 exactly.
- **Environment-specific secrets are mandatory** for every one of the six external service integrations before first production traffic is served — see `docs/API_REFERENCE.md` §1.3 and the full variable inventory in Appendix A §A.5.
- **Rate limiting (GAP-002) requires explicit configuration** — confirm `UPSTASH_REDIS_REST_URL`/`UPSTASH_REDIS_REST_TOKEN` are set in the production environment scope specifically before considering the deployment complete; their absence is silent, not an error.
- **The complete pre-deployment gate** (`docs/TEST_PLAN.md` §7.2, Appendix F §F.11) must be satisfied before this release is exposed to real users — this is not optional guidance, it is the documented release criteria for this exact version.

---

## 6. Compatibility

| Requirement | Minimum |
|---|---|
| Node.js (build/runtime) | 20 LTS or newer |
| Browser support (client) | Current evergreen Chromium, Firefox, Safari |
| Minimum supported viewport | 320px width |
| PostgreSQL (via Neon) | Serverless, HTTP-driver compatible |

---

## 7. Contributors and Acknowledgments

This release represents the complete implementation arc documented across Parts 0–16 of the GreyMatter LMS build record, its full appendix reference set (A–I), and its complete operational documentation suite (PRD, SRD, Architecture, Data Dictionary, ERD Narration, API Reference, Test Plan, Onboarding Guides, Threat Model, Disaster Recovery Plan, and Incident Response Plan). Every architectural decision in this release — including its one deliberately-built-and-fixed vulnerability — is documented in full in the accompanying reference material for future maintainers.

---

## 8. Phased Changelog (Internal Implementation Milestones)

For teams wanting to understand the order capabilities were built and hardened, this changelog maps v1.0.0's feature set onto its originating implementation phases — useful context for understanding *why* certain architectural decisions were sequenced the way they were (e.g., why the transactional database schema predates authentication, and why the security fix in 1.0.0-rc.11 could only happen after the plugin architecture in 1.0.0-rc.10 existed to demonstrate the flaw concretely).

```text
1.0.0-rc.1   Project foundation — Next.js 16, TypeScript, Tailwind,
             health check, first Server/Client Components (Part 1)

1.0.0-rc.2   Design system — tokens, UI primitives, component
             showcase (Part 2)

1.0.0-rc.3   Content model — embedded Sanity Studio, course/chapter/
             lesson/quiz schemas (Part 3)

1.0.0-rc.4   Public course catalog and detail pages, GROQ queries,
             Portable Text rendering, course-scoped lesson query
             pattern established (Part 4)

1.0.0-rc.5   Transactional schema — Neon/Drizzle, all ten tables,
             constraints, seed data (Part 5)

1.0.0-rc.6   Authentication — Clerk integration, webhook-based
             provisioning, idempotent processing, auth helpers
             (Part 6)

1.0.0-rc.7   Student dashboard shell, responsive navigation,
             enrollment-aware course list, resource-level
             authorization pattern established (Part 7)

1.0.0-rc.8   Secure enrollment — Zod validation, server-side
             re-verification, atomic transaction, race-condition
             proof (Part 8)

1.0.0-rc.9   Lesson player — course-scoped delivery, safe video
             embeds, resume-learning (Part 9)

1.0.0-rc.10  Interactive module SDK — plugin architecture, five
             module types. NOTE: this milestone intentionally
             included a client-side grading vulnerability, built
             and demonstrated as a deliberate exercise. See 1.0.0-rc.11.
             (Part 10)

1.0.0-rc.11  SECURITY FIX — server-exclusive grading, answer-key
             removal from all client-facing queries, eight-layer
             submission defense, permanent regression tests added.
             Corresponds to SEC-001/SEC-002 in Section 3. (Part 11)

1.0.0-rc.12  Inngest integration — event catalog, first durable
             background workflows (Part 12)

1.0.0-rc.13  Automated course completion — certificates, PDF
             generation, email notification (Part 13)

1.0.0-rc.14  Scheduled engagement — reminders, digests, notification
             preferences and center (Part 14)

1.0.0-rc.15  Instructor dashboard and analytics (Part 15)

1.0.0-rc.16  Testing, security review, production deployment
             (Part 16)

1.0.0        GENERAL AVAILABILITY — full pre-deployment gate
             satisfied; complete documentation suite finalized.
```

---

## 9. Feedback and Issue Reporting

Defects should be classified and routed per `docs/TEST_PLAN.md` §8 (Defect Management) and, where security-relevant, per `docs/INCIDENT_RESPONSE.md` Section 2 (Incident Classification). Any suspected security issue involving assessment grading, authorization, or data exposure should be escalated immediately per `docs/INCIDENT_RESPONSE.md` rather than filed as a routine defect.
