# GreyMatter LMS — Coding Style Guide

**Document type:** Coding Style Guide
**Product:** GreyMatter LMS
**Version:** 1.0
**Status:** Baseline — approved
**Location:** `docs/CODING_STYLE_GUIDE.md`
**Companion documents:** `docs/ARCHITECTURE.md`, `docs/ONBOARDING.md`, `docs/API_REFERENCE.md`, Appendix A, Appendix D

---

## 1. Purpose and Philosophy

This guide codifies the conventions already established, consistently, across every part of the GreyMatter LMS implementation. It is not a generic style guide adapted to this project — every rule below is extracted from an actual, repeated pattern in the codebase, with a rationale grounded in this system's own architecture and security model, not an appeal to abstract "best practice."

The guiding principle behind every convention here is the same one stated in `docs/ONBOARDING.md`'s Code Review Standards: **consistency is a security property, not just an aesthetic one.** A codebase where authorization checks, transaction boundaries, and error handling all follow the identical shape everywhere is a codebase where a *missing* instance of that shape is immediately visible to a reviewer. A codebase with inconsistent style hides that same omission in noise. Every rule in this document exists to keep deviations visible.

---

## 2. Language and Type System Conventions

### 2.1 TypeScript strict mode is non-negotiable

`strict: true` has been enabled since the project's first commit (`tsconfig.json`, Part 1). Never disable strict mode, or any of its constituent flags, to work around a type error — the type error is telling you something real. If a genuine escape hatch is needed, it must be `unknown` with an explicit narrowing step (Section 2.3), never `any`.

### 2.2 Prefer type inference; annotate deliberately, not habitually

```ts
// GOOD — let TypeScript infer the obvious
const studentName = "Ada Lovelace";
const enrollmentCount = 42;

// GOOD — explicit annotation where TypeScript cannot infer
// (function parameters) or where the annotation IS the contract
// (function return types on exported functions)
function formatGreeting(name: string): string {
  return `Welcome, ${name}!`;
}

// AVOID — redundant annotation adding noise, not clarity
const studentName: string = "Ada Lovelace";
```

**Rule:** annotate function parameters always. Annotate function return types on every **exported** function (it documents the contract for callers) but you may omit them on small, private, inferred-obviously helper functions.

### 2.3 `unknown`, never `any`

Any value crossing a trust boundary — a Server Action's raw input, a webhook payload before verification, a Sanity query result before it's cast — is typed `unknown` and narrowed explicitly before use, typically via a Zod schema (Section 4).

```ts
// GOOD — from the actual codebase pattern
export async function submitModuleAttempt(input: unknown): Promise<ModuleSubmissionResult> {
  const parsed = submitModuleAttemptSchema.safeParse(input);
  if (!parsed.success) {
    return errorResult("INVALID_SUBMISSION", "Invalid submission.");
  }
  // parsed.data is now a known, narrowed shape
}

// NEVER — any silently disables checking for everything downstream
export async function submitModuleAttempt(input: any) { ... }
```

If you find yourself reaching for `any`, stop and ask what shape you actually expect, and validate it. There is no accepted use of `any` anywhere in this codebase.

### 2.4 Interfaces for object shapes; type aliases for unions and derived types

```ts
// Object shapes → interface
export interface CourseCard {
  _id: string;
  title: string;
  slug: SanitySlug;
}

// Unions and derived types → type
export type UserRole = "STUDENT" | "INSTRUCTOR" | "ADMIN";
export type SubmitModuleAttemptInput = z.infer<typeof submitModuleAttemptSchema>;
```

Use `extends` to build one interface on top of another rather than duplicating shared fields:

```ts
export interface CourseDetail extends CourseCard {
  learningObjectives: string[];
  chapters: ChapterSummary[];
}
```

### 2.5 Derive types from runtime schemas — never maintain two parallel definitions

Every validated input type is derived via `z.infer<typeof schema>`, never hand-written separately alongside its schema. This is a hard rule, not a preference — see `docs/SRD.md` NFR-MAINT-1.

```ts
// GOOD
const enrollInCourseSchema = z.object({
  courseId: z.string().trim().min(1).max(200),
});
export type EnrollInCourseInput = z.infer<typeof enrollInCourseSchema>;

// NEVER — a second, hand-maintained definition that can silently drift
interface EnrollInCourseInput {
  courseId: string;
}
const enrollInCourseSchema = z.object({ courseId: z.string() });
```

---

## 3. File and Naming Conventions

| Element | Convention | Example |
|---|---|---|
| File names | kebab-case | `get-course-outline.ts`, `multiple-choice-quiz.tsx` |
| React component names | PascalCase, matches its file | `CourseOutlineNav` in `course-outline-nav.tsx` |
| Server Actions | verb-first camelCase | `enrollInCourse`, `submitModuleAttempt`, `markLessonVisited` |
| Query helper functions | `find*` (read one/many), `create*`, `update*`, `upsert*`, `delete*`, `mark*` | `findEnrollment`, `createEnrollmentWithProgress`, `markLessonCompleted` |
| Zod schemas | `*Schema` suffix | `enrollInCourseSchema`, `submitModuleAttemptSchema` |
| Drizzle tables | plural snake_case in SQL, camelCase in TS | `module_attempts` ↔ `moduleAttempts` |
| Inngest events | `noun/verb-past-tense` | `course/enrolled`, `lesson/completed` |
| Inngest function IDs | kebab-case, verb-first | `"issue-certificate"`, `"recalculate-course-progress"` |
| Boolean fields/props | `is*` prefix or `*Enabled` suffix | `isPublished`, `isPreview`, `inactivityRemindersEnabled` |
| Timestamp fields | `*_at` (DB) / `*At` (TS) | `enrolled_at` / `enrolledAt` |
| Identifier/foreign-key fields | `*_id` (DB) / `*Id` (TS) | `course_id` / `courseId` |

Never deviate from this table without updating it in the same change — naming consistency is itself part of what Section 1 calls "consistency as a security property": an inconsistently-named function is harder to `grep` for during a security audit (recall the `grep`-based checks throughout Appendix F and `docs/DEVSECOPS_ONBOARDING.md`).

---

## 4. Input Validation Conventions

### 4.1 Every network-crossing input is validated with Zod, at the boundary, before any business logic runs

```ts
export async function enrollInCourse(
  _previousState: EnrollActionResult | null,
  formData: FormData
): Promise<EnrollActionResult> {
  const user = await requireUser(); // Layer 1: auth, always first

  const rawCourseId = formData.get("courseId");
  const parsed = enrollInCourseSchema.safeParse({ courseId: rawCourseId }); // Layer 2: shape

  if (!parsed.success) {
    return { success: false, error: "Invalid course selection." };
  }
  // Business logic only begins here, on parsed.data
}
```

**Rule:** never destructure or use a raw, unvalidated input field before its schema check has returned successfully. Validation is always the second thing a Server Action does, immediately after authentication, before anything else.

### 4.2 Always bound size, not just shape

Every field capable of holding attacker- or user-controlled variable-length content has an explicit `.max(...)` (strings) or a `.refine(...)` size check (structured data). See `submitModuleAttemptSchema`'s `.refine()` on serialized submission length as the canonical pattern.

### 4.3 Use `safeParse`, not `parse`, at Server Action/Route Handler boundaries

`parse` throws; `safeParse` returns a discriminated result you branch on explicitly. Server Actions never let a validation failure become an uncaught exception — they return a structured failure result (Section 6).

---

## 5. Authorization Conventions

This is the single most important section in this guide. Every rule here is a direct consequence of `docs/ARCHITECTURE.md` §7.1's two-layer authorization model.

### 5.1 Every protected route enforces authentication at the layout boundary, once

```ts
// app/dashboard/layout.tsx — enforced ONCE, for every nested route
export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  await requireUser();
  return (/* ... */);
}
```

**Never** re-implement a bare "is anyone signed in" check inside an individual page inside an already-protected layout — that check belongs at the layout, exactly once.

### 5.2 Every resource-scoped operation independently re-verifies the specific relationship

Route-level authentication is **never** sufficient on its own. Any function reading or writing data scoped to a specific course, lesson, module, or certificate must perform its own, explicit, resource-level check — following this exact shape, used identically across enrollment (Part 7), lesson access (Part 9), assessment grading (Part 11), and instructor ownership (Part 15):

```ts
export async function getCourseOutline(userId: string, courseSlug: string): Promise<CourseOutline | null> {
  const course = await client.fetch<CourseDetail | null>(courseDetailQuery, { slug: courseSlug });
  if (!course) return null;

  const enrollments = await findActiveEnrollmentsForUser(userId);
  const isEnrolled = enrollments.some((e) => e.courseId === course._id && e.status !== "CANCELLED");
  if (!isEnrolled) return null; // Same response as "doesn't exist" — see 5.3

  // ...
}
```

**Rule:** never write a function that fetches a course, lesson, certificate, or any per-user resource by identifier alone. It must always accept the requesting user's identity as an explicit parameter and check the relationship before returning data.

### 5.3 "Not found" and "not authorized" are always the same response

```ts
// GOOD
if (!course) return null;
if (!isEnrolled) return null; // identical outcome, no distinguishing information leaked

// NEVER
if (!course) return null;
if (!isEnrolled) throw new ForbiddenError("You are not enrolled"); // leaks that the course exists
```

At the calling page, both `null` outcomes resolve to the identical `notFound()` call. Never introduce a code path that responds differently based on *which* of these two conditions failed.

### 5.4 Cross-system identifiers (Sanity IDs stored in Neon) are never trusted without a scoped query

Any field like `courseId`, `lessonId`, or `moduleId` stored in a Neon table has no database-enforced relationship to Sanity (`docs/ARCHITECTURE.md` §5.4, §7.3). Every read/write path touching one **must** use the course→chapter→lesson(→content) scoped query pattern — never a bare `*[_id == $id]` lookup when the caller's claimed course/lesson context also needs verifying.

```groq
# GOOD — proves the full chain
*[_type == "course" && slug.current == $courseSlug && isPublished == true][0]
.chapters[]->.lessons[]->[slug.current == $lessonSlug][0]{ ... }

# NEVER — accepts the lesson slug in isolation, with no proof it
# belongs to the claimed course
*[_type == "lesson" && slug.current == $lessonSlug][0]{ ... }
```

---

## 6. Server Action and Error Handling Conventions

### 6.1 Server Actions never throw on an expected failure path

Every expected failure — validation error, not-found, not-authorized, rate-limited — returns a structured result object. `throw` is reserved for genuinely unexpected conditions, and even then is typically caught and converted at the boundary.

```ts
// The canonical shape, consistent across every Server Action
export interface ModuleSubmissionResult {
  success: boolean;
  isCorrect: boolean | null;
  score: number | null;
  message: string;
  errorCode?: ModuleErrorCode;
}

function errorResult(errorCode: ModuleErrorCode, message: string): ModuleSubmissionResult {
  return { success: false, isCorrect: null, score: null, message, errorCode };
}
```

### 6.2 Closed error-code unions, not free-text matching

Any code that needs to distinguish *why* an action failed does so via a typed, closed `errorCode` union, never by inspecting the human-readable `message` string.

```ts
export type ModuleErrorCode =
  | "NOT_ENROLLED"
  | "MODULE_NOT_FOUND"
  | "ATTEMPT_LIMIT_EXCEEDED"
  | "INVALID_SUBMISSION"
  | "SUBMISSION_TOO_LARGE"
  | "UNKNOWN_ERROR";
```

### 6.3 Never return raw error detail to the client

```ts
// GOOD
try {
  await createEnrollmentWithProgress({ userId: user.id, courseId });
} catch (error) {
  console.error("Enrollment creation failed:", error); // logged server-side only
  return { success: false, error: "Something went wrong. Please try again." };
}

// NEVER
} catch (error) {
  return { success: false, error: error.message }; // leaks internal detail
}
```

`console.error` is always the destination for the raw exception; the client-facing message is always hand-authored and generic.

### 6.4 Route Handlers: correct HTTP status, always

- `400` for malformed/unverifiable requests (bad signature, missing headers).
- `404` for anything not found *or* not authorized (identical, per Section 5.3).
- `405` is automatic — never manually implement method-not-allowed handling; simply don't export a handler for methods you don't support.
- Never `500` for a condition that is actually the caller's fault — reserve `500`-class responses for genuine, unexpected server-side failure.

---

## 7. Database Access Conventions

### 7.1 Every query goes through Drizzle — never raw, unparameterized SQL strings

If a raw `sql` tagged template is genuinely needed (e.g., calling a Postgres sequence), every interpolated value must use the tagged template's own `${...}` parameterization, never manual string concatenation.

```ts
// GOOD — tagged template, safely parameterized
const result = await client.execute(sql`select nextval('certificate_number_seq') as val`);

// NEVER
const result = await client.execute(`SELECT * FROM users WHERE id = '${userId}'`);
```

### 7.2 Transactions: always use the callback's own client, never the outer one

```ts
// GOOD
return db.transaction(async (tx) => {
  const [enrollment] = await tx.insert(enrollments).values({ ... }).returning();
  const [progress] = await tx.insert(courseProgress).values({ ... }).returning();
  return { enrollment, progress };
});

// A SILENT, DANGEROUS BUG — this write escapes the transaction entirely,
// breaking the all-or-nothing guarantee with no error raised
return db.transaction(async (tx) => {
  const [enrollment] = await tx.insert(enrollments).values({ ... }).returning();
  const [progress] = await db.insert(courseProgress).values({ ... }).returning(); // ← db, not tx
  return { enrollment, progress };
});
```

Any multi-step write representing one logical action must be wrapped in `db.transaction(...)` — never left as sequential, independently-committing statements.

### 7.3 Uniqueness rules are enforced by database constraints — application-level checks are a UX nicety only

Any "at most one" business rule (enrollment, certificate, webhook processing, idempotent attempt) must have a corresponding `unique(...)` constraint in the Drizzle schema. An application-level existence check before an insert is acceptable **only** as a way to produce a friendlier error message — never as the sole guarantee. Pair it with a `try`/`catch` around the actual write that gracefully handles the constraint-violation case (see the enrollment and certificate-issuance race-recovery patterns).

### 7.4 Nullable fields represent "not applicable," never a disguised default

```ts
// GOOD — null is honestly "no correctness concept applies to this module type"
score: integer("score"), // no .notNull()
isCorrect: boolean("is_correct"),

// NEVER — using 0/false as a stand-in for "not applicable" conflates it
// with a genuine zero score / genuine false result
score: integer("score").notNull().default(0),
```

Default every column to `.notNull()` unless there is a genuine, articulable "no value yet" or "not applicable" state.

### 7.5 Cascade behavior is deliberate, not default — state it explicitly

Every foreign key explicitly declares its `onDelete` behavior. `"cascade"` is the default choice for data meaningless without its owning row; `"set null"` is reserved specifically for records (currently only `audit_logs`) that should outlive the row they reference.

---

## 8. Content Query (GROQ) Conventions

### 8.1 Public and authenticated queries are always separate definitions, never shared

Never reuse one GROQ query across a public/unauthenticated context and an authenticated one, even if the shapes look similar at first. A query's projection is itself a security boundary (`docs/ARCHITECTURE.md` §4.2) — write a distinct query for each trust context, even at the cost of some duplication.

### 8.2 Answer-key fields never appear in any query except the one designated server-only query

```ts
// The ONLY acceptable place these two field names may appear together
// with a live grading path:
export const assessmentDefinitionQuery = /* groq */ `
  ...
  correctOptionIndex,
  expectedKeywords
  ...
`;
```

Any other query touching `quizBlock` or `codeExerciseBlock` must use a conditional projection explicitly excluding these fields:

```groq
_type == "quizBlock" => { _type, _key, moduleId, question, options }
```

This is verified automatically by a permanent regression test (`tests/unit/grading-security.test.ts`) — do not treat this convention as optional discipline; it is enforced.

### 8.3 Always use `/* groq */` comment annotation on query template strings

```ts
export const courseCatalogQuery = /* groq */ `
  *[_type == "course" && isPublished == true] | order(title asc) { ... }
`;
```

This enables editor syntax highlighting for anyone with the appropriate extension and signals intent to every future reader.

---

## 9. React and Component Conventions

### 9.1 Default to Server Components; add `"use client"` only when genuinely required

Add `"use client"` only when a component needs one of: local interactive state (`useState`, `useOptimistic`), a client-only hook (`usePathname`), a browser-only API, or a React mechanism that is inherently client-side (error boundaries). Never add it preemptively or "to be safe."

```tsx
// "use client" MUST be the literal first line — nothing above it,
// not even a comment
"use client";

import { useState } from "react";
```

### 9.2 Composition over configuration

Prefer a family of small, composable components (`Card`, `CardHeader`, `CardTitle`, `CardContent`, `CardFooter`) over one large component accepting many conditional props. This is the established pattern for every `components/ui/` primitive.

### 9.3 Every design-system component extends its native HTML element's props

```tsx
export interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: "primary" | "secondary" | "outline" | "ghost" | "danger";
  size?: "sm" | "md" | "lg";
}
```

Never build a wrapper component that silently drops access to standard HTML attributes (`onClick`, `disabled`, `aria-*`) a caller would reasonably expect to pass through.

### 9.4 Class name merging always goes through `cn()`

```tsx
className={cn(
  "inline-flex items-center justify-center rounded-[var(--radius-control)]",
  variantClasses[variant],
  className // caller-supplied classes ALWAYS merged last
)}
```

Never concatenate class name strings manually or rely on prop-order coincidence to determine which class wins — `cn()`'s `tailwind-merge` resolution is the only accepted mechanism for resolving conflicting utility classes.

### 9.5 Type guards for narrowing registry/union lookups

```ts
function isKnownModuleType(type: string): type is ModuleBlockType {
  return type in moduleRegistry;
}
```

Use a proper `value is Type` type guard function rather than an `as` cast whenever narrowing a string or unknown value against a known set of possibilities.

---

## 10. Background Workflow (Inngest) Conventions

### 10.1 One `step.run` per independently-retryable unit of work

Never combine multiple genuinely independent operations (a database read, an external API call, a write) into a single `step.run` block if a failure partway through one but not the other would need different retry behavior. Split them, and name each step descriptively.

### 10.2 Events are emitted only after the triggering transaction commits — never inside it, never before it

```ts
// GOOD
await db.transaction(async (tx) => { /* writes */ });
await inngest.send({ name: "lesson/completed", data: { ... } }); // after commit

// NEVER — if the transaction rolls back, this describes something
// that never actually happened
await db.transaction(async (tx) => {
  await tx.insert(moduleAttempts).values({ ... });
  await inngest.send({ name: "lesson/completed", data: { ... } }); // inside tx — wrong
});
```

### 10.3 Idempotency: check-before-write, plus race-recovery try/catch, for anything with a uniqueness guarantee

```ts
const existing = await findCertificate(userId, courseId);
if (existing) return { issued: false, reason: "already_issued" };

try {
  return await createCertificate(db, { ... });
} catch (error) {
  const raced = await findCertificate(userId, courseId);
  if (raced) return raced; // a concurrent invocation won — use its result
  throw error;
}
```

### 10.4 Serialize step results to plain JSON-safe values

Never return a `Set`, `Map`, class instance, or `Date` object directly from a `step.run` callback — convert explicitly (`Array.from(set)`, `.toISOString()`) before returning, since step results must be durably, losslessly serializable.

### 10.5 Failures are recorded internally, then re-thrown

```ts
} catch (error) {
  await step.run("mark-workflow-failed", async () => {
    await markWorkflowEventStatus(workflowEvent.id, "FAILED");
  });
  throw error; // re-thrown so Inngest's own retry mechanism still engages
}
```

Never swallow an error inside a background function without a deliberate, stated reason — the default is always record-then-re-throw.

---

## 11. Comments and Documentation-in-Code

### 11.1 Comment the *why*, not the *what*

```ts
// GOOD — explains the non-obvious reasoning
// nextval() is atomic — this is the ONLY place in the entire
// application that generates a certificate number, and it can never
// produce a duplicate under concurrent load.
const result = await client.execute(sql`select nextval('certificate_number_seq') as val`);

// AVOID — restates what the code already says
// Execute a SQL query
const result = await client.execute(sql`...`);
```

### 11.2 Flag deliberate, non-obvious deviations explicitly

If a pattern deliberately differs from the norm established elsewhere in the codebase (e.g., `audit_logs.user_id` using `onDelete: "set null"` instead of the near-universal `"cascade"`), comment *why*, inline, at the point of deviation — never leave an inconsistency unexplained for a future reader to wonder about.

### 11.3 Security-relevant code gets a heavier comment burden than ordinary code

Any function touching grading, authorization, or webhook verification should have comments explaining the *threat* being defended against, not just the mechanism — following the density of commentary already present in `lib/modules/grading.ts` and `submit-module-attempt.ts`. A reviewer six months from now should be able to understand *why* a check exists from the comment alone, without needing to reconstruct the reasoning from first principles.

---

## 12. Testing Conventions

### 12.1 Pure logic is unit-tested in isolation, decoupled from request plumbing

Functions bearing security or correctness significance (`gradeSubmission` is the canonical example) are written as pure functions accepting plain data and returning plain data — no `requireUser()`, no database call, no request object — specifically so they can be unit-tested directly, per `docs/SRD.md` NFR-MAINT-2.

### 12.2 Every fixed security defect gets a permanent regression test, non-negotiably

```ts
// tests/unit/grading-security.test.ts — this exact pattern is the
// required response to ANY fixed security defect, not just this one
it("quizConfigSchema does not define a correctOptionIndex field", () => {
  expect(quizConfigSchema.shape).not.toHaveProperty("correctOptionIndex");
});
```

### 12.3 Test names describe behavior, not implementation

```ts
// GOOD
it("marks any other option index as incorrect with a zero score", () => { ... });

// AVOID — describes internal mechanics, not the behavior being verified
it("calls gradeSubmission with the right arguments", () => { ... });
```

---

## 13. Environment and Secrets Conventions

### 13.1 Every environment variable is read through exactly one designated access point per subsystem

```ts
// sanity/env.ts — the ONLY place NEXT_PUBLIC_SANITY_PROJECT_ID is read
export const projectId = assertValue(
  process.env.NEXT_PUBLIC_SANITY_PROJECT_ID,
  "Missing environment variable: NEXT_PUBLIC_SANITY_PROJECT_ID"
);
```

Never scatter `process.env.X` reads across arbitrary files — every subsystem (Sanity, Neon, email, rate limiting) has one file responsible for reading and validating its own configuration, failing fast and loudly if a required value is absent.

### 13.2 `NEXT_PUBLIC_` is applied deliberately, never by habit

Before adding this prefix to any new variable, explicitly justify that browser-side JavaScript genuinely needs the value. Default to *not* prefixing.

### 13.3 Every new variable is documented in `.env.example`, with no real value

Every environment variable, without exception, has a corresponding entry in `.env.example` — this is the living, version-controlled documentation of what configuration the system requires, and it must never itself contain a real secret.

---

## 14. Enforcement

This style guide is enforced through the same mechanisms already established in `docs/ONBOARDING.md`'s Code Review Standards and `docs/DEVSECOPS_ONBOARDING.md`'s pre-deploy gate:

- **Automated:** `npm run lint`, `npm run typecheck`, and the `grep`-based structural checks (Sections 8.2, 4, 13.1) run in CI on every commit.
- **Manual, at review time:** every reviewer checks new code against Sections 5 (Authorization) and 8.2 (answer-key exposure) as a mandatory, first-priority pass — before reviewing anything else about the change — consistent with `docs/ONBOARDING.md`'s stated review order.
- **Revision:** any new, repeated pattern that emerges across three or more files should be added to this guide in the same change set that introduces the third instance — this document is expected to grow alongside the codebase, not remain static after this baseline.
