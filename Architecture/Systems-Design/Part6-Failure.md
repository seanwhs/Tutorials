## Part 6: Designing for Failure

### 1. Concept and Philosophy

Every component discussed so far — load balancers, caches, databases, queues, other services — will eventually fail, time out, or slow down. A system that assumes its dependencies are always healthy is not a scalable system, it is a system that has not yet had its outage. The shift in mindset: stop asking how do I prevent failure, you cannot fully, and start asking how does my system behave when a dependency fails, and how do I stop that failure from cascading into a total outage.

The recurring theme is that most catastrophic outages are caused by the system's own reaction to the failure: retries that amplify load on an already struggling service, a slow dependency that exhausts a connection pool and takes down an otherwise healthy caller, or a thundering herd of clients all retrying at the same instant. Every pattern below exists to prevent your system from becoming its own worst enemy during a partial failure.

### 2. Retries with Exponential Backoff and Jitter

A naive immediate retry turns one failed request into a burst hitting an already struggling dependency at the exact moment it is weakest — retry amplification — often the cause of an outage turning into a prolonged outage. The fix is exponential backoff (each retry waits longer) plus jitter (randomizing the wait so many clients don't retry in lockstep, recreating the thundering herd at a delay).

Retry wrapper used for Quikn's call from the links service to the internal link validator (Part 5): on failure, increment an attempt counter; if attempts remain, compute a wait time of base-times-2-to-the-power-of-attempt capped at 10 seconds, add a random jitter of up to half that value, sleep, then retry; only after max attempts are exhausted does the error propagate to the caller.

Only retry transient errors: timeouts, connection resets, HTTP 502 or 503. Never retry HTTP 400 or 422 (identical failure every time). Never retry HTTP 409 conflicts without checking idempotency first (section 5).

### 3. Circuit Breakers

Retries alone are not enough: if a dependency is fully down, retrying with backoff still means every caller eventually times out slowly, tying up threads and connections while waiting — which can exhaust the caller's own resource pool and take it down too. This is cascading failure. A circuit breaker tracks the failure rate to a dependency and, once it crosses a threshold, opens the circuit: stops calling the dependency entirely for a cooldown period and fails fast instead, protecting both the caller's own resources and the already struggling dependency.

Three states: **Closed**, calls pass through normally and failures are counted. **Open**, calls fail immediately without attempting the network call, after too many recent failures within a window. **Half-Open**, after cooldown elapses, a small number of trial calls test recovery; success closes the circuit again, failure reopens it.

Implementation shape: a CircuitBreaker class holds a state field, a failure counter, and the last-failure timestamp. Its call method checks state first — if open and cooldown elapsed, moves to half-open and allows a trial call; if open and cooldown hasn't elapsed, throws immediately. On success it resets the counter and returns to closed. On failure it increments the counter and flips to open once the threshold is crossed.

Applied to Quikn: wrap the links-service-to-validator call in a circuit breaker. If the validator degrades, the circuit opens and link creation fails fast with a clear message rather than every request hanging for the full timeout. This is also a live CAP-adjacent decision: fail closed (block creation, favor correctness) versus fail open (allow creation unvalidated, favor availability) — the right answer depends on the actual business risk.

### 4. Rate Limiting

Rate limiting protects a service from being overwhelmed by too many requests from one client (retry storm, scraping, abuse), and protects shared downstream resources from monopolization. It is the producer-side counterpart to Part 4's consumer-side backpressure.

Token bucket algorithm implemented against Redis for Quikn's public API, shared correctly across all horizontally-scaled app instances: for a given user and time window, increment a Redis counter keyed by user id + window bucket; if first increment in the window, set an expiry equal to the window length; compare the resulting count against the limit and reject if exceeded.

Why Redis and not an in-memory counter per app server: with N horizontally-scaled instances, an in-memory counter per instance lets a client get N times the intended limit. A shared store is mandatory for rate limiting in any horizontally-scaled system.

Enforce rate limits at the API Gateway (Part 5) so individual backend services don't reimplement this, returning HTTP 429 with a Retry-After header.

### 5. Idempotency

An idempotent operation produces the same end result no matter how many times it's applied. This matters because at-least-once delivery (Part 4's async workers, and any retried sync call from section 2) means handlers will occasionally run twice on the same logical request. Without idempotency, a retried "charge this customer" call double-charges them.

Standard pattern: an idempotency key. The caller generates a unique key per logical operation (not per HTTP attempt); the server records which keys it has already processed, returning the original result on a repeat. For Quikn's link-creation endpoint: read an Idempotency-Key header, reject if missing; look it up in an idempotency-records table — if found, return the stored status/body unchanged; if not, create the link and durably store the (key, status, body) tuple, ideally behind a unique constraint so concurrent duplicates can't both slip through.

The client reuses the same key across retries of the same logical attempt; the server treats the key-result pair as durable and checked atomically before doing the real work.

### 6. Consistency in Distributed Systems

When a logical operation spans multiple services/databases (e.g., "create a link" in Postgres + "decrement quota" in a different service), you can't use a single ACID transaction, and two-phase commit across services is generally avoided since it requires all participants up and responsive simultaneously — reintroducing a distributed single point of failure.

The pragmatic alternative: the **Saga pattern** — break the operation into local transactions, each with a compensating action if a later step fails. For Quikn: create the link in Postgres, then call the quota service to decrement; if that fails, run a compensating action (delete the just-created link) rather than attempting a remote rollback.

This buys availability at the cost of a brief window of inconsistency — a deliberate PACELC trade-off applied at the application-transaction level.

### 7. C4 Diagram, Failure Handling Overview

Picture the Links Service calling a Circuit Breaker Wrapper, which calls the Link Validator (Part 5). In parallel, the API Gateway calls a Rate Limiter backed by Redis before routing to the Links Service. The Circuit Breaker Wrapper sits directly between the Links Service and the Validator: closed, calls pass through; open, calls are rejected locally without ever reaching the validator.

### 8. Design Challenge

Quikn's internal link validator starts timing out intermittently under load. Within minutes, the links service becomes unresponsive, and its health checks start failing on the load balancer, causing cascading restarts. Diagnose the root cause and propose a fix.

### 9. Solution and Discussion

Root cause: resource exhaustion via unbounded synchronous waiting, not the validator's slowness itself. Every link-creation request opens a connection to the validator and, without a circuit breaker or tight timeout, waits; as the validator degrades, waits get longer, and threads/connections pile up. Eventually the links service exhausts its own pool, and since health checks share that pool, they start failing too — even though the service's own code is healthy. The load balancer marks instances unhealthy and restarts them, which fixes nothing and adds restart churn — classic cascading failure.

The fix combines three patterns: **(1)** a circuit breaker around the validator call so failures cross a threshold and the service fails fast, freeing stuck resources. **(2)** an aggressive explicit timeout on the validator call, shorter than the health-check interval, so no single call can starve it. **(3)** an explicit decision on fail-open vs. fail-closed while the circuit is open — leaving this undefined is exactly what caused the cascading restarts in the first place.

---
*Next: "Scalable Systems Design - Part 7: Real-World Case Studies"*
