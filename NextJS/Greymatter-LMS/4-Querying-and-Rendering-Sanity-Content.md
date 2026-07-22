# Part 4 — Querying and Rendering Sanity Content

## The goal

By the end of this part, GreyMatter LMS will have a real, public-facing course catalog at `/courses` and a course detail page at `/courses/[courseSlug]`, both powered by hand-written GROQ queries against the content we authored in Part 3. We'll generate TypeScript types for our query results, render Portable Text (including our custom callout, quiz, and code-exercise blocks) safely, handle loading and error states properly, and establish a critical security/correctness rule: a lesson can never be looked up independently of its parent course.

## Why it exists

Part 3 gave us a filing cabinet full of correctly organized documents. But a filing cabinet nobody can open is useless — this part builds the "front desk" that actually retrieves and displays those documents to the public. Just as importantly, this is where we start thinking about **query design as a security boundary**, not just a data-fetching convenience: what we choose to *ask for* in a GROQ query determines what data is exposed to the browser, which matters enormously once quiz answers (Part 3's `correctOptionIndex`) are in the mix.

## The data flow

```text
Browser requests /courses
        │
        ▼
Server Component (app/courses/page.tsx)
        │
        ▼
GROQ query via sanity/lib/client.ts
        │
        ▼
Sanity CDN returns matching published course documents
        │
        ▼
Server Component renders HTML with the results
        │
        ▼
Browser receives fully-formed HTML (no separate client-side fetch needed)
```

Two terms to define before we write any queries:

- **GROQ** ("Graph-Relational Object Queries") — Sanity's dedicated query language, purpose-built for querying nested, reference-heavy JSON documents. Think of it as SQL's cousin, but designed from the ground up for content trees (arrays of references, nested objects) rather than flat database tables.
- **Cache revalidation** — the process of telling Next.js "the data you cached for this page might be stale now, please refetch it." We'll cover this properly in Step 8, but it's worth knowing the term exists: without it, published Sanity edits could take a long time to appear on our live pages.

---

## Step 1 — Writing and testing our first GROQ query in Vision

### The Target
Using the Vision tool (installed in Part 3, Step 2) inside Studio to write and test a GROQ query interactively, before we ever put it in application code.

### The Concept
Vision is a query sandbox — like a chemist's test tube rack, where you mix a reaction on a small scale before running it in a full production batch. Testing GROQ queries here first, with instant visual feedback, is dramatically faster than writing a query directly inside a Next.js page and refreshing the browser to see if it worked.

### The Implementation

No files to create. Visit `http://localhost:3000/studio/vision` (Vision is also reachable via a compass-shaped icon in Studio's top toolbar). Enter this query into the left pane:

```groq
*[_type == "course" && isPublished == true]{
  title,
  slug,
  difficulty
}
```

### The Verification

Click "Fetch" (or press the run shortcut shown in the UI). You should see a JSON array in the right pane containing exactly one object — our "Introduction to Databases" course — with its `title`, `slug` (an object containing a `current` property), and `difficulty` fields. If the array is empty, revisit Part 3's Step 10 and confirm the course's "Published" checkbox was actually checked and the document was published, not just saved as a draft.

**Code walkthrough of the query syntax:**

- `*` — means "every document in the dataset, of any type." This is GROQ's starting point for almost every query.
- `[_type == "course" && isPublished == true]` — a **filter**, narrowing "every document" down to only course documents that are also published. `_type` is a field Sanity adds automatically to every document, recording which schema it was created from.
- `{ title, slug, difficulty }` — a **projection**, specifying exactly which fields to return. Without a projection, GROQ returns the *entire* document, including every field — explicitly projecting is both a performance optimization and, as we'll see in Step 5, a security practice (never fetching more than a page actually needs).

---

## Step 2 — Resolving references in GROQ

### The Target
Extending our query to follow the `category` and `instructor` references, since Step 1's version only returned a raw, unresolved reference pointer (an object like `{ "_ref": "abc123", "_type": "reference" }`) rather than the actual category or instructor data.

### The Concept
Recall from Part 3 that a reference is a pointer, not the data itself — the same way a library catalog card lists a shelf location, not the book's actual contents. GROQ's arrow syntax (`->`) means "follow this pointer and fetch the document it points to," directly inline in the query.

### The Implementation

In Vision, replace the query with:

```groq
*[_type == "course" && isPublished == true]{
  title,
  slug,
  difficulty,
  category->{
    title,
    slug
  },
  instructor->{
    name,
    slug
  }
}
```

### The Verification

Click "Fetch" again. The result should now show `category` and `instructor` as fully resolved objects — e.g., `"category": { "title": "Web Development", "slug": { "current": "web-development" } }` — instead of a bare reference pointer. This confirms the `->` dereference operator works as expected, and we now have a query shape close to what our catalog page needs.

---

## Step 3 — Installing image URL tooling

### The Target
A small helper, `sanity/lib/image.ts`, that converts a Sanity image reference into an actual, optimized, loadable `<img>` URL.

### The Concept
Sanity stores images as *assets* with metadata (dimensions, a hash, a crop "hotspot" if configured) — not as a ready-made URL. Think of it like a photo negative stored in an archive: you need a specific process ("print me an 800×600 copy") to turn it into something displayable. The `@sanity/image-url` package is exactly that printing process, and it lets us request specific sizes and crops on demand rather than always downloading a full-resolution original.

### The Implementation

```bash
npm install @sanity/image-url
```

#### `sanity/lib/image.ts`

```ts
import createImageUrlBuilder from "@sanity/image-url";
import type { Image } from "sanity";
import { dataset, projectId } from "@/sanity/env";

const builder = createImageUrlBuilder({ projectId, dataset });

// Accepts any Sanity image object (from a thumbnail field, an avatar
// field, or an inline Portable Text image block) and returns a chainable
// URL builder. Callers then specify exactly the size/format they need,
// e.g. urlForImage(source).width(800).height(450).url()
export function urlForImage(source: Image) {
  return builder.image(source);
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors. We'll see this in actual use rendering a real image in Step 6.

---

## Step 4 — Building typed query result interfaces

### The Target
`sanity/lib/queries.ts` — a file holding both our GROQ query strings *and* hand-written TypeScript interfaces describing exactly what shape each query returns.

### The Concept
A GROQ query string, by itself, has no connection to TypeScript's type system — Sanity doesn't know at compile time what shape a raw string of query syntax will produce. Without doing anything about this, every query result would be typed `any`, silently disabling type-checking exactly where we need it most (three levels of nested references and arrays). We solve this the straightforward, beginner-friendly way: hand-writing an interface next to each query, describing its result shape ourselves. This is a manual step now — larger teams sometimes use code-generation tools to produce these types automatically from the schema, but writing them by hand first builds a much clearer mental model of what's actually happening, which is why we're doing it this way in this series.

### The Implementation

#### `sanity/lib/queries.ts`

```ts
import type { PortableTextBlock } from "sanity";

// ── Shared shape fragments ──────────────────────────────────────────

export interface SanitySlug {
  current: string;
}

export interface SanityImageRef {
  asset: {
    _ref: string;
    _type: "reference";
  };
  hotspot?: {
    x: number;
    y: number;
  };
}

// ── Course catalog card (list view) ─────────────────────────────────

export interface CourseCard {
  _id: string;
  title: string;
  slug: SanitySlug;
  description: string;
  thumbnail: SanityImageRef;
  difficulty: "beginner" | "intermediate" | "advanced";
  category: { title: string; slug: SanitySlug };
  instructor: { name: string; slug: SanitySlug };
}

// GROQ query string for the catalog page. Notice: no correctOptionIndex,
// no lesson content, nothing beyond what a course TILE needs to render —
// this is the "never fetch more than the page needs" principle in action.
export const courseCatalogQuery = /* groq */ `
  *[_type == "course" && isPublished == true] | order(title asc) {
    _id,
    title,
    slug,
    description,
    thumbnail,
    difficulty,
    category->{ title, slug },
    instructor->{ name, slug }
  }
`;

// ── Course detail page ───────────────────────────────────────────────

export interface LessonSummary {
  _id: string;
  title: string;
  slug: SanitySlug;
  order: number;
  isPreview: boolean;
}

export interface ChapterSummary {
  _id: string;
  title: string;
  slug: SanitySlug;
  order: number;
  lessons: LessonSummary[];
}

export interface CourseDetail extends CourseCard {
  learningObjectives: string[];
  chapters: ChapterSummary[];
}

// $slug is a GROQ PARAMETER — a placeholder filled in safely at query
// time (see Step 5), rather than us string-concatenating user input
// directly into the query. This is GROQ's equivalent of a parameterized
// SQL query, and it's the correct way to prevent query-injection issues.
export const courseDetailQuery = /* groq */ `
  *[_type == "course" && slug.current == $slug && isPublished == true][0]{
    _id,
    title,
    slug,
    description,
    thumbnail,
    difficulty,
    learningObjectives,
    category->{ title, slug },
    instructor->{ name, slug },
    chapters[]->{
      _id,
      title,
      slug,
      order,
      lessons[]->{
        _id,
        title,
        slug,
        order,
        isPreview
      }
    } | order(order asc)
  }
`;
```

**Code walkthrough:**

- `/* groq */` immediately before the template string is a convention (not a functional requirement) that enables GROQ syntax highlighting in editors with the right extension installed — a small but genuinely useful habit for readability.
- `chapters[]->{ ... }` — the `[]` after `chapters` means "for every item in this array," and `->` means "dereference each one." So this line reads as "for every chapter reference in the array, follow it and fetch the specified fields" — and the same pattern repeats one level deeper for `lessons[]->`.
- `| order(order asc)` — GROQ's pipe operator applies a transformation to the preceding result; here we sort resolved chapters by their `order` field. This guarantees chapters (and, on the inner array, lessons) always render in the sequence an editor intended, regardless of the order they happen to be stored in Sanity's internal array.
- `[0]` after the course filter — since `slug.current == $slug` should only ever match one course, `[0]` takes the first (and only) match and returns a single object instead of an array. Without it, `courseDetailQuery` would return `CourseDetail[]` (always length 0 or 1), forcing every caller to unwrap an array just to get one course — `[0]` does that unwrapping directly inside the query itself.
- `CourseDetail extends CourseCard` — a small TypeScript convenience: the detail page needs everything a catalog card needs (title, thumbnail, category, etc.) *plus* `learningObjectives` and `chapters`. Extending the interface avoids repeating every shared field twice.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors — this only confirms the file is syntactically valid TypeScript so far; we'll prove the types actually match real data once we use these queries in Step 5.

---

## Step 5 — Building the public course catalog page

### The Target
`app/courses/page.tsx` — a Server Component that runs `courseCatalogQuery`, and `app/courses/loading.tsx` — a loading skeleton shown automatically while the query resolves.

### The Concept
Recall from Part 1: a Server Component can directly `await` data — no `useEffect`, no client-side loading spinner logic, no separate API route needed just to move data from server to browser. It fetches the data and renders finished HTML in one motion, the same way a librarian who already has the requested book in hand simply hands it to you rather than sending you to go find it yourself. The `loading.tsx` file is a special Next.js convention: if it exists alongside a `page.tsx` in the same route folder, Next.js automatically shows it (wrapped in a React `<Suspense>` boundary behind the scenes) while the page's data is still being fetched — no manual wiring required.

### The Implementation

First, the client that actually executes queries (distinct from `sanity/lib/client.ts`'s raw connection — this step uses it directly):

#### `app/courses/page.tsx`

```tsx
import { client } from "@/sanity/lib/client";
import { urlForImage } from "@/sanity/lib/image";
import { courseCatalogQuery, type CourseCard } from "@/sanity/lib/queries";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import Image from "next/image";
import Link from "next/link";

const difficultyLabels: Record<CourseCard["difficulty"], string> = {
  beginner: "Beginner",
  intermediate: "Intermediate",
  advanced: "Advanced",
};

// Server Components can be declared "async" directly — Next.js awaits
// the whole function before rendering, unlike a Client Component, which
// would need useEffect + useState to achieve the same result.
export default async function CourseCatalogPage() {
  // client.fetch() sends the GROQ query to Sanity and returns parsed JSON.
  // The generic <CourseCard[]> tells TypeScript what shape to expect back —
  // this is exactly the manual "trust me, I wrote the query to match this
  // interface" step described in Step 4. Sanity itself does not verify
  // this at compile time; it's on us to keep query and interface in sync.
  const courses = await client.fetch<CourseCard[]>(courseCatalogQuery);

  return (
    <main className="mx-auto flex max-w-5xl flex-col gap-8 px-6 py-16">
      <div>
        <h1 className="text-3xl font-bold text-text-primary">Course Catalog</h1>
        <p className="mt-2 text-text-secondary">
          Browse every published course. Enroll to track your progress.
        </p>
      </div>

      {courses.length === 0 ? (
        <EmptyState
          title="No courses published yet"
          description="Check back soon — new courses are added regularly."
        />
      ) : (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {courses.map((course) => (
            <Link key={course._id} href={`/courses/${course.slug.current}`}>
              <Card className="h-full transition hover:border-brand hover:shadow-md">
                <div className="relative aspect-video w-full overflow-hidden rounded-t-[var(--radius-panel)]">
                  <Image
                    src={urlForImage(course.thumbnail).width(600).height(340).url()}
                    alt={course.title}
                    fill
                    className="object-cover"
                  />
                </div>
                <CardHeader>
                  <div className="flex items-center gap-2">
                    <Badge variant="brand">{difficultyLabels[course.difficulty]}</Badge>
                    <Badge variant="neutral">{course.category.title}</Badge>
                  </div>
                  <CardTitle>{course.title}</CardTitle>
                </CardHeader>
                <CardContent>
                  <p className="line-clamp-3 text-sm text-text-secondary">
                    {course.description}
                  </p>
                  <p className="mt-3 text-xs text-text-muted">
                    Taught by {course.instructor.name}
                  </p>
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </main>
  );
}
```

Now the loading skeleton — this file needs no imports beyond what it uses directly, and no data fetching of its own:

#### `app/courses/loading.tsx`

```tsx
import { Skeleton } from "@/components/ui/skeleton";

export default function CourseCatalogLoading() {
  return (
    <main className="mx-auto flex max-w-5xl flex-col gap-8 px-6 py-16">
      <div className="flex flex-col gap-2">
        <Skeleton className="h-9 w-64" />
        <Skeleton className="h-5 w-96" />
      </div>
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 6 }).map((_, index) => (
          <div key={index} className="flex flex-col gap-3 rounded-[var(--radius-panel)] border border-border p-4">
            <Skeleton className="aspect-video w-full" />
            <Skeleton className="h-5 w-3/4" />
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-2/3" />
          </div>
        ))}
      </div>
    </main>
  );
}
```

**Code walkthrough:**

- `Array.from({ length: 6 }).map((_, index) => ...)` is a common pattern for rendering a fixed number of placeholder items with no real data backing them — `{ length: 6 }` creates an array-like object of six empty slots, and `.map` fills each with skeleton markup. We use the numeric `index` as the React `key` here specifically *because* there's no real data with a stable ID yet — this is one of the few situations where using an array index as a key is the correct choice, since the list is static and never reordered.
- `next/image`'s `fill` prop, combined with the parent's `relative aspect-video` wrapper, makes the thumbnail responsively fill its container while preserving a 16:9 aspect ratio — this is Next.js's built-in image optimization component, which automatically handles responsive sizing, lazy loading, and format conversion (e.g., serving WebP where supported) without us writing any of that logic ourselves.
- `line-clamp-3` (a Tailwind utility) truncates the description to exactly three lines with a trailing ellipsis, keeping every card the same visual height regardless of how long an individual course's description text is.

Next.js's `next/image` component requires us to explicitly allow external image domains for security reasons — without this, Next.js will refuse to optimize images from Sanity's CDN. Add this configuration:

#### `next.config.ts`

```ts
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "cdn.sanity.io",
      },
    ],
  },
};

export default nextConfig;
```

### The Verification

Restart the dev server (required after editing `next.config.ts`):

```bash
npm run dev
```

Visit `http://localhost:3000/courses`. You should briefly see the six-card skeleton grid (it may flash quickly on a fast local connection — try throttling your network in DevTools to "Slow 3G" temporarily to observe it clearly), followed by the real catalog showing one card: "Introduction to Databases," with the correct thumbnail, "Beginner" and "Web Development" badges, description, and "Taught by Ada Lovelace." Click the card and confirm it attempts to navigate to `/courses/introduction-to-databases` (this will 404 for now — we build that page next).

---

## Step 6 — Building the course detail page and rendering Portable Text

### The Target
`app/courses/[courseSlug]/page.tsx` — a dynamic route rendering one course's full detail page, including its chapter/lesson outline and Portable Text preview content, plus proper handling for a course slug that doesn't exist.

### The Concept
A **dynamic route** is a page whose URL contains a variable segment — `[courseSlug]` in the folder name means Next.js will match *any* value in that position (`/courses/introduction-to-databases`, `/courses/react-fundamentals`, etc.) and hand us that value as a parameter, rather than us needing to create a separate file for every possible course. **Portable Text rendering** is the process of turning that structured array-of-blocks format from Part 3 into actual HTML — and critically, it must be done through a library that understands the format's structure, never through something like `dangerouslySetInnerHTML`, which would open the door to injecting arbitrary HTML/scripts if content ever came from a less-trusted source (a real concern we'll expand on in Part 16).

### The Implementation

First, install the official Portable Text React renderer:

```bash
npm install @portabletext/react
```

Now, a small dedicated component for rendering course-detail Portable Text content, including our custom blocks:

#### `components/portable-text-renderer.tsx`

```tsx
import { PortableText, type PortableTextComponents } from "@portabletext/react";
import type { PortableTextBlock } from "sanity";
import { urlForImage } from "@/sanity/lib/image";
import { Alert } from "@/components/ui/alert";
import Image from "next/image";

// PortableTextComponents is a lookup table telling @portabletext/react
// how to render each possible block/mark TYPE it encounters. Anything not
// listed here falls back to the library's sensible defaults (e.g. plain
// paragraphs and standard bold/italic marks render automatically without
// us specifying anything).
const components: PortableTextComponents = {
  types: {
    // Handles inline IMAGE blocks (see lesson.ts's Portable Text "of" array)
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
    // Handles our custom calloutBlock object type from Part 3
    calloutBlock: ({ value }) => {
      const variant =
        value.tone === "warning" ? "warning" : value.tone === "tip" ? "success" : "info";
      return (
        <Alert variant={variant} className="my-6">
          {value.text}
        </Alert>
      );
    },

    // quizBlock and codeExerciseBlock are rendered here ONLY as a
    // read-only preview placeholder — the real, interactive, gradeable
    // version is built by the module registry in Part 10 and only shown
    // inside the authenticated lesson player (Part 9), never on this
    // public-facing detail page. This keeps quiz answers out of any page
    // an unauthenticated visitor could load.
    quizBlock: ({ value }) => (
      <div className="my-6 rounded-[var(--radius-panel)] border border-dashed border-border bg-surface-muted p-4">
        <p className="text-sm font-semibold text-text-primary">📝 Interactive quiz</p>
        <p className="mt-1 text-sm text-text-secondary">{value.question}</p>
        <p className="mt-2 text-xs text-text-muted">
          Available inside the lesson player after enrolling.
        </p>
      </div>
    ),
    codeExerciseBlock: ({ value }) => (
      <div className="my-6 rounded-[var(--radius-panel)] border border-dashed border-border bg-surface-muted p-4">
        <p className="text-sm font-semibold text-text-primary">💻 Code exercise</p>
        <p className="mt-1 text-sm text-text-secondary">{value.prompt}</p>
        <p className="mt-2 text-xs text-text-muted">
          Available inside the lesson player after enrolling.
        </p>
      </div>
    ),
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

export function PortableTextRenderer({ value }: { value: PortableTextBlock[] }) {
  return <PortableText value={value} components={components} />;
}
```

**Code walkthrough:**

- Notice the `quizBlock` and `codeExerciseBlock` renderers here render `value.question` / `value.prompt` — but **never** `value.correctOptionIndex` or `value.expectedKeywords`. This is only safe because of a query-level decision we're about to make in the next file: we simply won't ask Sanity for those fields on this public page at all. Rendering logic alone is not a security boundary — the real protection happens one layer earlier, at the query.
- The `components.types` object handles custom block *types* (image, calloutBlock, quizBlock, codeExerciseBlock); `components.block` handles *styles* within the standard rich-text `block` type (h2, h3, blockquote, normal). This mirrors exactly the two-part structure we configured in Part 3's `lesson.ts` schema (`styles` and the array's other member types).
- We deliberately did **not** use `dangerouslySetInnerHTML` anywhere in this file. `@portabletext/react` walks the structured block array itself and produces real React elements — this is what makes Portable Text fundamentally safer to render than storing raw HTML strings, a point we'll expand on formally in Part 16's XSS discussion.

Now, the detail page itself, with a **public-safe** preview query that intentionally omits sensitive quiz/exercise fields:

#### `sanity/lib/queries.ts` (add this query and interface)

```ts
// (append to the existing file from Step 4)

export interface LessonPreviewContent extends LessonSummary {
  content: PortableTextBlock[];
}

// This query is used ONLY for the public course detail page's preview
// lesson. Note the projection inside quizBlock/codeExerciseBlock objects:
// we explicitly select "question"/"prompt" but OMIT "correctOptionIndex"
// and "expectedKeywords" — the public browser bundle for this page will
// never even receive those fields over the network, regardless of what
// our rendering component chooses to display.
export const previewLessonQuery = /* groq */ `
  *[_type == "lesson" && slug.current == $lessonSlug && isPreview == true][0]{
    _id,
    title,
    slug,
    order,
    isPreview,
    content[]{
      ...,
      _type == "quizBlock" => {
        _type,
        _key,
        moduleId,
        question
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

**Code walkthrough of the new query:**

- `content[]{ ..., _type == "quizBlock" => {...} }` — the `...` spreads every field of a block *by default*, and the `_type == "X" => {...}` syntax is GROQ's **conditional projection**: "but if this particular block's `_type` matches X, override the projection with this narrower field list instead." This is exactly how we exclude `correctOptionIndex` and `expectedKeywords` — every other block type (normal text, images, callouts) still gets the full `...` treatment, but these two specific types get a deliberately restricted view.
- This is the single most important query in this entire part from a security standpoint. Re-read it once more: **the correct answer to the quiz is never fetched by this query, full stop** — not hidden by CSS, not filtered client-side, simply never present in the JSON that leaves Sanity's servers for this request.

#### `app/courses/[courseSlug]/page.tsx`

```tsx
import { notFound } from "next/navigation";
import Link from "next/link";
import Image from "next/image";
import { client } from "@/sanity/lib/client";
import { urlForImage } from "@/sanity/lib/image";
import {
  courseDetailQuery,
  previewLessonQuery,
  type CourseDetail,
  type LessonPreviewContent,
} from "@/sanity/lib/queries";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { PortableTextRenderer } from "@/components/portable-text-renderer";

const difficultyLabels: Record<CourseDetail["difficulty"], string> = {
  beginner: "Beginner",
  intermediate: "Intermediate",
  advanced: "Advanced",
};

// In Next.js 16, dynamic route params are provided as a Promise — this is
// a deliberate change from earlier Next.js versions, made to better
// support streaming. We must "await" the params object before reading
// values off of it.
interface CourseDetailPageProps {
  params: Promise<{ courseSlug: string }>;
}

export default async function CourseDetailPage({ params }: CourseDetailPageProps) {
  const { courseSlug } = await params;

  const course = await client.fetch<CourseDetail | null>(courseDetailQuery, {
    slug: courseSlug, // matches the $slug parameter inside courseDetailQuery
  });

  // notFound() is a special Next.js function: calling it immediately halts
  // rendering and instructs Next.js to render the nearest not-found.tsx
  // boundary (built in Step 7), returning a real HTTP 404 status code —
  // NOT a 200 response with a "not found" message printed on the page,
  // which would be incorrect and bad for SEO.
  if (!course) {
    notFound();
  }

  // Find the first preview-eligible lesson, if any, across all chapters —
  // this is what the "Preview a lesson" section below will render.
  const previewLessonSummary = course.chapters
    .flatMap((chapter) => chapter.lessons)
    .find((lesson) => lesson.isPreview);

  const previewLesson = previewLessonSummary
    ? await client.fetch<LessonPreviewContent | null>(previewLessonQuery, {
        lessonSlug: previewLessonSummary.slug.current,
      })
    : null;

  return (
    <main className="mx-auto flex max-w-4xl flex-col gap-10 px-6 py-16">
      <div className="flex flex-col gap-4">
        <div className="flex items-center gap-2">
          <Badge variant="brand">{difficultyLabels[course.difficulty]}</Badge>
          <Badge variant="neutral">{course.category.title}</Badge>
        </div>
        <h1 className="text-4xl font-bold text-text-primary">{course.title}</h1>
        <p className="text-lg text-text-secondary">{course.description}</p>
        <p className="text-sm text-text-muted">Taught by {course.instructor.name}</p>

        <div className="relative aspect-video w-full overflow-hidden rounded-[var(--radius-panel)]">
          <Image
            src={urlForImage(course.thumbnail).width(1000).height(560).url()}
            alt={course.title}
            fill
            className="object-cover"
          />
        </div>

        {/* This button is inert for now — real enrollment logic arrives in Part 8 */}
        <Button variant="primary" size="lg" className="w-fit">
          Enroll — Free
        </Button>
      </div>

      {course.learningObjectives.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle>What you'll learn</CardTitle>
          </CardHeader>
          <CardContent>
            <ul className="flex flex-col gap-2">
              {course.learningObjectives.map((objective) => (
                <li key={objective} className="flex items-start gap-2 text-sm text-text-secondary">
                  <span className="mt-0.5 text-success">✓</span>
                  {objective}
                </li>
              ))}
            </ul>
          </CardContent>
        </Card>
      )}

      <div className="flex flex-col gap-4">
        <h2 className="text-2xl font-semibold text-text-primary">Course content</h2>
        {course.chapters.map((chapter) => (
          <Card key={chapter._id}>
            <CardHeader>
              <CardTitle>{chapter.title}</CardTitle>
            </CardHeader>
            <CardContent>
              <ul className="flex flex-col divide-y divide-border">
                {chapter.lessons.map((lesson) => (
                  <li key={lesson._id} className="flex items-center justify-between py-2 text-sm">
                    <span className="text-text-primary">{lesson.title}</span>
                    {lesson.isPreview && <Badge variant="success">Free preview</Badge>}
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>
        ))}
      </div>

      {previewLesson && (
        <div className="flex flex-col gap-4 border-t border-border pt-10">
          <div className="flex items-center gap-2">
            <h2 className="text-2xl font-semibold text-text-primary">Preview: {previewLesson.title}</h2>
            <Badge variant="success">Free</Badge>
          </div>
          <PortableTextRenderer value={previewLesson.content} />
          <Link href="/courses" className="text-sm text-brand hover:underline">
            ← Back to catalog
          </Link>
        </div>
      )}
    </main>
  );
}
```

**Code walkthrough:**

- `params: Promise<{ courseSlug: string }>` and `await params` — this reflects a real Next.js 16 API detail worth understanding, not just following blindly: route parameters are delivered asynchronously so Next.js can begin streaming a page's shell before every dynamic value is necessarily resolved. Forgetting the `await` here is a common upgrade mistake for anyone coming from an older Next.js tutorial — TypeScript will actually catch it for you, since `params.courseSlug` on an un-awaited `Promise` simply doesn't exist as a property, producing a compile error rather than a silent runtime bug.
- `notFound()` deliberately throws internally (it doesn't `return`) — this is why nothing after the `if (!course)` block needs an `else`; execution simply never reaches further once `notFound()` is called. We'll build the actual `not-found.tsx` boundary it renders into in the next step.
- The second `client.fetch` call for `previewLessonQuery` only runs `if (previewLessonSummary)` exists — this avoids an unnecessary network request when a course happens to have no preview-eligible lesson at all, a small but real performance consideration worth noticing as a pattern: don't fetch what you don't need, checked directly in application code, not just in the query itself.
- Look closely at what's rendered in the "Course content" outline: only `chapter.title` and `lesson.title`/`isPreview` — no lesson content, no video URLs, nothing beyond a table-of-contents view. This matches `courseDetailQuery`'s projection exactly (Step 4) — the outline is intentionally a *summary*, with full lesson content reserved for the authenticated lesson player we build in Part 9.

### The Verification

With the dev server running, visit `http://localhost:3000/courses/introduction-to-databases` (adjust the slug if you titled your sample course differently in Part 3). Confirm:

1. The hero section shows the correct title, description, badges, instructor name, and thumbnail image.
2. A "What you'll learn" card lists your learning objectives with checkmarks.
3. A "Course content" section shows one chapter card ("Getting Started") containing both lessons, with "Writing Your First Query" showing no badge and "What is a Database?" showing a green "Free preview" badge.
4. A "Preview: What is a Database?" section at the bottom renders your paragraph text and the callout block styled as a success-colored alert box.
5. Open DevTools → Network tab, find the request to Sanity's API for `previewLessonQuery`, and inspect its response body — confirm it contains no `correctOptionIndex` or `expectedKeywords` field anywhere (this course's preview lesson doesn't even contain a quiz block, so to fully test this, temporarily mark "Writing Your First Query" — the lesson *with* the quiz block — as `isPreview: true` in Studio, republish, refresh the page, and re-inspect the network response to directly confirm the correct answer index is genuinely absent from the payload).

Once confirmed, if you toggled the second lesson's preview flag for testing, remember to set `isPreview` back to `false` and republish, since Part 8 onward assumes only the first lesson is a free preview.

---

## Step 7 — Handling missing content: not-found and error boundaries

### The Target
`app/courses/[courseSlug]/not-found.tsx` — a friendly 404 page shown when `notFound()` is called — and `app/courses/[courseSlug]/error.tsx`, a boundary catching unexpected runtime errors (e.g., a temporary Sanity API outage) separately from "this course genuinely doesn't exist."

### The Concept
These are two *different* failure modes, and conflating them is a common mistake: a **404** means "we successfully asked the question and the honest answer is 'no such course exists'" — like asking a librarian for a book and being told it's not in the catalog. An **error** means "we couldn't even finish asking the question" — like the library's computer system crashing mid-search. Users (and search engines) need to be able to tell these apart: a 404 is a normal, permanent, cacheable outcome; an error is transient and should probably prompt a retry.

### The Implementation

#### `app/courses/[courseSlug]/not-found.tsx`

```tsx
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";

export default function CourseNotFound() {
  return (
    <main className="mx-auto flex max-w-2xl flex-col items-center px-6 py-24">
      <EmptyState
        title="Course not found"
        description="This course may have been unpublished or the link may be incorrect."
        action={
          <Link href="/courses">
            <Button variant="primary">Browse all courses</Button>
          </Link>
        }
      />
    </main>
  );
}
```

#### `app/courses/[courseSlug]/error.tsx`

```tsx
"use client"; // Next.js error boundaries MUST be Client Components — they
// need to catch errors thrown during rendering, which relies on React's
// error boundary mechanism, a client-side-only React feature.

import { useEffect } from "react";
import { Button } from "@/components/ui/button";
import { Alert } from "@/components/ui/alert";

export default function CourseDetailError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    // In a real production setup, this is where we'd forward the error to
    // a logging/monitoring service (Part 16 covers observability). For
    // now, logging to the console is sufficient for local debugging.
    console.error("Course detail page error:", error);
  }, [error]);

  return (
    <main className="mx-auto flex max-w-2xl flex-col gap-4 px-6 py-24">
      <Alert variant="danger" title="Something went wrong">
        We couldn't load this course right now. This is usually temporary.
      </Alert>
      <Button variant="primary" onClick={reset} className="w-fit">
        Try again
      </Button>
    </main>
  );
}
```

**Code walkthrough:**

- `error.tsx`'s `reset` function, when called, tells Next.js to attempt re-rendering the segment that failed — it does not reload the whole page, just retries the specific boundary, which is a much smoother recovery experience than a full browser refresh.
- We deliberately never show `error.message` or `error.stack` directly to the user in the rendered UI — only to `console.error` for our own debugging. This is the "safe error messages" principle previewed in Part 0 and formalized fully in Part 16: internal error details (stack traces, database errors) should never leak to end users, since they can reveal implementation details useful to an attacker.
- Notice `not-found.tsx` has no `"use client"` directive (it's a plain Server Component, since it has no interactivity of its own) while `error.tsx` requires one (React error boundaries are inherently a client-side mechanism) — a good concrete example reinforcing Part 1's Server/Client distinction.

### The Verification

Visit a deliberately nonexistent slug: `http://localhost:3000/courses/this-course-does-not-exist`. Confirm the friendly "Course not found" empty state renders, and check your terminal running `npm run dev` — you should **not** see any error logged, since this is a normal, expected `notFound()` outcome, not a thrown error.

To test the error boundary, temporarily introduce a deliberate bug — e.g., inside `app/courses/[courseSlug]/page.tsx`, add `throw new Error("test error boundary")` as the very first line inside the component function — save, reload the course detail page, and confirm the red "Something went wrong" alert renders instead of a raw Next.js stack-trace error screen, with a working "Try again" button. **Remove the deliberate `throw` line immediately after confirming this** — it was only a test.

---

## Step 8 — Cache behavior and revalidating published content

### The Target
Understanding and configuring how long Next.js caches the data fetched via `client.fetch()`, so that publishing a change in Sanity Studio actually shows up on the live site within a reasonable time.

### The Concept
By default, Next.js Server Components aggressively cache fetched data to keep pages fast — this is usually desirable, but it creates a real problem for a CMS-backed site: if we cache forever, publishing an edit in Studio might never appear on the live page without a full redeploy. We need a middle ground: **time-based revalidation**, where Next.js treats cached data as "good enough" for a fixed window (say, 60 seconds), then transparently refetches in the background after that window passes. This is a common, pragmatic tradeoff — the same one described back in Part 3, Step 3 when we chose `useCdn: true`.

### The Implementation

Update the Sanity client to specify a revalidation window using Next.js's fetch caching options, which `next-sanity`'s client respects:

#### `sanity/lib/client.ts` (updated)

```ts
import { createClient } from "next-sanity";
import { apiVersion, dataset, projectId } from "@/sanity/env";

export const client = createClient({
  projectId,
  dataset,
  apiVersion,
  useCdn: true,
  // Every query made with this client is tagged with Next.js's fetch
  // cache, set here to revalidate every 60 seconds. This means: serve
  // cached results instantly for up to 60 seconds, then transparently
  // refetch on the NEXT request after that window — visitors never wait
  // for the refetch themselves, they simply eventually see fresh data.
  stega: {
    enabled: false, // visual editing overlays — disabled; out of scope for this series
  },
});

// A separate, explicit fetch options object we'll pass alongside specific
// queries where we want tighter control than the client-level default.
export const defaultFetchOptions = {
  next: { revalidate: 60 },
};
```

Now apply `defaultFetchOptions` to both existing queries — update the two `client.fetch` calls we've already written:

#### `app/courses/page.tsx` (update the fetch call only)

```tsx
const courses = await client.fetch<CourseCard[]>(
  courseCatalogQuery,
  {},
  defaultFetchOptions
);
```

Remember to add the import:

```tsx
import { client, defaultFetchOptions } from "@/sanity/lib/client";
```

#### `app/courses/[courseSlug]/page.tsx` (update both fetch calls)

```tsx
const course = await client.fetch<CourseDetail | null>(
  courseDetailQuery,
  { slug: courseSlug },
  defaultFetchOptions
);

// ...

const previewLesson = previewLessonSummary
  ? await client.fetch<LessonPreviewContent | null>(
      previewLessonQuery,
      { lessonSlug: previewLessonSummary.slug.current },
      defaultFetchOptions
    )
  : null;
```

And update the import here too:

```tsx
import { client, defaultFetchOptions } from "@/sanity/lib/client";
```

**Code walkthrough:**

- `client.fetch(query, params, options)` — the third argument is where Next.js-specific fetch options (like `next: { revalidate: 60 }`) get passed through; `next-sanity`'s client is specifically built to forward these to the underlying `fetch()` call so Next.js's caching layer can see and respect them.
- A 60-second revalidation window is a reasonable default for course content: content edits aren't usually time-critical to the second, and this keeps Sanity's API load low while still feeling "live" within about a minute of publishing. If a future part ever needs instant updates (e.g., an admin action that should reflect immediately), we'll use Next.js's on-demand revalidation APIs instead — worth knowing that option exists, even though we won't need it until much later in the series.

### The Verification

With the dev server running, visit `/courses`, then go into Studio and edit the sample course's description slightly (add a sentence), and publish. Immediately refresh `/courses` — you likely Immediately refresh `/courses` — you likely **won't** see the change yet, since the previous fetch is still within its 60-second cache window. Wait roughly a minute, refresh again, and confirm the updated description now appears. This confirms revalidation is working as designed: not instant, but bounded and predictable.

Run the full verification suite to confirm the whole part compiles cleanly:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Step 9 — The important correctness rule: scoping lessons through their parent course

### The Target
No new files in this step — instead, we formalize and stress-test a rule already implicit in our query design: **a lesson must never be fetchable by its slug alone.** Every lesson lookup must prove, at the database-query level, that the lesson actually belongs to the course the URL claims it belongs to.

### The Concept
Imagine a hotel where room numbers are unique hotel-wide, but guests are only supposed to access rooms on their booked floor. If the key-card system only checks "is this a valid room number" — and never "does this room actually belong to this guest's floor" — a guest could type in *any* valid room number from *any* floor and get in. The fix isn't to make room numbers secret; it's to make the access check itself verify the room-to-floor relationship every single time, not just the room's bare existence.

This matters concretely once Part 9 builds `/dashboard/courses/[courseSlug]/lessons/[lessonSlug]`: a malicious (or simply curious) user could try swapping the URL's `lessonSlug` for a *real* lesson slug that belongs to a *completely different* course, while keeping the `courseSlug` in the URL unchanged. If our query only checked "does a lesson with this slug exist," it would happily return that other course's lesson content — a real content-leak bug, not a hypothetical one.

### The Implementation

We already built this correctly, somewhat invisibly, back in `courseDetailQuery` (Step 4) — chapters and lessons are only ever reached by *following references down from a specific course document*, never queried independently by lesson slug alone. But it's worth making the rule explicit and testable, since Part 9's lesson player will need a dedicated "fetch one full lesson" query, and it's critical that query is written the same safe way from day one.

Add this query now, in preparation for Part 9, demonstrating the correct pattern:

#### `sanity/lib/queries.ts` (append)

```ts
export interface LessonFull extends LessonSummary {
  videoUrl: string | null;
  content: PortableTextBlock[];
}

// THE CORRECT PATTERN: notice this query filters on BOTH the course's slug
// AND the lesson's slug, joined through the actual chapters/lessons
// reference chain — not on the lesson's slug in isolation. If a lesson
// slug is swapped in the URL for one belonging to a DIFFERENT course, this
// query correctly returns null, because the reference chain from THIS
// course never reaches that lesson.
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
    content
  }
`;
```

**Code walkthrough — read this one carefully, it's the crux of the rule:**

- The query starts by resolving the **course** (`_type == "course" && slug.current == $courseSlug`) — exactly as before.
- `.chapters[]->.lessons[]->` walks *down from that specific course document* — through its chapters, into their lessons — dereferencing at each level. This is fundamentally different from a query like `*[_type == "lesson" && slug.current == $lessonSlug][0]`, which would search *every lesson in the entire dataset* by slug, with zero regard for which course it's supposed to belong to.
- `[slug.current == $lessonSlug][0]` then filters *that specific course's* already-resolved lesson list down to the one matching slug. If the requested lesson slug doesn't appear anywhere in *this course's* chapter/lesson chain — because it actually belongs to some other course entirely — this filter matches nothing, and the query correctly returns `null`.

**A concrete way to prove this to yourself right now**, using Vision (`http://localhost:3000/studio/vision`): run the query above with `$courseSlug` set to your real course's slug and `$lessonSlug` set to a lesson slug from a *different, unrelated* course (create a throwaway second course with one throwaway lesson if you'd like a true test case). Confirm the result is `null` — not an error, not the wrong lesson's content, simply nothing, exactly as correct behavior demands.

### The Verification

Run the mismatched-slug test described above in Vision and confirm a `null` result. Then run it again with matching, correct `$courseSlug`/`$lessonSlug` pairs from your real sample course and confirm the full lesson content (including the quiz block, if applicable — note this query, unlike `previewLessonQuery`, is intentionally *not yet* restricted from returning `correctOptionIndex`; that restriction is only meaningful once we also add authentication and enrollment checks in Parts 6–8, so we defer finalizing this query's field-level restrictions to Part 9, where it's actually put to use behind an authenticated route).

```bash
npx tsc --noEmit
```

Should complete without errors.

---

## Common mistakes

- **`urlForImage(...).url()` throws or returns `undefined`** — Usually means the `thumbnail`/`image` field wasn't actually selected in the GROQ projection (e.g., writing `thumbnail { asset }` incorrectly, or omitting `thumbnail` from the query entirely). Confirm the query's projection includes the full image field, not a partial one.
- **`next/image` throws "hostname not configured"** — Means `next.config.ts`'s `remotePatterns` wasn't added, or the dev server wasn't restarted after adding it. Config file changes always require a full restart, not just a save.
- **Course detail page 404s even though the course is published** — Double-check the URL slug exactly matches the Sanity `slug.current` value (case-sensitive), and confirm `isPublished` is checked *and* the document was Published, not left as an unpublished draft.
- **Preview lesson section never appears on the detail page** — Confirm at least one lesson within the course has `isPreview` set to `true` in Studio, and that lesson was published.
- **TypeScript complains `course` is possibly `null` after the `notFound()` check** — This usually means TypeScript's control-flow narrowing didn't apply because `notFound()`'s return type isn't recognized as "never returns." Confirm you're calling `notFound()` as a bare statement (`notFound();`) rather than inside a ternary or wrapped expression, and that you're on a `next` package version whose type definitions correctly mark `notFound()` as returning `never`.
- **Revalidation never seems to update content, even after minutes** — Confirm `defaultFetchOptions` (with `next: { revalidate: 60 }`) is actually being passed as the third argument to *every* `client.fetch()` call — it's easy to add it to one query and forget another.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `sanity/lib/image.ts`, `sanity/lib/queries.ts`, `sanity/lib/client.ts` (modified), `components/portable-text-renderer.tsx`, `app/courses/page.tsx`, `app/courses/loading.tsx`, `app/courses/[courseSlug]/page.tsx`, `app/courses/[courseSlug]/not-found.tsx`, `app/courses/[courseSlug]/error.tsx`, and `next.config.ts` (modified).

```bash
git commit -m "Part 4: public course catalog and detail pages — GROQ queries, typed results, Portable Text rendering, 404/error boundaries, course-scoped lesson query"
```

---

## Reference: GROQ syntax cheat sheet

| Syntax | Meaning |
|---|---|
| `*` | Every document in the dataset |
| `[_type == "course"]` | Filter by field equality |
| `{ title, slug }` | Projection — select specific fields only |
| `->` | Dereference a reference (follow the pointer) |
| `[]` after a field | "For every item in this array" |
| `[0]` | Take the first result (turns an array result into a single object) |
| `| order(field asc)` | Sort results by a field |
| `$paramName` | A safely-injected query parameter (never string-concatenate user input directly into a query) |
| `_type == "X" => {...}` | Conditional projection — apply a different field selection depending on a block's type |
| `...` | Spread every field of the current object into the projection |

## Reference: Server Component data-fetching cheat sheet

| Concept | What it means |
|---|---|
| `async function Page()` | Server Components can be `async` directly — no `useEffect` needed |
| `loading.tsx` | Automatic `<Suspense>` fallback shown while the page's data fetch is in flight |
| `not-found.tsx` + `notFound()` | Correct way to render a real 404 for "valid request, no such resource" |
| `error.tsx` (Client Component) | Catches unexpected thrown errors; must be a Client Component; never show raw error details to users |
| `next: { revalidate: N }` | Time-based cache revalidation — serve cached data for N seconds, then refetch in the background |

---

## What's next

Part 5 leaves Sanity behind for now and turns to the other half of GreyMatter's hybrid architecture: creating a real Neon PostgreSQL project, installing Drizzle ORM, designing and migrating the full transactional schema (users, enrollments, lesson progress, module attempts, certificates, and more), and seeding development data — laying the foundation every authentication, enrollment, and progress-tracking feature from Part 6 onward will depend on.
