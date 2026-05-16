# 🧠 Runtime-Native Full-Stack Workshop

## Bun + React Kanban System (Hono vs Elysia + Eden)

---

# 🧭 0. What You Are Actually Building

You are not building a Kanban app.

You are building a **runtime-native system design prototype**.

In this system:

* Bun is not a tool → it is the **execution boundary**
* Backend is not a server → it is a **state engine**
* Frontend is not an app → it is a **state projection layer**
* Shared code is not utilities → it is the **truth contract**

---

## 🧠 Core Insight

> You are not composing tools.
> You are defining a single system with multiple perspectives.

---

# 🧠 1. High-Resolution Mental Model

## ❌ Traditional Architecture (Tool Composition)

```
Frontend → Backend API → Database
(each layer is independent infrastructure)
```

Problems:

* API drift
* duplicated schemas
* fragile integration points
* high operational overhead

---

## ✅ Runtime-Native Architecture (System Composition)

```
              [ Bun Runtime Boundary ]
                        |
        ┌───────────────┼────────────────┐
        |               |                |
        v               v                v
 Backend State     Shared Truth     Frontend UI
 (behavior)        (contracts)      (projection)
```

---

## 🧠 Principle #1

> The runtime is the system.

Everything else is just a role inside it.

---

# 🧱 2. Project Setup (System Boundary Creation)

## 📦 Create Project

```bash
mkdir bun-kanban
cd bun-kanban
bun init
```

---

## 🧠 What this really means

You are defining:

> A single execution boundary for an entire software system.

Not a project.

A **runtime domain**.

---

## 📁 System Structure

```bash
mkdir -p packages/backend/src
mkdir -p packages/frontend/src
mkdir -p packages/shared
```

---

## 🧠 Why this structure exists

| Layer    | Meaning                            |
| -------- | ---------------------------------- |
| backend  | system behavior (state + mutation) |
| frontend | system projection (UI rendering)   |
| shared   | system truth (contracts)           |

---

# ⚙️ 3. System Control Layer (Workspace)

## 📄 `package.json`

```json
{
  "name": "bun-kanban",
  "private": true,
  "workspaces": ["packages/*"],
  "scripts": {
    "dev:backend": "bun --watch packages/backend/src/index.ts",
    "dev:frontend": "bun --watch packages/frontend/src/dev.ts"
  }
}
```

---

## 🧠 Mental Model

This is not configuration.

It is your:

> system boot orchestration layer

---

## 🧠 Principle #2

> Scripts are system commands, not build steps.

---

# 🧠 4. Type System Alignment

## 📄 `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true,
    "baseUrl": ".",
    "paths": {
      "@shared": ["packages/shared/index.ts"]
    }
  }
}
```

---

## 🧠 Why this matters

You are enforcing:

> a single source of truth across runtime boundaries

---

# 🧩 5. Shared Truth Contract (Core System Definition)

## 📄 `packages/shared/index.ts`

```ts
export const TaskStatus = {
  TODO: "TODO",
  DOING: "DOING",
  DONE: "DONE"
} as const;

export type TaskStatus =
  typeof TaskStatus[keyof typeof TaskStatus];

export type Task = {
  id: string;
  title: string;
  description?: string;
  status: TaskStatus;
  createdAt: string;
};
```

---

## 🧠 Mental Model

This file defines:

> the constitution of your system

Everything else depends on it.

---

## 🧠 Why this is critical

Without it:

* frontend guesses types
* backend evolves independently
* bugs emerge silently

With it:

> the system becomes self-consistent by design

---

# ⚙️ 6. Backend v1 — State Engine (No Framework)

## 📄 `packages/backend/src/index.ts`

```ts
import { type Task, TaskStatus } from "@shared";

const tasks: Task[] = [];

console.log("🚀 Runtime-native state engine running at http://localhost:3000");

Bun.serve({
  port: 3000,

  async fetch(req) {
    const url = new URL(req.url);

    // READ STATE
    if (url.pathname === "/api/tasks" && req.method === "GET") {
      return Response.json(tasks);
    }

    // WRITE STATE
    if (url.pathname === "/api/tasks" && req.method === "POST") {
      const body = await req.json() as {
        title: string;
        description?: string;
      };

      const task: Task = {
        id: crypto.randomUUID(),
        title: body.title,
        description: body.description,
        status: TaskStatus.TODO,
        createdAt: new Date().toISOString()
      };

      tasks.push(task);

      return Response.json(task);
    }

    return new Response("Not found", { status: 404 });
  }
});
```

---

## 🧠 Mental Model

You now have:

* state
* API
* mutation logic

WITHOUT:

* Express
* ORM
* database
* framework

---

## 🧠 Principle #3

> State lives inside the runtime until explicitly externalized.

---

# 🧪 7. Backend Verification

```bash
bun run dev:backend
```

Test:

```bash
curl http://localhost:3000/api/tasks
```

Then:

```bash
curl -X POST http://localhost:3000/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title":"learn runtime-native systems"}'
```

---

# 🧭 8. Frontend Mental Model (Critical Shift)

The frontend is NOT:

* a separate system
* a separate app
* a separate runtime

It is:

> a projection of backend state

---

## Diagram

```
[Bun Runtime]
     ↓
[React UI]
     ↓
User sees state projection
```

---

# 🧱 9. React UI Layer

## 📦 Install

```bash
cd packages/frontend
bun add react react-dom
```

---

## 📄 `main.tsx`

```tsx
import React from "react";
import ReactDOM from "react-dom/client";
import { App } from "./App";

ReactDOM.createRoot(document.getElementById("root")!)
  .render(<App />);
```

---

## 📄 `App.tsx`

```tsx
import React, { useEffect, useState } from "react";
import type { Task } from "@shared";

const API = "http://localhost:3000";

export function App() {
  const [tasks, setTasks] = useState<Task[]>([]);
  const [title, setTitle] = useState("");

  async function load() {
    const res = await fetch(`${API}/api/tasks`);
    setTasks(await res.json());
  }

  useEffect(() => {
    load();
  }, []);

  async function createTask() {
    await fetch(`${API}/api/tasks`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title })
    });

    setTitle("");
    load();
  }

  return (
    <div style={{ padding: 20 }}>
      <h1>Runtime Kanban</h1>

      <input
        value={title}
        onChange={e => setTitle(e.target.value)}
        placeholder="New task"
      />
      <button onClick={createTask}>Add</button>

      {tasks.map(t => (
        <div key={t.id}>
          <strong>{t.title}</strong> — {t.status}
        </div>
      ))}
    </div>
  );
}
```

---

## 🧠 Mental Model Upgrade

React is NOT:

* state manager
* controller
* backend client layer

React IS:

> a rendering surface for runtime truth

---

# 🟡 10. SQLite Upgrade (Persistent Runtime State)

We evolve:

> RAM state → persistent system state

---

## 📦 Install

```bash
bun add bun:sqlite
```

---

## 📄 `db.ts`

```ts
import { Database } from "bun:sqlite";

export const db = new Database("kanban.db");

db.exec(`
CREATE TABLE IF NOT EXISTS tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL,
  createdAt TEXT NOT NULL
);
`);
```

---

## 📄 Repository Layer

```ts
import { db } from "./db";
import type { Task } from "@shared";

export const TaskRepo = {
  findAll(): Task[] {
    return db.query("SELECT * FROM tasks").all() as Task[];
  },

  create(task: Task) {
    db.query(`
      INSERT INTO tasks (id, title, description, status, createdAt)
      VALUES (?, ?, ?, ?, ?)
    `).run(
      task.id,
      task.title,
      task.description,
      task.status,
      task.createdAt
    );
  }
};
```

---

## 🧠 Mental Model

You introduced a controlled boundary:

> backend no longer owns state — it owns persistence behavior

---

# 🔴 11. Masterclass Upgrade — Elysia + Eden

Now we evolve into:

> a type-safe runtime graph

---

## 📦 Install

```bash
bun add elysia @elysiajs/eden
```

---

## 📄 Backend (Elysia)

```ts
import { Elysia } from "elysia";
import { TaskRepo } from "./repository";
import { TaskStatus } from "@shared";

const app = new Elysia()
  .group("/api", app =>
    app
      .get("/tasks", () => TaskRepo.findAll())

      .post("/tasks", ({ body }) => {
        const task = {
          id: crypto.randomUUID(),
          title: body.title,
          status: TaskStatus.TODO,
          createdAt: new Date().toISOString()
        };

        TaskRepo.create(task);
        return task;
      })
  )
  .listen(3000);

export type App = typeof app;
```

---

## 📄 Frontend (Eden Treaty)

```ts
import { edenTreaty } from "@elysiajs/eden";
import type { App } from "../../backend/src/index";

const api = edenTreaty<App>("http://localhost:3000");
```

---

## 🧠 Final Upgrade

Now you call:

```ts
api.api.tasks.get()
api.api.tasks.post()
```

NOT:

```ts
fetch("/api/tasks")
```

---

## 🧠 Why this matters

You eliminated:

* API drift
* schema duplication
* runtime mismatch risk
* manual typing

---

# 🧠 FINAL SYSTEM EVOLUTION MAP

```
Phase 1 → React projection layer
Phase 2 → SQLite persistence layer
Phase 3 → Elysia + Eden runtime graph
```

---

# 🧠 FINAL MASTER INSIGHT

You are no longer building applications.

You are designing:

> systems that exist inside a runtime boundary


Just tell me the direction.
