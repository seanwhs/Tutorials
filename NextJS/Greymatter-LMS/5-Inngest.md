# Part 5 — Inngest Workflow Engine: Building the Greymatter LMS Orchestration Layer 

In Part 4, we finished the Data Layer — Neon Postgres, a full Drizzle schema covering courses, lessons, enrollments, submissions, and worker results, and a `submitAssignment` Server Action that persisted real data but still stopped short of doing anything with it [6]. Now we build the Orchestration Layer itself and finally make that stub emit a real event.

**🎯 Goal of this lesson:** Set up Inngest for Greymatter LMS, understand the core workflow structure every event follows, and build our first real, runnable event-driven function — `assignment.submitted` [5].

**🧰 Prereqs:** Part 4 completed (Neon + Drizzle schema working, `submitAssignment` writing real rows). Use `npx` to run the Inngest CLI — no account signup is required for local dev, and no global install is needed either [5].

---

## 1. Why an Orchestration Layer at all

Recall Part 1's rule: the Orchestration Layer is the *only* place allowed to decide "this event happened, go run these workers" [12]. It would be technically possible to skip Inngest entirely and just call a grading function directly from the Server Action we wrote in Part 3 and updated in Part 4 [6][7] — but that's precisely the feature-explosion trap Part 0's demo warned about [13]. Inngest gives us three things a plain function call never could:

- **Durability** — if a step fails partway through, Inngest retries just that step, not the whole function from scratch.
- **Fan-out** — multiple independent workers can react to the same event without the emitter knowing they exist (this becomes concrete in Part 8 [2]).
- **Visibility** — every event, every step, every retry is inspectable in a local dashboard, which becomes the backbone of Part 10's observability work [11].

None of that exists yet in our 10-line `emit()` demo from Part 0 [13] — this part is where that toy simulation becomes something durable enough to actually run in production.

---

## 2. Installing and running Inngest

From inside `apps/web`, install the Inngest SDK:

```bash
cd apps/web
npm install inngest
```

Then, in a separate terminal, start the local Inngest dev server — this doesn't require any account or API key for local development:

```bash
npx inngest-cli@latest dev
```

This opens a dashboard at `localhost:8288`. Keep it running in its own terminal tab for the rest of this part — you'll return to it after every checkpoint to confirm what actually ran.

**✅ Checkpoint:** Visit `localhost:8288` and confirm the dashboard loads, showing an empty list of functions and events — there's nothing registered yet, which is expected.

---

## 3. Creating the Inngest client

Following the boundary set back in Part 2 — `infra/inngest` holds orchestration code, kept separate from `apps/web` so both the app and future worker-adjacent code can share it [8] — create the client there:

```typescript
// infra/inngest/client.ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "greymatter-lms" });
```

This single object is what every Server Action uses to `send()` events, and what every workflow function uses to `createFunction()` and listen for them. Keeping it in `infra/inngest` rather than duplicating it inside `apps/web` is the same "one source of truth" reasoning Part 4 used for the Drizzle schema [6].

---

## 4. The core workflow structure — four steps, every time

Every Inngest function in Greymatter LMS follows the same four-step shape, and understanding this shape now saves confusion in every later part:

1. **fetch-context** — load whatever data the event needs from Neon Postgres (e.g., the submission itself).
2. **discover-workers** — figure out which AI workers should run. Today, this is a hardcoded array; Part 6 replaces it with a real Sanity query [4].
3. **execute-workers** — actually call each worker. Today, this just logs a placeholder message; Part 7 wires in a real, HMAC-signed HTTP call [3].
4. **persist-results** — write whatever came back into `worker_results`, using the schema Part 4 built [6].

Wrapping each of these in `step.run(...)` — rather than plain function calls — is what gives us the durability mentioned in section 1: if `execute-workers` throws, Inngest retries *only* that step, not `fetch-context` all over again.

Let's build it:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts
import { inngest } from "../client";
import { db } from "../../apps/web/src/lib/db";
import { submissions } from "../../infra/db/schema";
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

    // Step 2: discover workers (placeholder for now — Part 6 makes this real)
    const workers = await step.run("discover-workers", async () => {
      return [{ name: "grading-worker", endpoint: "http://localhost:4001" }];
    });

    // Step 3: execute workers (placeholder for now — Part 7 makes this real)
    const results = await step.run("execute-workers", async () => {
      return workers.map((w) => ({ worker: w.name, output: { status: "simulated" } }));
    });

    // Step 4: persist results
    await step.run("persist-results", async () => {
      console.log("Persisting results for submission:", submission?.id, results);
      // Real insert into worker_results comes together with Part 7's wiring.
    });

    return { submissionId: submission?.id, workerCount: workers.length };
  }
);
```

Notice steps 2 and 3 are explicitly labeled as placeholders — this mirrors exactly how Part 3's Server Action was left deliberately incomplete [7]. We're not skipping anything; we're sequencing the series so each placeholder gets replaced by the part actually responsible for it: Part 6 for discovery [4], Part 7 for execution [3].

---

## 5. Registering the function with Next.js

Inngest functions need an HTTP endpoint the dev server (and later, Inngest Cloud) can call into. Create the route handler:

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

**✅ Checkpoint:** With `npm run dev` running in `apps/web` and `npx inngest-cli@latest dev` running separately, refresh `localhost:8288`. Confirm `assignment-submitted` now appears in the Functions tab — Inngest has discovered it via the `/api/inngest` route, even though it hasn't run yet.

---

## 6. Wiring the frontend to actually emit the event

Back in Part 3, our Server Action just logged to the console [7]; Part 4 upgraded it to persist a real row in Neon Postgres, but it still stopped there [6]. Let's finish the job and make it emit a real event:

```typescript
// src/app/(dashboard)/courses/actions.ts
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { submissions } from "../../../../../infra/db/schema";
import { inngest } from "../../../../../infra/inngest/client";

export async function submitAssignment(lessonId: string, content: string) {
  const { userId, orgId } = await auth();
  if (!userId || !orgId) throw new Error("Unauthorized");

  const [submission] = await db.insert(submissions).values({
    orgId,
    studentId: userId,
    lessonId,
    content,
  }).returning();

  await inngest.send({
    name: "assignment.submitted",
    data: { submissionId: submission.id },
  });

  return submission;
}
```

This is the *only* event the frontend ever needs to emit [12] — notice it doesn't say anything about grading, quizzes, or tutoring. Everything downstream of this single `inngest.send()` call is the Orchestration Layer talking to itself, exactly as Part 1's end-to-end trace described [12].

**✅ Checkpoint:** Submit an assignment through the dashboard button wired up in Part 3 [7]. Switch to `localhost:8288`, open the Events tab, and confirm an `assignment.submitted` event appears. Click into it and confirm a linked `assignment-submitted` function run shows all four steps — `fetch-context`, `discover-workers`, `execute-workers`, `persist-results` — each completed successfully.

---

## 7. What's next

We now have a real, running event pipeline: a Server Action emits `assignment.submitted`, Inngest picks it up, runs through fetch → discover → execute → persist, and (for now) logs what it would persist. The one piece still faked is "discover workers" — right now it
