# Reference Implementation Repository

> *"The purpose of a reference implementation is not to provide copy-and-paste code. It is to demonstrate how architectural decisions become executable software."*

---

# Purpose

This section documents the complete implementation of the production QR attendance platform.

The repository accompanying this book is designed as an educational reference implementation that demonstrates:

* Next.js 16 App Router architecture.
* React Server Components.
* Server Actions.
* Clerk authentication.
* Sanity document modeling.
* Inngest durable workflows.
* Resilient event processing.
* Production observability.
* Testing strategy.
* Deployment practices.

The codebase intentionally favors clarity over cleverness.

---

# Repository Goals

The implementation is designed around five objectives.

## 1. Architectural Clarity

Every folder exists for a reason.

Code organization should communicate system boundaries.

---

## 2. Production Patterns

The implementation demonstrates patterns used in real-world systems:

* Layer separation.
* Dependency inversion.
* Event-driven workflows.
* Idempotent operations.
* Observability.

---

## 3. Framework Alignment

The implementation follows modern Next.js 16 practices:

* App Router.
* Server Components.
* Server Actions.
* Async request handling.
* Streaming UI.
* Progressive enhancement.

---

## 4. Operational Readiness

The repository includes:

* Environment management.
* Logging.
* Monitoring hooks.
* Error handling.
* Deployment configuration.

---

## 5. Evolution Capability

The architecture allows future growth:

* Multiple organizations.
* Multi-tenant events.
* Advanced analytics.
* Mobile applications.
* Enterprise integrations.

---

# Technology Stack

The reference implementation uses:

| Area             | Technology          |
| ---------------- | ------------------- |
| Framework        | Next.js 16          |
| UI               | React               |
| Language         | TypeScript          |
| Authentication   | Clerk               |
| CMS / Data Store | Sanity              |
| Workflow Engine  | Inngest             |
| Rate Limiting    | Upstash Redis       |
| Email            | Resend              |
| Validation       | Zod                 |
| Testing          | Vitest / Playwright |
| Deployment       | Vercel              |

---

# Repository Structure

The final repository:

```text
attendance-platform/

├── app/
│
├── components/
│
├── actions/
│
├── domain/
│
├── application/
│
├── repositories/
│
├── infrastructure/
│
├── workflows/
│
├── schemas/
│
├── tests/
│
├── public/
│
├── scripts/
│
├── docs/
│
├── package.json
│
├── next.config.ts
│
├── tsconfig.json
│
└── .env.example
```

---

# Implementation Order

The repository should be built in the following sequence:

```text
1. Project Bootstrap

        ↓

2. Environment Configuration

        ↓

3. Infrastructure Clients

        ↓

4. Domain Model

        ↓

5. Persistence Layer

        ↓

6. Application Services

        ↓

7. Server Actions

        ↓

8. Inngest Workflows

        ↓

9. User Interface

        ↓

10. Testing + Deployment
```

This order follows dependency direction.

---

# Phase 1

# Project Bootstrap

Create the Next.js 16 application.

Responsibilities:

* Configure TypeScript.
* Enable App Router.
* Configure linting.
* Configure formatting.
* Establish folder structure.

At this stage, no business functionality exists.

The objective is creating a stable foundation.

---

# Phase 2

# Environment Configuration

All external dependencies require configuration.

Example:

```text
.env.example

NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=

CLERK_SECRET_KEY=

SANITY_PROJECT_ID=

SANITY_DATASET=

INNGEST_EVENT_KEY=

INNGEST_SIGNING_KEY=

RESEND_API_KEY=

UPSTASH_REDIS_REST_URL=

UPSTASH_REDIS_REST_TOKEN=
```

Production environments provide actual values.

Source control contains only the template.

---

# Phase 3

# Infrastructure Setup

Create external service adapters.

Example:

```text
infrastructure/

├── clerk/

├── sanity/

├── inngest/

├── redis/

├── email/

└── logging/
```

The rest of the application never imports third-party SDKs directly.

---

# Phase 4

# Domain Implementation

Define business concepts.

Example:

```text
domain/

├── event/

├── attendance/

├── session/

└── organization/
```

The domain layer contains:

* Entities.
* Value objects.
* Domain errors.
* Business concepts.

It does not know about databases or frameworks.

---

# Phase 5

# Persistence Implementation

Implement repositories.

Example:

```text
repositories/

attendance.repository.ts

event.repository.ts

session.repository.ts
```

Repositories translate between:

```text
Domain Objects

        ↕

Sanity Documents
```

---

# Phase 6

# Application Services

Implement business workflows.

Example:

```text
application/

services/

AttendanceService

EventService

DashboardService
```

Services coordinate:

* Validation.
* Policies.
* Repositories.
* Domain events.

---

# Phase 7

# Server Actions

Connect user intent to business operations.

Example:

```text
actions/

attendance.actions.ts

event.actions.ts
```

Responsibilities:

* Authentication.
* Validation.
* Service invocation.
* Response handling.

---

# Phase 8

# Durable Workflows

Implement asynchronous processing.

Example:

```text
workflows/

attendance.workflow.ts

email.workflow.ts

analytics.workflow.ts
```

Responsibilities:

* Retry failures.
* Execute background tasks.
* Fan out events.
* Schedule work.

---

# Phase 9

# Presentation Layer

Implement user experiences.

Example:

```text
app/

events/[slug]/checkin/

page.tsx
```

Components include:

* QR scanner.
* Check-in button.
* Attendance status.
* Organizer dashboard.

---

# Phase 10

# Verification

Before production:

Run:

```bash
npm run lint

npm run test

npm run test:e2e

npm run build
```

The repository must pass all verification stages.

---

# Code Reading Strategy

Do not start with components.

Start with the business flow.

Recommended reading order:

```text
AttendanceService

        ↓

AttendanceRepository

        ↓

AttendanceWorkflow

        ↓

CheckIn Server Action

        ↓

Check-In UI
```

This follows the actual runtime path.

---

# Extending the Platform

Future features follow the same architecture.

Example:

Adding certificates:

```text
Certificate Domain

        ↓

Certificate Service

        ↓

Certificate Repository

        ↓

Certificate Workflow

        ↓

Certificate UI
```

New capabilities become additions rather than rewrites.

---

# Final Note

The repository is intentionally structured around engineering principles rather than framework conventions.

Frameworks will evolve.

Libraries will change.

Business requirements will grow.

A strong architecture allows those changes without destabilizing the entire system.

The implementation is therefore not the destination.

It is a concrete demonstration of the principles discussed throughout this book.
