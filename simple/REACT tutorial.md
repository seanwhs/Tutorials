# 📘 Modern React Tutorial — Functional Components & Hooks

**Goal:** Build a deep understanding of modern React (2018+), using **functional components with Hooks**, mental models, best practices, and hands-on examples.

---

# 🎯 Learning Objectives

By the end of this tutorial, you will:

1. Understand the **philosophy behind React** and why **functional components** are now the standard.
2. Use **JSX, components, props, state, and hooks** to build dynamic UIs.
3. Implement **conditional rendering, lists, keys, and events** efficiently.
4. Understand **component hierarchy, data flow, and reactivity mental models**.
5. Build a **complete React app** from scratch.
6. Reference **full project code (Addendum A)** and **visual cheat sheet (Addendum B)**.

---

# 🧠 Section 1 — Introduction to React

React is a **declarative JavaScript library for building UIs**. Its main advantage is that it allows you to describe *what* the UI should look like rather than *how* to manipulate the DOM directly.

* **Declarative:** You tell React *what the UI should be*. React figures out the DOM changes.
* **Component-based:** UI is broken into reusable, self-contained **components**.
* **Virtual DOM:** React maintains a virtual representation of the DOM to efficiently update only the changed elements.

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

**Key Concept:** You rarely manipulate the DOM directly in React. You manipulate **state** and **props**, and React ensures the UI updates efficiently.

---

# 🧠 Section 2 — Why Functional Components?

Modern React development almost exclusively uses **functional components with Hooks**.

**Historical Context:**

* Before React 16.8: Functional components were stateless; state and lifecycle methods required **class components**.
* After React 16.8: Hooks allowed **stateful logic in functional components**, eliminating most use cases for classes.

**Advantages of Functional Components:**

1. **Simplicity:** No constructors, `this`, or method binding.
2. **Better Readability:** Logic can be grouped in one place with hooks.
3. **Easier Testing:** Pure functions with hooks are easier to test.
4. **Performance:** Slightly lighter than classes and easier to optimize.

**Example Comparison:**

```javascript
// Class Component (Legacy)
class Counter extends React.Component {
  constructor(props) {
    super(props);
    this.state = { count: 0 };
  }

  render() {
    return <button onClick={() => this.setState({ count: this.state.count + 1 })}>
      {this.state.count}
    </button>;
  }
}

// Functional Component (Modern)
function Counter() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(count + 1)}>{count}</button>;
}
```

**Mental Model:** Functional components are just **functions that accept props and return JSX**, optionally with internal state managed by hooks.

---

# 🧠 Section 3 — JSX: JavaScript XML

JSX allows you to **write HTML-like syntax inside JavaScript**. It improves readability and maintains **logic + UI cohesion**.

```jsx
const name = "Alice";
const element = <h1>Hello, {name}!</h1>;
```

* JSX is **not required**, but it simplifies component rendering.
* JavaScript expressions inside JSX use `{}`.
* Must have a **single parent element**, or use fragments (`<> </>`).

**Mental Model:**

```
JSX -> React.createElement() -> Virtual DOM -> DOM
```

---

# 🧠 Section 4 — Components & Props

A **component** is a function that returns JSX. **Props** are **inputs from a parent** and are **immutable**.

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
Parent component defines props
     ↓
Child component receives props
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
* Avoid complex nested objects unless needed.

---

# 🧠 Section 6 — Event Handling

React events are **normalized across browsers**.

```jsx
<button onClick={() => alert("Clicked!")}>Click Me</button>
```

* Handlers are **functions**, can be inline or external.
* Pass parameters using arrow functions:

```jsx
<button onClick={() => handleDelete(id)}>Delete</button>
```

---

# 🧠 Section 7 — Conditional Rendering

React allows **inline conditional rendering**:

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

Render arrays dynamically using `map()`:

```jsx
function TodoList({ todos }) {
  return (
    <ul>
      {todos.map((todo, i) => (
        <li key={i}>{todo}</li>
      ))}
    </ul>
  );
}
```

* **Key** is required for React diffing
* Avoid using index if the list can reorder
* Prefer unique IDs if available

---

# 🧠 Section 9 — Side Effects with useEffect

`useEffect` replaces class lifecycle methods (`componentDidMount`, `componentDidUpdate`, `componentWillUnmount`).

```jsx
import { useState, useEffect } from "react";

function Timer() {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => setSeconds(s => s + 1), 1000);
    return () => clearInterval(interval);
  }, []); // Empty dependency = run once
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

# 🧠 Section 10 — Full Example App: Todo Dashboard

**Goal:** Build a simple **Todo Dashboard** with multiple components.

### App.js

```jsx
import React, { useState } from "react";
import Navbar from "./Navbar";
import TodoList from "./TodoList";
import Counter from "./Counter";

function App() {
  const [todos, setTodos] = useState([
    "Learn JSX",
    "Understand Props",
    "Manage State",
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
      {items.map((todo, i) => (
        <li key={i}>{todo}</li>
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

# 🧠 Section 11 — React Mental Models

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

