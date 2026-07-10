# Part 9a: Multi-Agent Orchestration

## 1. The Trigger Condition for This Part

Per Appendix A: do not reach for multi-agent by default. This Part exists for the specific, measured case established there: a single agent's system prompt is being asked to hold two genuinely different skills simultaneously (writing code, and adversarially reviewing code for correctness and security), and evidence from Part 7 traces and the Appendix B evaluation framework shows role-mixing is the actual bottleneck, not a tooling or planning gap.

The concrete scenario built in this Part: a **Planner** agent receives a feature request, delegates implementation to a **Coder** agent, and routes the Coder's output to a **Reviewer** agent before anything is accepted. This generalizes Part 5's Generator/Critic pattern from two roles in one graph to three independent agents, each a full LangGraph subgraph, with distinct prompts, tools, and models.

## 2. Why Multi-Agent Is Not Just More Nodes

The critical architectural difference from Parts 1-8: each agent here is a complete, independently invokable LangGraph graph, with its own Reason/Act loop, its own tool registry, and potentially its own model — not a single node function. The Planner does not call the Coder's function directly; it invokes the Coder's graph and treats the result as an opaque, untyped-until-validated message, similar to how Part 6 treated n8n as an external system rather than inline code. Staff Engineer framing: multi-agent systems are a distributed-systems problem wearing an AI costume, and the same lessons about service boundaries, contracts, and partial failure apply.

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

Every cross-agent handoff passes through one of these three schemas, never a raw string — prevents the inter-agent miscommunication failure mode: a schema mismatch fails loudly and immediately instead of silently propagating a misunderstood instruction three hops downstream.

## 4. Role Isolation: Different Tools, Different Models

The Coder and Reviewer must not share a tool registry or a model.

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

The Reviewer should not have write access, only read access to diffs — enforced at the tool-registry level. The Reviewer's graph is never bound to `writeFileTool`, so no prompt injection or reasoning error can make it call a tool never wired into its `bindTools` call in the first place.

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

Cost/quality trade-off explicit in code: the Coder runs its ReAct loop many times cheaply; the Reviewer runs once or twice per task but needs the strongest available judgment.

## 5. The Coder Agent's Graph

Structurally identical to Part 1's graph, but scoped entirely to its own state, tools, and model.

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

Note the shape of `runCoderAgent`: accepts a validated `CodeTask`, returns a validated `CodeSubmission`. The internal graph, message history, step count are entirely invisible to callers — the Planner will only ever call `runCoderAgent(task)`, never reach into internals, exactly as it would call a REST endpoint it doesn't control.

## Continued in Part 9b
Section 6 onward (the Reviewer agent's graph, the Planner's orchestration graph, full multi-agent control flow, exercise and solution) continues in **"Agentic Workflows - Part 9b: Reviewer, Planner, and Orchestration."**
