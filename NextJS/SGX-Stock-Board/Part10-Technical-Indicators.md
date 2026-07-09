# Part 10: Technical Indicators (RSI and MACD)

## Concept

RSI (Relative Strength Index) and MACD (Moving Average Convergence Divergence) are the two most requested technical indicators by retail investors. Both can be computed purely from historical closing prices we already have — no extra API calls needed. We compute them server-side so the math lives in one tested place, expose them via a Next.js Route Handler, and render them as a sub-panel beneath the main chart.

> **Next.js 16 note:** The indicators route below is a dynamic route (`/api/stocks/[ticker]/indicators`), so its `params` argument must be typed as `Promise<{ ticker: string }>` and awaited before reading `ticker`.

## Step 1: RSI calculation

Create `src/lib/indicators/rsi.ts`:

```typescript
// src/lib/indicators/rsi.ts
import type { OhlcvBar } from "@/types/stock";

export interface RsiPoint {
  date: string;
  value: number;
}

// Standard 14-period RSI using Wilder's smoothing method.
export function calculateRSI(bars: OhlcvBar[], period = 14): RsiPoint[] {
  if (bars.length <= period) return [];

  const sorted = [...bars].sort((a, b) => a.date.localeCompare(b.date));
  const changes: number[] = [];
  for (let i = 1; i < sorted.length; i++) {
    changes.push(sorted[i].close - sorted[i - 1].close);
  }

  const gains = changes.map((c) => (c > 0 ? c : 0));
  const losses = changes.map((c) => (c < 0 ? -c : 0));

  let avgGain = gains.slice(0, period).reduce((a, b) => a + b, 0) / period;
  let avgLoss = losses.slice(0, period).reduce((a, b) => a + b, 0) / period;

  const result: RsiPoint[] = [];

  for (let i = period; i < changes.length; i++) {
    avgGain = (avgGain * (period - 1) + gains[i]) / period;
    avgLoss = (avgLoss * (period - 1) + losses[i]) / period;

    const rs = avgLoss === 0 ? 100 : avgGain / avgLoss;
    const rsi = avgLoss === 0 ? 100 : 100 - 100 / (1 + rs);

    result.push({
      date: sorted[i + 1].date,
      value: Number(rsi.toFixed(2)),
    });
  }

  return result;
}
```

## Step 2: MACD calculation

Create `src/lib/indicators/macd.ts`:

```typescript
// src/lib/indicators/macd.ts
import type { OhlcvBar } from "@/types/stock";

export interface MacdPoint {
  date: string;
  macd: number;
  signal: number;
  histogram: number;
}

export function ema(values: number[], period: number): number[] {
  if (!values.length) return [];
  const k = 2 / (period + 1);
  const result: number[] = [values[0]];
  for (let i = 1; i < values.length; i++) {
    result.push(values[i] * k + result[i - 1] * (1 - k));
  }
  return result;
}

export function calculateMACD(
  bars: OhlcvBar[],
  opts: { fastPeriod?: number; slowPeriod?: number; signalPeriod?: number } = {}
): MacdPoint[] {
  const { fastPeriod = 12, slowPeriod = 26, signalPeriod = 9 } = opts;
  const sorted = [...bars].sort((a, b) => a.date.localeCompare(b.date));
  if (sorted.length < slowPeriod + signalPeriod) return [];

  const closes = sorted.map((b) => b.close);
  const fastEma = ema(closes, fastPeriod);
  const slowEma = ema(closes, slowPeriod);
  const macdLine = closes.map((_, i) => fastEma[i] - slowEma[i]);
  const signalLine = ema(macdLine, signalPeriod);

  return sorted.slice(slowPeriod).map((bar, i) => {
    const idx = i + slowPeriod;
    const macd = macdLine[idx];
    const signal = signalLine[idx];
    return {
      date: bar.date,
      macd: Number(macd.toFixed(4)),
      signal: Number(signal.toFixed(4)),
      histogram: Number((macd - signal).toFixed(4)),
    };
  });
}
```

## Step 3: A combined indicators API route

Create `src/app/api/stocks/[ticker]/indicators/route.ts`:

```typescript
// src/app/api/stocks/[ticker]/indicators/route.ts
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { getCachedHistory } from "@/lib/data-sources";
import { normalizeTicker } from "@/lib/tickers";
import { resolveStock } from "@/lib/stock-service";
import { calculateRSI } from "@/lib/indicators/rsi";
import { calculateMACD } from "@/lib/indicators/macd";

const RangeSchema = z.enum(["1D", "5D", "1M", "6M", "1Y", "5Y"]);

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ ticker: string }> }
) {
  try {
    const { ticker: rawTicker } = await params;
    const ticker = normalizeTicker(rawTicker);
    const rangeParam = req.nextUrl.searchParams.get("range") ?? "6M";
    const range = RangeSchema.parse(rangeParam);

    await resolveStock(ticker);

    const { data: bars, cacheHit } = await getCachedHistory(ticker, range);

    const rsi = calculateRSI(bars, 14);
    const macd = calculateMACD(bars, {
      fastPeriod: 12,
      slowPeriod: 26,
      signalPeriod: 9,
    });

    return NextResponse.json({
      ticker,
      range,
      barCount: bars.length,
      cached: cacheHit,
      rsi,
      macd,
      warnings: {
        rsi: bars.length < 15 ? "Not enough bars for RSI" : null,
        macd: bars.length < 35 ? "Not enough bars for stable MACD" : null,
      },
    });
  } catch (err) {
    console.error("[api/indicators] error:", err);
    return NextResponse.json(
      { error: (err as Error).message || "Failed to calculate indicators" },
      { status: 502 }
    );
  }
}
```

This route accepts a `range` query parameter, reuses the cached history fetch from Part 6, computes RSI and MACD from the returned bars, and returns both series as JSON alongside the underlying bar count so the frontend can decide whether there is enough data to render a meaningful chart.

## Step 4: Indicator hook and sub-chart components

Create a `use-indicators` hook mirroring the `use-stock-history` hook from Part 8, fetching from the new indicators route whenever `ticker` or `range` changes.

Create an `RsiPanel` component that renders a small Lightweight Charts line series with horizontal reference lines at 70 (overbought) and 30 (oversold), colored red and green respectively, using the `chart.addSeries(LineSeries, options)` API pattern from Part 8.

Create a `MacdPanel` component that renders three series in one small chart: the MACD line, the signal line, and the histogram as a `HistogramSeries` colored green when the histogram is positive and red when negative.

## Step 5: Compose an IndicatorsCard

Create an `IndicatorsCard` component with tabs (using shadcn `Tabs`) switching between RSI and MACD. Label each tab with its current numeric reading (e.g. `RSI: 62.4 (Neutral)`). Add simple interpretation helpers:
- RSI > 70: Overbought
- RSI < 30: Oversold
- Otherwise: Neutral
- MACD histogram positive/rising: Bullish momentum
- MACD histogram negative/falling: Bearish momentum

## Step 6: Wire into the stock page

Add the `IndicatorsCard` beneath `StockChartCard` on the stock detail page. The stock page already awaits its route `params` in Part 8; just pass the resolved `ticker` string down as a prop.

## Checkpoint

- [ ] RSI and MACD calculation modules created and unit-verified against a known reference implementation or spreadsheet
- [ ] Indicators API route uses `params: Promise<{ ticker: string }>` and `await params`
- [ ] Indicators API route returns sensible RSI/MACD series for a real ticker with sufficient history (use 6M or longer)
- [ ] RsiPanel renders with visible 70/30 reference lines
- [ ] MacdPanel renders MACD line, signal line, and colored histogram correctly
- [ ] IndicatorsCard tabs switch cleanly between RSI and MACD views

Next: Part 11, the Dividend Tracker and DCA Calculator.
