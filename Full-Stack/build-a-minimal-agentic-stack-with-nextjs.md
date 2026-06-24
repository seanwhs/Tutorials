## From Concepts to Code: Building a Minimal Agentic Stack

In this tutorial, we’ll build a small agentic system in Next.js. It will retrieve context from local data, decide when to call a tool, and run through a simple workflow loop before returning an answer.

## Project Setup

Start with a new Next.js app and TypeScript.

```bash
npx create-next-app@latest agentic-starter
cd agentic-starter
npm install zod
```

Use a structure like this:

```txt
/app
  /api/agent/route.ts
  /page.tsx
/lib
  /agent.ts
  /rag.ts
  /tools.ts
/types
  /agent.ts
```

This keeps retrieval, tools, orchestration, and UI cleanly separated from one another.

## Retrieval Layer

First, define a small in-memory knowledge base.

```ts
// lib/rag.ts
const documents = [
  {
    id: 1,
    title: "Next.js",
    text: "Next.js is a React framework for building full-stack apps.",
  },
  {
    id: 2,
    title: "RAG",
    text: "RAG connects LLMs to external knowledge sources.",
  },
  {
    id: 3,
    title: "MCP",
    text: "MCP standardizes how agents connect to external tools and services.",
  },
];

function scoreDocument(query: string, doc: { title: string; text: string }) {
  const q = query.toLowerCase();
  const haystack = `${doc.title} ${doc.text}`.toLowerCase();
  return q.split(/\s+/).filter(token => haystack.includes(token)).length;
}

export async function retrieveContext(query: string) {
  return documents
    .map(doc => ({ ...doc, score: scoreDocument(query, doc) }))
    .filter(doc => doc.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, 3)
    .map(doc => `[${doc.title}] ${doc.text}`);
}
```

This gives the agent a grounded source of context. Later, you can swap this out for embeddings and vector search without changing the rest of the workflow.

## Tool Layer

Next, define the capabilities the agent can call.

```ts
// lib/tools.ts
export type Tool = {
  name: string;
  description: string;
  execute: (input: string) => Promise<string>;
};

export const tools: Tool[] = [
  {
    name: "getTime",
    description: "Returns the current server time in ISO format.",
    execute: async () => new Date().toISOString(),
  },
  {
    name: "reverseText",
    description: "Reverses the provided text.",
    execute: async (input: string) => input.split("").reverse().join(""),
  },
];
```

This keeps actions isolated from the orchestration logic. The agent only needs to know what tools exist and how to invoke them.

## State Model

Keep the agent state explicit so the workflow stays easy to trace.

```ts
// types/agent.ts
export type AgentState = {
  query: string;
  context: string[];
  steps: string[];
  toolResult?: string;
  done: boolean;
};
```

That state object becomes the backbone of the loop, making it easier to inspect, debug, and extend.

## Workflow Orchestration

Now connect retrieval and tools inside a simple loop.

```ts
// lib/agent.ts
import { retrieveContext } from "./rag";
import { tools } from "./tools";
import type { AgentState } from "@/types/agent";

type Decision =
  | { type: "tool"; tool: string; input: string }
  | { type: "final" };

export async function runAgent(query: string) {
  const state: AgentState = {
    query,
    context: [],
    steps: [],
    done: false,
  };

  state.context = await retrieveContext(query);
  state.steps.push(`Retrieved ${state.context.length} context chunk(s).`);

  for (let i = 0; i < 3; i++) {
    const decision = await decideNextStep(state);

    if (decision.type === "tool") {
      const tool = tools.find(t => t.name === decision.tool);

      if (!tool) {
        state.steps.push(`Tool not found: ${decision.tool}`);
        continue;
      }

      const result = await tool.execute(decision.input);
      state.toolResult = result;
      state.steps.push(`Executed ${tool.name}: ${result}`);
      continue;
    }

    if (decision.type === "final") {
      state.done = true;
      return generateFinalAnswer(state);
    }
  }

  return generateFinalAnswer(state);
}

async function decideNextStep(state: AgentState): Promise<Decision> {
  const query = state.query.toLowerCase();

  if (query.includes("time")) {
    return { type: "tool", tool: "getTime", input: state.query };
  }

  if (query.includes("reverse")) {
    return { type: "tool", tool: "reverseText", input: state.query };
  }

  return { type: "final" };
}

function generateFinalAnswer(state: AgentState) {
  return {
    answer: [
      "Answer:",
      state.context.length ? state.context.join("\n") : "No relevant context found.",
      state.toolResult ? `Tool result: ${state.toolResult}` : "",
      state.steps.length ? `\nTrace:\n${state.steps.join("\n")}` : "",
    ]
      .filter(Boolean)
      .join("\n"),
    state,
  };
}
```

This is the core of the tutorial. The agent retrieves context, decides whether to act, and loops until it can answer.

## API Route

Expose the agent through a route handler.

```ts
// app/api/agent/route.ts
import { runAgent } from "@/lib/agent";

export async function POST(req: Request) {
  const body = await req.json();

  if (!body?.query || typeof body.query !== "string") {
    return Response.json({ error: "query is required" }, { status: 400 });
  }

  const result = await runAgent(body.query);
  return Response.json(result);
}
```

This makes the workflow easy to test from a frontend or an API client.

## Minimal UI

Add a tiny interface so readers can try the system end to end.

```tsx
// app/page.tsx
"use client";

import { useState } from "react";

export default function Home() {
  const [query, setQuery] = useState("");
  const [result, setResult] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit() {
    setLoading(true);
    setResult(null);

    const res = await fetch("/api/agent", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query }),
    });

    const data = await res.json();
    setResult(data);
    setLoading(false);
  }

  return (
    <main style={{ padding: 24, maxWidth: 720 }}>
      <h1>Agentic Starter</h1>

      <input
        value={query}
        onChange={e => setQuery(e.target.value)}
        placeholder="Ask something..."
        style={{ width: "100%", padding: 12, marginTop: 16 }}
      />

      <button onClick={handleSubmit} disabled={loading} style={{ marginTop: 12 }}>
        {loading ? "Running..." : "Run Agent"}
      </button>

      <pre style={{ marginTop: 24, whiteSpace: "pre-wrap" }}>
        {result ? JSON.stringify(result, null, 2) : "No result yet."}
      </pre>
    </main>
  );
}
```

This gives the tutorial a clear end-to-end path: query, retrieval, tool call, workflow, response.

## Where To Go Next

Once this baseline works, the next upgrades are straightforward.

- Replace keyword matching with embeddings and vector search.
- Swap the static decision logic for structured model output.
- Move the tool layer into a real external service interface.
- Split the workflow into planner and executor agents.
- Add persistence so the agent can continue across requests.

That progression keeps the tutorial practical while still pointing readers toward production-grade patterns.
