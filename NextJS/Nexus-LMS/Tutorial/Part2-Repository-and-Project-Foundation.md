# PART 2 — Repository & Project Foundation

# Tutorial 02: Monorepo Structure for Nexus LMS

---

# Introduction

Now that we have the architecture defined, we need to make one critical engineering decision:

> How do we structure the codebase so that Nexus LMS stays scalable, extensible, and worker-friendly?

Most LMS systems fail here because they evolve into a tangled backend + frontend monolith with hidden coupling between:

* UI logic
* business logic
* AI integrations
* workflow orchestration

Nexus LMS avoids this by adopting a **strict monorepo + domain-packaged architecture**.

---

# Learning Objectives

By the end of this tutorial, you will understand:

* How to structure a production-grade LMS monorepo
* How to separate domains cleanly without microservice overkill
* How to design shared contracts for events and workers
* How to isolate AI workers from core LMS logic
* How to prepare for Inngest + Sanity integration
* How to enforce long-term maintainability

---

# 1. Why a Monorepo?

Nexus LMS is not a single application.

It is a **platform composed of multiple systems**:

* LMS Core (Next.js)
* Event Contracts
* Worker SDK
* Registry Client
* Shared UI
* External AI Workers

If these live in separate repositories, you get:

* version mismatch
* contract drift
* integration friction
* deployment complexity

So we unify them:

```text id="mono1"
nexus-lms/
```

But with strict boundaries.

---

# 2. Final Monorepo Structure

This is the target structure:

```text id="mono2"
nexus-lms/

apps/
  web/                      # Next.js LMS application

packages/
  ui/                       # Shared UI components
  types/                   # Shared TypeScript types
  events/                  # Event contracts (VERY IMPORTANT)
  sdk/                     # LMS client SDK
  workers/                 # Worker SDK (for external AI tools)
  registry/                # Sanity registry client

infra/
  supabase/                # DB schema + migrations
  inngest/                 # event functions/workflows
  sanity/                  # worker registry schemas

docs/
  architecture/
  tutorials/
```

---

# 3. Architectural Boundaries

## 3.1 apps/web (Next.js LMS Core)

Powered by Next.js

Responsibilities:

* UI rendering
* server actions
* authentication (via Clerk)
* event emission
* data fetching from Supabase

Does NOT:

* run AI logic
* define workflows
* contain worker logic

---

## 3.2 packages/events (The Most Important Package)

This is the **heart of the system**.

It defines:

* all LMS events
* event schemas
* type safety across system

Example:

```typescript id="evt1"
export type LMS_Event =
  | {
      name: "assignment.submitted";
      data: {
        submissionId: string;
        studentId: string;
        assignmentId: string;
      };
    }
  | {
      name: "lesson.completed";
      data: {
        lessonId: string;
        studentId: string;
      };
    };
```

Why this matters:

> Every system component depends on events—not functions.

---

## 3.3 packages/types

Shared domain models:

```typescript id="types1"
export interface User {
  id: string;
  role: "student" | "teacher" | "admin";
}

export interface Course {
  id: string;
  title: string;
}
```

This prevents duplication across:

* frontend
* workers
* workflows

---

## 3.4 packages/sdk (LMS Client SDK)

This is what frontend uses.

Instead of calling Supabase directly everywhere:

```typescript id="bad1"
supabase.from("assignments")
```

We standardize:

```typescript id="good1"
lms.assignments.get(id);
```

SDK responsibilities:

* API abstraction
* authentication handling
* typed responses
* event emission helper

---

## 3.5 packages/registry (Sanity Client Layer)

This package talks to Sanity

Responsibilities:

* fetch workers
* validate worker schemas
* filter by event type
* manage enable/disable state

Example:

```typescript id="reg1"
export async function findWorkers(event: string) {
  return sanity.fetch(`
    *[_type == "worker" && "${event}" in events && enabled == true]
  `);
}
```

---

## 3.6 packages/workers (Worker SDK)

This is critical for extensibility.

It defines how external AI systems integrate.

Example interface:

```typescript id="worker1"
export interface Worker {
  metadata(): {
    events: string[];
  };

  execute(input: any): Promise<any>;
}
```

Example implementation:

```typescript id="worker2"
export class QuizWorker implements Worker {
  metadata() {
    return {
      events: ["lesson.completed"]
    };
  }

  async execute(input: any) {
    return {
      questions: []
    };
  }
}
```

This allows:

* Python workers
* Node workers
* external APIs
* AI services

---

## 3.7 infra/supabase

Powered by Supabase

Contains:

* SQL schema
* migrations
* RLS policies
* seed data

Core tables:

```text id="db1"
users
courses
lessons
assignments
submissions
events
worker_results
```

---

## 3.8 infra/inngest

Powered by Inngest

Contains:

* event handlers
* workflows
* retries
* fan-out logic

Example:

```typescript id="ing1"
export const onAssignmentSubmitted = inngest.createFunction(
  { id: "assignment-submitted" },
  { event: "assignment.submitted" },
  async ({ event }) => {
    // orchestration logic
  }
);
```

---

## 3.9 infra/sanity

Worker registry schemas:

```typescript id="san1"
{
  name: "worker",
  fields: [
    { name: "name", type: "string" },
    { name: "events", type: "array" },
    { name: "endpoint", type: "url" },
    { name: "enabled", type: "boolean" }
  ]
}
```

---

# 4. Event-Driven Contract Flow

Everything depends on event contracts:

```text id="flow1"
apps/web
   |
   | emits event
   v

packages/events
   |
   v

infra/inngest
   |
   v

packages/registry
   |
   v

workers execution
   |
   v

supabase storage
```

---

# 5. Example End-to-End Flow

## Student submits assignment

### Step 1 — UI

```typescript id="e1"
lms.assignments.submit()
```

---

### Step 2 — Event emitted

```typescript id="e2"
emit("assignment.submitted")
```

---

### Step 3 — Inngest triggers workflow

---

### Step 4 — Registry lookup

```typescript id="e3"
registry.findWorkers("assignment.submitted");
```

Returns:

* Markly
* Quiz Generator
* Tutor AI
* Analytics Worker

---

### Step 5 — Workers execute

---

### Step 6 — Results stored

```text id="e4"
worker_results
```

---

# 6. Why This Structure Works

## 6.1 No hidden coupling

Everything depends on:

* events
* contracts
* registry

Not direct imports.

---

## 6.2 AI systems are isolated

Workers are external:

* can fail independently
* can scale independently
* can be replaced

---

## 6.3 LMS core stays stable

The LMS core never changes when:

* adding AI features
* swapping vendors
* introducing new models

---

## 6.4 Full extensibility

New capability =

> Add new worker + register in Sanity

No LMS rewrite required.

---

# 7. Key Design Rule

Nexus LMS enforces one strict rule:

> The LMS core never calls AI directly.

Instead:

```text id="rule1"
Event → Registry → Worker → Result
```

Not:

```text id="rule2"
LMS → AI Service
```

---

# 8. Summary

In this tutorial, we built the foundation of the Nexus LMS codebase:

* structured monorepo architecture
* strict domain separation
* event contract system
* worker SDK abstraction
* registry integration layer
* workflow orchestration separation

We now have a system that is:

* scalable
* AI-native
* plugin-driven
* event-based
* production-ready

---

# Next Tutorial

## Tutorial 03 — Next.js App Router Foundation

We will now build the actual LMS frontend:

* App Router structure
* server actions design
* authentication flow with Clerk
* LMS dashboard layout
* course/assignment UI architecture
* event emission layer from frontend
* Supabase integration patterns
