# Appendix G

# Persistence Architecture

> *"Persistence is more than storing data. It is the discipline of preserving business state while maintaining integrity, consistency, performance, and auditability under real-world conditions."*

---

# Purpose

The persistence layer translates business concepts into durable storage.

It shields the remainder of the application from database-specific implementation details and provides a consistent interface for querying, creating, and updating domain objects.

Within the reference implementation, persistence is intentionally isolated behind repositories. No other layer communicates directly with Sanity or its APIs.

---

# Design Goals

The persistence layer has six primary objectives:

* Preserve domain integrity.
* Hide storage implementation details.
* Support transactional updates.
* Optimize read performance.
* Enable future migration.
* Provide auditability.

Repositories should express business intent rather than storage mechanics.

---

# Architectural Position

```text
Presentation
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
Persistence Infrastructure
      │
      ▼
Sanity Content Lake
```

Only repositories communicate directly with the persistence infrastructure.

---

# Why Sanity?

The reference implementation uses **Sanity Content Lake** as both a content platform and operational document store.

This choice reflects several architectural advantages:

* Flexible document schemas
* GROQ query language
* Global CDN
* Real-time content capabilities
* Schema evolution
* Strong developer tooling

The persistence layer is designed so that these capabilities remain implementation details rather than business dependencies.

---

# Repository Pattern

Repositories encapsulate all persistence logic.

Typical responsibilities include:

* Entity retrieval
* Entity creation
* Updates
* Transactions
* Query composition
* Mapping between storage documents and domain models

Repositories do **not** contain business rules.

---

# Repository Catalogue

The reference implementation defines a repository for each aggregate root and major entity.

| Repository             | Responsibility     |
| ---------------------- | ------------------ |
| OrganizationRepository | Organizations      |
| VenueRepository        | Venues             |
| EventRepository        | Events             |
| SessionRepository      | Sessions           |
| AttendanceRepository   | Attendance records |
| UserProfileRepository  | User profiles      |

Each repository owns its respective persistence concerns.

---

# Read and Write Separation

Although the implementation uses a single persistence technology, read and write operations are treated differently.

Read operations prioritize:

* Cache efficiency
* Projection
* Pagination
* Filtering

Write operations prioritize:

* Consistency
* Validation
* Idempotency
* Auditability

This separation reduces contention and improves scalability.

---

# Aggregate Persistence

Aggregate roots define persistence boundaries.

For example:

```text
Organization
    │
    ├── Venue
    └── Event
             │
             └── Session

AttendanceRecord
```

Attendance records remain independent documents referencing the corresponding event rather than being embedded.

This avoids large document growth and enables efficient reporting.

---

# Document Relationships

Relationships are maintained through references rather than duplication.

```text
AttendanceRecord

 ├── Event
 ├── Session
 ├── User
 └── Organization
```

This model preserves normalization while allowing rich projections through GROQ.

---

# Query Strategy

The persistence layer favors explicit query definitions.

Categories include:

* Single entity retrieval
* Collection queries
* Dashboard projections
* Search
* Reporting
* Analytics

Queries remain reusable and independently testable.

---

# Transactions

Attendance creation is treated as a transactional operation.

A successful transaction should guarantee:

* Attendance record created.
* Duplicate prevention enforced.
* Audit metadata recorded.

Downstream notifications remain asynchronous and occur outside the transaction.

---

# Idempotency

Duplicate attendance requests are expected rather than exceptional.

Repositories therefore support idempotent operations.

Typical implementation strategies include:

* Unique document identifiers.
* Composite business keys.
* Existence checks.
* Conditional transactions.

Idempotency ensures retries never produce duplicate attendance records.

---

> **Production Tip — Design for Retries**
>
> Durable workflows retry failed operations by design. Every persistence operation should therefore be safe to execute multiple times. If a repeated request changes the final outcome, the operation is not idempotent and should be redesigned.

---

# Query Optimization

Performance considerations include:

* Field projection.
* Pagination.
* Cursor-based navigation.
* Avoiding over-fetching.
* Selective indexing.
* Cached immutable queries.

Optimizations are applied only after correctness has been established.

---

# Consistency Model

The application balances two forms of consistency.

| Data                 | Consistency |
| -------------------- | ----------- |
| Attendance           | Strong      |
| Event Metadata       | Eventual    |
| Dashboard Statistics | Eventual    |
| Analytics            | Eventual    |

This distinction allows user-facing operations to remain responsive while analytics and reporting continue asynchronously.

---

# Auditability

Every persisted attendance record includes sufficient metadata to support operational analysis.

Typical audit information includes:

* Creation timestamp
* User identifier
* Event identifier
* Check-in method
* Correlation identifier
* Workflow identifier
* Client metadata

Audit trails are append-only.

---

# Evolution

The persistence layer is designed for change.

Future enhancements may include:

* Alternative persistence technologies
* Read replicas
* Materialized reporting views
* Event sourcing
* Polyglot persistence

Because repositories isolate storage concerns, these changes remain localized.

---

# Reference Implementation

The implementation chapters associated with this appendix include:

* Repository interfaces
* Sanity document mappings
* GROQ query catalogue
* Transaction helpers
* Pagination utilities
* Repository tests

These artifacts collectively form the persistence subsystem used throughout the application.

---

# Looking Ahead

With durable persistence established, the next appendix introduces the application layer.

The focus shifts from storing business state to enforcing business rules, coordinating repositories, and orchestrating the processes that transform user requests into meaningful outcomes.
