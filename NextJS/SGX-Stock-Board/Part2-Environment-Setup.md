# Part 2: Environment Setup (Next.js 16, TypeScript, Tailwind v4, shadcn/ui)

> **TARGET VERSIONS:** This series targets **Next.js 16** (App Router, React 19, Turbopack as the default bundler). Next.js 16 requires **Node.js 20.9+** — Node 22 LTS is recommended; Node 18 is end-of-life and will not work. `create-next-app` now scaffolds **Tailwind CSS v4** (CSS-first configuration — no `tailwind.config.js` by default). One breaking change from older tutorials you may find online: **`params` and `searchParams` in Page components and Route Handlers are `Promise`-based and must be `await`-ed** — every code sample in this series already uses the correct pattern (established in Parts 7 and 8). Database is **Neon serverless Postgres** (Part 3), not Supabase.

## Concept

Before touching any stock data, we need a solid project scaffold: a Next.js 16 App Router project, TypeScript, Tailwind CSS v4, and shadcn/ui for pre-built accessible components (so our UI looks like "Bloomberg Terminal lite" without hand-rolling every button and card).

## Step 0: Verify your Node.js version

```bash
node -v
```

This must print `v20.9.0` or higher (ideally `v22.x`). If it doesn't, install the current LTS from nodejs.org (or via `nvm install --lts`) before continuing — Next.js 16 will refuse to run on older Node versions.

## Step 1: Create the project

```bash
npx create-next-app@latest sgx-dashboard
```

When prompted, choose:
```
Would you like to use TypeScript?  Yes
Would you like to use ESLint?      Yes
Would you like to use Tailwind CSS? Yes
Would you like to use `src/` directory? Yes
Would you like to use App Router?  Yes
Would you like to use Turbopack?   Yes (default in Next.js 16)
Would you like to customize the default import alias (@/*)? Yes (keep default)
```

```bash
cd sgx-dashboard
```

This scaffolds Next.js 16 with React 19, Turbopack, and Tailwind v4.

## Step 2: Install all dependencies up front

We install everything now so no later part is interrupted by a missing-package error:

```bash
npm install prisma @prisma/client
npm install @neondatabase/serverless
npm install @upstash/redis @upstash/ratelimit
npm install yahoo-finance2
npm install lightweight-charts recharts
npm install ai @ai-sdk/google @ai-sdk/groq @ai-sdk/openai
npm install @clerk/nextjs
npm install date-fns
npm install zod
npm install rss-parser
npm install resend
npm install cheerio
npm install -D tsx vitest
```

Quick rundown of what each does:
- `prisma` / `@prisma/client` — our ORM and database toolkit
- `@neondatabase/serverless` — Neon's serverless driver, used later if we want edge-compatible/HTTP-based queries; standard Prisma + `pg`-style connection also works fine over Neon's pooled connection string, but installing this now keeps the option open with no extra step later
- `@upstash/redis` — REST-based Redis client, works great in serverless functions; `@upstash/ratelimit` — request throttling (Part 20)
- `yahoo-finance2` — free stock data (no API key)
- `lightweight-charts` — TradingView's free charting library, **v5** (we use the v5 `addSeries` API in Part 8)
- `recharts` — simpler charts for heatmaps/bar charts
- `ai`, `@ai-sdk/google`, `@ai-sdk/groq` — Vercel AI SDK + free-tier providers (Gemini, Groq); `@ai-sdk/openai` — OpenAI-compatible client used for OpenRouter's free models (Part 14)
- `@clerk/nextjs` — authentication
- `date-fns` — date manipulation (ex-dividend dates, DCA schedules)
- `zod` — schema validation for API inputs
- `rss-parser` — parsing Straits Times / news RSS feeds (Part 17)
- `resend` — free-tier transactional email for price alerts (Part 19)
- `cheerio` — HTML parsing for the SGX StockFacts REIT scraper (Part 15)
- `tsx` (dev) — run TypeScript scripts directly (seed + test scripts); `vitest` (dev) — unit tests (Part 20)

## Step 3: Set up shadcn/ui

```bash
npx shadcn@latest init
```

Recommended answers:
```
Style: New York
Base color: Slate
CSS variables: Yes
```

shadcn's current CLI fully supports Tailwind v4 and will wire itself into your CSS-first config automatically.

Then install the components we'll use throughout the series:

```bash
npx shadcn@latest add button card table tabs badge input select dialog dropdown-menu skeleton tooltip separator sonner command
```

This gives us a consistent, professional component library (`sonner` = toast notifications, `command` = the Cmd+K command bar we build in Part 22).

## Step 4: Project folder structure

Create this structure inside `src/`:

```
src/
  app/
    (dashboard)/
      page.tsx                      # home / market overview
      stock/[ticker]/page.tsx       # individual stock page
      reits/page.tsx                # REIT focus tab
      simulator/page.tsx            # CPF/SRS simulator
      watchlist/page.tsx            # user watchlist
    api/
      stocks/[ticker]/quote/route.ts
      stocks/[ticker]/history/route.ts
      stocks/[ticker]/dividends/route.ts
      stocks/[ticker]/indicators/route.ts
      stocks/[ticker]/dca/route.ts
      stocks/[ticker]/reit/route.ts
      stocks/[ticker]/ai-summary/route.ts
      stocks/search/route.ts
      sectors/heatmap/route.ts
      backtest/route.ts
      news/[ticker]/route.ts
      simulator/cpf-srs/route.ts
      watchlist/route.ts
      watchlist/[ticker]/route.ts
      alerts/check/route.ts
      cron/nightly-refresh/route.ts
    layout.tsx
    globals.css
    error.tsx
    not-found.tsx
  components/
    charts/
    metrics/
    indicators/
    dividends/
    heatmap/
    backtest/
    ai/
    reits/
    simulator/
    news/
    watchlist/
    layout/
    ui/                             # shadcn generated components live here
  lib/
    prisma.ts
    redis.ts
    rate-limit.ts
    api-error.ts
    email.ts
    format.ts
    heatmap-color.ts
    dca-calculator.ts
    cpf-srs-constants.ts
    cpf-srs-simulator.ts
    reit-metrics.ts
    reit-refresh.ts
    stock-service.ts
    tickers.ts
    data-sources/
      yahoo.ts
      finnhub.ts
      sgx-stockfacts.ts
      index.ts
    ai/
      models.ts
      summarize.ts
      prompts.ts
    indicators/
      rsi.ts
      macd.ts
    backtest/
      strategies.ts
      engine.ts
    news/
      rss-fetcher.ts
      sentiment.ts
    hooks/
      use-quote.ts
      use-stock-history.ts
      use-indicators.ts
  types/
    stock.ts
```

We won't create every file yet — we'll create them as we need them in later parts. But go ahead and create the empty folders now so the structure feels familiar as we progress.

## Step 5: Environment variables file

Create `.env.local` in the project root:

```bash
# Database (Part 3) - Neon Postgres
DATABASE_URL=""
DIRECT_URL=""

# Upstash Redis (Part 6)
UPSTASH_REDIS_REST_URL=""
UPSTASH_REDIS_REST_TOKEN=""

# Finnhub fallback (Part 5)
FINNHUB_API_KEY=""

# Clerk (Part 18)
NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY=""
CLERK_SECRET_KEY=""

# AI - free tier providers (Part 14)
GOOGLE_GENERATIVE_AI_API_KEY=""
GROQ_API_KEY=""
OPENROUTER_API_KEY=""

# Email for alerts (Part 19)
RESEND_API_KEY=""

# Cron secret (Part 19)
CRON_SECRET=""

# App URL, used in alert email links (Part 19/21)
NEXT_PUBLIC_APP_URL="http://localhost:3000"
```

Leave the secrets blank for now — we'll fill each one in as its corresponding part requires it. Add `.env.local` to `.gitignore` (Next.js does this by default, but double check).

## Step 6: Tailwind v4 theme utilities

Since we're going for a "Bloomberg Terminal lite" aesthetic (dark, data-dense, green/red for gains/losses), open `src/app/globals.css`. Tailwind v4 uses CSS-first configuration — you'll see an `@import "tailwindcss";` line at the top instead of the old `@tailwind` directives, and custom utilities are defined with the **`@utility`** directive. Add these below the import (and below shadcn's generated theme blocks):

```css
@utility text-gain {
  color: var(--color-emerald-500);
}
@utility text-loss {
  color: var(--color-red-500);
}
@utility bg-gain {
  background-color: color-mix(in oklab, var(--color-emerald-500) 10%, transparent);
}
@utility bg-loss {
  background-color: color-mix(in oklab, var(--color-red-500) 10%, transparent);
}
@utility font-mono-num {
  font-variant-numeric: tabular-nums;
}
```

We'll use `.text-gain` / `.text-loss` throughout the series any time we render a price change, and `.font-mono-num` on every numeric display so columns of prices align.

## Step 7: Run it

```bash
npm run dev
```

Visit `http://localhost:3000` — you should see the default Next.js starter page, compiled by Turbopack (you'll notice it's fast).

## Checkpoint

- [ ] `node -v` prints v20.9+ (ideally v22.x)
- [ ] `npm run dev` runs with no errors on Next.js 16 / Turbopack
- [ ] shadcn/ui components installed under `src/components/ui`
- [ ] Folder structure created under `src/`
- [ ] `.env.local` created (empty secret values are fine for now)
- [ ] `.gitignore` includes `.env.local`
- [ ] `globals.css` contains the five `@utility` definitions

Next: **Part 3 — Database Design (Prisma + Neon Postgres)**, where we design our full schema (Stock, Price, Dividend, Watchlist, Alert) and connect to a real Postgres database hosted on Neon.
