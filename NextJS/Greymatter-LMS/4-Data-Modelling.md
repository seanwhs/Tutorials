# Part 4 — Data Modelling: Designing the Greymatter LMS Database 

In Part 3, we built the Next.js 16 frontend shell — route groups, Clerk auth, a Tailwind dashboard, and a Server Action stub that stopped short of any business logic [6]. Now we build the system of record: the database itself.

**🎯 Goal of this lesson:** Design and implement the full Greymatter LMS schema in Neon Postgres using Drizzle ORM in place of Supabase, and understand exactly what we lose — and must replace ourselves — by not having Supabase's built-in Auth and Row-Level Security [6].

**🧰 Prereqs:** Part 3 completed. You'll need a free Neon account (neon.tech) — create a project and copy your connection string before section 2 [6].

---

## 1. Why Neon + Drizzle instead of Supabase

Many LMS tutorials reach for Supabase because it bundles Postgres, Auth, and Row-Level Security (RLS) into one product. Greymatter LMS deliberately doesn't, because Part 3 already gave us Clerk for authentication [7], and layering Supabase's Auth on top would mean maintaining two separate identity systems that could drift out of sync. Instead, we use **Neon** (serverless Postgres) purely as storage, and **Drizzle ORM** as a type-safe query layer — keeping the Data Layer's job exactly as narrow as Part 1 defined it: store data, never decide what runs [12].

That narrowness has a real cost worth naming up front: Supabase's RLS would normally enforce "a user can only see their own organization's rows" automatically, at the database level. Without it, **every single query we write in this part and beyond must manually filter by `orgId`** — there is no safety net catching a forgotten filter. This isn't fully closed here; it's flagged deliberately as an open gap that Part 9's hardening pass comes back to reinforce with explicit tenant-scope checks inside every Inngest step [1]. For now, just keep in mind: any query that touches `submissions`, `courses`, or `worker_results` without an `orgId` condition is a bug waiting to leak data across tenants.

---

## 2. Setting up Neon + Drizzle

From the monorepo root, move into the `infra/db` package created back in Part 2 [8] and initialize it:

```bash
cd infra/db
npm init -y
npm install drizzle-orm pg
npm install --save-dev drizzle-kit @types/pg
```

Add your Neon connection string:

```bash
# infra/db/.env
DATABASE_URL=postgresql://user:password@your-neon-host/greymatter?sslmode=require
```

And configure Drizzle Kit, the CLI that generates and runs migrations:

```typescript
// infra/db/drizzle.config.ts
import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./schema.ts",
  out: "./migrations",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});
```

A quick concept note: Drizzle Kit is a *migration generator*, not the ORM itself. The ORM (`drizzle-orm`) is what your application code imports to run queries; Drizzle Kit is a separate CLI tool that reads your schema file and produces SQL migration files to keep your actual Neon database in sync with it.

**✅ Checkpoint:** Run `npx drizzle-kit studio` — it should connect to your Neon project and open a browser-based table viewer (currently empty, since we haven't defined any tables yet) [6].

---

## 3. Designing the schema

Greymatter LMS needs six tables to support everything from Part 5 (events) through Part 11 (AI-native features) [5][10]: `courses`, `lessons`, `enrollments`, `submissions`, `worker_results`, and (added later in Part 10) `workflow_logs` [11]. This part builds the first five. Every single one carries an `orgId` column — this is the tenant-scoping mechanism that stands in for the Row-Level Security Supabase would normally give us for free, and it's non-negotiable on every table from here forward.

```typescript
// infra/db/schema.ts
import { pgTable, uuid, text, timestamp, jsonb, integer } from "drizzle-orm/pg-core";

export const courses = pgTable("courses", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  title: text("title").notNull(),
  description: text("description"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const lessons = pgTable("lessons", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  courseId: uuid("course_id").notNull(),
  title: text("title").notNull(),
  content: text("content"),
});

export const enrollments = pgTable("enrollments", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  courseId: uuid("course_id").notNull(),
  studentId: text("student_id").notNull(),
});

export const submissions = pgTable("submissions", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  studentId: text("student_id").notNull(),
  lessonId: uuid("lesson_id").notNull(),
  content: text("content"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const workerResults = pgTable("worker_results", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  submissionId: uuid("submission_id").notNull(),
  workerName: text("worker_name").notNull(),
  resultType: text("result_type").notNull(),
  output: jsonb("output"),
  createdAt: timestamp("created_at").defaultNow(),
});
```

Walking through why each table exists: `courses` and `lessons` are the content students consume; `enrollments` links a student to a course; `submissions` is what a student hands in — this is the exact table Part 5's `assignment.submitted` event reads from via `fetch-context` [5]; and `worker_results` is where every AI worker's output eventually lands — the row Part 7's Grading Worker writes its score into, and the same table Part 11's Summary Worker later writes a `knowledge_graph`-typed result into [10].

Run the migration against your Neon database:

```bash
cd infra/db
npx drizzle-kit push
```

**✅ Checkpoint:** Reopen `npx drizzle-kit studio` and confirm all five tables now appear, empty but real.

---

## 4. Connecting Neon to the Next.js app

Back in `apps/web`, install the same query layer so Server Actions can read and write directly:

```bash
cd apps/web
npm install drizzle-orm pg
```

```typescript
// apps/web/src/lib/db/index.ts
import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import * as schema from "../../../../../infra/db/schema";

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
export const db = drizzle(pool, { schema });
```

Don't forget to add `DATABASE_URL` to `apps/web/.env.local` too, pointing at the same Neon database [6]. Notice this import reaches directly into `infra/db/schema` rather than duplicating the table definitions — this is exactly why `infra/db` was scaffolded as its own package back in Part 2, separate from `apps/web`: starting in Part 5, Inngest functions will *also* need this same schema to persist worker results, so keeping one shared source of truth here prevents the app and the orchestration layer from silently drifting out of sync [8].

**✅ Checkpoint:** From a Server Action or a temporary test file in `apps/web`, run `db.query.courses.findMany()` and confirm it resolves without a connection error (an empty array is expected — we haven't inserted any courses yet).

---

## 5. Wiring the schema into Part 3's stub Server Action

Recall Part 3's `submitAssignment` Server Action stopped at a `console.log`, deliberately, because there was nowhere real to persist a submission yet [7]. Now there is. Update it:

```typescript
// app/(dashboard)/courses/actions.ts
"use server";

import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { submissions } from "../../../../../infra/db/schema";

export async function submitAssignment(lessonId: string, content: string) {
  const { userId, orgId } = await auth();
  if (!userId || !orgId) throw new Error("Unauthorized");

  const [record] = await db.insert(submissions).values({
    orgId,
    studentId: userId,
    lessonId,
    content,
  }).returning();

  console.log("Submission persisted:", record.id);
  // Part 5 makes this actually emit a real event.
}
```

Notice `orgId` comes straight from Clerk's `auth()` call, never from client input — this is the tenant-scoping discipline every future query must repeat by hand, since we have no RLS to fall back on.

**✅ Checkpoint:** Submit an assignment through the dashboard button wired up in Part 3, then open `npx drizzle-kit studio` and confirm a new row appears in `submissions` with the correct `orgId` and `studentId` attached.

---

## 6. What we still owe ourselves

Two things are deliberately left open at the end of this part, both flagged here on purpose rather than glossed over:

1. **No automatic tenant isolation.** Every query anywhere in this codebase — today and in every future part — must manually include an `orgId` filter. Nothing stops a forgotten one from leaking data across organizations.
2. **No event emission yet.** `submitAssignment` now writes a real row, but still just logs afterward — there's still no Orchestration Layer to hand that submission off to.

Both gaps are intentional teaching devices, not oversights: Part 5 closes the second one immediately by turning this same Server Action into a real event emitter [5], and Part 9 closes the first one by adding explicit tenant-scope checks inside every Inngest step, rejecting any submission missing an `orgId` outright [1].

---

## 7. What's next

We now have a real Neon Postgres database, a full Drizzle schema, and a Server Action that persists real data instead of just logging it. In Part 5, we build the Orchestration Layer itself with Inngest, and finally make `submitAssignment` emit a real event — `assignment.submitted` — instead of stopping at a database write [5].

**🩹 Common confusion at this stage:** "If we don't have Row-Level Security, why not just add a Postgres policy instead of trusting every query to filter by `orgId` manually?" — That's a completely reasonable production alternative, and worth exploring on your own. This series deliberately keeps tenant scoping at the application layer instead, specifically so Part 9 has a concrete, visible gap to close — watching the defense get added in Inngest's `discover-workers` step makes the *reason* for
