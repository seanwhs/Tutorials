## Part 8: The Production Pipeline

### 1. Concept and Philosophy

A design that only exists as a diagram has delivered zero value. This part closes the loop from architecture to running infrastructure: how the system gets provisioned repeatably, how changes ship safely, how you know it's healthy in real time, and how much it costs to run. Production readiness is not a separate phase bolted on at the end — it's a set of properties (reproducibility, observability, safe deployability, cost awareness) that should be designed in from Part 1 onward; this part makes them concrete and executable.

### 2. Infrastructure as Code

Manually clicking through a cloud console is not reproducible, reviewable, or safe to redo after a disaster. IaC expresses infrastructure as versioned, declarative configuration, so environments recreate identically and a disaster-recovery rebuild is a command, not a multi-day scramble.

Terraform, and its fully open-source fork OpenTofu, are the standard free tools. A minimal configuration provisions: a provider block, a Redis resource sized for the Part 2 caching workload, a Postgres resource (Neon's Terraform provider, Part 3), a load balancer resource with listener rules (Part 2), and environment-specific variables so the same config provisions both staging and production from one source of truth.

Key discipline IaC enforces: changes are **planned before applied** — a plan step shows exactly what will be created/changed/destroyed, the infra equivalent of a code review diff, catching an accidental production-database destroy-and-recreate before it happens.

### 3. CI/CD Pipeline

CI/CD automates the path from commit to running production change, and should reflect Part 6's failure-awareness philosophy — a deployment pipeline is itself a distributed system with its own failure modes.

A free-tooling pipeline (GitHub Actions or self-hosted Woodpecker CI): on every PR, run tests + static analysis (CI half). On merge to main, build a container image, run migrations against staging first, run a smoke test suite, and only if that passes, promote the *same built artifact* (not a rebuild) to production — artifact immutability matters because rebuilding at each stage risks subtly different code reaching production than what was tested in staging.

Deployment strategy: a **rolling deployment** replaces instances gradually behind the LB, using the same health-check mechanism from Part 6, so instances only receive traffic once healthy. A **canary deployment** (weighted LB from Part 2) sends a small percentage of real traffic to the new version first, with automated rollback triggered if error rate/latency on that slice exceeds a threshold — reusing the observability signals from section 4 as the go/no-go decision.

### 4. Monitoring and Observability

You cannot operate what you cannot see. Three pillars: **metrics** (request rate, error rate, latency percentiles), **logs** (per-request debugging), **traces** (follow one request across every service it touched — essential once Part 5's service communication means one user action spans multiple services).

Prometheus (free, OSS) scrapes metrics endpoints periodically. Grafana (free, OSS) visualizes and evaluates alerting rules. Each app server exposes request/error/latency-histogram metrics; Redis and Postgres have free Prometheus exporters translating their internal stats (cache hit ratio, replication lag, connection pool usage) into the same format.

The metrics that matter most, traceable to earlier parts: **p50/p95/p99 latency** per endpoint (Part 1's Little's Law — averages hide tail latency). **Cache hit ratio** (Part 2) — a sudden drop signals an invalidation bug or traffic shift. **Replication lag** (Part 3) — growing lag means stale replica reads (PACELC). **Queue depth/consumer lag** (Part 4) — the earliest leading indicator consumers can't keep up. **Circuit breaker state transitions** (Part 6) — an open circuit is itself alertable, worth paging on even before user-facing error rates spike.

Alerting philosophy: alert on user-facing symptoms (elevated p99, elevated error rate), not every individual cause — alerting on everything creates alert fatigue and trains engineers to ignore pages. Combine a small number of high-signal alerts with detailed dashboards for root-cause investigation after a real alert fires.

### 5. Cost Optimization

Every architectural choice has a cost axis to weigh explicitly. Caching (Part 2) reduces compute/DB cost, but Redis memory cost is proportional to what's cached and for how long — oversized TTLs on rarely-accessed keys waste memory. Horizontal scaling (Part 1) costs roughly linearly, but only if paired with autoscaling that scales back down — a fixed fleet sized for peak but running constantly is the single most common source of cloud waste. Read replicas and multi-region deployments multiply cost directly — justify each against an actual requirement, not a hypothetical. Serverless-native, scale-to-zero services (Neon for Postgres) reduce cost for spiky/low-traffic workloads by not charging for idle capacity.

Generalizable discipline: attach a rough dollar estimate to every scaling decision *during design*, not after building it — "adding two read replicas costs roughly $X/month and buys us Y" — and let that influence whether the simpler, cheaper fix is tried first (Part 3's diagnose-before-you-shard discipline).

### 6. C4 Diagram, Production Pipeline Overview

Picture: a Developer commits to Git, triggering a CI Runner (GitHub Actions/Woodpecker) that runs tests, builds a container image, and hands off to a Deployment step. The Deployment step applies Terraform/OpenTofu changes, then performs a rolling or canary rollout behind the existing Load Balancer (Part 2). In parallel, Prometheus continuously scrapes metrics from every live component (App Servers, Redis, Postgres, Message Queue) and feeds Grafana, which displays dashboards and pages on-call when user-facing symptoms cross a threshold.

### 7. Design Challenge

Quikn's infrastructure was hand-provisioned over months. A new engineer must stand up an identical staging environment to test the Part 3 sharding migration before touching production — currently ~2 weeks of manual, error-prone work, and nobody's sure staging matches production. Propose a plan, and explain the specific risk beyond lost time.

### 8. Solution and Discussion

**The specific risk:** configuration drift compounding into *false confidence* — if staging is manually rebuilt from memory/docs rather than the same source of truth as production, subtle differences (a missing index, different Redis eviction policy) can make a migration that passes in staging fail in production, which is arguably worse than not testing in staging at all.

**The plan:** (1) reverse-engineer the hand-built production infra into Terraform/OpenTofu via a cloud provider's import workflow — one-time work converting tribal knowledge into a reviewable, versioned artifact. (2) Standing up staging then becomes applying the same config with different variables (smaller instance sizes for cost) — hours, not weeks, and structurally identical to production. (3) Wire staging into the same CI/CD pipeline (section 3) so the migration itself gets tested through the automated migration-and-smoke-test stage, not applied by hand. (4) Once validated with real traffic-shaped load tests, promote the same reviewed Terraform change to production through the pipeline, with monitoring (section 4) watching replication lag and query latency during cutover, and a rollback plan defined *before* starting.

---
This concludes the 8-part series. Continue to Appendix A, B, and C for quick-reference material.
