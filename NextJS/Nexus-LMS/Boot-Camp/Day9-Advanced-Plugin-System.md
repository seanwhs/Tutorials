# 🟣 DAY 9 — ADVANCED PLUGIN SYSTEM (FANOUT + PRIORITY + MARKETPLACE FOUNDATION)

# Nexus LMS Bootcamp (Executable)

---

# 🎯 Goal of Day 9

By the end of today, you will have:

```text id="d9_goal"
✔ Multiple workers per event (fan-out system)
✔ Worker priority + ordering
✔ Plugin version support (v1, v2, etc.)
✔ External AI tools integration pattern (Markly-style)
✔ Foundation for AI plugin marketplace
```

This is where Nexus LMS becomes a **real extensible AI platform**, not just a workflow system.

---

# 🧠 WHAT CHANGES TODAY

Before:

```text id="d9_before"
1 event → 1 worker → 1 result
```

After:

```text id="d9_after"
1 event → N workers → prioritized execution → aggregated results
```

---

# 🧱 STEP 1 — Upgrade Worker Schema (Sanity)

Sanity

Update worker schema:

```ts id="d9_schema"
export default {
  name: "worker",
  type: "document",
  fields: [
    { name: "name", type: "string" },
    { name: "event", type: "string" },

    // NEW: priority system
    { name: "priority", type: "number" },

    // NEW: versioning
    { name: "version", type: "string" },

    { name: "endpoint", type: "url" },
    { name: "enabled", type: "boolean" }
  ]
};
```

---

# 🧪 CHECKPOINT 1

In Sanity Studio:

```text id="d9_check1"
Workers now include:
✔ priority
✔ version
✔ enabled
```

---

# 🧠 STEP 2 — Create Multiple Workers in CMS

Add these workers in Sanity:

---

## Worker 1 — Grader

```json id="d9_worker1"
{
  "name": "AI Grader",
  "event": "assignment.submitted",
  "priority": 1,
  "version": "1.0",
  "endpoint": "http://localhost:3000/api/workers/grade",
  "enabled": true
}
```

---

## Worker 2 — Feedback Enhancer

```json id="d9_worker2"
{
  "name": "Feedback Enhancer",
  "event": "assignment.submitted",
  "priority": 2,
  "version": "1.0",
  "endpoint": "http://localhost:3000/api/workers/feedback",
  "enabled": true
}
```

---

## Worker 3 — Analytics Generator

```json id="d9_worker3"
{
  "name": "Analytics Worker",
  "event": "assignment.submitted",
  "priority": 3,
  "version": "1.0",
  "endpoint": "http://localhost:3000/api/workers/analytics",
  "enabled": true
}
```

---

# 🧠 STEP 3 — Add New Worker APIs

---

## 3.1 Feedback Worker

```text id="d9_file1"
app/api/workers/feedback/route.ts
```

```ts id="d9_feedback"
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const { content } = await req.json();

  return NextResponse.json({
    suggestions: [
      "Add more structure",
      "Use examples",
      "Clarify key points"
    ],
    improvedVersion: content + " (improved)"
  });
}
```

---

## 3.2 Analytics Worker

```text id="d9_file2"
app/api/workers/analytics/route.ts
```

```ts id="d9_analytics"
import { NextResponse } from "next/server";

export async function POST(req: Request) {
  const { content } = await req.json();

  return NextResponse.json({
    wordCount: content.length,
    complexity: content.length > 100 ? "high" : "low",
    sentiment: "neutral"
  });
}
```

---

# 🧠 STEP 4 — Upgrade Registry Query (SORT + FILTER)

Update:

```text id="d9_file3"
lib/registry.ts
```

---

## Replace with:

```ts id="d9_registry"
export async function getWorkers(eventName: string) {
  const workers = await sanity.fetch(
    `*[_type == "worker" && event == $event && enabled == true]
     | order(priority asc)`,
    { event: eventName }
  );

  return workers;
}
```

---

# 🧠 STEP 5 — Upgrade Inngest Fan-out System

Update:

```text id="d9_file4"
app/api/inngest/functions.ts
```

---

## Replace with:

```ts id="d9_fanout"
import { inngest } from "@/lib/inngest";
import { getWorkers } from "@/lib/registry";
import { supabase } from "@/lib/supabase";

export const assignmentWorker = inngest.createFunction(
  { id: "fanout-worker-system" },
  { event: "assignment.submitted" },
  async ({ event }) => {

    const workers = await getWorkers(event.name);

    const results = [];

    for (const worker of workers) {
      const start = Date.now();

      const res = await fetch(worker.endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(event.data)
      });

      const output = await res.json();
      const latency = Date.now() - start;

      await supabase.from("worker_logs").insert({
        worker_name: worker.name,
        input: event.data,
        output,
        latency_ms: latency
      });

      results.push({
        worker: worker.name,
        output
      });
    }

    return {
      success: true,
      fanout_count: workers.length,
      results
    };
  }
);
```

---

# 🧪 CHECKPOINT 2

Submit assignment.

✔ Expected:

```text id="d9_expected"
3 workers executed in order:
1. Grader
2. Feedback
3. Analytics
```

---

# 🧠 STEP 6 — Understand the Fanout Model

You now have:

---

## Execution flow

```text id="d9_flow"
Event
 ↓
Registry fetch
 ↓
Sort by priority
 ↓
Fan-out execution
 ↓
Multiple AI outputs
 ↓
Logged per worker
```

---

## Key insight:

> One event now produces multiple AI perspectives

---

# 🧠 STEP 7 — Plugin Marketplace Foundation

This architecture now supports:

---

## 1. External AI tools

Example:

```text id="d9_external"
Markly AI Grader → plug into endpoint
```

---

## 2. Third-party workers

Anyone can add:

* grading AI
* tutoring AI
* analytics AI

---

## 3. Versioning

```text id="d9_version"
v1 → simple grading
v2 → LLM-powered grading
v3 → multimodal grading
```

---

## 4. Marketplace vision

Eventually:

```text id="d9_market"
Install worker → enable → runs automatically
```

---

# 🚀 DAY 9 COMPLETE STATE

```text id="d9_state"
Fanout system: ACTIVE
Multiple workers: ENABLED
Priority system: WORKING
Plugin architecture: MATURE
Marketplace foundation: READY
```

---

# 🐛 DEBUG GUIDE

| Issue                | Cause                | Fix                  |
| -------------------- | -------------------- | -------------------- |
| workers not ordered  | missing sort         | check priority field |
| only one worker runs | registry query wrong | verify event name    |
| API mismatch         | endpoint wrong       | test manually        |

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🟣 DAY 10 — PRODUCTION ARCHITECTURE (DEPLOYMENT + SCALING + FINAL SYSTEM DESIGN)

We will build:

* full production deployment model
* Vercel + Supabase + worker scaling
* CI/CD pipelines
* environment separation (dev/staging/prod)
* disaster recovery strategy
* final Nexus LMS reference architecture

This is the **final transformation into production-grade AI platform**
