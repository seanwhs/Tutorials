# Appendix D

# Shared Infrastructure (`lib/`)

> *"Infrastructure should enable the application, not define it. Every integration with an external service belongs behind a clean abstraction so that the rest of the application remains focused on business logic."*

---

# Purpose

The `lib/` directory contains shared infrastructure modules that are used throughout the application.

These modules are intentionally lightweight, reusable, and framework-aware where necessary, while hiding implementation details behind well-defined interfaces.

This appendix covers:

* Configuration management
* Logging
* Authentication helpers
* Sanity client
* Inngest client
* Redis client
* Resend email client
* Correlation IDs
* Validation utilities
* Common helper functions

Unlike business services, these modules are infrastructure building blocks and should contain no domain-specific business rules.

---

# Directory Structure

```text
src/lib/
│
├── auth/
│   ├── clerk.ts
│   ├── permissions.ts
│   └── session.ts
│
├── config/
│   ├── env.ts
│   └── index.ts
│
├── logging/
│   ├── logger.ts
│   ├── correlation.ts
│   └── request-log.ts
│
├── sanity/
│   ├── client.ts
│   ├── image.ts
│   └── groq.ts
│
├── inngest/
│   ├── client.ts
│   └── events.ts
│
├── redis/
│   ├── client.ts
│   └── ratelimit.ts
│
├── email/
│   └── resend.ts
│
├── telemetry/
│   └── tracing.ts
│
├── validation/
│   ├── attendance.ts
│   ├── event.ts
│   └── common.ts
│
├── ids.ts
├── dates.ts
└── constants.ts
```

---

# Dependency Relationships

```text
Server Components
        │
        ▼
Server Actions
        │
        ▼
───────────────────────────────
          src/lib
───────────────────────────────
 │       │        │        │
 ▼       ▼        ▼        ▼
Clerk  Sanity  Inngest  Redis
                    │
                    ▼
                 Resend
```

No application feature should instantiate external clients directly. Instead, all integrations are accessed through the modules defined in `lib/`.

---

# Configuration Management

Centralizing configuration prevents environment variables from being scattered throughout the codebase.

## `config/env.ts`

Responsibilities:

* Read environment variables
* Validate required configuration
* Provide strongly typed access
* Fail fast on startup if configuration is invalid

Typical configuration categories include:

* Clerk keys
* Sanity project information
* Inngest credentials
* Redis connection details
* Resend API key
* Application URLs
* Feature flags

All runtime configuration should originate from this module.

---

# Authentication Helpers

## `auth/clerk.ts`

This module wraps Clerk functionality and provides helper methods that are used consistently throughout the application.

Responsibilities include:

* Retrieve authenticated user
* Verify session state
* Extract user identifiers
* Normalize Clerk responses

Keeping Clerk-specific code isolated makes future upgrades or provider changes easier.

---

## `auth/permissions.ts`

Authorization rules belong here rather than inside page components or Server Actions.

Examples include:

* Can the user check in?
* Can the user manage an event?
* Can the user access the dashboard?
* Can the user perform administrative actions?

This separation keeps authorization policies consistent across the application.

---

# Logging

Production applications require structured logging rather than ad hoc `console.log()` statements.

## `logging/logger.ts`

Responsibilities:

* Structured log output
* Log levels
* Context propagation
* JSON formatting
* Error serialization

Each log entry should include:

* Timestamp
* Severity
* Correlation ID
* User ID (where available)
* Event ID (where available)
* Workflow ID (where applicable)

This allows operators to reconstruct the lifecycle of a request across multiple services.

---

## Correlation IDs

Every request entering the system should receive a unique correlation identifier.

```
Request

↓

Correlation ID Generated

↓

Server Action

↓

Workflow

↓

Repository

↓

Sanity

↓

Analytics

↓

Email
```

The same identifier appears in every log entry, enabling end-to-end traceability.

---

# Sanity Client

The Sanity client should be initialized exactly once.

Responsibilities include:

* API configuration
* Dataset selection
* Authentication
* GROQ query execution
* Mutations
* Image URL generation

Higher layers should interact with repositories rather than calling the client directly.

---

# Inngest Client

The Inngest client encapsulates all workflow communication.

Responsibilities include:

* Publish events
* Register functions
* Event naming
* Retry configuration
* Workflow metadata

Server Actions communicate with workflows exclusively through this client.

---

# Redis

Redis serves two primary purposes:

* Rate limiting
* Short-lived caching

Additional uses may include:

* Idempotency locks
* Temporary session data
* Dashboard counters

Redis should never become the system of record for attendance data.

---

# Email

The Resend client provides a single integration point for transactional email.

Responsibilities include:

* Template rendering
* Message dispatch
* Retry handling
* Delivery metadata

Email templates remain separate from transport logic.

---

# Validation

Validation logic is organized by business capability.

Examples include:

```
attendance.ts

event.ts

common.ts
```

These modules define reusable validation rules that can be shared across Server Actions, workflows, and services.

Duplicating validation logic should be avoided.

---

# Date Utilities

Time handling is surprisingly complex in distributed systems.

The date utility module centralizes:

* UTC conversion
* Time zone normalization
* Check-in window calculations
* Relative timestamps
* Formatting helpers

Using a single implementation avoids inconsistent date handling across the application.

---

# ID Generation

Several identifiers are generated during request processing:

* Correlation ID
* Workflow ID
* Idempotency key
* QR token
* Attendance reference

Centralizing these algorithms ensures consistent behavior and simplifies auditing.

---

# Constants

The constants module contains application-wide values such as:

* Event names
* Cache durations
* Rate limit thresholds
* Default pagination
* Header names
* Status values

Replacing magic strings with named constants improves readability and reduces maintenance effort.

---

# Design Principles

The `lib/` directory follows several important principles:

1. No business rules.
2. No page rendering.
3. No domain orchestration.
4. Infrastructure only.
5. Reusable across features.
6. Testable in isolation.

Following these principles keeps infrastructure independent of application logic.

---

# Typical Request Flow

The following diagram illustrates how infrastructure modules support a typical request.

```text
Browser
   │
   ▼
Middleware
   │
   ▼
Authentication
   │
   ▼
Configuration
   │
   ▼
Logging
   │
   ▼
Server Action
   │
   ▼
Workflow
   │
   ▼
Repositories
```

Each module contributes a specific capability without introducing unnecessary coupling.

---

# Testing Infrastructure

Infrastructure modules should be tested independently of business logic.

Examples include:

* Configuration validation
* Logger formatting
* Correlation ID generation
* Redis connectivity
* Sanity client initialization
* Event publishing
* Email transport

Isolating infrastructure tests helps identify integration issues before they affect higher-level workflows.

---

# Looking Ahead

With the shared infrastructure in place, we can begin modeling the application's core data structures.

The next appendix introduces the complete Sanity implementation, including document schemas, GROQ queries, mutations, client configuration, and repository integration that power the event management and attendance workflow.
