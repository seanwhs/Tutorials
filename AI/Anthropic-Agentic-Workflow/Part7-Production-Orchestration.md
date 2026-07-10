# Part 7: Production Orchestration

**Series:** Building Agentic Workflows: Mastering the Anthropic Suite
**Prerequisite:** Parts 1-6 (the entire orchestration, structured output, caching, agent, and streaming stack).

## Concept Explanation

Everything built so far works locally. Shipping it means addressing three concerns that don't show up in a demo but define whether the system survives real traffic and a real bill:

1. **Rate limiting your own endpoints** — Anthropic's free/trial tier RPM/TPM limits are a hard ceiling shared across your entire app. If you don't rate-limit your own Route Handlers, a single busy user (or a retry storm from Part 6's backoff logic) can exhaust your quota for everyone else. This is an internal control, separate from and in addition to handling Anthropic's own 429s.
2. **Environment variable security** — the API key must never leak to a client bundle, a log line, or a error message returned to the browser.
3. **Observability** — without per-call logging of tokens, latency, model tier, and cache hit/miss (Part 4), you cannot answer "why did the bill spike" or "why did this feature get slow" after the fact.

## Implementation

### Step 1 — Rate limiting with Upstash Redis (free tier) sliding window

```bash
npm install @upstash/ratelimit @upstash/redis
```

`src/lib/anthropic/rate-limit.ts`

```ts
import { Ratelimit } from "@upstash/ratelimit";
import { Redis } from "@upstash/redis";

const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL!,
  token: process.env.UPSTASH_REDIS_REST_TOKEN!,
});

// 10 requests per 60s per identifier — tune against your actual Anthropic tier limits,
// leaving headroom (e.g. target 70-80% of the true ceiling) for burst absorption.
export const anthropicRateLimiter = new Ratelimit({
  redis,
  limiter: Ratelimit.slidingWindow(10, "60 s"),
  analytics: true,
  prefix: "ratelimit:anthropic",
});
```

### Step 2 — Middleware enforcement

`src/middleware.ts`

```ts
import { NextRequest, NextResponse } from "next/server";
import { anthropicRateLimiter } from "@/lib/anthropic/rate-limit";

export const config = {
  matcher: ["/api/chat", "/api/agent/:path*"],
};

export async function middleware(req: NextRequest) {
  // Identify by authenticated user ID in a real app; IP is a reasonable fallback for a PoC.
  const identifier = req.headers.get("x-forwarded-for") ?? "anonymous";

  const { success, limit, remaining, reset } = await anthropicRateLimiter.limit(identifier);

  if (!success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Please slow down.", limit, remaining, reset },
      { status: 429 }
    );
  }

  return NextResponse.next();
}
```

### Step 3 — Environment variable security checklist (enforced in code)

`src/lib/env.ts`

```ts
import { z } from "zod";

/**
 * Validates required server env vars at boot. Fails fast and loudly rather
 * than surfacing a cryptic runtime error deep inside an API route later.
 * Import this once from a server-only entry point (e.g. instrumentation.ts).
 */
const EnvSchema = z.object({
  ANTHROPIC_API_KEY: z.string().min(1, "ANTHROPIC_API_KEY is required"),
  DATABASE_URL: z.string().url(),
  UPSTASH_REDIS_REST_URL: z.string().url().optional(),
  UPSTASH_REDIS_REST_TOKEN: z.string().optional(),
});

export const env = EnvSchema.parse(process.env);
```

Security rules enforced across the whole series (recap, restated as a checklist):

- All `ANTHROPIC_API_KEY` reads happen in `src/lib/anthropic/client.ts` (server-only module) — never in a `"use client"` file, never in a `NEXT_PUBLIC_*` variable.
- Route Handlers never echo raw error objects from the Anthropic SDK back to the client (Part 6's `classifyAnthropicError` strips this to a safe category + message).
- `.env.local` is in `.gitignore` by default in Next.js — verify it, never commit it. `.env.example` (Appendix A) contains only placeholder values.
- In Vercel, set `ANTHROPIC_API_KEY` and `DATABASE_URL` as **encrypted environment variables** scoped to the appropriate environment (Production/Preview/Development), never inline in `next.config.ts` or committed config.

### Step 4 — Observability: structured per-call logging

`src/lib/anthropic/observability.ts`

```ts
interface AnthropicCallLog {
  timestamp: string;
  route: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
  cacheReadTokens?: number;
  cacheWriteTokens?: number;
  latencyMs: number;
  stopReason: string;
  success: boolean;
  errorCategory?: string;
}

/**
 * Minimal structured logger — swap console.log for a real sink
 * (e.g. Axiom, Datadog, or a Postgres table) without changing call sites.
 */
export function logAnthropicCall(log: AnthropicCallLog) {
  console.log(JSON.stringify({ type: "anthropic_call", ...log }));
}
```

Wired into a Route Handler:

```ts
import { logAnthropicCall } from "@/lib/anthropic/observability";
import { classifyAnthropicError } from "@/lib/anthropic/errors";
import { withRetry } from "@/lib/anthropic/retry";

export async function POST(req: NextRequest) {
  const startedAt = Date.now();
  const { message } = await req.json();

  try {
    const response = await withRetry(() =>
      anthropic.messages.create({
        model: MODELS.haiku,
        max_tokens: 512,
        messages: [{ role: "user", content: message }],
      })
    );

    logAnthropicCall({
      timestamp: new Date().toISOString(),
      route: "/api/chat",
      model: MODELS.haiku,
      inputTokens: response.usage.input_tokens,
      outputTokens: response.usage.output_tokens,
      cacheReadTokens: response.usage.cache_read_input_tokens,
      cacheWriteTokens: response.usage.cache_creation_input_tokens,
      latencyMs: Date.now() - startedAt,
      stopReason: response.stop_reason ?? "unknown",
      success: true,
    });

    return NextResponse.json({ content: response.content, usage: response.usage });
  } catch (err) {
    const classified = classifyAnthropicError(err);
    logAnthropicCall({
      timestamp: new Date().toISOString(),
      route: "/api/chat",
      model: MODELS.haiku,
      inputTokens: 0,
      outputTokens: 0,
      latencyMs: Date.now() - startedAt,
      stopReason: "error",
      success: false,
      errorCategory: classified.category,
    });
    return NextResponse.json({ error: classified.message }, { status: classified.statusCode });
  }
}
```

### Architecture note: cost dashboards from logs alone

Because every log line already carries `inputTokens`, `outputTokens`, and cache fields, you can build a cost dashboard purely by aggregating this log stream (grouped by `route` and `model`) against published Anthropic per-token pricing — no separate billing integration required. This is the natural companion to Part 4's `cacheStats` helper: log the raw counts, compute derived cost/savings metrics in your dashboard layer, not inline in the hot path.

## Exercise Challenge

Add a per-user daily token budget check that runs before the rate-limit check in middleware: given a `dailyTokenUsage` lookup (assume a function `getUserDailyTokenUsage(userId): Promise<number>` backed by aggregating the observability log table), reject requests once a user exceeds 100,000 tokens/day with a 402-style "budget exceeded" response, distinct from the 429 rate-limit response.

## Solution

```ts
// src/lib/anthropic/budget.ts
import { sql } from "@/lib/db";

const DAILY_TOKEN_BUDGET = 100_000;

export async function getUserDailyTokenUsage(userId: string): Promise<number> {
  const rows = await sql`
    SELECT COALESCE(SUM(input_tokens + output_tokens), 0) AS total
    FROM anthropic_call_logs
    WHERE user_id = ${userId} AND created_at >= NOW() - INTERVAL '1 day'
  `;
  return Number(rows[0]?.total ?? 0);
}

export async function checkDailyBudget(userId: string): Promise<{ ok: boolean; used: number }> {
  const used = await getUserDailyTokenUsage(userId);
  return { ok: used < DAILY_TOKEN_BUDGET, used };
}
```

```ts
// src/middleware.ts — extended
import { checkDailyBudget } from "@/lib/anthropic/budget";

export async function middleware(req: NextRequest) {
  const identifier = req.headers.get("x-user-id") ?? "anonymous";

  const budget = await checkDailyBudget(identifier);
  if (!budget.ok) {
    return NextResponse.json(
      { error: "Daily token budget exceeded. Resets at midnight UTC.", used: budget.used },
      { status: 402 }
    );
  }

  const { success, limit, remaining, reset } = await anthropicRateLimiter.limit(identifier);
  if (!success) {
    return NextResponse.json(
      { error: "Rate limit exceeded. Please slow down.", limit, remaining, reset },
      { status: 429 }
    );
  }

  return NextResponse.next();
}
```

**Why 402 vs 429:** these are semantically different failure modes — 429 says "you're going too fast, try again soon"; 402 ("Payment Required," repurposed here as "budget required") says "you're within pace but out of allotment until the window resets." Distinguishing them lets your client UI show the right message ("slow down" vs "come back tomorrow / upgrade").
---

That's the last of the 7 core parts. Want the **Appendices** note next (file tree, env.example, pattern library table, deployment checklist)?
