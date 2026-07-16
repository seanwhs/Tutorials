# Architectural Proposal: Greymatter LMS — Reintroducing Sanity as a Traditional Headless CMS with a Dedicated Quizzes & Exams Module

---

## 1. Executive Summary

Greymatter LMS's current architecture was built around one central idea: every AI capability — grading, quiz generation, tutoring — runs as an independently registered **worker**, discovered at runtime through a live Sanity registry and invoked through a signed HTTP call orchestrated by Inngest [12][13]. That design is genuinely valuable when the thing being executed requires actual intelligence — grading open-ended text, generating novel questions, or intervening when a student is struggling [10].

It is not valuable when the thing being executed is a deterministic comparison: "did the student pick option B, and is B the correct answer?" Today, even a plain multiple-choice quiz submitted by a student routes through the same fan-out worker execution path used for adaptive tutoring [2], and the Quiz Worker registered in Part 8 to prove fan-out capability still returns a static placeholder array rather than doing any real evaluation [2][10]. That's paying full orchestration and (eventually) LLM cost for a task with no genuine non-determinism in it.

This proposal makes an explicit, named pivot away from two specific decisions in the existing architecture:

1. **Sanity stops being the runtime Worker Registry** [4] and reverts to a traditional headless CMS role: structured course content, lessons, and quiz/exam authoring only.
2. **Quizzes and exams stop being AI workers** entirely. A new, dedicated **Quizzes & Exams Module**, living inside `apps/web`, grades objective assessments with plain server-side JavaScript — no registration, no HMAC signing, no LLM call, zero marginal token cost.

Everything else in the existing architecture — Neon Postgres via Drizzle [6], Inngest for async side effects [5], Clerk-based tenant scoping [7], event hardening [1], and observability via `traceId` [11] — is kept, not replaced, and is explicitly extended to cover this new module rather than bypassed.

---

## 2. Why This Is a Pivot, Not an Extension

It would be easy to describe this as simply "adding a new module," but that undersells what's actually changing. The table below names each existing decision this proposal moves away from, and why.

| Existing Greymatter Decision | What Changes | Why |
|---|---|---|
| Sanity is the **Registry Layer**: a live, queryable list of which AI workers exist, their `events`, `endpoint`, and `enabled` state, so adding a worker is "one Sanity edit, zero redeploys" [4] | Sanity holds **only content**: courses, lessons, quiz questions, and answer keys. No worker documents live there for quizzes. | Quizzes no longer need to be discoverable/pluggable AI capabilities — they need to be authored content with a locked-down answer key. |
| The Quiz Worker registered in Part 8 specifically to prove multi-subscriber fan-out (`findWorkers` returning two documents for one event) [2], later slated to run real LLM-generated questions in Part 11 [10] | Quiz *grading* is removed from the worker model entirely. (Quiz *generation*, if still AI-assisted, can remain a worker — see section 6.) | Grading a fixed-answer question is a pure function, not a task requiring the Execution Layer's signing/trust boundary [3]. |
| Every worker call is HMAC-signed request/response, verified via `signPayload`/`verifySignature`, because "anyone could stand up an HTTP endpoint... with no verification" [3][4] | The Quiz Module makes no network call at all — it's an in-process function inside the same Next.js server runtime that received the submission. | There is no separate service boundary to secure when grading logic runs in the same process as the Server Action. |
| Inngest's four-step shape — fetch-context → discover-workers → execute-workers → persist-results — runs *before* any state exists [5] | For quizzes, state (the score) is written to Postgres **first**; Inngest is invoked only afterward, purely for side effects. | Matches how the existing chain already treats downstream events (`grading.completed → student.struggling → tutor.intervention`) as reactions to already-persisted state [2] — we're just moving that pattern earlier for this one flow. |

If open-ended assessment (essays, conceptual synthesis) or AI-driven quiz *generation* should stay in the worker model, that is a deliberate hybrid — Sanity would then serve two roles, CMS content and registry — and should be named as such in engineering docs, not discovered as an implicit side effect later.

---

## 3. Revised Component Map

```text
        [ Next.js Front-End Shell (apps/web) ]
                    │                  │
 1. Fetch JSON      │                  │ 3. Submit Answers
    Course/Quiz Data│                  │    (Zero-Token Request)
                    ▼                  ▼
      ┌────────────────────────┐  ┌────────────────────────────────────┐
      │   SANITY (Headless CMS)│  │   QUIZZES & EXAMS MODULE           │
      ├────────────────────────┤  │        (in apps/web, no registry)  │
      │ • Courses / Lessons    │  ├────────────────────────────────────┤
      │ • Quiz Qs + Answer Keys│  │ • Pulls answer keys from Sanity    │
      │ • No worker documents  │  │ • Grades locally in JS, no LLM     │
      │ • No registry state    │  │ • Computes deterministic score     │
      └────────────────────────┘  └────────────────────────────────────┘
                                                   │
                                                   │ 4. Persist to Neon
                                                   ▼
                                  ┌────────────────────────────────────┐
                                  │     NEON POSTGRES (Drizzle)        │
                                  │  quiz_submissions table (new),     │
                                  │  alongside existing submissions /  │
                                  │  worker_results tables [6]         │
                                  └────────────────────────────────────┘
                                                   │
                                                   │ 5. Emit validated,
                                                   │    traced event
                                                   ▼
                                  ┌────────────────────────────────────┐
                                  │      INNGEST (role unchanged)      │
                                  │ Async remediation, certification,  │
                                  │ analytics — same reactive pattern  │
                                  │ as grading.completed today [2]     │
                                  └────────────────────────────────────┘
```

---

## 4. Component Responsibilities

### A. Sanity — reverted to Content Domain only

No worker documents, no `enabled` flags, no runtime registry queries for quizzes. Sanity's job returns to what a headless CMS is meant to do: hold structured, editable course and assessment content. Correct-answer fields remain restricted to authenticated, server-only GROQ queries — never exposed to public/client-facing queries.

This is a genuine reversal of the registry pattern established in Part 6, where the entire payoff was "adding a Quiz Worker means creating one new document in Sanity Studio. No code touched, no redeploy" [4]. We are explicitly giving up that pluggability for quizzes in exchange for zero latency and zero cost on a task that never needed pluggability in the first place.

### B. Quizzes & Exams Module — new, deterministic, unregistered

Lives inside `apps/web`, not the Execution Layer. It does **not** go through the six-step worker registration flow [3], does not sign requests with `signPayload`, and does not verify responses with `verifySignature` [3] — because there is no independent network hop to secure. It is a same-process function call, closer in kind to the validation logic already living in Server Actions (e.g., the `auth()` check in `submitAssignment` [7]) than to an AI worker invocation.

### C. Neon Postgres — kept as-is, extended not replaced

We recommend continuing with **Drizzle**, not migrating to Prisma. The existing schema was deliberately built in `infra/db` as a single shared source of truth between `apps/web` and the Inngest functions [6], and a parallel ORM migration would fork that shared contract for no architectural benefit. Add one table alongside the existing `submissions` and `worker_results` tables [6]:

```typescript
// infra/db/schema.ts (extends the existing schema — not a replacement)
export const quizSubmissions = pgTable("quiz_submissions", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),        // from Clerk auth(), never client input — same discipline as existing tables [7]
  studentId: text("student_id").notNull(),
  quizId: text("quiz_id").notNull(),      // corresponds to the Sanity quiz document ID
  selectedAnswers: jsonb("selected_answers").notNull(),
  finalScore: integer("final_score").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
});
```

If there's a separate, standalone case for adopting Prisma system-wide, that should be scoped as its own migration project, not bundled silently into this proposal.

### D. Inngest — role unchanged, only triggered at a different point in the flow

Inngest continues to do exactly what it already does for `grading.completed → student.struggling → tutor.intervention` [2]: react to already-persisted state with non-blocking side effects (certification builds, remediation nudges, analytics). Two things from the existing hardening and observability work must carry over into this new flow rather than be treated as optional extras:

1. **Event validation before dispatch.** Part 9's hardening work exists specifically to reject malformed events — e.g., a `student.struggling` event missing a `submissionId` — before they reach a worker [1][2]. The new `lms/quiz.submitted` event needs the same validation, not a bare, unchecked `inngest.send`.
2. **`traceId` propagation.** Part 10 generates a `traceId` at the moment a student action occurs specifically so a single submission's full downstream effects can be traced across every function it triggers [11]. The Quiz Module must generate one at submission time and thread it through, exactly as `fetch-context`, `discover-workers`, `execute-workers`, and `persist-results` already do for assignments [11].

---

## 5. Server Execution Blueprint (continued)

```typescript
// apps/web/actions/quiz-actions.ts
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/infra/db";
import { quizSubmissions } from "@/infra/db/schema";
import { inngest } from "@/infra/inngest/client";
import { fetchSanityQuizAnswerKey } from "@/infra/sanity/client"; // content-only client, no registry queries
import { validateEventPayload } from "@/infra/inngest/validation";  // same hardening pattern as Part 9 [1]
import { logStep } from "@/infra/observability/logger";            // same tracing pattern as Part 10 [11]
import { randomUUID } from "crypto";

export async function submitQuiz(quizId: string, answers: Record<string, string>) {
  const { userId, orgId } = await auth();
  if (!userId || !orgId) throw new Error("Unauthorized");

  const traceId = randomUUID(); // generated at the point of student action, matching Part 10's approach [11]

  // 1. Fetch answer key from Sanity — content only, no registry lookup, no worker discovery [4]
  const answerKey = await fetchSanityQuizAnswerKey(quizId);

  // 2. Grade locally — zero tokens, zero LLM calls, no HMAC signing needed since there's no network hop [3]
  let correct = 0;
  const totalQuestions = Object.keys(answerKey).length;
  for (const [questionId, correctAnswer] of Object.entries(answerKey)) {
    if (answers[questionId] === correctAnswer) correct++;
  }
  const finalScore = Math.round((correct / totalQuestions) * 100);

  // 3. Persist to Neon Postgres via Drizzle, alongside the existing schema [6]
  const [record] = await db.insert(quizSubmissions).values({
    orgId,
    studentId: userId,
    quizId,
    selectedAnswers: answers,
    finalScore,
  }).returning();

  await logStep(traceId, "quiz-submitted", "grade-and-persist", "success", record);

  // 4. Validate the event shape before dispatch — same discipline as Part 9's hardening pass [1]
  const event = {
    name: "lms/quiz.submitted",
    data: {
      traceId,
      submissionId: record.id,
      orgId: record.orgId,
      studentId: record.studentId,
      quizId: record.quizId,
      finalScore: record.finalScore,
    },
  };
  const parsed = validateEventPayload(event);
  if (!parsed.success) {
    await logStep(traceId, "quiz-submitted", "validate-event", "failed", { error: parsed.error });
    throw new Error("Malformed quiz.submitted event — refusing to dispatch");
  }

  // 5. Hand off async side effects to Inngest — same reactive pattern as grading.completed [2][5]
  await inngest.send(parsed.data);
  await logStep(traceId, "quiz-submitted", "dispatch-event", "success", parsed.data);

  return { success: true, submissionId: record.id, score: record.finalScore, traceId };
}
```

The downstream Inngest function (`infra/inngest/functions/quizSubmitted.ts`) follows the exact same try/log/catch/rethrow shape already used for `assignment.submitted`'s `fetch-context`, `discover-workers`, `execute-workers`, and `persist-results` steps [11] — nothing new is invented here, the pattern is simply reused for a new event name.

---

## 6. What Stays a Worker (Explicit Scope Boundary)

To avoid ambiguity for engineers picking this up later, this proposal deliberately draws a hard line:

| Task | Stays a Worker? | Reasoning |
|---|---|---|
| Multiple-choice / true-false grading | **No** — moves to Quiz Module | Pure equality check, no non-determinism [10] |
| Exact formula / numeric answer matching | **No** — moves to Quiz Module | Same as above |
| Open-ended / essay grading | **Yes** — stays on Grading Worker | Genuinely requires language understanding, same as today [2][10] |
| AI-generated quiz questions (if kept) | **Yes** — stays a registered worker | Requires generative capability, still benefits from Sanity's pluggable registry [4] |
| Tutor intervention on low scores | **Yes** — stays inline in the Orchestration Layer | Already handled this way, not as a separate worker [10] |

If quiz *generation* remains AI-driven, Sanity ends up serving two roles simultaneously — CMS content and worker registry — which is fine, but should be documented as an intentional hybrid, not left for someone to infer later.

---

## 7. Business & Technical Benefits

**Absolute Determinism for Objective Assessment**
Grading moves from LLM inference to compile-time-simple JavaScript comparison, eliminating hallucination risk and output-format failures for the specific subset of assessments that never needed a model in the first place [10].

**Elimination of UI Blocking**
Because grading runs synchronously in the same server process handling the submission — no signed HTTP round trip to a separate worker [3] — there is no network latency, no polling, and no timeout risk during the exam-submission critical path.

**Preserved Observability and Hardening Guarantees**
Unlike a version of this proposal that treats the new module as a clean break from the rest of the system, this design explicitly reuses Part 9's event validation [1] and Part 10's `traceId`-based tracing [11], so this new path is queryable in `workflow_logs` exactly like every other student action, both locally and in production [9].

**Honest Cost Table**

| Assessment Form | Compute Path | Token Cost |
|---|---|---|
| Multiple Choice / True-False | Quiz & Exam Module (JS) | $0.00 |
| Exact Formula Matching | Quiz & Exam Module (JS) | $0.00 |
| Open-Ended Conceptual Review | Grading Worker (LLM) [10] | Metered |
| Adaptive Tutoring | Inline Orchestration Logic [10] | Metered |

---

## 8. Summary

This proposal is not an incremental addition to Greymatter LMS — it is a scoped reversal of two specific decisions: Sanity's role as a live worker registry [4], and quiz grading's place inside the AI Worker Execution Layer [2][3]. Everything else — Drizzle-based Postgres [6], Inngest's reactive orchestration model [2][5], Clerk-based tenant isolation [7], event validation [1], and trace-based observability [11] — is retained and extended, not discarded, so the new Quizzes & Exams Module is a first-class citizen of the existing system rather than a parallel, unmonitored path.
