# 📘 Production-Grade TypeScript Application Handbook

## Design, Type, Test, and Ship Maintainable Applications with TypeScript

**Edition:** 1.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

**Tech Stack:**

* TypeScript (ES2022+)
* Node.js (runtime)
* Vite (dev server & bundling)
* Jest / Vitest (testing)
* Zod (runtime validation)
* ESLint + Prettier
* TypeScript Compiler (`tsc`)

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Understand **why TypeScript exists and how it works**
✅ Model **real-world domains using types**
✅ Use **interfaces, unions, generics, and utility types** correctly
✅ Separate **types, domain logic, and infrastructure**
✅ Write **fully typed, testable applications**
✅ Prevent entire classes of runtime bugs
✅ Confidently read and write **enterprise TypeScript codebases**

---

# 🧭 Architecture Overview

---

## High-Level Architecture

```
+----------------------+
| Entry Point          |
| (main.ts)            |
+----------+-----------+
           |
           v
+----------------------+        +----------------------+
| Application Core     | <----> | External Interfaces  |
| (Domain Logic)       |        | (API / IO / Storage) |
+----------+-----------+        +----------+-----------+
           |
           v
+----------------------+
| Type System          |
| (Contracts & Safety) |
+----------------------+
```

> **Key idea:**
> Types are not decoration — they are **the architecture**.

---

## Design Principles

* **Types define contracts**
* **Illegal states unrepresentable**
* **Compile-time correctness over runtime guessing**
* **Domain logic isolated from IO**
* **Testability by construction**

---

# 📁 Project Structure (Production-Grade)

```
ts-task-manager/
│
├── package.json
├── tsconfig.json
├── vite.config.ts
│
├── src/
│   ├── main.ts                # App entry
│   │
│   ├── domain/
│   │   ├── task.ts            # Domain types
│   │   └── taskService.ts     # Domain logic
│   │
│   ├── services/
│   │   ├── storage.ts         # Infrastructure adapter
│   │   └── api.ts             # External API client
│   │
│   ├── utils/
│   │   └── result.ts          # Generic utilities
│   │
│   └── tests/
│       ├── taskService.test.ts
│       └── types.test.ts
│
└── dist/
```

---

# ⚙️ Part 1: Tooling & Setup

---

## 1️⃣ Initialize Project

```bash
npm init -y
npm install typescript vite --save-dev
npm install vitest --save-dev
```

---

## 2️⃣ TypeScript Config (`tsconfig.json`)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "strict": true,
    "noImplicitAny": true,
    "exactOptionalPropertyTypes": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

> **Strict mode is non-negotiable in production.**

---

## 3️⃣ Scripts (`package.json`)

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "test": "vitest"
  }
}
```

---

# 🧠 Part 2: Core TypeScript Fundamentals (Used Immediately)

---

## Types vs Interfaces

```ts
type TaskId = string;

interface Task {
  id: TaskId;
  title: string;
  completed: boolean;
}
```

**Rule of thumb:**

* `type` → unions, primitives, compositions
* `interface` → object shapes, public contracts

---

## Union Types (Critical)

```ts
type TaskStatus = "active" | "completed" | "archived";
```

This replaces:

❌ magic strings
❌ boolean explosions
❌ undocumented states

---

## Making Illegal States Impossible

```ts
type CompletedTask = Task & { completed: true };
type ActiveTask = Task & { completed: false };
```

---

# 🧠 Part 3: Domain Modeling (The Heart of TypeScript)

---

## `src/domain/task.ts`

```ts
export type TaskId = string;

export interface Task {
  id: TaskId;
  title: string;
  completed: boolean;
}

export type NewTask = Omit<Task, "id" | "completed">;
```

---

## Domain Rules as Types

```ts
export type TaskAction =
  | { type: "ADD"; title: string }
  | { type: "TOGGLE"; id: TaskId }
  | { type: "REMOVE"; id: TaskId };
```

---

# 🧠 Part 4: Domain Logic (Pure & Typed)

---

## `src/domain/taskService.ts`

```ts
import { Task, TaskAction } from "./task";

export function taskReducer(
  state: Task[],
  action: TaskAction
): Task[] {
  switch (action.type) {
    case "ADD":
      return [
        ...state,
        {
          id: crypto.randomUUID(),
          title: action.title,
          completed: false
        }
      ];
    case "TOGGLE":
      return state.map(t =>
        t.id === action.id
          ? { ...t, completed: !t.completed }
          : t
      );
    case "REMOVE":
      return state.filter(t => t.id !== action.id);
    default:
      return assertNever(action);
  }
}

function assertNever(x: never): never {
  throw new Error(`Unhandled action: ${JSON.stringify(x)}`);
}
```

> This guarantees **exhaustive checks at compile time**.

---

## ✅ Domain Tests

### `tests/taskService.test.ts`

```ts
import { taskReducer } from "../domain/taskService";

test("adds a task", () => {
  const state = taskReducer([], { type: "ADD", title: "Learn TS" });
  expect(state.length).toBe(1);
});
```

---

# 🗄 Part 5: Infrastructure & Adapters

---

## `src/services/storage.ts`

```ts
import { Task } from "../domain/task";

const KEY = "tasks";

export function save(tasks: Task[]): void {
  localStorage.setItem(KEY, JSON.stringify(tasks));
}

export function load(): Task[] {
  const data = localStorage.getItem(KEY);
  return data ? JSON.parse(data) : [];
}
```

> **Key insight:**
> Infrastructure depends on domain — never the reverse.

---

# 🧩 Part 6: Advanced TypeScript Patterns

---

## Generics

```ts
export type Result<T, E> =
  | { ok: true; value: T }
  | { ok: false; error: E };
```

Usage:

```ts
function parse(input: string): Result<number, string> {
  const n = Number(input);
  return isNaN(n)
    ? { ok: false, error: "Not a number" }
    : { ok: true, value: n };
}
```

---

## Utility Types (Real Use)

```ts
type UpdateTask = Partial<Omit<Task, "id">>;
```

---

## Readonly & Immutability

```ts
type ReadonlyTask = Readonly<Task>;
```

---

# 🧪 Part 7: Testing Strategy (TypeScript-Specific)

---

## What We Test

| Layer        | Tested? | Why                      |
| ------------ | ------- | ------------------------ |
| Domain Logic | ✅       | Deterministic & critical |
| Types        | ✅       | Prevent regressions      |
| Adapters     | ✅       | Boundary correctness     |
| UI           | ⚠️      | Covered by higher layers |

---

## Type-Level Tests (Advanced)

```ts
type Expect<T extends true> = T;
type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends
  (<T>() => T extends B ? 1 : 2) ? true : false;

type _ = Expect<Equal<Task["completed"], boolean>>;
```

---

# 🚀 Part 8: Build & Distribution

---

## Compile

```bash
npm run build
```

Produces:

```
dist/
├── main.js
├── main.d.ts
```

---

## Consumption Targets

* React applications
* Node.js backends
* Shared domain libraries
* Monorepos (Nx / Turborepo)

---

# 🏛 Part 9: Enterprise-Grade Extensions

---

Add progressively:

🔐 Branded types (IDs, Tokens)
🧪 Runtime validation (Zod)
📦 API contracts (OpenAPI → TS)
🧩 Monorepo architecture
📊 Observability typing
🔄 Schema-driven development

---
