# Part 4 — Data Modelling: Designing the Greymatter LMS Database

In Part 3, we built the Next.js 16 frontend shell — route groups, Clerk auth, a Tailwind dashboard, and a Server Action stub that stops short of any business logic. Now we build the system of record: the database itself.

**🎯 Goal of this lesson:** Design and implement the Greymatter LMS schema in Neon Postgres, using Drizzle ORM in place of Supabase, and understand exactly what we lose (and must replace) by not having Supabase's built-in Auth and Row-Level Security.

**🧰 Prereqs:** Part 3 completed. You'll need a free Neon account (neon.tech) — create a project and copy your connection string before section 3.

---

## 1. Why the database matters this much

The original tutorial frames this part simply but powerfully: the database is the "memory" of the system, storing the raw data that AI workers later read from and write results back into — things like quiz generation, grading results, summaries, tutor feedback, and analytics insights [6].

For Greymatter LMS, the schema needs to support the exact flow we traced in Part 1: a student submits an assignment, and multiple independent workers — a grader, a quiz generator, a tutor AI, and an analytics engine — all read that submission and write their own results back [6].

---

## 2. What changes moving from Supabase to Neon

The original architecture uses Supabase specifically because it bundles PostgreSQL, Auth, Row-Level Security (RLS) policies, and Realtime subscriptions together as hosted components [9]. Neon Postgres gives us only the first piece — a serverless, branchable Postgres database. That means for Greymatter LMS:

| What Supabase gave for free | What Greymatter LMS must do instead |
|---|---|
| Postgres hosting | Neon Postgres hosting (still just Postgres) |
| Auth | Clerk (already wired up in Part 3) |
| RLS policies enforcing tenant isolation | Manual `orgId`/`userId` checks in every query, written in our Server Actions |
| Realtime subscriptions | Not used in this series yet — Inngest handles our "reactivity" instead |

This is a deliberate trade-off worth internalizing now: every table we create below will include an `org_id` or `user_id` column that **we** are responsible for filtering on in application code, because there's no database-level policy doing it for us automatically.

---

## 3. Setting up Neon + Drizzle

```bash
cd infra/db
pnpm init
pnpm add drizzle-orm pg
pnpm add -D drizzle-kit @types/pg
```

```bash
# infra/db/.env
DATABASE_URL=postgresql://user:password@your-neon-host/greymatter?sslmode=require
```

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

**✅ Checkpoint:** Run `npx drizzle-kit studio` — it should connect to your Neon project and open a browser-based table viewer (currently empty, since we haven't defined any tables yet).

---

## 4. Defining the schema

The original data model gives us the core tables we need — courses, lessons, and the outputs workers write back [6]. Let's translate them into Drizzle, adding `org_id`/`user_id` columns everywhere since we no longer have RLS doing tenant isolation for us.

```typescript
// infra/db/schema.ts
import { pgTable, uuid, text, integer, timestamp } from "drizzle-orm/pg-core";

export const courses = pgTable("courses", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  title: text("title").notNull(),
  description: text("description"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Lessons table, adapted from the original schema [6]
export const lessons = pgTable("lessons", {
  id: uuid("id").primaryKey().defaultRandom(),
  courseId: uuid("course_id").references(() => courses.id),
  title: text("title"),
  content: text("content"),
  orderIndex: integer("order_index"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const enrollments = pgTable("enrollments", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: text("user_id").notNull(),
  courseId: uuid("course_id").references(() => courses.id),
  orgId: text("org_id").notNull(),
  createdAt: timestamp("created_at").defaultNow(),
});

export const submissions = pgTable("submissions", {
  id: uuid("id").primaryKey().defaultRandom(),
  courseId: uuid("course_id").references(() => courses.id),
  assignmentId: uuid("assignment_id"),
  userId: text("user_id").notNull(),
  orgId: text("org_id").notNull(),
  content: text("content"),
  createdAt: timestamp("created_at").defaultNow(),
});

// Where every worker's results land — grading, quizzes, tutor feedback, analytics [6]
export const workerResults = pgTable("worker_results", {
  id: uuid("id").primaryKey().defaultRandom(),
  submissionId: uuid("submission_id").references(() => submissions.id),
  workerName: text("worker_name").notNull(),
  resultType: text("result_type"), // "grading" | "quiz" | "tutor_feedback" | "analytics"
  resultData: text("result_data"), // JSON-stringified payload
  createdAt: timestamp("created_at").defaultNow(),
});
```

Notice the last table, `workerResults` — this is the single destination the original architecture describes for quiz generation output, grading results, summaries, tutor feedback, and analytics insights, all written by independent workers [6].

**✅ Checkpoint:** Run the migration:

```bash
npx drizzle-kit push
```

Then reopen `npx drizzle-kit studio` — you should now see five tables: `courses`, `lessons`, `enrollments`, `submissions`, and `worker_results`.

---

## 5. Connecting Neon to the Next.js app

```bash
cd apps/web
pnpm add drizzle-orm pg
```

```typescript
// apps/web/src/lib/db/index.ts
import { drizzle } from "drizzle-orm/node-postgres";
import { Pool } from "pg";
import * as schema from "../../../../../infra/db/schema";

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
export const db = drizzle(pool, { schema });
```

Don't forget to add `DATABASE_URL` to `apps/web/.env.local` too, pointing at the same Neon database.

---

## 6. The tenant-isolation check we owe ourselves

Since Neon has no RLS, every query touching `courses`, `submissions`, or `enrollments` must manually filter by `orgId`. Let's write our first real query function, replacing the `console.log` stub from Part 3:

```typescript
// apps/web/src/lib/db/queries.ts
import { db } from "./index";
import { enrollments, courses } from "../../../../../infra/db/schema";
import { eq, and } from "drizzle-orm";

export async function getCoursesForUser(userId: string, orgId: string) {
  return db
    .select({ id: courses.id, title: courses.title, description: courses.description })
    .from(courses)
    .innerJoin(enrollments, eq(enrollments.courseId, courses.id))
    .where(and(eq(enrollments.userId, userId), eq(courses.orgId, orgId)));
}
```

Wire this into the courses page from Part 3:

```tsx
// src/app/(dashboard)/courses/page.tsx
import { auth } from "@clerk/nextjs/server";
import { getCoursesForUser } from "@/lib/db/queries";

export default async function CoursesPage() {
  const { userId, orgId } = await auth();
  const courses = orgId ? await getCoursesForUser(userId!, orgId) : [];

  return (
    <div>
      <h2 className="mb-4 text-2xl font-bold text-slate-900">My Courses</h2>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {courses.map((course) => (
          <div key={course.id} className="rounded-lg border bg-white p-4 shadow-sm">
            <h3 className="font-semibold">{course.title}</h3>
            <p className="text-sm text-slate-500">{course.description}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
```

**✅ Checkpoint:** Manually insert a row into `courses` and a matching row into `enrollments` (via Drizzle Studio) using your real Clerk `userId`/`orgId`. Refresh `/courses` — your real data should now render instead of the hardcoded placeholder from Part 3.

---

## 7. Previewing the worker write-back pattern

We won't run real workers until Part 5–8, but here's the shape every worker will eventually use to write into `worker_results` — the same pattern the original tutorial describes as Markly grading, the quiz generator creating practice questions, Tutor AI generating feedback, and analytics updating dashboards, all off the back of one submission [6]:

```typescript
// Preview only — this will live in infra/inngest functions starting Part 5
async function saveWorkerResult(submissionId: string, workerName: string, resultType: string, data: unknown) {
  await db.insert(workerResults).values({
    submissionId,
    workerName,
    resultType,
    resultData: JSON.stringify(data),
  });
}
```

---

## 8. What's next

We now have a real, queryable Neon Postgres database, a schema covering courses, lessons, enrollments, submissions, and worker results, and a Next.js page reading live data through Drizzle with manual tenant checks standing in for Supabase's RLS. In Part 5, we build the Orchestration Layer — Inngest — and finally make `submitAssignment` do something real: emit an event that triggers actual workflow execution.

**🩹 Common confusion at this stage:** "Do I really have to remember to add `orgId` filters to *every single query* by hand?" — Yes, and this is the single biggest risk area in a non-RLS setup. In Part 9 (Hardening), we'll build a small internal helper/lint pattern to make it much harder to accidentally forget this check.

Ready? → **Part 5: Inngest Workflow Engine for Greymatter LMS**
