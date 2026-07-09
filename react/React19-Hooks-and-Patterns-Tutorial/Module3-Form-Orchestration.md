# **Module 3: Form Orchestration — `useFormStatus`, `useActionState`, and `useOptimistic`**:

---

## Concept Explanation

`useFormStatus` reads the pending state of the **nearest parent `<form>`** automatically — no prop-drilling `isPending` through layers. `useOptimistic` shows a mutation's result immediately, before server confirmation, reconciling automatically once the real response arrives.

**Key terms:**
- `useFormStatus()`: called from a *descendant* of a `<form>` (not the form's own component). Returns `{ pending, data, method, action }`.
- `useOptimistic(state, updateFn)`: returns `[optimisticState, addOptimistic]`.

## Implementation

**Step 1 — Reusable `SubmitButton` (zero props for loading state):**
```tsx
"use client";
import { useFormStatus } from "react-dom";

export function SubmitButton({ children, pendingText = "Saving..." }: { children: ReactNode; pendingText?: string }) {
  const { pending } = useFormStatus();
  return (
    <button type="submit" disabled={pending} className="rounded bg-blue-600 px-4 py-2 text-white disabled:opacity-50">
      {pending ? pendingText : children}
    </button>
  );
}
```
*(`useFormStatus` lives in `react-dom`, not `react`, since it's DOM-form-specific.)*

**Step 2 — Use it in any form without threading props:** `ProfileForm` uses `useActionState(updateProfileAction, initialState)` + drops in `<SubmitButton>` with zero pending prop. Paired `updateProfileAction` Server Action validates with zod, simulates DB write, returns typed state.

**Step 3 — Optimistic UI:** `OptimisticTaskToggle` uses `useOptimistic(task.done)` inside `useTransition` — instantly flips the checkbox, then calls the real Server Action. Reverts automatically if server state doesn't match.

## Exercise: Challenge
1. Build `<FormError>` — uses `useFormStatus`'s `data` field to show a live validation hint while submitting, with zero props.
2. Build an optimistic comment list — new comments appear instantly marked "(sending...)" before server confirmation.

## Solution

```tsx
// FormError.tsx
"use client";
import { useFormStatus } from "react-dom";
export function FormError({ field, message }: { field: string; message: string }) {
  const { pending, data } = useFormStatus();
  if (!pending || !data) return null;
  const value = data.get(field);
  const isEmpty = !value || String(value).trim().length === 0;
  if (!isEmpty) return null;
  return <p className="text-xs text-amber-400">{message}</p>;
}
```

`OptimisticComments` component: `useOptimistic(comments, reducer)` appends a `{ pending: true }` entry synchronously on submit inside `startTransition`, then awaits the real `addCommentAction`. 

**Explanation:** the optimistic comment renders in the same tick as the click, while the real action is still awaiting its 700ms simulated delay. Once the transition finishes and the real revalidated `comments` prop arrives, `useOptimistic` automatically discards the fake entry — no manual cleanup code needed.
