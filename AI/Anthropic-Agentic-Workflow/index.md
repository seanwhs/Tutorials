# Building Agentic Workflows: Mastering the Anthropic Suite

**Series:** 7-part, code-heavy, beginner-friendly tutorial on building production-grade agentic AI applications with the official Anthropic SDK inside Next.js 16.

Note prefix for the whole series: **"Anthropic Agentic Suite - "**. Search notes with that prefix to find any part.

## Guiding Principles (apply to every part)

- **Tooling constraint:** Next.js 16 (App Router, Turbopack), TypeScript, Zod, official `@anthropic-ai/sdk` only. No third-party AI framework required for Parts 1-5 (Vercel AI SDK introduced deliberately in Part 6 for streaming ergonomics).
- **Cost-conscious by default:** every code sample calls out token/credit implications, model tier tradeoffs (Haiku vs Sonnet vs Opus), and free-tier rate limits.
- **Senior AI Architect tone:** every design decision explains the "why" — latency, determinism, failure modes — not just the "how".
- **Server-only API calls:** the Anthropic API key NEVER touches the client. All calls happen in Route Handlers or Server Actions.

## Series Structure

1. **Part 1 - Anthropic Foundation.** SDK setup, client singleton, first Messages API call, model selection strategy, basic request/response loop as a Next.js Route Handler.
2. **Part 2 - The Tool Use Pattern.** Function calling to query a Postgres/Neon DB and an external API. Tool schemas, the tool-use loop, parallel tool calls.
3. **Part 3 - Structured Outputs.** Forcing deterministic JSON via `tools` + `tool_choice`, Zod-validated schemas, JSON Schema generation from Zod, self-repair on validation failure.
4. **Part 4 - Managing Context & Memory.** Prompt Caching (`cache_control`), conversation history trimming/summarization, context window budgeting.
5. **Part 5 - Agentic Workflow Design.** Multi-step "Reflect → Plan → Execute" agent loop, task decomposition, stopping conditions, guardrails against infinite loops.
6. **Part 6 - Handling Errors & Streaming.** Timeout/retry strategy, error taxonomy, streaming with the Vercel AI SDK's Anthropic provider, `useChat` UI patterns.
7. **Part 7 - Production Orchestration.** Rate limiting, env var security, observability/logging, cost dashboards, deployment readiness.

Each part follows the same four-section format: **Concept Explanation → Implementation (step-by-step code) → Exercise Challenge → Solution with explanation.**

## Repository Setup (do this once, before Part 1)

### 1. Scaffold the project

```bash
npx create-next-app@latest anthropic-agentic-suite \
  --typescript --app --tailwind --eslint --turbopack \
  --src-dir --import-alias "@/*"
cd anthropic-agentic-suite
```

Requires Node.js 20.9+ or 22 LTS (Next.js 16 minimum). Node 18 is EOL and unsupported.

### 2. Install dependencies

```bash
npm install @anthropic-ai/sdk zod
npm install ai @ai-sdk/anthropic          # only needed from Part 6 onward
npm install @neondatabase/serverless      # Part 2 DB tool example
npm install lucide-react clsx             # small UI helpers used in later parts
npm install -D @types/node
```

### 3. `package.json` (relevant excerpt)

```json
{
  "name": "anthropic-agentic-suite",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "eslint ."
  },
  "dependencies": {
    "@anthropic-ai/sdk": "^0.32.0",
    "@ai-sdk/anthropic": "^1.0.0",
    "ai": "^4.0.0",
    "@neondatabase/serverless": "^0.10.0",
    "zod": "^3.23.8",
    "lucide-react": "^0.460.0",
    "clsx": "^2.1.1",
    "next": "^16.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  }
}
```

### 4. Folder structure used throughout the series

```
anthropic-agentic-suite/
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── chat/route.ts              # Part 1, Part 6 (streaming variant)
│   │   │   ├── agent/tool-loop/route.ts   # Part 2
│   │   │   ├── agent/structured/route.ts  # Part 3
│   │   │   ├── agent/workflow/route.ts    # Part 5
│   │   │   └── agent/production/route.ts  # Part 7
│   │   ├── chat-demo/page.tsx             # Part 6 UI
│   │   └── layout.tsx
│   ├── lib/
│   │   ├── anthropic/
│   │   │   ├── client.ts                  # Part 1 singleton
│   │   │   ├── models.ts                  # Part 1 model tier registry
│   │   │   ├── tools/
│   │   │   │   ├── registry.ts            # Part 2
│   │   │   │   ├── db-tools.ts            # Part 2
│   │   │   │   └── weather-tool.ts        # Part 2 (external API demo)
│   │   │   ├── schemas/
│   │   │   │   ├── ticket-update.schema.ts# Part 3
│   │   │   │   └── plan.schema.ts         # Part 5
│   │   │   ├── cache.ts                   # Part 4
│   │   │   ├── memory.ts                  # Part 4
│   │   │   ├── agent-loop.ts              # Part 5
│   │   │   ├── errors.ts                  # Part 6
│   │   │   └── rate-limit.ts              # Part 7
│   │   └── db.ts                          # fake/in-memory or Neon client
│   └── middleware.ts                      # Part 7 rate limiting
├── .env.local                             # never committed
├── .env.example
├── next.config.ts
└── package.json
```

### 5. `.env.example` (secure template — see Appendix A for full annotated version)

```bash
# Anthropic
ANTHROPIC_API_KEY=sk-ant-xxxxxxxxxxxxxxxxxxxxxxxx

# Neon / Postgres (Part 2)
DATABASE_URL=postgresql://user:password@ep-example.neon.tech/neondb?sslmode=require

# External demo API (Part 2 tool-use example)
OPENWEATHER_API_KEY=your_free_tier_key_here

# Rate limiting (Part 7 — optional Upstash Redis, free tier)
UPSTASH_REDIS_REST_URL=
UPSTASH_REDIS_REST_TOKEN=

# App
NODE_ENV=development
```

### 6. Anthropic Console setup (do this before writing any code)

1. Create an account at console.anthropic.com.
2. Generate an API key under **Settings → API Keys**. Copy it immediately (shown once).
3. Note your **rate limits and credit balance** under **Settings → Limits** — the free/trial tier has strict RPM (requests/min) and TPM (tokens/min) caps that Part 7's rate limiter is designed around.
4. Add `ANTHROPIC_API_KEY` to `.env.local` (never `.env` — Next.js loads `.env.local` and it's gitignored by default).

## Model Tier Cheat Sheet (referenced throughout the series)

| Model | Best for | Relative cost | Notes |
|---|---|---|---|
| `claude-3-5-haiku-latest` | High-volume, low-latency tool calls, classification, structured extraction | $ | Default choice for Parts 2-3 exercises to conserve free-tier credits |
| `claude-3-7-sonnet-latest` / `claude-sonnet-4-5` | Balanced reasoning + cost, general agentic steps | $$ | Default for Part 5 agent loop |
| `claude-opus-4-*` | Complex multi-step planning, highest-stakes reasoning | $$$ | Used sparingly — e.g., only the "Plan" step in Part 5 |

Series convention: pass the model name via `lib/anthropic/models.ts` registry, never hardcode strings inline, so swapping tiers is a one-line change (critical for cost control).

## How to Navigate

Search your notes for "Anthropic Agentic Suite - Part N" to jump to any part, or "Anthropic Agentic Suite - Appendix" for the reference appendices.
