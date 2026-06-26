# PART 4 — Supabase Data Modeling & Multi-Tenant Architecture

# Tutorial 04: Designing the LMS Data Layer

---

# Introduction

At this point, Nexus LMS has:

* a working frontend (Next.js App Router)
* an event system (Inngest)
* a worker concept (Sanity registry)
* a clean monorepo structure

Now we design the **system of record**.

> If events are the nervous system, the database is the memory.

In this tutorial, we build a production-grade **multi-tenant LMS schema using Supabase + PostgreSQL + RLS**.

---

# Learning Objectives

By the end of this tutorial, you will understand:

* How to design a multi-tenant LMS schema
* How Supabase enforces security using Row Level Security (RLS)
* How to model courses, lessons, assignments, and submissions
* How to persist events and worker outputs
* How to structure AI-generated artifacts safely
* How to prepare the database for event-driven workflows

---

# 1. The Core Principle: Multi-Tenancy First

Nexus LMS is built for:

* schools
* institutions
* organizations
* cohorts

So every record must belong to an **organization boundary**.

---

## Base Rule

Every table must include:

```text id="t1"
organization_id
```

This is non-negotiable.

---

## Why this matters

Without strict tenancy isolation:

* data leaks between schools
* AI workers mix student data
* analytics become unreliable
* compliance becomes impossible

---

# 2. Supabase Architecture Overview

We use Supabase as:

* primary database
* authorization boundary (via RLS)
* event persistence layer
* worker result store

---

# 3. Core Schema Design

---

## 3.1 Organizations

```sql id="s1"
create table organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamp default now()
);
```

---

## 3.2 Users

```sql id="s2"
create table users (
  id uuid primary key default gen_random_uuid(),
  clerk_id text unique not null,
  organization_id uuid references organizations(id),
  role text check (role in ('student','teacher','admin')),
  created_at timestamp default now()
);
```

---

## 3.3 Courses

```sql id="s3"
create table courses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id),
  title text not null,
  description text,
  created_by uuid references users(id),
  created_at timestamp default now()
);
```

---

## 3.4 Lessons

```sql id="s4"
create table lessons (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses(id),
  title text,
  content text,
  order_index int,
  created_at timestamp default now()
);
```

---

## 3.5 Assignments

```sql id="s5"
create table assignments (
  id uuid primary key default gen_random_uuid(),
  course_id uuid references courses(id),
  lesson_id uuid references lessons(id),
  title text,
  description text,
  due_date timestamp,
  created_at timestamp default now()
);
```

---

## 3.6 Submissions

```sql id="s6"
create table submissions (
  id uuid primary key default gen_random_uuid(),
  assignment_id uuid references assignments(id),
  student_id uuid references users(id),
  content text,
  status text check (status in ('draft','submitted','graded')),
  created_at timestamp default now()
);
```

---

# 4. Event Persistence Table

Every event becomes traceable.

```sql id="s7"
create table events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  name text not null,
  payload jsonb not null,
  created_at timestamp default now()
);
```

---

## Why store events?

Because:

* debugging AI workflows requires traceability
* workers may fail and retry
* analytics depend on event history
* audit logs are mandatory in education systems

---

# 5. Worker Execution Results

This is where AI outputs are stored.

```sql id="s8"
create table worker_results (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  worker_id text not null,
  event_name text not null,
  input jsonb,
  output jsonb,
  status text check (status in ('success','failed')),
  created_at timestamp default now()
);
```

---

## Example outputs stored here:

* quiz generation
* grading results
* summaries
* tutor feedback
* analytics insights

---

# 6. AI Artifact Tables (Optional Expansion Layer)

To avoid mixing raw AI output with system data, we normalize artifacts.

---

## 6.1 Lesson Summaries

```sql id="s9"
create table lesson_summaries (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid,
  summary text,
  key_points jsonb,
  created_at timestamp default now()
);
```

---

## 6.2 Generated Quizzes

```sql id="s10"
create table quizzes (
  id uuid primary key default gen_random_uuid(),
  lesson_id uuid,
  title text,
  questions jsonb,
  created_at timestamp default now()
);
```

---

# 7. Row Level Security (RLS)

This is critical for production safety.

---

## Enable RLS

```sql id="r1"
alter table courses enable row level security;
alter table lessons enable row level security;
alter table assignments enable row level security;
alter table submissions enable row level security;
```

---

## Example Policy: Courses

```sql id="r2"
create policy "org isolation"
on courses
for select
using (
  organization_id = auth.jwt() ->> 'org_id'
);
```

---

## Example Policy: Submissions

```sql id="r3"
create policy "students can view own submissions"
on submissions
for select
using (
  student_id = auth.uid()
);
```

---

# 8. Event → Database Flow

Every LMS action follows this pipeline:

```text id="f1"
UI Action
   ↓
Supabase Write
   ↓
Event Emitted
   ↓
Inngest Workflow
   ↓
Worker Execution
   ↓
worker_results Insert
```

---

## Example: Assignment Submission

### Step 1

```sql id="f2"
insert into submissions (...)
```

---

### Step 2

```typescript id="f3"
emit("assignment.submitted")
```

---

### Step 3

Workers:

* Markly grades
* Quiz generator creates practice questions
* Tutor AI generates feedback
* Analytics updates dashboards

---

### Step 4

Outputs stored in:

```text id="f4"
worker_results
```

---

# 9. Data Ownership Rules

Each system owns specific data:

| System   | Ownership          |
| -------- | ------------------ |
| Supabase | persistent state   |
| Inngest  | execution flow     |
| Sanity   | worker registry    |
| Workers  | derived AI outputs |
| Next.js  | UI state only      |

---

# 10. Critical Design Insight

Most LMS systems fail because they mix:

* raw data
* derived AI data
* workflow state
* UI state

Nexus LMS separates them cleanly:

```text id="c1"
Raw Data → Supabase
Derived AI → Workers
Workflow → Inngest
Registry → Sanity
UI → Next.js
```

---

# 11. Why This Architecture Works

## 11.1 Safe multi-tenancy

Every table is scoped by organization.

---

## 11.2 AI output isolation

AI results never overwrite core data.

---

## 11.3 Full traceability

Every event and worker output is stored.

---

## 11.4 Rebuildable system state

You can reconstruct:

* grades
* quizzes
* analytics

from events + worker results.

---

## 11.5 AI is non-destructive

Workers never mutate core LMS data directly.

They produce **artifacts**, not mutations.

---

# 12. Key Architectural Principle

> Supabase is the source of truth.
>
> AI is the source of interpretation.

---

# Summary

In this tutorial, we built the full data foundation of Nexus LMS:

* multi-tenant database design
* LMS core tables (courses, lessons, assignments)
* submission lifecycle modeling
* event persistence layer
* worker output storage
* AI artifact tables
* Row Level Security policies
* strict data ownership boundaries

We now have a **production-grade LMS database architecture**.

---

# Next Tutorial

## Tutorial 05 — Inngest Workflow Engine & Event Orchestration Layer

We will now design:

* event ingestion system
* durable workflows
* fan-out/fan-in execution
* retry and failure handling
* worker orchestration engine
* event-to-worker mapping system
* production-grade AI workflow execution pipeline
