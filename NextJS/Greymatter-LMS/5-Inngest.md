# Part 5 — Inngest Workflow Engine: Building the Greymatter LMS Orchestration Layer

In Part 4, we finished the data layer — Neon Postgres, Drizzle schema, and a `submitAssignment` Server Action stub that stopped short of doing anything real. Now we build the Orchestration Layer itself and finally make that stub emit a real event.

**🎯 Goal of this lesson:** Set up Inngest for Greymatter LMS, understand the core workflow structure every event follows, and build our first real, runnable event-driven function — `assignment.submitted`.

**🧰 Prereqs:** Part 4 completed (Neon + Drizzle schema working). Install the Inngest CLI globally or use `npx` — no account signup is required for local dev.

---

## 1. Why an event-driven workflow engine at all

This is the architectural payoff we've been building toward since Part 0. The philosophy behind Greymatter LMS states it plainly: traditional LMS thinking is `User Action → Function Call → Response`, but the AI-native reality is `Event → Multiple AI Systems → Async Results → Aggregation` [13]. Concretely:

```text
Student submits assignment
|
+--> grading AI
+--> plagiarism AI
+--> tutor AI
+--> analytics AI
+--> feedback AI
```

This is no longer a single function call — it's a distributed workflow system [13]. Inngest is the piece of Greymatter LMS that turns this diagram into working, durable, retryable code.

---

## 2. Installing Inngest

```bash
cd apps/web
pnpm add inngest
```

```typescript
// infra/inngest/client.ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "greymatter-lms" });
```

Add an API route so Inngest can reach your functions locally:

```typescript
// apps/web/src/app/api/inngest/route.ts
import { serve } from "inngest/next";
import { inngest } from "../../../../../infra/inngest/client";
import { assignmentSubmitted } from "../../../../../infra/inngest/functions/assignmentSubmitted";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [assignmentSubmitted],
});
```

**✅ Checkpoint:** Run `pnpm dev` in `apps/web`, then in a second terminal run:

```bash
npx inngest-cli dev
```

Visit `localhost:8288` — the Inngest Dev Server dashboard should load and detect your app at `localhost:3000/api/inngest`.

---

## 3. The core workflow structure

Every Greymatter LMS event follows the same shape, straight from the original workflow engine design — event received, fetch context, discover workers, execute workers, validate outputs, persist results, optionally emit new events [5]:

```text
Event Received
↓
Fetch Context (DB)
↓
Discover Workers (Registry)
↓
Execute Workers (Parallel/Sequential)
↓
Validate Outputs
↓
Persist Results
↓
Emit New Events (Optional)
```

We won't have a real registry until Part 6, so for now we'll hardcode a placeholder "discover workers" step and swap it for a real Sanity query next lesson.

---

## 4. Writing our first real Inngest function

```typescript
// infra/inngest/functions/assignmentSubmitted.ts
import { inngest } from "../client";
import { db } from "../../db"; // adjust path to your infra/db client
import { submissions, workerResults } from "../../db/schema";
import { eq } from "drizzle-orm";

export const assignmentSubmitted = inngest.createFunction(
  { id: "assignment-submitted" },
  { event: "assignment.submitted" },
  async ({ event, step }) => {
    // Step 1: Fetch Context (DB)
    const submission = await step.run("fetch-context", async () => {
      return db.query.submissions.findFirst({
        where: eq(submissions.id, event.data.submissionId),
      });
    });

    // Step 2: Discover Workers (placeholder — real registry comes in Part 6)
    const workers = await step.run("discover-workers", async () => {
      return ["grading-worker", "quiz-worker"];
    });

    // Step 3: Execute Workers (Parallel)
    const results = await step.run("execute-workers", async () => {
      return Promise.all(
        workers.map(async (workerName) => ({
          workerName,
          resultType: workerName === "grading-worker" ? "grading" : "quiz",
          data: { message: `Simulated output from ${workerName}` },
        }))
      );
    });

    // Step 4: Persist Results
    await step.run("persist-results", async () => {
      for (const result of results) {
        await db.insert(workerResults).values({
          submissionId: submission!.id,
          workerName: result.workerName,
          resultType: result.resultType,
          resultData: JSON.stringify(result.data),
        });
      }
    });

    return { submissionId: submission!.id, workerCount: results.length };
  }
);
```

Every `step.run` call maps directly onto one box in the workflow diagram above — this isn't a stylistic choice, it's what makes each step independently retryable by Inngest if it fails.

---

## 5. Wiring the frontend to actually emit the event

Back in Part 3, our Server Action just logged to the console. Let's make it real:

```typescript
// src/app/(dashboard)/assignments/actions.ts
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { submissions } from "../../../../../infra/db/schema";
import { inngest } from "../../../../../infra/inngest/client";

export async function submitAssignment(assignmentId: string, courseId: string, content: string) {
  const { userId, orgId } = await auth();
  if (!userId || !orgId) throw new Error("Unauthorized");

  const [submission] = await db
    .insert(submissions)
    .values({ courseId, assignmentId, userId, orgId, content })
    .returning();

  await inngest.send({
    name: "assignment.submitted",
    data: { submissionId: submission.id },
  });

  return { success: true, submissionId: submission.id };
}
```

**✅ Checkpoint:** Submit an assignment through your UI (or call this action directly in a test script). Then open `localhost:8288`, click into the "assignment-submitted" function run, and confirm all four steps — fetch-context, discover-workers, execute-workers, persist-results — show green. Query `worker_results` in Drizzle Studio and confirm two new rows appeared.

---

## 6. Event chaining — a preview of adaptive behavior

The original workflow engine design describes an advanced behavior called event chaining, where workers can emit new events themselves, creating adaptive learning loops [5]:

```text
assignment.submitted
↓
grading.completed
↓
student.struggling
↓
tutor.intervention
```

We won't implement this until Part 8 (Inngest Deep Dive), but it's worth seeing now: nothing about this chain requires the frontend to know it's happening. `assignment.submitted` is the only event Greymatter LMS's UI ever needs to emit — everything downstream is the Orchestration Layer talking to itself.

---

## 7. Why store events at all?

You might wonder why we're persisting rows in `submissions` and `worker_results` rather than just passing data through Inngest directly. The data modelling lesson gives four concrete reasons: debugging AI workflows requires traceability, workers may fail and retry, analytics depend on event history, and audit logs are mandatory in education systems [6]. Inngest's dashboard gives you *execution* history; your database gives you *permanent, queryable* history — you need both.

---

## 8. What's next

We now have a real, running event pipeline: a Server Action emits `assignment.submitted`, Inngest picks it up, runs through fetch → discover → execute → persist, and writes results back to Neon Postgres. The one piece still faked is "discover workers" — right now it's a hardcoded array. In Part 6, we replace that hardcoded array with a real, queryable **Sanity-based worker registry**, so adding a new AI worker becomes a content edit, not a code change.

**🩹 Common confusion at this stage:** "Why does Inngest need its own local dev server (`localhost:8288`) separate from my Next.js app (`localhost:3000`)?" — The dev server simulates the durable, retryable execution engine that Inngest Cloud runs in production. Your Next.js app just exposes the *function definitions* via the `/api/inngest` route; the dev server is what actually calls, retries, and tracks each step.

Ready? → **Part 6: Building the Plugin Registry (Sanity) for Greymatter LMS**
