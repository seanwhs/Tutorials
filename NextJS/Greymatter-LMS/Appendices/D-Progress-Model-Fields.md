# Appendix D: The Course → Chapter → Lesson Hierarchy and the Progress Model Fields

This appendix covers two topics not yet addressed in Appendices A through C: the full structural shape of Sanity's content hierarchy (and exactly where the `CustomModule` extension block fits within it), and a complete reference to every field on the `Progress` model, explaining how they work together to represent a single student's completion state.

## D.1 The Course → Chapter → Lesson Schema Hierarchy

Greymatter's content structure is built as a strict, one-directional chain of references — a `Course` references many `Chapter` documents, and each `Chapter` references many `Lesson` documents [1]:

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
│  PortableText Block  │                        │     CustomModule     │
│  (Paragraphs, Code)  │                        │  (Registry-bound JS) │
└──────────────────────┘                        └──────────────────────┘
```

**Reading this diagram top to bottom:** a `Course` is the top-level container an instructor creates first — it holds a "1-to-Many" reference down to `Chapter` documents, meaning one course can have many chapters, but each chapter belongs to exactly one course. The same 1-to-Many pattern repeats one level down: a `Chapter` references many `Lesson` documents. This mirrors exactly how the sidebar navigation you built in Part 2 walks through courses, then chapters, then lessons, resolving each reference in turn via a single GROQ query.

**Where the split happens:** once you reach the `Lesson` level, the hierarchy branches into two distinct paths rather than continuing straight down:

- The **left branch** is the `PortableText Block` path — this is where ordinary lesson material lives: paragraphs, headings, code snippets, lists. It's Sanity's standard structured rich-text format.
- The **right branch** is the **optional** `CustomModule` extension — described explicitly as "Registry-bound JS" [1]. This is optional precisely because most lesson content is just text; only lessons that need interactivity (like a SQL Sandbox) include one or more of these blocks.

**Why "Registry-bound" is the key phrase:** this label captures the entire design philosophy of Greymatter's plugin system. Sanity doesn't know what a `CustomModule` *does* — it only stores two plain fields describing it, confirmed directly in the schema definition [1]:

```typescript
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
}
```

Notice the `moduleType` field's own description states its entire job: it "must match a dynamic key in the Next.js ModuleRegistry" [1]. In other words, this string is meaningless to Sanity — it's a lookup key meant to be resolved entirely on the Next.js side, exactly by the `ModuleRegistry` built in Part 3. The `configPayload` field's validation is similarly narrow in scope: it only confirms the string is *parsable* JSON via a `try/JSON.parse/catch` check — it makes no attempt to validate that the JSON contains the right keys for any particular plugin, because Sanity has no way of knowing what "right" means for a SQL Sandbox versus a quiz versus any future plugin type [1]. That responsibility is deliberately left to the plugin component itself at render time.

This is the same "sealed envelope" principle from Appendix A applied one level deeper: just as `Enrollment.courseId` and `Progress.lessonId` are plain strings rather than true foreign keys, `moduleType` is a plain string rather than a real binding to executable code — the actual connection only happens in application code, never inside the content database itself.

## D.2 The Full `Progress` Model Field Reference

The `Progress` table is where every piece of student interaction ultimately lands. Here is the complete field reference, consolidated directly from the schema documentation [1]:

| Field | Type | Key Type | Description |
|---|---|---|---|
| `lessonId` | `VARCHAR(255)` | `Index` | References Sanity's `lesson._id` value. |
| `completed` | `BOOLEAN` | None | Tracks whether the lesson has been completed. |
| `score` | `INT` | None | Standardized percentage-based score (0 to 100). |
| `moduleState` | `JSONB` | None | Raw, arbitrary storage for developer sandbox outputs. |

**`lessonId` (indexed string)** — This is the seam described in Appendix A: an indexed lookup key pointing at a Sanity document, not a true foreign key. The index exists specifically so queries like "give me every completed lesson for this user" (used in Part 4's `getCompletedLessonIds()`) run efficiently, even as the `Progress` table grows to millions of rows across many students.

**`completed` (boolean)** — The simplest possible signal: has this student finished this lesson, yes or no. This is the field the sidebar checkmark in Part 4 directly reflects — `useOptimistic` updates a client-side mirror of this exact boolean, instantly, ahead of server confirmation.

**`score` (integer, 0–100)** — A standardized percentage. Because this field has a defined valid range, the `completeLesson` Server Action explicitly rejects any value outside 0–100 *before* the transaction begins, treating an out-of-bounds score as a "Transaction Integrity Violation" rather than silently accepting it. Standardizing this to a 0–100 scale means every plugin type — SQL Sandbox today, a quiz or code grader tomorrow — can report progress through the exact same numeric contract, regardless of how internally different their grading logic is.

**`moduleState` (JSONB, arbitrary)** — Described explicitly as "raw, arbitrary storage for developer sandbox outputs" [1]. Unlike the other three fields, this column has no fixed shape — it's a flexible JSON blob that each plugin type can fill however it needs. The SQL Sandbox plugin, for instance, stores `{ submittedQuery: "...", lessonId: "..." }` here, but a future quiz plugin might instead store `{ answers: [...], attemptsUsed: 2 }`. This flexibility is precisely what lets the plugin registry (Appendix C) support arbitrarily many different interactive experiences without ever needing a database migration to add support for a new plugin type — new plugins simply write whatever shape of JSON makes sense for them.

**How these four fields work together in practice:** when a student completes an interactive module, all four fields are written in a single atomic `upsert` call (detailed fully in Appendix C) — `completed` flips to `true`, `score` records the standardized outcome, `moduleState` preserves whatever raw detail the specific plugin wants to keep, and `lessonId` ties the whole record back to the correct piece of Sanity content. None of these fields is meaningful read in isolation from the others: a `completed: true` row with no `score` tells you *that* something happened but not *how well*, while `moduleState` without `completed` would be meaningless leftover data from an unfinished attempt. Together, they form the minimum complete record of "this student did this specific interactive thing, here's how well they did, and here's the raw detail of what they submitted."
