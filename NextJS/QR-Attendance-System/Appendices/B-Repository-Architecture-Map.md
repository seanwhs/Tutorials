# Appendix B

# Repository Architecture Map

> *"Good software architecture is not measured by the number of directories in a repository. It is measured by how easily engineers can locate responsibilities, understand dependencies, and safely make changes."*

---

# Purpose

This appendix serves as the navigation guide for the complete reference implementation.

Rather than presenting source code immediately, it explains how the repository is organized, why each layer exists, how the layers interact, and which dependencies are permitted.

The repository follows several guiding principles:

* Feature-oriented organization
* Separation of Concerns (SoC)
* Domain-Driven Design (DDD)
* Clean Architecture
* Event-Driven Architecture
* Single Responsibility Principle (SRP)
* Dependency Inversion Principle (DIP)

Every subsequent appendix expands one or more sections of this architecture.

---

# High-Level Architecture

The application is organized into logical architectural layers rather than technical silos.

```text
┌───────────────────────────────────────────┐
│               Presentation                │
│ Next.js App Router • Pages • Components   │
└───────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────┐
│              Application Layer            │
│ Server Actions • Commands • Validation    │
└───────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────┐
│               Domain Layer                │
│ Services • Policies • Business Rules      │
└───────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────┐
│             Persistence Layer             │
│ Repositories • Sanity • Queries           │
└───────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────┐
│          Infrastructure Layer             │
│ Clerk • Inngest • Redis • Resend          │
└───────────────────────────────────────────┘
```

Each layer has a single responsibility and communicates only with adjacent layers.

---

# Repository Structure

```text
attendance-platform/

├── docs/
├── public/
├── src/
│
│   ├── app/
│   ├── actions/
│   ├── components/
│   ├── services/
│   ├── repositories/
│   ├── workflows/
│   ├── sanity/
│   ├── lib/
│   ├── emails/
│   ├── hooks/
│   ├── providers/
│   ├── middleware/
│   ├── types/
│   ├── utils/
│   ├── constants/
│   └── tests/
│
├── package.json
├── next.config.ts
├── tsconfig.json
└── README.md
```

The repository is intentionally shallow. Most business functionality resides under `src/`, grouped by architectural responsibility.

---

# Directory Responsibilities

## `src/app/`

### Responsibility

Implements the Next.js App Router.

Contains:

* Routes
* Layouts
* Server Components
* Loading UI
* Error boundaries
* Route handlers

### Depends On

* Server Actions
* Components

### Never Depends On

* Repositories
* External APIs directly

The presentation layer should remain thin.

---

## `src/actions/`

### Responsibility

Implements Server Actions.

Each action represents a user intent, such as:

* Check in to an event
* Create an event
* Update an attendee
* Generate a QR code

### Depends On

* Services
* Validation
* Authentication

### Never Depends On

* UI components

Server Actions coordinate work but do not contain business logic.

---

## `src/components/`

### Responsibility

Contains reusable user interface components.

Examples include:

* QR Scanner
* Check-in Button
* Attendance Card
* Dashboard Widgets
* Charts
* Navigation
* Form Controls

Components should remain presentation-focused.

---

## `src/services/`

### Responsibility

Implements business rules.

Examples:

* AttendanceService
* CheckInService
* EventService
* NotificationService
* DashboardService

Services express domain behavior and coordinate repositories.

---

## `src/repositories/`

### Responsibility

Provides access to persistent storage.

Responsibilities include:

* Reading data
* Writing data
* Transactions
* Query abstraction

Repositories isolate the rest of the application from storage-specific implementation details.

---

## `src/workflows/`

### Responsibility

Implements durable workflows using Inngest.

Typical workflows include:

* Attendance processing
* Email notifications
* Analytics fan-out
* Dashboard updates
* Retry handling

Long-running operations belong here rather than in Server Actions.

---

## `src/sanity/`

### Responsibility

Contains the content model.

Includes:

* Document schemas
* GROQ queries
* Mutations
* Seed data
* Studio configuration

The remainder of the application accesses Sanity through repositories rather than directly.

---

## `src/lib/`

### Responsibility

Shared infrastructure.

Examples include:

* Configuration
* Logging
* Authentication helpers
* Redis client
* Sanity client
* Inngest client
* Date utilities

Infrastructure should contain no business rules.

---

## `src/emails/`

Contains transactional email templates built with React Email.

Examples include:

* Attendance confirmation
* Event reminder
* Administrative notifications

Templates remain independent of email delivery.

---

## `src/hooks/`

Contains reusable React hooks.

Examples:

* `useCheckIn()`
* `useNetworkStatus()`
* `useOfflineQueue()`

Hooks encapsulate reusable client-side behavior.

---

## `src/providers/`

Contains React context providers.

Examples:

* Theme provider
* Query provider
* Toast provider

Providers compose application-wide functionality.

---

## `src/middleware/`

Contains reusable middleware utilities.

Examples include:

* Correlation IDs
* Rate limiting
* Security headers
* Request logging

---

## `src/tests/`

Contains all automated tests.

The test suite is divided into:

* Unit tests
* Integration tests
* End-to-end tests
* Fixtures
* Test utilities

---

# Dependency Rules

The repository follows strict dependency rules.

```text
UI
 │
 ▼
Server Actions
 │
 ▼
Services
 │
 ▼
Repositories
 │
 ▼
Infrastructure
 │
 ▼
External Services
```

Dependencies always flow downward.

Lower layers never depend on higher layers.

---

# Architectural Boundaries

| Layer          | May Access                 |
| -------------- | -------------------------- |
| Pages          | Components, Server Actions |
| Components     | Hooks, Utilities           |
| Server Actions | Services                   |
| Services       | Repositories               |
| Repositories   | Infrastructure             |
| Infrastructure | External APIs              |

Cross-layer shortcuts are intentionally avoided.

---

# Request Flow

A typical attendance request follows this path:

```text
Browser
   │
   ▼
Server Component
   │
   ▼
Server Action
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
Inngest Workflow
   │
   ├── Email
   ├── Analytics
   ├── Dashboard
   └── Audit Log
```

This separation keeps the user experience responsive while allowing background work to proceed independently.

---

# Repository Design Principles

The implementation adheres to several architectural principles:

* One responsibility per module.
* Business rules are independent of infrastructure.
* External services are isolated behind abstractions.
* Long-running work is delegated to workflows.
* Read and write concerns are separated where appropriate.
* Every layer is independently testable.

These principles help the application remain maintainable as it evolves.

---

# Reading Guide

Readers may approach the repository from different perspectives.

| Role               | Suggested Starting Point                  |
| ------------------ | ----------------------------------------- |
| Frontend Developer | `src/app/`, `src/components/`             |
| Backend Developer  | `src/actions/`, `src/services/`           |
| Solution Architect | Domain model, workflows, repositories     |
| DevOps Engineer    | Infrastructure, deployment, observability |
| Security Engineer  | Middleware, authentication, workflows     |

The repository is intentionally organized so that each audience can focus on the layers most relevant to their work.

---

# Appendix Roadmap

The remaining appendices build on this architectural map.

| Appendix | Topic                         |
| -------- | ----------------------------- |
| C        | Engineering Standards         |
| D        | Domain Model                  |
| E        | Domain Source Code            |
| F        | Infrastructure                |
| G        | External Integrations         |
| H        | Repository Layer              |
| I        | Service Layer                 |
| J        | Server Actions                |
| K        | Workflow Engine               |
| L        | User Interface                |
| M        | Dashboard                     |
| N        | Offline Architecture          |
| O        | Security                      |
| P        | Observability                 |
| Q        | Testing                       |
| R        | Deployment                    |
| S        | Complete Source Listing       |
| T        | Sequence Diagrams             |
| U        | Architecture Decision Records |

Together, these appendices form a complete engineering reference manual that complements the concepts presented throughout the book while providing a practical blueprint for building production-grade, workflow-driven applications with Next.js 16.
