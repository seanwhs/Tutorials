# Greymatter LMS: The Complete Build Series

Before we touch a single line of code, let's set the map on the table. You're about to build **Greymatter LMS** — a full-stack Learning Management System that separates "what content looks like" from "what a student has actually done" using two purpose-built engines instead of forcing one database to do everything.

Think of it like a restaurant: the **menu, recipes, and photos of dishes** rarely change and can be printed in bulk ahead of time (that's your content — courses, chapters, lessons). But **who ordered what, and whether they finished their meal** changes every second and must be tracked precisely (that's your transactional data — enrollments, progress, completions). Greymatter uses **Sanity.io** as the "printed menu" system and **Neon PostgreSQL + Prisma** as the "live order tracker." Separating these means a spike in students checking off lessons never slows down the rendering of your course catalog, and vice versa.

---

## The Full Series Roadmap

Here is the entire journey, so you always know where you are and what's coming next.

| Part | Title | What You'll Walk Away With |
|---|---|---|
| **Part 0** | Introduction to the Series *(this document)* | Mental model of the architecture, verified local toolchain, initialized project skeleton, Git repo, and environment variable scaffolding. |
| **Part 1** | Architecture & Local Workspace Bootstrapping | A running Next.js 16 + Tailwind app, a local Sanity Studio with `course`, `chapter`, `lesson` schemas, a provisioned Neon Postgres instance, and Prisma modeling `User`, `Enrollment`, `Progress`. |
| **Part 2** | Authentication & Core Navigation Shell | Clerk-protected routes via middleware, role assignment, a responsive collapsible-sidebar dashboard, and Sanity content rendered through the App Router. |
| **Part 3** | The React-Only Plugin Registry & Component Contract | A typed `@greymatter/plugin-sdk` contract, a `next/dynamic`-powered lazy-loading component registry, and a working "SQL Sandbox" interactive lesson plugin. |
| **Part 4** | Building the Secure State & Progress Transaction Engine | A Server Action + Prisma transaction that safely records progress, wired to React 19's `useOptimistic` for instant UI feedback. |
| **Appendix A** | The Hybrid Data Engine Concept | Deep dive on why content and transactions are split. |
| **Appendix B** | Next.js 16 Data Lifecycle | How Server Components, Client Components, and Server Actions hand off work to each other. |
| **Appendix C** | Code Segment Breakdown | Line-by-line dissection of the Prisma transaction and `next/dynamic` internals. |
| **Appendix D** | The Course → Chapter → Lesson Hierarchy & Progress Model Fields | A deeper look at the content schema hierarchy, where the `CustomModule` extension block fits, and a full reference to every `Progress` model field. |

Every part builds strictly on the previous one — nothing in Part 2 will require you to have "secretly known" something not yet taught in Part 0 or 1.

---

# Part 0: Introduction to the Series

### 0.1 The Target
Before writing framework code, our target for Part 0 is entirely **foundational**: a verified development toolchain, a clean project directory under version control, and an environment variable scaffold that documents every secret we will need across the whole series — even before we've created the accounts that generate those secrets.

### 0.2 The Concept: Why "Bootstrapping" Comes Before "Building"
Imagine building a house. You wouldn't pour the foundation for the kitchen before confirming your tools (hammer, level, drill) actually work and before marking out the property lines. In software, this "marking out the property lines" step is called **bootstrapping** — setting up the empty shell of a project (folder structure, version control, environment configuration) so that every subsequent step has a safe, predictable place to land. Skipping this is the single biggest cause of "it works on my machine" bugs later.

We're also going to explain **why** Greymatter is architected the way it is, because in later parts you'll be asked to write code (like Prisma transactions or Sanity schemas) that only makes sense once you understand the two-engine design.

---

## Step 1: Understand the Two Engines (Content vs. Transaction)

**The Target:** No code yet — a shared mental model everyone on the team (including future-you) can point to.

**The Concept:**
Greymatter's data lives in two separate "brains":

1. **The Content Brain (Sanity.io)** — a **headless CMS**, meaning a content database with no built-in webpage of its own; it just serves structured content (JSON) over an API for *any* frontend to consume. Sanity stores things that change rarely: course titles, chapter outlines, lesson text, and the definitions of interactive "modules" inside a lesson. Because schemas are just JavaScript/TypeScript objects, we can define strict rules for what a "lesson" or "course" is allowed to contain.
2. **The Transaction Brain (Neon PostgreSQL via Prisma)** — a traditional relational database that tracks **who did what, when**. This is where `User`, `Enrollment`, and `Progress` records live, exactly as laid out in the consolidated database model matrix: `User.id` maps directly to the Clerk User ID, `Enrollment.courseId` is an indexed string referencing Sanity's `course._id`, and `Progress.lessonId` is an indexed string referencing Sanity's `lesson._id` [1]. Neon is a **serverless Postgres** provider, meaning the database automatically "scales down to zero" — shutting down compute when nobody is using it — so you pay nothing (or close to it) during idle periods, and it wakes back up on the next request through Neon's built-in connection pooling proxy.

**Why split them at all?** If you stored every lesson's rich text *and* every student's click-by-click progress in the same relational table, a popular course being viewed by thousands of students would compete for the same database connections needed to record a single student's checkbox click. Splitting "read-heavy, rarely-changing content" from "write-heavy, per-user transactional data" means these two workloads never block each other.

Here's the exact request flow you'll be building toward — this is the diagram you should keep open in a tab while working through Part 1 and Part 2:

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

Notice the "Parallel Fetch A / Parallel Fetch B" split — this is the two-engine design made literal in code: one request goes to Sanity's CDN for content, another goes to Neon for the student's personal progress, and Next.js combines them into a single rendered page. This design is what lets Greymatter target **sub-100ms lesson rendering** by strictly segregating static assets, read-heavy structures, and transactional data.

**The Verification:** There's no code to run yet for Step 1 — it's a conceptual checkpoint. Before moving on, make sure you can answer these three questions out loud (or to a rubber duck):

1. "If 10,000 students are viewing a course's chapter list right now, which system serves that request — Sanity or Neon?" *(Answer: Sanity — it's read-heavy, rarely-changing content.)*
2. "If one student clicks 'Mark Lesson Complete,' which system records that?" *(Answer: Neon, via Prisma — it's a per-user transactional write.)*
3. "Why does Next.js fetch from both in parallel instead of one-after-the-other?" *(Answer: so a slow write to the transaction engine never delays the rendering of static content, and vice versa.)*

If you can answer all three without looking back, you're ready to move forward.

---

## Step 2: Verify Your Local Toolchain

**The Target:** Confirm Node.js, a package manager, and Git are correctly installed before any project files exist.

**The Concept:** This is the "check your hammer isn't broken before swinging it" step. Every tool in this series — Next.js, Prisma, Sanity's CLI — runs on top of Node.js. If your Node version is too old, half the errors you'll hit later will be red herrings caused by an outdated runtime, not your actual code.

**The Implementation:** Open your terminal and run:

```bash
node -v
```

You should see `v20.x` or higher (Next.js 16 requires a modern LTS Node release). If you see anything below `v18`, install the latest LTS from nodejs.org before continuing.

```bash
npm -v
git --version
```

Both should return version numbers without errors.

**The Verification:** Your terminal output should resemble:

```
v20.14.0
10.7.0
git version 2.43.0
```

If any command says "command not found," stop here and install that tool before proceeding — every later step assumes these three exist.

---

## Step 3: Create the Project Directory and Initialize Git

**The Target:** An empty, version-controlled folder named `greymatter-lms` that will hold every file we create for the rest of the series.

**The Concept:** Git is like a "save game" system for your code — it lets you snapshot your progress after each step so that if something breaks in Part 3, you can compare it against a known-good checkpoint from Part 1 instead of guessing what changed.

**The Implementation:**

```bash
mkdir greymatter-lms
cd greymatter-lms
git init
```

Create a `.gitignore` file at the project root so secrets and generated files never get committed:

#### `.gitignore`
```
# Dependencies
node_modules/

# Next.js build output
.next/
out/

# Environment secrets — never commit these
.env
.env.local
.env*.local

# Prisma generated client
node_modules/.prisma

# Sanity
.sanity/

# OS/editor noise
.DS_Store
*.log
```

**The Verification:**

```bash
git status
```

You should see `.gitignore` listed as an untracked file, and nothing else complaining. Commit this first checkpoint:

```bash
git add .gitignore
git commit -m "chore: initialize repository and gitignore"
```

---

## Step 4: Scaffold the Environment Variable Contract

**The Target:** A `.env.example` file that documents *every* secret the entire series will eventually need — even though we haven't created the Sanity project, Neon database, or Clerk app yet.

**The Concept:** Think of `.env.example` as a packing checklist you write before a trip, before you've actually bought any of the items. By writing down every credential name up front, later parts of this series become "fill in this blank" instead of "figure out what variable name to invent." It also means anyone cloning your repo instantly knows what accounts they need to create, without reading through every file.

Two of these variable names — `DATABASE_URL` and `DIRECT_URL` — come directly from how Prisma's `datasource` block is configured: `DATABASE_URL` is the pooled connection Neon gives your app for normal queries, while `DIRECT_URL` is used for non-pooled direct migration runs [1].

**The Implementation:**

#### `.env.example`

```bash
# ── Database (Neon Serverless PostgreSQL + Prisma) ──────────────────────────
# Pooled connection string — used by the running app for normal queries.
DATABASE_URL="postgresql://user:password@ep-example-pooler.region.aws.neon.tech/greymatter?sslmode=require"
# Direct (non-pooled) connection string — used only for running migrations.
DIRECT_URL="postgresql://user:password@ep-example.region.aws.neon.tech/greymatter?sslmode=require"

# ── Sanity.io (Content Registry) ────────────────────────────────────────────
NEXT_PUBLIC_SANITY_PROJECT_ID=""
NEXT_PUBLIC_SANITY_DATASET="production"
NEXT_PUBLIC_SANITY_API_VERSION="2024-01-01"
SANITY_API_READ_TOKEN=""

# ── Clerk (Authentication) ──────────────────────────────────────────────────
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=""
CLERK_SECRET_KEY=""
NEXT_PUBLIC_CLERK_SIGN_IN_URL="/sign-in"
NEXT_PUBLIC_CLERK_SIGN_UP_URL="/sign-up"

# ── App Config ───────────────────────────────────────────────────────────────
NEXT_PUBLIC_APP_URL="http://localhost:3000"
```

Now copy it to a real (untracked) `.env` file so your local setup has a place to eventually paste real secrets into:

```bash
cp .env.example .env
```

**The Verification:**

```bash
git status
```

You should see `.env.example` listed as untracked (good — we *want* to commit this one), but **`.env` should not appear**, because `.gitignore` is already excluding it. If `.env` shows up in `git status`, stop and double-check your `.gitignore` spelling before continuing — leaking real secrets into Git history is one of the most common beginner mistakes.

Commit the template:

```bash
git add .env.example
git commit -m "chore: scaffold environment variable contract"
```

---

## Step 5: Preview What You're Building Toward (Forward Reference)

**The Target:** No new files — just a preview so Part 1 doesn't feel like it's coming out of nowhere.

**The Concept:** It helps to see the destination before starting the drive. In Part 1, you'll write a Prisma schema that defines a `User` and an `Enrollment` model, plus the `datasource` and `generator` blocks that make Prisma work at all. Here's the complete preview, exactly as it will appear in Part 1 [1]:

```prisma
datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL") // Used for non-pooled direct migration runs
}

generator client {
  provider = "prisma-client-js"
}

enum Role {
  STUDENT
  INSTRUCTOR
  ADMIN
}

model User {
  id          String       @id
  email       String       @unique
  role        Role         @default(STUDENT)
  enrollments Enrollment[]
  progress    Progress[]
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt

  @@index([email])
}

model Enrollment {
  id        String   @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  courseId  String   // Points directly to Sanity Course ID
  createdAt DateTime @default(now())

  @@unique([userId, courseId])
  @@index([courseId])
}
```

A few things worth noticing now, so they feel familiar rather than new in Part 1:

- **`datasource db { ... }`** — this block is where `DATABASE_URL` and `DIRECT_URL`, the two variables you just scaffolded in Step 4, actually get used [1]. `url` (pooled) is what your running app uses for everyday queries; `directUrl` (non-pooled) is used only when running schema migrations.
- **`enum Role`** — this restricts the `User.role` field to exactly three fixed values (`STUDENT`, `INSTRUCTOR`, `ADMIN`) at the database level, rather than trusting every part of your app to type the string correctly. You'll see why this matters when Clerk assigns roles in Part 2.
- **`Enrollment.courseId` is a plain `String`, not a foreign key** — it deliberately points at a Sanity document ID rather than another Postgres table. That single line *is* the hybrid architecture in practice: Postgres tracks the relationship ("this user is enrolled in this course"), while Sanity owns what that course actually *is*.

And in Part 4, you'll write a Server Action that wraps a progress-completion write in a Prisma transaction — first checking that an enrollment exists, and only then recording progress, all inside one atomic operation so a student can never have "progress" on a course they were never enrolled in. Here's the complete pattern you'll build, shown in full now as a preview [1]:

```ts
try {
  await prisma.$transaction(async (tx) => {
    // 1. Assert registration status exists before saving progress
    const enrollment = await tx.enrollment.findUnique({
      where: {
        userId_courseId: { userId, courseId }
      }
    });

    if (!enrollment) {
      throw new Error('Transaction Failed: Student has not enrolled in the parent course.');
    }

    // 2. Upsert progress state safely
    await tx.progress.upsert({
      where: {
        userId_lessonId: { userId, lessonId }
      },
      update: {
        completed: true,
        completedAt: new Date(),
        score,
        moduleState: moduleState || {},
      },
      create: {
        userId,
        lessonId,
        completed: true,
        completedAt: new Date(),
        score,
        moduleState: moduleState || {},
      }
    });
  });

  // Clear static client cache paths for this specific course
  revalidateTag(`progress-${courseId}`);
  return { success: true };

} catch (error: any) {
  console.error('CRITICAL: Database transaction rollback executed: ', error.message);
  return { success: false, error: 'Failed to write completed execution progress.' };
}
```

**Why this matters as a preview:** notice the whole thing is wrapped in `prisma.$transaction(...)`. Think of a database transaction like an "all-or-nothing" checkout at a store — either every item in your cart gets rung up and paid for, or if something fails partway (a card decline), *none* of it goes through. Here, that means: if the enrollment check fails, the progress upsert never happens — the database never ends up in a half-finished, inconsistent state [1]. You don't need to write this code yet; just notice the shape, because in Part 4 we'll build it piece by piece, explaining `findUnique`, `upsert`, and `$transaction` individually before assembling them.

**The Verification:** Since this step was purely a "preview read," there's nothing to run. Just confirm you can point to which env variable (`DATABASE_URL` vs `DIRECT_URL`) each line in the `datasource` block uses, and why `courseId` on `Enrollment` is a plain string instead of a foreign key relation — if both make sense, you're ready to close out Part 0.

---

## Closing Out Part 0

**Final checkpoint commit:**

```bash
git add .
git status   # confirm only .gitignore and .env.example are staged — never .env
git commit -m "chore: complete Part 0 bootstrap - toolchain verified, env contract scaffolded"
```

### What You Have Right Now
- A clear mental model of Greymatter's two-engine (Content vs. Transaction) architecture
- A verified Node.js/npm/Git toolchain
- A Git-initialized `greymatter-lms` project folder
- A `.gitignore` protecting secrets from ever being committed
- A complete `.env.example` documenting every credential the entire series will need
- A preview understanding of the `User` and `Enrollment` Prisma models and the enrollment-verifying transaction pattern you'll build in Part 4 [1]

### What's Next
**Part 1: Architecture & Local Workspace Bootstrapping** picks up immediately from here — you'll run `create-next-app` inside this exact folder, install Tailwind CSS, initialize a local Sanity Studio with real `course`, `chapter`, `lesson` schemas, provision an actual Neon Postgres instance, and run your first Prisma migration against the schema you just previewed [1].
