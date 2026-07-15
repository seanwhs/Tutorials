# Part 10 — Observability, Logging, and AI System Debugging for Greymatter LMS

In Part 9, we hardened the Orchestrator layer against spoofed events, forged worker responses, and cross-tenant leakage, closing out the Threat Model Summary [1]. Now we tackle a different problem: even a secure system is useless to debug if you can't see what's happening inside it when something goes wrong.

**🎯 Goal of this lesson:** Build an event tracing system, an AI worker observability pipeline, debugging tools for failed workflows, a distributed logs architecture, performance monitoring, cost tracking per worker, and learning analytics instrumentation for Greymatter LMS [1].

**🧰 Prereqs:** Part 9 completed (HMAC request/response signing and internal event restrictions in place).

---

## 1. Why observability matters here specifically

Since Part 8 introduced fan-out execution and multi-step event chains (`assignment.submitted → grading.completed → student.struggling → tutor.intervention`), a single student action can now silently touch five or six independent systems. Without tracing, "why didn't the tutor intervention fire?" becomes nearly impossible to answer. The goal of this part is to make sure failures become **diagnosable** — explicitly, no "black box AI behavior" [11].

---

## 2. The execution timeline model

The core mental model for Greymatter LMS observability is a simple per-step timeline, tracking exactly how long each stage of a workflow takes [11]:

```text
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

Let's reproduce this for real. Wrap each `step.run` in our `assignmentSubmitted` function with timing instrumentation:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (instrumented)
async function timedStep<T>(label: string, fn: () => Promise<T>): Promise<T> {
  const start = Date.now();
  const result = await fn();
  const duration = Date.now() - start;
  console.log(`[trace] ${label} (${duration}ms)`);
  return result;
}

export const assignmentSubmitted = inngest.createFunction(
  { id: "assignment-submitted" },
  { event: "assignment.submitted" },
  async ({ event, step }) => {
    const submission = await step.run("fetch-submission", () =>
      timedStep("fetch-submission", async () => {
        return db.query.submissions.findFirst({ where: eq(submissions.id, event.data.submissionId) });
      })
    );

    const workers = await step.run("discover-workers", () =>
      timedStep("discover-workers", async () => findWorkers("assignment.submitted"))
    );

    const results = await step.run("execute-workers", () =>
      timedStep("fan-out execution", async () => {
        return Promise.all(workers.map((w: any) => callWorker(w, submission)));
      })
    );

    await step.run("persist-results", () =>
      timedStep("persist-results", async () => saveResults(submission!.id, results))
    );

    return results;
  }
);
```

**✅ Checkpoint:** Submit an assignment and check your terminal output. You should see a timeline printed exactly like the model above — `fetch-submission (Xms)`, `discover-workers (Xms)`, `fan-out execution (Xms)`, `persist-results (Xms)` [11].

---

## 3. Event tracing across chained functions

Since Part 8 introduced multi-hop chains (`assignment.submitted → student.struggling → practice.assigned`), a single `console.log` per function isn't enough — we need a shared **trace ID** that follows the chain across function boundaries.

```typescript
// infra/inngest/trace.ts
import { randomUUID } from "crypto";

export function withTraceId(data: Record<string, unknown>) {
  return { ...data, traceId: (data.traceId as string) ?? randomUUID() };
}
```

Update every `inngest.send` call to carry the trace ID forward:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (propagate trace)
await internalEmit("student.struggling", withTraceId({
  studentId: submission!.userId,
  submissionId: submission!.id,
  score,
  traceId: event.data.traceId,
}));
```

```typescript
// infra/inngest/functions/studentStruggling.ts (log with same trace)
console.log(`[trace:${event.data.traceId}] tutor-intervention triggered`);
```

**✅ Checkpoint:** Trigger a low-score submission (as in Part 8) and grep your terminal logs for the trace ID — you should be able to follow one `traceId` across both `assignment-submitted` and `student-struggling` function runs, confirming the full chain executed as one logical unit, not two unrelated events.

---

## 4. Persisting logs — a distributed logs table

Console logs disappear when your terminal closes. Let's persist trace events to Neon Postgres so we have permanent, queryable history — matching the same reasoning from Part 4 about why we store event data at all (traceability, retries, analytics, audit logs) [6].

```typescript
// infra/db/schema.ts (add to existing schema)
import { pgTable, uuid, text, timestamp, integer } from "drizzle-orm/pg-core";

export const workflowLogs = pgTable("workflow_logs", {
  id: uuid("id").primaryKey().defaultRandom(),
  traceId: text("trace_id").notNull(),
  step: text("step").notNull(),
  durationMs: integer("duration_ms"),
  status: text("status"), // "success" | "failed"
  errorMessage: text("error_message"),
  createdAt: timestamp("created_at").defaultNow(),
});
```

```typescript
// infra/inngest/trace.ts (add logging helper)
import { db } from "../db";
import { workflowLogs } from "../db/schema";

export async function logStep(traceId: string, step: string, durationMs: number, status: "success" | "failed", errorMessage?: string) {
  await db.insert(workflowLogs).values({ traceId, step, durationMs, status, errorMessage });
}
```

Wire it into `timedStep`:

```typescript
async function timedStep<T>(traceId: string, label: string, fn: () => Promise<T>): Promise<T> {
  const start = Date.now();
  try {
    const result = await fn();
    await logStep(traceId, label, Date.now() - start, "success");
    return result;
  } catch (err: any) {
    await logStep(traceId, label, Date.now() - start, "failed", err.message);
    throw err;
  }
}
```

**✅ Checkpoint:** Run `npx drizzle-kit push` to create the new table, submit a few assignments (including one where you temporarily break the Grading Worker's endpoint), then query `workflow_logs` in Drizzle Studio. You should see a real, permanent execution history — including at least one `status: "failed"` row with a captured error message.

---

## 5. Cost tracking per worker

Since Part 11 introduces real LLM-powered workers with real API costs, it's worth wiring in cost tracking now while the plumbing is fresh. Extend `worker_results` (from Part 4) to include a cost field:

```typescript
// infra/db/schema.ts (extend workerResults)
export const workerResults = pgTable("worker_results", {
  // ...existing fields from Part 4...
  costUsd: integer("cost_usd"), // store as cents to avoid float rounding issues
});
```

Then have each worker report its own cost as part of its `WorkerOutput` (extending the contract from Part 7):

```typescript
// packages/workers/types.ts (extend WorkerOutput)
export interface WorkerOutput {
  workerName: string;
  resultType: string;
  data: Record<string, unknown>;
  success: boolean;
  costCents?: number; // e.g., estimated LLM API cost for this call
}
```

**✅ Checkpoint:** Query `worker_results` grouped by `workerName`, summing `costUsd` — even with our simulated Grading Worker returning `costCents: 0` for now, the column exists and is ready for Part 11's real AI calls.

---

## 6. What we've achieved

To recap directly against this part's stated purpose: failures become diagnosable, and there is no more "black box AI behavior" in Greymatter LMS [11]. We now have a per-step execution timeline, a trace ID that follows chained events across function boundaries, a permanent distributed log table in Neon Postgres, and the groundwork for per-worker cost tracking.

---

## 7. What's next

With tracing, logging, and cost tracking in place, we're ready to build the actual intelligence layer. In Part 11, we build LLM-powered lesson summaries, an automatic quiz generation system, adaptive learning insights, student weakness detection, an AI tutoring layer, and knowledge graph extraction from LMS data [11] — replacing every simulated worker response we've used since Part 5 with real AI calls.

**🩹 Common confusion at this stage:** "Do I need a dedicated logging service like Datadog for this to work?" — Not for this tutorial series. Everything here runs on Neon Postgres and plain `console.log`, which is enough to learn the *pattern* of observability. Swapping `workflowLogs` for a hosted log aggregator later is a drop-in replacement, not a redesign.

Ready? → **Part 11: AI-Native Features — Auto Summaries, Quiz Generation & Learning Intelligence**
