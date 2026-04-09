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
/* ==========================================================================
   1. VARIABLES & RESET
   ========================================================================== */
:root {
  /* Colors */
  --primary: #4f46e5;
  --primary-dark: #4338ca;
  --primary-light: #eef2ff;
  --danger: #ef4444;
  
  /* Text & Surface */
  --bg: #f8fafc;
  --card: #ffffff;
  --text-main: #1e293b;
  --text-muted: #64748b;
  --border: #e2e8f0;
  
  /* Design Tokens */
  --radius: 12px;
  --radius-sm: 8px;
  --shadow-sm: 0 2px 4px rgba(0, 0, 0, 0.05);
  --shadow-md: 0 6px 12px rgba(0, 0, 0, 0.08);
  --transition: all 0.2s ease-in-out;
  --focus-ring: 0 0 0 3px rgba(79, 70, 229, 0.15);
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: "Inter", -apple-system, BlinkMacSystemFont, sans-serif;
  background: var(--bg);
  color: var(--text-main);
  line-height: 1.5;
}

/* ==========================================================================
   2. CORE LAYOUT
   ========================================================================== */
.app-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px;
  min-height: 100vh;
}

h1 {
  font-size: 2.5rem;
  font-weight: 800;
  color: var(--primary);
  margin-bottom: 20px;
  letter-spacing: -0.5px;
}

/* ==========================================================================
   3. SHARED UI COMPONENTS (Inputs & Buttons)
   ========================================================================== */
input, select {
  padding: 10px 12px;
  border-radius: var(--radius-sm);
  border: 1px solid var(--border);
  font-size: 0.95rem;
  transition: var(--transition);
}

input:focus, select:focus {
  border-color: var(--primary);
  outline: none;
  box-shadow: var(--focus-ring);
}

.btn-primary {
  background: var(--primary);
  color: white;
  border: none;
  padding: 10px 18px;
  border-radius: var(--radius-sm);
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition);
}

.btn-primary:hover {
  background: var(--primary-dark);
  transform: translateY(-1px);
}

/* ==========================================================================
   4. FEATURE COMPONENTS
   ========================================================================== */

/* --- Task Form --- */
form {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 10px;
  background: var(--card);
  padding: 15px;
  border-radius: var(--radius);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
  max-width: 900px;
  width: 100%;
}

/* --- Navigation & Search --- */
.search-bar {
  margin-top: 15px;
  width: 100%;
  max-width: 420px;
  box-shadow: var(--shadow-sm);
}

.filter-bar {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin: 20px 0;
  flex-wrap: wrap;
}

.filter-bar button {
  padding: 10px 18px;
  border-radius: 10px;
  border: 1px solid var(--border);
  background: var(--card);
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition);
}

.filter-bar button:hover {
  background: var(--primary-light);
  color: var(--primary);
}

.filter-bar button.active {
  background: var(--primary);
  color: white;
  border-color: var(--primary);
  box-shadow: var(--shadow-sm);
}

/* --- Todo List --- */

ul {
  padding: 0;
  width: 100%;
  max-width: 900px; /* Increased to accommodate single-line elements */
}

.todo-item {
  list-style: none;
  background: var(--card);
  border-radius: var(--radius);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
  margin-bottom: 12px;
  transition: var(--transition);
  padding: 0 18px; /* Vertical padding is now inside child elements */
}

.todo-item:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-1px);
}

/* Edit Mode Styles */
.todo-item .edit-mode.full-edit {
  display: flex;
  flex-wrap: wrap; /* Allows wrapping on small screens */
  gap: 8px;
  width: 100%;
}

.todo-item .edit-mode.full-edit input[type="text"] {
  flex: 2; /* Task text gets more space */
}

.todo-item .edit-mode.full-edit input,
.todo-item .edit-mode.full-edit select {
  padding: 5px;
  font-size: 0.85rem;
}

/* View Mode Styles (Single-line row) */
.todo-item .view-mode {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 15px;
  min-height: 50px;
  color: var(--text-main);
}

/* Container for text and metadata (Left side) */
.todo-item .content-group {
  display: flex;
  align-items: center;
  gap: 15px;
  flex-grow: 1;
}

/* Main task text */
.todo-item .task-text {
  font-size: 1.125rem;
  font-weight: 600;
  cursor: pointer;
  transition: var(--transition);
}

.todo-item .task-text:hover {
  color: var(--primary);
}

.todo-item .task-text.completed {
  text-decoration: line-through;
  color: var(--text-muted);
  opacity: 0.6;
}

/* Metadata group (due date, priority, tags) */
.todo-item .meta-group {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--text-muted);
  font-size: 0.9rem;
}

/* Individual tag styling */
.todo-item .tag {
  background: var(--primary-light);
  color: var(--primary);
  padding: 2px 8px;
  border-radius: 4px;
  font-weight: 600;
  font-size: 0.8rem;
}

/* Action Buttons (Right side) */
.todo-item .actions {
  display: flex;
  gap: 6px;
}

.todo-item .actions button {
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  font-weight: 600;
  transition: var(--transition);
}

.todo-item .actions .edit:hover { background: #e0f2fe; color: #0284c7; }
.todo-item .actions .delete:hover { background: #fee2e2; color: var(--danger); }
.todo-item .actions .save:hover { background: #dcfce7; color: #166534; }
.todo-item .actions .cancel:hover { background: var(--border); }

/* Priority Colors */
.todo-item .priority-high { color: var(--danger); font-weight: bold; }
.todo-item .priority-medium { color: #f97316; font-weight: bold; }
.todo-item .priority-low { color: #64748b; font-weight: bold; }

/* States */
.todo-item.overdue {
  border-left: 5px solid var(--danger);
  background: #fff5f5;
}

/* Update h1 slightly for better balance */
h1 {
  margin-top: 0;
}

/* ==========================================================================
   5. ANALYTICS
   ========================================================================== */
.analytics-container {
  display: flex;
  justify-content: center;
  gap: 20px;
  margin-top: 30px;
  flex-wrap: wrap;
  width: 100%;
  max-width: 900px;
}

.chart, .stats {
  background: var(--card);
  padding: 20px;
  border-radius: var(--radius);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-sm);
}

.chart { flex: 2; }

.stats {
  flex: 1;
  min-width: 220px;
}

.stats p {
  margin: 12px 0;
  font-size: 1rem;
  font-weight: 600;
}

/* ==========================================================================
   6. RESPONSIVE DESIGN
   ========================================================================== */
@media (max-width: 768px) {
  h1 { font-size: 2rem; }

  form {
    flex-direction: column;
    align-items: stretch;
  }

  .search-bar { max-width: 100%; }

  .analytics-container {
    flex-direction: column;
    align-items: center;
  }

  .chart, .stats { width: 100%; }
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
      <input name="text" placeholder="Enter a task..." required />
      <input name="tags" placeholder="e.g. work, urgent" />
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
  
  // 1. Expand local state to hold all editable fields
  const [tempTodo, setTempTodo] = useState({
    text: todo.text,
    priority: todo.priority,
    tags: todo.tags.join(", "), // Convert array to string for input
    dueDate: todo.dueDate
  });

  const save = () => {
    dispatch({ 
      type: "UPDATE", 
      payload: { 
        ...todo, 
        text: tempTodo.text,
        priority: tempTodo.priority,
        dueDate: tempTodo.dueDate,
        tags: tempTodo.tags.split(",").map(t => t.trim()) // Convert string back to array
      } 
    });
    setEditing(false);
  };

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const isOverdue = !todo.completed && todo.dueDate && new Date(todo.dueDate) < today;

  return (
    <li className={`todo-item ${isOverdue ? "overdue" : ""}`}>
      {editing ? (
        // 2. NEW EDIT MODE: Includes Text, Date, Priority, and Tags
        <div className="edit-mode full-edit">
          <input
            value={tempTodo.text}
            onChange={(e) => setTempTodo({...tempTodo, text: e.target.value})}
            placeholder="Task name"
          />
          <input 
            type="date" 
            value={tempTodo.dueDate} 
            onChange={(e) => setTempTodo({...tempTodo, dueDate: e.target.value})}
          />
          <select 
            value={tempTodo.priority} 
            onChange={(e) => setTempTodo({...tempTodo, priority: e.target.value})}
          >
            <option value="low">Low</option>
            <option value="medium">Medium</option>
            <option value="high">High</option>
          </select>
          <input 
            value={tempTodo.tags} 
            onChange={(e) => setTempTodo({...tempTodo, tags: e.target.value})}
            placeholder="Tags (comma separated)"
          />
          <div className="actions">
            <button className="save" onClick={save}>Save</button>
            <button className="cancel" onClick={() => setEditing(false)}>Cancel</button>
          </div>
        </div>
      ) : (
        /* VIEW MODE (Remains the same as previous step) */
        <div className="view-mode">
          <div className="content-group">
            <span
              className={`task-text ${todo.completed ? "completed" : ""}`}
              onClick={() => dispatch({ type: "TOGGLE", payload: todo.id })}
            >
              {todo.text}
            </span>
            <div className="meta-group">
              <span>📅 {todo.dueDate}</span>
              <span className={`priority-${todo.priority}`}>⚡ {todo.priority}</span>
              {todo.tags?.map((tag, i) => (
                <span key={i} className="tag">{tag}</span>
              ))}
            </div>
          </div>
          <div className="actions">
            <button className="edit" onClick={() => setEditing(true)}>Edit</button>
            <button className="delete" onClick={() => dispatch({ type: "DELETE", payload: todo.id })}>Delete</button>
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

  const filters = [
    { label: "All 📋", value: "ALL" },
    { label: "Completed ✅", value: "COMPLETED" },
    { label: "Pending ⏳", value: "PENDING" },
    { label: "Overdue ⚠️", value: "OVERDUE" }
  ];

  return (
    <div className="filter-bar">
      {filters.map((filter) => (
        <button
          key={filter.value}
          className={state.filter === filter.value ? "active" : ""}
          onClick={() =>
            dispatch({ type: "SET_FILTER", payload: filter.value })
          }
        >
          {filter.label}
        </button>
      ))}
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


