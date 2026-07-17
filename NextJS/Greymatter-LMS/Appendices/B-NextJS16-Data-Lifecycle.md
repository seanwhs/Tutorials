# Appendix B: Next.js 16 Data Lifecycle

This appendix breaks down how Server Components, Client Components, and Server Actions collaborate during a single page lifecycle in Greymatter LMS — the mechanical "how" behind the request flow you've been building across Parts 1 through 4.

## B.1 The Full Request Journey

Every request a student makes to a Greymatter dashboard page follows one consistent path, starting at the network edge and ending with a fully rendered, interactive page:

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

To ensure sub-100ms lesson rendering, Greymatter strictly segregates Static Assets, Read-Heavy Structures, and Transactional Data at every stage of this pipeline.

## B.2 Stage One: Edge Middleware

Before any page component runs at all, the request passes through Next.js Edge Middleware, which performs the Clerk session check. This is the earliest possible interception point — it runs geographically close to the student, before the main application logic even starts. If the session is invalid, the request never reaches the App Router page at all; it's redirected away immediately. This is exactly the `middleware.ts` file you built in Part 2, protecting every route under `/dashboard`.

## B.3 Stage Two: The App Router Page as a Server Component (RSC)

Once middleware confirms a valid session, the request reaches the actual page — implemented as a **React Server Component (RSC)**. This is the default behavior for any file inside the `app/` directory that does not declare `"use client"` at the top. Server Components run exclusively on the server, meaning they can directly `await` data-fetching functions without shipping that fetching logic (or its dependencies) to the browser at all.

## B.4 Stage Three: Parallel Fetching (A and B)

This is the heart of the hybrid architecture made mechanical. The Server Component simultaneously issues two independent fetches:

- **Parallel Fetch A** — against Sanity's Content CDN, retrieving course/chapter/lesson structure and rich text content
- **Parallel Fetch B** — against Neon's database, retrieving the specific student's enrollment and progress records

Because these are `Promise`-based operations run together (for example, via `Promise.all`, as in the Part 4 dashboard layout's `Promise.all([getCourseNavigation(), getCompletedLessonIds()])`), neither fetch waits on the other to begin. The total time to gather both data sources is roughly the time of the _slower_ of the two — not the sum of both — which is a key contributor to keeping lesson rendering fast.

## B.5 Stage Four: Combined Server Render

Once both fetches resolve, the Server Component merges this data into a single rendered output. This is where Sanity's content structure (what a lesson contains) and Neon's transactional state (whether the student has completed it) are combined into one coherent view — for example, a sidebar showing lesson titles from Sanity alongside checkmarks derived from Neon.

## B.6 Stage Five: Dynamic Component Resolution (RSC)

The final stage maps each Sanity `customModule.moduleType` string to an imported Client chunk via `React.lazy`. This is precisely the `ModuleRegistry` you built in Part 3 using `next/dynamic` — Sanity's plain string identifier for a plugin (like `"sql-sandbox"`) gets resolved into the actual React component responsible for rendering that interactive experience. Because this resolution happens lazily, only the specific plugin components actually used on a given lesson page are downloaded to the browser, rather than every plugin that has ever been built.

## B.7 Where Server Actions Re-Enter the Lifecycle

The lifecycle diagram above describes the _initial_ page load, but the story doesn't end once the page is rendered. When a student interacts with a Client Component plugin (like completing the SQL Sandbox), that component calls a **Server Action** — a function marked `"use server"` that securely re-enters server-side execution without a full page reload.

This is exactly the boundary implemented in the `completeLesson` Server Action built in Part 4, which sits between the dynamic custom client module and the Neon SQL ledger:

```typescript
// app/actions/progress.ts
"use server";

import { prisma } from "@/lib/prisma";
import { getInternalUserId } from "@/lib/auth/get-internal-user";

interface CompleteLessonPayload {
  courseId: string;
  lessonId: string;
  score?: number;
  moduleState?: Record<string, unknown>;
}

export async function completeLesson(payload: CompleteLessonPayload) {
  // Resolve Clerk's session identity down to our own internal User.id —
  // Enrollment.userId and Progress.userId are foreign keys into that
  // internal id, never into Clerk's raw session identity directly.
  const userId = await getInternalUserId();
  if (!userId) {
    return { success: false, error: "You must be signed in to record progress." };
  }

  const { courseId, lessonId, score, moduleState } = payload;

  if (score !== undefined && (score < 0 || score > 100)) {
    return {
      success: false,
      error: "Transaction Integrity Violation: Score bound out of index.",
    };
  }

  // ...transaction logic continues from here, and is the ONLY place
  // in this function that throws rather than returns — see below.
}
```

Two mechanical details are easy to miss but matter a great deal here:

**1. Identity resolution happens before anything else, and it's a lookup, not a passthrough.** `getInternalUserId()` doesn't just call Clerk's `auth()` and hand back whatever it returns — it uses that verified Clerk identity to look up the corresponding row in our own `User` table and returns *that* row's internal `id`. This matters because `auth()`'s `userId` is Clerk's external identity string, while `Enrollment.userId` and `Progress.userId` are foreign keys into `User.id` — a Prisma-generated `cuid()`, deliberately kept distinct back in Part 1 and Part 2. Skipping this resolution step and using Clerk's raw id directly against those tables would make every enrollment lookup fail silently, since nothing in `Enrollment` is ever keyed on that string.

**2. Not every guard in this function fails the same way, and that's intentional.** The identity check and the score-bounds check both `return { success: false, error: ... }` rather than throwing. The enrollment check, deeper inside the `$transaction` block, is the *only* place that throws:

```typescript
if (!enrollment) {
  throw new Error("Transaction Failed: Student has not enrolled in the parent course.");
}
```

The distinction isn't arbitrary. By the time execution reaches the enrollment check, we're already inside `prisma.$transaction(...)` — throwing there is what triggers Prisma's automatic rollback, guaranteeing that if the enrollment check fails, the subsequent `progress.upsert(...)` call never executes and nothing is written at all. The identity and score checks, by contrast, run *before* the transaction ever opens — there's nothing yet to roll back, so a plain early `return` is sufficient and avoids the overhead of opening a transaction that was never going to do anything anyway.

**3. There's no `revalidateTag` call, and that's also intentional.** It might seem natural to invalidate a cache entry here once a write succeeds, but Next.js's `revalidateTag` only invalidates cache entries created via `fetch(url, { next: { tags: [...] } })`. Nothing in this pipeline reads progress data that way — `getCompletedLessonIds()` queries Prisma directly — so a `revalidateTag(...)` call here would be a silent no-op, not real cache-invalidation logic. If a future part introduces `fetch()`-based caching for course-detail pages, that's the point at which a targeted `revalidatePath(...)` or `revalidateTag(...)` call would actually do something.

This is the critical distinction between the _initial render lifecycle_ (Stages One through Five, which only ever _reads_ data) and the _Server Action lifecycle_ (which _writes_ data): reads flow through Server Components during page load, while writes flow through Server Actions triggered by Client Component event handlers, at any point after the page has already rendered. And within the write path itself, there's a further distinction between guards that run *before* a transaction opens (fast-fail via `return`) and the one guard that runs *inside* the transaction, specifically because only that failure needs an atomic rollback.

## B.8 Why This Division of Labor Matters

Each piece of this lifecycle exists specifically to keep responsibilities separated:

- **Middleware** decides _who_ is allowed in, before anything else runs
- **Server Components** decide _what data_ to gather and _how_ to combine it, without shipping that logic to the browser
- **Dynamic Component Resolution** decides _which interactive code_ the browser actually needs to download, minimizing unnecessary bundle size
- **Server Actions** decide _whether a write is legitimate_ — resolving true internal identity rather than trusting Clerk's raw session id directly, independently re-verifying data integrity every single time regardless of what the client claims, and reserving transactional rollback specifically for the one check (enrollment) where a partial write would actually be dangerous

Together, these five mechanisms form the complete data lifecycle of a Greymatter LMS page — from the first network request, through content and progress retrieval, all the way to a secure, verified database write triggered by student interaction.
