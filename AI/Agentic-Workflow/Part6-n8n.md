# Part 6: Visual Orchestration with n8n

> Recap: Parts 1-5 built a fully self-contained reasoning system — loop, tools, memory, planning, self-critique — entirely in code. Real production systems, though, eventually need to talk to Slack, a CRM, an email provider, a ticketing system, and a dozen other pieces of external infrastructure, each with its own auth quirks and rate limits. This Part is about a decision most teams either skip or get backwards: which parts of that integration surface belong in your reasoning graph, and which parts genuinely don't.

## 1. LangGraph vs n8n — the Actual Decision Criteria

The framing to avoid up front: this is not "which is better." LangGraph and n8n solve different problems, and asking which one wins in the abstract is the wrong question — the right question is which problem you're actually looking at in a given piece of your system.

| Dimension | LangGraph (code-first) | n8n (visual) |
|---|---|---|
| Best for | Branching logic driven by model reasoning | Fixed integration sequences to external systems |
| Change cadence | Changes with prompt/logic iteration (frequent) | Changes with which SaaS tools you integrate (infrequent) |
| Who edits it | Engineers | Engineers AND non-engineers (ops, support leads) |
| Debuggability | Stack traces, structured logs, Langfuse traces | Visual execution log, per-node input/output inspector |
| Failure mode if wrong | Bad reasoning, hallucinated tool args | Misconfigured credential, wrong field mapping |

A few of these rows deserve unpacking rather than a glance. "Change cadence" matters more than it looks: LangGraph code — prompts, routing logic, tool schemas — is exactly the layer you'll be iterating on constantly as you tune agent behavior, which is precisely why it benefits from being real, version-controlled, diffable code with tests. The sequence of steps needed to actually send an email through your SMTP provider, by contrast, changes approximately never, once it's built — which is exactly the kind of stable, low-churn logic that benefits from a visual, inspectable representation instead of code nobody needs to touch again.

"Who edits it" is the row most engineering teams underweight. A support-ops lead who understands exactly how a refund notification workflow *should* behave — which fields matter, what the retry policy should be, who gets CC'd — can open an n8n canvas and verify or adjust that logic directly, without needing to read TypeScript or file a ticket to an engineer. That's not a nice-to-have; it's a meaningful reduction in the bus factor and iteration latency for logic that non-engineers are often the actual domain experts on.

"Failure mode if wrong" is the row that should most directly drive your architectural instincts: a LangGraph failure means the model reasoned badly or hallucinated an argument — a *judgment* problem, best debugged by someone who can reason about prompts and model behavior. An n8n failure means a credential expired or a field got mapped to the wrong API parameter — a *configuration* problem, best debugged by someone who can read a visual execution log and see exactly which node received which input. Conflating these two failure classes into one codebase makes both harder to triage, because you can't tell at a glance which kind of bug you're chasing.

Staff Engineer rule, stated as a test you can actually apply: if a human could write the flowchart for a process without needing to know what the AI said, it belongs in n8n. If the next step genuinely depends on interpreting ambiguous natural-language intent, it belongs in LangGraph. "Send this exact message to this exact address once confirmed" is a flowchart a human can write blind, with no visibility into the conversation that led there — that's n8n's job. "Decide whether this user's message constitutes explicit confirmation" (Part 5's escalation criterion) is not something a fixed flowchart can do — that's LangGraph's job, irreducibly. Most real systems need both, and the mistake worth actively guarding against is picking one tool you're comfortable with and forcing the other's job into it — hand-rolling OAuth retry logic in TypeScript because "it's all code anyway," or trying to get n8n's visual branching to approximate genuine natural-language judgment it structurally can't do.

## 2. The Hybrid Architecture

Reasoning stays in LangGraph — everything built across Parts 1-5: the ReAct loop, the tool contracts, memory, planning, critique. Actions with external side effects move to n8n, invoked via webhook from a LangGraph tool. The boundary between the two systems is exactly the tool-call boundary Part 2 already established — nothing about *how* LangGraph calls a tool changes; what changes is what sits on the other side of that call.

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

Read the two "decides" verbs in that diagram as the entire thesis of this Part condensed to two words: LangGraph decides *what*, n8n decides *how*. That split maps directly onto section 1's table — the "what" is the judgment-heavy, frequently-iterated, engineer-owned layer; the "how" is the mechanical, stable, cross-functionally-owned layer. Keeping that boundary crisp, rather than letting either side creep into the other's job, is what keeps this architecture legible as it grows past a handful of integrations.

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

```bash
docker compose up -d n8n
```

Open `http://localhost:5678`, complete setup, then create a new workflow. Two things worth flagging before you go further: `N8N_BASIC_AUTH_PASSWORD=changeme` is exactly what it says — a placeholder that needs to be replaced with a real secret (via environment variable injection, not committed to source) before this ever runs anywhere reachable outside your local machine. And this is the same pattern as Part 3's `docker-compose.yml` for pgvector — you're standing up n8n as another piece of self-hosted infrastructure alongside Postgres, both owned and versioned the same way, rather than reaching for a hosted equivalent by default. Consistent with the pgvector trade-off from Part 3: self-hosting buys you operational simplicity and cost control up to a point, and it's a decision worth revisiting explicitly once you're operating at a scale where a managed offering's SLA matters more than the marginal infrastructure cost.

## 4. Building the n8n "Action" Workflow

Workflow: "Send Customer Refund Notification":

1. **Webhook node** — trigger, POST, path `/agent-notify`.
2. **Set node** — validate/normalize incoming fields (`recipient`, `message`, `sourceAgentRun`).
3. **IF node** — branch on `recipient` domain if different providers are used per audience.
4. **HTTP Request / Email node** — the actual send (SMTP, Slack, Twilio nodes — n8n ships maintained nodes so you don't hand-roll OAuth/retry logic).
5. **Respond to Webhook node** — return `{ "status": "sent", "id": "<provider message id>" }` so LangGraph gets a real confirmation.

Walk through why step 5 is not optional, even though it's tempting to treat "the workflow ran" as good enough. Recall Part 2's `ToolResult` contract: every tool in this series returns `ok(data)` or `fail(error, retryable)`, and the Reason/Critique nodes on the LangGraph side are built around consuming that structured result. If the n8n workflow's webhook response is just `{ "status": "ok" }` with no real confirmation from the underlying provider, LangGraph has no way to distinguish "the email actually sent" from "the workflow started but the SMTP call is still pending, or silently failed downstream of the webhook response." Returning the actual provider message ID closes that gap — it's evidence the send genuinely happened, not just that the workflow was triggered.

Export as JSON and check it into your repo (`infra/n8n/agent-notify.json`) — treat n8n workflows as versioned infrastructure, not as configuration that only lives inside the n8n UI. This matters for the same reason any infrastructure-as-code discipline matters: a workflow that only exists as UI state on a running n8n instance has no history, no code review, no way to reproduce it on a fresh environment, and no diff to look at when someone asks "what changed since last week." Exporting it as JSON turns a visual, non-engineer-editable artifact back into something that fits your existing version-control and review process, without losing the visual-editability that made n8n the right choice for this layer in the first place.

## 5. The LangGraph Tool That Calls n8n

This replaces Part 2's mocked `notifyTool` — and it's worth pausing on exactly how much stays the same, because that's the real payoff of this whole Part, made concrete: the schema and the confirmation gate stay identical, only the execution body changes.

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

Note precisely what did **not** change relative to Part 2's mocked version: the Zod schema (`NotifyInput`, byte-for-byte identical, `z.literal(true)` confirmation gate included), the tool's `name`, and its `description`'s contract with the rest of the graph — the safety-critical parts, in other words. What changed is exactly the part this Part is about: the body no longer does a mocked `console.log` and returns a fake success; it makes a real HTTP call to n8n and propagates a real `res.status >= 500` retryability signal, following the identical `fail(message, retryable)` convention Part 2's weather tool established back in section 3 of that Part. LangGraph's Reason and Critique nodes are completely unaware the implementation swapped from a mock to a real n8n call — Part 5's Critique criterion 4 (verifying `confirmed: true` traces back to explicit user approval) still applies exactly as written, because it was checking the *conversation*, never the tool's internals.

This is the tool-contract decoupling from Part 2, paying off across the largest architectural change the series has made so far: swapping an entire execution backend — from an in-process mock to an external, visually-orchestrated workflow engine — required editing exactly one file's function body, and zero files anywhere else in the graph.

## 6. Passing `runConfig?.runId` Through

`sourceAgentRun` lets you correlate an n8n execution log entry back to the specific LangGraph run that triggered it — this single field is the thread that ties the two halves of the hybrid system together for debugging and audit purposes. Without it, if a customer reports "I got a strange notification," you'd have an n8n execution log showing *that* a notification was sent, with no way to trace it back to *which* agent conversation, *which* user turn, and *which* critique pass approved it. With it, that trace is a direct lookup. This is critical infrastructure for Part 7's observability work — a Langfuse trace on the LangGraph side and an n8n execution log entry on the other side, joined on this one ID — and it's explicitly called out as a requirement in Appendix C's audit-logging standard: any tool call that triggers an irreversible external action must carry an identifier back to the reasoning run that authorized it, full stop, not as an optional debugging convenience.

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

In n8n: add an **HTTP Request node** pointed at your app's `/api/agent`, triggered by whatever upstream event starts the workflow — an incoming support email, a Slack mention, a new row in a spreadsheet, whatever your integration surface actually is. This completes the hybrid loop, and it's worth stating explicitly what "completes" means here: sections 5 and 6 showed LangGraph *calling out to* n8n; this section shows n8n *calling into* LangGraph. The two directions aren't symmetric in purpose, though — n8n calling LangGraph is "an external event needs judgment applied to it, hand it to the reasoning layer"; LangGraph calling n8n is "judgment has been applied, now execute the mechanical follow-through." Both directions respect the same "what vs. how" boundary from section 1 — the direction of the call doesn't change which system is doing which kind of work, and it's worth double-checking any new integration against that boundary rather than assuming direction alone tells you where logic belongs.

Notice too that `compiledReflectiveAgent` here is Part 5's fully reflective graph — Critique and Refine included — not Part 1's bare loop. Anything n8n triggers into this endpoint inherits all of Parts 1-5's guardrails automatically: step ceilings, schema-validated tools, memory grounding, plan structure (if you point this at the Part 4 graph instead), critique, and escalation. That inheritance is exactly the point — this API route is a thin adapter, not a place where any of that logic needs to be re-implemented or re-verified.

## 8. Exercise Challenge

`notifyTool`, as written in section 5, has no retry logic of its own — a transient network failure to n8n is caught by the `try`/`catch` and immediately reported back to the model as `fail(..., true)`, but nothing actually retries the request before handing the failure to the reasoning layer. Add an explicit retry-with-backoff wrapper so transient failures are absorbed before ever reaching the model's reasoning step.

Before jumping to the solution, notice the framing of the goal: this isn't about making the tool more resilient in the abstract, it's specifically about keeping a *solvable, mechanical* problem out of the model's reasoning loop. A transient network blip retried automatically three times with backoff is invisible to the model entirely — it just sees a success on the far side. A transient network blip surfaced to the model as an immediate failure costs an entire extra reasoning turn (the model has to decide "should I retry this?", possibly consult Critique, possibly ask the user) to solve a problem that a fixed, well-understood algorithm could have solved silently and faster.

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

A quick read of the backoff math itself: `baseDelayMs * 2 ** attempt` doubles the wait on each successive attempt (300ms, 600ms, 1200ms, for the default `retries: 3`), which is standard exponential backoff — it gives a struggling downstream service progressively more room to recover rather than hammering it at a constant rate. The added `Math.random() * 100` — jitter — exists for a subtler reason: without it, if many concurrent tool calls all fail at once (say, n8n briefly restarts), they'd all retry in lockstep at exactly 300ms, then all again at exactly 600ms, creating synchronized retry spikes that can themselves overwhelm a recovering service. Jitter staggers those retries across a small random window, smoothing out the load instead of concentrating it.

Why retries belong here, in a small standalone `lib/retry.ts` utility, and not anywhere in the model's reasoning loop: exponential backoff with jitter is a solved, deterministic problem with a well-known correct algorithm — there is no judgment call to make about *whether* to wait 600ms before a second attempt at a transient failure. Routing that decision through an LLM call would add real latency and real cost (an entire model invocation) to resolve a question that a twenty-line utility function answers correctly, consistently, and near-instantly. This is the same principle Part 3's `isMemoryWorthy` heuristic and Part 4's plan-length cap were both built on, restated once more in its clearest form yet: reserve the model's reasoning for genuine judgment calls, and push every problem with a known, deterministic, correct answer down into plain code — not as a cost-cutting compromise, but because plain code is the *more reliable* solution for problems that don't actually require judgment.

## Hybrid Architecture Checklist

- **Apply the "could a human write this flowchart blind" test** before deciding whether new integration logic belongs in LangGraph or n8n.
- **Keep the tool-call boundary the seam.** LangGraph should never need to know whether a tool's implementation is a mock, an in-process call, or a remote workflow — Part 2's contract makes that swap a one-file change.
- **Return real confirmation, not just "the workflow ran."** A tool result is only as trustworthy as the evidence behind it.
- **Thread a correlation ID through every cross-system call.** `sourceAgentRun` is what turns two separate logs into one traceable story.
- **Respect the "what vs. how" boundary in both call directions.** n8n calling LangGraph and LangGraph calling n8n are asymmetric in purpose even when the wiring looks symmetric.
- **Push solved, deterministic problems (retries, backoff) into plain code**, never into the reasoning loop, regardless of how tempting it is to let the model "just handle it."

## Next

Part 7 makes both halves of this hybrid system observable in one place — tracing token usage, latency, and full reasoning transcripts via self-hosted Langfuse.
