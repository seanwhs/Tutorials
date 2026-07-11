# Implementation Map

> *"Architecture becomes valuable when ideas can be traced to concrete implementations."*

---

## Purpose

This document maps the architectural concepts defined in this project to their specific implementation artifacts. Its goal is not to exhaustively explain every file, but to establish a clear mental model of the repository structure and the lifecycle of a request as it traverses the system.

---

## Repository Structure

The project follows a layered architecture to ensure separation of concerns and maintainability.

```text
attendance-platform/
├── app/            # Next.js App Router (Routing, UI composition)
├── components/     # Reusable presentation and UI logic
├── actions/        # Server Actions (Request entry points)
├── application/    # Business orchestration, policies, and services
├── domain/         # Core business entities and logic
├── repositories/   # Data persistence abstractions
├── infrastructure/ # External system integrations (Sanity, Clerk, Inngest, etc.)
├── workflows/      # Durable execution and background processes
├── tests/          # Layer-specific and end-to-end test suites
└── docs/           # Project documentation

```

---

## Request Lifecycle: The QR Scan

A typical QR scan traverses the architecture in a unidirectional flow:

1. **Client Interaction:** User scans QR code.
2. **Presentation:** `app/events/[slug]/checkin` (Server Component).
3. **Trigger:** `components/attendance/CheckInButton.tsx` initiates a request.
4. **Action:** `actions/attendance.actions.ts` validates intent and authentication.
5. **Orchestration:** `application/services/AttendanceService` coordinates business logic.
6. **Data Access:** `repositories/AttendanceRepository` interfaces with the store.
7. **Infrastructure:** `infrastructure/sanity/` performs the atomic database write.
8. **Event Trigger:** System emits `AttendanceRecorded` domain event.
9. **Workflow:** `workflows/` (via Inngest) handles side effects (Email, Analytics, Dashboard updates).

---

## Layer Responsibilities

### App Layer (`/app`)

Defines the application surface. Contains routing, layout composition, metadata, and error boundaries. **Rule:** Does not contain business logic.

### Components Layer (`/components`)

Handles UI composition, user interactions, and presentation logic.

* **attendance/**: Check-in UX and status indicators.
* **events/**: Event cards and QR rendering.
* **dashboard/**: Real-time data visualization.

### Actions Layer (`/actions`)

The primary interface for client requests. Responsibilities include authentication, input validation, and delegating to application services. **Rule:** Keep Server Actions thin.

### Application Layer (`/application`)

The core of business orchestration. Manages policy execution, command handling, and the triggering of domain events. It consumes repositories and domain entities to fulfill business requirements.

### Domain Layer (`/domain`)

Contains the "business language"—entities, value objects, and domain-specific errors. **Rule:** This layer has zero dependencies on Next.js or external frameworks.

### Repository Layer (`/repositories`)

Provides persistence abstraction. The application layer depends on repository interfaces, not concrete database implementations (e.g., Sanity).

### Infrastructure Layer (`/infrastructure`)

Houses adapters for external services (Clerk, Sanity, Inngest, Redis, Resend, OpenTelemetry). This layer translates external system APIs into application-friendly interfaces.

### Workflow Layer (`/workflows`)

Handles durable execution patterns such as retries, long-running processes, fan-out operations, and compensation logic (Sagas).

---

## Testing Strategy

Tests are partitioned to mirror the architectural layers, ensuring each layer is verified in isolation:

* `tests/domain/`: Pure logic and entity state.
* `tests/application/`: Service and policy orchestration.
* `tests/repositories/`: Data mapping and query integrity.
* `tests/actions/`: Request handling and validation.
* `tests/workflows/`: Durable process execution.
* `tests/e2e/`: Full system integration.

---

## Architectural Rule: Dependency Direction

Dependency flow is strictly unidirectional to prevent tight coupling:

**Presentation → Application → Domain → Infrastructure**

* Higher layers depend on lower layers.
* Lower layers **never** depend on higher layers.

---

## Troubleshooting & Discovery

Use this mapping to locate logic during investigation:

| Investigation Question | Target Directory |
| --- | --- |
| **Where is auth handled?** | `/infrastructure/clerk`, `/actions` |
| **Where is validation logic?** | `/application/policies`, `/application/services` |
| **Where is the DB write?** | `/repositories`, `/infrastructure/sanity` |
| **Where are emails sent?** | `/workflows`, `/infrastructure/email` |
| **Where does the QR scan begin?** | `/components/attendance`, `/app/events/[slug]/checkin` |

---

## Closing Perspective

A repository is an executable expression of an architecture. By maintaining this mental model, extending the platform becomes a predictable engineering process rather than a hunt for hidden dependencies. When adding features—such as certificate generation—you simply follow the architectural thread from **Domain** (Entity) to **Application** (Service) to **Repository** (Persistence) to **Workflow** (Job) and finally **Presentation** (UI).
