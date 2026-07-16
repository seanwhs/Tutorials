# Appendix C — Technology Stack Reference

This appendix documents each major technology used across the Greymatter LMS series, based strictly on what the tutorials actually build.

---

## C.1 Next.js (Application Layer)

Next.js is the Client + Application Layer. Its job is strictly bounded: it does **not** run AI, orchestrate workflows, or execute business logic [12]. The rule is stated bluntly in the source material as "no AI logic in the frontend," enforced literally with folder structure and lint rules starting in Part 3 [7][12].

A component in the Application Layer only ever talks to the layer directly below it — a React component never queries Neon directly; it always goes through a Server Action [12]. In practice, this means Server Actions authenticate the user, write to the database, and emit an event — nothing more.

Part 3 builds the route structure using route groups to separate unauthenticated pages from the authenticated dashboard:

```bash
mkdir -p src/app/(auth)/sign-in/[[...sign-in]]
mkdir -p src/app/(auth)/sign-up/[[...sign-up]]
mkdir -p src/app/(dashboard)/courses
mkdir -p src/app/(dashboard)/assignments
```

Route groups in parentheses don't affect the URL — `(dashboard)/courses` still resolves to `/courses` [7]. Clerk middleware then protects specific routes:

```typescript
const isProtectedRoute = createRouteMatcher(["/courses(.*)", "/assignments(.*)"]);

export default clerkMiddleware(async (auth, req) => {
  if (isProtectedRoute(req)) {
    await auth.protect();
  }
});
```
[7]

---

## C.2 Neon Postgres, in place of Supabase (Data Layer)

The original architecture notes used Supabase for the Data Layer, with Row-Level Security (RLS) enforcing tenant isolation directly in the database [12]. Greymatter LMS uses Neon Postgres instead, which means two responsibilities Supabase would have handled for free are taken on manually:

| Responsibility | Supabase (original) | Greymatter (Neon) |
|---|---|---|
| Database hosting | Supabase Postgres | Neon Postgres (serverless, branchable) [6] |
| Auth | Supabase Auth | Clerk [6] |
| Tenant isolation | Row-Level Security (RLS) policies | Enforced in application code via Drizzle ORM queries, checked against the Clerk `orgId` [6] |
| Client SDK | `@supabase/supabase-js` | Drizzle ORM + plain SQL via `pg` [6] |

The schema itself carries an explicit `orgId` column on every tenant-scoped table:

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

The schema is defined up front in Part 4 specifically because Part 5's Inngest function needs somewhere to persist results immediately, and Part 7 onward assumes `worker_results` already exists — meaning every later part can `import` from `infra/db/schema` without hitting a missing-table error [6].

---

## C.3 Inngest (Orchestration Layer)

Inngest is the **only** layer allowed to decide "this event happened, go run these workers" — neither the frontend nor the database is allowed to make that decision [5][12]. Part 5 is explicitly where this rule "stops being a diagram and becomes real, running code" [5].

Two things in the Part 5 pipeline are deliberately left as placeholders at first: `discover-workers` returns a hardcoded array instead of querying a real registry, and `execute-workers` just logs instead of actually calling an HTTP endpoint — deliberate scaffolding to prove the orchestration shape works end-to-end before Part 6 adds a real registry and Part 7 adds a real, signed worker contract [5][4][3].

Part 8 goes further, building parallel AI execution strategies, result aggregation systems, conditional workflows, adaptive learning pipelines, and retry/compensation flows [2].

---

## C.4 Sanity (Registry Layer)

Sanity is the **only** place that knows "these workers exist and listen to these events" [12]. The reasoning against a simpler alternative is explicit: a hardcoded array of workers in a TypeScript file would live *inside* the Orchestration Layer's codebase, meaning every new worker requires a code change and a redeploy. A real registry instead lets a worker be added, disabled, or swapped as a **content edit**, with zero code changes to Inngest or the frontend [4].

This is proven directly as a checkpoint: toggling `enabled` to `false` on a worker's Sanity document, publishing with no code touched, and confirming `discover-workers` returns an empty array — then flipping it back and confirming the worker is discovered again [4].

**🩹 Common confusion (from the source):** "If anyone can create a Sanity document with any `endpoint` URL, what stops a malicious or broken worker from being registered?" — Nothing yet, deliberately, to keep the registry mechanism simple to learn first. Part 7 introduces the signed request/response contract that closes this gap, and Part 9's threat model explicitly revisits "disabled/malicious worker still executing" as a named threat [4][3][1].

---

## C.5 Worker SDK (Execution Layer Contract)

The Execution Layer is the **only** place AI logic actually lives, and it's meant to be independently deployable — in any language, anywhere [12]. That only works safely if every worker agrees on the exact same shape of data coming in and going out, which is why `packages/workers` was scaffolded back in Part 2 specifically to hold this shared contract [3][8].

Every request is signed and every response verified before being trusted:

```typescript
const output = await res.json();
const outSignature = res.headers.get("x-signature") ?? "";

if (!verifySignature(output, outSignature, SECRET)) {
  throw new Error(`Worker ${worker.name} returned an invalid signature`);
}

return output;
```
[3]

**✅ Checkpoint:** With the Grading Worker running (`localhost:4000`) and its Sanity registry document still pointing at that URL, resubmit an assignment. Confirm `execute-workers` shows a real score in its output — not the placeholder `{}` from Part 5 — and confirm `persist-results` writes that score into `worker_results` in Neon [3].

---

## C.6 Clerk (Authentication)

Clerk handles authentication and organization membership, and in the Neon-based adaptation, it also absorbs the Auth responsibility Supabase would otherwise have bundled in [6]. A Server Action re-checks identity before any downstream processing — this is proven directly in Part 9's checkpoint confirming Org A's user attempting to submit against Org B's `courseId` receives a "Rejected" error [1].

---

## C.7 AI-Native Feature Layer

Part 11 replaces every simulated worker with real AI — grading, quizzes, tutoring, summaries, and knowledge graph extraction [13][10]. Lesson summaries are called out as "the clearest demonstration of 'new AI feature = new worker, no core changes' in the whole series" — they don't hook into `assignment.submitted` at all, requiring an entirely new event, `lesson.completed`, registered exactly the same way every worker has been since Part 6 [10]:

```json
{
  "name": "Summary Worker",
  "enabled": true,
  "events": ["lesson.completed"],
  "endpoint": "http://localhost:4003/api/summary-worker"
}
```
[10]

Notably, tutor intervention is a deliberate exception to the "every capability is its own worker" pattern — it's built as a change *inside* an existing Inngest function rather than a new registered worker, which the source calls out explicitly as "a deliberate simplification worth noting" [10]. By the end of Part 11, every worker — Grading, Quiz, Tutor logic, Summary, and Knowledge Graph — runs real AI using only mechanisms already built in earlier parts, with no core file in `apps/web`, `infra/inngest`, or `packages/registry` ever modified [10].

---

## C.8 Monorepo Structure (Structural Layer)

Since Greymatter LMS deliberately separates the Application Layer from the Orchestration, Registry, and Execution layers, those boundaries need to be *visible* in the codebase, not just remembered [8][12]. If the Application Layer ever tries to import something it shouldn't — like worker execution logic — that becomes an obvious, catchable mistake rather than a subtle architectural violation [8].

Mapping folders to layers:

| Folder | Layer it serves | Why it's separate |
|---|---|---|
| `apps/web` | Client + Application | The only place UI renders and Server Actions run [8] |
| `packages/events` | Orchestration (contract) | Shared event shape — imported by both the frontend and Inngest functions, so neither one "owns" it [8] |
| `packages/types` | Cross-cutting | Shared TypeScript types used across the app and workers [8] |
| `packages/sdk` | Application | A client SDK for interacting with Greymatter LMS [8] |
| `packages/workers` | Execution (contract) | The `WorkerInput`/`WorkerOutput` shape and signing helpers every worker implements, starting in Part 7 [8] |
| `packages/registry` | Registry | The client used to query the Sanity worker registry, starting in Part 6 [8] |

---

## C.9 Observability (Tracing & Debugging)

Part 10 addresses an honest gap left at the end of Part 9: very little visibility exists into what's happening when something goes wrong, with the only debugging tool being manual reading of the Inngest dashboard [11][1]. The core mechanism is a **trace ID** — generated once at the start of a request and threaded through every downstream event, worker call, and log line, even across function boundaries:

```typescript
// packages/events/trace.ts
import { randomUUID } from "crypto";

export function newTraceId(): string {
  return randomUUID();
}
```
[11]

Without this, `assignment-submitted` and `student-struggling` — built separately in Part 8 — look like two unrelated runs in the Inngest dashboard, with no way to prove they came from the same student action [11][2]. A `/debug/<traceId>` page renders the ordered list of every step for that trace, with failed steps marked clearly in red [11].

---

## C.10 Production Deployment (Capstone Layer)

Part 12 deploys the frontend to Vercel, with environment variables in the dashboard forming a direct audit trail of the series:

**✅ Checkpoint:** Run `vercel` from `apps/web` (after installing it globally with `pnpm add -g vercel`) [9]. Set your environment variables in the Vercel dashboard, matching every `.env.local` value accumulated since Part 3:

```bash
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=pk_live_xxxxxxxx
CLERK_SECRET_KEY=sk_live_xxxxxxxx
DATABASE_URL=postgresql://user:password@your-neon-host/greymatter?sslmode=require
INNGEST_EVENT_KEY=xxxxxxxx
INNGEST_SIGNING_KEY=xxxxxxxx
WORKER_SIGNING_SECRET=xxxxxxxx
```
[9]

This list is a direct audit trail of the series: `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`/`CLERK_SECRET_KEY` from Part 3's Clerk setup, `DATABASE_URL` from Part 4's Neon connection, `INNGEST_EVENT_KEY`/`INNGEST_SIGNING_KEY` from Part 5/9's orchestration and spoofed-event defenses [1], and `WORKER_SIGNING_SECRET` from Part 7's HMAC signing scheme [3]. If any of these feel unfamiliar, that's a signal to revisit the part that introduced them before continuing [9].

Once deployed, the full production flow can be traced end-to-end: the student's dashboard reloads and shows a real score, real feedback, and a real quiz [9]. The final checkpoint for the whole series confirms this entire chain completes with a real trace ID visible in `workflow_logs`, exactly as it did locally in Part 10 — proving observability survived the move to production, not just functionality [9][11].

---

## Series Complete

Starting from a 10-line `emit()` simulation in Part 0 [13], the series builds, in order: a five-layer architecture [12], a boundary-enforcing monorepo [8], a Clerk-authenticated Next.js frontend [7], a full Neon/Drizzle schema [6], a real Inngest orchestration pipeline [5], a live Sanity worker registry [4], a signed Worker SDK [3], fan-out/fan-in/event chaining [2], a hardened threat model [1], a full observability pipeline [11], real AI-native features [10], and a complete production deployment [9]. Every part built on the one before it, every checkpoint was something you could verify yourself, and every AI capability was added without ever touching the LMS core — proving the philosophy this whole series started with: **events, not features** [13].
