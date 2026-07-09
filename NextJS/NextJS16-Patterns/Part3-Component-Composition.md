# Part 3: Component Composition

Goal: move beyond prop drilling. Two techniques: the **Slot Pattern** (children / named component props) and **Compound Components** (a parent component that shares implicit state/context with its own children sub-components). Both keep Server Components server-rendered even when nested inside Client Component shells.

*(Full literal code lives in "EntNext16 - Part 3 Code Appendix" — ask for it directly if you want it.)*

---

## 1. The Anti-Pattern (prop drilling + accidental client boundary bloat)

Old approach: a `Card` component that accepts `title`, `description`, `icon`, `footerText`, `footerAction`, `showBadge`, `badgeColor`... as individual props, then internally decides how to lay them out. Two problems compound:

- **Prop drilling / prop explosion**: every new visual variant (a Card with a chart, a Card with a form, a Card with a list) means adding more optional props to the same component, and threading data through 2-3 intermediate components that don't use it themselves, just to reach a deeply nested child.
- **Accidental client boundary bloat**: because the Card needs an `onClick` for the footer action, the entire Card (and everything nested inside it, including what could have been static server-rendered content like a long description or a data table) gets marked `"use client"` — pulling server-only content into the client bundle and losing streaming/RSC benefits for content that never needed interactivity.

---

## 2. The Next.js 16 Pattern

### 2a. Slot Pattern (children and named slots)

Instead of a Card taking data props and rendering markup internally, it takes `children` (the default slot) and/or explicitly named props that are themselves `ReactNode` (e.g., `header`, `footer`). The Card component itself only owns layout/styling — a `"use client"` wrapper if it truly needs interactivity (hover state, expand/collapse) — while the actual content passed into its slots can remain Server Components, because passing a Server Component as `children` (or as a named `ReactNode` prop) into a Client Component does **not** convert that child into client code. React renders the server-rendered slot content on the server and simply hands the Client Component an already-resolved React element tree to place — the Client Component never re-executes or needs to import that child's server-only dependencies.

Concretely: an `<InteractiveCard>` client component (owns only `isExpanded` state and the toggle button) receives `header` and `children` props, both of which are populated in a Server Component parent with real data-fetching Server Components (e.g., a `ProjectStats` server component that awaits a repository call) — zero client bundle cost for that data-heavy content, even though it's visually "inside" a client-rendered shell.

### 2b. Compound Components (implicit shared state via Context)

For UI families where several sub-parts need to coordinate (a `Tabs` component and its `TabList`/`Tab`/`TabPanels`, or an `Accordion` and its `Item`/`Trigger`/`Content`), use the Compound Component pattern: a parent component creates a small Context (active tab index, open/closed item id) and exposes child components as properties on itself (`Tabs.List`, `Tabs.Trigger`, `Tabs.Content`) or as separate named exports used together. Consumers compose the pieces declaratively without passing any state through explicit props — the coordination is implicit via context, and the public API reads like plain HTML/JSX rather than a config-object prop.

This is a client-side pattern almost by definition (it needs interactive state), but keep the Context/state logic isolated to just the interactive shell components — the *content* rendered inside each `Tab.Content` can still be a Server Component passed as children, same principle as 2a.

---

## 3. Type-Safe Implementation

- Slot props are typed as `ReactNode`, never `any` or a rendering-callback function unless render-prop flexibility is specifically needed (rare in Server/Client boundary scenarios, since a function prop passed from a Server Component to a Client Component is not serializable — only element trees / Server Actions can cross that boundary).
- Compound Component context is typed with a discriminated interface (e.g., `TabsContextValue { activeId: string; setActiveId: (id: string) => void }`) and a custom hook (`useTabsContext()`) that throws a descriptive error if a sub-component is rendered outside its parent Provider — this catches misuse (e.g., `<Tabs.Trigger>` used outside `<Tabs>`) at runtime with a clear message instead of a silent `undefined` context bug.
- Every compound sub-component's props interface extends or omits from standard HTML element props (e.g., `ComponentPropsWithoutRef<"button">`) so consumers can still pass `className`, `onClick`, `aria-*`, etc. through without the library re-declaring every native attribute.

---

## 4. Architect's Note

**Trade-off — Slot Pattern flexibility vs discoverability:** children/named-slot APIs are extremely flexible and keep the server/client boundary as thin as possible, but they're less self-documenting than an explicit prop list — a consumer has to open the component (or its stories/docs) to know which named slots exist (header, footer, sidebar) versus a data-prop API where TypeScript autocomplete shows everything. Mitigate this by keeping a small number of well-named slots (2-4) rather than an open-ended children free-for-all once a component's layout has more than one distinct region.

**Trade-off — Compound Components and bundle boundary:** because the parent must hold client state, the entire compound family's *shell* (`Tabs`, `Tabs.List`, `Tabs.Trigger`) is client code, but this is a small, fixed cost paid once regardless of how much content flows through it — the actual page content inside `Tabs.Content` is not forced into the client bundle. Keep compound component shells generic/reusable (a design-system-level primitive) so this client-cost is paid once per app, not once per feature.

**Trade-off — Context re-renders:** Compound Components built on Context re-render all consuming sub-components whenever the shared state changes (e.g., every `Tab.Trigger` re-renders when `activeId` changes, to check if it's the active one). For small UI families (under ~20 items) this is invisible; for large dynamically-generated lists (e.g., 200-row accordion), consider splitting context value from context setter, or memoizing sub-components with `React.memo` keyed on relevant slices of the context value.

---

Next up: **Part 4 — Resilient Infrastructure**, where these composed UI modules get wrapped in error boundaries and loading states, and external SDK calls get wrapped in a Facade Pattern.
