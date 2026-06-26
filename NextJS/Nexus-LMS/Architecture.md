# Nexus LMS — System Architecture RFC

**Document Type:** RFC / Architecture Design Doc  
**Status:** Draft  
**Version:** 1.0  
**Primary Author:** sean wong  
**Audience:** Engineering, product, AI/workflow contributors, platform maintainers  
**Last Updated:** 2026-06-27  

## 1. Executive Summary

Nexus LMS is an AI-native, event-driven, plugin-oriented Learning Management System designed to orchestrate educational workflows through events instead of direct service coupling. The platform is built to support extensible AI workers, durable execution, multi-tenant isolation, and end-to-end observability [web:24][web:33].

The core design choice is to treat integrations as dynamically discovered plugins rather than hardcoded dependencies. This allows new capabilities such as grading, feedback generation, quiz generation, analytics, and tutoring to be added through configuration and registry updates rather than core application changes.

## 2. Problem Statement

Traditional LMS architectures tend to couple business workflows directly to specific services, providers, and application code paths. That makes them harder to extend, harder to observe, and harder to evolve as AI capabilities change. Nexus LMS is intended to solve that by making events the primary coordination mechanism and plugins the primary extension mechanism.

The system must also support long-running AI and workflow operations reliably. That means retries, replay, isolation, and traceability are not optional implementation details; they are architectural requirements.

## 3. Goals

- Support educational workflows through an event-first architecture.
- Allow AI workers and external tools to register dynamically through a plugin registry.
- Enable durable, retryable, resumable, and replayable execution.
- Enforce multi-tenant isolation across all persisted entities.
- Provide first-class observability for events, worker execution, and AI activity.
- Keep the core application free from provider-specific coupling.

## 4. Non-Goals

- Building a monolithic LMS with hardcoded point-to-point integrations.
- Embedding AI logic directly into the application layer.
- Allowing AI workers to bypass security or data-access constraints.
- Supporting global shared state across tenants.
- Replacing all enterprise systems with a single generalized platform.
- Implementing synchronous, tightly coupled orchestration as the primary execution model.

## 5. Background and Motivation

Nexus LMS is designed for a world where educational systems increasingly depend on AI-assisted workflows, external services, and evolving automation patterns. In that environment, static integrations become fragile and expensive to maintain. A plugin-oriented architecture makes the system more adaptable because workers can be discovered and activated at runtime.

The platform also reflects a practical reality: AI-generated outputs are probabilistic, not deterministic. That makes validation, auditability, and durable execution critical to production use. The system therefore treats AI as a worker in a workflow, not as privileged application logic.

## 6. Design Overview

The system is organized as a layered execution platform:

Users  
→ Next.js Frontend  
→ Application API Layer  
→ Inngest Event Engine  
→ Sanity Plugin Registry  
→ Worker Execution Layer  
→ AI Layer  
→ Supabase PostgreSQL

This separation keeps presentation, orchestration, discovery, execution, and persistence decoupled while preserving a clear execution path for every workflow.

## 7. Proposed Architecture

### 7.1 Presentation Layer

**Technology:** Next.js App Router  
**Location:** `apps/web`  
**Responsibilities:** UI rendering, server actions, dashboards, API routes

The presentation layer provides the user-facing interface and application entry points. It uses the Next.js App Router model to structure application routes and server-side interactions [web:1][web:3].

### 7.2 Authentication Layer

**Technology:** Clerk  
**Responsibilities:** login, session management, identity management, JWT issuance

Authentication is handled separately from business logic so that identity and access concerns remain consistent across the application. Clerk provides the user session and authenticated request foundation used by the rest of the system [web:12][web:18].

### 7.3 Event Layer

**Technology:** Inngest  
**Responsibilities:** event dispatching, retries, orchestration, scheduling, replay

Inngest is the system’s orchestration backbone. It handles event-driven execution and durable workflows so that long-running operations can be retried, resumed, and replayed safely [web:2].

### 7.4 Registry Layer

**Technology:** Sanity  
**Responsibilities:** plugin discovery, worker registration, version management, feature flags

The registry acts as service discovery for the platform. Instead of baking worker knowledge into the core application, the system resolves eligible plugins from the registry at runtime.

### 7.5 Worker Layer

**Responsibilities:** AI grading, feedback generation, lesson summarization, quiz generation, analytics

Workers are stateless, isolated, and versioned. They receive structured input, perform a bounded unit of work, and return structured output.

### 7.6 AI Layer

**Responsibilities:** model routing, prompt management, validation, provider abstraction  
**Supported providers:** OpenAI, Claude, future models

The AI layer standardizes access to model providers and enforces validation before results are accepted into system state. This ensures AI remains a controlled execution step rather than an uncontrolled integration surface.

### 7.7 Persistence Layer

**Technology:** Supabase PostgreSQL  
**Responsibilities:** storage, security, auditing, observability

The persistence layer stores application data, event traces, worker logs, and AI audit logs. Supabase Row Level Security supports tenant-scoped access control at the database layer [web:13][web:15].

## 8. Core Principles

### 8.1 Event First

Business operations never directly invoke downstream services. Instead, actions emit events, which then trigger worker discovery and execution.

### 8.2 Plugins over Integrations

The LMS core does not know about specific providers such as OpenAI, Claude, analytics engines, or quiz generators. Those capabilities are expressed as plugins.

### 8.3 Configuration over Code

New behavior is introduced by registering and enabling plugins, not by modifying the core application.

### 8.4 AI as a Worker

AI systems are participants in workflows, not the workflow engine itself. They produce structured outputs under validation and orchestration control.

### 8.5 Durable Execution

All long-running work must be retryable, resumable, replayable, and observable.

### 8.6 Multi-Tenant by Default

Every business entity is scoped by `tenant_id`. No global state is allowed.

### 8.7 Observability First

Every operation must be logged, traceable, replayable, and debuggable.

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

This structure separates the product app, shared packages, infra definitions, and documentation into clear boundaries.

## 10. Event Model

Every workflow begins with an event.

### Event Examples

- `course.created`
- `lesson.published`
- `assignment.created`
- `assignment.submitted`
- `grading.completed`
- `feedback.generated`
- `analytics.completed`

### Event Structure

```json
{
  "id": "uuid",
  "name": "assignment.submitted",
  "tenantId": "tenant",
  "timestamp": "ISO8601",
  "data": {}
}
```

Events are immutable records and should be preserved for replay, audit, and recovery.

## 11. Plugin Registry Design

The plugin registry is implemented in Sanity. It stores worker definitions, capabilities, activation rules, and version metadata.

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

Event  
↓  
Sanity Query  
↓  
Resolve Workers  
↓  
Sort by Priority  
↓  
Execute Workers

This design allows the system to discover eligible workers dynamically without hardcoded service references.

## 12. AI Execution Pipeline

AI execution follows a strict pipeline:

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

This pipeline ensures that outputs are structured, checked, and auditable before they are committed to the system.

### Supported AI Tasks

- Grading.
- Feedback generation.
- Summarization.
- Quiz generation.
- Tutoring.
- Analytics.

## 13. Data Model

### Core Tables

- `users`
- `courses`
- `lessons`
- `assignments`
- `submissions`
- `grades`
- `plugins`
- `event_traces`
- `worker_logs`
- `ai_audit_logs`

### Multi-Tenant Model

Every table contains `tenant_id` for tenant isolation.

```text
tenant_1
├── courses
├── lessons
└── submissions
```

This ensures that all data access and operational logic remain tenant aware.

## 14. Security Model

Security is enforced in five layers.

### Authentication
**Provider:** Clerk

### Authorization
**Provider:** Supabase RLS

### Event Security
Events are immutable, append-only, and replayable.

### Plugin Security
Plugins must pass schema validation, endpoint validation, and timeout enforcement.

### AI Security
AI systems cannot modify the database, cannot emit events, and cannot execute code. They only return structured outputs.

This keeps AI output useful while preventing it from becoming a privileged execution surface.

## 15. Observability Model

Observability is built around three telemetry systems.

### Event Tracing
**Table:** `event_traces`  
Captures event names, payloads, timestamps, and trace context.

### Worker Tracing
**Table:** `worker_logs`  
Captures worker execution details, latency, and failures.

### AI Auditing
**Table:** `ai_audit_logs`  
Captures prompts, responses, model versions, and validation results.

Together these logs provide a complete history of system behavior across orchestration, workers, and AI calls.

## 16. Failure Model

Nexus LMS assumes failures are normal.

### Failure Domains

- Event failures.
- Worker failures.
- AI failures.
- Database failures.
- Plugin failures.

### Recovery Flow

Failure  
↓  
Isolation  
↓  
Logging  
↓  
Retry  
↓  
Recovery

Durable execution and replayable events make recovery a normal part of system behavior rather than a special case.

## 17. Scaling and Deployment

### Scaling Strategy

- **Frontend:** Vercel autoscaling.
- **Events:** Inngest durable execution.
- **Workers:** stateless horizontal scaling.
- **Database:** Supabase PostgreSQL.

### Deployment Flow

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

Each layer scales independently according to its own constraints and workload profile.

## 18. Alternatives Considered

### Direct Service Coupling
This was rejected because it creates brittle integrations, makes extensibility harder, and increases the cost of adding new workflow participants.

### Hardcoded AI Provider Integration
This was rejected because it would lock the platform into specific AI vendors and reduce portability.

### Synchronous End-to-End Execution
This was rejected because long-running educational workflows require retries, replay, and failure isolation.

### Monolithic LMS Design
This was rejected because the system’s long-term direction depends on dynamic workflows and plugin participation, not static application wiring.

## 19. Risks and Trade-Offs

### Complexity
A plugin-oriented event architecture is more complex than a traditional CRUD application. That complexity is justified by extensibility and workflow flexibility.

### Operational Overhead
The system requires careful logging, tracing, and registry management to remain debuggable.

### AI Reliability
AI outputs may vary in quality, so validation and structured schemas are essential.

### Multi-Tenancy Mistakes
Any missing `tenant_id` enforcement could cause isolation failures, so tenant scoping must be enforced consistently across app and database layers.

### Registry Drift
Plugin metadata may become stale if registry state and worker reality diverge. Versioning and validation reduce this risk.

## 20. Open Questions

- How should worker compatibility be handled across versions?
- Should plugin execution support ordered fan-out or only single-worker resolution?
- What validation guarantees are required before AI results are persisted?
- How should failed worker retries be surfaced to users?
- Which events should be replayable by administrators versus internal operators only?

## 21. Implementation Notes

The initial implementation should prioritize:

- event emission from core LMS actions,
- registry-based worker discovery,
- durable worker execution,
- AI output validation,
- tenant-aware persistence,
- and basic operational tracing.

This keeps the first release aligned with the architectural intent without overcommitting to premature optimization.

## 22. Decision Summary

Nexus LMS is built as an event-driven, plugin-oriented execution platform rather than a conventional LMS. The design intentionally separates orchestration, registry, AI execution, and persistence so the system can evolve as educational workflows and AI capabilities change.

The result is a platform that behaves like an LMS on the surface, but underneath operates as a durable workflow engine with AI workers and plugin-based extensibility.
