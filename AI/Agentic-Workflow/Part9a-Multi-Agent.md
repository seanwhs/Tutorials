# Part 9a: Multi-Agent Orchestration

> Recap: Parts 1-8 built a single, deep agent — one reasoning core, extended with tools, memory, planning, reflection, external action, tracing, and deployment. Every one of those Parts made that one agent better at its job. This Part does something categorically different: it stops trying to make one agent good at everything, and instead splits the job across several agents that are each good at one thing. That's a bigger architectural jump than it might first appear, and Appendix A exists specifically to stop you from taking it before you actually need to.

## 1. The Trigger Condition for This Part

Per Appendix A: do not reach for multi-agent by default. It's worth taking that warning seriously rather than skimming past it, because multi-agent systems are strictly more complex to build, debug, and operate than the single-agent system Parts 1-8 already gave you — more moving parts, more places for a handoff to go wrong, more infrastructure to run. That complexity needs to be earned by a real, specific problem, not adopted because it sounds like the more sophisticated architecture.

This Part exists for the specific, measured case Appendix A establishes: a single agent's system prompt is being asked to hold two genuinely different skills simultaneously — writing code, and adversarially reviewing code for correctness and security — and evidence from Part 7 traces and the Appendix B evaluation framework shows role-mixing is the actual bottleneck, not a tooling or planning gap. Notice how specific that trigger condition is: it's not "code review would be a nice feature to add," and it's not "multi-agent architectures are more impressive." It's a measured finding — from your own Langfuse traces, per the discipline Part 7 built — that one agent trying to be a good author *and* a good adversarial reviewer of its own work, in the same prompt, is producing worse outcomes on one or both of those jobs than the two jobs would produce split apart. That's precisely the kind of self-agreement bias problem Part 5's Critique section named directly: a single prompt trying to hold both "write this well" and "find everything wrong with what I just wrote" is fighting the same psychological tension a human would face doing both jobs at once, and splitting the roles into genuinely separate agents — not just separate turns of one agent, which Part 5 already tried — is the next lever available once prompt-level separation (Part 5) has been tried and measured as insufficient.

The concrete scenario built in this Part: a **Planner** agent receives a feature request, delegates implementation to a **Coder** agent, and routes the Coder's output to a **Reviewer** agent before anything is accepted. It's worth explicitly naming what this generalizes: Part 5's Generator/Critic pattern, which lived as two *nodes* inside one graph, sharing one model, one tool registry, one piece of state — now expanded from two roles in one graph to three fully independent agents, each a complete LangGraph subgraph, with distinct prompts, distinct tools, and potentially distinct models. The pattern that motivated Part 5 (generate, then adversarially critique before accepting) survives completely intact here; what changes is the unit of isolation.

## 2. Why Multi-Agent Is Not Just More Nodes

This is the section to read slowly, because it's the single most common source of confusion when people first build a multi-agent system — the temptation is to think "I'll just add a few more nodes to my existing graph, one for Coder logic, one for Reviewer logic" and call that multi-agent. That's not what this Part builds, and the distinction matters enormously for how failures propagate and how the system can be debugged.

The critical architectural difference from Parts 1-8: each agent here is a complete, independently invokable LangGraph graph, with its own Reason/Act loop, its own tool registry, and potentially its own model — not a single node function living inside a shared graph. The Planner does not call the Coder's *function* directly, the way Part 4's `executeNode` called into shared tooling within one graph; it invokes the Coder's *graph* as a whole and treats the result as an opaque, untyped-until-validated message. That's deliberately analogous to how Part 6 treated n8n as an external system to be called across a boundary, rather than inline code the reasoning layer directly manipulates — the Coder agent, from the Planner's point of view, is exactly as much of a black box as the n8n webhook was, even though both happen to be TypeScript running in the same repository.

Staff Engineer framing, and the lens worth applying to every design decision in the rest of this Part: multi-agent systems are a distributed-systems problem wearing an AI costume. The moment you have more than one independently-reasoning process whose outputs feed into each other, you've acquired every classic distributed-systems concern — service boundaries and what crosses them (section 3), partial failure (one agent succeeding while another fails, or timing out), contract versioning (what happens when the Coder's output shape changes but the Planner still expects the old shape), and the debugging difficulty of a failure that only manifests as an *interaction* between two independently-correct components. None of that is new to AI systems — it's exactly what any team building microservices has had to reckon with for years — but it's easy to lose sight of it when everything is still running in one process, one repository, one deploy, and it feels like "just calling a function." Treat each agent boundary with the same rigor you'd apply to a real network boundary between two services owned by two different teams, even though today they're owned by you and live in the same repo.

## 3. Shared Contracts Between Agents

**src/agents/contracts.ts:**

```typescript
import { z } from "zod";

export const CodeTaskSchema = z.object({
  taskId: z.string(),
  instructions: z.string(),
  constraints: z.array(z.string()).default([]),
});

export const CodeSubmissionSchema = z.object({
  taskId: z.string(),
  files: z.array(z.object({ path: z.string(), content: z.string() })),
  summary: z.string(),
});

export const ReviewVerdictSchema = z.object({
  taskId: z.string(),
  approved: z.boolean(),
  blockingIssues: z.array(z.string()).default([]),
  nonBlockingNotes: z.array(z.string()).default([]),
});

export type CodeTask = z.infer<typeof CodeTaskSchema>;
export type CodeSubmission = z.infer<typeof CodeSubmissionSchema>;
export type ReviewVerdict = z.infer<typeof ReviewVerdictSchema>;
```

Every cross-agent handoff passes through one of these three schemas, never a raw string — this is Part 2's tool-contract discipline (Zod schema as the contract, not prose) applied one level up, at agent-to-agent boundaries instead of agent-to-tool boundaries. It's worth being precise about exactly which failure mode this prevents: the inter-agent miscommunication failure mode, where one agent's free-text output gets loosely re-interpreted by the next agent's prompt, and a subtle misreading compounds silently across hops with no error anywhere in the pipeline — everything looks like it's working, right up until the final output is wrong in a way nobody can trace back to its origin. A schema mismatch, by contrast, fails loudly and immediately — a Zod `.parse()` call throws the moment a Coder's output doesn't conform to `CodeSubmissionSchema`, at the exact boundary where the mismatch occurred, instead of silently propagating a misunderstood instruction three hops downstream into a Reviewer verdict that's confidently wrong about a submission it never actually understood correctly.

Notice too the shape of `taskId` threading through all three schemas — `CodeTaskSchema`, `CodeSubmissionSchema`, and `ReviewVerdictSchema` all carry it. That's the multi-agent equivalent of Part 6's `sourceAgentRun` correlation ID: without a shared identifier threaded through every handoff, there's no way to reconstruct, after the fact, which Reviewer verdict corresponds to which Coder submission corresponds to which original Planner task — three independently-produced pieces of structured data with no way to join them back together. `taskId` is what keeps the whole pipeline traceable end-to-end, exactly the way `sourceAgentRun` kept a LangGraph run traceable across the n8n boundary.

## 4. Role Isolation: Different Tools, Different Models

The Coder and Reviewer must not share a tool registry or a model — and "must not," not "don't need to," because the isolation itself is doing safety work, not just organizational tidiness.

**src/agents/coder/tools.ts:**

```typescript
import { z } from "zod";
import { tool } from "@langchain/core/tools";
import { ok } from "../../tools/types.js";

const WriteFileInput = z.object({
  path: z.string(),
  content: z.string(),
});

export const writeFileTool = tool(
  async (input) => {
    const parsed = WriteFileInput.parse(input);
    return ok({ path: parsed.path, bytesWritten: parsed.content.length });
  },
  {
    name: "write_file",
    description: "Write a file within the sandboxed workspace of the current task.",
    schema: WriteFileInput,
  }
);

export const coderTools = [writeFileTool];
```

**src/agents/reviewer/tools.ts:**

```typescript
import { z } from "zod";
import { tool } from "@langchain/core/tools";
import { ok } from "../../tools/types.js";

const ReadDiffInput = z.object({ taskId: z.string() });

export const readDiffTool = tool(
  async (input) => {
    const parsed = ReadDiffInput.parse(input);
    return ok({ taskId: parsed.taskId, diff: "diff content placeholder" });
  },
  {
    name: "read_diff",
    description: "Read the code diff for a task. Read-only. The Reviewer cannot modify code.",
    schema: ReadDiffInput,
  }
);

export const reviewerTools = [readDiffTool];
```

The Reviewer should not have write access — only read access to diffs — and the crucial detail is *where* that restriction is enforced: at the tool-registry level, not in a prompt instruction telling the Reviewer "please don't modify code." The Reviewer's graph is never bound to `writeFileTool` at all — it isn't imported into `reviewer/tools.ts`, it isn't part of `reviewerTools`, and consequently it never appears in the Reviewer's `bindTools(reviewerTools)` call. That means no prompt injection, no reasoning error, no adversarial input crafted by a malicious code submission under review can make the Reviewer call a tool that was never wired into its own graph in the first place — the capability doesn't exist for that agent to invoke, full stop, structurally, the same way Part 2's `z.literal(true)` made an unconfirmed notification impossible to construct rather than merely discouraged. This is the multi-agent-scale version of the principle that's recurred throughout this entire series: never trust a prompt alone to enforce a hard constraint, enforce it in code — here, "in code" means "in which array gets passed to `bindTools`."

**src/agents/model.ts:**

```typescript
import { ChatOpenAI } from "@langchain/openai";

export function getCoderModel() {
  return new ChatOpenAI({
    model: process.env.CODER_MODEL ?? "gpt-4o-mini",
    temperature: 0,
    apiKey: process.env.AGENT_API_KEY,
    configuration: { baseURL: process.env.AGENT_BASE_URL },
  });
}

export function getReviewerModel() {
  return new ChatOpenAI({
    model: process.env.REVIEWER_MODEL ?? "gpt-4o",
    temperature: 0,
    apiKey: process.env.AGENT_API_KEY,
    configuration: { baseURL: process.env.AGENT_BASE_URL },
  });
}
```

The cost/quality trade-off here is made explicit in code rather than left as an implicit assumption: the Coder runs its ReAct loop potentially many times per task, cheaply, on `gpt-4o-mini`; the Reviewer runs once or twice per task but needs the strongest available judgment, hence `gpt-4o`. This is a direct, deliberate echo of Part 5's framing — Reflection is expensive, so reserve it for the steps where being wrong is costly — now expressed as an actual model-tier choice rather than just a "run this twice" cost. It's worth noticing the two `getModel`-style functions here are structurally identical to Part 1's original `model.ts`, just parameterized separately per role — the same "swap the model in exactly one file" isolation Part 1 established for a single agent now applies independently to each agent in the system, meaning you can tune the Coder's model and the Reviewer's model on entirely separate schedules, based on entirely separate evidence about each role's actual failure modes, without either change touching the other agent's configuration at all.

## 5. The Coder Agent's Graph

Structurally identical to Part 1's graph — genuinely, worth confirming by comparing it line by line against Part 1's `reason.ts`/`act.ts`/`graph.ts` — but scoped entirely to its own state, its own tools, and its own model, per the isolation argued for in section 4.

**src/agents/coder/state.ts:**

```typescript
import { Annotation } from "@langchain/langgraph";
import type { BaseMessage } from "@langchain/core/messages";

export const CoderState = Annotation.Root({
  messages: Annotation<BaseMessage[]>({
    reducer: (current, update) => current.concat(update),
    default: () => [],
  }),
  stepCount: Annotation<number>({
    reducer: (_c, u) => u,
    default: () => 0,
  }),
});
```

**src/agents/coder/graph.ts:**

```typescript
import { StateGraph, END } from "@langchain/langgraph";
import { ToolNode } from "@langchain/langgraph/prebuilt";
import { CoderState } from "./state.js";
import { coderTools } from "./tools.js";
import { getCoderModel } from "../model.js";
import { SystemMessage } from "@langchain/core/messages";

const CODER_SYSTEM_PROMPT = "You are a focused implementation agent. You receive one task at a time. Write minimal, correct code that satisfies the instructions and constraints exactly. Do not add unrequested features.";

async function coderReasonNode(state: typeof CoderState.State) {
  const model = getCoderModel().bindTools(coderTools);
  const response = await model.invoke([
    new SystemMessage(CODER_SYSTEM_PROMPT),
    ...state.messages,
  ]);
  return { messages: [response], stepCount: state.stepCount + 1 };
}

const coderActNode = new ToolNode(coderTools);

const coderGraph = new StateGraph(CoderState)
  .addNode("reason", coderReasonNode)
  .addNode("act", coderActNode)
  .addEdge("__start__", "reason")
  .addConditionalEdges("reason", (state) => {
    const last = state.messages[state.messages.length - 1] as any;
    return last?.tool_calls?.length > 0 ? "act" : END;
  })
  .addEdge("act", "reason");

export const compiledCoderAgent = coderGraph.compile();
```

Notice the `CODER_SYSTEM_PROMPT`'s closing instruction: "Do not add unrequested features." That's not boilerplate — it's the Coder-specific analog of Part 2's scoped tool descriptions ("Use ONLY when...") and Part 6's "what vs. how" boundary, applied to an agent's overall mandate rather than a single tool's applicability. A Coder agent that quietly expands scope — implementing more than what the Planner actually asked for — is producing exactly the kind of unreviewed, unrequested surface area that makes the Reviewer's job harder and the whole system's behavior less predictable. Keeping each agent's mandate as narrow as its role requires is a version of the same discipline Part 4 applied to Executor steps: narrower scope produces more reliable behavior.

**src/agents/coder/index.ts (the public boundary — the only export other agents may import):**

```typescript
import { compiledCoderAgent } from "./graph.js";
import { CodeTaskSchema, CodeSubmissionSchema } from "../contracts.js";
import type { CodeTask, CodeSubmission } from "../contracts.js";
import { HumanMessage } from "@langchain/core/messages";

export async function runCoderAgent(task: CodeTask): Promise<CodeSubmission> {
  const validatedTask = CodeTaskSchema.parse(task);

  const result = await compiledCoderAgent.invoke({
    messages: [
      new HumanMessage(
        "Task: " + validatedTask.instructions + " Constraints: " + validatedTask.constraints.join("; ")
      ),
    ],
  });

  const finalMessage = result.messages.at(-1);
  const submission: CodeSubmission = {
    taskId: validatedTask.taskId,
    files: [],
    summary: String(finalMessage?.content ?? ""),
  };

  return CodeSubmissionSchema.parse(submission);
}
```

The file-level comment — "the only export other agents may import" — is worth treating as an enforced convention, not just a helpful note, and it's the single most important architectural rule in this entire Part. Everything else in `src/agents/coder/` — `CoderState`, `coderReasonNode`, `coderActNode`, `compiledCoderAgent` itself — is an internal implementation detail of the Coder agent, exactly the way a well-designed microservice's internal database schema and business logic are invisible to its callers, who only ever see its public API. `runCoderAgent` is that public API: it validates its input against `CodeTaskSchema` on the way in (`.parse()`, which throws loudly on a malformed task, per section 3's argument), and it validates its output against `CodeSubmissionSchema` on the way out, guaranteeing that whatever the Coder's internal graph did — however many reasoning steps, however many tool calls, whatever the raw message transcript looked like — the *only* thing that ever crosses the boundary to another agent is a value that's been checked against the shared contract.

This is what makes the earlier claim in section 2 concrete rather than just aspirational: the Planner will only ever call `runCoderAgent(task)`, never reach into `compiledCoderAgent` directly, never inspect `CoderState`, never see a raw message array — exactly as it would call a REST endpoint belonging to a service it doesn't own and can't see inside of. If you find yourself, while extending this pattern later, importing anything from `coder/graph.js` or `coder/state.js` directly into the Planner's code, that's the signal the boundary has been violated — the fix is always to add whatever's needed to the contract schema and expose it through `runCoderAgent`'s return value, never to reach around the boundary.

## Multi-Agent Boundary Checklist (so far)

- **Earn multi-agent with measured evidence**, per Appendix A — don't reach for it because a single agent's prompt is getting long, reach for it when traces show a specific role-mixing bottleneck.
- **Each agent is a graph, not a node.** The unit of isolation is a complete, independently invokable LangGraph subgraph, not a function living inside a shared graph.
- **Every cross-agent handoff goes through a shared Zod contract**, never a raw string — the same "make invalid states unrepresentable" instinct from Part 2, now at the agent-to-agent boundary.
- **Thread a shared correlation ID (`taskId`) through every contract** so a multi-hop pipeline stays traceable end to end.
- **Enforce role isolation via tool registry, not prompt instruction.** A capability an agent's graph was never bound to is a capability no reasoning failure can invoke.
- **Expose exactly one public entry point per agent** (`runCoderAgent`, and its Reviewer/Planner equivalents to come), and treat everything else in that agent's directory as a private implementation detail no other agent may import directly.

## Continued in Part 9b

Section 6 onward — the Reviewer agent's graph, the Planner's orchestration graph, full multi-agent control flow, exercise and solution — continues in **"Agentic Workflows - Part 9b: Reviewer, Planner, and Orchestration."**
