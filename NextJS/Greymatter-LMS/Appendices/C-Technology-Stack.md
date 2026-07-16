# Appendix C — Technology Stack Deep Dive

This appendix consolidates every technology referenced throughout the Greymatter LMS series into a single reference, answering for each one: *what is it normally used for, and how does Greymatter LMS use it — sometimes conventionally, sometimes not?* Where the original source material and the Greymatter adaptation diverge (notably Supabase → Neon), both are documented explicitly.

---

## C.1 Next.js (Application Layer)

**Normal use:** A React framework for building full-stack web applications with routing, server rendering, and API routes.

**Role in Greymatter LMS:** The frontend is deliberately kept "thin." Its entire job is captured in one architectural principle:

> "The frontend never makes educational decisions. It only: captures intent, writes state, emits events. Everything else is downstream." [7]

This is why, throughout the series, Server Actions never contain grading logic, quiz logic, or tutoring logic — they authenticate, validate, write to the database, and emit an event. Nothing more. Route structure follows a course-centric model, with dedicated route segments handling things like course views containing modules, lessons, and completion tracking [7].

The platform organizes its web codebase using functional **Route Groups** to mirror this usage layout:

* `(dashboard)`: Serves as the main platform shell, rendering student progress overviews, course timelines, and read-only AI analytics metrics [7].
* `(course)`: Orchestrates the structured core lesson experience—handling lessons, modular text contents, video elements, and static progression indicators [7].
* `(assignment)`: Manages the student assignment lifecycle, housing UI workflows for viewing descriptions, processing student input files, and displaying historical, read-only worker-generated AI feedback [7].

A second key principle governs how the frontend relates to AI features specifically:

> "AI is fully decoupled. Workers evolve independently." [7]

This means the frontend is never rebuilt or redeployed when a new AI worker is added — it only ever reacts to results that eventually land back in the database.

### Concrete Implementation Example

When a student interacts with an essay portal:

1. The student submits text through a form component inside the `(assignment)` route group [7].
2. A Next.js Server Action captures the submission text, maps the structural target, validates the session, and commits a record to the database [7].
3. The Server Action broadcasts an `assignment.submitted` event token to the event bus and instantly unlocks the UI with an acknowledgment state [2, 7].
4. The Next.js runtime does *not* invoke an LLM inline. It returns immediately, remaining highly responsive while background systems execute the grading routine out-of-band [2, 5].

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

* The "RLS enforced" step in the Defense-in-Depth chain above [1] becomes "manual `organization_id` checks in Server Actions and Inngest steps" in Greymatter LMS — the same *rule* (every table scoped by organization [6]) still applies, but it's enforced in application code rather than database policy.
* Auth moves entirely to Clerk (see C.5).
* We rely on Drizzle ORM as the query layer connecting Next.js and Inngest to Neon.

The underlying schema philosophy carries over unchanged — including the AI Artifact Tables pattern, which normalizes and separates AI-generated output from core system data [6] — only the hosting/enforcement mechanism changes.

### Concrete Schema & Query Example

To separate structural entities from unstructured AI output, the data layer utilizes explicit, multi-tenant schemas coupled with an isolated `worker_results` expansion target [6]:

```typescript
// Core system table enforcing organization boundaries via application code
export const assignments = pgTable("assignments", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(), // Absolute multi-tenant tracking key
  courseId: uuid("course_id").notNull(),
  title: text("title").notNull(),
  maxPoints: integer("max_points").default(100),
});

// Normalized AI Artifact Table separating raw model metadata from core entities
export const workerResults = pgTable("worker_results", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  submissionId: uuid("submission_id").notNull(),
  workerName: text("worker_name").notNull(), // e.g., "Markly"
  resultType: text("result_type").notNull(), // e.g., "grading"
  payload: jsonb("payload").notNull(),       // Raw JSON output from AI execution
  createdAt: timestamp("created_at").defaultNow(),
});

```

Because Neon Postgres does not filter these boundaries implicitly, a Greymatter data fetch must explicitly pass tenant validation criteria using Drizzle's logical filters [6]:

```typescript
export async function getTenantAssignments(currentOrgId: string, courseId: string) {
  return db
    .select()
    .from(assignments)
    .where(
      and(
        eq(assignments.orgId, currentOrgId), // Hard manual isolation barrier
        eq(assignments.courseId, courseId)
      )
    );
}

```

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

### Concrete Orchestration Example

The platform utilizes Inngest's multi-step step rehydration loop to reliably stitch together autonomous loops without side-effect leaks [5]:

```typescript
import { inngest } from "./client";

export const onAssignmentSubmitted = inngest.createFunction(
  { id: "assignment-submitted-flow" },
  { event: "assignment.submitted" },
  async ({ event, step }) => {
    // Step 1: Query database for student context metadata
    const context = await step.run("fetch-context", async () => {
      return await db.select().from(submissions).where(eq(submissions.id, event.data.submissionId));
    });

    // Step 2: Route payload securely to the grading worker discovered via the Registry
    const evaluation = await step.run("execute-grading-worker", async () => {
      return await callExternalWorker("Markly", { content: context.content });
    });

    // Step 3: Conditional branching enabling adaptive loops
    if (evaluation.score < 70) {
      await step.run("trigger-remediation-loop", async () => {
        // Emit secure internal chained event to launch independent tutor tracking
        return await inngest.send({
          name: "student.struggling",
          data: { submissionId: event.data.submissionId, currentScore: evaluation.score }
        });
      });
    }
  }
);

```

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

### Concrete Schema Example

Rather than schemas for landing pages, Sanity configures structural documents for live compute routes [4]:

```javascript
// sanity/schemas/workerDocument.js
export default {
  name: 'workerDocument',
  title: 'AI Worker Registry Target',
  type: 'document',
  fields: [
    { name: 'workerId', title: 'Unique Identifer Key', type: 'string' }, // e.g., "markly-essay-grader"
    { name: 'version', title: 'Semantic Version', type: 'string' },     // e.g., "2.4.0"
    { name: 'targetEndpoint', title: 'Worker HTTP Target URL', type: 'url' }, 
    { 
      name: 'capabilities', 
      title: 'Resolved Computing Capabilities', 
      type: 'array', 
      of: [{ type: 'string' }] // e.g., ["essay-grading", "rubric-validation", "sentiment-analysis"]
    },
    { name: 'lifecycleState', title: 'System Status', type: 'string', options: { list: ['alpha', 'beta', 'production', 'deprecated'] } }
  ]
}

```

---

## C.5 Clerk (Authentication)

**Role in Greymatter LMS:** Clerk handles authentication and organization membership. While the source material's Defense-in-Depth diagram shows validation happening at the "Server Actions (validated)" step before ever reaching the data layer [1], Clerk is what supplies the identity being validated at that step. In the Greymatter LMS adaptation (C.2), Clerk also absorbs the Auth responsibility that Supabase would otherwise have bundled in, since Neon does not provide it natively.

### Concrete Implementation Example

Inside a Next.js Server Action file, Clerk guarantees identity claims and yields multi-tenant partition parameters before any downstream processing:

```typescript
'use server'
import { auth } from "@clerk/nextjs/server";

export async function submitAssignmentAction(submissionPayload: unknown) {
  // Extract verified token claims directly out-of-band
  const { userId, orgId } = await auth();

  // Enforce zero-trust security assertion checks
  if (!userId || !orgId) {
    throw new Error("Authentication Failed: Invalid token context signature provided.");
  }

  // Safe to execute query operations under explicit application filtering boundaries
  await db.insert(submissions).values({
    orgId: orgId, // Absolute scope validation anchoring
    userId: userId,
    content: JSON.stringify(submissionPayload),
  });
}

```

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

### Concrete Implementation Example

External plug-ins receive structured context parameters and return standardized payloads implementing strict execution schemas [3]:

```typescript
// Shared input typing contract standard
interface WorkerInput {
  submission: { id: string; content: string };
  rubric: Record<string, unknown>;
}

// Strict standard output interface tracking metrics and telemetry costs
interface WorkerOutput {
  workerName: string;
  resultType: string;
  success: boolean;
  data: Record<string, unknown>;
  costCents: number; // Shared telemetry logging metric
}

// Concrete execution handler template for third-party endpoints
export async function POST(req: Request): Promise<Response> {
  const input: WorkerInput = await req.json();
  
  // Compute localized intelligence routines (e.g., executing specialized prompt sequences)
  const feedbackData = await executeIntelligenceModel(input.submission.content, input.rubric);

  const output: WorkerOutput = {
    workerName: "Markly Grading Engine",
    resultType: "grading",
    success: true,
    data: { feedback: feedbackData.text, score: feedbackData.numericGrade },
    costCents: 5 // Track token consumption expenditures
  };

  return new Response(JSON.stringify(output), { status: 200 });
}

```

---

## C.7 AI-Native Feature Layer

**Role in Greymatter LMS:** Rather than a single "technology," this is the pattern by which real AI capability gets attached to the system once the SDK, registry, and orchestration layers exist. Example capabilities documented in the series include automatically generated lesson summaries — described as "knowledge compression" [10] — and adaptive tutor output producing personalized explanations, learning path adjustments, and remediation suggestions [10]. All such AI output is persisted rather than discarded: "We persist all AI outputs" [10], feeding directly into the AI Artifact Tables pattern described in C.2 [6].

### Concrete Feature Example

A complete application loop for a "Lesson Knowledge Compression Summarizer" manifests as follows:

1. An instructor updates a text document inside a course outline layout interface.
2. The core system registers the update and fires off a decoupled background event notification.
3. Inngest traps the event payload and looks up a worker containing specialized synthesis capabilities within the registry [4, 5].
4. An external context-summarization worker receives the course raw text string data and applies structured prompt compression patterns.
5. The worker outputs a structured summary, returning it directly to the system of record [10].
6. The frontend renders this persistent record inside the read-only section of the student interface, serving as an on-demand study reference guide [7].

---

## C.8 Monorepo Tooling (Structural Layer)

**Role in Greymatter LMS:** The repository itself is treated as an architectural enforcement mechanism, not just a folder convention. The target structure explicitly separates the app, shared packages, and infrastructure:

```text
nexus-lms/

apps/
web/                      # Next.js LMS application

packages/
ui/                       # Shared UI components
types/                    # Shared TypeScript types
events/                   # Event contracts (VERY IMPORTANT)
sdk/                      # LMS client SDK
workers/                  # Worker SDK (for external AI tools)
registry/                 # Sanity registry client

infra/
db/                       # DB schema + migrations (Neon adaptation)
inngest/                  # event functions/workflows
sanity/                   # worker registry schemas

docs/
architecture/
tutorials/

```

[8]

This structure exists to enforce a specific dependency rule, stated directly as the reason the structure "works":

> "No hidden coupling. Everything depends on: events, contracts, registry. Not direct imports." [8]

This is the codebase-level mechanism that makes every other principle in this appendix possible — Next.js can't reach into a worker's internals, a worker can't reach into Next.js's internals, and Sanity/Inngest sit in between as the only sanctioned communication paths.

### Concrete Dependency Enforcement Example

If a developer needs to link the Next.js frontend app (`apps/web/`) to the AI orchestration framework:

* **Forbidden Pattern:** Direct import statements pointing across bounded layers (e.g., `import { runGrading } from '../../workers/grading/engine'`) are blocked by code structure and monorepo lint limits [8].
* **Sanctioned Pattern:** The frontend app imports standard, decoupled contract schemas from `@nexus/events` [8]. It uses those contracts to emit an asynchronous message. The worker project reads from the exact same event typing package to catch that payload on the other side of the system network. They never share execution paths or runtime code memory footprints [8].

---

## C.9 Production & Delivery Tooling (Capstone Layer)

**Role in Greymatter LMS:** At the capstone stage, the stack is completed with CI/CD pipeline architecture and a disaster recovery model [9], covering how every layer above — Next.js, Neon, Inngest, Sanity, and the worker fleet — gets deployed, monitored, and recovered in a production environment.

### Concrete Production Pipeline Example

During a continuous delivery run via GitHub Actions:

1. Code changes are verified through an analysis engine check to determine which workspace bounds were adjusted.
2. If changes are isolated to a single external worker codebase folder (e.g., updating prompt styles inside `TutorAI`), only that independent edge worker image is built and re-deployed [3].
3. The core `apps/web/` server cluster receives zero deployment impact updates, remaining live online throughout the release window [8, 9].
4. The engineer updates the version parameters inside the Sanity registry management dashboard, instantly routing net-new runtime traffic requests to the new worker endpoint without an application reboot cycle [4, 9].

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
