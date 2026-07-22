# Part 12 — Inngest Fundamentals and Event-Driven Workflows

## The goal

By the end of this part, GreyMatter LMS will have a working Inngest integration: a typed event catalog, a served Inngest API route, and three real, durable background workflows — student onboarding, enrollment confirmation, and course-progress recalculation. We'll wire `course/enrolled` (dormant since Part 8) and `lesson/completed` (dormant since Part 11) into genuine event emissions for the first time, and see Inngest's local development dashboard actually receive, retry, and process them.

## Why it exists

Recall Part 0's bank-teller analogy: the teller confirms your deposit instantly, but the check-clearing process happens afterward, without you standing at the counter. Every part since Part 8 has been building the "teller" half of GreyMatter — fast, synchronous, must-happen-now writes. This part builds the "back office" half. It matters architecturally, not just for performance: some operations (recalculating a whole course's completion percentage, checking certificate eligibility, sending an email) genuinely don't belong inside the response time of a student clicking "Submit," and trying to cram them in there would make every interaction feel sluggish and fragile — a transient email-provider hiccup shouldn't ever cause a quiz submission to fail.

## The data flow

```text
Server Action (enrollInCourse, submitModuleAttempt) finishes its Neon transaction
        │
        ▼
inngest.send({ name: "...", data: {...} })  — fire-and-forget, returns almost instantly
        │
        ▼
Inngest's infrastructure receives the event, durably
        │
        ▼
app/api/inngest/route.ts — our own endpoint, invoked BY Inngest when it's time to run a function
        │
        ▼
The matching function executes, step by step, with automatic retry on failure
        │
        ▼
Function writes its own results back to Neon (e.g., updated course_progress)
```

Terms worth defining before we build this:

- **Event-driven architecture**: a system design where components communicate by announcing "this happened" (an event) rather than directly calling each other. The Server Action that handles enrollment doesn't need to know anything about onboarding emails or analytics — it just announces `course/enrolled` happened, and any number of *other* pieces of code can independently decide to react to that announcement, now or in the future, without the original code ever being modified.
- **Step function**: an Inngest function broken into named, independently-retryable `step.run(...)` blocks. If step 2 of a 5-step function fails, Inngest retries *only* step 2 (using cached results from steps that already succeeded) — not the entire function from scratch, which matters enormously once a function sends an email (you don't want to risk sending the same email five times because step 4 failed).

---

## Step 1 — Creating an Inngest account and installing the SDK

### The Target

A real Inngest account, the `inngest` npm package installed, and environment variables added.

### The Concept

Inngest, for local development, runs almost entirely on your own machine via a small CLI dev server — you don't strictly need a hosted account to build and test everything in this part. We'll still create one now, since Part 16's production deployment needs it, and it costs nothing to set up early.

### The Implementation

```bash
npm install inngest
```

Visit **https://app.inngest.com**, sign up, and create an app named `greymatter-lms`. For local development we don't yet need real keys — Inngest's dev server (Step 3) runs without them. Still, add placeholders now so the pattern is established:

#### `.env.example` (update the Inngest section)

```bash
# ── Inngest (added in Part 12) ─────────────────────────────────────
INNGEST_EVENT_KEY=
INNGEST_SIGNING_KEY=
```

Leave `.env.local`'s equivalents empty for now — local development works without them, and we'll populate them for real in Part 16.

### The Verification

```bash
npm ls inngest
```

Should show the installed package with no `UNMET DEPENDENCY` warnings.

---

## Step 2 — The Inngest client and typed event catalog

### The Target

`inngest/client.ts` — the shared Inngest client instance, and `inngest/events.ts` — a typed catalog of every event GreyMatter will ever emit.

### The Concept

Recall Part 5's `db/client.ts` and Part 3's `sanity/lib/client.ts` — this is the identical "one shared, typed connection object, imported everywhere" pattern, now applied to Inngest. The typed event catalog is arguably more important here than in either of those two systems: because events are *strings* passed around as plain data (`"course/enrolled"`), it would be alarmingly easy to typo an event name in one file and never notice, since nothing would visibly break — the event would simply be silently ignored by every function listening for the correctly-spelled version. A typed catalog turns that entire class of bug into a compile-time TypeScript error instead.

### The Implementation

#### `inngest/events.ts`

```ts
// The single source of truth for every event GreyMatter emits or
// listens for. Adding a new event type ANYWHERE in the app means adding
// it here first — every emitter and every listener then gets full
// autocomplete and type-checking against this exact shape.
export type GreyMatterEvents = {
  "user/created": {
    data: {
      userId: string; // our INTERNAL users.id, not Clerk's ID
      email: string;
    };
  };
  "course/enrolled": {
    data: {
      userId: string;
      courseId: string; // Sanity course _id
      enrollmentId: string;
    };
  };
  "lesson/completed": {
    data: {
      userId: string;
      courseId: string;
      lessonId: string; // Sanity lesson _id
    };
  };
  "course/completed": {
    data: {
      userId: string;
      courseId: string;
    };
  };
};
```

#### `inngest/client.ts`

```ts
import { EventSchemas, Inngest } from "inngest";
import type { GreyMatterEvents } from "./events";

export const inngest = new Inngest({
  id: "greymatter-lms",
  // EventSchemas().fromRecord<T>() is what wires our hand-written
  // GreyMatterEvents type into Inngest's own typing system — every
  // inngest.send({ name: "...", data: {...} }) call and every
  // inngest.createFunction({ event: "..." }, ...) definition is now
  // checked against this exact shape at compile time.
  schemas: new EventSchemas().fromRecord<GreyMatterEvents>(),
});
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 3 — Serving the Inngest Route Handler and running the dev server

### The Target

`app/api/inngest/route.ts` — the endpoint Inngest's infrastructure calls to discover and invoke our functions — and running Inngest's local dev server alongside `npm run dev`.

### The Concept

This route is conceptually the mirror image of Part 6's Clerk webhook: there, an external service called *us* to announce something happened. Here, Inngest calls *us* too, but for a different reason — to ask "what functions do you have, and please run this specific one now." We start with an empty function list; Step 4 fills it in.

### The Implementation

#### `inngest/functions/index.ts`

```ts
// Empty for now — filled in across Steps 4-6. Centralizing every
// function export here (rather than scattering imports across the
// route handler) mirrors Part 3's schema-types/index.ts pattern.
export const functions = [];
```

#### `app/api/inngest/route.ts`

```ts
import { serve } from "inngest/next";
import { inngest } from "@/inngest/client";
import { functions } from "@/inngest/functions";

// serve() generates GET, PUT, and POST handlers automatically:
// GET is used by Inngest's dashboard to introspect available functions,
// PUT registers this endpoint with Inngest, and POST is how Inngest
// actually invokes a function when its trigger condition is met.
export const { GET, POST, PUT } = serve({
  client: inngest,
  functions,
});
```

Now, run both servers side by side. In one terminal:

```bash
npm run dev
```

In a second terminal:

```bash
npx inngest-cli@latest dev
```

This starts Inngest's local dev server, which discovers functions from our running Next.js app and provides a dashboard for inspecting events and runs.

### The Verification

Visit **http://localhost:8288** (Inngest's local dashboard). Confirm it shows a connected app named `greymatter-lms` under the "Apps" tab, with zero functions currently registered — expected, since `functions` is still an empty array.

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 4 — The first workflow: student onboarding

### The Target

`inngest/functions/onboard-user.ts` — a function triggered by `user/created`, and wiring Part 6's webhook handler to actually emit that event for the first time.

### The Concept

Recall Part 6's `user.created` Clerk webhook already creates a row in our `users` table — but it does that work synchronously, inline, inside the webhook handler itself. We're not moving that write into Inngest (it's fast, simple, and needs to happen immediately so `ensureInternalUser`'s race-condition fallback has something to find). What we're adding is a *second*, independent reaction to the same underlying fact ("a new user now exists") — anything onboarding-related that can reasonably happen a moment later, decoupled entirely from the webhook's own success or failure.

### The Implementation

#### `inngest/functions/onboard-user.ts`

```ts
import { inngest } from "@/inngest/client";

export const onboardUser = inngest.createFunction(
  // id: a stable identifier for THIS function, used by Inngest's
  // dashboard and for idempotency/concurrency configuration later.
  { id: "onboard-user" },
  // event: which event triggers this function — fully typed against
  // GreyMatterEvents, so a typo here is a compile error, not a silent
  // no-op.
  { event: "user/created" },
  async ({ event, step }) => {
    // step.run() wraps one logical unit of work. If this function is
    // ever retried (due to a later step failing), Inngest replays the
    // function from the top but SKIPS re-executing any step.run() block
    // whose result it already has cached — this specific log line will
    // never run twice, even across retries.
    await step.run("log-onboarding", async () => {
      console.log(`Onboarding new user: ${event.data.userId} (${event.data.email})`);
      // A real application might create a welcome notification row,
      // schedule a "getting started" email (Part 14), or seed default
      // preferences here — kept minimal and observable for this part,
      // since the POINT being demonstrated is the durable-execution
      // mechanism itself, not any specific onboarding business logic.
    });

    return { onboarded: true, userId: event.data.userId };
  }
);
```

Register it:

#### `inngest/functions/index.ts` (updated)

```ts
import { onboardUser } from "./onboard-user";

export const functions = [onboardUser];
```

Now, emit the event from Part 6's webhook handler:

#### `app/api/webhooks/clerk/route.ts` (update the `user.created` case)

```ts
// Add this import at the top:
import { inngest } from "@/inngest/client";

// Inside the "user.created" case, after createUser(...) succeeds:
case "user.created": {
  const clerkUser = event.data;
  const primaryEmail = clerkUser.email_addresses.find(
    (e) => e.id === clerkUser.primary_email_address_id
  )?.email_address;

  if (!primaryEmail) {
    throw new Error("Clerk user has no primary email address");
  }

  const existing = await findUserByAuthProviderId(clerkUser.id);
  if (!existing) {
    const newUser = await createUser({
      authProviderId: clerkUser.id,
      email: primaryEmail,
      role: "STUDENT",
    });
    console.log(`Provisioned internal user for Clerk ID: ${clerkUser.id}`);

    // Fire-and-forget: sending this event should never be able to fail
    // the webhook's own success response. inngest.send() itself is
    // awaited (so we know Inngest's infrastructure accepted the event),
    // but nothing about the WORKFLOW's eventual outcome affects what we
    // return to Clerk below.
    await inngest.send({
      name: "user/created",
      data: { userId: newUser.id, email: newUser.email },
    });
  }
  break;
}
```

### The Verification

With both `npm run dev` and `npx inngest-cli@latest dev` running, sign up a brand new test account through `/sign-up`.

Visit `http://localhost:8288`, click the "Runs" tab, and confirm a new run appears for the `onboard-user` function, with status "Completed." Click into it and confirm you can see the `user/created` event's payload (your new user's ID and email) and the `log-onboarding` step's output.

Check your `npm run dev` terminal and confirm the `Onboarding new user: ...` log line appears.

---

## Step 5 — The second workflow: enrollment confirmation

### The Target

`inngest/functions/confirm-enrollment.ts` — triggered by `course/enrolled`, and wiring Part 8's `enrollInCourse` Server Action to finally emit this event.

### The Concept

Recall Part 8's data-flow diagram explicitly included "Emit `course/enrolled` Inngest event" as a step — but at the time, we deferred actually building it, since Inngest didn't exist yet. This is the moment that diagram becomes real. This function will fetch the course's title from Sanity (something the original enrollment action never needed to do, since it only stored a course ID) — a good demonstration of background work legitimately needing *more* information than the synchronous path required, which is one reason offloading it makes sense in the first place.

### The Implementation

#### `inngest/functions/confirm-enrollment.ts`

```ts
import { inngest } from "@/inngest/client";
import { client as sanityClient } from "@/sanity/lib/client";

interface CourseTitleResult {
  title: string;
}

export const confirmEnrollment = inngest.createFunction(
  { id: "confirm-enrollment" },
  { event: "course/enrolled" },
  async ({ event, step }) => {
    // Each step.run() call is independently named and cached. Splitting
    // "fetch the course title" and "log the confirmation" into two
    // steps (rather than one) means if step two ever needed to retry
    // for some reason, step one's Sanity fetch would NOT be repeated —
    // its cached result is simply reused.
    const course = await step.run("fetch-course-title", async () => {
      return sanityClient.fetch<CourseTitleResult | null>(
        `*[_type == "course" && _id == $courseId][0]{ title }`,
        { courseId: event.data.courseId }
      );
    });

    await step.run("log-confirmation", async () => {
      console.log(
        `Enrollment confirmed: user ${event.data.userId} enrolled in "${course?.title ?? "Unknown course"}" (enrollment ${event.data.enrollmentId})`
      );
      // A real application would send a confirmation email here
      // (Part 13 builds our email-sending pattern properly).
    });

    return { confirmed: true, courseTitle: course?.title ?? null };
  }
);
```

Register it:

#### `inngest/functions/index.ts` (updated)

```ts
import { onboardUser } from "./onboard-user";
import { confirmEnrollment } from "./confirm-enrollment";

export const functions = [onboardUser, confirmEnrollment];
```

Now wire the emission into Part 8's Server Action:

#### `app/dashboard/courses/actions.ts` (update `enrollInCourse`)

```ts
// Add this import at the top:
import { inngest } from "@/inngest/client";

// Replace the Layer 5 block with:
try {
  const { enrollmentId } = await createEnrollmentWithProgress({ userId: user.id, courseId });

  // Fire-and-forget: this send is awaited (confirming Inngest accepted
  // the event) but its outcome has NO bearing on whether enrollment
  // itself succeeded — that already happened, durably, in Neon, above.
  await inngest.send({
    name: "course/enrolled",
    data: { userId: user.id, courseId, enrollmentId },
  });
} catch (error) {
  console.error("Enrollment creation failed:", error);
  return { success: false, error: "Something went wrong. Please try again." };
}
```

Note this requires `createEnrollmentWithProgress` to return `enrollmentId` — confirm this matches its existing return shape from Part 8 (`{ enrollmentId, courseProgressId }`) — no changes needed there.

### The Verification

Sign in with a test account not yet enrolled in any course, and enroll in "Introduction to Databases" through the real UI. Check `http://localhost:8288`'s "Runs" tab and confirm a `confirm-enrollment` run completed successfully, showing the correct course title ("Introduction to Databases") resolved from Sanity inside its `fetch-course-title` step's output.

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 6 — The third workflow: recalculating course progress on lesson completion

### The Target

`inngest/functions/recalculate-course-progress.ts` — triggered by `lesson/completed`, reading every required lesson from Sanity, comparing against the student's actual `lesson_progress` rows in Neon, and updating `course_progress.completionPercentage` accordingly. And wiring Part 11's `submitModuleAttempt` to finally emit `lesson/completed` when a lesson's progress reaches `COMPLETED`.

### The Concept

This is the most substantial workflow in this part, and it directly fulfills Part 0's very first architectural promise: "Sanity stores what lessons exist; Neon stores what a student has finished; something must periodically reconcile the two into a percentage." Notice this function needs data from **both** systems simultaneously — precisely the hybrid-architecture pattern from Part 7's `getEnrolledCourses`, now running inside a background job instead of a page request.

An important design decision worth calling out: **we are not marking a lesson `COMPLETED` inside `submitModuleAttempt` itself.** Recall Part 11 only ever upserts lesson progress to `IN_PROGRESS` on any module attempt. Determining "is this entire lesson actually finished" requires knowing about *every* module within it — information the single-module submission function doesn't have and shouldn't need to fetch on every request. We compute that separately, here, inside the background workflow, exactly the kind of "can happen a moment later" work Part 0 described.

### The Implementation

First, a query helper to check if all of a lesson's modules have been successfully attempted:

#### `sanity/lib/queries.ts` 

```ts
export interface CourseRequiredContent {
  _id: string;
  chapters: {
    lessons: {
      _id: string;
      moduleIds: string[]; // every gradeable/interactive module _key's moduleId within this lesson
    }[];
  }[];
}

// Fetches the FULL required-content shape for a course: every lesson,
// and every interactive module's moduleId within each lesson. This is
// the "textbook's table of contents," fetched fresh, so we can compare
// it against what Neon says a student has actually done.
export const courseRequiredContentQuery = /* groq */ `
  *[_type == "course" && _id == $courseId][0]{
    _id,
    chapters[]->{
      lessons[]->{
        _id,
        "moduleIds": content[
          _type in ["quizBlock", "codeExerciseBlock", "reflectionBlock", "checkpointBlock"]
        ].moduleId
      }
    }
  }
`;
```

Now, query helpers to read this student's actual Neon-side progress:

#### `db/queries/module-attempts.ts` (append)

```ts
export async function findAllModuleIdsWithAttempts(userId: string, lessonId: string): Promise<Set<string>> {
  const attempts = await db.query.moduleAttempts.findMany({
    where: and(eq(moduleAttempts.userId, userId), eq(moduleAttempts.lessonId, lessonId)),
  });
  return new Set(attempts.map((a) => a.moduleId));
}
```

#### `db/queries/lesson-progress.ts` (append)

```ts
export async function markLessonCompleted(
  client: DbClientOrTransaction,
  userId: string,
  lessonId: string
) {
  await client
    .update(lessonProgress)
    .set({ status: "COMPLETED", completedAt: new Date(), updatedAt: new Date() })
    .where(and(eq(lessonProgress.userId, userId), eq(lessonProgress.lessonId, lessonId)));
}
```

#### `db/queries/course-progress.ts` (new file — query helpers for the aggregate table)

```ts
import { and, eq } from "drizzle-orm";
import { db } from "@/db/client";
import { courseProgress } from "@/db/schema";
import type { DbClientOrTransaction } from "@/db/transaction-type";

export async function updateCourseCompletionPercentage(
  client: DbClientOrTransaction,
  userId: string,
  courseId: string,
  completionPercentage: number
) {
  await client
    .update(courseProgress)
    .set({ completionPercentage, lastActivityAt: new Date(), updatedAt: new Date() })
    .where(and(eq(courseProgress.userId, userId), eq(courseProgress.courseId, courseId)));
}

export async function findCourseProgressRow(userId: string, courseId: string) {
  return db.query.courseProgress.findFirst({
    where: and(eq(courseProgress.userId, userId), eq(courseProgress.courseId, courseId)),
  });
}
```

Now, the workflow itself:

#### `inngest/functions/recalculate-course-progress.ts`

```ts
import { inngest } from "@/inngest/client";
import { client as sanityClient } from "@/sanity/lib/client";
import {
  courseRequiredContentQuery,
  type CourseRequiredContent,
} from "@/sanity/lib/queries";
import { db } from "@/db/client";
import { findAllModuleIdsWithAttempts } from "@/db/queries/module-attempts";
import { markLessonCompleted } from "@/db/queries/lesson-progress";
import {
  updateCourseCompletionPercentage,
  findCourseProgressRow,
} from "@/db/queries/course-progress";

export const recalculateCourseProgress = inngest.createFunction(
  { id: "recalculate-course-progress" },
  { event: "lesson/completed" },
  async ({ event, step }) => {
    const { userId, courseId, lessonId } = event.data;

    // Step 1: is THIS specific lesson now fully done? A lesson is
    // "complete" once every one of its interactive modules has at
    // least one attempt recorded — a simple, defensible definition for
    // this series (a real system might require a PASSING attempt
    // instead; noted here as a reasonable future refinement).
    const requiredContent = await step.run("fetch-required-content", async () => {
      return sanityClient.fetch<CourseRequiredContent | null>(courseRequiredContentQuery, {
        courseId,
      });
    });

    if (!requiredContent) {
      // The course no longer exists or was unpublished between the
      // triggering event and now — nothing meaningful to recalculate.
      return { recalculated: false, reason: "course_not_found" };
    }

    const currentLesson = requiredContent.chapters
      .flatMap((chapter) => chapter.lessons)
      .find((lesson) => lesson._id === lessonId);

    if (currentLesson) {
      const attemptedModuleIds = await step.run("fetch-attempted-modules", async () => {
        const set = await findAllModuleIdsWithAttempts(userId, lessonId);
        return Array.from(set); // Sets aren't directly JSON-serializable across step boundaries
      });

      const allModulesAttempted = currentLesson.moduleIds.every((id) =>
        attemptedModuleIds.includes(id)
      );

      if (allModulesAttempted) {
        await step.run("mark-lesson-completed", async () => {
          await markLessonCompleted(db, userId, lessonId);
        });
      }
    }

    // Step 2: recompute the WHOLE course's completion percentage —
    // comparing every lesson across every chapter against this
    // student's lesson_progress rows.
    const allLessons = requiredContent.chapters.flatMap((chapter) => chapter.lessons);

    const completedCount = await step.run("count-completed-lessons", async () => {
      const rows = await db.query.lessonProgress.findMany({
        where: (lp, { and, eq }) => and(eq(lp.userId, userId), eq(lp.courseId, courseId)),
      });
      const completedLessonIds = new Set(
        rows.filter((r) => r.status === "COMPLETED").map((r) => r.lessonId)
      );
      return allLessons.filter((lesson) => completedLessonIds.has(lesson._id)).length;
    });

    const completionPercentage =
      allLessons.length === 0 ? 0 : Math.round((completedCount / allLessons.length) * 100);

    await step.run("update-course-progress", async () => {
      await updateCourseCompletionPercentage(db, userId, courseId, completionPercentage);
    });

    // Step 3: if the course JUST reached 100%, emit course/completed —
    // Part 13 listens for this event to trigger certificate generation.
    // We check the PREVIOUS percentage first so this event fires
    // exactly ONCE, at the moment of crossing the threshold, not on
    // every subsequent recalculation once already at 100%.
    const previousProgress = await step.run("fetch-previous-progress", async () => {
      return findCourseProgressRow(userId, courseId);
    });

    if (completionPercentage === 100 && previousProgress?.completionPercentage !== 100) {
      await step.sendEvent("emit-course-completed", {
        name: "course/completed",
        data: { userId, courseId },
      });
    }

    return { recalculated: true, completionPercentage };
  }
);
```

**Code walkthrough:**

- `Array.from(set)` inside the `step.run` callback matters for a subtle but important reason: every `step.run` result is serialized to JSON internally by Inngest (so it can be cached and safely replayed across a retry) — a `Set` object does not serialize to/from JSON automatically the way a plain array does, so we deliberately convert it before returning.
- `step.sendEvent(...)` is Inngest's own dedicated helper for emitting an event *from within* a function (as opposed to `inngest.send(...)`, used from regular application code like Server Actions) — using it here means this emission is itself tracked as a durable step, consistent with everything else in the function.
- The `previousProgress?.completionPercentage !== 100` check is the concrete mechanism preventing `course/completed` from firing repeatedly on every subsequent lesson revisit once a course is already finished — worth re-reading, since a naive version of this function (just checking `completionPercentage === 100` alone) would re-emit the event forever after first completion, which Part 13's certificate-issuance workflow would then need its own idempotency protection against (it will, via Part 5's `unique(user_id, course_id)` constraint on `certificates` — but avoiding the redundant emission here is still the cleaner fix).

Register the new function:

#### `inngest/functions/index.ts` (final version for this part)

```ts
import { onboardUser } from "./onboard-user";
import { confirmEnrollment } from "./confirm-enrollment";
import { recalculateCourseProgress } from "./recalculate-course-progress";

export const functions = [onboardUser, confirmEnrollment, recalculateCourseProgress];
```

Finally, emit `lesson/completed` from Part 11's Server Action, at the exact moment lesson progress is upserted:

#### `lib/modules/submit-module-attempt.ts` (update the transaction block)

```ts
// Add this import at the top:
import { inngest } from "@/inngest/client";

// Replace the "Layer 8: The atomic write" try block with this version —
// notice the event is sent AFTER the transaction commits successfully,
// never from inside it (an Inngest event send is a network call, and
// network calls have no place inside a database transaction).
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

  // Fire-and-forget, AFTER the transaction has genuinely committed.
  // Every module attempt (not just ones that individually complete a
  // lesson) triggers a recalculation — the recalculate-course-progress
  // function itself is responsible for figuring out whether the LESSON
  // is now fully done, not this Server Action.
  await inngest.send({
    name: "lesson/completed",
    data: { userId: user.id, courseId, lessonId },
  });
} catch (error) {
  console.error("Failed to record module attempt:", error);
  return errorResult("UNKNOWN_ERROR", "Something went wrong. Please try again.");
}
```

**Code walkthrough:**

- Notice the event name `lesson/completed` is emitted on **every** module attempt, not only ones that happen to finish the lesson — this might look surprising at first, but it's a deliberate simplification: the recalculation function itself is the single source of truth for "is this lesson actually done," re-checking that condition fresh every time rather than trusting the Server Action to have determined it correctly. This avoids duplicating the "is every module attempted" logic in two separate places (the Server Action and the Inngest function), keeping that determination in exactly one place.
- Sending the event **after** the transaction (not inside it, not before it) is a small but important ordering detail: if the transaction had failed and rolled back, but we'd already sent the event, Inngest would attempt to recalculate progress based on data that was never actually saved — a real, avoidable inconsistency this ordering prevents entirely.

### The Verification

With both dev servers running, open the "Writing Your First Query" lesson and submit the quiz (any answer — we're testing the workflow trigger, not re-testing grading correctness from Part 11). 

Visit `http://localhost:8288`'s "Runs" tab and confirm a `recalculate-course-progress` run appears and completes successfully. Click into it and inspect each step's output — confirm `fetch-required-content` shows your course's real chapter/lesson structure, and `update-course-progress` ran.

Open Drizzle Studio and confirm the `course_progress` row's `completion_percentage` has updated to reflect real progress (e.g., if this course has 2 lessons and you've now attempted every module in lesson 1, and completed the reflection/checkpoint from Part 10 too, confirm the math lines up: completed lessons ÷ total lessons × 100).

If you also completed every required module in the second lesson during this or earlier testing, confirm `completion_percentage` reaches `100`, and check the Inngest dashboard for a resulting `emit-course-completed` step having fired — its corresponding `course/completed` event will simply have no listener yet (that's Part 13's job) but should still appear correctly in Inngest's "Events" tab.

Run the full verification suite:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Common mistakes

- **Inngest dashboard shows zero functions even after adding them to `functions/index.ts`** — Confirm `npm run dev` was restarted after the route handler changed, and that Inngest's dev server (`npx inngest-cli@latest dev`) is genuinely running and pointed at `http://localhost:3000/api/inngest` (its default assumption) — check its terminal output for a "synced" confirmation.
- **A function run shows status "Failed" with a JSON serialization error** — Almost always caused by returning a non-plain-JSON value (a `Set`, a `Map`, a `Date` object, a class instance) from inside a `step.run` callback. Convert to a plain array/string/number before returning, as done with `Array.from(set)` above.
- **`lesson/completed` fires but `recalculate-course-progress` never runs** — Double-check the event name string in `inngest.send({ name: "lesson/completed", ... })` exactly matches the key in `GreyMatterEvents` — a mismatch wouldn't be caught by TypeScript if the string were passed as a raw literal outside the typed catalog; confirm you're relying on the typed `inngest.send` call (which would show a compile error on a genuine typo) rather than a loosely-typed alternative.
- **`course/completed` fires repeatedly on every single module attempt once a course is done** — Re-check the `previousProgress?.completionPercentage !== 100` guard; a common mistake is comparing against the *newly computed* percentage instead of the *previously stored* one, which would always be true/false incorrectly.
- **Enrollment succeeds but `confirm-enrollment` never appears in Inngest's dashboard** — Confirm `createEnrollmentWithProgress`'s destructured `enrollmentId` matches its actual return shape, and that `inngest.send(...)` is genuinely reached (i.e., not accidentally placed after a `return` statement earlier in the function).

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `inngest/client.ts`, `inngest/events.ts`, `inngest/functions/*.ts`, `app/api/inngest/route.ts`, `sanity/lib/queries.ts` (modified), `db/queries/module-attempts.ts` (modified), `db/queries/lesson-progress.ts` (modified), `db/queries/course-progress.ts`, `app/api/webhooks/clerk/route.ts` (modified), `app/dashboard/courses/actions.ts` (modified), `lib/modules/submit-module-attempt.ts` (modified).

```bash
git commit -m "Part 12: Inngest integration — typed event catalog, served API route, onboarding/enrollment-confirmation/course-progress-recalculation workflows, real event emission from webhook and Server Actions"
```

---

## Reference: Inngest core concepts cheat sheet

| Concept | Role |
|---|---|
| `inngest.send({ name, data })` | Emit an event from regular application code (Server Actions, Route Handlers, webhooks) |
| `inngest.createFunction({ id }, { event }, handler)` | Define a function triggered when a matching event arrives |
| `step.run(name, fn)` | One retryable, cached unit of work — never re-executed once it has succeeded, even across retries |
| `step.sendEvent(name, event)` | Emit an event *from within* a function, tracked as its own durable step |
| Inngest dev server (`npx inngest-cli@latest dev`) | Local dashboard + event router for development, no account required |
| `app/api/inngest/route.ts` | The endpoint Inngest calls to discover and invoke functions |

## Reference: why events are emitted after, not inside, a transaction

```text
GOOD:  db.transaction(writes) → (commit succeeds) → inngest.send(event)
BAD:   db.transaction(writes + inngest.send(event) inside the callback)
```

If the event send happened *inside* the transaction and the transaction later rolled back (due to a later step failing), Inngest would have already been told something happened that, from the database's perspective, never actually did. Always emit events strictly after a transaction has been confirmed to commit.

---

## What's next

Part 13 builds the full course-completion pipeline this part's `course/completed` event has been waiting for: reading required lessons from Sanity, generating a uniquely-numbered certificate record protected by Part 5's `unique(user_id, course_id)` constraint, a PDF generation strategy, a completion email, and retry-safe, idempotent workflow behavior throughout.
