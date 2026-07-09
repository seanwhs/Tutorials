# **Module 2: Async Mastery — The `use` Hook, Suspense, and Streaming**:

---

## Concept Explanation

Before React 19, reading a promise required `useEffect` + `useState` gymnastics. React 19's **`use` hook** lets you read a Promise (or Context) directly during render.

`use` is not a normal hook — it can be called conditionally/in loops. **Hard rule:** the promise must not be created fresh on every render inside a Client Component (causes infinite refetch loop). Idiomatic pattern: create the promise in a **Server Component**, pass it as a prop, call `use(promise)` in a **Client Component** wrapped in `<Suspense>`.

**`use` for Context:** unlike `useContext`, `use(SomeContext)` can be called after an early `return` or inside an `if` block.

## Implementation

**Step 1 — Slow data source:**
```ts
export type Notification = { id: string; text: string };
export async function getNotifications(): Promise<Notification[]> {
  await new Promise((res) => setTimeout(res, 2000));
  return [{ id: "n1", text: "Your report is ready" }, { id: "n2", text: "New comment on your task" }];
}
```

**Step 2 — Start promise in Server Component, don't await it:**
```tsx
export default async function Module2Page() {
  const tasks = await getTasks(); // fast: await normally
  const notificationsPromise = getNotifications(); // slow: do NOT await
  return (
    <main className="space-y-6">
      <section>{/* tasks list, rendered immediately */}</section>
      <section>
        <Suspense fallback={<p>Loading notifications…</p>}>
          <NotificationsList notificationsPromise={notificationsPromise} />
        </Suspense>
      </section>
    </main>
  );
}
```

**Step 3 — Read with `use` in a Client Component:**
```tsx
"use client";
import { use } from "react";
export function NotificationsList({ notificationsPromise }: { notificationsPromise: Promise<Notification[]> }) {
  const notifications = use(notificationsPromise); // suspends until resolved
  return <ul>{notifications.map((n) => <li key={n.id}>{n.text}</li>)}</ul>;
}
```
**Common mistake:** calling `getNotifications()` *inside* the Client Component → infinite suspend loop.

**Step 4 — `use` for conditional Context reads:** a `PlanBadge` component does an early `return null`, *then* calls `use(UserContext)` — illegal with `useContext`, fine with `use`.

## Exercise: Challenge
Build a streamed "Recent Activity" panel: add `getRecentActivity()` (1.5s delay), render it in its own sibling `<Suspense>` alongside Notifications so both stream independently, with distinct fallbacks. Bonus: explain why sibling Suspense boundaries stream independently but nested ones don't.

## Solution
Full `getRecentActivity()`, updated page with both `notificationsPromise` and `activityPromise` started in parallel (neither awaited), and an `ActivityList` component mirroring `NotificationsList`.

**Explanation:** Both promises kick off in parallel; Activity (1.5s) visibly resolves before Notifications (2s) despite being declared second, since each `<Suspense>` is an independent stream target. Nesting breaks this because an inner `<Suspense>` placed inside an outer's *fallback* is discarded wholesale once the outer resolves — it was never mounted as real sibling content.
