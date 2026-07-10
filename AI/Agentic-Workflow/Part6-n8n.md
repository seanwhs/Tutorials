# Part 6: Visual Orchestration with n8n

## 1. LangGraph vs n8n — the Actual Decision Criteria

Not "which is better" — they solve different problems:

| Dimension | LangGraph (code-first) | n8n (visual) |
|---|---|---|
| Best for | Branching logic driven by model reasoning | Fixed integration sequences to external systems |
| Change cadence | Changes with prompt/logic iteration (frequent) | Changes with which SaaS tools you integrate (infrequent) |
| Who edits it | Engineers | Engineers AND non-engineers (ops, support leads) |
| Debuggability | Stack traces, structured logs, Langfuse traces | Visual execution log, per-node input/output inspector |
| Failure mode if wrong | Bad reasoning, hallucinated tool args | Misconfigured credential, wrong field mapping |

Staff Engineer rule: if a human could write the flowchart for a process without needing to know what the AI said, it belongs in n8n. If the next step genuinely depends on interpreting ambiguous natural-language intent, it belongs in LangGraph. Most real systems need both — the mistake is picking one and forcing the other's job into it.

## 2. The Hybrid Architecture

Reasoning stays in LangGraph (Parts 1-5). Actions with external side effects move to n8n, invoked via webhook from a LangGraph tool.

```
User request
     |
     v
LangGraph (Reason/Plan/Critique) -- decides WHAT to do
     |
     v  (tool call: "trigger_n8n_workflow")
n8n webhook -- decides HOW to do it (deterministic steps: auth, API calls, retries, field mapping)
     |
     v
External system (Slack, CRM, email provider, ticketing system)
```

## 3. n8n Setup

**docker-compose.yml:**
```yaml
services:
  n8n:
    image: n8nio/n8n:latest
    ports:
      - "5678:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=changeme
      - WEBHOOK_URL=http://localhost:5678/
    volumes:
      - n8n_data:/home/node/.n8n

volumes:
  n8n_data:
```

```
docker compose up -d n8n
```

Open http://localhost:5678, complete setup, then create a new workflow.

## 4. Building the n8n "Action" Workflow

Workflow: "Send Customer Refund Notification":

1. **Webhook node** — trigger, POST, path `/agent-notify`.
2. **Set node** — validate/normalize incoming fields (`recipient`, `message`, `sourceAgentRun`).
3. **IF node** — branch on `recipient` domain if different providers are used per audience.
4. **HTTP Request / Email node** — the actual send (SMTP, Slack, Twilio nodes — n8n ships maintained nodes so you don't hand-roll OAuth/retry logic).
5. **Respond to Webhook node** — return `{ "status": "sent", "id": "<provider message id>" }` so LangGraph gets a real confirmation.

Export as JSON and check it into your repo (`infra/n8n/agent-notify.json`) — treat n8n workflows as versioned infrastructure.

## 5. The LangGraph Tool That Calls n8n

Replaces Part 2's mocked `notifyTool` — schema/gating stays identical, only the execution body changes.

**src/tools/notify.ts (n8n-backed version):**
```typescript
import { z } from "zod";
import { tool } from "@langchain/core/tools";
import { ok, fail } from "./types.js";

const NotifyInput = z.object({
  recipient: z.string().email(),
  message: z.string().min(1).max(500),
  confirmed: z.literal(true),
});

const N8N_WEBHOOK_URL =
  process.env.N8N_NOTIFY_WEBHOOK_URL ?? "http://localhost:5678/webhook/agent-notify";

export const notifyTool = tool(
  async (input, runConfig) => {
    const parse = NotifyInput.safeParse(input);
    if (!parse.success) {
      return fail(
        "Notification blocked: requires explicit user confirmation (confirmed=true).",
        false
      );
    }

    try {
      const res = await fetch(N8N_WEBHOOK_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          recipient: parse.data.recipient,
          message: parse.data.message,
          sourceAgentRun: runConfig?.runId ?? "unknown",
        }),
        signal: AbortSignal.timeout(8000),
      });

      if (!res.ok) {
        return fail(`n8n workflow returned ${res.status}`, res.status >= 500);
      }

      const body = await res.json();
      return ok(body);
    } catch (err) {
      return fail(`Failed to reach n8n: ${(err as Error).message}`, true);
    }
  },
  {
    name: "send_notification",
    description:
      "Send a notification via the n8n-managed delivery workflow. IRREVERSIBLE — requires confirmed=true, set only after explicit user approval.",
    schema: NotifyInput,
  }
);
```

Note what did NOT change: the Zod schema, the `confirmed: true` gate, and the tool's name/description contract with the rest of the graph. LangGraph's Reason/Critique nodes are completely unaware the implementation swapped from a mock to a real n8n call.

## 6. Passing `runConfig?.runId` Through

`sourceAgentRun` lets you correlate an n8n execution log entry back to the specific LangGraph run that triggered it — critical for Part 7's observability and Appendix C's audit-logging requirement.

## 7. n8n Calling Back INTO LangGraph (the Reverse Direction)

**src/app/api/agent/route.ts:**
```typescript
import { NextRequest, NextResponse } from "next/server";
import { compiledReflectiveAgent } from "../../../agent/graph.reflect.js";
import { HumanMessage } from "@langchain/core/messages";

export async function POST(req: NextRequest) {
  const body = await req.json();
  const result = await compiledReflectiveAgent.invoke({
    messages: [new HumanMessage(body.text)],
  });
  return NextResponse.json({
    reply: result.messages.at(-1)?.content,
  });
}
```

In n8n: add an **HTTP Request node** pointed at your app's `/api/agent`, triggered by whatever upstream event starts the workflow. This completes the hybrid loop: n8n can both receive agent-triggered actions and initiate agent reasoning.

## 8. Exercise Challenge

`notifyTool` has no retry logic — a transient network failure to n8n is just reported back to the model. Add an explicit retry-with-backoff wrapper so transient failures are absorbed before ever reaching the model's reasoning step.

## 9. Solution

**src/lib/retry.ts:**
```typescript
export async function withRetry<T>(
  fn: () => Promise<T>,
  { retries = 3, baseDelayMs = 300 }: { retries?: number; baseDelayMs?: number } = {}
): Promise<T> {
  let lastErr: unknown;
  for (let attempt = 0; attempt <= retries; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastErr = err;
      if (attempt === retries) break;
      const delay = baseDelayMs * 2 ** attempt + Math.random() * 100; // jitter
      await new Promise((r) => setTimeout(r, delay));
    }
  }
  throw lastErr;
}
```

Applied in notifyTool:
```typescript
import { withRetry } from "../lib/retry.js";

const res = await withRetry(() =>
  fetch(N8N_WEBHOOK_URL, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ /* ...same payload... */ }),
    signal: AbortSignal.timeout(8000),
  }).then((r) => {
    if (!r.ok) throw new Error(`status ${r.status}`);
    return r;
  })
);
```

Why retries belong here and not in the model's reasoning loop: exponential backoff with jitter is a solved, deterministic problem — routing it through an LLM decision adds latency and cost for a decision that doesn't need judgment.

## Next
Part 7 makes both halves of this hybrid system observable in one place — tracing token usage, latency, and full reasoning transcripts via self-hosted Langfuse.
