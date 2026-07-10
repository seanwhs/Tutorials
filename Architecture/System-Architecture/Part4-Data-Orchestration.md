# Part 4: Data Orchestration

## 1. Schemas That Evolve: The Real Cost of Data

Code can be refactored in an afternoon. A production database with millions of rows cannot be casually "refactored" — every schema change is a migration that must run against live data, often while the system stays online. This asymmetry is why data architecture deserves its own dedicated thinking, separate from application architecture.

**Core principle:** design schemas around **what varies together**, mirroring the bounded contexts from Part 2. A schema change to Catalog's `products` table should never require a coordinated migration of the Inventory or Ordering tables in the same deploy. If it does, your data boundaries don't match your bounded contexts, and every future schema change becomes riskier and slower — a direct Cost of Change tax paid on every release, forever, until you fix the boundary.

## 2. Database-per-Service vs. Shared Database

| Approach | Pros | Cons | When to use |
|---|---|---|---|
| **Shared database** | Simple joins, one transaction spans everything, easy to reason about consistency | Any schema change risks breaking unrelated code; tight coupling defeats bounded contexts; scales poorly across teams | Early-stage / single team / Modular Monolith |
| **Database-per-service** | Each context evolves its schema independently; failure isolation; can pick different storage tech per context | No cross-context SQL joins; must handle eventual consistency; more operational surface area | Multiple teams, proven scale needs, or contexts with very different data shapes/read patterns |

**The architect's answer is rarely binary.** In a **Modular Monolith** (which is what we build for Northwind Orders through Part 8), the pragmatic middle ground is: **one physical database, but logically partitioned schemas with a hard rule — no cross-schema foreign keys, no cross-schema joins in application code.** Each module's repository only ever queries its own tables. This gets you 90% of the benefit of database-per-service (real decoupling, easy to later carve out a service) while deferring 100% of the operational cost (running N databases) until you've actually proven you need to scale a context independently.

```sql
-- schemas are logically separated even though physically colocated
CREATE TABLE ordering.orders (
  id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE ordering.order_line_items (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL REFERENCES ordering.orders(id),
  sku TEXT NOT NULL,           -- reference by value, NOT a foreign key into catalog schema
  quantity INTEGER NOT NULL,
  price_cents INTEGER NOT NULL
);

CREATE TABLE inventory.stock_items (
  sku TEXT PRIMARY KEY,        -- no FK relationship to ordering schema
  quantity_on_hand INTEGER NOT NULL,
  reorder_threshold INTEGER NOT NULL
);
```

Notice `order_line_items.sku` is *not* a foreign key into `inventory.stock_items`. This is deliberate — a hard FK constraint across bounded contexts recreates the exact coupling DDD tells us to avoid. If Inventory needs to change its primary key strategy tomorrow, Ordering must not break.

## 3. The Dual-Write Problem

Here's the failure mode that makes naive event-driven architectures unreliable: an order is placed, the code writes the order row, *then* tries to publish an `OrderPaid` event to a message queue. If the process crashes between those two steps (network blip, server restart, OOM kill), the database says "paid" but no downstream service (Notifications, Inventory) ever hears about it. This is the **dual-write problem** — writing to two different systems (DB + queue) is not atomic.

## 4. The Outbox Pattern

The Outbox pattern solves this by writing the event to the **same database, same transaction** as the business data change. A separate relay process then reads unpublished outbox rows and publishes them, retrying until success, and marks them published only after confirmed delivery.

```sql
CREATE TABLE ordering.outbox_events (
  id TEXT PRIMARY KEY,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  occurred_at TIMESTAMP NOT NULL DEFAULT now(),
  published_at TIMESTAMP NULL       -- NULL = not yet relayed
);
```

```ts
// infrastructure/persistence/SqlOrderRepository.ts
import { Order } from "@/core/ordering/domain/entities/Order";
import { OrderRepository } from "@/core/ordering/application/ports/OrderRepository";
import { db } from "./db"; // fake in-memory/SQLite db client

export class SqlOrderRepository implements OrderRepository {
  async findById(id: string): Promise<Order | null> {
    return db.orders.findById(id);
  }

  // The critical method: save the order AND the outbox event
  // in a single atomic transaction.
  async saveWithEvent(order: Order, eventType: string, payload: unknown): Promise<void> {
    await db.transaction(async (tx) => {
      await tx.orders.upsert(order);
      await tx.outboxEvents.insert({
        id: crypto.randomUUID(),
        eventType,
        payload,
        occurredAt: new Date(),
        publishedAt: null,
      });
    });
    // If this line is reached, both writes succeeded together, or neither did.
  }

  async save(order: Order): Promise<void> {
    await db.orders.upsert(order);
  }
}
```

```ts
// infrastructure/events/OutboxRelay.ts
// Runs on an interval (cron, or a background task). Free/OSS-friendly:
// no message broker required for the PoC — this could later point at
// Kafka, RabbitMQ, or SQS without changing any core/ code.
import { db } from "../persistence/db";
import { ConsoleEventPublisher } from "./ConsoleEventPublisher";

const publisher = new ConsoleEventPublisher();

export async function relayOutboxEvents(): Promise<void> {
  const pending = await db.outboxEvents.findUnpublished();

  for (const event of pending) {
    try {
      await publisher.publish({
        type: event.eventType,
        payload: event.payload,
        occurredAt: event.occurredAt,
      });
      await db.outboxEvents.markPublished(event.id);
    } catch (err) {
      // Leave unpublished — will retry next tick.
      // Combined with Part 5's retry/backoff patterns for production hardening.
      console.error(`Failed to relay event ${event.id}, will retry`, err);
    }
  }
}
```

**Why this belongs in infrastructure, not core:** the Outbox table and relay are a *delivery mechanism* detail. The `PlaceOrderUseCase` from Part 3 doesn't know or care that events go through an Outbox table — it just calls `events.publish(...)` via the `EventPublisher` port. We can upgrade `ConsoleEventPublisher` to write-to-outbox-then-relay entirely inside infrastructure, with zero change to the use case. This is Part 3's Dependency Injection paying dividends again.

## 5. Schema Evolution: Additive by Default

**The single highest-leverage rule for evolving schemas safely:** prefer additive, backward-compatible changes over destructive ones, and roll out schema changes in phases separate from code deploys.

| Change type | Risk | Strategy |
|---|---|---|
| Add nullable column | Low | Deploy anytime, old code ignores it |
| Add table | Low | Deploy anytime |
| Rename column | High | Never rename directly — add new column, dual-write, backfill, migrate readers, drop old column (expand/contract pattern) |
| Change column type | High | Same expand/contract approach |
| Drop column | Medium | Only after confirming zero code paths (including old deployed versions) read it |

```
Expand/Contract migration example: renaming "customer_id" -> "buyer_id"

Phase 1 (Expand):   add buyer_id column, backfill from customer_id, write to both
Phase 2 (Migrate):  update all readers to use buyer_id
Phase 3 (Contract): stop writing customer_id, drop it after a safe monitoring window
```

This pattern is what allows a schema to evolve **without ever requiring a "big bang" migration that takes the system offline** — directly reducing the Cost of Change for data, the most expensive layer to change in any system.

## 6. Design Exercise

**Step 1:** Design the Inventory context's schema (`inventory.stock_items`, `inventory.reservations`) such that a stock reservation can be released automatically if a payment fails, without Inventory ever needing to call back into Ordering synchronously.

**Step 2:** Using the Outbox pattern, design the event flow for: order placed → stock reserved → payment attempted → on failure, stock reservation released. Which service owns the "release reservation" outbox event?

**Step 3:** Identify one schema change to `orders` that would be additive/safe, and one that would require the expand/contract pattern.

## 7. Solution & Discussion

**Step 1:** `inventory.reservations(id, sku, order_id, quantity, status, expires_at)` — Inventory owns reservation lifecycle independently. It never queries Ordering's tables; it only reacts to events (`OrderPlaced` → create reservation, `PaymentFailed` → release reservation, `OrderPaid` → convert reservation to permanent stock deduction).

**Step 2:** Ordering owns and emits `OrderPlaced` and `PaymentFailed` via its own outbox. Inventory subscribes to both and manages the reservation state machine on *its* side, writing to *its own* outbox if it needs to notify anyone further downstream (e.g., a "low stock" alert). Notice neither context ever makes a synchronous call into the other's write path — everything is event-driven, which means a slow or down Payments provider (Part 5 territory) never blocks Inventory from staying responsive.

**Step 3:** Adding a nullable `shipping_notes TEXT` column is safe and additive. Renaming `customer_id` to `buyer_id` requires the full expand/contract sequence — attempting it directly in one migration risks breaking any in-flight requests hitting old application code during a rolling deploy.

## Up Next

**Part 5 (Resilience & Scalability)** addresses what happens when the Payments Gateway from Part 3, or the Outbox relay's downstream consumer, is slow or unavailable — retries, circuit breakers, caching, and graceful degradation, deployed on Next.js's Edge runtime.

---

Want Part 5 next?
