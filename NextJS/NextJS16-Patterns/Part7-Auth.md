
## Part 7: Auth and Authorization Patterns 

**Anti-Pattern:** Client-side-only role checks (hiding a button ≠ security), copy-pasted authz logic drifting across call sites, ad-hoc session lookups everywhere with no single source of truth.

**Next.js 16 Pattern:**
- **Session facade** — `getCurrentUser()`/`requireUser()`, memoized per-request via `cache()` (same technique as Parts 1 & 6), wraps whatever real provider you use (Clerk, Auth.js, custom JWT).
- **Composable policy functions** — `canArchiveProject(user, project)`, `canManageBilling(user, org)` — pure, named, unit-testable, returning a typed `AuthzResult` instead of a bare boolean.
- **Defense in depth** — coarse `middleware.ts` checks ("is there a session") + fine-grained per-resource policy checks inside Server Actions/repositories (explicitly warns: middleware alone is a common real-world security gap since it can't see the specific resource id).
- **Safe multi-tenancy** — `orgId` always derived from the verified session, never trusted from client-supplied request data.

**Type-Safe Implementation:** strict `AuthUser` interface, `AuthzResult` discriminated union (mirrors `ActionResult`/`FacadeResult` from Parts 2/4), `requireUser()` narrows `AuthUser | null` → `AuthUser`, repository methods require `orgId` as a mandatory typed param.

**Architect's Note:** session-cache-per-request trade-offs, hand-written policies vs a full RBAC library, middleware vs action-level checks, tenant-id-from-session vs from-request.

**Code Appendix** rewires the running example: `archiveProject` (Part 2) and `projectRepository` (Part 1) now require session + policy checks, plus a `middleware.ts` example and a Vitest unit test for `canArchiveProject` (ties directly into Part 5's testing pyramid).
