# 🚀 FULL TUTORIAL: Production-Style React Todo App

Build a **real-world scalable Todo App** with:

- useReducer (state management)
- useContext (global state)
- Multi-file architecture
- Editing todos ✏️
- Tags, Due Dates, Priority
- Search + Filter
- Charts (productivity insights 📊)
- Persistence (localStorage)

---

# 🧱 STEP 1 — Create Project

```bash
npx create-react-app todo-pro
cd todo-pro
npm start
```

---

# 🧱 STEP 2a — Folder Structure (IMPORTANT)

Create this structure inside `/src`:

```
src/
 ├── context/
 │    ├── TodoContext.js
 │    └── todoReducer.js
 ├── components/
 │    ├── TodoInput.js
 │    ├── TodoList.js
 │    ├── TodoItem.js
 │    ├── SearchBar.js
 │    ├── FilterBar.js
 │    ├── Stats.js
 │    └── Chart.js
 ├── App.js
```

---
# 🧱 STEP 2b — CSS 

Create styles.css inside `/src`:
```css
/* =========================================================
   🎨 DESIGN TOKENS
========================================================= */
:root {
  --primary: #4f46e5;
  --bg: #f8fafc;
  --card: #ffffff;

  --text-main: #1e293b;
  --text-muted: #64748b;

  --border: #e2e8f0;

  --shadow-sm: 0 4px 6px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 10px 15px rgba(0, 0, 0, 0.1);

  --radius-sm: 6px;
  --radius-md: 8px;
  --radius-lg: 12px;

  --transition: all 0.2s ease-in-out;
}

/* =========================================================
   🌍 GLOBAL STYLES
========================================================= */
*,
*::before,
*::after {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: "Inter", -apple-system, BlinkMacSystemFont, sans-serif;
  background: var(--bg);
  color: var(--text-main);
  line-height: 1.6;
}

/* =========================================================
   📦 APP LAYOUT
========================================================= */
.app-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px;
  min-height: 100vh;
}

h1 {
  font-size: 2rem;
  font-weight: 800;
  margin-bottom: 24px;
  color: var(--primary);
  letter-spacing: -0.025em;
}

/* =========================================================
   📋 TODO LIST
========================================================= */
ul {
  padding: 0;
  width: 100%;
  max-width: 550px;
}

/* =========================================================
   📝 TODO ITEM CARD
========================================================= */
.todo-item {
  list-style: none;
  padding: 18px;
  margin-bottom: 16px;
  background: var(--card);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
  transition: var(--transition);
}

.todo-item:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

/* Overdue Highlight */
.todo-item.overdue {
  border-left: 5px solid #ef4444;
  background: #fff5f5;
}

/* =========================================================
   📌 TASK HEADER
========================================================= */
.task-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.task-text {
  font-size: 1.125rem;
  font-weight: 600;
  cursor: pointer;
  color: var(--text-main);
  transition: var(--transition);
}

.task-text.completed {
  text-decoration: line-through;
  color: var(--text-muted);
  opacity: 0.6;
}

/* =========================================================
   🔘 ACTION BUTTONS
========================================================= */
.actions {
  display: flex;
  gap: 8px;
}

.actions button {
  padding: 6px 12px;
  border-radius: var(--radius-sm);
  border: none;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  transition: var(--transition);
}

/* Button Variants */
.edit {
  background: #eff6ff;
  color: #2563eb;
}

.edit:hover {
  background: #dbeafe;
}

.delete {
  background: #fff1f2;
  color: #e11d48;
}

.delete:hover {
  background: #ffe4e6;
}

.save {
  background: #22c55e;
  color: white;
}

.cancel {
  background: #94a3b8;
  color: white;
}

/* =========================================================
   📑 TASK DETAILS
========================================================= */
.task-details {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px dashed var(--border);
}

.meta {
  font-size: 0.8rem;
  color: var(--text-muted);
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
}

/* =========================================================
   ⚡ PRIORITY BADGES
========================================================= */
.priority-high {
  color: #be123c;
  background: #fff1f2;
  padding: 2px 8px;
  border-radius: 4px;
}

.priority-medium {
  color: #b45309;
  background: #fef3c7;
  padding: 2px 8px;
  border-radius: 4px;
}

.priority-low {
  color: #047857;
  background: #ecfdf5;
  padding: 2px 8px;
  border-radius: 4px;
}

/* =========================================================
   🏷️ TAGS
========================================================= */
.tags-container {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.tag {
  background: #f1f5f9;
  color: #475569;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.7rem;
  font-weight: 500;
}

/* =========================================================
   ✏️ EDIT MODE
========================================================= */
.edit-mode {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.edit-mode input {
  padding: 10px;
  border: 2px solid var(--primary);
  border-radius: var(--radius-md);
  font-size: 1rem;
  outline: none;
}

/* =========================================================
   🔍 FILTER BAR
========================================================= */
.filter-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin: 20px 0;
}

.filter-bar button {
  padding: 8px 14px;
  border: 1px solid var(--border);
  background: white;
  border-radius: var(--radius-md);
  cursor: pointer;
  font-weight: 600;
  transition: var(--transition);
}

.filter-bar button:hover {
  background: #eef2ff;
}

.filter-bar button.active {
  background: var(--primary);
  color: white;
  border-color: var(--primary);
}

/* =========================================================
   📊 ANALYTICS SECTION (CHART + STATS)
========================================================= */
.analytics-container {
  display: flex;
  justify-content: center;
  align-items: stretch;
  gap: 20px;
  margin-top: 30px;
  width: 100%;
  max-width: 900px;
  flex-wrap: wrap;
}

.chart,
.stats {
  background: var(--card);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
}

/* Chart */
.chart {
  flex: 2;
  padding: 16px;
}

/* Stats */
.stats {
  flex: 1;
  min-width: 200px;
  padding: 20px;
}

.stats p {
  margin: 10px 0;
  font-size: 1rem;
  font-weight: 600;
}

/* =========================================================
   📱 RESPONSIVE DESIGN
========================================================= */
@media (max-width: 768px) {
  .analytics-container {
    flex-direction: column;
    align-items: center;
  }

  .chart,
  .stats {
    width: 100%;
  }

  .task-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .actions {
    width: 100%;
    justify-content: flex-end;
  }
}
```
---

# 🧠 STEP 3 — Reducer (todoReducer.js)

```js
export default function reducer(state, action) {
  switch (action.type) {
    case "ADD":
      return { ...state, todos: [...state.todos, action.payload] };

    case "UPDATE":
      return {
        ...state,
        todos: state.todos.map(t =>
          t.id === action.payload.id ? action.payload : t
        )
      };

    case "TOGGLE":
      return {
        ...state,
        todos: state.todos.map(t =>
          t.id === action.payload
            ? { ...t, completed: !t.completed }
            : t
        )
      };

    case "DELETE":
      return {
        ...state,
        todos: state.todos.filter(t => t.id !== action.payload)
      };

    case "SET_SEARCH":
      return { ...state, search: action.payload };

    case "SET_FILTER":
      return { ...state, filter: action.payload };

    case "LOAD":
      return {
        ...state,
        ...action.payload,
        todos: action.payload.todos || [],
        search: "",
        filter: "ALL"
      };

    default:
      return state;
  }
}
```

---

# 🌐 STEP 4 — Context (TodoContext.js)

```js
import { createContext, useReducer, useContext, useEffect } from "react";
import reducer from "./todoReducer";

const TodoContext = createContext();

const initialState = {
  todos: [],
  search: "",
  filter: "ALL"
};

export function TodoProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, initialState);

  useEffect(() => {
  const data = localStorage.getItem("todos");

  if (data) {
    const savedState = JSON.parse(data);

    // Ensure compatibility with older saved data
    if (Array.isArray(savedState)) {
      dispatch({
        type: "LOAD",
        payload: {
          todos: savedState,
          search: "",
          filter: "ALL"
        }
      });
    } else {
      dispatch({
        type: "LOAD",
        payload: {
          todos: savedState.todos || [],
          search: "",
          filter: "ALL"
           }
         });
       }
     }
   }, []);

  useEffect(() => {
    localStorage.setItem("todos", JSON.stringify(state));
  }, [state]);

  return (
    <TodoContext.Provider value={{ state, dispatch }}>
      {children}
    </TodoContext.Provider>
  );
}

export const useTodos = () => useContext(TodoContext);
```

---

# ✍️ STEP 5 — Todo Input (TodoInput.js)

```js
import { useTodos } from "../context/TodoContext";

export default function TodoInput() {
  const { dispatch } = useTodos();

  const handleSubmit = e => {
    e.preventDefault();
    const f = e.target;

    const todo = {
      id: Date.now(),
      text: f.text.value,
      tags: f.tags.value.split(","),
      dueDate: f.date.value,
      priority: f.priority.value,
      completed: false
    };

    dispatch({ type: "ADD", payload: todo });
    f.reset();
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="text" placeholder="Task" required />
      <input name="tags" placeholder="tags" />
      <input type="date" name="date" />

      <select name="priority">
        <option value="low">Low</option>
        <option value="medium">Medium</option>
        <option value="high">High</option>
      </select>

      <button>Add</button>
    </form>
  );
}
```

---

# ✏️ STEP 6 — Editing Todos (TodoItem.js)

```js
import { useState } from "react";
import { useTodos } from "../context/TodoContext";

export default function TodoItem({ todo }) {
  const { dispatch } = useTodos();
  const [editing, setEditing] = useState(false);
  const [text, setText] = useState(todo.text);

  const save = () => {
    dispatch({ type: "UPDATE", payload: { ...todo, text } });
    setEditing(false);
  };

  const isOverdue =
    !todo.completed &&
    todo.dueDate &&
    new Date(todo.dueDate) < new Date().setHours(0, 0, 0, 0);

  return (
    <li className={`todo-item ${isOverdue ? "overdue" : ""}`}>
      {editing ? (
        <div className="edit-mode">
          <input
            value={text}
            onChange={(e) => setText(e.target.value)}
            autoFocus
          />
          <div className="actions">
            <button className="save" onClick={save}>Save</button>
            <button className="cancel" onClick={() => setEditing(false)}>Cancel</button>
          </div>
        </div>
      ) : (
        <div className="view-mode">
          {/* Header Row: Task Name + Buttons */}
          <div className="task-header">
            <span
              className={`task-text ${todo.completed ? "completed" : ""}`}
              onClick={() => dispatch({ type: "TOGGLE", payload: todo.id })}
            >
              {todo.text}
            </span>

            <div className="actions">
              <button className="edit" onClick={() => setEditing(true)}>Edit</button>
              <button
                className="delete"
                onClick={() => dispatch({ type: "DELETE", payload: todo.id })}
              >
                Delete
              </button>
            </div>
          </div>

          {/* Metadata & Tags fall below the header */}
          <div className="task-details">
            <div className="meta">
              📅 {todo.dueDate}
              {" | "}
              <span className={`priority-${todo.priority.toLowerCase()}`}>
                ⚡ {todo.priority}
              </span>
            </div>

            <div className="tags-container">
              {todo.tags?.map((tag, i) => (
                <span key={i} className="tag">{tag}</span>
              ))}
            </div>
          </div>
        </div>
      )}
    </li>
  );
}
```

---

# 📋 STEP 7 — Todo List (TodoList.js)

```js
import { useTodos } from "../context/TodoContext";
import TodoItem from "./TodoItem";

export default function TodoList() {
  const { state } = useTodos();

  const today = new Date();
  today.setHours(0, 0, 0, 0); // Normalize time for accurate comparison

  const filtered = state.todos
    .filter(t =>
      t.text.toLowerCase().includes(state.search.toLowerCase())
    )
    .filter(t => {
      const dueDate = t.dueDate ? new Date(t.dueDate) : null;
      if (dueDate) dueDate.setHours(0, 0, 0, 0);

      if (state.filter === "COMPLETED") return t.completed;
      if (state.filter === "PENDING") return !t.completed;
      if (state.filter === "OVERDUE") {
        return (
          !t.completed &&
          dueDate &&
          dueDate < today
        );
      }
      return true; // ALL
    });

  return (
    <ul>
      {filtered.map(t => (
        <TodoItem key={t.id} todo={t} />
      ))}
    </ul>
  );
}
```

---

# 🔍 STEP 8 — Search + Filter

SearchBar.js
```js
import { useTodos } from "../context/TodoContext";

export default function SearchBar() {
  const { dispatch } = useTodos();

  return (
    <input
      className="search-bar"
      placeholder="Search..."
      onChange={e => dispatch({ type: "SET_SEARCH", payload: e.target.value })}
    />
  );
}
```

FilterBar.js
```js
import { useTodos } from "../context/TodoContext";

export default function FilterBar() {
  const { state, dispatch } = useTodos();

  return (
    <div className="filter-bar">
      <button
        className={state.filter === "ALL" ? "active" : ""}
        onClick={() =>
          dispatch({ type: "SET_FILTER", payload: "ALL" })
        }
      >
        All
      </button>

      <button
        className={state.filter === "COMPLETED" ? "active" : ""}
        onClick={() =>
          dispatch({ type: "SET_FILTER", payload: "COMPLETED" })
        }
      >
        Completed
      </button>

      <button
        className={state.filter === "PENDING" ? "active" : ""}
        onClick={() =>
          dispatch({ type: "SET_FILTER", payload: "PENDING" })
        }
      >
        Pending
      </button>

      <button
        className={state.filter === "OVERDUE" ? "active" : ""}
        onClick={() =>
          dispatch({ type: "SET_FILTER", payload: "OVERDUE" })
        }
      >
        Overdue
      </button>
    </div>
  );
}
```

---

# 📊 STEP 9 — Charts (Chart.js)

Install chart lib:
```bash
npm install recharts
```

```js
import { useTodos } from "../context/TodoContext";
import { BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid } from "recharts";

export default function Chart() {
  const { state } = useTodos();

  // Normalize today's date
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Calculate overdue tasks
  const overdueCount = state.todos.filter(t => {
    if (!t.dueDate || t.completed) return false;

    const due = new Date(t.dueDate);
    due.setHours(0, 0, 0, 0);

    return due < today;
  }).length;

  // Prepare chart data
  const data = [
    { name: "Completed", value: state.todos.filter(t => t.completed).length },
    { name: "Pending", value: state.todos.filter(t => !t.completed).length },
    { name: "Overdue", value: overdueCount }
  ];

  return (
    <div className="chart">
      <BarChart width={320} height={220} data={data}>
        <CartesianGrid strokeDasharray="3 3" />
        <XAxis dataKey="name" />
        <YAxis allowDecimals={false} />
        <Tooltip />
        <Bar dataKey="value" radius={[6, 6, 0, 0]} />
      </BarChart>
    </div>
  );
}
```

---

# 📊 STEP 10 — Stats (Stats.js)

```js
import { useTodos } from "../context/TodoContext";

export default function Stats() {
  const { state } = useTodos();

  const total = state.todos.length;
  const completed = state.todos.filter(t => t.completed).length;

  return (
    <div className="stats">
      <p>Total: {total}</p>
      <p>Completed: {completed}</p>
      <p>Pending: {total - completed}</p>
    </div>
  );
}
```

---

# 🧩 STEP 11 — App.js (Assembly)

```js
import { TodoProvider } from "./context/TodoContext";
import TodoInput from "./components/TodoInput";
import TodoList from "./components/TodoList";
import SearchBar from "./components/SearchBar";
import FilterBar from "./components/FilterBar";
import Stats from "./components/Stats";
import Chart from "./components/Chart";
import "./styles.css";

export default function App() {
  return (
    <div className="app-container">
      <TodoProvider>
        <h1>My Tasks</h1>
        <TodoInput />
        <SearchBar />
        <FilterBar />
        <TodoList />
        <Stats />
        <Chart />
      </TodoProvider>
    </div>
  );
}
```

---

# 🎯 What You Achieved

You built a **real-world React architecture**:

- Scalable folder structure
- Clean separation of concerns
- Reducer-driven logic
- Global state with Context
- Advanced features (edit, filter, search)
- Data visualization (charts)

---

# 🚀 Next Steps

- Add backend (Node / Firebase)
- Add authentication
- Convert to TypeScript
- Add drag-and-drop


