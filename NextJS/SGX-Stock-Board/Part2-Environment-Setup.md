# Part 1: Introduction & Architecture

## Welcome

This is a step-by-step, beginner-friendly, code-heavy tutorial series for building a **SGX Stock Analytics Dashboard for Retail Investors** — a real, deployable SaaS-style app that pulls live and historical data for Singapore Exchange (SGX) stocks like DBS (D05.SI), SingTel (Z74.SI), and CapitaLand Integrated Commercial Trust (C38U.SI), and layers on the kind of analytics an SG retail investor actually cares about: dividends, REIT metrics, CPF/SRS DCA planning, sector heatmaps, and AI-generated plain-English summaries.

By the end of this series you will have:

- A working Next.js 16 App Router application
- A Postgres database (via **Neon**, a serverless Postgres provider) storing stocks, prices, dividends, watchlists
- Live SGX quote + historical price ingestion (yahoo-finance2 primary, Finnhub fallback)
- Redis caching (Upstash) so you don't hit rate limits
- Candlestick/line/volume charts with 1D–5Y ranges (TradingView Lightweight Charts v5)
- A key metrics panel (P/E, Dividend Yield, Market Cap, 52W Hi/Lo)
- RSI and MACD technical indicators
- A dividend tracker with ex-div dates and a DCA calculator
- A sector heatmap
- A "best trading times" backtesting engine
- AI-generated summaries using **free** LLM models only, with a model-selector abstraction
- A REIT-focused tab (DPU, NAV, Gearing Ratio, Occupancy)
- A CPF/SRS portfolio DCA simulator
- News + sentiment analysis
- User accounts, watchlists, and price alerts (email via Vercel Cron)
- A full deployment to Vercel, all on free tiers

We will build this exactly the way you'd build it as a professional: **concept first, then schema, then server logic, then UI, then a checkpoint** to verify it works — every part, no exceptions.

> This series assumes you're comfortable with basic JavaScript/TypeScript and have Node.js installed. Everything else — Next.js, Prisma, Tailwind, Redis, chart libraries — is taught from scratch.

## Why this project is a great portfolio piece

This project proves you can:
- Build a full-stack app (frontend + backend + DB)
- Integrate multiple third-party APIs and handle their quirks/rate limits
- Process and transform financial time-series data
- Build domain-specific features (REITs, CPF/SRS) that show you understand the Singapore market specifically — this is what makes it stand out in an SG job interview versus a generic "stock tracker" clone
- Use modern AI tooling (Vercel AI SDK) responsibly, with cost-consciousness (free models only)

## Why Neon for Postgres

We use **Neon** (a serverless Postgres provider) rather than a bundled backend-as-a-service platform, because:
- This project only ever touches Postgres through Prisma — no bundled auth, storage, or realtime features are needed (auth is handled by Clerk, Part 18).
- Neon is a focused product: true scale-to-zero compute, fast resume from idle, and built-in connection pooling designed specifically for serverless environments like Vercel's.
- Neon integrates tightly with Vercel (Vercel's own managed Postgres offering is built on Neon).
- Neon's free tier doesn't require a manual dashboard restart after a period of inactivity, which matters for an infrequently-visited portfolio project.
- Database branching (instant copy-on-write branches) is a nice bonus if you ever want a separate database per Vercel preview deployment — not required for this tutorial, but available if you explore it later.

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                           Browser (Client)                        │
│  Next.js App Router pages/components (React Server + Client)      │
│  - Chart components (Lightweight Charts, Recharts)                │
│  - Dashboard, REIT tab, Watchlist, Backtest UI                    │
└───────────────┬────────────────────────────────────────────────────┘
                │ fetch() to same-origin API routes
┌───────────────▼────────────────────────────────────────────────────┐
│                   Next.js API Routes / Route Handlers              │
│  /api/stocks/[ticker]/quote                                       │
│  /api/stocks/[ticker]/history                                     │
│  /api/stocks/[ticker]/dividends                                   │
│  /api/stocks/[ticker]/ai-summary                                  │
│  /api/watchlist  /api/alerts  /api/backtest  /api/sentiment        │
└───────┬───────────────────┬───────────────────┬────────────────────┘
        │                   │                   │
┌───────▼────────┐  ┌───────▼────────┐  ┌───────▼─────────────────┐
│ Upstash Redis   │  │ Prisma ORM     │  │ External APIs           │
│ (cache 15 min)  │  │ → Neon Postgres│  │ - yahoo-finance2 (npm)   │
│                 │  │ Stock, Price,  │  │ - Finnhub (fallback)     │
│                 │  │ Dividend,      │  │ - SGX StockFacts (scrape)│
│                 │  │ Watchlist, User│  │ - Straits Times RSS      │
└─────────────────┘  └────────────────┘  └──────────────────────────┘
                            │
                    ┌───────▼─────────────┐
                    │ Vercel AI SDK        │
                    │ Free model selector: │
                    │ Groq Llama 3.1 free  │
                    │ Google Gemini Flash  │
                    │ OpenRouter free tier │
                    └───────────────────────┘
                            │
                    ┌───────▼─────────────┐
                    │ Vercel Cron          │
                    │ (price alert emails, │
                    │  nightly data sync)  │
                    └───────────────────────┘
```

## Data flow, in plain English

1. A user opens `/stock/D05.SI`.
2. The page's server component calls our internal API route, which first checks **Upstash Redis** for a cached quote/history.
3. If cached data is fresh (< 15 min old), we return it immediately — this keeps us within free API rate limits.
4. If not cached, we call **yahoo-finance2** (no API key needed, generous limits) to get quote + historical OHLCV data. If that fails, we fall back to **Finnhub** free tier.
5. Fresh data is written to **Neon Postgres** (via Prisma) for permanent historical storage, and to Redis for short-term caching.
6. The client renders candlestick charts, metrics panel, indicators — all computed from this data.
7. For the AI Summary feature, we assemble a small structured prompt (price change, P/E, dividend yield, recent headline) and send it to a **free** LLM (Groq/Gemini/OpenRouter — user-selectable in code) via the Vercel AI SDK, and stream back a natural-language summary.
8. Vercel Cron jobs run nightly to refresh dividend calendars and periodically (during SGX trading hours) to check watchlist alert prices, emailing users when triggered.

## Why these tools specifically

| Concern | Choice | Why |
|---|---|---|
| Framework | Next.js 16 App Router | Server + client components in one framework, API routes built-in, first-class Vercel deployment |
| Database | Neon serverless Postgres (free tier) | Scale-to-zero, fast resume, built-in pooling, tight Vercel integration, no bundled features we don't need |
| ORM | Prisma | Type-safe queries, easy migrations, great DX for beginners |
| Charts | TradingView Lightweight Charts v5 | Purpose-built for candlestick/OHLC financial charts, free, lightweight, used by real trading platforms |
| Secondary charts | Recharts | Easier for simple bar/heatmap/line visualizations (sector heatmap, DPU trends) |
| Caching | Upstash Redis (free tier) | Serverless-friendly (REST-based), generous free tier, avoids hitting API rate limits |
| Data source | yahoo-finance2 (npm) | Free, no API key, covers `.SI` SGX tickers, good enough for a portfolio project |
| Fallback data source | Finnhub free tier | Real API key + rate limits teach you to build resilient fallback logic |
| Auth | Clerk (free tier) | Fast to integrate, handles sessions/JWTs, free for small user counts |
| AI | Vercel AI SDK + free models only | Teaches the modern AI SDK pattern without any cost; model-selector abstraction shown in Part 14 |
| Hosting | Vercel free (Hobby) tier | Cron jobs, edge functions, zero-cost deployment |

## A note on ".SI" tickers and free data

SGX-listed stocks on Yahoo Finance and most data providers use a `.SI` suffix, e.g.:
- `D05.SI` = DBS Group Holdings
- `O39.SI` = OCBC Bank
- `U11.SI` = UOB
- `Z74.SI` = Singtel
- `C38U.SI` = CapitaLand Integrated Commercial Trust (a REIT)
- `A17U.SI` = CapitaLand Ascendas REIT (a REIT)
- `ES3.SI` = SPDR STI ETF (tracks the Straits Times Index)

We will use these as our running examples throughout the series. `yahoo-finance2` supports `.SI` tickers out of the box with no extra configuration — this is what makes it perfect for free prototyping. Finnhub's free tier also supports many SGX symbols (format may differ slightly — we cover normalization in Part 5).

## What you need before starting

- **Node.js 20.9+ installed** (Next.js 16 requires this; Node 22 LTS recommended; Node 18 is end-of-life and will NOT work)
- A free GitHub account (for deployment)
- A free Vercel account
- A free Neon account (for Postgres)
- A free Upstash account
- A free Clerk account
- A free Finnhub account (just for the fallback/Part 5 — optional but recommended)
- A free Groq and/or Google AI Studio (Gemini) account for AI summaries (Part 14)
- A code editor (VS Code recommended)

No credit card is required for any of the above at the free tiers we use.

## Series structure recap

Every part will follow this format:
1. **Concept** — what we're building and why
2. **Schema** — any database changes needed (if applicable)
3. **Server logic** — API routes, data fetching, business logic
4. **UI** — the React components
5. **Checkpoint** — a concrete way to verify it works before moving to the next part

## Checkpoint for Part 1

There's no code yet — this part is purely conceptual. Before moving to Part 2, make sure you:
- [ ] Understand the high-level architecture diagram above
- [ ] Have Node.js 20.9+ installed (`node -v` to check — should print v20.9 or higher, ideally v22.x)
- [ ] Have created (or are ready to create) free accounts: GitHub, Vercel, Neon, Upstash, Clerk, Finnhub, Groq/Google AI Studio
- [ ] Understand why this series uses Neon rather than Supabase (see "Why Neon for Postgres" above)

Once you're ready, move on to **Part 2: Environment Setup**, where we scaffold the actual Next.js project.
