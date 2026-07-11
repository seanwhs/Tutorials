# Appendix H

# Application Services

> *"Frameworks deliver requests. Databases store state. Services make decisions."*

---

# Purpose

The Application Services layer is responsible for orchestrating business operations.

It receives validated requests from Server Actions, coordinates repositories, evaluates business policies, invokes workflows where appropriate, and returns deterministic results.

Unlike the Domain Model, which defines *what the business is*, or the Persistence Layer, which defines *how state is stored*, the Application Services layer defines *how the business behaves*.

It is the operational core of the attendance platform.

---

# Responsibilities

Application Services are responsible for:

* Coordinating business operations.
* Enforcing business policies.
* Orchestrating repositories.
* Publishing domain events.
* Returning application responses.

Application Services are **not** responsible for:

* Rendering UI.
* Managing HTTP requests.
* Performing database queries directly.
* Sending emails.
* Calling third-party SDKs.

Those responsibilities belong to other architectural layers.

---

# Position Within the Architecture

```text
                    Browser
                       │
                       ▼
              Next.js Server Action
                       │
                       ▼
              Application Service
          ┌────────────┼────────────┐
          ▼            ▼            ▼
   Repository      Policy      Workflow
          │                         │
          ▼                         ▼
      Sanity                 Inngest Event
```

Application Services coordinate work without becoming tightly coupled to infrastructure.

---

# Service Catalogue

The reference implementation defines a service for each major business capability.

| Service             | Responsibility                      |
| ------------------- | ----------------------------------- |
| OrganizationService | Manage organizations                |
| VenueService        | Manage venues                       |
| EventService        | Event lifecycle                     |
| SessionService      | Session management                  |
| AttendanceService   | Attendance validation and recording |
| DashboardService    | Dashboard projections               |
| NotificationService | Notification orchestration          |
| AnalyticsService    | Business metrics                    |

Each service encapsulates one cohesive area of business behavior.

---

# Command-Oriented Design

Application Services expose commands rather than CRUD operations.

Instead of:

```text
saveAttendance()
```

the implementation favors:

```text
checkInAttendee()

cancelRegistration()

closeEvent()

publishResults()

reopenCheckIn()
```

Commands communicate business intent.

---

# The Check-In Service

The most important service in the platform is the **AttendanceService**.

Its primary responsibility is to coordinate the complete attendance process while preserving business integrity.

Typical workflow:

```text
Validate Request
        │
        ▼
Load Event
        │
        ▼
Evaluate Attendance Policy
        │
        ▼
Check Duplicate Attendance
        │
        ▼
Verify Capacity
        │
        ▼
Create Attendance Record
        │
        ▼
Publish Domain Event
```

Every decision occurs before persistence.

---

# Business Policies

Policies represent business rules that may evolve independently of implementation.

Examples include:

## Attendance Policy

Determines:

* Check-in window.
* Capacity rules.
* Authentication requirements.
* Duplicate behavior.
* Session restrictions.

---

## Capacity Policy

Evaluates:

* Maximum attendance.
* Reserved seats.
* VIP allocations.
* Waitlist behavior.

---

## Security Policy

Determines:

* Authentication requirements.
* Authorization.
* Geofencing.
* QR signature validation.

Policies remain independent of storage technologies and presentation logic.

---

# Service Collaboration

Services communicate through well-defined interfaces.

Example:

```text
AttendanceService
        │
        ├────────► EventRepository
        │
        ├────────► AttendanceRepository
        │
        ├────────► CapacityPolicy
        │
        └────────► WorkflowPublisher
```

Each dependency has a single responsibility.

---

# Domain Events

Application Services publish domain events rather than invoking downstream processes directly.

Typical events include:

* AttendanceRequested
* AttendanceRecorded
* AttendanceRejected
* EventOpened
* EventClosed
* SessionStarted
* SessionCompleted

These events become inputs for durable workflows.

---

# Why Publish Events?

Publishing events rather than executing side effects immediately provides several benefits:

* Loose coupling.
* Better scalability.
* Independent retries.
* Improved observability.
* Easier testing.
* Greater resilience.

For example, sending a confirmation email should never determine whether attendance is successfully recorded.

---

# Transaction Boundary

The service layer defines the transactional boundary.

A successful check-in guarantees:

* Business validation completed.
* Attendance persisted.
* Domain event published.

Everything after that point becomes asynchronous.

This approach minimizes user-facing latency while preserving consistency.

---

# Idempotency

Application Services are designed to be safely re-executed.

Every command must produce the same outcome regardless of duplicate submissions.

Typical strategies include:

* Repository uniqueness constraints.
* Business key evaluation.
* Conditional persistence.
* Workflow deduplication.

---

> **Production Tip — Business Idempotency**
>
> Idempotency belongs in the business layer, not the user interface. Double-click prevention improves the user experience, but only business rules can guarantee that duplicate requests never produce duplicate attendance records.

---

# Error Handling

Application Services distinguish between three categories of failures.

| Category       | Example            | Retry |
| -------------- | ------------------ | ----- |
| Validation     | Invalid QR         | No    |
| Business Rule  | Already checked in | No    |
| Infrastructure | Database timeout   | Yes   |

Only infrastructure failures are retried automatically.

---

# Service Composition

Services should remain small.

A service should answer one question:

> **What business capability does this module own?**

If the answer contains "and", the service probably has too many responsibilities.

---

# Testing Strategy

Application Services are tested independently of infrastructure.

Typical test doubles include:

* Mock repositories.
* Stub policies.
* Fake workflow publishers.

Because infrastructure is abstracted away, business rules can be verified without requiring databases or external services.

---

# Reference Implementation

The implementation accompanying this appendix includes:

* Service interfaces.
* Command handlers.
* Business policies.
* Validation pipeline.
* Event publisher.
* Unit tests.
* Integration tests.

Together, these components form the behavioral core of the application.

---

# Looking Ahead

The next appendix introduces the entry point into the application: **Next.js 16 Server Actions**.

Server Actions bridge the gap between the user interface and the application layer, authenticating requests, validating input, invoking Application Services, and returning lightweight responses while delegating long-running work to durable workflows.
