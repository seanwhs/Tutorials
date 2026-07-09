# Part 9: Key Metrics Panel (P/E, Dividend Yield, Market Cap, 52W High/Low)

## Concept

A compact grid of the numbers retail investors check first. All of this data already comes back from our `/api/stocks/[ticker]/quote` route (built in Part 7) — this part is mostly about presentation, plus a `useQuote` hook we'll reuse in later parts (AI summary, watchlist rows, etc).

## Step 1: The quote hook

Create `src/lib/hooks/use-quote.ts`:

```typescript
// src/lib/hooks/use-quote.ts
"use client";

import { useEffect, useState, useCallback } from "react";
import type { Quote } from "@/types/stock";

export function useQuote(ticker: string, pollMs = 0) {
  const [quote, setQuote] = useState<(Quote & { cached: boolean }) | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchQuote = useCallback(async (force = false) => {
    try {
      const res = await fetch(`/api/stocks/${ticker}/quote${force ? "?force=true" : ""}`);
      if (!res.ok) throw new Error(`Failed to load quote (${res.status})`);
      const json = await res.json();
      setQuote(json);
      setError(null);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setLoading(false);
    }
  }, [ticker]);

  useEffect(() => {
    setLoading(true);
    fetchQuote();

    if (pollMs > 0) {
      const id = setInterval(() => fetchQuote(), pollMs);
      return () => clearInterval(id);
    }
  }, [fetchQuote, pollMs]);

  return { quote, loading, error, refresh: () => fetchQuote(true) };
}
```

`pollMs` is optional — pass e.g. `60000` on a live-trading page to auto-refresh every minute; leave it `0` for a static view.

## Step 2: Formatting helpers

Create `src/lib/format.ts` (we'll keep adding to this file throughout the series):

```typescript
// src/lib/format.ts
export function formatCurrency(value: number | undefined | null, currency = "SGD"): string {
  if (value == null) return "—";
  return new Intl.NumberFormat("en-SG", {
    style: "currency",
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 3,
  }).format(value);
}

export function formatCompactNumber(value: number | undefined | null): string {
  if (value == null) return "—";
  return new Intl.NumberFormat("en-SG", {
    notation: "compact",
    maximumFractionDigits: 1,
  }).format(value);
}

export function formatPercent(value: number | undefined | null, digits = 2): string {
  if (value == null) return "—";
  return `${value.toFixed(digits)}%`;
}

export function formatNumber(value: number | undefined | null, digits = 2): string {
  if (value == null) return "—";
  return value.toFixed(digits);
}
```

## Step 3: A reusable MetricCard component

Create `src/components/metrics/metric-card.tsx`:

```tsx
// src/components/metrics/metric-card.tsx
interface MetricCardProps {
  label: string;
  value: string;
  hint?: string;
  tone?: "neutral" | "gain" | "loss";
}

export function MetricCard({ label, value, hint, tone = "neutral" }: MetricCardProps) {
  const toneClass =
    tone === "gain" ? "text-gain" : tone === "loss" ? "text-loss" : "text-foreground";

  return (
    <div className="rounded-lg border p-3">
      <div className="text-xs text-muted-foreground">{label}</div>
      <div className={`text-lg font-semibold font-mono-num ${toneClass}`}>{value}</div>
      {hint && <div className="text-xs text-muted-foreground mt-0.5">{hint}</div>}
    </div>
  );
}
```

## Step 4: The Key Metrics Panel

Create `src/components/metrics/key-metrics-panel.tsx`:

```tsx
// src/components/metrics/key-metrics-panel.tsx
"use client";

import { Card, CardContent, CardHeader } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { Button } from "@/components/ui/button";
import { MetricCard } from "./metric-card";
import { useQuote } from "@/lib/hooks/use-quote";
import {
  formatCurrency,
  formatCompactNumber,
  formatPercent,
  formatNumber,
} from "@/lib/format";

export function KeyMetricsPanel({ ticker }: { ticker: string }) {
  const { quote, loading, error, refresh } = useQuote(ticker);

  if (loading) {
    return (
      <Card>
        <CardContent className="grid grid-cols-2 md:grid-cols-4 gap-3 pt-6">
          {Array.from({ length: 8 }).map((_, i) => (
            <Skeleton key={i} className="h-16" />
          ))}
        </CardContent>
      </Card>
    );
  }

  if (error || !quote) {
    return (
      <Card>
        <CardContent className="pt-6 text-sm text-loss">
          {error ?? "No quote data available."}
        </CardContent>
      </Card>
    );
  }

  const isUp = quote.change >= 0;

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <div className="text-3xl font-bold font-mono-num">
            {formatCurrency(quote.price, quote.currency)}
          </div>
          <div className={`text-sm font-mono-num ${isUp ? "text-gain" : "text-loss"}`}>
            {isUp ? "+" : ""}
            {formatNumber(quote.change)} ({isUp ? "+" : ""}
            {formatPercent(quote.changePercent)})
          </div>
        </div>
        <Button size="sm" variant="outline" onClick={refresh}>
          Refresh
        </Button>
      </CardHeader>
      <CardContent className="grid grid-cols-2 md:grid-cols-4 gap-3">
        <MetricCard label="Open" value={formatCurrency(quote.open, quote.currency)} />
        <MetricCard label="Prev Close" value={formatCurrency(quote.previousClose, quote.currency)} />
        <MetricCard label="Day High" value={formatCurrency(quote.high, quote.currency)} />
        <MetricCard label="Day Low" value={formatCurrency(quote.low, quote.currency)} />
        <MetricCard label="Market Cap" value={formatCompactNumber(quote.marketCap)} />
        <MetricCard label="P/E Ratio" value={formatNumber(quote.peRatio ?? null)} />
        <MetricCard label="Dividend Yield" value={formatPercent(quote.dividendYield ?? null)} />
        <MetricCard label="Volume" value={formatCompactNumber(quote.volume)} />
        <MetricCard
          label="52W High"
          value={formatCurrency(quote.week52High ?? null, quote.currency)}
        />
        <MetricCard
          label="52W Low"
          value={formatCurrency(quote.week52Low ?? null, quote.currency)}
        />
      </CardContent>
    </Card>
  );
}
```

## Step 5: Wire it into the stock page

> **Next.js 16 note:** The stock page is the `async function StockPage({ params })` established in Part 8, which already awaits its `Promise<{ ticker: string }>` params. This step only adds the `KeyMetricsPanel` import/render to that same file — it does **not** change the page's function signature or params handling.

Update `src/app/(dashboard)/stock/[ticker]/page.tsx`:

```tsx
// src/app/(dashboard)/stock/[ticker]/page.tsx
import { StockChartCard } from "@/components/charts/stock-chart-card";
import { KeyMetricsPanel } from "@/components/metrics/key-metrics-panel";

interface StockPageProps {
  params: Promise<{ ticker: string }>;
}

export default async function StockPage({ params }: StockPageProps) {
  const { ticker: rawTicker } = await params;
  const ticker = decodeURIComponent(rawTicker).toUpperCase();

  return (
    <div className="mx-auto max-w-6xl p-6 space-y-6">
      <h1 className="text-2xl font-bold font-mono-num">{ticker}</h1>
      <KeyMetricsPanel ticker={ticker} />
      <StockChartCard ticker={ticker} />
    </div>
  );
}
```

Visit `/stock/D05.SI` — you should now see a metrics panel above the chart with live price, day change (colored green/red), and the full metrics grid.

## Checkpoint

- [ ] `use-quote.ts` hook created
- [ ] `format.ts` helpers created
- [ ] `MetricCard` and `KeyMetricsPanel` components created
- [ ] `/stock/D05.SI` shows a metrics panel with correctly colored gain/loss
- [ ] Clicking "Refresh" forces a live (non-cached) quote fetch
- [ ] The stock page's `async function StockPage({ params })` signature and `await params` line from Part 8 are still intact after this update

Next: **Part 10 — Technical Indicators (RSI, MACD)**, where we compute these indicators ourselves from historical bars (no extra API needed) and add them as chart overlays/sub-panels.
