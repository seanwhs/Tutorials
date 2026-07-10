# Secure by Design — Part 2: Identity & Access Orchestration

## 1. Concept & Architecture Rationale

### Beyond "logins": identity as a system boundary

Authentication answers "who are you." Authorization answers "what can you do." Most breaches involving Elevation of Privilege happen not because authentication was broken, but because authorization was checked in the wrong place — usually the client, or only at the edge, never re-verified deeper in the call stack.

Principal Architect rule: **every layer that can independently receive a request must independently verify authorization.** Trusting a role passed up from a layer "closer to the user" (a client component, a gateway that "already checked") is a Confused Deputy vulnerability waiting to happen.

### RBAC design axes

When designing RBAC, decide explicitly on:

- **Grain**: Coarse (Admin/Member/Viewer) vs fine-grained (permission strings like invoices:write, reports:read).
- **Scope**: Global role vs per-tenant/per-organization role (critical in multi-tenant SaaS — a user can be Admin in Org A and Viewer in Org B).
- **Source of truth**: Roles should live in the identity provider (Clerk, Auth0, or your own users/memberships table) — never solely in a client-side JWT claim you don't re-verify.
- **Propagation**: How does role travel from IdP -> server session -> business logic -> database row-level policy?

### Short-lived tokens as a blast-radius control

Long-lived access tokens are a liability: if leaked (log file, browser extension, XSS), they remain valid for their full lifetime. Short-lived tokens (5-15 minutes) paired with refresh tokens (rotated, detectable-reuse) shrink the exploitation window dramatically. This is a direct, quantifiable Availability/Confidentiality trade in your threat model: shorter token life = smaller blast radius but more refresh traffic.

### Securing API boundaries

Every API boundary (Next.js Route Handler, Server Action, tRPC procedure) is a trust boundary per your Part 1 DFD. The pattern to enforce: authenticate -> authorize -> validate input -> act -> audit. Skipping any step is a gap.

## 2. Implementation

### Step 1 — Centralize role verification in one guard function

Using Clerk (free tier) as the identity provider with Next.js 16 Server Actions, build one reusable, server-only guard that every protected action calls. This is the concrete answer to the Part 1 threat model finding.

File: `src/lib/auth/require-role.ts`

```ts
export type Role = "org:admin" | "org:member" | "org:viewer";

export async function requireRole(allowed: Role[]) {
  const authObj = await auth(); // Clerk's async auth() — Next.js 16 dynamic APIs are async
  if (!authObj.userId) {
    throw new UnauthorizedError("Not authenticated");
  }
  const role = authObj.orgRole as Role | undefined;
  if (!role || !allowed.includes(role)) {
    throw new ForbiddenError("Insufficient role: " + String(role));
  }
  return { userId: authObj.userId, orgId: authObj.orgId, role };
}
```

Usage inside a Server Action:

```ts
export async function deleteInvoice(invoiceId: string) {
  const { orgId } = await requireRole(["org:admin"]);
  // orgId scoping below prevents cross-tenant access even if invoiceId is guessed
  await db.delete(invoices).where(and(eq(invoices.id, invoiceId), eq(invoices.orgId, orgId)));
}
```

Key point for students: notice the double control — role check AND tenant-scoped `WHERE` clause. Role check alone is not Data Isolation; you must also filter by `orgId` on every query. This prevents IDOR (Insecure Direct Object Reference) even for a correctly-authorized Admin acting outside their own org.

### Step 2 — Fine-grained permissions table for scale

Once role count grows, move from hardcoded role arrays to a permissions table pattern:

Permission matrix (conceptually, stored as a Postgres table `role_permissions(role, permission)`):

- `org:admin` -> invoices:write, invoices:read, reports:read, members:write
- `org:member` -> invoices:write, invoices:read, reports:read
- `org:viewer` -> invoices:read, reports:read

Guard becomes `requirePermission("invoices:write")` which resolves the caller's role, looks up permissions, and checks membership — decoupling "what a role can do" (data, easily audited/changed) from "how we check it" (code, stable).

### Step 3 — Short-lived tokens for service-to-service calls

For machine-to-machine calls (e.g., your app calling an internal reporting microservice), do not reuse user session cookies. Issue short-lived JWTs signed with a rotating key:

- Access token TTL: 5-10 minutes
- Refresh token TTL: 7-30 days, single-use, rotated on every refresh, and revoked entirely if reuse of an old refresh token is detected (a strong signal of token theft)
- Signing algorithm: prefer asymmetric (RS256/ES256) over symmetric (HS256) between services, so the verifying service never holds a secret capable of minting new tokens.

### Step 4 — Enforce authorization at the database layer too (defense-in-depth)

Even with application-layer checks, add Postgres Row-Level Security (RLS) as a second, independent layer, so a bug in application logic cannot leak cross-tenant data:

```sql
CREATE POLICY org_isolation ON invoices
  USING (org_id = current_setting('app.current_org_id')::text);
```

Your connection pooling layer sets `app.current_org_id` per request/transaction from the verified session — meaning even a raw SQL injection or an application logic bug cannot return another tenant's rows, because the database itself refuses.

### Step 5 — Audit every authorization decision

Structured audit log entry on every `requireRole`/`requirePermission` call, success or failure:

```json
{
  "event": "authz_check",
  "userId": "user_123",
  "orgId": "org_456",
  "permission": "invoices:write",
  "result": "denied",
  "reason": "role org:viewer lacks invoices:write",
  "timestamp": "2026-01-15T10:22:00Z",
  "requestId": "req_abc"
}
```

This directly answers the Repudiation threat from Part 1 and feeds Part 7's centralized logging/alerting design (a spike in "denied" authz events is a strong signal of an active privilege-escalation attempt).

## 3. Exercise Challenge

1. Implement `requireRole` (or `requirePermission`) as a single reusable server-only function and wire it into at least 3 Server Actions or Route Handlers of a real project.
2. Add tenant-scoping (`orgId`/`tenantId` `WHERE` clause) to every query inside those actions — treat missing tenant scoping as a bug even when the role check alone would technically be correct.
3. Add one Postgres RLS policy on your most sensitive table as a second independent layer.
4. Emit a structured authz audit log line for both allow and deny outcomes.

## 4. Solution & Explanation

The worked solution mirrors Step 1-5 above applied to the QB Clone's invoices table: `requireRole(["org:admin"])` guards `deleteInvoice`, tenant scoping via `eq(invoices.orgId, orgId)` prevents IDOR, an RLS policy on invoices provides a database-level backstop, and every call emits an `authz_check` audit event consumed later by Part 7's alerting pipeline.

Why layering matters architecturally: if the application-layer `requireRole` check is ever bypassed (a future refactor forgets to call it, or a new code path is added without review), the RLS policy alone still prevents cross-tenant data leakage. This is Defense-in-Depth in its purest form — no single control is a single point of failure for Confidentiality.

## 5. Key Takeaways

- Authorization must be re-verified at every layer that can independently receive a request — never trust a role claim propagated from "closer to the user."
- Role checks and tenant-scoped queries are two separate controls; both are required to prevent IDOR in multi-tenant systems.
- Short-lived, rotated tokens shrink the blast radius of credential leakage; refresh-token-reuse detection turns theft into an early warning signal.
- Database-level RLS is a free, powerful second layer that survives application-layer bugs.
- Every authorization decision — allow or deny — should be an audit event, not silence.

Next: Part 3 — Secure Coding & Taint Analysis, where we wire Semgrep (SAST) and OWASP Dependency-Track (SCA) into CI so vulnerable patterns and vulnerable dependencies are caught before merge.
