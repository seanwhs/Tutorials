# Part 1: Architecture & Local Workspace Bootstrapping

By the end of this part, you will have: a running Next.js 16 app styled with Tailwind CSS, a local Sanity Studio embedded inside that same app with real `coursechapterlesson` schemas, a live Neon PostgreSQL database, and a Prisma schema modeling `User`, `Enrollment`, and `Progress` — fully migrated and ready to query.

## 1.0 System Design Recap (Read Before Coding)

**The Concept:** Recall from Part 0 that Greymatter splits its data into two brains. Here's the exact request lifecycle diagram again, because every folder we create in this part maps directly onto one node in this diagram:

```
[Student Request] ──► Next.js Edge Middleware (Clerk Session Check)
                                    │
                                    ▼
                          [App Router Page] (RSC)
                                    │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
         [Parallel Fetch A]              [Parallel Fetch B]
        Sanity Content CDN             Neon DB User Progress
                  │                               │
                  └───────────────┬───────────────┘
                                  ▼
                        Combined Server Render
                                  │
                                  ▼
                  [Dynamic Component Resolution] (RSC)
                  Maps Sanity customModule.moduleType
                  to imported Client chunk via React.lazy
```

Greymatter strictly segregates static assets, read-heavy structures, and transactional data specifically so a course page renders in under 100ms even under load [1]. In this part, "Parallel Fetch A" (Sanity) and "Parallel Fetch B" (Neon) both get built — but as two completely independent systems, so neither one knows the other exists yet. That's intentional; we're building foundations before wiring them together in Part 2.

---

## Step 1: Initialize the Next.js 16 Workspace with Tailwind CSS

**The Target:** A running Next.js 16 application, written in TypeScript, using the App Router, styled with Tailwind CSS, living inside your existing `greymatter-lms` folder from Part 0.

**The Concept:** `create-next-app` is a scaffolding tool — think of it like ordering a pre-assembled furniture frame instead of cutting your own wood. It gives you a working skeleton (build tooling, TypeScript config, folder conventions) so you spend your time on Greymatter's actual features, not on reinventing bundler configuration.

As of the current CLI, you no longer need to memorize a wall of flags (`--typescript --tailwind --eslint --app --src-dir=false --import-alias "@/*"`). The scaffolder now offers a single **"recommended defaults"** prompt that bundles the exact combination Greymatter needs: TypeScript, Tailwind CSS v4, ESLint, the App Router, no `src/` directory, and the `@/*` import alias. Turbopack is also on by default for `dev`/`build`.

**The Implementation:**

Since we already have a git-initialized folder from Part 0, run the scaffolder _inside_ it:

```bash
cd greymatter-lms
npx create-next-app@latest .
```

You'll see one prompt:

```
√ Would you like to use the recommended Next.js defaults? » Yes, use recommended defaults
```

Answer **Yes**. The CLI will then:

```
Creating a new Next.js app in C:\Users\seanw\Documents\greymatter-lms.
Using npm.
Initializing project with template: app-tw

Installing dependencies:
- next
- react
- react-dom

Installing devDependencies:
- @tailwindcss/postcss
- @types/node
- @types/react
- @types/react-dom
- eslint
- eslint-config-next
- tailwindcss
- typescript

Initialized a git repository.
Success! Created greymatter-lms at C:\Users\seanw\Documents\greymatter-lms
```

> **Note on existing files:** Your Part 0 `.gitignore` and `.env.example` sit quietly alongside the new files — recommended-defaults mode doesn't interactively ask about them the way flag-based invocations sometimes do, it just scaffolds around them. Run `git status` afterward if you want to confirm nothing from Part 0 was clobbered.

Verify the resulting tree looks like this (dotfiles hidden by default in `tree`):

```
.
├── AGENTS.md
├── CLAUDE.md
├── README.md
├── app
│   ├── favicon.ico
│   ├── globals.css
│   ├── layout.tsx
│   └── page.tsx
├── eslint.config.mjs
├── next-env.d.ts
├── next.config.ts
├── package-lock.json
├── package.json
├── postcss.config.mjs
├── public
│   ├── file.svg
│   ├── globe.svg
│   ├── next.svg
│   ├── vercel.svg
│   └── window.svg
└── tsconfig.json
```

This confirms all five defaults landed correctly: TypeScript (`tsconfig.json`), Tailwind v4 (`postcss.config.mjs` + `@tailwindcss/postcss`), ESLint (`eslint.config.mjs`), App Router (`app/` present), and no `src/` nesting (`app/` sits at repo root).

This generates (among other files) the following key files. Let's look at what matters:

#### `package.json` (relevant excerpt after scaffolding)

```json
{
  "name": "greymatter-lms",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint"
  },
  "dependencies": {
    "next": "^16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "typescript": "^5.6.0",
    "tailwindcss": "^4.0.0",
    "@tailwindcss/postcss": "^4.0.0",
    "eslint": "^9.0.0",
    "eslint-config-next": "^16.0.0"
  }
}
```

#### `app/globals.css`

Tailwind CSS v4 uses a **CSS-first configuration** — instead of a separate `tailwind.config.js` listing theme colors, you declare them directly inside your CSS using an `@theme` block. Replace the generated file with this, which adds Greymatter's brand color tokens:

```css
@import "tailwindcss";

@theme {
  /* Greymatter brand palette — used across buttons, sidebar, and accents */
  --color-brand-50: #f4f5f7;
  --color-brand-500: #4b5563;
  --color-brand-600: #374151;
  --color-brand-900: #111827;

  /* Semantic accent used for "lesson completed" checkmarks in Part 4 */
  --color-success-500: #22c55e;
}

body {
  background-color: var(--color-brand-50);
  color: var(--color-brand-900);
}
```

#### `app/layout.tsx`

```tsx
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Greymatter LMS",
  description: "A hybrid-architecture Learning Management System.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
```

#### `app/page.tsx`

Overwrite the generated starter page entirely (it ships with the default Next.js logo/links demo — discard all of it):

```tsx
export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h1 className="text-4xl font-bold text-brand-900">
        Greymatter LMS
      </h1>
      <p className="text-brand-600 max-w-md text-center">
        Workspace bootstrapped successfully. Tailwind CSS v4 is wired up
        and rendering with our custom brand theme tokens.
      </p>
      <span className="rounded-full bg-success-500 px-4 py-1 text-sm font-medium text-white">
        Step 1 verified ✓
      </span>
    </main>
  );
}
```

**The Verification:** Start the dev server and confirm everything renders correctly before moving forward.

```bash
npm run dev
```

Open `http://localhost:3000` in your browser. You should see:

- A heading "Greymatter LMS" in dark gray (`brand-900`)
- Descriptive paragraph text in a lighter gray (`brand-600`)
- A green pill-shaped badge reading "Step 1 verified ✓"

If the badge is unstyled (plain black text, no green background), Tailwind isn't processing correctly — double check that `app/globals.css` is imported in `app/layout.tsx` and that the dev server was restarted after editing the CSS file.

Since this scaffold uses Turbopack by default, the dev server should also print something like:

```
   ▲ Next.js 16.0.0 (Turbopack)
   - Local:        http://localhost:3000
   ✓ Ready in 800ms
```

If you instead see a webpack compiler banner, your global npm cache may have resolved an older `create-next-app` version — safe to ignore for this course, but worth rerunning `npx create-next-app@latest --version` later to confirm you're current.

Commit this checkpoint:

```bash
git add .
git commit -m "feat: bootstrap Next.js 16 workspace with Tailwind CSS v4"
```

---

## Step 2: Embed Sanity Studio Inside the Same Next.js App

**The Target:** A local Sanity Studio, running at `/studio` inside this same Next.js app (not a separate project/repo), with a real content schema for `course`, `chapter`, and `lesson` document types wired up and ready to author content in.

**The Concept:** Sanity ships an "embedded Studio" pattern: instead of running a separate Sanity app on its own port, you mount the entire Studio React application as a single catch-all route inside your existing Next.js app. This is exactly the "Sanity Content CDN" node from the Part 1.0 diagram — it's the authoring surface that eventually populates "Parallel Fetch A." Embedding it here means one repo, one `npm run dev`, one deploy target for both the authoring tool and the storefront.

**The Implementation:**

Install the Sanity toolkit alongside the Next.js integration package:

```bash
npm install sanity @sanity/vision next-sanity styled-components
```

> `styled-components` is a peer dependency of Sanity's Studio UI — without it, `/studio` will fail to render with a cryptic `use client` boundary error.

Create a Sanity project (skip if you already have one from a prior exercise):

```bash
npx sanity@latest init --env
```

Answer the prompts:
- **Create new project** → `Greymatter LMS`
- **Use the default dataset configuration** → `Yes` (dataset: `production`)
- **Project output path** → press Enter to accept the current directory
- **Select project template** → `Clean project with no predefined schemas`
- **Would you like to add configuration files for a Next.js project?** → `Yes`

This writes your `projectId` and `dataset` into `.env` (via the `--env` flag) as:

```bash
NEXT_PUBLIC_SANITY_PROJECT_ID="your-project-id"
NEXT_PUBLIC_SANITY_DATASET="production"
```

#### `sanity.config.ts` (project root)

```ts
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { visionTool } from "@sanity/vision";
import { schemaTypes } from "./sanity/schemaTypes";

export default defineConfig({
  name: "default",
  title: "Greymatter LMS",

  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID!,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET!,

  plugins: [structureTool(), visionTool()],

  schema: {
    types: schemaTypes,
  },
});
```

#### `sanity/schemaTypes/course.ts`

```ts
import { defineField, defineType } from "sanity";

export const course = defineType({
  name: "course",
  title: "Course",
  type: "document",
  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title", maxLength: 96 },
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "description",
      title: "Description",
      type: "text",
    }),
    defineField({
      name: "chapters",
      title: "Chapters",
      type: "array",
      of: [{ type: "reference", to: [{ type: "chapter" }] }],
    }),
  ],
});
```

#### `sanity/schemaTypes/chapter.ts`

```ts
import { defineField, defineType } from "sanity";

export const chapter = defineType({
  name: "chapter",
  title: "Chapter",
  type: "document",
  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "order",
      title: "Order",
      type: "number",
      validation: (Rule) => Rule.required().integer().min(0),
    }),
    defineField({
      name: "lessons",
      title: "Lessons",
      type: "array",
      of: [{ type: "reference", to: [{ type: "lesson" }] }],
    }),
  ],
});
```

#### `sanity/schemaTypes/lesson.ts`

```ts
import { defineField, defineType } from "sanity";

export const lesson = defineType({
  name: "lesson",
  title: "Lesson",
  type: "document",
  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (Rule) => Rule.required(),
    }),
    defineField({
      name: "order",
      title: "Order",
      type: "number",
      validation: (Rule) => Rule.required().integer().min(0),
    }),
    defineField({
      name: "videoUrl",
      title: "Video URL",
      type: "url",
    }),
    defineField({
      name: "body",
      title: "Body",
      type: "array",
      of: [{ type: "block" }],
    }),
  ],
});
```

#### `sanity/schemaTypes/index.ts`

```ts
import { course } from "./course";
import { chapter } from "./chapter";
import { lesson } from "./lesson";

export const schemaTypes = [course, chapter, lesson];
```

#### `app/studio/[[...tool]]/page.tsx`

This catch-all route is what mounts the entire Studio UI at `/studio`:

```tsx
"use client";

import { NextStudio } from "next-sanity/studio";
import config from "@/sanity.config";

export const dynamic = "force-static";

export default function StudioPage() {
  return <NextStudio config={config} />;
}
```

**The Verification:**

```bash
npm run dev
```

Open `http://localhost:3000/studio`. You should see the Sanity Studio UI load with a sidebar listing **Course**, **Chapter**, and **Lesson** document types. Create one test document of each type, and confirm a chapter can reference a lesson, and a course can reference a chapter, via the reference-array fields.

Commit this checkpoint:

```bash
git add .
git commit -m "feat: embed Sanity Studio with course/chapter/lesson schemas"
```

## Step 3: Provision a Live Neon PostgreSQL Database

**The Target:** A live, cloud-hosted PostgreSQL database on Neon's free tier, with a connection string saved to your local `.env` file — ready for Prisma to talk to in Step 4.

**The Concept:** This is "Parallel Fetch B" from the Part 1.0 diagram — the transactional side of Greymatter's split brain. Sanity (Step 2) holds slow-changing, read-heavy content: course titles, lesson bodies, video URLs. Neon holds fast-changing, per-user transactional state: who's enrolled in what, and how far they've gotten. These are different workloads with different consistency needs, which is why Greymatter uses two databases instead of stuffing everything into one. Neon specifically gives us serverless Postgres — it scales to zero when idle and spins up on the next request, which matters for a course-project budget where you don't want a database bill running 24/7.

**The Implementation:**

1. Go to [neon.com](https://neon.com) and sign up (GitHub OAuth is fastest).
2. Click **Create a project**.
   - **Project name** → `greymatter-lms`
   - **Postgres version** → leave default (17)
   - **Region** → pick whichever is closest to you
3. Once provisioned, Neon drops you on the project dashboard with a **Connection string** panel. Select:
   - **Pooled connection** → toggled **on** (this matters — Next.js serverless functions open/close connections frequently, and Neon's pooler prevents you from exhausting Postgres's connection limit)
4. Copy both connection strings shown — Neon gives you a pooled one (using port `5432` through PgBouncer, host containing `-pooler`) and, if you expand "direct connection," an unpooled one. You need both for Prisma in Step 4.

Add them to your `.env`:

```bash
# .env

# Pooled — used by the app at runtime (Prisma Client queries)
DATABASE_URL="postgresql://<user>:<password>@<host>-pooler.<region>.aws.neon.tech/greymatter-lms?sslmode=require"

# Unpooled — used only for migrations (Prisma needs a direct connection to run DDL)
DIRECT_URL="postgresql://<user>:<password>@<host>.<region>.aws.neon.tech/greymatter-lms?sslmode=require"
```

> **Why two URLs?** PgBouncer (Neon's pooler) operates in transaction mode, which doesn't support the session-level features Prisma Migrate needs (advisory locks, prepared statements) when running `migrate dev`. So the app queries through the fast pooled connection, but schema migrations go straight to Postgres via the direct connection. You'll see both wired into `schema.prisma` in Step 4.

Confirm `.env` is gitignored — it should already be, since your Part 0 `.gitignore` and this scaffold's generated one both exclude it:

```bash
git status
```

`.env` should **not** appear in the output. If it does, add `.env` to `.gitignore` immediately before committing anything else.

**The Verification:**

Test the connection directly with `psql` (or Neon's built-in SQL editor in the dashboard, if you don't have `psql` installed locally):

```bash
psql "$env:DIRECT_URL"
```

(On PowerShell, or use the literal connection string in quotes.) You should get a `psql` prompt like:

```
greymatter-lms=>
```

Run a trivial sanity check:

```sql
SELECT version();
```

You should see a Postgres 17 version string returned. Exit with `\q`.

There's nothing to commit in this step — you didn't create any tracked files, only external infrastructure and untracked `.env` entries. Confirm your working tree is still clean before moving on:

```bash
git status
```

## Step 4: Model `User`, `Enrollment`, and `Progress` with Prisma

**The Target:** A Prisma schema defining `User`, `Enrollment`, and `Progress` models, migrated against your live Neon database from Step 3, with the Prisma Client generated and ready to query.

**The Concept:** This is where "Parallel Fetch B" gets its actual shape. Sanity (Step 2) doesn't know these tables exist, and these tables don't know Sanity exists — that's intentional per the Part 1.0 diagram. `User` mirrors an authenticated learner (Clerk will own the actual auth identity later; this table just tracks the LMS-specific record tied to that identity). `Enrollment` is the join between a user and a course — but notice it stores a `courseId` as a plain string, **not** a foreign key or Prisma relation to anything in Sanity. Postgres has no concept of a Sanity document, so that ID is just an opaque reference Greymatter resolves manually in Part 2 when it stitches both fetches together. `Progress` tracks per-lesson completion state, same pattern: a `lessonId` string pointing at a Sanity document that Postgres can't see.

**The Implementation:**

Install Prisma:

```bash
npm install prisma --save-dev
npm install @prisma/client
npx prisma init
```

This scaffolds `prisma/schema.prisma` and a `.env` (already present from Step 3 — Prisma will just append if needed, so check for duplicate `DATABASE_URL` lines).

#### `prisma/schema.prisma`

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}

model User {
  id          String       @id @default(cuid())
  clerkId     String       @unique
  email       String       @unique
  name        String?
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt

  enrollments Enrollment[]
  progress    Progress[]
}

model Enrollment {
  id         String   @id @default(cuid())
  userId     String
  courseId   String   // opaque reference to a Sanity `course` document _id — no FK possible
  enrolledAt DateTime @default(now())

  user       User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, courseId])
  @@index([courseId])
}

model Progress {
  id          String    @id @default(cuid())
  userId      String
  lessonId    String    // opaque reference to a Sanity `lesson` document _id
  courseId    String    // denormalized for fast "progress by course" queries
  completed   Boolean   @default(false)
  completedAt DateTime?

  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, lessonId])
  @@index([userId, courseId])
}
```

A few design notes worth sitting with before you migrate:

- **`clerkId` vs `id`**: `id` is Prisma's own internal primary key (a `cuid()`), while `clerkId` is the external identity string Clerk will hand us in Part 2 middleware. Keeping them separate means if you ever needed to migrate auth providers, only `clerkId` changes — every `Enrollment` and `Progress` row keeps working because they reference the internal `id`.
- **`@@unique([userId, courseId])` on `Enrollment`**: prevents a user from double-enrolling in the same course — the database enforces this, not application code.
- **`courseId` denormalized onto `Progress`**: technically redundant (you could join through nothing, since there's no `Lesson` table to join to — Sanity owns lessons), but it lets Part 3's dashboard query "give me all progress rows for user X in course Y" with a single indexed lookup instead of fetching every progress row for the user and filtering in JS.

**Run the migration** against your Neon database:

```bash
npx prisma migrate dev --name init
```

You should see:

```
Environment variables loaded from .env
Prisma schema loaded from prisma/schema.prisma
Datasource "db": PostgreSQL database "greymatter-lms"

Applying migration `20250101000000_init`

The following migration(s) have been created and applied:

migrations/
  └─ 20250101000000_init/
    └─ migration.sql

Your database is now in sync with your schema.

✔ Generated Prisma Client
```

This does three things at once: writes a `migration.sql` file to `prisma/migrations/`, applies it to the Neon database via `DIRECT_URL`, and generates the Prisma Client into `node_modules/@prisma/client` so you can import it in app code.

#### `lib/prisma.ts` — a singleton client (needed so Next.js dev mode's hot-reload doesn't spawn a new Prisma Client on every file save, exhausting your connection pool)

```ts
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["query", "error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
```

**The Verification:**

First, inspect the tables visually:

```bash
npx prisma studio
```

This opens a local GUI at `http://localhost:5555`. Confirm you see three empty tables: `User`, `Enrollment`, `Progress`, matching the schema above.

Second, prove the client actually works end-to-end with a throwaway script:

#### `scripts/verify-prisma.ts`

```ts
import { prisma } from "@/lib/prisma";

async function main() {
  const user = await prisma.user.create({
    data: {
      clerkId: "test_clerk_id_123",
      email: "test@greymatter-lms.dev",
      name: "Test Student",
    },
  });

  const enrollment = await prisma.enrollment.create({
    data: {
      userId: user.id,
      courseId: "sanity-course-id-placeholder",
    },
  });

  const withRelations = await prisma.user.findUnique({
    where: { id: user.id },
    include: { enrollments: true, progress: true },
  });

  console.log("Created user with enrollment:", JSON.stringify(withRelations, null, 2));

  // Clean up — this was just a smoke test
  await prisma.enrollment.delete({ where: { id: enrollment.id } });
  await prisma.user.delete({ where: { id: user.id } });
  console.log("Cleanup complete. Prisma + Neon verified end-to-end. ✓");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
```

Run it:

```bash
npx tsx scripts/verify-prisma.ts
```

(If `tsx` isn't installed: `npm install --save-dev tsx`.)

You should see the created user logged with a nested `enrollments` array containing one row, followed by `Cleanup complete. Prisma + Neon verified end-to-end. ✓`. This confirms writes, relational includes, and deletes all round-trip correctly against the live Neon database — not just a local mock.

Delete the throwaway script (or leave it — it's harmless and handy for future debugging), then commit:

```bash
git add .
git commit -m "feat: add Prisma schema (User, Enrollment, Progress) migrated to Neon"
```

---

## Part 1 Recap

At this point your repo has two genuinely independent systems living side by side, exactly as the diagram in 1.0 promised:

- **`/studio`** — Sanity Studio, authoring `course` → `chapter` → `lesson` content, backed by Sanity's CDN.
- **`prisma/schema.prisma`** — `User`, `Enrollment`, `Progress` tables, migrated onto Neon Postgres, queryable via `lib/prisma.ts`.

Neither system has imported anything from the other. There's no code anywhere that takes a Sanity `course._id` and looks up a matching `Enrollment.courseId` — that stitching is explicitly deferred to **Part 2**, where Clerk middleware, the parallel-fetch page pattern, and the `moduleType` → `React.lazy` component resolution all get built on top of this foundation.


