# 📘 JavaScript Task Manager: Step-By-Step Beginner Project Tutorial

**Interactive + Visual + Challenges + Cheat Sheet**

**Edition:** 1.0 
**Audience:** Absolute beginners → aspiring professional JS developers
**Level:** Beginner → Professional

**Goal:** Build a **Vanilla JS task manager** demonstrating:

* Event-driven architecture
* Modular code layers (UI, Event Bus, Core, Persistence)
* Persistence with localStorage
* Visual ASCII flow of system
* Layer-by-layer mini challenges
* Quick-reference cheat sheet

---

## 🏁 Step 0: Setup & Overview

We’re building a **task manager** with:

* Add, toggle, and remove tasks.
* Event-driven architecture using a **central Event Bus**.
* **localStorage** persistence.
* **Layered architecture**: UI → Event Bus → Core → Persistence → UI.

**Project folder structure:**

```
js-task-manager/
├── index.html
├── style.css
├── src/
│   ├── app.js
│   ├── state/taskStore.js
│   ├── ui/taskView.js
│   ├── services/storage.js
│   ├── bus/bus.js
│   └── utils/id.js
└── tests/
```

✅ **Checkpoint 0:** Create folders and open in your editor.

---

## 🧩 Step 1: JavaScript Basics

* **Runtime-Executed**: JS engine (V8/SpiderMonkey)
* **Single-Threaded & Event-Driven**: callbacks, promises, async/await
* **Multi-Paradigm**: imperative, functional, object-oriented
* **Portable**: browser + Node.js

**Exercise 1:** Test JS in browser and Node.js:

```html
<button onclick="alert('Hello JS!')">Click Me</button>
```

```js
console.log("Hello from Node.js!");
```

---

## 🌐 Step 2: Technology Stack

| Tool                 | Purpose                     |
| -------------------- | --------------------------- |
| Vanilla JS (ES2022+) | Core language mastery       |
| HTML5 / CSS3         | Render content              |
| Browser APIs         | DOM, events, fetch, storage |
| Jest                 | Core logic testing          |
| LocalStorage         | Persistence                 |
| Vite                 | Fast dev/build environment  |

✅ **Exercise 2:** Initialize Vite:

```bash
npm create vite@latest js-task-manager
cd js-task-manager
npm install
npm run dev
```

---

## 🏗️ Step 3: Layered Architecture

**Layers:**

```
UI Layer → Event Bus → Core Logic → Event Bus → Persistence → UI Layer
```

✅ **Exercise 3:** Sketch this diagram.

---

## 🖋️ Step 4: Step-By-Step Implementation

### 4a: Event Bus (`bus.js`)

```js
const listeners = {};

export function emit(event, payload) {
  if (!listeners[event]) return;
  listeners[event].forEach(fn => fn(payload));
}

export function on(event, fn) {
  if (!listeners[event]) listeners[event] = [];
  listeners[event].push(fn);
}

export function off(event, fn) {
  if (!listeners[event]) return;
  listeners[event] = listeners[event].filter(f => f !== fn);
}
```

✅ **Exercise:** Test event emission and logging.

---

### 4b: Core Logic (`taskStore.js`)

```js
import { emit } from '../bus/bus.js';

let tasks = [];

export function load(initial = []) {
  tasks = initial;
  emit('tasksLoaded', [...tasks]);
}

export function getAll() {
  return [...tasks];
}

export function add(title) {
  const task = { id: crypto.randomUUID(), title, completed: false };
  tasks.push(task);
  emit('taskAdded', task);
  return task;
}

export function toggle(id) {
  tasks = tasks.map(t => t.id === id ? { ...t, completed: !t.completed } : t);
  emit('taskToggled', id);
}

export function remove(id) {
  tasks = tasks.filter(t => t.id !== id);
  emit('taskRemoved', id);
}
```

✅ **Exercise:** Add, toggle, remove tasks, verify `getAll()`.

---

### 4c: UI Layer (`taskView.js`)

```js
import { on, emit } from '../bus/bus.js';
import { getAll } from '../state/taskStore.js';

const listEl = document.querySelector('#taskList');

export function render(tasks) {
  listEl.innerHTML = '';
  tasks.forEach(task => {
    const li = document.createElement('li');
    li.textContent = task.title;
    li.style.textDecoration = task.completed ? 'line-through' : 'none';
    li.addEventListener('click', () => emit('toggleTask', task.id));
    listEl.appendChild(li);
  });
}

on('tasksLoaded', render);
on('taskAdded', () => render(getAll()));
on('taskToggled', () => render(getAll()));
on('taskRemoved', () => render(getAll()));
```

✅ **Exercise:** Verify UI toggling in `<ul id="taskList"></ul>`.

---

### 4d: Persistence (`storage.js`)

```js
import { on } from '../bus/bus.js';
import { getAll } from '../state/taskStore.js';

on('taskAdded', saveTasks);
on('taskToggled', saveTasks);
on('taskRemoved', saveTasks);

function saveTasks() {
  localStorage.setItem('tasks', JSON.stringify(getAll()));
}
```

✅ **Exercise:** Refresh page → tasks persist.

---

### 4e: App Orchestration (`app.js`)

```js
import * as store from './state/taskStore.js';
import './ui/taskView.js';
import './services/storage.js';
import { on } from './bus/bus.js';

on('addTask', title => store.add(title));
on('toggleTask', id => store.toggle(id));
on('removeTask', id => store.remove(id));

const initial = JSON.parse(localStorage.getItem('tasks') || '[]');
store.load(initial);
```

✅ **Exercise:** Test full workflow.

---

## 🧩 Step 5: Full-System Visual Flow (ASCII)

```
Step 0: App Load
UI: <ul id="taskList"></ul>
Event Bus: listeners registered
Core: tasks=[]
Persistence: localStorage empty
Browser: blank list

User Action: Add "Buy milk"
UI → emit('addTask') → Core.add() → emit('taskAdded') → Persistence.save() → UI.render()
Browser shows: Buy milk

User Action: Toggle "Buy milk"
UI → Core.toggle() → Persistence.save() → UI.render()
Browser shows: Buy milk (line-through)
```

---

## 🧪 Step 6: Layer-by-Layer Mini Challenges

| Layer       | Mini Challenge          | Expected Outcome                       |
| ----------- | ----------------------- | -------------------------------------- |
| UI          | Add “Remove” button     | Clicking removes task → UI updates     |
| Event Bus   | Log every event emitted | Console logs for all events            |
| Core Logic  | Add task priority       | `getAll()` shows priority, UI updates  |
| Persistence | Save timestamp          | `localStorage` shows timestamped tasks |

✅ **Exercise:** Complete all mini-challenges.

---

## 🌍 Step 7: Testing

* Unit → Core logic
* Integration → Core + Event Bus + UI
* E2E → Full browser simulation

```js
test('add task increases tasks length', () => {
  const initial = getAll().length;
  add('Test Task');
  expect(getAll().length).toBe(initial + 1);
});
```

---

## 🚀 Step 8: Build & Deploy

* Vite bundling
* Deploy: GitHub Pages / Netlify / S3

✅ **Exercise:** Deploy a working demo online.

---

## 🧠 Step 9: Final Mental Model

```
User Action → Event Bus → Core → Event Bus → Adapters (UI, Storage)
```

✅ **Exercise:** Sketch 3 example actions.

---

## 📝 Cheat Sheet: Visual Flow + Layer Challenges (One Page)

```
Layers: UI → Event Bus → Core → Event Bus → Persistence → UI

Event Flow Examples:
Add Task:
UI.emit('addTask') → Core.add() → EventBus.emit('taskAdded') → Persistence.save() → UI.render()

Toggle Task:
UI.emit('toggleTask') → Core.toggle() → EventBus.emit('taskToggled') → Persistence.save() → UI.render()

Remove Task:
UI.emit('removeTask') → Core.remove() → EventBus.emit('taskRemoved') → Persistence.save() → UI.render()

Mini Challenges:
UI: Add “Remove” button
Event Bus: Log all events
Core: Add priority field
Persistence: Add timestamp
Testing: Unit → Integration → E2E

Tips:
- Keep core logic pure
- Emit events for all state changes
- UI renders are reactive to Event Bus
- Persistence happens at every state change
