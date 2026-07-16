# Part 7 — Building the Worker SDK for Greymatter LMS 

In Part 6, we replaced our hardcoded worker list with a real, live Sanity registry, and proved that toggling a worker's `enabled` flag changes runtime behavior with zero code changes [4]. But we left one gap open: right now, anyone could stand up an HTTP endpoint, register it as a worker document, and Inngest would call it — with no verification that the request or response is legitimate. This part closes that gap.

**🎯 Goal of this lesson:** Define a standard input/output contract every worker must implement, secure worker calls with HMAC request signing, build our first real worker (the Grading Worker), and walk through the formal registration flow end-to-end.

**🧰 Prereqs:** Part 6 completed (Sanity registry working, `findWorkers` returning real documents). No new account signups needed — we'll generate our own signing secret locally.

---

## 1. Why a shared contract, not ad hoc endpoints

Recall from Part 1 that the Execution Layer is the **only** place AI logic actually lives, and it's meant to be independently deployable — in any language, anywhere [12]. That only works safely if every worker, regardless of who builds it or what language it's written in, agrees on the exact same shape of data coming in and going out. Without that agreement, Inngest's `execute-workers` step (still a placeholder since Part 5 [5]) would have no reliable way to call a worker or trust its response.

This is exactly why `packages/workers` was scaffolded back in Part 2, specifically to hold this shared contract [8].

---

## 2. Defining the Worker contract

Every worker in Greymatter LMS — whether it's grading, quizzes, tutoring, or analytics — must accept the same input shape and return the same output shape. Let's define this in `packages/workers`, the package we scaffolded back in Part 2 specifically for this purpose [8]:

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

**✅ Checkpoint:** Confirm `packages/workers` type-checks on its own (`pnpm tsc --noEmit` or equivalent), with no dependency on `apps/web` or `infra/inngest` — this package should be importable from *both* sides of a worker call: our orchestrator and any external worker codebase.

---

## 3. Securing worker calls with HMAC signing

Since a worker could be deployed anywhere, on anyone's infrastructure, we need a way to prove that a request genuinely came from Greymatter LMS's orchestrator, and that a response genuinely came from the worker it claims to be from. We do this with HMAC request signing.

First, generate a shared secret and store it in both places that will need it:

```bash
# apps/web/.env.local and infra/inngest/.env
WORKER_SIGNING_SECRET=your-random-shared-secret-here
```

Now build the signing helper inside `packages/workers`:

```typescript
// packages/workers/sign.ts
import { createHmac } from "crypto";

export function signPayload(payload: unknown, secret: string): string {
  const body = JSON.stringify(payload);
  return createHmac("sha256", secret).update(body).digest("hex");
}

export function verifySignature(payload: unknown, signature: string, secret: string): boolean {
  const expected = signPayload(payload, secret);
  return expected === signature;
}
```

Every request Inngest sends to a worker will include this signature in a header; every worker is expected to verify it before doing any real work, and to sign its own response the same way before returning it.

**✅ Checkpoint:** From a quick local test, call `signPayload({ hello: "world" }, "test-secret")` twice with the same input and confirm you get the same signature both times — and a *different* signature if you change either the payload or the secret. This confirms the helper is deterministic and tamper-sensitive, which is exactly the property we're relying on.

---

## 4. Building our first real worker — the Grading Worker

Now let's build an actual worker that implements this contract. This can live in its own small Express (or any HTTP framework) service, deployed independently from the rest of Greymatter LMS:

```typescript
// grading-worker/index.ts
import express from "express";
import { verifySignature, signPayload } from "../packages/workers/sign";
import type { WorkerInput, WorkerOutput } from "../packages/workers/types";

const app = express();
app.use(express.json());

const SECRET = process.env.WORKER_SIGNING_SECRET!;

app.post("/api/grading-worker", (req, res) => {
  const signature = req.header("x-signature") ?? "";
  const input: WorkerInput = req.body;

  if (!verifySignature(input, signature, SECRET)) {
    return res.status(401).json({ error: "Invalid signature" });
  }

  // Placeholder grading logic — replaced with real AI in Part 11
  const score = Math.floor(Math.random() * 41) + 60;

  const output: WorkerOutput = {
    workerName: "grading-worker",
    resultType: "grade",
    data: { score },
    success: true,
  };

  const outSignature = signPayload(output, SECRET);
  res.setHeader("x-signature", outSignature);
  res.json(output);
});

app.listen(4000, () => console.log("Grading Worker listening on :4000"));
```

Note the placeholder scoring logic (`Math.random()`) — we're deliberately keeping the "intelligence" fake for now, so we can fully prove the *contract and security* work before adding a real LLM call in Part 11 [10].

**✅ Checkpoint:** Run this worker locally (`node grading-worker/index.ts` or via `tsx`), then send it a manually-signed test request with `curl` or a script. Confirm a correctly signed request returns a `200` with a signed response, and a request with a tampered or missing signature returns `401 Invalid signature`.

---

## 5. Wiring the real HTTP call into Inngest's `execute-workers` step

Back in Part 5, `execute-workers` just logged a message instead of actually calling anything [5]. Let's make it real:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (execute-workers step, updated)
import { signPayload, verifySignature } from "../../../packages/workers/sign";

const SECRET = process.env.WORKER_SIGNING_SECRET!;

const results = await step.run("execute-workers", async () => {
  return Promise.all(
    workers.map(async (worker) => {
      const input = {
        event: event.name,
        submission: {
          id: submission!.id,
          courseId: submission!.courseId,
          userId: submission!.userId,
          content: submission!.content,
        },
      };

      const signature = signPayload(input, SECRET);

      const res = await fetch(worker.endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-signature": signature },
        body: JSON.stringify(input),
      });

      const output = await res.json();
      const outSignature = res.headers.get("x-signature") ?? "";

      if (!verifySignature(output, outSignature, SECRET)) {
        throw new Error(`Worker ${worker.name} returned an invalid signature`);
      }

      return output;
    })
  );
});
```

**✅ Checkpoint:** With the Grading Worker running (`localhost:4000`) and its Sanity registry document still pointing at that URL (from Part 6 [4]), resubmit an assignment through the dashboard. In the Inngest dashboard, confirm `execute-workers` now shows a real score in its output — not the placeholder `{}` from Part 5 — and confirm `persist-results` writes that score into `worker_results` in Neon.

---

## 6. The formal worker registration flow

This is the payoff of everything in this part: adding a new AI capability to Greymatter LMS should never require touching `apps/web` or `infra/inngest`. Here's the exact repeatable sequence every future worker — Quiz Worker, Tutor Worker, Summary Worker in Part 11 [10] — will follow:

1. **Build** the worker as an independent HTTP service implementing `WorkerInput`/`WorkerOutput`.
2. **Deploy** it somewhere reachable (locally for now; Vercel/Railway in Part 12 [9]).
3. **Generate** (or reuse) a `WORKER_SIGNING_SECRET`, shared between the orchestrator and the worker.
4. **Create a Sanity document** for it — `name`, `events`, `endpoint`, `enabled: true` — exactly as we did for the Grading Worker in Part 6 [4].
5. **Publish** the document in Sanity Studio.
6. **Auto-discovery** — the next time the relevant event fires, `findWorkers()` picks it up automatically, with zero changes to any core file.

**✅ Checkpoint:** As a rehearsal, try disabling the Grading Worker's Sanity document (`enabled: false`) again — same as the Part 6 checkpoint — and confirm `execute-workers` now returns an empty result set with no failed HTTP call, proving steps 4–6 of this flow are what's actually gating execution, not the worker's own code.

---

## 7. What we've built, and what's still open

At this point, Greymatter LMS has a real, standardized Worker SDK: a shared input/output contract, HMAC-signed requests and responses, a working Grading Worker, and a formal registration flow that requires zero changes to Greymatter LMS's core codebase. One thing is still deliberately unresolved: this signing scheme has no secret rotation strategy, and no protection against a captured signature being replayed later. We're flagging that now on purpose — it's addressed properly in Part 9 [1].

---

## 8. What's next

We now have a real, standardized Worker SDK: a shared input/output contract, HMAC-signed requests, a working Grading Worker, and a formal registration flow that requires zero changes to Greymatter LMS's core codebase. In Part 8, we go deeper into Inngest itself — designing advanced orchestration patterns including parallel AI execution strategies, result aggregation, conditional workflows, adaptive learning pipelines, and retry/compensation flows [3].

**🩹 Common confusion at this stage:** "Where does `WORKER_SIGNING_SECRET` actually come from, and how do both sides get the same value?" — For now, treat it like any shared API key: generate one random string, store it in both Greymatter LMS's `.env.local` and the worker's own `.env`. In Part 9 (Hardening), we'll cover the full event security model, including how to rotate this secret safely and what else we must defend against on the event surface [1].

Ready? → **Part 8: Inngest Deep Dive — Fan-Out, Fan-In & AI Workflow Composition**
