# Building GreyMatter LMS: What It Actually Takes to Make a Quiz Answer Trustworthy

*A technical deep-dive into the architecture, security model, and hard-won lessons behind a full-stack learning management system built on Next.js, Sanity, Neon, and Inngest.*

---

## Introduction: The Question Nobody Asks Until It's Too Late

Here's a question worth sitting with for a moment: when a student clicks "Submit" on a quiz answer in your LMS, who decides whether they got it right?

If your honest answer is "the browser computes it, and sends the result to the server to save," you have a problem — and it's not a hypothetical one. It's a problem we built, on purpose, into an early version of GreyMatter LMS, specifically so we could watch it fail and then fix it properly. That story — the vulnerability, the exploit, and the fix — is the spine of this post, because it's the single decision that shaped almost everything else about how this system is architected.

GreyMatter LMS is a full-stack learning management system: course catalog, enrollment, a lesson player, interactive assessments, automated certificates, instructor analytics, scheduled learner engagement, and a production deployment across five external services. This post isn't a feature tour. It's an explanation of the *architecture underneath* those features — why the data lives where it lives, why the background jobs exist, and why the security model looks the way it does. If you're building something similar, or just curious what a genuinely defensible LMS architecture looks like under the hood, this is for you.

---

## Part 1: Two Databases, One Clear Reason

The first architectural decision in GreyMatter LMS — and the one every other decision traces back to — is that there are **two separate databases**, not one.

- **Sanity** (a headless CMS) holds courses, chapters, lessons, quiz definitions, instructor bios. Content.
- **Neon** (serverless PostgreSQL) holds users, enrollments, progress, assessment attempts, certificates. Transactional state.

This split isn't a stylistic preference or a "microservices are cool" decision. It comes from asking one honest question about every piece of data in the system: *is this the same for every user and edited rarely, or is it unique to one user and changing constantly?*

A course title is the first kind of thing. Every student sees the identical title; an instructor edits it once every few months. A student's quiz score is the second kind. It's true only for that student, and it changes every time they submit something.

Cramming both kinds of data into one database works fine for a toy project, but it starts to hurt the moment you care about either side doing its job well. Content needs rich authoring tools, a review/draft workflow, and cheap, cacheable public reads. Transactional data needs strict consistency, real constraints, and fast per-user writes. Optimizing one database for both is optimizing for neither.

So GreyMatter draws a hard line:

```text
                    ┌─────────────────────────────┐
                    │   Is this the SAME for every  │
                    │   user, and edited RARELY?      │
                    └───────────┬─────────────────┘
                       Yes ▼                ▼ No
              ┌──────────────────┐   ┌──────────────────────┐
              │      SANITY        │   │  Is this UNIQUE per     │
              │  (content system)   │   │  user, and changes       │
              │                     │   │  FREQUENTLY?              │
              └──────────────────┘   └───────────┬──────────┘
                                          Yes ▼
                                    ┌──────────────────┐
                                    │       NEON          │
                                    │ (transactional        │
                                    │      system)            │
                                    └──────────────────┘
```

This decision rule sounds almost too simple to matter, but it's the thing that keeps a codebase honest as it grows. When a new feature comes along, the question "which database does this belong in" almost always has an obvious answer, because the rule is doing the work, not vibes.

### The cost of this decision: no foreign keys across the seam

Here's the part that's less convenient, and worth being honest about. PostgreSQL is extremely good at enforcing relationships — a foreign key means the database *physically refuses* to let you insert a row pointing at something that doesn't exist. But that guarantee only works within Postgres. The moment `enrollments.course_id` needs to point at a document living in Sanity, that guarantee evaporates. Postgres has no idea Sanity exists.

So `course_id`, `lesson_id`, and `module_id` in Neon are just... text fields. Plain strings. Nothing stops you from inserting `enrollments.course_id = "this-does-not-exist"` at the database level.

This isn't an oversight — it's the direct, unavoidable price of the two-database decision, and it's worth naming explicitly rather than pretending it away. The consequence is that **every single code path touching one of these fields has to independently re-verify the relationship it implies**, every time, because the database can't do it for you. This single fact ends up explaining an enormous amount of the code in this system, so it's worth internalizing before moving on.

---

## Part 2: The Attack We Built on Purpose

Now here's where it gets interesting.

Early in development, we built the interactive assessment system — quizzes, code exercises, reflections, checkpoints — as a proper plugin architecture. Each module type is a React component implementing a shared contract: it gets a config (the authored question), a prior attempt if one exists, and a `submit` function. Clean, extensible, exactly the kind of thing you'd be proud to show in a design review.

And then we shipped it with client-side grading. On purpose.

Here's what that looked like. The quiz component received the full quiz block from Sanity — question, options, *and* the correct answer index:

```ts
export const quizConfigSchema = z.object({
  moduleId: z.string().min(1),
  question: z.string().min(1),
  options: z.array(z.string().min(1)).min(2),
  correctOptionIndex: z.number().int().min(0), // ← sitting right there
});
```

And the component computed correctness locally, in the browser:

```tsx
function handleSubmit() {
  if (selectedIndex === null) return;

  // ⚠️ NAIVE, CLIENT-SIDE GRADING ⚠️
  const isCorrect = selectedIndex === config.correctOptionIndex;

  startTransition(async () => {
    const outcome = await submit({ selectedOptionIndex: selectedIndex }, { isCorrect });
    setResult(outcome);
  });
}
```

The server accepted that `isCorrect` value and just... saved it.

If you've spent any time thinking about web security, you already know exactly what's wrong here, and you're right. Here's the actual exploit, reproduced with nothing more exotic than a browser's built-in developer tools:

1. Open a lesson with a quiz. Select the wrong answer on purpose.
2. Open DevTools → Network tab.
3. Click Submit. Watch the outgoing request. Right there in the payload: `clientComputedIsCorrect: false`.
4. Right-click → Copy as fetch. Paste into the console. Change `false` to `true`. Hit enter.
5. Refresh the page.

The quiz now shows as correctly answered. Permanently. In the production database. For an answer that was, factually, wrong.

We didn't discover this by accident during a pen test — we built it deliberately, as a teaching device, specifically so that fixing it would land with real weight instead of being an abstract warning. There is a particular kind of clarity that comes from watching a vulnerability work with your own hands, on your own system, using a tool as mundane as "Copy as fetch." It's not theoretical anymore. It's a checkbox in a network tab away from being exploited by literally anyone who's ever opened DevTools out of curiosity.

### The fix, and why it required deleting code, not adding it

The fix is conceptually simple to state and genuinely important to internalize: **the answer key must never leave the server.** Not "must be hidden by the UI." Not "must be obfuscated." Must never be present in any response the browser ever receives, full stop.

Here's the query that used to feed the lesson player:

```groq
content[]{
  ...
}
```

That `...` spreads every field of every block — including `correctOptionIndex`. The fix replaced it with an explicit, restrictive projection:

```groq
content[]{
  ...,
  _type == "quizBlock" => {
    _type, _key, moduleId, question, options
    // correctOptionIndex deliberately absent
  },
  _type == "codeExerciseBlock" => {
    _type, _key, moduleId, prompt, language, starterCode
    // expectedKeywords deliberately absent
  }
}
```

And grading moved entirely server-side, into a pure, independently-testable function:

```ts
export function gradeSubmission(
  assessment: AssessmentDefinition,
  rawSubmission: unknown
): GradingOutcome {
  switch (assessment._type) {
    case "quizBlock": {
      const parsed = quizSubmissionSchema.safeParse(rawSubmission);
      if (!parsed.success) throw new ModuleGradingError("...");
      const isCorrect = parsed.data.selectedOptionIndex === assessment.correctOptionIndex;
      return { isCorrect, score: isCorrect ? 100 : 0 };
    }
    // ...
  }
}
```

This function is called from exactly one place: a Server Action that independently re-fetches the answer key from Sanity, scoped through a query that proves the module genuinely belongs to the claimed lesson and course — not just "a module with this ID exists somewhere."

The genuinely interesting thing about this fix, and the reason it's worth dwelling on: **it made the plugin components simpler, not more complex.** The quiz component no longer computes anything. It collects a raw answer and hands it to `submit()`. There's less code, not more. Good security fixes often look like this — they remove a responsibility that never should have existed on that side of the boundary in the first place, rather than bolting on a defensive patch.

### Now it's permanent, not just fixed

Fixing a vulnerability once is good. Making it structurally impossible to silently reintroduce is better. So there's a dedicated regression test whose entire job is asserting the bad fields can never come back:

```ts
describe("module config schemas never accept answer-key fields", () => {
  it("quizConfigSchema does not define a correctOptionIndex field", () => {
    expect(quizConfigSchema.shape).not.toHaveProperty("correctOptionIndex");
  });

  it("codeExerciseConfigSchema does not define an expectedKeywords field", () => {
    expect(codeExerciseConfigSchema.shape).not.toHaveProperty("expectedKeywords");
  });
});
```

This test doesn't test *behavior* in the usual sense. It tests an *architectural invariant*. If someone six months from now, under deadline pressure, "helpfully" adds `correctOptionIndex` back to the config schema to simplify some refactor, this test fails immediately, loudly, in CI — before it ever reaches a real user's browser. That's the difference between "we fixed a bug" and "we closed a category of bug permanently."

---

## Part 3: Trust Boundaries as a Design Discipline, Not a Checklist

The quiz-grading story is the sharpest example in the system, but it's really an instance of a much more general principle that shows up everywhere: **anything the browser sends is a claim, not a fact, and every server-side operation has to independently verify the claims that matter.**

This shows up as a repeated, almost mechanical pattern across the whole codebase. Take enrollment. When a student clicks "Enroll," the browser sends exactly one thing: a course ID. Here's the actual server-side reasoning, laid out as a table before any code was written:

| Claim | Trusted from the browser? |
|---|---|
| "I am user X" | No — derived independently from the verified session |
| "This course ID exists" | No |
| "This course is published" | No |
| "I haven't already enrolled" | No |

Every "No" in that table becomes an explicit, independent check in the Server Action:

```ts
export async function enrollInCourse(previousState, formData) {
  const user = await requireUser();                    // who are you, really?
  const { courseId } = enrollInCourseSchema.parse(...); // is this even shaped right?

  const course = await client.fetch(courseExistsAndPublishedQuery, { courseId });
  if (!course || !course.isPublished) {
    return { success: false, error: "This course is not available for enrollment." };
  }

  const existing = await findEnrollment(user.id, courseId);
  if (existing) {
    return { success: false, error: "You are already enrolled in this course." };
  }

  await createEnrollmentWithProgress({ userId: user.id, courseId });
  await inngest.send({ name: "course/enrolled", data: { userId: user.id, courseId } });
  return { success: true };
}
```

Notice what's *not* here: nowhere does the function trust the client's belief about whether the course is published, whether it exists, or whether the user is already enrolled. Every one of those facts is independently re-derived, every single time, regardless of what the UI currently shows.

### The same pattern, one level deeper: resource ownership

The same discipline applies to authorization, not just data validity. Consider the course dashboard page. Being signed in isn't enough to see a course's content — you specifically need to be enrolled in *that* course. And here's the subtle, important detail: when access is denied, the system doesn't say "access denied." It returns exactly the same response as "this course doesn't exist":

```ts
export async function getCourseOutline(userId: string, courseSlug: string) {
  const course = await client.fetch(courseDetailQuery, { slug: courseSlug });
  if (!course) return null;

  const enrollments = await findActiveEnrollmentsForUser(userId);
  const isEnrolled = enrollments.some(e => e.courseId === course._id && e.status !== "CANCELLED");
  if (!isEnrolled) return null; // identical to "doesn't exist"

  // ... only reachable if genuinely enrolled ...
}
```

Why collapse these two cases? Because distinguishing them would leak information. If unauthorized visitors got a distinct "you're not enrolled in *this specific, real* course" message versus "no such course," you've just handed them a free way to enumerate which course slugs are real, without ever needing valid access. Returning the identical `null` — and the identical HTTP 404 at the page level — means an attacker learns nothing by probing.

This exact two-part shape — route-level authentication, then resource-level authorization, both required, neither sufficient alone, and both failing identically — repeats for enrollment, lesson access, module submissions, certificate downloads, and instructor course ownership. Once you've internalized it once, you recognize it everywhere in the system, which is exactly the point: consistency here isn't an aesthetic preference, it's what makes a *missing* instance of the pattern visible to a reviewer instead of hidden in the noise.

---

## Part 4: Races Are Real, and "Check Then Insert" Isn't Enough

Here's a bug that's genuinely easy to miss in code review, because the code *looks* correct:

```ts
const existing = await findEnrollment(userId, courseId);
if (existing) {
  return { error: "Already enrolled" };
}
await createEnrollment(userId, courseId);
```

Check first, then act. Seems fine. It's also broken under concurrency, and the reason is worth spelling out precisely, because "race condition" is one of those terms people nod along to without always internalizing the mechanism.

Imagine two requests — a student double-clicking Enroll, or two browser tabs — arriving close enough together in time that **both** of them run `findEnrollment` and both see "nothing exists yet," *before either one has written anything*. Both proceed to insert. You now have two enrollment rows for one student and one course, and every downstream assumption in the system that expected "at most one enrollment per user per course" is quietly wrong.

```text
Request A: ── findEnrollment() → "none found" ──────── createEnrollment() ──►
Request B:      ── findEnrollment() → "none found" ──────── createEnrollment() ──►
                        ▲
                  Both checks land in the gap BEFORE either insert
```

No amount of careful application-code review closes this gap, because the gap isn't a logic error — it's a timing problem, and timing problems don't yield to "just write better code." The only thing that actually closes it is a guarantee that doesn't depend on timing at all: a database-level unique constraint.

```ts
export const enrollments = pgTable(
  "enrollments",
  { /* columns */ },
  (table) => [
    unique("enrollments_user_course_unique").on(table.userId, table.courseId),
  ]
);
```

With this constraint in place, even if both requests' "check" phases both say "clear to proceed," only **one** of the two `INSERT` statements can actually succeed. Postgres enforces this atomically, at the moment of insertion, regardless of how close together in time the two requests arrive. The second insert throws a constraint-violation error, which the application catches and converts into a friendly, honest "you're already enrolled" — not a crash, not silent data corruption.

We didn't just assert this works — we proved it, with a script that fires two enrollment attempts at genuinely the same instant using `Promise.allSettled`:

```ts
const results = await Promise.allSettled([
  createEnrollmentWithProgress({ userId: user.id, courseId: SAMPLE_COURSE_ID }),
  createEnrollmentWithProgress({ userId: user.id, courseId: SAMPLE_COURSE_ID }),
]);
```

Run it, and you reliably see exactly one `fulfilled` and one `rejected` — never both succeeding, never both failing. The exact same pattern — application-level check as a UX nicety, database constraint as the actual guarantee, with a graceful catch-and-recover on the losing side — reappears for certificate issuance, where two near-simultaneous course-completion signals could otherwise both try to issue a certificate for the same student and course.

The lesson generalizes well beyond this one system: **whenever you find yourself writing "check if it exists, then insert," ask whether the "at most one" guarantee is genuinely enforced by the database, or only by the hope that your check-then-act window is too narrow for anyone to hit.** It's never too narrow. Traffic finds the gap eventually.

---

## Part 5: Not Everything Needs to Happen Right Now

A different kind of architectural decision governs the other half of the system: **what has to complete before the browser gets its response, and what can happen a moment later?**

Recall the bank-teller mental model: a teller confirms your deposit instantly and hands you a receipt. The check actually clearing, the interest recalculating, the monthly statement generating — none of that needs you standing at the counter. It happens afterward, reliably, without blocking the thing you were actually there for.

GreyMatter draws this line explicitly. When a student submits a quiz answer, the synchronous, must-happen-now part is: validate the input, verify enrollment, grade it server-side, and record the result. That's it. Recalculating the *whole course's* completion percentage, checking whether a certificate should be issued, sending a completion email — none of that needs to hold up the response the student is staring at.

```ts
await db.transaction(async (tx) => {
  await tx.insert(moduleAttempts).values({ /* ... */ });
  await upsertLessonProgress(tx, { /* ... */ });
  await recordAuditLog(tx, { /* ... */ });
});

// AFTER the transaction commits — not before, not inside it
await inngest.send({ name: "lesson/completed", data: { userId, courseId, lessonId } });
```

That last line matters more than it looks like it should. The event is emitted strictly **after** the transaction commits, never inside it. If it were emitted from inside the transaction and the transaction later rolled back, you'd have told the background workflow engine that something happened which, from the database's own perspective, never actually did. Ordering here isn't a stylistic choice — it's the difference between an event stream that's trustworthy and one that occasionally lies.

The background side of this is handled by Inngest, and the whole point of a dedicated workflow engine (versus, say, a cron script or a manually-managed queue) is that it gives you two things almost for free: automatic, granular retries, and step-level caching.

```ts
export const issueCertificate = inngest.createFunction(
  { id: "issue-certificate" },
  { event: "course/completed" },
  async ({ event, step }) => {
    const progress = await step.run("verify-completion", async () => {
      return findCourseProgressRow(event.data.userId, event.data.courseId);
    });

    if (!progress || progress.completionPercentage !== 100) {
      return { issued: false, reason: "not_actually_complete" };
    }

    const existing = await step.run("check-existing-certificate", async () => {
      return findCertificate(event.data.userId, event.data.courseId);
    });

    if (existing) {
      return { issued: false, reason: "already_issued" };
    }

    // ... generate certificate, send email, each its own step ...
  }
);
```

Each `step.run` is independently cached and independently retryable. If "send the completion email" fails because the email provider had a momentary hiccup, the function retries — but it does **not** re-verify completion, re-check for an existing certificate, or (worse) re-issue a second certificate number. Only the failed step re-executes. This matters enormously once you're sending emails: you really don't want "retry the whole function" to mean "maybe send the same congratulations email twice."

Notice also the *first* thing this function does after confirming the trigger: it re-verifies completion is genuinely 100%, from the database, rather than trusting the event that triggered it. Even an internal, server-generated event doesn't get a free pass — the same "never trust the incoming claim, re-derive the fact" discipline from Part 3 applies here too, just applied to an internal signal instead of a browser request.

---

## Part 6: Scheduled Work Has Its Own Failure Mode, and It's Not the One You'd Guess

Reminder emails seem like the simplest feature in the whole system. "If a student's been inactive for a week, email them." What could go wrong?

The actual failure mode isn't logical — it's about *time itself* being a trigger with no natural rate limit. A cron job runs on a schedule, not in response to a specific user action, which means a single design mistake can affect every eligible student simultaneously, repeatedly, forever, unless you build in the guardrails explicitly.

Two guardrails turned out to matter in practice.

**First: spam prevention has to be independent of the cron schedule's own frequency.** The reminder job runs daily. But "inactive for 7+ days" shouldn't mean "email them every single day for as long as they stay inactive." So before sending anything, the function checks whether this specific student has already received this specific notification type within the last 7 days:

```ts
const alreadyReminded = await hasRecentNotification(
  enrollment.userId,
  "INACTIVITY_REMINDER",
  sevenDaysAgo
);
if (alreadyReminded) {
  return "skipped_already_sent" as const;
}
```

**Second — and this one is subtler — "no preference record exists" must resolve to the enabled default, never to an implicit opt-out.** Preferences are optional; a student who's never visited Settings has no row in `notification_preferences` at all. If the code treated "no row" as "disabled," you'd have silently opted every single existing user out of reminders the instant this feature shipped, with zero visible error and zero way to notice except a slow, mysterious decline in engagement. This resolution logic lives in exactly one function, everywhere:

```ts
export async function getEffectivePreferences(userId: string): Promise<EffectivePreferences> {
  const row = await db.query.notificationPreferences.findFirst({
    where: eq(notificationPreferences.userId, userId),
  });
  return {
    inactivityRemindersEnabled: row?.inactivityRemindersEnabled ?? true,
    weeklyDigestEnabled: row?.weeklyDigestEnabled ?? true,
  };
}
```

That single `?? true` on each line is doing an enormous amount of quiet, important work. It's centralized deliberately — every caller resolves preferences through this one function, never by querying the table directly and improvising a default inline, because two slightly different improvised defaults scattered across the codebase is exactly how this kind of bug sneaks in.

There's also a design choice about *how* to process a batch of candidates that's worth naming, because it's counterintuitive if your instinct is "parallelize everything." The reminder function loops through inactive students **sequentially**, each as its own independently-named, independently-retryable step:

```ts
for (const enrollment of inactiveEnrollments) {
  const outcome = await step.run(`process-enrollment-${enrollment.enrollmentId}`, async () => {
    // check preferences, check spam guard, send email, record notification
  });
}
```

Not `Promise.all`. Sequentially, one at a time. This is slower in wall-clock terms, and that's a deliberate trade against a real alternative concern: firing two hundred emails simultaneously risks bursting past an email provider's own rate limits, and — more importantly for a feature whose entire value proposition is "never send a duplicate reminder" — a partial failure partway through a sequential loop leaves you with a clean, resumable trail (student #1 through #46 already processed successfully; only #47 needs retrying), whereas a parallel batch failing partway through is much harder to reason about cleanly. At GreyMatter's documented scale, this is the right trade. At meaningfully larger scale, it stops being the right trade, and the system's own documentation says so explicitly rather than pretending the current design scales forever — a two-function, event-per-candidate pattern is the documented next step, deliberately not implemented until the scale that would actually justify its added complexity.

---

## Part 7: Certificates Are a Lesson in Snapshotting

Certificate issuance sounds like the most straightforward feature in the entire system — congratulations, here's a PDF — but it hides one of the more interesting modeling decisions in the whole codebase.

The naive approach: store `user_id` and `course_id` on the certificate, and whenever someone wants to view or download it, join live against the current `users` and Sanity `course` records to get the display name and course title.

Here's why that's wrong, concretely. Suppose an instructor renames "Introduction to Databases" to "Database Fundamentals" a year after a student earned their certificate. With a live join, every previously-issued certificate for that course silently changes its displayed title, retroactively, the moment the rename happens. That's not merely surprising — it's actively dishonest. The certificate is supposed to represent "you completed a specific thing, as it existed, at a specific moment." A live join makes it represent "whatever this thing happens to be called *right now*," which is a completely different, and wrong, claim.

The fix is to snapshot the facts that matter, permanently, onto the certificate row itself, at the moment of issuance:

```ts
export const certificates = pgTable("certificates", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  courseId: text("course_id").notNull(),
  certificateNumber: text("certificate_number").notNull().unique(),

  // Snapshots — captured once, at issuance, never touched again
  courseTitle: text("course_title").notNull(),
  recipientEmail: text("recipient_email").notNull(),

  issuedAt: timestamp("issued_at", { withTimezone: true }).notNull().defaultNow(),
});
```

Once written, `courseTitle` and `recipientEmail` are frozen. The course can be renamed, the student's account email can change — the certificate keeps telling the truth about the moment it was earned. This also has a genuinely nice side effect on the implementation side: generating a PDF becomes trivially self-contained. No live Sanity query, no live user lookup — everything needed to render the certificate is already sitting right there on the row.

Certificate numbering has its own small, deliberate design decision worth mentioning. It would be tempting to compute "the next number" by counting existing certificates in application code — `SELECT COUNT(*) FROM certificates` plus one. But that's exactly the same check-then-act race condition from Part 4, just wearing a different outfit. Instead, numbering uses a genuine Postgres sequence:

```sql
CREATE SEQUENCE certificate_number_seq START WITH 1 INCREMENT BY 1;
```

```ts
const result = await client.execute(sql`select nextval('certificate_number_seq') as val`);
```

A database sequence is atomic by construction — two concurrent calls to `nextval()` can never return the same value, no matter how close together they happen. Same underlying lesson as the unique constraints in Part 4, applied to a slightly different problem: numbering rather than existence-checking.

---

## Part 8: A Registry, Not a Switch Statement

The interactive assessment system deserves a mention purely as a piece of extensibility design, separate from its security story. Five module types exist today — multiple-choice quiz, code exercise, reflection, and completion checkpoint — and the system is built so a sixth can be added without touching the lesson player at all.

The mechanism is a typed registry mapping a Sanity content block's `_type` to a validation schema and a lazily-loaded component:

```ts
export const moduleRegistry = {
  quizBlock: {
    configSchema: quizConfigSchema,
    component: dynamic(() => import("@/components/modules/multiple-choice-quiz").then(m => m.MultipleChoiceQuiz)),
  },
  codeExerciseBlock: {
    configSchema: codeExerciseConfigSchema,
    component: dynamic(() => import("@/components/modules/code-exercise").then(m => m.CodeExercise)),
  },
  // ...
} as const;
```

Two things worth calling out here. First, `dynamic()` means a lesson with no code exercise in it never pays the bundle-size cost of the code-exercise component's JavaScript — it's only fetched when a lesson genuinely contains one. Second, and more important: every block gets validated against its Zod schema **at render time**, not just at authoring time in Sanity Studio. This matters because Sanity's own schema validation only protects *authoring* — it says nothing about a manual API edit, a schema migration gap, or older content authored before a field existed, any of which could produce data that doesn't match what the React component expects. Re-validating at the boundary where content actually enters the render tree is a second, independent check, and it fails gracefully rather than crashing the page:

```tsx
if (!isKnownModuleType(_type)) {
  return <Alert variant="warning">This lesson contains an interactive element ("{_type}")
    that isn't supported by this version of the app yet.</Alert>;
}

const parsedConfig = entry.configSchema.safeParse(block);
if (!parsedConfig.success) {
  return <Alert variant="danger">This interactive element is misconfigured
    and can't be displayed.</Alert>;
}
```

Three distinct, honestly-labeled failure modes — "our code is older than this content," "this content itself is broken," and (via a wrapping error boundary) "a genuine bug happened while rendering" — rather than one generic catch-all "something went wrong" that tells nobody anything useful about what actually happened.

---

## Part 9: What This Buys You, and What It Costs

None of this is free. Two databases mean two things to keep in sync conceptually, and a whole class of verification work (the scoped queries) that a single-database system wouldn't need. A background workflow engine means eventual consistency for things like course-completion percentage — there's a real, if brief, window where a student has technically finished a course but the certificate hasn't landed yet. Database constraints mean occasionally catching and interpreting a constraint-violation error rather than a cleaner application-level rejection.

But look at what each cost buys:

- The Sanity/Neon split buys content and transactional data each getting a storage engine actually suited to it, and it buys a hard architectural line that keeps "where does this belong" from ever being a judgment call six parts into a project.
- The server-exclusive grading model buys the one guarantee an LMS genuinely cannot function without: a grade means what it says it means.
- Database-enforced uniqueness buys correctness that holds *regardless of load*, not correctness that happens to hold in the traffic patterns you tested against.
- The Inngest split buys a request/response cycle that stays fast and simple, with reliability for the slower stuff handled by a system actually designed for retries and durability.
- Snapshotting on certificates buys a permanent record that means what it claimed to mean the day it was issued, forever, regardless of what happens to the source data afterward.

If there's one thread tying all of this together, it's that almost none of these decisions were about making the happy path prettier. They were about being honest, ahead of time, about what happens when something goes wrong — a network retry, two requests at once, a stale cache, a curious user with DevTools open — and building the system so that the *correct* thing happens automatically in that moment, rather than depending on nobody ever hitting the edge case.

The quiz-grading vulnerability, in particular, is worth remembering not as an embarrassing anecdote but as the clearest possible demonstration of a principle that's easy to state and surprisingly easy to violate in practice: **the browser can send anything. Design as if it will.**
