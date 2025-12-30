# ⚛️ React Architecture & Design Patterns Tutorial

---

## **1. Introduction to React Architecture**

React is a **JavaScript library for building user interfaces**. Its core philosophy is **component-based architecture**, breaking the UI into **reusable, composable components**.

**Key Concepts:**

* **Components:** Reusable building blocks of UI.
* **State:** Internal data for components.
* **Props:** Data passed to child components.
* **Virtual DOM:** Efficiently updates the real DOM.
* **Hooks:** Manage state, lifecycle, and side effects in functional components.

**React Architecture Overview:**

```
+----------------------+
|      App Root        |
+----------------------+
           |
   +-------+-------+
   |               |
+--------+     +--------+
| Header |     | Footer |
+--------+     +--------+
   |
+---------+
| Content |
+---------+
   |
+---------+
| Widgets |
+---------+
```

**Flow of Data:**

```
State / Props
     |
     v
React Components
     |
     v
Virtual DOM Diffing
     |
     v
Actual DOM Update
```

---

## **2. React Project Structure (Recommended)**

```
my-app/
├── public/
│   └── index.html
├── src/
│   ├── components/
│   │   ├── Header.js
│   │   ├── Footer.js
│   │   └── Widget.js
│   ├── hooks/
│   │   └── useCustomHook.js
│   ├── context/
│   │   └── AppContext.js
│   ├── services/
│   │   └── apiService.js
│   ├── App.js
│   ├── index.js
│   └── styles/
│       └── main.css
└── package.json
```

**Layered View of React Architecture:**

```
+---------------------+
| Presentation Layer  | <- Components, JSX, CSS
+---------------------+
| State Management    | <- useState, useReducer, Redux, Context
+---------------------+
| Service Layer       | <- API calls, business logic, adapters
+---------------------+
| Utilities / Helpers | <- Pure functions, formatting
+---------------------+
| Data Layer          | <- Fetching from APIs, localStorage, IndexedDB
+---------------------+
```

---

## **3. Components & Patterns**

### **3.1 Functional Components (Hooks)**

```jsx
import React, { useState, useEffect } from 'react';

function Counter() {
  const [count, setCount] = useState(0);

  useEffect(() => {
    console.log('Count updated:', count);
  }, [count]);

  return (
    <div>
      <h1>{count}</h1>
      <button onClick={() => setCount(count + 1)}>Increment</button>
    </div>
  );
}
```

**Pros:** Lightweight, readable, easy to test.
**Cons:** Hooks replace legacy class lifecycle methods; otherwise no major drawbacks.

---

### **3.2 Class Components**

```jsx
import React, { Component } from 'react';

class Counter extends Component {
  state = { count: 0 };

  increment = () => this.setState({ count: this.state.count + 1 });

  render() {
    return (
      <div>
        <h1>{this.state.count}</h1>
        <button onClick={this.increment}>Increment</button>
      </div>
    );
  }
}
```

**Pros:** Explicit lifecycle methods.
**Cons:** More boilerplate; functional components with hooks are generally preferred.

---

### **3.3 Higher-Order Components (HOC)**

HOCs are functions that **wrap components to add extra behavior**.

```jsx
function withLogger(Component) {
  return function WrappedComponent(props) {
    console.log('Rendering:', Component.name);
    return <Component {...props} />;
  };
}

const LoggedCounter = withLogger(Counter);
```

**Use Cases:** Logging, authentication, permission handling.

---

### **3.4 Render Props Pattern**

```jsx
function MouseTracker({ render }) {
  const [x, setX] = useState(0);
  const [y, setY] = useState(0);

  const handleMouseMove = e => {
    setX(e.clientX);
    setY(e.clientY);
  };

  return <div onMouseMove={handleMouseMove}>{render({ x, y })}</div>;
}

function App() {
  return (
    <MouseTracker render={({ x, y }) => <h1>Mouse at ({x}, {y})</h1>} />
  );
}
```

**Use Cases:** Share dynamic behavior between components.

---

### **3.5 Context API**

```jsx
import React, { createContext, useContext } from 'react';

const ThemeContext = createContext('light');

function ThemedButton() {
  const theme = useContext(ThemeContext);
  return <button className={theme}>Click me</button>;
}

function App() {
  return (
    <ThemeContext.Provider value="dark">
      <ThemedButton />
    </ThemeContext.Provider>
  );
}
```

**Pros:** Avoids prop drilling; centralizes global state.

---

## **4. State Management Patterns**

1. **Local State:** `useState` for component-specific data.
2. **Reducer Pattern:** `useReducer` for complex state logic.
3. **Context + Reducer:** Global state management without Redux.
4. **Redux / Zustand / Jotai:** External libraries for large-scale apps.

---

## **5. DRY & Reusable Patterns**

| Pattern              | Usage in React                                     |
| -------------------- | -------------------------------------------------- |
| HOC                  | Extend component functionality                     |
| Render Props         | Share behavior dynamically                         |
| Compound Components  | Parent provides logic, children define UI          |
| Custom Hooks         | Reusable stateful logic                            |
| Context API          | Global state sharing                               |
| Adapter / Facade     | Wrap API calls for consistency                     |
| Observer / Event Bus | Decouple components for event-driven communication |

---

## **6. Component Lifecycle Patterns**

### **6.1 Functional Components (Hooks)**

| Hook        | Purpose                                       |
| ----------- | --------------------------------------------- |
| useState    | Local state                                   |
| useEffect   | Side-effects (mount, update, unmount)         |
| useMemo     | Memoize expensive calculations                |
| useCallback | Memoize functions to avoid re-renders         |
| useRef      | Access DOM elements or persist mutable values |

### **6.2 Class Components**

| Method               | Purpose                       |
| -------------------- | ----------------------------- |
| componentDidMount    | Runs after initial render     |
| componentDidUpdate   | Runs after state/prop updates |
| componentWillUnmount | Runs before component removal |

---

## **7. React Architecture Diagram**

```
User Interaction / Event
         |
         v
+--------------------+
| Component Tree     | <- Functional / Class Components
+--------------------+
         |
         v
+--------------------+
| State Management   | <- useState, useReducer, Context, Redux
+--------------------+
         |
         v
+--------------------+
| Service Layer      | <- API calls, business logic, data fetching
+--------------------+
         |
         v
+--------------------+
| Utilities / Helpers | <- Pure functions, formatting
+--------------------+
         |
         v
+--------------------+
| API / Data Layer    | <- REST/GraphQL/IndexedDB/LocalStorage
+--------------------+
         |
         v
User Interface Update (Virtual DOM → Real DOM)
```

---

## **8. Best Practices & Patterns Summary**

1. **Component Hierarchy:** Keep components small, reusable, and single-responsibility.
2. **State Management:** Use local state for small components; Context or Redux for global state.
3. **Hooks & Custom Hooks:** Encapsulate reusable logic.
4. **HOCs & Render Props:** Share behavior across components.
5. **Context API:** Avoid prop drilling for global state.
6. **Service Layer:** Keep API calls separate from components.
7. **Observer Pattern:** Event bus or pub/sub for decoupled communication.
8. **Adapter / Facade:** Wrap API endpoints to standardize responses.
9. **Memoization:** Use `React.memo`, `useMemo`, and `useCallback` to optimize rendering.
10. **Testing:** Unit-test components, hooks, and services for maintainability.

---

## **9. React Design Patterns Quick Reference**

| Pattern              | Example / Usage                                |
| -------------------- | ---------------------------------------------- |
| HOC                  | `withLogger(Component)`                        |
| Render Props         | `<MouseTracker render={...} />`                |
| Custom Hook          | `useFetch(url)`                                |
| Context API          | `ThemeContext.Provider`                        |
| Adapter / Facade     | `apiService.js` wraps REST calls               |
| Observer / Event Bus | EventEmitter for cross-component communication |
| Compound Component   | Tabs, Accordions                               |
| Memoization          | `React.memo`, `useMemo`, `useCallback`         |

---

## **10. React Architecture & Design Patterns Mind Map**

```
                         +------------------------+
                         |      User / Client     |
                         +------------------------+
                                    |
        +---------------------------+---------------------------+
        |                           |                           |
+----------------+           +----------------+          +------------------+
| Functional /   |           | Class Components|          | Hooks / Context |
| Class Components|           +----------------+          +------------------+
+----------------+                    |                          |
| - JSX / UI     |                    |                          |
| - Props        |                    |                          |
| - State        |                    |                          |
+----------------+                    +--------------------------+
        |                                      |
        |                             +-------------------+
        |                             | Mixins / HOC / RP |
        |                             +-------------------+
        |                             | Higher-Order Components
        |                             | Render Props
        |                             | Compound Components
        |                             +-------------------+
        |                                      |
        |                                      |
        +--------------------------------------+
                       |
                +----------------+
                | State Management|
                +----------------+
                | Local State    |
                | useReducer     |
                | Context / Redux|
                +----------------+
                       |
                +----------------+
                | Service Layer  |
                +----------------+
                | API calls      |
                | Business logic |
                | Adapter / Facade|
                +----------------+
                       |
                +----------------+
                | Utilities /    |
                | Helpers        |
                +----------------+
                       |
                +----------------+
                | Data Layer     |
                +----------------+
                | REST / GraphQL |
                | LocalStorage   |
                | IndexedDB      |
                +----------------+
                       |
                +----------------+
                | Virtual DOM →  |
                | Actual DOM     |
                +----------------+
                       |
                User Interface Update
```

---
