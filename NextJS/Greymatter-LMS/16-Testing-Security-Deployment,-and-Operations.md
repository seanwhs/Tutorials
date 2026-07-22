# Part 16 — Testing, Security, Deployment, and Operations

## The goal

By the end of this part, GreyMatter LMS will have an automated test suite (unit tests with Vitest, end-to-end tests with Playwright), a completed security review covering every trust boundary this series has built, and a fully deployed production application — Next.js on Vercel, Neon's production branch, a deployed Sanity Studio, Clerk in production mode, and Inngest wired to real webhooks. We'll close with a scripted, twelve-step verification journey run against the real, live deployment, proving the entire system works end to end, exactly as designed since Part 0.

## Why it exists

Every part so far has been verified by hand — clicking buttons, checking Drizzle Studio, reading terminal logs. That's the right way to *build* confidence step by step, but it doesn't scale, and it doesn't protect you from silently breaking Part 8's enrollment logic while working on Part 15's analytics six weeks later. This part exists to convert manual verification into automated, repeatable proof — and to take the project from "runs on my machine" to "runs in production, for real users, safely."

---

## Part A — Automated Testing

## Step 1 — Vitest setup and configuration

### The Target

Installing Vitest, configuring it for our TypeScript/Next.js project, and writing our first unit test against pure business logic that has no database or network dependency.

### The Concept

A **unit test** verifies one small, isolated piece of logic — a function, given specific inputs, produces the expected output — without touching a real database, a real Sanity project, or a real network. This is precisely why Part 11's `gradeSubmission` function was deliberately written as a pure, synchronous function separate from the Server Action's authentication/database plumbing: pure functions are trivially, quickly testable, while functions tangled up with `requireUser()` and `db.transaction()` are not.

### The Implementation

```bash
npm install -D vitest @vitejs/plugin-react vite-tsconfig-paths
```

#### `vitest.config.ts`

```ts
import { defineConfig } from "vitest/config";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
  // tsconfigPaths() lets Vitest understand our "@/" import alias
  // (Part 1) exactly the way Next.js itself does — without this, every
  // test file importing "@/lib/..." would fail to resolve.
  plugins: [tsconfigPaths()],
  test: {
    environment: "node",
    include: ["tests/unit/**/*.test.ts"],
  },
});
```

#### `package.json` (add scripts)

```json
{
  "scripts": {
    "test:unit": "vitest run",
    "test:unit:watch": "vitest"
  }
}
```

#### `tests/unit/grading.test.ts`

```ts
import { describe, expect, it } from "vitest";
import { gradeSubmission, ModuleGradingError } from "@/lib/modules/grading";
import type { AssessmentDefinition } from "@/sanity/lib/queries";

describe("gradeSubmission — quizBlock", () => {
  const assessment: AssessmentDefinition = {
    _type: "quizBlock",
    moduleId: "test-quiz",
    correctOptionIndex: 2,
  };

  it("marks the correct option index as correct with a full score", () => {
    const result = gradeSubmission(assessment, { selectedOptionIndex: 2 });
    expect(result.isCorrect).toBe(true);
    expect(result.score).toBe(100);
  });

  it("marks any other option index as incorrect with a zero score", () => {
    const result = gradeSubmission(assessment, { selectedOptionIndex: 0 });
    expect(result.isCorrect).toBe(false);
    expect(result.score).toBe(0);
  });

  it("throws ModuleGradingError for a malformed submission shape", () => {
    expect(() => gradeSubmission(assessment, { wrongField: true })).toThrow(ModuleGradingError);
  });
});

describe("gradeSubmission — codeExerciseBlock", () => {
  const assessment: AssessmentDefinition = {
    _type: "codeExerciseBlock",
    moduleId: "test-exercise",
    expectedKeywords: ["select", "from"],
  };

  it("awards full credit when every keyword is present, case-insensitively", () => {
    const result = gradeSubmission(assessment, { responseText: "SELECT * FROM users" });
    expect(result.score).toBe(100);
    expect(result.isCorrect).toBe(true);
  });

  it("awards partial credit when only some keywords are present", () => {
    const result = gradeSubmission(assessment, { responseText: "select something" });
    expect(result.score).toBe(50);
    expect(result.isCorrect).toBe(false);
  });

  it("clamps score to a sane 0-100 range even with unusual input", () => {
    const result = gradeSubmission(assessment, { responseText: "select from select from" });
    expect(result.score).toBeGreaterThanOrEqual(0);
    expect(result.score).toBeLessThanOrEqual(100);
  });
});

describe("gradeSubmission — modules with no correct answer", () => {
  it("returns null isCorrect/score for reflectionBlock", () => {
    const assessment: AssessmentDefinition = { _type: "reflectionBlock", moduleId: "reflect-1" };
    const result = gradeSubmission(assessment, { responseText: "My thoughts..." });
    expect(result.isCorrect).toBeNull();
    expect(result.score).toBeNull();
  });

  it("returns null isCorrect/score for checkpointBlock", () => {
    const assessment: AssessmentDefinition = { _type: "checkpointBlock", moduleId: "checkpoint-1" };
    const result = gradeSubmission(assessment, { acknowledged: true });
    expect(result.isCorrect).toBeNull();
    expect(result.score).toBeNull();
  });
});
```

### The Verification

```bash
npm run test:unit
```

Expected output: all tests pass (green checkmarks), something like `Test Files 1 passed | Tests 8 passed`.

To confirm the tests are genuinely meaningful (not just trivially passing), deliberately break `gradeSubmission` — temporarily flip the `===` to `!==` in the quiz-grading branch — rerun `npm run test:unit`, and confirm tests now fail with a clear diff showing expected vs. actual values. **Revert the deliberate break** immediately after confirming this.

---

## Step 2 — Zod validation tests and authorization tests

### The Target

`tests/unit/validation.test.ts` and `tests/unit/authorization.test.ts` — testing our Zod schemas directly, and testing the *shape* of our authorization helpers using dependency injection rather than a real database.

### The Implementation

#### `tests/unit/validation.test.ts`

```ts
import { describe, expect, it } from "vitest";
import { enrollInCourseSchema } from "@/lib/validation/enrollment";
import { submitModuleAttemptSchema } from "@/lib/modules/submission-schema";

describe("enrollInCourseSchema", () => {
  it("accepts a well-formed course ID", () => {
    const result = enrollInCourseSchema.safeParse({ courseId: "abc123" });
    expect(result.success).toBe(true);
  });

  it("rejects an empty course ID", () => {
    const result = enrollInCourseSchema.safeParse({ courseId: "" });
    expect(result.success).toBe(false);
  });

  it("trims whitespace from the course ID", () => {
    const result = enrollInCourseSchema.safeParse({ courseId: "  abc123  " });
    expect(result.success).toBe(true);
    if (result.success) expect(result.data.courseId).toBe("abc123");
  });
});

describe("submitModuleAttemptSchema", () => {
  const base = { lessonId: "lesson-1", courseId: "course-1", moduleId: "module-1" };

  it("rejects a submission exceeding the size limit", () => {
    const hugeSubmission = { responseText: "x".repeat(10000) };
    const result = submitModuleAttemptSchema.safeParse({ ...base, submission: hugeSubmission });
    expect(result.success).toBe(false);
  });

  it("accepts a reasonably sized submission", () => {
    const result = submitModuleAttemptSchema.safeParse({
      ...base,
      submission: { responseText: "a normal answer" },
    });
    expect(result.success).toBe(true);
  });
});
```

#### `tests/unit/grading-security.test.ts`

```ts
import { describe, expect, it } from "vitest";
import { quizConfigSchema, codeExerciseConfigSchema } from "@/lib/modules/registry";

// A REGRESSION TEST specifically encoding Part 11's security fix — this
// test exists to make it IMPOSSIBLE to silently reintroduce the Part 10
// vulnerability in the future, since re-adding these fields to the
// schema would make this test fail loudly.
describe("module config schemas never accept answer-key fields", () => {
  it("quizConfigSchema does not define a correctOptionIndex field", () => {
    const shape = quizConfigSchema.shape;
    expect(shape).not.toHaveProperty("correctOptionIndex");
  });

  it("codeExerciseConfigSchema does not define an expectedKeywords field", () => {
    const shape = codeExerciseConfigSchema.shape;
    expect(shape).not.toHaveProperty("expectedKeywords");
  });
});
```

**Code walkthrough:**

- The final test file is worth pausing on: it's not testing *behavior* so much as testing an **architectural invariant** — "this schema must never grow this specific field again." This is a valuable, low-effort pattern for encoding hard-won security lessons directly into your test suite, so a future contributor (or future you, in six months) can't accidentally undo Part 11's fix without a test failing to explain why.

### The Verification

```bash
npm run test:unit
```

All tests should pass. Run `npm run test:unit:watch` once and leave it running in a spare terminal while you work through the rest of this part — it's a useful habit for the remainder of your work on any project.

---

## Step 3 — Playwright end-to-end setup

### The Target

Installing Playwright and configuring it to drive a real browser against our locally running application.

### The Concept

Recall Part 0's distinction: unit tests check one function in isolation; **end-to-end (E2E) tests** drive an actual browser through actual pages, clicking real buttons and reading real rendered text — verifying that every layer (React, Server Actions, Neon, Sanity, Clerk) genuinely works together, the way a human tester would, but scripted and repeatable.

### The Implementation

```bash
npm init playwright@latest -- --quiet --browser=chromium
```

This scaffolds `playwright.config.ts` and a `tests/e2e/` example — replace the example with our own configuration:

#### `playwright.config.ts`

```ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./tests/e2e",
  fullyParallel: false, // our tests share database state — run sequentially to avoid interference
  retries: 1,
  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry",
  },
  projects: [{ name: "chromium", use: { ...devices["Desktop Chrome"] } }],
  webServer: {
    command: "npm run dev",
    url: "http://localhost:3000",
    reuseExistingServer: true,
  },
});
```

#### `package.json` (add script)

```json
{
  "scripts": {
    "test:e2e": "playwright test"
  }
}
```

### The Verification

```bash
npx playwright install chromium
npm run test:e2e
```

Since no real test files exist under `tests/e2e/` yet (beyond Playwright's scaffolded example, which we'll replace next), this should run with zero or one trivial test passing. This confirms the harness itself works before we write anything meaningful.

---

## Step 4 — Accessibility testing

### The Target

`tests/e2e/accessibility.spec.ts` — an automated accessibility scan of key pages using `axe-core`, catching the kind of issues Part 2's design system was built specifically to avoid.

### The Implementation

```bash
npm install -D @axe-core/playwright
```

#### `tests/e2e/accessibility.spec.ts`

```ts
import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test.describe("Accessibility scans", () => {
  test("homepage has no detectable accessibility violations", async ({ page }) => {
    await page.goto("/");
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });

  test("course catalog has no detectable accessibility violations", async ({ page }) => {
    await page.goto("/courses");
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });
});
```

### The Verification

```bash
npm run test:e2e -- accessibility.spec.ts
```

Confirm both tests pass. If a violation is reported, Playwright's output includes the specific WCAG rule violated and the offending element — a genuinely useful, automated payoff of Part 2's early investment in `aria-*` attributes, focus rings, and semantic HTML.

---

## Step 5 — The final verification journey as a Playwright test

### The Target

`tests/e2e/full-journey.spec.ts` — a single, comprehensive test scripting the entire twelve-step journey from the blueprint: account creation through certificate issuance.

### The Concept

This is the ultimate expression of "logical progression" this whole series has followed — one test, mirroring the entire reader journey, that either passes completely or tells you exactly which stage of the pipeline broke.

### The Implementation

Since Clerk's real sign-up flow involves email verification codes that are impractical to script directly, we use Clerk's official testing utilities, which allow a test-mode bypass:

```bash
npm install -D @clerk/testing
```

#### `tests/e2e/full-journey.spec.ts`

```ts
import { test, expect } from "@playwright/test";
import { clerkSetup, setupClerkTestingToken } from "@clerk/testing/playwright";

test.beforeAll(async () => {
  await clerkSetup();
});

test("complete student journey: signup through certificate", async ({ page }) => {
  await setupClerkTestingToken({ page });

  // Step 1-2: Create a student account, which synchronizes into Neon
  // via Part 6's webhook / Part 6's ensureInternalUser fallback.
  const uniqueEmail = `test-${Date.now()}@example.com`;
  await page.goto("/sign-up");
  await page.getByLabel("Email address").fill(uniqueEmail);
  await page.getByLabel("Password", { exact: true }).fill("TestPassword123!");
  await page.getByRole("button", { name: "Continue" }).click();
  await page.waitForURL("/dashboard");

  // Step 3: Browse the course catalog.
  await page.goto("/courses");
  await expect(page.getByText("Introduction to Databases")).toBeVisible();

  // Step 4: Enroll in a course.
  await page.getByText("Introduction to Databases").click();
  await page.getByRole("button", { name: "Enroll — Free" }).click();
  await page.waitForURL(/\/dashboard\/courses\//);

  // Step 5: Open an authorized lesson.
  await page.getByText(/Start learning|Resume learning/).click();
  await expect(page.getByRole("heading", { name: "What is a Database?" })).toBeVisible();

  // Step 6-7: Submit an interactive assessment and confirm server-graded progress.
  await page.getByText("Writing Your First Query").click();
  await page.getByLabel("SELECT").check();
  await page.getByRole("button", { name: "Submit answer" }).click();
  await expect(page.getByText("Correct!")).toBeVisible();

  // Step 8: Complete every remaining required lesson content (reflection,
  // checkpoint) so the course reaches 100%.
  await page.getByLabel("Your reflection").fill("SQL syntax was more approachable than I expected.");
  await page.getByRole("button", { name: "Save response" }).click();
  await page.getByRole("button", { name: /Mark as complete/ }).click();

  // Step 9-10: Give the Inngest completion workflow time to process
  // (local dev server processes near-instantly, but we allow a margin).
  await page.waitForTimeout(3000);

  // Step 11: Confirm the certificate appears in the student dashboard.
  await page.goto("/dashboard/achievements");
  await expect(page.getByText(/Certificate No\./)).toBeVisible({ timeout: 10000 });
});
```

**Code walkthrough:**

- `setupClerkTestingToken({ page })` is Clerk's own official testing helper — it injects a special token that lets Playwright bypass real email verification while still exercising Clerk's genuine sign-up flow, rather than mocking Clerk out entirely (which would defeat the purpose of an end-to-end test).
- `page.waitForTimeout(3000)` is a pragmatic, explicitly-labeled compromise: Inngest's local processing is asynchronous relative to the browser's perspective, and a fixed wait is simpler to reason about for a tutorial than a full polling/retry mechanism — in a stricter production test suite, you'd replace this with a proper polling assertion (`expect.poll(...)`) checking the achievements page repeatedly until the certificate appears or a timeout is reached.
- This single test file directly encodes the blueprint's explicit twelve-step "Final verification journey" — worth recognizing that as intentional, not a coincidence.

### The Verification

```bash
npm run test:e2e -- full-journey.spec.ts
```

This test requires a real Clerk test-mode application and a seeded, published sample course exactly matching Part 3's content — if any earlier part's manual verification steps were skipped, this is often where you'll discover it. Confirm it passes end to end; if it fails partway, the failing assertion tells you precisely which part of the fifteen preceding parts to revisit.

Run the complete verification suite one final time before moving to deployment:

```bash
npm run lint
npm run typecheck
npm run build
npm run test:unit
```

---

## Part B — Security Review

## Step 6 — A structured security pass over every trust boundary

### The Target

No new application code — a deliberate, systematic review of every security-relevant decision made across the previous fifteen parts, organized by topic, with concrete fixes applied where gaps remain.

### 6.1 Authentication vs. authorization, restated

Authentication (Clerk, Part 6) answers "who are you." Authorization answers "are you allowed to do *this*." This series has enforced authorization at **two levels** consistently since Part 7: route-level (`requireUser`/`requireRole` in layouts) and resource-level (enrollment checks, ownership checks, course-scoped queries). Confirm, as a final audit, that every authenticated route in `app/dashboard/`, `app/instructor/`, and every Server Action touching user-specific data performs both.

### 6.2 Resource-level access checks — a final audit checklist

| Resource | Route-level check | Resource-level check |
|---|---|---|
| `/dashboard/*` | `requireUser()` in layout (Part 6) | N/A — every signed-in user may access their own dashboard |
| `/dashboard/courses/[slug]` | `requireUser()` (inherited) | `getCourseOutline`'s enrollment check (Part 7) |
| `/dashboard/courses/.../lessons/[slug]` | `requireUser()` (inherited) | Enrollment + course-scoped lesson query (Part 9) |
| `submitModuleAttempt` | `requireUser()` (Part 11) | Enrollment + course-scoped module lookup (Part 11) |
| `/instructor/*` | `requireRole("INSTRUCTOR")` (Part 15) | N/A at this level |
| `/instructor/courses/[id]/*` | `requireRole` (inherited) | `verifyCourseOwnership` (Part 15) |
| Certificate download | `requireUser()` (Part 13) | `certificate.userId !== user.id` check (Part 13) |

### 6.3 Webhook signature verification — confirm, don't assume

Revisit Part 6's Clerk webhook handler. Confirm the production `CLERK_WEBHOOK_SIGNING_SECRET` (added in Step 12 below) differs from your local development one — Clerk issues a distinct secret per registered endpoint, so your production endpoint (registered against your real deployed URL) will have its own secret, never reused from local testing.

### 6.4 Rate limiting

### The Target

Adding basic rate limiting to `submitModuleAttempt` and `enrollInCourse` — the two most sensitive, write-heavy Server Actions in the app.

### The Concept

Even with every other defense from Part 11 in place (enrollment checks, attempt limits, server-side grading), nothing so far stops a script from calling `submitModuleAttempt` thousands of times per second. A **rate limiter** caps how many requests a given identity can make in a time window, protecting both against abuse and against accidental runaway client bugs.

### The Implementation

```bash
npm install @upstash/ratelimit @upstash/redis
```

#### `.env.example` (append)

```bash
# ── Rate limiting (added in Part 16) ───────────────────────────────
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=
```

#### `lib/rate-limit.ts`

```ts
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

let limiter: Ratelimit | null = null;

function getLimiter(): Ratelimit | null {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) return null; // Dev fallback: no limiting configured locally.

  if (!limiter) {
    limiter = new Ratelimit({
      redis: new Redis({ url, token }),
      // 10 requests per 10 seconds, per identity — generous enough for
      // legitimate rapid quiz attempts, restrictive enough to blunt an
      // automated script.
      limiter: Ratelimit.slidingWindow(10, "10 s"),
    });
  }
  return limiter;
}

export async function checkRateLimit(identity: string): Promise<boolean> {
  const rl = getLimiter();
  if (!rl) return true; // No limiter configured (local dev) — always allow.
  const { success } = await rl.limit(identity);
  return success;
}
```

#### `lib/modules/submit-module-attempt.ts` (add as the very first check, before `requireUser()`)

```ts
// Add this import:
import { checkRateLimit } from "@/lib/rate-limit";

// At the very top of submitModuleAttempt, BEFORE requireUser():
// We can't rate-limit by user ID before authenticating, so we rate-limit
// by a coarser signal first — in a real deployment behind Vercel, the
// request's IP would be available via headers; for simplicity here we
// rate-limit post-authentication, by user ID, immediately after
// requireUser() resolves:
const user = await requireUser();
const withinLimit = await checkRateLimit(user.id);
if (!withinLimit) {
  return errorResult("UNKNOWN_ERROR", "Too many requests. Please slow down.");
}
```

### The Verification

Without real Upstash credentials configured, confirm `checkRateLimit` returns `true` unconditionally (check via a quick temporary `console.log` in `getLimiter()`) — the app remains fully functional locally. Document in your deployment checklist (Step 13) that production requires real Upstash credentials for this protection to be active.

### 6.5 Input-size limits — confirmed, not new

Recall Part 11, Step 5 already added a 5,000-character submission-size limit. Confirm no other user-controlled input in the app lacks a bound: Zod schemas for enrollment (Part 8) already restrict `courseId` to 200 characters; notification preference toggles are booleans with no size concern. No further action needed here — this is a confirmation, not a new implementation.

### 6.6 SQL injection prevention — confirmed, not new

Every database query in this series has gone through Drizzle's query builder (`eq()`, `and()`, etc.) or tagged `sql` template literals (which automatically parameterize interpolated values) — never raw string concatenation into a SQL string. Confirm this by searching the codebase:

```bash
grep -rn "db.execute(sql\`" --include="*.ts" .
```

Review every match and confirm all interpolated values use template literal `${...}` syntax (which Drizzle's `sql` tag parameterizes safely) rather than manual string building.

### 6.7 XSS and Portable Text rendering — confirmed, not new

Recall Part 4 explicitly avoided `dangerouslySetInnerHTML`, using `@portabletext/react`'s structured rendering instead. Recall Part 9's video embed allow-list (never rendering an untrusted URL directly into an `iframe src`). Recall Part 13's email HTML escaping. Confirm no new code introduced since violates this:

```bash
grep -rn "dangerouslySetInnerHTML" --include="*.tsx" .
```

Expected output: no matches. If any appear, they represent a genuine regression requiring immediate attention before deployment.

### 6.8 Safe error messages — confirmed, not new

Recall every Server Action in this series returns structured `{ success: false, error/errorCode, message }` objects with hand-written, safe messages — never a raw `error.message` from a caught exception. Confirm:

```bash
grep -rn "error: error.message" --include="*.ts" .
grep -rn "error\.stack" --include="*.tsx" .
```

Expected output: no matches in any user-facing return path (matches inside `console.error(...)` calls are fine and expected — those are server-side logs, never sent to the browser).

### 6.9 Environment secrets handling — a final audit

Confirm `.env.local` has never been committed:

```bash
git log --all --full-history -- .env.local
```

Expected output: empty (no history at all for this file). If it shows commits, the secrets it ever contained must be treated as compromised — rotate every one of them (Clerk keys, `DATABASE_URL`, Sanity token) before deploying, regardless of how old the commit is.

### 6.10 Audit logs — confirmed, not new

Recall Part 11 records an audit log entry on every module attempt (success and rejection), and Part 8's enrollment logic could be extended similarly. This is sufficient for this series' scope; a production system might add audit entries for role changes and admin actions as a natural extension.

### 6.11 Admin route protection

We built `requireRole("INSTRUCTOR")` in Part 15 but never built a dedicated `ADMIN`-only route, since the blueprint's admin capabilities (managing roles, reviewing all enrollments, retrying workflows) are genuinely substantial enough to warrant their own follow-up work beyond this series' scope. Document this clearly as a known, deliberate gap:

#### `docs/known-gaps.md`

```markdown
# Known Gaps (Deliberate, Documented)

- No dedicated `/admin` UI exists. `requireRole("ADMIN")` is implemented
  and ready to use (Part 6), but no admin-only pages currently call it.
  A production deployment should build these before opening the
  platform to real administrators, following the exact same
  route-level + resource-level authorization pattern used throughout
  this series (see Part 15's `requireCourseOwnership` as a template).
- Rate limiting (Step 6.4) requires Upstash Redis credentials in
  production to be active; without them, it silently no-ops.
```

---

## Part C — Production Deployment

## Step 7 — Preparing Neon for production

### The Target

A dedicated Neon production branch, separate from the development database used throughout this series.

### The Concept

Recall Part 5's mention that Neon branches work similarly to Git branches. We use this now: your `main` branch (used throughout development) stays as-is for continued local work; we create a distinct branch for production traffic, so schema experiments during future development never risk real user data.

### The Implementation

In the Neon console, open your project, and create a new branch named `production` from `main`'s current state. Copy its connection string (the pooled variant, exactly as in Part 5, Step 1).

### The Verification

Confirm the `production` branch appears in Neon's console with its own connection string, distinct from `main`'s.

---

## Step 8 — Deploying Sanity Studio and configuring CORS

### The Target

A deployed, standalone Sanity Studio, and CORS origins configured to allow your production domain to query Sanity's API.

### The Implementation

```bash
npx sanity deploy
```

Follow the prompts to choose a `*.sanity.studio` subdomain. Once deployed, visit **https://www.sanity.io/manage**, open your project's API settings, and add your production domain (e.g., `https://greymatter-lms.vercel.app`) under "CORS Origins," with credentials allowed.

### The Verification

Visit your deployed `*.sanity.studio` URL and confirm you can sign in and see your existing course content — proof this is the *same* dataset, not a fresh empty one.

---

## Step 9 — Configuring Clerk for production

### The Target

Switching Clerk from test/development keys to production keys, and updating the production webhook endpoint.

### The Implementation

In Clerk's dashboard, switch to "Production" mode (Clerk walks you through domain verification for your real production URL). Copy the new production `Publishable key` and `Secret key`. Under "Webhooks," register a new endpoint pointing at `https://your-production-domain.com/api/webhooks/clerk`, subscribed to the same three events as Part 6 (`user.created`, `user.updated`, `user.deleted`), and copy its distinct production signing secret.

### The Verification

Keep these values ready for Step 12's environment variable configuration — full verification happens once deployed.

---

## Step 10 — Configuring Inngest for production

### The Target

Registering your production app with Inngest and obtaining production event/signing keys.

### The Implementation

In Inngest's dashboard (from Part 12's account), create a production environment for your app, pointing its serve URL at `https://your-production-domain.com/api/inngest`. Copy the generated `Event Key` and `Signing Key`.

### The Verification

Keep these ready for Step 12.

---

## Step 11 — Deploying to Vercel

### The Target

The Next.js application deployed and running on Vercel.

### The Implementation

Push your repository to GitHub (or GitLab/Bitbucket) if you haven't already. Visit **https://vercel.com**, import the repository, and let Vercel auto-detect the Next.js framework. Do **not** deploy yet — proceed to Step 12 to configure environment variables first, since a deploy without them will fail at build or runtime.

---

## Step 12 — Production environment variables

### The Target

Every environment variable from this series' `.env.example`, populated with real production values, entered into Vercel's project settings.

### The Implementation

In Vercel's project settings → "Environment Variables," add each of the following (values from Steps 7–10 and your existing Sanity/Resend/Upstash accounts):

```text
NEXT_PUBLIC_APP_URL=https://your-production-domain.com
NEXT_PUBLIC_SANITY_PROJECT_ID=<your project id>
NEXT_PUBLIC_SANITY_DATASET=production
SANITY_API_TOKEN=<a token, if needed for any server-side write operations>
DATABASE_URL=<Neon PRODUCTION branch pooled connection string>
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=<production key>
CLERK_SECRET_KEY=<production key>
CLERK_WEBHOOK_SIGNING_SECRET=<production endpoint's secret>
NEXT_PUBLIC_CLERK_SIGN_IN_URL=/sign-in
NEXT_PUBLIC_CLERK_SIGN_UP_URL=/sign-up
NEXT_PUBLIC_CLERK_SIGN_IN_FORCE_REDIRECT_URL=/dashboard
NEXT_PUBLIC_CLERK_SIGN_UP_FORCE_REDIRECT_URL=/dashboard
INNGEST_EVENT_KEY=<production event key>
INNGEST_SIGNING_KEY=<production signing key>
RESEND_API_KEY=<your Resend key, if configured>
UPSTASH_REDIS_REST_URL=<your Upstash URL, if configured>
UPSTASH_REDIS_REST_TOKEN=<your Upstash token, if configured>
```

### The Verification

Confirm every variable is listed in Vercel's dashboard with the correct environment scope (Production). Trigger a deploy.

---

## Step 13 — Running production migrations

### The Target

Applying every Drizzle migration generated throughout this series against the production Neon branch.

### The Implementation

From your local machine, temporarily point `.env.local`'s `DATABASE_URL` at the **production** branch's connection string (or use a separate `.env.production.local` file with `dotenv-cli` pointed at it explicitly), then run:

```bash
npm run db:migrate
```

**Immediately revert** your local `DATABASE_URL` back to your development branch afterward — running development seed scripts or manual test data against production would be a real, avoidable mistake.

### The Verification

Connect to the production branch via Drizzle Studio or Neon's console and confirm all tables from Parts 5, 9, 11, 13, and 14 exist with the correct columns and constraints.

---

## Step 14 — The final production verification journey

### The Target

Manually repeating the twelve-step journey from Step 5's Playwright test, this time against your real, live, deployed URL — the ultimate proof this series set out to deliver.

### The Implementation and Verification

Visit your production URL. Walk through, by hand, in order:

1. Sign up with a real account.
2. Confirm (via your production Neon branch) an internal user row was created.
3. Browse the course catalog.
4. Enroll in a course.
5. Open an authorized lesson.
6. Submit an interactive assessment.
7. Confirm server-calculated progress updates.
8. Complete every required lesson.
9. Check Inngest's production dashboard for the completion workflow run.
10. Confirm a certificate was generated.
11. Download it from `/dashboard/achievements`.
12. Sign in as your promoted instructor account and confirm this student appears in the course's roster with correct progress.

If every step succeeds against the real, deployed system, GreyMatter LMS is complete.

---

## Common mistakes

- **Vercel build fails with a missing environment variable error** — Confirm every variable from Step 12 is present; Next.js build-time static analysis can fail on a missing `NEXT_PUBLIC_*` variable even before runtime.
- **Production webhook never fires** — Confirm the Clerk webhook endpoint URL uses your real production domain (not `localhost` or an old ngrok URL), and that its signing secret in Vercel matches the *production* endpoint's secret, not your local development one.
- **Inngest functions never run in production** — Confirm Inngest's dashboard shows your production app as "synced" — this typically requires one successful deployment before Inngest's `PUT` handshake (Part 12) completes.
- **Sanity Studio works locally but production pages show no content** — Almost always a CORS misconfiguration (Step 8); confirm your exact production domain (including `https://`) is listed.
- **Playwright's full-journey test times out at the certificate step** — Confirm Inngest's dev server was running throughout the test, and that the sample course used in the test genuinely matches the lesson titles/content the test script references.

---

## Git checkpoint

```bash
git add .
git status
```

```bash
git commit -m "Part 16: automated testing (Vitest + Playwright + accessibility), security review, rate limiting, production deployment across Vercel/Neon/Sanity/Clerk/Inngest, final verification journey"
```

---

## Final outcome

GreyMatter LMS is now a complete, tested, secured, and deployed full-stack learning management system — built from an empty folder across sixteen parts, following the exact progression Part 0 promised:

```text
Project foundation → Content modeling → Database modeling → Authentication
    → Enrollment → Lesson delivery → Interactive modules
    → Secure progress tracking → Inngest automation
    → Certificates and reminders → Instructor analytics
    → Testing and deployment
```
