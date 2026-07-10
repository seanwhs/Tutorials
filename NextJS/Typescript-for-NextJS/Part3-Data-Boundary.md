# Type-Safe Horizons — Part 3: The Data Boundary

*Series: Type-Safe Horizons. Prerequisite: Part 1 (Task type, unions, utility types), Part 2 (component prop typing).*

## Safety Check: The Anti-Pattern

```tsx
export default async function TaskPage({ params }: { params: any }) {
  const { id } = await params;
  const task = await db.task.findUnique({ where: { id } });
  return <TaskEditForm task={task as any} />;
}

function TaskEditForm({ task }: { task: any }) {
  async function handleSubmit(formData: FormData) {
    "use server";
    await db.task.update({
      where: { id: task.id },
      data: {
        title: formData.get("title"),
        status: formData.get("status"),
      },
    });
  }
  return <form action={handleSubmit}>{}</form>;
}
```

Three compounding failures, all `any`-shaped: `params: any` throws away Next.js 16's own typed route params, so a typo in a dynamic segment goes uncaught; `task as any` means the database result flows into the form with zero verification that `findUnique` didn't return `null`; and `formData.get("title")` returns `FormDataEntryValue | null` (string, File, or null), passed directly into `data: { title: ... }` where Prisma either throws a confusing runtime error or silently accepts a `File` where a string was expected.

## Type Logic

Derive types from a single source of truth — the schema — rather than hand-writing parallel interfaces that drift out of sync. Prisma and Drizzle both generate/infer types directly from the schema definition, so `Task` as a TypeScript type and `Task` as a database table are structurally guaranteed to agree. Layer three zones on top of that generated base: the **full row type** (what the database returns), a **projection** (`Pick`/`Omit`, matching Part 1) for what the client actually needs, and a **validated input type** (Zod) for anything crossing the untrusted client-to-server boundary, since `FormData` and `searchParams` are runtime strings no matter what your TypeScript types claim.

## Refactored Solution

### 1. Schema-derived base type (Prisma)

```prisma
model Task {
  id         String   @id @default(cuid())
  title      String
  status     String   @default("todo")
  priority   String   @default("medium")
  assigneeId String?
  dueDate    DateTime?
}
```

```ts
import type { Task as PrismaTask } from "@prisma/client";

export type TaskStatus = "todo" | "in-progress" | "done";
export type TaskPriority = "low" | "medium" | "high";

export type Task = Omit<PrismaTask, "status" | "priority"> & {
  status: TaskStatus;
  priority: TaskPriority;
};
```

Prisma's client generates `status`/`priority` as plain `string` since Prisma has no native enum-as-literal-union feature for this shape; re-narrowing those two fields with `Omit` + intersection gives back the literal-union safety from Part 1 while still deriving every other field from the real schema.

Drizzle equivalent, which supports literal unions natively via `pgEnum` and needs no re-narrowing step:

```ts
import { pgTable, text, timestamp, pgEnum } from "drizzle-orm/pg-core";
import type { InferSelectModel } from "drizzle-orm";

export const taskStatusEnum = pgEnum("task_status", ["todo", "in-progress", "done"]);
export const taskPriorityEnum = pgEnum("task_priority", ["low", "medium", "high"]);

export const tasks = pgTable("tasks", {
  id: text("id").primaryKey(),
  title: text("title").notNull(),
  status: taskStatusEnum("status").notNull().default("todo"),
  priority: taskPriorityEnum("priority").notNull().default("medium"),
  assigneeId: text("assignee_id"),
  dueDate: timestamp("due_date"),
});

export type Task = InferSelectModel<typeof tasks>;
```

### 2. Typed Server Component with Next.js 16 async params

```tsx
interface TaskPageProps {
  params: Promise<{ id: string }>;
}

export default async function TaskPage({ params }: TaskPageProps) {
  const { id } = await params;
  const task = await db.task.findUnique({ where: { id } });

  if (!task) {
    notFound();
  }

  return <TaskEditForm task={task} />;
}
```

`task` is narrowed from `Task | null` to `Task` after the `notFound()` early return — no `as any`, no unchecked null access downstream.

### 3. Validating the untrusted boundary with Zod

```ts
import { z } from "zod";

export const taskUpdateSchema = z.object({
  title: z.string().min(1, "Title is required"),
  status: z.enum(["todo", "in-progress", "done"]),
  priority: z.enum(["low", "medium", "high"]),
});

export type TaskUpdateInput = z.infer<typeof taskUpdateSchema>;
```

`z.infer<typeof taskUpdateSchema>` derives a TypeScript type straight from the runtime validator, so the compile-time type and the runtime check can never disagree the way a hand-written interface next to a separate validation function can.

### 4. The Server Action, fully typed end to end

```ts
"use server";

import { taskUpdateSchema } from "@/lib/validation/task";
import { db } from "@/lib/db";
import { revalidatePath } from "next/cache";

export type ActionResult =
  | { status: "success" }
  | { status: "error"; message: string; fieldErrors?: Record<string, string[]> };

export async function updateTask(taskId: string, formData: FormData): Promise<ActionResult> {
  const parsed = taskUpdateSchema.safeParse({
    title: formData.get("title"),
    status: formData.get("status"),
    priority: formData.get("priority"),
  });

  if (!parsed.success) {
    return {
      status: "error",
      message: "Validation failed",
      fieldErrors: parsed.error.flatten().fieldErrors,
    };
  }

  await db.task.update({ where: { id: taskId }, data: parsed.data });
  revalidatePath(`/tasks/${taskId}`);
  return { status: "success" };
}
```

`parsed.data` is `TaskUpdateInput`, not `FormData` entries — every field is a guaranteed `string` matching the enum, because `safeParse` did the runtime narrowing. `ActionResult` is a discriminated union, directly reusing the pattern from Part 1: the client never has to guess whether `fieldErrors` exists, it's only present on the `"error"` branch.

### 5. Flowing the type into the client form

```tsx
"use client";

import { useActionState } from "react";
import { updateTask, type ActionResult } from "@/app/actions/task";
import type { Task } from "@/types/task";

function TaskEditForm({ task }: { task: Task }) {
  const [state, formAction] = useActionState<ActionResult, FormData>(
    (_prevState, formData) => updateTask(task.id, formData),
    { status: "success" }
  );

  return (
    <form action={formAction}>
      <input name="title" defaultValue={task.title} />
      <select name="status" defaultValue={task.status}>
        <option value="todo">Todo</option>
        <option value="in-progress">In Progress</option>
        <option value="done">Done</option>
      </select>
      {state.status === "error" && (
        <p role="alert">{state.message}</p>
      )}
    </form>
  );
}
```

`task: Task` is the same schema-derived type from step 1 — no re-declaration, no drift. `state.status === "error"` narrows `state` so `state.message` is accessible only where it actually exists, exactly like the `RequestState` pattern from Part 1.

## Exercise Challenge

Add a `createTask` Server Action for a "new task" form. It should: validate input with a Zod schema derived from `taskUpdateSchema` (hint: use `.pick()` if only `title` and `priority` are collected at creation time), return the same `ActionResult` union, and use `Omit<Task, "id" | "dueDate">` server-side for the insert payload shape.

## Solution

```ts
export const taskCreateSchema = taskUpdateSchema.pick({ title: true, priority: true });
export type TaskCreateInput = z.infer<typeof taskCreateSchema>;

export async function createTask(formData: FormData): Promise<ActionResult> {
  const parsed = taskCreateSchema.safeParse({
    title: formData.get("title"),
    priority: formData.get("priority"),
  });

  if (!parsed.success) {
    return { status: "error", message: "Validation failed", fieldErrors: parsed.error.flatten().fieldErrors };
  }

  await db.task.create({
    data: { ...parsed.data, status: "todo", assigneeId: null, dueDate: null },
  });

  revalidatePath("/tasks");
  return { status: "success" };
}
```

Zod's own `.pick()` mirrors TypeScript's `Pick<T, K>` from Part 1 — the same mental model applies at the runtime-validation layer, not just the type layer.

## TypeScript Tip: `z.infer` beats hand-written DTOs

Whenever a Zod schema exists at a boundary, derive its TypeScript type with `z.infer<typeof schema>` rather than writing a parallel `interface`. Two independent definitions of "what a valid task update looks like" will drift the moment one changes and the other doesn't — `z.infer` makes that drift structurally impossible, the same way Prisma/Drizzle's generated types make schema/type drift impossible for your database models.

---
**Previous:** Part 2: The Component Layer — ReactNode, forwardRef, ComponentPropsWithoutRef
**Next:** Part 4: Advanced Architectural Safety — Generics and Brand Types
