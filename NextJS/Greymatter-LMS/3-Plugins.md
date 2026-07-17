### Prerequisite: add `score` and `moduleState` to the `Progress` model

Part 3's completion contract needs two fields that were never actually added to Part 1's `Progress` model. Add them now in `prisma/schema.prisma`:

```prisma
model Progress {
  id          String    @id @default(cuid())
  userId      String
  lessonId    String
  courseId    String
  completed   Boolean   @default(false)
  completedAt DateTime?
  score       Int?
  moduleState Json?

  user        User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, lessonId])
  @@index([userId, courseId])
}
```

```bash
npx prisma migrate dev --name add_progress_score_state
```

With that in place, here's Part 3.

---

# Part 3: The React-Only Plugin Registry & Component Contract

Picking up exactly where Part 2 left off: you have authenticated dashboard routes and a sidebar rendering real course/chapter/lesson navigation from Sanity's CDN. Now we tackle the feature that makes Greymatter more than a glorified PDF viewer — **interactive lesson modules**, like a live SQL sandbox embedded directly inside a lesson's content.

## 3.0 Why We Need a "Plugin Registry" At All

**The Concept:** Recall from Part 1 (as patched above) that a `Progress` record in our Neon database stores a `moduleState` field, and a nullable `score` field, both written together whenever a student completes something inside a lesson. That's the entire reason this Part exists: Greymatter needs a way for arbitrary, developer-built interactive widgets (a SQL sandbox today, maybe a code grader or quiz tomorrow) to plug into a lesson, run their own logic, and hand back a result shaped exactly like what the `Progress` model expects.

Think of it like a universal remote control: the remote (Sanity content) doesn't know how to build a TV, a sound system, or a streaming box — it just sends a code ("this block is type X"), and the actual appliance (a React component) that responds to that code lives entirely on your side, wired in ahead of time. This decoupling means a course author can write "insert a SQL Sandbox here" inside Sanity Studio without ever touching React code, while developers can add brand-new interactive widget types without ever touching Sanity's schema definitions again.

---

## Step 1: Finalize the `customModule` Schema Field in Sanity

**The Target:** Extend the `lesson` schema — the actual one created in Part 1 at `sanity/schemaTypes/lesson.ts` — so its existing Portable Text field accepts a `customModule` block type alongside regular text.

**The Concept:** A `customModule` block is a special kind of Portable Text entry — Portable Text being Sanity's structured, JSON-based rich text format (instead of plain HTML strings). Every "normal" paragraph, heading, or list becomes a `block` type, but we're now teaching Sanity a second type of block: `customModule`, which just carries two harmless-looking fields — a `moduleType` string (like `"sql-sandbox"`) and a `configPayload` JSON string. Sanity has *no idea* what a SQL sandbox is; it just stores those two strings faithfully, the same way a postal service delivers a sealed envelope without reading its contents.

This amends the existing `body` field from Part 1 (rather than introducing a duplicate schema file at a different path) — Part 1's `body` was already a Portable Text array of `block` entries; we're just adding a second entry type to that same `of` array.

**The Implementation:**

#### `sanity/schemaTypes/lesson.ts` 

```ts
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
                  // Sanity has no idea what "valid" means for a sandbox config —
                  // the only thing we can verify at the content layer is that
                  // the string itself is parsable JSON. Business logic validation
                  // (e.g. "does this sandbox need a starterQuery field?") is the
                  // plugin component's responsibility on the Next.js side, not Sanity's.
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

Nothing else in `sanity/schemaTypes/index.ts` needs to change — `lesson` is already exported and registered from Part 1, so this amendment is picked up automatically the next time Studio reloads.

**The Verification:**

1. Restart your local Sanity Studio (embedded from Part 1, at `/studio`):

```bash
npm run dev
```

2. Open `http://localhost:3000/studio`, navigate to an existing `lesson` document (or create a new one), and open the **Body** field's block editor.
3. Click the "+" insert menu inside the Portable Text editor — you should now see **"Custom Interactivity Module"** listed as an insertable block type alongside the standard text formatting options.
4. Insert one, and fill in:
   - `moduleType`: `sql-sandbox`
   - `configPayload`: `{"starterQuery": "SELECT * FROM students;"}`
5. Try breaking validation on purpose — type `{invalid json` into `configPayload` and confirm Sanity shows the red validation error "Must be a valid, parsable JSON string" and blocks publishing until it's fixed.
6. Fix the JSON and click **Publish**.
7. Confirm your existing `order` and `videoUrl` fields are still present and unaffected — this amendment should have only *added* a block type, not disturbed any other field.

This confirms Sanity can now store a "sealed envelope" describing a plugin without knowing anything about React — exactly the decoupling described in Step 0.

Commit this checkpoint:

```bash
git add sanity/schemaTypes/lesson.ts
git commit -m "feat: extend lesson body schema with customModule block type"
```

---

## Step 2: Define the `@greymatter/plugin-sdk` TypeScript Contract

**The Target:** A shared TypeScript module defining the **exact props shape** every plugin component must accept — the "contract" all interactive modules agree to honor.

**The Concept:** Imagine hiring electricians to install appliances in a building you're designing. You don't need to know *how* a dishwasher or a washing machine works internally — you just need every appliance manufacturer to agree on one thing: they'll all plug into a standard-shaped wall socket. The `plugin-sdk` is that standard socket shape. Every plugin — whether it's a SQL sandbox today or a code-execution grader next year — must accept the same three props: the module's parsed config, a way to report completion, and the lesson/course identifiers needed to know *which* progress record it's reporting against.

This contract's `onComplete` callback exists specifically to produce data matching the fields written together in the progress transaction pattern that Part 4 will build — `completed`, `score`, and `moduleState` are all set at once, in the same `upsert` call, whenever a student finishes something. With the prerequisite patch applied above, this now matches the real `Progress` model exactly:

```typescript
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
    courseId,
    completed: true,
    completedAt: new Date(),
    score,
    moduleState: moduleState || {},
  }
});
```

Notice `score` and `moduleState` are the two pieces of dynamic data in that call — everything else (`userId`, `lessonId`, `courseId`, `completed`, `completedAt`) is derived automatically by the server, not supplied by the plugin. This is exactly why our plugin contract's `onComplete` signature only needs to accept `score` and `moduleState`, nothing more.

**The Implementation:**

Since we're keeping this a single Next.js project rather than a true separate npm package (simpler for a tutorial, still fully functional), we'll place the SDK as an internal shared module under `lib/`.

#### `lib/plugin-sdk/types.ts`

```typescript
/**
 * @greymatter/plugin-sdk — Component Contract
 *
 * Every interactive lesson plugin (SQL Sandbox, Code Grader, Quiz, etc.)
 * must be a React Client Component whose props satisfy this interface.
 * This is the "standard wall socket" every plugin agrees to plug into.
 */
export interface GreymatterPluginProps<TConfig = Record<string, unknown>> {
  /**
   * The parsed JSON object from the lesson's `configPayload` field in Sanity.
   * Generic so individual plugins can narrow this to their own config shape
   * (e.g. SqlSandboxConfig) without weakening the base contract.
   */
  config: TConfig;

  /**
   * Identifiers needed so the plugin knows WHICH lesson/course
   * it's reporting progress against when calling onComplete.
   */
  context: {
    courseId: string;
    lessonId: string;
  };

  /**
   * Called by the plugin itself once the student has satisfied
   * whatever "completion" means for that specific plugin type
   * (e.g. running a correct SQL query, passing a quiz threshold).
   *
   * These two fields map directly onto the `score` and `moduleState`
   * arguments passed into the Prisma progress.upsert() call that
   * Part 4 will build.
   */
  onComplete: (result: { score?: number; moduleState?: Record<string, unknown> }) => void;
}

/**
 * The shape of a raw customModule block as it arrives from Sanity's
 * Portable Text array — before we've parsed configPayload into an object.
 */
export interface RawCustomModuleBlock {
  _type: "customModule";
  _key: string;
  moduleType: string;
  configPayload?: string;
}
```

**Why generics here?** The `<TConfig = Record<string, unknown>>` syntax means "this interface works with any config shape, defaulting to a generic object if the caller doesn't specify one." This lets the SQL Sandbox plugin later write `GreymatterPluginProps<SqlSandboxConfig>` to get full autocomplete and type-checking on its specific config fields, while the registry code that doesn't know the specific plugin type yet can still safely handle the generic version.

**The Verification:** This step is a type-only file — there's no UI to click yet. Confirm it's syntactically valid by running the TypeScript compiler in check-only mode:

```bash
npx tsc --noEmit
```

You should see no errors related to `lib/plugin-sdk/types.ts`. If you get an error like "Cannot find module," confirm the file was saved at exactly `lib/plugin-sdk/types.ts` relative to your project root.

Commit:

```bash
git add lib/plugin-sdk/types.ts
git commit -m "feat: define GreymatterPluginProps contract for plugin-sdk"
```

---

## Step 3: Build the Dynamic Client-Side Component Registry

**The Target:** A `ModuleRegistry` object mapping string keys (like `"sql-sandbox"`) to lazily-loaded React components using `next/dynamic`.

**The Concept:** Normally, if you `import` ten different plugin components at the top of a file, JavaScript bundles *all ten* into the page's initial download — even if a given lesson only uses one of them. That's wasteful, like shipping every tool in a hardware store to a customer who only bought a hammer. `next/dynamic` solves this with **code splitting**: it defers loading a component's code until the exact moment it's actually needed on screen, and only downloads that one component's bundle — not the other nine. The registry is simply a lookup table connecting Sanity's plain `moduleType` string (e.g., `"sql-sandbox"`) to the correct lazy-loaded component.

**The Implementation:**

#### `lib/plugin-sdk/registry.tsx`

```tsx
import dynamic from "next/dynamic";
import type { ComponentType } from "react";
import type { GreymatterPluginProps } from "./types";

// Loading fallback shown while a plugin's JS chunk is being fetched over the network.
function ModuleLoadingSkeleton() {
  return (
    <div className="animate-pulse rounded-lg border border-brand-100 bg-white p-6">
      <div className="h-4 w-1/3 rounded bg-brand-100" />
      <div className="mt-3 h-24 w-full rounded bg-brand-50" />
    </div>
  );
}

/**
 * The ModuleRegistry maps a Sanity-authored `moduleType` string to the
 * actual React component implementing that interactive experience.
 *
 * Each entry is wrapped in next/dynamic so its code is only downloaded
 * by the browser when a lesson containing THAT specific module type
 * is actually rendered — never bundled into every page by default. This
 * is the literal implementation of the "Dynamic Component Resolution (RSC)"
 * step in the request lifecycle, which maps a Sanity customModule.moduleType
 * string to an imported Client chunk via React.lazy.
 */
export const ModuleRegistry: Record<
  string,
  ComponentType<GreymatterPluginProps<any>>
> = {
  "sql-sandbox": dynamic(
    () => import("@/components/plugins/sql-sandbox").then((mod) => mod.SqlSandbox),
    {
      loading: () => <ModuleLoadingSkeleton />,
      ssr: false, // Browser-only interactivity (typing/running a query); skip server rendering.
    }
  ),
};

/**
 * Safe lookup helper — returns null instead of throwing if a course author
 * typos a moduleType or references a plugin that hasn't been built yet,
 * so one bad lesson block can never crash an entire page render.
 */
export function resolveModule(moduleType: string) {
  return ModuleRegistry[moduleType] ?? null;
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

You'll see an error at this point: `Cannot find module '@/components/plugins/sql-sandbox'` — that's expected. It confirms the registry file itself is syntactically valid; the only failure is the import target we haven't built yet, which we fix right now in Step 4.

Commit:

```bash
git add lib/plugin-sdk/registry.tsx
git commit -m "feat: build dynamic ModuleRegistry using next/dynamic"
```

---

## Step 4: Build the "SQL Sandbox" Sample Plugin

**The Target:** A working, self-contained React Client Component implementing a simplified SQL sandbox — a text area where a student types a query, and a mock evaluator checks it against an expected answer, calling `onComplete` when correct.

**The Concept:** This plugin is the first real "appliance" plugged into the "wall socket" contract from Step 2. It doesn't need a real database behind it — that would be its own project — so we simulate evaluation with simple string comparison. What matters architecturally is that this component honors the `GreymatterPluginProps` contract exactly: it receives `config` and `context` as props, and decides *when* to call `onComplete`. A plugin only ever reports a `score` and structured `moduleState` upward — it never writes to the database itself, which is exactly what the now-correctly-shaped `Progress` model (patched at the top of this Part) expects to receive later in Part 4.

**The Implementation:**

#### `components/plugins/sql-sandbox/types.ts`

```typescript
export interface SqlSandboxConfig {
  /** The query pre-filled into the editor when the student first opens it. */
  starterQuery?: string;
  /** The exact query string (whitespace/case-insensitive) considered "correct". */
  expectedQuery: string;
  /** Friendly instructions shown above the editor. */
  prompt: string;
}
```

#### `components/plugins/sql-sandbox/index.tsx`

```tsx
"use client";

import { useState } from "react";
import type { GreymatterPluginProps } from "@/lib/plugin-sdk/types";
import type { SqlSandboxConfig } from "./types";

type SandboxStatus = "idle" | "correct" | "incorrect";

/**
 * A simplified SQL sandbox plugin. Honors the GreymatterPluginProps<SqlSandboxConfig>
 * contract — this is the "appliance" plugged into the registry's "wall socket".
 */
export function SqlSandbox({
  config,
  context,
  onComplete,
}: GreymatterPluginProps<SqlSandboxConfig>) {
  const [query, setQuery] = useState(config.starterQuery ?? "");
  const [status, setStatus] = useState<SandboxStatus>("idle");
  const [isSubmitting, setIsSubmitting] = useState(false);

  function normalize(sql: string) {
    // Loose comparison: ignore casing and collapse extra whitespace,
    // so "select * from students;" matches "SELECT * FROM students;"
    return sql.trim().toLowerCase().replace(/\s+/g, " ");
  }

  async function handleRun() {
    setIsSubmitting(true);
    const isCorrect = normalize(query) === normalize(config.expectedQuery);
    setStatus(isCorrect ? "correct" : "incorrect");

    if (isCorrect) {
      // The plugin never writes to the database itself — it only reports
      // a score and a moduleState snapshot upward, matching the score/moduleState
      // fields on the Progress model.
      onComplete({
        score: 100,
        moduleState: {
          submittedQuery: query,
          lessonId: context.lessonId,
        },
      });
    }
    setIsSubmitting(false);
  }

  return (
    <div className="rounded-lg border border-brand-100 bg-white p-6">
      <p className="mb-3 text-sm font-medium text-brand-900">{config.prompt}</p>
      <textarea
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        rows={4}
        spellCheck={false}
        className="w-full rounded-md border border-brand-100 bg-brand-50 p-3 font-mono text-sm text-brand-900 focus:outline-none focus:ring-2 focus:ring-brand-500"
        placeholder="SELECT * FROM ..."
      />
      <div className="mt-3 flex items-center gap-3">
        <button
          onClick={handleRun}
          disabled={isSubmitting || status === "correct"}
          className="rounded-md bg-brand-900 px-4 py-2 text-sm font-medium text-white disabled:opacity-50"
        >
          {status === "correct" ? "Completed ✓" : "Run Query"}
        </button>
        {status === "correct" && (
          <span className="text-sm font-medium text-success-500">
            Correct! Progress saved.
          </span>
        )}
        {status === "incorrect" && (
          <span className="text-sm font-medium text-red-500">
            Not quite — check your syntax and try again.
          </span>
        )}
      </div>
    </div>
  );
}
```

**The Verification:**

```bash
npx tsc --noEmit
```

The earlier "Cannot find module" error should now be gone. To visually confirm it renders, temporarily drop it onto the dashboard home page:

#### `app/dashboard/page.tsx` (temporary test edit)

```tsx
import { currentUser } from "@clerk/nextjs/server";
import { SqlSandbox } from "@/components/plugins/sql-sandbox";

export default async function DashboardHomePage() {
  const user = await currentUser();

  return (
    <div>
      <h1 className="text-2xl font-bold text-brand-900">
        Welcome back{user?.firstName ? `, ${user.firstName}` : ""} 👋
      </h1>

      {/* Temporary manual test render — remove after confirming it works */}
      <div className="mt-6 max-w-xl">
        <SqlSandbox
          config={{
            prompt: "Write a query that selects everything from the students table.",
            starterQuery: "",
            expectedQuery: "SELECT * FROM students;",
          }}
          context={{ courseId: "test-course", lessonId: "test-lesson" }}
          onComplete={(result) => console.log("Plugin reported completion:", result)}
        />
      </div>
    </div>
  );
}
```

```bash
npm run dev
```

Visit `http://localhost:3000/dashboard` and confirm:

1. A text area (empty), the prompt above it, and a "Run Query" button.
2. Typing something wrong and clicking **Run Query** shows the red "Not quite" message.
3. Typing exactly `SELECT * FROM students;` (any casing/spacing) and clicking **Run Query** shows the green "Correct! Progress saved." message, the button becomes disabled and reads "Completed ✓", and the console logs `Plugin reported completion: { score: 100, moduleState: {...} }`.

Revert `app/dashboard/page.tsx` back to its Part 2 state, then commit:

```bash
git add components/plugins/sql-sandbox lib/plugin-sdk
git commit -m "feat: build SQL Sandbox plugin honoring GreymatterPluginProps contract"
```

---

## Step 5: Render Custom Modules Inside Real Lesson Content

**The Target:** A lesson page at `/dashboard/courses/[courseSlug]/lessons/[lessonSlug]` that fetches a lesson's Portable Text content from Sanity, renders normal text blocks normally, and — whenever it encounters a `customModule` block — resolves it through the `ModuleRegistry`.

**The Concept:** Sanity's Portable Text is an array of differently-shaped objects — some are `block` (regular paragraphs/headings), some are our custom `customModule` type. We use `@portabletext/react`, which lets us supply custom rendering logic per block type via a `components` prop — like a mail sorter reading each envelope's label and routing it to the correct department: "just print this text" or "hand this off to the plugin registry." This is the combined-render step of the request lifecycle — Sanity content resolved server-side, then handed down for client-side dynamic component resolution.

One correction from the original draft: `courseId` must **not** be derived from the URL's `courseSlug` segment. Part 1 established that `Enrollment.courseId` and `Progress.courseId` are opaque references to a Sanity **course document `_id`**, not a slug. Passing the slug through as if it were the `_id` would silently break every future enrollment/progress lookup in Part 4, since nothing would ever match. Instead, we fetch the course's real `_id` alongside the lesson.

**The Implementation:**

```bash
npm install @portabletext/react
```

#### `lib/sanity/queries.ts` (addition)

```typescript
export interface LessonContentBlock {
  _type: string;
  _key: string;
  [key: string]: unknown;
}

export interface LessonDetail {
  _id: string;
  title: string;
  body: LessonContentBlock[];
  courseId: string;
}

// Resolves the lesson AND walks back up to find which course actually
// references it, so we can pass the course's real Sanity _id (not the
// URL slug) down to the plugin as context.courseId. This matters because
// Part 1 established Enrollment.courseId / Progress.courseId as opaque
// references to a Sanity course document's _id — never a slug.
const LESSON_DETAIL_QUERY = `*[_type == "lesson" && slug.current == $lessonSlug][0] {
  _id,
  title,
  body,
  "courseId": *[_type == "course" && slug.current == $courseSlug][0]._id
}`;

export async function getLessonBySlug(
  courseSlug: string,
  lessonSlug: string
): Promise<LessonDetail | null> {
  return client.fetch(
    LESSON_DETAIL_QUERY,
    { courseSlug, lessonSlug },
    { cache: "force-cache" }
  );
}
```

Now build a Client Component wrapper responsible for resolving and rendering a single `customModule` block, plus handling its completion. Its `onComplete` handler is intentionally just a `console.log` for now — it does **not** write to the database directly. This matches the security boundary from the architecture: a plugin only ever reports a `score` and `moduleState` upward; the actual database write happens later, inside a Prisma transaction that independently verifies the student's enrollment before saving anything.

#### `components/plugins/module-renderer.tsx`

```tsx
"use client";

import { resolveModule } from "@/lib/plugin-sdk/registry";
import type { RawCustomModuleBlock } from "@/lib/plugin-sdk/types";

interface ModuleRendererProps {
  block: RawCustomModuleBlock;
  courseId: string;
  lessonId: string;
}

export function ModuleRenderer({ block, courseId, lessonId }: ModuleRendererProps) {
  const PluginComponent = resolveModule(block.moduleType);

  if (!PluginComponent) {
    // Fails gracefully — a typo'd or not-yet-built moduleType shows a
    // visible warning instead of crashing the entire lesson page.
    return (
      <div className="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-600">
        Unknown module type: <code>{block.moduleType}</code>
      </div>
    );
  }

  let parsedConfig: Record<string, unknown> = {};
  try {
    parsedConfig = block.configPayload ? JSON.parse(block.configPayload) : {};
  } catch {
    return (
      <div className="rounded-md border border-red-200 bg-red-50 p-4 text-sm text-red-600">
        Invalid configPayload JSON for module <code>{block.moduleType}</code>
      </div>
    );
  }

  return (
    <PluginComponent
      config={parsedConfig}
      context={{ courseId, lessonId }}
      onComplete={(result) => {
        // Part 4 replaces this console.log with a real Server Action call
        // wrapped in a Prisma transaction that verifies enrollment before
        // writing progress.
        console.log("Lesson module completed:", result);
      }}
    />
  );
}
```

Finally, the lesson page itself, using `@portabletext/react` to route each block type appropriately — now correctly threading through the course's real Sanity `_id` instead of its slug:

#### `app/dashboard/courses/[courseSlug]/lessons/[lessonSlug]/page.tsx`

```tsx
import { PortableText, type PortableTextComponents } from "@portabletext/react";
import { getLessonBySlug } from "@/lib/sanity/queries";
import { ModuleRenderer } from "@/components/plugins/module-renderer";
import { notFound } from "next/navigation";
import type { RawCustomModuleBlock } from "@/lib/plugin-sdk/types";

interface LessonPageProps {
  params: Promise<{ courseSlug: string; lessonSlug: string }>;
}

export default async function LessonPage({ params }: LessonPageProps) {
  const { courseSlug, lessonSlug } = await params;

  // Server-side fetch, resolved before any HTML reaches the browser.
  // Returns the lesson's own _id AND its parent course's real Sanity _id —
  // never a slug — since that _id is what Progress.courseId will store.
  const lesson = await getLessonBySlug(courseSlug, lessonSlug);

  if (!lesson || !lesson.courseId) {
    notFound();
  }

  // PortableTextComponents lets us supply custom render logic per block type.
  // Regular text blocks fall through to the library's sensible defaults;
  // we only intercept our own "customModule" type.
  const components: PortableTextComponents = {
    types: {
      customModule: ({ value }) => (
        <ModuleRenderer
          block={value as RawCustomModuleBlock}
          courseId={lesson.courseId}
          lessonId={lesson._id}
        />
      ),
    },
  };

  return (
    <article className="prose prose-neutral max-w-3xl">
      <h1 className="text-2xl font-bold text-brand-900">{lesson.title}</h1>
      <div className="mt-6 space-y-4">
        <PortableText value={lesson.body} components={components} />
      </div>
    </article>
  );
}
```

Notice this now fetches `lesson.body` (matching Part 1's actual field name) rather than a `content` field that was never defined, and `courseId` comes from a real cross-referenced Sanity `_id` rather than the URL slug. The `types.customModule` entry is the "mail sorter" routing described earlier — every other block type (paragraphs, headings, lists) is handled automatically by the library's built-in defaults, and only our custom type gets intercepted and handed to `ModuleRenderer`, which calls `resolveModule()` from the registry built in Step 3.

**The Verification:**

1. Confirm your test `lesson` document in Sanity Studio still has the `customModule` block inside its **Body** field with `moduleType: "sql-sandbox"` and a `configPayload` matching the `SqlSandboxConfig` shape exactly (three keys: `prompt`, `starterQuery`, `expectedQuery`), e.g.:

```json
{"prompt": "Write a query that selects everything from the students table.", "starterQuery": "", "expectedQuery": "SELECT * FROM students;"}
```

Click **Publish** in Sanity Studio after updating. Also confirm the test `course` document referencing this lesson (via its `chapter`) is published with a valid slug — the cross-reference query depends on it.

2. Start (or restart) your dev server:

```bash
npm run dev
```

3. Sign in, then navigate through the sidebar (from Part 2) to your test lesson — the URL should resolve to something like `http://localhost:3000/dashboard/courses/intro-to-sql/lessons/what-is-a-database`.
4. Confirm the page renders:
   - The lesson title as an `<h1>`
   - Any regular Portable Text paragraphs as normal prose
   - The SQL Sandbox plugin rendered inline exactly where you inserted the `customModule` block, with the prompt text pulled from `configPayload`
5. Type the correct query and click **Run Query** — confirm the green "Correct! Progress saved." message appears, and your terminal or browser DevTools console logs `Lesson module completed: { score: 100, moduleState: { submittedQuery: "...", lessonId: "..." } }`. The `lessonId` logged should be a real Sanity document `_id` string (e.g. starting with a random alphanumeric string), not the slug.
6. As a negative test, temporarily edit the Sanity document's `moduleType` to a typo like `sql-sandbxo`, republish, refresh the lesson page, and confirm you see the graceful red "Unknown module type: sql-sandbxo" message instead of a crashed page. Revert the typo and republish afterward.
7. As a second negative test, temporarily rename the course's slug in Sanity Studio without republishing the change (or point your browser at a nonexistent `courseSlug` in the URL) and confirm the page correctly 404s rather than rendering with a broken/undefined `courseId`.

Once confirmed, commit this final checkpoint for Part 3:

```bash
git add app/dashboard/courses components/plugins/module-renderer.tsx lib/sanity/queries.ts
git commit -m "feat: render customModule blocks via dynamic plugin registry inside lesson pages"
```

---

## Closing Out Part 3

### What You Have Right Now

- A `customModule` block type added directly into Part 1's existing `lesson.body` schema field — no duplicate or orphaned schema files
- A `Progress` model (patched at the top of this Part) that now actually has the `score` and `moduleState` columns the rest of this Part assumes
- A typed `GreymatterPluginProps` contract (`lib/plugin-sdk/types.ts`) that every plugin component must satisfy
- A `ModuleRegistry` (`lib/plugin-sdk/registry.tsx`) mapping string `moduleType` keys to lazily-loaded components via `next/dynamic`, preventing unused plugin code from bloating every page's bundle
- A fully working "SQL Sandbox" plugin that evaluates a student's typed query and calls `onComplete` with a score and module state snapshot — never writing to the database directly itself
- A real lesson page that fetches Portable Text content from Sanity and routes `customModule` blocks through the registry via `@portabletext/react`'s custom component mapping, correctly resolving `courseId` from a real Sanity document `_id` rather than a URL slug
- Graceful fallback handling for unknown module types, malformed JSON config, and missing course/lesson matches, so one bad content entry or stale link can never crash an entire lesson page

### What's Next

**Part 4: Building the Secure State & Progress Transaction Engine** picks up exactly at the `onComplete` callback's current placeholder `console.log` inside `module-renderer.tsx`. You'll replace that log with a real Next.js Server Action, wrap the database write in a Prisma transaction that verifies enrollment before recording progress, and wire React 19's `useOptimistic` hook into the sidebar so completion checkmarks light up instantly, before the server has even confirmed the write succeeded.
