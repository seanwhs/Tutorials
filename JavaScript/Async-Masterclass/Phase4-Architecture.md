## Phase 4: Practical Architecture

### 4.1 Async Anti-Patterns (and Their Fixes)

**Anti-pattern 1: The "Await in a Loop" trap for independent work**

```javascript
// BAD: each iteration waits for the previous one to fully finish - O(n) sequential time
async function loadAllBad(ids) {
  const results = [];
  for (const id of ids) {
    results.push(await fetchThing(id)); // no dependency between iterations!
  }
  return results;
}

// GOOD: fire all requests concurrently, then await together
async function loadAllGood(ids) {
  return Promise.all(ids.map((id) => fetchThing(id)));
}
```

**Anti-pattern 2: The Unhandled Promise Rejection**

```javascript
// BAD: fire-and-forget async call with no .catch - crashes Node in strict mode
async function riskyOperation() { throw new Error('kaboom'); }
riskyOperation(); // UnhandledPromiseRejectionWarning, or process exit in modern Node

// GOOD: always attach a rejection handler for fire-and-forget calls
riskyOperation().catch((err) => console.error('Handled:', err.message));
```

**Anti-pattern 3: Mixing callbacks and promises inconsistently ("callback-promise hybrid")**

```javascript
// BAD: half-async-half-callback API is confusing and easy to misuse
function ambiguousFetch(id, cb) {
  return fetch(`/api/${id}`).then((r) => r.json()).then((data) => cb(null, data)).catch(cb);
}

// GOOD: pick ONE paradigm. Promisify at the boundary and stay async/await internally.
async function cleanFetch(id) {
  const r = await fetch(`/api/${id}`);
  if (!r.ok) throw new Error(`HTTP ${r.status}`);
  return r.json();
}
```

**Anti-pattern 4: Swallowing errors silently**

```javascript
// BAD
try { await doThing(); } catch (e) { /* nothing - silent failure */ }

// GOOD: at minimum, log with context; better, decide to rethrow, fallback, or report
try {
  await doThing();
} catch (err) {
  console.error('doThing failed:', { err, context: 'user checkout flow' });
  throw err; // or return a safe fallback value, deliberately
}
```

> **Pro-Tip:** A silent `catch {}` block is one of the most dangerous patterns in production code — it turns real incidents into invisible ones. If you truly want to ignore an error, comment *why*, explicitly.

### 4.2 Debugging Async Code in Chrome DevTools

Key techniques:

1. **Async stack traces**: Modern DevTools (Sources panel) shows the *logical* async call chain (e.g., `loadFeed` → `await getPosts` → `fetch`), not just the raw event-loop callback stack. Enable the "Async" checkbox in the Call Stack pane if not already on.
2. **Breakpoints inside `.then()`/`async` functions**: Set a breakpoint directly inside the callback; DevTools pauses execution there just like sync code, and you can inspect the Scope pane for closed-over variables.
3. **`debugger;` statement**: Drop this directly before an `await` to pause exactly at that point when DevTools is open.
4. **The "Async" toggle in the Call Stack panel**: Without it, a paused promise callback looks like it has no meaningful caller (just "Promise.then (async)"); with it, DevTools stitches together the full logical chain across ticks.
5. **Network panel + Initiator column**: For `fetch`/XHR, click any request's "Initiator" to see the exact line of code (and async chain) that triggered it.
6. **Performance panel**: Record a trace to visually see microtask/macrotask boundaries as colored blocks on the main thread timeline — genuinely see the event loop in action.

**Learning Lab 4.2 — Instrumenting Code for Easier Debugging**

```javascript
async function loadDashboard(userId) {
  console.time('loadDashboard'); // start a named timer visible in DevTools console
  try {
    debugger; // DevTools will pause here if open, with full async stack available
    const user = await getUser(userId);
    console.log('%cUser loaded', 'color: green; font-weight: bold', user);
    const stats = await getStats(user.id);
    console.log('%cStats loaded', 'color: green; font-weight: bold', stats);
    return { user, stats };
  } catch (err) {
    console.error('%cDashboard load failed', 'color: red; font-weight: bold', err);
    throw err;
  } finally {
    console.timeEnd('loadDashboard'); // logs elapsed ms automatically
  }
}
```

> **Pro-Tip:** `console.table()` on an array of objects (e.g., results from `Promise.allSettled`) renders a readable grid in DevTools — far easier to scan than nested `console.log` objects during async debugging sessions.

### 4.3 State Management for Async Data (React + the D-H-A Pattern)

Real UIs need to represent async operations as **state**, not just side effects. The most common beginner mistake is representing async status with a single boolean (`isLoading`), which cannot correctly express simultaneous/overlapping states (e.g., "loading AND has stale data AND previously errored").

**The D-H-A Pattern** (Data / Has-error / Awaiting — a discriminated-union approach) models each async resource as one of a small closed set of states, instead of independent booleans that can contradict each other:

```javascript
// Instead of this (booleans can contradict: isLoading=true AND error=set AND data=set, all at once):
// { isLoading: false, error: null, data: null }

// ...model it as a discriminated union - only ONE shape is valid at a time:
// { status: 'idle' }
// { status: 'loading' }
// { status: 'success', data }
// { status: 'error', error }
```

**Learning Lab 4.3 — A `useAsync` React Hook Built on the D-H-A Pattern**

```javascript
import { useCallback, useEffect, useRef, useState } from 'react';

function useAsync(asyncFn, deps = []) {
  const [state, setState] = useState({ status: 'idle' });
  const controllerRef = useRef(null);

  const execute = useCallback(async (...args) => {
    // Cancel any in-flight previous request before starting a new one
    controllerRef.current?.abort();
    const controller = new AbortController();
    controllerRef.current = controller;

    setState({ status: 'loading' });
    try {
      const data = await asyncFn(...args, controller.signal);
      if (!controller.signal.aborted) {
        setState({ status: 'success', data });
      }
    } catch (error) {
      if (error.name !== 'AbortError') {
        setState({ status: 'error', error });
      }
    }
  }, deps); // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    return () => controllerRef.current?.abort(); // cleanup on unmount
  }, []);

  return { ...state, execute };
}

// Usage in a component:
function UserProfile({ userId }) {
  const { status, data, error, execute } = useAsync(
    (signal) => fetch(`/api/users/${userId}`, { signal }).then((r) => r.json()),
    [userId]
  );

  useEffect(() => { execute(); }, [execute]);

  if (status === 'idle' || status === 'loading') return 'Loading...';
  if (status === 'error') return `Error: ${error.message}`;
  return `Hello, ${data.name}`;
}
```

> **Pro-Tip:** Notice `useAsync` aborts the *previous* in-flight request whenever `execute` is called again (e.g., `userId` changes fast). Without this, a slow earlier response arriving AFTER a faster later one can overwrite fresh state with stale data — a classic React race-condition bug.

### 4.4 The "Final Boss" — API Request / Retry / Abort Orchestration Layer

**Goal:** design a single, reusable, clean-architecture module that wraps any fetch-like call with configurable timeout, exponential-backoff retries, external cancellation via `AbortController`, and structured error reporting — without callers needing to know any of that plumbing.

**Architecture (clean separation of concerns):**

- `httpClient.js` — thin wrapper around fetch, throws on non-2xx
- `withTimeout.js` — races a promise against a timeout signal
- `withRetry.js` — retry wrapper with exponential backoff + jitter
- `requestOrchestrator.js` — composes the above + exposes a `cancel()` handle
- `AppError.js` — a typed error hierarchy so callers can branch on error kind

This is the canonical production pattern: small single-responsibility functions composed together, rather than one giant tangled function.

*(The full, runnable, consolidated codebase of all five files plus a usage demo lives in the Appendix.)*

### Phase 4 Exercise

Using the orchestrator design above, write a `createRequestOrchestrator()` factory that returns `{ run, cancel }`, where `run(fetcher, opts)` retries up to `opts.retries` times with exponential backoff, each attempt bounded by `opts.timeoutMs`, and `cancel()` immediately aborts any in-flight attempt and stops further retries.

### Phase 4 Solution

See the **Appendix** for the complete, working `createRequestOrchestrator` implementation along with every supporting module and a full usage walkthrough, including console output commentary explaining exactly which phase (timeout vs retry vs cancel) is firing at each step.
