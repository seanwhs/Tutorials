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
/* --- Global & Layout --- */
:root {
  --primary: #4f46e5;
  --bg: #f8fafc;
  --card: #ffffff;
  --text-main: #1e293b;
  --text-muted: #64748b;
  --border: #e2e8f0;
}

body {
  margin: 0;
  font-family: 'Inter', -apple-system, sans-serif;
  background-color: var(--bg);
  color: var(--text-main);
}

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

/* --- Wrapper for the List --- */
ul {
  padding: 0;
  width: 100%;
  max-width: 550px;
}

/* --- Todo Item Card --- */
.todo-item {
  list-style: none;
  padding: 18px;
  background: var(--card);
  border-radius: 12px;
  border: 1px solid var(--border);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
  margin-bottom: 16px;
  transition: transform 0.2s, box-shadow 0.2s;
}

.todo-item:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1);
}

/* --- Header Row --- */
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
  transition: color 0.2s;
}

.task-text.completed {
  text-decoration: line-through;
  color: var(--text-muted);
  opacity: 0.6;
}

/* --- Actions Buttons --- */
.actions {
  display: flex;
  gap: 8px;
}

.actions button {
  padding: 6px 12px;
  border-radius: 6px;
  border: none;
  cursor: pointer;
  font-weight: 600;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  transition: all 0.2s;
}

.edit { background: #eff6ff; color: #2563eb; }
.edit:hover { background: #dbeafe; }

.delete { background: #fff1f2; color: #e11d48; }
.delete:hover { background: #ffe4e6; }

.save { background: #22c55e; color: white; }
.cancel { background: #94a3b8; color: white; }

/* --- Details Section --- */
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

/* Priority Badges */
.priority-high { color: #be123c; background: #fff1f2; padding: 2px 8px; border-radius: 4px; }
.priority-medium { color: #b45309; background: #fef3c7; padding: 2px 8px; border-radius: 4px; }
.priority-low { color: #047857; background: #ecfdf5; padding: 2px 8px; border-radius: 4px; }

/* --- Tags --- */
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

/* --- Edit Mode --- */
.edit-mode {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.edit-mode input {
  padding: 10px;
  border: 2px solid var(--primary);
  border-radius: 8px;
  font-size: 1rem;
  outline: none;
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
          t.id === action.payload ? { ...t, completed: !t.completed } : t
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
      return action.payload;

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
    if (data) dispatch({ type: "LOAD", payload: JSON.parse(data) });
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

  return (
    <li className="todo-item">
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

  const filtered = state.todos
    .filter(t => t.text.toLowerCase().includes(state.search.toLowerCase()))
    .filter(t => {
      if (state.filter === "COMPLETED") return t.completed;
      if (state.filter === "PENDING") return !t.completed;
      return true;
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
  const { dispatch } = useTodos();

  return (
    <div className="filter-bar">
      <button onClick={() => dispatch({ type: "SET_FILTER", payload: "ALL" })}>All</button>
      <button onClick={() => dispatch({ type: "SET_FILTER", payload: "COMPLETED" })}>Completed</button>
      <button onClick={() => dispatch({ type: "SET_FILTER", payload: "PENDING" })}>Pending</button>
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
import { BarChart, Bar, XAxis, YAxis, Tooltip } from "recharts";

export default function Chart() {
  const { state } = useTodos();

  const data = [
    { name: "Completed", value: state.todos.filter(t => t.completed).length },
    { name: "Pending", value: state.todos.filter(t => !t.completed).length }
  ];

  return (
    <div className="chart">
      <BarChart width={300} height={200} data={data}>
        <XAxis dataKey="name" />
        <YAxis />
        <Tooltip />
        <Bar dataKey="value" />
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


