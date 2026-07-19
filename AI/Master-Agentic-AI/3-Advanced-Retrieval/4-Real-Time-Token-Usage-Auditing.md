# Phase 3, Part 4: Real-Time Token Usage Auditing Per User Turn

## The Target

We already track raw token counts via `usageTracker.js` (Phase 2, Part 2), but raw token counts alone don't answer the question a real business actually cares about: **"what did this specific user's request cost us, in dollars?"** In this part, we build a proper **cost auditing layer** — a pricing table for each model, a function that converts token counts into real dollar estimates, and a persistent **cost ledger** that accumulates spend per session, so we can answer both "what did this one turn cost" and "what has this user cost us across their whole conversation."

## The Concept

Think about a taxi meter. It doesn't just tell you "you traveled 4.2 miles" at the end of the ride — it continuously converts distance and time into an actual fare, in real currency, that you can see accumulating turn by turn. Raw token counts are the "4.2 miles" — technically accurate, but not directly meaningful to anyone making a business decision. Converting tokens into dollars, using each provider's actual published pricing, is what turns a technical metric into something a product manager, a finance team, or an alerting system can actually act on ("this single user's conversation just cost us $4.30 — that's unusual, let's look into why").

There's a second, subtler idea here: **input tokens and output tokens are priced very differently by every major provider**, usually with output tokens costing several times more per token than input tokens (since generating text is more computationally expensive than reading it). A naive system that just reports `totalTokens` obscures this — two requests with identical total token counts can have wildly different actual costs if one skews heavily toward output generation (like our multi-step ReAct loop, which generates a JSON reasoning turn on every single step) versus one that's mostly large input context with a short reply. Our cost model needs to treat these as genuinely separate line items, not a single lump sum.

Finally, we introduce the idea of a **cost ledger** — an append-only, session-scoped running total. This reuses the exact same session-store pattern we already built in Phase 2, Part 3 (a `Map`-backed store with a documented "swap this for Redis in production" caveat) — because tracking cost *across* a multi-turn conversation is fundamentally the same kind of cross-request state problem as tracking chat history, just applied to a different piece of data.

## The Implementation

### Step 1 — A pricing table, kept separate from logic

**File: `lib/agent/cost/pricing.js`**
```js
/**
 * Published per-model pricing, expressed in US dollars per ONE MILLION
 * tokens — the standard unit most providers quote pricing in. Keeping this
 * as a flat, isolated data table (rather than scattering dollar math
 * throughout the codebase) means updating prices when a provider changes
 * their rates is a one-file edit, not a hunt through business logic.
 *
 * IMPORTANT: these are illustrative example rates for this course. Always
 * check each provider's official, current pricing page before relying on
 * these numbers for real financial reporting — providers change pricing
 * periodically, and free-tier vs. paid-tier rates can differ substantially.
 */
export const MODEL_PRICING = {
  'llama-3.3-70b-versatile': {
    provider: 'groq',
    inputPerMillion: 0.59,
    outputPerMillion: 0.79,
  },
  'gemini-2.5-flash': {
    provider: 'google',
    inputPerMillion: 0.15,
    outputPerMillion: 0.60,
  },
  'deepseek-v4-flash': {
    provider: 'deepseek',
    inputPerMillion: 0.27,
    outputPerMillion: 1.10,
  },
};

/**
 * Looks up pricing for a model, falling back to a conservative default rate
 * if a model isn't in our table yet — this prevents a silent $0.00 cost
 * report for a model we simply forgot to add pricing for (a dangerous kind
 * of invisible bug in a real cost-auditing system), while clearly flagging
 * that the estimate is a fallback rather than accurate published pricing.
 */
export function getModelPricing(modelName) {
  const known = MODEL_PRICING[modelName];
  if (known) return { ...known, isFallbackEstimate: false };

  console.warn(`[pricing] No pricing entry for model "${modelName}" — using conservative fallback rate.`);
  return {
    provider: 'unknown',
    inputPerMillion: 1.0,
    outputPerMillion: 2.0,
    isFallbackEstimate: true,
  };
}
```

### Step 2 — Cost calculation from token counts

**File: `lib/agent/cost/calculateCost.js`**
```js
import { getModelPricing } from './pricing.js';

/**
 * Converts raw token counts into a real dollar cost estimate, treating
 * input and output tokens as separate line items priced independently —
 * matching how every major provider actually bills.
 */
export function calculateCost(modelName, promptTokens, completionTokens) {
  const pricing = getModelPricing(modelName);

  const inputCost = (promptTokens / 1_000_000) * pricing.inputPerMillion;
  const outputCost = (completionTokens / 1_000_000) * pricing.outputPerMillion;
  const totalCost = inputCost + outputCost;

  return {
    modelName,
    provider: pricing.provider,
    promptTokens,
    completionTokens,
    inputCostUsd: roundToCents(inputCost, 6), // token costs are tiny — keep more precision than 2 decimals
    outputCostUsd: roundToCents(outputCost, 6),
    totalCostUsd: roundToCents(totalCost, 6),
    isFallbackEstimate: pricing.isFallbackEstimate,
  };
}

// Rounds to a given number of decimal places — we use 6 decimal places
// (not the usual 2) because individual LLM calls often cost a fraction of
// a cent; rounding to 2 decimals would show "$0.00" for nearly every
// single call, hiding real signal that only becomes visible in aggregate.
function roundToCents(value, decimalPlaces) {
  const factor = 10 ** decimalPlaces;
  return Math.round(value * factor) / factor;
}
```

### Step 3 — Upgrade the usage tracker into a full cost-aware tracker

**File: `lib/agent/usageTracker.js`** *(full updated file, replacing the Phase 2 version)*
```js
import { calculateCost } from './cost/calculateCost.js';

/**
 * Tracks BOTH raw token usage and real dollar cost across every model call
 * made during a single ReAct loop run. This is the per-TURN auditing layer;
 * Part 5 (the cost ledger) will build on top of this to track cost across
 * an entire multi-turn SESSION.
 */
export function createUsageTracker(modelName) {
  const totals = {
    promptTokens: 0,
    completionTokens: 0,
    totalTokens: 0,
    callCount: 0,
    totalCostUsd: 0,
  };
  const perCallBreakdown = [];

  return {
    record(completion) {
      const usage = completion?.usage;
      if (!usage) return;

      const promptTokens = usage.prompt_tokens ?? 0;
      const completionTokens = usage.completion_tokens ?? 0;

      const cost = calculateCost(modelName, promptTokens, completionTokens);

      totals.promptTokens += promptTokens;
      totals.completionTokens += completionTokens;
      totals.totalTokens += usage.total_tokens ?? 0;
      totals.callCount += 1;
      totals.totalCostUsd = roundTotal(totals.totalCostUsd + cost.totalCostUsd);

      perCallBreakdown.push(cost);
    },
    getSummary() {
      return {
        ...totals,
        totalCostUsd: roundTotal(totals.totalCostUsd),
        perCallBreakdown,
      };
    },
  };
}

function roundTotal(value) {
  return Math.round(value * 1_000_000) / 1_000_000;
}
```

### Step 4 — Update `reactLoop.js` to pass the model name into the tracker

**File: `lib/agent/reactLoop.js`** *(only the relevant lines change — shown with surrounding context)*
```js
import Groq from 'groq-sdk';
import { completionWithTimeout } from './timeoutCompletion.js';
import { generateFallbackAnswer } from './fallbackAnswer.js';
import { TOOLS } from './tools.js';
import { trimMessagesToBudget } from './tokenBudget.js';
import { createUsageTracker } from './usageTracker.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || '' });

const MAX_STEPS = 6;
const STEP_TIMEOUT_MS = 15000;
const MAX_CONTEXT_TOKENS = 4000;
const MODEL_NAME = 'llama-3.3-70b-versatile'; // single source of truth for the active model ID

export async function runReactLoop(initialMessages) {
  let messages = [...initialMessages];

  const trace = [];
  const recentActionSignatures = [];
  const usageTracker = createUsageTracker(MODEL_NAME); // now cost-aware, keyed to the active model

  for (let step = 1; step <= MAX_STEPS; step++) {
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
        STEP_TIMEOUT_MS
      );
    } catch (error) {
      trace.push({ step, error: error.message, code: error.code || 'PROVIDER_ERROR' });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'provider_call_failed');
      messages.push({ role: 'assistant', content: fallbackAnswer });
      return { finalAnswer: fallbackAnswer, stopReason: 'provider_call_failed', trace, usage: usageTracker.getSummary(), messages };
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
      messages.push({ role: 'assistant', content: action_input });
      return { finalAnswer: action_input, stopReason: 'final_answer', trace, usage: usageTracker.getSummary(), messages };
    }

    const signature = `${action}::${action_input}`;
    recentActionSignatures.push(signature);
    const repeatsOfThisSignature = recentActionSignatures.filter((s) => s === signature).length;
    if (repeatsOfThisSignature >= 2) {
      trace.push({ step, warning: 'Detected repeated action, halting loop early.' });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'stuck_loop_detected');
      messages.push({ role: 'assistant', content: fallbackAnswer });
      return { finalAnswer: fallbackAnswer, stopReason: 'stuck_loop_detected', trace, usage: usageTracker.getSummary(), messages };
    }

    const tool = TOOLS[action];
    let observation;
    if (!tool) {
      observation = { error: `Unknown tool "${action}". Available tools: ${Object.keys(TOOLS).join(', ')}` };
    } else {
      observation = await tool(action_input);
    }

    messages.push({ role: 'assistant', content: rawContent });
    messages.push({ role: 'user', content: `Observation: ${JSON.stringify(observation)}` });
  }

  trace.push({ warning: `Exceeded MAX_STEPS (${MAX_STEPS}) without reaching final_answer.` });
  const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'max_steps_exceeded');
  messages.push({ role: 'assistant', content: fallbackAnswer });
  return { finalAnswer: fallbackAnswer, stopReason: 'max_steps_exceeded', trace, usage: usageTracker.getSummary(), messages };
}
```

### Step 5 — A per-session cost ledger, mirroring the session store pattern from Phase 2

**File: `lib/agent/cost/costLedger.js`**
```js
/**
 * A session-scoped, accumulating cost ledger. Mirrors the exact same
 * pluggable-store pattern as lib/agent/sessionStore.js from Phase 2 —
 * same in-memory Map caveat applies here too: this works correctly on a
 * single running instance only. In production, back this with the SAME
 * shared store (Redis, a database) you'd use for sessionStore.js, ideally
 * writing both pieces of state together in a single transaction/call.
 */
const ledger = new Map();

export function recordTurnCost(sessionId, usageSummary) {
  const existing = ledger.get(sessionId) || {
    turnCount: 0,
    totalPromptTokens: 0,
    totalCompletionTokens: 0,
    totalCostUsd: 0,
    history: [],
  };

  existing.turnCount += 1;
  existing.totalPromptTokens += usageSummary.promptTokens;
  existing.totalCompletionTokens += usageSummary.completionTokens;
  existing.totalCostUsd = roundTotal(existing.totalCostUsd + usageSummary.totalCostUsd);
  existing.history.push({
    turn: existing.turnCount,
    costUsd: usageSummary.totalCostUsd,
    tokens: usageSummary.totalTokens,
    timestamp: new Date().toISOString(),
  });

  ledger.set(sessionId, existing);
  return existing;
}

export function getSessionCostSummary(sessionId) {
  return ledger.get(sessionId) || null;
}

function roundTotal(value) {
  return Math.round(value * 1_000_000) / 1_000_000;
}
```

### Step 6 — Wire the ledger into the stateful chat endpoint

**File: `app/api/agent/chat/route.js`** *(full updated file)*
```js
import { NextResponse } from 'next/server';
import { buildSystemPrompt } from '@/lib/agent/systemPrompt.js';
import { runReactLoop } from '@/lib/agent/reactLoop.js';
import { resolveSessionId } from '@/lib/agent/session.js';
import { getSession, saveSession } from '@/lib/agent/sessionStore.js';
import { recordTurnCost, getSessionCostSummary } from '@/lib/agent/cost/costLedger.js';

export async function POST(request) {
  try {
    const body = await request.json();
    const userMessage = String(body?.message ?? '').trim();

    if (!userMessage) {
      return NextResponse.json(
        { success: false, error: 'Request body must include a non-empty "message" string.' },
        { status: 400 }
      );
    }

    const { sessionId, isNewSession } = await resolveSessionId();
    const existingMessages = getSession(sessionId);

    let messages;
    if (existingMessages) {
      messages = [...existingMessages, { role: 'user', content: userMessage }];
    } else {
      const systemPrompt = await buildSystemPrompt();
      messages = [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userMessage },
      ];
    }

    const { finalAnswer, stopReason, trace, usage, messages: updatedMessages } =
      await runReactLoop(messages);

    saveSession(sessionId, updatedMessages);

    // Record THIS turn's cost against the running session ledger, and
    // retrieve the updated cumulative summary to return to the caller.
    const sessionCostSummary = recordTurnCost(sessionId, usage);

    return NextResponse.json({
      success: true,
      sessionId,
      isNewSession,
      finalAnswer,
      stopReason,
      turnCount: updatedMessages.filter((m) => m.role === 'user' || m.role === 'assistant').length,
      trace,
      thisTurnCost: {
        promptTokens: usage.promptTokens,
        completionTokens: usage.completionTokens,
        totalCostUsd: usage.totalCostUsd,
      },
      cumulativeSessionCost: {
        turnCount: sessionCostSummary.turnCount,
        totalCostUsd: sessionCostSummary.totalCostUsd,
        totalPromptTokens: sessionCostSummary.totalPromptTokens,
        totalCompletionTokens: sessionCostSummary.totalCompletionTokens,
      },
    });
  } catch (error) {
    console.error('[chat] Loop failed:', error);
    return NextResponse.json(
      { success: false, error: error.message || 'Unknown error' },
      { status: 500 }
    );
  }
}
```

### Step 7 — A dedicated cost-inspection endpoint

**File: `app/api/agent/cost-summary/route.js`**
```js
import { NextResponse } from 'next/server';
import { resolveSessionId } from '@/lib/agent/session.js';
import { getSessionCostSummary } from '@/lib/agent/cost/costLedger.js';

export async function GET() {
  const { sessionId } = await resolveSessionId();
  const summary = getSessionCostSummary(sessionId);

  if (!summary) {
    return NextResponse.json({ sessionId, message: 'No cost history found for this session yet.' });
  }

  return NextResponse.json({ sessionId, ...summary });
}
```

## The Verification

### Test 1 — Confirm per-model cost calculation logic in isolation

**File: `app/api/agent/cost-test/route.js`**
```js
import { NextResponse } from 'next/server';
import { calculateCost } from '@/lib/agent/cost/calculateCost.js';

export async function GET() {
  // 1000 prompt tokens + 500 completion tokens, priced against our known model.
  const known = calculateCost('llama-3.3-70b-versatile', 1000, 500);
  // An unregistered model name, to confirm the fallback pricing path engages.
  const unknown = calculateCost('some-future-model-v9', 1000, 500);

  return NextResponse.json({ known, unknown });
}
```

```bash
curl -s http://localhost:3000/api/agent/cost-test | python3 -m json.tool
```

**Expected output:**
```json
{
    "known": {
        "modelName": "llama-3.3-70b-versatile",
        "provider": "groq",
        "promptTokens": 1000,
        "completionTokens": 500,
        "inputCostUsd": 0.00059,
        "outputCostUsd": 0.000395,
        "totalCostUsd": 0.000985,
        "isFallbackEstimate": false
    },
    "unknown": {
        "modelName": "some-future-model-v9",
        "provider": "unknown",
        "promptTokens": 1000,
        "completionTokens": 500,
        "inputCostUsd": 0.001,
        "outputCostUsd": 0.001,
        "totalCostUsd": 0.002,
        "isFallbackEstimate": true
    }
}
```

Confirm `isFallbackEstimate` correctly flips to `true` for the unregistered model — proof the "never silently report $0.00 for an unknown model" safeguard works.

### Test 2 — Confirm cumulative cost tracking across a real multi-turn session

Using the same cookie jar approach from Phase 2:

```bash
curl -s -c cookies.txt -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is 88 times 4?"}' \
  | python3 -m json.tool
```

Note the `cumulativeSessionCost.turnCount` should be `1`. Now send a second turn:

```bash
curl -s -b cookies.txt -c cookies.txt -X POST http://localhost:3000/api/agent/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Now search the knowledge base for the refund policy."}' \
  | python3 -m json.tool
```

**Expected:** `cumulativeSessionCost.turnCount` should now be `2`, and `totalCostUsd` should have increased from the first response's value — confirming costs are accumulating correctly across genuinely separate HTTP requests, not resetting each time.

Finally, confirm the dedicated summary endpoint reflects the same accumulated totals:

```bash
curl -s -b cookies.txt http://localhost:3000/api/agent/cost-summary | python3 -m json.tool
```

**Expected output** shape:
```json
{
    "sessionId": "a1b2c3d4-...",
    "turnCount": 2,
    "totalPromptTokens": 1850,
    "totalCompletionTokens": 210,
    "totalCostUsd": 0.002194,
    "history": [
        { "turn": 1, "costUsd": 0.001080, "tokens": 940, "timestamp": "..." },
        { "turn": 2, "costUsd": 0.001114, "tokens": 1120, "timestamp": "..." }
    ]
}
```

With both tests passing, you've built a real, functioning cost-auditing layer: individual model calls are priced accurately using per-model, input/output-differentiated rates; unknown models trigger a visible fallback rather than a silent zero; and cost accumulates correctly and persistently across a genuinely multi-turn, cross-request conversation — giving you exactly the kind of per-user-turn financial visibility a real production system needs before scaling to real traffic.
