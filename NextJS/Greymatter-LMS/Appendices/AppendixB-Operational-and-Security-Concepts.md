# Appendix B — Key Concepts & Deep-Dive Reference

Appendix A is the structural map of Greymatter LMS. Appendix B complements it with a quick-lookup glossary and deeper mechanics behind the runtime, security, and design rationale — using only what the series actually builds.

---

## B.0 Quick-Reference Glossary

**Events, not features** — The founding philosophy of Greymatter LMS: one `emit()` call can fire multiple independent reactions — grading, tutor feedback, analytics — none of which know about each other, and a new one can be added or removed without touching the others. Everything from Part 5 onward with Inngest is a durable, production-grade version of this same idea [13].

**Client + Application Layer** — Next.js. Renders UI, emits events, and explicitly does **not** run AI, orchestrate workflows, or execute business logic directly [7][12].

**Data Layer** — Neon Postgres via Drizzle ORM. Chosen deliberately over Supabase, meaning tenant isolation and auth had to be replaced by hand: Clerk for auth, and manual `orgId` checks in every query instead of Row-Level Security [6].

**Orchestration Layer** — Inngest. The only layer allowed to decide "this event happened, go run these workers" — neither the frontend nor the database is allowed to make that call [5][12].

**Registry Layer** — Sanity, used exclusively as a runtime worker-discovery registry, not as a content management system. It answers "which workers listen to this event, and are they enabled?" [12][4]. Built specifically so a worker can be added, disabled, or swapped as a content edit, with zero code changes to Inngest or the frontend [4].

**Execution Layer** — Independently deployed AI Workers — the only place AI logic lives [12].

**Worker contract (`WorkerInput`/`WorkerOutput`)** — The standardized shape every worker must implement, defined in `packages/workers`, so Inngest's `execute-workers` step has a reliable way to call any worker and trust its response, regardless of what language or infrastructure that worker runs on [3].

**HMAC request/response signing** — Every outgoing worker request is signed, and every response is verified before being trusted — using an `x-signature` header on both sides of the exchange. A mismatched signature throws `"Worker returned an invalid signature"` and the call is rejected [3].

**Six-step worker registration flow** — Build the worker against the shared contract → deploy it → share the signing secret → create a Sanity document (`name`, `events`, `endpoint`, `enabled`) → publish it → Inngest auto-discovers it on the next matching event, with zero code changes [4][3].

**Fan-out** — Multiple independent, registered workers reacting in parallel to the same event [2].

**Fan-in / aggregate-report** — Collapsing parallel worker outputs into one unified object (e.g., `{ score, quizGenerated, workerCount }`), persisted alongside the raw per-worker results as a single source of truth for "what happened to this submission" [2].

**Event chaining / conditional workflows** — Orchestration functions emitting new events themselves based on a result — e.g., a low score triggering `student.struggling` — creating adaptive routing that stays entirely hidden from the frontend [2].

**Trace ID** — A single identifier generated once, at the very start of a request, then threaded through every downstream event, worker call, and log line, even across function boundaries — so multiple linked runs (e.g., `assignment-submitted` and `student-struggling`) can be proven to come from the same student action instead of looking like unrelated runs [11].

**Threat Model Summary** — The explicit set of defenses Part 9 reinforces, most of which were already built in earlier parts: the `auth()` check in Server Actions (Part 3), the `enabled == true` clause in `findWorkers` (Part 6), tenant scoping on submissions, and rejection of malformed chained events like `student.struggling` missing a `submissionId` [1][7][4].

**"New AI feature = new worker, no core changes"** — Proven concretely in Part 11: lesson summaries require a brand-new event (`lesson.completed`) and a brand-new Summary Worker, registered exactly like every worker since Part 6, with zero changes to core orchestration code [10][4].

---

## B.1 The Mechanics of the Orchestration Layer

Inngest sits in exactly one place in the architecture: it is the only layer allowed to decide "this event happened, go run these workers." The frontend only emits events, and the database only stores results [5][12]. The shared client both the frontend and function definitions import from is created once:

```typescript
// infra/inngest/client.ts
import { Inngest } from "inngest";

export const inngest = new Inngest({ id: "greymatter-lms" });
```

This mirrors the same "shared contract, not duplicated logic" principle used for `packages/events` back in Part 2 [5][8].

---

## B.2 The HMAC Signing Exchange

To let workers be built independently — in any language, anywhere — the Execution Layer relies on a shared, agreed-upon contract and a signed request/response exchange [12][3]. On the calling side, a worker's response is checked before it's trusted:

```typescript
const output = await res.json();
const outSignature = res.headers.get("x-signature") ?? "";

if (!verifySignature(output, outSignature, SECRET)) {
  throw new Error(`Worker ${worker.name} returned an invalid signature`);
}

return output;
```

If the signature doesn't match, the call throws rather than silently accepting a forged or corrupted response [3]. This closes the gap flagged back in Part 6, where nothing yet stopped a malicious or broken worker from being registered with an arbitrary endpoint [4].

---

## B.3 Application-Level Multitenancy (The Non-RLS Strategy)

Because Neon Postgres has no built-in Row-Level Security the way Supabase does, tenant isolation shifts entirely to the application and orchestration layers [6]. Every tenant-scoped table carries an explicit `orgId` column:

```typescript
export const submissions = pgTable("submissions", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  studentId: text("student_id").notNull(),
  courseId: uuid("course_id").notNull().references(() => courses.id),
  content: text("content").notNull(),
  status: text("status").default("submitted"),
  createdAt: timestamp("created_at").defaultNow(),
});
```
[6]

This check is applied first inside Server Actions, then explicitly re-verified — Part 9's checkpoint confirms that Org A's user attempting to submit against Org B's `courseId` receives a "Rejected" error rather than a successful submission [1][6].

---

## B.4 The Threat Model, Reinforced Not Reinvented

Part 9's hardening pass is explicitly framed as reinforcement, not a rebuild — four of five defenses in its table point back at code already written in earlier parts [1]. Concretely verified checkpoints include:

- Cross-org submission attempts are rejected [1].
- A `student.struggling` event missing `submissionId` fails immediately rather than proceeding to run a tutor intervention [1].
- The `enabled == true` clause in `findWorkers`, built in Part 6, is the actual mechanism stopping a disabled worker from being called [4][1].

---

## B.5 Adaptive Event Chaining

Rather than one function with branching logic, adaptive behavior is modeled as independent, chained Inngest functions. Part 8's `aggregate-report` step produces the unified object that later logic reacts to:

```typescript
return {
  score: grading?.data?.score ?? null,
  quizGenerated: Boolean(quiz),
  workerCount: results.length,
};
```
[2]

This `report` object is what a future dashboard widget — or Part 10's observability tooling — reads as a single source of truth for "what happened to this submission" [2][11].

---

## B.6 Distributed Tracing Across Function Boundaries

The core observability mechanism is a trace ID generated once and threaded through the whole chain:

```typescript
// packages/events/trace.ts
import { randomUUID } from "crypto";

export function newTraceId(): string {
  return randomUUID();
}
```
[11]

Without it, `assignment-submitted` and `student-struggling` — built separately in Part 8 — look like two unrelated runs in the Inngest dashboard, with no way to prove they came from the same student action [11][2]. A debug timeline page renders the ordered list of every step for a given trace, with failed steps marked clearly in red — directly answering "why didn't the tutor intervention fire?" [11]

---

## B.7 Production Deployment as an Audit Trail

Every environment variable set in the Vercel dashboard during deployment traces back to a specific earlier part, functioning as a literal audit trail of the whole series [9]:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_xxxxxxxx   # Part 3
CLERK_SECRET_KEY=sk_live_xxxxxxxx                     # Part 3
DATABASE_URL=postgresql://...                          # Part 4
INNGEST_EVENT_KEY=xxxxxxxx                            # Part 5 / Part 9
INNGEST_SIGNING_KEY=xxxxxxxx                          # Part 5 / Part 9
WORKER_SIGNING_SECRET=xxxxxxxx                        # Part 7
```
[9][1][3]

Notably, `OPENAI_API_KEY` is never added to `apps/web` — it belongs only in each worker's own `.env`, since only workers are allowed to call AI models directly [10][12].

---

## B.8 A Deliberate Simplification Worth Noting

Not every AI capability in the series is a separately registered worker. Tutor intervention in Part 11 is built as a change *inside* the existing `student-struggling` Inngest function, rather than as its own registered worker — a deliberate simplification the source calls out explicitly, rather than a hidden inconsistency [10]. Lesson summaries, by contrast, are built as a genuinely new worker and new event (`lesson.completed`), making them "the clearest demonstration of 'new AI feature = new worker, no core changes' in the whole series" [10].

---

## B.9 What Changed, Part by Part — A Recap

Each part reinforces or extends exactly one part of the architecture, and nothing more [13]:

| Part | What it adds |
|---|---|
| 2 | Monorepo boundaries, mapped folder-to-layer [8] |
| 3 | Frontend shell, Clerk auth, route groups [7] |
| 4 | Neon/Drizzle schema, manual tenant isolation in place of RLS [6] |
| 5 | Real Inngest function, first event (`assignment.submitted`) [5] |
| 6 | Live Sanity registry, replacing a hardcoded worker list [4] |
| 7 | Worker contract, HMAC signing, first real registered worker [3] |
| 8 | Fan-out, fan-in, conditional event chaining [2] |
| 9 | Reinforced tenant checks, malformed-event rejection, threat model [1] |
| 10 | Trace IDs, distributed logging, debug timeline [11] |
| 11 | Real AI replacing every simulated worker, plus a brand-new worker [10] |
| 12 | Every layer deployed, env vars as an audit trail [9] |
