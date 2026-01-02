# 🌐 **Key JavaScript Concepts**

To master JS at a professional level, you need to move beyond syntax and understand **prototypes, closures, async patterns, and functional paradigms**. This tutorial mirrors advanced Python concepts in JavaScript.

---

## 1. Classes & “Magic” Methods

JS classes use **constructor**, **toString()**, and operator-like methods via prototypes. While JS doesn’t have dunder methods like Python, you can emulate similar behavior.

```javascript
class Vector {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }

  add(other) {
    return new Vector(this.x + other.x, this.y + other.y);
  }

  magnitude() {
    return Math.sqrt(this.x ** 2 + this.y ** 2);
  }

  toString() {
    return `Vector(${this.x}, ${this.y})`;
  }
}

const v1 = new Vector(3, 4);
const v2 = new Vector(1, 2);
console.log(v1.add(v2).toString()); // Vector(4, 6)
console.log(v1.magnitude());        // 5
```

---

## 2. Rest & Spread (Variadic Arguments)

JS uses `...args` to collect variable numbers of arguments, like Python’s `*args` and `**kwargs`.

```javascript
function logEvent(event, ...tags) {
  const metadata = tags.pop() || {};
  console.log("Event:", event);
  console.log("Tags:", tags);
  console.log("Metadata:", metadata);
}

logEvent("purchase", "urgent", "online", { userId: 42 });
```

---

## 3. Decorators / Function Wrappers (Logic Injection)

JS doesn’t have native decorators (outside TypeScript), but **higher-order functions** achieve the same.

```javascript
function authRequired(fn) {
  return function (...args) {
    const self = this;
    if (!self._authenticated) throw new Error("Unauthorized");
    return fn.apply(self, args);
  };
}

class Account {
  constructor(owner) {
    this.owner = owner;
    this._authenticated = false;
  }

  login(password) {
    this._authenticated = password === "secret";
  }

  @authRequired // If using JS decorators (experimental), otherwise wrap manually
  deposit(amount) {
    console.log(`Deposited $${amount}`);
  }
}
```

---

## 4. Resource & Memory Management

### 4.1 Async / Await (Context Management Equivalent)

JS handles resources via `try...finally` or **async functions**:

```javascript
async function withLogger(file, callback) {
  const fs = require("fs").promises;
  try {
    await callback({
      log: async (msg) => fs.appendFile(file, msg + "\n")
    });
  } finally {
    console.log("Logger closed");
  }
}

await withLogger("transactions.log", async (logger) => {
  await logger.log("Transaction completed");
});
```

### 4.2 Generators & Lazy Evaluation

```javascript
function* fibonacci(n) {
  let a = 0, b = 1;
  for (let i = 0; i < n; i++) {
    yield a;
    [a, b] = [b, a + b];
  }
}

for (const num of fibonacci(5)) {
  console.log(num);
}
```

---

## 5. Type Safety & Constants

```javascript
const MAX_USERS = 100; // Constant

/** @param {number} a
 *  @param {number} b
 *  @returns {number} */
function add(a, b) {
  return a + b;
}
```

---

## 6. Getters / Setters (Property Decorators)

```javascript
class Person {
  constructor(name, age) {
    this.name = name;
    this._age = age;
  }

  get age() {
    return this._age;
  }

  set age(value) {
    if (value < 0) throw new Error("Age cannot be negative");
    this._age = value;
  }
}
```

---

## 7. Array & Object Comprehensions

JS uses **map, filter, reduce** instead of Python comprehensions:

```javascript
const nums = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

// Map + Filter: squares of even numbers
const squares = nums.filter(x => x % 2 === 0).map(x => x ** 2);

// Object map
const users = [{id: 1, name: "Alice"}, {id: 2, name: "Bob"}];
const userMap = Object.fromEntries(users.map(u => [u.id, u.name]));

// Set from array
const tags = ["JS", "js", "JS"];
const uniqueTags = new Set(tags.map(t => t.toLowerCase()));

console.log(squares, userMap, uniqueTags);
```

---

## 8. Real-World Example: Bank System

```javascript
class BankAccount {
  static INTEREST_RATE = 0.02;

  constructor(owner, balance = 0) {
    this.owner = owner;
    this._balance = balance;
    this._authenticated = false;
    this.transactions = [];
  }

  login(password) {
    this._authenticated = password === "secret";
  }

  deposit(amount, ...tags) {
    if (!this._authenticated) throw new Error("Unauthorized");
    this._balance += amount;
    const metadata = typeof tags[tags.length-1] === "object" ? tags.pop() : {};
    this.transactions.push({amount, tags, metadata});
    console.log(`Deposited $${amount}`);
  }

  withdraw(amount) {
    if (!this._authenticated) throw new Error("Unauthorized");
    if (amount > this._balance) throw new Error("Insufficient funds");
    this._balance -= amount;
    this.transactions.push({amount: -amount, tags: [], metadata: {}});
    console.log(`Withdrew $${amount}`);
  }

  *transactionHistory() {
    for (let i = 0; i < this.transactions.length; i++) {
      const t = this.transactions[i];
      yield `Txn ${i+1}: $${t.amount}, Tags: ${t.tags}, Meta: ${JSON.stringify(t.metadata)}`;
    }
  }

  *calculateInterest() {
    for (const t of this.transactions) {
      if (t.amount > 0) yield t.amount * BankAccount.INTEREST_RATE;
    }
  }
}

// Usage
const acc1 = new BankAccount("Alice", 1000);
acc1.login("secret");
acc1.deposit(200, "salary", {userId: 101});
acc1.withdraw(150);

console.log([...acc1.transactionHistory()]);
console.log([...acc1.calculateInterest()]);
```

---

## ✅ Concepts Illustrated

| Concept                | JS Example              | Use Case                                |
| ---------------------- | ----------------------- | --------------------------------------- |
| Classes & Methods      | `class BankAccount`     | Object-oriented modeling                |
| Rest & Spread          | `...tags`               | Variadic arguments                      |
| Higher-Order Functions | `authRequired`          | Decorator-like logic                    |
| Getters/Setters        | `get age() / set age()` | Safe property access                    |
| Generators             | `*transactionHistory()` | Lazy evaluation                         |
| Async Functions        | `withLogger()`          | Resource & memory management            |
| Constants              | `const MAX_USERS`       | Safe immutable values                   |
| Map/Filter/Reduce      | `[...].filter().map()`  | Comprehension-style collection creation |

---

