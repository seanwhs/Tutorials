# Appendix A17 — Next.js 16 System Design Patterns & Architectural Patterns Cheat Sheet

## The Complete Guide to Recognizing and Applying Software Architecture Patterns in Real Applications

> **Purpose:** This appendix is the definitive reference for system design and architectural patterns used when building real-world Next.js 16 applications. Most professional engineers do not invent architectures. They recognize patterns and apply them appropriately.

---

# Introduction

The biggest misconception beginners have is:

```text
Architecture
=
Technology choices.
```

Professional engineers understand:

```text
Architecture
=
Organizing complexity.
```

Because every sufficiently successful application eventually becomes:

```text
Complex

Distributed

Stateful

Failure-prone
```

And architectural patterns exist to help humans manage that complexity.

---

# The Pattern Hierarchy

```text
Programming Patterns

        |

Application Patterns

        |

Architectural Patterns

        |

Distributed System Patterns
```

---

# The Golden Rule

Never ask:

```text
Which pattern
is best?
```

Ask:

```text
Which problem
does this
pattern solve?
```

---

# Pattern 1 — Layered Architecture

Most common architecture.

```text
UI Layer
    |
Application Layer
    |
Domain Layer
    |
Data Layer
```

---

# Example

```text
app/
    |
services/
    |
domain/
    |
repositories/
```

---

# Benefits

```text
✓ Simple

✓ Familiar

✓ Maintainable
```

---

# Costs

```text
✗ Tight coupling

✗ Layer leakage
```

---

# Pattern 2 — Feature-Based Architecture

Organize by feature.

---

Bad:

```text
components/

hooks/

types/

utils/
```

---

Better:

```text
features/

    posts/

    auth/

    comments/
```

---

Example:

```text
features/

    posts/

        components/

        actions/

        schemas/

        hooks/

        tests/
```

---

# Benefits

```text
✓ Cohesion

✓ Ownership

✓ Scalability
```

---

# Pattern 3 — Modular Monolith

Modern default architecture.

---

Visualizing:

```text
Application

    |

+---------+
| Auth    |
+---------+

+---------+
| Posts   |
+---------+

+---------+
| Billing |
+---------+
```

---

# Benefits

```text
✓ Simple deployment

✓ Strong boundaries

✓ Low cost
```

---

# Costs

```text
✗ Shared failures
```

---

# Pattern 4 — Microservices

Visualizing:

```text
Auth Service

Posts Service

Billing Service
```

---

Benefits:

```text
✓ Independent scaling

✓ Independent deployment
```

---

Costs:

```text
✗ Complexity

✗ Operations

✗ Networking
```

---

# Professional Advice

Start with:

```text
Modular Monolith
```

Move to:

```text
Microservices
```

Only when forced.

---

# Pattern 5 — Backend For Frontend (BFF)

Visualizing:

```text
Browser
    |
Next.js
    |
APIs
```

---

Next.js often acts as:

```text
BFF
```

---

Example:

```text
Browser

    |

Server Actions

    |

Backend Services
```

---

# Benefits

```text
✓ Hide APIs

✓ Aggregate data

✓ Improve security
```

---

# Pattern 6 — Repository Pattern

Purpose:

```text
Separate
business logic
from storage.
```

---

Example:

```ts
interface
PostRepository {

  findAll();

  findById();

  save();

}
```

---

Implementation:

```ts
class
PostgresRepository
implements
PostRepository {

}
```

---

Benefits:

```text
✓ Testable

✓ Flexible
```

---

# Pattern 7 — Service Layer

Visualizing:

```text
Route
   |
Service
   |
Repository
```

---

Example:

```ts
export class
PostService {

  async publish() {

  }

}
```

---

Purpose:

```text
Business rules.
```

---

# Pattern 8 — Domain Model

Instead of:

```ts
user.isAdmin
```

---

Use:

```ts
user.canPublish()
```

---

Benefits:

```text
Behavior
near data.
```

---

# Pattern 9 — CQRS

Command Query Responsibility Segregation.

---

Split:

```text
Writes

and

Reads
```

---

Example:

```text
POST
    |
Database
```

---

```text
GET
    |
Cache
```

---

Benefits:

```text
✓ Performance

✓ Scalability
```

---

Costs:

```text
✗ Complexity
```

---

# Pattern 10 — Event Sourcing

Store:

```text
Events
```

Instead of:

```text
Current state
```

---

Example:

```text
UserCreated

UserUpdated

UserDeleted
```

---

Benefits:

```text
✓ Audit trail

✓ History
```

---

Costs:

```text
✗ Complexity
```

---

# Pattern 11 — Event-Driven Architecture

Visualizing:

```text
Publisher
      |
      Event
      |
Subscriber
```

---

Example:

```text
OrderPlaced
```

Triggers:

```text
Email

Analytics

Billing
```

---

# Pattern 12 — Pub/Sub

Example:

```text
Publisher
     |
Redis
     |
Subscribers
```

---

Benefits:

```text
Loose coupling.
```

---

# Pattern 13 — Queue Pattern

Visualizing:

```text
Request
    |
Queue
    |
Worker
```

---

Examples:

```text
Emails

AI jobs

Reports
```

---

# Pattern 14 — Worker Pattern

Example:

```text
Web Server

      |

Job Queue

      |

Workers
```

---

Benefits:

```text
Background processing.
```

---

# Pattern 15 — Cache Aside

Visualizing:

```text
Cache
  |
Miss
  |
Database
```

---

Example:

```ts
let user =
  cache.get(id);

if (!user) {

}
```

---

Benefits:

```text
✓ Fast

✓ Simple
```

---

# Pattern 16 — Write Through Cache

Visualizing:

```text
Write
   |
Database
   |
Cache
```

---

Benefits:

```text
Fresh cache.
```

---

# Pattern 17 — Circuit Breaker

Purpose:

```text
Prevent
cascade failure.
```

---

Visualizing:

```text
Service A
    |
FAIL
    |
OPEN
```

---

States:

```text
Closed

Open

Half-open
```

---

# Pattern 18 — Retry Pattern

Example:

```ts
for (
  let i=0;
  i<3;
  i++
) {

}
```

---

Use for:

```text
Temporary failures.
```

---

# Pattern 19 — Bulkhead Pattern

Visualizing:

```text
Service

  |

+-----+
| A |
+-----+

+-----+
| B |
+-----+
```

---

Purpose:

```text
Isolate failures.
```

---

# Pattern 20 — Saga Pattern

Distributed transaction.

---

Example:

```text
Payment
    |
Inventory
    |
Shipping
```

---

Rollback:

```text
Refund
```

---

# Pattern 21 — API Gateway

Visualizing:

```text
Clients
     |
Gateway
     |
Services
```

---

Benefits:

```text
Authentication

Routing

Caching
```

---

# Pattern 22 — Adapter Pattern

Example:

```ts
interface
Storage {

}
```

---

Adapters:

```text
S3

Cloudflare

Local
```

---

# Pattern 23 — Facade Pattern

Hide complexity.

---

Example:

```ts
Auth.login()
```

Instead of:

```text
JWT

Cookies

Sessions

Permissions
```

---

# Pattern 24 — Strategy Pattern

Example:

```ts
PaymentStrategy
```

Implementations:

```text
Stripe

PayPal

Bank
```

---

# Pattern 25 — Factory Pattern

Example:

```ts
createDatabase()
```

Returns:

```text
Postgres

MySQL

SQLite
```

---

# Pattern 26 — Observer Pattern

Visualizing:

```text
Subject
   |
Observers
```

---

Example:

```text
Notifications

Events

Subscriptions
```

---

# Pattern 27 — Dependency Injection

Bad:

```ts
const db =
  new Database();
```

---

Good:

```ts
constructor(
  db
)
```

---

Benefits:

```text
✓ Testing

✓ Decoupling
```

---

# Pattern 28 — Hexagonal Architecture

Visualizing:

```text
UI
 |
Ports
 |
Domain
 |
Adapters
```

---

Benefits:

```text
Business logic
independence.
```

---

# Pattern 29 — Clean Architecture

Visualizing:

```text
Frameworks
     |
Adapters
     |
Use Cases
     |
Entities
```

---

Rule:

```text
Dependencies
point inward.
```

---

# Pattern 30 — Server Component Architecture

Next.js 16 pattern:

```text
Browser
     |
Server Component
     |
Database
```

---

Benefits:

```text
Less JS

Better SEO

Better performance
```

---

# Pattern 31 — Cache Component Architecture

Visualizing:

```text
Request
    |
Cache
    |
Server
```

---

Components:

```text
cacheLife()

cacheTag()

revalidateTag()
```

---

# Pattern 32 — Streaming Architecture

Visualizing:

```text
Request
    |
Header
    |
Sidebar
    |
Content
```

---

Benefits:

```text
Faster perception.
```

---

# Pattern 33 — Partial Prerendering

Visualizing:

```text
Static Shell

     +

Dynamic Islands
```

---

Benefits:

```text
Best of both worlds.
```

---

# Pattern Selection Matrix

| Problem           | Pattern          |
| ----------------- | ---------------- |
| Organization      | Modular Monolith |
| Scalability       | CQRS             |
| Background Jobs   | Queue            |
| External Services | Adapter          |
| Caching           | Cache Aside      |
| Distributed Work  | Event Driven     |
| Isolation         | Bulkhead         |
| Transactions      | Saga             |
| API Aggregation   | BFF              |

---

# Common Beginner Mistakes

---

## Mistake 1

Using microservices first.

---

## Mistake 2

Using CQRS everywhere.

---

## Mistake 3

Using event sourcing unnecessarily.

---

## Mistake 4

Ignoring modular boundaries.

---

## Mistake 5

Copying FAANG architectures.

---

## Mistake 6

Optimizing for scale before users exist.

---

## Mistake 7

Confusing patterns with solutions.

---

# Architecture Evolution Path

Most applications evolve:

```text
CRUD App
    |
Layered
    |
Feature-based
    |
Modular Monolith
    |
Event-driven
    |
Distributed System
```

---

# The Complete Architecture Mental Model

```text
Requirements
       |
Constraints
       |
Patterns
       |
Tradeoffs
       |
Architecture
       |
Operations
```

---

# Mental Model

Beginners think:

```text
Architecture
=
Technology.
```

Professional engineers think:

```text
Architecture
=
Managing complexity
through
recognizable patterns.
```

Because almost every software problem has already been solved before.

The difficult part is recognizing which solution creates the fewest new problems.
