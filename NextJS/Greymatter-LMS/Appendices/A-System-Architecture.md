# Appendix A — System Architecture Reference

## A.1 The Foundational Principle

A Server Action should never call an AI model directly and skip Inngest — doing so would mean the Application Layer owns retry logic, worker discovery, and failure handling itself, recreating the "feature landfill" problem the series opens with [13]. Keeping AI execution behind the Orchestration and Registry layers is what lets a worker be disabled with zero code changes, and lets new AI workers be added later with zero core changes [12].

This traces back to a 10-line `emit()` simulation in Part 0:

```javascript
// One action, three independent reactions
emit("assignment.submitted", { submissionId: "sub_123", studentId: "stu_456" });
```

One `emit()` call fires three independent reactions — grading, tutor feedback, analytics — none of which know about each other, and a fourth could be added or removed without touching the others [13]. Everything built from Part 5 onward with Inngest is a durable, production-grade version of that same function [13].

```mermaid
flowchart LR
    E["emit('assignment.submitted', ...)"] --> W1["📝 Grading"]
    E --> W2["🧠 Tutor Feedback"]
    E --> W3["📊 Analytics"]
    style E fill:#4a4a4a,color:#fff
    style W1 fill:#2d6a4f,color:#fff
    style W2 fill:#2d6a4f,color:#fff
    style W3 fill:#2d6a4f,color:#fff
```

The common confusion at this stage is worth stating directly: this demo is trivial, so why does the real system need Inngest, Sanity, HMAC signing, and observability at all? Because a toy `emit()` function doesn't survive contact with production — it can't retry a failed worker, can't discover new workers without a code change, can't verify a request wasn't forged, and can't tell you *why* something failed [13]. Parts 5 through 10 exist to turn this simple idea into something durable enough to actually run, with real AI workers added in Part 11 with zero changes to the core [13].

---

## A.2 The Five Architectural Layers

Greymatter LMS is built from five layers, each with one job and a strict rule about who it's allowed to talk to [12]:

* **Client + Application Layer** — Next.js 16 (React 19). Renders UI, runs Server Actions, and emits events. Never runs AI logic directly [12].
* **Auth** — Clerk. Handles authentication and org membership [12].
* **Data Layer** — Neon Postgres via Drizzle ORM. Stores courses, submissions, and worker results. Never decides *what* runs [12].
* **Orchestration Layer** — Inngest. The event bus and workflow engine. The only place that decides "this event happened, go run these workers" [12].
* **Registry Layer** — Sanity. The only place that knows which workers exist and what events they listen to [12].
* **Execution Layer** — independently deployed AI Workers. The only place AI logic actually lives [12].

Tracing one event end-to-end: Inngest queries Sanity to discover which workers listen to `assignment.submitted` and are enabled (Registry Layer), then calls each matching worker's endpoint independently and in parallel (Execution Layer), each worker's result is written back into Neon Postgres in a shared `worker_results` table (Data Layer), and the student's dashboard reads those updated results and renders them (Client Layer) [12].

```mermaid
sequenceDiagram
    participant S as Student (Client Layer)
    participant N as Next.js App
    participant C as Clerk (Auth)
    participant D as Neon Postgres (Data)
    participant I as Inngest (Orchestration)
    participant R as Sanity (Registry)
    participant W as AI Workers (Execution)

    S->>N: Submit assignment
    N->>C: Confirm identity + org
    N->>D: Write submission row
    N->>I: emit "assignment.submitted"
    I->>R: Which workers listen to this event, and are they enabled?
    R-->>I: [Grading Worker, Quiz Worker]
    par Parallel execution
        I->>W: Call Grading Worker endpoint
        I->>W: Call Quiz Worker endpoint
    end
    W-->>D: Write results to worker_results
    D-->>N: Dashboard reads updated results
    N-->>S: Render score, feedback, quiz
```

The Registry Layer — not the frontend, and not Inngest itself — decides which workers run for a given event; Inngest only queries the registry [12]. A useful self-check: without looking back at the steps above, try to answer which layer decides *which* workers run for a given event. The answer is the Registry Layer, Sanity — this distinction is exactly what Part 6 builds [4][12].

```mermaid
flowchart TD
    A[Client + Application<br/>Next.js 16] -->|emits events only| B[Orchestration<br/>Inngest]
    B -->|queries| C[Registry<br/>Sanity]
    C -->|returns enabled workers| B
    B -->|calls in parallel| D[Execution<br/>AI Workers]
    D -->|writes results| E[Data<br/>Neon Postgres]
    E -->|reads results| A
    F[Auth<br/>Clerk] -.->|confirms identity| A
    style A fill:#1d3557,color:#fff
    style B fill:#457b9d,color:#fff
    style C fill:#e63946,color:#fff
    style D fill:#2a9d8f,color:#fff
    style E fill:#f4a261,color:#000
    style F fill:#6c757d,color:#fff
```

**🩹 Common confusion:** "Why can't a Server Action just call the AI model directly and skip Inngest entirely — wouldn't that be faster?" It would be faster to write, but it would also mean the Application Layer now owns retry logic, worker discovery, and failure handling itself — exactly the "feature landfill" problem from Part 0 [13]. Keeping AI execution behind the Orchestration and Registry layers is what lets Part 6 disable a worker with zero code changes, and Part 11 add real AI workers with zero core changes [10][12].

---

## A.3 Monorepo Structure

Boundaries are enforced by folders, not just convention: `apps/web`, `packages/*`, and `infra/*` [8]. Turborepo wires scripts to run across every package at once via a root `turbo.json` and matching `dev`/`build` scripts [8].

Mapping the folder structure onto the five layers makes clear why each package exists [8][12]:

| Folder | Layer it serves | Why it's separate |
|---|---|---|
| `apps/web` | Client + Application | The only place UI renders and Server Actions run [8] |
| `packages/events` | Orchestration (contract) | Shared event shape — imported by both the frontend and Inngest functions later, so neither one "owns" it [8] |
| `packages/types` | Cross-cutting | Shared TypeScript types used across the app and workers [8] |
| `packages/sdk` | Application | A client SDK for interacting with Greymatter LMS [8] |
| `packages/workers` | Execution (contract) | The `WorkerInput`/`WorkerOutput` shape and signing helpers every worker implements, starting in Part 7 [8] |
| `packages/registry` | Registry | The client used to query the Sanity worker registry, starting in Part 6 [8] |
| `infra/db` | Data | Drizzle schema, shared by both the app and any Inngest functions that persist worker results [8] |
| `infra/inngest` | Orchestration | The actual event functions/workflows, built starting in Part 5 [8] |
| `infra/sanity` | Registry | Worker registry schemas, built starting in Part 6 [8] |

```mermaid
graph TD
    Root["greymatter-lms/"] --> Apps["apps/"]
    Root --> Packages["packages/"]
    Root --> Infra["infra/"]

    Apps --> Web["web/ — Client + Application Layer"]

    Packages --> PEvents["events/ — Orchestration contract"]
    Packages --> PTypes["types/ — Cross-cutting"]
    Packages --> PSdk["sdk/ — Application client"]
    Packages --> PWorkers["workers/ — Execution contract"]
    Packages --> PRegistry["registry/ — Registry client"]

    Infra --> IDb["db/ — Data schema (Drizzle)"]
    Infra --> IInngest["inngest/ — Orchestration functions"]
    Infra --> ISanity["sanity/ — Registry schemas"]

    style Web fill:#1d3557,color:#fff
    style PEvents fill:#457b9d,color:#fff
    style IInngest fill:#457b9d,color:#fff
    style PRegistry fill:#e63946,color:#fff
    style ISanity fill:#e63946,color:#fff
    style PWorkers fill:#2a9d8f,color:#fff
    style IDb fill:#f4a261,color:#000
```

**🩹 Common confusion:** "Why is `infra/db` separate from `apps/web` if the app is the only thing querying the database right now?" Because starting in Part 5, Inngest workers will *also* need to read/write to Neon Postgres to persist worker results. Keeping schema definitions in their own package means both the Application Layer and the Orchestration Layer share one source of truth, instead of each maintaining its own copy that can drift out of sync [8].

---

## A.4 Multi-Tenant Isolation (`orgId`) — completing the Threat Model Summary

| Threat | Where it enters | Greymatter LMS defense |
|---|---|---|
| Spoofed events hitting `/api/inngest` directly | Orchestration Layer | Inngest's signing key + our own event-origin checks [1] |
| Forged worker responses | Execution Layer | HMAC request signing, built in Part 7 [1] |
| Cross-tenant data leakage | Data Layer | Manual `orgId` checks in every query (Part 4), now reinforced inside Inngest steps [1] |
| Disabled/malicious worker still executing | Registry Layer | `enabled` flag check in the registry query (Part 6) [1] |
| Unauthorized Server Action calls | Application Layer | `auth()` re-check inside every Server Action (Part 3) [1] |

Notice this table maps directly onto the flowchart above it — each of the three rejection branches (`Reject1`, `Reject2`, `Reject3`) corresponds to one of these five named threats, closing the loop between the diagram and the actual defense-by-defense breakdown [1].

---

## A.5 Fan-Out — Multiple Workers, One Event

We now have two workers registered in Sanity — the Grading Worker and the Quiz Worker — and Part 7's real signed-execution pattern already handles calling more than one [2][3]. Fan-out simply means: when `assignment.submitted` fires, every matching worker runs at the same time, not one after another [2].

```mermaid
flowchart LR
    Event["assignment.submitted"] --> Grading["Grading Worker<br/>Score: 87"]
    Event --> Quiz["Quiz Worker<br/>Generated"]
    Grading --> Report["Unified Learning Report"]
    Quiz --> Report
    style Event fill:#457b9d,color:#fff
    style Grading fill:#2a9d8f,color:#fff
    style Quiz fill:#2a9d8f,color:#fff
    style Report fill:#e63946,color:#fff
```

The `execute-workers` step from Part 7 already does this implicitly via `Promise.all` [2][3] — this part just makes the aggregation explicit and visible, matching the unified-report pattern from the original design [2].

---

## A.6 Conditional Branching — The Struggling-Student Path

Real adaptive behavior requires branching: if a student's grade is low, something different should happen than if it's high [2]. Critically, this decision lives in Inngest (Orchestration), never in the frontend or in a worker — respecting the exact boundary set back in Part 1 [2][12].

```mermaid
flowchart TD
    Agg["aggregate-results step"] --> Check{"report.score < 70?"}
    Check -->|Yes| Emit["emit 'student.struggling'"]
    Check -->|No| End["Flow ends normally"]
    Emit --> Chain["student-struggling function<br/>picks up event"]
    Chain --> Tutor["tutor.intervention"]
    Tutor --> Practice["practice.assigned"]
    style Check fill:#f4a261,color:#000
    style Emit fill:#e63946,color:#fff
    style Chain fill:#457b9d,color:#fff
```

This is what creates the adaptive learning loop referenced throughout Part 8: `assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned` [2].

**🩹 Common confusion:** "If anyone can call `inngest.send({ name: 'student.struggling', ... })` from anywhere, what stops a fake event from triggering a real tutor intervention?" — Nothing, at this stage, and that's intentional so the chaining mechanism itself stays simple to learn first. Part 9 closes this gap directly by restricting which internal events can be sent from where, as part of its full threat model [2].

---

## A.7 Worker Registration — The Six-Step Flow

Adding a new AI capability should never require touching `apps/web` or `infra/inngest`. This is the exact repeatable sequence every future worker — Quiz Worker, Tutor Worker, Summary Worker in Part 11 — follows [3]:

```mermaid
flowchart LR
    S1["1. Build worker<br/>(WorkerInput/WorkerOutput)"] --> S2["2. Deploy it<br/>somewhere reachable"]
    S2 --> S3["3. Generate/reuse<br/>WORKER_SIGNING_SECRET"]
    S3 --> S4["4. Create Sanity document<br/>name, events, endpoint, enabled"]
    S4 --> S5["5. Publish in<br/>Sanity Studio"]
    S5 --> S6["6. Auto-discovery via<br/>findWorkers() — zero code changes"]
    style S6 fill:#2d6a4f,color:#fff
```

This six-step flow is what Part 6 proves concretely: toggling `enabled` to `false` on the Grading Worker's Sanity document, publishing with no code touched, and confirming `discover-workers` returns an empty array — then flipping it back and confirming the worker is discovered again [4][3].

---

## A.8 HMAC Signing — Request and Response Verification

Every worker call is signed on the way out and verified on the way back, using an `x-signature` header on both the request and response [3]:

```mermaid
sequenceDiagram
    participant I as Inngest (execute-workers)
    participant W as Worker (e.g. Grading Worker)
    I->>I: signPayload(input, SECRET)
    I->>W: POST with x-signature header
    W->>W: verifySignature(input, signature, SECRET)
    W-->>I: response + x-signature header
    I->>I: verifySignature(output, outSignature, SECRET)
    alt Invalid signature
        I->>I: throw "Worker returned an invalid signature"
    else Valid
        I->>I: Persist result to worker_results
    end
```

**✅ Checkpoint:** With the Grading Worker running (`localhost:4000`) and its Sanity registry document still pointing at that URL, resubmit an assignment through the dashboard. In the Inngest dashboard, confirm `execute-workers` shows a real score in its output — not the placeholder `{}` from Part 5 — and confirm `persist-results` writes that score into `worker_results` in Neon [3].

---

## A.9 Observability — Trace IDs Across the Whole Chain

Since Part 8 introduced fan-out execution and multi-step event chains, a single student action can silently touch five or six independent systems [11]. The core mechanism introduced to fix this is a trace ID: one identifier generated at the start of a request, threaded through every downstream event, worker call, and log line — even across function boundaries [11].

```mermaid
flowchart LR
    Submit["Server Action<br/>generates traceId"] --> Event1["assignment.submitted<br/>traceId: abc-123"]
    Event1 --> Chain["student.struggling<br/>traceId: abc-123 (propagated)"]
    Chain --> Log["Both runs share<br/>the same traceId in dashboard"]
    style Submit fill:#457b9d,color:#fff
    style Log fill:#2d6a4f,color:#fff
```

**✅ Checkpoint:** Force a low score (as in Part 8's conditional-branch checkpoint) and resubmit. In the Inngest dashboard, open both the `assignment-submitted` and `student-struggling` runs, and confirm the exact same `traceId` value appears in each run's event payload — proving they're now provably linked, not just adjacent in time [11].

---

## A.10 Production Deployment — The Full End-to-End Trace

With every layer deployed, the original nine-step request lifecycle from Part 1 runs one final time, on real infrastructure [9][12]:

```mermaid
flowchart TD
    S1["1. Student submits on live Vercel URL"] --> S2["2. Clerk (production) confirms identity + org"]
    S2 --> S3["3. Application Layer checks course ownership"]
    S3 --> S4["4. Submission written to Neon production branch"]
    S4 --> S5["5. assignment.submitted sent to Inngest Cloud"]
    S5 --> S6["6. Inngest Cloud queries deployed Sanity Studio"]
    S6 --> S7["7. Each deployed worker called over HTTPS, HMAC-signed"]
    S7 --> S8["8. Results written back to worker_results in Neon"]
    S8 --> S9["9. Dashboard reloads: real score, feedback, quiz"]
    style S9 fill:#2d6a4f,color:#fff
```

---

## Series Complete

Starting from a 10-line `emit()` simulation in Part 0 [13], the series builds, in order: a five-layer architecture [12], a boundary-enforcing monorepo [8], a Clerk-authenticated Next.js frontend [7], a full Neon/Drizzle schema [6], a real Inngest orchestration pipeline [5], a live Sanity worker registry [4], a signed Worker SDK [3], fan-out/fan-in/event chaining [2], a hardened threat model [1], a full observability pipeline [11], real AI-native features [10], and a complete production deployment [9] — proving the philosophy the series opened with: **events, not features** [13].
