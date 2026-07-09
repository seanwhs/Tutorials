## Phase 3: Advanced Execution

### 3.1 Microtasks vs Macrotasks — The "Why"

Not all async callbacks are treated equally. JS engines split them into two priority queues:

- **Microtasks**: Promise `.then/.catch/.finally` callbacks, `queueMicrotask()`, and in Node, `process.nextTick()` (which is actually even higher priority than the Promise microtask queue).
- **Macrotasks**: `setTimeout`, `setInterval`, `setImmediate` (Node), I/O callbacks, UI events.

The rule: **the entire microtask queue is fully drained (including any new microtasks added during draining) before the event loop is allowed to process even one macrotask.**

**Learning Lab 3.1 — process.nextTick vs Promise vs setTimeout (Node.js)**

```javascript
console.log('start');

setTimeout(() => console.log('setTimeout (macrotask)'), 0);

setImmediate(() => console.log('setImmediate (check phase macrotask)'));

Promise.resolve().then(() => console.log('Promise.then (microtask)'));

process.nextTick(() => console.log('process.nextTick (highest priority microtask)'));

console.log('end');

/*
Output:
start
end
process.nextTick (highest priority microtask)
Promise.then (microtask)
setTimeout (macrotask)          <- order vs setImmediate can vary outside the main module
setImmediate (check phase macrotask)

WHY nextTick beats Promise: Node reserves a separate, even-higher-priority
queue for process.nextTick, drained completely before the Promise microtask
queue on every single transition point (after each callback, not just each phase).
*/
```

> **Pro-Tip:** Overusing `process.nextTick()` recursively can literally starve the event loop — since it's drained *before* I/O, an infinite chain of `nextTick` calls will block timers, network callbacks, and everything else forever. This is called "I/O starvation."

**Learning Lab 3.1b — A Starvation Trap (illustration only — do not run unbounded)**

```javascript
// DANGER: this never lets the event loop reach the 'poll' phase for I/O
function starve() {
  process.nextTick(starve); // recursively re-queues itself
}
// starve(); // uncommenting this would block all I/O indefinitely
```

### 3.2 Concurrency Control — The Promise Combinators

Once you have multiple independent promises, you rarely want to `await` them one by one. JS gives you four combinators, each with a distinct failure semantic:

| Combinator | Resolves when... | Rejects when... | Use case |
|---|---|---|---|
| `Promise.all` | ALL promises fulfill | ANY ONE rejects (fails fast) | "I need every result, or none of it matters" |
| `Promise.allSettled` | ALL promises settle (fulfilled or rejected) | Never rejects | "Show me everything, even partial failures" |
| `Promise.race` | The FIRST promise to settle (win OR lose) | If that first settler is a rejection | Timeouts, "whichever responds first" |
| `Promise.any` | The FIRST promise to fulfill | Only if ALL reject (AggregateError) | "Give me any success, ignore individual failures" |

**Learning Lab 3.2 — All Four Combinators Side by Side**

```javascript
const ok = (ms, val) => new Promise((res) => setTimeout(() => res(val), ms));
const fail = (ms, reason) => new Promise((_, rej) => setTimeout(() => rej(new Error(reason)), ms));

// Promise.all — fails fast on first rejection
async function demoAll() {
  try {
    const results = await Promise.all([ok(100, 'A'), ok(200, 'B'), fail(50, 'boom')]);
    console.log(results);
  } catch (err) {
    console.error('all() rejected fast:', err.message); // "boom" - fires ~50ms in
  }
}

// Promise.allSettled — always resolves, gives you a status report
async function demoAllSettled() {
  const results = await Promise.allSettled([ok(100, 'A'), fail(50, 'boom')]);
  console.log(results);
  // [ { status: 'fulfilled', value: 'A' }, { status: 'rejected', reason: Error('boom') } ]
}

// Promise.race — first to SETTLE wins, win or lose
async function demoRace() {
  try {
    const winner = await Promise.race([ok(300, 'slow-success'), fail(50, 'fast-failure')]);
    console.log(winner);
  } catch (err) {
    console.error('race() settled first with a rejection:', err.message); // fires first
  }
}

// Promise.any — first to FULFILL wins; ignores rejections unless ALL reject
async function demoAny() {
  try {
    const winner = await Promise.any([fail(50, 'fast-failure'), ok(200, 'slow-success')]);
    console.log(winner); // "slow-success" - the only fulfillment, even though slower
  } catch (aggErr) {
    console.error('any() only rejects if ALL fail:', aggErr.errors);
  }
}

demoAll(); demoAllSettled(); demoRace(); demoAny();
```

> **Pro-Tip:** A classic real-world use of `Promise.race` is implementing a timeout for a fetch call that has no native timeout option — race the fetch against a promise that rejects after N ms (we build exactly this in Phase 4's Final Boss).

### 3.3 Async Iterators & Generators

A regular iterator's `.next()` returns `{ value, done }` synchronously. An **async iterator**'s `.next()` returns a *Promise* of `{ value, done }` — perfect for streaming data (paginated APIs, file streams, WebSocket messages) where each "next" chunk requires waiting.

**Learning Lab 3.3 — An Async Generator Simulating Paginated API Fetching**

```javascript
async function* fetchAllPages(totalPages) {
  for (let page = 1; page <= totalPages; page++) {
    // Simulate a network call per page
    await new Promise((res) => setTimeout(res, 200));
    yield { page, items: [`item-${page}-a`, `item-${page}-b`] };
  }
}

async function consumePages() {
  for await (const chunk of fetchAllPages(3)) {
    console.log('Received:', chunk);
    // Each iteration only runs once the previous await/yield resolves —
    // memory-efficient streaming instead of loading everything up front.
  }
  console.log('All pages consumed');
}

consumePages();
```

> **Pro-Tip:** `for await...of` also works directly on an array of plain Promises (not just async generators) — it will await each one in sequence, unwrapping the values as it goes.

### 3.4 AbortController — Cancelling Async Work

Promises themselves are NOT cancellable once started — that's a deliberate design decision. `AbortController` is the standard, cross-platform escape hatch: you create a controller, pass its `.signal` into a cancellable operation (like `fetch`), and call `.abort()` to signal cancellation.

**Learning Lab 3.4 — Aborting a Fetch and a Custom Async Function**

```javascript
// (A) Aborting a native fetch
async function fetchWithAbort(url, timeoutMs) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timeoutId);
    return await response.json();
  } catch (err) {
    if (err.name === 'AbortError') {
      throw new Error(`Request to ${url} timed out after ${timeoutMs}ms`);
    }
    throw err;
  }
}

// (B) Making YOUR OWN async function abortable (signal is just a convention you honor)
function delayAbortable(ms, signal) {
  return new Promise((resolve, reject) => {
    if (signal?.aborted) return reject(new DOMException('Aborted', 'AbortError'));
    const timer = setTimeout(() => resolve('done'), ms);
    signal?.addEventListener('abort', () => {
      clearTimeout(timer); // critical: release the underlying resource
      reject(new DOMException('Aborted', 'AbortError'));
    });
  });
}

async function demoCustomAbort() {
  const controller = new AbortController();
  setTimeout(() => controller.abort(), 100); // change your mind after 100ms
  try {
    const result = await delayAbortable(500, controller.signal);
    console.log(result);
  } catch (err) {
    console.log('Cancelled as expected:', err.name); // "AbortError"
  }
}

demoCustomAbort();
```

> **Pro-Tip:** `AbortController` instances are single-use — once `.abort()` is called, that controller is spent. For a new cancellable operation, always construct a fresh controller.

### Phase 3 Exercise

Write a function `fetchWithRetryTimeout(fetcher, { retries, timeoutMs })` that:
1. Attempts `fetcher()` (a function returning a Promise).
2. Races it against a timeout of `timeoutMs`.
3. If it fails (rejects OR times out), retries up to `retries` times.
4. Succeeds as soon as ANY attempt succeeds.

### Phase 3 Solution

```javascript
function withTimeout(promise, ms) {
  const timeout = new Promise((_, reject) =>
    setTimeout(() => reject(new Error(`Timed out after ${ms}ms`)), ms)
  );
  return Promise.race([promise, timeout]);
}

async function fetchWithRetryTimeout(fetcher, { retries = 3, timeoutMs = 1000 } = {}) {
  let lastError;
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      const result = await withTimeout(fetcher(), timeoutMs);
      console.log(`Succeeded on attempt ${attempt}`);
      return result;
    } catch (err) {
      lastError = err;
      console.warn(`Attempt ${attempt} failed: ${err.message}`);
    }
  }
  throw new Error(`All ${retries} attempts failed. Last error: ${lastError.message}`);
}

// Usage demo with a flaky fetcher that fails twice, then succeeds:
let callCount = 0;
function flakyFetcher() {
  callCount++;
  return new Promise((resolve, reject) => {
    const delay = callCount < 3 ? 1500 : 100; // first 2 attempts are "slow" (will time out)
    setTimeout(() => resolve(`data-from-attempt-${callCount}`), delay);
  });
}

fetchWithRetryTimeout(flakyFetcher, { retries: 3, timeoutMs: 500 })
  .then((data) => console.log('Final result:', data))
  .catch((err) => console.error('Gave up:', err.message));
```

This exercise is intentionally a rehearsal for Phase 4's "Final Boss" — you've just hand-built the core of a retry/timeout orchestration layer.
