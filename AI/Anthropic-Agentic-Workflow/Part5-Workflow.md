# Part 5: Agentic Workflow Design (Multi-Step Agent)

**Series:** Building Agentic Workflows: Mastering the Anthropic Suite
**Prerequisite:** Parts 1-4 (client, tools, structured output, caching/memory).

## Concept Explanation

A "chat with tools" loop (Part 2) reacts turn-by-turn. A true **agent** pursues a goal across multiple steps without a human re-prompting it each time: it reads the current state, reflects on what's missing, plans the next action, executes it (often via a tool), and re-evaluates — repeating until the goal is satisfied or a stopping condition fires.

The classic architecture is **Reflect → Plan → Execute**, run in a loop:

1. **Reflect:** Given the goal and everything done so far, what do we know? What's still unknown or unresolved?
2. **Plan:** Decide the single next concrete action (not a full plan up front — re-planning after each step keeps the agent adaptive to tool results).
3. **Execute:** Run that action (a tool call) and record the result.
4. **Check stopping condition:** Goal satisfied? Max steps hit? Irrecoverable error? If not, loop back to Reflect.

### Why re-plan every step instead of planning once upfront

Upfront planning is brittle — step 3 might reveal information that invalidates step 5. Re-planning after every execution costs more tokens but produces agents that actually recover from surprises (a failed lookup, an empty query result, a tool error) instead of blindly executing a stale plan. This is the core tradeoff a Senior AI Architect must state explicitly to stakeholders: **adaptiveness costs tokens**.

### Guardrails that make an agent production-safe, not a demo toy

- **Hard step ceiling** (`MAX_STEPS`) — never allow unbounded loops.
- **Explicit stop tool** — give the agent a `finish_task` tool it must call to end the loop with a final structured result (Part 3 pattern), rather than inferring completion from prose.
- **Per-step cost budget** — track cumulative `usage` across the loop and abort if it exceeds a threshold, independent of step count (a single step can be disproportionately expensive).
- **Tiered model use** — use Haiku for the cheap Reflect step, Sonnet for Plan/Execute reasoning, and reserve Opus only if a step is flagged high-stakes.

## Implementation

### Step 1 — Define the agent's structured plan/finish schemas

`src/lib/anthropic/schemas/plan.schema.ts`

```ts
import { z } from "zod";

export const NextStepSchema = z.object({
  reasoning: z.string().describe("Brief internal reasoning for why this action is next."),
  action: z.enum(["call_tool", "finish_task"]).describe("Whether to call a tool or finish."),
  toolName: z.string().optional().describe("Required if action is 'call_tool'."),
  toolInput: z.record(z.unknown()).optional().describe("Arguments for the tool call."),
  finalAnswer: z.string().optional().describe("Required if action is 'finish_task'."),
});

export type NextStep = z.infer<typeof NextStepSchema>;
```

### Step 2 — The agent loop module

`src/lib/anthropic/agent-loop.ts`

```ts
import Anthropic from "@anthropic-ai/sdk";
import { anthropic } from "./client";
import { MODELS } from "./models";
import { TOOLS } from "./tools/registry";
import { executeTool } from "./tools/dispatch";

const MAX_STEPS = 8;
const MAX_CUMULATIVE_TOKENS = 20_000; // hard budget ceiling for one agent run

export interface AgentStepLog {
  step: number;
  reasoning: string;
  action: "call_tool" | "finish_task";
  toolName?: string;
  toolResult?: unknown;
}

export interface AgentRunResult {
  finalAnswer: string;
  steps: AgentStepLog[];
  totalTokens: number;
  stoppedReason: "finished" | "max_steps" | "budget_exceeded";
}

const FINISH_TOOL: Anthropic.Tool = {
  name: "finish_task",
  description:
    "Call this when the goal has been fully achieved and you are ready to return the final answer to the user. " +
    "Do not call this prematurely if information is still missing.",
  input_schema: {
    type: "object",
    properties: {
      finalAnswer: { type: "string", description: "The complete final answer for the user." },
    },
    required: ["finalAnswer"],
  },
};

export async function runAgent(goal: string): Promise<AgentRunResult> {
  const messages: Anthropic.MessageParam[] = [
    { role: "user", content: `Goal: ${goal}` },
  ];
  const steps: AgentStepLog[] = [];
  let totalTokens = 0;

  for (let i = 0; i < MAX_STEPS; i++) {
    const response = await anthropic.messages.create({
      model: MODELS.sonnet,
      max_tokens: 1024,
      system:
        "You are an autonomous task-completing agent. On each turn, decide the single next " +
        "action toward the goal: either call one of the available tools, or call finish_task " +
        "once the goal is fully satisfied. Think step by step but keep reasoning concise. " +
        "Never call finish_task until you have verified the goal is actually met.",
      tools: [...TOOLS, FINISH_TOOL],
      messages,
    });

    totalTokens += response.usage.input_tokens + response.usage.output_tokens;
    messages.push({ role: "assistant", content: response.content });

    if (totalTokens > MAX_CUMULATIVE_TOKENS) {
      return { finalAnswer: "Agent stopped: token budget exceeded.", steps, totalTokens, stoppedReason: "budget_exceeded" };
    }

    const toolUse = response.content.find(
      (b): b is Anthropic.ToolUseBlock => b.type === "tool_use"
    );

    if (!toolUse) {
      // Model responded in plain text without calling a tool — nudge it back on track.
      messages.push({
        role: "user",
        content: "Please continue by calling a tool or finish_task — do not respond in plain text.",
      });
      continue;
    }

    if (toolUse.name === "finish_task") {
      const finalAnswer = (toolUse.input as { finalAnswer: string }).finalAnswer;
      steps.push({ step: i + 1, reasoning: "Task complete.", action: "finish_task" });
      return { finalAnswer, steps, totalTokens, stoppedReason: "finished" };
    }

    const result = await executeTool(toolUse.name, toolUse.input as Record<string, unknown>);
    steps.push({
      step: i + 1,
      reasoning: `Called tool ${toolUse.name}`,
      action: "call_tool",
      toolName: toolUse.name,
      toolResult: result,
    });

    messages.push({
      role: "user",
      content: [
        {
          type: "tool_result",
          tool_use_id: toolUse.id,
          content: JSON.stringify(result),
        },
      ],
    });
  }

  return {
    finalAnswer: "Agent stopped: max steps reached without completing the goal.",
    steps,
    totalTokens,
    stoppedReason: "max_steps",
  };
}
```

### Step 3 — Expose it via a Route Handler

`src/app/api/agent/workflow/route.ts`

```ts
import { NextRequest, NextResponse } from "next/server";
import { runAgent } from "@/lib/anthropic/agent-loop";

export async function POST(req: NextRequest) {
  const { goal } = await req.json();
  if (!goal || typeof goal !== "string") {
    return NextResponse.json({ error: "Field 'goal' (string) is required." }, { status: 400 });
  }

  const result = await runAgent(goal);
  return NextResponse.json(result);
}
```

### Architecture note: how "Thinking" affects UI design and latency

Extended thinking (Claude's visible reasoning blocks, when enabled via the `thinking` API parameter) produces additional `thinking` content blocks before the final answer or tool call. Two consequences for UI design:

- **Latency:** thinking tokens are generated before the actionable output, so time-to-first-useful-token increases. For agent loops with multiple steps, this compounds — budget for it explicitly rather than assuming Part 1-style response times.
- **UI treatment:** never show raw thinking content as the "answer" — render it (if shown at all) as a collapsed "reasoning" panel, distinct from the final response/tool result. In Part 6's streaming implementation, thinking deltas arrive as a separate content block type and should be routed to a different UI region than text deltas.

For agent loops specifically, prefer reserving extended thinking for the **Plan** step only (higher-stakes decision), not every Reflect/Execute cycle — it's a cost multiplier you should apply surgically.

## Exercise Challenge

Modify `runAgent` to accept an optional `onStep` callback (`(log: AgentStepLog) => void`) invoked after every step, and use it to persist step logs to your database in real time (rather than only returning them at the end) — this is required for any UI that wants to show live agent progress rather than a single blocking spinner.

## Solution

```ts
export async function runAgent(
  goal: string,
  onStep?: (log: AgentStepLog) => void
): Promise<AgentRunResult> {
  // ...identical setup...
  for (let i = 0; i < MAX_STEPS; i++) {
    // ...identical response handling...

    if (toolUse.name === "finish_task") {
      const finalAnswer = (toolUse.input as { finalAnswer: string }).finalAnswer;
      const log: AgentStepLog = { step: i + 1, reasoning: "Task complete.", action: "finish_task" };
      steps.push(log);
      onStep?.(log);
      return { finalAnswer, steps, totalTokens, stoppedReason: "finished" };
    }

    const result = await executeTool(toolUse.name, toolUse.input as Record<string, unknown>);
    const log: AgentStepLog = {
      step: i + 1,
      reasoning: `Called tool ${toolUse.name}`,
      action: "call_tool",
      toolName: toolUse.name,
      toolResult: result,
    };
    steps.push(log);
    onStep?.(log); // fire-and-forget persistence hook — e.g. write to DB or push over a WebSocket

    // ...rest identical...
  }
}
```

**Why a callback instead of returning a stream directly here:** decoupling step-by-step notification from the function's return value keeps `runAgent` framework-agnostic — the caller decides whether `onStep` writes to Postgres, pushes to a WebSocket, or feeds an SSE stream (Part 6 shows the latter).

**Next:** Part 6 adds robust error handling (timeouts, rate limits, malformed responses) and converts this synchronous agent into a streaming UI experience with the Vercel AI SDK.
