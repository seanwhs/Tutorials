# Part 6 — Building the Plugin Registry: The Sanity Worker System for Greymatter LMS 

In Part 5, we built our first real Inngest function — `assignment.submitted` — with a working four-step pipeline: fetch context, discover workers, execute workers, persist results [5]. But one piece was deliberately faked: "discover workers" returned a hardcoded array instead of querying anything real [5]. Now we fix that properly by building the actual registry system.

**🎯 Goal of this lesson:** Understand why Greymatter LMS uses Sanity as a real-time, queryable worker registry (not a CMS in the traditional sense), design the worker schema, register a real worker through Sanity Studio, and replace our hardcoded array with a live registry query [4].

**🧰 Prereqs:** Part 5 completed (Inngest running locally). You'll need a free Sanity account (sanity.io) — we'll create a project in section 2 [4].

---

## 1. Why a registry, not just a config file

Recall the rule from Part 1: Sanity is the **only** place that knows "these workers exist and listen to these events" [12]. It would be simpler to just keep an array of workers in a TypeScript file somewhere in `infra/inngest` — but that array would live *inside* the Orchestration Layer's codebase, meaning every new worker would require a code change and a redeploy. A real registry lets us add, disable, or swap a worker as a **content edit**, with zero code changes to Inngest or the frontend — proving the "new AI feature = new worker, no core changes" promise from Part 5 concretely [5].

---

## 2. Creating a Sanity project

```bash
cd infra/sanity
pnpm dlx sanity@latest init
```

Follow the prompts to create a new project (choose the "Clean project with no predefined schemas" template) and note your **Project ID** — you'll need it in section 5.

**✅ Checkpoint:** Run `pnpm dlx sanity@latest dev` from `infra/sanity` and visit the local Sanity Studio URL it prints (typically `localhost:3333`). You should see an empty Studio with no document types yet [4].

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

**✅ Checkpoint:** Restart `pnpm dlx sanity@latest dev` and confirm a "Worker" document type now appears in the Studio sidebar. Click "Create new Worker" and confirm the four fields (`name`, `events`, `endpoint`, `enabled`) all render correctly [4].

---

## 4. Registering our first real worker document

Using the Studio UI you just confirmed works, create one document:

| Field | Value |
|---|---|
| `name` | `Grading Worker` |
| `events` | `["assignment.submitted"]` |
| `endpoint` | `http://localhost:4000/api/grading-worker` |
| `enabled` | `true` |

Click **Publish**. This single document is what turns "discover workers" from a hardcoded array into a real, queryable fact.

**✅ Checkpoint:** In the Studio's "Vision" tab (a built-in GROQ query tester), run `*[_type == "worker"]` and confirm your Grading Worker document is returned as JSON.

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

**✅ Checkpoint:** From a temporary test script (or `tsx` one-liner) inside `packages/registry`, call `findWorkers("assignment.submitted")` and confirm it returns an array containing your Grading Worker document — not an empty array, and not an error.

---

## 6. Replacing the hardcoded array in our Inngest function

Now go back to the `assignmentSubmitted` function we built in Part 5 and swap the placeholder `discover-workers` step for a real registry call:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (discover-workers step, updated)
import { findWorkers } from "../../../packages/registry";

// Step 2: discover workers (now real!)
const workers = await step.run("discover-workers", async () => {
  return findWorkers("assignment.submitted");
});
```

Everything downstream — `execute-workers` and `persist-results` — stays exactly as it was in Part 5 [5]. Only the source of the worker list changed, from a hardcoded array to a live Sanity query.

**✅ Checkpoint:** Resubmit an assignment through the dashboard (built in Part 3 [7]). In the Inngest dashboard (`localhost:8288`), confirm the `discover-workers` step now shows your real Grading Worker document as its output, instead of the placeholder array from Part 5.

---

## 7. Proving the "content edit, not code change" promise

This is the checkpoint that matters most in this part — not just that the registry *works*, but that it behaves the way Part 1's service boundaries promised [12].

Go back into Sanity Studio and toggle `enabled` to `false` on your Grading Worker document. Publish the change. **Do not touch any code.**

**✅ Checkpoint:** Resubmit an assignment. In the Inngest dashboard, confirm the `discover-workers` step now returns an **empty array**, and no worker is called. Then flip `enabled` back to `true`, publish, and resubmit — confirm the Grading Worker is discovered again. You just disabled and re-enabled an AI capability in a production-shaped system with zero deploys — this is the exact mechanism Part 7's registration flow and Part 11's new AI workers both depend on [3].

---

## 8. What's next

We've replaced our hardcoded worker list with a real, live Sanity registry, proven that toggling `enabled` changes runtime behavior with zero code changes, and confirmed the registry client (`packages/registry`) is a clean, standalone package other layers can depend on. There's still a gap, though: right now anyone could stand up an HTTP endpoint, register it as a worker, and Inngest would call it — with no verification that the request or response is legitimate. In Part 7, we fix this by building a **Worker SDK**: a standard input/output contract every worker must implement, plus HMAC request signing to secure execution end-to-end [3].

**🩹 Common confusion at this stage:** "If anyone can create a Sanity document with any `endpoint` URL, what stops a malicious or broken worker from being registered?" — Nothing yet, and that's intentional at this stage of the series so the registry mechanism itself stays simple to learn. Part 7 introduces the signed request/response contract that closes this gap [3], and Part 9's threat model explicitly revisits "disabled/malicious worker still executing" as a threat whose defense is exactly the `enabled` flag check you just tested in section 7 [1].

Ready? → **Part 7: Building the Worker SDK for Greymatter LMS**
