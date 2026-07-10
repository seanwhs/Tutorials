# Part 9b: Reviewer, Planner, and Orchestration

*(Continued from Part 9: Multi-Agent Orchestration, sections 1-5.)*

## 6. The Reviewer Agent's Graph

Same shape again, deliberately — reuse is the point. Different system prompt, narrower tools, stronger model.

**src/agents/reviewer/state.ts:**
```typescript
import { Annotation } from "@langchain/langgraph";
import type { BaseMessage } from "@langchain/core/messages";

export const ReviewerState = Annotation.Root({
  messages: Annotation<BaseMessage[]>({
    reducer: (current, update) => current.concat(update),
    default: () => [],
  }),
});
```

**src/agents/reviewer/graph.ts:**
```typescript
import { StateGraph, END } from "@langchain/langgraph";
import { ToolNode } from "@langchain/langgraph/prebuilt";
import { ReviewerState } from "./state.js";
import { reviewerTools } from "./tools.js";
import { getReviewerModel } from "../model.js";
import { SystemMessage } from "@langchain/core/messages";

const REVIEWER_SYSTEM_PROMPT = "You are a strict, adversarial code reviewer. You did not write this code. Look specifically for correctness bugs, security issues, and unmet constraints. Approve only if you find zero blocking issues.";

async function reviewerReasonNode(state: typeof ReviewerState.State) {
  const model = getReviewerModel().bindTools(reviewerTools);
  const response = await model.invoke([
    new SystemMessage(REVIEWER_SYSTEM_PROMPT),
    ...state.messages,
  ]);
  return { messages: [response] };
}

const reviewerActNode = new ToolNode(reviewerTools);

const reviewerGraph = new StateGraph(ReviewerState)
  .addNode("reason", reviewerReasonNode)
  .addNode("act", reviewerActNode)
  .addEdge("__start__", "reason")
  .addConditionalEdges("reason", (state) => {
    const last = state.messages[state.messages.length - 1] as any;
    return last?.tool_calls?.length > 0 ? "act" : END;
  })
  .addEdge("act", "reason");

export const compiledReviewerAgent = reviewerGraph.compile();
```

**src/agents/reviewer/index.ts:**
```typescript
import { compiledReviewerAgent } from "./graph.js";
import { getReviewerModel } from "../model.js";
import { ReviewVerdictSchema } from "../contracts.js";
import type { CodeSubmission, ReviewVerdict } from "../contracts.js";
import { HumanMessage } from "@langchain/core/messages";

export async function runReviewerAgent(submission: CodeSubmission): Promise<ReviewVerdict> {
  const result = await compiledReviewerAgent.invoke({
    messages: [
      new HumanMessage(
        "Review this submission for task " + submission.taskId + ". Summary: " + submission.summary
      ),
    ],
  });

  const structuredModel = getReviewerModel().withStructuredOutput(ReviewVerdictSchema);
  const verdict = await structuredModel.invoke([
    ...result.messages,
    new HumanMessage("Produce your final structured verdict now."),
  ]);

  return ReviewVerdictSchema.parse({ ...verdict, taskId: submission.taskId });
}
```

Note the two-step call: the Reviewer first runs its own free-form ReAct loop, then a second call forces that reasoning into the `ReviewVerdictSchema` shape — mirrors Part 4's Planner pattern of using `withStructuredOutput` as a distinct step rather than hoping the tool-calling loop's final message happens to be parseable.

## 7. The Planner Orchestrating Both Agents

The Planner is the only agent aware both the Coder and Reviewer exist — neither is aware of the other or of the Planner, enforcing the isolation principle structurally.

**src/agents/planner/orchestrate.ts:**
```typescript
import { runCoderAgent } from "../coder/index.js";
import { runReviewerAgent } from "../reviewer/index.js";
import type { CodeTask } from "../contracts.js";

const MAX_REVISION_ROUNDS = 3;

export async function orchestrateCodeTask(task: CodeTask) {
  let currentTask = task;
  let lastVerdict = null;

  for (let round = 0; round <= MAX_REVISION_ROUNDS; round++) {
    const submission = await runCoderAgent(currentTask);
    const verdict = await runReviewerAgent(submission);
    lastVerdict = verdict;

    if (verdict.approved) {
      return { status: "approved" as const, submission, verdict, rounds: round + 1 };
    }

    if (round === MAX_REVISION_ROUNDS) {
      return { status: "escalated" as const, submission, verdict, rounds: round + 1 };
    }

    currentTask = {
      ...currentTask,
      instructions: currentTask.instructions + " Address these blocking issues from review: " + verdict.blockingIssues.join("; "),
    };
  }

  throw new Error("unreachable");
}
```

Trace the flow: Coder produces a submission, Reviewer produces a verdict, and on rejection the Planner feeds `blockingIssues` back into the next round's instructions — exactly as Part 5's `refineNode` fed Critique feedback back into regeneration, now across a process boundary. `MAX_REVISION_ROUNDS` is the same hard-stop-in-code discipline from every prior Part.

## 8. Escalation on Exhausted Rounds

**src/agents/planner/escalate.ts:**
```typescript
export async function escalateToHuman(result: { submission: unknown; verdict: unknown; rounds: number }) {
  const webhookUrl = process.env.N8N_ESCALATION_WEBHOOK_URL;
  if (!webhookUrl) {
    throw new Error("No escalation destination configured");
  }
  await fetch(webhookUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      reason: "coder_reviewer_max_rounds_exhausted",
      rounds: result.rounds,
      verdict: result.verdict,
    }),
  });
}
```

Reuses Part 6's exact n8n webhook pattern — escalation is structurally just another external action, belonging behind the same n8n action layer as any other side effect.

## 9. Observability Across Agent Boundaries

**src/agents/planner/observability.ts:**
```typescript
import { CallbackHandler } from "langfuse-langchain";

export function getSharedHandler(orchestrationId: string) {
  return new CallbackHandler({
    publicKey: process.env.LANGFUSE_PUBLIC_KEY,
    secretKey: process.env.LANGFUSE_SECRET_KEY,
    baseUrl: process.env.LANGFUSE_BASE_URL,
    sessionId: orchestrationId,
    metadata: { multiAgent: true },
  });
}
```

Pass the same handler into `runCoderAgent`'s and `runReviewerAgent`'s underlying invoke calls. One `orchestrationId` ties all three agents' traces into a single reviewable session in Langfuse, satisfying Appendix C's audit logging requirement across this multi-process architecture.

## 10. Exercise Challenge

`orchestrateCodeTask` always runs the full Coder-then-Reviewer sequence, even for a trivial one-line fix. Add a heuristic so mechanical issues (missing semicolon, unused import) can be fixed deterministically rather than paying for another full Coder invocation.

## 11. Solution

```typescript
const MECHANICAL_ISSUE_PATTERNS = [/unused import/i, /missing semicolon/i, /trailing whitespace/i];

function isMechanicalOnly(issues: string[]): boolean {
  return issues.length > 0 && issues.every((issue) =>
    MECHANICAL_ISSUE_PATTERNS.some((p) => p.test(issue))
  );
}

// Inside the orchestration loop, before re-invoking runCoderAgent:
if (isMechanicalOnly(verdict.blockingIssues)) {
  const patchedSubmission = applyMechanicalFixes(submission, verdict.blockingIssues);
  const revalidation = await runReviewerAgent(patchedSubmission);
  if (revalidation.approved) {
    return { status: "approved" as const, submission: patchedSubmission, verdict: revalidation, rounds: round + 1 };
  }
}
```

Why this belongs here: the same principle from Part 6 applied one level up — deterministic work should never be routed through a model call. A full Coder invocation to fix a missing semicolon is the multi-agent equivalent of routing exponential backoff through an LLM decision. Reserve the Coder's (and the org's) budget for issues that genuinely need reasoning.

## Series Status
With Part 9 and this note, the series spans a single ReAct agent (Part 1) through a full three-agent Planner/Coder/Reviewer system, reusing the same state, tool, memory, reflection, tracing, and deployment primitives throughout. Appendix A's Multi-Agent row is no longer hypothetical — it's a built, working reference implementation in this series.

---

That's the end of the numbered Parts. Next up in the series are the three Appendices — say **"next"** again to continue to **Appendix A: The Agentic Pattern Matrix**.
