# 📘 Production-Grade JavaScript Application Handbook

## Build, Test, and Ship a Maintainable Frontend Application (Vanilla JS)

**Edition:** 1.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional
**Tech Stack:**

* Vanilla JavaScript (ES2022+)
* HTML5
* CSS3
* Browser APIs
* Jest (unit testing)
* LocalStorage (persistence)
* Vite (dev server & bundling)

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Understand **modern JavaScript architecture**
✅ Separate **domain logic, UI, and infrastructure**
✅ Write **testable JavaScript code**
✅ Use **unit tests as safety nets**
✅ Build a **complete task management application**
✅ Apply **real-world engineering practices**

---

# 🧭 Architecture Overview

---

## High-Level Architecture

```
+------------------+
|     index.html   |
+------------------+
         |
         v
+------------------+        +------------------+
|   UI (DOM Layer) | <----> | Application Core |
+------------------+        +------------------+
                                     |
                                     v
                           +----------------------+
                           | Persistence Adapter  |
                           | (LocalStorage)       |
                           +----------------------+
```

---

## Design Principles

* **Single Responsibility**
* **Explicit State**
* **Pure Functions where possible**
* **Dependency Isolation**
* **Testability first**

---

# 📁 Project Structure (Production-Grade)

```
js-task-manager/
│
├── index.html
├── style.css
│
├── src/
│   ├── app.js              # App bootstrap
│   ├── state/
│   │   └── taskStore.js    # Domain state & logic
│   ├── ui/
│   │   └── taskView.js     # DOM rendering
│   ├── services/
│   │   └── storage.js      # Persistence adapter
│   └── utils/
│       └── id.js           # Utilities
│
├── tests/
│   ├── taskStore.test.js
│   └── storage.test.js
│
├── package.json
└── vite.config.js
```

---

# ⚙️ Part 1: Tooling & Setup

---

## 1️⃣ Initialize Project

```bash
npm init -y
npm install vite --save-dev
npm install jest --save-dev
```

---

## 2️⃣ Configure Scripts (`package.json`)

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "test": "jest"
  }
}
```

---

## 3️⃣ Jest Config (`jest.config.js`)

```js
export default {
  testEnvironment: "jsdom"
};
```

---

# 🧠 Part 2: Domain Model & State Management

---

## `src/state/taskStore.js`

> **Pure domain logic (testable, no DOM)**

```js
let tasks = [];

export function load(initialTasks = []) {
  tasks = initialTasks;
}

export function getAll() {
  return [...tasks];
}

export function add(title) {
  const task = {
    id: crypto.randomUUID(),
    title,
    completed: false
  };
  tasks.push(task);
  return task;
}

export function toggle(id) {
  tasks = tasks.map(task =>
    task.id === id
      ? { ...task, completed: !task.completed }
      : task
  );
}

export function remove(id) {
  tasks = tasks.filter(task => task.id !== id);
}
```

---

## ✅ Unit Tests for Domain Logic

### `tests/taskStore.test.js`

```js
import { load, getAll, add, toggle, remove } from "../src/state/taskStore";

beforeEach(() => load([]));

test("adds a task", () => {
  add("Learn JS");
  expect(getAll().length).toBe(1);
});

test("toggles task", () => {
  const task = add("Test toggle");
  toggle(task.id);
  expect(getAll()[0].completed).toBe(true);
});

test("removes task", () => {
  const task = add("Delete me");
  remove(task.id);
  expect(getAll()).toHaveLength(0);
});
```

---

# 🗄 Part 3: Persistence Layer (Adapter Pattern)

---

## `src/services/storage.js`

```js
const KEY = "tasks";

export function save(tasks) {
  localStorage.setItem(KEY, JSON.stringify(tasks));
}

export function load() {
  const data = localStorage.getItem(KEY);
  return data ? JSON.parse(data) : [];
}
```

---

## ✅ Storage Tests

### `tests/storage.test.js`

```js
import { save, load } from "../src/services/storage";

beforeEach(() => localStorage.clear());

test("saves and loads tasks", () => {
  const tasks = [{ id: 1, title: "Persist", completed: false }];
  save(tasks);
  expect(load()).toEqual(tasks);
});
```

---

# 🎨 Part 4: UI Layer (DOM Rendering)

---

## `src/ui/taskView.js`

> **All DOM code lives here**

```js
export function render(tasks, handlers) {
  const list = document.getElementById("taskList");
  list.innerHTML = "";

  tasks.forEach(task => {
    const li = document.createElement("li");
    li.textContent = task.title;

    if (task.completed) {
      li.classList.add("completed");
    }

    li.onclick = () => handlers.onToggle(task.id);
    list.appendChild(li);
  });
}
```

---

## UI Design Rules

* No business logic
* No persistence
* Receives **data + callbacks**
* Easy to replace with React later

---

# 🚦 Part 5: Application Orchestration

---

## `src/app.js`

> **Glue code**

```js
import * as store from "./state/taskStore";
import * as storage from "./services/storage";
import { render } from "./ui/taskView";

const input = document.getElementById("taskInput");
const addBtn = document.getElementById("addBtn");

function sync() {
  storage.save(store.getAll());
  render(store.getAll(), {
    onToggle: handleToggle
  });
}

function handleToggle(id) {
  store.toggle(id);
  sync();
}

addBtn.onclick = () => {
  if (!input.value.trim()) return;
  store.add(input.value);
  input.value = "";
  sync();
};

store.load(storage.load());
sync();
```

---

# 🧪 Part 6: Testing Strategy

---

## What We Test

| Layer        | Tested?  | Why                  |
| ------------ | -------- | -------------------- |
| Domain Logic | ✅        | Critical correctness |
| Persistence  | ✅        | Data integrity       |
| UI           | ⚠️ Light | Brittle, expensive   |
| Integration  | ✅        | App wiring           |

---

## Test Pyramid

```
        E2E (few)
     Integration
  Unit Tests (many)
```

---

# 🚀 Part 7: Build & Deployment

---

## Production Build

```bash
npm run build
```

Outputs:

```
dist/
├── index.html
├── assets/
```

---

## Deployment Targets

* GitHub Pages
* Netlify
* Cloudflare Pages
* S3 + CloudFront

---

# 🏛 Part 8: Enterprise-Grade Extensions

---

Add progressively:

🔐 Authentication (OAuth)
🌐 Backend API (Node.js / Express)
📦 Replace LocalStorage with REST
🧪 Cypress E2E tests
🧩 Feature flags
📊 Telemetry & logging
📱 PWA support

---
