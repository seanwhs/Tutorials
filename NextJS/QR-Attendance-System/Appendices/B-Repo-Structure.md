# Appendix B

# Repository Structure

> *"A well-organized repository is one of the most valuable forms of documentation. It communicates architectural intent before a single line of business logic is read."*

---

# Purpose

This appendix introduces the complete repository layout for the QR Attendance Platform.

Rather than organizing the application by technical layer alone, the project follows a **feature-oriented architecture** with clear separation between presentation, application, domain, infrastructure, and workflow concerns.

The repository is designed around the following principles:

* Single Responsibility Principle (SRP)
* Separation of Concerns (SoC)
* Dependency Inversion
* Domain-Driven Design (DDD) concepts
* Event-Driven Architecture
* Production-ready maintainability
* Scalability through modular design

Every subsequent appendix will expand on one or more sections of this repository.

---

# High-Level Repository Layout

```text
attendance-platform/
│
├── .github/
│   └── workflows/
│       ├── ci.yml
│       ├── lint.yml
│       ├── test.yml
│       └── release.yml
│
├── docs/
│   ├── architecture/
│   ├── diagrams/
│   ├── adr/
│   └── api/
│
├── public/
│   ├── images/
│   ├── icons/
│   ├── manifest.json
│   ├── sw.js
│   └── offline.html
│
├── src/
│
│   ├── app/
│   │
│   │   ├── (marketing)/
│   │   │
│   │   ├── admin/
│   │   │
│   │   ├── dashboard/
│   │   │
│   │   ├── events/
│   │   │   └── [slug]/
│   │   │       ├── page.tsx
│   │   │       ├── loading.tsx
│   │   │       ├── error.tsx
│   │   │       └── checkin/
│   │   │           └── page.tsx
│   │   │
│   │   ├── api/
│   │   │
│   │   │   ├── inngest/
│   │   │   ├── health/
│   │   │   └── webhooks/
│   │   │
│   │   ├── globals.css
│   │   ├── layout.tsx
│   │   ├── loading.tsx
│   │   ├── error.tsx
│   │   └── not-found.tsx
│   │
│   ├── actions/
│   │   ├── attendance/
│   │   ├── dashboard/
│   │   ├── events/
│   │   └── admin/
│   │
│   ├── components/
│   │   ├── attendance/
│   │   ├── dashboard/
│   │   ├── forms/
│   │   ├── layout/
│   │   ├── navigation/
│   │   ├── ui/
│   │   └── shared/
│   │
│   ├── services/
│   │   ├── attendance/
│   │   ├── analytics/
│   │   ├── dashboard/
│   │   ├── email/
│   │   ├── events/
│   │   ├── qr/
│   │   └── security/
│   │
│   ├── repositories/
│   │   ├── attendance/
│   │   ├── events/
│   │   └── shared/
│   │
│   ├── workflows/
│   │   ├── attendance/
│   │   ├── analytics/
│   │   ├── notifications/
│   │   └── maintenance/
│   │
│   ├── sanity/
│   │   ├── schemas/
│   │   ├── queries/
│   │   ├── mutations/
│   │   └── client/
│   │
│   ├── lib/
│   │   ├── auth/
│   │   ├── cache/
│   │   ├── config/
│   │   ├── logging/
│   │   ├── redis/
│   │   ├── security/
│   │   ├── telemetry/
│   │   └── validation/
│   │
│   ├── emails/
│   │
│   ├── hooks/
│   │
│   ├── providers/
│   │
│   ├── middleware/
│   │
│   ├── types/
│   │
│   ├── utils/
│   │
│   ├── constants/
│   │
│   └── tests/
│       ├── unit/
│       ├── integration/
│       ├── e2e/
│       └── fixtures/
│
├── .env.example
├── .gitignore
├── components.json
├── eslint.config.mjs
├── middleware.ts
├── next.config.ts
├── package.json
├── postcss.config.mjs
├── README.md
├── tailwind.config.ts
└── tsconfig.json
```

---

# Repository Organization Philosophy

The repository deliberately separates responsibilities into distinct layers.

| Layer           | Responsibility                                   |
| --------------- | ------------------------------------------------ |
| `app/`          | Routing, layouts, Server Components, and pages   |
| `actions/`      | Server Actions that express application commands |
| `components/`   | Reusable UI components                           |
| `services/`     | Business rules and application services          |
| `repositories/` | Data access and persistence                      |
| `workflows/`    | Durable orchestration with Inngest               |
| `sanity/`       | Content schemas, queries, and mutations          |
| `lib/`          | Shared infrastructure and integrations           |
| `emails/`       | Transactional email templates                    |
| `hooks/`        | Client-side React hooks                          |
| `providers/`    | Context providers                                |
| `middleware/`   | Request pipeline extensions                      |
| `types/`        | Shared TypeScript models                         |
| `utils/`        | Pure utility functions                           |
| `tests/`        | Unit, integration, and end-to-end testing        |

Each directory has a clearly defined purpose and avoids overlapping responsibilities.

---

# Architectural Dependency Flow

The application follows a unidirectional dependency model.

```text
Browser
    │
    ▼
Server Components
    │
    ▼
Server Actions
    │
    ▼
Application Services
    │
    ▼
Repositories
    │
    ▼
Sanity
```

Workflows operate alongside this path rather than inside it.

```text
Server Action
      │
      ▼
attendance/checkin.requested
      │
      ▼
Inngest Workflow
      │
      ├────────► Attendance Repository
      ├────────► Email Service
      ├────────► Analytics Service
      └────────► Dashboard Service
```

This separation ensures that long-running operations never block user interactions.

---

# Directory Responsibilities

## `app/`

Contains the Next.js App Router implementation, including route groups, layouts, pages, loading states, and error boundaries.

This layer focuses exclusively on presentation and request orchestration.

---

## `actions/`

Contains Server Actions.

Each action represents a business command such as requesting an attendance check-in.

Server Actions authenticate, authorize, validate, and publish workflow events. They do not implement business logic or persistence directly.

---

## `services/`

Implements application and domain logic.

Examples include attendance validation, event policies, dashboard aggregation, and notification orchestration.

Services remain independent of user interface concerns.

---

## `repositories/`

Encapsulates persistence operations.

Repositories expose a clean API for reading and writing data while hiding Sanity-specific implementation details.

This allows business logic to remain storage-agnostic.

---

## `workflows/`

Contains Inngest functions responsible for durable execution.

Each workflow coordinates multiple services while ensuring retries, idempotency, and reliable completion.

---

## `sanity/`

Defines content schemas, reusable queries, mutations, and client configuration.

The rest of the application interacts with Sanity through repositories rather than directly.

---

## `lib/`

Contains shared infrastructure components.

Examples include:

* Clerk integration
* Redis client
* Logging
* Configuration
* Security helpers
* Validation
* Telemetry

These modules are intentionally framework-independent wherever possible.

---

# Development Workflow

The repository supports a modern engineering workflow.

```text
Feature Branch
      │
      ▼
Pull Request
      │
      ▼
Lint
      │
      ▼
Type Check
      │
      ▼
Unit Tests
      │
      ▼
Integration Tests
      │
      ▼
Preview Deployment
      │
      ▼
Production
```

Every change passes through automated quality gates before reaching production.

---

# Why This Structure?

As applications grow, technical debt often begins with repository organization.

This structure aims to prevent common problems such as:

* business logic embedded in page components
* direct database access from UI code
* duplicated validation logic
* tightly coupled infrastructure
* difficult-to-test services

By establishing clear architectural boundaries from the outset, the application remains easier to understand, maintain, and extend over time.

---

# Appendix Roadmap

The remaining appendices build upon this foundation.

| Appendix   | Focus                               |
| ---------- | ----------------------------------- |
| Appendix C | Project Bootstrap and Configuration |
| Appendix D | Shared Infrastructure (`lib/`)      |
| Appendix E | Sanity Schemas and Content Model    |
| Appendix F | Authentication and Middleware       |
| Appendix G | Event Pages and Routing             |
| Appendix H | Server Actions                      |
| Appendix I | Application Services                |
| Appendix J | Repository Layer                    |
| Appendix K | Inngest Workflows                   |
| Appendix L | UI Components                       |
| Appendix M | Dashboard and Analytics             |
| Appendix N | Email Templates                     |
| Appendix O | Offline-First Support               |
| Appendix P | Testing Strategy                    |
| Appendix Q | Deployment and CI/CD                |
| Appendix R | Observability and Operations        |

Each appendix includes complete source code for its respective layer, providing a comprehensive reference implementation that complements the architectural discussions presented throughout the book.
