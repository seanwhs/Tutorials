## Series: Scalable Systems Design — Engineering for High Performance and Availability

**Perspective:** Staff/Principal Engineer. Every part answers "why," weighs trade-offs against CAP theorem, latency budgets, and $ cost — not just "how to wire up a tool."
**Tooling constraint:** 100% free/open-source. Diagramming via C4 Model + Structurizr DSL / PlantUML / Excalidraw (all free/OSS or free-tier). Implementation stack: Next.js, PostgreSQL (Neon free tier), Redis (OSS), Nginx (OSS), Kafka/Redpanda or Inngest (free tier), Prometheus/Grafana (OSS), Terraform/OpenTofu (OSS).

### How this series is structured

Each Part follows the same four-beat pattern so you can study it like a runbook:

1. **Concept & Philosophy** — the problem being solved, and the *why* behind the chosen pattern, framed against CAP theorem / latency-throughput trade-offs / cost.
2. **Architecture** — a C4-style diagram (rendered as PlantUML/Structurizr DSL text you can paste into a free renderer) plus a written walkthrough of the boxes and arrows.
3. **Implementation** — real config/code: Nginx configs, SQL DDL, Redis commands, Kafka/Inngest producers/consumers, TypeScript services. Copy-pasteable, annotated.
4. **Design Challenge + Solution** — a scenario you build yourself, then a worked solution with the trade-offs made explicit.

### Reference architecture used throughout

Most parts build toward one running example: **"Quikn" — a URL shortener + link-analytics platform** that gradually gains traffic (10 req/s → 50K req/s) and features (auth, real-time click analytics, notifications). Part 7 also branches into two more case studies (chat system, notification service) to prove the patterns generalize.

Stack for the reference implementation:
- **Framework:** Next.js (App Router) for API + minimal dashboard UI
- **Primary DB:** PostgreSQL via Neon (serverless Postgres, free tier, scale-to-zero)
- **Cache:** Redis (OSS, run locally via Docker or free-tier Upstash/Redis Cloud)
- **Reverse proxy / LB:** Nginx (OSS) for L7 examples; HAProxy mentioned for L4
- **Async/eventing:** Kafka concepts taught generically, with runnable examples using **Redpanda** (Kafka-API-compatible, free OSS, single-binary, no ZooKeeper) and **Inngest** (free-tier, great DX for event-driven functions on serverless)
- **IaC:** Terraform/OpenTofu (OSS)
- **Observability:** Prometheus + Grafana (OSS, Docker Compose)

### Part Index

| Part | Title | Core Question Answered |
|---|---|---|
| 1 | The Foundations | What does "scale" even mean, and what can't you have all of at once (CAP)? |
| 2 | Designing for Traffic (Load Balancing & Caching) | How do you absorb 100x traffic without 100x-ing your servers? |
| 3 | The Data Layer | How does your database survive when it becomes the bottleneck? |
| 4 | Asynchronous Processing | How do you decouple "must happen now" from "must happen eventually"? |
| 5 | Service Communication | How do services find and talk to each other without becoming a distributed monolith? |
| 6 | Designing for Failure | How do you fail gracefully instead of catastrophically? |
| 7 | Real-World Case Studies | How do the patterns compose into a full interview-grade system design? |
| 8 | The Production Pipeline | How does this design actually get deployed, watched, and paid for? |

### Appendix Index

| Appendix | Title | Use it for |
|---|---|---|
| A | System Design Toolkit | Picking a free diagramming/notation tool and knowing the C4 levels |
| B | Scalability Cheat Sheet | Fast lookup tables during design interviews or architecture reviews |
| C | The Resilience Playbook | Mapping a failure symptom to the architectural remedy |

### Suggested study path

- **First pass (concepts):** Read Part 1 → Part 6 in order, skimming code, focusing on the "Philosophy" sections and diagrams.
- **Second pass (hands-on):** Re-run Part 2–Part 5 code examples locally (Docker Compose provided per part) against the Quikn schema from Part 3.
- **Interview prep:** Jump straight to Part 7, then back-reference Appendices B and C for the trade-off vocabulary.
- **"I need to ship this for real":** Part 8, then loop back to Part 6 (failure modes) before going to production.

### Prerequisites
- Comfortable with basic web dev (HTTP, REST, a general-purpose language). TypeScript/Node used for code samples but concepts are language-agnostic.
- Docker installed for local Redis/Redpanda/Prometheus examples.
- No paid services required anywhere in this series — free tiers only (Neon, Upstash, Inngest, Grafana Cloud free tier optional).

---
*Next: open "Scalable Systems Design - Part 1: The Foundations"*
