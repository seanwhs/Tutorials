# Greymatter LMS: Enterprise Architecture Design Document (EADD)

**System Name:** Greymatter LMS
**System Classification:** Extensible Enterprise Learning Management System
**Target Core Stack:** Next.js 16 (App Router), React 19, Sanity Studio v3 (Headless CMS), Clerk Core Auth, Neon Serverless PostgreSQL, Prisma ORM, Tailwind CSS
**Document Version:** 1.2.0 (Consolidated, Reconciled Against Parts 1–4 Implementation)

---

## 1. System Vision & Problem Domain

Traditional Enterprise Learning Management Systems suffer architectural degradation over time due to **Data Domain Conflation** — mixing heavy, slow-changing structural content with high-velocity transactional writes in a single database.

```
                                 [ TRADITIONAL LMS PATHOLOGY ]

     Heavy Structural Content (markdown, media metadata, quiz matrices)
                                               │
                                               ▼
                                   ┌──────────────────────┐
                                   │  SINGLE DATABASE     │ ◄─── High-Velocity Writes
                                   │  (e.g., MySQL, PG)   │      (progress, heartbeat,
                                   └──────────────────────┘      clicks, analytics)
                                               │
                       Result: Table bloat, performance degradation,
                               expensive migrations on content schema changes.
```

Greymatter LMS decouples content authoring from transactional state to achieve high performance and easy extensibility:

```
                                 [ GREYMATTER DECOUPLED PATHWAY ]

     [ Content Creator Workspace ]                      [ High-Frequency App Runtime ]
                   │                                                  │
                   ▼                                                  ▼
       ┌──────────────────────┐                           ┌──────────────────────┐
       │   SANITY HEADLESS    │                           │    NEON SERVERLESS   │
       │     (Read-Heavy)     │                           │     (Write-Heavy)    │
       └──────────────────────┘                           └──────────────────────┘
        Delivers nested JSON via                           Manages ACID relational
        highly-cached CDN edges.                           transactions at the edge.
```

---

## 2. Core Architectural Principles

1. **Strict Locality of Behavior (LoB):** Keep styling, presentation logic, and interaction constraints close to the component definitions they affect.
2. **The "Stateless Player" Pattern:** The core LMS runtime layout stays oblivious to _how_ a lesson is formatted or _what_ interactive mechanics run inside it — it acts merely as a container frame.
3. **Optimistic-First Execution:** The UI assumes server-bound mutations will succeed, capping perceived latency at client-side execution speed via React 19 transition features (`useOptimistic`, `useTransition`).
4. **Identity Boundary Discipline:** The system that proves *who you are* (Clerk) and the system that stores *what you're allowed to do* (Neon/Prisma `User.id`) are deliberately kept as two distinct identifiers, joined by exactly one field (`User.clerkId`), never conflated elsewhere in the schema.
5. **Isolated Trust Boundaries:** Untrusted developer components execute within constrained execution frames to prevent Cross-Site Scripting (XSS) and token theft — a defense layer scoped as a future-phase enhancement beyond this document's baseline implementation (see §5.2).

---

## 3. High-Level System Architecture

```
                     ┌───────────────────────────────────┐
                     │      Sanity.io Studio (CMS)        │
                     │  Content Authors Design Courses    │
                     └─────────────────┬───────────────────┘
                                       │ (Webhook Sync)
                                       ▼
                     ┌───────────────────────────────────┐
                     │      Sanity Edge Content Lake      │
                     │  Read-Only Course Definitions      │
                     │  Static Custom Module Blueprints   │
                     └─────────────────┬───────────────────┘
                                       │ (Shared Join Key: Sanity ID String)
                                       ▼
  ┌─────────────────────────────────────────────────────────────────────────┐
  │                           NEXT.JS CORE LAYER                            │
  │                                                                         │
  │   ┌───────────────────────────────┐     ┌───────────────────────────┐  │
  │   │     Dynamic Course Engine     │     │   Server Actions Engine    │  │
  │   │  Hydrates Sanity content      │     │  Guards state changes      │  │
  │   │  Renders custom module JSON   │     │  Wraps Prisma steps        │  │
  │   └───────────────┬───────────────┘     └─────────────┬─────────────┘  │
  └───────────────────┼───────────────────────────────────┼────────────────┘
                      │ (Queries Data)                    │ (Atomic Mutations)
                      ▼                                   ▼
          ┌───────────────────────┐           ┌───────────────────────┐
          │  Vercel Data Cache    │           │  Neon Serverless PG   │
          │  Tag-based invalidation│          │  Transaction Brain    │
          │  Blazing fast reads   │           │  Strict Prisma ORM    │
          └───────────────────────┘           └───────────────────────┘
```

Greymatter strictly segregates three concerns to ensure sub-100ms lesson rendering:

| Layer | Responsibility | Refresh Model |
|---|---|---|
| Static Layout | Global nav, workspace shell, sidebar indexes | Build-time / rarely revalidated |
| Read-Heavy Structure | Course/chapter/lesson content from Sanity | CDN-cached, webhook-revalidated |
| Transactional Data | Enrollment, progress, scores | Real-time, per-request via Neon |

### Request Lifecycle

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

### High-Performance Static Caching (`"use cache"`)

Next.js 16 stabilizes native caching directives. Lesson structures pulled from Sanity are wrapped in a cached context, remaining active until revalidated via webhook:

```typescript
// app/data/course-fetcher.ts
import { createClient } from "@sanity/client";

const sanity = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: "production",
  useCdn: true,
  apiVersion: "2026-07-17",
});

export async function getCachedLesson(lessonId: string) {
  "use cache";
  // Cache remains active until revalidated via webhook
  return await sanity.fetch(`*[_type == "lesson" && _id == $id][0]`, { id: lessonId });
}
```

---

## 4. Deep-Dive Data Architecture

### 4.1 Headless CMS Content Domain (Sanity)

Sanity acts as a document store. Because schemas are written in plain JavaScript/TypeScript, structural rules can be defined for content, media assets, and interactive component parameters.

```
                              [ SANITY CONTENT HIERARCHY ]

                              ┌────────────────────────┐
                              │     Course Schema      │
                              └───────────┬────────────┘
                                          │ (1-to-Many References)
                                          ▼
                              ┌────────────────────────┐
                              │     Chapter Schema     │
                              └───────────┬────────────┘
                                          │ (1-to-Many References)
                                          ▼
                              ┌────────────────────────┐
                              │     Lesson Schema      │
                              └───────────┬────────────┘
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼ (Rich Text Block Array — field: "body")       ▼ (Optional Extension Block)
       ┌──────────────────────┐                        ┌──────────────────────┐
       │  PortableText Block  │                        │     customModule     │
       │  (Paragraphs, Code)  │                        │  (Registry-bound JS) │
       └──────────────────────┘                        └──────────────────────┘
```

#### Sanity Schema Definitions (TypeScript)

The following schemas match the actual implementation, using Sanity's `defineField`/`defineType` helpers for full type inference in Studio — not plain object literals:

```typescript
// sanity/schemaTypes/course.ts
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

```typescript
// sanity/schemaTypes/chapter.ts
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

```typescript
// sanity/schemaTypes/lesson.ts
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
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title", maxLength: 96 },
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
      of: [
        { type: "block" }, // Standard Portable Text editor (headings, lists, strong, etc.)
        defineField({
          type: "object",
          name: "customModule",
          title: "Custom Interactivity Module",
          fields: [
            defineField({
              name: "moduleType",
              type: "string",
              title: "Module Key Identifier",
              description:
                'Must match a dynamic key in the Next.js ModuleRegistry (e.g. "sql-sandbox").',
              validation: (Rule) => Rule.required(),
            }),
            defineField({
              name: "configPayload",
              type: "text",
              title: "Module Config (JSON string)",
              description:
                "Arbitrary configuration passed as props to the resolved plugin component — must be valid JSON.",
              validation: (Rule) =>
                Rule.custom((value: string | undefined) => {
                  if (!value) return true; // optional field, empty is fine
                  try {
                    JSON.parse(value);
                    return true;
                  } catch (e) {
                    return "Must be a valid, parsable JSON string";
                  }
                }),
            }),
          ],
        }),
      ],
    }),
  ],
});
```

```typescript
// sanity/schemaTypes/index.ts
import { course } from "./course";
import { chapter } from "./chapter";
import { lesson } from "./lesson";

export const schemaTypes = [course, chapter, lesson];
```

Note that the lesson's rich-text field is named `body`, not `content` — this matters because every GROQ query in this document and in the reference implementation reads `body`, and a mismatch here would silently return `undefined` at query time rather than throwing a visible error.

---

### 4.2 Serverless Relational Database Domain (Neon PostgreSQL + Prisma)

Neon PostgreSQL scales down to zero during inactive periods to minimize hosting overhead. Under active load, connection pooling is handled through Neon's integrated transaction proxy (PgBouncer). Operational tables link to the unstructured CMS schema via plain `TEXT` string identifiers rather than foreign keys — completely avoiding expensive cross-database migrations and synchronizations.

A critical identity-boundary decision governs the `User` model specifically: **`User.id` is never the Clerk-issued identity string.** It is an internal, Prisma-generated `cuid()`, kept permanently distinct from `User.clerkId` (the external Clerk identity). This is not a stylistic choice — every `Enrollment` and `Progress` foreign key points at `User.id`, so if `id` and `clerkId` were ever conflated, changing auth providers in the future would require rewriting every transactional row in the database. Keeping them separate means only the `clerkId` column would need to change.

All primary keys across `User`, `Enrollment`, and `Progress` use Prisma's `cuid()` generator, producing `TEXT`-backed string values — **not** native Postgres `UUID` columns. This is a deliberate, single standard applied consistently across the schema, chosen because `cuid()` is collision-resistant, sortable-by-creation-time, and requires no `pgcrypto` extension or `dbgenerated()` call to produce.

#### Consolidated Database Model Matrix

| Model | Database Field Name | Data Type | Primary / Foreign Key / Index | Description |
| --- | --- | --- | --- | --- |
| **User** | `id` | `TEXT` (`cuid()`) | **Primary Key** | Internal identifier, distinct from Clerk's own user id. |
|  | `clerkId` | `TEXT` | `Unique Index` | The external Clerk User ID, synced via webhook. |
|  | `email` | `TEXT` | `Unique Index` | User email synced via webhook from Clerk. |
|  | `name` | `TEXT`, nullable | None | Optional display name. |
|  | `role` | `ENUM ('STUDENT', 'INSTRUCTOR', 'ADMIN')` | None | System permission level, defaults to `STUDENT`. |
| **Enrollment** | `id` | `TEXT` (`cuid()`) | **Primary Key** | Unique enrollment ID. |
|  | `userId` | `TEXT` | Foreign Key → `User.id` | Student enrolled — always the internal id. |
|  | `courseId` | `TEXT` | `Index` | References Sanity's `course._id` value. |
|  | `enrolledAt` | `TIMESTAMP` | None | Defaults to creation time. |
|  | — | — | `Unique(userId, courseId)` | Prevents duplicate enrollment; backs the compound lookup used in the transaction engine (§6). |
| **Progress** | `id` | `TEXT` (`cuid()`) | **Primary Key** | Unique progress tracker ID. |
|  | `userId` | `TEXT` | Foreign Key → `User.id` | Student tracking state — always the internal id. |
|  | `courseId` | `TEXT` | `Index` | References Sanity's `course._id`. Denormalized so course-scoped progress queries avoid a join. Required on every row. |
|  | `lessonId` | `TEXT` | `Index` | References Sanity's `lesson._id` value. |
|  | `completed` | `BOOLEAN` | None | Tracks whether the lesson has been completed. |
|  | `completedAt` | `TIMESTAMP`, nullable | None | Set when `completed` becomes `true`. |
|  | `score` | `INT`, nullable | None | Standardized percentage-based score (0 to 100). |
|  | `moduleState` | `JSON`, nullable | None | Raw, arbitrary storage for developer sandbox outputs. |
|  | — | — | `Unique(userId, lessonId)` | Guarantees exactly one progress row per student per lesson; backs the transaction engine's `upsert`. |

#### Prisma Schema

```prisma
// prisma/schema.prisma
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
  id          String       @id @default(cuid())
  clerkId     String       @unique
  email       String       @unique
  name        String?
  role        Role         @default(STUDENT)
  createdAt   DateTime     @default(now())
  updatedAt   DateTime     @updatedAt

  enrollments Enrollment[]
  progress    Progress[]
}

model Enrollment {
  id         String   @id @default(cuid())
  userId     String
  courseId   String   // Points directly to Sanity Course ID — no FK possible
  enrolledAt DateTime @default(now())

  user       User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, courseId])
  @@index([courseId])
}

model Progress {
  id          String    @id @default(cuid())
  userId      String
  courseId    String    // Denormalized for fast "progress by course" queries — required
  lessonId    String    // Points directly to Sanity Lesson ID
  completed   Boolean   @default(false)
  completedAt DateTime?
  score       Int?      // Nullable score ranging from 0 to 100
  moduleState Json?     // Nullable — arbitrary developer sandbox output

  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, lessonId])
  @@index([userId, courseId])
}
```

---

## 5. Security Architecture & Boundary Controls

Executing custom JavaScript components loaded dynamically introduces two major vulnerabilities: **Cross-Site Scripting (XSS)** and **Data Spoofing** (students sending fake "successful completion" payloads via simulated API requests).

The baseline implementation covered in this document (§6) addresses spoofing via server-side enrollment verification and score-bounds checking inside an atomic transaction. The two mechanisms below — iframe sandboxing and HMAC challenge/response — are **future-phase hardening layers**, not part of the current build. They're documented here because the plugin registry's architecture (a string `moduleType` resolved to a component, per §4.1) is designed to accommodate them without requiring a redesign, should Greymatter later need to run third-party-authored plugin code it doesn't fully trust.

### 5.1 Defense Path 1 (Future Phase): Sandboxing Untrusted Code

If a module is built by an untrusted third party, it should never execute in the client's parent frame. Instead, it would run inside a secure iframe container:

```tsx
// components/plugins/SandboxFrame.tsx
"use client";

import React, { useRef, useEffect } from "react";

interface SandboxFrameProps {
  moduleUrl: string;
  config: Record<string, any>;
  onComplete: (score: number, metadata: any) => void;
}

export function SandboxFrame({ moduleUrl, config, onComplete }: SandboxFrameProps) {
  const iframeRef = useRef<HTMLIFrameElement>(null);

  useEffect(() => {
    const handleMessage = (event: MessageEvent) => {
      // Security Check: Verify source matches target developer domain
      const trustedOrigins = ["https://trusted-modules.greymatter.com"];
      if (!trustedOrigins.includes(event.origin)) return;

      const { type, payload } = event.data;
      if (type === "MODULE_COMPLETE") {
        onComplete(payload.score, payload.metadata);
      }
    };

    window.addEventListener("message", handleMessage);
    return () => window.removeEventListener("message", handleMessage);
  }, [onComplete]);

  const sendConfigOnLoad = () => {
    if (iframeRef.current?.contentWindow) {
      iframeRef.current.contentWindow.postMessage(
        { type: "INITIALIZE", config },
        moduleUrl
      );
    }
  };

  return (
    <iframe
      ref={iframeRef}
      src={moduleUrl}
      onLoad={sendConfigOnLoad}
      sandbox="allow-scripts" // Blocks cookie and localStorage access
      className="w-full h-96 border border-slate-200 rounded-xl"
    />
  );
}
```

Note this is architecturally separate from the `ModuleRegistry` built in the current implementation — `ModuleRegistry` resolves `moduleType` to a **first-party, code-split React component** via `next/dynamic`, whereas `SandboxFrame` would be an alternative resolution path for third-party plugin URLs specifically. The two are not mutually exclusive: a future version of `resolveModule()` could check whether a given `moduleType` maps to a trusted first-party component or an untrusted iframe URL, and branch accordingly. No such branching exists in the current build — every registered module today is first-party code, rendered directly, with trust established through the transaction engine in §6 rather than iframe isolation.

### 5.2 Defense Path 2 (Future Phase): Cryptographic Hash Verification

For high-stakes exams or grading modules, client submissions should be verified using a standard HMAC cryptographic handshake.

When a lesson loads, the backend would issue a single-use token signed with a server secret. When the custom module finishes execution, it would need to return its progress output alongside this encrypted signature, preventing students from bypassing the UI and spoofing API requests directly against the Server Action.

```
1. Next.js Server ──(Generates Unique Lesson Salt)──► React Plugin Client
                                                             │
                                                     (Solves Challenge)
                                                             │
                                                             ▼
2. Next.js Server ◄──(Submits Response + Salt Hash)── React Plugin Client
         │
  [Server recalculates hash to verify score was legitimately earned]
```

As with §5.1, this is not implemented in the current build. The baseline defense actually shipped — enrollment verification inside an atomic transaction, plus server-side score-bounds checking — protects against the specific threat model of "a student tampers with the plugin's JS to fake a score," but does not protect against a sufficiently motivated attacker replaying a legitimate request with a forged score, since no cryptographic proof of *how* the score was derived is currently collected or checked. The HMAC handshake would close that gap; it's listed here as the documented next step for any module type where that residual risk is unacceptable (e.g., a proctored final exam).

---

## 6. The Secure Transaction Pipeline

Because modern frontends expose application variables directly to client runtimes, absolute security perimeter separation is required. Progress updates bypass traditional REST endpoints, routing instead through a heavily isolated, multi-stage Next.js Server Action wrapped in a strict relational database transaction block.

```
┌─────────────────────────┐
│ Client Custom Module    │
│ (e.g., SQL Sandbox UI)  │
└────────────┬────────────┘
             │ (Dispatches raw local analytics payloads)
             ▼
┌─────────────────────────┐
│ Next.js Server Boundary │
├─────────────────────────┴────────────────────────────────────────────────┐
│ 1. Identity Resolution: Extracts verified Clerk session, resolves it to  │
│    our own internal User.id via a User.clerkId lookup — never uses the  │
│    raw Clerk id against Enrollment/Progress directly.                   │
│ 2. Parameter Sanitization: Asserts structural bounds on dynamic variables.│
│                                                                           │
│ 3. Database Isolation Boundary ($transaction):                          │
│    ┌───────────────────────────────────────────────────────────────┐    │
│    │ Operational Assertions:                                       │    │
│    │ - Queries Enrollment row using composite user/course indexes. │    │
│    │ - Aborts explicitly (throws, triggering rollback) if the      │    │
│    │   relationship returns void.                                  │    │
│    │                                                               │    │
│    │ State Serialization:                                          │    │
│    │ - Executes atomic Upsert on target Progress rows, supplying  │    │
│    │   courseId on the create branch (required, non-nullable).    │    │
│    └───────────────────────────────┬───────────────────────────────┘    │
│                                    │                                     │
│                                    ▼ (On Success Commit)                 │
│ 4. Client Response: Returns a generic success/failure signal — never    │
│    the raw internal error message, which stays server-side only.        │
└──────────────────────────────────────────────────────────────────────────┘
```

### Complete Implementation

```typescript
// lib/auth/get-internal-user.ts
import { auth } from "@clerk/nextjs/server";
import { prisma } from "@/lib/prisma";

/**
 * Resolves the currently signed-in Clerk session down to our own
 * internal User.id. Enrollment.userId and Progress.userId are foreign
 * keys into User.id, NOT into Clerk's external id — this lookup is
 * mandatory before either table can be safely queried.
 */
export async function getInternalUserId(): Promise<string | null> {
  const { userId: clerkId } = await auth();
  if (!clerkId) return null;

  const user = await prisma.user.findUnique({
    where: { clerkId },
    select: { id: true },
  });

  return user?.id ?? null;
}
```

```typescript
// app/actions/progress.ts
"use server";

import { prisma } from "@/lib/prisma";
import { getInternalUserId } from "@/lib/auth/get-internal-user";

interface ModuleStateSchema {
  currentStep?: number;
  terminalLogs?: string[];
  executionHistory?: Array<{ timestamp: string; verified: boolean }>;
  [key: string]: unknown;
}

interface CompleteLessonPayload {
  courseId: string;
  lessonId: string;
  score?: number;
  moduleState?: ModuleStateSchema;
}

interface OperationalResponse {
  success: boolean;
  error?: string;
}

/**
 * Executes a structured Server Action protecting progress entries via
 * database isolation levels. Never trusts client-supplied identity or
 * an unbounded score; never leaks internal failure detail to the caller.
 */
export async function completeLesson(
  payload: CompleteLessonPayload
): Promise<OperationalResponse> {
  // 1. Resolve verified identity to our own internal User.id
  const userId = await getInternalUserId();
  if (!userId) {
    return {
      success: false,
      error: "You must be signed in to record progress.",
    };
  }

  const { courseId, lessonId, score, moduleState } = payload;
  if (!courseId || !lessonId) {
    return { success: false, error: "Missing courseId or lessonId." };
  }

  // 2. Strict application guardrails on client-provided data
  if (score !== undefined && (score < 0 || score > 100)) {
    return {
      success: false,
      error: "Transaction Integrity Violation: Score bound out of index.",
    };
  }

  try {
    // 3. Initiate database isolation context
    await prisma.$transaction(async (tx) => {
      const enrollment = await tx.enrollment.findUnique({
        where: {
          userId_courseId: { userId, courseId },
        },
      });

      if (!enrollment) {
        throw new Error(
          "Transaction Failed: Student has not enrolled in the parent course."
        );
      }

      await tx.progress.upsert({
        where: {
          userId_lessonId: { userId, lessonId },
        },
        update: {
          completed: true,
          completedAt: new Date(),
          score,
          moduleState: moduleState ?? {},
        },
        create: {
          userId,
          lessonId,
          courseId, // required, non-nullable — must be supplied on create
          completed: true,
          completedAt: new Date(),
          score,
          moduleState: moduleState ?? {},
        },
      });
    });

    return { success: true };
  } catch (error: any) {
    // Detailed failure reason stays server-side only.
    console.error("CRITICAL: Database transaction rollback executed:", error.message);
    return {
      success: false,
      error: "Failed to save lesson progress. Please try again.",
    };
  }
}
```

---

## 7. Advanced Data Hydration & Aggregation Strategy

To safely reconstruct complete system UI nodes without maintaining deep database joins, Greymatter leverages parallelized read mechanisms that combine unstructured CMS content with relational transactional state.

```typescript
// app/data/hydrate-course.ts
import { createClient } from "@sanity/client";
import { prisma } from "@/lib/prisma";
import { getInternalUserId } from "@/lib/auth/get-internal-user";
import { cache } from "react";

const sanity = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  useCdn: false, // false reads freshly generated content directly from Sanity's origin
  apiVersion: "2026-03-01",
});

export interface HydratedLesson {
  id: string;
  title: string;
  slug: string;
  cmsContent: unknown; // the lesson's "body" Portable Text array
  userProgress: {
    completed: boolean;
    completedAt: Date | null;
    score: number | null;
    moduleState: unknown;
  } | null;
}

/**
 * High-performance composite reader combining CMS unstructured arrays with
 * Neon database records. Resolves the caller's internal User.id once,
 * up front — never queries Progress using a raw Clerk session id.
 */
export const getHydratedCourseData = cache(async (courseId: string) => {
  const userId = await getInternalUserId();

  try {
    // A. Fetch the course structure from Sanity, including each lesson's
    //    real "body" field (not "content" — that field doesn't exist),
    //    walking through the chapters[] -> lessons[] reference chain.
    const sanityCourse = await sanity.fetch(
      `*[_type == "course" && _id == $courseId][0]{
        _id,
        title,
        "lessons": chapters[]->lessons[]->{
          _id,
          title,
          "slug": slug.current,
          body
        }
      }`,
      { courseId }
    );

    if (!sanityCourse) return null;

    // B. Fetch user progress scoped strictly to the current course's
    //    lesson set — but only if a signed-in, resolved user exists.
    //    An anonymous or not-yet-synced visitor sees content with no
    //    progress overlay, rather than throwing.
    const targetLessonIds = sanityCourse.lessons.map((l: any) => l._id);

    const specificProgress = userId
      ? await prisma.progress.findMany({
          where: {
            userId,
            lessonId: { in: targetLessonIds },
          },
        })
      : [];

    // Create a key-value hashmap for constant-time lookup performance
    const progressMap = new Map(specificProgress.map((p) => [p.lessonId, p]));

    // C. Perform non-destructive hydration, matching elements via shared
    //    Sanity document _id strings — never a true database join.
    const hydratedLessons: HydratedLesson[] = sanityCourse.lessons.map((lesson: any) => {
      const progress = progressMap.get(lesson._id);
      return {
        id: lesson._id,
        title: lesson.title,
        slug: lesson.slug,
        cmsContent: lesson.body,
        userProgress: progress
          ? {
              completed: progress.completed,
              completedAt: progress.completedAt,
              score: progress.score,
              moduleState: progress.moduleState,
            }
          : null,
      };
    });

    return {
      courseId: sanityCourse._id,
      courseTitle: sanityCourse.title,
      lessons: hydratedLessons,
    };
  } catch (error) {
    console.error("Aggregation Layer Exception Failure:", error);
    throw new Error("DATA_HYDRATION_FAILED: Multi-source record binding could not complete.");
  }
});
```

Two corrections from an earlier draft of this function are worth calling out explicitly, since both are easy to reintroduce by accident:

- **No `lesson.type` field.** An earlier version of this hydrator referenced `lesson.type: "text" | "interactive_sandbox" | "assessment"` and queried it directly from Sanity. No such field exists anywhere in the actual `lesson` schema (§4.1) — a lesson's "type" is implicit, derived entirely from whether its `body` array happens to contain a `customModule` block, not from an explicit enum. If a future iteration wants to classify lessons this way for filtering/UI purposes, it would need to be added as a real schema field first; referencing it here without that field existing would silently return `undefined` for every lesson.
- **`userId` is resolved once, before either fetch runs**, rather than assumed to be a valid parameter passed in from elsewhere. This function accepts only `courseId` — it derives `userId` internally via `getInternalUserId()`, consistent with every other data-access function in this document, so that no caller can accidentally pass in an unresolved Clerk id by mistake.

---

## 8. Summary Matrix: Component Field Mapping

| **Data Space / Target** | **Schema Model Type** | **Database Layer** | **Primary Key Format** | **Data Mapping Objective** |
| --- | --- | --- | --- | --- |
| **Auth System (External)** | Clerk User | Clerk Ecosystem | String ID (`user_...`) | Session management & identity proof — mirrored into `User.clerkId`, never into `User.id` |
| **Auth System (Internal)** | `User` | Neon DB (Prisma) | `TEXT` (`cuid()`) | Local identity record satisfying FK relationships for `Enrollment`/`Progress` |
| **Course Structuring** | `Course` / `Chapter` / `Lesson` | Sanity Studio | Sanity document `_id` (string) | Content delivery & module configurations |
| **Operational Maps** | `Enrollment` | Neon DB (Prisma) | `TEXT` (`cuid()`) | Validation checks & course-access tracking |
| **Runtime Aggregates** | `Progress` | Neon DB (Prisma) | `TEXT` (`cuid()`) | Real-time scores & interactive states |

---

## 9. Next Steps for Implementation

With the blueprint complete, implementation can proceed in the following order:

1. **Provision infrastructure:** Set up Sanity project/dataset, Neon database (with pooled + direct URLs), and Clerk application.
2. **Define schemas:** Deploy the `course` / `chapter` / `lesson` Sanity schemas (§4.1) and run the initial Prisma migration (§4.2), including the `User.clerkId` field and `Progress.courseId`/`score`/`moduleState` columns from the outset.
3. **Wire authentication:** Configure Clerk middleware, and sync users to the `User` table via webhook — upserting on `clerkId`, never on `id`.
4. **Build the Stateless Player:** Implement the RSC lesson page that performs parallel fetches (Sanity + Neon) and resolves `customModule.moduleType` against a client-side `ModuleRegistry`.
5. **Ship the baseline transaction engine:** Deploy `completeLesson` as a Server Action (§6), gated by resolved-identity checks, score-bound validation, and an enrollment-guarded atomic transaction — this is the security baseline actually shipped, not the future-phase mechanisms in §5.
6. **Enable caching/revalidation:** Wrap Sanity reads in `"use cache"`, and configure webhook-triggered cache revalidation scoped per course where applicable.
7. **(Optional, future phase) Harden high-stakes modules:** For graded/proctored content specifically, implement the `SandboxFrame` iframe isolation and/or HMAC salt-issuance handshake described in §5.1–5.2. Treat this as an additive layer on top of the baseline transaction engine, not a replacement for it.
8. **Load-test the decoupled path:** Confirm Sanity CDN reads stay sub-100ms and Neon writes remain isolated from content-read latency under concurrent load.

$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$



