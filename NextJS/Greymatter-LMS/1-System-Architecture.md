# Part 1 — System Architecture: Mapping Out Greymatter LMS 

In Part 0, we built a tiny 10-line simulation of "one event, many workers" and saw why Greymatter LMS treats everything as an event rather than a hardcoded feature [13]. Now it's time to zoom out and design the **actual system architecture** — the real services, the real boundaries, and the real flow of data through Greymatter LMS [12].

**🎯 Goal of this lesson:** Understand every layer of the Greymatter stack, how they talk to each other, and walk through one real event end-to-end.

**🧰 Prereqs:** Part 0 completed. No new tools needed yet — this is a design lesson before we start scaffolding the repo in Part 2 [12].

---

## 1. The five layers, named

Greymatter LMS is built from five layers, each with one job and a strict rule about who it's allowed to talk to [12]:

* **Client + Application Layer** — Next.js 16 (React 19). Renders UI, runs Server Actions, and emits events. Never runs AI logic directly.
* **Auth** — Clerk. Handles authentication and org membership.
* **Data Layer** — Neon Postgres via Drizzle ORM. Stores courses, submissions, and worker results. Never decides *what* runs.
* **Orchestration Layer** — Inngest. The event bus and workflow engine. The only place that decides "this event happened, go run these workers."
* **Registry Layer** — Sanity. The only place that knows which workers exist and what events they listen to.
* **Execution Layer** — independently deployed AI Workers. The only place AI logic actually lives.

Each layer's restriction is as important as its job. The Application Layer never runs AI logic itself — that's what stops it from ever turning back into Part 0's tangled `onAssignmentSubmitted` function [13]. The Data Layer never decides what runs — it just remembers what happened. Only the Orchestration Layer is allowed to make the call "this event happened, go run these workers," and only the Registry Layer is allowed to say which workers exist. Keep this rule in mind — every later part in this series exists to make one arrow in this diagram real:

- Part 5 makes the Orchestration Layer's decision-making real, with Inngest [5]
- Part 6 makes the Registry Layer's "which workers exist" answer real, with Sanity [4]
- Part 7 makes the Execution Layer callable, with a signed Worker SDK [3]
- Part 9 makes sure none of these layers can be tricked into crossing their own boundary [1]

---

## 2. The full architecture diagram

Putting it all together, here's the production picture we're building toward across this entire series (compare this to Part 0's simplified `emit()` version):

```text
Users
↓
Next.js 16 (React 19) — Client + Application Layer
↓
Clerk — Auth & Org Membership
↓
Neon Postgres — Data Layer (via Drizzle ORM)
↓
Inngest — Orchestration Layer (event bus + workflow engine)
↓
Sanity — Registry Layer (worker discovery)
↓
AI Workers — Execution Layer (isolated, independently deployed)
↓
Neon Postgres — Results written back
↓
Next.js 16 — Reads results, renders to student
```

Notice the diagram isn't a straight line — it loops back. Data flows down through five layers to trigger AI work, then flows back *up* through the Data Layer so the same Next.js app that emitted the event can render its outcome. This round-trip is exactly what we'll trace as one concrete example in section 3 below.

**✅ Checkpoint:** Before moving on, redraw this diagram yourself from memory on paper or in a notes app, labeling each arrow with the technology that implements it. If you can't remember what sits between "Orchestration" and "Execution," re-read section 1 before continuing — this diagram is the map every later part builds one piece of.

---

## 3. Tracing one event end-to-end

To make this diagram concrete rather than abstract, walk through what happens the moment a student clicks "Submit" on an assignment — the exact scenario Part 0's `assignment.submitted` demo was modeling [13]:

1. **Application Layer:** The student's browser calls a Next.js Server Action, `submitAssignment`. Clerk has already confirmed who this student is and which organization they belong to.
2. **Data Layer:** The Server Action writes the submission to Neon Postgres via Drizzle, then emits an event — `assignment.submitted` — into Inngest. It does **not** call a grader directly.
3. **Orchestration Layer:** Inngest receives the event and runs a durable, multi-step function: fetch context, discover workers, execute workers, persist results.
4. **Registry Layer:** As part of "discover workers," Inngest asks Sanity: "which workers are enabled and subscribed to `assignment.submitted`?" Sanity answers with a list — maybe just a Grading Worker today, a Quiz Worker and Tutor Worker added later with zero changes to this step.
5. **Execution Layer:** Inngest calls each worker returned by the registry, in parallel if there's more than one, and waits for their results.
6. **Data Layer again:** Inngest writes each worker's output back to Neon Postgres.
7. **Application Layer again:** The next time the student's dashboard renders, it reads that result from Neon Postgres and displays it — a grade, a generated quiz, tutor feedback.

Notice what never happens anywhere in this trace: the Application Layer never imports grading logic, and the Orchestration Layer never hardcodes which workers exist. That separation is the entire reason Parts 5 through 11 can add new AI capabilities — a Quiz Worker, a Tutor Worker, a Summary Worker — without ever reopening this flow [10].

---

## 4. Why this maps directly onto later parts

This isn't just a diagram for its own sake — every layer named here becomes a specific, buildable part of the series:

| Layer | Built in | What it becomes |
|---|---|---|
| Client + Application | Part 3 | Route groups, Clerk-authenticated dashboard, Server Actions [7] |
| Data | Part 4 | Full Drizzle schema — courses, enrollments, submissions, worker results [6] |
| Orchestration | Part 5, deepened in Part 8 | Real Inngest functions, then fan-out/fan-in and chained events [5][2] |
| Registry | Part 6 | A live, queryable Sanity worker registry [4] |
| Execution | Part 7, hardened in Part 9 | A signed Worker SDK and a formal registration flow [3][1] |

Part 12 later confirms this same diagram holds all the way to production — it's "the exact same diagram from Part 1, just with a real hosting provider written next to each layer instead of a technology name alone" [9].

---

## 5. What's next

We now understand every layer of the Greymatter stack, the one rule governing how they talk to each other, and what a single event's round trip looks like end-to-end. In Part 2, we turn this architecture into an actual folder structure — a monorepo — so these boundaries are enforced by the codebase itself, not just good intentions [8].

**🩹 Common confusion at this stage:** "If the Orchestration Layer and Registry Layer are separate, why can't Inngest just keep its own list of workers instead of asking Sanity every time?" — Because that would silently move a Registry Layer responsibility into the Orchestration Layer, recreating exactly the kind of hidden coupling this architecture is designed to prevent. Keeping them separate is what lets Part 6 add, disable, or swap a worker as a pure content edit in Sanity Studio, with zero code changes to Inngest [4].

Ready? → **Part 2: Repository & Project Foundation — Scaffolding the Greymatter LMS Monorepo**
