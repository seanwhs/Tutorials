# Appendix D — External Services & Setup Reference

This appendix consolidates every external service, hosted component, and setup dependency referenced throughout the Greymatter LMS series into a single checklist. Where a service was originally specified as Supabase in the source material, the Greymatter LMS adaptation (Neon + Clerk) is noted alongside it.

---

## D.1 Clerk (Authentication)

**What it's for:** Identity and authentication, sitting at the very top of the architecture stack. In the original conceptual model, Clerk is literally the first box authenticated users pass through before ever reaching the LMS itself:

```text
Clerk
|
V
+-----------------------------+
|        Next.js LMS         |
+-----------------------------+
```
[13]

**Where it's used across the series:** Every downstream layer assumes a Clerk-authenticated identity is already available — it's the entry point validated by "Server Actions (validated)" in the Defense-in-Depth chain before any request reaches the database or orchestration layers [1].

**Setup checklist:**
- Create a Clerk application
- Grab publishable + secret keys
- Configure organization/multi-tenancy support (since every piece of data is organization-bound — see D.6 below) [1]

---

## D.2 Supabase → Neon Postgres (Database)

**What it's for:** The core academic data model — the source material specifies this as where courses, modules, lessons, enrollment, and progress tracking are stored [12]. It's described directly as "the core academic data model" [12].

**Where it's used across the series:**
- Core Schema Design for the entire application [6]
- AI Artifact Tables — an optional expansion layer specifically so raw AI output doesn't get mixed with core system data [6]
- The Defense-in-Depth chain, where this layer is responsible for RLS enforcement before Inngest ever executes anything [1]
- The course page data flow: "Fetch course data (Supabase)" happens immediately after a user opens a course [7]

**Greymatter LMS adaptation:** Since Neon Postgres doesn't provide built-in Row-Level Security or Auth, this checklist changes slightly for Greymatter LMS builders:
- Create a Neon project and database
- Set up a connection string (`DATABASE_URL`)
- Because there's no RLS layer, manually enforce the Multi-Tenant Isolation Principle — "every piece of data belongs to `organization_id`, no exceptions" [1] — in every query yourself
- Auth responsibilities move entirely to Clerk (D.1) rather than Supabase Auth

---

## D.3 Inngest (Orchestration / Event Engine)

**What it's for:** The event-driven workflow engine — the layer responsible for orchestrating AI worker execution rather than running intelligence itself [5]. The dedicated tutorial for this service is explicitly titled "Inngest, Orchestration, and AI Worker Execution" [5].

**Where it's used across the series:**
- Core event-driven workflow engine setup [5]
- Advanced orchestration: conditional/adaptive workflows [2] and multi-stage educational pipelines (grading → understanding analysis → knowledge gap detection → tutor intervention → practice generation → progress tracking) [2]
- Powers the observability/tracing system — "each Inngest workflow generates a trace ID. Powered by Inngest" [11]
- Referenced in the Defense-in-Depth chain as the "controlled execution" step, sitting between the database and the worker registry [1]

**Setup checklist:**
- Create an Inngest account/project
- Configure event keys and signing keys
- Set up local dev server for testing workflows before deploying

---

## D.4 Sanity (Worker Registry — not a CMS)

**What it's for:** Despite being a headless CMS product, it is explicitly repurposed in this architecture:

> "Powered by Sanity. Stores: AI workers, tool definitions, schemas, execution metadata. This is NOT content management. It is a runtime registry for AI capabilities." [12]

**Where it's used across the series:**
- Worker schema design — every AI tool is modeled as a Worker Document [4]
- Capability-based extension — matching workers by capability, not just by event name [4]
- Versioning strategy for AI tools, and a dynamic plugin marketplace model [5]
- Input/output contract validation and safe execution contracts for third-party workers [5]
- Referenced again at the capstone level with its role summarized simply as: "dynamic AI plug-in system" [9]
- Appears in the Defense-in-Depth chain as "Registry (sanitized worker discovery)," positioned between Inngest and the workers themselves [1]

**Setup checklist:**
- Create a Sanity project
- Deploy the worker registry schema
- Configure dataset access for both local development and production queries

---

## D.5 Worker SDK / Third-Party AI Services

**What it's for:** Not a single hosted service, but a standard SDK interface [3] that allows an entire ecosystem of independently deployed AI tools to plug into the LMS. The example ecosystem given in the source material:

```text
Nexus Marketplace
|
+-- Markly (grading)
+-- TutorAI
+-- ExamGuard
+-- InsightAI
```
[3]

**Where it's used across the series:** The possible ecosystem explicitly includes grading AI tools, tutoring agents, plagiarism detectors, analytics engines, and exam proctors — all plugging in via the SDK [3]. Each of these would be its own external service/deployment with its own setup requirements (API keys, hosting, etc.), separate from the core Greymatter LMS stack.

**Setup checklist (per worker):**
- Deploy the worker as its own service (any language/host)
- Register it in the Sanity registry (D.4) as a Worker Document
- Configure whatever third-party AI provider credentials that specific worker needs (e.g., an LLM API key)

---

## D.6 Cross-Cutting Requirement: Multi-Tenant Isolation

This isn't a service to sign up for, but a configuration requirement that touches **every** service above:

> "Every piece of data belongs to `organization_id`. No exceptions." [1]

When setting up Clerk (D.1), Neon (D.2), Inngest (D.3), and Sanity (D.4), confirm each one is configured to carry or respect an `organization_id` boundary — this is described as what enables safe multi-tenancy at the database layer specifically: "every table is scoped by organization" [6].

---

## D.7 CI/CD & Production Deployment Services

**What it's for:** The capstone architecture layer covering pipeline architecture and recovery planning for the whole stack once deployed [9].

**Where it's used across the series:**
- CI/CD Pipeline Architecture — automating build/test/deploy across the monorepo [9]
- Disaster Recovery Model — planning for failure recovery in production [9]

**Setup checklist:** Not detailed further in the available source material beyond these two section headers [9] — treat this as the stage where you connect your hosting provider(s) for Next.js, your Neon production branch, Inngest Cloud, and deployed Sanity Studio into a repeatable pipeline.

---

## D.8 Quick Reference Table

| Service | Original Spec | Greymatter LMS Adaptation | Primary Role |
|---|---|---|---|
| Clerk | Clerk [13] | Unchanged | Authentication, top of the stack |
| Database | Supabase [12] [6] | Neon Postgres | Core academic data + AI artifacts |
| RLS / Isolation | Supabase RLS [1] | Manual `organization_id` checks | Multi-tenant safety |
| Orchestration | Inngest [5] | Unchanged | Event bus, workflow execution, tracing |
| Registry | Sanity [12] [4] | Unchanged | Worker discovery, capability matching |
| Worker Ecosystem | Custom SDK [3] | Unchanged | Third-party AI tool plug-ins |
| CI/CD & Recovery | Capstone tooling [9] | Unchanged | Production deployment |

---

## D.9 How to Use This Appendix

Before starting any tutorial part that introduces a new service, check this appendix first to confirm:
1. Do you have an account/project created for it already? (D.1–D.4)
2. Does it need to respect the organization-scoping rule? (D.6) — nearly everything does.
3. Is this a core hosted service, or a third-party worker you're expected to deploy yourself? (D.5)

If a specific setup step (exact dashboard screen, exact CLI command) isn't covered here, that level of detail wasn't present in the source material reviewed for this appendix — treat D.1–D.5's checklists as a starting outline to fill in with each provider's current onboarding docs.
