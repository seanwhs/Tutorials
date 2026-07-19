# Phase 1, Part 3: Deterministic Termination & Fallback Routes

## The Target

We're hardening the ReAct loop we built in Part 2 against two remaining classes of real-world failure:

1. **Wall-clock hangs** — what happens if a single provider call doesn't error out, but simply never returns? Our current loop has a *step* ceiling, but no *time* ceiling per step.
2. **Silent user-facing failure** — right now, if the loop hits `stuck_loop_detected` or `max_steps_exceeded`, we return `finalAnswer: null` to the user. That's honest, but it's a bad user experience — imagine asking a colleague a question and their only response to being confused is silence. We're going to add a **graceful fallback route**: one final, tool-free, constrained call that forces the model to give its best possible answer using whatever it already learned, rather than leaving the user with nothing.

By the end of this part, our agent will *always* return a usable answer to the user, and will *never* be able to hang a request indefinitely, no matter how the model or tools misbehave.

## The Concept

There are two related but distinct engineering ideas here.

**First: timeouts vs. step limits.** A step limit (`MAX_STEPS`) protects you from an agent that reasons *badly* — looping in circles logically. But it does nothing to protect you from an agent that reasons *slowly* — a single network call to the provider that stalls due to a server-side issue, a dropped connection, or a rate-limit queue. Think of it like a meeting with a strict agenda of "6 topics" (your step limit) versus a hard "this meeting ends at 3:00 PM no matter what" rule (a wall-clock timeout). You need both: an agenda alone doesn't stop someone from talking for two hours about topic one. We enforce the wall-clock rule using the standard Web API `AbortController`, which lets us tell an in-flight `fetch`-based request "stop waiting, right now" after a fixed duration.

**Second: fail gracefully, not silently.** Imagine calling a support hotline, and after being on hold too long, the line just goes dead with no message. That's what returning `finalAnswer: null` feels like to whoever is consuming this API. A well-engineered agent, when it can't fully solve a problem, should behave like a good human professional who's run out of time: *"I wasn't able to fully verify X, but based on what I found, here's my best answer."* We implement this as a **fallback route**: a separate, final call to the model — with tools disabled, and explicit instructions to just answer using the transcript so far — triggered only when the main loop fails to converge naturally.

This "escape hatch" pattern — a bounded main process, plus a guaranteed degraded-but-useful fallback when the main process can't complete — is one of the most important shapes in resilient system design, and we'll see it again in Phase 7 at the level of entire providers, not just individual calls.

## The Implementation

### Step 1 — A timeout-safe wrapper around the provider call

We isolate the "make a Groq call, but abort it after N milliseconds" logic into its own reusable helper function. This keeps the main loop readable and means every future part of the course that calls a provider can reuse the exact same safety wrapper.

**File: `lib/agent/timeoutCompletion.js`**
```js
/**
 * Wraps a Groq chat completion call with a hard wall-clock timeout using
 * AbortController. If the provider hasn't responded within `timeoutMs`,
 * the in-flight request is aborted and this function throws a clearly
 * labeled TimeoutError, instead of leaving the caller waiting indefinitely.
 */
export async function completionWithTimeout(groqClient, requestOptions, timeoutMs = 15000) {
  // AbortController is a standard Web API (also available in Node.js 22+)
  // that gives us a "signal" object we can hand to a fetch-based request,
  // and a .abort() method that cancels that request on demand.
  const controller = new AbortController();

  // setTimeout schedules the abort call itself — this is the actual
  // "deadline enforcement" mechanism. If the request finishes first,
  // we cancel this timer in the `finally` block below so it never fires.
  const timeoutId = setTimeout(() => {
    controller.abort(new Error(`Provider call exceeded ${timeoutMs}ms timeout`));
  }, timeoutMs);

  try {
    // The Groq SDK (like most modern provider SDKs) accepts a second
    // argument for per-request options, including an abort signal.
    const completion = await groqClient.chat.completions.create(requestOptions, {
      signal: controller.signal,
    });
    return completion;
  } catch (error) {
    // Distinguish an intentional timeout-abort from a genuine provider error,
    // so the caller can log/handle them differently if it wants to.
    if (controller.signal.aborted) {
      const timeoutError = new Error(`Provider call timed out after ${timeoutMs}ms`);
      timeoutError.code = 'PROVIDER_TIMEOUT';
      throw timeoutError;
    }
    throw error;
  } finally {
    // Always clear the pending timer, whether the call succeeded, failed,
    // or was aborted — otherwise we'd leave a dangling timer for the
    // lifetime of the serverless function instance.
    clearTimeout(timeoutId);
  }
}
```

> **Why a separate file under `lib/agent/`?** This is our first piece of code that isn't an API endpoint — it's shared logic that multiple Route Handlers will need. Next.js doesn't treat files outside the `app/` directory as routes at all, so `lib/` is a safe, conventional place for reusable modules. We'll keep building this folder out across every remaining phase.

### Step 2 — The fallback route: a guaranteed "best effort" answer

**File: `lib/agent/fallbackAnswer.js`**
```js
import { completionWithTimeout } from './timeoutCompletion.js';

/**
 * Called only when the main ReAct loop fails to converge on its own
 * (stuck loop, malformed JSON, or step limit exceeded). Makes ONE final,
 * tool-free call asking the model to do its best with whatever context
 * already exists in the transcript, guaranteeing the user gets a real
 * answer instead of a bare null/error.
 */
export async function generateFallbackAnswer(groqClient, messages, stopReason) {
  const fallbackInstruction = {
    role: 'user',
    content: `
You were unable to fully complete the task through normal steps (reason: "${stopReason}").
Do NOT attempt to use any tools or return JSON this time.
Based ONLY on the information already gathered above, give the best plain-text answer
you can to the original request. If you genuinely cannot answer, say so clearly and
explain what information was missing.
    `.trim(),
  };

  try {
    const completion = await completionWithTimeout(
      groqClient,
      {
        model: 'llama-3.3-70b-versatile',
        messages: [...messages, fallbackInstruction],
        temperature: 0.3,
        // Deliberately NO response_format constraint here — we want free-form
        // natural language for a human, not structured JSON for our loop.
      },
      10000 // shorter timeout than the main loop's steps, since this is a last resort
    );

    return completion.choices[0]?.message?.content ?? 'Unable to generate a fallback answer.';
  } catch (error) {
    // If even the fallback call fails, we still must not throw an unhandled
    // error up to the client — we return an honest, safe message instead.
    console.error('[fallback] Fallback answer generation failed:', error);
    return 'The agent was unable to complete this request and the fallback response also failed. Please try again.';
  }
}
```

### Step 3 — Wire both into the main loop

Update the route handler to use the timeout-safe wrapper for every step, and to invoke the fallback whenever the loop ends for any reason other than a clean `final_answer`.

**File: `app/api/agent/react/route.js`** *(full updated file)*
```js
import { NextResponse } from 'next/server';
import Groq from 'groq-sdk';
import { completionWithTimeout } from '@/lib/agent/timeoutCompletion.js';
import { generateFallbackAnswer } from '@/lib/agent/fallbackAnswer.js';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

const TOOLS = {
  calculator: async (input) => {
    const expression = String(input ?? '');
    const isSafeExpression = /^[0-9+\-*/().\s]+$/.test(expression);
    if (!isSafeExpression) {
      return { error: `Rejected unsafe expression: "${expression}"` };
    }
    try {
      const result = new Function(`return (${expression});`)();
      return { result };
    } catch (err) {
      return { error: `Could not evaluate expression: ${err.message}` };
    }
  },

  getCurrentTime: async () => {
    return { isoTimestamp: new Date().toISOString() };
  },
};

const TOOL_DESCRIPTIONS = `
- calculator: Evaluates a basic arithmetic expression. action_input must be a string like "42 * 17".
- getCurrentTime: Returns the current UTC timestamp. action_input should be an empty string.
`.trim();

const SYSTEM_PROMPT = `
You are a careful reasoning agent that solves tasks step by step.

On EVERY turn, you must respond with a single JSON object and nothing else —
no markdown, no commentary outside the JSON. The object must have this exact shape:

{
  "thought": "<your brief reasoning about what to do next>",
  "action": "<one of: calculator, getCurrentTime, final_answer>",
  "action_input": "<the input for the chosen action, or your answer text if action is final_answer>"
}

Available tools:
${TOOL_DESCRIPTIONS}

Rules:
- Choose exactly ONE action per turn.
- Only use "final_answer" once you have all the information you need.
- Never invent tool results — always wait for the real observation before continuing.
- Keep "thought" short (one sentence).
`.trim();

const MAX_STEPS = 6;
const STEP_TIMEOUT_MS = 15000; // hard wall-clock ceiling per individual model call

async function runReactLoop(userGoal) {
  const messages = [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: userGoal },
  ];

  const trace = [];
  const recentActionSignatures = [];

  for (let step = 1; step <= MAX_STEPS; step++) {
    // --- THINK -------------------------------------------------------------
    let completion;
    try {
      completion = await completionWithTimeout(
        groq,
        {
          model: 'llama-3.3-70b-versatile',
          messages,
          response_format: { type: 'json_object' },
          temperature: 0.2,
        },
        STEP_TIMEOUT_MS
      );
    } catch (error) {
      // A timed-out or genuinely failed provider call is NOT a crash —
      // it's a signal to stop the main loop and hand off to the fallback.
      trace.push({ step, error: error.message, code: error.code || 'PROVIDER_ERROR' });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'provider_call_failed');
      return { finalAnswer: fallbackAnswer, stopReason: 'provider_call_failed', trace };
    }

    const rawContent = completion.choices[0]?.message?.content ?? '{}';

    let parsed;
    try {
      parsed = JSON.parse(rawContent);
    } catch (err) {
      trace.push({ step, error: 'Model returned invalid JSON', rawContent });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'malformed_json');
      return { finalAnswer: fallbackAnswer, stopReason: 'malformed_json', trace };
    }

    const { thought, action, action_input } = parsed;
    trace.push({ step, thought, action, action_input });

    // --- Stopping condition 1: the model says it's done ---------------------
    if (action === 'final_answer') {
      return { finalAnswer: action_input, stopReason: 'final_answer', trace };
    }

    // --- Stopping condition 2: repeated identical action (stuck loop) -------
    const signature = `${action}::${action_input}`;
    recentActionSignatures.push(signature);
    const repeatsOfThisSignature = recentActionSignatures.filter((s) => s === signature).length;
    if (repeatsOfThisSignature >= 2) {
      trace.push({ step, warning: 'Detected repeated action, halting loop early.' });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'stuck_loop_detected');
      return { finalAnswer: fallbackAnswer, stopReason: 'stuck_loop_detected', trace };
    }

    // --- ACT -----------------------------------------------------------------
    const tool = TOOLS[action];
    let observation;
    if (!tool) {
      observation = { error: `Unknown tool "${action}". Available tools: ${Object.keys(TOOLS).join(', ')}` };
    } else {
      observation = await tool(action_input);
    }

    // --- OBSERVE ---------------------------------------------------------------
    messages.push({ role: 'assistant', content: rawContent });
    messages.push({ role: 'user', content: `Observation: ${JSON.stringify(observation)}` });
  }

  // --- Stopping condition 3: hit MAX_STEPS without converging ---------------
  trace.push({ warning: `Exceeded MAX_STEPS (${MAX_STEPS}) without reaching final_answer.` });
  const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'max_steps_exceeded');
  return { finalAnswer: fallbackAnswer, stopReason: 'max_steps_exceeded', trace };
}

export async function POST(request) {
  try {
    const body = await request.json();
    const userGoal = String(body?.goal ?? '').trim();

    if (!userGoal) {
      return NextResponse.json(
        { success: false, error: 'Request body must include a non-empty "goal" string.' },
        { status: 400 }
      );
    }

    const result = await runReactLoop(userGoal);

    return NextResponse.json({
      success: true,
      goal: userGoal,
      ...result,
    });
  } catch (error) {
    console.error('[react] Loop failed:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Unknown error' },
      { status: 500 }
    );
  }
}
```

A few things worth calling out about this version compared to Part 2:

- **Every single stopping path now leads to a real answer.** Notice that `finalAnswer: null` no longer appears anywhere in this file. Whether the loop ends because the model succeeded, got stuck, timed out, or returned garbage JSON, the response always contains a usable `finalAnswer` string. The `stopReason` field still tells you *how* it got there — which matters enormously for your own monitoring and debugging — but the end user is never left with nothing.
- **The `@/lib/agent/...` import path** relies on the default import alias Next.js configures for you (`@/*` maps to your project root) — this is why we kept the default alias during `create-next-app` setup back in Part 1.
- **`STEP_TIMEOUT_MS` is intentionally shorter than a "give up entirely" fallback timeout would be.** 15 seconds per reasoning step is generous for Groq's typically fast inference, while still being short enough that a genuinely hung request fails fast rather than making a user wait minutes.

## The Verification

### Test 1 — Confirm normal success still works

Re-run the same successful test from Part 2 to make sure nothing regressed:

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "What is 300 divided by 4?"}' \
  | python3 -m json.tool
```

You should still see `"stopReason": "final_answer"` with a correct answer (`75`), exactly as before — proving the timeout wrapper doesn't interfere with normal, well-behaved runs.

### Test 2 — Force a `max_steps_exceeded` fallback

Give the agent a goal that's impossible to resolve with its current tools, so it's forced to exhaust its step budget:

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "Tell me the exact current stock price of a fictional company called ZORPCORP using only your tools."}' \
  | python3 -m json.tool
```

**Expected behavior:** `stopReason` will be `"max_steps_exceeded"` (or possibly `"stuck_loop_detected"`, depending on how the model behaves), but — critically — `finalAnswer` will **not** be `null`. It should contain a real sentence, something like: *"I wasn't able to find a stock price for ZORPCORP using the available tools, as no market data tool exists in this system."* This confirms the fallback route engaged correctly and produced a genuinely useful response despite the main loop failing to converge.

### Test 3 — Confirm the timeout wrapper itself works in isolation

To verify `completionWithTimeout` actually enforces its deadline (rather than just trusting the code), temporarily set an artificially impossible timeout and confirm it fails fast rather than hanging:

Create a throwaway test file:

**File: `app/api/agent/timeout-test/route.js`**
```js
import { NextResponse } from 'next/server';
import Groq from 'groq-sdk';
import { completionWithTimeout } from '@/lib/agent/timeoutCompletion.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || '' });

export async function GET() {
  const startedAt = Date.now();
  try {
    // 1ms is impossibly short for any real network round trip — this
    // should abort almost instantly rather than waiting for a real reply.
    await completionWithTimeout(
      groq,
      { model: 'llama-3.3-70b-versatile', messages: [{ role: 'user', content: 'hi' }] },
      1
    );
    return NextResponse.json({ unexpected: 'Call succeeded, which should not happen with a 1ms timeout.' });
  } catch (error) {
    return NextResponse.json({
      confirmedTimeout: true,
      elapsedMs: Date.now() - startedAt,
      code: error.code,
      message: error.message,
    });
  }
}
```

Run it:

```bash
curl -s http://localhost:3000/api/agent/timeout-test | python3 -m json.tool
```

**Expected output:**
```json
{
    "confirmedTimeout": true,
    "elapsedMs": 3,
    "code": "PROVIDER_TIMEOUT",
    "message": "Provider call timed out after 1ms"
}
```

The important detail is `elapsedMs` being a tiny number (single-digit to low double-digit milliseconds) — proof that the request was genuinely aborted immediately, rather than the promise happening to resolve quickly on its own. Once confirmed, delete this throwaway route — it was purely diagnostic and isn't part of the permanent application:

```bash
rm -rf app/api/agent/timeout-test
```

With all three tests passing, your ReAct loop now has fully deterministic termination: it cannot hang past its per-step timeout, cannot spin forever past its step ceiling, cannot get permanently stuck retrying an identical failed action, and — no matter which of those boundaries it hits — it always hands the user back a real, useful answer via the fallback route. This closes out the foundational reasoning loop for the entire course.
