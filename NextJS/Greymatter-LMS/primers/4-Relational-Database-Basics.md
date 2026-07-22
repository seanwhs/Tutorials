# Primer 04 — Relational Database Basics

## Why this primer exists

Part 5 hands you Drizzle ORM and asks you to define nine PostgreSQL tables, complete with foreign keys, unique constraints, and enums — and from Part 8 onward, the entire series depends on you understanding *why* those constraints exist, not just how to write the TypeScript syntax that creates them. Drizzle abstracts away raw SQL, but it doesn't (and shouldn't) abstract away the underlying relational concepts: tables, rows, keys, and the guarantees a database can enforce that application code alone cannot. If terms like "primary key," "foreign key," or "constraint" feel like things you can use but not fully explain, this primer builds that understanding from first principles before Part 5 asks you to design an entire schema around them.

**You can safely skip this primer if** you're already comfortable with: what a table/row/column is, what a primary key and foreign key are and why they differ, what a unique constraint enforces and why it matters under concurrency, and what a database transaction guarantees. If any of those feel uncertain, keep reading.

---

## The core idea: a spreadsheet, but one that refuses to let you make mistakes

You've almost certainly used a spreadsheet before. Imagine two sheets in one workbook:

```text
Sheet: "Students"                      Sheet: "Enrollments"
┌────┬──────────────┐                  ┌────┬────────────┬───────────┐
│ ID │ Name          │                  │ ID │ StudentID  │ CourseID   │
├────┼──────────────┤                  ├────┼────────────┼───────────┤
│ 1  │ Ada Lovelace  │                  │ 1  │ 1          │ course-A   │
│ 2  │ Alan Turing   │                  │ 2  │ 2          │ course-B   │
└────┴──────────────┘                  │ 3  │ 5          │ course-A   │  ← StudentID 5
                                        └────┴────────────┴───────────┘     doesn't EXIST!
```

In a plain spreadsheet, absolutely nothing stops someone from typing `5` into that `StudentID` column, even though no student with ID `5` exists anywhere in the "Students" sheet. The mistake sits there silently — nobody notices until someone tries to look up "which student is enrollment #3 for" and gets nothing back.

A **relational database** is exactly this idea — data organized into tables (like sheets), rows (like spreadsheet rows), and columns (like spreadsheet columns) — but with the software itself actively **enforcing rules** about what data is allowed to exist. In a real relational database, attempting to insert an enrollment row with `StudentID = 5` would be **physically rejected** by the database itself, the moment you tried it, if no student with that ID exists. This is the single most important idea in this entire primer: **a relational database doesn't just store your data — it actively refuses to store data that violates rules you've defined**, which is a fundamentally different guarantee than "we wrote code that's supposed to check this."

---

## Tables, rows, and columns — the vocabulary

```text
                    ┌─────────────────────────────────────────┐
                    │              TABLE: users                 │
column names ──────►│  id (PK)  │  email          │  role       │
                    ├───────────┼─────────────────┼─────────────┤
one row ───────────►│  uuid-1   │  ada@ex.com     │  STUDENT    │
another row ───────►│  uuid-2   │  alan@ex.com    │  INSTRUCTOR │
                    └───────────┴─────────────────┴─────────────┘
```

- A **table** is one named collection of structured records — `users`, `enrollments`, `certificates`, etc.
- A **row** is one specific record within a table — one specific user, one specific enrollment.
- A **column** is a named, typed field every row in the table has — `email`, `role`, `enrolled_at`.

Every column has a declared **type** — `text`, `integer`, `boolean`, `timestamp`, and so on — and, just like TypeScript (Primer 01), the database *enforces* that type. You cannot insert the text `"hello"` into a column declared as `integer` — the database rejects it outright, the same way TypeScript rejects passing a string where a `number` was promised.

### Seeing this directly in GreyMatter's Drizzle schema

Part 5's `users` table is a direct, literal translation of "table with typed columns" into Drizzle's TypeScript syntax:

```ts
export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  authProviderId: text("auth_provider_id").notNull().unique(),
  email: text("email").notNull().unique(),
  role: userRoleEnum("role").notNull().default("STUDENT"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});
```

Read this the same way you'd read a spreadsheet's column headers: this table has five columns (`id`, `auth_provider_id`, `email`, `role`, `created_at`), and each declares its type (`uuid`, `text`, `text`, an enum, a `timestamp`) plus rules about that column (`.notNull()`, `.unique()`, a default value).

---

## The primary key: every row's permanent, unique identity

A **primary key** is a column (or combination of columns) that uniquely identifies one specific row, forever, across the entire table. No two rows in the same table can ever share the same primary key value — the database enforces this automatically, without you needing to check for duplicates yourself.

```text
users table:
┌──────────┬────────────────┐
│ id (PK)  │ email           │
├──────────┼────────────────┤
│ uuid-1   │ ada@example.com │  ← "uuid-1" uniquely identifies THIS row, forever
│ uuid-2   │ alan@example.com│  ← "uuid-2" uniquely identifies THIS OTHER row
└──────────┴────────────────┘
```

**Why use a randomly-generated UUID instead of a simple counting number (1, 2, 3...)?** This is a genuine, deliberate choice made throughout GreyMatter LMS:

```ts
id: uuid("id").primaryKey().defaultRandom(),
```

A UUID (Universally Unique Identifier) is a long, essentially-impossible-to-guess random string (like `a1b2c3d4-e5f6-7890-abcd-ef1234567890`). Compare this to a simple auto-incrementing integer (1, 2, 3, ...), which is predictable and sequential. Two practical reasons this series uses UUIDs everywhere:

1. **Unguessability** — if certificate IDs were sequential integers, anyone could try `/api/certificates/1/download`, `/api/certificates/2/download`, and so on, probing for certificates that might not properly enforce ownership checks. A UUID makes that kind of blind guessing essentially impossible.
2. **Safe generation without coordination** — a UUID can be generated independently, anywhere, without needing to ask a central counter "what's the next number?" first — which matters when multiple servers or processes might be inserting rows concurrently (recall Primer 02's discussion of concurrent operations).

`.defaultRandom()` tells Postgres to generate this value **automatically**, inside the database itself, the moment a row is inserted — application code never has to invent an ID itself, which sidesteps an entire category of ID-collision bugs.

---

## The foreign key: a *database-enforced* pointer to another table's row

This is the single most important concept in this entire primer, because Part 5's whole schema design revolves around it, and Part 5's own text explicitly compares it to something you already know from Part 4: a Sanity "reference."

A **foreign key** is a column in one table that is *required* to match an existing primary key value in another table — enforced automatically by the database.

```text
users table                          enrollments table
┌──────────┬──────────────┐          ┌──────────┬───────────┬────────────┐
│ id (PK)  │ email         │          │ id (PK)  │ user_id    │ course_id   │
├──────────┼──────────────┤          ├──────────┼───────────┼────────────┤
│ uuid-1   │ ada@ex.com    │◄─────────┤ uuid-100 │ uuid-1     │ course-A    │
└──────────┴──────────────┘   FK      └──────────┴───────────┴────────────┘
                              points
                              here

Attempting to insert an enrollment with user_id = "uuid-999" (which
doesn't exist in the users table) is PHYSICALLY REJECTED by Postgres —
not just "a bad idea," but an error thrown immediately at insert time.
```

Compare this precisely to the spreadsheet example at the top of this primer: this is exactly the "StudentID 5 doesn't exist" problem, except a real relational database refuses to let it happen at all.

### Seeing this directly in GreyMatter's schema

```ts
export const enrollments = pgTable("enrollments", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }), // ← THE foreign key
  courseId: text("course_id").notNull(), // ← NOT a foreign key — see below
  // ...
});
```

`.references(() => users.id, ...)` is Drizzle's syntax for declaring a foreign key — it tells Postgres: "every value in this `userId` column must match a real, existing `id` in the `users` table, always, no exceptions." Notice the function wrapper (`() => users.id`) rather than a direct reference (`users.id`) — Part 5 explains this is a Drizzle convention letting tables reference each other regardless of which file happens to load first, avoiding circular-import errors.

### The critical, deliberate exception: `courseId` is NOT a foreign key

Look again at the same table above: `courseId: text("course_id").notNull()` has **no** `.references(...)` call at all. This is not an oversight — it's one of the most important architectural decisions in the entire series, and Part 5 states it explicitly:

> *"`enrollments.course_id` and `lesson_progress.lesson_id` are plain strings, not foreign keys. PostgreSQL cannot enforce a foreign key into Sanity, since Sanity is an entirely separate system with its own storage."*

This is the direct database-level consequence of GreyMatter's hybrid architecture (Part 0): Postgres can only enforce relationships *within its own database*. It has no way to reach across the network into Sanity's separate content system and verify "does this course ID actually exist there?" That verification becomes **application code's responsibility**, entirely — which is exactly why Part 4 built the "course-scoped lesson query" pattern, and why Part 8's enrollment action independently re-checks a course's existence against Sanity before writing anything to Neon. Understanding this one distinction — foreign key (database-enforced) versus plain text ID (application-enforced) — is the key to understanding *why* so much of this series' security reasoning exists at all.

```text
┌─────────────────────────────────────────────────────────────────┐
│  Foreign key (users.id ← enrollments.user_id)                     │
│  Enforced by: PostgreSQL itself, automatically, always             │
│                                                                     │
│  "Reference-like" text field (Sanity course _id ← enrollments.      │
│  course_id)                                                          │
│  Enforced by: OUR OWN APPLICATION CODE, every single time we read     │
│  or write it — Postgres has no idea Sanity even exists                │
└─────────────────────────────────────────────────────────────────┘
```

### `ON DELETE CASCADE` — what happens to related rows when the referenced row is deleted

```ts
userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
```

`onDelete: "cascade"` tells Postgres: "if the `users` row this points to is ever deleted, automatically delete this row too." This is what makes Part 6's `user.deleted` webhook handling clean — deleting one `users` row automatically, safely removes every enrollment, every progress record, every module attempt, every certificate that pointed at that user, without our application code needing to manually clean up five separate tables one at a time.

Recall Part 5 also introduced the one deliberate exception: `audit_logs.userId` uses `onDelete: "set null"` instead — because an audit trail should outlive the account it describes, whereas an enrollment genuinely has no meaning without its user.

---

## The unique constraint: making certain mistakes *structurally impossible*

A **unique constraint** guarantees that no two rows can ever share the same value (or combination of values) in specified columns — enforced by the database, at the moment of insertion, regardless of what application code does or doesn't check beforehand.

```ts
export const enrollments = pgTable(
  "enrollments",
  { /* ...columns... */ },
  (table) => [
    unique("enrollments_user_course_unique").on(table.userId, table.courseId),
  ]
);
```

This declares: no two rows in `enrollments` may ever have the *same* `(userId, courseId)` pair together. One user can be enrolled in many different courses (different `courseId` each time), and many different users can be enrolled in the same course — but the exact same user enrolling in the exact same course twice is physically impossible, the instant a second insert attempts it.

### Why this matters more than it might first appear: the race condition problem

This is genuinely one of the most important lessons in the entire series, first demonstrated concretely in Part 8, Step 4. Imagine application code that tries to prevent duplicates "manually":

```ts
// THE NAIVE APPROACH — looks reasonable, but has a real bug
const existing = await findEnrollment(userId, courseId);
if (existing) {
  return { error: "Already enrolled" };
}
await createEnrollment(userId, courseId); // ← insert happens here
```

This looks correct — check first, then insert. But imagine two requests arriving at *almost exactly the same instant* (a student double-clicking "Enroll," or two browser tabs). Both requests could run `findEnrollment` and both see "no existing enrollment" — **before either one has actually written anything yet** — and then both proceed to insert. Without a database-level guarantee, you'd end up with two enrollment rows for the same student and course.

```text
Time →
Request A: ── findEnrollment() → "none found" ──────── createEnrollment() ──►
Request B:      ── findEnrollment() → "none found" ──────── createEnrollment() ──►
                        ▲
                  Both checks happen BEFORE either insert — the "gap"
                  where the race condition lives
```

**A unique constraint closes this gap completely, because it doesn't rely on timing at all.** Even if both requests' `findEnrollment` checks return "none found" and both proceed to insert, only **one** of the two `INSERT` statements can actually succeed — Postgres itself guarantees this, atomically, no matter how close together in time the two requests arrive. The second insert simply fails with a "unique constraint violation" error, which application code then catches and handles gracefully (exactly what Part 8's `try`/`catch` around the enrollment write does).

This is precisely why Part 8's own text states: *"application-level 'check then act' logic has an inherent gap between the check and the act... a database constraint closes that window completely, no matter how many requests arrive at the same instant."* Part 8, Step 4 proves this with a real, deliberately concurrent test script — worth revisiting once you reach it, since seeing the constraint actually catch a real race condition firsthand is far more convincing than reading about it abstractly.

---

## `NOT NULL` and nullable columns: modeling "this value must always exist" vs. "this value might legitimately be absent"

By default, a database column *can* hold a special absent-value marker called `NULL` unless you explicitly forbid it. `.notNull()` in Drizzle forbids this — declaring "every row must have a real value here, no exceptions."

```ts
score: integer("score"), // nullable — NO .notNull() here
isCorrect: boolean("is_correct"), // also nullable
```

Part 11's `module_attempts` table deliberately leaves `score` and `isCorrect` nullable — and this is a meaningful modeling decision, not laziness. Recall the reasoning: a reflection or checkpoint module has *no notion of correctness at all* — it would be actively misleading to store `score: 0`, since `0` looks identical to "scored zero points," when the real meaning is "this concept doesn't apply here." `NULL` is the honest way to represent "not applicable," genuinely distinct from any real value including zero or false.

**The rule of thumb used consistently throughout this series:** default every column to `NOT NULL` unless there's a genuine, articulable reason a value might legitimately be absent — a rule Part 5 states explicitly: *"we'll only omit `.notNull()` on columns that have a genuine, meaningful 'no value yet' state."*

---

## The enum: restricting a column to a fixed, named set of values

Recall Primer 01's TypeScript union types (`"STUDENT" | "INSTRUCTOR" | "ADMIN"`). A database **enum** is the equivalent idea, enforced at the database level rather than (or in addition to) the application level:

```ts
export const userRoleEnum = pgEnum("user_role", ["STUDENT", "INSTRUCTOR", "ADMIN"]);

export const users = pgTable("users", {
  role: userRoleEnum("role").notNull().default("STUDENT"),
  // ...
});
```

This means: even if some future bug in application code somehow attempted to insert `role: "SUPERADMIN"` (a value never defined), Postgres itself would reject it — the enum type simply doesn't include that value. This is a second, independent layer of protection beyond TypeScript's own union-type checking (which only runs at compile time, before the code is even deployed) — the database enum protects you even against a bug that somehow slipped past TypeScript's compile-time checks, or against a stray manual SQL edit made directly in a database console.

---

## The database transaction: multiple writes that succeed or fail as one indivisible unit

This concept connects directly back to Primer 02's asynchronous JavaScript foundations, but it's specifically a *database* guarantee, worth understanding on its own terms.

Imagine an operation that needs to make **two** related writes — say, creating an enrollment row *and* creating a matching course-progress row (Part 8's actual enrollment flow). What should happen if the second write fails right after the first one succeeds?

```text
WITHOUT a transaction:
   INSERT enrollment ──► succeeds
   INSERT course_progress ──► FAILS (e.g., a momentary connection issue)
   ─────────────────────────────────────────────────────────────
   RESULT: an enrollment exists with NO matching progress record —
   a genuinely broken, inconsistent state that nothing else in the
   app expects or knows how to handle gracefully

WITH a transaction:
   BEGIN TRANSACTION
     INSERT enrollment ──► succeeds (but not yet permanently committed)
     INSERT course_progress ──► FAILS
   ROLLBACK — BOTH writes are undone, as if neither had ever happened
   ─────────────────────────────────────────────────────────────
   RESULT: either BOTH rows exist, or NEITHER does — never a
   half-finished, inconsistent state
```

**Analogy:** a bank transfer between two accounts. Money must leave account A and arrive in account B as a single, indivisible action — if the system crashes after debiting A but before crediting B, that money must never simply vanish. A database transaction is the mechanism guaranteeing exactly this "all or nothing" behavior for any group of writes you explicitly group together.

### Seeing this directly in Drizzle

```ts
export async function createEnrollmentWithProgress(input: CreateEnrollmentInput) {
  return db.transaction(async (tx) => {
    const [enrollment] = await tx
      .insert(enrollments)
      .values({ userId: input.userId, courseId: input.courseId })
      .returning();

    const [progress] = await tx
      .insert(courseProgress)
      .values({
        userId: input.userId,
        enrollmentId: enrollment.id,
        courseId: input.courseId,
        completionPercentage: 0,
      })
      .returning();

    return { enrollment, progress };
  });
}
```

The critical detail, emphasized repeatedly throughout Part 5 and Part 8: **every query inside the transaction callback must use `tx`, never the outer `db`.** Writing `db.insert(...)` instead of `tx.insert(...)` inside this callback would silently run that specific query *outside* the transaction entirely — meaning it would commit permanently on its own, immediately, defeating the entire "all or nothing" guarantee, with no error or warning to tell you it happened. This is a genuinely easy mistake to make and a genuinely important one to avoid — worth re-checking every transaction block you ever write.

---

## Indexes: why some queries are fast and others are slow, briefly

Not deeply covered in the main series' hands-on steps, but worth knowing conceptually since Appendix B mentions it: an **index** is a separate, auxiliary data structure the database maintains alongside a table, allowing it to find matching rows quickly without scanning every single row one by one.

**Analogy:** the index at the back of a textbook. Without it, finding every page that mentions "foreign keys" means reading the entire book start to finish. With an index, you jump directly to the relevant pages. A database index works the same way for a specific column — Postgres can jump directly to matching rows instead of checking every row in the table.

Every `PRIMARY KEY` and `UNIQUE` constraint automatically creates a supporting index for free — this is why looking up a user by `id` or `authProviderId` is fast even in a table with millions of rows. Appendix B, Section B.8 documents a few additional indexes worth adding at production scale (e.g., speeding up Part 14's inactivity-detection query) — not required for this tutorial's data volumes, but a natural next optimization once real-world scale is a genuine concern.

---

## Putting it all together: reading Part 5's `module_attempts` table fluently

```ts
export const moduleAttempts = pgTable(
  "module_attempts",
  {
    id: uuid("id").primaryKey().defaultRandom(),        // ← every row's unique identity,
                                                          //   generated by Postgres itself

    userId: uuid("user_id")
      .notNull()                                          // ← every attempt MUST belong to a user
      .references(() => users.id, { onDelete: "cascade" }), // ← FOREIGN KEY — Postgres refuses
                                                              //   an attempt row pointing at a
                                                              //   nonexistent user; and if the
                                                              //   user is deleted, this row goes too

    lessonId: text("lesson_id").notNull(),                // ← a Sanity ID — NOT a foreign key,
                                                              //   since Sanity is a separate system

    moduleId: text("module_id").notNull(),

    attemptNumber: integer("attempt_number").notNull().default(1),

    submission: jsonb("submission").notNull(),

    score: integer("score"),                                // ← NULLABLE — genuinely "not
    isCorrect: boolean("is_correct"),                        //   applicable" for some module types,
                                                              //   distinct from actually scoring zero

    submittedAt: timestamp("submitted_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    unique("module_attempts_user_module_attempt_unique").on(
      table.userId, table.moduleId, table.attemptNumber
    ),
    // ← UNIQUE CONSTRAINT: allows MULTIPLE attempts per user per module
    //   (since attemptNumber differs each time), but makes it physically
    //   impossible for two rows to claim to be the SAME attempt number
    //   for the same user and module — closing a race-condition gap
    //   exactly the way enrollments' constraint does
  ]
);
```

If every annotation above makes sense on its own terms — not just "what the syntax does" but *why* each design choice was made — you're ready for Part 5, and you'll recognize this exact reasoning pattern repeating across every table in the schema.

---

## You're ready for Part 5 if you can answer these

1. What's the difference between a primary key and a foreign key — and why can a table have only one primary key column (or one primary key combination) but potentially several foreign keys?
2. Why does `enrollments.course_id` deliberately *not* have a foreign key constraint, even though `enrollments.user_id` does?
3. What specific problem does a unique constraint solve that a "check if it exists, then insert" application-code pattern cannot fully solve on its own?
4. Why would a column be left nullable (no `.notNull()`) instead of given a default value like `0` or `false`?
5. Inside a `db.transaction(async (tx) => { ... })` callback, what happens if you accidentally write `db.insert(...)` instead of `tx.insert(...)`, and why is that a real, dangerous mistake rather than just a style issue?

If all five feel solid, you're ready for Part 5 (or Primer 05, if you're working through the primers in sequence) — and you'll recognize this exact vocabulary and reasoning immediately, rather than needing to piece it together for the first time while also learning Drizzle's syntax.
