# Appendix B: React 19 New APIs

## Purpose of This Appendix
A standalone reference consolidating every React 19-specific API used throughout this series — `useActionState`, `useFormStatus`, `useOptimistic`, `use()`, and the broader concept of "Actions" — with direct comparisons to how you'd have solved the same problems in React 18, so the *value* of each new API is concrete rather than abstract.

---

## The Underlying Shift: "Actions" as a First-Class Concept

Before React 19, handling a form submission that triggers async work (a network request, a file upload) typically required manually wiring together three separate pieces of state:

```javascript
// The React 18 way — manual, but instructive to see explicitly
const [isLoading, setIsLoading] = useState(false);
const [error, setError] = useState(null);
const [result, setResult] = useState(null);

async function handleSubmit(formData) {
  setIsLoading(true);
  setError(null);
  try {
    const data = await someAsyncOperation(formData);
    setResult(data);
  } catch (err) {
    setError(err.message);
  } finally {
    setIsLoading(false);
  }
}
```

React 19 introduces **Actions** — a formal concept for exactly this pattern: an async function, typically triggered by a form submission, whose pending/error/result lifecycle React manages for you. `useActionState` (used throughout Parts 1, 3, and 4) is the hook that gives you this management directly, collapsing the three manual `useState` calls above into one hook call.

---

## `useActionState` — Full Reference

**Signature:** `const [state, formAction, isPending] = useActionState(action, initialState)`

- **`action`** — an async function with the signature `(previousState, formData) => Promise<newState>`. React calls this automatically whenever `formAction` is triggered (via a `<form action={formAction}>`, exactly as we used it in Part 4B's `ExportButton.tsx`).
- **`initialState`** — the value `state` holds before the action has ever run.
- **`state`** — always reflects whatever the `action` function most recently returned (or `initialState`, if it hasn't run yet).
- **`formAction`** — the wrapped version of your function, suitable for passing directly to a `<form>`'s `action` prop.
- **`isPending`** (the third, often-overlooked return value) — `true` while the action is currently running. Note: Part 4B's `ExportButton` used `useFormStatus`'s `pending` instead, for a specific reason explained below — but `useActionState` itself also exposes this same information directly, useful when you don't need the "nested component" separation `useFormStatus` requires.

**Where we used it:** Part 4B's `ExportButton.tsx` — wrapping `downloadExport()` so that clicking an export button automatically tracked `{ success, error }` as `state`, with zero manually-written `isLoading`/`error` `useState` pairs.

**A subtlety worth calling out:** `useActionState`'s `action` function does **not** need to be an actual Server Action (a function marked `"use server"`). Part 4B deliberately passed it a plain, client-side async function (since the real network call needed to be a `fetch()`, per Part 4A's Route Handler vs. Server Action decision) — `useActionState` manages the pending/result lifecycle around *any* async function, regardless of where that function's real work happens.

---

## `useFormStatus` — Full Reference

**Signature:** `const { pending, data, method, action } = useFormStatus()`

- **`pending`** — `true` while the nearest enclosing `<form>` is currently submitting.
- **`data`** — the `FormData` currently being submitted (useful for optimistically displaying "what was submitted" before the result comes back).
- **`method`** / **`action`** — the HTTP method and action reference of the enclosing form.

**The one non-negotiable rule, emphasized in Part 4B:** `useFormStatus` must be called from a component **nested inside** the `<form>` it's reporting on — never from the same component that renders the `<form>` tag itself. This is why Part 4B split `ExportButton` (which renders the `<form>`) from a separate inner `SubmitButton` component (which calls `useFormStatus`).

**Why use this instead of `useActionState`'s own `isPending`?** When you have multiple independent buttons, each needing its *own* independent pending state, without prop-drilling that state down manually. `useFormStatus` reads it directly from the nearest form ancestor, with zero props needed.

---

## `useOptimistic` — Full Reference

**Signature:** `const [optimisticState, setOptimisticState] = useOptimistic(baseState, updateFn?)`

- **`baseState`** — the "real," confirmed value. Once the surrounding async action completes and a genuine re-render occurs, `optimisticState` automatically reverts to reflect this real value.
- **`setOptimisticState`** — call this (wrapped in `startTransition`, as required by the API) to immediately, synchronously show an assumed value, ahead of any real confirmation.
- **`updateFn`** (optional second argument) — used when you need to *merge* the optimistic update with existing state (e.g., "append this new item to an existing list, before the server confirms it was saved") rather than simply replacing it.

**Where we used it:** Part 8B's `ExportButton.tsx` — flipping `isPreparing` to `true` the instant a button was clicked, before the network request had even begun, giving a "Preparing…" label distinct from `useFormStatus`'s network-bound "Exporting…" label.

**The React 18 equivalent, and why it's meaningfully worse:** You *could* approximate this with a plain `useState` set directly inside an `onClick` handler — but you'd be responsible for manually resetting it back to `false` yourself once the action completes, including correctly handling error cases. `useOptimistic`'s automatic reversion (tied to the surrounding action's actual completion) removes an entire category of "forgot to reset the loading flag on the error path" bugs.

---

## `use()` — Full Reference

**Signature:** `const value = use(promiseOrContext)`

`use()` is a genuinely new kind of React function — it can be called conditionally (inside an `if` statement, a loop, after an early `return`), unlike every other React Hook, which must always be called unconditionally at the top level of a component. It accepts either:

1. **A Promise** — `use()` will suspend the component (pause its rendering, showing a nearest `<Suspense>` fallback) until the Promise resolves, then return its resolved value directly, without you writing any `useEffect`/`useState` combination to manage the async lifecycle yourself.
2. **A Context object** — functionally equivalent to `useContext(SomeContext)`, but with the added flexibility of being callable conditionally.

**Honest note on this series:** GreyMatter MConvert did not end up needing `use()` directly — every asynchronous operation in our app was already well-served by `useActionState` (for form-triggered async work) or plain `async`/`await` inside Server Components (for server-side data needs, like `parseMarkdown` running directly and synchronously inside Server Actions). This is worth stating honestly rather than forcing an artificial use case into the tutorial: `use()` shines specifically for consuming a Promise created *outside* the current render (e.g., a data-fetching Promise created in a parent Server Component and passed down to a Client Component to `use()` and suspend on) — a pattern our app's architecture didn't require, since Part 4's Route Handler approach already cleanly separated "trigger a conversion" (a user action) from "load data for display" (which `use()` more directly targets).

---

## Quick Reference Table

| Hook | One-line purpose | Used in |
|---|---|---|
| `useActionState` | Manage pending/result state around an async action | Parts 1, 3, 4 |
| `useFormStatus` | Read the pending status of an ancestor `<form>`, from a nested component | Part 4B |
| `useOptimistic` | Show an assumed value immediately, ahead of confirmation | Part 8B |
| `use()` | Unwrap a Promise or read Context, callable conditionally | Not used in this series — noted for completeness |
| `useTransition` (React 18, still central here) | Mark a state update as low-priority/interruptible | Part 2C |

---

**Official documentation:** [react.dev/reference/react](https://react.dev/reference/react) — the "Hooks" section documents every API above individually, including additional edge cases (like `useActionState`'s behavior with nested forms) beyond what this series needed to cover.
