# Part 11 — Secure Assessments and Progress Transactions

## The goal

By the end of this part, GreyMatter LMS's assessment system will be genuinely secure: the correct answer to a quiz and the expected keywords for a code exercise will **never** be sent to the browser at all — not hidden by CSS, not filtered client-side, simply absent from every payload a student's browser ever receives. Grading will happen exclusively on the server, against an authoritative, freshly-fetched answer key. We'll add enrollment verification directly into the submission path, attempt limits, submission-size limits, idempotency keys, structured public error codes, audit logging, an atomic transaction covering both the attempt and lesson-progress records, and a genuinely reliable optimistic UI using React 19's `useOptimistic`.

## Why it exists

Part 10 ended with you personally proving a real vulnerability: editing a network request in DevTools to turn a wrong quiz answer into a permanently recorded "correct" one. That was not a hypothetical warning — it was working code, in your own database, right now. This part exists to fix it completely, not by patching the symptom, but by removing the underlying cause: **any value the browser needs to compute correctness is a value the browser can also falsify.** The only real fix is that the browser never receives that value in the first place, and every one of this part's steps builds toward that single guarantee.

## The data flow

```text
Student submits an answer (only the raw answer — nothing else)
        │
        ▼
submitModuleAttempt() Server Action
        │
        ├── requireUser() — authentication
        ├── Zod validation — shape + size limits
        ├── Idempotency check — was this exact submission already processed?
        ├── Enrollment verification — is this user enrolled in this course?
        ├── Course-scoped assessment lookup — does this module genuinely
        │     belong to this lesson, which genuinely belongs to this course?
        │     (fetched fresh from Sanity, SERVER-SIDE ONLY, never sent to the browser)
        ├── Attempt-limit check
        ├── Server-side grading — compare against the freshly-fetched answer key
        └── Database transaction:
              ├── INSERT module_attempt (with authoritative score/correctness)
              └── UPSERT lesson_progress → IN_PROGRESS
        │
        ▼
Structured, safe result returned to the browser — never the answer key itself
```

---

## Step 1 — Redesigning the trust boundary for grading

### The Target

No code yet — an explicit, updated version of Part 8's trust-boundary table (Step 1), this time for assessment submissions specifically, identifying exactly what Part 10 got wrong and what must change.

### The Concept

Recall Part 8 built a five-layer defense for enrollment. This table does the same thing for grading — and it's worth building fresh rather than assuming Part 10's approach was "mostly right." Read it carefully; every remaining step in this part implements exactly one row.

| Claim | Trusted from the browser? | Correct source of truth |
|---|---|---|
| "I am user X" | No | `requireUser()` — Part 6 |
| "This submission is shaped correctly" | No | Zod, validated server-side |
| "I selected option 2" / "I typed this response" | **Yes** — this is genuinely the student's own input, there's nothing to fake here | The raw submission itself |
| "Option 2 happens to be correct" | **Absolutely not** | A fresh, server-side fetch of the answer key from Sanity — never sent to the browser |
| "I haven't exceeded my attempt limit" | No | Server-counted rows in `module_attempts` |
| "I am enrolled in this course" | No | `findEnrollment()` — Part 8, re-checked here independently |
| "This module belongs to this lesson/course" | No | A course-scoped Sanity query, mirroring Part 4 Step 9's pattern one level deeper |

The critical distinction in this table, worth internalizing permanently: **the student's raw answer is trustworthy data** (it genuinely is whatever they clicked or typed) — what's *never* trustworthy is any claim, computed anywhere outside our server, about whether that answer happens to be *correct*.

### The Verification

No code to verify — but before proceeding, make sure you can articulate why row three ("I selected option 2") is safe to trust while row four ("...happens to be correct") is not, even though Part 10's code treated both identically.

---

## Step 2 — Removing answer keys from every browser-facing query

### The Target

Updating `lessonWithinCourseQuery` in `sanity/lib/queries.ts` to strip `correctOptionIndex` and `expectedKeywords`, mirroring the restriction Part 4's `previewLessonQuery` already applied to the public catalog — closing the exact gap Part 10 left open in the *authenticated* lesson query.

### The Concept

Recall Part 4, Step 9 introduced the conditional-projection technique (`_type == "quizBlock" => {...}`) specifically for the public preview query. Part 10's interactive lesson player, however, used `lessonWithinCourseQuery`, which fetches lesson `content` with no restriction at all — meaning the full quiz/code-exercise block, answer key included, has been flowing to the browser since Part 9. This step applies the identical restriction pattern to this second query, so **every** query a browser-rendered page ever touches is now answer-key-free.

### The Implementation

#### `sanity/lib/queries.ts` (replace `lessonWithinCourseQuery`)

```ts
// UPDATED: this query now excludes correctOptionIndex and
// expectedKeywords entirely — the exact fields Part 10's vulnerability
// relied on. This is not a rendering-layer fix; the data is now simply
// absent from the network response, regardless of what any component
// chooses to display.
export const lessonWithinCourseQuery = /* groq */ `
  *[
    _type == "course" &&
    slug.current == $courseSlug &&
    isPublished == true
  ][0]
  .chapters[]->.lessons[]->[slug.current == $lessonSlug][0]{
    _id,
    title,
    slug,
    order,
    isPreview,
    videoUrl,
    content[]{
      ...,
      _type == "quizBlock" => {
        _type,
        _key,
        moduleId,
        question,
        options
      },
      _type == "codeExerciseBlock" => {
        _type,
        _key,
        moduleId,
        prompt,
        language,
        starterCode
      }
    }
  }
`;
```

Now, update the Zod config schemas that validate this data at render time (Part 10, Step 3) to match — these fields should no longer even be *expected*, let alone required:

#### `lib/modules/registry.ts` (updated config schemas only)

```ts
export const quizConfigSchema = z.object({
  moduleId: z.string().min(1),
  question: z.string().min(1),
  options: z.array(z.string().min(1)).min(2),
  // correctOptionIndex REMOVED — it no longer arrives from the query
  // above, and this schema should not expect (or silently accept) it.
});
export type QuizConfig = z.infer<typeof quizConfigSchema>;

export const codeExerciseConfigSchema = z.object({
  moduleId: z.string().min(1),
  prompt: z.string().min(1),
  language: z.enum(["sql", "javascript", "plaintext"]),
  starterCode: z.string().optional().default(""),
  // expectedKeywords REMOVED — same reasoning as above.
});
export type CodeExerciseConfig = z.infer<typeof codeExerciseConfigSchema>;

// reflectionConfigSchema and checkpointConfigSchema are unchanged —
// they never contained answer-key data in the first place.
```

### The Verification

```bash
npm run dev
```

While signed in, open the "Writing Your First Query" lesson. Open DevTools → Network tab, reload, and find the network request that fetches this lesson's Sanity content (look for a request to your Sanity project's API domain). Inspect its response body directly and confirm — by reading it yourself, not by trusting the UI — that **no field named `correctOptionIndex` or `expectedKeywords` appears anywhere in the payload.**

The quiz UI will currently look broken or throw a TypeScript error where it references `config.correctOptionIndex` — that's expected and correct at this exact moment; we fix the component itself in the next step.

```bash
npx tsc --noEmit
```

This should now show a real compile error inside `multiple-choice-quiz.tsx` and `code-exercise.tsx`, telling you exactly where the removed fields were still being referenced — a good demonstration of TypeScript catching this class of mistake immediately, rather than it silently shipping.

---

## Step 3 — Simplifying the module components (no more client-side grading)

### The Target

Updating `components/modules/multiple-choice-quiz.tsx` and `components/modules/code-exercise.tsx` to remove all client-side correctness computation, and simplifying the plugin contract's `submit` signature back to a single argument.

### The Concept

With the answer key gone from `config`, there is nothing left for these components to grade — which is exactly the point. Their job shrinks to something simpler and safer: collect the student's raw input, and hand it to `submit()`. This is a good moment to notice something reassuring about good architecture: fixing a serious security bug here required **deleting code**, not adding complexity — the plugin contract actually gets simpler, not more convoluted, once the browser is no longer asked to do a job it should never have been trusted with.

### The Implementation

#### `lib/modules/types.ts` (simplify the `submit` signature)

```ts
export interface GreyMatterModuleProps<TConfig, TSubmission> {
  moduleId: string;
  lessonId: string;
  courseId: string;
  config: TConfig;
  initialAttempt: ModuleAttemptSnapshot | null;
  // SIMPLIFIED: back to a single argument. There is no longer a
  // "grading hint" for the module to compute and pass along — grading
  // happens entirely server-side, inside submit()'s implementation.
  submit: (submission: TSubmission) => Promise<ModuleSubmissionResult>;
}

// NEW: a small, closed set of error codes the server can return,
// distinct from the free-text "message" shown to the user. Building a
// UI around a stable code (rather than parsing message text) is a small
// but genuinely useful habit — Part 15's analytics can later count
// occurrences of each code without any string-matching fragility.
export type ModuleErrorCode =
  | "NOT_ENROLLED"
  | "MODULE_NOT_FOUND"
  | "ATTEMPT_LIMIT_EXCEEDED"
  | "INVALID_SUBMISSION"
  | "SUBMISSION_TOO_LARGE"
  | "UNKNOWN_ERROR";

export interface ModuleSubmissionResult {
  success: boolean;
  isCorrect: boolean | null;
  score: number | null;
  message: string;
  errorCode?: ModuleErrorCode;
}
```

#### `components/modules/multiple-choice-quiz.tsx` (full, simplified rewrite)

```tsx
"use client";

import { cn } from "@/lib/cn";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { useModuleSubmission } from "@/lib/modules/use-module-submission";
import type { GreyMatterModuleProps } from "@/lib/modules/types";
import type { QuizConfig } from "@/lib/modules/registry";
import { useState } from "react";

interface QuizSubmission {
  selectedOptionIndex: number;
}

export function MultipleChoiceQuiz({
  config,
  initialAttempt,
  submit,
}: GreyMatterModuleProps<QuizConfig, QuizSubmission>) {
  const [selectedIndex, setSelectedIndex] = useState<number | null>(
    (initialAttempt?.submission as QuizSubmission | undefined)?.selectedOptionIndex ?? null
  );

  // useModuleSubmission (built in Step 9) centralizes the
  // optimistic-UI + submit-and-reconcile pattern shared by every
  // gradeable module, so we don't hand-roll useOptimistic/useTransition
  // separately in each one.
  const { result, isPending, submitOptimistically } = useModuleSubmission<QuizSubmission>({
    initialResult: initialAttempt
      ? {
          success: true,
          isCorrect: initialAttempt.isCorrect,
          score: initialAttempt.score,
          message: initialAttempt.isCorrect ? "Correct!" : "Not quite — review below.",
        }
      : null,
    submit,
  });

  const isLockedIn = result?.isCorrect === true;

  function handleSubmit() {
    if (selectedIndex === null) return;
    // NOTICE: no correctness computation happens here at all anymore.
    // We hand the RAW answer to the server and wait to be told the
    // truth — exactly the "browser proposes, server disposes" principle
    // from Part 0, now fully realized in code.
    submitOptimistically({ selectedOptionIndex: selectedIndex }, "Checking your answer...");
  }

  return (
    <div className="my-6 flex flex-col gap-3 rounded-[var(--radius-panel)] border border-border bg-surface p-4">
      <p className="font-semibold text-text-primary">{config.question}</p>
      <div className="flex flex-col gap-2">
        {config.options.map((option, index) => (
          <label
            key={index}
            className={cn(
              "flex cursor-pointer items-center gap-2 rounded-[var(--radius-control)] border px-3 py-2 text-sm",
              selectedIndex === index ? "border-brand bg-surface-inset" : "border-border"
            )}
          >
            <input
              type="radio"
              name={`quiz-${config.moduleId}`}
              checked={selectedIndex === index}
              onChange={() => setSelectedIndex(index)}
              disabled={isLockedIn}
            />
            {option}
          </label>
        ))}
      </div>
      <Button
        variant="primary"
        size="sm"
        className="w-fit"
        onClick={handleSubmit}
        disabled={selectedIndex === null || isPending || isLockedIn}
      >
        {isPending ? "Checking..." : isLockedIn ? "Completed" : "Submit answer"}
      </Button>
      {result && (
        <Alert variant={result.isCorrect === false ? "danger" : result.isCorrect === true ? "success" : "info"}>
          {result.message}
        </Alert>
      )}
    </div>
  );
}
```

#### `components/modules/code-exercise.tsx` (full, simplified rewrite)

```tsx
"use client";

import { useState } from "react";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import { useModuleSubmission } from "@/lib/modules/use-module-submission";
import type { GreyMatterModuleProps } from "@/lib/modules/types";
import type { CodeExerciseConfig } from "@/lib/modules/registry";

interface CodeExerciseSubmission {
  responseText: string;
}

const languageLabels: Record<CodeExerciseConfig["language"], string> = {
  sql: "SQL",
  javascript: "JavaScript",
  plaintext: "Text",
};

export function CodeExercise({
  config,
  initialAttempt,
  submit,
}: GreyMatterModuleProps<CodeExerciseConfig, CodeExerciseSubmission>) {
  const [responseText, setResponseText] = useState<string>(
    (initialAttempt?.submission as CodeExerciseSubmission | undefined)?.responseText ??
      config.starterCode ??
      ""
  );

  const { result, isPending, submitOptimistically } = useModuleSubmission<CodeExerciseSubmission>({
    initialResult: initialAttempt
      ? {
          success: true,
          isCorrect: initialAttempt.isCorrect,
          score: initialAttempt.score,
          message: initialAttempt.isCorrect ? "Looks good!" : "Not quite — review below.",
        }
      : null,
    submit,
  });

  function handleSubmit() {
    if (responseText.trim().length === 0) return;
    // No keyword-matching happens here anymore either — the server
    // fetches config.expectedKeywords fresh from Sanity and grades
    // there, entirely out of this component's reach.
    submitOptimistically({ responseText }, "Checking your answer...");
  }

  return (
    <div className="my-6 flex flex-col gap-3 rounded-[var(--radius-panel)] border border-border bg-surface p-4">
      <div className="flex items-center justify-between">
        <p className="font-semibold text-text-primary">{config.prompt}</p>
        <span className="rounded-full bg-surface-inset px-2 py-0.5 text-xs text-text-secondary">
          {languageLabels[config.language]}
        </span>
      </div>
      <Textarea
        value={responseText}
        onChange={(e) => setResponseText(e.target.value)}
        rows={6}
        className="font-mono text-sm"
        aria-label="Your response"
      />
      <Button
        variant="primary"
        size="sm"
        className="w-fit"
        onClick={handleSubmit}
        disabled={responseText.trim().length === 0 || isPending}
      >
        {isPending ? "Checking..." : "Submit"}
      </Button>
      {result && (
        <Alert variant={result.isCorrect === false ? "danger" : result.isCorrect === true ? "success" : "info"}>
          {result.message}
        </Alert>
      )}
    </div>
  );
}
```

We'll build `useModuleSubmission` itself in Step 9 — for now, note that both components already assume it exists with this exact signature.

### The Verification

```bash
npx tsc --noEmit
```

This will still show errors — `useModuleSubmission` doesn't exist yet, and `ModuleRenderer`'s `submit` closure (Part 10) still expects a second `grading` argument. Both are resolved by the end of this part; continue to the next steps.

---

## Step 4 — The server-only assessment definition query and grading function

### The Target

`sanity/lib/queries.ts` (append) — a new, **server-only** query fetching exactly the answer key needed to grade one specific module, scoped through the course/lesson relationship exactly like Part 4 Step 9's lesson query. And `lib/modules/grading.ts` — the function that uses it to compute an authoritative result.

### The Concept

This query must never be imported into any Client Component, and must never have its result serialized back to the browser — it exists exclusively to be called from inside `submitModuleAttempt` (a Server Action), whose only client-visible surface is its final, safe return value. We reuse Part 4 Step 9's exact scoping technique — course → chapters → lessons → this specific lesson — and extend it one level further, into the lesson's `content` array, to reach one specific module by `moduleId`. This proves, at the query level, that the module genuinely belongs to the lesson which genuinely belongs to the course — not merely that a module with this ID exists *somewhere* in the entire dataset.

### The Implementation

#### `sanity/lib/queries.ts` (append)

```ts
export interface AssessmentDefinition {
  _type: "quizBlock" | "codeExerciseBlock" | "reflectionBlock" | "checkpointBlock";
  moduleId: string;
  correctOptionIndex?: number;
  optionCount?: number;
  expectedKeywords?: string[];
}

// ⚠️ SERVER-ONLY QUERY ⚠️
// This query fetches exactly the fields needed to GRADE a submission —
// including the answer key itself. It must ONLY ever be called from
// server-side code (a Server Action, a Route Handler) whose response to
// the browser is a separately-constructed, safe object — never the raw
// result of this query. Never import this query into a Client Component,
// and never spread its result directly into a client-facing response.
//
// Notice the scoping chain: course (_id == $courseId) → chapters →
// lessons (_id == $lessonId) → content (moduleId == $moduleId). This is
// Part 4 Step 9's course-scoped lesson pattern, extended one level
// deeper — a module's answer key can only be reached by proving it
// belongs to a lesson that belongs to the exact course claimed.
export const assessmentDefinitionQuery = /* groq */ `
  *[_type == "course" && _id == $courseId][0]
  .chapters[]->.lessons[]->[_id == $lessonId][0]
  .content[moduleId == $moduleId][0]{
    _type,
    moduleId,
    correctOptionIndex,
    "optionCount": count(options),
    expectedKeywords
  }
`;
```

Now, the grading function itself — pure, synchronous business logic, deliberately kept separate from the Server Action's authentication/authorization plumbing so it can be tested in isolation (a habit Part 16's unit tests will lean on directly):

#### `lib/modules/grading.ts`

```ts
import { z } from "zod";
import type { AssessmentDefinition } from "@/sanity/lib/queries";

export interface GradingOutcome {
  isCorrect: boolean | null;
  score: number | null;
}

// A distinct error type for grading-specific failures — lets the caller
// (Step 6's Server Action) distinguish "this submission was malformed
// for THIS module type" from generic unexpected errors.
export class ModuleGradingError extends Error {}

const quizSubmissionSchema = z.object({
  selectedOptionIndex: z.number().int().min(0),
});

const textSubmissionSchema = z.object({
  responseText: z.string().min(1).max(5000),
});

// clampScore guarantees the number we ever write to the database (and
// return to the browser) is always a sane 0–100 value, regardless of
// how it was computed — the same defensive habit as Part 2's
// ProgressBar clamp, applied here to a security-relevant number instead
// of a purely cosmetic one.
function clampScore(value: number): number {
  return Math.min(100, Math.max(0, Math.round(value)));
}

// THE authoritative grading function. It NEVER trusts anything about
// correctness from its caller — only the raw submission and a FRESHLY
// FETCHED assessment definition (the answer key), obtained by the
// Server Action via assessmentDefinitionQuery above.
export function gradeSubmission(
  assessment: AssessmentDefinition,
  rawSubmission: unknown
): GradingOutcome {
  switch (assessment._type) {
    case "quizBlock": {
      const parsed = quizSubmissionSchema.safeParse(rawSubmission);
      if (!parsed.success) {
        throw new ModuleGradingError("Submission does not match the expected quiz answer shape.");
      }
      if (assessment.correctOptionIndex === undefined) {
        throw new ModuleGradingError("Assessment definition is missing its answer key.");
      }
      const isCorrect = parsed.data.selectedOptionIndex === assessment.correctOptionIndex;
      return { isCorrect, score: isCorrect ? 100 : 0 };
    }

    case "codeExerciseBlock": {
      const parsed = textSubmissionSchema.safeParse(rawSubmission);
      if (!parsed.success) {
        throw new ModuleGradingError("Submission does not match the expected text response shape.");
      }
      if (!assessment.expectedKeywords || assessment.expectedKeywords.length === 0) {
        throw new ModuleGradingError("Assessment definition is missing its expected keywords.");
      }
      const normalized = parsed.data.responseText.toLowerCase();
      const matchedCount = assessment.expectedKeywords.filter((keyword) =>
        normalized.includes(keyword.toLowerCase())
      ).length;
      // Partial credit — a demonstration of clamping applied to a
      // genuinely variable computed value, not just a fixed 0/100.
      const rawScore = (matchedCount / assessment.expectedKeywords.length) * 100;
      const score = clampScore(rawScore);
      return { isCorrect: score === 100, score };
    }

    case "reflectionBlock":
    case "checkpointBlock":
      // No answer key exists for these types — recall Part 10, Step 8's
      // observation that "never trust the client" is a targeted
      // principle, applied only where correctness genuinely exists.
      return { isCorrect: null, score: null };

    default:
      throw new ModuleGradingError(`Unknown assessment type: ${assessment._type}`);
  }
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete cleanly for these two new files (unrelated pre-existing errors from Step 3 may still be present — that's expected until Step 9).

---

## Step 5 — Public error codes and the submission Zod schema

### The Target

`lib/modules/submission-schema.ts` — a Zod schema for the Server Action's *input*, including size limits, and a small helper mapping internal failures to the public `ModuleErrorCode`s defined in Step 3.

### The Concept

Recall Part 4's "safe error messages" principle: a failure inside our grading logic should never leak internal detail (a stack trace, a raw database error, a hint about our schema) to the browser. This step formalizes that as a small, closed mapping — every possible failure path in the upcoming Server Action resolves to exactly one of a short list of known-safe codes and messages.

### The Implementation

#### `lib/modules/submission-schema.ts`

```ts
import { z } from "zod";

// A generous but FINITE limit on submission size. Without this, nothing
// stops a malicious request from sending a multi-megabyte JSON blob as
// "submission," which would be stored as-is in our jsonb column
// (Part 5) — wasting storage and, at scale, a real resource-exhaustion
// vector. 5,000 characters comfortably covers any legitimate quiz
// answer or written reflection in this application.
const MAX_SUBMISSION_JSON_LENGTH = 5000;

export const submitModuleAttemptSchema = z.object({
  lessonId: z.string().min(1),
  courseId: z.string().min(1),
  moduleId: z.string().min(1),
  submission: z.unknown(),
  // A client-generated identifier for THIS specific submission attempt —
  // see Step 6. Optional so older/simpler callers still work, but every
  // module built in this series always sends one.
  idempotencyKey: z.string().uuid().optional(),
}).refine(
  (data) => JSON.stringify(data.submission).length <= MAX_SUBMISSION_JSON_LENGTH,
  { message: "Submission is too large.", path: ["submission"] }
);

export type SubmitModuleAttemptInput = z.infer<typeof submitModuleAttemptSchema>;

// The maximum number of graded attempts a student may make on a single
// module. Kept as a simple, named constant rather than scattered magic
// numbers — easy to find and adjust later (e.g. per-course configurable
// limits would be a natural future enhancement, out of scope here).
export const MAX_ATTEMPTS_PER_MODULE = 5;
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete cleanly.

---

## Step 6 — Schema addition: idempotency keys on `module_attempts`

### The Target

Adding an `idempotencyKey` column to the `module_attempts` table, with a compound unique constraint that only enforces uniqueness when a key is actually provided.

### The Concept

Recall Part 6's webhook idempotency pattern: record a unique identifier for an operation *before* doing the real work, so a retried request can be recognized and short-circuited rather than duplicated. We apply the identical pattern here, but for a **client-initiated** action instead of an external webhook — protecting against network-level retries (a flaky connection causing the same "Submit" click's request to be sent twice) producing two separate attempt rows for what was, from the student's perspective, one single action.

A genuinely useful detail about PostgreSQL worth knowing here: a `UNIQUE` constraint treats multiple `NULL` values as **not conflicting with each other** — meaning we can make `idempotencyKey` optional/nullable while still gaining full protection whenever a real key *is* provided.

### The Implementation

#### `db/schema/module-attempts.ts` (add one column and one constraint)

```ts
import {
  boolean,
  integer,
  jsonb,
  pgTable,
  text,
  timestamp,
  unique,
  uuid,
} from "drizzle-orm/pg-core";
import { users } from "./users";

export const moduleAttempts = pgTable(
  "module_attempts",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
    lessonId: text("lesson_id").notNull(),
    moduleId: text("module_id").notNull(),
    attemptNumber: integer("attempt_number").notNull().default(1),
    submission: jsonb("submission").notNull(),
    score: integer("score"),
    isCorrect: boolean("is_correct"),

    // NEW — nullable, since not every caller is required to provide
    // one, but every real submission from our UI (Step 9) always does.
    idempotencyKey: text("idempotency_key"),

    submittedAt: timestamp("submitted_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [
    unique("module_attempts_user_module_attempt_unique").on(
      table.userId,
      table.moduleId,
      table.attemptNumber
    ),
    // Only enforces uniqueness among rows where idempotencyKey is NOT
    // null — exactly the Postgres NULL behavior described above.
    unique("module_attempts_user_module_idempotency_unique").on(
      table.userId,
      table.moduleId,
      table.idempotencyKey
    ),
  ]
);
```

Generate and apply the migration:

```bash
npm run db:generate
npm run db:migrate
```

### The Verification

```bash
npm run db:studio
```

Confirm `module_attempts` now shows a nullable `idempotency_key` column, and confirm (via Neon's console SQL editor, or Drizzle Studio's constraints panel) that both unique constraints listed above now exist on the table.

Add the corresponding query helper:

#### `db/queries/module-attempts.ts` (append)

```ts
export async function findAttemptByIdempotencyKey(
  userId: string,
  moduleId: string,
  idempotencyKey: string
) {
  return db.query.moduleAttempts.findFirst({
    where: and(
      eq(moduleAttempts.userId, userId),
      eq(moduleAttempts.moduleId, moduleId),
      eq(moduleAttempts.idempotencyKey, idempotencyKey)
    ),
  });
}
```

```bash
npx tsc --noEmit
```

Should complete cleanly.

---

## Step 7 — Atomic writes: attempt, lesson progress, and audit log together

### The Target

`db/queries/lesson-progress.ts` (append) — an upsert helper marking a lesson `IN_PROGRESS` the moment a student interacts with any module inside it — and `db/queries/audit-logs.ts` — a small helper recording this event, both designed to run **inside the same transaction** as the attempt insert itself.

### The Concept

Recall Part 5's `lesson_progress` table was designed back then but, notice carefully, has never actually been *written to* anywhere in this series until now — Part 9's "last visited lesson" tracking only ever touched `course_progress`. This part is the natural, correct place to finally populate it: a student meaningfully engaging with a lesson's interactive content is a clear, unambiguous signal that the lesson is now "in progress," worth recording atomically alongside the attempt that triggered it.

### The Implementation

First, a small TypeScript type alias for Drizzle's transaction client — worth defining once, since we'll reuse it across query helpers that need to work both standalone and inside a transaction:

#### `db/transaction-type.ts`

```ts
import type { db } from "@/db/client";

// A transaction callback's "tx" parameter has a slightly different type
// than the top-level "db" export, even though it supports the same
// query API. This utility type extracts that exact shape from
// db.transaction's own signature, so our query helpers can accept
// EITHER the real db client or an active transaction interchangeably.
export type DbClientOrTransaction = Parameters<Parameters<typeof db.transaction>[0]>[0];
```

#### `db/queries/lesson-progress.ts` (append)

```ts
import type { DbClientOrTransaction } from "@/db/transaction-type";
import { lessonProgress } from "@/db/schema";

export interface UpsertLessonProgressInput {
  userId: string;
  enrollmentId: string;
  courseId: string;
  lessonId: string;
  status: "IN_PROGRESS" | "COMPLETED";
}

// Accepts either the real db client OR an active transaction (tx) —
// this is what lets Step 8 call it from INSIDE a transaction alongside
// the attempt insert, guaranteeing both writes succeed or fail together.
export async function upsertLessonProgress(
  client: DbClientOrTransaction,
  input: UpsertLessonProgressInput
) {
  await client
    .insert(lessonProgress)
    .values({
      userId: input.userId,
      enrollmentId: input.enrollmentId,
      courseId: input.courseId,
      lessonId: input.lessonId,
      status: input.status,
      completedAt: input.status === "COMPLETED" ? new Date() : null,
    })
    .onConflictDoUpdate({
      // Targets the exact columns behind Part 5's
      // lesson_progress_user_lesson_unique constraint — Drizzle uses
      // this to know WHICH existing row to update on a conflict.
      target: [lessonProgress.userId, lessonProgress.lessonId],
      set: {
        status: input.status,
        completedAt: input.status === "COMPLETED" ? new Date() : null,
        updatedAt: new Date(),
      },
    });
}
```

#### `db/queries/audit-logs.ts`

```ts
import type { DbClientOrTransaction } from "@/db/transaction-type";
import { auditLogs } from "@/db/schema";

export interface RecordAuditLogInput {
  userId: string | null;
  action: string;
  metadata?: unknown;
}

export async function recordAuditLog(client: DbClientOrTransaction, input: RecordAuditLogInput) {
  await client.insert(auditLogs).values({
    userId: input.userId,
    action: input.action,
    metadata: input.metadata ?? null,
  });
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete cleanly. We verify these functions' real behavior in Step 8's combined transaction, next.

---

## Step 8 — Rebuilding the secure Server Action end to end

### The Target

The complete, final rewrite of `lib/modules/submit-module-attempt.ts` — implementing every layer from Step 1's trust-boundary table, in order, ending in one atomic transaction.

### The Concept

This is where every piece built in this part converges. Read the ordering of checks carefully — it directly mirrors Step 1's table, top to bottom, and each check exists specifically to close one row of that table.

### The Implementation

First, we need `findEnrollment` (from Part 8) importable here, and a query helper for counting attempts (already built in Part 10):

#### `lib/modules/submit-module-attempt.ts` (complete rewrite)

```ts
"use server";

import { client as sanityClient } from "@/sanity/lib/client";
import {
  assessmentDefinitionQuery,
  type AssessmentDefinition,
} from "@/sanity/lib/queries";
import { requireUser } from "@/lib/auth/require-user";
import { db } from "@/db/client";
import { moduleAttempts } from "@/db/schema";
import {
  countAttemptsForModule,
  findAttemptByIdempotencyKey,
} from "@/db/queries/module-attempts";
import { findEnrollment } from "@/db/queries/enrollments";
import { upsertLessonProgress } from "@/db/queries/lesson-progress";
import { recordAuditLog } from "@/db/queries/audit-logs";
import {
  submitModuleAttemptSchema,
  MAX_ATTEMPTS_PER_MODULE,
} from "./submission-schema";
import { gradeSubmission, ModuleGradingError } from "./grading";
import type { ModuleSubmissionResult, ModuleErrorCode } from "./types";

function errorResult(errorCode: ModuleErrorCode, message: string): ModuleSubmissionResult {
  return { success: false, isCorrect: null, score: null, message, errorCode };
}

export async function submitModuleAttempt(input: unknown): Promise<ModuleSubmissionResult> {
  // ── Layer 1: Authentication ─────────────────────────────────────
  const user = await requireUser();

  // ── Layer 2: Shape + size validation (Zod) ──────────────────────
  const parsed = submitModuleAttemptSchema.safeParse(input);
  if (!parsed.success) {
    const tooLarge = parsed.error.issues.some((issue) => issue.path.includes("submission"));
    return errorResult(
      tooLarge ? "SUBMISSION_TOO_LARGE" : "INVALID_SUBMISSION",
      tooLarge ? "Your submission is too large." : "Invalid submission."
    );
  }
  const { lessonId, courseId, moduleId, submission, idempotencyKey } = parsed.data;

  // ── Layer 3: Idempotency short-circuit ──────────────────────────
  // If this EXACT submission (same key) was already processed, return
  // its already-recorded result immediately — never re-grade, never
  // insert a second row, regardless of how many times this exact
  // request happens to arrive (e.g. a network-level retry).
  if (idempotencyKey) {
    const existingAttempt = await findAttemptByIdempotencyKey(user.id, moduleId, idempotencyKey);
    if (existingAttempt) {
      return {
        success: true,
        isCorrect: existingAttempt.isCorrect,
        score: existingAttempt.score,
        message: existingAttempt.isCorrect === false ? "Not quite — review below." : "Submitted successfully.",
      };
    }
  }

  // ── Layer 4: Enrollment verification ────────────────────────────
  const enrollment = await findEnrollment(user.id, courseId);
  if (!enrollment || enrollment.status === "CANCELLED") {
    await recordAuditLog(db, {
      userId: user.id,
      action: "module_attempt.rejected",
      metadata: { reason: "not_enrolled", courseId, moduleId },
    });
    return errorResult("NOT_ENROLLED", "You are not enrolled in this course.");
  }

  // ── Layer 5: Course-scoped assessment lookup (the answer key) ───
  // THIS is the query that never reaches the browser. It also proves,
  // structurally, that this moduleId genuinely belongs to this lesson,
  // which genuinely belongs to this course — mirroring Part 4 Step 9's
  // guarantee, now enforced for module submissions too.
  const assessment = await sanityClient.fetch<AssessmentDefinition | null>(
    assessmentDefinitionQuery,
    { courseId, lessonId, moduleId }
  );

  if (!assessment) {
    await recordAuditLog(db, {
      userId: user.id,
      action: "module_attempt.rejected",
      metadata: { reason: "module_not_found", courseId, lessonId, moduleId },
    });
    return errorResult("MODULE_NOT_FOUND", "This exercise could not be found.");
  }

  // ── Layer 6: Attempt limit ───────────────────────────────────────
  const previousAttemptCount = await countAttemptsForModule(user.id, moduleId);
  if (previousAttemptCount >= MAX_ATTEMPTS_PER_MODULE) {
    return errorResult(
      "ATTEMPT_LIMIT_EXCEEDED",
      `You've reached the maximum of ${MAX_ATTEMPTS_PER_MODULE} attempts for this exercise.`
    );
  }

  // ── Layer 7: Authoritative, server-side grading ─────────────────
  let grading;
  try {
    grading = gradeSubmission(assessment, submission);
  } catch (error) {
    if (error instanceof ModuleGradingError) {
      return errorResult("INVALID_SUBMISSION", "Your submission couldn't be graded.");
    }
    console.error("Unexpected grading error:", error);
    return errorResult("UNKNOWN_ERROR", "Something went wrong. Please try again.");
  }

  // ── Layer 8: The atomic write ────────────────────────────────────
  try {
    await db.transaction(async (tx) => {
      await tx.insert(moduleAttempts).values({
        userId: user.id,
        lessonId,
        moduleId,
        attemptNumber: previousAttemptCount + 1,
        submission,
        score: grading.score,
        isCorrect: grading.isCorrect,
        idempotencyKey: idempotencyKey ?? null,
      });

      await upsertLessonProgress(tx, {
        userId: user.id,
        enrollmentId: enrollment.id,
        courseId,
        lessonId,
        status: "IN_PROGRESS",
      });

      await recordAuditLog(tx, {
        userId: user.id,
        action: "module_attempt.recorded",
        metadata: { moduleId, lessonId, isCorrect: grading.isCorrect, score: grading.score },
      });
    });
  } catch (error) {
    console.error("Failed to record module attempt:", error);
    return errorResult("UNKNOWN_ERROR", "Something went wrong. Please try again.");
  }

  return {
    success: true,
    isCorrect: grading.isCorrect,
    score: grading.score,
    message:
      grading.isCorrect === false
        ? "Not quite — review below."
        : grading.isCorrect === true
          ? "Correct!"
          : "Submitted successfully.",
  };
}
```

**Code walkthrough:**

- Every failure path returns via `errorResult(...)`, never `throw` — exactly Part 8's lesson about Server Actions and `useActionState`-style consumers, applied here even though this action isn't driven by `useActionState` directly (Step 9's hook plays that role instead).
- Notice **Layer 5 runs before Layer 6** — we look up whether the module genuinely exists before checking attempt counts against it, since counting attempts for a module that doesn't even exist would be a meaningless check performed in the wrong order.
- The three database writes inside `db.transaction(...)` — the attempt, the lesson-progress upsert, and the audit log — either **all** succeed or **all** roll back together. If the audit-log insert somehow failed (e.g., a transient constraint issue), we would not want a "ghost" attempt recorded with no lesson-progress update reflecting it — the transaction guarantees that can never happen.
- We deliberately return the exact same `errorResult("MODULE_NOT_FOUND", ...)` for both "this module doesn't exist anywhere" and "this module exists but not within this course/lesson" — the identical "don't leak which case it was" principle from Part 7, applied here to prevent an attacker from using error-message differences to probe which course/lesson/module combinations are valid.

### The Verification

```bash
npx tsc --noEmit
```

This should now show errors only in `module-renderer.tsx` (still calling `submit` with a `grading` second argument from Part 10) — fix that now:

#### `components/modules/module-renderer.tsx` (update the `submit` closure)

```tsx
  // Replace the Part 10 two-argument version with this simplified one —
  // no grading hint is passed anymore; idempotencyKey is generated
  // fresh for each logical submission by useModuleSubmission (Step 9).
  async function submit(submission: unknown) {
    return submitModuleAttempt({ lessonId, courseId, moduleId, submission });
  }
```

```bash
npx tsc --noEmit
```

Should now show errors only for the not-yet-built `useModuleSubmission` hook — continue to Step 9.

---

## Step 9 — Reliable optimistic UI with `useOptimistic`

### The Target

`lib/modules/use-module-submission.ts` — a shared Client-side hook wrapping every gradeable module's submit flow with React 19's `useOptimistic`, providing an honest, transitional "Checking..." state rather than a false, guessed correctness.

### The Concept

Recall Part 10's naive version let the browser *guess* correctness instantly (since it had the answer key). Now that the answer key is gone, there is nothing left to optimistically guess about correctness — and that's the correct, honest outcome, not a limitation to work around. What we *can* still do optimistically is show immediate feedback that the submission was received and is being checked, giving the interface a responsive, "alive" feel while we wait for the one thing only the server can tell us: whether the answer was actually right.

`useOptimistic` is a React 19 Hook for exactly this shape of problem: showing a provisional value immediately, which is automatically replaced the moment the real, awaited result arrives — with automatic "rollback" built in, since the optimistic value is never persisted anywhere; it simply exists until the real state updates.

### The Implementation

#### `lib/modules/use-module-submission.ts`

```ts
"use client";

import { useOptimistic, useState, useTransition } from "react";
import type { ModuleSubmissionResult } from "./types";

interface UseModuleSubmissionOptions<TSubmission> {
  initialResult: ModuleSubmissionResult | null;
  submit: (submission: TSubmission) => Promise<ModuleSubmissionResult>;
}

export function useModuleSubmission<TSubmission>({
  initialResult,
  submit,
}: UseModuleSubmissionOptions<TSubmission>) {
  // "result" is the last CONFIRMED, server-authoritative outcome.
  const [result, setResult] = useState<ModuleSubmissionResult | null>(initialResult);

  // useOptimistic layers a TEMPORARY, provisional value on top of
  // "result" — it automatically reverts back to "result" the moment the
  // surrounding transition finishes, UNLESS we've explicitly called
  // setResult() with a new confirmed value in the meantime (which is
  // exactly what we do below, once the real server response arrives).
  const [optimisticResult, setOptimisticResult] = useOptimistic(result);

  const [isPending, startTransition] = useTransition();

  function submitOptimistically(submission: TSubmission, pendingMessage: string) {
    startTransition(async () => {
      // Deliberately HONEST: isCorrect/score are null here, not a guess.
      // We no longer have any legitimate basis to claim correctness
      // before the server responds — this IS the correct behavior now
      // that grading is fully server-side.
      setOptimisticResult({ success: true, isCorrect: null, score: null, message: pendingMessage });

      // A client-generated idempotency key, unique to THIS logical
      // submission — protects against network-level retries of this
      // exact request producing a duplicate attempt row (Step 6).
      const idempotencyKey = crypto.randomUUID();

      try {
        const outcome = await submit({ ...submission, idempotencyKey } as TSubmission & {
          idempotencyKey: string;
        });
        // Reconciliation: whatever the server says is now the new
        // confirmed truth — this is where an optimistic guess would be
        // "rolled back" if it were ever wrong; here, there was no guess
        // to roll back, only a transition from "unknown" to "known."
        setResult(outcome);
      } catch (error) {
        console.error("Module submission failed:", error);
        setResult({
          success: false,
          isCorrect: null,
          score: null,
          message: "Something went wrong. Please try again.",
          errorCode: "UNKNOWN_ERROR",
        });
      }
    });
  }

  return { result: optimisticResult, isPending, submitOptimistically };
}
```

**Code walkthrough:**

- `setOptimisticResult` may only be called from inside a `useTransition`-wrapped update (either the `startTransition` callback itself, or a function called synchronously within it) — this is a hard requirement of `useOptimistic`, not a style preference; calling it outside a transition throws at runtime.
- The `try/catch` around `submit(...)` handles a genuinely different failure mode than anything inside the Server Action itself: a total network failure (the request never reaches the server at all, or the connection drops) — the Server Action's own internal error handling (Step 8) cannot help here, since its code never ran.
- Notice the idempotency key is generated **fresh on every call** to `submitOptimistically` — meaning it protects against *retries of this one request*, not against a student clicking "Submit" twice in a row (that's separately prevented by `isPending` disabling the button, visible in both `MultipleChoiceQuiz` and `CodeExercise` from Step 3). These are two different problems with two different, appropriate defenses — worth noticing rather than conflating.

### The Verification

```bash
npx tsc --noEmit
npm run lint
npm run build
```

All three should now complete with **no errors** — every file across this part now compiles and links together correctly.

```bash
npm run dev
```

While signed in and enrolled, open the quiz lesson. Select an answer and click "Submit answer." Confirm you briefly see the button read "Checking..." and — if your connection is fast enough that this flashes by too quickly to see clearly — throttle your network in DevTools to "Slow 3G" temporarily and retry, confirming an `info`-styled "Checking your answer..." alert genuinely appears before the real green/red result replaces it.

Submit the correct answer this time and confirm the real, server-graded "Correct!" result appears, options lock, and Drizzle Studio's `module_attempts` table shows the new row with `idempotency_key` populated with a real UUID.

---

## Step 10 — Replaying Part 10's attack, and confirming it now fails

### The Target

No new code — the payoff verification of this entire part: repeating Part 10, Step 10's exact DevTools attack, and confirming it can no longer succeed.

### The Implementation and Verification

Open the quiz lesson, open DevTools → Network tab, select the **wrong** answer, and click "Submit answer." Find the `submitModuleAttempt` request and inspect its payload.

**Confirm there is no `clientComputedIsCorrect` field anywhere in the request** — the field doesn't exist in this part's schema at all anymore; there is nothing left resembling it to edit.

Now inspect the **response** to that same request. Confirm it correctly shows `isCorrect: false` — computed entirely server-side, from a fresh Sanity fetch you cannot see or influence from the browser.

For a final, direct confrontation with the fix: try to replicate Part 10's exact attack anyway — right-click the request, "Copy as fetch," and attempt to add any client-side `isCorrect`/`score`-like field to the payload before resending it. Confirm the server's response is **unaffected** by whatever you add — the Server Action's Zod schema (Step 5) simply has no field for it to land in, and even if it did, `gradeSubmission` (Step 4) never reads anything from the request except the raw `submission` itself.

Open Drizzle Studio and confirm the `module_attempts` row for this wrong answer correctly shows `is_correct: false`, `score: 0` — permanently, honestly recorded, exactly matching what the student actually submitted.

Run the complete verification suite one final time to close out this part:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Common mistakes

- **`useOptimistic` throws "can only be called within a transition"** — Confirm `setOptimisticResult(...)` is called *synchronously inside* the function passed to `startTransition`, not after an `await` inside it (calling it after the first `await` is a common mistake that moves it outside the transition's synchronous scope).
- **Idempotency check never triggers, even on a genuine duplicate request** — Confirm the exact same `idempotencyKey` value is genuinely being sent twice; since Step 9 generates a fresh UUID per `submitOptimistically` call, testing this requires manually replaying a captured request (as in Step 10), not just clicking Submit twice normally.
- **`gradeSubmission` throws `ModuleGradingError: Assessment definition is missing its answer key`** — Almost always means `assessmentDefinitionQuery` returned a result for the wrong module or a stale/incomplete document; confirm the `moduleId` sent from the client exactly matches the one authored in Sanity.
- **Attempt limit never triggers even after many submissions** — Confirm `countAttemptsForModule` is counting by `moduleId`, not `lessonId` — a lesson can contain multiple modules, and the limit is meant to apply per-module, not per-lesson.
- **`onConflictDoUpdate`'s `target` throws a runtime error about a missing constraint** — Confirm the column order in `target: [lessonProgress.userId, lessonProgress.lessonId]` exactly matches the order used in Part 5's `unique(...).on(table.userId, table.lessonId)` definition; Postgres matches conflict targets against the constraint's exact column set.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `sanity/lib/queries.ts` (modified — `lessonWithinCourseQuery` restricted, new `assessmentDefinitionQuery`), `lib/modules/registry.ts` (modified), `lib/modules/types.ts` (modified), `lib/modules/grading.ts`, `lib/modules/submission-schema.ts`, `lib/modules/use-module-submission.ts`, `lib/modules/submit-module-attempt.ts` (rewritten), `components/modules/multiple-choice-quiz.tsx` (modified), `components/modules/code-exercise.tsx` (modified), `components/modules/module-renderer.tsx` (modified), `db/schema/module-attempts.ts` (modified), `db/migrations/000X_*.sql` (new), `db/transaction-type.ts`, `db/queries/lesson-progress.ts` (modified), `db/queries/audit-logs.ts`, `db/queries/module-attempts.ts` (modified).

```bash
git commit -m "Part 11: secure server-side grading — answer keys removed from every browser-facing query, authoritative grading function, enrollment/attempt-limit/size checks, idempotency keys, atomic attempt+progress+audit transaction, honest useOptimistic UI"
```

---

## Reference: the eight-layer secure submission defense

| Layer | What it checks | Fails as |
|---|---|---|
| 1. Authentication | Someone is genuinely signed in | Blocked before any other code runs |
| 2. Shape + size validation | Well-formed, bounded submission | `INVALID_SUBMISSION` / `SUBMISSION_TOO_LARGE` |
| 3. Idempotency | Is this an exact retry of a known submission? | Returns the original recorded result |
| 4. Enrollment | Is this user genuinely enrolled? | `NOT_ENROLLED` |
| 5. Course-scoped module lookup | Does this module genuinely belong to this lesson/course? | `MODULE_NOT_FOUND` |
| 6. Attempt limit | Has this module been attempted too many times? | `ATTEMPT_LIMIT_EXCEEDED` |
| 7. Server-side grading | Compute correctness from a freshly-fetched, never-exposed answer key | `INVALID_SUBMISSION` (malformed answer) |
| 8. Atomic transaction | Attempt + lesson progress + audit log, all-or-nothing | `UNKNOWN_ERROR`, safely rolled back |

## Reference: what changed between Part 10 and Part 11, side by side

| | Part 10 (intentionally insecure) | Part 11 (fixed) |
|---|---|---|
| Where does grading happen? | In the browser (`MultipleChoiceQuiz`, `CodeExercise`) | Exclusively on the server (`gradeSubmission`) |
| Does the browser ever see the answer key? | Yes — `correctOptionIndex`/`expectedKeywords` in `config` | Never — stripped from every query |
| What does the client send? | The raw answer **plus a self-computed correctness claim** | Only the raw answer |
| Can DevTools fake a passing score? | Yes | No |
| `submit()` signature | `(submission, grading?)` | `(submission)` |

---

## What's next

Part 12 introduces Inngest — installing the client, serving the Inngest API route, defining our first typed events (`user/created`, `course/enrolled`, `lesson/completed`, `course/completed`), and writing our first durable background workflows: onboarding records, enrollment confirmation, and course-progress recalculation — finally emitting the `lesson/completed` event this part's secure submission flow has been quietly ready to trigger since the moment a module attempt is successfully recorded.
