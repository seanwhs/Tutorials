# Part 9 — Hardening: Securing Greymatter LMS's Event Surface

In Part 8, we built real fan-out execution, fan-in aggregation into a unified report, and a working chained event sequence (`assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned`) that creates adaptive learning loops [2]. Now we shift focus to securing this system — the Orchestrator (Inngest) layer specifically — and building out a full threat model for Greymatter LMS [1].

**🎯 Goal of this lesson:** Secure the Inngest orchestration layer, understand what Greymatter LMS explicitly defends against, and close the gaps we've been flagging since Part 5 (worker auth) and Part 8 (tenant checks, chain integrity).

**🧰 Prereqs:** Part 8 completed (fan-out/fan-in and event chaining working locally).

---

## 1. Orchestrator Security — the Inngest Layer

Since Inngest is the layer that decides "this event happened, go run these workers," it's also the layer most worth hardening deliberately — the source material frames this explicitly as its own section: **Orchestrator Security (Inngest Layer)** [1].

Concretely, for Greymatter LMS this means:

* Verifying that every event dispatched into Inngest actually originated from an authenticated Server Action (not a spoofed direct call to `/api/inngest`).
* Making sure a chained event (like `student.struggling`) can only be emitted by trusted internal functions, not by an external caller hitting the endpoint directly.
* Ensuring every `step.run` that touches the database re-applies the same `orgId`/`userId` tenant checks we established back in Part 4, since Neon has no RLS to fall back on.

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (hardened fetch-context step)
const submission = await step.run("fetch-context", async () => {
  const record = await db.query.submissions.findFirst({
    where: eq(submissions.id, event.data.submissionId),
  });

  // Defense-in-depth: re-verify tenant ownership even inside the orchestrator,
  // not just at the Server Action boundary (Part 3/4)
  if (!record || record.orgId !== event.data.orgId) {
    throw new Error("Tenant mismatch or submission not found");
  }

  return record;
});
```

---

## 2. Threat Model Summary

The source material's hardening tutorial is structured around an explicit **Threat Model Summary** — the set of attack scenarios Greymatter LMS is deliberately built to defend against [1]. Let's map each one to what we've already built (or still need to close):

| Threat | Where it enters | Greymatter LMS defense |
|---|---|---|
| Spoofed events hitting `/api/inngest` directly | Orchestration Layer | Inngest's signing key + our own event-origin checks |
| Forged worker responses | Execution Layer | HMAC request signing, built in Part 7 |
| Cross-tenant data leakage | Data Layer | Manual `orgId` checks in every query (Part 4), now reinforced inside Inngest steps (section 1 above) |
| Disabled/malicious worker still executing | Registry Layer | `enabled` flag check in the registry query (Part 6) |
| Unauthorized Server Action calls | Application Layer | `auth()` re-check inside every Server Action (Part 3) |
| Chain hijacking (fake `student.struggling` events) | Orchestration Layer | Restrict which internal functions are allowed to emit sensitive downstream events |

---

## 3. Locking down worker responses further

Back in Part 7, we signed *outgoing* requests to workers with HMAC so a worker could verify Greymatter LMS was the real caller. Now let's close the reverse gap — verifying that the *response* actually came from that same worker, not an attacker who intercepted or replaced it:

```typescript
// infra/inngest/functions/assignmentSubmitted.ts (verify worker response)
import { verifySignature } from "../../../packages/workers/sign";

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

      const responseSignature = response.headers.get("x-greymatter-response-signature");
      const data = await response.json();

      if (!responseSignature || !verifySignature(data, responseSignature)) {
        throw new Error(`Untrusted response from worker: ${worker.name}`);
      }

      return { workerName: worker.name, data };
    })
  );
});
```

Update the Grading Worker from Part 7 to sign its own responses:

```typescript
// workers/grading-worker/index.ts (sign the response too)
import { signPayload } from "../../packages/workers/sign";

app.post("/api/grading-worker", (req, res) => {
  // ...existing signature verification of the incoming request...

  const output = {
    workerName: "Grading Worker",
    resultType: "grading",
    data: { score: 87, feedback: "Solid understanding, minor gaps in edge cases." },
    success: true,
  };

  res.setHeader("X-Greymatter-Response-Signature", signPayload(output));
  res.json(output);
});
```

**✅ Checkpoint:** Submit an assignment and confirm in `localhost:8288` that `execute-workers` still succeeds. Then temporarily comment out the `res.setHeader` line in the worker, resubmit, and confirm the step now throws `"Untrusted response from worker"` — proving the check actually works both directions.

---

## 4. Restricting who can emit sensitive chained events

Recall from Part 8 that `student.struggling` triggers a tutor intervention chain. Since Inngest's `/api/inngest` endpoint technically accepts any registered event name, we should guard against anything outside our own server code emitting that event directly. A simple, effective pattern for a beginner-friendly project is an internal-only emit wrapper:

```typescript
// infra/inngest/internalEmit.ts
import { inngest } from "./client";

const ALLOWED_INTERNAL_EVENTS = ["student.struggling", "tutor.intervention", "practice.assigned"];

export async function internalEmit(name: string, data: unknown) {
  if (!ALLOWED_INTERNAL_EVENTS.includes(name)) {
    throw new Error(`Event "${name}" is not permitted via internalEmit`);
  }
  return inngest.send({ name, data });
}
```

Use `internalEmit` instead of calling `inngest.send` directly inside any Inngest function that triggers a downstream chain link — this keeps a single, auditable chokepoint for every internally-chained event in Greymatter LMS.

---

## 5. What we've hardened vs. what's still a known limitation

Being transparent with beginners here matters. After this part, Greymatter LMS defends against:

* ✅ Spoofed or tampered worker requests/responses (HMAC both directions)
* ✅ Cross-tenant data leakage inside orchestration steps, not just at the API boundary
* ✅ Disabled workers still executing
* ✅ Unrestricted internal event emission

Still open for a real production system (flagged honestly, not hidden): secret rotation strategy for `WORKER_SIGNING_SECRET`, rate limiting on `/api/inngest`, and replay-attack protection (an attacker resending a previously valid signed payload). These are worth knowing about, but out of scope for a beginner tutorial — a "Part 13: Going to Production Security" note is the right place for advanced readers to pursue them further.

---

## 6. What's next

We've hardened the Orchestrator and Execution layers, but we still have very little *visibility* into what's happening when something goes wrong. If a worker silently fails, or a chain never fires, right now our only debugging tool is manually reading the Inngest dashboard. In Part 10, we design a proper observability system: an event tracing system, an AI worker observability pipeline, debugging tools for failed workflows, a distributed logs architecture, performance monitoring, cost tracking per worker, and learning analytics instrumentation [1].

**🩹 Common confusion at this stage:** "Isn't HMAC signing overkill for a tutorial project?" — For a toy demo, yes. But Greymatter LMS is explicitly designed to model what a *real* AI-native LMS needs, and worker security is one of the areas beginners most commonly skip — leaving an open HTTP endpoint that anyone can call and inject fake grades or feedback into a student's record. It's worth the extra 20 lines of code now, before Part 11 adds real LLM-powered workers with real API costs behind them.

Ready? → **Part 10: Observability, Logging, and AI System Debugging for Greymatter LMS**
