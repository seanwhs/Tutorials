# Appendix D: The Course → Chapter → Lesson Hierarchy and the Progress Model Fields

This appendix covers two topics not yet addressed in Appendices A through C: the full structural shape of Sanity's content hierarchy (and exactly where the `customModule` extension block fits within it), and a complete reference to every field on the `Progress` model, explaining how they work together to represent a single student's completion state.

## D.1 The Course → Chapter → Lesson Schema Hierarchy

Greymatter's content structure is built as a strict, one-directional chain of references — a `course` document references many `chapter` documents, and each `chapter` references many `lesson` documents:

```
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
│  PortableText Block  │                        │     customModule     │
│  (Paragraphs, Code)  │                        │  (Registry-bound JS) │
└──────────────────────┘                        └──────────────────────┘
```

**Reading this diagram top to bottom:** a `course` document is the top-level container an instructor creates first — it holds a "1-to-Many" reference down to `chapter` documents, meaning one course can have many chapters, but each chapter belongs to exactly one course. The same 1-to-Many pattern repeats one level down: a `chapter` references many `lesson` documents. This mirrors exactly how the sidebar navigation you built in Part 2 walks through courses, then chapters, then lessons, resolving each reference in turn via a single GROQ query.

**Where the split happens:** once you reach the `lesson` level, the hierarchy branches into two distinct paths within its `body` field, rather than continuing straight down:

- The **left branch** is the `PortableText Block` path — this is where ordinary lesson material lives: paragraphs, headings, code snippets, lists. It's Sanity's standard structured rich-text format.
- The **right branch** is the **optional** `customModule` extension — described as "Registry-bound JS." This is optional precisely because most lesson content is just text; only lessons that need interactivity (like a SQL Sandbox) include one or more of these blocks.

**Why "Registry-bound" is the key phrase:** this label captures the entire design philosophy of Greymatter's plugin system. Sanity doesn't know what a `customModule` *does* — it only stores two plain fields describing it, exactly as defined in the schema built in Part 3:

```typescript
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
```

Notice the `moduleType` field's own description states its entire job: it "must match a dynamic key in the Next.js ModuleRegistry." In other words, this string is meaningless to Sanity — it's a lookup key meant to be resolved entirely on the Next.js side, exactly by the `ModuleRegistry` built in Part 3, via `resolveModule(block.moduleType)`. The `configPayload` field's validation is similarly narrow in scope: it only confirms the string is *parsable* JSON via a `try/JSON.parse/catch` check — it makes no attempt to validate that the JSON contains the right keys for any particular plugin, because Sanity has no way of knowing what "right" means for a SQL Sandbox versus a quiz versus any future plugin type. That responsibility is deliberately left to the plugin component itself at render time — for the SQL Sandbox specifically, to the `SqlSandboxConfig` type and its consuming component.

This is the same "sealed envelope" principle from Appendix A applied one level deeper: just as `Enrollment.courseId` and `Progress.lessonId`/`Progress.courseId` are plain strings rather than true foreign keys, `moduleType` is a plain string rather than a real binding to executable code — the actual connection only happens in application code, never inside the content database itself.

## D.2 The Full `Progress` Model Field Reference

The `Progress` table is where every piece of student interaction ultimately lands. Here is the complete field reference, matching the model exactly as it stands after the prerequisite patches introduced ahead of Parts 1 and 3:

| Field | Type | Key Type | Description |
|---|---|---|---|
| `id` | `TEXT` (`cuid()`) | **Primary Key** | Unique identifier for this progress record itself. |
| `userId` | `TEXT` | Foreign Key → `User.id` | The student this record belongs to — always the internal `User.id`, resolved via `getInternalUserId()`, never Clerk's raw session id directly. |
| `courseId` | `TEXT` | `Index` | References Sanity's `course._id` value. Denormalized here specifically so "all progress for user X in course Y" can be answered with a single indexed lookup, without a join back through `Enrollment`. Required on every row — the `completeLesson` transaction's `create` branch cannot succeed without it. |
| `lessonId` | `TEXT` | `Index` | References Sanity's `lesson._id` value. |
| `completed` | `BOOLEAN` | None | Tracks whether the lesson has been completed. Defaults to `false`. |
| `completedAt` | `TIMESTAMP`, nullable | None | Set to the current time at the moment `completed` flips to `true`. |
| `score` | `INT`, nullable | None | Standardized percentage-based score (0 to 100), bounds-checked server-side before ever reaching the transaction. |
| `moduleState` | `JSON`, nullable | None | Raw, arbitrary storage for developer sandbox outputs. |
| — | — | `Unique(userId, lessonId)` | Guarantees exactly one `Progress` row can ever exist per student per lesson, and is what makes the `upsert` in `completeLesson` safe to call repeatedly. |

**`id` (primary key)** — Like every other model in this schema, this is a Prisma-generated `cuid()`, not a database-native `UUID`. It exists purely so this row has its own stable identity, independent of the `(userId, lessonId)` pair that uniquely identifies it logically.

**`userId` (foreign key into `User.id`)** — This is the field most likely to be gotten wrong, because it's tempting to assume it stores whatever `auth()` returns from Clerk. It doesn't. `Progress.userId`, like `Enrollment.userId`, is a foreign key into the internal `User.id` — the same `cuid()` established back in Part 1 and deliberately kept separate from `User.clerkId`. Every read or write against this table first resolves the caller's Clerk session down to this internal id via `getInternalUserId()`; skipping that step means every lookup silently matches nothing.

**`courseId` (indexed string, denormalized)** — This is the field most worth dwelling on, because its absence from an earlier draft of this exact reference table was itself the source of a real bug: without it, the `create` branch of `completeLesson`'s `progress.upsert` call would throw a Prisma validation error, since it's a required, non-nullable column. Architecturally, it exists as a deliberate denormalization — you could theoretically derive "which course does this lesson belong to" by looking it up in Sanity, but storing it directly on `Progress` means a query like "show me this student's completion percentage across course X" never needs to leave Postgres or make a second round-trip to Sanity's CDN just to filter rows.

**`lessonId` (indexed string)** — This is the seam described in Appendix A: an indexed lookup key pointing at a Sanity document, not a true foreign key. The index exists specifically so queries like "give me every completed lesson for this user" (used in Part 4's `getCompletedLessonIds()`) run efficiently, even as the `Progress` table grows to millions of rows across many students.

**`completed` (boolean)** — The simplest possible signal: has this student finished this lesson, yes or no. This is the field the sidebar checkmark in Part 4 directly reflects — `useOptimistic` updates a client-side mirror of this exact boolean, instantly, ahead of server confirmation.

**`completedAt` (nullable timestamp)** — Written in the same `upsert` call as `completed`, set to `new Date()` at the moment of completion. Its nullability matters: a `Progress` row could theoretically exist with `completed: false` and `completedAt: null` (representing an in-progress but unfinished attempt, should Greymatter ever track partial progress in a future iteration) — the two fields aren't collapsed into one because "has this happened" and "when did it happen" are logically distinct questions, even though today they're always set together.

**`score` (nullable integer, 0–100)** — A standardized percentage. Because this field has a defined valid range, the `completeLesson` Server Action explicitly rejects any value outside 0–100 *before* the transaction begins, returning a "Transaction Integrity Violation" error rather than silently accepting it. Standardizing this to a 0–100 scale means every plugin type — SQL Sandbox today, a quiz or code grader tomorrow — can report progress through the exact same numeric contract, regardless of how internally different their grading logic is. Its nullability accounts for plugin types that might report only a binary `completed` state with no meaningful numeric score at all.

**`moduleState` (nullable JSON, arbitrary)** — A flexible JSON blob that each plugin type can fill however it needs. The SQL Sandbox plugin, for instance, stores `{ submittedQuery: "...", lessonId: "..." }` here, but a future quiz plugin might instead store `{ answers: [...], attemptsUsed: 2 }`. This flexibility is precisely what lets the plugin registry (Appendix C) support arbitrarily many different interactive experiences without ever needing a database migration to add support for a new plugin type — new plugins simply write whatever shape of JSON makes sense for them.

**`@@unique([userId, lessonId])`** — Not a column, but worth including in this reference because it's the mechanism, not just a constraint. This is what makes `tx.progress.upsert({ where: { userId_lessonId: { userId, lessonId } }, ... })` valid Prisma syntax in the first place, and what guarantees that even under concurrent requests (two rapid completions of the same lesson), the table can never end up with two separate `Progress` rows for the same student and lesson.

**How these fields work together in practice:** when a student completes an interactive module, six fields are written in a single atomic `upsert` call (detailed fully in Appendix C) — `userId` and `lessonId` together locate (or create) the correct row via the unique constraint, `courseId` is supplied so the row satisfies its required-field constraint and remains queryable by course, `completed` flips to `true`, `completedAt` records when, `score` records the standardized outcome, and `moduleState` preserves whatever raw detail the specific plugin wants to keep. None of these fields is meaningful read in isolation from the others: a `completed: true` row with no `score` tells you *that* something happened but not *how well*; `moduleState` without `completed` would be meaningless leftover data from an unfinished attempt; and a row with `score` and `moduleState` but a missing or mismatched `courseId` would silently fail to appear in any course-scoped progress query, even though the lesson-level data is perfectly intact. Together, these six fields form the minimum complete record of "this student did this specific interactive thing, in this specific course, here's how well they did, and here's the raw detail of what they submitted" — and it's worth noting that `courseId` in particular is the field that ties an individual lesson's result back into the larger enrollment relationship established in Appendix A, closing the loop between the content hierarchy described in D.1 and the transactional guarantees described in Appendix C.
