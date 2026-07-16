# Part 4 — Data Modelling: Designing the Greymatter LMS Database *(Expanded & Enriched)*

In Part 3, we built the Next.js 16 frontend shell — route groups, Clerk auth, a Tailwind dashboard, and a Server Action stub that stops short of any business logic [6]. Now we build the system of record: the database itself.

**🎯 Goal of this lesson:** Design and implement the full Greymatter LMS schema in Neon Postgres using Drizzle ORM in place of Supabase, and understand exactly what we lose — and must replace ourselves — by not having Supabase's built-in Auth and Row-Level Security [6].

**🧰 Prereqs:** Part 3 completed. You'll need a free Neon account (neon.tech) — create a project and copy your connection string before section 2 [6].

---

## 1. Why Neon, not Supabase — what we lose and must replace

Before writing any schema, it's worth being explicit about a tradeoff made back in Part 1. The original architecture notes use Supabase for the Data Layer, with Row-Level Security enforcing tenant isolation directly in the database [12]. Greymatter LMS uses Neon Postgres instead, which means we take on two responsibilities Supabase used to hand us for free:

| Responsibility | Supabase (original) | Greymatter (Neon) |
|---|---|---|
| Database hosting | Supabase Postgres | Neon Postgres (serverless, branchable) |
| Auth | Supabase Auth | Clerk |
| Tenant isolation | Row-Level Security (RLS) policies | Enforced in application code via Drizzle ORM queries, checked against the Clerk `orgId` |
| Client SDK | `@supabase/supabase-js` | Drizzle ORM + plain SQL via `pg` |

Every time a future lesson mentions "Supabase enforces X," in Greymatter LMS that job moves to **our server code**, not the database itself [12]. This part is where we build that properly.

---

## 2. Setting up Neon + Drizzle

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

**✅ Checkpoint:** Run `npx drizzle-kit studio` — it should connect to your Neon project and open a browser-based table viewer (currently empty, since we haven't defined any tables yet) [6].

---

## 3. Designing the full schema, all at once

Looking ahead, Part 12's deployment checkpoint confirms Greymatter LMS ultimately needs five core tables — `courses`, `lessons`, `enrollments`, `submissions`, `worker_results` — plus a `workflow_logs` table added later in Part 10 [9]. Rather than introducing these piecemeal, let's define all five now in one file, so nothing downstream imports a table that doesn't exist yet.

```typescript
// infra/db/schema.ts
import { pgTable, uuid, text, timestamp, integer, boolean, jsonb } from "drizzle-orm/pg-core";

export const courses = pgTable("courses", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  title: text("title").notNull(),
  description: text("description"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const lessons = pgTable("lessons", {
  id: uuid("id").primaryKey().defaultRandom(),
  courseId: uuid("course_id").notNull().references(() => courses.id),
  title: text("title").notNull(),
  content: text("content"),
  order: integer("order").default(0),
});

export const enrollments = pgTable("enrollments", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  courseId: uuid("course_id").notNull().references(() => courses.id),
  studentId: text("student_id").notNull(),
  enrolledAt: timestamp("enrolled_at").defaultNow(),
});

export const submissions = pgTable("submissions", {
  id: uuid("id").primaryKey().defaultRandom(),
  orgId: text("org_id").notNull(),
  studentId: text("student_id").notNull(),
  courseId: uuid("course_id").notNull().references(() => courses.id),
  content: text("content").notNull(),
  status: text("status").default("submitted"),
  createdAt: timestamp("created_at").defaultNow(),
});

export const workerResults = pgTable("worker_results", {
  id: uuid("id").primaryKey().defaultRandom(),
  submissionId: uuid("submission_id").notNull().references(() => submissions.id),
  workerName: text("worker_name").notNull(),
  resultType: text("result_type").notNull(),
  data: jsonb("data"),
  success: boolean("success").default(true),
  createdAt: timestamp("created_at").defaultNow(),
});
```

Note that `orgId` appears on every top-level table (`courses`, `enrollments`, `submissions`) — this is deliberate, and it's the exact column every future query must filter on, since Neon gives us no automatic Row-Level Security to fall back on [12].

**✅ Checkpoint:** Run `npx drizzle-kit push`, then reopen `npx drizzle-kit studio`. Confirm all five tables now appear, empty but real.

---

## 4. Connecting Neon to the Next.js app

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

Don't forget to add `DATABASE_URL` to `apps/web/.env.local` too, pointing at the same Neon database [6].

**✅ Checkpoint:** From a Server Action or a temporary test file in `apps/web`, run `db.query.courses.findMany()` and confirm it resolves without a connection error (an empty array is expected — we haven't inserted any courses yet).

---

## 5. Enforcing tenant isolation without RLS

Since Supabase's RLS is gone, every query touching `courses`, `enrollments`, or `submissions` must manually filter by `orgId`, matched against the signed-in user's Clerk organization [12]. For example:

```typescript
// apps/web/src/app/(dashboard)/courses/queries.ts
import { auth } from "@clerk/nextjs/server";
import { db } from "@/lib/db";
import { courses } from "../../../../../infra/db/schema";
import { eq } from "drizzle-orm";

export async function getMyCourses() {
  const { orgId } = await auth();
  if (!orgId) throw new Error("Unauthorized");

  return db.query.courses.findMany({
    where: eq(courses.orgId, orgId),
  });
}
```

This pattern — re-checking `auth()` and filtering by `orgId` inside every query — is the single most important habit to build now. It's reinforced again in Part 9's threat model, which explicitly lists "cross-tenant data leakage" as a threat whose defense is "manual `orgId` checks in every query (Part 4), now reinforced inside Inngest steps" [1].

**✅ Checkpoint:** Temporarily hardcode a different `orgId` in a test query and confirm it returns zero rows for your test account's courses — proving the filter is actually doing something, not just decorative.

---

## 6. What's next

We now have a real system of record — five tables in Neon Postgres, connected to our Next.js app, with manual tenant isolation replacing what Supabase's RLS would have given us for free. In Part 5, we build the Orchestration Layer itself and finally make our `submitAssignment` Server Action stub emit a real event — `assignment.submitted` — that Inngest can pick up and act on.

**🩹 Common confusion at this stage:** "Why define `worker_results` now if no worker exists yet?" — Because Part 5's Inngest function will need somewhere to persist results the moment it starts running, and Part 7 onward assumes this table already exists. Defining the full schema up front means every later part can `import` from `infra/db/schema` without hitting a missing-table error.

Ready? → **Part 5: Inngest Workflow Engine — Building the Greymatter LMS Orchestration Layer**
