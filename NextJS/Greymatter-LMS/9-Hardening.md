# Part 9 — Hardening: Securing Greymatter LMS's Event Surface 

In Part 8, we built real fan-out execution, fan-in aggregation into a unified report, and a working chained event sequence — `assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned` — that creates adaptive learning loops [2]. Now we shift focus to securing this system: the Orchestrator (Inngest) layer specifically, and building out a full threat model for Greymatter LMS [1].

**🎯 Goal of this lesson:** Secure the Inngest orchestration layer, understand what Greymatter LMS explicitly defends against, and close the gaps we've been flagging since Part 5 (worker auth) and Part 8 (tenant checks, chain integrity) [1].

**🧰 Prereqs:** Part 8 completed (fan-out/fan-in and event chaining working locally) [1].

---

## 1. Why hardening comes now, not earlier

Every part since Part 5 has been building real, running capability — event emission, worker discovery, signed worker calls, fan-out, fan-in, event chaining. Along the way, we deliberately flagged several gaps rather than fixing them immediately, so each lesson could stay focused on one mechanism at a time [1]:

- Part 7 left `WORKER_SIGNING_SECRET` rotation as an open question [3].
- Part 8 flagged that nothing stops a forged `student.struggling` event from being injected directly into Inngest [2].
- Part 4 flagged that manual `orgId` checks are easy to forget across dozens of queries [6].

This part is where all three of those flags get resolved at once, alongside a couple of threats we haven't discussed yet [1].

---

## 2. The full threat model, named explicitly

Before writing any new code, it's worth naming every threat Greymatter LMS actually defends against, and where each defense already lives (or is supposed to). This is the same table the source material points to directly [1]:

| Threat | Defense | Where it lives |
|---|---|---|
| Unauthenticated user hits a route | Clerk session check | `auth()` call in `actions.ts`, Part 3 [7] |
| A submission belongs to the wrong org | Manual `orgId` filter on every query | Drizzle queries, Part 4 [6] |
| A disabled worker still gets called | `enabled == true` filter at the query level | `findWorkers` in `packages/registry`, Part 6 [4] |
| A forged HTTP request pretends to be Inngest | HMAC request signing | `verifySignature`/`signPayload`, Part 7 [3] |
| A forged event is injected directly into Inngest | *(not yet built — closed in section 4 below)* | New in Part 9 [1] |
| A leaked signing secret can't be rotated safely | *(not yet built — closed in section 5 below)* | New in Part 9 [1] |

Notice that four of these five rows point back at code we've *already written* — this part is largely about reinforcing and verifying those defenses, not building an entirely new system [1].

**✅ Checkpoint:** Before writing any new code, go through this table and, for each row, locate the actual file/line in your own project that implements the stated defense (e.g., find the `auth()` call in `actions.ts` from Part 3 [7], find the `enabled == true` clause in `findWorkers` from Part 6 [4]). If you can't locate one, that's the exact gap this part will close [1].

---

## 3. Reinforcing tenant scoping inside Inngest itself

Part 4 flagged that manual `orgId` checks are easy to forget across dozens of queries [6], and it's true that every Server Action written since Part 3 already filters by `orgId` [7]. But nothing stops an Inngest function from receiving an event whose payload is simply missing `orgId` altogether — perhaps from a malformed client call, or a future function some other engineer writes without reading this series. Add an explicit guard at the very top of `fetch-context`, before any other step runs:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (tenant guard added)
const submission = await step.run("fetch-context", async () => {
  if (!event.data.submissionId) {
    throw new Error("Rejected: event missing submissionId");
  }

  const record = await db.query.submissions.findFirst({
    where: eq(submissions.id, event.data.submissionId),
  });

  if (!record || !record.orgId) {
    throw new Error("Rejected: submission missing tenant scope");
  }

  return record;
});
```

This doesn't replace the per-query `orgId` filters from Part 4 [6] — it's a second, independent line of defense specifically for the Orchestration Layer, so a missing or malformed tenant reference is rejected the moment a function tries to act on it, rather than silently propagating downstream into a worker call.

**✅ Checkpoint:** Manually send a test event to Inngest with a `submissionId` that doesn't exist in your database, and confirm the `fetch-context` step fails with `"Rejected: submission missing tenant scope"` rather than proceeding to `discover-workers`.

---

## 4. Validating events before they reach a worker — closing Part 8's flagged gap

Part 8 flagged directly that nothing stops a forged `student.struggling` event from being injected straight into Inngest — bypassing `assignment.submitted` and the grading step entirely [2]. Anyone with access to `inngest.send()` (or the Inngest dashboard's manual event trigger) could currently fabricate a `student.struggling` event with an arbitrary `studentId` and `score`, triggering a real tutor intervention for a submission that never happened.

Close this with schema validation on every event payload, using `zod`:

```bash
cd packages/events
npm install zod
```

```typescript
// packages/events/schemas.ts
import { z } from "zod";

export const StudentStrugglingSchema = z.object({
  studentId: z.string().min(1),
  submissionId: z.string().uuid(),
  score: z.number().min(0).max(100),
});
```

```typescript
// infra/inngest/functions/studentStruggling.ts (validation added)
import { StudentStrugglingSchema } from "../../packages/events/schemas";

export const studentStruggling = inngest.createFunction(
  { id: "student-struggling" },
  { event: "student.struggling" },
  async ({ event, step }) => {
    const parsed = StudentStrugglingSchema.safeParse(event.data);
    if (!parsed.success) {
      throw new Error(`Rejected: malformed student.struggling event — ${parsed.error.message}`);
    }

    // ...rest of the function from Part 8 continues here, using parsed.data instead of event.data
  }
);
```

This closes the gap at the *shape* level — a payload missing `score`, or with a `score` outside 0–100, is rejected before the tutor intervention step ever runs. It doesn't yet prove the event came from a legitimate upstream function rather than a manually triggered one; that's a deliberately separate concern worth flagging honestly rather than solving with false confidence here — for a production system, you'd extend this with a signed "chain token" passed between events, similar in spirit to the HMAC signing already used for worker calls [3].

**✅ Checkpoint:** Using the Inngest dashboard's manual event trigger, send a `student.struggling` event missing the `score` field entirely, and confirm the function run fails immediately with a clear rejection message rather than silently proceeding to `tutor-intervention`.

---

## 5. Rotating the worker signing secret safely

Part 7 left `WORKER_SIGNING_SECRET` rotation as an open question, treating it like a plain shared API key with no rotation story [3]. The problem with a single static secret is that rotating it requires updating every worker's `.env` and Greymatter LMS's own `.env.local` at the exact same instant — any gap between the two means either legitimate requests get rejected, or the old secret stays valid longer than intended.

The straightforward fix is supporting two valid secrets during a rotation window:

```typescript
// packages/workers/sign.ts (updated to support rotation)
const secrets = [process.env.WORKER_SIGNING_SECRET!, process.env.WORKER_SIGNING_SECRET_PREVIOUS].filter(Boolean);

export function verifySignature(payload: unknown, signature: string): boolean {
  return secrets.some((secret) => signPayload(payload, secret!) === signature);
}
```

To rotate: generate a new secret, set it as `WORKER_SIGNING_SECRET`, move the old value into `WORKER_SIGNING_SECRET_PREVIOUS`, deploy every worker and the orchestrator with both values present, confirm signing still works, then drop `WORKER_SIGNING_SECRET_PREVIOUS` once you're confident every service has picked up the new value.

**✅ Checkpoint:** Locally, set `WORKER_SIGNING_SECRET` to a brand-new value while leaving the Grading Worker still signing with the old one via `WORKER_SIGNING_SECRET_PREVIOUS` on the orchestrator side. Confirm a submission still processes successfully — proving the rotation window works — then remove the previous secret and confirm a stale-signed request now correctly fails.

---

## 6. What's next

We've now gone through Greymatter LMS's full threat model, confirmed which defenses already existed from Parts 3, 4, 6, and 7 [7][6][4][3].

The core fix closing the gap flagged at the end of Part 4 [6] is placing the tenant check inside the `discover-workers` step itself, not just at `fetch-context`:

```typescript
return record;
});

// Reinforce tenant scoping before any worker sees this data
const workers = await step.run("discover-workers", async () => {
  if (!submission!.orgId) {
    throw new Error("Rejected: submission missing orgId, cannot verify tenant scope");
  }
  return findWorkers("assignment.submitted");
});
```

Rather than trusting that every future query remembers to filter by `orgId`, the very first step of every Inngest function now refuses to proceed at all if a submission is missing tenant context [1].

**✅ Checkpoint:** Manually insert a `submissions` row with `orgId` set to `null` or an empty string directly via Drizzle Studio, then trigger `assignment.submitted` pointing at that row's ID. Confirm the run fails at `discover-workers` with the "Rejected: submission missing orgId" error, rather than silently calling workers with incomplete context [1].

### Cross-organization submission checks

The series also verifies tenant isolation at the submission boundary itself — confirming that a user from one organization cannot submit against another organization's course:

**✅ Checkpoint:** Using two separate Clerk test accounts in two different organizations, confirm that Org A's user attempting to submit against Org B's `courseId` receives the "Rejected" error, rather than a successful submission [1].

### Validating malformed events before they trigger a worker

The hardening pass also closes the gap where a malformed event — say, `student.struggling` missing its `submissionId` — could otherwise slip through and trigger a real tutor intervention:

**✅ Checkpoint:** Manually craft and send a `student.struggling` event missing `submissionId` (using the Inngest dashboard's manual event trigger, or a quick script). Confirm the function run fails immediately with the "Rejected" error, rather than proceeding to run a tutor intervention [1].

### What's next

With tenant scoping reinforced at the Orchestration Layer itself, and malformed events rejected before they reach a worker, Greymatter LMS's threat model is meaningfully closed for the core pipeline. Part 10 shifts focus to observability — because since Part 8 introduced fan-out execution and multi-step event chains (`assignment.submitted → grading.completed → student.struggling → tutor.intervention`), a single student action can now silently touch five or six independent systems, and a question as simple as "why didn't the tutor intervention fire?" becomes nearly impossible to answer without proper tracing [11].

Ready? → **Part 10: Observability — Tracing, Logging, and Cost Tracking Across Greymatter LMS**

Let me know if you'd like the fully expanded and enriched version of Part 10 next, following the same style as the previous parts.
