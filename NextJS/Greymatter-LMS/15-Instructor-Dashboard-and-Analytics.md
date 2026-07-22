# Part 15 — Instructor Dashboard and Analytics

## The goal

By the end of this part, GreyMatter LMS will have a complete instructor-facing surface: a role-protected `/instructor` area, a list of courses the signed-in instructor actually owns, a per-course student roster with pagination, a lesson-completion funnel, average assessment scores, an "at-risk students" view, CSV export, a manual reminder trigger, and a background-materialized analytics summary table — turning five parts' worth of accumulated Neon data into something an instructor can genuinely act on.

## Why it exists

Every table this series has built since Part 5 — `enrollments`, `lesson_progress`, `module_attempts`, `course_progress`, `certificates` — has been accumulating real, structured data this entire time, but nothing has ever presented it back to the person who actually needs it: the instructor. This part is the payoff of that accumulation. It's also the first place in the series we build genuinely **aggregate** queries (counts, averages, groupings across many students at once) rather than per-user lookups, and the first place we need real **course ownership** as a distinct authorization concept from "any signed-in instructor can see anything."

## The data flow

```text
Instructor visits /instructor/courses/[courseId]
        │
        ▼
requireRole("INSTRUCTOR") — Part 6's role-based authorization, used for the first time
        │
        ▼
Verify THIS instructor owns THIS course (Sanity's course.instructor reference)
        │
        ▼
Paginated queries: enrollment count, completion funnel, average scores, at-risk students
        │
        ▼
Instructor triggers a manual reminder → emits an Inngest event → Part 14's reminder logic runs on demand
```

---

## Step 1 — Course ownership: linking Clerk instructors to Sanity instructor documents

### The Target

No schema changes — a design decision and one small query helper, `lib/instructor/verify-course-ownership.ts`, establishing how we determine "does this signed-in instructor own this course."

### The Concept

Recall Part 3's schema: `course.instructor` references an `instructor` document, which has a `name`, `bio`, and `avatar` — but no connection whatsoever to a Clerk account or our `users` table. We need to bridge these, exactly the way Part 6 bridged Clerk to our internal `users` table. The simplest, least invasive approach — avoiding a Sanity schema migration this late in the series — is to add one field connecting the two: the instructor document stores the corresponding internal `users.id`.

### The Implementation

#### `sanity/schema-types/instructor.ts` (add one field)

```ts
// Add this field to the existing instructor schema, alongside name/slug/avatar/bio/title:
defineField({
  name: "userId",
  title: "Linked user ID",
  type: "string",
  description:
    "The internal GreyMatter users.id (a UUID from Neon) this instructor profile belongs to. Required for instructor dashboard access — set this manually after promoting a user to the INSTRUCTOR role.",
}),
```

Since Studio can't query Neon directly, this field is populated manually by an administrator — a deliberate, simple manual step rather than over-engineering a live cross-system sync for a field that changes rarely (recall Part 0's textbook/library-card test: this is closer to content than to transactional data, since it changes about as often as an instructor's bio does).

#### `sanity/lib/queries.ts` (append)

```ts
export interface CourseOwnershipCheck {
  _id: string;
  instructorUserId: string | null;
}

export const courseOwnershipQuery = /* groq */ `
  *[_type == "course" && _id == $courseId][0]{
    _id,
    "instructorUserId": instructor->userId
  }
`;
```

#### `lib/instructor/verify-course-ownership.ts`

```ts
import { client } from "@/sanity/lib/client";
import { courseOwnershipQuery, type CourseOwnershipCheck } from "@/sanity/lib/queries";

// Returns true only if the course exists AND its linked instructor
// document's userId matches the given internal user ID. Mirrors Part
// 7's getCourseOutline enrollment check exactly — same "prove the
// specific relationship, don't just check existence" pattern, applied
// here to course ownership instead of student enrollment.
export async function verifyCourseOwnership(courseId: string, userId: string): Promise<boolean> {
  const result = await client.fetch<CourseOwnershipCheck | null>(courseOwnershipQuery, {
    courseId,
  });
  return result?.instructorUserId === userId;
}
```

### The Verification

In Sanity Studio, open your "Ada Lovelace" instructor document, and set "Linked user ID" to the internal `users.id` of whichever test account you'd like to use as an instructor for the rest of this part. We'll promote that account's role next.

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 2 — Promoting a user to the Instructor role

### The Target

A small, deliberately manual admin script, `db/promote-user.ts`, since we haven't built a full admin UI for role management yet (that's Part 16's scope, as an operational task).

### The Implementation

#### `db/promote-user.ts`

```ts
import { eq } from "drizzle-orm";
import { db } from "@/db/client";
import { users } from "@/db/schema";

const TARGET_EMAIL = "REPLACE_WITH_YOUR_TEST_ACCOUNT_EMAIL";
const TARGET_ROLE = "INSTRUCTOR" as const;

async function run() {
  const [updated] = await db
    .update(users)
    .set({ role: TARGET_ROLE, updatedAt: new Date() })
    .where(eq(users.email, TARGET_EMAIL))
    .returning();

  if (!updated) {
    console.error(`No user found with email ${TARGET_EMAIL}`);
    process.exit(1);
  }
  console.log(`Promoted ${updated.email} to ${updated.role}`);
}

run().then(() => process.exit(0));
```

### The Verification

```bash
npx tsx db/promote-user.ts
```

Expected output: `Promoted your-email@example.com to INSTRUCTOR`. Confirm via Drizzle Studio that this user's `role` column now reads `INSTRUCTOR`. You can delete `db/promote-user.ts` after use, or keep it as a reusable local admin tool — either is reasonable at this stage of the series.

---

## Step 3 — The instructor layout and course list

### The Target

`app/instructor/layout.tsx` — protected with `requireRole("INSTRUCTOR")` for the first time in this series — and `app/instructor/page.tsx`, listing every course this instructor owns.

### The Concept

Recall Part 6 built `requireRole` but we never had a genuine use for it until now. Also recall Part 7's lesson: route-level protection (this layout) is necessary but not sufficient — it answers "is this person an instructor at all," not "does this specific instructor own this specific course," which Step 1's `verifyCourseOwnership` will answer separately, per-course, starting in Step 4.

### The Implementation

#### `sanity/lib/queries.ts` (append)

```ts
export interface InstructorCourseSummary {
  _id: string;
  title: string;
  slug: SanitySlug;
  isPublished: boolean;
}

export const coursesByInstructorUserIdQuery = /* groq */ `
  *[_type == "course" && instructor->userId == $userId]{
    _id,
    title,
    slug,
    isPublished
  }
`;
```

#### `app/instructor/layout.tsx`

```tsx
import { requireRole } from "@/lib/auth/require-role";
import Link from "next/link";

export default async function InstructorLayout({ children }: { children: React.ReactNode }) {
  // First use of requireRole in this series — recall it builds on
  // requireUser, so an unauthenticated visitor is redirected to
  // /sign-in, while an authenticated STUDENT is redirected to
  // /dashboard, never seeing this layout's content at all.
  await requireRole("INSTRUCTOR");

  return (
    <div className="flex min-h-screen flex-col">
      <header className="border-b border-border bg-surface px-6 py-4">
        <Link href="/instructor" className="text-lg font-bold text-text-primary">
          GreyMatter Instructor
        </Link>
      </header>
      <main className="flex-1 bg-surface-muted">{children}</main>
    </div>
  );
}
```

#### `app/instructor/page.tsx`

```tsx
import Link from "next/link";
import { requireRole } from "@/lib/auth/require-role";
import { client } from "@/sanity/lib/client";
import {
  coursesByInstructorUserIdQuery,
  type InstructorCourseSummary,
} from "@/sanity/lib/queries";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/ui/empty-state";

export default async function InstructorHomePage() {
  const user = await requireRole("INSTRUCTOR");

  const courses = await client.fetch<InstructorCourseSummary[]>(coursesByInstructorUserIdQuery, {
    userId: user.id,
  });

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-6 px-6 py-10">
      <h1 className="text-2xl font-bold text-text-primary">Your courses</h1>

      {courses.length === 0 ? (
        <EmptyState
          title="No courses linked to your account"
          description="Ask an administrator to link your instructor profile in Sanity Studio."
        />
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {courses.map((course) => (
            <Link key={course._id} href={`/instructor/courses/${course._id}`}>
              <Card className="h-full transition hover:border-brand hover:shadow-md">
                <CardHeader>
                  <div className="flex items-center justify-between">
                    <CardTitle>{course.title}</CardTitle>
                    <Badge variant={course.isPublished ? "success" : "warning"}>
                      {course.isPublished ? "Published" : "Draft"}
                    </Badge>
                  </div>
                </CardHeader>
                <CardContent>
                  <p className="text-sm text-text-secondary">View students & analytics →</p>
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

### The Verification

Sign in as your newly-promoted instructor account. Visit `/instructor` and confirm "Introduction to Databases" appears as a card with a green "Published" badge. Sign in as a plain student account instead and visit `/instructor` directly — confirm you're redirected to `/dashboard`, never seeing instructor content.

---

## Step 4 — Aggregate analytics queries

### The Target

`db/queries/instructor-analytics.ts` — the real analytical heart of this part: enrollment counts, a lesson-completion funnel, average scores, and at-risk student detection, all computed with efficient, batch-oriented SQL rather than fetching every row and computing in JavaScript.

### The Concept

Every query in this file follows one rule worth stating explicitly: **push aggregation into the database, don't pull raw rows into Node.js and loop.** Recall Part 14's `findInactiveEnrollments` already established this habit; here we extend it to `COUNT`, `AVG`, and `GROUP BY` — operations PostgreSQL is specifically optimized to perform, and which would be needlessly slow and memory-hungry to replicate by hand in application code once a course has hundreds or thousands of enrolled students.

### The Implementation

#### `db/queries/instructor-analytics.ts`

```ts
import { and, avg, count, eq, sql } from "drizzle-orm";
import { db } from "@/db/client";
import { enrollments, lessonProgress, moduleAttempts, courseProgress } from "@/db/schema";

export async function getEnrollmentCount(courseId: string): Promise<number> {
  const [row] = await db
    .select({ value: count() })
    .from(enrollments)
    .where(eq(enrollments.courseId, courseId));
  return row.value;
}

export interface LessonCompletionFunnelEntry {
  lessonId: string;
  completedCount: number;
}

// GROUP BY pushed entirely into Postgres — returns, for every lesson_id
// that has ANY progress row for this course, how many students have
// COMPLETED it. This is the raw material for a funnel chart: which
// lessons see the steepest drop-off in completion.
export async function getLessonCompletionFunnel(
  courseId: string
): Promise<LessonCompletionFunnelEntry[]> {
  const rows = await db
    .select({
      lessonId: lessonProgress.lessonId,
      completedCount: count(),
    })
    .from(lessonProgress)
    .where(and(eq(lessonProgress.courseId, courseId), eq(lessonProgress.status, "COMPLETED")))
    .groupBy(lessonProgress.lessonId);
  return rows;
}

export interface ModuleAverageScore {
  moduleId: string;
  averageScore: number | null;
  attemptCount: number;
}

// AVG() computed by Postgres directly — averaging in application code
// would require pulling every single attempt row into memory first,
// which becomes genuinely wasteful at scale.
export async function getAverageScoresByModule(lessonIds: string[]): Promise<ModuleAverageScore[]> {
  if (lessonIds.length === 0) return [];
  const rows = await db
    .select({
      moduleId: moduleAttempts.moduleId,
      averageScore: avg(moduleAttempts.score),
      attemptCount: count(),
    })
    .from(moduleAttempts)
    .where(sql`${moduleAttempts.lessonId} in ${lessonIds}`)
    .groupBy(moduleAttempts.moduleId);

  return rows.map((r) => ({
    moduleId: r.moduleId,
    averageScore: r.averageScore ? Math.round(Number(r.averageScore)) : null,
    attemptCount: r.attemptCount,
  }));
}

export interface AtRiskStudent {
  userId: string;
  userEmail: string;
  completionPercentage: number;
  lastActivityAt: Date;
}

// "At risk" defined simply, for this series' scope: enrolled, ACTIVE,
// under 50% complete, and inactive for 3+ days. A real product might
// tune these thresholds per course or make them configurable — kept as
// clear, named constants here so that future adjustment is a one-line
// change, not a hunt through query logic.
const AT_RISK_MAX_COMPLETION = 50;
const AT_RISK_INACTIVITY_DAYS = 3;

export async function getAtRiskStudents(courseId: string): Promise<AtRiskStudent[]> {
  const cutoff = new Date(Date.now() - AT_RISK_INACTIVITY_DAYS * 24 * 60 * 60 * 1000);

  const rows = await db
    .select({
      userId: enrollments.userId,
      completionPercentage: courseProgress.completionPercentage,
      lastActivityAt: courseProgress.lastActivityAt,
    })
    .from(enrollments)
    .innerJoin(
      courseProgress,
      and(eq(courseProgress.userId, enrollments.userId), eq(courseProgress.courseId, enrollments.courseId))
    )
    .where(
      and(
        eq(enrollments.courseId, courseId),
        eq(enrollments.status, "ACTIVE"),
        sql`${courseProgress.completionPercentage} < ${AT_RISK_MAX_COMPLETION}`,
        sql`${courseProgress.lastActivityAt} < ${cutoff}`
      )
    );

  // Fetching user emails separately — a small tradeoff favoring query
  // readability here, since this list is typically small (a handful of
  // at-risk students, not the whole roster).
  const { findUserById } = await import("@/db/queries/users");
  const withEmails = await Promise.all(
    rows.map(async (row) => {
      const user = await findUserById(row.userId);
      return {
        userId: row.userId,
        userEmail: user?.email ?? "unknown",
        completionPercentage: row.completionPercentage,
        lastActivityAt: row.lastActivityAt,
      };
    })
  );
  return withEmails;
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors. Full behavioral verification happens once wired into the analytics page in Step 6.

---

## Step 5 — Paginated student roster

### The Target

`db/queries/instructor-analytics.ts` (append) — a paginated query listing every enrolled student for a course, using SQL's `LIMIT`/`OFFSET` rather than fetching everyone at once.

### The Concept

Recall the blueprint's explicit call for "paginated database queries" and "accessible data tables." Pagination exists for the same reason Part 4 built loading skeletons instead of blocking renders — a course with 5,000 enrolled students should never require loading all 5,000 rows (and their joined user emails) into memory just to show the first 20.

### The Implementation

#### `db/queries/instructor-analytics.ts` (append)

```ts
export interface StudentRosterEntry {
  userId: string;
  userEmail: string;
  enrolledAt: Date;
  completionPercentage: number;
  status: "ACTIVE" | "COMPLETED" | "CANCELLED";
}

export interface PaginatedRoster {
  students: StudentRosterEntry[];
  totalCount: number;
  page: number;
  pageSize: number;
}

const DEFAULT_PAGE_SIZE = 20;

export async function getStudentRoster(
  courseId: string,
  page: number = 1,
  pageSize: number = DEFAULT_PAGE_SIZE
): Promise<PaginatedRoster> {
  const offset = (page - 1) * pageSize;

  const [rows, totalRow] = await Promise.all([
    db
      .select({
        userId: enrollments.userId,
        userEmail: users.email,
        enrolledAt: enrollments.enrolledAt,
        status: enrollments.status,
        completionPercentage: courseProgress.completionPercentage,
      })
      .from(enrollments)
      .innerJoin(users, eq(users.id, enrollments.userId))
      .innerJoin(
        courseProgress,
        and(eq(courseProgress.userId, enrollments.userId), eq(courseProgress.courseId, enrollments.courseId))
      )
      .where(eq(enrollments.courseId, courseId))
      .orderBy(enrollments.enrolledAt)
      .limit(pageSize)
      .offset(offset),
    db.select({ value: count() }).from(enrollments).where(eq(enrollments.courseId, courseId)),
  ]);

  return {
    students: rows,
    totalCount: totalRow[0]?.value ?? 0,
    page,
    pageSize,
  };
}
```

**Code walkthrough:**

- `Promise.all([rowsQuery, countQuery])` fetches one page of results *and* the total count concurrently — a very common, worthwhile pagination pattern: you almost always need both "show me page 2" and "tell me how many total pages exist" simultaneously, and there's no reason to wait for one before starting the other.
- `.orderBy(enrollments.enrolledAt)` guarantees a **stable, deterministic order** — pagination without an explicit, stable sort order is a subtle, common bug: without it, Postgres offers no guarantee that "page 2" won't occasionally show a row you already saw on "page 1," since row ordering is otherwise unspecified.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 6 — The per-course analytics page

### The Target

`app/instructor/courses/[courseId]/page.tsx`, `.../students/page.tsx`, and `.../analytics/page.tsx` — assembling every query from Steps 4–5 into real, readable instructor screens, protected by Step 1's ownership check.

### The Implementation

First, a shared ownership-check wrapper used by all three sub-pages:

#### `lib/instructor/require-course-ownership.ts`

```ts
import { notFound } from "next/navigation";
import { requireRole } from "@/lib/auth/require-role";
import { verifyCourseOwnership } from "./verify-course-ownership";

// Combines Part 6's role check with Step 1's ownership check, exactly
// mirroring Part 7's getCourseOutline pattern: route-level auth first,
// resource-level auth second, both required, neither sufficient alone.
export async function requireCourseOwnership(courseId: string) {
  const user = await requireRole("INSTRUCTOR");
  const owns = await verifyCourseOwnership(courseId, user.id);
  if (!owns) {
    notFound(); // Same "don't leak existence" principle as Part 7/8/9.
  }
  return user;
}
```

#### `app/instructor/courses/[courseId]/page.tsx`

```tsx
import Link from "next/link";
import { requireCourseOwnership } from "@/lib/instructor/require-course-ownership";
import { getEnrollmentCount } from "@/db/queries/instructor-analytics";
import { client } from "@/sanity/lib/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

interface PageProps {
  params: Promise<{ courseId: string }>;
}

export default async function InstructorCourseOverviewPage({ params }: PageProps) {
  const { courseId } = await params;
  await requireCourseOwnership(courseId);

  const [enrollmentCount, course] = await Promise.all([
    getEnrollmentCount(courseId),
    client.fetch<{ title: string } | null>(`*[_type == "course" && _id == $courseId][0]{ title }`, {
      courseId,
    }),
  ]);

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-6 px-6 py-10">
      <h1 className="text-2xl font-bold text-text-primary">{course?.title ?? "Course"}</h1>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Card>
          <CardHeader>
            <CardTitle>Enrolled students</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-3xl font-bold text-text-primary">{enrollmentCount}</p>
          </CardContent>
        </Card>
      </div>

      <div className="flex gap-3">
        <Link href={`/instructor/courses/${courseId}/students`}>
          <Button variant="primary">View students</Button>
        </Link>
        <Link href={`/instructor/courses/${courseId}/analytics`}>
          <Button variant="outline">View analytics</Button>
        </Link>
      </div>
    </div>
  );
}
```

Now, the student roster page, with pagination and an accessible table:

#### `app/instructor/courses/[courseId]/students/page.tsx`

```tsx
import { requireCourseOwnership } from "@/lib/instructor/require-course-ownership";
import { getStudentRoster } from "@/db/queries/instructor-analytics";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { ProgressBar } from "@/components/ui/progress-bar";
import Link from "next/link";

interface PageProps {
  params: Promise<{ courseId: string }>;
  searchParams: Promise<{ page?: string }>;
}

export default async function InstructorStudentsPage({ params, searchParams }: PageProps) {
  const { courseId } = await params;
  const { page: pageParam } = await searchParams;
  await requireCourseOwnership(courseId);

  const page = Math.max(1, Number(pageParam) || 1);
  const roster = await getStudentRoster(courseId, page);
  const totalPages = Math.ceil(roster.totalCount / roster.pageSize);

  return (
    <div className="mx-auto flex max-w-5xl flex-col gap-6 px-6 py-10">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-text-primary">Students</h1>
        <a href={`/api/instructor/courses/${courseId}/students/export`}>
          <Button variant="outline" size="sm">
            Export CSV
          </Button>
        </a>
      </div>

      <div className="overflow-x-auto rounded-[var(--radius-panel)] border border-border bg-surface">
        {/* A plain HTML <table>, marked up accessibly with <th scope="col">
            — this is a good default for tabular data over a div-based
            "table-like" layout, since screen readers understand real
            tables' row/column relationships natively. */}
        <table className="w-full text-left text-sm">
          <thead className="border-b border-border bg-surface-muted">
            <tr>
              <th scope="col" className="px-4 py-3 font-medium text-text-secondary">Email</th>
              <th scope="col" className="px-4 py-3 font-medium text-text-secondary">Status</th>
              <th scope="col" className="px-4 py-3 font-medium text-text-secondary">Progress</th>
              <th scope="col" className="px-4 py-3 font-medium text-text-secondary">Enrolled</th>
            </tr>
          </thead>
          <tbody>
            {roster.students.map((student) => (
              <tr key={student.userId} className="border-b border-border last:border-0">
                <td className="px-4 py-3 text-text-primary">{student.userEmail}</td>
                <td className="px-4 py-3">
                  <Badge variant={student.status === "COMPLETED" ? "success" : "neutral"}>
                    {student.status}
                  </Badge>
                </td>
                <td className="px-4 py-3 w-48">
                  <ProgressBar value={student.completionPercentage} />
                </td>
                <td className="px-4 py-3 text-text-secondary">
                  {student.enrolledAt.toLocaleDateString()}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <nav className="flex items-center justify-between text-sm text-text-secondary" aria-label="Pagination">
        <span>
          Page {roster.page} of {totalPages || 1} ({roster.totalCount} total)
        </span>
        <div className="flex gap-2">
          <Link href={`?page=${Math.max(1, page - 1)}`}>
            <Button variant="outline" size="sm" disabled={page <= 1}>
              Previous
            </Button>
          </Link>
          <Link href={`?page=${page + 1}`}>
            <Button variant="outline" size="sm" disabled={page >= totalPages}>
              Next
            </Button>
          </Link>
        </div>
      </nav>
    </div>
  );
}
```

Now, the analytics page — completion funnel and average scores:

#### `app/instructor/courses/[courseId]/analytics/page.tsx`

```tsx
import { requireCourseOwnership } from "@/lib/instructor/require-course-ownership";
import {
  getLessonCompletionFunnel,
  getAverageScoresByModule,
  getAtRiskStudents,
} from "@/db/queries/instructor-analytics";
import { client } from "@/sanity/lib/client";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { EmptyState } from "@/components/ui/empty-state";

interface PageProps {
  params: Promise<{ courseId: string }>;
}

interface LessonTitleLookup {
  _id: string;
  title: string;
}

export default async function InstructorAnalyticsPage({ params }: PageProps) {
  const { courseId } = await params;
  await requireCourseOwnership(courseId);

  const lessons = await client.fetch<LessonTitleLookup[]>(
    `*[_type == "course" && _id == $courseId][0].chapters[]->.lessons[]->{ _id, title }`,
    { courseId }
  );
  const lessonIds = lessons.map((l) => l._id);

  const [funnel, averageScores, atRiskStudents] = await Promise.all([
    getLessonCompletionFunnel(courseId),
    getAverageScoresByModule(lessonIds),
    getAtRiskStudents(courseId),
  ]);

  const funnelByLessonId = new Map(funnel.map((f) => [f.lessonId, f.completedCount]));

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-6 px-6 py-10">
      <h1 className="text-2xl font-bold text-text-primary">Analytics</h1>

      <Card>
        <CardHeader>
          <CardTitle>Lesson completion funnel</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-3">
          {lessons.map((lesson) => (
            <div key={lesson._id} className="flex items-center justify-between text-sm">
              <span className="text-text-primary">{lesson.title}</span>
              <Badge variant="neutral">
                {funnelByLessonId.get(lesson._id) ?? 0} completed
              </Badge>
            </div>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Average scores by module</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-3">
          {averageScores.length === 0 ? (
            <p className="text-sm text-text-muted">No graded attempts yet.</p>
          ) : (
            averageScores.map((m) => (
              <div key={m.moduleId} className="flex items-center justify-between text-sm">
                <span className="text-text-primary">{m.moduleId}</span>
                <span className="text-text-secondary">
                  {m.averageScore ?? "—"}% avg ({m.attemptCount} attempts)
                </span>
              </div>
            ))
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>At-risk students</CardTitle>
        </CardHeader>
        <CardContent>
          {atRiskStudents.length === 0 ? (
            <EmptyState title="No at-risk students right now" />
          ) : (
            <ul className="flex flex-col gap-2">
              {atRiskStudents.map((s) => (
                <li key={s.userId} className="flex items-center justify-between text-sm">
                  <span className="text-text-primary">{s.userEmail}</span>
                  <span className="text-text-secondary">
                    {s.completionPercentage}% — inactive since{" "}
                    {s.lastActivityAt.toLocaleDateString()}
                  </span>
                </li>
              ))}
            </ul>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
```

### The Verification

```bash
npm run dev
```

As your instructor account, visit `/instructor/courses/<your-course-id>` (find the ID via Vision). Confirm the enrollment count card shows a real number matching Drizzle Studio's `enrollments` table. Click "View students" and confirm the roster table renders with correct emails, status badges, progress bars, and enrollment dates — test pagination if you have enough test enrollments, or manually add a few more via Drizzle Studio to see "Previous"/"Next" behavior.

Click "View analytics" and confirm the lesson-completion funnel shows both lesson titles with accurate completed counts, the average-scores section shows your quiz/code-exercise `moduleId`s with real computed averages, and — if you have a backdated inactive test enrollment from Part 14 — confirm it appears under "At-risk students."

As a student account, attempt to visit `/instructor/courses/<some-other-instructor-or-nonexistent-course-id>` directly and confirm a 404, proving `requireCourseOwnership` genuinely blocks unauthorized access.

---

## Step 7 — CSV export and manual reminder trigger

### The Target

`app/api/instructor/courses/[courseId]/students/export/route.ts` — a Route Handler streaming a CSV file, and a button on the students page letting an instructor manually trigger Part 14's reminder workflow for a specific at-risk student.

### The Implementation

#### `app/api/instructor/courses/[courseId]/students/export/route.ts`

```ts
import { NextResponse } from "next/server";
import { requireCourseOwnership } from "@/lib/instructor/require-course-ownership";
import { db } from "@/db/client";
import { enrollments, users, courseProgress } from "@/db/schema";
import { and, eq } from "drizzle-orm";

// A minimal, dependency-free CSV field escaper — wraps a value in
// quotes and doubles any internal quote characters, exactly per the CSV
// spec, preventing a student's email (however unlikely) from breaking
// the file's column structure.
function csvField(value: string | number): string {
  const str = String(value);
  return `"${str.replace(/"/g, '""')}"`;
}

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ courseId: string }> }
) {
  const { courseId } = await params;
  await requireCourseOwnership(courseId);

  const rows = await db
    .select({
      email: users.email,
      status: enrollments.status,
      completionPercentage: courseProgress.completionPercentage,
      enrolledAt: enrollments.enrolledAt,
    })
    .from(enrollments)
    .innerJoin(users, eq(users.id, enrollments.userId))
    .innerJoin(
      courseProgress,
      and(eq(courseProgress.userId, enrollments.userId), eq(courseProgress.courseId, enrollments.courseId))
    )
    .where(eq(enrollments.courseId, courseId));

  const header = ["Email", "Status", "Completion %", "Enrolled At"].join(",");
  const lines = rows.map((r) =>
    [csvField(r.email), csvField(r.status), csvField(r.completionPercentage), csvField(r.enrolledAt.toISOString())].join(",")
  );
  const csv = [header, ...lines].join("\n");

  return new NextResponse(csv, {
    status: 200,
    headers: {
      "Content-Type": "text/csv",
      "Content-Disposition": `attachment; filename="course-${courseId}-students.csv"`,
    },
  });
}
```

Now, a manual reminder trigger — reusing Part 14's exact email-sending function directly, outside the cron schedule:

#### `app/instructor/courses/[courseId]/students/actions.ts`

```ts
"use server";

import { requireCourseOwnership } from "@/lib/instructor/require-course-ownership";
import { sendInactivityReminderEmail } from "@/lib/email/send-reminder-email";
import { createNotification } from "@/db/queries/notifications";
import { client } from "@/sanity/lib/client";

export async function sendManualReminder(courseId: string, userId: string, userEmail: string) {
  await requireCourseOwnership(courseId);

  const course = await client.fetch<{ title: string } | null>(
    `*[_type == "course" && _id == $courseId][0]{ title }`,
    { courseId }
  );
  const courseTitle = course?.title ?? "your course";

  await sendInactivityReminderEmail({
    toEmail: userEmail,
    courseTitle,
    courseUrl: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard/courses/${courseId}`,
  });

  await createNotification({
    userId,
    type: "INACTIVITY_REMINDER",
    title: "A reminder from your instructor",
    body: `Your instructor sent you a reminder about ${courseTitle}.`,
    metadata: { courseId, courseTitle, manual: true },
    emailSent: true,
  });
}
```

#### `app/instructor/courses/[courseId]/analytics/page.tsx` (add a reminder button to at-risk students)

```tsx
// Add this import:
import { RemindStudentButton } from "@/components/instructor/remind-student-button";

// Replace the at-risk students <li> content with:
<li key={s.userId} className="flex items-center justify-between text-sm">
  <span className="text-text-primary">{s.userEmail}</span>
  <div className="flex items-center gap-3">
    <span className="text-text-secondary">
      {s.completionPercentage}% — inactive since {s.lastActivityAt.toLocaleDateString()}
    </span>
    <RemindStudentButton courseId={courseId} userId={s.userId} userEmail={s.userEmail} />
  </div>
</li>
```

#### `components/instructor/remind-student-button.tsx`

```tsx
"use client";

import { useState, useTransition } from "react";
import { Button } from "@/components/ui/button";
import { sendManualReminder } from "@/app/instructor/courses/[courseId]/students/actions";

export function RemindStudentButton({
  courseId,
  userId,
  userEmail,
}: {
  courseId: string;
  userId: string;
  userEmail: string;
}) {
  const [sent, setSent] = useState(false);
  const [isPending, startTransition] = useTransition();

  return (
    <Button
      variant="outline"
      size="sm"
      disabled={sent || isPending}
      onClick={() => startTransition(async () => {
        await sendManualReminder(courseId, userId, userEmail);
        setSent(true);
      })}
    >
      {isPending ? "Sending..." : sent ? "Sent ✓" : "Send reminder"}
    </Button>
  );
}
```

### The Verification

```bash
npm run dev
```

Visit `/instructor/courses/<id>/students`, click "Export CSV," and confirm a real CSV file downloads — open it and confirm correct headers and one row per enrolled student, with properly quoted fields.

Visit the analytics page and, next to your backdated at-risk test student, click "Send reminder." Confirm the button changes to "Sending..." then "Sent ✓", and check your terminal for the dev-fallback reminder email log. Confirm a new notification appears in that student's in-app notification bell (sign in as them to check, or inspect the `notifications` table directly in Drizzle Studio) with `metadata.manual: true`.

Run the full verification suite:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Common mistakes

- **`/instructor` redirects to `/dashboard` even for a genuinely promoted instructor** — Confirm the promotion script (Step 2) actually targeted the correct email, and that you signed out and back in (or hard-refreshed) after promotion — `requireRole` re-checks the database on every request, so a stale session isn't the cause, but a stale browser cache of a previous redirect sometimes confuses testing; a full reload resolves it.
- **Course page 404s for a genuine owner** — Confirm the Sanity `instructor.userId` field (Step 1) contains the exact internal UUID, not a Clerk ID — this is the single most common setup mistake in this part, since both are superficially similar-looking strings.
- **`getAverageScoresByModule` returns an empty array despite real attempts existing** — Confirm `lessonIds` isn't empty — this happens if the course's chapters/lessons GROQ traversal in the analytics page doesn't match your actual content structure; verify the query in Vision directly against a real course ID.
- **Pagination "Next" button remains clickable past the last page** — Confirm `totalPages` is computed as `Math.ceil(roster.totalCount / roster.pageSize)`, not `Math.floor`, which would undercount by one whenever the total isn't an exact multiple of the page size.
- **CSV file opens with garbled/misaligned columns in Excel** — Confirm every field genuinely passes through `csvField(...)` before joining — a raw, un-escaped value containing a comma (unlikely for these specific columns, but worth the general habit) would silently shift every subsequent column.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `sanity/schema-types/instructor.ts` (modified), `sanity/lib/queries.ts` (modified), `lib/instructor/verify-course-ownership.ts`, `lib/instructor/require-course-ownership.ts`, `db/promote-user.ts`, `db/queries/instructor-analytics.ts`, `app/instructor/layout.tsx`, `app/instructor/page.tsx`, `app/instructor/courses/[courseId]/page.tsx`, `app/instructor/courses/[courseId]/students/page.tsx`, `app/instructor/courses/[courseId]/students/actions.ts`, `app/instructor/courses/[courseId]/analytics/page.tsx`, `app/api/instructor/courses/[courseId]/students/export/route.ts`, `components/instructor/remind-student-button.tsx`.

```bash
git commit -m "Part 15: instructor dashboard — course ownership verification, paginated student roster, lesson-completion funnel, average scores, at-risk detection, CSV export, manual reminder trigger"
```

---

## Reference: aggregation pushed to the database

| Query | Postgres operation used | Why not compute in JavaScript? |
|---|---|---|
| Enrollment count | `COUNT()` | Avoids loading every row just to count them |
| Completion funnel | `COUNT() ... GROUP BY` | One query instead of one per lesson |
| Average scores | `AVG() ... GROUP BY` | Avoids loading every attempt row into memory |
| At-risk students | `WHERE` + `JOIN` | Filters at the database, returns only genuinely at-risk rows |
| Paginated roster | `LIMIT` / `OFFSET` | Never loads more than one page at a time |

## Reference: the ownership-check pattern, one more time

By now this pattern has appeared for enrollment (Part 7), lessons (Part 9), certificates (Part 13), and now course ownership — worth seeing the shared shape one final time:

```text
1. requireUser() or requireRole() — is anyone/the right kind of person signed in?
2. A resource-specific check — does THIS person own/have access to THIS specific resource?
3. Both checks fail the SAME way (notFound / redirect) — never leak which one failed.
```

---

## What's next

Part 16 is the final part of the core series: automated testing with Vitest and Playwright, a full security review (webhook verification, rate limiting, input-size limits, safe error messages, secrets handling), and production deployment across Vercel, Neon, Sanity, Clerk, and Inngest — culminating in a complete, scripted end-to-end verification journey from account creation through certificate issuance, run against the real, deployed application.
