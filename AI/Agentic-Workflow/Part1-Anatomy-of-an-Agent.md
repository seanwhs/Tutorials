# Part 1: The Anatomy of an Agent

## 1. Deterministic vs Probabilistic — where this Part sits

Before any code: an "agent" in this series means a system where an LLM decides, at runtime, what the next action is. That decision-making step is the ReAct loop. Everything else (the graph plumbing, the state schema, the tool interface) exists to make that one probabilistic decision safe, observable, and resumable.

## 2. The ReAct Pattern

ReAct (Reason + Act) is a loop, not a single call:
1. **Reason** — the model produces a thought about what to do next, given the current state and available tools.
2. **Act** — the model emits a tool call (name + arguments).
3. **Observe** — the tool executes; its output is appended to state.
4. Repeat from step 1 until the model decides it has enough information to answer, or a stop condition (max steps, error) is hit.

Staff Engineer note: naive ReAct has no upper bound on steps. Every production ReAct agent needs a hard step ceiling and a cost ceiling — covered in section 6.

## 3. Project Setup

```
pnpm init
pnpm add @langchain/langgraph @langchain/core @langchain/openai zod
pnpm add -D typescript tsx @types/node
```

tsconfig.json (minimal, ESM, Node16 module resolution):
```
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist"
  },
  "include": ["src"]
}
```

Folder structure for the whole series (this is the shape every later Part extends):
```
src/
  agent/
    state.ts        <- graph state schema
    graph.ts         <- StateGraph wiring
    nodes/
      reason.ts
      act.ts
    model.ts         <- swappable LLM client
  tools/
    index.ts
  app/                <- Next.js App Router (introduced Part 6+)
```

## 4. Defining Graph State

LangGraph state is a typed, append-reducible object that flows through every node. Get this wrong and your agent silently drops history — this is the single most common bug in hand-rolled agent loops (why most people reach for LangGraph instead of a plain while-loop).

**src/agent/state.ts:**
```typescript
import { Annotation } from "@langchain/langgraph";
import type { BaseMessage } from "@langchain/core/messages";

export const AgentState = Annotation.Root({
  messages: Annotation<BaseMessage[]>({
    reducer: (current, update) => current.concat(update),
    default: () => [],
  }),
  stepCount: Annotation<number>({
    reducer: (_current, update) => update,
    default: () => 0,
  }),
  maxSteps: Annotation<number>({
    reducer: (_current, update) => update,
    default: () => 6,
  }),
});

export type AgentStateType = typeof AgentState.State;
```

Why a reducer per field, not a plain object merge: LangGraph re-invokes nodes with partial state updates. Without an explicit reducer, a node that returns `{ messages: [newMsg] }` would overwrite the entire history instead of appending to it. The `concat` reducer above is what gives you an append-only transcript — this is your audit log for free, and it is exactly what Part 7 (Observability) reads from.

## 5. The Swappable Model Client

**src/agent/model.ts:**
```typescript
import { ChatOpenAI } from "@langchain/openai";

// OpenAI-compatible client. Point baseURL at Ollama, vLLM, Groq, or OpenAI itself.
// This is the ONLY file that changes when you swap model providers.
export function getModel() {
  return new ChatOpenAI({
    model: process.env.AGENT_MODEL ?? "gpt-4o-mini",
    temperature: 0,
    apiKey: process.env.AGENT_API_KEY ?? "ollama",
    configuration: {
      baseURL: process.env.AGENT_BASE_URL ?? "https://api.openai.com/v1",
    },
  });
}
```

**.env.example:**
```
AGENT_MODEL=gpt-4o-mini
AGENT_API_KEY=sk-...
AGENT_BASE_URL=https://api.openai.com/v1

# Local alternative (Ollama), uncomment to use:
# AGENT_MODEL=llama3.1
# AGENT_API_KEY=ollama
# AGENT_BASE_URL=http://localhost:11434/v1
```

Trade-off called out explicitly: temperature 0 sacrifices creativity for reproducibility. For a ReAct agent whose job is tool selection and reasoning (not creative writing), reproducibility wins — you want the same input to reliably produce the same tool call during testing (see Appendix B).

## 6. The Reason Node and the Act Node

**src/agent/nodes/reason.ts:**
```typescript
import { getModel } from "../model.js";
import type { AgentStateType } from "../state.js";
import { toolDefinitions } from "../../tools/index.js";

export async function reasonNode(state: AgentStateType) {
  if (state.stepCount >= state.maxSteps) {
    // Hard ceiling — this is the guardrail against runaway loops/cost.
    return {
      messages: [
        {
          role: "assistant",
          content: "Step limit reached before a final answer was produced.",
        },
      ],
    };
  }

  const model = getModel().bindTools(toolDefinitions);
  const response = await model.invoke(state.messages);

  return {
    messages: [response],
    stepCount: state.stepCount + 1,
  };
}
```

**src/agent/nodes/act.ts:**
```typescript
import { ToolNode } from "@langchain/langgraph/prebuilt";
import { toolDefinitions } from "../../tools/index.js";

// ToolNode inspects the last AIMessage's tool_calls, executes matching
// tools, and appends ToolMessage results back into state.messages.
export const actNode = new ToolNode(toolDefinitions);
```

## 7. Wiring the Graph

The routing decision (Act vs. END) is expressed as a plain, deterministic function of state — no LLM call inside it. This function is the entire "agentic" branching logic in code form:

**src/agent/graph.ts:**
```typescript
import { StateGraph, END } from "@langchain/langgraph";
import { AgentState, type AgentStateType } from "./state.js";
import { reasonNode } from "./nodes/reason.js";
import { actNode } from "./nodes/act.js";

function routeAfterReason(state: AgentStateType): "act" | typeof END {
  const lastMessage = state.messages[state.messages.length - 1] as any;
  const hasToolCalls =
    lastMessage?.tool_calls && lastMessage.tool_calls.length > 0;
  return hasToolCalls ? "act" : END;
}

const graph = new StateGraph(AgentState)
  .addNode("reason", reasonNode)
  .addNode("act", actNode)
  .addEdge("__start__", "reason")
  .addConditionalEdges("reason", routeAfterReason)
  .addEdge("act", "reason");

export const compiledAgent = graph.compile();
```

Note on the conditional edge: if the model's last message contains tool_calls, route to Act; otherwise the model has decided it's done, and we route to END. Reason is probabilistic (an LLM decides); routeAfterReason is deterministic (a pure function of state). That pairing — probabilistic node, deterministic router — is the core LangGraph design idiom you'll reuse in every later Part.

## 8. Running It

**src/run.ts:**
```typescript
import { compiledAgent } from "./agent/graph.js";
import { HumanMessage } from "@langchain/core/messages";

const result = await compiledAgent.invoke({
  messages: [new HumanMessage("What's 42 * 17, then add 8?")],
});

console.log(result.messages.at(-1)?.content);
```

CLI:
```
pnpm tsx src/run.ts
```

Debugging tip: log `result.messages` in full (not just the last one) to see the entire Reason -> Act -> Reason transcript. This raw transcript is precisely what Part 7's Langfuse integration visualizes automatically instead of you eyeballing console.log output.

## 9. Exercise Challenge

Extend the graph with a second conditional branch: if `stepCount` exceeds `maxSteps - 1` on entry to Reason, skip tool-binding entirely and force the model to answer directly with whatever it has (a "graceful degradation" path, distinct from the hard-stop shown above). This mirrors a real production requirement: never let a user-facing agent return "step limit reached" with no attempt at an answer.

## 10. Solution

```typescript
export async function reasonNode(state: AgentStateType) {
  const nearLimit = state.stepCount >= state.maxSteps - 1;

  const baseModel = getModel();
  const model = nearLimit ? baseModel : baseModel.bindTools(toolDefinitions);

  const messages = nearLimit
    ? [
        ...state.messages,
        {
          role: "system",
          content:
            "You are nearly out of steps. Answer now using only information already gathered.",
        },
      ]
    : state.messages;

  const response = await model.invoke(messages);

  return {
    messages: [response],
    stepCount: state.stepCount + 1,
  };
}
```

Why this works: unbinding tools on the final allowed step removes the possibility of another tool_call being emitted, which means `routeAfterReason` will always return END next — the graceful-degradation path is enforced **structurally by the graph**, not just by prompt instruction. Never trust a prompt alone to enforce a hard constraint; enforce it in code where possible.

## Next
Part 2 replaces the placeholder `toolDefinitions` import used above with real, Zod-validated, type-safe tools — and makes the case for why tool quality, not model quality, is usually the actual bottleneck in agent performance.
