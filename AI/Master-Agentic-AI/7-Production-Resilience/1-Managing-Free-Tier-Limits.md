# Phase 7: Production Resilience, Quotas & Gateways

## Phase 7, Part 1: Managing Free-Tier Limits — Rate-Limit-Aware Request Handling

### The Target

We're building a proper **exponential backoff retry mechanism** at `lib/agent/resilience/withRetry.js` that specifically detects rate-limit responses (`HTTP 429`) from our providers, reads any `retry-after` guidance they provide, and waits an intelligently increasing amount of time between retries — rather than hammering an already-overloaded or quota-exhausted provider with immediate repeated requests. We'll wrap our core Groq call with this mechanism and prove its behavior using a deliberately rate-limit-triggering test.

### The Concept

Imagine calling a busy restaurant to make a reservation, and getting a busy signal. The wrong response is to immediately hit redial as fast as your finger allows, dozens of times a second — that's not just unhelpful, it can actually make the restaurant's phone system *more* congested, and many systems will explicitly penalize this behavior (e.g., temporarily blocking your number). The sensible response is to wait a bit, try again, and if it's still busy, wait *longer* before the next attempt, progressively backing off — giving the restaurant's phone line breathing room to actually clear before you try again. This is **exponential backoff**: each successive retry waits roughly twice as long as the one before it (1 second, then 2, then 4, then 8...), rather than retrying at a fixed interval or not waiting at all.

This matters enormously for AI agent systems built on **free-tier API keys**, exactly as this course's blueprint specifies. Free tiers (Groq, Google AI Studio, DeepSeek) enforce genuinely tight **rate limits** — a maximum number of requests per minute, or tokens per minute — specifically because they're offered for free, and providers need to prevent abuse of that generosity. A well-engineered application built on top of these tiers must treat hitting a rate limit not as an exceptional crash-worthy event, but as an entirely normal, expected condition to gracefully handle — your ReAct loop, remember, can make several sequential calls per single user request, meaning rate limits are *more* likely to be hit in an agentic system than in a simple one-shot chatbot, making this resilience layer especially important for exactly the kind of system this course has been building.

We also add a small but important refinement beyond naive fixed-doubling backoff: **jitter** — a small amount of randomness added to each wait time. Without jitter, if your system happens to send several requests that all get rate-limited at the same moment (for example, several concurrent users, or our Phase 6 fan-out calling three specialists simultaneously), they would all back off using the *exact same* schedule and all retry at the *exact same* moment again, potentially re-triggering the same rate limit collision repeatedly in lockstep. Adding a small random jitter to each wait spreads those retries out over a slightly different timing window for each request, meaningfully reducing the odds of repeated collision.

### The Implementation

#### Step 1 — The exponential backoff retry wrapper

**File: `lib/agent/resilience/withRetry.js`**
```js
/**
 * Wraps any async function with exponential backoff retry logic,
 * specifically tuned to recognize rate-limit errors (HTTP 429) and honor
 * a provider's own suggested `retry-after` guidance when present, falling
 * back to a calculated exponential delay (with jitter) otherwise.
 */
export async function withRetry(asyncFn, options = {}) {
  const {
    maxRetries = 4,
    baseDelayMs = 1000,
    maxDelayMs = 16000,
    isRetryable = defaultIsRetryable,
  } = options;

  let lastError;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await asyncFn(attempt);
    } catch (error) {
      lastError = error;

      // If this error isn't something we consider worth retrying (e.g. a
      // genuine 400 bad request, which will fail identically no matter how
      // many times we retry it), fail immediately rather than wasting time.
      if (!isRetryable(error)) {
        throw error;
      }

      // If we've exhausted our retry budget, stop and let the final error
      // propagate — we do NOT retry forever, exactly matching this course's
      // consistent "every loop must have a deterministic end" principle.
      if (attempt === maxRetries) {
        break;
      }

      const delayMs = computeDelay(error, attempt, baseDelayMs, maxDelayMs);
      console.warn(
        `[withRetry] Attempt ${attempt + 1}/${maxRetries + 1} failed (${error.message}). Retrying in ${delayMs}ms...`
      );
      await sleep(delayMs);
    }
  }

  // All retries exhausted — throw the LAST real error, not a generic
  // wrapper message, so the caller can still see exactly what actually
  // went wrong on the final attempt.
  throw lastError;
}

/**
 * Determines whether an error is worth retrying at all. Rate limits (429)
 * and server-side/network errors (5xx, timeouts) are generally transient
 * and worth retrying. Client errors (400, 401, 403, 404) generally are NOT
 * — retrying an invalid request or bad auth will just fail identically
 * every time, wasting time and provider quota for no benefit.
 */
function defaultIsRetryable(error) {
  const status = error.status || error.statusCode;
  if (status === 429) return true; // rate limit — classic transient, retryable condition
  if (status >= 500 && status < 600) return true; // provider-side server error
  if (error.code === 'PROVIDER_TIMEOUT') return true; // our own timeout wrapper's error code from Phase 1
  if (error.code === 'ECONNRESET' || error.code === 'ETIMEDOUT') return true; // network-level transient failures
  return false; // anything else (bad request, invalid auth, etc.) — not retryable
}

/**
 * Computes the delay before the next retry attempt. Prefers a provider's
 * own explicit `retry-after` header/field if present (the provider knows
 * its own rate-limit window better than we ever could guess), and falls
 * back to a jittered exponential calculation otherwise.
 */
function computeDelay(error, attempt, baseDelayMs, maxDelayMs) {
  const providerSuggestedMs = extractRetryAfterMs(error);
  if (providerSuggestedMs !== null) {
    return providerSuggestedMs;
  }

  // Exponential growth: baseDelayMs * 2^attempt, capped at maxDelayMs.
  const exponentialDelay = Math.min(baseDelayMs * 2 ** attempt, maxDelayMs);

  // Jitter: add a random amount between 0 and 30% of the calculated delay,
  // to avoid multiple concurrent retries landing on the exact same schedule.
  const jitter = Math.random() * exponentialDelay * 0.3;

  return Math.round(exponentialDelay + jitter);
}

/**
 * Attempts to read a provider-supplied retry hint from common error shapes.
 * Different SDKs surface this differently — we check a few common
 * conventions defensively, since we can't guarantee which shape any given
 * provider's SDK will throw.
 */
function extractRetryAfterMs(error) {
  const headerValue =
    error?.headers?.get?.('retry-after') ??
    error?.response?.headers?.get?.('retry-after') ??
    null;

  if (headerValue) {
    const seconds = Number(headerValue);
    if (!Number.isNaN(seconds)) {
      return seconds * 1000;
    }
  }
  return null;
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
```

#### Step 2 — Wrap the core Groq call with retry logic

**File: `lib/agent/timeoutCompletion.js`** *(full updated file)*
```js
import { withRetry } from './resilience/withRetry.js';

export async function completionWithTimeout(groqClient, requestOptions, timeoutMs = 15000) {
  // The retry wrapper now surrounds the ENTIRE timeout-protected call —
  // meaning a rate-limited or transient-failure request gets several
  // intelligently-spaced attempts, and EACH individual attempt still gets
  // its own full timeout protection underneath, from Phase 1, Part 3.
  return withRetry(async () => {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => {
      controller.abort(new Error(`Provider call exceeded ${timeoutMs}ms timeout`));
    }, timeoutMs);

    try {
      const completion = await groqClient.chat.completions.create(requestOptions, {
        signal: controller.signal,
      });
      return completion;
    } catch (error) {
      if (controller.signal.aborted) {
        const timeoutError = new Error(`Provider call timed out after ${timeoutMs}ms`);
        timeoutError.code = 'PROVIDER_TIMEOUT';
        throw timeoutError;
      }
      throw error;
    } finally {
      clearTimeout(timeoutId);
    }
  }, {
    maxRetries: 4,
    baseDelayMs: 1000,
    maxDelayMs: 16000,
  });
}
```

> **Why does retry wrap timeout, rather than timeout wrapping retry?** This ordering matters. We want **each individual attempt** to have its own fresh timeout window — if attempt 1 times out at 15 seconds, attempt 2 (after backing off) should get its own full 15-second allowance, not a shrinking remainder of some single outer timeout budget. By placing `withRetry` on the *outside* and the `AbortController`/timeout logic on the *inside* (built fresh on every single invocation of the wrapped function, since it's defined as a new closure each time `withRetry` calls `asyncFn(attempt)`), each retry attempt gets a completely clean, full-length timeout window of its own — exactly the behavior we want: "give this specific attempt a fair, full chance to succeed, and only after it genuinely fails, wait and try again."

### Step 3 — A diagnostic endpoint to directly observe retry behavior

Since genuinely triggering a real `429` from Groq's free tier on demand is unreliable to test against directly (it depends on your actual current usage), we build a small test harness that simulates a function which fails a controllable number of times before succeeding — letting us observe the retry mechanism's exact behavior deterministically.

**File: `app/api/agent/retry-test/route.js`**
```js
import { NextResponse } from 'next/server';
import { withRetry } from '@/lib/agent/resilience/withRetry.js';

export async function GET(request) {
  const { searchParams } = new URL(request.url);
  const failCount = Number(searchParams.get('failCount') ?? '2'); // how many times to fail before succeeding
  const statusCode = Number(searchParams.get('statusCode') ?? '429'); // simulated error status

  let attemptsMade = 0;
  const attemptTimestamps = [];

  const simulatedCall = async () => {
    attemptsMade += 1;
    attemptTimestamps.push(Date.now());

    if (attemptsMade <= failCount) {
      const error = new Error(`Simulated failure (attempt ${attemptsMade})`);
      error.status = statusCode;
      throw error;
    }
    return { message: `Succeeded on attempt ${attemptsMade}` };
  };

  const startedAt = Date.now();
  try {
    const result = await withRetry(simulatedCall, { maxRetries: 4, baseDelayMs: 500, maxDelayMs: 8000 });
    return NextResponse.json({
      success: true,
      result,
      totalAttempts: attemptsMade,
      totalElapsedMs: Date.now() - startedAt,
      // Compute the gap between each attempt, to directly observe the
      // increasing (exponential) delay pattern in real timing data.
      gapsBetweenAttemptsMs: attemptTimestamps.slice(1).map((t, i) => t - attemptTimestamps[i]),
    });
  } catch (error) {
    return NextResponse.json({
      success: false,
      error: error.message,
      totalAttempts: attemptsMade,
      totalElapsedMs: Date.now() - startedAt,
    });
  }
}
```

## The Verification

### Test 1 — Confirm retries happen and eventually succeed, with visibly increasing delays

```bash
curl -s "http://localhost:3000/api/agent/retry-test?failCount=3&statusCode=429" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  | python3 -m json.tool
```

**Expected output shape:**
```json
{
    "success": true,
    "result": { "message": "Succeeded on attempt 4" },
    "totalAttempts": 4,
    "totalElapsedMs": 7412,
    "gapsBetweenAttemptsMs": [1120, 2340, 4180]
}
```

Confirm three things:
1. `totalAttempts` is `4` — three simulated failures, then a success on the fourth attempt.
2. `gapsBetweenAttemptsMs` shows a **clearly increasing** pattern (roughly doubling each time, plus jitter) — direct, measured proof of exponential backoff in action, not a fixed constant delay.
3. Also check your **server terminal logs** — you should see three `[withRetry] Attempt N/5 failed...` warning lines, confirming the retry mechanism is logging its behavior for observability.

### Test 2 — Confirm non-retryable errors fail immediately, without wasting time on pointless retries

```bash
curl -s "http://localhost:3000/api/agent/retry-test?failCount=4&statusCode=400" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  | python3 -m json.tool
```

**Expected output:**
```json
{
    "success": false,
    "error": "Simulated failure (attempt 1)",
    "totalAttempts": 1,
    "totalElapsedMs": 3
}
```

Confirm `totalAttempts` is exactly `1`, and `totalElapsedMs` is tiny (a handful of milliseconds) — proving that a `400`-style error (which `defaultIsRetryable` correctly identifies as non-transient) is **not** retried at all, failing immediately rather than burning through backoff delays for an error that would fail identically no matter how many times it's retried.

### Test 3 — Confirm exhausting all retries surfaces the real underlying error, not a generic wrapper message

```bash
curl -s "http://localhost:3000/api/agent/retry-test?failCount=10&statusCode=429" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  | python3 -m json.tool
```

**Expected:** `totalAttempts` should be `5` (the initial attempt plus `maxRetries: 4`), `success` should be `false`, and `error` should read `"Simulated failure (attempt 5)"` — confirming that once genuinely all retries are exhausted, the caller receives the real, specific error from the final attempt, not a vague "something went wrong after several tries" message that would obscure the actual root cause.

### Test 4 — Confirm the full agent pipeline still works correctly with retry logic now wrapping every real provider call

```bash
curl -s -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"message": "What is 256 divided by 8?"}' \
  | python3 -m json.tool
```

Confirm a normal, successful response — proving the retry wrapper integrates transparently underneath the entire existing pipeline (guardrails, session management, cost tracking) without disrupting normal, successful requests at all, since `withRetry` only ever introduces delay/retries when a genuine failure actually occurs.

Once all four tests pass, you've built and thoroughly verified a genuine rate-limit-aware resilience layer: transient failures (rate limits, server errors, timeouts) are retried with intelligently increasing, jittered delays that respect provider guidance when available; permanent client errors fail fast without wasted retries; the retry budget is bounded and deterministic; and — critically — none of this changes the behavior or performance of normal, successful requests at all, exactly the property you want from a resilience layer that should be invisible until you actually need it.
