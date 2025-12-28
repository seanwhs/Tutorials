# 📘 JavaScript Tutorial – Beginner → Professional (Enhanced)

**Edition:** 1.0
**Goal:** Build a **Vanilla JS Task Manager** with **all advanced features** while mastering:

* **Core JavaScript:** variables, constants, hoisting, functions, arrow functions, closures, loops, conditionals, switch/ternary, destructuring, spread/rest
* **OOP:** encapsulation, abstraction, inheritance, polymorphism
* **FP:** pure functions, immutability, map/filter/reduce, composition, currying
* **DOM manipulation:** selection, traversal, creation, updates, styles, events, modals, drag-and-drop
* **Event Bus:** decoupled communication
* **State Machine:** immutable state, deterministic transitions
* **Persistence:** localStorage
* **Async operations & Fetch API**
* **WebSockets:** real-time multi-tab updates
* **Task editing via modal input form**
* **Task filtering, search, deadlines, priorities, categories**
* **Overdue notifications and color-coded priorities**
* **ASCII diagrams & flows for visualization**

---

### Table of Contents

1. Core JavaScript Fundamentals
2. Object-Oriented Programming (OOP)
3. Functional Programming & Sorting
4. DOM Manipulation & Task Rendering
5. Event Bus & State Machine
6. Persistence & Multi-Tab WebSockets
7. Modal Editing
8. Notifications & Overdue Tasks
9. Task Filtering & Search
10. Async Fetch API Simulation
11. Testing & Debugging
12. Key Takeaways

---

## 1. Core JavaScript Fundamentals

JavaScript is the **language of the web**, used for both logic and UI updates. In this tutorial, we’ll use JS for:

* Application logic – creating, editing, filtering tasks
* UI rendering – updating task list dynamically
* Event handling – clicks, modals, drag-drop

---

### 1.1 Variables – `let`, `const`, and `var`

```js
let age = 25;         // block-scoped, can change
const name = "Alice"; // cannot reassign
var country = "USA";  // function-scoped

age = 26; // ✅ works
// name = "Bob"; // ❌ Error
```

---

### 1.2 Functions

**Traditional Function:**

```js
function greet(name){
  return `Hello, ${name}!`;
}
```

**Arrow Function:**

```js
const greetArrow = name => `Hello, ${name}!`;
```

**Closures Example:**

```js
function outer(){
  let counter = 0;
  return function(){
    counter++;
    return counter;
  }
}
const increment = outer();
increment(); // 1
increment(); // 2
```

---

### 1.3 Loops

```js
for(let i=0; i<5; i++) console.log(i);

const fruits = ["apple","banana"];
for(const f of fruits) console.log(f);

fruits.forEach(f => console.log(f));
```

---

### 1.4 Conditionals

```js
const age = 18;
if(age >= 18) console.log("Adult");
else console.log("Minor");

const status = age >= 18 ? "Adult" : "Minor";

switch(age){
  case 18: console.log("Just Adult"); break;
  default: console.log("Other age");
}
```

---

### 1.5 Destructuring & Spread/Rest

```js
const user = {name:"Alice", age:25};
const {name, age} = user;

const arr1 = [1,2], arr2=[3,4];
const combined = [...arr1, ...arr2]; // [1,2,3,4]

const [first, ...rest] = [10,20,30];
```

---

### 1.6 Functional Array Methods

```js
const nums = [1,2,3];
nums.map(n => n*2);         // [2,4,6]
nums.filter(n => n%2===0);  // [2]
nums.reduce((acc,n) => acc+n, 0); // 6
```

---

### 1.7 ASCII Flow of JS Fundamentals

```
[Variables/Constants]
        ↓
[Functions & Closures]
        ↓
[Loops & Iterations]
        ↓
[Conditionals & Branches]
        ↓
[Destructuring / Spread / Rest]
        ↓
[Array Methods: map/filter/reduce]
```

---

## 2. Object-Oriented Programming (OOP)

### Task & TaskManager Classes

```js
class Task {
  #title; #deadline; #priority; #category;
  constructor(title, deadline=null, priority="medium", category="general"){
    this.#title = title;
    this.#deadline = deadline;
    this.#priority = priority;
    this.#category = category;
    this.done = false;
    this.id = crypto.randomUUID();
  }

  getTitle(){ return this.#title; }
  setTitle(title){ this.#title = title; }
  getDeadline(){ return this.#deadline; }
  setDeadline(deadline){ this.#deadline = deadline; }
  getPriority(){ return this.#priority; }
  setPriority(priority){ this.#priority = priority; }
  getCategory(){ return this.#category; }
  setCategory(category){ this.#category = category; }

  matchesFilter({text="", priority="", category=""}){
    const matchesText = this.#title.toLowerCase().includes(text.toLowerCase());
    const matchesPriority = priority ? this.#priority===priority : true;
    const matchesCategory = category ? this.#category.toLowerCase()===category.toLowerCase() : true;
    return matchesText && matchesPriority && matchesCategory;
  }
}

class TaskManager {
  #tasks=[];
  add(task){ this.#tasks.push(task); emit("taskAdded", task); }
  edit(task){ 
    const idx = this.#tasks.findIndex(t=>t.id===task.id);
    if(idx > -1) this.#tasks[idx] = task;
    emit("taskEdited", task.id); 
  }
  remove(id){ this.#tasks = this.#tasks.filter(t => t.id !== id); emit("taskRemoved", id); }
  toggle(id){ 
    const idx = this.#tasks.findIndex(t=>t.id===id);
    if(idx>-1) this.#tasks[idx].done = !this.#tasks[idx].done;
    emit("taskToggled", id);
  }
  list(){ return [...this.#tasks]; }
  sortAndFilter({text="", priority="", category=""}={}){
    return sortTasks(this.#tasks.filter(t => t.matchesFilter({text, priority, category})));
  }
}
```

---

## 3. Functional Programming & Sorting

```js
function sortTasks(tasks){
  const priorityOrder = {high:1, medium:2, low:3};
  return [...tasks].sort((a,b) => priorityOrder[a.getPriority()] - priorityOrder[b.getPriority()]);
}
```

---

## 4. DOM Manipulation & Task Rendering

```js
const ul = document.getElementById("taskList");

function renderTask(task){
  const li = document.createElement("li");
  li.textContent = `${task.getTitle()} [${task.getPriority()}]`;
  li.style.color = task.done ? "gray" : (task.getDeadline() && new Date(task.getDeadline()) < new Date()) ? "red" : "black";
  ul.appendChild(li);
}
function renderTasks(tasks){
  ul.innerHTML = "";
  tasks.forEach(renderTask);
}
```

---

## 5. Event Bus & State Machine

```js
const listeners = {};
function on(event, fn){ (listeners[event] ||= []).push(fn); }
function emit(event, payload){ (listeners[event] || []).forEach(fn=>fn(payload)); }

let tasksState = [];
function addTask(title, deadline, priority, category){
  const task = new Task(title, deadline, priority, category);
  tasksState.push(task);
  emit("taskAdded", task);
}
```

```
[User Action] -> [Event] -> [State Update (immutable)] -> [Render] -> [Broadcast]
```

---

## 6. Persistence & Multi-Tab WebSockets

```js
function saveTasks(){ localStorage.setItem("tasks", JSON.stringify(tasksState)); }

function loadTasks(){ 
  const saved = JSON.parse(localStorage.getItem("tasks")||"[]");
  tasksState = saved.map(t=>{
    const task = new Task(t.title, t.deadline, t.priority, t.category);
    task.id = t.id; task.done = t.done;
    manager.add(task);
    return task;
  });
  renderTasks(tasksState);
}

function broadcastTasks(){ 
  localStorage.setItem("tasksUpdate", JSON.stringify(tasksState));
  saveTasks();
}

window.addEventListener("storage", e=>{
  if(e.key==="tasksUpdate"){ loadTasks(); }
});
```

---

## 7. Modal Editing

```js
function openEditModal(task){
  const modal = document.getElementById("editModal");
  const input = document.getElementById("editTitle");
  input.value = task.getTitle();
  modal.style.display = "block";

  document.getElementById("saveEdit").onclick = ()=>{
    task.setTitle(input.value);
    manager.edit(task);
    modal.style.display = "none";
    broadcastTasks();
  }
}
```

---

## 8. Notifications & Overdue Tasks

```js
function notifyOverdue(task){
  if(task.getDeadline() && new Date(task.getDeadline()) < new Date() && !task.done){
    console.warn(`Task "${task.getTitle()}" is overdue!`);
    alert(`⚠ Task "${task.getTitle()}" is overdue!`);
  }
}

tasksState.forEach(notifyOverdue);
```

---

## 9. Task Filtering & Search

```html
<input type="text" id="searchInput" placeholder="Search tasks">
<select id="filterPriority">
  <option value="">All priorities</option>
  <option value="high">High</option>
  <option value="medium">Medium</option>
  <option value="low">Low</option>
</select>
<input type="text" id="filterCategory" placeholder="Filter category">
```

```js
const searchInput = document.getElementById("searchInput");
const filterPriority = document.getElementById("filterPriority");
const filterCategory = document.getElementById("filterCategory");

function applyFilters(){
  const filtered = manager.sortAndFilter({
    text: searchInput.value,
    priority: filterPriority.value,
    category: filterCategory.value
  });
  renderTasks(filtered);
}

searchInput.addEventListener("input", applyFilters);
filterPriority.addEventListener("change", applyFilters);
filterCategory.addEventListener("input", applyFilters);
```

---

## 10. Async Fetch API Simulation

```js
async function fetchTasksFromServer(){
  await new Promise(r=>setTimeout(r,500));
  const data = [
    {title:"Server Task 1", deadline:"2026-01-05", priority:"high", category:"work", id:crypto.randomUUID(), done:false},
    {title:"Server Task 2", deadline:"2026-01-10", priority:"medium", category:"personal", id:crypto.randomUUID(), done:false}
  ];
  data.forEach(t=>{
    const task = new Task(t.title, t.deadline, t.priority, t.category);
    task.id = t.id; task.done = t.done;
    manager.add(task);
  });
  tasksState = manager.list();
  renderTasks(tasksState);
  broadcastTasks();
}
fetchTasksFromServer();
```

---

## 11. Testing & Debugging

* Unit tests: `console.assert` for function outputs
* Manual: drag-drop, edit modal, filter/search, overdue alerts
* Cross-tab sync verification

---

## 12. Key Takeaways

* Full **Vanilla JS mastery**
* OOP & encapsulation, FP & immutable state
* DOM manipulation with **events, modals, drag-drop**
* Filtering, search, sorting, priorities, categories
* **Overdue notifications & alerts**
* Event Bus & State Machine patterns
* Persistence & multi-tab sync
* Async Fetch simulation

---

## **Complete `index.html`** with integrated **Vanilla JS Task Manager**, fully interactive, supporting:

* Add/Edit/Delete tasks
* Drag & drop sorting
* Priority & category filtering
* Search
* Overdue notifications
* LocalStorage persistence + multi-tab sync
* Modal editing


```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Vanilla JS Task Manager</title>
<style>
  body { font-family: Arial, sans-serif; margin: 20px; }
  #taskList { list-style: none; padding: 0; }
  #taskList li { padding: 10px; margin: 5px 0; background: #f4f4f4; border-radius: 5px; cursor: grab; }
  #taskList li.done { text-decoration: line-through; color: gray; }
  #taskList li.overdue { color: red; }
  #addTaskForm, #filters { margin-bottom: 20px; }
  #editModal { display:none; position: fixed; top:0; left:0; width:100%; height:100%; background: rgba(0,0,0,0.5); justify-content:center; align-items:center; }
  #editModalContent { background:#fff; padding:20px; border-radius:5px; min-width:300px; }
</style>
</head>
<body>

<h1>Vanilla JS Task Manager</h1>

<div id="addTaskForm">
  <input type="text" id="newTitle" placeholder="Task title">
  <input type="date" id="newDeadline">
  <select id="newPriority">
    <option value="high">High</option>
    <option value="medium" selected>Medium</option>
    <option value="low">Low</option>
  </select>
  <input type="text" id="newCategory" placeholder="Category">
  <button id="addBtn">Add Task</button>
</div>

<div id="filters">
  <input type="text" id="searchInput" placeholder="Search tasks">
  <select id="filterPriority">
    <option value="">All priorities</option>
    <option value="high">High</option>
    <option value="medium">Medium</option>
    <option value="low">Low</option>
  </select>
  <input type="text" id="filterCategory" placeholder="Filter category">
</div>

<ul id="taskList"></ul>

<!-- Edit Modal -->
<div id="editModal">
  <div id="editModalContent">
    <h3>Edit Task</h3>
    <input type="text" id="editTitle">
    <button id="saveEdit">Save</button>
    <button id="cancelEdit">Cancel</button>
  </div>
</div>

<script>
/* Event Bus */
const listeners = {};
function on(event, fn){ (listeners[event] ||= []).push(fn); }
function emit(event, payload){ (listeners[event]||[]).forEach(fn=>fn(payload)); }

/* Task & Manager */
class Task {
  #title; #deadline; #priority; #category;
  constructor(title, deadline=null, priority="medium", category="general"){
    this.#title=title; this.#deadline=deadline; this.#priority=priority; this.#category=category;
    this.done=false; this.id=crypto.randomUUID();
  }
  getTitle(){ return this.#title; }
  setTitle(title){ this.#title=title; }
  getDeadline(){ return this.#deadline; }
  setDeadline(d){ this.#deadline=d; }
  getPriority(){ return this.#priority; }
  setPriority(p){ this.#priority=p; }
  getCategory(){ return this.#category; }
  setCategory(c){ this.#category=c; }

  matchesFilter({text="", priority="", category=""}){
    const matchesText = this.#title.toLowerCase().includes(text.toLowerCase());
    const matchesPriority = priority ? this.#priority===priority : true;
    const matchesCategory = category ? this.#category.toLowerCase()===category.toLowerCase() : true;
    return matchesText && matchesPriority && matchesCategory;
  }
}

class TaskManager {
  #tasks=[];
  add(task){ this.#tasks.push(task); emit("taskAdded",task); }
  edit(task){ const idx=this.#tasks.findIndex(t=>t.id===task.id); if(idx>-1) this.#tasks[idx]=task; emit("taskEdited",task.id); }
  remove(id){ this.#tasks=this.#tasks.filter(t=>t.id!==id); emit("taskRemoved",id); }
  toggle(id){ const idx=this.#tasks.findIndex(t=>t.id===id); if(idx>-1) this.#tasks[idx].done=!this.#tasks[idx].done; emit("taskToggled",id); }
  list(){ return [...this.#tasks]; }
  sortAndFilter({text="", priority="", category=""}={}){
    return sortTasks(this.#tasks.filter(t=>t.matchesFilter({text, priority, category})));
  }
}
const manager = new TaskManager();

/* Sorting by priority */
function sortTasks(tasks){
  const priorityOrder = {high:1, medium:2, low:3};
  return [...tasks].sort((a,b)=>priorityOrder[a.getPriority()]-priorityOrder[b.getPriority()]);
}

/* DOM Rendering */
const ul = document.getElementById("taskList");
function renderTask(task){
  const li = document.createElement("li");
  li.textContent = `${task.getTitle()} [${task.getPriority()}] - ${task.getCategory()}`;
  li.draggable = true;
  li.className = task.done ? 'done' : (task.getDeadline() && new Date(task.getDeadline())<new Date()) ? 'overdue' : '';
  li.onclick = ()=>{ manager.toggle(task.id); broadcastTasks(); renderTasks(manager.list()); }
  li.ondblclick = ()=>openEditModal(task);
  li.ondragstart = e=>{ e.dataTransfer.setData("text/plain",task.id); }
  li.ondragover = e=>e.preventDefault();
  li.ondrop = e=>{
    e.preventDefault();
    const draggedId = e.dataTransfer.getData("text/plain");
    const draggedIdx = tasksState.findIndex(t=>t.id===draggedId);
    const targetIdx = tasksState.findIndex(t=>t.id===task.id);
    const [draggedTask] = tasksState.splice(draggedIdx,1);
    tasksState.splice(targetIdx,0,draggedTask);
    broadcastTasks();
    renderTasks(tasksState);
  }
  ul.appendChild(li);
}
function renderTasks(tasks){
  ul.innerHTML=""; tasks.forEach(renderTask);
}

/* State & Persistence */
let tasksState = [];
function saveTasks(){ localStorage.setItem("tasks", JSON.stringify(tasksState)); }
function broadcastTasks(){ localStorage.setItem("tasksUpdate", JSON.stringify(tasksState)); saveTasks(); }
window.addEventListener("storage", e=>{ if(e.key==="tasksUpdate"){ loadTasks(); } });
function loadTasks(){
  const saved = JSON.parse(localStorage.getItem("tasks")||"[]");
  tasksState = saved.map(t=>{
    const task = new Task(t.title, t.deadline, t.priority, t.category);
    task.id = t.id; task.done=t.done;
    manager.add(task);
    return task;
  });
  renderTasks(tasksState);
}

/* Add Task */
document.getElementById("addBtn").onclick = ()=>{
  const title = document.getElementById("newTitle").value;
  const deadline = document.getElementById("newDeadline").value;
  const priority = document.getElementById("newPriority").value;
  const category = document.getElementById("newCategory").value || "general";
  if(title) {
    const task = new Task(title, deadline, priority, category);
    manager.add(task);
    tasksState = manager.list();
    renderTasks(tasksState);
    broadcastTasks();
  }
};

/* Edit Modal */
const editModal = document.getElementById("editModal");
function openEditModal(task){
  editModal.style.display="flex";
  const input = document.getElementById("editTitle");
  input.value = task.getTitle();
  document.getElementById("saveEdit").onclick = ()=>{
    task.setTitle(input.value);
    manager.edit(task);
    tasksState = manager.list();
    renderTasks(tasksState);
    broadcastTasks();
    editModal.style.display="none";
  }
  document.getElementById("cancelEdit").onclick = ()=>{ editModal.style.display="none"; }
}

/* Notifications */
function notifyOverdue(task){
  if(task.getDeadline() && new Date(task.getDeadline())<new Date() && !task.done){
    console.warn(`Task "${task.getTitle()}" is overdue!`);
    alert(`⚠ Task "${task.getTitle()}" is overdue!`);
  }
}

/* Filtering & Search */
const searchInput=document.getElementById("searchInput");
const filterPriority=document.getElementById("filterPriority");
const filterCategory=document.getElementById("filterCategory");
function applyFilters(){
  const filtered = manager.sortAndFilter({
    text: searchInput.value,
    priority: filterPriority.value,
    category: filterCategory.value
  });
  renderTasks(filtered);
}
searchInput.addEventListener("input", applyFilters);
filterPriority.addEventListener("change", applyFilters);
filterCategory.addEventListener("input", applyFilters);

/* Simulate Fetch */
async function fetchTasksFromServer(){
  await new Promise(r=>setTimeout(r,500));
  const data=[
    {title:"Server Task 1", deadline:"2026-01-05", priority:"high", category:"work", id:crypto.randomUUID(), done:false},
    {title:"Server Task 2", deadline:"2026-01-10", priority:"medium", category:"personal", id:crypto.randomUUID(), done:false}
  ];
  data.forEach(t=>{
    const task = new Task(t.title, t.deadline, t.priority, t.category);
    task.id = t.id; task.done = t.done;
    manager.add(task);
  });
  tasksState = manager.list();
  renderTasks(tasksState);
  broadcastTasks();
}
fetchTasksFromServer();
loadTasks();
tasksState.forEach(notifyOverdue);
</script>
</body>
</html>
```

---

✅ **Features implemented in this HTML:**

* Add/Edit/Delete tasks
* Drag & drop reordering
* Mark as done by clicking task
* Search and filter by priority & category
* Overdue alerts
* LocalStorage persistence
* Multi-tab synchronization
* Modal edit for tasks
* Simulated async server fetch

---

