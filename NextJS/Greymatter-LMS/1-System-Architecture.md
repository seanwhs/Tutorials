# Part 1 — System Architecture: Mapping Out Greymatter LMS

In Part 0, we built a tiny 10-line simulation of "one event, many workers" and saw why Greymatter LMS treats everything as an event rather than a hardcoded feature. Now it's time to zoom out and design the **actual system architecture** — the real services, the real boundaries, and the real flow of data through Greymatter LMS [12].

**🎯 Goal of this lesson:** Understand every layer of the Greymatter stack, how they talk to each other, and walk through one real event end-to-end.

**🧰 Prereqs:** Part 0 completed. No new tools needed yet — this is a design lesson before we start scaffolding the repo in Part 2.

---

## 1. The five layers of Greymatter LMS

Every request in Greymatter passes through five distinct layers. Each layer has **one job** and is not allowed to do the others' jobs — this separation is the whole reason the architecture stays maintainable as AI features grow [12].

```text
Client Layer        → Browser / mobile UI (untrusted input)
Application Layer    → Next.js 16 (React 19 Server Actions, routing, auth checks)
Data Layer           → Neon Postgres (source of truth)
Orchestration Layer   → Inngest (event bus + workflow engine)
Registry Layer        → Sanity (worker discovery)
Execution Layer       → AI Workers (isolated, replaceable)
```

Compare this to our original demo from Part 0 — the `emit()` function is now split into two real services: **Inngest** (the event bus) and **Sanity** (the worker registry that tells Inngest *which* workers exist).

---

## 2. Why not Supabase? Mapping the Data Layer to Neon

The original architecture notes use Supabase for the Data Layer, with Row-Level Security enforcing tenant isolation directly in the database [12]. Greymatter LMS uses **Neon Postgres** instead, which means we take on two responsibilities that Supabase used to hand us for free:

| Responsibility | Supabase (original) | Greymatter (Neon) |
|---|---|---|
| Database hosting | Supabase Postgres | Neon Postgres (serverless, branchable) |
| Auth | Supabase Auth | Clerk |
| Tenant isolation | Row-Level Security (RLS) policies | Enforced in application code via Drizzle ORM queries, checked against the Clerk `orgId` |
| Client SDK | `@supabase/supabase-js` | Drizzle ORM + plain SQL via `pg` |

We'll build this properly in Part 4, but keep this table in mind — every time a future lesson mentions "Supabase enforces X," in Greymatter LMS that job moves to **our server code**, not the database itself.

---

## 3. Walking through one real event

Let's trace what the original architecture calls a "real scenario" [12] but rebuilt for Greymatter LMS's stack. Say a student submits an assignment.

```text
1. Student clicks "Submit Assignment" in the Next.js 16 UI
2. Client Layer sends a Server Action call (not a raw API call) — untrusted input
3. Application Layer validates the request:
     - Is the user authenticated? (Clerk)
     - Does this student belong to this course's org? (Drizzle query against Neon)
4. Application Layer writes the submission row to Neon Postgres (Data Layer)
5. Application Layer emits an event: "assignment.submitted" (Orchestration Layer / Inngest)
6. Inngest asks the Registry Layer (Sanity): "Which workers care about assignment.submitted?"
7. Registry returns: [GradingWorker, QuizWorker, TutorAIWorker, AnalyticsWorker]
8. Inngest invokes each worker independently (Execution Layer)
9. Each worker writes its own result back to Neon Postgres
10. Next.js UI reads updated results and displays them to the student
```

Notice step 3 and step 4 — this is where Greymatter differs most from the Supabase-based version. Because we don't have RLS, **the Application Layer itself must check "does this student belong to this org?"** before writing anything. We'll write this exact check in Part 9 (Hardening), but it's worth previewing now:

```typescript
// app/actions/submitAssignment.ts
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { submissions, enrollments } from "@/lib/db/schema";
import { and, eq } from "drizzle-orm";
import { inngest } from "@/infra/inngest/client";

export async function submitAssignment(courseId: string, assignmentId: string, content: string) {
  const { userId, orgId } = await auth();
  if (!userId || !orgId) throw new Error("Unauthorized");

  // Because we don't have Supabase RLS, we check tenant boundaries ourselves
  const enrollment = await db.query.enrollments.findFirst({
    where: and(eq(enrollments.userId, userId), eq(enrollments.courseId, courseId)),
  });
  if (!enrollment) throw new Error("Not enrolled in this course");

  const [submission] = await db
    .insert(submissions)
    .values({ courseId, assignmentId, userId, content, orgId })
    .returning();

  await inngest.send({
    name: "assignment.submitted",
    data: { submissionId: submission.id, studentId: userId, orgId },
  });

  return submission;
}
```

**✅ Checkpoint (conceptual, not runnable yet):** Read through the function above and identify the five layers: Client (the form that calls this), Application (this Server Action), Data (the `db.insert` call), Orchestration (`inngest.send`), and Execution (whatever workers pick up `assignment.submitted` later). We'll make this fully runnable once Neon and Inngest are wired up in Parts 4–5.

---

## 4. Service boundaries — what each layer is *not* allowed to do

This is the most important rule in the whole series, and it's stated as a hard architectural principle in the original notes: **the LMS does not execute intelligence, it orchestrates intelligence execution** [5]. In Greymatter terms:

* ❌ Next.js **never** calls an AI model directly from a component or API route.
* ❌ Server Actions **never** contain grading logic, quiz-generation logic, or tutoring logic.
* ❌ Neon Postgres **never** decides which workers run — it just stores data.
* ✅ Inngest is the **only** place that decides "this event happened, go run these workers."
* ✅ Sanity is the **only** place that knows "these workers exist and listen to these events."
* ✅ Workers are the **only** place AI logic lives, and they can be written in any language, deployed anywhere, and swapped out without touching Next.js at all.

This is also why the frontend rule in the original series is stated so bluntly: **no AI logic in the frontend** [7]. We'll enforce this literally with folder structure and lint rules in Part 3.

---

## 5. The full architecture diagram for Greymatter LMS

Putting it all together, here's the production picture we're building toward (compare to Part 0's simplified version):

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

Every arrow in this diagram is a **contract**, not a shortcut. A component in the Application Layer only ever talks to the layer directly below it — it never reaches "down" two layers (e.g., a React component never queries Neon directly; it always goes through a Server Action).

---

## 6. Why this design pays off (and when it doesn't)

Borrowing the reasoning from the original architecture: because every layer is independent, AI systems can fail, scale, or be replaced without touching the rest of the system [8]. New AI feature = new worker, no core changes required [5].

The honest trade-off for beginners: **this is more setup than a simple CRUD app needs.** If Greymatter LMS only ever needed one feature (say, just grading), a monolith would be simpler. This architecture earns its complexity the moment you have 3+ independent AI capabilities reacting to the same events — exactly the scenario we simulated in Part 0.

---

## 7. What's next

We now have the full picture: five layers, one event bus in the middle, strict boundaries between them. In Part 2, we translate this architecture into an actual folder structure — a monorepo where the UI, the database schema, the event contracts, and the worker SDK all live in clearly separated packages, so the boundaries we just described are enforced by the codebase itself, not just convention [8].

**🩹 Common confusion at this stage:** "Isn't Inngest + Sanity overkill for a small app?" — Yes, for a toy app. But Greymatter LMS is designed as a teaching example for *scalable* AI-native systems, so we accept the extra layers now to see the payoff in Parts 8 and 11 when we add multiple AI workers with zero changes to existing code.

Ready? → **Part 2: Repository & Project Foundation for Greymatter LMS**
