# Part 4: Building the Secure State & Progress Transaction Engine

Picking up exactly where Part 3 left off: you have a working "SQL Sandbox" plugin that calls `onComplete` with a `score` and `moduleState`, currently just logged to the console inside `module-renderer.tsx`. Now we build the real backend that securely records that completion — replacing the placeholder `console.log` with a genuine database write.

## 4.0 Why We Can't Just "Trust" the Plugin's Score

**The Concept:** Right now, any student could open their browser's DevTools and manually call `onComplete({ score: 100 })` without ever writing a correct SQL query — the plugin runs entirely in the browser, which is fundamentally not a trusted environment. Think of it like a self-checkout kiosk at a grocery store: the kiosk *displays* a price, but the actual charge to your card only happens after the store's backend system verifies the transaction. Similarly, we never let the browser directly write to our database. Instead, every completion must pass through a **Server Action** — a function that runs exclusively on the server — which independently re-verifies that the write is legitimate before touching the database.

For high-stakes situations (like graded exams), Greymatter's architecture actually goes a step further using a **cryptographic hash verification** handshake: the server issues a single-use signed token (a "salt") when the lesson loads, and the plugin must return that exact salt back alongside its score. The server then recalculates the hash itself to confirm the score was legitimately earned, rather than spoofed [1]:

```
1. Next.js Server ──(Generates Unique Lesson Salt)──► React Plugin Client
│
(Solves Challenge)
│
▼
2. Next.js Server ◄──(Submits Response + Salt Hash)── React Plugin Client
│
[Server recalculates hash to verify score was legitimately earned]
```

For this tutorial, we'll implement the simpler, foundational defense layer that every plugin gets for free regardless of stakes: **enrollment verification inside a database transaction**. This guarantees a student can never have progress recorded for a course they were never enrolled in — a prerequisite check that must happen atomically alongside the actual progress write.

---

## Step 1: Write the Progress Server Action

**The Target:** A Next.js Server Action at `app/actions/progress.ts` that accepts a completion payload and writes it to Neon via Prisma.

**The Concept:** A **Server Action** is a regular-looking async function marked with `"use server"` at the top — but Next.js treats it specially, generating a secure API endpoint behind the scenes so client components can call it directly, as if it were a local function, without you hand-writing a `fetch()` call or an API route. Think of it like a hotel's room service button: you press it (call the function) and the button itself doesn't cook your food — it silently triggers a request to the kitchen (the server), which handles everything out of your sight.

**The Implementation:**

#### `app/actions/progress.ts`
```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { PrismaClient } from "@prisma/client";
import { revalidateTag } from "next/cache";

const prisma = new PrismaClient();

interface CompleteLessonPayload {
  courseId: string;
  lessonId: string;
  score?: number;
  moduleState?: Record<string, unknown>;
}

interface ActionResult {
  success: boolean;
  error?: string;
}

export async function completeLesson(
  payload: CompleteLessonPayload
): Promise<ActionResult> {
  // Step 1: Identify the caller server-side. We never trust a userId
  // passed in from the client — Clerk's auth() reads the verified
  // session cookie directly on the server.
  const { userId } = await auth();

  if (!userId) {
    return { success: false, error: "You must be signed in to record progress." };
  }

  const { courseId, lessonId, score, moduleState } = payload;

  if (!courseId || !lessonId) {
    return { success: false, error: "Missing courseId or lessonId." };
  }

  try {
    // Step 2: Wrap the enrollment check and the progress write in a
    // single atomic transaction — built out fully in Step 2 below.
    await prisma.$transaction(async (tx) => {
      const enrollment = await tx.enrollment.findUnique({
        where: {
          userId_courseId: { userId, courseId },
        },
      });

      if (!enrollment) {
        throw new Error(
          "Transaction Failed: Student has not enrolled in the parent course."
        );
      }

      await tx.progress.upsert({
        where: {
          userId_lessonId: { userId, lessonId },
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
          completed: true,
          completedAt: new Date(),
          score,
          moduleState: moduleState || {},
        },
      });
    });

    // Step 3: Invalidate any cached data tagged with this course so
    // subsequent page loads reflect the fresh progress state.
    revalidateTag(`progress-${courseId}`);

    return { success: true };
  } catch (error: any) {
    console.error("CRITICAL: Database transaction rollback executed:", error.message);
    return {
      success: false,
      error: error.message ?? "Failed to save lesson progress.",
    };
  }
}
```

Notice the very first thing this function does is call `auth()` from Clerk — it **never** trusts a `userId` field sent from the browser, because a malicious client could simply put someone else's ID in that field. The only trustworthy source of "who is making this request" is the server-verified session.

**The Verification:**

```bash
npx tsc --noEmit
```

Confirm no type errors are reported for `app/actions/progress.ts`. We can't fully test this yet in the browser since nothing calls it — that wiring happens in Step 3.

Commit:

```bash
git add app/actions/progress.ts
git commit -m "feat: add completeLesson Server Action with auth check"
```

---

## Step 2: Understand the Prisma Transaction Guarantee

**The Target:** No new code in this step — a focused explanation of the `prisma.$transaction(...)` block you just wrote, since it's the most important line in this entire Part.

**The Concept:** A **database transaction** is an "all-or-nothing" unit of work — like an ATM withdrawal, where "deduct from your account" and "dispense cash" must either both succeed or both fail; the machine should never deduct money without also giving you cash. Inside our `$transaction` callback, we do two things in sequence:

1. `tx.enrollment.findUnique(...)` — check that an `Enrollment` row exists linking this `userId` to this `courseId`.
2. `tx.progress.upsert(...)` — if (and only if) that enrollment exists, write or update the `Progress` row.

If step 1 finds no enrollment, we `throw new Error(...)` — and because we're inside `prisma.$transaction`, throwing an error automatically triggers a **rollback**: nothing gets written to the database at all, even though we never explicitly wrote "undo" logic ourselves. This is the mechanism that makes it structurally impossible for a student to accumulate progress on a course they never enrolled in, no matter what payload a malicious client sends. Note also that both the enrollment check and the progress write share the exact `userId`/`courseId`/`lessonId` shape defined back in your `User`, `Enrollment`, and `Progress` Prisma models, referenced by the `@@unique([userId, courseId])` and `@@unique([userId, lessonId])` constraints [1].

We'll revisit this exact mechanism in more depth in **Appendix C: Code Segment Breakdown** at the end of the series.

---

## Step 3: Wire the Server Action into the Module Renderer

**The Target:** Replace the temporary `console.log` inside `components/plugins/module-renderer.tsx` (built in Part 3) with a real call to `completeLesson`.

**The Concept:** This is the literal hand-off point between the "untrusted browser" world and the "trusted server" world. The plugin itself never talks to Prisma or the database directly — it only ever calls a function that Next.js has wired up to securely tunnel the request to the server, no differently in the component's code than calling any other async function.

**The Implementation:**

#### `components/plugins/module-renderer.tsx` (updated)
```tsx
"use client";

import { resolveModule } from "@/lib/plugin-sdk/registry";
import type { RawCustomModuleBlock } from "@/lib/plugin-sdk/types";
import { completeLesson } from "@/app/actions/progress";
import { useTransition } from "react";

interface ModuleRendererProps {
  block: RawCustomModuleBlock;
  courseId: string;
  lessonId: string;
}

export function ModuleRenderer({ block, courseId, lessonId }: ModuleRendererProps) {
  // useTransition lets us call the Server Action without blocking the UI —
  // isPending tells us whether the request is still in flight.
  const [isPending, startTransition] = useTransition();

  const PluginComponent = resolveModule(block.moduleType);

  if (!PluginComponent) {
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
        // Wrapped in startTransition so React can mark this as a
        // non-urgent background update rather than a blocking one.
        startTransition(async () => {
          const response = await completeLesson({
            courseId,
            lessonId,
            score: result.score,
            moduleState: result.moduleState,
          });

          if (!response.success) {
            // In production, replace this with a toast/notification component.
            console.error("Failed to save progress:", response.error);
          }
        });
      }}
    />
  );
}
```

**The Verification:**

1. Confirm your test user (from Part 2) actually has an `Enrollment` row for the test course — since we haven't built an enrollment UI yet, insert one manually via Prisma Studio:

```bash
npx prisma studio
```

Open the `Enrollment` table and click **Add document**, filling in your test `userId` (found in the `User` table) and the `courseId` matching your Sanity course's `_id` or slug (whichever your lesson page passes as `courseId` — check `app/dashboard/courses/[courseSlug]/lessons/[lessonSlug]/page.tsx` from Part 3).

2. Start your dev server and navigate to the test lesson page:

```bash
npm run dev
```

3. Complete the SQL Sandbox with the correct query. Open your browser's Network tab (or just watch the terminal running `npm run dev`) — you should see no errors, and no `"Failed to save progress"` log in the console.

4. Confirm the write actually landed by refreshing Prisma Studio's `Progress` table — you should see a new row with `completed: true`, a `score` of `100`, and a `moduleState` JSON object containing your submitted query.

5. **Negative test:** Delete the `Enrollment` row you created in step 1 via Prisma Studio, then complete the SQL Sandbox again on a *fresh* lesson (or clear the existing `Progress` row first so the upsert has nothing to update). This time, check your terminal running `npm run dev` — you should see the logged error:

```
CRITICAL: Database transaction rollback executed:  Transaction Failed: Student has not enrolled in the parent course.
```

This confirms the exact failure path built into the Server Action's transaction: when `tx.enrollment.findUnique(...)` returns `null`, we `throw new Error('Transaction Failed: Student has not enrolled in the parent course.')`, which is caught by the surrounding `try/catch`, logged, and returned to the client as `{ success: false, error: '...' }` — and critically, the `tx.progress.upsert(...)` call never executes at all, because the transaction rolled back before reaching it [1].

6. Confirm this in Prisma Studio directly: refresh the `Progress` table and verify **no new row was written** for that lesson — the rollback means the database was left completely untouched, not partially written.

7. Re-add the `Enrollment` row in Prisma Studio, retry the SQL Sandbox completion, and confirm the `Progress` row now appears correctly — proving the transaction only succeeds when both conditions (valid enrollment + correct upsert) are satisfied together.

Once both the positive and negative paths are confirmed, commit this checkpoint:

```bash
git add components/plugins/module-renderer.tsx
git commit -m "feat: wire completeLesson Server Action into module renderer with enrollment-guarded transaction"
```

---

## Step 3.5: Harden the Server Action with Score Validation

**The Target:** Add a bounds check to `app/actions/progress.ts` so a malicious or buggy plugin can never submit an out-of-range score.

**The Concept:** Recall that `completeLesson` already refuses to trust the client's `userId` — it only trusts Clerk's server-verified session. But there's a second, equally important boundary we haven't guarded yet: the `score` value itself. A plugin is just browser JavaScript, and browser JavaScript can be tampered with (someone could edit the SQL Sandbox's code in DevTools to call `onComplete({ score: 9999 })`). The transaction boundary described in the architecture explicitly checks this exact condition before ever touching the database — throwing a "Transaction Integrity Violation" if the score falls outside 0–100 [1]:

```typescript
if (score < 0 || score > 100) {
  throw new Error('Transaction Integrity Violation: Score bound out of index.');
}
```

**The Implementation:** Update the existing Server Action to include this guard immediately after the auth check, before the transaction ever begins.

#### `app/actions/progress.ts` (updated)
```typescript
"use server";

import { auth } from "@clerk/nextjs/server";
import { PrismaClient } from "@prisma/client";
import { revalidateTag } from "next/cache";

const prisma = new PrismaClient();

interface CompleteLessonPayload {
  courseId: string;
  lessonId: string;
  score?: number;
  moduleState?: Record<string, unknown>;
}

interface ActionResult {
  success: boolean;
  error?: string;
}

export async function completeLesson(
  payload: CompleteLessonPayload
): Promise<ActionResult> {
  const { userId } = await auth();

  if (!userId) {
    return { success: false, error: "You must be signed in to record progress." };
  }

  const { courseId, lessonId, score, moduleState } = payload;

  if (!courseId || !lessonId) {
    return { success: false, error: "Missing courseId or lessonId." };
  }

  // Integrity guard: even though the plugin is expected to only ever send
  // 0-100, we never trust that promise — the server independently rejects
  // anything outside the valid range before it can reach the transaction [1].
  if (score !== undefined && (score < 0 || score > 100)) {
    return {
      success: false,
      error: "Transaction Integrity Violation: Score bound out of index.",
    };
  }

  try {
    await prisma.$transaction(async (tx) => {
      const enrollment = await tx.enrollment.findUnique({
        where: {
          userId_courseId: { userId, courseId },
        },
      });

      if (!enrollment) {
        throw new Error(
          "Transaction Failed: Student has not enrolled in the parent course."
        );
      }

      await tx.progress.upsert({
        where: {
          userId_lessonId: { userId, lessonId },
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
          completed: true,
          completedAt: new Date(),
          score,
          moduleState: moduleState || {},
        },
      });
    });

    revalidateTag(`progress-${courseId}`);
    return { success: true };
  } catch (error: any) {
    console.error("CRITICAL: Database transaction rollback executed:", error.message);
    return {
      success: false,
      error: error.message ?? "Failed to save lesson progress.",
    };
  }
}
```

**The Verification:** Temporarily edit `components/plugins/sql-sandbox/index.tsx`'s `onComplete` call to send `score: 500` instead of `score: 100`, save, and re-run the SQL Sandbox test from the browser. Check your terminal — you should see the logged error `Transaction Integrity Violation: Score bound out of index.`, and confirm in Prisma Studio that no `Progress` row was written or updated. Revert the test edit back to `score: 100` afterward.

Commit:

```bash
git add app/actions/progress.ts
git commit -m "feat: harden completeLesson Server Action with score bounds validation"
```

This confirms two layers of defense are now in place inside `completeLesson`: the server never trusts the client-supplied `userId` (it uses Clerk's verified session instead), and it never trusts an out-of-range `score`, rejecting the request before the transaction ever begins.

---

## Step 4: Integrate React 19's `useOptimistic` for Instant Checkmarks

**The Target:** Update the sidebar (built in Part 2) so that when a student completes a lesson, its checkmark appears **instantly** in the UI — before the server has even confirmed the write succeeded — and automatically reverts if the write fails.

**The Concept:** Normally, a UI update waits for a round trip: click → send request → wait for server → wait for database → get response → *then* update the screen. On a slow connection, this can feel sluggish, like a light switch with a two-second delay before the bulb turns on. React 19's `useOptimistic` hook lets us show the "optimistic" (assumed-successful) result **immediately**, while the real request is still in flight in the background. Think of it like a waiter at a restaurant who tells you "your order is confirmed!" the moment you order, rather than making you wait at the counter until the kitchen has physically finished cooking — and if the kitchen later says "sorry, we're out of that dish," the waiter comes back and corrects the record.

**The Implementation:**

First, we need the sidebar to know which lessons are already completed, so it can render checkmarks correctly on page load. Extend the Sanity navigation query helper to also accept a set of completed lesson IDs (fetched separately from Neon):

#### `lib/db/progress.ts`
```typescript
import { PrismaClient } from "@prisma/client";
import { auth } from "@clerk/nextjs/server";

const prisma = new PrismaClient();

/**
 * Fetches the set of lessonIds this signed-in user has already completed.
 * This is "Parallel Fetch B" from the architecture — Neon progress data,
 * fetched independently from Sanity's content structure.
 */
export async function getCompletedLessonIds(): Promise<string[]> {
  const { userId } = await auth();
  if (!userId) return [];

  const rows = await prisma.progress.findMany({
    where: { userId, completed: true },
    select: { lessonId: true },
  });

  return rows.map((row) => row.lessonId);
}
```

Now update the dashboard layout to fetch both data sources in parallel and pass completion state down into the sidebar:

#### `app/dashboard/layout.tsx` (updated)
```tsx
import { Sidebar } from "./_components/sidebar";
import { getCourseNavigation } from "@/lib/sanity/queries";
import { getCompletedLessonIds } from "@/lib/db/progress";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Fetch content structure (Sanity) and progress state (Neon) at the
  // same time, rather than one after another — this is the parallel
  // fetch pattern from the architecture's request lifecycle.
  const [courses, completedLessonIds] = await Promise.all([
    getCourseNavigation(),
    getCompletedLessonIds(),
  ]);

  return (
    <div className="flex">
      <Sidebar courses={courses} initialCompletedIds={completedLessonIds}>
        <p className="px-2 py-1.5 text-xs font-semibold uppercase text-brand-600">
          My Courses
        </p>
      </Sidebar>
      <main className="flex-1 bg-brand-50 p-8">{children}</main>
    </div>
  );
}
```

Now rebuild the sidebar itself to accept this data and manage optimistic state:

#### `app/dashboard/_components/sidebar.tsx` (updated)
```tsx
"use client";

import { useOptimistic } from "react";
import Link from "next/link";
import { UserButton } from "@clerk/nextjs";
import { useState } from "react";
import type { SidebarCourse } from "@/lib/sanity/queries";

interface SidebarProps {
  children: React.ReactNode;
  courses: SidebarCourse[];
  initialCompletedIds: string[];
}

export function Sidebar({ children, courses, initialCompletedIds }: SidebarProps) {
  const [isOpen, setIsOpen] = useState(true);

  // useOptimistic gives us a temporary, client-only copy of completedIds
  // that we can update INSTANTLY on user interaction, without waiting
  // for the server. React automatically reconciles this back to the real
  // `initialCompletedIds` value whenever that prop changes (e.g. after
  // revalidation), and silently discards the optimistic value if the
  // enclosing action throws or the component re-renders with fresh data.
  const [optimisticCompletedIds, addOptimisticCompletedId] = useOptimistic(
    initialCompletedIds,
    (currentIds: string[], newLessonId: string) => {
      // Avoid duplicate entries if the same lesson is marked twice.
      if (currentIds.includes(newLessonId)) return currentIds;
      return [...currentIds, newLessonId];
    }
  );

  return (
    <div className="flex min-h-screen">
      <aside
        className={`flex flex-col border-r border-brand-100 bg-white transition-all duration-200 ${
          isOpen ? "w-72" : "w-16"
        }`}
      >
        <div className="flex items-center justify-between p-4 border-b border-brand-100">
          {isOpen && (
            <Link href="/dashboard" className="font-bold text-brand-900">
              Greymatter
            </Link>
          )}
          <button
            onClick={() => setIsOpen(!isOpen)}
            aria-label="Toggle sidebar"
            className="rounded-md p-1.5 text-brand-600 hover:bg-brand-50"
          >
            {isOpen ? "«" : "»"}
          </button>
        </div>

        <nav className="flex-1 overflow-y-auto p-2">
          {isOpen && (
            <>
              {children}
              <div className="mt-2 space-y-4">
                {courses.map((course) => (
                  <div key={course._id}>
                    <Link
                      href={`/dashboard/courses/${course.slug}`}
                      className="block rounded-md px-2 py-1.5 font-medium text-brand-900 hover:bg-brand-50"
                    >
                      {course.title}
                    </Link>
                    <div className="ml-3 mt-1 space-y-1 border-l border-brand-100 pl-3">
                      {course.chapters.map((chapter) => (
                        <div key={chapter._id}>
                          <p className="px-2 py-1 text-sm font-semibold text-brand-600">
                            {chapter.title}
                          </p>
                          <div className="space-y-0.5">
                            {chapter.lessons.map((lesson) => {
                              const isCompleted = optimisticCompletedIds.includes(
                                lesson._id
                              );
                              return (
                                <Link
                                  key={lesson._id}
                                  href={`/dashboard/courses/${course.slug}/lessons/${lesson.slug}`}
                                  className="flex items-center justify-between rounded-md px-2 py-1 text-sm text-brand-600 hover:bg-brand-50 hover:text-brand-900"
                                >
                                  <span>{lesson.title}</span>
                                  {isCompleted && (
                                    <span className="text-success-500">✓</span>
                                  )}
                                </Link>
                              );
                            })}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            </>
          )}
        </nav>

        <div className="border-t border-brand-100 p-4 flex items-center gap-2">
          <UserButton afterSignOutUrl="/sign-in" />
          {isOpen && <span className="text-sm text-brand-600">My Account</span>}
        </div>
      </aside>
    </div>
  );
}
```

There's a subtlety here: `useOptimistic` must be called *inside* the component that owns the state, but the actual trigger (`addOptimisticCompletedId`) needs to be called from deep inside `module-renderer.tsx`, several component levels away. The cleanest way to bridge that gap is via **React Context**, so any lesson page can reach up and trigger the sidebar's optimistic update without prop-drilling through every intermediate layout.

#### `app/dashboard/_components/progress-context.tsx`
```tsx
"use client";

import { createContext, useContext } from "react";

interface ProgressContextValue {
  markLessonCompleteOptimistically: (lessonId: string) => void;
}

export const ProgressContext = createContext<ProgressContextValue | null>(null);

export function useProgressContext() {
  const ctx = useContext(ProgressContext);
  if (!ctx) {
    throw new Error("useProgressContext must be used within a ProgressContext.Provider");
  }
  return ctx;
}
```

Now wire the provider around the sidebar's optimistic updater function:

#### `app/dashboard/_components/sidebar.tsx` (final version, wrapping children in the provider)

```tsx
"use client";

import { useOptimistic, useState } from "react";
import Link from "next/link";
import { UserButton } from "@clerk/nextjs";
import type { SidebarCourse } from "@/lib/sanity/queries";
import { ProgressContext } from "./progress-context";

interface SidebarProps {
  children: React.ReactNode;
  courses: SidebarCourse[];
  initialCompletedIds: string[];
}

export function Sidebar({ children, courses, initialCompletedIds }: SidebarProps) {
  const [isOpen, setIsOpen] = useState(true);

  // useOptimistic gives us a temporary, client-only copy of completedIds
  // that updates INSTANTLY on user interaction, without waiting for the
  // server. This directly implements the "Optimistic-First Execution"
  // principle — UI latency is capped at the speed of client-side execution
  // using React 19 transition features, rather than a full round trip [1].
  const [optimisticCompletedIds, addOptimisticCompletedId] = useOptimistic(
    initialCompletedIds,
    (currentIds: string[], newLessonId: string) => {
      if (currentIds.includes(newLessonId)) return currentIds;
      return [...currentIds, newLessonId];
    }
  );

  return (
    <ProgressContext.Provider
      value={{
        markLessonCompleteOptimistically: (lessonId: string) =>
          addOptimisticCompletedId(lessonId),
      }}
    >
      <div className="flex min-h-screen">
        <aside
          className={`flex flex-col border-r border-brand-100 bg-white transition-all duration-200 ${
            isOpen ? "w-72" : "w-16"
          }`}
        >
          <div className="flex items-center justify-between p-4 border-b border-brand-100">
            {isOpen && (
              <Link href="/dashboard" className="font-bold text-brand-900">
                Greymatter
              </Link>
            )}
            <button
              onClick={() => setIsOpen(!isOpen)}
              aria-label="Toggle sidebar"
              className="rounded-md p-1.5 text-brand-600 hover:bg-brand-50"
            >
              {isOpen ? "«" : "»"}
            </button>
          </div>

          <nav className="flex-1 overflow-y-auto p-2">
            {isOpen && (
              <>
                {children}
                <div className="mt-2 space-y-4">
                  {courses.map((course) => (
                    <div key={course._id}>
                      <Link
                        href={`/dashboard/courses/${course.slug}`}
                        className="block rounded-md px-2 py-1.5 font-medium text-brand-900 hover:bg-brand-50"
                      >
                        {course.title}
                      </Link>
                      <div className="ml-3 mt-1 space-y-1 border-l border-brand-100 pl-3">
                        {course.chapters.map((chapter) => (
                          <div key={chapter._id}>
                            <p className="px-2 py-1 text-sm font-semibold text-brand-600">
                              {chapter.title}
                            </p>
                            <div className="space-y-0.5">
                              {chapter.lessons.map((lesson) => {
                                const isCompleted = optimisticCompletedIds.includes(
                                  lesson._id
                                );
                                return (
                                  <Link
                                    key={lesson._id}
                                    href={`/dashboard/courses/${course.slug}/lessons/${lesson.slug}`}
                                    className="flex items-center justify-between rounded-md px-2 py-1 text-sm text-brand-600 hover:bg-brand-50 hover:text-brand-900"
                                  >
                                    <span>{lesson.title}</span>
                                    {isCompleted && (
                                      <span className="text-success-500">✓</span>
                                    )}
                                  </Link>
                                );
                              })}
                            </div>
                          </div>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </>
            )}
          </nav>

          <div className="border-t border-brand-100 p-4 flex items-center gap-2">
            <UserButton afterSignOutUrl="/sign-in" />
            {isOpen && <span className="text-sm text-brand-600">My Account</span>}
          </div>
        </aside>
      </div>
    </ProgressContext.Provider>
  );
}
```

Since the `Sidebar` itself now renders the course list internally, simplify the layout that wraps it:

#### `app/dashboard/layout.tsx` (final version)
```tsx
import { Sidebar } from "./_components/sidebar";
import { getCourseNavigation } from "@/lib/sanity/queries";
import { getCompletedLessonIds } from "@/lib/db/progress";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  // Parallel Fetch A (Sanity content) and Parallel Fetch B (Neon progress)
  // resolved together, then combined into a single server render [1].
  const [courses, completedLessonIds] = await Promise.all([
    getCourseNavigation(),
    getCompletedLessonIds(),
  ]);

  return (
    <div className="flex">
      <Sidebar courses={courses} initialCompletedIds={completedLessonIds}>
        <p className="px-2 py-1.5 text-xs font-semibold uppercase text-brand-600">
          My Courses
        </p>
      </Sidebar>
      <main className="flex-1 bg-brand-50 p-8">{children}</main>
    </div>
  );
}
```

Now wire the context into `module-renderer.tsx` so completing a lesson triggers the sidebar's optimistic update *and* the real server write, at the same time:

#### `components/plugins/module-renderer.tsx` (final version)
```tsx
"use client";

import { resolveModule } from "@/lib/plugin-sdk/registry";
import type { RawCustomModuleBlock } from "@/lib/plugin-sdk/types";
import { completeLesson } from "@/app/actions/progress";
import { useTransition } from "react";
import { useProgressContext } from "@/app/dashboard/_components/progress-context";

interface ModuleRendererProps {
  block: RawCustomModuleBlock;
  courseId: string;
  lessonId: string;
}

export function ModuleRenderer({ block, courseId, lessonId }: ModuleRendererProps) {
  const [isPending, startTransition] = useTransition();
  const { markLessonCompleteOptimistically } = useProgressContext();

  const PluginComponent = resolveModule(block.moduleType);

  if (!PluginComponent) {
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
        startTransition(async () => {
          // 1. Update the sidebar checkmark INSTANTLY, before the server
          //    has responded — this must happen inside the same transition
          //    as the async server call so React can correctly roll back
          //    the optimistic value if the request ultimately fails.
          markLessonCompleteOptimistically(lessonId);

          // 2. Fire the real, trust-verified write in the background.
          const response = await completeLesson({
            courseId,
            lessonId,
            score: result.score,
            moduleState: result.moduleState,
          });

          if (!response.success) {
            // If the server rejects the write (e.g. no enrollment, or a
            // score integrity violation), the optimistic checkmark is
            // automatically discarded once this transition settles and
            // the component re-renders with the real (unchanged) server data.
            console.error("Failed to save progress:", response.error);
          }
        });
      }}
    />
  );
}
```

**The Verification:**

1. Restart your dev server:

```bash
npm run dev
```

2. Navigate to your test lesson (with a valid `Enrollment` row already in place from Step 3's positive test). Open the sidebar and confirm the lesson currently shows **no** checkmark.

3. Complete the SQL Sandbox with the correct query. Watch closely — the checkmark (✓) should appear next to the lesson title in the sidebar **immediately**, even before any network response has come back. This is the optimistic update firing synchronously inside `startTransition`.

4. Refresh the entire page (a hard reload, not just client-side navigation). The checkmark should still be present — this confirms the *real* write succeeded server-side (via `getCompletedLessonIds()` in the layout), not just the temporary optimistic one.

5. **Negative test for optimistic rollback:** Remove your test user's `Enrollment` row again via Prisma Studio. Clear the corresponding `Progress` row too. Reload the lesson page fully, then complete the SQL Sandbox again. You should observe:
   - The checkmark appears **instantly** (optimistic update fires regardless of what the server will eventually say)
   - Shortly after, your terminal logs `Failed to save progress: Transaction Failed: Student has not enrolled in the parent course.`
   - On the *next* full page reload, the checkmark is **gone** — because `getCompletedLessonIds()` never found a real `Progress` row, proving the optimistic state was only ever a temporary illusion, correctly discarded once fresh server data replaced it.

6. Re-add the `Enrollment` row afterward to restore your working test setup.

Once all three scenarios (instant checkmark, persistence across reload, and correct rollback on failure) are confirmed, commit the final checkpoint for Part 4:

```bash
git add app/dashboard components/plugins/module-renderer.tsx lib/db/progress.ts
git commit -m "feat: integrate useOptimistic for instant lesson completion checkmarks"
```

---

## Closing Out Part 4

### What You Have Right Now
- A `completeLesson` Server Action that never trusts client-supplied identity, relying exclusively on Clerk's server-verified session
- A score bounds check rejecting any value outside 0–100 before it can reach the database, guarding against a tampered or malicious plugin
- A Prisma `$transaction` that atomically verifies enrollment via `tx.enrollment.findUnique(...)` before ever writing to `Progress` via `tx.progress.upsert(...)` — if no enrollment exists, an error is thrown, the transaction rolls back, and nothing is written to the database at all [1]
- A `revalidateTag(\`progress-${courseId}\`)` call that clears cached client paths for that course immediately after a successful write [1]
- A `useOptimistic`-powered sidebar that lights up lesson checkmarks instantly on completion, then correctly discards that optimistic state if the server ultimately rejects the write (e.g., due to a missing enrollment or an out-of-range score)
- End-to-end verified behavior across three scenarios: instant checkmark appearance, persistence across a full page reload, and correct rollback when the underlying transaction fails

### The Complete Data Flow You Built
Tracing a single "lesson completed" event end to end, here is everything that now happens, step by step:

1. Student clicks "Run Query" in the SQL Sandbox plugin (Part 3)
2. Plugin calls `onComplete({ score, moduleState })` — browser-only, untrusted
3. `module-renderer.tsx` receives this callback and, inside a single `startTransition`:
   - Instantly marks the lesson complete in the sidebar via `useOptimistic`
   - Calls the `completeLesson` Server Action in the background
4. `completeLesson` re-verifies identity via Clerk's `auth()`, rejects out-of-range scores, then opens a Prisma transaction
5. The transaction checks `Enrollment` existence — if missing, it throws and rolls back everything, including the `Progress` upsert [1]
6. If enrollment is confirmed, `Progress` is upserted with `completed: true`, `completedAt`, `score`, and `moduleState` [1]
7. On success, `revalidateTag` clears cached course paths; on failure, the client logs the error and the optimistic checkmark is discarded on next render

This closes the loop first diagrammed all the way back at the start of the series — Sanity's content engine and Neon's transaction engine, now fully wired together through a secure, atomic, optimistic-UI-enabled pipeline [1].

### What's Next
With Parts 1 through 4 complete, the core Greymatter LMS application is functionally whole: authenticated dashboard, Sanity-driven content and plugin rendering, and a secure, optimistic progress-tracking engine. The three appendices — **Appendix A: The Hybrid Data Engine Concept**, **Appendix B: Next.js 16 Data Lifecycle**, and **Appendix C: Code Segment Breakdown** — remain as the standalone reference material to deepen understanding of the architectural decisions made throughout the series.

