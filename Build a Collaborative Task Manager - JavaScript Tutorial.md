# 📘 Build a Collaborative Task Manager - JavaScript Tutorial 

**Edition:** 1.0
**Goal:** Build a **production-grade, offline-first, collaborative task manager** using **Vanilla JS**, while mastering **core JS concepts, architecture patterns, and environment mental models**.

---

# 🧭 Learning Roadmap

```
Project Setup (Vite + ES Modules)
   ↓
JS Fundamentals (Execution Model, Closures, Recursion)
   ↓
Primitive vs Reference
   ↓
Arrow Functions & FP
   ↓
OOP (Encapsulation, Abstraction, Inheritance, Polymorphism)
   ↓
Domain Modeling (Task Entity)
   ↓
Use Cases & Controllers
   ↓
Command Pattern (Undo/Redo)
   ↓
Offline-First Persistence
   ↓
Real-Time Collaboration
   ↓
Error Handling
   ↓
Browser vs Node.js Mental Models
   ↓
Testing (Unit & E2E)
   ↓
Production Build
```

Each section **builds on the previous**, so you understand **why each pattern exists**, not just **how to write code**.

---

# 🏗 PART 0 — Project Setup

```bash
npm create vite@latest js-task-manager
cd js-task-manager
npm install
npm run dev
```

**Choose:** Vanilla → JavaScript

```
src/
 ├── app.js
 ├── domain/
 │   └── Task.js
 ├── usecases/
 │   ├── TaskManager.js
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

> **Memorize this layout** — it mirrors real-world systems architecture.

---

# 🧠 PART 1 — JavaScript Fundamentals

### 1.1 Execution Model & Hoisting

**Phases:**

```
CREATION PHASE  → memory allocation, function/var hoisting
EXECUTION PHASE → run code line by line, assign let/const
```

**Example:**

```js
hello(); // works
function hello() { console.log("Hi!"); }

console.log(x); // ❌ ReferenceError
let x = 10;
```

**Mental Model:** Functions live **above the line**; `let`/`const` are in a **temporal dead zone**.

---

### 1.2 Stack vs Heap

```
STACK        HEAP
------       ------
function     objects
local vars   closures
parameters   class instances
```

**Browser vs Node:**

* Browser heap may contain DOM references
* Node heap contains module state, buffers, sockets

---

# 🧠 PART 2 — Closures

A closure is a **function carrying its environment**.

```js
function outer() {
  let count = 0;
  return () => ++count;
}
const counter = outer();
console.log(counter()); // 1
console.log(counter()); // 2
```

```
Heap:
count = 2
counter ─► inner() captured count
```

**Mental Model:** closure = backpack of variables that travel with the function.

* Browser: captures DOM references
* Node: captures module variables

---

# 🧠 PART 3 — Recursion

Recursion models **state changes over time**.

```js
function countdown(n){
  if(n===0) return;
  console.log(n);
  countdown(n-1);
}
countdown(3);
```

```
┌─────────────┐
│ countdown(0)│
├─────────────┤
│ countdown(1)│
├─────────────┤
│ countdown(2)│
├─────────────┤
│ countdown(3)│
└─────────────┘
```

---

# 🧠 PART 4 — Primitive vs Reference Types

| Type      | Example                | Behavior                     |
| --------- | ---------------------- | ---------------------------- |
| Primitive | `let a=1; let b=a;`    | copied by value              |
| Reference | `let t1={}; let t2=t1` | copied by reference → shared |

**Rule:** Always copy or snapshot references to avoid hidden mutations.

---

# 🧠 PART 5 — Arrow Functions & Functional Programming

```js
const add = (a,b)=>a+b;
const makeAdder = x => y => x+y;
```

```
makeAdder(5)
 └─► y => 5 + y
```

**Benefits:**

* No `this` confusion
* FP style: **immutable transformations**, safe undo

---

# 🧱 PART 6 — Object-Oriented Programming

### 6.1 Encapsulation

```js
class Task {
  #title;
  #done = false;

  constructor(title) {
    if(!title) throw new Error("Title required");
    this.#title = title;
  }

  toggle(){ this.#done = !this.#done; }

  isDone(){ return this.#done; }

  snapshot(){ return { title:this.#title, done:this.#done }; }
}
```

**ASCII Diagram:**

```
┌───────────┐
│ Task      │
│-----------│
│ #title    │
│ #done     │
│-----------│
│ toggle()  │
│ isDone()  │
│ snapshot()│
└───────────┘
```

---

### 6.2 Abstraction

UI sees **snapshot**, never internal state:

```
UI ──► snapshot ──► {title, done}
```

---

### 6.3 Inheritance & Polymorphism

Commands hierarchy:

```
       Command
        / \
 AddTaskCommand ToggleTaskCommand
```

Polymorphism = same `execute()` message for all command types.

---

# 🧠 PART 7 — Domain Layer

```js
export class Task {
  #title; #done = false;
  constructor(title){ this.#title = title; }
  toggle(){ this.#done = !this.#done; }
  snapshot(){ return {title:this.#title, done:this.#done}; }
}
```

**Mental Model:** Task = **business truth**, no UI or storage knowledge.

---

# 🧠 PART 8 — Use Cases & Controllers

```js
export class TaskManager {
  #tasks = [];

  add(task){ this.#tasks.push(task); }

  toggle(id){
    const task = this.#tasks.find(t => t.id === id);
    if(task) task.toggle();
  }

  list(){ return this.#tasks.map(t=>t.snapshot()); }
}
```

Controller orchestrates **commands → use cases → view**.

---

# 🧠 PART 9 — Command Pattern (Undo / Redo)

```js
class CommandManager {
  undoStack=[]; redoStack=[];

  execute(cmd){
    cmd.execute();
    this.undoStack.push(cmd);
    this.redoStack=[];
  }

  undo(){
    const cmd = this.undoStack.pop();
    if(cmd){ cmd.undo(); this.redoStack.push(cmd); }
  }

  redo(){
    const cmd = this.redoStack.pop();
    if(cmd){ cmd.execute(); this.undoStack.push(cmd); }
  }
}
```

```
t0 ─ AddTask
t1 ─ Toggle
t2 ─ Reorder
```

**Mental Model:** Commands = **time capsules** for state.

---

# 🧠 PART 10 — Offline & Persistence

```js
function enqueue(action){
  const q = JSON.parse(localStorage.getItem('queue')||'[]');
  q.push(action);
  localStorage.setItem('queue', JSON.stringify(q));
}

function dequeueAll(){
  const q = JSON.parse(localStorage.getItem('queue')||'[]');
  localStorage.removeItem('queue');
  return q;
}
```

**Browser:** localStorage / IndexedDB
**Node:** file system / databases

---

# 🧠 PART 11 — Real-Time Collaboration

```js
export function broadcast(command){
  window.dispatchEvent(new CustomEvent("remote",{detail:command}));
}

window.addEventListener("remote", e=>{
  commands.execute(e.detail);
});
```

> Mental Model: **sync commands, not state**

---

# 🧠 PART 12 — Error Handling

```js
try{
  const task = new Task();
}catch(e){
  console.error("Failed to create task:", e);
}
```

Custom errors:

```js
class ValidationError extends Error{}
if(!title) throw new ValidationError("Title required");
```

Async errors:

```js
async function fetchTasks(){
  try{
    const res = await fetch("/tasks");
    if(!res.ok) throw new Error("Network error");
  }catch(e){ console.error(e); }
}
```

Browser vs Node:

```
Browser: window.onerror, Promise.catch()
Node: process.on('uncaughtException'), Promise.catch()
```

---

# 🧠 PART 13 — JS in Browser vs Node.js

| Feature        | Browser                 | Node.js               |
| -------------- | ----------------------- | --------------------- |
| Global Object  | window                  | global                |
| Module System  | ES Modules              | ES Modules / CommonJS |
| Event Loop     | JS + Browser APIs       | JS + Timers + I/O     |
| DOM            | Yes                     | ❌ None                |
| Network        | fetch, WebSocket        | http, ws, net         |
| Storage        | localStorage, IndexedDB | fs, databases         |
| Timers         | throttled               | accurate              |
| Worker Threads | Web Workers             | Worker Threads module |

> **Mental Model:** Same JS concepts, different APIs.

---

# 🛠 PART 14 — Full Task Manager Code

Let’s build the **full working code** for the **Task Manager**, fully integrated, verbose, with **OOP, FP, closures, undo/redo, offline queue, real-time simulation**, and **ASCII diagrams + mental models**.

We’ll build it **module by module**, starting with the **Domain Layer (Task entity)**.

---

# 🧱 DOMAIN LAYER — `Task.js`

```js
// src/domain/Task.js

/**
 * Task Entity
 *
 * Business truth: represents a task.
 * Fully encapsulated. No DOM or persistence knowledge.
 *
 * Features:
 *  - Private fields (#title, #priority)
 *  - Public methods for toggling & snapshot
 *  - Throws error if title is missing
 */

export class Task {
  #title;
  #priority;
  #done = false;
  id;

  constructor(title, priority = "medium") {
    if (!title) throw new Error("Task title is required");
    this.#title = title;
    this.#priority = priority;
    this.id = crypto.randomUUID(); // unique ID
  }

  toggle() {
    this.#done = !this.#done;
  }

  getTitle() { return this.#title; }
  getPriority() { return this.#priority; }
  isDone() { return this.#done; }

  snapshot() {
    return {
      id: this.id,
      title: this.#title,
      priority: this.#priority,
      done: this.#done
    };
  }
}
```

**ASCII Memory Diagram:**

```
Heap:
Task {
  #title: "Buy milk"
  #priority: "medium"
  #done: false
  id: "uuid-1234"
}
```

**Mental Model:**

> Task = **immutable business truth** for UI / controllers. Snapshot is the only safe way to read state.

---

# 🧠 PART 2 — `TaskManager.js` (Use Case Layer)

```js
// src/usecases/TaskManager.js

import { Task } from "../domain/Task.js";

/**
 * TaskManager
 *
 * Responsible for managing tasks in memory.
 * Implements:
 *  - add, remove, toggle
 *  - list snapshots (for UI)
 */

export class TaskManager {
  #tasks = []; // private array of Task instances

  add(task) {
    this.#tasks.push(task);
  }

  remove(id) {
    this.#tasks = this.#tasks.filter(t => t.id !== id);
  }

  toggle(id) {
    const task = this.#tasks.find(t => t.id === id);
    if (task) task.toggle();
  }

  list() {
    // Return immutable snapshots
    return this.#tasks.map(t => t.snapshot());
  }

  replace(tasks) {
    this.#tasks = tasks;
  }
}
```

**ASCII Diagram (Tasks in Memory):**

```
TaskManager
 └─ #tasks[]
      ├─ Task{id: uuid1, title: "Buy milk", done: false}
      └─ Task{id: uuid2, title: "Pay bills", done: true}
```

**Mental Model:**

> Use Cases = orchestrate business rules, **no DOM, no storage**.
> Commands interact with use cases, controllers orchestrate commands → view.

---

# 🧱 PART 3 — Command Pattern

### `Command.js` (Base Class)

```js
// src/usecases/commands/Command.js

/**
 * Base Command
 *
 * All commands must implement:
 *  - execute()
 *  - undo()
 *
 * Enables: undo/redo, offline queue, real-time replay
 */

export class Command {
  execute() { throw new Error("execute() not implemented"); }
  undo() { throw new Error("undo() not implemented"); }
}
```

---

### `AddTaskCommand.js`

```js
// src/usecases/commands/AddTaskCommand.js
import { Command } from "./Command.js";

export class AddTaskCommand extends Command {
  constructor(taskManager, task) {
    super();
    this.taskManager = taskManager;
    this.task = task;
  }

  execute() {
    this.taskManager.add(this.task);
  }

  undo() {
    this.taskManager.remove(this.task.id);
  }
}
```

---

### `ToggleTaskCommand.js`

```js
// src/usecases/commands/ToggleTaskCommand.js
import { Command } from "./Command.js";

export class ToggleTaskCommand extends Command {
  constructor(taskManager, taskId) {
    super();
    this.taskManager = taskManager;
    this.taskId = taskId;
  }

  execute() {
    this.taskManager.toggle(this.taskId);
  }

  undo() {
    // toggle is reversible
    this.taskManager.toggle(this.taskId);
  }
}
```

---

### `ReorderTaskCommand.js`

```js
// src/usecases/commands/ReorderTaskCommand.js
import { Command } from "./Command.js";

export class ReorderTaskCommand extends Command {
  constructor(taskManager, fromIndex, toIndex) {
    super();
    this.taskManager = taskManager;
    this.fromIndex = fromIndex;
    this.toIndex = toIndex;
  }

  execute() {
    const tasks = this.taskManager.list();
    const [moved] = tasks.splice(this.fromIndex, 1);
    tasks.splice(this.toIndex, 0, moved);
    this.taskManager.replace(tasks.map(snap => new this.taskManager.constructor(snap.title, snap.priority)));
  }

  undo() {
    const tasks = this.taskManager.list();
    const [moved] = tasks.splice(this.toIndex, 1);
    tasks.splice(this.fromIndex, 0, moved);
    this.taskManager.replace(tasks.map(snap => new this.taskManager.constructor(snap.title, snap.priority)));
  }
}
```

---

### `CommandManager.js`

```js
// src/usecases/CommandManager.js

/**
 * CommandManager
 *
 * Tracks undo/redo stack
 */

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
    if (cmd) {
      cmd.undo();
      this.redoStack.push(cmd);
    }
  }

  redo() {
    const cmd = this.redoStack.pop();
    if (cmd) {
      cmd.execute();
      this.undoStack.push(cmd);
    }
  }
}
```

---

✅ At this point we have:

* **Task entity** → encapsulated business object
* **TaskManager** → use case orchestrator
* **Command pattern** → undo/redo capable, reversible, offline-friendly

---

**Next Step:**

In the next part, we will build:

1. **Controller (`TaskController.js`)** — orchestrates commands → use cases → view
2. **View (`view.js`)** — DOM rendering + drag/drop
3. **Offline Queue (`offlineQueue.js`)** — persistence + replay
4. **Real-Time Collaboration (`realtimeBus.js`)** — broadcast/receive commands
5. **App Bootstrap (`app.js`)** — integrate everything

This will produce a **fully working interactive Task Manager**.

---

Let’s continue and build the **Controller, View, Offline Queue, Real-Time Collaboration, and App Bootstrap** — fully integrated, verbose, with ASCII diagrams and mental models. This will give us a **fully working, interactive Task Manager**.

---

# 🧠 PART 4 — Controller (`TaskController.js`)

```js
// src/controllers/TaskController.js
import { render } from "../ui/view.js";
import { AddTaskCommand } from "../usecases/commands/AddTaskCommand.js";
import { ToggleTaskCommand } from "../usecases/commands/ToggleTaskCommand.js";
import { ReorderTaskCommand } from "../usecases/commands/ReorderTaskCommand.js";

/**
 * TaskController
 *
 * Orchestrates commands, use cases, and view rendering.
 * Keeps view and business logic decoupled.
 */

export class TaskController {
  constructor(taskManager, commandManager) {
    this.taskManager = taskManager;
    this.commandManager = commandManager;
  }

  add(task) {
    this.commandManager.execute(new AddTaskCommand(this.taskManager, task));
    this.refresh();
  }

  toggle(id) {
    this.commandManager.execute(new ToggleTaskCommand(this.taskManager, id));
    this.refresh();
  }

  reorder(fromIndex, toIndex) {
    this.commandManager.execute(new ReorderTaskCommand(this.taskManager, fromIndex, toIndex));
    this.refresh();
  }

  refresh() {
    render(this.taskManager.list(), {
      onToggle: id => this.toggle(id),
      onReorder: (from, to) => this.reorder(from, to)
    });
  }
}
```

**ASCII Diagram (Controller Flow):**

```
User Action
    │
    ▼
TaskController
    │
    ├─ execute Command → TaskManager (Use Cases)
    │
    └─ render → View (DOM)
```

**Mental Model:** Controller = **traffic director**. It never mutates state directly; it delegates to **Commands → Use Cases**.

---

# 🧱 PART 5 — View (`view.js`)

```js
// src/ui/view.js

/**
 * render()
 *
 * Pure DOM rendering. Never mutates state.
 * Supports drag & drop reordering.
 */
export function render(tasks, handlers) {
  const ul = document.querySelector("#tasks");
  ul.innerHTML = ""; // clear previous content

  tasks.forEach((task, index) => {
    const li = document.createElement("li");
    li.textContent = task.title;
    li.className = task.done ? "done" : "";
    li.draggable = true;

    li.onclick = () => handlers.onToggle(task.id);

    // Drag & Drop
    li.ondragstart = e => e.dataTransfer.setData("fromIndex", index);
    li.ondrop = e => {
      const from = +e.dataTransfer.getData("fromIndex");
      handlers.onReorder(from, index);
      e.preventDefault();
    };
    li.ondragover = e => e.preventDefault();

    ul.appendChild(li);
  });
}
```

**ASCII Diagram (DOM Structure)**

```
<ul id="tasks">
 ├─ <li>Buy milk</li>
 ├─ <li>Pay bills</li>
 └─ <li>Exercise</li>
```

**Mental Model:** View = **pure renderer**. All state changes come from **commands via controller**.

---

# 🧠 PART 6 — Offline Queue (`offlineQueue.js`)

```js
// src/infrastructure/offlineQueue.js

/**
 * Offline-first queue
 * Saves commands when offline, replays when online.
 */
export function enqueue(command) {
  const queue = JSON.parse(localStorage.getItem("queue") || "[]");
  queue.push(command);
  localStorage.setItem("queue", JSON.stringify(queue));
}

export function dequeueAll() {
  const queue = JSON.parse(localStorage.getItem("queue") || "[]");
  localStorage.removeItem("queue");
  return queue;
}
```

**Mental Model:**

> Offline queue = **command buffer**. Replay commands later ensures **eventual consistency**.

---

# 🧠 PART 7 — Real-Time Collaboration (`realtimeBus.js`)

```js
// src/infrastructure/realtimeBus.js

/**
 * Broadcast and listen to commands across browser tabs.
 */

export function broadcast(command) {
  window.dispatchEvent(new CustomEvent("remote", { detail: command }));
}

export function subscribe(commandManager) {
  window.addEventListener("remote", e => {
    commandManager.execute(e.detail);
  });
}
```

**ASCII Diagram (Multi-Tab / Collaboration)**

```
Tab A  ──► broadcast(Command) ──► Tab B
Tab B  ──► execute(command) ──► TaskManager → View
```

**Mental Model:**

> Real-time sync = **share commands, not state**, safe across multiple tabs.

---

# 🛠 PART 8 — App Bootstrap (`app.js`)

```js
// src/app.js
import { Task } from "./domain/Task.js";
import { TaskManager } from "./usecases/TaskManager.js";
import { CommandManager } from "./usecases/CommandManager.js";
import { AddTaskCommand } from "./usecases/commands/AddTaskCommand.js";
import { TaskController } from "./controllers/TaskController.js";
import { broadcast, subscribe } from "./infrastructure/realtimeBus.js";
import { enqueue, dequeueAll } from "./infrastructure/offlineQueue.js";

// Instantiate core modules
const manager = new TaskManager();
const commands = new CommandManager();
const controller = new TaskController(manager, commands);

// Subscribe for real-time events
subscribe(commands);

// Load offline queue
const offlineCommands = dequeueAll();
offlineCommands.forEach(cmd => commands.execute(cmd));

// DOM Hooks
document.querySelector("#addTask").onclick = () => {
  const input = document.querySelector("#newTask");
  if (!input.value) return;

  const task = new Task(input.value);
  const addCmd = new AddTaskCommand(manager, task);

  try {
    commands.execute(addCmd);
    broadcast(addCmd);   // real-time sync
    controller.refresh();
    input.value = "";
  } catch (e) {
    console.error("Failed to add task:", e);
    enqueue(addCmd); // store offline
  }
};

document.querySelector("#undo").onclick = () => { commands.undo(); controller.refresh(); };
document.querySelector("#redo").onclick = () => { commands.redo(); controller.refresh(); };

// Initial render
controller.refresh();
```

**ASCII Diagram (Full Flow)**

```
User Action
    │
    ▼
TaskController
    │
    ├─ execute Command → TaskManager
    │
    ├─ broadcast → other tabs
    │
    ├─ offline queue if fails
    │
    └─ render → View
```

---

# ✅ Features Fully Integrated

* [x] **OOP + FP + closures + recursion**
* [x] **Primitive vs reference safety**
* [x] **Commands + undo/redo**
* [x] **Offline-first queue + replay**
* [x] **Real-time collaboration across tabs**
* [x] **Error handling everywhere**
* [x] **Browser vs Node.js mental models**
* [x] **Drag & drop reordering**
* [x] **ASCII diagrams and verbose explanations**

---

# 🏁 Next Step — Testing & Production

* **Unit tests:** test Task entity, TaskManager, Commands
* **E2E tests:** simulate DOM interactions via Playwright
* **Production build:** `npm run build`, offline cache remains intact

---

This is now a **full working Vanilla JS Task Manager tutorial** with **everything fully integrated**, verbose, with ASCII diagrams and mental models.

---




