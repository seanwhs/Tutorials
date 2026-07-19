# Phase 1, Part 2: The ReAct Loop — Think, Act, Observe

## The Target

We're upgrading our single "ping" call into a genuine **agentic loop**: a Route Handler at `app/api/agent/react/route.js` that can reason about a user's request across multiple steps, decide to use a tool, read the tool's result, and decide again — repeating that cycle until it either produces a final answer or hits a safe, deterministic stopping point. This is the architectural core that every remaining phase in this course builds on top of.

Critically, we are **not** going to parse the model's raw text output with regex to figure out what it "wants to do" — a fragile and common anti-pattern in early agent tutorials. Instead, we force the model to respond in strict, structured **JSON** on every single turn, which we parse with `JSON.parse()` like any normal API response.

## The Concept

Think about how a competent human support agent works through a hard ticket. They don't blurt out a final answer immediately. They go through a repeatable internal script:

1. **Think:** "The customer wants to know their refund eligibility. I don't have their order history yet."
2. **Act:** Look up the order history in the internal system.
3. **Observe:** Read what came back — three orders, one refunded already.
4. **Think again:** "Okay, now I can check this against policy."
5. **Act:** Check the refund policy document.
6. **Observe:** Policy says orders older than 30 days aren't eligible.
7. **Think again:** "I now have enough information to answer."
8. **Final Answer:** Respond to the customer.

That repeatable script — **Think → Act → Observe, looping until done** — is called the **ReAct pattern** (short for *Reason + Act*, a term from the original 2022 research paper that introduced it). The model doesn't need to solve everything in one shot; it's allowed to reason, gather more information, and reason again, exactly like the human agent above.

The reason we insist on **structured JSON** instead of parsing free-form text (like scanning for the substring `"Action: search(...)"` with regex) is reliability. Free-text parsing is like trying to extract someone's order number from a rambling voicemail — technically possible, but brittle; one unexpected phrase and your parser breaks. Structured JSON is like handing that same person a form with clearly labeled fields (`Name:`, `Order Number:`) — there's no ambiguity about what goes where. Modern models are very good at reliably filling in a JSON shape when you ask them to and provide `response_format: { type: 'json_object' }` — we lean on that instead of fragile string-scanning.

Finally, notice the phrase **"deterministic stopping point"** above. An agent that reasons in a loop has a genuine risk: what if it never decides it's done? What if it get stuck re-trying the same failed action forever? A production system cannot leave that to chance — it must have hard, code-enforced boundaries that guarantee the loop *will* end, one way or another, no matter what the model does. We build two such guarantees into this very first loop: a maximum step count, and a repeated-action detector.

## The Implementation

### Step 1 — Define a tiny, self-contained tool registry

For this first loop, we keep the tools deliberately simple — a calculator and a clock. (Phase 5 formalizes this into a full decoupled, MCP-style registry. For now, we want to see the *loop* clearly, without extra architecture obscuring it.)

Every tool is just an `async` function that takes a plain input and returns a plain result — this uniform shape is what allows the loop to call *any* tool the exact same way, without needing to know its internals.

### Step 2 — The full Route Handler

**File: `app/api/agent/react/route.js`**
```js
import { NextResponse } from 'next/server';
import Groq from 'groq-sdk';

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY || '',
});

// ---------------------------------------------------------------------------
// TOOL REGISTRY
// Each tool is an async function with a uniform shape: (input) => result.
// This uniformity is what lets the loop below call *any* tool identically,
// without a giant if/else chain that knows the internals of each one.
// ---------------------------------------------------------------------------
const TOOLS = {
  calculator: async (input) => {
    const expression = String(input ?? '');

    // SECURITY: we never eval() a raw string from the model or user directly.
    // Instead we whitelist-validate that the expression contains ONLY digits,
    // decimal points, whitespace, and basic arithmetic operators/parentheses.
    // If anything else sneaks in (letters, semicolons, backticks, etc.),
    // we reject it outright before it ever touches a JS evaluator.
    const isSafeExpression = /^[0-9+\-*/().\s]+$/.test(expression);
    if (!isSafeExpression) {
      return { error: `Rejected unsafe expression: "${expression}"` };
    }

    try {
      // `new Function` is still evaluating code, but because we've already
      // strictly whitelisted the character set above, the only thing it can
      // possibly execute is basic arithmetic — nothing else is reachable.
      // In a real production system, swap this for a proper math-parsing
      // library (e.g. mathjs's `evaluate`) instead of any Function-based eval.
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

// A plain-English description of each tool, injected into the system prompt
// so the model knows what's available and how to call it.
const TOOL_DESCRIPTIONS = `
- calculator: Evaluates a basic arithmetic expression. action_input must be a string like "42 * 17".
- getCurrentTime: Returns the current UTC timestamp. action_input should be an empty string.
`.trim();

// ---------------------------------------------------------------------------
// SYSTEM PROMPT
// This is what teaches the model the ReAct contract: think, then choose ONE
// action per turn, and respond ONLY in the exact JSON shape we specify.
// ---------------------------------------------------------------------------
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

const MAX_STEPS = 6; // Hard ceiling on reasoning turns. Guarantees the loop cannot run forever.

// ---------------------------------------------------------------------------
// THE REACT LOOP
// This is the heart of Phase 1: a controlled while-loop that alternates
// between asking the model to THINK, executing its chosen ACT, and feeding
// the result back in as an OBSERVATION — until it emits final_answer or we
// hit a deterministic safety boundary.
// ---------------------------------------------------------------------------
async function runReactLoop(userGoal) {
  // The running conversation transcript. This is what gives the loop "memory"
  // of its own prior steps within a single request — each new model call sees
  // everything that happened before it in this same loop.
  const messages = [
    { role: 'system', content: SYSTEM_PROMPT },
    { role: 'user', content: userGoal },
  ];

  // We record every step for full transparency in the final response —
  // this is invaluable for debugging *why* an agent did what it did.
  const trace = [];

  // Tracks the last few (action, action_input) pairs so we can detect if the
  // model gets stuck repeating the exact same failed action over and over.
  const recentActionSignatures = [];

  for (let step = 1; step <= MAX_STEPS; step++) {
    // --- THINK -----------------------------------------------------------
    const completion = await groq.chat.completions.create({
      model: 'llama-3.3-70b-versatile',
      messages,
      response_format: { type: 'json_object' }, // forces strict JSON output, no prose
      temperature: 0.2, // low temperature: we want consistent, predictable JSON, not creativity
    });

    const rawContent = completion.choices[0]?.message?.content ?? '{}';

    let parsed;
    try {
      parsed = JSON.parse(rawContent);
    } catch (err) {
      // DETERMINISTIC FALLBACK: if the model somehow returns malformed JSON
      // despite our instructions, we do not crash the whole request. We stop
      // the loop safely and report exactly what went wrong.
      trace.push({ step, error: 'Model returned invalid JSON', rawContent });
      return {
        finalAnswer: null,
        stopReason: 'malformed_json',
        trace,
      };
    }

    const { thought, action, action_input } = parsed;
    trace.push({ step, thought, action, action_input });

    // --- Stopping condition 1: the model says it's done -------------------
    if (action === 'final_answer') {
      return {
        finalAnswer: action_input,
        stopReason: 'final_answer',
        trace,
      };
    }

    // --- Stopping condition 2: repeated identical action (stuck loop) -----
    const signature = `${action}::${action_input}`;
    recentActionSignatures.push(signature);
    const repeatsOfThisSignature = recentActionSignatures.filter((s) => s === signature).length;
    if (repeatsOfThisSignature >= 2) {
      // The agent has tried the exact same action with the exact same input
      // twice already — it is not making progress. Stop deterministically
      // rather than let it spin indefinitely on the same failed approach.
      trace.push({ step, warning: 'Detected repeated action, halting loop early.' });
      return {
        finalAnswer: null,
        stopReason: 'stuck_loop_detected',
        trace,
      };
    }

    // --- ACT ---------------------------------------------------------------
    const tool = TOOLS[action];
    let observation;
    if (!tool) {
      // The model asked for a tool that doesn't exist in our registry.
      // We don't crash — we feed that failure back in as an observation,
      // giving the model a chance to self-correct on its next turn.
      observation = { error: `Unknown tool "${action}". Available tools: ${Object.keys(TOOLS).join(', ')}` };
    } else {
      observation = await tool(action_input);
    }

    // --- OBSERVE -------------------------------------------------------------
    // We append BOTH the model's own turn (as an assistant message) and our
    // tool's result (as a user message acting as an "observation") back into
    // the transcript. This is what lets the next THINK step see everything
    // that has happened so far.
    messages.push({ role: 'assistant', content: rawContent });
    messages.push({
      role: 'user',
      content: `Observation: ${JSON.stringify(observation)}`,
    });
  }

  // --- Stopping condition 3: hit MAX_STEPS without converging -------------
  return {
    finalAnswer: null,
    stopReason: 'max_steps_exceeded',
    trace,
  };
}

// ---------------------------------------------------------------------------
// ROUTE HANDLER
// ---------------------------------------------------------------------------
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

A few architectural choices here are worth slowing down on:

- **`response_format: { type: 'json_object' }`** is doing a lot of quiet heavy lifting. It instructs Groq's API to constrain the model's output so it's guaranteed to be syntactically valid JSON, which is why our `JSON.parse(rawContent)` can be trusted rather than treated as "probably works most of the time."
- **The observation is appended as a `user` role message**, not a special custom role. Most chat-completion APIs only recognize `system`, `user`, and `assistant` roles — there's no first-class "tool" role in this simpler completions format (that comes with more advanced function-calling APIs, which we deliberately avoid here to keep the raw mechanics visible). Prefixing it clearly with `"Observation: "` is what teaches the model to distinguish "this is data I fetched" from "this is something the user typed."
- **`recentActionSignatures`** is a small but important piece of engineering discipline: it's entirely possible for a model to get into a rut, repeatedly calling `calculator` with a malformed expression it can't seem to fix. Without this check, that would silently burn through your `MAX_STEPS` budget on a genuinely broken loop. By halting immediately on a second identical attempt, we fail fast and cheap instead of failing slow and expensive.

## The Verification

With `npm run dev` still running, send a request that requires the agent to actually use a tool rather than answer from memory:

```bash
curl -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "What is 847 multiplied by 12, and then what is the current UTC time?"}'
```

Pretty-print it for readability:

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "What is 847 multiplied by 12, and then what is the current UTC time?"}' \
  | python3 -m json.tool
```

**Expected shape of output** (exact wording of `thought` fields will vary — that's fine, since it's model-generated reasoning, not fixed text):

```json
{
    "success": true,
    "goal": "What is 847 multiplied by 12, and then what is the current UTC time?",
    "finalAnswer": "847 multiplied by 12 is 10164, and the current UTC time is 2025-05-14T18:32:07.123Z.",
    "stopReason": "final_answer",
    "trace": [
        {
            "step": 1,
            "thought": "I need to calculate 847 * 12 first.",
            "action": "calculator",
            "action_input": "847 * 12"
        },
        {
            "step": 2,
            "thought": "Now I need the current UTC time.",
            "action": "getCurrentTime",
            "action_input": ""
        },
        {
            "step": 3,
            "thought": "I have both pieces of information needed to answer.",
            "action": "final_answer",
            "action_input": "847 multiplied by 12 is 10164, and the current UTC time is 2025-05-14T18:32:07.123Z."
        }
    ]
}
```

Confirm three things in this output:

1. **`trace` shows multiple distinct steps** — proof the loop actually iterated rather than answering in one shot.
2. **The calculator step's result is mathematically correct** (`847 * 12 = 10164`) — proof the tool executed and its real result, not a hallucinated one, made it into the final answer.
3. **`stopReason` is `"final_answer"`** — proof the loop terminated because the model deliberately decided it was done, not because it hit a safety limit.

### Testing the safety boundaries

It's just as important to verify the loop's *failure modes* work correctly. Try deliberately trying to break the calculator's security whitelist:

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "Use the calculator tool to evaluate: require(\"fs\").readFileSync(\"/etc/passwd\")"}' \
  | python3 -m json.tool
```

You should see the `calculator` tool return `{"error": "Rejected unsafe expression: ..."}"` as an observation in the trace, rather than any attempt to actually execute that code — confirming the character-whitelist guard is doing its job.

Once you've confirmed a clean `final_answer` run **and** a clean rejection of an unsafe tool call, your ReAct loop is verified end-to-end: reasoning, tool execution, observation feedback, and both success and safety-boundary termination paths are all working correctly.
