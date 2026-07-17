# Appendix A: The Hybrid Data Engine Concept

This appendix is a deep dive into the single most important architectural decision behind Greymatter LMS: why we deliberately split our data across two completely separate systems — Sanity.io for content, and Neon PostgreSQL for transactions — instead of putting everything in one database.

## A.1 The Core Problem: Two Very Different Kinds of Data

Every piece of data in a Learning Management System falls into one of two buckets, and these buckets behave very differently under load:

**Content data** — course titles, chapter outlines, lesson text, embedded plugin configuration — changes _rarely_. An instructor might edit a lesson once a week. But this data is _read constantly_: potentially thousands of students loading the same course page simultaneously.

**Transactional data** — enrollments, lesson completions, quiz scores, module state snapshots — changes _constantly_. Every click of "mark complete," every quiz submission, every sandbox run generates a write. But each individual write only matters to one specific student at a time.

If you stored both kinds of data in a single relational database, these two workloads would compete for the exact same resources: the same connection pool, the same table locks, the same query planner attention. A surge of students all completing a popular lesson at once (write-heavy transactional traffic) could measurably slow down the rendering of that same course's static content for everyone else browsing it (read-heavy content traffic) — even though these two activities have nothing logically to do with each other.

## A.2 Why Splitting Prevents Bottlenecking

Greymatter's architecture solves this by giving each workload its own dedicated engine, matched to its actual usage pattern:

- **Sanity.io (Content Registry)** — a headless CMS backed by a global CDN. Course, chapter, and lesson documents are fetched from cached, geographically-distributed edge nodes rather than a single origin database. Because content rarely changes, this cache stays valid for long periods, meaning the vast majority of student requests for course content never even touch Sanity's origin servers.
- **Neon Serverless PostgreSQL (Transaction Engine)** — a relational database purpose-built for exactly the kind of small, frequent, per-user writes that `Enrollment` and `Progress` records represent. Being serverless, Neon automatically scales its compute up during bursts of activity (e.g., many students completing lessons at the end of a class period) and back down to zero when idle, so the transactional workload never has to "borrow" capacity from — or compete with — anything content-related.

Neither of these two systems shares infrastructure, connection pools, or query engines with the other. A spike in one workload structurally cannot degrade the performance of the other, because they are, quite literally, two different databases running on two different platforms.

## A.3 The Data Model Seam: `courseId` and `lessonId` as Plain Strings

The clearest evidence of this split, visible directly in the database schema itself, is that the `Enrollment` and `Progress` tables never store a real foreign-key relationship into course or lesson content. Instead, they store plain indexed string references, as shown in the consolidated database model matrix:

| Model | Database Field Name | Data Type | Primary / Foreign Key / Index | Description |
|---|---|---|---|---|
| **User** | `id` | `TEXT` (`cuid()`) | **Primary Key** | Internal identifier — a Prisma-generated `cuid()`, deliberately distinct from Clerk's own user id. |
| | `clerkId` | `TEXT` | `Unique Index` | The external Clerk User ID. Kept separate from `id` so that if auth providers ever changed, only this column would need to migrate — every `Enrollment`/`Progress` row keeps working unmodified since they reference `id`, not `clerkId`. |
| | `email` | `TEXT` | `Unique Index` | User email synced via webhook from Clerk. |
| | `role` | `ENUM ('STUDENT', 'INSTRUCTOR', 'ADMIN')` | None | System permission level, defaults to `STUDENT`. |
| **Enrollment** | `id` | `TEXT` (`cuid()`) | **Primary Key** | Unique enrollment ID. |
| | `userId` | `TEXT` | Foreign Key → `User.id` | Student enrolled — references the internal `id`, never `clerkId` directly. |
| | `courseId` | `TEXT` | `Index` | References Sanity's `course._id` value. Opaque to Postgres — no FK possible, since the referenced row doesn't live in this database. |
| | `enrolledAt` | `TIMESTAMP` | None | Defaults to the time the enrollment row was created. |
| | — | — | `Unique(userId, courseId)` | Prevents a student from double-enrolling in the same course; this is also the exact constraint `completeLesson`'s transaction relies on to look up enrollment status atomically. |
| **Progress** | `id` | `TEXT` (`cuid()`) | **Primary Key** | Unique progress tracker ID. |
| | `userId` | `TEXT` | Foreign Key → `User.id` | Student tracking state — again, the internal `id`. |
| | `lessonId` | `TEXT` | `Index` | References Sanity's `lesson._id` value. |
| | `courseId` | `TEXT` | `Index` | Denormalized from the parent course specifically so "all progress for user X in course Y" can be answered with a single indexed lookup, without a join. Required on every row — the completion transaction cannot write a `Progress` record without it. |
| | `completed` | `BOOLEAN` | None | Defaults to `false`; flips to `true` once the student satisfies the plugin's completion condition. |
| | `completedAt` | `TIMESTAMP`, nullable | None | Set the moment `completed` becomes `true`. |
| | `score` | `INTEGER`, nullable | None | Bounds-checked server-side to the range 0–100 before ever being written. |
| | `moduleState` | `JSON`, nullable | None | Arbitrary structured snapshot reported by the plugin (e.g. the exact query a student submitted). |
| | — | — | `Unique(userId, lessonId)` | Makes the transaction's `upsert` deterministic — exactly one progress row can ever exist per student per lesson. |

Notice that `courseId` and `lessonId` are indexed for fast lookup, but they are **not** foreign keys pointing at another table inside the same Postgres database — because the thing they reference (a course or a lesson) doesn't live in Postgres at all. It lives in Sanity. This is the hybrid architecture made concrete: Postgres is only ever responsible for answering "did this user do this thing," while Sanity is solely responsible for answering "what is this thing." Neither database needs to understand the other's internal structure — they're joined only logically, at the application layer, by matching these string identifiers together at render time.

The two `@@unique` constraints deserve special attention, because they're not just data-integrity housekeeping — they're the literal mechanism the progress-tracking transaction engine (Part 4) depends on. `tx.enrollment.findUnique({ where: { userId_courseId: { userId, courseId } } })` only works because Prisma auto-generates that compound lookup key from the `@@unique([userId, courseId])` constraint; without it, there'd be no fast, guaranteed-unique way to ask "is this student enrolled in this course?" inside an atomic transaction. The same is true of `@@unique([userId, lessonId])` on `Progress`, which is what makes the `upsert` in `completeLesson` safe to call repeatedly without ever accidentally creating duplicate progress rows for the same lesson.

Meanwhile, `User.id` is its own internal primary key — a Prisma-generated `cuid()` — and is kept deliberately distinct from `User.clerkId`, which mirrors the Clerk User ID. `User.email` and `User.clerkId` are kept in sync via a webhook fired from Clerk, meaning even _identity_ data flows through this same "mirror, don't merge" pattern: Clerk owns the authentication system of record, and our own `User` table is simply a lightweight local copy sufficient to satisfy foreign-key relationships inside Postgres. Every Server Action that touches `Enrollment` or `Progress` first resolves a request's Clerk session down to this internal `id` before running any query — conflating the two, even briefly, would cause every enrollment and progress lookup to silently fail, since those tables never store a raw Clerk identity string at all.

## A.4 Why This Matters for Interactive Plugins Specifically

This same separation extends into Greymatter's plugin system. A lesson's rich content is a Portable Text block array, but it also supports an optional extension block — the `customModule` — sitting alongside standard paragraph and code blocks. This hierarchy flows directly from Course, to Chapter, to Lesson, and finally splits into two paths at the content level:

```
Course Schema
      │ (1-to-Many References)
      ▼
Chapter Schema
      │ (1-to-Many References)
      ▼
Lesson Schema
      │
┌─────┴─────────────────────────┐
▼ (Rich Text Block Array)       ▼ (Optional Extension Block)
PortableText Block          customModule
(Paragraphs, Code)          (Registry-bound JS)
```

Sanity stores only a `moduleType` key and a JSON `configPayload` string for that block — it has no idea what a "SQL Sandbox" actually is or how it behaves; that logic is "registry-bound," meaning it lives entirely in application JavaScript (the `ModuleRegistry` built in Part 3), not in Sanity's content model. When a student completes that sandbox, the resulting `score` and `moduleState` are written to Neon's `Progress` table, not back into Sanity. This keeps interactive, per-student results entirely inside the transaction engine, while the _definition_ of what interactivity is available stays entirely inside the content engine — reinforcing the same boundary at every layer of the system, not just at the top-level course/enrollment relationship.

## A.5 Summary

The hybrid data engine is not an incidental implementation detail — it is the organizing principle of the entire Greymatter architecture. By ensuring content reads (Sanity) and transactional writes (Neon) never share infrastructure, connection pools, or table locks, and by connecting the two only through plain, indexed string identifiers (`courseId`, `lessonId`) rather than true foreign keys, the system guarantees that a spike in one workload can never silently degrade the performance of the other. That same discipline extends inward, too: even within Postgres itself, `User.id` and `User.clerkId` are kept deliberately separate, so that the boundary between "who Clerk says you are" and "who our own database says you are" is never allowed to blur — a distinction that turned out to matter a great deal once real Server Actions started depending on it in Part 4.
