# Part 6 — Building the Plugin Registry: The Sanity Worker System for Greymatter LMS

In Part 5, we built our first real Inngest function — `assignment.submitted` — but it used a hardcoded array of worker names as a placeholder for "worker discovery." Now we fix that properly by building the actual registry system.

**🎯 Goal of this lesson:** Understand why Greymatter LMS uses Sanity as a real-time, queryable worker registry (not a CMS in the traditional sense), design the worker schema, register a real worker through Sanity Studio, and replace our hardcoded array with a live registry query.

**🧰 Prereqs:** Part 5 completed (Inngest running locally). You'll need a free Sanity account (sanity.io) — we'll create a project in section 2.

---

## 1. Why we need a dynamic registry at all

Back in Part 0, we established that AI is not a feature bolted onto the LMS — it's a pluggable execution layer [13]. But a pluggable layer is useless if "which plugins exist" is still hardcoded somewhere in your codebase. The philosophy behind this part is explicit:

> "We need a dynamic registry: not code-based, not config files, not environment variables. We need a **queryable system of record**." [13]

Without this, adding a new AI worker means: `Code → Integration → Deployment` — a full release cycle every time. With a registry, it becomes: `Sanity Registry → Worker Discovery → Runtime Execution` — adding a new capability is just **inserting a document**, not modifying the system [13].

This is also confirmed at the system-architecture level — Sanity's role in Greymatter LMS is described as "not content management," but rather a "runtime registry for AI capabilities" that stores workers, tool definitions, schemas, and execution metadata [12].

---

## 2. Setting up Sanity for Greymatter LMS

```bash
cd infra/sanity
pnpm dlx sanity@latest init --project-name "greymatter-lms-registry"
```

Follow the prompts — choose "Clean project with no predefined schemas" since we're not using Sanity for content, we're using it purely as a plugin registry [4].

---

## 3. Designing the worker schema

The registry needs to store worker definitions, event subscriptions, input/output schemas, and enable/disable flags [12]. Here's the schema, adapted directly from the original registry design [8]:

```typescript
// infra/sanity/schemas/worker.ts
export default {
  name: "worker",
  type: "document",
  fields: [
    { name: "name", type: "string" },
    { name: "events", type: "array", of: [{ type: "string" }] },
    { name: "endpoint", type: "url" },
    { name: "enabled", type: "boolean" },
  ],
};
```

*(schema structure adapted from the original `infra/sanity` worker registry definition [8])*

Register the schema in your Sanity config:

```typescript
// infra/sanity/sanity.config.ts
import { defineConfig } from "sanity";
import { deskTool } from "sanity/desk";
import worker from "./schemas/worker";

export default defineConfig({
  name: "greymatter-lms-registry",
  projectId: "your-project-id",
  dataset: "production",
  plugins: [deskTool()],
  schema: {
    types: [worker],
  },
});
```

**✅ Checkpoint:** Run `pnpm dev` inside `infra/sanity`. Sanity Studio should open locally, showing a "Worker" document type ready to be filled in — no blog posts, no pages, just workers.

---

## 4. Registering your first real worker

Instead of writing code to add a worker, open Sanity Studio in the browser and create a new "Worker" document by hand:

```json
{
  "name": "Grading Worker",
  "enabled": true,
  "events": ["assignment.submitted"],
  "endpoint": "http://localhost:4000/api/grading-worker"
}
```

This mirrors the exact worker shape used throughout the series — for example, "Markly Grader" registered against `assignment.submitted` with an endpoint and a capabilities list [12], and the "Quiz Generator" registered against `lesson.completed` [13]. Add a second worker too, so we have something to actually discover:

```json
{
  "name": "Quiz Worker",
  "enabled": true,
  "events": ["assignment.submitted"],
  "endpoint": "http://localhost:4000/api/quiz-worker"
}
```

**✅ Checkpoint:** Click "Publish" on both documents in Sanity Studio. You now have two real, queryable worker records — no code deployment required.

---

## 5. Building the Registry Client package

Recall from Part 2 that `packages/registry` exists specifically to talk to Sanity, with responsibilities limited to fetching workers, validating schemas, filtering by event type, and managing enable/disable state [8]. Let's build it for real:

```bash
cd packages/registry
pnpm add @sanity/client
```

```typescript
// packages/registry/index.ts
import { createClient } from "@sanity/client";

const sanity = createClient({
  projectId: "your-project-id",
  dataset: "production",
  apiVersion: "2024-01-01",
  useCdn: false,
});

export async function findWorkers(event: string) {
  return sanity.fetch(
    `*[_type == "worker" && "${event}" in events && enabled == true]`
  );
}
```

*(function adapted directly from the original registry client implementation [8])*

This is our "worker discovery" query — and notice it maps exactly to the design principle from Part 5: **workers are NOT hardcoded, they come from the registry, stored in Sanity** [5].

---

## 6. Wiring the real registry into our Inngest function

Now we go back and fix the placeholder from Part 5:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts
import { inngest } from "../client";
import { db } from "../../db";
import { submissions, workerResults } from "../../db/schema";
import { findWorkers } from "../../../packages/registry";
import { eq } from "drizzle-orm";

export const assignmentSubmitted = inngest.createFunction(
  { id: "assignment-submitted" },
  { event: "assignment.submitted" },
  async ({ event, step }) => {
    const submission = await step.run("fetch-context", async () => {
      return db.query.submissions.findFirst({
        where: eq(submissions.id, event.data.submissionId),
      });
    });

    // Real worker discovery — replaces the hardcoded array from Part 5
    const workers = await step.run("discover-workers", async () => {
      return findWorkers("assignment.submitted");
    });

    const results = await step.run("execute-workers", async () => {
      return Promise.all(
        workers.map(async (worker: any) => {
          const response = await fetch(worker.endpoint, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ submission }),
          });
          return { workerName: worker.name, data: await response.json() };
        })
      );
    });

    await step.run("persist-results", async () => {
      for (const result of results) {
        await db.insert(workerResults).values({
          submissionId: submission!.id,
          workerName: result.workerName,
          resultType: "unknown",
          resultData: JSON.stringify(result.data),
        });
      }
    });

    return { submissionId: submission!.id, workerCount: results.length };
  }
);
```

**✅ Checkpoint:** Submit an assignment again through your UI. Open `localhost:8288` and confirm the `discover-workers` step now returns real data pulled from Sanity — two worker objects with real names and endpoints, not the hardcoded strings from Part 5. (The `execute-workers` step will fail right now since `localhost:4000` doesn't exist yet — that's expected. We build real worker endpoints in Part 7.)

---

## 7. Toggling a worker off — proving the point

This is the payoff moment. Go back into Sanity Studio, open the "Quiz Worker" document, and flip `enabled` to `false`. Publish it. Submit another assignment.

**✅ Checkpoint:** The `discover-workers` step should now return only one worker — Grading Worker. You didn't touch a single line of code, redeploy anything, or restart any service. This is exactly the principle stated back in Part 5: **"New AI feature = new worker. No core changes."** [5]

---

## 8. What we've built

To recap what this tutorial covered, matching the original summary of this stage: a Sanity-based worker registry, event → worker mapping, capability-based discovery, and the foundation for a fully dynamic AI plug-in ecosystem [4]. Compared to hardcoding, Sanity here is functioning as "a real-time, queryable plug-in registry" [4] — deliberately not used as a traditional content management system.

---

## 9. What's next

We now have workers being *discovered* dynamically, but the endpoints they point to don't exist yet, and there's no standard contract for what a "worker" must accept or return. In Part 7, we build the official **Worker SDK** — a standardized interface (in both TypeScript and Python) so any AI tool, written by anyone, can plug into Greymatter LMS safely and consistently [3].

**🩹 Common confusion at this stage:** "Why store `endpoint` as a plain URL with no auth in the schema — isn't that insecure?" — Good instinct. Right now, any worker endpoint is called with zero verification of who's calling it or whether the payload is trustworthy. We'll fix this properly in Part 7 with HMAC request signing [3], and again in Part 9 (Hardening), where we enforce that workers never access the database directly, never call other workers, and never bypass the registry [1].

Ready? → **Part 7: Building the Worker SDK for Greymatter LMS**
