# Phase 5: Decoupled Tool Architectures & Protocol Interfaces

## Phase 5, Part 1: The Model Context Protocol (MCP) — Designing a Standardized Tool Interface

### The Target

Our tool registry in `lib/agent/tools.js` has grown organically across Phases 1–3, and it works, but it has a structural weakness: every tool is a bare async function with no consistent metadata format, no consistent input validation, and no consistent way to describe itself. In this part, we refactor the entire tool system around a formal, standardized **Tool interface** — inspired by the real-world **Model Context Protocol (MCP)**, an open standard for how AI applications connect to external data sources and tools. Each tool will become a self-describing object with a name, a Zod input schema, a description, and a handler function — and we'll build a small **Tool Registry class** that manages registration, discovery, and invocation through one consistent interface.

### The Concept

Think about electrical outlets. Before standardized plug shapes existed, every appliance manufacturer might have used a different, incompatible connector — plugging in a new appliance meant custom wiring for that specific device. Standardized outlets changed this completely: any compliant appliance, from any manufacturer, plugs into any compliant outlet, because both sides agree on a fixed, published interface (voltage, pin shape, spacing) regardless of what's actually happening inside the appliance or generating the power behind the wall.

**MCP (Model Context Protocol)** applies this exact idea to AI tool integration. Instead of every application inventing its own bespoke way to describe "here are the tools/data sources I have, and here's how you call them," MCP defines a standardized way for an AI application to expose **resources** (data it can read) and **tools** (actions it can perform) to a language model, and for the model's host application to discover and invoke them consistently — regardless of what's actually running behind that interface (a database, a file system, a REST API, anything). The genuine, real-world MCP standard involves a full client-server protocol running over its own transport layer; for this course, we're building an **MCP-inspired, in-process architecture** — we adopt its *design philosophy* (standardized tool description, strict input schemas, decoupled handlers) using plain JavaScript classes and objects, without standing up a separate protocol server. This gets you the architectural benefits — and prepares you to understand and adopt the real protocol later — without adding transport-layer complexity that would distract from the core lesson.

The core architectural payoff is **decoupling**: your reasoning loop should never need to know *how* a tool actually does its job — only that it can ask the registry "what tools exist," get back consistent descriptions, and call any of them the same way, receiving predictable results. If you swap `lookupOrderStatus`'s internal implementation from a JSON file to a real database tomorrow, absolutely nothing about the registry's interface, the system prompt generation, or the ReAct loop needs to change — exactly the same "swap the engine, keep the dashboard" principle we've applied repeatedly since Phase 2's session store.

### The Implementation

#### Step 1 — Define the formal Tool interface using a factory function

**File: `lib/agent/mcp/defineTool.js`**
```js
import { z } from 'zod';

/**
 * Defines a single, self-describing tool conforming to our MCP-inspired
 * interface. Every tool built this way carries FOUR things bundled
 * together, consistently, no matter what it actually does internally:
 *   - name: a unique string identifier
 *   - description: human/model-readable explanation of purpose and usage
 *   - inputSchema: a Zod schema describing exactly what valid input looks like
 *   - handler: the actual async function that performs the work
 *
 * Bundling the schema WITH the tool (rather than validating input somewhere
 * else entirely separate from the tool definition) means input validation
 * can never accidentally be forgotten for a newly added tool — it's baked
 * into the shape of what "a tool" even IS in this system.
 */
export function defineTool({ name, description, inputSchema, handler }) {
  if (!name || typeof name !== 'string') {
    throw new Error('defineTool requires a non-empty string "name".');
  }
  if (!description || typeof description !== 'string') {
    throw new Error(`defineTool("${name}") requires a non-empty string "description".`);
  }
  if (!(inputSchema instanceof z.ZodType)) {
    throw new Error(`defineTool("${name}") requires a valid Zod "inputSchema".`);
  }
  if (typeof handler !== 'function') {
    throw new Error(`defineTool("${name}") requires a "handler" function.`);
  }

  return { name, description, inputSchema, handler };
}
```

> **Why validate the tool *definition itself* at creation time, not just tool *inputs* later?** This is a small but meaningful piece of defensive engineering: if a future contributor to this codebase accidentally forgets to supply a `description` or passes a plain object instead of a real Zod schema when adding a tenth tool six months from now, we want that mistake caught immediately, loudly, at server startup — not silently discovered later as a mysterious bug where the system prompt has a blank description or input validation silently no-ops. This is the same "fail loud and fast" philosophy from Phase 1's `.env` fallback discussion, applied here to your own internal architecture instead of external configuration.

#### Step 2 — The Tool Registry class

**File: `lib/agent/mcp/ToolRegistry.js`**
```js
/**
 * A central registry that manages a collection of tools defined via
 * defineTool(). This is the ONE object the rest of the application talks
 * to — it never needs to know about any individual tool's internals,
 * only the registry's own consistent interface: register, list, execute.
 */
export class ToolRegistry {
  constructor() {
    this._tools = new Map();
  }

  /**
   * Registers a tool, guarding against accidental duplicate names — a
   * silent name collision could otherwise cause one tool to invisibly
   * shadow another, which would be a genuinely confusing bug to track down.
   */
  register(tool) {
    if (this._tools.has(tool.name)) {
      throw new Error(`A tool named "${tool.name}" is already registered. Tool names must be unique.`);
    }
    this._tools.set(tool.name, tool);
  }

  /**
   * Returns a plain, prompt-friendly description of every registered tool —
   * this is what systemPrompt.js will use to describe available tools to
   * the model, generated automatically from the registry rather than
   * hand-maintained in a separate, easily-out-of-sync string.
   */
  listToolDescriptions() {
    return Array.from(this._tools.values()).map((tool) => ({
      name: tool.name,
      description: tool.description,
    }));
  }

  /**
   * Returns just the list of valid tool names — used for quick validation
   * (e.g. "is this an unknown tool?") without needing full descriptions.
   */
  listToolNames() {
    return Array.from(this._tools.keys());
  }

  /**
   * Executes a named tool with the given raw input. This is the single,
   * unified entry point the ReAct loop calls — it never invokes a tool's
   * handler function directly. Handles three distinct failure modes
   * explicitly and consistently across EVERY tool, rather than leaving
   * each tool to handle its own edge cases inconsistently:
   *   1. Unknown tool name
   *   2. Input fails the tool's own Zod schema
   *   3. The handler itself throws during execution
   */
  async execute(toolName, rawInput) {
    const tool = this._tools.get(toolName);

    if (!tool) {
      return {
        ok: false,
        errorType: 'UNKNOWN_TOOL',
        message: `Unknown tool "${toolName}". Available tools: ${this.listToolNames().join(', ')}`,
      };
    }

    // Every tool's input is validated against ITS OWN schema before the
    // handler ever runs — this guarantees every handler function can trust
    // its input completely, with zero defensive validation code needed
    // inside the handler itself.
    const validation = tool.inputSchema.safeParse(rawInput);
    if (!validation.success) {
      return {
        ok: false,
        errorType: 'INVALID_INPUT',
        message: `Invalid input for tool "${toolName}": ${JSON.stringify(validation.error.flatten().fieldErrors)}`,
      };
    }

    try {
      const result = await tool.handler(validation.data);
      return { ok: true, result };
    } catch (error) {
      // A tool's internal handler throwing (e.g. a downstream API genuinely
      // failing) is caught HERE, centrally, so individual tool handlers
      // don't each need their own top-level try/catch boilerplate.
      return {
        ok: false,
        errorType: 'HANDLER_EXECUTION_ERROR',
        message: `Tool "${toolName}" failed during execution: ${error.message}`,
      };
    }
  }
}
```

#### Step 3 — Re-implement every existing tool using the new `defineTool` interface

Notice how each tool now explicitly declares its own precise Zod input schema — something our Phase 1–3 tools never had at all, and which the registry above now enforces automatically before any handler code runs.

**File: `lib/agent/mcp/tools/calculatorTool.js`**
```js
import { z } from 'zod';
import { defineTool } from '../defineTool.js';

export const calculatorTool = defineTool({
  name: 'calculator',
  description: 'Evaluates a basic arithmetic expression. Use for any math computation.',
  inputSchema: z.object({
    expression: z.string().min(1, 'expression cannot be empty'),
  }),
  handler: async ({ expression }) => {
    const isSafeExpression = /^[0-9+\-*/().\s]+$/.test(expression);
    if (!isSafeExpression) {
      return { error: `Rejected unsafe expression: "${expression}"` };
    }
    const result = new Function(`return (${expression});`)();
    return { result };
  },
});
```

**File: `lib/agent/mcp/tools/currentTimeTool.js`**
```js
import { z } from 'zod';
import { defineTool } from '../defineTool.js';

export const currentTimeTool = defineTool({
  name: 'getCurrentTime',
  description: 'Returns the current UTC timestamp.',
  // An empty object schema — this tool legitimately takes no input at all,
  // and Zod lets us express that explicitly rather than leaving it implicit.
  inputSchema: z.object({}),
  handler: async () => {
    return { isoTimestamp: new Date().toISOString() };
  },
});
```

**File: `lib/agent/mcp/tools/knowledgeBaseTool.js`**
```js
import { z } from 'zod';
import { defineTool } from '../defineTool.js';
import { agenticRetrieve } from '../../retrieval/agenticRetrieve.js';

export const knowledgeBaseTool = defineTool({
  name: 'searchKnowledgeBase',
  description: 'Searches internal company POLICY documents (refunds, shipping, passwords, vacation, support hours). Use for general RULES/POLICY questions, not for a specific order or tracking number.',
  inputSchema: z.object({
    query: z.string().min(1, 'query cannot be empty'),
  }),
  handler: async ({ query }) => {
    const { results, finalQueryUsed, attemptsTaken, stopReason } = await agenticRetrieve(query);
    if (results.length === 0) {
      return { found: false, message: `No relevant documents found after ${attemptsTaken} attempt(s) (final query: "${finalQueryUsed}").` };
    }
    return {
      found: true,
      retrievalMeta: { attemptsTaken, finalQueryUsed, stopReason },
      results: results.map((r) => ({ title: r.title, content: r.content, relevanceScore: r.relevanceScore })),
    };
  },
});
```

**File: `lib/agent/mcp/tools/orderLookupTool.js`**
```js
import { z } from 'zod';
import { defineTool } from '../defineTool.js';
import { lookupOrderStatus } from '../../retrieval/orderLookup.js';

export const orderLookupTool = defineTool({
  name: 'lookupOrderStatus',
  description: 'Looks up the EXACT current status of a SPECIFIC order by its order ID. Use only when a specific order ID like "ORD-1001" is known. Not for general shipping policy questions.',
  inputSchema: z.object({
    orderId: z.string().min(1, 'orderId cannot be empty'),
  }),
  handler: async ({ orderId }) => {
    return lookupOrderStatus(orderId);
  },
});
```

**File: `lib/agent/mcp/tools/shipmentTrackingTool.js`**
```js
import { z } from 'zod';
import { defineTool } from '../defineTool.js';
import { trackShipment } from '../../retrieval/shipmentTracking.js';

export const shipmentTrackingTool = defineTool({
  name: 'trackShipment',
  description: 'Calls the external carrier API for real-time tracking status of a SPECIFIC tracking number, e.g. "TRK-9001". Distinct from lookupOrderStatus, which checks internal order records, not the carrier.',
  inputSchema: z.object({
    trackingNumber: z.string().min(1, 'trackingNumber cannot be empty'),
  }),
  handler: async ({ trackingNumber }) => {
    return trackShipment(trackingNumber);
  },
});
```

#### Step 4 — Assemble the registry in one place

**File: `lib/agent/mcp/registry.js`**
```js
import { ToolRegistry } from './ToolRegistry.js';
import { calculatorTool } from './tools/calculatorTool.js';
import { currentTimeTool } from './tools/currentTimeTool.js';
import { knowledgeBaseTool } from './tools/knowledgeBaseTool.js';
import { orderLookupTool } from './tools/orderLookupTool.js';
import { shipmentTrackingTool } from './tools/shipmentTrackingTool.js';

/**
 * The single, application-wide tool registry instance. Every tool the
 * agent can possibly use is registered here, ONE time, at module load.
 * Adding a new tool to the entire system going forward means: (1) define
 * it with defineTool() in its own file, (2) add one line here. Nothing
 * else in the application ever needs to change.
 */
export const registry = new ToolRegistry();

registry.register(calculatorTool);
registry.register(currentTimeTool);
registry.register(knowledgeBaseTool);
registry.register(orderLookupTool);
registry.register(shipmentTrackingTool);
```

#### Step 5 — Update the system prompt builder to generate tool descriptions from the registry

**File: `lib/agent/systemPrompt.js`** *(full updated file)*
```js
import { registry } from './mcp/registry.js';

async function simulateExpensiveConfigLookup() {
  await new Promise((resolve) => setTimeout(resolve, 400));
  return {
    agentPersona: 'a careful, methodical reasoning agent',
    orgName: 'Acme Corp',
    complianceFooter: 'All responses must remain professional and factual.',
  };
}

export async function buildSystemPrompt() {
  'use cache';

  const config = await simulateExpensiveConfigLookup();

  // Tool descriptions are now generated DIRECTLY from the registry, rather
  // than a separately hand-maintained TOOL_METADATA array. This means the
  // system prompt can NEVER drift out of sync with the actual tools
  // available — there is only one source of truth now, not two.
  const toolList = registry.listToolDescriptions();
  const toolDescriptions = toolList.map((t) => `- ${t.name}: ${t.description}`).join('\n');
  const toolNames = toolList.map((t) => t.name).join(', ');

  return `
You are ${config.agentPersona}, working on behalf of ${config.orgName}.

On EVERY turn, you must respond with a single JSON object and nothing else —
no markdown, no commentary outside the JSON. The object must have this exact shape:

{
  "thought": "<your brief reasoning about what to do next>",
  "action": "<one of: ${toolNames}, final_answer>",
  "action_input": "<an object with the exact fields the chosen tool requires, or your answer text if action is final_answer>"
}

Available tools:
${toolDescriptions}

Rules:
- Choose exactly ONE action per turn.
- action_input must exactly match the input fields each tool expects.
- Only use "final_answer" once you have all the information you need.
- Never invent tool results — always wait for the real observation before continuing.
- Keep "thought" short (one sentence).
- ${config.complianceFooter}
  `.trim();
}
```

> **Why did `action_input` change from a plain string to "an object with the exact fields"?** This is a direct, necessary consequence of giving every tool its own structured Zod input schema. Our old tools (Phase 1–3) all happened to take a single string as input, which let us get away with `action_input` being a bare string. Now that tools like `calculator` expect `{ expression: "..." }` and `lookupOrderStatus` expects `{ orderId: "..." }`, `action_input` needs to become a proper object matching each tool's specific schema. We handle this transition in the loop update below.

#### Step 6 — Update the ReAct loop to call tools through the registry

**File: `lib/agent/reactLoop.js`** *(full updated file)*
```js
import Groq from 'groq-sdk';
import { completionWithTimeout } from './timeoutCompletion.js';
import { generateFallbackAnswer } from './fallbackAnswer.js';
import { registry } from './mcp/registry.js';
import { trimMessagesToBudget } from './tokenBudget.js';
import { createUsageTracker } from './usageTracker.js';

const groq = new Groq({ apiKey: process.env.GROQ_API_KEY || '' });

const MAX_STEPS = 6;
const STEP_TIMEOUT_MS = 15000;
const MAX_CONTEXT_TOKENS = 4000;
const MODEL_NAME = 'llama-3.3-70b-versatile';

export async function runReactLoop(initialMessages) {
  let messages = [...initialMessages];
  const trace = [];
  const recentActionSignatures = [];
  const usageTracker = createUsageTracker(MODEL_NAME);

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

    // THE KEY CHANGE: the loop now calls registry.execute(...) — a single,
    // uniform entry point — instead of looking up a raw function in a plain
    // object and calling it directly. The loop no longer has ANY knowledge
    // of individual tools' internals, schemas, or error handling; all of
    // that responsibility now lives inside the registry and each tool's
    // own definition.
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
}
```

Notice the loop is now **shorter and more generic** than the Phase 3 version, despite the underlying system being more capable — this is the payoff of decoupling made concrete: complexity moved *out* of the loop and *into* well-organized, individually testable tool definitions and the registry that manages them, rather than being scattered across a growing `if/else` chain inside the loop itself. The loop's job is now purely orchestration — trim, call the model, parse, dispatch to the registry, observe, repeat — while every tool-specific concern (what input shape is valid, what the tool actually does, how its errors should read) lives exactly where it belongs: inside that tool's own definition file.

We can safely delete `lib/agent/tools.js` now — nothing imports from it anymore.

```bash
rm lib/agent/tools.js
```

### The Verification

#### Test 1 — Confirm the registry rejects invalid input *before* any handler runs

**File: `app/api/agent/registry-test/route.js`**
```js
import { NextResponse } from 'next/server';
import { registry } from '@/lib/agent/mcp/registry.js';

export async function GET() {
  // Case 1: a completely unknown tool name.
  const unknownToolResult = await registry.execute('doesNotExist', {});

  // Case 2: a known tool, but input missing a required field.
  const invalidInputResult = await registry.execute('calculator', { wrongField: '1+1' });

  // Case 3: a known tool, called correctly.
  const validResult = await registry.execute('calculator', { expression: '6 * 7' });

  // Case 4: listing all registered tools' descriptions.
  const allTools = registry.listToolDescriptions();

  return NextResponse.json({ unknownToolResult, invalidInputResult, validResult, allTools });
}
```

```bash
curl -s http://localhost:3000/api/agent/registry-test | python3 -m json.tool
```

**Expected output:**
```json
{
    "unknownToolResult": {
        "ok": false,
        "errorType": "UNKNOWN_TOOL",
        "message": "Unknown tool \"doesNotExist\". Available tools: calculator, getCurrentTime, searchKnowledgeBase, lookupOrderStatus, trackShipment"
    },
    "invalidInputResult": {
        "ok": false,
        "errorType": "INVALID_INPUT",
        "message": "Invalid input for tool \"calculator\": {\"expression\":[\"Required\"]}"
    },
    "validResult": {
        "ok": true,
        "result": { "result": 42 }
    },
    "allTools": [
        { "name": "calculator", "description": "..." },
        { "name": "getCurrentTime", "description": "..." },
        { "name": "searchKnowledgeBase", "description": "..." },
        { "name": "lookupOrderStatus", "description": "..." },
        { "name": "trackShipment", "description": "..." }
    ]
}
```

Confirm all four cases behave exactly as expected — critically, notice that `invalidInputResult` was rejected **before** the calculator's handler ever ran (no expression was evaluated at all), proving validation genuinely happens as a gate in front of execution, not as an afterthought inside it.

#### Test 2 — Confirm duplicate tool registration is rejected at startup

Temporarily add a duplicate registration line to `lib/agent/mcp/registry.js` to confirm the safety check works:

```js
registry.register(calculatorTool);
registry.register(calculatorTool); // duplicate, added temporarily for this test
```

Restart the dev server and observe the terminal — it should crash immediately on startup with:
```
Error: A tool named "calculator" is already registered. Tool names must be unique.
```

This confirms the registry protects against a genuinely dangerous silent bug (one tool invisibly shadowing another). Remove the duplicate line and restart the server again before continuing.

#### Test 3 — Confirm the full ReAct loop still works end-to-end through the new registry-based architecture

```bash
curl -s -X POST http://localhost:3000/api/agent/react \
  -H "Content-Type: application/json" \
  -d '{"goal": "What is 17 times 23, and can you look up order ORD-1001?"}' \
  | python3 -m json.tool
```

**Expected behavior:** the trace should show two tool invocations — `calculator` with `action_input: {"expression": "17 * 23"}` and `lookupOrderStatus` with `action_input: {"orderId": "ORD-1001"}` — both correctly structured as objects now, not bare strings. The final answer should correctly report `391` and the order's delivered status for Jane Rivera. This confirms the entire pipeline — system prompt generation, model reasoning with structured `action_input` objects, registry-mediated dispatch, and observation feedback — all function correctly together under the new MCP-inspired architecture.

Once all three tests pass, you've completed a genuine architectural upgrade: every tool in your system is now a formally self-describing unit with its own enforced input contract, the reasoning loop has been fully decoupled from tool-specific implementation details, and adding, removing, or modifying any tool going forward touches exactly one file — never the loop, never the prompt builder, never the registry's own internals.
