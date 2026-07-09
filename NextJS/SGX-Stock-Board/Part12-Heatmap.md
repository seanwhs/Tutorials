# Part 12: Sector Heatmap

> **Next.js 16 note:** The heatmap route (`/api/sectors/heatmap`) and the dashboard home page have **no** dynamic segments, so no `params` handling is needed anywhere in this part.

## Concept

A sector heatmap gives an at-a-glance view of which parts of the SGX market are hot or cold: Banks, REITs, Tech, Telco, Industrials, Consumer, Healthcare, Energy, ETF. We aggregate the day's percentage change across all stocks in each sector (weighted by market cap, so DBS moving 1% matters more to the Banks tile than a small-cap mover) and render a grid where tile size reflects aggregate market cap and color reflects performance.

## Step 1: A sector aggregation API route

Create `src/app/api/sectors/heatmap/route.ts`. Logic:
1. Load all `Stock` rows from Postgres, grouped by `sector`.
2. For each stock, fetch a cached quote (`getCachedQuote`) — reuse the same 15-minute Redis cache from Part 6, so a heatmap refresh doesn't cause a burst of live API calls beyond what individual stock pages are already doing.
3. For each sector, compute a market-cap-weighted average `changePercent`: `sum(changePercent_i * marketCap_i) / sum(marketCap_i)`. Fall back to a simple average if market cap is missing for some stocks.
4. Return an array of `{ sector, weightedChangePercent, totalMarketCap, stockCount, topMover: { ticker, changePercent } }`.

```typescript
// src/app/api/sectors/heatmap/route.ts
import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { getCachedQuote } from "@/lib/data-sources";

export async function GET() {
  const stocks = await prisma.stock.findMany();

  const bySector = new Map<string, { ticker: string; changePercent: number; marketCap: number }[]>();

  await Promise.all(
    stocks.map(async (stock) => {
      try {
        const { data: quote } = await getCachedQuote(stock.ticker);
        const entry = {
          ticker: stock.ticker,
          changePercent: quote.changePercent,
          marketCap: quote.marketCap ?? stock.marketCap ?? 0,
        };
        const list = bySector.get(stock.sector) ?? [];
        list.push(entry);
        bySector.set(stock.sector, list);
      } catch (err) {
        console.warn(`[heatmap] skipping ${stock.ticker}:`, (err as Error).message);
      }
    })
  );

  const sectors = Array.from(bySector.entries()).map(([sector, entries]) => {
    const totalMarketCap = entries.reduce((sum, e) => sum + e.marketCap, 0);
    const weighted =
      totalMarketCap > 0
        ? entries.reduce((sum, e) => sum + e.changePercent * e.marketCap, 0) / totalMarketCap
        : entries.reduce((sum, e) => sum + e.changePercent, 0) / entries.length;

    const topMover = [...entries].sort(
      (a, b) => Math.abs(b.changePercent) - Math.abs(a.changePercent)
    )[0];

    return {
      sector,
      weightedChangePercent: Number(weighted.toFixed(2)),
      totalMarketCap,
      stockCount: entries.length,
      topMover,
    };
  });

  return NextResponse.json({ sectors, asOf: new Date().toISOString() });
}
```

Note: since our seed list only has ~10 stocks, sectors will have few members — that's fine for a portfolio project. In a real product you'd seed hundreds of SGX tickers; the aggregation logic scales regardless.

## Step 2: A heatmap tile color scale

Create `src/lib/heatmap-color.ts`:

```typescript
// src/lib/heatmap-color.ts
// Maps a percentage change to a background color, red (losses) to green (gains).
export function heatmapColor(changePercent: number): string {
  const clamped = Math.max(-5, Math.min(5, changePercent)); // clamp to +/-5% for color scaling
  const intensity = Math.abs(clamped) / 5; // 0 to 1

  if (clamped >= 0) {
    // green scale
    const lightness = 45 - intensity * 20; // darker green as it gets stronger
    return `hsl(152, 60%, ${lightness}%)`;
  } else {
    const lightness = 45 - intensity * 20;
    return `hsl(0, 65%, ${lightness}%)`;
  }
}
```

## Step 3: The heatmap grid component

Create `src/components/heatmap/sector-heatmap.tsx`:

```tsx
// src/components/heatmap/sector-heatmap.tsx
"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { Skeleton } from "@/components/ui/skeleton";
import { heatmapColor } from "@/lib/heatmap-color";
import { formatCompactNumber, formatPercent } from "@/lib/format";

interface SectorTile {
  sector: string;
  weightedChangePercent: number;
  totalMarketCap: number;
  stockCount: number;
  topMover: { ticker: string; changePercent: number };
}

export function SectorHeatmap() {
  const [sectors, setSectors] = useState<SectorTile[] | null>(null);

  useEffect(() => {
    fetch("/api/sectors/heatmap")
      .then((res) => res.json())
      .then((json) => setSectors(json.sectors));
  }, []);

  if (!sectors) {
    return (
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {Array.from({ length: 8 }).map((_, i) => (
          <Skeleton key={i} className="h-28" />
        ))}
      </div>
    );
  }

  // Tile size proportional to market cap share of the total.
  const totalCap = sectors.reduce((s, t) => s + t.totalMarketCap, 0) || 1;

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
      {sectors
        .sort((a, b) => b.totalMarketCap - a.totalMarketCap)
        .map((tile) => {
          const sizeShare = tile.totalMarketCap / totalCap;
          return (
            <Link
              key={tile.sector}
              href={`/sector/${tile.sector.toLowerCase()}`}
              className="rounded-lg p-4 text-white flex flex-col justify-between transition-transform hover:scale-[1.02]"
              style={{
                backgroundColor: heatmapColor(tile.weightedChangePercent),
                minHeight: `${80 + sizeShare * 160}px`,
              }}
            >
              <div>
                <div className="font-semibold text-sm">{tile.sector}</div>
                <div className="text-2xl font-bold font-mono-num">
                  {tile.weightedChangePercent >= 0 ? "+" : ""}
                  {formatPercent(tile.weightedChangePercent)}
                </div>
              </div>
              <div className="text-xs opacity-90">
                {tile.stockCount} stocks · Cap {formatCompactNumber(tile.totalMarketCap)}
                <br />
                Top mover: {tile.topMover?.ticker} ({formatPercent(tile.topMover?.changePercent)})
              </div>
            </Link>
          );
        })}
    </div>
  );
}
```

## Step 4: A dashboard home page

Create `src/app/(dashboard)/page.tsx`:

```tsx
// src/app/(dashboard)/page.tsx
import { SectorHeatmap } from "@/components/heatmap/sector-heatmap";

export default function DashboardHome() {
  return (
    <div className="mx-auto max-w-6xl p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold">SGX Market Overview</h1>
        <p className="text-sm text-muted-foreground">Sector performance, updated every 15 minutes</p>
      </div>
      <SectorHeatmap />
    </div>
  );
}
```

Visit `http://localhost:3000` — you should see a colored grid of sector tiles sized by market cap and colored by today's weighted performance, each linking to a (future) sector detail page.

## Checkpoint

- [ ] `/api/sectors/heatmap` returns market-cap-weighted sector performance
- [ ] `SectorHeatmap` renders colored, sized tiles on the dashboard home page
- [ ] Colors scale sensibly (deep green for strong gains, deep red for strong losses, muted for flat)
- [ ] Tile size roughly reflects sector market cap share

Next: **Part 13 — Backtesting Engine ("Best Trading Times")**, where we build a generic backtester for simple pattern strategies like "buy on Monday dip" or "sell before ex-div".
