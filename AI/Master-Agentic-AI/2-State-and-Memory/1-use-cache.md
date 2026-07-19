# Phase 2: State Persistence, Caching & Context Windows

## Phase 2, Part 1: Isolating Expensive System Prompt Construction with `use cache`

### The Target

Right now, our `SYSTEM_PROMPT` in `app/api/agent/react/route.js` is a hardcoded string constant. That was fine for Phase 1, but starting in Phase 3 through 6, this prompt is going to grow substantially — it will need to describe a larger tool registry, embed guardrail rules, and include retrieval instructions. In a real system, building that prompt might involve reading configuration files, formatting metadata from a database, or computing token counts — genuinely expensive work that shouldn't be redone from scratch on every single request.

In this part, we extract prompt construction into its own module, make it deliberately more expensive (to simulate a real-world config-heavy system prompt), and then use Next.js 16's **`use cache`** directive to ensure that expensive work only actually runs occasionally — not on every request — while still allowing us to eventually invalidate and refresh it on demand.

### The Concept

Imagine a law office that has one master reference document — a 200-page compliance manual — that every new case needs to reference. Photocopying that entire manual from scratch, page by page, every single time a paralegal needs it would be absurd. Instead, the office makes copies once, keeps a stack of them ready in a supply closet, and only reprints the whole stack when the manual is actually revised.

That's exactly what `use cache` does for a function's return value in Next.js. You mark a function (or a whole file) with the `"use cache"` directive, and Next.js will compute it once, store the result, and hand back the *stored* result to subsequent callers — completely skipping re-execution — until either a time-based **revalidation window** passes, or you explicitly invalidate it by tag. This is distinct from caching a raw HTTP response; we're caching the *output of an arbitrary async function*, which is exactly what a "build my system prompt" operation is.

This matters enormously in a serverless agentic system specifically because of how our ReAct loop works: **every single step of the loop calls the model again, and every one of those calls needs the system prompt.** Without caching, a 6-step reasoning loop would rebuild an identical, unchanging string six separate times in a single request — pure wasted CPU. Multiply that across thousands of concurrent serverless invocations, and it's a meaningful, avoidable cost.

### The Implementation

#### Step 1 — Enable the `use cache` feature in your Next.js config

`use cache` is a directive that needs to be explicitly enabled in your project configuration before Next.js will honor it.

**File: `next.config.mjs`**
```js
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    // Enables the "use cache" directive throughout the app.
    // Without this flag, "use cache" is silently ignored and functions
    // run fresh on every single call — exactly like before this change.
    useCache: true,
  },
};

export default nextConfig;
```

> **Why is this still under `experimental`?** Next.js ships major new caching primitives behind an experimental flag first, so that projects can opt in deliberately rather than having caching behavior change underneath them automatically during a routine version upgrade. As this feature graduates to stable in future Next.js releases, this flag requirement may be lifted — always check the official Next.js caching documentation for the version you're running.

Restart your dev server after saving this file — configuration changes in `next.config.mjs` are only read at server startup:

```bash
# stop the running server (Ctrl+C in that terminal), then:
npm run dev
```

#### Step 2 — Extract the tool registry into its own reusable module

Before we build the cached prompt, we need the tool metadata living somewhere both the prompt builder and the route handler can import from, rather than duplicated inline.

**File: `lib/agent/tools.js`**
```js
// A single, shared source of truth for every tool the agent can call.
// Both the system-prompt builder and the ReAct loop import from here,
// so a new tool only ever needs to be registered in ONE place.

export const TOOLS = {
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

// Metadata describing each tool in a structured way (rather than a single
// hardcoded string), so the prompt builder can format it programmatically —
// this is what makes the "expensive construction" step realistic and also
// makes it trivially extensible: adding a new tool later means adding one
// object to this array, not hand-editing a prompt string somewhere else.
export const TOOL_METADATA = [
  {
    name: 'calculator',
    description: 'Evaluates a basic arithmetic expression.',
    inputHint: 'A string like "42 * 17"',
  },
  {
    name: 'getCurrentTime',
    description: 'Returns the current UTC timestamp.',
    inputHint: 'An empty string',
  },
];
```

#### Step 3 — Build the (deliberately expensive) cached system prompt

**File: `lib/agent/systemPrompt.js`**
```js
import { TOOL_METADATA } from './tools.js';

/**
 * Simulates realistic "expensive" prompt construction work — in a real
 * system this might be reading multiple config files, querying a database
 * for tenant-specific rules, or computing embeddings for few-shot examples.
 * We simulate that cost here with an artificial delay and some non-trivial
 * string formatting, so the caching behavior we verify is meaningful.
 */
async function simulateExpensiveConfigLookup() {
  // Artificial 400ms delay stands in for "reading config from disk / DB".
  await new Promise((resolve) => setTimeout(resolve, 400));
  return {
    agentPersona: 'a careful, methodical reasoning agent',
    orgName: 'Acme Corp',
    complianceFooter: 'All responses must remain professional and factual.',
  };
}

/**
 * Builds the full system prompt. Marked with "use cache" so Next.js computes
 * this ONCE and reuses the stored result across calls, instead of re-running
 * the (simulated) expensive lookup and string formatting on every request.
 */
export async function buildSystemPrompt() {
  'use cache'; // Directive must be the first line inside the function body.

  const config = await simulateExpensiveConfigLookup();

  const toolDescriptions = TOOL_METADATA.map(
    (tool) => `- ${tool.name}: ${tool.description} action_input must be: ${tool.inputHint}.`
  ).join('\n');

  return `
You are ${config.agentPersona}, working on behalf of ${config.orgName}.

On EVERY turn, you must respond with a single JSON object and nothing else —
no markdown, no commentary outside the JSON. The object must have this exact shape:

{
  "thought": "<your brief reasoning about what to do next>",
  "action": "<one of: ${TOOL_METADATA.map((t) => t.name).join(', ')}, final_answer>",
  "action_input": "<the input for the chosen action, or your answer text if action is final_answer>"
}

Available tools:
${toolDescriptions}

Rules:
- Choose exactly ONE action per turn.
- Only use "final_answer" once you have all the information you need.
- Never invent tool results — always wait for the real observation before continuing.
- Keep "thought" short (one sentence).
- ${config.complianceFooter}
  `.trim();
}
```

> **Why `'use cache'` as the very first line, inside the function?** Next.js's caching directives follow the same convention as `'use client'`/`'use server'` — they must appear as the first statement in the scope they apply to. Placed here, it tells Next.js: "the return value of this specific async function is cacheable — compute it once, store the result, and serve that stored result to future callers instead of re-running this function body," until the cache entry expires or is explicitly invalidated.

#### Step 4 — Update the ReAct route to use the cached prompt builder

**File: `app/api/agent/react/route.js`** *(relevant changes only — replace the top portion of the file)*
```js
import { NextResponse } from 'next/server';
import Groq from 'groq-sdk';
import { completionWithTimeout } from '@/lib/agent/timeoutCompletion.js';
import { generateFallbackAnswer } from '@/lib/agent/fallbackAnswer.js';
import { TOOLS } from '@/lib/agent/tools.js';
import { buildSystemPrompt } from '@/lib/agent/systemPrompt.js';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

const MAX_STEPS = 6;
const STEP_TIMEOUT_MS = 15000;

async function runReactLoop(userGoal) {
  // The cached system prompt is awaited here. On the FIRST call after a
  // server start (or cache invalidation), this triggers the ~400ms
  // simulated lookup. Every call after that returns instantly from cache.
  const systemPrompt = await buildSystemPrompt();

  const messages = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: userGoal },
  ];

  const trace = [];
  const recentActionSignatures = [];

  for (let step = 1; step <= MAX_STEPS; step++) {
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

    if (action === 'final_answer') {
      return { finalAnswer: action_input, stopReason: 'final_answer', trace };
    }

    const signature = `${action}::${action_input}`;
    recentActionSignatures.push(signature);
    const repeatsOfThisSignature = recentActionSignatures.filter((s) => s === signature).length;
    if (repeatsOfThisSignature >= 2) {
      trace.push({ step, warning: 'Detected repeated action, halting loop early.' });
      const fallbackAnswer = await generateFallbackAnswer(groq, messages, 'stuck_loop_detected');
      return { finalAnswer: fallbackAnswer, stopReason: 'stuck_loop_detected', trace };
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

Notice we also removed the duplicated `TOOLS` object and `SYSTEM_PROMPT` constant from this file entirely — they now live in `lib/agent/tools.js` and `lib/agent/systemPrompt.js` respectively, which the route imports. This is a direct application of the "single source of truth" principle: the tool registry no longer needs to be kept in sync by hand across multiple files.

#### Step 5 — A small diagnostic endpoint to observe the cache in action

To *see* caching behavior rather than just trust it exists, add a lightweight timing endpoint.

**File: `app/api/agent/prompt-timing/route.js`**
```js
import { NextResponse } from 'next/server';
import { buildSystemPrompt } from '@/lib/agent/systemPrompt.js';

export async function GET() {
  const startedAt = Date.now();
  const prompt = await buildSystemPrompt();
  const elapsedMs = Date.now() - startedAt;

  return NextResponse.json({
    elapsedMs,
    promptLength: prompt.length,
    promptPreview: prompt.slice(0, 80) + '...',
  });
}
```

### The Verification

With the dev server restarted (required after the `next.config.mjs` change), call the timing endpoint **twice in a row**:

```bash
curl -s http://localhost:3000/api/agent/prompt-timing | python3 -m json.tool
curl -s http://localhost:3000/api/agent/prompt-timing | python3 -m json.tool
```

**Expected behavior:**

- **First call:** `elapsedMs` should be roughly **400ms or more** (dominated by our simulated expensive lookup).
- **Second call:** `elapsedMs` should drop to a **very small number** (single-digit to low double-digit milliseconds) — proof that Next.js served the cached result instead of re-running `simulateExpensiveConfigLookup()`.

Example expected output sequence:
```json
{
    "elapsedMs": 406,
    "promptLength": 812,
    "promptPreview": "You are a careful, methodical reasoning agent, working on behalf of Acme Corp...."
}
```
```json
{
    "elapsedMs": 1,
    "promptLength": 812,
    "promptPreview": "You are a careful, methodical reasoning agent, working on behalf of Acme Corp...."
}
```

Finally, confirm the full ReAct loop still functions correctly end-to-end with the refactored, cached prompt:

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "What is 12 squared?"}' \
  | python3 -m json.tool
```

You should get a clean `"stopReason": "final_answer"` response with the correct value (`144`), confirming the extracted, cached prompt builder integrates correctly with the loop from Phase 1.

With both checks passing, you've confirmed two things: the `use cache` directive is correctly enabled and functioning (verified by the dramatic timing difference between calls), and the refactor into shared `lib/agent/` modules didn't break any existing behavior. This sets up the shared module structure — `tools.js`, `systemPrompt.js` — that every subsequent phase will continue to build on.

