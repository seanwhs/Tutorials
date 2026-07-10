## Part 1: The Foundations

### 1. Concept & Philosophy

Before touching a load balancer or a database shard, a Staff Engineer asks one question: **what does "scale" mean for this specific system?** Scale is not a single axis. A system can be:

- **Load-scalable**: handles more concurrent users/requests
- **Data-scalable**: handles growing data volume without degrading
- **Geographically-scalable**: serves users across regions with acceptable latency
- **Team-scalable**: many engineers can ship changes without stepping on each other (this is why microservices exist as much for Conway's Law as for traffic)

Most junior designs fail not because they picked the wrong database, but because they optimized for the wrong axis. A system with 100 users spread across 40 countries has a *latency* problem, not a *throughput* problem — throwing more servers at one region won't fix it. Always start by identifying the dominant constraint.

### 2. Vertical vs. Horizontal Scaling

**Vertical scaling (scale up)**: add more CPU/RAM/disk to a single machine.
- Pros: no code changes, no distributed-systems complexity, strong consistency is trivial (it's one machine).
- Cons: hard ceiling (biggest cloud instance is still finite), single point of failure, cost grows non-linearly at the high end, downtime during resize.
- Right call: early-stage products, batch/analytical workloads that are hard to parallelize, or when the org's real bottleneck is engineering time, not infra.

**Horizontal scaling (scale out)**: add more machines and distribute load across them.
- Pros: near-linear cost scaling, no hard ceiling, fault tolerance (one node dies, others absorb load), can scale to zero when idle.
- Cons: you now own distributed-systems problems — state must live somewhere shared, coordination, network partitions, CAP theorem trade-offs.
- Right call: unpredictable/spiky traffic, systems that need to survive node failure, anything user-facing at internet scale.

**Trade-off framing (the "why"):** Vertical scaling trades *operational simplicity* for a *lower ceiling and worse fault tolerance*. Horizontal scaling trades *simplicity and consistency* for *elasticity and resilience*. Most production systems do both.

### 3. CAP Theorem — the constraint you cannot engineer away

CAP theorem states a distributed data system can provide at most **two** of these three guarantees simultaneously, and only during a **network partition** does the trade-off actually bite:

- **Consistency (C)**: every read receives the most recent write (or an error).
- **Availability (A)**: every request receives a (non-error) response, without guarantee it's the latest write.
- **Partition Tolerance (P)**: the system continues operating despite network partitions between nodes.

Partitions *will* happen. So P is not optional — you are really choosing between **CP** and **AP**:

- **CP systems** (e.g., single-leader PostgreSQL with sync replication, ZooKeeper, etcd): during a partition, refuses writes/reads on the minority side rather than risk stale/conflicting data. Choose for money movement, inventory counts.
- **AP systems** (e.g., Cassandra, DynamoDB default mode): every node keeps answering, possibly stale, reconciles later. Choose for social feeds, view counters, presence/status.

**PACELC extension:** even *without* a partition, you trade **Latency vs. Consistency (ELC)**. Sync replication = strong consistency but latency tax on every write. Async replication = fast but can lose last writes on failover. "We use Postgres so we're CP" is incomplete — you must also state your replication mode.

### 4. Latency vs. Throughput

- **Latency**: time for a single request to complete. What the *user* feels.
- **Throughput**: requests processed per unit time. What the *system* feels.

- Batching increases throughput but increases per-item latency.
- More concurrent workers increases throughput until contention causes latency spikes — measure p50/p95/p99 *under* throughput, not max throughput alone.
- **Little's Law**: L = λ × W (avg requests in system = arrival rate × avg time in system). Rising latency at flat arrival rate = requests piling up, a leading indicator of overload.

**Design implication:** define SLOs in both dimensions, e.g. "p99 latency < 200ms at 5,000 req/s sustained."

### 5. High-Level System Components

```
Client → CDN → Load Balancer (L7) → API Gateway → Application Servers
                                                        │
                              ┌─────────────────────────┼─────────────────────┐
                              ▼                          ▼                     ▼
                         Cache (Redis)          Primary DB (Postgres)   Message Queue (Kafka)
                                                        │                       │
                                                  Read Replicas          Async Workers
```

- **CDN**: caches assets at edge locations near users.
- **Load Balancer**: distributes requests across app instances (Part 2).
- **API Gateway**: auth, rate limiting, routing (Part 5).
- **Application servers**: stateless — critical, so the LB can add/remove freely.
- **Cache**: absorbs repeated reads (Part 2).
- **Database**: durable state, hardest to scale horizontally (Part 3).
- **Message queue**: decouples producers/consumers, absorbs spikes (Part 4).

Recurring rule of thumb: **push work as far from the user's critical request path as possible** — cache it, queue it, or precompute it.

### 6. C4 Diagram — System Context (Level 1)

```
@startuml
!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Context.puml

Person(user, "End User", "Uses the Quikn URL shortener")
System(quikn, "Quikn", "Shortens URLs, tracks click analytics, sends notifications")
System_Ext(dns, "DNS/CDN", "Cloudflare or similar")

Rel(user, dns, "HTTPS request")
Rel(dns, quikn, "Forwards request")
@enduml
```

We start at Level 1 deliberately — no Redis/Postgres boxes yet. Resist jumping to implementation diagrams before the system boundary is agreed on.

### 7. Design Challenge

**Scenario:** Design "a service that lets 10 million users check in at physical store locations and see a live count of how many people are currently checked in at each store."

1. Is this system dominated by throughput, latency, or geographic distribution? Why?
2. For the "live count" feature, would you choose CP or AP? Justify with a concrete failure scenario.
3. Scale vertically or horizontally first? What's the first bottleneck?

### 8. Solution & Discussion

1. **Dominant constraint:** Throughput at peak + geographic distribution. A 1-2s staleness on the live count is tolerable — throughput+availability dominant, not latency-critical.
2. **CP vs AP:** Choose **AP**. If two data centers partition during a rush, an AP design (local counting + eventual sync) keeps check-ins succeeding everywhere — a slightly-wrong count is cosmetic. A CP design would block check-ins in the minority partition — unacceptable for a display counter. (Contrast: "reserve the last spot" would lean CP.)
3. **Scaling direction:** Horizontal, immediately. First bottleneck: the **counter write hotspot** — a single Postgres row getting `UPDATE ... count = count + 1` becomes lock-contended. Fix: move the counter to Redis `INCR`, treat Postgres as the eventually-synced system of record.

---
*Next: "Scalable Systems Design - Part 2: Designing for Traffic (Load Balancing & Caching)"*
