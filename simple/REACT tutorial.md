# 📘 Modern React Tutorial — Functional Components, Hooks, Virtual DOM & Pure Functions

## Goal

Build a **deep, first-principles understanding of modern React (2018+)** grounded in:

* **Functional components**
* **Hooks**
* **Pure function mental models**
* **Virtual DOM mechanics**
* **Lifecycle behavior**
* **Predictable state-driven UI design**
* **Hands-on, end-to-end examples**

This tutorial is intentionally written to help you **reason about React**, not just write React.

---

# 🎯 Learning Objectives

By the end of this tutorial, you will be able to:

1. Explain the **design philosophy behind React**, including why **functional components, Hooks, and pure functions** form its foundation.
2. Use **JSX, components, props, state, and hooks** to build predictable, reactive user interfaces.
3. Implement **event handling, conditional rendering, lists, and keys** correctly and efficiently.
4. Develop precise mental models for **component hierarchy, unidirectional data flow, lifecycle phases, and the Virtual DOM**.
5. Build and reason about a **complete React application** from scratch.
6. Use **Addendum A (full project code)**, **Addendum B (visual cheat sheets)**, and **Addendum C (Hooks + lifecycle flows)** as long-term reference material.

---

# 🧠 Section 1 — React, the DOM, and the Virtual DOM

<img width="800" height="533" alt="image" src="https://github.com/user-attachments/assets/045e0843-0d70-45c6-82fd-26ce86e5adfe" />

React is a **declarative JavaScript library for building user interfaces**.

Its foundational idea is:

> **UI = f(state)**
> The UI is a *pure function* of application state.

This single idea explains **components, hooks, rendering, and the Virtual DOM**.

---

## Core Characteristics of React

* **Declarative**
  You describe *what the UI should be*, not *how to update the DOM*.
* **Component-based**
  The UI is composed of small, reusable units.
* **Pure-function-oriented**
  Components are written as **pure functions of props and state**.
* **Virtual DOM–driven**
  React optimizes DOM updates using an in-memory representation.

---

## How Browsers Render Without React

### Browser Parses HTML → DOM

<img width="1806" height="543" alt="image" src="https://github.com/user-attachments/assets/29c3e29b-080d-406c-acc3-eaf2f609acf0" />

The browser parses HTML and constructs a **DOM tree in memory**.

```
HTML
  ↓ (parse)
DOM (in memory)
```

The DOM becomes the browser’s **source of truth**.

---

### JavaScript Imperatively Mutates the DOM

<img width="1669" height="697" alt="image" src="https://github.com/user-attachments/assets/211c43f3-a52c-49f0-b923-291a6ae442ad" />

JavaScript uses **browser APIs** to mutate the DOM directly.

This is **imperative programming**:
you describe *how* to change things step-by-step.

```
User Action
      ↓
JavaScript
      ↓
Browser DOM API
      ↓
DOM Mutation
```

**Example — Imperative DOM Manipulation**

```javascript
document.getElementById('btn').addEventListener('click', function () {
  document.getElementById('page-title').textContent = 'New Title';
});
```

---

### Browser Re-renders on DOM Mutation

```
DOM Change
   ↓
Browser Re-render
   ↓
Updated UI
```

---

### ⚠️ Limitations of Imperative DOM Code

* UI logic scattered across event handlers
* State hidden inside DOM nodes
* Tight coupling between logic and structure
* Difficult to reason about correctness
* Poor scalability

```
More Features
 → More DOM Code
   → More Coupling
     → More Bugs
```

---

# 🧠 How React Changes the Model

## React’s Declarative + Pure Function Model

React **inverts control**.

Instead of mutating the DOM, you **recompute the UI**.

---

### Step 1 — State Is the Source of Truth

```
State
  ↓
UI
```

The DOM is no longer authoritative — **state is**.

---

### Step 2 — Components as Pure Functions

```jsx
function App({ title }) {
  return <h1>{title}</h1>;
}
```

This function is **pure**:

* Same input → same output
* No side effects
* No DOM manipulation

---

### Step 3 — State Change Triggers Re-computation

```jsx
function App() {
  const [title, setTitle] = React.useState("Old Title");

  return (
    <>
      <h1>{title}</h1>
      <button onClick={() => setTitle("New Title")}>
        Change Title
      </button>
    </>
  );
}
```

```
State Change
     ↓
Re-run Pure Component Functions
     ↓
Virtual DOM
     ↓
Diff
     ↓
DOM
```

---

### Step 4 — Browser Re-renders Automatically

You never manually touch the DOM.

---

## 🆚 Mental Model Comparison

```
Imperative DOM                 React
----------------              ----------------
DOM is truth                  State is truth
Manual updates                Pure function recompute
Hard to reason                Predictable
Fragile                       Scales well
```

---

## ASCII Diagram — Rendering Flow

```
User Event
   ↓
setState
   ↓
Component Functions (Pure)
   ↓
Virtual DOM
   ↓
Diff
   ↓
Real DOM
```

---

# 🧠 Section 2 — Components, Purity & Rendering

React components are **functions that take inputs and return UI**.

The key idea: **components are pure functions**, and **side effects live in hooks**.

---

## **2.1 Component as a Pure Function**

```
Component = f(props, state) → JSX
```

* **Inputs:** `props` and `state`
* **Output:** JSX (what the UI should look like)
* **Rule:** Never directly modify external state, the DOM, or perform side effects inside the render function

**Example — Pure Component:**

```jsx
function Greeting({ name }) {
  return <h1>Hello, {name}</h1>; // output depends only on props
}
```

**Why Pure?**

* Predictable: same inputs → same output every time
* Testable: you can render the component and check output without worrying about side effects
* Easy to reason about: no hidden mutations

---

## **2.2 What Are Side Effects?**

Side effects are **operations that affect something outside the function**.

Examples:

* DOM manipulation (`document.getElementById…`)
* API calls (`fetch`)
* Timers (`setTimeout`)
* Logging or global state changes

**Don’t do these inside render.**

---

## **2.3 Controlled Impurity via Hooks**

React uses **hooks** to handle side effects **after the render**, keeping the render function pure.

**Example — Moving Side Effect to `useEffect`:**

```jsx
import { useState, useEffect } from "react";

function Greeting({ name }) {
  const [message, setMessage] = useState("");

  // Side effect: runs after render
  useEffect(() => {
    setMessage(`Hello, ${name}`);
  }, [name]);

  return <h1>{message}</h1>; // render stays pure
}
```

**Explanation:**

* The render function just returns JSX
* `useEffect` handles the side effect (updating state based on props)
* Result: predictable, testable, safe rendering

---

## **2.4 Visual Mental Model**

```
Props + State
      ↓
Render Function (Pure)
      ↓
JSX → Virtual DOM
      ↓
Diff → Real DOM
```

```
Hooks (useEffect, useRef, useContext, etc.)
      ↘ side effects
      ↘ controlled impurity (does not break render purity)
```

---

## **2.5 Key Takeaways**

1. **Components = pure functions**: always return JSX based on inputs
2. **Never perform side effects inside render**
3. **Hooks = controlled impurity**: handle side effects, timers, API calls, refs
4. This pattern makes React **predictable, testable, and easy to reason about**

---

✅ **Tip for Beginners:**
Always ask yourself:

> “Does this code change something outside the render function?”

* Yes → put it in a **hook** (`useEffect`, `useRef`)
* No → keep it in the render function

---

# 🧠 Section 3 — JSX

JSX allows you to express UI declaratively.

```jsx
const element = <h1>Hello, {name}</h1>;
```

JSX does **not** break purity — it compiles to pure function calls.

```
JSX
 → React.createElement
 → Virtual DOM
```

---

# 🧠 Section 4 — Components & Props (Pure Functions & Data Flow)

In React, **components are functions** and **props are their inputs**.

This is not a metaphor — it is the **core architectural rule** of React.

> **UI = f(props)**

Every React component is expected to behave like a **pure function**.

---

## 🔹 Props as Inputs to Pure Functions

```jsx
function Greeting({ name }) {
  return <h1>Hello, {name}</h1>;
}
```

This component is **pure**:

* Same `name` → same UI
* No modification of external variables
* No mutation of props
* No side effects during rendering

```
Props (input)
     ↓
Component Function (pure)
     ↓
Returned JSX (output)
```

React relies on this purity to safely re-run components whenever needed.

---

## 🔹 Core Rules of Props

* **Props are immutable**

  * A component must never change its props
* **Props flow one way**

  * Parent → child only
* **Changing props re-executes the component**

  * The function runs again with new inputs
* **Props represent external ownership**

  * The parent owns the data, the child consumes it

This mirrors classical functional programming:

> A function cannot mutate its arguments — it can only compute with them.

---

## 🔹 Visual Prop Flow Diagram (Single Direction)

```
┌─────────┐
│ Parent  │
│ State   │
└────┬────┘
     │ props
     ▼
┌─────────┐
│ Child   │
│ (pure)  │
└────┬────┘
     │ props
     ▼
┌─────────┐
│ Grand-  │
│ Child   │
└─────────┘
```

Key rule:

* **Data flows down**
* **Events flow up**
* **DOM is never the source of truth**

---

## 🔹 Parent → Child Data Ownership

```jsx
function App() {
  return <Greeting name="Sean" />;
}
```

```
App (owns data)
   ↓
Greeting (consumes data)
```

* `App` controls the value
* `Greeting` renders based on input
* The child cannot modify the parent’s state directly

This enforces **predictable rendering** and **traceable data flow**.

---

## 🔹 Why Purity Matters for React Rendering

When props change:

```
New Props
   ↓
Component Function Re-runs (pure)
   ↓
New Virtual DOM Snapshot
   ↓
Diff
   ↓
Minimal DOM Update
```

Because components are pure:

* React can re-run them freely
* Rendering can be paused or restarted
* Optimizations (memoization, batching) are safe

This is foundational to **Concurrent Rendering** in React 18+.

---

## 🔹 Prop Drilling (What It Is)

**Prop drilling** happens when data must be passed through components that do not use it directly.

```jsx
function App() {
  return <Layout user={user} />;
}

function Layout({ user }) {
  return <Header user={user} />;
}

function Header({ user }) {
  return <UserMenu user={user} />;
}
```

```
App
 ↓ user
Layout
 ↓ user
Header
 ↓ user
UserMenu
```

Only `UserMenu` needs `user`, but every component must forward it.

---

## 🔹 Why Prop Drilling Exists (By Design)

Prop drilling is **not a bug**.

It exists because React enforces:

* One-way data flow
* Explicit dependencies
* Immutable inputs
* Pure rendering functions

React intentionally avoids **implicit global state**.

> Explicit data flow > hidden magic

---

## 🔹 When Prop Drilling Becomes a Problem

Prop drilling becomes harmful when:

* Component trees are deep
* Many unrelated props are passed
* Intermediate components act as “pipes”
* Refactoring becomes fragile

This is a **maintainability problem**, not a performance one.

---

## 🔹 Decision Guide: Props vs Context

Use this guide **before reaching for context**.

### ✅ Use Props When:

* Data is used by **direct children**
* Data flow is clear and local
* Component hierarchy is shallow
* You want explicit dependencies

### ⚠️ Consider Context When:

* Data is needed by **many distant descendants**
* Props are passed only to be forwarded
* The data is **conceptually global**

  * theme
  * auth user
  * locale
  * feature flags

```
Props = explicit, local, predictable
Context = shared, global, implicit
```

Context **reduces plumbing**, not complexity.

---

## 🔹 Forward Reference: Section 11 — `useContext`

React’s solution to excessive prop drilling is **Context**.

Context allows components to **consume data without receiving it as props**, while still preserving:

* Purity
* Predictable re-renders
* Virtual DOM diffing

In **Section 11**, you will learn how:

```
Context Provider
      ↓
(useContext)
      ↓
Component Function
```

> Think of Context as **implicit props provided by React**, not a replacement for props.

---

## ✅ Key Takeaways

* React components are **pure functions**
* Props are **immutable inputs**
* Changing props re-runs the function
* Prop drilling is a **natural consequence of purity**
* Context exists to **reduce unnecessary prop forwarding**
* Props + Context both preserve **declarative rendering**

---

# 🧠 Section 5 — State with `useState` (Controlled Impurity & Data Flow)

React components are still **pure functions**, but state introduces **controlled impurity**: a way for components to **remember values over time** without breaking predictability.

> Pure function + controlled impurity = dynamic but predictable UI.

---

## 🔹 Basic Counter Example

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

* `count` → current state
* `setCount` → schedules the **next state update**
* Component **function remains pure**: it does not mutate DOM directly

```
UI = f(props, state)
```

---

## 🔹 Mental Model: Pure Functions + Controlled Impurity

1. Component runs → produces UI from **props + state**
2. React tracks state **outside the function**
3. `setState` schedules **re-render**
4. Component re-runs → new Virtual DOM
5. React performs **minimal DOM update** via diffing

```
Initial Render:
props + state=0
        ↓
Component Function (pure)
        ↓
Virtual DOM Snapshot
        ↓
Real DOM Update
```

```
State Change (setCount):
props + state=1
        ↓
Component Function re-runs
        ↓
Virtual DOM diff
        ↓
Minimal Real DOM Update
```

---

## 🔹 Key Characteristics of `useState`

* **Local to component** — isolated memory slot
* **State updates are scheduled**, not immediate
* **Component remains pure** — output depends on props + state
* **Virtual DOM ensures efficient updates**

> Controlled impurity = dynamic behavior, predictable rendering

---

## 🔹 State vs Props

| Aspect     | Props            | State                  |
| ---------- | ---------------- | ---------------------- |
| Ownership  | Parent           | Local component        |
| Mutability | Immutable        | Mutable via setter     |
| Trigger    | Parent re-render | `setState` call        |
| Purpose    | Configure UI     | Track dynamic behavior |

---

## 🔹 Data Flow Scenarios (Visual)

### 1️⃣ Props Only (Pure Function, No State)

```
App (state: userName="Alice")
      │ props
      ▼
Greeting({name})
      │
      └─ JSX → Virtual DOM → DOM
```

* Component is **pure**
* UI fully determined by **props**
* No memory inside component

---

### 2️⃣ Props + Local State (`useState`) — Controlled Impurity

```
App
      │
      ▼
Counter (useState count=0)
      │
      └─ JSX → Virtual DOM → DOM
```

* Component stores **its own internal state**
* Calling `setCount` schedules a **re-render**
* Component function **remains pure**: same props + same state → same UI
* React manages state **outside the function**

```
User clicks "+"
     ↓
setCount triggers re-render
     ↓
Component function re-runs
     ↓
Virtual DOM diff → minimal DOM update
     ↓
UI updated
```

---

### 3️⃣ Props + Context (`useContext`) — Implicit Inputs

```
ThemeProvider (value="dark")
      │ context
      ▼
ThemedButton
      │
      └─ JSX → Virtual DOM → DOM
```

* Component receives **implicit input from context**
* Still **pure function**: same props + same context → same UI
* Reduces **prop drilling** through intermediate components

---

## 🔹 State + Prop Drilling

Sometimes **state lives in parent** to share it across children:

```jsx
function CounterParent() {
  const [count, setCount] = useState(0);
  return <Counter count={count} onIncrement={() => setCount(count + 1)} />;
}
```

* Prevents multiple independent states
* If many components need the same state → consider **Context** (Section 11)

```
App
   │ state
   ▼
CounterParent
   │ props
   ▼
Counter
```

---

## 🔹 Best Practices for `useState`

1. **Initialize state with meaningful defaults**
2. **Avoid deeply nested objects** → consider multiple `useState` hooks or `useReducer`
3. **Functional updates** when new state depends on previous:

```jsx
setCount(prev => prev + 1);
```

4. **Lift state only when necessary** → local state is preferable
5. Combine with **Context** to avoid excessive prop drilling

---

## 🔹 Controlled Impurity + Virtual DOM Flow Diagram

```
User Action (click)
       ↓
setState called
       ↓
Component Function re-runs (pure)
       ↓
Virtual DOM Snapshot
       ↓
Diffing Algorithm
       ↓
Minimal DOM Update
       ↓
User sees updated UI
```

---

## 🔹 Key Takeaways

* `useState` introduces **controlled impurity**
* Components remain **pure functions**: output = f(props, state)
* Virtual DOM ensures **efficient re-renders**
* Local state can **reduce prop drilling**, but **Context** is better for widely shared state
* Functional updates (`setCount(prev => prev+1)`) prevent stale closures

---

This section now fully **visualizes data flow for props, state, and context**, making it clear **how controlled impurity integrates with pure components**.

---

# 🧠 Section 6 — Event Handling (Triggering State, Not DOM)

In React, **events do not directly mutate the DOM**.
Instead, events **trigger state changes**, which then cause **controlled, predictable re-renders** via the Virtual DOM.

> Think of an event as a signal:
> **“something happened” → update state → UI recalculates**

---

## 🔹 Basic Example: Button Click Counter

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

* Clicking the button **calls `setCount`**
* React **re-runs the component function** with updated state
* The Virtual DOM calculates **minimal changes** to the real DOM
* The UI updates **without you touching the DOM**

---

## 🔹 Mental Model: Event → State → Virtual DOM → DOM

```
User Event (click)
       ↓
Event Handler
       ↓
State Setter (setCount)
       ↓
Component Function Re-run (pure)
       ↓
Virtual DOM Diff
       ↓
Minimal Real DOM Update
       ↓
Updated UI
```

* **Event handler** is just a function
* It updates **state or props**, never the DOM directly
* React maintains **purity and predictability**

---

## 🔹 Inline vs External Handlers

### Inline Handler (simple)

```jsx
<button onClick={() => setCount(count + 1)}>+</button>
```

### External Handler (recommended for complex logic)

```jsx
function Counter() {
  const [count, setCount] = useState(0);

  const increment = () => setCount(prev => prev + 1);

  return <button onClick={increment}>+</button>;
}
```

**Benefits of external handlers:**

* Cleaner JSX
* Easier to test
* Avoids creating new functions every render (useful with `useCallback`)

---

## 🔹 Passing Parameters

```jsx
<button onClick={() => handleDelete(id)}>Delete</button>
```

* Use arrow functions to **pass arguments**
* React ensures the event handler runs **only on click**
* Still triggers **state updates**, not DOM mutations

---

## 🔹 Event Normalization

React **normalizes browser events**:

* `onClick`, `onChange`, `onSubmit` are **synthetic events**
* Works consistently across browsers
* Event object is **pooled**, lightweight, and managed by React

---

## 🔹 Best Practices

1. **Do not manipulate DOM directly** inside handlers — always update state
2. **Use functional updates** if new state depends on old state:

```jsx
setCount(prev => prev + 1);
```

3. **Lift state** when multiple components need it
4. Use **Context** for widely shared state (Section 11)
5. Keep **handlers small and pure** → makes components predictable

---

## 🔹 Event Handling + Controlled Impurity (Connection to Section 5)

Events are the **trigger for controlled impurity**:

```
Click → setState → re-run pure function → Virtual DOM diff → DOM update
```

* Event handler itself is **pure** if it only calls `setState` or triggers prop callbacks
* UI updates remain **declarative**, **predictable**, and **efficient**

---

## 🔹 Event Flow with Props and Context

```
User Event
   ↓
Child Component Handler
   ↓
Local State (useState) or Context (useContext)
   ↓
Virtual DOM diff
   ↓
DOM Update
```

* Works with **props passed from parent** or **context from providers**
* Eliminates direct DOM manipulation and fragile imperative code

---

## ✅ Key Takeaways

* **React events do not mutate the DOM**
* They **trigger state or prop updates**, which drive re-renders
* Event handlers should remain **pure functions**
* Combine events with **state (Section 5)** and **context (Section 11)** for predictable, maintainable UI
* Always follow **Virtual DOM principles** for efficiency

---

# 🧠 Section 7 — Conditional Rendering (Pure Function, Dynamic Output)

In React, **conditional rendering** lets a component return **different JSX based on state, props, or context**.

> Conditional rendering is still **pure function behavior**: same inputs → same output.

---

## 🔹 Basic Example: Login / Welcome

```jsx
function App({ isLoggedIn }) {
  return (
    <div>
      {isLoggedIn ? <Welcome /> : <Login />}
    </div>
  );
}
```

* The component **returns different JSX** depending on `isLoggedIn`
* React calculates the **Virtual DOM diff** and updates only what changed in the real DOM

---

## 🔹 Mental Model: Conditional = Pure Function Output

```
Inputs: props + state + context
       ↓
Component Function executes
       ↓
JSX (conditional)
       ↓
Virtual DOM
       ↓
Minimal DOM update
```

* React **does not require you to manually manipulate the DOM**
* You only declare **what the UI should look like for each state**

---

## 🔹 Conditional Rendering Patterns

### 1️⃣ Ternary Operator (inline)

```jsx
{isLoggedIn ? <Welcome /> : <Login />}
```

### 2️⃣ Logical AND (render if true)

```jsx
{notifications.length > 0 && <NotificationList />}
```

### 3️⃣ Early Return (more complex logic)

```jsx
function Dashboard({ user }) {
  if (!user) return <Login />;
  return <UserDashboard user={user} />;
}
```

---

## 🔹 Integration with State and Events

Conditional rendering often depends on **state updated by events**:

```jsx
function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);

  return (
    <div>
      {isLoggedIn ? <Welcome /> : <Login />}
      <button onClick={() => setIsLoggedIn(!isLoggedIn)}>
        Toggle Login
      </button>
    </div>
  );
}
```

**Flow:**

```
User clicks button
       ↓
setIsLoggedIn toggles state
       ↓
Component function re-runs
       ↓
Conditional JSX evaluated
       ↓
Virtual DOM diff
       ↓
Minimal DOM update
```

---

## 🔹 Conditional Rendering + Props

You can also pass props down to dynamically rendered components:

```jsx
{isLoggedIn ? <Welcome user={user} /> : <Login onLogin={handleLogin} />}
```

* Props flow **downwards** to child components (Section 4)
* Each child is still a **pure function**: input → output

---

## 🔹 Conditional Rendering + Context

When combined with context (Section 11), conditional rendering becomes even more powerful:

```jsx
const AuthContext = createContext(false);

function App() {
  const isLoggedIn = useContext(AuthContext);

  return (
    <div>
      {isLoggedIn ? <Welcome /> : <Login />}
    </div>
  );
}
```

* No need to pass `isLoggedIn` through multiple layers of props
* Still fully **pure functional behavior**

---

## 🔹 Key Takeaways

* Conditional rendering is **just a function returning different JSX**
* **Inputs** = state + props + context
* **Outputs** = Virtual DOM snapshot → minimal real DOM update
* Works seamlessly with **state changes**, **events**, **props**, and **context**
* Preserves **pure function mental model**: same inputs → same outputs

---

### 🔹 Conditional Rendering Diagram

```
[Props + State + Context]
          ↓
Component Function
          ↓
Conditional Logic
    ┌───────────────┐
    │ isLoggedIn = true  │ → <Welcome />
    │ isLoggedIn = false │ → <Login />
    └───────────────┘
          ↓
Virtual DOM Diff
          ↓
Minimal DOM Update
```

---

This version fully connects **Section 7** to **Sections 4, 5, 6, and 11**, showing that conditional rendering:

* Uses **state** (Section 5)
* Reacts to **events** (Section 6)
* Accepts **props** (Section 4)
* Can consume **context** (Section 11)
* Always produces a **pure function output → Virtual DOM → DOM**

---

# 🧠 Section 8 — Lists and Keys (Efficient Virtual DOM Diffing)

In React, when rendering **collections**, each element needs a **stable identifier** — a **key** — so React can **diff pure render outputs efficiently**.

> Keys help React know **which elements changed, were added, or removed**, without re-rendering everything.

---

## 🔹 Basic Example: Todo List

```jsx
const todos = [
  { id: 1, text: "Learn JSX" },
  { id: 2, text: "Understand Props" },
  { id: 3, text: "Manage State" },
];

function TodoList({ todos }) {
  return (
    <ul>
      {todos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
}
```

* `key={todo.id}` → **unique, stable identity**
* Helps React **match old and new Virtual DOM nodes**
* Prevents unnecessary **remounting of components**

---

## 🔹 Mental Model: Lists + Keys = Pure Functions + Diffing

```
Input: todos array
         ↓
Component Function (pure)
         ↓
JSX with keys
         ↓
Virtual DOM diff
         ↓
Minimal DOM update
```

* Each list item is a **pure function** of its data (`todo`)
* React uses `key` to **track each item across renders**

---

## 🔹 Why Keys Matter

Without keys:

```jsx
{todos.map(todo => <li>{todo.text}</li>)}
```

* React defaults to **index-based keys**
* Adding/removing items may **recycle elements incorrectly**
* Can cause **state loss** in child components

With proper keys:

* React can **reorder, add, or remove elements efficiently**
* Preserves **internal component state** for each item

---

## 🔹 Keys + State in List Items

If a child component has its **own state**, keys are critical:

```jsx
function TodoItem({ todo }) {
  const [completed, setCompleted] = useState(false);

  return (
    <li>
      <input
        type="checkbox"
        checked={completed}
        onChange={() => setCompleted(!completed)}
      />
      {todo.text}
    </li>
  );
}

function TodoList({ todos }) {
  return (
    <ul>
      {todos.map(todo => (
        <TodoItem key={todo.id} todo={todo} />
      ))}
    </ul>
  );
}
```

* Each `TodoItem` maintains its **own internal state**
* Changing list order or updating the array **does not lose state** because **keys are stable**

---

## 🔹 Keys + Conditional Rendering

Keys also matter in **conditionally rendered lists**:

```jsx
{todos.map(todo =>
  todo.completed ? null : <TodoItem key={todo.id} todo={todo} />
)}
```

* Only non-completed items are rendered
* React still tracks items via **key**
* Avoids unnecessary **re-mounting** of unchanged items

---

## 🔹 Best Practices for Keys

1. **Use stable IDs from your data** (`todo.id`)
2. **Avoid using array index** unless items are static
3. **Ensure uniqueness** among siblings
4. **Do not change keys between renders** → triggers remount

---

## 🔹 Lists + Keys + Virtual DOM Flow

```
[State or Props: todos array]
            ↓
Component Function executes
            ↓
JSX with keys
            ↓
Virtual DOM diff
    ┌───────────────┐
    │ Compare keys   │
    │ Old vs New     │
    └───────────────┘
            ↓
Minimal DOM update
```

* Only the items that **changed, added, or removed** are updated in the real DOM
* Preserves **child component state**
* Ensures **efficient rendering at scale**

---

## ✅ Key Takeaways

* **Keys are identifiers for pure function outputs** in lists
* Essential for **efficient Virtual DOM diffing**
* Preserve **component state** across renders
* Work with **stateful child components, conditional rendering, and prop updates**
* Always prefer **unique IDs** over indices

---

This section **connects directly to Section 5 (state)**, **Section 7 (conditional rendering)**, and **Section 4 (props)**, showing that **keys are the bridge between dynamic data, pure functions, and efficient DOM updates**.

---

# 🧠 Section 9 — Lifecycle with `useEffect` (Side Effects Only)

React components are **pure functions**, which means **render functions should never have side effects**.

`useEffect` exists to **contain all side effects**, so rendering stays predictable and testable.

---

## **9.1 Controlled Side Effects**

**Side effects include:**

* API calls (`fetch`)
* Timers (`setTimeout`, `setInterval`)
* Subscribing to events
* Logging, DOM manipulations, or global state changes

**Rule:** Keep the **render function pure** and handle these in `useEffect`.

---

## **9.2 Basic Example**

```jsx
import { useState, useEffect } from "react";

function Timer() {
  const [seconds, setSeconds] = useState(0);

  // Side effect: increment timer every second
  useEffect(() => {
    const interval = setInterval(() => setSeconds(s => s + 1), 1000);
    
    // Cleanup on unmount
    return () => clearInterval(interval);
  }, []);

  return <p>Seconds: {seconds}</p>;
}
```

**Explanation:**

* Render function (`return <p>…</p>`) is pure → depends only on `seconds`
* `useEffect` handles **the side effect** (interval timer)
* React ensures `useEffect` runs **after render** → no unpredictable behavior

---

## **9.3 Lifecycle Mental Model (Functional Components)**

| Phase   | Purpose                     | Functional Equivalent                   |
| ------- | --------------------------- | --------------------------------------- |
| Mount   | Setup side effects          | `useEffect(() => { … }, [])`            |
| Update  | React to state/prop changes | `useEffect(() => { … }, [deps])`        |
| Unmount | Cleanup side effects        | `return () => { … }` inside `useEffect` |

---

## **9.4 Visual Flow — Pure Render vs Side Effects**

```
Props + State
      ↓
Render Function (Pure)
      ↓
JSX → Virtual DOM → Diff → Real DOM
```

```
useEffect / Hooks
      ↘ Side effects (API calls, timers, subscriptions)
      ↘ Cleanup (on unmount or dependency change)
```

**Key Idea:** **Render = pure** → predictable UI.
**Hooks = controlled impurity** → safe side effects.

---

## **9.5 Example — Fetch Data from API**

```jsx
function UserProfile({ userId }) {
  const [profile, setProfile] = useState(null);

  // Side effect: fetch user data
  useEffect(() => {
    fetch(`/api/user/${userId}`)
      .then(res => res.json())
      .then(setProfile);
  }, [userId]);

  if (!profile) return <p>Loading...</p>;
  return <h1>{profile.name}</h1>;
}
```

**Explanation:**

* Pure render: depends only on `profile` state
* Side effect: API fetch runs **after render**
* React updates state → triggers **controlled re-render**

---

## **9.6 Key Takeaways**

1. **Render function = pure** → no side effects
2. **`useEffect` = controlled side effects**
3. React handles **mount, update, unmount** via `useEffect` and dependency array
4. This pattern ensures **predictable, testable, and maintainable UI**

---

This now **directly connects to Section 2**, reinforcing the mental model:

```
Render Function (Pure)
      ↕
Hooks (useEffect, useRef, etc.) → controlled impurity
```

---

# 🧠 Section 10 — `useRef` (Persistent Mutable Values Without Breaking Purity)

In React, **render functions are pure**: they return JSX based on **props, state, and context**.
Sometimes, you need **mutable values that persist across renders** or **direct access to DOM nodes** — this is where `useRef` comes in.

> `useRef` provides a way to store **mutable values** or **DOM references** without triggering re-renders.

---

## 🔹 Basic Example: Focus Input

```jsx
import { useRef } from "react";

function FocusInput() {
  const inputRef = useRef();

  return (
    <>
      <input ref={inputRef} />
      <button onClick={() => inputRef.current.focus()}>
        Focus
      </button>
    </>
  );
}
```

**Explanation:**

* `inputRef` persists across renders
* Clicking the button **focuses the input** without changing component state
* **Render function remains pure** — `useRef` does **not trigger re-renders**

---

## 🔹 Mental Model: `useRef` vs `useState`

| Concept              | `useState`          | `useRef`                           |
| -------------------- | ------------------- | ---------------------------------- |
| Triggers render?     | ✅ Yes               | ❌ No                               |
| Stores mutable value | ✅ Yes               | ✅ Yes                              |
| Ideal for            | UI state            | DOM nodes, timers, previous values |
| Purity               | Controlled impurity | Preserves render purity            |

* **Key idea:** `useRef` = **mutable storage outside render flow**

---

## 🔹 Example: Storing Previous State

```jsx
import { useRef, useEffect, useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);
  const prevCountRef = useRef(0);

  useEffect(() => {
    prevCountRef.current = count;
  }, [count]);

  return (
    <div>
      <p>Current: {count}</p>
      <p>Previous: {prevCountRef.current}</p>
      <button onClick={() => setCount(count + 1)}>+</button>
    </div>
  );
}
```

**Flow:**

```
Click → setCount → re-render → JSX shows count → useEffect updates prevCountRef → ref persists without extra render
```

* `prevCountRef` stores **previous state** without causing additional renders
* Keeps **render function pure**

---

## 🔹 `useRef` + DOM Access

```jsx
function TextInput() {
  const inputEl = useRef();

  const focusInput = () => inputEl.current.focus();

  return (
    <>
      <input ref={inputEl} />
      <button onClick={focusInput}>Focus</button>
    </>
  );
}
```

* Access DOM **safely and declaratively**
* No need for **document.getElementById** or **manual DOM manipulation**

---

## 🔹 `useRef` + Event Handlers + State

* Can store **timers, intervals, or previous values**
* Works alongside **state and events** (Sections 5 & 6)
* Preserves **pure function mental model** for render

```jsx
function Stopwatch() {
  const [seconds, setSeconds] = useState(0);
  const intervalRef = useRef();

  const start = () => {
    intervalRef.current = setInterval(() => setSeconds(s => s + 1), 1000);
  };

  const stop = () => {
    clearInterval(intervalRef.current);
  };

  return (
    <div>
      <p>Seconds: {seconds}</p>
      <button onClick={start}>Start</button>
      <button onClick={stop}>Stop</button>
    </div>
  );
}
```

**Key idea:** the **interval persists in a ref**, not in state → does **not trigger re-render**, keeping rendering pure.

---

## 🔹 Ref + Context Integration

Refs can also be used with **context** (Section 11) to **share mutable values** across the component tree:

```jsx
const FocusContext = createContext();

function Parent() {
  const inputRef = useRef();

  return (
    <FocusContext.Provider value={inputRef}>
      <Child />
      <button onClick={() => inputRef.current.focus()}>Focus from Parent</button>
    </FocusContext.Provider>
  );
}

function Child() {
  const inputRef = useContext(FocusContext);
  return <input ref={inputRef} />;
}
```

* Allows **prop drilling avoidance**
* Preserves **pure function renders**
* Ref is shared via context instead of state

---

## 🔹 Flow Diagram: `useRef` Lifecycle

```
Initial Render:
  ┌───────────────┐
  │ useRef created │
  └───────┬───────┘
          ↓
Render function returns JSX (pure)
          ↓
DOM updates
          ↓
Ref persists across renders

Subsequent Renders:
  ┌───────────────────┐
  │ inputRef unchanged │
  └───────────┬───────┘
              ↓
Render function returns new JSX (pure)
              ↓
DOM updates minimal
```

---

## ✅ Key Takeaways

* `useRef` stores **mutable values that persist across renders**
* Does **not trigger re-renders** → keeps **render function pure**
* Ideal for **DOM nodes, timers, previous state, or shared mutable values**
* Works seamlessly with **state (useState), events (onClick), and context (useContext)**
* Enables **controlled impurity without breaking declarative UI**

---

# 🧠 Section 11 — `useContext` (Implicit Inputs to Pure Functions)

```jsx
import { createContext, useContext } from "react";

const ThemeContext = createContext("light");

function ThemedButton() {
  const theme = useContext(ThemeContext);
  return <button className={theme}>Click Me</button>;
}
```

`useContext` allows a component to **consume shared data without receiving it as props**.

This does **not** break React’s mental model.

Instead, it introduces **implicit inputs** to otherwise pure functions.

---

## 🔹 Context in One Sentence

> **Context is a controlled way to inject shared inputs into a component tree.**

Think of it as **React-managed parameters**, not global variables.

---

## 🔹 Context + Pure Functions (Critical Mental Model)

A component using context is still **pure**.

```
UI = f(props, context)
```

* Same props + same context → same UI
* No DOM reads
* No side effects during render
* Still re-executes predictably

Context does **not** make components stateful — it just changes *where inputs come from*.

---

## 🔹 Why Context Exists (Solving Prop Drilling)

Recall prop drilling from Section 4:

```
App
 ↓ theme
Layout
 ↓ theme
Header
 ↓ theme
Button
```

With Context:

```
ThemeProvider
      ↓
  (implicit)
      ↓
ThemedButton
```

Intermediate components no longer need to forward props they don’t care about.

---

## 🔹 Visual Context Flow Diagram

```
┌─────────────────────┐
│ ThemeProvider       │
│ value="dark"        │
└─────────┬───────────┘
          │ context
          ▼
┌─────────────────────┐
│ Any Descendant      │
│ useContext(...)     │
└─────────────────────┘
```

Key idea:

* Context flows **through the component tree**
* Consumers subscribe to changes
* React controls re-rendering

---

## 🔹 Creating and Providing Context

```jsx
import { createContext } from "react";

export const ThemeContext = createContext("light");
```

```jsx
function App() {
  return (
    <ThemeContext.Provider value="dark">
      <ThemedButton />
    </ThemeContext.Provider>
  );
}
```

```
Provider defines value
     ↓
Descendants can read value
```

---

## 🔹 Consuming Context with `useContext`

```jsx
function ThemedButton() {
  const theme = useContext(ThemeContext);
  return <button className={theme}>Click Me</button>;
}
```

What happens internally:

```
Context value changes
        ↓
Subscribed components re-render
        ↓
Virtual DOM diff
        ↓
Minimal DOM update
```

Only components that **consume** the context re-render.

---

## 🔹 Context Is Not Global State

This is a common misunderstanding.

| Context            | Global Variable     |
| ------------------ | ------------------- |
| Scoped to subtree  | Global to app       |
| Tracked by React   | Invisible to React  |
| Triggers re-render | No render awareness |
| Predictable        | Error-prone         |

Context is **React-aware shared state**, not magic.

---

## 🔹 When to Use Context (Clear Rules)

### ✅ Use Context For:

* Theme (light/dark)
* Auth user
* Locale / language
* Feature flags
* App-wide configuration

### ❌ Avoid Context For:

* Rapidly changing values
* Component-specific state
* Deeply nested, frequently updated data
* Performance-critical hot paths

> Context trades **explicitness** for **convenience**.

---

## 🔹 Context vs Props (Decision Table)

| Scenario               | Use Props | Use Context |
| ---------------------- | --------- | ----------- |
| Direct parent → child  | ✅         | ❌           |
| Many distant consumers | ❌         | ✅           |
| Local state            | ✅         | ❌           |
| App-wide configuration | ❌         | ✅           |

---

## 🔹 Context and Re-renders (Important)

When a context value changes:

* **All consuming components re-render**
* Even if they only use part of the value

Best practice:

```jsx
// Bad: large object
value={{ theme, user, locale }}

// Better: split contexts
<ThemeContext.Provider value={theme}>
<AuthContext.Provider value={user}>
```

This minimizes unnecessary re-renders.

---

## 🔹 Context Preserves React’s Core Guarantees

Context does **not** break:

* Declarative rendering
* Virtual DOM diffing
* Predictable re-renders
* Pure component functions

It simply **reduces prop plumbing**.

---

## ✅ Key Takeaways

* `useContext` provides **implicit inputs** to components
* Components remain **pure functions**
* Context solves **prop drilling**, not state management
* React controls context updates and re-renders
* Use context sparingly and intentionally

---

## 🔜 What’s Next

In the next sections, you’ll see how Context works together with:

* **`useReducer`** (complex shared state)
* **Custom Hooks** (encapsulating context logic)
* **Performance optimizations** (`useMemo`, `useCallback`)

React’s power comes from **composing small, pure primitives** — not from magic.

---

# 🧠 Section 12 — `useMemo` & `useCallback` (Memoization & Referential Stability)

In React, **re-rendering triggers component functions**, producing **pure JSX outputs**.
Sometimes, **expensive computations** or **callback functions** are recreated unnecessarily on every render.
`useMemo` and `useCallback` let us **optimize these without breaking purity**.

> They provide **referential stability**: the value or function identity remains consistent across renders unless dependencies change.

---

## 🔹 `useMemo` — Memoize Computed Values

```jsx
import { useMemo } from "react";

function Expensive({ x }) {
  const value = useMemo(() => {
    console.log("Computing...");
    return x * 2; // imagine a heavy computation
  }, [x]);

  return <p>Computed value: {value}</p>;
}
```

* `value` is **cached** between renders
* Only recomputed when `x` changes
* Avoids expensive recalculation
* Render function **remains pure**: same input → same output

---

### Mental Model: `useMemo`

```
Input: props + state
         ↓
Check deps [x]
   ┌─────────────┐
   │ Changed?     │
   ├─ Yes → recompute
   └─ No  → return cached value
         ↓
Component returns JSX → Virtual DOM → minimal DOM update
```

---

## 🔹 `useCallback` — Memoize Functions

```jsx
import { useCallback } from "react";

function Button({ onClick }) {
  return <button onClick={onClick}>Click Me</button>;
}

function App({ x }) {
  const handleClick = useCallback(() => {
    console.log("Clicked! Computed:", x);
  }, [x]);

  return <Button onClick={handleClick} />;
}
```

* `handleClick` keeps the **same function identity** unless `x` changes
* Prevents unnecessary re-renders of **memoized child components**
* Keeps **event handlers pure** in terms of inputs → outputs

---

## 🔹 Why Referential Stability Matters

* React uses **referential equality (`===`)** to decide if props changed
* Without memoization:

```jsx
<Button onClick={() => console.log(x)} />
```

* Every render creates a **new function instance** → child re-renders unnecessarily
* With `useCallback`, the function identity is stable → reduces **Virtual DOM diffing overhead**

---

## 🔹 Flow Diagram: `useMemo` & `useCallback` Integration

```
[Props + State]
       ↓
Component Function executes (pure)
       ↓
useMemo / useCallback checks dependencies
       ↓
Return memoized value/function if unchanged
       ↓
JSX → Virtual DOM diff → minimal DOM update
```

* Optimization occurs **outside the main render logic**
* Preserves **pure function mental model**
* Works seamlessly with **state (useState), events (onClick), refs (useRef), context (useContext)**

---

## 🔹 Practical Example: List with Expensive Render

```jsx
function TodoItem({ todo, computeValue }) {
  const memoizedValue = useMemo(() => computeValue(todo.id), [todo.id, computeValue]);
  return <li>{memoizedValue}</li>;
}
```

* `computeValue` only runs for **changed items**
* `useMemo` + `key` (Section 8) = **efficient list rendering**
* Avoids recalculation for unchanged items → faster **Virtual DOM diffing**

---

## ✅ Key Takeaways

* **`useMemo`** → memoize values for expensive calculations
* **`useCallback`** → memoize functions to maintain identity
* Both maintain **referential stability** without breaking **pure function renders**
* Integrates seamlessly with **state, props, events, refs, context, lifecycle, conditional rendering, and lists**
* Critical for **performance optimization at scale**

---

# 🧠 Section 13 — Custom Hooks (Reusable Logic for Clean Components)

React encourages **pure functional components**: they take **props, state, and context** and return **JSX**.

> When multiple components share **side-effect logic or complex state updates**, repeating code breaks clarity.
> **Custom hooks** let you **extract logic** while keeping components **clean, pure, and declarative**.

---

## 🔹 Basic Example: Data Fetch Hook

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
```

**Usage:**

```jsx
function UsersList() {
  const users = useFetch("/api/users");

  if (!users) return <p>Loading...</p>;
  return (
    <ul>
      {users.map(u => <li key={u.id}>{u.name}</li>)}
    </ul>
  );
}
```

* `useFetch` encapsulates **side-effect logic** (fetch + state)
* Component remains **pure**: only renders JSX based on returned `data`
* **Dependencies** are explicit (`url`) → predictable updates

---

## 🔹 Mental Model: Custom Hook Flow

```
[Input: props or args]
       ↓
Custom Hook executes
       ├─ useState → stores local state
       ├─ useEffect → side effects (e.g., fetch, timers)
       └─ useMemo/useCallback → optimize calculations
       ↓
Returns value(s) → used by component
       ↓
Component renders JSX (pure) → Virtual DOM → minimal DOM update
```

* Hooks can be **composed** (use one hook inside another)
* Logic is **reusable** and **isolated**

---

## 🔹 Advanced Example: Fetch + Memoized Computation

```jsx
import { useState, useEffect, useMemo } from "react";

function useUserData(url) {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch(url)
      .then(res => res.json())
      .then(setData);
  }, [url]);

  const activeUsers = useMemo(() => {
    return data ? data.filter(u => u.active) : [];
  }, [data]);

  return activeUsers;
}
```

**Usage:**

```jsx
function ActiveUsers() {
  const users = useUserData("/api/users");

  return (
    <ul>
      {users.map(u => <li key={u.id}>{u.name}</li>)}
    </ul>
  );
}
```

* Combines **state, side-effects, memoization, and pure rendering**
* Logic is **encapsulated** → component only concerns itself with **UI**
* **Efficient Virtual DOM updates** occur automatically when data changes

---

## 🔹 Custom Hooks + `useRef` + `useContext`

Custom hooks can also integrate **refs** and **context**:

```jsx
import { useContext, useRef, useState, useEffect } from "react";
const ThemeContext = createContext("light");

function useFocusAndTheme() {
  const inputRef = useRef();
  const theme = useContext(ThemeContext);
  const [value, setValue] = useState("");

  useEffect(() => {
    inputRef.current?.focus();
  }, []);

  return { inputRef, value, setValue, theme };
}

function TextInput() {
  const { inputRef, value, setValue, theme } = useFocusAndTheme();
  return (
    <input
      ref={inputRef}
      className={theme}
      value={value}
      onChange={e => setValue(e.target.value)}
    />
  );
}
```

* Combines **state, refs, context, and side-effects**
* Component remains **pure and declarative**
* Logic is **centralized, reusable, and testable**

---

## 🔹 Custom Hooks + Performance Optimization

Custom hooks can also integrate **`useMemo`** and **`useCallback`** to **avoid unnecessary recalculation or re-renders**:

```jsx
function useSortedUsers(url) {
  const users = useFetch(url);

  const sortedUsers = useMemo(() => {
    return users ? [...users].sort((a,b) => a.name.localeCompare(b.name)) : [];
  }, [users]);

  return sortedUsers;
}
```

* Only recalculates sorted array when **users change**
* Preserves **referential stability**
* Works seamlessly with **lists & keys (Section 8)**

---

## 🔹 Flow Diagram: Custom Hook Integration

```
[Props + Context + Ref + State]
          ↓
Custom Hook executes
 ┌────────┼─────────┐
 │ useState → local state
 │ useEffect → side effects
 │ useMemo/useCallback → optimization
 │ useRef → persistent values
 └────────┼─────────┘
          ↓
Returns value(s) → Component
          ↓
Component renders JSX → Virtual DOM diff → minimal DOM update
```

* All logic is **encapsulated**
* Component only **describes UI**
* Maintains **pure functional mental model**

---

## ✅ Key Takeaways

1. **Custom hooks** encapsulate reusable logic, side effects, and computations
2. Keep components **pure and declarative**: they only render JSX based on hook outputs
3. Combine with **state, refs, context, memoization, and events**
4. Enables **clean, maintainable, and scalable React applications**
5. Integrates seamlessly with **lists, conditional rendering, and Virtual DOM diffing**

---

This section now **completes the core React tutorial flow**, linking **props → state → events → conditional rendering → lists/keys → lifecycle → refs → context → memoization → custom hooks** into a **cohesive, diagram-friendly mental model**.

---

# 🧠 Section 14 — Full Example App: Todo Dashboard

This app ties together **all the core React concepts** you’ve learned so far:

* **Pure functional components** → render JSX based on props, state, and context
* **State-driven rendering** → UI updates automatically when state changes
* **Hook-based lifecycle control** → `useEffect`, `useRef`, `useMemo`, `useCallback`, and **custom hooks**
* **Lists, keys, conditional rendering, and events** → handled declaratively
* **Virtual DOM optimization** → minimal real DOM updates

---

## 🔹 Mental Model: Todo Dashboard Data Flow

```
<App state={todos} count={count}>
       │
       ├─ <Navbar title="React Todo Dashboard" />  → props → Virtual DOM → DOM update
       │
       ├─ <TodoList items={todos} />              → props + keys → Virtual DOM → minimal DOM updates
       │       └─ <li key={todo.id}>{todo.text}</li>
       │
       └─ <Counter state={count} />               → useState → event handler → state update → Virtual DOM diff → DOM update
```

* **State changes** trigger **re-render of affected components**
* **Hooks** manage lifecycle, side effects, and memoization
* **Refs** (if used) persist values without extra renders
* **Context** (if added) avoids prop drilling and shares global state

---

## 🔹 How This App Demonstrates Key Concepts

| Feature                         | Concept Illustrated                                               |
| ------------------------------- | ----------------------------------------------------------------- |
| `App.js` state (`todos`)        | Source of truth for child components (Section 5 — `useState`)     |
| `<Navbar>` component            | Props as pure function inputs (Section 4 — Components & Props)    |
| `<TodoList>` + `key={todo.id}`  | Lists & keys for efficient Virtual DOM diffing (Section 8)        |
| `<Counter>` + button events     | Event handling triggers state updates (Section 6)                 |
| `useEffect` inside custom hooks | Lifecycle & side-effect management (Section 9 & 13)               |
| `useRef` (if integrated)        | Persistent values that do not trigger re-renders (Section 10)     |
| `useMemo` / `useCallback`       | Optimized calculations & stable function references (Section 12)  |
| Declarative JSX                 | Pure rendering → same input → same output (all sections combined) |

---

## 🔹 Component Breakdown

### **App.js**

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

* Demonstrates **state-driven UI**
* `todos` is the **source of truth** for child components

---

### **Navbar.js**

```jsx
function Navbar({ title }) {
  return <h1>{title}</h1>;
}

export default Navbar;
```

* **Pure functional component**
* **Props** control rendered output
* Renders only if props change

---

### **TodoList.js**

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

* **Lists + keys** → efficient Virtual DOM diffing
* Stateless → pure render based on props

---

### **Counter.js**

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

export default Counter;
```

* **useState** → controlled impurity
* **Event handler** triggers **Virtual DOM diff → DOM update**
* Render function remains **pure**

---

### **index.js**

```jsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<App />);
```

* Bootstraps **React application**
* Initial render → **Virtual DOM → DOM**

---

## 🔹 Flow Diagram: Full Todo Dashboard Lifecycle

```
Initial Mount:
  App renders → Navbar, TodoList, Counter render
  useState initialized → Virtual DOM snapshot → DOM updates
  useEffect runs → side effects executed

User Interaction:
  Button click → setCount → Counter re-render
  State change → Virtual DOM diff → minimal DOM update
  useEffect (if any) → runs side effects

Todo Update:
  Modify todos → TodoList re-renders
  Keys → efficient Virtual DOM diff → DOM update
```

* Combines **state, props, events, lifecycle, Virtual DOM, lists/keys**
* Demonstrates **pure component design**

---

## ✅ Key Takeaways

1. Components are **pure functions of props, state, and context**
2. **State drives rendering**, not manual DOM manipulation
3. **Events** trigger **controlled state updates** → Virtual DOM → minimal real DOM update
4. **Hooks** (`useState`, `useEffect`, `useRef`, `useMemo`, `useCallback`) manage **state, side-effects, memoization, and lifecycle**
5. **Keys** in lists allow **efficient diffing** and minimal updates
6. Full app demonstrates **scalable, maintainable, declarative React architecture**

---

# 🧠 Section 15 — Mental Models: Props, State, Hooks & Virtual DOM

At the heart of React:

```
UI = f(props, state)
```

> The UI is a **pure function** of **props** (external inputs) and **state** (internal memory).
> Everything else — events, hooks, context, refs, conditional rendering, lists, memoization — exists to **support this invariant** efficiently and predictably.

---

## 🔹 Core Principles

| Concept               | Mental Model                                                                              |
| --------------------- | ----------------------------------------------------------------------------------------- |
| Props                 | Immutable inputs → pure render outputs (Section 4)                                        |
| State                 | Controlled impurity → triggers re-render (Section 5)                                      |
| Events                | Trigger state updates, never direct DOM mutations (Section 6)                             |
| Conditional Rendering | Pure function returns different JSX per state/props (Section 7)                           |
| Lists & Keys          | Pure render outputs identified via keys → efficient Virtual DOM diff (Section 8)          |
| useEffect / Lifecycle | Side effects isolated from pure render → predictable updates (Section 9)                  |
| useRef                | Persistent mutable values without breaking purity (Section 10)                            |
| useContext            | Implicit inputs for pure functions → avoids prop drilling (Section 11)                    |
| useMemo / useCallback | Referential stability → avoids unnecessary recomputation/re-renders (Section 12)          |
| Custom Hooks          | Encapsulate reusable logic & side effects → components remain clean and pure (Section 13) |

---

## 🔹 Visual Data Flow

```
          ┌───────────┐
          │ User Event│
          └─────┬─────┘
                ↓
          ┌───────────┐
          │  State/Props │
          └─────┬─────┘
                ↓
      ┌────────────────────┐
      │ Component Function │  ← Pure function: JSX = f(props, state)
      └─────────┬─────────┘
                ↓
        ┌───────────────┐
        │ Virtual DOM   │
        └─────┬─────────┘
                ↓
       ┌────────────────┐
       │ Diffing Engine │  ← Calculates minimal real DOM updates
       └─────┬─────────┘
                ↓
           ┌───────────┐
           │  Real DOM │
           └───────────┘
                ↓
           User sees UI
```

---

## 🔹 Lifecycle of a React Update

1. **Event triggers** → state/props change
2. **Component re-executes** → pure function computes new JSX
3. **Virtual DOM diff** → determines minimal updates
4. **Real DOM updates** → browser renders changes
5. **Side effects run** via `useEffect`
6. **Refs persist values**, context provides implicit inputs, memoization ensures stable computations

---

## 🔹 Prop Drilling vs Context Decision Guide

| Scenario                        | Recommended Approach                                             |
| ------------------------------- | ---------------------------------------------------------------- |
| Few levels of nested components | Pass props directly (Section 4)                                  |
| Deeply nested or global state   | Use `useContext` to avoid prop drilling (Section 11)             |
| Performance-sensitive values    | Combine `useContext` with `useMemo` / `useCallback` (Section 12) |

---

## 🔹 Pure Functions as the Mental Core

* **Every render function** should behave like a **pure function**:

```
same input (props + state) → same output (JSX)
```

* **Controlled impurity** occurs **only in hooks**: `useState`, `useRef`, `useEffect`
* **All UI updates** flow through **Virtual DOM diffing** → predictable, optimized DOM updates

---

## 🔹 Full App Integration (Todo Dashboard)

```
<App state={todos}>
   ├─ <Navbar title="React Todo Dashboard"/> → props → pure render
   ├─ <TodoList items={todos}/> → list + keys → efficient Virtual DOM diff
   └─ <Counter state={count}/> → useState → events → Virtual DOM diff → DOM update
```

* Hooks (`useEffect`, `useRef`, `useMemo`, `useCallback`) manage side-effects, persistent values, and optimization
* Custom hooks encapsulate reusable logic (Section 13)
* Context avoids prop drilling for global or deeply nested values

---

## ✅ Key Takeaways

1. **React components = pure functions**: `UI = f(props, state)`
2. **State drives UI updates** → controlled, predictable rendering
3. **Hooks** provide controlled impurity for side effects, persistence, and optimization
4. **Virtual DOM** ensures efficient real DOM updates
5. **Context, refs, memoization, lists/keys, conditional rendering, and custom hooks** support scalability and maintainability
6. Mastering these **mental models** allows building **large, complex React apps** confidently

---

# 🧾 Addendum A — Full Project Code 

## **Project Structure**

```
react_todo_dashboard/
├── public/
│   └── index.html
├── src/
│   ├── App.js
│   ├── Navbar.js
│   ├── TodoList.js
│   ├── Counter.js
│   ├── index.js
│   └── hooks/
│       └── useFetch.js      # Optional: custom hooks folder
├── package.json
└── README.md
```

---

## **public/index.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>React Todo Dashboard</title>
</head>
<body>
  <div id="root"></div>
</body>
</html>
```

* **Root div** is the entry point for React
* No direct DOM manipulation required in components

---

## **src/index.js**

```jsx
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App";

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(<App />);
```

* Initializes the **React app**
* Renders `<App />` into **Virtual DOM → Real DOM**

---

## **src/App.js**

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

* **State-driven rendering**: `todos` is source of truth
* Pure functional components return JSX → Virtual DOM → minimal real DOM updates

---

## **src/Navbar.js**

```jsx
function Navbar({ title }) {
  return <h1>{title}</h1>;
}

export default Navbar;
```

* Props are **immutable inputs** → pure render function
* Rerenders only when `title` prop changes

---

## **src/TodoList.js**

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

* **Keys** allow efficient **Virtual DOM diffing**
* Stateless → pure rendering
* Integrates cleanly with **state-driven updates from App.js**

---

## **src/Counter.js**

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

export default Counter;
```

* **Event triggers state update** → triggers Virtual DOM diff → minimal DOM update
* Component function remains **pure**
* Demonstrates **controlled impurity** via `useState`

---

## **src/hooks/useFetch.js** (Optional Custom Hook)

```jsx
import { useState, useEffect } from "react";

export function useFetch(url) {
  const [data, setData] = useState(null);

  useEffect(() => {
    fetch(url)
      .then(res => res.json())
      .then(setData);
  }, [url]);

  return data;
}
```

* Encapsulates **side-effect logic**
* Components remain clean and pure
* Supports **reusability across multiple components**

---

## **package.json**

```json
{
  "name": "react_todo_dashboard",
  "version": "1.0.0",
  "private": true,
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-scripts": "5.0.1"
  },
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test",
    "eject": "react-scripts eject"
  }
}
```

---

# 🧾 Addendum B — Visual Cheat Sheet + Virtual DOM Flow

### Props, State, Events, Lifecycle & Virtual DOM

```
Props = immutable input → pure render
State = internal memory → triggers Virtual DOM diff → DOM update
Events = triggers state updates
useEffect = side effects & lifecycle
useRef = persistent ref (no re-render)
useMemo = memoized value
useCallback = memoized function
```

---

### Component Tree + Virtual DOM Flow

```
<App state={todos}>
   ├─ <Navbar title="React Todo Dashboard"/> → VDOM
   ├─ <TodoList items={todos}/> → VDOM → diff → DOM update
   │    ├─ <li>Learn JSX</li>
   │    ├─ <li>Understand Props</li>
   │    └─ <li>Manage State</li>
   └─ <Counter state={count}/> → VDOM → diff → DOM update
```

* **All updates flow through Virtual DOM diffing** → efficient DOM manipulation
* **Pure components + controlled state** → predictable rendering

---

### Virtual DOM & Lifecycle Flow Diagram

```
Initial Mount
   ├─ useState -> initialize state
   ├─ useEffect [] -> run side effects
   └─ Component renders → Virtual DOM → minimal DOM update

State Update
   ├─ setState -> triggers re-render
   ├─ useMemo/useCallback -> optimize computation & function identity
   └─ Virtual DOM diff → minimal DOM update

Unmount
   └─ useEffect cleanup → DOM cleaned
```

* Visualizes **how state, hooks, and Virtual DOM interact**
* Ensures **predictable, efficient updates**

---

# 🧾 Addendum C — Hooks, Context, Memoization & Custom Hooks Flow

### Full Mental Model Integration

```
User Interaction
        ↓
State / Props change
        ↓
Component function executes (pure)
        ├─ useState -> local state
        ├─ useEffect -> side effects
        ├─ useRef -> persistent values
        ├─ useMemo -> memoized values
        ├─ useCallback -> stable function identity
        └─ useContext -> implicit inputs
        ↓
JSX returned → Virtual DOM
        ↓
Diffing Algorithm → Minimal DOM Update
        ↓
User sees UI
```

### Key Concepts

1. **Pure Components:** JSX = f(props, state)
2. **Controlled Impurity:** state, refs, effects
3. **Virtual DOM:** Efficiently reconciles changes
4. **Custom Hooks:** Encapsulate reusable logic
5. **Memoization:** Optimizes heavy computations and stable functions
6. **Context:** Avoids prop drilling for deeply nested or global state

---

✅ **Summary**

* The tutorial + addendums now form a **complete, professional-grade React reference**.
* Covers **everything from core mental models to full app implementation**.
* Fully **diagram-friendly**, highlighting **pure functions, state, events, hooks, context, refs, memoization, lists/keys, conditional rendering, Virtual DOM, and custom hooks**.

---

# 🧾 Addendum D — Ultimate React Flow & Prop Flow Reference

### **Purpose:**

One complete, visual reference showing **React concepts end-to-end**: props, state, events, hooks, context, refs, memoization, Virtual DOM, conditional rendering, lists/keys, custom hooks — **plus a clear prop flow / prop drilling guide** and **render vs side effect mental model**.

---

## **1️⃣ User Interaction → State / Props**

```
🖱️ User Interaction
        ↓
📦 State / Props
```

**Explanation:**

* **Props** = immutable inputs from parent → pure function render
* **State** = internal component data → triggers re-render
* Both are the **source of truth** for the UI

---

## **2️⃣ Component Function (Pure)**

```
⚛️ Component Function (Pure)
```

**Explanation:**

* Components = **pure functions**: same props + state → same JSX output
* No side effects inside render → predictable, testable, easy to reason about

**Example — Pure Component:**

```jsx
function Greeting({ name }) {
  return <h1>Hello, {name}</h1>; // output depends only on props
}
```

**Mental Model:**

```
Input: props + state
     ↓
Render function (pure)
     ↓
Output: JSX
```

---

## **3️⃣ Controlled Impurity via Hooks**

```
🪝 Hooks Execute
   ├─ useState      → manage internal data
   ├─ useEffect     → side effects (API calls, timers)
   ├─ useRef        → store mutable values without re-render
   ├─ useMemo       → memoize expensive calculations
   ├─ useCallback   → memoize function references
   └─ useContext    → access global / nested data (avoids prop drilling)
```

**Explanation:**

* Hooks handle **controlled side effects**
* Render remains pure; side effects are isolated in hooks
* Makes components **predictable and testable**

---

## **4️⃣ JSX → Virtual DOM**

```
📄 JSX → Virtual DOM
```

* Component returns JSX → React builds **Virtual DOM**
* Virtual DOM = fast, in-memory representation
* **No real DOM updates yet**

---

## **5️⃣ Diffing Algorithm → Minimal DOM Updates**

```
🔍 Diffing Algorithm
        ↓
🖥️ Real DOM
```

* React compares previous and new Virtual DOM
* Computes **minimal DOM changes** → efficient re-rendering

---

## **6️⃣ Browser Re-render → UI Update**

```
🖥️ Real DOM
        ↓
👀 User Sees UI
```

* Browser redraws only what changed
* Developers **never manipulate the DOM directly**

---

## **7️⃣ Prop Flow Diagram — Prop Drilling vs Context**

**Prop Drilling:**

```
Parent Component
     props: theme="dark"
          ↓
 Child Component 1
     props: theme="dark"
          ↓
 Child Component 2
     props: theme="dark"
          ↓
 Child Component 3
```

* Passing props through many intermediate layers = **prop drilling**

**Solution: Context**

```
Parent Component
     ⬇
  ThemeContext.Provider value="dark"
          ↓
 Child Component 3 (directly accesses context)
```

* `useContext` allows **deeply nested components** to access data **without drilling**
* Keeps components **clean, reusable, and pure**

---

## **8️⃣ Special Features / Notes**

| Feature               | Explanation                                                                         |
| --------------------- | ----------------------------------------------------------------------------------- |
| Conditional Rendering | `{state ? <A /> : <B />}` → render UI depending on state                            |
| Lists & Keys          | `<li key={id}>…</li>` → helps React track dynamic lists efficiently                 |
| Custom Hooks          | Encapsulate reusable logic outside component function                               |
| Memoization           | `useMemo` and `useCallback` → avoid unnecessary recalculation / function recreation |

---

## **9️⃣ Pure Render vs Side Effects Visual**

```
Props + State
      ↓
Render Function (Pure)
      ↓
JSX → Virtual DOM → Diff → Real DOM
```

```
useEffect / Hooks
      ↘ Side effects (API calls, timers, subscriptions)
      ↘ Cleanup (on unmount or dependency change)
```

**Key Idea:**

* **Render function = pure** → predictable UI
* **Hooks = controlled impurity** → safe side effects

---

## **🔟 Full Quick Reference Flow (Emoji + ASCII)**

```
🖱️ User Interaction
        ↓
📦 State / Props (source of truth)
        ↓
⚛️ Component Function (pure)
        ↓
🪝 Hooks Execute (controlled side effects)
        ↓
📄 JSX → Virtual DOM
        ↓
🔍 Diffing Algorithm → Minimal DOM Updates
        ↓
🖥️ Real DOM
        ↓
👀 User Sees UI
```

---

## ✅ **Key Takeaways**

1. **UI = f(props, state)** — central mental model
2. **Pure function components** → predictable & testable
3. **Hooks** = controlled impurity (state, effects, refs, memoization, context)
4. **Virtual DOM + diffing** → minimal, efficient DOM updates
5. **Prop drilling vs context**: avoid deep manual prop passing
6. **Render vs side effects:**

   * Render = pure → returns JSX only
   * Side effects = in hooks (`useEffect`, `useRef`)
7. **Everything flows predictably**:

   ```
   User Interaction → State/Props → JSX → Virtual DOM → Diff → DOM → UI
   ```

---

