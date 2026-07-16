# Appendix D — External Services & Setup Reference (with Examples)

Here's Appendix D with concrete examples added to each section, grounded in the source material.

---

## D.1 Clerk (Authentication)

**What it's for:** Identity and authentication, sitting at the top of the architecture stack, authenticating users before they ever reach the LMS itself [13].

**Example:** A teacher named Ms. Rivera logs into Greymatter LMS. Clerk authenticates her session before any request reaches the Next.js LMS layer, matching the flow shown in the final conceptual model where Clerk sits directly above the Next.js LMS box [13]. Once authenticated, her identity (and organization membership) is what every downstream layer — Server Actions, the database, Inngest — relies on when enforcing the isolation principle that "everything is organization-bound" [1].

---

## D.2 Supabase → Neon Postgres (Database)

**What it's for:** The core academic data model, storing structured records such as assignments — for example, a table storing `course_id`, `lesson_id`, `title`, `description`, and `due_date` for every assignment created in the system [6].

**Example:** When a course creator builds a new assignment ("Essay: Causes of WWI," due next Friday), that record is inserted into the `assignments` table, referencing its parent `course_id` and `lesson_id` [6]. Later, when Markly (the grading worker) generates a lesson summary, that output goes into a *separate* `lesson_summaries` table with its own `summary` and `key_points` fields [6] — keeping AI-derived content cleanly separated from the original assignment record, exactly the "source of truth vs. source of interpretation" pattern this layer is built around.

**Greymatter LMS adaptation example:** Since Neon doesn't provide RLS like Supabase does in the original Defense-in-Depth chain [1], a Greymatter LMS developer would need to manually add a `WHERE organization_id = ...` clause to the query fetching assignments for Ms. Rivera's school, rather than relying on a database policy to filter it automatically.

---

## D.3 Inngest (Orchestration / Event Engine)

**What it's for:** The event-driven workflow engine coordinating AI worker execution rather than performing intelligence itself, as covered in "Tutorial 05: Inngest, Orchestration, and AI Worker Execution" [5].

**Example:** A student submits an assignment, firing an `assignment.submitted` event. Inngest then independently triggers Markly (grading), a plagiarism detector, Tutor AI, and an analytics engine — each running on its own [5]. If the workflow needs to go further — say, the student scored poorly — Inngest can chain into follow-up events like `grading.completed → student.struggling → tutor.intervention → practice.assigned` [2], all coordinated without the frontend needing to know any of this is happening.

---

## D.4 Sanity (Worker Registry — not a CMS)

**What it's for:** Explicitly *not* content management — it's a runtime registry storing AI workers, tool definitions, schemas, and execution metadata [12], where every AI tool is modeled as a **Worker Document** [4].

**Example:** When the team wants to add a new grading tool called "Markly," they create a Worker Document for it in Sanity describing its capabilities and version. As Markly improves over time, this becomes a real versioning trail: "Markly v1 → Markly v2 → Markly v3" [4], with each version tracked in the registry rather than hardcoded into the LMS. This same registry setup is what later allows a broader ecosystem to emerge — as the source material puts it, "You can build: LMS App Store, AI Worker Marketplace, Educational plugin ecosystem" [4] — all powered by the same Worker Document model.

---

## D.5 Worker SDK / Third-Party AI Services

**What it's for:** A standard SDK interface [3] that lets independently built AI tools plug into the LMS, illustrated by the example marketplace:

```text
Nexus Marketplace
|
+-- Markly (grading)
+-- TutorAI
+-- ExamGuard
+-- InsightAI
```
[3]

**Example:** Suppose a third-party developer wants to build "ExamGuard," a proctoring tool. They'd implement the standard SDK interface defined for AI plug-ins [3], deploy ExamGuard as its own service, and register it in the Sanity registry (D.4) so Inngest can discover and call it during exam-related events — without ever needing direct access to Greymatter LMS's internals.

---

## D.6 Cross-Cutting Requirement: Multi-Tenant Isolation

**What it's for:** Not a service itself, but a rule every service above must respect: "Everything is organization-bound" [1].

**Example:** Both Clerk (D.1) and the database (D.2) must agree on the same `organization_id` for a given user. If Ms. Rivera's Clerk session says she belongs to "Riverside Academy," every Neon/Supabase query her actions trigger — fetching courses, assignments, or worker results — must filter by that same organization ID, ensuring she never sees data belonging to a different school using the same Greymatter LMS instance.

---

## D.7 CI/CD & Production Deployment Services

**What it's for:** The capstone layer covering pipeline architecture and disaster recovery planning for the full stack [9].

**Example:** Once Greymatter LMS is ready to launch, the team sets up a CI/CD pipeline (per the "CI/CD Pipeline Architecture" section [9]) so that every code change to the Next.js frontend, Inngest functions, or Sanity schemas is automatically tested and deployed. Separately, they define a Disaster Recovery Model [9] — for instance, deciding how quickly the production `Supabase (Results Storage)` layer shown in the production architecture diagram [9] would need to be restored if it went down.

---

## D.8 Quick Reference Table

| Service | Original Spec | Example Use Case |
|---|---|---|
| Clerk | Clerk [13] | Authenticating Ms. Rivera before she reaches the LMS |
| Database | Supabase [6] | Storing assignment records; separating AI summaries into their own table [6] |
| Orchestration | Inngest [5] | Fanning out `assignment.submitted` to Markly, plagiarism detector, Tutor AI, analytics [5] |
| Registry | Sanity [4] | Registering Markly v1 → v2 → v3 as Worker Documents [4] |
| Worker Ecosystem | Custom SDK [3] | A third party building "ExamGuard" via the standard SDK interface [3] |
| CI/CD & Recovery | Capstone tooling [9] | Automating deploys and planning recovery for the production Supabase results layer [9] |

---

## D.9 How to Use This Appendix

Before starting any tutorial part that introduces a new service, check this appendix first and use the worked examples above as a template: trace through what *your* equivalent of "Ms. Rivera submitting an assignment" or "registering ExamGuard" would look like for the feature you're building, and confirm the organization-scoping rule (D.6) is respected at every step.
