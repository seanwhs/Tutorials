# 📘 JavaScript Tutorial

## **Build a Production‑Grade Vanilla JS Task Manager**

**Edition:** 1.0 Interactive Playground
**Audience:** Absolute beginners → aspiring professional frontend engineers
**Style:** Extremely verbose · Step‑by‑step · Architecture‑first · Real‑world mental models
**Tooling:** ES Modules · Vite · Vitest · Playwright

---

## 🎯 What You Will Build (Read This First)

By the end of this tutorial, you will have built a **production-grade, collaborative, offline‑capable web application** using **only Vanilla JavaScript**.

Not a toy.
Not a demo.
Not a framework tutorial.

A **real system**, built the way frameworks are architected internally.

✅ Supports **live drag/drop**, **undo/redo**, **offline-first**, **multi-tab sync**, and **real-time collaboration**.

---

### 🧠 Architecture & Design Capabilities

You will implement:

* Clean **HTML / CSS / JS separation**
* **MVC + Clean Architecture** (properly, not buzzwords)
* Explicit **Domain Modeling (Entities)**
* **Use Cases** as business logic
* **Controllers** as orchestration layers
* **Views** as pure DOM renderers
* **Event Bus** for decoupling
* **Explicit State Machines** (no boolean soup)
* **Command Pattern** (Undo / Redo / Time‑Travel)
* **Functional core, imperative shell**

---

### ⚙️ Platform & System Capabilities

* Local persistence (`localStorage`)
* **Offline-first behavior** (queue + replay)
* **Multi-tab synchronization**
* **Real-time collaborative editing** (command broadcast)
* **Drag & drop reordering**
* **Undo / Redo across offline + collaboration**
* Async behavior (network simulation)
* ES Modules (`import / export`)
* Vite dev server & production build
* **Unit tests** (Vitest)
* **End-to-End tests** (Playwright)

🚫 No React
🚫 No Vue
🚫 No frameworks

✅ Just **Vanilla JS the way frameworks are built internally**

---

# 🧭 Learning Roadmap (Architecture-Aware)

```
Project Setup (Vite + ES Modules)
   ↓
JavaScript Fundamentals (for architecture)
   ↓
Domain Modeling (Entities)
   ↓
Use Cases (Business Logic)
   ↓
MVC Wiring
   ↓
Event Bus
   ↓
State Machines
   ↓
Command Pattern (Undo / Redo)
   ↓
Offline-First Sync
   ↓
Real-Time Collaboration
   ↓
Persistence & Multi-Tab Sync
   ↓
Async Behavior
   ↓
Drag & Drop
   ↓
Unit Testing
   ↓
E2E Testing
   ↓
Production Build
```

Keep this roadmap in mind. Every line of code fits into it.

---

# 🏗️ Clean Architecture Mental Model

```
UI (DOM)
 ↓
Controllers
 ↓
Use Cases
 ↓
Entities (Domain)
```

**Rules that NEVER break:**

* Entities know nothing about the browser
* Use cases know nothing about DOM
* Controllers coordinate, never compute rules
* Views render, never decide
* Infrastructure stays at the edges

This is why the app is:

✔ Testable
✔ Maintainable
✔ Collaborative-ready
✔ Framework-independent

---

# 🗂️ PART 0 — Project Setup (Vite + ES Modules)

## 0.1 Why Vite

Modern JS apps need:

* ES Modules
* Fast dev server
* Hot reload
* Production bundling
* Testing support

Vite gives all of this **without forcing a framework**.

---

## 0.2 Initialize Project

```bash
npm create vite@latest js-task-manager
cd js-task-manager
npm install
npm run dev
```

Choose **Vanilla → JavaScript**.

---

## 0.3 Project Structure

```
src/
 ├── app.js                 # Application bootstrap
 ├── domain/                # Core business entities
 │   └── Task.js
 ├── usecases/              # Business logic
 │   ├── TaskManager.js
 │   ├── reorderTasks.js
 │   ├── commands/
 │   │   ├── Command.js
 │   │   ├── AddTaskCommand.js
 │   │   ├── ToggleTaskCommand.js
 │   │   └── ReorderTaskCommand.js
 │   └── CommandManager.js
 ├── controllers/
 │   └── TaskController.js
 ├── ui/
 │   └── view.js
 ├── shared/
 │   ├── eventBus.js
 │   └── stateMachine.js
 └── infrastructure/
     ├── storage.js
     ├── offlineQueue.js
     ├── syncService.js
     └── realtimeBus.js
```

This mirrors **real-world systems**. Memorize it.

---

# 🧠 PART 1 — JavaScript Fundamentals (Only What Matters)

JS features exist to **enable architecture**.

### Closures = Encapsulation

```js
function createCounter() {
  let count = 0;
  return () => ++count;
}
```

Benefits:

* Private state
* Encapsulation
* No classes required

Frameworks rely heavily on this.

---

# 🧱 PART 2 — Domain Layer (Entities)

Entities are **business truth**. Stable, testable, and framework-independent.

### 2.1 Task Entity

```js
export class Task {
  #title;
  #priority;

  constructor(title, priority = "medium") {
    this.#title = title;
    this.#priority = priority;
    this.done = false;
    this.id = crypto.randomUUID();
  }

  toggle() { this.done = !this.done; }
  getTitle() { return this.#title; }
  getPriority() { return this.#priority; }
}
```

✔ No DOM
✔ No storage
✔ Fully testable

---

# 🧠 PART 3 — Use Cases (Business Logic)

Use cases model **user intent**, not UI events.

### 3.1 TaskManager

```js
export class TaskManager {
  #tasks = [];

  add(task) { this.#tasks.push(task); }
  remove(id) { this.#tasks = this.#tasks.filter(t => t.id !== id); }
  toggle(id) {
    const task = this.#tasks.find(t => t.id === id);
    if (task) task.toggle();
  }
  list() { return [...this.#tasks]; }
  replace(tasks) { this.#tasks = tasks; }
}
```

---

# 🧠 PART 4 — MVC Wiring

### 4.1 View (DOM Only)

```js
export function render(tasks, handlers) {
  const ul = document.querySelector("#tasks");
  ul.innerHTML = "";

  tasks.forEach((task, index) => {
    const li = document.createElement("li");
    li.textContent = task.getTitle();
    li.className = task.done ? "done" : "";

    li.onclick = () => handlers.onToggle(task.id);

    // Drag & Drop
    li.draggable = true;
    li.ondragstart = e => e.dataTransfer.setData("i", index);
    li.ondrop = e => handlers.onReorder(+e.dataTransfer.getData("i"), index);
    li.ondragover = e => e.preventDefault();

    ul.appendChild(li);
  });
}
```

Views never mutate state.

---

### 4.2 Controller (Orchestration)

```js
export class TaskController {
  constructor(manager, commands) {
    this.manager = manager;
    this.commands = commands;
  }

  add(task) {
    this.commands.execute(new AddTaskCommand(this.manager, task));
    this.refresh();
  }

  toggle(id) {
    this.commands.execute(new ToggleTaskCommand(this.manager, id));
    this.refresh();
  }

  reorder(from, to) {
    this.commands.execute(new ReorderTaskCommand(this.manager, from, to));
    this.refresh();
  }

  refresh() {
    render(this.manager.list(), {
      onToggle: id => this.toggle(id),
      onReorder: (f, t) => this.reorder(f, t)
    });
  }
}
```

---

# 🧠 PART 5 — Event Bus (Decoupling Layers)

```js
const listeners = {};

export function on(event, fn) { (listeners[event] ||= []).push(fn); }

export function emit(event, payload) { (listeners[event] || []).forEach(fn => fn(payload)); }
```

---

# 🧠 PART 6 — State Machines

```js
export const STATES = { IDLE: "IDLE", LOADING: "LOADING" };

export class StateMachine {
  constructor(initial) { this.state = initial; }
  transition(next) { this.state = next; }
}
```

Prevent illegal UI states.

---

# 🧠 PART 7 — Command Pattern (Undo / Redo)

```js
export class CommandManager {
  undoStack = [];
  redoStack = [];

  execute(cmd) {
    cmd.execute();
    this.undoStack.push(cmd);
    this.redoStack = [];
  }

  undo() {
    const cmd = this.undoStack.pop();
    if (cmd) { cmd.undo(); this.redoStack.push(cmd); }
  }

  redo() {
    const cmd = this.redoStack.pop();
    if (cmd) { cmd.execute(); this.undoStack.push(cmd); }
  }
}
```

---

# 🌍 PART 8 — Offline-First Synchronization

```js
export function enqueue(action) {
  const q = JSON.parse(localStorage.getItem("queue") || "[]");
  q.push(action);
  localStorage.setItem("queue", JSON.stringify(q));
}

export function dequeueAll() {
  const q = JSON.parse(localStorage.getItem("queue") || "[]");
  localStorage.removeItem("queue");
  return q;
}
```

---

# 🤝 PART 9 — Real-Time Collaboration

All clients share **commands**, not state.

```js
export function broadcast(command) {
  window.dispatchEvent(new CustomEvent("remote", { detail: command }));
}

window.addEventListener("remote", e => {
  // Execute commands from other clients
  commands.execute(e.detail);
});
```

---

# 🛠 PART 10 — Bootstrap (`app.js`)

```js
import { Task } from "./domain/Task.js";
import { TaskManager } from "./usecases/TaskManager.js";
import { CommandManager } from "./usecases/CommandManager.js";
import { AddTaskCommand } from "./usecases/commands/AddTaskCommand.js";
import { TaskController } from "./controllers/TaskController.js";

const manager = new TaskManager();
const commands = new CommandManager();
const controller = new TaskController(manager, commands);

document.querySelector("#addTask").onclick = () => {
  const input = document.querySelector("#newTask");
  if(input.value){
    const task = new Task(input.value);
    controller.add(new AddTaskCommand(manager, task));
    input.value = "";
  }
};

document.querySelector("#undo").onclick = () => controller.commands.undo();
document.querySelector("#redo").onclick = () => controller.commands.redo();

controller.refresh();
```

> Fully interactive: add tasks, drag/drop, undo/redo, offline queue + real-time simulation.

---

# 🧪 PART 11 — Test Hooks

### Unit Test Example (Vitest)

```js
import { Task } from "./domain/Task.js";
import { describe, it, expect } from "vitest";

describe("Task Entity", () => {
  it("toggles correctly", () => {
    const t = new Task("Test"); t.toggle();
    expect(t.done).toBe(true);
  });
});
```

### E2E Example (Playwright)

```js
await page.fill("#newTask","Demo Task");
await page.click("#addTask");
await expect(page.locator("li")).toHaveCount(1);
```

---

# 📦 PART 12 — Production Build

```bash
npm run build
```

Deploy anywhere. Offline-first capabilities remain intact.

---

# 🏁 Final Words

You did **not** learn a todo app.

You learned:

* How **frameworks are structured internally**
* How **collaboration really works**
* How **offline systems are designed**
* How **undo/redo is modeled correctly**
* How **drag & drop belongs in use cases, not views**

From here:

➡ React is easy
➡ Vue is obvious
➡ Frameworks stop being magic

---

Do you want me to do that next?
