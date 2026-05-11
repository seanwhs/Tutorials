## 🧱 Phase 1: Vanilla JavaScript (The Manual Labor)

In Vanilla, the **DOM is the source of truth**. If you want to know if a task is completed, you have to look at the class list of an HTML element.

```javascript
// Imperative: Step-by-step instructions for the browser
const input = document.getElementById('todoInput');
const addBtn = document.getElementById('addBtn');
const list = document.getElementById('todoList');

addBtn.addEventListener('click', () => {
    if (!input.value) return;

    const li = document.createElement('li');
    li.textContent = input.value;
    
    const del = document.createElement('button');
    del.textContent = 'X';
    del.onclick = () => li.remove(); // Direct DOM manipulation

    li.appendChild(del);
    list.appendChild(li);
    input.value = '';
});

```

---

## ⚛️ Phase 2: React Component (The Data-Driven UI)

In React, the **State is the source of truth**. The UI is just a "snapshot" of what that data looks like at any given moment.

```jsx
function TodoApp() {
  const [todos, setTodos] = useState([]);
  const [text, setText] = useState('');

  const handleAdd = () => {
    setTodos([...todos, { id: Date.now(), content: text }]);
    setText('');
  };

  return (
    <div>
      <input value={text} onChange={(e) => setText(e.target.value)} />
      <button onClick={handleAdd}>Add</button>
      <ul>
        {todos.map(t => <li key={t.id}>{t.content}</li>)}
      </ul>
    </div>
  );
}

```

---

## 🧠 Phase 3: The Mental Model Shift

### Visual Flow Comparison

| Feature | Vanilla JS Flow | React Flow |
| --- | --- | --- |
| **Trigger** | User clicks button | User clicks button |
| **Action** | Code finds the `<ul>` element | Code updates a JS array (`setState`) |
| **Mutation** | Code creates/appends `<li>` | React notices data changed |
| **Result** | Screen changes directly | React re-draws UI based on new data |

> **Key Takeaway:** In Vanilla, you manage **Relationships** between elements. In React, you manage **Transitions** between data states.

---

## 🪝 Phase 4: The Custom Hook (Architecture Level)

To reach professional-grade React, we separate **Logic** from **View**. We extract everything into a `useTodo` hook. This makes your code testable and your UI component extremely thin.

```javascript
// useTodo.js
export function useTodo() {
  const [todos, setTodos] = useState([]);
  const [text, setText] = useState('');

  const addTodo = () => {
    if (!text.trim()) return;
    setTodos(prev => [...prev, { id: Date.now(), content: text }]);
    setText('');
  };

  const removeTodo = (id) => setTodos(prev => prev.filter(t => t.id !== id));

  return { todos, text, setText, addTodo, removeTodo };
}

```

---

## 🧭 Phase 5: The Evolution (Scaling State)

As applications grow, "local" state isn't enough. You move from the component level to the system level.

### The State Management Ladder

1. **useState:** Perfect for a single form or a toggle switch.
2. **Prop Drilling:** (The Problem) Passing data through 5 components that don't need it just to reach 1 that does.
3. **Zustand (Modern/Simple):** A global "store" where any component can grab the list of todos without passing props.
4. **Redux (Enterprise):** Strict, predictable patterns for massive teams managing thousands of state changes.

| Tech | Thinking Style | When to use? |
| --- | --- | --- |
| **Local State** | "What does this button do right now?" | Small features |
| **Zustand** | "Where is the global list of tasks?" | Most modern Apps |
| **Redux** | "How does every action affect the entire system history?" | Large Scale / Complex |

---

### The Professional Refactor Process

1. **Lift State:** Step 1.
Move data out of individual list items and into a parent array.


2. **Extract Logic:** Step 2.
Move the `handleAdd` and `handleRemove` functions into a Custom Hook (`useTodo`).


3. **Clean View:** Step 3.
Refactor the JSX component so it only contains the `return` statement and calls the hook.


4. **Globalize (Optional):** Step 4.
If the Todo count needs to appear in a Navbar far away, migrate the hook logic into a **Zustand store**.
