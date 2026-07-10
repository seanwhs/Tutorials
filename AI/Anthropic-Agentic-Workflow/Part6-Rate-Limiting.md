# Part 6: Handling Errors & Streaming

**Series:** Building Agentic Workflows: Mastering the Anthropic Suite
**Prerequisite:** Parts 1-5 (client, tools, structured output, caching, agent loop).

## Concept Explanation

Everything so far has assumed the happy path. Production Anthropic integrations must handle:

- **Rate limits** (`429`) — free/trial tiers have strict RPM/TPM caps; expect these regularly under any real load.
- **Overloaded/transient server errors** (`529`/`503`) — Anthropic's infrastructure occasionally sheds load; these are retryable.
- **Timeouts** — long agent loops or large-output generations can exceed reasonable client timeouts.
- **Malformed/unexpected responses** — a tool call missing an expected field, a `stop_reason` of `max_tokens` when you needed a complete structured object.

Separately, **streaming** changes the interaction model: instead of waiting for a full response, you render tokens as they arrive, which is essential for perceived latency in a chat UI, especially once "Thinking" and multi-step tool loops add real wall-clock time (Part 5's architecture note).

We use the **Vercel AI SDK's** Anthropic provider (`@ai-sdk/anthropic`) here specifically for its `useChat` React hook and stream-handling ergonomics — it wraps the same underlying Anthropic API but removes substantial boilerplate for SSE parsing, tool-call streaming, and React state management. The raw `@anthropic-ai/sdk` remains the right choice for Parts 1-5's server-side orchestration logic; use the right tool for the layer you're building.

## Implementation

### Step 1 — An error taxonomy

`src/lib/anthropic/errors.ts`

```ts
import Anthropic from "@anthropic-ai/sdk";

export type AnthropicErrorCategory =
  | "rate_limited"
  | "overloaded"
  | "invalid_request"
  | "auth_error"
  | "timeout"
  | "unknown";

export interface ClassifiedError {
  category: AnthropicErrorCategory;
  retryable: boolean;
  message: string;
  statusCode: number;
}

export function classifyAnthropicError(err: unknown): ClassifiedError {
  if (err instanceof Anthropic.APIError) {
    switch (err.status) {
      case 429:
        return { category: "rate_limited", retryable: true, message: "Rate limit exceeded.", statusCode: 429 };
      case 529:
      case 503:
        return { category: "overloaded", retryable: true, message: "Anthropic API is overloaded.", statusCode: 503 };
      case 401:
      case 403:
        return { category: "auth_error", retryable: false, message: "Invalid or missing API key.", statusCode: 401 };
      case 400:
        return { category: "invalid_request", retryable: false, message: err.message, statusCode: 400 };
      default:
        return { category: "unknown", retryable: false, message: err.message, statusCode: err.status ?? 500 };
    }
  }

  if (err instanceof Error && err.name === "AbortError") {
    return { category: "timeout", retryable: true, message: "Request timed out.", statusCode: 504 };
  }

  return { category: "unknown", retryable: false, message: String(err), statusCode: 500 };
}
```

### Step 2 — Retry with exponential backoff for retryable categories only

`src/lib/anthropic/retry.ts`

```ts
import { classifyAnthropicError } from "./errors";

export async function withRetry<T>(
  fn: () => Promise<T>,
  { maxAttempts = 3, baseDelayMs = 500 }: { maxAttempts?: number; baseDelayMs?: number } = {}
): Promise<T> {
  let lastError: unknown;

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (err) {
      lastError = err;
      const classified = classifyAnthropicError(err);

      if (!classified.retryable || attempt === maxAttempts) {
        throw err;
      }

      // Exponential backoff with jitter — avoids thundering-herd retries under rate limiting.
      const delay = baseDelayMs * 2 ** (attempt - 1) + Math.random() * 200;
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }

  throw lastError;
}
```

Usage: wrap any `anthropic.messages.create(...)` call site with `withRetry(() => anthropic.messages.create(...))`.

### Step 3 — A Route Handler that surfaces classified errors cleanly

```ts
import { NextRequest, NextResponse } from "next/server";
import { anthropic } from "@/lib/anthropic/client";
import { MODELS } from "@/lib/anthropic/models";
import { withRetry } from "@/lib/anthropic/retry";
import { classifyAnthropicError } from "@/lib/anthropic/errors";

export async function POST(req: NextRequest) {
  const { message } = await req.json();

  try {
    const response = await withRetry(() =>
      anthropic.messages.create(
        { model: MODELS.haiku, max_tokens: 512, messages: [{ role: "user", content: message }] },
        { timeout: 20_000 } // per-call override of the client default from Part 1
      )
    );
    return NextResponse.json({ content: response.content, usage: response.usage });
  } catch (err) {
    const classified = classifyAnthropicError(err);
    return NextResponse.json(
      { error: classified.message, category: classified.category },
      { status: classified.statusCode }
    );
  }
}
```

### Step 4 — Streaming with the Vercel AI SDK

Install (already listed in the INDEX repo setup): `ai` + `@ai-sdk/anthropic`.

`src/app/api/chat/route.ts` (streaming variant)

```ts
import { anthropic } from "@ai-sdk/anthropic";
import { streamText } from "ai";

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: anthropic("claude-sonnet-4-5"),
    system: "You are a concise, senior-engineer assistant.",
    messages,
    // Extended thinking, when enabled, arrives as separate reasoning stream parts —
    // route them to a distinct UI region (see the client component below).
  });

  return result.toDataStreamResponse();
}
```

### Step 5 — The streaming chat UI

`src/app/chat-demo/page.tsx`

```tsx
"use client";

import { useChat } from "ai/react";

export default function ChatDemoPage() {
  const { messages, input, handleInputChange, handleSubmit, isLoading, error } = useChat({
    api: "/api/chat",
  });

  return (
    <div className="mx-auto max-w-2xl p-6 space-y-4">
      <div className="space-y-3">
        {messages.map((m) => (
          <div key={m.id} className={m.role === "user" ? "text-right" : "text-left"}>
            <span className="inline-block rounded-lg bg-gray-100 px-3 py-2">{m.content}</span>
          </div>
        ))}
      </div>

      {isLoading && <p className="text-sm text-gray-400">Claude is thinking…</p>}
      {error && (
        <p className="text-sm text-red-500">
          Something went wrong: {error.message}. Please retry.
        </p>
      )}

      <form onSubmit={handleSubmit} className="flex gap-2">
        <input
          value={input}
          onChange={handleInputChange}
          className="flex-1 rounded border px-3 py-2"
          placeholder="Ask something…"
        />
        <button type="submit" className="rounded bg-black px-4 py-2 text-white" disabled={isLoading}>
          Send
        </button>
      </form>
    </div>
  );
}
```

### Architecture note: streaming + tool use + guardrails together

Streaming complicates the tool-use loop from Part 2: you now receive incremental `input_json_delta` events for tool arguments before the full JSON is valid. The Vercel AI SDK's `streamText` with `tools` handles buffering this for you and only fires `onToolCall` once arguments are complete — do not attempt to `JSON.parse` partial tool-argument deltas yourself when using the raw SDK's streaming mode; accumulate the full delta string first.

## Exercise Challenge

Add a `maxDuration` export and an explicit request timeout to the streaming Route Handler so that a hung generation is aborted after 30 seconds server-side (important on Vercel, where function execution time is billed and capped), and surface a user-friendly retry message in the UI when that happens.

## Solution

```ts
// src/app/api/chat/route.ts
export const maxDuration = 30; // Vercel route segment config — hard ceiling in seconds

import { anthropic } from "@ai-sdk/anthropic";
import { streamText } from "ai";

export async function POST(req: Request) {
  const { messages } = await req.json();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 28_000); // headroom under maxDuration

  try {
    const result = streamText({
      model: anthropic("claude-sonnet-4-5"),
      system: "You are a concise, senior-engineer assistant.",
      messages,
      abortSignal: controller.signal,
    });
    return result.toDataStreamResponse();
  } finally {
    clearTimeout(timeout);
  }
}
```

```tsx
// UI change: surface a specific message for aborted/timeout errors
{error && (
  <p className="text-sm text-red-500">
    {error.message.includes("abort")
      ? "The response took too long and was stopped. Please try a shorter question or retry."
      : `Something went wrong: ${error.message}. Please retry.`}
  </p>
)}
```

**Why 28s, not exactly 30s:** leave headroom between your own abort and the platform's hard ceiling so your code path returns a controlled, user-friendly error instead of the platform terminating the function abruptly mid-stream.

**Next:** Part 7 wraps everything in production concerns — rate limiting your own endpoints, securing environment variables, and observability across all the Route Handlers built in Parts 1-6.
