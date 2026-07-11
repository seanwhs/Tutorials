# Implementation Map

> *"Architecture becomes valuable when ideas can be traced to concrete implementations."*

---

# Purpose

This section maps the architectural concepts introduced throughout the book to their corresponding implementation artifacts.

The goal is not to explain every file.

The goal is to establish a mental model of how the repository is organized and how a request travels through the system.

---

# Repository Overview

The reference implementation follows a layered architecture.

```text
attendance-platform/

├── app/
│   ├── (public)/
│   ├── dashboard/
│   ├── events/
│   ├── api/
│   └── layout.tsx
│
├── components/
│   ├── ui/
│   ├── attendance/
│   ├── events/
│   └── dashboard/
│
├── actions/
│   ├── attendance.actions.ts
│   ├── event.actions.ts
│   └── user.actions.ts
│
├── application/
│   ├── services/
│   ├── policies/
│   ├── commands/
│   └── events/
│
├── domain/
│   ├── entities/
│   ├── value-objects/
│   └── errors/
│
├── repositories/
│   ├── attendance.repository.ts
│   ├── event.repository.ts
│   └── user.repository.ts
│
├── infrastructure/
│   ├── sanity/
│   ├── clerk/
│   ├── inngest/
│   ├── redis/
│   ├── email/
│   └── logging/
│
├── workflows/
│   ├── attendance.workflow.ts
│   ├── notification.workflow.ts
│   └── analytics.workflow.ts
│
├── tests/
│
└── docs/
```

---

# Request Flow Mapping

A QR scan travels through the following path:

```text
User scans QR

        ↓

app/events/[slug]/checkin

        ↓

Attendance Client Component

        ↓

Server Action

actions/attendance.actions.ts

        ↓

AttendanceService

application/services/

        ↓

AttendanceRepository

repositories/

        ↓

Sanity Client

infrastructure/sanity/

        ↓

Domain Event

AttendanceRecorded

        ↓

Inngest Workflow

workflows/

        ↓

Email + Analytics + Dashboard
```

---

# Layer Responsibilities

## App Layer

Location:

```text
/app
```

Responsibilities:

* Routing.
* Layout composition.
* Server Components.
* Metadata.
* Loading states.
* Error boundaries.

The App Router defines the application surface.

It does not contain business logic.

---

# Components Layer

Location:

```text
/components
```

Responsibilities:

* UI composition.
* Reusable presentation components.
* User interactions.

Examples:

```text
components/

attendance/
    CheckInButton.tsx
    AttendanceStatus.tsx

events/
    EventCard.tsx
    QRCodeDisplay.tsx

dashboard/
    LiveCounter.tsx
```

---

# Actions Layer

Location:

```text
/actions
```

Responsibilities:

* Receive user intent.
* Authenticate requests.
* Validate input.
* Call application services.

Example:

```text
checkInAttendee()
createEvent()
updateRegistration()
```

Server Actions remain thin.

---

# Application Layer

Location:

```text
/application
```

Responsibilities:

* Business orchestration.
* Policy execution.
* Command handling.
* Domain event creation.

Example:

```text
AttendanceService

    |
    |
    +-- EventRepository

    |
    |
    +-- AttendanceRepository

    |
    |
    +-- AttendancePolicy
```

---

# Domain Layer

Location:

```text
/domain
```

Responsibilities:

* Business concepts.
* Entities.
* Value objects.
* Domain errors.

Examples:

```text
Event
AttendanceRecord
Venue
Session
```

This layer has no dependency on Next.js.

---

# Repository Layer

Location:

```text
/repositories
```

Responsibilities:

* Persistence abstraction.
* Query execution.
* Data mapping.

Example:

```typescript
interface AttendanceRepository {

    findByUserAndEvent()

    create()

    exists()

}
```

The application layer depends on the interface, not Sanity.

---

# Infrastructure Layer

Location:

```text
/infrastructure
```

Responsibilities:

External integrations:

```text
Clerk
Sanity
Inngest
Redis
Resend
OpenTelemetry
```

Infrastructure adapters translate external systems into application-friendly interfaces.

---

# Workflow Layer

Location:

```text
/workflows
```

Responsibilities:

* Durable execution.
* Retries.
* Scheduling.
* Fan-out.
* Compensation.

Example:

```text
attendance.workflow.ts

Steps:

1. Validate attendance
2. Store record
3. Send email
4. Update dashboard
5. Publish analytics
```

---

# Testing Map

Testing follows the architecture.

```text
tests/

├── domain/
│
├── application/
│
├── repositories/
│
├── actions/
│
├── workflows/
│
└── e2e/
```

Each layer is tested independently.

---

# Adding a New Feature

Suppose we add:

> "Generate attendance certificate after event completion."

The change flows through the architecture:

```text
Domain

Certificate Entity

        ↓

Application

Certificate Service

        ↓

Repository

Certificate Repository

        ↓

Workflow

Certificate Generation Job

        ↓

Presentation

Certificate Download UI
```

The architecture guides implementation.

---

# Finding Code by Question

When investigating the system:

## "Where is authentication handled?"

Look at:

```text
/infrastructure/clerk
/actions
```

---

## "Where is attendance validation?"

Look at:

```text
/application/policies
/application/services
```

---

## "Where is the database write?"

Look at:

```text
/repositories
/infrastructure/sanity
```

---

## "Where are emails sent?"

Look at:

```text
/workflows
/infrastructure/email
```

---

## "Where does the QR scan happen?"

Look at:

```text
/components/attendance
/app/events/[slug]/checkin
```

---

# Architectural Rule

The dependency direction is always:

```text
Presentation

        ↓

Application

        ↓

Domain

        ↓

Infrastructure
```

Higher layers may depend on lower layers.

Lower layers never depend on higher layers.

---

# Closing Perspective

A repository is not simply a collection of files.

It is an executable expression of the architecture.

The purpose of this implementation map is to allow engineers to move confidently between:

* Architecture decisions.
* Source code.
* Runtime behavior.
* Production operations.

Once this mental model is established, extending the platform becomes a predictable engineering activity rather than a process of discovering hidden dependencies.
