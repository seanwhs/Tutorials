# Appendix A  — Complete Project Structure Reference

This expanded reference goes beyond a bare file tree. It's organized as a navigable map of the entire GreyMatter LMS codebase as it exists at the end of Part 16: what every file does, which part introduced it, what it depends on, which subsystem it belongs to, and how the pieces connect. Use it as a "you are here" map any time you're unsure where a new feature should live, or need to trace how a request flows through the system.

---

## A.1 How to use this appendix

Four ways to read this document, depending on what you need:

- **"Where does X live?"** → Use the **annotated full tree** (A.2).
- **"What routes exist, and how are they protected?"** → Use the **route map** (A.3).
- **"What does this specific file do, and what does it depend on?"** → Use the **per-directory file reference tables** (A.4).
- **"Which files read which environment variable?"** → Use the **environment variable map** (A.5).

---

## A.2 The full annotated tree

Every file below is tagged with the Part that introduced it `[P#]`, and a one-line purpose.

```text
greymatter-lms/
│
├── app/                                                    ── ROUTING & PRESENTATION LAYER
│   ├── layout.tsx                    [P6]  Root layout — wraps everything in <ClerkProvider>
│   ├── page.tsx                      [P2,6,8]  Public marketing homepage
│   ├── globals.css                   [P2]  Design tokens (:root, .dark, @theme)
│   ├── design-system/
│   │   └── page.tsx                  [P2]  Internal-only component showcase, never linked publicly
│   ├── sign-in/[[...sign-in]]/
│   │   └── page.tsx                  [P6]  Clerk <SignIn/> — optional catch-all route
│   ├── sign-up/[[...sign-up]]/
│   │   └── page.tsx                  [P6]  Clerk <SignUp/> — optional catch-all route
│   ├── studio/[[...tool]]/
│   │   └── page.tsx                  [P3]  Embedded Sanity Studio (<NextStudio/>)
│   │
│   ├── courses/                                            ── PUBLIC (unauthenticated) SURFACE
│   │   ├── page.tsx                  [P4]  Public catalog — courseCatalogQuery
│   │   ├── loading.tsx               [P4]  Skeleton grid shown during fetch
│   │   └── [courseSlug]/
│   │       ├── page.tsx              [P4,8]  Public course detail + EnrollButton/sign-in prompt
│   │       ├── not-found.tsx         [P4]  Friendly 404 — "course doesn't exist / unpublished"
│   │       └── error.tsx             [P4]  Client Component error boundary (transient failures)
│   │
│   ├── dashboard/                                          ── AUTHENTICATED STUDENT SURFACE
│   │   ├── layout.tsx                [P7,14]  requireUser() + Sidebar/Topbar/DashboardProvider
│   │   ├── page.tsx                  [P7]  Enrolled-course grid (getEnrolledCourses)
│   │   ├── loading.tsx               [P7]  Dashboard overview skeleton
│   │   ├── achievements/
│   │   │   └── page.tsx              [P7→P13]  Certificate list (placeholder → real)
│   │   ├── settings/
│   │   │   ├── page.tsx              [P7→P14]  Account info + notification preference toggles
│   │   │   └── actions.ts            [P14]  updateNotificationPreferences Server Action
│   │   ├── notifications/
│   │   │   └── actions.ts            [P14]  getMyNotifications / markNotificationsRead
│   │   └── courses/
│   │       ├── actions.ts            [P8,12]  enrollInCourse Server Action
│   │       └── [courseSlug]/
│   │           ├── page.tsx          [P7,9,13]  Course outline, progress, resume/certificate links
│   │           └── lessons/
│   │               ├── actions.ts    [P9]  markLessonVisited Server Action
│   │               └── [lessonSlug]/
│   │                   └── page.tsx  [P9,10]  The lesson player itself
│   │
│   ├── instructor/                                         ── AUTHENTICATED INSTRUCTOR SURFACE
│   │   ├── layout.tsx                [P15]  requireRole("INSTRUCTOR") + minimal chrome
│   │   ├── page.tsx                  [P15]  This instructor's owned courses
│   │   └── courses/[courseId]/
│   │       ├── page.tsx              [P15]  Course overview (enrollment count)
│   │       ├── students/
│   │       │   ├── page.tsx          [P15]  Paginated roster table
│   │       │   └── actions.ts        [P15]  sendManualReminder Server Action
│   │       └── analytics/
│   │           └── page.tsx          [P15]  Funnel, avg. scores, at-risk students
│   │
│   └── api/                                                ── ROUTE HANDLERS (non-page endpoints)
│       ├── health/route.ts            [P1]  GET — liveness probe
│       ├── webhooks/clerk/route.ts     [P6,12]  POST — Clerk identity sync + Inngest emission
│       ├── inngest/route.ts             [P12]  GET/POST/PUT — Inngest function discovery/invocation
│       ├── certificates/[certificateId]/download/
│       │   └── route.ts                [P13]  GET — on-demand PDF generation, owner-checked
│       └── instructor/courses/[courseId]/students/export/
│           └── route.ts                [P15]  GET — CSV roster export, ownership-checked
│
├── components/                                             ── PRESENTATIONAL LAYER
│   ├── ui/                                                  ── Part 2 design system (no business logic)
│   │   ├── button.tsx, input.tsx, textarea.tsx
│   │   ├── card.tsx, badge.tsx, alert.tsx
│   │   ├── progress-bar.tsx, skeleton.tsx, empty-state.tsx
│   ├── health-check-button.tsx        [P1]  First Client Component example
│   ├── portable-text-renderer.tsx     [P4,10]  PUBLIC Portable Text renderer (static previews only)
│   ├── dashboard/
│   │   ├── sidebar.tsx, mobile-nav.tsx, nav-links.tsx, nav-icon.tsx  [P7]  Nav shell
│   │   ├── topbar.tsx                  [P7,14]  Includes UserButton + NotificationBell
│   │   ├── enroll-button.tsx           [P8]  useActionState-driven enrollment form
│   │   ├── course-outline-nav.tsx      [P7,9]  Shared chapter/lesson nav (dashboard + lesson player)
│   │   └── notification-bell.tsx       [P14]  Client-side notification dropdown
│   ├── lesson/
│   │   ├── video-embed.tsx             [P9]  Allow-listed YouTube/Vimeo embed
│   │   └── interactive-lesson-content.tsx  [P10]  AUTHENTICATED Portable Text renderer (live modules)
│   ├── modules/                                              ── Part 10/11 plugin components
│   │   ├── module-renderer.tsx, module-error-boundary.tsx
│   │   ├── multiple-choice-quiz.tsx, code-exercise.tsx
│   │   ├── reflection-response.tsx, completion-checkpoint.tsx
│   └── instructor/
│       └── remind-student-button.tsx    [P15]  Manual reminder trigger button
│
├── db/                                                      ── TRANSACTIONAL DATA LAYER (Neon)
│   ├── client.ts                        [P5]  Shared Drizzle + Neon HTTP connection
│   ├── transaction-type.ts              [P11]  DbClientOrTransaction shared type
│   ├── seed.ts                          [P5]  Idempotent dev seed script
│   ├── promote-user.ts                  [P15]  Manual role-promotion script
│   ├── schema/                                                ── Table definitions (10 tables)
│   │   ├── index.ts                     [P5→P14]  Re-exports every table
│   │   ├── users.ts                     [P5]  users + userRoleEnum
│   │   ├── enrollments.ts               [P5]  enrollments + enrollmentStatusEnum
│   │   ├── lesson-progress.ts           [P5]  lesson_progress + lessonStatusEnum
│   │   ├── course-progress.ts           [P5,9]  course_progress (+ resume columns)
│   │   ├── module-attempts.ts           [P5,11]  module_attempts (+ idempotency_key)
│   │   ├── certificates.ts              [P5,13]  certificates (+ snapshot columns, sequence)
│   │   ├── webhook-events.ts            [P5]  webhook_events (idempotency ledger)
│   │   ├── workflow-events.ts           [P5]  workflow_events (job observability)
│   │   ├── audit-logs.ts                [P5]  audit_logs
│   │   ├── notifications.ts             [P14]  notifications + notificationTypeEnum
│   │   └── notification-preferences.ts  [P14]  notification_preferences
│   ├── migrations/                                            ── Generated, versioned SQL (never hand-edited)
│   │   └── 0000_*.sql … 000N_*.sql
│   └── queries/                                                ── Hand-written query helper functions
│       ├── users.ts                     [P5,6]  find/create/update/delete by authProviderId
│       ├── enrollments.ts               [P7,8,14]  find/create + batch inactivity/digest queries
│       ├── lesson-progress.ts           [P7,9,11]  progress reads, upsert, mark-completed
│       ├── course-progress.ts           [P12]  aggregate percentage read/update
│       ├── module-attempts.ts           [P10,11,12]  attempt counting, snapshot lookup, idempotency
│       ├── certificates.ts              [P13]  find + atomic sequence-based creation
│       ├── webhook-events.ts            [P6]  idempotent event recording
│       ├── audit-logs.ts                [P11]  append-only audit trail writer
│       ├── workflow-events.ts           [P13]  background job start/status recording
│       ├── notifications.ts             [P14]  create, spam-check, mark read
│       ├── notification-preferences.ts  [P14]  get-with-defaults, upsert
│       ├── create-enrollment.ts         [P8]  the real transactional enrollment writer
│       └── instructor-analytics.ts      [P15]  counts, funnels, averages, at-risk, roster
│
├── inngest/                                                 ── BACKGROUND WORKFLOW LAYER
│   ├── client.ts                        [P12]  Shared Inngest client + typed schemas
│   ├── events.ts                        [P12]  GreyMatterEvents type catalog (4 events)
│   └── functions/
│       ├── index.ts                     [P12→P14]  Central function registry
│       ├── onboard-user.ts              [P12]  user/created
│       ├── confirm-enrollment.ts        [P12]  course/enrolled
│       ├── recalculate-course-progress.ts [P12]  lesson/completed → course/completed
│       ├── issue-certificate.ts         [P13,14]  course/completed → certificate + email
│       ├── send-inactivity-reminders.ts [P14]  cron: daily 09:00 UTC
│       └── send-weekly-digest.ts        [P14]  cron: weekly Monday 08:00 UTC
│
├── lib/                                                     ── SHARED APPLICATION LOGIC
│   ├── cn.ts                            [P2]  clsx + tailwind-merge helper
│   ├── get-app-info.ts                  [P1]  Trivial cross-folder import demo
│   ├── rate-limit.ts                    [P16]  Upstash-backed rate limiter, dev no-op fallback
│   ├── auth/
│   │   ├── get-current-user.ts          [P6,8]  auth() → internal CurrentUser (nullable)
│   │   ├── require-user.ts              [P6]  Non-null guarantee + redirect
│   │   ├── require-role.ts              [P6]  Role-gated guarantee + redirect
│   │   └── ensure-internal-user.ts      [P6,8]  Webhook race-condition fallback
│   ├── validation/
│   │   ├── enrollment.ts                [P8]  enrollInCourseSchema
│   │   └── notifications.ts             [P14]  updatePreferencesSchema
│   ├── dashboard/
│   │   ├── get-enrolled-courses.ts      [P7]  Sanity + Neon merge for the overview page
│   │   ├── get-course-outline.ts        [P7,9]  Enrollment-checked course + progress tree
│   │   ├── get-lesson-for-student.ts    [P9,10]  Enrollment + scope-checked single lesson
│   │   ├── nav-items.ts                 [P7]  Shared sidebar/drawer nav data
│   │   └── dashboard-context.tsx        [P7]  React Context provider (userId/email/role)
│   ├── modules/
│   │   ├── types.ts                     [P10,11]  GreyMatterModuleProps plugin contract
│   │   ├── registry.ts                  [P10,11]  Zod configs + dynamic component map
│   │   ├── grading.ts                   [P11]  Pure, testable server-side grading function
│   │   ├── submission-schema.ts         [P11]  Zod input schema + size/attempt-limit constants
│   │   ├── submit-module-attempt.ts     [P10,11,12,16]  THE secure submission Server Action
│   │   └── use-module-submission.ts     [P11]  Shared useOptimistic submission hook
│   ├── instructor/
│   │   ├── verify-course-ownership.ts   [P15]  Sanity instructor.userId match check
│   │   └── require-course-ownership.ts  [P15]  requireRole + ownership, combined
│   ├── email/
│   │   ├── client.ts                    [P13]  Resend client, null if unconfigured
│   │   ├── send-completion-email.ts     [P13]  Certificate email + HTML escaping
│   │   ├── send-reminder-email.ts       [P14]  Inactivity reminder email
│   │   └── send-digest-email.ts         [P14]  Weekly digest email
│   └── certificates/
│       └── generate-certificate-pdf.ts  [P13]  pdf-lib in-memory PDF generation
│
├── sanity/                                                  ── CONTENT DATA LAYER (Sanity)
│   ├── env.ts                           [P3]  Validated project ID / dataset / API version
│   ├── lib/
│   │   ├── client.ts                    [P3,4]  Shared read-only Sanity client
│   │   ├── image.ts                     [P4]  urlForImage() builder
│   │   └── queries.ts                   [P3→P15]  Every GROQ query + TS interface (largest file in the project)
│   └── schema-types/
│       ├── index.ts                     [P3→P10]  Schema type registry
│       ├── course.ts, chapter.ts, lesson.ts          [P3]  Core hierarchy
│       ├── instructor.ts                [P3,15]  (+ userId link field)
│       ├── category.ts                  [P3]
│       ├── callout-block.ts, quiz-block.ts, code-exercise-block.ts  [P3]
│       └── reflection-block.ts, checkpoint-block.ts   [P10]
│
├── tests/                                                   ── VERIFICATION LAYER
│   ├── unit/
│   │   ├── grading.test.ts              [P16]  gradeSubmission behavior
│   │   ├── validation.test.ts           [P16]  Zod schema edge cases
│   │   └── grading-security.test.ts     [P16]  Regression guard vs. Part 10's vulnerability
│   └── e2e/
│       ├── accessibility.spec.ts        [P16]  axe-core scans
│       └── full-journey.spec.ts         [P16]  The 12-step signup→certificate journey
│
├── docs/
│   └── known-gaps.md                    [P16]  Deliberate scope boundaries, documented
│
├── middleware.ts                        [P6]  clerkMiddleware() request matcher
├── sanity.config.ts                     [P3]  Root Studio configuration
├── drizzle.config.ts                    [P5]  drizzle-kit CLI configuration
├── vitest.config.ts                     [P16]  Unit test runner config
├── playwright.config.ts                 [P16]  E2E test runner config
├── next.config.ts                       [P4]  remotePatterns for Sanity CDN images
├── .env.example                         [P1→P16]  Every environment variable, documented, no values
└── package.json                         [P1→P16]  Scripts + dependencies
```

---

## A.3 The complete route map

Every user-facing route and API endpoint, with its protection level and originating part.

| Route | Type | Protection | Introduced |
|---|---|---|---|
| `/` | Page | Public | P1, styled P2, wired P6/P8 |
| `/design-system` | Page | Public (unlisted) | P2 |
| `/courses` | Page | Public | P4 |
| `/courses/[courseSlug]` | Page | Public | P4, enrollment CTA P8 |
| `/sign-in` | Page | Public | P6 |
| `/sign-up` | Page | Public | P6 |
| `/studio` | Page | Sanity's own login | P3 |
| `/dashboard` | Page | `requireUser()` | P6→P7 |
| `/dashboard/courses/[courseSlug]` | Page | `requireUser()` + enrollment check | P7 |
| `/dashboard/courses/[courseSlug]/lessons/[lessonSlug]` | Page | `requireUser()` + enrollment + course-scoped lesson check | P9 |
| `/dashboard/achievements` | Page | `requireUser()` | P7→P13 |
| `/dashboard/settings` | Page | `requireUser()` | P7→P14 |
| `/instructor` | Page | `requireRole("INSTRUCTOR")` | P15 |
| `/instructor/courses/[courseId]` | Page | `requireRole` + ownership check | P15 |
| `/instructor/courses/[courseId]/students` | Page | `requireRole` + ownership check | P15 |
| `/instructor/courses/[courseId]/analytics` | Page | `requireRole` + ownership check | P15 |
| `GET /api/health` | Route Handler | Public | P1 |
| `POST /api/webhooks/clerk` | Route Handler | Svix signature verification | P6 |
| `GET/POST/PUT /api/inngest` | Route Handler | Inngest signing key (prod) | P12 |
| `GET /api/certificates/[id]/download` | Route Handler | `requireUser()` + owner check | P13 |
| `GET /api/instructor/courses/[id]/students/export` | Route Handler | `requireRole` + ownership check | P15 |

---

## A.4 Per-directory purpose reference

### `app/dashboard/courses/actions.ts` and related Server Actions

| File | Exported function | Trust-boundary layers implemented |
|---|---|---|
| `app/dashboard/courses/actions.ts` | `enrollInCourse` | Auth → Zod → Sanity existence/publish check → duplicate check → atomic write → Inngest emit (P8, P12) |
| `app/dashboard/courses/[courseSlug]/lessons/actions.ts` | `markLessonVisited` | Auth only — best-effort, fire-and-forget (P9) |
| `lib/modules/submit-module-attempt.ts` | `submitModuleAttempt` | Auth → Zod → idempotency → enrollment → scoped assessment lookup → attempt limit → server grading → atomic transaction → Inngest emit (P11, P12, P16 rate limit) |
| `app/instructor/courses/[courseId]/students/actions.ts` | `sendManualReminder` | Ownership check → email send → notification record (P15) |
| `app/dashboard/settings/actions.ts` | `updateNotificationPreferences` | Auth → Zod → upsert (P14) |

### `db/queries/` — every helper's dependency direction

All files in `db/queries/` depend only on `db/client.ts` and `db/schema/`. **None** of them import from `app/`, `components/`, or `sanity/` — this one-way dependency rule is what keeps them independently testable and reusable across page requests (Parts 7–9) and Inngest functions (Parts 12–14) alike.

### `lib/modules/` — the plugin system's internal dependency graph

```text
types.ts  ←── imported by every module component AND registry.ts
registry.ts  ←── imported by module-renderer.tsx only
grading.ts  ←── imported ONLY by submit-module-attempt.ts (never by any component)
submission-schema.ts  ←── imported ONLY by submit-module-attempt.ts
submit-module-attempt.ts  ←── imported by module-renderer.tsx (indirectly, via the submit prop)
use-module-submission.ts  ←── imported by every gradeable module component (quiz, code-exercise)
```

Notice `grading.ts` has exactly **one** importer in the entire codebase — this is deliberate and worth preserving: the moment a second file imports it (especially anything under `components/`), that would be a signal the answer-key logic has leaked toward the client again.

---

## A.5 Environment variable → file map

| Variable | Consumed by | Introduced |
|---|---|---|
| `NEXT_PUBLIC_APP_URL` | `lib/email/*.ts` (link generation) | P1 |
| `NEXT_PUBLIC_SANITY_PROJECT_ID`, `NEXT_PUBLIC_SANITY_DATASET` | `sanity/env.ts` | P3 |
| `SANITY_API_TOKEN` | *(reserved — no file currently requires it; public reads use no token)* | P3 |
| `DATABASE_URL` | `db/client.ts`, `drizzle.config.ts` | P5 |
| `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY` | `app/layout.tsx` (`ClerkProvider`), `middleware.ts` | P6 |
| `CLERK_WEBHOOK_SIGNING_SECRET` | `app/api/webhooks/clerk/route.ts` | P6 |
| `NEXT_PUBLIC_CLERK_SIGN_IN_URL` etc. | Clerk components (implicit, no direct import) | P6 |
| `INNGEST_EVENT_KEY`, `INNGEST_SIGNING_KEY` | `inngest/client.ts` (prod only) | P12 |
| `RESEND_API_KEY` | `lib/email/client.ts` | P13 |
| `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` | `lib/rate-limit.ts` | P16 |

---

## A.6 Growth of the codebase, part by part

A rough sense of how the project accumulated, useful for understanding the pacing of the series:

| Part | New files (approx.) | Primary additions |
|---|---|---|
| 0 | 0 | Planning only |
| 1 | ~8 | Project scaffold, health check |
| 2 | ~12 | Design system components |
| 3 | ~12 | Sanity schemas, embedded Studio |
| 4 | ~7 | Public queries, catalog/detail pages |
| 5 | ~15 | Full Neon schema, Drizzle setup |
| 6 | ~9 | Clerk auth, webhook, auth helpers |
| 7 | ~12 | Dashboard shell, nav, Context |
| 8 | ~5 | Enrollment action + UI |
| 9 | ~6 | Lesson player, video embed |
| 10 | ~14 | Plugin SDK, 4 module components, 2 schemas |
| 11 | ~9 | Secure grading rewrite |
| 12 | ~8 | Inngest client, 3 functions |
| 13 | ~10 | Certificates, PDF, email |
| 14 | ~13 | Notifications, 2 cron functions |
| 15 | ~11 | Instructor dashboard, analytics |
| 16 | ~10 | Tests, rate limiting, deployment config |

**Total: roughly 160+ files**, none of them containing a placeholder or a `// TODO` — every single one is complete, working code as of the part that introduced it.

---

## A.7 Naming conventions used throughout

Consistent naming was maintained across all sixteen parts — worth stating explicitly, since it's easy to drift from without noticing:

| Convention | Example |
|---|---|
| Files: kebab-case | `get-course-outline.ts`, `multiple-choice-quiz.tsx` |
| React components: PascalCase, matching filename | `CourseOutlineNav` in `course-outline-nav.tsx` |
| Server Actions: verb-first camelCase | `enrollInCourse`, `submitModuleAttempt`, `markLessonVisited` |
| Query helpers: `find*` (read), `create*`/`upsert*` (write), `update*`, `delete*` | `findEnrollment`, `createEnrollmentWithProgress` |
| Zod schemas: `*Schema` suffix | `enrollInCourseSchema`, `submitModuleAttemptSchema` |
| Drizzle tables: plural snake_case in SQL, camelCase in TS | `module_attempts` table ↔ `moduleAttempts` export |
| Inngest events: `noun/verb-past-tense` | `course/enrolled`, `lesson/completed` |
| Inngest function IDs: kebab-case, verb-first | `"issue-certificate"`, `"recalculate-course-progress"` |
