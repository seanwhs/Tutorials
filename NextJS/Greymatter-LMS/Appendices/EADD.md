# Greymatter LMS: Enterprise Architecture Design Document (EADD)

**System Name:** Greymatter LMS
**System Classification:** Extensible Enterprise Learning Management System
**Target Core Stack:** Next.js 16 (App Router), React 19, Sanity Studio v3 (Headless CMS), Clerk Core Auth, Neon Serverless PostgreSQL, Prisma ORM, Tailwind CSS
**Document Version:** 1.1.0 (Consolidated Production-Ready Spec)

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
2. **The "Stateless Player" Pattern:** The core LMS runtime layout stays oblivious to *how* a lesson is formatted or *what* interactive mechanics run inside it — it acts merely as a container frame.
3. **Optimistic-First Execution:** The UI assumes server-bound mutations will succeed, capping perceived latency at client-side execution speed via React 19 transition features.
4. **Isolated Trust Boundaries:** Untrusted developer components execute within constrained execution frames to prevent Cross-Site Scripting (XSS) and token theft.

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
import { createClient } from '@sanity/client';

const sanity = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: 'production',
  useCdn: true,
  apiVersion: '2026-07-17',
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
                  ▼ (Rich Text Block Array)                       ▼ (Optional Extension Block)
       ┌──────────────────────┐                        ┌──────────────────────┐
       │  PortableText Block  │                        │     CustomModule     │
       │  (Paragraphs, Code)  │                        │  (Registry-bound JS) │
       └──────────────────────┘                        └──────────────────────┘
```

#### Sanity Schema Definitions (TypeScript)

```typescript
// schemas/course.ts
export const course = {
  name: 'course',
  type: 'document',
  title: 'Course Blueprint',
  fields: [
    { name: 'title', type: 'string', title: 'Course Title', validation: (Rule: any) => Rule.required() },
    { name: 'slug', type: 'slug', title: 'Slug', options: { source: 'title' } },
    { name: 'description', type: 'text', title: 'Short Description' },
    {
      name: 'chapters',
      type: 'array',
      title: 'Course Chapters',
      of: [{ type: 'reference', to: [{ type: 'chapter' }] }],
    },
  ],
};

// schemas/chapter.ts
export const chapter = {
  name: 'chapter',
  type: 'document',
  title: 'Chapter',
  fields: [
    { name: 'title', type: 'string', title: 'Chapter Title', validation: (Rule: any) => Rule.required() },
    {
      name: 'lessons',
      type: 'array',
      title: 'Lessons',
      of: [{ type: 'reference', to: [{ type: 'lesson' }] }],
    },
  ],
};

// schemas/lesson.ts
export const lesson = {
  name: 'lesson',
  type: 'document',
  title: 'Lesson',
  fields: [
    { name: 'title', type: 'string', title: 'Lesson Title', validation: (Rule: any) => Rule.required() },
    {
      name: 'content',
      type: 'array',
      title: 'Lesson Material',
      of: [
        { type: 'block' }, // Standard Portable Text editor (headings, lists, strong, etc.)
        {
          type: 'object',
          name: 'customModule',
          title: 'Custom Interactivity Module',
          fields: [
            {
              name: 'moduleType',
              type: 'string',
              title: 'Module Key Identifier',
              description: 'Must match a dynamic key in the Next.js ModuleRegistry.',
              validation: (Rule: any) => Rule.required(),
            },
            {
              name: 'configPayload',
              type: 'text',
              title: 'JSON Configurations',
              description: 'Paste valid JSON structure containing parameters passed to the developer widget.',
              initialValue: '{}',
              validation: (Rule: any) =>
                Rule.custom((value: string) => {
                  try {
                    if (value) JSON.parse(value);
                    return true;
                  } catch (e) {
                    return 'Must be a valid, parsable JSON string';
                  }
                }),
            },
          ],
        },
      ],
    },
  ],
};
```

---

### 4.2 Serverless Relational Database Domain (Neon PostgreSQL + Prisma)

Neon PostgreSQL scales down to zero during inactive periods to minimize hosting overhead. Under active load, connection pooling is handled through Neon's integrated transaction proxy. Operational tables link to the unstructured CMS schema via plain `VARCHAR(255)` string identifiers rather than foreign keys — completely avoiding expensive cross-database migrations and synchronizations.

#### Consolidated Database Model Matrix

| Model | Database Field Name | Data Type | Primary / Foreign Key / Index | Description |
| --- | --- | --- | --- | --- |
| **User** | `id` | `VARCHAR(255)` | **Primary Key** | Directly maps to the Clerk User ID. |
|  | `email` | `VARCHAR(255)` | `Unique Index` | User email synced via webhook from Clerk. |
|  | `role` | `ENUM ('STUDENT', 'INSTRUCTOR', 'ADMIN')` | None | System permission level. |
| **Enrollment** | `id` | `UUID` | **Primary Key** | Unique enrollment ID. |
|  | `userId` | `VARCHAR(255)` | Foreign Key -> `User.id` | Student enrolled. |
|  | `courseId` | `VARCHAR(255)` | `Index` | References Sanity's `course._id` value. |
| **Progress** | `id` | `UUID` | **Primary Key** | Unique progress tracker ID. |
|  | `userId` | `VARCHAR(255)` | Foreign Key -> `User.id` | Student tracking state. |
|  | `lessonId` | `VARCHAR(255)` | `Index` | References Sanity's `lesson._id` value. |
|  | `completed` | `BOOLEAN` | None | Tracks whether the lesson has been completed. |
|  | `score` | `INT` | None | Standardized percentage-based score (0 to 100). |
|  | `moduleState` | `JSONB` | None | Raw, arbitrary storage for developer sandbox outputs. |

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

model Progress {
  id          String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId      String
  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  lessonId    String    // Points directly to Sanity Lesson ID
  completed   Boolean   @default(false)
  completedAt DateTime?
  score       Int?      // Nullable score ranging from 0 to 100
  moduleState Json      @default("{}") // Stored complex objects from custom developer components
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  @@unique([userId, lessonId])
  @@index([userId])
  @@index([lessonId])
}
```

---

## 5. Security Architecture & Boundary Controls

Executing custom JavaScript components loaded dynamically introduces two major vulnerabilities: **Cross-Site Scripting (XSS)** and **Data Spoofing** (students sending fake "successful completion" payloads via simulated API requests).

### 5.1 Defense Path 1: Sandboxing Untrusted Code

If a module is built by an untrusted third party, it must never execute in the client's parent frame. Instead, it runs inside a secure iframe container:

```tsx
// components/plugins/SandboxFrame.tsx
'use client';

import React, { useRef, useEffect } from 'react';

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
      if (type === 'MODULE_COMPLETE') {
        onComplete(payload.score, payload.metadata);
      }
    };

    window.addEventListener('message', handleMessage);
    return () => window.removeEventListener('message', handleMessage);
  }, [onComplete]);

  const sendConfigOnLoad = () => {
    if (iframeRef.current?.contentWindow) {
      iframeRef.current.contentWindow.postMessage(
        { type: 'INITIALIZE', config },
        moduleUrl
      );
    }
  };

  return (
    <iframe
      ref={iframeRef}
      src={moduleUrl}
      onLoad={sendConfigOnLoad}
      sandbox="allow-scripts" // Blocks cookie and localStorage access!
      className="w-full h-96 border border-slate-200 rounded-xl"
    />
  );
}
```

---

### 5.2 Defense Path 2: Cryptographic Hash Verification

For high-stakes exams or grading modules, client submissions should be verified using a standard HMAC cryptographic handshake.

When a lesson loads, the backend issues a single-use token signed with a server secret. When the custom module finishes execution, it must return its progress output alongside this encrypted signature, preventing students from bypassing the UI and spoofing API requests.

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
│ 1. Context Auth Evaluation: Extracts verified token claims via Clerk.     │
│ 2. Parameter Sanitization: Asserts structural bounds on dynamic variables.│
│                                                                          │
│ 3. Database Isolation Boundary ($transaction):                          │
│    ┌───────────────────────────────────────────────────────────────┐    │
│    │ Operational Assertions:                                       │    │
│    │ - Queries Enrollment row using composite user/course indexes. │    │
│    │ - Aborts explicitly if relationship returns void.             │    │
│    │                                                               │    │
│    │ State Serialization:                                          │    │
│    │ - Executes atomic Upsert on target Progress rows.             │    │
│    └───────────────────────────────┬───────────────────────────────┘    │
│                                    │                                     │
│                                    ▼ (On Success Commit)                 │
│ 4. Cache Eviction Pipeline: Dispatches cache tag invalidation rules.     │
└──────────────────────────────────────────────────────────────────────────┘
```

### Complete Implementation

```typescript
// app/actions/progress.ts
'use server';

import { auth } from "@clerk/nextjs/server";
import { PrismaClient } from "@prisma/client";
import { revalidateTag } from "next/cache";

const prisma = new PrismaClient();

// Rigid custom types to structure the Dynamic JSON Payload data store
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
  transactionTimestamp?: string;
}

/**
 * Executes a highly structured Server Action protecting progress entries via database isolation levels.
 */
export async function completeLesson(payload: CompleteLessonPayload): Promise<OperationalResponse> {
  // 1. Establish strict server-side identity context
  const { userId } = await auth();
  if (!userId) {
    return {
      success: false,
      error: "UNAUTHORIZED_ACCESS_DENIED: Execution context missing authenticated session identifiers.",
    };
  }

  const { courseId, lessonId, score, moduleState } = payload;

  // 2. Strict application guardrails on client-provided data
  if (score !== undefined && (score < 0 || score > 100)) {
    return {
      success: false,
      error: "INTEGRITY_VIOLATION: Input score deviates outside established system baseline (0-100).",
    };
  }

  try {
    // 3. Initiate database isolation context
    await prisma.$transaction(async (tx) => {
      // Step A: Assert the student has a verified operational relationship with the parent course
      const enrollment = await tx.enrollment.findUnique({
        where: {
          userId_courseId: { userId, courseId },
        },
      });

      if (!enrollment) {
        throw new Error(
          "ENROLLMENT_NOT_FOUND: Mutation cancelled. Target user does not possess verified course clearance."
        );
      }

      // Step B: Atomically commit the progress status change
      await tx.progress.upsert({
        where: {
          userId_lessonId: { userId, lessonId },
        },
        update: {
          completed: true,
          completedAt: new Date(),
          score: score ?? null,
          moduleState: moduleState || {},
        },
        create: {
          userId,
          lessonId,
          completed: true,
          completedAt: new Date(),
          score: score ?? null,
          moduleState: moduleState || {},
        },
      });
    });

    // 4. Invalidate the relevant segment of the Data Cache
    revalidateTag(`progress-${courseId}`);

    return {
      success: true,
      transactionTimestamp: new Date().toISOString(),
    };

  } catch (error: any) {
    console.error(`FATAL SYSTEM TRANSACTION FAILURE — ROLLBACK INITIATED: ${error.message}`);
    return {
      success: false,
      error: error.message ?? "INTERNAL_SERVER_ERROR: Relational processing exception.",
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
import { PrismaClient } from "@prisma/client";
import { cache } from "react";

const sanity = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: process.env.NEXT_PUBLIC_SANITY_DATASET,
  useCdn: false, // Set false to read freshly generated content directly from edge nodes
  apiVersion: "2026-03-01",
});

const prisma = new PrismaClient();

// Data schemas enforcing structural design parity across system models
export interface HydratedLesson {
  id: string;
  title: string;
  slug: string;
  type: "text" | "interactive_sandbox" | "assessment";
  cmsContent: any;
  userProgress: {
    completed: boolean;
    completedAt: Date | null;
    score: number | null;
    moduleState: any;
  } | null;
}

/**
 * High-performance composite reader combining CMS unstructured arrays with Neon database records.
 * Uses Next.js tag-based data cache rules.
 */
export const getHydratedCourseData = cache(async (userId: string, courseId: string) => {
  try {
    // A. Fetch the course structure from Sanity
    const sanityCourse = await sanity.fetch(
      `*[_type == "course" && _id == $courseId][0]{
        _id,
        title,
        lessons[]->{
          _id,
          title,
          "slug": slug.current,
          type,
          body
        }
      }`,
      { courseId }
    );

    if (!sanityCourse) return null;

    // B. Fetch user progress scoped strictly to the current course's lesson set
    const targetLessonIds = sanityCourse.lessons.map((l: any) => l._id);
    const specificProgress = await prisma.progress.findMany({
      where: {
        userId,
        lessonId: { in: targetLessonIds },
      },
    });

    // Create a key-value hashmap for constant-time lookup performance
    const progressMap = new Map(specificProgress.map((p) => [p.lessonId, p]));

    // C. Perform non-destructive hydration, matching elements via shared ID string signatures
    const hydratedLessons: HydratedLesson[] = sanityCourse.lessons.map((lesson: any) => {
      const progress = progressMap.get(lesson._id);

      return {
        id: lesson._id,
        title: lesson.title,
        slug: lesson.slug,
        type: lesson.type,
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

---

## 8. Summary Matrix: Component Field Mapping

| **Data Space / Target** | **Schema Model Type** | **Database Layer** | **Primary Key Format** | **Data Mapping Objective** |
| --- | --- | --- | --- | --- |
| **Auth System** | `User` | Clerk Ecosystem | String ID (`user_...`) | Session management & user base context |
| **Course Structuring** | `Course` / `Chapter` / `Lesson` | Sanity Studio | String UUID / Hash Key | Content delivery & module configurations |
| **Operational Maps** | `Enrollment` | Neon DB Matrix | PostgreSQL UUID Key | Validation checks & purchase tracking |
| **Runtime Aggregates** | `Progress` | Neon DB Matrix | PostgreSQL UUID Key | Real-time scores & interactive states |

---

## 9. Next Steps for Implementation

With the blueprint complete, implementation can proceed in the following order:

1. **Provision infrastructure:** Set up Sanity project/dataset, Neon database (with pooled + direct URLs), and Clerk application.
2. **Define schemas:** Deploy the `course` / `chapter` / `lesson` Sanity schemas and run the initial Prisma migration.
3. **Wire authentication:** Configure Clerk middleware and sync users to the `User` table via webhook.
4. **Build the Stateless Player:** Implement the RSC lesson page that performs parallel fetches (Sanity + Neon) and resolves `customModule.moduleType` against a client-side `ModuleRegistry`.
5. **Implement trust boundaries:** Stand up the `SandboxFrame` iframe component and, for graded modules, the HMAC salt-issuance/verification handshake.
6. **Ship the transaction engine:** Deploy `completeLesson` as a Server Action, gated by enrollment checks and score-bound validation.
7. **Enable caching/revalidation:** Wrap Sanity reads in `"use cache"`, and configure webhook-triggered `revalidateTag` calls scoped per course.
8. **Load-test the decoupled path:** Confirm Sanity CDN reads stay sub-100ms and Neon writes remain isolated from content-read latency under concurrent load.
