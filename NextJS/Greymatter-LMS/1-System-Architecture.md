# Part 1 — System Architecture: Mapping Out Greymatter LMS

Following directly from Part 0, where we proved the "events, not features" philosophy with a tiny `emit()` simulation [13], this part translates that philosophy into real system architecture: diagrams, service boundaries, event pipeline design, worker lifecycle, and data flow between the frontend, database, event engine, and registry [13].

**🎯 Goal of this lesson:** Understand the five-layer architecture of Greymatter LMS, see the full request lifecycle from browser to AI worker and back, and learn the hard boundary rules that every later part must respect.

**🧰 Prereqs:** Part 0 completed. Nothing to install yet — this part is conceptual, with one non-runnable code walkthrough.

---

## 1. The five layers

Greymatter LMS is built from five distinct layers, each mapped to a real technology:

* **Client + Application** — Next.js 16 (React 19), Tailwind
* **Auth** — Clerk
* **Data** — Neon Postgres + Drizzle ORM
* **Orchestration** — Inngest
* **Registry** — Sanity
* **Execution** — independently deployed AI Workers

Each layer only talks to the one directly adjacent to it — no layer reaches past its neighbor.

---

## 2. Tracing a full request end-to-end

Following the sequence from the architecture notes, a single assignment submission flows through these steps [12]:

1. Student submits an assignment in the Next.js UI
2. A Server Action runs, checking auth via Clerk
3. The Application Layer verifies the student belongs to the org (since Greymatter has no built-in RLS like Supabase) [12]
4. The submission is written to Neon Postgres
5. The Server Action emits an `assignment.submitted` event to Inngest
6. Inngest fetches the submission and discovers which workers should run
7. Workers execute (grading, quiz generation, tutoring, analytics)
8. Each worker writes its own result back to Neon Postgres [12]
9. The Next.js UI reads updated results and displays them to the student

A non-runnable code sketch demonstrates the five layers concretely:

```typescript
// app/actions/submitAssignment.ts
"use server";
```

**✅ Checkpoint (conceptual, not runnable yet):** Read through the function above and identify the five layers: Client (the form that calls this), Application (this Server Action), Data (the `db.insert` call), Orchestration (`inngest.send`), and Execution (whatever workers pick up `assignment.submitted` later). We'll make this fully runnable once Neon and Inngest are wired up in Parts 4–5 [12].

---

## 3. The RLS gap — Greymatter's biggest architectural difference

Because Greymatter uses Neon Postgres instead of Supabase, it doesn't get row-level security for free. Step 3 above — "does this student belong to this org?" — has to be checked explicitly in application code, every time [12]. This is previewed now but implemented properly in Part 9 (Hardening) [12].

---

## 4. Service boundaries — what each layer is *not* allowed to do

This is the most important rule in the whole series, stated as a hard architectural principle: **the LMS does not execute intelligence, it orchestrates intelligence execution** [12]. In Greymatter terms:

* ❌ Next.js **never** calls an AI model directly from a component or API route.
* ❌ Server Actions **never** contain grading logic, quiz-generation logic, or tutoring logic.
* ❌ Neon Postgres **never** decides which workers run — it just stores data.
* ✅ Inngest is the **only** place that decides "this event happened, go run these workers."
* ✅ Sanity is the **only** place that knows "these workers exist and listen to these events."
* ✅ Workers are the **only** place AI logic lives, and they can be written in any language, deployed anywhere, and swapped out without touching Next.js at all [12].

These rules are what make the Part 5 promise possible: "new AI feature = new worker, no core changes" [12] — a promise the series proves concretely in Part 6 (toggling a worker off/on with zero code changes) [4] and again in Part 11 (adding real AI workers with zero core changes) [10].

---

## 5. What's next

We now understand the philosophy and the architecture on paper. In Part 2, we move from diagrams to a real, physical monorepo — scaffolding `apps/web`, `packages/*`, and `infra/*` with the exact boundaries described above, and proving the boundary system works with a first shared event contract package [8].

**🩹 Common confusion at this stage:** "If none of this is runnable yet, why not skip straight to code?" — Because every later part assumes you understand *why* a Server Action can't just call an AI model directly, or why Sanity isn't "just a CMS." Skipping this leads to reasonable-sounding but wrong shortcuts later (e.g., putting grading logic inside a Server Action), which Part 9's threat model exists specifically to catch [1].

Ready? → **Part 2: Monorepo Setup for Greymatter LMS**
