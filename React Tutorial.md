# 📘 Production-Grade React Application Handbook

## Build, Test, Secure, and Ship a Maintainable React Application

**Edition:** 1.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

**Tech Stack:**

* React 18 (Hooks + Functional Components)
* TypeScript (recommended, optional)
* Vite (dev server & bundling)
* React Router
* Context API + Reducer
* REST API (mock → real)
* Authentication (JWT / OAuth-ready)
* Vitest + Testing Library
* ESLint + Prettier

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Understand **modern React architecture**
✅ Design **scalable component hierarchies**
✅ Implement **authentication & route protection**
✅ Separate **UI, domain, and infrastructure layers**
✅ Write **unit, integration, and auth tests**
✅ Build a **production-ready task management app**
✅ Deploy securely to the cloud

---

# 🧭 Architecture Overview

---

## High-Level Architecture

```
+---------------------+
|   index.html        |
+---------------------+
          |
          v
+---------------------+
|   React App (UI)    |
|  Components + Hooks |
+----------+----------+
           |
           v
+---------------------+        +----------------------+
| Application State   | <----> | Auth & API Services  |
| (Context / Reducer) |        | (JWT / OAuth)        |
+----------+----------+        +----------+-----------+
           |
           v
+---------------------+
| Persistence Layer   |
| (API / Storage)    |
+---------------------+
```

---

## Design Principles

* **Component Single Responsibility**
* **Explicit State Flow**
* **Side-effects isolated in hooks**
* **Dependency inversion**
* **Testability first**
* **Framework-agnostic domain logic**

---

# 📁 Project Structure (Production-Grade)

```
react-task-manager/
│
├── index.html
├── vite.config.ts
├── package.json
│
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   │
│   ├── auth/
│   │   ├── AuthContext.tsx
│   │   ├── authService.ts
│   │   └── ProtectedRoute.tsx
│   │
│   ├── state/
│   │   ├── taskReducer.ts
│   │   └── TaskContext.tsx
│   │
│   ├── components/
│   │   ├── TaskList.tsx
│   │   ├── TaskItem.tsx
│   │   └── TaskForm.tsx
│   │
│   ├── pages/
│   │   ├── LoginPage.tsx
│   │   └── Dashboard.tsx
│   │
│   ├── services/
│   │   ├── apiClient.ts
│   │   └── taskService.ts
│   │
│   ├── hooks/
│   │   └── useTasks.ts
│   │
│   └── tests/
│       ├── taskReducer.test.ts
│       └── auth.test.ts
│
└── dist/
```

---

# ⚙️ Part 1: Tooling & Setup

---

## 1️⃣ Create React App (Vite)

```bash
npm create vite@latest react-task-manager -- --template react-ts
cd react-task-manager
npm install
```

---

## 2️⃣ Install Dependencies

```bash
npm install react-router-dom
npm install vitest @testing-library/react jsdom --save-dev
```

---

## 3️⃣ Scripts (`package.json`)

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "vitest"
  }
}
```

---

# 🧠 Part 2: Domain Model & State Management

---

## `src/state/taskReducer.ts`

> **Pure business logic (framework-independent)**

```ts
export type Task = {
  id: string;
  title: string;
  completed: boolean;
};

type Action =
  | { type: "ADD"; title: string }
  | { type: "TOGGLE"; id: string }
  | { type: "REMOVE"; id: string };

export function taskReducer(state: Task[], action: Action): Task[] {
  switch (action.type) {
    case "ADD":
      return [
        ...state,
        { id: crypto.randomUUID(), title: action.title, completed: false }
      ];
    case "TOGGLE":
      return state.map(t =>
        t.id === action.id ? { ...t, completed: !t.completed } : t
      );
    case "REMOVE":
      return state.filter(t => t.id !== action.id);
    default:
      return state;
  }
}
```

---

## ✅ Reducer Tests

### `tests/taskReducer.test.ts`

```ts
import { taskReducer } from "../state/taskReducer";

test("adds a task", () => {
  const state = taskReducer([], { type: "ADD", title: "Learn React" });
  expect(state.length).toBe(1);
});
```

---

# 🔐 Part 3: Authentication Architecture

---

## Auth Flow (JWT-Based)

```
Login Page
   |
   v
Auth Service → API
   |
   v
JWT stored (memory / storage)
   |
   v
Protected Routes Enabled
```

---

## `src/auth/authService.ts`

```ts
export async function login(username: string, password: string) {
  // mock auth (replace with real API)
  if (username === "admin" && password === "password") {
    return { token: "fake-jwt-token" };
  }
  throw new Error("Invalid credentials");
}
```

---

## `src/auth/AuthContext.tsx`

```tsx
import { createContext, useContext, useState } from "react";

const AuthContext = createContext<any>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(null);

  return (
    <AuthContext.Provider value={{ token, setToken }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
```

---

## 🔒 Protected Routes

### `src/auth/ProtectedRoute.tsx`

```tsx
import { Navigate } from "react-router-dom";
import { useAuth } from "./AuthContext";

export function ProtectedRoute({ children }: any) {
  const { token } = useAuth();
  return token ? children : <Navigate to="/login" />;
}
```

---

# 🎨 Part 4: UI Layer (React Components)

---

## `TaskList.tsx`

```tsx
export function TaskList({ tasks, onToggle }: any) {
  return (
    <ul>
      {tasks.map((task: any) => (
        <li key={task.id} onClick={() => onToggle(task.id)}>
          {task.completed ? "✅" : "⬜"} {task.title}
        </li>
      ))}
    </ul>
  );
}
```

---

## UI Design Rules

* No direct API calls
* Stateless where possible
* Props = data + callbacks
* Easily testable

---

# 🚦 Part 5: Application Orchestration

---

## `App.tsx`

```tsx
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import { ProtectedRoute } from "./auth/ProtectedRoute";
import LoginPage from "./pages/LoginPage";
import Dashboard from "./pages/Dashboard";

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
```

---

# 🧪 Part 6: Testing Strategy

---

## What We Test

| Layer            | Tested?  | Why               |
| ---------------- | -------- | ----------------- |
| Reducers / Logic | ✅        | Deterministic     |
| Auth Logic       | ✅        | Security critical |
| Components       | ✅        | User behavior     |
| Routing          | ⚠️       | Integration-level |
| E2E              | Optional | Confidence        |

---

## Test Pyramid

```
        E2E (few)
   Integration (some)
Unit Tests (many)
```

---

# 🚀 Part 7: Build & Deployment

---

## Production Build

```bash
npm run build
```

Outputs:

```
dist/
├── index.html
├── assets/
```

---

## Deployment Targets

* Vercel
* Netlify
* Cloudflare Pages
* S3 + CloudFront

---

# 🏛 Part 8: Enterprise-Grade Extensions

---

Add progressively:

🔐 OAuth (Google / GitHub)
🌐 Real Backend (Node.js / Django / Spring)
📦 React Query / TanStack
🧪 Cypress / Playwright
🧩 Feature flags
📊 Observability
📱 PWA & Offline Support

---
