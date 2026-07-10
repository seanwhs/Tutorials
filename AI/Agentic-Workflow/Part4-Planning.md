# Part 4: Task Decomposition & Planning

## 1. Why ReAct Alone Doesn't Scale to Long-Running Goals

ReAct (Parts 1-3) interleaves one reasoning step with one action, every time. That's efficient for short, well-scoped tasks. It breaks down for goals that require many coordinated steps: the model re-derives "what's my overall plan" from scratch on every single step, burning tokens and risking drift — where step 7's reasoning subtly contradicts the intent established at step 1.

**Plan-and-Execute** splits this into two distinct phases:
1. **Planner** — reasons once (or infrequently) about the full task and produces an explicit, structured list of sub-tasks.
2. **Executor** — works through the plan one sub-task at a time, using the same ReAct tool-calling loop from Parts 1-3 for each individual sub-task, without re-deriving the overall strategy each time.

Staff Engineer trade-off: Plan-and-Execute reduces drift and token cost on long tasks, at the cost of upfront planning latency and reduced flexibility if the plan itself is wrong (a bad plan is "baked in" until a re-plan is triggered — see section 5).

## 2. Extending the State Schema

Plan representation, defined with Zod so the Planner's structured output is validated the same way tool inputs are:

**src/agent/plan.ts:**
```typescript
import { z } from "zod";

export const PlanStepSchema = z.object({
  id: z.number().int(),
  description: z.string().min(1),
  status: z.enum(["pending", "in_progress", "done", "failed"]).default("pending"),
  result: z.string().optional(),
});

export const PlanSchema = z.object({
  goal: z.string(),
  steps: z.array(PlanStepSchema).min(1).max(10),
});

export type Plan = z.infer<typeof PlanSchema>;
```

The `.max(10)` cap is a deliberate guardrail, same rationale as Part 1's `maxSteps` — an unbounded plan is an unbounded cost/latency commitment. If a task genuinely needs more than 10 steps, reconsider decomposition granularity rather than raising the cap silently.

Add plan storage to the graph state:
```typescript
import { Annotation } from "@langchain/langgraph";
import type { Plan } from "./plan.js";

export const AgentState = Annotation.Root({
  // ...messages, stepCount, maxSteps from Part 1...
  plan: Annotation<Plan | null>({
    reducer: (_current, update) => update,
    default: () => null,
  }),
  currentStepIndex: Annotation<number>({
    reducer: (_current, update) => update,
    default: () => 0,
  }),
});
```

## 3. The Planner Node

**src/agent/nodes/plan.ts:**
```typescript
import { getModel } from "../model.js";
import { PlanSchema } from "../plan.js";
import type { AgentStateType } from "../state.js";
import { SystemMessage } from "@langchain/core/messages";

const PLANNER_PROMPT = `You are a planning module. Break the user's goal into
a short, ordered list of concrete, independently-executable sub-tasks.
Each sub-task should be small enough to complete with 1-3 tool calls.
Do not solve the task — only produce the plan.`;

export async function plannerNode(state: AgentStateType) {
  const model = getModel().withStructuredOutput(PlanSchema);
  const plan = await model.invoke([
    new SystemMessage(PLANNER_PROMPT),
    ...state.messages,
  ]);

  return {
    plan,
    currentStepIndex: 0,
    messages: [
      new SystemMessage(
        `Plan created with ${plan.steps.length} steps: ${plan.steps
          .map((s) => s.description)
          .join(" -> ")}`
      ),
    ],
  };
}
```

`withStructuredOutput` forces the model's response to conform to `PlanSchema` — the same "make invalid states unrepresentable via schema" principle from Part 2's tool contracts, now applied to the planning output itself.

## 4. The Executor Node

Reuses Part 1's Reason/Act loop, but scoped to a single plan step instead of the open-ended goal — the key mechanism that reduces drift.

**src/agent/nodes/execute.ts:**
```typescript
import { getModel } from "../model.js";
import { toolDefinitions } from "../../tools/index.js";
import type { AgentStateType } from "../state.js";
import { HumanMessage, SystemMessage } from "@langchain/core/messages";

export async function executeNode(state: AgentStateType) {
  const plan = state.plan!;
  const step = plan.steps[state.currentStepIndex];

  const model = getModel().bindTools(toolDefinitions);
  const response = await model.invoke([
    new SystemMessage(
      `You are executing ONE step of a larger plan. Focus only on this step; do not attempt other steps.\nOverall goal: ${plan.goal}`
    ),
    new HumanMessage(step.description),
  ]);

  const hasToolCalls =
    (response as any).tool_calls && (response as any).tool_calls.length > 0;

  if (hasToolCalls) {
    // Route to the shared Act node (Part 1) — let it execute, then re-enter
    // executeNode via the graph's conditional edges (wired below).
    return { messages: [response] };
  }

  // No more tool calls -> this step is considered complete.
  const updatedSteps = plan.steps.map((s, i) =>
    i === state.currentStepIndex
      ? { ...s, status: "done" as const, result: String(response.content) }
      : s
  );

  return {
    plan: { ...plan, steps: updatedSteps },
    currentStepIndex: state.currentStepIndex + 1,
    messages: [response],
  };
}
```

## 5. Wiring the Plan-and-Execute Graph

**src/agent/graph.planExecute.ts:**
```typescript
import { StateGraph, END } from "@langchain/langgraph";
import { AgentState, type AgentStateType } from "./state.js";
import { plannerNode } from "./nodes/plan.js";
import { executeNode } from "./nodes/execute.js";
import { actNode } from "./nodes/act.js";

function routeAfterExecute(state: AgentStateType): "act" | "execute" | typeof END {
  const lastMessage = state.messages[state.messages.length - 1] as any;
  if (lastMessage?.tool_calls?.length > 0) return "act";

  const plan = state.plan!;
  const allDone = plan.steps.every((s) => s.status === "done");
  return allDone ? END : "execute";
}

const graph = new StateGraph(AgentState)
  .addNode("plan", plannerNode)
  .addNode("execute", executeNode)
  .addNode("act", actNode)
  .addEdge("__start__", "plan")
  .addEdge("plan", "execute")
  .addConditionalEdges("execute", routeAfterExecute)
  .addEdge("act", "execute");

export const compiledPlanExecuteAgent = graph.compile();
```

Trace the control flow: Plan runs once. Execute runs per-step, delegating to Act for tool calls exactly like Part 1's loop, but returning to Execute (not back to Plan) afterward. Only when every step's status is `"done"` does the graph terminate. This is Plan-and-Execute's defining structural property: planning and execution are separate graph regions, connected by state, not by re-invoking the planner.

## 6. Re-Planning on Failure

**src/agent/nodes/replan.ts:**
```typescript
import { getModel } from "../model.js";
import { PlanSchema } from "../plan.js";
import type { AgentStateType } from "../state.js";
import { SystemMessage } from "@langchain/core/messages";

export async function replanNode(state: AgentStateType) {
  const plan = state.plan!;
  const model = getModel().withStructuredOutput(PlanSchema);

  const revisedPlan = await model.invoke([
    new SystemMessage(
      `The current plan has a failed step. Revise the remaining steps only.
Keep completed steps' descriptions unchanged. Do not repeat already-completed work.`
    ),
    new SystemMessage(JSON.stringify(plan)),
  ]);

  return { plan: revisedPlan, currentStepIndex: state.currentStepIndex };
}
```

Wire a `"failed"` branch in `routeAfterExecute` to route to `"replan"` instead of `END` when any step's status is `"failed"`. Cap re-plan attempts (e.g., max 2 per task) with the same "hard ceiling in code" discipline from Part 1, to prevent an unfixable step from causing an infinite plan/execute/fail/replan cycle.

## 7. Exercise Challenge

The Planner currently has no visibility into which tools exist, so it may produce steps that are impossible to execute (e.g., "check the customer's credit score" when no such tool exists). Modify the Planner to constrain planning to achievable steps.

## 8. Solution

```typescript
import { toolDefinitions } from "../../tools/index.js";

export async function plannerNode(state: AgentStateType) {
  const toolSummaries = toolDefinitions
    .map((t) => `- ${t.name}: ${t.description}`)
    .join("\n");

  const model = getModel().withStructuredOutput(PlanSchema);
  const plan = await model.invoke([
    new SystemMessage(
      `${PLANNER_PROMPT}\n\nAvailable tools (a step must be achievable using ONLY these, or general reasoning):\n${toolSummaries}`
    ),
    ...state.messages,
  ]);

  return { plan, currentStepIndex: 0, messages: [] };
}
```

Why this matters architecturally: it re-establishes the Part 2 principle that the tool layer is the ground truth for what's *possible* — the Planner must be grounded in the same tool registry the Executor actually has access to, or you get plans that look coherent but are unexecutable, which fails late (mid-execution) instead of never starting.

## Next
Part 5 adds a Critique step after Execute — before a plan step's output is accepted as "done," a separate reasoning pass validates it, closing the loop with self-correction instead of blind forward progress.
