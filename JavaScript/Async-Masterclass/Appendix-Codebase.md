## Appendix: Full Codebase Reference 

This is the complete, consolidated, runnable implementation referenced at the end of Phase 4. Five small files, each with a single responsibility, composed together into one clean orchestrator. Works in Node.js 18+ or any modern browser (uses native `fetch` and `AbortController`).

### File: AppError.js

```javascript
// A small typed error hierarchy so callers can branch on WHAT kind of failure occurred,
// instead of parsing error message strings.

export class AppError extends Error {
  constructor(message, options = {}) {
    super(message);
    this.name = this.constructor.name;
    this.cause = options.cause;
  }
}

export class TimeoutError extends AppError {
  constructor(ms) {
    super(`Operation timed out after ${ms}ms`);
    this.ms = ms;
  }
}

export class AbortedError extends AppError {
  constructor() {
    super('Operation was aborted by the caller');
  }
}

export class HttpError extends AppError {
  constructor(status, statusText, url) {
    super(`HTTP ${status} (${statusText}) for ${url}`);
    this.status = status;
    this.url = url;
  }
}

export class RetriesExhaustedError extends AppError {
  constructor(attempts, lastError) {
    super(`All ${attempts} attempts failed. Last error: ${lastError?.message}`);
    this.attempts = attempts;
    this.lastError = lastError;
  }
}
```

### File: httpClient.js

```javascript
import { HttpError } from './AppError.js';

// Thin wrapper around fetch: normalizes non-2xx responses into thrown errors,
// and always forwards an AbortSignal so it's cancellable by design.
export async function httpGet(url, { signal, headers = {} } = {}) {
  const response = await fetch(url, { method: 'GET', signal, headers });
  if (!response.ok) {
    throw new HttpError(response.status, response.statusText, url);
  }
  return response.json();
}
```

### File: withTimeout.js

```javascript
import { TimeoutError } from './AppError.js';

// Races an operation against a timeout. Crucially, it also ABORTS the underlying
// operation on timeout (via the passed AbortController) so we don't leak an
// in-flight request just because we stopped waiting for it.
export function withTimeout(taskFn, ms, controller) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      controller.abort();
      reject(new TimeoutError(ms));
    }, ms);

    taskFn(controller.signal)
      .then((result) => {
        clearTimeout(timer);
        resolve(result);
      })
      .catch((err) => {
        clearTimeout(timer);
        reject(err);
      });
  });
}
```

### File: withRetry.js

```javascript
import { RetriesExhaustedError, AbortedError } from './AppError.js';

// Exponential backoff with jitter, honoring an external "isCancelled" check
// so a manual cancel() stops retries immediately instead of sleeping through them.
function backoffDelay(attempt, baseMs = 300, maxMs = 5000) {
  const exp = Math.min(maxMs, baseMs * 2 ** (attempt - 1));
  const jitter = Math.random() * exp * 0.3; // +/- up to 30% jitter to avoid thundering herd
  return Math.round(exp + jitter);
}

function sleep(ms, isCancelled) {
  return new Promise((resolve, reject) => {
    const id = setTimeout(resolve, ms);
    const checkInterval = setInterval(() => {
      if (isCancelled()) {
        clearTimeout(id);
        clearInterval(checkInterval);
        reject(new AbortedError());
      }
    }, 20);
    // Ensure the interval doesn't outlive the sleep
    setTimeout(() => clearInterval(checkInterval), ms + 25);
  });
}

export async function withRetry(attemptFn, { retries = 3, isCancelled = () => false } = {}) {
  let lastError;
  for (let attempt = 1; attempt <= retries; attempt++) {
    if (isCancelled()) throw new AbortedError();
    try {
      return await attemptFn(attempt);
    } catch (err) {
      lastError = err;
      if (isCancelled()) throw new AbortedError();
      if (attempt < retries) {
        const delay = backoffDelay(attempt);
        console.warn(`Attempt ${attempt} failed (${err.name}: ${err.message}). Retrying in ${delay}ms...`);
        await sleep(delay, isCancelled);
      }
    }
  }
  throw new RetriesExhaustedError(retries, lastError);
}
```

### File: requestOrchestrator.js

```javascript
import { withTimeout } from './withTimeout.js';
import { withRetry } from './withRetry.js';
import { AbortedError } from './AppError.js';

// The composition root: wires together timeout + retry + cancellation into one
// small public API — `run` and `cancel` — so callers never touch the internals.
export function createRequestOrchestrator({ retries = 3, timeoutMs = 2000 } = {}) {
  let cancelled = false;
  let activeController = null;

  function cancel() {
    cancelled = true;
    activeController?.abort();
  }

  async function run(fetcher) {
    cancelled = false; // reset for reuse across multiple run() calls
    try {
      return await withRetry(
        async () => {
          if (cancelled) throw new AbortedError();
          activeController = new AbortController();
          return withTimeout(
            (signal) => fetcher(signal),
            timeoutMs,
            activeController
          );
        },
        { retries, isCancelled: () => cancelled }
      );
    } finally {
      activeController = null;
    }
  }

  return { run, cancel };
}
```

### File: demo.js (Usage Walkthrough)

```javascript
import { createRequestOrchestrator } from './requestOrchestrator.js';
import { httpGet } from './httpClient.js';

// --- Scenario 1: Happy path, succeeds within timeout on first try ---
async function scenarioHappyPath() {
  const orchestrator = createRequestOrchestrator({ retries: 3, timeoutMs: 3000 });
  const data = await orchestrator.run((signal) =>
    httpGet('https://jsonplaceholder.typicode.com/todos/1', { signal })
  );
  console.log('Scenario 1 (happy path) result:', data);
}

// --- Scenario 2: A flaky fetcher that fails twice then succeeds — retry logic kicks in ---
function makeFlakyFetcher() {
  let attempts = 0;
  return async (signal) => {
    attempts++;
    if (attempts < 3) {
      throw new Error(`Simulated transient failure #${attempts}`);
    }
    return { ok: true, attempts };
  };
}

async function scenarioRetrySucceeds() {
  const orchestrator = createRequestOrchestrator({ retries: 5, timeoutMs: 1000 });
  const flaky = makeFlakyFetcher();
  const result = await orchestrator.run(flaky);
  console.log('Scenario 2 (retry then succeed) result:', result);
}

// --- Scenario 3: Manual cancellation mid-flight ---
async function scenarioManualCancel() {
  const orchestrator = createRequestOrchestrator({ retries: 5, timeoutMs: 5000 });
  const neverEndingFetcher = (signal) =>
    new Promise((resolve, reject) => {
      signal.addEventListener('abort', () => reject(new Error('aborted by signal')));
      // Deliberately never resolves on its own to force cancellation to matter.
    });

  const runPromise = orchestrator.run(neverEndingFetcher);
  setTimeout(() => {
    console.log('Cancelling scenario 3 manually after 500ms...');
    orchestrator.cancel();
  }, 500);

  try {
    await runPromise;
  } catch (err) {
    console.log('Scenario 3 (manual cancel) correctly rejected with:', err.name, err.message);
  }
}

// --- Scenario 4: Every retry exhausted — permanent failure ---
async function scenarioAllRetriesFail() {
  const orchestrator = createRequestOrchestrator({ retries: 2, timeoutMs: 500 });
  const alwaysFails = async () => { throw new Error('permanent upstream failure'); };
  try {
    await orchestrator.run(alwaysFails);
  } catch (err) {
    console.log('Scenario 4 (exhausted retries) correctly rejected with:', err.name, err.message);
  }
}

(async () => {
  await scenarioHappyPath().catch((e) => console.error('Scenario 1 failed:', e.message));
  await scenarioRetrySucceeds();
  await scenarioManualCancel();
  await scenarioAllRetriesFail();
})();
```

### Design Notes (Why It's Built This Way)

- **Single Responsibility**: `httpClient` only knows HTTP. `withTimeout` only knows timing. `withRetry` only knows backoff/retry logic. `requestOrchestrator` only knows composition. None of them import each other's concerns beyond what's needed.
- **Cancellation is threaded through everywhere**: a single `cancel()` call flips a flag AND aborts the live controller, which is checked before every attempt, during sleep, and inside the active fetch — so cancellation is near-instant regardless of which phase (backoff sleep vs in-flight request) it happens during.
- **Errors are typed, not stringly-matched**: callers can `if (err instanceof TimeoutError)` etc., rather than fragile `if (err.message.includes('timeout'))` checks.
- **Reusable across call sites**: the same orchestrator factory works for any `fetcher(signal) => Promise`, not just HTTP — e.g., a database call, a websocket round-trip, or a worker message.

> **Pro-Tip:** This exact shape (timeout → retry → cancel, composed via small functions) is close to what production HTTP client libraries (e.g., `ky`, `got`, `axios-retry`) implement internally — you've essentially built a mini version of one from first principles.
