# Part 6: Data Orchestration

## 6.1 Concept: Server Actions Replace the API Layer

In Part 5.7 you built a Route Handler by hand to accept a `POST` request. Server Actions give you the same capability — a function that runs on the server, callable from a form — without manually defining a URL, a fetch call, or JSON serialization. Under the hood, Next.js still sends a `POST` request (same HTTP mechanics from Part 1), but the framework generates and wires that request for you.

```typescript
// app/actions/cards.ts
"use server";

import { revalidatePath } from "next/cache";

// Same fake in-memory store as Part 5, imported from a shared module in a real app
let cards = [{ id: "c1", title: "Fix login bug", columnId: "todo" }];

export async function createCard(formData: FormData) {
  const title = formData.get("title");
  const columnId = formData.get("columnId");

  if (typeof title !== "string" || title.trim().length === 0) {
    return { error: "Title is required" };
  }

  cards.push({
    id: crypto.randomUUID(),
    title: title.trim(),
    columnId: columnId as string,
  });

  // Tells Next.js: the data behind this path changed, re-render Server
  // Components there on next navigation/request — no manual cache-busting.
  revalidatePath("/board");
}
```

`"use server"` marks every exported function in this file as a Server Action — callable directly from a Client Component as if it were a local function, even though it executes on the server.

## 6.2 Wiring a Server Action to a Form

```tsx
// app/components/AddCardForm.tsx
"use client";

import { createCard } from "@/app/actions/cards";

export function AddCardForm({ columnId }: { columnId: string }) {
  return (
    <form action={createCard}>
      <input type="hidden" name="columnId" value={columnId} />
      <label htmlFor={`title-${columnId}`}>New card title</label>
      <input id={`title-${columnId}`} name="title" required />
      <button type="submit">Add card</button>
    </form>
  );
}
```

Compare this to Part 4's vanilla approach (`onSubmit` -> `preventDefault` -> `fetch` -> parse JSON -> update DOM by hand). The `action={createCard}` prop replaces all of that: the browser's native form submission mechanics (Part 1's `POST`) are preserved, progressive enhancement works even before JS loads, and there's no manual `fetch` call anywhere in this file.

## 6.3 `useActionState`: Tracking Pending/Error State

Raw `action={fn}` has no way to show a loading spinner or a validation error. `useActionState` wraps a Server Action to expose that state to the component:

```tsx
// app/components/AddCardForm.tsx
"use client";

import { useActionState } from "react";
import { createCard } from "@/app/actions/cards";

const initialState = { error: undefined as string | undefined };

export function AddCardForm({ columnId }: { columnId: string }) {
  const [state, formAction, isPending] = useActionState(async (_prevState: typeof initialState, formData: FormData) => {
    const result = await createCard(formData);
    return result ?? { error: undefined };
  }, initialState);

  return (
    <form action={formAction}>
      <input type="hidden" name="columnId" value={columnId} />
      <label htmlFor={`title-${columnId}`}>New card title</label>
      <input id={`title-${columnId}`} name="title" required disabled={isPending} />
      <button type="submit" disabled={isPending}>
        {isPending ? "Adding..." : "Add card"}
      </button>
      {state.error && <p role="alert">{state.error}</p>}
    </form>
  );
}
```

`isPending` is derived automatically from the `async` function's lifecycle (Part 4.3's event loop, formalized into a hook) — no manual `setLoading(true)` / `setLoading(false)` bookkeeping.

## 6.4 `useOptimistic`: Instant UI Before the Server Responds

Recall Part 4.5's hand-rolled optimistic update (render immediately, roll back on failure). `useOptimistic` is React's built-in version of that exact pattern:

```tsx
// app/components/CardColumn.tsx
"use client";

import { useOptimistic } from "react";
import { AddCardForm } from "./AddCardForm";

type Card = { id: string; title: string };

export function CardColumn({ columnId, initialCards }: { columnId: string; initialCards: Card[] }) {
  const [optimisticCards, addOptimisticCard] = useOptimistic(
    initialCards,
    (current, newCard: Card) => [...current, newCard]
  );

  async function handleSubmit(formData: FormData) {
    const title = formData.get("title") as string;

    // Show the card immediately, before the server has confirmed anything
    addOptimisticCard({ id: `temp-${Date.now()}`, title });

    // The real Server Action call still happens, and initialCards will
    // eventually reflect the confirmed server state after revalidation
    await createCard(formData);
  }

  return (
    <section>
      <ul>
        {optimisticCards.map((card) => <li key={card.id}>{card.title}</li>)}
      </ul>
      <form action={handleSubmit}>
        <input type="hidden" name="columnId" value={columnId} />
        <input name="title" required />
        <button type="submit">Add card</button>
      </form>
    </section>
  );
}
```

## 6.5 `useFormStatus`: A Reusable Submit Button

A common professional pattern: extract a `SubmitButton` that knows its own pending state, without prop-drilling `isPending` through every form:

```tsx
// app/components/SubmitButton.tsx
"use client";

import { useFormStatus } from "react-dom";

export function SubmitButton({ children }: { children: React.ReactNode }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending}>
      {pending ? "Saving..." : children}
    </button>
  );
}
```

`useFormStatus` must be called from a component *rendered inside* a `<form>`, not the form component itself — it reads the status of its nearest parent form automatically.

## 6.6 Basic Client State: `useState` for UI-Only Concerns

Not everything needs a Server Action. Toggling a modal, expanding a card, tracking a search input as you type — pure UI state belongs in `useState`, kept local and client-only:

```tsx
"use client";
import { useState } from "react";

export function CardSearch({ onSearch }: { onSearch: (query: string) => void }) {
  const [query, setQuery] = useState("");

  return (
    <input
      value={query}
      onChange={(e) => {
        setQuery(e.target.value);
        onSearch(e.target.value);
      }}
      placeholder="Search cards..."
    />
  );
}
```

**Rule of thumb going forward:** if the state needs to survive a page refresh or be visible to other users, it belongs on the server (Server Action + revalidation). If it's purely how the current user is interacting with the page right now, `useState` is correct and simpler.

## Exercise Challenge

1. Add server-side validation to `createCard` that rejects titles longer than 100 characters, returning a clear `error` message, and surface that error in `AddCardForm` using `useActionState`.
2. Extend `CardColumn`'s optimistic update so that if `createCard` throws (simulate this by throwing inside `createCard` when the title is `"fail"`), the optimistic card is removed and an error is shown.

## Solution & Explanation

```typescript
// app/actions/cards.ts
export async function createCard(formData: FormData) {
  const title = formData.get("title");

  if (typeof title !== "string" || title.trim().length === 0) {
    return { error: "Title is required" };
  }
  if (title.length > 100) {
    return { error: "Title must be 100 characters or fewer" };
  }
  if (title === "fail") {
    throw new Error("Simulated server failure");
  }

  cards.push({ id: crypto.randomUUID(), title: title.trim(), columnId: formData.get("columnId") as string });
  revalidatePath("/board");
}
```

```tsx
async function handleSubmit(formData: FormData) {
  const title = formData.get("title") as string;
  const tempId = `temp-${Date.now()}`;
  addOptimisticCard({ id: tempId, title });

  try {
    const result = await createCard(formData);
    if (result?.error) throw new Error(result.error);
  } catch (err) {
    // In a full implementation, filter optimisticCards to remove tempId here,
    // typically by deriving the reducer to accept a "remove" action shape too.
    console.error(err);
  }
}
```

The key lesson: `useOptimistic`'s reducer only controls *what renders while pending* — once the real server state (`initialCards`, refreshed via `revalidatePath`) comes back, React reconciles to that truth automatically. Error rollback is about ensuring your error UI communicates the failure, since the optimistic entry disappears on its own once the underlying `initialCards` prop updates without it.

---
*Next: `Roadmap Tutorial - Part 7: Styling & Polish`*

---

Say "next" to continue to Part 7.
