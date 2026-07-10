# Part 1: Anthropic Foundation

**Series:** Building Agentic Workflows: Mastering the Anthropic Suite
**Prerequisite:** Complete the INDEX note repo setup (scaffold, deps, env vars, Anthropic Console API key) before starting.

## Concept Explanation

The Anthropic Messages API is the single entry point for every pattern in this series — tool use, structured output, caching, and multi-step agents are all variations on the same request shape: a list of `messages`, an optional `system` prompt, a `model`, and a `max_tokens` budget.

As a Senior AI Architect, three decisions matter more than anything else at this foundational stage:

1. **Client lifecycle.** Instantiate the SDK client once as a module-level singleton on the server. Re-instantiating per-request wastes connection setup and makes it harder to centrally enforce timeouts/retries later (Part 6).
2. **Model selection is a cost lever, not a constant.** Every call should reference a named tier from a registry, not a hardcoded string, so you can swap Haiku/Sonnet/Opus per use case without touching call sites.
3. **Server-only boundary.** The API key must never reach a Client Component or the browser bundle. All Anthropic calls happen inside Route Handlers (`app/api/**/route.ts`) or Server Actions — never in `"use client"` files.

### Why Route Handlers over Server Actions here

Either works, but Route Handlers give you a clean seam for later streaming (Part 6) and standard HTTP semantics (status codes, headers) that map well to error handling (Part 6) and observability (Part 7). We use Route Handlers as the default surface for the whole series and call out Server Action alternatives where relevant.

## Implementation

### Step 1 — The client singleton

`src/lib/anthropic/client.ts`

```ts
import Anthropic from "@anthropic-ai/sdk";

if (!process.env.ANTHROPIC_API_KEY) {
  throw new Error(
    "ANTHROPIC_API_KEY is not set. Add it to .env.local (see .env.example)."
  );
}

// Module-level singleton: reused across requests in the same server runtime.
// The SDK internally manages an HTTP client; instantiating once avoids
// redundant setup cost on every invocation.
export const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
  maxRetries: 2, // baseline retry policy; refined in Part 6
  timeout: 60_000, // 60s ceiling; refined per-call in later parts
});
```

### Step 2 — The model tier registry

`src/lib/anthropic/models.ts`

```ts
/**
 * Central registry of model identifiers. Never hardcode a model string
 * at a call site — always reference a key from this object. This is the
 * single lever you pull to trade cost for capability across the whole app.
 */
export const MODELS = {
  /** Fast + cheap. Default for classification, extraction, tool routing. */
  haiku: "claude-3-5-haiku-latest",
  /** Balanced. Default for general agentic reasoning steps. */
  sonnet: "claude-sonnet-4-5",
  /** Slow + expensive. Reserve for high-stakes planning/reflection only. */
  opus: "claude-opus-4-1",
} as const;

export type ModelTier = keyof typeof MODELS;

/** Sensible default token ceiling per tier — keeps runaway generations in check. */
export const DEFAULT_MAX_TOKENS: Record<ModelTier, number> = {
  haiku: 1024,
  sonnet: 2048,
  opus: 4096,
};
```

### Step 3 — A minimal request/response Route Handler

`src/app/api/chat/route.ts`

```ts
import { NextRequest, NextResponse } from "next/server";
import { anthropic } from "@/lib/anthropic/client";
import { MODELS, DEFAULT_MAX_TOKENS } from "@/lib/anthropic/models";

export async function POST(req: NextRequest) {
  const body = await req.json();
  const userMessage: string = body.message;

  if (!userMessage || typeof userMessage !== "string") {
    return NextResponse.json(
      { error: "Field 'message' (string) is required." },
      { status: 400 }
    );
  }

  const response = await anthropic.messages.create({
    model: MODELS.haiku,
    max_tokens: DEFAULT_MAX_TOKENS.haiku,
    system:
      "You are a concise, senior-engineer assistant. Answer in 3 sentences or fewer unless asked for more detail.",
    messages: [{ role: "user", content: userMessage }],
  });

  // Anthropic responses return an array of content blocks. For a plain-text
  // reply there is typically one block of type "text".
  const textBlock = response.content.find((b) => b.type === "text");

  return NextResponse.json({
    reply: textBlock?.type === "text" ? textBlock.text : null,
    usage: response.usage, // { input_tokens, output_tokens } — log this from day one
    stop_reason: response.stop_reason,
  });
}
```

### Step 4 — Calling it

```bash
curl -X POST http://localhost:3000/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "In one sentence, what is prompt caching?"}'
```

Expected shape:

```json
{
  "reply": "Prompt caching lets you reuse previously processed prompt content across requests, cutting latency and cost for repeated context.",
  "usage": { "input_tokens": 42, "output_tokens": 28 },
  "stop_reason": "end_turn"
}
```

### Architecture note: why `usage` and `stop_reason` matter from message #1

- `usage.input_tokens` / `usage.output_tokens` is your **only** ground truth for cost. Log it on every call from Part 1 onward — retrofitting cost observability later (Part 7) is painful without a baseline.
- `stop_reason` tells you *why* generation stopped: `"end_turn"` (natural completion), `"max_tokens"` (truncated — dangerous if you expected structured output, see Part 3), `"tool_use"` (Part 2), or `"stop_sequence"`. Treat anything other than `"end_turn"` or `"tool_use"` as a signal worth handling explicitly.

## Exercise Challenge

Extend the Route Handler so that:

1. It accepts an optional `tier` field (`"haiku" | "sonnet" | "opus"`) in the request body and uses it to select the model via the registry, defaulting to `"haiku"` if omitted.
2. It rejects (400) any `tier` value not present in `MODELS`.
3. It returns a `model_used` field in the response so the caller can verify which tier served the request.

## Solution

```ts
import { NextRequest, NextResponse } from "next/server";
import { anthropic } from "@/lib/anthropic/client";
import { MODELS, DEFAULT_MAX_TOKENS, type ModelTier } from "@/lib/anthropic/models";

function isValidTier(tier: unknown): tier is ModelTier {
  return typeof tier === "string" && tier in MODELS;
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const userMessage: string = body.message;
  const requestedTier = body.tier ?? "haiku";

  if (!userMessage || typeof userMessage !== "string") {
    return NextResponse.json(
      { error: "Field 'message' (string) is required." },
      { status: 400 }
    );
  }

  if (!isValidTier(requestedTier)) {
    return NextResponse.json(
      {
        error: `Invalid tier '${requestedTier}'. Valid tiers: ${Object.keys(MODELS).join(", ")}`,
      },
      { status: 400 }
    );
  }

  const tier: ModelTier = requestedTier;

  const response = await anthropic.messages.create({
    model: MODELS[tier],
    max_tokens: DEFAULT_MAX_TOKENS[tier],
    system:
      "You are a concise, senior-engineer assistant. Answer in 3 sentences or fewer unless asked for more detail.",
    messages: [{ role: "user", content: userMessage }],
  });

  const textBlock = response.content.find((b) => b.type === "text");

  return NextResponse.json({
    reply: textBlock?.type === "text" ? textBlock.text : null,
    usage: response.usage,
    stop_reason: response.stop_reason,
    model_used: MODELS[tier],
  });
}
```

**Why this design:** validating `tier` against the registry (rather than trusting any string) prevents a caller from ever reaching the API with a typo'd model name — that would surface as an opaque 404-ish error from Anthropic instead of a clean 400 from your own app. Fail fast, fail locally, with a message that tells the caller exactly what's valid.

**Next:** Part 2 introduces Tool Use — Claude will decide *when* to call your functions, and you'll build the loop that executes them and feeds results back.
