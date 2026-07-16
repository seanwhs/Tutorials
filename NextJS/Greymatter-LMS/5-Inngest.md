# Part 5 — Inngest Workflow Engine: Building the Greymatter LMS Orchestration Layer 

In Part 4, we finished the Data Layer — Neon Postgres, a full Drizzle schema covering courses, lessons, enrollments, submissions, and worker results, and a `submitAssignment` Server Action stub that stopped short of doing anything real [6]. Now we build the Orchestration Layer itself and finally make that stub emit a real event.

**🎯 Goal of this lesson:** Set up Inngest for Greymatter LMS, understand the core workflow structure every event follows, and build our first real, runnable event-driven function — `assignment.submitted` [5].

**🧰 Prereqs:** Part 4 completed (Neon + Drizzle schema working). Install the Inngest CLI globally or use `npx` — no account signup is required for local dev [5].

---

## 1. Why Inngest sits exactly where it does

Recall the hard rule from Part 1: Inngest is the **only** place that decides "this event happened, go run these workers" [12]. Neither the frontend nor the database is allowed to make that decision — the frontend only emits events, and the database only stores results. This part is where that rule stops being a diagram and becomes real, running code.

---

## 2. Installing and running Inngest locally

```bash
cd infra/inngest
pnpm init
pnpm add inngest
```

Start the local Inngest dev server, which simulates the durable, retryable execution engine that Inngest Cloud runs in production:

```bash
npx inngest-cli@latest dev
```

**✅ Checkpoint:** Visit `localhost:8288` — you should see the Inngest Dev Server dashboard, currently showing no events, since we haven't wired anything up yet [5].

**🩹 Common confusion at this stage:** "Why does Inngest need its own local dev server (`localhost:8288`) separate from my Next.js app (`localhost:3000`)?" — The dev server simulates the durable, retryable execution engine that Inngest Cloud runs in production. Your Next.js app just exposes the *function definitions* via the `/api/inngest` route; the dev server is what actually calls, retries, and tracks each step [5].

---

## 3. Creating the Inngest client

```typescript
// infra/inngest/client.ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "greymatter-lms" });
```

This client is the shared object both the frontend (to `send` events) and our function definitions (to `createFunction`) will import from — matching the same "shared contract, not duplicated logic" principle we used for `packages/events` back in Part 2 [8].

---

## 4. Building the core workflow — `assignment.submitted`

Every event-driven function in Greymatter LMS follows the same four-step shape: fetch context, discover workers, execute, persist. Let's build the real version now, with a temporary hardcoded worker list standing in for the real registry we build in Part 6:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts
import { inngest } from "../client";
import { db } from "../../db";
import { submissions, workerResults } from "../../db/schema";
import { eq } from "drizzle-orm";

export const assignmentSubmitted = inngest.createFunction(
  { id: "assignment-submitted" },
  { event: "assignment.submitted" },
  async ({ event, step }) => {
    // Step 1: fetch context
    const submission = await step.run("fetch-context", async () => {
      return db.query.submissions.findFirst({
        where: eq(submissions.id, event.data.submissionId),
      });
    });

    // Step 2: discover workers (hardcoded for now — replaced in Part 6)
    const workers = await step.run("discover-workers", async () => {
      return [
        { name: "grading-worker", endpoint: "http://localhost:4000/api/grading-worker" },
      ];
    });

    // Step 3: execute
    const results = await step.run("execute-workers", async () => {
      return Promise.all(
        workers.map(async (worker) => {
          console.log(`Would call worker: ${worker.name}`);
          return { workerName: worker.name, success: true, data: {} };
        })
      );
    });

    // Step 4: persist
    await step.run("persist-results", async () => {
      for (const result of results) {
        await db.insert(workerResults).values({
          submissionId: submission!.id,
          workerName: result.workerName,
          resultType: "placeholder",
          data: result.data,
          success: result.success,
        });
      }
    });

    return { submissionId: submission!.id, workersRun: workers.length };
  }
);
```

Notice each stage is wrapped in its own `step.run` — this is deliberate. Each named step is independently retryable and independently visible in the Inngest dashboard, which becomes essential once we start debugging multi-hop chains in Part 8 [2] and tracing execution timelines in Part 10 [11].

---

## 5. Exposing the function via an API route

Inngest needs an HTTP endpoint in our Next.js app to actually invoke functions:

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

**✅ Checkpoint:** With both `pnpm dev` (Next.js) and `npx inngest-cli@latest dev` running, visit `localhost:8288` again. Under the "Functions" tab, you should now see `assignment-submitted` registered and synced [5].

---

## 6. Wiring the frontend to actually emit the event

Back in Part 3, our Server Action just logged to the console [7]. Let's make it real:

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
}
```

Note that this Server Action keeps to exactly the responsibilities defined back in Part 1 and Part 2: auth check, a database write, and a single event emission — nothing more [8]. No grading logic, no worker-calling logic lives here; that boundary is what makes the rest of this series possible.

**✅ Checkpoint:** Submit an assignment through the dashboard form built in Part 3. In the Inngest dashboard (`localhost:8288`), confirm a new run of `assignment-submitted` appears, and that all four steps (`fetch-context`, `discover-workers`, `execute-workers`, `persist-results`) completed successfully. Then check Neon (via `drizzle-kit studio`) and confirm a new row appeared in `worker_results` [6].

---

## 7. What's still faked, on purpose

At this point, two things in our pipeline are intentionally placeholders:

* **`discover-workers`** returns a hardcoded array instead of querying a real registry.
* **`execute-workers`** just logs instead of actually calling an HTTP endpoint.

Both are deliberate scaffolding — we're proving the orchestration shape works end-to-end before adding the complexity of a real registry (Part 6 [4]) and a real, signed worker contract (Part 7 [3]).

---

## 8. What's next

We now have a real, running event pipeline: a Server Action emits `assignment.submitted`, Inngest picks it up, runs through fetch → discover → execute → persist, and writes results back to Neon Postgres. The one piece still faked is "discover workers" — right now it's a hardcoded array. In Part 6, we replace that hardcoded array with a real, queryable **Sanity-based worker registry**, so adding a new AI worker becomes a content edit, not a code change [4].

**🩹 Common confusion at this stage:** "Why does Inngest need its own local dev server (`localhost:8288`) separate from my Next.js app (`localhost:3000`)?" — The dev server simulates the durable, retryable execution engine that Inngest Cloud runs in production. Your Next.js app just exposes the *function definitions* via the `/api/inngest` route; the dev server is what actually calls, retries, and tracks each step [5].

Ready? → **Part 6: Building the Plugin Registry (Sanity) for Greymatter LMS**
