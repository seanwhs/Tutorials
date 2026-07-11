# Appendix A — Reference Implementation

## Complete Next.js 16 QR Attendance Platform

Throughout this series, we've progressively designed and implemented a production-ready QR attendance platform. Rather than presenting isolated code snippets, this appendix brings the entire solution together as a cohesive reference implementation.

The application follows the architecture established in Part 1 and demonstrates how modern Next.js 16 applications can combine Server Components, Server Actions, durable workflows, and event-driven design to build resilient systems.

---

# Technology Stack

| Layer             | Technology    | Purpose                                       |
| ----------------- | ------------- | --------------------------------------------- |
| Framework         | Next.js 16    | App Router, Server Components, Server Actions |
| Language          | TypeScript    | End-to-end type safety                        |
| Authentication    | Clerk         | Identity and session management               |
| CMS & Persistence | Sanity        | Events and attendance records                 |
| Workflow Engine   | Inngest       | Durable orchestration                         |
| Email             | Resend        | Transactional notifications                   |
| Rate Limiting     | Upstash Redis | Request throttling                            |
| Styling           | Tailwind CSS  | User interface                                |
| Deployment        | Vercel        | Serverless hosting                            |

---

# Repository Layout

```text
attendance-platform/

├── src/
│
├── app/
│   ├── (marketing)/
│   ├── dashboard/
│   ├── events/
│   │   └── [slug]/
│   │       └── checkin/
│   │
│   ├── admin/
│   ├── api/
│   │   └── inngest/
│   └── layout.tsx
│
├── actions/
│   └── attendance/
│
├── components/
│
├── services/
│   ├── attendance/
│   ├── events/
│   ├── notification/
│   └── dashboard/
│
├── repositories/
│   └── sanity/
│
├── workflows/
│   └── attendance/
│
├── lib/
│
├── sanity/
│
├── types/
│
├── middleware.ts
│
└── package.json
```

The repository is organized by business capability rather than technical layer. This keeps related functionality together and reduces coupling as the application grows.

---

# Source Code Roadmap

Each part of the series corresponds directly to a section of the repository.

| Series Part | Repository                                 |
| ----------- | ------------------------------------------ |
| Part 1      | Architecture documentation                 |
| Part 2      | Project structure                          |
| Part 3      | `sanity/` schemas                          |
| Part 4      | `app/`, `actions/`, `components/`          |
| Part 5      | `workflows/`, `services/`, `repositories/` |
| Part 6      | Infrastructure, monitoring, deployment     |

Readers can move between the article and repository without losing context.

---

# Request Lifecycle

The complete request flow is shown below.

```text
Attendee

↓

QR Code

↓

Next.js App Router

↓

Server Component

↓

Clerk Authentication

↓

Server Action

↓

attendance/checkin.requested

↓

Inngest Workflow

↓

Validation

↓

Idempotency

↓

Attendance Repository

↓

Sanity

↓

Email

↓

Analytics

↓

Dashboard
```

Every layer has a single responsibility.

---

# Project Modules

The implementation is divided into several logical modules.

## User Experience

Responsible for:

* QR scanning
* Event display
* Check-in interface
* Dashboard

---

## Application Layer

Responsible for:

* Server Actions
* Authentication
* Authorization
* Validation

---

## Domain Services

Responsible for:

* Attendance rules
* Event rules
* Business policies

---

## Repository Layer

Responsible for:

* Sanity queries
* Persistence
* Transactions

---

## Workflow Layer

Responsible for:

* Durable execution
* Retries
* Notifications
* Analytics
* Fan-out

---

# Repository Responsibilities

```text
Server Action

↓

Attendance Service

↓

Attendance Repository

↓

Sanity
```

Notice that Server Actions never communicate directly with Sanity.

Business rules remain isolated from persistence.

---

# Workflow Responsibilities

The attendance workflow performs the following sequence.

```text
Receive Event

↓

Validate

↓

Check Event

↓

Check Idempotency

↓

Persist Attendance

↓

Email

↓

Analytics

↓

Dashboard

↓

Complete
```

Each step is independently retryable.

---

# External Services

The implementation integrates with the following services.

```text
                 Next.js

       ┌──────────┼──────────┐

       ▼          ▼          ▼

    Clerk      Sanity     Inngest

       │                     │

       ▼                     ▼

 Authentication         Durable Workflow

                             │

               ┌─────────────┼────────────┐

               ▼             ▼            ▼

           Resend      Upstash Redis   Dashboard
```

Every dependency is isolated behind a service abstraction.

---

# Environment Variables

The project requires the following configuration.

```text
CLERK_SECRET_KEY

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY

SANITY_PROJECT_ID

SANITY_DATASET

SANITY_API_TOKEN

INNGEST_EVENT_KEY

INNGEST_SIGNING_KEY

RESEND_API_KEY

UPSTASH_REDIS_REST_URL

UPSTASH_REDIS_REST_TOKEN
```

Configuration should be centralized rather than accessed throughout the codebase.

---

# Operational Features

The implementation includes support for:

* Correlation IDs
* Structured logging
* Rate limiting
* Durable retries
* Idempotency
* Event replay
* Health checks
* Offline synchronization
* Live dashboards
* Email notifications
* Audit metadata

These features distinguish the application from a simple CRUD implementation.

---

# Suggested Git Branches

To make the repository easier to follow, create a branch or tag for each article.

| Branch   | Description          |
| -------- | -------------------- |
| `main`   | Complete application |
| `part-1` | Architecture only    |
| `part-2` | Foundation           |
| `part-3` | Domain model         |
| `part-4` | Application layer    |
| `part-5` | Workflow engine      |
| `part-6` | Production-ready     |

Readers can compare each milestone independently without being overwhelmed by the complete codebase.

---

# Suggested Git Tags

A semantic tagging strategy provides additional reference points.

```text
v0.1-foundation

v0.2-domain

v0.3-checkin

v0.4-workflows

v0.5-production

v1.0-release
```

These milestones mirror the progression of the series.

---

# Extending the Platform

The architecture is intentionally modular.

Future enhancements could include:

* Badge printing
* NFC check-in
* Multi-session conferences
* Sponsor booth attendance
* Certificate generation
* AI-powered attendance analytics
* Mobile applications
* Offline kiosk mode
* Multi-tenant event management

None of these require fundamental architectural changes.

---

# Final Repository Diagram

```text
                        Browser

                           │

                           ▼

                 Next.js App Router

                           │

       ┌───────────────────┼───────────────────┐

       ▼                   ▼                   ▼

Server Components    Server Actions     Client Components

                           │

                           ▼

                  Attendance Service

                           │

                           ▼

                 Attendance Repository

                           │

                           ▼

                        Sanity

                           │

                           ▼

                Inngest Orchestration

       ┌────────────┼────────────┬────────────┐

       ▼            ▼            ▼            ▼

    Email      Analytics     Dashboard    Audit
```

This reference implementation demonstrates more than a QR attendance application.

It demonstrates how to design modern workflow-driven systems using Next.js 16, durable execution, and event-driven architecture.

The same blueprint can be adapted to e-commerce, booking systems, customer onboarding, approval workflows, AI orchestration, and countless other business domains where reliability matters.
