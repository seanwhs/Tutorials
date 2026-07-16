# Greymatter LMS: Enterprise Architecture Design Document (EADD)

**System Name:** Greymatter LMS

**System Classification:** Extensible Enterprise Learning Management System

**Target Core Stack:** Next.js 16 (App Router), React 19, Sanity Studio v3 (Headless CMS), Clerk Core Auth, Neon Serverless PostgreSQL, Prisma ORM, Tailwind CSS

**Document Version:** 1.0.0 (Production-Ready Spec)

---

## 1. System Vision & Problem Domain

Traditional Enterprise Learning Management Systems (LMS) suffer from severe architectural degradation over time due to **Data Domain Conflation**.

```
                                 [ TRADITIONAL LMS PATHOLOGY ]
                             
     Heavy Structural Content (Unstructured markdown, media metadata, quiz matrices)
                                               │
                                               ▼
                                   ┌──────────────────────┐
                                   │  SINGLE DATABASE     │ ◄─── High-Velocity Writes
                                   │  (e.g., MySQL, PG)   │      (User progress, heartbeat,
                                   └──────────────────────┘      clicks, analytics)
                                               │
                       Result: Table bloat, performance degradation, 
                               expensive migrations on content schema changes.

```

By decoupling content from transactions, **Greymatter LMS** achieves high performance and easy developer extensibility.

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

1. **Strict Locality of Behavior (LoB):** Keep styling, presentation logic, and interaction constraints close to the component definitions.
2. **The "Stateless Player" Pattern:** The core LMS runtime layout remains completely oblivious to *how* a lesson is formatted or *what* interactive mechanics are occurring inside it. It acts merely as a container frame.
3. **Optimistic-First Execution:** The UI immediately assumes server-bound mutations will succeed. UI latency is capped at the speed of client-side execution using React 19 transition features.
4. **Isolated Trust Boundaries:** Untrusted developer components must execute within constrained execution frames to prevent Cross-Site Scripting (XSS) and token theft.

---

## 3. Deep-Dive Data Architecture

### 3.1 Headless CMS Content Domain (Sanity)

Sanity acts as a document store. Because schemas are written in plain JavaScript/TypeScript, we can define structural rules for content, media assets, and interactive component parameters.

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

#### Sanity Schema Definition (TypeScript)

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

### 3.2 Serverless Relational Database Domain (Neon PostgreSQL + Prisma)

Neon PostgreSQL is configured to scale down to zero during inactive periods to minimize hosting overhead. Under active loads, connection pooling is handled through Neon's integrated transaction proxy.

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
  id           String    @id @default(dbgenerated("gen_random_uuid()")) @db.Uuid
  userId       String
  user         User      @relation(fields: [userId], references: [id], onDelete: Cascade)
  lessonId     String    // Points directly to Sanity Lesson ID
  completed    Boolean   @default(false)
  completedAt  DateTime?
  score        Int?      // Nullable score ranging from 0 to 100
  moduleState  Json?     // Stored complex objects from custom developer components
  updatedAt    DateTime  @updatedAt

  @@unique([userId, lessonId])
  @@index([userId])
  @@index([lessonId])
}

```

---

## 4. Next.js App Router Architecture & Request Lifecycle

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

To ensure sub-100ms lesson rendering, Greymatter strictly segregates Static Assets, Read-Heavy Structures, and Transactional Data:

### 1. Static Layout Elements

Global navigations, workspace layouts, and sidebar indexes are rendered as static skeletal trees.

### 2. High-Performance Static Caching (`"use cache"`)

Next.js 16 stabilizes native caching directives. When pulling lesson structures from Sanity, the data fetching logic is wrapped in a cached context:

```typescript
// app/data/course-fetcher.ts
import { createClient } from '@sanity/client';

const sanity = createClient({
  projectId: process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  dataset: 'production',
  useCdn: true,
  apiVersion: '2026-07-17',
});

// Leveraging Next.js 16's high performance cached functions
export async function getCachedLesson(lessonId: string) {
  "use cache";
  // Cache remains active until revalidated via webhook
  return await sanity.fetch(`*[_type == "lesson" && _id == $id][0]`, { id: lessonId });
}

```

---

## 5. Security Architecture & Boundary Controls

Executing custom JavaScript components loaded dynamically introduces two massive vulnerabilities: **Cross-Site Scripting (XSS)** and **Data Spoofing** (students sending successful completions through simulated API requests).

### 5.1 Defense Path 1: Sandboxing Untrusted Code

If the module is built by an untrusted third party, do not let it execute in the client's parent frame. Use a secure iframe container:

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

For high-stakes exams or grading modules, you should verify client submissions using a standard HMAC cryptographic handshake.

When the lesson loads, the backend issues a single-use token signed with a server secret. When the custom module finishes execution, it must return its progress output alongside this encrypted signature, preventing students from bypassing the UI and spoofing API requests.

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

## 6. Real-Time Transaction Engine (Server Action Setup)

Below is the clean Server Action configuration that secures the boundary between the dynamic custom client module and your Neon SQL ledger.

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
}

```

---

## 7. Next Steps for Implementation

Now that the blueprint is complete, you can start building:
