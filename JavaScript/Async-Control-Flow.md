# 🚀 Asynchronous Control Flow in JavaScript

## Beginner → Production Engineering Tutorial Series

> Learn async JavaScript by understanding how the runtime *actually behaves*, not just the syntax.

---

# 📁 Repo Structure

```text
async-control-flow-series/
│
├── 00-introduction/
├── 01-blocking-vs-non-blocking/
├── 02-callbacks/
├── 03-promises/
├── 04-async-await/
├── 05-event-loop/
├── 06-closure-loop-trap/
├── 07-parallel-vs-sequential/
├── 08-streams/
│
├── 09-queues/
├── 10-retries/
├── 11-backpressure/
├── 12-timeouts/
├── 13-circuit-breaker/
├── 14-dead-letter-queue/
│
└── 15-final-system/
```

---

# 📘 00 — Introduction

## 🧠 Explanation (Expanded)

JavaScript runs on a **single-threaded call stack**, meaning only one function executes at a time.

Yet modern apps behave like they are doing many things simultaneously:

* API calls in the background
* UI remains responsive
* timers execute later
* streams process continuously

This is achieved through **asynchronous delegation**, where work is handed off to the runtime (browser / Node.js APIs), and JavaScript continues executing.

---

## 💻 Code Example (Basic async delegation)

```javascript
console.log("Start");

// delegated async operation
setTimeout(() => {
  console.log("Async task completed");
}, 1000);

console.log("End");
```

### 🧠 Execution Order

1. Start
2. End
3. Async task completed (later)

---

## 🔧 Function Call Mental Model

Even `setTimeout` behaves like:

```javascript
function fakeSetTimeout(callback, delay) {
  // runtime takes over timing
  runtime.registerTimer(delay, callback);
}
```

---

## 🧪 Exercise

* Name 3 async operations in real apps
* What breaks if JS was fully blocking?

---

# 📘 01 — Blocking vs Non-Blocking

## 🧠 Explanation

Blocking = halts everything
Non-blocking = delegates and continues

---

## 💻 Code Example

```javascript
console.log("Start");

// ❌ blocking operation
for (let i = 0; i < 1e9; i++) {
  // CPU heavy loop blocks main thread
}

console.log("End");
```

---

## ✔ Non-blocking version

```javascript
console.log("Start");

setTimeout(() => {
  console.log("Async done");
}, 0); // delegated immediately

console.log("End");
```

---

## 🔧 Function Call Model

```javascript
function blockingTask() {
  // occupies call stack fully
  for (let i = 0; i < 1e9; i++) {}
}

function nonBlockingTask(callback) {
  setTimeout(callback, 0); // delegated
}
```

---

# 📘 02 — Callbacks

## 🧠 Explanation

A callback is simply:

> a function passed into another function to be executed later

But deeper meaning:

> You are giving control of execution timing away (inversion of control)

---

## 💻 Your Enhanced Example (with full inline commentary)

```javascript
function doTask(taskName, callback) {
  console.log("Starting task:", taskName);

  // simulate async work delegated to runtime
  setTimeout(() => {
    console.log("Task complete:", taskName);

    // callback runs AFTER async completion
    callback(); // execution returned later
  }, 1000);
}
```

---

## 🧪 FUNCTION CALL USAGE (your requested line, enriched)

```javascript
doTask("Demo", () => {
  console.log("Callback Executed"); 
  // runs ONLY after async work finishes
});
```

---

## 🧠 Execution Breakdown

1. `doTask()` starts
2. logs "Starting task: Demo"
3. schedules timer
4. function exits
5. later → callback runs

---

## 🔥 Mental Model (Important)

```javascript
doTask("A", callback);

// roughly behaves like:
runtime.queueLater(callback);
```

---

## ⚠️ Real-world problem: callback nesting

```javascript
doTask("A", () => {
  doTask("B", () => {
    doTask("C", () => {
      console.log("Deep nesting 😵");
    });
  });
});
```

This is the origin of **callback hell**.

---

# 📘 03 — Promises

## 🧠 Explanation

Promise = a structured representation of future completion.

---

## 💻 Code Example

```javascript
function delay(ms) {
  return new Promise((resolve) => {
    setTimeout(() => {
      resolve(`Done after ${ms}ms`);
    }, ms);
  });
}
```

---

## 🔧 Equivalent mental model

```javascript
function delay(ms) {
  return {
    then: function(callback) {
      setTimeout(() => callback(`Done after ${ms}ms`), ms);
    }
  };
}
```

---

## 🧪 Usage

```javascript
delay(1000).then((msg) => {
  console.log(msg);
});
```

---

# 📘 04 — Async / Await

## 🧠 Explanation

Async/await is:

> syntactic sugar over Promises

---

## 💻 Example

```javascript
async function run() {
  console.log("Step 1");

  await delay(1000); // pauses function ONLY

  console.log("Step 2");

  await delay(1000);

  console.log("Step 3");
}
```

---

## 🧠 Key Insight

Only the function pauses — NOT the thread.

---

# 📘 05 — Event Loop

## 🧠 Explanation

The event loop is the scheduler that decides execution order.

---

## 💻 Example

```javascript
console.log("A");

setTimeout(() => console.log("B"), 0);

Promise.resolve().then(() => console.log("C"));

console.log("D");
```

---

## 🧠 Output

```
A
D
C
B
```

---

## 🔧 Internal Model

```javascript
callStack.execute();

microtaskQueue.flushFirst();
taskQueue.flushAfter();
```

---

# 📘 06 — Closure Loop Trap

## 🧠 Explanation

Async callbacks capture variables, not values.

---

## 💻 Problem Example

```javascript
for (var i = 0; i < 3; i++) {
  setTimeout(() => {
    console.log(i); // prints 3, 3, 3
  }, 100);
}
```

---

## ✔ Fixed version

```javascript
for (let i = 0; i < 3; i++) {
  setTimeout(() => {
    console.log(i); // 0, 1, 2
  }, 100);
}
```

---

## 🔧 Function-call mental model

```javascript
function createTimer(i) {
  return function () {
    console.log(i);
  };
}
```

---

# 📘 07 — Sequential vs Parallel

## 💻 Sequential

```javascript
await task("A", 1000);
await task("B", 1000);
await task("C", 1000);
```

---

## 💻 Parallel

```javascript
await Promise.all([
  task("A", 1000),
  task("B", 1000),
  task("C", 1000),
]);
```

---

## 🧠 Insight

* sequential = sum time
* parallel = max time

---

# 📘 08 — Streams

## 🧠 Explanation

Streams process data incrementally.

---

## 💻 Simulation

```javascript
function processStream() {
  let chunk = 0;

  const interval = setInterval(() => {
    chunk++;

    console.log("Processing chunk:", chunk);

    if (chunk === 5) {
      clearInterval(interval);
      console.log("Stream complete");
    }
  }, 500);
}

processStream();
```

---

# 📘 09 — Queues (Core idea)

```javascript
function queueTask(task) {
  setTimeout(() => {
    console.log("Processing:", task);
  }, 0);
}
```

---

# 📘 10 — Retries

```javascript
async function retry(task, attempts = 3) {
  for (let i = 0; i < attempts; i++) {
    try {
      return await task();
    } catch (e) {
      console.log("Retrying...");
    }
  }
}
```

---

# 📘 11 — Backpressure

```javascript
let queue = [];

function push(item) {
  if (queue.length > 1000) {
    console.log("Backpressure triggered");
    return;
  }

  queue.push(item);
}
```

---

# 📘 12 — Timeouts

```javascript
function withTimeout(promise, ms) {
  return Promise.race([
    promise,
    new Promise((_, reject) =>
      setTimeout(() => reject("Timeout"), ms)
    )
  ]);
}
```

---

# 📘 13 — Circuit Breaker

```javascript
let failures = 0;

function circuit(task) {
  if (failures > 3) {
    console.log("Circuit OPEN");
    return;
  }

  task().catch(() => failures++);
}
```

---

# 📘 14 — Dead Letter Queue

```javascript
let dlq = [];

function handleFailure(task) {
  dlq.push(task);
  console.log("Moved to DLQ");
}
```

---

# 📘 15 — Final System

## 🧠 Real system model

* retries
* timeouts
* queues
* streams
* circuit breakers

---

## 🔥 Final Mental Model

> You are not writing functions.
> You are designing time, flow, and failure handling.
