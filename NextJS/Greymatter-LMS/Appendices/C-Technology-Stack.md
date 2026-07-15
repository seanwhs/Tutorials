# Appendix C — Technology Stack Deep Dive

This appendix consolidates every technology referenced throughout the Greymatter LMS series into a single reference, answering for each one: *what is it normally used for, and how does Greymatter LMS use it — sometimes conventionally, sometimes not?* Where the original source material and the Greymatter adaptation diverge (notably Supabase → Neon), both are documented explicitly.

---

## C.1 Next.js (Application Layer)

**Normal use:** A React framework for building full-stack web applications with routing, server rendering, and API routes.

**Role in Greymatter LMS:** The frontend is deliberately kept "thin." Its entire job is captured in one architectural principle:

> "The frontend never makes educational decisions. It only: captures intent, writes state, emits events. Everything else is downstream." [7]

This is why, throughout the series, Server Actions never contain grading logic, quiz logic, or tutoring logic — they authenticate, validate, write to the database, and emit an event. Nothing more. Route structure follows a course-centric model, with dedicated route segments handling things like course views containing modules, lessons, and completion tracking [7].

A second key principle governs how the frontend relates to AI features specifically:

> "AI is fully decoupled. Workers evolve independently." [7]

This means the frontend is never rebuilt or redeployed when a new AI worker is added — it only ever reacts to results that eventually land back in the database.

---

## C.2 Supabase → Neon Postgres (Data Layer)

**Normal use (original source material):** Supabase bundles Postgres hosting, Auth, and Row-Level Security (RLS) policies together, and is used throughout the original architecture as the Data Layer, explicitly appearing in the Defense-in-Depth chain:

```text
Client Layer (untrusted)
↓
Server Actions (validated)
↓
Supabase (RLS enforced)
↓
Inngest (controlled execution)
↓
Registry (sanitized worker discovery)
↓
Workers (isolated execution)
```
[1]

The core schema design in the original material centers on this same database, with an optional expansion layer specifically for AI outputs — normalizing artifacts so raw AI output doesn't get mixed with system data [6]. The architecture's safety guarantee is stated plainly: "Every table is scoped by organization" [6], which is what "Supabase (RLS enforced)" in the diagram above is actually protecting.

**Greymatter LMS adaptation:** We use **Neon Postgres** instead of Supabase. Neon gives us hosted Postgres, but *not* Auth or RLS. Practically, this means:

- The "RLS enforced" step in the Defense-in-Depth chain above [1] becomes "manual `organization_id` checks in Server Actions and Inngest steps" in Greymatter LMS — the same *rule* (every table scoped by organization [6]) still applies, but it's enforced in application code rather than database policy.
- Auth moves entirely to Clerk (see C.5).
- We rely on Drizzle ORM as the query layer connecting Next.js and Inngest to Neon.

The underlying schema philosophy carries over unchanged — including the AI Artifact Tables pattern, which normalizes and separates AI-generated output from core system data [6] — only the hosting/enforcement mechanism changes.

---

## C.3 Inngest (Orchestration Layer)

**Normal use:** A durable workflow/event-processing engine for background jobs, retries, and multi-step function execution.

**Role in Greymatter LMS:** Inngest is the literal embodiment of the series' central architectural rule:

> "The LMS does not execute intelligence. It orchestrates intelligence execution." [5]

The dedicated tutorial for this layer is framed explicitly as "Inngest, Orchestration, and AI Worker Execution" [5] — not "Inngest, AI, and Grading," reinforcing that Inngest's job is coordination, never intelligence itself.

Beyond basic event handling, Inngest also powers the series' advanced orchestration patterns, introduced under the heading "Advanced Orchestration Patterns" [2], including **Conditional Workflows (Adaptive AI)** — described as the point "where LMS becomes intelligent" [2] — and the canonical adaptive learning sequence:

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

Inngest also underpins observability in Greymatter LMS. Each workflow run generates a trace ID, and the tracing system itself is explicitly noted as "Powered by Inngest" [11], tying back to the observability principle: "If you cannot trace it, you cannot trust it." [11]

---

## C.4 Sanity (Registry Layer)

**Normal use:** A headless CMS for managing structured content such as blog posts, marketing pages, or product catalogs.

**Role in Greymatter LMS (deliberately unconventional):** Sanity is explicitly repurposed away from its typical CMS role:

> "Powered by Sanity. Stores: AI workers, tool definitions, schemas, execution metadata. This is NOT content management. It is a runtime registry for AI capabilities." [12]

This role is reinforced again at the capstone level, where the registry's function is summarized in a single line:

> "Role: dynamic AI plug-in system" [9]

Every worker is modeled as a **Worker Document** inside Sanity [4], and the registry supports more than simple event-name matching — it also supports **capability-based extension**, an explicitly flagged "Important Upgrade": "We don't just match by event. We also support capabilities." [4] This lets the registry answer richer questions than "who listens to `assignment.submitted`?" — it can also answer "who is *capable* of grading essays?" regardless of event wiring.

Sanity also carries the system's **versioning strategy**, since workers are expected to evolve independently over time:

```text
Markly v1 → Markly v2 → Markly v3
```
[4]

Every worker also follows a strict lifecycle defined at the system-architecture level [12], and Sanity is the system of record tracking where each worker currently sits in that lifecycle.

---

## C.5 Clerk (Authentication)

**Role in Greymatter LMS:** Clerk handles authentication and organization membership. While the source material's Defense-in-Depth diagram shows validation happening at the "Server Actions (validated)" step before ever reaching the data layer [1], Clerk is what supplies the identity being validated at that step. In the Greymatter LMS adaptation (C.2), Clerk also absorbs the Auth responsibility that Supabase would otherwise have bundled in, since Neon does not provide it natively.

---

## C.6 Worker SDK (Execution Layer Contract)

**Normal use:** N/A — this is a custom layer built specifically for this architecture, not an off-the-shelf product.

**Role in Greymatter LMS:** The Worker SDK is the standardized interface every AI tool must implement to participate in the system, introduced under the heading "Worker SDK & External AI Integration Layer" [3]:

> "We define a standard SDK interface." [3]

This SDK is what enables an entire third-party ecosystem of pluggable tools, illustrated as:

```text
Nexus Marketplace
|
+-- Markly (grading)
+-- TutorAI
+-- ExamGuard
+-- InsightAI
```
[3]

Each of these is independently deployed and independently maintained, consistent with the philosophy principle that workers "must conform to a schema, not internal logic" [13] — the SDK enforces the schema; everything behind it is the worker author's business.

---

## C.7 AI-Native Feature Layer

**Role in Greymatter LMS:** Rather than a single "technology," this is the pattern by which real AI capability gets attached to the system once the SDK, registry, and orchestration layers exist. Example capabilities documented in the series include automatically generated lesson summaries — described as "knowledge compression" [10] — and adaptive tutor output producing personalized explanations, learning path adjustments, and remediation suggestions [10]. All such AI output is persisted rather than discarded: "We persist all AI outputs" [10], feeding directly into the AI Artifact Tables pattern described in C.2 [6].

---

## C.8 Monorepo Tooling (Structural Layer)

**Role in Greymatter LMS:** The repository itself is treated as an architectural enforcement mechanism, not just a folder convention. The target structure explicitly separates the app, shared packages, and infrastructure:

```text
nexus-lms/

apps/
web/                      # Next.js LMS application

packages/
ui/                       # Shared UI components
types/                   # Shared TypeScript types
events/                  # Event contracts (VERY IMPORTANT)
sdk/                     # LMS client SDK
workers/                 # Worker SDK (for external AI tools)
registry/                # Sanity registry client

infra/
supabase/                # DB schema + migrations
inngest/                 # event functions/workflows
sanity/                  # worker registry schemas

docs/
architecture/
tutorials/
```
[8]

*(Greymatter LMS note: `infra/supabase/` becomes `infra/db/` when following the Neon adaptation from C.2.)*

This structure exists to enforce a specific dependency rule, stated directly as the reason the structure "works":

> "No hidden coupling. Everything depends on: events, contracts, registry. Not direct imports." [8]

This is the codebase-level mechanism that makes every other principle in this appendix possible — Next.js can't reach into a worker's internals, a worker can't reach into Next.js's internals, and Sanity/Inngest sit in between as the only sanctioned communication paths.

---

## C.9 Production & Delivery Tooling (Capstone Layer)

**Role in Greymatter LMS:** At the capstone stage, the stack is completed with CI/CD pipeline architecture and a disaster recovery model [9], covering how every layer above — Next.js, Neon, Inngest, Sanity, and the worker fleet — gets deployed, monitored, and recovered in a production environment.

---

## C.10 How to Use This Appendix

When you're unsure why a piece of tech was chosen, or whether you're using it "correctly":

1. **Is it rendering UI or handling user input?** → C.1 (Next.js)
2. **Is it storing or querying data?** → C.2 (Neon/Supabase)
3. **Is it deciding what happens next after an event?** → C.3 (Inngest)
4. **Is it storing worker definitions or capabilities?** → C.4 (Sanity) — remember, this is a registry, not a CMS [12]
5. **Is it about who the user is?** → C.5 (Clerk)
6. **Is it about how an external AI tool plugs in?** → C.6 (Worker SDK)
7. **Is it an actual AI capability (summaries, grading, tutoring)?** → C.7
8. **Is it about folder structure or dependency rules?** → C.8 (Monorepo)
9. **Is it about deployment or recovery?** → C.9 (Capstone tooling)
