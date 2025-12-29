# 📘 JavaScript Architecture & Design Patterns Tutorial (Enhanced Masterclass)

**Goal:** Learn to structure scalable, maintainable, and testable JavaScript applications using **modern architectural principles**, **classic & advanced design patterns**, and **mental models for reasoning about JS**.

**Edition:** 1.0 

---

# 🧭 Table of Contents

1. Introduction & Mental Models
2. JavaScript Application Architecture

   * Layered Architecture
   * Component-Based Architecture
   * Modular / Micro Frontends
3. Core Design Patterns

   * Creational Patterns: Factory, Singleton, Builder
   * Structural Patterns: Module/IIFE, Facade, Decorator, Proxy
   * Behavioral Patterns: Observer, Command, Strategy, State, Mediator
4. Advanced Patterns for JS Apps

   * Event Bus
   * Flux / Redux Pattern
   * MVC / MVVM / MVP
5. Architecture Mental Models

   * Stack / Heap / Closures
   * Async Flow / Event Loop
   * State Management & Immutability
6. Practical Example: Task Manager

   * Layered Implementation
   * Design Patterns Applied
   * Offline-First + Undo/Redo + Multi-Tab Sync
7. Super Master Blueprint — Full Integrated Architecture
8. Testing, Maintainability & Scaling
9. Conclusion & Key Mental Models

---

# 1️⃣ Introduction & Mental Models

JavaScript applications can become **complex quickly** if you don’t reason in terms of **layers, responsibilities, and patterns**. Think **like an architect**:

* **Layers:** Presentation → Controller → Domain → Data
* **Commands:** Encapsulated actions that are reversible & decoupled
* **State:** Immutable vs mutable, shared vs local
* **Events:** Broadcast → Subscribers → Predictable flow

**ASCII Diagram – Conceptual Flow**

```
User Interaction
      │
      ▼
Controller / Dispatcher
      │
      ├─ Executes Command → Domain Layer
      ├─ Updates State
      └─ Broadcasts Event → Subscribers
      │
      ▼
View Layer (DOM / React / Vanilla)
```

**Rationale:**
This mental model helps reason about **side effects**, **decoupling**, and **predictability**. Every action should have a clear **entry point → effect → update → render**.

---

# 2️⃣ JavaScript Application Architecture

## 2.1 Layered Architecture

**Principle:** Separate responsibilities by **layers** to make apps **maintainable and testable**.

```
┌───────────────┐
│  Presentation │  ← Handles DOM, React components, UI rendering
└───────┬───────┘
        │
┌───────▼───────┐
│  Controller   │  ← Executes commands, updates domain, orchestrates flows
└───────┬───────┘
        │
┌───────▼───────┐
│   Domain /    │  ← Core business logic, entities, validation, rules
│  Use Cases    │
└───────┬───────┘
        │
┌───────▼───────┐
│  Data / APIs  │  ← LocalStorage, IndexedDB, REST/GraphQL, offline queue
└───────────────┘
```

**Key Benefits:**

* **Single Responsibility:** Each layer has a distinct role.
* **Testability:** Mock lower layers for unit testing.
* **Reusability:** Domain logic is framework-agnostic.

---

## 2.2 Component-Based Architecture

Components encapsulate **state + logic + UI**:

```
App
 ├─ HeaderComponent
 ├─ TaskListComponent
 │    ├─ TaskItemComponent
 │    └─ AddTaskForm
 └─ FooterComponent
```

**Mental Model:** Components = black boxes with **controlled inputs/outputs**. Promotes **composition over inheritance**.

---

## 2.3 Modular / Micro Frontends

* ES Modules (`import/export`) or IIFE modules for **code isolation**
* Applications can split into **small independently deployable units**

```js
// taskManager.js
export class TaskManager {...}

// ui.js
import { TaskManager } from './taskManager.js';
```

**Benefit:** Each module is testable, maintainable, and replaceable.

---

# 3️⃣ Core Design Patterns

## 3.1 Creational Patterns

### Factory

```js
class TaskFactory {
  static create(title){ return new Task(title); }
}
const t = TaskFactory.create("Buy Milk");
```

**Mental Model:** Centralizes object creation, hides complexity.

---

### Singleton

```js
class Config {
  static instance;
  constructor(data){
    if(Config.instance) return Config.instance;
    this.data=data; 
    Config.instance=this;
  }
}
```

**Use Case:** Global config, shared state, API instances.

---

### Builder

```js
class TaskBuilder {
  constructor(){ this.task={}; }
  setTitle(title){ this.task.title=title; return this; }
  setDone(done){ this.task.done=done; return this; }
  build(){ return new Task(this.task.title); }
}
```

**Mental Model:** Stepwise object creation, avoids complex constructors.

---

## 3.2 Structural Patterns

### Module / IIFE

```js
const TaskModule = (function(){
  const tasks = [];
  return {
    add(task){ tasks.push(task); },
    list(){ return [...tasks]; }
  }
})();
```

### Facade

```js
class APIFacade {
  static fetchTasks(){ return fetch('/tasks').then(r=>r.json()); }
  static saveTask(t){ return fetch('/tasks',{method:'POST',body:JSON.stringify(t)}); }
}
```

### Decorator

```js
function logger(fn){
  return (...args)=>{
    console.log('Calling',fn.name,args);
    return fn(...args);
  }
}
```

### Proxy

```js
const taskProxy = new Proxy(task, {
  set(target,key,value){ console.log(`Setting ${key}`); target[key]=value; return true; }
});
```

---

## 3.3 Behavioral Patterns

### Observer / Pub-Sub

```
Publisher → Event → Subscriber
```

```js
class EventBus {
  constructor(){ this.events={}; }
  subscribe(event, fn){ (this.events[event]??=[]).push(fn); }
  publish(event, data){ (this.events[event]||[]).forEach(fn=>fn(data)); }
}
```

### Command

```js
class CommandManager {
  undoStack=[]; redoStack=[];
  execute(cmd){ cmd.execute(); this.undoStack.push(cmd); this.redoStack=[]; }
  undo(){ const cmd=this.undoStack.pop()?.undo(); }
}
```

### Strategy

```js
class SortStrategy {
  constructor(strategy){ this.strategy=strategy; }
  sort(array){ return this.strategy(array); }
}
```

### State

```js
class TaskState {
  constructor(task){ this.task=task; }
  setState(state){ this.task.state=state; }
}
```

### Mediator

```js
class Mediator {
  constructor(){ this.components=[]; }
  register(c){ this.components.push(c); }
  broadcast(sender,msg){ this.components.filter(c=>c!==sender).forEach(c=>c.receive(msg)); }
}
```

---

# 4️⃣ Advanced Patterns for JS Apps

### Event Bus

* Central hub for events → decouples components
* Supports multi-tab & offline-first patterns

```
Component A → Event Bus → Component B / C
```

### Flux / Redux

```
Actions → Dispatcher → Store → View
```

* Immutable state
* Single source of truth
* Predictable updates

### MVC / MVVM / MVP

```
MVC: View ↔ Controller ↔ Model
MVVM: View ↔ ViewModel ↔ Model
MVP: View ↔ Presenter ↔ Model
```

**Mental Model:** Each variant separates responsibilities differently.

---

# 5️⃣ Architecture Mental Models

* **Stack / Heap / Closures:** Understand memory flow, persistent objects, and environment capture
* **Async / Event Loop:** Promises, async/await, callbacks
* **State Management:** Immutable vs mutable, snapshot vs live reference
* **Commands & Events:** Reversible and decoupled actions → predictable flows

---

# 6️⃣ Practical Example: Task Manager

### Layered Implementation

```
┌───────────────┐
│ View / UI     │ TaskList, Forms, DOM
└───────┬───────┘
        │
┌───────▼───────┐
│ Controller    │ CommandManager, EventBus
└───────┬───────┘
        │
┌───────▼───────┐
│ Domain Layer  │ Task, TaskManager, Factories
└───────┬───────┘
        │
┌───────▼───────┐
│ Data Layer    │ LocalStorage / API, Offline Queue
└───────────────┘
```

### Patterns Applied

* **Singleton:** Config, API
* **Factory:** Task creation
* **Command:** Undo/Redo, offline replay
* **Observer:** EventBus, multi-tab sync
* **Proxy:** Validation / access control

---

# 7️⃣ 🏗️ Super Master Blueprint — Full Integrated JS Architecture

```
                                   USER INTERACTION
                                          │
                                          ▼
                                ┌─────────────────┐
                                │      View / UI  │ DOM / React / Components
                                └────────┬────────┘
                                         │
                      ┌──────────────────┼───────────────────┐
                      │                  │                   │
                      ▼                  ▼                   ▼
             ┌─────────────┐     ┌─────────────┐     ┌───────────────┐
             │  Event Bus  │     │ Controller  │     │  Mediator     │
             │ (Observer)  │     │  / Dispatcher│    │ (Component Msg│
             └─────┬───────┘     └──────┬──────┘     └──────┬────────┘
                   │                    │                  │
       ┌───────────▼───────────┐        │                  │
       │     Subscribers        │        │                  │
       │  Components / Handlers │        │                  │
       └───────────┬───────────┘        │                  │
                   │                    │                  │
                   ▼                    ▼                  ▼
           ┌─────────────┐       ┌──────────────┐    ┌───────────────┐
           │  Command    │       │ Strategy /   │    │ State Pattern │
           │  Pattern    │       │ Validation   │    │ Task States   │
           └─────┬───────┘       └──────┬───────┘    └──────┬────────┘
                 │                      │                  │
                 ▼                      ▼                  ▼
           ┌─────────────┐        ┌─────────────┐     ┌───────────────┐
           │  Domain     │        │ Factory     │     │ Singleton     │
           │  Layer      │        │ Task / Obj  │     │ Config / API  │
           │ TaskManager │        └─────────────┘     └───────────────┘
           └─────┬───────┘
                 │
      ┌──────────▼──────────┐
      │     Data Layer      │
      │ LocalStorage / API  │
      │ Offline Queue       │
      └──────────┬──────────┘
                 │
                 ▼
         ┌───────────────┐
         │   Undo / Redo │
         │   CommandMgr  │
         └───────────────┘
                 │
                 ▼
           ┌─────────────┐
           │ Stack / Heap│
           │ Closures    │
           │ Async Flow  │
           └─────────────┘
                 │
                 ▼
           ┌─────────────┐
           │ Multi-Tab / │
           │ Real-Time    │
           │ Sync / WS    │
           └─────────────┘
```

**Expanded Rationale:**

* **Decoupled layers:** Easy maintenance, unit testing
* **Command + Observer:** Predictable side-effects, undo/redo
* **Strategy / State:** Encapsulated business logic & validation
* **Factory / Singleton:** Controlled object creation, shared configs
* **Stack / Heap / Closures / Async:** Understand memory & runtime behavior
* **Offline Queue + Multi-Tab Sync:** Resilient, collaborative apps

---

# 8️⃣ Testing, Maintainability & Scaling

* **Unit Testing:** Test each layer in isolation
* **Integration Testing:** Commands + EventBus + Domain
* **End-to-End Testing:** UI → Controller → Domain → Data
* **Scalability:** Modular / componentized code, micro frontends
* **Maintainability:** Encapsulation, clear patterns, predictable flows

---

# 9️⃣ Conclusion & Key Mental Models

* **Layered & Modular architecture** → maintainable, testable
* **Command & Observer** → decoupled, reversible actions
* **State patterns** → predictable behavior
* **Event-driven design** → asynchronous, scalable, multi-tab ready
* **Memory awareness** → closures, stack/heap, async callbacks
* **Factory / Singleton** → controlled, reusable object creation

This forms a **complete reference for building production-grade JS applications** using **architecture principles, design patterns, and mental models**.

---

# 🟢 Addendum: Kanban Playground — JS Architecture in Action

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Kanban Board Playground — Advanced JS Architecture</title>
<style>
/* ================= Global Styles ================= */
body { font-family: Arial, sans-serif; background: #f0f0f0; margin: 0; padding: 0; }
h1,h2 { text-align:center; margin:5px 0; }
button { margin:5px; padding:5px 10px; cursor:pointer; }

/* ================= Board & Columns ================= */
.board { display:flex; justify-content:center; gap:10px; margin:20px; }
.column { width:220px; background:#e0e7ff; padding:10px; border-radius:5px; min-height:300px; }
.column h3 { text-align:center; margin-top:0; }
.card { background:#fff; padding:8px; margin:5px 0; border-radius:3px; cursor:grab; border-left:5px solid #3b82f6; }

/* ================= Layer Color Codes ================= */
.layer-view { background:#d0f0fd; }         /* Light Blue */
.layer-controller { background:#d4edda; }   /* Light Green */
.layer-domain { background:#fff4e5; }       /* Light Orange */
.layer-data { background:#e2d5ff; }         /* Lavender */

/* ================= Logs Panel ================= */
#logs { height:150px; overflow-y:auto; background:#222; color:#eee; font-size:12px; padding:5px; margin:10px; border-radius:5px; }

/* ================= Annotations ================= */
.annotation { font-size:12px; color:#444; margin:5px 0; }
</style>
</head>
<body>

<h1>Advanced Kanban Playground</h1>
<h2>JS Architecture, Patterns & Multi-Tab Sync</h2>

<!-- ================= View Layer ================= -->
<div class="board layer-view" id="board">
  <div class="column" id="todo-column" data-status="todo">
    <h3>To Do</h3>
  </div>
  <div class="column" id="inprogress-column" data-status="inprogress">
    <h3>In Progress</h3>
  </div>
  <div class="column" id="done-column" data-status="done">
    <h3>Done</h3>
  </div>
</div>

<!-- ================= Control Buttons ================= -->
<div style="text-align:center;">
  <button id="add-task-btn">Add Task</button>
  <button id="undo-btn">Undo</button>
  <button id="redo-btn">Redo</button>
  <button id="toggle-offline-btn">Toggle Offline</button>
</div>

<!-- ================= Event Flow Logs ================= -->
<div id="logs"></div>

<script>
/* ===================================================
   Layer: Data Layer
   Responsibilities:
     - Store tasks persistently
     - Simulate offline queue
     - Synchronize between multiple tabs
   Patterns: Singleton, Facade
   Mental Model: Single source of truth for tasks
=================================================== */
class DataStore {
  constructor() {
    // Singleton pattern ensures only one instance
    if (DataStore.instance) return DataStore.instance;

    // Load existing tasks or start empty
    this.tasks = JSON.parse(localStorage.getItem('kanbanTasks') || '[]');

    // Queue for commands while offline
    this.offlineQueue = [];

    // Online/offline simulation
    this.online = true;

    DataStore.instance = this;

    // Multi-tab synchronization: listen for localStorage updates
    window.addEventListener('storage', e => {
      if (e.key === 'kanbanTasks') {
        this.tasks = JSON.parse(e.newValue || '[]');
        eventBus.publish('tasksUpdated', this.tasks);  // Observer pattern
        logEvent("DataLayer: Synced tasks from another tab");
      }
    });
  }

  /* Save a new task */
  saveTask(task) {
    if (this.online) {
      this.tasks.push(task);
      localStorage.setItem('kanbanTasks', JSON.stringify(this.tasks));
      this.log(`Saved task "${task.title}"`);
    } else {
      this.offlineQueue.push({ action: 'add', task });
      this.log(`Offline, queued task "${task.title}"`);
    }
  }

  /* Update task status (column move) */
  updateTaskStatus(taskId, status) {
    const task = this.tasks.find(t => t.id === taskId);
    if (task) {
      if (this.online) {
        task.status = status;
        localStorage.setItem('kanbanTasks', JSON.stringify(this.tasks));
        this.log(`Updated task "${task.title}" to "${status}"`);
      } else {
        this.offlineQueue.push({ action: 'update', taskId, status });
        this.log(`Offline, queued status change for "${task.title}"`);
      }
    }
  }

  /* Replay queued offline commands when back online */
  replayOfflineQueue() {
    this.log("Replaying offline queue...");
    while (this.offlineQueue.length) {
      const cmd = this.offlineQueue.shift();
      if (cmd.action === 'add') this.saveTask(cmd.task);
      if (cmd.action === 'update') this.updateTaskStatus(cmd.taskId, cmd.status);
    }
  }

  /* List all tasks (immutable copy) */
  listTasks() { return [...this.tasks]; }

  /* Toggle online/offline mode */
  toggleOnline() {
    this.online = !this.online;
    this.log(`Online = ${this.online}`);
    if (this.online) this.replayOfflineQueue();
  }

  /* Logging helper */
  log(msg) { logEvent(`DataLayer: ${msg}`); }
}

const dataStore = new DataStore();

/* ===================================================
   Layer: Domain Layer
   Responsibilities:
     - Define Task entity
     - Business rules for tasks
   Patterns: Factory, Builder, State
   Mental Model: Encapsulate core logic and object creation
=================================================== */
class Task {
  constructor({ id, title, status = 'todo' }) {
    this.id = id;
    this.title = title;
    this.status = status;
  }
}

// Factory Pattern: centralized task creation
class TaskFactory {
  static create(title) {
    const id = Date.now(); // simple unique id
    const task = new Task({ id, title });
    logEvent(`Factory: Created task "${title}"`);
    return task;
  }
}

/* ===================================================
   Layer: Controller Layer
   Responsibilities:
     - Handle user commands
     - Manage undo/redo
     - Publish events
   Patterns: Command, Observer/EventBus
   Mental Model: Orchestrate predictable flows
=================================================== */
class EventBus {
  constructor() { this.events = {}; }
  subscribe(event, fn) { (this.events[event] ??= []).push(fn); }
  publish(event, data) { (this.events[event] || []).forEach(fn => fn(data)); }
}
const eventBus = new EventBus();

class CommandManager {
  constructor() { this.undoStack = []; this.redoStack = []; }
  execute(cmd) { cmd.execute(); this.undoStack.push(cmd); this.redoStack = []; }
  undo() { this.undoStack.pop()?.undo(); }
  redo() { this.redoStack.pop()?.redo(); }
}
const commandManager = new CommandManager();

// Command Pattern: Add Task
class AddTaskCommand {
  constructor(title) { this.title = title; this.task = null; }
  execute() {
    this.task = TaskFactory.create(this.title);
    dataStore.saveTask(this.task);
    eventBus.publish('taskAdded', this.task);
    return this.task;
  }
  undo() {
    const index = dataStore.tasks.indexOf(this.task);
    if (index >= 0) dataStore.tasks.splice(index, 1);
    localStorage.setItem('kanbanTasks', JSON.stringify(dataStore.tasks));
    eventBus.publish('taskRemoved', this.task);
  }
}

// Command Pattern: Move Task (column change)
class MoveTaskCommand {
  constructor(taskId, newStatus) { this.taskId = taskId; this.newStatus = newStatus; this.prevStatus = null; }
  execute() {
    const task = dataStore.tasks.find(t => t.id === this.taskId);
    this.prevStatus = task.status;
    dataStore.updateTaskStatus(this.taskId, this.newStatus);
    eventBus.publish('taskMoved', { task, newStatus: this.newStatus });
  }
  undo() {
    dataStore.updateTaskStatus(this.taskId, this.prevStatus);
    const task = dataStore.tasks.find(t => t.id === this.taskId);
    eventBus.publish('taskMoved', { task, newStatus: this.prevStatus });
  }
}

/* ===================================================
   Layer: View Layer
   Responsibilities:
     - Render DOM tasks
     - Enable drag-and-drop
     - Subscribe to EventBus
   Patterns: Mediator, Observer
   Mental Model: UI visualizes state and events
=================================================== */
function createTaskCard(task) {
  const card = document.createElement('div');
  card.className = 'card';
  card.draggable = true;
  card.textContent = task.title;
  card.dataset.id = task.id;

  card.addEventListener('dragstart', e => {
    e.dataTransfer.setData('text/plain', task.id);
  });

  return card;
}

function renderTask(task) {
  const column = document.getElementById(`${task.status}-column`);
  const existing = document.querySelector(`.card[data-id='${task.id}']`);
  if (existing) existing.remove();
  column.appendChild(createTaskCard(task));
  logEvent(`View: Rendered task "${task.title}" in ${task.status}`);
}

// Event subscriptions
eventBus.subscribe('taskAdded', renderTask);
eventBus.subscribe('taskRemoved', task => {
  const el = document.querySelector(`.card[data-id='${task.id}']`);
  if (el) el.remove();
});
eventBus.subscribe('taskMoved', data => { renderTask(data.task); });

// Drag-over & drop handling
document.querySelectorAll('.column').forEach(col => {
  col.addEventListener('dragover', e => e.preventDefault());
  col.addEventListener('drop', e => {
    e.preventDefault();
    const id = parseInt(e.dataTransfer.getData('text/plain'));
    const newStatus = col.dataset.status;
    commandManager.execute(new MoveTaskCommand(id, newStatus));
  });
});

/* ===== UI Button Listeners ===== */
document.getElementById('add-task-btn').addEventListener('click', () => {
  const title = prompt('Enter task title');
  if (title) commandManager.execute(new AddTaskCommand(title));
});
document.getElementById('undo-btn').addEventListener('click', () => commandManager.undo());
document.getElementById('redo-btn').addEventListener('click', () => commandManager.redo());
document.getElementById('toggle-offline-btn').addEventListener('click', () => dataStore.toggleOnline());

/* ===== Logging Utility ===== */
function logEvent(msg) {
  const logs = document.getElementById('logs');
  const time = new Date().toLocaleTimeString();
  logs.innerHTML += `[${time}] ${msg}<br>`;
  logs.scrollTop = logs.scrollHeight;
}

/* ===== Initial Render ===== */
dataStore.listTasks().forEach(task => renderTask(task));
</script>

<!-- ================= Annotations ================= -->
<div class="annotation">
<h3>Playground Notes:</h3>
<ul>
<li><strong>View Layer:</strong> DOM rendering, drag-and-drop (light blue)</li>
<li><strong>Controller Layer:</strong> Commands, undo/redo, EventBus (light green)</li>
<li><strong>Domain Layer:</strong> Task entity, Factory creation, State (light orange)</li>
<li><strong>Data Layer:</strong> Storage, Singleton instance, offline queue simulation (lavender)</li>
<li><strong>Patterns Illustrated:</strong> Singleton, Factory, Command, Observer/EventBus, Mediator, State</li>
<li><strong>Features:</strong> Add tasks, undo/redo, drag across columns, multi-tab sync, offline queue</li>
<li>Flow visualized: <em>User → View → Controller → Domain → Data → View update</em></li>
</ul>
</div>
```

---

## ✅ Key Explanations

1. **Data Layer**

   * Singleton ensures a single source of truth.
   * Offline queue simulates network delay; queued actions are replayed when online.
   * Multi-tab sync uses `storage` events (Observer pattern).

2. **Domain Layer**

   * Task entity encapsulates business logic (`id`, `title`, `status`).
   * Factory pattern creates tasks consistently.

3. **Controller Layer**

   * Handles commands (Add/Move) with undo/redo (Command pattern).
   * EventBus decouples producers (controller) from consumers (view).

4. **View Layer**

   * Renders tasks in columns with drag-and-drop support.
   * Subscribes to events for real-time updates.
   * Mediator pattern manages drag-drop between columns.

5. **Flow of Control**

```
User Interaction (click/drag)
        │
        ▼
Controller executes Command
        │
        ▼
Domain Layer → Task Factory
        │
        ▼
Data Layer → Storage / Offline Queue
        │
        ▼
EventBus publishes → View Layer updates
```

6. **Patterns Demonstrated**

* Singleton, Factory, Command, Observer/EventBus, Mediator, State

7. **Mental Models**

* Layer separation: View, Controller, Domain, Data
* Predictable flows: commands → state → render → log
* Offline resilience & multi-tab sync

---

This playground **visually demonstrates modern JS architecture principles, design patterns, and mental models in a fully interactive environment**.

---

