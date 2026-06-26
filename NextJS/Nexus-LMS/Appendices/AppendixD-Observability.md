# 🧩 APPENDIX D — OBSERVABILITY & DEBUGGING GUIDE (AI SYSTEM DIAGNOSTICS)

---

# 🧠 D.1 — Purpose of This Appendix

This appendix defines how to:

* trace any request in Nexus LMS
* debug AI worker failures
* inspect event flows end-to-end
* identify performance bottlenecks
* reproduce production issues locally

In short:

> “How do you debug a system you didn’t directly control?”

---

# 🧠 D.2 — Observability Philosophy

Nexus LMS follows one strict rule:

> **If it executes, it must be traceable**

There are no hidden paths.

Every system action is logged into:

Supabase

---

# 🔭 D.3 — The Three Pillars of Observability

---

## 1. Events (What happened)

Stored in:

* `event_traces`

Example:

```json id="d3_event"
{
  "event_name": "assignment.submitted",
  "payload": { ... }
}
```

---

## 2. Execution (Who did it)

Stored in:

* `worker_logs`

Example:

```json id="d3_worker"
{
  "worker_name": "AI Grader",
  "input": {},
  "output": {},
  "latency_ms": 1200
}
```

---

## 3. Intelligence (What AI decided)

Stored in:

* `ai_audit_logs`

Example:

```json id="d3_ai"
{
  "score": 85,
  "feedback": "Good work",
  "raw_response": { ... }
}
```

---

# 🔍 D.4 — Debugging Methodology (3-Step Model)

---

## 🧭 STEP 1 — Find the Event

Start from:

```text id="d4_step1"
event_traces
```

Ask:

* Did the event fire?
* Was payload correct?

---

## 🧭 STEP 2 — Trace Worker Execution

Check:

```text id="d4_step2"
worker_logs
```

Look for:

* missing workers
* latency spikes
* failed executions

---

## 🧭 STEP 3 — Validate AI Output

Check:

```text id="d4_step3"
ai_audit_logs
```

Verify:

* correctness of scoring
* feedback quality
* schema validity

---

# 🧠 D.5 — Common Failure Patterns

---

## ❌ 1. “Event fired but nothing happened”

### Cause:

* worker not registered
* Sanity query returned empty

### Fix:

* verify registry query
* check `event` field match

---

## ❌ 2. “Worker ran but no DB update”

### Cause:

* Supabase insert failed
* RLS blocking request

### Fix:

* check permissions
* validate schema

---

## ❌ 3. “AI output missing or malformed”

### Cause:

* worker returned invalid JSON
* schema mismatch

### Fix:

* enforce output schema validation

---

## ❌ 4. “Duplicate grades appear”

### Cause:

* event replay or retry

### Fix:

* implement idempotency key

---

# ⏱ D.6 — Latency Debugging Model

Each worker log includes:

```text id="d6_latency"
latency_ms
```

---

## Interpretation:

| Range      | Meaning                  |
| ---------- | ------------------------ |
| 0–300ms    | healthy                  |
| 300–1500ms | acceptable               |
| 1500ms+    | AI or network bottleneck |

---

# 🧠 D.7 — Event Correlation Strategy

To debug complex flows:

### Use a single event as the root trace:

```text id="d7_trace"
assignment.submitted → trace_id
```

Everything downstream inherits:

* worker logs
* AI outputs
* retries

---

# 🧩 D.8 — Debugging Fanout Systems

When multiple workers run:

---

## Problem:

```text id="d8_fanout"
3 workers → 3 different outcomes
```

---

## Solution:

Always inspect:

* order of execution
* priority values
* endpoint reliability

---

# 🧠 D.9 — Replay Debugging Strategy

Because events are durable:

Inngest

You can:

* re-trigger events
* simulate failures
* reproduce AI outputs

---

## Replay use cases:

* debug bad grading
* fix broken worker logic
* test new AI versions

---

# 🧠 D.10 — AI-Specific Debugging (Critical)

AI failures are NOT traditional bugs.

They fall into 3 categories:

---

## 1. Prompt Drift

Same input → different output

Fix:

* version prompts per worker

---

## 2. Schema Drift

AI returns invalid structure

Fix:

* strict JSON validation

---

## 3. Context Loss

AI receives incomplete payload

Fix:

* ensure full event propagation

---

# 🧩 D.11 — Debugging Mental Model

Think of system as:

```text id="d11_model"
Event → Interpretation → Transformation → Storage
```

NOT:

```text id="d11_wrong"
Function → Output → Done
```

---

# 🧠 D.12 — Golden Debug Rule

> Never debug the UI first.

Always debug in this order:

1. Event
2. Worker
3. AI output
4. UI rendering

---

# 🧠 FINAL INSIGHT

> In Nexus LMS, bugs are not errors — they are **traceable event histories that failed to converge**

Every failure is:

* explainable
* replayable
* fixable

---

If you want next, Appendix E will cover one of the most critical production concerns:

# 🧩 “Security Model (RLS, Plugin Injection, AI Safety, and Multi-Tenant Isolation)”

This is where we harden Nexus LMS into a **production-safe AI platform**.
