# Appendix C — Technology Stack Deep Dive (with Examples)

Here's Appendix C with concrete examples added to each section, grounded in the source material.

---

## C.1 Next.js (Application Layer)

**Normal use:** A React framework for building full-stack web applications with routing and server rendering.

**Role in Greymatter LMS:** The frontend stays deliberately thin, organized into route groups matching the LMS's actual usage patterns. The `(dashboard)` route group serves as the main LMS shell, containing course overview, assignments, progress tracking, and AI-generated insights displayed read-only [7]. The `(course)` route group handles the course view itself — modules, lessons, and completion tracking [7]. The `(assignment)` route group covers the full assignment lifecycle: view, submit, review results, and AI feedback display [7].

**Example:** When a student navigates to an assignment, they move through the `(assignment)` route group's lifecycle — viewing the prompt, submitting their work, and eventually reviewing results with AI feedback rendered on the page [7]. Critically, notice that "AI-generated insights" in the dashboard and "AI feedback display" in the assignment view are both explicitly listed as **display only** [7] — the Next.js layer never generates that feedback itself, it only renders whatever a worker already produced.

---

## C.2 Supabase → Neon Postgres (Data Layer)

**Normal use (original source material):** Supabase bundles Postgres, Auth, and RLS, and is used as the Data Layer, enforcing Row-Level Security in the Defense-in-Depth chain [1].

**Example:** The `assignments` table stores structured records with `course_id`, `lesson_id`, `title`, `description`, and `due_date` [6]. Separately, the Core Schema Design section defines what AI workers write back into this same data layer — quiz generation, grading results, summaries, tutor feedback, and analytics insights [6] — all stored as outputs distinct from the original assignment record itself.

**Greymatter LMS adaptation example:** Since Neon lacks Supabase's RLS enforcement step in the Defense-in-Depth chain [1], a Greymatter LMS developer must manually replicate that protection — for instance, explicitly filtering the `assignments` query by the requesting user's organization before returning results, rather than relying on an automatic database policy.

---

## C.3 Inngest (Orchestration Layer)

**Normal use:** A durable workflow/event-processing engine for background jobs and multi-step function execution.

**Role in Greymatter LMS:** Inngest embodies the core principle: "The LMS does not execute intelligence. It orchestrates intelligence execution" [5]. This layer also sits in the middle of the Defense-in-Depth chain as the "controlled execution" step, positioned between the database and the registry [1].

**Example:** The Adaptive Learning Flow shows Inngest orchestrating a full sequential pipeline:

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

A more specific chained example shows exactly which events fire in sequence: `assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned` [2], explicitly described as creating "adaptive learning loops" [2]. Inngest also handles fan-in aggregation — for example, combining a Markly score of 87, tutor feedback of "Improve clarity," an analytics note of "Struggling in recursion," and a generated quiz into one Unified Learning Report [2].

---

## C.4 Sanity (Registry Layer)

**Normal use:** A headless CMS for managing structured content.

**Role in Greymatter LMS (deliberately unconventional):** Explicitly "NOT content management. It is a runtime registry for AI capabilities" [12], where every AI tool is modeled as a **Worker Document** [4].

**Example:** Markly, the grading worker, is registered as a Worker Document and evolves over time with a tracked version history: "Markly v1 → Markly v2 → Markly v3" [4], since "workers evolve independently" [4]. This same registry model is what enables a broader ecosystem to form — as the source material states, "You can build: LMS App Store, AI Worker Marketplace, Educational plugin ecosystem" [4] — all built on top of the same Worker Document schema used for Markly.

---

## C.5 Clerk (Authentication)

**Role in Greymatter LMS:** Clerk supplies the validated identity that the "Server Actions (validated)" step in the Defense-in-Depth chain relies on before any request proceeds to the data layer [1].

**Example:** Every request that eventually touches organization-scoped data — per the rule that "everything is organization-bound" [1] — depends on Clerk having already established who the user is and which organization they belong to, before the Server Action or database layer ever runs its own checks.

---

## C.6 Worker SDK (Execution Layer Contract)

**Normal use:** N/A — a custom layer built specifically for this architecture.

**Role in Greymatter LMS:** The Worker SDK is introduced under "Tutorial 07: Building the Developer Interface for AI Plug-ins" [3], where "We define a standard SDK interface" [3].

**Example:** The example ecosystem this SDK enables includes:

```text
Nexus Marketplace
|
+-- Markly (grading)
+-- TutorAI
+-- ExamGuard
+-- InsightAI
```
[3]

Each of these — Markly, TutorAI, ExamGuard, InsightAI — is built by conforming to the same standard SDK interface [3], which is what makes them interchangeable plug-ins rather than bespoke integrations each requiring custom LMS code.

---

## C.7 AI-Native Feature Layer

**Role in Greymatter LMS:** The pattern by which real AI capability attaches once the SDK, registry, and orchestration layers exist.

**Example:** Lesson Summaries are described as "Auto-Generated Knowledge Compression" [10] — an LLM condenses lesson content automatically. Separately, the Tutor AI layer produces personalized explanations, learning path adjustments, and remediation suggestions [10] as its output. Both of these are grounded by the same key architectural principle governing this whole layer: "Learning is not delivered. It is continuously inferred" [10] — meaning these features aren't static content, but ongoing, recalculated interpretations of student behavior.

---

## C.8 Monorepo Tooling (Structural Layer)

**Role in Greymatter LMS:** The repository enforces architectural boundaries structurally, guided by the principle: "No hidden coupling. Everything depends on: events, contracts, registry. Not direct imports" [8].

**Example:** Because of this rule, adding a new AI capability follows a specific, constrained path: "Add new worker + register in Sanity. No LMS rewrite required" [8] — described as "Full extensibility" [8]. For instance, adding a brand-new plagiarism-detection worker would mean writing the worker itself and registering it in Sanity, without touching or redeploying the core LMS codebase at all.

---

## C.9 Production & Delivery Tooling (Capstone Layer)

**Role in Greymatter LMS:** Covers CI/CD Pipeline Architecture for the whole stack [9].

**Example:** This same extensibility principle carries all the way to the capstone level, restated as "Platform extensibility: New features = new workers, not code rewrites" [9] — confirming that the CI/CD pipeline only needs to redeploy the core LMS when the core itself changes, not every time a new worker is registered.

---

## C.10 How to Use This Appendix

Use the worked examples above as a template: when you're unsure which technology owns a piece of behavior you're building, find the closest matching example here (a route lifecycle, a chained event, a Worker Document, an SDK-conforming plug-in) and follow the same pattern for your own feature.
