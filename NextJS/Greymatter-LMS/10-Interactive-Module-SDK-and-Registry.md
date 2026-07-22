# Part 10 — Interactive Module SDK and Registry

## The goal

By the end of this part, GreyMatter LMS will have a real, extensible **interactive module system**: a typed plugin contract, a registry mapping Sanity block types to dynamically-loaded React components, runtime configuration validation, graceful fallbacks for unknown or malformed content, and five working interactive modules — a multiple-choice quiz, a short-answer exercise, a SQL syntax exercise, a reflective response, and a completion checkpoint — replacing the static, read-only placeholders Part 9's lesson player currently renders.

**A deliberate, important note before we begin:** this part will end with a fully working, end-to-end submission flow — but one that is **intentionally, visibly insecure** in one specific way, matching Part 0's warning almost exactly. We're building it this way on purpose, as a teaching device: you will be able to open your browser's DevTools and see the correct quiz answer sitting in the page's data, and you'll be able to fake a passing score. Part 11 exists entirely to fix this. Seeing the vulnerability work with your own eyes first will make Part 11's fix land far more meaningfully than if we simply asserted "never trust the client" without ever showing you what happens when you do.

## Why it exists

Part 3 designed `quizBlock` and `codeExerciseBlock` as authoring schemas. Part 4 rendered them as static, non-interactive previews on the public catalog. Part 9's authenticated lesson player rendered them as slightly nicer, but still non-interactive, placeholders. None of this has actually let a student *answer* anything yet. This part builds the missing piece: real, submittable, stateful interactive components — but architected as a genuine **plugin system**, so that adding a sixth or seventh module type in the future never requires touching the lesson player itself.

## The data flow

```text
Lesson content array (from Sanity, via Part 9's course-scoped query)
        │
        ▼
InteractiveLessonContent walks each Portable Text block
        │
        ├── Known block type (quizBlock, codeExerciseBlock, reflectionBlock, checkpointBlock)
        │     │
        │     ▼
        │   ModuleRenderer validates the block's config with Zod
        │     │
        │     ├── Valid   → dynamically loads and renders the matching module component
        │     └── Invalid → renders a graceful "content error" fallback
        │
        └── Unknown block type → renders a graceful "unsupported content" fallback
                │
                ▼
        Student interacts, clicks Submit
                │
                ▼
        submitModuleAttempt() Server Action — records the attempt in Neon
```

Terms worth defining before we build this:

- **Plugin contract**: a fixed shape (a TypeScript interface) that every interactive module component must implement, regardless of what it actually does internally. Think of it like a standard electrical outlet — any appliance that fits the plug shape can be plugged in, without the wall's wiring needing to know anything about *which* appliance it happens to be.
- **Dynamic import / lazy loading**: loading a piece of code only at the moment it's actually needed, rather than bundling it into the page's initial JavaScript download. If a lesson has no quiz in it, there's no reason to make every student download the quiz component's code — dynamic imports mean we only pay that cost when a lesson genuinely uses it.

---

## Step 1 — Designing the plugin contract

### The Target

`lib/modules/types.ts` — the shared TypeScript contract every interactive module component and the registry itself will depend on.

### The Concept

Recall the electrical outlet analogy above. Every module — quiz, code exercise, reflection, checkpoint — is wildly different in what it *asks* the student to do, but every single one needs exactly the same three things from its surroundings: **what to configure it with** (the authored question/prompt), **what the student previously did here, if anything** (so revisiting a lesson doesn't lose their answer), and **a way to persist a new answer** (without needing to know anything about databases, users, or authorization — that's the lesson player's job to provide, not the module's job to know about).

### The Implementation

#### `lib/modules/types.ts`

```ts
// The result shape every module submission resolves to, regardless of
// module type. "isCorrect" and "score" are nullable because some modules
// (reflection, checkpoint) have no notion of correctness at all — they
// simply record that the student did the activity.
export interface ModuleSubmissionResult {
  success: boolean;
  isCorrect: boolean | null;
  score: number | null;
  message: string;
}

// A snapshot of the student's most recent attempt at this specific
// module, if one exists — used to restore state when a student revisits
// a lesson they've already interacted with.
export interface ModuleAttemptSnapshot {
  attemptNumber: number;
  submission: unknown;
  isCorrect: boolean | null;
  score: number | null;
  submittedAt: string;
}

// THE PLUGIN CONTRACT. Every module component receives exactly these
// props and nothing more — it has no direct access to the database, the
// current user, or Sanity. This deliberate restriction is what makes the
// module system safe to extend: a new, untrusted-feeling module type
// can only ever do what this narrow interface allows.
export interface GreyMatterModuleProps<TConfig, TSubmission> {
  moduleId: string;
  lessonId: string;
  courseId: string;
  config: TConfig;
  initialAttempt: ModuleAttemptSnapshot | null;
  // The module calls this to persist an answer. It has NO knowledge of
  // HOW submission is persisted (Server Action today; could be
  // anything else later) — that separation of UI from persistence is
  // the whole point of this prop existing.
  submit: (submission: TSubmission) => Promise<ModuleSubmissionResult>;
}
```

**Code walkthrough:**

- Notice `submit` is a *function passed in as a prop*, not something the module component imports and calls directly. This is the "separating plugin UI from persistence logic" principle from the blueprint made concrete: `MultipleChoiceQuiz` (built in Step 6) will have zero imports related to databases, Server Actions, or authentication — it only knows "I have a function that takes my answer and gives me back a result."
- Generic type parameters `<TConfig, TSubmission>` let every module define its *own* shape for what it's configured with and what it submits, while still satisfying one shared interface — a `MultipleChoiceQuiz` submits `{ selectedOptionIndex: number }`, a `ReflectionResponse` submits `{ responseText: string }`, and neither needs to know about the other's shape.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors — this file has no dependencies yet.

---

## Step 2 — Extending the Sanity schema with two new module types

### The Target

`sanity/schema-types/reflection-block.ts` and `sanity/schema-types/checkpoint-block.ts` — two new, simple object types, extending Part 3's content model to round out our five planned modules.

### The Concept

Recall Part 3 gave us `quizBlock` (→ our multiple-choice quiz module) and `codeExerciseBlock` (→ our short-answer *and* SQL syntax exercise modules, distinguished by the existing `language` field). We're adding two more block types now specifically because they represent a **meaningfully different category** of interactive content: modules with **no correct answer at all**. This distinction matters enormously for this part's security narrative — as you'll see in Step 6 and Step 7, only the quiz and code-exercise modules have anything worth "faking," because only they have a correct answer to fake.

### The Implementation

#### `sanity/schema-types/reflection-block.ts`

```ts
import { EditIcon } from "@sanity/icons";
import { defineField, defineType } from "sanity";

// A reflection has NO correct answer — it simply asks a student to write
// a response and records that they did so. Notice this schema has no
// "correctAnswer" field of any kind, unlike quizBlock/codeExerciseBlock.
export const reflectionBlock = defineType({
  name: "reflectionBlock",
  title: "Reflection",
  type: "object",
  icon: EditIcon,
  fields: [
    defineField({
      name: "moduleId",
      title: "Module ID",
      type: "string",
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "prompt",
      title: "Prompt",
      type: "text",
      rows: 2,
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "minWords",
      title: "Minimum word count (suggested)",
      type: "number",
      description: "A soft guideline shown to the student — not strictly enforced.",
      initialValue: 20,
      validation: (rule) => rule.min(0),
    }),
  ],
  preview: {
    select: { title: "prompt", subtitle: "moduleId" },
  },
});
```

#### `sanity/schema-types/checkpoint-block.ts`

```ts
import { CheckmarkCircleIcon } from "@sanity/icons";
import { defineField, defineType } from "sanity";

// A checkpoint is the simplest possible module — a "mark as done" button
// with a custom label. Useful for lessons that want an explicit
// completion gesture (e.g. "I've set up my local environment") without
// any actual assessment attached.
export const checkpointBlock = defineType({
  name: "checkpointBlock",
  title: "Completion Checkpoint",
  type: "object",
  icon: CheckmarkCircleIcon,
  fields: [
    defineField({
      name: "moduleId",
      title: "Module ID",
      type: "string",
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "label",
      title: "Button label",
      type: "string",
      initialValue: "Mark as complete",
      validation: (rule) => rule.required(),
    }),
  ],
  preview: {
    select: { title: "label", subtitle: "moduleId" },
  },
});
```

Register both, and add both to the lesson's Portable Text `content` array:

#### `sanity/schema-types/lesson.ts` (update the `content` field's `of` array)

```ts
// Inside lesson.ts's content field, add two more array members alongside
// the existing calloutBlock/quizBlock/codeExerciseBlock entries:
defineArrayMember({ type: "reflectionBlock" }),
defineArrayMember({ type: "checkpointBlock" }),
```

#### `sanity/schema-types/index.ts` (updated)

```ts
import type { SchemaTypeDefinition } from "sanity";
import { calloutBlock } from "./callout-block";
import { category } from "./category";
import { chapter } from "./chapter";
import { checkpointBlock } from "./checkpoint-block";
import { codeExerciseBlock } from "./code-exercise-block";
import { course } from "./course";
import { instructor } from "./instructor";
import { lesson } from "./lesson";
import { quizBlock } from "./quiz-block";
import { reflectionBlock } from "./reflection-block";

export const schemaTypes: SchemaTypeDefinition[] = [
  course,
  category,
  instructor,
  chapter,
  lesson,
  calloutBlock,
  quizBlock,
  codeExerciseBlock,
  reflectionBlock,
  checkpointBlock,
];
```

### The Verification

```bash
npx tsc --noEmit
```

Restart the dev server, visit `http://localhost:3000/studio`, open your "Writing Your First Query" lesson, and confirm the content "+" menu now also offers "Reflection" and "Completion Checkpoint" alongside the existing options. Add one of each to this lesson for testing:

- A **Reflection** with Module ID `first-query-reflection`, prompt "What surprised you about SQL syntax so far?"
- A **Completion Checkpoint** with Module ID `first-query-checkpoint`, label "I've written my first query"

Click **Publish**.

---

## Step 3 — Zod configuration schemas and the dynamic-loading registry

### The Target

`lib/modules/registry.ts` — Zod schemas validating each module type's expected shape at runtime, paired with `next/dynamic`-loaded components for each.

### The Concept

Recall Part 3's warning: Sanity's own schema validation only runs *inside Studio*, at authoring time — it does not protect our React components from receiving malformed data at *render* time (a manual API edit, a schema migration bug, or simply older content authored before a field was added could all produce data that doesn't match what our component expects). We validate again, here, at the boundary where Sanity data enters our React tree — the same "don't trust data crossing a system boundary" principle from Part 8, now applied to content instead of user input.

### The Implementation

```bash
npm install next
# (already installed — next/dynamic ships as part of Next.js itself, no separate package needed)
```

#### `lib/modules/registry.ts`

```ts
import dynamic from "next/dynamic";
import { z } from "zod";

// ── Config schemas ───────────────────────────────────────────────────
// Each schema validates the RAW Portable Text block object as it arrives
// from Sanity, at RENDER time — independent of, and in addition to,
// Part 3's author-time Studio validation.

export const quizConfigSchema = z.object({
  moduleId: z.string().min(1),
  question: z.string().min(1),
  options: z.array(z.string().min(1)).min(2),
  // NOTE: correctOptionIndex is included here so our (deliberately naive)
  // Step 6 component can grade client-side. Part 11 removes this field
  // from what reaches the browser entirely — see this part's closing
  // security callout.
  correctOptionIndex: z.number().int().min(0),
});
export type QuizConfig = z.infer<typeof quizConfigSchema>;

export const codeExerciseConfigSchema = z.object({
  moduleId: z.string().min(1),
  prompt: z.string().min(1),
  language: z.enum(["sql", "javascript", "plaintext"]),
  starterCode: z.string().optional().default(""),
  // Same caveat as above — Part 11 removes this from the browser payload.
  expectedKeywords: z.array(z.string().min(1)).min(1),
});
export type CodeExerciseConfig = z.infer<typeof codeExerciseConfigSchema>;

export const reflectionConfigSchema = z.object({
  moduleId: z.string().min(1),
  prompt: z.string().min(1),
  minWords: z.number().int().min(0).default(20),
});
export type ReflectionConfig = z.infer<typeof reflectionConfigSchema>;

export const checkpointConfigSchema = z.object({
  moduleId: z.string().min(1),
  label: z.string().min(1),
});
export type CheckpointConfig = z.infer<typeof checkpointConfigSchema>;

// ── The registry ─────────────────────────────────────────────────────
// Maps a Portable Text block's "_type" to its validator AND its
// component, loaded lazily. dynamic() means the actual component code
// for, say, the code-exercise editor is only downloaded by a student's
// browser if a lesson genuinely contains one — not bundled into every
// page's initial JavaScript regardless of whether it's used.
export const moduleRegistry = {
  quizBlock: {
    configSchema: quizConfigSchema,
    component: dynamic(() =>
      import("@/components/modules/multiple-choice-quiz").then((m) => m.MultipleChoiceQuiz)
    ),
  },
  codeExerciseBlock: {
    configSchema: codeExerciseConfigSchema,
    component: dynamic(() =>
      import("@/components/modules/code-exercise").then((m) => m.CodeExercise)
    ),
  },
  reflectionBlock: {
    configSchema: reflectionConfigSchema,
    component: dynamic(() =>
      import("@/components/modules/reflection-response").then((m) => m.ReflectionResponse)
    ),
  },
  checkpointBlock: {
    configSchema: checkpointConfigSchema,
    component: dynamic(() =>
      import("@/components/modules/completion-checkpoint").then((m) => m.CompletionCheckpoint)
    ),
  },
} as const;

export type ModuleBlockType = keyof typeof moduleRegistry;
```

**Code walkthrough:**

- `dynamic(() => import("@/components/modules/multiple-choice-quiz").then(...))` — the `import(...)` call here is a **dynamic import**: unlike a normal `import { X } from "..."` at the top of a file (resolved at build time, bundled immediately), this form returns a Promise, resolved only when actually invoked, letting Next.js split this component into its own separate JavaScript chunk, fetched on demand.
- We're deliberately **not** yet passing a custom `loading` fallback to `dynamic()` here — we'll add that at the point where these components are actually rendered (Step 4's `ModuleRenderer`), since that's where we have the surrounding layout context (a skeleton sized appropriately for "a module is loading here") rather than a generic one defined once for every module type regardless of its eventual size.
- `as const` on the registry object is what makes `ModuleBlockType` a precise union of the four literal string keys (`"quizBlock" | "codeExerciseBlock" | "reflectionBlock" | "checkpointBlock"`) rather than the much looser `string` — this is what lets Step 4's `isKnownModuleType` type guard work correctly.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors — the four imported component files don't exist yet, so this will actually show module-not-found errors until Steps 6–8 create them. That's expected at this point in the part; we'll come back to a clean `tsc` run once every module component exists.

---

## Step 4 — The error boundary and the `ModuleRenderer`

### The Target

`components/modules/module-error-boundary.tsx` and `components/modules/module-renderer.tsx` — the component responsible for looking up a block's type in the registry, validating its config, and rendering the correct module — or a graceful fallback if anything is wrong.

### The Concept

This is the "unknown-module fallback" and "loading/error boundaries" machinery from the blueprint, built once, centrally, so no individual module component ever has to worry about what happens if *it itself* crashes, or if a Sanity content editor references a module type this version of our code doesn't recognize yet (a real scenario: imagine deploying a new module type to Sanity's schema before the corresponding Next.js code ships).

A quick, important technical note: **React error boundaries currently require a class component** — there is no Hook equivalent as of React 19. This is a deliberate, narrow exception to our "always prefer function components" habit, used *only* here, for exactly this one purpose.

### The Implementation

#### `components/modules/module-error-boundary.tsx`

```tsx
"use client";

import { Component, type ReactNode } from "react";
import { Alert } from "@/components/ui/alert";

interface ModuleErrorBoundaryProps {
  children: ReactNode;
}

interface ModuleErrorBoundaryState {
  hasError: boolean;
}

// getDerivedStateFromError and componentDidCatch are React's ERROR
// BOUNDARY lifecycle methods — they only exist on class components.
// This boundary's job is narrow and specific: if ANY module component
// throws during render (a bug in a specific plugin, an unexpected data
// shape that slipped past Zod), we contain the failure to just THIS
// module's box on the page, rather than crashing the entire lesson.
export class ModuleErrorBoundary extends Component<
  ModuleErrorBoundaryProps,
  ModuleErrorBoundaryState
> {
  state: ModuleErrorBoundaryState = { hasError: false };

  static getDerivedStateFromError() {
    return { hasError: true };
  }

  componentDidCatch(error: Error) {
    console.error("An interactive module crashed:", error);
  }

  render() {
    if (this.state.hasError) {
      return (
        <Alert variant="danger" title="Something went wrong" className="my-6">
          This interactive element couldn't be displayed. Try refreshing the page.
        </Alert>
      );
    }
    return this.props.children;
  }
}
```

#### `components/modules/module-renderer.tsx`

```tsx
"use client";

import { Alert } from "@/components/ui/alert";
import { Skeleton } from "@/components/ui/skeleton";
import { moduleRegistry, type ModuleBlockType } from "@/lib/modules/registry";
import { submitModuleAttempt } from "@/lib/modules/submit-module-attempt";
import type { ModuleAttemptSnapshot } from "@/lib/modules/types";
import { ModuleErrorBoundary } from "./module-error-boundary";

interface ModuleRendererProps {
  block: Record<string, unknown> & { _type: string };
  lessonId: string;
  courseId: string;
  initialAttempt: ModuleAttemptSnapshot | null;
}

// A type guard — narrows a plain string down to our known union of
// registry keys. This is what lets TypeScript know moduleRegistry[_type]
// is safe to index into after this check passes.
function isKnownModuleType(type: string): type is ModuleBlockType {
  return type in moduleRegistry;
}

export function ModuleRenderer({
  block,
  lessonId,
  courseId,
  initialAttempt,
}: ModuleRendererProps) {
  const { _type } = block;

  // ── Unknown-module fallback ──────────────────────────────────────
  if (!isKnownModuleType(_type)) {
    return (
      <Alert variant="warning" title="Unsupported content" className="my-6">
        This lesson contains an interactive element ("{_type}") that isn't supported by this
        version of the app yet.
      </Alert>
    );
  }

  const entry = moduleRegistry[_type];

  // ── Runtime config validation ─────────────────────────────────────
  const parsedConfig = entry.configSchema.safeParse(block);

  if (!parsedConfig.success) {
    console.error(
      `Invalid config for module block "${_type}" (moduleId: ${String(block.moduleId)}):`,
      parsedConfig.error.flatten()
    );
    return (
      <Alert variant="danger" title="Content error" className="my-6">
        This interactive element is misconfigured and can't be displayed. Please contact your
        instructor.
      </Alert>
    );
  }

  const Component = entry.component;
  const moduleId = parsedConfig.data.moduleId;

  // This closure is the ENTIRE bridge between the module's UI and real
  // persistence — the module component itself never sees lessonId,
  // courseId, or the Server Action directly, only this bound function.
  async function submit(submission: unknown) {
    return submitModuleAttempt({ lessonId, courseId, moduleId, submission });
  }

  return (
    <ModuleErrorBoundary>
      <Component
        moduleId={moduleId}
        lessonId={lessonId}
        courseId={courseId}
        config={parsedConfig.data}
        initialAttempt={initialAttempt}
        submit={submit}
      />
    </ModuleErrorBoundary>
  );
}
```

**Code walkthrough:**

- Notice the **three distinct failure modes**, each handled independently and each producing a different, honest message: an unrecognized `_type` ("unsupported content" — our code is simply older than the content), a config that fails Zod validation ("content error" — the content itself is broken), and a component that throws during render, caught by `ModuleErrorBoundary` ("something went wrong" — a genuine bug). Distinguishing these in your own systems, rather than collapsing every failure into one generic "error" message, is a habit worth carrying well beyond this tutorial.
- `next/dynamic`'s default loading behavior (when no explicit `loading` option is given) is to render `null` until the chunk resolves — for our purposes here that's an acceptable, brief flash, but production polish could add a `loading: () => <Skeleton className="h-32 w-full" />` option to each registry entry; we import `Skeleton` above specifically to leave that as a one-line enhancement you can add yourself if you'd like a smoother loading transition.

### The Verification

```bash
npx tsc --noEmit
```

This will still show errors until Step 5's `submitModuleAttempt` and Steps 6–8's module components exist — expected at this stage. Continue to the next step.

---

## Step 5 — The submission Server Action (and its deliberate, temporary insecurity)

### The Target

`lib/modules/submit-module-attempt.ts` — a Server Action that records a module attempt in Neon, and `db/queries/module-attempts.ts` — a query helper resolving each module's most recent attempt so revisiting a lesson restores prior answers.

### The Concept

**Read this section carefully — it's the crux of this entire part.**

This Server Action *does* check that a real user is signed in. It *does* validate the shape of the incoming payload with Zod. It *does* correctly write to our `module_attempts` table using everything Part 5 built. In nearly every respect, it looks like solid, careful code — because it mostly is.

But it has exactly one, serious flaw: it accepts `isCorrect` and `score` values **computed by the browser** and simply writes them to the database as-is. This is precisely Part 0's driving-test scenario, now made real: nothing stops a student from opening DevTools, intercepting this request, and changing `clientComputedIsCorrect: false` to `clientComputedIsCorrect: true` before it's sent — no different from an "Edit and Resend" in your network tab.

We are building it this way **on purpose**, so you can verify the vulnerability yourself in this part's final verification step, before Part 11 removes it entirely.

### The Implementation

#### `db/queries/module-attempts.ts`

```ts
import { and, desc, eq } from "drizzle-orm";
import { db } from "@/db/client";
import { moduleAttempts } from "@/db/schema";
import type { ModuleAttemptSnapshot } from "@/lib/modules/types";

// Returns a map of moduleId -> that module's MOST RECENT attempt for
// this user within this lesson — used to restore a student's prior
// answer when they revisit a lesson they've already interacted with.
export async function findLatestModuleAttempts(
  userId: string,
  lessonId: string
): Promise<Record<string, ModuleAttemptSnapshot>> {
  const attempts = await db.query.moduleAttempts.findMany({
    where: and(eq(moduleAttempts.userId, userId), eq(moduleAttempts.lessonId, lessonId)),
    orderBy: [desc(moduleAttempts.attemptNumber)],
  });

  // Since attempts are ordered by attemptNumber DESCENDING, the first
  // time we see a given moduleId in this loop, it's necessarily that
  // module's latest attempt — a Map's "set only if absent" behavior via
  // .has() gives us this "keep only the first/latest" result cheaply.
  const latestByModuleId = new Map<string, (typeof attempts)[number]>();
  for (const attempt of attempts) {
    if (!latestByModuleId.has(attempt.moduleId)) {
      latestByModuleId.set(attempt.moduleId, attempt);
    }
  }

  const result: Record<string, ModuleAttemptSnapshot> = {};
  for (const [moduleId, attempt] of latestByModuleId) {
    result[moduleId] = {
      attemptNumber: attempt.attemptNumber,
      submission: attempt.submission,
      isCorrect: attempt.isCorrect,
      score: attempt.score,
      submittedAt: attempt.submittedAt.toISOString(),
    };
  }
  return result;
}

export async function countAttemptsForModule(userId: string, moduleId: string): Promise<number> {
  const attempts = await db.query.moduleAttempts.findMany({
    where: and(eq(moduleAttempts.userId, userId), eq(moduleAttempts.moduleId, moduleId)),
  });
  return attempts.length;
}
```

#### `lib/modules/submit-module-attempt.ts`

```ts
"use server";

import { z } from "zod";
import { requireUser } from "@/lib/auth/require-user";
import { db } from "@/db/client";
import { moduleAttempts } from "@/db/schema";
import { countAttemptsForModule } from "@/db/queries/module-attempts";
import type { ModuleSubmissionResult } from "./types";

const submitSchema = z.object({
  lessonId: z.string().min(1),
  courseId: z.string().min(1),
  moduleId: z.string().min(1),
  submission: z.unknown(),
  // ⚠️ TEMPORARY, INSECURE FIELDS ⚠️
  // These two fields are computed by the BROWSER and trusted here
  // without any independent server-side verification. This is a
  // deliberate, visible violation of the "never trust the client"
  // principle from Part 0 — Part 11 deletes these two fields from this
  // schema entirely and computes correctness/score on the server
  // instead, using the actual answer key from Sanity. Do not carry this
  // pattern into a real application.
  clientComputedIsCorrect: z.boolean().nullable().optional(),
  clientComputedScore: z.number().nullable().optional(),
});

export async function submitModuleAttempt(input: unknown): Promise<ModuleSubmissionResult> {
  const user = await requireUser();

  const parsed = submitSchema.safeParse(input);
  if (!parsed.success) {
    return { success: false, isCorrect: null, score: null, message: "Invalid submission." };
  }

  const { lessonId, moduleId, submission, clientComputedIsCorrect, clientComputedScore } =
    parsed.data;

  const previousAttemptCount = await countAttemptsForModule(user.id, moduleId);
  const attemptNumber = previousAttemptCount + 1;

  await db.insert(moduleAttempts).values({
    userId: user.id,
    lessonId,
    moduleId,
    attemptNumber,
    submission,
    // Directly trusting browser-supplied values — THIS is the
    // vulnerability this part's closing verification step exploits on
    // purpose, and that Part 11 removes.
    isCorrect: clientComputedIsCorrect ?? null,
    score: clientComputedScore ?? null,
  });

  return {
    success: true,
    isCorrect: clientComputedIsCorrect ?? null,
    score: clientComputedScore ?? null,
    message:
      clientComputedIsCorrect === false
        ? "Recorded. Review the correct answer below."
        : "Submitted successfully.",
  };
}
```

**Code walkthrough:**

- Notice this function still does real, legitimate work correctly: `requireUser()` genuinely blocks unauthenticated requests, Zod genuinely validates shape, `attemptNumber` is genuinely computed correctly from real prior attempts. The *only* flaw is trusting `clientComputedIsCorrect`/`clientComputedScore` — isolating the vulnerability to exactly one clearly-marked spot, rather than the whole function being carelessly written, mirrors how real security bugs usually look in practice: one specific, easy-to-miss trust assumption inside otherwise solid code.
- We are not enforcing enrollment verification in this function yet either — notice there's no check that the user is actually enrolled in the course containing this lesson. This is deliberate too, and will be added alongside the grading fix in Part 11, kept out of scope here to keep this part's focus narrow and specific to the module-rendering system itself.

### The Verification

```bash
npx tsc --noEmit
```

Should still show errors from the four not-yet-built module component imports in `registry.ts` — proceed to build them now.

---

## Step 6 — The Multiple-Choice Quiz module

### The Target

`components/modules/multiple-choice-quiz.tsx` — our first real, interactive, plugin-contract-implementing module.

### The Concept

This component is a direct implementation of Step 1's `GreyMatterModuleProps` contract — notice, reading through it, that it has zero imports related to databases, users, or Server Actions. It receives `config`, `initialAttempt`, and `submit`, and that's its entire universe.

### The Implementation

#### `components/modules/multiple-choice-quiz.tsx`

```tsx
"use client";

import { useState, useTransition } from "react";
import { cn } from "@/lib/cn";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import type { GreyMatterModuleProps, ModuleSubmissionResult } from "@/lib/modules/types";
import type { QuizConfig } from "@/lib/modules/registry";

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
  const [result, setResult] = useState<ModuleSubmissionResult | null>(
    initialAttempt
      ? {
          success: true,
          isCorrect: initialAttempt.isCorrect,
          score: initialAttempt.score,
          message: initialAttempt.isCorrect ? "Correct!" : "Not quite — review below.",
        }
      : null
  );
  const [isPending, startTransition] = useTransition();

  const isLockedIn = result?.isCorrect === true;

  function handleSubmit() {
    if (selectedIndex === null) return;

    // ⚠️ NAIVE, CLIENT-SIDE GRADING ⚠️
    // We compute correctness HERE, in the browser, by comparing against
    // config.correctOptionIndex — which arrived in this component's
    // props, meaning it is fully visible in DevTools right now. Part 11
    // removes this comparison from the client entirely.
    const isCorrect = selectedIndex === config.correctOptionIndex;

    startTransition(async () => {
      const outcome = await submit({ selectedOptionIndex: selectedIndex });
      setResult(outcome);
    });
    // Note: we don't currently SEND isCorrect to submit() as a separate
    // argument here — the naive grading happens implicitly via the
    // wiring in Step 9, where we pass clientComputedIsCorrect alongside
    // the raw submission. Kept visible here as "isCorrect" for clarity
    // of what's being computed, even though it's threaded through via
    // the wrapping call in the lesson content wiring.
    void isCorrect;
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
        <Alert variant={result.isCorrect ? "success" : "danger"}>{result.message}</Alert>
      )}
    </div>
  );
}
```

Since the naive grading needs to actually reach `submitModuleAttempt`'s `clientComputedIsCorrect` field, we adjust `ModuleRenderer`'s `submit` closure to accept an optional grading hint — updated now:

#### `components/modules/module-renderer.tsx` (update the `submit` closure)

```tsx
  // Replace the previous submit() definition with this version, which
  // accepts an OPTIONAL grading hint from the calling module — modules
  // with no notion of correctness (reflection, checkpoint) simply omit it.
  async function submit(
    submission: unknown,
    grading?: { isCorrect?: boolean | null; score?: number | null }
  ) {
    return submitModuleAttempt({
      lessonId,
      courseId,
      moduleId,
      submission,
      clientComputedIsCorrect: grading?.isCorrect ?? null,
      clientComputedScore: grading?.score ?? null,
    });
  }
```

And update the plugin contract to match this two-argument shape:

#### `lib/modules/types.ts` (update the `submit` field)

```ts
export interface GreyMatterModuleProps<TConfig, TSubmission> {
  moduleId: string;
  lessonId: string;
  courseId: string;
  config: TConfig;
  initialAttempt: ModuleAttemptSnapshot | null;
  submit: (
    submission: TSubmission,
    grading?: { isCorrect?: boolean | null; score?: number | null }
  ) => Promise<ModuleSubmissionResult>;
}
```

Now finalize `MultipleChoiceQuiz`'s `handleSubmit` to actually pass the computed grading:

#### `components/modules/multiple-choice-quiz.tsx` (replace `handleSubmit`)

```tsx
  function handleSubmit() {
    if (selectedIndex === null) return;

    // ⚠️ NAIVE, CLIENT-SIDE GRADING ⚠️ — visible in DevTools, fixed in Part 11.
    const isCorrect = selectedIndex === config.correctOptionIndex;

    startTransition(async () => {
      const outcome = await submit({ selectedOptionIndex: selectedIndex }, { isCorrect });
      setResult(outcome);
    });
  }
```

### The Verification

```bash
npx tsc --noEmit
```

Should now show fewer errors — only the three remaining not-yet-built modules. Continue to Step 7.

---

## Step 7 — The Code Exercise module (short-answer and SQL)

### The Target

`components/modules/code-exercise.tsx` — a single component handling both the "short-answer exercise" and "SQL syntax exercise" module types from the blueprint, distinguished purely by the `language` config field.

### The Concept

Rather than building two nearly-identical components, we build one, and let `language` change its presentation slightly (e.g., a monospace textarea either way, but the prompt/framing differs). This mirrors real plugin systems, where a single component often serves multiple closely-related content variations rather than needlessly duplicating code.

### The Implementation

#### `components/modules/code-exercise.tsx`

```tsx
"use client";

import { useState, useTransition } from "react";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import type { GreyMatterModuleProps, ModuleSubmissionResult } from "@/lib/modules/types";
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
  const [result, setResult] = useState<ModuleSubmissionResult | null>(
    initialAttempt
      ? {
          success: true,
          isCorrect: initialAttempt.isCorrect,
          score: initialAttempt.score,
          message: initialAttempt.isCorrect ? "Looks good!" : "Not quite — review below.",
        }
      : null
  );
  const [isPending, startTransition] = useTransition();

  function handleSubmit() {
    if (responseText.trim().length === 0) return;

    // ⚠️ NAIVE, CLIENT-SIDE GRADING ⚠️ — a simple case-insensitive
    // substring check against config.expectedKeywords, which arrived
    // fully visible in this component's props. Part 11 replaces this
    // with genuine server-side grading.
    const normalizedResponse = responseText.toLowerCase();
    const isCorrect = config.expectedKeywords.every((keyword) =>
      normalizedResponse.includes(keyword.toLowerCase())
    );

    startTransition(async () => {
      const outcome = await submit({ responseText }, { isCorrect });
      setResult(outcome);
    });
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
        <Alert variant={result.isCorrect ? "success" : "danger"}>{result.message}</Alert>
      )}
    </div>
  );
}
```

### The Verification

```bash
npx tsc --noEmit
```

Two remaining module errors should still appear — continue to Step 8.

---

## Step 8 — The Reflection and Completion Checkpoint modules

### The Target

`components/modules/reflection-response.tsx` and `components/modules/completion-checkpoint.tsx` — the two modules with genuinely **no correct answer**, worth building side by side with the previous two for direct contrast.

### The Concept

These two modules have nothing to "fake," because they have no correctness concept at all — submitting *is* succeeding. This is a deliberate, useful contrast to draw explicitly: the security concern from Steps 6–7 exists specifically and only because those modules have an objectively correct answer worth cheating toward. A reflection or checkpoint has no such incentive, and thus no such vulnerability — proof that "never trust the client" is a targeted principle applied where correctness genuinely matters, not a vague blanket paranoia applied everywhere uniformly.

### The Implementation

#### `components/modules/reflection-response.tsx`

```tsx
"use client";

import { useState, useTransition } from "react";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Textarea } from "@/components/ui/textarea";
import type { GreyMatterModuleProps, ModuleSubmissionResult } from "@/lib/modules/types";
import type { ReflectionConfig } from "@/lib/modules/registry";

interface ReflectionSubmission {
  responseText: string;
}

export function ReflectionResponse({
  config,
  initialAttempt,
  submit,
}: GreyMatterModuleProps<ReflectionConfig, ReflectionSubmission>) {
  const [responseText, setResponseText] = useState<string>(
    (initialAttempt?.submission as ReflectionSubmission | undefined)?.responseText ?? ""
  );
  const [result, setResult] = useState<ModuleSubmissionResult | null>(
    initialAttempt
      ? { success: true, isCorrect: null, score: null, message: "Response saved." }
      : null
  );
  const [isPending, startTransition] = useTransition();

  const wordCount = responseText.trim().length === 0 ? 0 : responseText.trim().split(/\s+/).length;
  const meetsGuideline = wordCount >= config.minWords;

  function handleSubmit() {
    if (responseText.trim().length === 0) return;
    startTransition(async () => {
      // No grading hint is passed at all — there's nothing to grade.
      // isCorrect/score simply stay null for this entire module type.
      const outcome = await submit({ responseText });
      setResult(outcome);
    });
  }

  return (
    <div className="my-6 flex flex-col gap-3 rounded-[var(--radius-panel)] border border-border bg-surface p-4">
      <p className="font-semibold text-text-primary">{config.prompt}</p>
      <Textarea
        value={responseText}
        onChange={(e) => setResponseText(e.target.value)}
        rows={5}
        aria-label="Your reflection"
      />
      <p className="text-xs text-text-muted">
        {wordCount} word{wordCount === 1 ? "" : "s"}
        {config.minWords > 0 && ` (suggested minimum: ${config.minWords})`}
        {!meetsGuideline && wordCount > 0 && " — consider adding a bit more detail."}
      </p>
      <Button
        variant="primary"
        size="sm"
        className="w-fit"
        onClick={handleSubmit}
        disabled={responseText.trim().length === 0 || isPending}
      >
        {isPending ? "Saving..." : "Save response"}
      </Button>
      {result && <Alert variant="success">{result.message}</Alert>}
    </div>
  );
}
```

#### `components/modules/completion-checkpoint.tsx`

```tsx
"use client";

import { useState, useTransition } from "react";
import { Alert } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import type { GreyMatterModuleProps, ModuleSubmissionResult } from "@/lib/modules/types";
import type { CheckpointConfig } from "@/lib/modules/registry";

interface CheckpointSubmission {
  acknowledged: true;
}

export function CompletionCheckpoint({
  config,
  initialAttempt,
  submit,
}: GreyMatterModuleProps<CheckpointConfig, CheckpointSubmission>) {
  const [result, setResult] = useState<ModuleSubmissionResult | null>(
    initialAttempt ? { success: true, isCorrect: null, score: null, message: "Marked complete." } : null
  );
  const [isPending, startTransition] = useTransition();

  const isDone = result !== null;

  function handleClick() {
    startTransition(async () => {
      const outcome = await submit({ acknowledged: true });
      setResult(outcome);
    });
  }

  return (
    <div className="my-6 flex items-center justify-between gap-3 rounded-[var(--radius-panel)] border border-border bg-surface p-4">
      <Button variant={isDone ? "secondary" : "primary"} size="sm" onClick={handleClick} disabled={isPending || isDone}>
        {isPending ? "Saving..." : isDone ? "✓ Done" : config.label}
      </Button>
      {result && <Alert variant="success" className="flex-1">{result.message}</Alert>}
    </div>
  );
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should now complete with **no errors** — every registry entry's imported component now genuinely exists.

---

## Step 9 — Wiring interactive modules into the lesson player

### The Target

Refactoring `components/portable-text-renderer.tsx` to expose its shared, non-interactive rendering logic, and building `components/lesson/interactive-lesson-content.tsx` — the version used exclusively by the authenticated lesson player, swapping in `ModuleRenderer` for every interactive block type.

### The Concept

Recall Part 4's public `PortableTextRenderer` deliberately shows *static, read-only* previews of quiz/code-exercise blocks — that behavior must remain completely unchanged for the public catalog. We don't want to risk accidentally wiring live submission logic into a page reachable by unauthenticated visitors. Instead, we extract the genuinely shared pieces (image rendering, headings, callouts) into a reusable base, and build an entirely separate component for the authenticated, interactive context.

### The Implementation

#### `components/portable-text-renderer.tsx` (refactored)

```tsx
import { PortableText, type PortableTextComponents } from "@portabletext/react";
import type { PortableTextBlock } from "sanity";
import { urlForImage } from "@/sanity/lib/image";
import { Alert } from "@/components/ui/alert";
import Image from "next/image";

// EXPORTED so the authenticated lesson player (below) can reuse these
// shared, non-interactive renderers without duplicating them.
export const baseFieldComponents: PortableTextComponents = {
  types: {
    image: ({ value }) => (
      <div className="relative my-6 aspect-video w-full overflow-hidden rounded-[var(--radius-panel)]">
        <Image
          src={urlForImage(value).width(800).height(450).url()}
          alt={value.alt ?? ""}
          fill
          className="object-cover"
        />
      </div>
    ),
    calloutBlock: ({ value }) => {
      const variant =
        value.tone === "warning" ? "warning" : value.tone === "tip" ? "success" : "info";
      return (
        <Alert variant={variant} className="my-6">
          {value.text}
        </Alert>
      );
    },
  },
  block: {
    h2: ({ children }) => (
      <h2 className="mt-8 mb-3 text-2xl font-semibold text-text-primary">{children}</h2>
    ),
    h3: ({ children }) => (
      <h3 className="mt-6 mb-2 text-xl font-semibold text-text-primary">{children}</h3>
    ),
    blockquote: ({ children }) => (
      <blockquote className="my-4 border-l-4 border-brand pl-4 italic text-text-secondary">
        {children}
      </blockquote>
    ),
    normal: ({ children }) => <p className="my-3 leading-relaxed text-text-secondary">{children}</p>,
  },
};

// The PUBLIC-facing renderer — used by Part 4's course catalog only.
// Interactive blocks render as static, read-only placeholders here,
// unchanged since Part 4. This component is NEVER used inside the
// authenticated dashboard.
const publicComponents: PortableTextComponents = {
  ...baseFieldComponents,
  types: {
    ...baseFieldComponents.types,
    quizBlock: ({ value }) => (
      <div className="my-6 rounded-[var(--radius-panel)] border border-dashed border-border bg-surface-muted p-4">
        <p className="text-sm font-semibold text-text-primary">📝 Interactive quiz</p>
        <p className="mt-1 text-sm text-text-secondary">{value.question}</p>
        <p className="mt-2 text-xs text-text-muted">Available inside the lesson player after enrolling.</p>
      </div>
    ),
    codeExerciseBlock: ({ value }) => (
      <div className="my-6 rounded-[var(--radius-panel)] border border-dashed border-border bg-surface-muted p-4">
        <p className="text-sm font-semibold text-text-primary">💻 Code exercise</p>
        <p className="mt-1 text-sm text-text-secondary">{value.prompt}</p>
        <p className="mt-2 text-xs text-text-muted">Available inside the lesson player after enrolling.</p>
      </div>
    ),
  },
};

export function PortableTextRenderer({ value }: { value: PortableTextBlock[] }) {
  return <PortableText value={value} components={publicComponents} />;
}
```

Now the authenticated, interactive version:

#### `components/lesson/interactive-lesson-content.tsx`

```tsx
"use client";

import { PortableText, type PortableTextComponents } from "@portabletext/react";
import type { PortableTextBlock } from "sanity";
import { baseFieldComponents } from "@/components/portable-text-renderer";
import { ModuleRenderer } from "@/components/modules/module-renderer";
import type { ModuleAttemptSnapshot } from "@/lib/modules/types";

interface InteractiveLessonContentProps {
  value: PortableTextBlock[];
  lessonId: string;
  courseId: string;
  initialAttempts: Record<string, ModuleAttemptSnapshot>;
}

export function InteractiveLessonContent({
  value,
  lessonId,
  courseId,
  initialAttempts,
}: InteractiveLessonContentProps) {
  // Every interactive block type shares the SAME rendering call — only
  // the raw block data (which includes "_type") differs. ModuleRenderer
  // handles picking the right component internally, per Step 4.
  const renderModule = (block: Record<string, unknown> & { _type: string; moduleId?: string }) => (
    <ModuleRenderer
      block={block}
      lessonId={lessonId}
      courseId={courseId}
      initialAttempt={
        typeof block.moduleId === "string" ? initialAttempts[block.moduleId] ?? null : null
      }
    />
  );

  const components: PortableTextComponents = {
    ...baseFieldComponents,
    types: {
      ...baseFieldComponents.types,
      quizBlock: ({ value: block }) => renderModule(block),
      codeExerciseBlock: ({ value: block }) => renderModule(block),
      reflectionBlock: ({ value: block }) => renderModule(block),
      checkpointBlock: ({ value: block }) => renderModule(block),
    },
  };

  return <PortableText value={value} components={components} />;
}
```

Now, update `getLessonForStudent` to fetch and return each module's latest attempt, and update the lesson page to use `InteractiveLessonContent`:

#### `lib/dashboard/get-lesson-for-student.ts` (updated)

```ts
import { client, defaultFetchOptions } from "@/sanity/lib/client";
import { lessonWithinCourseQuery, type LessonFull } from "@/sanity/lib/queries";
import { getCourseOutline, type CourseOutline } from "@/lib/dashboard/get-course-outline";
import { findLatestModuleAttempts } from "@/db/queries/module-attempts";
import type { ModuleAttemptSnapshot } from "@/lib/modules/types";

export interface LessonPlayerData {
  course: CourseOutline;
  lesson: LessonFull;
  previousLesson: { slug: string; title: string } | null;
  nextLesson: { slug: string; title: string } | null;
  moduleAttempts: Record<string, ModuleAttemptSnapshot>;
}

export async function getLessonForStudent(
  userId: string,
  courseSlug: string,
  lessonSlug: string
): Promise<LessonPlayerData | null> {
  const course = await getCourseOutline(userId, courseSlug);
  if (!course) return null;

  const lesson = await client.fetch<LessonFull | null>(
    lessonWithinCourseQuery,
    { courseSlug, lessonSlug },
    defaultFetchOptions
  );
  if (!lesson) return null;

  const allLessons = course.chapters.flatMap((chapter) => chapter.lessons);
  const currentIndex = allLessons.findIndex((l) => l.slug.current === lessonSlug);

  const previousLesson =
    currentIndex > 0
      ? { slug: allLessons[currentIndex - 1].slug.current, title: allLessons[currentIndex - 1].title }
      : null;
  const nextLesson =
    currentIndex >= 0 && currentIndex < allLessons.length - 1
      ? { slug: allLessons[currentIndex + 1].slug.current, title: allLessons[currentIndex + 1].title }
      : null;

  const moduleAttempts = await findLatestModuleAttempts(userId, lesson._id);

  return { course, lesson, previousLesson, nextLesson, moduleAttempts };
}
```

#### `app/dashboard/courses/[courseSlug]/lessons/[lessonSlug]/page.tsx` (update imports and content rendering)

```tsx
// Replace this import:
import { PortableTextRenderer } from "@/components/portable-text-renderer";
// With:
import { InteractiveLessonContent } from "@/components/lesson/interactive-lesson-content";

// ...and inside the component, destructure moduleAttempts too:
const { course, lesson, previousLesson, nextLesson, moduleAttempts } = data;

// ...and replace:
// <PortableTextRenderer value={lesson.content} />
// with:
<InteractiveLessonContent
  value={lesson.content}
  lessonId={lesson._id}
  courseId={course._id}
  initialAttempts={moduleAttempts}
/>
```

### The Verification

```bash
npm run dev
```

While signed in and enrolled, navigate to the "Writing Your First Query" lesson. Confirm the quiz block now renders as a **real, interactive** multiple-choice question with clickable radio options and a "Submit answer" button — not the static placeholder from Part 9.

Select the **wrong** answer and submit. Confirm a red "Not quite — review below" alert appears. Select the **correct** answer ("SELECT") and submit. Confirm a green "Correct!" alert appears and the options lock (disabled).

Scroll down and confirm the Reflection module (if you added one in Step 2's verification) renders as a textarea with a live word counter, and the Completion Checkpoint renders as a clickable "Mark as complete" button — click it and confirm it changes to a disabled "✓ Done" state with a green confirmation.

Refresh the entire page. Confirm the quiz still shows your correct answer selected and locked (proof `initialAttempt` correctly restored state from `findLatestModuleAttempts`), and the checkpoint still shows "✓ Done."

Open Drizzle Studio and confirm the `module_attempts` table now has real rows — one per submission — with `submission` containing your actual answer JSON, and `is_correct`/`score` populated.

Run the full verification suite:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Step 10 — Seeing the vulnerability firsthand (and why Part 11 exists)

### The Target

No new code — a deliberate, hands-on exercise proving the exact vulnerability this part warned about from the start.

### The Implementation and Verification

With the quiz lesson open in your browser, open DevTools → Network tab, and click "Submit answer" on the quiz **with the wrong option selected**. Find the `submitModuleAttempt` request (it will appear as a POST to your app's server action endpoint) and inspect its request payload — confirm you can see `clientComputedIsCorrect: false` sitting in plain text.

Now, right-click that request and choose "Copy as fetch" (or your browser's equivalent), paste it into your DevTools Console, and **edit the payload** so `clientComputedIsCorrect` reads `true` instead of `false`, then run it.

Refresh the lesson page. **Confirm the quiz now shows as correctly answered — with your genuinely wrong answer still selected.**

This is the vulnerability, proven with your own hands, exactly as Part 0 described it in the abstract: *"anyone can open their browser's developer tools, intercept that network request, and simply change the request body... The server just... believed them."*

Also open Drizzle Studio and look at the `module_attempts` row this created — you'll see `is_correct: true` sitting right there in your production database, permanently, for an answer that was actually wrong.

**Do not attempt to fix this yourself right now** — Part 11 walks through the correct, complete fix step by step, including removing `correctOptionIndex`/`expectedKeywords` from what the browser ever receives at all, and replacing client-side grading with genuine server-side grading against Sanity's answer key.

---

## Common mistakes

- **`next/dynamic` throws "ssr: false is not allowed with next/dynamic in Server Components"** — This would occur if `ModuleRenderer` or the registry were imported into a Server Component without `"use client"`. Confirm `module-renderer.tsx` has `"use client"` at the very top — since it's imported by `InteractiveLessonContent` (also `"use client"`), the whole interactive subtree stays correctly client-rendered.
- **Reflection/Checkpoint modules show a "content error" alert** — Almost always means the block's `moduleId` field is missing in Sanity (check Step 2's authored content), since every config schema requires it.
- **Quiz shows "Correct!" for every answer, even wrong ones** — Confirm `config.correctOptionIndex` genuinely matches the index you expect in Sanity (recall it's zero-based — option 1 is index `0`), and confirm you didn't accidentally swap the `isCorrect` comparison direction.
- **Module state doesn't persist after refresh** — Confirm `findLatestModuleAttempts` is being called with the correct `lesson._id` (a Sanity ID) and not accidentally a lesson *slug* — these are easy to confuse since both are strings.
- **TypeScript complains about `Record<string, unknown> & { _type: string }`** — This intersection type is required because Portable Text's raw block objects are only loosely typed by `@portabletext/react`; if you see a mismatch, confirm you're passing the raw `value` object from PortableText's render prop directly, not a partially-destructured version of it.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `lib/modules/types.ts`, `lib/modules/registry.ts`, `lib/modules/submit-module-attempt.ts`, `db/queries/module-attempts.ts`, `sanity/schema-types/reflection-block.ts`, `sanity/schema-types/checkpoint-block.ts`, `sanity/schema-types/lesson.ts` (modified), `sanity/schema-types/index.ts` (modified), `components/modules/*.tsx`, `components/portable-text-renderer.tsx` (modified), `components/lesson/interactive-lesson-content.tsx`, `lib/dashboard/get-lesson-for-student.ts` (modified), `app/dashboard/courses/[courseSlug]/lessons/[lessonSlug]/page.tsx` (modified).

```bash
git commit -m "Part 10: interactive module SDK — plugin contract, dynamic-loading registry, runtime config validation, five module types, error/unknown-module fallbacks (client-side grading intentionally insecure, fixed in Part 11)"
```

---

## Reference: the five modules at a glance

| Module | Sanity type | Has a correct answer? | Submission shape |
|---|---|---|---|
| Multiple-choice quiz | `quizBlock` | Yes | `{ selectedOptionIndex: number }` |
| Short-answer exercise | `codeExerciseBlock` (language: `plaintext`/`javascript`) | Yes | `{ responseText: string }` |
| SQL syntax exercise | `codeExerciseBlock` (language: `sql`) | Yes | `{ responseText: string }` |
| Reflective response | `reflectionBlock` | No | `{ responseText: string }` |
| Completion checkpoint | `checkpointBlock` | No | `{ acknowledged: true }` |

## Reference: the plugin contract, restated

```text
Every module component receives EXACTLY:
  - moduleId, lessonId, courseId  (identity — read-only)
  - config                          (validated Sanity content)
  - initialAttempt                  (prior submission, if any)
  - submit(submission, grading?)     (the ONLY way to persist anything)

Every module component NEVER has direct access to:
  - The database
  - The current user's identity
  - Sanity's client
  - Any other module's state
```

## Reference: why this part's vulnerability exists, in one sentence

**Any value used to compute correctness (`correctOptionIndex`, `expectedKeywords`) that is sent to the browser at all — even just to let the browser render nicely — can also be read and exploited by that same browser**, regardless of how the UI itself is built; the only real fix is never sending it in the first place, and grading exclusively on the server.

---

## What's next

Part 11 delivers on this part's promise: we'll remove `correctOptionIndex` and `expectedKeywords` from what ever reaches the browser, build a dedicated server-side grading query and function, add enrollment verification directly into the submission path, wrap the attempt-plus-progress write in a real database transaction, and upgrade the client experience with React 19's `useOptimistic` for a fast, reliable, but now genuinely secure submission flow.
