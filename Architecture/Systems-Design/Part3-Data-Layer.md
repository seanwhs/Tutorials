## Part 3: The Data Layer

### 1. Concept and Philosophy

The database is almost always the last thing to scale horizontally: application servers are stateless and disposable; a database node is neither. Every technique here answers: how do you keep data correct and available as write/data volume grows past a single machine, without sacrificing more consistency than the business can tolerate.

Escalation order a Staff Engineer follows: (1) vertical scale + query optimization, (2) read replicas, (3) caching (Part 2), (4) partitioning within one database, and only when exhausted, (5) sharding across instances — the most operationally expensive and hardest to undo.

### 2. Replication

Replication copies data from a primary to replica(s), solving availability (promote a replica if primary dies) and read scaling, but not write scaling (writes still go to primary).

- **Synchronous**: primary waits for replica ack before confirming. Strong consistency, but latency tax on every write, and reduced availability if replica is slow/down (PACELC).
- **Asynchronous**: primary confirms immediately, streams changes after. Lower latency, higher availability, but failover can lose recent writes, and replica reads can be stale.

```
# postgresql.conf on primary
wal_level = replica
max_wal_senders = 5
hot_standby = on

# On replica
primary_conninfo = 'host=primary.internal port=5432 user=replicator password=...'
```

With Neon: read replicas are async and eventually consistent. Route latency-tolerant, read-heavy traffic (Quikn's analytics dashboard) to a replica; anything read-your-own-write sensitive to the primary.

### 3. Partitioning

Splits one logical table into smaller physical pieces within the same instance. Postgres native declarative partitioning on Quikn's `click_events` by month:

```
CREATE TABLE click_events (
    id BIGSERIAL,
    shortcode TEXT NOT NULL,
    clicked_at TIMESTAMPTZ NOT NULL,
    country TEXT,
    referrer TEXT
) PARTITION BY RANGE (clicked_at);

CREATE TABLE click_events_2026_01 PARTITION OF click_events
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

CREATE TABLE click_events_2026_02 PARTITION OF click_events
    FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
```

Why: queries filtered by `clicked_at` only scan the relevant partition (pruning), indexes stay small, and old partitions can be dropped instantly instead of a slow `DELETE`. Cheapest scaling lever here — no application routing logic needed.

### 4. Sharding

Splits data across multiple separate database instances, needed once a single machine's disk/memory/write ceiling is reached even after partitioning + replicas. Most expensive step: cross-shard queries/transactions get hard, and re-sharding later is painful.

Sharding key selection is the most consequential decision. Sharding `links` by hash of shortcode distributes load evenly but makes "list all links for user X" need every shard. Sharding by `user_id` makes per-user queries fast but risks hotspots from power users.

```
// lib/shard.ts
import { createHash } from "crypto";

const SHARD_COUNT = 4;
const shardConnections = [
  process.env.DB_SHARD_0_URL!,
  process.env.DB_SHARD_1_URL!,
  process.env.DB_SHARD_2_URL!,
  process.env.DB_SHARD_3_URL!,
];

export function getShardForKey(key: string): string {
  const hash = createHash("sha256").update(key).digest();
  const shardIndex = hash.readUInt32BE(0) % SHARD_COUNT;
  return shardConnections[shardIndex];
}

export function getConnectionForShortcode(shortcode: string) {
  return getShardForKey(shortcode);
}
```

Why hashing over range-based sharding: shortcodes are effectively random, so range sharding would create hotspots. Range sharding is right for naturally sequential, time-ordered data (e.g., orders by date). Choose based on access pattern and key distribution, not by default.

### 5. SQL vs NoSQL

**SQL (Postgres)**: enforces schema/referential integrity, multi-row ACID transactions, rich joins. Cost: migrations required, horizontal write scaling needs sharding.

**NoSQL sub-categories:**
- **Document (MongoDB)**: flexible schema, weaker cross-document guarantees historically.
- **Key-value (Redis, DynamoDB)**: extremely fast single-key lookups, minimal query flexibility.
- **Wide-column (Cassandra)**: massive write throughput, AP-leaning, weak ad hoc query support.

Decision framework: Quikn uses Postgres for links/users/billing (referential integrity + atomic transactions matter). Redis for caching/rate-limits (pure key-value, disposable if lost). Lesson: production systems are usually **polyglot persistence**, not one database for everything.

### 6. C4 Diagram, Data Layer Detail

```
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Component.puml

Container_Boundary(data, "Data Layer") {
  ComponentDb(primary, "Primary (Neon)", "PostgreSQL", "Writes, read-your-own-write reads")
  ComponentDb(replica, "Read Replica (Neon)", "PostgreSQL", "Analytics dashboard reads")
  ComponentDb(shard0, "Shard 0", "PostgreSQL", "shortcode hash % 4 == 0")
  ComponentDb(shard1, "Shard 1", "PostgreSQL", "shortcode hash % 4 == 1")
  Component(router, "Shard Router", "TypeScript lib", "Hashes key, picks connection")
}

Rel(router, shard0, "Routes by hash")
Rel(router, shard1, "Routes by hash")
Rel(primary, replica, "Async streaming replication")
@enduml
```

### 7. Design Challenge

Quikn's `links` table has grown to 500 million rows. Write latency degraded from 5ms to 60ms, and the nightly `click_events` aggregation now takes 4 hours, overlapping business hours. Propose a plan. Be explicit about what you would **NOT** shard yet.

### 8. Solution and Discussion

**Diagnose before sharding.** 60ms write latency on a 500M-row table is very likely an indexing/bloat problem, not a hard sharding-required ceiling — check for bloated indexes and autovacuum health first.

For the aggregation job: apply partitioning (section 3) before sharding — partition `click_events` by month, aggregate only the current partition. Likely fixes the 4-hour job without touching `links` at all.

For `links` specifically: if the write ceiling is still genuine after fixing indexes/vacuum, shard by hash of shortcode, since both reads and writes benefit from even distribution and no cross-user joins are needed.

**What NOT to shard:** `users` and `billing`. Much smaller tables, no size problem, and sharding them would break the atomic "create link, decrement quota" transaction, which needs both rows in the same database to stay ACID. Keep small, transactionally-critical tables unsharded as long as possible.

---
*Next: "Scalable Systems Design - Part 4: Asynchronous Processing"*
