# ⚛️ **Key React Concepts**

React is more than just a UI library—understanding **state management, component lifecycles, and hooks** is essential for building professional apps.

---

## 1. Components: Functional vs Class

React apps are built from **components**.

**Functional Components** are modern, concise, and often preferred:

```jsx
function Greeting({ name }) {
  return <h1>Hello, {name}!</h1>;
}
```

**Class Components** support **lifecycle methods**:

```jsx
import React, { Component } from "react";

class Counter extends Component {
  constructor(props) {
    super(props);
    this.state = { count: 0 };
  }

  increment = () => {
    this.setState({ count: this.state.count + 1 });
  }

  render() {
    return (
      <div>
        <p>Count: {this.state.count}</p>
        <button onClick={this.increment}>Increment</button>
      </div>
    );
  }
}
```

---

## 2. JSX & Props

JSX is **JavaScript + XML-like syntax**. Props are **inputs to components**:

```jsx
function Button({ label, onClick }) {
  return <button onClick={onClick}>{label}</button>;
}

// Usage
<Button label="Submit" onClick={() => console.log("Clicked")} />
```

---

## 3. State & useState Hook

State stores **mutable values** in functional components:

```jsx
import React, { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0); // [value, setter]

  return (
    <div>
      <p>{count}</p>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}
```

---

## 4. Side Effects & useEffect

`useEffect` replaces **class lifecycle methods**:

* `componentDidMount` → `useEffect(..., [])`
* `componentDidUpdate` → `useEffect(..., [deps])`
* `componentWillUnmount` → cleanup function

```jsx
import React, { useState, useEffect } from "react";

function Timer() {
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => setSeconds(s => s + 1), 1000);
    return () => clearInterval(interval); // cleanup
  }, []);

  return <p>Timer: {seconds}s</p>;
}
```

---

## 5. Context API

Context allows **global state** without prop drilling:

```jsx
import React, { createContext, useContext, useState } from "react";

const ThemeContext = createContext("light");

function ThemeSwitcher() {
  const { theme, toggleTheme } = useContext(ThemeContext);
  return <button onClick={toggleTheme}>Current: {theme}</button>;
}

function App() {
  const [theme, setTheme] = useState("light");
  const toggleTheme = () => setTheme(t => (t === "light" ? "dark" : "light"));

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme }}>
      <ThemeSwitcher />
    </ThemeContext.Provider>
  );
}
```

---

## 6. useMemo & useCallback (Performance)

* `useMemo` → memoize **expensive calculations**
* `useCallback` → memoize **functions** to prevent unnecessary re-renders

```jsx
import React, { useState, useMemo, useCallback } from "react";

function Expensive({ num }) {
  const result = useMemo(() => {
    console.log("Calculating...");
    return num ** 2;
  }, [num]);
  return <p>Result: {result}</p>;
}

function Parent() {
  const [count, setCount] = useState(0);
  const memoizedFn = useCallback(() => console.log(count), [count]);
  return <Expensive num={count} />;
}
```

---

## 7. Conditional Rendering & Lists

```jsx
function TodoList({ todos }) {
  return (
    <ul>
      {todos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
      {todos.length === 0 && <p>No todos!</p>}
    </ul>
  );
}
```

---

## 8. Lazy Loading & Suspense

Split code and **load components only when needed**:

```jsx
import React, { lazy, Suspense } from "react";

const HeavyComponent = lazy(() => import("./HeavyComponent"));

function App() {
  return (
    <Suspense fallback={<p>Loading...</p>}>
      <HeavyComponent />
    </Suspense>
  );
}
```

---

## 9. Custom Hooks

Encapsulate reusable logic:

```jsx
import { useState, useEffect } from "react";

function useWindowWidth() {
  const [width, setWidth] = useState(window.innerWidth);

  useEffect(() => {
    const handleResize = () => setWidth(window.innerWidth);
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  return width;
}

// Usage
function App() {
  const width = useWindowWidth();
  return <p>Window width: {width}px</p>;
}
```

---

## 10. Real-World Example: Bank System in React

```jsx
import React, { useState } from "react";

function BankAccount({ owner, initialBalance }) {
  const [balance, setBalance] = useState(initialBalance || 0);
  const [transactions, setTransactions] = useState([]);

  const deposit = amount => {
    setBalance(b => b + amount);
    setTransactions(t => [...t, { type: "deposit", amount }]);
  };

  const withdraw = amount => {
    if (amount > balance) return alert("Insufficient funds");
    setBalance(b => b - amount);
    setTransactions(t => [...t, { type: "withdraw", amount }]);
  };

  return (
    <div>
      <h3>{owner}'s Account</h3>
      <p>Balance: ${balance}</p>
      <button onClick={() => deposit(100)}>Deposit $100</button>
      <button onClick={() => withdraw(50)}>Withdraw $50</button>
      <ul>
        {transactions.map((t, i) => (
          <li key={i}>{t.type}: ${t.amount}</li>
        ))}
      </ul>
    </div>
  );
}

export default function App() {
  return <BankAccount owner="Alice" initialBalance={1000} />;
}
```

---

## ✅ Key React Concepts Cheat Sheet

| Concept               | Example / Hook                            | Use Case                           |
| --------------------- | ----------------------------------------- | ---------------------------------- |
| Functional Components | `function Greeting()`                     | Preferred modern components        |
| Class Components      | `class Counter extends Component`         | Lifecycle support                  |
| JSX & Props           | `<Button label="Click" />`                | Component inputs                   |
| State                 | `useState`                                | Mutable local data                 |
| Effects               | `useEffect`                               | Side effects / lifecycle           |
| Context API           | `createContext` / `useContext`            | Global state without prop drilling |
| Performance           | `useMemo` / `useCallback`                 | Prevent unnecessary re-renders     |
| Conditional Rendering | `{todos.length === 0 && <p>No todos</p>}` | UI logic                           |
| Lazy Loading          | `React.lazy` / `Suspense`                 | Code splitting                     |
| Custom Hooks          | `useWindowWidth`                          | Reusable logic across components   |
| Lists                 | `.map()`                                  | Render collections efficiently     |

