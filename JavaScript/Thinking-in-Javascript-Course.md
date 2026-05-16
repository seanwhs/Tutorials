# ⚡ Thinking in Javascript Course

## From Language Mechanics $\rightarrow$ Runtime Thinking $\rightarrow$ Production Systems

This course is designed to move you through **three layers of mastery**:

1. 🧠 **Language Semantics** (how JS behaves)
2. ⚙️ **Engine Mechanics** (how JS runs)
3. 🚀 **System Design** (how JS scales in real applications)

---

# 🧱 Module 1: Scope — The Invisible Boundary System

Scope defines **where variables exist, who can access them, and how data flows through your program**. Think of scope as a **hierarchical permission system**.

---

## 🌳 Scope Hierarchy Model

JavaScript uses nested scope chains:

* **Global Scope** (top-level environment)
* **Function Scope** (created per function call)
* **Block Scope** (created by `{}`)

### Core Rule

> A child scope can access its parent scope.
> A parent scope cannot access its child scope.

---

### 🧪 Example

```javascript
const globalVar = "I'm global";

function outerFunction() {
    const parentVar = "I'm in outer function";

    if (true) {
        const childVar = "I'm inside block";

        console.log(globalVar);  // ✅ accessible
        console.log(parentVar);  // ✅ accessible
    }

    // console.log(childVar); // ❌ ReferenceError
}

```

---

## 🧩 `var` vs `let` vs `const` (Critical Evolution)

| Keyword | Scope | Re-declare | Re-assign | Risk Level |
| --- | --- | --- | --- | --- |
| `var` | Function | Yes | Yes | 🚨 High |
| `let` | Block | No | Yes | 🟡 Safe |
| `const` | Block | No | No | 🟢 Safest |

---

### ⚠️ Key Insight

> `var` ignores block boundaries — it “escapes” `{}`.

```javascript
for (var i = 0; i < 3; i++) {}
console.log(i); // 3 (leaked into function scope!)

```

---

## 🧭 Lexical Scoping (Static Scope Model)

JavaScript scope is determined at **write-time, not run-time**.

```javascript
const value = "global";

function print() {
    console.log(value);
}

function wrapper() {
    const value = "local";
    print(); // still "global"
}

wrapper();

```

### Mental Model:

> Functions remember where they were **defined**, not where they are **called**.

---

# ⚙️ Module 2: Execution Model — How JavaScript Runs

To understand JS deeply, you must think like the engine.

---

## 🧠 Execution Context

Every function runs inside an **Execution Context** managed in two sequential phases:

### 1. Creation Phase

* Memory is allocated for variables and functions
* Variables are hoisted (initialized as `undefined` or left uninitialized in the TDZ)
* Functions are registered in the scope memory map

### 2. Execution Phase

* Code runs line-by-line
* Values are assigned to variables
* Functions are invoked and pushed to the stack

---

## 📚 Call Stack (Single-Thread Model)

JavaScript is **single-threaded**, meaning only one function executes at a time. It uses a **Last-In, First-Out (LIFO)** stack system:

```javascript
function first() {
    second();
}

function second() {
    console.log("Done");
}

first();

```

### Stack Flow:

1. Global context pushed
2. `first()` pushed
3. `second()` pushed
4. `second()` popped
5. `first()` popped

---

## ⛓ Hoisting + Temporal Dead Zone (TDZ)

### Hoisting Rule:

* Declarations are processed and placed in memory before code execution begins.

---

### `var`

```javascript
console.log(a); // undefined
var a = 5;

```

### `let` / `const`

```javascript
console.log(b); // ❌ ReferenceError
let b = 10;

```

---

### 🔥 TDZ Concept

> The time between an identifier's raw memory allocation and its explicit inline structural initialization.

Variables exist in memory... but are **not usable yet** and will throw hard runtime errors if accessed.

---

# 🧠 Module 3: Closures — Persistent Scope Memory

Closures are not a trick — they are a **natural consequence of lexical scoping**.

---

## 🔐 Definition

> A closure is a function that retains access to its outer scope even after that scope has finished executing and its parent context has been popped from the call stack.

---

## 🧪 Example

```javascript
function createGreeting(greeting) {
    return function(name) {
        console.log(`${greeting}, ${name}!`);
    };
}

const sayHello = createGreeting("Hello");

sayHello("Alice");

```

Even though `createGreeting` has finished executing, the inner function retains an explicit live lookup link to `greeting`.

---

## 🧱 Encapsulation Pattern

Closures enable **private state** templates:

```javascript
function createCounter() {
    let count = 0;

    return {
        increment() {
            count++;
            return count;
        },
        decrement() {
            count--;
            return count;
        }
    };
}

```

### Key Insight:

> JavaScript has no true private variables — closures simulate them.

---

## 🧠 Memory Model Insight

* **Normally:** Function scope memory is automatically garbage collected upon exit.
* **With Closures:** Memory stays alive indefinitely if an external reference to the inner function remains active.

⚠️ Risk:

> Long-lived closures can cause severe memory leaks if they hold references to large arrays, objects, or DOM nodes.

---

# 🧬 Module 4: Prototypes — Object Linking System

JavaScript is not class-based — it is **prototype-based**.

---

## 🔗 Prototype Chain

Every object links to another object via its internal `[[Prototype]]` link:

```javascript
const animal = {
    eat() {
        console.log("Eating...");
    }
};

const dog = Object.create(animal);

dog.bark = function() {
    console.log("Woof!");
};

dog.eat(); // found via prototype chain delegation

```

---

## 🧠 Lookup Rule

When accessing a property or method on an object:

1. Check the object instance itself.
2. If not found $\rightarrow$ traverse up its prototype link.
3. Continue upward until the property is found or the chain terminates at `null`.

---

## 🏗 `new` Keyword Mechanics

When using the `new` operator on a constructor function, the engine performs 4 atomic operations:

1. **Object Allocation:** Step 1.
Allocates a completely blank, new plain JavaScript object literal in memory.


2. **Prototype Linking:** Step 2.
Binds the new object's internal `[[Prototype]]` link to the constructor function's public `.prototype` property.


3. **Context Binding:** Step 3.
Invokes the constructor function, explicitly binding the execution context's `this` keyword to the newly allocated object.


4. **Instance Return:** Step 4.
Returns the newly populated object automatically, unless the constructor function returns an explicit object of its own.


```javascript
function User(name) {
    this.name = name;
}

User.prototype.sayHi = function() {
    console.log(`Hi, I'm ${this.name}`);
};

const bob = new User("Bob");

```

---

## 🧩 ES6 Classes = Syntax Sugar

```javascript
class Animal {
    constructor(name) {
        this.name = name;
    }

    move() {
        console.log(`${this.name} moves`);
    }
}

```

> Under the hood: It compiles down to the exact same prototype linking delegation engine.

---

# 🌐 Module 5: DOM Events — The Propagation System

When you interact with a node on a page, you trigger a deep nested **DOM event cascade**.

---

## 🔄 Event Flow Phases

1. **Capturing Phase:** Event trickles down from the window element $\rightarrow$ target parent.
2. **Target Phase:** Event activates event listeners registered directly on the element itself.
3. **Bubbling Phase:** Event bubbles back up from the target element $\rightarrow$ window element.

---

```javascript
element.addEventListener("click", handler); // Triggers during default Bubbling Phase

element.addEventListener("click", handler, true); // Triggers during Capturing Phase

```

---

## 🧩 Event Delegation Pattern

Instead of attaching 100 individual event listeners to 100 distinct items, attach a single listener to a shared structural parent container:

```javascript
list.addEventListener("click", (event) => {
    if (event.target.tagName === "LI") {
        console.log(event.target.innerText);
    }
});

```

### Why this matters:

* Lower memory consumption footprint
* Better overall hardware execution performance
* Works automatically with dynamically injected future elements

---

## 🎯 target vs currentTarget

| Property | Meaning |
| --- | --- |
| `event.target` | The absolute concrete leaf element that originally triggered the event action. |
| `event.currentTarget` | The structural container node that is currently evaluating the attached event listener code. |

---

# ⚡ Module 6: Asynchrony — The Event Loop System

JavaScript feels multi-threaded, but it operates entirely within a single main execution thread.

---

## 🧠 Architecture Model

### Components:

* **Call Stack:** Executes code blocks synchronously.
* **Web APIs (or Node C++ APIs):** Offloads multi-threaded platform tasks like timers, network requests, or file systems.
* **Microtask Queue:** Processes high-priority promises (`.then()`, `async/await` resumptions, and `queueMicrotask`).
* **Callback Queue (Macrotask Queue):** Holds low-priority macros (`setTimeout`, network event resolution callbacks).
* **Event Loop:** Orchestrates timing loops between components.

---

## 🔁 Event Loop Rule

> If the Call Stack is completely empty $\rightarrow$ flush the Microtask Queue entirely until empty, then pull the next single queued task from the Callback Queue.

---

## 📡 Async/Await (Modern Standard)

```javascript
async function fetchUser() {
    try {
        const res = await fetch("/api/user");
        const data = await res.json();
        return data;
    } catch (err) {
        console.error(err);
    }
}

```

---

# 🚀 Module 7: Performance Engineering

This is where code scales to handle enterprise-level multi-user production environments.

---

## 🧠 Memoization

Cache computing operations inside a runtime hash signature indexed by incoming function argument signatures:

```javascript
function memoize(fn) {
    const cache = {};

    return function(...args) {
        const key = JSON.stringify(args);

        if (cache[key]) return cache[key];

        const result = fn(...args);
        cache[key] = result;

        return result;
    };
}

```

---

## 🧵 Web Workers (Parallel Execution)

Move blocking or resource-heavy computations (image manipulations, big data processing) completely off the main UI execution thread:

```javascript
const worker = new Worker("worker.js");

worker.postMessage([1e7, 2e7]);

worker.onmessage = (e) => {
    console.log(e.data);
};

```

---

## ⚙️ Node.js Internals

### V8 Engine

* Compiles JavaScript source text directly into low-level optimized machine code.

### libuv

* Written in C; manages asynchronous system-level I/O tasks, abstracts underlying thread pools, and drives non-blocking platform loop execution.

---

# 🧠 Final Mental Model Summary

JavaScript applications are structured around 4 fundamental pillars:

1. **Scope System** $\rightarrow$ Where data properties live, route, and hide.
2. **Execution System** $\rightarrow$ How lines of code run and populate step-by-step stack memories.
3. **Object System (Prototype)** $\rightarrow$ How object memory instances inherit and delegate behaviors without classical structures.
4. **Async System (Event Loop)** $\rightarrow$ How concurrency mechanics operate gracefully on a single-threaded architecture.

---

# 🏆 JavaScript Mastery: Production Assessment Suite

This assessment suite avoids syntax trivia and focuses on tracking down state containment bugs, debugging runtime memory traps, and optimizing concurrency queues.

---

## 🧪 Section 1: Practical Code Challenges

### Challenge 1: The Haunted Micro-Framework (Modules 1, 3, & 4)

**Scenario:** A developer built a lightweight state management store using closures and prototypes. However, state properties are leaking across distinct instances, and internal private counters are throwing errors or exposing raw data.

#### The Broken Code:

```javascript
function CreateStore(initialState) {
    this._state = initialState; 
    // Intended to be totally private and unmodifiable from the outside
    let accessCount = 0; 

    this.getAccessCount = function() {
        return accessCount;
    };
}

CreateStore.prototype.get = function(key) {
    // Intent: Increment accessCount on every read, then return data
    // PROBLEM: This throws a ReferenceError or reads the wrong value
    accessCount++; 
    return this._state[key];
};

CreateStore.prototype.set = function(key, val) {
    this._state[key] = val;
};

// Execution test
const storeA = new CreateStore({ role: "admin" });
const storeB = new CreateStore({ role: "guest" });

storeA.set("role", "superuser");
console.log(storeB.get("role")); // Unexpected side effect testing target

```

#### Your Task:

1. Identify why `accessCount++` fails inside the prototype method.
2. Fix the leaking state issue so that modifying `storeA` cannot accidentally mutate data links inside `storeB`.
3. Rewrite `CreateStore` using a secure combination of **closures** and **prototypal delegation** (or modern ES6 classes) so that the raw state object can *only* be read or updated via explicit `.get()` and `.set()` methods.

---

### Challenge 2: The Concurrency Gatekeeper (Module 6: Event Loop)

**Scenario:** Your frontend application communicates with a third-party rate-limited API. If your code fires off more than 3 requests concurrently, the server bans your IP address.

#### Your Task:

Implement a `throttleTasks` execution queue. It accepts an array of asynchronous task functions and a maximum concurrency limit. It must run tasks in parallel, but *Lincoln-bound* to never exceed the threshold limit.

```javascript
/**
 * Executes async tasks with strict concurrency capping.
 * @param {Array<() => Promise<any>>} tasks - Array of functions returning promises
 * @param {number} limit - Maximum concurrent executions allowed
 * @returns {Promise<Array<any>>} Resolves with array of all task results in original order
 */
async function throttleTasks(tasks, limit) {
    // Your implementation here
}

// --- Test Case ---
const delay = (ms, val) => () => new Promise(res => setTimeout(() => res(val), ms));
const tasks = [
    delay(500, "Task 1 finished"),
    delay(100, "Task 2 finished"),
    delay(300, "Task 3 finished"),
    delay(200, "Task 4 finished")
];

// If limit is 2, Task 1 and 2 start immediately. 
// When Task 2 finishes (at 100ms), Task 3 should step into its slot instantly.
throttleTasks(tasks, 2).then(console.log);

```

---

### Challenge 3: Memory Leak Forensic Lab (Modules 2, 3, & 5)

**Scenario:** Users complain that your Single Page Application (SPA) becomes incredibly sluggish and crashes mobile browsers after clicking through tabs for 15 minutes. You suspect a closure/DOM handler memory leak.

#### The Broken Code:

```javascript
class TabComponent {
    constructor(tabElement) {
        this.tabElement = tabElement;
        this.hugeAnalyticsLog = new Array(1000000).fill("⚠️ MASSIVE DATA BLOB ⚠️");
        this.init();
    }

    init() {
        // Appending click handler to a global viewport window
        window.addEventListener("resize", () => {
            this.renderLayout();
        });

        this.tabElement.addEventListener("click", () => {
            console.log(`Tab clicked. Current records logged: ${this.hugeAnalyticsLog.length}`);
        });
    }

    renderLayout() {
        // Complex layout updates
    }

    destroy() {
        // Explicitly called by SPA router when switching tabs
        this.tabElement.remove();
    }
}

```

#### Your Task:

1. Explain exactly why `hugeAnalyticsLog` remains trapped in heap memory even after `destroy()` is called and the tab is removed from the screen layout.
2. Refactor `TabComponent` to cleanly release its memory footprint as soon as `destroy()` runs.

---

## 💬 Section 2: Architectural Interview Questions

### Question 1 (Modules 1 & 2): The Microtask Trap

Look at the following code snippet:

```javascript
console.log("Start");

setTimeout(() => {
    console.log("Timeout 1");
}, 0);

Promise.resolve().then(() => {
    console.log("Promise 1");
    
    // Injecting a nested microtask loop
    Promise.resolve().then(() => {
        console.log("Promise 2");
    });
});

setTimeout(() => {
    console.log("Timeout 2");
}, 0);

console.log("End");

```

#### Interviewer Prompts:

* What is the exact line-by-line output order in the terminal?
* If `Promise 1` repeatedly scheduled another microtask recursively forever, would `Timeout 1` ever execute? Why or why not? Explain this using the Event Loop structural rules.

---

### Question 2 (Module 4): Classical vs. Prototypal Memory Overhead

An engineer is building an online RPG with millions of active monster instances. They argue that using factory functions that copy methods directly onto every new object literal is better than using classical `prototype` assignments because it looks cleaner.

#### Interviewer Prompts:

* From a hardware/V8 engine execution perspective, evaluate the memory footprint implications of copying methods onto object instances versus linking them up a `[[Prototype]]` chain.
* How does V8's optimization engine ("hidden classes" or "shapes") react when you dynamically add or delete properties from these instances at runtime?

---

### Question 3 (Modules 5 & 7): Dom Optimization & Event Mechanics

You are building an infinitely scrolling dashboard with millions of data rows. Each row has an interactive "Delete" button.

#### Interviewer Prompts:

* How would you architect this using **Event Delegation** to minimize event listeners in memory? Where exactly would you attach the listener?
* In this specific workflow, explain the operational difference between checking `event.target` vs `event.currentTarget`.
* If rendering updates cause heavy screen layout stutter, how would you leverage microtask schedules or `requestAnimationFrame` to decouple event evaluation from rendering loops?

---

## 🔑 Answer Key & Evaluation Rubric for Instructors

1. **Evaluate Challenge 1 Fix (Scope/Prototypes):** Verify the student removed the `this._state` structural reference assignment out of common object contexts, and wrapped `accessCount` safely within the closure factory scope or made it a private class field (`#accessCount`).
2. **Verify Challenge 2 Implementation (Async Execution):** Check that the `throttleTasks` function handles immediate execution bounds cleanly. Ensure it uses an internal index pointer loop or a worker pool array layout rather than running `Promise.all()` blindly.
3. **Inspect Challenge 3 Cleanup (Memory Deallocation):** Confirm that `window.removeEventListener("resize", ...)` was added inside the `destroy()` method. The student must pass the *exact same* function reference to `removeEventListener` to unlock heap allocation scopes.

---

## 🛠 Complete Solutions Manual

Optimized for V8 execution efficiency and absolute memory safety.

### 🔑 Challenge 1 Solution: The Safe State Store

```javascript
class CreateStore {
    // Natively declared private fields enforced by the V8 Engine
    #state;
    #accessCount = 0;

    constructor(initialState) {
        // Deep copy the initial state to break references and isolate instances
        this.#state = JSON.parse(JSON.stringify(initialState));
    }

    /**
     * Safely reads a value from the private state block.
     * @param {string} key 
     * @returns {*}
     */
    get(key) {
        this.#accessCount++;
        // Return a copy if returning nested objects to prevent external mutation
        const value = this.#state[key];
        if (value && typeof value === 'object') {
            return JSON.parse(JSON.stringify(value));
        }
        return value;
    }

    /**
     * Updates a value inside the private state block.
     * @param {string} key 
     * @param {*} val 
     */
    set(key, val) {
        // Break references for incoming objects/arrays
        this.#state[key] = val && typeof val === 'object' 
            ? JSON.parse(JSON.stringify(val)) 
            : val;
    }

    /**
     * Public accessor to view access metrics without exposing raw values.
     * @returns {number}
     */
    getAccessCount() {
        return this.#accessCount;
    }
}

// --- Verification Test ---
const storeA = new CreateStore({ role: "admin" });
const storeB = new CreateStore({ role: "guest" });

storeA.set("role", "superuser");

console.log(storeB.get("role"));       // ✅ Outputs: "guest" (Completely isolated!)
console.log(storeB.getAccessCount());  // ✅ Outputs: 1 (Tracked perfectly)
console.log(storeB.role);              // ✅ Outputs: undefined (Encapsulated)

```

---

### 🔑 Challenge 2 Solution: The Concurrency Gatekeeper

```javascript
/**
 * Executes async tasks with strict concurrency capping using a Worker Pool Pattern.
 * @param {Array<() => Promise<any>>} tasks - Array of functions returning promises
 * @param {number} limit - Maximum concurrent executions allowed
 * @returns {Promise<Array<any>>} Resolves with array of all task results in original order
 */
async function throttleTasks(tasks, limit) {
    // Array to store final results matching original task array indexes
    const results = new Array(tasks.length);
    
    // Track our location in the queue
    let nextTaskIndex = 0;

    // Worker definition: consumes tasks one by one from the shared queue
    async function worker() {
        while (nextTaskIndex < tasks.length) {
            // Claim the current index and advance the pointer atomically
            const currentIndex = nextTaskIndex++;
            
            try {
                // Execute the task and save its output to its dedicated slot
                results[currentIndex] = await tasks[currentIndex]();
            } catch (error) {
                results[currentIndex] = error; // Capture rejections gracefully
            }
        }
    }

    // Determine actual concurrency boundaries (handle small task arrays gracefully)
    const poolSize = Math.min(limit, tasks.length);
    const workers = [];

    // Initialize and boot up parallel worker instances
    for (let i = 0; i < poolSize; i++) {
        workers.push(worker());
    }

    // Wait for all parallel worker streams to fully drain the task queue
    await Promise.all(workers);
    return results;
}

// --- Verification Test ---
const delay = (ms, val) => () => new Promise(res => setTimeout(() => res(val), ms));
const tasksList = [
    delay(500, "Task 1 finished"), // Worker 1 takes this (0ms -> 500ms)
    delay(100, "Task 2 finished"), // Worker 2 takes this (0ms -> 100ms)
    delay(300, "Task 3 finished"), // Worker 2 picks this up at 100ms (100ms -> 400ms)
    delay(200, "Task 4 finished")  // Worker 2 picks this up at 400ms (400ms -> 600ms)
];

console.time("Execution Time");
throttleTasks(tasksList, 2).then(outputs => {
    console.log(outputs);
    console.timeEnd("Execution Time"); // Total runtime should be roughly ~600ms
});

```

---

### 🔑 Challenge 3 Solution: Memory Leak Forensic Lab

```javascript
class TabComponent {
    constructor(tabElement) {
        this.tabElement = tabElement;
        this.hugeAnalyticsLog = new Array(1000000).fill("⚠️ MASSIVE DATA BLOB ⚠️");
        
        // Explicitly bind the method context once to save a fixed function reference
        this.boundRenderLayout = this.renderLayout.bind(this);
        this.boundHandleClick = this.handleClick.bind(this);
        
        this.init();
    }

    init() {
        // Register utilizing our saved, unique function reference
        window.addEventListener("resize", this.boundRenderLayout);
        this.tabElement.addEventListener("click", this.boundHandleClick);
    }

    handleClick() {
        console.log(`Tab clicked. Current records logged: ${this.hugeAnalyticsLog.length}`);
    }

    renderLayout() {
        console.log("Layout re-rendered cleanly.");
    }

    /**
     * Cleanly severs all garbage collection anchors when tab is closed.
     */
    destroy() {
        // 1. Remove global window handles using the identical method reference
        window.removeEventListener("resize", this.boundRenderLayout);
        
        // 2. Remove instance-level bindings to clean up DOM connections
        if (this.tabElement) {
            this.tabElement.removeEventListener("click", this.boundHandleClick);
            this.tabElement.remove();
        }

        // 3. Clear massive references explicitly to assist the V8 Garbage Collector
        this.hugeAnalyticsLog = null;
        this.tabElement = null;
        
        console.log("🧹 Tab Component successfully deallocated from memory.");
    }
}

```

---

### 🧠 Solutions Summary & Architectural Best Practices

* **Reference Isolation:** Always clone inbound mutable configurations or objects to safeguard your internal closure systems from secondary runtime mutations.
* **Continuous Worker Pipelines:** Avoid grouping async tasks into staggered blocks using basic array splitting. Use shared index counters to maximize execution output.
* **Symmetrical Memory Cleanups:** Any global handler (`window.addEventListener`) must always have an explicit removal step (`removeEventListener`) referencing an identical, static pointer reference to free up instance scopes.
