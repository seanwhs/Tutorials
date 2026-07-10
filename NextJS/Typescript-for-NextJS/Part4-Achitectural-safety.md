# Type-Safe Horizons — Part 4: Advanced Architectural Safety

*Series: Type-Safe Horizons. Prerequisite: Parts 1-3 (Task type, prop typing, Server Actions/Prisma).*

## Safety Check: The Anti-Pattern

```tsx
function DataTable({ columns, data }: { columns: any[]; data: any[] }) {
  return (
    <table>
      <thead>
        <tr>
          {columns.map((col) => <th key={col.key}>{col.label}</th>)}
        </tr>
      </thead>
      <tbody>
        {data.map((row, i) => (
          <tr key={i}>
            {columns.map((col) => <td key={col.key}>{row[col.key]}</td>)}
          </tr>
        ))}
      </tbody>
    </table>
  );
}

function assignTask(taskId: string, userId: string) {
  db.task.update({ where: { id: taskId }, data: { assigneeId: userId } });
}

const post = await db.post.findFirst();
assignTask(post.id, someTask.id); // WRONG ORDER — both are just `string`, compiles fine
```

Two distinct anti-patterns: `DataTable`'s `any[]` columns/data means a typo in `col.key` or a mismatched column/data shape between two unrelated tables is invisible to the compiler — you get one non-generic, non-reusable, unsafe table instead of a real reusable component. And `assignTask(post.id, someTask.id)` — a **PostId passed where a UserId belongs** — compiles perfectly, because both are just `string` at the type level. TypeScript's structural typing means any two `string`s are interchangeable, no matter what real-world entity they represent. This class of bug is invisible until the wrong row gets updated in production.

## Type Logic

**Generics** solve the `DataTable` problem: instead of `any[]`, a type parameter `<T>` lets the component say "I work with an array of *some* row type `T`, and my `columns` must describe keys that actually exist on `T`" — reusable *and* checked, simultaneously.

**Brand types (nominal typing)** solve the `UserId`/`PostId` problem. TypeScript is structurally typed by default — two types with the same shape are considered the same type. A "brand" attaches a unique, uninhabited phantom property to an otherwise-plain type, so two strings with different brands become structurally incompatible even though both compile down to plain strings at runtime. This is the standard technique for simulating nominal typing in a structural type system.

## Refactored Solution

### 1. A generic, reusable `DataTable<T>`

```tsx
interface Column<T> {
  key: keyof T;
  label: string;
  render?: (value: T[keyof T], row: T) => React.ReactNode;
}

interface DataTableProps<T> {
  columns: Column<T>[];
  data: T[];
  getRowId: (row: T) => string;
}

function DataTable<T>({ columns, data, getRowId }: DataTableProps<T>) {
  return (
    <table>
      <thead>
        <tr>
          {columns.map((col) => (
            <th key={String(col.key)}>{col.label}</th>
          ))}
        </tr>
      </thead>
      <tbody>
        {data.map((row) => (
          <tr key={getRowId(row)}>
            {columns.map((col) => (
              <td key={String(col.key)}>
                {col.render ? col.render(row[col.key], row) : String(row[col.key])}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

`key: keyof T` means `columns` can only reference properties that actually exist on the row type — reusing `Task` from Part 1:

```tsx
import type { Task } from "@/types/task";

const columns: Column<Task>[] = [
  { key: "title", label: "Title" },
  { key: "status", label: "Status", render: (value) => <StatusBadge status={value as Task["status"]} /> },
  // { key: "titel", label: "Typo" }, // compile error — "titel" is not keyof Task
];

<DataTable columns={columns} data={tasks} getRowId={(t) => t.id} />;
```

Swap `Task` for any other row shape — a `User`, an `Order` — and the same `DataTable<T>` component works, fully checked, with zero duplication.

### 2. A generic `Select<T>`

```tsx
interface SelectOption<T> {
  value: T;
  label: string;
}

interface SelectProps<T extends string> {
  options: SelectOption<T>[];
  value: T;
  onChange: (value: T) => void;
}

function Select<T extends string>({ options, value, onChange }: SelectProps<T>) {
  return (
    <select value={value} onChange={(e) => onChange(e.target.value as T)}>
      {options.map((opt) => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  );
}

// Usage — T is inferred as Task["status"], onChange is fully typed:
<Select<Task["status"]>
  value={task.status}
  onChange={(status) => updateStatus(status)}
  options={[
    { value: "todo", label: "Todo" },
    { value: "in-progress", label: "In Progress" },
    { value: "done", label: "Done" },
  ]}
/>;
```

`T extends string` constrains the generic to string-literal unions specifically (matching Part 1's `TaskStatus`/`TaskPriority` pattern), so `onChange` receives the exact literal type, not a widened `string`.

### 3. Brand types to prevent ID mix-ups

```ts
// types/brand.ts
declare const brand: unique symbol;
export type Brand<T, B extends string> = T & { readonly [brand]: B };

// types/ids.ts
import type { Brand } from "./brand";

export type UserId = Brand<string, "UserId">;
export type PostId = Brand<string, "PostId">;
export type TaskId = Brand<string, "TaskId">;
```

The `unique symbol` field never exists at runtime — it's a type-level-only marker. This means `UserId` and `PostId` both compile to plain strings (zero runtime cost, zero serialization concerns), but the TypeScript compiler now treats them as structurally distinct types.

Constructing branded values safely, at the one place data enters the system:

```ts
export function toUserId(id: string): UserId {
  return id as UserId;
}

export function toPostId(id: string): PostId {
  return id as PostId;
}
```

The cast (`as UserId`) is intentional and safe *only* at this single boundary function — everywhere else in the codebase, values arrive already branded and the cast is never repeated.

### 4. Applying brands to the Part 3 data layer

```ts
import type { UserId, TaskId } from "@/types/ids";

export interface Task {
  id: TaskId;
  title: string;
  status: "todo" | "in-progress" | "done";
  priority: "low" | "medium" | "high";
  assigneeId: UserId | null;
  dueDate: Date | null;
}

function assignTask(taskId: TaskId, userId: UserId) {
  db.task.update({ where: { id: taskId }, data: { assigneeId: userId } });
}

declare const post: { id: string };
declare const someTask: { id: TaskId };

// assignTask(toPostId(post.id), someTask.id); // ← compile error: PostId not assignable to UserId
assignTask(someTask.id, toUserId(post.id)); // must go through the boundary function to even attempt it, and the types still won't match a real PostId
```

The bug from the top of this lesson — a `PostId` silently accepted where a `UserId` belongs — is now a compile error, not a production incident. This is the direct architectural payoff of everything from Parts 1-3: precise literal unions, validated boundaries, and now nominally distinct identity types.

## Exercise Challenge

Using the `Brand<T, B>` utility above, create a `WorkspaceId` brand type and refactor a `getWorkspaceTasks(workspaceId: WorkspaceId)` function signature so that passing a raw, unbranded `string` (e.g., straight from `searchParams`) is a compile error unless it's first passed through a `toWorkspaceId()` boundary function.

## Solution

```ts
export type WorkspaceId = Brand<string, "WorkspaceId">;

export function toWorkspaceId(id: string): WorkspaceId {
  return id as WorkspaceId;
}

async function getWorkspaceTasks(workspaceId: WorkspaceId) {
  return db.task.findMany({ where: { workspaceId } });
}

// In a Server Component reading a Next.js 16 typed param:
interface PageProps {
  params: Promise<{ workspaceId: string }>;
}

export default async function WorkspacePage({ params }: PageProps) {
  const { workspaceId } = await params;
  const tasks = await getWorkspaceTasks(toWorkspaceId(workspaceId));
  // getWorkspaceTasks(workspaceId) directly — compile error, raw string isn't WorkspaceId
  return <DataTable columns={taskColumns} data={tasks} getRowId={(t) => t.id} />;
}
```

The `toWorkspaceId()` call is the single, intentional, auditable point where an untrusted route param becomes a trusted domain identity — exactly mirroring the Zod validation boundary from Part 3, but for identity rather than shape.

## TypeScript Tip: brand your generics together

When a generic component's type parameter should itself be constrained to a specific domain concept (not just `string`), constrain it directly:

```ts
function useTaskAssignment<TUserId extends UserId>(userId: TUserId) {
  // ...
}
```

Combined with `satisfies` (Part 1) for config/registry objects, discriminated unions (Part 1) for state, `ComponentPropsWithoutRef` (Part 2) for native element inheritance, Zod-derived types (Part 3) for boundary validation, and brand types (this part) for identity safety — this five-part toolkit is sufficient to eliminate the overwhelming majority of `any`-driven runtime bugs in a real Next.js 16 codebase.

---
**Previous:** Part 3: The Data Boundary — Server Components, Server Actions, Prisma/Drizzle, Zod
**Series complete.** 🎉
