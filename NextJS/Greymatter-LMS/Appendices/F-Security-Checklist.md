# Appendix F — Security Checklist

This expanded reference is a complete, actionable security audit checklist for GreyMatter LMS, organized by topic exactly as the blueprint specifies: identity, authorization, input validation, assessment integrity, webhooks, rate limits, error handling, secrets, and audit logging. Each item includes *why* it matters, *where* it's implemented, *how to verify* it yourself, and — critically — what the codebase looks like when that protection is **missing**, so you can recognize a regression immediately if you ever see it. Use this as a pre-deployment gate: every checkbox should be genuinely checkable, not assumed.

---

## F.1 How to use this checklist

Each section follows the same four-part structure:

1. **The risk** — what could go wrong, in plain terms.
2. **The control** — what GreyMatter does about it, with a file reference.
3. **Verify it yourself** — a concrete test you can run right now.
4. **What a regression looks like** — the exact code pattern that would silently reintroduce the vulnerability.

Treat this as a living document: any time you add a new feature to GreyMatter (or a project modeled on it), walk through every relevant section here before considering the feature "done."

---

## F.2 Identity

### F.2.1 Every user has exactly one, unambiguous internal identity

**The risk:** if a user could somehow end up with two internal `users` rows (one from a race condition, one from a retried webhook), their enrollments, progress, and certificates could split across two identities — appearing to "lose" data even though nothing was actually deleted.

**The control:** `users.auth_provider_id` carries a `UNIQUE` constraint (Part 5). Three independent layers protect against duplicate creation: the webhook handler's defensive `findUserByAuthProviderId` check before insert (Part 6), `ensureInternalUser`'s try/catch race recovery (Part 6, Step 8), and the database constraint itself as the final, unbeatable backstop.

**Verify it yourself:**
```bash
# Confirm the constraint exists
npm run db:studio
# → open users table → constraints panel → confirm UNIQUE(auth_provider_id)
```
Then repeat Part 6, Step 8's manual test: comment out the webhook's user-creation logic, sign up fresh, and confirm `ensureInternalUser`'s on-demand fallback still produces exactly one row.

**What a regression looks like:**
```ts
// REGRESSION: no existence check before insert, no try/catch —
// a race between the webhook and ensureInternalUser could now
// throw an unhandled unique-constraint error to the user.
export async function ensureInternalUser(clerkUserId: string) {
  const clerkUser = await client.users.getUser(clerkUserId);
  return createUser({ authProviderId: clerkUserId, email: clerkUser.emailAddresses[0].emailAddress });
  // ← missing: findUserByAuthProviderId check, missing: try/catch fallback
}
```

### F.2.2 Authentication and authorization are never conflated

**The risk:** treating "this person is signed in" as equivalent to "this person may do this specific thing" — the single most common real-world access-control bug.

**The control:** `requireUser()` answers only "is anyone genuinely signed in" (Part 6). Every sensitive operation *additionally* calls a distinct, resource-specific check — `getCourseOutline`'s enrollment verification (Part 7), `verifyCourseOwnership` (Part 15), `certificate.userId !== user.id` (Part 13).

**Verify it yourself:** Sign in as Student A. Attempt to visit a course dashboard page for a course Student A never enrolled in, by directly typing the URL. Confirm a 404, not the course content.

**What a regression looks like:**
```ts
// REGRESSION: authentication checked, but authorization skipped —
// ANY signed-in user can view ANY course's dashboard, enrolled or not.
export default async function DashboardCoursePage({ params }) {
  await requireUser(); // ← only checks "signed in," nothing more
  const course = await client.fetch(courseDetailQuery, { slug: courseSlug });
  // ← missing: enrollment verification before rendering
  return <CourseView course={course} />;
}
```

---

## F.3 Authorization

### F.3.1 Resource-level checks exist independently of route-level checks

**The risk:** protecting a route (`/dashboard/*`) does nothing to prevent an authenticated user from accessing *another user's specific resource* within that same route tree.

**The control:** every resource-scoped page/action in this series performs the two-layer pattern documented repeatedly since Part 7:

```text
Layer 1 (route-level): requireUser() / requireRole()
        │
Layer 2 (resource-level): does THIS specific user have a relationship
        with THIS specific resource? (enrollment, ownership, authorship)
```

**Verify it yourself — the complete audit table:**

| Resource | File | Layer 2 check present? |
|---|---|---|
| Course dashboard page | `lib/dashboard/get-course-outline.ts` | ✅ `enrollments.some(e => e.courseId === course._id && e.status !== "CANCELLED")` |
| Lesson player | `lib/dashboard/get-lesson-for-student.ts` | ✅ Reuses `getCourseOutline`, plus course-scoped lesson query |
| Module submission | `lib/modules/submit-module-attempt.ts` | ✅ `findEnrollment` + course-scoped `assessmentDefinitionQuery` |
| Certificate download | `app/api/certificates/[id]/download/route.ts` | ✅ `certificate.userId !== user.id` |
| Instructor course pages | `lib/instructor/require-course-ownership.ts` | ✅ `verifyCourseOwnership` |

Run through every row of this table against your own codebase whenever you add a new resource-scoped route — if a row would say "❌," that's an open vulnerability, not a stylistic gap.

**What a regression looks like:** any resource-fetching function that returns data based *only* on the resource's own ID, without cross-referencing the requesting user:
```ts
// REGRESSION: fetches by ID alone — no ownership check at all
export async function getCourseOutline(courseSlug: string) {
  return client.fetch(courseDetailQuery, { slug: courseSlug });
  // ← missing: userId parameter, missing: enrollment check entirely
}
```

### F.3.2 Failure responses never leak which specific check failed

**The risk:** returning a distinct "Access Denied" message (vs. a generic 404) for "this resource exists but you're not authorized" leaks the *existence* of the resource to an unauthorized party — useful information for probing valid IDs.

**The control:** every resource-level check in this series collapses "doesn't exist" and "exists but unauthorized" into the **identical** response — `notFound()`, consistently, since Part 7.

**Verify it yourself:**
```bash
# As an unauthenticated/unauthorized visitor, compare these two:
curl -I https://your-app.com/dashboard/courses/genuinely-nonexistent-slug
curl -I https://your-app.com/dashboard/courses/real-course-you-are-not-enrolled-in
# Both should return the SAME status code and rendered page.
```

**What a regression looks like:**
```ts
// REGRESSION: leaks existence via a distinct response
if (!course) return notFound();
if (!isEnrolled) return <AccessDeniedPage />; // ← different response reveals the course DOES exist
```

---

## F.4 Input Validation

### F.4.1 Every Server Action validates shape before use

**The risk:** a Server Action is reachable via a raw network request, not just through the UI that happens to call it — anything not explicitly validated can arrive malformed, oversized, or entirely absent.

**The control:** every Server Action in this series runs its input through a Zod schema before touching business logic — `enrollInCourseSchema` (Part 8), `submitModuleAttemptSchema` (Part 11), `updatePreferencesSchema` (Part 14).

**Verify it yourself:**
```bash
grep -rL "safeParse\|\.parse(" app/**/actions.ts lib/modules/submit-module-attempt.ts
# Expected: EMPTY output — every actions.ts file should contain a
# Zod parse call. Any file listed here has NO validation at all.
```

### F.4.2 Every user-controlled input has an explicit size bound

**The risk:** unbounded input (a multi-megabyte "quiz answer") wastes storage, slows queries, and at scale becomes a resource-exhaustion vector.

**The control:** `submitModuleAttemptSchema`'s `.refine()` check enforces a 5,000-character JSON limit on `submission` (Part 11, Step 5); `enrollInCourseSchema` bounds `courseId` to 200 characters (Part 8).

**Verify it yourself:**
```ts
// tests/unit/validation.test.ts already contains this exact test —
// confirm it passes:
it("rejects a submission exceeding the size limit", () => {
  const result = submitModuleAttemptSchema.safeParse({
    ...base, submission: { responseText: "x".repeat(10000) },
  });
  expect(result.success).toBe(false);
});
```

**What a regression looks like:**
```ts
// REGRESSION: no .refine() size check at all
export const submitModuleAttemptSchema = z.object({
  lessonId: z.string().min(1),
  courseId: z.string().min(1),
  moduleId: z.string().min(1),
  submission: z.unknown(), // ← genuinely unbounded — accepts any size
});
```

### F.4.3 Zod-derived types keep validation and TypeScript types in sync

**The risk:** hand-maintaining a TypeScript interface *and* a separate Zod schema for the same shape inevitably drifts — a field added to one and forgotten in the other silently defeats validation.

**The control:** every schema in this series uses `z.infer<typeof schema>` to derive its TypeScript type directly from the runtime schema (Part 8 onward) — there is no independent, hand-written interface to drift out of sync.

**Verify it yourself:** search for any interface that duplicates a Zod schema's shape by hand rather than using `z.infer`:
```bash
grep -rn "z.infer<typeof" lib/validation lib/modules
```
Every validated input type in the project should appear in this output.

---

## F.5 Assessment Integrity

*(This section exists specifically because of Part 10/11's central lesson — it deserves its own dedicated, exhaustive treatment beyond the general input-validation section above.)*

### F.5.1 No answer key ever reaches the browser

**The risk:** exactly Part 10's demonstrated vulnerability — if `correctOptionIndex` or `expectedKeywords` is present in *any* data sent to the browser, it can be read and used to falsify a passing score, regardless of how carefully the UI hides or ignores it.

**The control:** every browser-facing GROQ query since Part 11 uses conditional projections to explicitly exclude these two fields; exactly one query (`assessmentDefinitionQuery`) is permitted to fetch them, and it is called only from server-side code.

**Verify it yourself — the definitive test:**
```bash
grep -rn "correctOptionIndex\|expectedKeywords" sanity/lib/queries.ts
```
Expected output: these two field names should appear **only** inside `assessmentDefinitionQuery`'s projection. If they appear in `lessonWithinCourseQuery`, `previewLessonQuery`, or any other query, this is a critical regression — stop and fix immediately.

Additionally, this exact check is automated as a permanent regression test (Part 16, Step 2):
```ts
// tests/unit/grading-security.test.ts
it("quizConfigSchema does not define a correctOptionIndex field", () => {
  expect(quizConfigSchema.shape).not.toHaveProperty("correctOptionIndex");
});
```

**What a regression looks like:**
```groq
// REGRESSION: the "..." spread includes EVERY field of quizBlock,
// including correctOptionIndex — no conditional projection at all.
content[]{ ... }
```

### F.5.2 Grading happens exclusively on the server, against freshly-fetched data

**The risk:** even without exposing the answer key, if the *server* somehow trusted a client-computed correctness claim (Part 10's exact flaw), the browser could simply lie about the outcome directly.

**The control:** `gradeSubmission` (Part 11) is the **only** function in the codebase that determines `isCorrect`/`score`. It accepts only a freshly-fetched `AssessmentDefinition` and the raw submission — it has no code path that accepts a pre-computed correctness value from anywhere.

**Verify it yourself:**
```bash
grep -rn "clientComputedIsCorrect\|clientComputedScore" lib/
```
Expected output: **no matches anywhere**. These fields existed only in Part 10's deliberately-insecure version and were fully removed in Part 11 — their presence anywhere in the codebase would indicate the vulnerability has been reintroduced.

### F.5.3 The module belongs to the lesson which belongs to the course — proven at the query level

**The risk:** a `moduleId` could theoretically be reused or guessed across different lessons/courses; without proof of the full chain, a submission for one course's module could be graded against a different course's answer key.

**The control:** `assessmentDefinitionQuery`'s scoping chain (`course → chapters → lessons → content[moduleId == $moduleId]`) structurally requires the module to be reachable from the claimed course and lesson — mirroring Part 4, Step 9's original lesson-scoping rule, extended one level deeper.

**Verify it yourself:** in Sanity Vision, run `assessmentDefinitionQuery` with a real `$moduleId` but a `$courseId`/`$lessonId` pair that doesn't actually contain it. Confirm the result is `null`.

### F.5.4 Attempt limits and idempotency are enforced server-side

**The risk:** without a server-enforced cap, a script could submit unlimited attempts to eventually get a lucky correct guess; without idempotency, a network retry could double-count a single logical submission.

**The control:** `MAX_ATTEMPTS_PER_MODULE` (Part 11) checked via `countAttemptsForModule` before grading; `idempotencyKey` with a partial unique constraint (Part 11, Step 6).

**Verify it yourself:** submit the same quiz module more than `MAX_ATTEMPTS_PER_MODULE` times and confirm `ATTEMPT_LIMIT_EXCEEDED` is returned on the final attempt.

---

## F.6 Webhooks

### F.6.1 Every webhook verifies its cryptographic signature before processing

**The risk:** without signature verification, anyone who discovers a webhook's URL can send fabricated payloads — fake "user.created" events, fake completion notifications — and the server would process them as genuine.

**The control:** `app/api/webhooks/clerk/route.ts` verifies the Svix signature via `webhook.verify(rawBody, {...})` (Part 6) before any database write occurs, using the **raw, unparsed** request body.

**Verify it yourself:**
```bash
# Send a request WITHOUT valid Svix headers and confirm rejection:
curl -X POST https://your-app.com/api/webhooks/clerk \
  -H "Content-Type: application/json" \
  -d '{"type":"user.created","data":{"id":"fake_user"}}'
# Expected: 400 "Missing required Svix headers" or "Invalid signature" —
# NEVER a 200 with the fake user actually created.
```

**What a regression looks like:**
```ts
// REGRESSION: processes the payload with NO signature check at all
export async function POST(request: Request) {
  const event = await request.json(); // ← no verify() call anywhere
  await createUser({ authProviderId: event.data.id, email: event.data.email });
}
```

### F.6.2 Every webhook is idempotent against redelivery

**The risk:** providers explicitly warn the same webhook event may be delivered more than once — without protection, this could create duplicate users, duplicate certificates, or double-processed side effects.

**The control:** `webhook_events` table with `UNIQUE(source, external_id)` (Part 5), checked via `tryRecordWebhookEvent` **before** any real work begins (Part 6).

**Verify it yourself:** in Clerk's dashboard, resend a previously-delivered webhook event and confirm the server logs "Skipping duplicate Clerk webhook delivery" rather than reprocessing it.

### F.6.3 Webhook secrets are distinct per environment

**The risk:** reusing a development webhook secret in production (or vice versa) means a compromised local `.env.local` could be used to forge production webhooks.

**The control:** Part 16, Step 9 explicitly generates a **new** production endpoint with its own distinct signing secret, never reused from local development.

**Verify it yourself:** confirm `CLERK_WEBHOOK_SIGNING_SECRET` differs between your local `.env.local` and your production environment variables in Vercel.

---

## F.7 Rate Limits

### F.7.1 Sensitive, write-heavy actions are rate-limited

**The risk:** even with every other defense in place, nothing stops a script from calling `submitModuleAttempt` or `enrollInCourse` thousands of times per second — a form of resource abuse independent of any single defense already covered.

**The control:** `checkRateLimit` (Part 16, Step 6.4), applied to `submitModuleAttempt` immediately after authentication, using a sliding-window limiter (10 requests / 10 seconds per user).

**Verify it yourself (with real Upstash credentials configured):** script 15 rapid submissions from the same authenticated session and confirm the later ones return the rate-limit error message rather than processing normally.

### F.7.2 Rate limiting fails safe in local development, and this is documented

**The risk:** requiring paid third-party credentials just to run the app locally would be a real barrier — but silently having *no* rate limiting in production, because nobody remembered to configure it, would be a real vulnerability.

**The control:** `getLimiter()` returns `null` (allow-everything) when Upstash credentials are absent, **and** this exact gap is explicitly documented in `docs/known-gaps.md` (Part 16) so it's never an accidental, forgotten omission in production.

**Verify it yourself:** confirm `docs/known-gaps.md` explicitly calls out this requirement, and confirm your production Vercel environment variables genuinely include `UPSTASH_REDIS_REST_URL`/`_TOKEN` before considering deployment complete.

---

## F.8 Error Handling

### F.8.1 Server Actions never leak raw error details to the browser

**The risk:** a raw `error.message` or stack trace can reveal implementation details (database schema hints, internal file paths, library versions) genuinely useful to an attacker probing for weaknesses.

**The control:** every Server Action in this series returns hand-written, safe messages via structured result objects (`{ success: false, error/errorCode, message }`) — raw errors are only ever passed to `console.error(...)`, a server-side log never sent to the client.

**Verify it yourself:**
```bash
grep -rn "error: error.message\|error: error\.toString()" app/**/*.ts lib/**/*.ts
# Expected: no matches in any user-facing return statement.
```

### F.8.2 404 and error boundaries are distinguished correctly

**The risk:** conflating "this resource genuinely doesn't exist" (a normal, permanent, cacheable outcome) with "something unexpected broke" (transient, retryable) confuses both users and search engines, and can mask real bugs behind a generic "not found" message.

**The control:** `notFound()` + `not-found.tsx` for genuine absence (Part 4); a separate `error.tsx` Client Component boundary for unexpected thrown errors (Part 4), which logs to `console.error` but shows only a generic "Something went wrong" message with a "Try again" (`reset()`) option.

**Verify it yourself:** repeat Part 4, Step 7's deliberate-bug test — temporarily throw an error inside a page component, confirm the red error alert (not a raw Next.js stack trace) renders, then revert the test change.

### F.8.3 Structured, closed error codes replace free-text message matching

**The risk:** relying on parsing a human-readable error string to determine *what kind* of failure occurred is fragile — a future message wording change would silently break that logic.

**The control:** `ModuleErrorCode` (Part 11) — a closed union type (`"NOT_ENROLLED" | "MODULE_NOT_FOUND" | ...`) — is returned alongside every error message, giving both the UI and any future analytics (Part 15) a stable, non-string-matching way to distinguish failure categories.

---

## F.9 Secrets Handling

### F.9.1 `.env.local` has never been committed to version control

**The risk:** once a secret is committed to Git, it exists in history forever — even deleting the file in a later commit does not remove it from earlier commits, which remain fully accessible to anyone with repository access (or anyone who ever forks/clones it).

**The control:** `.gitignore` includes `.env*.local` from Part 1 onward.

**Verify it yourself — the definitive check, worth running before every deployment:**
```bash
git log --all --full-history -- .env.local
# Expected: completely EMPTY output.
```
If this ever shows commits, treat every secret that file ever contained as compromised — rotate all of them (Clerk keys, `DATABASE_URL`, Sanity token, Resend key, Upstash token) immediately, regardless of how old the commit is or whether the repository is private.

### F.9.2 Every secret has a documented, single source of truth

**The risk:** a secret duplicated across multiple files or hardcoded in more than one place makes rotation error-prone — you might update one copy and miss another.

**The control:** every environment variable is read through a single, centralized access point per subsystem — `sanity/env.ts` (with `assertValue` fail-fast checks), `db/client.ts`'s `getDatabaseUrl()`, `lib/email/client.ts`'s `getResendClient()`, `lib/rate-limit.ts`'s `getLimiter()` — never accessed via scattered, ad hoc `process.env.X` calls throughout the codebase.

**Verify it yourself:**
```bash
grep -rn "process\.env\." --include="*.ts" --include="*.tsx" . | grep -v "node_modules"
```
Review the output — every match should be inside one of the small number of designated environment-access files, not scattered arbitrarily through page components or Server Actions.

### F.9.3 The `NEXT_PUBLIC_` prefix is used deliberately, never by habit

**The risk:** Next.js exposes any variable prefixed `NEXT_PUBLIC_` directly to browser JavaScript — accidentally prefixing a genuinely secret value (an API key, a signing secret) would leak it into every visitor's browser.

**The control:** every `NEXT_PUBLIC_` variable in `.env.example` was deliberately chosen because the browser genuinely needs it (Clerk's publishable key, Sanity's project ID, the app's own public URL) — every secret-bearing variable (`CLERK_SECRET_KEY`, `DATABASE_URL`, `SANITY_API_TOKEN`, `RESEND_API_KEY`, `CLERK_WEBHOOK_SIGNING_SECRET`, `UPSTASH_REDIS_REST_TOKEN`) deliberately omits it.

**Verify it yourself:** review `.env.example` in full, and for every `NEXT_PUBLIC_` entry, ask "does client-side JavaScript in the browser genuinely need this value?" If the answer is no, it should not have that prefix.

### F.9.4 Production secrets are distinct from development secrets

**The risk:** covered in F.6.3 for webhooks specifically — the same principle applies platform-wide: Clerk keys, Neon connection strings, and Inngest keys should all differ between environments.

**The control:** Part 16's deployment steps explicitly provision a separate Neon `production` branch (Step 7), production Clerk keys (Step 9), and production Inngest keys (Step 10) — never reusing development credentials.

---

## F.10 Audit Logging

### F.10.1 Security-relevant actions are recorded, not just successful business outcomes

**The risk:** without a record of *rejected* attempts (not just successful ones), there's no way to detect a pattern of probing — repeated `NOT_ENROLLED` rejections against many different course IDs from one user, for instance, would be invisible without a log.

**The control:** `submit-module-attempt.ts` records an audit log entry for **both** successful attempts and specific rejection reasons (`"module_attempt.rejected"` with `reason: "not_enrolled"` or `"module_not_found"`) — not only the happy path.

**Verify it yourself:**
```bash
grep -n "recordAuditLog" lib/modules/submit-module-attempt.ts
# Confirm it's called on BOTH the success path AND at least one
# rejection path — not exclusively on success.
```

### F.10.2 Audit records outlive the accounts they describe

**The risk:** if a user's audit trail were deleted alongside their account (via a naive `onDelete: cascade`), any investigation into past behavior — including behavior relevant to *other* users or to a security incident — would lose its evidence the moment the account is removed.

**The control:** `audit_logs.user_id` uses `onDelete: "set null"` (Part 5) — the only table in the entire schema with this behavior, deliberately distinct from every other table's `cascade` — preserving the log entry with an anonymized (null) user reference rather than deleting it.

**Verify it yourself:**
```bash
npm run db:studio
# → audit_logs table → confirm user_id column allows NULL,
# and confirm (via schema file) onDelete: "set null", not "cascade"
```

### F.10.3 Audit entries are structured, queryable, and include context

**The risk:** a log entry containing only "something happened" with no structured detail is nearly useless for investigation.

**The control:** every `recordAuditLog` call includes a structured `metadata` (jsonb) field with the specific relevant context (`{ moduleId, lessonId, isCorrect, score }` or `{ reason, courseId, moduleId }`) — never a bare, contextless string.

---

## F.11 The complete pre-deployment security gate

Before considering any deployment "production ready," walk through this final consolidated checklist — every item below has a corresponding detailed section above:

- [ ] `git log --all --full-history -- .env.local` returns empty
- [ ] Production Clerk keys, webhook secret, Neon connection string, and Inngest keys are all distinct from development values
- [ ] `grep` for `correctOptionIndex`/`expectedKeywords` shows them **only** inside `assessmentDefinitionQuery`
- [ ] `grep` for `clientComputedIsCorrect`/`clientComputedScore` returns zero matches anywhere
- [ ] Every Server Action's file contains a Zod `safeParse`/`parse` call
- [ ] Every resource-scoped page/action appears with a "✅" in the F.3.1 audit table
- [ ] Unauthorized and nonexistent resources return identical responses (F.3.2)
- [ ] Clerk webhook signature verification confirmed via a deliberately malformed test request
- [ ] `UPSTASH_REDIS_REST_URL`/`_TOKEN` configured in production (not silently relying on the dev no-op fallback)
- [ ] `grep` for `dangerouslySetInnerHTML` returns zero matches
- [ ] `grep` for raw error message leakage (`error: error.message`) returns zero matches in user-facing paths
- [ ] `docs/known-gaps.md` reviewed and every listed gap is either accepted or resolved before opening to real users
- [ ] `npm run test:unit` passes, including `grading-security.test.ts`'s regression guards
- [ ] Full Playwright `full-journey.spec.ts` passes against the real, deployed URL (Part 16, Step 14)
