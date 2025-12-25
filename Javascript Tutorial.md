# 📘 JavaScript Application Handbook 

## Build, Test, and Ship a Maintainable Frontend Application (Vanilla JS)

**Edition:** 1.0
**Audience:** Engineers, Bootcamp Learners, Trainers
**Level:** Beginner → Professional

**Tech Stack:**

* Vanilla JavaScript (ES2022+)
* HTML5 / CSS3
* Browser APIs
* Jest (unit testing)
* LocalStorage (persistence)
* Vite (dev server & bundling)

---

## 🎯 Learning Outcomes

By the end of this guide, readers will:

✅ Understand **modern JavaScript architecture & modular design**
✅ Separate **domain logic, UI, and persistence layers**
✅ Write **testable and maintainable JavaScript code**
✅ Use **unit tests and integration tests as safety nets**
✅ Build a **full-featured task management application**
✅ Apply **real-world engineering practices** (dependency isolation, pure functions, orchestration)
✅ Visualize **app flow & lifecycle using ASCII diagrams**

---

# 🧭 Architecture Overview

---

## Full App Flow (ASCII Diagram)

```
       +----------------+
       |   User Input   |
       | (click / type) |
       +----------------+
                │
                ▼
       +----------------+
       |    UI Layer    |  <-- Handles DOM rendering & event listeners
       |  (taskView.js) |
       +----------------+
                │
                ▼
       +----------------+
       | Application Core|  <-- Pure domain logic; single source of truth
       |  (taskStore.js)|
       +----------------+
                │
                ▼
       +----------------------+
       | Persistence Adapter  |  <-- Abstracts storage (LocalStorage)
       |   (storage.js)       |
       +----------------------+
                │
                ▼
         Browser Storage
                │
                ▼
          +-----------+
          | Unit Tests|
          |   Jest    |
          +-----------+
```

**Mental Models:**

* **UI Layer:** Only renders, listens to events, and triggers callbacks.
* **Application Core:** Maintains tasks as the **single source of truth**, all mutations happen here.
* **Persistence Adapter:** Isolates storage logic so you can swap LocalStorage for REST APIs or IndexedDB.
* **Tests:** Verify each layer independently for **predictable, maintainable behavior**.

> Think of it as a **pipeline**:
> `User Input → UI → Core → Persistence → UI refresh`

---

## Design Principles

* **Single Responsibility:** Each module does one thing.
* **Explicit State:** Avoid hidden state, centralize in the Core.
* **Pure Functions:** Deterministic, easier to test.
* **Dependency Isolation:** Layers depend only on the layer below.
* **Testability First:** Write tests alongside logic, not after.

---

# 📁 Project Structure

```
js-task-manager/
│
├── index.html            # Entry point
├── style.css             # Global styles
│
├── src/
│   ├── app.js            # Orchestration
│   ├── state/
│   │   └── taskStore.js  # Domain logic (pure)
│   ├── ui/
│   │   └── taskView.js   # DOM rendering
│   ├── services/
│   │   └── storage.js    # Persistence layer (adapter)
│   └── utils/
│       └── id.js         # Utility helpers
│
├── tests/
│   ├── taskStore.test.js
│   └── storage.test.js
│
├── package.json
└── vite.config.js
```

**Mental Model:** Separation allows replacing any layer (UI → React, storage → API) **without touching other layers**.

---

# ⚙️ Part 1: Tooling & Setup

---

## 1️⃣ Initialize Project

```bash
npm init -y
npm install vite --save-dev
npm install jest --save-dev
```

* **Vite** → Dev server with HMR & fast bundling
* **Jest** → Unit testing framework using `jsdom`

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

* `dev` → Start dev server
* `build` → Production bundle
* `test` → Run all unit tests

---

## 3️⃣ Jest Config (`jest.config.js`)

```js
export default {
  testEnvironment: "jsdom"
};
```

> `jsdom` enables DOM testing in Node.js environment.

---

# 🧠 Part 2: Domain Model & State Management

---

## `src/state/taskStore.js` (Pure Logic)

```js
let tasks = [];

export function load(initialTasks = []) {
  tasks = initialTasks;
}

export function getAll() {
  return [...tasks];
}

export function add(title) {
  const task = { id: crypto.randomUUID(), title, completed: false };
  tasks.push(task);
  return task;
}

export function toggle(id) {
  tasks = tasks.map(t => t.id === id ? { ...t, completed: !t.completed } : t);
}

export function remove(id) {
  tasks = tasks.filter(t => t.id !== id);
}
```

**Example Usage:**

```js
const task = add("Learn JS");
toggle(task.id);
remove(task.id);
getAll();
```

> **Mental Model:** Application Core = **single source of truth**. UI observes state, does not mutate directly.

---

## ✅ Unit Tests (`tests/taskStore.test.js`)

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

**Teaching Tip:** Adapter pattern allows **swapping storage** without touching Core.

---

## ✅ Storage Tests

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

```js
export function render(tasks, handlers) {
  const list = document.getElementById("taskList");
  list.innerHTML = "";

  tasks.forEach(task => {
    const li = document.createElement("li");
    li.textContent = task.title;
    if (task.completed) li.classList.add("completed");
    li.onclick = () => handlers.onToggle(task.id);
    list.appendChild(li);
  });
}
```

**UI Design Rules:**

* No domain logic
* No persistence
* Receives **data + callbacks**
* Replaceable with React later

**ASCII Flow:**

```
taskStore --> render(tasks) --> [DOM]
      ^                       |
      | callback (toggle)     |
      +----------------------+
```

---

# 🚦 Part 5: Application Orchestration

---

## `src/app.js`

```js
import * as store from "./state/taskStore";
import * as storage from "./services/storage";
import { render } from "./ui/taskView";

const input = document.getElementById("taskInput");
const addBtn = document.getElementById("addBtn");

function sync() {
  storage.save(store.getAll());
  render(store.getAll(), { onToggle: handleToggle });
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

> **Mental Model:** `sync()` orchestrates **Core → Persistence → UI**, ensuring **predictable state updates**.

---

# 🧪 Part 6: Testing Strategy

---

| Layer        | Tested?  | Why                  |
| ------------ | -------- | -------------------- |
| Domain Logic | ✅        | Core correctness     |
| Persistence  | ✅        | Data integrity       |
| UI           | ⚠️ Light | Brittle, expensive   |
| Integration  | ✅        | Verify orchestration |

**Test Pyramid:**

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

> Mental Model: Static SPA → **fast deployment**, domain logic stays client-side.

---

# 🏛 Part 8: Enterprise-Grade Extensions

* 🔐 Authentication (OAuth / JWT)
* 🌐 Backend API (Node.js/Express)
* 📦 Replace LocalStorage with REST or DB
* 🧪 Cypress E2E tests
* 🧩 Feature flags
* 📊 Telemetry & logging
* 📱 Progressive Web App (PWA)

---

# ✅ End-to-End Flow Diagram (ASCII)

```
+----------------+      +----------------+      +----------------+
|   User Input   | ---> |    UI Layer    | ---> | Application    |
| (click / type) |      |  (taskView.js) |      | Core (taskStore)|
+----------------+      +----------------+      +----------------+
                                                           |
                                                           v
                                                +----------------------+
                                                | Persistence Adapter  |
                                                |     (storage.js)     |
                                                +----------------------+
                                                           |
                                                           v
                                                  Browser Storage (LocalStorage)
                                                           |
                                                           v
                                                   +----------------+
                                                   | Unit & Integration|
                                                   |    Tests        |
                                                   +----------------+
```

---

✅ **Key Takeaways**

* Full **separation of concerns**: UI, Core, Persistence
* **Testable, modular domain logic**
* **Adapter pattern** for storage abstraction
* Central **orchestration** ensures predictable flow
* ASCII diagrams help **visualize the app lifecycle**

---
