# Part 2: The Data Fetching and Form Muddle

## The Habit You Need to Break

For years, the default way to fetch data in a component was `useEffect` plus a trio of `useState` calls for `data`, `isLoading`, and `error`. For forms, you wired up `onSubmit`, called `event.preventDefault()`, ran your own validation, and manually tracked submission state.

React 19 replaces both of these with the **Actions** model: Server Actions plus `useActionState`, `useFormStatus`, and `useOptimistic`. This part shows why the old approach breaks in subtle ways, and how the new hooks remove entire categories of bugs.

---

## 1. The Anti-Pattern: Data Fetching with useEffect

```tsx
// components/UserProfile.tsx (React 18 style - DO NOT COPY)
"use client";

import { useState, useEffect } from "react";

interface User {
  id: string;
  name: string;
  email: string;
}

export default function UserProfile({ userId }: { userId: string }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchUser() {
      setIsLoading(true);
      setError(null);
      try {
        const res = await fetch("/api/users/" + userId);
        if (!res.ok) throw new Error("Failed to load user");
        const data = await res.json();
        if (!cancelled) setUser(data);
      } catch (err) {
        if (!cancelled) setError((err as Error).message);
      } finally {
        if (!cancelled) setIsLoading(false);
      }
    }

    fetchUser();

    return () => {
      cancelled = true;
    };
  }, [userId]);

  if (isLoading) return <p>Loading...</p>;
  if (error) return <p>Error: {error}</p>;
  if (!user) return null;

  return (
    <div>
      <h2>{user.name}</h2>
      <p>{user.email}</p>
    </div>
  );
}
```

### Why This Feels "Right" But Isn't
- You need a `cancelled` flag to avoid setting state on an unmounted component or after a newer request resolves. Easy to forget, easy to get wrong.
- React Strict Mode intentionally double-invokes effects in development, causing duplicate fetches unless you handle cleanup correctly.
- Every component that fetches data re-implements the same `isLoading`/`error`/`data` boilerplate.
- Data fetching does not start until after the component mounts and the effect runs, creating **request waterfalls** (child waits for parent to render before it can even start fetching).
- Nothing here is server-renderable. This is 100% client-side JavaScript shipped to the browser just to fetch data that could have been fetched during the initial server render.

---

## 2. The Anti-Pattern: Manual Form State

```tsx
// components/LoginForm.tsx (React 18 style - DO NOT COPY)
"use client";

import { useState } from "react";

export default function LoginForm() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const res = await fetch("/api/login", {
        method: "POST",
        body: JSON.stringify({ email, password }),
      });
      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.message ?? "Login failed");
      }
      window.location.href = "/dashboard";
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Email" />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
      />
      {error && <p style={{ color: "red" }}>{error}</p>}
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "Logging in..." : "Log In"}
      </button>
    </form>
  );
}
```

### The Problem, Explained Simply
- `isSubmitting` has to be manually threaded into the submit button. If the button lives in a separate component, you need to prop-drill it.
- Every form re-implements the same submit/error/pending dance.
- No progressive enhancement: if JavaScript hasn't loaded yet, the form does nothing when submitted.
- No built-in support for optimistic UI (showing the result before the server confirms it).

---

## 3. The Modern React 19 Solution

### Step 1: Define a Server Action

```ts
// app/actions/auth.ts
"use server";

export type LoginState = {
  error: string | null;
};

export async function loginAction(
  _prevState: LoginState,
  formData: FormData
): Promise<LoginState> {
  const email = formData.get("email") as string;
  const password = formData.get("password") as string;

  if (!email || !password) {
    return { error: "Email and password are required." };
  }

  const res = await fetch("https://api.example.com/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    return { error: "Invalid credentials." };
  }

  // On success, redirect (throws internally, does not return)
  const { redirect } = await import("next/navigation");
  redirect("/dashboard");
}
```

### Step 2: Wire It Up with useActionState

```tsx
// components/LoginForm.tsx (React 19)
"use client";

import { useActionState } from "react";
import { loginAction, type LoginState } from "@/app/actions/auth";
import SubmitButton from "@/components/SubmitButton";

const initialState: LoginState = { error: null };

export default function LoginForm() {
  const [state, formAction] = useActionState(loginAction, initialState);

  return (
    <form action={formAction}>
      <input name="email" placeholder="Email" />
      <input name="password" type="password" placeholder="Password" />
      {state.error && <p style={{ color: "red" }}>{state.error}</p>}
      <SubmitButton />
    </form>
  );
}
```

`useActionState` gives you `[state, formAction]`: `state` is whatever your Server Action returns, and `formAction` is passed directly to the form's `action` prop. React manages pending status, request sequencing, and re-invocation for you.

### Step 3: A Reusable Submit Button with useFormStatus

```tsx
// components/SubmitButton.tsx
"use client";

import { useFormStatus } from "react-dom";

export default function SubmitButton() {
  const { pending } = useFormStatus();

  return (
    <button type="submit" disabled={pending}>
      {pending ? "Logging in..." : "Log In"}
    </button>
  );
}
```

`useFormStatus` must be called from a component **rendered inside** the `<form>` — it reads the pending state of the nearest parent form automatically. No props passed down. Drop this component into any form in your app and it just works.

### Step 4: Instant UI Feedback with useOptimistic

```tsx
// components/TodoList.tsx
"use client";

import { useOptimistic, useRef } from "react";
import { addTodoAction } from "@/app/actions/todos";

interface Todo {
  id: string;
  text: string;
  pending?: boolean;
}

export default function TodoList({ todos }: { todos: Todo[] }) {
  const formRef = useRef<HTMLFormElement>(null);

  const [optimisticTodos, addOptimisticTodo] = useOptimistic(
    todos,
    (state, newText: string) => [
      ...state,
      { id: crypto.randomUUID(), text: newText, pending: true },
    ]
  );

  async function handleSubmit(formData: FormData) {
    const text = formData.get("text") as string;
    addOptimisticTodo(text);
    formRef.current?.reset();
    await addTodoAction(formData);
  }

  return (
    <div>
      <ul>
        {optimisticTodos.map((todo) => (
          <li key={todo.id} style={{ opacity: todo.pending ? 0.5 : 1 }}>
            {todo.text} {todo.pending && "(saving...)"}
          </li>
        ))}
      </ul>
      <form ref={formRef} action={handleSubmit}>
        <input name="text" placeholder="New todo" />
        <button type="submit">Add</button>
      </form>
    </div>
  );
}
```

The list updates **immediately** when the user submits, showing a "saving..." state, then reconciles with the real server response once `addTodoAction` completes. If the action fails, React automatically reverts to the last confirmed state.

---

## 4. Migration Steps

1. **Identify every `useEffect` whose only job is fetching data on mount.** Move that fetch into a Server Component (`async function Page()`), or a `route.ts` handler consumed by a Server Action.
2. **Replace manual `onSubmit` handlers** with a Server Action passed to the form's `action` prop.
3. **Wrap the action with `useActionState`** if you need to read return values (validation errors, success messages) on the client.
4. **Extract submit buttons into their own component** using `useFormStatus` instead of prop-drilling an `isSubmitting` boolean.
5. **Add `useOptimistic`** anywhere the UI can safely predict the outcome of an action (adding a list item, toggling a flag, incrementing a counter).
6. **Delete the `cancelled` flags, manual `isLoading`/`error` state, and try/catch/finally blocks** that Actions now handle for you.

---

## Quick Checklist

- [ ] No `useEffect` used purely to fetch data on mount
- [ ] Forms use `action={serverAction}` instead of `onSubmit={handler}`
- [ ] `useActionState` used wherever the client needs the action's return value
- [ ] Submit buttons use `useFormStatus`, not prop-drilled pending flags
- [ ] Optimistic UI (`useOptimistic`) used for any instantly-predictable mutation
- [ ] Server Actions marked with `"use server"` at the top of the file or function
- [ ] Manual `isLoading`/`error` state removed in favor of Action-returned state

**Next:** Part 3: The Component Bloat — retiring `forwardRef` and prop-drilling with "ref as a prop" and the `use` API.
