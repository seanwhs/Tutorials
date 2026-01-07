# 📘 Just Enough JavaScript for React

## A Deep, Practical Foundation in Modern JavaScript (ES6+) — with Real React Patterns

**Audience:** Backend developers, architects, beginners

**Goal:** Understand **JavaScript as the engine** of React. React is a **renderer**, not the brain.

> **Core Principle**
>
> ```
> JavaScript decides WHAT changes
> React decides HOW to show it
> The browser reflects the result
> ```

To master React, you do **not** need to know every obscure corner of JavaScript.
But you **must** be fluent in **Modern JavaScript (ES6+)**.

React is built on specific JavaScript patterns that favor:

* Declarative code
* Immutability
* Readability
* Predictable data flow

This guide teaches **only what React actually uses — deeply and correctly**.

---

# 🧠 Big Picture Mental Model

```
User Action
   ↓
JavaScript Logic (events, state, data)
   ↓
React observes state changes
   ↓
Virtual DOM diffing
   ↓
Browser updates the UI
```

If JavaScript logic is wrong, **React cannot save you**.

---

# 🏗️ Part 0: Why JavaScript Comes First

React:

* ❌ Does **not** replace JavaScript
* ❌ Does **not** manage your business logic
* ❌ Does **not** understand domain rules

React only:

* Calls your functions
* Tracks state references
* Renders data you provide

> React is the **dashboard**.
> JavaScript is the **engine**.

A broken engine cannot be fixed with a prettier dashboard.

---

# 🧩 Part 1: Variables, Memory & Hoisting

### *ES6 Foundations That Prevent Real Bugs*

---

## 1️⃣ Variables Are **Memory References**, Not Boxes

```js
let count = 1;
```

```
Memory:
┌─────────┐
│    1    │
└─────────┘
     ▲
   count
```

A JavaScript variable does **not** store the value itself.
It stores a **reference (pointer) to a memory location** where the value lives.

This single idea explains:

* Why **objects and arrays behave differently** from numbers and strings
* Why **mutating objects can cause invisible bugs**
* Why **React relies on reference changes**, not value changes

> If you misunderstand this, JavaScript feels inconsistent.
> If you understand this, JavaScript becomes predictable.

---

## 2️⃣ `var` vs `let` vs `const`

---

### ❌ `var` — Legacy JavaScript (Avoid)

```js
console.log(x); // undefined
var x = 5;
```

What the engine actually sees:

```js
var x;
console.log(x);
x = 5;
```

**Problems with `var`:**

* ❌ Function-scoped (ignores blocks)
* ❌ Unsafe hoisting behavior
* ❌ Redeclaration allowed
* ❌ Source of many legacy bugs

> `var` exists for backward compatibility, not best practice.

---

### ✔ `let` — Block Scoped, Reassignable

```js
let score = 0;
score++;
```

**Characteristics:**

* ✔ Block-scoped
* ✔ Hoisted but **not usable before declaration**
* ✔ Explicit reassignment allowed

Use `let` **only when reassignment is intentional**.

---

## 3️⃣ `const` — The Default Choice (and Most Misunderstood)

### What `const` *Actually* Guarantees

```js
const x = 10;
```

Once created:

* `const` **cannot be reassigned**
* `const` **is block-scoped**
* The **reference is fixed**, not the value

This is the key idea most people miss.

---

### ⚠️ Why the Name `const` Is Misleading

`const` does **not** mean:

> “This value will never change”

It means:

> **“This variable will always point to the same thing.”**

That distinction matters **a lot**.

---

### ❌ What You CANNOT Do with `const`

You cannot change the reference:

```js
const x = 5;
x = 10;          // ❌ Error
```

```js
const arr = [1, 2, 3];
arr = [4, 5, 6]; // ❌ Error
```

```js
const obj = { a: 1 };
obj = { a: 2 };  // ❌ Error
```

Once assigned, the reference is **locked**.

---

### ✅ What You CAN Do with `const`

You *can* mutate the contents of the referenced object:

```js
const arr = [1, 2, 3];
arr.push(4);     // ✅ Allowed
```

```js
const obj = { a: 1 };
obj.a = 2;       // ✅ Allowed
```

Why?

Because the **reference did not change** — only the internal data did.

---

### 🧠 Mental Model (This Prevents Bugs)

```
const variable
     │
     ▼
┌──────────────┐
│  Memory Ref  │  ← LOCKED
└──────────────┘
       │
       ▼
  { object data }  ← MUTABLE
```

`const` protects the **pointer**, not the **contents**.

Once this clicks, JavaScript stops feeling “weird.”

---

### 🏆 Why Professionals Use `const` by Default

* Prevents accidental reassignment
* Makes code easier to reason about
* Signals developer intent clearly
* Works naturally with immutable patterns
* Reduces entire classes of bugs

**Modern JavaScript rule:**

> **Use `const` unless you explicitly intend to reassign.**

---

## ⚛️ React-Specific Warning (Very Important)

This is **valid JavaScript**:

```js
const user = { name: "Alice" };
user.name = "Bob"; // ✅ JS allows this
```

But in **React**, this is often **wrong**.

React detects changes via **reference comparison**, not deep inspection.

Correct React pattern:

```js
setUser({ ...user, name: "Bob" });
```

Why?

* New object
* New reference
* React sees the change
* UI updates correctly

---

## 🧠 One-Sentence Rule (Memorize This)

> **`const` means “this variable will always point to the same thing.”**

Not:

> “This thing will never change.”

Once you internalize this, **half of JavaScript confusion disappears**.

---

## 4️⃣ Hoisting & the Temporal Dead Zone

```js
console.log(a); // ❌ ReferenceError
let a = 3;
```

What’s happening?

* `let` and `const` **are hoisted**
* But they are **not initialized**
* Accessing them before declaration triggers the **Temporal Dead Zone (TDZ)**

This is **intentional safety**, not a bug.

> If something crashes *before* it runs → think **scope + hoisting + TDZ**.

---

### Final Takeaway

JavaScript isn’t loose — it’s **precise**.
Once you understand **references, scope, and intent**, the language becomes predictable, React becomes easier, and bugs become rarer.

---

# 🧩 Part 2: Data Types & References

### *Why React Bugs Exist*

---

## 1️⃣ Two Categories of Data in JavaScript

JavaScript data types fall into **two fundamentally different behaviors**:

| Category            | How They Copy           | Examples                                                               |
| ------------------- | ----------------------- | ---------------------------------------------------------------------- |
| **Primitive Types** | Copied by **value**     | `number`, `string`, `boolean`, `null`, `undefined`, `symbol`, `bigint` |
| **Reference Types** | Copied by **reference** | `object`, `array`, `function`                                          |

If you don’t internalize this difference, **React will feel broken**.

---

## 2️⃣ Primitive Types — Copied by Value

```js
let a = 5;
let b = a;
b = 10;
```

What happens in memory:

```
a → 5
b → 5
```

Then:

```
b → 10
```

✔ Each variable gets its **own copy**
✔ Changes are **isolated**
✔ Predictable behavior
✔ Safe for React state

> Primitives behave like photocopies.

---

## 3️⃣ Reference Types — Copied by Reference ⚠️

```js
const t1 = { done: false };
const t2 = t1;

t2.done = true;
```

Memory model:

```
t1 ─┐
    ▼
  { done: true }
    ▲
t2 ─┘
```

✔ Only **one object**
❌ Two variables pointing to it
❌ Mutations affect both

> This is the **#1 cause of React bugs**.

---

### Why This Breaks React

React determines updates by checking:

> **“Did the reference change?”**

In this example:

* The object **mutated**
* The reference **did not change**
* React may **skip rendering**
* UI becomes **out of sync**

Correct React approach:

```js
setTodo({ ...t1, done: true });
```

✔ New object
✔ New reference
✔ React detects the change

---

## 4️⃣ Template Strings (ES6 Quality-of-Life Feature)

Template strings allow:

* Multi-line strings
* Embedded expressions
* Cleaner, more readable code

They use **backticks (`)** instead of quotes.

---

### ❌ Without Template Strings

```js
const name = "John";
const age = 30;

const message =
  "Hello, " + name + "!\n" +
  "You are " + age + " years old.";
```

Harder to read. Easy to break.

---

### ✅ With Template Strings

```js
const name = "John";
const age = 30;

const message = `Hello, ${name}!
You are ${age} years old.`;
```

✔ Cleaner
✔ More readable
✔ Less error-prone

---

### What Template Strings Support

* Multiple lines (no `\n`)
* Embedded expressions via `${}`
* Quotes without escaping

---

### Multi-Line Strings

```js
const html = `
  <div>
    <h1>Title</h1>
    <p>Paragraph</p>
  </div>
`;
```

⚠️ **Indentation is preserved**

```js
const x = `
  John:
    Hello, how are you?
  Jane:
    I'm fine, thanks!
`;
```

> Whitespace becomes part of the string.
> Be intentional when formatting.

---

## 5️⃣ Expressions Inside `${}`

Any valid JavaScript expression is allowed.

```js
let firstName = "John";
let lastName = "Doe";

let text = `Welcome ${firstName}, ${lastName}!`;
```

```js
let price = 10;
let quantity = 5;

let total = `Total: ${price * quantity}`;
```

---

### Using `map()` Inside Template Strings

```js
const items = ["apple", "banana", "orange"];

const list = `You have ${items.length} items:
${items.map(item => `- ${item}`).join('\n')}`;
```

✔ Powerful
✔ Expressive
✔ Common in UI rendering

---

### Using the Ternary Operator

```js
const isAdmin = true;

const message = `Status: ${isAdmin ? "Admin" : "User"}`;
```

Readable conditional output — perfect for UI logic.

---

## 6️⃣ Tagged Template Literals (Advanced)

Tagged templates allow a **function to process a template string**.

> ⚠️ Advanced feature — rarely needed for everyday React work.

---

### Basic Tagged Template

```js
function highlight(strings, fname) {
  let x = fname.toUpperCase();
  return strings[0] + x + strings[1];
}

let name = "John";

let text = highlight`Hello ${name}, how are you?`;
```

---

### Multiple Expressions

```js
function highlight(strings, fname1, fname2) {
  let x = fname1.toUpperCase();
  let y = fname2.toUpperCase();
  return strings[0] + x + strings[1] + y + strings[2];
}

let name1 = "John";
let name2 = "Jane";

let text = highlight`Hello ${name1} and ${name2}, how are you?`;
```

Tagged templates are commonly used in:

* Styling libraries
* Localization systems
* Sanitization / formatting tools

---

## 🧠 Final Mental Model (Memorize This)

> **Primitives are copied. Objects are shared.**

React bugs happen when you:

* Mutate shared objects
* Expect React to “notice”
* Don’t change references

---

### One-Line Rule for React

> **If the UI didn’t update, ask: “Did I create a new reference?”**

---

# 🧩 Part 3: Modern Functions

### *Arrow Functions & Closures (Why Hooks Actually Work)*

---

## 1️⃣ Arrow Functions — Used Everywhere in React

```js
const add = (a, b) => a + b;
```

Arrow functions are not “syntactic sugar.”
They encode **intent** and remove entire classes of bugs.

---

### Why React Prefers Arrow Functions

✔ Concise syntax
✔ Cleaner callbacks
✔ No accidental `this` binding
✔ Predictable behavior in components

```js
<button onClick={() => setCount(c => c + 1)} />
```

This pattern is **idiomatic React**.

---

## 2️⃣ Arrow Functions vs Regular Functions

### Traditional Function

```js
function add(a, b) {
  return a + b;
}
```

### Arrow Function

```js
const add = (a, b) => a + b;
```

Key differences:

| Feature     | `function` | Arrow          |
| ----------- | ---------- | -------------- |
| Syntax      | Verbose    | Compact        |
| `this`      | Dynamic    | **Lexical**    |
| React usage | Rare       | **Everywhere** |

---

## 3️⃣ Lexical `this` (Why Arrow Functions Matter)

Traditional functions get `this` **at call time**.
Arrow functions capture `this` **from where they are defined**.

```js
function Timer() {
  this.seconds = 0;

  setInterval(function () {
    this.seconds++; // ❌ `this` is wrong
  }, 1000);
}
```

Arrow function fix:

```js
function Timer() {
  this.seconds = 0;

  setInterval(() => {
    this.seconds++; // ✅ lexical `this`
  }, 1000);
}
```

> Arrow functions **do not create their own `this`**.

This is why React event handlers and callbacks overwhelmingly use arrows.

---

## 4️⃣ Closures — The Most Important JavaScript Concept

```js
function outer() {
  let count = 0;

  return () => {
    count++;
    console.log(count);
  };
}
```

What’s happening?

* `outer()` finishes execution
* Its local variables **should be gone**
* But they’re not

Why?

---

## 5️⃣ What Is a Closure?

> A **closure** is a function **plus** the memory it remembers.

The returned arrow function **closes over** `count`.

Memory model:

```
closure
   │
   ▼
┌────────────┐
│ count = 0  │ ← preserved
└────────────┘
```

Each call:

```js
const counter = outer();
counter(); // 1
counter(); // 2
counter(); // 3
```

The memory persists **between calls**.

---

## 6️⃣ Why Closures Exist (Design Intent)

Closures allow:

* Private state
* Controlled mutation
* Long-lived memory without globals

JavaScript **intentionally supports this**.

> Closures are not a trick — they are the foundation of modern JS.

---

## 7️⃣ Why React Hooks Work

React hooks are **controlled closures**.

Example:

```js
function Counter() {
  const [count, setCount] = useState(0);

  function increment() {
    setCount(count + 1);
  }

  return <button onClick={increment}>{count}</button>;
}
```

What React does:

* Re-runs your component function
* Recreates functions
* Preserves state via closures
* Syncs memory to UI

Hooks rely on:

* Function scope
* Closures
* Reference consistency

---

## 8️⃣ The Famous “Stale Closure” Bug ⚠️

```js
setTimeout(() => {
  console.log(count);
}, 1000);
```

Why this breaks:

* The closure captures **old `count`**
* React has already re-rendered
* The closure didn’t update

Correct pattern:

```js
setCount(c => c + 1);
```

Why this works:

* React passes the **latest value**
* No stale closure
* Reference-safe update

---

## 🧠 Final Mental Models (Memorize These)

> **Arrow functions inherit `this`.**

> **Closures remember variables, not values.**

> **Hooks are closures with rules.**

If you understand these three ideas:

* React stops feeling magical
* Bugs become explainable
* State becomes predictable

---

### One-Line Rule for React

> **If something behaves “stuck in the past,” suspect a closure.**

---

# 🧩 Part 4: Destructuring

### *React’s Favorite Syntax (Because It Encodes Intent)*

---

## 1️⃣ What Destructuring Really Is

Destructuring is **pattern matching for data**.

Instead of manually pulling values out of arrays or objects, you **declare the shape you expect** and JavaScript does the extraction for you.

> Destructuring makes data access **explicit, readable, and self-documenting**.

---

## 2️⃣ Array Destructuring (Order Matters)

### ❌ Old Way (Index-Based, Error-Prone)

```js
const vehicles = ['mustang', 'f-150', 'expedition'];

const car = vehicles[0];
const truck = vehicles[1];
const suv = vehicles[2];

document.getElementById('demo').innerHTML = truck;
```

Problems:

* Magic numbers (`[0]`, `[1]`, `[2]`)
* Harder to refactor
* Meaning lives in comments, not code

---

### ✅ New Way (Declarative)

```js
const vehicles = ['mustang', 'f-150', 'expedition'];

const [car, truck, suv] = vehicles;

document.getElementById('demo').innerHTML = truck;
```

✔ Order defines meaning
✔ No indexes
✔ Self-explanatory

---

### Skipping Values

```js
const vehicles = ['mustang', 'f-150', 'expedition'];

const [car, , suv] = vehicles;
```

> Empty slots mean “skip this position.”

---

### Destructuring Function Returns

```js
function dateInfo(dat) {
  const d = dat.getDate();
  const m = dat.getMonth() + 1;
  const y = dat.getFullYear();

  return [d, m, y];
}

const [date, month, year] = dateInfo(new Date());
```

This creates a **clear contract** between the function and its caller.

---

## 3️⃣ Object Destructuring (Order Does NOT Matter)

### Basic Object Destructuring

```js
const person = {
  firstName: "John",
  lastName: "Doe",
  age: 50
};

let { firstName, lastName, age } = person;

document.getElementById("demo").innerHTML = firstName;
```

✔ Property names define mapping
✔ Order is irrelevant

---

### Order Doesn’t Matter

```js
let { lastName, age, firstName } = person;
```

Objects are **key-based**, not position-based.

---

### Extract Only What You Need

```js
let { firstName } = person;
```

This is common and encouraged.

> Unused data is noise.

---

### Default Values (Defensive Coding)

```js
let { firstName, lastName, age, country = "Norway" } = person;
```

Useful when:

* Data is incomplete
* Props are optional
* APIs change

---

### Nested Object Destructuring

```js
const person = {
  firstName: "John",
  lastName: "Doe",
  age: 50,
  car: {
    brand: 'Ford',
    model: 'Mustang',
  }
};

let { firstName, car: { brand, model } } = person;

let message = `My name is ${firstName}, and I drive a ${brand} ${model}.`;
```

This avoids deep dot chains:

```js
person.car.brand // ❌ repetitive
```

---

## 4️⃣ Object Destructuring in React — Props

### Preferred (Destructured Props)

```js
function Greeting({ name, age }) {
  return <h1>Hello, {name}! You are {age} years old.</h1>;
}
```

### Avoid (Props Dot-Chaining)

```js
function Greeting(props) {
  return <h1>Hello, {props.name}! You are {props.age} years old.</h1>;
}
```

Why destructuring wins:

* Cleaner JSX
* Clear component API
* Easier refactoring

---

### Practical React Example

```js
import { createRoot } from 'react-dom/client';

function Greeting({ name, age }) {
  return <h1>Hello, {name}! You are {age} years old.</h1>;
}

createRoot(document.getElementById('root')).render(
  <Greeting name="John" age={25} />
);
```

> Props destructuring makes components **self-documenting**.

---

## 5️⃣ Array Destructuring in React — Hooks

```js
const [count, setCount] = useState(0);
```

Why arrays here?

* Order-based contract
* Short, predictable syntax
* No naming conflicts

---

### Practical Hook Example

```js
import { createRoot, useState } from 'react-dom/client';

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <button onClick={() => setCount(count + 1)}>
      Count: {count}
    </button>
  );
}

createRoot(document.getElementById('root')).render(
  <Counter />
);
```

Destructuring here:

* Declares **state shape**
* Makes intent obvious
* Encourages immutability

---

## 🧠 Final Mental Models (Memorize These)

> **Array destructuring is positional.**

> **Object destructuring is named.**

> **Destructuring declares contracts, not convenience.**

---

### One-Line Rule for React

> **If you’re typing `props.` more than once, destructure.**

---

# 🧩 Part 5: Spread Operator (`...`) & Immutability

### *The Tool React Depends On*

---

## 1️⃣ What the Spread Operator Really Does

The JavaScript spread operator (`...`) **expands** an iterable (array, object) into its individual elements or properties.

Most importantly:

> **Spread creates a new reference.**

This is why React cares about it.

---

## 2️⃣ Spreading Arrays (Copying & Combining)

```js
const numbersOne = [1, 2, 3];
const numbersTwo = [4, 5, 6];

const numbersCombined = [...numbersOne, ...numbersTwo];
```

What happened?

* A **new array** is created
* Values are copied in order
* Original arrays are untouched

Memory model:

```
numbersOne  → [1, 2, 3]
numbersTwo  → [4, 5, 6]
numbersCombined → [1, 2, 3, 4, 5, 6]  ← new reference
```

✔ Safe
✔ Predictable
✔ React-friendly

---

## 3️⃣ Spread with Destructuring (Rest Pattern)

Spread is often used together with destructuring:

```js
const numbers = [1, 2, 3, 4, 5, 6];

const [one, two, ...rest] = numbers;
```

Result:

```
one  → 1
two  → 2
rest → [3, 4, 5, 6]  ← new array
```

This is called the **rest operator** (same syntax, different role).

> **Spread expands. Rest collects.**

---

## 4️⃣ Spreading Objects (The React Default Pattern)

```js
const car = {
  brand: 'Ford',
  model: 'Mustang',
  color: 'red'
};

const car_more = {
  type: 'car',
  year: 2021,
  color: 'yellow'
};

const mycar = { ...car, ...car_more };
```

Key rules:

* Properties are copied left → right
* Later properties **overwrite earlier ones**
* A **new object reference** is created

Result:

```js
{
  brand: 'Ford',
  model: 'Mustang',
  color: 'yellow', // overwritten
  type: 'car',
  year: 2021
}
```

---

## 5️⃣ Why Spread Is Critical for React

React detects changes by checking:

> **“Did the reference change?”**

### ❌ Mutating State (Wrong)

```js
user.name = "Bob";
setUser(user); // same reference ❌
```

React may **skip re-rendering**.

---

### ✅ Immutable Update with Spread (Correct)

```js
setUser({
  ...user,
  name: "Bob"
});
```

✔ New object
✔ New reference
✔ React re-renders

---

## 6️⃣ Spread ≠ Deep Copy ⚠️

Spread only copies **one level deep**.

```js
const state = {
  user: {
    name: "Alice"
  }
};

const next = { ...state };
next.user.name = "Bob";
```

Problem:

* `state.user` and `next.user` point to the **same object**

> Spread is **shallow**, not deep.

Correct pattern:

```js
const next = {
  ...state,
  user: {
    ...state.user,
    name: "Bob"
  }
};
```

---

## 7️⃣ Common React Patterns Using Spread

### Updating Arrays

```js
setItems([...items, newItem]);
```

### Removing Items

```js
setItems(items.filter(i => i.id !== id));
```

### Updating an Item

```js
setItems(
  items.map(i =>
    i.id === id ? { ...i, done: true } : i
  )
);
```

Each pattern:

* Avoids mutation
* Creates new references
* Keeps React predictable

---

## 🧠 Final Mental Models (Memorize These)

> **Spread copies — it does not link.**

> **Spread creates new references.**

> **New references trigger React updates.**

---

### One-Line Rule for React

> **If state changes, spread something.**

---

### Summary: Spread Operator

* ✔ Copies properties or elements
* ✔ Creates new references
* ✔ Enables immutability
* ✔ Powers React re-renders

---

# 🧩 Part 6: Array Methods

### *`.map()` & `.filter()` — How React Renders Lists*

---

## 1️⃣ Why React Never Uses `for` Loops in JSX

React rendering is **declarative**, not imperative.

You don’t tell React *how* to loop.
You tell React *what* UI should exist **for each item**.

```js
{items.map(item => (
  <li key={item.id}>{item.name}</li>
))}
```

This reads as:

> “For every item, produce a UI element.”

Not:

> “Loop, push, mutate, then render.”

---

## 2️⃣ `.map()` — Transform Data → UI

`.map()` takes an array and **returns a new array** of the same length.

In React, that new array is **JSX elements**.

```js
.map() → transform
```

---

### Basic `map()` Example (React List)

```js
import { createRoot } from 'react-dom/client';

const fruitlist = ['apple', 'banana', 'cherry'];

function MyList() {
  return (
    <ul>
      {fruitlist.map(fruit => 
        <li key={fruit}>{fruit}</li>
      )}
    </ul>
  );
}

createRoot(document.getElementById('root')).render(
  <MyList />
);
```

✔ No mutation
✔ No manual loops
✔ Declarative UI

---

## 3️⃣ `.map()` with Objects (Most Common Case)

```js
const users = [
  { id: 1, name: 'John', age: 30 },
  { id: 2, name: 'Jane', age: 25 },
  { id: 3, name: 'Bob', age: 35 }
];

function UserList() {
  return (
    <ul>
      {users.map(user => 
        <li key={user.id}>
          {user.name} is {user.age} years old
        </li>
      )}
    </ul>
  );
}
```

### Why `key` Matters ⚠️

* React tracks list items by **key**
* Keys must be **stable and unique**
* IDs are ideal

> **Never use `index` as a key** unless the list is static.

---

## 4️⃣ `.filter()` — Select Data (Without Mutating)

`.filter()` creates a **new array** containing only items that match a condition.

```js
.filter() → select
```

Example:

```js
const adults = users.filter(user => user.age >= 30);
```

React usage:

```js
{users
  .filter(user => user.age >= 30)
  .map(user => (
    <li key={user.id}>{user.name}</li>
  ))}
```

✔ Composable
✔ Immutable
✔ Expressive

---

## 5️⃣ `.map()` Parameters (What React Gives You)

The `.map()` method provides **three arguments**:

1. `currentValue` – the current element
2. `index` – the position (optional)
3. `array` – the original array (optional)

```js
const fruitlist = ['apple', 'banana', 'cherry'];

function App() {
  return (
    <ul>
      {fruitlist.map((fruit, index, array) => {
        return (
          <li key={fruit}>
            Item: {fruit}, Index: {index}, Array: {array.join(', ')}
          </li>
        );
      })}
    </ul>
  );
}
```

> In React, you almost always use **only the first parameter**.

---

## 6️⃣ Why `.map()` Fits React Perfectly

| Feature       | `for` loop | `.map()` |
| ------------- | ---------- | -------- |
| Mutates       | Often      | ❌ Never  |
| Returns value | ❌ No       | ✔ Yes    |
| JSX-friendly  | ❌ No       | ✔ Yes    |
| Declarative   | ❌ No       | ✔ Yes    |

React rendering expects **pure functions**.

`.map()` guarantees:

* No side effects
* Predictable output
* Referential safety

---

## 🧠 Final Mental Models (Memorize These)

> **`.map()` describes UI.**

> **`.filter()` selects data.**

> **React renders arrays, not loops.**

---

### One-Line Rule for React

> **If you’re building a list, you’re using `.map()`.**

---

# 🧩 Part 7: Conditional Rendering

### *Ternary (`? :`) & Logical AND (`&&`)*

---

## 1️⃣ Conditional Rendering in React

In React, **rendering is just JavaScript expressions returning JSX**.

You don’t:

* Show / hide elements manually
* Manipulate the DOM
* Imperatively call render functions

You **describe conditions** and React does the rest.

> Declarative UI means:
> **Describe *what* should appear, not *how* to manipulate the DOM.**

---

## 2️⃣ The Ternary Operator (`? :`)

The ternary operator is a **compact if/else expression**.

### Syntax

```js
condition ? expressionIfTrue : expressionIfFalse
```

> Ternary returns a **value** — perfect for JSX.

---

### Traditional if / else (Imperative)

```js
if (authenticated) {
  renderApp();
} else {
  renderLogin();
}
```

This style does **not** fit JSX well.

---

### Ternary (Declarative)

```js
authenticated ? renderApp() : renderLogin();
```

Same logic, but now it’s:

* An expression
* Composable
* JSX-friendly

---

## 3️⃣ Ternary Inside JSX (Most Common Case)

```js
function App({ authenticated }) {
  return (
    <div>
      {authenticated ? <Dashboard /> : <Login />}
    </div>
  );
}
```

✔ One condition
✔ Two possible UIs
✔ No side effects

---

## 4️⃣ Ternary Inside Template Strings

```js
const isAdmin = true;

const message = `Status: ${isAdmin ? 'Admin' : 'User'}`;
```

This works because:

* `${}` accepts **any JavaScript expression**
* Ternary returns a value

---

## 5️⃣ Logical AND (`&&`) — Render *Only If True*

When you want to render something **only when a condition is true**, use `&&`.

### Syntax

```js
condition && <JSX />
```

### Example

```js
function App({ isLoggedIn }) {
  return (
    <div>
      {isLoggedIn && <LogoutButton />}
    </div>
  );
}
```

If `isLoggedIn` is:

* `true` → JSX renders
* `false` → nothing renders

---

## 6️⃣ Why `&&` Works in JSX

JavaScript logical AND returns:

* The **right-hand value** if the left is truthy
* The left value if falsy

React ignores:

* `false`
* `null`
* `undefined`

So this is safe:

```js
false && <Component /> // renders nothing
```

---

## 7️⃣ Common `&&` Pitfall ⚠️

Be careful with numbers:

```js
{items.length && <List />}
```

If `items.length === 0`, React renders `0`.

### Safer Version

```js
{items.length > 0 && <List />}
```

---

## 8️⃣ When to Use Which

| Situation                   | Use                 |
| --------------------------- | ------------------- |
| Two possible UI outcomes    | **Ternary**         |
| Render something or nothing | **`&&`**            |
| Complex conditions          | Extract to variable |

---

### Clean Pattern for Complex Logic

```js
const content = authenticated
  ? <Dashboard />
  : <Login />;

return <div>{content}</div>;
```

> JSX should stay readable.
> Logic belongs in variables.

---

## 🧠 Final Mental Models (Memorize These)

> **JSX accepts expressions, not statements.**

> **Ternary chooses between UIs.**

> **`&&` conditionally includes UI.**

---

### One-Line Rule for React

> **If it’s conditional, it’s an expression — not an `if`.**

---

# 🧩 Part 8: Modules (Import / Export)

### *How JavaScript Code Scales Without Chaos*

---

## 1️⃣ Why Modules Exist

JavaScript modules allow you to **split code into separate files**, each with a clear responsibility.

Modules:

* Enforce boundaries
* Reduce coupling
* Improve maintainability
* Enable large-scale applications

> Without modules, React apps collapse under their own weight.

---

## 2️⃣ ES Modules (ESM)

Modern JavaScript uses **ES Modules**, built on two keywords:

```js
export
import
```

Each file is its **own module scope**.

Nothing is shared unless you explicitly export it.

---

## 3️⃣ Types of Exports

There are **two kinds of exports**:

1. **Named exports**
2. **Default exports**

Understanding the difference eliminates 90% of import errors.

---

## 4️⃣ Named Exports (Explicit APIs)

Named exports are **explicit contracts**.

### In-line Named Exports

```js
export const name = "Tobias";
export const age = 18;
```

---

### Named Exports at the Bottom

```js
const name = "Tobias";
const age = 18;

export { name, age };
```

---

### Named Function Export

```js
export function add(a, b) {
  return a + b;
}
```

✔ Multiple named exports allowed
✔ Names are part of the public API
✔ Excellent refactor safety

---

## 5️⃣ Default Export (One Main Thing)

A file may have **only one default export**.

### Example: `message.js`

```js
const message = () => {
  const name = "Tobias";
  const age = 18;
  return name + ' is ' + age + ' years old.';
};

export default message;
```

Default exports are about **convenience**, not strict contracts.

---

## 6️⃣ Importing Modules

### Importing Named Exports

```js
import { name, age } from "./person.js";
```

Rules:

* Curly braces required
* Names must match exactly

---

### Importing Default Exports

```js
import message from "./message.js";
```

Rules:

* No braces
* Name is technically flexible (but shouldn’t be abused)

---

## 7️⃣ What Modules Guarantee

Modules:

* Are scoped by default
* Prevent global pollution
* Make dependencies explicit
* Enable tree-shaking and optimization

> If it’s not imported, it doesn’t exist.

---

## ⚛️ React: Named vs Default Exports

### Named Export (Explicit)

```js
export function App() {
  return <h1>Hello World</h1>;
}
```

### Importing It

```js
import { App } from "./App";
```

✔ Braces required
✔ Name must match
✔ Clear public API

---

## Default Export (Common in React Apps)

```js
export default function App() {
  return <h1>Hello World</h1>;
}
```

or

```js
function App() {
  return <h1>Hello World</h1>;
}

export default App;
```

### Importing It

```js
import App from "./App";
```

✔ Cleaner syntax
✔ One main export per file

---

## 8️⃣ Side-by-Side Comparison

| Feature              | Named Export     | Default Export |
| -------------------- | ---------------- | -------------- |
| Import syntax        | `import { App }` | `import App`   |
| Requires exact name  | ✅ Yes            | ❌ No           |
| Multiple per file    | ✅ Yes            | ❌ No           |
| Refactor safety      | ⭐⭐⭐⭐             | ⭐⭐             |
| Common in libraries  | ✅ Yes            | ❌ Less         |
| Common in React apps | ⚠️ Mixed         | ✅ Very common  |

---

## 9️⃣ Why React Examples Often Use `export default`

* One component per file
* Minimal syntax
* Beginner-friendly
* Cleaner imports

```js
import App from "./App";
```

---

## 🔧 Why Named Exports Scale Better

Named exports:

* Encourage explicit APIs
* Prevent silent renaming
* Improve autocomplete
* Make refactoring safer
* Work better in shared code

```js
export function App() {}
export function Header() {}
export function Footer() {}
```

---

## 🧠 Professional Rule of Thumb

> **Libraries → Named exports**
> **Applications → Default export (per component file)**

Both are valid.
**Consistency matters more than the choice.**

---

## ⚠️ React-Specific Gotcha

This will **NOT** work:

```js
import App from "./App"; // ❌ if App was a named export
```

Export and import **must match**.

---

## 🧠 Final Mental Models (Memorize These)

> **Named export = explicit contract**

> **Default export = convenience shortcut**

> **Imports define what exists in a file**

Once this clicks, module errors stop feeling *random* and start feeling **logical**.

---

# 🧩 Part 9: Side Effects, `async / await` & Data Fetching

### *How React Talks to the Outside World Safely*

---

## 1️⃣ What a “Side Effect” Actually Is

A **side effect** is *anything* that:

* Talks to the outside world
* Changes something beyond the function’s scope
* Is not purely derived from props or state

Examples:

* Fetching data
* Timers (`setTimeout`, `setInterval`)
* Subscriptions
* Logging
* Direct DOM access

> Rendering must be **pure**.
> Side effects must be **isolated**.

---

## 2️⃣ Why React Needs `useEffect`

React components are **re-executed frequently**.

If you fetch data directly inside the component body, it will:

* Run on every render
* Trigger infinite loops
* Break mental models

`useEffect` exists to say:

> “Run this code **after render**, under controlled conditions.”

---

## 3️⃣ The Professional Data Fetching Pattern

```js
import { useState, useEffect } from "react";

function UserProfile() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const response = await fetch(
          "https://jsonplaceholder.typicode.com/users/1"
        );
        const data = await response.json();
        setUser(data);
      } catch (err) {
        console.error(err);
      } finally {
        setLoading(false);
      }
    };

    fetchUser();
  }, []);

  if (loading) return <p>Loading...</p>;

  return <h1>{user.name}</h1>;
}
```

This is **not accidental complexity**.
Each piece solves a real problem.

---

## 4️⃣ Why `async` Is Inside `useEffect`

React does **not** allow the effect callback itself to be `async`.

❌ Wrong:

```js
useEffect(async () => {
  // not allowed
}, []);
```

✅ Correct:

```js
useEffect(() => {
  const fetchUser = async () => {
    // async work here
  };

  fetchUser();
}, []);
```

Reason:

* `useEffect` expects a cleanup function, not a Promise
* `async` functions always return a Promise

---

## 5️⃣ `async / await` (Readable Asynchronous Code)

```js
const response = await fetch(url);
const data = await response.json();
```

This is equivalent to chained promises, but:

* Reads top-to-bottom
* Handles errors naturally
* Easier to debug

> `await` pauses the function, **not the app**.

---

## 6️⃣ Error Handling with `try / catch / finally`

```js
try {
  // risky async work
} catch (err) {
  // handle errors
} finally {
  // always runs
}
```

In React data fetching:

* `try` → network request
* `catch` → network / parsing errors
* `finally` → cleanup or loading state

This ensures UI never gets “stuck.”

---

## 7️⃣ Dependency Array (`[]`) — Why It Matters

```js
useEffect(() => {
  fetchUser();
}, []);
```

The empty array means:

> “Run **once** after the first render.”

Common patterns:

| Dependency Array | Meaning                                  |
| ---------------- | ---------------------------------------- |
| `[]`             | Run once (on mount)                      |
| `[id]`           | Run when `id` changes                    |
| Omitted          | Run on **every render** (rarely correct) |

---

## 8️⃣ Conditional Rendering for Async States

```js
if (loading) return <p>Loading...</p>;
```

This pattern handles:

* Initial empty state
* Slow networks
* Prevents `null` access crashes

> Async data always needs **loading logic**.

---

## 9️⃣ Mental Model: The Render Cycle

1. Component renders (pure)
2. UI updates
3. `useEffect` runs (side effects)
4. State updates
5. React re-renders

Side effects never run **during render**.

---

## 🧠 Final Mental Models (Memorize These)

> **Rendering must be pure.**

> **Side effects live in `useEffect`.**

> **Async work always needs loading and error handling.**

---

### One-Line Rule for React

> **If it touches the outside world, it belongs in `useEffect`.**

---

### Key JS Concepts Used Here

* `async / await`
* `try / catch / finally`
* Closures
* Conditional rendering
* Controlled side effects

---

# 🧩 Part 10: Robust Error Handling

### *Don’t Trust `fetch()` to Fail Silently*

---

## 1️⃣ Why `fetch` Can Mislead You

`fetch()` only **rejects on network errors**, like:

* No internet connection
* DNS failure
* CORS blocked

> A `404` or `500` response **does not throw an error**.
> Your code must check `response.ok`.

---

## 2️⃣ Basic Pattern

```js
const response = await fetch(url);

if (!response.ok) {
  throw new Error(`HTTP error: ${response.status}`);
}

const data = await response.json();
```

* `response.ok` → `true` if status is 200–299
* `response.status` → exact HTTP status code
* Throwing ensures `catch` blocks handle it

---

## 3️⃣ Full Example in React

```js
import { useState, useEffect } from "react";

function UserProfile() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchUser = async () => {
      try {
        const response = await fetch("https://jsonplaceholder.typicode.com/users/1");

        if (!response.ok) {
          throw new Error(`HTTP error: ${response.status}`);
        }

        const data = await response.json();
        setUser(data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchUser();
  }, []);

  if (loading) return <p>Loading...</p>;
  if (error) return <p>Error: {error}</p>;

  return <h1>{user.name}</h1>;
}
```

---

## 4️⃣ Key Principles

1. **Always check `response.ok`**
2. **Throw errors explicitly** to enter `catch`
3. **Use `try / catch / finally`** to update UI states
4. **Never assume success** — users, servers, and networks fail

---

## 5️⃣ Professional Mental Model

```
fetch() → network layer
response.ok? → success check
throw → enters catch → UI handles gracefully
finally → clean up / stop loading
```

> Robust error handling = **predictable, resilient UI**

---

### One-Line Rule for React + Fetch

> **Check `response.ok`, throw if bad, catch and render errors.**

---

# 🧩 Part 11: Derived State — The Search Example

### *Don’t Store What You Can Calculate*

---

## 1️⃣ What is Derived State?

**Derived state** is **data you can compute from existing state or props**.

Example:

* `users` → original state
* `searchTerm` → user input
* `filteredUsers` → derived, can be computed on-the-fly

> Rule of thumb: **If it can be calculated, don’t store it.**

Storing derived state leads to:

* Redundant state
* Risk of inconsistencies
* Hard-to-debug bugs

---

## 2️⃣ React Example: Filtering a List

```js
function UserList({ users, searchTerm }) {
  const filteredUsers = users.filter(user =>
    user.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <ul>
      {filteredUsers.map(user => (
        <li key={user.id}>{user.name}</li>
      ))}
    </ul>
  );
}
```

### Why This Works

* `filteredUsers` is recalculated **on each render**
* No extra state needed
* Always consistent with `users` and `searchTerm`

---

## 3️⃣ Mental Model

```
State → minimal
Derived state → calculated
UI → render derived state
```

* `users` and `searchTerm` → source of truth
* `filteredUsers` → ephemeral, always in sync

---

## 4️⃣ Bonus: Using `useMemo` for Performance

If computing derived state is **expensive**, memoize it:

```js
import { useMemo } from "react";

const filteredUsers = useMemo(() => 
  users.filter(user =>
    user.name.toLowerCase().includes(searchTerm.toLowerCase())
  ),
  [users, searchTerm]
);
```

* Recalculates **only when dependencies change**
* Avoids unnecessary work on every render

---

### One-Line Rule for React

> **Store the minimal state needed; calculate the rest.**

---

# 🧩 Part 12: Controlled Components

### *React Controls the Input, Not the DOM*

---

## 1️⃣ What Is a Controlled Component?

A **controlled component** is an input element whose **value is fully controlled by React state**.

```js
<input
  value={searchTerm}
  onChange={e => setSearchTerm(e.target.value)}
/>
```

* `value` → always comes from state
* `onChange` → updates state
* UI never manages its own internal value

> React is the **single source of truth**.

---

## 2️⃣ One-Way Data Flow

```
User types → onChange → state updates → value renders
```

> UI → State → UI

This ensures:

* Predictable behavior
* Easy validation
* Consistent derived data

---

## 3️⃣ Comparison: Controlled vs Uncontrolled

### Controlled (React owns state)

```js
const [text, setText] = useState("");

<input value={text} onChange={e => setText(e.target.value)} />
```

* Pros: Predictable, easier to validate, works with derived state
* Cons: Slightly more boilerplate

---

### Uncontrolled (DOM owns state)

```js
<input defaultValue="Hello" />
```

* Pros: Less code for simple forms
* Cons: Hard to read value in React, hard to validate

> **Rule of thumb:** In React, prefer **controlled components**.

---

## 4️⃣ Practical Example: Search Input

```js
function SearchBar({ searchTerm, setSearchTerm }) {
  return (
    <input
      type="text"
      placeholder="Search users..."
      value={searchTerm}
      onChange={e => setSearchTerm(e.target.value)}
    />
  );
}
```

* Typing updates `searchTerm` in state
* Derived lists (e.g., filtered users) automatically update

---

## 5️⃣ Mental Model

```
React State
    │
    ▼
<Input value={state} onChange={updateState} />
    │
    ▼
UI reflects state
```

> React is **the boss of the input**.

---

### One-Line Rule for React

> **Controlled = React owns the value.**
> **Uncontrolled = DOM owns the value.**

---

# 🧩 Part 13: Component Refactoring & Lifting State Up

### *Organizing Components for Reusability and Clear Data Flow*

---

## 1️⃣ Refactoring Child Components

Instead of tightly coupling inputs to state, we **pass value and event handlers as props**:

```js
function SearchBar({ value, onChange }) {
  return (
    <input
      type="text"
      placeholder="Search users..."
      value={value}
      onChange={e => onChange(e.target.value)}
    />
  );
}
```

* `value` → controlled input state from parent
* `onChange` → notifies parent of changes
* Child is **stateless** and reusable

---

## 2️⃣ Parent Component Controls State

```js
function App() {
  const [searchTerm, setSearchTerm] = useState("");

  return (
    <div>
      <SearchBar value={searchTerm} onChange={setSearchTerm} />
    </div>
  );
}
```

* **Parent owns the state**
* Child simply **reports events**
* Clear, **top-down data flow**

---

## 3️⃣ Why Lifting State Up Matters

When multiple components need access to the same state:

* Store state in the **closest common ancestor**
* Pass down as props
* Children report changes via callbacks

This avoids **duplicate or conflicting state**.

---

### Example: Filtering Users

```js
function App() {
  const [searchTerm, setSearchTerm] = useState("");
  const users = [
    { id: 1, name: "John" },
    { id: 2, name: "Jane" },
    { id: 3, name: "Bob" }
  ];

  const filteredUsers = users.filter(user =>
    user.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div>
      <SearchBar value={searchTerm} onChange={setSearchTerm} />
      <ul>
        {filteredUsers.map(user => (
          <li key={user.id}>{user.name}</li>
        ))}
      </ul>
    </div>
  );
}
```

✅ Single source of truth
✅ Derived state calculated, not stored
✅ Controlled component drives UI

---

## 4️⃣ Integrated React Data Flow

```
User Action
   ↓
JS Event Handler
   ↓
Immutable State Update
   ↓
Array / Object Transforms
   ↓
Side Effects (useEffect)
   ↓
Reference Change
   ↓
React Re-render
   ↓
Browser Update
```

> This is **React’s mental model** for every UI interaction.

---

### One-Line Rule for React

> **Lift state up → control it in parent → children report events → UI stays consistent.**

---

# 🏁 Final Takeaway

> **React becomes simple when JavaScript is solid.**

If React ever feels **magical, unpredictable, or buggy**, the root cause is almost always:

* **References** — objects and arrays share memory
* **Closures** — functions remember state across renders
* **Mutation** — changing data in place breaks React’s reactivity
* **Side effects** — external operations must be controlled

---

### Your Mental Model (React + JavaScript)

```
User Action
   ↓
JS Event Handler
   ↓
Immutable State Update
   ↓
Derived Data / Transforms
   ↓
Side Effects (useEffect)
   ↓
Reference Change
   ↓
React Re-render
   ↓
Browser Update
```

---

### Core Principles to Remember

1. **Use `const` by default** — only reassign if necessary
2. **Keep state minimal** — calculate derived values, don’t store them
3. **Use controlled components** — React owns the UI
4. **Lift state up** — parent owns state, children report changes
5. **Handle side effects properly** — `useEffect`, `async/await`, and error handling
6. **Leverage modern JS features** — destructuring, spread, arrow functions, template strings
7. **Understand references** — prevent subtle bugs in arrays, objects, and React state

---

> Master these JavaScript fundamentals and React becomes **predictable, maintainable, and fun**.

React isn’t magic — it’s **a natural extension of good JavaScript**.

---

# 📎 Appendix: Common Mistakes vs Correct Patterns

### *Quick Reference for React + Modern JavaScript Gotchas*

---

## ⚠️ Bonus Gotcha: `this` Context (Regular Functions vs Arrow Functions)

> One of the **classic JS gotchas**—explains a lot of confusing behavior, especially coming from OOP-heavy languages.

**Key Rule:**

> `this` is determined by **how a function is called**, not where it is defined.

### Symptom

* On page load → `this` = **Window**
* On button click → `this` = **HTMLButtonElement**

### Why This Happens

* Regular function → `this` = caller
* Arrow function → `this` = surrounding scope

---

### ❌ Regular Function in a Class

```js
class Header {
  constructor() {
    this.color = "Red";
  }

  changeColor() {
    console.log(this.color); // undefined
  }
}
```

* `this` points to the caller (`window` / `button`)
* Class property lost

---

### ✅ Arrow Function (Lexical `this`)

```js
class Header {
  constructor() {
    this.color = "Red";
  }

  changeColor = () => {
    console.log(this.color); // "Red"
  };
}
```

* `this` is locked to the class instance
* No unexpected context issues

---

### Quick Reference

| Function Type    | How `this` Is Determined |
| ---------------- | ------------------------ |
| Regular function | Caller object            |
| Arrow function   | Scope where defined      |

> React function components avoid `this` entirely—closures replace it.

---

## 1️⃣ Mutating State Directly

### ❌ Mistake

```js
user.age = 31;
setUser(user);
```

* Same object reference → React sees **no change**
* UI does **not re-render**

### ✅ Correct

```js
setUser({ ...user, age: 31 });
```

* Creates a **new object reference**
* UI updates predictably

---

## 2️⃣ Updating State Based on Stale Values

### ❌ Mistake

```js
setCount(count + 1);
setCount(count + 1);
```

* Captures old closure → both updates use same value

### ✅ Correct

```js
setCount(prev => prev + 1);
setCount(prev => prev + 1);
```

* Safe for async updates

---

## 3️⃣ Side Effects in Render

### ❌ Mistake

```js
function Component() {
  fetchData();
  return <div />;
}
```

* Runs on every render → infinite loop

### ✅ Correct

```js
useEffect(() => {
  fetchData();
}, []);
```

> Render = pure. Side effects = `useEffect`.

---

## 4️⃣ Incorrect `useEffect` Dependencies

### ❌ Mistake

```js
useEffect(() => {
  setCount(count + 1);
}, [count]);
```

* Infinite loop

### ✅ Correct

* Run once:

```js
useEffect(() => {
  fetchData();
}, []);
```

* Run on change:

```js
useEffect(() => {
  console.log(count);
}, [count]);
```

---

## 5️⃣ Storing Derived State

### ❌ Mistake

```js
const [filteredUsers, setFilteredUsers] = useState([]);
```

* Duplicate source of truth → desync risk

### ✅ Correct

```js
const filteredUsers = users.filter(user =>
  user.name.includes(searchTerm)
);
```

> Compute what can be derived

---

## 6️⃣ Using `for` Loops Instead of Declarative Rendering

### ❌ Mistake

```js
for (let i = 0; i < items.length; i++) {
  elements.push(<li>{items[i]}</li>);
}
```

### ✅ Correct

```js
items.map(item => <li key={item.id}>{item.name}</li>);
```

* Declarative → predictable and clean

---

## 7️⃣ Forgetting `key` in Lists

### ❌ Mistake

```js
items.map(item => <li>{item.name}</li>);
```

* React cannot track identity → rendering bugs

### ✅ Correct

```js
items.map(item => <li key={item.id}>{item.name}</li>);
```

---

## 8️⃣ Overusing `useEffect`

### ❌ Mistake

```js
useEffect(() => {
  setFilteredUsers(...);
}, [users, searchTerm]);
```

* Effect used for pure computation → unnecessary re-renders

### ✅ Correct

```js
const filteredUsers = users.filter(...);
```

> `useEffect` = side effects only

---

## 9️⃣ Mixing Logic and Presentation

### ❌ Mistake

* One giant component that fetches data, filters, handles inputs, and renders UI

### ✅ Correct

* Parent: **data + state**
* Child: **UI only**

```js
<SearchBar value={searchTerm} onChange={setSearchTerm} />
```

---

## 🔟 Thinking React Is the Source of Truth

### ❌ Mistake

> “React will handle it automatically.”

### ✅ Correct Mental Model

> **JavaScript holds the truth; React reflects it.**

---

## 🧠 Final Debugging Mantra

When something breaks, ask:

1. Did I mutate state?
2. Did the reference change?
3. Is this derived or side-effectful?
4. Is a closure capturing stale data?
5. Does my `useEffect` dependency array match my intent?

> Answering these 5 questions solves ~90% of React bugs.

