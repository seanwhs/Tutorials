# Type-Safe Horizons — Part 1: Beyond Basics

*Series: Type-Safe Horizons: Mastering TypeScript in the Next.js Ecosystem. Prerequisite: none — start here.*

## Safety Check: The Anti-Pattern

```tsx
function TaskCard(props: any) {
  return (
    <div>
      <h3>{props.tittle}</h3>
      <p>{props.stat}</p>
    </div>
  );
}
```

`props.tittle` is a typo. `props.stat` doesn't exist on any real Task. Both compile without a single warning, and both silently render `undefined` in production. `any` is not "no type" — it is a type that actively turns the compiler off for that value and everything derived from it.

A more common, sneakier variant is the "loose interface":

```tsx
interface TaskProps {
  title?: string;
  status?: string;
  priority?: string;
}

function TaskCard({ title, status, priority }: TaskProps) {
  if (status === "donee") {
    // typo — never true, and TypeScript can't help because status is just `string`
  }
  return <h3>{title}</h3>;
}
```

Two separate problems stack here: every field is optional (so every consumer has to null-check everything, even fields that are logically always present), and `status: string` accepts *any* string — `"donee"`, `"Done"`, `"DONE "` all type-check identically to the correct `"done"`.

## Type Logic

Before touching implementation, reason about the *shape* of the data:

- **Interfaces vs. `type`** — both describe object shapes and are interchangeable 95% of the time. The practical difference: `interface` supports **declaration merging** (two `interface Foo` blocks combine) and is what most component-library authors extend from; `type` is required for unions, tuples, and mapped/conditional types. Rule of thumb: use `interface` for public component prop contracts you expect consumers to extend; use `type` for everything else (unions, derived/utility types, function signatures).
- **Discriminated unions** — when a value can be one of several *distinct shapes*, don't model it as one object with a pile of optional fields. Model it as a union of exact shapes, tied together by one shared literal field (the "discriminant" or "tag"). TypeScript's control-flow narrowing then uses that tag to know exactly which fields exist inside each `if`/`switch` branch — no optional chaining, no unsafe casts.
- **Utility types** (`Pick`, `Omit`, `Partial`) exist so you never hand-duplicate a shape that already exists elsewhere. If a form needs "everything about a Task except its id," you don't write a second interface — you *derive* it with `Omit<Task, "id">`. When the base type changes, every derived type updates automatically; hand-duplicated types silently drift out of sync.

## Refactored Solution

### 1. A precise base type

```ts
// types/task.ts
export interface Task {
  id: string;
  title: string;
  status: "todo" | "in-progress" | "done";
  priority: "low" | "medium" | "high";
  assigneeId: string | null;
  dueDate: Date | null;
}
```

Notice `status` and `priority` are **string literal unions**, not `string`. This is the single highest-leverage change you can make to a codebase full of stringly-typed state: `"donee"` is now a compile error, and your editor autocompletes the valid values.

### 2. Interfaces vs. type — applied

```ts
// Public component contract → interface (extendable, mergeable)
export interface TaskCardProps {
  task: Task;
  onSelect?: (id: Task["id"]) => void;
}

// A union of shapes → must be `type`, interfaces can't express unions
export type TaskFilter = "all" | "active" | "completed";
```

`Task["id"]` above is an **indexed access type** — it reads the type of the `id` property off `Task`. If `Task.id` ever changes from `string` to a branded type (see Part 4), `onSelect`'s signature updates automatically with zero edits here.

### 3. Discriminated unions for request state

This is the pattern that replaces the classic `isLoading: boolean; error?: string; data?: T` anti-pattern, where all three combinations that shouldn't be possible (`isLoading: true` *and* `data` present) are still perfectly legal to construct.

```ts
// types/request-state.ts
export type RequestState<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; error: string };
```

Using it:

```tsx
"use client";

import { useState } from "react";
import type { RequestState } from "@/types/request-state";
import type { Task } from "@/types/task";

function TaskList() {
  const [state, setState] = useState<RequestState<Task[]>>({ status: "idle" });

  switch (state.status) {
    case "idle":
      return <p>Ready to load tasks.</p>;
    case "loading":
      return <p>Loading…</p>;
    case "error":
      // state.error exists here — TypeScript narrowed it, no `state.error!`, no optional chaining
      return <p role="alert">Failed: {state.error}</p>;
    case "success":
      // state.data exists here, fully typed as Task[]
      return (
        <ul>
          {state.data.map((task) => (
            <li key={task.id}>{task.title}</li>
          ))}
        </ul>
      );
  }
}
```

Try accessing `state.data` inside the `"loading"` branch — TypeScript refuses, because that shape genuinely does not have a `data` field. This is the anti-pattern from the top of this lesson, made structurally impossible rather than just discouraged by convention.

### 4. Utility types on real props

```ts
import type { Task } from "@/types/task";

// Omit — "everything about Task except id and dueDate" (server assigns these)
export type CreateTaskInput = Omit<Task, "id" | "dueDate"> & {
  dueDate?: Date;
};

// Pick — a lightweight summary shape for a list row, not the whole Task
export type TaskSummary = Pick<Task, "id" | "title" | "status">;

// Partial — a patch object for an edit form (any subset of fields may change)
export type TaskUpdate = Partial<Omit<Task, "id">>;

function updateTask(id: Task["id"], patch: TaskUpdate) {
  // patch.title, patch.status, etc. are all optional here — correctly so,
  // since this is exactly a "partial update" shape, unlike TaskProps earlier
  // where fields were optional despite being logically required.
}
```

The distinction that matters: `TaskProps` in the anti-pattern had optional fields because the *author was lazy*. `TaskUpdate` has optional fields because a partial update *is genuinely optional data*. Same TypeScript syntax (`?`), completely different intent — and `Partial<T>` documents that intent for you instead of leaving it to a comment.

### 5. Applied to a Next.js 16 page (typed `searchParams`)

Next.js 16 passes `searchParams` to Server Component pages as a `Promise`. Combine that with the union types above:

```tsx
// app/tasks/page.tsx
import type { TaskFilter } from "@/types/task";

interface TasksPageProps {
  searchParams: Promise<{ filter?: TaskFilter }>;
}

export default async function TasksPage({ searchParams }: TasksPageProps) {
  const { filter = "all" } = await searchParams;
  // filter is narrowed to "all" | "active" | "completed" — a typo like
  // ?filter=activee still arrives as a string at runtime (searchParams are
  // always strings), so validate at the boundary — see Part 3 for the
  // full Server Action / Zod validation pattern.
  return <TaskListServer filter={filter} />;
}

async function TaskListServer({ filter }: { filter: TaskFilter }) {
  return null; // fetch + render tasks here
}
```

Note the honest caveat: `searchParams` values are runtime strings supplied by the URL, so the type annotation is a *contract for your own code*, not a runtime guarantee. Part 3 covers validating and narrowing untrusted boundary data (Zod) so the type and the runtime value actually agree.

## Exercise Challenge

Given this loose starting point:

```ts
interface NotificationProps {
  type?: string;
  message?: string;
  actionUrl?: string;
  actionLabel?: string;
}
```

A notification is really one of three distinct kinds: an `"info"` notification (just a message), a `"action-required"` notification (message + required `actionUrl` + `actionLabel`), and a `"error"` notification (message + optional `retryable: boolean`). Refactor `NotificationProps` into a discriminated union that makes it impossible to construct an `"action-required"` notification without both `actionUrl` and `actionLabel`.

## Solution

```ts
export type NotificationProps =
  | { type: "info"; message: string }
  | { type: "action-required"; message: string; actionUrl: string; actionLabel: string }
  | { type: "error"; message: string; retryable?: boolean };

function Notification(props: NotificationProps) {
  switch (props.type) {
    case "info":
      return <p>{props.message}</p>;
    case "action-required":
      // props.actionUrl and props.actionLabel are guaranteed present — no `?.`, no `!`
      return (
        <div>
          <p>{props.message}</p>
          <a href={props.actionUrl}>{props.actionLabel}</a>
        </div>
      );
    case "error":
      return <p role="alert">{props.message} {props.retryable && "(retry available)"}</p>;
  }
}
```

Constructing `{ type: "action-required", message: "Approve this" }` without `actionUrl`/`actionLabel` is now a compile error at the call site — the bug is caught before the component ever renders, not discovered in a bug report.

## TypeScript Tip: `satisfies`

When you want to check an object against a type *without widening or losing the literal type*, use `satisfies` instead of an annotation:

```ts
const defaultFilter = { filter: "all" } satisfies { filter: TaskFilter };
// defaultFilter.filter is inferred as the literal "all", not widened to TaskFilter —
// autocomplete and further narrowing both still work.

// Compare to an annotation, which widens immediately:
const wider: { filter: TaskFilter } = { filter: "all" };
// wider.filter's inferred type is TaskFilter, the literal "all" is lost.
```

`satisfies` is the fix for the common "I want type-checking on this object literal but I still want the specific inferred type afterward" problem — extremely common on config objects, default props, and similar registries in a real app.

---
**Next:** Part 2: The Component Layer — typing `ReactNode`, `forwardRef`, and `ComponentPropsWithoutRef`.
