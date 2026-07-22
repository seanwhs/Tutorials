# Part 3 — Modeling Course Content in Sanity

## The goal

By the end of this part, GreyMatter LMS will have a fully working content authoring system: a real Sanity project, an embedded Sanity Studio running at `/studio` inside our own Next.js app, and a complete schema modeling the course hierarchy — courses, chapters, lessons, instructors, categories, and rich content blocks (including quiz and code-exercise blocks). We'll finish by authoring one real sample course by hand, end to end, so we have genuine content to query against in Part 4.

## Why it exists

Recall Part 0's textbook analogy: Sanity is the publishing house, not the classroom. Before students can browse anything (Part 4) or enroll in anything (Part 8), there has to be *something written* — a structured, validated hierarchy of courses containing chapters containing lessons containing actual content. If we design this hierarchy carelessly now, every later part inherits the mistake: a lesson player that can't tell which course a lesson belongs to, a quiz block with no way to know the correct answer, an instructor with no course to be attributed to. This part is where we deliberately design that structure, once, correctly.

## The data flow

```text
Content Editor opens /studio (embedded Sanity Studio)
        │
        ▼
Creates/edits documents: Course → Chapter → Lesson → Content Blocks
        │
        ▼
Documents saved to Sanity's hosted dataset (a managed, cloud-hosted content database)
        │
        ▼
(Starting Part 4) Next.js queries this dataset via GROQ and the Sanity client
        │
        ▼
Public course catalog and lesson pages render the content
```

Two terms worth defining immediately, since they'll appear constantly for the rest of the series:

- **Schema**: a definition of what *shape* a document is allowed to take — which fields exist, what type each one is, and which are required. Think of it as a form template: a blank intake form at a doctor's office defines exactly which boxes exist (name, date of birth, allergies) before any patient fills one out. Sanity's schema is written in TypeScript, in our own codebase.
- **Document**: one actual filled-in instance of a schema — one specific course, one specific lesson. If "course" is the form template, "React Fundamentals" is one filled-out form.

---

## Step 1 — Creating a Sanity project

### The Target
A real, free Sanity project and dataset, created through Sanity's CLI, giving us a project ID and dataset name we'll use for the rest of the series.

### The Concept
A Sanity **project** is like renting a storage unit — an isolated space with its own address (project ID) that only your credentials can open. A **dataset** is a named partition within that unit — most projects use one called `production` for real content and, later, could add a `staging` dataset for testing changes safely. We'll use a single `production` dataset for the whole series to keep things simple, exactly as a small business might use a single storage unit rather than renting multiple.

### The Implementation

From the project root, install the Sanity CLI as a one-off command (no need to install it globally):

```bash
npm create sanity@latest -- --project-plan=free
```

The CLI will ask a series of questions. Answer as follows:

```text
Would you like to create a new project or use an existing one? › Create new project
Your project name: › GreyMatter LMS
Use the default dataset configuration? › Yes (this creates a "production" dataset)
Project output path: › ./studio-temp   (we will not actually use this folder — see below)
Select project template: › Clean project with no predefined schema types
Would you like to add configuration files for Next.js? › No (we configure this manually, to control exactly what's created)
```

**Why a temporary folder?** The Sanity CLI scaffolds a *standalone* Studio project by default — an entirely separate application. But Part 0's architecture calls for an **embedded** Studio, living inside our existing Next.js app at `/studio`, sharing the same repository, deployment, and domain. So we only use the CLI here to perform the actual *project creation* (which registers a project ID with Sanity's servers) — we will discard the scaffolded folder and wire the embedded Studio ourselves in Step 3.

Once the CLI finishes, find your new project ID:

```bash
cd studio-temp
cat sanity.config.ts
```

Look for a line like `projectId: 'abcd1234'` — copy that value, then return to the main project and remove the temporary folder entirely:

```bash
cd ..
rm -rf studio-temp
```

### The Verification

Confirm the project was registered on Sanity's side by visiting **https://www.sanity.io/manage** in your browser, signing in with the account you used during the CLI flow, and confirming "GreyMatter LMS" appears in your projects list with a `production` dataset underneath it.

---

## Step 2 — Installing Sanity packages into the Next.js app

### The Target
The actual npm packages needed to run an embedded Studio and, later, query content from it.

### The Concept
Up to now, Sanity has only existed as a *remote* project (a storage unit with an address). These packages are what let our *own* Next.js application act both as a landlord's front desk (the embedded Studio, for content editors) and as a tenant reading from the storage unit (the content-fetching client we'll build in Part 4).

### The Implementation

```bash
npm install sanity @sanity/vision next-sanity
```

**Package roles:**
- `sanity` — the core Studio engine and schema-definition types.
- `@sanity/vision` — an optional GROQ query-testing tool built into Studio (a "try it yourself" query console we'll use throughout Part 4).
- `next-sanity` — official helpers for integrating Sanity cleanly with Next.js, including the embedded Studio route component we'll use in Step 4.

### The Verification

```bash
npm ls sanity @sanity/vision next-sanity
```

Expected output lists all three packages with resolved version numbers and no `UNMET DEPENDENCY` warnings.

---

## Step 3 — Environment variables and the Sanity client configuration

### The Target
Adding real Sanity credentials to `.env.local`/`.env.example`, and creating `sanity/lib/client.ts` and `sanity/env.ts` — the foundational configuration every schema file and future query will import from.

### The Concept
Every request to Sanity needs to know three things: *which* project (the project ID), *which* dataset (`production`), and *how fresh* the data needs to be (more on this "API version" concept below). We centralize these three facts in one file so that if we ever need to change them, we change one place, not every file that talks to Sanity — the exact same "single source of truth" principle from Part 2's design tokens.

### The Implementation

Update your environment files:

#### `.env.example` (update the Sanity section)

```bash
# ── Sanity (added in Part 3) ─────────────────────────────────────
NEXT_PUBLIC_SANITY_PROJECT_ID=
NEXT_PUBLIC_SANITY_DATASET=production
SANITY_API_TOKEN=
```

Now add your **real** project ID (from Step 1) to `.env.local`:

```bash
# .env.local
NEXT_PUBLIC_SANITY_PROJECT_ID=your_actual_project_id_here
NEXT_PUBLIC_SANITY_DATASET=production
```

We're leaving `SANITY_API_TOKEN` empty for now — it's only required for *writing* to Sanity or reading unpublished draft content programmatically, neither of which we need until Part 4's preview mode. Studio itself authenticates through your logged-in browser session, not this token.

#### `sanity/env.ts`

```ts
// Centralizes every Sanity-related environment value with runtime
// validation. If a required variable is missing, we want a clear error
// message immediately at startup — not a cryptic failure deep inside a
// GROQ query three files away.
export const projectId = assertValue(
  process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  "Missing environment variable: NEXT_PUBLIC_SANITY_PROJECT_ID"
);

export const dataset = assertValue(
  process.env.NEXT_PUBLIC_SANITY_DATASET,
  "Missing environment variable: NEXT_PUBLIC_SANITY_DATASET"
);

// The API version is a date-based version lock for Sanity's query API.
// Pinning it (instead of always using "latest") means Sanity's API can
// evolve without silently changing how OUR queries behave overnight.
export const apiVersion = "2025-01-01";

function assertValue<T>(value: T | undefined, errorMessage: string): T {
  if (value === undefined) {
    throw new Error(errorMessage);
  }
  return value;
}
```

#### `sanity/lib/client.ts`

```ts
import { createClient } from "next-sanity";
import { apiVersion, dataset, projectId } from "@/sanity/env";

// This is the shared, read-only client every future GROQ query (Part 4
// onward) will import. useCdn=true serves content from Sanity's fast,
// globally-cached CDN rather than hitting the primary API directly —
// appropriate for published, public content where a few seconds of
// staleness is an acceptable tradeoff for speed.
export const client = createClient({
  projectId,
  dataset,
  apiVersion,
  useCdn: true,
});
```

**Code walkthrough:**

- `assertValue` fails loudly at startup if an environment variable is missing, rather than letting `undefined` silently flow into a network request that fails with a confusing, unrelated error later. This "fail fast" pattern will reappear throughout the series.
- `useCdn: true` is a meaningful architectural choice: it means our public course catalog (Part 4) will be fast and cheap to serve, at the cost of occasionally showing content that's a few seconds out of date immediately after a Studio edit. We'll revisit this tradeoff explicitly in Part 4 when we discuss cache revalidation.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors. We'll do a real network verification once Studio is running in the next step.

---

## Step 4 — Embedding Sanity Studio at `/studio`

### The Target
A working Sanity Studio, running live inside our Next.js app at `http://localhost:3000/studio`, with no schema types defined yet (we'll add those in Step 5).

### The Concept
An embedded Studio means the *content editing tool itself* is just another route in our Next.js app — the same way `/api/health` is a route, `/studio` is a route too, except instead of returning JSON, it renders an entire React-based editing application. This is possible because Sanity Studio is, under the hood, itself a React application that `next-sanity` knows how to mount inside any Next.js route.

Because Studio needs to catch *every* URL underneath `/studio` (like `/studio/desk/course` for editing a specific document type), we use a special Next.js convention called a **catch-all route** — a folder named `[[...tool]]` that matches `/studio`, `/studio/anything`, `/studio/anything/nested`, all with one file.

### The Implementation

First, the root Studio configuration file (this is a standard Sanity convention — it must live at the project root, not inside `sanity/`):

#### `sanity.config.ts`

```ts
import { visionTool } from "@sanity/vision";
import { defineConfig } from "sanity";
import { structureTool } from "sanity/structure";
import { apiVersion, dataset, projectId } from "@/sanity/env";
import { schemaTypes } from "@/sanity/schema-types";

export default defineConfig({
  name: "greymatter-lms",
  title: "GreyMatter LMS",

  projectId,
  dataset,

  // basePath must match the route we embed Studio at (the catch-all route
  // below). If these ever mismatch, Studio's internal links (e.g. clicking
  // a document in the list) will navigate to the wrong URL and 404.
  basePath: "/studio",

  plugins: [
    structureTool(), // the standard "desk" — the left-hand document list/editing UI
    visionTool({ defaultApiVersion: apiVersion }), // the GROQ query-testing console
  ],

  schema: {
    types: schemaTypes,
  },
});
```

Next, a placeholder schema index so this file compiles even before we define real schema types in Step 5:

#### `sanity/schema-types/index.ts`

```ts
import type { SchemaTypeDefinition } from "sanity";

// This array is the single registry of every document and object type
// Studio knows about. Step 5 onward will import real schema definitions
// here one at a time. Starting empty lets us verify the embedded Studio
// shell works before adding any content model complexity.
export const schemaTypes: SchemaTypeDefinition[] = [];
```

Now the actual embedded route. This is the catch-all convention described above:

#### `app/studio/[[...tool]]/page.tsx`

```tsx
"use client"; // Sanity Studio is a fully client-rendered React application —
// it manages its own routing, state, and real-time document editing
// entirely in the browser, so this page must opt out of Server Component
// rendering entirely.

import { NextStudio } from "next-sanity/studio";
import config from "@/sanity.config";

export default function StudioPage() {
  return <NextStudio config={config} />;
}
```

**Code walkthrough:**

- `[[...tool]]` (double square brackets) denotes an **optional** catch-all segment — it matches `/studio` itself (zero extra segments) *as well as* `/studio/structure/course` (many extra segments). A single `[...tool]` (single brackets) would only match if at least one extra segment were present, which would break the bare `/studio` URL. This distinction — optional vs. required catch-all — is worth remembering, since we won't use this pattern again until it's genuinely needed.
- `NextStudio` is `next-sanity`'s purpose-built component for exactly this embedding scenario — it handles mounting Studio's internal router inside our page without conflicting with Next.js's own routing.
- We import the config from the project root (`@/sanity.config`) rather than duplicating it — this ensures Studio's embedded instance and any future server-side tooling (Part 4's typed query generation) always reference the exact same schema definitions.

### The Verification

```bash
npm run dev
```

Visit **http://localhost:3000/studio**. You should be prompted to log in with your Sanity account (the same one from Step 1). After logging in, you'll land on Studio's shell — likely showing an empty document list, since no schema types exist yet. This confirms the embedding itself works correctly; we'll populate it with real content types next.

---

## Step 5 — Designing the content hierarchy

### The Target
No code yet in this step — a deliberate planning pause before writing schema files, to fix the exact hierarchy and relationships in your mind first.

### The Concept
Before laying pipes in a house, a plumber draws the full water system on paper — where the main line enters, which rooms branch off it, which fixtures are downstream of which valves — because pipes are expensive to move once installed. Sanity schemas are the same: reorganizing a live content hierarchy after real courses exist is possible but painful. We fix the shape now.

Our hierarchy, matching Part 0's plan:

```text
Course
├── title, slug, description, thumbnail
├── difficulty, category (reference)
├── instructor (reference)
├── isPublished (boolean — draft vs. live)
└── chapters[] (array of references, in order)
        └── Chapter
            ├── title, slug, order
            └── lessons[] (array of references, in order)
                    └── Lesson
                        ├── title, slug, order
                        ├── videoUrl (optional)
                        ├── content (Portable Text — rich text with embedded blocks)
                        │       ├── standard text/headings/images
                        │       ├── Callout block
                        │       ├── Quiz block
                        │       └── Code-exercise block
                        └── isPreview (boolean — accessible without enrollment)
```

Three design decisions worth explaining **before** we write any code, because they directly shape the schema files:

1. **Chapters and lessons are separate document types, referenced from arrays — not nested objects.** A "reference" in Sanity is a pointer from one document to another (conceptually similar to a foreign key in a SQL database, which we'll meet properly in Part 5). We use references here rather than nesting the entire lesson content directly inside the course document because Sanity documents have practical size limits, and because references let Studio show chapters and lessons as their own manageable, independently-editable list items rather than one enormous unwieldy course document.

2. **Quiz and code-exercise blocks live *inside* Portable Text, as custom block types — not as separate top-level documents.** This is because a quiz question is meaningless without its surrounding lesson context; it's authored inline, exactly where it appears in the reading flow, the same way a textbook prints a "check your understanding" box directly inside a chapter rather than in a separate appendix you'd have to cross-reference.

3. **`isPreview` on lessons is a deliberate escape hatch for Part 4's public catalog** — some lessons (typically a course's first lesson) should be viewable by anyone, enrolled or not, as a marketing preview. We build this field in now rather than retrofitting it later, because Part 4's page structure depends on knowing this field exists.

### The Verification

No code to verify yet — but before moving on, make sure you could redraw the diagram above from memory. If any arrow is unclear, re-read this step before continuing; every remaining step in this part builds a schema file matching one box in this diagram.

---

## Step 6 — Building the `category` and `instructor` schemas

### The Target
`sanity/schema-types/category.ts` and `sanity/schema-types/instructor.ts` — the two simplest, "leaf" document types in our hierarchy, referenced by courses but referencing nothing themselves.

### The Concept
We start with the simplest pieces first — the same way you'd assemble furniture by building the small drawer before the cabinet frame it slides into. Categories and instructors have no dependencies on anything else in our schema, so they're the safest, clearest place to learn Sanity's schema-definition syntax before tackling something more complex like Portable Text blocks.

### The Implementation

#### `sanity/schema-types/category.ts`

```ts
import { TagIcon } from "@sanity/icons";
import { defineField, defineType } from "sanity";

export const category = defineType({
  name: "category", // the internal type name — used in GROQ queries and references
  title: "Category", // the human-readable label shown in Studio's UI
  type: "document",
  icon: TagIcon,
  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      // validation rules run both in Studio (blocking publish) and are
      // documented for anyone reading this schema later — they are NOT
      // automatically enforced on our Next.js side, a point we'll return
      // to directly in Part 4's "important correctness rule."
      validation: (rule) => rule.required().max(60),
    }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      // "source: 'title'" powers the "Generate" button in Studio, which
      // auto-derives a URL-safe slug from the title field — a convenience
      // for content editors, not a hard requirement.
      options: { source: "title", maxLength: 60 },
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "description",
      title: "Description",
      type: "text",
      rows: 2,
    }),
  ],
  preview: {
    select: { title: "title" },
  },
});
```

#### `sanity/schema-types/instructor.ts`

```ts
import { UserIcon } from "@sanity/icons";
import { defineField, defineType } from "sanity";

export const instructor = defineType({
  name: "instructor",
  title: "Instructor",
  type: "document",
  icon: UserIcon,
  fields: [
    defineField({
      name: "name",
      title: "Full name",
      type: "string",
      validation: (rule) => rule.required().max(80),
    }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "name", maxLength: 80 },
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "avatar",
      title: "Avatar photo",
      type: "image",
      options: { hotspot: true }, // lets editors pick a focal point for cropping
    }),
    defineField({
      name: "bio",
      title: "Short biography",
      type: "text",
      rows: 4,
      validation: (rule) => rule.max(500),
    }),
    defineField({
      name: "title",
      title: "Professional title",
      type: "string",
      description: 'e.g. "Senior Backend Engineer"',
    }),
  ],
  preview: {
    select: { title: "name", subtitle: "title", media: "avatar" },
  },
});
```

**Code walkthrough:**

- `defineField`/`defineType` are Sanity's typed helper functions — they exist purely to give you TypeScript autocomplete and catch schema mistakes at compile time (e.g., misspelling `"sting"` instead of `"string"` for a `type`). They don't change runtime behavior versus writing plain objects.
- `validation: (rule) => rule.required().max(60)` — this is a **chained validation builder**: `rule.required()` returns a new rule object with `.max(60)` still callable on it, so you can stack as many constraints as needed in one readable line.
- `preview: { select: {...} }` controls what Studio's document list shows for each item — without this, every instructor would show up in a generic, unhelpful list as just "Untitled." We're mapping the list's `title`/`subtitle`/`media` slots to our actual `name`/`title`/`avatar` fields.

Register both in the schema index:

#### `sanity/schema-types/index.ts` (updated)

```ts
import type { SchemaTypeDefinition } from "sanity";
import { category } from "./category";
import { instructor } from "./instructor";

export const schemaTypes: SchemaTypeDefinition[] = [category, instructor];
```

### The Verification

Restart the dev server if it's running, then visit `http://localhost:3000/studio`. Confirm the left sidebar now shows two document types: "Category" and "Instructor." Click "Instructor" → "Create," fill in a name ("Ada Lovelace"), click "Generate" next to Slug, add a short bio, and click **Publish**. Confirm it appears in the instructor list afterward with the name shown correctly (proving the `preview` config works).

Create one Category the same way (e.g., title "Web Development") — we'll need at least one of each for Step 10's sample course.

---

## Step 7 — Building the Portable Text content blocks

### The Target
Three custom block schemas — `sanity/schema-types/callout-block.ts`, `sanity/schema-types/quiz-block.ts`, and `sanity/schema-types/code-exercise-block.ts` — designed to be embedded inside a lesson's Portable Text content.

### The Concept

**Portable Text** is Sanity's format for rich text — instead of storing lesson content as one giant HTML string (which is fragile, hard to validate, and dangerous to render directly due to XSS risks we'll discuss in Part 16), Portable Text stores content as a structured **array of blocks** — each block is a small JSON object describing one paragraph, heading, image, or custom element. Think of it like a slide deck instead of a single scanned poster: each slide (block) is independently editable, reorderable, and can be a completely different *type* of content (a text slide, an image slide, a quiz slide) while still flowing together as one continuous lesson.

The three custom blocks we're building are **object types**, not document types — meaning they don't exist independently in Studio's document list (you'll never see "Quiz Block" as its own top-level item), they only exist *embedded inside* a lesson's Portable Text array. This distinction between `type: "document"` (Step 6) and `type: "object"` (this step) is one of the most important schema-level decisions in the entire content model.

### The Implementation

#### `sanity/schema-types/callout-block.ts`

```ts
import { InfoOutlineIcon } from "@sanity/icons";
import { defineField, defineType } from "sanity";

// A callout is a small highlighted note inline in lesson content — e.g.
// "Tip: remember to save your work" or "Warning: this API call is billed."
// It's an "object" type: it has no independent existence outside a lesson.
export const calloutBlock = defineType({
  name: "calloutBlock",
  title: "Callout",
  type: "object",
  icon: InfoOutlineIcon,
  fields: [
    defineField({
      name: "tone",
      title: "Tone",
      type: "string",
      options: {
        list: [
          { title: "Info", value: "info" },
          { title: "Tip", value: "tip" },
          { title: "Warning", value: "warning" },
        ],
        layout: "radio", // renders as radio buttons instead of a dropdown in Studio
      },
      initialValue: "info",
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "text",
      title: "Text",
      type: "text",
      rows: 3,
      validation: (rule) => rule.required(),
    }),
  ],
  preview: {
    select: { title: "text", subtitle: "tone" },
  },
});
```

#### `sanity/schema-types/quiz-block.ts`

```ts
import { HelpCircleIcon } from "@sanity/icons";
import { defineField, defineType } from "sanity";

// A quiz block defines the QUESTION and its possible answers — never a
// "correctness" value the browser can read directly during normal lesson
// rendering. We'll enforce that separation properly in Part 4 by fetching
// this block through a query that OMITS the correct-answer field for
// unauthenticated/public contexts, and again in Part 11 by grading
// server-side using a privileged query that DOES include it.
export const quizBlock = defineType({
  name: "quizBlock",
  title: "Quiz",
  type: "object",
  icon: HelpCircleIcon,
  fields: [
    defineField({
      name: "moduleId",
      title: "Module ID",
      type: "string",
      description:
        "A stable, unique identifier for this quiz (e.g. 'react-hooks-quiz-1'). Used by the interactive module system in Part 10 — changing this after students have attempted the quiz will disconnect their history.",
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "question",
      title: "Question",
      type: "text",
      rows: 2,
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "options",
      title: "Answer options",
      type: "array",
      of: [{ type: "string" }],
      validation: (rule) => rule.required().min(2).max(6),
    }),
    defineField({
      name: "correctOptionIndex",
      title: "Correct option (index)",
      type: "number",
      description: "The zero-based index into 'Answer options' that is correct.",
      validation: (rule) =>
        rule
          .required()
          .min(0)
          .custom((value, context) => {
            // A custom validation rule — this runs inside Studio to catch
            // an author-side mistake (pointing at an option that doesn't
            // exist) before publish, rather than discovering it at grading
            // time in Part 11.
            const options = (context.parent as { options?: string[] })?.options;
            if (options && typeof value === "number" && value >= options.length) {
              return `Index ${value} is out of range — there are only ${options.length} options.`;
            }
            return true;
          }),
    }),
  ],
  preview: {
    select: { title: "question", subtitle: "moduleId" },
  },
});
```

#### `sanity/schema-types/code-exercise-block.ts`

```ts
import { CodeBlockIcon } from "@sanity/icons";
import { defineField, defineType } from "sanity";

// A short-answer / code exercise — the student types a response (e.g. a
// SQL query or a code snippet) which is graded server-side in Part 11
// against expectedKeywords, NOT executed as real code in this tutorial's
// scope. This keeps the exercise system simple while still demonstrating
// server-authoritative grading.
export const codeExerciseBlock = defineType({
  name: "codeExerciseBlock",
  title: "Code Exercise",
  type: "object",
  icon: CodeBlockIcon,
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
      rows: 3,
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "language",
      title: "Language",
      type: "string",
      options: {
        list: [
          { title: "SQL", value: "sql" },
          { title: "JavaScript", value: "javascript" },
          { title: "Plain text", value: "plaintext" },
        ],
      },
      initialValue: "sql",
    }),
    defineField({
      name: "starterCode",
      title: "Starter code",
      type: "text",
      rows: 4,
      description: "Pre-filled code shown to the student when they open the exercise.",
    }),
    defineField({
      name: "expectedKeywords",
      title: "Expected keywords",
      type: "array",
      of: [{ type: "string" }],
      description:
        "Keywords/substrings the server checks for (case-insensitive) when grading a submission in Part 11.",
      validation: (rule) => rule.required().min(1),
    }),
  ],
  preview: {
    select: { title: "prompt", subtitle: "language" },
  },
});
```

**Code walkthrough:**

- `moduleId` appears on both interactive blocks — this is a deliberate forward reference to Part 10's plugin registry and Part 11's secure grading, where the server needs a **stable identifier** to look up "which quiz is this submission for" independent of the question text (which an editor might reword later without breaking student history).
- The `.custom()` validation in `quizBlock` demonstrates Sanity's most powerful validation feature: arbitrary function-based rules with access to sibling fields via `context.parent`. This catches a real authoring mistake — pointing `correctOptionIndex` at an option that doesn't exist — at write time in Studio, rather than surfacing as a confusing bug during grading three parts later.
- Note carefully: **nothing in this schema hides `correctOptionIndex` from anyone with a valid Sanity API token.** Sanity's document-level permissions aren't fine-grained enough to hide one field from certain queries automatically — that protection has to be enforced by *us*, in our own GROQ queries (Part 4) and server code (Part 11), by simply choosing never to send that field to the browser in student-facing queries. This is worth remembering now: **the schema defines what data can exist, not who's allowed to see which fields** — that responsibility belongs to our query layer.

### The Verification

We can't verify these visually in isolation yet — object types only appear once embedded inside a lesson's Portable Text field, which we build in Step 9. Confirm only that they compile:

```bash
npx tsc --noEmit
```

(This will still show an error until we register them in the schema index — we'll do that together with the lesson schema in Step 9, since Portable Text needs to reference them by name.)

---

## Step 8 — Building the `chapter` schema

### The Target
`sanity/schema-types/chapter.ts` — a document type sitting between courses and lessons, holding an ordered list of lesson references.

### The Concept
A chapter is a folder inside a filing cabinet drawer (the course): it doesn't contain the actual documents itself, it contains an ordered list of *pointers* to where those documents live. This is the reference pattern mentioned in Step 5 — chapters reference lessons, and (in Step 10) courses reference chapters, forming the full hierarchy through pointers rather than deep nesting.

### The Implementation

#### `sanity/schema-types/chapter.ts`

```ts
import { DocumentsIcon } from "@sanity/icons";
import { defineArrayMember, defineField, defineType } from "sanity";

export const chapter = defineType({
  name: "chapter",
  title: "Chapter",
  type: "document",
  icon: DocumentsIcon,
  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (rule) => rule.required().max(100),
    }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title", maxLength: 100 },
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "order",
      title: "Order",
      type: "number",
      description: "Determines this chapter's position within its course (lower = earlier).",
      validation: (rule) => rule.required().integer().min(0),
    }),
    defineField({
      name: "lessons",
      title: "Lessons",
      type: "array",
      // defineArrayMember wraps each array item's definition — here, each
      // item is a REFERENCE to a lesson document, not the lesson itself.
      of: [
        defineArrayMember({
          type: "reference",
          to: [{ type: "lesson" }],
        }),
      ],
      validation: (rule) => rule.required().min(1),
    }),
  ],
  preview: {
    select: { title: "title", subtitle: "order" },
    prepare({ title, subtitle }) {
      return { title, subtitle: `Order: ${subtitle}` };
    },
  },
});
```

**Code walkthrough:**

- `order` is a plain number field, not something Sanity manages automatically — this is intentional. We want content editors to have explicit, visible control over sequencing (e.g., typing `1`, `2`, `3`) rather than relying on array position alone, which becomes ambiguous once chapters are referenced from multiple places or reordered via drag-and-drop.
- `prepare({ title, subtitle })` is a function-based preview — more powerful than the plain `select`-only preview we used for categories, letting us transform the selected values (here, prefixing the order number with the label "Order:") before display.
- Notice `chapter` references `lesson`, but we haven't defined `lesson` yet — Sanity's `to: [{ type: "lesson" }]` is just a string-based type name at this stage, so schema files can reference each other regardless of definition order, as long as every referenced type name is eventually registered in the schema index.

### The Verification

Deferred — we'll verify chapters visually once lessons exist and we can actually create one referencing the other, in Step 10's full course build.

## Step 9 — Building the `lesson` schema

### The Target
`sanity/schema-types/lesson.ts` — the document type where Portable Text content, video embeds, and our three custom blocks (callout, quiz, code-exercise) all come together.

### The Concept
The lesson is where every piece we've built so far converges: it's a document (like chapter and category), but its main `content` field is a Portable Text array that can contain *both* standard rich-text blocks (paragraphs, headings, images) *and* our custom object types from Step 7, interleaved in whatever order an editor authors them — exactly like inserting a photo or a call-out box at a specific point while writing a real document, not appending it at the end.

### The Implementation

#### `sanity/schema-types/lesson.ts`

```ts
import { DocumentTextIcon } from "@sanity/icons";
import { defineArrayMember, defineField, defineType } from "sanity";

export const lesson = defineType({
  name: "lesson",
  title: "Lesson",
  type: "document",
  icon: DocumentTextIcon,
  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (rule) => rule.required().max(120),
    }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title", maxLength: 120 },
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "order",
      title: "Order",
      type: "number",
      description: "Determines this lesson's position within its chapter (lower = earlier).",
      validation: (rule) => rule.required().integer().min(0),
    }),
    defineField({
      name: "isPreview",
      title: "Available as free preview",
      type: "boolean",
      description:
        "If enabled, this lesson is viewable by anyone, even without enrolling in the course. Typically used for a course's first lesson.",
      initialValue: false,
    }),
    defineField({
      name: "videoUrl",
      title: "Video URL",
      type: "url",
      description: "Optional embedded video (e.g. a YouTube or Vimeo link).",
    }),
    defineField({
      name: "content",
      title: "Lesson content",
      type: "array",
      // "of" lists every block TYPE allowed inside this Portable Text
      // field. The first entry, { type: "block" }, is Sanity's BUILT-IN
      // rich text block (paragraphs, headings, bold/italic, lists). Every
      // entry after it is one of OUR custom object types from Step 7.
      of: [
        defineArrayMember({
          type: "block",
          // Restricting styles/marks keeps the authoring experience
          // focused and prevents inconsistent formatting from creeping
          // into lesson content over time.
          styles: [
            { title: "Normal", value: "normal" },
            { title: "Heading 2", value: "h2" },
            { title: "Heading 3", value: "h3" },
            { title: "Quote", value: "blockquote" },
          ],
          lists: [
            { title: "Bullet", value: "bullet" },
            { title: "Numbered", value: "number" },
          ],
          marks: {
            decorators: [
              { title: "Bold", value: "strong" },
              { title: "Italic", value: "em" },
              { title: "Code", value: "code" },
            ],
          },
        }),
        defineArrayMember({
          type: "image",
          options: { hotspot: true },
          fields: [
            defineField({
              name: "alt",
              title: "Alternative text",
              type: "string",
              description: "Important for accessibility and SEO — describe the image content.",
              validation: (rule) => rule.required(),
            }),
          ],
        }),
        defineArrayMember({ type: "calloutBlock" }),
        defineArrayMember({ type: "quizBlock" }),
        defineArrayMember({ type: "codeExerciseBlock" }),
      ],
    }),
  ],
  preview: {
    select: { title: "title", subtitle: "order", isPreview: "isPreview" },
    prepare({ title, subtitle, isPreview }) {
      return {
        title,
        subtitle: `Order: ${subtitle}${isPreview ? " · Free preview" : ""}`,
      };
    },
  },
});
```

**Code walkthrough:**

- `type: "block"` is Sanity's *built-in* Portable Text block — we're not defining it ourselves, only configuring which `styles`, `lists`, and `marks` (bold/italic/code) are available to editors. Restricting these options is a deliberate content-governance choice: it keeps every lesson's formatting visually consistent, since editors can't invent one-off styles that our Part 4/Part 9 rendering code wouldn't know how to display anyway.
- The `image` array member includes a **required `alt` field** — this is not optional cosmetic strictness. Every image needs alternative text for screen-reader accessibility, and we're enforcing this at the schema level, in Studio, rather than hoping editors remember to add it — the same "bake it in structurally rather than trust discipline" principle we used for `isPreview` in Step 5.
- The three custom block members (`calloutBlock`, `quizBlock`, `codeExerciseBlock`) are added simply by referencing their registered type names — this is the payoff of Step 7: once registered in the schema index (next), Studio's Portable Text editor will offer them as insertable block types via a "+" menu, indistinguishable in the authoring UI from inserting a normal paragraph or image.

Now register everything built so far in the schema index — order matters here only in the sense that referenced types (`calloutBlock`, `quizBlock`, `codeExerciseBlock`) should exist in the array before or alongside the types that reference them; Sanity resolves this by name, not array position, but keeping it organized helps human readers:

#### `sanity/schema-types/index.ts` (updated)

```ts
import type { SchemaTypeDefinition } from "sanity";
import { calloutBlock } from "./callout-block";
import { category } from "./category";
import { chapter } from "./chapter";
import { codeExerciseBlock } from "./code-exercise-block";
import { instructor } from "./instructor";
import { lesson } from "./lesson";
import { quizBlock } from "./quiz-block";

export const schemaTypes: SchemaTypeDefinition[] = [
  // Documents
  category,
  instructor,
  chapter,
  lesson,
  // Objects (embedded only — never appear as top-level Studio documents)
  calloutBlock,
  quizBlock,
  codeExerciseBlock,
];
```

### The Verification

```bash
npx tsc --noEmit
```

Should now complete with no errors — this confirms every schema file compiles and every referenced type name (`calloutBlock`, `quizBlock`, etc.) resolves correctly.

Restart the dev server, visit `http://localhost:3000/studio`, and confirm "Chapter" and "Lesson" now appear in the sidebar alongside "Category" and "Instructor." Click "Lesson" → "Create," give it a title, and click the "+" button inside the empty content array — confirm the insert menu shows options including "Callout," "Quiz," and "Code Exercise" alongside the standard text and image options. Don't publish yet — we'll author a real lesson properly as part of Step 10's full sample course.

---

## Step 10 — Building the `course` schema and authoring the first sample course

### The Target
`sanity/schema-types/course.ts` — the top-level document type tying everything together — followed by hand-authoring one complete, published, real course through Studio: one course, containing one chapter, containing two lessons, one of which includes a quiz block.

### The Concept
The course document is the "cover and table of contents" of our textbook analogy — it doesn't contain lesson content directly, it references an instructor, a category, and an ordered list of chapters, plus metadata like difficulty and publication status that Part 4's catalog page will filter and display by.

### The Implementation

#### `sanity/schema-types/course.ts`

```ts
import { BookIcon } from "@sanity/icons";
import { defineArrayMember, defineField, defineType } from "sanity";

export const course = defineType({
  name: "course",
  title: "Course",
  type: "document",
  icon: BookIcon,
  fields: [
    defineField({
      name: "title",
      title: "Title",
      type: "string",
      validation: (rule) => rule.required().max(120),
    }),
    defineField({
      name: "slug",
      title: "Slug",
      type: "slug",
      options: { source: "title", maxLength: 120 },
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "description",
      title: "Description",
      type: "text",
      rows: 4,
      validation: (rule) => rule.required().max(600),
    }),
    defineField({
      name: "thumbnail",
      title: "Thumbnail image",
      type: "image",
      options: { hotspot: true },
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "difficulty",
      title: "Difficulty",
      type: "string",
      options: {
        list: [
          { title: "Beginner", value: "beginner" },
          { title: "Intermediate", value: "intermediate" },
          { title: "Advanced", value: "advanced" },
        ],
        layout: "radio",
      },
      initialValue: "beginner",
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "category",
      title: "Category",
      type: "reference",
      to: [{ type: "category" }],
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "instructor",
      title: "Instructor",
      type: "reference",
      to: [{ type: "instructor" }],
      validation: (rule) => rule.required(),
    }),
    defineField({
      name: "learningObjectives",
      title: "Learning objectives",
      type: "array",
      of: [{ type: "string" }],
      description: "Short bullet points shown on the course detail page (Part 4).",
      validation: (rule) => rule.min(1),
    }),
    defineField({
      name: "chapters",
      title: "Chapters",
      type: "array",
      of: [
        defineArrayMember({
          type: "reference",
          to: [{ type: "chapter" }],
        }),
      ],
      validation: (rule) => rule.required().min(1),
    }),
    defineField({
      name: "isPublished",
      title: "Published",
      type: "boolean",
      description:
        "Unpublished courses are hidden from the public catalog (enforced in Part 4's queries) even if this document itself is saved.",
      initialValue: false,
    }),
  ],
  preview: {
    select: {
      title: "title",
      subtitle: "difficulty",
      media: "thumbnail",
      isPublished: "isPublished",
    },
    prepare({ title, subtitle, media, isPublished }) {
      return {
        title: `${isPublished ? "" : "🔒 "}${title}`,
        subtitle,
        media,
      };
    },
  },
});
```

**Code walkthrough:**

- `isPublished` is a plain boolean field **we** control — this is distinct from Sanity's own built-in draft/published document state (every document is automatically a "draft" until explicitly published via Studio's Publish button, which we'll explain fully in Part 4). We're layering an *additional*, editor-controlled flag on top, because a course might be technically "published" as a Sanity document (so an editor can preview it, share a link internally) while still not being intended for the *public* catalog yet — e.g., a course fully written and proofread but scheduled for announcement next week. Part 4's public queries will filter on `isPublished == true`, not on Sanity's own draft state.
- The preview's `prepare` function prepends a 🔒 emoji to the title whenever `isPublished` is `false` — a small but genuinely useful touch: it lets a content editor scan Studio's course list and instantly spot which courses are still hidden from the public catalog, without opening each one individually.

Register the final schema type:

#### `sanity/schema-types/index.ts` (final version for this part)

```ts
import type { SchemaTypeDefinition } from "sanity";
import { calloutBlock } from "./callout-block";
import { category } from "./category";
import { chapter } from "./chapter";
import { codeExerciseBlock } from "./code-exercise-block";
import { course } from "./course";
import { instructor } from "./instructor";
import { lesson } from "./lesson";
import { quizBlock } from "./quiz-block";

export const schemaTypes: SchemaTypeDefinition[] = [
  // Documents
  course,
  category,
  instructor,
  chapter,
  lesson,
  // Objects (embedded only — never appear as top-level Studio documents)
  calloutBlock,
  quizBlock,
  codeExerciseBlock,
];
```

### Authoring the first sample course, by hand, end to end

Restart the dev server and open `http://localhost:3000/studio`. We now author real content, in this exact order (order matters — later documents reference earlier ones):

**1. Confirm you already have one Category and one Instructor** from Step 6. If not, create them now (Category: "Web Development"; Instructor: "Ada Lovelace").

**2. Create two Lessons:**

- Lesson 1 — Title: `What is a Database?`
  - Order: `1`
  - Available as free preview: **enabled** (this will be our public-preview lesson in Part 4)
  - Content: add one paragraph of body text (e.g., "A database is a structured collection of data that a computer can quickly search, update, and manage."), then insert a **Callout** block (tone: "Tip", text: "You'll use this exact concept when we introduce Neon in Part 5.")
  - Click **Publish**.

- Lesson 2 — Title: `Writing Your First Query`
  - Order: `2`
  - Available as free preview: disabled
  - Content: add one paragraph, then insert a **Quiz** block:
    - Module ID: `first-query-quiz`
    - Question: `Which SQL keyword retrieves rows from a table?`
    - Answer options: `SELECT`, `INSERT`, `DELETE`, `UPDATE`
    - Correct option (index): `0`
  - Click **Publish**.

**3. Create one Chapter:**

- Title: `Getting Started`
- Order: `1`
- Lessons: add both lessons above, **in order** (Lesson 1, then Lesson 2)
- Click **Publish**.

**4. Create the Course:**

- Title: `Introduction to Databases`
- Description: a few sentences summarizing the course
- Thumbnail: upload any placeholder image
- Difficulty: `Beginner`
- Category: select "Web Development"
- Instructor: select "Ada Lovelace"
- Learning objectives: add two or three short bullet strings (e.g., "Understand what a database is", "Write a basic SELECT query")
- Chapters: add the "Getting Started" chapter
- Published: **enable this checkbox**
- Click **Publish**.

### The Verification

In Studio's document list, click "Course" and confirm "Introduction to Databases" appears **without** the 🔒 lock emoji (proving `isPublished` displays correctly). Click into it and confirm every reference (category, instructor, chapter) resolved correctly and shows a readable title rather than a broken reference warning.

Then run the full project verification suite to confirm nothing regressed:

```bash
npm run lint
npm run typecheck
npm run build
```

All three should complete without errors. This confirms our schema files are syntactically valid TypeScript in addition to being valid inside Studio.

---

## Common mistakes

- **`/studio` shows a blank white screen** — Almost always a `basePath` mismatch between `sanity.config.ts` and the actual route folder. Confirm `basePath: "/studio"` exactly matches the `app/studio/[[...tool]]/` folder path.
- **"Missing environment variable" error on page load** — `NEXT_PUBLIC_SANITY_PROJECT_ID` or `NEXT_PUBLIC_SANITY_DATASET` is missing from `.env.local`, or the dev server was started before the file was saved (environment variables are only read at server startup — restart after any `.env.local` change).
- **A referenced document shows "Broken reference" in Studio** — Usually means you tried to reference a document type that hasn't been registered in `schema-types/index.ts` yet, or the referenced document was deleted. Confirm the type is registered and the target document still exists.
- **Quiz block's "+"-menu option doesn't appear inside lesson content** — Confirm `quizBlock` (and the others) are spelled identically between their `defineType({ name: "quizBlock", ... })` declaration and the `defineArrayMember({ type: "quizBlock" })` entry inside `lesson.ts`'s `content` field — these are plain string matches with no autocomplete safety net across files.
- **`rule.custom()` validation in `quiz-block.ts` throws a TypeScript error about `context.parent`** — `context.parent` is typed as `unknown` by Sanity's types since it can't know your schema shape statically; the `as { options?: string[] }` cast in our example is the expected, correct way to handle this — just be sure the cast shape actually matches the sibling field you're reading.
- **Course preview still shows 🔒 after enabling "Published"** — Confirm you clicked **Publish** (not just closed the document) after checking the box — an unpublished draft change won't reflect anywhere queries or other Studio views read from, which is the exact draft/published distinction Part 4 will explain in depth.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `sanity.config.ts`, `sanity/env.ts`, `sanity/lib/client.ts`, `sanity/schema-types/*.ts`, `app/studio/[[...tool]]/page.tsx`, and the updated `.env.example`. (Your authored content itself — the course, lessons, chapter, category, and instructor — lives in Sanity's hosted dataset, not in Git, so it won't appear here; that's expected and correct.)

```bash
git commit -m "Part 3: Sanity content model — embedded Studio, course/chapter/lesson schemas, custom Portable Text blocks, first sample course"
```

---

## Reference: document types vs. object types cheat sheet

| | Document type (`type: "document"`) | Object type (`type: "object"`) |
|---|---|---|
| Appears as its own item in Studio's document list? | Yes | No — only embedded inside a field |
| Has its own unique `_id` and can be referenced from elsewhere? | Yes | No |
| Examples in our schema | `course`, `category`, `instructor`, `chapter`, `lesson` | `calloutBlock`, `quizBlock`, `codeExerciseBlock` |
| Analogy | A standalone form (its own filing-cabinet folder) | A stamped-in section *within* another form |

## Reference: the full schema field inventory

| Schema | Field | Type | Notes |
|---|---|---|---|
| `category` | title, slug, description | string, slug, text | Simple, leaf-level, no references |
| `instructor` | name, slug, avatar, bio, title | string, slug, image, text, string | Leaf-level |
| `chapter` | title, slug, order, lessons[] | string, slug, number, reference array | References `lesson` |
| `lesson` | title, slug, order, isPreview, videoUrl, content[] | string, slug, number, boolean, url, Portable Text array | `content` mixes `block`, `image`, `calloutBlock`, `quizBlock`, `codeExerciseBlock` |
| `course` | title, slug, description, thumbnail, difficulty, category, instructor, learningObjectives[], chapters[], isPublished | string, slug, text, image, string, reference, reference, string array, reference array, boolean | Top of the hierarchy |
| `calloutBlock` | tone, text | string, text | Object type only |
| `quizBlock` | moduleId, question, options[], correctOptionIndex | string, text, string array, number | `correctOptionIndex` must never be sent to unauthenticated public queries |
| `codeExerciseBlock` | moduleId, prompt, language, starterCode, expectedKeywords[] | string, text, string, text, string array | Graded server-side in Part 11 |

---

## What's next

Part 4 turns this authored content into real, public web pages: we'll write our first GROQ queries, generate TypeScript types from them, build a public course catalog and course detail page, render Portable Text (including our custom blocks) safely in the browser, and establish the critical rule that lesson queries must always be scoped through their parent course — never accepted as a standalone slug.
