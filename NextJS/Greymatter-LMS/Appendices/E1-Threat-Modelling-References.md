# Appendix E — Threat Model & Security Reference (with Examples)

Here's Appendix E with concrete examples added to each section, grounded in the source material.

---

## E.1 The Foundational Isolation Principle

> "Every piece of data belongs to: `organization_id`. No exceptions." [1]

Restated as a summary principle: "Data is always scoped. Everything is organization-bound." [1]

**Example scenario:** Imagine two schools, "Riverside Academy" and "Oakwood High," both using Greymatter LMS. Riverside's `organization_id` is `org_riverside`, Oakwood's is `org_oakwood`. Every row in every table — courses, assignments, submissions, worker results — carries one of these two values. A query for "all submissions for assignment X" must *always* include `WHERE organization_id = 'org_riverside'` (or whichever org the requester belongs to). There is no scenario in the source material where a query is allowed to skip this filter — the rule is stated unconditionally both times it appears [1].

---

## E.2 Defense-in-Depth Architecture

```text
Client Layer (untrusted)
↓
Server Actions (validated)
↓
Supabase (RLS enforced)
↓
Inngest (controlled execution)
↓
Registry (sanitized worker discovery)
↓
Workers (isolated execution)
```
[1]

**Example — tracing one request through the chain:** A student at Oakwood High clicks "Submit Assignment."

1. **Client Layer** — the browser sends the submission content. This is treated as untrusted input, even though it came from a logged-in student [1].
2. **Server Actions** — the action validates the student's session and confirms they're actually enrolled in that course before accepting the submission [1].
3. **Database (RLS enforced)** — even if the Server Action had a bug, the database itself would reject any row insert or query that doesn't match the caller's `organization_id` = `org_oakwood` [1].
4. **Inngest** — once the submission is saved, an `assignment.submitted` event is emitted, and Inngest executes the workflow in a controlled, predefined manner — it doesn't allow arbitrary code execution [1].
5. **Registry** — Inngest asks Sanity "which workers listen to `assignment.submitted`?" and receives a sanitized list — e.g., Markly (grading), Tutor AI, Analytics engine [5] — not a raw, unchecked list of arbitrary endpoints.
6. **Workers** — each worker (Markly, Tutor AI, etc.) executes independently and in isolation [5], so if the Analytics engine crashes, it doesn't affect Markly's grading run.

*(Note: if using the Greymatter LMS Neon adaptation instead of Supabase, step 3 becomes "manual `organization_id` checks in application code," since Neon has no built-in RLS.)*

---

## E.3 What This Model Explicitly Prevents

**Example — a violation this chain is designed to stop:** Without the isolation principle enforced at every layer, a bug in a single query could let a Riverside Academy teacher pull up a class roster and accidentally see Oakwood High's students' grades. The chain in E.2 exists precisely so that even if the Server Action layer had a bug, the database layer (RLS or manual checks) would still catch and block that cross-organization access [1].

---

## E.4 Why Worker Isolation Is a Security Boundary

> "Workers do not depend on LMS internals." [3]
> "AI is fully decoupled. Workers evolve independently." [7]
> "Each AI system is replaceable." [4]

**Example:** Consider "ExamGuard," a third-party proctoring worker from the example ecosystem [3]. If ExamGuard were compromised or started misbehaving — say, returning malformed data or crashing — it cannot reach into the LMS's core database tables, cannot call other workers like Markly or TutorAI directly, and cannot affect the Next.js frontend. Its blast radius is limited to its own execution and whatever result it writes back through the sanctioned registry/Inngest pipeline. This is also why versioning is safe: Markly can go from v1 → v2 → v3 [4] without ExamGuard or TutorAI needing any changes, since none of them depend on Markly's internals.

---

## E.5 Registry as a Security Gatekeeper

The registry is explicitly the "sanitized worker discovery" checkpoint between Inngest and the workers [1].

**Example:** Every AI tool is registered as a Worker Document [4] — for instance, a Worker Document for Markly might specify it handles grading and listens for `assignment.submitted`. When Inngest queries the registry for `assignment.submitted`, it only gets back workers that are properly registered, versioned, and matched by capability [4] — not just any endpoint that happens to be listening on the network. If someone tried to stand up a rogue "fake-markly" service, it would need to be explicitly registered in Sanity to ever receive traffic — an unregistered service is simply invisible to the pipeline.

---

## E.6 Source of Truth vs. Source of Interpretation

> "Supabase is the source of truth. AI is the source of interpretation." [6]
> "To avoid mixing raw AI output with system data, we normalize artifacts." [6]

**Example:** Suppose Markly (the grading AI) hallucinates and outputs a nonsensical grade or feedback string for a submission. Because lesson summaries and other AI outputs are stored in their own dedicated tables — e.g., `lesson_summaries`, with fields like `summary` and `key_points jsonb` [6] — rather than overwriting the actual `assignments` or `submissions` records [6], the bad output only pollutes its own artifact row. The original assignment record (`assignments` table, referencing `course_id` and `lesson_id` [6]) remains untouched and trustworthy, since it was never AI-writable in the first place.

---

## E.7 Traceability as a Security Control

> "If you cannot trace it, you cannot trust it." [11]
> "Full traceability. Every decision is logged." [11]

**Example:** The observability dashboards described in the source material include views like Student AI feedback history, Assignment processing timeline, Worker health metrics, and System-wide AI cost tracking [11]. If an administrator noticed something suspicious — say, an unusually high number of "Tutor AI" invocations for one student, or unexpected cost spikes ("Tutor AI: $0.08 per submission" [11] suddenly appearing far more often than normal) — the trace ID generated for each Inngest workflow [11] would let them reconstruct exactly which event triggered it, which worker ran, and what it returned, rather than guessing after the fact.

---

## E.8 Known Gaps (Honest Assessment)

**Example of a gap:** The source material establishes *that* every workflow generates a trace ID and *that* costs like "Markly: $0.03 per submission" [11] are tracked, but it doesn't specify, for instance, how often the `WORKER_SIGNING_SECRET`-style credentials should be rotated, or exact rate-limit thresholds for `/api/inngest`-style endpoints. If you needed those specifics for a real production audit, you'd need to extend E.1–E.7's principles with your own concrete policy — the source material gives you the architecture-level rules, not an operations runbook.
