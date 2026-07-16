# Part 9 — Hardening: Securing Greymatter LMS's Event Surface 

In Part 8, we built real fan-out execution, fan-in aggregation into a unified report, and a working chained event sequence — `assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned` — that creates adaptive learning loops [2]. Now we shift focus to securing this system: the Orchestrator (Inngest) layer specifically, and building out a full threat model for Greymatter LMS [1].

**🎯 Goal of this lesson:** Secure the Inngest orchestration layer, understand what Greymatter LMS explicitly defends against, and close the gaps we've been flagging since Part 5 (worker auth) and Part 8 (tenant checks, chain integrity) [1].

**🧰 Prereqs:** Part 8 completed (fan-out/fan-in and event chaining working locally) [1].

---

## 1. Why hardening comes now, not earlier

Every part since Part 5 has been building real, running capability — event emission, worker discovery, signed worker calls, fan-out, fan-in, event chaining. Along the way, we deliberately flagged several gaps rather than fixing them immediately, so each lesson could stay focused on one mechanism at a time:

* Part 7 left `WORKER_SIGNING_SECRET` rotation as an open question [3].
* Part 8 flagged that nothing stops a forged `student.struggling` event from being injected directly into Inngest [2].
* Part 4 flagged that manual `orgId` checks are easy to forget across dozens of queries [6].

This part is where all three of those flags get resolved at once, alongside a couple of threats we haven't discussed yet.

---

## 2. The Threat Model Summary

The source material's hardening tutorial is structured around an explicit **Threat Model Summary** — the set of attack scenarios Greymatter LMS is deliberately built to defend against [1]. Let's map each one to what we've already built, and what still needs closing:

| Threat | Where it enters | Greymatter LMS defense |
|---|---|---|
| Spoofed events hitting `/api/inngest` directly | Orchestration Layer | Inngest's signing key + our own event-origin checks |
| Forged worker responses | Execution Layer | HMAC request signing, built in Part 7 |
| Cross-tenant data leakage | Data Layer | Manual `orgId` checks in every query (Part 4), now reinforced inside Inngest steps |
| Disabled/malicious worker still executing | Registry Layer | `enabled` flag check in the registry query (Part 6) |
| Unauthorized Server Action calls | Application Layer | `auth()` re-check inside every Server Action (Part 3) |

[1]

Notice that four of these five rows point back at code we've *already written* — this part is largely about reinforcing and verifying those defenses, not building an entirely new system.

**✅ Checkpoint:** Before writing any new code, go through this table and, for each row, locate the actual file/line in your own project that implements the stated defense (e.g., find the `auth()` call in `actions.ts` from Part 3 [7], find the `enabled == true` clause in `findWorkers` from Part 6 [4]). If you can't locate one, that's the exact gap this part will close.

---

## 3. Defending against spoofed events

Right now, anything that can reach `/api/inngest` with the correct shape can trigger a workflow — including, as flagged at the end of Part 8, a forged `student.struggling` event sent by an attacker who knows our event names [2]. Two layers of defense close this:

First, Inngest's own signing key ensures that only requests genuinely originating from the Inngest platform (not an arbitrary client) can invoke our functions — this is configured via the `INNGEST_SIGNING_KEY` environment variable, which we should now add alongside `WORKER_SIGNING_SECRET` from Part 7 [3]:

```bash
# apps/web/.env.local
INNGEST_SIGNING_KEY=your-inngest-signing-key
```

Second, since some events (like `student.struggling`) should only ever be emitted by our own Inngest functions — never directly by the frontend — we add an explicit origin check inside any function that consumes an internally-generated event:

```typescript
// infra/inngest/functions/studentStruggling.ts (origin check added)
export const studentStruggling = inngest.createFunction(
  { id: "student-struggling" },
  { event: "student.struggling" },
  async ({ event, step }) => {
    // Defense: reject events missing internal provenance markers
    if (!event.data.submissionId || !event.data.studentId) {
      throw new Error("Rejected: student.struggling event missing required internal context");
    }

    // ... rest of function unchanged from Part 8
  }
);
```

**✅ Checkpoint:** Manually craft and send a `student.struggling` event missing `submissionId` (using the Inngest dashboard's manual event trigger, or a quick script). Confirm the function run fails immediately with the "Rejected" error, rather than proceeding to run a tutor intervention.

---

## 4. Reinforcing tenant checks inside Inngest steps

Part 4 established that every query touching `courses`, `enrollments`, or `submissions` must manually filter by `orgId`, since Neon gives us no Row-Level Security to fall back on [6]. That discipline was easy to enforce in Part 3's Server Actions, where every function starts with `auth()` [7] — but Inngest functions don't have a signed-in user session at all, so this check has to be re-derived from stored data instead.

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (tenant check reinforced)
const submission = await step.run("fetch-context", async () => {
  const record = await db.query.submissions.findFirst({
    where: eq(submissions.id, event.data.submissionId),
  });

  if (!record) {
    throw new Error("Rejected: submission not found or already deleted");
  }

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

This closes the gap flagged at the end of Part 4: rather than trusting that every future query remembers to filter by `orgId`, the very first step of every Inngest function now refuses to proceed at all if a submission is missing tenant context [6].

**✅ Checkpoint:** Manually insert a `submissions` row with `orgId` set to `null` or an empty string directly via Drizzle Studio, then trigger `assignment.submitted` pointing at that row's ID. Confirm the run fails at `discover-workers` with the "Rejected: submission missing orgId" error, rather than silently calling workers with incomplete context.

---

## 5. Reinforcing the `enabled` flag and worker response signing

Two defenses we already built are worth re-verifying explicitly in this part, since they're exactly what a threat model is meant to double-check, not just assume works.

**Disabled worker still executing (Part 6 defense):** revisit the checkpoint from Part 6 where toggling a worker's `enabled` flag to `false` removed it from `discover-workers`' output entirely [4]. That's the whole defense — a disabled worker is never called in the first place, because `findWorkers` filters on `enabled == true` at the query level, not after the fact.

**Forged worker responses (Part 7 defense):** revisit the `verifySignature` check added to `execute-workers` in Part 7 [3]. Let's now actively test it as an attack, not just a happy path:

```typescript
// Quick local test — simulate a forged response
const forgedOutput = { workerName: "grading-worker", resultType: "grade", data: { score: 100 }, success: true };
const forgedSignature = "0000000000000000000000000000000000000000000000000000000000000000";

console.log(verifySignature(forgedOutput, forgedSignature, process.env.WORKER_SIGNING_SECRET!));
// should log: false
```

**✅ Checkpoint:** Temporarily modify the Grading Worker from Part 7 to skip signing its response (comment out the `res.setHeader("x-signature", ...)` line), then resubmit an assignment through the dashboard. Confirm the `execute-workers` step now throws `"Worker grading-worker returned an invalid signature"` and the run fails — proving the signature check actually blocks a forged/unsigned response rather than silently accepting it. Then restore the signing line.

---

## 6. Reinforcing unauthorized Server Action calls

The last row of the threat model table points back at Part 3's `auth()` check inside every Server Action [7]. As a final reinforcement, add a matching org-membership check, not just a signed-in check, since a signed-in user from one org should never be able to submit against another org's course:

```typescript
// apps/web/src/app/(dashboard)/assignments/actions.ts (reinforced)
export async function submitAssignment(assignmentId: string, courseId: string, content: string) {
  const { userId, orgId } = await auth();
  if (!userId || !orgId) throw new Error("Unauthorized");

  const course = await db.query.courses.findFirst({ where: eq(courses.id, courseId) });
  if (!course || course.orgId !== orgId) {
    throw new Error("Rejected: course does not belong to your organization");
  }

  // ... insert + inngest.send unchanged from Part 5
}
```

**✅ Checkpoint:** Using two separate Clerk test accounts in two different organizations, confirm that Org A's user attempting to submit against Org B's `courseId` receives the "Rejected" error, rather than a successful submission.

---

## 7. What's honestly still open

A threat model is only useful if it's honest about its limits. Two items are explicitly flagged here as unresolved, matching what Part 7 already warned about and what Part 12 later reiterates as a real-world launch consideration [9]:

* **Secret rotation** — `WORKER_SIGNING_SECRET` and `INNGEST_SIGNING_KEY` have no rotation mechanism; changing either currently requires redeploying every worker simultaneously.
* **Replay attacks** — a captured, validly-signed request could theoretically be resent later, since our HMAC scheme doesn't yet include a timestamp or nonce.

These are called out honestly rather than papered over — Part 12's capstone explicitly reminds readers that this is "a complete, correct *foundation*... not a finished enterprise product" [9], and these two items are exactly what separates the two.

---

## 8. What's next

We've hardened the Orchestrator and Execution layers, but we still have very little *visibility* into what's happening when something goes wrong. If a worker silently fails, or a chain never fires, right now our only debugging tool is manually reading the Inngest dashboard. In Part 10, we design a proper observability system: an event tracing system, an AI worker observability pipeline, debugging tools for failed workflows, a distributed logs architecture, performance monitoring, cost tracking per worker, and learning analytics instrumentation [1].

**🩹 Common confusion at this stage:** "We just added five different `throw new Error(...)` checks — is that really 'hardening,' or just error handling?" — It's both, deliberately. Each check in this part corresponds to a named row in the Threat Model Summary table [1]; the difference between "error handling" and "hardening" is that these checks exist specifically to reject *malicious or malformed* input, not just handle expected edge cases. Part 10 will make these rejections visible and traceable, instead of just failing silently in a dashboard only you are watching [1].

Ready? → **Part 10: Observability — Tracing, Logging & Debugging Greymatter LMS**
