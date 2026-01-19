# 🟠 TanStack Tutorial

Building a modern React application in 2026 requires **robust state management, type-safe navigation, and scalable data architecture**. The **TanStack ecosystem** provides high-performance, type-safe tools that handle the "hard parts" of frontend development.

This tutorial walks you through creating a **Todo Management App** using **Query, Router, Table, and TanStack Start (SSR-ready)**.

---

## **Step 0️⃣: Understand TanStack**

| Library             | Purpose                                                                              |
| ------------------- | ------------------------------------------------------------------------------------ |
| **TanStack Query**  | Async state management: fetch, cache, and sync server data                           |
| **TanStack Router** | Type-safe routing with nested layouts and loaders                                    |
| **TanStack Table**  | Headless table for sorting, filtering, grouping without dictating CSS                |
| **TanStack Start**  | Full-stack meta framework (Vite-powered, SSR-ready) integrating Query, Router, Table |

> Focus: **type safety, server-side rendering (SSR), and optimized performance**

---

## **Step 1️⃣: Project Setup**

### Option 1: Recommended – TanStack Start

```bash
npx create-tanstack-app@latest
```

**Setup options:**

* Select **TanStack Start**
* Enable:

  * Query ✅
  * Router ✅
  * Table ✅
  * Tailwind (optional) ✅

Project structure created:

```
src/
 ├─ routes/
 ├─ components/
 ├─ api/
```

Providers (`QueryClientProvider` and `RouterProvider`) are preconfigured.

### Option 2: Manual Installation (React Projects)

```bash
npm install @tanstack/react-query @tanstack/react-router @tanstack/react-table
```

---

## **Step 2️⃣: Create a CRUD Todo App with Query**

### 2.1 API Functions (`src/api/todos.ts`)

```ts
export async function fetchTodos() {
  const res = await fetch('/api/todos');
  if (!res.ok) throw new Error('Failed to fetch todos');
  return res.json();
}

export async function addTodo(todo: { title: string }) {
  const res = await fetch('/api/todos', {
    method: 'POST',
    body: JSON.stringify(todo),
    headers: { 'Content-Type': 'application/json' },
  });
  return res.json();
}

export async function deleteTodo(id: number) {
  await fetch(`/api/todos/${id}`, { method: 'DELETE' });
}
```

### 2.2 Todo List Component (`src/components/TodoList.tsx`)

```tsx
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { fetchTodos, addTodo, deleteTodo } from '../api/todos';

export default function TodoList() {
  const queryClient = useQueryClient();

  const { data: todos = [], isLoading } = useQuery(['todos'], fetchTodos);

  const addMutation = useMutation(addTodo, {
    onSuccess: () => queryClient.invalidateQueries(['todos']),
  });

  const deleteMutation = useMutation(deleteTodo, {
    onSuccess: () => queryClient.invalidateQueries(['todos']),
  });

  if (isLoading) return <p>Loading...</p>;

  return (
    <div>
      <h2 className="text-lg font-bold">Todos</h2>
      <ul>
        {todos.map((t: any) => (
          <li key={t.id}>
            {t.title}
            <button onClick={() => deleteMutation.mutate(t.id)}>❌</button>
          </li>
        ))}
      </ul>
      <button
        className="mt-2 p-2 bg-blue-500 text-white rounded"
        onClick={() => addMutation.mutate({ title: 'New Task' })}
      >
        Add Todo
      </button>
    </div>
  );
}
```

---

## **Step 3️⃣: Add Router for Multiple Pages**

### 3.1 Routes (`src/routes/index.tsx`)

```tsx
import { createRoute, createRootRoute, Link, Outlet } from '@tanstack/react-router';
import TodoList from '../components/TodoList';

const rootRoute = createRootRoute({
  component: () => (
    <div className="p-4">
      <nav className="flex gap-4 mb-4">
        <Link to="/">Home</Link>
        <Link to="/todos">Todos</Link>
      </nav>
      <hr />
      <Outlet />
    </div>
  ),
});

const indexRoute = createRoute({ getParentRoute: () => rootRoute, path: '/' });
const todosRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/todos',
  component: TodoList,
});

export const routeTree = rootRoute.addChildren([indexRoute, todosRoute]);
```

### 3.2 Wrap App with Providers (`src/app.tsx`)

```tsx
import { RouterProvider } from '@tanstack/react-router';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { routeTree } from './routes';

const queryClient = new QueryClient();

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={routeTree} />
    </QueryClientProvider>
  );
}
```

---

## **Step 4️⃣: Upgrade List Views to Table**

### Todo Table Component (`src/components/TodoTable.tsx`)

```tsx
import { useReactTable, getCoreRowModel, flexRender } from '@tanstack/react-table';
import { useQuery } from '@tanstack/react-query';
import { fetchTodos } from '../api/todos';

export default function TodoTable() {
  const { data: todos = [] } = useQuery(['todos'], fetchTodos);

  const columns = [
    { accessorKey: 'id', header: 'ID' },
    { accessorKey: 'title', header: 'Title' },
  ];

  const table = useReactTable({
    data: todos,
    columns,
    getCoreRowModel: getCoreRowModel(),
  });

  return (
    <table className="w-full border">
      <thead>
        {table.getHeaderGroups().map(hg => (
          <tr key={hg.id}>
            {hg.headers.map(h => (
              <th key={h.id} className="border-b p-2">{flexRender(h.column.columnDef.header, h.getContext())}</th>
            ))}
          </tr>
        ))}
      </thead>
      <tbody>
        {table.getRowModel().rows.map(row => (
          <tr key={row.id}>
            {row.getVisibleCells().map(cell => (
              <td key={cell.id} className="p-2 border-b">{flexRender(cell.column.columnDef.cell, cell.getContext())}</td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

> Optional: Add **sorting/filtering** using `getSortedRowModel` and `getFilteredRowModel`.

---

## **Step 5️⃣: SSR and Server Functions with TanStack Start**

### Server Functions (`src/routes/api/todos.ts`)

```ts
import { createServerFunction } from '@tanstack/start/server';

let todos: { id: number; title: string }[] = [
  { id: 1, title: 'Learn TanStack' },
  { id: 2, title: 'Build Todo App' },
];

export const getTodos = createServerFunction(async () => todos);

export const addTodo = createServerFunction(async (input: { title: string }) => {
  const id = todos.length + 1;
  const newTodo = { id, title: input.title };
  todos.push(newTodo);
  return newTodo;
});

export const deleteTodo = createServerFunction(async (id: number) => {
  todos = todos.filter(t => t.id !== id);
  return true;
});
```

### Using Server Functions in Route Loader

```ts
import { getTodos } from './api/todos';
import { useLoaderData } from '@tanstack/react-router';

export const todosRoute = createRoute({
  path: '/todos',
  loader: async () => ({ todos: await getTodos() }),
  component: () => {
    const { todos } = useLoaderData();
    return <TodoTable data={todos} />;
  },
});
```

> Benefits: SSR-ready, type-safe server-client integration, no separate API endpoints needed.

---

## **Step 6️⃣: Recommended File Structure**

```
src/
 ├─ api/             # server API calls and query functions
 │    └─ todos.ts
 ├─ components/      # reusable UI components
 │    └─ TodoTable.tsx
 ├─ routes/          # TanStack Router definitions
 │    ├─ index.tsx
 │    └─ todos.tsx
 ├─ app.tsx          # root provider setup (Query + Router)
 └─ main.tsx         # app bootstrap
```

---

## **Step 7️⃣: Next Steps / Enhancements**

* Add **optimistic UI updates** for add/delete actions
* Integrate **pagination & filters** in tables
* Style UI with **Tailwind + headless components**
* Deploy SSR-ready app with **TanStack Start**

