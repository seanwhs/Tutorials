# PART 1 — System Architecture

# Tutorial 01: Designing the Nexus LMS System Architecture

---

# Introduction

In Part 0, we defined the philosophy:

> Nexus LMS is not an application. It is an orchestration system for educational events and AI workers.

Now we translate that philosophy into a **production-grade system architecture** using:

* Next.js (App Router)
* Supabase (PostgreSQL + RLS)
* Clerk (Auth + orgs)
* Inngest (event orchestration)
* Sanity (worker registry)

This tutorial defines how all components interact in a real system.

---

# Learning Objectives

By the end of this tutorial, you will understand:

* The bounded contexts of Nexus LMS
* How services are separated (without over-microservicing)
* How events flow through the system
* How workers are discovered and executed
* Where each technology fits in the architecture
* The runtime lifecycle of an AI-driven LMS event

---

# 1. High-Level Architecture

Nexus LMS is structured as four layers:

```text id="arch1"
┌──────────────────────────────┐
│        Presentation Layer     │
│     (Next.js App Router)      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│        Domain Layer           │
│   Courses / Assignments      │
│   Users / Learning Flow      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│      Event & Workflow Layer   │
│          (Inngest)            │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│     Intelligence Layer        │
│  (Sanity Worker Registry)     │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│     Execution Layer           │
│   AI Workers / External APIs  │
└──────────────────────────────┘
```

Each layer is independent and replaceable.

---

# 2. Bounded Contexts (Domain Design)

We divide the LMS into clear domains.

---

## 2.1 Identity Context

Handled by Clerk

Responsibilities:

* authentication
* sessions
* organizations
* roles

No LMS logic belongs here.

---

## 2.2 Learning Context

Stored in Supabase

Includes:

* courses
* modules
* lessons
* enrollment
* progress tracking

This is the **core academic data model**.

---

## 2.3 Assessment Context

* assignments
* submissions
* grading states
* rubrics
* feedback artifacts

This is where AI workers heavily interact.

---

## 2.4 Workflow Context

Powered by Inngest

Responsible for:

* event handling
* retries
* fan-out workflows
* durable execution

This is the **brain of orchestration**.

---

## 2.5 Intelligence Context

Powered by Sanity

Stores:

* AI workers
* tool definitions
* schemas
* execution metadata

This is NOT content management.

It is a **runtime registry for AI capabilities**.

---

# 3. System Components Breakdown

## 3.1 Next.js App (Frontend + BFF)

Responsibilities:

* UI rendering
* server actions
* API routes (lightweight)
* session handling (Clerk)
* event emission

It does NOT:

* run AI
* orchestrate workflows
* execute business logic

---

## 3.2 Supabase (System of Record)

Stores:

```text id="db1"
users
courses
lessons
assignments
submissions
progress
events
worker_results
```

Key principle:

> Supabase is the source of truth, not the orchestrator.

---

## 3.3 Inngest (Event Backbone)

Inngest handles:

* event ingestion
* retries
* async workflows
* fan-out execution
* background processing

Example event:

```typescript id="event1"
await inngest.send({
  name: "assignment.submitted",
  data: {
    submissionId,
    studentId,
    assignmentId
  }
});
```

---

## 3.4 Sanity (Worker Registry)

Stores:

* worker definitions
* event subscriptions
* input/output schemas
* enable/disable flags

Example worker:

```json id="worker1"
{
  "name": "Markly Grader",
  "enabled": true,
  "events": ["assignment.submitted"],
  "endpoint": "https://markly/api/run",
  "capabilities": ["grading"]
}
```

---

## 3.5 AI Workers (Execution Layer)

Examples:

* grading AI (Markly)
* quiz generator
* tutor assistant
* analytics engine
* recommendation system

Each worker:

* is independent
* is stateless
* obeys contract
* can be replaced

---

# 4. Event Flow Architecture

Let’s walk through a real scenario.

## Scenario: Student submits assignment

---

### Step 1 — Event is emitted

```typescript id="flow1"
emit("assignment.submitted", {
  submissionId,
  studentId,
  assignmentId
});
```

---

### Step 2 — Inngest captures event

Inngest triggers workflow function.

---

### Step 3 — Worker discovery

System queries Sanity:

```text id="flow2"
Find workers subscribed to:
assignment.submitted
```

Returns:

* Markly (grading)
* Plagiarism detector
* Analytics engine
* Tutor AI

---

### Step 4 — Execution fan-out

```text id="flow3"
assignment.submitted
      |
      +--> Markly
      +--> Plagiarism AI
      +--> Analytics AI
      +--> Tutor AI
```

---

### Step 5 — Results stored

Each worker writes:

```text id="flow4"
worker_results table
```

or emits follow-up events:

```text id="flow5"
grading.completed
tutor.feedback.generated
```

---

# 5. Worker Lifecycle Model

Every worker follows a strict lifecycle:

---

## 5.1 Registration

Stored in Sanity.

---

## 5.2 Discovery

Queried dynamically:

```typescript id="w1"
registry.findWorkers(eventName);
```

---

## 5.3 Execution

Executed via HTTP or SDK:

```typescript id="w2"
await fetch(worker.endpoint, {
  method: "POST",
  body: payload
});
```

---

## 5.4 Validation

System validates:

* input schema
* output schema
* timeout constraints

---

## 5.5 Persistence

Results stored in Supabase:

* audit logs
* learning artifacts
* analytics data

---

## 5.6 Optional chaining

Workers may emit new events.

Example:

```text id="w3"
Markly → grading.completed
```

---

# 6. Data Flow Architecture

## Write path:

```text id="df1"
Next.js → Supabase → Event emitted → Inngest → Workers → Supabase
```

## Read path:

```text id="df2"
Next.js → Supabase → UI rendering
```

---

# 7. Why This Architecture Works

## 7.1 No hardcoded AI logic

The LMS does NOT know:

* which AI tools exist
* which models are used
* how grading works

---

## 7.2 Fully extensible system

New capability = new worker

No LMS code change required.

---

## 7.3 AI becomes interchangeable

You can swap:

* GPT → Claude → local model
* Markly v1 → v2 → competitor

without touching LMS core.

---

## 7.4 Independent scaling

Each worker scales independently:

* grading can scale separately
* analytics can scale separately
* tutoring can scale separately

---

## 7.5 Failure isolation

If a worker fails:

* LMS continues working
* other workers continue executing

---

# 8. Architectural Summary

Nexus LMS is built on five pillars:

| Layer      | Responsibility           |
| ---------- | ------------------------ |
| Next.js    | UI + orchestration entry |
| Supabase   | System of record         |
| Inngest    | Event workflow engine    |
| Sanity     | Worker registry          |
| AI Workers | Execution layer          |

---

# 9. Core Insight

The most important idea in this architecture:

> The LMS does not implement features.
>
> It enables systems that implement features.

This is the shift from:

* application → platform
* functions → workflows
* features → capabilities
* logic → orchestration

---

# Next Tutorial

## Tutorial 02 — Monorepo Structure & Project Setup

We will now move into implementation:

* full monorepo structure
* Next.js App Router setup
* shared event contracts package
* worker SDK design
* registry client (Sanity SDK layer)
* Supabase schema bootstrap
* Inngest initialization

And start turning architecture into production code.
