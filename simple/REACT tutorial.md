# 📘 React Tutorial

**Goal:** Build a deep understanding of modern React (2018+), using **functional components with Hooks**, mental models, best practices, and hands-on examples.

---

# 🎯 Learning Objectives

By the end of this tutorial, you will:

1. Understand the **philosophy behind React** and why **functional components with Hooks** are the standard.
2. Use **JSX, components, props, state, and hooks** to build dynamic, reactive UIs.
3. Implement **conditional rendering, lists, keys, and events** efficiently.
4. Understand **component hierarchy, data flow, and reactivity mental models**.
5. Build a **complete React app** from scratch.
6. Reference **full project code (Addendum A)** and **visual cheat sheet (Addendum B)**.

---

# 🧠 Section 1 — Introduction to React

React is a **declarative JavaScript library for building UIs**. Its main advantage is describing *what* the UI should look like rather than *how* to manipulate the DOM directly.

* **Declarative:** Tell React what the UI should look like; React handles DOM updates.
* **Component-based:** UI is built from reusable **components**.
* **Virtual DOM:** React maintains a virtual DOM for efficient updates.

**ASCII Diagram: React Rendering Flow**

```
User Interaction
        ↓
 React Component Logic
        ↓
   Virtual DOM
        ↓
  Diffing Algorithm
        ↓
     Real DOM
        ↓
     User sees UI
```

**Key Concept:** In React, you **never manipulate the DOM directly**. Instead, you change **state** and **props**, and React handles the updates efficiently.

---

# 🧠 Section 2 — Why Functional Components?

Modern React development exclusively uses **functional components with Hooks**.

**Historical Context:**

* Before React 16.8: Functional components were stateless; state and lifecycle required **class components**.
* After React 16.8: Hooks allowed **state and side effects in functional components**, replacing most class components.

**Advantages of Functional Components:**

1. **Simplicity:** No constructors, `this`, or method binding.
2. **Better Readability:** Group logic with hooks instead of splitting across lifecycle methods.
3. **Easier Testing:** Pure functions are easier to test.
4. **Performance:** Lightweight and easier to optimize.

**Example Comparison:**

```javascript
// Class Component (Legacy)
class Counter extends React.Component {
  constructor(props) {
    super(props);
    this.state = { count: 0 };
  }

  render() {
    return (
      <button onClick={() => this.setState({ count: this.state.count + 1 })}>
        {this.state.count}
      </button>
    );
  }
}

// Functional Component (Modern)
import { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

**Mental Model:** Functional components are **functions that accept props and return JSX**, optionally with internal state managed by hooks.

---

# 🧠 Section 3 — JSX: JavaScript XML

JSX lets you **write HTML-like syntax in JavaScript**, keeping **UI and logic cohesive**.

```jsx
const name = "Alice";
const element = <h1>Hello, {name}!</h1>;
```

* JSX is optional, but improves readability.
* Use `{}` for JavaScript expressions inside JSX.
* JSX must have a **single parent element** or use fragments (`<> </>`).

**Mental Model:**

```
JSX -> React.createElement() -> Virtual DOM -> DOM
```

---

# 🧠 Section 4 — Components & Props

A **component** is a function returning JSX. **Props** are inputs from a parent and are **immutable**.

```jsx
function Greeting({ name }) {
  return <h1>Hello, {name}!</h1>;
}

function App() {
  return (
    <>
      <Greeting name="Alice" />
      <Greeting name="Bob" />
    </>
  );
}
```

**Mental Model:**

```
Parent defines props
     ↓
Child receives props
     ↓
Child renders UI
```

---

# 🧠 Section 5 — State with useState

**State** is internal, mutable data that triggers **re-render** when updated.

```jsx
import { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>+</button>
    </div>
  );
}
```

**Mental Model:**

```
useState(initial) -> [state, setter]
state changes -> triggers re-render
```

* Use multiple `useState` calls for unrelated state.
* Avoid deeply nested objects unless necessary.

---

# 🧠 Section 6 — Event Handling

React normalizes events across browsers.

```jsx
<button onClick={() => alert("Clicked!")}>Click Me</button>
```

* Handlers are functions, can be inline or external.
* Pass parameters using arrow functions:

```jsx
<button onClick={() => handleDelete(id)}>Delete</button>
```

---

# 🧠 Section 7 — Conditional Rendering

React supports **inline conditional rendering**:

```jsx
function Greeting({ isLoggedIn }) {
  return (
    <div>
      {isLoggedIn ? <p>Welcome back!</p> : <p>Please log in</p>}
    </div>
  );
}
```

* Use ternary for simple conditions.
* Use `&&` for conditional display:

```jsx
{isLoggedIn && <p>Welcome back!</p>}
```

---

# 🧠 Section 8 — Lists and Keys

Render arrays dynamically with `map()`:

```jsx
function TodoList({ todos }) {
  return (
    <ul>
      {todos.map((todo) => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
}
```

* **Key** is required for React diffing.
* Avoid using index if the list can reorder.
* Prefer unique IDs.

---

# 🧠 Section 9 — Side Effects with useEffect

`useEffect` replaces class lifecycle methods (`componentDidMount`, `componentDidUpdate`, `componentWillUnmount`).

```jsx
import { useState, useEffect } from "react";

function Timer() {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => setSeconds(s => s + 1), 1000);
    return () => clearInterval(interval); // cleanup
  }, []); // Empty dependency = run once on mount

  return <p>Seconds: {seconds}</p>;
}
```

**Mental Model:**

```
Mount -> Run effect
Dependency change -> Run effect again
Unmount -> Cleanup
```

---

# 🧠 Section 10 — Using useRef

`useRef` stores persistent values without triggering re-render and can access DOM nodes.

```jsx
import { useRef } from "react";

function FocusInput() {
  const inputRef = useRef();

  const focus = () => inputRef.current.focus();

  return (
    <div>
      <input ref={inputRef} />
      <button onClick={focus}>Focus Input</button>
    </div>
  );
}
```

---

# 🧠 Section 11 — useContext for Context

Consume React context cleanly in functional components.

```jsx
import { createContext, useContext } from "react";

const ThemeContext = createContext("light");

function ThemedButton() {
  const theme = useContext(ThemeContext);
  return <button className={theme}>Click Me</button>;
}
```

---

# 🧠 Section 12 — Performance Optimization: useMemo & useCallback

```jsx
import { useMemo, useCallback } from "react";

function ExpensiveComputation({ num }) {
  const computed = useMemo(() => num * 2, [num]);
  const handleClick = useCallback(() => alert(computed), [computed]);

  return <button onClick={handleClick}>Show Computed</button>;
}
```

* `useMemo` memoizes **values**.
* `useCallback` memoizes **functions**.

---

# 🧠 Section 13 — Custom Hooks

Custom hooks encapsulate reusable logic.

```jsx
import { useState, useEffect } from "react";

function useFetch(url) {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch(url)
      .then(res => res.json())
      .then(setData);
  }, [url]);

  return data;
}

// Usage
function App() {
  const data = useFetch("/api/items");
  return <pre>{JSON.stringify(data, null, 2)}</pre>;
}
```

* Must **start with `use`**.
* Keeps logic reusable and declarative.

---

# 🧠 Section 14 — Full Example App: Todo Dashboard

**Goal:** Build a simple **Todo Dashboard**.

### App.js

```jsx
import React, { useState } from "react";
import Navbar from "./Navbar";
import TodoList from "./TodoList";
import Counter from "./Counter";

function App() {
  const [todos, setTodos] = useState([
    { id: 1, text: "Learn JSX" },
    { id: 2, text: "Understand Props" },
    { id: 3, text: "Manage State" },
  ]);

  return (
    <div>
      <Navbar title="React Todo Dashboard" />
      <TodoList items={todos} />
      <Counter />
    </div>
  );
}

export default App;
```

### Navbar.js

```jsx
function Navbar({ title }) {
  return <h1>{title}</h1>;
}

export default Navbar;
```

### TodoList.js

```jsx
function TodoList({ items }) {
  return (
    <ul>
      {items.map((todo) => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
}

export default TodoList;
```

### Counter.js

```jsx
import { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <>
      <p>Count: {count}</p>
      <button onClick={() => setCount(count + 1)}>+</button>
    </>
  );
}

export default Counter;
```

---

# 🧠 Section 15 — React Mental Models

**Component Tree:**

```
<App state={todos}>
   ├─ <Navbar title="React Todo Dashboard" />
   ├─ <TodoList items={todos} />
   └─ <Counter state={count} />
```

**Data Flow:**

```
Props flow down → Events flow up
State change → triggers re-render → Virtual DOM diff → DOM update
```

---

# 🧾 Addendum A — Full Project Code

**Project Structure:**

```
react_todo_dashboard/
├── public/
│   └── index.html
├── src/
│   ├── App.js
│   ├── Navbar.js
│   ├── TodoList.js
│   ├── Counter.js
│   └── index.js
├── package.json
└── README.md
```

**index.js**

```jsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<App />);
```

**package.json**

```json
"dependencies": {
  "react": "^18.2.0",
  "react-dom": "^18.2.0",
  "react-scripts": "5.0.1"
}
```

---

# 🧾 Addendum B — Visual Cheat Sheet

**Props, State, Events**

```
Props -> Child (immutable)
State -> Internal, triggers re-render
Events -> Handlers -> State change -> UI update
```

**Component Tree Example:**

```
<App state={todos}>
   |
   |-- <Navbar title="React Dashboard" />
   |-- <TodoList items={todos} />
   |-- <Counter state={count} />
```

**CRUD-like Mental Flow:**

```
User interacts -> Event -> setState -> Component re-render -> Virtual DOM diff -> DOM update
```

**Mnemonic:**

> Props = input, State = internal memory, Event = trigger, useEffect = side effects

---

# 🧾 Addendum C — React Hooks Flow & Cheat Sheet

**Purpose:** Quick visual reference for **all major hooks**, when to use them, and mental models for their behavior.

---

## **1️⃣ Core Hooks Overview**

| Hook          | Purpose                       | Input / Output               | Mental Model                                                          |
| ------------- | ----------------------------- | ---------------------------- | --------------------------------------------------------------------- |
| `useState`    | Local state                   | `[state, setState]`          | State changes → re-render → UI updates                                |
| `useEffect`   | Side effects                  | Callback + dependencies      | Mount → Run effect → Dependency changes → Re-run → Cleanup on unmount |
| `useContext`  | Consume context               | `useContext(Context)`        | Pulls data from context provider anywhere in component tree           |
| `useRef`      | Persistent value / DOM ref    | `{ current: ... }`           | Value persists across renders, doesn’t trigger re-render              |
| `useMemo`     | Memoize expensive computation | Value returned from function | Recalculate only if dependencies change                               |
| `useCallback` | Memoize function              | Memoized function            | Function identity stable unless dependencies change                   |

---

## **2️⃣ Mental Flow Diagram — State & Hooks**

```
Component Render
       ↓
useState -> Internal State updated
       ↓
useEffect -> Side Effects run after render
       ↓
Virtual DOM diff
       ↓
DOM updated
       ↓
User sees updated UI
```

**Key Notes:**

* `useState` triggers re-render
* `useEffect` runs **after** render
* `useRef` stores values **without triggering re-render**
* `useMemo` & `useCallback` optimize performance

---

## **3️⃣ Hook Usage Patterns**

### **useState — Multiple States**

```jsx
const [count, setCount] = useState(0);
const [name, setName] = useState("Alice");
```

> Use separate `useState` calls for unrelated state, not a single object.

---

### **useEffect — Dependencies**

```jsx
useEffect(() => {
  console.log("Effect ran!");
}, [count]); // runs only when count changes
```

**Patterns:**

* `[]` → Run once (mount)
* `[dep1, dep2]` → Run when any dependency changes
* No array → Run after **every render**

---

### **useRef — DOM Access & Persistent Values**

```jsx
const inputRef = useRef();
<input ref={inputRef} />
```

* Perfect for focus, scroll, or timers
* Stores values without triggering re-render

---

### **useContext — Global State Access**

```jsx
const theme = useContext(ThemeContext);
```

* Avoid prop drilling
* Works seamlessly in functional components

---

### **useMemo / useCallback — Optimization**

```jsx
const computedValue = useMemo(() => expensiveFunction(num), [num]);
const memoizedFn = useCallback(() => doSomething(value), [value]);
```

* Prevents unnecessary recalculation or re-rendering
* Only use for expensive computations or stable function references

---

### **Custom Hook — Reusable Logic**

```jsx
function useFetch(url) {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch(url).then(res => res.json()).then(setData);
  }, [url]);

  return data;
}
```

> Encapsulate repeated logic, keep components clean and declarative

---

## **4️⃣ Quick Hook Mnemonic**

```
useState = memory
useEffect = side effect
useContext = global info
useRef = persistent reference
useMemo = memoized value
useCallback = memoized function
```

---

## **5️⃣ Hooks Flow Diagram — Lifecycle Mental Model**

```
Initial Mount
   ├─ useState -> state initialized
   ├─ useEffect -> run effect
   └─ DOM render

State Update
   ├─ setState -> triggers re-render
   ├─ useMemo/useCallback -> recalc if deps changed
   └─ useEffect -> run effect if deps changed

Unmount
   └─ useEffect cleanup
```

---

✅ **Tips for Mastery:**

1. Always declare **dependencies** in `useEffect`, `useMemo`, `useCallback`.
2. Keep **custom hooks small and focused**.
3. Avoid excessive memoization; optimize **only when needed**.
4. Remember: **Hooks = Declarative Lifecycle + State Management**.

---

