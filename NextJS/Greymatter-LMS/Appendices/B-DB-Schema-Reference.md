# Appendix B (Expanded) — Database Schema Reference

This expanded reference documents every table in GreyMatter LMS's Neon PostgreSQL database in full detail: every field with its type, constraints, and rationale; every relationship, with a complete entity-relationship diagram; every index and why it exists; and realistic, copy-pasteable Drizzle query examples for each table. Use this as the authoritative reference any time you need to recall exactly why a column exists, what depends on it, or how to query it correctly.

---

## B.1 The complete entity-relationship diagram

```text
                                   ┌──────────────┐
                                   │    users     │
                                   │──────────────│
                                   │ id (PK)      │
                                   │ auth_provider│
                                   │ _id (unique) │
                                   │ email(unique)│
                                   │ role         │
                                   └──────┬───────┘
                                          │
            ┌───────────────┬────────────┼────────────┬────────────────┬───────────────┐
            │               │            │            │                │               │
            ▼               ▼            ▼            ▼                ▼               ▼
   ┌────────────────┐ ┌───────────┐ ┌──────────┐ ┌──────────────┐ ┌───────────┐ ┌──────────────┐
   │  enrollments   │ │module_    │ │certifi-  │ │notification_ │ │audit_logs │ │notifications │
   │────────────────│ │attempts   │ │cates     │ │preferences   │ │(nullable  │ │              │
   │ id (PK)        │ │───────────│ │──────────│ │──────────────│ │ user_id)  │ │              │
   │ user_id (FK)   │ │ user_id   │ │ user_id  │ │ user_id      │ │           │ │ user_id (FK) │
   │ course_id(text)│ │ (FK)      │ │ (FK)     │ │ (FK, unique) │ │           │ │              │
   │ status         │ │ lesson_id │ │course_id │ └──────────────┘ └───────────┘ └──────────────┘
   │ enrolled_at    │ │ (text)    │ │(text)    │
   │ UQ(user,course)│ │ module_id │ │cert_num  │
   └───────┬────────┘ │ (text)    │ │(unique)  │
           │           │ attempt#  │ │course_   │
           │           │ submission│ │title(snap)│
           │           │ score     │ │recipient_│
           │           │ is_correct│ │email(snap)│
           │           │idempotency│ │UQ(user,  │
           │           │_key       │ │  course) │
           │           │UQ(user,   │ └──────────┘
           │           │ module,   │
           │           │ attempt#) │
           │           │UQ(user,   │
           │           │ module,   │
           │           │ idem_key) │
           │           └───────────┘
           │
           ├──────────────────────┬─────────────────────┐
           ▼                      ▼                     │
   ┌────────────────┐     ┌──────────────────┐           │
   │lesson_progress │     │ course_progress   │◄──────────┘
   │────────────────│     │───────────────────│  (enrollment_id FK)
   │ id (PK)        │     │ id (PK)            │
   │ user_id (FK)   │     │ user_id (FK)       │
   │enrollment_id   │     │enrollment_id (FK)  │
   │ (FK)           │     │ course_id (text)   │
   │ course_id(text)│     │completion_%        │
   │ lesson_id(text)│     │last_visited_lesson_ │
   │ status         │     │  id (text)         │
   │completed_at    │     │last_visited_at     │
   │UQ(user,lesson) │     │last_activity_at    │
   └────────────────┘     │UQ(user,course)     │
                           └────────────────────┘

   ┌────────────────┐     ┌──────────────────┐
   │webhook_events  │     │ workflow_events   │
   │────────────────│     │───────────────────│
   │ id (PK)        │     │ id (PK)           │
   │ source         │     │ event_name        │
   │ event_type     │     │ payload (jsonb)   │
   │ external_id    │     │ status            │
   │ payload (jsonb)│     │created_at/        │
   │ processed_at   │     │  processed_at     │
   │UQ(source,      │     │ (no FK — system-  │
   │  external_id)  │     │  level, no owner) │
   └────────────────┘     └──────────────────┘

   Legend:
   PK = Primary Key    FK = Foreign Key    UQ = Unique constraint
   (text) = plain string, NOT a foreign key — points into SANITY, a
            separate system Postgres cannot validate referentially
```

**The single most important thing this diagram shows:** every arrow pointing *into* `users` is a real, Postgres-enforced foreign key with `onDelete: cascade` (except `audit_logs`, which uses `onDelete: set null`). Every `(text)` field pointing conceptually *out* toward Sanity is **not** a foreign key at all — it's a plain string that our application code is solely responsible for validating, every single time, via the course-scoped query patterns established in Part 4 and Part 11.

---

## B.2 Table-by-table field reference

### `users`

The anchor table. Every other table's `user_id` foreign key ultimately points here.

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | Internal, stable identity — used by every foreign key in the system. Never exposed to Clerk or Sanity. |
| `auth_provider_id` | `text` | `NOT NULL`, `UNIQUE` | — | Clerk's external user ID (`user_xxx`). The bridge Part 6 built between authentication and our data model. |
| `email` | `text` | `NOT NULL`, `UNIQUE` | — | Synchronized from Clerk on `user.created`/`user.updated`. Used for certificates (Part 13) and reminder emails (Part 14). |
| `role` | `user_role` enum | `NOT NULL` | `'STUDENT'` | One of `STUDENT`, `INSTRUCTOR`, `ADMIN`. Enforced at the database level — an invalid role string can never be inserted, regardless of application-layer bugs. |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` | Account creation time. |
| `updated_at` | `timestamptz` | `NOT NULL` | `now()` | Bumped on every `updateUserByAuthProviderId` call (Part 6). |

**Why `auth_provider_id` and not `id` is what Clerk sees:** this indirection is deliberate. If GreyMatter ever needed to migrate away from Clerk to a different auth provider, only this one column's *meaning* would need to change — every other table's foreign keys, which point at the stable internal `id`, would be completely unaffected.

**Sample queries:**

```ts
// Find by Clerk ID — the single most common lookup in the entire app,
// called on nearly every authenticated request via getCurrentUser().
const user = await db.query.users.findFirst({
  where: eq(users.authProviderId, clerkUserId),
});

// Promote a role (Part 15's manual admin script pattern)
await db.update(users)
  .set({ role: "INSTRUCTOR", updatedAt: new Date() })
  .where(eq(users.email, "instructor@example.com"));

// Count users by role (a natural Part 16+/admin-dashboard extension)
const counts = await db
  .select({ role: users.role, count: count() })
  .from(users)
  .groupBy(users.role);
```

---

### `enrollments`

The access-control record: does this user have permission to view this course's authenticated content at all?

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `user_id` | `uuid` | `NOT NULL`, FK → `users.id`, `ON DELETE CASCADE` | — | Deleting a user cleans up their enrollments automatically. |
| `course_id` | `text` | `NOT NULL` | — | Sanity course `_id`. **Not** a foreign key — cross-system reference, verified in application code (Part 8's existence/publication check). |
| `status` | `enrollment_status` enum | `NOT NULL` | `'ACTIVE'` | `ACTIVE`, `COMPLETED`, or `CANCELLED`. Set to `COMPLETED` automatically by `issue-certificate` (Part 14). |
| `enrolled_at` | `timestamptz` | `NOT NULL` | `now()` | |

**Constraint:** `UNIQUE(user_id, course_id)` — named `enrollments_user_course_unique`. This is the database-level guarantee that makes duplicate enrollment *structurally impossible*, proven under real concurrent load in Part 8, Step 4.

**Lifecycle diagram:**

```text
Student clicks "Enroll"
        │
        ▼
   status = ACTIVE  ──────────────► (student learns, submits, progresses)
        │                                      │
        │                                      ▼
        │                          course_progress reaches 100%
        │                                      │
        │                                      ▼
        └───────────────────────────► status = COMPLETED
                                    (set by issue-certificate, Part 14)

   status = CANCELLED — reserved for a future admin/refund workflow;
   no code path in this series currently sets this value, but the
   enum and every enrollment-status check (Part 7/8's `!== "CANCELLED"`
   filters) was written to already respect it correctly if it's added.
```

**Sample queries:**

```ts
// Check for an existing enrollment before creating one (Part 8, Layer 4)
const existing = await db.query.enrollments.findFirst({
  where: and(eq(enrollments.userId, userId), eq(enrollments.courseId, courseId)),
});

// Every enrollment for a user, across every course (Part 7's dashboard)
const mine = await db.query.enrollments.findMany({
  where: eq(enrollments.userId, userId),
});

// Total enrollment count for one course (Part 15's instructor overview)
const [{ value }] = await db
  .select({ value: count() })
  .from(enrollments)
  .where(eq(enrollments.courseId, courseId));
```

---

### `lesson_progress`

Fine-grained: has this student finished *this specific lesson*?

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `user_id` | `uuid` | `NOT NULL`, FK → `users.id`, CASCADE | — | |
| `enrollment_id` | `uuid` | `NOT NULL`, FK → `enrollments.id`, CASCADE | — | Links progress back to the specific enrollment that authorized it. |
| `course_id` | `text` | `NOT NULL` | — | Denormalized from the enrollment, deliberately, so "all progress for course X" is a single-table query without an extra join (Part 5's stated tradeoff). |
| `lesson_id` | `text` | `NOT NULL` | — | Sanity lesson `_id`. Not a foreign key. |
| `status` | `lesson_status` enum | `NOT NULL` | `'NOT_STARTED'` | `NOT_STARTED`, `IN_PROGRESS`, `COMPLETED`. First written by `submitModuleAttempt` (Part 11) as `IN_PROGRESS`; upgraded to `COMPLETED` by `recalculate-course-progress` (Part 12) once every module in the lesson has an attempt. |
| `completed_at` | `timestamptz` | nullable | `null` | Set only when `status` becomes `COMPLETED`. |
| `created_at`, `updated_at` | `timestamptz` | `NOT NULL` | `now()` | |

**Constraint:** `UNIQUE(user_id, lesson_id)` — exactly one progress row per student per lesson, ever. This is what makes `upsertLessonProgress`'s `onConflictDoUpdate` (Part 11) work correctly — Drizzle needs this exact column pair to know which existing row to update.

**Sample queries:**

```ts
// All progress rows for a user within one course (Part 7's outline)
const rows = await db.query.lessonProgress.findMany({
  where: and(eq(lessonProgress.userId, userId), eq(lessonProgress.courseId, courseId)),
});

// The upsert pattern from Part 11 — insert or update on conflict
await db.insert(lessonProgress).values({...}).onConflictDoUpdate({
  target: [lessonProgress.userId, lessonProgress.lessonId],
  set: { status: "IN_PROGRESS", updatedAt: new Date() },
});
```

---

### `course_progress`

The aggregate: what percentage of the whole course is done, and where did the student last leave off?

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `user_id`, `enrollment_id` | `uuid` | `NOT NULL`, FK, CASCADE | — | |
| `course_id` | `text` | `NOT NULL` | — | Sanity course `_id`. |
| `completion_percentage` | `integer` | `NOT NULL` | `0` | 0–100. Recalculated exclusively by Inngest's `recalculate-course-progress` function (Part 12) — never written directly by any Server Action. |
| `last_visited_lesson_id` | `text` | nullable | `null` | Sanity lesson `_id`, powering "Resume learning" (Part 9). |
| `last_visited_at` | `timestamptz` | nullable | `null` | |
| `last_activity_at` | `timestamptz` | `NOT NULL` | `now()` | The field `findInactiveEnrollments` (Part 14) filters against for reminder eligibility. |
| `created_at`, `updated_at` | `timestamptz` | `NOT NULL` | `now()` | |

**Constraint:** `UNIQUE(user_id, course_id)`.

**Why this table is separate from `enrollments` at all**, rather than adding these columns directly onto the enrollment row: `enrollments` answers a yes/no access-control question that changes rarely (enroll once, maybe complete/cancel once). `course_progress` changes on nearly every request (every lesson visit, every module attempt). Keeping frequently-mutated aggregate data in its own table is a small but genuine performance and clarity habit — it also means `course_progress` could theoretically be entirely rebuilt from `lesson_progress` + `module_attempts` if ever corrupted, since it's a derived summary, not a source of truth.

**Sample queries:**

```ts
// The core recalculation write (Part 12)
await db.update(courseProgress)
  .set({ completionPercentage, lastActivityAt: new Date() })
  .where(and(eq(courseProgress.userId, userId), eq(courseProgress.courseId, courseId)));

// Every student's progress in one course, for the instructor roster (Part 15)
// — see the full JOIN version in the instructor-analytics reference below.
```

---

### `module_attempts`

The most granular table in the system: one row per graded (or acknowledged) interaction with one interactive module.

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `user_id` | `uuid` | `NOT NULL`, FK → `users.id`, CASCADE | — | |
| `lesson_id` | `text` | `NOT NULL` | — | Sanity lesson `_id`. |
| `module_id` | `text` | `NOT NULL` | — | Matches a `quizBlock`/`codeExerciseBlock`/etc.'s authored `moduleId` field (Part 3). The link between "an interactive block in Sanity" and "a submission record in Neon." |
| `attempt_number` | `integer` | `NOT NULL` | `1` | Increments per module per user — supports the `MAX_ATTEMPTS_PER_MODULE` limit (Part 11). |
| `submission` | `jsonb` | `NOT NULL` | — | The student's raw answer, e.g. `{"selectedOptionIndex": 2}`. Never the graded result — that's `score`/`is_correct`, computed separately. |
| `score` | `integer` | nullable | `null` | 0–100. `null` for module types with no notion of correctness (reflection, checkpoint). |
| `is_correct` | `boolean` | nullable | `null` | Same nullability reasoning as `score`. |
| `idempotency_key` | `text` | nullable | `null` | Client-generated UUID per logical submission (Part 11, Step 6) — protects against network-retry duplication. |
| `submitted_at` | `timestamptz` | `NOT NULL` | `now()` | |

**Constraints:**
- `UNIQUE(user_id, module_id, attempt_number)` — allows *multiple* attempts, but never two rows claiming to be "attempt #3" for the same student/module.
- `UNIQUE(user_id, module_id, idempotency_key)` — a **partial** effective constraint: Postgres treats `NULL` values as never conflicting with each other, so this only actually enforces uniqueness among rows where a real key was supplied.

**Why `score`/`is_correct` are nullable rather than defaulting to `0`/`false`:** a `0` or `false` default would be indistinguishable from "genuinely scored zero" — an important, real distinction (a student who got every answer wrong vs. a reflection that was never meant to be scored at all). `NULL` unambiguously means "not applicable," never "failed."

**Sample queries:**

```ts
// Count prior attempts for the attempt-limit check (Part 11)
const attempts = await db.query.moduleAttempts.findMany({
  where: and(eq(moduleAttempts.userId, userId), eq(moduleAttempts.moduleId, moduleId)),
});

// Restore a student's most recent state for every module in a lesson (Part 10)
const rows = await db.query.moduleAttempts.findMany({
  where: and(eq(moduleAttempts.userId, userId), eq(moduleAttempts.lessonId, lessonId)),
  orderBy: [desc(moduleAttempts.attemptNumber)],
});

// Average score per module across ALL students (Part 15's analytics)
const rows = await db
  .select({ moduleId: moduleAttempts.moduleId, averageScore: avg(moduleAttempts.score), attemptCount: count() })
  .from(moduleAttempts)
  .where(sql`${moduleAttempts.lessonId} in ${lessonIds}`)
  .groupBy(moduleAttempts.moduleId);
```

---

### `certificates`

Permanent, historical proof of achievement — deliberately **snapshotted**, never live-joined.

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `user_id` | `uuid` | `NOT NULL`, FK → `users.id`, CASCADE | — | |
| `course_id` | `text` | `NOT NULL` | — | Sanity course `_id`. |
| `certificate_number` | `text` | `NOT NULL`, `UNIQUE` | — | Human-readable, e.g. `GM-2025-000042`. Generated from `certificate_number_seq`, an atomic Postgres sequence (Part 13). |
| `course_title` | `text` | `NOT NULL` | — | **Snapshot** — the course's title at the moment of issuance. Never updated if the course is later renamed. |
| `recipient_email` | `text` | `NOT NULL` | — | **Snapshot** — the student's email at issuance. Never updated if the account email later changes. |
| `issued_at` | `timestamptz` | `NOT NULL` | `now()` | |

**Constraint:** `UNIQUE(user_id, course_id)` — one certificate per student per course, forever. Proven under concurrent load in Part 13, Step 10's duplicate-safety test.

**Associated database object:** `certificate_number_seq` — a `pgSequence`, not a column. Queried via `SELECT nextval('certificate_number_seq')`, guaranteeing atomic, gap-tolerant, never-repeating numbers regardless of concurrent completions.

**Sample queries:**

```ts
// Atomic number generation + insert (Part 13)
const result = await client.execute(sql`select nextval('certificate_number_seq') as val`);

// Every certificate a student has earned, newest first (achievements page)
const certs = await db.query.certificates.findMany({
  where: eq(certificates.userId, userId),
  orderBy: (c, { desc }) => [desc(c.issuedAt)],
});
```

---

### `webhook_events`

The idempotency ledger for externally-delivered webhooks (Clerk, and any future provider).

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `source` | `text` | `NOT NULL` | — | e.g. `"clerk"`. Supports multiple future providers in one table. |
| `event_type` | `text` | `NOT NULL` | — | e.g. `"user.created"`. |
| `external_id` | `text` | `NOT NULL` | — | The provider's own delivery ID (Clerk's `svix-id` header). |
| `payload` | `jsonb` | `NOT NULL` | — | The full raw event body, kept for debugging/audit. |
| `processed_at` | `timestamptz` | nullable | `null` | Set once the event's real work completes successfully. |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` | |

**Constraint:** `UNIQUE(source, external_id)` — the exact mechanism that makes Clerk webhook redelivery safe (Part 6).

---

### `workflow_events`

Internal observability for Inngest background jobs — a record queryable directly from Neon, independent of Inngest's own external dashboard.

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `event_name` | `text` | `NOT NULL` | — | e.g. `"course/completed"`. |
| `payload` | `jsonb` | `NOT NULL` | — | The triggering event's data. |
| `status` | `workflow_status` enum | `NOT NULL` | `'PENDING'` | `PENDING`, `PROCESSED`, `FAILED`. |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` | |
| `processed_at` | `timestamptz` | nullable | `null` | |

**Note:** deliberately has **no** `user_id` foreign key — this table tracks *job runs*, not per-user records; a given row's payload may or may not reference a user internally, but the table itself doesn't model that relationship structurally.

---

### `audit_logs`

The general accountability trail — designed to outlive the accounts it describes.

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `user_id` | `uuid` | FK → `users.id`, **`ON DELETE SET NULL`** | nullable | The one deliberate exception to this codebase's cascade-delete pattern — see below. |
| `action` | `text` | `NOT NULL` | — | e.g. `"module_attempt.recorded"`, `"module_attempt.rejected"`. |
| `metadata` | `jsonb` | nullable | `null` | Contextual detail — module ID, rejection reason, etc. |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` | |

**Why `SET NULL` instead of `CASCADE` here, uniquely among every table in this schema:** every other table's data is *meaningless without* its owning user (an enrollment with no user is nonsense — delete it). An audit log entry describing "a submission was rejected for reason X" remains historically true and potentially valuable evidence *even after* the account is deleted. `SET NULL` preserves the record while honestly reflecting that its subject no longer exists.

---

### `notifications`

User-facing notification history — distinct from `audit_logs`, which is purely internal.

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `user_id` | `uuid` | `NOT NULL`, FK → `users.id`, CASCADE | — | |
| `type` | `notification_type` enum | `NOT NULL` | — | `INACTIVITY_REMINDER`, `WEEKLY_DIGEST`, `COURSE_COMPLETED`, `NEW_CONTENT_PUBLISHED`. |
| `title`, `body` | `text` | `NOT NULL` | — | Displayed directly in the in-app notification center. |
| `metadata` | `jsonb` | nullable | `null` | e.g. `{ courseId, courseTitle, manual: true }` — lets the UI link directly to relevant content. |
| `read_at` | `timestamptz` | nullable | `null` | `NULL` = unread. Set by `markAllNotificationsRead` (Part 14). |
| `email_sent` | `boolean` | `NOT NULL` | `false` | Records whether an email genuinely went out (vs. dev-fallback logging) alongside the in-app entry. |
| `created_at` | `timestamptz` | `NOT NULL` | `now()` | |

**Sample query — the spam-prevention check (Part 14):**

```ts
const alreadySent = await db.query.notifications.findFirst({
  where: and(
    eq(notifications.userId, userId),
    eq(notifications.type, "INACTIVITY_REMINDER"),
    gte(notifications.createdAt, sevenDaysAgo)
  ),
});
```

---

### `notification_preferences`

A minimal, optional-by-default opt-out control.

| Column | Type | Constraints | Default | Why it exists |
|---|---|---|---|---|
| `id` | `uuid` | PRIMARY KEY | `defaultRandom()` | |
| `user_id` | `uuid` | `NOT NULL`, FK → `users.id`, CASCADE | — | |
| `inactivity_reminders_enabled` | `boolean` | `NOT NULL` | `true` | |
| `weekly_digest_enabled` | `boolean` | `NOT NULL` | `true` | |
| `updated_at` | `timestamptz` | `NOT NULL` | `now()` | |

**Constraint:** `UNIQUE(user_id)` — at most one preferences row per user.

**Critical design rule (Part 14, Step 2):** application code must **never** treat "no row exists" as "everything disabled." The `getEffectivePreferences` helper is the single, centralized place this default is applied — every consumer (the cron functions, the settings page) reads through it, never querying this table directly.

---

## B.3 Every enum, in one place

| Enum | Values | Used by |
|---|---|---|
| `user_role` | `STUDENT`, `INSTRUCTOR`, `ADMIN` | `users.role` |
| `enrollment_status` | `ACTIVE`, `COMPLETED`, `CANCELLED` | `enrollments.status` |
| `lesson_status` | `NOT_STARTED`, `IN_PROGRESS`, `COMPLETED` | `lesson_progress.status` |
| `workflow_status` | `PENDING`, `PROCESSED`, `FAILED` | `workflow_events.status` |
| `notification_type` | `INACTIVITY_REMINDER`, `WEEKLY_DIGEST`, `COURSE_COMPLETED`, `NEW_CONTENT_PUBLISHED` | `notifications.type` |

---

## B.4 Every constraint, in one place

| Table | Constraint name | Columns | Prevents |
|---|---|---|---|
| `users` | (unique) | `auth_provider_id` | Two internal users for one Clerk identity |
| `users` | (unique) | `email` | Duplicate accounts by email |
| `enrollments` | `enrollments_user_course_unique` | `user_id, course_id` | Duplicate enrollment |
| `lesson_progress` | `lesson_progress_user_lesson_unique` | `user_id, lesson_id` | Duplicate progress rows |
| `course_progress` | `course_progress_user_course_unique` | `user_id, course_id` | Duplicate aggregate rows |
| `module_attempts` | `module_attempts_user_module_attempt_unique` | `user_id, module_id, attempt_number` | Two rows claiming the same attempt number |
| `module_attempts` | `module_attempts_user_module_idempotency_unique` | `user_id, module_id, idempotency_key` | Duplicate processing of a retried request |
| `certificates` | `certificates_user_course_unique` | `user_id, course_id` | Duplicate certificate issuance |
| `certificates` | (unique) | `certificate_number` | Two certificates sharing a number |
| `webhook_events` | `webhook_events_source_external_id_unique` | `source, external_id` | Double-processing a redelivered webhook |
| `notification_preferences` | `notification_preferences_user_unique` | `user_id` | Multiple preference rows per user |

---

## B.5 Cascade behavior, in one place

| Table.column | `onDelete` behavior | Why |
|---|---|---|
| `enrollments.user_id` | `CASCADE` | An enrollment is meaningless without its user |
| `lesson_progress.user_id`, `.enrollment_id` | `CASCADE` | Same reasoning |
| `course_progress.user_id`, `.enrollment_id` | `CASCADE` | Same reasoning |
| `module_attempts.user_id` | `CASCADE` | Same reasoning |
| `certificates.user_id` | `CASCADE` | Same reasoning |
| `notifications.user_id` | `CASCADE` | Same reasoning |
| `notification_preferences.user_id` | `CASCADE` | Same reasoning |
| `audit_logs.user_id` | **`SET NULL`** | Historical record should outlive the account |
| `workflow_events` | *(no user_id column at all)* | Job-level record, not user-owned |

---

## B.6 The "text field, not a foreign key" list — every cross-system reference

These fields are the deliberate seam between Neon and Sanity. **None of them are validated by Postgres.** Every read/write path touching them must independently verify the relationship in application code — this is the single most important recurring lesson of the entire series.

| Field | Points to (in Sanity) | Verified by |
|---|---|---|
| `enrollments.course_id` | `course._id` | Part 8's existence/publication check |
| `lesson_progress.course_id`, `.lesson_id` | `course._id`, `lesson._id` | Part 9's course-scoped lesson query |
| `course_progress.course_id`, `.last_visited_lesson_id` | same | Part 9's `getCourseOutline` |
| `module_attempts.lesson_id`, `.module_id` | `lesson._id`, block's `moduleId` | Part 11's `assessmentDefinitionQuery` (scoped through course → lesson → module) |
| `certificates.course_id` | `course._id` | Snapshotted at issuance; no longer re-verified after that point (Part 13) |

---

## B.7 Common cross-table query patterns

A few realistic queries that join multiple tables at once, exactly as used in Parts 7, 14, and 15 — useful as templates for any future feature you build on top of this schema.

```ts
// "Every course this user is enrolled in, with progress" (Part 7 pattern)
const rows = await db
  .select({
    courseId: enrollments.courseId,
    status: enrollments.status,
    completionPercentage: courseProgress.completionPercentage,
  })
  .from(enrollments)
  .innerJoin(
    courseProgress,
    and(eq(courseProgress.userId, enrollments.userId), eq(courseProgress.courseId, enrollments.courseId))
  )
  .where(eq(enrollments.userId, userId));

// "Every ACTIVE enrollment inactive for 7+ days, across ALL students" (Part 14 pattern)
const rows = await db
  .select({
    userId: enrollments.userId,
    userEmail: users.email,
    courseId: enrollments.courseId,
    lastActivityAt: courseProgress.lastActivityAt,
  })
  .from(enrollments)
  .innerJoin(courseProgress, and(eq(courseProgress.userId, enrollments.userId), eq(courseProgress.courseId, enrollments.courseId)))
  .innerJoin(users, eq(users.id, enrollments.userId))
  .where(and(eq(enrollments.status, "ACTIVE"), lt(courseProgress.lastActivityAt, cutoffDate)));

// "Paginated student roster for one course" (Part 15 pattern)
const rows = await db
  .select({ userEmail: users.email, status: enrollments.status, completionPercentage: courseProgress.completionPercentage })
  .from(enrollments)
  .innerJoin(users, eq(users.id, enrollments.userId))
  .innerJoin(courseProgress, and(eq(courseProgress.userId, enrollments.userId), eq(courseProgress.courseId, enrollments.courseId)))
  .where(eq(enrollments.courseId, courseId))
  .orderBy(enrollments.enrolledAt)
  .limit(pageSize)
  .offset(offset);
```

---

## B.8 Recommended indexes beyond the primary/unique keys

Every unique constraint in this schema (B.4) automatically creates a supporting index in Postgres — no extra work needed there. However, several columns are queried by equality *outside* of any unique constraint, and would benefit from an explicit index in a real production deployment at scale (not strictly required for this tutorial's data volumes, but worth knowing as a natural next optimization):

```sql
-- Speeds up findInactiveEnrollments' WHERE clause (Part 14)
CREATE INDEX idx_course_progress_last_activity ON course_progress (last_activity_at);

-- Speeds up countAttemptsForModule / findLatestModuleAttempts (Part 10, 11)
CREATE INDEX idx_module_attempts_user_module ON module_attempts (user_id, module_id);

-- Speeds up findNotificationsForUser's ORDER BY (Part 14)
CREATE INDEX idx_notifications_user_created ON notifications (user_id, created_at DESC);
```

These would be added as a new Drizzle migration (`db/schema/*.ts` files can declare indexes via `index()` alongside `unique()`) — left as a documented, optional production-hardening step rather than a required part of the series, since the data volumes generated while following this tutorial never approach the scale where they'd be noticeable.
