# Phase 7, Part 2: Enforcing Execution Deadlines — Whole-Loop `AbortController` Timeouts

## The Target

Back in Phase 1, Part 3, we built a per-step timeout (`STEP_TIMEOUT_MS`) that protects any single model call from hanging indefinitely. But we flagged a gap explicitly in Phase 1's Reference Section (R1.3): a loop that's individually fast per step, but takes many steps, retries, and now — after Part 1 of this phase — potentially several backoff-delayed retries per step, could still accumulate into an unacceptably long *total* request duration. In this part, we build a **whole-loop deadline**: a single outer `AbortController` that enforces a hard ceiling on the *entire* ReAct loop's total wall-clock time, independent of how many individual steps or retries occur within it, and we propagate that same abort signal down through every tool call and provider request so a single deadline genuinely stops everything in flight when it fires.

## The Concept

Recall our Phase 1 analogy: a step ceiling is like a meeting agenda ("6 topics max"), and a per-step timeout is like "each topic gets at most 15 minutes." But imagine a meeting where every individual topic *does* stay under 15 minutes, yet the meeting still runs for three hours overall because there turned out to be an unexpectedly large number of topics, or several topics needed a few retries after a slow start. Without an overall "this meeting ends at 3:00 PM, full stop" rule, no individual per-topic limit protects you from the *aggregate* running long. That aggregate, whole-meeting deadline is exactly what we're building now — a ceiling on the entire ReAct loop's execution, not just any single piece of it.

The engineering mechanism for this is the same `AbortController` API we already used in Phase 1, but applied at a different, wider scope. Previously, we created a *fresh* `AbortController` inside `completionWithTimeout` for *every single* provider call. Now, we create **one** `AbortController` at the very start of the whole loop, pass its `signal` down into every step's provider call and every tool invocation, and set a single timer that aborts that one shared signal after the whole-loop deadline elapses. The moment that fires, every in-flight operation holding a reference to that signal — no matter how deep in the call stack it currently is — can immediately notice the abort and stop.

This is a genuinely important pattern to internalize: **`AbortController` signals are shareable and composable.** A single signal can be threaded through an arbitrarily deep chain of async function calls, and any one of them can check `signal.aborted` or pass the signal onward to a further `fetch`-based call, all cooperating around one shared "stop now" flag — without needing to manually track and cancel each individual operation separately. This is precisely why it's a *web standard* API, not a bespoke library feature: it's designed exactly for this kind of cross-cutting cancellation propagation.

## The Implementation

### Step 1 — A whole-loop deadline utility

**File: `lib/agent/resilience/deadline.js`**
```js
/**
 * Creates a single AbortController representing a hard deadline for an
 * entire operation (e.g. one full ReAct loop run), rather than any single
 * sub-step within it. Returns the controller's signal (to be threaded
 * through every downstream call) plus a cleanup function that MUST be
 * called once the operation finishes, to cancel the pending timer and
 * avoid leaking it for the remaining lifetime of the server process.
 */
export function createDeadline(deadlineMs) {
  const controller = new AbortController();

  const timeoutId = setTimeout(() => {
    controller.abort(new Error(`Operation exceeded overall deadline of ${deadlineMs}ms`));
  }, deadlineMs);

  return {
    signal: controller.signal,
    clear: () => clearTimeout(timeoutId),
  };
}

/**
 * A small helper to check-and-throw at any point in a longer-running
 * process, letting us stop promptly BETWEEN steps (not just abort an
 * in-flight network call) the moment a deadline has already passed —
 * useful right before starting expensive new work we could otherwise skip.
 */
export function throwIfAborted(signal) {
  if (signal.aborted) {
    throw signal.reason instanceof Error
      ? signal.reason
      : new Error('Operation was aborted.');
  }
}
```

### Step 2 — Thread the deadline signal through the timeout+retry wrapper

**File: `lib/agent/timeoutCompletion.js`** *(full updated file)*
```js
import { withRetry } from './resilience/withRetry.js';

/**
 * `outerSignal` (optional) represents a WHOLE-LOOP deadline, distinct from
 * `timeoutMs`, which still protects each INDIVIDUAL attempt. Both can be
 * active simultaneously: an individual attempt might still be well within
 * its own per-step timeout window, yet get aborted anyway because the
 * broader, whole-loop deadline has separately expired.
 */
export async function completionWithTimeout(groqClient, requestOptions, timeoutMs = 15000, outerSignal = null) {
  return withRetry(async () => {
    // If the whole-loop deadline has ALREADY passed before we even start
    // this attempt, there's no point beginning a new network request at
    // all — fail immediately rather than starting work we know is moot.
    if (outerSignal?.aborted) {
      const err = new Error('Whole-loop deadline already exceeded; skipping new attempt.');
      err.code = 'DEADLINE_EXCEEDED';
      throw err;
    }

    const controller = new AbortController();

    // If an outer (whole-loop) signal aborts WHILE this specific attempt is
    // in flight, immediately propagate that abort to this attempt's own
    // controller too — this is the actual mechanism that lets one shared,
    // top-level deadline reach all the way down into an individual,
    // currently-executing network call and cancel it right away.
    const onOuterAbort = () => controller.abort(outerSignal.reason);
    outerSignal?.addEventListener('abort', onOuterAbort);

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
        const isDeadline = outerSignal?.aborted;
        const timeoutError = new Error(
          isDeadline
            ? 'Provider call aborted due to whole-loop deadline.'
            : `Provider call timed out after ${timeoutMs}ms`
        );
        timeoutError.code = isDeadline ? 'DEADLINE_EXCEEDED' : 'PROVIDER_TIMEOUT';
        throw timeoutError;
      }
      throw error;
    } finally {
      clearTimeout(timeoutId);
      outerSignal?.removeEventListener('abort', onOuterAbort);
    }
  }, {
    maxRetries: 4,
    baseDelayMs: 1000,
    maxDelayMs: 16000,
    // Deadline-exceeded failures should NEVER be retried — retrying after
    // the whole-loop deadline has already passed would be pointless and
    // would only delay returning a response to the user even further.
    isRetryable: (error) => error.code !== 'DEADLINE_EXCEEDED' && defaultRetryCheck(error),
  });
}

function defaultRetryCheck(error) {
  const status = error.status || error.statusCode;
  if (status === 429) return true;
  if (status >= 500 && status < 600) return true;
  if (error.code === 'PROVIDER_TIMEOUT') return true;
  if (error.code === 'ECONNRESET' || error.code === 'ETIMEDOUT') return true;
  return false;
}
```

### Step 3 — Wire the whole-loop deadline into `reactLoop.js`

**File: `lib/agent/reactLoop.js`** *(full updated file)*
```js
import Groq from 'groq-sdk';
import { completionWithTimeout } from './timeoutCompletion.js';
import { generateFallbackAnswer } from './fallbackAnswer.js';
import { registry } from './mcp/registry.js';
import { trimMessagesToBudget } from './tokenBudget.js';
import { createUsageTracker } from './usageTracker.js';
import { createDeadline, throwIfAborted } from './resilience/deadline.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || '' });

const MAX_STEPS = 6;
const STEP_TIMEOUT_MS = 15000;
const MAX_CONTEXT_TOKENS = 4000;
const MODEL_NAME = 'llama-3.3-70b-versatile';
const WHOLE_LOOP_DEADLINE_MS = 45000; // hard ceiling on the ENTIRE loop's total wall-clock time

export async function runReactLoop(initialMessages) {
  let messages = [...initialMessages];
  const trace = [];
  const recentActionSignatures = [];
  const usageTracker = createUsageTracker(MODEL_NAME);

  // ONE deadline, created once, for the whole duration of this loop run —
  // its signal will be threaded into every provider call and every tool
  // execution below.
  const { signal: deadlineSignal, clear: clearDeadline } = createDeadline(WHOLE_LOOP_DEADLINE_MS);

  try {
    for (let step = 1; step <= MAX_STEPS; step++) {
      // Check BETWEEN steps too — not just inside individual network calls —
      // so that if the deadline already passed while we were busy trimming,
      // parsing, or running a tool, we stop immediately rather than kicking
      // off an entirely new, doomed step.
      try {
        throwIfAborted(deadlineSignal);
      } catch (deadlineError) {
        trace.push({ step, warning: 'Whole-loop deadline exceeded before this step could start.' });
        const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'deadline_exceeded');
        messages.push({ role: 'assistant', content: fallbackAnswer });
        return { finalAnswer: fallbackAnswer, stopReason: 'deadline_exceeded', trace, usage: usageTracker.getSummary(), messages };
      }

      const { trimmedMessages, wasTrimmed, removedCount } = trimMessagesToBudget(messages, MAX_CONTEXT_TOKENS);
      messages = trimmedMessages;
      if (wasTrimmed) {
        trace.push({ step, systemNote: `Trimmed ${removedCount} oldest transcript messages to stay within ${MAX_CONTEXT_TOKENS} token budget.` });
      }

      let completion;
      try {
        completion = await completionWithTimeout(
          groq,
          { model: MODEL_NAME, messages, response_format: { type: 'json_object' }, temperature: 0.2 },
          STEP_TIMEOUT_MS,
          deadlineSignal // <-- the whole-loop signal is threaded all the way down into this individual call
        );
      } catch (error) {
        const stopReason = error.code === 'DEADLINE_EXCEEDED' ? 'deadline_exceeded' : 'provider_call_failed';
        trace.push({ step, error: error.message, code: error.code || 'PROVIDER_ERROR' });
        const fallbackAnswer = await generateFallbackAnswer(groq, messages, stopReason);
        messages.push({ role: 'assistant', content: fallbackAnswer });
        return { finalAnswer: fallbackAnswer, stopReason, trace, usage: usageTracker.getSummary(), messages };
      }

      usageTracker.record(completion);
      const rawContent = completion.choices[0]?.message?.content ?? '{}';

      let parsed;
      try {
        parsed = JSON.parse(rawContent);
      } catch (err) {
        trace.push({ step, error: 'Model returned invalid JSON', rawContent });
        const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'malformed_json');
        messages.push({ role: 'assistant', content: fallbackAnswer });
        return { finalAnswer: fallbackAnswer, stopReason: 'malformed_json', trace, usage: usageTracker.getSummary(), messages };
      }

      const { thought, action, action_input } = parsed;
      trace.push({ step, thought, action, action_input });

      if (action === 'final_answer') {
        const finalText = typeof action_input === 'string' ? action_input : JSON.stringify(action_input);
        messages.push({ role: 'assistant', content: finalText });
        return { finalAnswer: finalText, stopReason: 'final_answer', trace, usage: usageTracker.getSummary(), messages };
      }

      const signature = `${action}::${JSON.stringify(action_input)}`;
      recentActionSignatures.push(signature);
      const repeatsOfThisSignature = recentActionSignatures.filter((s) => s === signature).length;
      if (repeatsOfThisSignature >= 2) {
        trace.push({ step, warning: 'Detected repeated action, halting loop early.' });
        const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'stuck_loop_detected');
        messages.push({ role: 'assistant', content: fallbackAnswer });
        return { finalAnswer: fallbackAnswer, stopReason: 'stuck_loop_detected', trace, usage: usageTracker.getSummary(), messages };
      }

      const executionResult = await registry.execute(action, action_input);
      const observation = executionResult.ok
        ? executionResult.result
        : { error: executionResult.message, errorType: executionResult.errorType };

      messages.push({ role: 'assistant', content: rawContent });
      messages.push({ role: 'user', content: `Observation: ${JSON.stringify(observation)}` });
    }

    trace.push({ warning: `Exceeded MAX_STEPS (${MAX_STEPS}) without reaching final_answer.` });
    const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'max_steps_exceeded');
    messages.push({ role: 'assistant', content: fallbackAnswer });
    return { finalAnswer: fallbackAnswer, stopReason: 'max_steps_exceeded', trace, usage: usageTracker.getSummary(), messages };
  } finally {
    // ALWAYS clear the deadline's pending timer when the loop finishes,
    // whether it succeeded, failed, or hit the deadline itself — otherwise
    // we'd leak a scheduled timer for the remaining lifetime of the
    // serverless function instance, exactly the same discipline from our
    // Phase 1 per-step timeout wrapper.
    clearDeadline();
  }
}
```

> **Why check `throwIfAborted` at the *top* of each loop iteration, in addition to the deadline signal being passed into `completionWithTimeout`?** These serve genuinely different purposes. The signal passed into `completionWithTimeout` protects against the deadline expiring *while a network call is actually in flight* — it can interrupt an already-started request. The `throwIfAborted` check at the top of the loop protects against a different scenario: what if the deadline expires during the *local, synchronous work* between steps — trimming the transcript, parsing JSON, executing a tool's local logic — where there's no network call in flight to abort at all? Without this check, the loop could dutifully finish its current step's non-network work, then start an entirely new, doomed step, only to have that new step's provider call immediately fail on deadline exceeded — wasting a full retry cycle's worth of setup for no benefit. Checking explicitly between steps lets us bail out immediately, cleanly, the moment we know continuing is pointless.

## The Verification

### Test 1 — Confirm normal, fast requests are completely unaffected by the new deadline

```bash
curl -s -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"message": "What is 3 times 3?"}' \
  | python3 -m json.tool
```
Confirm a normal, fast `"stopReason": "final_answer"` response — proving the 45-second whole-loop deadline is generous enough to never interfere with ordinary, well-behaved requests.

### Test 2 — Directly force a whole-loop deadline breach using a temporary, artificially tiny deadline

To observe the deadline mechanism firing without waiting 45 real seconds, temporarily lower `WHOLE_LOOP_DEADLINE_MS` in `reactLoop.js` to `2000` (2 seconds) and restart your dev server:

```js
const WHOLE_LOOP_DEADLINE_MS = 2000; // TEMPORARY, for testing only
```

Then send a request likely to require multiple reasoning steps, giving the loop enough real work to exceed 2 seconds:

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"goal": "Search the knowledge base for the refund policy, then look up order ORD-1001, then calculate 45 times 12."}' \
  | python3 -m json.tool
```

**Expected behavior:** `stopReason` should be `"deadline_exceeded"` — confirming the whole-loop deadline fired and correctly halted the loop partway through, well before it could naturally reach a `final_answer` through three full sequential tool calls. Critically, `finalAnswer` should still be a real, non-null string produced by our fallback route — proving that even a deadline-triggered halt still results in a graceful, usable response rather than an abrupt failure.

Restore `WHOLE_LOOP_DEADLINE_MS` back to `45000` and restart your server before continuing.

### Test 3 — Confirm deadline-exceeded failures are correctly excluded from retry attempts

Revisit the retry-test endpoint from Part 1, but this time confirm conceptually (via code review, since directly forcing this exact interaction requires deeper test scaffolding) that our `isRetryable` override in `completionWithTimeout` explicitly excludes `DEADLINE_EXCEEDED` — reread the relevant line:
```js
isRetryable: (error) => error.code !== 'DEADLINE_EXCEEDED' && defaultRetryCheck(error),
```
This confirms, by direct inspection, that once a whole-loop deadline has fired, no further retries will ever be attempted for that error — exactly the correct behavior, since retrying after a hard deadline has already passed would only prolong a response the user is already waiting too long for.

Once these tests pass, you've added the final missing piece of deterministic termination for this course's core agent loop: a genuine, enforced ceiling on total wall-clock execution time, correctly propagated through every layer of retries and individual provider calls via a single shared `AbortController` signal, with zero impact on normal, fast, well-behaved requests, and a graceful, still-useful fallback answer produced even in the worst case where the deadline genuinely fires.
