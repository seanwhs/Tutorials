# PART 10 — Observability, Logging & AI Debugging

# Tutorial 10: Making Nexus LMS Fully Traceable in Production

---

# Introduction

At this point, Nexus LMS is:

* event-driven
* AI-worker extensible
* multi-tenant secure
* orchestrated via workflows
* plug-in based via registry

Now we solve the hardest production problem:

> When something breaks, how do you know *why*?

In AI-native systems, failure is not rare—it is constant. The difference between a demo system and a production system is:

> observability.

---

# Learning Objectives

By the end of this tutorial, you will understand:

* How to trace events across the entire LMS system
* How to debug AI worker failures
* How to implement structured logging for workflows
* How to track performance and latency per worker
* How to build an event + execution timeline
* How to make AI systems explainable in production

---

# 1. The Observability Problem in AI Systems

Traditional LMS systems fail like this:

```text id="o1"
User reports issue → Dev guesses → DB inspected → fix attempted
```

AI-native LMS systems fail like this:

```text id="o2"
Event → 12 workers → 3 fail → 1 retries → 2 partial outputs → unknown final state
```

Without observability:

* you cannot reproduce bugs
* you cannot evaluate AI quality
* you cannot debug workflows
* you cannot measure system health

---

# 2. Observability Stack Overview

Nexus LMS tracks everything across 4 layers:

```text id="o3"
1. Event Logs
2. Workflow Execution Logs
3. Worker Execution Traces
4. AI Output Metadata
```

---

# 3. Event Tracing System

Every event becomes a trace root.

Example:

```text id="t1"
assignment.submitted (root event)
```

---

## Event log schema

Stored in Supabase:

Supabase

```sql id="t2"
create table event_logs (
  id uuid primary key,
  organization_id uuid,
  event_name text,
  payload jsonb,
  created_at timestamp
);
```

---

## Example record

```json id="t3"
{
  "event_name": "assignment.submitted",
  "payload": {
    "submissionId": "123"
  }
}
```

---

# 4. Workflow Execution Tracing

Each Inngest workflow generates a trace ID.

Powered by Inngest

---

## Execution timeline

```text id="w1"
assignment.submitted
   ↓
fetch-submission (12ms)
   ↓
discover-workers (45ms)
   ↓
fan-out execution (820ms)
   ↓
persist-results (30ms)
```

---

## Workflow logs table

```sql id="w2"
create table workflow_logs (
  id uuid primary key,
  event_id uuid,
  step text,
  duration_ms int,
  status text,
  created_at timestamp
);
```

---

# 5. Worker Execution Tracing

Every AI worker must emit:

* input snapshot
* output snapshot
* latency
* success/failure state

---

## Worker log schema

```sql id="wk1"
create table worker_logs (
  id uuid primary key,
  worker_id text,
  event_name text,
  input jsonb,
  output jsonb,
  latency_ms int,
  status text,
  created_at timestamp
);
```

---

## Example log

```json id="wk2"
{
  "worker_id": "markly",
  "latency_ms": 1200,
  "status": "success",
  "output": {
    "score": 87
  }
}
```

---

# 6. Full System Trace Model

Every LMS operation becomes a **trace tree**:

```text id="tr1"
Event (root)
 ├── Workflow step
 │     ├── Worker A
 │     ├── Worker B
 │     └── Worker C
 └── Aggregation step
```

---

## Trace ID propagation

```typescript id="tr2"
const traceId = event.id;
```

Every subsystem receives:

```json id="tr3"
{
  "traceId": "abc123"
}
```

---

# 7. AI Debugging Strategy

When AI fails, we need answers to:

* What input did it receive?
* Which model was used?
* How long did it take?
* What was returned?
* Did it retry?

---

## Debug payload standard

```json id="d1"
{
  "worker": "markly",
  "model": "gpt-4.1",
  "input": {},
  "output": {},
  "latency": 1200,
  "status": "failed"
}
```

---

# 8. Performance Monitoring

We track:

---

## 8.1 Worker latency

```text id="p1"
Markly: 1200ms
Tutor AI: 2400ms
Analytics: 800ms
```

---

## 8.2 Event processing time

```text id="p2"
assignment.submitted → 3.2s total
```

---

## 8.3 Bottleneck detection

Identify:

* slow workers
* overloaded pipelines
* failing AI models

---

# 9. Cost Tracking for AI Systems

Each worker tracks:

* tokens used
* API calls
* compute cost

---

## Cost schema

```sql id="c1"
create table worker_costs (
  worker_id text,
  event_name text,
  tokens_used int,
  cost_usd float,
  created_at timestamp
);
```

---

## Example

```text id="c2"
Markly: $0.03 per submission
Tutor AI: $0.08 per submission
Quiz Generator: $0.02 per submission
```

---

# 10. Distributed Logging Strategy

Logs are not centralized—they are structured per layer:

```text id="l1"
Frontend logs → UI actions
Backend logs → API actions
Workflow logs → orchestration
Worker logs → AI execution
```

---

# 11. Replayability (Critical Feature)

We can replay any event:

```text id="r1"
Replay: assignment.submitted
```

System re-runs:

* workflows
* worker execution
* aggregation

This enables:

* debugging
* testing new AI models
* backfilling analytics

---

# 12. Observability Dashboard Model

We expose:

* event timelines
* worker performance
* AI success rate
* cost per student
* system bottlenecks

---

## Example dashboard views:

```text id="d2"
- Student AI feedback history
- Assignment processing timeline
- Worker health metrics
- System-wide AI cost tracking
```

---

# 13. Why This Architecture Works

## 13.1 Full traceability

Every decision is logged.

---

## 13.2 AI becomes debuggable

We can inspect:

* inputs
* outputs
* model behavior

---

## 13.3 System becomes measurable

We can optimize:

* speed
* cost
* accuracy

---

## 13.4 Failures become diagnosable

No “black box AI behavior”.

---

## 13.5 Production readiness achieved

This is what separates:

> prototype vs real AI platform

---

# 14. Key Architectural Principle

> If you cannot trace it, you cannot trust it.

---

# Summary

In this tutorial, we built the observability layer:

* event tracing system
* workflow execution logs
* worker-level AI debugging
* performance monitoring
* cost tracking system
* distributed logging architecture
* replayable event system
* full system traceability model

We now have a **fully observable AI-native LMS platform**.

---

# Next Tutorial

## Tutorial 11 — AI-Native Features: Auto Summaries, Quiz Generation & Learning Intelligence

We will now build:

* LLM-powered lesson summaries
* automatic quiz generation system
* adaptive learning insights
* student weakness detection
* AI tutoring layer
* knowledge graph extraction from LMS data
