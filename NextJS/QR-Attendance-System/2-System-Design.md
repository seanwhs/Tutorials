# Production Patterns with Next.js 16

## Reference Architecture #1

# Part 2

# Bootstrapping the Foundation

## Building the Project Infrastructure for a Production-Ready Attendance Platform

> **Good architectures don't emerge from code. They emerge from clear boundaries between responsibilities.**

---

# Executive Summary

In Part 1, we designed the architecture for a production-ready attendance platform.

Before we implement individual features, we need to establish the project's foundation.

This article focuses on the **structural decisions** that make the application maintainable as it grows.

We'll define:

* project structure
* architectural boundaries
* shared services
* environment configuration
* authentication strategy
* routing
* infrastructure integration

By the end of this article, we'll have a clean foundation ready for implementing workflows in the rest of the series.

---

# Why Start with Structure?

One of the most common mistakes in application development is allowing the framework to dictate the architecture.

A small prototype often begins like this:

```text
app/
    page.tsx
    events/
    api/
```

As features accumulate, business logic spreads across pages, API routes, helper files, and components. The result is tight coupling, duplicated logic, and increasing maintenance costs.

Instead, we start by organizing the project around **responsibilities**, not framework folders.

---

# System Boundaries

Before creating directories, identify the major responsibilities within the application.

```text
                    Presentation
                         │
                         ▼
                  Application Layer
                         │
                         ▼
                  Domain Services
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
     Authentication   Persistence   Workflows
          │              │              │
          ▼              ▼              ▼
        Clerk         Sanity        Inngest
```

Each layer has a single responsibility, making the system easier to reason about and evolve.

---

# Organizing the Project

A practical folder structure might look like this:

```text
src/
├── app/
│   ├── (marketing)/
│   ├── (dashboard)/
│   ├── events/
│   ├── api/
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
│   └── users/
│
├── repositories/
│   └── sanity/
│
├── workflows/
│   └── attendance/
│
├── lib/
│
├── types/
│
└── utils/
```

Notice that the project is organized by **business capability** rather than by technical layer alone.

---

# Why Separate Services from Repositories?

One of the easiest architectural mistakes is allowing application code to communicate directly with the database.

Instead of:

```text
Page

↓

Sanity Client
```

introduce a service layer:

```text
Page

↓

Server Action

↓

Attendance Service

↓

Attendance Repository

↓

Sanity
```

This separation provides several benefits:

* business rules live in one place
* repositories focus on persistence
* services remain testable
* storage technology can evolve independently

---

# Environment Configuration

A production system depends on external services.

Typical environment variables include:

* Clerk publishable key
* Clerk secret key
* Sanity project ID
* Sanity dataset
* Sanity API token
* Inngest signing key
* Resend API key
* Upstash Redis URL
* Upstash Redis token

Avoid scattering access to these variables throughout the codebase. Instead, centralize configuration behind a typed configuration module.

---

# Shared Infrastructure

Rather than instantiating SDK clients in multiple files, create dedicated modules:

* `lib/clerk.ts`
* `lib/sanity.ts`
* `lib/inngest.ts`
* `lib/resend.ts`
* `lib/redis.ts`

Each module exports a configured client that can be reused across the application.

This reduces duplication and simplifies future changes.

---

# Authentication Strategy

Authentication is handled by Clerk.

However, authentication and authorization are different concerns.

Authentication answers:

> Who is this user?

Authorization answers:

> Is this user allowed to perform this action?

We'll enforce authentication at the route level using Clerk middleware, and we'll perform authorization again inside every Server Action. Defense in depth ensures that even if a request bypasses the UI, business rules remain protected.

---

# Routing Strategy

Each event exposes a predictable entry point:

```text
/events/[slug]/checkin
```

The slug keeps URLs human-readable while allowing the server to resolve the corresponding event document.

All validation occurs on the server after the route is resolved.

---

# Dependency Flow

To avoid circular dependencies, establish a clear direction of communication:

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
External Systems
```

Higher layers depend on lower layers.

Lower layers never depend on higher ones.

This keeps the architecture modular and testable.

---

# Observability from Day One

Every request should carry a correlation ID through the system.

```text
Browser
   │
Correlation ID
   │
Server Action
   │
Workflow
   │
Database
   │
Email
```

Including the same identifier in logs, workflow executions, and persistence records makes production troubleshooting significantly easier.

---

# Engineering Decision Record — Organizing by Capability

**Problem**

As applications grow, feature logic becomes scattered across pages, API routes, and helper files.

**Decision**

Organize the project around business capabilities (attendance, events, users) rather than framework primitives.

**Benefits**

* clearer ownership
* easier testing
* improved maintainability
* scalable architecture

**Trade-offs**

Requires slightly more upfront planning but pays dividends as the codebase evolves.

---

# Looking Ahead

With the project structure and architectural boundaries in place, we're ready to model the domain itself.

In the next article, we'll design the Sanity schemas for:

* Events
* Attendance Records
* QR Configuration
* Check-in Windows
* Audit Metadata
* Idempotency Keys

By modeling the domain before writing workflow logic, we ensure that the rest of the implementation builds on a solid, extensible foundation.
