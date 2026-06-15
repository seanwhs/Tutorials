# JavaScript Refresher (30 Days of React) — Notes

The JavaScript Refresher lesson serves as a prerequisite review before diving into React. The course emphasizes that React is a JavaScript library, therefore developers should be comfortable with modern JavaScript concepts before learning React. ([jQuery Plugins][1])

---

# 1. Why JavaScript Matters in React

React does not replace JavaScript.

Instead, React builds upon JavaScript and heavily relies on:

* Variables and constants
* Functions
* Objects and arrays
* ES6+ syntax
* Destructuring
* Spread operator
* Modules
* Arrow functions
* Array methods
* Promises and asynchronous programming

A developer who understands modern JavaScript will learn React significantly faster. ([jQuery Plugins][1])

---

# 2. Variables and Data Types

## Variable Declarations

```javascript
var name = "John";
let age = 25;
const country = "Singapore";
```

### Best Practice

Use:

```javascript
const
```

by default.

Use:

```javascript
let
```

when reassignment is required.

Avoid:

```javascript
var
```

because of function scoping and hoisting issues.

---

## Primitive Types

```javascript
String
Number
Boolean
Undefined
Null
Symbol
BigInt
```

Example:

```javascript
const name = "Sean";
const age = 30;
const isDeveloper = true;
```

---

# 3. Functions

Functions are fundamental building blocks in React.

## Traditional Function

```javascript
function greet(name) {
  return `Hello ${name}`;
}
```

## Arrow Function

```javascript
const greet = (name) => {
  return `Hello ${name}`;
};
```

### Short Form

```javascript
const greet = name => `Hello ${name}`;
```

React code frequently uses arrow functions.

---

# 4. Template Literals

Instead of string concatenation:

```javascript
const message =
  "Hello " + firstName + " " + lastName;
```

Use:

```javascript
const message =
  `Hello ${firstName} ${lastName}`;
```

Benefits:

* Cleaner syntax
* Easier interpolation
* Multi-line strings

---

# 5. Arrays

Arrays store collections of data.

```javascript
const techs = [
  "HTML",
  "CSS",
  "JavaScript",
  "React"
];
```

Accessing elements:

```javascript
techs[0];
```

---

## Common Array Methods

### map()

Transforms data.

```javascript
const upper =
  techs.map(tech => tech.toUpperCase());
```

React commonly uses:

```javascript
array.map()
```

for rendering lists.

---

### filter()

Filters data.

```javascript
const longNames =
  techs.filter(
    tech => tech.length > 4
  );
```

---

### find()

Returns first match.

```javascript
const react =
  techs.find(
    tech => tech === "React"
  );
```

---

# 6. Objects

Objects represent structured data.

```javascript
const user = {
  firstName: "Sean",
  lastName: "Wong",
  role: "Developer"
};
```

Access properties:

```javascript
user.firstName;
```

or

```javascript
user["firstName"];
```

---

# 7. Object Destructuring

Extract properties quickly.

Instead of:

```javascript
const firstName = user.firstName;
const role = user.role;
```

Use:

```javascript
const {
  firstName,
  role
} = user;
```

React components frequently destructure props.

Example:

```javascript
const User = ({ name }) => {
  return <h1>{name}</h1>;
};
```

---

# 8. Spread Operator

Copy arrays:

```javascript
const newTechs = [
  ...techs,
  "Node.js"
];
```

Copy objects:

```javascript
const updatedUser = {
  ...user,
  role: "Architect"
};
```

React state updates commonly use spread syntax.

---

# 9. Rest Parameters

Collect remaining values.

```javascript
const sum = (...numbers) => {
  return numbers.reduce(
    (a, b) => a + b,
    0
  );
};
```

---

# 10. Ternary Operator

Compact conditional logic.

```javascript
const message =
  isLoggedIn
    ? "Welcome"
    : "Please Login";
```

React JSX frequently uses ternary operators for conditional rendering.

---

# 11. Short Circuit Evaluation

```javascript
isAdmin && showAdminPanel();
```

Equivalent to:

```javascript
if (isAdmin) {
  showAdminPanel();
}
```

Common in React:

```jsx
{isLoggedIn && <Dashboard />}
```

---

# 12. Modules

Export code:

```javascript
export const greet = () => {};
```

Import code:

```javascript
import { greet } from "./utils";
```

React applications are built from modules.

---

# 13. Promises

Handle asynchronous operations.

```javascript
fetch(url)
  .then(response => response.json())
  .then(data => console.log(data));
```

Promise states:

* Pending
* Fulfilled
* Rejected

---

# 14. Async / Await

Cleaner asynchronous syntax.

```javascript
const getUsers = async () => {
  const response =
    await fetch(url);

  const data =
    await response.json();

  return data;
};
```

Used extensively in React API calls.

---

# 15. DOM vs React

Traditional JavaScript:

```javascript
document.getElementById("app");
```

React:

```jsx
<App />
```

React abstracts DOM manipulation and allows developers to focus on data and UI logic.

---

# 16. JavaScript Concepts Most Important for React

Priority order:

1. Functions
2. Arrow Functions
3. Objects
4. Arrays
5. map()
6. Destructuring
7. Spread Operator
8. Modules
9. Promises
10. Async/Await

These concepts appear constantly throughout React development. ([jQuery Plugins][1])

---

[1]: https://jquery-plugins.net/30-days-of-react-guide-to-learn-react-in-30-days?utm_source=chatgpt.com "30 Days Of React – Guide to Learn React in 30 Days | jQuery Plugins"
