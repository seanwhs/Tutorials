# Appendix C

# Engineering Standards and Development Conventions

> *"Code is read far more often than it is written. Engineering standards exist not to restrict creativity, but to reduce cognitive load, improve consistency, and enable teams to build reliable software together."*

---

# Purpose

This appendix establishes the engineering standards used throughout the reference implementation.

Rather than treating coding style as a matter of personal preference, the project adopts a consistent set of conventions covering architecture, naming, error handling, testing, security, observability, and deployment readiness.

Every source file presented in subsequent appendices follows these standards.

---

# Engineering Principles

The implementation is guided by the following principles:

* Simplicity over cleverness.
* Readability over brevity.
* Composition over inheritance.
* Explicitness over magic.
* Immutable data wherever practical.
* Small, focused modules.
* Infrastructure separated from business logic.
* Fail fast when configuration or validation errors occur.
* Design for observability from day one.
* Optimize for maintainability before optimization.

These principles influence every architectural decision in the application.

---

# Architectural Style

The application combines several complementary architectural patterns:

* Clean Architecture
* Domain-Driven Design (DDD)
* Event-Driven Architecture
* Repository Pattern
* Service Layer Pattern
* Command-Oriented Server Actions
* Durable Workflow Orchestration

Each pattern addresses a different concern:

| Pattern            | Responsibility                |
| ------------------ | ----------------------------- |
| Clean Architecture | Layer separation              |
| DDD                | Business modelling            |
| Repository         | Data access abstraction       |
| Service Layer      | Business behaviour            |
| Event-Driven       | Asynchronous processing       |
| Durable Workflows  | Reliable background execution |

No single pattern is applied dogmatically; instead, the architecture adopts the simplest pattern appropriate for each concern.

---

# Directory Conventions

Every top-level directory has a single responsibility.

| Directory       | Responsibility               |
| --------------- | ---------------------------- |
| `app/`          | Routing and rendering        |
| `actions/`      | Server Actions               |
| `components/`   | User interface               |
| `services/`     | Business rules               |
| `repositories/` | Persistence                  |
| `workflows/`    | Durable background processes |
| `lib/`          | Infrastructure               |
| `sanity/`       | Content model                |
| `tests/`        | Automated tests              |

Business logic should never migrate into infrastructure or presentation layers.

---

# Naming Conventions

Consistency improves readability.

## Files

| Type         | Convention           | Example                   |
| ------------ | -------------------- | ------------------------- |
| Components   | PascalCase           | `AttendanceCard.tsx`      |
| Hooks        | camelCase with `use` | `useOfflineQueue.ts`      |
| Utilities    | camelCase            | `formatDate.ts`           |
| Services     | PascalCase           | `AttendanceService.ts`    |
| Repositories | PascalCase           | `AttendanceRepository.ts` |
| Workflows    | kebab-case           | `attendance-checkin.ts`   |
| Schemas      | camelCase            | `attendanceRecord.ts`     |

---

## Functions

Function names should describe behaviour.

Good examples:

```ts
createAttendanceRecord()
sendConfirmationEmail()
calculateAttendanceRate()
publishCheckInRequested()
```

Avoid vague names such as:

```ts
process()
handle()
execute()
run()
```

unless their surrounding context makes the behaviour immediately obvious.

---

# TypeScript Standards

The reference implementation uses TypeScript in **strict mode**.

Guidelines include:

* Avoid `any`.
* Prefer `unknown` when type information is unavailable.
* Use discriminated unions for state.
* Export explicit interfaces where appropriate.
* Model domain concepts with types rather than comments.

Type safety should eliminate entire classes of runtime errors.

---

# Import Order

Imports follow a consistent order:

```text
1. Framework
2. Third-party packages
3. Internal aliases
4. Relative imports
```

Example:

```ts
import { cache } from "react";

import { auth } from "@clerk/nextjs/server";

import { AttendanceRepository } from "@/repositories/AttendanceRepository";

import { calculateDuration } from "../utils/dates";
```

Grouping imports consistently improves readability during reviews.

---

# Error Handling

Errors are classified into three categories.

## Validation Errors

Returned to the user.

Examples:

* Missing event.
* Invalid QR code.
* Event closed.

---

## Domain Errors

Represent business rule violations.

Examples:

* Duplicate attendance.
* Capacity exceeded.
* Check-in window closed.

---

## Infrastructure Errors

Represent failures in external systems.

Examples:

* Sanity unavailable.
* Redis timeout.
* Email provider failure.

Infrastructure errors should be retried where appropriate and logged with sufficient diagnostic context.

---

# Logging Standards

Every log entry should answer four questions:

* What happened?
* Where did it happen?
* Which user or event was involved?
* Can the issue be traced across services?

Structured logging is preferred over free-form messages.

Example fields include:

* Correlation ID
* Request ID
* Event ID
* User ID
* Workflow ID
* Duration
* Result

Sensitive information must never be logged.

---

# Validation

All external input should be validated.

Typical validation points include:

* Server Actions
* Route Handlers
* Workflow events
* Environment configuration

Validation should occur before business logic executes.

---

# Repository Pattern

Repositories encapsulate persistence concerns.

Responsibilities include:

* Queries
* Transactions
* Persistence
* Mapping

Repositories should not implement business decisions.

---

# Service Layer

Services express business behaviour.

Examples:

* Can this attendee check in?
* Is the event currently open?
* Has capacity been exceeded?

Services coordinate repositories but remain independent of storage technologies.

---

# Server Action Standards

Every Server Action should follow the same structure:

1. Authenticate.
2. Validate input.
3. Authorize.
4. Invoke a service.
5. Return a minimal response.

Long-running work must be delegated to workflows.

---

# Workflow Standards

Workflows are responsible for:

* Retry logic
* Compensation
* Fan-out
* Notifications
* Analytics
* Audit logging

Workflows must be idempotent so that retries never produce duplicate side effects.

---

# Security Standards

Security is treated as a cross-cutting concern.

Key principles include:

* Authenticate every request.
* Authorize every action.
* Validate every input.
* Never trust client data.
* Store secrets securely.
* Apply least privilege.
* Rate-limit public endpoints.
* Sign or validate QR payloads where appropriate.

---

# Testing Standards

The testing strategy follows the testing pyramid.

```text
          ▲
          │
     End-to-End
          │
   Integration Tests
          │
      Unit Tests
          ▼
```

Business logic should be tested independently of the user interface whenever possible.

---

# Documentation Standards

Every public module should include:

* Purpose
* Responsibilities
* Dependencies
* Example usage

Complex workflows should also include sequence diagrams.

Documentation is maintained alongside the code to reduce drift.

---

# Performance Guidelines

Performance considerations include:

* Prefer Server Components for data-heavy pages.
* Keep Client Components small.
* Avoid unnecessary client-side state.
* Cache immutable data.
* Defer expensive work to workflows.
* Batch persistence operations where appropriate.

Performance should be measured rather than assumed.

---

# Observability

Every critical workflow should expose:

* Logs
* Metrics
* Traces
* Health checks

Operational visibility is considered part of the feature, not an afterthought.

---

# Engineering Checklist

Before merging a feature, verify:

* Architecture respected.
* Types validated.
* Business rules tested.
* Errors handled.
* Logging included.
* Documentation updated.
* Security reviewed.
* Performance considered.

This checklist encourages consistent engineering quality across the application.

---

# Looking Ahead

With the engineering standards established, the next appendix introduces the application's domain model.

Rather than beginning with implementation details, the focus shifts to the business concepts that drive the system: organizations, venues, events, sessions, attendees, attendance records, and the relationships between them.

Understanding these concepts first makes the subsequent source code easier to read, reason about, and extend.
