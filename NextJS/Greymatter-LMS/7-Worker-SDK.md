# Part 7 — Building the Worker SDK for Greymatter LMS 

In Part 6, we replaced our hardcoded worker list with a real, live Sanity registry, and proved that toggling a worker's `enabled` flag changes runtime behavior with zero code changes [4]. But we left one gap open, flagged explicitly at the end of that part: right now, anyone could stand up an HTTP endpoint, register it as a worker document, and Inngest would call it — with no verification that the request or response is legitimate [4]. This part closes that gap.

**🎯 Goal of this lesson:** Define a standard input/output contract every worker must implement, secure worker calls with HMAC request signing, build our first real worker (the Grading Worker), and walk through the formal registration flow end-to-end [3].

**🧰 Prereqs:** Part 6 completed (Sanity registry working, `findWorkers` returning real documents). No new account signups needed — we'll generate our own signing secret locally [3].

---

## 1. Why a shared contract, not just "any HTTP endpoint"

Right now, Part 5's `execute-workers` step just logs a placeholder instead of actually calling anything [5], and Part 6's registry can tell us a worker's `endpoint`, but nothing about the *shape* of data that endpoint expects or returns [4]. Without a shared contract, every worker could invent its own request/response format, and Inngest would have no reliable way to call any of them generically. So before writing any signing code, we define one shape every worker — Grading today, Quiz and Summary later [2][10] — must implement.

Following Part 2's boundary — `packages/workers` holds "the `WorkerInput`/`WorkerOutput` shape and signing helpers every worker implements, starting in Part 7" [8] — build the contract there:

```typescript
// packages/workers/types.ts
export interface WorkerInput {
  submissionId: string;
  orgId: string;
  studentId: string;
  content: string;
}

export interface WorkerOutput {
  workerName: string;
  resultType: string;
  data: unknown;
  success: boolean;
}
```

Every worker, regardless of what AI logic it eventually runs, receives a `WorkerInput` and must return a `WorkerOutput` with exactly these fields. `resultType` is what lets `worker_results` (built in Part 4 [6]) store fundamentally different kinds of output — a `"grading"` result today, a `"quiz"` result once Part 8 registers a second worker [2], a `"summary"` result once Part 11 adds real AI [10] — in the same table, distinguished by this one string.

---

## 2. Securing worker calls with HMAC signing

Since a worker could be deployed anywhere, on anyone's infrastructure, we need a way to prove that a request genuinely came from Greymatter LMS's orchestrator, and that a response genuinely came from the worker it claims to be from. We do this with HMAC request signing [3].

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

Every request Inngest sends to a worker will include this signature in a header; every worker is expected to verify it before doing any real work, and to sign its own response the same way before returning it [3].

A quick concept note for anyone new to HMAC: this isn't encryption — the payload itself stays readable. What it guarantees is *integrity and authenticity*: only someone who knows `WORKER_SIGNING_SECRET` can produce a signature that matches a given payload, so if even one byte of the payload changes in transit, `verifySignature` fails. This is exactly the same shared-secret idea as the demo in Part 0, just applied to HTTP requests instead of a local function call [13].

**✅ Checkpoint:** From a quick local test, call `signPayload({ hello: "world" }, "test-secret")` twice with the same input and confirm you get the same signature both times — and a *different* signature if you change either the payload or the secret. This confirms the helper is deterministic and tamper-sensitive, which is exactly the property we're relying on [3].

---

## 3. Building the Grading Worker

With a contract and a signing helper in hand, build the first real worker as a small, independent Express service — deliberately outside `apps/web`, since Part 1 established that AI logic belongs only in the Execution Layer [12]:

```typescript
// workers/grading-worker/index.ts
import express from "express";
import { verifySignature, signPayload } from "../../packages/workers/sign";
import type { WorkerInput, WorkerOutput } from "../../packages/workers/types";

const app = express();
app.use(express.json());
const SECRET = process.env.WORKER_SIGNING_SECRET!;

app.post("/api/grading-worker", (req, res) => {
  const signature = req.header("x-signature") ?? "";
  const input: WorkerInput = req.body;

  if (!verifySignature(input, signature, SECRET)) {
    return res.status(401).json({ error: "Invalid signature" });
  }

  // Placeholder grading logic — Part 11 replaces this with a real LLM call
  const output: WorkerOutput = {
    workerName: "grading-worker",
    resultType: "grading",
    data: { score: 85, feedback: "Placeholder feedback." },
    success: true,
  };

  res.setHeader("x-signature", signPayload(output, SECRET));
  res.json(output);
});

app.listen(4000, () => console.log("Grading Worker listening on :4000"));
```

Notice the same `verifySignature`/`signPayload` pair is used on both sides of this exchange: once to check the incoming request is genuinely from our orchestrator, and once to sign the outgoing response so Inngest can confirm it wasn't tampered with either. The grading logic itself is still a placeholder — that's intentional, matching every other "real infrastructure, fake AI" pattern this series has used since Part 5 [5] — Part 11 is where this exact function gets replaced with a genuine LLM call, with "nothing else" about the signing or contract changing [10].

Run it in its own terminal:

```bash
cd workers/grading-worker
npx tsx index.ts
```

**✅ Checkpoint:** With the worker running on `localhost:4000`, use `curl` or a REST client to POST a signed test payload to `/api/grading-worker` and confirm you get back a `200` with a valid `x-signature` header — then deliberately send an unsigned request and confirm you get a `401`.

---

## 4. The formal six-step registration flow

Registering a new worker with Greymatter LMS always follows the same six steps — worth naming explicitly here since Part 8 repeats this exact flow to register a second worker [2], and it's the checklist you'll return to for every future worker:

1. **Define the worker's logic** as an HTTP endpoint implementing the `WorkerInput`/`WorkerOutput` contract from section 1.
2. **Verify incoming signatures** using `verifySignature` before doing any real work.
3. **Sign outgoing responses** using `signPayload` before returning them.
4. **Run the worker** as its own independent process, on its own port.
5. **Register it in Sanity Studio** as a `worker` document — `name`, `events`, `endpoint`, `enabled` — using the exact schema built in Part 6 [4].
6. **Confirm discovery** by calling `findWorkers` from `packages/registry` and checking the new worker appears.

Following step 5, register the Grading Worker in Sanity Studio:

| Field | Value |
|---|---|
| `name` | `grading-worker` |
| `events` | `["assignment.submitted"]` |
| `endpoint` | `http://localhost:4000/api/grading-worker` |
| `enabled` | `true` |

**✅ Checkpoint:** From `packages/registry`, call `findWorkers("assignment.submitted")` and confirm it returns this document with the correct `endpoint` [4].

---

## 5. Wiring real, signed execution into Part 5's function

Recall Part 5's `execute-workers` step was left as a deliberate placeholder that just logged a message instead of calling anything [5]. Replace it with a real, signed HTTP call:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (execute-workers step, updated)
import { signPayload, verifySignature } from "../../packages/workers/sign";
import type { WorkerInput } from "../../packages/workers/types";

const results = await step.run("execute-workers", async () => {
  const payload: WorkerInput = {
    submissionId: submission!.id,
    orgId: submission!.orgId,
    studentId: submission!.studentId,
    content: submission!.content ?? "",
  };
  const signature = signPayload(payload, process.env.WORKER_SIGNING_SECRET!);

  return Promise.all(
    workers.map(async (worker) => {
      const res = await fetch(worker.endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "x-signature": signature,
        },
        body: JSON.stringify(payload),
      });

      const responseSignature = res.headers.get("x-signature") ?? "";
      const output = await res.json();

      if (!verifySignature(output, responseSignature, process.env.WORKER_SIGNING_SECRET!)) {
        throw new Error(`Rejected: response from ${worker.name} failed signature verification`);
      }

      return output;
    })
  );
});
```

Notice this step now does real, bidirectional verification: the outgoing request is signed with `signPayload` before it leaves, and the incoming response is checked with `verifySignature` before we trust it at all — completing the same signing pattern the Grading Worker itself implements [3]. If a response's signature doesn't match, the step throws, and Inngest's durability (introduced back in Part 5) retries that step rather than silently accepting a tampered or corrupted response [5].

**✅ Checkpoint:** Submit an assignment through the dashboard. Confirm in the Inngest dashboard that `execute-workers` now shows a real result object from the Grading Worker — `{ workerName: "grading-worker", resultType: "grading", data: { score: 85, feedback: "Placeholder feedback." }, success: true }` — rather than the old `{ status: "simulated" }` placeholder. As a rehearsal, try disabling the Grading Worker's Sanity document (`enabled: false`) again — same as the Part 6 checkpoint — and confirm `execute-workers` now returns an empty result set with no failed HTTP call, proving steps 4–6 of the registration flow are what's actually gating execution, not the worker's own code [3].

---

## 6. What's next

We now have a complete, secured Execution Layer: a shared `WorkerInput`/`WorkerOutput` contract, HMAC-signed requests and responses, a real callable Grading Worker, and a formal six-step registration flow every future worker will follow. The pipeline from Part 5 through Part 7 is now fully real end-to-end — event emitted, workers discovered, workers executed and verified — with only the *content* of that execution (real grading logic vs. a placeholder score) still left to fill in.

In Part 8, we build on this exact foundation to design advanced orchestration patterns: parallel AI execution, result aggregation, conditional branching, and chained events — registering a second worker using the same six-step flow from section 4 [2].

**🩹 Common confusion at this stage:** "If the Grading Worker's actual grading logic is still just a placeholder score, what did this entire part actually secure?" — This part secured the *transport* — proving a request genuinely came from Greymatter LMS's orchestrator and a response genuinely came from the worker it claims to be from — completely independent of what logic sits behind that response. That separation is deliberate: Part 11 later swaps the placeholder score for a real LLM call by changing only the inside of the `/api/grading-worker` handler, with zero changes to signing, verification, or the registration flow [10].

Ready? → **Part 8: Inngest Deep Dive — Fan-Out, Fan-In & AI Workflow Composition** [3]
