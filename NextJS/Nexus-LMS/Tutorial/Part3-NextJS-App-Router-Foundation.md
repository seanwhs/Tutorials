# PART 3 — Next.js App Router Foundation

# Tutorial 03: Building the LMS Frontend Core

---

# Introduction

Now that the monorepo structure is in place, we move to the first executable system:

> The LMS frontend built with Next.js App Router.

This is not just a UI layer.

In Nexus LMS, the frontend is also:

* an event emitter
* a workflow initiator
* a domain gateway
* a thin orchestration entry point

But it must stay **deliberately thin**.

We do NOT want AI logic, business logic, or workflow logic in the UI.

---

# Learning Objectives

By the end of this tutorial, you will understand:

* How to structure a production Next.js App Router LMS
* How to separate UI from domain logic
* How server actions fit into the architecture
* How authentication works with Clerk
* How LMS events are emitted from the frontend
* How to connect frontend → Supabase → Inngest cleanly
* How to avoid frontend over-coupling

---

# 1. Frontend Role in Nexus LMS

The frontend is NOT:

* a business logic layer
* an AI orchestration layer
* a workflow engine

It IS:

> A controlled entry point into the LMS system

```text id="ui1"
User Action
    ↓
Next.js UI
    ↓
Server Action
    ↓
Supabase write
    ↓
Event emission (Inngest)
```

---

# 2. App Router Structure

We structure the LMS frontend like this:

```text id="app1"
apps/web/

app/
  (marketing)/
  (auth)/
  (dashboard)/
  (course)/
  (assignment)/
  layout.tsx
  page.tsx

components/
  ui/
  course/
  assignment/

lib/
  lms/
  supabase/
  clerk/
  events/

actions/
  courses.ts
  assignments.ts
  enrollments.ts
```

---

# 3. Route Groups Strategy

We use Next.js route groups:

Powered by Next.js

---

## 3.1 (auth)

Handles:

* login
* signup
* session bootstrapping

---

## 3.2 (dashboard)

Main LMS shell:

* course overview
* assignments
* progress tracking
* AI-generated insights (display only)

---

## 3.3 (course)

Course view:

* modules
* lessons
* completion tracking

---

## 3.4 (assignment)

Assignment lifecycle:

* view
* submit
* review results
* AI feedback display

---

# 4. Server Actions as Domain Gateways

We avoid traditional REST-heavy design.

Instead we use server actions as **controlled domain gateways**.

---

## Example: Assignment Submission

```typescript id="a1"
"use server";

import { emitEvent } from "@/lib/events";
import { createSubmission } from "@/lib/lms/assignments";

export async function submitAssignment(input: {
  assignmentId: string;
  content: string;
  studentId: string;
}) {
  const submission = await createSubmission(input);

  await emitEvent({
    name: "assignment.submitted",
    data: {
      submissionId: submission.id,
      assignmentId: input.assignmentId,
      studentId: input.studentId
    }
  });

  return submission;
}
```

---

# 5. Event Emission Layer

We isolate event logic.

```typescript id="e1"
import { inngest } from "@/lib/inngest";

export async function emitEvent(event: any) {
  await inngest.send({
    name: event.name,
    data: event.data
  });
}
```

Powered by Inngest

---

# 6. Supabase Data Layer

We isolate DB access into `lib/lms`.

Powered by Supabase

---

## Example: Create Submission

```typescript id="db1"
import { supabase } from "@/lib/supabase";

export async function createSubmission(data: {
  assignmentId: string;
  content: string;
  studentId: string;
}) {
  const { data: submission, error } = await supabase
    .from("submissions")
    .insert({
      assignment_id: data.assignmentId,
      content: data.content,
      student_id: data.studentId,
      status: "submitted"
    })
    .select()
    .single();

  if (error) throw error;

  return submission;
}
```

---

# 7. Authentication Layer

We use Clerk

---

## Middleware Protection

```typescript id="auth1"
import { clerkMiddleware } from "@clerk/nextjs/server";

export default clerkMiddleware();

export const config = {
  matcher: ["/dashboard/:path*", "/course/:path*", "/assignment/:path*"]
};
```

---

# 8. LMS Dashboard Architecture

The dashboard is NOT a monolith page.

It is a composition of domain views:

```text id="dash1"
Dashboard
  ├── CourseList
  ├── AssignmentList
  ├── ProgressTracker
  ├── AIInsightsPanel
  └── Notifications
```

Important rule:

> AI insights are DISPLAYED, not computed in UI.

---

# 9. Course Page Flow

```text id="course1"
User opens course
      ↓
Fetch course data (Supabase)
      ↓
Render modules + lessons
      ↓
User clicks lesson
      ↓
Lesson completion event emitted
```

---

## Lesson Completion Example

```typescript id="lesson1"
"use server";

import { emitEvent } from "@/lib/events";

export async function completeLesson(input: {
  lessonId: string;
  studentId: string;
}) {
  await emitEvent({
    name: "lesson.completed",
    data: input
  });
}
```

---

# 10. Assignment Page Flow

```text id="assign1"
Open assignment
     ↓
Submit solution
     ↓
Server action
     ↓
Supabase insert
     ↓
Emit event
     ↓
AI workers triggered (Markly, Quiz, Tutor, etc.)
```

---

# 11. Frontend Rule: No AI Logic

This is critical:

## ❌ WRONG

```typescript id="badai"
const result = await openai.chat.completions.create(...)
```

## ❌ WRONG

```typescript id="badai2"
if (assignment) runMarkly();
```

## ✅ CORRECT

```typescript id="goodai"
emitEvent("assignment.submitted");
```

---

# 12. Data Flow Summary

## Write flow:

```text id="flow1"
UI → Server Action → Supabase → Event → Inngest → Workers
```

## Read flow:

```text id="flow2"
UI → Supabase → Render
```

---

# 13. Why This Design Works

## 13.1 UI stays deterministic

No AI variability inside frontend.

---

## 13.2 AI is fully decoupled

Workers evolve independently.

---

## 13.3 Events become the contract

Frontend only knows:

> “something happened”

not “what happens next”

---

## 13.4 System is scalable by default

Each layer scales independently:

* UI scaling (CDN)
* DB scaling (Supabase)
* workflow scaling (Inngest)
* AI scaling (workers)

---

# 14. Key Architectural Principle

> The frontend never makes educational decisions.

It only:

* captures intent
* writes state
* emits events

Everything else is downstream.

---

# Summary

In this tutorial, we built the LMS frontend foundation:

* Next.js App Router structure
* domain-based routing groups
* server actions as controlled gateways
* Supabase data layer isolation
* Inngest event emission system
* Clerk authentication integration
* strict separation of UI and AI logic

We now have a **clean, production-grade LMS frontend core**.

---

# Next Tutorial

## Tutorial 04 — Supabase Data Modeling & Multi-Tenant LMS Schema

We will now design:

* full PostgreSQL schema
* multi-tenant architecture
* RLS security model
* course/assignment/submission modeling
* event persistence tables
* worker results storage
* analytics foundation

This is where Nexus LMS becomes a real data system.
