# 🧩 APPENDIX C — EVENT LIFECYCLE MODEL (GUARANTEES, RETRIES, IDEMPOTENCY)

---

# 🧠 C.1 — Purpose of This Appendix

This appendix defines how events behave in Nexus LMS:

* what guarantees exist
* how retries work
* how duplicates are handled
* how failures propagate (or don’t)
* how system correctness is preserved under chaos

In short:

> “What really happens when something breaks?”

---

# 🧩 C.2 — Core Principle

Nexus LMS treats events as:

> **at-least-once, retryable, observable units of work**

This is a deliberate design choice due to:

Inngest

---

# 🔁 C.3 — Event Lifecycle Stages

Every event goes through 6 stages:

---

## 🟦 Stage 1 — Emission

```text id="c3_stage1"
User action → event created
```

Example:

```text id="c3_event"
assignment.submitted
```

Payload:

```json id="c3_payload"
{
  "assignmentId": "123",
  "content": "answer..."
}
```

---

## 🟦 Stage 2 — Ingestion

Event is received by Inngest:

* validated
* persisted
* queued for execution

---

## 🟦 Stage 3 — Scheduling

System determines:

* which worker function handles event
* concurrency limits
* retry policy

---

## 🟦 Stage 4 — Execution

Workers are invoked:

* plugin registry lookup (Sanity)
* fanout execution begins
* each worker runs independently

---

## 🟦 Stage 5 — Completion

Each worker returns:

* success
* partial success
* or failure

---

## 🟦 Stage 6 — Observation

Everything is logged:

Supabase

---

# ⚠️ C.4 — Delivery Guarantee Model

Nexus LMS uses:

```text id="c4_model"
AT-LEAST-ONCE DELIVERY
```

Meaning:

* events may be delivered more than once
* workers MUST handle duplicates safely

---

# 🧠 C.5 — Idempotency Rule (CRITICAL)

Every worker MUST behave like this:

> “If I receive the same event twice, I produce the same result without duplicating side effects.”

---

## Example problem:

```text id="c5_problem"
assignment.submitted processed twice → duplicate grade entries
```

---

## Solution:

Workers must check:

```ts id="c5_solution"
if (alreadyProcessed(eventId)) return;
```

Or enforce:

* unique constraints in DB
* deterministic inserts
* upserts instead of inserts

---

# 🔁 C.6 — Retry Model

If a worker fails:

### Automatic behavior:

* retry is triggered by Inngest
* exponential backoff applied
* execution is re-attempted

---

## Retry states:

```text id="c6_states"
FAILED → RETRYING → FAILED → RETRYING → DEAD LETTER
```

---

## Dead-letter behavior:

* logged in Supabase
* visible in observability layer
* does NOT block system

---

# 🧠 C.7 — Partial Failure Model

Fanout execution allows:

```text id="c7_partial"
Worker A → success
Worker B → fail
Worker C → success
```

System behavior:

* does NOT rollback
* stores partial results
* marks event as partially successful

---

# 🧩 C.8 — Ordering Guarantees

Nexus LMS guarantees:

### ❌ No global ordering

Events may arrive out of order.

---

### ✔ Per-event ordering only

Within a single event:

* worker priority is respected

Example:

```text id="c8_order"
1. Grader
2. Feedback
3. Analytics
```

---

# 🧠 C.9 — Concurrency Model

Workers run:

* sequentially OR
* parallel fanout (depending on configuration)

But:

> system assumes concurrency is unsafe by default

---

# 🧩 C.10 — Failure Isolation Principle

A failure in one worker:

* MUST NOT affect others

Example:

```text id="c10_isolation"
Analytics worker fails → grading still completes
```

---

# 🧠 C.11 — Event Replay Concept (Advanced)

Because events are stored:

Inngest

We can:

* re-run events
* debug historical AI outputs
* regenerate grades

This enables:

> deterministic system recovery

---

# 🧠 C.12 — System Safety Guarantees Summary

Nexus LMS guarantees:

---

## ✔ At-least-once delivery

No event is lost.

---

## ✔ Event durability

Events are persisted before execution.

---

## ✔ Worker isolation

Failures are contained.

---

## ✔ Observability

Every execution is logged.

---

## ✔ Replayability (emergent property)

System can reconstruct past behavior.

---

# 🧠 FINAL INSIGHT

> Events are not actions.

They are **replayable records of intent**.

Workers do not “run code”.

They **interpret history**.

---

If you want next, Appendix D will be the first *debugging-focused engineering appendix*:

# 🧩 “Observability & Debugging Guide (How to Diagnose AI Systems in Production)”

This is where we turn Nexus LMS into a **self-debuggable AI platform**.
