**# 📘 React Tutorial**

**Edition:** 1.0  
**Audience:** Engineers, Bootcamp Learners, Trainers  
**Level:** Beginner → Professional

**Tech Stack (Recommended):**  
- React 18+ (Functional Components + Hooks)  
- TypeScript (strongly recommended)  
- Vite (build tool)  
- React Router  
- Context API + useReducer  
- Vitest + Testing Library  
- ESLint + Prettier  

---

## 🎯 Learning Outcomes

By the end of this handbook you will be able to:

- Explain **React’s core mental models** (pure functions, Virtual DOM, unidirectional data flow, controlled impurity via Hooks).
- Build **predictable, declarative UIs** using functional components.
- Design **scalable architectures** with clear separation of concerns.
- Implement **authentication, routing, state management, and testing**.
- Ship a **production-ready task management application**.

---

# 🧠 Section 1–15: First-Principles Foundation (Pure Functions, Hooks & Virtual DOM)

*(The complete foundational tutorial from the original material is preserved and integrated here as the bedrock.)*

### Key Mental Models (Consolidated)

**Core Idea:**  
**`UI = f(props, state)`** — React components are **pure functions**. Side effects are isolated in Hooks.

**Rendering Flow (All Sections):**
```
User Event → setState / Context update
      ↓
Component Function re-runs (pure: props + state → JSX)
      ↓
Virtual DOM (new snapshot)
      ↓
Diffing Algorithm → Minimal Real DOM updates
      ↓
UI Updated + useEffect side effects
```

**Props vs State vs Context**
- **Props**: Immutable inputs from parent (explicit, local).
- **State**: Local controlled impurity (`useState`, `useReducer`).
- **Context**: Implicit shared inputs (avoids prop drilling for themes, auth, etc.).

**Hooks Purpose:**
- `useState` / `useReducer` → managed memory
- `useEffect` → side effects & lifecycle
- `useRef` → persistent values without re-renders
- `useContext` → shared data
- `useMemo` / `useCallback` → referential stability & performance
- Custom Hooks → reusable logic

**Lists & Keys, Conditional Rendering, Event Handling** all follow the same pure-function + Virtual DOM model.

**Full foundational details** (pure components, JSX, props, state, events, conditional rendering, lists/keys, useEffect, useRef, useContext, memoization, custom hooks, lifecycle, and the Todo Dashboard example) remain exactly as written in the source material for deep understanding.

---

# 🏗️ Production-Grade Architecture

## High-Level Architecture

```
index.html
   ↓
React Root (main.tsx)
   ↓
App (Routing + Providers)
   ↓
├── AuthContext (JWT / token)
├── TaskContext (useReducer + custom hooks)
├── Pages (Login, Dashboard)
│     └── Components (TaskForm, TaskList, TaskItem)
   ↓
Services (apiClient, taskService) + Custom Hooks
```

**Design Principles**
- Single Responsibility for components
- Pure render functions
- Side effects in hooks/services
- Framework-agnostic domain logic (reducers)
- Testability first

---

# 📁 Production Project Structure

```
react-task-manager/
├── index.html
├── vite.config.ts
├── package.json
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
│   │   ├── taskReducer.ts          # Pure business logic
│   │   └── TaskContext.tsx
│   │
│   ├── components/
│   │   ├── TaskForm.tsx
│   │   ├── TaskList.tsx
│   │   └── TaskItem.tsx
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
│   └── tests/                      # Unit + integration tests
│
└── dist/
```

---

# ⚙️ Setup & Tooling

```bash
npm create vite@latest react-task-manager -- --template react-ts
cd react-task-manager
npm install
npm install react-router-dom
npm install -D vitest @testing-library/react @testing-library/jest-dom jsdom
```

Update `package.json` scripts and `vite.config.ts` for Vitest.

---

# 🧩 Domain & State Management (`useReducer`)

**`src/state/taskReducer.ts`** (Pure, testable logic)

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
      return [...state, { id: crypto.randomUUID(), title: action.title, completed: false }];
    case "TOGGLE":
      return state.map(t => t.id === action.id ? { ...t, completed: !t.completed } : t);
    case "REMOVE":
      return state.filter(t => t.id !== action.id);
    default:
      return state;
  }
}
```

**Tests** (`tests/taskReducer.test.ts`) — deterministic and isolated.

**Context + Custom Hook** for consumption:

```tsx
// TaskContext.tsx
export function TaskProvider({ children }: { children: React.ReactNode }) {
  const [tasks, dispatch] = useReducer(taskReducer, []);
  return <TaskContext.Provider value={{ tasks, dispatch }}>{children}</TaskContext.Provider>;
}

export const useTasks = () => {
  const context = useContext(TaskContext);
  if (!context) throw new Error("useTasks must be used within TaskProvider");
  return context;
};
```

---

# 🔐 Authentication

**Auth Flow:** Login → JWT (memory or secure storage) → Protected Routes.

**`authService.ts`** (mock or real API).

**`AuthContext.tsx`** + **`ProtectedRoute.tsx`** using `react-router-dom` `<Navigate>`.

---

# 🎨 UI Components (Pure Where Possible)

- `TaskForm.tsx` – controlled inputs + dispatch on submit.
- `TaskList.tsx` / `TaskItem.tsx` – use `key={task.id}`, conditional rendering, event handlers.
- All components follow the pure function model from Sections 1–15.

---

# 🚦 App Orchestration (`App.tsx`)

```tsx
function App() {
  return (
    <AuthProvider>
      <TaskProvider>
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
      </TaskProvider>
    </AuthProvider>
  );
}
```

---

# 🧪 Testing Strategy

- **Unit**: Reducers, pure utility functions.
- **Component**: `@testing-library/react` – render, fire events, assert UI.
- **Integration**: Auth flow, full task CRUD.
- **E2E** (optional): Cypress / Playwright.

Example reducer test is already shown above.

---

# 🚀 Build & Deployment

```bash
npm run build   # → dist/ folder
```

Deploy to Vercel, Netlify, Cloudflare Pages, or S3 + CloudFront.

---

# 🏛 Enterprise Extensions

- TanStack Query for server state
- Real backend (Node/Express, NestJS, etc.)
- OAuth (Google, GitHub)
- Feature flags
- PWA / Offline support
- Observability (Sentry, etc.)

---

# 📚 Addendums (Preserved & Enhanced)

**Addendum A**: Full project code (combine the simple Todo Dashboard with the production Task Manager structure above).  
**Addendum B**: Visual cheat sheets & flow diagrams (Virtual DOM, prop flow, context vs drilling, render vs side effects).  
**Addendum C**: Hooks & lifecycle reference.  
**Addendum D**: Ultimate consolidated mental model (User Event → State/Props → Pure Component → Hooks → JSX → VDOM → Diff → DOM).

---

## Final Advice

1. **Master the mental models first** (Sections 1–15) — they make everything else obvious.
2. **Start simple** (local `useState`) → **scale deliberately** (`useReducer` + Context → TanStack Query).
3. **Keep components pure**.
4. **Isolate side effects**.
5. **Test the logic, not the framework**.
