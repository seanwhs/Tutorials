# Appendix C: Architectural Pattern Matrix

A comparison of the four architectural styles referenced throughout this series, for deciding which fits a given system, team, and stage.

## 1. The Core Comparison Table

| Dimension | Monolith | Modular Monolith | Microservices | Serverless / Event-Driven |
|---|---|---|---|---|
| **Deployable units** | 1 | 1 (internally modular) | N (one per service) | N (one per function/event handler) |
| **Team size fit** | 1-5 engineers | 1-15 engineers | 15+ engineers, multiple teams | Variable; often small teams per function |
| **Data ownership** | Single shared schema | Logically partitioned schema, single DB (per Part 4) | Database-per-service | Often managed/shared data stores per event domain |
| **Operational complexity** | Lowest | Low-to-medium | High (service mesh, distributed tracing, N pipelines) | Medium (cold starts, vendor-specific tooling, though many OSS options like OpenFaaS exist) |
| **Failure isolation** | None — one bug can crash everything | Partial — module boundaries limit blast radius in code, but a shared process can still go down together | Strong — one service crashing doesn't take down others | Strong — functions are isolated by design |
| **Consistency model** | Trivial — one transaction, one DB | Mostly transactional within a module; eventual consistency across modules via events (Outbox, Part 4) | Eventual consistency the default; distributed transactions (sagas) are complex and costly | Eventual consistency, driven entirely by events |
| **Cost of Change (early stage)** | Low — everything is one codebase, easy to refactor | Low-to-medium — module boundaries add slight ceremony but stay refactorable | High — changing a cross-service contract requires coordinated deploys | Medium — function boundaries are natural seams but debugging distributed flows is harder |
| **Cost of Change (at scale)** | Very high — shared mutable state and tangled dependencies make any change risky | Medium — pre-cut seams (per Part 8) make incremental extraction cheap | Low for isolated services, high for cross-cutting changes spanning many services | Low for isolated functions, high for orchestrating complex multi-step workflows |
| **Best free/OSS tooling fit** | Any framework, single free DB | Next.js/Node monorepo + SQLite/Postgres + in-process events | Free container orchestration (k3s, Docker Compose) + OSS message broker (RabbitMQ/NATS) | OSS FaaS (OpenFaaS, Knative) or platform free tiers + OSS event bus |

## 2. Decision Guide: When to Use Each

### Use a **plain Monolith** when:
- Team is 1-5 people, or a solo project/PoC
- The domain is not yet well understood (premature modularization guesses wrong boundaries)
- Speed of initial delivery matters more than long-term structure
- **Caveat:** plan to introduce module boundaries (becoming a Modular Monolith) as soon as the domain stabilizes — don't let "just ship it" become permanent architectural debt. Revisit trigger: when a second developer joins and starts stepping on the first's changes regularly.

### Use a **Modular Monolith** when:
- Team is small-to-mid size (this series' default recommendation for most new products, including Northwind Orders through Part 8)
- Bounded contexts are reasonably well understood (per Part 2's DDD exercise) but haven't yet proven a need for independent scaling or independent deployment
- You want the *option* to extract services later without paying microservices' operational tax now
- **This is the default choice** for the vast majority of systems that are neither trivial PoCs nor already operating at significant multi-team scale. It defers the microservices decision to when you have *evidence*, not speculation.

### Use **Microservices** when:
- Specific, evidenced scaling asymmetry exists between contexts (e.g., Inventory's load is 40x Ordering's, per the Part 8 capstone exercise)
- Multiple teams need to own, deploy, and scale contexts fully independently, with different release cadences
- Different contexts have genuinely different technology needs (e.g., one context benefits from a graph database, another from a relational one)
- **Caveat:** each service split should be justified by its own ADR (per Part 7) with a specific trigger condition — never split "because microservices are best practice." The operational cost (distributed tracing, service mesh, N CI/CD pipelines, network partition handling) is real and ongoing.

### Use **Serverless / Event-Driven** when:
- Workloads are spiky/unpredictable and pay-per-use economics matter (though note: many "serverless" platforms are not free/OSS — favor OSS FaaS like OpenFaaS or Knative to honor this series' tooling constraint)
- The workflow is naturally a sequence of discrete reactions to events (e.g., "on OrderPaid, send notification" — directly matches the Outbox/Published Language pattern from Part 4)
- You want near-zero idle infrastructure cost and are comfortable with eventual consistency and the debugging complexity of distributed, asynchronous flows
- **Caveat:** orchestrating multi-step workflows across many functions (sagas) reintroduces complexity comparable to microservices' distributed transaction problem — don't reach for this pattern for tightly-coupled, strongly-consistent workflows.

## 3. Applying the Matrix to Northwind Orders (Worked Example)

| Stage | Chosen pattern | Why |
|---|---|---|
| MVP (Parts 1-8 baseline) | Modular Monolith | Team size small, contexts understood via DDD but unproven at scale — lowest Cost of Change while preserving future optionality |
| Post-Inventory-scaling-pressure (Part 8, Step 1-2 exercise) | Modular Monolith + 1 extracted Microservice (Inventory) | Specific, evidenced need for independent scaling of exactly one context — incremental, ADR-justified extraction, not a wholesale rewrite |
| Hypothetical future: Notifications becomes extremely high-volume, spiky (e.g., flash-sale traffic) | Modular Monolith + Inventory microservice + Serverless/event-driven Notifications | Notifications' workload profile (spiky, purely reactive to OrderPaid/OrderShipped events, already decoupled via Published Language since Part 2) is a strong natural fit for event-driven functions, while Ordering/Catalog/Payments-adapter remain in the steady-state monolith |

**The pattern to notice:** the architecture doesn't move as a monolithic block from "Monolith" to "Microservices" — it evolves **context by context, evidence by evidence**, exactly as designed from Part 1's Dependency Rule through Part 8's pre-cut module seams. This piecemeal evolvability, not any single pattern in isolation, is the actual mark of a well-architected system.

## 4. Anti-Pattern Warning: "Premature Distribution"

The single most common architectural mistake this matrix is meant to prevent: choosing Microservices or heavy Serverless fragmentation at project inception, before bounded contexts are even validated (Part 2), purely because it's perceived as the "modern" or "scalable" choice. This front-loads the highest Cost-of-Change tooling and operational overhead onto the phase of a project that can least afford it — when requirements are still volatile and every context boundary is a guess. The Modular Monolith exists specifically to let you defer that cost until your bounded contexts have survived contact with real usage and real scaling pressure.
