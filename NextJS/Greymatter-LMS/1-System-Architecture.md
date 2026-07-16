# Part 1 — System Architecture: Mapping Out Greymatter LMS

In Part 0, we built a tiny 10-line simulation of "one event, many workers" and saw why Greymatter LMS treats everything as an event rather than a hardcoded feature [13]. Now it's time to zoom out and design the **actual system architecture** — the real services, the real boundaries, and the real flow of data through Greymatter LMS [12].

**🎯 Goal of this lesson:** Understand every layer of the Greymatter stack, how they talk to each other, and walk through one real event end-to-end.

**🧰 Prereqs:** Part 0 completed. No new tools needed yet — this is a design lesson before we start scaffolding the repo in Part 2 [12].

---

## 1. The five layers, named

Greymatter LMS is built from five layers, each with one job and a strict rule about who it's allowed to talk to:

* **Client + Application Layer** — Next.js 16 (React 19). Renders UI, runs Server Actions, and emits events. Never runs AI logic directly.
* **Auth** — Clerk. Handles authentication and org membership.
* **Data Layer** — Neon Postgres via Drizzle ORM. Stores courses, submissions, and worker results. Never decides *what* runs.
* **Orchestration Layer** — Inngest. The event bus and workflow engine. The only place that decides "this event happened, go run these workers."
* **Registry Layer** — Sanity. The only place that knows which workers exist and what events they listen to.
* **Execution Layer** — independently deployed AI Workers. The only place AI logic actually lives.

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

**✅ Checkpoint:** Before moving on, redraw this diagram yourself from memory on paper or in a notes app, labeling each arrow with the technology that implements it. If you can't remember what sits between "Orchestration" and "Execution," re-read section 1 before continuing — this diagram is the map every later part builds one piece of.

---

## 3. The one rule that matters most

Every arrow in the diagram above is a **contract, not a shortcut**. A component in the Application Layer only ever talks to the layer directly below it — it never reaches "down" two layers. For example, a React component never queries Neon directly; it always goes through a Server Action [12].

This is also why the frontend rule in the original series is stated so bluntly: **no AI logic in the frontend** [7]. We'll enforce this literally with folder structure and lint rules in Part 3 [12].

**🩹 Common confusion at this stage:** "Why can't a Server Action just call the AI model directly and skip Inngest entirely — wouldn't that be faster?" — It would be *faster to write*, but it would also mean the Application Layer now owns retry logic, worker discovery, and failure handling itself, which is exactly the "feature landfill" problem from Part 0 [13]. Keeping AI execution behind the Orchestration and Registry layers is what lets Part 6 disable a worker with zero code changes, and Part 11 add real AI workers with zero core changes [10].

---

## 4. Walking one event end-to-end

Let's trace a single student submission through every layer, step by step, so the diagram above stops being abstract:

**Step 1 — Client Layer.** A student clicks "Submit" on an assignment form rendered by Next.js.

**Step 2 — Application Layer.** A Server Action receives the form data. It does *not* grade the assignment — it only validates input and checks auth.

**Step 3 — Auth Layer.** Clerk's `auth()` confirms the student is signed in and returns their `userId` and `orgId`.

**Step 4 — Data Layer.** The Server Action writes a new row into the `submissions` table in Neon Postgres via Drizzle.

**Step 5 — Orchestration Layer.** The Server Action emits one event — `assignment.submitted` — to Inngest. This is the *only* event the frontend ever needs to emit; everything downstream is the Orchestration Layer talking to itself [5].

**Step 6 — Registry Layer.** Inngest queries Sanity: "which workers listen to `assignment.submitted`, and are they enabled?"

**Step 7 — Execution Layer.** Inngest calls each matching worker's endpoint (grading, quiz generation, tutoring, analytics) — independently, in parallel.

**Step 8 — Data Layer, again.** Each worker's result is written back into Neon Postgres, into a shared `worker_results` table.

**Step 9 — Client Layer, again.** The student's dashboard reads updated results from Neon Postgres and renders them.

**✅ Checkpoint:** Without looking back at the steps above, try to answer: which layer decides *which* workers run for a given event? (Answer: the Registry Layer, Sanity — not the frontend, and not Inngest itself, which only *queries* the registry.) If you got this wrong, re-read Steps 5–6 before moving on — this distinction is exactly what Part 6 builds [4].

---

## 5. What we've designed, and what we haven't built yet

At this point we have *zero* running code — this part is entirely a design lesson [12]. But we now have a precise answer to a question every later part will implicitly assume you already know:

| Question | Answer | Built in |
|---|---|---|
| Where does auth happen? | Clerk, checked in every Server Action | Part 3 |
| Where does data live? | Neon Postgres, via Drizzle | Part 4 |
| What decides an event happened? | Inngest | Part 5 |
| What decides which workers run? | Sanity registry | Part 6 |
| Where does AI logic actually execute? | Independent worker endpoints | Part 7 |
| What secures worker calls? | HMAC request signing | Part 7, hardened in Part 9 |

---

## 6. What's next

We now understand every layer of the Greymatter stack, the one rule that governs how they talk to each other, and what a single event's journey looks like end-to-end. In Part 2, we turn this architecture into an actual folder structure — a monorepo — so these boundaries are enforced by the codebase itself, not just good intentions [8].

Ready? → **Part 2: Repository & Project Foundation — Scaffolding the Greymatter LMS Monorepo**
