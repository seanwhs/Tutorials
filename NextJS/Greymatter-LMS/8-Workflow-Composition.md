# Part 8 — Inngest Deep Dive: Fan-Out, Fan-In & AI Workflow Composition for Greymatter LMS 

In Part 7, we built a standardized Worker SDK — a shared input/output contract, HMAC-signed requests, a real, callable Grading Worker, and a formal registration flow for adding new workers with zero core changes [3]. Now we go deeper into Inngest itself and design the advanced orchestration patterns that make Greymatter LMS genuinely adaptive, not just event-triggered [2].

**🎯 Goal of this lesson:** Build real parallel (fan-out) AI execution with a second worker, aggregate results into a unified report (fan-in), add conditional branching, chain events together into an adaptive learning loop, and understand how Greymatter LMS tolerates partial failure [2].

**🧰 Prereqs:** Part 7 completed (Grading Worker running locally, signed requests working) [2].

---

## 1. What this part covers

Following directly from where Part 7 left off, this part designs advanced orchestration patterns: parallel AI execution strategies, result aggregation systems, conditional workflows, adaptive learning pipelines, retry + compensation flows, and production-grade AI workflow design patterns [3].

---

## 2. Registering a second worker — the Quiz Worker

Fan-out is only interesting once there's more than one worker to fan out *to*. Let's apply the exact six-step registration flow from Part 7 [3] to build a second worker: a Quiz Worker, still using placeholder logic for now (real AI arrives in Part 11 [10]).

```typescript
// workers/quiz-worker/index.ts
import express from "express";
import { verifySignature, signPayload } from "../../packages/workers/sign";
import type { WorkerInput, WorkerOutput } from "../../packages/workers/types";

const app = express();
app.use(express.json());
const SECRET = process.env.WORKER_SIGNING_SECRET!;

app.post("/api/quiz-worker", (req, res) => {
  const signature = req.header("x-signature") ?? "";
  const input: WorkerInput = req.body;

  if (!verifySignature(input, signature, SECRET)) {
    return res.status(401).json({ error: "Invalid signature" });
  }

  const output: WorkerOutput = {
    workerName: "quiz-worker",
    resultType: "quiz",
    data: { questions: ["Placeholder question 1?", "Placeholder question 2?"] },
    success: true,
  };

  res.setHeader("x-signature", signPayload(output, SECRET));
  res.json(output);
});

app.listen(4001, () => console.log("Quiz Worker listening on :4001"));
```

Now register it in Sanity Studio, following the exact same document shape used for the Grading Worker in Part 6 [4]:

| Field | Value |
|---|---|
| `name` | `Quiz Worker` |
| `events` | `["assignment.submitted"]` |
| `endpoint` | `http://localhost:4001/api/quiz-worker` |
| `enabled` | `true` |

**✅ Checkpoint:** From `packages/registry`, call `findWorkers("assignment.submitted")` again and confirm it now returns **two** documents — Grading Worker and Quiz Worker — not one [4].

---

## 3. Fan-out — running multiple AI workers in parallel

We now have two workers registered in Sanity (Grading Worker, Quiz Worker), and Part 7 gave us a real signed-execution pattern [2]. Fan-out simply means: when `assignment.submitted` fires, **every matching worker runs at the same time**, not one after another.

Our `execute-workers` step from Part 7 already does this implicitly via `Promise.all` [2], but let's make the aggregation explicit and visible, matching the unified-report pattern from the original design:

```text
Grading Score: 87
Tutor Feedback: "Improve clarity"
Analytics: "Struggling in recursion"
Quiz: Generated
       ↓
Unified Learning Report
```
[2]

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (fan-out step, updated)
const results = await step.run("execute-workers", async () => {
  return Promise.all(
    workers.map(async (worker: any) => {
      const payload = { event: "assignment.submitted", submission };
      const signature = signPayload(payload, SECRET);

      const res = await fetch(worker.endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-signature": signature },
        body: JSON.stringify(payload),
      });

      return res.json();
    })
  );
});
```

**✅ Checkpoint:** Submit an assignment with both workers running (`localhost:4000` and `localhost:4001`). In `localhost:8288`, confirm `execute-workers` returns an array with **two** entries — one `resultType: "grading"`, one `resultType: "quiz"` — and that both requests actually ran concurrently, not sequentially (you can confirm this by checking the step's duration is close to the *slower* of the two workers, not their sum).

---

## 4. Fan-in — aggregating into a unified learning report

Fan-out gets us parallel results; fan-in is the step that combines them into something meaningful before persisting. Let's add an explicit aggregation step between `execute-workers` and `persist-results`:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (fan-in step added)
const report = await step.run("aggregate-report", async () => {
  const grading = results.find((r: any) => r.resultType === "grading");
  const quiz = results.find((r: any) => r.resultType === "quiz");

  return {
    score: grading?.data?.score ?? null,
    quizGenerated: Boolean(quiz),
    workerCount: results.length,
  };
});
```

This `report` object is what gets persisted alongside the raw per-worker results, and it's also what a future dashboard widget (or Part 10's observability tooling [11]) can read as a single source of truth for "what happened to this submission."

**✅ Checkpoint:** Resubmit an assignment and confirm the `aggregate-report` step's output shows a real `score`, `quizGenerated: true`, and `workerCount: 2` — not `null`/`false`/`0`.

---

## 5. Conditional workflows — branching on the result

Real adaptive behavior requires branching: if a student's grade is low, something different should happen than if it's high. Let's add that logic right after aggregation:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (conditional branch added)
if (report.score !== null && report.score < 70) {
  await step.run("emit-struggling-event", async () => {
    await inngest.send({
      name: "student.struggling",
      data: { studentId: submission!.userId, submissionId: submission!.id, score: report.score },
    });
  });
}
```

Note that this Server-Action-adjacent code still respects the boundary from Part 1: the *decision* to branch lives in Inngest (Orchestration), not in the frontend or in a worker [12].

**✅ Checkpoint:** Temporarily hardcode the Grading Worker's placeholder score (Part 7 [3]) to return a value below 70, resubmit, and confirm a new `student.struggling` event appears in the Inngest dashboard's event stream. Then change it back to a random 60–100 range and confirm the event only fires on genuinely low scores.

---

## 6. Event chaining — building the adaptive learning loop

This is where Greymatter LMS goes from "reactive" to genuinely "adaptive." Let's build the full chain that Part 9 later assumes already exists [1]:

```text
assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned
```

Add a second Inngest function that listens for `student.struggling` and continues the chain:

```typescript
// infra/inngest/functions/studentStruggling.ts
import { inngest } from "../client";

export const studentStruggling = inngest.createFunction(
  { id: "student-struggling" },
  { event: "student.struggling" },
  async ({ event, step }) => {
    const intervention = await step.run("tutor-intervention", async () => {
      // Placeholder tutor logic — replaced with a real Tutor Worker in Part 11
      return { message: "Here's a simplified explanation of the topic you struggled with." };
    });

    await step.run("emit-practice-assigned", async () => {
      await inngest.send({
        name: "practice.assigned",
        data: { studentId: event.data.studentId, reason: "struggling", intervention },
      });
    });

    return intervention;
  }
);
```

Register it the same way we registered `assignmentSubmitted` back in Part 5 [5]:

```typescript
// apps/web/src/app/api/inngest/route.ts (updated)
import { studentStruggling } from "../../../../../infra/inngest/functions/studentStruggling";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [assignmentSubmitted, studentStruggling],
});
```

**✅ Checkpoint:** Force a low score again (section 5) and resubmit. In `localhost:8288`, confirm you now see **two separate function runs** — `assignment-submitted` and `student-struggling` — linked by the `student.struggling` event, and that a final `practice.assigned` event appears in the event stream, completing the chain [1].

---

## 7. Retry & compensation — what happens if a worker breaks

Since workers are executed independently, Greymatter LMS is designed so that one worker failing doesn't take down the others [3]:

```text
Grading Worker  ✓
Quiz Worker     ✗ (endpoint down)
```

Try it yourself: stop your Quiz Worker process and resubmit an assignment while the Grading Worker stays up.

**✅ Checkpoint:** In `localhost:8288`, you should see the `execute-workers` step report one success and one failure, but `aggregate-report` and `persist-results` still run and save whatever succeeded — the system proceeds rather than halting entirely [3]. This is also a good moment to confirm Inngest's own step-level retries: a step that throws will automatically retry a few times before the whole run is marked failed, which is worth watching happen once in the dashboard before moving on.

---

## 8. What we've built, and what's still open

At this point, Greymatter LMS can fan out to multiple independent workers, fan those results back into a single unified report, branch conditionally on the outcome, and chain events together into a genuinely adaptive loop — all without a single hardcoded `if/else` deciding which AI capability to run. Two things remain deliberately unresolved, flagged here on purpose: nothing currently stops a forged `student.struggling` event from being injected directly into Inngest by an attacker, and our `orgId` tenant checks from Part 4 [6] aren't yet re-verified *inside* each Inngest step.

---

## 9. What's next

We've built real fan-out execution, fan-in aggregation into a unified report, and a working chained event sequence — `assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned` — that creates adaptive learning loops [1]. In Part 9, we shift focus to securing this system: hardening the Orchestrator (Inngest) layer specifically, and building a full threat model for Greymatter LMS, closing the gaps we've been flagging since Part 5 (worker auth) and this part (tenant checks, chain integrity) [1].

**🩹 Common confusion at this stage:** "If anyone can call `inngest.send({ name: 'student.struggling', ... })` from anywhere, what stops a fake event from triggering a real tutor intervention?" — Nothing yet, and that's intentional at this stage so the chaining mechanism itself stays simple to learn. Part 9 addresses this directly by restricting which internal events can be sent from where, as part of its full threat model [1].

Ready? → **Part 9: Hardening — Securing Greymatter LMS's Event Surface**
