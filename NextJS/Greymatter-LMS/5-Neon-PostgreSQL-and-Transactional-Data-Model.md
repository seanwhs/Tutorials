# Part 5 — Neon PostgreSQL and the Transactional Data Model

## The goal

By the end of this part, GreyMatter LMS will have a real, cloud-hosted Neon PostgreSQL database, connected through Drizzle ORM, with a complete, versioned migration defining every transactional table from Part 0's plan: `users`, `enrollments`, `lesson_progress`, `module_attempts`, `course_progress`, `certificates`, `webhook_events`, `workflow_events`, and `audit_logs`. We'll build reusable query helpers and seed the database with a development user and a sample enrollment, so we have real rows to work against before authentication (Part 6) and enrollment logic (Part 8) arrive.

## Why it exists

Part 3 and Part 4 built the "textbook" half of GreyMatter. This part builds the "library card" half — the system of record for everything that's true about *one specific user*, at *one specific moment*, that must never be confused with any other user's data. Getting this schema right matters enormously: nearly every part from here to the end of the series — authentication, enrollment, progress tracking, certificates, analytics — reads from or writes to the tables we design in this part. A mistake here (a missing constraint, an ambiguous foreign key) doesn't stay contained; it resurfaces as a confusing bug five parts later.

## The data flow

```text
Next.js Server Action or Route Handler
        │
        ▼
Drizzle ORM (typed query builder)
        │
        ▼
Neon PostgreSQL (pooled connection over HTTPS)
        │
        ▼
Structured, constraint-enforced rows returned
```

Terms worth defining before we go further:

- **Relational database**: a database that stores data in tables (rows and columns) with explicit, enforced relationships between them — as opposed to a document store like Sanity, which stores loosely-structured trees. Think of a relational database like a well-organized spreadsheet workbook where certain columns in one sheet are *required* to match an ID that genuinely exists on another sheet — the software itself refuses to let you type in a mismatched reference.
- **Migration**: a versioned, ordered file describing a change to your database's structure (e.g., "create the `users` table," "add an index to `enrollments`"). Think of it as a construction permit history for a building — each permit describes exactly one modification, permits are applied in order, and anyone can look at the full stack of permits to understand how the building reached its current state.
- **Foreign key**: a column in one table that must reference an existing row's primary key in another table — the database-enforced version of the "does this room actually belong to this floor" check from Part 4, Step 9, except now enforced by the database itself rather than by query design alone.

---

## Step 1 — Creating a Neon project

### The Target
A real, free-tier Neon PostgreSQL project and database, with a connection string we'll use for the rest of the series.

### The Concept
Neon is "serverless Postgres" — a fully-managed PostgreSQL database that separates storage from compute and can scale down to near-zero when idle, which is why it's well suited to a project like ours that runs mostly on-demand (a handful of requests at a time) rather than under constant heavy load. For our purposes in this series, you can think of Neon simply as "PostgreSQL, hosted for you, with a web dashboard" — every SQL concept we use applies identically to any other PostgreSQL host.

### The Implementation

No code in this step. Visit **https://console.neon.tech**, sign up or sign in, and click "Create a project." Name it `greymatter-lms`. Neon will provision a default database (usually named `neondb`) inside a default branch (usually named `main`) — a **branch** in Neon is a full, isolated copy of your database schema and data, similar in spirit to a Git branch, which becomes relevant again in Part 16 when we discuss production branching.

Once created, find your connection string: in the Neon dashboard, go to your project's "Connection Details" panel and copy the connection string shown for the **pooled connection** (it will contain `-pooler` in the hostname). We use the pooled connection specifically because serverless environments like Next.js's server functions open and close many short-lived connections, and Neon's connection pooler is built to handle exactly that pattern efficiently, rather than exhausting Postgres's limited direct connection slots.

### The Verification

Confirm you can see your project, its `main` branch, and the `neondb` database listed in the Neon console, and that you've copied a connection string that looks like:

```text
postgresql://<user>:<password>@ep-xxxx-pooler.region.aws.neon.tech/neondb?sslmode=require
```

---

## Step 2 — Adding the connection string and installing Drizzle

### The Target
`DATABASE_URL` added to our environment files, and Drizzle ORM plus the Neon serverless driver installed.

### The Concept
Drizzle is our translator between "rows in a PostgreSQL table" and "typed JavaScript objects" — the ORM concept introduced in Part 0. We specifically use `@neondatabase/serverless`, a special HTTP/WebSocket-based Postgres driver built for exactly this kind of environment (Next.js server functions, edge runtimes) where a traditional long-lived TCP connection isn't always available or efficient.

### The Implementation

```bash
npm install drizzle-orm @neondatabase/serverless
npm install -D drizzle-kit
```

Update your environment files:

#### `.env.example` (update the Neon section)

```bash
# ── Neon / Drizzle (added in Part 5) ──────────────────────────────
DATABASE_URL=
```

Add your **real** pooled connection string to `.env.local`:

```bash
# .env.local
DATABASE_URL=postgresql://<user>:<password>@ep-xxxx-pooler.region.aws.neon.tech/neondb?sslmode=require
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors (nothing references these packages yet — we're just confirming installation didn't break anything).

---

## Step 3 — Designing the schema on paper, before code

### The Target
No code yet — a deliberate planning step, mirroring Part 3's Step 5, where we fix the exact table shapes and relationships in mind before writing Drizzle definitions.

### The Concept
Recall the plumber analogy from Part 3: reorganizing a live schema after real user data exists is far more painful than getting the shape right up front. This is doubly true for a relational database, because foreign keys and unique constraints actively *reject* data that doesn't fit the shape — a good thing once the shape is right, a source of confusing errors if it's designed carelessly.

### The full schema, and the reasoning behind every table

```text
users
├── id (internal primary key — used by every OTHER table below)
├── auth_provider_id (Clerk's external user ID — see Part 6)
├── email
├── role (STUDENT | INSTRUCTOR | ADMIN)
├── created_at, updated_at

enrollments
├── id
├── user_id → users.id
├── course_id (Sanity course document _id — a STRING, not a foreign key,
│    since Sanity is a separate system Postgres cannot enforce references into)
├── status (ACTIVE | COMPLETED | CANCELLED)
├── enrolled_at
├── UNIQUE (user_id, course_id) — prevents duplicate enrollment

lesson_progress
├── id
├── user_id → users.id
├── enrollment_id → enrollments.id
├── course_id (Sanity course _id, denormalized for query convenience)
├── lesson_id (Sanity lesson _id)
├── status (NOT_STARTED | IN_PROGRESS | COMPLETED)
├── completed_at
├── UNIQUE (user_id, lesson_id) — one progress row per user per lesson

module_attempts
├── id
├── user_id → users.id
├── lesson_id (Sanity lesson _id)
├── module_id (matches quizBlock/codeExerciseBlock's moduleId from Part 3)
├── attempt_number
├── submission (JSON — what the student submitted)
├── score (nullable — null until graded)
├── is_correct
├── submitted_at
├── UNIQUE (user_id, module_id, attempt_number) — supports multiple attempts safely

course_progress
├── id
├── user_id → users.id
├── enrollment_id → enrollments.id
├── course_id (Sanity course _id)
├── completion_percentage
├── last_activity_at
├── UNIQUE (user_id, course_id)

certificates
├── id
├── user_id → users.id
├── course_id (Sanity course _id)
├── certificate_number (unique, human-shareable identifier)
├── issued_at
├── UNIQUE (user_id, course_id) — prevents duplicate certificate issuance

webhook_events
├── id
├── source (e.g. "clerk")
├── event_type
├── external_id (the webhook provider's own event ID — for idempotency)
├── payload (JSON)
├── processed_at
├── UNIQUE (source, external_id) — prevents double-processing a retried webhook

workflow_events
├── id
├── event_name (e.g. "lesson/completed")
├── payload (JSON)
├── status (PENDING | PROCESSED | FAILED)
├── created_at, processed_at

audit_logs
├── id
├── user_id → users.id (nullable — some actions are system-initiated)
├── action (e.g. "enrollment.created")
├── metadata (JSON)
├── created_at
```

Three design decisions worth explaining **before** writing Drizzle code, exactly as Part 3 did for the content schema:

1. **`enrollments.course_id` and `lesson_progress.lesson_id` are plain strings, not foreign keys.** PostgreSQL cannot enforce a foreign key into Sanity, since Sanity is an entirely separate system with its own storage. This is a deliberate, permanent consequence of our hybrid architecture from Part 0 — and it's precisely *why* Part 4's Step 9 rule (always verify course/lesson relationships through a scoped query) and Part 8/Part 11's server-side verification exist: the database cannot do this verification for us the way it does for `user_id → users.id`, so our application code must.

2. **`module_attempts` is separate from `lesson_progress`**, exactly as Part 0 specified, because a single lesson can contain multiple interactive modules (recall Part 3's lesson schema, where `content` can include several `quizBlock`/`codeExerciseBlock` entries). `lesson_progress` answers "has this student finished this lesson," while `module_attempts` answers "what did this student submit for this specific quiz, and how many times."

3. **`UNIQUE` constraints appear on nearly every table** — this is not decoration. `UNIQUE (user_id, course_id)` on `enrollments` makes duplicate enrollment *structurally impossible*, not just "unlikely because our application code checks first." This distinction matters enormously once concurrent requests are possible (Part 8): application-level checks alone (`SELECT ... then INSERT`) have a real race-condition window; a database constraint closes that window completely, no matter how many requests arrive at the same instant.

### The Verification

No code to verify. Before proceeding, confirm you understand *why* `course_id`/`lesson_id` are strings rather than foreign keys, and *why* `module_attempts` and `lesson_progress` are separate tables — every remaining step in this part, and much of Part 8 and Part 11, depends on these two decisions.

---

## Step 4 — Configuring Drizzle

### The Target
`drizzle.config.ts` at the project root, and `db/client.ts` — the actual connection setup our schema and query files will import from.

### The Concept

`drizzle.config.ts` is metadata *for Drizzle's command-line tooling* (`drizzle-kit`) — it tells the migration generator where our schema files live, where to write generated SQL migration files, and how to connect to the real database when applying them. This is separate from `db/client.ts`, which is the runtime connection our actual *application code* uses while the server is running. Think of `drizzle.config.ts` as the blueprint office's address (used only when drafting or applying new construction plans) versus `db/client.ts` as the building's actual front door (used by everyone living there, every day).

### The Implementation

#### `drizzle.config.ts`

```ts
import { defineConfig } from "drizzle-kit";

// This file is only ever read by the `drizzle-kit` CLI (via the npm
// scripts we add in Step 8) — it is never imported by our running
// application. It needs its own copy of DATABASE_URL, which we read
// directly from process.env since drizzle-kit runs as a standalone
// script outside Next.js's usual env-loading machinery.
export default defineConfig({
  schema: "./db/schema/index.ts",
  out: "./db/migrations",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
  // Ensures every generated migration is verbose and readable —
  // useful while learning, since you can open any migration file and
  // immediately understand what it does without extra tooling.
  verbose: true,
  strict: true,
});
```

Since `drizzle.config.ts` reads `process.env.DATABASE_URL` directly (not through Next.js), we need a small tool to load `.env.local` when running CLI commands:

```bash
npm install -D dotenv-cli
```

#### `db/client.ts`

```ts
import { drizzle } from "drizzle-orm/neon-http";
import { neon } from "@neondatabase/serverless";
import * as schema from "@/db/schema";

function getDatabaseUrl(): string {
  const url = process.env.DATABASE_URL;
  if (!url) {
    // Fail loudly and immediately, exactly like sanity/env.ts's
    // assertValue pattern from Part 3 — a missing DATABASE_URL should
    // never silently produce a confusing downstream connection error.
    throw new Error("Missing environment variable: DATABASE_URL");
  }
  return url;
}

// neon() creates an HTTP-based SQL client — each query is sent as a
// single HTTPS request rather than over a persistent TCP socket. This is
// what makes it safe to use inside Next.js server functions, which may
// run in short-lived, serverless-style execution environments.
const sql = neon(getDatabaseUrl());

// drizzle() wraps that raw client with our typed schema, giving us
// db.query.users.findFirst(...), db.insert(enrollments).values(...), etc.
// with full TypeScript autocomplete and compile-time column checking.
export const db = drizzle(sql, { schema });
```

**Code walkthrough:**

- `drizzle-orm/neon-http` (as opposed to `drizzle-orm/neon-serverless`, a WebSocket-based alternative) is the simplest, most broadly compatible driver — each query is one HTTP request. We don't need multi-statement transactions spanning a persistent socket for anything in this series until Step 9's transaction helper, which Drizzle's HTTP driver still supports via its own transaction API, covered there.
- `{ schema }` passed to `drizzle()` is what enables Drizzle's "relational query API" (`db.query.users.findFirst(...)`) later in this part — without passing the schema object in, we'd only have the lower-level SQL-builder API (`db.select().from(...)`), which still works but has less convenient syntax for reading related rows.

### The Verification

```bash
npx tsc --noEmit
```

This will currently show an error because `@/db/schema` (the `index.ts` we're about to build) doesn't exist yet — that's expected. We'll resolve it in the next step.

---

## Step 5 — Defining the `users` and `roles` foundation

### The Target
`db/schema/users.ts` — our first real Drizzle table definition, including a PostgreSQL `enum` type for roles.

### The Concept
This table is the anchor every other table in this part points back to via `user_id`. We define the `role` column using a proper **PostgreSQL enum** — a column type restricted to a fixed, named set of values — rather than a plain string. This means the *database itself* rejects an attempt to insert `role = 'SUPERADMIN'` if that value was never defined, catching a whole category of bugs (typos, invalid states) before they ever reach application code — the database equivalent of Part 3's Sanity `options.list` restriction on the `difficulty` field.

### The Implementation

#### `db/schema/users.ts`

```ts
import { pgEnum, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

// A PostgreSQL enum — the database enforces that this column can ONLY
// ever contain one of these three exact strings, for every row, forever,
// regardless of what application code attempts to insert.
export const userRoleEnum = pgEnum("user_role", ["STUDENT", "INSTRUCTOR", "ADMIN"]);

export const users = pgTable("users", {
  // uuid().defaultRandom() generates a random UUID at insert time,
  // entirely inside Postgres — we never need to generate IDs in
  // application code, which avoids an entire class of ID-collision bugs.
  id: uuid("id").primaryKey().defaultRandom(),

  // The external Clerk user ID (added properly in Part 6). Marked
  // .unique() because exactly one internal user must correspond to
  // exactly one external identity — never shared, never duplicated.
  authProviderId: text("auth_provider_id").notNull().unique(),

  email: text("email").notNull().unique(),

  role: userRoleEnum("role").notNull().default("STUDENT"),

  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});
```

**Code walkthrough:**

- `.primaryKey().defaultRandom()` — every table in this schema uses this exact pattern for its `id` column. A **primary key** is a column guaranteed unique across every row in the table, used as that row's permanent, stable identity — every foreign key elsewhere in our schema points at one of these.
- `{ withTimezone: true }` on every timestamp column is a deliberate, non-optional habit: timestamps stored without timezone information become ambiguous the moment your application or users span more than one timezone — a very common real-world bug this single option prevents entirely.
- `.notNull()` appears on almost every column — in PostgreSQL, a column is nullable by default unless told otherwise, which is the *opposite* of what we usually want for required business data. We'll only omit `.notNull()` on columns that have a genuine, meaningful "no value yet" state (like `module_attempts.score`, built in Step 7).

### The Verification

Deferred — we verify the whole schema compiles together once every file exists, at the end of Step 7.

---

## Step 6 — Defining `enrollments`, `lesson_progress`, and `course_progress`

### The Target
`db/schema/enrollments.ts`, `db/schema/lesson-progress.ts`, and `db/schema/course-progress.ts` — the three tables tracking a student's relationship to courses and lessons.

### The Concept
These three tables answer three distinct, related questions, and keeping them separate (rather than combining them into one sprawling table) is deliberate:

- **`enrollments`**: "Is this student *allowed into* this course at all?" — the access-control record.
- **`lesson_progress`**: "Has this student finished *this specific lesson*?" — the fine-grained record.
- **`course_progress`**: "What percentage of the *whole course* has this student finished?" — the aggregated summary, which Part 12's Inngest workflows will recalculate automatically whenever lesson progress changes, rather than us trying to compute it live on every single page load.

### The Implementation

#### `db/schema/enrollments.ts`

```ts
import { pgEnum, pgTable, text, timestamp, unique, uuid } from "drizzle-orm/pg-core";
import { users } from "./users";

export const enrollmentStatusEnum = pgEnum("enrollment_status", [
  "ACTIVE",
  "COMPLETED",
  "CANCELLED",
]);

export const enrollments = pgTable(
  "enrollments",
  {
    id: uuid("id").primaryKey().defaultRandom(),

    // references() creates an ACTUAL PostgreSQL foreign key — Postgres
    // will physically refuse to insert an enrollment row pointing at a
    // user_id that doesn't exist in the users table.
    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),

    // A Sanity course document's _id — a plain string, per Step 3's
    // design decision. Postgres CANNOT verify this points at a real
    // Sanity document; that verification is our application's job.
    courseId: text("course_id").notNull(),

    status: enrollmentStatusEnum("status").notNull().default("ACTIVE"),

    enrolledAt: timestamp("enrolled_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    // The UNIQUE constraint described in Step 3 — makes duplicate
    // enrollment for the same user+course structurally impossible at the
    // database level, closing the race-condition window entirely.
    unique("enrollments_user_course_unique").on(table.userId, table.courseId),
  ]
);
```

#### `db/schema/lesson-progress.ts`

```ts
import { pgEnum, pgTable, text, timestamp, unique, uuid } from "drizzle-orm/pg-core";
import { enrollments } from "./enrollments";
import { users } from "./users";

export const lessonStatusEnum = pgEnum("lesson_status", [
  "NOT_STARTED",
  "IN_PROGRESS",
  "COMPLETED",
]);

export const lessonProgress = pgTable(
  "lesson_progress",
  {
    id: uuid("id").primaryKey().defaultRandom(),

    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),

    enrollmentId: uuid("enrollment_id")
      .notNull()
      .references(() => enrollments.id, { onDelete: "cascade" }),

    // Denormalized (duplicated) from the enrollment on purpose — this
    // lets us query "all progress for course X" directly, without an
    // extra join through enrollments every single time. A small,
    // deliberate tradeoff of a little redundancy for query simplicity.
    courseId: text("course_id").notNull(),

    lessonId: text("lesson_id").notNull(),

    status: lessonStatusEnum("status").notNull().default("NOT_STARTED"),

    completedAt: timestamp("completed_at", { withTimezone: true }),

    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    unique("lesson_progress_user_lesson_unique").on(table.userId, table.lessonId),
  ]
);
```

#### `db/schema/course-progress.ts`

```ts
import { integer, pgTable, text, timestamp, unique, uuid } from "drizzle-orm/pg-core";
import { enrollments } from "./enrollments";
import { users } from "./users";

export const courseProgress = pgTable(
  "course_progress",
  {
    id: uuid("id").primaryKey().defaultRandom(),

    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),

    enrollmentId: uuid("enrollment_id")
      .notNull()
      .references(() => enrollments.id, { onDelete: "cascade" }),

    courseId: text("course_id").notNull(),

    // Stored as a plain integer 0–100 rather than a fraction — this
    // matches exactly what ProgressBar (Part 2) expects as its "value"
    // prop, so no conversion logic is needed when we wire this up later.
    completionPercentage: integer("completion_percentage").notNull().default(0),

    lastActivityAt: timestamp("last_activity_at", { withTimezone: true }).notNull().defaultNow(),

    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    unique("course_progress_user_course_unique").on(table.userId, table.courseId),
  ]
);
```

**Code walkthrough:**

- `.references(() => users.id, { onDelete: "cascade" })` — the `onDelete: "cascade"` option tells Postgres: "if the referenced user row is ever deleted, automatically delete this row too, rather than leaving an orphaned record or blocking the deletion." This matters directly for Part 6's `user.deleted` Clerk webhook — when a user account is deleted, we want their enrollments, progress, and attempts to be cleanly removed alongside them, not left behind as broken references.
- Every foreign key is written as a *function* (`() => users.id`), not a direct reference (`users.id`) — this is a Drizzle convention that allows tables to reference each other regardless of which file happens to be imported first, avoiding JavaScript module circular-import errors that a direct reference could sometimes trigger.
- The `(table) => [...]` third argument to `pgTable` is where **table-level constraints** live — constraints that involve more than one column together (like our compound `unique(...).on(table.userId, table.courseId)`), as opposed to single-column rules like `.notNull()` or `.unique()` that attach directly to one field's definition.

### The Verification

Deferred to the end of Step 7.

---

## Step 7 — Defining `module_attempts`, `certificates`, `webhook_events`, `workflow_events`, and `audit_logs`

### The Target
The remaining five table definitions, completing the full schema from Step 3's plan.

### The Concept
These five tables serve four distinct purposes we've already discussed conceptually: fine-grained assessment history (`module_attempts`), proof of achievement (`certificates`), safe webhook processing (`webhook_events`), background job tracking (`workflow_events`), and a general accountability trail (`audit_logs`). We build all five now, together, since none of them have complex interdependencies beyond referencing `users`.

### The Implementation

#### `db/schema/module-attempts.ts`

```ts
import {
  boolean,
  integer,
  jsonb,
  pgTable,
  text,
  timestamp,
  unique,
  uuid,
} from "drizzle-orm/pg-core";
import { users } from "./users";

export const moduleAttempts = pgTable(
  "module_attempts",
  {
    id: uuid("id").primaryKey().defaultRandom(),

    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),

    lessonId: text("lesson_id").notNull(),

    // Matches quizBlock/codeExerciseBlock's moduleId from Part 3 — this
    // is the stable link between "a specific interactive block authored
    // in Sanity" and "a specific record of a student's attempt at it."
    moduleId: text("module_id").notNull(),

    attemptNumber: integer("attempt_number").notNull().default(1),

    // jsonb stores arbitrary structured data — here, exactly what the
    // student submitted (e.g. { "selectedOptionIndex": 2 } for a quiz).
    // We use jsonb (not json) because Postgres indexes and queries jsonb
    // more efficiently; we'll rely on this in Part 15's analytics.
    submission: jsonb("submission").notNull(),

    // Nullable ON PURPOSE — a submission that hasn't been graded yet (or
    // a module type with no numeric score) legitimately has no score.
    score: integer("score"),

    isCorrect: boolean("is_correct"),

    submittedAt: timestamp("submitted_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    // Allows MULTIPLE attempts per user per module, while still
    // preventing two rows from ever claiming to be the exact same
    // attempt number for the same module — this is what makes
    // idempotent retry logic possible in Part 11.
    unique("module_attempts_user_module_attempt_unique").on(
      table.userId,
      table.moduleId,
      table.attemptNumber
    ),
  ]
);
```

#### `db/schema/certificates.ts`

```ts
import { pgTable, text, timestamp, unique, uuid } from "drizzle-orm/pg-core";
import { users } from "./users";

export const certificates = pgTable(
  "certificates",
  {
    id: uuid("id").primaryKey().defaultRandom(),

    userId: uuid("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),

    courseId: text("course_id").notNull(),

    // A human-shareable identifier (e.g. "GM-2025-000042"), distinct from
    // the internal uuid "id" column — generated in Part 13, designed to
    // be safely printable on an actual certificate document.
    certificateNumber: text("certificate_number").notNull().unique(),

    issuedAt: timestamp("issued_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    // The single most important constraint in this table: it makes
    // issuing a SECOND certificate for the same user+course a database-
    // level impossibility, not merely something our application code
    // remembers to check — directly implementing Part 0's requirement
    // that certificates prevent duplicate issuance.
    unique("certificates_user_course_unique").on(table.userId, table.courseId),
  ]
);
```

#### `db/schema/webhook-events.ts`

```ts
import { jsonb, pgTable, text, timestamp, unique, uuid } from "drizzle-orm/pg-core";

export const webhookEvents = pgTable(
  "webhook_events",
  {
    id: uuid("id").primaryKey().defaultRandom(),

    // Which external provider sent this (e.g. "clerk") — lets this one
    // table serve multiple future webhook sources without redesign.
    source: text("source").notNull(),

    eventType: text("event_type").notNull(),

    // The webhook provider's OWN event ID (Clerk includes one in every
    // webhook payload). This is the key to idempotent webhook processing
    // in Part 6: if the same webhook is ever delivered twice (which
    // providers explicitly warn can happen — networks are unreliable),
    // this constraint lets us detect and skip the duplicate safely.
    externalId: text("external_id").notNull(),

    payload: jsonb("payload").notNull(),

    processedAt: timestamp("processed_at", { withTimezone: true }),

    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    unique("webhook_events_source_external_id_unique").on(table.source, table.externalId),
  ]
);
```

#### `db/schema/workflow-events.ts`

```ts
import { jsonb, pgEnum, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const workflowStatusEnum = pgEnum("workflow_status", [
  "PENDING",
  "PROCESSED",
  "FAILED",
]);

export const workflowEvents = pgTable("workflow_events", {
  id: uuid("id").primaryKey().defaultRandom(),

  // e.g. "lesson/completed", "course/enrolled" — matches the Inngest
  // event names we'll define formally in Part 12.
  eventName: text("event_name").notNull(),

  payload: jsonb("payload").notNull(),

  status: workflowStatusEnum("status").notNull().default("PENDING"),

  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  processedAt: timestamp("processed_at", { withTimezone: true }),
});
```

#### `db/schema/audit-logs.ts`

```ts
import { jsonb, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";
import { users } from "./users";

export const auditLogs = pgTable("audit_logs", {
  id: uuid("id").primaryKey().defaultRandom(),

  // Nullable ON PURPOSE — some audited actions are system-initiated
  // (e.g. an Inngest scheduled job), with no specific user to attribute
  // them to. Note there is deliberately NO onDelete: "cascade" here —
  // if a user is deleted, we want their audit history to remain
  // (with userId simply set to null via onDelete: "set null"), since
  // audit trails should outlive the account that generated them.
  userId: uuid("user_id").references(() => users.id, { onDelete: "set null" }),

  action: text("action").notNull(),

  metadata: jsonb("metadata"),

  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});
```

**Code walkthrough:**

- Notice `audit_logs.userId` uses `onDelete: "set null"` while every other table so far uses `onDelete: "cascade"` — this is a deliberate, meaningful difference we're calling out explicitly: cascading deletes make sense for data that's *meaningless without* its owning user (an enrollment with no user is nonsense), while `"set null"` makes sense for historical records that should *outlive* the user they were about (an audit trail entry documenting what happened is still valuable evidence even after an account is gone).
- `module_attempts`'s compound unique constraint on `(userId, moduleId, attemptNumber)` — rather than just `(userId, moduleId)` — is what deliberately *allows* multiple attempts, unlike `certificates`, which uses a `(userId, courseId)` unique constraint specifically to *forbid* multiples. Comparing these two side by side is a good way to internalize how the same `unique()` mechanism can enforce very different business rules depending on which columns it covers.

Finally, tie every table together in the schema index that `db/client.ts` (Step 4) already imports from:

#### `db/schema/index.ts`

```ts
export * from "./users";
export * from "./enrollments";
export * from "./lesson-progress";
export * from "./course-progress";
export * from "./module-attempts";
export * from "./certificates";
export * from "./webhook-events";
export * from "./workflow-events";
export * from "./audit-logs";
```

### The Verification

```bash
npx tsc --noEmit
```
Should now complete with **no errors** — this confirms every table file compiles, every cross-file foreign key reference resolves correctly, and `db/client.ts`'s import of `@/db/schema` (from Step 4) now succeeds since `db/schema/index.ts` exists and re-exports everything.

---

## Step 8 — Generating and applying the first migration

### The Target
Adding `db:generate`, `db:migrate`, and `db:studio` scripts to `package.json`, running them for the first time, and confirming the actual tables now exist inside our real Neon database.

### The Concept
Recall Step 3's Git-history analogy: a migration is a permit describing one change. `drizzle-kit generate` **compares** our TypeScript schema files against the migration history it already knows about, and writes a new SQL file describing exactly the difference — in our case, since this is the first migration, that difference is "create every one of these nine tables from scratch." `drizzle-kit migrate` then **applies** that SQL file to the real database. Separating "generate" from "apply" as two distinct steps is deliberate: it gives us a chance to *read* the generated SQL before running it against a real database — a habit worth keeping even after this series, since blindly trusting auto-generated SQL against production data is a genuine risk.

### The Implementation

#### `package.json` (add these scripts)

```json
{
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint",
    "typecheck": "tsc --noEmit",
    "db:generate": "dotenv -e .env.local -- drizzle-kit generate",
    "db:migrate": "dotenv -e .env.local -- drizzle-kit migrate",
    "db:studio": "dotenv -e .env.local -- drizzle-kit studio"
  }
}
```

**Why `dotenv -e .env.local --`?** As explained in Step 4, `drizzle-kit` runs as a standalone CLI tool outside of Next.js's own automatic environment-variable loading. `dotenv-cli` (installed in Step 4) explicitly loads `.env.local` into the process environment *before* running the given command, which is what makes `process.env.DATABASE_URL` inside `drizzle.config.ts` actually resolve to a real value when we run these scripts.

Generate the first migration:

```bash
npm run db:generate
```

Drizzle will print something like `9 tables created` and write a new file into `db/migrations/`, named something like `0000_<random_words>.sql`. Open that generated file and skim it — you should see nine `CREATE TABLE` statements, matching every table we defined, along with the enum types, foreign keys, and unique constraints we wrote in Steps 5–7, now expressed as real SQL.

Apply the migration to your actual Neon database:

```bash
npm run db:migrate
```

### The Verification

Open Drizzle's built-in visual database browser:

```bash
npm run db:studio
```

This opens a local web interface (usually at `https://local.drizzle.studio`) showing every table in your real Neon database. Confirm all nine tables appear: `users`, `enrollments`, `lesson_progress`, `course_progress`, `module_attempts`, `certificates`, `webhook_events`, `workflow_events`, `audit_logs` — each currently empty, with the exact columns we defined.

You can also verify directly from Neon's own console: visit **https://console.neon.tech**, open your project, go to the "Tables" view, and confirm the same nine tables appear there too — Drizzle Studio and Neon's console are simply two different windows onto the exact same underlying database.

---

## Step 9 — Building database query helpers and a transaction example

### The Target
`db/queries/users.ts` — a small set of reusable, typed helper functions for reading and writing user rows — and a demonstration of Drizzle's transaction API, which we'll rely on heavily starting in Part 8.

### The Concept
A **database transaction** groups multiple write operations into a single all-or-nothing unit — either every operation inside it succeeds and is saved, or (if any single one fails) *all* of them are rolled back as if none had ever happened. Think of it like a bank transfer: money must leave one account and arrive in another as a single, indivisible action — if the system crashes after debiting the sender but before crediting the receiver, that money must not simply vanish. We won't have a real multi-step write yet in this part (that arrives in Part 8's enrollment flow), but it's important to introduce the *pattern* now, using a realistic Part 8 preview as the example, so it isn't unfamiliar syntax when we depend on it for something securing real user data.

### The Implementation

#### `db/queries/users.ts`

```ts
import { eq } from "drizzle-orm";
import { db } from "@/db/client";
import { users, type userRoleEnum } from "@/db/schema";

export type UserRole = (typeof userRoleEnum.enumValues)[number];

// findUserByAuthProviderId is the function Part 6's authentication layer
// will call on every request to translate "this Clerk session" into
// "this internal database user." Returns undefined (not null) if no
// match exists, following Drizzle's own convention for "no result."
export async function findUserByAuthProviderId(authProviderId: string) {
  return db.query.users.findFirst({
    where: eq(users.authProviderId, authProviderId),
  });
}

export async function findUserById(id: string) {
  return db.query.users.findFirst({
    where: eq(users.id, id),
  });
}

export interface CreateUserInput {
  authProviderId: string;
  email: string;
  role?: UserRole;
}

export async function createUser(input: CreateUserInput) {
  // .returning() asks Postgres to hand back the row it just inserted
  // (including auto-generated fields like id/createdAt) in the same
  // round trip, rather than requiring a separate follow-up SELECT.
  const [created] = await db.insert(users).values(input).returning();
  return created;
}
```

Now, a small demonstration file showing the transaction pattern we'll rely on starting in Part 8 — not wired into any real feature yet, but worth seeing in isolation before it's combined with authorization logic:

#### `db/queries/enrollment-example.ts`

```ts
import { db } from "@/db/client";
import { courseProgress, enrollments } from "@/db/schema";

export interface CreateEnrollmentInput {
  userId: string;
  courseId: string;
}

// This function demonstrates Drizzle's transaction API. Part 8 will
// build the REAL version of this function, wrapped in authorization and
// Zod validation — this is a simplified preview focused purely on the
// transaction mechanics themselves.
export async function createEnrollmentWithProgress(input: CreateEnrollmentInput) {
  // db.transaction() opens a transaction and passes a special "tx" client
  // into the callback — every query inside MUST use "tx", not the outer
  // "db", or it would run outside the transaction entirely, defeating
  // the whole point.
  return db.transaction(async (tx) => {
    const [enrollment] = await tx
      .insert(enrollments)
      .values({ userId: input.userId, courseId: input.courseId })
      .returning();

    // If THIS insert fails for any reason (e.g. a constraint violation),
    // Drizzle automatically rolls back the enrollment insert above too —
    // we will never end up with an enrollment row that has no matching
    // course_progress row, because the two writes are indivisible.
    const [progress] = await tx
      .insert(courseProgress)
      .values({
        userId: input.userId,
        enrollmentId: enrollment.id,
        courseId: input.courseId,
        completionPercentage: 0,
      })
      .returning();

    return { enrollment, progress };
  });
}
```

**Code walkthrough:**

- `db.query.users.findFirst({ where: eq(users.authProviderId, authProviderId) })` uses Drizzle's **relational query API** (enabled back in Step 4 by passing `{ schema }` to `drizzle()`) — notice how closely this reads like a plain English sentence, which is exactly the point of a well-designed ORM.
- `eq(users.authProviderId, authProviderId)` — `eq` is Drizzle's equality-comparison helper, imported from `drizzle-orm`; there's a whole family of these (`ne`, `gt`, `lt`, `and`, `or`, etc.) which the Part 5 reference section below documents.
- `db.transaction(async (tx) => { ... })` — the critical detail here is that **every query inside the callback uses `tx`, never the outer `db`**. This is a common beginner mistake worth flagging explicitly: writing `db.insert(...)` instead of `tx.insert(...)` inside a transaction callback silently runs that query *outside* the transaction, defeating the entire all-or-nothing guarantee without raising any error.

### The Verification

We don't have a route calling these yet (that arrives properly in Part 6 and Part 8) — verify purely that everything compiles:

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 10 — Seeding development data

### The Target
`db/seed.ts` — a script inserting one development user and one sample enrollment directly, so we have real rows to inspect and build against before real authentication exists.

### The Concept
A **seed script** populates a database with a known, predictable starting set of data — useful during development so you're never staring at a completely empty database while building and testing a feature. We're seeding *before* Part 6's real authentication exists specifically so that Part 6 onward has a concrete, already-existing user row to link a real Clerk account to, making that part's verification steps much clearer.

### The Implementation

#### `db/seed.ts`

```ts
import { createUser, findUserByAuthProviderId } from "@/db/queries/users";
import { createEnrollmentWithProgress } from "@/db/queries/enrollment-example";

// A clearly fake, obviously-development-only Clerk ID — Part 6 will
// explain exactly how real IDs are generated and synchronized; for now
// this placeholder simply lets us create a real row to build against.
const DEV_AUTH_PROVIDER_ID = "dev_seed_user_001";
const DEV_EMAIL = "dev-student@example.com";

// Replace this with the real _id of your "Introduction to Databases"
// course from Part 3 — open Studio, click into the course, and copy its
// document ID from the URL or the document's metadata panel.
const SAMPLE_COURSE_ID = "REPLACE_WITH_REAL_SANITY_COURSE_ID";

async function seed() {
  console.log("Seeding development data...");

  const existing = await findUserByAuthProviderId(DEV_AUTH_PROVIDER_ID);
  if (existing) {
    console.log("Development user already exists, skipping user creation.");
    return;
  }

  const user = await createUser({
    authProviderId: DEV_AUTH_PROVIDER_ID,
    email: DEV_EMAIL,
    role: "STUDENT",
  });
  console.log(`Created development user: ${user.id} (${user.email})`);

  const { enrollment, progress } = await createEnrollmentWithProgress({
    userId: user.id,
    courseId: SAMPLE_COURSE_ID,
  });
  console.log(`Created enrollment: ${enrollment.id}`);
  console.log(`Created course progress: ${progress.id}`);

  console.log("Seeding complete.");
}

seed()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Seeding failed:", error);
    process.exit(1);
  });
```

Add a script to run it:

#### `package.json` (add this script)

```json
{
  "scripts": {
    "db:seed": "dotenv -e .env.local -- npx tsx db/seed.ts"
  }
}
```

```bash
npm install -D tsx
```

### The Implementation 

Before running the seed script, go back into Sanity Studio (`http://localhost:3000/studio`), open your "Introduction to Databases" course document, and copy its real document ID — you can find this by opening the document and checking the URL (it will contain something like `,eyJzIjoi...` encoded, which isn't directly readable) or, more reliably, by switching Vision (`http://localhost:3000/studio/vision`) to run:

```groq
*[_type == "course"][0]._id
```

Copy the returned string (it will look something like `a1b2c3d4-e5f6-7890-abcd-ef1234567890`) and paste it into `db/seed.ts`, replacing `REPLACE_WITH_REAL_SANITY_COURSE_ID`.

### The Verification

```bash
npm run db:seed
```

Expected output:

```text
Seeding development data...
Created development user: <some-uuid> (dev-student@example.com)
Created enrollment: <some-uuid>
Created course progress: <some-uuid>
Seeding complete.
```

Confirm the run is **idempotent** (safe to run more than once) by running it again immediately:

```bash
npm run db:seed
```

Expected output this time:

```text
Seeding development data...
Development user already exists, skipping user creation.
```

This confirms our `findUserByAuthProviderId` check correctly prevents duplicate seeding — worth testing deliberately, since a seed script that silently creates duplicate rows on every run is a common and confusing source of bugs during development.

Now open Drizzle Studio again to inspect the real rows:

```bash
npm run db:studio
```

Confirm:
1. The `users` table has exactly one row, with `role = STUDENT` and the correct email.
2. The `enrollments` table has exactly one row, with `user_id` matching that user, `course_id` matching your real Sanity course ID, and `status = ACTIVE`.
3. The `course_progress` table has exactly one row, linked to that same enrollment, with `completion_percentage = 0`.

Finally, test that our unique constraint actually works as designed — attempt to insert a genuine duplicate enrollment directly, by temporarily adding this snippet to the bottom of `db/seed.ts` just before the `seed().then(...)` call, then reverting it immediately after testing:

```ts
// TEMPORARY TEST — remove after confirming the error below
await createEnrollmentWithProgress({
  userId: (await findUserByAuthProviderId(DEV_AUTH_PROVIDER_ID))!.id,
  courseId: SAMPLE_COURSE_ID,
});
```

Run `npm run db:seed` once more (after first deleting the existing user row via Drizzle Studio, so the script re-creates everything fresh) and confirm the second `createEnrollmentWithProgress` call throws a Postgres unique-violation error in the terminal — proof the `enrollments_user_course_unique` constraint is genuinely enforced by the database, not just by application logic. **Remove this temporary test snippet** immediately after confirming the error, and re-run `npm run db:seed` one final time to restore a clean, single-enrollment state.

---

## Common mistakes

- **`drizzle-kit generate` says "Missing DATABASE_URL"** — Confirm you're running it via `npm run db:generate` (which goes through `dotenv-cli`), not `npx drizzle-kit generate` directly, which would skip loading `.env.local` entirely.
- **Migration fails with `relation "users" already exists`** — Usually means a previous partial migration attempt already created some tables. Check Neon's console "Tables" view; if tables exist but Drizzle's internal migration-tracking table doesn't know about them, you may need to drop the affected tables manually in Neon's SQL editor and re-run `npm run db:migrate` cleanly.
- **TypeScript error: "Property 'query' does not exist on type..."** — Means `drizzle()` in `db/client.ts` wasn't passed the `{ schema }` option, disabling the relational query API (`db.query.users.findFirst`) entirely.
- **Foreign key violation when seeding** — Almost always means `SAMPLE_COURSE_ID` in `db/seed.ts` still contains the placeholder text, or an incorrect/mistyped Sanity document ID. Re-run the Vision query from Step 10 to get the exact correct ID.
- **`unique constraint violation` appears unexpectedly on a normal (non-test) run** — Confirm you're not accidentally running the seed script against a database that already has the dev user from a previous session; the "already exists, skipping" branch should prevent this — if it doesn't, double check `DEV_AUTH_PROVIDER_ID` matches exactly between runs.
- **Drizzle Studio shows tables but every column looks like `text` regardless of what you defined** — This is usually just Drizzle Studio's display quirk for certain enum/timestamp rendering; the underlying Postgres column types are still correct — verify directly in Neon's SQL editor with `\d users` (or the table view) if in doubt.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `drizzle.config.ts`, `db/client.ts`, `db/schema/*.ts`, `db/migrations/0000_*.sql`, `db/queries/users.ts`, `db/queries/enrollment-example.ts`, `db/seed.ts`, and the updated `package.json` and `.env.example`.

**Important:** confirm `db/migrations/` is **not** excluded by `.gitignore` — unlike `.env.local`, migration SQL files must always be committed to Git, since they're the versioned historical record of your schema, exactly like source code itself.

```bash
git commit -m "Part 5: Neon PostgreSQL transactional schema — users, enrollments, progress, attempts, certificates, webhooks, workflows, audit logs, Drizzle setup, seed script"
```

---

## Reference: full table inventory

| Table | Primary purpose | Key constraints |
|---|---|---|
| `users` | Internal identity, linked to Clerk | `unique(auth_provider_id)`, `unique(email)` |
| `enrollments` | Course access control | `unique(user_id, course_id)` |
| `lesson_progress` | Per-lesson completion tracking | `unique(user_id, lesson_id)` |
| `course_progress` | Aggregated per-course completion % | `unique(user_id, course_id)` |
| `module_attempts` | Per-quiz/exercise submission history | `unique(user_id, module_id, attempt_number)` |
| `certificates` | Proof of course completion | `unique(user_id, course_id)`, `unique(certificate_number)` |
| `webhook_events` | Idempotent external webhook processing | `unique(source, external_id)` |
| `workflow_events` | Background job/event tracking | — |
| `audit_logs` | General accountability trail | `user_id` uses `onDelete: "set null"` |

## Reference: Drizzle query cheat sheet

| Pattern | Meaning |
|---|---|
| `db.query.table.findFirst({ where: eq(...) })` | Fetch one row (relational API) |
| `db.query.table.findMany({ where: ... })` | Fetch multiple rows |
| `db.insert(table).values({...}).returning()` | Insert and get the inserted row(s) back |
| `db.update(table).set({...}).where(eq(...))` | Update matching rows |
| `db.delete(table).where(eq(...))` | Delete matching rows |
| `db.transaction(async (tx) => {...})` | All-or-nothing multi-step writes — always use `tx`, never the outer `db`, inside the callback |
| `eq`, `ne`, `and`, `or`, `gt`, `lt`, `isNull` | Comparison/logical helpers imported from `"drizzle-orm"` |

## Reference: `onDelete` behavior cheat sheet

| Option | Effect when the referenced row is deleted |
|---|---|
| `"cascade"` | Automatically delete this row too (used for enrollments, progress, attempts, certificates) |
| `"set null"` | Set the foreign key column to `NULL`, keep this row (used for `audit_logs.user_id`) |
| *(default, unspecified)* | Postgres blocks the delete entirely if any referencing row exists |

---

## What's next

Part 6 connects these two halves of the architecture for the first time: we'll create a real Clerk application, add sign-in and sign-up flows, protect private routes, and build the webhook pipeline that keeps our `users` table (built in this part) synchronized with Clerk's external identity — including the critical distinction between an internal user ID and an external auth provider ID that every table in this part's foreign keys already assumes exists.
