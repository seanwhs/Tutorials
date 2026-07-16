# Part 6 — Building the Plugin Registry: The Sanity Worker System for Greymatter LMS 

In Part 5, we built our first real Inngest function — `assignment.submitted` — with a working four-step pipeline: fetch context, discover workers, execute workers, persist results [5]. But one piece was deliberately faked: "discover workers" returned a hardcoded array instead of querying anything real [5]. Now we fix that properly by building the actual registry system.

**🎯 Goal of this lesson:** Understand why Greymatter LMS uses Sanity as a real-time, queryable worker registry (not a CMS in the traditional sense), design the worker schema, register a real worker through Sanity Studio, and replace our hardcoded array with a live registry query [4].

**🧰 Prereqs:** Part 5 completed (Inngest running locally). You'll need a free Sanity account (sanity.io) — we'll create a project in section 2 [4].

---

## 1. Why Sanity, and why call it a "registry" instead of a CMS

Sanity is normally pitched as a headless CMS — the kind of tool you'd use to manage blog posts or marketing copy. Greymatter LMS uses it for something structurally similar but conceptually different: a **live, queryable list of which AI workers exist, which events they listen to, and whether they're currently enabled** [12]. Recall Part 1's rule — the Registry Layer is the *only* place allowed to answer "which workers exist" [12]. Inngest's job (Part 5) is to decide an event happened and orchestrate the response; it is never allowed to also decide, by itself, which workers should run [5].

The reason this needs to be a separate, editable system rather than a hardcoded array becomes obvious the moment you imagine adding a second AI capability. With a hardcoded array, adding a Quiz Worker means opening `infra/inngest/functions/assignmentSubmitted.ts`, editing code, and redeploying — exactly the feature-explosion pattern Part 0's `emit()` demo warned about [13]. With a real registry, adding a Quiz Worker means creating one new document in Sanity Studio. No code touched, no redeploy. That's the entire payoff of this part.

---

## 2. Setting up a Sanity project

Following the boundary set back in Part 2 — `infra/sanity` holds registry schemas, kept separate from `apps/web` [8] — initialize Sanity there:

```bash
cd infra/sanity
npx sanity@latest init
```

Follow the prompts to create a free Sanity project and dataset (call it something like `production`). This gives you a `projectId` and `dataset` name — save both, since `apps/web` will need them in section 5 to actually query the registry.

**✅ Checkpoint:** Confirm `npx sanity@latest init` completes and generates a `sanity.config.ts` file inside `infra/sanity`. Nothing is queryable yet — we haven't defined a schema.

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
  name: "greymatter-registry",
  projectId: "your-project-id",
  dataset: "production",
  plugins: [deskTool()],
  schema: {
    types: [worker],
  },
});
```

Walking through each field's job: `name` is the human-readable identifier (`"grading-worker"`); `events` is an array of event names this worker subscribes to (`["assignment.submitted"]`) — a single worker can subscribe to more than one event, and a single event can have more than one subscriber, which is exactly the fan-out pattern Part 8 builds on top of [2]; `endpoint` is the URL Inngest will call; and `enabled` is the on/off switch this entire part's payoff depends on.

**✅ Checkpoint:** Run `npx sanity dev` from inside `infra/sanity` and confirm Sanity Studio opens locally, showing a "Worker" document type in the sidebar, currently empty.

---

## 4. Registering a real worker through Sanity Studio

With the schema live, create your first real registry entry — the Grading Worker, which Part 7 will make fully functional and callable [3]. In Sanity Studio, create a new "Worker" document with:

- `name`: `grading-worker`
- `events`: `["assignment.submitted"]`
- `endpoint`: `http://localhost:4001`
- `enabled`: `true`

Publish it.

**✅ Checkpoint:** Confirm the document appears in Sanity Studio's published documents list, not just as a draft — Inngest will only ever query published content, not drafts.

---

## 5. Building the registry client

Following Part 2's boundary — `packages/registry` is the client used to query the Sanity worker registry [8] — build a small, typed query function there:

```bash
cd packages/registry
npm install @sanity/client
```

```typescript
// packages/registry/index.ts
import { createClient } from "@sanity/client";

const client = createClient({
  projectId: process.env.SANITY_PROJECT_ID!,
  dataset: process.env.SANITY_DATASET ?? "production",
  apiVersion: "2024-01-01",
  useCdn: false,
});

export interface WorkerDefinition {
  name: string;
  events: string[];
  endpoint: string;
  enabled: boolean;
}

export async function findWorkers(eventName: string): Promise<WorkerDefinition[]> {
  return client.fetch(
    `*[_type == "worker" && $eventName in events && enabled == true]`,
    { eventName }
  );
}
```

Notice the query filters on `enabled == true` directly at the database level, not as an afterthought in application code. This single line is the entire mechanism behind this part's core promise: flip a worker's `enabled` flag to `false` in Sanity Studio, and it disappears from every future `findWorkers` result immediately, with zero code deployed.

We keep `useCdn: false` here deliberately — the CDN-backed client trades freshness for speed via caching, and a stale cache would mean toggling `enabled` might not take effect immediately, undermining the whole "real-time" claim in this part's goal.

---

## 6. Replacing the hardcoded array in Part 5's function

Recall Part 5's `discover-workers` step returned a hardcoded array as a deliberate placeholder [5]. Replace it with a real call to `findWorkers`:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts
import { inngest } from "../client";
import { db } from "../../apps/web/src/lib/db";
import { submissions } from "../../infra/db/schema";
import { findWorkers } from "../../packages/registry";
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

    // Step 2: discover workers — now a real Sanity query, not a hardcoded array
    const workers = await step.run("discover-workers", async () => {
      return findWorkers("assignment.submitted");
    });

    const results = await step.run("execute-workers", async () => {
      return workers.map((w) => ({ worker: w.name, output: { status: "simulated" } }));
    });

    await step.run("persist-results", async () => {
      console.log("Persisting results for submission:", submission?.id, results);
    });

    return { submissionId: submission?.id, workerCount: workers.length };
  }
);
```

Notice `execute-workers` still simulates its output — that placeholder is exactly what Part 7 replaces with a real, HMAC-signed HTTP call [3]. This part's job was only ever "discover workers," and that job is now genuinely real.

**✅ Checkpoint:** Submit an assignment through the dashboard (built in Part 3, wired to emit events in Part 5 [7][5]). Open `localhost:8288` and confirm the `discover-workers` step's output now shows your real Sanity document — `grading-worker`, with its actual `endpoint` — instead of the old hardcoded value.

---

## 7. Proving the payoff: toggling `enabled` with zero code changes

This is the moment worth pausing on, because it's the entire reason this part exists. In Sanity Studio, open the `grading-worker` document and flip `enabled` to `false`. Publish it. Submit another assignment through the dashboard, with no code changes and no redeploy anywhere.

**✅ Checkpoint:** Confirm the `discover-workers` step's output is now an empty array — the disabled worker was filtered out at the query level, exactly as designed in section 5. Flip `enabled` back to `true`, publish, and confirm the worker reappears on the next submission. This single toggle is what makes Sanity a *registry*, not just a place to store configuration — it's read live, on every event, with no caching layer standing between an edit and its effect.

---

## 8. What's next

We've replaced our hardcoded worker list with a real, live Sanity registry, proven that toggling `enabled` changes runtime behavior with zero code changes, and confirmed the registry client (`packages/registry`) is a clean, standalone package other layers can depend on. There's still a gap, though: right now anyone could stand up an HTTP endpoint, register it as a worker, and Inngest would call it — with no verification that the request or response is legitimate. In Part 7, we fix this by building a **Worker SDK**: a standard input/output contract every worker must implement, plus HMAC request signing to secure execution end-to-end [4].

**🩹 Common confusion at this stage:** "If `execute-workers` still just simulates a response, what did registering a real `endpoint` actually accomplish?" — Discovery and execution are deliberately separate concerns here, matching Part 5's four-step shape [5]. This part proved the Registry Layer can correctly answer "which workers, with what endpoint, are currently enabled" [12] — Part 7 is what makes `execute-workers` actually call that endpoint over HTTP, with a signed request neither side can forge [3].

Ready? → **Part 7: Building the Worker SDK for Greymatter LMS**
