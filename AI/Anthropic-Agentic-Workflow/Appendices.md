# Appendices

## Appendix A: Codebase Reference

### Full File Tree

```
anthropic-agentic-suite/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── chat/route.ts
│   │   │   ├── agent/tool-loop/route.ts
│   │   │   ├── agent/structured/route.ts
│   │   │   ├── agent/workflow/route.ts
│   │   │   └── agent/production/route.ts
│   │   ├── chat-demo/page.tsx
│   │   └── layout.tsx
│   ├── lib/
│   │   ├── anthropic/
│   │   │   ├── client.ts
│   │   │   ├── models.ts
│   │   │   ├── cache.ts
│   │   │   ├── memory.ts
│   │   │   ├── agent-loop.ts
│   │   │   ├── errors.ts
│   │   │   ├── retry.ts
│   │   │   ├── rate-limit.ts
│   │   │   ├── budget.ts
│   │   │   ├── observability.ts
│   │   │   ├── tools/
│   │   │   │   ├── registry.ts
│   │   │   │   ├── db-tools.ts
│   │   │   │   ├── weather-tool.ts
│   │   │   │   └── dispatch.ts
│   │   │   └── schemas/
│   │   │       ├── ticket-update.schema.ts
│   │   │       ├── plan.schema.ts
│   │   │       └── repair.ts
│   │   ├── env.ts
│   │   └── db.ts
│   └── middleware.ts
├── .env.local
├── .env.example
├── next.config.ts
└── package.json
```

### Annotated env.example

```bash
# ── Anthropic (required, server-only, never exposed to client) ──
# Get this from console.anthropic.com under Settings -> API Keys.
# Never prefix with NEXT_PUBLIC_ — that would bundle it into client JS.
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx

# ── Database (Part 2 tool-use example, Part 7 budget tracking) ──
# Free tier Postgres from neon.tech. Requires sslmode=require.
DATABASE_URL=postgresql://user:password@ep-example.neon.tech/neondb?sslmode=require

# ── External demo API (Part 2 tool-use example) ──
# Free tier key from openweathermap.org.
OPENWEATHER_API_KEY=your_free_tier_key_here

# ── Rate limiting (Part 7, optional but recommended in production) ──
# Free tier from upstash.com (serverless Redis).
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=

# ── App ──
NODE_ENV=development
```

### Security notes for this file

- `.env.local` holds real secrets and is gitignored by default in Next.js — verify with `git check-ignore .env.local` before your first commit.
- `.env.example` (this template) contains ONLY placeholders and is safe to commit.
- In Vercel, replicate these keys under Project Settings → Environment Variables, scoped per environment (Development/Preview/Production), marked as "Sensitive" where the UI offers it.

## Appendix B: The Anthropic Pattern Library

| Pattern | How to trigger it | Key code construct | Notes / gotchas |
|---|---|---|---|
| Basic text response | Omit `tools` and `tool_choice` | `anthropic.messages.create({ model, max_tokens, system, messages })` | `stop_reason` should be `end_turn` |
| Optional tool use | Include `tools`, omit `tool_choice` (defaults to `auto`) | `tools: TOOLS` | Model decides whether to call a tool at all; check `stop_reason === "tool_use"` |
| Forced single tool (structured output) | Set `tool_choice: { type: "tool", name: "..." }` | Part 3 pattern | Guarantees a tool_use block on this turn; still Zod-validate the result |
| Forced "any tool" | `tool_choice: { type: "any" }` | — | Forces some tool call, but not a specific one; rare, used when 2+ tools are equally valid |
| Parallel tool calls | Default behavior when appropriate | Filter `response.content` for multiple `tool_use` blocks, `Promise.all` over them | Only safe if tools are independent/side-effect-isolated |
| System prompts | `system` parameter (string or content block array) | Part 1: plain string; Part 4: content block array for caching | Keep system prompts stable/static where possible to maximize cache reuse |
| Prompt caching (system) | Wrap system content block with `cache_control: { type: "ephemeral" }` | `cacheableSystem()` helper, Part 4 | Cache breakpoint applies to everything up to and including that block |
| Prompt caching (tools) | Set `cache_control` on the LAST tool definition in the array | `withCacheBreakpoint()` helper, Part 4 | Only mark the final tool; earlier ones are covered automatically |
| Prompt caching (conversation) | Mark a stable prefix of `messages` (e.g. a large reference doc) with `cache_control` | Manual block construction | Never cache the final/current user turn — it changes every request |
| Self-repair on validation failure | Feed a `tool_result` with `is_error: true` containing Zod issues, re-call with same `tool_choice` | `repairStructuredOutput()`, Part 3 | Cheaper than failing the whole user-facing request |
| Multi-step agent loop | Loop Reflect → Plan → Execute with a `finish_task` tool as explicit stop signal | `runAgent()`, Part 5 | Always pair with `MAX_STEPS` and a cumulative token budget ceiling |
| Streaming | Vercel AI SDK `streamText()` + `toDataStreamResponse()` | Part 6 | Raw SDK streaming requires manual buffering of `input_json_delta` for tool args |
| Retry with backoff | Wrap calls in `withRetry()`, only retry `retryable` categories (429, 529/503) | Part 6 | Never retry 400/401/403 — those are permanent until you fix the request/key |
| Rate limiting (your endpoints) | Upstash sliding window in `middleware.ts` | Part 7 | Protects your shared Anthropic quota from a single noisy client |
| Per-user budget enforcement | Aggregate logged token usage per user per day, reject over threshold with 402 | Part 7 exercise | Distinct failure mode from 429 — communicate differently in UI |

## Appendix C: Deployment Checklist (Vercel)

1. **Push to a Git provider** (GitHub/GitLab/Bitbucket) connected to Vercel.
2. **Import the project** in the Vercel dashboard; Vercel auto-detects Next.js 16 and configures the build (`next build`, Turbopack).
3. **Set environment variables** in Project Settings → Environment Variables for each of Production, Preview, and Development:
   - `ANTHROPIC_API_KEY` (mark sensitive)
   - `DATABASE_URL`
   - `OPENWEATHER_API_KEY` (if using Part 2's weather tool)
   - `UPSTASH_REDIS_REST_URL`, `UPSTASH_REDIS_REST_TOKEN` (if using Part 7's rate limiter)
4. **Verify server-only boundaries** before deploying: grep the codebase for `ANTHROPIC_API_KEY` and confirm every usage is inside `src/lib/anthropic/client.ts` or another server-only module (no `"use client"` file, no `NEXT_PUBLIC_` prefix anywhere).
5. **Set route segment configs** for any long-running AI routes: `export const maxDuration = 30;` (or higher, per your Vercel plan's function duration limits) on streaming/agent routes from Parts 5-6.
6. **Confirm your Anthropic usage tier** in the Anthropic Console covers expected production RPM/TPM — the free/trial tier is almost certainly insufficient for real traffic; upgrade before launch if needed.
7. **Deploy** — trigger via git push (auto) or `vercel --prod` (CLI).
8. **Smoke test in production**: hit `/api/chat`, `/api/agent/tool-loop`, `/api/agent/structured`, `/api/agent/workflow` with representative payloads; confirm `usage` fields are non-zero and `stop_reason` values are as expected.
9. **Verify observability sink** (Part 7's `logAnthropicCall`) is actually receiving production log lines — check Vercel's function logs or your external sink (Axiom/Datadog/etc.) immediately after the smoke test.
10. **Set up budget/rate-limit alerting**: configure a daily check (cron job or scheduled function) that alerts you if aggregate token usage approaches your Anthropic plan's spend limit — don't rely on discovering this via a surprise invoice.
11. **Document rollback plan**: know how to instantly disable AI routes (e.g., a feature flag or killing the route handler to return a 503) if costs spike unexpectedly post-launch.

**Series complete.** Cross-reference: INDEX note for setup, Parts 1-7 for implementation, this note for reference tables and deployment steps.
