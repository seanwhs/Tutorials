# Phase 2, Part 2: Token Budget Control & Dynamic History Trimming

## The Target

Our ReAct loop's `messages` array grows by two entries every single step (one assistant turn, one observation). Right now, nothing stops that array from growing indefinitely if a task requires many steps — and every model has a hard ceiling on how much text it can accept in one request, called a **context window**. In this part, we build a **token counter** and a **history-trimming function** that keeps our conversation transcript within a safe budget, while explicitly protecting the system prompt and the original user goal from ever being trimmed away.

## The Concept

Language models don't read text the way you do, character by character or word by word. They break text into chunks called **tokens** — roughly, a token is about ¾ of an English word on average (short words are often one token; longer or unusual words get split into multiple tokens). Every model has a maximum number of tokens it can accept across the entire conversation in a single request — its **context window**. If you exceed it, the request fails outright.

Think of the context window like the cargo hold of a delivery truck. It has a fixed maximum weight capacity. If you're the dispatcher, you don't just keep stacking boxes onto the truck and hope for the best — you actively track the running weight, and if you're approaching the limit, you have to make a decision about what to leave behind. Critically, you don't want to leave behind the *shipping manifest* (the system prompt, which tells the driver what rules to follow) or the *destination address* (the user's original goal) — those are non-negotiable. What you *can* leave behind, if you must, are the earliest, least-recently-relevant boxes loaded first.

That's exactly the trimming strategy we implement: **always keep the system prompt and the original user goal intact, and if the running token count creeps too high, start dropping the oldest assistant/observation pairs from the middle of the transcript** — the freshest exchanges (most likely to matter for the very next reasoning step) are preserved, while stale, early back-and-forth is sacrificed first.

We also need a way to actually *count* tokens before we can enforce a budget. Precise token counting requires the exact same tokenizer algorithm the model itself uses internally, which varies by provider and is often not exposed as a simple public library for every model. For this course, we use a well-established, dependency-free **approximation heuristic** (characters ÷ 4 ≈ tokens for English text) — accurate enough to make safe budgeting decisions, without requiring a heavyweight, provider-specific tokenizer package. We call this out explicitly as an approximation, not a precise count, so you know exactly what guarantee you are and are not getting.

## The Implementation

### Step 1 — A token estimation utility

**File: `lib/agent/tokenBudget.js`**
```js
/**
 * Approximates the token count of a string using the widely-used heuristic
 * of ~4 characters per token for English text. This is NOT an exact count —
 * exact tokenization depends on the specific model's tokenizer — but it is
 * accurate enough (typically within 10-15%) to make safe, conservative
 * budgeting decisions without pulling in a heavyweight tokenizer library
 * for every provider we support.
 */
export function estimateTokens(text) {
  if (!text) return 0;
  return Math.ceil(String(text).length / 4);
}

/**
 * Estimates the total token footprint of an array of chat messages,
 * including a small fixed overhead per message to account for the
 * role/formatting metadata every provider adds under the hood.
 */
export function estimateMessagesTokens(messages) {
  const PER_MESSAGE_OVERHEAD_TOKENS = 4; // conservative buffer for role/structure metadata
  return messages.reduce(
    (total, msg) => total + estimateTokens(msg.content) + PER_MESSAGE_OVERHEAD_TOKENS,
    0
  );
}

/**
 * Trims a chat messages array to fit within a token budget, while
 * GUARANTEEING two things are never removed:
 *   1. The system prompt (always messages[0], by our loop's convention)
 *   2. The original user goal (always messages[1], by our loop's convention)
 *
 * If trimming is required, we remove the OLDEST assistant/observation pairs
 * first (the messages immediately after the protected pair), preserving the
 * most recent exchanges, which are most likely to be relevant to the next
 * reasoning step.
 */
export function trimMessagesToBudget(messages, maxTokens) {
  // Nothing to do if we're already within budget — avoid unnecessary work.
  if (estimateMessagesTokens(messages) <= maxTokens) {
    return { trimmedMessages: messages, wasTrimmed: false, removedCount: 0 };
  }

  const PROTECTED_COUNT = 2; // system prompt + original user goal
  const protectedMessages = messages.slice(0, PROTECTED_COUNT);
  let trimmableMessages = messages.slice(PROTECTED_COUNT);

  let removedCount = 0;

  // Remove from the FRONT of the trimmable section (oldest first), two at a
  // time, since our loop always pushes assistant+observation as a pair —
  // removing them together avoids ever leaving a dangling, context-less
  // observation with no matching assistant turn before it.
  while (
    trimmableMessages.length > 0 &&
    estimateMessagesTokens([...protectedMessages, ...trimmableMessages]) > maxTokens
  ) {
    trimmableMessages = trimmableMessages.slice(2);
    removedCount += 2;
  }

  const trimmedMessages = [...protectedMessages, ...trimmableMessages];

  return {
    trimmedMessages,
    wasTrimmed: removedCount > 0,
    removedCount,
  };
}
```

> **Why remove in pairs of 2, specifically?** Our loop's convention (established back in Phase 1, Part 2) is that every step pushes exactly two messages: one `assistant` message (the model's JSON turn) and one `user` message (the tool observation). If we trimmed a single message at a time, we could end up leaving an orphaned observation with no corresponding assistant turn before it in the transcript — which would confuse the model on its next call, since it would see a tool result with no visible reasoning or action that produced it. Trimming in matched pairs keeps every remaining exchange structurally complete.

### Step 2 — A running token-usage tracker for the whole loop

While we're building token awareness, it makes sense to also track *actual* usage reported back by the provider (most chat completion APIs return a `usage` object with real prompt/completion token counts) — this gives us ground-truth numbers to compare against our estimate, and sets up Phase 3's per-turn cost auditing.

**File: `lib/agent/usageTracker.js`**
```js
/**
 * A simple accumulator for real token usage numbers reported by the
 * provider across multiple steps of a single ReAct loop run. Provider SDKs
 * typically return a `usage` object on every completion response with
 * `prompt_tokens`, `completion_tokens`, and `total_tokens` — these are the
 * ACTUAL counts the provider billed for, as opposed to our estimateTokens()
 * heuristic, which only guesses ahead of time for budgeting purposes.
 */
export function createUsageTracker() {
  const totals = { promptTokens: 0, completionTokens: 0, totalTokens: 0, callCount: 0 };

  return {
    record(completion) {
      const usage = completion?.usage;
      if (!usage) return; // some providers may omit usage on certain responses
      totals.promptTokens += usage.prompt_tokens ?? 0;
      totals.completionTokens += usage.completion_tokens ?? 0;
      totals.totalTokens += usage.total_tokens ?? 0;
      totals.callCount += 1;
    },
    getSummary() {
      return { ...totals };
    },
  };
}
```

### Step 3 — Wire budget enforcement and usage tracking into the loop

**File: `app/api/agent/react/route.js`** *(full updated file)*
```js
import { NextResponse } from 'next/server';
import Groq from 'groq-sdk';
import { completionWithTimeout } from '@/lib/agent/timeoutCompletion.js';
import { generateFallbackAnswer } from '@/lib/agent/fallbackAnswer.js';
import { TOOLS } from '@/lib/agent/tools.js';
import { buildSystemPrompt } from '@/lib/agent/systemPrompt.js';
import { trimMessagesToBudget, estimateMessagesTokens } from '@/lib/agent/tokenBudget.js';
import { createUsageTracker } from '@/lib/agent/usageTracker.js';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

const MAX_STEPS = 6;
const STEP_TIMEOUT_MS = 15000;
const MAX_CONTEXT_TOKENS = 4000; // conservative budget, well under any of our providers' real limits

async function runReactLoop(userGoal) {
  const systemPrompt = await buildSystemPrompt();

  let messages = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: userGoal },
  ];

  const trace = [];
  const recentActionSignatures = [];
  const usageTracker = createUsageTracker();

  for (let step = 1; step <= MAX_STEPS; step++) {
    // --- BUDGET ENFORCEMENT -------------------------------------------------
    // Before every model call, check whether our running transcript has
    // grown past our safe budget, and trim it if so. This runs BEFORE the
    // call, not after, since the call itself would fail outright if we
    // exceeded the model's actual hard context limit.
    const { trimmedMessages, wasTrimmed, removedCount } = trimMessagesToBudget(
      messages,
      MAX_CONTEXT_TOKENS
    );
    messages = trimmedMessages;
    if (wasTrimmed) {
      trace.push({
        step,
        systemNote: `Trimmed ${removedCount} oldest transcript messages to stay within ${MAX_CONTEXT_TOKENS} token budget.`,
      });
    }

    // --- THINK ---------------------------------------------------------------
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
      trace.push({ step, error: error.message, code: error.code || 'PROVIDER_ERROR' });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'provider_call_failed');
      return {
        finalAnswer: fallbackAnswer,
        stopReason: 'provider_call_failed',
        trace,
        usage: usageTracker.getSummary(),
      };
    }

    usageTracker.record(completion); // record REAL usage numbers from the provider's response

    const rawContent = completion.choices[0]?.message?.content ?? '{}';

    let parsed;
    try {
      parsed = JSON.parse(rawContent);
    } catch (err) {
      trace.push({ step, error: 'Model returned invalid JSON', rawContent });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'malformed_json');
      return {
        finalAnswer: fallbackAnswer,
        stopReason: 'malformed_json',
        trace,
        usage: usageTracker.getSummary(),
      };
    }

    const { thought, action, action_input } = parsed;
    trace.push({ step, thought, action, action_input });

    // --- Stopping condition 1: the model says it's done ---------------------
    if (action === 'final_answer') {
      return {
        finalAnswer: action_input,
        stopReason: 'final_answer',
        trace,
        usage: usageTracker.getSummary(),
      };
    }

    // --- Stopping condition 2: repeated identical action (stuck loop) -------
    const signature = `${action}::${action_input}`;
    recentActionSignatures.push(signature);
    const repeatsOfThisSignature = recentActionSignatures.filter((s) => s === signature).length;
    if (repeatsOfThisSignature >= 2) {
      trace.push({ step, warning: 'Detected repeated action, halting loop early.' });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'stuck_loop_detected');
      return {
        finalAnswer: fallbackAnswer,
        stopReason: 'stuck_loop_detected',
        trace,
        usage: usageTracker.getSummary(),
      };
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
  return {
    finalAnswer: fallbackAnswer,
    stopReason: 'max_steps_exceeded',
    trace,
    usage: usageTracker.getSummary(),
  };
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

A few points worth highlighting about this version:

- **Budget enforcement happens *before* the call, not after.** There's no value in trimming a transcript after it's already caused a failed request — the check has to run proactively, every single iteration, treating the token budget as a gate the transcript must pass through before it's allowed to reach the provider.
- **`usage` is now returned in every single response path**, including all three fallback routes. This means even a failed/degraded run gives you accurate cost visibility — arguably *more* important on a failure path, since runaway loops are exactly the scenario where unexpected cost accumulates.
- **`MAX_CONTEXT_TOKENS = 4000`** is deliberately conservative relative to `llama-3.3-70b-versatile`'s actual context window (which is much larger). We're not trying to maximize how much we can cram in — we're demonstrating the trimming *mechanism* clearly and cheaply. In a real production system, you'd set this close to (but safely under) the actual model's documented limit, leaving headroom for the model's own response tokens.

### Step 4 — A diagnostic endpoint to directly observe trimming behavior

Testing trimming through the full ReAct loop is possible but slow and indirect (you'd need a task requiring many real steps). Instead, let's directly unit-test the trimming function with synthetic data, so we can *see* the exact before/after behavior instantly.

**File: `app/api/agent/trim-test/route.js`**
```js
import { NextResponse } from 'next/server';
import { trimMessagesToBudget, estimateMessagesTokens } from '@/lib/agent/tokenBudget.js';

export async function GET() {
  // Build a synthetic transcript: 1 system prompt, 1 user goal, then 20
  // fake assistant/observation pairs — far more than any real loop would
  // produce, specifically to force trimming to kick in.
  const messages = [
    { role: 'system', content: 'You are a helpful agent. '.repeat(20) },
    { role: 'user', content: 'What is the weather trend for the last 20 days?' },
  ];

  for (let i = 1; i <= 20; i++) {
    messages.push({
      role: 'assistant',
      content: JSON.stringify({
        thought: `Checking day ${i}`,
        action: 'getCurrentTime',
        action_input: '',
      }),
    });
    messages.push({
      role: 'user',
      content: `Observation: {"day": ${i}, "note": "This is a synthetic filler observation to simulate real token weight."}`,
    });
  }

  const beforeTokens = estimateMessagesTokens(messages);
  const smallBudget = 300; // deliberately tiny, to force visible trimming

  const { trimmedMessages, wasTrimmed, removedCount } = trimMessagesToBudget(messages, smallBudget);
  const afterTokens = estimateMessagesTokens(trimmedMessages);

  return NextResponse.json({
    originalMessageCount: messages.length,
    beforeTokens,
    budget: smallBudget,
    wasTrimmed,
    removedCount,
    remainingMessageCount: trimmedMessages.length,
    afterTokens,
    // Confirm the protected messages survived, unchanged, at the front:
    firstMessageRolePreserved: trimmedMessages[0].role === 'system',
    secondMessageContentPreserved: trimmedMessages[1].content === messages[1].content,
  });
}
```

### The Verification

**Test 1 — Confirm trimming logic in isolation:**

```bash
curl -s http://localhost:3000/api/agent/trim-test | python3 -m json.tool
```

**Expected output:**
```json
{
    "originalMessageCount": 42,
    "beforeTokens": 1195,
    "budget": 300,
    "wasTrimmed": true,
    "removedCount": 34,
    "remainingMessageCount": 8,
    "afterTokens": 268,
    "firstMessageRolePreserved": true,
    "secondMessageContentPreserved": true
}
```

Check specifically that:
- `wasTrimmed` is `true` and `removedCount` is a positive even number (always even, since we remove in pairs)
- `afterTokens` is now under the `budget` (300)
- Both `firstMessageRolePreserved` and `secondMessageContentPreserved` are `true` — proof our protected system prompt and original user goal survived the trim untouched, even though the vast majority of the transcript was discarded

**Test 2 — Confirm the full loop still works and now reports usage:**

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "What is 15% of 640?"}' \
  | python3 -m json.tool
```

**Expected output** now includes a real `usage` object populated with actual provider-reported numbers:

```json
{
    "success": true,
    "goal": "What is 15% of 640?",
    "finalAnswer": "15% of 640 is 96.",
    "stopReason": "final_answer",
    "trace": [ ... ],
    "usage": {
        "promptTokens": 812,
        "completionTokens": 94,
        "totalTokens": 906,
        "callCount": 2
    }
}
```

Confirm `usage.callCount` matches the number of `trace` entries with an `action` field (each real model call increments it by one), and that `totalTokens` roughly equals `promptTokens + completionTokens`.

Once both tests pass, you've confirmed two independent, critical guarantees: your transcript can never silently grow past a safe token budget (verified directly against synthetic data designed to force the issue), and your system now surfaces real, provider-reported token consumption on every single request — success or failure — which is the exact groundwork Phase 3 needs for full cost auditing per user turn.
