# Appendix B — Key Concepts & Deep-Dive Reference

Appendix A is the structural map of Greymatter LMS — layer boundaries, ownership rules, and diagrams. Appendix B complements it in two parts: **B.0** is a quick-lookup glossary of every term used across the series, and **B.1–B.9** go deeper into the runtime mechanics, cryptographic protocols, and design rationale behind the architecture. Cross-references point back to the relevant Appendix A section wherever one exists.

---

## B.0 Quick-Reference Glossary

**Events, not features** — The founding philosophy of Greymatter LMS: rather than hard-wiring every AI feature into core app logic, everything that happens is treated as an event, and independent workers react to it. Adding a new AI feature later means adding a new worker, not touching existing code [13]. *See A.1, A.2.*

**Feature landfill** — The failure mode this philosophy exists to prevent: every new AI capability (grading, then quizzes, then tutoring, then analytics) multiplying the API integrations, UI updates, database changes, and edge-case handling required, until the codebase becomes unmanageable [13].

**"Does not execute intelligence, it orchestrates intelligence execution"** — The single absolute rule underlying every layer boundary in the system. The core application never runs a model directly; it only coordinates the lifecycle of a worker's execution [12]. *See A.1.*

**Contracts-over-implementations** — The principle that workers must conform to a strict, predefined input/output schema rather than exposing internal logic — allowing a worker like Markly to swap its underlying model (e.g., GPT-4o → Claude 3.5 Sonnet) without any change to orchestration or UI code [3]. *See A.2, A.8.*

**The five layers** — Client/Application (Next.js), Data (Postgres), Orchestration (Inngest), Registry (Sanity), Execution (AI Workers) — each with defined ownership and explicit non-ownership boundaries [12]. *See A.3.*

**Orchestration Layer** — Inngest, the only layer allowed to decide "this event happened, go run these workers." It owns event bus topology, workflow execution state, retries, and step chaining — never direct AI execution or raw data storage [5]. *See A.3, A.5–A.7.*

**Registry Layer** — Sanity, used exclusively as a runtime service discovery registry for AI capabilities, not as a content management system. It matches events (e.g., `assignment.submitted`) to valid, enabled worker endpoints [4]. *See A.3.*

**Worker** — An independently deployable service (e.g., Markly for grading, Quiz Generator, Tutor Assistant, Analytics Engine) that implements the standard input/output contract and reacts to one or more registered events. Workers are completely independent — they fail without threatening the rest of the system [3][4]. *See A.5.*

**Worker SDK** — The standardized `WorkerInput`/`WorkerOutput` TypeScript contract (`packages/workers`) every worker must implement, so any AI tool can plug into Greymatter LMS safely and consistently [3].

**Worker registration flow** — The repeatable, code-free sequence for adding a new worker: build it against the contract, deploy it, share a signing secret, create and publish a Sanity document (`name`, `events`, `endpoint`, `enabled`), and let Inngest auto-discover it on the next matching event [3].

**HMAC request signing** — The security mechanism signing both outgoing requests to workers and their responses, so forged or tampered payloads can be detected and rejected on either side of a worker call [3][1].

**Fan-out** — Running multiple independent workers in parallel in response to a single event, e.g., Markly, Plagiarism Checker, and Tutor AI all reacting to `assignment.submitted` simultaneously [2]. *See A.5.*

**Fan-in** — Aggregating the parallel results of a fan-out into a single, unified report (e.g., combining a grading score, tutor feedback, and analytics insight into one learning report) rather than leaving the frontend to query disconnected tables [2]. *See A.6.*

**Event chaining / conditional workflows** — Workers or orchestration functions emitting new events themselves, creating adaptive routing logic (e.g., `assignment.submitted → grading.completed → student.struggling → tutor.intervention`) that stays entirely hidden from the frontend [5][2]. *See A.7.*

**Event-Contract Principle** — The frontend only ever knows "something happened," never "what happens next." Events are the immutable contract between isolated layers [5].

**Multi-tenant isolation via `organization_id`** — Since Neon Postgres has no built-in Row-Level Security like Supabase, every tenant-scoped table and query must explicitly carry and validate an `organization_id`, checked first in Server Actions and re-verified inside Inngest steps directly, never trusting the initial event payload alone [6][1]. *See A.4.*

**Threat Model Summary** — The explicit set of attack scenarios Greymatter LMS defends against: spoofed events hitting `/api/inngest` directly, forged worker responses, cross-tenant data leakage, disabled/malicious workers still executing, and unauthorized Server Action calls [1].

**Trace ID** — A shared identifier generated once per root event and propagated through every chained event, worker call, and log line, so a multi-hop adaptive chain can be followed as a single trace tree rather than appearing as unrelated runs [11]. *See A.9.*

**"If you cannot trace it, you cannot trust it"** — The engineering principle underlying Greymatter LMS's observability requirements: distributed tracing is treated as architecturally required, not a secondary monitoring nice-to-have [11]. *See A.9.*

**New AI feature = new worker, no core changes** — The recurring, proven promise of the architecture: adding, swapping, or removing an AI capability never requires modifying the core orchestration logic, the registry client, or the Worker SDK contract [2][9]. *See A.8.*

**Known limitations (honestly flagged)** — Explicitly out-of-scope items for this beginner series: a secret rotation strategy for `WORKER_SIGNING_SECRET`, rate limiting on `/api/inngest`, and replay-attack protection against resent, validly-signed payloads [1][9].

---

## B.1 The Mechanics of Durable Execution (Inngest Internals)

Traditional asynchronous execution relies on simple queue processors (e.g., BullMQ, Celery) that follow a "fire-and-forget" model. Inngest instead treats each function as an interruptible, resumable state machine — every `step.run()` block is checkpointed independently, so a workflow can pause, fail, and resume without re-running work that already succeeded [5].

```text
[Inngest Engine]                      [Next.js /api/inngest Route]
      │  ── HTTP POST (invoke) ──────────►  │
      │                                     │ runs to first step.run()
      │  ◄── HTTP 202 (step state) ────────  │
      │  ── HTTP POST (resume) ───────────►  │
      │                                     │ skips step 1, runs step 2
      │  ◄── HTTP 200 (workflow complete) ─  │
```

**The rehydration loop:**
1. **Invocation** — Inngest sends an HTTP `POST` to `/api/inngest` with the event payload.
2. **First checkpoint** — the function runs until its first `step.run()`, then yields control back to Inngest with that step's result.
3. **State hydration** — Inngest persists the step's output and issues a follow-up request.
4. **Short-circuit replay** — the function re-runs from the top, but recognizes the first step already has a recorded result and skips straight to executing the next one.

This is exactly why each Inngest function in Greymatter LMS wraps every stage in its own named `step.run()` — each step is independently retryable and independently visible in the dashboard, which is what allows one worker's failure (e.g., a timed-out grading call) to be retried without re-running steps that already succeeded [2].

---

## B.2 The Double-Ended HMAC Exchange Protocol

To protect the Execution Layer from payload substitution, forged grading results, or injection attacks, worker calls use a double-ended HMAC-SHA256 handshake [3][1].

**Outbound signature generation:** the Orchestrator takes a shared secret key `K` (`WORKER_SIGNING_SECRET`), stringifies the outgoing payload `P`, and computes:

```text
S_out = HMAC-SHA256(K, JSON.stringify(P))
```

This signature travels in a custom header:

```http
POST /api/grading-worker HTTP/1.1
Host: localhost:4000
Content-Type: application/json
X-Greymatter-Signature: 8f3c7b... (computed S_out)
```

**Inbound verification and response signing:**
- The worker reads the `X-Greymatter-Signature` header and recomputes the HMAC using its own copy of `K`. A mismatch returns `401 Unauthorized` and halts execution.
- After computing its result `R`, the worker signs its own response the same way — `S_in = HMAC-SHA256(K, JSON.stringify(R))` — and returns it via an `X-Greymatter-Response-Signature` header.
- The Orchestrator verifies `S_in` before persisting the result, closing the loop against man-in-the-middle tampering [3][1].

---

## B.3 Application-Level Multitenancy (The Non-RLS Strategy)

Because Neon Postgres has no built-in Row-Level Security the way Supabase does, tenant isolation shifts entirely to the application query layer [6].

**Schema anchors** — every tenant-scoped table carries an explicit `org_id` column:

```typescript
export const courses = pgTable("courses", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(), // tenant partition anchor
  title: text("title").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
});

export const submissions = pgTable("submissions", {
  id: uuid("id").primaryKey().defaultRandom(),
  courseId: uuid("course_id").references(() => courses.id),
  userId: text("user_id").notNull(),
  orgId: text("org_id").notNull(), // tenant partition anchor
  content: text("content"),
  createdAt: timestamp("created_at").defaultNow(),
});
```

**Explicit filtering** — since nothing filters requests implicitly, every query must include an explicit `org_id` condition:

```typescript
export async function getTenantSubmissionContext(submissionId: string, currentOrgId: string) {
  return db
    .select()
    .from(submissions)
    .where(
      and(
        eq(submissions.id, submissionId),
        eq(submissions.orgId, currentOrgId) // omitting this causes a data leak
      )
    );
}
```

This check is applied first inside Server Actions, then re-verified inside Inngest's own steps rather than trusted from the original event payload [6][1].

---

## B.4 The Threat Matrix & Mitigation Architecture

Greymatter LMS's Threat Model Summary maps five attack vectors to concrete code-level defenses [1]:

| Threat Vector | Entry Point | Impact Scenario | Mitigation |
|---|---|---|---|
| Orchestrator spoofing | `/api/inngest` | Fake `assignment.submitted` events sent directly to the endpoint to trigger workflows | Inngest signing-key verification on every invocation |
| Worker forgery | Worker endpoints | Attacker calls a worker endpoint directly to force execution or intercept output | Outbound `X-Greymatter-Signature` check inside the Worker SDK |
| Response tampering | Return step | Intercepted worker response replaced with modified data (e.g., a forged score) | Inbound `X-Greymatter-Response-Signature` verified before persisting |
| Cross-tenant leakage | Data layer | A worker or step reads context belonging to the wrong organization | Tenant ownership re-verified inside the `fetch-context` step before any worker sees the data |
| Chain hijacking | Downstream event pipeline | A forged `student.struggling` event injected to bypass validation | Sensitive chained events restricted to an internal-only emit wrapper |

[1]

---

## B.5 Adaptive Loop Event Chaining Topology

Rather than a single function with branching `if/else` logic, adaptive behavior is modeled as a sequence of independent, chained Inngest functions [5][2]:

```text
[ assignment.submitted ] (emitted by the UI)
        │
        ▼
assignmentSubmitted function:
  1. Fetch submission context [5]
  2. Query the Sanity registry [5]
  3. Fan-out execute matching workers [2]
  4. Aggregate into a unified report (fan-in) [2]
  5. Evaluate score threshold
        │  score < 70 → chain link fires
        ▼
[ student.struggling ] (internal chained event)
        │
        ▼
studentStruggling function:
  1. Run AI tutor intervention [10]
  2. Persist result to worker_results [10]
  3. Emit next event via an internal-only wrapper [1][10]
        │
        ▼
[ practice.assigned ] (downstream adaptive target)
```

**Internal flow isolation:** sensitive chained events are restricted to an allow-list, so nothing outside the orchestration layer can forge them directly:

```typescript
// infra/inngest/internalEmit.ts
const SECURE_INTERNAL_CHANNELS = ["student.struggling", "practice.assigned"];

export async function internalEmit(eventName: string, payload: unknown) {
  if (!SECURE_INTERNAL_CHANNELS.includes(eventName)) {
    throw new Error(`Security violation: event channel ${eventName} restricted`);
  }
  return inngest.send({ name: eventName, data: payload });
}
```

This keeps each link in the chain independently retryable, independently observable, and protected from external event injection [2][1].

---

## B.6 Distributed Telemetry & AI Cost Auditing

Since AI workers incur real, per-call costs from external LLM providers, the observability pipeline tracks cost alongside execution logs, not as an afterthought [11][10].

```typescript
const completion = await openai.chat.completions.create({
  model: "gpt-4o-mini",
  messages: [{ role: "user", content: input.submission.content }],
});

const output: WorkerOutput = {
  workerName: "quiz-worker",
  resultType: "quiz",
  data: { quiz: parseJSON(completion.choices[0].message.content) },
  success: true,
  costCents: Math.round((completion.usage?.total_tokens ?? 0) * 0.001),
};
```

This cost figure is persisted into `worker_results` alongside the trace ID, so a single request can be audited for both *what happened* and *what it cost* [11].

---

## B.7 Paradigm Comparison: Greymatter LMS vs. Legacy LMS Platforms

Traditional LMS platforms (e.g., Moodle, Canvas) are synchronous, monolithic systems of record. Greymatter LMS is deliberately structured as an event-driven orchestration layer instead [13][12]:

| Dimension | Traditional LMS | Greymatter LMS |
|---|---|---|
| Compute model | Synchronous, blocking — one request handles everything inline | Asynchronous fan-out — a light event is emitted, workers process independently [2] |
| Extensibility | Monolithic — new features mean modifying core code | Registry-driven — new workers are added via a document, not a deploy [4] |
| Telemetry | Basic relational logs (e.g., `last_login_at`) | Distributed tracing with a shared trace ID and cost data [11] |
| Remediation logic | Rigid, manually hardcoded rules | Adaptive event chaining reacting to real outcomes [5][2] |

---

## B.8 Why This Design Avoids Common Failure Modes

**Monolithic bottlenecks → asynchronous fan-out:** in a traditional LMS, a stalled or crashing grading plugin can block the entire request, degrading the whole system. In Greymatter LMS, the Application Layer writes the submission and emits an event instantly; if a worker crashes or takes minutes, the student's dashboard remains unaffected [2].

**Hardcoded plugins → dynamic registries:** legacy systems require plugins to share memory and schema with the core app. Greymatter LMS treats every worker as a decoupled, stateless service discovered at runtime through the registry — swapping a model or prompt requires zero redeployment of the core app [4][10].

---

## B.9 Real-World Impact on Learners

* **Faster feedback loops** — fan-out execution means grading, quiz generation, and analytics all run concurrently on submission, rather than a student waiting days for a single manual pass [2].
* **Automatic remediation** — event chaining means a struggling student is flagged and routed to a tutor intervention without a teacher manually reviewing every low score [5][2].
* **Context-aware guidance** — because each worker reads the same submission context, follow-up support (e.g., a tutor message) can be tailored to the specific thing the student got wrong, rather than generic help content [10].
