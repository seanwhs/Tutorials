# Appendix E — Threat Model & Security Reference

This appendix consolidates the security and hardening material actually built across the Greymatter LMS series into a single reference.

---

## E.1 Tenant Isolation Without Row-Level Security

Since Neon Postgres doesn't provide Supabase's Row-Level Security, every query touching `courses`, `enrollments`, or `submissions` must manually filter by `orgId`, matched against the signed-in user's Clerk organization [6]. This pattern — re-checking `auth()` and filtering by `orgId` inside every query — is described as "the single most important habit to build" [6].

This defense is reinforced explicitly in Part 9's threat model, which lists "cross-tenant data leakage" as a named threat whose defense is "manual `orgId` checks in every query (Part 4), now reinforced inside Inngest steps" [1][6].

**✅ Checkpoint (Part 4):** Temporarily hardcode a different `orgId` in a test query and confirm it returns zero rows for your test account's courses — proving the filter is actually doing something, not just decorative [6].

**✅ Checkpoint (Part 9):** Using two separate Clerk test accounts in two different organizations, confirm that Org A's user attempting to submit against Org B's `courseId` receives a "Rejected" error, rather than a successful submission [1].

---

## E.2 Rejecting Malformed Chained Events

Part 8 introduced event chaining, where one function's output can trigger a second function via an internal event like `student.struggling` [2]. Part 9 hardens this by rejecting malformed events before they can trigger a real action — for example, a `student.struggling` event missing `submissionId` [1].

**✅ Checkpoint:** Manually craft and send a `student.struggling` event missing `submissionId` (using the Inngest dashboard's manual event trigger, or a quick script). Confirm the function run fails immediately with a "Rejected" error, rather than proceeding to run a tutor intervention [1].

---

## E.3 Rejecting Forged Worker Signatures

Every worker request and response is signed and verified using a shared secret (`WORKER_SIGNING_SECRET`) [3][9]. Part 9 explicitly tests the failure path of this mechanism using a forged signature value:

```typescript
const forgedSignature = "0000000000000000000000000000000000000000000000000000000000000000";
```
[1]

This confirms the verification step actually rejects a tampered or forged signature, rather than only being exercised on the "happy path" where signatures always match.

---

## E.4 Worker Discovery via the Registry

The registry (Sanity) is the only place that knows which workers exist and what events they subscribe to [12]. Every worker is registered as a document with `name`, `events`, `endpoint`, and `enabled` fields [4]. Because Inngest queries this registry live rather than relying on a hardcoded worker list, disabling a worker is a content edit, not a code change — proven directly in Part 6's checkpoint of toggling `enabled` and confirming the worker disappears from `findWorkers()` results [4].

---

## E.5 The Worker Contract as a Safety Boundary

Every worker — grading, quizzes, tutoring, or analytics — must accept the same input shape and return the same output shape, defined once in `packages/workers` [3]. This shared contract exists because the Execution Layer is meant to be independently deployable in any language, anywhere, and that only works safely if Inngest's `execute-workers` step has a reliable way to call a worker and trust its response [3][12].

---

## E.6 Traceability for Debugging and Auditing

Part 10 builds a `workflow_logs` mechanism so that every step of a submission's journey — including failures — can be reconstructed with a single query instead of hunting across systems [11]. A debug timeline page renders this, marking failed steps clearly in red [11]:

```tsx
{events.map((e) => (
  <li key={e.id} className={e.status === "failed" ? "text-red-600" : "text-slate-700"}>
    {e.functionName} → {e.stepName} — {e.status}
  </li>
))}
```
[11]

**✅ Checkpoint:** Visit `/debug/<your-trace-id>` for a submission you triggered. Confirm you see a readable, ordered list of every step that ran — including a failed worker call, marked clearly in red [11].

A `costEstimate` field is also included in every logged step's detail, defaulting to `0` until Part 11 wires up real OpenAI calls — the pipeline is built and ready before real costs exist [11][10].

---

## E.7 Signature Header Inconsistency (Known Discrepancy)

Worth flagging directly for anyone auditing the code: the Grading and Quiz Workers verify signatures using an `x-signature` header [3][2], while the Summary Worker built in Part 11 uses a different header, `x-greymatter-signature` [10]. This is an inconsistency in the actual worker implementations across the series, not a deliberate security upgrade — worth reconciling to one consistent header name in a real deployment.

---

## E.8 Production Secrets Audit

Part 12's deployment step doubles as a security checklist — every secret introduced across the series must be present in the right place in production, cross-referenced against the part that introduced it [9]:

| Variable / Account | First introduced | Where it lives in production |
|---|---|---|
| Clerk publishable/secret keys | Part 3 | Vercel env vars (production instance) [9] |
| `DATABASE_URL` | Part 4 | Vercel env vars → Neon production branch [9] |
| `INNGEST_EVENT_KEY` / `INNGEST_SIGNING_KEY` | Part 5, hardened Part 9 | Vercel env vars → Inngest Cloud [9][1] |
| Sanity `projectId` / `dataset` | Part 6 | Deployed Studio + Vercel env vars [9] |
| `WORKER_SIGNING_SECRET` | Part 7 | Vercel + every deployed worker's own env vars [9][3] |
| `OPENAI_API_KEY` | Part 11 | Each worker's own env vars — never in `apps/web` [9] |

---

## E.9 Known, Honestly-Flagged Gaps

The series is explicit that Part 9's hardening pass is about reinforcing gaps flagged earlier — worker auth (Part 5) and tenant/chain checks (Part 8) — not an exhaustive production security audit. I don't have source content in this context confirming further specifics (such as secret-rotation cadence or rate-limiting thresholds for `/api/inngest`) beyond what's captured above — if you need those specifics, they would need to be defined as an extension on top of what's actually documented here.
