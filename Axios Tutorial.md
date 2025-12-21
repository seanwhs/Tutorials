# 📘 Production-Grade Axios Handbook

## Design, Test, and Operate Reliable HTTP Clients in JavaScript & TypeScript

**Edition:** 1.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

**Tech Stack:**

* Axios
* TypeScript
* Node.js / Browser
* Jest / Vitest
* Zod (runtime validation)
* ESLint + Prettier

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Understand **what Axios really is (and isn’t)**
✅ Design a **centralized HTTP client architecture**
✅ Handle **authentication, retries, timeouts, and errors** correctly
✅ Prevent **API contract drift** using types & validation
✅ Write **fully testable API clients**
✅ Integrate Axios safely into **React, Node, or DRF backends**

---

# 🧭 Architecture Overview

---

## Axios in a Production System

```
+----------------------+
| UI / Service Layer   |
| (React / Node)       |
+----------+-----------+
           |
           v
+----------------------+
| API Client Layer     |
| (Axios Wrapper)     |
+----------+-----------+
           |
           v
+----------------------+
| Axios Core           |
| (HTTP Engine)        |
+----------+-----------+
           |
           v
+----------------------+
| External API         |
| (REST / DRF)         |
+----------------------+
```

> **Key idea:**
> You never call Axios directly from UI or business logic.

---

## Design Principles

* **Single Axios instance**
* **No raw HTTP in business code**
* **Typed inputs & outputs**
* **Centralized error handling**
* **Infrastructure isolated from domain**

---

# 📁 Project Structure (Production-Grade)

```
axios-client/
│
├── package.json
├── tsconfig.json
│
├── src/
│   ├── http/
│   │   ├── axiosClient.ts     # Axios instance
│   │   ├── interceptors.ts    # Auth / logging
│   │   └── errors.ts          # Error mapping
│   │
│   ├── api/
│   │   └── taskApi.ts         # API-specific functions
│   │
│   ├── domain/
│   │   └── task.ts            # Domain models
│   │
│   ├── config/
│   │   └── env.ts             # Environment config
│   │
│   └── tests/
│       ├── axiosClient.test.ts
│       └── taskApi.test.ts
│
└── dist/
```

---

# ⚙️ Part 1: Installation & Setup

---

## 1️⃣ Install Dependencies

```bash
npm install axios
npm install -D typescript vitest zod
```

Axios ships with **excellent TypeScript types** — no `@types` needed.

---

# 🧠 Part 2: What Axios Actually Does

---

## Axios vs Fetch (Architectural View)

| Concern              | Fetch | Axios |
| -------------------- | ----- | ----- |
| Interceptors         | ❌     | ✅     |
| Request cancellation | ⚠️    | ✅     |
| Automatic JSON       | ❌     | ✅     |
| Timeout handling     | ❌     | ✅     |
| Error normalization  | ❌     | ✅     |

> Axios is **not** magic — it’s a **better HTTP abstraction**.

---

## Axios Is NOT

❌ A domain layer
❌ A state manager
❌ A replacement for backend validation
❌ A retry strategy by default

---

# 🧱 Part 3: Creating a Central Axios Client

---

## `src/http/axiosClient.ts`

```ts
import axios from "axios";

export const axiosClient = axios.create({
  baseURL: "https://api.example.com",
  timeout: 5000,
  headers: {
    "Content-Type": "application/json"
  }
});
```

**Rules:**

* Only **one instance**
* No business logic
* No UI imports

---

# 🔐 Part 4: Interceptors (Auth, Logging, Errors)

---

## Request Interceptor (Auth)

```ts
axiosClient.interceptors.request.use(config => {
  const token = localStorage.getItem("token");

  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }

  return config;
});
```

---

## Response Interceptor (Error Normalization)

### `src/http/errors.ts`

```ts
export class ApiError extends Error {
  constructor(
    public status: number,
    message: string
  ) {
    super(message);
  }
}
```

```ts
import { AxiosError } from "axios";
import { ApiError } from "./errors";

axiosClient.interceptors.response.use(
  response => response,
  (error: AxiosError) => {
    if (error.response) {
      throw new ApiError(
        error.response.status,
        String(error.response.data)
      );
    }
    throw new ApiError(0, "Network error");
  }
);
```

> **All consumers now receive a predictable error shape.**

---

# 🧠 Part 5: Domain Models (Never Inline Types)

---

## `src/domain/task.ts`

```ts
export interface Task {
  id: string;
  title: string;
  completed: boolean;
}
```

---

# 🌐 Part 6: API Layer (Never Export Axios)

---

## `src/api/taskApi.ts`

```ts
import { axiosClient } from "../http/axiosClient";
import { Task } from "../domain/task";

export async function fetchTasks(): Promise<Task[]> {
  const res = await axiosClient.get<Task[]>("/tasks");
  return res.data;
}

export async function createTask(
  title: string
): Promise<Task> {
  const res = await axiosClient.post<Task>("/tasks", { title });
  return res.data;
}
```

**Key rules:**

* API layer returns **domain types**
* No Axios types leak out
* No `.then()` chains

---

# 🛡 Part 7: Runtime Validation (Critical)

TypeScript does **not** protect you from bad servers.

---

## Zod Schema

```ts
import { z } from "zod";

export const TaskSchema = z.object({
  id: z.string(),
  title: z.string(),
  completed: z.boolean()
});

export const TaskListSchema = z.array(TaskSchema);
```

---

## Safe Parsing

```ts
export async function fetchTasksSafe() {
  const res = await axiosClient.get("/tasks");
  return TaskListSchema.parse(res.data);
}
```

> This catches **backend regressions instantly**.

---

# 🧪 Part 8: Testing Axios Code

---

## Mock Axios (Unit Tests)

```ts
import axios from "axios";
import { fetchTasks } from "../api/taskApi";

vi.mock("axios");

test("fetches tasks", async () => {
  (axios.get as any).mockResolvedValue({
    data: [{ id: "1", title: "Test", completed: false }]
  });

  const tasks = await fetchTasks();
  expect(tasks.length).toBe(1);
});
```

---

## What We Test

| Layer         | Tested? | Why                  |
| ------------- | ------- | -------------------- |
| API functions | ✅       | Business correctness |
| Interceptors  | ✅       | Security & stability |
| Axios itself  | ❌       | Vendor code          |

---

# 🔁 Part 9: Advanced Axios Patterns

---

## Request Cancellation

```ts
const controller = new AbortController();

axiosClient.get("/tasks", {
  signal: controller.signal
});

controller.abort();
```

---

## Retry Strategy (Manual)

```ts
async function retry<T>(
  fn: () => Promise<T>,
  attempts = 3
): Promise<T> {
  try {
    return await fn();
  } catch (e) {
    if (attempts <= 1) throw e;
    return retry(fn, attempts - 1);
  }
}
```

---

## File Uploads

```ts
const form = new FormData();
form.append("file", file);

axiosClient.post("/upload", form, {
  headers: { "Content-Type": "multipart/form-data" }
});
```

---

# 🚀 Part 10: Integration Examples

---

## React

```ts
useEffect(() => {
  fetchTasks().then(setTasks).catch(setError);
}, []);
```

---

## Node.js

```ts
export async function syncTasks() {
  const tasks = await fetchTasks();
  // persist to DB
}
```

---

## Django REST Framework (Consumer)

Axios pairs naturally with:

* JWT auth
* Pagination
* Filtering
* OpenAPI schemas

---

# 🏛 Part 11: Enterprise-Grade Extensions

---

Add progressively:

🔐 Token refresh flows
📦 OpenAPI → Axios codegen
🧪 Contract tests (frontend ↔ backend)
📊 Request tracing headers
🌍 Multi-tenant base URLs
🧩 Shared API SDK packages

---

## ✅ Final Mental Model

> Axios is **infrastructure**, not application logic.
> Treat it like a **database driver**, not a helper function.

