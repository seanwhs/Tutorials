## Phase 1: The Foundations

### 1.1 The "Why" — JavaScript is Single-Threaded

JavaScript was born in a browser in 1995 to manipulate a single DOM tree. If two pieces of code could touch that DOM at the exact same instant, you'd get chaos — corrupted layouts, race conditions on every click. So JavaScript's designers gave it **one call stack, one memory heap, and one thread of execution.**

This means: **JavaScript can only do one thing at a time.**

Everything else you've heard about "async JavaScript" — promises, `async/await`, timers, network requests — is a set of clever illusions built *around* that single thread, not a violation of it. The JS engine (V8, SpiderMonkey, JavaScriptCore) never actually runs two lines of your JS code simultaneously. Instead, it hands off slow work to the *environment* (the browser or Node.js/libuv) and gets notified later.

> **Pro-Tip:** "Asynchronous" does not mean "parallel." Async JS is about **not blocking** while waiting, not about doing two computations at the exact same nanosecond. True parallelism in JS requires Web Workers or Node's `worker_threads` — separate threads with separate call stacks.

### 1.2 The Restaurant Kitchen Analogy

Imagine a single chef (the **call stack**) working in a kitchen.

- The chef can only cook **one dish at a time** — that's synchronous execution.
- When an order requires something slow — like waiting for bread to toast, or water to boil — the chef doesn't stand there staring at it. They **hand it off** to an appliance (the toaster, the oven — this is the **Web API / libuv environment**) and move to the next ticket on the counter (the **task queue**).
- When the toaster dings, it doesn't interrupt the chef mid-chop. The ding just places a note on a **pickup counter** (the **queue**). The chef only looks at that counter when they've finished whatever they're currently doing and their hands are empty (the **call stack is empty**).
- The person who decides "chef, your hands are empty, go check the counter" is the **Event Loop** — a tireless restaurant manager who does nothing but ask, over and over: *"Is the chef free? Is there a ticket waiting?"*

This analogy resurfaces throughout Phase 1 — hold onto it.

### 1.3 Call Stack vs. Heap

JavaScript's runtime has two core memory structures:

| Structure | Purpose | Analogy |
|---|---|---|
| **Call Stack** | Tracks *what function is currently executing* — a LIFO (Last In, First Out) stack of "execution contexts" | A stack of dinner plates — you can only take from (or add to) the top |
| **Heap** | An unstructured region where objects, arrays, and closures actually *live* in memory | A giant walk-in pantry — things are stored by reference, and the stack holds "location tags" pointing into it |

**Learning Lab 1.3 — Watching the Stack Grow and Shrink**

```javascript
function multiply(a, b) {
  return a * b;
}

function square(n) {
  return multiply(n, n); // stack frame for `multiply` pushed on top of `square`
}

function printSquare(n) {
  const result = square(n); // stack frame for `square` pushed on top
  console.log(result);
}

printSquare(4);

/*
Call Stack visualization over time:

Step 1:            Step 2:                  Step 3:                    Step 4 (unwind):
+----------------+  +----------------+       +----------------+        +----------------+
|                |  |                |       |  multiply(4,4) |        |                |
|                |  |  square(4)     |       |  square(4)     |        |  printSquare(4)|
| printSquare(4) |  | printSquare(4) |       | printSquare(4) |        |                |
+----------------+  +----------------+       +----------------+        +----------------+
      pushed             pushed                    pushed              multiply returns 16,
                                                                        its frame POPS off,
                                                                        result flows back down
*/
```

Objects and arrays created inside these functions (e.g., `{ a, b }`) live in the **heap**; the stack only ever holds primitive values and *references* (pointers) to heap objects.

> **Pro-Tip:** A "Maximum call stack size exceeded" error is *always* the stack overflowing — usually from unbounded recursion. It has nothing to do with the heap running out of space (that would throw a different error — an out-of-memory / OOM error).

### 1.4 The Event Loop Mechanics

Here is the full picture, piece by piece:

```
   ┌───────────────────────────┐
   │        Call Stack          │  ← Only place code actually executes
   └─────────────┬───────────────┘
                 │  (empty?)
                 ▼
   ┌───────────────────────────┐
   │        Event Loop          │  ← "Is the stack empty? What's next?"
   └───────┬─────────────┬───────┘
           │             │
           ▼             ▼
 ┌───────────────┐ ┌─────────────────┐
 │ Microtask     │ │ Macrotask       │
 │ Queue         │ │ Queue (a.k.a.   │
 │ (Promises,    │ │  "Task Queue")  │
 │ queueMicrotask│ │ (setTimeout,    │
 │ )             │ │  setInterval,   │
 │               │ │  I/O callbacks, │
 │               │ │  UI events)     │
 └───────────────┘ └─────────────────┘
```

The Event Loop's algorithm, simplified:

1. Run everything currently on the **Call Stack** until it's empty (this is your synchronous code, top to bottom).
2. Once the stack is empty, drain the **entire Microtask Queue** — one at a time, running each to completion, even if new microtasks get added mid-drain.
3. Take **exactly one** task off the **Macrotask Queue**, push it onto the stack, and run it to completion.
4. Go back to step 2 (drain microtasks again).
5. Repeat forever. This is why it's called a *loop*.

**Learning Lab 1.4 — Proving the Loop's Order**

```javascript
console.log('1: Synchronous - Start');

setTimeout(() => {
  console.log('2: Macrotask - setTimeout callback');
}, 0);

Promise.resolve().then(() => {
  console.log('3: Microtask - Promise .then');
});

console.log('4: Synchronous - End');

/*
Output (guaranteed, regardless of engine):
1: Synchronous - Start
4: Synchronous - End
3: Microtask - Promise .then
2: Macrotask - setTimeout callback

WHY: Even with a 0ms delay, setTimeout's callback is a MACROTASK.
It must wait for (a) all synchronous code to finish, AND
(b) the entire microtask queue to fully drain, before it gets a turn.
*/
```

### Phase 1 Wrap-Up

At this point you should be able to: explain why JS is single-threaded, trace a call stack by hand, distinguish stack vs. heap, and predict `console.log` ordering across sync code / microtasks / macrotasks — the single most common trick interview question in async JS.

> **Pro-Tip:** If you can correctly predict the output of Learning Lab 1.4 without running it, you've internalized the core mental model this entire masterclass builds on. Everything in Phases 2–4 is refinement on top of this one idea.
