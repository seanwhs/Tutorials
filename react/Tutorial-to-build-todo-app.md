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
/* ===== GLOBAL ===== */
body {
  font-family: Arial, sans-serif;
  background: #f4f6f8;
  margin: 0;
  padding: 0;
}

h1 {
  text-align: center;
  margin-top: 20px;
}

/* ===== CONTAINER ===== */
.app-container {
  max-width: 700px;
  margin: 30px auto;
  background: white;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0 4px 10px rgba(0,0,0,0.1);
}

/* ===== FORM ===== */
form {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 20px;
}

input, select {
  padding: 8px;
  border: 1px solid #ccc;
  border-radius: 6px;
}

input[name="text"] {
  flex: 2;
}

input[name="tags"],
input[type="date"],
select {
  flex: 1;
}

/* ===== BUTTONS ===== */
button {
  padding: 8px 12px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  background: #007bff;
  color: white;
  transition: 0.2s;
}

button:hover {
  background: #0056b3;
}

button.delete {
  background: #dc3545;
}

button.delete:hover {
  background: #a71d2a;
}

button.edit {
  background: #ffc107;
  color: black;
}

button.edit:hover {
  background: #d39e00;
}

/* ===== SEARCH ===== */
.search-bar {
  width: 100%;
  margin-bottom: 10px;
}

/* ===== FILTER ===== */
.filter-bar {
  display: flex;
  justify-content: center;
  gap: 10px;
  margin-bottom: 15px;
}

/* ===== LIST ===== */
ul {
  list-style: none;
  padding: 0;
}

li {
  padding: 10px;
  border-bottom: 1px solid #eee;
  display: flex;
  flex-direction: column;
  gap: 5px;
}

li:hover {
  background: #f9f9f9;
}

/* ===== TASK TEXT ===== */
.task-text {
  font-weight: bold;
  cursor: pointer;
}

.completed {
  text-decoration: line-through;
  color: gray;
}

/* ===== META INFO ===== */
.meta {
  font-size: 12px;
  color: #666;
}

/* ===== TAGS ===== */
.tag {
  display: inline-block;
  background: #e0e7ff;
  color: #333;
  padding: 2px 6px;
  border-radius: 5px;
  margin-right: 5px;
  font-size: 11px;
}

/* ===== PRIORITY ===== */
.priority-low {
  color: green;
}

.priority-medium {
  color: orange;
}

.priority-high {
  color: red;
  font-weight: bold;
}

/* ===== ACTION BUTTONS ===== */
.actions {
  display: flex;
  gap: 10px;
  margin-top: 5px;
}

/* ===== STATS ===== */
.stats {
  margin-top: 20px;
  padding-top: 10px;
  border-top: 1px solid #eee;
  text-align: center;
}

/* ===== CHART ===== */
.chart {
  display: flex;
  justify-content: center;
  margin-top: 20px;
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
    <li>
      {editing ? (
        <>
          <input value={text} onChange={e => setText(e.target.value)} />
          <button onClick={save}>Save</button>
        </>
      ) : (
        <>
          <span onClick={() => dispatch({ type: "TOGGLE", payload: todo.id })}>
            {todo.text}
          </span>

          <button onClick={() => setEditing(true)}>Edit</button>
        </>
      )}

      <button onClick={() => dispatch({ type: "DELETE", payload: todo.id })}>
        Delete
      </button>
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
    <div>
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
    <BarChart width={300} height={200} data={data}>
      <XAxis dataKey="name" />
      <YAxis />
      <Tooltip />
      <Bar dataKey="value" />
    </BarChart>
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
    <div>
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


