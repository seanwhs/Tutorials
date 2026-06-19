# JavaScript Fundamentals — Student Handbook

*Version 1.0 — Guide for Modern JavaScript Development*

***

## 1.0 Introduction to JavaScript Fundamentals

JavaScript is the programming language of the web. It powers interactive websites, modern web applications, server-side backends, mobile apps, and even desktop software. Understanding JavaScript fundamentals is essential for anyone pursuing full-stack web development, React development, or AI-integrated coding workflows.

This handbook provides a comprehensive, verbose, and example-rich exploration of JavaScript from the ground up. Every concept includes detailed explanations, multiple code examples, common pitfalls, best practices, and practical exercises to ensure deep understanding.

Whether you're a beginner starting your coding journey or an experienced developer looking to solidify your JavaScript foundation before moving to React or full-stack development, this handbook will equip you with the knowledge and skills needed to write modern, efficient, and maintainable JavaScript code.

***

## 1.1 Learning Objectives

By the end of this course, you will be able to:

### 1.1.1 Understand JavaScript Fundamentals and Modern Syntax
- Explain how JavaScript executes in different environments (browser vs Node.js)
- Understand the JavaScript runtime, event loop, and execution context
- Write code using modern ES6+ syntax confidently
- Recognize and apply best practices for clean, readable code

### 1.1.2 Work Effectively with Data Structures (Arrays, Objects)
- Master array manipulation using modern methods (map, filter, reduce)
- Understand object property access, iteration, and transformation
- Choose appropriate data structures for specific problems
- Implement common algorithms using JavaScript data structures

### 1.1.3 Manipulate the DOM and Handle User Events
- Select and traverse DOM elements efficiently
- Modify content, styles, and structure dynamically
- Create, insert, and remove elements programmatically
- Handle user interactions (clicks, form submissions, keyboard events)
- Build interactive web applications without frameworks

### 1.1.4 Write Asynchronous Code Using Promises and async/await
- Understand synchronous vs asynchronous execution
- Master callback patterns and their limitations
- Work with Promise objects and chain asynchronous operations
- Use async/await for clean, readable asynchronous code
- Handle errors in asynchronous code effectively

### 1.1.5 Use Modern ES6+ Features Confidentally
- Apply destructuring for arrays and objects
- Use spread and rest operators effectively
- Implement optional chaining and nullish coalescing
- Work with modules (import/export) for code organization
- Leverage template literals, arrow functions, and classes

### 1.1.6 Debug JavaScript Applications
- Use browser DevTools effectively
- Set breakpoints and inspect execution
- Identify and fix common JavaScript errors
- Understand error types and stack traces
- Implement logging and debugging strategies

### 1.1.7 Build a Foundation for React and Full-Stack Development
- Understand concepts that React builds upon (components, state, events)
- Prepare for framework-specific patterns and philosophies
- Build confidence in reading and writing modern JavaScript
- Transition smoothly to React, Next.js, and backend development

***

## 1.2 Why JavaScript Matters

JavaScript is unique among programming languages for several reasons:

### 1.2.1 Universal Reach
- **Frontend**: Runs in every browser (Chrome, Firefox, Safari, Edge)
- **Backend**: Node.js enables server-side development
- **Mobile**: Frameworks like React Native build mobile apps
- **Desktop**: Electron enables desktop application development
- **Embedded**: JavaScript runs on IoT devices and microcontrollers

### 1.2.2 Ecosystem and Community
- Largest package repository (npm with 2+ million packages)
- Massive community support (Stack Overflow, GitHub, forums)
- Continuous innovation (annual ES specifications)
- Industry adoption (Google, Facebook, Amazon, Microsoft)

### 1.2.3 Career Opportunities
- Highest demand among programming languages
- Full-stack developer roles (frontend + backend)
- Specialized roles (React developer, Node.js developer)
- Freelance and consulting opportunities
- Startup and enterprise positions

***

## 1.3 Module 1: JavaScript Basics & Setup

### 1.3.1 Language, Runtime, and Output

JavaScript is a **high-level**, **interpreted** (or compiled), **dynamic**, **single-threaded**, **prototypal** programming language with **first-class functions**.

#### Key Characteristics

| Characteristic | Explanation |
|---------------|-------------|
| High-level | Abstracts memory management and hardware details |
| Dynamic | Types are checked at runtime, not compile time |
| Single-threaded | Executes one operation at a time |
| Asynchronous | Can handle non-blocking operations via event loop |
| Prototypal | Uses prototypes for inheritance (not classes) |
| First-class functions | Functions can be passed as arguments, returned from other functions |

#### JavaScript Runtime

The runtime is the environment where JavaScript executes:

```javascript
// Browser Runtime
console.log("Running in browser");
document.querySelector("h1"); // DOM access

// Node.js Runtime
console.log("Running in Node.js");
console.log(process.version); // Node-specific API
```

#### Output Methods

```javascript
// Console output (most common)
console.log("Hello, world!");
console.info("Information message");
console.warn("Warning message");
console.error("Error message");

// Browser-specific output
alert("Alert popup");
document.write("Written to document");

// Node.js specific
process.stdout.write("Node output\n");
```

### 1.3.2 Browser vs Node.js

Understanding the differences between these environments is crucial:

#### Browser Environment

```javascript
// Browser-only APIs
const element = document.querySelector("#app");
window.addEventListener("resize", () => {});
fetch("https://api.example.com/data");

// Browser global object
console.log(window); // Global object in browser
console.log(document); // DOM document
console.log navigator; // Browser information
```

**Key Browser Features:**
- DOM (Document Object Model) manipulation
- CSS manipulation via style properties
- Browser events (click, submit, keypress)
- LocalStorage, SessionStorage
- Fetch API for network requests
- Geolocation, Canvas, Web Audio APIs

#### Node.js Environment

```javascript
// Node.js-only APIs
console.log(process.version);
const fs = require("fs");
fs.readFile("file.txt", "utf8", (err, data) => {});

// Node.js global object
console.log(global); // Global object in Node.js
```

**Key Node.js Features:**
- File system access (fs module)
- HTTP server creation
- Process management
- Package management (npm)
- Database connections
- No DOM access

#### Cross-Environment Code

```javascript
// Code that works in both environments
function greet(name) {
  return `Hello, ${name}!`;
}

console.log(greet("Sean")); // Works in both

// Detect environment
if (typeof window !== "undefined") {
  console.log("Running in browser");
} else if (typeof process !== "undefined") {
  console.log("Running in Node.js");
}
```

### 1.3.3 How JavaScript Runs

JavaScript execution involves several stages:

#### Execution Flow

```javascript
// 1. Parsing - JavaScript engine reads code
function calculate(a, b) {
  // 2. Compilation - Code converted to optimized machine code
  return a + b;
  
  // 3. Execution - Code actually runs
}

const result = calculate(5, 3);
console.log(result); // 8
```

#### The Event Loop

JavaScript is single-threaded but handles asynchronous operations via the event loop:

```javascript
console.log("1. Start");

setTimeout(() => {
  console.log("2. Timeout callback");
}, 1000);

console.log("3. End");

// Output order:
// 1. Start
// 3. End
// 2. Timeout callback (after 1 second)
```

**Event Loop Phases:**
1. **Call Stack**: Executes synchronous code
2. **Web APIs**: Browser provides APIs (setTimeout, fetch)
3. **Task Queue**: Callbacks wait here
4. **Event Loop**: Moves callbacks from queue to call stack

### 1.3.4 First JavaScript File + console.log()

#### Creating Your First File

```html
<!-- index.html -->
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>My First JS</title>
</head>
<body>
  <h1>Hello, JavaScript!</h1>
  
  <!-- Method 1: Inline script -->
  <script>
    console.log("Script running inline");
  </script>
  
  <!-- Method 2: External file -->
  <script src="app.js"></script>
</body>
</html>
```

```javascript
// app.js - External JavaScript file
console.log("Hello from external file!");

const message = "Welcome to JavaScript";
console.log(message);
```

#### console.log() Deep Dive

```javascript
// Basic usage
console.log("Simple string");
console.log(42);
console.log(true);
console.log(null);

// Multiple arguments
console.log("Name:", "Sean", "Age:", 30);
// Output: Name: Sean Age: 30

// Object inspection
const user = {
  name: "Sean",
  age: 30,
  isActive: true
};
console.log(user);
// Shows expandable object in console

// Array inspection
const numbers = [1, 2, 3, 4, 5];
console.log(numbers);
// Shows expandable array

// Template literals in console
console.log(`User ${user.name} is ${user.age} years old`);

// Console methods
console.info("This is info");
console.warn("This is a warning");
console.error("This is an error");

// Console formatting
console.log("%cStyled text", "color: blue; font-size: 20px;");
console.log("Number: %d, String: %s, Hex: %x", 42, "hello", 255);

// Timing operations
console.time("Operation");
// Some operation here
setTimeout(() => {
  console.timeEnd("Operation");
  // Output: Operation: 1000.123ms
}, 1000);

// Grouping logs
console.group("User Data");
console.log("Name: Sean");
console.log("Age: 30");
console.groupEnd();

// Conditional logging
const isAdmin = true;
console.log(isAdmin && "Admin access enabled");
```

### 1.3.5 Variables: const, let, var

Variable declaration determines how and where values can be stored and modified.

#### const (Constant)

```javascript
// Declaration and assignment required together
const age = 30;

// Cannot be reassigned
age = 31; // TypeError: Assignment to constant variable

// Works with all data types
const name = "Sean";
const isActive = true;
const user = { name: "Sean", age: 30 };
const numbers = [1, 2, 3];

// Object reference is constant, but properties can change
user.age = 31; // Valid - modifying property
user = { name: "New" }; // TypeError - cannot reassign

// Arrays: reference constant, contents can change
const list = [1, 2, 3];
list.push(4); // Valid - modifying array
list = [5, 6]; // TypeError - cannot reassign

// Best practice: Use const by default
const API_URL = "https://api.example.com";
const MAX_USERS = 100;
const DEFAULT_NAME = "Anonymous";
```

#### let (Variable)

```javascript
// Can be reassigned
let count = 0;
count = 1; // Valid
count = count + 1; // Valid

// Works with all data types
let name = "Sean";
let age = 30;
let isActive = true;

// Use when value needs to change
let counter = 0;
for (let i = 0; i < 5; i++) {
  counter += i;
}
console.log(counter); // 10

// Loop variables
let total = 0;
const numbers = [1, 2, 3, 4, 5];
for (let i = 0; i < numbers.length; i++) {
  total += numbers[i];
}
```

#### var (Legacy - Avoid)

```javascript
// Old way of declaring variables (pre-ES6)
var name = "Sean";
var age = 30;

// Problems with var:
// 1. Function-scoped only (not block-scoped)
if (true) {
  var blockVar = "Inside block";
}
console.log(blockVar); // Works - var is NOT block-scoped

// 2. Can be redeclared
var name = "Sean";
var name = "Wong"; // No error - silently overwrites

// 3. Hoisted to top of function
console.log(hoisted); // undefined (not error)
var hoisted = "I'm hoisted";

// 4. No let/const equivalent until ES6
// Modern code should NOT use var

// Modern replacement
const constantName = "Sean";
let variableName = "Sean";
```

#### Variable Declaration Comparison

| Feature | const | let | var |
|---------|-------|-----|-----|
| Reassignment | ❌ No | ✅ Yes | ✅ Yes |
| Block Scope | ✅ Yes | ✅ Yes | ❌ No |
| Redeclaration | ❌ No | ❌ No | ✅ Yes |
| Hoisting | ✅ Yes (uninitialized) | ✅ Yes (uninitialized) | ✅ Yes (initialized as undefined) |
| Use Case | Fixed values | Changing values | Avoid (legacy) |

#### Best Practices for Variable Declaration

```javascript
// ✅ BEST: Use const by default
const API_KEY = "abc123";
const MAX_RETRIES = 3;
const userName = "Sean";

// ✅ Use let when reassignment is needed
let count = 0;
count++;
count++;

// ❌ AVOID: var
var oldVariable = "deprecated";

// ✅ Naming conventions
// Use descriptive names
const numberOfUsers = 100; // Not: num, n
const isUserActive = true; // Not: flag, b
const getUserById = (id) => {}; // Not: fn, func

// Use camelCase for variables and functions
const userName = "Sean";
function calculateTotal() {}

// Use UPPER_SNAKE_CASE for constants
const API_URL = "https://api.com";
const MAX_LENGTH = 100;

// Avoid single-letter names (except in loops)
for (let i = 0; i < 10; i++) { // i is acceptable
  const index = i; // Better than i for non-loop usage
}

// Declare variables close to usage
function processData(items) {
  const filtered = items.filter(item => item.active);
  return filtered.map(item => item.name);
}

// Don't declare variables at top of function unnecessarily
function calculate() {
  // Don't do this:
  const a = 0;
  const b = 0;
  const c = 0;
  
  // Do this:
  const a = calculateA();
  const b = calculateB(a);
  const c = calculateC(b);
}
```

### 1.3.6 Naming Conventions

Proper naming makes code readable, maintainable, and professional.

#### Variable Naming Rules

```javascript
// ✅ Valid names
let userName;
let user_name;
let UserName;
let $element;
let _private;
let count123;

// ❌ Invalid names
let user-name; // Hyphen not allowed
let user name; // Space not allowed
let 123user; // Cannot start with number
let var; // Reserved keyword
let class; // Reserved keyword
```

#### Naming Conventions by Type

```javascript
// Variables and Functions: camelCase
const userName = "Sean";
let counter = 0;
function calculateTotal() {}
const getUserById = (id) => {};

// Classes: PascalCase (capital first letter)
class User {
  constructor(name) {
    this.name = name;
  }
}
const UserController = {};

// Constants: UPPER_SNAKE_CASE
const API_URL = "https://api.example.com";
const MAX_USERS = 100;
const DEFAULT_COLOR = "#000000";

// Private variables: underscore prefix
class'user' {
  constructor(name) {
    this._privateField = name; // Convention only, not truly private
  }
}

// DOM elements: camelCase with elem/el suffix
const headerElement = document.querySelector("#header");
const buttonEl = document.querySelector(".btn");

// API responses: camelCase
const userData = {
  id: 1,
  name: "Sean",
  email: "sean@example.com"
};

// Boolean variables: is/has/can prefix
const isActive = true;
const hasPermission = false;
const canEdit = true;

// Array variables: plural nouns
const users = ["Sean", "Wong"];
const numbers = [1, 2, 3];
const items = [];

// Function names: verb or verb + noun
function calculateTotal() {}
function getUserById() {}
function validateEmail() {}
function fetchData() {}

// Event handlers: on + event name
const onClick = () => {};
const onSubmit = (e) => {};
const onKeyPress = (e) => {};
```

#### Common Naming Mistakes

```javascript
// ❌ Too vague
const data = {};
const temp = 42;
const x = 10;
const fn = () => {};

// ✅ Clear and descriptive
const userProfile = {};
const temperature = 42;
const userId = 10;
const calculateTotal = () => {};

// ❌ Mixed conventions
const userName = "Sean";
const USER_AGE = 30;
function calculateTotal() {}
const MAX_ITEMS = 100;

// ✅ Consistent conventions
const userName = "Sean";
const userAge = 30;
function calculateTotal() {}
const maxItems = 100;

// ❌ Misleading names
const userList = []; // Actually an array
const userCount = 5; // Actually a string
const isActive = "true"; // Actually a string

// ✅ Accurate names
const users = [];
const count = 5;
const isActive = true;
```

***

## 1.4 Module 2: Data Types & Core Concepts

### 1.4.1 Primitive Data Types

JavaScript has **seven** primitive data types. Primitives are immutable (cannot be changed) and are stored by value.

#### Number

```javascript
// Integer and floating-point
const integer = 42;
const floating = 3.14;
const negative = -10;

// Special number values
const infinity = Infinity;
const negativeInfinity = -Infinity;
const notANumber = NaN; // Not a Number

// Number methods
console.log(Number.isInteger(42)); // true
console.log(Number.isInteger(3.14)); // false
console.log(Number.isNaN(NaN)); // true
console.log(Number.parseFloat("3.14")); // 3.14
console.log(Number.parseInt("42")); // 42

// Math object
console.log(Math.PI); // 3.14159...
console.log(Math.round(3.14)); // 3
console.log(Math.ceil(3.14)); // 4
console.log(Math.floor(3.14)); // 3
console.log(Math.random()); // 0-1 random
console.log(Math.max(1, 2, 3)); // 3
console.log(Math.min(1, 2, 3)); // 1

// Large numbers with BigInt
const hugeNumber = BigInt(9007199254740991);
console.log(hugeNumber); // 9007199254740991n
```

#### String

```javascript
// String creation
const str1 = "Hello";
const str2 = 'World';
const str3 = `Template`;

// String is immutable
const name = "Sean";
name[0] = "S"; // Does NOT work
console.log(name); // "Sean"

// String methods
console.log(name.length); // 4
console.log(name.toUpperCase()); // "SEAN"
console.log(name.toLowerCase()); // "sean"
console.log(name.charAt(0)); // "S"
console.log(name.indexOf("a")); // 1
console.log(name.includes("ea")); // true
console.log(name.slice(1, 3)); // "ea"
console.log(name.replace("S", "J")); // "Jean"
console.log(name.split("")); // ["S","e","a","n"]
console.log(name.trim()); // Removes whitespace

// Template literals (ES6)
const userName = "Sean";
const age = 30;
const message = `Hello, ${userName}! You are ${age} years old.`;
console.log(message); // "Hello, Sean! You are 30 years old."

// Multi-line strings
const multiLine = `Line 1
Line 2
Line 3`;
console.log(multiLine);

// String escaping
const quote = "He said \"Hello\"";
const backslash = "Path\\to\\file";
console.log(quote); // "He said "Hello""
console.log(backslash); // "Path\to\file"
```

#### Boolean

```javascript
// Boolean values
const isActive = true;
const isDisabled = false;

// Boolean conversion
console.log(Boolean(1)); // true
console.log(Boolean(0)); // false
console.log(Boolean("")); // false
console.log(Boolean("hello")); // true
console.log(Boolean(null)); // false
console.log(Boolean(undefined)); // false

// Truthy and falsy values
// Falsy: false, 0, "", null, undefined, NaN
// Truthy: everything else

if (0) {
  console.log("This won't run");
}

if ("hello") {
  console.log("This will run"); // "This will run"
}

// Boolean operations
console.log(true && false); // false (AND)
console.log(true || false); // true (OR)
console.log(!true); // false (NOT)
```

#### Null

```javascript
// Null represents "no value" or "empty"
const emptyValue = null;

// Common use cases
let user = null; // User not loaded yet
user = { name: "Sean" }; // User loaded

// Null vs undefined
const nullValue = null; // Explicitly empty
const undefinedValue = undefined; // Not assigned

// Null checking
console.log(nullValue === null); // true
console.log(undefinedValue === null); // false
console.log(nullValue == undefined); // true (loose equality)

// Optional: Use null for intentional emptiness
function getUser(id) {
  const user = findUser(id);
  return user || null; // Return null if not found
}
```

#### Undefined

```javascript
// Undefined means "not assigned"
let uninitialized;
console.log(uninitialized); // undefined

// Function without return
function noReturn() {}
console.log(noReturn()); // undefined

// Accessing non-existent property
const user = { name: "Sean" };
console.log(user.age); // undefined

// Undefined checking
console.log(uninitialized === undefined); // true
console.log(typeof uninitialized === "undefined"); // true

// Default values with undefined
function greet(name = "Anonymous") {
  return `Hello, ${name}`;
}
console.log(greet()); // "Hello, Anonymous"
console.log(greet("Sean")); // "Hello, Sean"
```

#### BigInt

```javascript
// BigInt for arbitrarily large integers
const huge = BigInt(9007199254740991);
const alsoHuge = 9007199254740991n; // Literal syntax

console.log(huge); // 9007199254740991n
console.log(alsoHuge); // 9007199254740991n

// BigInt operations
console.log(huge + alsoHuge); // 18014398509481982n
console.log(huge * 2); // 18014398509481982n

// Cannot mix BigInt with regular numbers
// huge + 1; // TypeError
console.log(huge + BigInt(1)); // Valid

// Convert to regular number
console.log(Number(huge)); // 9007199254740991
```

#### Symbol

```javascript
// Symbol for unique identifiers
const sym1 = Symbol("id");
const sym2 = Symbol("id");

console.log(sym1 === sym2); // false - always unique

// Symbol usage in objects
const user = {
  name: "Sean",
  [sym1]: 123
};

console.log(user[sym1]); // 123

// Symbols are not enumerated
console.log(Object.keys(user)); // ["name"]
```

### 1.4.2 Non-Primitive Data Types

#### Object

```javascript
// Object creation
const user = {
  name: "Sean",
  age: 30,
  isActive: true
};

// Property access
console.log(user.name); // "Sean"
console.log(user["age"]); // 30

// Dynamic property access
const key = "name";
console.log(user[key]); // "Sean"

// Adding properties
user.email = "sean@example.com";
user["city"] = "Singapore";

// Deleting properties
delete user.isActive;
console.log(user); // { name: "Sean", age: 30, email: "...", city: "Singapore" }

// Object methods
console.log(Object.keys(user)); // ["name", "age", "email", "city"]
console.log(Object.values(user)); // ["Sean", 30, "sean@example.com", "Singapore"]
console.log(Object.entries(user)); // [["name","Sean"],["age",30],...]

// Object cloning
const cloned = Object.assign({}, user);
const cloned2 = { ...user }; // Spread operator (ES6)

// Object.freeze (immutable)
const frozen = Object.freeze({ name: "Sean" });
frozen.age = 30; // Does NOT work
```

#### Array

```javascript
// Array creation
const numbers = [1, 2, 3, 4, 5];
const mixed = [1, "hello", true, null];
const empty = [];

// Array access
console.log(numbers[0]); // 1
console.log(numbers[numbers.length - 1]); // 5

// Array methods
const arr = [1, 2, 3];

arr.push(4); // Add to end: [1,2,3,4]
arr.pop(); // Remove from end: [1,2,3]
arr.unshift(0); // Add to start: [0,1,2,3]
arr.shift(); // Remove from start: [1,2,3]

console.log(arr.indexOf(2)); // 1
console.log(arr.includes(2)); // true
console.log(arr.length); // 3

// Array iteration
numbers.forEach(num => console.log(num));

// Array to string
console.log(numbers.join("-")); // "1-2-3-4-5"
```

### 1.4.3 Type coercion and Conversion

```javascript
// Implicit coercion
console.log(5 + "5"); // "55" (number + string = string)
console.log(5 - "2"); // 3 (string converted to number)
console.log(true + 1); // 2 (true = 1)

// Explicit conversion
console.log(Number("42")); // 42
console.log(String(42)); // "42"
console.log(Boolean(1)); // true

// parseInt and parseFloat
console.log(parseInt("42px")); // 42
console.log(parseFloat("3.14abc")); // 3.14

// Template literals convert automatically
console.log(`Value: ${42}`); // "Value: 42"
```

### 1.4.4 Operators & Control Flow

#### Arithmetic Operators

```javascript
// Basic arithmetic
console.log(10 + 5); // 15 (addition)
console.log(10 - 5); // 5 (subtraction)
console.log(10 * 5); // 50 (multiplication)
console.log(10 / 5); // 2 (division)
console.log(10 % 3); // 1 (remainder)
console.log(10 ** 2); // 100 (exponentiation)

// Increment and decrement
let count = 5;
count++; // 6
count--; // 4
count += 2; // 6
count -= 2; // 4
count *= 2; // 8
count /= 2; // 4
```

#### Comparison Operators

```javascript
// Equality
console.log(5 === 5); // true (strict equality)
console.log(5 == "5"); // true (loose equality - type coercion)
console.log(5 !== "5"); // true (strict not equal)
console.log(5 != "5"); // false (loose not equal)

// Comparison
console.log(5 > 3); // true
console.log(5 < 3); // false
console.log(5 >= 5); // true
console.log(5 <= 4); // false

// Special comparisons
console.log(NaN === NaN); // false
console.log(Object.isNaN(NaN)); // true
console.log(null === undefined); // false
console.log(null == undefined); // true
```

#### Logical Operators

```javascript
// AND (&&)
console.log(true && true); // true
console.log(true && false); // false
console.log(false && true); // false

// OR (||)
console.log(true || false); // true
console.log(false || false); // false

// NOT (!)
console.log(!true); // false
console.log(!false); // true

// Logical operators with values
console.log(5 && 10); // 10 (returns last truthy)
console.log(0 && 10); // 0 (returns first falsy)
console.log(5 || 10); // 5 (returns first truthy)
console.log(0 || 10); // 10

// Short-circuit evaluation
function getValue() {
  console.log("Called");
  return 42;
}

console.log(true && getValue()); // "Called", 42
console.log(false && getValue()); // Not called, false
```

#### if/else Statements

```javascript
// Basic if/else
const age = 18;

if (age >= 18) {
  console.log("Adult");
} else {
  console.log("Minor");
}

// Multiple conditions
const score = 85;

if (score >= 90) {
  console.log("A");
} else if (score >= 80) {
  console.log("B");
} else if (score >= 70) {
  console.log("C");
} else {
  console.log("F");
}

// Ternary operator (short if/else)
const status = age >= 18 ? "Adult" : "Minor";
console.log(status); // "Adult"

// Multiple conditions with &&
const day = "Monday";
const isHourly = true;

if (day === "Monday" && isHourly) {
  console.log("Monday hourly shift");
}

// Multiple conditions with ||
if (day === "Saturday" || day === "Sunday") {
  console.log("Weekend");
}
```

#### switch Statements

```javascript
// Basic switch
const role = "admin";

switch (role) {
  case "admin":
    console.log("Full access");
    break;
  case "user":
    console.log("Limited access");
    break;
  case "guest":
    console.log("No access");
    break;
  default:
    console.log("Unknown role");
}

// Multiple cases
const day = "Monday";

switch (day) {
  case "Monday":
  case "Tuesday":
  case "Wednesday":
  case "Thursday":
  case "Friday":
    console.log("Workday");
    break;
  case "Saturday":
  case "Sunday":
    console.log("Weekend");
    break;
  default:
    console.log("Invalid day");
}

// Switch with expressions
const score = 85;

switch (true) {
  case (score >= 90):
    console.log("A");
    break;
  case (score >= 80):
    console.log("B");
    break;
  default:
    console.log("Below B");
}
```

#### Loops

```javascript
// for loop
for (let i = 0; i < 5; i++) {
  console.log(i); // 0, 1, 2, 3, 4
}

// for loop with array
const numbers = [1, 2, 3, 4, 5];
for (let i = 0; i < numbers.length; i++) {
  console.log(numbers[i]); // 1, 2, 3, 4, 5
}

// while loop
let count = 0;
while (count < 5) {
  console.log(count);
  count++;
}

// do...while loop (runs at least once)
let num = 0;
do {
  console.log(num);
  num++;
} while (num < 5);

// break and continue
for (let i = 0; i < 10; i++) {
  if (i === 5) {
    break; // Exit loop
  }
  console.log(i); // 0, 1, 2, 3, 4
}

for (let i = 0; i < 5; i++) {
  if (i === 2) {
    continue; // Skip this iteration
  }
  console.log(i); // 0, 1, 3, 4
}
```

***

## 1.5 Module 3: Functions & Scope

### 1.5.1 Function Types

#### Function Declaration

```javascript
// Classic function declaration
function greet(name) {
  return `Hello, ${name}!`;
}

console.log(greet("Sean")); // "Hello, Sean!"

// Function with multiple parameters
function add(a, b) {
  return a + b;
}

console.log(add(5, 3)); // 8

// Function with default parameters
function multiply(a, b = 1) {
  return a * b;
}

console.log(multiply(5)); // 5
console.log(multiply(5, 3)); // 15

// Function with rest parameters
function sum(...numbers) {
  return numbers.reduce((acc, num) => acc + num, 0);
}

console.log(sum(1, 2, 3, 4, 5)); // 15
```

#### Function Expression

```javascript
// Function assigned to variable
const greet = function(name) {
  return `Hello, ${name}!`;
};

console.log(greet("Sean")); // "Hello, Sean!"

// Anonymous function expression
const anonymous = function() {
  console.log("No name");
};

// Function expression with default params
const multiply = function(a, b = 1) {
  return a * b;
};
```

#### Arrow Functions (ES6)

```javascript
// Basic arrow function
const greet = (name) => {
  return `Hello, ${name}!`;
};

console.log(greet("Sean")); // "Hello, Sean!"

// Short form (single expression)
const greet = (name) => `Hello, ${name}!`;

// No parameters
const sayHello = () => {
  console.log("Hello!");
};

// Single parameter (no parentheses)
const double = x => x * 2;

// Multiple parameters
const add = (a, b) => a + b;

// Returning object (wrap in parentheses)
const getUser = () => ({ name: "Sean", age: 30 });

// Arrow function with rest params
const sum = (...numbers) => numbers.reduce((acc, num) => acc + num, 0);

// Arrow function with default params
const multiply = (a, b = 1) => a * b;
```

#### Function Declaration vs Expression vs Arrow

| Feature | Declaration | Expression | Arrow |
|---------|-------------|------------|-------|
| Syntax | `function name() {}` | `const fn = function() {}` | `const fn = () => {}` |
| Hoisting | ✅ Yes | ❌ No | ❌ No |
| `this` binding | Dynamic | Dynamic | Lexical |
| Can be constructor | ✅ Yes | ✅ Yes | ❌ No |
| Best for | Named functions | Callbacks | Short functions |

### 1.5.2 Scope

#### Global Scope

```javascript
// Global variable (accessible everywhere)
const globalVar = "I am global";

function accessGlobal() {
  console.log(globalVar); // "I am global"
}

accessGlobal();
console.log(globalVar); // "I am global"

// ⚠️ Avoid global variables
// They cause naming conflicts and make code harder to maintain
```

#### Function Scope

```javascript
function functionScope() {
  const functionVar = "Inside function";
  console.log(functionVar); // "Inside function"
}

functionScope();
console.log(functionVar); // ❌ ReferenceError
```

#### Block Scope

```javascript
// let and const are block-scoped
if (true) {
  const blockVar = "Inside block";
  let blockLet = "Also inside";
  console.log(blockVar); // "Inside block"
}

console.log(blockVar); // ❌ ReferenceError

// var is NOT block-scoped
if (true) {
  var varInBlock = "Inside";
}
console.log(varInBlock); // "Inside" (var leaks out)
```

#### Scope Chain

```javascript
const global = "global";

function outer() {
  const outerVar = "outer";
  
  function inner() {
    const innerVar = "inner";
    console.log(global); // "global" (from global scope)
    console.log(outerVar); // "outer" (from outer function scope)
    console.log(innerVar); // "inner" (from inner function scope)
  }
  
  inner();
}

outer();
```

### 1.5.3 Closures

A closure is a function that remembers variables from its outer scope.

```javascript
// Basic closure
function createCounter() {
  let count = 0;
  
  return function() {
    count++;
    return count;
  };
}

const counter = createCounter();
console.log(counter()); // 1
console.log(counter()); // 2
console.log(counter()); // 3

// Closure with multiple functions
function createPerson(name) {
  let age = 0;
  
  return {
    getName: () => name,
    getAge: () => age,
    grow: () => age++
  };
}

const person = createPerson("Sean");
console.log(person.getName()); // "Sean"
console.log(person.getAge()); // 0
person.grow();
console.log(person.getAge()); // 1

// Closure for data privacy
function createBankAccount(initialBalance) {
  let balance = initialBalance;
  
  return {
    deposit: (amount) => {
      balance += amount;
      return balance;
    },
    withdraw: (amount) => {
      if (amount <= balance) {
        balance -= amount;
        return balance;
      }
      return "Insufficient funds";
    },
    getBalance: () => balance
  };
}

const account = createBankAccount(1000);
console.log(account.deposit(500)); // 1500
console.log(account.withdraw(200)); // 1300
console.log(account.getBalance()); // 1300
console.log(account.withdraw(2000)); // "Insufficient funds"
```

### 1.5.4 Higher-Order Functions

Functions that take other functions as arguments or return functions.

```javascript
// Function as argument
function applyOperation(num, operation) {
  return operation(num);
}

const double = x => x * 2;
const square = x => x * x;

console.log(applyOperation(5, double)); // 10
console.log(applyOperation(5, square)); // 25

// Function returning function
function createMultiplier(factor) {
  return function(num) {
    return num * factor;
  };
}

const double = createMultiplier(2);
const triple = createMultiplier(3);

console.log(double(5)); // 10
console.log(triple(5)); // 15

// Common higher-order functions
const numbers = [1, 2, 3, 4, 5];

// map - transforms each element
const doubled = numbers.map(x => x * 2);
console.log(doubled); // [2, 4, 6, 8, 10]

// filter - keeps elements that pass test
const evens = numbers.filter(x => x % 2 === 0);
console.log(evens); // [2, 4]

// reduce - accumulates to single value
const sum = numbers.reduce((acc, x) => acc + x, 0);
console.log(sum); // 15

// find - returns first matching element
const firstEven = numbers.find(x => x % 2 === 0);
console.log(firstEven); // 2

// some - checks if any element passes test
const hasEven = numbers.some(x => x % 2 === 0);
console.log(hasEven); // true

// every - checks if all elements pass test
const allPositive = numbers.every(x => x > 0);
console.log(allPositive); // true
```

***

## 1.6 Module 4: Data Structures In Depth

### 1.6.1 Arrays

#### Array Creation and Basic Operations

```javascript
// Creating arrays
const numbers = [1, 2, 3, 4, 5];
const mixed = [1, "hello", true, null];
const empty = [];
const fromConstructor = new Array(1, 2, 3);

// Array length
console.log(numbers.length); // 5

// Accessing elements
console.log(numbers[0]); // 1
console.log(numbers[4]); // 5
console.log(numbers[-1]); // undefined (not like Python)

// Modifying elements
numbers[0] = 10;
console.log(numbers); // [10, 2, 3, 4, 5]

// Adding elements
numbers[5] = 6; // Adds at index 5
numbers.push(7); // Adds to end
console.log(numbers); // [10, 2, 3, 4, 5, 6, 7]

// Removing elements
numbers.pop(); // Removes from end
numbers.shift(); // Removes from start
console.log(numbers); // [2, 3, 4, 5, 6]
```

#### Core Array Methods

```javascript
const arr = [1, 2, 3, 4, 5];

// push/pop - add/remove from end
arr.push(6); // [1,2,3,4,5,6]
arr.pop(); // [1,2,3,4,5]

// shift/unshift - add/remove from start
arr.unshift(0); // [0,1,2,3,4,5]
arr.shift(); // [1,2,3,4,5]

// slice - copy part of array (non-mutating)
const sliced = arr.slice(1, 3); // [2, 3]
console.log(arr); // [1,2,3,4,5] (unchanged)

// splice - modify array (mutating)
const spliced = arr.splice(1, 2); // removes 2 elements at index 1
console.log(arr); // [1, 4, 5]
console.log(spliced); // [2, 3]

// concat - join arrays
const arr2 = [6, 7, 8];
const combined = arr.concat(arr2); // [1,2,3,4,5,6,7,8]

// join - convert array to string
console.log(arr.join("-")); // "1-4-5"
console.log(arr.join("")); // "145"
```

#### Advanced Array Methods

```javascript
const numbers = [1, 2, 3, 4, 5];

// map - transform each element
const doubled = numbers.map(n => n * 2);
console.log(doubled); // [2, 4, 6, 8, 10]

// filter - keep elements that pass test
const evens = numbers.filter(n => n % 2 === 0);
console.log(evens); // [2, 4]

// reduce - accumulate to single value
const sum = numbers.reduce((acc, n) => acc + n, 0);
console.log(sum); // 15

// find - first element that passes test
const firstEven = numbers.find(n => n % 2 === 0);
console.log(firstEven); // 2

// findIndex - index of first element
const firstEvenIndex = numbers.findIndex(n => n % 2 === 0);
console.log(firstEvenIndex); // 1

// includes - check if array contains value
console.log(numbers.includes(3)); // true
console.log(numbers.includes(10)); // false

// indexOf - index of value
console.log(numbers.indexOf(3)); // 2
console.log(numbers.indexOf(10)); // -1

// some - any element passes test
console.log(numbers.some(n => n > 3)); // true

// every - all elements pass test
console.log(numbers.every(n => n > 0)); // true

// sort - sort array (mutating)
const unsorted = [3, 1, 4, 1, 5];
unsorted.sort(); // [1, 1, 3, 4, 5]
unsorted.sort((a, b) => b - a); // [5, 4, 3, 1, 1]

// reverse - reverse array (mutating)
numbers.reverse(); // [5, 4, 3, 2, 1]

// flat - flatten nested arrays
const nested = [1, [2, 3], [4, [5, 6]]];
console.log(nested.flat()); // [1, 2, 3, 4, [5, 6]]
console.log(nested.flat(2)); // [1, 2, 3, 4, 5, 6]

// forEach - iterate without return
numbers.forEach(n => console.log(n));
```

#### Array Iteration Patterns

```javascript
const numbers = [1, 2, 3, 4, 5];

// Traditional for loop
for (let i = 0; i < numbers.length; i++) {
  console.log(numbers[i]);
}

// for...of loop (ES6)
for (const num of numbers) {
  console.log(num);
}

// forEach method
numbers.forEach((num, index) => {
  console.log(`Index ${index}: ${num}`);
});

// map with index
numbers.map((num, index) => `${index}: ${num}`);

// Reduce with index
numbers.reduce((acc, num, index) => {
  console.log(`Accumulator: ${acc}, Value: ${num}, Index: ${index}`);
  return acc + num;
}, 0);
```

### 1.6.2 Objects

#### Object Creation and Property Access

```javascript
// Object creation
const user = {
  name: "Sean",
  age: 30,
  isActive: true,
  address: {
    city: "Singapore",
    country: "SG"
  }
};

// Property access - dot notation
console.log(user.name); // "Sean"
console.log(user.age); // 30

// Property access - bracket notation
console.log(user["name"]); // "Sean"
console.log(user["age"]); // 30

// Dynamic property access
const key = "name";
console.log(user[key]); // "Sean"

// Accessing nested properties
console.log(user.address.city); // "Singapore"
console.log(user.address["country"]); // "SG"

// Optional chaining (ES2020)
console.log(user.address?.city); // "Singapore"
console.log(user.phone?.number); // undefined (no error)
```

#### Adding, Modifying, and Deleting Properties

```javascript
const user = { name: "Sean" };

// Adding properties
user.age = 30;
user["email"] = "sean@example.com";

// Modifying properties
user.name = "Sean Wong";
user.age = 31;

// Deleting properties
delete user.email;
console.log(user); // { name: "Sean Wong", age: 31 }

// Checking if property exists
console.log(user.name); // "Sean Wong"
console.log(user.email); // undefined
console.log("name" in user); // true
console.log("email" in user); // false
console.log(user.hasOwnProperty("name")); // true
```

#### Object Methods

```javascript
const user = {
  name: "Sean",
  age: 30,
  isActive: true
};

// Object.keys() - get property names
console.log(Object.keys(user)); // ["name", "age", "isActive"]

// Object.values() - get property values
console.log(Object.values(user)); // ["Sean", 30, true]

// Object.entries() - get key-value pairs
console.log(Object.entries(user)); // [["name","Sean"],["age",30],["isActive",true]]

// Object.assign() - copy/merge objects
const defaults = { theme: "dark" };
const settings = { theme: "light", lang: "en" };
const merged = Object.assign({}, defaults, settings);
console.log(merged); // { theme: "light", lang: "en" }

// Spread operator (ES6) - modern alternative
const merged2 = { ...defaults, ...settings };
console.log(merged2); // { theme: "light", lang: "en" }

// Object.freeze() - make immutable
const frozen = Object.freeze({ name: "Sean" });
frozen.age = 30; // Does NOT work
console.log(frozen); // { name: "Sean" }

// Object.defineProperty() - define with options
const obj = {};
Object.defineProperty(obj, "id", {
  value: 1,
  writable: false,
  enumerable: true,
  configurable: false
});
console.log(obj.id); // 1
obj.id = 2; // Does NOT work
```

#### Object Iteration

```javascript
const user = {
  name: "Sean",
  age: 30,
  isActive: true
};

// for...in loop
for (const key in user) {
  console.log(`${key}: ${user[key]}`);
}

// Object.keys() + forEach
Object.keys(user).forEach(key => {
  console.log(`${key}: ${user[key]}`);
});

// Object.entries() + forEach
Object.entries(user).forEach(([key, value]) => {
  console.log(`${key}: ${value}`);
});

// Object.entries() + map
const entries = Object.entries(user).map(([key, value]) => `${key}=${value}`);
console.log(entries); // ["name=Sean", "age=30", "isActive=true"]
```

### 1.6.3 Strings

#### String Methods

```javascript
const str = "Hello, World!";

// Basic methods
console.log(str.length); // 13
console.log(str.toUpperCase()); // "HELLO, WORLD!"
console.log(str.toLowerCase()); // "hello, world!"
console.log(str.charAt(0)); // "H"
console.log(str.charCodeAt(0)); // 72

// Search methods
console.log(str.indexOf("World")); // 7
console.log(str.lastIndexOf("o")); // 11
console.log(str.includes("World")); // true
console.log(str.startsWith("Hello")); // true
console.log(str.endsWith("!")); // true

// Extraction methods
console.log(str.slice(7, 12)); // "World"
console.log(str.substring(7, 12)); // "World"
console.log(str.substr(7, 5)); // "World"

// Replacement methods
console.log(str.replace("World", "JavaScript")); // "Hello, JavaScript!"
console.log(str.replace(/o/g, "0")); // "Hell0, W0rld!"

// Trimming methods
const spaced = "  hello  ";
console.log(spaced.trim()); // "hello"
console.log(spaced.trimStart()); // "hello  "
console.log(spaced.trimEnd()); // "  hello"

// Splitting
console.log(str.split(" ")); // ["Hello,", "World!"]
console.log(str.split(", ")); // ["Hello", "World!"]

// Concatenation
console.log("Hello" + " " + "World"); // "Hello World"
console.log(`Hello ${"World"}`); // "Hello World"
```

#### Template Literals

```javascript
// Basic template literal
const name = "Sean";
const age = 30;
const message = `Hello, ${name}! You are ${age} years old.`;
console.log(message); // "Hello, Sean! You are 30 years old."

// Multi-line strings
const multiLine = `Line 1
Line 2
Line 3`;
console.log(multiLine);

// Template literal with expressions
const a = 5;
const b = 10;
const result = `Sum: ${a + b}`;
console.log(result); // "Sum: 15"

// Template literal with functions
function greet(name) {
  return `Hello, ${name.toUpperCase()}!`;
}
console.log(greet("Sean")); // "Hello, SEAN!"

// Tagged templates
function highlight(tag, ...values) {
  return values.map(v => `<strong>${v}</strong>`).join("");
}
const html = highlight(`Hello ${"Sean"} and ${"World"}`);
console.log(html);
```

***

## 1.7 Module 5: DOM & Browser Interaction

### 1.7.1 Selecting Elements

```javascript
// getElementsByID
const header = document.getElementById("header");

// getElementsByClassName
const items = document.getElementsByClassName("item");

// getElementByTagName
const paragraphs = document.getElementsByTagName("p");

// querySelector (single element)
const app = document.querySelector("#app");
const button = document.querySelector(".btn");
const firstItem = document.querySelector("li:first-child");

// querySelectorAll (multiple elements)
const allItems = document.querySelectorAll(".item");
const allButtons = document.querySelectorAll("button.btn");

// NodeList vs Array
allItems.forEach(item => console.log(item)); // Works (NodeList has forEach)
console.log(allItems.map); // undefined (not an array)

// Convert NodeList to Array
const itemsArray = Array.from(allItems);
console.log(itemsArray.map); // Works
```

### 1.7.2 Manipulating Content

```javascript
const element = document.querySelector("#app");

// textContent - plain text
element.textContent = "Hello, World!";

// innerHTML - HTML content
element.innerHTML = "<strong>Hello</strong> <em>World</em>";

// innerText - text with formatting
element.innerText = "Hello\nWorld";

// value - for input elements
const input = document.querySelector("input");
input.value = "Default value";

// Getting content
console.log(element.textContent);
console.log(element.innerHTML);
console.log(input.value);
```

### 1.7.3 Class Manipulation

```javascript
const element = document.querySelector("#app");

// classList methods
element.classList.add("active");
element.classList.remove("inactive");
element.classList.toggle("visible"); // Adds if not present, removes if present
element.classList.replace("old", "new");

// Check for class
console.log(element.classList.contains("active")); // true

// Get all classes
console.log(element.classList); // DOMTokenList

// Multiple classes
element.classList.add("btn", "primary", "large");
```

### 1.7.4 Creating & Removing Elements

```javascript
// Creating elements
const div = document.createElement("div");
div.textContent = "New element";
div.className = "container";

// Setting attributes
div.setAttribute("id", "new-id");
div.setAttribute("data-user", "123");

// Adding to DOM
document.body.appendChild(div);

// Insert before/after
const existing = document.querySelector("#existing");
document.body.insertBefore(div, existing);

// Insert adjacent
existing.insertAdjacentElement("beforebegin", div);
existing.insertAdjacentElement("afterend", div);

// Removing elements
div.remove(); // Removes itself
existing.removeChild(div); // Removes child

// Replacing elements
const newDiv = document.createElement("div");
existing.replaceWith(newDiv);
```

### 1.7.5 Event Listeners

```javascript
const button = document.querySelector("#btn");

// addEventListener
button.addEventListener("click", (event) => {
  console.log("Button clicked!");
  console.log(event.target); // The clicked element
});

// Multiple events
button.addEventListener("mouseenter", () => {
  console.log("Mouse entered");
});

button.addEventListener("mouseleave", () => {
  console.log("Mouse left");
});

// Removing event listeners
function handleClick() {
  console.log("Clicked");
}

button.addEventListener("click", handleClick);
button.removeEventListener("click", handleClick);

// Event options
button.addEventListener("click", handleClick, {
  once: true, // автоматически удаляет после первого вызова
  passive: false,
  capture: false
});

// Event propagation
// parent -> child (down) = capturing
// child -> parent (up) = bubbling

const parent = document.querySelector("#parent");
const child = document.querySelector("#child");

child.addEventListener("click", (e) => {
  console.log("Child clicked");
  e.stopPropagation(); // Prevents bubbling
});

parent.addEventListener("click", () => {
  console.log("Parent clicked"); // Won't run if child stops propagation
});
```

### 1.7.6 Forms & Input Handling

```javascript
const form = document.querySelector("#form");
const input = document.querySelector("input[name="username"]");

// Form submission
form.addEventListener("submit", (e) => {
  e.preventDefault(); // Prevent actual submission
  
  const username = input.value;
  console.log(`Submitting: ${username}`);
  
  // Validate
  if (username.length < 3) {
    console.error("Username too short");
    return;
  }
  
  // Submit logic here
});

// Input changes
input.addEventListener("input", (e) => {
  console.log(`Current value: ${e.target.value}`);
});

input.addEventListener("change", (e) => {
  console.log(`Value changed to: ${e.target.value}`);
});

// Focus events
input.addEventListener("focus", () => {
  console.log("Input focused");
});

input.addEventListener("blur", () => {
  console.log("Input blurred");
});

// Keyboard events
input.addEventListener("keydown", (e) => {
  console.log(`Key pressed: ${e.key}`);
  if (e.key === "Enter") {
    console.log("Enter pressed");
  }
});

// Getting form data
form.addEventListener("submit", (e) => {
  e.preventDefault();
  
  const formData = new FormData(form);
  const username = formData.get("username");
  const email = formData.get("email");
  
  console.log({ username, email });
});
```

***

## 1.8 Module 6: Asynchronous JavaScript

### 1.8.1 Synchronous vs Asynchronous

```javascript
// Synchronous - executes line by line
console.log("1");
console.log("2");
console.log("3");
// Output: 1, 2, 3

// Asynchronous - non-blocking
console.log("1");

setTimeout(() => {
  console.log("2");
}, 1000);

console.log("3");
// Output: 1, 3, 2 (after 1 second)
```

### 1.8.2 Callbacks → Promises → async/await

#### Callbacks

```javascript
// Callback pattern
function fetchData(callback) {
  setTimeout(() => {
    const data = { name: "Sean", age: 30 };
    callback(data);
  }, 1000);
}

fetchData((data) => {
  console.log(data);
});

// Callback with error
function fetchData(callback) {
  setTimeout(() => {
    const error = null;
    const data = { name: "Sean" };
    callback(error, data);
  }, 1000);
}

fetchData((error, data) => {
  if (error) {
    console.error(error);
  } else {
    console.log(data);
  }
});
```

#### Promises

```javascript
// Creating a Promise
const promise = new Promise((resolve, reject) => {
  setTimeout(() => {
    const success = true;
    
    if (success) {
      resolve({ name: "Sean", age: 30 });
    } else {
      reject("Failed to fetch data");
    }
  }, 1000);
});

// Consuming a Promise
promise
  .then(data => console.log(data))
  .catch(error => console.error(error));

// Promise with .then() and .catch()
fetch("https://api.example.com/data")
  .then(response => response.json())
  .then(data => console.log(data))
  .catch(error => console.error(error));

// Promise chaining
fetch("/api/user")
  .then(response => response.json())
  .then(user => fetch(`/api/posts/${user.id}`))
  .then(response => response.json())
  .then(posts => console.log(posts))
  .catch(error => console.error(error));

// Promise methods
const promise1 = Promise.resolve(1);
const promise2 = Promise.resolve(2);

Promise.all([promise1, promise2])
  .then(values => console.log(values)); // [1, 2]

Promise.allSettled([promise1, promise2])
  .then(results => console.log(results));

Promise.any([promise1, promise2])
  .then(value => console.log(value)); // 1 (first resolved)
```

#### async/await

```javascript
// async function
async function fetchData() {
  return { name: "Sean", age: 30 };
}

const result = fetchData();
console.log(result); // Promise object

result.then(data => console.log(data)); // { name: "Sean", age: 30 }

// await with Promise
async function getUser() {
  const response = await fetch("https://api.example.com/user");
  const data = await response.json();
  return data;
}

getUser().then(user => console.log(user));

// Error handling with try/catch
async function getData() {
  try {
    const response = await fetch("https://api.example.com/data");
    const data = await response.json();
    console.log(data);
  } catch (error) {
    console.error("Error:", error);
  }
}

// Multiple awaits
async function loadUserData() {
  const user = await fetch("/api/user").then(r => r.json());
  const posts = await fetch(`/api/posts/${user.id}`).then(r => r.json());
  const comments = await fetch(`/api/comments/${posts[0].id}`).then(r => r.json());
  
  return { user, posts, comments };
}

// Parallel awaits
async function loadParallel() {
  const [user, posts, comments] = await Promise.all([
    fetch("/api/user").then(r => r.json()),
    fetch("/api/posts").then(r => r.json()),
    fetch("/api/comments").then(r => r.json())
  ]);
  
  return { user, posts, comments };
}
```

### 1.8.3 fetch() API

```javascript
// Basic GET request
fetch("https://api.example.com/data")
  .then(response => {
    console.log(response.status); // 200
    console.log(response.ok); // true
    return response.json();
  })
  .then(data => console.log(data))
  .catch(error => console.error(error));

// async/await with fetch
async function getData() {
  try {
    const response = await fetch("https://api.example.com/data");
    
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const data = await response.json();
    console.log(data);
  } catch (error) {
    console.error("Fetch error:", error);
  }
}

// POST request
async function createUser(user) {
  const response = await fetch("https://api.example.com/users", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer token123"
    },
    body: JSON.stringify(user)
  });
  
  const data = await response.json();
  return data;
}

// DELETE request
async function deleteUser(id) {
  const response = await fetch(`/api/users/${id}`, {
    method: "DELETE",
    headers: {
      "Authorization": "Bearer token123"
    }
  });
  
  return response.ok;
}

// Request with timeout
async function fetchWithTimeout(url, timeout = 5000) {
  const controller = new AbortController();
  
  const timeoutId = setTimeout(() => controller.abort(), timeout);
  
  try {
    const response = await fetch(url, {
      signal: controller.signal
    });
    clearTimeout(timeoutId);
    return response;
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}
```

### 1.8.4 Error Handling

```javascript
// Try/catch with async
async function fetchData() {
  try {
    const response = await fetch("https://api.example.com/data");
    const data = await response.json();
    return data;
  } catch (error) {
    console.error("Error fetching data:", error);
    throw error;
  }
}

// Multiple try/catch blocks
async function complexOperation() {
  try {
    const user = await fetch("/api/user").then(r => r.json());
    
    try {
      const posts = await fetch(`/api/posts/${user.id}`).then(r => r.json());
      return { user, posts };
    } catch (postError) {
      console.error("Error fetching posts:", postError);
      return { user, posts: [] };
    }
  } catch (userError) {
    console.error("Error fetching user:", userError);
    throw userError;
  }
}

// Error types
try {
  throw new TypeError("Invalid type");
} catch (error) {
  console.log(error.name); // "TypeError"
  console.log(error.message); // "Invalid type"
}

// Custom error
class APIError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.name = "APIError";
  }
}

async function fetchData() {
  const response = await fetch("/api/data");
  
  if (!response.ok) {
    throw new APIError("Failed to fetch", response.status);
  }
  
  return response.json();
}
```

***

## 1.9 Module 7: Modern ES6+ Features

### 1.9.1 Destructuring

```javascript
// Array destructuring
const numbers = [1, 2, 3];
const [first, second, third] = numbers;

console.log(first); // 1
console.log(second); // 2
console.log(third); // 3

// Skip elements
const [a, _, c] = [1, 2, 3];
console.log(a, c); // 1, 3

// Rest pattern
const [x, ...rest] = [1, 2, 3, 4, 5];
console.log(x); // 1
console.log(rest); // [2, 3, 4, 5]

// Object destructuring
const user = {
  name: "Sean",
  age: 30,
  email: "sean@example.com"
};

const { name, age } = user;
console.log(name, age); // "Sean", 30

// Rename variables
const { name: userName, age: userAge } = user;
console.log(userName, userAge); // "Sean", 30

// Default values
const { email = "default@example.com" } = user;
console.log(email); // "sean@example.com"

const { phone = "N/A" } = user;
console.log(phone); // "N/A"

// Nested destructuring
const data = {
  user: {
    name: "Sean",
    profile: {
      age: 30,
      city: "Singapore"
    }
  }
};

const { user: { profile: { age, city } } } = data;
console.log(age, city); // 30, "Singapore"

// Destructuring in function parameters
function greet({ name, age }) {
  return `Hello ${name}, you are ${age} years old`;
}

console.log(greet(user)); //
