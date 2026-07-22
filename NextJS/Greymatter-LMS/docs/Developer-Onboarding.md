# GreyMatter LMS — Developer Onboarding Guide

**Document type:** Developer Onboarding Guide
**Product:** GreyMatter LMS
**Version:** 1.0
**Status:** Baseline — approved
**Location:** `docs/ONBOARDING.md`
**Companion documents:** `docs/ARCHITECTURE.md`, `docs/API_REFERENCE.md`, `docs/DATA_DICTIONARY.md`, `docs/TEST_PLAN.md`, Appendices A–I

---

## Welcome

This guide takes a new engineer from zero access to shipping their first reviewed change. It's organized as a sequence of days, not because you must follow this exact timeline, but because the *order* matters — each day builds a mental model the next day depends on, mirroring how the system itself was originally built (Parts 0–16 of the implementation record). If you're an experienced engineer joining a mature version of this codebase, you can move through the early days faster, but don't skip them entirely — the ordering encodes real dependencies, not just pacing.

**Before you begin:** confirm you have accounts/invitations for GitHub (or your VCS), Vercel, Neon, Sanity, Clerk, and Inngest. If any are missing, request access before Day 1 — most of Day 1 is blocked without them.

---

## Day 0: Access and Accounts Checklist

Work through this list with your onboarding buddy before attempting to run anything locally.

- [ ] Repository access (read/write) to the GreyMatter LMS Git repository
- [ ] Vercel project access (at minimum: Preview deployments; Production if your role requires it)
- [ ] Neon project access, invited to both the `main` (development) and `production` branches
- [ ] Sanity project access, invited as an Editor or Administrator (ask your onboarding buddy which role you need)
- [ ] Clerk **development** application dashboard access (never production keys on Day 0)
- [ ] Inngest account, added to the project's team
- [ ] A copy of the team's shared `.env.local` values, delivered through your organization's secrets manager — **never** via email, chat, or a shared document. If you receive it any other way, flag it to your team lead immediately; see `docs/ARCHITECTURE.md` §7 for why this matters.
- [ ] Local tooling: Node.js 20 LTS or newer, Git, a code editor with TypeScript support

**Do not proceed to Day 1 until every item above is checked.** Nearly every early blocker new engineers hit traces back to a missing credential from this list, not a code problem.

---

## Day 1: Environment Setup and Your First Successful Build

### Goal for today

Get the application running locally, end to end, without writing any code — and understand *why* each setup step exists, not just that it works.

### 1. Clone and install

```bash
git clone <repository-url>
cd greymatter-lms
npm install
```

### 2. Environment variables

```bash
cp .env.example .env.local
```

Open `.env.local` and fill in every value from your team's shared secrets, matching the structure documented in Appendix A §A.5 (environment variable → file map). Do not guess or invent placeholder values for anything beyond `NEXT_PUBLIC_APP_URL` — every other variable connects to a real external service and a genuinely wrong value produces confusing downstream errors rather than a clean failure.

**Read this before moving on:** `docs/ARCHITECTURE.md` §7.5 and Appendix F §F.9. Understand *why* `.env.local` is gitignored and *why* it must never be committed — this is not a formality, it's a permanent, irreversible mistake if it happens (Appendix F §F.9.1).

### 3. Database setup

```bash
npm run db:migrate
npm run db:seed
```

Confirm this worked:

```bash
npm run db:studio
```

Open the URL it prints. Confirm all ten tables from `docs/DATA_DICTIONARY.md` Section 2 exist, and confirm the seeded development user and sample enrollment appear correctly.

**Read this before moving on:** `docs/ARCHITECTURE.md` §5, and Appendix B in full. You do not need to memorize every column today, but you should be able to explain, in your own words, why `enrollments.course_id` is a plain text field with no foreign key, while `enrollments.user_id` is a real foreign key with `ON DELETE CASCADE`. If you can't yet, stop and re-read Appendix B §B.6 before continuing — this distinction underlies nearly every security-relevant decision you'll encounter for the rest of onboarding.

### 4. Run the app

```bash
npm run dev
```

In a second terminal:

```bash
npx inngest-cli@latest dev
```

Visit `http://localhost:3000`. Confirm the homepage loads. Visit `http://localhost:3000/api/health` and confirm a JSON response. Visit `http://localhost:8288` (Inngest's local dashboard) and confirm your app appears as connected, with every function from `docs/API_REFERENCE.md` §6.2 listed.

### 5. Run the full verification suite

```bash
npm run lint
npm run typecheck
npm run build
npm run test:unit
```

All four must pass cleanly before you consider Day 1 complete. If `npm run build` fails, consult Appendix G §G.2 before asking for help — most build failures on a fresh machine are covered there directly.

### End-of-day checkpoint

You should be able to answer:
- What are the four core external services this app depends on, and what does each one own?
- Why does the project use two separate terminal processes (`npm run dev` and the Inngest CLI) instead of one?
- Where does `.env.local` come from, and what would you do if you accidentally saw it appear in `git status`?

---

## Day 2: The Mental Model — Reading, Not Writing

### Goal for today

Build the architectural mental model *before* touching any code seriously. Resist the urge to jump into a ticket today — an engineer who understands the two-system data model and the trust-boundary discipline will move faster for the rest of their tenure than one who skips straight to shipping.

### Required reading, in this exact order

1. **`docs/PRD.md`** — understand *what* this system is for and who it serves, before anything else.
2. **`docs/ARCHITECTURE.md`**, Sections 1–5 — the hybrid architecture, the "why," and the data model at a conceptual level.
3. **Appendix H (Glossary)**, Sections H.1–H.2 — if any architecture or database term felt unfamiliar in step 2, look it up here immediately rather than guessing from context.

### Exercise: trace one request by hand

Without writing any code, open these three files in order and trace, line by line, what happens when a signed-in student visits their course dashboard page:

1. `middleware.ts` — what does this file actually do, and *not* do?
2. `app/dashboard/layout.tsx` — where is authentication actually enforced?
3. `lib/dashboard/get-course-outline.ts` — where is authorization (not just authentication) enforced, and why does a "not found" response cover two genuinely different real-world situations?

Write your answer to that last question down somewhere — you'll need this exact reasoning pattern again on Day 4.

### End-of-day checkpoint

You should be able to explain, without looking anything up:
- The difference between authentication and authorization, using this codebase's own terms
- Why a course dashboard page performs *two* separate checks (route-level and resource-level) rather than one
- Why `getCourseOutline` returns `null` identically for "course doesn't exist" and "you're not enrolled," rather than two different responses

---

## Day 3: The Security Model — The Part You Cannot Skip

### Goal for today

Understand, in depth, the single most important architectural decision in the entire system: **the browser never grades its own homework.** This is not optional context — it is the load-bearing security principle behind nearly every Server Action you will ever write or review in this codebase.

### Required reading

1. **`docs/ARCHITECTURE.md` §7.2** — the assessment integrity model, in full.
2. **Appendix F, Sections F.5.1–F.5.4** — the concrete, checkable version of the same principle.
3. **`docs/API_REFERENCE.md` §4.3** (`submitModuleAttempt`) — the actual function implementing all of this.

### Exercise: reproduce the vulnerability, then confirm the fix, yourself

This exercise is mandatory for every new engineer, regardless of what part of the system they'll ultimately work on. It is far more effective to *see* the vulnerability with your own hands than to read about it abstractly.

1. Open a lesson containing a quiz module in your local running app.
2. Open browser DevTools → Network tab.
3. Submit a deliberately wrong answer.
4. Inspect the request payload sent to the server. Confirm — by reading it yourself — that no field resembling a correct answer or a correctness claim exists anywhere in it.
5. Inspect the response. Confirm the server told you, correctly, that your answer was wrong.
6. Now attempt to break it: right-click the request, copy it as a fetch call, and try adding any field you can think of that might convince the server the answer was actually correct. Run it from the console.
7. Reload the page. Confirm your answer is still shown as wrong, in the database and on screen — because there is genuinely nothing in the request payload capable of changing that outcome.

If you want to see exactly how this was *not always true* — Parts 10 and 11 of the implementation record document the deliberately-built-vulnerable version and its complete fix side by side. Reading that pair of parts back to back is the single highest-value use of your time this week if you plan to work anywhere near assessment grading, progress computation, or certificate issuance.

### End-of-day checkpoint

You should be able to explain:
- Precisely which query in the entire codebase is allowed to fetch an assessment's answer key, and why exactly one
- Why `grep`-ing for `correctOptionIndex` or `expectedKeywords` outside that one query is treated as a release-blocking finding (Appendix F §F.5.1, `docs/TEST_PLAN.md` §6.1)
- What "the browser proposes, the server disposes" means in your own words, applied to a feature area you haven't looked at yet

---

## Day 4: Your First Change — A Guided Walkthrough

### Goal for today

Make one small, real, low-risk change, following the full contribution loop end to end: branch, code, test, document, commit, PR.

### Suggested first tickets (representative, not exhaustive)

- Add a new field to an existing `components/ui/` component (low risk, high learning value for the design system conventions)
- Add a new unit test case to `tests/unit/validation.test.ts` covering an edge case not yet covered
- Add a new index to a Neon table per the recommendation in Appendix B §B.8 (a real, useful, low-risk production-hardening task)

Avoid, for your very first change: anything touching `lib/modules/grading.ts`, `submit-module-attempt.ts`, or any Server Action's authorization logic. Not because you can't be trusted with it eventually — because the review bar for that code is intentionally the highest in the codebase (Section "Code Review Standards" below), and your first PR shouldn't also be your first exposure to that bar.

### The contribution loop

```bash
git checkout -b your-name/short-description-of-change
```

Make your change. Then, before committing, run the exact same verification sequence used at the end of every part in the original implementation record:

```bash
npm run lint
npm run typecheck
npm run build
npm run test:unit
```

If your change touches a page or user-facing flow, also run:

```bash
npm run test:e2e
```

Commit with a message following the project's established convention — descriptive, specific, naming *what* changed and *why*, mirroring the style of every Git checkpoint in Parts 1–16 (e.g., `"Add composite index on course_progress.last_activity_at to speed up inactivity queries"` — not `"fix stuff"`).

```bash
git add .
git status   # confirm nothing unexpected (especially .env.local) is staged
git commit -m "..."
git push -u origin your-name/short-description-of-change
```

Open a pull request. In the description, reference:
- The requirement ID from `docs/SRD.md` this change relates to, if applicable
- Which test cases from `docs/TEST_PLAN.md` (if any) verify it
- Any data dictionary or architecture doc update needed alongside the code change (see "Documentation Obligations" below)

---

## Code Review Standards

Every reviewer on this project — and every engineer submitting code — is expected to check the following, in order, before approving any change. This list is not aspirational; it is the actual bar this codebase was built against across all sixteen implementation phases.

### 1. Does this change need a new resource-level authorization check?

If the change adds a new page, Server Action, or Route Handler that reads or writes data scoped to a specific user, course, or other resource, confirm it performs **both**:
- Route-level check (`requireUser()` / `requireRole()`)
- Resource-level check (an explicit, independent verification that *this* user has a genuine relationship to *this* specific resource)

Walk the new code against the audit table pattern in Appendix F §F.3.1. If you can't find an equivalent row for your new resource, that's a gap, not an oversight to defer.

### 2. Does this change touch anything answer-key related?

If a change touches `lib/modules/`, any Sanity query involving `quizBlock` or `codeExerciseBlock`, or grading logic of any kind — run the exact `grep` checks from Appendix F §F.5.1 before approving:

```bash
grep -rn "correctOptionIndex\|expectedKeywords" sanity/lib/queries.ts
grep -rn "clientComputedIsCorrect\|clientComputedScore" lib/
```

Any unexpected match in either command is a release-blocking finding, full stop, regardless of how urgent the surrounding change is.

### 3. Does this change introduce a new "at most one" business rule?

If yes (a new kind of enrollment, a new kind of issued artifact, anything that must never be duplicated), confirm a database-level unique constraint enforces it — not solely an application-level existence check. Reference `docs/ARCHITECTURE.md` §7.4 and Appendix B §B.4 for the pattern.

### 4. Does this change introduce a new external webhook or background job?

If yes, confirm it follows the idempotency pattern in Appendix E §E.3 (or, for webhooks specifically, `docs/API_REFERENCE.md` §5.1's guidance for new inbound sources) — record-before-process, with a uniqueness constraint on the provider's own delivery identifier.

### 5. Are error messages safe?

Confirm no new code path returns a raw `error.message`, stack trace, or internal identifier to the client. Reference Appendix F §F.8.1.

### 6. Is the change tested?

- Pure logic changes (especially anything resembling `grading.ts`) require a unit test.
- New user-facing flows require an E2E test or, at minimum, a documented manual verification step added to `docs/TEST_PLAN.md`.
- A fix for any Critical or High severity defect requires a permanent regression test, per `docs/TEST_PLAN.md` §8.3.

---

## Documentation Obligations

This project maintains its documentation as a living, accurate reflection of the system — not a one-time artifact. Any change falling into the categories below **must** update the corresponding document in the same pull request, not as a follow-up:

| Change type | Document(s) to update |
|---|---|
| New or modified Neon table/column | `docs/DATA_DICTIONARY.md` §2, Appendix B, and the ERD narration (`docs/ERD_NARRATION.md`) if a new relationship is introduced |
| New or modified Sanity schema field | `docs/DATA_DICTIONARY.md` §3, Appendix C |
| New Route Handler or Server Action | `docs/API_REFERENCE.md` Section 3 or 4 |
| New Inngest event or scheduled function | `docs/API_REFERENCE.md` Section 6, Appendix E |
| New functional requirement or behavior change | `docs/SRD.md` Section 3, with a new or updated REQ-ID |
| New or changed security control | Appendix F, and `docs/TEST_PLAN.md` Section 6 if it warrants a dedicated adversarial test |
| New deliberate scope gap | `docs/ARCHITECTURE.md` §11 and `docs/PRD.md` §11 |

A pull request that changes system behavior without a corresponding documentation update should be treated the same as a pull request without tests — incomplete, not merely "nice to have later."

---

## Week 2 and Beyond: Deepening Your Understanding by Subsystem

Once Days 1–4 are complete, deepen your knowledge in whichever subsystem your work will actually touch, using this map:

| If you're working on... | Read this, in order |
|---|---|
| Public pages / content rendering | Appendix C (full), Appendix D §D.5–D.6 |
| Authentication / user provisioning | `docs/API_REFERENCE.md` §3.2 and §5, Appendix F §F.2 and §F.6 |
| Enrollment / progress tracking | `docs/ARCHITECTURE.md` §7.4, Appendix E §E.3 (idempotency), the Part 8 concurrency test script pattern |
| Assessment grading | Everything in Day 3, plus Appendix F §F.5 in full, plus `lib/modules/grading.ts` read start to finish |
| Background workflows (Inngest) | Appendix E in full — every pattern has a runnable example |
| Instructor analytics | `docs/API_REFERENCE.md` §4, Appendix B §B.7 (query patterns), `docs/TEST_PLAN.md` §4.9 |
| Deployment / operations | `docs/ARCHITECTURE.md` §10, Appendix G in full |

---

## Common First-Month Mistakes (and How to Avoid Them)

| Mistake | Why it happens | The fix |
|---|---|---|
| Treating a resource-scoped query's `null` result as a bug | New engineers expect an error when access is denied | Recall: `null` for "not found" and `null` for "not authorized" are *deliberately* the same response — re-read Appendix F §F.3.2 |
| Adding a field to a client-facing GROQ query without checking what it exposes | Feels like a routine content addition | Before adding *any* field to a public or authenticated (non-server-only) query, ask: could this field ever determine correctness of something gradable? If yes, stop and consult Appendix F §F.5.1 |
| Writing a "check then insert" pattern for a new uniqueness rule | Feels intuitive, works in local testing | Local testing rarely exposes race conditions — always add the database constraint, and treat the application-level check as a UX nicety, never the actual guarantee (Appendix B §B.4) |
| Calling `db.insert(...)` instead of `tx.insert(...)` inside a transaction callback | Easy typo, no immediate error | This silently breaks the transaction's atomicity guarantee with no warning — always double-check every query inside a `db.transaction(async (tx) => {...})` callback uses `tx` |
| Emitting an Inngest event from inside a database transaction | Seems like it should be fine | If the transaction later rolls back, the event has already been sent describing something that never actually happened — always emit after the transaction commits, never inside it (`docs/ARCHITECTURE.md` §8.2) |
| Assuming `.env.local` changes take effect immediately | Works this way in some other frameworks/tools | Environment variables are read once at process startup — always restart `npm run dev` after any `.env.local` change |

---

## Getting Help

1. Check Appendix G (Troubleshooting Guide) first — it is organized as a diagnostic flowchart specifically so you can self-serve most environment and build issues.
2. Check whether your question is already answered in one of the case studies in `docs/USER_MANUAL.md` if it's a product-behavior question rather than an implementation question.
3. Ask your onboarding buddy or the team channel, but **include what you already checked** — "I read Appendix G §G.4 and confirmed my `DATABASE_URL` uses the pooled connection, but I'm still seeing X" is a question the team can act on immediately; "the database doesn't work" is not.

---

## Onboarding Completion Checklist

Before your onboarding buddy signs off on your onboarding:

- [ ] Local environment runs cleanly (`npm run dev`, Inngest dev server, full verification suite all pass)
- [ ] You have personally reproduced and fixed-side-verified the assessment integrity exercise (Day 3)
- [ ] You have merged at least one real pull request following the full contribution loop
- [ ] You can explain, unprompted, the two-layer authorization pattern and give an example from a part of the codebase you found yourself, not one from this guide
- [ ] You know which document to update for each of the seven change types in "Documentation Obligations"
- [ ] You know where to find the troubleshooting guide and have used it at least once without escalating

Welcome aboard.
