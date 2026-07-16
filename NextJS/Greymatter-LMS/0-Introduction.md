# Part 0 — Introduction: The Philosophy Behind Greymatter LMS

Welcome to the first lesson in the **Greymatter LMS** tutorial series. Before we write a single line of production code, we need to understand *why* Greymatter is built the way it is — otherwise Part 5 onward (events, workers, Inngest) will feel like arbitrary complexity instead of a deliberate design choice [13].

**🎯 Goal of this lesson:** Understand the core philosophy — "events, not features" — see a tiny working demo of it, understand every tool you'll use before you install it, and know exactly what you'll build, and in what order, across the rest of this series.

**🧰 Prereqs:** None yet. Just Node.js installed (npm ships bundled with it) and curiosity. Full tooling setup happens in Part 2.

---

## 1. The problem: feature explosion

Imagine building Greymatter LMS the "obvious" way. A student submits an assignment, so you write a function that grades it. Then product wants auto-generated quizzes, so you add a line to that same function. Then a tutor bot, then lesson summaries, then a knowledge graph, then analytics — every new AI capability means reopening this one function and adding another call into it. Eventually it's a dozen unrelated responsibilities tangled together, all succeeding or failing as a single unit. This is *feature explosion*, and it's exactly what this series is designed to avoid.

## 2. The alternative: events, not features

Instead of a function that *knows about* every capability, Greymatter LMS emits a plain description of what happened:

```js
emit("assignment.submitted", { submissionId, studentId, courseId });
```

Nothing here calls a grader, a quiz generator, or a tutor bot directly. It just states a fact. Separately, any number of independent "workers" can *subscribe* to that fact and react — without the emitter ever needing to know they exist. Adding a new AI capability later means adding a new subscriber, never editing this line again.

## 3. A tiny runnable demo

```js
// demo-event.js
function emit(event, payload) {
  listeners[event]?.forEach(worker => worker(payload));
}

function gradeSubmission({ submissionId }) {
  console.log(`📝 Grading: ${submissionId}`);
}

function generateTutorFeedback({ submissionId }) {
  console.log(`🧠 Generating tutor feedback for: ${submissionId}`);
}

function updateAnalytics({ studentId }) {
  console.log(`📊 Updating analytics for: ${studentId}`);
}

const listeners = {
  "assignment.submitted": [gradeSubmission, generateTutorFeedback, updateAnalytics],
};
```

This ~10-line simulation is what the entire series is built on top of [13]. Walking through it: `listeners` is a plain object mapping an event name to an array of functions. `emit(...)` looks up that array and calls every function in it. Because `"assignment.submitted"` maps to three separate functions, one `emit()` call triggers three independent reactions, none of which know the others exist.

**✅ Checkpoint:** Save this as `demo-event.js`, add one line at the bottom calling `emit("assignment.submitted", { submissionId: "abc123", studentId: "s1" })`, and run `node demo-event.js`. Confirm all three console.log lines print. Then add a fourth function of your own — maybe a `sendEncouragementEmail` — and add it to the `listeners` array, without touching `emit()` at all. That one addition, with zero changes to existing code, *is* the entire architectural principle Greymatter LMS is built on.

This toy version can't survive production — it can't retry a failed worker, discover new workers without a code change, or verify a request wasn't forged. Parts 5 through 10 turn this same idea into something durable, culminating in real AI workers added in Part 11 with zero changes to the core.

---

## 4. The tools you'll use, and why (a preview)

You don't need to install any of these yet — each is introduced right before you need it:

| Tool | Role | Introduced in |
|---|---|---|
| **Node.js + npm** | JavaScript runtime and package manager (npm ships with Node.js) | Part 2 |
| **Next.js 16 (App Router)** | Frontend framework — pages, routing, Server Actions | Part 3 |
| **Clerk** | Authentication and organization membership | Part 3 |
| **Neon Postgres + Drizzle ORM** | Database and its type-safe query layer | Part 4 |
| **Inngest** | Event bus and workflow engine — the "emit/listeners" from our demo, made durable | Part 5 |
| **Sanity** | Real-time, queryable registry of which AI workers exist and are enabled | Part 6 |
| **HMAC request signing** | Proves a worker call is genuinely from Greymatter LMS, not forged | Part 7, hardened in Part 9 |

This series uses **npm** throughout, including npm's built-in workspaces feature for the monorepo — letting a shared package be imported directly by the frontend or a worker without publishing it anywhere.

---

## 5. The roadmap — what you'll build, part by part

So this doesn't feel like abstract theory, here's the full build plan up front. Each part assumes the previous one is complete, and ends with a checkpoint before moving on:

1. **Part 1 — System Architecture:** design the real services, boundaries, and layers Greymatter LMS is built from, and trace one event end-to-end.
2. **Part 2 — Project Foundation:** scaffold a real, running Next.js app with `create-next-app`, then grow the surrounding monorepo — shared packages and `infra/*` folders — around it, so the architectural boundaries from Part 1 are enforced by the codebase itself.
3. **Part 3 — Next.js App Router Foundation:** build the first executable piece of the system — the frontend shell, route groups, and Clerk authentication.
4. **Part 4 — Data Modelling:** design the Neon Postgres/Drizzle schema — the "memory" every AI worker reads from and writes results back into.
5. **Part 5 — Inngest Workflow Engine:** build the Orchestration Layer and make the `submitAssignment` stub emit a real event, `assignment.submitted`.
6. **Part 6 — Plugin Registry:** replace the hardcoded worker array with a real, queryable Sanity-based registry, so adding a new AI worker becomes a content edit, not a code change.
7. **Part 7 — Worker SDK:** build a shared input/output contract, HMAC-signed requests, a real callable Grading Worker, and a formal registration flow.
8. **Part 8 — Workflow Composition:** design fan-out/fan-in orchestration, conditional branching, and chained events into an adaptive learning loop.
9. **Part 9 — Hardening:** reinforce tenant scoping, event validation, and the defenses quietly assumed since Part 4.
10. **Part 10 — Observability:** add tracing, logging, and cost tracking across every workflow run.
11. **Part 11 — AI-Native Features:** replace every simulated worker response since Part 5 with real LLM-powered summaries, quiz generation, and tutoring — proving "new AI feature = new worker, no core changes."
12. **Part 12 — Capstone Deployment:** deploy every layer to real infrastructure and map the full architecture diagram onto production.

By the end, Greymatter LMS will have gone from this 10-line `emit()` simulation to a fully deployed, secure, observable, AI-native LMS — and every step along the way will be something *you* built, in order, with a working checkpoint before moving to the next.

---

Ready? → **Part 1: System Architecture — Designing the Layers of Greymatter LMS**
