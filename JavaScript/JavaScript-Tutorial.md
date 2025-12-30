# 🧩 JS-Labs – Complete JavaScript Learning Path & Tutorials

**JS-Labs** is a **hands-on playground** for mastering JavaScript from **core fundamentals to real-world applications**. It combines **conceptual explanations, practical examples, and interactive exercises** for a **step-by-step learning journey**.

---

## **JavaScript Learning Phases – Conceptual Roadmap**

| Phase | Focus                       | Key Concepts                                                                                        |
| ----- | --------------------------- | --------------------------------------------------------------------------------------------------- |
| 1     | Core JS (The Logic)         | Variables, Data Types, Operators, Conditionals, Loops, Functions, Arrays & Objects                  |
| 2     | Browser Interaction (DOM)   | Selecting Elements, DOM Traversal, Event Listeners, Attributes, Class Manipulation, Dynamic Content |
| 3     | Advanced & Modern JS (ES6+) | Template Literals, Destructuring, Spread & Rest, Async JS, Fetch API, ES Modules                    |
| 4     | Error Handling & Debugging  | `try/catch`, Input Validation, DevTools, Logging, Breakpoints                                       |

> **Goal:** Progress **linearly** from understanding **logic**, to **interacting with web pages**, to writing **modern, maintainable JS**, and finally **ensuring code reliability**.

---

# 🧩 Phase 1 – Core JavaScript (JS Core Deep Dive)

This phase builds the **engine of your programs**.

### **1. Variables & Scope**

```javascript
let age = 25;          // mutable, block-scoped
const pi = 3.14159;    // immutable constant
var legacyVar = "I exist"; // function-scoped, legacy
```

**Scope Example:**

```javascript
let globalVar = "I am global";
function testScope() {
    let localVar = "I am local";
    console.log(globalVar); // ✅ Accessible
    console.log(localVar);  // ✅ Accessible
}
console.log(globalVar); // ✅ Accessible
// console.log(localVar); // ❌ Error
```

---

### **2. Data Types**

**Primitives:** String, Number, Boolean, Null, Undefined
**Objects:** Arrays, Object literals

```javascript
let person = {name: "Alice", age: 30};
let colors = ["red","green","blue"];
```

---

### **3. Operators**

* Arithmetic: `+`, `-`, `*`, `/`, `%`
* Comparison: `==`, `===`, `!=`, `!==`, `<`, `>`
* Logical: `&&`, `||`, `!`

```javascript
console.log(10 + 5); // 15
console.log(10 % 3); // 1
console.log(true && false); // false
```

---

### **4. Conditionals**

```javascript
let age = 20;
if(age < 18) console.log("Too young");
else console.log("Adult");

let day = 3;
switch(day){
    case 1: console.log("Monday"); break;
    case 2: console.log("Tuesday"); break;
    default: console.log("Another day");
}
```

---

### **5. Loops**

```javascript
for(let i=0; i<5; i++) console.log(i);

let arr = [1,2,3];
arr.forEach(num => console.log(num));

let i = 0;
while(i < 5){
    console.log(i);
    i++;
}
```

---

### **6. Functions**

```javascript
function greet(name){ return `Hello, ${name}`; }
const greet2 = name => `Hi, ${name}`;
```

---

### **7. Type Conversion**

```javascript
let ageStr = prompt("Enter age:");
let ageNum = parseInt(ageStr);
console.log(ageNum + 5);
```

---

### **8. Arrays & Objects**

```javascript
let fruits = ["apple","banana"];
console.log(fruits[0]);

let person = {name:"Bob"};
person.age = 28;
fruits.push("orange");
```

---

# 🧩 Phase 2 – Browser Interaction (DOM)

**Goal:** Make web pages interactive.

### **1. Element Selection**

```javascript
const title = document.getElementById("title");
const paragraph = document.querySelector(".description");
const items = document.querySelectorAll("ul li");
```

---

### **2. DOM Manipulation**

```javascript
title.textContent = "Updated Title";
paragraph.style.color = "blue";
items[0].textContent = "Updated Item 1";
```

---

### **3. Event Listeners**

```javascript
document.getElementById("btn").addEventListener("click", () => alert("Clicked!"));

document.getElementById("nameInput").addEventListener("keyup", (e) => console.log(e.target.value));
```

---

### **4. DOM Traversal**

```javascript
const ul = document.getElementById("list");
ul.firstElementChild.style.color = "red";
ul.lastElementChild.style.fontWeight = "bold";
ul.children[1].textContent = "Middle Item Updated";
```

---

### **5. Attributes & Class Manipulation**

```javascript
const link = document.querySelector("a");
link.setAttribute("href", "https://example.com");
link.classList.add("highlight");
link.classList.toggle("active");
```

---

# 🧩 Phase 3 – Advanced & Modern JS (ES6+)

### **1. Template Literals & Destructuring**

```javascript
const person = {name:"Alice", age:30, city:"SG"};
const {name, age, city} = person;
console.log(`Hello ${name}, ${age} years old, from ${city}`);
```

---

### **2. Spread & Rest Operators**

```javascript
let arr1 = [1,2];
let arr2 = [3,4];
let merged = [...arr1, ...arr2];

function sumAll(...nums){
    return nums.reduce((acc,curr)=>acc+curr,0);
}
console.log(sumAll(1,2,3,4));
```

---

### **3. Async JS & Fetch API**

```javascript
async function getTodo(){
    try{
        const res = await fetch("https://jsonplaceholder.typicode.com/todos/1");
        const data = await res.json();
        console.log(data);
    } catch(err){
        console.error("Error fetching data", err);
    }
}
getTodo();
```

---

### **4. ES Modules**

`math.js`:

```javascript
export function add(a,b){ return a+b; }
```

`main.js`:

```javascript
import { add } from "./math.js";
console.log(add(5,3));
```

---

# 🧩 Phase 4 – Error Handling & Debugging

* `try/catch` for runtime errors
* Input validation (`console.warn` for invalid inputs)
* Use `debugger` and DevTools to step through code
* Logging levels for tracing: `console.log`, `console.warn`, `console.error`

---

# 🧩 JS-Labs Step-by-Step Labsheets

## **Labsheet 1 – Core JS**

* Variables & Scope
* Data Types & Conversion
* Operators & Conditionals
* Loops
* Functions & Arrays/Objects

---

## **Labsheet 2 – DOM Manipulation**

* HTML Setup
* Element Selection & Manipulation
* Event Listeners
* DOM Traversal
* Attributes & Class Handling

---

## **Labsheet 3 – Modern JS (ES6+)**

* Template Literals
* Destructuring
* Spread & Rest Operators
* Async JS & Fetch
* ES Modules

---

## **Labsheet 4 – Error Handling & Debugging**

* Try/Catch
* Input Validation
* Console & DevTools
* Safe calculations

---

## **Labsheet 5 – Integration Project: Digital Clock**

* Core JS + DOM + Modern JS
* Timers (`setInterval`)
* AM/PM & Dynamic Styling
* Start/Stop Button Events
* Error Handling

---

# 🗺️ JS-Labs ASCII Roadmap

```
┌─────────────────────────────────────┐
│           JS-Labs Program           │
│ Comprehensive JavaScript Tutorials │
└─────────────────┬──────────────────┘
                  │
                  ▼
┌─────────────── Lab 1: Core JS ──────────────┐
│ Variables, Data Types, Operators, Loops      │
│ Functions, Arrays & Objects                  │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────── Lab 2: DOM ──────────────────┐
│ Element Selection, Manipulation, Events      │
│ Traversal, Attributes & Classes              │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────── Lab 3: Modern JS ────────────┐
│ Template Literals, Destructuring, Spread/Rest│
│ Async JS, Fetch API, ES Modules              │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────── Lab 4: Error Handling ───────┐
│ Try/Catch, Input Validation, DevTools       │
│ Logging, Debugging                          │
└─────────────┬───────────────────────────────┘
              │
              ▼
┌─────────────── Lab 5: Integration ──────────┐
│ Digital Clock Application: Core+DOM+Modern  │
│ Timers, AM/PM, Dynamic Styling, Buttons     │
└─────────────────────────────────────────────┘
```

---

✅ **Next Step:** Work **sequentially** from Labsheet 1 → 5. Complete exercises, apply optional enhancements, and test in-browser for full mastery.

---

# 🧩 JS-Labs – Ready-to-Run Folder Structure

```
JS-Labs/
├── Lab1_CoreJS/
│   ├── lab1.html
│   └── lab1.js
├── Lab2_DOM/
│   ├── lab2.html
│   └── lab2.js
├── Lab3_ModernJS/
│   ├── lab3.html
│   └── lab3.js
├── Lab4_ErrorHandling/
│   ├── lab4.html
│   └── lab4.js
├── Lab5_DigitalClock/
│   ├── lab5.html
│   └── lab5.js
└── README.md
```

---

## **Lab1_CoreJS/lab1.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lab 1 - Core JS</title>
</head>
<body>
    <h1>Lab 1: Core JavaScript</h1>
    <p>Open console to view outputs.</p>
    <script src="lab1.js"></script>
</body>
</html>
```

### **Lab1_CoreJS/lab1.js**

```javascript
// Variables & Scope
let userName = "Your Name";
const birthYear = 1990;
var legacyVar = "Legacy";

function displayVariables(){
    console.log("User:", userName);
    console.log("Birth Year:", birthYear);
    console.log("Legacy:", legacyVar);
}
displayVariables();

// Data Types & Type Conversion
let num1 = parseInt(prompt("Enter first number:"));
let num2 = parseInt(prompt("Enter second number:"));
console.log("Sum:", num1 + num2);
console.log("Difference:", num1 - num2);
console.log("Product:", num1 * num2);
console.log("Quotient:", num1 / num2);
console.log("Remainder:", num1 % num2);

// Conditionals
let age = parseInt(prompt("Enter your age:"));
if(age < 18) console.log("Too young");
else if(age <= 65) console.log("Adult");
else console.log("Senior");

// Loops
let fruits = ["apple","banana","cherry"];
for(let i=0; i<fruits.length; i++) console.log(fruits[i]);
fruits.forEach(fruit => console.log(fruit.toUpperCase()));

// Functions
function square(n){ return n*n; }
const greet = name => `Hello, ${name}`;
console.log(square(5));
console.log(greet("Alice"));
```

---

## **Lab2_DOM/lab2.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lab 2 - DOM</title>
    <style>
        .highlight { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1 id="title">Hello JS-Labs</h1>
    <p class="description">This is a paragraph.</p>
    <button id="btn">Click Me</button>
    <input id="nameInput" placeholder="Type your name">
    <ul id="list">
        <li>Item 1</li>
        <li>Item 2</li>
        <li>Item 3</li>
    </ul>
    <script src="lab2.js"></script>
</body>
</html>
```

### **Lab2_DOM/lab2.js**

```javascript
// Element Selection & Manipulation
const title = document.getElementById("title");
title.textContent = "Updated Title";

const paragraph = document.querySelector(".description");
paragraph.style.color = "blue";

const items = document.querySelectorAll("#list li");
items.forEach((item, index) => item.textContent = `Item ${index + 1} Updated`);

// Event Listeners
document.getElementById("btn").addEventListener("click", () => alert("Button clicked!"));

document.getElementById("nameInput").addEventListener("keyup", (e) => console.log(e.target.value));

// DOM Traversal
const ul = document.getElementById("list");
ul.firstElementChild.style.color = "green";
ul.lastElementChild.style.fontWeight = "bold";

// Attributes & Class Manipulation
const link = document.createElement("a");
link.href = "#";
link.textContent = "Example Link";
document.body.appendChild(link);

link.setAttribute("href","https://example.com");
link.classList.add("highlight");
link.addEventListener("click", (e)=>{
    e.preventDefault();
    alert("Link clicked!");
});
```

---

## **Lab3_ModernJS/lab3.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lab 3 - Modern JS</title>
</head>
<body>
    <h1>Lab 3: Modern JS</h1>
    <script type="module" src="lab3.js"></script>
</body>
</html>
```

### **Lab3_ModernJS/lab3.js**

```javascript
// Template Literals & Destructuring
const person = { name: "Alice", age: 30, city: "Singapore" };
const {name, age, city} = person;
console.log(`Hello ${name}, ${age} years old from ${city}`);

// Spread & Rest Operators
const arr1 = [1,2], arr2=[3,4];
const merged = [...arr1,...arr2];
console.log(merged);

function sumAll(...nums){ return nums.reduce((a,b)=>a+b,0); }
console.log(sumAll(1,2,3,4));

// Async & Fetch
async function getTodo(){
    try{
        const res = await fetch("https://jsonplaceholder.typicode.com/todos/1");
        const data = await res.json();
        console.log(data);
    } catch(err){ console.error("Error:", err); }
}
getTodo();

// ES Modules Example
// create math.js in same folder if using modules:
// export function add(a,b){ return a+b; }
// import { add } from "./math.js";
// console.log(add(5,3));
```

---

## **Lab4_ErrorHandling/lab4.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lab 4 - Error Handling</title>
</head>
<body>
    <h1>Lab 4: Error Handling</h1>
    <script src="lab4.js"></script>
</body>
</html>
```

### **Lab4_ErrorHandling/lab4.js**

```javascript
// Try/Catch Example
try{
    let input = prompt("Enter a number:");
    let result = 100 / parseInt(input);
    if(isNaN(result)) throw new Error("Invalid input!");
    console.log("Result:", result);
} catch(err){
    console.error("Error caught:", err.message);
}

// Debugging
let x = 10;
debugger; // Opens DevTools breakpoint
console.log("x =", x);

// Input Validation
let name = prompt("Enter your name:");
if(!name) console.warn("Name cannot be empty");
else console.log("Hello", name);
```

---

## **Lab5_DigitalClock/lab5.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Lab 5 - Digital Clock</title>
    <style>
        #clock{font-size:2em; font-family:monospace;}
        body.morning{background-color:#fff9c4;}
        body.afternoon{background-color:#ffe0b2;}
        body.evening{background-color:#b3e5fc;}
    </style>
</head>
<body>
    <h1>Digital Clock</h1>
    <div id="clock">00:00:00</div>
    <button id="startBtn">Start</button>
    <button id="stopBtn">Stop</button>
    <script src="lab5.js"></script>
</body>
</html>
```

### **Lab5_DigitalClock/lab5.js**

```javascript
const clockEl = document.getElementById("clock");
let timerId;

// Core Time Functions
function getCurrentTime(){
    const now = new Date();
    return {h: now.getHours(), m: now.getMinutes(), s: now.getSeconds()};
}

function formatTime(unit){ return unit<10?"0"+unit:unit; }

function formatAMPM(h){
    const period = h>=12?"PM":"AM";
    h = h%12 || 12;
    return {h, period};
}

function updateClock(){
    const {h,m,s} = getCurrentTime();
    const {h: hh, period} = formatAMPM(h);
    clockEl.textContent = `${formatTime(hh)}:${formatTime(m)}:${formatTime(s)} ${period}`;
    updateBackground(h);
}

// Dynamic Background
function updateBackground(h){
    if(h>=6 && h<12) document.body.className="morning";
    else if(h>=12 && h<18) document.body.className="afternoon";
    else document.body.className="evening";
}

// Start & Stop
document.getElementById("startBtn").addEventListener("click", ()=>{
    if(!timerId) timerId = setInterval(updateClock, 1000);
});
document.getElementById("stopBtn").addEventListener("click", ()=>{
    clearInterval(timerId);
    timerId = null;
});

// Initialize
updateClock();
```

---

## **README.md**

```markdown
# JS-Labs

Complete JavaScript Learning Path – ready-to-run projects.

## Instructions

1. Open each lab folder (Lab1_CoreJS … Lab5_DigitalClock)
2. Open the corresponding HTML file in your browser.
3. Open the browser console (F12) to view outputs where needed.
4. Follow prompts and interact with DOM elements.
5. Sequentially complete Labs 1 → 5 to master JS fundamentals, DOM, modern JS, error handling, and integration.

```

# 🧩 JS-Labs Addendum – Object-Oriented Programming (OOP) & Functional Programming (FP)

**Purpose:** Learn structured design (OOP) and functional thinking (FP) to build **maintainable, reusable, predictable JS applications**.

**Mental Models:**

* **OOP:** Code as **real-world objects** with properties (state) and methods (behavior). Classes = blueprints, objects = instances.
* **FP:** Code as **data transformations**. Functions take input → produce output **without side effects**. Emphasizes **immutability** and **composition**.
* **Arrow Functions:** A concise way to define functions; keep `this` binding consistent, especially useful in FP and callbacks.

---

# 🧩 Phase 5 – OOP & FP Integration in JS-Labs

---

## **Step 0 – Folder Structure**

```
JS-Labs/
├── Lab 1: Core JS
├── Lab 2: DOM Interaction
├── Lab 3: Modern JS
├── Lab 4: Error Handling
├── Lab 5: Digital Clock
├── Lab 6: OOP & FP
│   ├── index.html
│   └── lab6.js
└── README.md
```

---

## **Lab 6: Object-Oriented & Functional Programming**

**Objective:** Apply **OOP + FP + arrow functions** in a **hands-on project**, progressively learning step-by-step.

---

### **Step 1: HTML Setup**

`index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>JS-Labs OOP & FP</title>
</head>
<body>
    <h1>JS-Labs: OOP & FP</h1>

    <h2>Students Management</h2>
    <button id="addStudentBtn">Add Random Student</button>
    <button id="showStudentsBtn">Show Students</button>
    <ul id="studentList"></ul>

    <script src="lab6.js"></script>
</body>
</html>
```

**Checkpoint:** Open in browser; see buttons and empty list.

---

### **Step 2: Define Classes (OOP)**

`lab6.js`:

```javascript
// Class Blueprint for a Student
class Student {
    constructor(name, score){
        this.name = name;
        this.score = score;
    }

    // Method using arrow function
    introduce = () => console.log(`Hi, I'm ${this.name}, scored ${this.score}`);
}

// Subclass example: SpecialStudent
class SpecialStudent extends Student {
    constructor(name, score, skill){
        super(name, score); // inherit name & score
        this.skill = skill;
    }

    showSkill = () => console.log(`${this.name} excels in ${this.skill}`);
}

// Array to hold students
const students = [];
```

**Mental Model:**

* `Student` = blueprint for each student.
* `SpecialStudent` = specialized version (inheritance).
* Arrow functions used in methods to **retain `this` context**.

**Exercise:** Create `Teacher` class with `name` and `subject`, and a `teach()` arrow function.

---

### **Step 3: Add Students Dynamically**

```javascript
const studentList = document.getElementById("studentList");
const addBtn = document.getElementById("addStudentBtn");

addBtn.addEventListener("click", () => {
    const names = ["Alice","Bob","Charlie","Diana"];
    const randomName = names[Math.floor(Math.random()*names.length)];
    const randomScore = Math.floor(Math.random()*101); // 0-100

    const student = new Student(randomName, randomScore);
    students.push(student);
    console.log(`Added: ${student.name} with score ${student.score}`);
});
```

**Checkpoint:** Click "Add Random Student"; check console logs.

---

### **Step 4: Display Students (OOP + FP)**

```javascript
const showBtn = document.getElementById("showStudentsBtn");

showBtn.addEventListener("click", () => {
    // Clear previous list
    studentList.innerHTML = "";

    // Functional approach: map + forEach
    students.map(s => s.introduce()).forEach(s => console.log(s));

    // Display in HTML
    students.forEach(s => {
        const li = document.createElement("li");
        li.textContent = `${s.name} - ${s.score}`;
        studentList.appendChild(li);
    });
});
```

**Explanation:**

* `map()` transforms each student to `introduce()` call.
* `forEach()` performs the side-effect of logging or DOM update.
* Arrow functions keep code concise and `this` consistent.

**Exercise:** Use `filter()` to display only students with score ≥ 50.

---

### **Step 5: Functional Programming – Array Transformations**

```javascript
// Get top scoring students (≥70)
const topStudents = students.filter(s => s.score >= 70).map(s => s.name);
console.log("Top Students:", topStudents);

// Calculate average score using reduce
const avgScore = students.reduce((acc,s) => acc + s.score, 0) / (students.length || 1);
console.log("Average Score:", avgScore.toFixed(2));
```

**Mental Model:**

* **filter()** → select relevant data
* **map()** → transform data
* **reduce()** → aggregate data

**Exercise:** Chain filter → map → reduce to calculate **sum of top student scores**.

---

### **Step 6: Immutability & Composition**

```javascript
// Add student immutably
const addStudentImmutable = (studentsArray, student) => [...studentsArray, student];

// Compose functions
const doubleScore = s => ({...s, score: s.score*2});
const incrementScore = s => ({...s, score: s.score+1});
const compose = (...fns) => x => fns.reduce((v,f)=>f(v),x);

const transformStudent = compose(doubleScore, incrementScore);
const newStudent = transformStudent(new Student("Eve",50));
console.log(newStudent);
```

**Checkpoint:** Observe original `students` array is unchanged.

**Exercise:** Compose functions to **filter, boost score, and log top students**.

---

### **Step 7: Progressive Challenge – Mini App**

**Objective:** Combine everything:

1. Add random students (`Student` class).
2. Display all students and top scorers (DOM + FP).
3. Include `SpecialStudent` subclass with unique skills.
4. Use **arrow functions** for methods and callbacks.
5. Compute average score and display in HTML.

**Sample Bonus HTML Element:**

```html
<p id="avgScore">Average Score: </p>
```

**JS:**

```javascript
document.getElementById("showStudentsBtn").addEventListener("click", () => {
    studentList.innerHTML = "";
    students.forEach(s => {
        const li = document.createElement("li");
        li.textContent = `${s.name} - ${s.score}`;
        studentList.appendChild(li);
    });

    const avgScore = students.reduce((acc,s)=>acc+s.score,0)/(students.length||1);
    document.getElementById("avgScore").textContent = `Average Score: ${avgScore.toFixed(2)}`;
});
```

---

### ✅ **Lab 6 – Checkpoints & Exercises**

| Step | Exercise                                             | Checkpoint               |
| ---- | ---------------------------------------------------- | ------------------------ |
| 1    | Create `Teacher` class with arrow function `teach()` | Works in console         |
| 2    | Add multiple students dynamically                    | Students array grows     |
| 3    | Display students in DOM using FP                     | List appears             |
| 4    | Filter top scorers (≥70) using FP                    | Correct output           |
| 5    | Compose score transformations                        | Original array unchanged |
| 6    | Add `SpecialStudent` with skill                      | Can call `.showSkill()`  |
| 7    | Integration: Add + Display + Top + Avg               | Full mini-app working    |

---

### **OOP & FP Mental Models Recap**

* **OOP:** Objects encapsulate state & behavior → real-world modeling → reusable & maintainable.
* **FP:** Functions are **pure, composable, immutable** → predictable transformations → easier reasoning.
* **Arrow Functions:** Concise syntax, `this` bound lexically → perfect for callbacks and FP pipelines.
* **Combination:** Use **OOP for structure**, **FP for data processing**, **DOM for interactivity**, **arrow functions for clean syntax**.

---

### **Suggested Flow in JS-Labs**

```
Lab 1 → Core JS
Lab 2 → DOM
Lab 3 → Modern JS
Lab 4 → Error Handling
Lab 5 → Digital Clock
Lab 6 → OOP & FP Integration
```

---

