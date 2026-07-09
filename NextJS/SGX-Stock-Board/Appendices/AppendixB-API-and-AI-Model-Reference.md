# Appendix B: Free APIs & Free AI Models Reference

A consolidated reference for every external service used in this series, what free tier it offers, what we use it for, and links to where you'd sign up. Free tier limits change over time — always check the provider's current pricing page before relying on this for a real product.

## Market Data

### yahoo-finance2 (npm package)
- **Used for**: Primary source for live quotes, historical OHLCV bars, and dividend history (Parts 4, 7, 8, 11)
- **Cost**: Free, no API key, no official rate limit published (unofficial wrapper around Yahoo Finance's public endpoints)
- **SGX coverage**: Excellent — `.SI` suffixed tickers work out of the box
- **Caveat**: Unofficial; Yahoo could change internal endpoints without notice, which is exactly why we built the Finnhub fallback in Part 5

### Finnhub.io
- **Used for**: Fallback quote/history provider (Part 5)
- **Cost**: Free tier — 60 API calls/minute at the time of writing
- **SGX coverage**: Partial — good for quotes, candle/historical coverage varies by symbol
- **Sign up**: finnhub.io, no credit card required for free tier

### SGX StockFacts (scraped)
- **Used for**: REIT fundamentals — DPU, NAV, gearing ratio, occupancy rate (Part 15)
- **Cost**: Free (public webpage, no official API)
- **Caveat**: Not an official API; scraping can break if page structure changes. Always wrap in try/catch with graceful degradation, as built in Part 15.

## Caching

### Upstash Redis
- **Used for**: 15-minute quote/history cache, 30-min news/AI-summary cache, 24h dividend cache, rate limiting (Parts 6, 20)
- **Cost**: Free tier — generous request quota, no credit card required
- **Why this over traditional Redis**: REST-based API works natively in serverless/edge functions without persistent TCP connections
- **Sign up**: upstash.com
- **Companion package**: `@upstash/ratelimit` for request throttling (Part 20)

## Database

### Neon (serverless Postgres)
- **Used for**: All persistent data — stocks, prices, dividends, watchlists, alerts, news (Part 3)
- **Cost**: Free tier — includes a Postgres project with scale-to-zero compute, generous storage for a portfolio-scale project
- **Sign up**: neon.tech
- **Why Neon over a bundled backend-as-a-service platform**: this project only ever accesses Postgres through Prisma — no bundled auth, storage, or realtime features are used, since auth is handled separately by Clerk. Neon is a focused serverless Postgres product with fast resume-from-idle and built-in connection pooling, and integrates tightly with Vercel. See Part 1 for the fuller rationale.
- **Two connection strings needed**: a pooled connection string (`DATABASE_URL`, used at runtime) and a direct connection string (`DIRECT_URL`, used only for migrations) — both are available directly from the Neon dashboard's Connection Details panel, see Part 3.
- **Optional companion package**: `@neondatabase/serverless` (installed in Part 2) — only needed if you later want Neon's HTTP-based driver for Edge-runtime routes; not required for anything built in this tutorial, since all our routes run as standard Node serverless functions.

## Authentication

### Clerk
- **Used for**: User sign-up/sign-in, session management, watchlist ownership (Part 18)
- **Cost**: Free tier — sufficient monthly active user allowance for a personal project/demo
- **Sign up**: clerk.com
- **Current API surface used**: `clerkMiddleware`, `createRouteMatcher`, `await auth()`, `await clerkClient()`

## Email

### Resend
- **Used for**: Price alert emails (Part 19)
- **Cost**: Free tier — includes a monthly email sending quota sufficient for personal alert volumes
- **Sign up**: resend.com
- **Note**: requires domain verification for production sending; a shared test domain is available for development

## AI Models (Free Tier Only — Part 14)

This project deliberately uses **only free-tier AI models**, wired behind a model-selector abstraction (`src/lib/ai/models.ts`) so switching or adding providers is a one-line change.

### Groq (default/primary)
- **Model used**: `llama-3.1-8b-instant` (Meta's open Llama 3.1 8B, hosted by Groq)
- **Cost**: Free tier — very generous rate limits, extremely fast inference (Groq's LPU hardware)
- **Package**: `@ai-sdk/groq`
- **Sign up**: console.groq.com

### Google Gemini (secondary)
- **Model used**: `gemini-2.0-flash` (or the latest "Flash" tier model available at the time)
- **Cost**: Free tier via Google AI Studio — daily free request quota
- **Package**: `@ai-sdk/google`
- **Sign up**: aistudio.google.com

### OpenRouter (optional tertiary fallback)
- **Model used**: any model with a `:free` suffix, e.g. `meta-llama/llama-3.1-8b-instruct:free`
- **Cost**: Free — OpenRouter explicitly labels a rotating set of community-hosted models as free, subject to their own rate limits
- **Package**: `@ai-sdk/openai` (OpenAI-compatible client, pointed at OpenRouter's base URL) — this must be installed even though you're not using OpenAI itself, since OpenRouter speaks the OpenAI-compatible API shape
- **Sign up**: openrouter.ai

### Why three providers?
Following the exact same resilience pattern as our market-data layer (Part 5): if the primary (Groq) is rate-limited or down, we automatically fall back to Gemini, then OpenRouter, via `generateWithFallback` (Part 14). This is real production practice applied at zero cost.

### Keeping model IDs current
Free-tier model IDs are the single most volatile piece of information in this entire series — providers retire and add models regularly. If a `generateText` call ever fails with a "model not found" style error:
1. Check the provider's current model list (console.groq.com/docs/models, ai.google.dev/models, openrouter.ai/models filtered to "free").
2. Update the corresponding string in `src/lib/ai/models.ts` — this is the only file that needs to change.

## News

### RSS feeds (SG business news)
- **Used for**: News headlines feeding the News tab and AI Summary (Part 17)
- **Cost**: Free, public RSS feeds, key-less
- **Caveat**: Feed URLs/availability can change; always degrade gracefully rather than treat this as a guaranteed data source

## Hosting

### Vercel (Hobby / free tier)
- **Used for**: Hosting the Next.js 16 app, serverless API routes, and Cron Jobs (Part 21)
- **Cost**: Free Hobby tier — sufficient for a personal portfolio project, includes Cron Jobs
- **Requirement**: Node.js 20.9+ runtime (confirm explicitly under Settings → General → Node.js Version — see Part 21)
- **Sign up**: vercel.com
- **Optional Neon integration**: Vercel's Marketplace has an official Neon integration that can auto-sync connection strings and provision a Neon branch per preview deployment (Part 21) — optional, not required.

## Summary table

| Service | Purpose | Free tier sufficient for portfolio use? |
|---|---|---|
| yahoo-finance2 | Primary market data + dividends | Yes |
| Finnhub | Fallback market data | Yes |
| SGX StockFacts (scrape) | REIT fundamentals | Yes, with graceful degradation |
| Upstash Redis | Caching, rate limiting | Yes |
| Neon Postgres | Persistent storage | Yes |
| Clerk | Auth | Yes |
| Resend | Email alerts | Yes |
| Groq | AI (primary) | Yes |
| Google Gemini | AI (secondary) | Yes |
| OpenRouter | AI (optional tertiary) | Yes |
| Vercel | Hosting + Cron | Yes |

No paid service, paid API key, or paid AI model is required anywhere in this tutorial series.

---

Want me to finish up with **Appendix C (Environment Variables & Troubleshooting Guide)** — the last note in the series?
