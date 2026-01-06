# Part III — Distributed Systems & Microservices

Distribution is not an automatic upgrade—it’s a **trade-off** where you sacrifice local simplicity (shared memory, ACID transactions) for global scalability and team autonomy.

## 1. Microservices (Componentization via Services)

Defined by Martin Fowler as **“componentization via services”**, Microservices are primarily an **organizational and architectural strategy**, not just small codebases.

### ✅ When to Use

* Team coordination exceeds manageable limits.
* Independent deployment becomes a requirement.
* Domains evolve at different speeds or use different tech stacks.

### ⚙ Core Traits

* **Independently deployable services** – each service has its own lifecycle.
* **Decentralized governance** – services make local decisions.
* **Evolutionary technology choices** – services may use different languages, databases, or frameworks.
* **Smart endpoints, dumb pipes** – intelligence resides in services, not in the messaging layer (REST, gRPC, or message queues).

### 🔄 Conceptual Flow

```text
   +-----------+       +-----------+       +-----------+
   | Service A | ----> | Service B | ----> | Service C |
   | (Own DB)  |       | (Own DB)  |       | (Own DB)  |
   +-----------+       +-----------+       +-----------+

```

Each service owns its data, enforces its boundaries, and communicates via well-defined APIs or messages.

---

## 2. Essential Distributed Patterns

To manage the complexity of "The Unreliable Network," we utilize specific patterns to ensure consistency and resilience.

### A. CQRS (Command Query Responsibility Segregation)

**The Problem:** High-performance reads often conflict with the normalized structure required for consistent writes.
**The Solution:** Separate the models for updating data from the models for reading data.

```text
Command (POST/PUT) --> [ Write Model ] --> SQL (Source of Truth)
                                |
                         (Sync/Async Event)
                                |
Query (GET) <--------- [ Read Model ] <--- NoSQL / Cache / Index

```

### B. Saga Pattern (Distributed Transactions)

**The Problem:** Distributed systems lack a global `BEGIN/COMMIT`. How do we ensure data consistency across three services?
**The Solution:** A sequence of local transactions. If one fails, the system triggers "Compensating Transactions" to undo previous successful steps.

```text
[ Order Service ] -> [ Payment Service ] -> [ Shipping Service ]
      |                      |                      |
      |             (Failure) X                      |
      |                      |                      |
      |<--- (Compensate) ----+                      |

```

### C. Circuit Breaker

**The Problem:** A single slow service can cause a thread-pool backup, leading to a cascading failure across the entire cluster.
**The Solution:** A proxy that monitors for failures. When a threshold is met, it "trips," failing fast to protect the caller and giving the supplier time to recover.

```text
Service A --> [ Circuit Breaker ] --> Service B
                     |
            (Trips if B is failing)
                     |
             X-- (Fail Fast) --X

```

---

## ⚠ Operational Notes

* **The Microservices Tax:** Monitoring, deployment pipelines, network management, and cross-service tracing (OpenTelemetry) are non-negotiable.
* **Earn Your Distribution:** Start with a modular monolith. Extract services only when organizational complexity or specific scaling needs justify the overhead.

> Microservices are about **scale, autonomy, and flexibility**, not fragmentation for its own sake.

---

### 📂 Directory Contents

* `/cqrs-implementation`: Node.js + Redis + Postgres example.
* `/saga-orchestrator`: A "Travel Booking" demo with compensating logic.
* `/resilience-lab`: Hands-on with Circuit Breakers and Retries.

