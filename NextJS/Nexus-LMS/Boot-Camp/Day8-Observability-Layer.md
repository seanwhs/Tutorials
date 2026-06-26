# 🔵 DAY 8 — OBSERVABILITY LAYER (TRACE EVERYTHING + AI DEBUGGING SYSTEM)

# Nexus LMS Bootcamp (Executable)

---

# 🎯 Goal of Day 8

By the end of today, you will have:

```text id="d8_goal"
✔ Full event trace logging
✔ Worker execution logs stored in DB
✔ AI input/output captured per request
✔ Replayable execution history (foundation)
✔ Debuggable AI pipeline (no black boxes)
```

This is what turns Nexus LMS from a “system” into a **production AI platform**.

---

# 🧠 WHAT CHANGES TODAY

Before:

```text id="d8_before"
Event → worker → output (invisible)
```

After:

```text id="d8_after"
Event → trace → worker → logs → AI output stored → auditable system
```

---

# 🧱 STEP 1 — Create Observability Tables

In Supabase:

Supabase

---

## 1. Event traces

```sql id="d8_sql1"
create table event_traces (
  id uuid primary key default gen_random_uuid(),
  event_name text,
  payload jsonb,
  created_at timestamp default now()
);
```

---

## 2. Worker logs

```sql id="d8_sql2"
create table worker_logs (
  id uuid primary key default gen_random_uuid(),
  worker_name text,
  input jsonb,
  output jsonb,
  latency_ms int,
  created_at timestamp default now()
);
```

---

## 3. AI results audit table

```sql id="d8_sql3"
create table ai_audit_logs (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid,
  score int,
  feedback text,
  raw_response jsonb,
  created_at timestamp default now()
);
```

---

# 🧪 CHECKPOINT 1

Verify tables exist:

```text id="d8_check1"
event_traces ✔
worker_logs ✔
ai_audit_logs ✔
```

---

# 🧠 STEP 2 — Add Event Tracing (Inngest Layer)

Update:

```text id="d8_file1"
app/api/inngest/functions.ts
```

---

## Modify worker:

```ts id="d8_trace1"
import { inngest } from "@/lib/inngest";
import { supabase } from "@/lib/supabase";
import { getWorkers } from "@/lib/registry";

export const assignmentWorker = inngest.createFunction(
  { id: "observability-worker" },
  { event: "assignment.submitted" },
  async ({ event }) => {

    // 1. TRACE EVENT
    await supabase.from("event_traces").insert({
      event_name: event.name,
      payload: event.data
    });

    // 2. FETCH WORKERS
    const workers = await getWorkers(event.name);

    const results = await Promise.all(
      workers.map(async (worker) => {
        const start = Date.now();

        const res = await fetch(worker.endpoint, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(event.data)
        });

        const output = await res.json();
        const end = Date.now();

        // 3. LOG WORKER EXECUTION
        await supabase.from("worker_logs").insert({
          worker_name: worker.name,
          input: event.data,
          output,
          latency_ms: end - start
        });

        return output;
      })
    );

    return {
      success: true,
      results
    };
  }
);
```

---

# 🧪 CHECKPOINT 2

Trigger assignment submission.

✔ Expected:

```text id="d8_expected1"
event_traces populated
worker_logs populated
AI responses stored
```

---

# 🧠 STEP 3 — Capture AI Output (Grading System Upgrade)

Update worker API:

```text id="d8_file2"
app/api/workers/grade/route.ts
```

---

## Replace with:

```ts id="d8_ai_trace"
import { NextResponse } from "next/server";
import { supabase } from "@/lib/supabase";

function fakeAI(content: string) {
  const score = Math.min(100, content.length);

  return {
    score,
    feedback:
      score > 80
        ? "Excellent answer"
        : score > 50
        ? "Good, but improve clarity"
        : "Needs significant improvement"
  };
}

export async function POST(req: Request) {
  const body = await req.json();

  const result = fakeAI(body.content);

  // STORE AI AUDIT LOG
  await supabase.from("ai_audit_logs").insert({
    assignment_id: body.assignmentId,
    score: result.score,
    feedback: result.feedback,
    raw_response: result
  });

  return NextResponse.json(result);
}
```

---

# 🧪 CHECKPOINT 3

Submit assignment again.

✔ Expected:

```text id="d8_expected2"
ai_audit_logs populated
worker_logs populated
event_traces populated
```

---

# 🧠 STEP 4 — Understanding the Observability Model

You now track 3 layers:

---

## 1. Event layer

```text id="d8_layer1"
assignment.submitted
```

---

## 2. Execution layer

```text id="d8_layer2"
worker execution logs
latency tracking
input/output capture
```

---

## 3. AI layer

```text id="d8_layer3"
score + feedback + raw AI output
```

---

# 🧩 CORE INSIGHT

> You are no longer building an LMS.

You are building:

```text id="d8_insight"
an observable AI execution platform
```

---

# 🧠 STEP 5 — Why This Matters

This enables:

---

## 1. Debugging AI behavior

You can answer:

* Why did AI give this score?
* What input did it receive?
* Which worker executed?

---

## 2. Performance tuning

* identify slow workers
* detect bottlenecks

---

## 3. AI auditability

* every decision is stored
* fully reproducible system

---

## 4. Foundation for replay system (next step)

You are now ready for:

> event replay + AI re-execution

---

# 🚀 DAY 8 COMPLETE STATE

```text id="d8_state"
Event tracing: ACTIVE
Worker logs: ACTIVE
AI audit system: ACTIVE
Observability: FULLY FUNCTIONAL
```

---

# 🐛 DEBUG GUIDE

| Issue        | Cause                  | Fix                 |
| ------------ | ---------------------- | ------------------- |
| missing logs | supabase insert failed | check table schema  |
| no AI audit  | worker API not called  | verify endpoint     |
| slow system  | too many logs          | batch inserts later |

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🟣 DAY 9 — ADVANCED PLUGIN SYSTEM (MULTI-WORKER FANOUT + AI MARKETPLACE DESIGN)

We will build:

* multiple workers per event
* worker priority system
* plugin versioning
* external AI tools (Markly-style integrations)
* foundation for LMS plugin marketplace
* true multi-worker orchestration layer
