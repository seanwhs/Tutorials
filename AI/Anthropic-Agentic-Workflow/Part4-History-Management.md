# Part 4: Managing Context & Memory (Prompt Caching)

**Series:** Building Agentic Workflows: Mastering the Anthropic Suite
**Prerequisite:** Parts 1-3 (client, tool loop, structured output).

## Concept Explanation

Two distinct problems live under "context management":

1. **Cost/latency of repeated large context.** Your system prompt, tool definitions, and reference documents are often identical across many requests (e.g., every message in a chat session, or every call in a batch job). Re-sending and re-processing them every time is wasted spend.
2. **Context window growth.** Long-running conversations or agent loops accumulate messages until they approach the model's context limit, degrading quality (the "lost in the middle" effect) and increasing cost per call even with caching.

Anthropic's **Prompt Caching** solves problem 1: you mark a point in your prompt with `cache_control: { type: "ephemeral" }`, and Anthropic caches everything up to and including that block server-side for ~5 minutes (refreshed on each cache hit). Subsequent requests that repeat that exact prefix get charged a fraction of the normal input token cost for the cached portion, with significantly lower latency (skips re-processing).

Problem 2 is solved architecturally, not by Anthropic — you need **history management**: sliding windows, summarization, or explicit memory extraction.

### Where to put `cache_control`

Cache breakpoints must be placed on stable, reusable prefixes: system prompts, tool definitions, and any large static reference content (e.g., a document being discussed repeatedly). Do NOT cache the final user turn — it changes every request and caching it provides no benefit while adding overhead.

Order of stability (cache the most stable, largest, earliest content):

```
[static system prompt] → [static tool defs] → [static reference doc] → [dynamic conversation history] → [current user turn]
```

### Cost/latency math that justifies this

A cache write costs ~25% more than a normal input token (one-time), but a cache read (hit) costs ~10% of normal input token price. For a system prompt + tool schema block of, say, 2,000 tokens reused across 50 turns in a session, you pay the 25% premium once and then 90% savings on 49 subsequent reads — a large net win for any agent loop or chat session beyond a couple of turns.

## Implementation

### Step 1 — Cache-aware system prompt and tools

`src/lib/anthropic/cache.ts`

```ts
import Anthropic from "@anthropic-ai/sdk";

/**
 * Wraps a system prompt string as a cacheable content block. Anthropic
 * caches everything up to and including the LAST block that has
 * cache_control set — so only mark the final stable block, not every one.
 */
export function cacheableSystem(text: string): Anthropic.TextBlockParam[] {
  return [
    {
      type: "text",
      text,
      cache_control: { type: "ephemeral" },
    },
  ];
}

/** Marks the final tool definition as the cache breakpoint for the tool array. */
export function withCacheBreakpoint(tools: Anthropic.Tool[]): Anthropic.Tool[] {
  if (tools.length === 0) return tools;
  return tools.map((tool, i) =>
    i === tools.length - 1
      ? { ...tool, cache_control: { type: "ephemeral" as const } }
      : tool
  );
}
```

### Step 2 — Using it in a chat Route Handler

`src/app/api/chat/route.ts` (extended from Part 1)

```ts
import { NextRequest, NextResponse } from "next/server";
import Anthropic from "@anthropic-ai/sdk";
import { anthropic } from "@/lib/anthropic/client";
import { MODELS } from "@/lib/anthropic/models";
import { TOOLS } from "@/lib/anthropic/tools/registry";
import { cacheableSystem, withCacheBreakpoint } from "@/lib/anthropic/cache";

const LARGE_STATIC_SYSTEM_PROMPT = `
You are an internal support assistant for Acme Corp.
[... imagine 1500+ tokens of policy, tone, and formatting rules here ...]
`;

export async function POST(req: NextRequest) {
  const { messages }: { messages: Anthropic.MessageParam[] } = await req.json();

  const response = await anthropic.messages.create({
    model: MODELS.sonnet,
    max_tokens: 1024,
    system: cacheableSystem(LARGE_STATIC_SYSTEM_PROMPT),
    tools: withCacheBreakpoint(TOOLS),
    messages, // conversation history — intentionally NOT cached, it changes every turn
  });

  // usage.cache_creation_input_tokens (write) vs cache_read_input_tokens (hit)
  // — log both from day one; this is your caching ROI signal.
  return NextResponse.json({
    content: response.content,
    usage: response.usage,
  });
}
```

### Step 3 — Conversation history management (sliding window + summarization)

`src/lib/anthropic/memory.ts`

```ts
import Anthropic from "@anthropic-ai/sdk";
import { anthropic } from "./client";
import { MODELS } from "./models";

const MAX_TURNS_BEFORE_SUMMARY = 12; // tune per app; ~12 turns keeps most sessions well under limits

/**
 * Rough token estimate (chars/4) — good enough for a summarization trigger,
 * not for billing accuracy (use response.usage for that).
 */
function estimateTokens(messages: Anthropic.MessageParam[]): number {
  const chars = messages.reduce((sum, m) => {
    const text = typeof m.content === "string" ? m.content : JSON.stringify(m.content);
    return sum + text.length;
  }, 0);
  return Math.ceil(chars / 4);
}

export async function maybeCompactHistory(
  messages: Anthropic.MessageParam[]
): Promise<Anthropic.MessageParam[]> {
  if (messages.length <= MAX_TURNS_BEFORE_SUMMARY) return messages;

  // Keep the most recent 4 turns verbatim (they carry the immediate context the
  // model needs); summarize everything older into a single system-style note.
  const recent = messages.slice(-4);
  const toSummarize = messages.slice(0, -4);

  const summaryResponse = await anthropic.messages.create({
    model: MODELS.haiku, // cheap tier — summarization is not a high-stakes reasoning task
    max_tokens: 400,
    system:
      "Summarize this conversation history into a compact bullet list of facts, decisions, " +
      "and open questions that a new assistant turn would need to continue the conversation coherently. " +
      "Be terse. Omit pleasantries.",
    messages: [
      {
        role: "user",
        content: toSummarize
          .map((m) => `${m.role.toUpperCase()}: ${JSON.stringify(m.content)}`)
          .join("\n"),
      },
    ],
  });

  const summaryText = summaryResponse.content.find((b) => b.type === "text");

  const summaryMessage: Anthropic.MessageParam = {
    role: "user",
    content: `[CONVERSATION SUMMARY — earlier turns compacted]\n${
      summaryText?.type === "text" ? summaryText.text : ""
    }`,
  };

  return [summaryMessage, ...recent];
}

export { estimateTokens };
```

### Step 4 — Wiring compaction into the loop

```ts
import { maybeCompactHistory } from "@/lib/anthropic/memory";

// Before each call in a long-running session or agent loop:
messages = await maybeCompactHistory(messages);
```

### Architecture note: caching + summarization interact

Summarizing early turns invalidates the cache prefix for anything downstream of the summarized content, because the cached bytes no longer match. Structure your prompt so the **summary itself becomes the new stable prefix** you cache going forward — i.e., re-apply `cache_control` after compaction, don't just cache once at session start and forget about it.

## Exercise Challenge

Add a `cacheStats(usage)` helper that, given a Anthropic `usage` object (`{ input_tokens, output_tokens, cache_creation_input_tokens?, cache_read_input_tokens? }`), returns an estimated cost saved on this call versus a no-cache baseline, assuming cache reads cost 10% of normal input price and cache writes cost 125% of normal input price. Use Haiku's list pricing as a placeholder constant.

## Solution

```ts
// Placeholder list price — replace with current published Anthropic pricing.
const HAIKU_INPUT_PRICE_PER_MTOK = 0.80; // USD per 1M input tokens

interface AnthropicUsage {
  input_tokens: number;
  output_tokens: number;
  cache_creation_input_tokens?: number;
  cache_read_input_tokens?: number;
}

export function cacheStats(usage: AnthropicUsage) {
  const baseRate = HAIKU_INPUT_PRICE_PER_MTOK / 1_000_000;
  const cacheReadTokens = usage.cache_read_input_tokens ?? 0;
  const cacheWriteTokens = usage.cache_creation_input_tokens ?? 0;

  const actualCost =
    usage.input_tokens * baseRate +
    cacheReadTokens * baseRate * 0.1 +
    cacheWriteTokens * baseRate * 1.25;

  const noCacheBaselineCost =
    (usage.input_tokens + cacheReadTokens + cacheWriteTokens) * baseRate;

  return {
    actualCostUsd: Number(actualCost.toFixed(6)),
    noCacheBaselineCostUsd: Number(noCacheBaselineCost.toFixed(6)),
    estimatedSavingsUsd: Number((noCacheBaselineCost - actualCost).toFixed(6)),
    cacheHit: cacheReadTokens > 0,
  };
}
```

**Why log this per call:** aggregate `estimatedSavingsUsd` across a day of traffic and you get a concrete, defensible number to justify caching architecture to stakeholders — exactly the kind of cost-efficiency evidence a Senior AI Architect should have on hand.

**Next:** Part 5 builds the full multi-step agent — Reflect → Plan → Execute — using everything from Parts 2-4 (tools, structured output, caching, history management) together.
