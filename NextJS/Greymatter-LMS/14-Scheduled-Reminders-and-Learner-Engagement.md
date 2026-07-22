# Part 14 — Scheduled Reminders and Learner Engagement

## The goal

By the end of this part, GreyMatter LMS will have real, scheduled background workflows: a daily cron job detecting students who've gone quiet on an active course for seven days and sending them a reminder, a weekly progress digest, notification-preference controls a student can actually turn off, and an in-app notification center showing every notification ever sent — all recorded auditable, all safe against spamming the same student repeatedly, and all correctly silenced once a student resumes activity or finishes the course.

## Why it exists

Every workflow built in Part 12 and Part 13 was **reactive** — triggered by something a student actively did (enrolling, submitting an answer, completing a course). This part introduces a genuinely different trigger: **the passage of time itself**, with nobody doing anything at all. This is a meaningfully different engineering problem: instead of reacting to one event about one specific student, a scheduled job must scan across *potentially every student on the platform* at once, efficiently, without accidentally emailing someone six times because of a badly-written loop.

## The data flow

```text
Inngest cron trigger fires (e.g., daily at 09:00 UTC)
        │
        ▼
send-inactivity-reminders function
        │
        ├── Query Neon: every ACTIVE enrollment where last_activity_at
        │     is 7+ days ago AND no reminder already sent this week
        ├── Batch: for each qualifying enrollment...
        │     ├── Check notification_preferences (has this student opted out?)
        │     ├── Send reminder email
        │     └── Record a notifications row (for the in-app center + spam prevention)
        │
        ▼
Student sees a red dot on the notification bell next time they visit
```

---

## Step 1 — Schema additions: notifications and preferences

### The Target

Two new tables: `notifications` (every notification ever sent, in-app and email alike) and `notification_preferences` (a simple per-user opt-out control).

### The Concept

Recall Part 5's `audit_logs` — a permanent record of what happened. `notifications` is a close cousin, but with a distinct purpose: it's *user-facing* (a student will actually read this list in the notification center), whereas `audit_logs` is purely internal. Keeping them separate, rather than overloading one table for both jobs, avoids a future headache where an internal system log accidentally becomes visible to a student, or a user-facing notification gets buried among thousands of unrelated internal audit rows.

### The Implementation

#### `db/schema/notifications.ts`

```ts
import { boolean, jsonb, pgEnum, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";
import { users } from "./users";

export const notificationTypeEnum = pgEnum("notification_type", [
  "INACTIVITY_REMINDER",
  "WEEKLY_DIGEST",
  "COURSE_COMPLETED",
  "NEW_CONTENT_PUBLISHED",
]);

export const notifications = pgTable("notifications", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  type: notificationTypeEnum("type").notNull(),
  title: text("title").notNull(),
  body: text("body").notNull(),
  // Arbitrary extra context (e.g. { courseId, courseTitle }) — lets the
  // in-app center link directly to the relevant course without a second
  // lookup, and lets Part 15's analytics group notifications by course.
  metadata: jsonb("metadata"),
  readAt: timestamp("read_at", { withTimezone: true }),
  emailSent: boolean("email_sent").notNull().default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});
```

#### `db/schema/notification-preferences.ts`

```ts
import { boolean, pgTable, timestamp, unique, uuid } from "drizzle-orm/pg-core";
import { users } from "./users";

export const notificationPreferences = pgTable(
  "notification_preferences",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
    inactivityRemindersEnabled: boolean("inactivity_reminders_enabled").notNull().default(true),
    weeklyDigestEnabled: boolean("weekly_digest_enabled").notNull().default(true),
    updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
  },
  (table) => [unique("notification_preferences_user_unique").on(table.userId)]
);
```

#### `db/schema/index.ts` (append both)

```ts
export * from "./notifications";
export * from "./notification-preferences";
```

Generate and apply:

```bash
npm run db:generate
npm run db:migrate
```

### The Verification

```bash
npm run db:studio
```

Confirm both new tables appear with the correct columns and the `notification_preferences_user_unique` constraint.

---

## Step 2 — Query helpers, with preference defaults handled correctly

### The Target

`db/queries/notification-preferences.ts` and `db/queries/notifications.ts`.

### The Concept

A subtle but important design point: **a student who has never visited the settings page has no row in `notification_preferences` at all.** We must treat "no row exists" as "defaults apply" (both reminders enabled), not as "somehow disabled" — getting this backwards would silently opt every existing student out of reminders the moment this feature ships, which is exactly the kind of quiet, hard-to-notice bug worth guarding against deliberately.

### The Implementation

#### `db/queries/notification-preferences.ts`

```ts
import { eq } from "drizzle-orm";
import { db } from "@/db/client";
import { notificationPreferences } from "@/db/schema";

export interface EffectivePreferences {
  inactivityRemindersEnabled: boolean;
  weeklyDigestEnabled: boolean;
}

// Returns real preferences if a row exists, or safe DEFAULTS (both
// enabled) if the student has never customized anything — never treats
// "no row" as "everything off."
export async function getEffectivePreferences(userId: string): Promise<EffectivePreferences> {
  const row = await db.query.notificationPreferences.findFirst({
    where: eq(notificationPreferences.userId, userId),
  });
  return {
    inactivityRemindersEnabled: row?.inactivityRemindersEnabled ?? true,
    weeklyDigestEnabled: row?.weeklyDigestEnabled ?? true,
  };
}

export async function upsertPreferences(
  userId: string,
  input: Partial<EffectivePreferences>
) {
  await db
    .insert(notificationPreferences)
    .values({
      userId,
      inactivityRemindersEnabled: input.inactivityRemindersEnabled ?? true,
      weeklyDigestEnabled: input.weeklyDigestEnabled ?? true,
    })
    .onConflictDoUpdate({
      target: [notificationPreferences.userId],
      set: { ...input, updatedAt: new Date() },
    });
}
```

#### `db/queries/notifications.ts`

```ts
import { and, desc, eq, gte, isNull } from "drizzle-orm";
import { db } from "@/db/client";
import { notifications } from "@/db/schema";

export interface CreateNotificationInput {
  userId: string;
  type: "INACTIVITY_REMINDER" | "WEEKLY_DIGEST" | "COURSE_COMPLETED" | "NEW_CONTENT_PUBLISHED";
  title: string;
  body: string;
  metadata?: unknown;
  emailSent: boolean;
}

export async function createNotification(input: CreateNotificationInput) {
  const [row] = await db.insert(notifications).values(input).returning();
  return row;
}

// SPAM PREVENTION: has a notification of this exact type already been
// sent to this user since the given date? Used to guarantee "at most
// one inactivity reminder per week per student," not once per day.
export async function hasRecentNotification(
  userId: string,
  type: CreateNotificationInput["type"],
  sinceDate: Date
): Promise<boolean> {
  const existing = await db.query.notifications.findFirst({
    where: and(
      eq(notifications.userId, userId),
      eq(notifications.type, type),
      gte(notifications.createdAt, sinceDate)
    ),
  });
  return Boolean(existing);
}

export async function findNotificationsForUser(userId: string) {
  return db.query.notifications.findMany({
    where: eq(notifications.userId, userId),
    orderBy: [desc(notifications.createdAt)],
  });
}

export async function countUnreadNotifications(userId: string): Promise<number> {
  const rows = await db.query.notifications.findMany({
    where: and(eq(notifications.userId, userId), isNull(notifications.readAt)),
  });
  return rows.length;
}

export async function markAllNotificationsRead(userId: string) {
  await db
    .update(notifications)
    .set({ readAt: new Date() })
    .where(and(eq(notifications.userId, userId), isNull(notifications.readAt)));
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 3 — Finding inactive enrollments efficiently

### The Target

`db/queries/enrollments.ts` (append) — a single, batch-oriented query finding every enrollment across the *entire platform* that's gone quiet for seven days, rather than looping through students one at a time.

### The Concept

Recall the blueprint's explicit warning: "batching database queries" and "concurrency controls." A naive implementation might fetch every user, then loop and query enrollments per user — for a platform with thousands of students, that's thousands of round trips. We instead write **one query** that finds every qualifying enrollment directly, using a database join, and let the Inngest function iterate over the (much smaller) *results*, not the entire user base.

### The Implementation

#### `db/queries/enrollments.ts` (append)

```ts
import { and, eq, lt } from "drizzle-orm";
import { courseProgress, enrollments, users } from "@/db/schema";

export interface InactiveEnrollment {
  userId: string;
  userEmail: string;
  courseId: string;
  enrollmentId: string;
  lastActivityAt: Date;
}

// ONE query, joining enrollments -> course_progress -> users, finding
// every ACTIVE enrollment whose last_activity_at is older than the
// given cutoff. This scales to the size of the RESULT (students who
// are genuinely inactive), not the size of the whole user base.
export async function findInactiveEnrollments(cutoffDate: Date): Promise<InactiveEnrollment[]> {
  const rows = await db
    .select({
      userId: enrollments.userId,
      userEmail: users.email,
      courseId: enrollments.courseId,
      enrollmentId: enrollments.id,
      lastActivityAt: courseProgress.lastActivityAt,
    })
    .from(enrollments)
    .innerJoin(
      courseProgress,
      and(eq(courseProgress.userId, enrollments.userId), eq(courseProgress.courseId, enrollments.courseId))
    )
    .innerJoin(users, eq(users.id, enrollments.userId))
    .where(and(eq(enrollments.status, "ACTIVE"), lt(courseProgress.lastActivityAt, cutoffDate)));

  return rows;
}
```

(Note: this appends to the existing file, so `db` must already be imported at the top — confirm it is, alongside the existing imports from Parts 7 and 8.)

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 4 — The email sender for reminders (reusing Part 13's pattern)

### The Target

`lib/email/send-reminder-email.ts` — following the exact same Resend-with-dev-fallback pattern established in Part 13, Step 5.

### The Implementation

#### `lib/email/send-reminder-email.ts`

```ts
import { getResendClient } from "./client";

export interface ReminderEmailInput {
  toEmail: string;
  courseTitle: string;
  courseUrl: string;
}

export async function sendInactivityReminderEmail(
  input: ReminderEmailInput
): Promise<{ sent: boolean; simulated: boolean }> {
  const client = getResendClient();
  const html = `
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <h1 style="color:#4f46e5;">Still there?</h1>
      <p>You haven't made progress in <strong>${escapeHtml(input.courseTitle)}</strong> in a while.</p>
      <p><a href="${escapeHtml(input.courseUrl)}" style="color:#4f46e5;">Pick up where you left off</a></p>
    </div>
  `;

  if (!client) {
    console.log("─── (DEV) Would send inactivity reminder email ───");
    console.log(`To: ${input.toEmail} — Course: ${input.courseTitle}`);
    return { sent: false, simulated: true };
  }

  await client.emails.send({
    from: "GreyMatter LMS <reminders@greymatter-lms.example.com>",
    to: input.toEmail,
    subject: `Continue learning: ${input.courseTitle}`,
    html,
  });
  return { sent: true, simulated: false };
}

function escapeHtml(value: string): string {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
```

### The Verification

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 5 — The cron function: inactivity reminders

### The Target

`inngest/functions/send-inactivity-reminders.ts` — an Inngest **cron function**, triggered on a schedule rather than by an event.

### The Concept

Recall Part 12's functions were all triggered by `{ event: "..." }`. A cron function instead declares `{ cron: "..." }` — a schedule expression, using the same syntax traditional Unix cron jobs use. Inngest's infrastructure itself keeps time and invokes the function automatically; there's no separate scheduler process for us to run or maintain.

### The Implementation

#### `inngest/functions/send-inactivity-reminders.ts`

```ts
import { inngest } from "@/inngest/client";
import { client as sanityClient } from "@/sanity/lib/client";
import { findInactiveEnrollments } from "@/db/queries/enrollments";
import { getEffectivePreferences } from "@/db/queries/notification-preferences";
import { hasRecentNotification, createNotification } from "@/db/queries/notifications";
import { sendInactivityReminderEmail } from "@/lib/email/send-reminder-email";

interface CourseTitleResult {
  title: string;
}

export const sendInactivityReminders = inngest.createFunction(
  {
    id: "send-inactivity-reminders",
    // CONCURRENCY CONTROL: caps how many invocations of THIS function
    // run at once. Since each run below processes many students in a
    // loop already, we don't need high concurrency here — this mostly
    // guards against an accidental double-trigger overlapping itself.
    concurrency: { limit: 1 },
  },
  // cron, not event: this function runs on a SCHEDULE, using standard
  // cron syntax — "0 9 * * *" means "09:00 UTC, every day."
  { cron: "0 9 * * *" },
  async ({ step }) => {
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

    const inactiveEnrollments = await step.run("find-inactive-enrollments", async () => {
      return findInactiveEnrollments(sevenDaysAgo);
    });

    let remindersSent = 0;
    let skippedByPreference = 0;
    let skippedAlreadySent = 0;

    // Each qualifying enrollment is handled as its OWN step, uniquely
    // named per enrollment. This means if reminder #47 out of 200
    // fails and the function retries, Inngest does NOT re-send
    // reminders #1 through #46 — their results are already cached.
    for (const enrollment of inactiveEnrollments) {
      const outcome = await step.run(
        `process-enrollment-${enrollment.enrollmentId}`,
        async () => {
          const preferences = await getEffectivePreferences(enrollment.userId);
          if (!preferences.inactivityRemindersEnabled) {
            return "skipped_preference" as const;
          }

          // SPAM PREVENTION: even though this cron runs daily, a
          // student who was flagged yesterday and remains inactive
          // today should NOT receive a second reminder within the same
          // week — this check enforces "at most one per 7 days."
          const alreadyReminded = await hasRecentNotification(
            enrollment.userId,
            "INACTIVITY_REMINDER",
            sevenDaysAgo
          );
          if (alreadyReminded) {
            return "skipped_already_sent" as const;
          }

          const course = await sanityClient.fetch<CourseTitleResult | null>(
            `*[_type == "course" && _id == $courseId][0]{ title }`,
            { courseId: enrollment.courseId }
          );
          const courseTitle = course?.title ?? "your course";

          const emailResult = await sendInactivityReminderEmail({
            toEmail: enrollment.userEmail,
            courseTitle,
            courseUrl: `${process.env.NEXT_PUBLIC_APP_URL}/dashboard/courses/${enrollment.courseId}`,
          });

          await createNotification({
            userId: enrollment.userId,
            type: "INACTIVITY_REMINDER",
            title: "Continue learning",
            body: `You haven't made progress in ${courseTitle} in a while.`,
            metadata: { courseId: enrollment.courseId, courseTitle },
            emailSent: emailResult.sent,
          });

          return "sent" as const;
        }
      );

      if (outcome === "sent") remindersSent++;
      else if (outcome === "skipped_preference") skippedByPreference++;
      else skippedAlreadySent++;
    }

    return {
      totalInactive: inactiveEnrollments.length,
      remindersSent,
      skippedByPreference,
      skippedAlreadySent,
    };
  }
);
```

**Code walkthrough:**

- `concurrency: { limit: 1 }` prevents a rare but real scenario: if this cron function were somehow triggered twice in close succession (a manual test run overlapping the real schedule, for instance), we don't want two full passes processing the same inactive students simultaneously — `hasRecentNotification`'s check alone helps, but capping concurrency at the function level is a cleaner, more direct guard.
- Notice the loop processes enrollments **sequentially**, each as its own named `step.run`, rather than firing off many database/email calls in parallel with `Promise.all`. For a function whose primary value is *reliability* (never double-sending a reminder) rather than raw throughput, this sequential, individually-retryable approach is the more defensible default — a platform with tens of thousands of inactive students at once would need a genuinely different, fan-out-based design, which Part 16's Appendix E references as a further pattern beyond this series' scope.

Register it:

#### `inngest/functions/index.ts` (updated)

```ts
import { onboardUser } from "./onboard-user";
import { confirmEnrollment } from "./confirm-enrollment";
import { recalculateCourseProgress } from "./recalculate-course-progress";
import { issueCertificate } from "./issue-certificate";
import { sendInactivityReminders } from "./send-inactivity-reminders";

export const functions = [
  onboardUser,
  confirmEnrollment,
  recalculateCourseProgress,
  issueCertificate,
  sendInactivityReminders,
];
```

### The Verification

Cron functions can be triggered manually in Inngest's local dev dashboard without waiting for the real schedule. Visit `http://localhost:8288`, find `send-inactivity-reminders` under the "Functions" tab, and use its "Invoke" or "Trigger" option to run it immediately.

To produce a real test case, temporarily backdate a test enrollment's `course_progress.last_activity_at` to 8 days ago using Drizzle Studio, then trigger the function manually. Confirm the run completes, shows `remindersSent: 1` (or more, depending on your test data), and check your terminal for the "(DEV) Would send inactivity reminder email" log block.

Trigger the function a **second** time immediately afterward. Confirm this run reports `skippedAlreadySent: 1` for that same student — proving the spam-prevention check works.

---

## Step 6 — The weekly progress digest

### The Target

`inngest/functions/send-weekly-digest.ts` — a second cron function, summarizing a student's progress across *all* their active courses once a week.

### The Implementation

#### `lib/email/send-digest-email.ts`

```ts
import { getResendClient } from "./client";

export interface DigestEmailInput {
  toEmail: string;
  courseSummaries: { title: string; completionPercentage: number }[];
}

export async function sendWeeklyDigestEmail(
  input: DigestEmailInput
): Promise<{ sent: boolean; simulated: boolean }> {
  const client = getResendClient();
  const rows = input.courseSummaries
    .map((c) => `<li>${escapeHtml(c.title)} — ${c.completionPercentage}% complete</li>`)
    .join("");
  const html = `
    <div style="font-family: sans-serif; max-width: 480px; margin: 0 auto;">
      <h1 style="color:#4f46e5;">Your weekly progress</h1>
      <ul>${rows}</ul>
    </div>
  `;

  if (!client) {
    console.log("─── (DEV) Would send weekly digest email ───");
    console.log(`To: ${input.toEmail}`, input.courseSummaries);
    return { sent: false, simulated: true };
  }

  await client.emails.send({
    from: "GreyMatter LMS <digest@greymatter-lms.example.com>",
    to: input.toEmail,
    subject: "Your weekly progress digest",
    html,
  });
  return { sent: true, simulated: false };
}

function escapeHtml(value: string): string {
  return value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}
```

#### `db/queries/enrollments.ts` (append)

```ts
export interface StudentWithActiveCourses {
  userId: string;
  userEmail: string;
}

// Every student with at least one ACTIVE enrollment — the candidate
// list for the weekly digest, before per-user preference filtering.
export async function findStudentsWithActiveEnrollments(): Promise<StudentWithActiveCourses[]> {
  const rows = await db
    .selectDistinct({ userId: enrollments.userId, userEmail: users.email })
    .from(enrollments)
    .innerJoin(users, eq(users.id, enrollments.userId))
    .where(eq(enrollments.status, "ACTIVE"));
  return rows;
}
```

#### `inngest/functions/send-weekly-digest.ts`

```ts
import { inngest } from "@/inngest/client";
import { client as sanityClient } from "@/sanity/lib/client";
import { findStudentsWithActiveEnrollments } from "@/db/queries/enrollments";
import { getEnrolledCourses } from "@/lib/dashboard/get-enrolled-courses";
import { getEffectivePreferences } from "@/db/queries/notification-preferences";
import { createNotification } from "@/db/queries/notifications";
import { sendWeeklyDigestEmail } from "@/lib/email/send-digest-email";

export const sendWeeklyDigest = inngest.createFunction(
  { id: "send-weekly-digest", concurrency: { limit: 1 } },
  // Every Monday at 08:00 UTC.
  { cron: "0 8 * * 1" },
  async ({ step }) => {
    const students = await step.run("find-active-students", async () => {
      return findStudentsWithActiveEnrollments();
    });

    let digestsSent = 0;

    for (const student of students) {
      const sent = await step.run(`digest-for-${student.userId}`, async () => {
        const preferences = await getEffectivePreferences(student.userId);
        if (!preferences.weeklyDigestEnabled) return false;

        // Reusing Part 7's exact cross-database merge function — a good
        // demonstration of a well-designed helper paying off in a
        // completely different context (a background job instead of a
        // page request) without any modification.
        const courses = await getEnrolledCourses(student.userId);
        if (courses.length === 0) return false;

        await sendWeeklyDigestEmail({
          toEmail: student.userEmail,
          courseSummaries: courses.map((c) => ({
            title: c.title,
            completionPercentage: c.completionPercentage,
          })),
        });

        await createNotification({
          userId: student.userId,
          type: "WEEKLY_DIGEST",
          title: "Your weekly progress digest",
          body: `A summary of your progress across ${courses.length} course(s).`,
          emailSent: true,
        });

        return true;
      });
      if (sent) digestsSent++;
    }

    return { totalStudents: students.length, digestsSent };
  }
);
```

**Code walkthrough:**

- Reusing `getEnrolledCourses` (built in Part 7 for a page request) directly inside this Inngest function is worth pausing on: it's proof that keeping data-fetching logic in plain, framework-agnostic functions — rather than baking it directly into a page component — pays off the moment you need the same logic somewhere unexpected, like a scheduled background job.

Register it:

#### `inngest/functions/index.ts` (final version)

```ts
import { onboardUser } from "./onboard-user";
import { confirmEnrollment } from "./confirm-enrollment";
import { recalculateCourseProgress } from "./recalculate-course-progress";
import { issueCertificate } from "./issue-certificate";
import { sendInactivityReminders } from "./send-inactivity-reminders";
import { sendWeeklyDigest } from "./send-weekly-digest";

export const functions = [
  onboardUser,
  confirmEnrollment,
  recalculateCourseProgress,
  issueCertificate,
  sendInactivityReminders,
  sendWeeklyDigest,
];
```

### The Verification

Manually trigger `send-weekly-digest` from Inngest's local dashboard, using your enrolled test student. Confirm the run completes, `digestsSent: 1`, and your terminal shows the dev-fallback log listing every enrolled course with its correct completion percentage.

```bash
npx tsc --noEmit
```

Should complete with no errors.

---

## Step 7 — Reminder cancellation on activity or completion

### The Target

No new files — verifying that reminders are **already** correctly silenced by two mechanisms already built, and understanding exactly why no *new* code is needed here.

### The Concept

This is a good moment to see how earlier, careful design decisions quietly prevent problems before they exist. Two facts, already true from earlier parts, combine to fully satisfy this requirement:

1. **Part 9's `markLessonVisited`** updates `course_progress.lastActivityAt` on every real lesson visit. The moment a student returns and opens any lesson, `findInactiveEnrollments`'s `lt(courseProgress.lastActivityAt, cutoffDate)` filter naturally excludes them from the very next cron run — no explicit "cancel the reminder" logic is needed, because the underlying condition that qualified them is no longer true.
2. **Part 8's enrollment status** — once a course is completed, nothing in this series currently changes `enrollments.status` away from `"ACTIVE"` to `"COMPLETED"` automatically. This is worth fixing now, as a small addition, so completed courses correctly stop generating reminders regardless of activity recency.

### The Implementation

#### `db/queries/enrollments.ts` (append)

```ts
export async function markEnrollmentCompleted(userId: string, courseId: string) {
  await db
    .update(enrollments)
    .set({ status: "COMPLETED" })
    .where(and(eq(enrollments.userId, userId), eq(enrollments.courseId, courseId)));
}
```

#### `inngest/functions/issue-certificate.ts` (add one step, after `create-certificate` succeeds)

```ts
// Add this import at the top:
import { markEnrollmentCompleted } from "@/db/queries/enrollments";

// Add this step right after the "create-certificate" step succeeds,
// before "send-completion-email":
await step.run("mark-enrollment-completed", async () => {
  await markEnrollmentCompleted(userId, courseId);
});
```

Now `findInactiveEnrollments`'s `eq(enrollments.status, "ACTIVE")` filter (Step 3) automatically and correctly excludes any course a student has already completed — no reminder logic itself needed to change at all.

### The Verification

Re-run the manual backdating test from Step 5 on your already-completed "Introduction to Databases" enrollment (backdate its `last_activity_at` to 8 days ago in Drizzle Studio). Trigger `send-inactivity-reminders` manually and confirm this enrollment is **not** included in the run's output at all — check the `totalInactive` count directly reflects its exclusion, proving `markEnrollmentCompleted` correctly took effect during Part 13's earlier verification (or, if you're testing this fresh, confirm it takes effect now).

```bash
npx tsc --noEmit
npm run build
```

---

## Step 8 — Notification preferences UI and the in-app notification center

### The Target

Adding preference toggles to `/dashboard/settings`, and `components/dashboard/notification-bell.tsx` — a client component in the top bar showing an unread count and a dropdown list.

### The Implementation

#### `lib/validation/notifications.ts`

```ts
import { z } from "zod";

export const updatePreferencesSchema = z.object({
  inactivityRemindersEnabled: z.boolean(),
  weeklyDigestEnabled: z.boolean(),
});
```

#### `app/dashboard/settings/actions.ts`

```ts
"use server";

import { requireUser } from "@/lib/auth/require-user";
import { upsertPreferences } from "@/db/queries/notification-preferences";
import { updatePreferencesSchema } from "@/lib/validation/notifications";
import { revalidatePath } from "next/cache";

export async function updateNotificationPreferences(formData: FormData) {
  const user = await requireUser();
  const parsed = updatePreferencesSchema.safeParse({
    inactivityRemindersEnabled: formData.get("inactivityRemindersEnabled") === "on",
    weeklyDigestEnabled: formData.get("weeklyDigestEnabled") === "on",
  });
  if (!parsed.success) return;

  await upsertPreferences(user.id, parsed.data);
  revalidatePath("/dashboard/settings");
}
```

#### `app/dashboard/settings/page.tsx` (add a preferences section)

```tsx
// Add these imports:
import { getEffectivePreferences } from "@/db/queries/notification-preferences";
import { updateNotificationPreferences } from "./actions";

// Inside SettingsPage, after fetching `user`, add:
const preferences = await getEffectivePreferences(user.id);

// Add this Card after the existing "Account" card:
<Card>
  <CardHeader>
    <CardTitle>Notifications</CardTitle>
  </CardHeader>
  <CardContent>
    <form action={updateNotificationPreferences} className="flex flex-col gap-4">
      <label className="flex items-center justify-between text-sm">
        <span className="text-text-primary">Inactivity reminders</span>
        <input
          type="checkbox"
          name="inactivityRemindersEnabled"
          defaultChecked={preferences.inactivityRemindersEnabled}
        />
      </label>
      <label className="flex items-center justify-between text-sm">
        <span className="text-text-primary">Weekly progress digest</span>
        <input
          type="checkbox"
          name="weeklyDigestEnabled"
          defaultChecked={preferences.weeklyDigestEnabled}
        />
      </label>
      <Button type="submit" variant="primary" size="sm" className="w-fit">
        Save preferences
      </Button>
    </form>
  </CardContent>
</Card>
```

Now the notification bell:

#### `app/dashboard/notifications/actions.ts`

```ts
"use server";

import { requireUser } from "@/lib/auth/require-user";
import { findNotificationsForUser, markAllNotificationsRead } from "@/db/queries/notifications";

export async function getMyNotifications() {
  const user = await requireUser();
  return findNotificationsForUser(user.id);
}

export async function markNotificationsRead() {
  const user = await requireUser();
  await markAllNotificationsRead(user.id);
}
```

#### `components/dashboard/notification-bell.tsx`

```tsx
"use client";

import { useEffect, useState, useTransition } from "react";
import { cn } from "@/lib/cn";
import { getMyNotifications, markNotificationsRead } from "@/app/dashboard/notifications/actions";

interface NotificationItem {
  id: string;
  title: string;
  body: string;
  readAt: Date | null;
  createdAt: Date;
}

export function NotificationBell() {
  const [isOpen, setIsOpen] = useState(false);
  const [notifications, setNotifications] = useState<NotificationItem[]>([]);
  const [isPending, startTransition] = useTransition();

  useEffect(() => {
    startTransition(async () => {
      const data = await getMyNotifications();
      setNotifications(data);
    });
  }, []);

  const unreadCount = notifications.filter((n) => !n.readAt).length;

  function handleOpen() {
    setIsOpen((prev) => !prev);
    if (!isOpen && unreadCount > 0) {
      startTransition(async () => {
        await markNotificationsRead();
        setNotifications((prev) => prev.map((n) => ({ ...n, readAt: n.readAt ?? new Date() })));
      });
    }
  }

  return (
    <div className="relative">
      <button
        onClick={handleOpen}
        aria-label="Notifications"
        className="relative rounded-full p-2 text-text-secondary hover:bg-surface-inset"
      >
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2}>
          <path d="M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" />
          <path d="M13.73 21a2 2 0 0 1-3.46 0" />
        </svg>
        {unreadCount > 0 && (
          <span className="absolute -right-0.5 -top-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-danger text-[10px] font-bold text-white">
            {unreadCount}
          </span>
        )}
      </button>

      {isOpen && (
        <div className="absolute right-0 top-full z-50 mt-2 w-80 rounded-[var(--radius-panel)] border border-border bg-surface p-2 shadow-lg">
          {isPending && notifications.length === 0 ? (
            <p className="p-3 text-sm text-text-muted">Loading...</p>
          ) : notifications.length === 0 ? (
            <p className="p-3 text-sm text-text-muted">No notifications yet.</p>
          ) : (
            <ul className="flex max-h-80 flex-col gap-1 overflow-y-auto">
              {notifications.map((n) => (
                <li
                  key={n.id}
                  className={cn(
                    "rounded-[var(--radius-control)] p-2 text-sm",
                    !n.readAt && "bg-surface-inset"
                  )}
                >
                  <p className="font-medium text-text-primary">{n.title}</p>
                  <p className="text-xs text-text-secondary">{n.body}</p>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}
```

#### `components/dashboard/topbar.tsx` (add the bell)

```tsx
import { UserButton } from "@clerk/nextjs";
import { MobileNav } from "./mobile-nav";
import { NotificationBell } from "./notification-bell";

export function Topbar() {
  return (
    <header className="flex h-16 items-center justify-between border-b border-border bg-surface px-4 lg:px-8">
      <MobileNav />
      <div className="ml-auto flex items-center gap-3">
        <NotificationBell />
        <UserButton afterSignOutUrl="/" />
      </div>
    </header>
  );
}
```

### The Verification

```bash
npm run dev
```

Visit `/dashboard/settings`, confirm both toggles render checked by default (proving the "no row yet = defaults" logic from Step 2), uncheck "Inactivity reminders," save, and confirm the page reflects the saved state after reload.

Visit any dashboard page and confirm a bell icon appears in the top bar. If you have notification rows from Steps 5–6's manual testing, confirm a red unread-count badge appears; click the bell and confirm the dropdown lists them, then confirm the badge disappears (marked read) and persists as read after closing and reopening the dropdown.

Now re-trigger `send-inactivity-reminders` manually for your test student (with reminders now disabled in settings) and confirm the run reports `skippedByPreference: 1` — proof the settings toggle genuinely reaches the cron function's logic.

Run the full verification suite:

```bash
npm run lint
npm run typecheck
npm run build
```

---

## Common mistakes

- **Cron function never appears to run on schedule locally** — Inngest's local dev server only fires cron triggers if it stays running continuously; short-lived local sessions may simply never reach the scheduled time. Always use the dashboard's manual "Invoke" option for local testing, reserving the real schedule for the deployed environment (Part 16).
- **Every student receives a reminder immediately, even active ones** — Double-check the cutoff date direction: `lt(courseProgress.lastActivityAt, cutoffDate)` means "activity is OLDER than the cutoff" — a reversed comparison (`gte` instead of `lt`) would silently invert the entire feature.
- **`findInactiveEnrollments` throws a SQL error about ambiguous columns** — Confirm the `.select({...})` object explicitly aliases every column (as shown) rather than using `.select()` with no arguments across a multi-table join, which can produce naming collisions between tables that share column names.
- **Preferences toggle appears to save but doesn't persist** — Confirm `onConflictDoUpdate`'s `target: [notificationPreferences.userId]` matches the actual unique constraint column exactly, and that the form's checkbox `name` attributes exactly match what the Server Action reads via `formData.get(...)`.
- **Notification bell shows a stale unread count after clicking** — Confirm `handleOpen`'s local state update (`setNotifications` mapping `readAt: n.readAt ?? new Date()`) runs, not just the server-side `markNotificationsRead()` call — without updating local state too, the badge would only clear after a full page reload.

---

## Git checkpoint

```bash
git add .
git status
```

Confirm you see: `db/schema/notifications.ts`, `db/schema/notification-preferences.ts`, `db/schema/index.ts` (modified), `db/migrations/000X_*.sql` (new), `db/queries/notification-preferences.ts`, `db/queries/notifications.ts`, `db/queries/enrollments.ts` (modified), `lib/email/send-reminder-email.ts`, `lib/email/send-digest-email.ts`, `inngest/functions/send-inactivity-reminders.ts`, `inngest/functions/send-weekly-digest.ts`, `inngest/functions/issue-certificate.ts` (modified), `inngest/functions/index.ts` (modified), `lib/validation/notifications.ts`, `app/dashboard/settings/actions.ts`, `app/dashboard/settings/page.tsx` (modified), `app/dashboard/notifications/actions.ts`, `components/dashboard/notification-bell.tsx`, `components/dashboard/topbar.tsx` (modified).

```bash
git commit -m "Part 14: scheduled engagement workflows — inactivity reminders and weekly digest cron functions, notification preferences with safe defaults, in-app notification center, automatic reminder cancellation on completion"
```

---

## Reference: event-triggered vs. cron-triggered functions

| | Event-triggered (Part 12/13) | Cron-triggered (this part) |
|---|---|---|
| Trigger | `{ event: "name" }` | `{ cron: "expression" }` |
| Fires when | Something specific happens, once | On a fixed schedule, regardless of activity |
| Typical data shape | One specific user/course | A batch — must query broadly, then loop |
| Spam-prevention concern | Usually just idempotency (same event twice) | Also: has this same **type** of notification already gone out recently? |

## Reference: the "no row = default" principle

Whenever a preference, setting, or configuration table is *optional* per user (a row only exists once someone customizes something), always resolve missing rows to an explicit, safe default in a single, well-tested helper function — never scatter `?? true` fallbacks across multiple call sites, which risks one of them drifting out of sync with the others over time.

---

## What's next

Part 15 builds the instructor-facing side of everything this series has generated so far: an authorization-protected `/instructor` dashboard, per-course enrollment and completion analytics, a paginated student roster with individual progress inspection, CSV export, and background-materialized summary metrics — turning the raw `module_attempts`, `lesson_progress`, and `certificates` data accumulated since Part 5 into something an instructor can actually act on.
