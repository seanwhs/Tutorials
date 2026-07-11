# Appendix F

# Infrastructure Foundation

> *"Every resilient application stands on a foundation of infrastructure that remains largely invisible to its users. Configuration, logging, security, caching, and integration clients rarely receive attention in feature discussions, yet they determine how reliably the system behaves under production conditions."*

---

# Purpose

The previous appendices established the repository structure, engineering standards, and business domain.

This appendix introduces the infrastructure layer—the collection of cross-cutting capabilities that every feature relies upon but no feature should implement for itself.

Infrastructure provides the technical foundation that allows business logic to remain focused on solving business problems.

---

# Responsibilities

The infrastructure layer is responsible for:

* Configuration management
* Environment validation
* Logging
* Error handling
* External service clients
* Date and time utilities
* Identifier generation
* Caching
* Feature flags
* Security helpers
* Shared constants

It deliberately contains **no business rules**.

---

# Architectural Position

```text
                     Business Layer
                           ▲
                           │
                    Service Layer
                           ▲
                           │
                  Repository Layer
                           ▲
                           │
                Infrastructure Layer
                           ▲
                           │
                External Platforms
```

Infrastructure supports every layer above it while remaining independent of business concepts.

---

# Infrastructure Package

```text
src/infrastructure/

config/
logging/
security/
cache/
events/
clients/
observability/
utilities/
constants/
types/
```

Each package has a narrowly defined responsibility.

---

# Configuration

Configuration is validated once during application startup.

Key principles include:

* Strong typing
* Fail-fast validation
* Environment isolation
* Immutable configuration
* No direct `process.env` access outside the configuration package

The exported configuration object becomes the single source of truth for runtime settings.

---

# External Clients

Infrastructure owns all communication with external platforms.

Examples include:

* Clerk
* Sanity
* Inngest
* Upstash Redis
* Resend

No other layer creates SDK clients directly.

This centralization simplifies upgrades, testing, and dependency management.

---

# Logging

Logging is structured rather than free-form.

Every log entry includes contextual metadata such as:

* Correlation ID
* Request ID
* Event ID
* User ID
* Workflow ID
* Duration
* Severity

This enables efficient troubleshooting across distributed workflows.

---

# Error Classification

Infrastructure defines a common error taxonomy.

| Category       | Example                      |
| -------------- | ---------------------------- |
| Configuration  | Missing environment variable |
| Validation     | Invalid payload              |
| Authentication | Missing session              |
| Authorization  | Insufficient permissions     |
| Infrastructure | External API unavailable     |
| Workflow       | Retry exhausted              |

Shared error types provide consistent handling across the application.

---

# Time

All timestamps are stored in UTC.

Localization occurs only when rendering user interfaces.

This avoids ambiguity during reporting and simplifies cross-region deployments.

---

# Identifiers

The application distinguishes between several identifier types.

* Organization ID
* Event ID
* Session ID
* Attendance ID
* Workflow ID
* Correlation ID

Identifiers are immutable and remain stable throughout the lifecycle of an entity.

---

# Caching

Caching is treated as an optimization rather than a source of truth.

Typical cache candidates include:

* Event metadata
* Venue information
* Organization settings

Attendance records and workflow state remain strongly consistent.

---

# Feature Flags

Infrastructure provides centralized feature flag evaluation.

Typical flags include:

* Offline support
* Geofencing
* Email notifications
* Live dashboard updates

Business logic queries capabilities rather than reading environment variables directly.

---

# Security Helpers

Common security functionality includes:

* Request signing
* QR payload verification
* Secret management
* Rate limiting helpers
* Cryptographic utilities

Security remains a shared capability rather than duplicated logic.

---

# Observability

Infrastructure exposes telemetry consumed by operational tooling.

Capabilities include:

* Structured logs
* Metrics
* Distributed traces
* Health checks
* Performance counters

Observability is considered a first-class engineering concern.

---

# Why This Layer Matters

Without a dedicated infrastructure layer, business logic quickly becomes entangled with framework code and third-party SDKs.

By isolating infrastructure, the remainder of the application remains easier to test, easier to maintain, and easier to evolve as technology choices change.

---

# Looking Ahead

With the technical foundation established, the next appendix introduces the persistence layer.

The focus shifts from infrastructure concerns to how domain entities are mapped, queried, and stored, while preserving the architectural boundaries established throughout this reference implementation.
