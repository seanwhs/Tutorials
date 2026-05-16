**# 📘 Introduction to React Course**  
**Edition:** 1.0  
**Level:** Beginner 
**Focus:** Mental Models + Practical Building + Production Architecture  

---

### 🎯 Course Philosophy

React is **not** a traditional UI library. It is a **state-driven rendering system**:

> **UI = f(state)**

**React does NOT**:
- Manipulate the DOM directly
- Track individual element changes

**React DOES**:
- Take a snapshot of state
- Re-run component logic
- Compute a new UI representation
- Efficiently reconcile differences with the real DOM

**Fundamental Mental Model**:
> React is a function that turns data into UI → `UI = render(state)`

**Core Cycle**:
**State Change → Re-render → New UI Snapshot → Diff → Commit**

React recomputes the page instead of editing it imperatively.

---

### 🗺️ Learning Path

1. **Mental Model** (how React thinks)
2. **JSX & Components** (UI as functions)
3. **Props & State** (data flow)
4. **Lists & Conditionals** (dynamic UI)
5. **Side Effects (`useEffect`)**
6. **Routing & Architecture**
7. **Capstone Projects + Assessment**
8. **Advanced** (React Internals, Production Architecture)

---

## 🧱 MODULE 1: React Mental Model

**Core Insight**: React is a **re-render engine**, not a DOM mutation engine.

**Vanilla JS (Imperative)** vs **React (Declarative)**

**Imperative**:
```js
document.querySelector("button").onclick = () => {
  const el = document.querySelector("h1");
  el.innerText = Number(el.innerText) + 1;
};
```

**Declarative (React)**:
```jsx
import { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);
  return (
    <button onClick={() => setCount(c => c + 1)}>
      {count}
    </button>
  );
}
```

**Key Takeaway**: You declare *what* the UI should look like for a given state. React handles the *how*.

---

## 🧱 MODULE 2: JSX & Components

JSX is syntactic sugar that compiles to `React.createElement()`.

**Examples**:
```jsx
const name = "Sean";
const a = 5, b = 10;

return (
  <h1>Hello {name}</h1>
  <p>{a + b}</p>
  <h1>{isAdmin ? "Admin" : "User"}</h1>
);
```

**Component Rules**:
- PascalCase
- Return single root element (or fragment)
- Behave like **pure functions** (same input → same output)

---

## 🧱 MODULE 3: Props & State

| Type   | Meaning                      | Mutability    |
|--------|------------------------------|---------------|
| Props  | External input from parent   | Immutable     |
| State  | Internal component memory    | Mutable (via setter) |

**Props**:
```jsx
function User({ name }) {
  return <h1>Hello {name}</h1>;
}
// Usage: <User name="Sean" />
```

**State**:
```jsx
const [count, setCount] = useState(0);
```

**Rule**: State change = full component re-execution (pure re-evaluation).

---

### 🟢 Project 1: Counter App

```jsx
import { useState } from "react";

export default function CounterApp() {
  const [count, setCount] = useState(0);

  return (
    <div style={{ textAlign: "center", marginTop: "50px" }}>
      <h1>Counter App</h1>
      <h2>{count}</h2>
      <button onClick={() => setCount(c => c - 1)}>-</button>
      <button onClick={() => setCount(0)}>Reset</button>
      <button onClick={() => setCount(c => c + 1)}>+</button>
    </div>
  );
}
```

---

## 🧱 MODULE 4: Lists & Conditional Rendering

**Lists**:
```jsx
const items = ["A", "B", "C"];

return (
  <ul>
    {items.map(item => <li key={item}>{item}</li>)}
  </ul>
);
```

**Conditionals**:
```jsx
{isLoggedIn && <Dashboard />}
{isAdmin ? <Admin /> : <User />}
```

---

### 🟡 Project 2: Todo App

```jsx
import { useState } from "react";

export default function TodoApp() {
  const [tasks, setTasks] = useState([]);
  const [input, setInput] = useState("");

  const addTask = () => {
    if (!input.trim()) return;
    setTasks([...tasks, { id: Date.now(), text: input }]);
    setInput("");
  };

  const removeTask = (id) => setTasks(tasks.filter(t => t.id !== id));

  return (
    <div>
      <h1>Todo App</h1>
      <input value={input} onChange={e => setInput(e.target.value)} />
      <button onClick={addTask}>Add</button>
      <ul>
        {tasks.map(task => (
          <li key={task.id}>
            {task.text}
            <button onClick={() => removeTask(task.id)}>X</button>
          </li>
        ))}
      </ul>
    </div>
  );
}
```

---

## 🧱 MODULE 5: Side Effects (`useEffect`)

Components should be **pure**. Side effects (API calls, timers, subscriptions) go in `useEffect`.

```jsx
useEffect(() => {
  console.log("Mounted");
  return () => console.log("Cleanup");
}, []); // Empty dependency array = run once on mount
```

---

### 🔵 Project 3: Weather App

```jsx
import { useState } from "react";

export default function WeatherApp() {
  const [city, setCity] = useState("");
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);

  const fetchWeather = async () => {
    setLoading(true);
    const res = await fetch(`https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=YOUR_KEY`);
    const json = await res.json();
    setData(json);
    setLoading(false);
  };

  return (
    <div>
      <h1>Weather App</h1>
      <input onChange={e => setCity(e.target.value)} />
      <button onClick={fetchWeather}>Search</button>
      {loading && <p>Loading...</p>}
      {data && (
        <div>
          <h2>{data.name}</h2>
          <p>{data.main.temp}</p>
        </div>
      )}
    </div>
  );
}
```

---

## 🧱 MODULE 6: Routing & Architecture

Use **React Router** for SPA navigation.

```jsx
import { BrowserRouter, Routes, Route } from "react-router-dom";

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/projects" element={<Projects />} />
        <Route path="/contact" element={<Contact />} />
      </Routes>
    </BrowserRouter>
  );
}
```

---

### 🟣 Project 4: Portfolio App

(Structure as shown in Module 6 above)

---

## 🧪 Final Quiz

**1.** Why `className` instead of `class`?  
**B)** `class` is a reserved keyword in JavaScript

**2.** Props in React are:  
**B)** Read-only inputs passed from parent components

**3.** The dependency array in `useEffect` controls:  
**B)** When the effect runs

**4.** Correct way to update state safely?  
**D)** Both B and C (`setCount(count + 1)` and functional updater)

**5.** Why do we use `key` in lists?  
**B)** To help React identify and optimize list updates

**6.** Prop drilling refers to:  
**B)** Passing props through multiple nested components

**7.** Use `useReducer` instead of `useState` when:  
**B)** State logic is complex or has multiple transitions

**8.** `JSON.stringify()` does:  
**B)** Converts a JavaScript object into a JSON string

**9.** React Router works by:  
**B)** Using the browser History API to swap components without reload

**10.** A “pure component” means:  
**B)** It always returns the same output for the same props/state

---

## 🧠 Advanced: React Internals

**Render Pipeline**:
1. Render (create Virtual DOM tree)
2. Diff (reconciliation)
3. Commit (minimal DOM mutations)

**Fiber Architecture**:
- Rendering split into interruptible **Fibers**
- **Render Phase** (can pause/resume)
- **Commit Phase** (synchronous, non-interruptible)
- Priority-based scheduling

**Performance comes from**:
- Batching updates
- Structural comparison (not mutation tracking)
- Minimal DOM writes

---

## 🏗️ Production-Grade Architecture

**Recommended Stack**:
- React 18+ (Hooks)
- TypeScript
- Vite
- React Router
- Context + `useReducer` (or TanStack Query for server state)
- Vitest + Testing Library

### Project Structure (Task Manager Example)

```
src/
├── auth/ (AuthContext, ProtectedRoute)
├── state/ (taskReducer.ts, TaskContext)
├── components/ (TaskForm, TaskList, TaskItem)
├── pages/ (LoginPage, Dashboard)
├── services/ (apiClient, taskService)
├── hooks/ (useTasks)
└── tests/
```

**Pure Reducer Example** (highly testable):
```ts
export function taskReducer(state: Task[], action: Action): Task[] { ... }
```

**Best Practices**:
- Keep components pure
- Isolate side effects
- Single Responsibility
- Test reducers and business logic heavily
- Use controlled components
- Prefer composition over prop drilling

---

**Final Advice**:
1. Master the mental model first (`UI = f(state)`).
2. Start simple (`useState`) → scale to `useReducer` + Context + server state tools.
3. Always prioritize predictability and testability.

This consolidated material gives you everything from foundational understanding to production-ready architecture. You can now build, scale, and interview with confidence. 

Ready for interactive exercises, full codebase, or TypeScript version? Let me know!
