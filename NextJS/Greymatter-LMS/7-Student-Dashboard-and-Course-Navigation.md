# Part 7 — The Student Dashboard and Course Navigation

## The goal

By the end of this part, GreyMatter LMS will have a real, permanent authenticated application shell: a responsive dashboard layout with a persistent sidebar, a mobile navigation drawer, a user menu, and a course list that shows only the courses the signed-in student is actually enrolled in. We'll build the routing skeleton for `/dashboard`, `/dashboard/courses/[courseSlug]`, `/dashboard/courses/[courseSlug]/lessons/[lessonSlug]`, `/dashboard/achievements`, and `/dashboard/settings`, along with loading skeletons and a proper empty state for students with no enrollments yet.

## Why it exists

Every part from here forward — enrollment (Part 8), the lesson player (Part 9), interactive modules (Part 10), certificates (Part 13) — lives *inside* this authenticated shell. If we build the shell haphazardly now, every one of those parts inherits an inconsistent layout, duplicated navigation code, or a sidebar that doesn't know how to highlight the current page. This part exists to build that shell once, correctly, exactly the way Part 2 built the design system once before any real screen used it.

## The data flow

```text
Signed-in request to any /dashboard/* route
        │
        ▼
app/dashboard/layout.tsx (Server Component)
        │
        ├── requireUser() — confirms authentication (Part 6)
        ├── Query Neon for this user's enrollments, joined with Sanity course titles
        └── Renders persistent sidebar + mobile nav + user menu
        │
        ▼
The specific page (app/dashboard/page.tsx, or a nested route) renders inside the shell
```

One term worth defining before we start: a **layout** in Next.js's App Router is a special file (`layout.tsx`) that wraps every page inside its own folder *and every nested folder beneath it*, persisting across navigations between those pages rather than re-rendering from scratch. Think of it like a picture frame around a rotating gallery display — the frame (sidebar, header) stays put while the picture inside it (the actual page content) changes as you navigate.

---

## Step 1 — Fetching enrolled courses across two databases

### The Target
`lib/dashboard/get-enrolled-courses.ts` — a function that reads a student's enrollments from Neon, then fetches the matching course titles/slugs/thumbnails from Sanity, and merges the two into one clean list.

### The Concept
This is the first place in the series where we genuinely need data from **both halves** of our hybrid architecture in a single screen: Neon knows *which* Sanity course IDs a student is enrolled in, but Neon has no idea what those courses are actually called — it only stores an opaque string ID (recall Part 5's design decision). Sanity, meanwhile, has no concept of "enrollment" at all. We bridge them here, in application code, exactly the way Part 0 predicted we would.

### The Implementation

First, a small query helper for reading enrollments from Neon:

#### `db/queries/enrollments.ts`

```ts
import { eq } from "drizzle-orm";
import { db } from "@/db/client";
import { enrollments, courseProgress } from "@/db/schema";

// Returns every ACTIVE enrollment for a user, joined with that
// enrollment's course_progress row (added via Drizzle's relational
// query API — see the schema relations note below).
export async function findActiveEnrollmentsForUser(userId: string) {
  return db.query.enrollments.findMany({
    where: eq(enrollments.userId, userId),
  });
}

export async function findCourseProgressForUser(userId: string) {
  return db.query.courseProgress.findMany({
    where: eq(courseProgress.userId, userId),
  });
}
```

Now, the function that merges Neon's enrollment data with Sanity's course content:

#### `sanity/lib/queries.ts` (append)

```ts
export interface CourseTitleLookup {
  _id: string;
  title: string;
  slug: SanitySlug;
  thumbnail: SanityImageRef;
  difficulty: "beginner" | "intermediate" | "advanced";
}

// $ids is an ARRAY parameter — GROQ's "in" operator checks membership
// against it directly, letting us fetch every enrolled course's title in
// ONE round trip rather than one request per course.
export const coursesByIdsQuery = /* groq */ `
  *[_type == "course" && _id in $ids]{
    _id,
    title,
    slug,
    thumbnail,
    difficulty
  }
`;
```

#### `lib/dashboard/get-enrolled-courses.ts`

```ts
import { client } from "@/sanity/lib/client";
import { coursesByIdsQuery, type CourseTitleLookup } from "@/sanity/lib/queries";
import {
  findActiveEnrollmentsForUser,
  findCourseProgressForUser,
} from "@/db/queries/enrollments";

export interface EnrolledCourseSummary extends CourseTitleLookup {
  completionPercentage: number;
  enrollmentStatus: "ACTIVE" | "COMPLETED" | "CANCELLED";
}

export async function getEnrolledCourses(userId: string): Promise<EnrolledCourseSummary[]> {
  // Step 1: ask NEON which Sanity course IDs this user is enrolled in.
  const [userEnrollments, userProgress] = await Promise.all([
    findActiveEnrollmentsForUser(userId),
    findCourseProgressForUser(userId),
  ]);

  if (userEnrollments.length === 0) {
    return []; // Avoids an unnecessary Sanity request when there's nothing to look up.
  }

  const courseIds = userEnrollments.map((enrollment) => enrollment.courseId);

  // Step 2: ask SANITY for the actual titles/slugs/thumbnails of exactly
  // those courses — a single query, using the "in" operator, instead of
  // one query per enrollment.
  const courses = await client.fetch<CourseTitleLookup[]>(coursesByIdsQuery, {
    ids: courseIds,
  });

  // Step 3: merge the two data sources in application code, keyed by
  // Sanity's _id — this is the "bridge" step described in this part's
  // concept explanation, made concrete.
  const progressByCourseId = new Map(userProgress.map((p) => [p.courseId, p]));
  const enrollmentByCourseId = new Map(userEnrollments.map((e) => [e.courseId, e]));

  return courses
    .map((course) => {
      const enrollment = enrollmentByCourseId.get(course._id);
      const progress = progressByCourseId.get(course._id);
      if (!enrollment) return null; // Defensive — should be impossible given how courseIds was built, but keeps TypeScript honest.
      return {
        ...course,
        completionPercentage: progress?.completionPercentage ?? 0,
        enrollmentStatus: enrollment.status,
      };
    })
    .filter((c): c is EnrolledCourseSummary => c !== null);
}
```

**Code walkthrough:**

- `Promise.all([...])` runs the two Neon queries concurrently rather than one after another — since neither depends on the other's result, there's no reason to wait sequentially, and this small habit compounds into meaningful speed savings once dashboards involve many concurrent queries (Part 15's instructor analytics will lean on this heavily).
- The early `return []` when `userEnrollments.length === 0` isn't just an optimization — it also means we correctly skip calling Sanity's `_id in $ids` query with an *empty* array, which some GROQ query patterns handle unpredictably. Always worth checking for empty-input edge cases before they reach a query.
- `.filter((c): c is EnrolledCourseSummary => c !== null)` is a TypeScript **type predicate** — a special function signature that doesn't just filter at runtime, it also tells TypeScript's compiler "after this filter, treat the array as having no `null` entries." Without this, TypeScript would still see the array type as including `null`, forcing awkward null-checks everywhere the result is used later.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors. We'll see this function produce real visible output once the sidebar renders it in Step 3.

---

## Step 2 — Building the dashboard layout shell

### The Target
`app/dashboard/layout.tsx` — the persistent frame wrapping every dashboard page: a fixed sidebar on desktop, a slide-out drawer on mobile, and a top bar with a user menu.

### The Concept
This layout is the "picture frame" described above. We split it into three files for clarity: the layout itself (a Server Component, since it fetches data and handles auth), a `Sidebar` component (mostly static, server-rendered navigation links), and a `MobileNav` client component (needs `useState` to track open/closed, hence must be a Client Component per Part 1's rule).

### The Implementation

First, install one small utility for detecting the current route, used to highlight active navigation links — this is built into Next.js already via the `usePathname` hook, so no new package is needed. Let's build the navigation link data structure and sidebar first:

#### `lib/dashboard/nav-items.ts`

```ts
export interface DashboardNavItem {
  label: string;
  href: string;
  icon: "home" | "book" | "award" | "settings";
}

// A single source of truth for navigation links — used by BOTH the
// desktop sidebar and the mobile drawer, so the two can never silently
// drift out of sync with each other as the app grows.
export const dashboardNavItems: DashboardNavItem[] = [
  { label: "Overview", href: "/dashboard", icon: "home" },
  { label: "Achievements", href: "/dashboard/achievements", icon: "award" },
  { label: "Settings", href: "/dashboard/settings", icon: "settings" },
];
```

#### `components/dashboard/nav-icon.tsx`

```tsx
import type { DashboardNavItem } from "@/lib/dashboard/nav-items";

// A tiny, dependency-free icon set using inline SVG — avoids pulling in
// a full icon library just for four simple glyphs. Each icon is 20x20
// and inherits its color from the surrounding text via "currentColor".
export function NavIcon({ icon }: { icon: DashboardNavItem["icon"] }) {
  const commonProps = {
    width: 20,
    height: 20,
    viewBox: "0 0 24 24",
    fill: "none",
    stroke: "currentColor",
    strokeWidth: 2,
    strokeLinecap: "round" as const,
    strokeLinejoin: "round" as const,
  };

  switch (icon) {
    case "home":
      return (
        <svg {...commonProps}>
          <path d="M3 9.5 12 3l9 6.5V21a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1Z" />
        </svg>
      );
    case "book":
      return (
        <svg {...commonProps}>
          <path d="M4 4.5A2.5 2.5 0 0 1 6.5 2H20v18H6.5A2.5 2.5 0 0 0 4 22.5Z" />
          <path d="M4 4.5v16" />
        </svg>
      );
    case "award":
      return (
        <svg {...commonProps}>
          <circle cx="12" cy="8" r="5" />
          <path d="m8.5 12.5-1 8 4.5-2.5 4.5 2.5-1-8" />
        </svg>
      );
    case "settings":
      return (
        <svg {...commonProps}>
          <circle cx="12" cy="12" r="3" />
          <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1Z" />
        </svg>
      );
  }
}
```

Now the sidebar itself — a Server Component, since it renders static navigation with no client-side state of its own (the *active-link highlighting* needs the current pathname, which requires a small client wrapper, built next):

#### `components/dashboard/nav-links.tsx`

```tsx
"use client"; // usePathname() is a client-only hook — it reads the
// browser's current URL, which only exists once the page is actually
// navigated to in the browser. This is the one piece of the sidebar that
// genuinely needs to be a Client Component; everything else stays server-
// rendered.

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/cn";
import { NavIcon } from "./nav-icon";
import { dashboardNavItems } from "@/lib/dashboard/nav-items";

export function NavLinks({ onNavigate }: { onNavigate?: () => void }) {
  const pathname = usePathname();

  return (
    <nav className="flex flex-col gap-1">
      {dashboardNavItems.map((item) => {
        // Exact match for "/dashboard" itself, but a "starts with" check
        // for everything else — this prevents "/dashboard" from staying
        // highlighted while viewing "/dashboard/achievements", while
        // still correctly highlighting "/dashboard/courses/xyz" under
        // whichever parent nav item eventually links there.
        const isActive =
          item.href === "/dashboard"
            ? pathname === "/dashboard"
            : pathname.startsWith(item.href);

        return (
          <Link
            key={item.href}
            href={item.href}
            onClick={onNavigate}
            className={cn(
              "flex items-center gap-3 rounded-[var(--radius-control)] px-3 py-2 text-sm font-medium transition-colors",
              isActive
                ? "bg-brand text-brand-contrast"
                : "text-text-secondary hover:bg-surface-inset hover:text-text-primary"
            )}
          >
            <NavIcon icon={item.icon} />
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
```

#### `components/dashboard/sidebar.tsx`

```tsx
import Link from "next/link";
import { NavLinks } from "./nav-links";

// A plain Server Component — it renders the outer chrome (logo, fixed
// positioning) and delegates only the interactive highlighting logic to
// the small Client Component above.
export function Sidebar() {
  return (
    <aside className="hidden w-64 shrink-0 border-r border-border bg-surface lg:flex lg:flex-col">
      <div className="flex h-16 items-center border-b border-border px-6">
        <Link href="/dashboard" className="text-lg font-bold text-text-primary">
          GreyMatter
        </Link>
      </div>
      <div className="flex-1 overflow-y-auto p-4">
        <NavLinks />
      </div>
    </aside>
  );
}
```

Now the mobile drawer — this genuinely needs `useState` to track open/closed, so the entire component is a Client Component:

#### `components/dashboard/mobile-nav.tsx`

```tsx
"use client";

import { useState } from "react";
import Link from "next/link";
import { NavLinks } from "./nav-links";
import { Button } from "@/components/ui/button";

export function MobileNav() {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <div className="lg:hidden">
      <Button
        variant="ghost"
        size="sm"
        onClick={() => setIsOpen(true)}
        aria-label="Open navigation menu"
        aria-expanded={isOpen}
      >
        {/* Simple hamburger icon — inline, no external dependency */}
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
          <path d="M4 6h16M4 12h16M4 18h16" strokeLinecap="round" />
        </svg>
      </Button>

      {isOpen && (
        // A full-screen overlay, dismissible by clicking the backdrop —
        // role="dialog" + aria-modal communicate to assistive technology
        // that this is a modal surface, not part of the normal page flow.
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Navigation menu"
          className="fixed inset-0 z-50 flex"
        >
          <div
            className="fixed inset-0 bg-black/40"
            onClick={() => setIsOpen(false)}
            aria-hidden="true"
          />
          <div className="relative z-10 flex h-full w-72 flex-col bg-surface p-4 shadow-lg">
            <div className="mb-4 flex items-center justify-between">
              <Link href="/dashboard" className="text-lg font-bold text-text-primary" onClick={() => setIsOpen(false)}>
                GreyMatter
              </Link>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setIsOpen(false)}
                aria-label="Close navigation menu"
              >
                ✕
              </Button>
            </div>
            <NavLinks onNavigate={() => setIsOpen(false)} />
          </div>
        </div>
      )}
    </div>
  );
}
```

Now the user menu, using Clerk's built-in `<UserButton>` component (recall Part 6 — we don't build our own account dropdown, the same way we don't build our own sign-in form):

#### `components/dashboard/topbar.tsx`

```tsx
import { UserButton } from "@clerk/nextjs";
import { MobileNav } from "./mobile-nav";

export function Topbar() {
  return (
    <header className="flex h-16 items-center justify-between border-b border-border bg-surface px-4 lg:px-8">
      <MobileNav />
      <div className="ml-auto flex items-center gap-4">
        <UserButton afterSignOutUrl="/" />
      </div>
    </header>
  );
}
```

Finally, the layout file that ties everything together:

#### `app/dashboard/layout.tsx`

```tsx
import { requireUser } from "@/lib/auth/require-user";
import { Sidebar } from "@/components/dashboard/sidebar";
import { Topbar } from "@/components/dashboard/topbar";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Calling requireUser() HERE, in the layout, means every single page
  // nested under app/dashboard/ is automatically protected — individual
  // pages don't each need to remember to call it themselves. This is a
  // deliberate architectural choice: authorization enforced at the
  // layout boundary, not repeated ad hoc in every page file.
  await requireUser();

  return (
    <div className="flex min-h-screen">
      <Sidebar />
      <div className="flex flex-1 flex-col">
        <Topbar />
        <main className="flex-1 bg-surface-muted">{children}</main>
      </div>
    </div>
  );
}
```

**Code walkthrough:**

- Calling `requireUser()` in the **layout** rather than in every individual page is the single most important architectural decision in this step — it guarantees that *any* new route we add under `app/dashboard/` for the rest of this series (achievements, settings, course pages, lesson pages) is automatically protected, with zero chance of a future part forgetting to add the check. Note carefully, though: this protects *access to the dashboard shell itself* — it does not, by itself, verify that a specific student is enrolled in a specific course, which is a distinct, additional check we build in Part 8.
- `NavLinks` is shared, unmodified, between both `Sidebar` (desktop) and `MobileNav` (mobile) — exactly the "single source of truth" reasoning from `dashboardNavItems` in Step 2 extended one level further: the *rendering* logic is shared too, not just the data.
- `<UserButton afterSignOutUrl="/" />` is Clerk's pre-built account menu — clicking it reveals options like "Manage account" and "Sign out," entirely handled by Clerk, requiring zero custom code from us, exactly mirroring Part 6's `<SignIn>`/`<SignUp>` philosophy.

### The Verification

```bash
npm run dev
```

While signed in, visit `http://localhost:3000/dashboard`. Confirm:

1. A desktop sidebar appears on the left (on a wide browser window) showing "GreyMatter" as a logo/link, and three nav items: Overview, Achievements, Settings — with "Overview" highlighted in brand color (since we're on `/dashboard`).
2. A top bar appears showing a user avatar/button on the right — click it and confirm Clerk's account menu opens with a working "Sign out" option.
3. Narrow your browser window below Tailwind's `lg` breakpoint (1024px) — confirm the desktop sidebar disappears and a hamburger button appears in the top bar instead.
4. Click the hamburger button — confirm a slide-out drawer appears with the same three nav links, and clicking the backdrop or the ✕ button closes it.
5. Click "Achievements" in either the sidebar or drawer — confirm it navigates to `/dashboard/achievements` (this will 404 for now — we build it in Step 5) and, if you navigate back to `/dashboard`, confirm "Overview" is highlighted again correctly.

---

## Step 3 — Building the enrollment-aware course list

### The Target
Rebuilding `app/dashboard/page.tsx` (currently Part 6's placeholder) into the real dashboard overview page — showing a grid of enrolled courses with progress bars, or a proper empty state if the student has no enrollments yet.

### The Concept
This page is the first real payoff of Step 1's cross-database merge function — and a good demonstration of Part 2's design system doing exactly the job it was built for: assembling `Card`, `ProgressBar`, `Badge`, and `EmptyState` into a real, meaningful screen without inventing any new styling.

### The Implementation

#### `app/dashboard/page.tsx`

```tsx
import Link from "next/link";
import Image from "next/image";
import { requireUser } from "@/lib/auth/require-user";
import { getEnrolledCourses } from "@/lib/dashboard/get-enrolled-courses";
import { urlForImage } from "@/sanity/lib/image";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { EmptyState } from "@/components/ui/empty-state";
import { ProgressBar } from "@/components/ui/progress-bar";

const difficultyLabels = {
  beginner: "Beginner",
  intermediate: "Intermediate",
  advanced: "Advanced",
} as const;

export default async function DashboardOverviewPage() {
  // Note: this page does NOT call requireUser() itself — that's already
  // guaranteed by app/dashboard/layout.tsx from Step 2. We only need the
  // returned user object here to know WHICH user's courses to fetch.
  const user = await requireUser();
  const courses = await getEnrolledCourses(user.id);

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-8 px-6 py-10">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">
          Welcome back{user.email ? `, ${user.email.split("@")[0]}` : ""}
        </h1>
        <p className="mt-1 text-text-secondary">Continue where you left off.</p>
      </div>

      {courses.length === 0 ? (
        <EmptyState
          title="You haven't enrolled in any courses yet"
          description="Browse the catalog to find your first course."
          action={
            <Link href="/courses">
              <Button variant="primary">Browse Catalog</Button>
            </Link>
          }
        />
      ) : (
        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {courses.map((course) => (
            <Link key={course._id} href={`/dashboard/courses/${course.slug.current}`}>
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
                    {course.enrollmentStatus === "COMPLETED" && (
                      <Badge variant="success">Completed</Badge>
                    )}
                  </div>
                  <CardTitle>{course.title}</CardTitle>
                </CardHeader>
                <CardContent>
                  <ProgressBar value={course.completionPercentage} label="Your progress" />
                </CardContent>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
```

Add a loading skeleton, following the exact same pattern established in Part 4:

#### `app/dashboard/loading.tsx`

```tsx
import { Skeleton } from "@/components/ui/skeleton";

export default function DashboardOverviewLoading() {
  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-8 px-6 py-10">
      <div className="flex flex-col gap-2">
        <Skeleton className="h-7 w-56" />
        <Skeleton className="h-5 w-72" />
      </div>
      <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        {Array.from({ length: 3 }).map((_, index) => (
          <div key={index} className="flex flex-col gap-3 rounded-[var(--radius-panel)] border border-border p-4">
            <Skeleton className="aspect-video w-full" />
            <Skeleton className="h-5 w-3/4" />
            <Skeleton className="h-2 w-full" />
          </div>
        ))}
      </div>
    </div>
  );
}
```

### The Verification

While signed in with your test account (which currently has zero enrollments — recall Part 6's webhook-created user is separate from Part 5's seeded dev user), visit `/dashboard`. Confirm you see the **empty state**: "You haven't enrolled in any courses yet," with a working "Browse Catalog" button linking to `/courses`.

To verify the populated state, we need a real enrollment for this specific Clerk-authenticated user. Since Part 8 builds the real enrollment Server Action, temporarily create one directly for testing purposes using Drizzle Studio:

```bash
npm run db:studio
```

Find the `enrollments` table, click "Add row," and manually set `user_id` to your webhook-provisioned user's internal UUID (visible in the `users` table), `course_id` to your real Sanity course `_id` (from Part 5, Step 10's Vision query), and `status` to `ACTIVE`. Also add a matching row in `course_progress` with the same `user_id`/`course_id`/`enrollment_id` and `completion_percentage` set to, say, `35`.

Refresh `/dashboard` and confirm the course now appears as a card, with the correct thumbnail, title, difficulty badge, and a progress bar showing 35%. Click the card and confirm it attempts to navigate to `/dashboard/courses/introduction-to-databases` (expected to 404 for now — built in Step 4).

---

## Step 4 — Building the course and lesson navigation shell

### The Target
`app/dashboard/courses/[courseSlug]/page.tsx` — a per-course dashboard page showing the chapter/lesson outline with progress indicators — plus a shared `CourseSidebarNav` component we'll reuse inside the actual lesson player in Part 9.

### The Concept

This page is deliberately similar in spirit to Part 4's public course detail page — but with a critical difference: instead of a public, unauthenticated outline, this version is scoped to *this specific signed-in student's* progress, and every lesson link points into the authenticated `/dashboard/courses/.../lessons/...` tree rather than anywhere public. We're also building the navigation component here as a **separate, reusable piece** — not just inline markup on this page — because Part 9's actual lesson player needs the exact same chapter/lesson outline rendered alongside lesson content, just with one lesson highlighted as "current."

### The Implementation

First, a query helper combining a course's structure (from Sanity) with this specific user's lesson-level progress (from Neon):

#### `db/queries/lesson-progress.ts`

```ts
import { and, eq } from "drizzle-orm";
import { db } from "@/db/client";
import { lessonProgress } from "@/db/schema";

export async function findLessonProgressForCourse(userId: string, courseId: string) {
  return db.query.lessonProgress.findMany({
    where: and(eq(lessonProgress.userId, userId), eq(lessonProgress.courseId, courseId)),
  });
}
```

#### `lib/dashboard/get-course-outline.ts`

```ts
import { client } from "@/sanity/lib/client";
import { defaultFetchOptions } from "@/sanity/lib/client";
import { courseDetailQuery, type CourseDetail } from "@/sanity/lib/queries";
import { findCourseProgressForUser } from "@/db/queries/enrollments";
import { findLessonProgressForCourse } from "@/db/queries/lesson-progress";
import { findActiveEnrollmentsForUser } from "@/db/queries/enrollments";

export interface LessonWithProgress {
  _id: string;
  title: string;
  slug: { current: string };
  order: number;
  isPreview: boolean;
  status: "NOT_STARTED" | "IN_PROGRESS" | "COMPLETED";
}

export interface ChapterWithProgress {
  _id: string;
  title: string;
  slug: { current: string };
  order: number;
  lessons: LessonWithProgress[];
}

export interface CourseOutline extends Omit<CourseDetail, "chapters"> {
  chapters: ChapterWithProgress[];
  completionPercentage: number;
}

// The KEY authorization check for this entire page lives here: we ONLY
// return course data if the given user has an ACTIVE enrollment for it.
// If not, we return null, and the calling page treats that identically
// to "course doesn't exist" — this is exactly the resource-level
// authorization principle previewed in Part 0 and Part 6: route
// protection (requireUser in the layout) is necessary but NOT
// sufficient; each individual resource must also verify the specific
// relationship (this user + this course) before returning data.
export async function getCourseOutline(
  userId: string,
  courseSlug: string
): Promise<CourseOutline | null> {
  const course = await client.fetch<CourseDetail | null>(
    courseDetailQuery,
    { slug: courseSlug },
    defaultFetchOptions
  );

  if (!course) {
    return null;
  }

  const enrollments = await findActiveEnrollmentsForUser(userId);
  const isEnrolled = enrollments.some(
    (e) => e.courseId === course._id && e.status !== "CANCELLED"
  );

  if (!isEnrolled) {
    return null; // Not enrolled — treated as "not found," never leaking that the course exists but access is denied.
  }

  const [progressRows, courseProgressRows] = await Promise.all([
    findLessonProgressForCourse(userId, course._id),
    findCourseProgressForUser(userId),
  ]);

  const statusByLessonId = new Map(progressRows.map((p) => [p.lessonId, p.status]));
  const courseProgress = courseProgressRows.find((cp) => cp.courseId === course._id);

  return {
    ...course,
    completionPercentage: courseProgress?.completionPercentage ?? 0,
    chapters: course.chapters.map((chapter) => ({
      ...chapter,
      lessons: chapter.lessons.map((lesson) => ({
        ...lesson,
        status: statusByLessonId.get(lesson._id) ?? "NOT_STARTED",
      })),
    })),
  };
}
```

**Code walkthrough:**

- Read the comment above `getCourseOutline` carefully — this is one of the most important lines of reasoning in the entire series so far: returning `null` for "course exists but you're not enrolled" using the *exact same code path* as "course doesn't exist at all" is a deliberate security choice. If we distinguished between these two cases (e.g., a distinct "Access Denied" page for existing-but-unenrolled courses), we'd be leaking information — confirming to an unauthorized visitor that a specific course slug *does* exist, which an attacker could use to enumerate valid course slugs. Treating both cases identically avoids that leak entirely.
- `Omit<CourseDetail, "chapters">` is a TypeScript utility type meaning "every field of `CourseDetail` except `chapters`" — we need this because `CourseOutline` redefines `chapters` with a different, progress-aware shape (`ChapterWithProgress[]` instead of `ChapterSummary[]`), and TypeScript would otherwise complain about the field being declared twice with conflicting types.

Now, the reusable outline navigation component, designed for use both on this course landing page *and* later inside Part 9's lesson player sidebar:

#### `components/dashboard/course-outline-nav.tsx`

```tsx
import Link from "next/link";
import { cn } from "@/lib/cn";
import type { CourseOutline } from "@/lib/dashboard/get-course-outline";

interface CourseOutlineNavProps {
  course: CourseOutline;
  currentLessonSlug?: string; // when provided (Part 9), highlights the active lesson
}

const statusIndicator: Record<string, string> = {
  COMPLETED: "✓",
  IN_PROGRESS: "●",
  NOT_STARTED: "○",
};

export function CourseOutlineNav({ course, currentLessonSlug }: CourseOutlineNavProps) {
  return (
    <nav className="flex flex-col gap-4">
      {course.chapters.map((chapter) => (
        <div key={chapter._id} className="flex flex-col gap-1">
          <p className="px-2 text-xs font-semibold uppercase tracking-wide text-text-muted">
            {chapter.title}
          </p>
          {chapter.lessons.map((lesson) => {
            const isCurrent = lesson.slug.current === currentLessonSlug;
            return (
              <Link
                key={lesson._id}
                href={`/dashboard/courses/${course.slug.current}/lessons/${lesson.slug.current}`}
                className={cn(
                  "flex items-center gap-2 rounded-[var(--radius-control)] px-2 py-1.5 text-sm transition-colors",
                  isCurrent
                    ? "bg-brand text-brand-contrast"
                    : "text-text-secondary hover:bg-surface-inset hover:text-text-primary"
                )}
              >
                <span
                  className={cn(
                    "text-xs",
                    lesson.status === "COMPLETED" && !isCurrent && "text-success"
                  )}
                  aria-hidden="true"
                >
                  {statusIndicator[lesson.status]}
                </span>
                {lesson.title}
              </Link>
            );
          })}
        </div>
      ))}
    </nav>
  );
}
```

Finally, the course landing page itself:

#### `app/dashboard/courses/[courseSlug]/page.tsx`

```tsx
import { notFound } from "next/navigation";
import Image from "next/image";
import { requireUser } from "@/lib/auth/require-user";
import { getCourseOutline } from "@/lib/dashboard/get-course-outline";
import { urlForImage } from "@/sanity/lib/image";
import { CourseOutlineNav } from "@/components/dashboard/course-outline-nav";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { ProgressBar } from "@/components/ui/progress-bar";
import Link from "next/link";

interface CoursePageProps {
  params: Promise<{ courseSlug: string }>;
}

export default async function DashboardCoursePage({ params }: CoursePageProps) {
  const { courseSlug } = await params;
  const user = await requireUser();
  const course = await getCourseOutline(user.id, courseSlug);

  // Recall the reasoning from getCourseOutline: a null result covers BOTH
  // "course doesn't exist" and "you're not enrolled" — we render the
  // exact same 404 boundary either way, for the security reasons
  // explained above.
  if (!course) {
    notFound();
  }

  const firstLesson = course.chapters[0]?.lessons[0];

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-6 px-6 py-10 lg:flex-row lg:gap-10">
      <aside className="lg:w-72 lg:shrink-0">
        <Card>
          <CardContent className="p-4">
            <CourseOutlineNav course={course} />
          </CardContent>
        </Card>
      </aside>

      <div className="flex flex-1 flex-col gap-6">
        <div className="relative aspect-video w-full overflow-hidden rounded-[var(--radius-panel)]">
          <Image
            src={urlForImage(course.thumbnail).width(1000).height(560).url()}
            alt={course.title}
            fill
            className="object-cover"
          />
        </div>
        <div>
          <h1 className="text-2xl font-bold text-text-primary">{course.title}</h1>
          <p className="mt-2 text-text-secondary">{course.description}</p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Your progress</CardTitle>
          </CardHeader>
          <CardContent>
            <ProgressBar value={course.completionPercentage} label="Course completion" />
          </CardContent>
        </Card>

        {firstLesson && (
          <Link
            href={`/dashboard/courses/${course.slug.current}/lessons/${firstLesson.slug.current}`}
            className="text-sm font-medium text-brand hover:underline"
          >
            {course.completionPercentage > 0 ? "Resume learning →" : "Start learning →"}
          </Link>
        )}
      </div>
    </div>
  );
}
```

### The Verification

Using the manually-created enrollment from Step 3's verification, visit `/dashboard/courses/introduction-to-databases`. Confirm:

1. A left-hand outline card shows "Getting Started" as a section header, with both lessons listed underneath, each showing a status indicator (○ for not-started).
2. The main content area shows the course thumbnail, title, description, and a progress bar matching the `completionPercentage` you set in Neon.
3. A "Start learning →" (or "Resume learning →" if you set completion above 0) link appears, pointing at `/dashboard/courses/introduction-to-databases/lessons/what-is-a-database` — this will 404 for now, since Part 9 builds the actual lesson player.

Now test the authorization boundary directly: temporarily change your manually-created enrollment's `status` to `CANCELLED` in Drizzle Studio, refresh this page, and confirm you now see a proper 404 (not a broken page or an error) — proving `isEnrolled` correctly excludes cancelled enrollments. Set `status` back to `ACTIVE` afterward.

---

## Step 5 — Achievements and Settings placeholders, and the Context provider boundary

### The Target
Minimal but real `app/dashboard/achievements/page.tsx` and `app/dashboard/settings/page.tsx` pages, plus `lib/dashboard/dashboard-context.tsx` — a Context provider that will carry lightweight, cross-page dashboard state (starting with the current user's role and email) down to client components without prop-drilling.

### The Concept
We build these two pages now — even though Achievements gets real content in Part 13 (certificates) and Settings stays minimal until later — because leaving them as broken 404 links in a *finished-looking* sidebar would be a poor experience even during development. The **Context provider** solves a different problem: several Client Components deeper in the tree (like a future notification bell in Part 14, or role-aware UI elements) will need to know basic facts about the current user without every single layout and page manually passing them down as props through every intermediate layer — Context lets any descendant component read this data directly.

### The Implementation

#### `lib/dashboard/dashboard-context.tsx`

```tsx
"use client"; // Context providers that wrap client-consumed state must
// themselves be Client Components — createContext/useContext are React
// client-side APIs.

import { createContext, useContext } from "react";
import type { UserRole } from "@/db/queries/users";

export interface DashboardContextValue {
  userId: string;
  email: string;
  role: UserRole;
}

const DashboardContext = createContext<DashboardContextValue | null>(null);

export function DashboardProvider({
  value,
  children,
}: {
  value: DashboardContextValue;
  children: React.ReactNode;
}) {
  return <DashboardContext.Provider value={value}>{children}</DashboardContext.Provider>;
}

// A custom hook wrapping useContext — this is a common, worthwhile
// pattern: it throws a CLEAR error immediately if some future component
// tries to use this hook outside the provider, rather than silently
// returning null and causing a confusing crash three lines later at the
// point of actually using the (unexpectedly null) value.
export function useDashboardContext(): DashboardContextValue {
  const context = useContext(DashboardContext);
  if (!context) {
    throw new Error("useDashboardContext must be used within a DashboardProvider");
  }
  return context;
}
```

Wire the provider into the layout from Step 2:

#### `app/dashboard/layout.tsx` (updated)

```tsx
import { requireUser } from "@/lib/auth/require-user";
import { Sidebar } from "@/components/dashboard/sidebar";
import { Topbar } from "@/components/dashboard/topbar";
import { DashboardProvider } from "@/lib/dashboard/dashboard-context";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await requireUser();

  return (
    // Notice: requireUser() runs on the SERVER, resolving the real user
    // ONCE per request. We then pass just the small pieces of data any
    // CLIENT component might need (userId, email, role) into the
    // provider as a plain serializable object — this is how Server
    // Component data crosses the boundary into Client Component Context.
    <DashboardProvider value={{ userId: user.id, email: user.email, role: user.role }}>
      <div className="flex min-h-screen">
        <Sidebar />
        <div className="flex flex-1 flex-col">
          <Topbar />
          <main className="flex-1 bg-surface-muted">{children}</main>
        </div>
      </div>
    </DashboardProvider>
  );
}
```

Now the two remaining pages:

#### `app/dashboard/achievements/page.tsx`

```tsx
import { requireUser } from "@/lib/auth/require-user";
import { EmptyState } from "@/components/ui/empty-state";

export default async function AchievementsPage() {
  await requireUser();

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6 px-6 py-10">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Achievements</h1>
        <p className="mt-1 text-text-secondary">Your earned certificates will appear here.</p>
      </div>
      <EmptyState
        title="No certificates yet"
        description="Complete a course to earn your first certificate. This feature is fully built out in Part 13."
      />
    </div>
  );
}
```

#### `app/dashboard/settings/page.tsx`

```tsx
import { requireUser } from "@/lib/auth/require-user";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export default async function SettingsPage() {
  const user = await requireUser();

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-6 px-6 py-10">
      <div>
        <h1 className="text-2xl font-bold text-text-primary">Settings</h1>
        <p className="mt-1 text-text-secondary">Manage your account details.</p>
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Account</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-3 text-sm">
          <div className="flex items-center justify-between">
            <span className="text-text-secondary">Email</span>
            <span className="text-text-primary">{user.email}</span>
          </div>
          <div className="flex items-center justify-between">
            <span className="text-text-secondary">Role</span>
            <Badge variant="brand">{user.role}</Badge>
          </div>
          <p className="text-xs text-text-muted">
            To change your password or connected accounts, use the account menu in the top bar.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
```

### The Verification

Visit `/dashboard/achievements` and confirm the "No certificates yet" empty state renders cleanly, with correct sidebar highlighting on "Achievements." Visit `/dashboard/settings` and confirm your real email and `STUDENT` role badge display correctly, with "Settings" highlighted in the sidebar.

To verify the Context provider works end-to-end, temporarily add this snippet to the bottom of `app/dashboard/settings/page.tsx`'s `CardContent` (as a quick manual test, since `useDashboardContext` needs a Client Component to actually call it):

```tsx
// Add this component temporarily, in the same file, above SettingsPage:
"use client";
function ContextTestDisplay() {
  const { useDashboardContext } = require("@/lib/dashboard/dashboard-context");
  const ctx = useDashboardContext();
  return <p className="text-xs text-text-muted">Context check: {ctx.email} / {ctx.role}</p>;
}
```

(In practice, proper components import `useDashboardContext` normally at the top of a dedicated `"use client"` file rather than using `require()` inline — this snippet is only a quick throwaway verification, not a pattern to keep. Remove it once confirmed.) Render `<ContextTestDisplay />` inside the card, reload the page, and confirm the same email/role appear a second time, sourced entirely from Context rather than a prop — then delete this test snippet.

Run the full verification suite:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Common mistakes

- **Sidebar shows all nav items highlighted, or none at all** — Check `NavLinks`'s `isActive` logic; a common mistake is using `pathname.includes(item.href)` instead of `.startsWith(item.href)` — `.includes` can produce false positives if one route's path happens to be a substring of another.
- **`useDashboardContext` throws "must be used within a DashboardProvider"** — Confirm the component calling it is actually rendered *inside* `app/dashboard/layout.tsx`'s tree — this hook will correctly fail if called from a page outside `/dashboard/*`, like a public `/courses` page, since no provider wraps those routes.
- **Course page 404s even though you're enrolled** — Double-check the enrollment's `course_id` in Neon *exactly* matches the Sanity course's `_id` (copy-paste it directly from Vision rather than retyping), and confirm `status` isn't accidentally set to `CANCELLED`.
- **Mobile drawer doesn't close when clicking a link** — Confirm `onNavigate` is actually passed through from `MobileNav` to `NavLinks`, and that `NavLinks`'s `<Link onClick={onNavigate}>` prop is wired correctly — a common oversight when adding new nav items directly instead of through the shared array.
- **`getCourseOutline` throws instead of returning `null` for a nonexistent course** — Confirm you're checking `if (!course) return null;` *before* attempting to read `course._id` anywhere below it — reordering these checks is an easy mistake when refactoring.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `db/queries/enrollments.ts`, `db/queries/lesson-progress.ts`, `lib/dashboard/get-enrolled-courses.ts`, `lib/dashboard/get-course-outline.ts`, `lib/dashboard/nav-items.ts`, `lib/dashboard/dashboard-context.tsx`, `components/dashboard/*.tsx`, `sanity/lib/queries.ts` (modified), `app/dashboard/layout.tsx` (modified), `app/dashboard/page.tsx` (modified), `app/dashboard/loading.tsx`, `app/dashboard/courses/[courseSlug]/page.tsx`, `app/dashboard/achievements/page.tsx`, `app/dashboard/settings/page.tsx`.

```bash
git commit -m "Part 7: student dashboard shell — responsive sidebar/mobile nav, enrollment-aware course list, course outline navigation, resource-level authorization, dashboard Context provider"
```

---

## Reference: resource-level authorization, reinforced

This part's most important lesson, worth restating on its own: **Part 6's `requireUser()` in the dashboard layout answers "is anyone allowed in here at all?" — it does not, and cannot, answer "is *this* user allowed to see *this specific* course."** That second question is answered separately, per-resource, inside `getCourseOutline()`. Every remaining part of this series — enrollment (Part 8), lesson access (Part 9), module submissions (Part 11) — will repeat this exact two-layer pattern: route-level authentication first, resource-level authorization second, never conflating the two.

## Reference: dashboard route map so far

| Route | Status |
|---|---|
| `/dashboard` | ✅ Enrollment-aware course list |
| `/dashboard/courses/[courseSlug]` | ✅ Course outline + progress |
| `/dashboard/courses/[courseSlug]/lessons/[lessonSlug]` | ⏳ Built in Part 9 |
| `/dashboard/achievements` | ✅ Placeholder — real content in Part 13 |
| `/dashboard/settings` | ✅ Basic account info |

---

## What's next

Part 8 replaces this part's manually-created-in-Drizzle-Studio enrollment with the real thing: a secure enrollment Server Action, validated with Zod, wrapped in a database transaction, protected against duplicate enrollment, and — for the first time in this series — emitting an event that Part 12's Inngest workflows will later consume.
