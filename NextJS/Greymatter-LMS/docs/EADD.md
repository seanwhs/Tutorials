# GreyMatter LMS — Engineering Architecture Design Document (EADD)

**Document type:** Architecture Design Document
**Product:** GreyMatter LMS
**Status:** Approved — reflects implemented system (Parts 0–16)
**Location:** `docs/ARCHITECTURE.md`
**Companion documents:** `docs/PRD.md`, Appendices A–I

---

## 1. Purpose and Audience

This document describes **how** GreyMatter LMS is built: the system's major components, how they communicate, the data model, the trust and authorization model, the background-processing model, and the key architectural decisions with their trade-offs. It is written for engineers joining the project, engineers extending it, and engineers responsible for operating it in production.

Where the PRD defines *what* the system must do, this document defines *how* it does it and *why* it's structured this way rather than another way.

---

## 2. Architectural Summary

GreyMatter LMS is a **hybrid, event-driven, monolith-at-the-edge** system:

- **One Next.js application** serves the public marketing site, the authenticated student/instructor experiences, an embedded content-authoring tool, and every API surface — deployed as a single unit, not a collection of microservices.
- **Two independent, purpose-specialized data stores** back it: a headless CMS for authored content, and a relational database for transactional, per-user state.
- **One durable background-workflow engine** absorbs every operation that does not need to complete within the lifetime of an HTTP request.
- **One identity provider** is delegated full ownership of authentication, bridged into the application's own user model via webhook and on-demand synchronization.

```text
                              ┌───────────────────────────┐
                              │        Browser             │
                              │  Student / Instructor /     │
                              │  Admin / Content Editor      │
                              └─────────────┬─────────────┘
                                            │ HTTPS
                                            ▼
                    ┌───────────────────────────────────────────┐
                    │              Next.js Application              │
                    │  ┌─────────────┐   ┌────────────────────┐    │
                    │  │  Pages /     │   │  Route Handlers      │    │
                    │  │  Server      │   │  (webhooks, Inngest   │    │
                    │  │  Components / │   │   endpoint, downloads)│    │
                    │  │  Server      │   └──────────┬─────────┘    │
                    │  │  Actions      │              │              │
                    │  └──────┬───────┘              │              │
                    └─────────┼──────────────────────┼──────────────┘
                              │                       │
        ┌─────────────────────┼───────────────────────┼──────────────────┐
        ▼                     ▼                       ▼                  ▼
┌───────────────┐   ┌───────────────────┐    ┌────────────────┐  ┌───────────────┐
│  Sanity          │   │  Neon PostgreSQL   │    │     Clerk        │  │  Upstash Redis  │
│  (content system) │   │  (transactional     │    │  (identity)      │  │  (rate limiting) │
│                  │   │   system of record) │    │                  │  │                  │
└───────────────┘   └─────────┬─────────┘    └────────────────┘  └───────────────┘
                              │ emits events
                              ▼
                    ┌───────────────────┐
                    │      Inngest        │
                    │ (durable workflow    │
                    │      engine)          │
                    │                        │
                    │  onboarding · progress  │
                    │  recalculation ·         │
                    │  certificates · reminders│
                    └───────────┬───────────┘
                                ▼
                    ┌───────────────────┐
                    │   Resend (email)    │
                    └───────────────────┘
```

---

## 3. Architectural Drivers

The following forces shaped every major decision described in this document.

| Driver | Consequence |
|---|---|
| Content changes rarely, is read by everyone identically | Push content into a system optimized for authoring workflows and cheap, cacheable public reads (Sanity), not the same database as per-user state. |
| Per-user state changes constantly and must be strictly consistent | Push transactional state into a relational database with real constraints (Neon), not a loosely-structured content store. |
| Some work must never block a user-facing request | Push non-critical-path work into a durable, retryable background engine (Inngest), never inline in the request/response cycle. |
| Identity and session management is a high-stakes, easy-to-get-wrong domain | Delegate entirely to a specialist provider (Clerk); never hand-roll authentication. |
| The browser is an untrusted actor | Every server-side operation independently re-verifies anything the browser claims — existence, ownership, correctness — rather than trusting client-supplied state. |
| The system must remain a single deployable unit for a team of this scale | Favor one Next.js application with clear internal module boundaries over a distributed microservice topology. |

---

## 4. System Components

### 4.1 Next.js Application (the core)

A single Next.js 16 application using the App Router, deployed to Vercel. It is the *only* component end users interact with directly. Internally it separates cleanly along **route groups**, each with its own authorization posture:

| Route group | Authorization posture | Responsibilities |
|---|---|---|
| Public (`/`, `/courses/**`) | None required | Marketing, course discovery, public preview content |
| Auth (`/sign-in`, `/sign-up`) | None required (pre-auth) | Delegated entirely to Clerk's hosted components |
| Studio (`/studio/**`) | Sanity's own auth | Embedded content authoring |
| Student dashboard (`/dashboard/**`) | Session required (route-level) + resource-level checks per page | Enrollment, learning, progress, certificates, settings |
| Instructor (`/instructor/**`) | Session + `INSTRUCTOR` role (route-level) + ownership checks per resource | Roster, analytics, reminders |
| API (`/api/**`) | Varies per endpoint — see Section 6 | Webhooks, background-job integration, file downloads |

The application uses **Server Components as the default execution model** — most data fetching happens directly inside components that run exclusively on the server, with Client Components reserved specifically for interactivity (forms, optimistic UI, dropdowns). This keeps the client-side JavaScript payload proportional to actual interactivity needs rather than the size of the application overall.

### 4.2 Sanity (Content System)

A hosted, headless CMS holding every piece of authored content: courses, chapters, lessons, Portable Text content blocks (including custom interactive-module definitions), instructor profiles, and categories. Sanity Studio is embedded directly inside the Next.js application at `/studio`, sharing the same deployment and repository as the rest of the system, while remaining logically and operationally independent — content edits do not require an application deploy, and application deploys do not require Studio changes.

Content is queried via **GROQ**, Sanity's native query language, through a single shared client. Public-facing queries and authenticated-facing queries are deliberately **separate, differently-scoped query definitions** — never the same query reused across trust boundaries — so that a query's own projection acts as an enforcement point for what data a given context is allowed to receive.

### 4.3 Neon PostgreSQL (Transactional System)

A serverless, managed PostgreSQL database holding every piece of state that is unique to a specific user and changes frequently: identity mapping, enrollments, lesson/course progress, assessment attempts, certificates, notifications, and operational/audit records. Access is exclusively through **Drizzle ORM**, using its typed relational query API and explicit transaction boundaries for any multi-step write.

The schema deliberately does **not** attempt to model Sanity's content via foreign keys. Fields referencing content (`course_id`, `lesson_id`, `module_id`) are plain text columns — the relational database cannot verify a cross-system reference, so that verification is pushed to the application layer, consistently, at every access point (see Section 7.3).

### 4.4 Clerk (Identity Provider)

A hosted authentication service, fully responsible for credential storage, session issuance, and account lifecycle UI (sign-up, sign-in, password reset, account management). The application never stores a password or implements a session mechanism of its own.

Clerk's identity is bridged into the application's own data model through:
1. A verified, idempotent webhook (`user.created`/`user.updated`/`user.deleted`) as the primary synchronization path.
2. An on-demand, race-safe fallback (`ensureInternalUser`) that resolves a user record directly from Clerk's API if the webhook has not yet completed, guaranteeing no legitimate authenticated request is ever incorrectly treated as unauthenticated.

### 4.5 Inngest (Durable Workflow Engine)

A background-job platform responsible for every operation that must not execute inline within a user-facing request: user onboarding side effects, enrollment confirmation, course-progress recalculation, certificate issuance, scheduled inactivity reminders, and weekly progress digests. Functions are composed of independently-retryable, cached **steps**, giving the system automatic, granular recovery from transient failures without duplicating already-completed work or side effects (e.g., a second email send).

Communication into Inngest is exclusively **event-based**: application code emits a typed event (`course/enrolled`, `lesson/completed`, `course/completed`) after a synchronous write has already committed; it never calls a workflow function directly, and workflow functions never call application code synchronously in return.

### 4.6 Resend (Transactional Email)

A hosted transactional email API, invoked exclusively from within Inngest functions — never from a synchronous request path. Every email-sending function is built with a documented, deliberate development-mode fallback (structured console logging) so the system remains fully exercisable without requiring a configured email provider during development.

### 4.7 Upstash Redis (Rate Limiting)

A hosted Redis instance backing a sliding-window rate limiter applied to the system's most sensitive write paths (assessment submission). This component is explicitly optional at the infrastructure level: its absence causes the rate limiter to no-op rather than fail, a deliberate trade-off documented as a known operational gap (see Section 11) rather than a silent, unnoticed vulnerability.

---

## 5. Data Architecture

### 5.1 The Two-System Principle

Every piece of data in the system is classified along exactly one axis: **is it authored content, shared identically across users, or is it per-user transactional state?**

```text
                    ┌─────────────────────────────┐
                    │   Is this the SAME for every  │
                    │   user, and edited RARELY?      │
                    └───────────┬─────────────────┘
                       Yes ▼                ▼ No
              ┌──────────────────┐   ┌──────────────────────┐
              │      SANITY        │   │  Is this UNIQUE per     │
              │  (content system)   │   │  user, and changes       │
              │                     │   │  FREQUENTLY?              │
              └──────────────────┘   └───────────┬──────────┘
                                          Yes ▼
                                    ┌──────────────────┐
                                    │       NEON          │
                                    │ (transactional        │
                                    │      system)            │
                                    └──────────────────┘
```

This single decision rule, applied consistently, is what keeps the system's data model coherent as it has grown across sixteen implementation phases.

### 5.2 Neon Schema Overview

Ten tables, organized into four functional clusters:

| Cluster | Tables | Purpose |
|---|---|---|
| Identity | `users` | Internal identity, bridged to Clerk |
| Learning state | `enrollments`, `lesson_progress`, `course_progress`, `module_attempts` | Access control and fine/coarse-grained progress |
| Achievement | `certificates` | Immutable, snapshotted proof of completion |
| Operations | `webhook_events`, `workflow_events`, `audit_logs`, `notifications`, `notification_preferences` | Idempotency, observability, and learner communication |

Every table enforcing a business-critical uniqueness guarantee (no duplicate enrollment, no duplicate certificate, no duplicate progress row, bounded assessment attempts) does so via a **database-level unique constraint**, not application-level pre-checks alone — this is a deliberate, load-bearing decision covered in Section 7.4.

Full field-level schema: Appendix B.

### 5.3 Sanity Content Model Overview

```text
course → category (ref), instructor (ref), chapters[] (ref)
chapter → lessons[] (ref)
lesson → content[] (Portable Text: text blocks, images,
                     calloutBlock, quizBlock, codeExerciseBlock,
                     reflectionBlock, checkpointBlock)
```

Interactive assessment definitions (`quizBlock`, `codeExerciseBlock`) are modeled as **object types embedded within lesson content**, not standalone documents — they have no independent existence outside the lesson that contains them, and no reference can be made *to* them from elsewhere in the content graph. This is deliberate: an assessment's meaning is inseparable from its lesson context.

Full schema detail: Appendix C.

### 5.4 Data Consistency Model

| Guarantee | Mechanism |
|---|---|
| No duplicate enrollment | Database unique constraint (`user_id, course_id`) |
| No duplicate certificate | Database unique constraint + application-level idempotency check + concurrency-safe retry-on-conflict |
| No duplicate webhook processing | Database unique constraint on `(source, external_id)`, checked before any side-effecting work begins |
| No duplicate assessment attempt (from a retried request) | Optional client-generated idempotency key, uniquely constrained per `(user_id, module_id, idempotency_key)` |
| Atomic multi-step writes | Explicit Drizzle transactions — attempt + progress + audit log committed as one unit, or none at all |
| Certificate historical accuracy | Data snapshotting at issuance time (course title, recipient email captured as plain fields, never live-joined) |

---

## 6. API and Interface Architecture

### 6.1 Two Distinct Interaction Patterns

The system deliberately uses **two different mechanisms** for server-side logic, chosen based on *who* the caller is:

| Pattern | Used when | Examples |
|---|---|---|
| **Server Actions** | The caller is our own UI, invoked via a form or user interaction | Enrollment, assessment submission, preference updates, manual reminders |
| **Route Handlers** | The caller is external to our own React tree, or a real downloadable file is being returned | Clerk webhook receiver, Inngest's function-discovery endpoint, certificate PDF download, CSV export, health check |

This is not an arbitrary stylistic choice — Server Actions provide progressive enhancement (a real `<form>` that works even before JavaScript loads) and eliminate the need to hand-design a REST surface for purely internal UI-triggered operations. Route Handlers exist specifically where a genuine, externally-addressable URL is required.

### 6.2 API Surface Inventory

| Endpoint | Method | Caller | Auth model |
|---|---|---|---|
| `/api/health` | GET | Uptime monitoring | None |
| `/api/webhooks/clerk` | POST | Clerk's infrastructure | Cryptographic signature verification |
| `/api/inngest` | GET/POST/PUT | Inngest's infrastructure | Signing key (production) |
| `/api/certificates/[id]/download` | GET | Authenticated browser | Session + resource ownership check |
| `/api/instructor/courses/[id]/students/export` | GET | Authenticated instructor browser | Session + role + course ownership check |

Every Server Action (not URL-addressable, invoked internally) is documented in full in Appendix A, Section A.4.

### 6.3 Middleware Scope

A single middleware layer attaches session-detection capability to every matched request. It performs **no authorization decisions of its own** — it exists purely to make identity information available to downstream code. All actual access-control decisions are made explicitly, at the point of use, inside layouts and Server Actions. This separation keeps every authorization decision visible and auditable at its point of application, rather than implicit in a centrally-configured middleware matcher.

---

## 7. Security Architecture

### 7.1 Authentication vs. Authorization

Authentication (identity) is fully delegated to Clerk. Authorization (permission) is implemented entirely within the application, at two independent, always-both-required layers:

```text
Layer 1 — Route-level:   "Is anyone/the correct kind of user signed in?"
Layer 2 — Resource-level: "Does THIS user have a genuine relationship
                            to THIS specific resource?"
```

Neither layer is sufficient alone. Route-level protection on `/dashboard` does not imply a signed-in student may view *any* course's content — resource-level enrollment verification is independently required on every course- and lesson-scoped operation. The identical two-layer pattern is repeated for instructor course ownership and certificate ownership.

### 7.2 The Assessment Integrity Model

This is the single most architecturally significant security decision in the system, and it merits its own dedicated treatment.

**The threat:** a browser-based client can be freely inspected and manipulated. Any value the client uses to determine its own "correctness" can also be forged by that same client, regardless of UI design.

**The architectural response:**

```text
1. The answer key for any assessment (correct option index, expected
   keywords) is NEVER included in any query result reachable by browser
   code — public or authenticated. It exists in exactly one query,
   called from exactly one place: a server-side grading function.

2. The client sends ONLY the learner's raw answer — never a
   correctness claim of any kind.

3. Grading is performed by a pure, independently-testable server
   function, which accepts only the raw submission and a freshly
   retrieved, never-client-supplied answer key.

4. The module submission path additionally re-verifies enrollment and
   proves — via a query scoped through course → lesson → module — that
   the submitted module genuinely belongs to the claimed lesson and
   course, closing the same class of cross-resource confusion addressed
   at the lesson-delivery layer.
```

This model is deliberately regression-tested at the schema level (a Zod schema that once accepted an answer-key field can never silently regain that field without an automated test failing) — treating this specific vulnerability class as permanently closed rather than merely fixed once.

### 7.3 Cross-System Reference Verification

Because Neon cannot enforce referential integrity into Sanity, every code path that reads or writes a Sanity-identifier field independently re-verifies the relationship it implies, following one consistent pattern:

```text
Course-scoped lesson lookup:
  course (by slug/id) → chapters[] → lessons[] → [match on lesson slug/id]

Course-scoped assessment lookup:
  course (by id) → chapters[] → lessons[] → [match on lesson id]
      → content[moduleId == target] → [match on module id]
```

A lesson or assessment reachable only by its bare identifier, without proof of this full chain, is never treated as valid — this closes the specific vulnerability of a valid-but-unrelated identifier being substituted into a URL or request payload.

### 7.4 Concurrency and Race-Condition Defense

Every business rule requiring "this can happen at most once" (enrollment, certificate issuance, webhook processing) is enforced by a **database constraint**, not solely by an application-level existence check — because a check-then-act sequence has an inherent timing gap that concurrent requests can exploit, regardless of how carefully the application code appears to guard against it. Where a constraint violation is expected under legitimate concurrent load (e.g., two simultaneous course-completion signals both attempting certificate issuance), the application catches the resulting database error and treats it as a successful outcome achieved by a concurrent operation, rather than surfacing it as a failure.

### 7.5 Webhook Trust Model

Every inbound webhook is verified cryptographically, over its **exact original request bytes**, before any processing occurs. Every webhook event is additionally recorded against a uniqueness constraint on the provider's own delivery identifier *before* any side-effecting work begins — guaranteeing that a redelivered event (an explicitly documented possibility for any real webhook provider) is recognized and skipped rather than reprocessed.

Full security detail: Appendix F.

---

## 8. Background Processing Architecture

### 8.1 Synchronous vs. Asynchronous Boundary

The system draws a firm line between what must complete within a request/response cycle and what may complete afterward:

| Synchronous (must complete inline) | Asynchronous (may complete later) |
|---|---|
| Recording an enrollment | Sending an enrollment confirmation email |
| Recording a graded assessment attempt | Recalculating whole-course completion percentage |
| Persisting lesson-visit bookkeeping | Checking certificate eligibility and issuing one |
| — | Detecting inactivity and sending reminders |
| — | Sending a weekly progress digest |

The rule applied consistently: if the user is actively waiting to see the result on-screen, it must be synchronous. If the result is a downstream consequence the user does not need confirmed within the same interaction, it belongs in the background engine.

### 8.2 Event Catalog

A single, centrally-typed catalog of every event the system emits or consumes — `user/created`, `course/enrolled`, `lesson/completed`, `course/completed` — ensures event names and payload shapes cannot silently drift between an emitter and its listener; a mismatch is a compile-time error, not a silent runtime no-op.

### 8.3 Workflow Reliability Patterns

| Pattern | Applied to |
|---|---|
| Independently-retryable steps | Every background function |
| Idempotency (check-before-write + race-safe retry-on-conflict) | Certificate issuance |
| Concurrency capping | Scheduled reminder/digest functions, to prevent an overlapping manual test run from duplicating real-world effects |
| Sequential per-item fan-out | Batch reminder/digest processing across many candidate students |
| Internal observability, decoupled from the workflow engine's own dashboard | A dedicated operations table recording every significant workflow's start/success/failure state, queryable directly |
| Failure recording + re-throw | Failures are recorded for internal visibility, then re-raised so the underlying engine's own retry mechanism still has the opportunity to recover from transient conditions |

Full pattern catalog with runnable examples: Appendix E.

---

## 9. Caching and Data Freshness Architecture

Two distinct caching strategies are applied, chosen based on who is affected by staleness:

| Strategy | Applied to | Staleness tolerance |
|---|---|---|
| **Time-based revalidation** | Public content reads (catalog, course detail) | Bounded window (tens of seconds) is acceptable — no single user is actively waiting on a just-published edit |
| **On-demand invalidation** | Any user-triggered write affecting that same user's next view | None — must be reflected immediately upon the triggering action's success |

Pages requiring per-request authorization decisions (any dashboard or instructor page) are rendered dynamically per request by necessity, rather than cached at all, since their content depends on session state that cannot be safely shared across users.

Full lifecycle detail: Appendix D.

---

## 10. Deployment Architecture

| Component | Hosting | Environment separation |
|---|---|---|
| Next.js application | Vercel | Preview deployments per branch; distinct production environment variables |
| Transactional database | Neon | Separate `main` (development) and `production` branches |
| Content system | Sanity | Single project; CORS origins scoped per deployed domain |
| Identity provider | Clerk | Separate development and production applications, each with distinct keys and webhook secrets |
| Workflow engine | Inngest | Separate development (local CLI) and production environments, each with distinct signing/event keys |
| Email | Resend | Single account; safe to share across environments given no destructive side effects from sending |
| Rate limiting | Upstash | Production-only; absent in local development by design |

Database schema changes are applied via versioned, generated migrations, reviewed before execution and applied identically across environments — no environment's schema is ever hand-edited outside this pipeline.

---

## 11. Known Architectural Gaps

Documented deliberately, not accidentally omitted:

1. **No dedicated administrative interface.** The `ADMIN` role and its authorization primitive exist; no page currently exercises it. Role changes are performed via a manual operational script.
2. **Rate limiting is infrastructure-dependent and fails open.** In the absence of configured Redis credentials, the rate limiter no-ops rather than blocking traffic — an explicit, documented trade-off favoring local-development accessibility over defense-in-depth by default; production deployments must actively configure this component.
3. **Sequential-only background fan-out.** Batch workflows (reminders, digests) process candidates one at a time, appropriate at the system's current expected scale; a genuinely high-volume deployment would require migrating to a two-function, event-per-item fan-out pattern (documented as a forward-compatible extension, see Appendix E §E.8).
4. **No content-level multi-tenancy.** The content and transactional systems both assume a single organizational tenant; supporting multiple isolated customer organizations would require schema and query-scoping changes not present in this architecture.

---

## 12. Architectural Decision Log (Summary)

| Decision | Alternative considered | Why this architecture won |
|---|---|---|
| Separate content (Sanity) and transactional (Neon) stores | Single relational database modeling both | Content and transactional data have opposing read/write and consistency needs; conflating them couples editorial workflow to application deploys and vice versa |
| Server Actions for internal mutations | A hand-built REST API for every mutation | Eliminates need to design/maintain a parallel URL surface for operations with no external caller; gains progressive enhancement for free |
| Durable background engine (Inngest) for delayed work | Cron scripts / manual queue implementation | Automatic retry, step-level caching, and typed event contracts, without operating a message broker directly |
| Database-level uniqueness constraints for business invariants | Application-level existence checks only | Closes race conditions that timing-dependent application checks cannot, regardless of code quality |
| Server-exclusive assessment grading | Client-side grading with server-side confirmation | The only architecture that removes the *possibility* of client-side falsification, rather than merely making it harder |
| Delegated identity (Clerk) | Self-hosted authentication | Removes an entire class of high-consequence, easy-to-get-wrong security surface from the team's direct responsibility |

---

## 13. References

- `docs/PRD.md` — product requirements
- Part 0 — architectural rationale, plain-language introduction
- Parts 1–16 — full implementation record, one architectural layer per phase
- Appendix A — project structure and route map
- Appendix B — database schema
- Appendix C — content schema
- Appendix D — request/rendering lifecycle
- Appendix E — background workflow patterns
- Appendix F — security requirements and audit checklist
- Appendix G — troubleshooting reference
