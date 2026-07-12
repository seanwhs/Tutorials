# Part 9b: Reviewer, Planner, and Orchestration

*(Continued from Part 9a: Multi-Agent Orchestration, sections 1-5 — the trigger condition for multi-agent, the distributed-systems framing, the shared contracts, and the Coder agent's graph and public boundary.)*

## 6. The Reviewer Agent's Graph

Same shape again, deliberately — reuse is the point, not a coincidence, and it's worth pausing on that before diving into the code. By the time you're building a third agent in a system like this, you want its graph to be *boring* — structurally identical to the Coder's graph from section 5, differing only in the dimensions that actually need to differ: system prompt, tool registry, and model. If your third agent's graph looked structurally novel, that would be a warning sign that something's been over-engineered; the whole value of Part 1's Reason/Act shape is that it's a stable, reusable unit you can stamp out per role, and this section is the proof of that reusability, not a new pattern to learn.

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

Notice this state is even leaner than the Coder's `CoderState` from Part 9a — no `stepCount` field at all. That's a deliberate, minor asymmetry worth explaining rather than an oversight: the Reviewer's job, per its narrow tool registry (Part 9a, section 4 — read-only, one tool), is inherently bounded in a way that doesn't need an explicit step ceiling the way an open-ended Coder implementation loop does. This is worth internalizing as a general instinct for the rest of this series and beyond: state schemas should carry exactly the fields a given role actually needs, not a copy-pasted template applied uniformly regardless of fit — a good state schema is itself documentation of what a node's job actually requires.

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

Read `REVIEWER_SYSTEM_PROMPT`'s opening line — "You did not write this code" — against Part 5, section 3's framing for the in-graph Critique node: "You are a strict reviewer, not the original author." It's the identical self-agreement-bias countermeasure, restated for a context where it's actually *literally* true this time, not just a useful fiction the prompt asserts. In Part 5, the Critique node was evaluating output the same underlying model had just produced moments earlier in the same graph — the instruction was fighting a real, present bias. Here, the Reviewer genuinely is a separate agent, potentially running on a different, stronger model (`getReviewerModel()`'s `gpt-4o` default from Part 9a, section 4), that had no hand whatsoever in writing the code under review. The instruction is no longer compensating for a fiction; it's simply stating the actual architecture. That's worth noticing as the real payoff of graduating from Part 5's in-graph Critique to this Part's separate Reviewer agent: the self-agreement-bias problem doesn't just get *mitigated* by a stronger prompt, it gets *structurally eliminated*, because there's no longer a shared authorship to be biased about in the first place.

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

Note the two-step call, and why it's two steps rather than one: the Reviewer first runs its own free-form ReAct loop — reading the diff via `readDiffTool`, reasoning about it in whatever unstructured way the model finds natural — and *only then* does a second, separate call force that accumulated reasoning into the `ReviewVerdictSchema` shape via `withStructuredOutput`. This mirrors Part 4's Planner pattern exactly: `withStructuredOutput` as a distinct, final step, rather than hoping the tool-calling loop's own final message happens to already be cleanly parseable JSON. The reason this separation matters: forcing structured output *and* tool-calling in the same call constrains the model in two different ways simultaneously, and models are more reliable at each constraint in isolation. Letting the Reviewer reason and investigate freely first, then asking it to *summarize* that investigation into a fixed shape as a distinct final act, tends to produce a more faithful verdict than trying to force structure onto every single intermediate reasoning step along the way.

Also worth flagging: `ReviewVerdictSchema.parse({ ...verdict, taskId: submission.taskId })` explicitly overwrites whatever `taskId` the structured call itself produced with the *known-correct* `taskId` from the input `submission`. That's a small but meaningful defensive detail — it's cheap insurance against the model hallucinating or mistyping the task ID inside its own structured output, by simply not trusting the model to correctly echo back a value the calling code already has authoritative access to. Never let a model regenerate a value your own code already knows for certain.

## 7. The Planner Orchestrating Both Agents

This is where the three-agent system actually becomes a *system* rather than three independent pieces — and notice the specific shape of what makes it one: the Planner is the *only* agent aware both the Coder and Reviewer exist. Neither the Coder nor the Reviewer is aware of the other, or of the Planner, and that mutual unawareness is not a limitation to work around — it's the isolation principle from Part 9a, section 2 enforced structurally, not just by convention. The Coder's entire world, from inside its own graph, is "here is a task, produce a submission." The Reviewer's entire world is "here is a submission, produce a verdict." Only the Planner holds the knowledge that these two calls are related steps in one larger workflow — exactly the way, in a well-designed microservice architecture, an individual service often has no idea which other services are calling it or in what larger business process it's participating; only the orchestrating layer holds that context.

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

Notice this function imports *only* `runCoderAgent` and `runReviewerAgent` — the public boundary functions from each agent's `index.ts`, per Part 9a section 5's rule — and nothing from either agent's internal graph, state, or tools. The Planner's orchestration logic is written entirely against the shared contracts from `contracts.ts`; it has no idea, and no need to know, that the Coder runs on `gpt-4o-mini` with one write-only tool while the Reviewer runs on `gpt-4o` with one read-only tool. That opacity is exactly what the boundary was built to guarantee back in Part 9a, and here's the payoff made visible: you could completely rewrite either agent's internals — swap models, add tools, change the reasoning strategy — and this orchestration function would not need to change a single line, as long as the contract shapes stay the same.

Trace the flow deliberately: Coder produces a submission, Reviewer produces a verdict, and on rejection, the Planner feeds `verdict.blockingIssues` back into the *next* round's `instructions` — exactly as Part 5's `refineNode` fed Critique's `issues` array back into a regeneration call, now happening across a genuine process/agent boundary instead of within a single graph's refine loop. The mechanism is identical; only the distance between "critique" and "regenerate" has changed, from adjacent nodes in one graph to two separate agents coordinated by a third. `MAX_REVISION_ROUNDS` is the same hard-stop-in-code discipline from every prior Part — Part 1's step ceiling, Part 4's plan-length cap and re-plan cap, Part 5's refinement cap — now guarding against an unfixable code task cycling between Coder and Reviewer forever, each round consuming a full round-trip of two separate agent invocations rather than one refinement call, making an uncapped version of this loop considerably more expensive to leave unguarded than any single-agent equivalent.

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

Look closely at what this function does and doesn't reinvent: it reuses Part 6's exact n8n webhook pattern — a plain `fetch` POST to a configured webhook URL, with a guard clause refusing to proceed silently if the destination isn't configured (mirroring Part 1's `model.ts` "refuse to start with no credentials" instinct, applied here as "refuse to escalate into the void with no destination"). That reuse is the point of this section, not an incidental similarity: escalation is structurally *just another external action*, no different in kind from Part 2's notification tool or Part 6's refund workflow. It belongs behind the exact same n8n action layer as any other side effect, rather than earning its own bespoke escalation infrastructure. The `reason` field in the payload — `"coder_reviewer_max_rounds_exhausted"` — is a small but important detail: it gives whoever's building the n8n workflow on the receiving end (and whoever eventually reads the resulting Slack message or ticket) a machine-readable, filterable category for *why* this particular escalation happened, distinct from Part 5's single-agent escalation reason and distinct from whatever other escalation triggers might exist elsewhere in a larger system.

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

Pass the same handler instance into `runCoderAgent`'s and `runReviewerAgent`'s underlying `invoke` calls — meaning both agents' `index.ts` boundary functions need a small extension beyond what Part 9a showed, to accept and forward an optional callback handler through to their respective `compiledCoderAgent.invoke(...)` / `compiledReviewerAgent.invoke(...)` calls. Once that's wired through, one `orchestrationId`, generated by the Planner at the start of `orchestrateCodeTask`, ties all three agents' traces — Coder's reasoning and tool calls, Reviewer's reasoning and tool calls, and (if instrumented) the orchestration loop itself — into a single reviewable session in Langfuse, exactly the grouping mechanism Part 7, section 4 described `sessionId` as providing for a single agent, now doing the same job across three independently-running graphs.

This satisfies Appendix C's audit-logging requirement across what is, underneath the shared repository, a genuinely multi-process architecture in spirit — and it's worth stating plainly why this matters more here than in any single-agent Part so far: without a shared `orchestrationId`, debugging a rejected code task would mean separately locating a Coder trace and a Reviewer trace in Langfuse, with no built-in way to know they belonged to the same review round, let alone the same overall task across multiple rounds. The `metadata: { multiAgent: true }` tag additionally lets you filter Langfuse's dashboard down to just multi-agent traffic — useful once this pattern coexists with the single-agent systems from Parts 1-8 in the same Langfuse project, so cost and latency analysis doesn't accidentally conflate two architecturally different workloads.

## 10. Exercise Challenge

`orchestrateCodeTask`, as written in section 7, always runs the full Coder-then-Reviewer sequence on every round — including the *revision* rounds, where the Coder is essentially being asked to make a small, mechanical fix (say, removing an unused import the Reviewer flagged) and then the *entire* expensive review cycle runs again from scratch. For a trivial one-line fix, that's a lot of machinery — a full Coder agent invocation (its own ReAct loop, however short) plus a full Reviewer agent invocation (its own ReAct loop plus a structured-output call) — to resolve something that doesn't actually require either agent's judgment at all. Add a heuristic so mechanical issues can be fixed deterministically rather than paying for another full Coder invocation.

Before jumping to the solution, connect this to a pattern that's now recurred across nearly every Part in this series: Part 3's cheap-heuristic-first memory-write gate, Part 6's "push solved problems into plain code" retry logic, and now this. The shape is always the same — identify the subset of cases where a judgment call is actually unnecessary, because a fixed, deterministic transformation reliably solves them, and route only the genuinely ambiguous remainder through the expensive reasoning path.

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

Notice `isMechanicalOnly` requires *every* issue in `blockingIssues` to match one of the mechanical patterns (`.every(...)`), not just *some* of them — a deliberate, conservative choice. If a review comes back with a mix of one mechanical issue and one genuine correctness bug, this check correctly falls through to the normal, full Coder-reinvocation path, rather than attempting a partial mechanical fix and hoping the correctness bug goes unaddressed. Notice too that even the mechanical-fix path still calls `runReviewerAgent` again afterward (`revalidation`) — the deterministic `applyMechanicalFixes` step is trusted to make the specific, narrow edit, but it is explicitly *not* trusted to know, on its own, that the edit actually resolved the issue to the Reviewer's satisfaction. That re-check is cheap insurance in the same spirit as section 6's `ReviewVerdictSchema.parse` overwrite of `taskId`: never assume a shortcut worked without confirming it, even when the shortcut itself is simple and well-tested.

Why this belongs here, stated as the general principle one more time, now at its third distinct layer of the series: the same instinct from Part 6 applied one level up the stack — deterministic work should never be routed through a model call, and that's true whether the "model call" in question is a single LLM invocation (Part 6's retry-backoff example) or an entire agent's full reasoning loop (this example). A full Coder invocation to fix a missing semicolon is the multi-agent equivalent of routing exponential backoff through an LLM decision — both spend a disproportionate amount of latency, cost, and non-determinism on a problem with one obviously correct, mechanical answer. Reserve the Coder's reasoning — and the org's budget, per Part 8's cost guard — for issues that genuinely need it, and let plain code handle everything that doesn't.

## Multi-Agent Boundary Checklist (complete)

Extending Part 9a's running checklist with what this half of the Part adds:

- **Keep each new agent's graph boring.** The Reviewer's graph is structurally identical to the Coder's — differing only in prompt, tools, and model — because reusing Part 1's Reason/Act shape per role is the entire value of having established it once.
- **Size the state schema to the role**, not to a copy-pasted template — a lean `ReviewerState` with no step counter documents, by its shape alone, that this role doesn't need one.
- **Separate free reasoning from forced structure**, as `runReviewerAgent` does — let the agent investigate naturally first, then force a final structured verdict as a distinct closing step.
- **Never let a model re-supply a value your own code already knows for certain** — overwrite it explicitly, as `taskId` is overwritten after the structured call.
- **Only the orchestrator knows the whole picture.** Coder and Reviewer stay mutually unaware by construction; only the Planner imports both boundary functions.
- **Cap multi-agent revision rounds even more conservatively than single-agent loops** — each round here costs two full agent invocations, not one refinement call.
- **Route escalation through the same action layer as every other side effect** — it's not a special case, it's n8n receiving one more kind of webhook.
- **Share one correlation ID across every agent in an orchestration**, the same way `sourceAgentRun` and `taskId` have threaded through every cross-boundary handoff in this series.
- **Push mechanical, pattern-matchable fixes into deterministic code**, and re-verify the result with the cheapest possible check — never trust a shortcut silently, even a well-tested one.

## Series Status

With Part 9a, this note, and everything before them, the series now spans a single ReAct agent (Part 1) through a full three-agent Planner/Coder/Reviewer system (Parts 9a-9b), reusing the same state, tool, memory, reflection, tracing, and deployment primitives throughout — nothing in this Part introduced a genuinely new primitive; it recombined and reapplied Parts 1-8's primitives across agent boundaries. Appendix A's Multi-Agent row is no longer hypothetical — it's a built, working reference implementation sitting directly behind this series, with its own contracts, its own isolation guarantees, and its own escalation and observability paths, all traceable back to a decision made for a specific, measured reason rather than adopted as an architectural default.

---

That's the end of the numbered Parts. Next up in the series are the three Appendices — say **"next"** again to continue to **Appendix A: The Agentic Pattern Matrix**.
