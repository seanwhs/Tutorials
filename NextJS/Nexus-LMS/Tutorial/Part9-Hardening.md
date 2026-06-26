# PART 9 — Production Security & Multi-Tenant Hardening

# Tutorial 09: Securing Nexus LMS for Real-World Deployment

---

# Introduction

At this stage, Nexus LMS is already capable of:

* event-driven orchestration
* AI worker execution
* multi-tenant data modeling
* plug-in registry expansion
* adaptive learning pipelines

Now we address the part most systems get wrong:

> Security is not a layer you add. It is the foundation you enforce.

In a multi-tenant AI-native LMS, security failures are not bugs—they are data leaks across institutions.

---

# Learning Objectives

By the end of this tutorial, you will understand:

* How to enforce strict multi-tenant isolation
* How Supabase Row Level Security (RLS) protects data boundaries
* How to secure AI worker execution
* How to prevent cross-organization data leakage
* How to authenticate events, workflows, and workers
* How to design production-grade trust boundaries

---

# 1. Security Model Overview

Nexus LMS has 4 trust zones:

```text id="s1"
1. Client (Next.js UI)
2. Backend (Server Actions / API)
3. Orchestration Layer (Inngest)
4. External Workers (AI services)
```

Each zone has **different trust levels**.

---

## Trust Hierarchy

```text id="s2"
Lowest Trust → Client
Medium Trust → Backend
High Trust → Orchestrator
Isolated Trust → Workers
```

---

# 2. Multi-Tenant Isolation Principle

Every piece of data belongs to:

```text id="s3"
organization_id
```

No exceptions.

---

## Threat if ignored

Without strict isolation:

* Student A sees Student B data
* Teacher A accesses Teacher B courses
* AI workers leak cross-school insights

This is unacceptable in production LMS systems.

---

# 3. Supabase RLS Hardening

We use Supabase as the enforcement layer.

---

## 3.1 Global RLS Rule Pattern

Every table must enforce:

```sql id="r1"
organization_id = auth.jwt() ->> 'org_id'
```

---

## 3.2 Courses Policy

```sql id="r2"
create policy "courses isolation"
on courses
for select
using (
  organization_id = auth.jwt() ->> 'org_id'
);
```

---

## 3.3 Submissions Policy

```sql id="r3"
create policy "student owns submissions"
on submissions
for select
using (
  student_id = auth.uid()
  AND organization_id = auth.jwt() ->> 'org_id'
);
```

---

## 3.4 Worker Results Policy

```sql id="r4"
create policy "org scoped worker results"
on worker_results
for select
using (
  organization_id = auth.jwt() ->> 'org_id'
);
```

---

# 4. Event Security Model

Events are a major attack surface.

---

## Problem

```text id="e1"
Client → Event → Inngest → Workers
```

If unprotected:

* fake events can be injected
* malicious users can trigger AI execution
* cross-org manipulation becomes possible

---

## Solution: Signed Events

Each event is signed:

```typescript id="e2"
await inngest.send({
  name: "assignment.submitted",
  data,
  user: {
    id: user.id,
    orgId: user.orgId
  }
});
```

---

## Verification in workflow

```typescript id="e3"
if (event.user.orgId !== event.data.organizationId) {
  throw new Error("Org mismatch");
}
```

---

# 5. Worker Security Model

Workers are external systems → highest risk zone.

---

## 5.1 HMAC Signature Verification

Every request includes:

```text id="w1"
X-Nexus-Signature: sha256=...
```

---

## Worker validation

```typescript id="w2"
function verify(payload, signature, secret) {
  return hmac(secret, payload) === signature;
}
```

---

## Prevents:

* spoofed LMS requests
* unauthorized execution
* fake grading injections

---

# 6. Worker Isolation Strategy

Workers must NEVER:

* access database directly
* call other workers
* bypass registry

They only:

> receive input → return output

---

## Safe execution model

```text id="w3"
LMS → Worker (HTTP) → LMS
```

No backchannel access.

---

# 7. Data Leakage Prevention

AI workers are the biggest risk vector.

---

## Rule 1: Minimal payload principle

Workers receive only:

```json id="d1"
{
  "submissionId": "123",
  "content": "..."
}
```

NOT:

* full student profile
* cross-org data
* unrelated submissions

---

## Rule 2: Scoped queries only

Workers cannot query Supabase directly.

They must operate on provided context.

---

# 8. Orchestrator Security (Inngest Layer)

Powered by Inngest

---

## Inngest trust rules:

* only accepts validated events
* enforces retry limits
* isolates workflow execution
* prevents duplicate execution

---

## Idempotency protection

```typescript id="i1"
if (event.id already processed) return;
```

---

# 9. API Security Layer

All server actions must enforce:

---

## Authentication check

```typescript id="a1"
const user = await clerkClient.users.getUser(userId);

if (!user) throw new Error("Unauthorized");
```

---

## Organization validation

```typescript id="a2"
if (user.orgId !== input.orgId) {
  throw new Error("Forbidden");
}
```

---

# 10. Threat Model Summary

We explicitly defend against:

---

## 10.1 Cross-tenant data leaks

Mitigated by:

* RLS
* org_id enforcement

---

## 10.2 Fake event injection

Mitigated by:

* signed events
* server-side validation

---

## 10.3 Malicious worker execution

Mitigated by:

* HMAC signing
* endpoint registry validation

---

## 10.4 Data exfiltration via AI workers

Mitigated by:

* minimal payload design
* no DB access from workers

---

# 11. Defense-in-Depth Architecture

```text id="d2"
Client Layer (untrusted)
      ↓
Server Actions (validated)
      ↓
Supabase (RLS enforced)
      ↓
Inngest (controlled execution)
      ↓
Registry (sanitized worker discovery)
      ↓
Workers (isolated execution)
```

---

# 12. Why This Architecture Works

## 12.1 No single trust boundary

Every layer validates input.

---

## 12.2 AI cannot escape sandbox

Workers are isolated execution units.

---

## 12.3 Data is always scoped

Everything is organization-bound.

---

## 12.4 Events are controlled entry points

No direct system mutation allowed.

---

## 12.5 System is audit-ready

Every action is traceable:

* event logs
* worker results
* DB changes

---

# 13. Key Architectural Principle

> Security is not a feature of the LMS.
>
> It is the constraint that defines the LMS.

---

# Summary

In this tutorial, we hardened Nexus LMS for production:

* multi-tenant RLS enforcement
* event signing and validation
* worker isolation model
* HMAC-secured execution
* minimal payload AI safety
* orchestration security boundaries
* API authentication rules
* full threat model design

We now have a **production-grade secure AI LMS platform**.

---

# Next Tutorial

## Tutorial 10 — Observability, Logging, and AI System Debugging

We will now design:

* event tracing system
* AI worker observability pipeline
* debugging failed workflows
* distributed logs architecture
* performance monitoring for AI systems
* cost tracking per worker
* learning analytics instrumentation
