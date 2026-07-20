# Phase 7, Part 3: Unified Provider Gateways — Automatic Failover Between Groq, Gemini & DeepSeek

## The Target

This is the capstone of the entire course. We're replacing our hardcoded, Groq-only provider call with a genuine **Unified Provider Gateway** — `lib/agent/providers/providerGateway.js` — that normalizes Groq, Google Gemini (`@google/genai`), and DeepSeek (via the OpenAI-compatible client) behind one single, consistent interface, and automatically **fails over** to the next provider in line if the current one is rate-limited, erroring, or offline. We'll also build a lightweight **circuit breaker** that temporarily stops sending traffic to a provider that's recently failed repeatedly, rather than wastefully retrying a provider that's clearly having a bad day. Every single tool, guardrail, and loop we've built across six prior phases will run completely unchanged on top of this new gateway — the ultimate proof of this entire course's decoupling philosophy.

## The Concept

Think about a call center that routes incoming customer calls to available agents. If Agent A's line is busy, a well-designed system doesn't just fail the caller entirely — it routes the call to Agent B, and if Agent B is unavailable too, to Agent C. Crucially, if Agent A has been unavailable for the last several attempts in a row, a smart routing system stops even *trying* Agent A for a little while — it temporarily takes them out of rotation, rather than wasting a few seconds on every single call attempting a connection that's very likely to fail again, before finally falling through to someone who can actually help. That's exactly the two mechanisms we're building: **failover** (try the next provider if this one fails) and a **circuit breaker** (stop trying a provider that's recently proven unreliable, for a cool-down period, before giving it another chance).

The engineering challenge underneath this is **normalization**. Groq and DeepSeek both happen to expose an OpenAI-compatible SDK shape (`chat.completions.create(...)`, with `.choices[0].message.content` and `.usage.prompt_tokens`), but Google's `@google/genai` SDK has a genuinely different shape — different method names, a different response structure, different usage-field naming. If our ReAct loop directly called each SDK's native methods, adding failover would mean scattering provider-specific branching logic throughout the loop itself. Instead, we write one small **adapter function per provider** — each responsible for translating *that provider's* specific request/response shape into one common, agreed-upon shape (`{ content, usage: { promptTokens, completionTokens, totalTokens } }`). Once every provider speaks this same normalized language, the gateway (and everything above it — the entire rest of this course's codebase) never needs to know or care which specific vendor actually answered any given request.

This is the same principle we've applied at every layer of this course — the ReAct loop doesn't know tool internals (Phase 5), the chat endpoint doesn't know session storage internals (Phase 2) — now finally applied at the outermost layer of all: **the reasoning loop doesn't need to know which AI company answered its question.**

## The Implementation

### Step 1 — Per-provider adapters, each normalizing to one common response shape

**File: `lib/agent/providers/groqAdapter.js`**
```js
import Groq from 'groq-sdk';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || '' });

/**
 * Normalizes a Groq call into our common provider response shape:
 * { content: string, usage: { promptTokens, completionTokens, totalTokens } }
 * Every adapter in this file promises to return EXACTLY this shape,
 * regardless of how different the underlying SDK's native response looks.
 */
export async function callGroq({ messages, temperature, responseFormatJson, signal }) {
  const completion = await groq.chat.completions.create(
    {
      model: 'llama-3.3-70b-versatile',
      messages,
      temperature,
      ...(responseFormatJson ? { response_format: { type: 'json_object' } } : {}),
    },
    { signal }
  );

  const content = completion.choices[0]?.message?.content ?? '';
  const usage = completion.usage || {};

  return {
    content,
    usage: {
      promptTokens: usage.prompt_tokens ?? 0,
      completionTokens: usage.completion_tokens ?? 0,
      totalTokens: usage.total_tokens ?? 0,
    },
    providerName: 'groq',
    modelName: 'llama-3.3-70b-versatile',
  };
}
```

**File: `lib/agent/providers/deepseekAdapter.js`**
```js
import OpenAI from 'openai';

const deepseek = new OpenAI({
  baseURL: 'https://api.deepseek.com/v1',
  apiKey: process.env.DEEPSEEK_API_KEY || '',
});

export async function callDeepSeek({ messages, temperature, responseFormatJson, signal }) {
  const completion = await deepseek.chat.completions.create(
    {
      model: 'deepseek-v4-flash',
      messages,
      temperature,
      ...(responseFormatJson ? { response_format: { type: 'json_object' } } : {}),
    },
    { signal }
  );

  const content = completion.choices[0]?.message?.content ?? '';
  const usage = completion.usage || {};

  return {
    content,
    usage: {
      promptTokens: usage.prompt_tokens ?? 0,
      completionTokens: usage.completion_tokens ?? 0,
      totalTokens: usage.total_tokens ?? 0,
    },
    providerName: 'deepseek',
    modelName: 'deepseek-v4-flash',
  };
}
```

**File: `lib/agent/providers/geminiAdapter.js`**
```js
import { GoogleGenAI } from '@google/genai';

const genAI = new GoogleGenAI({ apiKey: process.env.GOOGLE_API_KEY || '' });

/**
 * Gemini's SDK shape is genuinely different from the OpenAI-style clients
 * above: it takes a single "contents" structure rather than a flat
 * messages array with role/content pairs, and its usage metadata field
 * names differ entirely. This adapter's ENTIRE job is absorbing that
 * difference so nothing above this file ever needs to know about it.
 */
export async function callGemini({ messages, temperature, responseFormatJson, signal }) {
  // Gemini treats the system prompt as a separate top-level field, not a
  // message in the array — we split it out here.
  const systemMessage = messages.find((m) => m.role === 'system');
  const conversationMessages = messages.filter((m) => m.role !== 'system');

  // Gemini expects role "model" instead of "assistant", and content wrapped
  // in a `parts` array — this remapping is exactly the kind of shape
  // translation an adapter exists to absorb.
  const contents = conversationMessages.map((m) => ({
    role: m.role === 'assistant' ? 'model' : 'user',
    parts: [{ text: m.content }],
  }));

  const response = await genAI.models.generateContent({
    model: 'gemini-2.5-flash',
    contents,
    config: {
      systemInstruction: systemMessage?.content,
      temperature,
      ...(responseFormatJson ? { responseMimeType: 'application/json' } : {}),
      abortSignal: signal,
    },
  });

  const content = response.text ?? '';
  const usageMetadata = response.usageMetadata || {};

  return {
    content,
    usage: {
      promptTokens: usageMetadata.promptTokenCount ?? 0,
      completionTokens: usageMetadata.candidatesTokenCount ?? 0,
      totalTokens: usageMetadata.totalTokenCount ?? 0,
    },
    providerName: 'google',
    modelName: 'gemini-2.5-flash',
  };
}
```

> **Why does the Gemini adapter split out the system message and remap roles, while the Groq/DeepSeek adapters don't need to?** This is the normalization principle made concrete. Groq and DeepSeek both natively understand the standard `{ role: 'system'|'user'|'assistant', content: string }` array shape we've used since Phase 1 — so their adapters can pass our messages through almost unchanged. Gemini's underlying API genuinely models conversations differently (a separate system instruction field, `model` instead of `assistant`, content wrapped in `parts`). Rather than teaching our entire ReAct loop, system prompt builder, and session store about Gemini's particular quirks, we contain that entire translation inside this one adapter file — exactly the kind of isolated, single-purpose "shape conversion" logic that should live at the boundary of a system, not leak into its core.

### Step 2 — A simple circuit breaker to track per-provider health

**File: `lib/agent/providers/circuitBreaker.js`**
```js
/**
 * Tracks recent failure counts per provider and temporarily "opens" the
 * circuit (stops sending traffic) for a provider that has failed too many
 * times in a row, for a fixed cool-down period — mirroring the same
 * in-memory-Map-with-
 * documented-caveat pattern used by our Phase 2 session store: this works
 * correctly on a single running instance, and would need a shared external
 * store (Redis, etc.) to coordinate circuit state across multiple
 * serverless instances in a real multi-instance production deployment.
 */
const FAILURE_THRESHOLD = 3; // consecutive failures before we "open" the circuit
const COOLDOWN_MS = 30000; // how long to keep a provider benched before giving it another chance

const providerState = new Map(); // providerName -> { consecutiveFailures, openedAt }

export function isCircuitOpen(providerName) {
  const state = providerState.get(providerName);
  if (!state || state.openedAt === null) return false;

  const elapsedSinceOpened = Date.now() - state.openedAt;
  if (elapsedSinceOpened >= COOLDOWN_MS) {
    // Cool-down period has passed — give this provider another chance
    // ("half-open" in classic circuit breaker terminology) by resetting it.
    providerState.set(providerName, { consecutiveFailures: 0, openedAt: null });
    return false;
  }

  return true; // still within cool-down — keep this provider benched
}

export function recordSuccess(providerName) {
  providerState.set(providerName, { consecutiveFailures: 0, openedAt: null });
}

export function recordFailure(providerName) {
  const state = providerState.get(providerName) || { consecutiveFailures: 0, openedAt: null };
  const consecutiveFailures = state.consecutiveFailures + 1;

  if (consecutiveFailures >= FAILURE_THRESHOLD && state.openedAt === null) {
    console.warn(`[circuitBreaker] Opening circuit for "${providerName}" after ${consecutiveFailures} consecutive failures. Benched for ${COOLDOWN_MS}ms.`);
    providerState.set(providerName, { consecutiveFailures, openedAt: Date.now() });
  } else {
    providerState.set(providerName, { consecutiveFailures, openedAt: state.openedAt });
  }
}

export function getCircuitStatus() {
  return Object.fromEntries(
    Array.from(providerState.entries()).map(([name, state]) => [
      name,
      { ...state, isOpen: isCircuitOpen(name) },
    ])
  );
}
```

### Step 3 — The Unified Provider Gateway itself

**File: `lib/agent/providers/providerGateway.js`**
```js
import { callGroq } from './groqAdapter.js';
import { callDeepSeek } from './deepseekAdapter.js';
import { callGemini } from './geminiAdapter.js';
import { isCircuitOpen, recordSuccess, recordFailure } from './circuitBreaker.js';
import { withRetry } from '../resilience/withRetry.js';

/**
 * Ordered provider chain: the gateway tries these IN ORDER, falling
 * through to the next one only if the current one fails (after its own
 * internal retries are exhausted) or its circuit is currently open. Order
 * here reflects a deliberate preference — Groq first for its low latency,
 * Gemini second, DeepSeek as a final fallback — but is trivially
 * reconfigurable by simply reordering this array.
 */
const PROVIDER_CHAIN = [
  { name: 'groq', call: callGroq },
  { name: 'google', call: callGemini },
  { name: 'deepseek', call: callDeepSeek },
];

/**
 * THE central entry point every part of the application now calls instead
 * of reaching for any individual provider's SDK directly. Returns our
 * normalized response shape, PLUS metadata about which provider actually
 * ended up serving the request and how many providers were attempted.
 */
export async function generateCompletion({ messages, temperature = 0.2, responseFormatJson = false, signal = null }) {
  const attemptLog = [];

  for (const provider of PROVIDER_CHAIN) {
    if (isCircuitOpen(provider.name)) {
      attemptLog.push({ provider: provider.name, skipped: true, reason: 'circuit_open' });
      continue; // this provider has failed too much recently — skip it without even trying
    }

    try {
      // Each provider still gets our full Phase 7 Part 1 retry treatment
      // (exponential backoff for transient errors like rate limits) BEFORE
      // the gateway gives up on it and falls through to the next provider
      // in the chain. Failover across providers is the LAST resort, after
      // retrying the CURRENT provider has already been exhausted.
      const result = await withRetry(
        () => provider.call({ messages, temperature, responseFormatJson, signal }),
        { maxRetries: 2, baseDelayMs: 800, maxDelayMs: 6000 }
      );

      recordSuccess(provider.name);
      attemptLog.push({ provider: provider.name, success: true });

      return { ...result, attemptLog };
    } catch (error) {
      recordFailure(provider.name);
      attemptLog.push({ provider: provider.name, success: false, error: error.message });
      console.warn(`[providerGateway] Provider "${provider.name}" failed, falling through to next provider:`, error.message);
      // Deliberately no `throw` here — we continue the loop to try the next provider.
    }
  }

  // Every single provider in the chain failed (or was circuit-broken) —
  // this is a genuine, total outage across our entire provider chain, and
  // we must surface that honestly rather than pretending to succeed.
  const error = new Error('All configured providers failed or are currently circuit-broken.');
  error.attemptLog = attemptLog;
  throw error;
}

// Exposed for diagnostics/monitoring endpoints.
export { getCircuitStatus } from './circuitBreaker.js';
```

### Step 4 — Update `reactLoop.js` to use the gateway instead of a hardcoded Groq client

**File: `lib/agent/reactLoop.js`** *(only the relevant provider-calling section changes — full file shown)*
```js
import { generateCompletion } from './providers/providerGateway.js';
import { generateFallbackAnswer } from './fallbackAnswer.js';
import { registry } from './mcp/registry.js';
import { trimMessagesToBudget } from './tokenBudget.js';
import { createUsageTracker } from './usageTracker.js';
import { createDeadline, throwIfAborted } from './resilience/deadline.js';

const MAX_STEPS = 6;
const MAX_CONTEXT_TOKENS = 4000;
const WHOLE_LOOP_DEADLINE_MS = 45000;

export async function runReactLoop(initialMessages) {
  let messages = [...initialMessages];
  const trace = [];
  const recentActionSignatures = [];
  const usageTracker = createUsageTracker('gateway'); // model name is now dynamic per-call; tracked per-response instead
  const { signal: deadlineSignal, clear: clearDeadline } = createDeadline(WHOLE_LOOP_DEADLINE_MS);

  try {
    for (let step = 1; step <= MAX_STEPS; step++) {
      try {
        throwIfAborted(deadlineSignal);
      } catch (deadlineError) {
        trace.push({ step, warning: 'Whole-loop deadline exceeded before this step could start.' });
        const fallbackAnswer = await generateFallbackAnswer(messages, 'deadline_exceeded');
        messages.push({ role: 'assistant', content: fallbackAnswer });
        return { finalAnswer: fallbackAnswer, stopReason: 'deadline_exceeded', trace, usage: usageTracker.getSummary(), messages };
      }

      const { trimmedMessages, wasTrimmed, removedCount } = trimMessagesToBudget(messages, MAX_CONTEXT_TOKENS);
      messages = trimmedMessages;
      if (wasTrimmed) {
        trace.push({ step, systemNote: `Trimmed ${removedCount} oldest transcript messages to stay within ${MAX_CONTEXT_TOKENS} token budget.` });
      }

      let gatewayResult;
      try {
        // THE KEY CHANGE: we call the GATEWAY, not any specific provider's
        // client directly. The loop has no idea whether Groq, Gemini, or
        // DeepSeek actually answered — and it doesn't need to.
        gatewayResult = await generateCompletion({
          messages,
          temperature: 0.2,
          responseFormatJson: true,
          signal: deadlineSignal,
        });
      } catch (error) {
        trace.push({ step, error: error.message, code: 'ALL_PROVIDERS_FAILED', attemptLog: error.attemptLog });
        const fallbackAnswer = await generateFallbackAnswer(messages, 'provider_call_failed');
        messages.push({ role: 'assistant', content: fallbackAnswer });
        return { finalAnswer: fallbackAnswer, stopReason: 'provider_call_failed', trace, usage: usageTracker.getSummary(), messages };
      }

      usageTracker.record({ usage: {
        prompt_tokens: gatewayResult.usage.promptTokens,
        completion_tokens: gatewayResult.usage.completionTokens,
        total_tokens: gatewayResult.usage.totalTokens,
      }});

      const rawContent = gatewayResult.content || '{}';
      trace.push({ step, servedBy: gatewayResult.providerName }); // NEW: transparently record which provider actually answered this step

      let parsed;
      try {
        parsed = JSON.parse(rawContent);
      } catch (err) {
        trace.push({ step, error: 'Model returned invalid JSON', rawContent });
        const fallbackAnswer = await generateFallbackAnswer(messages, 'malformed_json');
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
        const fallbackAnswer = await generateFallbackAnswer(messages, 'stuck_loop_detected');
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
    const fallbackAnswer = await generateFallbackAnswer(messages, 'max_steps_exceeded');
    messages.push({ role: 'assistant', content: fallbackAnswer });
    return { finalAnswer: fallbackAnswer, stopReason: 'max_steps_exceeded', trace, usage: usageTracker.getSummary(), messages };
  } finally {
    clearDeadline();
  }
}
```

### Step 5 — Update `fallbackAnswer.js` to also route through the gateway

**File: `lib/agent/fallbackAnswer.js`** *(full updated file)*
```js
import { generateCompletion } from './providers/providerGateway.js';

/**
 * Updated to call the gateway instead of a hardcoded Groq client — even
 * our LAST-RESORT fallback path now benefits from automatic provider
 * failover. If Groq is down, the fallback answer itself can still be
 * generated by Gemini or DeepSeek instead, rather than failing outright.
 */
export async function generateFallbackAnswer(messages, stopReason) {
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
    const result = await generateCompletion({
      messages: [...messages, fallbackInstruction],
      temperature: 0.3,
      responseFormatJson: false,
    });
    return result.content || 'Unable to generate a fallback answer.';
  } catch (error) {
    console.error('[fallback] Fallback answer generation failed across ALL providers:', error);
    return 'The agent was unable to complete this request, and all fallback providers also failed. Please try again shortly.';
  }
}
```

### Step 6 — A diagnostic endpoint exposing gateway and circuit-breaker health

**File: `app/api/agent/gateway-status/route.js`**
```js
import { NextResponse } from 'next/server';
import { getCircuitStatus } from '@/lib/agent/providers/circuitBreaker.js';

export async function GET() {
  return NextResponse.json({ circuitStatus: getCircuitStatus() });
}
```

## The Verification

Before testing, ensure your `.env.local` has a genuinely valid `GOOGLE_API_KEY` and `DEEPSEEK_API_KEY` in addition to `GROQ_API_KEY` — the whole point of this part is proving failover actually works across real providers.

### Test 1 — Confirm normal operation: Groq (first in chain) serves requests successfully

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"goal": "What is 8 times 9?"}' \
  | python3 -m json.tool
```

**Expected:** a normal successful response. Check the `trace` array for entries containing `"servedBy": "groq"` — confirming that under normal conditions, the gateway correctly defaults to the first, preferred provider in the chain, with zero failover overhead.

### Test 2 — Force a failure in the primary provider and confirm automatic failover to the next one

Temporarily set an invalid Groq key to simulate an outage:
```bash
# In .env.local, temporarily change:
GROQ_API_KEY=intentionally-broken-key-for-testing
```
Restart the server, then run the same request:
```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -H "x-api-key: demo-secret-key-change-me-in-production" \
  -d '{"goal": "What is 8 times 9?"}' \
  | python3 -m json.tool
```

**Expected behavior:** the request should still **succeed** overall, but the trace should now show `"servedBy": "google"` (Gemini, the second provider in the chain) instead of Groq — proof of genuine, automatic failover. Also check your server logs for the `[providerGateway] Provider "groq" failed, falling through to next provider...` warning line, confirming the failure was correctly detected, logged, and handled transparently, with the end user receiving a completely normal, successful response despite an entire provider outage happening behind the scenes.

Restore your real `GROQ_API_KEY` in `.env.local` and restart the server.

### Test 3 — Confirm the circuit breaker opens after repeated failures and skips a consistently-broken provider

With the broken Groq key still in place temporarily, send several requests in a row (at least 3, to exceed `FAILURE_THRESHOLD`):

```bash
for i in 1 2 3 4; do
  curl -s -X POST http://localhost:3000/api/agent/react \
    -H "Content-Type: application/json" \
    -H "x-api-key: demo-secret-key-change-me-in-production" \
    -d '{"goal": "What is 2 plus 2?"}' \
    -o /dev/null -w "Request $i completed\n"
done
```

Then check the circuit status directly:
```bash
curl -s -H "x-api-key: demo-secret-key-change-me-in-production" http://localhost:3000/api/agent/gateway-status | python3 -m json.tool
```

**Expected output:**
```json
{
    "circuitStatus": {
        "groq": { "consecutiveFailures": 4, "openedAt": 1234567890123, "isOpen": true }
    }
}
```

Confirm `isOpen: true` for `groq` — proof the circuit breaker correctly detected repeated consecutive failures and benched that provider. Send one more request and confirm in the trace/logs that the gateway now **skips Groq entirely** (you should see `{"provider": "groq", "skipped": true, "reason": "circuit_open"}` in the attempt log) and goes straight to Gemini, saving the wasted time of retrying a provider already known to be currently broken.

Restore your real `GROQ_API_KEY`, restart the server, and wait 30+ seconds (the `COOLDOWN_MS` period) before your next real test, or simply restart the server to reset the in-memory circuit state entirely.

### Test 4 — Confirm total outage across all providers is surfaced honestly, not silently swallowed

As a final, conceptual confirmation (not necessarily requiring you to actually break all three keys), review `providerGateway.js`'s final lines: if every single provider in `PROVIDER_CHAIN` fails or is circuit-broken, the function explicitly `throw`s a clear `"All configured providers failed or are currently circuit-broken."` error, with a full `attemptLog` attached — which `reactLoop.js` catches and correctly routes into our `provider_call_failed` fallback path, exactly matching this course's consistent, foundational principle since Phase 1, Part 3: **every possible failure path still produces a real, useful, non-null final answer for the user**, never a raw unhandled crash — even in the worst-case scenario of a complete, simultaneous outage across your entire AI provider portfolio.

---

With all four tests verified, the entire course architecture is complete and fully operational. Every layer built across seven phases — the ReAct loop, deterministic termination, cached system prompts, token budgeting, cross-request session memory, cost auditing, agentic and vectorless RAG, PII redaction, jailbreak detection, Zod-validated structured output, the MCP-inspired decoupled tool registry, global middleware security, parallel multi-agent cascades with a shared event bus, exponential backoff retries, whole-loop deadlines, and now full multi-provider failover with circuit breaking — now operates together as a single, cohesive, production-grade agentic system, exactly as sketched in Part 0's architecture diagram, built entirely from first principles in plain JavaScript on Next.js 16.
