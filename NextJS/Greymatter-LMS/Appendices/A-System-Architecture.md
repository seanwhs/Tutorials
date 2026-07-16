# Appendix A — System Architecture Reference

This appendix consolidates every architectural truth scattered across Parts 0, 1, 8, 9, 10, and 12 into a single, definitive reference page. Bookmark this page—it is the source of truth you will return to whenever you need to verify layer boundaries, worker behaviors, or data ownership rules.

---

## A.1 The Foundational Principle

Every diagram, layer boundary, and design decision in the system exists to enforce a single, absolute rule:

> "The LMS does not execute intelligence. It orchestrates intelligence execution." [5]

**Example:** When a student submits an assignment, the core application simply emits an `assignment.submitted` event. The actual cognitive work—the grading, analysis, and feedback generation—is completely offloaded to isolated AI workers [5]. The core LMS engine never runs a machine learning model directly; it only coordinates the lifecycle of its execution.

---

## A.2 The Conceptual Model

Before concrete infrastructure was provisioned, the architectural decoupling was defined by a contracts-over-implementations model [13]. Workers must strictly conform to a predefined input/output schema rather than internal application logic:

```text
               [ Clerk (Auth) ]
                      |
                      v
            +-------------------+
            |    Next.js LMS    |
            +-------------------+
             /                 \
            v                   v
       [ Courses ]         [ Assignments ]
            \                   /
             v                 v
          [ Inngest Event Bus ]
                      |
                      v
         [ Worker Registry (Sanity) ]
                      |
      +-------+-------+-------+-------+
      |       |               |       |
      v       v               v       v
  [Grading] [Quizzes]     [Tutors] [Analytics]

```

[13]

Nothing downstream cares *how* a worker processes a task, only that it honors its specific API contract. A user authenticates via Clerk, triggers a feature in the Next.js frontend, and the underlying event fires down the Inngest bus. Inngest queries the Sanity registry to discover matching workers, launching independent downstream execution paths [13].

---

## A.3 The Five Architectural Layers

Every request and state transition passes through five isolated layers, each governed by strict separation of concerns [9][12]:

| Layer | Owns | Explicitly Does NOT Own | Examples / Real-World Role |
| --- | --- | --- | --- |
| **Client / Application** *(Next.js)* | UI rendering, client-side event emission, authentication checks | AI logic, workflow topologies, worker schemas | Renders dashboards, verifies active user sessions, and fires initial hooks. |
| **Data** *(Postgres)* | System of record, raw table storage, derived data aggregates | Determining workflow paths, orchestrating workers | Houses student profiles, submission states, and relational records. |
| **Orchestration** *(Inngest)* | Event bus topology, workflow execution state, retries, step chaining | Direct AI model execution, raw data storage | Listens for system hooks, safely handles step failures, and guarantees event delivery. |
| **Registry** *(Sanity)* | Worker capability discovery, runtime schema matching, version metadata | Application content management (despite being a CMS) [12] | Acts as a lookup table matching events (`assignment.submitted`) to valid worker endpoints. |
| **Execution** *(AI Workers)* | Core cognitive tasks (grading, quiz compilation, direct analysis) | Core LMS business rules, un-scoped database writes | **Markly (Grading)**, Quiz Generator, Tutor Assistant, Analytics Engine [12]. |

> ### ⚠️ Crucial Architectural Distinction
> 
> 
> The Registry layer (Sanity) is **not** a content management system for rich text, blog posts, or marketing material. It functions exclusively as a **runtime service discovery registry** for AI capabilities [12].

---

## A.4 The Multi-Tenant Isolation Principle

Layered across all five tiers is a non-negotiable data boundary cutting horizontally through the entire codebase:

> "Every piece of data belongs to an `organization_id`. No exceptions." [1]

Isolation is an unyielding constraint enforced at every stage of the lifecycle:

* **Application Layer:** Validates the user's active `organization_id` context before processing any incoming action.
* **Data Layer:** Assigns an explicit `organization_id` foreign key column to every single tenant-scoped table.
* **Orchestration Layer:** Re-verifies tenant scope within individual workflow steps; it never blindly trusts the initial payload event header.

**Example:** Consider the system's *Assessment Context*—the database rows housing assignments, rubrics, submissions, and feedback items where AI workers interact heavily [12]. Every submission row must carry a verified `organization_id`. If an AI grading worker is executing a job for *School A*, the isolation boundary ensures it is programmatically blocked from reading or writing data belonging to *School B*.

---

## A.5 Worker Execution Model (The Fan-Out Pattern)

The system is fundamentally "AI-native" rather than "AI-bolted-on" due to its asynchronous fan-out design: a single system event triggers multiple, isolated workers executing in parallel [2][5].

```text
                  [ assignment.submitted ]
                              |
      +-----------------------+-----------------------+
      |                       |                       |
      v                       v                       v
[ Markly ]            [ Plagiarism ]             [ Tutor AI ]
(Grading Engine)        (Detector)           (Feedback Assistant)

```

### The Registry Lookup Matrix

When an event fires, the Registry dynamically resolves the valid subscribers:

* **Triggering Event:** `assignment.submitted`
* **Registry Returns:** `Markly Grader`, `Plagiarism Checker`, `Tutor AI`, `Analytics Engine`, `Quiz Generator` [2][4].

Because execution is decoupled, workers are **completely independent** [5]. They share no internal memory, do not block one another, scale automatically, and fail gracefully without threatening the stability of surrounding routines [2]. If the `Quiz Generator` times out, `Markly` still posts its grade successfully.

---

## A.6 Fan-In (Result Aggregation)

Fan-out handles parallel compute; Fan-in is the structural counterpart that aggregates disparate, asynchronous worker inputs back into a single, cohesive application asset [2].

```text
  [ Markly Score: 87 ] 
  [ Tutor Feedback: "Improve recursion clarity" ]   ===>  [ Unified Learning Report ]
  [ Analytics: "Struggling with memory management" ] 

```

Rather than forcing the frontend to query individual tables for five disconnected tool updates, the orchestration layer intercepts completion tokens and flattens the records into a unified student record or teacher action item.

---

## A.7 Conditional & Adaptive Workflows

The platform shifts from a reactive structure (event $\rightarrow$ worker $\rightarrow$ stop) to an intelligent system when it leverages **conditional event chaining** [2]. Workers can emit secondary events directly into the bus, hiding complex adaptive routing logic from the frontend application [12].

```text
[ assignment.submitted ]
           │
           ▼
     [ Markly AI ] ────> Emits: `grading.completed` [12]
           │
           ▼
[ Performance Analysis ] ───> Checks condition: Is student struggling?
           │
     ┌─────┴─────┐
     ▼ (Yes)     ▼ (No)
[ Tutor Hook ]  [ Terminate Flow ]
     │
     ▼
[ Quiz Generation ]
     │
     ▼
[ Remediation Plan ]

```

> ### 💡 The Event-Contract Principle
> 
> 
> The frontend remains entirely decoupled from this sequence. As a core rule: **the client application only knows that "something happened," never "what happens next."** [7] The events themselves serve as the immutable contract between isolated architectural layers [7].

---

## A.8 Worker Evolution & Schema Versioning

Because workers are decoupled from the core application framework, they evolve independently without requiring simultaneous system-wide deployments [4].

```text
[ Markly v1 (GPT-4o) ] ───> [ Markly v2 (Claude 3.5 Sonnet) ] ───> [ Markly v3 (Custom Fine-Tune) ]

```

[4]

This independent evolution is guaranteed by the *contracts-over-implementations* rule [13]. As long as an updated version of `Markly` honors the strict JSON schema defining its input and output payloads, developers can swap the underlying model architectures without altering a single line of orchestration or UI code [8]. This pattern enables modular ecosystems like internal plug-in marketplaces and AI application stores [4].

---

## A.9 Native System Observability

Distributed tracing is treated as an architectural requirement rather than a secondary monitoring tool, operating under a strict engineering principle:

> "If you cannot trace it, you cannot trust it." [11]

Every transaction spans a single **trace tree** rooted at the original entry event [11]. Inngest workflows carry a consistent trace ID down the entire execution line, binding multi-hop conditional chains together into a single, visible context.

```text
[ assignment.submitted ] (Root Trace ID: #tx-88902)
├── Step 1: Execute Registry Lookup
└── Step 2: Fan-Out Workers
     ├── Worker A (Markly Execution) ──> Inherits: #tx-88902
     ├── Worker B (Plagiarism Check) ──> Inherits: #tx-88902
     └── Worker C (Tutor Generation) ──> Inherits: #tx-88902

```

---

## A.10 Production Topology Matrix

The complete physical infrastructure map routes telemetry and data through highly resilient cloud systems [9]:

```text
               [ Active End Users ]
                        │
                        ▼
             [ Next.js Web Frontend ]
                        │
                        ▼
      [ Supabase Infrastructure Layer ]
      (Bundled Authentication, DB, & RLS)
                        │
                        ▼
         [ Inngest Workflow Engine ]
                        │
                        ▼
       [ Sanity.io Worker Registry ]
                        │
                        ▼
      [ Distributed AI Worker Pools ]
                        │
                        ▼
     [ Supabase Storage & Results DB ]

```

[9]

### 🛠️ Architecture Customization Track: Neon + Clerk + Drizzle

If you are building the modular variant of the Greymatter LMS architecture (replacing the all-in-one Supabase stack with a decoupled, best-of-breed toolchain), use this direct mapping layout:

$$\text{Supabase (DB + Auth + RLS Bundle)} \longrightarrow \begin{cases} \textbf{Clerk} & \text{(Identity \& Auth Management)} \\ \textbf{Neon Postgres} & \text{(Relational Compute \& Storage)} \\ \textbf{Drizzle ORM} & \text{(Manual org\_id Isolation Queries)} \end{cases}$$

Every other system tier—including the Next.js frontend, the Inngest orchestration bus, the Sanity discovery registry, and the distributed worker nodes—remains completely unaffected. The workflow environment is powered exclusively by Inngest, meaning it has no hard dependencies on your choice of database engines [9].

---

## A.11 Architectural Evaluation Checklist

When designing new features or debugging complex bugs, trace your implementation through these five core structural validation gates:

1. **Layer Alignment (A.3):** Which specific layer does this piece of code live within? Does it mistakenly perform actions reserved for an adjacent layer (e.g., placing raw AI prompts directly inside a Next.js API route)?
2. **Tenant Security Check (A.4):** If this logic interacts with data storage, does it explicitly pass and validate an `organization_id`? Is the filter applied deep at the runtime execution level?
3. **Worker Autonomy (A.5–A.8):** If you are deploying an AI routine, can it fail completely without crashing the core user dashboard? Does it map to a strict JSON input/output contract managed by the registry?
4. **Trace Path Verification (A.6–A.9):** If debugging an adaptive learning loop, are you analyzing decoupled function logs in isolation, or are you tracking the unified Inngest trace ID from the originating root event?
5. **Topology Target (A.10):** Does your deployment target match the centralized Supabase architecture, or are you executing the decoupled alternative using Neon Postgres and manual query isolation checks?
