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

To ensure sub-100ms lesson rendering, Greymatter strictly segregates Static Assets, Read-Heavy Structures, and Transactional Data at every stage of this pipeline [1].

## B.2 Stage One: Edge Middleware

Before any page component runs at all, the request passes through Next.js Edge Middleware, which performs the Clerk session check [1]. This is the earliest possible interception point — it runs geographically close to the student, before the main application logic even starts. If the session is invalid, the request never reaches the App Router page at all; it's redirected away immediately. This is exactly the `middleware.ts` file you built in Part 2, protecting every route under `/dashboard`.

## B.3 Stage Two: The App Router Page as a Server Component (RSC)

Once middleware confirms a valid session, the request reaches the actual page — implemented as a **React Server Component (RSC)**. This is the default behavior for any file inside the `app/` directory that does not declare `"use client"` at the top. Server Components run exclusively on the server, meaning they can directly `await` data-fetching functions without shipping that fetching logic (or its dependencies) to the browser at all.

## B.4 Stage Three: Parallel Fetching (A and B)

This is the heart of the hybrid architecture made mechanical. The Server Component simultaneously issues two independent fetches [1]:

- **Parallel Fetch A** — against Sanity's Content CDN, retrieving course/chapter/lesson structure and rich text content
- **Parallel Fetch B** — against Neon's database, retrieving the specific student's enrollment and progress records

Because these are `Promise`-based operations run together (for example, via `Promise.all`), neither fetch waits on the other to begin. The total time to gather both data sources is roughly the time of the *slower* of the two — not the sum of both — which is a key contributor to keeping lesson rendering fast.

## B.5 Stage Four: Combined Server Render

Once both fetches resolve, the Server Component merges this data into a single rendered output. This is where Sanity's content structure (what a lesson contains) and Neon's transactional state (whether the student has completed it) are combined into one coherent view — for example, a sidebar showing lesson titles from Sanity alongside checkmarks derived from Neon.

## B.6 Stage Five: Dynamic Component Resolution (RSC)

The final stage maps each Sanity `customModule.moduleType` string to an imported Client chunk via `React.lazy` [1]. This is precisely the `ModuleRegistry` you built in Part 3 using `next/dynamic` — Sanity's plain string identifier for a plugin (like `"sql-sandbox"`) gets resolved into the actual React component responsible for rendering that interactive experience. Because this resolution happens lazily, only the specific plugin components actually used on a given lesson page are downloaded to the browser, rather than every plugin that has ever been built.

## B.7 Where Server Actions Re-Enter the Lifecycle

The lifecycle diagram above describes the *initial* page load, but the story doesn't end once the page is rendered. When a student interacts with a Client Component plugin (like completing the SQL Sandbox), that component calls a **Server Action** — a function marked `'use server'` that securely re-enters server-side execution without a full page reload.

This is exactly the boundary implemented in the progress Server Action, which sits between the dynamic custom client module and the Neon SQL ledger [1]:

```typescript
// app/actions/progress.ts
'use server';

import { auth } from '@clerk/nextjs/server';
import { PrismaClient } from '@prisma/client';
import { revalidateTag } from 'next/cache';

const prisma = new PrismaClient();

interface ProgressPayload {
  lessonId: string;
  courseId: string;
  score: number;
  moduleState: any;
}

export async function submitLessonProgress({ lessonId, courseId, score, moduleState }: ProgressPayload) {
  const { userId } = await auth();

  if (!userId) {
    throw new Error('Unauthorized Access: User session was missing or expired.');
  }

  if (score < 0 || score > 100) {
    throw new Error('Transaction Integrity Violation: Score bound out of index.');
  }
  // ...transaction logic continues from here
}
```

Notice that this function re-establishes trust independently at every single invocation — it calls `auth()` fresh each time rather than trusting anything the client passed in, and it re-validates the score bounds before ever touching the database [1]. This is the critical distinction between the *initial render lifecycle* (Stages One through Five, which only ever *reads* data) and the *Server Action lifecycle* (which *writes* data): reads flow through Server Components during page load, while writes flow through Server Actions triggered by Client Component event handlers, at any point after the page has already rendered.

## B.8 Why This Division of Labor Matters

Each piece of this lifecycle exists specifically to keep responsibilities separated:

- **Middleware** decides *who* is allowed in, before anything else runs
- **Server Components** decide *what data* to gather and *how* to combine it, without shipping that logic to the browser
- **Dynamic Component Resolution** decides *which interactive code* the browser actually needs to download, minimizing unnecessary bundle size
- **Server Actions** decide *whether a write is legitimate*, independently re-verifying identity and data integrity every single time, regardless of what the client claims

Together, these five mechanisms form the complete data lifecycle of a Greymatter LMS page — from the first network request, through content and progress retrieval, all the way to a secure, verified database write triggered by student interaction [1].
