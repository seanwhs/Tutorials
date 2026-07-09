# Part 13: Backtesting Engine (Best Trading Times)

> **Next.js 16 note:** The backtest route in this part (`/api/backtest`) has **no** dynamic segment, so it takes no `params` argument at all — no async-params handling is needed here. It reads its inputs from the POST body.

## Concept

This feature answers questions like "does buying on Monday dips actually work for DBS?" or "is selling right before ex-dividend historically a good idea?". We build a small, honest backtesting engine: honest in the sense that we clearly show sample size and disclaim that past patterns are not guarantees. This is a pattern-testing tool for retail education, not a trading signal generator.

We support a fixed set of pattern strategies to keep this tractable:
- Buy Monday, Sell Friday (day-of-week seasonality)
- Buy on N percent dip, sell after H holding days
- Sell before ex-dividend, buy back after (a dividend capture pattern test)
- Buy after RSI oversold (below 30), sell after H holding days

## Step 1: Strategy definitions

Create `src/lib/backtest/strategies.ts` defining a `Strategy` type with an id, label, and a set of typed parameters (e.g., `holdDays`, `dipPercent`, `rsiThreshold`). Define the four strategies above as constant objects implementing this shape, each with a pure function signature `(bars, dividends, params) => Trade[]`, where a `Trade` is `{ entryDate, entryPrice, exitDate, exitPrice, returnPercent }`.

## Step 2: The core backtest runner

Create `src/lib/backtest/engine.ts`. For each strategy:
- "Buy Monday Sell Friday": scan bars, for every bar that falls on a Monday, treat it as an entry, then find the bar on or before the following Friday as the exit; record the trade.
- "Buy on dip": scan consecutive closes, whenever a day's close is down more than `dipPercent` versus the previous close, enter at that close, exit after `holdDays` trading days.
- "Sell before ex-div": for each dividend's `exDate` in the `Dividend` table, treat the trading day immediately before `exDate` as an exit point from a hypothetical position opened `holdDays` before that, and separately compute the buy-back point some days after `exDate`; compare the avoided-drop math against simply holding through the ex-date.
- "RSI oversold bounce": reuse the RSI calculation from Part 10, whenever RSI crosses below 30, enter at that day's close, exit after `holdDays`.

Aggregate all trades produced by a strategy into summary statistics: total trades, win rate (percentage of trades with positive `returnPercent`), average return per trade, best trade, worst trade, and cumulative return if trades were compounded sequentially (non-overlapping only, to keep this honest and simple).

## Step 3: The backtest API route

Create `src/app/api/backtest/route.ts` accepting a POST body validated with zod: `{ ticker, strategyId, params, range }`. Because the ticker arrives in the request body (not a URL segment), this route needs no route-params handling — just `const body = await req.json()` and zod validation. It resolves the stock, fetches cached history for the requested range (reusing Part 6/7 infrastructure), fetches dividends from Postgres if the strategy needs them, runs the engine, and returns the trade list plus summary statistics. Add a minimum sample size guard: if fewer than 5 trades are produced, include a warning field in the response such as "Insufficient sample size for reliable conclusions" and the frontend must display this warning prominently rather than letting a 100% win rate over 2 trades look impressive.

## Step 4: The Backtest UI

Build a `BacktestPanel` component with: a strategy selector (shadcn `Select`), parameter inputs that change based on the selected strategy (e.g., dip percent slider for the dip strategy, hold days input for all strategies), a "Run Backtest" button, and a results view showing summary stats in `MetricCard`s (reusing the component from Part 9), a simple Recharts bar chart of individual trade returns colored green/red, and the sample-size warning banner when applicable.

## Step 5: Wire into the stock page

Add a "Backtest" tab to the stock detail page's tab set (alongside Chart, Indicators, Dividends, DCA Calculator from prior parts). The stock page already awaits its `params` once at the top (Part 8) — just pass the resolved `ticker` string into `BacktestPanel` as a prop.

## Step 6: An important disclaimer

Add a permanent, non-dismissible disclaimer text near the top of the `BacktestPanel`: "Backtested results are based on historical data only and do not guarantee future performance. This tool is for educational exploration of historical patterns, not investment advice." This is both an ethical requirement and, frankly, good practice to show in a portfolio project — it demonstrates product judgment.

## Checkpoint

- [ ] Backtest API route runs all four strategies against a real ticker without errors
- [ ] Trade list and summary stats look sane (e.g., win rate between 0-100%, average return in a plausible single-digit percent range for most strategies)
- [ ] Sample-size warning appears correctly when fewer than 5 trades are found (try a short range like 1M to trigger this)
- [ ] `BacktestPanel` UI lets you switch strategies and parameters and re-run
- [ ] Disclaimer is visible and permanent

Next: Part 14, the AI Summary feature using the Vercel AI SDK with a free-model selector abstraction, arguably the most "wow factor" feature in the whole app.
