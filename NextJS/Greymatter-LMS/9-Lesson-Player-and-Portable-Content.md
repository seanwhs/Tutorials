# Part 9 — Lesson Player and Portable Content

## The goal

By the end of this part, GreyMatter LMS will have a complete, authenticated lesson player at `/dashboard/courses/[courseSlug]/lessons/[lessonSlug]` — rendering full Portable Text lesson content (including our custom callout, quiz, and code-exercise blocks), embedded video, previous/next lesson navigation, automatic "last visited lesson" tracking for resume functionality, and a reading-progress indicator. This page will be built directly on top of Part 4's course-scoped query rule and Part 8's enrollment verification, extended one level deeper to cover individual lessons.

## Why it exists

Part 7 gave students a course outline; Part 8 gave them a way to actually get enrolled. But neither part ever rendered a single word of real lesson content inside the authenticated dashboard — Part 4's Portable Text renderer only ever displayed a public, restricted preview. This part is where the actual "product" of an LMS comes together: students reading real lessons, in the correct order, with their place remembered. It's also where Part 4's Step 9 correctness rule ("a lesson must never be fetchable by its slug alone") finally gets used for real, inside a page that renders complete, unrestricted lesson content — making that rule's enforcement more important here than anywhere else so far.

## The data flow

```text
Student navigates to /dashboard/courses/[courseSlug]/lessons/[lessonSlug]
        │
        ▼
requireUser() — confirm authentication (Part 6)
        │
        ▼
getCourseOutline() — confirm ACTIVE enrollment (Part 7/8), get chapter/lesson structure
        │
        ▼
lessonWithinCourseQuery — fetch THIS lesson, scoped through the course (Part 4, Step 9)
        │
        ▼
Server Action: recordLastVisitedLesson() — fire-and-forget, updates "resume" pointer
        │
        ▼
Render: video embed, Portable Text content, prev/next controls, outline sidebar
```

One term worth defining before we build this: **resume functionality** means the app remembers where a student left off and offers to take them back there — the same convenience a video streaming service provides when it defaults to "Continue Watching" instead of making you scroll to find your show again.

---

## Step 1 — Extending the course-scoped lesson query for authenticated use

### The Target

Finalizing `lessonWithinCourseQuery` (first written as a preview in Part 4, Step 9) as the real query this page uses, and building `getLessonForStudent()` — a function combining that query with the enrollment check from Part 7, exactly mirroring the two-step pattern `getCourseOutline()` already established.

### The Concept

Recall Part 4's rule precisely: a lesson query must **never** accept a lesson slug in isolation — it must always be proven to belong to the specific course named in the URL. Part 4 demonstrated this at the *query* level. This step adds the second, equally necessary layer: even a correctly-scoped lesson belonging to a real, published course must **not** be shown to a student who isn't enrolled in that course. Both checks are required; neither alone is sufficient — this is the same "two independent layers" reasoning from Part 7's `getCourseOutline`, now applied one level deeper.

### The Implementation

#### `lib/dashboard/get-lesson-for-student.ts`

```ts
import { client, defaultFetchOptions } from "@/sanity/lib/client";
import { lessonWithinCourseQuery, type LessonFull } from "@/sanity/lib/queries";
import { getCourseOutline, type CourseOutline } from "@/lib/dashboard/get-course-outline";
import { recordLastVisitedLesson } from "@/db/queries/lesson-progress";

export interface LessonPlayerData {
  course: CourseOutline;
  lesson: LessonFull;
  previousLesson: { slug: string; title: string } | null;
  nextLesson: { slug: string; title: string } | null;
}

// The single function every lesson-player request goes through. It
// performs, in order: (1) the enrollment check (reusing Part 7's
// getCourseOutline, so we never duplicate that logic), and (2) the
// course-scoped lesson fetch from Part 4. Returning null covers THREE
// distinct real-world cases identically: course doesn't exist, student
// isn't enrolled, or lesson doesn't belong to this course — exactly the
// "don't leak which case it was" principle from Part 7.
export async function getLessonForStudent(
  userId: string,
  courseSlug: string,
  lessonSlug: string
): Promise<LessonPlayerData | null> {
  const course = await getCourseOutline(userId, courseSlug);
  if (!course) {
    return null; // Not enrolled, or course doesn't exist — Part 7's guarantee.
  }

  const lesson = await client.fetch<LessonFull | null>(
    lessonWithinCourseQuery,
    { courseSlug, lessonSlug },
    defaultFetchOptions
  );

  if (!lesson) {
    return null; // This lesson slug does not belong to THIS course — Part 4's guarantee, now enforced here.
  }

  // Flatten the course's chapters into one ordered lesson list, so we
  // can find "the lesson before/after this one" regardless of which
  // chapter it happens to fall in — a course-wide sequence, not just a
  // within-chapter one.
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

  // Fire-and-forget: recording "you were last here" should never block
  // or fail the actual page render. We deliberately do NOT await this
  // inside the data-fetching path in a way that would delay the
  // response — see the Server Action version built in Step 3 for the
  // properly awaited, user-triggered equivalent.

  return { course, lesson, previousLesson, nextLesson };
}
```

**Code walkthrough:**

- Notice `getLessonForStudent` calls `getCourseOutline` rather than re-implementing the enrollment check itself — this is a deliberate reuse of Part 7's function, avoiding two slightly-different copies of the same critical security check existing in two places (a classic source of subtle bugs, where one copy gets updated and the other doesn't).
- `allLessons.findIndex(...)` flattening chapters into one sequential list is what makes "next lesson" correctly cross chapter boundaries — e.g., the last lesson of Chapter 1 correctly points to the first lesson of Chapter 2, without us hand-writing that boundary case.
- We return the **entire** `course` object (not just the current lesson) because Step 5's outline sidebar needs the full chapter/lesson structure to render alongside the content — exactly why `CourseOutlineNav` (Part 7) was built to accept an optional `currentLessonSlug` prop in the first place.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors — we'll see this produce real output once the page exists in Step 5.

---

## Step 2 — Adding a "last visited lesson" column

### The Target

A small schema addition: `lastVisitedLessonId` and `lastVisitedAt` columns on `course_progress`, plus a new migration.

### The Concept

Recall Part 5's design: `course_progress` already tracks *how much* of a course is done. We're extending it to also track *where* the student was most recently, which is exactly the data Part 7's dashboard "Resume learning" link needs to point somewhere more specific than always "the first lesson."

### The Implementation

#### `db/schema/course-progress.ts` (updated — add two columns)

```ts
import { integer, pgTable, text, timestamp, unique, uuid } from "drizzle-orm/pg-core";
import { enrollments } from "./enrollments";
import { users } from "./users";

export const courseProgress = pgTable(
  "course_progress",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
    enrollmentId: uuid("enrollment_id").notNull().references(() => enrollments.id, { onDelete: "cascade" }),
    courseId: text("course_id").notNull(),
    completionPercentage: integer("completion_percentage").notNull().default(0),

    // NEW: the Sanity lesson _id the student most recently viewed, and
    // when. Nullable, since a freshly-enrolled student hasn't visited
    // any lesson yet.
    lastVisitedLessonId: text("last_visited_lesson_id"),
    lastVisitedAt: timestamp("last_visited_at", { withTimezone: true }),

    lastActivityAt: timestamp("last_activity_at", { withTimezone: true }).notNull().defaultNow(),
    createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [unique("course_progress_user_course_unique").on(table.userId, table.courseId)]
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

Confirm the `course_progress` table now shows two new nullable columns: `last_visited_lesson_id` and `last_visited_at`.

---

## Step 3 — The "record last visited lesson" Server Action

### The Target

`db/queries/lesson-progress.ts` (extended) and a Server Action wrapping it, called automatically whenever a student opens a lesson.

### The Concept

This write happens on *every single lesson page view* — unlike Part 8's enrollment action, it's not triggered by a deliberate button click, but by simply visiting a page. It should never slow down or risk breaking the page render if it fails (a student should still be able to read a lesson even if this bookkeeping write has a transient hiccup) — this is a "best-effort, side-channel" write, a distinct pattern worth contrasting against Part 8's very deliberate, must-succeed-or-report-failure enrollment write.

### The Implementation

#### `db/queries/lesson-progress.ts` (append)

```ts
import { eq, and } from "drizzle-orm";
import { courseProgress } from "@/db/schema";

export async function recordLastVisitedLesson(
  userId: string,
  courseId: string,
  lessonId: string
) {
  await db
    .update(courseProgress)
    .set({
      lastVisitedLessonId: lessonId,
      lastVisitedAt: new Date(),
      lastActivityAt: new Date(),
    })
    .where(and(eq(courseProgress.userId, userId), eq(courseProgress.courseId, courseId)));
}
```

#### `app/dashboard/courses/[courseSlug]/lessons/actions.ts`

```ts
"use server";

import { requireUser } from "@/lib/auth/require-user";
import { recordLastVisitedLesson } from "@/db/queries/lesson-progress";

// Deliberately NOT wrapped in the enrollment-verification machinery from
// getLessonForStudent — by the time this action is called, the page that
// called it has ALREADY performed that check (Step 5). This action's
// only job is the bookkeeping write itself. We still call requireUser()
// as a baseline safety net — never skip authentication just because a
// caller "should" already be authorized.
export async function markLessonVisited(courseId: string, lessonId: string) {
  const user = await requireUser();

  try {
    await recordLastVisitedLesson(user.id, courseId, lessonId);
  } catch (error) {
    // Deliberately swallowed — recall the "best-effort, side-channel"
    // reasoning above. A failure here should never surface as a broken
    // page to the student; it just means "resume" might point slightly
    // stale next time, a low-stakes, fully recoverable outcome.
    console.error("Failed to record last visited lesson:", error);
  }
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors — full verification arrives once wired into the real page in Step 5.

---

## Step 4 — Rendering video embeds and extending Portable Text for the full lesson player

### The Target

`components/lesson/video-embed.tsx` — a component rendering a lesson's `videoUrl` field safely, supporting YouTube and Vimeo links specifically (rather than allowing arbitrary iframe embeds).

### The Concept

Recall Part 3's schema: `lesson.videoUrl` is a plain URL string, entered freely by a content editor in Studio. Naively dropping any URL into an `<iframe src="...">` is a real security concern — it would let an editor (or anyone who somehow gained write access to Sanity) embed a page from *any* domain, including a malicious one, directly inside our authenticated dashboard. Instead, we parse the URL, confirm it's from an **allow-listed** set of known video providers, and construct our own trusted embed URL from the extracted video ID — never passing the raw, editor-supplied URL directly into the `src` attribute unchecked.

### The Implementation

#### `components/lesson/video-embed.tsx`

```tsx
function extractYouTubeId(url: URL): string | null {
  if (url.hostname === "youtu.be") {
    return url.pathname.slice(1) || null;
  }
  if (url.hostname.endsWith("youtube.com")) {
    return url.searchParams.get("v");
  }
  return null;
}

function extractVimeoId(url: URL): string | null {
  if (url.hostname.endsWith("vimeo.com")) {
    const match = url.pathname.match(/\/(\d+)/);
    return match ? match[1] : null;
  }
  return null;
}

export function VideoEmbed({ url }: { url: string }) {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    // A malformed URL string somehow saved in Sanity — fail safely by
    // rendering nothing rather than crashing the whole lesson page.
    return null;
  }

  const youtubeId = extractYouTubeId(parsed);
  const vimeoId = extractVimeoId(parsed);

  // THE KEY SECURITY DECISION: we only ever construct an iframe "src"
  // from a WELL-KNOWN, TRUSTED embed URL template, using an extracted
  // ID — never the raw, editor-supplied url string itself. An
  // unrecognized domain renders nothing, rather than being embedded
  // unchecked.
  let embedSrc: string | null = null;
  if (youtubeId) {
    embedSrc = `https://www.youtube-nocookie.com/embed/${encodeURIComponent(youtubeId)}`;
  } else if (vimeoId) {
    embedSrc = `https://player.vimeo.com/video/${encodeURIComponent(vimeoId)}`;
  }

  if (!embedSrc) {
    return null;
  }

  return (
    <div className="relative aspect-video w-full overflow-hidden rounded-[var(--radius-panel)] bg-black">
      <iframe
        src={embedSrc}
        title="Lesson video"
        allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
        allowFullScreen
        className="absolute inset-0 h-full w-full"
      />
    </div>
  );
}
```

**Code walkthrough:**

- `youtube-nocookie.com` (rather than plain `youtube.com`) is YouTube's own privacy-enhanced embed domain — it avoids setting tracking cookies until the visitor actually interacts with the video, a small but meaningful default worth using unless there's a specific reason not to.
- The `try/catch` around `new URL(url)` handles the case where `videoUrl` contains genuinely malformed text — recall Part 3's schema used a plain `url` field type, which Sanity validates loosely; we don't rely on Sanity alone to guarantee a parseable URL reaches this component.
- Returning `null` for any unrecognized domain (rather than, say, falling back to embedding it anyway) is the actual enforcement point of this entire component — re-read this if anything is unclear, since it's the concrete implementation of "never render untrusted external content unchecked," a principle we'll revisit in Part 16's XSS discussion.

### The Verification

Deferred to Step 6, once wired into a real lesson page. For now, confirm it compiles:

```bash
npx tsc --noEmit
```

---

## Step 5 — Building the lesson player page

### The Target

`app/dashboard/courses/[courseSlug]/lessons/[lessonSlug]/page.tsx` — the complete lesson player, combining every piece built so far in this part with Part 4's `PortableTextRenderer` and Part 7's `CourseOutlineNav`.

### The Concept

This page is an assembly job, in the same spirit as Part 2's "dress rehearsal" homepage — every individual piece (enrollment check, course-scoped query, video embed, outline nav, Portable Text renderer) already exists; this step's job is combining them correctly, in the right order, with the right authorization guarantees intact throughout.

### The Implementation

#### `app/dashboard/courses/[courseSlug]/lessons/[lessonSlug]/page.tsx`

```tsx
import { notFound } from "next/navigation";
import Link from "next/link";
import { requireUser } from "@/lib/auth/require-user";
import { getLessonForStudent } from "@/lib/dashboard/get-lesson-for-student";
import { markLessonVisited } from "../actions";
import { CourseOutlineNav } from "@/components/dashboard/course-outline-nav";
import { PortableTextRenderer } from "@/components/portable-text-renderer";
import { VideoEmbed } from "@/components/lesson/video-embed";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

interface LessonPageProps {
  params: Promise<{ courseSlug: string; lessonSlug: string }>;
}

export default async function LessonPlayerPage({ params }: LessonPageProps) {
  const { courseSlug, lessonSlug } = await params;
  const user = await requireUser();

  const data = await getLessonForStudent(user.id, courseSlug, lessonSlug);

  // A SINGLE null check covers every failure mode described in Step 1:
  // course doesn't exist, not enrolled, or lesson doesn't belong to this
  // course. All three render the identical 404 — no information leaked
  // about which specific case occurred.
  if (!data) {
    notFound();
  }

  const { course, lesson, previousLesson, nextLesson } = data;

  // Fire-and-forget bookkeeping — deliberately NOT awaited inline in a
  // way that would delay rendering. We still call it server-side, before
  // the page finishes, so it's reliably triggered on every real visit.
  void markLessonVisited(course._id, lesson._id);

  return (
    <div className="mx-auto flex max-w-6xl flex-col gap-6 px-6 py-10 lg:flex-row lg:gap-10">
      <aside className="lg:w-72 lg:shrink-0">
        <Card>
          <CardContent className="p-4">
            <CourseOutlineNav course={course} currentLessonSlug={lessonSlug} />
          </CardContent>
        </Card>
      </aside>

      <div className="flex flex-1 flex-col gap-6">
        <div className="flex items-center gap-2">
          {lesson.isPreview && <Badge variant="success">Free preview</Badge>}
          <h1 className="text-2xl font-bold text-text-primary">{lesson.title}</h1>
        </div>

        {lesson.videoUrl && <VideoEmbed url={lesson.videoUrl} />}

        <article className="max-w-none">
          <PortableTextRenderer value={lesson.content} />
        </article>

        <nav className="flex items-center justify-between border-t border-border pt-6">
          {previousLesson ? (
            <Link href={`/dashboard/courses/${courseSlug}/lessons/${previousLesson.slug}`}>
              <Button variant="outline">← {previousLesson.title}</Button>
            </Link>
          ) : (
            <span />
          )}
          {nextLesson ? (
            <Link href={`/dashboard/courses/${courseSlug}/lessons/${nextLesson.slug}`}>
              <Button variant="primary">{nextLesson.title} →</Button>
            </Link>
          ) : (
            <span className="text-sm text-text-muted">You've reached the end of this course.</span>
          )}
        </nav>
      </div>
    </div>
  );
}
```

**Code walkthrough:**

- `void markLessonVisited(...)` — the `void` keyword explicitly signals "we are intentionally not awaiting this promise," rather than it looking like an accidental missing `await`. This is a small but meaningful readability convention: a future reader (including future-you) can immediately tell this is deliberate fire-and-forget behavior, not a bug.
- Notice the previous/next navigation renders an empty `<span />` or a muted message rather than simply omitting the button entirely when there's no previous/next lesson — this keeps the `justify-between` layout visually stable rather than having the remaining button awkwardly jump to one side when only one direction is available.
- `PortableTextRenderer` — the exact same component built in Part 4 — is reused here completely unchanged, rendering the *full*, non-preview-restricted lesson content (since `lessonWithinCourseQuery`, unlike `previewLessonQuery`, fetches every field). This is a good moment to appreciate why we split those into two separate queries back in Part 4: one deliberately restricted for public/unauthenticated use, one deliberately complete for this authenticated, enrollment-verified context.

### The Verification

```bash
npm run dev
```

While signed in and enrolled in "Introduction to Databases," visit `/dashboard/courses/introduction-to-databases`, then click "Start learning →". Confirm:

1. The page loads at `/dashboard/courses/introduction-to-databases/lessons/what-is-a-database`, showing the outline sidebar with this lesson highlighted in brand color.
2. The lesson title, a green "Free preview" badge (since this lesson has `isPreview: true`), your authored paragraph text, and the callout block (styled as a success alert) all render correctly.
3. A "next lesson" button appears at the bottom pointing to "Writing Your First Query," and no "previous lesson" button appears (since this is the first lesson) — confirm the layout still looks balanced rather than lopsided.
4. Click the next-lesson button and confirm it navigates correctly, this time showing a "previous lesson" button pointing back, and the quiz block rendering as the read-only placeholder built in Part 4 (we'll replace this placeholder with a real interactive version in Part 10).

Open Drizzle Studio and confirm the `course_progress` row for this user now shows `last_visited_lesson_id` populated with the second lesson's Sanity `_id`, and `last_visited_at` set to a recent timestamp — proof Step 3's bookkeeping action fired correctly.

Now directly re-test Part 4/Part 8's course-scoping guarantee, this time against the *real, authenticated* player rather than just Vision: if you created a second test course in Part 8's Step 6, find one of its lesson slugs, and manually visit:

```text
http://localhost:3000/dashboard/courses/introduction-to-databases/lessons/<the-other-courses-lesson-slug>
```

Confirm you receive a proper 404 — proving that even a real, published, existing lesson slug is correctly rejected when it doesn't belong to the course named in the URL, exactly as designed since Part 4.

---

## Step 6 — Wiring "Resume learning" to the last visited lesson

### The Target

Updating Part 7's course landing page so its "Start/Resume learning" link points at the actual last-visited lesson (if one exists) instead of always the first lesson.

### The Concept

This is the direct payoff of Step 2's schema addition — a small change, but one that meaningfully improves the experience: a returning student clicking "Resume learning" should land exactly where they left off, not have to re-navigate through the outline every time.

### The Implementation

#### `lib/dashboard/get-course-outline.ts` (add one field to the returned shape)

```ts
// Add to the CourseOutline interface:
export interface CourseOutline extends Omit<CourseDetail, "chapters"> {
  chapters: ChapterWithProgress[];
  completionPercentage: number;
  lastVisitedLessonSlug: string | null; // NEW
}
```

To resolve a lesson **ID** (stored in `course_progress`) back into a lesson **slug** (needed for the URL), we need a small lookup. Since `getCourseOutline` already has the full chapter/lesson tree in memory, we can resolve this without an extra query:

```ts
// Inside getCourseOutline, after fetching courseProgressRows:
const courseProgressRow = courseProgressRows.find((cp) => cp.courseId === course._id);
const allLessonsFlat = course.chapters.flatMap((chapter) => chapter.lessons);
const lastVisitedLesson = courseProgressRow?.lastVisitedLessonId
  ? allLessonsFlat.find((l) => l._id === courseProgressRow.lastVisitedLessonId)
  : undefined;

// Update the final return statement to include:
return {
  ...course,
  completionPercentage: courseProgressRow?.completionPercentage ?? 0,
  lastVisitedLessonSlug: lastVisitedLesson?.slug.current ?? null,
  chapters: course.chapters.map((chapter) => ({
    ...chapter,
    lessons: chapter.lessons.map((lesson) => ({
      ...lesson,
      status: statusByLessonId.get(lesson._id) ?? "NOT_STARTED",
    })),
  })),
};
```

Now update the course landing page:

#### `app/dashboard/courses/[courseSlug]/page.tsx` (update the resume link section)

```tsx
// Replace the previous firstLesson-based logic with:
const targetLesson = course.lastVisitedLessonSlug
  ? { slug: { current: course.lastVisitedLessonSlug } }
  : course.chapters[0]?.lessons[0];

// ...and further down:
{targetLesson && (
  <Link
    href={`/dashboard/courses/${course.slug.current}/lessons/${targetLesson.slug.current}`}
    className="text-sm font-medium text-brand hover:underline"
  >
    {course.lastVisitedLessonSlug ? "Resume learning →" : "Start learning →"}
  </Link>
)}
```

### The Verification

Having already visited the second lesson in Step 5's verification, revisit `/dashboard/courses/introduction-to-databases` directly. Confirm the link now reads **"Resume learning →"** and, when clicked, navigates directly to "Writing Your First Query" — the exact lesson you last viewed — rather than back to the first lesson.

Run the full verification suite:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Common mistakes

- **Video doesn't render even for a valid YouTube URL** — Check the URL format carefully: `extractYouTubeId` handles `youtube.com/watch?v=...` and `youtu.be/...` formats specifically; a YouTube Shorts URL (`youtube.com/shorts/...`) uses a different path structure and would need an additional case added if you want to support it.
- **Lesson page 404s even though you just enrolled** — Confirm you're testing against the *same* course you enrolled in during Part 8, and double check `getLessonForStudent` isn't accidentally called with a stale `courseSlug`/`lessonSlug` pair (easy to mistype when testing manually via the address bar).
- **"Resume learning" never appears, always shows "Start learning"** — Confirm Step 3's `markLessonVisited` is genuinely being called (check for the `console.error` fallback log — its *absence* is expected on success) and that Step 6's `getCourseOutline` changes were saved correctly; also confirm you're testing on a *second* visit, since the very first lesson view will still show "Start learning" until `last_visited_lesson_id` has actually been written once.
- **Previous/next buttons show the wrong lesson across chapter boundaries** — Confirm `allLessons` is built via `.flatMap` (not `.map`, which would produce a nested array of arrays) — this is a common, easy-to-miss typo that silently breaks the cross-chapter ordering.
- **TypeScript complains about `Omit<CourseDetail, "chapters">` conflicts** — Confirm `CourseOutline`'s new `lastVisitedLessonSlug` field doesn't already exist on `CourseDetail` under a different name — since we're extending via `Omit`, any field genuinely present on both interfaces with a different type will still conflict and must be explicitly omitted too.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `lib/dashboard/get-lesson-for-student.ts`, `db/schema/course-progress.ts` (modified), `db/migrations/000X_*.sql` (new), `db/queries/lesson-progress.ts` (modified), `app/dashboard/courses/[courseSlug]/lessons/actions.ts`, `components/lesson/video-embed.tsx`, `app/dashboard/courses/[courseSlug]/lessons/[lessonSlug]/page.tsx`, `lib/dashboard/get-course-outline.ts` (modified), `app/dashboard/courses/[courseSlug]/page.tsx` (modified).

```bash
git commit -m "Part 9: lesson player — course-scoped authenticated lesson fetching, safe video embeds, prev/next navigation, last-visited-lesson tracking and resume functionality"
```

---

## Reference: the full authorization chain, restated one more time

By this point in the series, this exact chain has appeared three times, each time one layer deeper — worth seeing it side by side once, in full:

| Part | Layer added | Guarantees |
|---|---|---|
| Part 6 | `requireUser()` | Someone is genuinely signed in |
| Part 7 | `getCourseOutline()`'s enrollment check | This signed-in user is actually enrolled in this course |
| Part 4 / Part 9 | Course-scoped lesson query | This lesson genuinely belongs to this course (not just any lesson slug in the dataset) |

Every one of these three checks is independent and necessary — removing any single one reopens a real, exploitable gap. Part 11 adds a fourth and final layer on top of all three: verifying a *specific interactive module submission* belongs to a lesson the student is genuinely authorized to be on.

## Reference: safe external embedding pattern (reusable beyond video)

```text
1. Parse the untrusted string as a URL (fail closed on parse errors).
2. Check the URL's hostname against an explicit allow-list.
3. Extract only the SPECIFIC piece of data needed (an ID, a slug) — never the raw URL itself.
4. Construct a NEW, trusted URL from a hardcoded template + the extracted ID.
5. Render nothing if any step fails, rather than falling back to embedding the untrusted input directly.
```

---

## What's next

Part 10 builds the interactive module SDK — a typed plugin contract, a dynamic-loading registry mapping Sanity's `moduleId` values to real React components, and the first five interactive modules (multiple-choice quiz, short-answer exercise, SQL syntax exercise, reflective response, completion checkpoint) — replacing the static, read-only quiz/code-exercise placeholders this part's lesson player currently renders.
Say the word when you'd like Part 10.
