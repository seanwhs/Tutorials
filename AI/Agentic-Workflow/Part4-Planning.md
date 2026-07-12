# Part 4: Task Decomposition & Planning

> Recap: Parts 1-3 built a single ReAct loop — Reason, Act, Observe, repeat — with a real tool layer (Part 2) and a real memory layer (Part 3) underneath it. That loop is genuinely good at short, well-scoped tasks. This Part is about what happens when it isn't scoped short anymore, and why the fix isn't "make the loop bigger" but "split the loop into two different kinds of work."

## 1. Why ReAct Alone Doesn't Scale to Long-Running Goals

ReAct, as built across Parts 1-3, interleaves one reasoning step with one action, every single time, with no persistent notion of "the plan" beyond whatever's implicit in the accumulated transcript. That's efficient — genuinely efficient, not just simple — for short, well-scoped tasks: "look up this order and tell me its status" doesn't benefit from an explicit planning phase, and adding one would just be overhead.

It breaks down for goals that require many coordinated steps, for a specific reason worth naming precisely: the model re-derives "what's my overall plan" from scratch on every single step, implicitly, by re-reading the entire transcript and re-inferring intent. That re-derivation isn't free, and it isn't perfectly stable. It burns tokens (the transcript grows every step, and gets fully re-read every step — Part 3's `windowForModel` helps with cost but doesn't fix the underlying re-derivation problem), and it risks *drift* — a specific failure mode where step 7's reasoning subtly contradicts the intent established at step 1, not because the model made an obvious error, but because "the plan" was never actually written down anywhere; it was re-inferred fresh each time, and re-inference is not guaranteed to converge on the same answer twice, especially across a long, noisy transcript.

**Plan-and-Execute** splits this into two distinct phases, and the split itself is the fix for drift — not a smarter model, not a longer prompt, an actual architectural separation:

1. **Planner** — reasons once, or infrequently, about the full task and produces an explicit, *structured* list of sub-tasks. Structured, not prose, matters here: a plan written down as data can be inspected, validated, stored in state, and referred back to exactly, rather than re-inferred approximately from a transcript.
2. **Executor** — works through the plan one sub-task at a time, using the same ReAct tool-calling loop from Parts 1-3 for each individual sub-task, without re-deriving the overall strategy each time. The strategy was already decided; the Executor's job is narrower — execute *this* step — and narrower jobs are exactly where ReAct excels.

Staff Engineer trade-off, stated plainly rather than left implicit: Plan-and-Execute reduces drift and token cost on long tasks, at the cost of upfront planning latency (you pay for the whole plan before any work starts) and reduced flexibility if the plan itself is wrong — a bad plan is "baked in" until a re-plan is explicitly triggered (section 6). This is not a strict upgrade over plain ReAct; it's a different point on the same trade-off curve, and the right choice depends on task length and how much you expect the world to change mid-task. Short, simple asks: stay with Part 1's loop. Long, multi-step goals with low expected surprise: Plan-and-Execute. High expected surprise mid-task: you want re-planning to be cheap and frequent, which section 6 addresses directly.

## 2. Extending the State Schema

Plan representation, defined with Zod so the Planner's structured output is validated the same way tool inputs were validated back in Part 2 — the same instinct, applied to a different kind of model output.

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

The `.max(10)` cap is a deliberate guardrail with the exact same rationale as Part 1's `maxSteps`: an unbounded plan is an unbounded cost and latency commitment, made *before a single step has executed*. That's a sharper risk than Part 1's step ceiling, because Part 1's ceiling caps a loop that's already producing incremental value turn by turn; a runaway plan commits you to a large amount of downstream work on the strength of a single, unverified planning call. If a task genuinely needs more than 10 steps to complete, the right response is to reconsider decomposition granularity — are these truly atomic sub-tasks, or should two "steps" really be one step with a slightly larger scope — rather than quietly raising the cap. Raising the cap treats the symptom; reconsidering granularity treats the cause.

Note also the `status` enum's four states, and specifically that `"failed"` is a first-class status, not something inferred from an absence or a caught exception elsewhere. Making failure a value the schema can represent — rather than something that has to be reconstructed from logs or a thrown error — is what makes section 6's re-planning possible to wire in cleanly: `routeAfterExecute` can check `status === "failed"` directly, no separate failure-tracking mechanism required.

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

Both new fields use replace-on-update reducers, not `concat` — the same distinction Part 1 drew between `messages` (accumulates) and `stepCount` (replaces). A plan isn't a log of every plan that's ever existed; it's the *current* plan, and each update should fully supersede the last. Keep asking that question — "does combining old and new mean concatenating, or replacing?" — every time you add a state field for the rest of this series; it's a two-second check that prevents a whole category of subtle state-corruption bugs.

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

`withStructuredOutput(PlanSchema)` forces the model's response to conform to `PlanSchema` at the API layer — this is the same "make invalid states unrepresentable via schema" principle from Part 2's tool contracts (recall `z.literal(true)` on the notification tool), now applied to the planning output itself rather than to a tool's arguments. It's worth noticing how far that one principle has now traveled: Part 2 used it to make an unsafe *action* impossible to construct; here it's used to make a malformed *plan* impossible to produce. Same mechanism, different failure mode being closed off.

Look also at the explicit instruction "Do not solve the task — only produce the plan." That line is doing real work, not just tidying up the prompt: a model asked to plan a task will, left unconstrained, sometimes start solving it inline — reasoning through step 1's actual answer while it's supposed to be listing steps. That blurs the Planner/Executor boundary this whole Part depends on, so the prompt draws the line explicitly rather than relying on the schema alone to keep the Planner in its lane (the schema constrains the *shape* of the output, not what the model does with its reasoning to get there).

Finally, notice what the returned `messages` entry is: a `SystemMessage` summarizing the plan, appended to the transcript. That's a deliberate observability choice, in the spirit of Part 1's "the transcript is your audit log" — anyone reading the transcript later (a human debugging, or Part 7's Langfuse view) sees the plan announced in-line, in order, rather than having to separately go look up `state.plan` to understand what the agent decided to do.

## 4. The Executor Node

The Executor reuses Part 1's Reason/Act loop conceptually, but scoped to a single plan step instead of the open-ended goal — this scoping is the actual mechanism that reduces drift, not just a organizational nicety. A model reasoning about "execute this one described sub-task" has a dramatically narrower space of plausible next actions than a model reasoning about "make progress on this whole multi-part goal," and narrower spaces are where models are most reliable.

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

Notice the model call here is invoked with a *fresh*, minimal message array — `[SystemMessage(...), HumanMessage(step.description)]` — not `state.messages`. That's a significant departure from Part 1's Reason node, which fed the model the (windowed) full transcript every time. Here, the Executor deliberately withholds most of the accumulated conversation history from the model on each step, giving it only the overall goal (one line) and the specific step description. This is the drift-reduction mechanism made concrete in code: the model literally cannot re-litigate step 1's reasoning while executing step 4, because step 1's reasoning isn't in its context window for this call. The trade-off is that the Executor loses access to details surfaced earlier in the transcript unless they were captured in `step.result` or the plan itself — worth keeping in mind when a step genuinely needs information another step produced (the `result` field on each `PlanStepSchema` entry exists precisely to carry that information forward deliberately, rather than relying on ambient transcript context).

Also notice the shared reuse of `toolDefinitions` and `actNode` (Part 1/Part 2) unchanged — the Executor isn't a parallel, separately-maintained tool-calling implementation, it's the *same* Act mechanism, just invoked from a different Reason-equivalent node. That reuse is only possible because Part 2 built the tool registry as a standalone, graph-agnostic array in the first place.

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

Trace the control flow deliberately, the way you did with Part 1's simpler graph: Plan runs exactly once, at the very start (`__start__ -> plan -> execute`, no cycle back to `plan` anywhere in this graph — re-planning, when it exists, is a separate explicit path, section 6). Execute then runs per-step, delegating to Act for tool calls exactly like Part 1's loop (`execute -> act -> execute`, mirroring Part 1's `reason -> act -> reason`), but critically, control returns to Execute afterward, *not* to Plan. Only when every step's `status` is `"done"` — the `allDone` check — does the graph terminate.

This is Plan-and-Execute's defining structural property, worth stating as plainly as possible: **planning and execution are separate graph regions, connected by state (the `plan` field), not by re-invoking the planner.** The Planner's job finishes and its node is never visited again in this graph (absent the re-planning extension in section 6); everything from that point forward is the Executor consulting and updating the plan it was handed. If you find yourself wanting the Planner to weigh in mid-execution without an explicit re-plan trigger, that's a sign you actually want a different architecture — closer to Part 1's single-loop ReAct — not a bug in this one.

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

Wire a `"failed"` branch in `routeAfterExecute` to route to `"replan"` instead of `END` when any step's status is `"failed"`. Two instructions in the prompt are doing the real safety work here and are worth reading twice: "Keep completed steps' descriptions unchanged" and "Do not repeat already-completed work." Without them, a re-plan call has no guarantee it won't quietly rewrite history — re-describing a step that already ran and already produced a `result`, or worse, generating a whole new plan that re-does work a tool call already completed (a real problem if that work included a side effect, like Part 2's `send_notification` tool — re-running a step that already sent a message is not a harmless no-op).

Cap re-plan attempts — say, a maximum of 2 per task — with the same "hard ceiling in code" discipline from Part 1's `maxSteps`, not a prompt instruction alone. The reasoning is identical to Part 1's: without a coded ceiling, an unfixable step (a step whose failure the model cannot actually resolve by rewording it — a tool that's genuinely unavailable, a piece of data that genuinely doesn't exist) produces an infinite plan → execute → fail → replan cycle, because each re-plan call has no way of knowing it's the *n*th attempt at fixing the same underlying problem unless the harness tracks and enforces that count itself.

## 7. Exercise Challenge

The Planner, as written in section 3, currently has no visibility into which tools exist. It's reasoning about "what sub-tasks would accomplish this goal" in a vacuum, disconnected entirely from `toolDefinitions` (Part 2). That means it may confidently produce steps that are impossible to execute — "check the customer's credit score," say, when no such tool exists anywhere in the registry. Worse, this failure mode surfaces late: the plan looks perfectly coherent when it's created, and the impossibility only becomes visible when the Executor gets to that step and has no tool capable of completing it. Modify the Planner to constrain planning to genuinely achievable steps.

Before looking at the solution, connect this back to Part 2's closing checklist: "scope the description" was advice for a tool talking to a model. This exercise is the mirror version — making sure the *Planner* talking to the model is scoped by what the tools can actually do.

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

Why this matters architecturally, beyond just "fewer bad plans": it re-establishes a principle Part 2 already argued for — the tool layer is the ground truth for what's *possible* — and applies it one level up the stack. The Planner must be grounded in the exact same tool registry the Executor actually has access to, not a separately-maintained description of capabilities that can silently drift out of sync with reality. If a new tool is added to `toolDefinitions` in Part 2's file, this Planner picks it up automatically, with zero changes needed here — the same "swap one file, everything downstream updates" property Part 1's `model.ts` and Part 2's `index.ts` were both designed around.

The alternative — a Planner that doesn't know what tools exist — produces plans that look coherent on paper and fail late, mid-execution, which is a strictly worse failure mode than failing early: late failure has already consumed planning latency, possibly several completed (and non-trivially reversible) steps, and now has to be handled by the section 6 re-planning path instead of never having produced the bad plan in the first place. Grounding the Planner in real tool descriptions moves a whole class of failure from "discovered at runtime, three steps in" to "never produced."

## Plan-and-Execute Checklist

- **Structure the plan, don't let it stay implicit in prose.** A Zod-validated `Plan` can be inspected, stored, and referenced exactly; a plan re-inferred from a transcript can't.
- **Cap plan length in code**, the same way Part 1 capped loop steps — an oversized plan is a cost commitment made before any work has verified it's the right plan.
- **Scope the Executor to one step at a time**, deliberately withholding the broader transcript — that narrowing is the actual drift-reduction mechanism, not a side effect of the architecture.
- **Make failure a first-class status**, not something reconstructed after the fact, so re-planning logic can branch on it directly.
- **Ground the Planner in the real tool registry.** A plan produced in ignorance of what's executable fails late; a plan grounded in `toolDefinitions` fails early or not at all.
- **Cap re-plan attempts in code.** An unfixable step plus unlimited re-planning is Part 1's runaway-loop risk, one level up the stack.

## Next

Part 5 adds a Critique step after Execute — before a plan step's output is accepted as "done," a separate reasoning pass validates it, closing the loop with self-correction instead of blind forward progress.
