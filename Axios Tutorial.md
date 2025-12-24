# 📘 Production-Grade Axios Handbook

## Design, Test, and Operate Reliable HTTP Clients in JavaScript & TypeScript

**Edition:** 1.1 (Enhanced)
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

**Tech Stack:** Axios, TypeScript, Node.js / Browser, Jest / Vitest, Zod, ESLint + Prettier

---

## 🎯 Learning Outcomes

By the end of this guide, readers will be able to:

✅ Understand **what Axios really is (and isn’t)**
✅ Design a **centralized HTTP client architecture**
✅ Handle **authentication, retries, timeouts, and errors** robustly
✅ Prevent **API contract drift** using TypeScript types & runtime validation
✅ Write **fully testable, reliable API clients**
✅ Integrate Axios safely into **React, Node, or DRF backends**
✅ Extend Axios for **enterprise-grade workflows**

---

# 🧭 Architecture Overview

```
UI / Service Layer (React / Node)
           │
           ▼
API Client Layer (Axios Wrapper)
           │
           ▼
Axios Core (HTTP Engine)
           │
           ▼
External API (REST / DRF / GraphQL)
```

> Never call Axios directly from UI or business logic. Always centralize it.

---

## Design Principles

* Single Axios instance per service/environment
* No raw HTTP in business/domain code
* Typed inputs & outputs using TypeScript and Zod
* Centralized error handling and logging
* Infrastructure isolated from domain logic

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
│   │   ├── interceptors.ts    # Auth / logging / error handling
│   │   └── errors.ts          # Error mapping / normalization
│   │
│   ├── api/
│   │   └── taskApi.ts         # API-specific functions returning domain types
│   │
│   ├── domain/
│   │   └── task.ts            # Domain models / TypeScript interfaces
│   │
│   ├── config/
│   │   └── env.ts             # Environment configuration
│   │
│   └── tests/
│       ├── axiosClient.test.ts
│       └── taskApi.test.ts
│
└── dist/
```

> Separation of concerns ensures **testability and maintainability**.

---

# ⚙️ Installation & Setup

```bash
npm install axios
npm install -D typescript vitest zod
```

> Axios includes **built-in TypeScript types** — no `@types/axios` needed.

---

# 🧠 Axios Fundamentals

| Feature              | Fetch | Axios |
| -------------------- | ----- | ----- |
| Interceptors         | ❌     | ✅     |
| Request cancellation | ⚠️    | ✅     |
| Automatic JSON       | ❌     | ✅     |
| Timeout handling     | ❌     | ✅     |
| Error normalization  | ❌     | ✅     |

**Axios is NOT:** domain layer, state manager, backend validator, or automatic retry strategy.

---

# 🧱 Creating a Central Axios Client

```ts
import axios from "axios";

export const axiosClient = axios.create({
  baseURL: "https://api.example.com",
  timeout: 5000,
  headers: { "Content-Type": "application/json" }
});
```

**Rules:** single instance per environment, no business logic, no UI imports.

---

# 🔐 Interceptors (Auth, Logging, Errors)

### Request Interceptor (Auth)

```ts
axiosClient.interceptors.request.use(config => {
  const token = localStorage.getItem("token");
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});
```

### Response Interceptor (Error Normalization)

```ts
import { AxiosError } from "axios";
import { ApiError } from "./errors";

axiosClient.interceptors.response.use(
  response => response,
  (error: AxiosError) => {
    if (error.response)
      throw new ApiError(error.response.status, String(error.response.data));
    throw new ApiError(0, "Network error");
  }
);
```

```ts
// src/http/errors.ts
export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}
```

> Consumers receive **predictable error shapes**.

---

# 🧠 Domain Models

```ts
export interface Task {
  id: string;
  title: string;
  completed: boolean;
}
```

> Keep types centralized; never inline in API functions.

---

# 🌐 API Layer (Typed & Safe)

```ts
import { axiosClient } from "../http/axiosClient";
import { Task } from "../domain/task";

export async function fetchTasks(): Promise<Task[]> {
  const res = await axiosClient.get<Task[]>("/tasks");
  return res.data;
}

export async function createTask(title: string): Promise<Task> {
  const res = await axiosClient.post<Task>("/tasks", { title });
  return res.data;
}
```

**Rules:** API returns domain types only; Axios types never leak; use async/await.

---

# 🛡 Runtime Validation (Optional but Critical)

```ts
import { z } from "zod";

export const TaskSchema = z.object({
  id: z.string(),
  title: z.string(),
  completed: z.boolean()
});
export const TaskListSchema = z.array(TaskSchema);

export async function fetchTasksSafe() {
  const res = await axiosClient.get("/tasks");
  return TaskListSchema.parse(res.data);
}
```

> Detects **backend contract violations instantly**.

---

# 🧪 Testing Axios Code

### Mock Axios

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

**Testing layers:** API functions ✅, interceptors ✅, Axios itself ❌ (mocked).

---

# 🔁 Advanced Axios Patterns

**Retry**

```ts
async function retry<T>(fn: () => Promise<T>, attempts = 3): Promise<T> {
  try { return await fn(); }
  catch (e) { if (attempts <= 1) throw e; return retry(fn, attempts - 1); }
}
```

**Request Cancellation**

```ts
const controller = new AbortController();
axiosClient.get("/tasks", { signal: controller.signal });
controller.abort();
```

**File Upload**

```ts
const form = new FormData();
form.append("file", file);
axiosClient.post("/upload", form, { headers: { "Content-Type": "multipart/form-data" }});
```

---

# 🚀 Integration Examples

**React**

```ts
useEffect(() => {
  fetchTasks().then(setTasks).catch(setError);
}, []);
```

**Node.js Service**

```ts
export async function syncTasks() {
  const tasks = await fetchTasks();
  // persist to DB
}
```

**Django REST Framework Consumer:** supports JWT, pagination, filtering, OpenAPI/Swagger schemas.

---

# 🏛 Enterprise-Grade Extensions

* Token refresh flows & silent authentication
* OpenAPI → Axios codegen for typed clients
* Contract tests (frontend ↔ backend)
* Request tracing & correlation headers
* Multi-tenant base URLs & dynamic routing
* Shared API SDK packages

---

# ✅ Mental Model

> Axios is **infrastructure**, not application logic. Treat it like a **centralized, typed, testable database driver**.

---

# 🌐 Full Lifecycle (ASCII)

```
UI / Service Layer
│ - Calls domain API functions
│ - Receives validated objects
▼
API Client Layer
│ - Typed funcs
│ - Retry / timeout / cancel
│ - Token refresh
▼
Axios Client
│ - Single instance
│ - Interceptors (Auth, Errors)
│ - Retry / cancellation
▼
External API / Backend
│ - REST / DRF / GraphQL
│ - JWT / validation / pagination
▼
Runtime Validation (Zod)
│ - Ensures contract adherence
▼
Domain Layer
│ - Receives validated objects
│ - Updates UI / persists data
```

---

## 🔑 Key Rules

1. Never call Axios directly from UI/business logic
2. Always return typed domain objects
3. Centralize error handling via interceptors
4. Optional: Use Zod for runtime validation
5. Advanced: Retry, cancellation, file upload, token refresh
6. Testing: Mock Axios; test API & interceptors only

---

