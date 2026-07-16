# Part 10 — Observability: Tracing, Logging & Debugging Greymatter LMS 

In Part 9, we hardened the Orchestrator and Execution layers — closing the spoofed-event gap, reinforcing tenant checks inside Inngest steps, and verifying our HMAC signature checks actually reject forged worker responses [1]. But we ended that part on an honest admission: we still have very little *visibility* into what's happening when something goes wrong. If a worker silently fails, or a chain never fires, our only debugging tool right now is manually reading the Inngest dashboard [1]. This part fixes that.

**🎯 Goal of this lesson:** Build a proper observability system for Greymatter LMS — an event tracing system, an AI worker observability pipeline, debugging tools for failed workflows, a distributed logs architecture, performance monitoring, and cost tracking per worker [1].

**🧰 Prereqs:** Part 9 completed (hardened event surface, all threat-model checks passing locally).

---

## 1. Why observability matters here specifically

Since Part 8 introduced fan-out execution and multi-step event chains (`assignment.submitted → grading.completed → student.struggling → tutor.intervention`), a single student action can now silently touch five or six independent systems [11]. Without tracing, a question as simple as "why didn't the tutor intervention fire?" becomes nearly impossible to answer by just staring at logs scattered across the Grading Worker, the Quiz Worker, and two separate Inngest functions. The goal of this part is to make sure failures become **diagnosable** — explicitly, no more "black box AI behavior" [11].

---

## 2. Designing a trace ID that survives the whole chain

The core mechanism this part introduces is a **trace ID**: a single identifier generated once, at the very start of a request, that gets threaded through every downstream event, worker call, and log line — even across function boundaries [11]. Without this, `assignment-submitted` and `student-struggling` (built separately in Part 8) look like two unrelated runs in the Inngest dashboard, with no way to prove they came from the same student action.

```typescript
// packages/events/trace.ts
import { randomUUID } from "crypto";

export function newTraceId(): string {
  return randomUUID();
}
```

Now thread it through the very first event emission, back in our Server Action from Part 5:

```typescript
// apps/web/src/app/(dashboard)/assignments/actions.ts (trace ID added)
import { newTraceId } from "../../../../../packages/events/trace";

export async function submitAssignment(assignmentId: string, courseId: string, content: string) {
  // ... auth + course ownership checks unchanged from Part 9

  const [submission] = await db.insert(submissions).values({ /* ... */ }).returning();
  const traceId = newTraceId();

  await inngest.send({
    name: "assignment.submitted",
    data: { submissionId: submission.id, traceId },
  });
}
```

And propagate it forward every time one function chains into another, exactly as `student-struggling` does today:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (trace ID propagated)
if (report.score !== null && report.score < 70) {
  await step.run("emit-struggling-event", async () => {
    await inngest.send({
      name: "student.struggling",
      data: { studentId: submission!.userId, submissionId: submission!.id, score: report.score, traceId: event.data.traceId },
    });
  });
}
```

**✅ Checkpoint:** Force a low score again (as in Part 8's conditional-branch checkpoint) and resubmit. In the Inngest dashboard, open both the `assignment-submitted` and `student-struggling` runs it produces, and confirm the exact same `traceId` value appears in each run's event payload — proving they're now provably linked, not just adjacent in time.

---

## 3. Building the distributed logs table

A trace ID is only useful if something actually collects the events it tags. Let's add a permanent log table to the schema we defined back in Part 4 [6], so every step across every function writes a durable, queryable record — not just a line in a dashboard only you are watching [1]:

```typescript
// infra/db/schema.ts (workflowLogs table added)
export const workflowLogs = pgTable("workflow_logs", {
  id: uuid("id").primaryKey().defaultRandom(),
  traceId: text("trace_id").notNull(),
  functionName: text("function_name").notNull(),
  stepName: text("step_name").notNull(),
  status: text("status").notNull(), // "success" | "failed"
  detail: jsonb("detail"),
  createdAt: timestamp("created_at").defaultNow(),
});
```

Run the migration the same way we did in Part 4:

```bash
cd infra/db
npx drizzle-kit push
```

**✅ Checkpoint:** Reopen `npx drizzle-kit studio` and confirm the `workflow_logs` table now exists alongside the five tables from Part 4, empty but real.

Now build a small helper that any Inngest step can call to log its own outcome:

```typescript
// infra/inngest/logging.ts
import { db } from "../db";
import { workflowLogs } from "../db/schema";

export async function logStep(traceId: string, functionName: string, stepName: string, status: "success" | "failed", detail?: unknown) {
  await db.insert(workflowLogs).values({ traceId, functionName, stepName, status, detail: detail ?? {} });
}
```

Wire it into the `execute-workers` step from Part 7/8, so both successes and failures get recorded, not just successes:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (logging added)
import { logStep } from "../logging";

const results = await step.run("execute-workers", async () => {
  return Promise.all(
    workers.map(async (worker: any) => {
      try {
        // ... signed fetch call unchanged from Part 7
        await logStep(event.data.traceId, "assignment-submitted", `execute-${worker.name}`, "success", output);
        return output;
      } catch (err) {
        await logStep(event.data.traceId, "assignment-submitted", `execute-${worker.name}`, "failed", { error: String(err) });
        throw err;
      }
    })
  );
});
```

**✅ Checkpoint:** Resubmit an assignment, then query `workflow_logs` directly (via Drizzle Studio or a quick script) filtered by the `traceId` from that run. Confirm you see one row per worker call, each correctly marked `success` — then stop the Quiz Worker (as we did in Part 8's retry/compensation checkpoint) and resubmit, confirming a `failed` row now appears with the actual error message captured in `detail`, instead of the failure only being visible transiently in the Inngest dashboard [2].

---

## 4. Building an execution timeline view

With `workflow_logs` populated, we can now answer "what happened to this submission, in order?" with a single query instead of hunting across two different systems:

```typescript
// packages/registry/timeline.ts (or a new packages/observability package)
import { db } from "../../infra/db";
import { workflowLogs } from "../../infra/db/schema";
import { eq, asc } from "drizzle-orm";

export async function getTimeline(traceId: string) {
  return db.query.workflowLogs.findMany({
    where: eq(workflowLogs.traceId, traceId),
    orderBy: asc(workflowLogs.createdAt),
  });
}
```

Render this on a simple debug page inside the dashboard:

```tsx
// src/app/(dashboard)/debug/[traceId]/page.tsx
import { getTimeline } from "../../../../../../packages/registry/timeline";

export default async function TimelinePage({ params }: { params: { traceId: string } }) {
  const events = await getTimeline(params.traceId);

  return (
    <div className="p-8">
      <h1 className="text-xl font-bold mb-4">Timeline for {params.traceId}</h1>
      <ul className="space-y-2">
        {events.map((e) => (
          <li key={e.id} className={e.status === "failed" ? "text-red-600" : "text-slate-700"}>
            {e.functionName} → {e.stepName} — {e.status}
          </li>
        ))}
      </ul>
    </div>
  );
}
```

**✅ Checkpoint:** Visit `/debug/<your-trace-id>` for a submission you triggered in section 3. Confirm you see a readable, ordered list of every step that ran — including the failed Quiz Worker call, marked clearly in red — answering exactly the question this part opened with: "why didn't the tutor intervention fire?" [11]

---

## 5. Performance monitoring and per-worker cost tracking

Since each `logStep` call already records a timestamp, we get basic performance monitoring almost for free — the gap between two consecutive rows for the same `traceId` is that step's duration. Let's extend the `detail` field to also capture a rough cost signal, laying groundwork for Part 11's real AI workers, which will have actual per-call token costs [10]:

```typescript
// infra/inngest/logging.ts (cost tracking groundwork added)
export async function logStep(
  traceId: string,
  functionName: string,
  stepName: string,
  status: "success" | "failed",
  detail?: unknown,
  costEstimate?: number
) {
  await db.insert(workflowLogs).values({
    traceId,
    functionName,
    stepName,
    status,
    detail: { ...((detail as object) ?? {}), costEstimate: costEstimate ?? 0 },
  });
}
```

We won't have a real cost figure to pass in until Part 11 wires up actual OpenAI calls [10] — for now, this field just defaults to `0`, but the pipeline is ready the moment real costs exist.

**✅ Checkpoint:** Query `workflow_logs` and confirm every row's `detail` field now includes a `costEstimate` key (currently always `0`), proving the field exists and is being populated end-to-end before we ever attach a real number to it.

---

## 6. What we've achieved

To recap directly against this part's stated purpose: failures become diagnosable, and there is no more "black box AI behavior" in Greymatter LMS [11]. We now have a per-step execution timeline, a trace ID that follows chained events across function boundaries, a permanent distributed log table in Neon Postgres, and the groundwork for per-worker cost tracking.

---

## 7. What's next

With tracing, logging, and cost tracking in place, we're ready to build the actual intelligence layer. In Part 11, we build LLM-powered lesson summaries, an automatic quiz generation system, adaptive learning insights, student weakness detection, an AI tutoring layer, and knowledge graph extraction from LMS data [11] — replacing every simulated worker response we've used since Part 5 with real AI calls, and finally giving our `costEstimate` field a real number to record.

**🩹 Common confusion at this stage:** "Do I need a dedicated logging service like Datadog for this to work?" — Not for this tutorial series. Everything here runs on Neon Postgres and plain `console.log`, which is enough to learn the *pattern* of observability. Swapping `workflowLogs` for a hosted log aggregator later is a drop-in replacement, not a redesign [11].

Ready? → **Part 11: AI-Native Features — Auto Summaries, Quiz Generation & Learning Intelligence**
