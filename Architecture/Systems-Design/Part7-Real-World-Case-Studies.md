## Part 7: Real-World Case Studies

### 1. Concept and Philosophy

This part proves the patterns from Parts 1–6 compose into full system designs, the kind asked in a Staff Engineer design interview or architecture review. Each case study: clarify requirements and scale first, identify the dominant constraint (throughput, latency, consistency, storage growth), then walk through the architecture layer by layer, citing which earlier pattern solves which problem and why. Resist jumping straight to a component diagram before requirements are pinned down — the single most common design-interview mistake.

### 2. Case Study A: URL Shortener at Scale (Quikn, generalized)

**Requirements:** 100M links total, 10B redirects/month, ~100:1 read-to-write ratio, redirects need <50ms latency but a link edit can tolerate small staleness, click analytics can be eventually consistent.

**Dominant constraint:** read-heavy, latency-sensitive, high-throughput — not strong-consistency. Write path (link creation) is comparatively low volume.

**Architecture:** CDN + Redis absorb most redirect reads before Postgres (Part 2's multi-tier caching, effective given Zipfian link popularity). Shortcode generation uses a pre-generated pool of unique IDs rather than checking uniqueness against the full dataset per write. `links` is partitioned/sharded by hash of shortcode (Part 3) once a single instance's ceiling is hit. Click events recorded async via event bus (Part 4), decoupling the redirect hot path from analytics writes; `click_events` is time-partitioned. Redirect sits behind an L7 LB (Part 2); any sync internal call (e.g., a safety validator) is wrapped in retries + circuit breaker (Part 6).

**Trade-off callout:** eventual consistency for the dashboard click count vs. strong consistency for shortcode uniqueness — a collision is a correctness bug, a stale count is cosmetic. CAP framing applied *per-feature*, not per-system.

### 3. Case Study B: Real-Time Chat System

**Requirements:** 50M MAU, mostly 1:1/small groups, in-order delivery per conversation, sub-second delivery to online recipients, durable history even if recipient offline.

**Dominant constraint:** latency-sensitive, ordering-sensitive, connection-heavy. New problem vs. the URL shortener: many long-lived stateful client connections, conflicting with Part 1's "stateless servers" principle.

**Architecture:** clients hold persistent WebSocket connections to a chat gateway tier — the one place that must track state (which socket is on which instance), scaled by connection count, not CPU. A presence registry (Redis) maps user id → gateway instance. Send flow: sender's gateway writes the message durably to Postgres first, publishes an event to the message bus (Part 4); recipient's gateway delivers over the open socket if online, or the message waits in storage if offline (a request-async-reply pattern applied to humans). Ordering preserved via conversation id as partition key (Part 4). Service discovery uses DNS-plus-load-balancer (Part 5).

**Trade-off callouts:** at-least-once delivery + client-side dedup (idempotency applied to message ids) over exactly-once, since exactly-once is prohibitively complex for the same user-visible outcome. Keeping the gateway tier stateful breaks Part 1's stateless guidance deliberately — WebSockets are inherently stateful, so statefulness is contained to the smallest tier, leaving message-processing and storage stateless.

### 4. Case Study C: Real-Time Notification Service

**Requirements:** shared internal service across products, multi-channel (push/email/in-app), tolerates huge bursts (e.g., 5M users notified simultaneously), never double-sends the same notification.

**Dominant constraint:** burst-tolerant, multi-channel, idempotency-critical. Core challenge: fan-out at scale without overwhelming rate-limited third-party providers.

**Architecture:** producers emit one generic `notification-requested` event (Part 4 decoupling) — any future channel added with zero producer changes. A fan-out worker emits per-channel events on separate partitioned topics, so a slow email provider can't backpressure push. Each channel worker rate-limits outbound provider calls (Part 6 token bucket) and wraps calls in retries + circuit breaker, so a provider outage degrades only that channel. Dedup via idempotency key = user id + event id + channel, stored durably before the provider call (Part 6).

**Trade-off callout:** fail open per channel independently rather than an all-or-nothing Saga — if email fails but push succeeds, the user is still notified. A different consistency posture than Part 6's link-creation Saga, which needed real rollback because it managed billable quota, not best-effort communication.

### 5. Design Challenge

Add a new requirement to one case study: custom branded domains (URL shortener), message search across history (chat), or "digest mode" batching notifications daily. Identify which existing component changes and which trade-off shifts.

### 6. Solution and Discussion

**Custom domains:** LB/CDN must route on Host header, requiring per-customer TLS (free ACME/Certbot), and shortcode lookup becomes a composite key of domain+shortcode. Trade-off: cache keys now include domain, increasing cardinality and slightly lowering hit ratio during a new customer's cold start.

**Chat search:** a new read pattern Postgres was never optimized for. Fix: polyglot persistence — keep Postgres as system of record, asynchronously index messages (event-bus fan-out) into a purpose-built search store. Trade-off: search becomes eventually consistent with a short indexing lag — an acceptable PACELC trade since search freshness matters far less than message delivery freshness.

**Digest mode:** inverts "fire immediately" into "collect then batch" — events written to a per-user accumulating store, a scheduled job emits one combined email per user per digest window. Trade-off: deliberately increases latency (no immediate notice) in exchange for reduced volume and better UX for high-frequency-event users — a throughput-vs-latency trade made at the product level.

---
*Next: "Scalable Systems Design - Part 8: The Production Pipeline"*
