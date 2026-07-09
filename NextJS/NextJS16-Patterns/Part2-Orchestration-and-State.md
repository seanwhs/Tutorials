# Part 2: Orchestration and State

Goal: replace global client state managers (Redux/Zustand/Context-as-store) for two categories of state:

1. Shareable, bookmarkable UI state (filters, tabs, pagination, sort order) → URL Search Params.
2. Cross-component data mutations → Server Action composition, with revalidation closing the loop back to Part 1's repositories.

Also covers the `useOptimistic` vs local `useState` decision.

*(Full literal code lives in the companion "EntNext16 - Part 2 Code Appendix" note — ask for it directly if you want it.)*

---

## 1. The Anti-Pattern (Next.js 13/14-style global client state)

Old approach: a Zustand/Context store just to hold filter/sort/page state that is fundamentally derived from the URL, plus a client-side mutation function calling a REST API route and manually updating store state to reflect the change.

Problems this causes:
- Filter state is lost on refresh and cannot be shared via link/bookmark, even though it is exactly the kind of state a URL is designed for.
- A client store adds a dependency, a Provider wrapping the tree, and shipped JS, purely to hold what is serializable UI state.
- The mutation function optimistically edits store state by hand, with no built-in rollback if the server call fails, and no connection to the server cache from Part 1 (the store and the Data Cache silently drift apart).

---

## 2. The Next.js 16 Pattern

### 2a. URL Search Params as State

Directory:
```
app/dashboard/projects/page.tsx        Server Component, reads searchParams
app/dashboard/projects/filter-bar.tsx  Client Component, small, only updates URL
```

Filter bar (the ONLY client code needed) reads current params via `useSearchParams`, and on change builds a new `URLSearchParams` object and calls `router.push`, `router.replace`, or wraps the navigation in `startTransition` from `useTransition` for non-blocking updates. No stored client state at all — the URL is the single source of truth.

The page Server Component receives `searchParams` as a Promise (async dynamic API in Next.js 16), awaits it, parses/validates `status` and `sort` with zod, and passes the validated values straight into the Part 1 repository call, e.g. `projectRepository.getAll({ status, sort })`.

### 2b. Server Action Composition

Directory:
```
lib/actions/project-actions.ts
```

Pattern: small, single-purpose Server Actions that compose. A low-level action (`archiveProject(id)`) does one write and calls `revalidateTag("projects")`. A higher-level action (`archiveAndNotify(id)`) calls `archiveProject(id)` then a notification action, composing two server-only functions the same way you'd compose normal functions, all still executing on the server with zero client bundle cost. Each action validates its input with zod before touching the repository/db layer, and returns a discriminated union result type (`{ success: true, data } | { success: false, error }`) rather than throwing, so client components can render either branch without try/catch.

### 2c. useOptimistic vs local useState

Decision rule:
- **Local `useState`**: state that is purely client-side UI (an accordion open/closed, a hover flag, a modal visibility toggle) with no server round-trip. No optimism needed because there's nothing to reconcile against.
- **`useOptimistic`**: state that mirrors server data and is about to be mutated by a Server Action, where you want the UI to update instantly before the network round-trip resolves, and automatically revert if the action fails. Example: toggling a project's archived flag in a list — show it as archived immediately, call the Server Action, and let React reconcile with the real server-confirmed value when the action settles.

Example flow: a `ProjectRow` Client Component holds `const [optimisticStatus, setOptimisticStatus] = useOptimistic(project.status)`, wraps the click handler in `startTransition`, calls `setOptimisticStatus("archived")` synchronously for instant feedback, then awaits the `archiveProject` Server Action; if the action's returned result has `success: false`, the component sets a local error state to show an inline "failed to archive, reverted" message (React automatically reverts the optimistic value once the action's promise settles and the underlying prop updates via revalidation).

---

## 3. Type-Safe Implementation

Define a shared `ActionResult<T>` discriminated union type in `lib/actions/types.ts`:
```ts
type ActionResult<T> = { success: true; data: T } | { success: false; error: string }
```

Every Server Action's return type is `ActionResult<SomeShape>`, never `any`, never a bare thrown `Error` surfaced to the client as an unhandled rejection. Input validation uses zod schemas colocated with each action file (e.g., `archiveProjectSchema = z.object({ id: z.string().uuid() })`), parsed with `.safeParse` so invalid input becomes a typed `{ success: false, error }` instead of a runtime throw.

`searchParams` parsing on the Server Component side uses a matching zod schema (`projectFilterSchema`) with `.catch()` defaults, so a malformed or missing query string never crashes the page — it falls back to sane defaults (`status: "all"`, `sort: "updatedAt"`).

---

## 4. Architect's Note

**Trade-off — URL state vs client store:** URL state is free (no dependency, no Provider, shareable, survives refresh, works with the back button) but has a practical size/complexity ceiling — deeply nested UI state or non-serializable state (e.g., a `File` object, a `Map`) still needs local or lifted React state. Use URL state for anything a user would reasonably want to bookmark or share; keep everything else local.

**Trade-off — `revalidateTag` granularity:** composing Server Actions that each call `revalidateTag("projects")` is simple but coarse — it invalidates every cached fetch tagged `"projects"` even if only one project changed. Tagging both a collection tag (`"projects"`) and an item tag (`"project:id"`) per Part 1, and revalidating only the tags actually affected by a given action, avoids unnecessary cache churn on high-traffic list pages.

**Trade-off — `useOptimistic` failure UX:** optimistic UI trades a small risk of visible "flicker back" on failure for a large perceived-performance win on the common success path. For destructive or high-stakes actions (e.g., deleting a project), prefer explicit confirmation plus a normal pending state over optimism, since a revert after the user has already navigated away feels worse than a brief spinner.

---

Next up: **Part 3 — Component Composition**, where the `ProjectRow` and `FilterBar` components built here get restructured with the Slot Pattern and Compound Components to stay reusable as the dashboard grows.
