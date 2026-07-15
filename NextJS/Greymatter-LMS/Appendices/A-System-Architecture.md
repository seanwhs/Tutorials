# Appendix A — System Architecture Reference

This appendix consolidates every architectural fact scattered across Parts 0, 1, 8, 9, 10, and 12 into a single reference page. Bookmark this — it's the page you'll return to whenever you forget "wait, what does Sanity actually store again?" or "which layer owns tenant isolation?"

---

## A.1 The Foundational Principle

Everything in Greymatter LMS's architecture flows from one sentence, stated as the key architectural principle of the entire series:

> "The LMS does not execute intelligence. It orchestrates intelligence execution." [5]

Every diagram, every layer boundary, and every design decision in this appendix exists to enforce that one rule. If you remember nothing else from this series, remember this.

---

## A.2 The Conceptual Model (Where It All Started)

Before any real infrastructure existed, the series' final conceptual model looked like this [13]:

```text
Clerk
|
V
+-----------------------------+
|        Next.js LMS         |
+-----------------------------+
|              |
|              |
V              V
Courses        Assignments
|
V
Inngest Event Bus
|
V
Worker Registry (Sanity)
|
+---------+---------+---------+
|         |         |         |
V         V         V         V
Grading   Quizzes   Tutors   Analytics
```
[13]

This model established the shape everything else follows: **auth sits above the app, the app talks to an event bus, the event bus consults a registry, and the registry fans out to independent AI workers.** Note also the design rule guiding this: workers must conform to a schema, not internal logic — contracts over implementations [13]. Nothing downstream cares *how* a worker does its job, only that it honors its input/output contract.

---

## A.3 The Five Architectural Layers

Every request in Greymatter LMS passes through five layers, each with one job. This table is the single most-referenced structure in the entire series [12] [9]:

| Layer | Owns | Explicitly does NOT own |
|---|---|---|
| **Client/Application** (Next.js) | UI rendering, event emission, auth checks | AI logic, workflow definitions, worker logic |
| **Data** (Postgres) | System of record, raw + derived data storage | Deciding which workers run |
| **Orchestration** (Inngest) | Event bus, workflow execution, retries, chaining | AI model execution itself |
| **Registry** (Sanity) | Worker discovery, capability matching, versioning | Content management (despite being a CMS) [12] |
| **Execution** (AI Workers) | Actual intelligence — grading, quizzes, tutoring, analytics | LMS business rules, direct database writes outside their own results |

The Registry layer deserves special emphasis because it's the most counter-intuitive piece of the stack. It is explicitly described as **not** content management, but rather "a runtime registry for AI capabilities," storing AI workers, tool definitions, schemas, and execution metadata [12].

---

## A.4 The Multi-Tenant Isolation Principle

Layered on top of all five architectural layers is a non-negotiable rule that cuts across every one of them:

> Every piece of data belongs to `organization_id`. No exceptions. [1]

This means the isolation boundary isn't a feature of one layer — it's a constraint every layer must respect independently:

- The **Application layer** must check `organization_id` before every read/write.
- The **Data layer** stores `organization_id` on every scoped table.
- The **Orchestration layer** must re-verify `organization_id` inside workflow steps, not just trust the caller.
- Data is, without exception, always scoped this way [1].

This principle is why, architecturally, "data is always scoped" appears as its own dedicated rule rather than an implementation detail [1].

---

## A.5 Worker Execution Model — The Fan-Out Pattern

The core execution pattern that makes the whole system "AI-native" rather than "AI-bolted-on" is this: one event, many independent workers, executed in parallel [5]:

```text
assignment.submitted
|
+--> Markly (grading)
+--> Plagiarism detector
+--> Tutor AI
+--> Analytics engine
```
[5]

Each worker here is executed **independently** [5] — meaning none of them know about each other, none of them block each other, and any one of them can fail without affecting the others. This is the architectural realization of the fan-out concept, and it directly enables the registry's discovery result for a typical event:

```text
assignment.submitted
```
Registry returns:
```text
- Markly Grader
- Plagiarism Checker
- Tutor AI
- Analytics Engine
```
[4]

---

## A.6 Fan-In — Aggregating Independent Results

Fan-out alone only gets you parallel execution; fan-in is what turns four unrelated worker outputs into one coherent artifact. The canonical example from the series:

```text
Markly Score: 87
Tutor Feedback: "Improve clarity"
Analytics: "Struggling in recursion"
Quiz: Generated
↓
Unified Learning Report
```
[2]

---

## A.7 Conditional & Adaptive Workflows

This is described as the point "where LMS becomes intelligent" [2] — the moment the architecture stops being purely reactive (event → workers → done) and starts chaining conditionally based on outcomes. The canonical adaptive learning flow:

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

This is supported architecturally by **optional event chaining**, where workers may emit new events themselves rather than the frontend driving every step:

```text
Markly → grading.completed
```
[12]

Notice what this implies structurally: the frontend never needs to know this chain exists. As stated directly in the series' event-contract principle: the frontend only knows "something happened," not "what happens next" [7]. Events *are* the contract between layers [7].

---

## A.8 Worker Evolution — Versioning as an Architectural Concern

Because workers are decoupled from the LMS core, they're also allowed to evolve independently of it — a first-class architectural concern, not an afterthought:

```text
Markly v1 → Markly v2 → Markly v3
```
[4]

This is only possible because of the contracts-over-implementations rule established back in the philosophy layer [13] — as long as a new worker version honors the same input/output schema, the registry, the orchestrator, and the frontend never need to change.

---

## A.9 Observability as an Architectural Layer, Not a Bolt-On

The series treats tracing as architecture, not tooling, governed by its own key principle:

> "If you cannot trace it, you cannot trust it." [11]

Every operation in the system becomes a **trace tree**, rooted at the originating event:

```text
Event (root)
├── Workflow step
│     ├── Worker A
│     ├── Worker B
│     └── Worker C
└── Aggregation step
```
[11]

Each Inngest workflow generates a trace ID [11], which is what allows the multi-hop chains from A.7 to be followed and debugged as one logical unit rather than a series of disconnected function calls.

---

## A.10 The Production Architecture Diagram

Pulling every layer above together, this is the full production topology defined in the capstone [9]:

```text
Users
↓
Next.js (Frontend)
↓
Supabase (DB + Auth + RLS)
↓
Inngest (Event Engine)
↓
Sanity (Worker Registry)
↓
AI Workers (Distributed Systems)
↓
Supabase (Results Storage)
```
[9]

**Note for Greymatter LMS builders:** this diagram in its original form uses Supabase for the Data layer, bundling DB + Auth + RLS together [9]. If you're following the Greymatter LMS adaptation of this series (Neon Postgres + Clerk + Drizzle instead of Supabase), mentally substitute:

```text
Supabase (DB + Auth + RLS)  →  Neon Postgres (DB) + Clerk (Auth) + manual org_id checks (Part 9's isolation principle, A.4 above)
```

Every other layer — Next.js, Inngest, Sanity, AI Workers — carries over unchanged, since the orchestration and registry layers were never coupled to Supabase specifically. The Workflow Engine in particular is explicitly noted as simply "Powered by Inngest" [9], with no dependency on the database vendor beneath it.

---

## A.11 How to Use This Appendix

When you're mid-tutorial and lose track of *why* a piece of code is structured a certain way, come back here and ask:

1. **Which of the five layers (A.3) is this code in?** That tells you what it's allowed and not allowed to do.
2. **Does this touch data?** If yes, check A.4 — it must be `organization_id`-scoped, no exceptions.
3. **Is this a worker?** Check A.5–A.8 — it must be independently executable, contract-conforming, and versionable without touching the core.
4. **Am I debugging a chain?** Check A.6–A.9 — follow the trace ID, look at the trace tree, not just one function's logs.
5. **Am I deploying?** Check A.10 for the full production topology and the Supabase→Neon/Clerk substitution if you're building Greymatter LMS specifically.
