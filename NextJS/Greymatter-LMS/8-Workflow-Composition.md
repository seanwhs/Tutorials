# Part 8 — Inngest Deep Dive: Fan-Out, Fan-In & AI Workflow Composition for Greymatter LMS 

In Part 7, we built a standardized Worker SDK — a shared input/output contract, HMAC-signed requests, a real, callable Grading Worker, and a formal registration flow for adding new workers with zero core changes [3]. Now we go deeper into Inngest itself and design the advanced orchestration patterns that make Greymatter LMS genuinely adaptive, not just event-triggered [2].

**🎯 Goal of this lesson:** Build real parallel (fan-out) AI execution with a second worker, aggregate results into a unified report (fan-in), add conditional branching, chain events together into an adaptive learning loop, and understand how Greymatter LMS tolerates partial failure [2].

**🧰 Prereqs:** Part 7 completed (Grading Worker running locally, signed requests working) [2].

---

## 1. What this part covers

Following directly from where Part 7 left off, this part designs advanced orchestration patterns: parallel AI execution strategies, result aggregation systems, conditional workflows, adaptive learning pipelines, retry + compensation flows, and production-grade AI workflow design patterns [3]. Up to now, our `assignment.submitted` function has only ever called a single worker — the Grading Worker [5][3]. Real LMS behavior needs more than one AI capability reacting to the same event simultaneously, and needs the system to *do something different* depending on what those workers report back. That's what this part builds.

---

## 2. Registering a second worker — proving the six-step flow scales

Rather than inventing a new pattern, we reuse the exact six-step registration flow from Part 7 [3] to add a Quiz Worker. This is worth doing deliberately here, since it's the first real proof that the flow generalizes beyond a single worker:

1. **Build** the worker as an independent HTTP service implementing `WorkerInput`/`WorkerOutput` — same contract as the Grading Worker, different logic (placeholder quiz generation for now, replaced with a real LLM call in Part 11 [10]).
2. **Verify** incoming signatures using `verifySignature`.
3. **Sign** outgoing responses using `signPayload`.
4. **Run** it as its own process, on its own port (`localhost:4001`).
5. **Create a Sanity document** — `name: "quiz-worker"`, `events: ["assignment.submitted"]`, `endpoint: "http://localhost:4001/api/quiz-worker"`, `enabled: true` — exactly as done for the Grading Worker in Part 6 [4].
6. **Publish**, and let `findWorkers()` pick it up automatically, with zero changes to `infra/inngest` or `apps/web` [4].

**✅ Checkpoint:** With both workers registered and `enabled: true`, call `findWorkers("assignment.submitted")` directly and confirm it now returns **two** documents — `grading-worker` and `quiz-worker` — proving the registry (built in Part 6) scales to multiple subscribers per event with no code change at all [4].

---

## 3. Fan-out — real parallel AI execution

Recall Part 7's `execute-workers` step already looped over whatever `workers` the registry returned and called each one [3]. With two real workers now registered, that same code is already doing fan-out — but it's worth making the parallelism explicit and deliberate, since this is the pattern every future worker addition relies on:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (fan-out, explicit)
const results = await step.run("execute-workers", async () => {
  const payload: WorkerInput = {
    submissionId: submission!.id,
    orgId: submission!.orgId,
    studentId: submission!.studentId,
    content: submission!.content ?? "",
  };
  const signature = signPayload(payload, process.env.WORKER_SIGNING_SECRET!);

  // Promise.allSettled, not Promise.all — one worker failing must not sink the others
  const settled = await Promise.allSettled(
    workers.map((worker) =>
      fetch(worker.endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json", "x-signature": signature },
        body: JSON.stringify(payload),
      }).then((res) => res.json())
    )
  );

  return settled.map((outcome, i) => ({
    worker: workers[i].name,
    status: outcome.status,
    output: outcome.status === "fulfilled" ? outcome.value : null,
  }));
});
```

The switch from `Promise.all` to `Promise.allSettled` is the important detail here: `Promise.all` rejects entirely the moment *any* worker fails, which would mean one broken Quiz Worker silently prevents the Grading Worker's already-successful result from ever being persisted. `Promise.allSettled` instead resolves with a per-worker status, letting Greymatter LMS tolerate partial failure — a working grade *and* a failed quiz generation is a perfectly acceptable outcome, not a total failure of the whole event [2].

**✅ Checkpoint:** Temporarily stop the Quiz Worker process (leave the Grading Worker running) and resubmit an assignment. In the Inngest dashboard, confirm `execute-workers` still completes successfully, showing `grading-worker` as `"fulfilled"` and `quiz-worker` as `"rejected"` — rather than the entire step failing outright.

---

## 4. Fan-in — aggregating results into a unified report

Fanning out to multiple workers is only half the picture; Greymatter LMS also needs to collapse those parallel results back into one coherent object before persisting or branching on them. Add an aggregation step right after `execute-workers`:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (fan-in step added)
const report = await step.run("aggregate-results", async () => {
  const grading = results.find((r) => r.worker === "grading-worker" && r.status === "fulfilled");
  const quiz = results.find((r) => r.worker === "quiz-worker" && r.status === "fulfilled");

  return {
    score: grading?.output?.data?.score ?? null,
    feedback: grading?.output?.data?.feedback ?? null,
    quiz: quiz?.output?.data ?? null,
  };
});
```

This `report` object is what `persist-results` (from Part 5 [5]) now writes into `worker_results` — one row per worker, but a single aggregated shape any downstream logic (including the branching in the next section) can read from without caring how many workers actually ran.

**✅ Checkpoint:** Confirm `aggregate-results` appears as its own named step in the Inngest dashboard, and that its output shows a populated `score` and `feedback` even in the partial-failure scenario from section 3, where `quiz` correctly resolves to `null`.

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

Note that this Server-Action-adjacent code still respects the boundary from Part 1: the *decision* to branch lives in Inngest (Orchestration), not in the frontend or in a worker [12][2]. Neither `apps/web` nor either registered worker ever needs to know this threshold exists.

**✅ Checkpoint:** Manually insert a submission whose grading result comes back under 70 (or temporarily hardcode a low score in the Grading Worker's placeholder response), resubmit, and confirm a new `student.struggling` event appears in the Inngest dashboard's Events tab, linked to the same submission ID.

---

## 6. Chaining events into an adaptive learning loop

The real payoff of an event bus is that `student.struggling` isn't just an event we emit and forget — it's picked up by a *second* Inngest function, which can itself branch and emit a *third* event, and so on. This is the full chain Greymatter LMS builds toward:

```text
assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned
```

Register a new function listening for `student.struggling`:

```typescript
// infra/inngest/functions/studentStruggling.ts
import { inngest } from "../client";

export const studentStruggling = inngest.createFunction(
  { id: "student-struggling" },
  { event: "student.struggling" },
  async ({ event, step }) => {
    const intervention = await step.run("tutor-intervention", async () => {
      // Placeholder — Part 11 replaces this with a real, context-aware LLM call [10]
      return { message: `Let's review this topic together, score was ${event.data.score}.` };
    });

    await step.run("assign-practice", async () => {
      await inngest.send({
        name: "practice.assigned",
        data: { studentId: event.data.studentId, submissionId: event.data.submissionId },
      });
    });

    return intervention;
  }
);
```

Don't forget to register this new function alongside `assignmentSubmitted` in the `/api/inngest` route handler built in Part 5 [5], the same way every future function gets wired in.

Each event in this chain is deliberately simple and single-purpose — `assignment.submitted` doesn't know or care that `student.struggling` might eventually lead to `practice.assigned`. That's the whole point: every function only reacts to the one event it subscribes to, and only emits the next event in the chain, never reaching ahead to orchestrate steps that aren't its concern.

**✅ Checkpoint:** Temporarily hardcode the Grading Worker's placeholder score to return a value below 70, resubmit, and confirm a new `student.struggling` event appears in the Inngest dashboard's event stream. Then change it back to a random 60–100 range and confirm the event only fires on genuinely low scores [2].

---

### 7. Aggregating results into a single report

Before this part wraps up, revisit the aggregation step from section 4 — this `report` object is what gets persisted alongside the raw per-worker results, and it's also what a future dashboard widget (or Part 10's observability tooling) can read as a single source of truth for "what happened to this submission" [2]:

```typescript
const report = await step.run("aggregate-report", async () => {
  return {
    score: grading?.data?.score ?? null,
    quizGenerated: Boolean(quiz),
    workerCount: results.length,
  };
});
```

**✅ Checkpoint:** Resubmit an assignment and confirm the `aggregate-report` step's output shows a real `score`, `quizGenerated: true`, and `workerCount: 2` — not `null`/`false`/`0` [2].

---

### 8. What's next

We now have real parallel AI execution across two independently registered workers, graceful tolerance of partial failure via `Promise.allSettled`, a fan-in aggregation step producing one unified report, conditional branching based on that report, and a chained sequence of events forming an adaptive learning loop — all without the frontend or any single worker needing to know the full chain exists.

There's a gap worth naming honestly, though: nothing yet stops a malformed or tampered event from entering this chain — a `student.struggling` event missing a `submissionId`, or a submission missing tenant (`orgId`) context, would currently be accepted and processed as-is. In Part 9, we harden this pipeline directly: reinforcing tenant scoping at the very first step of every Inngest function, and rejecting malformed events before they ever reach a worker [1].

**🩹 Common confusion at this stage:** "If one worker fails via `Promise.allSettled`, does the whole event get silently swallowed?" — No — the failed worker's result is simply recorded as `"rejected"` in the results array and excluded from the aggregated report, while every other worker's successful output still gets persisted. Nothing is retried automatically at the individual worker level in this part; Part 9's hardening pass is what adds explicit rejection logic for missing or invalid data, rather than a network-level worker failure [1].

Ready? → **Part 9: Hardening — Reinforcing Tenant Scoping and Event Validation in Greymatter LMS**


