# Part 8: Price & Volume Charts (Lightweight Charts v5, 1D–5Y)

## Concept

This is the visual centerpiece of the app. We use TradingView's `lightweight-charts` library (v5) to render a candlestick chart with a synced volume histogram beneath it, plus a range selector (1D, 5D, 1M, 6M, 1Y, 5Y) and a toggle between candlestick and line view.

`lightweight-charts` is a canvas-based charting library (not React-native), so we wrap it in a `useEffect`-based React component.

## Step 1: A data-fetching hook

Create `src/lib/hooks/use-stock-history.ts`:

```typescript
// src/lib/hooks/use-stock-history.ts
"use client";

import { useEffect, useState } from "react";
import type { OhlcvBar, Range } from "@/types/stock";

export function useStockHistory(ticker: string, range: Range) {
  const [bars, setBars] = useState<OhlcvBar[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError(null);

    fetch(`/api/stocks/${ticker}/history?range=${range}`)
      .then((res) => {
        if (!res.ok) throw new Error(`Failed to load history (${res.status})`);
        return res.json();
      })
      .then((json) => {
        if (!cancelled) setBars(json.bars ?? []);
      })
      .catch((err) => {
        if (!cancelled) setError(err.message);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, [ticker, range]);

  return { bars, loading, error };
}
```

## Step 2: The chart component

Create `src/components/charts/price-chart.tsx`:

```tsx
// src/components/charts/price-chart.tsx
"use client";

import { useEffect, useRef } from "react";
import {
  createChart,
  ColorType,
  CandlestickSeries,
  HistogramSeries,
  LineSeries,
  type IChartApi,
} from "lightweight-charts";
import type { OhlcvBar } from "@/types/stock";

interface PriceChartProps {
  bars: OhlcvBar[];
  mode: "candlestick" | "line";
  height?: number;
}

export function PriceChart({ bars, mode, height = 400 }: PriceChartProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const chartRef = useRef<IChartApi | null>(null);

  useEffect(() => {
    if (!containerRef.current) return;

    const chart = createChart(containerRef.current, {
      height,
      layout: {
        background: { type: ColorType.Solid, color: "transparent" },
        textColor: "#94a3b8", // slate-400, matches our dark theme
      },
      grid: {
        vertLines: { color: "#1e293b" },
        horzLines: { color: "#1e293b" },
      },
      timeScale: {
        borderColor: "#334155",
        timeVisible: true,
      },
      rightPriceScale: {
        borderColor: "#334155",
      },
      crosshair: { mode: 0 },
    });

    chartRef.current = chart;

    const sortedBars = [...bars].sort((a, b) => a.date.localeCompare(b.date));

    if (mode === "candlestick") {
      // v5 API: chart.addSeries(CandlestickSeries, options) — NOT chart.addCandlestickSeries()
      const series = chart.addSeries(CandlestickSeries, {
        upColor: "#10b981",
        downColor: "#ef4444",
        borderVisible: false,
        wickUpColor: "#10b981",
        wickDownColor: "#ef4444",
      });
      series.setData(
        sortedBars.map((b) => ({
          time: b.date,
          open: b.open,
          high: b.high,
          low: b.low,
          close: b.close,
        }))
      );
    } else {
      const series = chart.addSeries(LineSeries, {
        color: "#38bdf8",
        lineWidth: 2,
      });
      series.setData(sortedBars.map((b) => ({ time: b.date, value: b.close })));
    }

    // Volume histogram, overlaid at the bottom of the same pane
    const volumeSeries = chart.addSeries(HistogramSeries, {
      priceFormat: { type: "volume" },
      priceScaleId: "volume",
    });
    volumeSeries.priceScale().applyOptions({
      scaleMargins: { top: 0.8, bottom: 0 },
    });
    volumeSeries.setData(
      sortedBars.map((b) => ({
        time: b.date,
        value: b.volume,
        color: b.close >= b.open ? "#10b98166" : "#ef444466",
      }))
    );

    chart.timeScale().fitContent();

    const handleResize = () => {
      if (containerRef.current) {
        chart.applyOptions({ width: containerRef.current.clientWidth });
      }
    };
    window.addEventListener("resize", handleResize);
    handleResize();

    return () => {
      window.removeEventListener("resize", handleResize);
      chart.remove();
    };
  }, [bars, mode, height]);

  return <div ref={containerRef} className="w-full" />;
}
```

## Step 3: The range selector + mode toggle

Create `src/components/charts/range-selector.tsx`:

```tsx
// src/components/charts/range-selector.tsx
"use client";

import { Button } from "@/components/ui/button";
import type { Range } from "@/types/stock";

const RANGES: Range[] = ["1D", "5D", "1M", "6M", "1Y", "5Y"];

interface RangeSelectorProps {
  value: Range;
  onChange: (range: Range) => void;
}

export function RangeSelector({ value, onChange }: RangeSelectorProps) {
  return (
    <div className="flex gap-1">
      {RANGES.map((r) => (
        <Button
          key={r}
          size="sm"
          variant={r === value ? "default" : "ghost"}
          onClick={() => onChange(r)}
        >
          {r}
        </Button>
      ))}
    </div>
  );
}
```

## Step 4: Compose it all into a StockChartCard

Create `src/components/charts/stock-chart-card.tsx`:

```tsx
// src/components/charts/stock-chart-card.tsx
"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { PriceChart } from "./price-chart";
import { RangeSelector } from "./range-selector";
import { useStockHistory } from "@/lib/hooks/use-stock-history";
import type { Range } from "@/types/stock";

export function StockChartCard({ ticker }: { ticker: string }) {
  const [range, setRange] = useState<Range>("6M");
  const [mode, setMode] = useState<"candlestick" | "line">("candlestick");
  const { bars, loading, error } = useStockHistory(ticker, range);

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <RangeSelector value={range} onChange={setRange} />
        <div className="flex gap-1">
          <Button
            size="sm"
            variant={mode === "candlestick" ? "default" : "ghost"}
            onClick={() => setMode("candlestick")}
          >
            Candles
          </Button>
          <Button
            size="sm"
            variant={mode === "line" ? "default" : "ghost"}
            onClick={() => setMode("line")}
          >
            Line
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {loading && <Skeleton className="h-[400px] w-full" />}
        {error && (
          <div className="flex h-[400px] items-center justify-center text-sm text-loss">
            {error}
          </div>
        )}
        {!loading && !error && bars.length === 0 && (
          <div className="flex h-[400px] items-center justify-center text-sm text-muted-foreground">
            No data available for this range.
          </div>
        )}
        {!loading && !error && bars.length > 0 && (
          <PriceChart bars={bars} mode={mode} />
        )}
      </CardContent>
    </Card>
  );
}
```

## Step 5: Wire it into the stock page

> **Next.js 16 note:** Page component `params` are also `Promise`-based. The page below is an `async` Server Component that `await`s `params` before use — this is the required pattern. This same `page.tsx` file will be extended across Parts 9 through 17 to add the Key Metrics Panel, Indicators, Dividends, DCA Calculator, Backtest, REIT Focus, and News tabs — all of those additions reuse the same `async function StockPage({ params })` shape established here.

Create `src/app/(dashboard)/stock/[ticker]/page.tsx`:

```tsx
// src/app/(dashboard)/stock/[ticker]/page.tsx
import { StockChartCard } from "@/components/charts/stock-chart-card";

interface StockPageProps {
  params: Promise<{ ticker: string }>;
}

export default async function StockPage({ params }: StockPageProps) {
  const { ticker: rawTicker } = await params;
  const ticker = decodeURIComponent(rawTicker).toUpperCase();

  return (
    <div className="mx-auto max-w-6xl p-6 space-y-6">
      <h1 className="text-2xl font-bold font-mono-num">{ticker}</h1>
      <StockChartCard ticker={ticker} />
    </div>
  );
}
```

Visit `http://localhost:3000/stock/D05.SI` — you should see a real candlestick chart with a volume histogram underneath, range buttons (1D–5Y) that reload data, and a candlestick/line toggle.

## Checkpoint

- [ ] `PriceChart`, `RangeSelector`, `StockChartCard` components created
- [ ] `/stock/D05.SI` renders a real candlestick chart with volume bars
- [ ] Switching ranges (1D–5Y) reloads and re-renders the chart correctly
- [ ] Toggling Candles/Line switches chart type without errors
- [ ] Chart resizes correctly when you resize the browser window
- [ ] The stock page component is `async` and correctly `await`s `params`

Next: **Part 9 — Key Metrics Panel**, where we build the P/E, Dividend Yield, Market Cap, and 52-Week High/Low display that sits alongside the chart.
