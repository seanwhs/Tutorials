# Enterprise-Grade Patterns for Next.js 16

A code-heavy series on architecting production Next.js 16 apps using the Server-First paradigm. Core series is 4 parts; Parts 5-8 are bonus add-ons. Every part follows the same structure: **Anti-Pattern → Next.js 16 Pattern → Type-Safe Implementation → Architect's Note**.

Stack assumptions: Next.js 16 (App Router, Turbopack default), React 19, TypeScript strict mode, Node 20.9+/22 LTS. All dynamic APIs (`params`, `searchParams`, `cookies()`, `headers()`) are async and must be awaited.

## Parts (each has a main note + a Code Appendix note with full literal snippets)

1. **Part 1: The Data Layer (Repository Pattern)** — killing `useEffect` fetching, Repository Pattern, `fetch` caching, `revalidateTag`/`revalidatePath`, `cache()` dedupe, `unstable_cache`. *(Code is inline in the main note; no separate appendix needed.)*
2. **Part 2: Orchestration and State** — URL search params as state, Server Action composition, `useOptimistic` vs local state.
   → **Part 2 Code Appendix**
3. **Part 3: Component Composition** — killing prop drilling, Slot Pattern, Compound Components, keeping Server Components server-rendered inside Client shells.
   → **Part 3 Code Appendix**
4. **Part 4: Resilient Infrastructure and Deployment** — nested `error.tsx`, manual error boundaries, granular Suspense/loading UI, Facade Pattern for SDKs, and a full **Deploying to Vercel** section on Full Route Cache / Data Cache / on-demand revalidation / streaming / cold starts.
   → **Part 4 Code Appendix**
5. **Part 5: Testing Strategy (Bonus)** — testing pyramid mapped to the architecture: unit-test repositories/Server Actions/facades with Vitest (fakes implementing the same interfaces), integration-test async Server Components and Suspense/error boundaries with React Testing Library, reserve Playwright E2E for full browser flows (URL state persistence, optimistic UI, Vercel cache behavior).
   → **Part 5 Code Appendix**
6. **Part 6: Observability and Structured Logging (Bonus)** — killing scattered `console.log`, a typed `Logger` facade emitting structured JSON, per-request correlation IDs via `cache()` tying client-visible `error.digest` to server logs, a `withLogging` higher-order wrapper for Server Actions, and layer-by-layer guidance on what to log (repositories, actions, facades, error boundaries) plus sampling/cost/Edge Runtime trade-offs.
   → **Part 6 Code Appendix**
7. **Part 7: Auth and Authorization Patterns (Bonus)** — killing client-trusted permission checks and copy-pasted authz logic, a request-scoped `getCurrentUser()`/`requireUser()` session facade via `cache()`, composable/testable policy functions (`canArchiveProject`, `canManageBilling`) returning a typed `AuthzResult` union, defense-in-depth (coarse `middleware.ts` session checks + fine-grained per-resource policy checks inside Server Actions), and multi-tenancy done safely (`orgId` always sourced from the verified session, never from client input).
   → **Part 7 Code Appendix**
8. **Part 8: Internationalization and Accessibility Patterns (Bonus)** — killing hardcoded strings and a11y-as-afterthought, server-resolved typed translations with zero client fetch waterfall via a `[locale]` dynamic segment + `cache()`-memoized `getMessages()`, locale-aware `middleware.ts` redirect, and rebuilding Part 3's `Tabs` compound component with real accessibility (roving `tabIndex`, arrow/Home/End keyboard navigation, `aria-controls`/`aria-labelledby` pairing) plus explicit focus management after client-side navigations and Suspense-streamed content.
   → **Part 8 Code Appendix** (i18n: types, JSON messages, `get-translations.ts`, locale layout/page, locale middleware, `LocaleLink`)
   → **Part 8 Code Appendix (Accessibility)** (accessible `Tabs` rebuild, focus-managing `FilterBar`, anti-pattern contrast)

## Reading order

Read in order 1 → 4 for the core architecture series. Part 2 assumes the repositories from Part 1 exist. Part 3 assumes the mutation actions from Part 2 exist. Part 4 wraps everything with resilience and ships it to Vercel. Parts 5-8 are bonus material that can be read any time after Part 4 — Part 5 proves the architecture is correct (tests), Part 6 makes it diagnosable in production (logging/observability), Part 7 makes sure only the right people can touch it (auth/authz), Part 8 makes sure it actually works for everyone, in whatever language and however they navigate (i18n/a11y).

## Continuous narrative thread

All parts build one running example: a "Projects Dashboard." Part 1 builds `projectRepository`. Part 2 adds `archiveProject`/`archiveAndNotify` Server Actions plus a URL-filtered list view. Part 3 restructures the list/detail UI with `InteractiveCard` and a `Tabs` compound component. Part 4 wraps it all in error boundaries, splits loading UI per-section, and adds a `paymentsFacade` example for external SDK integration, then explains Vercel deployment implications. Part 5 adds a full test suite (unit, integration, E2E) across every layer built in Parts 1-4. Part 6 adds a structured `logger` facade and `requestId` correlation, wired into the same repositories, actions, facades, and error boundaries from Parts 1-4. Part 7 adds `getCurrentUser()`/policy functions and rewires `archiveProject` (Part 2) and `projectRepository` (Part 1) to require a verified session and org-scoped tenant isolation. Part 8 moves the dashboard under a `[locale]` route segment with server-resolved translations, and rebuilds Part 3's `Tabs` component with real keyboard/ARIA support plus explicit focus management on Part 2's `FilterBar`.
