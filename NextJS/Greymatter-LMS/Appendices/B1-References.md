# Appendix B — Key Concepts Glossary (with Examples)

Here's Appendix B with concrete examples added to each section, grounded in the source material.

---

## B.1 Orchestration vs. Execution

> "The LMS does not execute intelligence. It orchestrates intelligence execution." [5]

**Example:** When a student submits an assignment, the LMS itself never runs a grading algorithm or calls an AI model directly. Instead, it simply recognizes that `assignment.submitted` occurred and hands off responsibility. The actual grading intelligence lives entirely in a separate worker like Markly [5] — the LMS core's job stops at recognizing and routing the event.

---

## B.2 Event-Driven Architecture

**Example:** The dedicated tutorial for this layer is literally titled "Inngest, Orchestration, and AI Worker Execution" [5] rather than something like "How to Call the Grading Function" — reflecting that the system is built around reacting to events (`assignment.submitted`) rather than direct, synchronous function calls.

---

## B.3 Fan-Out

**Example:** A single `assignment.submitted` event triggers five independent workers simultaneously:

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

Each of these workers "runs independently, does not depend on others, can fail safely, can scale independently" [2] — for instance, if the Plagiarism Detector is temporarily overloaded, Markly's grading and the Analytics Engine's processing continue unaffected.

---

## B.4 Fan-In (Aggregation)

**Example:** A closely related worker execution model shows the same fan-out pattern with slightly different workers:

```text
assignment.submitted
|
+--> Markly (grading)
+--> Plagiarism detector
+--> Tutor AI
+--> Analytics engine
```
[5]

The results from all four of these — a grade, a plagiarism flag, tutor feedback, and analytics insight — would need to be aggregated back into a single view before being useful to a student or teacher, rather than four disconnected outputs.

---

## B.5 Conditional Workflows (Adaptive AI)

**Example:** The Adaptive Learning Flow shows a workflow that changes direction based on prior results rather than running a fixed sequence:

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

Here, "tutor intervention" only makes sense to trigger *if* the "performance analysis" step actually detected a problem — this is a decision point, not just a fixed pipeline.

---

## B.6 Event Chaining & Adaptive Learning Loops

**Example:** A concrete chain of events shows this in action:

```text
assignment.submitted
↓
grading.completed
↓
student.struggling
↓
tutor.intervention
↓
practice.assigned
```
[2]

This is explicitly described as creating "adaptive learning loops" [2] — notice that `student.struggling` is itself an event, likely emitted only when grading detects a low score, which then triggers `tutor.intervention` automatically, without any new instruction from the frontend.

---

## B.7 Multi-Tenant Isolation Principle

**Example:** The threat this principle prevents is spelled out directly: without strict isolation, "Student A sees Student B data," "Teacher A accesses Teacher B courses," and "AI workers leak cross-school insights" [1]. This is why "every table is scoped by organization" [6] at the database level — for example, a query for assignment data must always be filtered so a teacher at one school can never retrieve another school's assignments, submissions, or grading states [12].

---

## B.8 Capability-Based Extension

**Example:** Every AI tool is registered as a **Worker Document** [4], which allows the registry to answer questions beyond simple event matching. For instance, rather than only knowing "Markly listens to `assignment.submitted`," the registry can also describe *what Markly is capable of* (e.g., grading essays), enabling more flexible discovery as new workers with overlapping capabilities are added.

---

## B.9 AI Modularity / Replaceability

**Example:** The Versioning Strategy shows this principle in action directly: "Markly v1 → Markly v2 → Markly v3" [4]. Because "workers evolve independently" [4], upgrading Markly from v1 to v2 doesn't require touching Tutor AI, the Plagiarism Detector, or any other registered worker — each one can be replaced or upgraded on its own timeline.

---

## B.10 Full Decoupling of Workers

**Example:** The AI Workers layer lists concrete examples — grading AI (Markly), quiz generator, tutor assistant, analytics engine, recommendation system — and states each one "is independent, is stateless, obeys contract, can be replaced" [12]. A recommendation system could be swapped out entirely for a new implementation as long as it still obeys the same contract, with no other worker needing to know the change happened.

---

## B.11 No Hidden Coupling (Structural Dependency Rule)

**Example:** "Everything depends on: events, contracts, registry. Not direct imports" [8]. Concretely, this means the code for the Quiz Generator worker would never directly `import` code from Markly's grading logic — if they need to relate to each other at all, it happens through an event (like `grading.completed`) or through the registry, never a direct code-level dependency.

---

## B.12 Extensibility Over Completeness

**Example:** This principle is demonstrated by how new capabilities are added: "Add new worker + register in Sanity. No LMS rewrite required" [8], described as "Full extensibility" [8]. For example, adding a brand-new "Plagiarism Detector" worker to an already-running Greymatter LMS instance requires only building the worker and registering it — the existing courses, assignments, and grading workers remain completely untouched.

---

## B.13 Observability Principle — "If You Cannot Trace It, You Cannot Trust It"

**Example:** This principle is backed by real dashboard views: "Student AI feedback history, Assignment processing timeline, Worker health metrics, System-wide AI cost tracking" [11]. If a teacher questioned why a particular student received a certain AI-generated grade, the "Assignment processing timeline" view — built on the trace ID that "each Inngest workflow generates" [11] — would let staff reconstruct exactly which workers ran and what they returned for that specific submission.

---

## B.14 The Shift: From LMS to "Learning Intelligence System"

**Example:** This shift is captured in the key architectural principle: "Learning is not delivered. It is continuously inferred" [10]. Rather than a static gradebook simply recording a score once, the system continuously reinterprets a student's progress — for instance, Lesson Summaries are described as "Auto-Generated Knowledge Compression" [10], meaning the system is actively generating new interpretive artifacts from lesson content, not just storing what a teacher originally wrote.

---

## B.15 Dynamic AI Plug-in System (Registry Role)

**Example:** Because the registry stores workers as documents rather than hardcoded integrations, an entire marketplace model becomes possible: "LMS App Store, AI Worker Marketplace, Educational plugin ecosystem" [4]. A third-party developer could build a new worker, register it as a Worker Document, and it would become discoverable by the same registry mechanism already serving Markly and Tutor AI — no different in kind from the tools built by the core team.
