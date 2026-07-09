# Part 4: Resilient Infrastructure and Deployment

Goal: make the app degrade gracefully. Custom Error Boundaries, granular Loading UI, a Facade Pattern for external SDKs, and how all of this interacts with Vercel's caching layers when deployed.

*(Full literal code lives in "EntNext16 - Part 4 Code Appendix" — ask for it directly if you want it.)*

---

## 1. The Anti-Pattern (Next.js 13/14-style, brittle infra)

Old approach: one top-level try/catch (or no error handling at all) around a big page component that calls a third-party SDK directly (e.g., a payments SDK, a CMS client) inline wherever it's needed, with a single global `loading.tsx` (or a single full-page spinner) covering the entire route regardless of which part of the page is actually slow.

Problems this causes:
- One unhandled error anywhere in the tree crashes the entire route to a blank white screen or the generic Next.js error overlay — a failure in a non-critical widget (e.g., a "related items" sidebar) takes down the whole page, including content that had nothing to do with the failure.
- A single route-level `loading.tsx` blocks the *entire* page behind the slowest data dependency, even if 90% of the page (header, nav, static content) was ready instantly — no granular streaming.
- The third-party SDK is imported and called directly from many components across the codebase. When the SDK's API changes, or you need to swap providers, or you need to mock it for tests, you're editing dozens of call sites instead of one.

---

## 2. The Next.js 16 Pattern

### 2a. Custom Error Boundaries (nested `error.tsx`)

Next.js's file-convention `error.tsx` creates an error boundary automatically scoped to its route segment. Nest them deliberately: a broad `app/error.tsx` as the last-resort catch-all, and narrower `error.tsx` files inside specific route segments (e.g., `app/dashboard/projects/[id]/error.tsx`) so a failure in one segment doesn't take down parent layouts (nav, sidebar) that rendered successfully. For a failure isolated to a single widget rather than a whole route segment, wrap just that widget in a manually-created React error boundary component (React itself has no built-in one; you write a small class component once and reuse it) instead of relying on route-level `error.tsx`.

### 2b. Granular Loading UI

Rather than one `loading.tsx` per route gating the entire page, push `<Suspense>` boundaries down to wrap only the specific slow data-dependent components, each with its own small fallback (a skeleton matching that component's shape). The route's static shell (header, nav, layout chrome) renders and streams immediately; each Suspense-wrapped section resolves and streams in independently as its own `await` finishes, so a slow "recent activity" widget doesn't block a fast "project stats" widget from appearing.

### 2c. Facade Pattern for external SDKs

Wrap every third-party SDK/API behind a single internal module with your own interface, mirroring the Repository Pattern from Part 1 but for external *services* rather than your own data. All application code imports your facade (e.g., `lib/facades/payments.ts`), never the raw SDK. This centralizes error normalization (SDK-specific error shapes get translated into your own `ActionResult`-style types), makes provider swaps a one-file change, and gives you one place to add retries/timeouts/logging.

---

## 3. Type-Safe Implementation

- `error.tsx` components are typed with Next.js's implicit props: `{ error: Error & { digest?: string }; reset: () => void }` — always destructure `digest` since it's what you correlate against server logs, and never render `error.message` directly to end users in production (log `digest` server-side, show a generic message client-side).
- Manual (non-route) error boundaries are typed class components implementing `componentDidCatch(error: Error, info: ErrorInfo)`, with a strictly typed `Props { children: ReactNode; fallback: ReactNode }` and `State { hasError: boolean }`.
- Facade modules define an interface per external capability (e.g., `PaymentsFacade { createCharge(input: ChargeInput): Promise<FacadeResult<Charge>> }`) so application code depends on your own domain types, never the SDK's generated types directly — this is what makes swapping providers a contained change.
- `FacadeResult<T>` mirrors `ActionResult<T>` from Part 2: a discriminated union, never a thrown raw SDK error crossing into application code un-normalized.

---

## 4. Architect's Note

**Trade-off — error boundary granularity vs complexity:** more `error.tsx`/manual boundaries means more resilience (isolated failures) but more files and more fallback UI to design/maintain. Rule of thumb: put a boundary at every route segment that has its own independent data dependency, and add manual widget-level boundaries only around genuinely optional/non-critical content (third-party embeds, recommendation widgets) where "just hide this section on failure" is an acceptable UX outcome.

**Trade-off — Suspense granularity vs waterfalls:** splitting one page into many independent Suspense boundaries lets independent-but-slow data sources stream in parallel instead of blocking each other — but if those data sources actually depend on each other (B needs A's result), over-splitting creates a visible sequential waterfall of skeletons resolving one after another instead of one clean load. Only split Suspense boundaries along genuinely independent data dependencies.

**Trade-off — Facade Pattern overhead vs vendor lock-in:** for a single-provider app you'll likely never swap, a full facade layer can feel like an unnecessary indirection. It earns its cost the moment the SDK has flaky error shapes worth normalizing, you need to mock it in tests without hitting a real API, or there's realistic chance of a provider swap (payments, email, auth) — which for enterprise-grade software is the common case, not the exception.

### Deploying to Vercel — how these patterns interact with Vercel's caching layers

- **Full Route Cache**: static/no-dynamic-API routes (no uncached `fetch`, no `cookies()`/`headers()` calls, no `searchParams` usage) get fully pre-rendered at build/deploy and served from Vercel's Edge Network with zero server execution per request. Part 2's URL-search-params pattern means any route reading `searchParams` opts out of full static rendering for that route by design — this is the correct trade-off since that page's content is a function of the URL query string, but be aware it costs you the Full Route Cache tier and moves that route into on-demand server rendering (still fast, just not "free" static).
- **Data Cache**: Part 1's `fetch(..., { next: { revalidate, tags } })` calls are stored in Vercel's persistent Data Cache, shared across all deployments and regions (not just in-memory per-instance) — this is what makes `revalidateTag` from a Server Action (Part 2) immediately reflect for every user globally, not just the user who triggered the mutation.
- **On-demand revalidation cost model**: every `revalidateTag`/`revalidatePath` call is effectively free and instant on Vercel's infra (no redeploy needed), which is why tag-based invalidation (Part 1 + Part 2) is preferred over short time-based `revalidate` windows in a serverless/edge deployment — you get both long cache lifetimes *and* instant freshness on mutation, rather than picking one.
- **Streaming + Suspense (Part 4 2b)**: Vercel's Edge Network supports HTTP streaming natively, so granular Suspense boundaries genuinely improve Time-To-First-Byte-perceived-content in production, not just in local dev — the static shell reaches the browser immediately while slow segments stream in over the same connection.
- **Facade Pattern + serverless cold starts**: keep facade modules lean (lazy-init SDK clients inside the function rather than heavy work at module scope) since each serverless/edge function invocation may cold-start; a facade is also the natural place to add a timeout wrapper (e.g., `Promise.race` against an `AbortController`) so one slow third-party API can't exhaust a Vercel function's execution time limit and take an otherwise-healthy request down with it.

---

This closes the series: Part 1's repositories feed Part 2's URL-driven pages and Server Actions, Part 3 composes the UI without prop drilling or unnecessary client bundle cost, and Part 4 wraps the whole thing in error/loading resilience and ships it to Vercel with a caching model that's fast by default and precisely invalidatable on demand.
