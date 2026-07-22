# Appendix E — Inngest Workflow Patterns

This expanded reference documents every durable-workflow pattern used across GreyMatter LMS's Inngest functions, with complete, runnable code for each pattern in isolation, a precise explanation of the underlying mechanism, and a decision framework for choosing between patterns when building new background workflows. Every pattern below is drawn directly from a real function built somewhere in Parts 12–14 — nothing here is hypothetical.

---

## E.1 The complete function inventory, at a glance

Before diving into individual patterns, here's every Inngest function built across this series, with every pattern it demonstrates:

| Function | Trigger | Patterns demonstrated |
|---|---|---|
| `onboard-user` | `user/created` | Basic step, single-purpose function |
| `confirm-enrollment` | `course/enrolled` | Multi-step with dependent data fetch |
| `recalculate-course-progress` | `lesson/completed` | Multi-step, conditional emission, cross-system aggregation |
| `issue-certificate` | `course/completed` | Idempotency, race recovery, failure recording, re-throw for retry |
| `send-inactivity-reminders` | cron (`0 9 * * *`) | Scheduling, concurrency limits, batch fan-out, spam prevention |
| `send-weekly-digest` | cron (`0 8 * * 1`) | Scheduling, batch fan-out, reused business logic |

---

## E.2 Pattern: Retries (automatic, step-scoped)

### The mechanism

Every `step.run(name, fn)` call is independently, automatically retried by Inngest's infrastructure if it throws — **and** its result is cached the moment it succeeds, so a retry of the overall function never re-executes an already-successful step.

```text
Function invoked
    │
    ▼
step.run("step-a", ...) ──► succeeds ──► result CACHED
    │
    ▼
step.run("step-b", ...) ──► THROWS
    │
    ▼
Inngest schedules a retry of the WHOLE FUNCTION
    │
    ▼
Function invoked again
    │
    ▼
step.run("step-a", ...) ──► Inngest sees a cached result already
    │                        exists for this step — SKIPS execution,
    │                        returns the cached value instantly
    ▼
step.run("step-b", ...) ──► actually re-executes this time
```

### Complete runnable example

```ts
import { inngest } from "@/inngest/client";

export const exampleRetryPattern = inngest.createFunction(
  { id: "example-retry-pattern" },
  { event: "example/demo" },
  async ({ event, step }) => {
    // If this step succeeds, its result is cached FOREVER for this
    // specific function run — even across retries triggered by a
    // LATER step failing.
    const userData = await step.run("fetch-user-data", async () => {
      console.log("Fetching user data — this log only appears ONCE, even on retry");
      return { id: event.data.userId, name: "Ada Lovelace" };
    });

    // Suppose this step has a 30% chance of throwing (simulating a
    // transient network failure) — Inngest will retry the FUNCTION,
    // but "fetch-user-data" above will NOT re-run; its cached
    // { id, name } result is reused directly.
    await step.run("flaky-external-call", async () => {
      if (Math.random() < 0.3) {
        throw new Error("Simulated transient failure");
      }
      console.log(`Processing ${userData.name}`);
    });

    return { done: true };
  }
);
```

### Where this is used in GreyMatter

Every single function in Parts 12–14 relies on this automatically — it's not something we had to opt into. The pattern becomes *visible* specifically in `issue-certificate` (Part 13), where steps like `fetch-user-and-course` and `create-certificate` are deliberately kept separate, precisely so a failure in email sending (a later step) never causes the certificate to be re-created or the user/course data to be re-fetched.

### Decision guidance

**Split into multiple `step.run` calls whenever:** a later operation is more likely to fail than an earlier one (email sending vs. a database read), or an operation has a side effect that must never happen twice (sending an email, charging a payment, incrementing a counter).

**Keep in one `step.run` call when:** operations are cheap, side-effect-free, and always succeed or fail together as a genuine logical unit (e.g., a single `SELECT` followed immediately by a pure computation on its result, with no external call in between).

---

## E.3 Pattern: Idempotency (event-level and business-level)

### The mechanism

Idempotency means "processing the same logical event twice produces the same end state as processing it once." Inngest gives you retries for free (E.2), but retries alone don't prevent *duplicate events* — the same event delivered twice, deliberately or by accident, is a different problem requiring your own business-level check.

### Complete runnable example — the full pattern from `issue-certificate`

```ts
import { inngest } from "@/inngest/client";
import { db } from "@/db/client";
import { findCertificate, createCertificate } from "@/db/queries/certificates";

export const exampleIdempotentIssuance = inngest.createFunction(
  { id: "example-idempotent-issuance" },
  { event: "example/course-completed" },
  async ({ event, step }) => {
    const { userId, courseId } = event.data;

    // LAYER 1: Check-before-write idempotency. Handles the common
    // case — a genuinely duplicate event, or a retry that reached
    // this point on a PREVIOUS attempt and already finished.
    const existing = await step.run("check-existing", async () => {
      return findCertificate(userId, courseId);
    });

    if (existing) {
      return { issued: false, reason: "already_issued", id: existing.id };
    }

    // LAYER 2: Race-recovery try/catch. Handles the RARE case where
    // TWO invocations of this function are running concurrently and
    // BOTH passed Layer 1's check before either had written anything —
    // the database's own UNIQUE constraint is the final, unbeatable
    // arbiter here, not application logic.
    const certificate = await step.run("create-with-race-recovery", async () => {
      try {
        return await createCertificate(db, { userId, courseId, courseTitle: "Demo", recipientEmail: "a@b.com" });
      } catch (error) {
        const wonByOther = await findCertificate(userId, courseId);
        if (wonByOther) return wonByOther; // The other invocation won — use its result.
        throw error; // A genuinely different error — don't swallow it.
      }
    });

    return { issued: true, id: certificate.id };
  }
);
```

### The two-layer idempotency diagram

```text
Event arrives
    │
    ▼
LAYER 1: "Does a result already exist?"
    │
    ├── Yes ──► Return the existing result. Done. (handles: retries,
    │           duplicate event delivery, re-invocation after success)
    │
    └── No ──► Attempt to create
                    │
                    ▼
              LAYER 2: try { create } catch { check again }
                    │
                    ├── Insert succeeded ──► Done, genuinely new.
                    │
                    └── Insert failed (unique constraint) ──►
                            A CONCURRENT invocation won the race
                            between Layer 1's check and this insert.
                            Fetch and return ITS result instead of
                            treating this as a failure.
```

### Where this is used in GreyMatter

`issue-certificate` (Part 13) is the canonical example — proven under genuine concurrent load in Part 13, Step 10's duplicate-safety test, where two `course/completed` events were fired simultaneously and exactly one certificate row resulted.

Compare this to `webhook_events` (Part 6) and `module_attempts.idempotency_key` (Part 11) — both are the *same conceptual pattern* (Layer 1 only, since those two cases don't have a meaningful "Layer 2 race" scenario the way certificate issuance does), applied at the database-constraint level directly rather than inside an Inngest function.

### Decision guidance

**Always apply Layer 1** for any workflow that creates a record with real-world consequences (certificates, payments, emails with unsubscribe-relevant content). **Add Layer 2** specifically when the workflow could plausibly run concurrently for the same logical target — which, for event-triggered functions, means: could the same event fire twice in quick succession, or could two *different* events both eventually try to do the same "final" write (as `recalculate-course-progress` firing on every module attempt, potentially multiple times close together, could).

---

## E.4 Pattern: Concurrency limits

### The mechanism

`concurrency: { limit: N }` caps how many simultaneous invocations of one specific function are allowed to run at once — additional trigger events queue rather than executing in parallel.

### Complete runnable example

```ts
import { inngest } from "@/inngest/client";

export const exampleConcurrencyLimited = inngest.createFunction(
  {
    id: "example-concurrency-limited",
    // At most ONE invocation of this specific function runs at any
    // given moment, platform-wide — a second trigger while one is
    // already running will WAIT, not run alongside it.
    concurrency: { limit: 1 },
  },
  { cron: "0 9 * * *" },
  async ({ step }) => {
    await step.run("do-work", async () => {
      console.log("Only one of these ever runs at a time");
    });
  }
);
```

### Why this matters specifically for scheduled functions

```text
Without concurrency limit:
   Scheduled trigger fires ──► Run A starts (takes 90 seconds)
   A manual "invoke now" test ──► Run B starts CONCURRENTLY with Run A
        │                              │
        ▼                              ▼
   Both scan the SAME inactive students, both send reminders
   ────────────────────────────────────────────────────────
   RESULT: some students receive TWO reminder emails for one
           inactivity period — the exact spam problem Part 14
           was built to prevent, reintroduced by concurrent runs

With concurrency: { limit: 1 }:
   Scheduled trigger fires ──► Run A starts
   A manual "invoke now" test ──► Run B WAITS until Run A finishes
        │
        ▼
   Run B starts only after Run A completes — by which point the
   students Run A already reminded now show up as "already sent"
   in Run B's own spam-prevention check (E.3-style Layer 1 logic)
```

### Where this is used in GreyMatter

`send-inactivity-reminders` and `send-weekly-digest` (Part 14) both use `concurrency: { limit: 1 }` — not because concurrent runs are *likely* under Inngest's normal cron scheduling, but as a defense against the realistic scenario of a developer manually triggering a test run (Part 14's verification steps explicitly do this) while a real scheduled run happens to also be in flight.

### Decision guidance

**Apply a concurrency limit of 1** to any function whose job is "scan broadly and act on many records," where acting twice on the same record is undesirable (spam, duplicate charges). **Higher limits (or no limit at all)** are appropriate for functions that are naturally per-entity and already protected by their own idempotency logic (like `issue-certificate`, which doesn't set a concurrency limit at all, relying entirely on E.3's two-layer pattern instead).

---

## E.5 Pattern: Debouncing

### The mechanism

**Not used directly in this series' functions**, but worth documenting here since it's a natural extension of patterns we *did* build, and the blueprint calls for it explicitly. Debouncing delays a function's execution until a burst of matching events has quieted down, running only once for the whole burst rather than once per event.

### Complete runnable example (illustrative, not implemented in GreyMatter)

```ts
import { inngest } from "@/inngest/client";

export const exampleDebounced = inngest.createFunction(
  {
    id: "example-debounced-analytics-refresh",
    // Waits 5 seconds after the LAST matching event before running —
    // if ten "lesson/completed" events arrive within a 5-second burst,
    // this function runs ONCE, not ten times.
    debounce: {
      key: "event.data.courseId", // debounce PER COURSE, not globally
      period: "5s",
    },
  },
  { event: "lesson/completed" },
  async ({ event, step }) => {
    await step.run("refresh-course-analytics", async () => {
      console.log(`Refreshing analytics for course ${event.data.courseId} once, after the burst settled`);
    });
  }
);
```

### Why this pattern would be a natural fit for a future GreyMatter enhancement

Recall `recalculate-course-progress` (Part 12) currently runs on **every single** `lesson/completed` event — meaning if a student rapid-fires through five checkpoint clicks in one lesson, the function runs five separate times, each recalculating the entire course's percentage from scratch. This is harmless (each run is correct and idempotent in its outcome), but wasteful. Debouncing by `userId` + `courseId` would let five rapid submissions collapse into one recalculation, run shortly after the burst settles — a genuine, realistic improvement left as a documented next step rather than implemented in the core series, to keep Part 12's introduction of Inngest focused on fundamentals first.

### Decision guidance

**Use debouncing** when a function's *correctness* doesn't depend on running immediately after every single triggering event, only on eventually running once after a burst — recalculation, cache-warming, and analytics-refresh workflows are the classic fit. **Never use debouncing** for anything where the student is actively waiting for a specific result (grading feedback, for instance) — debouncing intentionally introduces delay.

---

## E.6 Pattern: Scheduling (cron)

### The mechanism

`{ cron: "expression" }` replaces `{ event: "..." }` as a function's trigger — Inngest's own infrastructure keeps time and invokes the function automatically, with no separate scheduler process to run or maintain ourselves.

### Complete runnable example — both real cron functions from Part 14

```ts
import { inngest } from "@/inngest/client";

// Standard 5-field cron syntax: minute, hour, day-of-month, month, day-of-week
export const dailyAt9am = inngest.createFunction(
  { id: "daily-at-9am", concurrency: { limit: 1 } },
  { cron: "0 9 * * *" }, // "at minute 0 of hour 9, every day"
  async ({ step }) => {
    await step.run("do-daily-work", async () => {
      console.log("Runs once per day at 09:00 UTC");
    });
  }
);

export const weeklyMondayAt8am = inngest.createFunction(
  { id: "weekly-monday-8am", concurrency: { limit: 1 } },
  { cron: "0 8 * * 1" }, // "at minute 0 of hour 8, on day-of-week 1 (Monday)"
  async ({ step }) => {
    await step.run("do-weekly-work", async () => {
      console.log("Runs once per week, Monday at 08:00 UTC");
    });
  }
);
```

### Cron expression cheat sheet

```text
┌───────────── minute (0–59)
│ ┌───────────── hour (0–23)
│ │ ┌───────────── day of month (1–31)
│ │ │ ┌───────────── month (1–12)
│ │ │ │ ┌───────────── day of week (0–6, Sunday=0)
│ │ │ │ │
* * * * *

"0 9 * * *"     → every day at 09:00 UTC
"0 8 * * 1"     → every Monday at 08:00 UTC
"*/15 * * * *"  → every 15 minutes
"0 0 1 * *"     → midnight on the 1st of every month
```

### Where this is used in GreyMatter, and why UTC matters

Both `send-inactivity-reminders` and `send-weekly-digest` use UTC-based cron expressions. Inngest's cron scheduling is always interpreted in UTC — a genuinely important detail worth stating explicitly, since "9am" means something different depending on the reader's timezone, but "09:00 UTC" is unambiguous. A production system serving a specific regional audience might want to compute an appropriate UTC offset deliberately, rather than assuming "9am" means "9am for my users."

### Decision guidance

**Use cron triggers** for anything that should happen on a calendar schedule regardless of user activity (digests, inactivity sweeps, periodic cleanup). **Use event triggers** (the default, covered implicitly throughout E.2–E.4) for anything that should happen in direct response to something a specific user did. Never simulate scheduling by having an event handler "check if it's been a while" on every request — that's both unreliable (depends on someone happening to trigger a request) and wasteful (redundant checks on every page load) compared to a dedicated cron function.

---

## E.7 Pattern: Fan-out (batch processing within one function)

### The mechanism

When one function needs to process many independent items (many inactive students, many active learners), each item's work is wrapped in its **own uniquely-named** `step.run` call inside a loop — not a single `step.run` wrapping the entire loop. This is what makes partial-failure recovery possible: if item #47 of 200 fails, only #47 retries; items #1–46 (already succeeded) are not redone.

### Complete runnable example — the exact pattern from `send-inactivity-reminders`

```ts
import { inngest } from "@/inngest/client";

interface Student {
  userId: string;
  email: string;
}

async function findInactiveStudents(): Promise<Student[]> {
  // Simulated — in the real function, this is Part 14's
  // findInactiveEnrollments(), a single batch query.
  return [
    { userId: "u1", email: "a@example.com" },
    { userId: "u2", email: "b@example.com" },
    { userId: "u3", email: "c@example.com" },
  ];
}

export const exampleFanOut = inngest.createFunction(
  { id: "example-fan-out", concurrency: { limit: 1 } },
  { cron: "0 9 * * *" },
  async ({ step }) => {
    // ONE query fetches every candidate — never loop over "every user
    // in the platform" and query per-user (see the "batching" note below).
    const students = await step.run("find-candidates", async () => {
      return findInactiveStudents();
    });

    let sentCount = 0;

    for (const student of students) {
      // CRITICAL: each iteration's step name includes a UNIQUE
      // identifier (student.userId). Without this, Inngest cannot
      // distinguish "step for student A" from "step for student B" —
      // they'd collide under one generic name, breaking the whole
      // point of per-item retry isolation.
      const outcome = await step.run(`process-${student.userId}`, async () => {
        console.log(`Sending reminder to ${student.email}`);
        // ... send email, record notification ...
        return "sent";
      });
      if (outcome === "sent") sentCount++;
    }

    return { total: students.length, sentCount };
  }
);
```

### Why sequential, not `Promise.all`

```text
Sequential (what GreyMatter does):
   for (student of students) {
     await step.run(`process-${student.id}`, ...)   // one at a time
   }
   → Slower overall, but each step is independently retryable,
     and a crash partway through leaves a clean, resumable trail.

Promise.all (an alternative NOT used in this series):
   await Promise.all(students.map(s => step.run(`process-${s.id}`, ...)))
   → Faster overall (parallel), but harder to reason about ordering
     and rate limits against external services (e.g. an email
     provider's own rate limit could be exceeded by firing 200 sends
     simultaneously).
```

### Where this is used in GreyMatter

Both `send-inactivity-reminders` and `send-weekly-digest` (Part 14) use this exact sequential fan-out pattern. The blueprint's own commentary on this choice (Part 14) is worth repeating here: for a function whose primary value is *reliability* over raw throughput, sequential per-item steps are the more defensible default; a platform with tens of thousands of candidates at once would need a genuinely different, true parallel-fan-out design (see E.8).

### Decision guidance

**Use sequential fan-out** (as built in this series) when: the batch size is moderate (dozens to low hundreds), reliability and clean partial-failure recovery matter more than raw speed, and downstream services (email providers) have rate limits you'd rather not risk bursting.

---

## E.8 Pattern: True fan-out via child function invocation (beyond this series' scope)

### The mechanism

For genuinely large batches (thousands+), a more scalable pattern separates "find the candidates" from "process one candidate" into **two separate functions** — the first emits one event *per candidate*, and Inngest's own infrastructure handles invoking many parallel instances of the second function, each with its own independent concurrency budget, retry history, and observability.

### Illustrative example (not implemented in GreyMatter — documented as the natural next step beyond this series)

```ts
import { inngest } from "@/inngest/client";

// Function 1: finds candidates, emits ONE EVENT PER CANDIDATE.
// This function itself does almost no "processing" — just fan-out.
export const findAndDispatchReminders = inngest.createFunction(
  { id: "find-and-dispatch-reminders" },
  { cron: "0 9 * * *" },
  async ({ step }) => {
    const students = await step.run("find-candidates", async () => {
      return findInactiveStudents(); // could be thousands of rows
    });

    // step.sendEvent can send MANY events in one call — Inngest
    // durably records each one, then invokes Function 2 independently
    // for every single one, in parallel, each with its OWN retry
    // history isolated from the others.
    await step.sendEvent(
      "dispatch-reminder-events",
      students.map((student) => ({
        name: "reminder/send-one" as const,
        data: { userId: student.userId, email: student.email },
      }))
    );

    return { dispatched: students.length };
  }
);

// Function 2: processes exactly ONE student per invocation. Inngest
// runs MANY of these concurrently (bounded by ITS OWN concurrency
// limit, set independently from Function 1's).
export const sendOneReminder = inngest.createFunction(
  { id: "send-one-reminder", concurrency: { limit: 20 } },
  { event: "reminder/send-one" },
  async ({ event, step }) => {
    await step.run("send-email", async () => {
      console.log(`Sending to ${event.data.email}`);
    });
  }
);
```

### Sequential fan-out vs. true fan-out, compared

| | Sequential (GreyMatter's actual pattern) | True fan-out (this section) |
|---|---|---|
| Functions involved | 1 | 2 (dispatcher + worker) |
| Parallelism | None — one item at a time | Bounded parallel (e.g., 20 at once) |
| Retry granularity | Per-`step.run`, within one function run | Per-event, as fully independent function invocations |
| Best for | Dozens to low hundreds of items | Thousands+ items |
| Complexity | Lower — one function to reason about | Higher — two functions, an intermediate event type |

### Decision guidance

**Start with sequential fan-out** (E.7) for any new batch workflow — it's simpler, and GreyMatter's realistic data volumes throughout this tutorial never approach the scale where it becomes a bottleneck. **Graduate to true fan-out** (E.8) only once you have concrete evidence that a sequential loop is taking too long relative to your needs (e.g., a nightly job that used to take 2 minutes now takes 40 minutes because your user base has grown 100x) — this is a genuine, realistic production concern, documented here so you know the pattern exists when that day comes, without needing to prematurely complicate Part 14's simpler, correct-for-its-scale implementation.

---

## E.9 Pattern: Failure recovery and observability

### The mechanism

Wrapping a function's core logic in try/catch, recording status to your *own* database (independent of Inngest's own dashboard), and **re-throwing** the error so Inngest's automatic retry mechanism (E.2) still gets a chance to recover from genuinely transient failures.

### Complete runnable example — the exact pattern from `issue-certificate`

```ts
import { inngest } from "@/inngest/client";
import { recordWorkflowEventStart, markWorkflowEventStatus } from "@/db/queries/workflow-events";

export const exampleObservableWorkflow = inngest.createFunction(
  { id: "example-observable-workflow" },
  { event: "example/important-thing" },
  async ({ event, step }) => {
    // Record BEFORE doing any real work — this row exists in Neon
    // regardless of what happens next, giving us a queryable audit
    // trail independent of Inngest's own external dashboard.
    const workflowEvent = await step.run("record-start", async () => {
      const row = await recordWorkflowEventStart("example/important-thing", event.data);
      return { id: row.id };
    });

    try {
      await step.run("do-the-real-work", async () => {
        // ... whatever this workflow actually does ...
      });

      await step.run("mark-processed", async () => {
        await markWorkflowEventStatus(workflowEvent.id, "PROCESSED");
      });
    } catch (error) {
      // Record the failure in OUR OWN table — queryable by an admin
      // dashboard (Part 15's natural extension) without needing to
      // reach into Inngest's API at all.
      await step.run("mark-failed", async () => {
        await markWorkflowEventStatus(workflowEvent.id, "FAILED");
      });

      // CRITICAL: re-throw. If we swallowed this error instead, Inngest
      // would consider the function "successful" and NEVER retry it —
      // even if the failure was a transient network blip that would
      // have succeeded on attempt #2.
      throw error;
    }
  }
);
```

### Why re-throwing (not swallowing) is the correct choice here

```text
If you SWALLOW the error (don't re-throw):
   Function catches error → logs it → returns normally
        │
        ▼
   Inngest sees: "this function completed without error"
        │
        ▼
   NO RETRY HAPPENS — even though the underlying cause (e.g. Neon
   being briefly unreachable) may have completely resolved by now

If you RE-THROW:
   Function catches error → records FAILED status → re-throws
        │
        ▼
   Inngest sees: "this function's execution failed"
        │
        ▼
   Automatic retry scheduled, per Inngest's own backoff policy
        │
        ▼
   If the transient cause has resolved: retry succeeds, "mark-processed"
   now runs, status becomes PROCESSED — the FAILED record from the
   first attempt remains as a historical fact, which is fine; it
   accurately reflects what happened at that point in time
```

### Decision guidance

**Always re-throw** after recording failure state, unless you have a specific, deliberate reason to suppress retries entirely (e.g., you've determined the error is permanent and unrecoverable — a malformed payload that will fail identically on every retry). Recall Part 6's webhook handler made the *opposite* choice deliberately (swallowing certain errors to avoid infinite retries from an external provider) — the difference is that Clerk's webhook retries are controlled by *Clerk*, outside our influence, whereas Inngest's retries are a tool we explicitly want to keep available for our own internal workflows.

---

## E.10 Choosing the right pattern — a complete decision framework

```text
Does this workflow need to run on a SCHEDULE, independent of user action?
        │
   ┌────┴────┐
  Yes         No
   │           │
   ▼           ▼
Use CRON      Use EVENT trigger
(E.6)          │
   │           ▼
   │      Does the SAME logical outcome need to be guaranteed to
   │      happen AT MOST ONCE, even under retries or duplicate events?
   │           │
   │      ┌────┴────┐
   │     Yes         No
   │      │           │
   │      ▼           ▼
   │  Apply IDEMPOTENCY   A simple step-based function
   │  (E.3) — Layer 1      (E.2) is sufficient
   │  always; Layer 2 if
   │  concurrent invocations
   │  are plausible
   │
   ▼
Does this workflow process MANY independent items in one run?
        │
   ┌────┴────┐
  Yes         No
   │           │
   ▼           ▼
Is the batch size in the dozens-to-low-hundreds range?
   │
   ├── Yes ──► Sequential FAN-OUT within one function (E.7)
   │
   └── No, thousands+ ──► True fan-out via child function (E.8)

Should MULTIPLE rapid-fire events for the same entity collapse
into ONE eventual run, rather than running once per event?
   │
   ├── Yes ──► Apply DEBOUNCING (E.5)
   └── No ──► Run once per event, as normal

Could this function's real invocations from the SAME cron schedule
or a manual test trigger overlap in time in a way that would cause
duplicate real-world effects (duplicate emails, duplicate charges)?
   │
   ├── Yes ──► Apply a CONCURRENCY LIMIT (E.4)
   └── No ──► No limit needed

Does this workflow's failure need to be visible OUTSIDE Inngest's
own dashboard (e.g., in an internal admin tool)?
   │
   ├── Yes ──► Apply the OBSERVABILITY + RE-THROW pattern (E.9)
   └── No ──► Inngest's own dashboard is sufficient
```
