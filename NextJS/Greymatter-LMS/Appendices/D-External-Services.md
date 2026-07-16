# Appendix D — External Services & Setup Reference

This appendix consolidates every external service and hosted dependency referenced throughout the Greymatter LMS series, based strictly on what the tutorials actually build.

---

## D.1 Clerk (Authentication)

**What it's for:** Identity, authentication, and organization membership. Clerk's `auth()` call confirms a student is signed in and returns their `userId` and `orgId`, which every downstream layer relies on [12].

**Where it's used across the series:**
- Wired into the App Router in Part 3, protecting the `(dashboard)` route group via middleware while leaving `(auth)` routes public [7]
- Every Server Action re-checks `auth()` before writing data, and this check is explicitly verified again in Part 9's hardening pass — confirming that a user from one organization cannot submit against another organization's course [1]
- Deployed to production in Part 12, with `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY` and `CLERK_SECRET_KEY` set in the Vercel dashboard [9]

**Setup checklist:**
- Create a Clerk account and grab your API keys before starting Part 3, section 4 [7]
- Wire the publishable/secret keys into route middleware (`createRouteMatcher`, `clerkMiddleware`) [7]
- For production, create or upgrade to a production-tier Clerk setup before Part 12 [9]

---

## D.2 Neon Postgres (Database)

**What it's for:** The core system of record — courses, lessons, enrollments, submissions, and worker results [6].

**Where it's used across the series:**
- Schema defined in Part 4 with tables including `lessons`, `enrollments`, and `submissions`, each carrying an `orgId` column [6]
- Since there's no Row-Level Security, every query touching `courses`, `enrollments`, or `submissions` must manually filter by `orgId`, matched against the signed-in user's Clerk organization [6]
- The `submissions` table is what Part 5's `assignment.submitted` event reads from and writes results back into [6][5]
- Deployed to production in Part 12, with `DATABASE_URL` set in the Vercel dashboard [9]

**Setup checklist:**
- Create a Neon project and database
- Set up your `DATABASE_URL` connection string
- Manually enforce tenant isolation via `orgId` in every query — since this replaces what RLS would otherwise provide [6]
- Confirm `worker_results` exists early, even before a worker exists — Part 5's Inngest function needs it immediately, and Part 7 onward assumes it's already there [6]

---

## D.3 Inngest (Orchestration / Event Engine)

**What it's for:** The event bus and workflow engine — the only layer allowed to decide "this event happened, go run these workers" [12][5].

**Where it's used across the series:**
- Set up in Part 5 to run the first real event-driven function, `assignment.submitted` — no account signup is required for local dev, just the CLI via `npx` [5]
- Two pieces are deliberately left as placeholders at first — `discover-workers` (hardcoded array) and `execute-workers` (just logs) — proven out end-to-end before Part 6 and Part 7 replace them with real logic [5]
- Extended in Part 8 with fan-out execution, fan-in aggregation (`aggregate-report`), and conditional/adaptive workflows [2]
- Hardened in Part 9 to reject malformed events — e.g., a `student.struggling` event missing `submissionId` now fails immediately rather than proceeding [1]
- Deployed to production in Part 12, with `INNGEST_EVENT_KEY` and `INNGEST_SIGNING_KEY` set in the Vercel dashboard [9]

**Setup checklist:**
- Install the Inngest CLI (globally or via `npx`) for local dev [5]
- No account needed until deploying — Inngest Cloud keys are only required in Part 12 [5][9]
- Configure event keys and signing keys before production deployment [9]

---

## D.4 Sanity (Worker Registry — not a CMS)

**What it's for:** The **only** place that knows "these workers exist and listen to these events" [12]. Explicitly not used as a content management system in this architecture.

**Where it's used across the series:**
- Built in Part 6 as a real alternative to a hardcoded worker array — proving that a worker can be added, disabled, or swapped as a **content edit**, with zero code changes to Inngest or the frontend [4]
- Every worker is registered as a Sanity document with `name`, `events`, `endpoint`, and `enabled` fields — first the Grading Worker (Part 6/7) [4][3], then the Quiz Worker (Part 8), registered with the exact same document shape [2]
- The registry client lives in `packages/registry`, with responsibilities limited to fetching workers, validating schemas, filtering by event type, and managing enable/disable state [8][4]
- The checkpoint proving this works: toggling `enabled` to `false` on a worker document, publishing with no code touched, and confirming `discover-workers` returns an empty array — then flipping it back and confirming rediscovery [4]

**Setup checklist:**
- Create a Sanity project and dataset (e.g., `production`) [4]
- Deploy the worker document schema
- Register each worker (name, events, endpoint, enabled) as you build it, starting in Part 6 [4]

---

## D.5 Worker Services (Execution Layer)

**What it's for:** Independently deployed AI workers — the only place AI logic actually lives [12]. Each worker implements a shared `WorkerInput`/`WorkerOutput` contract.

**Where it's used across the series:**
- The Grading Worker is built and registered first, in Part 7, following a six-step formal registration flow: build → deploy → generate a shared `WORKER_SIGNING_SECRET` → create a Sanity document → publish → auto-discovery via `findWorkers()` [3]
- The Quiz Worker follows the identical flow in Part 8 [2]
- The Summary Worker is added in Part 11 as a genuinely new capability, listening to a brand-new event (`lesson.completed`) rather than `assignment.submitted` — the clearest proof that "new AI feature = new worker, no core changes" holds [10]
- Every request/response is HMAC-signed and verified — using an `x-signature` header for the Grading and Quiz Workers, and `x-greymatter-signature` for the Summary Worker [3][10]

**Setup checklist (per worker):**
- Deploy the worker as its own independent service (locally first; Vercel/Railway in Part 12) [3][9]
- Share the same `WORKER_SIGNING_SECRET` between the orchestrator and the worker [3]
- Register it in Sanity (D.4) as a document with `name`, `events`, `endpoint`, `enabled: true` [3][4]
- Set the worker's own environment variables (e.g., `OPENAI_API_KEY` for the Summary Worker in Part 11) [10]

---

## D.6 Cross-Cutting Requirement: Tenant Isolation (`orgId`)

Not a separate service, but a requirement touching Clerk, Neon, and Inngest together: every tenant-scoped table carries an `orgId` column, and every query must filter by it, since Neon provides no Row-Level Security [6]. This is checked at multiple points:
- In every Server Action, matched against the Clerk-authenticated user's `orgId` [6]
- Re-verified explicitly in Part 9's hardening pass — confirmed via a checkpoint using two separate Clerk test accounts in two different organizations, where Org A's user attempting to submit against Org B's `courseId` receives a "Rejected" error [1]

---

## D.7 Production Deployment Services

**What it's for:** Taking every service above from local development to production.

**Where it's used across the series:** Part 12 deploys the frontend via `vercel`, and sets every accumulated environment variable in the Vercel dashboard — forming a direct audit trail back through the series: Clerk keys (Part 3), `DATABASE_URL` (Part 4), Inngest keys (Part 5/9), and `WORKER_SIGNING_SECRET` (Part 7) [9][1][3].

**Setup checklist:**
- Production-tier (or upgraded free-tier) accounts for Vercel, Neon, Clerk, Inngest Cloud, and Sanity — each created just before it's needed [9]
- Run `vercel` from `apps/web` [9]
- Set all environment variables in the Vercel dashboard [9]
- **✅ Checkpoint:** Run `vercel --prod`, visit your deployed URL, sign in with Clerk, and confirm `/courses` renders real data from Neon Postgres [9]

---

## D.8 Quick Reference Table

| Service | Introduced in | Primary Role |
|---|---|---|
| Clerk | Part 3 [7] | Authentication, org membership |
| Neon Postgres | Part 4 [6] | System of record, manual tenant isolation |
| Inngest | Part 5 [5] | Event bus, orchestration, fan-out/fan-in [2] |
| Sanity | Part 6 [4] | Worker registry (not a CMS) |
| Worker Services | Part 7, extended Part 8 & 11 [3][2][10] | Independently deployed AI execution |
| Production Deployment | Part 12 [9] | Hosting every layer above |

---

## D.9 How to Use This Appendix

Before starting any tutorial part that introduces a new service, check this appendix first to confirm:
1. Do you already have an account/project for it? (D.1–D.4)
2. Does this logic need to respect the `orgId` tenant-scoping rule? (D.6) — nearly everything touching Neon or Inngest does [6][1]
3. Is this a core hosted service, or a worker you're expected to build and deploy yourself? (D.5)

If a specific setup step isn't covered here, that level of detail wasn't present in the source material — treat D.1–D.5's checklists as a starting outline to fill in with each provider's current onboarding docs.
