# Part 5: Reflection & Self-Correction

## 1. Why Generation Alone Isn't Enough

Every node built so far (Reason, Execute) produces an output and moves forward. None ask "was that output actually correct/safe/complete?" before acting on it. Reflection introduces a dedicated **Critique** phase between generation and action — the "Generation-Critique-Refinement" cycle:

1. **Generate** — produce a candidate output.
2. **Critique** — a separate reasoning pass evaluates the candidate against explicit criteria and returns a structured verdict (pass/fail + reasons).
3. **Refine** — if critique fails, generate again, informed by the critique's specific feedback. Loop back to step 2, bounded by a retry ceiling.

Staff Engineer framing: this is the highest-leverage pattern for reducing hallucination-driven failures, because it forces the model to check its own work using a *fresh, differently-framed* reasoning pass rather than trusting the first output. Cost is doubling (or more) token spend and latency per action — reserve it for steps where being wrong is expensive (irreversible actions, user-facing final answers), not every micro-step.

## 2. Critique as a Structured Output (Not a Vibe)

**src/agent/critique.ts:**
```typescript
import { z } from "zod";

export const CritiqueSchema = z.object({
  verdict: z.enum(["pass", "fail"]),
  issues: z.array(z.string()).default([]),
  suggestion: z.string().optional().describe(
    "Concrete instruction for how to fix the issues, if verdict is fail."
  ),
});

export type Critique = z.infer<typeof CritiqueSchema>;
```

## 3. The Critique Node

**src/agent/nodes/critique.ts:**
```typescript
import { getModel } from "../model.js";
import { CritiqueSchema } from "../critique.js";
import type { AgentStateType } from "../state.js";
import { SystemMessage } from "@langchain/core/messages";

const CRITIQUE_PROMPT = `You are a strict reviewer, not the original author.
Evaluate the candidate output against these criteria:
1. Does it directly address the user's actual request?
2. Are all factual claims traceable to information present in the conversation
   or tool results (no invented facts)?
3. If the output proposes an action, is that action safe and reversible,
   or explicitly confirmed if irreversible?
Return "fail" if ANY criterion is not met, with specific issues listed.`;

export async function critiqueNode(state: AgentStateType) {
  const candidate = state.messages[state.messages.length - 1];
  const model = getModel().withStructuredOutput(CritiqueSchema);

  const critique = await model.invoke([
    new SystemMessage(CRITIQUE_PROMPT),
    ...state.messages.slice(0, -1),
    new SystemMessage(`Candidate output to review:\n${candidate.content}`),
  ]);

  return { lastCritique: critique };
}
```

Note the framing "You are a strict reviewer, not the original author" — a deliberate prompt-engineering technique to reduce self-agreement bias (an LLM asked to critique its own immediately-prior output tends to rubber-stamp it unless explicitly instructed to adopt an adversarial stance).

Add `lastCritique` to state:
```typescript
lastCritique: Annotation<Critique | null>({
  reducer: (_current, update) => update,
  default: () => null,
}),
refinementCount: Annotation<number>({
  reducer: (_current, update) => update,
  default: () => 0,
}),
```

## 4. The Refine Node and Routing

**src/agent/nodes/refine.ts:**
```typescript
import { getModel } from "../model.js";
import type { AgentStateType } from "../state.js";
import { SystemMessage } from "@langchain/core/messages";

const MAX_REFINEMENTS = 2;

export async function refineNode(state: AgentStateType) {
  const critique = state.lastCritique!;
  const model = getModel();

  const response = await model.invoke([
    ...state.messages,
    new SystemMessage(
      `Your previous output failed review. Issues: ${critique.issues.join("; ")}. ${
        critique.suggestion ?? ""
      }\nProduce a corrected output.`
    ),
  ]);

  return {
    messages: [response],
    refinementCount: state.refinementCount + 1,
  };
}
```

Routing function:
```typescript
import { END } from "@langchain/langgraph";
import type { AgentStateType } from "../state.js";

export function routeAfterCritique(state: AgentStateType): "refine" | typeof END {
  const critique = state.lastCritique!;
  if (critique.verdict === "pass") return END;
  if (state.refinementCount >= MAX_REFINEMENTS) {
    // Ceiling reached — accept the last candidate rather than looping forever.
    // Section 6 covers escalation instead of silent acceptance.
    return END;
  }
  return "refine";
}
```

Same hard-ceiling discipline as every prior Part: `MAX_REFINEMENTS` is enforced in the router, not left to the model's judgment about when to "give up."

## 5. Wiring Generation-Critique-Refinement

**src/agent/graph.reflect.ts:**
```typescript
import { StateGraph, END } from "@langchain/langgraph";
import { AgentState } from "./state.js";
import { reasonNode } from "./nodes/reason.js";
import { actNode } from "./nodes/act.js";
import { critiqueNode } from "./nodes/critique.js";
import { refineNode } from "./nodes/refine.js";
import { routeAfterCritique } from "./nodes/routeAfterCritique.js";

const graph = new StateGraph(AgentState)
  .addNode("reason", reasonNode)
  .addNode("act", actNode)
  .addNode("critique", critiqueNode)
  .addNode("refine", refineNode)
  .addEdge("__start__", "reason")
  .addConditionalEdges("reason", (state) => {
    const last = state.messages[state.messages.length - 1] as any;
    return last?.tool_calls?.length > 0 ? "act" : "critique";
  })
  .addEdge("act", "reason")
  .addConditionalEdges("critique", routeAfterCritique)
  .addEdge("refine", "critique");

export const compiledReflectiveAgent = graph.compile();
```

Control flow: tool-calling loops exactly as in Part 1 (reason ↔ act) until the model produces a final answer with no tool calls — then routes to Critique instead of ending immediately. Refine loops back to Critique (not Reason), because refinement is "fix this specific output," narrower than "re-reason from scratch."

## 6. Escalation Instead of Silent Acceptance

Silently shipping an output that failed review twice is a governance gap. Prefer explicit escalation:

```typescript
export function routeAfterCritique(
  state: AgentStateType
): "refine" | "escalate" | typeof END {
  const critique = state.lastCritique!;
  if (critique.verdict === "pass") return END;
  if (state.refinementCount >= MAX_REFINEMENTS) return "escalate";
  return "refine";
}
```

**src/agent/nodes/escalate.ts:**
```typescript
import type { AgentStateType } from "../state.js";
import { AIMessage } from "@langchain/core/messages";

export async function escalateNode(state: AgentStateType) {
  // In production: write to a review queue, notify a human (Part 6's n8n
  // integration is the natural home for this side effect), and halt.
  return {
    messages: [
      new AIMessage(
        "I was unable to produce output that passed review after multiple attempts. This has been flagged for human review rather than returned as a final answer."
      ),
    ],
  };
}
```

This is the first explicit **human-in-the-loop (HITL) checkpoint** in the series — Part 6 gives it a real destination, and Appendix C requires at least one HITL escalation path before any agent handling irreversible actions ships.

## 7. Applying Reflection to Part 4's Plan-and-Execute Steps

Insert a `critique` node after `execute` in the Part 4 graph, before marking a step "done." This catches an executor that calls a tool successfully but misinterprets or misreports the result. Critique re-reads the step's goal against the tool's actual raw output — since the executor's summary is exactly what might be wrong.

## 8. Exercise Challenge

Extend the Critique prompt so that for candidate outputs containing a `send_notification`-style tool call, Critique specifically verifies that `confirmed: true` was only set after an explicit user confirmation appears earlier in the message history — not merely assumed by the model.

## 9. Solution

```typescript
const CRITIQUE_PROMPT_WITH_CONFIRMATION_CHECK = `${CRITIQUE_PROMPT}
4. If the candidate includes a tool call with a "confirmed" field set to true,
   verify that an earlier message in the conversation contains an explicit
   user statement approving that specific action. If no such explicit
   approval exists in the history, this is an automatic FAIL, regardless of
   how reasonable the action seems.`;
```

Why this belongs in Critique rather than the tool schema alone: Part 2's `z.literal(true)` guarantees the *field* can't be missing, but cannot verify the *reason* the model set it to true was a real user confirmation rather than the model's own inference. Schema validation and critique review are complementary layers, not substitutes — defense in depth applied to agent safety.

## Next
Part 6 moves from pure-code orchestration to a hybrid architecture: n8n takes over deterministic, external-system actions (the "Act" side), while everything built in Parts 1-5 continues to own reasoning, planning, and reflection.
