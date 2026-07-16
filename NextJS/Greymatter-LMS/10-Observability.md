# Part 10 — Observability: Tracing, Logging & Debugging Greymatter LMS 

In Part 9, we hardened the Orchestrator and Execution layers — closing the spoofed-event gap, reinforcing tenant checks inside Inngest steps, and verifying our HMAC signature checks actually reject forged worker responses [1]. But we ended that part on an honest admission: we still have very little *visibility* into what's happening when something goes wrong. If a worker silently fails, or a chain never fires, our only debugging tool right now is manually reading the Inngest dashboard [1].

**🎯 Goal of this lesson:** Build a proper observability system for Greymatter LMS — an event tracing system, an AI worker observability pipeline, debugging tools for failed workflows, a distributed logs architecture, performance monitoring, and cost tracking per worker [11].

**🧰 Prereqs:** Part 9 completed (hardened event surface, all threat-model checks passing locally) [11].

---

## 1. Why the Inngest dashboard alone isn't enough

Since Part 8 introduced fan-out execution and event chaining — `assignment.submitted → grading.completed → student.struggling → tutor.intervention` [2] — a single student action can now silently touch several independent systems: two or more parallel workers, an aggregation step, a conditional branch, and a second Inngest function entirely. The Inngest dashboard shows you *one function run at a time*, but it can't easily answer "show me everything that happened as a result of this one student submission, across every function it eventually triggered." That's the specific gap this part closes: a proper distributed logging and tracing layer, built on top of — not replacing — the dashboard we've relied on since Part 5 [5].

---

## 2. Introducing trace IDs

The core mechanism this part introduces is a **trace ID**: a single identifier generated the moment a submission happens, then threaded through every event, every step, and every worker call that follows from it — no matter how many functions or workers get involved downstream.

```typescript
// packages/events/trace.ts
import { randomUUID } from "crypto";

export function newTraceId(): string {
  return randomUUID();
}
```

This gets generated once, at the very first Server Action — the same `submitAssignment` action wired up back in Part 5 [5] — and passed along as part of every event's payload from that point forward:

```typescript
// src/app/(dashboard)/assignments/actions.ts (traceId added)
import { newTraceId } from "../../../../../packages/events/trace";

export async function submitAssignment(assignmentId: string, courseId: string, content: string) {
  const { userId, orgId } = await auth();
  if (!userId || !orgId) throw new Error("Unauthorized");

  const traceId = newTraceId();

  const [submission] = await db
    .insert(submissions)
    .values({ courseId, assignmentId, userId, orgId, content })
    .returning();

  await inngest.send({
    name: "assignment.submitted",
    data: { submissionId: submission.id, traceId },
  });

  return submission;
}
```

Every downstream event this triggers — `student.struggling`, `practice.assigned`, and so on, from the chain built in Part 8 [2] — must carry this same `traceId` forward in its payload. This is what lets us later ask "show me every step, across every function, for this one trace" instead of being stuck function-by-function.

**✅ Checkpoint:** Submit an assignment and confirm, via a temporary `console.log`, that the same `traceId` value appears in both the `assignment.submitted` event payload and any `student.struggling` event it eventually triggers.

---

## 3. Building a distributed logs table

Following the same pattern Part 4 used for `worker_results` [6], add a new table specifically for structured, queryable logs:

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

And a shared logging helper any Inngest function can call from any step:

```typescript
// infra/inngest/logging.ts
import { db } from "../../apps/web/src/lib/db";
import { workflowLogs } from "../db/schema";

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

Notice the `detail` field already includes a `costEstimate` key, defaulting to `0` — we won't have a real cost figure to pass in until Part 11 wires up actual OpenAI calls [10], but the pipeline is built and ready the moment real costs exist, rather than needing a schema change later.

**✅ Checkpoint:** Run the Drizzle migration to add `workflow_logs`, then confirm the table appears (empty) in Drizzle Studio.

---

## 4. Wiring `logStep` into every step of `assignmentSubmitted`

Go back to the function built across Parts 5–9 and wrap each step with a call to `logStep`, both on success and on failure:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (logging added)
import { logStep } from "../logging";

const submission = await step.run("fetch-context", async () => {
  try {
    const record = await db.query.submissions.findFirst({
      where: eq(submissions.id, event.data.submissionId),
    });
    await logStep(event.data.traceId, "assignment-submitted", "fetch-context", "success", record);
    return record;
  } catch (err) {
    await logStep(event.data.traceId, "assignment-submitted", "fetch-context", "failed", { error: String(err) });
    throw err;
  }
});
```

Repeat this same try/log/catch/rethrow shape for `discover-workers`, `execute-workers`, and `persist-results` — every step Parts 5 through 9 already built [5][1]. Nothing about the actual logic of these steps changes; we're only adding a parallel, queryable record of what happened alongside each one.

**✅ Checkpoint:** Submit an assignment, then query `workflow_logs` filtered by that submission's `traceId`. Confirm you see one row per step — `fetch-context`, `discover-workers`, `execute-workers`, `persist-results` — each with a `status` of `"success"`.

---

## 5. Performance monitoring and per-worker cost tracking

Since each `logStep` call already records a timestamp, we get basic performance monitoring almost for free — the gap between two consecutive rows for the same `traceId` is that step's duration. The `detail.costEstimate` field, added in section 3, is what lays the groundwork for Part 11's real AI workers, which will have actual per-call token costs [10].

**✅ Checkpoint:** Query `workflow_logs` and confirm every row's `detail` field now includes a `costEstimate` key (currently always `0`), proving the field exists and is being populated end-to-end before we ever attach a real number to it.

---

## 6. Debugging a failed workflow using trace IDs

This is the actual payoff of everything built above. Simulate a failure — temporarily stop the Quiz Worker (as in Part 8's fan-out checkpoint [2]) or force a rejection (as in Part 9's hardening checks [1]) — then submit an assignment. Instead of digging through the Inngest dashboard function-by-function, query `workflow_logs` for that submission's `traceId` directly:

```sql
SELECT * FROM workflow_logs WHERE trace_id = '...' ORDER BY created_at;
```

**✅ Checkpoint:** Confirm this single query shows the entire story of what happened to one student submission — every step, across every function it touched, in order, with a clear `"failed"` row marking exactly where and why something broke — proving you no longer need to manually reconstruct this from the dashboard alone.

---

## 7. What's next

We now have trace IDs threaded through every event, a distributed `workflow_logs` table, per-step logging wired into our core Inngest function, and the groundwork for real cost tracking once genuine AI calls exist. In Part 11, we replace every simulated worker response we've built since Part 5 — the Grading Worker's `Math.random()` score [3], the Quiz Worker's placeholder output [2] — with real, LLM-powered logic, and finally populate that `costEstimate` field with genuine numbers [10].

**🩹 Common confusion at this stage:** "Why generate the `traceId` in the Server Action instead of letting Inngest generate one itself?" — Because Inngest's own internal run ID only covers a single function invocation, while our `traceId` needs to survive across an entire chain of events — `assignment.submitted → student.struggling → practice.assigned` — that may span several separate function runs [2]. Generating it once, at the very first point a student action occurs, is what lets it act as a consistent thread through the whole chain.

Ready? → **Part 11: AI-Native Features — Replacing Simulation with Real Intelligence in Greymatter LMS**
