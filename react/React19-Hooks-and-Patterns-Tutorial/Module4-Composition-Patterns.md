# **Module 4: Composition Patterns — Composition Over Prop-Drilling**:

---

## Concept Explanation

**Prop-drilling:** passing a prop through layers that don't use it, just to reach the layer that does. **Composition** is the fix: a component accepts `children` (or React-element props) and lets the parent decide what goes inside — like `<div>` not knowing what's inside it.

**The powerful combo:** Server Components can pass React elements (not just data) as `children`/props into Client Components — only the truly interactive leaf needs `"use client"`.

**Key terms:** Slot pattern (renders `{children}` or named props like `header`/`footer`); Server Component passed as children into Client Component (the `"use client"` boundary doesn't "infect" content that arrives via `children` from a Server Component parent).

## Implementation

**Step 1 — The prop-drilling problem:** `Dashboard` → `Panel` → `PanelHeader`, where `Panel` forwards `user` it never uses — coupling it to a shape it doesn't care about.

**Step 2 — Fix with `children`:**
```tsx
export function Panel({ children, title }: { children: ReactNode; title?: string }) {
  return (
    <div className="rounded-lg border border-slate-800 bg-slate-900/40 p-4">
      {title && <h3 className="mb-2 font-semibold text-slate-200">{title}</h3>}
      {children}
    </div>
  );
}
```
Now `Dashboard` passes `<PanelHeader user={user} />` directly as children — `Panel` never touches `user`.

**Step 3 — Named slots for multi-region components:** `Card` with `header`, `footer`, and `children` props — never imports or knows about what's slotted in.

**Step 4 — Composition across the Server/Client boundary (the key insight):** `Collapsible` (Client Component, `useState` for open/closed) receives a `<ul>` built by a Server Component parent as `children`. That `<ul>` stays server-rendered — zero extra client JS — even though it visually lives inside an interactive client widget, because `"use client"` marks the *module*, not content passed in via `children` from outside.

## Exercise: Challenge
Build a composable `<Tabs>` component: Client Component managing `activeIndex`, taking `tabs: { label, content: ReactNode }[]`, with all three tabs' content server-fetched/rendered. Bonus: explain why passing `content: ReactNode` (rather than `Tabs` importing `<TaskList>` itself) keeps fetching server-side.

## Solution

```tsx
// Tabs.tsx (Client Component)
"use client";
export function Tabs({ tabs }: { tabs: { label: string; content: ReactNode }[] }) {
  const [activeIndex, setActiveIndex] = useState(0);
  return (
    <div>
      <div className="flex gap-2 border-b border-slate-800">
        {tabs.map((tab, i) => (
          <button key={tab.label} onClick={() => setActiveIndex(i)}>{tab.label}</button>
        ))}
      </div>
      <div className="py-4">{tabs[activeIndex]?.content}</div>
    </div>
  );
}
```

Server Component page fetches `tasks` and `notifications` via `Promise.all`, then passes fully-rendered `<ul>` content for each tab.

**Explanation:** `Tabs` never imports `getTasks` — it only decides *which* pre-built `ReactNode` to show. If `Tabs` internally rendered `<TaskList />` itself, that component (and its data-fetching) would need to become client code too, dragging server-only logic into the browser bundle. Passing rendered `ReactNode` as data preserves the server/client split while still allowing full composition.
