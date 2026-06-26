# 🟣 DAY 7 — PLUGIN REGISTRY (SANITY) + DYNAMIC AI WORKERS (COMPLETE)

# Nexus LMS Bootcamp (Executable)

---

# 🎯 Goal of Day 7

By the end of today, you will have:

```text id="d7_goal"
✔ Sanity CMS connected
✔ AI Workers stored as “plugins”
✔ Dynamic worker discovery (no hardcoding)
✔ Event → registry lookup → execution pipeline
✔ First real plugin-based AI architecture
```

This is the **architectural heart of Nexus LMS**.

---

# 🧠 WHAT CHANGES TODAY

Before:

```text id="d7_before"
Event → hardcoded worker → execution
```

After:

```text id="d7_after"
Event → registry (Sanity) → dynamic workers → execution
```

---

# 🧱 STEP 1 — Initialize Sanity Project

Sanity

Run:

```bash id="d7_init"
npm create sanity@latest
```

Choose:

* Project name: nexus-lms-registry
* Dataset: production
* Template: Clean project

---

# 📁 Sanity structure (important)

```text id="d7_sanity"
sanity/
  schemaTypes/
    worker.ts
  sanity.config.ts
```

---

# 🧠 STEP 2 — Define Worker Schema (PLUGIN CONTRACT)

Create:

```text id="d7_schema_file"
sanity/schemaTypes/worker.ts
```

---

## Paste:

```ts id="d7_worker_schema"
export default {
  name: "worker",
  title: "AI Worker Plugin",
  type: "document",
  fields: [
    {
      name: "name",
      type: "string",
      title: "Worker Name"
    },
    {
      name: "event",
      type: "string",
      title: "Event Trigger"
    },
    {
      name: "endpoint",
      type: "url",
      title: "Worker Endpoint"
    },
    {
      name: "enabled",
      type: "boolean",
      title: "Enabled"
    }
  ]
};
```

---

# 🧪 CHECKPOINT 1

Go to Sanity Studio:

```text id="d7_studio"
http://localhost:3333
```

✔ You should see:

* “AI Worker Plugin” schema
* ability to create workers

---

# 🧠 STEP 3 — Create Example Worker in CMS

Add in Sanity:

```json id="d7_worker_doc"
{
  "name": "AI Grader",
  "event": "assignment.submitted",
  "endpoint": "http://localhost:3000/api/workers/grade",
  "enabled": true
}
```

---

# 🧠 STEP 4 — Create Worker Execution API

Create:

```text id="d7_api"
app/api/workers/grade/route.ts
```

---

## Paste:

```ts id="d7_worker_api"
import { NextResponse } from "next/server";

function fakeAI(content: string) {
  return {
    score: Math.min(100, content.length),
    feedback: content.length > 80
      ? "Strong answer"
      : "Needs more detail"
  };
}

export async function POST(req: Request) {
  const body = await req.json();

  const result = fakeAI(body.content);

  return NextResponse.json(result);
}
```

---

# 🧠 STEP 5 — Create Registry Fetcher

Create:

```text id="d7_registry"
lib/registry.ts
```

---

## Paste:

```ts id="d7_registry_code"
import { createClient } from "@sanity/client";

export const sanity = createClient({
  projectId: "YOUR_PROJECT_ID",
  dataset: "production",
  apiVersion: "2024-01-01",
  useCdn: false
});

export async function getWorkers(eventName: string) {
  return await sanity.fetch(
    `*[_type == "worker" && event == $event && enabled == true]`,
    { event: eventName }
  );
}
```

---

# 🧠 STEP 6 — Replace Hardcoded Worker (CORE SHIFT)

Update:

```text id="d7_inngest"
app/api/inngest/functions.ts
```

---

## Replace with dynamic plugin system:

```ts id="d7_dynamic_worker"
import { inngest } from "@/lib/inngest";
import { getWorkers } from "@/lib/registry";

export const assignmentWorker = inngest.createFunction(
  { id: "dynamic-worker-system" },
  { event: "assignment.submitted" },
  async ({ event }) => {
    const workers = await getWorkers(event.name);

    const results = await Promise.all(
      workers.map(async (worker) => {
        const res = await fetch(worker.endpoint, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(event.data)
        });

        return await res.json();
      })
    );

    console.log("PLUGIN RESULTS:", results);

    return {
      success: true,
      results
    };
  }
);
```

---

# 🧪 CHECKPOINT 2

Trigger:

```text id="d7_test"
Submit assignment
```

✔ Expected:

```text id="d7_expected"
Sanity → worker fetched → API called → AI result returned
```

---

# 🧠 STEP 7 — What You Just Built

This is the **most important architecture upgrade so far**:

---

## BEFORE

```text id="d7_arch_before"
Inngest → hardcoded worker → execution
```

---

## AFTER

```text id="d7_arch_after"
Inngest → Sanity Registry → dynamic workers → execution
```

---

# 🧩 CORE CONCEPT

> Workers are no longer code.

They are now:

```text id="d7_plugins"
configuration-driven AI plugins
```

---

# 🚀 DAY 7 COMPLETE STATE

```text id="d7_state"
AI system: WORKING
Plugin registry: ACTIVE
Dynamic workers: ENABLED
Hardcoding: REMOVED
Architecture: EXTENSIBLE PLATFORM
```

---

# 🐛 DEBUG GUIDE

| Issue               | Cause              | Fix               |
| ------------------- | ------------------ | ----------------- |
| no workers returned | wrong Sanity query | check event field |
| API not called      | wrong endpoint     | verify URL        |
| empty response      | worker disabled    | set enabled=true  |

---

# 🧠 WHY THIS DAY IS IMPORTANT

You just transformed Nexus LMS into:

> a **plugin-based AI execution platform**

This is the foundation of:

* AI marketplaces
* external grading tools (like Markly)
* third-party LMS extensions
* modular AI ecosystems

---

# 👉 NEXT STEP

If you say **“next”**, we move to:

# 🔵 DAY 8 — OBSERVABILITY LAYER (TRACE EVERYTHING + AI DEBUGGING SYSTEM)

We will build:

* full event tracing
* worker execution logs
* AI input/output capture
* debugging dashboard
* production-grade observability layer
* ability to replay AI decisions

This is where Nexus becomes **production-grade AI infrastructure**
