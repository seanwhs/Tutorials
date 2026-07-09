# Enterprise-Grade Patterns for Next.js 16

A 4-part, code-heavy series on architecting production Next.js 16 apps using the Server-First paradigm. Every part follows the same structure: **Anti-Pattern → Next.js 16 Pattern → Type-Safe Implementation → Architect's Note**.

Stack assumptions: Next.js 16 (App Router, Turbopack default), React 19, TypeScript strict mode, Node 20.9+/22 LTS. All dynamic APIs (`params`, `searchParams`, `cookies()`, `headers()`) are async and must be awaited.

## Parts (each has a main note + a Code Appendix note with full literal snippets)

1. **EntNext16 - Part 1: The Data Layer (Repository Pattern)** — killing `useEffect` fetching, Repository Pattern, `fetch` caching, `revalidateTag`/`revalidatePath`, `cache()` dedupe, `unstable_cache`. *(Code is inline in the main note; no separate appendix needed.)*
2. **EntNext16 - Part 2: Orchestration and State** — URL search params as state, Server Action composition, `useOptimistic` vs local state.
   → **EntNext16 - Part 2 Code Appendix** (full snippets: filter-bar, project-row, actions)
3. **EntNext16 - Part 3: Component Composition** — killing prop drilling, Slot Pattern, Compound Components, keeping Server Components server-rendered inside Client shells.
   → **EntNext16 - Part 3 Code Appendix** (full snippets: interactive-card, project-stats, tabs compound component)
4. **EntNext16 - Part 4: Resilient Infrastructure and Deployment** — nested `error.tsx`, manual error boundaries, granular Suspense/loading UI, Facade Pattern for SDKs, and a full **Deploying to Vercel** section on Full Route Cache / Data Cache / on-demand revalidation / streaming / cold starts.
   → **EntNext16 - Part 4 Code Appendix** (full snippets: error boundaries, skeletons, Stripe payments facade)

## Reading order

Read in order 1 → 4. Part 2 assumes the repositories from Part 1 exist. Part 3 assumes the mutation actions from Part 2 exist. Part 4 wraps everything with resilience and ships it to Vercel.

## Continuous narrative thread

All four parts build one running example: a "Projects Dashboard." Part 1 builds `projectRepository`. Part 2 adds `archiveProject`/`archiveAndNotify` Server Actions plus a URL-filtered list view. Part 3 restructures the list/detail UI with `InteractiveCard` and a `Tabs` compound component. Part 4 wraps it all in error boundaries, splits loading UI per-section, and adds a `paymentsFacade` example for external SDK integration, then explains Vercel deployment implications.
