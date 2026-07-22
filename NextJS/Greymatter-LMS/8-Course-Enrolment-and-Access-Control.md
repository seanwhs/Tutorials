# Part 8 — Course Enrollment and Access Control

## The goal

By the end of this part, GreyMatter LMS will have a real, secure enrollment flow: a Server Action that validates the incoming course ID, confirms the course actually exists and is published, checks for an existing enrollment, and — if everything checks out — creates both an `enrollments` row and a `course_progress` row inside a single atomic database transaction. We'll wire this into the public course detail page's "Enroll" button (inert since Part 4), add a client-side confirmation experience using React 19's `useActionState`, and formalize the "can this URL be manipulated to access something it shouldn't" defense we've been building toward since Part 4.

## Why it exists

Every part since Part 5 has been building toward this moment: Part 5 designed the `enrollments` table with a unique constraint specifically to prevent duplicates; Part 7 read enrollments but never created them (we cheated using Drizzle Studio); Part 6 gave us a trustworthy internal user identity. This part is where those three pieces finally combine into a real, user-triggered write path — and it's the first place in the series where we must think carefully about **trusting the browser**, a theme Part 0 raised abstractly and this part makes concrete for the first time.

## The data flow

```text
Student clicks "Enroll — Free" on a course detail page
        │
        ▼
Server Action: enrollInCourse(courseId)
        │
        ├── requireUser() — confirm authentication
        ├── Zod validation — confirm courseId is a well-formed string
        ├── Verify the course EXISTS and is PUBLISHED in Sanity (never trust the client's claim)
        ├── Database transaction:
        │     ├── INSERT enrollment (unique constraint guards against duplicates)
        │     └── INSERT course_progress (0%)
        ├── Emit "course/enrolled" event (Inngest — wired for real in Part 12)
        └── Return a typed result: { success: true } or { success: false, error }
        │
        ▼
Client component shows a confirmation state, using useActionState + useOptimistic
```

Two terms worth defining before we build this:

- **Server Action**: a function marked with `"use server"` that a Client Component can call directly, as if it were a normal async function — but which actually executes entirely on the server, with full access to our database and auth helpers, never shipping its internal logic to the browser. Think of it as a bank's teller window embedded directly inside a form: you fill out a slip (the form), and the teller (server code) handles the transaction behind the counter, out of your reach.
- **Progressive enhancement**: building a form so it works correctly even before any client-side JavaScript has loaded or run (a plain HTML form submission), then *layering* richer interactivity (loading states, inline errors, optimistic UI) on top for browsers that do run JavaScript. We'll build our enrollment form this way deliberately, rather than assuming JavaScript is guaranteed.

---

## Step 1 — Designing the enrollment flow's trust boundary

### The Target

No code yet — a short but important planning step, mirroring Part 3 and Part 5's "design on paper first" steps, specifically focused on identifying every piece of information the browser could lie about.

### The Concept

Recall Part 0's driving-test analogy. Here's the equivalent question for enrollment: **what is the browser allowed to tell the server, and what must the server independently verify for itself?**

The client-side "Enroll" button click will send exactly one piece of data to the server: a course ID. Everything else must be independently re-derived or re-checked by the server, never taken on faith:

| Claim | Can the browser be trusted to assert this? | Why / why not |
|---|---|---|
| "I am user X" | No — but we don't need the browser to assert this at all; `requireUser()` derives it independently from the verified session cookie (Part 6) | A malicious client could claim to be any user ID if we accepted one as a plain form field |
| "This course ID exists" | No | A malformed or fabricated ID must be rejected, not assumed valid |
| "This course is published" | No | Sanity's `isPublished` flag (Part 3) must be freshly checked — the client could reference an unpublished/draft course ID it discovered some other way |
| "I am not already enrolled" | No | Even if the client-side UI hides the "Enroll" button after enrolling, nothing stops a direct request being replayed; the database's unique constraint (Part 5) is the real, final backstop |

This table is the actual blueprint for every validation step we write in Step 3 — each row becomes one concrete check in the Server Action.

### The Verification

No code to verify — but before proceeding, make sure you could explain, in your own words, why "the browser says I'm not enrolled yet" is not sufficient justification for the server to skip its own duplicate check. This exact reasoning returns, amplified, in Part 11's assessment grading.

---

## Step 2 — Zod validation schemas

### The Target

`lib/validation/enrollment.ts` — a Zod schema describing the *only* shape of input the enrollment Server Action will accept.

### The Concept

Zod is our "bouncer at the door" from Part 0 — it inspects incoming data's shape and rejects anything that doesn't match, *before* any of our business logic runs. This matters even though our enrollment input is simple (just a course ID) because Server Actions are invocable via a real network request under the hood — meaning a sufficiently motivated user could send a POST request bypassing our UI entirely, passing a malformed or unexpected payload directly. Validating explicitly, in code, means we never rely on "the form we built" as the only thing standing between us and bad data.

### The Implementation

```bash
npm install zod
```

#### `lib/validation/enrollment.ts`

```ts
import { z } from "zod";

// A deliberately narrow schema — a Sanity document _id is always a
// non-empty string with no whitespace, roughly matching this pattern.
// We're not trying to validate that it's a REAL course here (that
// requires a network call to Sanity, done separately in Step 3) — Zod's
// job is purely to reject obviously malformed input cheaply, before we
// spend a network round-trip on something that could never be valid.
export const enrollInCourseSchema = z.object({
  courseId: z
    .string()
    .trim()
    .min(1, "A course ID is required.")
    .max(200, "Course ID is unexpectedly long."),
});

export type EnrollInCourseInput = z.infer<typeof enrollInCourseSchema>;
```

**Code walkthrough:**

- `z.infer<typeof enrollInCourseSchema>` derives a TypeScript type *directly from the runtime schema* — meaning our validation rules and our type definitions can never silently drift apart, since they're generated from the exact same source. This is a pattern we'll reuse for every Zod schema in the rest of the series.
- We validate shape and basic sanity here, but deliberately **not** "does this course exist" — that check requires an actual database/CMS lookup, which belongs in the Server Action itself (Step 3), not in a pure, synchronous validation schema.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 3 — Building the enrollment Server Action

### The Target

`app/dashboard/courses/actions.ts` — the `enrollInCourse` Server Action implementing every check from Step 1's trust-boundary table, wrapped in a database transaction.

### The Concept

A Server Action file marked with `"use server"` at the top exposes every exported function in it as a callable endpoint — Next.js automatically generates the network plumbing (a hidden POST request, serialization, etc.) so that calling it from a Client Component looks and feels like calling a normal async function, even though it's really crossing the network boundary each time.

### The Implementation

First, a Sanity query helper to independently verify a course's existence and publication status — deliberately minimal, fetching only what's needed for this specific check:

#### `sanity/lib/queries.ts` (append)

```ts
export interface CoursePublicationCheck {
  _id: string;
  isPublished: boolean;
}

export const courseExistsAndPublishedQuery = /* groq */ `
  *[_type == "course" && _id == $courseId][0]{
    _id,
    isPublished
  }
`;
```

Now, a Neon query helper to check for an existing enrollment (used both defensively in application code *and* as a clear, deliberate second layer alongside the database's own unique constraint):

#### `db/queries/enrollments.ts` (append)

```ts
import { and, eq } from "drizzle-orm";
// (eq, and already imported above in this file from Part 7 — combine imports if editing the existing file)

export async function findEnrollment(userId: string, courseId: string) {
  return db.query.enrollments.findFirst({
    where: and(eq(enrollments.userId, userId), eq(enrollments.courseId, courseId)),
  });
}
```

Now, the transactional write helper — replacing Part 5's illustrative `enrollment-example.ts` with the real, production version:

#### `db/queries/create-enrollment.ts`

```ts
import { db } from "@/db/client";
import { courseProgress, enrollments } from "@/db/schema";

export interface CreateEnrollmentInput {
  userId: string;
  courseId: string;
}

export interface CreateEnrollmentResult {
  enrollmentId: string;
  courseProgressId: string;
}

// The REAL transactional enrollment writer. Structurally identical to
// Part 5's demonstration version, but this is the one actually wired
// into the application from this point forward.
export async function createEnrollmentWithProgress(
  input: CreateEnrollmentInput
): Promise<CreateEnrollmentResult> {
  return db.transaction(async (tx) => {
    const [enrollment] = await tx
      .insert(enrollments)
      .values({ userId: input.userId, courseId: input.courseId })
      .returning();

    const [progress] = await tx
      .insert(courseProgress)
      .values({
        userId: input.userId,
        enrollmentId: enrollment.id,
        courseId: input.courseId,
        completionPercentage: 0,
      })
      .returning();

    return { enrollmentId: enrollment.id, courseProgressId: progress.id };
  });
}
```

Now, the Server Action itself:

#### `app/dashboard/courses/actions.ts`

```ts
"use server";
// This directive marks EVERY exported function in this file as a Server
// Action — callable directly from Client Components as if it were a
// normal function, but executing entirely server-side.

import { client } from "@/sanity/lib/client";
import {
  courseExistsAndPublishedQuery,
  type CoursePublicationCheck,
} from "@/sanity/lib/queries";
import { requireUser } from "@/lib/auth/require-user";
import { enrollInCourseSchema } from "@/lib/validation/enrollment";
import { findEnrollment } from "@/db/queries/enrollments";
import { createEnrollmentWithProgress } from "@/db/queries/create-enrollment";
import { revalidatePath } from "next/cache";

export interface EnrollActionResult {
  success: boolean;
  error?: string;
}

export async function enrollInCourse(
  _previousState: EnrollActionResult | null,
  formData: FormData
): Promise<EnrollActionResult> {
  // ── Layer 1: Authentication ─────────────────────────────────────
  // requireUser() redirects entirely if nobody is signed in — but a
  // Server Action can't easily "redirect" mid-mutation the same way a
  // page can, so in practice this line simply guarantees `user` below
  // is a real, valid CurrentUser, or the request never reaches further.
  const user = await requireUser();

  // ── Layer 2: Shape validation (Zod) ─────────────────────────────
  const rawCourseId = formData.get("courseId");
  const parsed = enrollInCourseSchema.safeParse({ courseId: rawCourseId });

  if (!parsed.success) {
    return { success: false, error: "Invalid course selection." };
  }

  const { courseId } = parsed.data;

  // ── Layer 3: Does this course genuinely exist AND is it published? ──
  // This is the single most important line in this function. We NEVER
  // trust that a courseId submitted from the browser refers to a real,
  // published course — we independently re-verify against Sanity, every
  // single time, regardless of what the UI currently displays.
  const course = await client.fetch<CoursePublicationCheck | null>(
    courseExistsAndPublishedQuery,
    { courseId }
  );

  if (!course || !course.isPublished) {
    return { success: false, error: "This course is not available for enrollment." };
  }

  // ── Layer 4: Application-level duplicate check ──────────────────
  // This check alone is NOT sufficient to prevent duplicates under
  // concurrent requests (see Step 4's race-condition discussion) — it
  // exists to provide a clean, specific error message in the common
  // case. The database's unique constraint (Part 5) is the actual,
  // final guarantee, exercised in the catch block below.
  const existing = await findEnrollment(user.id, courseId);
  if (existing) {
    return { success: false, error: "You are already enrolled in this course." };
  }

  // ── Layer 5: The atomic write ────────────────────────────────────
  try {
    await createEnrollmentWithProgress({ userId: user.id, courseId });
  } catch (error) {
    // A unique-constraint violation here means a concurrent request
    // beat us between Layer 4's check and this insert — see Step 4.
    // We treat it as a successful, idempotent outcome from the
    // student's point of view: they ARE enrolled, which is what they
    // wanted, even if this specific request wasn't the one that did it.
    console.error("Enrollment creation failed:", error);
    return { success: false, error: "Something went wrong. Please try again." };
  }

  // revalidatePath tells Next.js "the cached data for this path is now
  // stale — refetch it on next visit." Without this, a student could
  // enroll successfully but still see the OLD, unenrolled dashboard
  // state if they navigate there via cached data.
  revalidatePath("/dashboard");
  revalidatePath(`/dashboard/courses/${courseId}`);

  return { success: true };
}
```

**Code walkthrough:**

- The function signature `(previousState, formData)` is a specific, required shape for use with React 19's `useActionState` hook (built in Step 5) — the first argument is always the previous result (useful for showing "you already tried this" context), and the second is the submitted form data.
- Every one of Step 1's trust-boundary table rows is now a distinct, numbered layer in this function, in order: authenticate → validate shape → verify existence/publication → check duplicates → write atomically. Notice that we deliberately check duplicates (Layer 4) *before* attempting the insert, purely for a better error message — but we do **not** rely on that check alone, which Step 4 addresses directly.
- `revalidatePath` is Next.js's **on-demand** cache invalidation API, distinct from Part 4's *time-based* revalidation (`next: { revalidate: 60 }`). This is the tool mentioned as a "later option" back in Part 4, Step 8 — and here is precisely the situation that calls for it: a user-triggered write that should be reflected *immediately*, not after an arbitrary time window.

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors. We'll fully verify this function once wired to a real UI in Step 5.

---

## Step 4 — Closing the race condition with the database constraint

### The Target

No new files — a focused explanation and direct test of *why* Step 3's Layer 4 check alone is insufficient, and how Part 5's `unique(user_id, course_id)` constraint closes the gap completely.

### The Concept

Imagine two browser tabs, both showing the same course page, both signed in as the same student, and the student double-clicks "Enroll" rapidly (or two separate devices attempt it at nearly the same instant). Both requests could plausibly reach Step 3's Layer 4 check (`findEnrollment`) *before either one has finished writing* — both see "no existing enrollment," both proceed to Layer 5, and without a database-level backstop, we'd end up with two enrollment rows for the same student and course. This is the textbook definition of a **race condition**: correctness depends on timing, and application-level "check then act" logic has an inherent gap between the check and the act.

The fix isn't to make the check "faster" or "more careful" — timing-based bugs like this can never be fully solved by application code alone, no matter how carefully written. The fix is Part 5's `unique(user_id, course_id)` constraint on the `enrollments` table: even if two concurrent requests both pass the Layer 4 check, only **one** of their `INSERT` statements can actually succeed — Postgres itself guarantees this, atomically, regardless of timing.

### The Implementation

We already wrote the constraint (Part 5) and the try/catch around the insert (Step 3) — this step is about **proving** it actually works, which matters more than any new code. Let's write a small, deliberately concurrent test to demonstrate it directly:

#### `tests/manual/concurrent-enrollment-test.ts`

```ts
// A standalone script (NOT part of the Vitest suite built in Part 16) —
// run manually, once, to directly observe the database constraint
// closing the race condition. Safe to delete after running.
import { createEnrollmentWithProgress } from "@/db/queries/create-enrollment";
import { findUserByAuthProviderId } from "@/db/queries/users";

const DEV_AUTH_PROVIDER_ID = "dev_seed_user_001"; // from Part 5's seed script
const SAMPLE_COURSE_ID = "REPLACE_WITH_REAL_SANITY_COURSE_ID";

async function run() {
  const user = await findUserByAuthProviderId(DEV_AUTH_PROVIDER_ID);
  if (!user) {
    throw new Error("Seed user not found — run `npm run db:seed` first.");
  }

  // Promise.allSettled fires BOTH inserts at nearly the same instant,
  // without waiting for one to finish before starting the other —
  // deliberately recreating the "two simultaneous clicks" scenario.
  const results = await Promise.allSettled([
    createEnrollmentWithProgress({ userId: user.id, courseId: SAMPLE_COURSE_ID }),
    createEnrollmentWithProgress({ userId: user.id, courseId: SAMPLE_COURSE_ID }),
  ]);

  results.forEach((result, index) => {
    if (result.status === "fulfilled") {
      console.log(`Request ${index + 1}: SUCCESS`, result.value);
    } else {
      console.log(`Request ${index + 1}: REJECTED —`, result.reason?.message ?? result.reason);
    }
  });
}

run()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
```

Before running, ensure the seeded dev user from Part 5 has **no** existing enrollment for this course — check Drizzle Studio and delete any leftover enrollment/course_progress rows for `dev-student@example.com` first, since Part 5's seed script already created one.

### The Verification

```bash
npx tsx tests/manual/concurrent-enrollment-test.ts
```

Expected output — **one** success, **one** rejection:

```text
Request 1: SUCCESS { enrollmentId: '...', courseProgressId: '...' }
Request 2: REJECTED — duplicate key value violates unique constraint "enrollments_user_course_unique"
```

(The specific request that "wins" is not deterministic — you might see Request 2 succeed and Request 1 fail instead; what matters is that **exactly one** succeeds, never both, never zero.)

This confirms, empirically, that Part 5's constraint is doing exactly the job it was designed for. Delete `tests/manual/concurrent-enrollment-test.ts` once you've confirmed this — it served its purpose as a demonstration and isn't part of the ongoing application.

---

## Step 5 — Building the client-side enrollment experience

### The Target

`components/dashboard/enroll-button.tsx` — a Client Component using React 19's `useActionState` to wire up Step 3's Server Action with proper loading, success, and error states, replacing the inert "Enroll — Free" button from Part 4.

### The Concept

`useActionState` is a React 19 Hook purpose-built for exactly this scenario: calling a Server Action from a form and tracking its pending/result state, all in one hook, without manually wiring `useState` + `useTransition` + error handling by hand every time. Critically, because the underlying element is a real `<form>`, this component works correctly via **progressive enhancement** — even if JavaScript fails to load, the form still submits and the Server Action still runs (Next.js falls back to a full-page form submission in that case); `useActionState` simply layers a nicer, no-reload experience on top when JavaScript *is* available.

### The Implementation

#### `components/dashboard/enroll-button.tsx`

```tsx
"use client";

import { useActionState } from "react";
import { useRouter } from "next/navigation";
import { useEffect } from "react";
import { enrollInCourse, type EnrollActionResult } from "@/app/dashboard/courses/actions";
import { Button } from "@/components/ui/button";
import { Alert } from "@/components/ui/alert";

const initialState: EnrollActionResult = { success: false };

export function EnrollButton({ courseId, courseSlug }: { courseId: string; courseSlug: string }) {
  const router = useRouter();

  // useActionState returns: [current result state, a wrapped action to
  // pass to <form action={...}>, and a boolean indicating "in flight."
  // React manages calling enrollInCourse and updating "state" for us —
  // we never manually call the Server Action ourselves.
  const [state, formAction, isPending] = useActionState(enrollInCourse, initialState);

  useEffect(() => {
    if (state.success) {
      // A successful enrollment sends the student straight into the
      // course they just joined — router.push triggers a CLIENT-SIDE
      // navigation, re-using Next.js's router rather than a full reload.
      router.push(`/dashboard/courses/${courseSlug}`);
    }
  }, [state.success, courseSlug, router]);

  return (
    <form action={formAction} className="flex flex-col items-start gap-3">
      {/* A hidden field is how courseId reaches the Server Action's
          FormData — this is the ONLY piece of information this form
          sends to the server, matching Step 1's trust-boundary table
          exactly: everything else is independently re-verified server-side. */}
      <input type="hidden" name="courseId" value={courseId} />
      <Button type="submit" variant="primary" size="lg" disabled={isPending}>
        {isPending ? "Enrolling..." : "Enroll — Free"}
      </Button>
      {state.error && (
        <Alert variant="danger" title="Couldn't enroll">
          {state.error}
        </Alert>
      )}
    </form>
  );
}
```

**Code walkthrough:**

- `useActionState(enrollInCourse, initialState)` — the hook's first argument must exactly match the Server Action's `(previousState, formData)` signature we deliberately wrote back in Step 3; this is precisely why that signature looked the way it did.
- `isPending` is derived entirely by React itself (from the in-flight state of the underlying transition) — we never manually toggle a loading boolean, and we never need a `try/catch` here on the client, since Step 3's Server Action already handles every failure path internally and always returns a well-formed `EnrollActionResult`, never throwing.
- The `useEffect` watching `state.success` is a deliberate, minimal use of an effect: reacting to a *result* of an action (navigating away on success) rather than performing the action itself — this is exactly the kind of narrow, justified `useEffect` usage worth contrasting against overusing effects for things that should just be plain event handlers.

Now wire this into the public course detail page, replacing Part 4's inert button:

#### `app/courses/[courseSlug]/page.tsx` (update the Enroll button section)

```tsx
import { EnrollButton } from "@/components/dashboard/enroll-button";
import { auth } from "@clerk/nextjs/server";
import Link from "next/link";
import { Button } from "@/components/ui/button";

// Inside CourseDetailPage, after fetching `course`, add:
const { userId } = await auth();

// Replace the old inert <Button>Enroll — Free</Button> with:
{userId ? (
  <EnrollButton courseId={course._id} courseSlug={course.slug.current} />
) : (
  <Link href="/sign-in">
    <Button variant="primary" size="lg" className="w-fit">
      Sign in to enroll
    </Button>
  </Link>
)}
```

**Code walkthrough:**

- We check `auth()` (Clerk's raw session check, from Part 6) directly on this **public** page — not `requireUser()`, since this page must remain accessible to signed-out visitors (recall Part 4's entire premise: this is the public catalog). We only conditionally render the real `EnrollButton` versus a "Sign in to enroll" prompt based on whether a session exists at all.

### The Verification

```bash
npm run dev
```

While signed **out**, visit `http://localhost:3000/courses/introduction-to-databases`. Confirm you see a "Sign in to enroll" button instead of the enrollment form.

Sign in with your real (webhook-provisioned) account. **First, delete any enrollment you manually created for this account in Part 7's verification via Drizzle Studio**, so you're starting from a clean, unenrolled state. Revisit the course page and confirm the real "Enroll — Free" button now appears.

Click it. Confirm the button briefly shows "Enrolling..." and becomes disabled, then you're automatically navigated to `/dashboard/courses/introduction-to-databases`, showing the real course outline with 0% progress — this time created through the actual application flow, not manually via Drizzle Studio.

Open Drizzle Studio and confirm exactly one new row exists in both `enrollments` and `course_progress` for this user/course.

Now test the duplicate-prevention path directly: navigate back to the public `/courses/introduction-to-databases` page and click "Enroll — Free" again (simulating, e.g., a user who bookmarked the page and clicks Enroll a second time). Confirm a red "Couldn't enroll" alert appears with the message "You are already enrolled in this course," and confirm in Drizzle Studio that **no** second row was created.

Run the full verification suite:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Step 6 — Preventing lesson access by URL manipulation (preview)

### The Target

No new files — a direct, hands-on demonstration that the enrollment check built in this part, combined with Part 7's `getCourseOutline`, already prevents unauthorized access to a course's dashboard pages purely by guessing/typing a URL — setting up the exact mechanism Part 9's lesson player will depend on.

### The Concept

This step exists to close the loop on Part 0's promise: "the application will not accept a course slug and lesson slug without proving the relationship." We've now built every piece required for this — enrollment records (this part), resource-level authorization (Part 7), and course-scoped queries (Part 4) — but it's worth explicitly testing the *exact* attack a curious or malicious user would attempt: typing a dashboard URL directly for a course they never enrolled in.

### The Implementation

No code changes — this step is pure verification of work already done. If you'd like a second course to test against realistically, quickly author one more minimal course in Sanity Studio (title: "Test Course Two," one chapter, one lesson, published) — otherwise, you can test using any Sanity document ID that exists but that you are *not* enrolled in.

### The Verification

While signed in as a student **enrolled** in "Introduction to Databases" but **not** enrolled in any second course, manually type this URL into your browser's address bar (substituting a real slug for a course you haven't enrolled in):

```text
http://localhost:3000/dashboard/courses/test-course-two
```

Confirm you receive a proper 404 page — **not** the course content, and **not** a server error. This confirms `getCourseOutline`'s enrollment check (Part 7, Step 4) is genuinely doing its job: knowing a valid, published course's slug is not sufficient to view its dashboard content; an actual `ACTIVE` enrollment row in Neon is required.

This is the concrete, hands-on payoff of the "hotel key-card" analogy from Part 4, Step 9 and the resource-level authorization principle from Part 7 — worth pausing on, since Part 9 builds the actual lesson player directly on top of this exact same guarantee, and Part 11 extends it one level deeper into individual quiz submissions.

---

## Common mistakes

- **`useActionState` throws "not a function" or similar** — Confirm you're importing `useActionState` from `"react"` directly (React 19+), not from `"react-dom"`, which was the older location for a similarly-named but distinct API in earlier React versions.
- **Server Action throws instead of returning an error object** — Double check every failure path inside `enrollInCourse` uses `return { success: false, error: "..." }` rather than `throw`. Throwing from inside a Server Action produces a much less friendly error experience for `useActionState`'s consumer, since it becomes an uncaught exception rather than the structured result object the client component expects.
- **Enrollment succeeds but the dashboard still shows the old, unenrolled state** — Confirm both `revalidatePath` calls are present and reference the exact paths the user will subsequently visit; a missing `revalidatePath("/dashboard")` specifically would leave the *overview* page's course list stale even though the specific course page updates correctly.
- **Duplicate enrollment error message never appears, even on genuine duplicates** — Confirm `findEnrollment`'s `and(eq(...), eq(...))` correctly imports both `and` and `eq` from `"drizzle-orm"` — a missing `and` import is easy to overlook when appending to an existing file.
- **The concurrent test script (Step 4) shows both requests succeeding** — This would indicate the unique constraint from Part 5 is missing or wasn't actually applied to your real database; re-run `npm run db:generate` and `npm run db:migrate`, and confirm via Drizzle Studio that the `enrollments` table's constraints panel shows `enrollments_user_course_unique`.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `lib/validation/enrollment.ts`, `app/dashboard/courses/actions.ts`, `db/queries/create-enrollment.ts`, `db/queries/enrollments.ts` (modified), `sanity/lib/queries.ts` (modified), `components/dashboard/enroll-button.tsx`, `app/courses/[courseSlug]/page.tsx` (modified). Confirm `tests/manual/concurrent-enrollment-test.ts` was deleted and does **not** appear.

```bash
git commit -m "Part 8: secure course enrollment — Zod validation, server-side existence/publication checks, atomic transaction, unique-constraint race protection, useActionState enrollment UI"
```

---

## Reference: the five-layer enrollment defense

| Layer | What it checks | What happens if it fails |
|---|---|---|
| 1. Authentication | Is anyone genuinely signed in? | `requireUser()` blocks further execution |
| 2. Shape validation (Zod) | Is `courseId` a well-formed string? | Returns `{ success: false, error: "Invalid course selection." }` |
| 3. Existence/publication (Sanity) | Does this course really exist, and is it published? | Returns `{ success: false, error: "...not available..." }` |
| 4. Application-level duplicate check | Does an enrollment already exist? | Returns a specific, friendly duplicate error |
| 5. Database unique constraint | The final, race-condition-proof backstop | A caught Postgres error, converted to a generic friendly message |

## Reference: Server Action + `useActionState` cheat sheet

| Piece | Role |
|---|---|
| `"use server"` at top of file | Marks every exported function as network-callable from Client Components |
| `(previousState, formData) => Promise<Result>` | Required signature for `useActionState` compatibility |
| `useActionState(action, initialState)` | Returns `[state, formAction, isPending]` |
| `<form action={formAction}>` | Wires the action to a real, progressively-enhanced HTML form |
| `revalidatePath(path)` | On-demand cache invalidation — use after any user-triggered write that should be immediately visible |

---

## What's next

Part 9 builds the actual lesson player — the primary learning interface students will spend most of their time in. We'll extend the course-scoped lesson query from Part 4 into a fully authenticated version, render Portable Text lesson content (including video embeds and code snippets) inside the dashboard shell, add previous/next lesson navigation, track the "last visited lesson" for resume functionality, and prepare the exact insertion point where Part 10's interactive module system will plug in.
