# **Module 1: The New Lifecycle — Migrating from State to Actions**:

---

## Concept Explanation

For years, the standard React mutation pattern was: `useState` for input value, `useState` for loading, `useState` for error, and an `onSubmit` handler that manually manages all three with try/catch/finally.

React 19 introduces **Actions** — functions React itself knows how to run and track. Paired with `useActionState`, React manages pending state and "last result" state *for you*.

**Key terms:**
- **Action:** any function passed to `useActionState`, or set as `<form action={fn}>`
- **Server Action:** an Action with `"use server"` — executes on the server, callable from client code, no hand-written API route needed
- **`useActionState(action, initialState)`:** returns `[state, formAction, isPending]`

## Implementation

**Step 1 — The old way (for comparison):** Classic `useState`×3 + `onSubmit` + try/catch/finally pattern shown in full.

**Step 2 — Define a Server Action** (`src/actions/tasks.ts`):
```ts
"use server";
import { addTask } from "@/lib/db";
import { revalidatePath } from "next/cache";
import { z } from "zod";

const TaskSchema = z.object({
  title: z.string().min(3, "Title must be at least 3 characters").max(80),
});

export type TaskActionState = {
  success: boolean;
  message: string | null;
  fieldErrors?: { title?: string[] };
};

export async function createTaskAction(_prevState: TaskActionState, formData: FormData): Promise<TaskActionState> {
  const parsed = TaskSchema.safeParse({ title: formData.get("title") });
  if (!parsed.success) {
    return { success: false, message: "Please fix the errors below.", fieldErrors: parsed.error.flatten().fieldErrors };
  }
  await addTask(parsed.data.title);
  revalidatePath("/module-1-actions");
  return { success: true, message: "Task added!" };
}
```

**Step 3 — Consume with `useActionState`** in a `TaskForm` client component — no `useState`, no manual try/catch.

**Step 4 — Wire into a Server Component page** — `revalidatePath` auto-refreshes the list, zero client cache-invalidation code.

**Step 5 — Non-form Actions via `useTransition`** — a `TaskRow` component that toggles "done" using `startTransition(() => toggleTaskAction(task.id))`.

## Exercise: Challenge
Build a delete-task feature: add `deleteTaskAction`, wire it into `TaskRow` via `useTransition` with per-row "deleting…" state, and explain why per-row pending indicators work automatically.

## Solution
Full `deleteTaskAction` + updated `TaskRow` with separate `isTogglePending`/`isDeletePending` transitions. Explanation: `useTransition` state is local to each component *instance* (keyed to its fiber), so each `<TaskRow>` in a list has its own independent pending flags — no shared "which row is loading" state variable needed.
