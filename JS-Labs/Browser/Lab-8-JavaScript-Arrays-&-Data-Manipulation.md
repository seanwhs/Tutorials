# Lab 8: JavaScript Arrays & Data Manipulation

This lab focuses on the fundamental concepts of JavaScript Arrays, shifting from basic storage to functional transformations and memory architecture.

---

## 🛠 Prerequisites

Ensure your project structure is set up as follows:

* **`index.html`**: The UI entry point.
* **`main.js`**: Where you will write your logic.
* **Console**: Keep your Browser Developer Tools open (`F12`).

---

## Part 1: Array Basics & Dynamic Typing

JavaScript arrays are **dynamic** and **heterogeneous** (they can hold different data types at once).

### Task 1.1: Initialization and Indexing

Update your `main.js` with the following:

```javascript
let friends = ['Peter', 'James', 'John', 'Martha'];

// Accessing by index (0-based)
console.log(friends[0]); // Peter

// Modifying an element
friends[1] = 'Amos'; 

// Adding new elements dynamically
friends[4] = 'Mary';
friends[5] = 100.5; // Number
friends[6] = true;  // Boolean

console.log(friends);

```

### 🧠 Architectural Insight: The Memory Heap

When you create an array, the variable `friends` is stored in the **Stack**, but the actual data (the array) is stored in the **Memory Heap**. The variable in the stack merely holds a **reference** (address) to that memory location.

---

## Part 2: Array Methods (The "Big Three")

In modern JavaScript, we prefer **Functional Programming (FP)** patterns over manual `for` loops. These methods are "Pure Functions"—they don't mutate the original array but return a new one.

### Task 2.1: `.filter()` - Selecting Data

Create a new array containing only friends whose names have more than 4 letters.

```javascript
const longNames = friends.filter(name => typeof name === 'string' && name.length > 4);
console.log("Long Names:", longNames);

```

### Task 2.2: `.map()` - Transforming Data

Transform the array to be all uppercase.

```javascript
const loudFriends = friends
    .filter(f => typeof f === 'string') // Clean the data first
    .map(f => f.toUpperCase());

console.log("Uppercase Friends:", loudFriends);

```

### Task 2.3: `.reduce()` - Condensing Data

Calculate the total length of all strings in the array.

```javascript
const totalChars = friends
    .filter(f => typeof f === 'string')
    .reduce((acc, current) => acc + current.length, 0);

console.log("Total Characters:", totalChars);

```

---

## Part 3: Advanced Manipulation & Spread Operators

To follow **Immutability** principles, we avoid methods like `.push()` which change the original array. Instead, we use the **Spread Operator (`...`)**.

### Task 3.1: Immutable Addition

```javascript
// Adding a friend without changing the original 'friends' array
const moreFriends = [...friends, 'Lazarus'];

console.log("Original:", friends);
console.log("New Copy:", moreFriends);

```

---

## 🧪 Challenge Lab: The Task Orchestrator

Apply what you've learned. Write a script that:

1. Creates an array of objects called `tasks` (each task should have a `title` and a `priority` level 1-5).
2. Uses `.filter()` to find tasks with a priority higher than 3.
3. Uses `.map()` to return just the titles of those high-priority tasks.
4. Logs the result to the console.

**Why this matters:**
This pattern (Filter -> Map) is the foundation of modern UI frameworks like React and Vue, where we transform raw data into a list of visual components.

---

## 🚨 Best Practices Review

* **Performance**: Use `friends.length = 0` to quickly clear an array instead of reassignment.
* **Security**: When displaying array data in HTML, use `textContent` rather than `innerHTML` to prevent XSS (Cross-Site Scripting).
* **Memory**: Always nullify large arrays if they are no longer needed to assist the **Garbage Collector**.
