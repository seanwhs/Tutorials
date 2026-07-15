# Part 7 — Building the Worker SDK: A Standard Contract for Greymatter LMS Workers

In Part 6, we replaced our hardcoded worker list with a real Sanity-based registry, and proved we could toggle a worker on/off without touching any code. But there's still a gap: nothing standardizes *how* a worker receives data, *how* it responds, or *how* we verify the request is legitimate. That's what the Worker SDK solves.

**🎯 Goal of this lesson:** Build a standard TypeScript interface every Greymatter LMS worker must implement, secure worker execution with request signing, and register a real, callable worker end-to-end.

**🧰 Prereqs:** Part 6 completed (Sanity registry with at least one worker document). No new accounts needed — we'll run our worker locally.

---

## 1. Why we need a formal SDK, not just "any HTTP endpoint"

Right now, our registry just stores a plain `endpoint` URL [4], and our Inngest function calls it with a raw `fetch`. That works for a demo, but it means:

* Any endpoint can claim to be a worker, with no verification.
* There's no shared contract for what input a worker receives or what output it must return.
* There's no standard way to register a new worker safely.

The Worker SDK exists to fix all three, and it plugs directly into the worker lifecycle model established earlier: register → discover → validate → execute → monitor → retire [12]. So far we've only built "register" (Part 6) and a naive "execute" (Part 5/6). This part builds proper validation and secure execution.

---

## 2. Defining the Worker contract

Every worker in Greymatter LMS — whether it's grading, quizzes, tutoring, or analytics — must accept the same input shape and return the same output shape. Let's define this in `packages/workers`, the package we scaffolded back in Part 2 specifically for this purpose.

```bash
cd packages/workers
pnpm init
pnpm add zod
```

```typescript
// packages/workers/types.ts
export interface WorkerInput {
  event: string;
  submission: {
    id: string;
    courseId: string;
    userId: string;
    content: string;
  };
}

export interface WorkerOutput {
  workerName: string;
  resultType: string;
  data: Record<string, unknown>;
  success: boolean;
}
```

This mirrors the same "one submission, many independent reactions" shape we've used since Part 0 — grading, plagiarism detection, tutoring, and analytics all consume the same `WorkerInput` [5], just returning different `resultType` values.

---

## 3. The Security Model (critical)

The original tutorial is blunt about this: worker execution must be secured [3]. Right now, our registry stores a raw URL with zero verification of the caller. Let's fix that with HMAC request signing, so a worker can prove a request genuinely came from Greymatter LMS's Inngest functions — not an attacker who found the endpoint.

```bash
pnpm add crypto
```

```typescript
// packages/workers/sign.ts
import { createHmac } from "crypto";

const SECRET = process.env.WORKER_SIGNING_SECRET!;

export function signPayload(payload: unknown): string {
  const body = JSON.stringify(payload);
  return createHmac("sha256", SECRET).update(body).digest("hex");
}

export function verifySignature(payload: unknown, signature: string): boolean {
  const expected = signPayload(payload);
  return expected === signature;
}
```

This directly answers the concern we flagged at the end of Part 6 — that a plain URL with no auth is insecure. Now every call to a worker will carry a signature the worker itself can verify before doing any work, which is one piece of the broader defense-in-depth strategy Greymatter LMS relies on against event-based attacks [1].

---

## 4. Updating the Inngest function to sign requests

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (execute-workers step, updated)
import { signPayload } from "../../../packages/workers/sign";

const results = await step.run("execute-workers", async () => {
  return Promise.all(
    workers.map(async (worker: any) => {
      const payload = { event: "assignment.submitted", submission };
      const signature = signPayload(payload);

      const response = await fetch(worker.endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Greymatter-Signature": signature,
        },
        body: JSON.stringify(payload),
      });

      return { workerName: worker.name, data: await response.json() };
    })
  );
});
```

---

## 5. Building our first real worker

Let's finally stand up the Grading Worker we registered in Sanity back in Part 6, so it's a real, callable service instead of a 404.

```bash
mkdir -p workers/grading-worker
cd workers/grading-worker
pnpm init
pnpm add express
```

```typescript
// workers/grading-worker/index.ts
import express from "express";
import { verifySignature } from "../../packages/workers/sign";
import type { WorkerInput, WorkerOutput } from "../../packages/workers/types";

const app = express();
app.use(express.json());

app.post("/api/grading-worker", (req, res) => {
  const signature = req.headers["x-greymatter-signature"] as string;

  if (!verifySignature(req.body, signature)) {
    return res.status(401).json({ error: "Invalid signature" });
  }

  const input = req.body as WorkerInput;

  // Simulated grading logic — real AI call comes in Part 11
  const output: WorkerOutput = {
    workerName: "Grading Worker",
    resultType: "grading",
    data: { score: 87, feedback: "Solid understanding, minor gaps in edge cases." },
    success: true,
  };

  res.json(output);
});

app.listen(4000, () => console.log("Grading Worker listening on port 4000"));
```

**✅ Checkpoint:** Run this worker with `npx tsx index.ts` (or `ts-node`). Submit an assignment through your Greymatter LMS UI again. This time, open `localhost:8288` and confirm the `execute-workers` step actually succeeds — no more connection error to `localhost:4000`. Check `worker_results` in Drizzle Studio: you should see a real row with `resultType: "grading"` and actual score data.

---

## 6. The Worker Registration Flow

Now that we have a real, secured worker, let's formalize how any new worker — built by us or a third party — gets registered into Greymatter LMS. The registration flow is [3]:

```text
1. Build the worker, implementing WorkerInput/WorkerOutput contract
2. Deploy the worker somewhere reachable (local, Vercel, Railway, etc.)
3. Generate/share a signing secret (WORKER_SIGNING_SECRET)
4. Create a new "worker" document in Sanity Studio:
     - name
     - events (which event(s) it listens to)
     - endpoint (its public URL)
     - enabled: true
5. Publish the document
6. Inngest automatically discovers it on the next matching event
```

Notice step 6 — no code deployment of Greymatter LMS itself is required. This is the same principle we proved in Part 6 by toggling `enabled` off, just now applied to adding something new.

---

## 7. Partial failure tolerance — what happens if a worker breaks

Since workers are executed independently, Greymatter LMS is designed so that one worker failing doesn't take down the others [5]:

```text
Grading Worker  ✓
Quiz Worker     ✗ (endpoint down)
```

Try it yourself: stop your Grading Worker process and resubmit an assignment while Quiz Worker (if you built one) stays up. **✅ Checkpoint:** In `localhost:8288`, you should see the `execute-workers` step report one success and one failure, but `persist-results` still runs and saves whatever succeeded — the system proceeds rather than halting entirely [5].

---

## 8. What's next

We now have a real, standardized Worker SDK: a shared input/output contract, HMAC-signed requests, a working Grading Worker, and a formal registration flow that requires zero changes to Greymatter LMS's core codebase. In Part 8, we go deeper into Inngest itself — designing advanced orchestration patterns including parallel AI execution strategies, result aggregation, conditional workflows, adaptive learning pipelines, and retry/compensation flows [3].

**🩹 Common confusion at this stage:** "Where does `WORKER_SIGNING_SECRET` actually come from, and how do both sides get the same value?" — For now, treat it like any shared API key: generate one random string, store it in both Greymatter LMS's `.env.local` and the worker's own `.env`. In Part 9 (Hardening), we'll cover the full event security model, including how to rotate this secret safely and what else we must defend against on the event surface [1].

Ready? → **Part 8: Inngest Deep Dive — Fan-Out, Fan-In & AI Workflow Composition**
