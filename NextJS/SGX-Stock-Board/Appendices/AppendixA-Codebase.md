# Appendix A: Full Codebase Reference

This appendix is a single map of every file created across the series, organized by folder, with the part number where each was introduced. Use this as a quick lookup/audit tool once you've built the whole app, or as a checklist to confirm nothing was skipped.

> **Next.js 16 compatibility:** Every file below with a dynamic route segment (any path containing `[ticker]`) receives its `params` as a `Promise` and must `await` it — this pattern is already used correctly throughout Parts 7, 8, 9, 10, 11, 14, 15, 17, and 18. Files marked **Yes** in the "Dynamic `params`?" column need this pattern; files marked **No** need no `params` handling at all.

## Root

| File | Introduced |
|---|---|
| `.env.local` | Part 2 (created empty), filled in progressively through Parts 3, 5, 6, 14, 18, 19 |
| `vercel.json` | Part 19 (cron config), used in Part 21 (deployment) |
| `package.json` scripts (`seed`, `test`, `build`) | Parts 3, 20, 21 |
| `prisma/schema.prisma` | Part 3 |
| `prisma/seed.ts` | Part 3 |
| `prisma/reit-fundamentals-seed.ts` | Part 15 |
| `prisma/migrations/` | Part 21 |
| `scripts/test-yahoo.ts` | Part 4 |
| `scripts/test-data-sources.ts` | Part 5 |
| `scripts/test-cache.ts` | Part 6 |

## `src/lib/`

| File | Introduced | Purpose |
|---|---|---|
| `prisma.ts` | Part 3 | Prisma client singleton |
| `redis.ts` | Part 6 | Upstash client + `cached()` helper |
| `rate-limit.ts` | Part 20 | Upstash `@upstash/ratelimit` limiter |
| `tickers.ts` | Part 4 | Curated ticker list, `normalizeTicker`, `isKnownTicker` |
| `stock-service.ts` | Part 6 | `resolveStock` — upsert-on-demand ticker resolution |
| `format.ts` | Part 9 | Currency/percent/number formatting helpers |
| `heatmap-color.ts` | Part 12 | Sector heatmap color scale |
| `dca-calculator.ts` | Part 11 | Pure DCA simulation logic (reused in Part 16) |
| `cpf-srs-constants.ts` | Part 16 | CPF/SRS rate and cap constants |
| `cpf-srs-simulator.ts` | Part 16 | CPF/SRS comparison simulation |
| `reit-metrics.ts` | Part 15 | Distribution yield, price/NAV, gearing risk classification |
| `reit-refresh.ts` | Part 15 | Orchestrates REIT fundamentals refresh |
| `email.ts` | Part 19 | Resend wrapper, `sendPriceAlertEmail` |
| `api-error.ts` | Part 20 | Shared API error response helper |
| `data-sources/yahoo.ts` | Part 4 (quote/history/search), Part 11 (dividends) | yahoo-finance2 wrapper |
| `data-sources/finnhub.ts` | Part 5 | Finnhub wrapper |
| `data-sources/index.ts` | Part 5 (fallback), Part 6 (caching added) | Unified `getQuote`/`getHistory`/`getCachedQuote`/`getCachedHistory` |
| `data-sources/sgx-stockfacts.ts` | Part 15 | Defensive REIT fundamentals scraper |
| `indicators/rsi.ts` | Part 10 | RSI calculation |
| `indicators/macd.ts` | Part 10 | MACD calculation |
| `backtest/strategies.ts` | Part 13 | Strategy definitions |
| `backtest/engine.ts` | Part 13 | Backtest runner + aggregation |
| `ai/models.ts` | Part 14 | Free model registry (Groq, Gemini, OpenRouter) |
| `ai/summarize.ts` | Part 14 | `generateWithFallback` |
| `ai/prompts.ts` | Part 14 | `buildStockSummaryPrompt` |
| `news/rss-fetcher.ts` | Part 17 | RSS news fetching + filtering |
| `news/sentiment.ts` | Part 17 | AI sentiment classification |
| `hooks/use-stock-history.ts` | Part 8 | Historical bars fetch hook |
| `hooks/use-quote.ts` | Part 9 | Quote fetch hook with optional polling |
| `hooks/use-indicators.ts` | Part 10 | RSI/MACD fetch hook |

## `src/types/`

| File | Introduced |
|---|---|
| `stock.ts` | Part 4 (`Quote`, `OhlcvBar`, `Range`) |

## `src/components/`

| File | Introduced |
|---|---|
| `ui/*` (shadcn generated) | Part 2, expanded (`command`) same part |
| `charts/price-chart.tsx` | Part 8 |
| `charts/range-selector.tsx` | Part 8 |
| `charts/stock-chart-card.tsx` | Part 8 |
| `metrics/metric-card.tsx` | Part 9 |
| `metrics/key-metrics-panel.tsx` | Part 9 |
| `indicators/rsi-panel.tsx`, `macd-panel.tsx`, `indicators-card.tsx` | Part 10 |
| `dividends/dividend-tracker.tsx`, `dca-calculator-form.tsx` | Part 11 |
| `heatmap/sector-heatmap.tsx` | Part 12 |
| `backtest/backtest-panel.tsx` | Part 13 |
| `ai/ai-summary-card.tsx` | Part 14 |
| `reits/reit-focus-panel.tsx` | Part 15 |
| `simulator/cpf-srs-simulator-form.tsx` | Part 16 |
| `news/news-feed.tsx` | Part 17 |
| `watchlist/watchlist-table.tsx` | Part 18 |
| `async-boundary.tsx` | Part 20 |
| `layout/page-shell.tsx`, `layout/command-bar.tsx` | Part 22 |

## `src/app/`

| File/Route | Introduced | Dynamic `params`? |
|---|---|---|
| `layout.tsx` | Part 2 (scaffold), Part 18 (Clerk), Part 22 (command bar, metadata) | No |
| `globals.css` | Part 2 (Tailwind v4 `@utility` blocks), Part 22 (theme tuning) | N/A |
| `error.tsx`, `not-found.tsx` | Part 20 | No |
| `middleware.ts` | Part 18 | No |
| `(dashboard)/page.tsx` | Part 12 (heatmap home) | No |
| `(dashboard)/stock/[ticker]/page.tsx` | Part 8, expanded through Parts 9-17, refactored Part 20 (notFound), Part 22 | **Yes** |
| `(dashboard)/reits/page.tsx` | Part 15 | No |
| `(dashboard)/simulator/page.tsx` | Part 16 | No |
| `(dashboard)/watchlist/page.tsx` | Part 18 | No |
| `api/stocks/[ticker]/quote/route.ts` | Part 7 | **Yes** |
| `api/stocks/[ticker]/history/route.ts` | Part 7 | **Yes** |
| `api/stocks/[ticker]/dividends/route.ts` | Part 7 (stub), Part 11 (full logic) | **Yes** |
| `api/stocks/[ticker]/indicators/route.ts` | Part 10 | **Yes** |
| `api/stocks/[ticker]/dca/route.ts` | Part 11 | **Yes** |
| `api/stocks/[ticker]/reit/route.ts` | Part 15 | **Yes** (GET + POST) |
| `api/stocks/[ticker]/ai-summary/route.ts` | Part 14 | **Yes** |
| `api/stocks/search/route.ts` | Part 7 | No |
| `api/sectors/heatmap/route.ts` | Part 12 | No |
| `api/backtest/route.ts` | Part 13 | No |
| `api/simulator/cpf-srs/route.ts` | Part 16 | No |
| `api/news/[ticker]/route.ts` | Part 17 | **Yes** |
| `api/watchlist/route.ts` | Part 18 | No |
| `api/watchlist/[ticker]/route.ts` | Part 18 | **Yes** (DELETE) |
| `api/alerts/check/route.ts` | Part 19 | No |
| `api/cron/nightly-refresh/route.ts` | Part 19 | No |

## Database schema summary (Part 3, extended by later parts)

- `Stock` — master record; fundamentals fields added in Part 3, REIT fields used starting Part 15
- `Price` — daily OHLCV, populated starting Part 7
- `Dividend` — historical + forecast distributions, populated Part 11
- `NewsItem` — headlines + AI sentiment, populated Part 17
- `WatchlistItem` — per-user tracked tickers + alert price, Part 18
- `Alert` — per-user price alerts with direction/triggered state, Part 3 schema, wired up Part 19

## Full environment variable list

See **Appendix C** for the complete list with descriptions, where to obtain each, and troubleshooting tips (including the async `params` pattern noted above).

## How to use this appendix

If you've followed Parts 1-22 in order, every file above should exist in your project. If something's missing or behaving unexpectedly, find its row here to jump back to the exact part that introduced it and re-read that section. For any file marked **Yes** in the "Dynamic `params`?" column, double check it uses the `Promise<{ ticker: string }>` + `await params` pattern if you've modified it or written it from scratch rather than copy-pasting directly.
