# 🧠 JavaScript Functional Programming

# The Beginner-Friendly Deep Dive

## From Mutation & Loops → Predictable Data Transformations

Functional Programming (FP) was one of the biggest mindset shifts in my JavaScript journey.

At first, JavaScript felt like this:

```js
for loops
variables
mutations
manual updates
```

But modern JavaScript — especially in React — heavily favors a different style:

```text
Transform data instead of manually controlling state
```

This tutorial/repository is my personal reference for understanding:

* functional programming
* immutable thinking
* predictable state management
* modern JavaScript architecture
* React state patterns
* data transformation pipelines

The deeper I learn JavaScript, the more I realize:

```text
Modern frontend engineering is mostly:
- transforming data
- preserving immutability
- managing references
- composing predictable behavior
```

Functional Programming is NOT about:

* avoiding loops to look clever
* writing unreadable one-liners
* making code “academic”

It is about:

```text
Predictable data flow
```

That idea powers:

* React
* Redux
* Zustand
* reducers
* event systems
* frontend architecture
* modern state management

---

# 📂 Suggested Repository Structure

A logical flow from:

* WHY FP matters
  → HOW it works
  → WHERE it is used in real apps

```text
functional-programming/
│
├── README.md
│
├── fundamentals/           # The "Why"
│   ├── imperative-vs-functional.js
│   ├── pure-functions.js
│   ├── immutability.js
│   ├── references.js
│   ├── shallow-vs-deep-copy.js
│   └── side-effects.js
│
├── array-methods/          # The "How"
│   ├── map.js
│   ├── filter.js
│   ├── reduce.js
│   ├── chaining.js
│   ├── composition.js
│   └── pipelines.js
│
├── real-world/             # Real app patterns
│   ├── shopping-cart.js
│   ├── todo-app.js
│   ├── analytics-dashboard.js
│   ├── api-data-transform.js
│   └── state-normalization.js
│
├── advanced/               # Advanced FP
│   ├── currying.js
│   ├── closures.js
│   ├── memoization.js
│   ├── recursion.js
│   └── functional-pipelines.js
│
└── react-patterns/         # React internals mindset
    ├── immutable-state.js
    ├── reducers.js
    ├── structural-sharing.js
    └── referential-equality.js
```

---

# 🚀 Running the Examples

I can run every file individually using Node.js.

Example:

```bash
node fundamentals/pure-functions.js

node array-methods/map.js

node real-world/todo-app.js
```

---

# ⚖️ The Big Mental Shift

One of the biggest breakthroughs in my learning journey was realizing:

```text
Imperative programming controls behavior.
Functional programming transforms data.
```

---

# 🧠 Imperative vs Functional Thinking

| Feature             | Imperative (Old Way)      | Functional (Modern Way) |
| ------------------- | ------------------------- | ----------------------- |
| Logic               | Step-by-step instructions | Data transformations    |
| Focus               | HOW                       | WHAT                    |
| State               | Mutable                   | Immutable               |
| Data Updates        | In-place changes          | New copies              |
| Control Flow        | Loops & conditions        | Higher-order functions  |
| Predictability      | Lower                     | Higher                  |
| Side Effects        | Common                    | Minimized               |
| React Compatibility | Poor                      | Excellent               |

---

# 🧠 Mental Model

Imperative programming asks:

```text
HOW do I do this?
```

Functional programming asks:

```text
WHAT transformation do I want?
```

---

# 📄 fundamentals/imperative-vs-functional.js

```js
console.log("=== IMPERATIVE VS FUNCTIONAL ===");

const numbers = [1, 2, 3, 4, 5];

console.log("\nOriginal:");
console.log(numbers);

console.log("\n----------------------");
console.log("IMPERATIVE STYLE");

/**
 * Imperative Programming:
 * 
 * I manually control:
 * - loop counters
 * - mutations
 * - indexes
 * - pushing values
 */

const doubledImperative = [];

for (let i = 0; i < numbers.length; i++) {
  doubledImperative.push(numbers[i] * 2);
}

console.log(doubledImperative);

console.log("\n----------------------");
console.log("FUNCTIONAL STYLE");

/**
 * Functional Programming:
 * 
 * I describe the transformation instead.
 */

const doubledFunctional = numbers.map(
  num => num * 2
);

console.log(doubledFunctional);
```

---

# 🧠 Functional Programming Mental Model

I think of FP like this:

```text
Input Data
     ↓
Transformation
     ↓
New Output Data
```

NOT this:

```text
Input Data
     ↓
Mutate Existing Data
     ↓
Hope Nothing Broke
```

---

# 🛠 Core Principles of Functional Programming

---

# 1. Immutability

Immutability means:

```text
Never directly modify existing data
```

Instead:

```text
Create NEW data with changes
```

---

# 🧠 Why Immutability Matters

In React, updates are detected using:

```js
oldReference === newReference
```

If references stay identical:

* React assumes nothing changed
* no re-render occurs
* UI bugs happen

Immutability guarantees:

* predictable updates
* safe state transitions
* reliable rendering

---

# 🧠 Mental Model

Mutation:

```text
Edit original document directly
```

Immutability:

```text
Photocopy document first,
then edit the copy
```

---

# 📄 fundamentals/immutability.js

```js
console.log("=== IMMUTABILITY ===");

const users = ["Sean", "Sarah"];

console.log("\nOriginal:");
console.log(users);

console.log("\n----------------------");
console.log("MUTATION");

/**
 * push() MUTATES the original array
 */

users.push("Sonia");

console.log(users);

console.log("\n----------------------");
console.log("IMMUTABLE UPDATE");

/**
 * Spread operator creates a NEW array
 */

const updatedUsers = [
  ...users,
  "Serenity"
];

console.log("\nOriginal:");
console.log(users);

console.log("\nUpdated:");
console.log(updatedUsers);

/**
 * React prefers NEW references
 * because shallow comparison becomes fast.
 */
```

---

# 🧠 Mutation vs Immutability Cheat Sheet

| Action        | Mutating ❌        | Immutable ✅          |
| ------------- | ----------------- | -------------------- |
| Add to End    | `push()`          | `[...arr, item]`     |
| Add to Start  | `unshift()`       | `[item, ...arr]`     |
| Remove Last   | `pop()`           | `slice(0, -1)`       |
| Remove First  | `shift()`         | `slice(1)`           |
| Remove Item   | `splice()`        | `filter()`           |
| Update Item   | `arr[index] = x`  | `map()`              |
| Sort Array    | `sort()`          | `[...arr].sort()`    |
| Reverse Array | `reverse()`       | `[...arr].reverse()` |
| Copy Object   | direct assignment | `{...obj}`           |
| Deep Clone    | ❌                 | `structuredClone()`  |

---

# ⚠️ Common Mutation Traps

Some methods silently mutate arrays:

| Method      | Mutates? |
| ----------- | -------- |
| `push()`    | ✅        |
| `pop()`     | ✅        |
| `shift()`   | ✅        |
| `unshift()` | ✅        |
| `splice()`  | ✅        |
| `sort()`    | ✅        |
| `reverse()` | ✅        |

Safe methods:

| Method     | Mutates? |
| ---------- | -------- |
| `map()`    | ❌        |
| `filter()` | ❌        |
| `reduce()` | ❌        |
| `slice()`  | ❌        |
| `concat()` | ❌        |

---

# 2. Pure Functions

A pure function:

* always returns same output for same input
* does not mutate outside state
* has no hidden side effects
* is deterministic

---

# 📄 fundamentals/pure-functions.js

```js
console.log("=== PURE FUNCTIONS ===");

console.log("\n----------------------");
console.log("PURE FUNCTION");

/**
 * Same Input = Same Output
 */

function add(a, b) {
  return a + b;
}

console.log(add(2, 3));
console.log(add(2, 3));

console.log("\n----------------------");
console.log("IMPURE FUNCTION");

let total = 0;

/**
 * External state mutation
 */

function addToTotal(value) {
  total += value;
  return total;
}

console.log(addToTotal(5));
console.log(addToTotal(5));
```

---

# 🧠 Pure Function Mental Model

Pure functions behave like:

```text
Math formulas
```

Example:

```text
2 + 2 always equals 4
```

No surprises.
No hidden behavior.
Easy to debug.

---

# 🧠 Benefits of Pure Functions

| Benefit     | Why It Matters         |
| ----------- | ---------------------- |
| Predictable | Easier debugging       |
| Reusable    | Works anywhere         |
| Testable    | No hidden dependencies |
| Composable  | Easy to combine        |
| Safer       | Fewer side effects     |

---

# 3. Side Effects

A side effect is anything affecting external state.

Examples:

* API calls
* database writes
* DOM updates
* timers
* logging
* modifying variables

---

# 📄 fundamentals/side-effects.js

```js
console.log("=== SIDE EFFECTS ===");

let count = 0;

console.log("\nBefore:");
console.log(count);

/**
 * Side effect:
 * modifies external state
 */

function increment() {
  count++;
}

increment();

console.log("\nAfter:");
console.log(count);

console.log("\n----------------------");

/**
 * Pure alternative
 */

function pureIncrement(value) {
  return value + 1;
}

const updatedCount = pureIncrement(count);

console.log(updatedCount);
```

---

# 🧠 Side Effects Mental Model

Side effects are like:

```text
Functions secretly changing the outside world
```

Pure functions:

```text
Only transform inputs into outputs
```

---

# 🧬 Essential Array Methods

These are the “Big Three” of modern JavaScript.

---

# 🧠 map() → The Transformer

Returns:

* NEW array
* SAME length

Used for:

* transforming values
* reshaping data
* extracting properties

---

# 📄 array-methods/map.js

```js
console.log("=== MAP ===");

const numbers = [1, 2, 3, 4];

console.log("\nOriginal:");
console.log(numbers);

/**
 * Transform every item
 */

const doubled = numbers.map(
  num => num * 2
);

console.log("\nDoubled:");
console.log(doubled);

console.log("\nOriginal remains unchanged:");
console.log(numbers);

console.log("\n----------------------");

/**
 * Real-world example:
 * extract names
 */

const users = [
  { id: 1, name: "Sean" },
  { id: 2, name: "Sarah" },
];

const names = users.map(
  user => user.name
);

console.log(names);
```

---

# 🧠 map() Mental Model

```text
Assembly Line Transformer
```

Visual:

```text
🍎 → sliced 🍎
🍌 → sliced 🍌
🍒 → sliced 🍒
```

Or:

```text
1 → 2
2 → 4
3 → 6
```

---

# 🧠 filter() → The Gatekeeper

Returns:

* NEW array
* POTENTIALLY smaller array

Used for:

* removing items
* applying conditions
* filtering datasets

---

# 📄 array-methods/filter.js

```js
console.log("=== FILTER ===");

const users = [
  { name: "Sean", active: true },
  { name: "Sarah", active: false },
  { name: "Sonia", active: true },
];

console.log("\nOriginal:");
console.log(users);

/**
 * Keep only active users
 */

const activeUsers = users.filter(
  user => user.active
);

console.log("\nActive Users:");
console.log(activeUsers);
```

---

# 🧠 filter() Mental Model

```text
Security Checkpoint
```

Each item gets asked:

```text
"Do you pass?"
```

YES → allowed through
NO → removed

---

# 🧠 reduce() → The Accumulator

The most powerful array method.

It collapses MANY values into ONE value.

Possible outputs:

* number
* string
* object
* map
* grouped structure
* another array

---

# 📄 array-methods/reduce.js

```js
console.log("=== REDUCE ===");

const prices = [10, 20, 30];

console.log("\nPrices:");
console.log(prices);

/**
 * Accumulator Snowball
 */

const total = prices.reduce(
  (accumulator, current) => {
    return accumulator + current;
  },
  0
);

console.log("\nTotal:");
console.log(total);

console.log("\n----------------------");
console.log("STEP-BY-STEP VISUALIZATION");

prices.reduce((accumulator, current) => {

  console.log(`
  accumulator: ${accumulator}
  current: ${current}
  next value: ${accumulator + current}
  `);

  return accumulator + current;

}, 0);
```

---

# 🧠 reduce() Mental Model

I visualize reduce like:

```text
A snowball rolling downhill
```

Visualization:

```text
START
accumulator = 0

Iteration 1:
0 + 10 = 10

Iteration 2:
10 + 20 = 30

Iteration 3:
30 + 30 = 60

FINAL RESULT = 60
```

---

# 🧠 Why reduce() Feels Hard

Because it can become:

* anything
* everything
* infinitely flexible

Unlike:

* `map()` → transforms
* `filter()` → removes

`reduce()` is:

```text
Build whatever you want
```

---

# 📄 array-methods/chaining.js

```js
console.log("=== METHOD CHAINING ===");

const users = [
  { name: "Sean", active: true, age: 58 },
  { name: "Sarah", active: false, age: 28 },
  { name: "Sonia", active: true, age: 18 },
  { name: "Serenity", active: true, age: 88 },
];

console.log("\nOriginal:");
console.log(users);

/**
 * Data pipeline:
 * 
 * 1. Filter active users
 * 2. Extract names
 * 3. Convert to uppercase
 */

const result = users
  .filter(user => user.active)
  .map(user => user.name)
  .map(name => name.toUpperCase());

console.log("\nResult:");
console.log(result);
```

---

# 🧠 Method Chaining Mental Model

```text
Raw Data
   ↓
Filter
   ↓
Transform
   ↓
Transform Again
   ↓
Final Result
```

Like a factory conveyor belt.

---

# 🧠 Function Composition

FP loves:

* small functions
* reusable functions
* composable functions

---

# 📄 array-methods/composition.js

```js
console.log("=== FUNCTION COMPOSITION ===");

const double = x => x * 2;

const square = x => x * x;

const addFive = x => x + 5;

/**
 * Composition:
 * 
 * Small functions combine
 * into larger behaviors
 */

const result = addFive(
  square(
    double(3)
  )
);

console.log(result);
```

---

# 🧠 Composition Mental Model

Like LEGO blocks.

Small functions snap together to build bigger systems.

---

# ⚠️ The Shallow Copy Trap

This was one of my biggest JavaScript “aha!” moments.

---

# 🧠 Shallow Copy vs Deep Copy

| Type                | Copies Nested Objects? | Safe?     |
| ------------------- | ---------------------- | --------- |
| Spread (`...`)      | ❌ No                   | Sometimes |
| `Object.assign()`   | ❌ No                   | Sometimes |
| `structuredClone()` | ✅ Yes                  | Yes       |

---

# 📄 fundamentals/shallow-vs-deep-copy.js

```js
console.log("=== SHALLOW VS DEEP COPY ===");

const user = {
  name: "Sean",
  address: {
    city: "Tanjong Pagar",
  },
};

console.log("\nOriginal:");
console.log(user);

console.log("\n----------------------");
console.log("SHALLOW COPY");

/**
 * Only top level copied
 */

const shallowCopy = {
  ...user
};

shallowCopy.address.city = "Chinatown";

console.log("\nOriginal CORRUPTED:");
console.log(user.address.city);

console.log("\n----------------------");
console.log("DEEP COPY");

/**
 * Full recursive copy
 */

const deepCopy = structuredClone(user);

deepCopy.address.city = "Orchard";

console.log("\nOriginal Safe:");
console.log(user.address.city);

console.log("\nDeep Copy:");
console.log(deepCopy.address.city);
```

---

# 🧠 Shallow Copy Mental Model

```text
New shell,
same internal organs
```

Deep copy:

```text
Entirely cloned organism
```

---

# ⚛️ FP in the Wild: React Patterns

If I understand FP:

```text
I already understand most React state updates
```

---

# 📄 real-world/todo-app.js

```js
console.log("=== TODO APP ===");

let todos = [
  {
    id: 1,
    text: "Learn JavaScript",
    completed: false,
  },
];

console.log("\nOriginal:");
console.log(todos);

/**
 * Map + Spread Pattern
 */

todos = todos.map(todo =>
  todo.id === 1
    ? {
        ...todo,
        completed: !todo.completed,
      }
    : todo
);

console.log("\nUpdated:");
console.log(todos);
```

---

# 🧠 React State Update Mental Model

```text
Find target item
        ↓
Create NEW object
        ↓
Keep untouched references
        ↓
Return NEW array
```

This is called:

```text
Structural Sharing
```

Only changed branches get new references.

Everything else is reused.

---

# 📄 real-world/shopping-cart.js

```js
console.log("=== SHOPPING CART ===");

const cart = [
  { id: 1, name: "Keyboard", price: 30 },
  { id: 2, name: "Mouse", price: 10 },
  { id: 3, name: "Laptop", price: 1500 },
];

console.log("\nOriginal Cart:");
console.log(cart);

/**
 * Derive total using reduce
 */

const total = cart.reduce(
  (sum, item) => sum + item.price,
  0
);

console.log("\nCart Total:");
console.log(total);

console.log("\n----------------------");
console.log("IMMUTABLE ADD ITEM");

const updatedCart = [
  ...cart,
  { id: 4, name: "Monitor", price: 300 },
];

console.log(updatedCart);
```

---

# ⚠️ Common Pitfalls

---

# 1. Invisible Mutation

These mutate:

* `sort()`
* `reverse()`
* `splice()`

Safe version:

```js
const sorted = [...users].sort();
```

---

# 2. Forgetting return in map()

Wrong:

```js
arr.map(item => {
  item * 2;
});
```

Correct:

```js
arr.map(item => item * 2);
```

---

# 3. forEach vs map()

| Method      | Returns Value? |
| ----------- | -------------- |
| `map()`     | ✅ NEW array    |
| `forEach()` | ❌ undefined    |

Use:

* `map()` for transformations
* `forEach()` for side effects

---

# 4. Overusing reduce()

Sometimes simpler is better.

Prefer:

* `map()`
* `filter()`
* `find()`

when readability improves.

---

# 🧠 Functional Programming Cheat Sheet

| Goal                  | Functional Pattern  |
| --------------------- | ------------------- |
| Transform items       | `map()`             |
| Remove items          | `filter()`          |
| Collapse values       | `reduce()`          |
| Add item immutably    | `[...arr, item]`    |
| Update item immutably | `map()`             |
| Remove item immutably | `filter()`          |
| Copy object           | `{...obj}`          |
| Deep clone            | `structuredClone()` |

---

# 🧠 The Big Realization

One of the biggest breakthroughs in my JavaScript journey was realizing:

> Functional programming is really about predictable state transitions.

The goal is NOT:

* clever syntax
* fancy one-liners
* avoiding loops completely

The goal is:

```text
Predictable transformations
```

That single idea explains:

* React rendering
* Redux reducers
* Zustand updates
* immutable architecture
* frontend scalability

---

# 🛠 Future Topics I Want To Add

As I continue learning, I want to expand this repo with:

* currying
* closures
* memoization
* generators
* async pipelines
* transducers
* RxJS
* reducers
* monads
* lazy evaluation

---

# 🚀 Final Thoughts

The deeper I go into JavaScript engineering, the more I realize:

```text
Modern applications are mostly:
- state transitions
- data transformations
- immutable updates
- reference management
- predictable rendering
```

Functional programming gave me a cleaner mental model for understanding:

* React
* frontend architecture
* scalable state management
* predictable systems

Instead of manually controlling everything:

```text
I now focus on transforming data predictably.
```

And that mindset completely changed how I write JavaScript.
