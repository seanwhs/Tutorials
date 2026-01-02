# 📘 Modern React Tutorial — Functional Components, Hooks & Lifecycle

**Goal:** Build a deep understanding of modern React (2018+), using **functional components with Hooks**, lifecycle concepts, mental models, best practices, and hands-on examples.

---

# 🎯 Learning Objectives

By the end of this tutorial, you will:

1. Understand the **philosophy behind React** and why **functional components with Hooks** are the standard.
2. Use **JSX, components, props, state, and hooks** to build dynamic, reactive UIs.
3. Implement **conditional rendering, lists, keys, and events** efficiently.
4. Understand **component hierarchy, data flow, and lifecycle mental models**.
5. Build a **complete React app** from scratch.
6. Reference **full project code (Addendum A)** and **visual cheat sheet (Addendum B)**.

---

# 🧠 Section 1 — Introduction to React

React is a **declarative JavaScript library for building UIs**. Its core principle: describe *what* the UI should look like, not *how* to manipulate the DOM.

* **Declarative:** Describe UI, React handles updates.
* **Component-based:** UI is built from reusable **components**.
* **Virtual DOM:** Efficiently updates only what changes.

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

**Key Concept:** In React, you **never manipulate the DOM directly**. Instead, you change **state** and **props**, and React updates the DOM efficiently.

---

# 🧠 Section 2 — Functional Components & Hooks

Modern React uses **functional components with Hooks** almost exclusively.

**Historical Context:**

* Before React 16.8: functional components were stateless; lifecycle and state required **class components**.
* After React 16.8: **Hooks** allow state, side effects, context, and lifecycle in functional components.

**Advantages of Functional Components:**

1. **Simplicity:** No constructors, `this`, or method binding.
2. **Better Readability:** Logic grouped using hooks.
3. **Easier Testing:** Pure functions are simpler to test.
4. **Performance:** Lightweight, easier to optimize.

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

**Mental Model:** Functional components = **functions receiving props → returning JSX**, optionally with internal state via hooks.

---

# 🧠 Section 3 — JSX: JavaScript XML

JSX lets you **write HTML-like syntax in JS**, keeping **UI + logic cohesive**.

```jsx
const name = "Alice";
const element = <h1>Hello, {name}!</h1>;
```

* Optional but improves readability.
* Use `{}` for expressions.
* Single parent element required; use fragments `<> </>` if needed.

**Mental Model:**

```
JSX -> React.createElement() -> Virtual DOM -> DOM
```

---

# 🧠 Section 4 — Components & Props

**Components** are functions returning JSX. **Props** are immutable inputs from parent components.

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

**State** = internal, mutable data → triggers re-render on change.

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

* Use separate `useState` for unrelated state.
* Avoid deeply nested objects unless necessary.

---

# 🧠 Section 6 — Event Handling

React events are **normalized across browsers**.

```jsx
<button onClick={() => alert("Clicked!")}>Click Me</button>
```

* Handlers = functions (inline or external).
* Pass parameters with arrow functions:

```jsx
<button onClick={() => handleDelete(id)}>Delete</button>
```

---

# 🧠 Section 7 — Conditional Rendering

React supports inline conditional rendering:

```jsx
function Greeting({ isLoggedIn }) {
  return (
    <div>
      {isLoggedIn ? <p>Welcome back!</p> : <p>Please log in</p>}
    </div>
  );
}
```

* Ternary for simple conditions.
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

* **Key** required for React diffing.
* Avoid using array index if list can reorder.
* Prefer unique IDs.

---

# 🧠 Section 9 — Component Lifecycle & useEffect

Functional components **replace class lifecycles with `useEffect`**.

| Phase   | Class Method           | Functional Equivalent               |
| ------- | ---------------------- | ----------------------------------- |
| Mount   | `componentDidMount`    | `useEffect(() => {...}, [])`        |
| Update  | `componentDidUpdate`   | `useEffect(() => {...}, [deps])`    |
| Unmount | `componentWillUnmount` | `return () => {...}` in `useEffect` |

**Example — Timer with full lifecycle:**

```jsx
import { useState, useEffect } from "react";

function Timer() {
  const [seconds, setSeconds] = useState(0);

  // Mount
  useEffect(() => {
    console.log("Mounted: Timer started");
    const interval = setInterval(() => setSeconds(s => s + 1), 1000);

    // Cleanup → Unmount
    return () => {
      console.log("Unmounted: Timer stopped");
      clearInterval(interval);
    };
  }, []);

  // Update
  useEffect(() => {
    console.log("Updated: seconds =", seconds);
  }, [seconds]);

  return <p>Seconds: {seconds}</p>;
}
```

**Mental Model:**

```
Initial Mount → run effect (componentDidMount)
State Update → run effect if dependencies changed (componentDidUpdate)
Unmount → cleanup effect (componentWillUnmount)
```

---

# 🧠 Section 10 — useRef for DOM & Persistent Values

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

* Useful for DOM access, timers, or persistent values without triggering re-renders.

---

# 🧠 Section 11 — useContext

```jsx
import { createContext, useContext } from "react";

const ThemeContext = createContext("light");

function ThemedButton() {
  const theme = useContext(ThemeContext);
  return <button className={theme}>Click Me</button>;
}
```

* Avoids prop drilling.
* Works seamlessly in functional components.

---

# 🧠 Section 12 — useMemo & useCallback

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

```jsx
function useFetch(url) {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch(url).then(res => res.json()).then(setData);
  }, [url]);

  return data;
}
```

> Encapsulate repeated logic; keeps components clean and declarative.

---

# 🧠 Section 14 — Full Example App: Todo Dashboard

**App.js**

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

**Navbar.js, TodoList.js, Counter.js** — same as before.

---

# 🧠 Section 15 — React Mental Models & Lifecycle

```
<App state={todos}>
   ├─ <Navbar title="React Todo Dashboard" />
   ├─ <TodoList items={todos} />
   └─ <Counter state={count} />

Lifecycle:
   ├─ Mount: useEffect([]) → runs once
   ├─ Update: useEffect([deps]) → runs on dependency change
   └─ Unmount: cleanup function in useEffect
```

**Data Flow:**

```
Props → down
Events → up
State change → re-render → Virtual DOM diff → DOM update
Hooks → manage side effects, lifecycle, memoization
```

---

# 🧾 Addendum A — Project Code

**Same as original** — App.js, Navbar.js, TodoList.js, Counter.js, index.js, package.json.

---

# 🧾 Addendum B — Visual Cheat Sheet

**Props, State, Events, Lifecycle**

```
Props = immutable input
State = internal memory
Events = triggers
useEffect = side effects (mount/update/unmount)
useRef = persistent reference
useMemo = memoized value
useCallback = memoized function
```

**CRUD Flow + Lifecycle:**

```
User interacts → Event → setState → Component re-render → Virtual DOM diff → DOM update
Effect runs after render → cleanup on unmount
```

---

# 🧾 Addendum C — Hooks & Lifecycle Cheat Sheet

**Hooks + Lifecycle Flow:**

```
Initial Mount
   ├─ useState -> initialize state
   ├─ useEffect [] -> run mount effect
   └─ DOM render

State Update
   ├─ setState -> re-render
   ├─ useEffect [deps] -> run effect if dependencies changed
   └─ useMemo/useCallback -> optimize computation

Unmount
   └─ useEffect cleanup -> runs before component removed
```

**Quick Mnemonic:**

```
useState = memory
useEffect = side effects (mount/update/unmount)
useContext = global info
useRef = persistent reference
useMemo = memoized value
useCallback = memoized function
```

---

✅ **Tips for Mastery:**

1. Declare **dependencies** in `useEffect`, `useMemo`, `useCallback`.
2. Keep **custom hooks small**.
3. Optimize **only when needed**.
4. Remember: **Hooks = Declarative Lifecycle + State Management**.

---

This version is **fully integrated**, modern, lifecycle-aware, and keeps your **mental models + examples + cheat sheets** intact.

---

