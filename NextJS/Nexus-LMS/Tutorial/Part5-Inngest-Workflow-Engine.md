# PART 5 — Event-Driven Workflow Engine

# Tutorial 05: Inngest, Orchestration, and AI Worker Execution

---

# Introduction

At this point, Nexus LMS has:

* a frontend that emits events
* a database that stores truth
* a worker registry (Sanity)
* a multi-tenant schema
* a clear separation of concerns

Now we build the **system that makes everything move**.

> This is where LMS becomes a living system instead of a static application.

We introduce the orchestration layer:

* event ingestion
* durable workflows
* fan-out execution
* worker coordination
* retries and failure recovery

Powered by Inngest

---

# Learning Objectives

By the end of this tutorial, you will understand:

* How LMS events become durable workflows
* How Inngest executes AI workflows safely
* How worker discovery integrates into execution
* How fan-out and fan-in patterns work
* How to handle failures and retries
* How to persist AI execution results
* How Nexus LMS becomes reactive instead of procedural

---

# 1. Why We Need an Orchestration Layer

Without orchestration:

```text id="bad1"
UI → DB → AI call → UI update
```

Problems:

* no retry system
* no visibility
* no workflow control
* no parallel execution
* no failure recovery

With orchestration:

```text id="good1"
Event → Workflow Engine → Workers → Results → Events
```

Now the system is:

* durable
* observable
* extensible
* replayable

---

# 2. Event Ingestion Model

Everything starts with an event:

```typescript id="e1"
await inngest.send({
  name: "assignment.submitted",
  data: {
    submissionId,
    studentId,
    assignmentId
  }
});
```

This is the **only entry point into the orchestration system**.

---

# 3. Core Workflow Structure

Every LMS event follows this pattern:

```text id="flow1"
Event Received
      ↓
Fetch Context (DB)
      ↓
Discover Workers (Registry)
      ↓
Execute Workers (Parallel/Sequential)
      ↓
Validate Outputs
      ↓
Persist Results
      ↓
Emit New Events (Optional)
```

---

# 4. Basic Inngest Workflow

```typescript id="w1"
export const assignmentSubmitted = inngest.createFunction(
  { id: "assignment-submitted" },
  { event: "assignment.submitted" },
  async ({ event, step }) => {

    const submission = await step.run("fetch-submission", async () => {
      return await getSubmission(event.data.submissionId);
    });

    const workers = await step.run("discover-workers", async () => {
      return await registry.findWorkers("assignment.submitted");
    });

    const results = await step.run("execute-workers", async () => {
      return Promise.all(
        workers.map(worker =>
          invokeWorker(worker, {
            submission
          })
        )
      );
    });

    await step.run("persist-results", async () => {
      return await saveWorkerResults(results);
    });

    return results;
  }
);
```

---

# 5. Worker Discovery Layer

Workers are NOT hardcoded.

They come from the registry:

Stored in Sanity

---

## Example Query

```typescript id="w2"
export async function findWorkers(eventName: string) {
  return sanity.fetch(`
    *[_type == "worker" &&
      "${eventName}" in events &&
      enabled == true
    ]
  `);
}
```

---

# 6. Worker Execution Model

Each worker is executed independently.

```text id="w3"
assignment.submitted
      |
      +--> Markly (grading)
      +--> Plagiarism detector
      +--> Tutor AI
      +--> Analytics engine
```

---

## Execution Function

```typescript id="w4"
export async function invokeWorker(worker, payload) {
  const res = await fetch(worker.endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(payload)
  });

  if (!res.ok) {
    throw new Error(`Worker failed: ${worker.name}`);
  }

  return res.json();
}
```

---

# 7. Fan-Out Pattern (Core AI Concept)

Fan-out means:

> One event triggers many independent AI systems.

```text id="fan1"
                Event
                  |
     +------------+-------------+
     |            |             |
     V            V             V

  Grader      Tutor AI     Analytics
```

Each worker:

* runs independently
* has no knowledge of others
* can fail safely

---

# 8. Fan-In Pattern (Aggregation Layer)

After fan-out, results can be merged:

```text id="fan2"
Markly --------\
Tutor AI ------- → Final Learning Report
Analytics ------/
```

Example:

```typescript id="fanin"
const finalReport = await step.run("aggregate", async () => {
  return {
    grade: marklyResult.score,
    feedback: tutorResult.feedback,
    insights: analyticsResult.patterns
  };
});
```

---

# 9. Failure Handling Strategy

AI systems fail frequently.

We design for failure:

---

## 9.1 Retry Policy

```typescript id="r1"
retry: {
  attempts: 3,
  backoff: "exponential"
}
```

---

## 9.2 Partial Failure Tolerance

If one worker fails:

```text id="r2"
Markly ✓
Tutor AI ✗
Analytics ✓
```

System still proceeds.

---

## 9.3 Dead Letter Handling

Failed workers go to:

```text id="r3"
worker_failures table
```

---

# 10. Result Persistence

All outputs go into:

```sql id="db1"
worker_results
```

Example record:

```json id="db2"
{
  "worker_id": "markly",
  "event_name": "assignment.submitted",
  "input": { "submissionId": "123" },
  "output": { "score": 87 },
  "status": "success"
}
```

---

# 11. Event Chaining (Advanced Behavior)

Workers can emit new events:

```text id="chain1"
assignment.submitted
        ↓
grading.completed
        ↓
student.struggling
        ↓
tutor.intervention
```

This creates:

> adaptive learning loops

---

# 12. Observability Layer

We track everything:

* event logs
* worker execution logs
* latency metrics
* failure rates

This is critical for AI systems.

---

# 13. Why This Architecture Works

## 13.1 Fully asynchronous

No blocking AI calls in UI or API layer.

---

## 13.2 Fully extensible

New AI feature = new worker.

No core changes.

---

## 13.3 Fully resilient

Failures do not break LMS flow.

---

## 13.4 Fully observable

Every AI decision is traceable.

---

## 13.5 Fully decoupled

LMS does NOT know:

* which AI runs
* how many workers exist
* what models are used

---

# 14. Key Architectural Principle

> The LMS does not execute intelligence.
>
> It orchestrates intelligence execution.

---

# Summary

In this tutorial, we built the orchestration layer:

* Inngest event workflows
* worker discovery system
* fan-out execution model
* fan-in aggregation patterns
* failure handling strategy
* result persistence model
* event chaining system
* observability foundation

We now have a **fully reactive AI orchestration engine**.

---

# Next Tutorial

## Tutorial 06 — Building the Plug-in Registry (Sanity Worker System)

We will now design:

* worker schema in Sanity
* versioning strategy for AI tools
* capability-based discovery
* input/output contract validation
* enabling external AI tools (Markly, Python Panel, etc.)
* dynamic plugin marketplace model
* safe execution contracts for third-party workers
