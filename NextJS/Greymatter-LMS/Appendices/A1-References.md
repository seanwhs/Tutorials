# Appendix A — System Architecture Reference (with Examples)

Here's Appendix A with concrete examples added to each section, grounded in the source material.

---

## A.1 The Foundational Principle

> "The LMS does not execute intelligence. It orchestrates intelligence execution." [5]

**Example:** When a student submits an assignment, the LMS's job is only to recognize that `assignment.submitted` occurred and route it onward. The actual grading — the "intelligence" part — happens entirely inside a separate worker like Markly [5]; the LMS core never runs a grading model itself, it only coordinates the handoff.

---

## A.2 The Conceptual Model (Where It All Started)

```text
Clerk
|
V
+-----------------------------+
|        Next.js LMS         |
+-----------------------------+
|              |
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
```
[13]

**Example:** Trace a single path through this diagram: a user authenticates via Clerk, opens the Next.js LMS, and interacts with the "Assignments" branch. That action reaches the Inngest Event Bus, which consults the Worker Registry (Sanity) to discover who should respond — and the registry returns "Grading," which then runs independently of "Quizzes," "Tutors," or "Analytics," even though all four sit at the same level in the diagram.

---

## A.3 The Five Architectural Layers

**Example:** The AI Workers (Execution Layer) row of this table is populated with concrete examples in the source material: grading AI (Markly), quiz generator, tutor assistant, analytics engine, and recommendation system [12] — each one described as independent, stateless, contract-obeying, and replaceable [12]. This is the Execution layer column of the table made concrete: none of these five examples know about each other or about the Next.js frontend directly.

For the Registry layer, an example of what it explicitly is *not* doing: it's not managing a blog post or marketing page — it's the system tracking metadata about the Grading, Quiz, Tutor, and Analytics workers shown in A.2's diagram.

---

## A.4 The Multi-Tenant Isolation Principle

> Every piece of data belongs to `organization_id`. No exceptions. [1]

**Example:** Consider the "Assessment Context" data the LMS manages — assignments, submissions, grading states, rubrics, and feedback artifacts, explicitly noted as "where AI workers heavily interact" [12]. Every one of these — a specific submission row, a specific rubric — must carry an `organization_id`, so that a grading worker processing School A's submissions can never accidentally read or write School B's assessment data.

---

## A.5 Worker Execution Model — The Fan-Out Pattern

```text
assignment.submitted
|
+--> Markly (grading)
+--> Plagiarism detector
+--> Tutor AI
+--> Analytics engine
```
[5]

**Example:** A related fan-out list shows a slightly expanded worker set reacting to the same event:

```text
assignment.submitted
|
+--> Markly (grading)
+--> Tutor AI (feedback)
+--> Plagiarism Detector
+--> Analytics Engine
+--> Quiz Generator
```
[2]

Here, each worker "runs independently, does not depend on others, can fail safely, can scale independently" [2] — for example, if the Quiz Generator is slow or temporarily down, Markly's grading and the Plagiarism Detector's check still complete normally.

---

## A.6 Fan-In — Aggregating Independent Results

**Example:** In the fan-out example above (A.5), five separate workers each produce their own output — a grade from Markly, a feedback note from Tutor AI, a flag from the Plagiarism Detector, an insight from Analytics Engine, and a new quiz from Quiz Generator [2]. Fan-in is the step that would take all five of these disconnected outputs and combine them into one report a teacher or student actually views, rather than five separate, unrelated records.

---

## A.7 Conditional & Adaptive Workflows

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

**Example:** A more specific version of this same idea shows the actual event names involved: `assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned` [2], explicitly stated to create "adaptive learning loops" [2]. Concretely, `student.struggling` would only be emitted if the grading step's "performance analysis" detected a low score — otherwise, the chain would simply end after grading, with no tutor intervention triggered at all.

---

## A.8 Worker Evolution — Versioning as an Architectural Concern

```text
Markly v1 → Markly v2 → Markly v3
```
[4]

**Example:** Because "workers evolve independently" [4], the team could upgrade Markly from v1 to v2 — say, switching its underlying grading model — without touching the Quiz Generator, Tutor AI, or Analytics Engine at all, and without any LMS rewrite required [8]. This directly enables the marketplace model described in the source material: an "LMS App Store," "AI Worker Marketplace," or "Educational plugin ecosystem" [4] can emerge because each worker's version history is independent of every other worker's.

---

## A.9 Observability as an Architectural Layer, Not a Bolt-On

> "If you cannot trace it, you cannot trust it." [11]

**Example:** Each Inngest workflow generates a trace ID [11], meaning that when the chain from A.7 runs (`assignment.submitted → grading.completed → student.struggling → tutor.intervention → practice.assigned`), every one of those five steps is tied to the same traceable execution path — letting a teacher or admin later reconstruct exactly why a specific tutor intervention fired for a specific student.

---

## A.10 The Production Architecture Diagram

```text
Users
↓
Next.js (Frontend)
↓
Supabase (DB + Auth + RLS)
↓
Inngest (Event Engine)
↓
Sanity (Worker Registry)
↓
AI Workers (Distributed Systems)
↓
Supabase (Results Storage)
```
[9]

**Example:** Trace a real request through this production diagram: a user submits an assignment through the Next.js frontend; Supabase enforces that they can only write to rows matching their own organization; the event reaches Inngest, which queries Sanity's Worker Registry and discovers Markly and Tutor AI; those AI Workers execute independently; and their results — a grade, some feedback — are written back into Supabase's Results Storage layer, ready to be displayed the next time the student loads their dashboard.

**Greymatter LMS adaptation example:** Following the Neon/Clerk substitution noted earlier in this appendix (A.10 discussion), the same request would instead pass through Clerk for auth, Neon Postgres for storage, with manual `organization_id` checks standing in for Supabase's RLS — every other step in the trace above remains identical.
