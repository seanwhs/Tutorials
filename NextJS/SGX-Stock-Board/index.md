# SGX Stock Analytics Dashboard for Retail Investors — Tutorial Series INDEX

## Target versions
- **Next.js 16** (App Router, React 19, Turbopack default) — requires **Node.js 20.9+** (Node 22 LTS recommended; Node 18 is EOL and will not work)
- All dynamic routes/pages use the **`Promise`-based `params`** pattern (`await params`)
- **Tailwind CSS v4** (CSS-first config, `@utility` directive, no `tailwind.config.js`)
- **lightweight-charts v5** (`chart.addSeries(CandlestickSeries, ...)` API)
- **Prisma 6+**, Clerk current async `auth()`/`clerkClient()`, Vercel AI SDK current `generateText`/`streamText`
- **Neon serverless Postgres** (replaces Supabase — see "Why Neon" below)

## What you're building
A full-stack dashboard for SGX tickers (D05.SI DBS, Z74.SI Singtel, C38U.SI CapitaLand ICT, etc.) — live/historical prices, indicators, dividends, sector heatmap, backtesting, AI summaries, REIT tab, CPF/SRS simulator, news sentiment, watchlist alerts.

## Stack (100% free-tier / open source)
Next.js 16 · Prisma + **Neon Postgres** · Tailwind v4 + shadcn/ui · Lightweight Charts v5 + Recharts · Upstash Redis + `@upstash/ratelimit` · Vercel (hosting + Cron) · Clerk · yahoo-finance2 (primary) + Finnhub (fallback) · SGX StockFacts scraping (defensive) · Resend · Vercel AI SDK free-model selector (Groq → Gemini → OpenRouter)

## Tutorial Parts (1–23)
1. Introduction & Architecture
2. Environment Setup
3. Database Design (Prisma + **Neon** Postgres)
4. Data Ingestion Foundations (yahoo-finance2)
5. Free Market Data APIs (Finnhub fallback)
6. Caching Layer (Upstash Redis)
7. Core API Routes
8. Price & Volume Charts
9. Key Metrics Panel
10. Technical Indicators (RSI, MACD)
11. Dividend Tracker & DCA Calculator
12. Sector Heatmap
13. Backtesting Engine
14. AI Summary (free model selector)
15. REIT Focus Tab
16. CPF/SRS Portfolio Simulator
17. News + Sentiment Analysis
18. Auth & Watchlists (Clerk)
19. Price Alerts (Vercel Cron + Email)
20. Testing, Error Handling, Rate-Limit Resilience
21. Deployment to Vercel (**Neon** + Vercel)
22. UI Polish — Bloomberg Terminal Theme
23. Conclusion & Roadmap

## Appendices
- **A:** Full Codebase Reference (with "Dynamic `params`?" column)
- **B:** Free APIs & Free AI Models Reference
- **C:** Environment Variables & Troubleshooting Guide (async `params` gotcha first; **Neon connection-string gotchas** included)

## Design principles
Provider-agnostic fallback (Yahoo→Finnhub, Groq→Gemini→OpenRouter), Redis cache-aside, pure/testable business logic, graceful degradation, explicit disclaimers, zero paid services, Postgres accessed purely through Prisma (so the Supabase→Neon swap only touched Parts 3 and 21).

## Validation honesty note
Validated via **static code review only** — not executed. The real test is your own `npm run dev` (Part 2) and deployment (Part 21).

