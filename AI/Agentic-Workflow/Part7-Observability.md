# Part 7: Observability & Tracing

> Recap: Parts 1-6 built a genuinely complex system — a reflective, plan-capable, memory-grounded agent that can reach out into external infrastructure via n8n. That complexity was worth it, but it comes due here. This Part is about paying down the debt of "how do I actually know what this thing did," which every prior Part has been quietly deferring with a comment along the lines of "this is what Part 7 will visualize."

## 1. Why "console.log the messages array" Stops Working

Parts 1-6 built systems where a single user request can fan out into: multiple Reason/Act cycles (Part 1), a Planner call and several Executor calls (Part 4), a Critique/Refine loop (Part 5), and an outbound n8n call (Part 6) — potentially all in service of one user message. Debugging that by reading raw message arrays, the way Part 1's "debugging tip" suggested when the system was still simple, does not scale past a handful of runs. It didn't even fully scale within Part 1 once you introduced tool calls; by Part 6, a printed `messages` array is a flat, chronological list that has completely lost the *structure* of what happened — which calls were nested inside which, which node incurred which cost, which step took how long.

A real tracer gives you three things a flat log fundamentally cannot: (1) a **hierarchical view** of nested calls — Plan containing Executes containing Acts, for instance — rendered as an actual tree rather than reconstructed by eye from indentation or timestamps; (2) **per-call token counts and cost**, attributed to the specific model invocation that incurred them, not just a single end-of-run total; and (3) **latency broken down by node**, so "the request took 8 seconds" becomes "Critique took 3.2 of those 8 seconds," which is an actionable finding and not just a fact.

Staff Engineer framing, worth sitting with because it explains why this Part exists at all rather than being an optional nice-to-have appendix: observability for agents is the *only* way to answer "why did the agent do that" after the fact. This is a structurally different debugging problem than debugging deterministic code. For a probabilistic system, the exact same code, given the exact same input, can produce a different decision on a different day — a different tool call, a different critique verdict, a different plan. You cannot re-run the code in your head, or even in a debugger, and expect to reliably reproduce what actually happened in a specific historical run. You need the actual historical trace of that specific run, because it is, in a very real sense, the only complete record of the decision that was actually made.

## 2. Why Langfuse (Self-Hosted) Over LangSmith

LangSmith's self-serve tier is capped and the product is closed-source. Langfuse is fully open-source (MIT-licensed core) and self-hostable via Docker Compose, with first-class LangChain/LangGraph JS integration — meaning the instrumentation work in section 4 below is close to automatic rather than something you build by hand.

The trade-off is worth stating in the same terms Part 3 used for pgvector and Part 6 used for n8n, because it's the same underlying trade-off recurring for a third time in this series: you operate the tracing infrastructure yourself — another Docker Compose service, another Postgres database, another thing that can go down — versus a SaaS product you'd just log into with none of that operational burden. This is consistent with the series' portability-over-convenience bias, stated explicitly here rather than left as an unexamined preference: every piece of infrastructure this series has reached for (Postgres for both relational data and vectors in Part 3, n8n for workflow orchestration in Part 6, and now Langfuse for tracing) is self-hostable, open, and swappable, at the cost of you — not a vendor — being responsible for keeping it running. That's a deliberate choice about what kind of system this series is teaching you to build, not an accident of which tools happened to get picked first.

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

```bash
docker compose up -d langfuse-db langfuse
```

Open `http://localhost:3001`, create an account/org/project, and generate a Public Key + Secret Key. Note that `langfuse-db` here is a *separate* Postgres instance from Part 3's `pgvector`-enabled one — a deliberate separation, not an oversight. Your application's long-term memory and your tracing infrastructure's operational data have different backup policies, different access-control needs, and different growth patterns (trace volume tends to scale with request volume, not with how much the agent has learned), and collapsing them into one database would couple two systems that have no real reason to be coupled. As with Part 6's `N8N_BASIC_AUTH_PASSWORD`, treat `NEXTAUTH_SECRET` and `SALT` exactly as their `changeme-` prefixes warn: real, randomly generated secrets, injected via environment configuration, before this runs anywhere beyond your local machine.

**.env additions:**

```
LANGFUSE_PUBLIC_KEY=pk-lf-...
LANGFUSE_SECRET_KEY=sk-lf-...
LANGFUSE_BASE_URL=http://localhost:3001
```

## 4. Instrumenting the LangGraph Agent

```bash
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

This file follows the exact same shape as Part 1's `model.ts` and, in spirit, Part 6's tool-swap pattern: one small factory function that isolates a piece of third-party configuration behind a clean interface, so nothing else in the codebase needs to know the details of how the Langfuse client is constructed. `sessionId` is what lets Langfuse group multiple traces — potentially multiple separate user turns — under one conversation; `userId` is what lets you later filter or aggregate metrics per user, which matters the moment you're running this for more than one person and want to know, say, whether a specific user's traffic pattern is unusually expensive.

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

Compare this to Part 1's `run.ts` — the invocation itself is essentially unchanged; the only addition is a second argument, `{ callbacks: [langfuseHandler] }`, passed alongside the existing input. That minimal footprint is the actual headline of this section: because LangGraph nodes are built from LangChain primitives throughout this series — every `model.invoke(...)` call in Reason, Execute, Critique, and Refine, every `ToolNode` invocation in Act — the callback handler automatically captures every model call, every tool invocation, and their nesting, with zero manual instrumentation inside any of those nodes. Reason → Act → Reason (Part 1), Plan → Execute → Critique → Refine (Parts 4-5) — all of it shows up as a nested trace tree in the Langfuse UI, for the cost of one constructor call and one extra argument at the top-level `invoke`. This is what "first-class LangChain integration," named in section 2, actually buys you in practice: instrumentation that would otherwise require hand-wiring a span around every single node, made close to free because every node was already built on the framework's own primitives from Part 1 onward.

## 5. Manual Spans for Non-LangChain Work

The one place that automatic coverage runs out: Part 6's raw `fetch` call to n8n. It's a plain HTTP request, written directly against the Fetch API rather than through any LangChain abstraction, precisely because — as Part 6 argued — that call is deliberately *outside* LangGraph's reasoning layer, crossing into "how," not "what." That same architectural boundary that made the Part 6 design correct is exactly what makes it invisible to automatic tracing here — it isn't routed through LangChain's callback system, so it needs to be instrumented explicitly.

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

Notice the shape here mirrors the automatic instrumentation conceptually even though it's manual: a span is opened with an explicit `name` and `input` right before the boundary-crossing call, and explicitly closed with `.end(...)` on both the success and failure paths — including tagging the failure path with `level: "ERROR"`, which is what lets you later filter a Langfuse view down to just the failed spans without having to eyeball every trace. This closes the observability gap identified back in Part 6: `sourceAgentRun` in the n8n payload (Part 6, section 6) gives you a correlation ID on the n8n side of the boundary, and this span gives you a correlation point on the LangGraph side — together, they let you trace a single notification action end-to-end, from the moment the model decided to send it, through the retry-wrapped HTTP call, to the n8n workflow execution that actually delivered it. Neither half alone would be enough; the whole point of a correlation ID is that it's useless without something on both ends to correlate.

## 6. What to Actually Look At: Token Usage and Latency Breakdown

Having the data is only useful if you know what to look for in it. Two views are worth making a habit of checking, not just once but as an ongoing practice:

- **Trace waterfall view** — wall-clock time per node, laid out visually against the total request duration. A common finding once you have real traffic flowing through Part 5's reflective graph: Critique accounts for 40%+ of total latency. That's not a bug to fix reflexively — it's the concrete, measured cost of the reliability trade-off Part 5 argued for in the abstract ("doubling, or more, of token spend and latency per action"). Seeing the actual number is what turns that trade-off from a theoretical warning into a specific, tunable design decision: is 40% of latency an acceptable price for the reliability gain, for *this* use case, or is it a sign Reflection is being applied more broadly than section 1 of Part 5 recommended?
- **Token usage by generation** — Langfuse tags each individual LLM call with prompt and completion tokens automatically, not just an aggregate per run. A frequent finding worth actively watching for: Critique's context — which re-sends recent messages as part of its evaluation, per Part 5 section 3's `...state.messages.slice(0, -1)` — silently grows expensive over long conversations, since it's paying the token cost of the accumulated transcript on every single critique pass, not just once. This is a direct, empirical validation of Part 3's `windowForModel` trimming as a genuine cost control rather than a hypothetical one: if you see Critique's token counts climbing steadily across a long-running conversation, that's the exact failure mode `windowForModel` was built to prevent, and it's worth confirming the trimming boundary is actually being applied consistently everywhere a full transcript gets sent to a model — including inside Critique's own message construction, which is worth auditing specifically, since Part 5's `critiqueNode` as written doesn't call `windowForModel` at all.

## 7. Setting Up Alerts on Cost/Latency Outliers

Dashboards you have to remember to check are a weaker safety net than alerts that come to you. n8n workflow: "Agent Cost Watchdog" — and notice this is n8n being used for exactly the kind of job Part 6, section 1 said it was best suited for: a fixed, human-writable-blind flowchart with no dependence on interpreting model reasoning.

1. **Schedule node** — every 15 minutes.
2. **HTTP Request node** — `GET {LANGFUSE_BASE_URL}/api/public/metrics` filtered to last 15 min, Basic Auth with Langfuse keys.
3. **Function node** — sum `totalCost`; compare against threshold (see Appendix C).
4. **IF node** — if over threshold, continue.
5. **Slack/Email node** — alert on-call with figure + dashboard link.

This feeds directly into Appendix C's "cost caps" requirement, and it's worth being precise about why a cap without this workflow is close to worthless: a documented cost cap that nobody is actively watching is a policy, not a control. Part 1's hard step ceiling and Part 5's refinement ceiling both work because they're enforced *in the code path itself*, at the moment a decision would otherwise be made — the code cannot proceed past the ceiling. A cost cap, by contrast, is typically a soft, aggregate constraint ("don't spend more than $X per day across all runs") that no single node in the graph can enforce on its own, because no single run knows the total spend of every other concurrent run. That's precisely the kind of constraint that needs an external watchdog rather than an in-graph guardrail — a cap is meaningless without a mechanism that watches it, and this n8n workflow is that mechanism.

## 8. Exercise Challenge

Add a custom Langfuse "score" to every trace that ran through Part 5's Critique node, recording whether the final output passed on the first attempt or required refinement — a "first-pass success rate" metric.

Before implementing it, think about why this specific metric, and not some more generic "did the run succeed" score. A run can succeed — end with `verdict: "pass"` — either because the very first candidate was already good, or because it took one or two refinement passes to get there. Both outcomes look identical from outside the system: the user gets a passing answer either way. But they represent very different underlying realities about how well the *generation* step (Reason, Execute) is performing on its own, versus how much load-bearing work Reflection is quietly doing to compensate for weaker first attempts. Collapsing both into one "success" number would hide exactly the distinction you need to make good decisions about where to invest next.

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

The condition itself is worth reading precisely: `state.refinementCount === 0 && critique.verdict === "pass"` scores `1` only when *both* the current critique passed *and* no refinement had happened yet at the point of this check — meaning the very first candidate, with zero corrective passes, was judged acceptable. Any run that needed even one refinement pass, even if it ultimately passed, scores `0` on this metric — deliberately, because "eventually passed after correction" and "passed immediately" are exactly the two outcomes section 8 argued need to stay distinguishable.

Why this metric specifically, and how to read it once you have weeks of it accumulating: it tells you, over real production traffic, whether Part 5's Reflection layer is earning its latency and cost tax, in a much more actionable way than the waterfall view in section 6 alone. Consistently 95%+ means Critique is mostly confirming already-good output — which raises a legitimate question of whether the reliability gain is worth the roughly-doubled cost Part 5 flagged, for this particular use case, or whether Reflection could be selectively disabled for lower-stakes request types. A first-pass success rate around 60%, by contrast, means Critique is doing real, load-bearing correction work on a majority of runs — and *that* result should point your next engineering effort somewhere specific: not toward removing Reflection (it's clearly earning its cost here), but toward improving the quality of the first-pass generation itself — better tool descriptions (Part 2's checklist), better grounding (Part 3's memory thresholds), better planning (Part 4's tool-aware Planner) — so that fewer runs need the expensive corrective pass in the first place. The metric doesn't just measure Reflection; read correctly, it tells you whether to invest in Reflection or in everything upstream of it.

## Observability Checklist

- **Trust traces over transcripts once the graph has more than one loop.** A flat `messages` array loses the structure a tracer preserves.
- **Let framework-native instrumentation do the automatic work**, and reserve manual spans for exactly the boundaries that step outside the framework — like Part 6's raw `fetch` to n8n.
- **Correlate across systems deliberately.** A span on one side of a boundary and a correlation ID on the other are only useful together, never alone.
- **Read cost/latency findings as validation, not just diagnostics.** A Critique-heavy waterfall confirms Part 5's stated trade-off; a growing token count under long conversations flags exactly the failure mode Part 3's trimming exists to prevent.
- **Enforce aggregate limits (cost caps) with an external watchdog**, not an in-graph ceiling — no single run can see total concurrent spend, so no single node can enforce a global cap.
- **Design custom metrics to separate outcomes that look identical from outside but mean different things internally** — first-pass success vs. eventual success being the clearest example here.

## Next

Part 8 takes this fully-instrumented, hybrid, reflective agent system and makes it deployable: containerization, environment/secret management, API key rotation, and lifecycle governance for running this in production on a plain VPS.
