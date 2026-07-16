# Part 0 — Introduction: The Philosophy Behind Greymatter LMS 

Welcome to the first lesson in the **Greymatter LMS** tutorial series — a step-by-step build of a real, production-shaped, AI-native Learning Management System. Before we write a single line of production code, we need to understand *why* Greymatter is built the way it is — otherwise Part 5 onward (events, workers, Inngest) will feel like arbitrary complexity instead of a deliberate design choice [13].

**🎯 Goal of this lesson:** Understand the core philosophy — "events, not features" — see a tiny working demo of it, and know exactly what you'll have built, and in what order, by the end of the series.

**🧰 Prereqs:** None yet. Just Node.js installed and curiosity. (Full tooling setup — pnpm, monorepo scaffolding — happens in Part 2 [8]; no accounts like Clerk/Sanity/Neon/Inngest are needed until the part that actually uses them.)

---

## 1. Why "events, not features"

Most tutorials teach you to build a feature: "add a grading button," "add a quiz page." Greymatter LMS is deliberately taught differently. The core idea is that **a submission is an event, not a function call** — and every piece of intelligence that reacts to it (a grader, a quiz generator, a tutor, an analytics engine) is an independent listener, not a branch in an `if/else` block [13].

This matters because of what it *prevents*: no giant conditional deciding which AI feature to run, and no single monolithic backend service that has to be modified every time you add a new capability. Every box in the system only knows about the event bus in the middle — that's the whole point [13].

---

## 2. A tiny working demo, before touching the real stack

To feel this philosophy before any real infrastructure exists, here's the ~10-line simulation this series starts from:

```javascript
function emit(event, payload) {
  listeners[event]?.forEach(worker => worker(payload));
}

const listeners = {
  "assignment.submitted": [
    gradeSubmission,
    generateQuiz,
    checkForStruggle,
  ],
};

emit("assignment.submitted", { studentId: 1, text: "My essay..." });
```

Nothing here is "real" yet — no database, no auth, no network calls. But it already demonstrates the entire shape of the system: one event, many independent workers reacting to it, and zero coupling between them. Everything we build from Part 1 onward is this same idea, scaled into real infrastructure.

---

## 3. What "AI-native" means for Greymatter LMS

Because every capability is just a listener on an event, adding AI features later never means editing existing code — it means registering a new worker. By Part 11, you'll prove this concretely: real LLM-powered grading, quiz generation, tutor intervention, and lesson summaries all get added to a fully working LMS without touching the core Server Actions, the registry client, or the Worker SDK contract [10]. That's the payoff this philosophy is building toward — AI becomes modular, and each AI system stays independently replaceable [10].

---

## 4. The Greymatter architecture (conceptual model)

Translating the philosophy into the actual Greymatter stack, here's what we're building toward across this series:

```text
Clerk (Auth)
   |
   V
+-----------------------------+
|      Next.js 16 LMS        |
|   (React 19 + Tailwind)    |
+-----------------------------+
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
                  |
                  V
        Neon Postgres (Results Storage)
```

Notice what *doesn't* appear in this diagram: no giant `if/else` block deciding which AI feature to run, no single monolithic backend service. Every box only knows about the event bus in the middle — that's the whole point [13].

---

## 5. The real technology stack, mapped to layers

Since this is a hands-on build, it's worth naming the actual tools behind each conceptual box now, so nothing feels unexplained when it first appears:

| Layer | Technology | First appears in |
|---|---|---|
| Client + Application | Next.js 16 (React 19), Tailwind | Part 3 |
| Auth | Clerk | Part 3 |
| Data | Neon Postgres + Drizzle ORM | Part 4 |
| Orchestration | Inngest (event bus + workflow engine) | Part 5 |
| Registry | Sanity (worker discovery, not a CMS) | Part 6 |
| Execution | Independently deployed AI Workers | Part 7 |

Part 1 walks through *why* each of these was chosen and how strictly they're allowed to talk to one another [12].

---

## 6. What you'll actually have built, part by part

So this doesn't feel like arbitrary complexity, here's the full roadmap up front — each part builds directly on the previous one, and by Part 12 all of this is deployed and running in production:

1. **Part 1 — System Architecture:** the five layers, the event bus, one request traced end-to-end [12].
2. **Part 2 — Monorepo Setup:** scaffold the actual folder structure enforcing the boundaries from Part 1 [8].
3. **Part 3 — App Router Foundation:** Clerk-authenticated Next.js frontend that renders UI, emits events, and never runs AI logic itself.
4. **Part 4 — Data Modelling:** the Neon Postgres/Drizzle schema — the "memory" every worker reads from and writes back to [6].
5. **Part 5 — Inngest:** the Orchestration Layer goes live, and `assignment.submitted` becomes a real, runnable event [5].
6. **Part 6 — Plugin Registry:** Sanity as a live, queryable worker registry — add a feature by inserting a document, not shipping code [4].
7. **Part 7 — Worker SDK:** a standardized, HMAC-secured contract and the formal worker registration flow [3].
8. **Part 8 — Workflow Composition:** fan-out/fan-in execution and chained adaptive learning loops [2].
9. **Part 9 — Hardening:** a full threat model, securing the event surface against spoofed events and forged responses [1].
10. **Part 10 — Observability:** trace IDs, execution timelines, persistent logs, and cost tracking — no more "black box AI behavior" [11].
11. **Part 11 — AI-Native Features:** real LLM-powered grading, quizzes, tutoring, summaries, and knowledge graph extraction — added with zero core changes [10].
12. **Part 12 — Capstone Deployment:** every layer deployed to real infrastructure (Vercel, Neon, Inngest Cloud, Sanity, worker fleet) [9].

By the end, Greymatter LMS will have gone from this 10-line `emit()` simulation to a fully deployed, event-driven, AI-native LMS [9] — and every step along the way will be something you built yourself, in order, with a checkpoint to verify it before moving on.

---

## 7. What's next

In the original architecture notes, the next step is described as translating this philosophy into system architecture diagrams, service boundaries, event pipeline design, worker lifecycle, and data flow between the frontend, database, event engine, and registry [13].

For **Greymatter LMS**, Part 1 will do exactly that, with our actual stack:
* System architecture diagrams (Next.js 16 ↔ Clerk ↔ Neon Postgres ↔ Inngest ↔ Sanity)
* Service boundaries — what each piece is *allowed* and *not allowed* to do
* The event pipeline design
* Worker lifecycle basics
* Data flow: how a request moves from the browser all the way to an AI worker and back

**🩹 Common confusion at this stage:** "Do I need to sign up for Clerk, Sanity, Neon, or Inngest right now?" — No. Nothing in this part or Part 1 requires an account. Signups happen right before each tool is first used (Clerk and a monorepo checkpoint in Part 2/3, Neon in Part 4, Inngest in Part 5, Sanity in Part 6) [8].

Ready? → **Part 1: System Architecture — Mapping Out Greymatter LMS**
