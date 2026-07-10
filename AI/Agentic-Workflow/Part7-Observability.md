# Part 7: Observability & Tracing

## 1. Why "console.log the messages array" Stops Working

Parts 1-6 built systems where a single user request can fan out into: multiple Reason/Act cycles, a Planner call, several Executor calls, a Critique/Refine loop, and an outbound n8n call. Debugging that by reading raw message arrays does not scale past a handful of runs. A real tracer gives you: (1) a hierarchical view of nested calls, (2) per-call token counts and cost, and (3) latency broken down by node, not just end-to-end.

Staff Engineer framing: observability for agents is the only way to answer "why did the agent do that" after the fact — for a probabilistic system, the exact same code can produce a different decision on a different day. You need the actual historical trace.

## 2. Why Langfuse (Self-Hosted) Over LangSmith

LangSmith's self-serve tier is capped and the product is closed-source. Langfuse is fully open-source (MIT-licensed core) and self-hostable via Docker Compose, with first-class LangChain/LangGraph JS integration. Trade-off: you operate the tracing infrastructure yourself versus a SaaS you'd just log into — consistent with the series' portability-over-convenience bias.

## 3. Langfuse Setup

**docker-compose.yml:**
```yaml
services:
  langfuse-db:
    image: postgres:16
    environment:
      POSTGRES_USER: langfuse
      POSTGRES_PASSWORD: langfuse
      POSTGRES_DB: langfuse
    volumes:
      - langfuse_db:/var/lib/postgresql/data

  langfuse:
    image: langfuse/langfuse:latest
    depends_on:
      - langfuse-db
    ports:
      - "3001:3000"
    environment:
      - DATABASE_URL=postgresql://langfuse:langfuse@langfuse-db:5432/langfuse
      - NEXTAUTH_SECRET=changeme-generate-a-real-secret
      - NEXTAUTH_URL=http://localhost:3001
      - SALT=changeme-generate-a-real-salt

volumes:
  langfuse_db:
```

```
docker compose up -d langfuse-db langfuse
```

Open http://localhost:3001, create an account/org/project, and generate a Public Key + Secret Key.

**.env additions:**
```
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_BASE_URL=http://localhost:3001
```

## 4. Instrumenting the LangGraph Agent

```
pnpm add langfuse-langchain
```

**src/agent/observability.ts:**
```typescript
import { CallbackHandler } from "langfuse-langchain";

export function getLangfuseHandler(sessionId: string, userId?: string) {
  return new CallbackHandler({
    publicKey: process.env.LANGFUSE_PUBLIC_KEY,
    secretKey: process.env.LANGFUSE_SECRET_KEY,
    baseUrl: process.env.LANGFUSE_BASE_URL,
    sessionId,
    userId,
  });
}
```

**src/run.ts (updated):**
```typescript
import { compiledReflectiveAgent } from "./agent/graph.reflect.js";
import { getLangfuseHandler } from "./agent/observability.js";
import { HumanMessage } from "@langchain/core/messages";

const langfuseHandler = getLangfuseHandler("session-123", "user-abc");

const result = await compiledReflectiveAgent.invoke(
  { messages: [new HumanMessage("Refund order ORD-000123, then notify the customer.")] },
  { callbacks: [langfuseHandler] }
);

console.log(result.messages.at(-1)?.content);
```

Because LangGraph nodes are built from LangChain primitives throughout this series, the callback handler automatically captures every model call, every tool invocation, and their nesting — Reason → Act → Reason, Plan → Execute → Critique → Refine, all show up as a nested trace tree with zero manual span creation.

## 5. Manual Spans for Non-LangChain Work

Part 6's raw `fetch` call to n8n isn't routed through LangChain's callback system — instrument it explicitly.

**src/tools/notify.ts (add tracing):**
```typescript
import { getLangfuseHandler } from "../agent/observability.js";

// Inside notifyTool's execute function, wrap the n8n call:
const trace = getLangfuseHandler("session-123").client;
const span = trace.span({ name: "n8n-notify-webhook", input: parse.data });
try {
  const res = await withRetry(() => fetch(N8N_WEBHOOK_URL, { /* ... */ }));
  const body = await res.json();
  span.end({ output: body });
  return ok(body);
} catch (err) {
  span.end({ output: { error: (err as Error).message }, level: "ERROR" });
  return fail(`Failed to reach n8n: ${(err as Error).message}`, true);
}
```

This closes the observability gap identified in Part 6: `sourceAgentRun` in the n8n payload plus this span together let you trace an action end-to-end.

## 6. What to Actually Look At: Token Usage and Latency Breakdown

- **Trace waterfall view** — wall-clock time per node. Common finding: Critique accounts for 40%+ of total latency, the concrete measured cost of Part 5's reliability trade-off.
- **Token usage by generation** — Langfuse tags each LLM call with prompt/completion tokens automatically. Frequent finding: Critique's context (re-sends recent messages) silently grows expensive over long conversations — directly validating Part 3's `windowForModel` trimming as a cost control.

## 7. Setting Up Alerts on Cost/Latency Outliers

n8n workflow: "Agent Cost Watchdog"
1. **Schedule node** — every 15 minutes.
2. **HTTP Request node** — `GET {LANGFUSE_BASE_URL}/api/public/metrics` filtered to last 15 min, Basic Auth with Langfuse keys.
3. **Function node** — sum `totalCost`; compare against threshold (see Appendix C).
4. **IF node** — if over threshold, continue.
5. **Slack/Email node** — alert on-call with figure + dashboard link.

This feeds directly into Appendix C's "cost caps" requirement — a cap is meaningless without a mechanism that watches it.

## 8. Exercise Challenge

Add a custom Langfuse "score" to every trace that ran through Part 5's Critique node, recording whether the final output passed on the first attempt or required refinement — a "first-pass success rate" metric.

## 9. Solution

```typescript
import { getLangfuseHandler } from "../observability.js";

export async function critiqueNode(state: AgentStateType) {
  // ...existing critique logic...

  const handler = getLangfuseHandler("session-123");
  await handler.client.score({
    traceId: handler.getTraceId?.() ?? "unknown",
    name: "first_pass_success",
    value: state.refinementCount === 0 && critique.verdict === "pass" ? 1 : 0,
  });

  return { lastCritique: critique };
}
```

Why this metric specifically: it tells you, over weeks of production traffic, whether Part 5's Reflection layer is earning its latency/cost tax. Consistently 95%+ means Critique is mostly confirming good output; 60% means it's doing real, load-bearing work — and low numbers signal investing in better upstream prompting/tool descriptions rather than leaning more on Reflection.

## Next
Part 8 takes this fully-instrumented, hybrid, reflective agent system and makes it deployable: containerization, environment/secret management, API key rotation, and lifecycle governance for running this in production on a plain VPS.
