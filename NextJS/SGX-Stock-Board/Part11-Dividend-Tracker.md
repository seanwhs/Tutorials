# Part 11: Dividend Tracker and DCA Calculator

## Concept

Dividends (and for REITs, distributions) are arguably the single biggest reason SG retail investors hold SGX stocks. This part builds:

1. A dividend history fetcher using Yahoo Finance dividend/event data
2. A Dividend Tracker UI: past payouts, upcoming estimated ex-dividend dates, trailing yield
3. A DCA (Dollar Cost Averaging) calculator: "if I invested $X every month since date Y, what would my position be worth today, including reinvested or cash dividends?"

> **Next.js 16 note:** The routes in this part under `/api/stocks/[ticker]/...` are dynamic routes, so they must use `params: Promise<{ ticker: string }>` and `await params`, same as Part 7.

## Step 1: Fetching dividend history from Yahoo

Add to `src/lib/data-sources/yahoo.ts` a function that calls Yahoo's chart endpoint with dividend events included:

```typescript
// src/lib/data-sources/yahoo.ts (addition)
export interface DividendEvent {
  exDate: string;
  amount: number;
}

export async function fetchYahooDividends(ticker: string): Promise<DividendEvent[]> {
  try {
    const result: any = await yahooFinance.chart(ticker, {
      period1: new Date("2000-01-01"),
      period2: new Date(),
      interval: "1d",
      events: "dividends" as any,
    });

    const dividends = result.events?.dividends ?? {};
    return Object.values(dividends)
      .map((d: any) => ({
        exDate: new Date((d.date ?? d.amountDate ?? Date.now()) * 1000).toISOString().slice(0, 10),
        amount: Number(d.amount),
      }))
      .filter((d) => Number.isFinite(d.amount));
  } catch (e) {
    console.warn(`[yahoo] dividends failed for ${ticker}:`, (e as Error).message);
    return [];
  }
}
```

We wrap this in try/catch and return an empty array on failure rather than throwing, since not all tickers will have dividend data (e.g., growth stocks with no payouts), and dividend event response shapes can shift between library versions.

## Step 2: Persisting dividends to Postgres

Update the dividends API route created in Part 7 (`src/app/api/stocks/[ticker]/dividends/route.ts`):

```typescript
// src/app/api/stocks/[ticker]/dividends/route.ts
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { cached, CACHE_TTL } from "@/lib/redis";
import { fetchYahooDividends } from "@/lib/data-sources/yahoo";
import { normalizeTicker } from "@/lib/tickers";
import { resolveStock } from "@/lib/stock-service";

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  const { ticker: rawTicker } = await params;
  const ticker = normalizeTicker(rawTicker);
  await resolveStock(ticker);

  // Refresh dividend history at most once per 24h (cached() dedupes repeated calls).
  await cached(`dividends:refresh:${ticker}`, CACHE_TTL.DIVIDENDS, async () => {
    const events = await fetchYahooDividends(ticker);
    for (const d of events) {
      await prisma.dividend.upsert({
        where: { ticker_exDate: { ticker, exDate: new Date(d.exDate) } },
        update: { amount: d.amount, isForecast: false },
        create: { ticker, exDate: new Date(d.exDate), amount: d.amount, isForecast: false },
      });
    }
    return { refreshed: true, count: events.length };
  });

  const dividends = await prisma.dividend.findMany({
    where: { ticker },
    orderBy: { exDate: "desc" },
  });

  return NextResponse.json({ ticker, dividends });
}
```

This keeps Postgres as the durable source of truth while Yahoo remains the refresh mechanism, capped to at most one live refresh per ticker per day.

## Step 3: Estimating upcoming ex-dividend dates

Since free APIs rarely expose forward-looking ex-dividend dates reliably for SGX counters, estimate them heuristically:
- Look at historical cadence between past ex-dates
- Compute average gap in days between recent ex-dates
- Project the next expected ex-date as `lastExDate + averageGap`
- Mark projected entries with `isForecast: true`
- Display them with a clear "Estimated" badge so users know this is not a confirmed corporate action

## Step 4: The Dividend Tracker UI

Build a `DividendTracker` component with:
- Summary row: trailing twelve-month dividend total + current trailing yield
- Table: ex-date, pay date, amount, confirmed/forecast badge
- Recharts bar chart: dividend amount per period over recent years

## Step 5: The DCA Calculator

Concept: user picks a ticker, a monthly contribution amount, and a start date. We fetch monthly historical closes for that ticker, simulate buying shares with the fixed monthly contribution, track share count, track dividends received, and optionally reinvest dividends.

Implement this as a pure function in `src/lib/dca-calculator.ts`:

```typescript
// src/lib/dca-calculator.ts
import type { OhlcvBar } from "@/types/stock";

export interface DcaMonthPoint {
  date: string;
  contribution: number;
  shares: number;
  value: number;
  dividendReceived: number;
}

export interface DcaResult {
  points: DcaMonthPoint[];
  totalContributed: number;
  totalDividends: number;
  finalValue: number;
  returnPercent: number;
}

export function simulateDca(params: {
  monthlyBars: OhlcvBar[]; // one bar per month, sorted ascending
  monthlyContribution: number;
  dividends: { exDate: string; amount: number }[];
  reinvestDividends: boolean;
}): DcaResult {
  const { monthlyBars, monthlyContribution, dividends, reinvestDividends } = params;
  const sorted = [...monthlyBars].sort((a, b) => a.date.localeCompare(b.date));

  let shares = 0;
  let totalContributed = 0;
  let totalDividends = 0;
  const points: DcaMonthPoint[] = [];

  for (const bar of sorted) {
    shares += monthlyContribution / bar.close;
    totalContributed += monthlyContribution;

    const monthDividends = dividends.filter((d) => d.exDate.slice(0, 7) === bar.date.slice(0, 7));
    const dividendReceived = monthDividends.reduce((sum, d) => sum + d.amount * shares, 0);
    totalDividends += dividendReceived;

    if (reinvestDividends && dividendReceived > 0) {
      shares += dividendReceived / bar.close;
    }

    points.push({
      date: bar.date,
      contribution: monthlyContribution,
      shares,
      value: shares * bar.close,
      dividendReceived,
    });
  }

  const finalValue = points.at(-1)?.value ?? 0;
  const returnPercent = totalContributed > 0 ? ((finalValue - totalContributed) / totalContributed) * 100 : 0;

  return { points, totalContributed, totalDividends, finalValue, returnPercent };
}
```

Keeping this pure (no API calls inside it) makes it easy to unit test and reuse in Part 16's CPF/SRS simulator.

Create `src/app/api/stocks/[ticker]/dca/route.ts`:

```typescript
// src/app/api/stocks/[ticker]/dca/route.ts
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { prisma } from "@/lib/prisma";
import { getCachedHistory } from "@/lib/data-sources";
import { simulateDca } from "@/lib/dca-calculator";
import { normalizeTicker } from "@/lib/tickers";
import { resolveStock } from "@/lib/stock-service";

const BodySchema = z.object({
  monthlyContribution: z.number().positive(),
  reinvestDividends: z.boolean().default(true),
});

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  const { ticker: rawTicker } = await params;
  const ticker = normalizeTicker(rawTicker);
  const body = BodySchema.parse(await req.json());

  await resolveStock(ticker);

  const { data: bars } = await getCachedHistory(ticker, "5Y");
  const dividends = await prisma.dividend.findMany({ where: { ticker } });

  // Reduce daily bars down to one bar per month (last trading day of each month).
  const byMonth = new Map<string, typeof bars[number]>();
  for (const bar of bars) byMonth.set(bar.date.slice(0, 7), bar);
  const monthlyBars = Array.from(byMonth.values());

  const result = simulateDca({
    monthlyBars,
    monthlyContribution: body.monthlyContribution,
    dividends: dividends.map((d) => ({ exDate: d.exDate.toISOString().slice(0, 10), amount: d.amount })),
    reinvestDividends: body.reinvestDividends,
  });

  return NextResponse.json(result);
}
```

Build a `DcaCalculatorForm` component with inputs for monthly amount and a reinvest-dividends checkbox. It calls the DCA API route and renders final totals plus a small area chart of portfolio value over time.

## Step 6: Wire into the stock page

Add a Dividends tab and a DCA Calculator tab to the stock detail page. The stock page already resolves its `ticker` after awaiting `params` in Part 8, so just pass that resolved string into the client components.

## Checkpoint

- [ ] Dividend route uses `params: Promise<{ ticker: string }>` and `await params`
- [ ] DCA route uses `params: Promise<{ ticker: string }>` and `await params`
- [ ] Dividend history successfully fetched and persisted for a real dividend-paying ticker such as D05.SI or C38U.SI
- [ ] Upcoming ex-dividend estimate appears with a clear "Estimated" badge and sensible projected date
- [ ] DividendTracker table and bar chart render real historical payout data
- [ ] DCA calculator computes plausible total invested and current value
- [ ] DCA calculation logic lives in a pure, reusable function separate from the API route

Next: Part 12, the Sector Heatmap.
