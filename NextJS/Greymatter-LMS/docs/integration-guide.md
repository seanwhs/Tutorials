# GreyMatter LMS — Integration Guide

**Document type:** Integration Guide
**Product:** GreyMatter LMS
**Version:** 1.0
**Status:** Baseline — approved
**Location:** `docs/INTEGRATION_GUIDE.md`
**Companion documents:** `docs/ARCHITECTURE.md`, `docs/API_REFERENCE.md`, `docs/DATA_DICTIONARY.md`, Appendix E, Appendix F

---

## 1. Purpose and Audience

This guide is for engineers connecting GreyMatter LMS to an external system — either configuring one of its **six existing** integrations for a new environment, or building a genuinely **new** integration (a new inbound webhook source, a new outbound notification channel, a new payment provider, or a new Inngest-consumed event). It assumes familiarity with `docs/ARCHITECTURE.md` (particularly §4 and §7) and `docs/API_REFERENCE.md`.

Every existing integration in GreyMatter follows one of a small number of repeated shapes. This guide documents each shape once, with its rationale, so a new integration can be built by following an established pattern rather than inventing a new one — consistent with `docs/CODING_STYLE_GUIDE.md`'s governing principle that consistency across integration points is itself a security property.

---

## 2. Integration Architecture Overview

GreyMatter's integration surface falls into exactly four shapes, each with a distinct trust model:

```text
┌─────────────────────────────────────────────────────────────────┐
│  SHAPE A: Delegated Identity                                        │
│  GreyMatter trusts an external provider entirely for a whole domain  │
│  Example: Clerk (authentication)                                     │
├─────────────────────────────────────────────────────────────────┤
│  SHAPE B: Content/Data Provider                                       │
│  GreyMatter queries an external system for read-mostly data,           │
│  never trusts it for security-critical decisions without re-verifying   │
│  Example: Sanity (content)                                               │
├─────────────────────────────────────────────────────────────────────┤
│  SHAPE C: Inbound Webhook Consumer                                        │
│  An external system calls INTO GreyMatter, proactively, to announce        │
│  something happened; GreyMatter verifies and idempotently processes it       │
│  Example: Clerk webhooks                                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│  SHAPE D: Outbound Service Call (fire-and-forget or best-effort)              │
│  GreyMatter calls an external system to perform an action, with a               │
│  documented graceful-degradation behavior if the service is unavailable          │
│  Example: Resend (email), Upstash (rate limiting), Inngest (workflow engine)       │
└─────────────────────────────────────────────────────────────────────────────────┘
```

Before building any new integration, identify which shape it fits — this determines nearly every subsequent design decision in this guide.

---

## 3. Shape A: Delegated Identity Integrations

### 3.1 When to use this shape

Use this shape when the external system is the **sole source of truth** for an entire domain of concern — GreyMatter never re-implements any part of it, only bridges its output into the application's own data model.

### 3.2 The existing reference implementation: Clerk

| Aspect | Implementation |
|---|---|
| Client library | `@clerk/nextjs` — official SDK, wraps session detection into `middleware.ts` |
| Bridging mechanism | Webhook (Shape C) for the primary sync path, plus an on-demand fallback for race conditions |
| Internal identity mapping | `users.auth_provider_id` stores the external ID; `users.id` (internal UUID) is what every other table references |
| Configuration | `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`, `CLERK_WEBHOOK_SIGNING_SECRET` — see `docs/API_REFERENCE.md` §5.1 |

### 3.3 Design checklist for a new Shape A integration

```text
1. Never store the external system's credentials/session data in
   GreyMatter's own database — only store the external identifier
   and whatever profile data is genuinely needed application-side
   (e.g., email).

2. Build a bridging function analogous to ensureInternalUser() that
   resolves an external session to an internal record ON DEMAND, not
   solely reliant on webhook timing — this closes the exact
   provisioning-race condition documented in docs/ARCHITECTURE.md §7
   and docs/THREAT_MODEL.md.

3. Design the internal identifier as independent from the external
   one from day one, even if it feels redundant initially — this is
   what allows the external provider to be swapped later without
   touching every other table's foreign keys.

4. Fail CLOSED (treat as unauthenticated) if the external identity
   API is unreachable — never fail open on an identity check.
```

### 3.4 Reconfiguring Clerk for a new environment

```bash
# 1. Create a new Clerk application (or environment within an
#    existing one) — dev and production MUST be fully separate
#    applications per docs/ARCHITECTURE.md §10.

# 2. Populate environment variables (never reuse across environments):
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=
CLERK_SECRET_KEY=
CLERK_WEBHOOK_SIGNING_SECRET=

# 3. Register the webhook endpoint (see Section 5.4 for the general
#    webhook registration procedure) at:
https://<your-domain>/api/webhooks/clerk
# Subscribed events: user.created, user.updated, user.deleted

# 4. Verify: sign up a test account; confirm a users row appears with
#    the correct auth_provider_id and email (Part 6, Step 6's
#    verification procedure).
```

---

## 4. Shape B: Content/Data Provider Integrations

### 4.1 When to use this shape

Use this shape for any external system holding data GreyMatter reads regularly but does not treat as the transactional system of record — content, catalogs, reference data. The defining rule: **any field from this system used in a security-relevant decision must be independently re-verified at the moment of use, never cached or trusted from an earlier read.**

### 4.2 The existing reference implementation: Sanity

| Aspect | Implementation |
|---|---|
| Client library | `next-sanity`, wrapping a shared, single `client` instance |
| Query language | GROQ, always parameterized (`$paramName`), never string-concatenated |
| Trust boundary discipline | Public and authenticated queries are **always separate definitions** (`docs/CODING_STYLE_GUIDE.md` §8.1); answer-key fields confined to exactly one server-only query |
| Configuration | `NEXT_PUBLIC_SANITY_PROJECT_ID`, `NEXT_PUBLIC_SANITY_DATASET`, `SANITY_API_TOKEN` |
| Cache strategy | Time-based revalidation (`next: { revalidate: 60 }`) for public reads; no caching for security-sensitive server-only queries |

### 4.3 Design checklist for a new Shape B integration

```text
1. Never build one shared query reused across trust contexts. Write
   a distinct query per context (public, authenticated,
   server-only-privileged), even if the shapes overlap significantly.

2. For any field capable of determining a graded/financial/access
   outcome, confirm explicitly: which queries include it, and are ALL
   but the designated privileged query excluding it via projection?
   This is not optional review — it is the exact discipline that
   prevented (and now permanently regression-tests against) the
   assessment-integrity vulnerability.

3. Never trust this system's own access-control model as GreyMatter's
   security boundary. Sanity's document permissions govern who can
   EDIT content; they say nothing about which FIELDS a given GreyMatter
   query is allowed to expose to which class of requester — that is
   entirely GreyMatter's own responsibility, enforced at the query
   projection layer.

4. Establish a bounded cache tolerance appropriate to how "live" this
   data genuinely needs to be, per docs/ARCHITECTURE.md §9's decision
   tree — do not default to either "always live" (wasteful) or
   "cached forever" (stale) without deliberately choosing.
```

### 4.4 Adding a new content query safely — a required pre-flight checklist

Before merging any new GROQ query, walk this checklist explicitly (this is `docs/ONBOARDING.md`'s Code Review Standards §2, restated here in integration-specific form):

- [ ] Does this query serve a public/unauthenticated context, an authenticated context, or a server-only privileged context? (Pick exactly one — never mixed.)
- [ ] If it touches `quizBlock` or `codeExerciseBlock`, does its projection explicitly exclude `correctOptionIndex`/`expectedKeywords` unless this is genuinely the one designated server-only grading query?
- [ ] Run `grep -rn "correctOptionIndex\|expectedKeywords" sanity/lib/queries.ts` after adding it — confirm the only match(es) are inside the existing, designated query.
- [ ] Does it accept any client-supplied identifier (a slug, an ID) that should be scoped through a parent relationship (course → lesson → module), rather than accepted in isolation?

---

## 5. Shape C: Inbound Webhook Consumer Integrations

### 5.1 When to use this shape

Use this shape whenever an external system needs to proactively notify GreyMatter that something happened on its side — an account lifecycle event, a payment confirmation, a third-party content-sync event. This is the highest-scrutiny integration shape in the system, because it accepts unsolicited, internet-reachable requests.

### 5.2 The mandatory four-step pattern

Every inbound webhook, without exception, follows this exact sequence — this is not a suggestion, it is the enforced pattern behind the existing Clerk integration and must be replicated identically for any new one:

```text
1. VERIFY the request's cryptographic signature, computed over the
   EXACT, unmodified raw request body — never over a re-serialized
   or partially-parsed version of it.

2. EXTRACT the provider's own unique delivery identifier (not
   something GreyMatter invents) from the verified request.

3. ATTEMPT to record that identifier against a database UNIQUE
   constraint BEFORE performing any associated business logic —
   if the recording fails (already exists), treat this as an
   already-processed duplicate and stop, returning success.

4. Only then, perform the actual business logic the webhook
   describes.
```

### 5.3 Reference implementation walkthrough: `POST /api/webhooks/clerk`

```ts
export async function POST(request: Request) {
  const secret = getWebhookSecret(); // fail loudly if misconfigured

  const headerPayload = await headers();
  const svixId = headerPayload.get("svix-id");
  const svixTimestamp = headerPayload.get("svix-timestamp");
  const svixSignature = headerPayload.get("svix-signature");

  if (!svixId || !svixTimestamp || !svixSignature) {
    return NextResponse.json({ error: "Missing required Svix headers" }, { status: 400 });
  }

  // STEP 1 — raw body, read BEFORE any parsing
  const rawBody = await request.text();
  const webhook = new Webhook(secret);

  let event: WebhookEvent;
  try {
    event = webhook.verify(rawBody, {
      "svix-id": svixId,
      "svix-timestamp": svixTimestamp,
      "svix-signature": svixSignature,
    }) as WebhookEvent;
  } catch (error) {
    return NextResponse.json({ error: "Invalid signature" }, { status: 400 });
  }

  // STEP 2 + 3 — record delivery ID before any processing
  const isNewEvent = await tryRecordWebhookEvent({
    source: "clerk",
    eventType: event.type,
    externalId: svixId,
    payload: event.data,
  });

  if (!isNewEvent) {
    return NextResponse.json({ received: true, duplicate: true });
  }

  // STEP 4 — business logic
  try {
    switch (event.type) {
      case "user.created": /* ... */ break;
      // ...
    }
    await markWebhookEventProcessed("clerk", svixId);
  } catch (error) {
    console.error(`Error processing webhook ${event.type}:`, error);
    // still return 200 — see rationale below
  }

  return NextResponse.json({ received: true });
}
```

### 5.4 Building a new inbound webhook integration

```text
1. Extend the webhook_events table's "source" values conceptually —
   the schema already supports multiple sources (docs/DATA_DICTIONARY.md
   §2.7); no schema change is needed to add a second source, only a
   new value for the existing "source" text field.

2. Create a new Route Handler at a dedicated path
   (e.g., app/api/webhooks/<provider>/route.ts) — never share a
   single endpoint across multiple providers' webhook formats.

3. Implement signature verification using the NEW provider's own
   scheme (every provider's scheme differs — Svix, HMAC-SHA256
   with a different header convention, etc.). Read the raw body
   FIRST, always, before any parsing, regardless of the specific
   scheme.

4. Implement the four-step pattern (5.2) exactly, reusing
   tryRecordWebhookEvent()/markWebhookEventProcessed() with a new
   "source" value.

5. Decide explicitly: on a processing failure AFTER successful
   signature verification, does this provider retry aggressively
   enough that swallowing the error (returning 200 anyway) is the
   right call, per the Clerk precedent — or does this new provider's
   retry behavior warrant propagating a 500 instead? This is a
   deliberate choice per integration, not a copy-paste default;
   document the reasoning in the new Route Handler's own comments.

6. Add the new endpoint to docs/API_REFERENCE.md Section 3 and
   Section 5, and to docs/DATA_DICTIONARY.md's webhook_events
   description if the payload shape introduces anything notable.

7. Write the Section 5.5 verification tests before considering the
   integration complete.
```

### 5.5 Required verification for any new webhook integration

Mirroring `docs/TEST_PLAN.md` §6.3's protocol exactly:

```text
1. Send a request with valid JSON but no/malformed signature headers.
   Expect rejection, no processing.
2. Send a request with a deliberately invalid signature. Expect
   rejection, no processing.
3. Send a genuinely valid, correctly signed request. Expect success
   and correct processing.
4. Resend the IDENTICAL valid request. Expect success response, but
   confirm via logs/database that processing was SKIPPED as a
   recognized duplicate.
```

---

## 6. Shape D: Outbound Service Call Integrations

### 6.1 When to use this shape

Use this shape when GreyMatter needs to call an external service to *perform* an action (send an email, check a rate limit, dispatch a background job) rather than receive data from it. The defining requirement: **every Shape D integration must have an explicit, documented behavior for when the service is unavailable or unconfigured** — silent, undocumented failure is never acceptable, but the *specific* graceful-degradation behavior is a deliberate per-integration decision.

### 6.2 The two existing patterns, and when to use each

**Pattern D1 — Fail-open with logging (Resend, email):**

```ts
export async function sendCourseCompletionEmail(input: CompletionEmailInput) {
  const client = getResendClient();

  if (!client) {
    // DEV FALLBACK: no RESEND_API_KEY configured. Log instead of
    // throwing, so the surrounding certificate-issuance pipeline
    // remains fully testable without a real email provider.
    console.log("─── (DEV) Would send completion email ───");
    console.log(html);
    return { sent: false, simulated: true };
  }

  await client.emails.send({ /* ... */ });
  return { sent: true, simulated: false };
}
```

Use this pattern when: the absence of the integration has **no security consequence**, only a UX/observability one, and local development would otherwise be blocked on a third-party signup.

**Pattern D2 — Fail-open with a documented security trade-off (Upstash, rate limiting):**

```ts
export async function checkRateLimit(identity: string): Promise<boolean> {
  const rl = getLimiter();
  if (!rl) return true; // No limiter configured — always allow.
  const { success } = await rl.limit(identity);
  return success;
}
```

Use this pattern **only** when the trade-off is explicitly documented as an accepted risk (`docs/ARCHITECTURE.md` §11, `docs/THREAT_MODEL.md` T-D-01) and paired with an operational monitoring control ensuring the fail-open state is never silently present in production (see the roadmap item in `docs/ROADMAP.md` §3.5 addressing exactly this).

**Never** apply Pattern D2 to anything with a genuine security consequence beyond rate limiting itself — e.g., never make an authorization check fail-open using this pattern. Section 6.3 makes this explicit.

### 6.3 Deciding between fail-open and fail-closed for a new Shape D integration

```text
Would the ABSENCE of this integration, if it silently failed, allow
an action to proceed that should have been blocked, or expose data
that should have been protected?
        │
       Yes ──► FAIL CLOSED. Block the action; return a generic error
        │       to the caller; log the misconfiguration loudly.
        No
        │
        ▼
Would blocking on this integration's unavailability meaningfully
degrade local development or non-critical functionality, with no
corresponding security cost?
        │
       Yes ──► FAIL OPEN with logging (Pattern D1), or fail open with
        │       an explicitly documented, monitored trade-off (Pattern D2)
        No
        │
        ▼
                FAIL CLOSED, as the safer default
```

### 6.4 The workflow engine as a special case of Shape D: Inngest

Inngest deserves separate treatment because, unlike Resend/Upstash, it is not "best-effort" in the same sense — it is the durability guarantee behind certificate issuance, progress recalculation, and reminders. Its integration pattern:

```text
1. Application code EMITS an event (inngest.send()) after a
   synchronous transaction commits — never before, never inside it
   (docs/CODING_STYLE_GUIDE.md §10.2).

2. Event emission itself is fire-and-forget from the CALLER'S
   perspective — a failure to emit does not roll back the already-
   committed synchronous work, since the synchronous write (e.g., the
   enrollment record) is the actually-important guarantee; the
   downstream workflow is a delayed CONSEQUENCE of it, not a
   co-requirement.

3. Reliability is achieved on the CONSUMING side (the Inngest
   function itself), via step-level retries, idempotency, and
   the observability/re-throw pattern (docs/CODING_STYLE_GUIDE.md
   §10.5) — not by the emitting code waiting for or verifying
   downstream success.
```

### 6.5 Building a new Shape D integration

```text
1. Create a dedicated client-access file (mirroring lib/email/client.ts
   or lib/rate-limit.ts) — one file, one function, returning null
   (or an equivalent "unavailable" signal) if required configuration
   is absent. Never scatter direct SDK instantiation across multiple
   call sites.

2. Decide fail-open vs. fail-closed using Section 6.3's decision tree,
   and document the decision inline, at the point of the check, the
   same way the existing rate-limiter and email client both do.

3. Add the new environment variable(s) to .env.example, following
   docs/CODING_STYLE_GUIDE.md §13.3.

4. Add the new integration to the infrastructure inventory table in
   docs/DEVSECOPS_ONBOARDING.md §1.1 and the failure-mode table in
   docs/DISASTER_RECOVERY.md §2.1, even if its RTO/RPO is "N/A —
   stateless" — every dependency should appear in both tables, with
   an explicit entry rather than a silent omission.

5. If the new integration introduces any new trust boundary (e.g., a
   payment provider — see docs/ROADMAP.md §4.1), it requires a new
   entry in docs/THREAT_MODEL.md before release, not after.
```

---

## 7. Adding a New Inngest-Consumed Event (Cutting Across Shapes)

This is a common integration task that doesn't map to exactly one of the four shapes above, since it's internal to GreyMatter's own architecture rather than a genuinely external system — documented here separately because it recurs often enough to warrant its own checklist.

```text
1. Add the event name and payload shape to inngest/events.ts's
   GreyMatterEvents type FIRST — this is the single source of truth
   every emitter and consumer is checked against at compile time.

2. Identify the emission point: the Server Action or webhook handler
   whose synchronous work, once committed, should trigger this event.
   Confirm the emission happens strictly AFTER that work's transaction
   commits (docs/CODING_STYLE_GUIDE.md §10.2).

3. Write the consuming function via inngest.createFunction(), applying:
   - Idempotency if the event could plausibly be duplicated or the
     function could be retried (docs/CODING_STYLE_GUIDE.md §10.3)
   - Concurrency limits if this is a scheduled/batch function where
     overlapping runs could cause duplicate real-world effects
   - The observability + re-throw pattern (docs/CODING_STYLE_GUIDE.md
     §10.5)

4. Register the new function in inngest/functions/index.ts.

5. Update docs/API_REFERENCE.md Section 6 (the event catalog table)
   and Appendix E if the function demonstrates a pattern not already
   documented there.

6. Verify locally: trigger the emitting action, confirm the new
   function appears and completes successfully in the Inngest local
   dashboard (http://localhost:8288), inspecting each step's output.
```

---

## 8. Integration Testing Requirements

Every integration, regardless of shape, must satisfy the applicable subset of these before being considered complete — cross-referencing `docs/TEST_PLAN.md`:

| Requirement | Applies to shape(s) |
|---|---|
| Unit test covering the client-access function's fail-open/fail-closed branch | C, D |
| Signature/idempotency verification test (Section 5.5's four-step protocol) | C |
| A manual or automated confirmation that no security-relevant field crosses from this integration into a client-facing response without the appropriate projection/exclusion | B |
| A concurrency test if the integration touches any "at most one" business rule | B, C, D (Inngest specifically) |
| An entry in `docs/DISASTER_RECOVERY.md` §2.1's RTO/RPO table | All |
| An entry in `docs/DEVSECOPS_ONBOARDING.md` §1.1's infrastructure inventory | All |

---

## 9. Common Integration Mistakes

| Mistake | Consequence | Correct approach |
|---|---|---|
| Parsing a webhook body (`request.json()`) before verifying its signature | Signature verification fails for every legitimate request, since the bytes no longer match | Always call `request.text()` first; verify against the raw string; parse only after verification succeeds |
| Sharing one GROQ query across a public and an authenticated context | Risks either over-fetching sensitive fields for the public context, or under-fetching for the authenticated one | Always write separate query definitions per trust context, even with duplication |
| Applying a fail-open pattern to an authorization-relevant check | Silently disables a security control under a configuration gap | Fail-open is only acceptable for genuinely non-security-relevant degradation (Section 6.3) |
| Emitting an Inngest event from inside a database transaction | Describes something that may never have actually happened if the transaction rolls back | Always emit strictly after the transaction commits |
| Treating a new external system's own access-control model as sufficient | Confuses "who can edit this in the vendor's UI" with "what data GreyMatter is allowed to expose to a given requester" | GreyMatter's own query/response layer is always the actual security boundary, regardless of vendor-side permissions |
| Reusing a development credential in production, or vice versa, "just to get started" | Violates the environment-separation requirement across every existing integration | Provision distinct credentials per environment from the very first setup step, never as a "temporary" shortcut |
