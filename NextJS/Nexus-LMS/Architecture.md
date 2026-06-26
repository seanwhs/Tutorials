# Nexus LMS — System Architecture RFC

**Document Type:** RFC / Architecture Design Doc  
**Status:** Draft  
**Version:** 1.0  
**Primary Author:** sean wong  
**Audience:** Engineering, product, architects, AI platform contributors, security reviewers  
**Last Updated:** 2026-06-27  

---

## 1. Executive Summary

Nexus LMS is an AI-native, event-driven, modular Learning Management System designed to support dynamic educational workflows through a plugin-based architecture.

Unlike traditional LMS platforms that hardcode integrations and business logic, Nexus LMS uses a Plugin Registry Pattern powered by Sanity, enabling external AI workers, agents, and tools to participate in workflows without modifying core application code.

The system functions as:

- A Learning Platform.
- An AI Orchestration Engine.
- A Plugin Marketplace Platform.
- An Event-Driven Execution System.

The primary architectural principle is:

> Core systems never directly call AI services. Instead, events are emitted and resolved dynamically through a plugin registry.

---

## 2. Problem Statement

Traditional LMS platforms are typically built around tightly coupled application logic and hardcoded integrations. That makes them difficult to extend, difficult to observe, and expensive to evolve as AI capabilities change.

Nexus LMS is intended to solve that problem by making events the primary coordination mechanism and plugins the primary extension mechanism. The architecture must also support durable execution, tenant isolation, structured AI output, and full traceability across workflows.

---

## 3. Product Vision

### Vision Statement

Build a production-grade, extensible, AI-native educational platform where:

- AI capabilities are composable.
- Workflows are event-driven.
- External tools are pluggable.
- System evolution requires configuration rather than core code changes.

### Design Goals

#### Functional Goals

- Course management.
- Assignment management.
- Student submissions.
- AI grading.
- AI feedback generation.
- AI lesson summarization.
- AI quiz generation.
- Analytics.
- Plugin marketplace support.

#### Technical Goals

- Event-driven architecture.
- Multi-tenant support.
- Plugin extensibility.
- AI provider abstraction.
- Durable workflows.
- Production observability.
- Schema evolution support.

---

## 4. Scope

Nexus LMS consists of five major subsystem groups:

```text
Frontend Layer
        ↓
Application Layer
        ↓
Event Layer
        ↓
Plugin Layer
        ↓
AI Execution Layer
```

The system is designed as a modular execution platform rather than a monolithic LMS. Each layer has a narrowly defined responsibility and interacts with other layers through explicit contracts.

### In Scope

- User authentication and role-based access.
- Course, lesson, assignment, and submission workflows.
- Event-driven orchestration.
- Dynamic plugin discovery and execution.
- AI-assisted grading, feedback, summarization, and quiz generation.
- Observability and audit logging.
- Tenant-scoped persistence.

### Out of Scope

- Hardcoded provider integrations in core business logic.
- Direct AI invocation from user-facing application code.
- Shared global state across tenants.
- Synchronous orchestration as the primary workflow model.
- AI systems with unrestricted database or event access.

---

## 5. Technology Stack

| Component       | Technology           |
| --------------- | -------------------- |
| Frontend        | Next.js App Router   |
| Authentication  | Clerk                |
| Database        | Supabase PostgreSQL  |
| Authorization   | Supabase RLS         |
| Workflow Engine | Inngest              |
| Plugin Registry | Sanity               |
| AI Providers    | OpenAI / Claude      |
| Deployment      | Vercel               |
| Observability   | Supabase + Dashboard |

This stack is selected to support a server-first frontend, durable event orchestration, tenant-aware authorization, and runtime plugin discovery.

---

## 6. User Roles

### Student

Capabilities:

- Enroll in courses.
- View lessons.
- Submit assignments.
- Receive feedback.
- View grades.
- Interact with AI tutors.

### Instructor

Capabilities:

- Create courses.
- Publish lessons.
- Create assignments.
- Review submissions.
- Manage plugins.
- Monitor AI execution.

### Administrator

Capabilities:

- Manage tenants.
- Manage users.
- Configure plugins.
- Audit execution.
- Manage observability.

### Plugin Developer

Capabilities:

- Publish workers.
- Update worker versions.
- Test AI integrations.
- Deploy external tools.

These roles define the primary actors that the architecture must serve.

---

## 7. Architecture Overview

Nexus LMS is organized into layered responsibilities:

### 7.1 Presentation Layer

**Technology:** Next.js App Router  
**Responsibilities:** rendering UI, server actions, dashboards, API routes  
**Folder:** `apps/web`

### 7.2 Authentication Layer

**Technology:** Clerk  
**Responsibilities:** login, session management, identity management, JWT issuance

### 7.3 Event Layer

**Technology:** Inngest  
**Responsibilities:** event dispatching, retries, orchestration, scheduling, replay

### 7.4 Registry Layer

**Technology:** Sanity  
**Responsibilities:** plugin discovery, worker registration, version management, feature flags

### 7.5 Worker Layer

**Responsibilities:** AI grading, feedback generation, lesson summarization, quiz generation, analytics

### 7.6 AI Layer

**Responsibilities:** model routing, prompt management, validation, provider abstraction

### 7.7 Persistence Layer

**Technology:** Supabase PostgreSQL  
**Responsibilities:** storage, security, auditing, observability

---

## 8. Core Architectural Principles

### Principle 1 — Event First

Business operations never directly invoke downstream services. Instead:

```text
Action
   ↓
Event
   ↓
Worker Discovery
   ↓
Execution
```

### Principle 2 — Plugins Over Integrations

The LMS core never knows about specific AI providers, analytics engines, or future agents. Those capabilities are registered dynamically through the plugin registry.

### Principle 3 — Configuration Over Code

Adding functionality should usually mean:

```text
Add Plugin
   ↓
Enable Plugin
   ↓
System Discovers Capability
```

### Principle 4 — AI as a Worker

AI systems are not application logic. They are workers participating in workflows.

Examples:

- Grading worker.
- Feedback worker.
- Summary worker.
- Quiz generator.
- Tutor agent.

### Principle 5 — Durable Execution

All long-running operations execute through durable workflows. They must be:

- Retryable.
- Resumable.
- Replayable.
- Observable.

### Principle 6 — Multi-Tenant by Default

Every business entity belongs to a tenant. No global state is allowed.

### Principle 7 — Observability First

Every operation must be:

- Logged.
- Traceable.
- Replayable.
- Debuggable.

---

## 9. Monorepo Structure

```text
nexus-lms/
├── apps/
│   └── web/
├── packages/
│   ├── ai/
│   ├── db/
│   ├── inngest/
│   ├── registry/
│   ├── workers/
│   └── shared/
├── infra/
│   ├── supabase/
│   ├── sanity/
│   └── vercel/
├── docs/
└── scripts/
```

This structure separates the product app, shared packages, infrastructure definitions, and documentation into clear boundaries.

---

## 10. Requirements Traceability

This section maps the SRD to the architecture.

### Functional Requirements

- **FR-001 User Authentication** → Clerk + session layer.
- **FR-002 Course Management** → Application layer + persistence.
- **FR-003 Lesson Management** → Presentation layer + application services.
- **FR-004 AI Lesson Summarization** → Event layer + registry + AI layer.
- **FR-005 AI Quiz Generation** → Event layer + registry + AI layer.
- **FR-006 Assignment Management** → Application layer + persistence.
- **FR-007 Submission Management** → Application layer + event emission.
- **FR-008 AI Grading** → Worker layer + AI layer + validation.
- **FR-009 AI Feedback Generation** → Worker layer + AI layer + structured output.
- **FR-010 Plugin Registry** → Sanity registry layer.
- **FR-011 Worker Execution** → Inngest + worker layer.
- **FR-012 Event Orchestration** → Inngest event engine.
- **FR-013 Observability Dashboard** → event traces, worker logs, AI audit logs.

### Plugin Requirements

- **PR-001 Plugin Registry Pattern** → dynamic discovery through Sanity.
- **PR-002 Worker Schema** → enforced plugin contract.
- **PR-003 Worker Contract** → JSON input/output, schema validation, versioning.

### AI Requirements

- **AI-001 Model Abstraction** → AI layer.
- **AI-002 Structured Output** → validator layer.
- **AI-003 Prompt Versioning** → prompt management in AI packages.
- **AI-004 AI Audit Logging** → `ai_audit_logs`.

---

## 11. Event Architecture

Every workflow begins with an event.

### Event Examples

- `course.created`
- `lesson.published`
- `assignment.created`
- `assignment.submitted`
- `grading.completed`
- `feedback.generated`
- `analytics.generated`

### Event Structure

```json
{
  "id": "uuid",
  "event": "assignment.submitted",
  "tenantId": "tenant",
  "timestamp": "ISO8601",
  "data": {}
}
```

Events are immutable, durable, replayable, and observable.

---

## 12. Plugin Registry Architecture

The plugin registry is implemented using Sanity.

### Worker Registration Example

```json
{
  "id": "grading-worker",
  "name": "AI Grader",
  "version": "1.0",
  "event": "assignment.submitted",
  "enabled": true,
  "priority": 1,
  "endpoint": "https://api.example.com",
  "inputSchema": {},
  "outputSchema": {}
}
```

### Worker Resolution Flow

```text
Event
   ↓
Registry Lookup
   ↓
Resolve Workers
   ↓
Execute Workers
```

Workers must not be hardcoded into the core application. Discovery happens at runtime through registry lookup.

---

## 13. AI Architecture

AI execution follows a controlled pipeline:

```text
Event
   ↓
Prompt Builder
   ↓
Model Router
   ↓
LLM
   ↓
Validator
   ↓
Storage
```

### Supported AI Tasks

- Grading.
- Feedback generation.
- Summarization.
- Quiz generation.
- Tutoring.
- Analytics.

### AI Guardrails

- AI outputs must be structured.
- AI outputs must be schema validated.
- AI systems cannot write directly to the database.
- AI systems cannot emit events directly.
- AI systems cannot execute arbitrary code.

---

## 14. Database Architecture

### Core Tables

```text
users
courses
lessons
assignments
submissions
grades
plugins
event_traces
worker_logs
ai_audit_logs
```

### Multi-Tenant Model

Every table contains:

```sql
tenant_id
```

### Security

All tables implement Row Level Security.

This supports tenant isolation, defense in depth, and authorization enforcement at the database layer.

---

## 15. Security Architecture

Security exists in five layers.

### Authentication
**Provider:** Clerk

### Authorization
**Provider:** Supabase RLS

### Event Security
- Immutable.
- Append-only.
- Replayable.

### Plugin Security
- Schema validation.
- Endpoint validation.
- Timeout enforcement.

### AI Security
- Structured outputs only.
- No direct database writes.
- No direct event emission.
- No code execution.

---

## 16. Observability Architecture

Observability consists of three systems.

### Event Tracing
**Table:** `event_traces`

Captures:

- events
- payloads
- timestamps
- trace context

### Worker Tracing
**Table:** `worker_logs`

Captures:

- worker execution
- latency
- failures

### AI Auditing
**Table:** `ai_audit_logs`

Captures:

- prompts
- responses
- model versions
- validation

---

## 17. Failure Model

Nexus LMS assumes failures are normal.

### Failure Domains

- Event failures.
- Worker failures.
- AI failures.
- Database failures.
- Plugin failures.

### Recovery Flow

```text
Failure
   ↓
Isolation
   ↓
Logging
   ↓
Retry
   ↓
Recovery
```

Durable execution and replayable events make failure handling a core system property rather than an exception path.

---

## 18. Scaling Architecture

Scaling occurs at four layers.

### Frontend
**Platform:** Vercel autoscaling

### Events
**Platform:** Inngest durable execution

### Workers
**Properties:** stateless, horizontally scalable

### Database
**Platform:** Supabase PostgreSQL

The design supports separate scaling strategies for the UI, orchestration, workers, and persistence layers.

---

## 19. Deployment Architecture

```text
Vercel
  ↓
Next.js
  ↓
Inngest
  ↓
Sanity
  ↓
AI Workers
  ↓
Supabase
```

This deployment model keeps the UI, orchestration, registry, and persistence layers loosely coupled.

---

## 20. Alternatives Considered

### Direct Service Coupling
Rejected because it creates brittle integrations and makes extensibility harder.

### Hardcoded AI Provider Integration
Rejected because it locks the platform into specific vendors and reduces portability.

### Synchronous End-to-End Execution
Rejected because long-running workflows need retries, replay, and failure isolation.

### Monolithic LMS Design
Rejected because the long-term direction depends on dynamic workflows and plugin participation.

---

## 21. Risks and Trade-Offs

### Complexity
The architecture is more complex than a traditional CRUD application, but that complexity buys extensibility and operational control.

### Operational Overhead
The system requires disciplined logging, tracing, and registry management.

### AI Reliability
AI outputs may vary in quality, so validation and structured schemas are essential.

### Multi-Tenancy Mistakes
Any missing `tenant_id` enforcement could cause isolation failures.

### Registry Drift
Plugin metadata may become stale if registry state and worker reality diverge.

---

## 22. Open Questions

- How should worker compatibility be handled across versions?
- Should plugin execution support ordered fan-out or only single-worker resolution?
- What validation guarantees are required before AI results are persisted?
- How should failed worker retries be surfaced to users?
- Which events should be replayable by administrators versus internal operators only?

---

## 23. Implementation Notes

The initial implementation should prioritize:

- event emission from core LMS actions,
- registry-based worker discovery,
- durable worker execution,
- AI output validation,
- tenant-aware persistence,
- and basic operational tracing.

This keeps the first release aligned with the architecture while avoiding unnecessary overengineering.

---

## 24. Decision Summary

Nexus LMS is built as an event-driven, plugin-oriented execution platform rather than a conventional LMS. The design intentionally separates orchestration, registry, AI execution, and persistence so the system can evolve as educational workflows and AI capabilities change.

The result is a platform that behaves like an LMS on the surface, but underneath operates as a durable workflow engine with AI workers and plugin-based extensibility.

---

## 25. Approval

| Role             | Status  |
| ---------------- | ------- |
| Product Owner    | Pending |
| System Architect | Pending |
| Engineering Lead | Pending |
| AI Platform Lead | Pending |
| Security Lead    | Pending |
