# Part 8 — Inngest Deep Dive: Fan-Out, Fan-In & AI Workflow Composition for Greymatter LMS

In Part 7, we built a standardized Worker SDK — a shared input/output contract, HMAC-signed requests, and a real, callable Grading Worker registered through Sanity. Now we go deeper into Inngest itself and design the advanced orchestration patterns that make Greymatter LMS genuinely adaptive, not just event-triggered.

**🎯 Goal of this lesson:** Build real parallel (fan-out) AI execution, aggregate results into a unified report (fan-in), and chain events together to create adaptive learning loops.

**🧰 Prereqs:** Part 7 completed (Grading Worker running locally, signed requests working).

---

## 1. What this part covers

Following directly from where Part 7 left off, this part designs advanced orchestration patterns, parallel AI execution strategies, result aggregation systems, conditional workflows, adaptive learning pipelines, retry + compensation flows, and production-grade AI workflow design patterns [3].

---

## 2. Fan-out — running multiple AI workers in parallel

We already have two workers registered in Sanity from Part 6 (Grading Worker, Quiz Worker), and Part 7 gave us a real signed-execution pattern. Fan-out simply means: when `assignment.submitted` fires, every matching worker runs **at the same time**, not one after another.

Our `execute-workers` step from Part 7 already does this implicitly via `Promise.all`, but let's make the aggregation explicit and visible, matching the unified-report pattern from the source material:

```text
Markly Score: 87
Tutor Feedback: "Improve clarity"
Analytics: "Struggling in recursion"
Quiz: Generated
↓
Unified Learning Report
```
[2]

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (fan-in step added)
const results = await step.run("execute-workers", async () => {
  return Promise.all(
    workers.map(async (worker: any) => {
      const payload = { event: "assignment.submitted", submission };
      const signature = signPayload(payload);
      const response = await fetch(worker.endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-Greymatter-Signature": signature },
        body: JSON.stringify(payload),
      });
      return { workerName: worker.name, data: await response.json() };
    })
  );
});

// Fan-in: aggregate all independent worker outputs into one unified report
const unifiedReport = await step.run("aggregate-results", async () => {
  return results.reduce((report: Record<string, unknown>, r: any) => {
    report[r.workerName] = r.data;
    return report;
  }, {});
});
```

**✅ Checkpoint:** Submit an assignment with both Grading Worker and Quiz Worker running. In `localhost:8288`, confirm `execute-workers` shows both calls completing concurrently (similar timestamps), and `aggregate-results` produces a single object containing both outputs — your first real "Unified Learning Report" [2].

---

## 3. Fan-in in the data layer — where the unified report lives

Recall from Part 4 that `worker_results` is the shared destination for exactly this kind of output — quiz generation, grading results, summaries, tutor feedback, and analytics insights [6]. Let's persist the unified report as well as the individual rows:

```typescript
await step.run("persist-unified-report", async () => {
  await db.insert(workerResults).values({
    submissionId: submission!.id,
    workerName: "unified-report",
    resultType: "aggregate",
    resultData: JSON.stringify(unifiedReport),
  });
});
```

---

## 4. Event chaining — building an adaptive learning loop

This is the most powerful pattern in this part. Workers can emit *new* events themselves, creating chains like:

```text
assignment.submitted
↓
grading.completed
↓
student.struggling
↓
tutor.intervention
```
[2] [5]

This creates what the source material calls **adaptive learning loops** [2] [5]. Let's implement the first link in that chain — after grading completes, check the score and conditionally emit a new event:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (conditional chaining)
await step.run("check-performance-and-chain", async () => {
  const gradingResult = results.find((r: any) => r.workerName === "Grading Worker");
  const score = gradingResult?.data?.score ?? 100;

  if (score < 70) {
    await inngest.send({
      name: "student.struggling",
      data: { studentId: submission!.userId, submissionId: submission!.id, score },
    });
  }
});
```

Now create a second Inngest function to handle the new event — this is the "tutor.intervention" link in the chain:

```typescript
// infra/inngest/functions/studentStruggling.ts
import { inngest } from "../client";

export const studentStruggling = inngest.createFunction(
  { id: "student-struggling" },
  { event: "student.struggling" },
  async ({ event, step }) => {
    await step.run("trigger-tutor-intervention", async () => {
      console.log(`Tutor AI intervention triggered for student ${event.data.studentId} (score: ${event.data.score})`);
      // Real Tutor AI worker call comes in Part 11
    });

    await step.run("emit-practice-assigned", async () => {
      await inngest.send({
        name: "practice.assigned",
        data: { studentId: event.data.studentId, submissionId: event.data.submissionId },
      });
    });
  }
);
```

Don't forget to register it:

```typescript
// apps/web/src/app/api/inngest/route.ts
import { studentStruggling } from "../../../../../infra/inngest/functions/studentStruggling";

export const { GET, POST, PUT } = serve({
  client: inngest,
  functions: [assignmentSubmitted, studentStruggling],
});
```

**✅ Checkpoint:** In your Grading Worker (Part 7), temporarily hardcode `score: 55` instead of `87`. Submit an assignment. In `localhost:8288`, you should now see **two separate function runs**: `assignment-submitted` completes, then automatically triggers `student-struggling`, which emits `practice.assigned`. This is the full chain from the source material, working end-to-end: `assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned` [2] [5].

---

## 5. Another adaptive flow — the full sequential pipeline

The source material also describes a more complete adaptive flow combining grading, analysis, intervention, and remediation into one sequence [2]:

```text
assignment.submitted
↓
grading AI
↓
performance analysis
↓
tutor intervention
↓
quiz generation
↓
remediation plan
```
[2]

This is exactly what we just built, just described end-to-end: our `assignment-submitted` function handles grading + performance analysis (the score check), `student-struggling` handles tutor intervention, and `practice.assigned` is the hook where quiz generation and a remediation plan would attach (we'll wire the real Quiz Worker into this in Part 11).

---

## 6. Why this matters architecturally

This pattern is what makes the registry work from Part 6 actually pay off. Because AI is modular — each AI system is replaceable [4] — we can swap the Grading Worker for a different model, run multiple graders in parallel to compare them, or add an entirely new intervention worker to the `student.struggling` event, all without touching `assignment-submitted`'s core logic [4]. The LMS logic stays fully decoupled from intelligence logic [4], and the system remains fully extensible: new AI feature = new worker, no core changes [5].

---

## 7. What's next

We now have real fan-out execution, fan-in aggregation into a unified report, and a working chained event sequence that creates an adaptive learning loop. But right now, if a worker fails mid-chain, or a chain silently stops, we have no good way to see *why*. In Part 9, we shift focus to **Hardening** — securing the orchestrator layer itself, defending against event-based attacks, and building out a full threat model for Greymatter LMS [1].

**🩹 Common confusion at this stage:** "Why use separate Inngest functions (`assignment-submitted`, `student-struggling`) instead of one giant function with if/else branches?" — Separate functions mean each link in the chain is independently retryable, independently observable in the dashboard, and can be triggered by *other* events too (e.g., a future "quiz.failed" event could also trigger `student-struggling`), which a single monolithic function can't do cleanly.

Ready? → **Part 9: Hardening — Securing Greymatter LMS's Event Surface**
