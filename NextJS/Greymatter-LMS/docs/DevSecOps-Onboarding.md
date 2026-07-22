# GreyMatter LMS — DevSecOps Onboarding Guide

**Document type:** DevSecOps Onboarding Guide
**Product:** GreyMatter LMS
**Version:** 1.0
**Status:** Baseline — approved
**Location:** `docs/DEVSECOPS_ONBOARDING.md`
**Companion documents:** `docs/ARCHITECTURE.md`, `docs/SRD.md`, `docs/ONBOARDING.md`, `docs/API_REFERENCE.md`, `docs/TEST_PLAN.md`, Appendix F, Appendix G

---

## Purpose of This Guide

`docs/ONBOARDING.md` takes a new engineer from zero to their first merged feature. This guide is different: it takes a new **DevSecOps engineer** — someone responsible for infrastructure, deployment pipelines, secrets governance, security gates, and production operations — from zero to being trusted with production access. If your role is "make sure this system deploys safely, stays secure, and can be operated with confidence by people other than the person who built it," this is your document.

This guide assumes you have already completed `docs/ONBOARDING.md` Days 0–3 (accounts, local environment, the architectural mental model, and the assessment-integrity exercise). If you have not, stop and do that first — you cannot responsibly own deployment and security operations for a system you don't understand the trust model of.

---

## Day 1: Infrastructure Topology and Ownership

### Goal for today

Build a complete, accurate map of every piece of infrastructure this system depends on, who owns each credential, and what happens if each one fails.

### 1.1 The complete infrastructure inventory

Walk through this table with your onboarding buddy, confirming your own access to each row as you go:

| Component | Hosting | Environments | Credential owner | Failure blast radius |
|---|---|---|---|---|
| Application runtime | Vercel | Production, Preview (per-branch), Development (local) | DevSecOps team | Total outage |
| Transactional database | Neon | `production` branch, `main` (dev) branch | DevSecOps team | Total outage for all authenticated/transactional features; public content pages degrade to stale-cache only |
| Content system | Sanity | Single project, single `production` dataset | DevSecOps team + Content lead | Public catalog and lesson content unavailable; authenticated dashboard shells still load but show empty/error states |
| Identity provider | Clerk | Separate dev and production applications | DevSecOps team | No new sign-ins/sign-ups; existing sessions may continue briefly depending on session TTL |
| Background workflow engine | Inngest | Separate dev and production environments | DevSecOps team | Synchronous features (enrollment, submission) continue working; progress recalculation, certificates, reminders silently stop advancing |
| Transactional email | Resend | Single account, no environment separation | DevSecOps team | Emails silently fail to send; system falls back to structured logging only if unconfigured, but a genuine outage of a *configured* provider fails silently unless monitored (see Day 3) |
| Rate limiting | Upstash Redis | Production only, by design | DevSecOps team | Fails open — rate limiting silently disabled, not blocking |

**Read now:** `docs/ARCHITECTURE.md` §4 and §10 in full.

### 1.2 Understanding the deliberate asymmetries

Two things in the table above are easy to misread as oversights. They are not — confirm you understand why before moving on:

1. **Resend has no environment separation**, unlike every other service. This is deliberate: sending a real email in "development" has no destructive side effect worth isolating against, unlike a database write or a production webhook secret.
2. **Upstash fails open, not closed.** This is a documented, deliberate trade-off (`docs/ARCHITECTURE.md` §11, Appendix F §F.7.2) favoring local-development accessibility over defense-in-depth-by-default. As the DevSecOps owner, this specific trade-off is **your** responsibility to actively counteract in production — Section "Day 4: The Security Gate" below covers exactly how you verify this isn't silently left unconfigured.

### 1.3 Exercise: draw the failure-mode diagram yourself

Without looking at the table above, draw the infrastructure diagram from `docs/ARCHITECTURE.md` §2 from memory, and annotate every arrow with "what happens if this specific dependency goes down." Compare against the table. Any gap between your diagram and the table is something to discuss with your onboarding buddy today, not later.

---

## Day 2: Secrets and Credential Governance

### Goal for today

Understand exactly where every secret lives, who can access it, how it's rotated, and what the actual incident response is if one leaks.

### 2.1 The secrets inventory

| Secret | Environments requiring distinct values | Stored in | Rotation trigger |
|---|---|---|---|
| `DATABASE_URL` | Dev (`main` branch), Production (`production` branch) | Vercel env vars (per environment scope), local `.env.local` | Suspected compromise; Neon branch recreation |
| `CLERK_SECRET_KEY` / publishable key | Dev app, Production app — fully separate Clerk applications | Vercel env vars, local `.env.local` | Suspected compromise; Clerk key rotation via dashboard |
| `CLERK_WEBHOOK_SIGNING_SECRET` | One per registered endpoint — dev (via ngrok) and production are inherently distinct | Vercel env vars, local `.env.local` | Any change to the webhook endpoint URL; suspected compromise |
| `SANITY_API_TOKEN` | Single dataset; token scope should be minimized to what's actually needed | Vercel env vars | Suspected compromise; access-scope review |
| `INNGEST_EVENT_KEY` / `INNGEST_SIGNING_KEY` | Dev and production Inngest environments | Vercel env vars | Suspected compromise |
| `RESEND_API_KEY` | Single account | Vercel env vars | Suspected compromise |
| `UPSTASH_REDIS_REST_URL` / `_TOKEN` | Production only | Vercel env vars (production scope only) | Suspected compromise |

**Non-negotiable rule, stated exactly as it appears in Appendix F §F.9.4:** *"Production secrets are distinct from development secrets"* — for every single row in this table, without exception.

### 2.2 The single most important verification you will ever run

Run this command right now, on your own machine, regardless of how many times you've been told it's already clean:

```bash
git log --all --full-history -- .env.local
```

**Expected output: nothing.** If this ever returns even one commit, treat every secret that file has ever contained as permanently compromised — see Appendix F §F.9.1. This is not a one-time check; it is a command you run **before every release**, permanently, for the life of this project (`docs/TEST_PLAN.md` §7.3, Suspension Criteria).

### 2.3 Exercise: trace one secret's full lifecycle

Pick `CLERK_WEBHOOK_SIGNING_SECRET` specifically and trace, concretely:
1. Where it's generated (Clerk's dashboard, per registered endpoint)
2. Where it's consumed (`app/api/webhooks/clerk/route.ts` — open the file, find the line)
3. Why the dev and production values are *necessarily* different, not just *conventionally* different (hint: re-read `docs/ARCHITECTURE.md` §7.5 and Appendix F §F.6.3)
4. What breaks, specifically, if these two values were ever accidentally swapped

### 2.4 Incident response: a leaked secret

If you ever discover a secret has been exposed (committed to Git, pasted into a public channel, logged in plaintext), the response is:

```text
1. Rotate the specific credential IMMEDIATELY, at the source
   (Clerk dashboard, Neon console, Sanity manage, Inngest dashboard,
   Resend/Upstash dashboard as applicable) — do not wait for
   permission; rotation is always reversible, exposure is not.

2. Update the rotated value in every environment that used it
   (Vercel production, Vercel preview if shared, every team member's
   local .env.local).

3. If the secret was committed to Git: do NOT simply delete it in a
   new commit and consider it resolved — the old commit still
   contains it in history. Treat the exposure as permanent from that
   commit's point in history forward, regardless of subsequent
   deletion.

4. Check webhook_events, workflow_events, and audit_logs for any
   activity in the exposure window that doesn't match expected
   patterns — this is your evidence trail if the secret was actually
   misused, not just exposed.

5. Document the incident: what leaked, when, how it was discovered,
   what was rotated, and what changed to prevent recurrence.
```

---

## Day 3: The CI/CD Pipeline and Deployment Procedure

### Goal for today

Understand exactly what happens between a merged pull request and a live production deployment, and where you — as the DevSecOps owner — are the last line of defense before something reaches real users.

### 3.1 The pipeline, stage by stage

```text
Pull request opened
        │
        ▼
┌─────────────────────────────────────┐
│  CI: lint, typecheck, unit tests,      │  ← Every commit
│  security regression tests             │
└─────────────┬─────────────────────────┘
              │ pass
              ▼
   Vercel Preview deployment (per-branch)
              │
              ▼
   E2E + accessibility tests run against
   the preview deployment
              │
              ▼
   Code review (docs/ONBOARDING.md,
   "Code Review Standards" section)
              │
              ▼
        Merge to main
              │
              ▼
┌─────────────────────────────────────┐
│  Pre-deploy gate (YOUR responsibility) │  ← Section 3.2 below
└─────────────┬─────────────────────────┘
              │ pass
              ▼
   Production deployment (Vercel)
              │
              ▼
   Production migration run (manual,
   deliberate — see Section 3.3)
              │
              ▼
   Post-deploy smoke test (Section 3.4)
```

### 3.2 The pre-deploy gate — your primary release-day responsibility

Before authorizing any production deployment, walk the **complete** exit criteria from `docs/TEST_PLAN.md` §7.2. Do not treat this as a formality — this is the actual job. Reproduced here for convenience, with your specific action against each item:

| Exit criterion | Your action |
|---|---|
| 100% of Mandatory requirement tests pass | Confirm CI is green on the exact commit being deployed, not a stale prior run |
| Zero regression suite failures | Specifically confirm `grading-security.test.ts` passed — this is the one test file whose failure should stop a release regardless of any other pressure |
| Full end-to-end journey passes against staging | Run it yourself against the Preview deployment for this specific release, not just trust CI |
| Zero accessibility violations on homepage/catalog | Confirm the axe-core scan ran against this build |
| Adversarial assessment-integrity protocol executed manually this release cycle | If it hasn't been run this cycle, run it yourself now (Appendix F §F.11, `docs/TEST_PLAN.md` §6.1) — do not skip this because "nothing touched grading this release," since a regression can be introduced by unrelated refactoring |
| Appendix F §F.11 full checklist satisfied | Walk every single line item personally |
| No open Critical/High severity defect | Confirm against the current defect tracker |

**This gate exists specifically so that release pressure never becomes the reason a security check gets skipped.** If you are ever asked to bypass this gate "just this once," escalate — do not quietly comply.

### 3.3 Production database migrations — the one manual, deliberate step

Migrations are never applied automatically as part of the Vercel deploy pipeline in this system. This is deliberate. Follow this exact procedure:

```bash
# 1. Point at the PRODUCTION branch's connection string — verify
#    this is correct before running anything. A wrong DATABASE_URL
#    here is the single most dangerous mistake possible in this
#    entire onboarding guide.
echo $DATABASE_URL  # confirm it points at the -pooler production hostname

# 2. Review the generated migration SQL file BEFORE applying it —
#    never apply a migration you haven't personally read.
cat db/migrations/000X_*.sql

# 3. Apply it
npm run db:migrate

# 4. IMMEDIATELY revert your local environment back to the
#    development branch's connection string.
```

**Read this before your first production migration:** Appendix G §G.5 in full, and `docs/ARCHITECTURE.md` §10's note that "no environment's schema is ever hand-edited outside this pipeline." If a migration fails partway through in production, do not attempt to hand-fix it under time pressure — follow Appendix G §G.5.1's guidance and involve a second engineer before touching production schema state directly.

### 3.4 Post-deploy smoke test

Immediately after every production deployment:

1. Visit `/api/health` on the production domain — confirm `200 OK`.
2. Sign in with a known test account; confirm dashboard loads.
3. Check the Inngest production dashboard — confirm the app shows as "synced" with every expected function listed (`docs/API_REFERENCE.md` §6.2).
4. Check Clerk's production dashboard — confirm the webhook endpoint shows no recent failed delivery attempts.

If any of these four checks fail, you are the one who decides whether to roll back — know Vercel's rollback procedure for this project before your first solo deployment, not during one.

---

## Day 4: Ongoing Security Operations

### Goal for today

Understand what you are responsible for monitoring *continuously*, not just at release time.

### 4.1 The continuous security checklist

This is Appendix F §F.11 reframed as an operational, recurring responsibility rather than a one-time gate:

| Check | Frequency | How |
|---|---|---|
| `.env.local` never committed | Every release, permanently | `git log --all --full-history -- .env.local` |
| Production/dev secrets remain distinct | Whenever any credential is rotated | Manual comparison across environments |
| Answer-key fields never leak into client-facing queries | Every commit (automated) + manual spot-check monthly | `grep -rn "correctOptionIndex\|expectedKeywords" sanity/lib/queries.ts` |
| No client-computed grading fields reintroduced | Every commit (automated) | `grep -rn "clientComputedIsCorrect\|clientComputedScore" lib/` |
| Rate limiting genuinely active in production | Every release | Confirm `UPSTASH_REDIS_REST_URL`/`_TOKEN` are set in Vercel's **production** scope specifically, not just present somewhere |
| Webhook signature verification functioning | Every release + ad hoc | Send a deliberately malformed request to the production webhook endpoint (from a controlled test, never against a live customer-impacting path without care) and confirm `400` |
| No raw error detail leaking to clients | Every release | Spot-check a few known error paths in production; confirm generic messages only |
| Audit trail integrity | Ongoing | Periodically query `audit_logs` for a sample user; confirm entries exist for expected actions and that a deleted-user's entries show a nulled `user_id`, not a missing row |

### 4.2 What to actually monitor, and where

| Signal | Source | What you're watching for |
|---|---|---|
| Application errors | Vercel deployment logs / your logging integration | Spikes correlating with a specific deploy |
| Failed webhook deliveries | Clerk dashboard | Sustained failures indicate a signature/secret mismatch or an outage |
| Inngest function failure rate | Inngest production dashboard | A failing function should show retries; a function stuck permanently failing needs manual investigation, starting with `workflow_events.status = 'FAILED'` rows in Neon |
| Database connection errors | Application logs | Recall Appendix G §G.4 — distinguish "too many connections" (pooled connection misconfiguration) from a genuine outage |
| Certificate issuance anomalies | `certificates` table row count vs. `course/completed` events emitted | A sustained mismatch suggests the `issue-certificate` function is failing silently — check `workflow_events` |
| Rate limit trigger frequency | Application logs (`"Too many requests"` responses) | A sudden spike may indicate abuse rather than legitimate load |

### 4.3 Exercise: run the full adversarial protocol yourself, unaided

Today, without your onboarding buddy walking you through it, execute the complete Section 6.1 protocol from `docs/TEST_PLAN.md` (the assessment-integrity adversarial test) against your local environment, start to finish, from memory. This is the single test you will be personally responsible for executing manually before every release for as long as you hold this role. It should be second nature before you're trusted to sign off on a production deploy alone.

---

## Day 5: Incident Response and Runbooks

### Goal for today

Know what to do — precisely, without improvising — for the incident classes most likely to actually occur in this system.

### 5.1 Runbook: Suspected assessment-integrity compromise

**Trigger:** any report or automated finding suggesting a student's graded result does not match server-computed correctness.

```text
1. Do NOT attempt to "quietly fix" the specific student's record first —
   first determine SCOPE: is this one anomalous row, or a systemic
   regression?

2. Immediately run the grep checks from Section 4.1 against the
   currently deployed commit. If either answer-key field or either
   client-computed-grading field is found where it shouldn't be,
   this is a CRITICAL, release-blocking finding — treat per
   docs/TEST_PLAN.md §7.3 (Suspension Criteria).

3. If a regression is confirmed: identify the specific commit that
   introduced it via `git log` / `git bisect` against
   grading-security.test.ts's known-good history.

4. Roll back the production deployment to the last known-good commit
   BEFORE attempting a forward fix, unless the forward fix is already
   reviewed and tested.

5. Audit module_attempts rows created during the exposure window for
   evidence of actual exploitation, not just possibility.

6. Add a new, permanent regression test encoding this specific
   scenario before closing the incident, per docs/TEST_PLAN.md §8.3.
```

### 5.2 Runbook: Duplicate enrollment or certificate discovered

**Trigger:** more than one active row found for a user/course pair in `enrollments` or `certificates`.

```text
1. Confirm the relevant UNIQUE CONSTRAINT genuinely exists on the
   live production database — do not assume; check directly via
   Drizzle Studio or the Neon console's constraint listing.

2. If the constraint is missing: this is a CRITICAL infrastructure
   gap — a migration was not applied correctly to production, or was
   reverted. Apply the correct migration immediately, following
   Section 3.3's procedure.

3. If the constraint IS present and a duplicate still exists: this
   indicates a genuinely novel race condition not covered by existing
   defenses. Do not simply delete the "extra" row without
   understanding how it was created — preserve both for investigation,
   remediate the application logic, add a regression test, THEN clean
   up the data.
```

### 5.3 Runbook: Background workflow stuck failing

**Trigger:** `workflow_events` shows a growing number of `FAILED` rows for a specific event type, or Inngest's dashboard shows repeated failures for one function.

```text
1. Check the Inngest dashboard's run detail for the specific failing
   step — identify whether the cause is transient (external service
   outage) or a genuine code defect.

2. If transient: confirm Inngest's own retry mechanism is still
   attempting the function (per docs/ARCHITECTURE.md §8.3's
   "failure recording + re-throw" pattern) — do not manually
   re-trigger unless retries have been exhausted.

3. If a genuine code defect: this requires a code fix and
   redeployment, following the standard pipeline (Section 3) — do
   not attempt to patch behavior directly against production data.

4. Once the underlying issue is fixed, identify every event that
   failed during the incident window (via workflow_events) and
   determine whether each needs to be manually re-emitted, or whether
   the fix + natural retry will resolve them.
```

### 5.4 Runbook: External service outage (Sanity, Neon, Clerk, or Inngest)

```text
1. Confirm via the provider's own status page whether this is a
   known, provider-side incident.

2. Identify blast radius using the table in Section 1.1 — communicate
   accurately what IS and ISN'T affected (e.g., a Sanity outage does
   NOT take down authentication or enrollment; only content-dependent
   pages degrade).

3. If the outage is prolonged, consider whether any degraded-mode
   messaging should be added to affected pages — this system does not
   currently implement automatic degraded-mode UI, so this may require
   an emergency deploy; weigh the risk of that deploy against the
   outage's duration and impact.

4. Document the incident timeline regardless of whether it required
   any action on your part — provider outages affecting this system
   should still be logged for pattern-tracking across time.
```

---

## Week 2: Ownership Transition

### Goal for this week

Move from shadowing to being the primary responsible party for one full release cycle, with your onboarding buddy observing rather than leading.

### Checklist before you run a release solo

- [ ] You have personally executed the pre-deploy gate (Section 3.2) at least twice, shadowing an experienced DevSecOps engineer
- [ ] You have personally run the adversarial assessment-integrity protocol from memory, unaided (Section 4.3)
- [ ] You have personally executed a production database migration under supervision (Section 3.3)
- [ ] You can recite, without looking it up, the difference in blast radius between a Neon outage and a Sanity outage
- [ ] You know exactly where every secret in the Section 2.1 inventory lives and who else has access to rotate it
- [ ] You have read every runbook in Section 5 and can explain, for each, why the *first* step is what it is (most begin with "confirm scope before reacting," which is a deliberate, repeated pattern worth internalizing)
- [ ] You understand and agree that the pre-deploy gate is never negotiable under release-schedule pressure

### Ongoing responsibilities, once fully onboarded

| Cadence | Responsibility |
|---|---|
| Every release | Full pre-deploy gate (Section 3.2); post-deploy smoke test (Section 3.4) |
| Every release | `.env.local` history check (Section 4.1) |
| Monthly | Manual spot-check of answer-key exposure and client-computed-grading greps, independent of CI, as a defense-in-depth habit |
| Quarterly | Review the known-gaps list (`docs/ARCHITECTURE.md` §11) and confirm none has silently become more urgent (e.g., real user scale approaching the sequential fan-out limits noted in Appendix E §E.8) |
| Quarterly | Credential rotation review — confirm no secret has gone untouched for an unreasonably long period without at least a deliberate decision not to rotate it |
| As needed | Incident response, per Section 5's runbooks |

---

## Reference: Your Personal Command Toolkit

Commands you should have memorized, not bookmarked, by the end of Week 2:

```bash
# Secret exposure check — run before every release, no exceptions
git log --all --full-history -- .env.local

# Answer-key exposure check
grep -rn "correctOptionIndex\|expectedKeywords" sanity/lib/queries.ts

# Client-computed grading regression check
grep -rn "clientComputedIsCorrect\|clientComputedScore" lib/

# Full local verification suite
npm run lint && npm run typecheck && npm run build && npm run test:unit

# Full E2E + accessibility suite
npm run test:e2e

# Database state inspection
npm run db:studio

# Production migration procedure (only after explicit review of the
# generated SQL, and only with DATABASE_URL confirmed correct)
npm run db:generate
cat db/migrations/000X_*.sql
npm run db:migrate
```

---

## Closing Note

Every runbook, checklist, and gate in this document exists because of a specific, real lesson embedded somewhere in this system's own construction — the assessment-integrity vulnerability that was deliberately built and fixed in Parts 10–11, the race conditions proven and closed in Parts 8 and 13, the idempotency patterns built for webhooks in Part 6 and extended for certificates in Part 13. You are not being asked to follow abstract best practices — you are being asked to guard, permanently, against the exact failure modes this system's own history already demonstrated were real. Treat every gate in this guide accordingly.
